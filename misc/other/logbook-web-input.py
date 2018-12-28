#!/usr/bin/env python
# -*- coding: utf8     -*-
"""
Super simple webserver to get input from 
"""
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import SocketServer
import re
import cgi
from datetime import datetime, date, timedelta
import json,sys
from subprocess import call

HTMLHeader="""<html><header> <meta charset="UTF-8"> </header><body><h1>Syscheck Logbook input</h1>
        <b><a href='https://logbak1.stuff'>kibana search for all logbook comments</a></b><br>
        <form action="/"  accept-charset="UTF-8" method="post">
            Logentry: <br>
            <input name=comment type=text size=50>
            <br>
            <input type="submit" value="Submit">
        </form>"""
HTMLFooter="""</body></html>"""
SYSCHEK_SYSTEM="PKI"

DEBUG=1

def debug(self,str):
    if DEBUG:
        print "DEBUG:", DEBUG , "str:", str


class S(BaseHTTPRequestHandler):

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def last7daysLog(self):
        date = datetime.now()
        dnow = datetime.strftime(date, "%Y%m%d")

        self.wfile.write( "<H2>local entries:</H2>")

        now = datetime.now()
        for delta in range(7):
            dateoffset = timedelta(days=delta)
            date = now - dateoffset
            matchstr = SYSCHEK_SYSTEM + " " + datetime.strftime(date, "%Y%m%d")
            self.wfile.write("<h3>entries from: " + datetime.strftime(date, "%Y%m%d") + "</h3>")
                
            for line in reversed(open("/var/log/syscheck-logbook.log").readlines()):
                if matchstr in line:
                    obj=json.loads(line)
                    self.wfile.write( "<br>" + obj["LEGACYFMT"] + "<br>" )


    def userPosting(self):
        if 'Remote-User' in self.headers:
            userPosting = self.headers['Remote-User']
            debug("remote user:", userPosting)
        else:
            userPosting="webuser"
            debug("using default username: ", userPosting)

        return userPosting

    def post2logbook(self,user,comment):
    
        SCRIPTID=701
        
        ERRNO[1]="7011"
        DESCR[1]="User: %s ; Logentry: %s"
        INFO="I"
        call(["/home/han/devel/syscheck/master/lib/logbook-cli.sh", str(SCRIPTID), str(SCRIPTINDEX), str(INFO), str(ERRNO[1]), str(DESCR[1]), user, comment])


    def do_GET(self):
        self._set_headers()
        self.wfile.write(HTMLHeader)
        self.wfile.write("<br>Posting as: " + self.userPosting() )
        self.last7daysLog()                
        self.wfile.write( HTMLFooter )

    def do_HEAD(self):
        self._set_headers()
        
        
    def do_POST(self):
        # Doesn't do anything with posted data
        form = cgi.FieldStorage(
			fp=self.rfile, 
			headers=self.headers,
			environ={'REQUEST_METHOD':'POST',
	                 'CONTENT_TYPE':self.headers['Content-Type'],

		})

        self.wfile.write("<br>Posting as: " + self.userPosting() )

        self.send_response(200)
        self.end_headers()
        self.wfile.write(HTMLHeader)
        now = datetime.now()
        if not form.has_key("comment"):
            print "empty submit"
        else:
            rawcomment = form["comment"].value
            comment = rawcomment[:120]
            notallowedre = re.search(r'"|\'|å|ä|ö',comment)
            debug(notallowedre)
            if notallowedre:
                self.wfile.write("Input contains notallowed characters")
            else:    
                self.wfile.write("Thanks for sending comment: " +  str(now) + " " + comment)
                self.post2logbook(userPosting,comment)
                        
        self.last7daysLog()
        self.wfile.write(HTMLFooter)
        return			

        
def run(server_class=HTTPServer, handler_class=S, port=8877):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print 'Starting httpd...'
    httpd.serve_forever()

if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()

