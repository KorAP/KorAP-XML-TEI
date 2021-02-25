package KorAP::XML::TEI::Inline;
use strict;
use warnings;
use Log::Any '$log';
use XML::CompactTree::XS;
use XML::LibXML::Reader;

use KorAP::XML::TEI::Data;
use KorAP::XML::TEI::Annotations::Collector;

# Parsing of inline annotations in i5 files

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
  my ($class, $skip_inline_tokens, $skip_inline_tags) = @_;

  my @self = ();

  # variables for handling ~ whitespace related issue ~
  # (it is sometimes necessary, to correct the from-values for some tags)
  $self[ADD_ONE] = 0;

  # hash for indices of whitespace-nodes
  # (needed to recorrect from-values)
  # IDEA:
  #   when closing element, check if it's from-index minus 1 refers to a whitespace-node
  #  (means: 'from-index - 1' is a key in %ws).
  #  if this is _not_ the case, then the from-value is one
  #  to high => correct it by substracting 1
  $self[WS] = {};

  # Initialize data collector
  $self[DATA] = KorAP::XML::TEI::Data->new;

  # Initialize token collector
  $self[TOKENS] = KorAP::XML::TEI::Annotations::Collector->new;

  # Initialize structure collector
  $self[STRUCTURES]         = KorAP::XML::TEI::Annotations::Collector->new;
  $self[SKIP_INLINE_TOKENS] = $skip_inline_tokens // undef;
  $self[SKIP_INLINE_TAGS]   = $skip_inline_tags   // {};

  bless \@self, $class;
};


# Parse inline data
sub parse {
  my ($self, $text_id_esc, $text_buffer_ref) = @_;

  $self->[TEXT_ID] = $text_id_esc;

  # Whitespace related issue
  $self->[ADD_ONE] = 0;
  $self->[WS] = {};

  # Reset all collectors
  $self->[DATA]->reset;
  $self->[STRUCTURES]->reset;
  $self->[TOKENS]->reset;

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

      # ~ whitespace related issue ~
      if ($from > 0) {

        if (exists $ws->{$from - 1}) {
          # Clean up whitespace
          delete $ws->{$from  - 1};
        }
        else {
          # Previous node was a text-node
          $anno->set_from($from - 1);
        };

        # TODO:
        #   check, if it's better to remove this line and
        #   change above check to 'if ($from - 1) >= $pos;
        #   do testing with bigger corpus excerpt (wikipedia?)
        if ($from == $pos + 1) {
          $anno->set_from($pos);
        };
      };

      $anno->set_to($pos);
      $anno->set_level($depth);
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

  1;
};


# Return data collector
sub data {
  $_[0]->[DATA];
};


# Return structures collector
sub structures {
  $_[0]->[STRUCTURES];
};


# Return tokens collector
sub tokens {
  $_[0]->[TOKENS];
};


1;


__END__

# NOTES

##  Notes on how 'XML::CompactTree::XS' works

Example: <node a="v"><node1>some <n/> text</node1><node2>more-text</node2></node>

Print out name of 'node2' for the above example:

echo '<node a="v"><node1>some <n/> text</node1><node2>more-text</node2></node>' | perl -e 'use XML::CompactTree::XS; use XML::LibXML::Reader; $reader = XML::LibXML::Reader->new(IO => STDIN); $data = XML::CompactTree::XS::readSubtreeToPerl( $reader, XCT_DOCUMENT_ROOT | XCT_IGNORE_COMMENTS | XCT_LINE_NUMBERS ); print "\x27".$data->[2]->[0]->[5]->[1]->[1]."\x27\n"'

Exploring the structure of $data ( = reference to below array ):

[ 0: XML_READER_TYPE_DOCUMENT,
  1: ?
  2: [ 0: [ 0: XML_READER_TYPE_ELEMENT                     <- start recursion with array '$data->[2]' (see descend( \$tree_data->[2] ))
            1: 'node'
            2: ?
            3: HASH (attributes)
            4: 1 (line number)
            5: [ 0: [ 0: XML_READER_TYPE_ELEMENT
                      1: 'node1'
                      2: ?
                      3: undefined (no attributes)
                      4: 1 (line number)
                      5: [ 0: [ 0: XML_READER_TYPE_TEXT
                                1: 'some '
                              ]
                           1: [ 0: XML_READER_TYPE_ELEMENT
                                1: 'n'
                                2: ?
                                3: undefined (no attributes)
                                4: 1 (line number)
                                5: undefined (no child-nodes)
                              ]
                           2: [ 0: XML_READER_TYPE_TEXT
                                1: ' text'
                              ]
                         ]
                    ]
                 1: [ 0: XML_READER_TYPE_ELEMENT
                      1: 'node2'
                      2: ?
                      3: undefined (not attributes)
                      4: 1 (line number)
                      5: [ 0: [ 0: XML_READER_TYPE_TEXT
                                1: 'more-text'
                              ]
                         ]
                    ]
               ]
          ]
     ]
]

$data->[0] = 9 (=> type == XML_READER_TYPE_DOCUMENT)

ref($data->[2])                                                         == ARRAY (with 1 element for 'node')
ref($data->[2]->[0])                                                    == ARRAY (with 6 elements)

$data->[2]->[0]->[0]                                                    == 1 (=> type == XML_READER_TYPE_ELEMENT)
$data->[2]->[0]->[1]                                                    == 'node'
ref($data->[2]->[0]->[3])                                               == HASH  (=> ${$data->[2]->[0]->[3]}{a} == 'v')
$data->[2]->[0]->[4]                                                    == 1 (line number)
ref($data->[2]->[0]->[5])                                               == ARRAY (with 2 elements for 'node1' and 'node2')
                                                                                   # child-nodes of actual node (see $children)

ref($data->[2]->[0]->[5]->[0])                                          == ARRAY (with 6 elements)
$data->[2]->[0]->[5]->[0]->[0]                                          == 1 (=> type == XML_READER_TYPE_ELEMENT)
$data->[2]->[0]->[5]->[0]->[1]                                          == 'node1'
$data->[2]->[0]->[5]->[0]->[3]                                          == undefined (=> no attribute)
$data->[2]->[0]->[5]->[0]->[4]                                          == 1 (line number)
ref($data->[2]->[0]->[5]->[0]->[5])                                     == ARRAY (with 3 elements for 'some ', '<n/>' and ' text')

ref($data->[2]->[0]->[5]->[0]->[5]->[0])                                == ARRAY (with 2 elements)
$data->[2]->[0]->[5]->[0]->[5]->[0]->[0]                                == 3 (=> type ==  XML_READER_TYPE_TEXT)
$data->[2]->[0]->[5]->[0]->[5]->[0]->[1]                                == 'some '

ref($data->[2]->[0]->[5]->[0]->[5]->[1])                                == ARRAY (with 5 elements)
$data->[2]->[0]->[5]->[0]->[5]->[1]->[0]                                == 1 (=> type == XML_READER_TYPE_ELEMENT)
$data->[2]->[0]->[5]->[0]->[5]->[1]->[1]                                == 'n'
$data->[2]->[0]->[5]->[0]->[5]->[1]->[3]                                == undefined (=> no attribute)
$data->[2]->[0]->[5]->[0]->[5]->[1]->[4]                                == 1 (line number)
$data->[2]->[0]->[5]->[0]->[5]->[1]->[5]                                == undefined (=> no child-nodes)

ref($data->[2]->[0]->[5]->[0]->[5]->[2])                                == ARRAY (with 2 elements)
$data->[2]->[0]->[5]->[0]->[5]->[2]->[0]                                == 3 (=> type ==  XML_READER_TYPE_TEXT)
$data->[2]->[0]->[5]->[0]->[5]->[2]->[1]                                == ' text'


descend() starts with the array reference ${$_[0]} (= \$tree_data->[2]), which corresponds to ${\$data->[2]} in the above example.
Hence, the expression @{${$_[0]}} corresponds to @{${\$data->[2]}}, $e to ${${\$data->[2]}}[0] (= $data->[2]->[0]) and $e->[0] to
${${\$data->[2]}}[0]->[0] (= $data->[2]->[0]->[0]).

## Notes on whitespace handling

Every whitespace inside the processed text is 'significant' and recognized as a node of type 'XML_READER_TYPE_SIGNIFICANT_WHITESPACE'
(see function 'descend()').

Definition of significant and insignificant whitespace
(source: https://www.oracle.com/technical-resources/articles/wang-whitespace.html):

Significant whitespace is part of the document content and should be preserved.
Insignificant whitespace is used when editing XML documents for readability.
These whitespaces are typically not intended for inclusion in the delivery of the document.

### Regarding XML_READER_TYPE_SIGNIFICANT_WHITESPACE

The 3rd form of nodes, besides text- (XML_READER_TYPE_TEXT) and tag-nodes (XML_READER_TYPE_ELEMENT) are nodes of the type
 'XML_READER_TYPE_SIGNIFICANT_WHITESPACE'.

When modifiying the previous example (see: Notes on how 'XML::CompactTree::XS' works) by inserting an additional blank between
 '</node1>' and '<node2>', the output for '$data->[2]->[0]->[5]->[1]->[1]' is a blank (' ') and it's type is '14'
 (XML_READER_TYPE_SIGNIFICANT_WHITESPACE, see 'man XML::LibXML::Reader'):

echo '<node a="v"><node1>some <n/> text</node1> <node2>more-text</node2></node>' | perl -e 'use XML::CompactTree::XS; use XML::LibXML::Reader; $reader = XML::LibXML::Reader->new(IO => STDIN); $data = XML::CompactTree::XS::readSubtreeToPerl( $reader, XCT_DOCUMENT_ROOT | XCT_IGNORE_COMMENTS | XCT_LINE_NUMBERS ); print "node=\x27".$data->[2]->[0]->[5]->[1]->[1]."\x27, type=".$data->[2]->[0]->[5]->[1]->[0]."\n"'


Example: '... <head type="main"><s>Campagne in Frankreich</s></head><head type="sub"> <s>1792</s> ...'

Two text-nodes should normally be separated by a blank. In the above example, that would be the 2 text-nodes
 'Campagne in Frankreich' and '1792', which are separated by the whitespace-node ' ' (see [2]).

The text-node 'Campagne in Frankreich' leads to the setting of '$add_one' to 1, so that when opening the 2nd 'head'-tag,
 it's from-index gets set to the correct start-index of '1792' (and not to the start-index of the whitespace-node ' ').

The assumption here is, that in most cases there _is_ a whitespace node between 2 text-nodes. The below code fragment
 enables a way, to check, if this really _was_ the case for the last 2 'non-tag'-nodes, when closing a tag:

When a whitespace-node is read, its from-index is stored as a hash-key (in %ws), to state that it belongs to a ws-node.
 So when closing a tag, it can be checked, if the previous 'non-tag'-node (text or whitespace), which is the one before
 the last read 'non-tag'-node, was a actually _not_ a ws-node, but instead a text-node. In that case, the from-value of
 the last read 'non-tag'-node has to be corrected (see [1]),

For whitespace-nodes $add_one is set to 0, so when opening the next tag (in the above example the 2nd 's'-tag), no
 additional 1 is added (because this was already done by the whitespace-node itself when incrementing the variable $pos).

[1]
Now, what happens, when 2 text-nodes are _not_ seperated by a whitespace-node (e.g.: <w>Augen<c>,</c></w>)?
 In this case, the falsely increased from-value has to be decreased again by 1 when closing the enclosing tag
 (see above code fragment '... not exists $ws{ $from - 1 } ...').

[2]
Comparing the 2 examples '<w>fu</w> <w>bar</w>' and '<w>fu</w><w> </w><w>bar</w>', is ' ' in both cases handled as a
 whitespace-node (XML_READER_TYPE_SIGNIFICANT_WHITESPACE).

The from-index of the 2nd w-tag in the second example refers to 'bar', which may not have been the intention
 (even though '<w> </w>' doesn't make a lot of sense). TODO: could this be a bug?

Empty tags also cling to the next text-token - e.g. in '<w>tok1</w> <w>tok2</w><a><b/></a> <w>tok3</w>' are the from-
 and to-indizes for the tags 'a' and 'b' both 12, which is the start-index of the token 'tok3'.


## Notes on whitespace fixing

The idea for the below code fragment was to fix (recreate) missing whitespace in a poorly created corpus, in which linebreaks where inserted
 into the text with the addition that maybe (or not) whitespace before those linebreaks was unintenionally stripped.

It soon turned out, that it was best to suggest considering just avoiding linebreaks and putting all primary text tokens into one line (see
 example further down and notes on 'Input restrictions' in the manpage).

Somehow an old first very poor approach remained, which is not stringent, but also doesn't affect one-line text.

Examples (how primary text with linebreaks would be converted by below code):

  '...<w>end</w>\n<w>.</w>...' -> '...<w>end</w> <w>.</w>...'
  '...<w>,</w>\n<w>this</w>\n<w>is</w>\n<w>it</w>\n<w>!</w>...' -> '<w>,<w> <w>this</w> <w>is</w> <w>it</w> <w>!</w>'.

Blanks are inserted before the 1st character:

 NOTE: not stringent ('...' stands for text):

   beg1............................end1  => no blank before 'beg1'
   beg2....<pb/>...................end2  => no blank before 'beg2'
   beg3....<info attr1="val1"/>....end3  => no blank before 'beg3'
   beg4....<test>ok</test>.........end4  =>    blank before 'beg4'

     =>  beg1....end1beg2...<pb/>...end2beg3....<info attr1="val1"/>....end3 beg4...<test>ok</test>....end4
                                                                            ^
                                                                            |_blank between 'end3' and 'beg4'
