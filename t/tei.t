use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

require_ok('KorAP::XML::TEI');

my ($fh, $filename) = tempfile();

print $fh <<'HTML';
mehrzeiliger
Kommentar
  -->
Test
HTML

is(KorAP::XML::TEI::delHTMLcom($fh, "hallo"),"hallo");
is(KorAP::XML::TEI::delHTMLcom($fh, "hallo <!-- Test -->"),"hallo ");
is(KorAP::XML::TEI::delHTMLcom($fh, "<!-- Test --> hallo")," hallo");

seek($fh, 0, 0);

is(KorAP::XML::TEI::delHTMLcom($fh, '<!--'), "Test\n");

seek($fh, 0, 0);

print $fh <<'HTML';
mehrzeiliger
Kommentar
  --><!-- Versuch
-->ist <!-- a --><!-- b --> ein Test
HTML

seek($fh, 0, 0);

is(KorAP::XML::TEI::delHTMLcom($fh, 'Dies <!--'), "Dies ist  ein Test");


done_testing;
