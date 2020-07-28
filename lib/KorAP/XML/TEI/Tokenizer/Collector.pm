package KorAP::XML::TEI::Tokenizer::Collector;
use base 'KorAP::XML::TEI::Tokenizer';
use KorAP::XML::TEI::Tokenizer::Token;
use Encode qw(encode decode);
use strict;
use warnings;


# Add token to tokens list
sub add_token {
  my $self = shift;
  my $token = KorAP::XML::TEI::Tokenizer::Token->new(@_);
  push @$self, $token;
  return $token;
};


# Get last token added to the tokens list
sub last_token {
  $_[0]->[$#{$_[0]}];
};


# Stringify all tokens
sub to_string {
  my ($self, $text_id, $with_inline_annotations) = @_;

  unless ($text_id) {
    warn 'Missing textID';
    return;
  };

  my $output = $self->_header($text_id);

  # Iterate
  my $c = 0;


  # correct last from-value (if the 'second to last'
  # from-value refers to an s-tag, then the last from-value
  # is one to big - see retr_info())
  my $last_token = $self->last_token;
  if ($last_token->from == $last_token->to + 1) {
    # TODO:
    #   check
    $last_token->set_from($last_token->to);
  };


  # Serialize with respect to inline annotations
  if ($with_inline_annotations) {
    # Iterate over all tokens
    foreach (@$self) {
      $output .= $_->to_string_with_inline_annotations($c++);
    };
  }

  # Serialize without respect to inline annotations
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
  my ($self, $zip, $text_id, $with_inline_annotations) = @_;
  $zip->print(encode('UTF-8', $self->to_string($text_id, $with_inline_annotations)));
};


1;
