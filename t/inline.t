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


subtest 'Support dependency parsing' => sub {
  $inline = KorAP::XML::TEI::Inline->new(0,{},0,1);
  ok($inline->parse('Fake News Media',
                    \'<s><w n="1" lemma="Fake"  pos="N" head="2" deprel="name" msd="SUBCAT_Prop|CASECHANGE_Up|OTHER_UNK">Fake</w> <w n="2" lemma="News"  pos="N" head="3" deprel="name" msd="SUBCAT_Prop|CASECHANGE_Up|OTHER_UNK">News</w> <w n="3" lemma="media" pos="N" head="0" deprel="ROOT" msd="NUM_Sg|CASE_Nom|CASECHANGE_Up">Media</w></s> '
                  ), 'Parsed');

  is($inline->data->data, 'Fake News Media ');

  Test::XML::Loy->new($inline->tokens->to_string('aaa', 1))
      ->attr_is('#s0', 'l', "3")
      ->attr_is('#s0', 'to', 4)
      ->text_is('#s0 fs f[name="lemma"]', 'Fake')
      ->text_is('#s0 fs f[name="pos"]', 'N')
      ->element_exists_not('#s0 fs f[name="n"]')

      ->attr_is('#s1', 'l', "3")
      ->attr_is('#s1', 'from', 5)
      ->attr_is('#s1', 'to', 9)
      ->text_is('#s1 fs f[name="lemma"]', 'News')
      ->text_is('#s1 fs f[name="pos"]', 'N')

      ->attr_is('#s2', 'l', "3")
      ->attr_is('#s2', 'from', 10)
      ->attr_is('#s2', 'to', 15)
      ->text_is('#s2 fs f[name="lemma"]', 'media')
      ->text_is('#s2 fs f[name="pos"]', 'N')
      ;

  Test::XML::Loy->new($inline->dependencies->to_string('aaa', 3))
      ->attr_is('#s1_n1', 'l', "3")
      ->element_exists('#s1_n1[from="0"]')
      ->attr_is('#s1_n1', 'to', 4)
      ->attr_is('#s1_n1 rel', 'label', 'name')
      ->attr_is('#s1_n1 rel span', 'from', 5)
      ->attr_is('#s1_n1 rel span', 'to', 9)
      ->element_exists_not('#s1_n1 fs')

      ->attr_is('#s1_n2', 'l', "3")
      ->attr_is('#s1_n2', 'from', 5)
      ->attr_is('#s1_n2', 'to', 9)
      ->attr_is('#s1_n2 rel', 'label', 'name')
      ->attr_is('#s1_n2 rel span', 'from', 10)
      ->attr_is('#s1_n2 rel span', 'to', 15)

      ->attr_is('#s1_n3', 'l', "3")
      ->attr_is('#s1_n3', 'from', 10)
      ->attr_is('#s1_n3', 'to', 15)
      ->attr_is('#s1_n3 rel', 'label', 'ROOT')
      ->element_exists('#s1_n3 rel span[from="0"]')
      ->attr_is('#s1_n3 rel span', 'to', 15)
      ;

  $inline = KorAP::XML::TEI::Inline->new(0,{},0,1);
  ok($inline->parse('Fake News Media',
                    \('<p xml:lang="x-|fin:2|"><s xml:lang="fin">'.
                    '<w deprel="nn" head="2" lemma="lJgkPOGUBSFSRQlx" msd="NUM_Sg|CASE_Nom|CASECHANGE_Up" n="1" pos="N">lJgkPOGUBSFSRQlx</w> '.
                    '<w deprel="nsubj" head="3" lemma="rYuqciR" msd="SUBCAT_Prop|NUM_Sg|CASE_Nom|CASECHANGE_Up|OTHER_UNK" n="2" pos="N">rYuqciR</w> '.
                    '<w deprel="ROOT" head="0" lemma="RcidTBqv" msd="PRS_Sg3|VOICE_Act|TENSE_Prt|MOOD_Ind" n="3" pos="V">RcidTBqv</w> '.
                    '<w deprel="poss" head="5" lemma="cHIf" msd="SUBCAT_Acro|NUM_Sg|CASE_Nom|CASECHANGE_Up" n="4" pos="N">cHIf</w> '.
                    '<w deprel="nommod" head="3" lemma="reuvyWZtUhN" msd="NUM_Sg|CASE_Ela" n="5" pos="N">reuvyWZtUhN</w> '.
                    '<w deprel="nsubj" head="7" lemma="KsaXYaFo" msd="NUM_Sg|CASE_Gen" n="6" pos="N">KsaXYaFo</w> '.
                    '<w deprel="iccomp" head="3" lemma="qJhgSDNOYpWg" msd="NUM_Sg|CASE_Ill|VOICE_Act|INF_Inf3" n="7" pos="V">qJhgSDNOYpWg</w> '.
                    '<w deprel="name" head="9" lemma="xtRyGN" msd="SUBCAT_Prop|CASECHANGE_Up|OTHER_UNK" n="8" pos="N">xtRyGN</w> '.
                    '<w deprel="poss" head="10" lemma="XCVuQwU" msd="SUBCAT_Prop|NUM_Sg|CASE_Gen|CASECHANGE_Up|OTHER_UNK" n="9" pos="N">XCVuQwU</w> '.
                    '<w deprel="poss" head="11" lemma="hYwEsYDUbYHmJ" msd="NUM_Sg|CASE_Gen|CASECHANGE_Up|OTHER_UNK" n="10" pos="N">hYwEsYDUbYHmJ</w> '.
                    '<w deprel="dobj" head="7" lemma="yYXOYOqX" msd="NUM_Sg|CASE_Gen" n="11" pos="N">yYXOYOqX</w> '.
                    '<w deprel="nommod" head="7" lemma="LkrLYiYgRSC" msd="NUM_Sg|CASE_Ade" n="12" pos="N">LkrLYiYgRSC</w> '.
                    '<w deprel="num" head="12" lemma="erRenLjillGtDCaRLIx" msd="_" n="13" pos="Num">erRenLjillGtDCaRLIx</w> '.
                    '<w deprel="punct" head="3" lemma="c" msd="_" n="14" pos="Punct">c</w> '.
                    '</s>'."\n".
                    '<s xml:lang="fin">'.
                    '<w deprel="nommod" head="3" lemma="LSymCdojKTj" msd="SUBCAT_Prop|NUM_Sg|CASE_Ine|CASECHANGE_Up|OTHER_UNK" n="1" pos="N">LSymCdojKTj</w> '.
                    '<w deprel="auxpass" head="3" lemma="vQ" msd="PRS_Sg3|VOICE_Act|TENSE_Prs|MOOD_Ind" n="2" pos="V">vQ</w> '.
                    '<w deprel="ROOT" head="0" lemma="nHfBTtne" msd="NUM_Sg|CASE_Nom|VOICE_Pass|PCP_PrfPrc|CMP_Pos" n="3" pos="V">nHfBTtne</w> '.
                    '<w deprel="preconj" head="6" lemma="fmcz" msd="SUBCAT_CC" n="4" pos="C">fmcz</w> '.
                    '<w deprel="poss" head="6" lemma="lHlPTQv" msd="SUBCAT_Prop|NUM_Sg|CASE_Gen|CASECHANGE_Up|OTHER_UNK" n="5" pos="N">lHlPTQv</w> '.
                    '<w deprel="dobj" head="3" lemma="IXxgORnMc" msd="NUM_Pl|CASE_Par|OTHER_UNK" n="6" pos="N">IXxgORnMc</w> '.
                    '<w deprel="cc" head="6" lemma="QdjQ" msd="SUBCAT_CC" n="7" pos="C">QdjQ</w> '.
                    '<w deprel="conj" head="6" lemma="luYMmwBGSUbXCMxqFzeZv" msd="NUM_Pl|CASE_Par|OTHER_UNK" n="8" pos="N">luYMmwBGSUbXCMxqFzeZv</w> '.
                    '<w deprel="punct" head="3" lemma="E" msd="_" n="9" pos="Punct">E</w>'.
                    '</s>'.
                    '</p>')
                  ), 'Parsed');

  is($inline->data->data, 'lJgkPOGUBSFSRQlx rYuqciR RcidTBqv cHIf reuvyWZtUhN KsaXYaFo qJhgSDNOYpWg xtRyGN XCVuQwU hYwEsYDUbYHmJ yYXOYOqX LkrLYiYgRSC erRenLjillGtDCaRLIx c  LSymCdojKTj vQ nHfBTtne fmcz lHlPTQv IXxgORnMc QdjQ luYMmwBGSUbXCMxqFzeZv E');

  Test::XML::Loy->new($inline->dependencies->to_string('aaa', 3))
      ->attr_is('#s1_n3', 'l', "4")
      ->attr_is('#s1_n3', 'from', 25)
      ->attr_is('#s1_n3', 'to', 33)
      ->attr_is('#s1_n3 rel', 'label', 'ROOT')
      ->element_exists('#s1_n3 rel span[from=0]')
      ->attr_is('#s1_n3 rel span', 'to', 144)
      ->element_exists_not('#s1_n3 fs')

      ->attr_is('#s1_n14', 'l', "4")
      ->attr_is('#s1_n14', 'from', 143)
      ->attr_is('#s1_n14', 'to', 144)
      ->attr_is('#s1_n14 rel', 'label', 'punct')
      ->attr_is('#s1_n14 rel span', 'from', 25)
      ->attr_is('#s1_n14 rel span', 'to', 33)

      ->attr_is('#s2_n1', 'l', "4")
      ->attr_is('#s2_n1', 'from', 146)
      ->attr_is('#s2_n1', 'to', 157)
      ->attr_is('#s2_n1 rel', 'label', 'nommod')
      ->attr_is('#s2_n1 rel span', 'from', 161)
      ->attr_is('#s2_n1 rel span', 'to', 169)

      ->attr_is('#s2_n9', 'l', "4")
      ->attr_is('#s2_n9', 'from', 220)
      ->attr_is('#s2_n9', 'to', 221)
      ->attr_is('#s2_n9 rel', 'label', 'punct')
      ->attr_is('#s2_n9 rel span', 'from', 161)
      ->attr_is('#s2_n9 rel span', 'to', 169)

      ->attr_is('#s2_n3', 'l', "4")
      ->attr_is('#s2_n3', 'from', 161)
      ->attr_is('#s2_n3', 'to', 169)
      ->attr_is('#s2_n3 rel', 'label', 'ROOT')
      ->attr_is('#s2_n3 rel span', 'from', 146)
      ->attr_is('#s2_n3 rel span', 'to', 221)
      ;

  Test::XML::Loy->new($inline->tokens->to_string('aaa', 1))
      ->attr_is('#s2', 'l', "4")
      ->attr_is('#s2', 'from', 25)
      ->attr_is('#s2', 'to', 33)
      ->text_is('#s2 fs f[name="lemma"]', 'RcidTBqv')
      ->text_is('#s2 fs f[name="pos"]', 'V')
      ->text_is('#s2 fs f[name="msd"]', 'PRS_Sg3|VOICE_Act|TENSE_Prt|MOOD_Ind')

      ->attr_is('#s22', 'l', "4")
      ->attr_is('#s22', 'from', 220)
      ->attr_is('#s22', 'to', 221)
      ->text_is('#s22 fs f[name="lemma"]', 'E')
      ->text_is('#s22 fs f[name="pos"]', 'Punct')
      ->text_is('#s22 fs f[name="msd"]', '_')
      ;

};

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


subtest 'Treatment of tokens' => sub {
  my $inline = KorAP::XML::TEI::Inline->new(0, {b => 1}, 1);

  ok($inline->parse('aaa', \'<a>Der</a> <b>alte</b> <w pos="NN">Baum</w>'), 'Parsed');
  is($inline->data->data, 'Der alte Baum');

  # Only contains '<a>'
  Test::XML::Loy->new($inline->structures->to_string('aaa', 1))
      ->attr_is('#s1', 'to', 3)
      ->element_exists_not('#s2')
      ;

  # Only contains 'w'
  Test::XML::Loy->new($inline->tokens->to_string('aaa', 1))
      ->attr_is('#s0', 'from', 9)
      ->attr_is('#s0', 'to', 13)
      ->attr_is('#s0 > fs > f > fs > f', 'name', 'pos')
      ->text_is('#s0 > fs > f > fs > f[name=pos]', 'NN')
      ->element_exists_not('#s1')
      ;
};

done_testing;
