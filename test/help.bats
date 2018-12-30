
debug(){
  echo "# ${lines[0]}" >&3
  echo "# ${lines[1]}" >&3
  echo "# ${lines[2]}" >&3
  echo "# ${lines[3]}" >&3

}

@test "syscheck.sh" {
    run ${SYSCHECK_HOME}/syscheck.sh --help
    [ "${lines[0]}" = "00 - Syscheck master script" ]

}


@test "logbook.sh" {
    run ${SYSCHECK_HOME}/logbook.sh --help
    line0=$(echo "${lines[0]}"  | grep "logbook.sh")
    [ "${lines[1]}" = "701 - Log book" ]
    [ "${lines[0]}" = "${line0}" ]

}

@test "getroot.sh" {
    run ${SYSCHECK_HOME}/getroot.sh --help
    line1=$(echo "${lines[2]}"  | grep "This is syscheck, getroot.sh")
    [ "${lines[0]}" = "700 - get root" ]
    [ "${lines[2]}" = "${line1}" ]

}
