Syscheck backup management
==========================

Henrik Andreasson
kinneh@users.sourceforge.net 
2010-10-12

Introduction
=============

Syscheck has the posibillity to backup the database to a file in several different locations, these can be used to save hourly, daily, monthly and yearly backups in different locations and save those in different amount of times.
Default values of saving the different backups can be adjusted in the config file for “clean old backups script” (<syscheck>/config/908.config) 




Add the different backups to crontab
====================================

```
$ sudo crontab -e
# hourly backups at 10 mins past every hour
10 * * * * /usr/local/certificate-services/syscheck/related-enabled/904_make_mysql_db_backup.sh

# daily backups 03:10
10 3 * * * /usr/local/certificate-services/syscheck/related-enabled/904_make_mysql_db_backup.sh --daily

# weekly backups on sundays 03:20
20 3 * * 7 /usr/local/certificate-services/syscheck/related-enabled/904_make_mysql_db_backup.sh --weekly

# monthly backups on first day of month 3:30
30 3 1 * * /usr/local/certificate-services/syscheck/related-enabled/904_make_mysql_db_backup.sh --monthly

# yearly backup on first of januari 3:40
40 3 1 1 * /usr/local/certificate-services/syscheck/related-enabled/904_make_mysql_db_backup.sh --yearly
```

Make new backup dirs
-------------------------
username@smartcard20-node1:/usr/local> sudo mkdir /backup/mysql/default
username@smartcard20-node1:/usr/local> sudo mkdir /backup/mysql/daily
username@smartcard20-node1:/usr/local> sudo mkdir /backup/mysql/weekly
username@smartcard20-node1:/usr/local> sudo mkdir /backup/mysql/monthly
username@smartcard20-node1:/usr/local> sudo mkdir /backup/mysql/yearly

Enable the clean old backups script
------------------------------------

        cd /usr/local/certificate-services/syscheck/related-enabled/
        smartcard20:/usr/local/certificate-services/syscheck/related-enabled# sudo ln -s ../related-available/908_clean_old_backups.sh .

Verify the config file
-------------------------

        $ sudo vi /usr/local/certificate-services/syscheck/config/908.config

```
### config for 908_clean_old_backups.sh

KEEPDAYS[0]=10;
BACKUPDIR[0]="/backup/mysql/default/";
DATESTR[0]=`${SYSCHECK_HOME}/lib/x-days-ago-datestring.pl ${KEEPDAYS[0]}  2>/dev/null`;
FILENAME[0]="${BACKUPDIR[0]}/ejbcabackup-${DATESTR[0]}*"

KEEPDAYS[1]=30;
BACKUPDIR[1]="/backup/mysql/daily";
DATESTR[1]=`${SYSCHECK_HOME}/lib/x-days-ago-datestring.pl ${KEEPDAYS[0]}  2>/dev/null`;
FILENAME[1]="${BACKUPDIR[0]}/ejbcabackup-${DATESTR[0]}*"


KEEPDAYS[2]=90;
BACKUPDIR[2]="/backup/mysql/weekly/";
DATESTR[2]=`${SYSCHECK_HOME}/lib/x-days-ago-datestring.pl ${KEEPDAYS[1]}  2>/dev/null`;
FILENAME[2]="${BACKUPDIR[1]}/ejbcabackup-${DATESTR[1]}*"

KEEPDAYS[3]=370;
BACKUPDIR[3]="/backup/mysql/monthly/";
DATESTR[3]=`${SYSCHECK_HOME}/lib/x-days-ago-datestring.pl ${KEEPDAYS[1]}  2>/dev/null`;
FILENAME[3]="${BACKUPDIR[1]}/ejbcabackup-${DATESTR[1]}*"
```

Add clean old backups to crontab
----------------------------------

        $ sudo crontab -e
        # at 4:10 am each day clean old backups
        10 4 * * * /usr/local/certificate-services/syscheck/related-enabled/908_clean_old_backups.sh

