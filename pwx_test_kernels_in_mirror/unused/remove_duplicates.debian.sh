#!/bin/bash

# remove_duplicates.debian.sh removes duplicate .deb files and the
# resulting .deb directory in ~ftp/build-results/pxfuse/by-date/latest that
# they may have caused to be created.
#
# These duplicate files should only have been created because of a
# previous bug in
# build-tools/portworx-mirror-server/mirror-kernels.debian.sh that
# I think is now fixed.

usage()
{
    echo "Usage: remove_dupcliates.debian.sh [--really]"
    echo ""
    echo "Without the \"--really\" argument, no files or directories are"
    echo "removed.  Instead, only the actions that would have been done"
    echo "are shown."
}

really_do_commands=false

show_duplicates_from_later_directories()
{
    local oldname filename filepath

    oldname=

    awk -F/ '{print $NF, $0}' |
        sort |
          while read filename filepath ; do
              if [[ ".$filename" = ".$oldname" ]] ; then
                  echo "$filepath"
              fi
              oldname="$filename"
          done
}

maybe_do_command_on_paths() {
    if $really_do_commands ; then
	xargs --no-run-if-empty -- "$@"
    else
	echo "Because you did not specify \"--do-it\" on the command line,"
	echo "the following command is not actually being run."
	echo "The command \"$*\" would have been run on the following file paths:"
	cat
	echo ""
    fi
}

maybe_do_command_on_later_duplicates() {
    show_duplicates_from_later_directories | maybe_do_command_on_paths "$@"
}


remove_duplicate_files()
{
    find /home/ftp/mirrors/http/snapshot.debian.org/archive/debian/ \
	 -name '*.deb' -type f -print |
	maybe_do_command_on_later_duplicates rm -f
}

remove_duplicate_build_dirs()
{
    find /home/ftp/build-results/pxfuse/by-date/latest/debian/http/snapshot.debian.org/archive/debian/ \
	 -name '*.deb' -type d -print |
	maybe_do_command_on_later_duplicates rm -rf
}

if [[ $# -eq 0 ]] ; then
    true
elif [[ $# -eq 1 ]] && [[ ".$1" = ".--really" ]] ; then
    really_do_commands=true
else
    usage >&2
    exit 1
fi

remove_duplicate_files
remove_duplicate_build_dirs
/usr/local/share/pwx_test_kernels_in_mirror/scripts/test_report.sh
