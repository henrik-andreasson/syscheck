
# Syscheck - LOGBOOK Tool


## Changes

|Version   |Author             |Date        |Comment                      |
|----------|.------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |





Log book is a tool to log activities by the operators, it may be trouble shooting,
handover of problems/incidents to next operator or any important info.

### to enable sudo run:

    usermod -D wheel -a lcso


### logbook samples

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
