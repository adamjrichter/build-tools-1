# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Debian drivers.

dist_init_container_debian()      { dist_init_container_deb       "$@" ; }
pkg_files_to_kernel_dirs_debian() { pkg_files_to_kernel_dirs_deb  "$@" ; }
pkg_files_to_names_debian()       { pkg_files_to_names_deb        "$@" ; }
install_pkgs_debian()             { install_pkgs_deb              "$@" ; }
install_pkgs_dir_debian()         { install_pkgs_dir_deb          "$@" ; }
uninstall_pkgs_debian()           { uninstall_pkgs_deb            "$@" ; }
pkgs_update_debian()              { pkgs_update_deb               "$@" ; }
test_kernel_pkgs_func_debian()    { test_kernel_pkgs_func_default "$@" ; }

debian_pkgs_to_dependencies() {
    local pkgfile
    for pkgfile in "$@" ; do
	dpkg --info "$pkgfile"
    done |
	egrep '^ Depends: ' |
	sed 's/(.*)/ /g;s/,/ /g;s/^ Depends: //;s/ /\n/g' |
	sort -u
}

echo_word_per_line() {
    local word
    for word in "$@" ; do
	echo "$word"
    done
}

debian_find_pkgs_in_mirror() {
    local mirror_tree="$1"
    local pkgname

    shift 1
    for pkgname in "$@" ; do
	find "$mirror_tree" -name "${pkgname}_*_${arch}.deb" | sort --unique | tail -1
	# "sort | tail -1" selects the latest revision.
    done
}

debian_process_common_deb_file()
{
        local mirror_tree="$1"
        local file="$2"
        local pkg_name dir
	local prefix suffix middle possible_file header_files files
	local deps depfiles

	shift 2

	prefix="${file%-common_*}"
	suffix="${file#*-common_}"

        pkg_name=$(pkg_files_to_names_deb "${mirror_tree}/${file}")
        dir=${file%/*}

	header_files=""
	for middle in common all all-${arch} ${arch} ; do
	    possible_file="${mirror_tree}/${prefix}-${middle}_${suffix}"
	    if [[ -e "$possible_file" ]] ; then
		header_files="$header_files $possible_file"
	    fi
	done

	deps=$(debian_pkgs_to_dependencies $header_files)
	depfiles=$(debian_find_pkgs_in_mirror "$mirror_tree" $deps)

	"$@" $(echo_word_per_line $header_files $depfiles | sort --unique)
}

walk_mirror_debian() {
    local mirror_tree="$1"
    local file return_status

    shift 1
    return_status=0
    ( cd "$mirror_tree" && find . -name "linux-headers-*-common_*_${arch}.deb" -type f -print0 ) |
    while read -r -d $'\0' file ; do
        if ! debian_process_common_deb_file "$mirror_tree" "$file" "$@" < /dev/null ; then
	    return_status=$?
	fi
    done
    return $return_status
}
