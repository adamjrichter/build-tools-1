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
    local file dir base devel_base base_without_kernel middle devel_file
    local rpm_arch return_status

    shift 1

    if [[ ".$arch" = ".amd64" ]] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    return_status=0
    find "$mirror_tree" -name "kernel-*headers-*.${rpm_arch}.rpm" -type f -print0 |
	while read -r -d $'\0' file ; do
	    dir=${file%/*}
	    base=${file##*/}
	    base_without_kernel="${base#kernel-}"
	    middle="${base_without_kernel%headers*}"
	    devel_base="kernel-${middle}devel-${base#kernel*-headers-}"
	    devel_file="$dir/$devel_base"
	    echo "AJR mirror_walk_driver.centos.sh: walk_mirror_centos:" >&2
	    echo "    dir=$dir" >&2
	    echo "    base=$base" >&2
	    echo "    devel_base=$devel_base" >&2
	    echo "    devel_file=$devel_file" >&2
	    if ! [[ -e "$devel_file" ]] ; then
		echo "    devel_file not found" >&2
		devel_file=""
	    else
		echo "    devel_file found" >&2
	    fi
	    echo "" >&2
	    # This assumes devel_file does not have spaces in its name:
            if ! "$@" "$file" $devel_file ; then
		return_status=$?
	    fi
	done

    return $return_status
}
