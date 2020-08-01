# Syscheck getting started


## Changes

|Version   |Author             |Date        |Comment                      |
|----------|-------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |



### Activate selected related scripts


Make the soft links in the related-enabled directory.

        han@ca-nod1:/opt/syscheck/related-enabled> ln -s ../related-available/904_make_mysql_db_backup.sh .

Verify there is soft links and no copied files in enabled!


        username@smartcard20-node1:/opt/syscheck/syscheck/related-enabled> ls -al
        lrwxrwxrwx  1 root root   48 2010-06-04 14:25 904_make_mysql_db_backup.sh -> ../related-available/904_make_mysql_db_backup.sh

Also check the config for each script you activate, there may or may not be anything to config, but let's check.

        username@smartcard20-node1:/opt/syscheck/> sudo vi config/900.conf
        username@smartcard20-node1:/opt/syscheck/> sudo vi config/904.conf
        [...]

### Mysql database configuration


Config database parameters

Make sure settings are correct in the syscheck config/common.conf

        DB_NAME=ejbca
        DB_USER=ejbca
        DB_PASSWORD="sdfiuh3wrnj"
        MYSQLROOT_PASSWORD="UiywfeW23"
