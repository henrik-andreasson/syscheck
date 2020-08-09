./getroot.sh: Tool become root and to log changes and to pause syscheck

Please state a short but clear reason why you need root

Scriptid: 700 - get root

This is syscheck, getroot.sh it ask for a reason to get root, logs it then asks if syscheck scripts should be put on hold.

Syntax: ./getroot.sh (run interactive)
-p|--pause to automatically set/unset syscheck on/off pause
-r|--reason <reason> set reason from arg

Error code / description - What to do

7001 / User: %s is getting root reason: %s - 
7002 / User: %s is getting root reason: %s - 
7003 / User: %s is getting root, with syscheck on hold reason: %s - 
7004 / User: %s is done with root reason: %s - 

to run with output directed to screen: add a '-s' or '--screen'

