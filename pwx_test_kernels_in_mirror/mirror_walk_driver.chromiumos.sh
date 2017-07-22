# This is not a standalone program.  It is a library to be sourced by a shell
# script.

pkg_files_to_names_chromiumos()       { true ; }

get_default_mirror_dirs_chromiumos()
{
    echo /home/ftp/mirrors/git/https/chromium.googlesource.com/chromiumos/third_party/kernel
}

walk_mirror_chromiumos() {
    local mirror_tree="$1"
    local return_status=0
    local branch

    shift 1

    "$@" --skip-build --skip-cleanup --all-releases "$mirror_tree"
    ( cd "$mirror_tree" && git branch -a ) |
	awk '{print $NF;}' |
	while read branch ; do
            if ! "$@" --skip-load --prepare-build --skip-cleanup "$mirror_tree/$branch" "$branch" ; then
		return_status=$?
	    fi
	done
    "$@" --skip-load --skip-build --all-releases "$mirror_tree"

    return $return_status
}
