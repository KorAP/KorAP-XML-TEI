use utf8;
use strict;
use warnings;
use Test::More;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile test_tei2korapxml!;

use_ok('KorAP::XML::TEI', 'remove_xml_comments', 'escape_xml', 'escape_xml_minimal', 'replace_entities');

subtest 'remove_xml_comments' => sub {
  my ($fh, $filename) = korap_tempfile('tei');

  print $fh <<'HTML';
mehrzeiliger
Kommentar
  -->
Test
HTML

  is(remove_xml_comments($fh, "hallo"),"hallo");
  is(remove_xml_comments($fh, "hallo <!-- Test -->"),"hallo ");
  is(remove_xml_comments($fh, "<!-- Test --> hallo")," hallo");

  seek($fh, 0, 0);

  is(remove_xml_comments($fh, '<!--'), "Test\n");

  seek($fh, 0, 0);

  print $fh <<'HTML';
mehrzeiliger
Kommentar
  --><!-- Versuch
-->ist <!-- a --><!-- b --> ein Test
HTML

  seek($fh, 0, 0);

  is(remove_xml_comments($fh, 'Dies <!--'), "Dies ist  ein Test\n");

  close($fh);
};


subtest 'remove_xml_comments in script' => sub {
  test_tei2korapxml(
    template => {
      text => "<!--\nDies ist ein\nmehrzeiligerKommentar -->Text1",
      textSigle => 'A/B.1',
      pattern => 'xx'
    },
    param => '--no-tokenizer'
  )
    ->file_exists('A/B/1/data.xml')
    ->unzip_xml('A/B/1/data.xml')
    ->text_is('text', 'Text1');
};


subtest 'skip missing dir in script' => sub {
  test_tei2korapxml(
    template => {
      text => "Nur ein Test",
      textSigle => '',
      pattern => 'missing_dir'
    },
    param => '--no-tokenizer'
  )
    ->file_exists_not('A/B/1/data.xml')
    ->stderr_like(qr!Empty '<textSigle />' \(L29\) in header!)
    ->stderr_like(qr!skipping this text!)
    ;
};


subtest 'escape_xml' => sub {
  is(
    escape_xml('"""'),
    '&quot;&quot;&quot;'
  );

  is(
    escape_xml('&&&'),
    '&amp;&amp;&amp;'
  );

  is(
    escape_xml('<<<'),
    '&lt;&lt;&lt;'
  );

  is(
    escape_xml('>>>'),
    '&gt;&gt;&gt;'
  );

  is(
    escape_xml('<tag att1="foo" att2="bar">C&A</tag>'),
    '&lt;tag att1=&quot;foo&quot; att2=&quot;bar&quot;&gt;C&amp;A&lt;/tag&gt;'
  );
};

subtest 'escape_xml_minimal' => sub {
  is(
      escape_xml_minimal('"""'),
      '"""'
  );

  is(
      escape_xml_minimal('&&&'),
      '&amp;&amp;&amp;'
  );

  is(
      escape_xml_minimal('<<<'),
      '&lt;&lt;&lt;'
  );

  is(
      escape_xml_minimal('>>>'),
      '&gt;&gt;&gt;'
  );

  is(
      escape_xml_minimal('<tag att1="foo" att2="bar">C&A</tag>'),
      '&lt;tag att1="foo" att2="bar"&gt;C&amp;A&lt;/tag&gt;'
  );
};

subtest 'Replace all entities' => sub {
  is(
    replace_entities('&alpha;&ap;&bdquo;&blk12;&blk14;&blk34;&block;&boxDL;&boxdl;&boxdr;&boxDR;&boxH;&boxh;&boxhd;&boxHD;&boxhu;&boxHU;&boxUL;&boxul;&boxur;&boxUR;&boxv;&boxV;&boxvh;&boxVH;&boxvl;&boxVL;&boxVR;&boxvr;&bull;&caron;&ccaron;&circ;&dagger;&Dagger;&ecaron;&euro;&fnof;&hellip;&Horbar;&inodot;&iota;&ldquo;&ldquor;&lhblk;&lsaquo;&lsquo;&lsquor;&mdash;&ndash;&nu;&oelig;&OElig;&omega;&Omega;&permil;&phi;&pi;&piv;&rcaron;&rdquo;&rho;&rsaquo;&rsquo;&rsquor;&scaron;&Scaron;&sigma;&squ;&squb;&squf;&sub;&tilde;&trade;&uhblk;&Yuml;&zcaron;&Zcaron;'),
    'α≈„▒░▓█╗┐┌╔═─┬╦┴╩╝┘└╚│║┼╬┤╣╠├•ˇčˆ†‡ě€ƒ…‗ıι“„▄‹‘‚—–νœŒωΩ‰φπϖř”ρ›’‘šŠσ□■▪⊂˜™▀ŸžŽ'
  );
  is(replace_entities('&#65;'), 'A');
  is(replace_entities('&#171;'), replace_entities('&#x00AB;'));
  is(replace_entities('&#x41;'), 'A');
  is(replace_entities('&amp;&lt;&gt;'), '&amp;&lt;&gt;')
};

done_testing;
