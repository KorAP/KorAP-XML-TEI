use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

our %ENV;
# default: remove temp. file created by func. tempfile
#  to keep temp. files use e.g. 'KORAPXMLTEI_DONTUNLINK=1 prove -lr t/script.t'
my $_UNLINK = $ENV{KORAPXMLTEI_DONTUNLINK}?0:1;

use_ok('KorAP::XML::TEI', 'remove_xml_comments');

my ($fh, $filename) = tempfile("KorAP-XML-TEI_tei_XXXXXXXXXX", SUFFIX => ".tmp", TMPDIR => 1, UNLINK => $_UNLINK);

print $fh <<'HTML';
mehrzeiliger
Kommentar
  -->
Test
HTML

is(remove_xml_comments($fh, "hallo"),"hallo");
is(remove_xml_comments($fh, "hallo <!-- Test -->"),"hallo ");
is(remove_xml_comments($fh, "<!-- Test --> hallo")," hallo");

seek($fh, 0, 0);

is(remove_xml_comments($fh, '<!--'), "Test\n");

seek($fh, 0, 0);

print $fh <<'HTML';
mehrzeiliger
Kommentar
  --><!-- Versuch
-->ist <!-- a --><!-- b --> ein Test
HTML

seek($fh, 0, 0);

is(remove_xml_comments($fh, 'Dies <!--'), "Dies ist  ein Test\n");

close($fh);

done_testing;
