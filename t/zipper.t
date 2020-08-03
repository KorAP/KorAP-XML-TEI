use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile/;
use IO::Uncompress::Unzip;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile!;

require_ok('KorAP::XML::TEI::Zipper');

subtest 'Create Zipper' => sub {
  my $data;
  my ($fh, $outzip) = korap_tempfile('zipper');

  my $zip = KorAP::XML::TEI::Zipper->new('', $outzip);
  $fh->close;

  ok($zip, 'Zipper initialized');

  ok($zip->new_stream('data/file1.txt')->print('hello'), 'Write to initial stream');
  ok($zip->new_stream('data/file2.txt')->print('world'), 'Write to appended stream');

  $zip->close;

  ok(-e $outzip, 'Zip exists');

  my $unzip = IO::Uncompress::Unzip->new($outzip, Name => 'data/file1.txt');

  $data .= $unzip->getline while !$unzip->eof;
  ok($unzip->close, 'Closed');

  is($data, 'hello', 'Data correct');

  $unzip = IO::Uncompress::Unzip->new($outzip, Name => 'data/file2.txt');

  $data = '';
  $data .= $unzip->getline while !$unzip->eof;
  ok($unzip->close, 'Closed');

  is($data, 'world', 'Data correct');
};


subtest 'Create Zipper with root dir "."' => sub {
  my $data;
  my ($fh, $outzip) = korap_tempfile('zipper');

  my $zip = KorAP::XML::TEI::Zipper->new('.', $outzip);
  $fh->close;

  ok($zip, 'Zipper initialized');

  ok($zip->new_stream('data/file1.txt')->print('hello'), 'Write to initial stream');
  $zip->close;
  ok(-e $outzip, 'Zip exists');

  ok(IO::Uncompress::Unzip->new($outzip, Name => 'data/file1.txt'), 'File exists');
};


subtest 'Create Zipper with root dir "subdir"' => sub {
  my $data;
  my ($fh, $outzip) = korap_tempfile('zipper');

  my $zip = KorAP::XML::TEI::Zipper->new('subdir', $outzip);
  $fh->close;

  ok($zip, 'Zipper initialized');

  ok($zip->new_stream('data/file1.txt')->print('hello'), 'Write to initial stream');
  $zip->close;
  ok(-e $outzip, 'Zip exists');

  ok(IO::Uncompress::Unzip->new($outzip, Name => 'subdir/data/file1.txt'), 'File exists');
  ok(!IO::Uncompress::Unzip->new($outzip, Name => 'data/file1.txt'), 'File exists not');
};

subtest 'Create Zipper with root dir "./"' => sub {
  my $data;
  my ($fh, $outzip) = korap_tempfile('zipper');

  my $zip = KorAP::XML::TEI::Zipper->new('./', $outzip);
  $fh->close;

  ok($zip, 'Zipper initialized');

  ok($zip->new_stream('data/file1.txt')->print('hello'), 'Write to initial stream');
  $zip->close;
  ok(-e $outzip, 'Zip exists');

  # Uncompress GOE/header.xml from zip file
  ok(IO::Uncompress::Unzip->new($outzip, Name => 'data/file1.txt'), 'File exists');
};


done_testing;
