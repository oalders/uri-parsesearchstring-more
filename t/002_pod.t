#!/usr/bin/perl

#use Test::More qw( no_plan );
use Test::Pod;
my @pod_dirs = ('../lib');

all_pod_files_ok( all_pod_files( @pod_dirs ) );
