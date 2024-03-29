#!/usr/bin/env perl
use strict;
use warnings;
use Dumbbench;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile rel2abs/;
use File::Temp 'tempfile';
use Encode qw!decode!;
use FindBin;
use Getopt::Long;

BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use Test::KorAP::XML::TEI qw!korap_tempfile!;
use KorAP::XML::TEI 'remove_xml_comments';
use KorAP::XML::TEI::Tokenizer::Aggressive;
use KorAP::XML::TEI::Tokenizer::Conservative;
use KorAP::XML::TEI::Data;

my $columns = 0;
my $no_header = 0;
GetOptions(
  'columns|c' => \$columns,
  'no-header|n' => \$no_header,
  'help|h' => sub {
    print "--columns|-c     Print instances in columns\n";
    print "--no-header|-n   Dismiss benchmark names\n";
    print "--help|-h        Print this page\n\n";
    exit(0);
  }
);

our $SCRIPT_NAME = 'tei2korapxml';

my $f = dirname(__FILE__);
my $script = rel2abs(catfile($f, '..', 'script', $SCRIPT_NAME));

# Load example files
my $file = rel2abs(catfile($f, '..', 't', 'data', 'goe_sample.i5.xml'));
my $goe_tagged = rel2abs(catfile($f, '..', 't', 'data', 'goe_sample_tagged.i5.xml'));
my $icc_german = rel2abs(catfile($f, '..', 't', 'data', 'icc_german_sample.p5.xml'));

# Create a new benchmark object
my $bench = Dumbbench->new(
  verbosity => 0
);

my $result;

# Data for delHTMLcom-long
my ($fh, $filename) = korap_tempfile('benchmark');

print $fh <<'HTML';
mehrzeiliger
Kommentar
  --><!-- Versuch
-->ist <!-- a --><!-- b --> ein Test
HTML

# Data for Tokenization
# Test data
my $t_dataf = catfile(dirname(__FILE__), '..', 't', 'data', 'wikipedia.txt');
my $t_data = '';
if ((open(FH, '<' . $t_dataf))) {
  binmode(FH);
  while (!eof(FH)) {
    $t_data .= <FH>
  };
  close(FH);
}
else {
  die "Unable to load $t_dataf";
};

my $t_data_utf_8 = decode('utf-8',$t_data);
my @t_data_split = split(' ', $t_data);

my $cons_tok = KorAP::XML::TEI::Tokenizer::Conservative->new;
my $aggr_tok = KorAP::XML::TEI::Tokenizer::Aggressive->new;

my $data = KorAP::XML::TEI::Data->new;

# Add benchmark instances
$bench->add_instances(
  Dumbbench::Instance::PerlSub->new(
    name => 'SimpleConversion',
    code => sub {
      `cat '$file' | perl '$script' -ti > /dev/null 2>&1`
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Conversion-with-inline-annotations',
    code => sub {
      `cat '$goe_tagged' | KORAPXMLTEI_INLINE=1 perl '$script' > /dev/null 2>&1`
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Conversion of standard TEI',
    code => sub {
      `cat '$icc_german' | perl '$script' > /dev/null 2>&1`
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'delHTMLcom',
    code => sub {
      for (1..100_000) {
        $result = remove_xml_comments(
          \*STDIN,
          "This <!-- comment --> is a test " . $_
        );
      };
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'delHTMLcom-long',
    code => sub {
      for (1..10_000) {
        $result = remove_xml_comments(
          $fh,
          "This <!--" . $_
        );
        seek($fh, 0, 0);
      };
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Tokenizer-conservative',
    code => sub {
      $result = $cons_tok->reset->tokenize($t_data);
      $result = 0;
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Tokenizer-conservative-utf-8',
    code => sub {
      $result = $cons_tok->reset->tokenize($t_data_utf_8);
      $result = 0;
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Tokenizer-aggressive',
    code => sub {
      $result = $aggr_tok->reset->tokenize($t_data);
      $result = 0;
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Tokenizer-aggressive-utf-8',
    code => sub {
      $result = $aggr_tok->reset->tokenize($t_data_utf_8);
      $result = 0;
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'Data-Collect with serialization',
    code => sub {
      $data->reset->append($_) foreach @t_data_split;
      $result = $data->to_string;
    }
  )
);

# Run benchmarks
$bench->run;

# Clean up
close($fh);

# Output in a single row
if ($columns) {
  unless ($no_header) {
    print join("\t", map { $_->name } $bench->instances), "\n";
  };
  print join("\t", map { $_->result->raw_number } $bench->instances), "\n";
  exit(0);
};

# Output simple timings for comparation
foreach my $inst ($bench->instances) {
  unless ($no_header) {
    print $inst->name, ': ';
  };
  print $inst->result->raw_number, "\n";
};

exit(0);

__END__
