use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use Test::XML::Loy;

use FindBin;
use utf8;

BEGIN {
  eval {
    require KorAP::XML::TEI::Tokenizer::KorAP;
    1;
  } or do {
    plan skip_all => "KorAP::XML::TEI::Tokenizer::KorAP cannot be used";
  };
}

require_ok('KorAP::XML::TEI::Tokenizer::KorAP');

my $f = dirname(__FILE__);
my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

my $ext = KorAP::XML::TEI::Tokenizer::KorAP->new();

$ext->tokenize("Der alte Mann");
my $str = $ext->to_string('unknown');
my $t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(1)', 'to', 3);
$t->attr_is('layer spanList span:nth-child(2)', 'from', 4);
$t->attr_is('layer spanList span:nth-child(2)', 'to', 8);
$t->attr_is('layer spanList span:nth-child(3)', 'from', 9);
$t->attr_is('layer spanList span:nth-child(3)', 'to', 13);
$t->element_count_is('layer spanList span', 3);

$ext->tokenize("ging über die Straße");
$str = $ext->to_string('unknown');
$t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(1)', 'to', 4);
$t->attr_is('layer spanList span:nth-child(2)', 'from', 5);
$t->attr_is('layer spanList span:nth-child(2)', 'to', 9);
$t->attr_is('layer spanList span:nth-child(3)', 'from', 10);
$t->attr_is('layer spanList span:nth-child(3)', 'to', 13);
$t->attr_is('layer spanList span:nth-child(4)', 'from', 14);
$t->attr_is('layer spanList span:nth-child(4)', 'to', 20);
$t->element_count_is('layer spanList span', 4);

$ext->reset;
$ext->tokenize("Hu aha\x{04}\ndas ist cool");
$str = $ext->to_string('unknown');
$t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(1)', 'to', 2);
$t->attr_is('layer spanList span:nth-child(2)', 'from', 3);
$t->attr_is('layer spanList span:nth-child(2)', 'to', 6);
$t->element_count_is('layer spanList span', 2);

my $string = "Pluto.\"  Eris-Entdecker Mike Brown, der im Kurznachrichtendienst Twitter unter \"\@plutokiller";
$ext->reset;
$ext->tokenize($string);
$str = $ext->to_string('unknown');
$t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(14)', 'from', 80);
$t->attr_is('layer spanList span:nth-child(14)', 'to', 92);
$t->element_count_is('layer spanList span', 14);
done_testing;
