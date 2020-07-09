use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use File::Temp 'tempfile';
use Test::XML::Loy;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

require_ok('KorAP::XML::TEI::Tokenizer::External');

my $f = dirname(__FILE__);
my $cmd = catfile($f, 'cmd', 'tokenizer.pl');

# Test aggressive
my $ext = KorAP::XML::TEI::Tokenizer::External->new(
  'perl ' . $cmd
  #  'java -cp Ingestion/target/KorAP-Ingestion-pipeline.jar de.ids_mannheim.korap.tokenizer.KorAPTokenizerImpl'
);

$ext->tokenize("Der alte Mann");
# TODO:
#   see comments on $sep in 'lib/KorAP/XML/TEI/Tokenizer/External.pm'
#$ext->tokenize("ging über die Straße");

my $str = $ext->to_string('unknown');
my $t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(1)', 'to', 3);
$t->attr_is('layer spanList span:nth-child(2)', 'from', 4);
$t->attr_is('layer spanList span:nth-child(2)', 'to', 8);
$t->attr_is('layer spanList span:nth-child(3)', 'from', 9);
$t->attr_is('layer spanList span:nth-child(3)', 'to', 13);
$t->element_count_is('layer spanList span', 3);

$ext->reset;
$ext->tokenize("Hu aha\ndas ist cool");

$str = $ext->to_string('unknown');
$t = Test::XML::Loy->new($str);
$t->attr_is('layer spanList span:nth-child(1)', 'to', 2);
$t->attr_is('layer spanList span:nth-child(2)', 'from', 3);
$t->attr_is('layer spanList span:nth-child(2)', 'to', 6);
$t->element_count_is('layer spanList span', 2);


done_testing;
