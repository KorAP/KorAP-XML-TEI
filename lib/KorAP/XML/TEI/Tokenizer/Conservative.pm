package KorAP::XML::TEI::Tokenizer::Conservative;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "conservatively" and return an array
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
  while ($txt =~ /(p*)
                  (P+(?:p+P+)*)?
                  (p*)
                  s?/gx) {

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

      $pr = 1; # the first punctuation character should always be tokenized

      # Punctuation character doesn't start at first position
      if ($p1 != 0) {
        # Check char before punctuation char
        $pr = ( substr( $txt, $p1-1, 1 ) =~ /[ps]/ );
      }
    }

    else {
      # Check char after punctuation char
      $pr = ( substr( $txt, $p2, 1 ) =~ /[ps]?/ ); # the last punctuation character should always be tokenized (signified by the ?)

      # Check char before punctuation char
      unless ($pr) {
        $pr = ( substr ( $txt, $p1-1, 1 ) =~ /[ps]/ );
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
