use strict;
use warnings;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::More;
use Test::XML::Loy;
use_ok('KorAP::XML::TEI::Inline');


my $inline = KorAP::XML::TEI::Inline->new;

ok($inline->parse('aaa', \'Der <b>alte</b> Mann'), 'Parsed');

is($inline->data->data, 'Der alte Mann');

Test::XML::Loy->new($inline->structures->to_string('aaa', 2))
  ->attr_is('#s0', 'l', "1")
  ->attr_is('#s0', 'to', 13)
  ->text_is('#s0 fs f[name=name]', 'text')
  ->attr_is('#s1', 'l', "2")
  ->attr_is('#s1', 'from', 4)
  ->attr_is('#s1', 'to', 8)
  ->text_is('#s1 fs f[name=name]', 'b')
  ;

Test::XML::Loy->new($inline->tokens->to_string('aaa', 0))
  ->element_exists_not('fs')
  ;


ok($inline->parse('aaa', \'<w>Die</w> <w>alte</w> <w>Frau</w>'), 'Parsed');

is($inline->data->data, 'Die alte Frau');

Test::XML::Loy->new($inline->structures->to_string('aaa', 2))
  ->attr_is('#s0', 'l', "1")
  ->attr_is('#s0', 'to', 13)
  ->text_is('#s0 fs f[name=name]', 'text')

  ->attr_is('#s1', 'l', "2")
  ->attr_is('#s1', 'to', 3)
  ->text_is('#s1 fs f[name=name]', 'w')

  ->attr_is('#s2', 'l', "2")
  ->attr_is('#s2', 'from', 4)
  ->attr_is('#s2', 'to', 8)
  ->text_is('#s2 fs f[name=name]', 'w')

  ->attr_is('#s3', 'l', "2")
  ->attr_is('#s3', 'from', 9)
  ->attr_is('#s3', 'to', 13)
  ->text_is('#s3 fs f[name=name]', 'w')
  ;

Test::XML::Loy->new($inline->tokens->to_string('aaa', 0))
  ->attr_is('#s0', 'l', "2")
  ->attr_is('#s0', 'to', 3)

  ->attr_is('#s1', 'l', "2")
  ->attr_is('#s1', 'from', 4)
  ->attr_is('#s1', 'to', 8)

  ->attr_is('#s2', 'l', "2")
  ->attr_is('#s2', 'from', 9)
  ->attr_is('#s2', 'to', 13)
  ;

ok($inline->parse('aaa', \'<w lemma="die" type="det">Die</w> <w
 lemma="alt" type="ADJ">alte</w> <w lemma="frau" type="NN">Frau</w>'), 'Parsed');

is($inline->data->data, 'Die alte Frau');

Test::XML::Loy->new($inline->tokens->to_string('aaa', 1))
  ->attr_is('#s0', 'l', "2")
  ->attr_is('#s0', 'to', 3)
  ->text_is('#s0 fs f[name="lemma"]', 'die')
  ->text_is('#s0 fs f[name="type"]', 'det')

  ->attr_is('#s1', 'l', "2")
  ->attr_is('#s1', 'from', 4)
  ->attr_is('#s1', 'to', 8)
  ->text_is('#s1 fs f[name="lemma"]', 'alt')
  ->text_is('#s1 fs f[name="type"]', 'ADJ')

  ->attr_is('#s2', 'l', "2")
  ->attr_is('#s2', 'from', 9)
  ->attr_is('#s2', 'to', 13)
  ->text_is('#s2 fs f[name="lemma"]', 'frau')
  ->text_is('#s2 fs f[name="type"]', 'NN')
  ;


done_testing;
