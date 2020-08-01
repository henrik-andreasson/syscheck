
# Syscheck - Install

## Changes

|Version   |Author             |Date        |Comment                      |
|----------|-------------------|------------|-----------------------------|
| 1.0      | Henrik Andreasson | 2016-11-27 | Initial version             |
| 1.1      | Henrik Andreasson | 2020-07-31 | mkdocs updates              |


### manually

untar the distribution in a suitable directory (default /usr/local/syscheck).
Then edit config/common.conf config/xxx.conf (where xxx is ther scriptid) to fit your needs.

### packaged (rpm and deb)


Download the rpm/deb from github

rpm -Uvh syscheck-<version>.rpm

dpkg -i syscheck-<version>.deb
