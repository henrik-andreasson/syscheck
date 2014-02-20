#!/usr/bin/perl

use Date::Manip;

my $indate = $ARGV[0];
my $returnMinutes = $ARGV[1];


$now = localtime;

my %mon2int = (	"Jan" => "1",
		"Feb" => "2",
		"Mar" => "3",
		"Apr" => "4",
		"May" => "5",
		"Jun" => "6",
		"Jul" => "7",
		"Aug" => "8",
		"Sep" => "9",
		"Oct" => "10",
		"Nov" => "11",
		"Dec" => "12");
		

# input crl date on the format: May 17 11:23:01 2006 GMT
$indate =~ m/(\w+)\ +(\d+) (\d+):(\d+):(\d+) (\d+)/gio;
my ($strmon, $day, $hour, $min, $sec, $year) = ($1, $2, $3, $4, $5, $6);
my $mon = $mon2int{$strmon};
$date1 = Date_SecsSince1970GMT($mon,$day, $hour, $min, $sec, $year);

# get now in secs
my ($nsec,$nmin,$nhour,$nmday,$nmon,$nyear,$nwday,$nyday,$isdst) = localtime(time);
$nyear+=1900;
$nmon++;
$date2 = Date_SecsSince1970GMT($nmon,$nmday,$nyear,$nhour,$nmin,$nsec);
print "crldate: $date1\n";
print "nowdate: $date2\n";
my $diff =int($date1 - $date2);
my $diff2=int($diff/60);
my $diff3=int($diff/3600);
print "diff(s): $diff\n";
print "diff(m): $diff2\n";
print "diff(h): $diff3\n";

if ( $returnMinutes eq "--return-in-minutes"){
	print "$diff2\n";
}else{
	print "$diff3\n";
}


