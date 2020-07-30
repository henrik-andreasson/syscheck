#!/usr/bin/python
import re
from datetime import datetime
import argparse
import os
import sys

parser = argparse.ArgumentParser("usage: %prog [options]")
parser.add_argument("--logfile",      help="logfile to search")
parser.add_argument("--positionfile", help="position file to store last position in")
parser.add_argument("--searchfor",    help="search for")

args = parser.parse_args()

posfilename = "/var/tmp/ejbca_log_position.txt"
logfilename = "/var/log/wildfly/server.log"
searchfor = ".*ERROR.*"
epoch = datetime(1970, 1, 1, 0, 0, 0)

if args.logfile:
    logfilename = args.logfile

if args.positionfile:
    posfilename = args.positionfile

if args.searchfor:
    searchfor = args.searchfor

sys.stderr.write("posfilename {}\n".format(posfilename))
sys.stderr.write("logfilename {}\n".format(logfilename))
sys.stderr.write("searchfor {}\n".format(searchfor))

ts_last_match = epoch
if not os.path.exists(posfilename):
    posfile = open(posfilename, mode='w')
    print("deltat {}".format(ts_last_match.isoformat()))
    posfile.write(ts_last_match.isoformat())
    posfile.close()
else:
    posfile = open(posfilename, mode='r')
    ts_last_match = datetime.strptime(posfile.read().strip(), "%Y-%m-%dT%H:%M:%S")
    if ts_last_match is None:
        ts_last_match = epoch
    posfile.close()

matches = []
ts_current_match = epoch
date_regex = r"(\d{4,4}-\d{1,2}-\d{1,2}\ +\d{1,2}:\d{1,2}:\d{1,2})"

logfile = open(logfilename, mode='r')
for line in logfile:

    match = re.search(searchfor, line)
    if match:
#        print("regex matches: {}".format(match.group()))
        date_str = re.search(date_regex, line)
#        print("date regex matches: {}".format(date_str.group()))
        match_ts = datetime.strptime(date_str.group(), "%Y-%m-%d %H:%M:%S")
#        print("current match {}".format(match_ts.isoformat()))
#        print("last match {}".format(ts_last_match.isoformat()))
        if (match_ts > ts_last_match):
            print(line.strip())
            matches.append(line)
            ts_current_match = match_ts


#print("current match {}".format(ts_current_match.isoformat()))
#print("last match {}".format(ts_last_match.isoformat()))

if (ts_current_match > ts_last_match):
    posfile = open(posfilename, mode='w')
#    print("writing current match to file: {}".format(ts_current_match.isoformat()))
    posfile.write(str(ts_current_match.isoformat()))
    posfile.close()
