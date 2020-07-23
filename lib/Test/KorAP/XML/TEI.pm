package Test::KorAP::XML::TEI;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use Exporter 'import';

our @EXPORT_OK = qw(korap_tempfile);

use Env qw(KORAPXMLTEI_DONTUNLINK);

# Create a temporary file and file handle
# That will stay intact, if KORAPXMLTEI_DONTUNLINK is set to true.
sub korap_tempfile {
  my $pattern = shift;
  $pattern .= '_' if $pattern;

  # default: remove temp. file created by func. tempfile
  #  to keep temp. files use e.g. 'KORAPXMLTEI_DONTUNLINK=1 prove -lr t/script.t'
  return tempfile(
    'KorAP-XML-TEI_' . ($pattern // '') . 'XXXXXXXXXX',
    SUFFIX => '.tmp',
    TMPDIR => 1,
    UNLINK => $KORAPXMLTEI_DONTUNLINK ? 0 : 1
  )
};

1;
