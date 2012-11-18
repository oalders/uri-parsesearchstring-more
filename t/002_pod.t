#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Pod;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

my @pod_dirs = ( '../lib' );

all_pod_files_ok( all_pod_files( @pod_dirs ) );
