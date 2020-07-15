use strict;
use warnings;
use Test::More;
#use File::Basename 'dirname'; # not needed yet
use File::Spec::Functions qw/catfile/;
use File::Temp qw/ tempfile :POSIX /;;
use IO::Uncompress::Unzip;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

our %ENV;
# default: remove temp. file created by func. tempfile
#  to keep temp. files use e.g. 'KORAPXMLTEI_DONTUNLINK=1 prove -lr t/script.t'
my $_UNLINK = $ENV{KORAPXMLTEI_DONTUNLINK}?0:1;

require_ok('KorAP::XML::TEI::Zipper');

my $data;
(my $fh, my $outzip) = tempfile("KorAP-XML-TEI_zipper_XXXXXXXXXX", SUFFIX => ".tmp", TMPDIR => 1, UNLINK => $_UNLINK);

my $zip = KorAP::XML::TEI::Zipper->new($outzip); # TODO: allow also filehandle
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


# Uncompress GOE/header.xml from zip file
$unzip = IO::Uncompress::Unzip->new($outzip, Name => 'data/file2.txt');

$data = '';
$data .= $unzip->getline while !$unzip->eof;
ok($unzip->close, 'Closed');

is($data, 'world', 'Data correct');

done_testing;
