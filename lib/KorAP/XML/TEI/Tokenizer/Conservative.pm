package KorAP::XML::TEI::Tokenizer::Conservative;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "conservatively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt) = @_;

  # Iterate over the whole string
  while ($txt =~ /(\p{Punct}*)
                  ([^\p{Punct} \x{9}\n]+(?:\p{Punct}+[^\p{Punct} \x{9}\n]+)*)?
                  (\p{Punct}*)
                  (?:[ \x{9}\n])?/gx) {

    # Punctuation preceding a token
    $self->_add_surroundings($txt, $-[1], $+[1], 1) if $1;

    # Token sequence
    push @$self, ($-[2], $+[2]) if $2; # from and to

    # Punctuation following a token
    $self->_add_surroundings($txt, $-[3], $+[3]) if $3;
  };

  return
};


# Check if surrounding characters justify tokenization of Punctuation
#  (in that case $pr is set)
sub _add_surroundings {
  my ($self, $txt, $p1, $p2, $preceding) = @_;

  my $pr; # "print" (tokenize) punctuation character (if one of the below tests justified it)

  if ($p2 == $p1+1) { # single punctuation character

    # Variant for preceding characters
    if ($preceding) {

      # Punctuation character doesn't start at first position
      if ($p1 != 0) {
        # Check char before punctuation char
        $pr = ( substr( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]$/ );
      }

      unless ($pr){
        # Check char after punctuation char
        $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]$/ );
      };
    }

    else {
      # Check char after punctuation char
      $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]?$/ );

      # Check char before punctuation char
      unless ($pr) {
        $pr = ( substr ( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]/ );
      };
    };

    # tokenize punctuation char (because it was justified)
    push @$self, ($p1, $p2) if $pr;  # from and to

    return;
  };

  # Iterate over all single punctuation symbols
  for (my $i = $p1; $i < $p2; $i++ ){
    push @$self, $i, $i+1; # from and to
  };
};


1;
