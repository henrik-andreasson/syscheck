#!/usr/bin/python

from datetime import datetime
from datetime import timedelta
import argparse
import sys

parser = argparse.ArgumentParser('Util to check validity, compares two date strings and calculate the time left. Calculates also two limits WARN (1/2 of the CRL lifetime), ERROR( 1/4 left of the lifetime). The process returns with these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.')
parser.add_argument('date1', help='date1 ex: "Mar 18 11:30:38 2017 GMT"')
parser.add_argument('date2', help='date2 ex: "Mar 18 19:30:38 2017 GMT"')
parser.add_argument('--warnminutes', type=int, help='set custom level for warning in minutes')
parser.add_argument('--errorminutes', type=int, help='set custom level for error in minutes')
parser.add_argument('--minutes', action='store_const', const="1", help='just return minutes to warn')
parser.add_argument('--diff', action='store_const', const="1", help='just return minutes between the dates')
parser.add_argument('--noyearnotz', action='store_const', const="1", help='datetime without year and tz (aka syslog format) ex: Jul 27 11:36:54')
parser.add_argument('--verbose', action='store_const', const="1")
args = parser.parse_args()


def deltaFMT(td):
    '''Convert timedelta objects to a HH:MM string with (+/-) sign'''
    if td < timedelta(seconds=0):
        sign = '-'
        td = -td
    else:
        sign = ''
    tdhours, rem = divmod(td.total_seconds(), 3600)
    tdminutes, rem = divmod(rem, 60)
    tdstr = '{}{:}:{:02d}'.format(sign, int(tdhours), int(tdminutes))
    return tdstr


if args.noyearnotz:
    created = datetime.strptime(args.date1, "%b %d %H:%M:%S")
    expires = datetime.strptime(args.date2, "%b %d %H:%M:%S")
    print("start: {}".format(created.isoformat()))
else:
    created = datetime.strptime(args.date1, "%b %d %H:%M:%S %Y %Z")
    expires = datetime.strptime(args.date2, "%b %d %H:%M:%S %Y %Z")

now = datetime.now()
validity = expires - created

if (args.warnminutes):
    warn_time = timedelta(0, args.warnminutes*60)
else:
    warn_time = validity*1/2

if (args.errorminutes):
    error_time = timedelta(0, args.errorminutes*60)
else:
    error_time = validity*1/4

since_created = now - created
until_expire = expires - now
until_warn = until_expire - warn_time
until_error = until_expire - error_time

if (args.verbose):
    print("date1                :", args.date1)
    print("date2                :", args.date2)
    print("created              :", created)
    print("expires              :", expires)
    print("now                  :", now.replace(microsecond=0))
    print("validity             :", validity)
    print("time since creation  :", since_created)
    print("validity             :", validity)
    print("warn time            :", warn_time)
    print("err time             :", error_time)
    print("time until warn      :", until_warn)
    print("time until expire    :", until_expire)
    print("time until error     :", until_error)


if (args.minutes):
    minutes = int((until_expire.total_seconds() / 60))

if args.diff:
    print(int(validity.total_seconds() / 60))
    exit

# has already expired
elif (now > expires):
    if (args.minutes):
        print(minutes)
    else:
        print("expire_in: HAS BEEN PASSED {} (h:m)".format(deltaFMT(until_expire)))
    sys.exit(3)

# error time has passed
elif (error_time > until_expire):
    if (args.minutes):
        print(minutes)
    else:
        print("error: HAS BEN PASSED with {} (h:m) until expire: {} (h:m)".format(deltaFMT(until_error), deltaFMT(until_expire)))
    sys.exit(2)

# warn time has passed
elif (warn_time > until_expire):
    if (args.minutes):
        print(minutes)
    else:
        print("warn HAS BEEN PASSED with {} (h:m), until error: {} (h:m) until expire: {} (h:m)".format(deltaFMT(until_warn), deltaFMT(until_error), deltaFMT(until_expire)))
    sys.exit(1)

# no warn/err all ok
else:
    if (args.minutes):
        print(minutes)
    else:
        print("until warn: {} (h:m) until error: {} (h:m) until expire: {} (h:m)".format(deltaFMT(until_warn), deltaFMT(until_error), deltaFMT(until_expire)))
    sys.exit(0)
