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

subtest 'Basic processing' => sub {

  my $t = test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-ti'
  )->stderr_like(qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!);


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
    ->element_count_is('', 196);

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
    ->stderr_like(qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!)
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


subtest 'Test Tokenizations' => sub {

  my $t = test_tei2korapxml(
    file => catfile($f, 'data', 'text_with_blanks.i5.xml'),
    tmp => 'script_out3',
    param => '-ti'
  )->stderr_like(qr!tei2korapxml: .*? text_id=CORP_DOC.00001!);

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
    ->stderr_like(qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!)
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
  binmode STDERR, qw{ :encoding(UTF-8) };

  stderr_like(
    sub { `cat '$tplfile' | perl '$script' -ti > '$outzip'` },
    qr!tei2korapxml: .*? text_id=$text_sigle_lax!, # see above: print $fh encode_utf8($tpl);
  );
};


subtest 'Check Inline annotations' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample_tagged.i5.xml');

  my $t = test_tei2korapxml(
    file => $file,
    env => 'KORAPXMLTEI_INLINE=1',
    tmp => 'script_tagged'
  )
    ->stderr_like(qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!)

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

subtest 'Check Inline annotations with untagged file' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my ($fh, $outzip) = korap_tempfile('script_untagged');

  # Generate zip file (unportable!)
  stderr_like(
    sub { `cat '$file' | KORAPXMLTEI_INLINE=1 perl '$script' > '$outzip'` },
    qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
    'Processing 1'
  );

  # TODO: there should be a better way to test this
  stderr_unlike(
    sub { `cat '$file' | KORAPXMLTEI_INLINE=1 perl '$script' > '$outzip'` },
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


subtest 'Test Log' => sub {
  test_tei2korapxml(
    tmp => 'script_out',
    file => $file,
    param => '-l=warn'
  )->stderr_is('');
};


done_testing;
