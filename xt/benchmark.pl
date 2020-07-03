#!/usr/bin/env perl
use strict;
use warnings;
use Dumbbench;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile rel2abs/;
use File::Temp ':POSIX';
use FindBin;
use Getopt::Long;

BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};

use KorAP::XML::TEI;

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

# Load example file
my $file = rel2abs(catfile($f, '..', 't', 'data', 'goe_sample.i5.xml'));

# Create a new benchmark object
my $bench = Dumbbench->new(
  verbosity => 0
);

my $result;

# Add benchmark instances
$bench->add_instances(
  Dumbbench::Instance::PerlSub->new(
    name => 'SimpleConversion',
    code => sub {
      `cat '$file' | perl '$script' > /dev/null 2>&1`
    }
  ),
  Dumbbench::Instance::PerlSub->new(
    name => 'delHTMLcom',
    code => sub {
      for (1..100_000) {
        $result = KorAP::XML::TEI::delHTMLcom(
          \*STDIN,
          "This <!-- comment --> is a test " . $_
        );
      };
    }
  ),
);

# Run benchmarks
$bench->run;

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
