package KorAP::XML::TEI::Annotations::Annotation;
use strict;
use warnings;
use Log::Any '$log';
use KorAP::XML::TEI 'escape_xml';
use Scalar::Util qw'looks_like_number';

# TODO:
#   Make these parameters passable from the script
#
# handling inline annotations (inside $_TOKENS_TAG)
# from which attribute to read LEMMA or ANA information
my $_INLINE_LEM_RD   = "lemma";
my $_INLINE_ATT_RD   = "ana";

# TODO:
#   The format for the POS and MSD information has to suffice
#   the regular expression ([^ ]+)( (.+))? - which means, that
#   the POS information can be followed by an optional blank with
#   additional MSD information; unlike the MSD part, the POS part
#   may not contain any blanks.
my $_INLINE_POS_WR   = "pos";
my $_INLINE_MSD_WR   = "msd";
my $_INLINE_LEM_WR   = "lemma";

our $_INLINE_DEP_N   = "n";
our $_INLINE_DEP_REL = "deprel";
our $_INLINE_DEP_SRC = "head";
our $_INLINE_DEP_ATTS =
  qr/^($_INLINE_DEP_N|$_INLINE_DEP_REL|$_INLINE_DEP_SRC)$/;

# An annotation is represented as an array reference of information
# with variable length.

use constant {
  TAG         => 0,
  FROM        => 1,
  TO          => 2,
  LEVEL       => 3,
  ATTR_OFFSET => 4
};


# Create a new annotation object
sub new {
  my $class = shift;

  if (defined $_[1]) {
    unless (looks_like_number($_[1])) {
      return;
    };

    if (defined $_[2]) {
      unless (looks_like_number($_[2])) {
        return;
      };

      if (defined $_[3] && !looks_like_number($_[3])) {
        return;
      };
    };
  };

  my $self = bless [@_], $class;

  # Ensure minimum length for pushing attributes
  $#$self = 3;
  return $self;
};


# Set 'from'
sub set_from {
  if (looks_like_number($_[1])) {
    $_[0]->[FROM] = $_[1];
    return 1;
  };
  $log->fatal('Passed non-numeric value as annotation start');
  return;
};


# Get 'from'
sub from {
  $_[0]->[FROM];
};


# Set 'to'
sub set_to {
  if (looks_like_number($_[1])) {
    $_[0]->[TO] = $_[1];
    return 1;
  };
  $log->fatal('Passed non-numeric value as annotation end');
  return;
};


# Get 'to'
sub to {
  $_[0]->[TO];
};


# Set level
sub set_level {
  # Insert information about depth of element in XML-tree
  # (top element = level 1)
  if (looks_like_number($_[1])) {
    $_[0]->[LEVEL] = $_[1];
    return 1;
  };
  $log->fatal('Passed non-numeric value as annotation level');
  return;
};


# Get level
sub level {
  $_[0]->[LEVEL]
};


# Add attributes
sub add_attribute {
  push @{shift()}, @_;
};


# Serialize span information in header
sub _header_span {
  my ($self, $id) = @_;

  # Start with indentation
  return '    ' .
    '<span id="s' . $id .
    '" from="' . ($self->[FROM] // '?') .
    '" to="' . ($self->[TO] // '?') .
    '" l="' . ($self->[LEVEL] // 0) . '">' .
    "\n";
};


# Serialize header for lexemes
sub _header_lex {

  # Start with indentation
  return _header_span(@_) .
    '      ' .
    '<fs type="lex" xmlns="http://www.tei-c.org/ns/1.0">' .
    "\n" .
    '        ' .
    '<f name="lex">' . "\n";
};


# Serialize header for structures
sub _header_struct {

  # Start with indentation
  return _header_span(@_) .
    '      ' .
    '<fs type="struct" xmlns="http://www.tei-c.org/ns/1.0">' .
    "\n" .
    '        ' .
    '<f name="name">' . $_[0]->[TAG] . "</f>\n";
};


# Serialize footer for lex and struct
sub _footer {
  return "      </fs>\n    </span>\n";
};


# Serialize attribute
sub _att {

  # XML escape the attribute value
  # ... <w lemma="&gt;" ana="PUNCTUATION">&gt;</w> ...
  # the '&gt;' is translated to '>' and hence the result would be '<f name="lemma">></f>'
  '            <f name="' . $_[0] . '">' . escape_xml($_[1] // '') . "</f>\n";
};


# Get attributes from annotation
sub get_attributes {
  my $self = shift;
  return @{$self}[ATTR_OFFSET..$#$self];
};


# Stringify without inline annotations
sub to_string {
  my ($self, $id) = @_;

  my $out = $self->_header_lex($id);

  # Check if attributes exist
  if ($self->[ATTR_OFFSET]) {

    $out .= "          <fs>\n";

    # Iterate over all attributes
    for (my $att_idx = ATTR_OFFSET; $att_idx < @{$self}; $att_idx += 2) {

      # Set attribute
      $out .= _att($self->[$att_idx], $self->[$att_idx + 1]);
    };

    $out .= "          </fs>\n";
  };

  return $out . "        </f>\n" . $self->_footer;
};


# Stringify with inline annotations
sub to_string_with_inline_annotations {
  my ($self, $id, $without_deps) = @_;

  my $out = $self->_header_lex($id);

  # if ( $idx > 2 ){ # attributes
  if ($self->[ATTR_OFFSET]) {

    $out .= "          <fs>\n";

    # Iterate over all attributes
    for (my $att_idx = ATTR_OFFSET; $att_idx < @{$self}; $att_idx += 2) {

      # The inline attribute is 'ana' (or something along the lines)
      if ($self->[$att_idx] eq $_INLINE_ATT_RD){

        # Take the first value
        $self->[$att_idx + 1] =~ /^([^ ]+)(?: (.+))?$/;

        # The POS attribute is defined
        if ($_INLINE_POS_WR) {
          unless (defined($1)) {
            die $log->fatal('Unexpected format! => Aborting ... ' .
                              '(att: ' . $self->[ $att_idx + 1 ] . ")");
          };
          $out .= _att($_INLINE_POS_WR, $1);
        };

        # The MSD attribute is defined
        if ($_INLINE_MSD_WR) {
          unless (defined($2)) {
            die $log->fatal('Unexpected format! => Aborting ... ' .
                              '(att: ' . $self->[ $att_idx + 1 ] . ")");
          };
          $out .= _att($_INLINE_MSD_WR, $2);
        };
      }

      # Ignore dependency annotations for tokens
      elsif ($without_deps &&
             $self->[$att_idx] =~ $_INLINE_DEP_ATTS) {
        # Do nothing
      }

      # Inline lemmata are expected
      # TODO:
      #   As $_INLINE_LEM_RD == $_INLINE_LEM_WR this
      #   currently does nothing special.
      # elsif ($_INLINE_LEM_RD && $self->[$att_idx] eq $_INLINE_LEM_RD){
      #   $out .= _att($_INLINE_LEM_WR, $self->[$att_idx + 1]);
      # }

      # Add all other attributes
      else {
        $out .= _att($self->[$att_idx], $self->[$att_idx + 1]);
      };
    };

    $out .= "          </fs>\n";
  };

  return $out . "        </f>\n" . $self->_footer;
};


# Stringify as a struct annotation
sub to_string_as_struct  {
  my ($self, $id) = @_;

  my $out = $self->_header_struct($id);

  # Check if attributes exist
  if ($self->[ATTR_OFFSET]) {

    $out .= '        <f name="attr">' . "\n" .
      '          <fs type="attr">' . "\n";
    # Iterate over all attributes
    for (my $att_idx = ATTR_OFFSET; $att_idx < @{$self}; $att_idx += 2) {
      # Set attribute
      $out .= _att($self->[$att_idx], $self->[$att_idx + 1]);
    };
    $out .= "          </fs>\n" .
      "        </f>\n";
  };

  return $out . $self->_footer;
};


# Stringify with inline dependencies
sub to_string_with_dependencies {
  my ($self, $id, $from, $to, $rel) = @_;

  my $out = $self->_header_span($id);

  my %att = $self->get_attributes;

  $out .= '      <rel label="' . $rel . '">' . "\n";
  $out .= '        <span from="' . $from . '" to="' . $to . '"/>' . "\n";
  $out .= "      </rel>\n";
  return $out . "    </span>\n";
};


1;
