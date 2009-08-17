#!/bin/sh

oldconfigdir=$1 
if [ "x$oldconfigdir" = "x" -o ! -f $oldconfigdir/01.conf ] ; then
	echo "arg1 should be the old config dir"
	exit	
fi
newconfigdir=$2 
if [ "x$newconfigdir" = "x" -o ! -f $newconfigdir/01.conf ] ; then
	echo "arg2 should be the new config dir"
	exit	
fi

for file in $(cd $newconfigdir ; ls ) ; do 
	diff -u $oldconfigdir/$file $newconfigdir/$file
	if [ $? -eq 0 ] ; then
		echo "files are identical ($file)"
		continue
	fi
	echo "copy this file? y/n default:n"
	read copy 
	if [ "x$copy" = "xy" -o "x$copy" = "xY" ] ; then
		mv $newconfigdir/$file $newconfigdir/$file.new
		cp $oldconfigdir/$file $newconfigdir/$file	
	else
		echo "did not copy $file (diff -u $oldconfigdir/$file $newconfigdir/$file)"
		cp $oldconfigdir/$file $newconfigdir/$file.old
	fi
done
