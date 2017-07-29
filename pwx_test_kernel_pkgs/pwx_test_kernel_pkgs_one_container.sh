#!/bin/bash
# ^^^^^^^^^ bash because it uses "[["

scriptsdir=$PWD

usage() {
    cat <<EOF
Usage: pwx_test_kernel_pkgs [options] pkg_files...
    options:
	--arch=architecture            [default: amd64]
	--containers=container_system  [default: docker]
	--container-tmpdir=dir       [default: /tmp/test-portworx-kernels.\$\$]
	--distribution=dist            [default: ubuntu]
	--force
        --help
	--leave-containers-running
	--logdir=logdir                [default: based on distribution]
	--prepare-build
	--pfxuse=pxfuse_src_dir        [default: download tempoary
				        directory from github]
	--release=dist_releaes       Which releaes of the OS distribution
                                     to use.  Mandatory.
	--releases=dist_releases     Ignored
	--skip-build
	--skip-cleanup
	--skip-load
EOF
}

. ${scriptsdir}/container_driver.sh
. ${scriptsdir}/distro_driver.sh

for_installer_dir="/home/ftp/build-results/pxfuse/for-installer/x86_64"
arch=amd64
distro=ubuntu
distro_release=""
container_system=lxc
container_tmpdir=/tmp/test-portworx-kernels.$$
leave_containers_running=false
make_args=""
force=false
logdir=$PWD
pxfuse_dir=""
prepare_build=false
skip_build=false
skip_cleanup=false
skip_load=false

exit_handler() {
    rm -rf "$local_tmp_dir"
}

echo "" >&2
echo "Command: pwx_test_kernel_pkgs_one_container.sh $*" >&2
echo "pwx_test_kernel_pkgs_one_container \$1=$1." >&2
echo "pwx_test_kernel_pkgs_one_container \$2=$2." >&2
echo "pwx_test_kernel_pkgs_one_container \$3=$3." >&2
echo "pwx_test_kernel_pkgs_one_container \$4=$4." >&2
echo "pwx_test_kernel_pkgs_one_container \$5=$5." >&2

i=1
count=1
while [[ $i -le $# ]] ; do
    arg="${@:$i:1}"
    echo "AJR pwx_test_kernel_pkgs_on_container.sh arg $count = $arg." >&2
    count=$((count + 1))
    case "$arg" in
	--all-releases ) true ;; # Ignore
	--arch=* ) arch=${arg#--arch=} ;;
	--containers=* ) container_system=${arg#--containers=} ;;
	--container-tmpdir=* ) container_tmpdir=${arg#--container-tmpdir=} ;;
	--distribution=* ) distro=${arg#--distribution=} ;;
	--force ) force=true ;;
	--help ) usage ; exit 0 ;;
	--leave-containers-running ) leave_containers_running=true ;;
	--logdir=* ) logdir=${arg#--logdir=} ;;
	--make-args=* ) make_args="${arg#--make-args=}" ;;
	--pxfuse=* ) pxfuse_dir=${arg#--pxfuse=} ;;
	--release=* ) distro_release=${arg#--release=} ;;
	--releases=* ) true ;;	# Ignore
	--prepare-build ) prepare_build=true ;;
	--skip-build ) skip_build=true ;;
	--skip-cleanup ) skip_cleanup=true ;;
	--skip-load ) skip_load=true ;;
	-- ) ;;
	--* )
	    echo "Unrecognized argument \"${arg}\"." >&2
	    usage >&2
	    exit 1 ;;
	* ) i=$((i + 1)) ; continue ;;
    esac

    set -- "${@:1:$((i - 1))}" "${@:$((i + 1))}"
    # ^^^ Deletes the current argument from the argument list.

    case "$arg" in
	-- ) break ;;
    esac
done

pkgformat=$distro
# Used by some function in distro_driver.sh.

if [[ $# -le 0 ]] ; then
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
	if [[ ".$first" = ".$other" ]] ; then
	    return 0
	fi
    done
    echo "$first"
}

guess_utsname_from_headers_dir() {
    local headers_dir="$1"
    local guess_utsname

    guess_utsname=$(in_container cat "${headers_dir}/include/config/kernel.release")
    if [[ $? = 0 ]] && [[ -n "$guess_utsname" ]] ; then
	echo "${guess_utsname}"
	return 0
    fi

    guess_utsname=${headers_dir#/usr/src/}
    guess_utsname=${guess_utsname#kernels/}
    guess_utsname=${guess_utsname#linux-headers-}

    case "$guess_utsname" in
	/tmp/coreos_remote_tmp_dir/* )
	    guess_utsname=${guess_utsname#/tmp/coreos_remote_tmp_dir/squashfs-root/lib/modules/}
	    guess_utsname=${guess_utsname%/}
	    guess_utsname=${guess_utsname%/build}
		    ;;
    esac
}

# Usage: test_kernel_pkgs_load pxfuse_dir container_tmpdir files...
test_kernel_pkgs_load() {
    local pxfuse_dir="$1"
    local container_tmpdir="$2"

    local result filename real dirname basename headers_dir
    local pkg_names deps_unfiltered dep_names dep_filtered
    local pxfuse_dir

    shift 2

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
	dep_filtered=$(filter_word "$dep" $pkg_names)
	dep_names="$dep_names $dep_filtered"
    done

    install_pkgs $dep_names
    uninstall_pkgs $pkg_names > /dev/null 2>&1 || true

    install_pkgs_dir "${container_tmpdir}/header_pkgs"
    result=$?

    if [[ $result != 0 ]] ; then
	uninstall_pkgs $pkg_names
	in_container rm -rf "$container_tmpdir"
    fi

    return $result
}

test_kernel_pkgs_build() {
    local pxfuse_dir="$1"
    local container_tmpdir="$2"
    local result_logdir="$3"
    local make_args="$4"

    local result_logdir
    local result headers_dir
    local pkg_names deps_unfiltered dep_names guess_utsname
    local dep_filtered
    local export_dir export_pkgs_dir export_module_dir
    local pxfuse_dir pxd_version
    local make_args=

    shift 4

    pkg_names=$(pkg_files_to_names "$@")
    deps_unfiltered=$(pkg_files_to_dependencies "$@")

    dep_names=""
    for dep in $deps_unfiltered ; do
	dep_filtered=$(filter_word "$dep" $pkg_names)
	dep_names="$dep_names $dep_filtered"
    done

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

    if [[ -z "$headers_dir" ]] ; then
        echo "FATAL: test_kernel_pkgs_func: null \$headers_dir, \$* = $*." >&2
        return 1
    fi

    result=0
    if $prepare_build ; then
	${distro}_prepare_build "${container_tmpdir}" "$@"
	result=$?
    fi
    if [[ $result = 0 ]] ; then
	in_container sh -c \
                 "cd ${container_tmpdir}/pxfuse_dir && \
                  autoreconf && \
                  ./configure && \
                  make KERNELPATH=$headers_dir $make_args"

	# make KERNELPATH=$headers_dir CC=\"gcc -fno-pie\"

	result=$?
    fi

    if [[ "$result" = 0 ]] ; then
        in_container tar -C "${container_tmpdir}/pxfuse_dir" -c px.ko |
            tar -C "${result_logdir}" -xpv

        guess_utsname=$(guess_utsname_from_headers_dir "$headers_dir")

        pxd_version=$(set -- $(egrep '^#define PXD_VERSION ' < "${pxfuse_dir}/pxd.h") ; echo $3)

        export_dir="${for_installer_dir}/${guess_utsname}"
        export_pkgs_dir="${export_dir}/packages"
        export_module_dir="${export_dir}/version/${pxd_version}"

        rm -rf "$export_pkgs_dir" "$export_module_dir"
        mkdir -p "$export_pkgs_dir" "$export_module_dir"
        ln --symbolic --force "$@" "${export_pkgs_dir}/"
        symlinks -c "$export_pkgs_dir" > /dev/null

        cp "${result_logdir}/px.ko" "${export_module_dir}/"

    fi # result = 0

    touch "${result_logdir}/ran_test"

    return $result
}

test_kernel_pkgs_func() {
    local result_logdir
    local result filename headers_dir
    local pkg_names deps_unfiltered dep_names arg guess_utsname
    local dep_filtered
    local export_dir export_pkgs_dir export_module_dir
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

    if ! $skip_load ; then
	test_kernel_pkgs_load "$pxfuse_dir" "$container_tmpdir" "$@" ||
	    return $?
    fi

    if ! $skip_build ; then
	test_kernel_pkgs_build "$pxfuse_dir" "$container_tmpdir" \
			       "$result_logdir" "$make_args" "$@"
	result=$?
    fi

    if ! $skip_cleanup ; then
	pkg_names=$(pkg_files_to_names "$@")
	uninstall_pkgs $pkg_names
	in_container rm -rf "$container_tmpdir"
	dist_clean_up_container
    fi

    echo "test_kernel_pkgs_func: build_exit_code=$result" >&2
    # if [[ "$result" != 0 ]] ; then
    #	sleep 3600
    # fi

    return $result
}

test_kernel_pkgs() {
    local result local
    local release="$distro_release"

    echo "test_kernel_pkgs: Attempting to test kernel package(s) on distribution $distro, release $release, make_args=$make_args." >&2
    echo "test_kernel_pkgs: Done printing make_args.  Doing start_container." >&2

    start_container --release="$release" dist_init_container

    echo "test_kernel_pkgs: Done with start_container.  Calling test_kernel_pkgs_func." >&2
    test_kernel_pkgs_func "$pxfuse_dir" "$logdir" "$make_args" "$@"
    result=$?

    if ! $leave_containers_running ; then
	stop_container
    fi

    return $result
}

test_kernel_pkgs "$@"
