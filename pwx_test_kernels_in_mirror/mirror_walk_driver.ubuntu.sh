# This is not a standalone program.  It is a library to be sourced by a bash
# script (bash because it uses "[[").

# For now, just default everything to the common Debian drivers.

pkg_files_to_contents_ubuntu()    { pkg_files_to_contents_deb     "$@" ; }
pkg_files_to_names_ubuntu()       { pkg_files_to_names_deb        "$@" ; }

get_default_mirror_dirs_ubuntu()
{
    echo \
	/home/ftp/mirrors/http/security.ubuntu.com/ubuntu/pool/main/l/linux/ \
	/home/ftp/mirrors/http/kernel.ubuntu.com/~kernel-ppa/mainline
}

ubuntu_process_non_arch_file()
{
        local file="$1"
        local dir pkg_name dir arch_file return_status

	shift 1

        pkg_name=$(pkg_files_to_names_ubuntu "$file" | head -1)
        dir=${file%/*}

	return_status=0
        for arch_file in ${dir}/${pkg_name}-*_${arch}.deb ; do
            if [[ ! -e "$arch_file" ]] ; then
                echo "No architecuture-specific matches for $file" >&2
                continue
            fi
	    if ! "$@" "$arch_file" "$file" ; then
		return_status=$?
	    fi
        done
	return $return_status
}

walk_mirror_ubuntu() {
    local mirror_tree="$1"
    local file return_status


    shift 1
    return_status=0
    find "$mirror_tree" -name 'linux-headers-*_all.deb' -type f -print0 |
    while read -r -d $'\0' file ; do
        if ! ubuntu_process_non_arch_file "$file" "$@" < /dev/null ; then
	    return_status=$?
	fi
    done
    return $return_status
}
