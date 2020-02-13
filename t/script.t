use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile/;

use Test::More;
use Test::Output;

my $f = dirname(__FILE__);
my $script = catfile($f, '..', 'script', 'tei2korapxml');
ok(-f $script, 'Script found');

stderr_is(
  sub { system('perl', $script, '--help') },
  "This program is called from inside another script.\n",
  'Help'
);


my $file = catfile($f, 'data', 'goe_sample.i5.xml');
stdout_is(
  sub {
    open(DATE, "cat $file|perl $script|");
    my $theDate = <DATE>;
    close(DATE);

    print $theDate;
    
    #    system('cat', $file, '|', 'perl', $script)
  },
  "This program is called from inside another script.\n",
  'Help'
);




done_testing;
