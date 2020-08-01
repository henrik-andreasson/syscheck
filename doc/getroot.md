
## GetRoot Tool


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
700 00 I 7004 han (1000) User:  is done with root reason:  Sun Nov 19 12:32:52 CET 2017:upgrade syscheck:han
```
