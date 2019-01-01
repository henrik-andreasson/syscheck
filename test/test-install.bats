debug(){

  for line in ${lines[*]} ; do
      echo "# ${line}" >&3
  done
}

@test "install systcheck" {

  rpm -e syscheck

  run rpm -Uvh /results/syscheck-snapshot-1.x86_64.rpm


  [ "${status}" == 0 ]

}
