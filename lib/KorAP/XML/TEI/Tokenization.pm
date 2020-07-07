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


sub _check_surroundings {
  my ($txt, $offset, $p1, $p2, $preceeding) = @_;

  my $pr;

  if ($p2 == $p1+1) {

    # Variant for preceeding characters
    if ($preceeding) {
      # Character doesn't start and first position
      if ($p1 != 0) {

        # Check if the prefix is a character
        $pr = ( substr( $txt, $p1-1, 1 ) =~ /^[^A-Za-z0-9]$/ );
      };

      # There is no prefix
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

    return () unless $pr;

    # Either before or after the char there is a token
    return ($p1+$offset, $p2+$offset);  # from and to
  };

  my @list;

  # Iterate over all single punctuation symbols
  for (my $i = $p1; $i < $p2; $i++ ){
    push @list, $i+$offset, $i+1+$offset; # from and to
  };

  return @list;
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
    push @tokens, _check_surroundings($txt, $offset, $-[1], $+[1], 1) if $1;

    # Token sequence
    push @tokens, ($-[2]+$offset, $+[2]+$offset) if $2; # from and to

    # Punctuation following a token
    push @tokens, _check_surroundings($txt, $offset, $-[3], $+[3]) if $3;

    # Special chars after token
    push @tokens, _check_surroundings($txt, $offset, $-[4], $+[4]) if $4;
  };

  return \@tokens
};


1;
