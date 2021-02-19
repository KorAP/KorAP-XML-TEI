use strict;
use warnings;
use Test::More;
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('Test::KorAP::XML::TEI','korap_tempfile', 'i5_template', 'test_tei2korapxml');


subtest 'korap_tempfile' => sub {
  my ($fh, $filename) = korap_tempfile('test');
  ok($fh, 'Filehandle created');
  ok($filename, 'Filename returned');
  close($fh);

  like($filename, qr!KorAP-XML-TEI_test_.+?\.tmp$!, 'Filename pattern');

  ($fh, $filename) = korap_tempfile();
  ok($fh, 'Filehandle created');
  ok($filename, 'Filename returned');
  close($fh);

  like($filename, qr!KorAP-XML-TEI_.+?\.tmp$!, 'Filename pattern');
};


subtest 'i5_template' => sub {
  my $tpl = i5_template();
  my $t = Test::XML::Loy->new($tpl);
  $t->text_is('korpusSigle', 'AAA')
    ->text_is('dokumentSigle', 'AAA/BBB')
    ->text_is('textSigle', 'AAA/BBB.00000')
    ->text_like('text', qr!Lorem ipsum!)
    ;

  $tpl = i5_template(
    korpusSigle => 'BBB',
    dokumentSigle => 'BBB/CCC',
    textSigle => 'BBB/CCC.11111',
    text => 'Ein Versuch'
  );
  $t = Test::XML::Loy->new($tpl);
  $t->text_is('korpusSigle', 'BBB')
    ->text_is('dokumentSigle', 'BBB/CCC')
    ->text_is('textSigle', 'BBB/CCC.11111')
    ->text_unlike('text', qr!Lorem ipsum!)
    ->text_like('text', qr!Ein Versuch!)
    ;
};


subtest 'test_tei2korapxml_i5_template' => sub {
  test_tei2korapxml(
    template => {
      text => 'Das ist ein gutes Beispiel',
      korpusSigle => 'a',
      dokumentSigle => 'a/b',
      textSigle => 'a/b.1'
    },
    param => '-ti'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=a_b\.1!)
    ->file_exists('a/b/1/header.xml')
    ->file_exists('a/b/header.xml')
    ->file_exists('a/header.xml')
    ->unzip_xml('a/b/1/data.xml')
    ->attr_is('raw_text', 'docid', 'a_b.1')
    ->text_is('text', 'Das ist ein gutes Beispiel');
};

done_testing;
