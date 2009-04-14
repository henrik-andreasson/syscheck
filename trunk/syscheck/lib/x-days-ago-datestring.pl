#!/usr/bin/perl

$KEEPDAYS=$ARGV[0];
if( "x$KEEPDAYS" eq "x" ){
    die "arg1 undefined (should be number of days)"
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time - (60*60*24*$KEEPDAYS));
$year += 1900;
$mon++;
printf("%04d-%02d-%02d\n" , $year, $mon, $mday );

