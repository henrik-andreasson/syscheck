#!/bin/bash

. ${SYSCHECK_HOME}/lib/isdigit.sh

test_returnval(){
# test_returnval 1 0  0 "Number zero" 
	testcase=$1
	testarg=$2
	expectedresult=$3
	description=$4

	# test
	isdigit $testarg
	returns=$?
	testresult="UNDEF"

	if [ "x${returns}" = "x" ] ; then
		testresult="UNKNOWN(no result)"
	fi

	if [ "x${expectedresult}" = "x" ] ; then
		testresult="UNKNOWN(no expected result)"
	fi

	if [ ${expectedresult} = ${returns} ] ; then
		testresult="SUCCESS"
	else
		testresult="FAIL"
	fi

	printf "${testcase} ;${testarg} ;${expectedresult} ;${returns} ;${testresult} ; ${description} \n"

	
}

print_testheader(){
	printf "Test case   ; Test arg ;Expected return ; Returns ; Test Result ;Description\n"
}


printf "############### "
printf "Test of isdigit"
printf "############### \n"
print_testheader

test_returnval 1 0  0 "Number zero" 
test_returnval 4 99 0 "Number 99" 
test_returnval 2 0a 1 "negative test, embed a letter" 
test_returnval 3 a0 1 "negative test, add letter in the begining" 
test_returnval 4 -1 0 "Number -1" 


