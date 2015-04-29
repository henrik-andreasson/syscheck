README for syscheck output
==============================

in version 1.7 JSON output format was added.

in version 1.6 the output format has changes to support pushing messages to icinga/nagios (and mayby other monitoring solutions also).


Info - JSON Syscheck Sample output
---------------------------

{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "01", "LEVEL": "E", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20150426 20:59:32", "HOSTNAME": "bang", "SEC1970NANO": "1430074772.388541169", "LONGLEVEL":  "ERROR", "DESCRIPTION": "Diskusage exceeded ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/", "EXTRAARG2":   "99", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-01-E-02-PKI 20150426 20:59:32 bang: ERROR - Diskusage exceeded (/ is 99 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "01", "SCRIPTINDEX": "02", "LEVEL": "E", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20150426 20:59:32", "HOSTNAME": "bang", "SEC1970NANO": "1430074772.416035932", "LONGLEVEL":  "ERROR", "DESCRIPTION": "Diskusage exceeded ( is  percent used: Limit is  percent)", "EXTRAARG1":   "/backup", "EXTRAARG2":   "99", "EXTRAARG3":   "75", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "01-02-E-02-PKI 20150426 20:59:32 bang: ERROR - Diskusage exceeded (/backup is 99 percent used: Limit is 75 percent)" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "02", "SCRIPTINDEX": "01", "LEVEL": "E", "ERRNO": "04", "SYSTEMNAME": "PKI", "DATE": "20150426 20:59:32", "HOSTNAME": "bang", "SEC1970NANO": "1430074772.483664082", "LONGLEVEL":  "ERROR", "DESCRIPTION": "EJBCA : application server unavailable", "EXTRAARG1":   "", "EXTRAARG2":   "", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "02-01-E-04-PKI 20150426 20:59:32 bang: ERROR - EJBCA : application server unavailable" }
{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "trunk", "LOGFMT": "JSON-1.0", "SCRIPTID": "03", "SCRIPTINDEX": "01", "LEVEL": "I", "ERRNO": "02", "SYSTEMNAME": "PKI", "DATE": "20150426 20:59:32", "HOSTNAME": "bang", "SEC1970NANO": "1430074772.521154236", "LONGLEVEL":  "INFO", "DESCRIPTION": "Memory limit ok (Memory is  KB used: Limit is  KB)", "EXTRAARG1":   "3825580", "EXTRAARG2":   "13079398", "EXTRAARG3":   "", "EXTRAARG4":   "", "EXTRAARG5":   "", "EXTRAARG6":   "", "EXTRAARG7":   "", "EXTRAARG8":   "", "EXTRAARG9":   "", "LEGACYFMT":   "03-01-I-02-PKI 20150426 20:59:32 bang: INFO - Memory limit ok (Memory is 3825580 KB used: Limit is 13079398 KB)" }


Info - JSON Format description:
---------------------------

{
   "FROM":"SYSCHECK",
   "SYSCHECK_VERSION":"trunk",
   "LOGFMT":"JSON-1.0",
   "SCRIPTID":"30",
   "SCRIPTINDEX":"01",
   "LEVEL":"I",
   "ERRNO":"01",
   "SYSTEMNAME":"PKI",
   "DATE":"20150426 20:59:34",
   "HOSTNAME":"bang",
   "SEC1970NANO":"1430074774.745658970",
   "LONGLEVEL":"INFO",
   "DESCRIPTION":"Process  is running",
   "EXTRAARG1":"apache2",
   "EXTRAARG2":"",
   "EXTRAARG3":"",
   "EXTRAARG4":"",
   "EXTRAARG5":"",
   "EXTRAARG6":"",
   "EXTRAARG7":"",
   "EXTRAARG8":"",
   "EXTRAARG9":"",
   "LEGACYFMT":"30-01-I-01-PKI 20150426 20:59:34 bang: INFO - Process apache2 is running"
}

Info - NEWFMT Syscheck Sample output
---------------------------
/opt/certificate-services/syscheck]$ ./console_syscheck.sh 
01-01-I-01-PKI 20140904 09:27:19 hostname: INFO - Diskusage ok (/ is 3 percent used: Limit is 75 percent)
01-02-I-01-PKI 20140904 09:27:19 hostname: INFO - Diskusage ok (/backup is 43 percent used: Limit is 75 percent)
01-03-I-01-PKI 20140904 09:27:19 hostname: INFO - Diskusage ok (/var/lib is 4 percent used: Limit is 75 percent)
01-04-I-01-PKI 20140904 09:27:19 hostname: INFO - Diskusage ok (/var/log is 1 percent used: Limit is 75 percent)
02-01-I-01-PKI 20140904 09:27:19 hostname: INFO - EJBCA : ALLOK
03-01-I-02-PKI 20140904 09:27:19 hostname: INFO - Memory limit ok (Memory is 7734720 KB used: Limit is 13054803 KB)
03-02-I-03-PKI 20140904 09:27:19 hostname: INFO - Swap limit ok (Swap is 279412 KB used: Limit is 21921788 KB)
06-01-I-01-PKI 20140904 09:27:20 hostname: INFO - PhysicalDiscs is OK       physicaldrive 1I:1:1 (port 1I:box 1:bay 1, SAS, 300 GB, OK)
06-02-I-01-PKI 20140904 09:27:21 hostname: INFO - PhysicalDiscs is OK       physicaldrive 1I:1:2 (port 1I:box 1:bay 2, SAS, 300 GB, OK)
06-03-I-01-PKI 20140904 09:27:22 hostname: INFO - PhysicalDiscs is OK       physicaldrive 1I:1:3 (port 1I:box 1:bay 3, SAS, 300 GB, OK)
06-04-I-01-PKI 20140904 09:27:22 hostname: INFO - PhysicalDiscs is OK       physicaldrive 1I:1:4 (port 1I:box 1:bay 4, SAS, 300 GB, OK)
06-05-I-03-PKI 20140904 09:27:23 hostname: INFO - LogicalDiscs is OK       logicaldrive 1 (838.1 GB, RAID 5, OK)
07-01-I-04-PKI 20140904 09:27:24 hostname: INFO - Syslog is running and delivers messages
09-02-I-03-PKI 20140904 09:27:24 hostname: INFO - Firewall is up and configured properly
12-01-I-01-PKI 20140904 09:27:24 hostname: INFO - mysql is running
17-02-I-01-PKI 20140904 09:27:24 hostname: INFO - ntpd is in sync with server: 10.1.1.1
19-01-I-03-PKI 20140904 09:27:24 hostname: INFO - I'm alive
20-01-I-01-PKI 20140904 09:27:24 hostname: INFO - No new errors in ejbca server log
31-01-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of PSU1 is OK 
31-02-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of PSU2 is OK 
31-06-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #1 AMBIENT Current: 25 Limit: 41 (celsius) is OK 
31-10-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #2 CPU#1 Current: 40 Limit: 82 (celsius) is OK 
31-14-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #3 CPU#2 Current: 40 Limit: 82 (celsius) is OK 
31-18-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #4 MEMORY_BD Current: 32 Limit: 87 (celsius) is OK 
31-22-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #5 MEMORY_BD Current: 32 Limit: 87 (celsius) is OK 
31-26-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #6 MEMORY_BD Current: 34 Limit: 87 (celsius) is OK 
31-30-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #7 MEMORY_BD Current: 35 Limit: 87 (celsius) is OK 
31-34-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #8 SYSTEM_BD Current: 41 Limit: 90 (celsius) is OK 
31-38-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #9 SYSTEM_BD Current: 36 Limit: 65 (celsius) is OK 
31-42-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #10 SYSTEM_BD Current: 44 Limit: 90 (celsius) is OK 
31-46-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #11 SYSTEM_BD Current: 33 Limit: 70 (celsius) is OK 
31-50-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #12 SYSTEM_BD Current: 42 Limit: 90 (celsius) is OK 
31-54-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #13 I/O_ZONE Current: 32 Limit: 70 (celsius) is OK 
31-58-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #14 I/O_ZONE Current: 35 Limit: 70 (celsius) is OK 
31-62-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #15 I/O_ZONE Current: 34 Limit: 70 (celsius) is OK 
31-63-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #16 I/O_ZONE is known not to give any reading (#16;I/O_ZONE;-;70C/158F;) is OK 
31-64-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #17 I/O_ZONE is known not to give any reading (#17;I/O_ZONE;-;70C/158F;) is OK 
31-65-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #18 I/O_ZONE is known not to give any reading (#18;I/O_ZONE;-;70C/158F;) is OK 
31-69-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #19 SYSTEM_BD Current: 27 Limit: 70 (celsius) is OK 
31-73-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #20 SYSTEM_BD Current: 30 Limit: 70 (celsius) is OK 
31-77-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #21 SYSTEM_BD Current: 32 Limit: 80 (celsius) is OK 
31-81-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #22 SYSTEM_BD Current: 32 Limit: 80 (celsius) is OK 
31-85-I-01-PKI 20140904 09:27:25 hostname: INFO - Sensor of TEMP #23 SYSTEM_BD Current: 39 Limit: 77 (celsius) is OK 
31-89-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #24 SYSTEM_BD Current: 34 Limit: 70 (celsius) is OK 
31-93-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #25 SYSTEM_BD Current: 33 Limit: 70 (celsius) is OK 
31-97-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #26 SYSTEM_BD Current: 34 Limit: 70 (celsius) is OK 
31-98-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #27 I/O_ZONE is known not to give any reading (#27;I/O_ZONE;-;70C/158F;) is OK 
31-99-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #28 I/O_ZONE is known not to give any reading (#28;I/O_ZONE;-;70C/158F;) is OK 
31-103-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #29 SCSI_BACKPLANE_ZONE Current: 35 Limit: 60 (celsius) is OK 
31-107-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of TEMP #30 SYSTEM_BD Current: 64 Limit: 110 (celsius) is OK 
31-108-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#1) IS in normal operation (NORMAL/29%) is OK 
31-109-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#2) IS in normal operation (NORMAL/30%) is OK 
31-110-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#3) IS in normal operation (NORMAL/35%) is OK 
31-111-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#4) IS in normal operation (NORMAL/35%) is OK 
31-112-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#5) IS in normal operation (NORMAL/30%) is OK 
31-113-I-01-PKI 20140904 09:27:26 hostname: INFO - Sensor of FAN(#6) IS in normal operation (NORMAL/13%) is OK 

Info - NEWFMT Format description:
---------------------------

01-01-I-01-PKI 20140904 09:27:19 hostname: INFO - Diskusage ok (/ is 3 percent used: Limit is 75 percent)
      I-0101-PKI 20090328 22:54:23 plup: INFO - Diskusage ok (/ is 51 percent used: Limit is 95 percent)


1. ScriptID, unique id for the script, usally 2 numbers byt may be more, use the - as separator
2. "-" Separator
3. ScriptIndex, unique index for the test (eg. 01 for the first disc tested, 02 for the second and so on..), usally 2 numbers byt may be more, use the - as separator
4. "-" Separator
5. ErrorLevel - Can be I for INFO, W for Warning or E for Error
6. "-" Separator
7. Status code, usally 2 numbers byt may be more, use the - as separator
7. "-" Separator
8. System ID
11. " " Separator
12: date and time YYYYMMDD HH:MM:SS
13. Systemname
14. ":" Separator
15. " " Separator
16. Level spelled out
17. " - " Separator
18 - . Message



Info - OLDFMT Syscheck Sample output
---------------------------

han@plup:/misc/src/syscheck/syscheck-trunk$ ./syscheck.sh -s
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


Info - OLDFMT Format description:
---------------------------

I-0101-PKI 20090328 22:54:23 plup: INFO - Diskusage ok (/ is 51 percent used: Limit is 95 percent)

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

