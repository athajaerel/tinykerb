#!/bin/bash
set -euo pipefail

# $1: path
get_type() {
	file $1 | cut -d: -f2 | tr -d ' '
}

# $1: path
copy_file() {
	echo Copying $1
	mkdir -p $(dirname ${1:1})
	cp -Lpr $1 ${1:1}
}

# have to copy this one manually
copy_file /lib64/ld-linux-x86-64.so.2

while read F
do
	T=$(get_type ${F})
	if [ "x${T}" == "xdirectory" ]; then
		continue
	fi
	if [ "x${T:0:6}" == "xcannot" ]; then
		continue
	fi
	if [ "x${T:0:6}" == "xbroken" ]; then
		continue
	fi
	copy_file ${F}
	# get deps
	if [ "x${T:0:9}" == "xELF64-bit" ]; then
		/usr/bin/ldd ${F} | awk '$3!="" {print $3}' | while read src
		do
			T=$(get_type ${src})
			if [ "x${T}" == "xdirectory" ]; then
				continue
			fi
			if [ "x${T:0:6}" == "xcannot" ]; then
				continue
			fi
			if [ "x${T:0:6}" == "xbroken" ]; then
				continue
			fi
			copy_file ${src}
		done
	fi
done
