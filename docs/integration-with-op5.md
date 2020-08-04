#  Syscheck integration with op5 and icinga

## Changes

|Version   |Author             |Date        |Comment                      |
|----------|-------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |



## Introduction

OP5 is an enterprise monitoring solution initally based on nagios.

Icinga is a comunity driven fork of nagios.

Purpose of the integration is to send infomration from servers that is out of reach for the regular agent.

## config

OP5 and Icinga is turned on/off in config/common.conf

```
# send log messages to icinga http api
# values: 0 - disabled or 1 - enabled
SENDTO_ICINGA=0

# send log messages to OP5 http api
# values: 0 - disabled or 1 - enabled
SENDTO_OP5=1

```

Then API username and password is set in config/monitoring.conf

```
# monitoring

ICINGA_USER="root"
ICINGA_PASS="foo123"
ICINGA_API_URL="https://icingaservername:5665/v1/actions/"


OP5_USER="root"
OP5_PASS="foo123x"
OP5_API_URL="https://op5servername/api/command/PROCESS_SERVICE_CHECK_RESULT"
```


### Example Work flow

* Syscheck run every 10 min
* As a part of the run syscheck sends information to OP5
* sample request:

        curl -u 'status_update:mysecret' -H 'content-type: application/json' -d '{"host_name":"example_host_1","service_description":"Example service", "status_code":"2","plugin_output":"Example issue has occurred"}' 'https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT'



References
==========

[OP5 API](https://kb.op5.com/display/HOWTOs/Submitting+status+updates+through+the+HTTP+API)

[Icinga API](https://icinga.com/docs/icinga2/latest/doc/12-icinga2-api/)
