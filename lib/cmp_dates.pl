#!/usr/bin/perl

use Date::Manip;
use Date::Manip::Date;

my $stringdate1 = $ARGV[0];
my $stringdate2 = $ARGV[1];
my $verbose     = $ARGV[2];

printf "Input1: $stringdate1\n" if $verbose;
my $date1  = new Date::Manip::Date;
my $err1   = $date1->parse($stringdate1);
if ( $err1 ne 0 ){
	printf "parse error of crl timestamp";
	exit;
}

printf "Input2: $stringdate2\n" if $verbose;
my $date2  = new Date::Manip::Date;
my $err2   = $date2->parse($stringdate2);
if ( $err2 ne 0 ){
        printf "parse error of now timestamp";
        exit;
}

print "crl date in secs: " . $date1->printf('%s') . "\n" if $verbose;
print "crl date parsed : " . $date1->printf("Now it is %Y-%m-%d %H:%M:%S %Z") . "\n" if $verbose;

print "now date in secs: " . $date2->printf('%s') . "\n" if $verbose;
print "now date parsed : " . $date2->printf("Now it is %Y-%m-%d %H:%M:%S %Z") . "\n" if $verbose;

my $delta = $date2->calc($date1);
printf $delta->printf("Delta: In %hv hours, %mv minutes, %sv seconds\n") if $verbose;

my $deltasec = $delta->printf('%sdms');
my $deltamin = int($deltasec/60);
my $deltahour = int($deltasec/3600);

print "delta sec:  $deltasec\n" if $verbose;
print "delta min:  $deltamin\n" if $verbose;
print "delta hrs:  $deltahour\n" if $verbose;

print "$deltamin\n";
