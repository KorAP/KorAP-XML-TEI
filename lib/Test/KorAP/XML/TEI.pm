package Test::KorAP::XML::TEI;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use Exporter 'import';

our @EXPORT_OK = qw(korap_tempfile i5_template);

our $data;
unless ($data) {
  $data .= <DATA> while !eof(DATA);
};

# Create a temporary file and file handle
# That will stay intact, if KORAPXMLTEI_DONTUNLINK is set to true.
sub korap_tempfile {
  my $pattern = shift;
  $pattern .= '_' if $pattern;

  # default: remove temp. file created by func. tempfile
  #  to keep temp. files use e.g. 'KORAPXMLTEI_DONTUNLINK=1 prove -lr t/script.t'
  return tempfile(
    'KorAP-XML-TEI_' . ($pattern // '') . 'XXXXXXXXXX',
    SUFFIX => '.tmp',
    TMPDIR => 1,
    UNLINK => $ENV{KORAPXMLTEI_DONTUNLINK} ? 0 : 1
  )
};


# Return basic i5 document with replacable parts.
# Supports:
# - korpusSigle
# - dokumentSigle
# - textSigle
# - text
sub i5_template {
  my %replace = @_;
  my $tpl = $data;

  foreach my $key (keys %replace) {
    $tpl =~ s!<% $key %>!$replace{$key}!ge;
  };

  for ($tpl) {
    s!<% korpusSigle %>!AAA!g;
    s!<% dokumentSigle %>!AAA/BBB!g;
    s!<% textSigle %>!AAA/BBB.00000!g;
    s!<% text %>!Lorem ipsum!g;
  };

  return $tpl;
};


1;


__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE idsCorpus
  PUBLIC
  "-//IDS//DTD IDS-I5 1.0//EN"
  "http://corpora.ids-mannheim.de/I5/DTD/i5.dtd">
<idsCorpus>
  <idsHeader type="corpus">
    <fileDesc>
      <titleStmt>
        <korpusSigle><% korpusSigle %></korpusSigle>
      </titleStmt>
    </fileDesc>
  </idsHeader>
  <idsDoc version="1.0">
    <idsHeader type="document">
      <fileDesc>
        <titleStmt>
          <dokumentSigle><% dokumentSigle %></dokumentSigle>
        </titleStmt>
      </fileDesc>
    </idsHeader>
    <idsText version="1.0">
      <idsHeader type="text">
        <fileDesc>
          <titleStmt>
            <textSigle><% textSigle %></textSigle>
          </titleStmt>
        </fileDesc>
      </idsHeader>
      <text>
        <% text %>
      </text>
    </idsText>
  </idsDoc>
</idsCorpus>
__END__
