setup() {
  IFS=$'\n'
  export IFS
  SYSCHECK_CONSOLE_DATA=$(${SYSCHECK_HOME}/syscheck.sh --testall --screen)

}


@test "console systcheck 01 discusage" {
  line1=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^01-" | egrep "diskusage")
  [ "${line1}" != "" ]
}

@test "console systcheck 02 ejbca" {
  line2=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^02-" | egrep "ejbca")
  [ "${line2}" != "" ]
}

@test "console systcheck 03 memusage" {
  line3=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^03-" | egrep "memoryusage")
  [ "${line3}" != "" ]
}

@test "console systcheck 04 pcsc readers" {
  line4=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^04-" | egrep "Connected PCSC Readers")
  [ "${line}" != "" ]
}

@test "console systcheck 05 pcscd" {
  line5=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^05-" | egrep "pcscd")
  [ "${line5}" != "" ]
}

@test "console systcheck 06 raidcheck" {
  line6=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^06-" | egrep "raidcheck")
  [ "${line6}" != "" ]
}

@test "console systcheck 07 syslog" {
  line7=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^07-" | egrep "syslog")
  [ "${line7}" != "" ]
}

@test "console systcheck 08 crl from webserver" {
  line8=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^08-" | egrep "crl_from_webserver")
  [ "${line8}" != "" ]
}

@test "console systcheck 09 firewall" {
  line9=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^09-" | egrep "firewall")
  [ "${line9}" != "" ]
}

@test "console systcheck 12 mysql" {
  line10=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^12-" | egrep "mysql")
  [ "${line10}" != "" ]
}

@test "console systcheck 14 swraid" {
  line14=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^14-" | egrep "swraid")
  [ "${line14}" != "" ]
}

@test "console systcheck 15 apache" {
  line15=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^15-" | egrep "apache")
  [ "${line15}" != "" ]
}

@test "console systcheck 16 ldap" {
  line16=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^16-" | egrep "ldap")
  [ "${line16}" != "" ]
}

@test "console systcheck 17 ntp" {
  line17=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "ntp")
  [ "${line17}" != "" ]
}

@test "console systcheck 18 sqlselect" {
  line18=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^18-" | egrep "sql_select")
  [ "${line18}" != "" ]
}

@test "console systcheck 19 alive" {
  line19=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^19-" | egrep "alive")
  [ "${line19}" != "" ]
}

@test "console systcheck 20 errors_ejbca" {
  line20=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^20-" | egrep "errors_ejbca")
  [ "${line20}" != "" ]
}

@test "console systcheck 22 boks" {
  line22=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^22-" | egrep "boks")
  [ "${line22}" != "" ]
}

@test "console systcheck 23 rsa_axm" {
  line23=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^23-" | egrep "rsa_axm")
  [ "${line23}" != "" ]
}

@test "console systcheck 27 dss" {
  line27=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^27-" | egrep "dss")
  [ "${line27}" != "" ]
}

@test "console systcheck 28 vip" {
  line28=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^28-" | egrep "vip")
  [ "${line28}" != "" ]
}

@test "console systcheck 29 signserver" {
  line29=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^29-" | egrep "signserver")
  [ "${line29}" != "" ]
}

@test "console systcheck 30 running processes" {
  line30=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^30-" | egrep "check_running_procs")
  [ "${line30}" != "" ]
}

@test "console systcheck 31 hphealth" {
  line31=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^31-" | egrep "hp_health")
  [ "${line31}" != "" ]
}

@test "console systcheck 32 db_sync" {
  line32=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^32-" | egrep "db_sync")
  [ "${line32}" != "" ]
}

@test "console systcheck 33 healthchecker" {
  line33=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^33-" | egrep "healthchecker")
  [ "${line33}" != "" ]
}

@test "console systcheck 43 redis" {
  line34=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^34-" | egrep "redis")
  [ "${line34}" != "" ]
}

@test "console systcheck 35 dellraid" {
  line35=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^35-" | egrep "dell_raid")
  [ "${line35}" != "" ]
}

@test "console systcheck 36 dellhealth" {
  line36=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^36-" | egrep "dell_health")
  [ "${line36}" != "" ]
}
