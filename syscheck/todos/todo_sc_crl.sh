#!/bin/sh


#Import  common resources
. resources.sh


wget $CRLFETCH_URL -T 10 -t 1 -o /tmp/crlcheck.crl

if [  -e /tmp/crlcheck.crl ] 
then
  echo "CRL not fetched"
  exit -1
fi

TEMPDATE=`openssl crl -inform der -in /tmp/crlcheck.crl -lastupdate -noout`
DATE=${TEMPDATE:11}
echo $DATE


HOURSSINCEGENERATION=`/usr/local/syscheck/cmp_dates.pl "$DATE"`

if [ "$HOURSSINCEGENERATION" -gt "$HOURTHRESHOLD" ] 
then
  echo "CRL not Updated"
else
  echo "CRL Updated"
fi


