# This is not a standalone program.  It is a library to be sourced by a shell
# script.

in_container_env_rpm() {
    # cron does not include the sbin directories in the $PATH that it
    # provides, and lxc-attach passes the provided environment variables,
    # including PATH. So, PATH to something that includes the sbin
    # directories, and, also, to reduce variation, set the rest of
    # the environment to something simple and standard.

    in_container env --ignore-environment \
	 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	 SHELL=/bin/sh \
	 USER=root \
	 "$@"
}

dist_init_container_rpm() {
    install_pkgs_rpm autoconf automake gcc gcc-c++ git make tar

    uninstall_pkgs_rpm kernel-devel   # FIXME? Is this command necessary?
}

pkg_files_to_kernel_dirs_rpm() {
    rpm --query --list --package "$@" |
	awk '{print $NF}' |
	egrep '^\.?/usr/src/kernels/' |
	sed 's|^\.\?\(/usr/src/kernels/[^/]*\)/.*$|\1|' |
	uniq |
	sort -u
}

pkg_files_to_names_rpm () {
    rpm --query --package --qf '%{NAME}\n' "$@"
}

pkg_files_to_dependencies_rpm() {
    local pkgfile
    for pkgfile in "$@" ; do
	rpm --query --package --requires "$pkgfile"
    done |
	sed 's/[( <=].*$//' |
	sort -u
}

#install_pkgs_dir_rpm() { in_container_env_rpm sh -c "rpm --install $1/*" ; }
install_pkgs_dir_rpm() {
    in_container_env_rpm sh -c "yum --assumeyes upgrade $1/*"
    in_container_env_rpm sh -c "yum --assumeyes install $1/*"
}

install_pkgs_dir_rpm_notyet()
{
    # in_container_env_rpm sh -c "yum --assumeyes install $1/*" ;
    # yum fails when asked to install a file that is already installed.
    # So, try to install the packages one by one, until all installs fail.
    in_container_env_rpm sh -c "yum --assumeyes --skip-broken install $1/*" ;
    return $?	 # AJR
    while in_container_env_rpm sh -c \
	"for pkgfile in $1/* ; do yum --assumeyes install \$pkgfile && exit 0 ; done ; false" ; do
	true
    done
}

install_pkgs_rpm()     { in_container_env_rpm yum --assumeyes --quiet install "$@" ; }
#uninstall_pkgs_rpm()   { in_container_env_rpm rpm --erase "$@" ; }
uninstall_pkgs_rpm()   { in_container_env_rpm yum --assumeyes remove "$@" ; }
pkgs_update_rpm()      { in_container_env_rpm yum --assumeyes --quiet update ; }
dist_clean_up_container_rpm() { true; }	# No-op for now.
