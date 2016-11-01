# This is not a standalone program.  It is a library to be sourced by a bash
# script (bash because it uses "[[").

# For now, just default everything to the common Debian drivers.

dist_init_container_ubuntu()      { dist_init_container_deb       "$@" ; }
pkg_files_to_kernel_dirs_ubuntu() { pkg_files_to_kernel_dirs_deb  "$@" ; }
pkg_files_to_contents_ubuntu()    { pkg_files_to_contents_deb     "$@" ; }
pkg_files_to_names_ubuntu()       { pkg_files_to_names_deb        "$@" ; }
install_pkgs_ubuntu()             { install_pkgs_deb              "$@" ; }
install_pkgs_dir_ubuntu()         { install_pkgs_dir_deb          "$@" ; }
uninstall_pkgs_ubuntu()           { uninstall_pkgs_deb            "$@" ; }
pkgs_update_ubuntu()              { pkgs_update_deb               "$@" ; }
test_kernel_pkgs_func_ubuntu()    { test_kernel_pkgs_func_default "$@" ; }
