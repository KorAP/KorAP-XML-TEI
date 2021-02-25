package KorAP::XML::TEI::Inline;
use strict;
use warnings;
use Log::Any '$log';
use XML::CompactTree::XS;
use XML::LibXML::Reader;


# name of the tag containing all information stored in $_tokens_file
our $_TOKENS_TAG = 'w';

# TODO:
#   Replace whitespace handling with Bit::Vector

use constant {
  # XCT_LINE_NUMBERS is only needed for debugging
  # (see XML::CompactTree::XS)
  XCT_PARAM => (
    XCT_DOCUMENT_ROOT
      | XCT_IGNORE_COMMENTS
      | XCT_ATTRIBUTE_ARRAY
      | ($ENV{KORAPXMLTEI_DEBUG} ? XCT_LINE_NUMBERS : 0)
  ),

  # Set to 1 for minimal more debug output (no need to be parametrized)
  DEBUG => $ENV{KORAPXMLTEI_DEBUG} // 0,

  # Array constants
  ADD_ONE            => 0,
  WS                 => 1,
  TEXT_ID            => 2,
  DATA               => 3,
  TOKENS             => 5,
  STRUCTURES         => 6,
  SKIP_INLINE_TAGS   => 7,
  SKIP_INLINE_TOKENS => 8
};


# Constructor
sub new {
  my $class = shift;
  my %self_hash = @_;

  my @self = (
    # variables for handling ~ whitespace related issue ~
    # (it is sometimes necessary, to correct the from-values for some tags)
    0, # ADD_ONE

    # hash for indices of whitespace-nodes
    # (needed to recorrect from-values)
    # IDEA:
    #   when closing element, check if it's from-index minus 1 refers to a whitespace-node
    #  (means: 'from-index - 1' is a key in %ws).
    #  if this is _not_ the case, then the from-value is one
    #  to high => correct it by substracting 1
    {} # WS
  );

  $self[DATA]               = $self_hash{data};
  $self[TOKENS]             = $self_hash{tokens};
  $self[STRUCTURES]         = $self_hash{structures};
  $self[SKIP_INLINE_TAGS]   = $self_hash{skip_inline_tags} // {};
  $self[SKIP_INLINE_TOKENS] = $self_hash{skip_inline_tokens} // undef;

  bless \@self, $class;
};


# Parse inline data
sub parse {
  my ($self, $text_id_esc, $text_buffer_ref) = @_;

  # whitespace related issue
  $self->[ADD_ONE] = 0;
  $self->[WS] = {};
  $self->[TEXT_ID] = $text_id_esc;

  # Create XML::LibXML::Reader
  my $reader = XML::LibXML::Reader->new(
    string => "<text>$$text_buffer_ref</text>",
    huge => 1
  );

  # Turn reader into XML::CompactTree structure
  my $tree_data = XML::CompactTree::XS::readSubtreeToPerl($reader, XCT_PARAM);

  # Recursively parse all children
  $self->_descend(1, $tree_data->[2]);
};


# Recursively called function to handle XML tree data
sub _descend {
  my $self = shift;

  # recursion level
  # (1 = topmost level inside _descend() = should always be level of tag $_TEXT_BODY)
  my $depth = shift;

  # Iteration through all array elements
  # ($_[0] is a reference to an array reference)
  # See notes on how 'XML::CompactTree::XS' works and
  # see 'NODE TYPES' in manpage of XML::LibXML::Reader
  foreach my $e (@{$_[0]}) {

    # $e->[1] represents the tag name of an element node
    # or the primary data of a text or ws node
    my $node_info = $e->[1];

    # Element node
    if ($e->[0] == XML_READER_TYPE_ELEMENT) {

      # Deal with opening tag

      # Get the child index depending on the debug state.
      # This is likely to be optimized away by the compiler.
      my $children = $e->[DEBUG ? 5 : 4];

      # Skip certain tags
      if ($self->[SKIP_INLINE_TAGS]->{$node_info}) {
        $self->_descend($depth + 1, $children) if defined $children;
        next;
      };

      my $anno = $self->[STRUCTURES]->add_new_annotation($node_info);

      # Add element also to token list
      if (!$self->[SKIP_INLINE_TOKENS] && $node_info eq $_TOKENS_TAG) {
        $self->[TOKENS]->add_annotation($anno);
      };

      # Handle attributes (if attributes exist)
      if (defined $e->[3]) {

        # with 'XCT_ATTRIBUTE_ARRAY', $node->[3] is an array reference of the form
        # [ name1, value1, name2, value2, ....] of attribute names and corresponding values.
        # NOTE:
        #   arrays are faster (see: http://makepp.sourceforge.net/2.0/perl_performance.html)
        for (local $_ = 0; $_ < @{$e->[3]}; $_ += 2) {
          $anno->add_attribute(
            @{$e->[3]}[$_, $_ + 1]
          );
        };
      };

      my $data = $self->[DATA];

      # This is, where a normal tag or tokens-tag ($_TOKENS_TAG) starts
      $anno->set_from($data->position + $self->[ADD_ONE]);

      # Call function recursively
      # do no recursion, if $children is not defined
      # (because we have no array of child-nodes, e.g.: <back/>)
      $self->_descend($depth+1, $children) if defined $children;


      # Deal with closing tag

      # NOTE:
      #   use $pos, because the offsets are _between_ the characters
      #   (e.g.: word = 'Hello' => from = 0 (before 'H'), to = 5 (after 'o'))
      my $pos = $data->position;

      # Handle structures and tokens

      my $from = $anno->from;

      my $ws = $self->[WS];

      # ~ whitespace related issue ~
      if ($from > 0 && not exists $ws->{$from - 1}) {

        # Previous node was a text-node
        $anno->set_from($from - 1);
      };

      # in case this fails, check input
      if (($from - 1) > $pos) {
        die $log->fatal(
          'text_id="' . $self->[TEXT_ID] . '", ' .
            'processing of structures: ' .
            "from-value ($from) is 2 or more greater " .
            "than to-value ($pos) => please check. Aborting"
          );
      };

      # TODO:
      #   find example for which this case applies
      #   maybe this is not necessary anymore, because the
      #   above recorrection of the from-value suffices
      #
      # TODO:
      #   check, if it's better to remove this line and
      #   change above check to 'if ($from - 1) >= $pos;
      #   do testing with bigger corpus excerpt (wikipedia?)
      $anno->set_from($pos) if $from == $pos + 1;
      $anno->set_to($pos);
      $anno->set_level($depth);

      # Clean up whitespace
      delete $ws->{$from  - 1} if $from > 0 && exists $ws->{$from - 1};
    }

    # Text node
    elsif ($e->[0] == XML_READER_TYPE_TEXT) {

      $self->[ADD_ONE] = 1;
      $self->[DATA]->append($node_info);
    }

    # Whitespace node
    # (See notes on whitespace handling - regarding XML_READER_TYPE_SIGNIFICANT_WHITESPACE)
    elsif ($e->[0] == XML_READER_TYPE_SIGNIFICANT_WHITESPACE) {

      # state, that this from-index belongs to a whitespace-node
      #  ('++' doesn't mean a thing here - maybe it could be used for a consistency check)
      $self->[WS]->{$self->[DATA]->position}++;

      $self->[ADD_ONE] = 0;
      $self->[DATA]->append($node_info);
    }

    # not yet handled type
    else {

      die $log->fatal('Not yet handled type ($e->[0]=' . $e->[0] . ') ... => Aborting');
    };
  };
};

1;
