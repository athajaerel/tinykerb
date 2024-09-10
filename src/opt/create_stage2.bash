#!/bin/bash
#set -uo pipefail

# $1: package
stage_package_files() {
	FILES=$(apt-file list $1 | cut -d: -f2- | tr -d ' ')
	echo Adding $FILES
	<<<${FILES} tee -a /opt/copylist.txt >/dev/null
	set +e
	DEPS=$(ldd $FILES 2>/dev/null | awk '/\.so/{print $3}' | sort -u)
	set -e
	echo Adding $DEPS
	<<<${DEPS} tee -a /opt/copylist.txt >/dev/null
}

# $1: directory path (no file)
create_path_if() {
	set +e
	# Oddly, neither mkdir nor install can do this
	# mkdir and install /really/ hate symlinks
	>/dev/null 2>/dev/null stat $1
	if [ $? -eq 0 ]; then
		return
	fi
	echo "Create path: $1"
	PARENT=$(dirname $1)
	STAT=$(2>/dev/null stat ${PARENT})
	if [ "x${STAT}" == "x" ]; then
		echo "Recursing"
		create_path_if ${PARENT}
	fi
	echo "${PARENT} exists, making $1"
	#ls -la ${PARENT}
	mkdir $1  # deliberately no -p
	#ls -la $1
	#install -d $1
}

# no container works without these
cat <<EOF >/opt/mandatory.txt
/lib64/ld-linux-x86-64.so.2
EOF

while read -d' ' PKG
do
	echo "Staging: ${PKG}"
	stage_package_files "${PKG}"
done <<<"${STAGE_PKGS} "
# not a typo, the extra space gets the last item ^^

# these will make the app work
cat <<EOF >/opt/nominated.txt
/etc/krb5.conf
/etc/krb5kdc/kdc.conf
/etc/krb5kdc/stash
/var/krb5kdc/kadm5.acl
/var/krb5kdc/principal
/var/krb5kdc/principal.kadm5
/var/krb5kdc/principal.kadm5.lock
/var/krb5kdc/principal.ok
/var/krb5kdc/kadm5.keytab
/etc/tls/ca-pw.txt
/etc/tls/ca.key
/etc/tls/ca.crt
/etc/tls/kdc.key
/etc/tls/kdc.crt
/bin/bash
/usr/bin/dd
/lib/x86_64-linux-gnu/libtinfo.so.6
/lib/x86_64-linux-gnu/libtinfo.so.6.4
/lib/x86_64-linux-gnu/libc.so.6
/etc/localtime
EOF

PRUNELIST="
/usr/share/doc
/usr/share/examples
/usr/share/licenses
/usr/share/lintian
/usr/share/locale
/usr/share/man
/lib/expect5.45.4
/lib/itcl4.2.4
/lib/thread2.8.9
/lib/python3.12
/lib/tdbcmysql1.1.7
/lib/tdbcodbc1.1.7
/lib/tdbcpostgres1.1.7
/lib/tdbc1.1.7
/lib/tcl8.6
/lib/tcl8
/lib/tc
/lib/systemd
/etc/sv
"

COPYLIST=$(cat /opt/copylist.txt /opt/nominated.txt /opt/mandatory.txt)

while read ITEM; do
	if [ "x${ITEM}" == "x" ]; then
		continue
	fi
	CL1=$(<<<${COPYLIST} sed -e "s;^.*${ITEM}.*$;;g")
	COPYLIST=${CL1}
done <<<"${PRUNELIST}"

for FILE in ${COPYLIST}
do
	echo "Copying file: ${FILE}"
	DEST=$(dirname ${FILE})
	create_path_if "/stage2/${DEST:1}"
	FNAME=$(basename ${FILE})
	install ${FILE} /stage2/${DEST:1}/${FNAME}
	echo "Copied file ${FILE}"
done
