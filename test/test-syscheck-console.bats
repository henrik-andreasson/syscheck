debug(){
  echo "# ${lines[0]}" >&3
  echo "# ${lines[1]}" >&3
  echo "# ${lines[2]}" >&3
  echo "# ${lines[3]}" >&3

}

SYSCHECK_CONSOLE_DATA=


setup(){
 IFS=$'\n'
 SYSCHECK_CONSOLE_DATA=$(${SYSCHECK_HOME}/syscheck.sh --testall --screen)
 echo "# $SYSCHECK_CONSOLE_DATA"
}

@test "all scripts - 01 diskusage" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^01-" | egrep "diskusage")
  [ "${line}" != "" ]
}

@test "all scripts - 02 ejbca" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^02-" | egrep "ejbca")
  [ "${line}" != "" ]
}
@test "all scripts - 03 memoryusage" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^03-" | egrep "memoryusage")
  [ "${line}" != "" ]
}
@test "all scripts - 04 pcscreaders" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^04-" | egrep "pcscreaders")
  [ "${line}" != "" ]
}
@test "all scripts - 05 pcscd" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^05-" | egrep "pcscd")
  [ "${line}" != "" ]
}
@test "all scripts - 06 raidcheck" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^06-" | egrep "raidcheck")
  [ "${line}" != "" ]
}
@test "all scripts - 07 syslog" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^07-" | egrep "syslog")
  [ "${line}" != "" ]
}
@test "all scripts - 08 crl_from_webserver" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^08-" | egrep "crl_from_webserver")
  [ "${line}" != "" ]
}
@test "all scripts - 09 firewall" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^09-" | egrep "firewall")
  [ "${line}" != "" ]
}
@test "all scripts - 12 mysql" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^12-" | egrep "mysql")
  [ "${line}" != "" ]
}
@test "all scripts - 14 swraid" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^14-" | egrep "swraid")
  [ "${line}" != "" ]
}
@test "all scripts - 15 apache" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^15-" | egrep "apache")
  [ "${line}" != "" ]
}
@test "all scripts - 16 ldap" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^16-" | egrep "ldap")
  [ "${line}" != "" ]
}
@test "all scripts - 17 ntp" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "ntp")
  [ "${line}" != "" ]
}
@test "all scripts - 18 sqlselect" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^18-" | egrep "sql_select")
  [ "${line}" != "" ]
}
@test "all scripts - 19 alive" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^19-" | egrep "alive")
  [ "${line}" != "" ]
}
@test "all scripts - 20 errors_ejbcalog" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^20-" | egrep "errors_ejbca")
  [ "${line}" != "" ]
}
@test "all scripts - 22 boks" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^22-" | egrep "boks")
  [ "${line}" != "" ]
}
@test "all scripts - 23 rsa axm" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^23-" | egrep "rsa_axm")
  [ "${line}" != "" ]
}
@test "all scripts - 27 dss" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^27-" | egrep "dss")
  [ "${line}" != "" ]
}
@test "all scripts - 28 check vip" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^28-" | egrep "vip")
  [ "${line}" != "" ]
}
@test "all scripts - 29 signserver" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^29-" | egrep "signserver")
  [ "${line}" != "" ]
}
@test "all scripts - 30 check_running_procs" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^30-" | egrep "check_running_procs")
  [ "${line}" != "" ]
}
@test "all scripts - 31 hp health" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^31-" | egrep "hp_health")
  [ "${line}" != "" ]
}
@test "all scripts - 32 dbsync" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^32-" | egrep "db_sync")
  [ "${line}" != "" ]
}
@test "all scripts - 33 healthchecker" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "healthchecker")
  [ "${line}" != "" ]
}
@test "all scripts - 34 redis" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^34-" | egrep "redis")
  [ "${line}" != "" ]
}
@test "all scripts - 35 dell raid" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^35-" | egrep "dell_raid")
  [ "${line}" != "" ]
}
@test "all scripts - 36 dell health" {
  line=$(echo "${SYSCHECK_CONSOLE_DATA}"  | egrep "^17-" | egrep "dell_health")
  [ "${line}" != "" ]
}
