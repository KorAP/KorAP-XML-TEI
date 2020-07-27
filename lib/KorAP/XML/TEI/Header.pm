package KorAP::XML::TEI::Header;
use strict;
use warnings;
use Encode qw(encode_utf8);

# Parsing of i5 header files

# Warning:
# Opening and closing tags (without attributes) have to be in one line

my $_HEADER_TAG = 'idsHeader';

use constant {
  TEXT      => 0,
  SIGTYPE   => 1,
  HEADTYPE  => 2,
  SIGLE     => 3
};

# convert '&', '<' and '>' into their corresponding sgml-entities
our %ent = (
  '"' => '&quot;',
  '&' => '&amp;',
  '<' => '&lt;',
  '>' => '&gt;'
);

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

  my $self = bless [$text, undef, '', ''], $class;

  # Check header types to distinguish between siglen types
  if ($text =~ /^\<${_HEADER_TAG}\stype=\"([^"]+?)\"/) {
    $self->[HEADTYPE] = $1;
  }

  # Unexpected header init
  else {
    die "ERROR ($0): Unable to parse header init '$text'";
    return;
  };

  return $self;
};


# Parse header object from filehandle
sub parse {
  my ($self, $fh) = @_;

  my $sig_type = $sig{$self->[HEADTYPE]} // 'textSigle';

  # Iterate over file handle
  while (<$fh>) {

    # Change:
    #   This version keeps comments in header files

    # End of header found - finish parsing
    if ( m#^(.*</${_HEADER_TAG}>)(.*)$# ){

      # Add to text
      $self->[TEXT] .= $1;

      die "ERROR ($0): main(): input line number $.: line with closing header tag '${_HEADER_TAG}'"
        ." contains additional information ... => Aborting\n\tline=$_"
        if $2 !~ /^\s*$/;

      if ($self->dir eq '') {

        print STDERR "WARNING ($0): main(): input line number $.: empty " . $sig_type .
          " in header => nothing to do ...\n header=" . $self->[TEXT] . "\n";
        return;

      };

      return $self;
    };

    # Check for sigle in line
    if ( m#^(.*)<$sig_type(?: [^>]*)?>([^<]*)(.*)$# ){

      my $pfx = $1;
      my $sig = $2;
      my $sfx = $3;

      die "ERROR ($0): main(): input line number $.: line with sigle-tag is not in expected format ... => Aborting\n\tline=$_"
        if $pfx !~ /^\s*$/  || $sfx !~ m#^</$sig_type>\s*$# || $sig =~ /^\s*$/;

      $self->[SIGLE] = encode_utf8($sig);

      # Escape sig
      $sig = $self->sigle_esc;

      # Replace line with new dir
      # Change:
      #   This now also replaces the sig even if no escaping was taken place,
      #   so that the change "/" -> _ takes effect
      s#(<$sig_type(?: [^>]*)?>)[^<]+</$sig_type>#$1$sig</$sig_type>#;
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
  $_[0]->[SIGLE] =~ s/("|&|<|>)/$ent{$1}/gr;
};


# corpus/doc/text id escaped
sub id_esc {
  $_[0]->[SIGLE] =~ tr/\//_/r =~ s/("|&|<|>)/$ent{$1}/gr;
};


# Return data as a string
sub to_string {
  my $self = shift;
  return $self->_header . $self->[TEXT];
};


# Header for XML output
sub _header {
  my $self = shift;
  ## TODO: remove this, because it's IDS-specific
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
  $zip->print(encode_utf8($self->to_string));
};


1;

