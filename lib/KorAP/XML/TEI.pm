package KorAP::XML::TEI;
use strict;
use warnings;

sub delHTMLcom { # remove HTML comments
  my ($fh, $html) = @_;

  # the source code part where $tc is used, leads to the situation, that comments can produce an additional blank, which
  # sometimes is not desirable (e.g.: '...<!-- comment -->\n<w>token</w>...' would lead to '... <w>token</w>...' in $buf_in).
  # removing comments before processing the line, prevents this situation.

  my ( $pfx, $sfx ) = ('','');

 CHECK:

  while ( $html =~ s/<!--.*?-->//g ){}; # remove all comments in actual line

  if ( $html =~ /^(.*)<!--/ && $html !~ /-->/ ){ # remove comment spanning over several lines

    $pfx = $1;

    while ( $html = <$fh> ){

      if ( $html =~ /-->(.*)$/ ){
        $sfx = $1; last
      }

    }

    $html = "$pfx$sfx";
    goto CHECK;
  }

  if ( $html =~ s/^\s*$// ){ # get next line and feed it also to this sub, if actual line is empty or only contains whitespace

    $html = <$fh>; delHTMLcom ( $fh, $html );
  }

  return $html
}

1;
