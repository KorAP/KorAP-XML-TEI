package KorAP::XML::TEI::Tokenizer::Aggressive;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt) = @_;

  # Iterate over the whole string
  while ($txt =~ /([^\p{Punct}\s]+)
                  (?:(\p{Punct})|\s?)|
                  (\p{Punct})/gx){

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
