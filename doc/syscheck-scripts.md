# Syscheck version 2.0 
Documentation generated: Sat  1 Aug 21:54:03 CEST 2020
# Syscheck scripts
##  sc_01_diskusage.sh 
```  

01 - Disk usage
--------------------------------------

sc_01_diskusage.sh Script that checks for to much hard-disc usage, limit is:

Error code / description - What to do

011 / Diskusage ok (%s is %s percent used: Limit is %s percent) - No action is needed
012 / Diskusage exceeded (%s is %s percent used: Limit is %s percent) - The usage is more than the limit, if the disk fills up thing will start to break, make some free space and maybe restart the machine
013 / Diskusage problems (%s : %s) - Manually check config and also try df -Ph /path

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_02_ejbca.sh 
```  

02 - EJBCA Health check
--------------------------------------

sc_02_ejbca.sh Script that connects to the ejbca health check servlet to check the status of the ejbca application. The health check servlet checks JVM memory, database connection and HSM connection.

Error code / description - What to do

021 / EJBCA : %s - No action is needed
022 / EJBCA : %s - Possible errors: 
"Error Virtual Memory is about to run out, currently free memory : X" - you need to add more virtual memory to application server/java process
"Error Connecting to EJBCA Database" - The internal check of database failed, try to connect to database directly or restart database server
"CA Token is disconnected" - activate token or maybe a restart of pcscd can help
023 / EJBCA : health check tool failure - The tool to check if EJBCA is at good health is not configured properly

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_03_memory-usage.sh 
```  

03 - Memory usage
--------------------------------------

sc_03_memory-usage.sh Script that checks that there is enough free memory. The limit is configured in the script, limit: 

Error code / description - What to do

031 / Memory limit exceded (Memory is %s KB used: Limit is %s KB) - system currently uses more than the configured limit, this can be a warning, but can also be a sign of a hard workning system without errors
032 / Memory limit ok (Memory is %s KB used: Limit is %s KB) - system currently uses below the limit
033 / Swap limit exceded (Swap is %s KB used: Limit is %s KB) - system uses more than the swap limit and if the usage dont drop soon you need to investigate, system WILL crash if it runs out of swap compleatly
034 / Swap limit ok (Swap is %s KB used: Limit is %s KB) - No action is needed

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_04_pcsc_readers.sh 
```  

04 - Connected PCSC Readers
--------------------------------------

checks for the defined number of PCSC readers is attached to the computer

Error code / description - What to do

041 / Right number of attatched pcsc-readers (%s) - No action is needed
042 / Wrong number of attached pcsc-readers current: (%s) should be: (%s) - means that all reader is NOT working correctly as defined by pcscd
043 / module not installed(%s) - means that you've not installed the module used by this script python pyscard

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_05_pcscd.sh 
```  

05 - pcscd is running
--------------------------------------

check that pcscd is running

Error code / description - What to do

051 / pcscd is running - No action is needed
052 / pcscd is NOT running - pcscd needs to be restarted, if it dont start, run it with: /path/to/pcscd --foreground --debug

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_06_raid_check.sh 
```  

06 - HP Raid check
--------------------------------------

check the raid discs

Error code / description - What to do

061 / PhysicalDiscs is OK %s - No action is needed
062 / PhysicalDiscs is not OK %s - Change disc as soon as possible
063 / LogicalDiscs is OK %s - No action is needed
064 / LogicalDiscs is rebuilding %s - check back in a while to see this error goes away, else you need to investigate
065 / LogicalDiscs has some other error %s - you need to investigate this error ASAP
066 / HPTOOL not installed at: %s - the hptool is not installed, install the tool to get working reports

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_07_syslog.sh 
```  

07 - Check if syslog if running
--------------------------------------

check to see that syslog is running and delivers messages ok

Error code / description - What to do

071 / loggmessage did not come throu SYSLOG - syslog is running but the messages dont comes throu to local file, restart and/or check config file
072 / syslog is not running - the process was not found amoung running processes
073 / Syslog is running and delivers messages - No action is needed
074 /  - 

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_08_crl_from_webserver.sh 
```  

08 - Download CRL from Webserver and check its validity
--------------------------------------

check the status of CRL, both that it can be downloaded and that its valid

Error code / description - What to do

081 / CRL %s creation have failed - either the server is not up, it dont produce CRL:s, it dont validate or the CRL is old 
082 / %s - No action is needed
083 / Unable to get CRL %s from webserver  - Check manually to get CRL from webserver
084 / When getting CRL %s the size of file is 0 - Check discusage, try manually to get CRL
085 / Configuration error: %s - Check config
086 / CRL has past the EXPIRE date: %s - Systems will probably fail due to this, urgent troubleshooting needed
087 / CRL has past the ERROR level: %s - Systems will soon fail if not fixed, urgent troubleshooting needed
088 / CRL has past the WARN level: %s - Systems will soon fail if not fixed, urgent troubleshooting needed
089 / CRL summary problems: %s - Systems will soon fail if not fixed, urgent troubleshooting needed

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_09_firewall.sh 
```  

09 - Firewall iptables
--------------------------------------

Check the firewall is configured and running

Error code / description - What to do

091 / Cant get status from iptables. - check manually with iptables -L -n or maybe restart the firewall with /etc/init.d/firewall start
092 / Firewall doesn't seem to have the correct ruleset configured. - Maybe something went wrong loading the firewall ruleset, because some very basic rules are'nt present 
093 / Firewall is up and configured properly - No action is needed

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_10_ocsp.sh 
```  

10 - Query OCSP Responder
--------------------------------------

all ok

Error code / description - What to do

101 / Responder cert calculation failed (%s) - either the server is not up, it don't produce OCSP Responses:s
102 / Responder cert ok: %s minutes remains: %s - No action is needed
103 / Responder cert has passed validity warning level %s : %s - Schedule a update of Responder cert
104 / Responder cert has passed validity ERROR level %s : %s - Urgently replace the OCSP responder certificate
105 / Responder cert has PASSED EXPIRY date %s : %s - Urgently replace the OCSP responder certificate
106 / Response status ok: %s - this ocsp response is ok
107 / OCSP Summary ERROR msg: %s errors: %s warnings: %s - search for 10 in logs for more detailed info or run syscheck manually
108 / OCSP Summary WARNING msg: %s errors: %s warnings: %s - search for 10 in logs for more detailed info or run syscheck manually
109 / OCSP Summary OK - this ocsp summary is ok
1010 / OCSP response not ok %s - ocsp response not ok

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_12_mysql.sh 
```  

12 - Mysql server
--------------------------------------

Mysql server checks

Error code / description - What to do

121 / mysql is running - No action is needed
122 / mysql is NOT running - mysql is not running, try /etc/init.d/mysql stop, wait, /etc/init.d/mysql start

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_14_sw_raid.sh 
```  

14 - SW Raid
--------------------------------------

Linux software raid checks

Error code / description - What to do

141 / Disc Array is OK %s - means this script has not detected any errors
142 / Disc %s is failed in array: %s - A disk has failed, you need to replace it
143 / Unpredicted error in SW-raid %s - this script has found a not prediced error

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_15_apache.sh 
```  

15 - Apache Web server
--------------------------------------

Check apache process is up and running

Error code / description - What to do

151 / Apache webserver is running - server is running and serving web pages
152 / Apache webserver is not running - check apache error.log, it is not running

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_16_ldap.sh 
```  

16 - LDAP Server
--------------------------------------

Checks the ldap server to make sure it's running

Error code / description - What to do

161 / LDAP directory server is running - all ok
162 / LDAP directory server is not running - check you ldap server logs

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_17_ntp.sh 
```  

17 - NTP in sync
--------------------------------------

Check that ntp i running and is insync

Error code / description - What to do

171 / ntpd is in sync with server: %s - all ok
172 / ntpd is NOT running. - Start it with /etc/init.d/xntpd start
173 / cant check ntp sync to: %s - check the configuration or restart ntpd
174 / ntpd can NOT synchronize to servers LOCAL(0) mode  - Check network connectivity and configuration of ntp
175 / ntp server not sent in input - Check your syscheck config for ntp

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_18_sqlselect.sh 
```  

18 - Mysql Select
--------------------------------------

Mysql select keepalive

Error code / description - What to do

181 / mysql is running and answering - No action is needed
182 / mysql is NOT answering to select statement check - mysql is not running, try /etc/init.d/mysql stop, wait, /etc/init.d/mysql start

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_19_alive.sh 
```  

19 - Server is alive
--------------------------------------

Sends alive messages to a central syscheck server run this script either along with the rest of the syscheck scripts or in a crontab (then you can run me more often...)

Error code / description - What to do

191 / Operating system just started - Message is sent when the server's operating system is started
192 / Operating system is shutting down - Message is sent when the server's operating system is shutdown
193 / I'm alive - Message is sent to make sure central server know's this server is alive

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_20_errors_ejbcalog.sh 
```  

20 - EJBCA Error log checker
--------------------------------------

checks fo new errors in the server log for ejbca

Error code / description - What to do

201 / No new errors in ejbca server log - No action is needed
202 / New error in log: %s - There was new ERRORS in the LOG file, please attend to them
203 / Cant find the specified ejbca log %s - maybe you havnt configured the script yet?
204 / New detailed error in log: %s - There was new ERRORS in the LOG file, please attend to them

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_22_boks_replica.sh 
```  

22 - BOKS
--------------------------------------

BoKS Replica checks

Error code / description - What to do

221 / No action is needed - all boks processes are running
222 / All BoKS replica processes IS NOT running %s - Not all boks processes are running

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_23_rsa_axm.sh 
```  

23 - RSA Access Manager
--------------------------------------

Checks the RSA Access Manager server to make sure it's running

Error code / description - What to do

231 / RSA Access Manager is running - all ok
232 / At least one service is not running (%s)  - check the rsa access manager server logs

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_27_dss.sh 
```  

27 - SignServer
--------------------------------------

checks the dss server

Error code / description - What to do

271 / Document SignServer is active - No action needed
272 / Document SignServer is running at ONLY ONE NODE - Check the failing node asap
273 / Document SignServer is NOT active - resolve this issue asap
274 / Document SignServer is not installed at this host - maybe you've configured wrong scripts or not yet installed signserver

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_28_check_vip.sh 
```  

28 - VIP
--------------------------------------

Checks which node has the VIP address

Error code / description - What to do

281 / Node 1 has the VIP - No action needed
282 / Node 2 has the VIP - No action needed
283 / Both nodes has the VIP - Resolve this issue asap
284 / None of the nodes has the VIP - Resolve this issue asap
285 / ssh tool 915 not activated - enable 915

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_29_signserver.sh 
```  

29 - SignServer health checker
--------------------------------------

signserver  Script that connects to the signserver health check servlet to check the status of the signserver application. The health check servlet checks JVM memory, database connection and HSM connection.

Error code / description - What to do

291 / SIGNSERVER : %s - No action is needed
292 / SIGNSERVER : %s - Possible errors: 
"Error Virtual Memory is about to run out, currently free memory : X" - you need to add more virtual memory to application server/java process
"Error Connecting to SIGNSERVER Database" - The internal check of database failed, try to connect to database directly or restart database server
"CA Token is disconnected" - activate token or maybe a restart of pcscd can help
293 / SIGNSERVER : Application Server is unavailable - The server is non-responding, restart application-server (jboss) and/or check server log to find the fault

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_30_check_running_procs.sh 
```  

30 - Running processes
--------------------------------------

Generic script to check a proc is running and try to restart those that's not

Error code / description - What to do

301 / Process %s is running - No action is needed
302 / Process %s was not running, restart succeded - If this happens regulary this need to be looked into
303 / Process %s was not running, restart failed - If this needs to be this handled manually

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_31_hp_health.sh 
```  

31 - HP Server health check
--------------------------------------

Check the HP Server health

Error code / description - What to do

311 / Sensor of %s is OK %s - No action is needed
312 / Temp sensor %s is NOT OK %s - Run manual test with hpasmcli
313 / FAN sensor %s is NOT OK %s - Run manual test with hpasmcli
314 / Tool not found: %s  - Install or set path

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_32_check_db_sync.sh 
```  

32 - EJBCA DB Sync
--------------------------------------

Check if DB in sync

Error code / description - What to do

321 / DB in sync - and updating databases
322 / DB not in sync, date of CertificateData diff betwin nodes: - check error.log, probebly needing manual sync, se manual

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_33_healthchecker.sh 
```  

33 - Check Health of applications
--------------------------------------

Healthcheck of applications with simple URL health (should return ALLOK and status 200)

Error code / description - What to do

331 / Healtcheck of app: %s ok - No action is needed
332 / Healtcheck of app: %s NOT ok error message: %s - Check errormessage and log-file
333 / Healtcheck of app: %s CHECKTOOL not curl nor wget - Config curl or wget
334 / Healtcheck of app: %s restarting due to previous failure status: %s command: %s - Check errormessage and log-file

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_34_redis.sh 
```  

34 - Redis
--------------------------------------

Check Redis VIP

Error code / description - What to do

341 / server is OK at %s:%s (%s) - All is ok
342 / server is not responding %s:%s (%s) - check the redis server is not responding
343 / Input Arg problem %s - Check config
344 / redis-cli is not found - install/configure redis-cli in config

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_35_dell_raid.sh 
```  

35 - Dell Hard drive checker
--------------------------------------

check the raid discs

Error code / description - What to do

351 / PhysicalDiscs is OK %s - No action is needed
352 / PhysicalDiscs is not OK %s - Change disc as soon as possible
353 / LogicalDiscs is OK %s - No action is needed
354 / LogicalDiscs is rebuilding %s - check back in a while to see this error goes away, else you need to investigate
355 / LogicalDiscs has some other error %s - you need to investigate this error ASAP
356 / TOOL not installed at: %s - the tool is not installed, install the tool to get working reports

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_36_dell_health.sh 
```  

36 - Dell Server system components
--------------------------------------

check dell system components

Error code / description - What to do

361 / Component is OK %s - No action is needed
362 / Component NOT OK %s - Change component as soon as possible
363 / TOOL not installed at: %s - the tool is not installed, install the tool to get working reports

to run with output directed to screen: add a '-s' or '--screen'

``` 
##  sc_37_monitor_jnlp.sh 
```  

01/ok: %s - No action is needed
02/problem: %s - problem: %s
03/ - 
04/ - 
05/ - 
to run with output directed to screen: add a '-s' or '--screen'
``` 
