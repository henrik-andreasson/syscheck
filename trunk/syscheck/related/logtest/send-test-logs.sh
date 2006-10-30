#!/bin/sh

chkvalue="${RANDOM}_$$"

check_log(){
        target=$1
        file=$2
        mess=$3

        logger -p ${target} "${mess}" 
        /bin/echo -e  "grep \"$mess\" $file || echo \"target $target/$file FAILED\" && echo \"target $target/$file OK\" >> /tmp/log-check-test$$ "

}

check_log local3.info /var/log/syscheck.info "chkvalue: ${chkvalue} detta borde hamna i syscheck.info"
check_log local3.warn /var/log/syscheck.warn "chkvalue: ${chkvalue} detta borde hamna i syscheck.warn"
check_log local3.err  /var/log/syscheck.err  "chkvalue: ${chkvalue} detta borde hamna i syscheck.err"
check_log local3.crit /var/log/syscheck.err  "chkvalue: ${chkvalue} detta borde hamna i syscheck.err (crit)"

check_log local4.info /var/log/ejbca.info "chkvalue: ${chkvalue} detta borde hamna i ejbca.info"
check_log local4.warn /var/log/ejbca.warn "chkvalue: ${chkvalue} detta borde hamna i ejbca.warn"
check_log local4.err  /var/log/ejbca.err  "chkvalue: ${chkvalue} detta borde hamna i ejbca.err"
check_log local4.crit /var/log/ejbca.err  "chkvalue: ${chkvalue} detta borde hamna i ejbca.err (crit)"

check_log local5.info /var/log/boks.info "chkvalue: ${chkvalue} detta borde hamna i boks.info"
check_log local5.warn /var/log/boks.warn "chkvalue: ${chkvalue} detta borde hamna i boks.warn"
check_log local5.err  /var/log/boks.err  "chkvalue: ${chkvalue} detta borde hamna i boks.err"
check_log local5.crit /var/log/boks.err  "chkvalue: ${chkvalue} detta borde hamna i boks.err (crit)"

check_log local6.info /var/log/cleartrust.info "chkvalue: ${chkvalue} detta borde hamna i cleartrust.info"
check_log local6.warn /var/log/cleartrust.warn "chkvalue: ${chkvalue} detta borde hamna i cleartrust.warn"
check_log local6.err  /var/log/cleartrust.err  "chkvalue: ${chkvalue} detta borde hamna i cleartrust.err"
check_log local6.crit /var/log/cleartrust.err  "chkvalue: ${chkvalue} detta borde hamna i cleartrust.err (crit)"


check_log local7.info /var/log/dss.info "chkvalue: ${chkvalue} detta borde hamna i dss.info"
check_log local7.warn /var/log/dss.warn "chkvalue: ${chkvalue} detta borde hamna i dss.warn"
check_log local7.err  /var/log/dss.err  "chkvalue: ${chkvalue} detta borde hamna i dss.err"
check_log local7.crit /var/log/dss.err  "chkvalue: ${chkvalue} detta borde hamna i dss.err (crit)"

