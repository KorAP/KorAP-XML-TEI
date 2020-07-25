package KorAP::XML::TEI::Tokenizer::Conservative;
use base 'KorAP::XML::TEI::Tokenizer';
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "conservatively" and return an array
# with character boundaries.
sub tokenize {
  my ($self, $txt) = @_;

  # Replace MBCs with single bytes
  $txt =~ s/\p{Punct}/./g;
  $txt =~ s/\s/~/g;
  $txt =~ s/[^\.\~]/_/g;
  utf8::downgrade($txt);

  # Iterate over the whole string
  while ($txt =~ /(\.*)
                  (_+(?:\.+_+)*)?
                  (\.*)
                  \~?/gx) {

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
    my $char;

    # Variant for preceding characters
    if ($preceding) {

      $pr = 1; # the first punctuation character should always be tokenized

      # Punctuation character doesn't start at first position
      if ($p1 != 0) {

        # Check char before punctuation char
        $char = substr( $txt, $p1-1, 1 );
        $pr = ($char eq '.' || $char eq '~') ? 1 : 0;
      }
    }

    else {
      # Check char after punctuation char
      $char = substr( $txt, $p2, 1 );

      # The last punctuation character should always be tokenized
      $pr = (!$char || $char eq '.' || $char eq '~') ? 1 : 0;

      # Check char before punctuation char
      unless ($pr) {
        $char = substr ( $txt, $p1-1, 1);
        $pr = ($char eq '.' || $char eq '~' ) ? 1 : 0;
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
