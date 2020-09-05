#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../../lib";
};
use KorAP::XML::TEI::Tokenizer::Aggressive;

$| = 1;

# Init tokenizer
my $tok = KorAP::XML::TEI::Tokenizer::Aggressive->new;

# Read lines from input and return boundaries
while (!eof(STDIN)) {
  my $line = <>;
  for my $text (split(/\n?\x{04}\n?/, $line)) {
    $tok->tokenize($text);
    print join(' ', $tok->boundaries), "\n";
    $tok->reset;
  }
};

1;
