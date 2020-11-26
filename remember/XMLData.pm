# Whitespace handling is done aside

# ~ recursion ~
# Instead of:
# retr_info(1, \$tree_data->[2] ); # parse input data


# Iterate through XML
$data->register(
  sub {
    my ($self, $element) = @_;

    my $anno = $structures->add_new_annotation($n);

    ...;

    $self->process($e);

    ...;

    $anno->set_to($x);
  }
);

# Process element
$data->process($e)



sub process {
  my $self = shift;
  my $element = shift;
  $self->{level}++;

  my $add_one = 1;

  if ($e->[0] == XML_READER_TYPE_TEXT || $e->[0] == XML_READER_TYPE_SIGNIFICANT_WHITESPACE) {
    $add_one = 0;

    ...
  }
  elsif ($e->[0] == XML_READER_TYPE_ELEMENT) {
    weaken $self;
    $self->registered_callback->($self, $e);

    # whitespace handling
  };
};



# or
$data->collect_annotations(
  'w' => $tokens,    # collect 'w'-Tags
  '*' => [$structures] # collect all tags
);

my $anno = anno;
foreach (@annotations) {
  $_->add_annotation($anno);
};
