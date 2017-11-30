#!/usr/bin/python

from datetime import datetime
from datetime import timedelta
import argparse
import sys

<<<<<<< HEAD
parser = argparse.ArgumentParser('Util to check CRL validity, compares two date strings and calculate the time left. Calculates also two limits WARN (1/2 of the CRL lifetime), ERROR( 1/4 left of the lifetime). The process returns with these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.')
parser.add_argument('date1', help='date1 ex: "Mar 18 11:30:38 2017 GMT"')
parser.add_argument('date2', help='date2 ex: "Mar 18 19:30:38 2017 GMT"')
parser.add_argument('--warnminutes', type=int, help='set custom level for warning in minutes')
parser.add_argument('--errorminutes', type=int, help='set custom level for error in minutes')
parser.add_argument('--minutes', action='store_const', const="1", help='just return minutes to warn')
parser.add_argument('--verbose', action='store_const', const="1")
args = parser.parse_args()

=======
ERROR=1/4
WARN=1/2


parser = argparse.ArgumentParser('Util to check CRL validity, compares two date strings and calculate the time left. Calculates also two limits WARN (1/2 of the CRL lifetime), ERROR( 1/4 left of the lifetime). The process returns with these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.')
parser.add_argument('date1', help='date1 ex: "Mar 18 11:30:38 2017 GMT"')
parser.add_argument('date2', help='date2 ex: "Mar 18 19:30:38 2017 GMT"')
parser.add_argument('--verbose', action='store_const', const="1")
args = parser.parse_args()

if ( args.verbose ) :
    print "date1: " , args.date1 , " date2: ", args.date2
>>>>>>> efafd1cc7290a3f22365eb93efed230e40a3a1f0


created       = datetime.strptime(args.date1, "%b %d %H:%M:%S %Y %Z")
expires       = datetime.strptime(args.date2, "%b %d %H:%M:%S %Y %Z")
now           = datetime.now()
<<<<<<< HEAD
validity      = expires - created

if ( args.warnminutes) :
    warn_time = timedelta(0,args.warnminutes*60)
else:
    warn_time     = validity*1/2

if ( args.errorminutes) :
    error_time = timedelta(0,args.errorminutes*60)
else:
    error_time    = validity*1/4

since_created = now - created
until_expire  = expires - now
until_warn    = until_expire - warn_time
until_error   = until_expire - error_time

if ( args.verbose ) :
    print "date1                :", args.date1
    print "date2                :", args.date2
    print "created              :", created
    print "expires              :", expires
    print "now                  :", now.replace(microsecond=0)
    print "validity             :", validity
    print "time since creation  :", since_created
    print "validity             :", validity
    print "warn time            :", warn_time
    print "err time             :", error_time
    print "time until warn      :", until_warn
    print "time until expire    :", until_expire
    print "time until error     :", until_error


if ( args.minutes ) :
    minutes = int((until_expire.total_seconds() / 60))

if (now > expires) :
    if ( args.minutes ) :
        print minutes
    else:
        print "ERROR HAS EXPIRED: ", expires , "(d:h:m:s.mmm)"
    sys.exit(3)
    
elif (error_time > until_expire) :
    if ( args.minutes ) :
        print minutes
    else:
        print "ERROR error_time", error_time, "(hh:mm:ss) has passed, time until expiration", until_expire, "(d:h:m:s.mmm)"
=======
warn_time     = (expires - created)*WARN
error_time    = (expires - created)*ERROR
validity      = expires - created

if ( args.verbose ) :
    print "created ", created
    print "expires ", expires
    print "now     ", now.replace(microsecond=0)
    print "validity", validity

since_created=now - created
until_expire=expires - now

if ( args.verbose ) :
    print "time since creation  :", str(since_created)
    print "time until expiration:", str(until_expire)
    print "validity             :", str(validity)
    print "warn time            :", str(warn_time)
    print "time until warn      :", str(until_expire - warn_time)
    print "err time             :", str(error_time)
    print "time until error     :", str(until_expire - error_time)
    print "real stuff"

if (now > expires) :
    print "ERROR expire has passed expired: ", expires , "(d:h:m:s.mmm)"
    sys.exit(3)
    
elif (error_time > until_expire) :
    print "ERROR error_time", error_time, "(hh:mm:ss) has passed, time until expiration", until_expire, "(d:h:m:s.mmm)"
>>>>>>> efafd1cc7290a3f22365eb93efed230e40a3a1f0
    sys.exit(2)


elif (warn_time > until_expire) :
<<<<<<< HEAD
    if ( args.minutes ) :
        print minutes
    else:
        print "WARNING warn_time", warn_time, "(hh:mm:ss) has passed, time until error: ", until_error, " time until expiration: ", until_expire, "(hh:mm:ss)"
    sys.exit(1)

else :
    if ( args.minutes ) :
        print minutes
    else:
        print "expire_in: ", until_expire , "(h:m:s), until_warn: ", until_warn , " until_err: ", until_error ," validity: " , validity
=======
    print "WARNING warn_time", warn_time, "(hh:mm:ss) has passed, time until expiration: ", until_expire, "(hh:mm:ss)"
    sys.exit(1)

else :
    print "OK  validity: " , validity, "(hh:mm:ss), time until warn: ", warn_time ,"(hh:mm:ss),",  "time until expiration: ", until_expire , "(hh:mm:ss.nnn)"
>>>>>>> efafd1cc7290a3f22365eb93efed230e40a3a1f0
    sys.exit(0)

