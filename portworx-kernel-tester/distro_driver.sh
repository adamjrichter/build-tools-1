# This is not a standalone program.  It is a library to be sourced by a shell
# script.

. $scriptsdir/distro_driver.deb.sh
. $scriptsdir/distro_driver.rpm.sh

. $scriptsdir/distro_driver.debian.sh
. $scriptsdir/distro_driver.ubuntu.sh
. $scriptsdir/distro_driver.centos.sh


dist_init_container()      { "dist_init_container_$distro"      "$@" ; }
pkg_files_to_kernel_dirs() { "pkg_files_to_kernel_dirs_$distro" "$@" ; }
pkg_files_to_names()       { "pkg_files_to_names_$distro"       "$@" ; }
install_pkgs()             { "install_pkgs_$distro"             "$@" ; }
install_pkgs_dir()         { "install_pkgs_dir_$distro"         "$@" ; }
uninstall_pkgs()           { "uninstall_pkgs_$distro"           "$@" ; }
pkgs_update()              { "pkgs_update_$distro"              "$@" ; }
walk_mirror()              { "walk_mirror_$distro"              "$@" ; }
test_kernel_pkgs_func()    { "test_kernel_pkgs_func_$distro"    "$@" ; }


test_kernel_pkgs_func_default() {
    local container_tmpdir result_logdir
    local result filename real dirname basename headers_dir
    local force=false

    while [[ $# -gt 0 ]] ; do
	case "$1" in
	    --force ) force=true ;;
	    * ) break ;;
	esac
	shift
    done

    container_tmpdir="$1"
    result_logdir="$2"

    shift 2

    if [[ -e "$result_logdir/done" ]] ; then
	echo "test_kernel_pkgs_func_default: $result_logdir/done exists.  Skipping."
    fi

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

    install_pkgs_dir "${container_tmpdir}/header_pkgs"

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
                  make KERNELPATH=$headers_dir"

    result=$?
    echo "test_kernel_pkgs_func_default: build_exit_code=$result" >&2
    if [ "$result" = 0 ] ; then
	in_container tar -C "${container_tmpdir}/pxfuse_dir" -c px.ko |
	    tar -C "${results_log_dir}" -xpv
    fi
    uninstall_pkgs $(pkg_files_to_names "$@")
    return $result
}
