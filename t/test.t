use strict;
use warnings;
use Test::More;

use_ok('Test::KorAP::XML::TEI','korap_tempfile');

my ($fh, $filename) = korap_tempfile('test');
ok($fh, 'Filehandle created');
ok($filename, 'Filename returned');
close($fh);

like($filename, qr!KorAP-XML-TEI_test_.+?\.tmp$!, 'Filename pattern');

($fh, $filename) = korap_tempfile();
ok($fh, 'Filehandle created');
ok($filename, 'Filename returned');
close($fh);

like($filename, qr!KorAP-XML-TEI_.+?\.tmp$!, 'Filename pattern');

done_testing;
