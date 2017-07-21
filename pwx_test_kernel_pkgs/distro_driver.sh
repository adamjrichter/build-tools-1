# This is not a standalone program.  It is a library to be sourced by a shell
# script.

. $scriptsdir/distro_driver.deb.sh
. $scriptsdir/distro_driver.rpm.sh

. $scriptsdir/distro_driver.debian.sh
. $scriptsdir/distro_driver.ubuntu.sh
. $scriptsdir/distro_driver.centos.sh
. $scriptsdir/distro_driver.chromiumos.sh
. $scriptsdir/distro_driver.coreos.sh
. $scriptsdir/distro_driver.fedora.sh
. $scriptsdir/distro_driver.opensuse.sh

# These commands are selected based on the format of the kernel header
# package files being used (.rpm or .deb)

pkg_files_to_kernel_dirs() { "pkg_files_to_kernel_dirs_$pkgformat" "$@" ; }
pkg_files_to_names()       { "pkg_files_to_names_$pkgformat"       "$@" ; }
pkg_files_to_dependencies() { "pkg_files_to_dependencies_$pkgformat" "$@" ; }
install_pkgs_dir()         { "install_pkgs_dir_$pkgformat"      "$@" ; }

get_dist_releases()        { "get_dist_releases_$distro"        "$@" ; }
dist_init_container()      { "dist_init_container_$distro"      "$@" ; }
dist_start_container()     { "dist_start_container_$distro"     "$@" ; }
install_pkgs()             { "install_pkgs_$distro"             "$@" ; }
uninstall_pkgs()           { "uninstall_pkgs_$distro"           "$@" ; }
pkgs_update()              { "pkgs_update_$distro"              "$@" ; }
dist_clean_up_container()  { "dist_clean_up_container_$distro"  "$@" ; }

