package KorAP::XML::TEI::Annotations;
use strict;
use warnings;
use Encode qw(encode);
use Log::Any qw($log);

# This is the base class for Annotation objects.

# Construct a new annotation collector
sub new {
  bless [], shift;
};


# Reset the inner state of the annotation collection
# and return the annotation object.
sub reset {
  @{$_[0]} = ();
  $_[0];
};


# Return boundaries of annotations
sub boundaries {
  @{$_[0]};
};


# Check if no annotations are stored
sub empty {
  return @{$_[0]} > 0 ? 0 : 1
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
  my ($self, $zip, $text_id, $param) = @_;
  $zip->print(encode('UTF-8', $self->to_string($text_id, $param)));
  return $self;
};


# Header for XML output
sub _header {
  my (undef, $text_id) = @_;
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
