# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Fedora drivers.

pkg_files_to_names_fedora()       { pkg_files_to_names_rpm        "$@" ; }

get_default_mirror_dirs_fedora()
{
    echo /home/ftp/mirrors/http/ftp.linux.ncsu.edu/pub/fedora/linux/releases
}

walk_mirror_fedora() {
    local mirror_tree="$1"
    local file dir base devel_base devel_file rpm_arch return_status

    shift 1

    if [[ ".$arch" = ".amd64" ]] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    return_status=0
    find "$mirror_tree" -name "kernel-headers-*.${rpm_arch}.rpm" -type f -print0 |
	while read -r -d $'\0' file ; do
	    dir=${file%/*}
	    base=${file##*/}
	    devel_base="kernel-devel-${base#kernel-headers-}"
	    devel_file="$dir/$devel_base"
	    if ! [[ -e "$devel_file" ]] ; then
		devel_file=""
	    fi
	    # This assumes devel_file does not have spaces in its name:
            if ! "$@" "$file" $devel_file ; then
		return_status=$?
	    fi
	done

    return $return_status
}
