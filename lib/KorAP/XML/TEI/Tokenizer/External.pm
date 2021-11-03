package KorAP::XML::TEI::Tokenizer::External;
use base 'KorAP::XML::TEI::Annotations';
use strict;
use warnings;
use Log::Any qw($log);
use IO::Select;
use IPC::Open2 qw(open2);
use Encode qw(encode);

# This tokenizer starts an external process for
# tokenization. It writes the data to tokenize
# to STDIN and reads boundary data from STDOUT.

use constant {
  WAIT_SECS => 3600
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
      sentence_starts => [],
      sentence_ends   => [],
  }, $class;

  # Initialize tokenizer
  $self->_init;
  return $self;
};


# Tokenize text in an external process
sub tokenize {
  my ($self, $txt) = @_;
  return unless $self->{pid};
  my $out = $self->{chld_in};
  print $out encode('UTF-8', $txt) . $self->{sep};
  return $self;
};


# Initialize the tokenizer and bind the communication
sub _init {
  my $self = shift;

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

  return '' unless $self->{select};

  # Start header
  my $output = $self->_header($text_id);

  # Wait 60m for the external tokenizer
  if ($self->{select}->can_read(WAIT_SECS)) {

    my $out = $self->{chld_out};
    $_ = <$out>;
    my @bounds = split;

    if ($self->{sentence_split}) {
      # sentence boundaries will be on a second line
      $_ = <$out>;
      my @sentence_bounds = split;

      # Save all sentence bounds
      for (my $i = 0; $i < @sentence_bounds; $i +=  2 ) {
        push @{$self->{sentence_starts}}, $sentence_bounds[$i];
        push @{$self->{sentence_endss}}, $sentence_bounds[$i+1];
      };
    }

    # Serialize all bounds
    my $c = 0;
    for (my $i = 0; $i < @bounds; $i +=  2 ){
      $output .= qq!    <span id="t_$c" from="! . $bounds[$i] . '" to="' .
        $bounds[$i+1] . qq!" />\n!;
      $c++;
    };

    while ($self->{select}->can_read(0)) {
      $_ = <$out>;

      if (defined $_ && $_ ne '') {

        # This warning is sometimes thrown, though not yet replicated
        # in the test suite. See the discussion in gerrit (3123:
        # Establish tokenizer object for external base tokenization)
        # for further issues.
        $log->warn("Extra output: $_");
      }
      else {
        $log->warn('Tokenizer seems to have crashed, restarting');
        $self->reset;
      };
    };
  }

  else {
    die $log->fatal("Can\'t retrieve token bounds from external tokenizer ('$text_id')");
  };

  # Add footer
  return $output . $self->_footer;
};


# Close communication channel
sub close {
  my $self = shift;
  close($self->{chld_in});
  close($self->{chld_out});
  $self->{chld_out} = $self->{chld_in} = undef;

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
    my $anno = $structures->add_new_annotation("s");
    $anno->set_from($self->{sentence_starts}[$i]);
    $anno->set_to($self->{sentence_endss}[$i]);
    $anno->set_level(-1);
  }
  $self->{sentence_starts} = [];
  $self->{sentence_endss} = [];
}


1;
