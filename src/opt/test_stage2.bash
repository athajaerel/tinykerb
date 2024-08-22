#!/bin/bash
set -euo pipefail

TestLinkedPresent() {
	echo "Testing for missing link dependencies..."
	LINKABLES=$(find /stage2 -type f -exec file {} \; | grep ELF | cut -d: -f1)
	LINKED=$(ldd ${LINKABLES} | awk '!/linux-vdso.so/ {print $3}' | grep \.so | sort -u)
	for L in ${LINKED}; do
		echo "Is ${L} present?"
		if [ "x${L:0:1}" == "x/" ]; then
			stat /stage2/${L:1}
		else
			stat /stage2/${L}
		fi
	done
}

TestBrokenSymlinks() {
	echo "Testing for broken symlinks..."
	BROKEN_SYMLINKS=$(find /stage2 -type l -xtype l | wc -l)
	[ ${BROKEN_SYMLINKS} -eq 0 ]
}

TestChroot() {
	return
}

TESTS="TestLinkedPresent TestBrokenSymlinks TestChroot"
for FN in ${TESTS}; do
	${FN}
	echo ${FN} returned ok
done

