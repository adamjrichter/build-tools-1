# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Debian drivers.

debian_tmpdir=/tmp/pwx-kernel-tester.distro-driver.debian.$$
debian_find_txt="${debian_tmpdir}/find.sorted.txt"

dist_init_container_debian()      { dist_init_container_deb       "$@" ; }
pkg_files_to_names_debian()       { pkg_files_to_names_deb        "$@" ; }
pkg_files_to_dependencies_debian() { pkg_files_to_dependencies_deb "$@" ; }
install_pkgs_debian()             { install_pkgs_deb              "$@" ; }
install_pkgs_dir_debian()         { install_pkgs_dir_deb          "$@" ; }
uninstall_pkgs_debian()           { uninstall_pkgs_deb            "$@" ; }
pkgs_update_debian()              { pkgs_update_deb               "$@" ; }
test_kernel_pkgs_func_debian()    { test_kernel_pkgs_func_default "$@" ; }

pkg_files_to_kernel_dirs_debian() {
    local result=$(pkg_files_to_kernel_dirs_deb "$@" | egrep -v -- '-common$')
    pkg_files_to_kernel_dirs_deb "$@" | egrep -v -- '-common$'
}
