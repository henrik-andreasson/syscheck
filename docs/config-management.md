# Syscheck config management


## Changes

|Version   |Author             |Date        |Comment                      |
|----------|.------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |




## Configuration Management


### ansible

syscheck is configurable with ansible.
for more info see the misc/ansible directory.

### manually


Each script has a config under config/


### syscheck-scripts


Enable scripts by making a soft link (ln -s) in "scripts-enabled" to "scripts-available" where all
scripts reside.

enable one script:

        # cd scripts-enabled
        # ln -s ../scripts-available/sc_01_disk_usage.sh .

enable all script:

        # cd scripts-enabled
        # ln -s ../scripts-available/* .

make a test-run by doing:

        ./syscheck.sh -s

 if it works out good (All is OK), then go ahead and try

        ./sysheck.sh

then check your syslog-logs


### Related scripts


Related scripts are other scripts not intended to be run every x min like the core syscheck script but maybe by cron every now and then, maybe by a admin manually to perform a maintenance task.

To list the available scripts look in related-available

        ls  related-available

To find out more about a certain script run with "-h" as argument:

        related-available/900_export_cert.sh -h

To enable a script:

        cd related-enabled
        ln -s ../related-available/900_export_cert.sh .

Why should you only use related scripts from "related-enabled"?
 - Those are configured and tested on this particular installation, so do make it a habit to run stuff only from "related-enabled"
