package KorAP::XML::TEI::Zipper;
use strict;
use warnings;
use IO::Compress::Zip qw($ZipError :constants);

# man IO::Compress::Zip
# At present three compression methods are supported by IO::Compress::Zip, namely
# Store (no compression at all), Deflate, Bzip2 and LZMA.
# Note that to create Bzip2 content, the module "IO::Compress::Bzip2" must be installed.
# Note that to create LZMA content, the module "IO::Compress::Lzma" must be installed.

# The symbols ZIP_CM_STORE, ZIP_CM_DEFLATE, ZIP_CM_BZIP2 and
# ZIP_CM_LZMA are used to select the compression method.
our $_COMPRESSION_METHOD = ZIP_CM_DEFLATE;


# Construct a new zipper object. Accepts an optional
# Output parameter, that may be a file or a file handle.
# Defaults to stdout.
sub new {
  my ($class, $out) = @_;
  bless [$out // '-'], $class;
};


# Return a new data stream for Zips
sub new_stream {
  my ($self, $file) = @_;

  # No stream open currently
  unless ($self->[1]) {
    $self->[1] = IO::Compress::Zip->new(
      $self->[0],
      Zip64 => 1,
      TextFlag => 1,
      Method => $_COMPRESSION_METHOD,
      Append => 0,
      Name => "$file"
    ) or die "ERROR ('$file'): zip failed: $ZipError\n"
  }

  # Close existing stream and open a new one
  else {
    $self->[1]->newStream(
      Zip64 => 1,
      TextFlag => 1,
      Method => $_COMPRESSION_METHOD,
      Append => 1,
      Name => "$file"
    ) or die "ERROR ('$file'): zip failed: $ZipError\n"
  };

  return $self->[1];
};


# Close stream and reset zipper
sub close {
  $_[0]->[1]->close;
  @{$_[0]} = ($_[0]->[0]);
};


1;