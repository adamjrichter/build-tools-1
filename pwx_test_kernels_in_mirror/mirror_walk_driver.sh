# This is not a standalone program.  It is a library to be sourced by a shell
# script.

. $scriptsdir/mirror_walk_driver.deb.sh
. $scriptsdir/mirror_walk_driver.rpm.sh

. $scriptsdir/mirror_walk_driver.debian.sh
. $scriptsdir/mirror_walk_driver.ubuntu.sh
. $scriptsdir/mirror_walk_driver.centos.sh
. $scriptsdir/mirror_walk_driver.fedora.sh

# Used for selecting kernels version 3.10 or later.  Used by some drivers.
above_3_9_regexp='(3\.[1-9][0-9]+|[4-9][0-9]*|[1-9][0-9]+)(\.[.0-9]+[0-9])?'

pkg_files_to_names()       { "pkg_files_to_names_$distro"       "$@" ; }
walk_mirror()              { "walk_mirror_$distro"              "$@" ; }

get_default_mirror_dirs()
{
    "get_default_mirror_dirs_$distro""$@"
    echo "/home/ftp/downloads/$distro"
}
