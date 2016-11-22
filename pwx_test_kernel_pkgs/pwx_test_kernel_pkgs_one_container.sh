#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["

scriptsdir=$PWD

usage() {
    cat <<EOF
Usage: pwx_test_kernel_pkgs [options] pkg_files...
    options:
	--arch=architecture            [default: amd64]
	--containers=container_system  [default: docker]
	--distribution=dist            [default: ubuntu]
	--force
        --help
	--leave-containers-running
	--logdir=logdir                [default: based on distribution]
	--pfxuse=pxfuse_src_dir        [default: download tempoary
				        directory from github]
	--release=dist_releaes         Which releaes of the OS distribution
                                       to use.  Mandatory.
	--releases=dist_releases       Ignored
EOF
}


. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

arch=amd64
distro=ubuntu
distro_release=""
container_system=lxc
leave_containers_running=false
make_args=""
force=false
logdir=$PWD
pxfuse_dir=""

exit_handler() {
    rm -rf "$local_tmp_dir"
}

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--arch=* ) arch=${1#--arch=} ;;
	--containers=* ) container_system=${1#--containers=} ;;
	--distribution=* ) distro=${1#--distribution=} ;;
	--force ) force=true ;;
	--help ) usage ; exit 0 ;;
	--leave-containers-running ) leave_containers_running=true ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	--make-args=* ) make_args="${1#--make-args=}" ;;
	--pxfuse=* ) pxfuse_dir=${1#--pxfuse=} ;;
	--release=* ) distro_release=${1#--release=} ;;
	--releases=* ) true ;;	# Ignore
	--* ) usage >&2 ; exit 1 ;;
	* ) break ;;
    esac
    shift
done

if [[ $# -lt 1 ]] ; then
    usage >&2
    exit 1
fi

if [[ -z "$distro_release" ]] ; then
    echo "$0: \"--release=...\" must be specified." >&2
    usage >&2
    exit 1
fi

if [[ -z "$pxfuse_dir" ]] ; then
    echo "$0: \"--pxfuse=...\" must be specified." >&2
    usage >&2
    exit 1
fi

if ! [[ -e "$pxfuse_dir" ]] ; then
    echo "$0: pxfuse directory ${pxfuse_dir} does not exist." >&2
    exit 1
fi

if ! [[ -d "$pxfuse_dir" ]] ; then
    echo "$0: pxfuse directory ${pxfuse_dir} is not a directory." >&2
    exit 1
fi

local_tmp_dir=/tmp/test-kernels.ubuntu.$$

test_kernel_pkgs() {
    local result local
    local release="$distro_release"

    echo "Command: pwx_test_kernel_pkgs_one_container.sh $*"

    echo "test_kernel_pkgs: Attempting to test kernel package(s) on distribution $distro, release $release, make_args=$make_args."

    start_container --release="$release" dist_init_container

    test_kernel_pkgs_func "$pxfuse_dir" "$logdir" "$make_args" "$@"
    result=$?

    if ! $leave_containers_running ; then
	stop_container
    fi

    return $result
}

test_kernel_pkgs "$@"
