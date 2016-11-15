# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Centos drivers.

pkg_files_to_names_centos()       { pkg_files_to_names_rpm        "$@" ; }

get_default_mirror_dirs_centos()
{
    echo \
	/home/ftp/mirrors/http/elrepo.org/linux/kernel \
	/home/ftp/mirrors/http/mirror.centos.org/centos
}

walk_mirror_centos() {
    local mirror_tree="$1"
    local file rpm_arch return_status

    shift 1

    if [[ ".$arch" = ".amd64" ]] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    return_status=0
    find "$mirror_tree" -name "kernel-*headers-*.${rpm_arch}.rpm" -type f -print0 |
	while read -r -d $'\0' file ; do
            if ! "$@" "$file" ; then
		return_status=$?
	    fi
	done

    return $return_status
}
