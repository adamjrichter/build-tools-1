# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Centos drivers.

dist_init_container_centos()      { dist_init_container_rpm       "$@" ; }
pkg_files_to_kernel_dirs_centos() { pkg_files_to_kernel_dirs_rpm  "$@" ; }
pkg_files_to_names_centos()       { pkg_files_to_names_rpm        "$@" ; }
install_pkgs_centos()             { install_pkgs_rpm              "$@" ; }
install_pkg_files_centos()        { install_pkg_files_rpm         "$@" ; }
uninstall_pkgs_centos()           { uninstall_pkgs_rpm            "$@" ; }
pkgs_update_centos()              { pkgs_update_rpm               "$@" ; }
test_kernel_pkgs_func_centos()    { test_kernel_pkgs_func_default "$@" ; }

walk_mirror_centos() {
    local mirror_tree="$1"
    local file
    local rpm_arch

    shift 1

    if [ ".$arch" = ".amd64" ] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    ( cd "$mirror_tree" && find "$mirror_tree" -name "kernel-*-headers-*.${rpm_arch}.rpm" -type f -print0 ) |
    while read -r -d $'\0' file ; do
        "$@" "$mirror_tree" "$file"
    done
}
