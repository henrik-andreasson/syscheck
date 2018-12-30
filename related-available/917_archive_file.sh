#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

# Import common resources
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=archive_file

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=917




# how many info/warn/error messages
NO_OF_ERR=9
initscript $SCRIPTID $NO_OF_ERR



# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsv" --long "help,screen,verbose" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

KeepOrg=
if [ "x$1" =  "x--keep-org"  ] ; then
    shift
    KeepOrg=1
fi


if [ ! -d ${InTransitDir} ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[9]} "$ARCHIVE_DESCR[9]"
	exit -1
fi

# arg1
FileToArchive=
if [ "x$1" = "x" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "$ARCHIVE_DESCR[3]"
	exit -1
else
    FileToArchive=$1
fi

# arg2 hostname
ArchiveServer=
if [ "x$2" = "x"  ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "$ARCHIVE_DESCR[3]"
	exit -1
else
    ArchiveServer=$2
fi


# arg3 mandatory, eg.: "/store/logs/hostname/"
ArchiveDir=
if [ "x$3" = "x"  ] ; then
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[3]} "$ARCHIVE_DESCR[3]"
        exit -1
else
	ArchiveDir=$3
fi

# arg4 optional, if not specified the executing user will be used
SSHTOUSER=
if [ "x$4" != "x"  ] ; then
    SSHTOUSER="$4"
fi


# arg5 optional , if not specified the default key will be used
SSHFROMKEY=
if [ "x$5" != "x"  ] ; then
    SSHFROMKEY="$5"
fi

### func ... ###

moveToIntransit() {
	ShortFileName=$1
	reultFromLocalClaim=`mktemp -p ${InTransitDir} "${ShortFileName}.XXXXXXXXX" | grep  ${ShortFileName} `
	IntransitFileName=`basename $reultFromLocalClaim `

	if [ "x${IntransitFileName}" = "x" ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[8]} "$ARCHIVE_DESCR[8]" ${IntransitFileName}
		exit -1
	fi
# move the file into the intransit dir and give it a unique name
	if [ "x${KeepOrg}" = "x" ] ; then
	        printtoscreen "mv ${file} ${InTransitDir}/${IntransitFileName}"
       		mv ${file} ${InTransitDir}/${IntransitFileName}
	else
	        printtoscreen "cp ${file} ${InTransitDir}/${IntransitFileName}"
       		cp ${file} ${InTransitDir}/${IntransitFileName}
	fi

	if [ $? != 0 ] ; then
	 	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "$ARCHIVE_DESCR[2]" ${file} ${InTransitDir}/${IntransitFileName}
		exit -1
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[7]} "$ARCHIVE_DESCR[7]" ${file} ${InTransitDir}/${IntransitFileName}
		echo "${IntransitFileName}"
	fi
}

transferFile(){
	ShortFileName=$1
	IntransitFileName=$2

# claim the filename that the file is not already there
	printtoscreen "$SYSCHECK_HOME/related-available/915_remote_command_via_ssh.sh ${ArchiveServer} \"mktemp -p ${ArchiveDir} ${ShortFileName}.XXXXXXXXX\" ${SSHTOUSER} ${SSHFROMKEY}"
	reultFromClaim=`$SYSCHECK_HOME/related-available/915_remote_command_via_ssh.sh ${ArchiveServer} "mktemp -p ${ArchiveDir} ${ShortFileName}.XXXXXXXXX" ${SSHTOUSER} ${SSHFROMKEY}`
	if [ $? != 0 ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[4]} "$ARCHIVE_DESCR[4]"
		exit -1
	fi
	baseFile=`echo $reultFromClaim | grep ${ShortFileName}`
	remoteFileName=`basename $baseFile`

# transfer the file
 	printtoscreen "$SYSCHECK_HOME/related-available/906_ssh-copy-to-remote-machine.sh "${InTransitDir}/${IntransitFileName}" $ArchiveServer ${ArchiveDir}/${remoteFileName} $SSHTOUSER ${SSHFROMKEY}"
 	$SYSCHECK_HOME/related-available/906_ssh-copy-to-remote-machine.sh "${InTransitDir}/${IntransitFileName}" $ArchiveServer ${ArchiveDir}/${remoteFileName} $SSHTOUSER ${SSHFROMKEY}
	if [ $? != 0 ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[5]} "$ARCHIVE_DESCR[5]" "${InTransitDir}/${IntransitFileName} $ArchiveServer ${ArchiveDir}/${remoteFileName}"
		exit -1
	fi

	printtoscreen "$SYSCHECK_HOME/related-available/915_remote_command_via_ssh.sh ${ArchiveServer} \"md5sum ${ArchiveDir}/${remoteFileName}\" ${SSHTOUSER} ${SSHFROMKEY}"
	sshresult=`$SYSCHECK_HOME/related-available/915_remote_command_via_ssh.sh ${ArchiveServer} "md5sum ${ArchiveDir}/${remoteFileName}" ${SSHTOUSER} ${SSHFROMKEY}`
	if [ $? != 0 ] ; then
                printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[5]} "$ARCHIVE_DESCR[5]" "md5sum check failed"
		exit -1
	fi
	remoteMD5sum=`echo $sshresult | cut -f1 -d\  `
	localMD5sum=`md5sum ${InTransitDir}/${IntransitFileName} | cut -f1 -d\ `
	if [ "x${remoteMD5sum}" = "x" -o "x${localMD5sum}" = "x" -o ${remoteMD5sum} != ${localMD5sum} ] ; then
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[5]} "$ARCHIVE_DESCR[5]" "md5sum check failed"
                exit -1
	fi

# return the filename
        printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[6]} "$ARCHIVE_DESCR[6]" "${InTransitDir}/${IntransitFileName} $ArchiveServer ${ArchiveDir}/${remoteFileName}"
	echo "${remoteFileName}"
}

archiveLocally() {
	remoteFileName=$1
	if [ "x${remoteFileName}" = "x" ] ; then exit -1 ; fi
	IntransitFileName=$2
	if [ "x${IntransitFileName}" = "x" ] ; then exit -1 ; fi
# ensure local file is uniq (should be, but just in case)
	i=0
	while [ -r ${remoteFileName} ] ; do
		remoteFileName="${remoteFileName}.$i"
		i=`expr $i + 1`
	done

# move the file locally also
        printtoscreen "mv ${InTransitDir}/${IntransitFileName} ${ArchiveDir}/${remoteFileName}"
        mv ${InTransitDir}/${IntransitFileName} ${ArchiveDir}/${remoteFileName}
	if [ $? != 0 ] ; then
	 	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $ERROR ${ERRNO[2]} "$ARCHIVE_DESCR[2]" ${InTransitDir}/${IntransitFileName} ${ArchiveDir}/${remoteFileName}
		exit -1
	else
		printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $INFO ${ERRNO[1]} "$ARCHIVE_DESCR[1]" ${InTransitDir}/${IntransitFileName} ${ArchiveDir}/${remoteFileName}
	fi
}

#### end funcs #####


### loop over new files #####

for file in ${FileToArchive} ; do
	printtoscreen $ARCHIVE_PTS_1 $file
# it the file really there ?
	if [ ! -r $file ] ;  then
                printtoscreen "$ARCHIVE_PTS_3" $file
		continue
	fi

# get new filenames
	infile=`basename $file`
	datestr=`date +"%Y-%m-%d_%H.%M.%S"`
	ShortFileName="${datestr}_orgname__${infile}__"

	itFile=`moveToIntransit ${ShortFileName}`
	reFile=`transferFile ${ShortFileName} ${itFile}`
	archiveLocally ${reFile} ${itFile}
done


### loop over failed to transfer files ####

for file in $(ls ${InTransitDir}/* 2>/dev/null) ; do
	printtoscreen $ARCHIVE_PTS_2 $file
	infile=`basename $file`
        reFile=`transferFile ${infile} ${infile} `
        archiveLocally ${reFile} ${infile}
done
