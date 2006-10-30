#!/usr/bin/perl

if( defined  $ENV{'EEL_SERVER_LOG_FILE'} ){
	$LOGFILE=$ENV{'EEL_SERVER_LOG_FILE'};
}else{
	$LOGFILE="/misc/pkg/jboss/server/default/log/server.log";
}

if( defined  $ENV{'EEL_SERVER_LOG_LASTPOSITION'} ){
	$LASTPOSISION_LOGFILE=$ENV{'EEL_SERVER_LOG_LASTPOSITION'};
}else{                                     
	$LASTPOSISION_LOGFILE="/tmp/misc_pkg_jboss_server_default_log_server_log.lastposision";
}

#####################################

sub err2ts($) {
    my $lasterror = shift || die "empty err: $lasterror\n";
    $lasterror =~ m/(\d{4,4})-(\d{1,2})-(\d{1,2})\ +(\d{1,2}):(\d{1,2}):(\d{1,2})/;

    my ($year, $mon, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    
#print "date: $year-$mon-$day\n";
    use Date::Manip;
    my $timestamp_lasterror = Date_SecsSince1970($mon,$day,$year,$hour,$min,$sec);
    return $timestamp_lasterror;
}


sub getErrorsFromFile {
    open(LOG,"<$LOGFILE");
    @logrows=<LOG>;

    my @errors = grep( /ERROR/, @logrows);

    #2006-08-17 08:49:37,160 ERROR [org.ejbca.core.model.ca.publisher.LdapPublisher] Error binding to LDAP server:

    return @errors;
}


sub writeTsFile($){
    my $ts = shift || die "no ts in input arg\n";
    open(LASTERR, ">$LASTPOSISION_LOGFILE");
    print LASTERR "$ts";
    close LASTERR;
}

sub readTsFromFile(){

    open(LASTERR, "<$LASTPOSISION_LOGFILE");
    my $ts  = <LASTERR>;
    close LASTERR;
    return $ts;
}

my @errors = getErrorsFromFile();

my $ts_lastrun = readTsFromFile();

foreach my $err ( @errors ){
    chomp $err;
    my $row_ts = err2ts($err);
#    print "err:$err, $row_ts > $ts_lastrun \n";
    if( $row_ts > $ts_lastrun ){
	print $err;
    }   
	
}

### write last error to file
my $lasterror=@errors[$#errors];
#print "lasterror: $lasterror\n";
my $ts = err2ts($lasterror);
#print "ts: $ts\n";
writeTsFile($ts);


