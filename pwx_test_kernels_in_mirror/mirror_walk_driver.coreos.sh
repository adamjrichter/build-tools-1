# This is not a standalone program.  It is a library to be sourced by a shell
# script.

pkg_files_to_names_coreos()       { true ; }

get_default_mirror_dirs_coreos()
{
    local release protocol dir
    for release in stable alpha beta ; do
	for protocol in http https ; do
	    dir="/home/ftp/mirrors/${protocol}/${release}.release.core-os.net/amd64-usr"
	    if [[ -e "$dir" ]] ; then
		echo "$dir"
	    fi
	done
    done
}

walk_mirror_coreos() {
    local mirror_tree="$1"
    local return_status=0
    local file

    shift 1

    find "$mirror_tree" -name '*.iso' -type f -print0 |
	while read -r -d $'\0' file ; do
            if ! "$@" "$file" ; then
		return_status=$?
	    fi
	done

    #find "$mirror_tree" -name 'coreos_developer_container.bin.bz2' -type f \
    #     -print0 |
    #    while read -r -d $'\0' file ; do
    #        if ! "$@" "$file" ; then
    #            return_status=$?
    #        fi
    #    done

    return $return_status
}
