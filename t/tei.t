use strict;
use warnings;
use Test::More;
use Test::KorAP::XML::TEI qw!korap_tempfile!;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('KorAP::XML::TEI', 'remove_xml_comments');

my ($fh, $filename) = korap_tempfile('tei');

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
