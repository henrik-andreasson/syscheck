Syscheck component cmp_dates.pl
=======================================

Introduction
------------

Input is to dates in UTC to be compared and the number of minutes is returned.

Examples
------------

   Force TimeZone to be UTC:
	export TZ=UTC

   Example to fixed dates:
	$SYSCHECK_HOME/lib/cmp_dates.pl '2014-05-20 07:43:18 UTC' '2014-05-20 07:33:18 UTC'
	10

   Compare a date with the current time:
	$SYSCHECK_HOME/lib/cmp_dates.pl '2014-05-20 07:33:18 UTC' "$(date -u +"%Y-%m-%d %H:%M:%S %Z")" 
	197


