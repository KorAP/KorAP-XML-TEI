package KorAP::XML::TEI::Tokenizer::Aggressive;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt_utf8) = @_;

  my $txt;

  # faster processing of UTF8-chars
  foreach my $char (split //, $txt_utf8) {
    if ($char =~ /\p{Punct}/) {
      $txt .= "p"
    } elsif ($char =~ /[^\p{Punct}\s]/) {
      $txt .= "P"
    } elsif ($char =~ /\s/) {
      $txt .= "s"
    } else {
      $txt .= "o" # other: should actually only happen for string end (0 byte)
      # check could be 'ord($char)==0'
    }
  };

  # Iterate over the whole string
  while ($txt =~ /(P+)
                  (?:(p)|s?)|
                  (p)/gx){

    # Starts with a character sequence
    if (defined $1){
      push @$self, $-[1], $+[1]; # from and to

      # Followed by a punctuation
      if ($2){
        push @$self, $-[2], $+[2] # from and to
      }
    }

    # Starts with a punctuation
    else {
      push @$self, $-[3], $+[3] # from and to
    };
  };

  return;
};


1;
