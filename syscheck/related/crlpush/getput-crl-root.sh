#!/bin/bash
# Change $HTTPSERVER, $SSHUSER and $SSHSERVER_DIR. Define the crl's and the servers in the end.
# Usage:
# get example.crl # This gets the crl from the CA server.
# put 192.168.10.10 # This sends the crl to the webserver.

CRLDIRECTORY="/var/crl"

SSHUSER='wwwrun'
SSHSERVER_DIR='/srv/www/htdocs/'


get () {
	cd /usr/local/ejbca/bin
	./ejbca.sh ca getcrl $1 $CRLDIRECTORY/$2
}

get "E-TUGRA_KSM" "e-tugra_ksm.crl"

put () {
	cd $CRLDIRECTORY
	scp $2 $SSHUSER@$1:$SSHSERVER_DIR
}

put 192.168.10.10 "e-tugra_ksm.crl"

put 192.168.10.11 "e-tugra_ksm.crl"
