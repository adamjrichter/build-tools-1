# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Debian drivers.

dist_init_container_ubuntu()      { "dist_init_container.deb"      "$@" ; }
pkg_files_to_kernel_dirs_ubuntu() { "pkg_files_to_kernel_dirs.deb" "$@" ; }
pkg_files_to_contents_ubuntu()    { "pkg_files_to_contents.deb"    "$@" ; }
pkg_files_to_names_ubuntu()       { "pkg_files_to_names.deb"       "$@" ; }
install_pkgs_ubuntu()             { "install_pkgs.deb"             "$@" ; }
install_pkg_files_ubuntu()        { "install_pkg_files.deb"        "$@" ; }
uninstall_pkgs_ubuntu()           { "uninstall_pkgs.deb"           "$@" ; }
pkgs_update_ubuntu()              { "pkgs_update.deb"              "$@" ; }
test_kernel_pkgs_func()           { "test_kernel_pkgs_func.default" "$@" ; }

ubuntu_process_non_arch_file()
{
        local file="$1"
        local dir pkg_name dir arch_file

	shift 1

        pkg_name=$(pkg_files_to_names_ubuntu "$file" | head -1)
        dir=${file%/*}

        for arch_file in ${dir}/${pkg_name}-*_${arch}.deb ; do
            if [ ! -e "$arch_file" ] ; then
                echo "No architecuture-specific matches for $file" >&2
                continue
            fi
	    "$@" "$arch_file" "$file"
        done
}

walk_mirror_ubuntu() {
    local mirror_tree="$1"
    local file

    shift 1
    find "$mirror_tree" -name 'linux-headers-*_all.deb' -type f -print0 |
    while read -r -d $'\0' file ; do
        ubuntu_process_non_arch_file "$file" "$@" < /dev/null
    done
}
