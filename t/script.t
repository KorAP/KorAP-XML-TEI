use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use File::Temp ':POSIX';
use IO::Uncompress::Unzip qw(unzip $UnzipError);

use Test::XML::Simple;
use Test::More;
use Test::Output;

my $f = dirname(__FILE__);
my $script = catfile($f, '..', 'script', 'tei2korapxml');
ok(-f $script, 'Script found');

stderr_is(
  sub { system('perl', $script, '--help') },
  "This program is called from inside another script.\n",
  'Help'
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

# Uncompress GOE/header.xml from zip file
my $zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/header.xml');

ok($zip, 'Zip-File is created');

# Read GOE/header.xml
my $header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

# This is slow - should be improved for more tests
xml_is($header_xml, '//korpusSigle', 'GOE', 'korpusSigle');
xml_is($header_xml, '//h.title[@type="main"]', 'Goethes Werke', 'h.title');
xml_is($header_xml, '//h.author', 'Goethe, Johann Wolfgang von', 'h.author');
xml_is($header_xml, '//pubDate[@type="year"]', '1982', 'pubDate');


# Uncompress GOE/AGA/header.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/header.xml');

ok($zip, 'Zip-File is found');

# Read GOE/header.xml
$header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

# This is slow - should be improved for more tests
# print $header_xml;
xml_is($header_xml, '//dokumentSigle', 'GOE/AGA', 'dokumentSigle');
xml_is($header_xml, '//d.title', 'Goethe: Autobiographische Schriften II, (1817-1825, 1832)', 'd.title');
xml_is($header_xml, '//creatDate', '1820-1822', 'creatDate');


# Uncompress GOE/AGA/00000/header.xml from zip file
$zip = IO::Uncompress::Unzip->new($outzip, Name => 'GOE/AGA/00000/header.xml');

ok($zip, 'Zip-File is found');

# Read GOE/header.xml
$header_xml = '';
$header_xml .= $zip->getline while !$zip->eof;
ok($zip->close, 'Closed');

# This is slow - should be improved for more tests
xml_is($header_xml, '//textSigle', 'GOE/AGA.00000', 'textSigle');
xml_is($header_xml, '//analytic/h.title[@type="main"]', 'Campagne in Frankreich', 'h.title');


done_testing;
