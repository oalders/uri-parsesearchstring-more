#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;
use lib '../lib';

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

pod_coverage_ok( 'URI::ParseSearchString::More' );

done_testing();
