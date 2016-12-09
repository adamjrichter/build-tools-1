# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Fedora drivers.

pkg_files_to_kernel_dirs_fedora() { pkg_files_to_kernel_dirs_rpm  "$@" ; }
pkg_files_to_names_fedora()       { pkg_files_to_names_rpm        "$@" ; }
pkg_files_to_dependencies_fedora() { pkg_files_to_dependencies_rpm "$@" ; }
install_pkgs_fedora()             { install_pkgs_rpm              "$@" ; }
install_pkgs_dir_fedora()         { install_pkgs_dir_rpm          "$@" ; }
uninstall_pkgs_fedora()           { uninstall_pkgs_rpm            "$@" ; }
pkgs_update_fedora()              { pkgs_update_rpm               "$@" ; }
dist_init_container_fedora()      { dist_init_container_rpm       "$@" ; }
dist_clean_up_container_fedora()  { dist_clean_up_container_rpm   "$@" ; }
dist_start_container_fedora()     { dist_start_container_rpm      "$@"; }

get_dist_releases_fedora()
{
    echo 24 23 22
}
