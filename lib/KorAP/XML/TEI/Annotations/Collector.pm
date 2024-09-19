package KorAP::XML::TEI::Annotations::Collector;
use base 'KorAP::XML::TEI::Annotations';
use KorAP::XML::TEI::Annotations::Annotation;
use KorAP::XML::TEI::Annotations::Dependencies;
use Log::Any '$log';
use strict;
use warnings;

use constant {
  WITH_INLINE  => 1,
  STRUCTURE    => 2,
  DEPENDENCIES => 3,
  WITH_INLINE_WITHOUT_DEPS => 4,
  RESET_MARKER => 'RESET'
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


# Add reset marker to parser
sub add_reset_marker {
  push @{$_[0]}, RESET_MARKER;
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

  # Serialize tokens with respect to inline annotations
  # but exclude dependency information
  elsif ($param == WITH_INLINE_WITHOUT_DEPS) {
    # Iterate over all tokens
    foreach (@$self) {
      $output .= $_->to_string_with_inline_annotations($c++, 1);
    };
  }

  # Serialize structures
  elsif ($param == STRUCTURE) {
    # Iterate over all structures
    foreach (@$self) {
      $output .= $_->to_string_as_struct($c++);
    };
  }

  # Serialize dependencies
  elsif ($param == DEPENDENCIES) {

    # Create dependency builder
    my $deps = KorAP::XML::TEI::Annotations::Dependencies->new;

    # Iterate over all dependencies
    foreach (@$self) {
      $output .= $deps->add_annotation_and_flush_to_string($_);
    };

    $output .= $deps->flush_to_string;
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
