package KorAP::XML::TEI::Annotations::Collector;
use base 'KorAP::XML::TEI::Annotations';
use KorAP::XML::TEI::Annotations::Annotation;
use Log::Any '$log';
use strict;
use warnings;

use constant {
  WITH_INLINE => 1,
  STRUCTURE   => 2
};


# Add new annotation to annotation list
sub add_new_annotation {
  my $self = shift;
  my $token = KorAP::XML::TEI::Annotations::Annotation->new(@_) or return;
  push @$self, $token;
  return $token;
};


# Add existing annotation to annotation list
sub add_annotation {
  push @{$_[0]}, $_[1];
};


# Stringify all tokens
sub to_string {
  my ($self, $text_id, $param) = @_;

  unless ($text_id) {
    $log->warn('Missing textID');
    return;
  };

  my $output = $self->_header($text_id);

  # Iterate
  my $c = 0;

  # Correct tokens
  # TODO:
  #   Check if this is also necessary for structures
  if ($param != STRUCTURE && !$self->empty) {
    # correct last from-value (if the 'second to last'
    # from-value refers to an s-tag, then the last from-value
    # is one to big - see _descend())
    my $last_token = $_[0]->[$#{$_[0]}];
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
  $log->warn('Not supported');
};


1;
