package KorAP::XML::TEI::Tokenization;
use strict;
use warnings;

# This tokenizer was originally written by cschnober.

# Tokenize string "aggressively" and return an array
# with character boundaries.
sub aggressive {
  my ($txt, $offset) = @_;

  $offset //= 0;
  my @tokens;

  # Iterate over the whole string
  while ($txt =~ /([^\p{Punct} \x{9}\n]+)(?:([\p{Punct}])|(?:[ \x{9}\n])?)|([\p{Punct}])/g){

    if (defined $1){

      push @tokens, $-[1]+$offset, $+[1]+$offset; # from and to

      if (defined $2){
        push @tokens, $-[2]+$offset, $+[2]+$offset # from and to
      }

    }

    # defined $3
    else {
      push @tokens, $-[3]+$offset, $+[3]+$offset # from and to
    }

  };

  return \@tokens;
};


# Tokenize string "conservatively" and return an array
# with character boundaries.
sub conservative {
  my ($txt, $offset) = @_;
  $offset //= 0;

  my @tokens;
  my ($m1, $m2, $m3, $m4);
  my ($tmp, $p1, $p2, $pr);

  my $dl; # ???
  my $i;

  # ~ start: conservative tokenization ~

  # '\p{Punct}' is equal to the character class '[-!"#%&'()*,./:;?@[\\\]_{}]'
  while ( $txt =~ /([\p{Punct}]*)([^\p{Punct} \x{9}\n]+(?:([\p{Punct}]+)[^\p{Punct} \x{9}\n]+)*)?([\p{Punct}]*)(?:[ \x{9}\n])?/g ){

    $m1 = $1; $m2 = $2; $m3 = $3; $m4 = $4;

    if ( "$m1" ne "" ){ # special chars before token

      $p1 = $-[1]; $p2 = $+[1];

      #print STDERR "A1: ".$m1." -> from $p1 to $p2\n";

      if ( $p2 == $p1+1 ){

        if ( $p1 != 0 ){ $tmp = substr( $txt, $p1-1, 1 ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) } else { $pr = 0 };

        if ( not $pr ){ $tmp = substr( $txt, $p2, 1 ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) };

        if ( $pr ){
          push @tokens, $p1+$offset, $p2+$offset; # from and to
        };

      } else {

        for ( $i = 0; $i < ( $p2-$p1 ); $i++ ){

          #print STDERR "A2: ".substr($m1,$i,1)." -> from $p1 to $p2\n";

          push @tokens, $p1+$i+$offset, $p1+$i+1+$offset; # from and to
        }
      }

    } # fi: "$m1" ne ""

    #print STDERR "B: "."$m2 -> from ".($-[2]+$offset)." to ".($+[2]+$offset)."\n" if defined $m2;   # token (wordform)

    if ( defined $m2 ){
      push @tokens, $-[2]+$offset, $+[2]+$offset; # from and to
    };

    if ( defined $m3 ){

      $p1 = $-[3]; $p2 = $+[3];

      #print STDERR "C: ".$m3." -> from $p1 to $p2\n";

      if ( $p2 == $p1+1 ){

        $tmp = substr( $txt, $p2, 1); $pr = ( $tmp =~ /^$/ ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) if not $pr; # char after match

        if ( not $pr ){ $tmp = substr( $txt, $p1-1, 1 ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) }; # char before match

        if ( $pr ){
          push @tokens, $p1+$offset, $p2+$offset; # from and to
        };

      } else { # length($m3)>1 => print all chars

        for ( $i = 0; $i < ( $p2-$p1 ); $i++ ){

          #$tmp=substr($m3,$i,1);
          #print STDERR "C2: $tmp -> from $p1 to $p2\n";

          push @tokens, $p1+$i+$offset, $p1+$i+1+$offset; # from and to
        }

      }

    } # fi: defined $m3

    if ( "$m4" ne "" ){ # special chars after token

      $p1 = $-[4]; $p2 = $+[4];

      #print STDERR "D1: ".$m4." -> from ".($p1+$offset)." to ".($p2+$offset)."\n";

      if ( $p2 == $p1+1 ){

        $tmp = substr( $txt, $p2, 1 ); $pr = ( $tmp =~ /^$/ ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) if not $pr; # char after match

        if ( not $pr ){ $tmp = substr ( $txt, $p1-1, 1 ); $pr = ( $tmp =~ /^[^A-Za-z0-9]/ ) }; # char before match

        if ( $pr ){
          push @tokens, $p1+$offset, $p2+$offset;  # from and to
        }

      }else{

        for ( $i = 0; $i < ( $p2-$p1 ); $i++ ){

          #print STDERR "D2: ".substr($m4,$i,1)." -> from ".($p1+$i+$offset)." to ".($p1+$i+1+$offset)."\n";

          push @tokens, $p1+$i+$offset, $p1+$i+1+$offset; # from and to
        }
      }

    }# fi: "$m4" ne ""

  }# end: while


  # ~ end: conservative tokenization ~


  ##$offset = $dl+1;

  # TEMP:
  $dl = 4;
  $offset = $dl;

  return \@tokens
}; # fi: $_GEN_TOK_DUMMY

1;
