use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

require_ok('KorAP::XML::TEI::Tokenizer::Aggressive');
require_ok('KorAP::XML::TEI::Tokenizer::Conservative');

# Test aggressive
my $aggr = KorAP::XML::TEI::Tokenizer::Aggressive->new;
$aggr->tokenize("Der alte Mann");
is_deeply($aggr, [0,3,4,8,9,13]);

$aggr->reset->tokenize("Der alte bzw. der grau-melierte Mann");
is_deeply($aggr, [0,3,4,8,9,12,12,13,14,17,18,22,22,23,23,31,32,36]);

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

# TODO:
#   bug: '.' is not tokenized
$cons->reset->tokenize(".Der");
is_deeply($cons, [1,4]);

$cons->reset->tokenize(".Der.... ");
is_deeply($cons, [1,4,4,5,5,6,6,7,7,8]);

$cons->reset->tokenize("..Der.... ");
is_deeply($cons, [0,1,1,2,2,5,5,6,6,7,7,8,8,9]);

# Test data
my $dataf = catfile(dirname(__FILE__), 'data', 'wikipedia.txt');
my $data = '';

ok(open(FH, '<' . $dataf), 'Open file');
while (!eof(FH)) {
  $data .= <FH>
};
close(FH);

is(137166, length($data));

$aggr->reset->tokenize($data);
is_deeply([@{$aggr}[0..7]], [1,7,8,12,14,18,19,22]);
is(47242, scalar(@$aggr));

$cons->reset->tokenize($data);
is_deeply([@{$cons}[0..7]], [1,7,8,12,14,18,19,22]);
is(43068, scalar(@$cons));

done_testing;
