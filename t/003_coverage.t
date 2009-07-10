#!/usr/bin/perl

use Test::Pod::Coverage tests => 1;
use lib '../lib';

pod_coverage_ok( 'URI::ParseSearchString::More' );

