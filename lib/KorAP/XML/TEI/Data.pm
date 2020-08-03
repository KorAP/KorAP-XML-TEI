package KorAP::XML::TEI::Data;
use strict;
use warnings;
use Log::Any qw($log);
use Encode qw(encode decode);
use KorAP::XML::TEI qw!escape_xml_minimal!;

sub new {
  bless \(my $data = ''), shift;
};


# Return data as a string
sub to_string {
  my ($self, $text_id) = @_;

  unless ($text_id) {
    $log->warn('Missing textID');
    return;
  };

  my $out = $self->_header($text_id);
  $out .= '  <text>' . escape_xml_minimal($$self) . "</text>\n";
  return  $out . $self->_footer;
};


# Reset the inner state of the collector
# and return the collector object.
sub reset {
  ${$_[0]} = '';
  $_[0];
};


# Return serialized data
sub data {
  ${$_[0]};
};


# Append data to data stream
sub append {
  my $d = pop;
  # TODO:
  #   should not be necessary, because whitespace at the end of
  #   every input line is removed: see 'whitespace handling' inside
  #   text body
  # note:
  #   2 blanks - otherwise offset data would become corrupt
  $d =~ tr/\n\r/  /;

  ${$_[0]} .= $d;
};


# Return the current position in data stream
sub position {
  length(${$_[0]});
};


# Header for XML output
sub _header {
  my (undef, $text_id) = @_;

  # TODO:
  #   Can 'metadata.xml' change or is it constant?
  return <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="text.rng"
            type="application/xml"
            schematypens="http://relaxng.org/ns/structure/1.0"?>
<raw_text docid="$text_id"
          xmlns="http://ids-mannheim.de/ns/KorAP">
  <metadata file="metadata.xml" />
HEADER
};


# Footer for XML output
sub _footer {
  return '</raw_text>';
};


# Write data to zip stream
sub to_zip {
  my ($self, $zip, $text_id) = @_;

  # Encode and escape data
  # note: the index still refers to the 'single character'-versions,
  # which are counted as 1 (search for '&amp;' in data.xml and see
  # corresponding indices in $_tokens_file)
  $zip->print(encode('UTF-8', $self->to_string($text_id)));
};


1;
