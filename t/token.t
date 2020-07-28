use strict;
use warnings;
use Test::More;
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('KorAP::XML::TEI::Tokenizer::Token');

subtest 'Initialization' => sub {
  my $t = KorAP::XML::TEI::Tokenizer::Token->new;

  ok(!defined($t->from), 'Undefined from');
  ok(!defined($t->to), 'Undefined to');
  ok(!defined($t->level), 'Undefined level');

  $t->add_attribute('foo' => 'bar');
  $t->add_attribute('x' => 'y');
  $t->set_from(7);
  $t->set_to(5);
  $t->set_from(4);

  my $loy = Test::XML::Loy->new($t->to_string(3));

  $loy->attr_is('span', 'id', 's3')
    ->attr_is('span', 'from', 4)
    ->attr_is('span', 'to', 5)
    ->attr_is('span fs f', 'name', 'lex')
    ->attr_is('span fs f fs f:nth-of-type(1)', 'name', 'foo')
    ->text_is('span fs f fs f:nth-of-type(1)', 'bar')
    ->attr_is('span fs f fs f:nth-of-type(2)', 'name', 'x')
    ->text_is('span fs f fs f:nth-of-type(2)', 'y')
    ;

  is($t->from,4);
  is($t->to,5);
  is($t->level,undef);
  $t->set_level(19);
  is($t->level,19);

  $loy = Test::XML::Loy->new($t->to_string(3));

  $loy->attr_is('span', 'id', 's3')
    ->attr_is('span', 'from', 4)
    ->attr_is('span', 'to', 5)
    ->attr_is('span', 'l', 19)
    ;
};


subtest 'Test inline annotations' => sub {
  my $t = KorAP::XML::TEI::Tokenizer::Token->new('x1', 0, 6);
  $t->add_attribute('ana' => 'DET @PREMOD');
  $t->add_attribute('lemma' => 'C & A');

  my $loy = Test::XML::Loy->new($t->to_string(1));

  $loy->attr_is('span', 'id', 's1')
    ->attr_is('span', 'to', 6)
    ->attr_is('span > fs > f > fs f:nth-of-type(1)', 'name', 'ana')
    ->text_is('span > fs > f > fs f:nth-of-type(1)', 'DET @PREMOD')
    ->attr_is('span > fs > f > fs f:nth-of-type(2)', 'name', 'lemma')
    ->text_is('span > fs > f > fs f:nth-of-type(2)', 'C & A')
    ;

  $loy = Test::XML::Loy->new($t->to_string_with_inline_annotations(1));

  $loy->attr_is('span', 'id', 's1')
    ->attr_is('span', 'to', 6)
    ->attr_is('span > fs > f > fs f:nth-of-type(1)', 'name', 'pos')
    ->text_is('span > fs > f > fs f:nth-of-type(1)', 'DET')
    ->attr_is('span > fs > f > fs f:nth-of-type(2)', 'name', 'msd')
    ->text_is('span > fs > f > fs f:nth-of-type(2)', '@PREMOD')
    ->attr_is('span > fs > f > fs f:nth-of-type(3)', 'name', 'lemma')
    ->text_is('span > fs > f > fs f:nth-of-type(3)', 'C & A')
};


done_testing;

