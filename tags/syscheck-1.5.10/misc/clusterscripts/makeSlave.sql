STOP SLAVE;
CHANGE MASTER TO MASTER_HOST='147.186.2.226', MASTER_USER='ejbcarep', MASTER_PASSWORD='foo123', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=98;

START SLAVE;
