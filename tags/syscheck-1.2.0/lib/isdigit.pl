#!/usr/bin/perl

my $input=$ARGV[0];

if( $input =~ m/^\d+$/ ){
	exit 0;
}else{
	exit 1;
}
