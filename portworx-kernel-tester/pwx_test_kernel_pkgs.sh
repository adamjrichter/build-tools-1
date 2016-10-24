#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["

scriptsdir=$PWD

usage() {
    echo "Usage: test_kernel_pkgs.sh [--distribution=dist] [--containers=container_system] [--logdir=dir] pxfuse_src_directory pkg_file [pkg_file...]"
}


. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

distro=ubuntu
container_system=docker
logdir=$PWD

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--distribution=* ) distro=${1#--distribution=} ;;
	--containers=* ) container_system=${1#--container-system=} ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	* ) break ;;
    esac
    shift
done

pxfuse_dir="$1"
shift

if [[ $# -lt 1 ]] ; then
    usage >&2
    exit 1
fi

local_tmp_dir=/tmp/test-kernels.ubuntu.$$
remote_tmp_dir=/tmp/test-portworx-kernels
results_logdir=${scriptsdir}/../build/results/$distro

main() {
    local kernel_dir
    start_container dist_init_container
    kernel_dir=$(pkg_files_to_kernel_dirs "$@" | head -1)

    start_container dist_init_container
    test_kernel_pkgs_func "$remote_tmpdir" "$logdir" "$@"
    result=$?
    stop_container
    return $result
}

main "$@"
