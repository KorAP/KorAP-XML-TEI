use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use Encode qw!encode_utf8 decode_utf8 encode!;

use Test::More;
use Test::Output;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile i5_template test_tei2korapxml!;

my $f = dirname(__FILE__);
my $script = catfile($f, '..', 'script', 'tei2korapxml');
ok(-f $script, 'Script found');

stdout_like(
  sub { system('perl', $script, '--help') },
  qr!This\s*program\s*is\s*usually\s*called\s*from\s*inside\s*another\s*script\.!,
  'Help'
);


stdout_like(
  sub { system('perl', $script, '--version') },
  qr!tei2korapxml - v\d+?\.\d+?!,
  'Version'
);

# Load example file
my $file = catfile($f, 'data', 'goe_sample.i5.xml');

subtest 'Debugging' => sub {

  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti',
    env => 'KORAPXMLTEI_DEBUG=1'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
  ->stderr_like(qr!Debugging is activated!);
};

subtest 'Basic processing' => sub {

  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
  ->stderr_unlike(qr!Debugging is activated!);


  # Uncompress GOE/header.xml from zip file
  $t->unzip_xml('GOE/header.xml')

    # TODO: check wrong encoding in header-files (compare with input document)!
    ->text_is('korpusSigle', 'GOE', 'korpusSigle')
    ->text_is('h\.title[type=main]', 'Goethes Werke', 'h.title')
    ->text_is('h\.author', 'Goethe, Johann Wolfgang von', 'h.author')
    ->text_is('pubDate[type=year]', '1982', 'pubDate');

  # Uncompress GOE/AGA/header.xml from zip file
  $t->unzip_xml('GOE/AGA/header.xml')
    ->text_is('dokumentSigle', 'GOE/AGA', 'dokumentSigle')
    ->text_is('d\.title', 'Goethe: Autobiographische Schriften II, (1817-1825, 1832)', 'd.title')
    ->text_is('creatDate', '1820-1822', 'creatDate');

  # Uncompress GOE/AGA/00000/header.xml from zip file
  $t->unzip_xml('GOE/AGA/00000/header.xml')
    ->text_is('textSigle', 'GOE/AGA.00000', 'textSigle')
    ->text_is('analytic > h\.title[type=main]', 'Campagne in Frankreich', 'h.title');

# Uncompress GOE/AGA/00000/data.xml from zip file
  $t->unzip_xml('GOE/AGA/00000/data.xml')
    ->attr_is('raw_text', 'docid', 'GOE_AGA.00000', 'text id')
    ->text_like('raw_text > text', qr!^Campagne in Frankreich 1792.*?uns allein begl.*cke\.$!, 'text content')
    ->text_like('raw_text > text', qr!unter dem Titel "Kriegstheater"!, 'text content');

  my $content = $t->get_content_of('GOE/AGA/00000/data.xml');
  like($content, qr!unter dem Titel "Kriegstheater"!, 'raw text content');

  $t->unzip_xml('GOE/AGA/00000/struct/structure.xml')
    ->text_is('span[id=s3] *[name=type]', 'Autobiographie', 'text content')
    ->text_is('#s3 *[name=type]', 'Autobiographie', 'text content')
    ->attr_is('#s0','to','1266')
    ->attr_is('#s0','l','1')

    ->attr_is('#s18','from','925')
    ->attr_is('#s18','to','1266')
    ->attr_is('#s18','l','5')
    ->attr_is('#s18 > fs','type', 'struct')
    ->attr_is('#s18 > fs > f','name','name')
    ->text_is('#s18 > fs > f','poem')

    ->attr_is('#s19','from','925')
    ->attr_is('#s19','to','1098')
    ->attr_is('#s19','l','6')
    ->attr_is('#s19 > fs','type','struct')
    ->text_is('#s19 > fs > f[name=name]','lg')
    ->text_is('#s19 > fs > f[name=attr] > fs[type=attr] >f[name=part]','u')

    ->attr_is('#s37','from','1229')
    ->attr_is('#s37','to','1266')
    ->attr_is('#s37','l','8')
    ->attr_is('#s37 > fs','type','struct')
    ->text_is('#s37 > fs > f[name=name]','s')
    ->text_is('#s37 > fs > f[name=attr] > fs[type=attr] > f[name=type]','manual')

    ->attr_is('#s38','from','1266')
    ->attr_is('#s38','to','1266')
    ->attr_is('#s38','l','2')
    ->attr_is('#s38 > fs','type','struct')
    ->text_is('#s38 > fs > f[name=name]','back')
    ->element_count_is('*', 196);

  $t->file_exists_not('GOE/AGA/00000/base/tokens.xml', 'External not generated');

  # Uncompress GOE/AGA/00000/base/tokens_aggressive.xml from zip file
  $t->unzip_xml('GOE/AGA/00000/base/tokens_aggressive.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 8)
    ->attr_is('spanList span#t_1', 'from', 9)
    ->attr_is('spanList span#t_1', 'to', 11)

    ->attr_is('spanList span#t_67', 'from', 427)
    ->attr_is('spanList span#t_67', 'to', 430)

    ->attr_is('spanList span#t_214', 'from', 1209)
    ->attr_is('spanList span#t_214', 'to', 1212)

    ->element_count_is('spanList span', 227);

  # Uncompress GOE/AGA/00000/base/tokens_conservative.xml from zip file
  $t->unzip_xml('GOE/AGA/00000/base/tokens_conservative.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 8)

    ->attr_is('spanList span#t_1', 'from', 9)
    ->attr_is('spanList span#t_1', 'to', 11)

    ->attr_is('spanList span#t_67', 'from', 427)
    ->attr_is('spanList span#t_67', 'to', 430)

    ->attr_is('spanList span#t_214', 'from', 1209)
    ->attr_is('spanList span#t_214', 'to', 1212)

    ->element_count_is('spanList span', 227);
};


subtest 'Tokenize with external tokenizer' => sub {

  my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

  test_tei2korapxml(
    file => $file,
    param => "-tc='perl $cmd'",
    tmp => 'script_out2'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_readable('GOE/AGA/00000/base/tokens.xml')

    # Uncompress GOE/AGA/00000/base/tokens.xml from zip file
    ->unzip_xml('GOE/AGA/00000/base/tokens.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 8)
    ->attr_is('spanList span#t_1', 'from', 9)
    ->attr_is('spanList span#t_1', 'to', 11)
    ->attr_is('spanList span#t_67', 'from', 427)
    ->attr_is('spanList span#t_67', 'to', 430)
    ->attr_is('spanList span#t_214', 'from', 1209)
    ->attr_is('spanList span#t_214', 'to', 1212)
    ->element_count_is('spanList span', 227);
};

subtest 'Tokenize with external tokenizer and defined folder' => sub {

  my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

  test_tei2korapxml(
    file => $file,
    param => "-tc='perl $cmd' --tokens-file=yadda",
    tmp => 'script_out2'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists_not('GOE/AGA/00000/base/tokens.xml')
    ->file_readable('GOE/AGA/00000/base/yadda.xml')
    ->unzip_xml('GOE/AGA/00000/base/yadda.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 8)
    ->attr_is('spanList span#t_1', 'from', 9)
    ->attr_is('spanList span#t_1', 'to', 11)
    ->attr_is('spanList span#t_67', 'from', 427)
    ->attr_is('spanList span#t_67', 'to', 430)
    ->attr_is('spanList span#t_214', 'from', 1209)
    ->attr_is('spanList span#t_214', 'to', 1212)
    ->element_count_is('spanList span', 227);
};

subtest 'Check KorAP tokenizer for infinite loop bug' => sub {

  my $file = catfile($f, 'data', 'korap_tokenizer_challenge.xml');

  eval {
    require KorAP::XML::TEI::Tokenizer::KorAP;
    1;
  } or do {
    plan skip_all => "KorAP::XML::TEI::Tokenizer::KorAP cannot be used";
  };

  test_tei2korapxml(
    file => $file,
    param => "-tk -s",
    tmp => 'script_bug_check'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=WDD19_H0039\.87242!)
    ->file_readable('WDD19/H0039/87242/struct/structure.xml');
};

subtest 'Sentence split with KorAP tokenizer' => sub {

  eval {
    require KorAP::XML::TEI::Tokenizer::KorAP;
    1;
  } or do {
    plan skip_all => "KorAP::XML::TEI::Tokenizer::KorAP cannot be used";
  };

  test_tei2korapxml(
      file => $file,
      param => "-tk -s",
      tmp => 'script_sentence_split'
  )
      ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
      ->file_readable('GOE/AGA/00000/struct/structure.xml')
      ->unzip_xml('GOE/AGA/00000/struct/structure.xml')
      ->text_is('span#s25 fs f', 's')
      ->attr_is('span#s25', 'l', -1)
      ->attr_is('span#s25', 'to', 54)
      ->text_is('span#s30 fs f', 's')
      ->attr_is('span#s30', 'l', -1)
      ->attr_is('span#s30', 'from', 1099)
      ->attr_is('span#s30', 'to', 1266);
};

subtest 'Test Tokenizations' => sub {

  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'text_with_blanks.i5.xml'),
    tmp => 'script_out3',
    param => '-ti'
  )->stderr_like(qr!tei2korapxml:.*? text_id=CORP_DOC.00001!);

  # ~ test conservative tokenization ~
  $t->unzip_xml('CORP/DOC/00001/base/tokens_conservative.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 6)

    ->attr_is('spanList span#t_1', 'from', 7)
    ->attr_is('spanList span#t_1', 'to', 9)

    ->attr_is('spanList span#t_3', 'from', 12)
    ->attr_is('spanList span#t_3', 'to', 16)

    ->attr_is('spanList span#t_9', 'from', 36)
    ->attr_is('spanList span#t_9', 'to', 37)

    ->attr_is('spanList span#t_13', 'from', 44)
    ->attr_is('spanList span#t_13', 'to', 45)          # "

    ->attr_is('spanList span#t_14', 'from', 45)        # twenty-two
    ->attr_is('spanList span#t_14', 'to', 55)

    ->attr_is('spanList span#t_15', 'from', 55)        # "
    ->attr_is('spanList span#t_15', 'to', 56)

    ->attr_is('spanList span#t_19', 'from', 66)
    ->attr_is('spanList span#t_19', 'to', 67)

    ->element_count_is('spanList span', 20);


  # ~ test aggressive tokenization ~
  $t->unzip_xml('CORP/DOC/00001/base/tokens_aggressive.xml')
    ->attr_is('spanList span:nth-child(1)', 'to', 6)

    ->attr_is('spanList span#t_1', 'from', 7)
    ->attr_is('spanList span#t_1', 'to', 9)

    ->attr_is('spanList span#t_3', 'from', 12)
    ->attr_is('spanList span#t_3', 'to', 16)

    ->attr_is('spanList span#t_9', 'from', 36)
    ->attr_is('spanList span#t_9', 'to', 37)

    ->attr_is('spanList span#t_13', 'from', 44)
    ->attr_is('spanList span#t_13', 'to', 45)          # "

    ->attr_is('spanList span#t_14', 'from', 45)        # twenty
    ->attr_is('spanList span#t_14', 'to', 51)

    ->attr_is('spanList span#t_15', 'from', 51)        # -
    ->attr_is('spanList span#t_15', 'to', 52)

    ->attr_is('spanList span#t_16', 'from', 52)        # two
    ->attr_is('spanList span#t_16', 'to', 55)

    ->attr_is('spanList span#t_17', 'from', 55)        # "
    ->attr_is('spanList span#t_17', 'to', 56)

    ->attr_is('spanList span#t_21', 'from', 66)
    ->attr_is('spanList span#t_21', 'to', 67)

    ->element_count_is('spanList span', 22);
};


subtest 'Check Tokenization Flags' => sub {

  # Get external tokenizer
  my $f = dirname(__FILE__);
  my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

  # Load example file
  test_tei2korapxml(
    file => catfile($f, 'data', 'goe_sample.i5.xml'),
    param => "-ti -tc 'perl $cmd'",
    tmp => 'script_tokflags'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/base/tokens_aggressive.xml')
    ->file_exists('GOE/AGA/00000/base/tokens_conservative.xml')
    ->file_exists('GOE/AGA/00000/base/tokens.xml')
    ;
};


subtest 'Test utf-8 handling' => sub {
  # Introduce invalid utf-8 characters
  my $text_sigle;
  {
    no warnings;
    # $text_sigle printed to file, without encoding: Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C
    # the utf8-sequence 'þ¿¿¿¿¿' encodes 32 bit of data (see 0x7FFF_FFFF in perlunicode)
    $text_sigle = "A\x{FFFF_FFFF}A_B\x{FFFF_FFFF}B.C\x{FFFF_FFFF}C"
  }
  # If CHECK is 0, encoding and decoding replace any malformed character
  # with a substitution character.
  # � = substitution character
  my $text_sigle_lax = encode_utf8($text_sigle);
  my $text_sigle_esc = encode('UTF-8', $text_sigle);

  is(length($text_sigle), 11);     # A�A_B�B.C�C (char string => length(�) = 1)
  is(length($text_sigle_lax), 29); # Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C (byte string)
  is(length($text_sigle_esc), 17); # A�A_B�B.C�C (byte string => length(�) = 3)


  my $tpl;
  {
    no warnings;
    $tpl = i5_template(
      korpusSigle => "A\x{FFFF_FFFF}A",
      dokumentSigle => "A\x{FFFF_FFFF}A_B\x{FFFF_FFFF}B",
      text => "<p>d\x{FFFF_FFFF}d e\x{FFFF_FFFF}e f\x{FFFF_FFFF}f</p>",
      textSigle => $text_sigle
    );
  };

  my ($fh, $tplfile) = korap_tempfile('script_out4');
  binmode($fh);
  print $fh encode_utf8($tpl); # => text_id=Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C
  close($fh);

  my (undef, $outzip) = korap_tempfile('script_out5');

  # because output 'textid=...' goes to STDERR (see script/tei2korapxml)
  binmode STDERR;

  stderr_like(
    sub { `cat '$tplfile' | perl '$script' -ti - > '$outzip'` },
    qr!tei2korapxml:.*? text_id=$text_sigle_esc!, # see above: print $fh encode_utf8($tpl);
  );
};


subtest 'Check structure parsing with defined foundry and folder' => sub {
  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti --inline-structures=myfoundry#mystr'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists_not('GOE/AGA/00000/struct/structure.xml', 'Structure not generated')
    ->unzip_xml('GOE/AGA/00000/myfoundry/mystr.xml')
    ->text_is('span[id=s3] *[name=type]', 'Autobiographie', 'text content')
    ->text_is('#s3 *[name=type]', 'Autobiographie', 'text content')
    ->attr_is('#s0','to','1266')
    ->attr_is('#s0','l','1')
    ->attr_is('#s18','from','925')
    ->attr_is('#s18','to','1266')
    ->attr_is('#s18','l','5')
    ;

  $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti --inline-structures=myfoundry'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists_not('GOE/AGA/00000/struct/structure.xml', 'Structure not generated')
    ->unzip_xml('GOE/AGA/00000/myfoundry/structure.xml')
    ->text_is('span[id=s3] *[name=type]', 'Autobiographie', 'text content')
    ->text_is('#s3 *[name=type]', 'Autobiographie', 'text content')
    ->attr_is('#s0','to','1266')
    ->attr_is('#s0','l','1')
    ->attr_is('#s18','from','925')
    ->attr_is('#s18','to','1266')
    ->attr_is('#s18','l','5')
    ;
};

subtest 'Check structure parsing with skipped tags' => sub {
  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/struct/structure.xml', 'Structure generated')
    ->unzip_xml('GOE/AGA/00000/struct/structure.xml')
    ->text_is('layer spanList span fs f', 'text')
    ->text_is('#s5 fs f[name=name]','head')
    ->text_is('#s6 fs f[name=name]','s')
    ->text_is('#s7 fs f[name=name]','head')
    ->text_is('#s8 fs f[name=name]','s')
    ->text_is('#s9 fs f[name=name]','quote')
    ->text_is('#s10 fs f[name=name]','s')
    ;

  $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti --skip-inline-tags=head'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/struct/structure.xml', 'Structure generated')
    ->unzip_xml('GOE/AGA/00000/struct/structure.xml')
    ->text_is('layer spanList span fs f', 'text')
    ->text_is('#s5 fs f[name=name]','s')
    ->text_is('#s6 fs f[name=name]','s')
    ->text_is('#s7 fs f[name=name]','quote')
    ->text_is('#s8 fs f[name=name]','s')
    ;

  $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti --skip-inline-tags=head,quote'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/struct/structure.xml', 'Structure generated')
    ->unzip_xml('GOE/AGA/00000/struct/structure.xml')
    ->text_is('layer spanList span fs f', 'text')
    ->text_is('#s5 fs f[name=name]','s')
    ->text_is('#s6 fs f[name=name]','s')
    ->text_is('#s7 fs f[name=name]','s')
    ;
};


subtest 'Check parsing but skip inline tokens' => sub {
  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my $t = test_tei2korapxml(
    tmp => 'script_skip_inline_tokens_1',
    file => $file,
    param => '-ti --skip-inline-tokens'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/data.xml', 'Data exists')
    ->file_exists('GOE/AGA/00000/struct/structure.xml', 'Structure generated')
    ->file_exists_not('GOE/AGA/00000/tokens/morpho.xml', 'Morpho not generated')
    ;

  $t = test_tei2korapxml(
    tmp => 'script_skip_inline_tokens_2',
    file => $file,
    param => '-ti --skip-inline-tokens --inline-tokens=myfoundry#myfile'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists('GOE/AGA/00000/struct/structure.xml', 'Structure generated')
    ->file_exists_not('GOE/AGA/00000/tokens/morpho.xml', 'Morpho not generated')
    ->file_exists_not('GOE/AGA/00000/myfoundry/myfile.xml', 'Morpho not generated')
    ;
};


subtest 'Check Inline annotations' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample_tagged.i5.xml');

  my $t = test_tei2korapxml(
    file => $file,
    env => 'KORAPXMLTEI_INLINE=1',
    tmp => 'script_tagged',
    param => '--no-tokenizer'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->stderr_like(qr!KORAPXMLTEI_INLINE is deprecated!)

    # Check zip using xml loy
    ->unzip_xml('GOE/AGA/00000/tokens/morpho.xml')

    ->attr_is('layer', 'docid', 'GOE_AGA.00000')
    ->attr_is('spanList span:nth-child(1)', 'id', 's0')
    ->attr_is('spanList span:nth-child(1)', 'from', '75')
    ->attr_is('spanList span:nth-child(1)', 'to', '81')
    ->attr_is('spanList span:nth-child(1)', 'l', '7')

    ->attr_is('span#s0 > fs', 'type', 'lex')
    ->attr_is('span#s0 > fs', 'xmlns', 'http://www.tei-c.org/ns/1.0')
    ->attr_is('span#s0 > fs > f > fs > f:nth-child(1)', 'name', 'pos')
    ->text_is('span#s0 > fs > f > fs > f:nth-child(1)', 'A')
    ->attr_is('span#s0 > fs > f > fs > f:nth-child(2)', 'name', 'msd')
    ->text_is('span#s0 > fs > f > fs > f:nth-child(2)', '@NH')

    ->attr_is('span#s25', 'from', '259')
    ->attr_is('span#s25', 'to', '263')
    ->attr_is('span#s25', 'l', '7')
    ->attr_is('span#s25 > fs > f > fs > f:nth-child(1)', 'name', 'pos')
    ->text_is('span#s25 > fs > f > fs > f:nth-child(1)', 'PRON')
    ->attr_is('span#s25 > fs > f > fs > f:nth-child(2)', 'name', 'msd')
    ->text_is('span#s25 > fs > f > fs > f:nth-child(2)', '@NH')

    ->attr_is('span#s58', 'from', '495')
    ->attr_is('span#s58', 'to', '500')
    ->attr_is('span#s58', 'l', '7')
    ->attr_is('span#s58 > fs > f > fs > f:nth-child(1)', 'name', 'pos')
    ->text_is('span#s58 > fs > f > fs > f:nth-child(1)', 'N')
    ->attr_is('span#s58 > fs > f > fs > f:nth-child(2)', 'name', 'msd')
    ->text_is('span#s58 > fs > f > fs > f:nth-child(2)', '@NH')

    ->attr_is('span#s119', 'from', '914')
    ->attr_is('span#s119', 'to', '925')
    ->attr_is('span#s119', 'l', '7')
    ->attr_is('span#s119 > fs > f > fs > f:nth-child(1)', 'name', 'pos')
    ->text_is('span#s119 > fs > f > fs > f:nth-child(1)', 'A')
    ->attr_is('span#s119 > fs > f > fs > f:nth-child(2)', 'name', 'msd')
    ->text_is('span#s119 > fs > f > fs > f:nth-child(2)', '@NH')
    ->element_exists_not('span#s120')
    ;
};


subtest 'Check file structure with defined folder and filenames' => sub {
  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');
  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti --base-foundry=root --data-file=primary --header-file=meta'
  )->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->file_exists_not('GOE/AGA/00000/header.xml', 'Header not there')
    ->file_exists_not('GOE/AGA/header.xml', 'Header not there')
    ->file_exists_not('GOE/header.xml', 'Header not there')
    ->file_exists_not('GOE/AGA/00000/data.xml', 'Data not there')
    ->file_exists_not('GOE/AGA/00000/base/tokens_conservative.xml', 'Tokens not there')
    ->file_exists_not('GOE/AGA/00000/base/tokens_aggressive.xml', 'Tokens not there')
    ->file_exists('GOE/AGA/00000/meta.xml', 'Header there')
    ->file_exists('GOE/AGA/meta.xml', 'Header there')
    ->file_exists('GOE/meta.xml', 'Header there')
    ->file_exists('GOE/AGA/00000/primary.xml', 'Data there')
    ->file_exists('GOE/AGA/00000/root/tokens_conservative.xml', 'Tokens there')
    ->file_exists('GOE/AGA/00000/root/tokens_aggressive.xml', 'Tokens there')
    ;

  $t->unzip_xml('GOE/AGA/00000/primary.xml')
    ->content_like(qr/\Q&quot;Kriegstheater&quot;\E/)
    ;
};

subtest 'Check Inline annotations with defined foundry and folder' => sub {
  # Load example file
  my $file = catfile($f, 'data', 'goe_sample_tagged.i5.xml');

  my $t = test_tei2korapxml(
    file => $file,
    tmp => 'script_tagged',
    param => '--inline-tokens=myfoundry#myfile --skip-inline-token-annotations=0 --no-tokenizer'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->stderr_unlike(qr!KORAPXMLTEI_INLINE is deprecated!)

    ->file_exists_not('GOE/AGA/00000/tokens/morpho.xml', 'Morpho not generated')

    # Check zip using xml loy
    ->unzip_xml('GOE/AGA/00000/myfoundry/myfile.xml')

    ->attr_is('layer', 'docid', 'GOE_AGA.00000')
    ->attr_is('spanList span:nth-child(1)', 'id', 's0')
    ->attr_is('spanList span:nth-child(1)', 'from', '75')
    ->attr_is('spanList span:nth-child(1)', 'to', '81')
    ->attr_is('spanList span:nth-child(1)', 'l', '7')
    ;

  $t = test_tei2korapxml(
    file => $file,
    tmp => 'script_tagged',
    param => '--inline-tokens=myfoundry --skip-inline-token-annotations=0 --no-tokenizer'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)

    ->file_exists_not('GOE/AGA/00000/tokens/morpho.xml', 'Morpho not generated')

    # Check zip using xml loy
    ->unzip_xml('GOE/AGA/00000/myfoundry/morpho.xml')

    ->attr_is('layer', 'docid', 'GOE_AGA.00000')
    ->attr_is('spanList span:nth-child(1)', 'id', 's0')
    ->attr_is('spanList span:nth-child(1)', 'from', '75')
    ->attr_is('spanList span:nth-child(1)', 'to', '81')
    ->attr_is('spanList span:nth-child(1)', 'l', '7')
    ;
};

subtest 'Check Inline annotations with untagged file' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my ($fh, $outzip) = korap_tempfile('script_untagged');

  # Generate zip file (unportable!)
  stderr_like(
    sub { `cat '$file' | perl '$script' --skip-token-inline-annotations=0 --no-tokenizer - > '$outzip'` },
    qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!,
    'Processing 1'
  );

  # TODO: there should be a better way to test this
  stderr_unlike(
    sub { `cat '$file' | perl '$script' --skip-token-inline-annotations=0 --no-tokenizer - > '$outzip'` },
    qr!.*undefined value.*!,
    'Processing 2'
  );
  #

  ok(-e $outzip, "File $outzip exists");

  my $zip = IO::Uncompress::Unzip->new(
    $outzip,
    Name => 'GOE/AGA/00000/tokens/morpho.xml'
  );
  ok((not $zip), 'missing morpho.xml');

  $zip = IO::Uncompress::Unzip->new(
    $outzip,
    Name => 'GOE/AGA/00000/struct/structure.xml'
  );
  ok($zip, 'found structure.xml');
};


subtest 'Check input encoding' => sub {

  # Load example file
  test_tei2korapxml(
    file => catfile($f, 'data', 'goe_sample.i5.xml'),
    tmp => 'script_utf8_enc',
    param => '--skip-inline-token-annotations=0 --no-tokenizer',
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->unzip_xml('GOE/AGA/00000/data.xml')
    ->content_like(qr/\Q&quot;Kriegstheater&quot;\E/)
    ->content_like(qr/\QTür&#39;\E/)
    ;

  test_tei2korapxml(
    file => catfile($f, 'data', 'goe_sample.i5.iso.xml'),
    param => '--skip-inline-token-annotations=0 --no-tokenizer',
    tmp => 'script_iso_enc'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=GOE_AGA\.00000!)
    ->unzip_xml('GOE/AGA/00000/data.xml')
    ->content_like(qr/\Q&quot;Kriegstheater&quot;\E/)
    ->content_like(qr/\QTür&#39;\E/)
    ;
};

subtest 'Check encoding with utf-8 sigle' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'wdd_sample.i5.xml');

  my $t = test_tei2korapxml(
      tmp   => 'script_sigle',
      file  => $file,
      param => "-ti"
  )->stderr_like(qr!tei2korapxml:.*? text_id=WDD19_ß0000\.10317!)
  ->stderr_unlike(qr!Debugging is activated!);

  $t->unzip_xml('WDD19/ß0000/10317/header.xml')
      ->text_is('idsHeader fileDesc titleStmt textSigle', 'WDD19/ß0000.10317');

  $t->unzip_xml('WDD19/ß0000/10317/data.xml')
    ->attr_is('raw_text', 'docid', 'WDD19_ß0000.10317');

  $t->unzip_xml('WDD19/ß0000/10317/struct/structure.xml')
      ->attr_is('layer', 'docid', 'WDD19_ß0000.10317');

  $t->unzip_xml('WDD19/ß0000/10317/base/tokens_conservative.xml')
      ->attr_is('layer', 'docid', 'WDD19_ß0000.10317');
};

subtest 'Check entity replacement' => sub {
  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'text_with_entities.i5.xml'),
    tmp => 'script_entity_replacement',
    param => '-ti'
  )->stderr_like(qr!tei2korapxml:.*? text_id=CORP_DOC.00003!);

  $t->unzip_xml('CORP/DOC/00003/data.xml')
    ->content_like(qr!üüü  Aα≈„▒░▓█╗┐┌╔═─┬╦┴╩╝┘└╚│║┼╬┤╣╠├•ˇčˆ†‡ě€ƒ…‗ıι“„▄‹‘‚—–νœŒωΩ‰φπϖř”ρ›’‘šŠσ□■▪⊂˜™▀ŸžŽ!);

  $t->unzip_xml('CORP/DOC/00003/header.xml')
    ->content_like(qr!üüü x α•α y!);
};

subtest 'Test Log' => sub {
  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-l=warn --no-tokenizer'
  )->stderr_is('');
};


subtest 'Broken data testing' => sub {
  my $file = catfile($f, 'data', 'wikipedia.txt');

  my $t = test_tei2korapxml(
    tmp => 'script_ginkgo',
    file => $file,
    param => '-ti',
    env => 'KORAPXMLTEI_DEBUG=1'
  )->stderr_like(qr!No opened zip file to close!)
  ->stderr_like(qr!Debugging is activated!);
};

subtest 'Required version testing' => sub {
  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-rv=2.2.2'
  )->stderr_like(qr!^Required version 2\.2\.2 mismatches version!);

  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '--required-version=2.2'
  )->stderr_like(qr!^Required version 2\.2 mismatches version!);

  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-rv=' . $KorAP::XML::TEI::Tokenizer::KorAP::VERSION . ' --no-tokenizer'
  )->stderr_like(qr!GOE_AGA\.00000!);

  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-rv=   "  ' . $KorAP::XML::TEI::Tokenizer::KorAP::VERSION . ' "  --no-tokenizer'
  )->stderr_like(qr!GOE_AGA\.00000!);
};

subtest 'Standard TEI P5 testing' => sub {

  my $t = test_tei2korapxml(
      file => catfile($f, 'data', 'icc_german_sample.p5.xml'),
      param => '--xmlid-to-textsigle \'ICC.German\.([^.]+\.[^.]+)\.(.+)@ICCGER/$1/$2\' -s -ti',
      tmp => 'script_utf8_enc'
  )->stderr_like(qr!tei2korapxml:.*? text_id=ICCGER/DeReKo-WPD17\.S00-18619!);

  $t->unzip_xml('ICCGER/DeReKo-WPD17/E51-96136/data.xml')
      ->content_like(qr/Recht auf persönliches Hab und Gut/);

  $t->unzip_xml('ICCGER/CCBY-LTE/MJB-00001/header.xml')
      ->text_is('textClass > classCode[scheme=ICC]', 'Learned_Technology', 'classCode is correctly extracted');

};

subtest 'Require tokenizer' => sub {

  my $t = test_tei2korapxml(
      file => catfile($f, 'data', 'icc_german_sample.p5.xml'),
      tmp => 'script_utf8_enc'
  )->stderr_like(qr!No tokenizer chosen!);
};

subtest 'Test handling of textSigle in text' => sub {

  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'text_with_textsigle_in_text.i5.xml'),
    tmp => 'script_out',
    param => '-ti'
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=CORP_DOC.00001!)
    ->stderr_unlike(qr!line with closing text-body tag 'text' contains additional information!);
};

subtest 'Handling of whitespace at linebreaks' => sub {
  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'stadigmer.p5.xml'),
    tmp => 'script_out',
    param => '-s -ti',
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=NO_000\.00000!);
    $t->unzip_xml('NO/000/00000/data.xml')
      ->content_like(qr/har lurt/)
      ->content_like(qr/etter at/)
      ->content_like(qr/en stund/)
      ->content_like(qr/skjønner med/)
      ->content_like(qr/og det/)
      ->content_like(qr/stadig mer/)
      ->content_like(qr/sitt, og/)
      ->content_like(qr/tenkt å bli/)
      ->content_like(qr/er både/)
      ;
};

subtest 'Write to output' => sub {

  my $temp_out = korap_tempfile('out');

  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'stadigmer.p5.xml'),
    tmp => 'script_out',
    param => '-s -ti -o "' . $temp_out . '"',
    )->stderr_like(qr!tei2korapxml:.*? text_id=NO_000\.00000!)
      ->stdout_is('');

  my $content;
  open(X, '<' . $temp_out);
  binmode(X);
  $content .= <X> while !eof(X);
  close(X);
  $t->{stdout} = $content;

  $t->unzip_xml('NO/000/00000/data.xml')
      ->content_like(qr/har lurt/)
      ->content_like(qr/etter at/)
      ->content_like(qr/en stund/)
      ->content_like(qr/skjønner med/)
      ->content_like(qr/og det/)
      ->content_like(qr/stadig mer/)
      ->content_like(qr/sitt, og/)
      ->content_like(qr/tenkt å bli/)
      ->content_like(qr/er både/)
      ;

  unlink $temp_out;
};

subtest 'Handling of dependency data (1)' => sub {
  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'SKU21.head.i5.xml'),
    tmp => 'script_out',
    param => '-s --no-tokenizer --inline-tokens=csc#morpho',
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=SKU21_JAN\.00001!);
  $t->unzip_xml('SKU21/JAN/00001/data.xml')
    ->content_like(qr/cgICpWb AQNFU/)
    ->content_like(qr/LhyS OLHV/)
    ->content_like(qr/kdQVs hunIRQIN/)
    ;

  $t->unzip_xml('SKU21/JAN/00001/csc/morpho.xml')
    ->attr_is('spanList span:nth-child(2)', 'id', 's1')
    ->attr_is('#s1', 'from', '5')
    ->attr_is('#s1', 'to', '9')
    ->text_is('#s1 fs f fs f[name="deprel"]', 'name')
    ->text_is('#s1 fs f fs f[name="head"]', '3')
    ->text_is('#s1 fs f fs f[name="lemma"]', 'kCXD')
    ->text_is('#s1 fs f fs f[name="msd"]', 'SUBCAT_Prop|CASECHANGE_Up|OTHER_UNK')
    ->text_is('#s1 fs f fs f[name="n"]', '2')
    ->text_is('#s1 fs f fs f[name="pos"]', 'N')
    ;
};

subtest 'Handling of dependency data (2)' => sub {
  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'SKU21.head.i5.xml'),
    tmp => 'script_out',
    param => '-s --no-tokenizer ' .
    '--inline-tokens=csc#morpho ' .
    '--inline-dependencies=!csc ' .
    '--no-skip-inline-token-annotations',
  )
    ->stderr_like(qr!tei2korapxml:.*? text_id=SKU21_JAN\.00001!)
    ->stderr_like(qr!tei2korapxml:.*? text_id=SKU21_JAN\.00002!)
    ->stderr_like(qr!tei2korapxml:.*? text_id=SKU21_JAN\.00003!)
    ;

  $t->unzip_xml('SKU21/JAN/00001/data.xml')
    ->content_like(qr/cgICpWb AQNFU/)
    ->content_like(qr/LhyS OLHV/)
    ->content_like(qr/kdQVs hunIRQIN/)
    ;

  $t->unzip_xml('SKU21/JAN/00001/csc/morpho.xml')
    ->attr_is('spanList span:nth-child(2)', 'id', 's1')
    ->attr_is('#s1', 'from', '5')
    ->attr_is('#s1', 'to', '9')
    ->text_is('#s1 fs f fs f[name="lemma"]', 'kCXD')
    ->text_is('#s1 fs f fs f[name="msd"]', 'SUBCAT_Prop|CASECHANGE_Up|OTHER_UNK')
    ->text_is('#s1 fs f fs f[name="pos"]', 'N')
    ->element_exists_not('#s1 fs f fs f[name="n"]')
    ->element_exists_not('#s1 fs f fs f[name="deprel"]')
    ->element_exists_not('#s1 fs f fs f[name="head"]')
    ;

  $t->unzip_xml('SKU21/JAN/00001/csc/dependency.xml')
    ->attr_is('spanList span:nth-child(2)', 'id', 's1_n2')
    ->attr_is('#s1_n2', "from", "5")
    ->attr_is('#s1_n2', "to", "9")
    ->attr_is('#s1_n2 rel', "label", "name")
    ->attr_is('#s1_n2 rel span', "from", '10')
    ->attr_is('#s1_n2 rel span', "to", '15')
    ;

  $t->unzip_xml('SKU21/JAN/00002/csc/dependency.xml')
    ->attr_is('spanList span:nth-child(2)', 'id', 's1_n2')
    ->attr_is('#s1_n2', "from", "4")
    ->attr_is('#s1_n2', "to", "5")
    ->attr_is('#s1_n2 rel', "label", "poss")
    ->attr_is('#s1_n2 rel span', "from", '6')
    ->attr_is('#s1_n2 rel span', "to", '12')
    ;
};


done_testing;
