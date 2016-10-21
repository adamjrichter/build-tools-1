# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_deb() {
    in_container apt-get update
    # ^^^ Skip this for binary reproducibility ??

    in_container apt-get install -y autoconf gcc g++ make tar libssl1.0
}

pkg_files_to_kernel_dirs_deb() {
    local file
    for file in "$@" ; do
	dpkg --contents "$file"
    done |
	egrep ^d |
	awk '{print $NF}' |
	egrep ^./usr/src/linux-headers- |
	sed 's|^\.\?\(/usr/src/linux-headers-[^/]*\)/.*$|\1|' |
	uniq |
	sort -u
}

pkg_files_to_names_deb () {
    local file
    for file in "$@" ; do
	( set -- $(dpkg --info "$file" | egrep '^ Package: ') ; echo "$2" )
    done
}

install_pkgs_deb()      { in_container apt-get install -y "$@" ; }
install_pkgs_dir_deb()  { in_container dpkg --install --force-all "$1/*" ; }
uninstall_pkgs_deb()    { in_container dpkg --remove "$@" ; }
pkgs_update_deb()       { in_container apt-get update -y ; }
