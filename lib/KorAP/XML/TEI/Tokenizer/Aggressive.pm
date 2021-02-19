package KorAP::XML::TEI::Tokenizer::Aggressive;
use base 'KorAP::XML::TEI::Annotations';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt) = @_;

  # Replace MBCs with single bytes
  $txt =~ s/\p{Punct}/./g;
  $txt =~ s/\s/~/g;
  $txt =~ s/[^\.\~]/_/g;
  utf8::downgrade($txt);

  # Iterate over the whole string
  while ($txt =~ /(_+)
                  (?:(\.)|\~?)|
                  (\.)/gx){

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

  return $self;
};


# Name of the tokenizer file
sub name {
  'tokens_aggressive';
};

1;
