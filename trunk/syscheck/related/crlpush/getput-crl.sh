#!/bin/bash
# The script fetches a crl from the ca and scp the crl to a webserver.
# Change $HTTPSERVER, $SSHUSER and $SSHSERVER_DIR. Define the crl's and the servers in the end.
# Usage:
# get example.crl # This gets the crl from the CA server.
# put 192.168.10.10 # This sends the crl to the webserver.

# HTTPSERVER='http://192.168.0.15:8080/ejbca/'
CRLDIRECTORY="/var/crl"

SSHUSER='wwwrun'
SSHSERVER_DIR='/srv/www/htdocs'


get () {
	cd /usr/local/ejbca/bin
	./ejbca.sh ca getcrl $1 $CRLDIRECTORY/$2
}

get "CA" "ca.crl"

put () {
	cd $CRLDIRECTORY
	scp $2 $SSHUSER@$1:$SSHSERVER_DIR
}

put 192.168.10.10 "ca.crl"

put 192.168.10.11 "ca.crl"
