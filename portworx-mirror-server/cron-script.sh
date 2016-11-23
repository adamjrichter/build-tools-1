#!/bin/bash
# ^^^^^^^^^ /bin/bash because pwx-mirror-util.sh uses "[[".

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
logdir=/var/log/portworx-mirror-server
main_logfile=${logdir}/cron-script.log

error_code=0

copy_link_tree_remove_index_html()
{
    local from="$1"
    local to="$2"

    set +e
    symlinks -d "${to}"

    cp --symbolic-link --recursive --remove-destination "$from/." "$to"
    save_error

    find "$to" -name index.html -print0 | xargs --null -- rm -f
    find "$to" -type d | sort -r | xargs rmdir 2> /dev/null || true

    symlinks -cs "$to"
    save_error
}

run_all_verb_scripts()
{
    local verb="$1"
    local basename logfile
    set -x
    for script in ${scriptsdir}/${verb}-kernels.*.sh ; do
	basename="${script##*/}"
	logfile="$logdir/${basename}.log"
	mv --force "$logfile" "${logfile}.old" > /dev/null 2>&1 || true
        $script > "$logfile" 2>&1 &
    done
    wait
}

run_all_mirror_scripts()
{
    run_all_verb_scripts mirror
    copy_link_tree_remove_index_html "${mirrordir}" "${web_mirrordir}"
    # copy_link_tree_remove_index_html "${ftp_top}/build-results" "${web_top}/build-results"
}

run_all_test_scripts()
{
    # For now, disable this, because the new test scripts need to run
    # as root to run lxc commands.  This should be fixable as LXC does
    # have some support for running containers by a non-superuser
    # (via lxd?).
    #
    # run_all_verb_scripts test
    true
}

mkdir -p "$logdir"

mv --force "$main_logfile" "${main_logfile}.old}"
( run_all_mirror_scripts ; run_all_test_scripts ) > "$main_logfile" 2>&1 < /dev/null
save_error

exit $error_code
