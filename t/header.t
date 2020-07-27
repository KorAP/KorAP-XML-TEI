use strict;
use warnings;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::More;
use Test::KorAP::XML::TEI qw!korap_tempfile!;

require_ok('KorAP::XML::TEI::Header');

my $h;

eval { $h = KorAP::XML::TEI::Header->new('<idsHeader>') };

ok(!$h, 'Header invalid');

subtest 'Corpus Header' => sub {
  $h = KorAP::XML::TEI::Header->new('<idsHeader type="corpus">');
  ok($h, 'Header valid');

  is($h->sigle, '', 'Check sigle');
  is($h->sigle_esc, '', 'Check sigle escaped');
  is($h->dir, '', 'Check dir');
  is($h->type, 'corpus', 'Check dir');
  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"corpus\">$!, 'String');

  my ($fh, $filename) = korap_tempfile('header_1');

  print $fh <<'HTML';
<-- mehrzeiliger
Kommentar
  -->  <fileDesc>
   <titleStmt>
    <korpusSigle>GOE</korpusSigle>
    <c.title>Goethe-Korpus</c.title>
   </titleStmt>
</idsHeader>
Test
HTML

  seek($fh, 0, 0);

  ok($h->parse($fh), 'Parsing');

  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"corpus\">!, 'String');
  like($h->to_string, qr!<-- mehrzeiliger!, 'String');
  like($h->to_string, qr!titleStmt!, 'String');
  like($h->to_string, qr!</idsHeader>$!, 'String');

  is($h->sigle, 'GOE', 'Check sigle');
  is($h->sigle_esc, 'GOE', 'Check sigle escaped');
  is($h->id, 'GOE', 'Check sigle');
  is($h->id_esc, 'GOE', 'Check sigle escaped');
  is($h->dir, 'GOE', 'Check dir');
  is($h->type, 'corpus', 'Check type');
};

subtest 'Document Header' => sub {
  $h = KorAP::XML::TEI::Header->new('<idsHeader type="document">');
  ok($h, 'Header valid');

  is($h->sigle, '', 'Check sigle');
  is($h->sigle_esc, '', 'Check sigle escaped');
  is($h->dir, '', 'Check dir');
  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"document\">$!, 'String');

  my ($fh, $filename) = korap_tempfile('header_2');

  print $fh <<'HTML';
  <fileDesc>
   <titleStmt>
    <dokumentSigle>GOE/"AAA"</dokumentSigle>
   </titleStmt>
</idsHeader>
Test
HTML

  seek($fh, 0, 0);

  ok($h->parse($fh), 'Parsing');

  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"document\">!, 'String');
  like($h->to_string, qr!titleStmt!, 'String');
  like($h->to_string, qr!</idsHeader>$!, 'String');

  is($h->sigle, 'GOE/"AAA"', 'Check sigle');
  is($h->sigle_esc, 'GOE/&quot;AAA&quot;', 'Check sigle escaped');
  is($h->id, 'GOE_"AAA"', 'Check sigle');
  is($h->id_esc, 'GOE_&quot;AAA&quot;', 'Check sigle escaped');
  is($h->dir, 'GOE/"AAA"', 'Check dir');
  is($h->type, 'document', 'Check type');
};


subtest 'Text Header' => sub {
  $h = KorAP::XML::TEI::Header->new('<idsHeader type="text">');
  ok($h, 'Header valid');

  is($h->sigle, '', 'Check sigle');
  is($h->sigle_esc, '', 'Check sigle escaped');
  is($h->dir, '', 'Check dir');
  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"text\">$!, 'String');

  my ($fh, $filename) = korap_tempfile('header_3');

  print $fh <<'HTML';
  <fileDesc>
   <titleStmt>
    <textSigle>GOE/"AAA".00003</textSigle>
   </titleStmt>
</idsHeader>
Test
HTML

  seek($fh, 0, 0);

  ok($h->parse($fh), 'Parsing');

  like($h->to_string, qr!^<\?xml version!, 'String');
  like($h->to_string, qr!<idsHeader type=\"text\">!, 'String');
  like($h->to_string, qr!titleStmt!, 'String');
  like($h->to_string, qr!</idsHeader>$!, 'String');

  like($h->to_string, qr!GOE/&quot;AAA&quot;\.00003!, 'String');

  is($h->sigle, 'GOE/"AAA".00003', 'Check sigle');
  is($h->sigle_esc, 'GOE/&quot;AAA&quot;.00003', 'Check sigle escaped');
  is($h->id, 'GOE_"AAA".00003', 'Check sigle');
  is($h->id_esc, 'GOE_&quot;AAA&quot;.00003', 'Check sigle escaped');
  is($h->dir, 'GOE/"AAA"/00003', 'Check dir');
  is($h->type, 'text', 'Check type');
};


done_testing;
