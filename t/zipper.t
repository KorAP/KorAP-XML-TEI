use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile/;
use Test::KorAP::XML::TEI qw!korap_tempfile!;
use IO::Uncompress::Unzip;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

require_ok('KorAP::XML::TEI::Zipper');

my $data;
my ($fh, $outzip) = korap_tempfile('zipper');

my $zip = KorAP::XML::TEI::Zipper->new($outzip);
$fh->close;

ok($zip, 'Zipper initialized');

ok($zip->new_stream('data/file1.txt')->print('hello'), 'Write to initial stream');
ok($zip->new_stream('data/file2.txt')->print('world'), 'Write to appended stream');

$zip->close;

ok(-e $outzip, 'Zip exists');

# Uncompress GOE/header.xml from zip file
my $unzip = IO::Uncompress::Unzip->new($outzip, Name => 'data/file1.txt');

$data .= $unzip->getline while !$unzip->eof;
ok($unzip->close, 'Closed');

is($data, 'hello', 'Data correct');


# Uncompress data/file2.txt from zip file
$unzip = IO::Uncompress::Unzip->new($outzip, Name => 'data/file2.txt');

$data = '';
$data .= $unzip->getline while !$unzip->eof;
ok($unzip->close, 'Closed');

is($data, 'world', 'Data correct');

done_testing;
