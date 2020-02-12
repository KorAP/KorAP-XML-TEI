#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'tei2korapxml',
  AUTHOR       => 'Peter Harders',
  ABSTRACT     => 'Conversion of TEI P5 based formats to KorAP-XML',
  VERSION      => '0.1',
  LICENSE      => 'freebsd',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 0
  },
  PREREQ_PM => {
    'XML::CompactTree::XS'     => '0.03',
    'XML::LibXML::Reader' => '2.0201',
    'IO::Compress::Zip' => '2.091',
  },
  MIN_PERL_VERSION => '5.016',
  EXE_FILES => ['./script/tei2korapxml']
);
