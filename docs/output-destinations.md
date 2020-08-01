
# Syscheck - LOGBOOK Tool


## Changes

|Version   |Author             |Date        |Comment                      |
|----------|.------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |


## Output to File


syscheck can write to a local file, this can be collected by filebeat to be managed in ELK.

## Output to  Syslog


Sycheck will send messages to a local syslog server, that server can of course route the messages to a central syslog.

[Rsyslog](http://www.rsyslog.com/doc-rsyslog_secure_tls.html) has native support for SSL, use this to make sure the messages are kept confidential during transport.

You still can use any syslog implementation.

## Output to  Icinga

syscheck can send check result directly to icinga  http api

Icinga API <https://icinga.com/docs/icinga2/latest/doc/12-icinga2-api/>

## Output to  OP5


OP5 is an enterprise monitoring solution initally based on nagios.
Purpose of the integration is to send infomration from servers that is out of reach for the regular agent.

*Example Work flow*


* Syscheck run every 10 min
* As a part of the run syscheck sends information to OP5
* sample request:

        curl -u 'status_update:mysecret' -H 'content-type: application/json' -d '{"host_name":"example_host_1","service_description":"Example service", "status_code":"2","plugin_output":"Example issue has occurred"}' 'https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT'

*References*

Nagios API <https://kb.op5.com/display/HOWTOs/Submitting+status+updates+through+the+HTTP+API>

## Output to  Elastic Stack

The JSON output was added for easy integration with elastic.

*Sample setup:*

```
[syscheck installed ] -> [ file output            ] -> [ filebeat reads ] -> [ logstash     ] -> [ icinga   ]
[on a server]            [ "/var/log/syscheck.log"]    [ sends logrows  ]    [ icinga ouput ]    [ alerting ]
```

Read more:
* <https://www.elastic.co/beats/filebeat>
* <https://www.elastic.co>
