# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Centos drivers.

pkg_files_to_kernel_dirs_centos() { pkg_files_to_kernel_dirs_rpm  "$@" ; }
pkg_files_to_names_centos()       { pkg_files_to_names_rpm        "$@" ; }
pkg_files_to_dependencies_centos() { pkg_files_to_dependencies_rpm "$@" ; }
install_pkgs_centos()             { install_pkgs_rpm              "$@" ; }
install_pkgs_dir_centos()         { install_pkgs_dir_rpm          "$@" ; }
install_pkgs_centos()             { install_pkgs_rpm              "$@" ; }
uninstall_pkgs_centos()           { uninstall_pkgs_rpm            "$@" ; }
pkgs_update_centos()              { pkgs_update_rpm               "$@" ; }
test_kernel_pkgs_func_centos()    { test_kernel_pkgs_func_default "$@" ; }
dist_init_container_centos()      { dist_init_container_rpm       "$@" ; }
dist_clean_up_container_centos()  { dist_clean_up_container_rpm   "$@" ; }
dist_start_container_centos()     { dist_start_container_rpm      "$@"; }

get_dist_releases_centos()
{
    echo "7 6"
}
