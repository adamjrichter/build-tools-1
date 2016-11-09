# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_rpm() {
    install_pkgs_rpm autoconf automake gcc gcc-c++ git make tar
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

#install_pkgs_dir_rpm() { in_container sh -c "rpm --install $1/*" ; }
install_pkgs_dir_rpm() {
    in_container sh -c "yum --assumeyes upgrade $1/*"
    in_container sh -c "yum --assumeyes install $1/*"
}

install_pkgs_rpm()     { in_container yum --assumeyes --quiet install "$@" ; }
uninstall_pkgs_rpm()   { in_container rpm --erase "$@" ; }
pkgs_update_rpm()      { in_container yum --assumeyes --quiet update ; }
