# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Debian drivers.

dist_init_container_debian()      { "dist_init_container.deb"      "$@" ; }
pkg_files_to_kernel_dirs_debian() { "pkg_files_to_kernel_dirs.deb" "$@" ; }
pkg_files_to_names_debian()       { "pkg_files_to_names.deb"       "$@" ; }
install_pkgs_debian()             { "install_pkgs.deb"             "$@" ; }
install_pkg_files_debian()        { "install_pkg_files.deb"        "$@" ; }
uninstall_pkgs_debian()           { "uninstall_pkgs.deb"           "$@" ; }
pkgs_update_debian()              { "pkgs_update.deb"              "$@" ; }
test_kernel_pkgs_func()           { "test_kernel_pkgs_func.default" "$@" ; }

debian_pkgs_to_dependencies() {
    local pkgfile
    for pkgfile in "$@" ; do
	dpkg --info "$pkgfile"
    done |
	egrep '^ Depends: ' |
	sed 's/^ Depends: //;s/ /\n/g' |
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
	find "$mirror_tree" -name "${pkgname}-*.deb"
    done |
	sort --unique
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

        pkg_name=$(dpkg_file_to_pkg_name "$file")
        dir=${file%/*}

	header_files=""
	for middle in common all all-${arch} ${arch} ; do
	    possible_file="${mirror_tree}/${prefix}-${middle}_${suffix}"
	    if [[ -e "$possible_file" ]] ; then
		header_files="$header_files $possible_file"
	    fi
	done

	deps=$(debian_pkgs_to_dependencies $files)
	depfiles=$(debian_find_pkgs_in_mirror "$mirror_tree" $deps)

	"$@" $(echo_word_per_line $files $depfiles | sort --unique)
}

walk_mirror_debian() {
    local mirror_tree="$1"
    local file

    shift 1
    ( cd "$mirror_tree" && find . -name "linux-headers-*-common_*_${arch}.deb" -type f -print0 ) |
    while read -r -d $'\0' file ; do
        debian_process_common_deb_file "$mirror_tree" "$file" "$@" < /dev/null
    done
}
