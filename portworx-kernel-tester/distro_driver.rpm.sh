# This is not a standalone program.  It is a library to be sourced by a shell
# script.

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

install_pkgs_rpm()            { in_container yum install "$@" ; }
install_pkg_files_rpm()       { in_container rpm --install "$@" ; }
uninstall_pkgs_rpm()          { in_container rpm --remove "$@" ; }

pkgs_update_rpm() { in_container "yum update" ; }
