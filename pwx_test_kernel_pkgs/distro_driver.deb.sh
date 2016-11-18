# This is not a standalone program.  It is a library to be sourced by a shell
# script.

in_container_flock_deb() {
    # Do an in_container command, but block for up to five minutes to
    # acquire (and release) the dpkg lock, to reduce the change of the
    # command failing due to some automatic dpkg database update running
    # or something like that.  Something taking the lock broke a few
    # of he Ubuntu rebuild tests.
    local seconds=600
    local lockfile=/var/lib/dpkg/lock
    in_container flock --timeout $seconds -- $lockfile \
		 flock --unlock -- $lockfile "$@"
}

dist_init_container_deb() {
    in_container_flock_deb apt-get update --quiet --yes
    # ^^^ Skip this for binary reproducibility ??

    in_container_flock_deb apt-get install --quiet --yes \
		 autoconf g++ gcc git libelf-dev libssl1.0 make tar
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

pkg_files_to_dependencies_deb() {
    local pkgfile
    for pkgfile in "$@" ; do
	dpkg --info "$pkgfile"
    done |
	egrep '^ Depends: ' |
	sed 's/(.*)/ /g;s/,/ /g;s/^ Depends: //;s/ /\n/g' |
	sort -u
}

install_pkgs_deb()      {
    in_container_flock_deb apt-get install --quiet --yes --force-yes "$@"
}

# uninstall_pkgs_deb()    { in_container_flock_deb dpkg --remove "$@" ; }
uninstall_pkgs_deb()    {
    local pkg
    if ! in_container_flock_deb apt-get remove --quiet --yes --force-yes "$@" ; then
	for pkg in "$@" ; do
	    in_container_flock_deb dpkg --remove --force-remove-reinstreq "$pkg"
	done
    fi
}

pkgs_update_deb()       {
    in_container_flock_deb apt-get update --quiet --yes --force-yes
}

dist_clean_up_container_deb()
{
    in_container_flock_deb sh -c "pkgs=\$( dpkg --list 'linux-headers-*' | awk '\$1 != \"un\" {print \$2;}' | egrep '^linux-headers-' ) ; dpkg --remove \$pkgs"
}

install_pkgs_dir_deb()  {
    in_container_flock_deb sh -c "dpkg --install --force-all $1/*"
    # in_container_flock_deb apt-get --fix-broken install --quiet --yes --force-yes || true
    # in_container_flock_deb apt-get --fix-broken install --yes --force-yes || true
    # ^^^ Try to install any missing dependencies.
}

