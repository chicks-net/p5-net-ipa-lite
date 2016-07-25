#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::IPA::Lite' ) || print "Bail out!\n";
}

diag( "Testing Net::IPA::Lite $Net::IPA::Lite::VERSION, Perl $], $^X" );
