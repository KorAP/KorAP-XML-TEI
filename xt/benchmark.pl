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

my $columns = 0;
GetOptions(
  'columns|c' => \$columns
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

# Add benchmark instances
$bench->add_instances(
  Dumbbench::Instance::PerlSub->new(
    name => 'SimpleConversion',
    code => sub {
      `cat '$file' | perl '$script'`
    }
  )
);

# Run benchmarks
$bench->run;

# Output in a single row
if ($columns) {
  print join("\t", map { $_->name       } $bench->instances), "\n";
  print join("\t", map { $_->single_run } $bench->instances), "\n";
  exit(0);
};

# Output simple timings for comparation
foreach my $inst ($bench->instances) {
  print $inst->name, ': ', $inst->single_run, "\n";
};

exit(0);

__END__
