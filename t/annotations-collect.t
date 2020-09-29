use strict;
use warnings;
use Test::More;
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('KorAP::XML::TEI::Annotations::Collector');
use_ok('KorAP::XML::TEI::Annotations::Annotation');

my $t = KorAP::XML::TEI::Annotations::Collector->new;

$t->add_new_annotation('x1',0,8);
my $token = $t->add_new_annotation('x2',9,14,2);
$t->add_new_annotation('x3',15,20);

my $loy = Test::XML::Loy->new($token->to_string(2));

$loy->attr_is('span', 'id', 's2')
  ->attr_is('span', 'from', 9)
  ->attr_is('span', 'to', 14)
  ->attr_is('span', 'l', 2)
  ->attr_is('span fs f', 'name', 'lex')
  ;

$loy = Test::XML::Loy->new($t->[-1]->to_string(3));

$loy->attr_is('span', 'id', 's3')
  ->attr_is('span', 'from', 15)
  ->attr_is('span', 'to', 20)
  ->attr_is('span fs f', 'name', 'lex')
;

$loy = Test::XML::Loy->new($t->to_string('text', 0))
  ->attr_is('layer', 'docid', 'text')
  ->attr_is('span#s0', 'to', '8')
  ->attr_is('span#s1', 'to', '14')
  ->attr_is('span#s1', 'l', '2')
  ->attr_is('span#s2', 'to', '20')
;

my $anno = KorAP::XML::TEI::Annotations::Annotation->new('x4', 20 => 21);

$t->add_annotation($anno);

$loy = Test::XML::Loy->new($t->to_string('text',0))
  ->attr_is('layer', 'docid', 'text')
  ->attr_is('span#s0', 'to', '8')
  ->attr_is('span#s1', 'to', '14')
  ->attr_is('span#s1', 'l', '2')
  ->attr_is('span#s2', 'to', '20')
  ->attr_is('span#s3', 'from', '20')
  ->attr_is('span#s3', 'to', '21')
;

done_testing;

