use strict;
use warnings;
use Test::More;
use Test::XML::Loy;

use_ok('KorAP::XML::TEI::Data');

my $d = KorAP::XML::TEI::Data->new;

ok($d, 'Constructed');

is($d->position, 0, 'Position');
ok($d->append('aaa'), 'Add raw data');
is($d->position, 3, 'Position');
ok($d->reset, 'Reset');
is($d->position, 0, 'Position');


ok($d->append('  Dies ist '), 'Add raw data');
is($d->position, 11, 'Position');
ok($d->append("Ein Versuch\n"), 'Add raw data');
is($d->position, 23, 'Position');

my $loy = Test::XML::Loy->new($d->to_string('x'));

$loy->attr_is('raw_text', 'docid', 'x')
  ->text_is('raw_text text', '  Dies ist Ein Versuch ');

done_testing;
