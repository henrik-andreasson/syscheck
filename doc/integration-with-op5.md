---
title: Syscheck integration with op5
author: Henrik Andreasson
date: 2016-11-27
---

#  Syscheck integration with op5

## Changes

|Version   |Author             |Date        |Comment                      |
|----------|.------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |



## Introduction

OP5 is an enterprise monitoring solution initally based on nagios.
Purpose of the integration is to send infomration from servers that is out of reach for the regular agent.

### Example Work flow

* Syscheck run every 10 min
* As a part of the run syscheck sends information to OP5
* sample request:

        curl -u 'status_update:mysecret' -H 'content-type: application/json' -d '{"host_name":"example_host_1","service_description":"Example service", "status_code":"2","plugin_output":"Example issue has occurred"}' 'https://monitorserver/api/command/PROCESS_SERVICE_CHECK_RESULT'



References
==========

[Nagios API](https://kb.op5.com/display/HOWTOs/Submitting+status+updates+through+the+HTTP+API)
