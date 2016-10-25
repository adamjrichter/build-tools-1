#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["

scriptsdir=$PWD

usage() {
    echo "Usage: test_kernel_pkgs.sh [--distribution=dist] [--containers=container_system] [--logdir=dir] pxfuse_src_directory pkg_file [pkg_file...]"
}


. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

arch=amd64
distro=ubuntu
container_system=docker
logdir=$PWD

exit_handler() {
    rm -rf "$local_tmp_dir"
}

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--arch=* ) arch=${1#--arch=} ;;
	--containers=* ) container_system=${1#--containers=} ;;
	--distribution=* ) distro=${1#--distribution=} ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	--pxfuse=* ) pxfuse_dir=${1#--pxfuse=} ;;
	--* ) usage >&2 ; exit 1 ;;
	* ) break ;;
    esac
    shift
done

if [[ $# -lt 1 ]] ; then
    usage >&2
    exit 1
fi

local_tmp_dir=/tmp/test-kernels.ubuntu.$$
remote_tmp_dir=/tmp/test-portworx-kernels

prepare_pxfuse_dir() {
    trap exit_handler EXIT

    mkdir -p "$local_tmp_dir"
    if [ -z "$pxfuse_dir" ] ; then
	(cd "$local_tmp_dir" &&
	 git clone https://github.com/portworx/px-fuse.git )

	pxfuse_dir="$local_tmp_dir/px-fuse"
    fi
}

main() {
    local kernel_dir
    start_container dist_init_container
    kernel_dir=$(pkg_files_to_kernel_dirs "$@" | head -1)

    start_container dist_init_container
    test_kernel_pkgs_func "$remote_tmp_dir" "$logdir" "$@"
    result=$?
    stop_container
    return $result
}

prepare_pxfuse_dir
main "$@"
