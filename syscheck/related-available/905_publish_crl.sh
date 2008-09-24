#!/bin/bash
# The script fetches a crl from the ca and scp the crl to a webserver.
# Change $HTTPSERVER, $SSHUSER and $SSHSERVER_DIR. Define the crl's and the servers in the end.
# Usage:
# get example.crl # This gets the crl from the CA server.
# put 192.168.10.10 # This sends the crl to the webserver.

# source env vars from system that dont get included when running from cron

SYSCHECK_HOME=${SYSCHECK_HOME:-"/usr/local/syscheck"}

# Import common resources
. $SYSCHECK_HOME/resources.sh


## local definitions ##
SCRIPTID=905
getlangfiles $SCRIPTID

HOURTHRESHOLD=12


CANAME[0]="Labb_EID_CA_v2"
VERIFY_HOST[0]="certpubl-nod1"
SSHUSER[0]='crlpubl'
SSHSERVER_DIR[0]='/srv/www/htdocs/'
SSHKEY[0]='/home/jboss/.ssh/id_rsa'

CANAME[1]="Labb_EID_CA_v2"
VERIFY_HOST[1]="certpubl-nod2"
SSHUSER[1]='crlpubl'
SSHSERVER_DIR[1]='/srv/www/htdocs/'
SSHKEY[1]='/home/jboss/.ssh/id_rsa'


### end config ###


ERRNO_1=${SCRIPTID}01
ERRNO_2=${SCRIPTID}02
ERRNO_3=${SCRIPTID}03
ERRNO_4=${SCRIPTID}04
ERRNO_5=${SCRIPTID}05
ERRNO_6=${SCRIPTID}06
ERRNO_7=${SCRIPTID}07




if [ "x$1" = "x--help" -o "x$1" = "x-h" ] ; then
        echo "$0 <-s|--screen>"
        exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen"  ] ; then
    PRINTTOSCREEN=1
fi 



CRLDIRECTORY="/var/tmp/crl"
if [ ! -d $CRLDIRECTORY ] ; then
	mkdir $CRLDIRECTORY
fi

VERIFYCRLDIRECTORY="/var/tmp/crl-verify"
if [ ! -d $VERIFYCRLDIRECTORY ] ; then
	mkdir $VERIFYCRLDIRECTORY
fi

get () {
	CRLNAME=$1
	CRLFILE=$2
        rm -f $CRLDIRECTORY/$CRLFILE
        printtoscreen "${EJBCA_HOME}/bin/ejbca.sh ca getcrl $CRLNAME $CRLDIRECTORY/$CRLFILE"
        ${EJBCA_HOME}/bin/ejbca.sh ca getcrl $CRLNAME $CRLDIRECTORY/$CRLFILE
	if [ $? != 0 -o  ! -r $CRLDIRECTORY/$CRLFILE  ] ; then
                printlogmess $ERROR $ERRNO_6 "$PUBL_DESCR_6" $CRLNAME
	fi
}

put () {

	CRLHOST=$1
        CRLNAME=$2
	SSHSERVER_DIR=$3
	SSHKEY=$4
	SSHUSER=$5

        cd $CRLDIRECTORY
        printtoscreen "scp -i $SSHKEY $CRLNAME $SSHUSER@$CRLHOST:$SSHSERVER_DIR"
#        scp -i $SSHKEY $CRLNAME $SSHUSER@$CRLHOST:$SSHSERVER_DIR
	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh $CRLNAME $CRLHOST $SSHSERVER_DIR
	if [ $? != 0 ] ; then
                printlogmess $ERROR $ERRNO_2 "$PUBL_DESCR_2" $CRLHOST $CRLNAME
	fi
}

### FOR NOW WE DO THIS HERE, next we should use syscheck who does this
checkcrl () {

	CRLHOST=$1
        CRLNAME=$2
	SSHSERVER_DIR=$3
	SSHKEY=$4
	SSHUSER=$5

        cd $VERIFYCRLDIRECTORY
        rm -f $VERIFYCRLDIRECTORY/$CRLNAME
        printtoscreen "scp -o ConnectTimeout=10 -i $SSHKEY $SSHUSER@${CRLHOST}:$SSHSERVER_DIR/$CRLNAME $VERIFYCRLDIRECTORY/$CRLNAME "
        scp -o ConnectTimeout=10 -i $SSHKEY $SSHUSER@${CRLHOST}:$SSHSERVER_DIR/$CRLNAME $VERIFYCRLDIRECTORY/$CRLNAME 
        if [ $? -ne 0 ] ; then
		printlogmess $ERROR $ERRNO_3 "$PUBL_DESCR_3" $CRLHOST $CRLNAME
                exit
        fi

# file not found where it should be
        if [ ! -f $VERIFYCRLDIRECTORY/$CRLNAME ] ; then
		printlogmess $ERROR $ERRNO_4 "$PUBL_DESCR_4" $CRLHOST $CRLNAME
                exit 1
        fi

        CRL_FILE_SIZE=`stat -c"%s" $VERIFYCRLDIRECTORY/$CRLNAME`
# stat return check
        if [ $? -ne 0 ] ; then
		printlogmess $ERROR $ERRNO_5 "$PUBL_DESCR_5" $CRLHOST $CRLNAME
                exit
        fi

# crl of 0 size?
        if [ "x$CRL_FILE_SIZE" = "x0" ] ; then
		printlogmess $ERROR $ERRNO_6 "$PUBL_DESCR_6" $CRLHOST $CRLNAME
                exit
        fi

# now we can check the crl:s best before date is in the future with atleast HOURTHRESHOLD hours (defined in resources)
        TEMPDATE=`openssl crl -inform der -in $CRLNAME -lastupdate -noout`
        DATE=${TEMPDATE:11}
        HOURSSINCEGENERATION=`${SYSCHECK_HOME}/lib/cmp_dates.pl "$DATE"`

        if [ "$HOURSSINCEGENERATION" -gt "$HOURTHRESHOLD" ] ; then
		printlogmess $ERROR $ERRNO_7 "$PUBL_DESCR_7" $CRLNAME $CRLHOST
        else
		printlogmess $INFO $ERRNO_1 "$PUBL_DESCR_1" $CRLHOST $CRLNAME
        fi
}

for (( i=0; i < ${#CANAME[@]} ; i++ )){

    get ${CANAME[$i]} "${CANAME[$i]}.crl"
    put ${VERIFY_HOST[$i]} "${CANAME[$i]}.crl" ${SSHSERVER_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]} 
    checkcrl ${VERIFY_HOST[$i]} "${CANAME[$i]}.crl" ${SSHSERVER_DIR[$i]} ${SSHKEY[$i]}  ${SSHUSER[$i]} 

}

#get ${CANAME2} "${CANAME2}.crl"
#put ${VERIFY_HOST2} "${CANAME2}.crl" ${SSHSERVER_DIR2} ${SSHKEY2}  ${SSHUSER2} 
#checkcrl ${VERIFY_HOST2} "${CANAME2}.crl" ${SSHSERVER_DIR2} ${SSHKEY2}  ${SSHUSER2} 



