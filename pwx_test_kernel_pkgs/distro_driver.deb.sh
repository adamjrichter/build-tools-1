# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_deb() {
    in_container apt-get update --quiet --yes
    # ^^^ Skip this for binary reproducibility ??

    in_container apt-get install --quiet --yes \
		 autoconf g++ gcc git libssl1.0 make tar
    # TODO?: install gcc-5?
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

install_pkgs_deb()      {
    in_container apt-get install --quiet --yes --force-yes "$@"
}

# uninstall_pkgs_deb()    { in_container dpkg --remove "$@" ; }
uninstall_pkgs_deb()    {
    in_container apt-get remove --quiet --yes --force-yes "$@"
}

pkgs_update_deb()       {
    in_container apt-get update --quiet --yes --force-yes
}

install_pkgs_dir_deb()  {
    in_container sh -c "dpkg --install --force-all $1/*"
    # in_container apt-get --fix-broken install --quiet --yes --force-yes || true
    # in_container apt-get --fix-broken install --yes --force-yes || true
    # ^^^ Try to install any missing dependencies.
}
