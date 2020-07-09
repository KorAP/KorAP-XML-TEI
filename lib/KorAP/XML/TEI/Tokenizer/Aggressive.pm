package KorAP::XML::TEI::Tokenizer::Aggressive;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt, $offset) = @_;

  $offset //= 0;

  # Iterate over the whole string
  while ($txt =~ /([^\p{Punct} \x{9}\n]+)
                  (?:(\p{Punct})|(?:[ \x{9}\n])?)|
                  (\p{Punct})/gx){

    # Starts with a character sequence
    if (defined $1){
      push @$self, $-[1]+$offset, $+[1]+$offset; # from and to

      # Followed by a punctuation
      if ($2){
        push @$self, $-[2]+$offset, $+[2]+$offset # from and to
      }
    }

    # Starts with a punctuation
    else {
      push @$self, $-[3]+$offset, $+[3]+$offset # from and to
    };
  };

  return;
};


1;
