#!/usr/bin/perl 
use Date::Manip;

my $indate = $ARGV[0];
# input log date on the format: 20081128 09:01:30
$indate =~ m/(\d{4})(\d{2})(\d{2})\ (\d{2}):(\d{2}):(\d{2})/gio;
my ($year, $mon, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
$logsec = Date_SecsSince1970($mon,$day,$year,$hour,$min,$sec);

# get now in secs
($nsec,$nmin,$nhour,$nmday,$nmon,$nyear,$nwday,$nyday,$nisdst) = localtime(time);
$nyear+=1900;
$nmon++;
my $nowsec = Date_SecsSince1970($nmon,$nmday,$nyear,$nhour,$nmin,$nsec);

# diff
my $diff=int(($nowsec - $logsec)/60);

print "$diff minutes since last log\n";
