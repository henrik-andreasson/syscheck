# Syscheck config management via ansible


## Changes

|Version   |Author             |Date        |Comment                      |
|----------|-------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2020-11-01 | Initial version             |


## Configuration Management - ansible

syscheck is configurable with ansible.

## configure

Look at misc/ansible/roles/defaults/main.yml for variables you'd like to customize

Then enter them into host_vars or group_vars

## running

put every ting in /misc/ansible or another directory of your choosing

    ansible-playbook -i /misc/ansible/hosts --limit=host.srv.domain.com -vv /misc/ansible/playbook-syscheck --user username --ask-become --become --become-method=su   --private-key
=/home/user/.ssh/id_rsa  --connection=ssh
