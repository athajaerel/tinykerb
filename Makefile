# minideb base
pkgs:=krb5-admin-server krb5-config krb5-k5tls krb5-kdc krb5-kdc-ldap krb5-kpropd krb5-locales krb5-otp krb5-pkinit krb5-sync-tools krb5-user libverto1 libverto-glib1 libverto-libev1
# Misleading error "Cannot allocate memory - while creating main loop" means Verto plugins are missing
temp_pkgs:=coreutils bash expect tcl botan iproute2 sed findutils apt-file file
temp_dirs:=/usr/share/tcltk/tcl8.6

id_kdc:=localhost/tinykerb-kdc:latest
id_kadmind:=localhost/tinykerb-kadmind:latest
id_kdc_debug:=localhost/debug-tinykerb-kdc:latest
id_kadmind_debug:=localhost/debug-tinykerb-kadmind:latest

include *.mk
