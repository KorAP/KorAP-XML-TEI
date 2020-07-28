use strict;
use warnings;
use Test::More;
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('KorAP::XML::TEI::Tokenizer::Collector');

my $t = KorAP::XML::TEI::Tokenizer::Collector->new;

$t->add_token('x1',0,8);
my $token = $t->add_token('x2',9,14,2);
$t->add_token('x3',15,20);

my $loy = Test::XML::Loy->new($token->to_string(2));

$loy->attr_is('span', 'id', 's2')
  ->attr_is('span', 'from', 9)
  ->attr_is('span', 'to', 14)
  ->attr_is('span', 'l', 2)
  ->attr_is('span fs f', 'name', 'lex')
  ;

$loy = Test::XML::Loy->new($t->last_token->to_string(3));

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


done_testing;

