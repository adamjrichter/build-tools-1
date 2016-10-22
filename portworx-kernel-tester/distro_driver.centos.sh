# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Centos drivers.

dist_init_container_centos()      { "dist_init_container.rpm"      "$@" ; }
pkg_files_to_kernel_dirs_centos() { "pkg_files_to_kernel_dirs.rpm" "$@" ; }
pkg_files_to_names_centos()       { "pkg_files_to_names.rpm"       "$@" ; }
install_pkgs_centos()             { "install_pkgs.rpm"             "$@" ; }
install_pkg_files_centos()        { "install_pkg_files.rpm"        "$@" ; }
uninstall_pkgs_centos()           { "uninstall_pkgs.rpm"           "$@" ; }
pkgs_update_centos()              { "pkgs_update.rpm"              "$@" ; }
test_kernel_pkgs_func()           { "test_kernel_pkgs_func.default" "$@" ; }

walk_mirror_centos() {
    local mirror_tree="$1"
    local file

    shift 1

    ( cd "$mirror_tree" && find "$mirror_tree" -name "kernel-*-headers-*.${arch}.rpm" -type f -print0 ) |
    while read -r -d $'\0' file ; do
        "$@" "$mirror_tree" "$file"
    done
}
