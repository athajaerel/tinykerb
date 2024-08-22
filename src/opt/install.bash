#!/bin/bash
set -euo pipefail

echo Realm: ${REALM}

DOMAIN=$(<<<${REALM} tr '[:upper:]' '[:lower:]')

mkdir -p /var/krb5kdc
kdb5_util create -r ${REALM} -s -P ${PW_MASTER}

kadmin.local -r ${REALM} -p ${USER_ADMIN} addpol users
kadmin.local -r ${REALM} -p ${USER_ADMIN} addpol admin
kadmin.local -r ${REALM} -p ${USER_ADMIN} addpol hosts

kadmin.local -r ${REALM} -p ${USER_ADMIN} ank -pw ${PW_ADMIN} -policy admin ${USER_ADMIN}@${REALM}

# Useless use of cat below, but I can do this or install yet another package. Not worth it.
botan rng --format=base64 100 >/etc/tls/ca-pw.txt
truncate -s -1 /etc/tls/ca-pw.txt
botan keygen --algo=RSA --params=2048 --passphrase="$(cat /etc/tls/ca-pw.txt)" >/etc/tls/ca.key
botan gen_self_signed /etc/tls/ca.key "PKINIT CA" --ca --days=365 --path-limit=2 --country=GB --organization="Kerberos" --key-pass="$(cat /etc/tls/ca-pw.txt)" >/etc/tls/ca.crt

botan keygen --algo=RSA --params=2048 >/etc/tls/kdc.key
botan gen_self_signed /etc/tls/kdc.key "${REALM}" --days=365 --path-limit=2 --country=GB --organization="K3S.LAB" >/etc/tls/kdc.crt

chmod 0400 /etc/tls/ca-pw.txt
chmod 0400 /etc/tls/ca.key
chmod 0444 /etc/tls/ca.crt
chmod 0400 /etc/tls/kdc.key
chmod 0444 /etc/tls/kdc.crt

krb5kdc -n -p 10088 -P /var/run/krb5-kdc.pid &
sleep 2

N=$(ss -H4lnt state listening src 0.0.0.0:10088 | wc -l)
[ ${N} -eq 0 ] && exit 1
echo "Port detected ok"
sleep 2

expect /opt/expect.exp

klist -c ${CCFILE}
kadmin.local -c ${CCFILE} ktadd -k ${KADM_KEYTAB} ${KCHP_PRINC} ${KADM_PRINC}
kdestroy -A -c ${CCFILE}

kill $(cat /var/run/krb5-kdc.pid)
