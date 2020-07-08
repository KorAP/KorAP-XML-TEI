use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use File::Temp ':POSIX';
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use Test::More;
use Test::Output;

use Test::XML::Loy;

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
my $outzip = tmpnam();

# Generate zip file (unportable!)
stderr_like(
  sub { `cat '$file' | perl '$script' > '$outzip'` },
  qr!tei2korapxml: .*? text_id=GOE_AGA\.00000!,
  'Processing'
);

ok(-e $outzip, "File $outzip exists");

# Uncompress GOE/header.xml from zip file
my $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/header.xml');

ok($zip, 'Zip-File is created');

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

done_testing;
