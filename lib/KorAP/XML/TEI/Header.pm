package KorAP::XML::TEI::Header;
use strict;
use warnings;
use Log::Any qw($log);
use Encode qw(encode decode);
use KorAP::XML::TEI qw!escape_xml!;
use KorAP::XML::TEI qw!remove_xml_comments replace_entities!;

# Parsing of i5 header files

# Warning:
# Opening and closing tags (without attributes) have to be in one line

use constant {
  TEXT      => 0,
  HEADTYPE  => 1,
  SIGLE     => 2,
  INPUTENC  => 3,
  HEADTAG   => 4
};


# convert header type to sigle type
our %sig = (
  corpus   => 'korpusSigle',
  doc      => 'dokumentSigle',
  document => 'dokumentSigle',
  text     => 'textSigle'
);


# Create new header object
sub new {
  my ($class, $text, $input_enc, $text_id_esc) = @_;

  my $self = bless [$text, undef, '', $input_enc // 'UTF-8', 'idsHeader'], $class;

  if ($text_id_esc) {
    $self->[SIGLE] = $text_id_esc;
  };

  # Expect teiHeader
  if ($text =~ m!<teiHeader\b!) {
    $self->[HEADTYPE] = 'text';
    $self->[HEADTAG]  = 'teiHeader';
  }

  # Check header types to distinguish between siglen types
  elsif ($text =~ m!^<idsHeader\s+[^>]*?type="([^"]+)"!) {
    $self->[HEADTYPE] = $1;

    unless (exists $sig{$1}) {
      $log->error("Unknown header type '$1' - treated as textSigle");
    };
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
  my $l = length('</' . $self->[HEADTAG]) + 1;

  # Iterate over file handle
  while (<$fh>) {

    $_ = decode($self->[INPUTENC], $_);
    $_ = replace_entities($_);

    # Change:
    #   This version keeps comments in header files

    # End of header found - finish parsing
    if (($pos = index($_, '</' . $self->[HEADTAG])) >= 0) {

      # Add to text
      $self->[TEXT] .= substr($_, 0, $l + $pos);

      die $log->fatal(q!Line with tag '</! . $self->[HEADTAG] . q!>' (L$.) contains additional information!)
        if substr($_, $l + $pos) !~ /^\s*$/;

      if ($self->dir eq '') {
        $log->error("Empty '<$sig_type />' (L$.) in header");
        return;
      };

      return $self;
    };

    # Check for sigle in line
    if (index($_, '<' . $sig_type) >= 0) {

      unless (m!^\s*<$sig_type[^>]*>([^<./]+(?:[/_][^<./]+(?:[./][^<./]+)?)?)?</$sig_type>\s*$!) {
        die $log->fatal("line with '<$sig_type />' (L$.) is not in expected format: $_");
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


# Directory (leveled) of the header file as UTF-8
sub dir {
  $_[0]->[SIGLE] =~ tr/\./\//r;
};


# corpus/doc/text sigle - as UTF-8
sub sigle {
  $_[0]->[SIGLE];
};


# corpus/doc/text id
sub id {
  decode('UTF-8', $_[0]->[SIGLE] =~ tr/\//_/r);
};


# corpus/doc/text sigle escaped - as UTF-8
sub sigle_esc {
  escape_xml($_[0]->[SIGLE]);
};


# corpus/doc/text id escaped
sub id_esc {
  escape_xml($_[0]->id);
};


# Return data as a string
sub to_string {
  return $_[0]->_header . $_[0]->[TEXT];
};


# Header for XML output
sub _header {
  # TODO: IDS-specific
  return <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
HEADER
};


# Write data to zip stream
sub to_zip {
  my ($self, $zip) = @_;
  $zip->print(encode('UTF-8', $self->to_string));
  return $self;
};


1;

