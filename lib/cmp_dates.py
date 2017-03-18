#!/usr/bin/python

from datetime import datetime
from datetime import timedelta
import argparse
import sys

ERROR=1/4
WARN=1/2


parser = argparse.ArgumentParser('Util to check CRL validity, compares two date strings and calculate the time left. Calculates also two limits WARN (1/2 of the CRL lifetime), ERROR( 1/4 left of the lifetime). The process returns with these values  0 -> ok,  1 -> warn ,  2 -> error,  3 -> expired.')
parser.add_argument('date1', help='date1 ex: "Mar 18 11:30:38 2017 GMT"')
parser.add_argument('date2', help='date2 ex: "Mar 18 19:30:38 2017 GMT"')
parser.add_argument('--verbose', action='store_const', const="1")
args = parser.parse_args()

if ( args.verbose ) :
    print "date1: " , args.date1 , " date2: ", args.date2


created       = datetime.strptime(args.date1, "%b %d %H:%M:%S %Y %Z")
expires       = datetime.strptime(args.date2, "%b %d %H:%M:%S %Y %Z")
now           = datetime.now()
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
    sys.exit(2)


elif (warn_time > until_expire) :
    print "WARNING warn_time", warn_time, "(hh:mm:ss) has passed, time until expiration: ", until_expire, "(hh:mm:ss)"
    sys.exit(1)

else :
    print "OK  validity: " , validity, "(hh:mm:ss), time until warn: ", warn_time ,"(hh:mm:ss),",  "time until expiration: ", until_expire , "(hh:mm:ss.nnn)"
    sys.exit(0)

