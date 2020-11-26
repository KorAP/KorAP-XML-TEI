package KorAP::XML::TEI::Raw;
use strict;
use warnings;
use Log::Any qw($log);
use Encode qw(encode decode);
use KorAP::XML::TEI qw!escape_xml!;
use XML::CompactTree::XS;
use XML::LibXML::Reader;

# This is a collector class for primary data.
# It differs between raw text (buffered) and primary data.

sub new {
  my $class = shift;

  #  ~ whitespace handling ~
  #
  #  Every whitespace inside the processed text is 'significant' and recognized as a node of type 'XML_READER_TYPE_SIGNIFICANT_WHITESPACE'
  #   (see function 'retr_info()').
  #
  #  Definition of significant and insignificant whitespace
  #   (source: https://www.oracle.com/technical-resources/articles/wang-whitespace.html):
  #
  #   Significant whitespace is part of the document content and should be preserved.
  #   Insignificant whitespace is used when editing XML documents for readability.
  #    These whitespaces are typically not intended for inclusion in the delivery of the document.
  #
  bless [], $class;
};


# Add raw data
sub append {
  my ($self, $data) = @_;

  # ~ whitespace handling ~

  # The idea for the below code fragment was to fix (recreate) missing whitespace in a poorly created corpus, in which linebreaks where inserted
  #  into the text with the addition that maybe (or not) whitespace before those linebreaks was unintenionally stripped.
  #
  # It soon turned out, that it was best to suggest considering just avoiding linebreaks and putting all primary text tokens into one line (see
  #  example further down and notes on 'Input restrictions' in the manpage).
  #
  # Somehow an old first very poor approach remained, which is not stringent, but also doesn't affect one-line text.
  #
  # TODO: Maybe it's best, to keep the stripping of whitespace and to just remove the if-clause and to insert a blank by default (with possibly
  #  an option on how newlines in primary text should be handled (stripped or replaced by a whitespace)).
  #
  # Examples (how primary text with linebreaks would be converted by below code):
  #
  #  '...<w>end</w>\n<w>.</w>...' -> '...<w>end</w> <w>.</w>...'
  #  '...<w>,</w>\n<w>this</w>\n<w>is</w>\n<w>it</w>\n<w>!</w>...' -> '<w>,<w> <w>this</w> <w>is</w> <w>it</w> <w>!</w>'.

  # remove consecutive whitespace at beginning and end (mostly one newline)
  $data =~ s/^\s+//;
  $data =~ s/\s+$//;

  ### NOTE: this is only relevant, if a text consists of more than one line
  ### TODO: find a better solution, or create a warning, if a text has more than one line ($tl > 1)
  ###  do testing with 2 different corpora (one with only one-line texts, the other with several lines per text)
  if ($data =~ m/<[^>]+>[^<]/ ){ # line contains at least one tag with at least one character contents

    # NOTE: not stringent ('...' stands for text):
    #
    #   beg1............................end1  => no blank before 'beg1'
    #   beg2....<pb/>...................end2  => no blank before 'beg2'
    #   beg3....<info attr1="val1"/>....end3  => no blank before 'beg3'
    #   beg4....<test>ok</test>.........end4  =>    blank before 'beg4'
    #
    #     =>  beg1....end1beg2...<pb/>...end2beg3....<info attr1="val1"/>....end3 beg4...<test>ok</test>....end4
    #                                                                            ^
    #                                                                            |_blank between 'end3' and 'beg4'

    # $tl++; # counter for text lines

    # insert blank before 1st character (for 2nd line and consecutive lines)
    # s/^(.)/ $1/ if $tl > 1;
    if (@{$self->[1]}) {
      push @{$self->[1]}, ' ';
    };
  }
  ###

  # add line to buffer
  # $buf_in .= $_;
  push @{$self->[1]}, $data;
};


# Serializes the content of the raw buffer to a tree
# structure and collects clean data
sub to_tree {
  my ($self, $with_line_nr) = @_;

  # Switch to data phase
  $self->[0] = 1;

  my $reader = XML::LibXML::Reader->new(
    string =>  join('', '<text>', @{$seld->[1]}, '</text>'),
    huge => 1
  );

  my $param = XCT_DOCUMENT_ROOT | XCT_IGNORE_COMMENTS | XCT_ATTRIBUTE_ARRAY;

  # _XCT_LINE_NUMBERS is only for debugging
  $param |= XCT_LINE_NUMBERS if $with_line_nr;

  XML::CompactTree::XS::readSubtreeToPerl(
    $reader, $param
  );
};

1;
