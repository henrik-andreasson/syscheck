changeDBHostToMaster.sh                 - dumpd db on node2 transfers it to node 1 and changes jboss configuration on both nodes to point to node1
changeDBHostToSlave.sh                  - changes jboss configuration on both nodes to point to node2
checkConnectionToMaster.sh              - dont use ?
createDBPriviledges.sh                  - creates "ejbca" user inside mysql with correct rights
createPriviledgesNode1.sql              - sql -- "" -- 
createPriviledgesNode1.sql.templ        - -- "" --
createPriviledgesNode2.sql              - -- "" --
createPriviledgesNode2.sql.templ        - -- "" --
createTestTable.sql                     - test table used by cluster scripts
createTestTableOnMaster.sh              - -- "" --
ejbca-ds-node1.xml                      - xml file that points jboss datasource to node1
ejbca-ds-node1.xml.templ                - -- "" -- template used by cluster scripts
ejbca-ds-node2.xml                      - xml file that points jboss datasource to node 2
ejbca-ds-node2.xml.templ                - -- "" -- template used by cluster scripts
makeMaster.sql                          - sql that changes a node to become a master mysql-server
makeSlave.sql                           - sql that changes a node to become a slave  mysql-server
makeSlave.sql.templ                     - -- "" -- template
markNode1AsActive.sh                    - dont use ?
markNode2AsActive.sh                    - dont use ?
recreateEJBCADB.sql                     - is not used
resetMaster.sql                         - sql "reset Master"
sync_cluster.sh                         - dont use
testMaster.sql                          - sql that reads from "test" table

