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

distro=ubuntu
container_system=docker
logdir=$PWD
pxfuse_dir=""

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--distribution=* ) distro=${1#--distribution=} ;;
	--containers=* ) container_system=${1#--container-system=} ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	--pxfuse=* ) pxfuse_dir=${1#--pxfuse=} ;;
	* ) break ;;
    esac
    shift
done

if [ $# -ne 1 ] ; then
    usage >&2
    exit 1
fi

mirror_dir="$2"
shift 2

local_tmp_dir=/tmp/test-kernels.ubuntu.$$
remote_tmp_dir=/tmp/test-portworx-kernels

if [ -z "$pxfuse_dir" ] ; then
    
fi

PATH=$PATH:/usr/local/bin

mirror_callback() {
    local log_subdir="$1"
    shift 1
    test_kernel_pkgs.sh "--logdir=${log_subdir}" \
	"--distribution=$distro" "--containers=${container_system}" "$@"
}

walk_mirror "$mirror_dir" mirror_callback
