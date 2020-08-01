package KorAP::XML::TEI::Tokenizer::Collector;
use base 'KorAP::XML::TEI::Tokenizer';
use KorAP::XML::TEI::Tokenizer::Token;
use Encode qw(encode decode);
use strict;
use warnings;

use constant {
  WITH_INLINE => 1,
  STRUCTURE   => 2
};


sub add_token {
  return add_new_annotation(@_);
};


# Add new annotation to annotation list
sub add_new_annotation {
  my $self = shift;
  my $token = KorAP::XML::TEI::Tokenizer::Token->new(@_);
  push @$self, $token;
  return $token;
};


# Add annotation to annotation list
sub add_annotation {
  push @{$_[0]}, $_[1];
};


# Get last token added to the tokens list
sub last_token {
  # DEPRECATED
  $_[0]->[$#{$_[0]}];
};


# Stringify all tokens
sub to_string {
  my ($self, $text_id, $param) = @_;

  unless ($text_id) {
    warn 'Missing textID';
    return;
  };

  my $output = $self->_header($text_id);

  # Iterate
  my $c = 0;

  # Correct tokens
  # TODO:
  #   Check if this is also necessary for structures
  if ($param != STRUCTURE) {
    # correct last from-value (if the 'second to last'
    # from-value refers to an s-tag, then the last from-value
    # is one to big - see retr_info())
    my $last_token = $self->last_token;
    if ($last_token->from == $last_token->to + 1) {
      # TODO:
      #   check
      $last_token->set_from($last_token->to);
    };
  };


  # Serialize tokens with respect to inline annotations
  if ($param == WITH_INLINE) {
    # Iterate over all tokens
    foreach (@$self) {
      $output .= $_->to_string_with_inline_annotations($c++);
    };
  }

  # Serialize structures
  elsif ($param == STRUCTURE) {
    # Iterate over all structures
    foreach (@$self) {
      $output .= $_->to_string_as_struct($c++);
    };
  }

  # Serialize tokens without respect to inline annotations
  else {
    # Iterate over all tokens
    foreach (@$self) {
      $output .= $_->to_string($c++);
    };
  };

  return $output . $self->_footer;
};


# Overwrite non-applicable boundary method
sub boundaries {
  warn 'Not supported';
};


# Write data to zip stream (as utf8)
sub to_zip {
  my ($self, $zip, $text_id, $param) = @_;
  $zip->print(encode('UTF-8', $self->to_string($text_id, $param)));
};


1;
