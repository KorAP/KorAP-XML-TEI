package KorAP::XML::TEI::Tokenizer::KorAP;
use base 'KorAP::XML::TEI::Tokenizer::External';
use strict;
use warnings;
use Log::Any qw($log);
use File::Share ':all';
use Encode;

use constant {
    WAIT_SECS => 30
};

my $java = `sh -c 'command -v java'`;
chomp $java;

if($java eq '') {
    warn("No java executable found in PATH. " . __PACKAGE__ . " requires a JVM.");
    return 0;
}

my $tokenizer_jar = dist_file('tei2korapxml', 'KorAP-Tokenizer-1.3-beta-standalone.jar');


sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new("$java -jar $tokenizer_jar");
    $self->{'name'} = "korap";
    $self->{'sep'} = "\x{04}\n";
    bless $self, $class;
    return $self;
}

1;
