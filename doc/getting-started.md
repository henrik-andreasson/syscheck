## Upgrade


### Unpack


        username@smartcard20-node1:/usr/local/# unzip  /var/tmp/syscheck-1.5.15.zip
        [...]

### Migration of config from a previous version


If migrating a host to new hardware make a backup of syscheck to be transferred to the new hardware.

        root@smartcard20-node1:/usr/local # zip -r9 /tmp/syscheck-backup-x.y.z.zip syscheck-x.y.z

Transfer the zip to the new host, then unpack the backup.

        root@smartcard20-node1:/usr/local # unzip /tmp/syscheck-backup-x.y.z.zip

Copy enabled scripts

        root@smartcard20-node1:/usr/local/syscheck # cp -a ../syscheck-<last-version>/related-enabled/* ./ related-enabled/
        root@smartcard20-node1:/usr/local/syscheck # cp -a ../syscheck-<last-version>/scritps-enabled/* ./ scritps-enabled/

Run the copy config command to loop through the configs and check wheter you want to use ther old or the new config.
Tip: Use the old if it's configured and only differs to the new config is the values you entered. Is there new options you need, use the new one and migrate the config manually

        root@smartcard20-node1:/usr/local/syscheck # ./lib/copy-config-from-old-version.sh /path/to/old/syscheck-<last-version>/config ./config/
