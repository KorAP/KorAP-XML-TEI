package KorAP::XML::TEI::Header;
use strict;
use warnings;
use Log::Any qw($log);
use Encode qw(encode decode);
use KorAP::XML::TEI qw!escape_xml!;

# Parsing of i5 header files

# Warning:
# Opening and closing tags (without attributes) have to be in one line

# TODO: IDS-specific
my $_HEADER_TAG = 'idsHeader';

use constant {
  TEXT      => 0,
  HEADTYPE  => 1,
  SIGLE     => 2
};


# convert header type to sigle type
our %sig = (
  corpus   => 'korpusSigle',
  document => 'dokumentSigle',
  text     => 'textSigle'
);


# Create new header object
sub new {
  my $class = shift;
  my $text = shift;

  my $self = bless [$text, undef, ''], $class;

  # Check header types to distinguish between siglen types
  if ($text =~ m!^<${_HEADER_TAG}\s+[^<]*type="([^"]+)"!) {
    $self->[HEADTYPE] = $1;
  }

  # Unexpected header init
  else {
    die $log->fatal("Unable to parse header init '$text'");
    return;
  };

  return $self;
};


# Parse header object from filehandle
sub parse {
  my ($self, $fh) = @_;

  my $sig_type = $sig{$self->[HEADTYPE]} // 'textSigle';

  my $pos;
  my $l = length('</' . $_HEADER_TAG) + 1;

  # Iterate over file handle
  while (<$fh>) {

    # Change:
    #   This version keeps comments in header files

    # End of header found - finish parsing
    if (($pos = index($_, '</' . $_HEADER_TAG)) >= 0) {

      # Add to text
      $self->[TEXT] .= substr($_, 0, $l + $pos);

      die $log->fatal("Line with tag '</${_HEADER_TAG}>' (L$.) contains additional information")
        if substr($_, $l + $pos) !~ /^\s*$/;

      if ($self->dir eq '') {
        $log->error("Empty '<$sig_type />' (L$.) in header");
        return;
      };

      return $self;
    };

    # Check for sigle in line
    if (index($_, '<' . $sig_type) >= 0) {

      unless (m!^\s*<$sig_type[^>]*>([^<]*)</$sig_type>\s*$!) {
        die $log->fatal("line with '<$sig_type />' (L$.) is not in expected format");
      };

      $self->[SIGLE] = encode('UTF-8' , $1);

      # Escape sig
      my $sig_esc = decode('UTF-8', $self->sigle_esc);

      # replace sigle in header, if there's an escaped version that differs
      s!$1</$sig_type>!$sig_esc</$sig_type>! if $sig_esc ne $1;
    };

    # Add line to header text
    $self->[TEXT] .= $_;
  };
};


# Type of the header
sub type {
  $_[0]->[HEADTYPE];
};


# Directory (leveled) of the header file
sub dir {
  $_[0]->[SIGLE] =~ tr/\./\//r;
};


# corpus/doc/text sigle
sub sigle {
  $_[0]->[SIGLE];
};


# corpus/doc/text id
sub id {
  $_[0]->[SIGLE] =~ tr/\//_/r;
};


# corpus/doc/text sigle escaped
sub sigle_esc {
  escape_xml($_[0]->[SIGLE]);
};


# corpus/doc/text id escaped
sub id_esc {
  escape_xml($_[0]->[SIGLE] =~ tr/\//_/r);
};


# Return data as a string
sub to_string {
  my $self = shift;
  return $self->_header . $self->[TEXT];
};


# Header for XML output
sub _header {
  my $self = shift;
  # TODO: IDS-specific
  return <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="header.rng"
            type="application/xml"
            schematypens="http://relaxng.org/ns/structure/1.0"?>
<!DOCTYPE idsCorpus PUBLIC "-//IDS//DTD IDS-XCES 1.0//EN"
          "http://corpora.ids-mannheim.de/idsxces1/DTD/ids.xcesdoc.dtd">
HEADER
};


# Write data to zip stream
sub to_zip {
  my ($self, $zip) = @_;
  $zip->print(encode('UTF-8', $self->to_string));
};


1;

