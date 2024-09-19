package KorAP::XML::TEI::Annotations::Dependencies;
use KorAP::XML::TEI::Annotations::Annotation;
use strict;
use warnings;

use constant {
  SENTENCE_COUNT => 0,
  FROM_MAP       => 1,
  TO_MAP         => 2,
  ANNO_OFFSET    => 3, # Start of annotations
  RESET_MARKER   => 'RESET'
};

our $_INLINE_DEP_N   = $KorAP::XML::TEI::Annotations::Annotation::_INLINE_DEP_N;
our $_INLINE_DEP_REL = $KorAP::XML::TEI::Annotations::Annotation::_INLINE_DEP_REL;
our $_INLINE_DEP_SRC = $KorAP::XML::TEI::Annotations::Annotation::_INLINE_DEP_SRC;

sub new {
  my $class = shift;
  bless[
    0, # Sentence count
    [], # map n -> "from"
    [], # map n -> to
  ], $class; # add relations as -> head2
};


# Reset the dependency object
sub DESTROY {
  my $self = shift;
  $self->[SENTENCE_COUNT] = 0;
  $self->[FROM_MAP] = [];
  $self->[TO_MAP] = [];
  @$self = ();
};


# Add annotations
sub add_annotation_and_flush_to_string {
  my $self = shift;

  # Reset marker is set
  if ($_[0] eq RESET_MARKER) {
    return $self->flush_to_string;
  };

  # Fill the head maps
  my %att = ($_[0]->get_attributes);

  $self->[FROM_MAP]->[$att{$_INLINE_DEP_N}] = $_[0]->from;
  $self->[TO_MAP]->[$att{$_INLINE_DEP_N}]   = $_[0]->to;

  # Add annotation
  push @{$self}, $_[0];
  return '';
};


# Flush all relations
sub flush_to_string {
  my $self = shift;

  return '' unless $self->[ANNO_OFFSET];

  my $output = '';
  my %att;

  # Map root, now that we know the sentence boundaries
  # Be aware: These are the boundaries based on all tokens
  # that have relations only!
  $self->[FROM_MAP]->[0] = $self->[ANNO_OFFSET]->from;
  $self->[TO_MAP]->[0]   = $self->[$#{$self}]->to;

  # Increment the base values for ID
  $self->[SENTENCE_COUNT]++;
  my $rel_count = 1;

  # Add relations with heads
  foreach (@{$self}[ANNO_OFFSET .. $#$self]) {

    # Create ids
    my $id = $self->[SENTENCE_COUNT] .
      '_n' . $rel_count;

    # In annotations attributes are stored
    # as pair arrays
    %att = $_->get_attributes;

    # Add dep-info to relation
    $output .= $_->to_string_with_dependencies(
      $id,
      $self->[FROM_MAP]->[$att{$_INLINE_DEP_SRC}],
      $self->[TO_MAP]->[$att{$_INLINE_DEP_SRC}],
      $att{$_INLINE_DEP_REL}
    );

    $rel_count++;
  };

  $#{$self->[FROM_MAP]} = 0;
  $#{$self->[TO_MAP]}   = 0;
  $#{$self}             = ANNO_OFFSET -1;

  return $output;
};


1;
