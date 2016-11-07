# This is not a standalone program.  It is a library to be sourced by a bash
# script (bash because it uses "[[").

# For now, just default everything to the common Debian drivers.

dist_init_container_ubuntu()      { dist_init_container_deb       "$@" ; }
pkg_files_to_kernel_dirs_ubuntu() { pkg_files_to_kernel_dirs_deb  "$@" ; }
pkg_files_to_dependencies_ubuntu() { pkg_files_to_dependencies_deb "$@" ; }
pkg_files_to_names_ubuntu()       { pkg_files_to_names_deb        "$@" ; }
install_pkgs_ubuntu()             { install_pkgs_deb              "$@" ; }
install_pkgs_dir_ubuntu()         { install_pkgs_dir_deb          "$@" ; }
uninstall_pkgs_ubuntu()           { uninstall_pkgs_deb            "$@" ; }
pkgs_update_ubuntu()              { pkgs_update_deb               "$@" ; }
test_kernel_pkgs_func_ubuntu()    { test_kernel_pkgs_func_default "$@" ; }

get_dist_releases_ubuntu()
{
    # Linux 3.10 was released on 2013-06-30, at which point the latest
    # official Ubuntu release 12.04 ("precise"). Yakkety is currently
    # (as of 2016-11-04) in test releases.
    echo xenial yakkety trusty precise zesty
    # The following are currently depreciated, but occurred after Precise.
    # echo wily vivid utopic saucy raring quantal
}
