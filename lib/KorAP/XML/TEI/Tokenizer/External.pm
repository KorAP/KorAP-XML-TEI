package KorAP::XML::TEI::Tokenizer::External;
use base 'KorAP::XML::TEI::Annotations';
use strict;
use warnings;
use Log::Any qw($log);
use IO::Select;
use IPC::Open2 qw(open2);
use Encode qw(encode);
use Scalar::Util qw'looks_like_number';

# This tokenizer starts an external process for
# tokenization. It writes the data to tokenize
# to STDIN and reads boundary data from STDOUT.

use constant {
  WAIT_SECS          => 3600,
  RETRY_ATTEMPTS    => 1,
  LOG_SNIPPET_CHARS => 120
};


# Construct a new tokenizer.
# Accepts the command to call the external tokenizer
# and optionally a character sequence indicating the
# end of an input.
sub new {
  my ($class, $cmd, $sep) = @_;

  unless ($cmd) {
    $log->warn('Tokenizer not established');
    return;
  };

  # Send <EOT> to separate textsv (and \n to flush output)
  # (Default for KorAP-Tokenizer).
  $sep //= "\x04\n";

  my $self = bless {
      chld_in         => undef,
      chld_out        => undef,
      pid             => undef,
      cmd             => $cmd,
      select          => undef,
      sep             => $sep,
      sentence_split  => undef,
      last_input      => undef,
      sentence_starts => [],
      sentence_endss  => [],
  }, $class;

  # Initialize tokenizer
  $self->_init;
  return $self;
};


# Tokenize text in an external process
sub tokenize {
  my ($self, $txt) = @_;
  return unless $self->{pid};
  $self->{last_input} = $txt;
  $self->{sentence_starts} = [];
  $self->{sentence_endss} = [];
  my $out = $self->{chld_in};
  print $out encode('UTF-8', $txt) . $self->{sep};
  return $self;
};


# Initialize the tokenizer and bind the communication
sub _init {
  my $self = shift;
  $self->{select} = undef;

  # Open process
  if ($self->{pid} = open2(
    $self->{chld_out},
    $self->{chld_in},
    $self->{cmd}
  )) {
    $self->{select} = IO::Select->new;
    $self->{select}->add(*{$self->{chld_out}});
  }

  else {
    $log->error('Tokenizer can\'t be started');
  };
};


# Reset the inner state of the tokenizer
# and return the tokenizer object.
sub reset {
  my $self = shift;
  $self->close;
  $self->_init;
  return $self;
};


# Return data as a string
sub to_string {
  my ($self, $text_id) = @_;

  unless ($text_id) {
    $log->warn('Missing textID');
    return;
  };

  for (my $attempt = 1; $attempt <= RETRY_ATTEMPTS + 1; $attempt++) {
    my $output = eval { $self->_to_string_once($text_id) };
    return $output unless $@;

    my $err = $@;
    chomp $err;

    if ($attempt <= RETRY_ATTEMPTS && defined $self->{last_input}) {
      $log->warn(
        "External tokenizer failed for '$text_id' on attempt $attempt/" . (RETRY_ATTEMPTS + 1) .
        ' (' . $self->_input_context . "): $err. Restarting tokenizer and retrying"
      );

      $self->reset;
      last unless $self->{pid};
      $self->tokenize($self->{last_input});
      next;
    };

    $log->error(
      "Skipping tokenization for '$text_id' after $attempt/" . (RETRY_ATTEMPTS + 1) .
      ' attempts (' . $self->_input_context . "): $err"
    );
    $self->reset;
    return;
  };

  return;
};


sub _to_string_once {
  my ($self, $text_id) = @_;

  die 'Tokenizer is not available' unless $self->{select};

  my $output = $self->_header($text_id);
  my ($bounds, $sentence_bounds) = $self->_read_bounds;

  if ($self->{sentence_split}) {
    for (my $i = 0; $i < @{$sentence_bounds}; $i += 2) {
      push @{$self->{sentence_starts}}, $sentence_bounds->[$i];
      push @{$self->{sentence_endss}}, $sentence_bounds->[$i + 1];
    };
  }

  my $c = 0;
  for (my $i = 0; $i < @{$bounds}; $i += 2) {
    unless (
      defined $bounds->[$i + 1] &&
      looks_like_number($bounds->[$i]) &&
      looks_like_number($bounds->[$i + 1])
    ) {
      die 'Token bounds not numerical';
    };
    $output .= qq!    <span id="t_$c" from="! . $bounds->[$i] . '" to="' .
      $bounds->[$i + 1] . qq!" />\n!;
    $c++;
  };

  $self->_drain_output;
  return $output . $self->_footer;
};


sub _read_bounds {
  my $self = shift;

  unless ($self->{select}->can_read(WAIT_SECS)) {
    die "Timed out after " . WAIT_SECS . "s while waiting for token bounds";
  };

  my $out = $self->{chld_out};
  my $bounds_line = <$out>;
  unless (defined $bounds_line && $bounds_line ne '') {
    die $self->_read_error('token bounds');
  };

  my @sentence_bounds;
  if ($self->{sentence_split}) {
    my $sentence_bounds_line = <$out>;
    unless (defined $sentence_bounds_line && $sentence_bounds_line ne '') {
      die $self->_read_error('sentence bounds');
    };
    @sentence_bounds = split ' ', $sentence_bounds_line;
  };

  return ([split(' ', $bounds_line)], \@sentence_bounds);
};


sub _drain_output {
  my $self = shift;
  my $out = $self->{chld_out};

  while ($self->{select}->can_read(0)) {
    my $line = <$out>;

    if (defined $line && $line ne '') {

      # This warning is sometimes thrown, though not yet replicated
      # in the test suite. See the discussion in gerrit (3123:
      # Establish tokenizer object for external base tokenization)
      # for further issues.
      $log->warn("Extra output from external tokenizer: $line");
    }
    else {
      $log->warn('Tokenizer ended after responding, restarting for the next text');
      $self->reset;
      last;
    };
  };
};


sub _read_error {
  my ($self, $what) = @_;
  return "Reached EOF while reading $what from external tokenizer (pid=" .
    ($self->{pid} // 'n/a') . ')';
};


sub _input_context {
  my $self = shift;
  my $text = $self->{last_input} // '';
  return 'chars=' . length($text) . ', snippet="' . _snippet($text) . '"';
};


sub _snippet {
  my $text = shift // '';
  $text =~ s/\s+/ /g;
  $text =~ s/"/\\"/g;
  if (length($text) > LOG_SNIPPET_CHARS) {
    return substr($text, 0, LOG_SNIPPET_CHARS - 3) . '...';
  };
  return $text;
};


# Close communication channel
sub close {
  my $self = shift;
  close($self->{chld_in}) if defined $self->{chld_in};
  close($self->{chld_out}) if defined $self->{chld_out};
  $self->{chld_out} = $self->{chld_in} = undef;
  $self->{select} = undef;

  # Close the pid if still open
  if ($self->{pid}) {
    waitpid $self->{pid}, 0;
    $self->{pid} = undef;
  };
};


# Set sentence split option
sub sentence_splits {
  my ($self, $bool) = @_;
  $self->{sentence_split} = !!$bool;
};


sub sentencize_from_previous_input {
  my ($self, $structures) = @_;

  for (my $i=0; $i < @{$self->{sentence_starts}}; $i++) {
    my $anno = $structures->add_new_annotation('s');
    $anno->set_from($self->{sentence_starts}[$i]) or die $log->fatal('Sentence boundaries not numerical');
    $anno->set_to($self->{sentence_endss}[$i]) or die $log->fatal('Sentence boundaries not numerical');
    $anno->set_level(-1);
  }
  $self->{sentence_starts} = [];
  $self->{sentence_endss} = [];
}


1;
