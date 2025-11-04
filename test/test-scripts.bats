@test "scripts-available/sc_01_diskusage.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_01_diskusage.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^01-" | egrep "diskusage")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_02_ejbca.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_02_ejbca.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^02-" | egrep "ejbca")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_03_memory-usage.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_03_memory-usage.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^03-" | egrep "memoryusage")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_04_pcsc_readers.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_04_pcsc_readers.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^04-" | egrep "pcscreaders")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_05_pcscd.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_05_pcscd.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^05-" | egrep "pcscd")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_06_raid_check.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_06_raid_check.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^06-" | egrep "raidcheck")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_07_syslog.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_07_syslog.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^07-" | egrep "syslog")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_08_crl_from_webserver.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_08_crl_from_webserver.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^08-" | egrep "crl_from_webserver")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_09_firewall.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_09_firewall.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^09-" | egrep "firewall")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_10_ocsp.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_10_ocsp.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^10-" | egrep "ocsp")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_12_mysql.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_12_mysql.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^12-" | egrep "mysql")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_14_sw_raid.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_14_sw_raid.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^14-" | egrep "swraid")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_15_apache.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_15_apache.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^15-" | egrep "apache")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_16_ldap.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_16_ldap.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^16-" | egrep "ldap")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_17_ntp.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_17_ntp.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^17-" | egrep "ntp")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_18_sqlselect.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_18_sqlselect.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^18-" | egrep "sql_select")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_19_alive.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_19_alive.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^19-" | egrep "alive")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_20_errors_ejbcalog.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_20_errors_ejbcalog.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^20-" | egrep "ejbcaerrorlog")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_22_boks_replica.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_22_boks_replica.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^22-" | egrep "boks")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_23_rsa_axm.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_23_rsa_axm.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^23-" | egrep "rsa_axm")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_27_dss.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_27_dss.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^27-" | egrep "dss")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_28_check_vip.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_28_check_vip.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^28-" | egrep "vip")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_29_signserver.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_29_signserver.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^29-" | egrep "signserver")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_30_check_running_procs.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_30_check_running_procs.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^30-" | egrep "running_processes")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_31_hp_health.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_31_hp_health.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^31-" | egrep "hp_health")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_32_check_db_sync.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_32_check_db_sync.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^32-" | egrep "db_sync")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_33_healthchecker.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_33_healthchecker.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^33-" | egrep "healthcheck")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_34_redis.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_34_redis.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^34-" | egrep "redis")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_35_dell_raid.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_35_dell_raid.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^35-" | egrep "dell_raid")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_36_dell_health.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_36_dell_health.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^36-" | egrep "dell_health")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_37_monitor_jnlp.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_37_monitor_jnlp.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^37-" | egrep "jnlp_checker")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_38_mysql_connections.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_38_mysql_connections.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^38-" | egrep "mysql_connections")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_39_hsm_health.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_39_hsm_health.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^39-" | egrep "hsm_health")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_40_cluster.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_40_cluster.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^40-" | egrep "check_mysql")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_41_ra_verifier.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_41_ra_verifier.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^41-" | egrep "ra_verifier")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_42_receipts.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_42_receipts.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^42-" | egrep "receipts")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_43_rittal_rack_sensors.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_43_rittal_rack_sensors.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^43-" | egrep "rittal_rack_sensors")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

@test "scripts-available/sc_44_cert_from_webserver.sh" {
	run ${SYSCHECK_HOME}/scripts-available/sc_44_cert_from_webserver.sh  --screen
echo "script-output: ${lines[0]}" >&3
	line0=$(echo "${lines[0]}"  | egrep "^44-" | egrep "cert_from_webserver")
echo "match: ${line0}" >&3
	[ "${lines[0]}" = "$line0" ]
}

