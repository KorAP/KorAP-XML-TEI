package KorAP::XML::TEI::Tokenizer::Token;
use strict;
use warnings;
use KorAP::XML::TEI 'escape_xml';

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

# A token is represented as an array reference of information
# with variable length.

use constant {
  TAG         => 0,
  FROM        => 1,
  TO          => 2,
  LEVEL       => 3,
  ATTR_OFFSET => 4
};


# Create a new token object
sub new {
  my $class = shift;
  my $self = bless [@_], $class;

  # Ensure minimum length for pushing attributes
  $#$self = 3;
  return $self;
};


# Set 'from'
sub set_from {
  $_[0]->[FROM] = $_[1];
};


# Get 'from'
sub from {
  $_[0]->[FROM];
};


# Set 'to'
sub set_to {
  $_[0]->[TO] = $_[1];
};


# Get 'to'
sub to {
  $_[0]->[TO];
};


# Set level
sub set_level {
  $_[0]->[LEVEL] = $_[1];
};


# Get level
sub level {
  $_[0]->[LEVEL]
};


# Add attributes
sub add_attribute {
  push @{shift()}, @_;
};


# Serialize header
sub _header {
  my ($self, $id) = @_;

  # l (level): insert information about depth of element in XML-tree (top element = level 1)
  #$out .= 'from="${$ref}[ $idx ]\" to=\"${$ref}[ $idx+1 ]\" l=\"${$ref}[ $idx+2 ]\">';

  # Start with indentation
  return '    ' .
    '<span id="s' . $id .
    '" from="' . ($self->[FROM] // '?') .
    '" to="' . ($self->[TO] // '?') .
    '" l="' . ($self->[LEVEL] // 0) . '">' .
    "\n" .
    '      ' .
    '<fs type="lex" xmlns="http://www.tei-c.org/ns/1.0">' .
    "\n" .
    '        ' .
    '<f name="lex">' . "\n";
};


# Serialize footer
sub _footer {
  "        </f>\n      </fs>\n    </span>\n";
};


# Serialize attribute
sub _att {

  # XML escape the attribute value
  # ... <w lemma="&gt;" ana="PUNCTUATION">&gt;</w> ...
  # the '&gt;' is translated to '>' and hence the result would be '<f name="lemma">></f>'
  '            <f name="' . $_[0] . '">' . escape_xml($_[1] // '') . "</f>\n";
}


# Stringify without inline annotations
sub to_string {
  my ($self, $id) = @_;

  my $out = $self->_header($id);

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

  return $out . $self->_footer;
};


# Stringify with inline annotations
sub to_string_with_inline_annotations {
  my ($self, $id) = @_;

  my $out = $self->_header($id);

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
            die 'ERROR (write_tokens()): unexpected format! => Aborting ... ' .
              '(att: ' . $self->[ $att_idx + 1 ] . ")\n";
          };
          $out .= _att($_INLINE_POS_WR, $1);
        };

        # The MSD attribute is defined
        if ($_INLINE_MSD_WR) {
          unless (defined($2)) {
            die 'ERROR (write_tokens()): unexpected format! => Aborting ... ' .
              '(att: ' . $self->[ $att_idx + 1 ] . ")\n";
          };
          $out .= _att($_INLINE_MSD_WR, $2);
        };

      }

      # Inline lemmata are expected
      # TODO:
      #   As $_INLINE_LEM_RD == $_INLINE_LEM_WR this
      #   currently does nothing special.
      elsif ($_INLINE_LEM_RD && $self->[$att_idx] eq $_INLINE_LEM_RD){
        $out .= _att($_INLINE_LEM_WR, $self->[$att_idx + 1]);
      }

      # Add all other attributes
      else {
        $out .= _att($self->[$att_idx], $self->[$att_idx + 1]);
      };
    };

    $out .= "          </fs>\n";
  };

  return $out . $self->_footer;
};


1;
