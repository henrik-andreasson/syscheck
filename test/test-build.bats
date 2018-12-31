

@test "build syscheck rpm " {

  rm -rf /results/syscheck-snapshot-1.x86_64.rpm
  cd /source/
  cp -ra /source/ /work
  cd /work
  /work/lib/release.sh  --program syscheck --version snapshot --outpath /results
  run stat -c "%s" /results/syscheck-snapshot-1.x86_64.rpm
  [ "${status}" != 0 ]
  [ "${lines[0]}" -gt 0 ]

}

@test "build syscheck deb " {

  rm -rf /results/syscheck*deb
  ./lib/release.sh  --program syscheck --version snapshot --outpath /results
  run stat -c "%s" /results/syscheck_snapshot*deb
  [ "${status}" != 0 ]
  [ "${lines[0]}" -gt 0 ]

}

@test "build syscheck zip " {

  rm -rf /results/syscheck*deb
  ./lib/release.sh  --program syscheck --version snapshot --outpath /results
  run stat -c "%s" /results/syscheck_snapshot*deb
  [ "${status}" != 0 ]
  [ "${lines[0]}" -gt 0 ]


}
