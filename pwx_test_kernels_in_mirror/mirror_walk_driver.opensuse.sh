# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Opensuse drivers.

pkg_files_to_names_opensuse()       { pkg_files_to_names_rpm        "$@" ; }

get_default_mirror_dirs_opensuse()
{
    echo \
	/home/ftp/mirrors/http/download.opensuse.org/distribution \
	/home/ftp/mirrors/http/download.opensuse.org/update \
	/home/ftp/mirrors/dvd/suse

    # echo /home/ftp/mirrors/http/dev.opensuse.org
}

walk_nonarch_file_opensuse()
{
    local nonarch_full_path="$1"
    local noarch_dir=${nonarch_full_path%/*}
    local all_archs_dir=${noarch_dir%/*}

    local filename=${nonarch_full_path##*/}
    local noarch_filename=${filename%.noarch.rpm}
    local version=${noarch_filename#kernel-devel-}
    local return_status=0
    local arch_full_path rpm_arch
    local adjective src_rpm src_dep src_rpm

    shift

    if [[ ".$arch" = ".amd64" ]] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    find "$all_archs_dir" -name "kernel-*-devel-${version}.${rpm_arch}.rpm" \
	 -print0 |
	while read -r -d $'\0' arch_full_path ; do
	    src_dep=$(rpm -qpR "$arch_full_path" 2> /dev/null |
			     egrep 'kernel-source.* = ' |
			     sed 's/ *= */-/' )
	    if [[ -n "$src_dep" ]] ; then
		src_rpm=$(find "$noarch_dir" -name "${src_dep}-*.noarch.rpm" |
				  sort | tail -1)
	    else
		src_rpm=""
	    fi
	    
	    if ! "$@" "$arch_full_path" "$nonarch_full_path" $src_rpm ; then
		return_status=$?
	    fi
	done
    return $return_status
}

read0_walk_nonarch_files_opensuse()
{
    local return_status=0
    local nonarch_file

    while read -r -d $'\0' nonarch_file ; do
	if ! walk_nonarch_file_opensuse "$nonarch_file" "$@" ; then
	    return_status=$?
	fi
    done
    return $return_status
}


walk_mirror_opensuse()
{
    local mirror_tree="$1"
    local kernel_regexp=".*/kernel-devel-${above_3_9_regexp}[0-9.]*-[0-9.]*\.noarch\.rpm"

    shift

    find "$mirror_tree" -regextype egrep -regex "$kernel_regexp" -type f \
	 -print0 |
	read0_walk_nonarch_files_opensuse "$@"
}
