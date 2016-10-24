#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["

scriptsdir=$PWD
build_results_dir=$PWD/build-results

usage() {
    echo "Usage: test_kernels_in_mirror.sh [--distribution=dist] [--containers=container_system] [--logdir=dir] [ --pxfuse=pxfuse_src_directory ] mirror_dir"
    echo ""
    echo "If pxfuse_src_directory is not specified, it is downloaded from"
    echo "github into a temporary directory."
    echo ""
}

. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

checksum_current_directory() {
    find . \( -name .git -type d -prune \) -o \( -type f -print0 \) |
        sort --zero-terminated |
        xargs --null --no-run-if-empty --max-args=1 md5sum |
        md5sum - |
	sed 's/ .*$//'
}

exit_handler() {
    rm -rf "$local_tmp_dir"
}

distro=ubuntu
arch=amd64
container_system=docker
logdir="$build_results_dir"
pxfuse_dir=""
command=pwx_test_kernel_pkgs.sh
# Global variables set later:
#   log_subdir

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--arch=* ) arch=${1#--arch=} ;;
	--command=* ) command=${1#--command=} ;;
	--containers=* ) container_system=${1#--container-system=} ;;
	--distribution=* ) distro=${1#--distribution=} ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	--pxfuse=* ) pxfuse_dir=${1#--pxfuse=} ;;
	--* ) usage >&2 ; exit 1 ;;
	* ) break ;;
    esac
    shift
done

if [ $# = 0 ] ; then
    case "$distro" in
	centos ) set /home/ftp/mirrors/http/elrepo.org/linux/kernel ;;
	debian ) set /home/ftp/mirrors/http/snapshot.debian.org/archive/debian ;;
	ubuntu ) set /home/ftp/mirrors/http/kernel.ubuntu.com/~kernel-ppa/mainline  ;;
	* ) echo "Unable to choose default mirror directory for unknown distribution \"$distro\"." >&2 ; exit 1 ;;
    esac
fi

local_tmp_dir=/tmp/test-kernels.ubuntu.$$
remote_tmp_dir=/tmp/test-portworx-kernels

trap exit_handler EXIT

mkdir -p "$local_tmp_dir"
if [ -z "$pxfuse_dir" ] ; then
	(cd "$local_tmp_dir/px-fuse" &&
	 git clone https://github.com/portworx/px-fuse.git )

	pxfuse_dir="$local_tmp_dir/px-fuse"
fi

PATH=$PATH:/usr/local/bin

mirror_callback() {
    local mirror_dir="$1"
    local log_subdir="$2"
    local pkg1="$3"
    local pkg_subdir=${pkg1#$mirror_dir}
    local pkg_subdir_no_ext=${pkg_subdir%.*}	# Remove trailing .rpm or .deb

    shift 2

    $command \
	"--arch=$arch" \
	"--containers=${container_system}" \
	"--distribution=$distro" \
	"--logdir=${log_subdir}/${pkg_subdir_no_ext}" \
	"--pxfuse=$pxfuse_dir" \
	"$@"
}

checksum=$(cd "$pxfuse_dir" && checksum_current_directory)
log_subdir="$logdir/pxfuse-${checksum}/${distro}"
exit_status=0
for mirror_dir in "$@" ; do
	walk_mirror "$mirror_dir" mirror_callback "$mirror_dir" "$log_subdir"
	tmp_exit_status=$?
	if [ "$tmp_exit_status" != 0 ] ; then
	    exit_status=$tmp_exit_status
	fi
done

( exit $exit_status )
# ^^^ Return $tmp_exit_status, but do not actually exit the shell if this
# file was sourced rather than executed.
