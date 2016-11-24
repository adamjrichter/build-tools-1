# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# FIXME? Maybe clear the other environment variables.  Here is the
# environment that a root cron script runs with on mirrors.portworx.com:
# HOME=/root
# LOGNAME=root
# PATH=/usr/bin:/bin
# LANG=en_US.UTF-8
# SHELL=/bin/sh
# PWD=/root
#
# Notice that /usr/local/sbin, /usr/sbin and /sbin are not in $PATH.
#

# Global variable determine which arguments to pass to apt-get to
# tell it it just do what was requests while avoiding warning messages:
deb_apt_get_args="--quiet --quiet --yes --force-yes"

in_container_flock_deb() {
    # Do an in_container command, but block for up to five minutes to
    # acquire (and release) the dpkg lock, to reduce the change of the
    # command failing due to some automatic dpkg database update running
    # or something like that.  Something taking the lock broke a few
    # of he Ubuntu rebuild tests.
    local seconds=600
    local lockfile=/var/lib/dpkg/lock
    in_container env DEBIAN_FRONTEND=noninteractive \
	flock --close --timeout $seconds $lockfile \
	flock --close --unlock $lockfile \
	"$@"
}

dist_start_container_deb()
{
    if in_container_flock_deb apt-get install --quiet --quiet --yes --allow-downgrades bash ; then
	deb_apt_get_args="--quiet --quiet --yes --allow-downgrades --allow-remove-essential --allow-change-held-packages"
    else
	deb_apt_get_args="--quiet --quiet --yes --force-yes"
    fi
}

dist_init_container_deb() {
    in_container_flock_deb apt-get update $deb_apt_get_args
    # ^^^ Skip this for binary reproducibility ??

    install_pkgs_deb autoconf g++ gcc git libelf-dev libssl1.0 make tar
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
    in_container_flock_deb apt-get install $deb_apt_get_args "$@"
}

# uninstall_pkgs_deb()    { in_container_flock_deb dpkg --remove "$@" ; }
uninstall_pkgs_deb()    {
    local pkg
    if ! in_container_flock_deb apt-get remove $deb_apt_get_args "$@" ; then
	for pkg in "$@" ; do
	    in_container_flock_deb dpkg --remove --force-remove-reinstreq "$pkg"
	done
    fi
}

pkgs_update_deb()       {
    in_container_flock_deb apt-get update $deb_apt_get_args
}

dist_clean_up_container_deb()
{
    in_container_flock_deb sh -c "
	pkgs=\$( dpkg --list 'linux-headers-*' |
            awk '\$1 != \"un\" {print \$2;}' |
            egrep '^linux-headers-' )
        if [ -n \"\$pkgs\" ] ; then
	    dpkg --remove \$pkgs
        fi
    "
    in_container_flock_deb apt-get --yes clean
}

install_pkgs_dir_deb()  {
    in_container_flock_deb apt-get --yes clean
    in_container_flock_deb sh -c "dpkg --install --force-all $1/*"
    # in_container_flock_deb apt-get --fix-broken install $deb_apt_get_args || true
    # in_container_flock_deb apt-get --fix-broken install $deb_apt_get_args || true
    # ^^^ Try to install any missing dependencies.
}
