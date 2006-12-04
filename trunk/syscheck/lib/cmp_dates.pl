#!/usr/bin/perl

use Date::Manip;

my $indate = $ARGV[0];

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
$date1 = Date_SecsSince1970($mon,$day,$year,$hour,$min,$sec);

# get now in secs
my ($nsec,$nmin,$nhour,$nmday,$nmon,$nyear,$nwday,$nyday,$isdst) = localtime(time);
$nyear+=1900;
$nmon++;
$date2 = Date_SecsSince1970($nmon,$nmday,$nyear,$nhour,$nmin,$nsec);

# diff
my $diff=int(($date2 - $date1)/3600);

print "$diff\n";
