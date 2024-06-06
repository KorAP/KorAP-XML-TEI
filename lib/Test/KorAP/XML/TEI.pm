package Test::KorAP::XML::TEI;
use strict;
use warnings;
use Test::More;
use Test::XML::Loy;
use Capture::Tiny qw'capture_stderr';
use Encode 'encode';
use File::Temp qw/tempfile/;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;
use IO::Uncompress::Unzip qw($UnzipError);

use Exporter 'import';

our @EXPORT_OK = qw(korap_tempfile i5_template test_tei2korapxml);

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

# Construct script test helper object.
# WARNING:
#   This isn't very portable and works only in the context
#   of the test suite.
sub test_tei2korapxml {
  my ($file, $script, $pattern);
  my ($env, $param, $fh) = ('', '');

  if (@_ == 1) {
    $file = shift;
  }

  else {
    my %hash = @_;
    $file    = $hash{file};
    $script  = $hash{script} if $hash{script};
    $param   = $hash{param}  if $hash{param};
    $env     = $hash{env}    if $hash{env};
    $pattern = $hash{tmp}    if $hash{tmp};

    # Handle template instead of hash
    if ($hash{template} && !$file) {
      my $pattern = delete $hash{template}->{pattern};
      my $tmpl = i5_template(%{$hash{template}});

      # Write template to file
      ($fh, $file) = korap_tempfile($pattern);
      print $fh $tmpl;
      close($fh);
    }
  };

  # Assume script in test environment
  unless ($script) {
    $script = catfile(dirname(__FILE__), '..', '..', '..', '..', 'script', 'tei2korapxml');

    unless (-e $script) {
      $script = undef;
    };
  };

  my $call;
  if ($script) {
    $call = "perl '$script'";
  }

  # Take installed path
  else {
    # This may be unoptimal, as it is silent
    $call = 'tei2korapxml';
  };

  # Because of some capturing issues and for debugging purposes
  # we pipe stdout through a temp file.
  my (undef, $fn) = korap_tempfile($pattern);

  $call = "$env $call $param -i '$file' > $fn";
  my $stderr = capture_stderr { `$call` };

  # Read from written file
  my $stdout = '';
  if (open($fh, '<', $fn)) {
    binmode($fh);
    $stdout .= <$fh> while !eof($fh);
    close($fh);
  };

  # Bless data for inspection
  return bless {
    stdout => $stdout,
    stderr => $stderr
  }, __PACKAGE__;
};


# Set or get success of the last test
sub success {
  my $self = shift;
  if (@_) {
    $self->{success} = shift;
    return $self;
  };
  return $self->{success} // 0;
};


# Check for stderr equality
sub stderr_is {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'is',
    $self->{stderr},
    $value,
    _desc($desc, 'exact match for stderr')
  );
};


# Check for stderr similarity
sub stderr_like {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'like',
    $self->{stderr},
    $value,
    _desc($desc, 'similar to stderr')
  );
};


# Check for stderr non-similarity
sub stderr_unlike {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'unlike',
    $self->{stderr},
    $value,
    _desc($desc, 'not similar to stderr')
  );
};

# Check for stdout equality
sub stdout_is {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'is',
    $self->{stdout},
    $value,
    _desc($desc, 'exact match for stdout')
  );
};


# Check for stdout similarity
sub stdout_like {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'like',
    $self->{stdout},
    $value,
    _desc($desc, 'similar to stdout')
  );
};


# Check for stdout non-similarity
sub stdout_unlike {
  my ($self, $value, $desc) = @_;
  return $self->_test(
    'unlike',
    $self->{stdout},
    $value,
    _desc($desc, 'not similar to stdout')
  );
};


# Check if a zip exists
sub file_exists {
  my ($self, $file, $desc) = @_;

  my $exists;
  if (my $zip = IO::Uncompress::Unzip->new(\$self->{stdout}, Name => $file)) {
    $exists = 1;
  };

  return $self->_test(
    'ok',
    $exists,
    _desc($desc, "File $file exists in zip file")
  );
};


# Check if a zip does not exist
sub file_exists_not {
  my ($self, $file, $desc) = @_;

  my $exists = 1;
  if (my $zip = IO::Uncompress::Unzip->new(\$self->{stdout}, Name => $file)) {
    $exists = 0;
  };

  return $self->_test(
    'ok',
    $exists,
    _desc($desc, "File $file does not exist in zip file")
  );
};


# Check if a zip exists
sub file_readable {
  my ($self, $file, $desc) = @_;

  my $readable;
  if (my $zip = IO::Uncompress::Unzip->new(\$self->{stdout}, Name => $file)) {
    $readable = !$zip->eof;
  };

  return $self->_test(
    'ok',
    $readable,
    _desc($desc, "File $file exists in zip file and is readable")
  );
};


# Get content of a file
sub get_content_of {
  my ($self, $file) = @_;
  if (my $zip = IO::Uncompress::Unzip->new(\$self->{stdout}, Name => $file)) {
    my $data = '';
    $data .= $zip->getline while !$zip->eof;
    $zip->close;
    return $data;
  };
  return '';
};


# Returns an Test::XML::Loy object
sub unzip_xml {
  my ($self, $file) = @_;
  if (my $zip = IO::Uncompress::Unzip->new(\$self->{stdout}, Name => $file)) {
    my $data = '';
    $data .= $zip->getline while !$zip->eof;
    $zip->close;

    return Test::XML::Loy->new($data);
  };

  $self->_test('ok', 0, qq!Unable to unzip "$file"!);
  return;
};


sub _test {
  my ($self, $name, @args) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return $self->success(!!Test::More->can($name)->(@args));
};


sub _desc {
  encode 'UTF-8', shift || shift;
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
