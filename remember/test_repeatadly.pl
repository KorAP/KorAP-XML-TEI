#!/usr/bin/env perl
use strict;
use warnings;

foreach (1..100) {
  #  system('prove','-lr','-j',9,'t')
    system('prove','-lrv','-j',9,'t/tokenization-external.t')
};
