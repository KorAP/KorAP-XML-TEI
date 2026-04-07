#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Encode qw(decode_utf8);

BEGIN {
  unshift @INC, "$FindBin::Bin/../../lib";
};

use KorAP::XML::TEI::Tokenizer::Aggressive;

$| = 1;

my $state_file = shift @ARGV;
my $tok = KorAP::XML::TEI::Tokenizer::Aggressive->new;

sub _state {
  return 0 unless $state_file;
  return 0 unless open(my $fh, '<', $state_file);
  my $count = <$fh> // 0;
  close($fh);
  chomp $count;
  return $count || 0;
}

sub _set_state {
  my $count = shift;
  return unless $state_file;
  open(my $fh, '>', $state_file) or die "Can't write state file '$state_file': $!";
  print {$fh} $count;
  close($fh);
}

while (!eof(STDIN)) {
  my $line = decode_utf8(<>);
  for my $text (split(/\n?\x{04}\n?/, $line)) {
    next if !defined $text || $text eq '';

    if (index($text, '__CRASH_ONCE__') >= 0 && !_state()) {
      _set_state(1);
      exit 9;
    }

    if (index($text, '__ALWAYS_CRASH__') >= 0) {
      exit 9;
    }

    $tok->tokenize($text);
    print join(' ', $tok->boundaries), "\n";
    $tok->reset;
  }
}

1;
