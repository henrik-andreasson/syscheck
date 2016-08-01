# Syscheck version trunk 
Documentation generated: Mon Aug  1 21:53:45 CEST 2016
# Syscheck related scripts 
##  900_export_cert.sh 
```  
Export certificate and archive them, ./900_export_cert.sh <certfile>
01/Export certificate run successfully - no actions needed
02/Export certificate failed (%s)  - Unexpected, run the script with sh -x to check
03/Export certificate failed, script called without file - call this script with a PEM encoded certficate as arg1
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  901_export_revocation.sh 
```  
Export CRL:s with a script ./901_export_revocation.sh <DER-encoded CERT>
01/Export revocation run successfully - no actions needed
02/Export revocation failed (%s)  - check manually with sh -x ./901_export_revocation.sh <file>
03/Export revocation failed, script called without file - call this script with a DER encoded CERT as arg1
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  902_export_crl.sh 
```  
Export CRL ./902_export_crl.sh: <DER encoded CRL>
01/Export CRL run successfully - no action needed
02/Export CRL failed (%s)  - check manual with sh -x ./902_export_crl.sh <crl>
03/Export CRL failed, script called without file - arg1 must be a DER encoded crl!
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  903_make_hsm_backup.sh 
```  

9031/Backup of Nfast HSM run successfully 
9032/Backup of Nfast HSM failed (%s)  
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  904_make_mysql_db_backup.sh 
```  
Mysql backup tool syntax: ./904_make_mysql_db_backup.sh [-x|--default|-d|--daily|-w|--weekly|-m|--monthly|-y|--yearly] [-s|--screen] [-b|--batch] 
 -x and --default will put the backupfile in directory defined in config as SUBDIR_DEFAULT
 -d or --daily will put the backup in the directory defined in config as SUBDIR_DAILY
 -w or --weekly will put the backup in the directory defined in config as SUBDIR_WEEKLY
 -m or --monthly will put the backup in the directory defined in config as SUBDIR_MONTHLY
 -y or --yearly will put the backup in the directory defined in config as SUBDIR_YEARLY
 OBSERVE that it's up to the admin to run this script with cron or alike at these intervals, so run this script once a day with --daily to get only one daily backup and so on
 -b or --batch will echo the resulting filename for processing by other scripts
01/Backed up db ok (file:%s) - no action needed
02/Could not compress the backup (%s) - Check disk space and owner of directory to write backup to
03/Backup failed, backupdir not found (%s) - check the configfile and make sure the configured directory exist
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  905_publish_crl.sh 
```  
./905_publish_crl.sh <-s|--screen>
``` 
##  906_ssh-copy-to-remote-machine.sh 
```  
Script used to copy files to other hosts/directorys usage: ./906_ssh-copy-to-remote-machine.sh: file host <directory> <to-username> <from-ssh-key> 
(if you dont specify directory the file will end up in the user's homedirectory, 
if you dont specify to-username the same user as the one executing this script will be used, 
if from-ssh-key is not specified default key will be used)
01/file transfered ok - ok
02/specify a filename as first argument to this script - filename not specified as argument
03/specify a hostname as second argument to this script - Hostname not specified as argument
04/scp file transfer failed (%s) - check the error message and try to fix it
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  907_make_mysql_db_backup_and_transfer_to_remote_mashine.sh 
```  
Script used to take backup of the sql database, compress and send to a separate server. call with -x|--default for puting the backupfile in the SUBDIR_DEFAULT ; -d|--daily to make daily backup end up in SUBDIR_DAILY; with -w|--weekly to make daily backup end up in SUBDIR_WEEKLY; -m|--monthly to make daily backup end up in SUBDIR_MONTHLY ; -y|--yearly to make daily backup end up in SUBDIR_YEARLY;
01/Backup and transfer was ok. - Ok
02/Could not get the backup from MySQL (%s)  - Could not make a backup.
03/Could not send the backup, maybe connection problem or problem logging in (%s)  - Could not send the backup.
04/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  908_clean_old_backups.sh 
```  

9081/Clean backupfiles run successfully - All is ok
9082/Clean backupfiles failed (%s)  - Unpredicted error while deleting file %s
9083/Clean backupfile file did not exist (%s)  - Maybe the files has been already removed or there was no files from start
9084/Datestring command did NOT return a valid string - try to run x-days-ago-datestring.pl manually ie: lib/x-days-ago-datestring.pl 3
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  909_activate_CAs.sh 
```  
Activate the CA:s (automaticlly enter PIN codes)
01/Activate CA:s run successfully - All is ok
02/Activate CA failed (%s/%s) - Could be problems accessing the application server, or token is not available  %s
03/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  910_deactivate_CAs.sh 
```  

01/Deactivate CA:s run successfully - All is ok
02/Deactivate CA failed (%s)  - Could be problems accessing the application server, or token is not available  %s
03/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  911_activate_VIP.sh 
```  
Activate the VIP
01/Activate VIP run successfully - All is ok
02/Activate VIP failed (%s)  - Manually try the ipconfig commands error:(%s)
03/Activate VIP failed since the VIP was already active - All is ok, if the VIP was supposed to be on this host already
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  912_deactivate_VIP.sh 
```  
Deactivate the VIP
9121/Deactivate VIP run successfully - All is ok
9122/Deactivate VIP failed (%s)  - Check manually with ifconfig -a and run ifconfig <if> down
9123/While deactivating, the VIP was already NOT active on this host - If the VIP was supposed to be at this host this event needs investigation 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  913_copy_ejbca_conf.sh 
```  

9131/Copy run successfully - All is ok
9132/Copy failed (%s)  - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  914_compare_master_slave_db.sh 
```  

9141/Data read successfully - All is ok
9142/Could not get table data - Check connection, username and password
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  915_remote_command_via_ssh.sh 
```  
Run command on another host with ssh ./915_remote_command_via_ssh.sh <host> <cmd> [sshtouser] [sshfromkey]
9151/Command executed successfully (%s) - All is ok
9152/Host not found (%s) - You have to specify a hostname to connect to
9153/Command not found (%s) - Specify a command to run
9154/Command not executed (%s) - Check connection, username and password
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  916_archive_access_manager_logs.sh 
```  
./916_archive_access_manager_logs.sh <-s|--screen>
Script used to move/archive Access Manager logfiles
9161/Files archived succefully (%s -> %s) - ok
9162/Failed to artchive files (%s -> %s) - test the underlying archive script manually
``` 
##  917_archive_file.sh 
```  
Script used to copy files to other hosts/directorys usage: ./917_archive_file.sh: file host <directory> <to-username> <from-ssh-key> \n(if you dont specify directory the file will end up in the user's homedirectory, \nif you dont specify to-username the same user as the one executing this script will be used, \nif from-ssh-key is not specified default key will be used)
9171/File archived succefully Locally (%s -> %s) - ok
9172/Failed to move file to Local archive (%s -> %s) - Check write premisions in archive dir
9173/Errornous input arguments - specify the right arguments (run ./917_archive_file.sh -h for help)
9174/Failed to get a filename from remote server - Check ssh connection setup to remote server
9175/File Failed to be Archived on Remote Server (%s) - Check ssh connection setup to remote server and write permissions in remote archive dir
9176/File Archived successfully to Remote Server (%s) - ok
9177/File moved successfully to intransit folder (%s -> %s) - ok
9178/Failed to create file in the intransit folder (%s) - Check permissions to write in the intransit folder
9179/Intransit dir not found - Create the dir with mkdir
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  918_server_alive.sh 
```  

9181/machine(%s) has called in as it's supposed to (lastcall: %s). - no action is needed
9182/machine(%s) has not called in within error limit (lastcall: %s) - two missed log messages, this needs attention
9183/machine(%s) has not called in within warn limit (lastcall: %s) - one missed log message, may be a glitch but should be checked
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  919_certpublisher_remotecommand.sh 
```  
Takes a certificate and runs a configurable command at a remote host
./919_certpublisher_remotecommand.sh -c|--cert <certfile-in-der-format> [-s|--screen] [-h|--help]
9191/Remote command ran successfully (%s) - 
9192/Remote command failed (%s) - 
9193/File input error, failed (%s) - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  920_restore_mysql_db_from_backup.sh 
```  
Restore db, syntax: ./920_restore_mysql_db_from_backup.sh <gzip:ed mysqldump-file>
9201/Failed to make backup of the pre-existing db prior to restore - run a manual backup with /home/han/service/code/syscheck/related-available/904_make_mysql_db_backup.sh -s to check if it works
9202/Restored the db from file (%s) - no action needed
9203/Failed to restore the db from the file (%s) consider to restore to previously db (%s) - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  921_copy_htmf_conf.sh 
```  

9211/ - 
9212/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  922-simple-database-replication-check.sh 
```  
Simple replication test
9221/Value replicated ok - ok, no action needed
9222/Value differs - databse not replicating (%s != %s), manually check the database with check master and check slave script
9223/No value from node2 (%s) - check connection manually, ping, telnet, mysql -h node2 -u dbadmin -p ... 
9224/No value from node1 (%s) - check connection manually, ping, telnet, mysql -h node1 -u dbadmin -p ... 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  923-rsync-to-remote-machine.sh 
```  
Script used to sync files with rsync to other hosts/directorys usage: ./923-rsync-to-remote-machine.sh: file host <directory> <to-username> <from-ssh-key> \n(if you dont specify directory the file will end up in the user's homedirectory, \nif you dont specify to-username the same user as the one executing this script will be used, \nif from-ssh-key is not specified default key will be used)
9231/file transfered ok - ok
9232/specify a filename as first argument to this script - filename not specified as argument
9233/specify a hostname as second argument to this script - Hostname not specified as argument
9234/rsync  transfer failed (%s) - check the error message and try to fix it
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  924-backup-this-machine-to-remote-machine.sh 
```  
Script used to rsync configured files/dirs to other hosts
9241/file transfered ok - ok
9242/Could not find transfer script - The underlying script for making the transfers SYSCHECK_HOME/related-enabled/923-rsync-to-remote-machine.sh dont exist, read docs for guide howto enable it
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  925_publish_crl_from_file.sh 
```  
Publish a CRL from file, ie you need to call this script with the file on disc
./925_publish_crl_from_file.sh: -c <file>|--crlfile=<file>

9251/Publish crl run successfully - ok
9252/no input file found - supply file as argument to this script
9253/Publish certificate failed, cant read file (%s) - verify the file is in place and with proper permissions before executing this script
./925_publish_crl_from_file.sh <-s|--screen>
``` 
##  926_local_htmf_copy_conf.sh 
```  
TEMP: > --help --<
``` 
##  927_create_crls.sh 
```  
Script to create the CRL:s from the CA:s options if needed
9271/Create CRL run successfully (%s) - No action needed
9272/Create CRL failed (%s) - Try manually to run this command or direct do 'cd  ; ./bin/ejbca.sh ca createcrl'
./927_create_crls.sh <-s|--screen>
``` 
##  928_check_dsm_backup.sh 
```  
./928_check_dsm_backup.sh 
92801/ - 
92802/ - 
``` 
##  929_filter_syscheck_messages.sh 
```  
Filter only some messages from a file
9291/Filter ok - no action needed
9292/Filter failed - try the commands manually
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  930_send_filtered_result_to_remote_machine.sh 
```  
Copy a file over to a central hub (might be used to expose some or all of syscheck results)
9301/Transfer ok (file:%s result:%s) - no action needed
9302/Could not transfer file:%s result:%s - try the transfer commands manually
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  931_mysql_backup_encrypt_send_to_remote_host.sh 
```  
TEMP: > --help --<

/ - 
/ - 
/ - 
/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
# Syscheck scripts
##  sc_01_diskusage.sh 
```  
sc_01_diskusage.sh Script that checks for to much hard-disc usage, limit is: %)
01/Diskusage ok (%s is %s percent used: Limit is %s percent)
02/Diskusage exceeded (%s is %s percent used: Limit is %s percent)
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  sc_02_ejbca.sh 
```  

01/EJBCA : %s - No action is needed
02/EJBCA : %s - Possible errors: \n"Error Virtual Memory is about to run out, currently free memory : X" - you need to add more virtual memory to application server/java process\n"Error Connecting to EJBCA Database" - The internal check of database failed, try to connect to database directly or restart database server\n"CA Token is disconnected" - activate token or maybe a restart of pcscd can help
03/EJBCA : health check tool failure - The tool to check if EJBCA is at good health is not configured properly
04/EJBCA : application server unavailable - Try manually to reach the URL:  manually %s
05/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  sc_03_memory-usage.sh 
```  
sc_03_memory-usage.sh Script that checks that there is enough free memory. The limit is configured in the script, limit:  mem: 80% / swap 50 %
01/Memory limit exceded (Memory is %s KB used: Limit is %s KB)
02/Memory limit ok (Memory is %s KB used: Limit is %s KB)
03/Swap limit exceded (Swap is %s KB used: Limit is %s KB)
03/Swap limit ok (Swap is %s KB used: Limit is %s KB)
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  sc_04_pcsc_readers.sh 
```  
./sc_04_pcsc_readers.sh checks for the defined number of PCSC readers is attached to the computer
01/Right number of attatched pcsc-readers (%s) - No action is needed
02/Wrong number of attached pcsc-readers (%s) - means that all reader is NOT working correctly as defined by pcscd
03/Perl module not installed(%s) - means that you've not installed the module used by this script 'Chipcard::PCSC' To install perl-module: cpan -i Chipcard::PCSC or get from http://search.cpan.org
``` 
##  sc_05_pcscd.sh 
```  
./sc_05_pcscd.sh check that pcscd is running
01/pcscd is running - No action is needed
02/pcscd is NOT running - pcscd needs to be restarted, if it dont start, run it with: /path/to/pcscd --foreground --debug
``` 
##  sc_06_raid_check.sh 
```  
./sc_06_raid_check.sh check the raid discs
01/PhysicalDiscs is OK %s - No action is needed
02/PhysicalDiscs is not OK %s - Change disc as soon as possible
03/LogicalDiscs is OK %s - No action is needed
04/LogicalDiscs is rebuilding %s - check back in a while to see this error goes away, else you need to investigate
05/LogicalDiscs has some other error %s - you need to investigate this error ASAP
06/HPTOOL not installed at: %s - the hptool is not installed, install the tool to get working reports
``` 
##  sc_07_syslog.sh 
```  
./sc_07_syslog.sh check to see that syslog is running and delivers messages ok
01/loggmessage did not come throu SYSLOG - syslog is running but the messages dont comes throu to local file, restart and/or check config file
02/no pid file found and syslog not found in ps-table - not even the pid-file os syslog was found, try a restart
03/syslog is not running - the process was not found amoung running processes
``` 
##  sc_08_crl_from_webserver.sh 
```  
./sc_08_crl_from_webserver.sh check the status of CRL, both that you can get it and that its valid
01/ CRL %s creation have failed - either the server is not up, it dont produce CRL:s, it dont validate or the CRL is old 
02/ CRL %s is updated - No action is needed
03/Unable to get CRL %s from webserver  - Check manually to get CRL from webserver
04/When getting CRL %s the size of file is 0 - Check discusage, try manually to get CRL
05/Configuration error: %s - Check config
``` 
##  sc_09_firewall.sh 
```  
./sc_09_firewall.sh Check the firewall is configured and running
01/Cant get status from iptables. - check manually with iptables -L -n or maybe restart the firewall with /etc/init.d/firewall start
02/Firewall doesn't seem to have the correct ruleset configured. - Maybe something went wrong loading the firewall ruleset, because some very basic rules are'nt present 
03/Firewall is up and configured properly - No action is needed
``` 
##  sc_12_mysql.sh 
```  
./sc_12_mysql.sh Mysql server checks
01/mysql is running - No action is needed
02/mysql is NOT running - mysql is not running, try /etc/init.d/mysql stop, wait, /etc/init.d/mysql start
``` 
##  sc_14_sw_raid.sh 
```  
./sc_14_sw_raid.sh: 
01 - 
02 - 
03 - 
``` 
##  sc_15_apache.sh 
```  
./sc_15_apache.sh Check apache process is up and running
01/Apache webserver is running - server is running and serving web pages
02/Apache webserver is not running - check apache error.log, it is not running
``` 
##  sc_16_ldap.sh 
```  
./sc_16_ldap.sh Checks the ldap server to make sure it's running
01/LDAP directory server is running - all ok
02/LDAP directory server is not running - check you ldap server logs
``` 
##  sc_17_ntp.sh 
```  
./sc_17_ntp.sh Check that ntp i running and is insync
01/ntpd is in sync with server: %s - all ok
02/ntpd is NOT running. - Start it with /etc/init.d/xntpd start
03/cant check ntp sync to: %s - check the configuration or restart ntpd
04/ntpd can NOT synchronize to servers LOCAL(0) mode  - Check network connectivity and configuration of ntp
05/ntp server not sent in input - Check your syscheck config for ntp
``` 
##  sc_18_sqlselect.sh 
```  
./sc_18_sqlselect.sh Mysql select keepalive
01/mysql is running and answering - No action is needed
02/mysql is NOT answering to select statement check - mysql is not running, try /etc/init.d/mysql stop, wait, /etc/init.d/mysql start
``` 
##  sc_19_alive.sh 
```  
Sends alive messages to a central syscheck server run this script either along with the rest of the syscheck scripts or in a crontab (then you can run me more often...)
01/Operating system just started - Message is sent when the server's operating system is started
02/Operating system is shutting down - Message is sent when the server's operating system is shutdown
03/I'm alive - Message is sent to make sure central server know's this server is alive
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  sc_20_errors_ejbcalog.sh 
```  
./sc_20_errors_ejbcalog.sh checks fo new errors in the server log for ejbca
01/No new errors in ejbca server log - No action is needed
02/New error in log: %s - There was new ERRORS in the LOG file, please attend to them
03/Cant find the specified ejbca log %s - maybe you havn't configured the script yet?
``` 
##  sc_22_boks_replica.sh 
```  
./sc_22_boks_replica.sh BoKS Replica checks
01/No action is needed - all boks processes are running
02/All BoKS replica processes IS NOT running %s - Not all boks processes are running
``` 
##  sc_23_rsa_axm.sh 
```  
./sc_23_rsa_axm.sh Checks the RSA Access Manager server to make sure it's running
01/RSA Access Manager is running - all ok
02/At least one service is not running (%s)  - check the rsa access manager server logs
``` 
##  sc_27_dss.sh 
```  
./sc_27_dss.sh checks the dss server
01/Document SignServer is active - No action needed
02/Document SignServer is running at ONLY ONE NODE - Check the failing node asap
03/Document SignServer is NOT active - resolve this issue asap
04/Document SignServer is not installed at this host - maybe you've configured wrong scripts or not yet installed signserver
``` 
##  sc_28_check_vip.sh 
```  
./sc_28_check_vip.sh Checks which node has the VIP address
01/Node 1 has the VIP - No action needed
02/Node 2 has the VIP - No action needed
03/Both nodes has the VIP - Resolve this issue asap
04/None of the nodes has the VIP - Resolve this issue asap
``` 
##  sc_29_signserver.sh 
```  
sc_29_signserver.sh Script that connects to the signserver health check servlet to check the status of the signserver application. The health check servlet checks JVM memory, database connection and HSM connection.
01/SIGNSERVER : %s - No action is needed
02/SIGNSERVER : %s - Possible errors: \n"Error Virtual Memory is about to run out, currently free memory : X" - you need to add more virtual memory to application server/java process\n"Error Connecting to SIGNSERVER Database" - The internal check of database failed, try to connect to database directly or restart database server\n"CA Token is disconnected" - activate token or maybe a restart of pcscd can help
03/SIGNSERVER : Application Server is unavailable - The server is non-responding, restart application-server (jboss) and/or check server log to find the fault
to run with output directed to screen: add a '-s' or '--screen'
``` 
##  sc_30_check_running_procs.sh 
```  
``` 
##  sc_31_hp_health.sh 
```  
./sc_31_hp_health.sh Check the HP Server health
01/Sensor of %s is OK %s - No action is needed
02/Temp sensor %s is NOT OK %s - Run manual test with hpasmcli
03/FAN sensor %s is NOT OK %s - Run manual test with hpasmcli
04/Tool not found: %s  - Install or set path
``` 
##  sc_32_check_db_sync.sh 
```  
./sc_32_check_db_sync.sh Check if DB in sync
01/DB in sync - and updating databases
02/DB not in sync, date of CertificateData diff betwin nodes: - check error.log, probebly needing manual sync, se manual
``` 
##  sc_33_healthchecker.sh 
```  

01/Healtcheck of app: %s ok - No action is needed
02/Healtcheck of app: %s NOT ok error message: %s - Check errormessage and log-file
03/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
