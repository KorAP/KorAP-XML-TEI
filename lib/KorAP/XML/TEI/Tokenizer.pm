package KorAP::XML::TEI::Tokenizer;
use strict;
use warnings;
use Log::Any qw($log);

# This is the base class for tokenizer objects.

# Construct a new tokenizer
sub new {
  bless [], shift;
};


# Reset the inner state of the tokenizer
# and return the tokenizer object.
sub reset {
  @{$_[0]} = ();
  $_[0];
};


# Return boundaries
sub boundaries {
  @{$_[0]};
};


# Return data as a string
sub to_string {
  my ($self, $text_id) = @_;

  unless ($text_id) {
    $log->warn('Missing textID');
    return;
  };

  my $output = $self->_header($text_id);

  my $c = 0;
  for (my $i = 0; $i < ($#$self + 1); $i +=  2 ){
    $output .= qq!    <span id="t_$c" from="! . $self->[$i] . '" to="' .
      $self->[$i+1] . qq!" />\n!;
    $c++;
  }

  return $output . $self->_footer;
};


# Write data to zip stream
sub to_zip {
  my ($self, $zip, $text_id) = @_;
  $zip->print($self->to_string($text_id));
};


# Header for XML output
sub _header {
  my ($self, $text_id) = @_;
  return <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="span.rng"
            type="application/xml"
            schematypens="http://relaxng.org/ns/structure/1.0"?>
<layer docid="$text_id"
       xmlns="http://ids-mannheim.de/ns/KorAP"
       version="KorAP-0.4">
  <spanList>
HEADER
};


# Footer for XML output
sub _footer {
  "  </spanList>\n</layer>";
};


1;
