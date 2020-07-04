package KorAP::XML::TEI;
use strict;
use warnings;

sub delHTMLcom { # remove HTML comments
  my ($fh, $html) = @_;

  # the source code part where $tc is used, leads to the situation, that comments can produce an additional blank, which
  # sometimes is not desirable (e.g.: '...<!-- comment -->\n<w>token</w>...' would lead to '... <w>token</w>...' in $buf_in).
  # removing comments before processing the line, prevents this situation.

  my $pfx = '';
  my $i = 0;

 CHECK:

  $html =~ s/<!--.*?-->//g; # remove all comments in actual line

  # Remove comment spanning over several lines
  # No closing comment found
  if ( index($html, '-->') == -1) {

    # Opening comment found
    $i = index($html, '<!--');
    if ($i != -1) {
      $pfx = substr($html, 0, $i);

      # Consume all lines until the closing comment is found
      while ( $html = <$fh> ){

        $i = index($html, '-->');
        if ($i != -1){
          $html = substr($html, $i + 3);
          last;
        }

      }

      $html = $pfx . ($html // '');
      goto CHECK;
    }
  }

  if ( $html =~ /^\s*$/ ){ # get next line and feed it also to this sub, if actual line is empty or only contains whitespace

    $html = <$fh>;
    goto CHECK;
  }

  return $html
}

1;
