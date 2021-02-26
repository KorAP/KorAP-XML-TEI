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

subtest 'Examples from documentation' => sub {
  plan skip_all => 'Expected behaviour not finalized';

  # From the documentation:
  #
  # Example:
  # '... <head type="main"><s>Campagne in Frankreich</s></head><head type="sub"> <s>1792</s> ...'

  # Two text-nodes should normally be separated by a blank.
  # In the above example, that would be the 2 text-nodes
  # 'Campagne in Frankreich' and '1792', which are separated
  # by the whitespace-node ' ' (see [2]).
  #
  # The text-node 'Campagne in Frankreich' leads to the setting
  # of '$add_one' to 1, so that when opening the 2nd 'head'-tag,
  # it's from-index gets set to the correct start-index of '1792'
  # (and not to the start-index of the whitespace-node ' ').
  #
  # The assumption here is, that in most cases there _is_ a
  # whitespace node between 2 text-nodes. The below code fragment
  # enables a way, to check, if this really _was_ the case for
  # the last 2 'non-tag'-nodes, when closing a tag:
  #
  # When a whitespace-node is read, its from-index is stored
  # as a hash-key (in %ws), to state that it belongs to a ws-node.
  # So when closing a tag, it can be checked, if the previous
  # 'non-tag'-node (text or whitespace), which is the one before
  # the last read 'non-tag'-node, was a actually _not_ a ws-node,
  # but instead a text-node. In that case, the from-value of
  # the last read 'non-tag'-node has to be corrected (see [1]),
  #
  # For whitespace-nodes $add_one is set to 0, so when opening
  # the next tag (in the above example the 2nd 's'-tag), no
  # additional 1 is added (because this was already done by the
  # whitespace-node itself when incrementing the variable $pos).
  #
  # [1]
  # Now, what happens, when 2 text-nodes are _not_ seperated by a
  # whitespace-node (e.g.: <w>Augen<c>,</c></w>)?
  # In this case, the falsely increased from-value has to be
  # decreased again by 1 when closing the enclosing tag
  # (see above code fragment '... not exists $ws{ $from - 1 } ...').
  #
  # [2]
  # Comparing the 2 examples '<w>fu</w> <w>bar</w>' and
  # '<w>fu</w><w> </w><w>bar</w>', is ' ' in both cases handled as a
  # whitespace-node (XML_READER_TYPE_SIGNIFICANT_WHITESPACE).
  #
  # The from-index of the 2nd w-tag in the second example refers to
  # 'bar', which may not have been the intention
  # (even though '<w> </w>' doesn't make a lot of sense).
  # TODO: could this be a bug?
  #
  # Empty tags also cling to the next text-token - e.g. in
  # '<w>tok1</w> <w>tok2</w><a><b/></a> <w>tok3</w>' are the from-
  # and to-indizes for the tags 'a' and 'b' both 12,
  # which is the start-index of the token 'tok3'.

  ok($inline->parse(
    'bbb',
    \'<head type="main"><s>Campagne in Frankreich</s></head><head type="sub"> <s>1792</s></head>'),'Parsed');
  is($inline->data->data, 'Campagne in Frankreich 1792');

  Test::XML::Loy->new($inline->structures->to_string('aaa', 2))
      ->attr_is('#s0', 'l', "1")
      ->attr_is('#s0', 'to', 27)
      ->text_is('#s0 fs f[name="name"]', 'text')

      ->attr_is('#s1', 'l', "2")
      ->attr_is('#s1', 'to', 22)
      ->text_is('#s1 fs f[name="name"]', 'head')
      ->text_is('#s1 fs f[name="attr"] fs f[name=type]', 'main')

      ->attr_is('#s2', 'l', "3")
      ->attr_is('#s2', 'to', 22)
      ->text_is('#s2 fs f[name="name"]', 's')

      ->attr_is('#s3', 'l', "2")
      ->attr_is('#s3', 'from', 23)
      ->attr_is('#s3', 'to', 27)
      ->text_is('#s3 fs f[name="name"]', 'head')
      ->text_is('#s3 fs f[name="attr"] fs f[name=type]', 'sub')

      ->attr_is('#s4', 'l', "3")
      ->attr_is('#s4', 'from', 23)
      ->attr_is('#s4', 'to', 27)
      ->text_is('#s4 fs f[name="name"]', 's')
      ;

  ok($inline->parse(
    'ccc',
    \'<w>tok1</w> <w>tok2</w><a><b/></a> <w>tok3</w>'
  ), 'Parsed');
  is($inline->data->data, 'tok1 tok2 tok3');

  Test::XML::Loy->new($inline->structures->to_string('ccc', 2))
      ->attr_is('#s0', 'l', "1")
      ->attr_is('#s0', 'to', 14)
      ->text_is('#s0 fs f[name="name"]', 'text')

      ->attr_is('#s1', 'l', "2")
      ->attr_is('#s1', 'to', 4)
      ->text_is('#s1 fs f[name="name"]', 'w')

      ->attr_is('#s2', 'l', "2")
      ->attr_is('#s2', 'from', 5)
      ->attr_is('#s2', 'to', 9)
      ->text_is('#s2 fs f[name="name"]', 'w')

      ->attr_is('#s2', 'l', "2")
      ->attr_is('#s2', 'from', 5)
      ->attr_is('#s2', 'to', 9)
      ->text_is('#s2 fs f[name="name"]', 'w')

      ->attr_is('#s3', 'l', "2")
      ->attr_is('#s3', 'from', 10)
      ->attr_is('#s3', 'to', 10)
      ->text_is('#s3 fs f[name="name"]', 'a')

      ->attr_is('#s4', 'l', "3")
      ->attr_is('#s4', 'from', 10)
      ->attr_is('#s4', 'to', 10)
      ->text_is('#s4 fs f[name="name"]', 'b')

      ->attr_is('#s5', 'l', "2")
      ->attr_is('#s5', 'from', 10)
      ->attr_is('#s5', 'to', 14)
      ->text_is('#s5 fs f[name="name"]', 'w')
      ;

  ok($inline->parse(
    'ccc',
    \'<w>Augen<c>,</c></w> <w>die</w>'
  ), 'Parsed');
  is($inline->data->data, 'Augen, die');

  Test::XML::Loy->new($inline->structures->to_string('ddd', 2))
      ->attr_is('#s0', 'l', "1")
      ->attr_is('#s0', 'to', 10)
      ->text_is('#s0 fs f[name="name"]', 'text')

      ->attr_is('#s1', 'l', "2")
      ->attr_is('#s1', 'to', 6)
      ->text_is('#s1 fs f[name="name"]', 'w')

      ->attr_is('#s2', 'l', "3")
      ->attr_is('#s2', 'from', 5)
      ->attr_is('#s2', 'to', 6)
      ->text_is('#s2 fs f[name="name"]', 'c')

      ->attr_is('#s3', 'l', "2")
      ->attr_is('#s3', 'from', 7)
      ->attr_is('#s3', 'to', 10)
      ->text_is('#s3 fs f[name="name"]', 'w')
      ;
};

done_testing;
