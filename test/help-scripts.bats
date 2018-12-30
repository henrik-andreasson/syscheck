@test scripts-available/sc_01_diskusage.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_01_diskusage.sh  --help
	line0=$(echo "${lines[0]}"  | grep "01 - Disk usage")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_02_ejbca.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_02_ejbca.sh  --help
	line0=$(echo "${lines[0]}"  | grep "02 - EJBCA Health check")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_03_memory-usage.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_03_memory-usage.sh  --help
	line0=$(echo "${lines[0]}"  | grep "03 - Memory usage")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_04_pcsc_readers.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_04_pcsc_readers.sh  --help
	line0=$(echo "${lines[0]}"  | grep "04 - Connected PCSC Readers")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_05_pcscd.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_05_pcscd.sh  --help
	line0=$(echo "${lines[0]}"  | grep "05 - pcscd is running")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_06_raid_check.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_06_raid_check.sh  --help
	line0=$(echo "${lines[0]}"  | grep "06 - HP Raid check")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_07_syslog.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_07_syslog.sh  --help
	line0=$(echo "${lines[0]}"  | grep "07 - Check if syslog if running")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_08_crl_from_webserver.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_08_crl_from_webserver.sh  --help
	line0=$(echo "${lines[0]}"  | grep "08 - Download CRL from Webserver and check its validity")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_09_firewall.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_09_firewall.sh  --help
	line0=$(echo "${lines[0]}"  | grep "09 - Firewall iptables")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_12_mysql.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_12_mysql.sh  --help
	line0=$(echo "${lines[0]}"  | grep "12 - Mysql server")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_14_sw_raid.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_14_sw_raid.sh  --help
	line0=$(echo "${lines[0]}"  | grep "14 - SW Raid")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_15_apache.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_15_apache.sh  --help
	line0=$(echo "${lines[0]}"  | grep "15 - Apache Web server")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_16_ldap.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_16_ldap.sh  --help
	line0=$(echo "${lines[0]}"  | grep "16 - LDAP Server")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_17_ntp.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_17_ntp.sh  --help
	line0=$(echo "${lines[0]}"  | grep "17 - NTP in sync")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_18_sqlselect.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_18_sqlselect.sh  --help
	line0=$(echo "${lines[0]}"  | grep "18 - Mysql Select")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_19_alive.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_19_alive.sh  --help
	line0=$(echo "${lines[0]}"  | grep "19 - Server is alive")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_20_errors_ejbcalog.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_20_errors_ejbcalog.sh  --help
	line0=$(echo "${lines[0]}"  | grep "20 - EJBCA Error log checker")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_22_boks_replica.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_22_boks_replica.sh  --help
	line0=$(echo "${lines[0]}"  | grep "22 - BOKS")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_23_rsa_axm.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_23_rsa_axm.sh  --help
	line0=$(echo "${lines[0]}"  | grep "23 - RSA Access Manager")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_27_dss.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_27_dss.sh  --help
	line0=$(echo "${lines[0]}"  | grep "27 - SignServer")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_28_check_vip.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_28_check_vip.sh  --help
	line0=$(echo "${lines[0]}"  | grep "28 - VIP")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_29_signserver.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_29_signserver.sh  --help
	line0=$(echo "${lines[0]}"  | grep "29 - SignServer health checker")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_30_check_running_procs.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_30_check_running_procs.sh  --help
	line0=$(echo "${lines[0]}"  | grep "30 - Running processes")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_31_hp_health.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_31_hp_health.sh  --help
	line0=$(echo "${lines[0]}"  | grep "31 - HP Server health check")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_32_check_db_sync.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_32_check_db_sync.sh  --help
	line0=$(echo "${lines[0]}"  | grep "32 - EJBCA DB Sync")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_33_healthchecker.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_33_healthchecker.sh  --help
	line0=$(echo "${lines[0]}"  | grep "33 - Check Health of tomcat applications")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_34_redis.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_34_redis.sh  --help
	line0=$(echo "${lines[0]}"  | grep "34 - Redis")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_35_dell_raid.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_35_dell_raid.sh  --help
	line0=$(echo "${lines[0]}"  | grep "35 - Dell Hard drive checker")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_36_dell_health.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_36_dell_health.sh  --help
	line0=$(echo "${lines[0]}"  | grep "36 - Dell Server system components")
	[ "${lines[0]}" = "$line0" ]
}

