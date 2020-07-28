use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use Encode qw!encode_utf8 decode_utf8 encode!;
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use Test::More;
use Test::Output;
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile!;

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

my ($fh, $outzip) = korap_tempfile('script_out');

# Generate zip file (unportable!)
stderr_like(
  sub { `cat '$file' | perl '$script' -ti > '$outzip'` },
# approaches for working with $fh (also better use OO interface then)
#  sub { open STDOUT, '>&', $fh; system("cat '$file' | perl '$script'") },
#  sub { open(my $pipe, "cat '$file' | perl '$script'|"); while(<$pipe>){$fh->print($_)}; $fh->close },
#  sub {
#    defined(my $pid = fork) or die "fork: $!";
#    if (!$pid) {
#      open STDOUT, '>&', $fh;
#      exec "cat '$file' | perl '$script'"
#    }
#    waitpid $pid, 0;
#    $fh->close;
#  },
  qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
  'Processing'
);

ok(-e $outzip, "File $outzip exists");

# Uncompress GOE/header.xml from zip file
my $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/header.xml');

ok($zip, 'Zip-File is created');

# TODO: check wrong encoding in header-files (compare with input document)!
# Read GOE/header.xml
my $header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

my $t = Test::XML::Loy->new($header_xml);

$t->text_is('korpusSigle', 'GOE', 'korpusSigle')
  ->text_is('h\.title[type=main]', 'Goethes Werke', 'h.title')
  ->text_is('h\.author', 'Goethe, Johann Wolfgang von', 'h.author')
  ->text_is('pubDate[type=year]', '1982', 'pubDate');


# Uncompress GOE/AGA/header.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/header.xml');

ok($zip, 'Zip-File is found');

# Read GOE/AGA/header.xml
$header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($header_xml);

$t->text_is('dokumentSigle', 'GOE/AGA', 'dokumentSigle')
  ->text_is('d\.title', 'Goethe: Autobiographische Schriften II, (1817-1825, 1832)', 'd.title')
  ->text_is('creatDate', '1820-1822', 'creatDate');

# Uncompress GOE/AGA/00000/header.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/header.xml');

ok($zip, 'Zip-File is found');

# Read GOE/AGA/00000/header.xml
$header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($header_xml);
$t->text_is('textSigle', 'GOE/AGA.00000', 'textSigle')
  ->text_is('analytic > h\.title[type=main]', 'Campagne in Frankreich', 'h.title');

# Uncompress GOE/AGA/00000/data.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/data.xml');

ok($zip, 'Zip-File is found');

# Read GOE/AGA/00000/data.xml
my $data_xml = '';
$data_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($data_xml);
$t->attr_is('raw_text', 'docid', 'GOE_AGA.00000', 'text id')
  ->text_like('raw_text > text', qr!^Campagne in Frankreich 1792.*?uns allein begl.*cke\.$!, 'text content');

# Uncompress GOE/AGA/00000/struct/structure.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/struct/structure.xml');

ok($zip, 'Zip-File is found');

# Read GOE/AGA/00000/struct/structure.xml
my $struct_xml = '';
$struct_xml .= $zip->getline while !$zip->eof;

ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($struct_xml);
$t->text_is('span[id=s3] *[name=type]', 'Autobiographie', 'text content');

$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens.xml');
ok(!$zip, 'External not generated');

# Uncompress GOE/AGA/00000/base/tokens_aggressive.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens_aggressive.xml');

# Read GOE/AGA/00000/base/tok.xml
my $tokens_xml = '';
$tokens_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($tokens_xml);
$t->attr_is('spanList span:nth-child(1)', 'to', 8);

$t->attr_is('spanList span#t_1', 'from', 9);
$t->attr_is('spanList span#t_1', 'to', 11);

$t->attr_is('spanList span#t_67', 'from', 427);
$t->attr_is('spanList span#t_67', 'to', 430);

$t->attr_is('spanList span#t_214', 'from', 1209);
$t->attr_is('spanList span#t_214', 'to', 1212);

$t->element_count_is('spanList span', 227);


# Uncompress GOE/AGA/00000/base/tokens_conservative.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens_conservative.xml');

$tokens_xml = '';
$tokens_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($tokens_xml);
$t->attr_is('spanList span:nth-child(1)', 'to', 8);

$t->attr_is('spanList span#t_1', 'from', 9);
$t->attr_is('spanList span#t_1', 'to', 11);

$t->attr_is('spanList span#t_67', 'from', 427);
$t->attr_is('spanList span#t_67', 'to', 430);

$t->attr_is('spanList span#t_214', 'from', 1209);
$t->attr_is('spanList span#t_214', 'to', 1212);

$t->element_count_is('spanList span', 227);


# Tokenize with external tokenizer
my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

my ($fh2, $outzip2) = korap_tempfile('script_out2');

stderr_like(
  sub { `cat '$file' | perl '$script' -tc='perl $cmd' > '$outzip2'` },
  qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
  'Processing'
);

# Uncompress GOE/AGA/00000/base/tokens.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip2, Name => 'GOE/AGA/00000/base/tokens.xml');
ok($zip, 'Found');
ok(!$zip->eof, 'Readable');

# Read GOE/AGA/00000/base/tokens.xml
$tokens_xml = '';
$tokens_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($tokens_xml);
$t->attr_is('spanList span:nth-child(1)', 'to', 8);

$t->attr_is('spanList span#t_1', 'from', 9);
$t->attr_is('spanList span#t_1', 'to', 11);

$t->attr_is('spanList span#t_67', 'from', 427);
$t->attr_is('spanList span#t_67', 'to', 430);

$t->attr_is('spanList span#t_214', 'from', 1209);
$t->attr_is('spanList span#t_214', 'to', 1212);

$t->element_count_is('spanList span', 227);


my ($fh3, $outzip3) = korap_tempfile('script_out3');


# ~ test conservative tokenization ~

$file = catfile($f, 'data', 'text_with_blanks.i5.xml');

stderr_like(
  sub { `cat '$file' | perl '$script' --ti > '$outzip3'` },
  qr!tei2korapxml: .*? text_id=CORP_DOC.00001!,
  'Processing'
);

ok(-e $outzip3, "File $outzip3 exists");

$zip = IO::Uncompress::Unzip->new($outzip3, Name => 'CORP/DOC/00001/base/tokens_conservative.xml');

ok($zip, 'Zip-File is created');

my $cons = '';
$cons .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($cons);
$t->attr_is('spanList span:nth-child(1)', 'to', 6);

$t->attr_is('spanList span#t_1', 'from', 7);
$t->attr_is('spanList span#t_1', 'to', 9);

$t->attr_is('spanList span#t_3', 'from', 12);
$t->attr_is('spanList span#t_3', 'to', 16);

$t->attr_is('spanList span#t_9', 'from', 36);
$t->attr_is('spanList span#t_9', 'to', 37);

$t->attr_is('spanList span#t_13', 'from', 44);
$t->attr_is('spanList span#t_13', 'to', 45);          # "

$t->attr_is('spanList span#t_14', 'from', 45);        # twenty-two
$t->attr_is('spanList span#t_14', 'to', 55);

$t->attr_is('spanList span#t_15', 'from', 55);        # "
$t->attr_is('spanList span#t_15', 'to', 56);

$t->attr_is('spanList span#t_19', 'from', 66);
$t->attr_is('spanList span#t_19', 'to', 67);

$t->element_count_is('spanList span', 20);


# ~ test aggressive tokenization ~

$zip = IO::Uncompress::Unzip->new($outzip3, Name => 'CORP/DOC/00001/base/tokens_aggressive.xml');

ok($zip, 'Zip-File is created');

my $aggr = '';
$aggr .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

$t = Test::XML::Loy->new($aggr);

$t->attr_is('spanList span:nth-child(1)', 'to', 6);

$t->attr_is('spanList span#t_1', 'from', 7);
$t->attr_is('spanList span#t_1', 'to', 9);

$t->attr_is('spanList span#t_3', 'from', 12);
$t->attr_is('spanList span#t_3', 'to', 16);

$t->attr_is('spanList span#t_9', 'from', 36);
$t->attr_is('spanList span#t_9', 'to', 37);

$t->attr_is('spanList span#t_13', 'from', 44);
$t->attr_is('spanList span#t_13', 'to', 45);          # "

$t->attr_is('spanList span#t_14', 'from', 45);        # twenty
$t->attr_is('spanList span#t_14', 'to', 51);

$t->attr_is('spanList span#t_15', 'from', 51);        # -
$t->attr_is('spanList span#t_15', 'to', 52);

$t->attr_is('spanList span#t_16', 'from', 52);        # two
$t->attr_is('spanList span#t_16', 'to', 55);

$t->attr_is('spanList span#t_17', 'from', 55);        # "
$t->attr_is('spanList span#t_17', 'to', 56);

$t->attr_is('spanList span#t_21', 'from', 66);
$t->attr_is('spanList span#t_21', 'to', 67);

$t->element_count_is('spanList span', 22);


subtest 'Check Tokenization Flags' => sub {

  # Get external tokenizer
  my $f = dirname(__FILE__);
  my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample.i5.xml');

  my ($fh, $outzip) = korap_tempfile('script_tokflags');

  # Generate zip file (unportable!)
  stderr_like(
    sub { `cat '$file' | perl '$script' -ti -tc 'perl $cmd' > '$outzip'` },
    qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
    'Processing'
  );

  ok(-e $outzip, "File $outzip exists");

  $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens_aggressive.xml');
  ok($zip, 'Aggressive generated');
  $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens_conservative.xml');
  ok($zip, 'Conservative generated');
  $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/base/tokens.xml');
  ok($zip, 'External generated');
};


subtest 'Test utf-8 handling' => sub {

  # Load template file
  $file = catfile($f, 'data', 'template.i5.xml');
  my $tpl = '';
  {
    open($fh, $file);
    $tpl .= <$fh> while !eof($fh);
    close($fh);
  }

  # Introduce invalid utf-8 characters
  my $text_sigle;
  { no warnings;
  # $text_sigle printed to file, without encoding: Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C
  # the utf8-sequence 'þ¿¿¿¿¿' encodes 32 bit of data (see 0x7FFF_FFFF in perlunicode)
  $text_sigle = "A\x{FFFF_FFFF}A_B\x{FFFF_FFFF}B.C\x{FFFF_FFFF}C" }
  # If CHECK is 0, encoding and decoding replace any malformed character with a substitution character.
  # � = substitution character
  my $text_sigle_lax = encode_utf8($text_sigle);
  my $text_sigle_esc = encode('UTF-8', $text_sigle);

  is(length($text_sigle), 11);     # A�A_B�B.C�C (char string => length(�) = 1)
  is(length($text_sigle_lax), 29); # Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C (byte string)
  is(length($text_sigle_esc), 17); # A�A_B�B.C�C (byte string => length(�) = 3)

  { no warnings;
  $tpl =~ s!\[KORPUSSIGLE\]!A\x{FFFF_FFFF}A!;
  $tpl =~ s!\[DOKUMENTSIGLE\]!A\x{FFFF_FFFF}A_B\x{FFFF_FFFF}B!;
  $tpl =~ s!\[TEXT\]!<p>d\x{FFFF_FFFF}d e\x{FFFF_FFFF}e f\x{FFFF_FFFF}f</p>! }
  $tpl =~ s!\[TEXTSIGLE\]!$text_sigle!;

  my ($fh, $tplfile) = korap_tempfile('script_out4');
  binmode($fh);
  print $fh encode_utf8($tpl); # => text_id=Aþ¿¿¿¿¿A_Bþ¿¿¿¿¿B.Cþ¿¿¿¿¿C
  close($fh);

  my (undef, $outzip) = korap_tempfile('script_out5');

  binmode STDERR, qw{ :encoding(UTF-8) }; # because output 'textid=...' goes to STDERR (see script/tei2korapxml)

  stderr_like(
    sub { `cat '$tplfile' | perl '$script' -ti > '$outzip'` },
    qr!tei2korapxml: .*? text_id=$text_sigle_lax!, # see above: print $fh encode_utf8($tpl);
  );
};


subtest 'Check Inline annotations' => sub {

  # Load example file
  my $file = catfile($f, 'data', 'goe_sample_tagged.i5.xml');

  my ($fh, $outzip) = korap_tempfile('script_tagged');

  # Generate zip file (unportable!)
  stderr_like(
    sub { `cat '$file' | KORAPXMLTEI_INLINE=1 perl '$script' > '$outzip'` },
    qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
    'Processing'
  );

  ok(-e $outzip, "File $outzip exists");

  my $zip = IO::Uncompress::Unzip->new(
    $outzip,
    Name => 'GOE/AGA/00000/tokens/morpho.xml'
  );
  ok($zip, 'Inline annotations');

  my $tokens;
  $tokens .= $zip->getline while !$zip->eof;
  ok($zip->close, 'Closed');

  my $t = Test::XML::Loy->new($tokens);

  $t->attr_is('layer', 'docid', 'GOE_AGA.00000')
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


done_testing;
