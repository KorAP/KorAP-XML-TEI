package KorAP::XML::TEI::Tokenizer::KorAP;
use base 'KorAP::XML::TEI::Tokenizer::External';
use strict;
use warnings;
use File::Share ':all';

use constant {
  WAIT_SECS => 30
};

my $java = `sh -c 'command -v java'`;
chomp $java;


if ($java eq '') {
  warn('No java executable found in PATH. ' . __PACKAGE__ . ' requires a JVM.');
  return 0;
};


my $tokenizer_jar = dist_file(
  'tei2korapxml',
  'KorAP-Tokenizer-1.3-beta-standalone.jar'
);


# Construct a new KorAP Tokenizer
sub new {
  my $class = shift;
  my $self = $class->SUPER::new("$java -jar $tokenizer_jar");
  $self->{name} = 'korap';
  $self->{sep} = "\x{04}\n";
  return bless $self, $class;
};


1;
