# This is not a standalone program.  It is a library to be sourced by a shell
# script.

. $scriptsdir/distro_driver.deb.sh
. $scriptsdir/distro_driver.rpm.sh

. $scriptsdir/distro_driver.debian.sh
. $scriptsdir/distro_driver.ubuntu.sh
. $scriptsdir/distro_driver.centos.sh
. $scriptsdir/distro_driver.fedora.sh


get_dist_releases()        { "get_dist_releases_$distro"        "$@" ; }
dist_init_container()      { "dist_init_container_$distro"      "$@" ; }
pkg_files_to_kernel_dirs() { "pkg_files_to_kernel_dirs_$distro" "$@" ; }
pkg_files_to_names()       { "pkg_files_to_names_$distro"       "$@" ; }
pkg_files_to_dependencies() { "pkg_files_to_dependencies_$distro" "$@" ; }
install_pkgs()             { "install_pkgs_$distro"             "$@" ; }
install_pkgs_dir()         { "install_pkgs_dir_$distro"         "$@" ; }
uninstall_pkgs()           { "uninstall_pkgs_$distro"           "$@" ; }
pkgs_update()              { "pkgs_update_$distro"              "$@" ; }
test_kernel_pkgs_func()    { "test_kernel_pkgs_func_$distro"    "$@" ; }
dist_clean_up_container()  { "dist_clean_up_container_$distro"  "$@" ; }

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

# test_kernel_pkgs_func_default also sets the global variable ran_test
test_kernel_pkgs_func_default() {
    local container_tmpdir result_logdir
    local result filename real dirname basename headers_dir
    local pkg_names deps_unfiltered dep_names arg
    local container_tmpdir=/tmp/test-portworx-kernels.$$
    local pxfuse_dir
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
	fi # result = 0
	ran_test=true	# Global variable
    fi # result = 0

    uninstall_pkgs $pkg_names
    in_container rm -rf "$container_tmpdir"
    dist_clean_up_container

    echo "test_kernel_pkgs_func_default: build_exit_code=$result" >&2
    # if [[ "$result" != 0 ]] ; then
    #	sleep 3600
    # fi

    return $result
}
