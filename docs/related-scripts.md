# Syscheck version 2.0 
Documentation generated: Sat  1 Aug 21:53:45 CEST 2020
# Syscheck related scripts 
##  900_export_cert.sh 
```  

900 - Export certificate file
--------------------------------------

Export certificate and archive them, ./900_export_cert.sh <certfile>

Error code / description - What to do

9001 / Export certificate run successfully - no actions needed
9002 / Export certificate failed (%s)  - Unexpected, run the script with sh -x to check
9003 / Export certificate failed, script called without file - call this script with a PEM encoded certficate as arg1

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  901_export_revocation.sh 
```  

901 - Export CRL file
--------------------------------------

Export CRL:s with a script ./901_export_revocation.sh <DER-encoded CERT>

Error code / description - What to do

9011 / Export revocation run successfully - no actions needed
9012 / Export revocation failed (%s)  - check manually with sh -x ./901_export_revocation.sh <file>
9013 / Export revocation failed, script called without file - call this script with a DER encoded CERT as arg1

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  902_export_crl.sh 
```  

902 - Export revoked certificate file
--------------------------------------

Export CRL ./902_export_crl.sh: <DER encoded CRL>

Error code / description - What to do

9021 / Export CRL run successfully - no action needed
9022 / Export CRL failed (%s)  - check manual with sh -x ./902_export_crl.sh <crl>
9023 / Export CRL failed, script called without file - arg1 must be a DER encoded crl!

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  903_make_hsm_backup.sh 
```  
``` 
##  904_make_mysql_db_backup.sh 
```  

904 - Mysql backup tool
--------------------------------------

syntax: ./904_make_mysql_db_backup.sh [-x|--default|-d|--daily|-w|--weekly|-m|--monthly|-y|--yearly] [-s|--screen] [-b|--batch] 

 -x and --default will put the backupfile in directory defined in config as SUBDIR_DEFAULT
 -d or --daily will put the backup in the directory defined in config as SUBDIR_DAILY
 -w or --weekly will put the backup in the directory defined in config as SUBDIR_WEEKLY
 -m or --monthly will put the backup in the directory defined in config as SUBDIR_MONTHLY
 -y or --yearly will put the backup in the directory defined in config as SUBDIR_YEARLY
 OBSERVE that it's up to the admin to run this script with cron or alike at these intervals, so run this script once a day with --daily to get only one daily backup and so on
 -b or --batch will echo the resulting filename for processing by other scripts

Error code / description - What to do

9041 / Backed up db ok file: %s time to complete(sec): %s filesize(bytes): %s - no action needed
9042 / Could not create the backup file: %s time to complete(sec): %s filesize(bytes): %s errormess: %s - Run manually also check disk space and owner of directory to write backup to
9043 / Backup failed, backupdir not found (%s) - check the configfile and make sure the configured directory exist

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  905_publish_crl.sh 
```  

905 - CRL publish
--------------------------------------

Script to publish the CRL:s from the CA, supports local and remote publishing by SSH

Error code / description - What to do

9051 / Publish CRL run successfully (%s) %s - No action needed
9052 / Publish to remote host failed crl:(%s) host:(%s) - Try manually to run this command and setup ssh-keys and check username
9053 / Publish CRL failed, can't copy crl to destination %s/%s - Check permissions for the path:s

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  906_ssh-copy-to-remote-machine.sh 
```  

906 - SCP support tool
--------------------------------------

Script used to copy files to other hosts/directorys usage: ./906_ssh-copy-to-remote-machine.sh: file host <directory> <to-username> <from-ssh-key> 
(if you dont specify directory the file will end up in the user's homedirectory, 
if you dont specify to-username the same user as the one executing this script will be used, 
if from-ssh-key is not specified default key will be used)

Error code / description - What to do

01 / file transfered ok - ok
02 / specify a filename as first argument to this script - filename not specified as argument
03 / specify a hostname as second argument to this script - Hostname not specified as argument

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  907_make_mysql_db_backup_and_transfer_to_remote_mashine.sh 
```  

907 - Mariadb backup and transfer to remote host
--------------------------------------

Script used to take backup of the sql database, compress and send to a separate server. call with -x|--default for puting the backupfile in the SUBDIR_DEFAULT ; -d|--daily to make daily backup end up in SUBDIR_DAILY; with -w|--weekly to make daily backup end up in SUBDIR_WEEKLY; -m|--monthly to make daily backup end up in SUBDIR_MONTHLY ; -y|--yearly to make daily backup end up in SUBDIR_YEARLY;

Error code / description - What to do

9071 / Backup and transfer was ok. - Ok
9072 / Could not get the backup from MySQL (%s)  - Could not make a backup.
9073 / Could not send the backup, maybe connection problem or problem logging in (%s)  - Could not send the backup.

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  908_clean_old_backups.sh 
```  

908 - Clean old backup files
--------------------------------------

Clean old backups, so the disk dont fill up

Error code / description - What to do

9081 / Clean backupfiles run successfully - All is ok
9082 / Clean backupfiles failed (%s)  - Unpredicted error while deleting file %s
9083 / Clean backupfile file did not exist (%s)  - Maybe the files has been already removed or there was no files from start
9084 / Datestring command did NOT return a valid string - try to run source lib/libsyscheck.sh ; x-days-ago-datestr 3 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  909_activate_CAs.sh 
```  

909 - Activate CA HSM
--------------------------------------

Activate the CA:s (automaticlly enter PIN codes)

Error code / description - What to do

9091 / Activate CA:s run successfully - All is ok
9092 / Activate CA failed (%s/%s) - Could be problems accessing the application server, or token is not available  %s

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  910_deactivate_CAs.sh 
```  

910 - Deactivate CA HSM
--------------------------------------

Deactivate the CA:s

Error code / description - What to do

9101 / Deactivate CA:s run successfully - All is ok
9102 / Deactivate CA failed (%s)  - Could be problems accessing the application server, or token is not available  %s

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  911_activate_VIP.sh 
```  

911 - Activate VIP
--------------------------------------

Activate the VIP

Error code / description - What to do

9111 / Activate VIP run successfully - All is ok
9112 / Activate VIP failed (%s)  - Manually try the ipconfig commands error:(%s)
9113 / Activate VIP failed since the VIP was already active - All is ok, if the VIP was supposed to be on this host already
9114 / Activate VIP failed since the VIP was already active on another node - Check the other node to see if that node has the VIP, else start invesigating who has you IP ...

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  912_deactivate_VIP.sh 
```  

912 - Deactivate VIP
--------------------------------------

Deactivate the VIP

Error code / description - What to do

9121 / Deactivate VIP run successfully - All is ok
9122 / Deactivate VIP failed (%s)  - Check manually with ifconfig -a and run ifconfig <if> down
9123 / While deactivating, the VIP was already NOT active on this host - If the VIP was supposed to be at this host this event needs investigation 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  913_copy_ejbca_conf.sh 
```  

913 - Copy config to NODE2
--------------------------------------

Copy EJBCA conf/, p12/ and syscheck

Error code / description - What to do

9131 / Copy run successfully - Check config and keys to remote hosts
9132 / Copy failed (%s)  - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  914_compare_master_slave_db.sh 
```  

914 - Deactivate VIP
--------------------------------------

Compare tables on master and slave database

Error code / description - What to do

9141 / Data read successfully - All is ok
9142 / Could not get table data - Check connection, username and password

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  915_remote_command_via_ssh.sh 
```  

915 - SSH remote command tool
--------------------------------------

Run command on another host with ssh ./915_remote_command_via_ssh.sh <host> <cmd> [sshtouser] [sshfromkey]

Error code / description - What to do

9151 / Command executed successfully (%s) - All is ok
9152 / Host not found (%s) - You have to specify a hostname to connect to
9153 / Command not found (%s) - Specify a command to run
9154 / Command not executed (%s) - Check connection, username and password

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  916_archive_access_manager_logs.sh 
```  

916 - Archive log files
--------------------------------------

Script used to move/archive logfiles

Error code / description - What to do

9161 / Files archived succefully (%s -> %s) - ok
9162 / Failed to artchive files (%s -> %s) - test the underlying archive script manually

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  917_archive_file.sh 
```  

917 - Archive files
--------------------------------------

Script used to copy files to other hosts/directorys usage: ./917_archive_file.sh: file host <directory> <to-username> <from-ssh-key> 
(if you dont specify directory the file will end up in the user's homedirectory, 
if you dont specify to-username the same user as the one executing this script will be used, 
if from-ssh-key is not specified default key will be used)

Error code / description - What to do

9171 / File archived succefully Locally (%s -> %s) - ok
9172 / Failed to move file to Local archive (%s -> %s) - Check write premisions in archive dir
9173 / Errornous input arguments - specify the right arguments (run ./917_archive_file.sh -h for help)
9174 / Failed to get a filename from remote server - Check ssh connection setup to remote server
9175 / File Failed to be Archived on Remote Server (%s) - Check ssh connection setup to remote server and write permissions in remote archive dir
9176 / File Archived successfully to Remote Server (%s) - ok
9177 / File moved successfully to intransit folder (%s -> %s) - ok
9178 / Failed to create file in the intransit folder (%s) - Check permissions to write in the intransit folder
9179 / Intransit dir not found - Create the dir with mkdir

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  918_server_alive.sh 
```  

918 - Passive server monitoring
--------------------------------------

Passive server monitoring, all server that should be monitored should be listed in 918.conf and run sc_19.sh every x:th minute, example: if you run syscheck every 10:th minute set warn to 15(missed one log and some margin) and error to 25(missed one log and some margin)

Error code / description - What to do

9181 / machine(%s) has called in as it's supposed to (lastcall: %s). - no action is needed
9182 / machine(%s) has not called in within error limit (lastcall: %s) - two missed log messages, this needs attention
9183 / machine(%s) has not called in within warn limit (lastcall: %s) - one missed log message, may be a glitch but should be checked

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  919_certpublisher_remotecommand.sh 
```  

919 - Certificate publishing remote host
--------------------------------------

Takes a certificate and runs a configurable command at a remote host

Error code / description - What to do

9191 / Remote command ran successfully (%s) - no action needed
9192 / Remote command failed (%s) - try to run the command manually
9193 / File input error, failed (%s) - input file not set ok

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  920_restore_mysql_db_from_backup.sh 
```  

920 - DB Restore tool
--------------------------------------

Restore db, syntax: ./920_restore_mysql_db_from_backup.sh <gzip:ed mysqldump-file>

Error code / description - What to do

9201 / Failed to make backup of the pre-existing db prior to restore - run a manual backup with arg -s to check errors
9202 / Restored the db from file (%s) - no action needed
9203 / Failed to restore the db from the file (%s) consider to restore to previously db (%s) - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  921_copy_htmf_conf.sh 
```  

921 - Copy HTMF config
--------------------------------------

Copy HTMF config

Error code / description - What to do

9211 / Interactive script to copy htmf / ejbca config - files are added in config file

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  922-simple-database-replication-check.sh 
```  

922 - Simple db replication tool
--------------------------------------

Simple replication test

Error code / description - What to do

9221 / Value replicated ok - ok, no action needed
9222 / Value differs - databse not replicating (%s != %s), manually check the database with check master and check slave script
9223 / No value from node2 (%s) - check connection manually, ping, telnet, mysql -h node2 -u dbadmin -p ... 
9224 / No value from node1 (%s) - check connection manually, ping, telnet, mysql -h node1 -u dbadmin -p ... 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  923-rsync-to-remote-machine.sh 
```  

923 - Sync files to remote host
--------------------------------------

Script used to sync files with rsync to other hosts/directorys usage: ./923-rsync-to-remote-machine.sh: file host <directory> <to-username> <from-ssh-key> 
(if you dont specify directory the file will end up in the user's homedirectory, 
if you dont specify to-username the same user as the one executing this script will be used, 
if from-ssh-key is not specified default key will be used)

Error code / description - What to do

9231 / file transfered ok - ok
9232 / specify a filename as first argument to this script - filename not specified as argument
9233 / specify a hostname as second argument to this script - Hostname not specified as argument
9234 / rsync  transfer failed (%s) - check the error message and try to fix it

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  924-backup-this-machine-to-remote-machine.sh 
```  

924 - Sync several directories and files to remote host
--------------------------------------

Script used to rsync configured files/dirs to other hosts

Error code / description - What to do

9241 / file transfered ok - ok
9242 / Could not find transfer script - The underlying script for making the transfers SYSCHECK_HOME/related-enabled/923-rsync-to-remote-machine.sh dont exist, read docs for guide howto enable it
9243 / Failed to sync files (%s) - check the config and run SYSCHECK_HOME/related-enabled/923-rsync-to-remote-machine.sh manually with the same options

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  925_publish_crl_from_file.sh 
```  

925 - Publish a CRL from a file
--------------------------------------

Publish a CRL from file, ie you need to call this script with the file on disc
./925_publish_crl_from_file.sh: -c <file>|--crlfile=<file>

Error code / description - What to do

9251 / Publish crl run successfully - ok
9252 / no input file found - supply file as argument to this script
9253 / Publish certificate failed, cant read file (%s) - verify the file is in place and with proper permissions before executing this script

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  926_local_htmf_copy_conf.sh 
```  

926 - Locally copy config and keystores
--------------------------------------

Copy all config/keystore files to /tmp/bckup_htmf_conf before system upgrade

Error code / description - What to do

9261 / File copied ok(%s) - no action needed
9262 / Failed to copy file (%s) - check permissions and paths
9263 / Failed to create backup dir (%s) - check permissions and paths

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  927_create_crls.sh 
```  

927 - Trigger the Creation of CRLs in EJBCA
--------------------------------------

Script to create the CRL:s from the CA:s options if needed

Error code / description - What to do

9271 / Create CRL run successfully (%s) - No action needed
9272 / Create CRL failed (%s) - Try manually to run this command or direct do 'cd /opt/ejbca ; ./bin/ejbca.sh ca createcrl'
9273 /  - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  928_check_dsm_backup.sh 
```  

928 - DSM Backup
--------------------------------------

Check if DSM Backup working

Error code / description - What to do

9281 / DSM Backup ok (file:%s result:%s) - no action needed
9282 / DSM Backup failed file:%s result:%s - Check DSM tool for troubleshooting
9283 /  - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  929_filter_syscheck_messages.sh 
```  

929 - Filter messages from syscheck
--------------------------------------

Filter only some messages from a file

Error code / description - What to do

9291 / Filter ok - no action needed
9292 / Filter failed - try the commands manually

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  930_send_filtered_result_to_remote_machine.sh 
```  

930 - Send files to remote host
--------------------------------------

Copy a file over to a central hub (might be used to expose some or all of syscheck results)

Error code / description - What to do

9301 / Transfer ok (file:%s result:%s) - no action needed
9302 / Could not transfer file:%s result:%s - try the transfer commands manually
9303 /  - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  931_mysql_backup_encrypt_send_to_remote_host.sh 
```  

931 - Backup, encrypt backup and send to remote hosts
--------------------------------------

Script used to take backup of the sql database, compress and send to a separate server. call with -x|--default for puting the backupfile in the SUBDIR_DEFAULT ; -d|--daily to make daily backup end up in SUBDIR_DAILY; with -w|--weekly to make daily backup end up in SUBDIR_WEEKLY; -m|--monthly to make daily backup end up in SUBDIR_MONTHLY ; -y|--yearly to make daily backup end up in SUBDIR_YEARLY;

Error code / description - What to do

9311 / Backup and transfer was ok. (%s) - Ok
9312 / Could not get the backup from MySQL (%s)  - Could not make a backup.
9313 / Compression of the backup failed (%s)  - Could not compress the backup.

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  932_send_result_as_message.sh 
```  

932 - Send result as a message
--------------------------------------

Send syscheck result as a message over to a central hub 

Error code / description - What to do

9321 / Transfer ok (command:%s result:%s) - no action needed
9322 / Could not send message: %s result:%s - try the transfer commands manually

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  933_select_from_database.sh 
```  

933 - Select from db for info
--------------------------------------

Get info from db

Error code / description - What to do

9331 / Selected info from DB (command:%s) - no action needed
9332 / Could not get info from db: %s - try the commands manually

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  934_check_validity_of_installed_certs.sh 
```  

934 - Certificate validity check
--------------------------------------

Monitor certificates validity

Error code / description - What to do

9341 / File: %s subj: %s days until expiry: %s - no action needed
9342 / File: %s subj: %s days until expiry: %s - schedule replacement soon
9343 / File: %s subj: %s days until expiry: %s - Certificate indicent is close

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  935_mysql_console_as_root.sh 
```  
``` 
##  936_mysql_console_as_db_user.sh 
```  
cant open langfile (/home/han/devel/syscheck/lang/936.english)
``` 
##  937_delete_old_CRLData.sh 
```  

937 - 
--------------------------------------

Delete records from crldata, keep default 20 record in crltable, see config file 817.conf

Error code / description - What to do

9371 / No Value in ROW_SAVE - Check scripts config file 
9372 / The value is less then 5 - Check  scripts config file 
9373 / Can't make a backup - Check permisson and dbuser
9374 / Can't get uniq issuerDN from CRLData  - Check database and logs 
9375 / Can't copy CRLData to db crldata.CRLDatalog for each issuerDN  - Check database and logs 
9376 / Cant delete record from CRLData for uniq issuerDN - Check database and logs 
9377 / Delete to crlnumber  - Delet ok 
9378 / Can't Optimize table  - Check vendor of database, and adjust command 
9379 / Can't zip dbbackup  - Check permission  
93710 / Delete to crlnumber, restart jboss and check sync  - Delete ok 

to run with output directed to screen: add a '-s' or '--screen'

``` 
