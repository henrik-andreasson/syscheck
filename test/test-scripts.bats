debug(){
  echo "# ${lines[0]}" >&3
  echo "# ${lines[1]}" >&3
  echo "# ${lines[2]}" >&3
  echo "# ${lines[3]}" >&3

}

@test scripts-available/sc_01_diskusage.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_01_diskusage.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^01-" | egrep "diskusage")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_02_ejbca.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_02_ejbca.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^02-" | egrep "ejbca")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_03_memory-usage.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_03_memory-usage.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^03-" | egrep "memoryusage")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_04_pcsc_readers.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_04_pcsc_readers.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^04-" | egrep "pcscreaders")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_05_pcscd.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_05_pcscd.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^05-" | egrep "pcscd")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_06_raid_check.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_06_raid_check.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^06-" | egrep "raidcheck")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_07_syslog.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_07_syslog.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^07-" | egrep "syslog")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_08_crl_from_webserver.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_08_crl_from_webserver.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^08-" | egrep "crl_from_webserver")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_09_firewall.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_09_firewall.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^09-" | egrep "firewall")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_12_mysql.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_12_mysql.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^12-" | egrep "mysql")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_14_sw_raid.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_14_sw_raid.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^14-" | egrep "swraid")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_15_apache.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_15_apache.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^15-" | egrep "apache")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_16_ldap.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_16_ldap.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^16-" | egrep "ldap")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_17_ntp.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_17_ntp.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^17-" | egrep "ntp")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_18_sqlselect.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_18_sqlselect.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^18-" | egrep "sql_select")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_19_alive.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_19_alive.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^19-" | egrep "alive")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_20_errors_ejbcalog.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_20_errors_ejbcalog.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^20-" | egrep "ejbcaerrorlog")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_22_boks_replica.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_22_boks_replica.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^22-" | egrep "boks")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_23_rsa_axm.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_23_rsa_axm.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^23-" | egrep "rsa_axm")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_27_dss.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_27_dss.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^27-" | egrep "dss")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_28_check_vip.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_28_check_vip.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^28-" | egrep "vip")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_29_signserver.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_29_signserver.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^29-" | egrep "signserver")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_30_check_running_procs.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_30_check_running_procs.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^30-" | egrep "running_processes")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_31_hp_health.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_31_hp_health.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^31-" | egrep "hp_health")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_32_check_db_sync.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_32_check_db_sync.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^32-" | egrep "db_sync")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_33_healthchecker.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_33_healthchecker.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^33-" | egrep "healthcheck")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_34_redis.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_34_redis.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^34-" | egrep "redis")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_35_dell_raid.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_35_dell_raid.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^35-" | egrep "dell_raid")
	[ "${lines[0]}" = "$line0" ]
}

@test scripts-available/sc_36_dell_health.sh {
	run ${SYSCHECK_HOME}/scripts-available/sc_36_dell_health.sh  --screen
	line0=$(echo "${lines[0]}"  | egrep "^36-" | egrep "dell_health")
	[ "${lines[0]}" = "$line0" ]
}
