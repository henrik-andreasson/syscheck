

@test "all scripts - console systcheck" {
  IFS=$'\n'
  export IFS
  SYSCHECK_CONSOLE_DATA=$(${SYSCHECK_HOME}/syscheck.sh --testall --screen)

  line1=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^01-" | egrep "diskusage")
  [ "${line1}" != "" ]
  line2=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^02-" | egrep "ejbca")
  [ "${line2}" != "" ]
  line3=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^03-" | egrep "memoryusage")
  [ "${line3}" != "" ]
  line4=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^04-" | egrep "pcscreaders")
  [ "${line}" != "" ]
  line5=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^05-" | egrep "pcscd")
  [ "${line5}" != "" ]
  line6=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^06-" | egrep "raidcheck")
  [ "${line6}" != "" ]
  line7=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^07-" | egrep "syslog")
  [ "${line7}" != "" ]
  line8=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^08-" | egrep "crl_from_webserver")
  [ "${line8}" != "" ]
  line9=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^09-" | egrep "firewall")
  [ "${line9}" != "" ]
  line10=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^12-" | egrep "mysql")
  [ "${line10}" != "" ]
  line14=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^14-" | egrep "swraid")
  [ "${line14}" != "" ]
  line15=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^15-" | egrep "apache")
  [ "${line15}" != "" ]
  line16=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^16-" | egrep "ldap")
  [ "${line16}" != "" ]
  line17=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "ntp")
  [ "${line17}" != "" ]
  line18=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^18-" | egrep "sql_select")
  [ "${line18}" != "" ]
  line19=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^19-" | egrep "alive")
  [ "${line19}" != "" ]
  line20=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^20-" | egrep "errors_ejbca")
  [ "${line20}" != "" ]
  line22=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^22-" | egrep "boks")
  [ "${line22}" != "" ]
  line23=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^23-" | egrep "rsa_axm")
  [ "${line23}" != "" ]
  line27=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^27-" | egrep "dss")
  [ "${line27}" != "" ]
  line28=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^28-" | egrep "vip")
  [ "${line28}" != "" ]
  line29=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^29-" | egrep "signserver")
  [ "${line29}" != "" ]
  line30=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^30-" | egrep "check_running_procs")
  [ "${line30}" != "" ]
  line31=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^31-" | egrep "hp_health")
  [ "${line31}" != "" ]
  line32=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^32-" | egrep "db_sync")
  [ "${line32}" != "" ]
  line33=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "healthchecker")
  [ "${line33}" != "" ]
  line34=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^34-" | egrep "redis")
  [ "${line34}" != "" ]
  line35=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^35-" | egrep "dell_raid")
  [ "${line35}" != "" ]
  line36=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "dell_health")
  [ "${line36}" != "" ]
}
