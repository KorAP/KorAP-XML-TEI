use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use IO::Uncompress::Unzip;
use open qw(:std :utf8); # assume utf-8 encoding

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use_ok('Test::KorAP::XML::TEI','korap_tempfile');
require_ok('KorAP::XML::TEI::Tokenizer::Aggressive');
require_ok('KorAP::XML::TEI::Tokenizer::Conservative');
require_ok('KorAP::XML::TEI::Zipper');

# Test aggressive
my $aggr = KorAP::XML::TEI::Tokenizer::Aggressive->new;
$aggr->tokenize("Der alte Mann");
is_deeply($aggr, [0,3,4,8,9,13]);

$aggr->reset->tokenize("Der alte bzw. der grau-melierte Mann");
is_deeply($aggr, [0,3,4,8,9,12,12,13,14,17,18,22,22,23,23,31,32,36]);

like(
  $aggr->reset->tokenize("Der")->to_string('a'),
  qr!id="t_0"!,
  'Chainable'
);

# Test conservative
my $cons = KorAP::XML::TEI::Tokenizer::Conservative->new;
$cons->tokenize("Der alte Mann");
is_deeply($cons, [0,3,4,8,9,13]);

$cons->reset->tokenize("Der alte bzw. der grau-melierte Mann");
is_deeply($cons, [0,3,4,8,9,12,12,13,14,17,18,31,32,36]);

$cons->reset->tokenize("  Der alte bzw. der grau-melierte Mann");
is_deeply($cons, [2,5,6,10,11,14,14,15,16,19,20,33,34,38]);

$cons->reset->tokenize(". Der");
is_deeply($cons, [0,1,2,5]);

$cons->reset->tokenize(" . Der");
is_deeply($cons, [1,2,3,6]);

$cons->reset->tokenize("   . Der");
is_deeply($cons, [3,4,5,8]);

$cons->reset->tokenize("... Der");
is_deeply($cons, [0,1,1,2,2,3,4,7]);

$cons->reset->tokenize(".Der");
is_deeply($cons, [0,1,1,4]);

$cons->reset->tokenize(".Der.... ");
is_deeply($cons, [0,1,1,4,4,5,5,6,6,7,7,8]);

$cons->reset->tokenize("..Der.... ");
is_deeply($cons, [0,1,1,2,2,5,5,6,6,7,7,8,8,9]);

$cons->reset->tokenize(". Der.... ");
is_deeply($cons, [0,1,2,5,5,6,6,7,7,8,8,9]);

$cons->reset->tokenize(". .Der.... ");
is_deeply($cons, [0,1,2,3,3,6,6,7,7,8,8,9,9,10]);

$cons->reset->tokenize("Der\talte\nMann");
is_deeply($cons, [0,3,4,8,9,13]);

## Test data
my $dataf = catfile(dirname(__FILE__), 'data', 'wikipedia.txt');
my $data = '';

ok(open(my $fh, '<' . $dataf), 'Open file wikipedia.txt');

while (!eof($fh)) {
  $data .= <$fh>
};

ok(close($fh), 'Close file wikipedia.txt');

is(134996, length($data));

$aggr->reset->tokenize($data);
is_deeply([@{$aggr}[0..25]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,49,49,50,50,57,58,66,67,72,72,73]);
is(47112, scalar(@$aggr));

$cons->reset->tokenize($data);
is_deeply([@{$cons}[0..21]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,57,58,66,67,72,72,73]);
is(42412, scalar(@$cons));

## check tokenization of 'Community-Ämter aufgestiegen'
##  from @{cons}[19518] (=66070) to @{cons}[19519] (=66085) => 'Community-Ämter'
##  from @{cons}[19520] (=66086) to @{cons}[19521] (=66098) => 'aufgestiegen'
my @vals_got=(66070,66085,66086,66098);
my @vals_exp; push @vals_exp, @{$cons}[$_] for(19518,19519,19520,19521);
is_deeply([@vals_exp], [@vals_got]);

$cons->reset->tokenize("Community-\xc4mter aufgestiegen");
is_deeply($cons, [0,15,16,28]);

$dataf = catfile(dirname(__FILE__), 'data', 'wikipedia_small.txt');
$data = '';
ok(open($fh, '<' . $dataf), 'Open file wikipedia_small.txt');
while (!eof($fh)) {
  $data .= <$fh>
};
ok(close($fh), 'Close file wikipedia_small.txt');

$aggr->reset->tokenize($data);
is_deeply([@{$aggr}[0..25]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,49,49,50,50,57,58,66,67,72,72,73]);
is(366, scalar(@$aggr));

$cons->reset->tokenize($data);
is_deeply([@{$cons}[0..21]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,57,58,66,67,72,72,73]);
is(302, scalar(@$cons));


subtest 'Test Zipper' => sub {
  # Test Zipper
  my ($fh, $outzip) = korap_tempfile('tokenize_zipper');
  my $zip = KorAP::XML::TEI::Zipper->new($outzip);
  $fh->close;

  my $aggr = KorAP::XML::TEI::Tokenizer::Aggressive->new;
  $aggr->tokenize("Der alte Mann");
  ok($aggr->to_zip(
    $zip->new_stream('tokens.xml'),
    'fun'
  ), 'Written successfully');

  $zip->close;

  ok(-e $outzip, 'Zip exists');
  my $unzip = IO::Uncompress::Unzip->new($outzip, Name => 'tokens.xml');
  ok(!$unzip->eof, 'Unzip successful');
};


done_testing;
