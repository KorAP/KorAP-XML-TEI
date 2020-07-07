package KorAP::XML::TEI::Tokenization;
use strict;
use warnings;

# This tokenizer was originally written by cschnober.
# '\p{Punct}' is equal to the character class '[-!"#%&'()*,./:;?@[\\\]_{}]'

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub aggressive {
  my ($txt, $offset) = @_;

  $offset //= 0;
  my @tokens;

  # Iterate over the whole string
  while ($txt =~ /([^\p{Punct} \x{9}\n]+)
                  (?:(\p{Punct})|(?:[ \x{9}\n])?)|
                  (\p{Punct})/gx){

    # Starts with a character sequence
    if (defined $1){
      push @tokens, $-[1]+$offset, $+[1]+$offset; # from and to

      # Followed by a punctuation
      if ($2){
        push @tokens, $-[2]+$offset, $+[2]+$offset # from and to
      }
    }

    # Starts with a punctuation
    else {
      push @tokens, $-[3]+$offset, $+[3]+$offset # from and to
    };
  };

  return \@tokens;
};


# Tokenize string "conservatively" and return an array
# with character boundaries.
sub conservative {
  my ($txt, $offset) = @_;
  $offset //= 0;

  my @tokens;
  my ($tmp, $p1, $p2, $pr);

  my $i;

  # Iterate over the whole string
  while ($txt =~ /(\p{Punct}*)
                  ([^\p{Punct} \x{9}\n]+(?:(\p{Punct}+)[^\p{Punct} \x{9}\n]+)*)?
                  (\p{Punct}*)
                  (?:[ \x{9}\n])?/gx) {

    # Punctuation preceding a token
    if ($1) {
      ($p1,$p2) = ($-[1], $+[1]);

      # Only a single character
      if ($p2 == $p1+1) {

        # Character doesn't start and first position
        if ($p1 != 0) {

          # Check if the prefix is a character
          $pr = ( substr( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]$/ );
        }

        # Prefix is empty
        else {
          $pr = 0
        };

        # There is no prefix
        unless ($pr){

          # Check, if the first character following the special char is a character?
          $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]$/ );
        };

        if ($pr){
          push @tokens, $p1+$offset, $p2+$offset; # from and to
        };

      } else {

        # Iterate over all single punctuation symbols
        for ($i = $p1; $i < $p2; $i++) {
          push @tokens, $i+$offset, $i+1+$offset; # from and to
        }
      }
    };

    # Token sequence
    if ($2){
      push @tokens, $-[2]+$offset, $+[2]+$offset; # from and to
    };

    # Punctuation following a token
    if ($3){
      ($p1,$p2) = ($-[3], $+[3]);

      # Only a single character
      if ($p2 == $p1+1){

        # Check the char after the match
        $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]?$/ );

        # Check the char before the match
        unless ($pr){
          $pr = ( substr( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]/ );
        };

        # Either before or after the char there is a token
        if ($pr) {
          push @tokens, $p1+$offset, $p2+$offset; # from and to
        };

      }

      else {

        # Iterate over all single punctuation symbols
        for ( $i = $p1; $i < $p2; $i++) {
          push @tokens, $i+$offset, $i+1+$offset; # from and to
        };
      };
    };

    if ($4) { # special chars after token

      ($p1,$p2) = ($-[4], $+[4]);

      if ($p2 == $p1+1) {

        # Check the char after the match
        $pr = ( substr( $txt, $p2, 1 ) =~ /^[^A-Za-z0-9]?$/ );

        # Check the char before the match
        unless ($pr) {
          $pr = ( substr ( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]/ );
        };

        # Either before or after the char there is a token
        if ($pr){
          push @tokens, $p1+$offset, $p2+$offset;  # from and to
        };

      }

      else {

        # Iterate over all single punctuation symbols
        for ( $i = $p1; $i < $p2; $i++ ){
          push @tokens, $i+$offset, $i+1+$offset; # from and to
        };
      };
    };
  };

  return \@tokens
};


1;
