use strict;
use warnings;
use Test::More;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile!;

use_ok('KorAP::XML::TEI', 'remove_xml_comments', 'escape_xml');

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


done_testing;
