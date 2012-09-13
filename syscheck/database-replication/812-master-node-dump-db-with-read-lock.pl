#!/usr/bin/perl

use DBI;

print "Will in once sweep do the following:\n";
print "Rest master on this host\n";
print "lock tables during a backup\n";
print "start the backup\n";
print "unlock the tables\ni";
print "no need for waiting while backup running (it's transaction secure)\n";
print "is this really what you want?\n";
print "if so type: im-really-sure, but with out the hypens(-)\n";
my $safenet=<STDIN>;
if($safenet=~m/im really sure/){
	print "ok proceeding, now remember to transfer the database dump to the replica and load it there, then restart replication\n";
}else{
	print "ok maybe safest, welcome back though\n";
	exit;
}

my $syscheckhome = $ENV{'SYSCHECK_HOME'};

# read mysql root pass from syscheck config
open(SYSCHECKCONF, "$syscheckhome/config/common.conf");
my @syscheckconf = <SYSCHECKCONF>;
close SYSCHECKCONF;
my $mysqlrootpass = undef;
foreach (@syscheckconf){ 
	if(m/MYSQLROOT_PASSWORD/gio){
		chomp;
		$_ =~ m/MYSQLROOT_PASSWORD.*=(.*)/;
		$mysqlrootpass = $1;	
		$mysqlrootpass =~ s/"//gio;
	}
}


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

print localtime(time) . "\n";
my $pid = fork();
if (not defined $pid) {
	print "fork failed";
} elsif ($pid == 0) {
    print "backup in process\n";
    print "backup filename:\n";
    system("$syscheckhome/related-enabled/904_make_mysql_db_backup.sh --batch");
    print "to transfer database backup run:\n";
    print "$syscheckhome/related-enabled/906_ssh-copy-to-remote-machine.sh -s file-from-above replica-hostname /home/jboss jboss /home/jboss/.ssh/id_rsa\n";
    print "backup done\n";
    exit 0;
} else {

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

	print localtime(time) . "\n";
	waitpid($pid, 0);
	print localtime(time) . "\n";
}
