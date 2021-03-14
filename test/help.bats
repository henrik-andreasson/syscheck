
debug(){
  echo "# ${lines[0]}" >&3
  echo "# ${lines[1]}" >&3
  echo "# ${lines[2]}" >&3
  echo "# ${lines[3]}" >&3

}
@test "syscheck.sh" {
    run ${SYSCHECK_HOME}/syscheck.sh --help
    [ "${lines[0]}" = "Scriptid: 00 - Syscheck master script" ]

}


@test "logbook.sh" {
    run ${SYSCHECK_HOME}/logbook.sh --help
    line0=$(echo "${lines[0]}"  | grep "logbook.sh")
    [ "${lines[1]}" = "Scriptid: 701 - Log book" ]
    [ "${lines[0]}" = "${line0}" ]

}

@test "getroot.sh" {
    run ${SYSCHECK_HOME}/getroot.sh --help
    [ "${lines[0]}" = "Scriptid: 700 - get root" ]
    [ "${lines[1]}" = "This is syscheck, getroot.sh it ask for a reason to get root, logs it then asks if syscheck scripts should be put on hold." ]

}
