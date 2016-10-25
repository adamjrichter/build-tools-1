# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_deb() {
    echo "AJR distro_driver.deb.sh dist_init_container_deb $* called." >&2
    in_container apt-get update
    # ^^^ Skip this for binary reproducibility ??

    in_container apt-get install -y autoconf g++ gcc git libssl1.0 make tar
    # Why px-fuse wants git is unclear to me.
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

install_pkgs_deb()      { in_container apt-get install --quiet --yes "$@" ; }
install_pkgs_dir_deb()  { in_container sh -c "dpkg --install --force-all $1/*" ; }
uninstall_pkgs_deb()    { in_container dpkg --remove "$@" ; }
pkgs_update_deb()       { in_container apt-get update --quiet --yes ; }
