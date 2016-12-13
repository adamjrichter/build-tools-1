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

echo ""
echo "Command: pwx_test_kernel_pkgs_one_container.sh $*"

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

pkgformat=$distro
# Used by some function in distro_driver.sh.

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

filter_word() {
    # Echo the first word if it does not match any of the subsequent words
    local first="$1"
    local other
    shift
    for other in "$@" ; do
	if [[ ".$first" = "$.other" ]] ; then
	    return 0
	fi
    done
    echo "$first"
}

test_kernel_pkgs_func() {
    local container_tmpdir result_logdir
    local result filename real dirname basename headers_dir
    local pkg_names deps_unfiltered dep_names arg guess_utsname dir
    local container_tmpdir=/tmp/test-portworx-kernels.$$
    local pxfuse_dir pxd_version
    local make_args=

    for arg in "$@" ; do
	echo "    $arg"
    done >&2
    echo "(end of arguments)" >&2
    echo "" >&2

    pxfuse_dir="$1"
    result_logdir="$2"
    make_args="$3"
    shift 3

    in_container rm -rf "$container_tmpdir"
    in_container mkdir -p "$container_tmpdir/pxfuse_dir" "$container_tmpdir/header_pkgs"

    ( cd "$pxfuse_dir" && tar c . ) |
	in_container tar -C "${container_tmpdir}"/pxfuse_dir -xp

    for filename in "$@" ; do
	real=$(realpath $filename)
	dirname=${real%/*}
	basename=${real##*/}
	tar -C "$dirname" -c -- "$basename" |
	    in_container tar -C "${container_tmpdir}/header_pkgs" -xpv
    done

    pkg_names=$(pkg_files_to_names "$@")
    deps_unfiltered=$(pkg_files_to_dependencies "$@")

    dep_names=""
    for dep in $deps_unfiltered ; do
	dep_names="$dep_names $(filter_word "$dep" $pkg_names)"
    done

    install_pkgs $dep_names
    uninstall_pkgs $pkg_names > /dev/null 2>&1 || true

    install_pkgs_dir "${container_tmpdir}/header_pkgs"
    result=$?

    if [[ $result != 0 ]] ; then
	uninstall_pkgs $pkg_names
	in_container rm -rf "$container_tmpdir"
	return $result
    fi

    if [[ $result = 0 ]] ; then
	headers_dir=$(pkg_files_to_kernel_dirs "$@" | sort -u | tail -1)
	# Use "tail" to get the last kernel directory that is alphabetically
	# last because Ubuntu unpacks and requires an architecure-independnt
	# kernel header directory that is a prefix architecture-specific
	# kernel header directory that should be passed to the pxfuse build.
	#
	# "sort -u | tail -1" is used rather than "sort -ur | head -1" to
	# avoid generating a broken pipe signal if the list were somehow
	# to become longer than a pipe buffer, although this would probably
	# never happen.

	in_container sh -c \
		     "cd ${container_tmpdir}/pxfuse_dir && \
                  autoreconf && \
                  ./configure && \
                  make KERNELPATH=$headers_dir $make_args"
                  # make KERNELPATH=$headers_dir CC=\"gcc -fno-pie\"

	result=$?
	if [[ "$result" = 0 ]] ; then
	    in_container tar -C "${container_tmpdir}/pxfuse_dir" -c px.ko |
		tar -C "${result_logdir}" -xpv

	    guess_utsname=${headers_dir#/usr/src/}
	    guess_utsname=${guess_utsname#kernels/}
	    guess_utsname=${guess_utsname#linux-header-}

	    pxd_version=$(set -- $(egrep '^#define PXD_VERSION ' < "${pxfuse_dir}/pxd.h") ; echo $3)

	    dir="${for_installer_dir}/${pxd_version}/${guess_utsname}"
	    rm -rf "$dir/packages"
	    mkdir -p "$dir/packages"
	    ln --symbolic --force "$@" "$dir/packages/"
	    symlinks -c "$dir/packages" > /dev/null
	    cp "${result_logdir}/px.ko" "$dir/"

	fi # result = 0
	touch "${result_logdir}/ran_test"
    fi # result = 0

    uninstall_pkgs $pkg_names
    in_container rm -rf "$container_tmpdir"
    dist_clean_up_container

    echo "test_kernel_pkgs_func: build_exit_code=$result" >&2
    # if [[ "$result" != 0 ]] ; then
    #	sleep 3600
    # fi

    return $result
}

test_kernel_pkgs() {
    local result local
    local release="$distro_release"

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
