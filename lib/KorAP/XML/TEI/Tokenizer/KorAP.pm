package KorAP::XML::TEI::Tokenizer::KorAP;
use base 'KorAP::XML::TEI::Tokenizer::External';
use strict;
use warnings;
use Log::Any qw($log);
use File::Share ':all';
use Encode;

my $tokenizer_jar = dist_file('tei2korapxml', 'KorAP-Tokenizer-1.3-beta-standalone.jar');

use constant {
    WAIT_SECS => 30
};

sub new {
    my ($class, $cmd, $sep) = @_;

    my $self = $class->SUPER::new("java -jar $tokenizer_jar");
    $self->{'name'} = "korap";
    bless $self, $class;
    return $self;
}

sub tokenize {
    my ($self, $string) = @_;
    return $self->SUPER::tokenize(encode_utf8($string));
}

1;
