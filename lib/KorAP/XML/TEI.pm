use utf8;
package KorAP::XML::TEI;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(remove_xml_comments escape_xml escape_xml_minimal replace_entities increase_auto_textsigle);

# convert '&', '<' and '>' into their corresponding sgml-entities
my %ent_without_quot = (
  '&' => '&amp;',
  '<' => '&lt;',
  '>' => '&gt;'
);

my %ent = (
  %ent_without_quot,
  '"' => '&quot;'
);

#  GET http://corpora.ids-mannheim.de/I5/DTD/ids-lat1.ent | perl -C255 -wlne 'print "'\''$1'\''\t=>\t '\''", chr($2), "'\'', # $3" if(/ENTITY (\S*)\s".#(\d+).*<!-- (.*) -->/)'
my %html_entities = (
  'alpha'  => 'α', # GREEK SMALL LETTER ALPHA
  'ap'     => '≈', # ALMOST EQUAL TO
  'bdquo'  => '„', # DOUBLE LOW-9 QUOTATION MARK
  'blk12'  => '▒', # MEDIUM SHADE
  'blk14'  => '░', # LIGHT SHADE
  'blk34'  => '▓', # DARK SHADE
  'block'  => '█', # FULL BLOCK
  'boxDL'  => '╗', # BOX DRAWINGS DOUBLE DOWN AND LEFT
  'boxdl'  => '┐', # BOX DRAWINGS LIGHT DOWN AND LEFT
  'boxdr'  => '┌', # BOX DRAWINGS LIGHT DOWN AND RIGHT
  'boxDR'  => '╔', # BOX DRAWINGS DOUBLE DOWN AND RIGHT
  'boxH'   => '═', # BOX DRAWINGS DOUBLE HORIZONTAL
  'boxh'   => '─', # BOX DRAWINGS LIGHT HORIZONTAL
  'boxhd'  => '┬', # BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
  'boxHD'  => '╦', # BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
  'boxhu'  => '┴', # BOX DRAWINGS LIGHT UP AND HORIZONTAL
  'boxHU'  => '╩', # BOX DRAWINGS DOUBLE UP AND HORIZONTAL
  'boxUL'  => '╝', # BOX DRAWINGS DOUBLE UP AND LEFT
  'boxul'  => '┘', # BOX DRAWINGS LIGHT UP AND LEFT
  'boxur'  => '└', # BOX DRAWINGS LIGHT UP AND RIGHT
  'boxUR'  => '╚', # BOX DRAWINGS DOUBLE UP AND RIGHT
  'boxv'   => '│', # BOX DRAWINGS LIGHT VERTICAL
  'boxV'   => '║', # BOX DRAWINGS DOUBLE VERTICAL
  'boxvh'  => '┼', # BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
  'boxVH'  => '╬', # BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
  'boxvl'  => '┤', # BOX DRAWINGS LIGHT VERTICAL AND LEFT
  'boxVL'  => '╣', # BOX DRAWINGS DOUBLE VERTICAL AND LEFT
  'boxVR'  => '╠', # BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
  'boxvr'  => '├', # BOX DRAWINGS LIGHT VERTICAL AND RIGHT
  'bull'   => '•', # BULLET
  'caron'  => 'ˇ', # CARON
  'ccaron' => 'č', # LATIN SMALL LETTER C WITH CARON
  'circ'   => 'ˆ', # MODIFIER LETTER CIRCUMFLEX ACCENT
  'dagger' => '†', # DAGGER
  'Dagger' => '‡', # DOUBLE DAGGER
  'ecaron' => 'ě', # LATIN SMALL LETTER E WITH CARON
  'euro'   => '€', # EURO SIGN
  'fnof'   => 'ƒ', # LATIN SMALL LETTER F WITH HOOK
  'hellip' => '…', # HORIZONTAL ELLIPSIS
  'Horbar' => '‗', # DOUBLE LOW LINE
  'inodot' => 'ı', # LATIN SMALL LETTER DOTLESS I
  'iota'   => 'ι', # GREEK SMALL LETTER IOTA
  'ldquo'  => '“', # LEFT DOUBLE QUOTATION MARK
  'ldquor' => '„', # DOUBLE LOW-9 QUOTATION MARK
  'lhblk'  => '▄', # LOWER HALF BLOCK
  'lsaquo' => '‹', # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
  'lsquo'  => '‘', # LEFT SINGLE QUOTATION MARK
  'lsquor' => '‚', # SINGLE LOW-9 QUOTATION MARK
  'mdash'  => '—', # EM DASH
  'ndash'  => '–', # EN DASH
  'nu'     => 'ν', # GREEK SMALL LETTER NU
  'oelig'  => 'œ', # LATIN SMALL LIGATURE OE
  'OElig'  => 'Œ', # LATIN CAPITAL LIGATURE OE
  'omega'  => 'ω', # GREEK SMALL LETTER OMEGA
  'Omega'  => 'Ω', # GREEK CAPITAL LETTER OMEGA
  'permil' => '‰', # PER MILLE SIGN
  'phi'    => 'φ', # GREEK SMALL LETTER PHI
  'pi'     => 'π', # GREEK SMALL LETTER PI
  'piv'    => 'ϖ', # GREEK PI SYMBOL
  'rcaron' => 'ř', # LATIN SMALL LETTER R WITH CARON
  'rdquo'  => '”', # RIGHT DOUBLE QUOTATION MARK
  'rho'    => 'ρ', # GREEK SMALL LETTER RHO
  'rsaquo' => '›', # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
  'rsquo'  => '’', # RIGHT SINGLE QUOTATION MARK
  'rsquor' => '‘', # LEFT SINGLE QUOTATION MARK
  'scaron' => 'š', # LATIN SMALL LETTER S WITH CARON
  'Scaron' => 'Š', # LATIN CAPITAL LETTER S WITH CARON
  'sigma'  => 'σ', # GREEK SMALL LETTER SIGMA
  'squ'    => '□', # WHITE SQUARE
  'squb'   => '■', # BLACK SQUARE
  'squf'   => '▪', # BLACK SMALL SQUARE
  'sub'    => '⊂', # SUBSET OF
  'tilde'  => '˜', # SMALL TILDE
  'trade'  => '™', # TRADE MARK SIGN
  'uhblk'  => '▀', # UPPER HALF BLOCK
  'Yuml'   => 'Ÿ', # LATIN CAPITAL LETTER Y WITH DIAERESIS
  'zcaron' => 'ž', # LATIN SMALL LETTER Z WITH CARON
  'Zcaron' => 'Ž', # LATIN CAPITAL LETTER Z WITH CARON
);

# remove xml comments
sub remove_xml_comments {
  my ($fh, $html) = @_;

  # the source code part where $tc is used, leads to the situation,
  # that comments can produce an additional blank, which
  # sometimes is not desirable (e.g.: '...<!-- comment -->\n<w>token</w>...'
  # would lead to '... <w>token</w>...' in $buf_in).
  # removing comments before processing the line, prevents this situation.

  my $pfx = '';
  my $i = 0;

 CHECK:

  return '' unless $html;

  $html =~ s/<!--.*?-->//g; # remove all comments in actual line

  # Remove comment spanning over several lines
  # No closing comment found
  if (index($html, '-->') == -1) {

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

  if ($html =~ /^\s*$/) {
    # get next line and feed it also to this sub,
    # if actual line is empty or only contains whitespace
    $html = <$fh>;
    goto CHECK;
  };

  return $html
};


# Escape strings using XML entities
sub escape_xml {
  ($_[0] // '') =~ s/([&<>"])/$ent{$1}/ger;
};


# Escape
sub escape_xml_minimal {
  ($_[0] // '') =~ s/([&<>])/$ent_without_quot{$1}/ger;
};

# Replace all entities, except %ent
sub replace_entities {
  $_= shift;
  return ($_) if index($_,'&') < 0;
  s/&#(?:34|x22);/&quot;/gi;
  s/&#(?:38|x26);/&amp;/gi;
  s/&#(?:39|x27);/&apos;/gi;
  s/&#(?:60|x3c);/&lt;/gi;
  s/&#(?:62|x3e);/&gt;/gi;
  s/[&]#(x[0-9A-Fa-f]+);/chr(hex("0$1"))/ge;
  s/[&]#(\d+);/chr($1)/ge;
  s/\&(alpha|ap|bdquo|blk12|blk14|blk34|block|boxDL|boxdl|boxdr|boxDR|boxH|boxh|boxhd|boxHD|boxhu|boxHU|boxUL|boxul|boxur|boxUR|boxv|boxV|boxvh|boxVH|boxvl|boxVL|boxVR|boxvr|bull|caron|ccaron|circ|dagger|Dagger|ecaron|euro|fnof|hellip|Horbar|inodot|iota|ldquo|ldquor|lhblk|lsaquo|lsquo|lsquor|mdash|ndash|nu|oelig|OElig|omega|Omega|permil|phi|pi|piv|rcaron|rdquo|rho|rsaquo|rsquo|rsquor|scaron|Scaron|sigma|squ|squb|squf|sub|tilde|trade|uhblk|Yuml|zcaron|Zcaron);/$html_entities{$1}/ge;
  return($_);
};

sub increase_auto_textsigle {
  my $sigle = shift;

  if ($sigle =~ /(\d+)$/) {
    my $number = $1;
    my $length = length($number);
    $number++;
    my $new_number = sprintf("%0${length}d", $number);
    $sigle =~ s/\d+$/$new_number/;
  }
  return $sigle;
}
1;
