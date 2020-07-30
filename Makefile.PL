#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'tei2korapxml',
  AUTHOR       => 'Peter Harders',
  ABSTRACT     => 'Conversion of TEI P5 based formats to KorAP-XML',
  VERSION_FROM => 'script/tei2korapxml',
  LICENSE      => 'freebsd',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 0,
    'XML::Loy' => 0.49,
    'IO::Uncompress::Unzip' => '2.091',
    'Pod::Usage'      => 0,
    'Dumbbench' => '0.111',
    'DateTime' => '1.51',
    'Capture::Tiny' => '0.48'
  },
  PREREQ_PM => {
    'XML::CompactTree::XS'     => '0.03',
    'XML::LibXML::Reader' => '2.0201',
    'IO::Compress::Zip' => '2.091'
  },
  MIN_PERL_VERSION => '5.016',
  EXE_FILES => ['script/tei2korapxml']
);
