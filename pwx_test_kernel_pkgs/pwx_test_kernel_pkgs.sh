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
distro_releases=""
container_system=docker
force=false
logdir=$PWD

exit_handler() {
    rm -rf "$local_tmp_dir"
}

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--arch=* ) arch=${1#--arch=} ;;
	--containers=* ) container_system=${1#--containers=} ;;
	--distribution=* ) distro=${1#--distribution=} ;;
	--force ) force=true ;;
	--releases=* ) distro_release=${1#--releases=} ;;
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

prepare_pxfuse_dir() {
    trap exit_handler EXIT

    mkdir -p "$local_tmp_dir"
    if [[ -z "$pxfuse_dir" ]] ; then
	(cd "$local_tmp_dir" &&
	 git clone https://github.com/portworx/px-fuse.git )

	pxfuse_dir="$local_tmp_dir/px-fuse"
	# ^^^^^^^ Global variable.
    fi
}

test_kernel_pkgs() {
    local result release releases local make_args

    ran_test=false	# global variable

    if [[ -n "$distro_releases" ]] ; then
	releases=$(echo "$distro_releases" | sed 's/,/ /g')
    else
	releases=$(get_dist_releases)
    fi

    result=1 # in case one of the loops should be empty for some reason.

    for make_args in "" "CC=\"gcc -fno-pie\"" ; do
	for release in $releases ; do
	    echo "test_kernel_pkgs: Attempting to test kernel package(s) on distribution $distro, release $release, make_args=$make_args."

	    start_container --release="$release" dist_init_container

	    test_kernel_pkgs_func "$pxfuse_dir" "$logdir" "$make_args" "$@"
	    result=$?

	    stop_container
	    if [[ $result = 0 ]] ; then
		break
	    fi
	done
	if [[ $result = 0 ]] ; then
	    break
	fi
    done
    echo "$result $distro $release make_args=$make_args" > "$logdir/exit_code"
    if $ran_test ; then
	touch "$logdir/done"
	# ^^ We have a "done" file in addition to an "exit_code" file, because
	# creating the empty "done" file is atomic.
    fi
    return $result
}

main()
{
    if [[ -e "$logdir/done" ]] && ! $force ; then
	echo "test_kernel_pkgs: $logdir/done exists.  Skipping."
    else
	prepare_pxfuse_dir
	mkdir -p "$logdir"
	test_kernel_pkgs "$@" > "$logdir/build.log" 2>&1
    fi
}

main "$@"
