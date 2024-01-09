package KorAP::XML::TEI::Tokenizer::KorAP;
use base 'KorAP::XML::TEI::Tokenizer::External';
use strict;
use warnings;
use File::Share ':all';

our $VERSION = '2.4.5-SNAPSHOT';
my $MIN_JAVA_VERSION = 17;

use constant {
  WAIT_SECS => 30
};

my $java = `sh -c 'command -v java'`;
chomp $java;

if ($java eq '') {
  warn('No java executable found in PATH. ' . __PACKAGE__ . " requires a JVM (minimum version $MIN_JAVA_VERSION).");
  return 0;
};

my ($java_version) = `java -version 2>&1` =~ /version "(\d+)/;
if ($java_version < $MIN_JAVA_VERSION) {
  warn("Java (JRE) version $MIN_JAVA_VERSION or higher required, but only found version $java_version. " . __PACKAGE__ );
  return 0;
};

my $tokenizer_jar = dist_file(
  'tei2korapxml',
  'KorAP-Tokenizer-2.2.5-standalone.jar'
);

unless (-f $tokenizer_jar) {
  return 0;
};

no warnings 'redefine';

# Construct a new KorAP Tokenizer
sub new {
  my ($class, $sentence_split) = @_;
  my $self = $class->SUPER::new("$java -Xmx512m -jar $tokenizer_jar --no-tokens --positions" .
      ($sentence_split? " --sentence-boundaries" : ""));
  $self->{sentence_split} = $sentence_split;
  $self->{name} = 'korap';
  $self->{sep} = "\n\x{04}\n";
  return bless $self, $class;
};


1;
