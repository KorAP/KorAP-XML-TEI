use strict;
use warnings;
use Test::More;

require_ok('KorAP::XML::TEI');

is(KorAP::XML::TEI::delHTMLcom("hallo"),"hallo");
is(KorAP::XML::TEI::delHTMLcom("hallo <!-- Test -->"),"hallo ");
is(KorAP::XML::TEI::delHTMLcom("<!-- Test --> hallo")," hallo");

done_testing;
