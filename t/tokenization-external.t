use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use File::Temp qw/tempfile/;
use Test::XML::Loy;

use FindBin;
use utf8;

BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

require_ok('KorAP::XML::TEI::Tokenizer::External');

my $f = dirname(__FILE__);
my $cmd = catfile($f, 'cmd', 'tokenizer.pl');
my $faulty_cmd = catfile($f, 'cmd', 'tokenizer_faulty.pl');

# Test aggressive
my $ext = KorAP::XML::TEI::Tokenizer::External->new(
  'perl ' . $cmd
  #  'java -cp Ingestion/target/KorAP-Ingestion-pipeline.jar de.ids_mannheim.korap.tokenizer.KorAPTokenizerImpl'
);

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

my (undef, $state_file) = tempfile();

$ext = KorAP::XML::TEI::Tokenizer::External->new(
  "perl $faulty_cmd '$state_file'"
);
$ext->tokenize("Der __CRASH_ONCE__ Mann");
$str = $ext->to_string('retry-doc');
ok($str, 'Tokenization succeeds after restarting the external tokenizer');
$t = Test::XML::Loy->new($str);
$t->element_exists('layer spanList span:nth-child(1)', 'Retry produces token bounds');

$ext->tokenize("Der __ALWAYS_CRASH__ Mann");
ok(!defined $ext->to_string('skip-doc'), 'Tokenization can be skipped after repeated crashes');

$ext->tokenize("Der alte Mann");
$str = $ext->to_string('recovered-doc');
ok($str, 'Tokenizer can continue after a skipped text');
$t = Test::XML::Loy->new($str);
$t->element_count_is('layer spanList span', 3);

done_testing;
