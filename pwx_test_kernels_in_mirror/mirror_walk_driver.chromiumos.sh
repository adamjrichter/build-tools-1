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
    local branch last_commit
    local container_tmpdir=/tmp/test-portworx-kernels.$$

    shift 1

    "$@" --skip-build --skip-cleanup --all-releases \
	 "--container-tmpdir=${container_tmpdir}" "$mirror_tree"

    ( cd "$mirror_tree" && git branch -a ) |
	awk '{print $NF;}' |
	while read branch ; do
	    last_commit=$(cd "$mirror_tree" && git rev-list --max-count=1 "$branch" )
	    echo "AJR walk_mirror_chromiumos: branch=${branch} last_commit=${last_commit}." >&2
            if ! "$@" --skip-load --prepare-build --skip-cleanup \
		 "--container-tmpdir=${container_tmpdir}" \
		 "$mirror_tree/${branch}/commit-${last_commit}" "$branch" ; then
		return_status=$?
	    fi
	done

    "$@" --skip-load --skip-build --all-releases \
	 "--container-tmpdir=${container_tmpdir}" "$mirror_tree"

    return $return_status
}
