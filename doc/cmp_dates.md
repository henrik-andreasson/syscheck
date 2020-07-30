Syscheck component cmp_dates.py
=======================================

Introduction
------------

usage: Util to check validity, compares two date strings and calculate the time left. Calculates also two limits WARN (1/2 of the CRL lifetime), ERROR( 1/4 left of the lifetime). The process returns with these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.
       [-h] [--warnminutes WARNMINUTES] [--errorminutes ERRORMINUTES]
       [--minutes] [--diff] [--noyearnotz] [--verbose]
       date1 date2

positional arguments:
  date1                 date1 ex: "Mar 18 11:30:38 2017 GMT"
  date2                 date2 ex: "Mar 18 19:30:38 2017 GMT"

optional arguments:
  -h, --help            show this help message and exit
  --warnminutes WARNMINUTES
                        set custom level for warning in minutes
  --errorminutes ERRORMINUTES
                        set custom level for error in minutes
  --minutes             just return minutes to warn
  --diff                just return minutes between the dates
  --noyearnotz          datetime without year and tz (aka syslog format) ex:
                        Jul 27 11:36:54
  --verbose
