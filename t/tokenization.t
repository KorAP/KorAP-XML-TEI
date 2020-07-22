use strict;
use warnings;
#use open qw(:std :utf8); # see perlunifaq: What is the difference between ":encoding" and ":utf8"?
use open qw(:std :encoding(UTF-8)); # assume utf-8 encoding (see utf8 in Test::More)
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

ok(open(my $fh, '<' . $dataf), 'Open file');
while (!eof($fh)) {
  $data .= <$fh>
};

## DEBUG
#my @layers = PerlIO::get_layers($fh); # see 'man PerlIO': Querying the layers of filehandles
#foreach my $l(@layers){print STDERR "DEBUG (filehandle layer): $l\n"};

ok(close($fh), 'Close file');

is(134996, length($data)); # mind that each UTF-8 character counts only once

## note
# check different output with/without additional UTF-8 layer
#  echo "„Wikipedia-Artikel brauchen Fotos“" | perl -ne 'chomp; for($i=0;$i<length;$i++){$c=substr $_,$i,1; print ">$c<\n" if $c=~/\p{Punct}/}'
#  echo "„Wikipedia-Artikel brauchen Fotos“" | perl -ne 'use open qw(:std :utf8); chomp; for($i=0;$i<length;$i++){$c=substr $_,$i,1; print ">$c<\n" if $c=~/\p{Punct}/}'

# TODO: With then necessary open-pragma (see above), this is extremely slow ... Where's the bottleneck?
# No performance-issue, when piping 'wikipedia.txt' into a perl one-liner (also not, when using while-loop from Aggressive.pm):
# cat t/data/wikipedia.txt | perl -ne 'use open qw(:std :utf8); chomp; for($i=0;$i<length;$i++){$c=substr $_,$i,1; print ">$c<\n" if $c=~/\p{Punct}/}' >/dev/null
# cat t/data/wikipedia.txt | perl -ne 'use open qw(:std :utf8); chomp; while($_=~/([^\p{Punct} \x{9}\n]+)(?:(\p{Punct})|(?:[ \x{9}\n])?)|(\p{Punct})/gx){ print "$1\n" if $1}' >/dev/null
diag("DEBUG (aggr): Tokenizing Wikipedia Text (134K). Because of an additional PerlIO layer (utf8) on the filehandle, this takes significant more time. Please wait ...\n");
$aggr->reset->tokenize($data);
is_deeply([@{$aggr}[0..25]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,49,49,50,50,57,58,66,67,72,72,73]);
is(47112, scalar(@$aggr));

diag("DEBUG (cons): Tokenizing Wikipedia Text (134K). Because of an additional PerlIO layer (utf8) on the filehandle, this takes significant more time. Please wait ...\n");
$cons->reset->tokenize($data);
is_deeply([@{$cons}[0..21]], [1,7,8,12,14,18,19,22,23,27,28,38,39,40,40,57,58,66,67,72,72,73]);
is(43218, scalar(@$cons));

# check tokenization of 'Community-Ämter'
my @vals_got=(66070,66085,66079,66080);
#  from @{cons}[19956] (=66070) to @{cons}[19957] (=66085) => 'Community-Ämter'   # correct tokenization
#  from @{cons}[19958] (=66079) to @{cons}[19959] (=66080) => '-'   # wrong tokenization (should be (?,?) for next word 'aufgestiegen' instead of (66079,66080) for '-')
my @vals_exp; push @vals_exp, @{$cons}[$_] for(19956,19957,19958,19959);
diag("DEBUG (cons): checking wrong tokenization ...\n");
is_deeply([@vals_exp], [@vals_got]);

done_testing;
