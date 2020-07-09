#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../../lib";
};
use KorAP::XML::TEI::Tokenizer::Aggressive;

use open qw(:std :utf8); # assume utf-8 encoding

$| = 1;

# Init tokenizer
my $tok = KorAP::XML::TEI::Tokenizer::Aggressive->new;

# Read lines from input and return boundaries
while (!eof(STDIN)) {
  my $line = <>;
  $tok->tokenize($line);
  print join(' ', $tok->boundaries), "\n";
  $tok->reset;
};

1;
