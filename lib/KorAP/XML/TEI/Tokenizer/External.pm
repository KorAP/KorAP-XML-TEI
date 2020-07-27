package KorAP::XML::TEI::Tokenizer::External;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;
use IO::Select;
use IPC::Open2 qw(open2);

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

  # e.g. 'java  -cp '. join(':', '.', glob(dirname(__FILE__) . "/../target/*.jar")).
  #      " de.ids_mannheim.korap.tokenizer.KorAPTokenizerImpl"

  unless ($cmd) {
    print STDERR "WARNING: tokenizer not established.\n";
    return;
  };

  # Send this sequence to separate inputs
  # TODO: needs to be explored furthermore ...
  #   '\x03' produces a warning in 't/tokenization-external.t' (WARNING: extra output: 0 1)
  #   - see discussion in gerrit (3123: Establish tokenizer object for external base tokenization)
  #   an empty $sep leads to a blocking situation inside t/cmd/tokenizer.pl (right before the while-loop)
  #$sep //= "\n\x03\n";
  $sep //= "\n";

  my $self = bless {
    chld_in  => undef,
    chld_out => undef,
    pid      => undef,
    cmd      => $cmd,
    select   => undef,
    sep      => $sep,
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
  print $out $txt . $self->{sep};
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
    print STDERR "WARNING: tokenizer can't be started.\n";
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
    warn 'Missing textID';
    return;
  };

  return '' unless $self->{select};

  # Start header
  my $output = $self->_header($text_id);

  # TODO:
  #   Escape the stringification of cmd.
  $output .= '    <!-- ' . $self->{cmd} . " -->\n";

  # Wait 60m for the external tokenizer
  if ($self->{select}->can_read(WAIT_SECS)) {

    my $out = $self->{chld_out};
    $_ = <$out>;

    my @bounds = split;

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
        print STDERR "WARNING: extra output: $_\n"
      }
      else {
        print STDERR "WARNING: tokenizer seems to have crashed, restarting.\n";
        $self->reset;
      };
    };
  }

  else {
    die "ERROR ($0): cannot retrieve token bounds from external tokenizer for text '$text_id' => Aborting ...\n";
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


1;
