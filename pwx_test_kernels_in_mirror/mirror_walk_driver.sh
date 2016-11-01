# This is not a standalone program.  It is a library to be sourced by a shell
# script.

. $scriptsdir/mirror_walk_driver.deb.sh
. $scriptsdir/mirror_walk_driver.rpm.sh

. $scriptsdir/mirror_walk_driver.debian.sh
. $scriptsdir/mirror_walk_driver.ubuntu.sh
. $scriptsdir/mirror_walk_driver.centos.sh


pkg_files_to_names()       { "pkg_files_to_names_$distro"       "$@" ; }
walk_mirror()              { "walk_mirror_$distro"              "$@" ; }
