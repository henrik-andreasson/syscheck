#!/usr/bin/perl

use DBI;

my $syscheckhome = $ENV{'SYSCHECK_HOME'};

# read mysql root pass from syscheck config
open(SYSCHECKCONF, "$syscheckhome/config/common.conf");
my @syscheckconf = <SYSCHECKCONF>;
close SYSCHECKCONF;
my $mysqlrootpass = undef;
foreach (@syscheckconf){ 
	if(m/MYSQLROOT_PASSWORD/gio){
		print "rootpass:  $_\n";
		chomp;
		$_ =~ m/MYSQLROOT_PASSWORD.*=(.*)/;
		$mysqlrootpass = $1;	
		$mysqlrootpass =~ s/"//gio;
	}
}


print "rootpass: $mysqlrootpass\n";
my $dbh = DBI->connect("DBI:mysql:database=mysql", 'root' , $mysqlrootpass , {'RaiseError' => 1, 'AutoCommit' => 0});

print "RESET MASTER\n";
my $sqlreset  = "RESET MASTER;";
my $sth = $dbh->prepare($sqlreset);
$sth->execute;
$dbh->commit;
if ($@) {
	die $@; # print the error
}else{
	print "RESET MASTER: ok\n";
}


my $sqlflush = "FLUSH TABLES WITH READ LOCK;";
$sth = $dbh->prepare($sqlflush);
$sth->execute;
$dbh->commit;
if ($@) {
	die $@; # print the error
}else{
        print "FLUSH TABLES WITH READ LOCK: ok\n";
}

my $sqlshow  = "SHOW MASTER STATUS;";
$sth = $dbh->prepare($sqlshow);
$sth->execute;
$dbh->commit;
if ($@) {
	die $@; # print the error
}else{
        print "Master logfile, Log pos,null,null\n";
	DBI::dump_results($sth);
        print "SHOW MASTER STATUS: ok\n";
}


my $backup = system("$syscheckhome/related-enabled/904_make_mysql_db_backup.sh -s ");

my $sqlunlock="UNLOCK TABLES;";
$sth = $dbh->prepare($sqlunlock);
$sth->execute;
$dbh->commit;
if ($@) {
	die $@; # print the error
}else{
        print "UNLOCK TABLES: ok\n";

}

$dbh->disconnect;
