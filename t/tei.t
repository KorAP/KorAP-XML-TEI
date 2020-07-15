use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/../lib";
};


my $_DEBUG  = 0; # set to 1 for debugging (see below)


# ~ main ~

my $_UNLINK = 1; # default (remove temp. file created by func. tempfile)

if( $_DEBUG ){
  $_UNLINK  = 0;              # keep file created by func. tempfile
  #$File::Temp::KEEP_ALL = 1; # keep all temp. files
  #$File::Temp::DEBUG    = 1; # more debug output
}

use_ok('KorAP::XML::TEI', 'remove_xml_comments');

#my ($fh, $filename) = tempfile();
(my $fh, my $filename) = tempfile("KorAP-XML-TEI_tei_XXXXXXXXXX", SUFFIX => ".tmp", TMPDIR => 1, UNLINK => $_UNLINK);

print $fh <<'HTML';
mehrzeiliger
Kommentar
  -->
Test
HTML

is(remove_xml_comments($fh, "hallo"),"hallo");
is(remove_xml_comments($fh, "hallo <!-- Test -->"),"hallo ");
is(remove_xml_comments($fh, "<!-- Test --> hallo")," hallo");

seek($fh, 0, 0);

is(remove_xml_comments($fh, '<!--'), "Test\n");

seek($fh, 0, 0);

print $fh <<'HTML';
mehrzeiliger
Kommentar
  --><!-- Versuch
-->ist <!-- a --><!-- b --> ein Test
HTML

seek($fh, 0, 0);

is(remove_xml_comments($fh, 'Dies <!--'), "Dies ist  ein Test\n");

##close($fh); # Not necessary, as tempfile is automatically removed when this program exits;
              # Anyway, if it should be kept, this should always be the last statement before 'done_testing',
              #  because the temp. file pointed to by $fh can't be used anymore, when it's unlinked on closing $fh.

done_testing;
