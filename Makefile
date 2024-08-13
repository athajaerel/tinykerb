id:=localhost/tinykerb
pkgs:=krb5-admin-server krb5-config krb5-k5tls krb5-kdc krb5-kdc-ldap krb5-kpropd krb5-locales krb5-otp krb5-pkinit krb5-sync-tools krb5-user

$(pkgs):
	/usr/bin/apt-file list $@ | cut -d: -f2- | tr -d ' ' | ./copy_with_deps.bash

prepdirs:
	mkdir -p ./bin
	mkdir -p ./etc
	mkdir -p ./lib
	mkdir -p ./usr
	mkdir -p ./var
	ln -s ../bin ./usr/bin
	ln -s bin ./sbin
	ln -s ../bin ./usr/sbin
	ln -s ../lib ./usr/lib
	ln -s ../lib ./usr/lib64
	ln -s lib ./lib64

tinykerb: prepdirs $(pkgs)
	podman build . --tag=$(id):latest
	rm -f tinykerb.tar
	podman image save $(id):latest -o tinykerb.tar

guts:
	mkdir guts
	tar xvpf tinykerb.tar -C guts

clean-guts:
	rm -rf guts

clean: clean-guts prune
	rm -f tinykerb.tar
	rm -rf ./bin
	rm -rf ./etc
	rm -rf ./lib
	rm -rf ./usr
	rm -rf ./var
	rm -rf ./sbin
	rm -rf ./lib64

prune:
	podman rmi -a || true
