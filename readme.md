README for Syscheck
=====================


DESCRIPTION
---------------------------
The system check scripts controls the overall health of the system
and sends it's result to syslog for further processing

The main script is 'syscheck.sh' that performs all subsystem checks with
a filename starting with "sc_" in the scripts-enebled directory.

The script 'syscheck.sh -s' performs the same checks but echoes the output to the terminal.

All message are described in lang/syscheck.<lang>
errorcodes are defined in the local sc_ files

Authors
------------

Maintainter is Henrik Andreasson github@han.pp.se


[![CircleCI](https://circleci.com/gh/henrik-andreasson/syscheck.svg?style=svg)](https://circleci.com/gh/henrik-andreasson/syscheck)

INFO
---------------------------
Homepage:	(http://github.com/henrik-andreasson/syscheck)

Patches are welcome via email or pull requests, please state if you want your name in the contributors list.

License is GPL 2.

INSTALLATION
==========================

manually
---------
untar the distribution in a suitable directory (default /usr/local/syscheck).
Then edit config/common.conf config/xxx.conf (where xxx is ther scriptid) to fit your needs.

packaged (rpm and deb)
----------------------

Download the rpm/deb from github

rpm -Uvh syscheck-<version>.rpm

dpkg -i syscheck-<version>.deb



Configuration Management
=========================

ansible
----------------
syscheck is configurable with ansible.
for more info see the misc/ansible directory.

manually
----------

Each script has a config under config/


syscheck-scripts
-------------------

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


Related scripts
---------------------------

Related scripts are other scripts not intended to be run every x min like the core syscheck script but maybe by cron every now and then, maybe by a admin manually to perform a maintenece task.

To list the available scripts look in related-available

        ls  related-available

To find out more about a certain script run with "-h" as argument:

        related-available/900_export_cert.sh -h

To enable a script:

        cd related-enabled
        ln -s ../related-available/900_export_cert.sh .

Why should you only use related scripts from "related-enabled"?
 - Those are configured and tested on this particular installation, so do make it a habit to run stuff only from "related-enabled"

Output
=====================

File
------------

syscheck can write to a local file, this can be collected by filebeat to be managed in ELK.

Syslog
------------

Sycheck will send messages to a local syslog server, that server can of course route the messages to a central syslog.

[Rsyslog](http://www.rsyslog.com/doc-rsyslog_secure_tls.html) has native support for SSL, use this to make sure the messages are kept confidential during transport.

You still can use any syslog implementation.


Database-replication
---------------------------
Setup and status control for replication of mysql(master-slave setup)
Read database_replication_and_failover.pdf for more info.


HELP
---------------------------

Each script within syscheck shall implement "-h" and "--help" to give syntax help and a decription of errorcodes:

Run: ./scripts-available/sc_nn_foo.sh --help
Eg: ./scripts-available/sc_04_pcsc_readers.sh --help


Message format
==========================

Info - JSON Syscheck Sample output
---------------------------

```
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "01", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.379420331", "LONGLEVEL":  "INFO", "DESCRIPTION": "Diskusage ok ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/", "EXTRAARG2":   "33", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-01-I-01-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Diskusage ok (/ is 33 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "02", "LEVEL": "I", "ERRNO": "01", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.423384892", "LONGLEVEL":  "INFO", "DESCRIPTION": "Diskusage ok ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/backup", "EXTRAARG2":   "1", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-02-I-01-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Diskusage ok (/backup is 1 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "03", "LEVEL": "I", "ERRNO": "01", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.462480498", "LONGLEVEL":  "INFO", "DESCRIPTION": "Diskusage ok ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/var/lib", "EXTRAARG2":   "11", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-03-I-01-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Diskusage ok (/var/lib is 11 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "04", "LEVEL": "I", "ERRNO": "01", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.487453851", "LONGLEVEL":  "INFO", "DESCRIPTION": "Diskusage ok ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/var/log", "EXTRAARG2":   "1", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-04-I-01-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Diskusage ok (/var/log is 1 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "02", "SCRIPTINDEX": "01", "LEVEL": "E", "ERRNO": "04", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.525515268", "LONGLEVEL":  "ERROR", "DESCRIPTION": "EJBCA : application server unavailable", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "02-01-E-04-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: ERROR - EJBCA : application server unavailable" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "03", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.592832241", "LONGLEVEL":  "INFO", "DESCRIPTION": "Memory limit ok (Memory is  KB used: Limit is  KB)", "EXTRAARG1":   "-318108", "EXTRAARG2":   "801065", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "03-01-I-02-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Memory limit ok (Memory is -318108 KB used: Limit is 801065 KB)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "03", "SCRIPTINDEX": "02", "LEVEL": "I", "ERRNO": "03", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:52", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767392.608875968", "LONGLEVEL":  "INFO", "DESCRIPTION": "Swap limit ok (Swap is  KB used: Limit is  KB)", "EXTRAARG1":   "9168", "EXTRAARG2":   "1548286", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "03-02-I-03-PKI 20160706 03:09:52 ca1.lab.certificateservices.org: INFO - Swap limit ok (Swap is 9168 KB used: Limit is 1548286 KB)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "07", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "04", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.666853178", "LONGLEVEL":  "INFO", "DESCRIPTION": "Syslog is running and delivers messages", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "07-01-I-04-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: INFO - Syslog is running and delivers messages" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "09", "SCRIPTINDEX": "02", "LEVEL": "E", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.685698511", "LONGLEVEL":  "ERROR", "DESCRIPTION": "Firewall doesn't seem to have the correct ruleset configured.", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "09-02-E-02-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: ERROR - Firewall doesn't seem to have the correct ruleset configured." }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "12", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "01", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.746307456", "LONGLEVEL":  "INFO", "DESCRIPTION": "mysql is running", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "12-01-I-01-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: INFO - mysql is running" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "17", "SCRIPTINDEX": "01", "LEVEL": "E", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.788459700", "LONGLEVEL":  "ERROR", "DESCRIPTION": "ntpd is NOT running.", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "17-01-E-02-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: ERROR - ntpd is NOT running." }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "19", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "03", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.806163697", "LONGLEVEL":  "INFO", "DESCRIPTION": "I'm alive", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "19-01-I-03-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: INFO - I'm alive" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "20", "SCRIPTINDEX": "00", "LEVEL": "W", "ERRNO": "03", "SYSTEMNAME": "PKI", "DATE": "20160706 03:09:53", "HOSTNAME": "ca1.lab.certificateservices.org", "SEC1970NANO": "1467767393.819028143", "LONGLEVEL":  "WARNING", "DESCRIPTION": "Cant find the specified ejbca log ", "EXTRAARG1":   "/var/log/jboss/server.log", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "20-00-W-03-PKI 20160706 03:09:53 ca1.lab.certificateservices.org: WARNING - Cant find the specified ejbca log /var/log/jboss/server.log" }
```

Info - NEW Syscheck Sample output
---------------------------

```
01-01-I-01-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Diskusage ok (/ is 33 percent used: Limit is 75 percent)
01-02-I-01-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Diskusage ok (/backup is 1 percent used: Limit is 75 percent)
01-03-I-01-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Diskusage ok (/var/lib is 11 percent used: Limit is 75 percent)
01-04-I-01-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Diskusage ok (/var/log is 1 percent used: Limit is 75 percent)
02-01-E-04-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: ERROR - EJBCA : application server unavailable
03-01-I-02-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Memory limit ok (Memory is -318196 KB used: Limit is 801065 KB)
03-02-I-03-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Swap limit ok (Swap is 9168 KB used: Limit is 1548286 KB)
07-01-I-04-PKI 20160706 03:09:14 ca1.lab.certificateservices.org: INFO - Syslog is running and delivers messages
09-02-E-02-PKI 20160706 03:09:14 ca1.lab.certificateservices.org: ERROR - Firewall doesn't seem to have the correct ruleset configured.
12-01-I-01-PKI 20160706 03:09:15 ca1.lab.certificateservices.org: INFO - mysql is running
17-01-E-02-PKI 20160706 03:09:15 ca1.lab.certificateservices.org: ERROR - ntpd is NOT running.
19-01-I-03-PKI 20160706 03:09:15 ca1.lab.certificateservices.org: INFO - I'm alive
20-00-W-03-PKI 20160706 03:09:15 ca1.lab.certificateservices.org: WARNING - Cant find the specified ejbca log /var/log/jboss/server.log
```

Description:


        01-01-I-01-PKI 20160706 03:09:13 ca1.lab.certificateservices.org: INFO - Diskusage ok (/ is 33 percent used: Limit is 75 percent)

| Position | example | description |
|----------|---------|-------------|
| 1-2      | 01      | SCRIPTID    |
| 3        | -       | Separator   |
| 4-5      | 01      | SCRIPTINDEX |
| 6        | -       | Separator   |
| 7        | I       | I for INFO, W for Warning or E for Error |
| 8        | -       | Separator   |
| 9-10     | 01      | Status code |
| 11       | -       | Separator   |
| 12-14    | PKI     | System ID   |
| 15       | " "     | Separator   |
| 16-32    | 20160706 03:09:13 | Date and time YYYYMMDD HH:MM:SS |
| 33       | " "     | Separator   |
| 34-64    | ca1.lab.certificateservices.org: | Systemname |
| 65       | ":"     | Separator   |
| 66       | " "     | Separator   |
| 67-70    | INFO    | Level spelled out |
| 71       | " - "   | Separator   |
| 72-      | Diskusage ok (/ is 33 percent used: Limit is 75 percent) | Message |



Info - OLD Syscheck Sample output
---------------------------

```
I-0101-PKI 20090328 22:54:23 plup: INFO - Diskusage ok (/ is 51 percent used: Limit is 95 percent)
E-0203-PKI 20090328 22:54:23 plup: ERROR - EJBCA : Application Server is unavailable
I-0302-PKI 20090328 22:54:23 plup: INFO - Memory limit ok (Memory is 869492 KB used: Limit is 1613286 KB)
I-0303-PKI 20090328 22:54:23 plup: INFO - Swap limit ok (Swap is 18672 KB used: Limit is 2963988 KB)
E-0402-PKI 20090328 22:54:24 plup: ERROR - Wrong number of attached pcsc-readers ()
I-0501-PKI 20090328 22:54:24 plup: INFO - pcscd is running
E-0606-PKI 20090328 22:54:24 plup: ERROR - HPTOOL not installed at: /usr/sbin/hpacucli
E-0703-PKI 20090328 22:54:24 plup: ERROR - syslog is not running
E-0803-PKI 20090328 22:54:25 plup: ERROR - Unable to get CRL http://localhost/crl/eIDCA.crl from webserver
E-0901-PKI 20090328 22:54:25 plup: ERROR - Firewall seems to be turned off.
E-1102-PKI 20090328 22:54:35 plup: ERROR - heartbeat is NOT running
I-1201-PKI 20090328 22:54:35 plup: INFO - mysql is running
E-1403-PKI 20090328 22:54:35 plup: ERROR - Unpredicted error in SW-raid 8 / 0 ()
E-1502-PKI 20090328 22:54:35 plup: ERROR - Apache webserver is not running
E-1602-PKI 20090328 22:54:36 plup: ERROR - LDAP directory server is not running
E-1703-PKI 20090328 22:54:36 plup: ERROR - ntpd can't synchronize a server
I-1801-PKI 20090328 22:54:36 plup: INFO - mysql is running and answering
I-1903-PKI 20090328 22:54:36 plup: INFO - I'm alive
```

Info - OLD Format description:
---------------------------


        I-0101-PKI 20090328 22:54:23 plup: INFO - Diskusage ok (/ is 51 percent used: Limit is 95 percent)

```
With fixed width:
1. "I" - Can be I for INFO, W for Warning or E for Error
2. "-" Separator
3-5. Script ID
6. Status code
7. "-" Separator
8-10. System ID
11. " " Separator
12-28: date and time YYYYMMDD HH:MM:SS

With Variable width:
29-32. Systemname
33. ":" Separator
34. " " Separator
35-38. Level spelled out
39-41. " - " Separator
42 - . Message
```

LOGBOOK Tool
=============

Log book is a tool to log activities by the operators, it may be trouble shooting,
handover of problems/incidents to next operator or any important info.

Help:

```
$ ./logbook.sh -h
./logbook.sh: Tool to log messages to syscheck

This is syscheck, loogbook.sh it ask for a entry then logs it.
./logbook.sh [ -r <days> |  -p ] (read is default)
```

to post an entry, it is a single line, need more lines, just run again.
```
$ ./logbook.sh -p
./logbook.sh: Tool to log messages to syscheck

Enter any type of info that needs to be logged into the logbook (max 160 chars)
> Fault tracing the server is slow

```


read the log, press enter to see next day, ctrl-c to exit

```
$ ./logbook.sh -r
./logbook.sh: Tool to log messages to syscheck

Logentries for: 20171119
701-00-I-7011-PKI 20171119 11:54:28 vroom: INFO - User: han ; Logentry: Fault tracing the server is slow
end-of-entries, press enter to see next day
Logentries for: 20171118
end-of-entries, press enter to see next day
Logentries for: 20171117
end-of-entries, press enter to see next day
Logentries for: 20171116
700-00-I-7003-PKI 20171116 15:48:23 vroom: INFO - User: han is getting root, with syscheck on hold reason: Change #363636 - update keystore 47
700-00-I-7004-PKI 20171116 15:48:31 vroom: INFO - User: han is done with root reason: Change #363636 - update keystore 47
end-of-entries, press enter to see next day
Logentries for: 20171115
end-of-entries, press enter to see next day^C
```

read the log x days and exit (put it in your .bashrc maybe)
```
$ ./logbook.sh -r 7
./logbook.sh: Tool to log messages to syscheck

Logentries for: 20171119
701-00-I-7011-PKI 20171119 11:54:28 vroom: INFO - User: han ; Logentry: Fault tracing the server is slow
Logentries for: 20171118
Logentries for: 20171117
Logentries for: 20171116
700-00-I-7003-PKI 20171116 15:48:23 vroom: INFO - User: han is getting root, with syscheck on hold reason: Change #363636 - update keystore 47
700-00-I-7004-PKI 20171116 15:48:31 vroom: INFO - User: han is done with root reason: Change #363636 - update keystore 47
701-00-I-7011-PKI 20171116 15:49:21 vroom: INFO - User: han ; Logentry: ny var det konstigt
Logentries for: 20171115
Logentries for: 20171114
Logentries for: 20171113
```


GetRoot Tool
===============

Small tool to log why you need root before getting access.
This is of course in no way enforceable but still easy to follow up
if operators do not log their reason. As an incentive getroot manages
putting syscheck on hold for the operator.

Becoming root
```
$ ./getroot.sh
./getroot.sh: Tool to log changes and to pause syscheck

Please state a short but clear reason why you need root
> Change CHG123456 - update the version of syscheck
stop any new syscheck scripts Y/n?y
[sudo] password for han:
# #do upgrade
# # now all syscheck batch jobs will not run
# # exit when ready
# exit
logout
Syscheck is on hold, are you done Y/n?y

```

Becoming root, keeping syscheck on-hold.
```
$ ./getroot.sh
./getroot.sh: Tool to log changes and to pause syscheck

Please state a short but clear reason why you need root
> Change CHG123456 - update the version of syscheck
stop any new syscheck scripts Y/n?y
root@vroom:~# exit
logout
Syscheck is on hold, are you done Y/n?n
```

Next time getroot is started, is asks if your done
```
$ ./getroot.sh
Syscheck is on hold, are you done Y/n?y
700 00 I 7004 han (1000) User:  is done with root reason:  Sun Nov 19 12:32:52 CET 2017:upgrade sytscheck:han
```
