# This is not a standalone program.  It is a library to be sourced by a shell
# script.

pkg_files_to_names_deb () {
    local file
    for file in "$@" ; do
	( set -- $(dpkg --info "$file" | egrep '^ Package: ') ; echo "$2" )
    done
}
