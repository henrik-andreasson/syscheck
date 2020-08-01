
#  ﻿Syscheck backup management

## Changes

|Version   |Author             |Date        |Comment                      |
|----------|.------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2010-10-12 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |


## Introduction

Syscheck has the possibility to backup the database to a file in several different locations, these can be used to save hourly, daily, monthly and yearly backups in different locations and save those in different amount of times.
Default values of saving the different backups can be adjusted in the config file for “clean old backups script” (<syscheck>/config/908.config)



## Syscheck backup management


Syscheck has the possibility to backup the database to a file in several different locations, these can be used to save hourly, daily, monthly and yearly backups in different locations and save those in different amount of times.
Default values of saving the different backups can be adjusted in the config file for “clean old backups script” (<syscheck>/config/908.config)


### Add the different backups to crontab


```
$ sudo crontab -e
# hourly backups at 10 mins past every hour
10 * * * * /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh

# daily backups 03:10
10 3 * * * /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh --daily

# weekly backups on sundays 03:20
20 3 * * 7 /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh --weekly

# monthly backups on first day of month 3:30
30 3 1 * * /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh --monthly

# yearly backup on first of januari 3:40
40 3 1 1 * /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh --yearly
```

### Make new backup dirs

    # mkdir -p /backup/mysql/default
    # mkdir -p /backup/mysql/daily
    # mkdir -p /backup/mysql/weekly
    # mkdir -p /backup/mysql/monthly
    # mkdir -p /backup/mysql/yearly


### run backup

    [root@ca1 related-enabled]# /opt/syscheck/related-enabled/904_make_mysql_db_backup.sh -s
    I-90401-LAB 20200519 15:11:35 ca1.lab.certificateservices.se: INFO - mysqlbackup Backed up db ok file: /backup/mysql//default/mysql-2020-05-19_15.11.33.gz time to complete(sec): 2 filesize(b
    I-90401-LAB 20200519 15:11:36 ca1.lab.certificateservices.se: INFO - mysqlbackup Backed up db ok file: /backup/mysql//default/ejbca-2020-05-19_15.11.35.gz time to complete(sec): 1 filesize(b

### Enable the clean old backups script

        cd /opt/syscheck/related-enabled/
        syscheck/related-enabled#  ln -s ../related-available/908_clean_old_backups.sh .

### Verify the config file

        $ sudo vi /opt/syscheck/config/908.config

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

### Add clean old backups to crontab

$ sudo crontab -e
```
# at 4:10 am each day clean old backups
10 4 * * * /opt/syscheck/related-enabled/908_clean_old_backups.sh
```
