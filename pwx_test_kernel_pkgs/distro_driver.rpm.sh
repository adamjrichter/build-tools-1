# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_rpm() {
    install_pkgs_rpm autoconf automake gcc git make tar
}

pkg_files_to_kernel_dirs_rpm() {
    rpm --query --list --package "$@" |
	egrep ^d |
	awk '{print $NF}' |
	egrep ^./usr/src/linux-headers- |
	sed 's|^\.\?\(/usr/src/linux-headers-[^/]*\)/.*$|\1|' |
	uniq |
	sort -u
}

pkg_files_to_names_rpm () {
    rpm --query --package "$@"
}

install_pkgs_rpm()     { in_container yum --assumeyes --quiet install "$@" ; }
install_pkgs_dir_rpm() { in_container sh -c "rpm --install $1/*" ; }
uninstall_pkgs_rpm()   { in_container rpm --erase "$@" ; }
pkgs_update_rpm()      { in_container yum --assumeyes --quiet update ; }
