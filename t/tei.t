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

done_testing;
