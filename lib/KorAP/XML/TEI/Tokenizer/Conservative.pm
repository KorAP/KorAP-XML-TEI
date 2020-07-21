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
                  ([^\p{Punct} \x{9}\n]+(?:(\p{Punct}+)[^\p{Punct} \x{9}\n]+)*)?
                  (\p{Punct}*)
                  (?:[ \x{9}\n])?/gx) {

    # Punctuation preceding a token
    $self->_add_surroundings($txt, $-[1], $+[1], 1) if $1;

    # Token sequence
    push @$self, ($-[2], $+[2]) if $2; # from and to

    # Punctuation following a token
    $self->_add_surroundings($txt, $-[3], $+[3]) if $3;

    # Special chars after token
    $self->_add_surroundings($txt, $-[4], $+[4]) if $4;
  };

  return
};


# Check if surrounding characters are token-worthy
sub _add_surroundings {
  my ($self, $txt, $p1, $p2, $preceding) = @_;

  my $pr;

  if ($p2 == $p1+1) {

    # Variant for preceding characters
    if ($preceding) {
      # Character doesn't start and first position
      if ($p1 != 0) {

        # Check if there is something to print
        $pr = ( substr( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]$/ );
      };

      # There is nothing to print
      unless ($pr){

        # Check, if the first character following the special char is a character?
        $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]$/ );
      };
    }

    else {
      # Check the char after the match
      $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]?$/ );

      # Check the char before the match
      unless ($pr) {
        $pr = ( substr ( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]/ );
      };
    };

    # Either before or after the char there is a token
    push @$self, ($p1, $p2) if $pr;  # from and to
    return;
  };

  # Iterate over all single punctuation symbols
  for (my $i = $p1; $i < $p2; $i++ ){
    push @$self, $i, $i+1; # from and to
  };
};


1;
