#!/bin/sh

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
logdir=${scriptsdir}/logs
logfile=${logdir}/$(date +%Y%m%d.%H:%M:%S).log

copy_link_tree_remove_index_html()
{
    local from="$1"
    local to="$2"

    set +e
    symlinks -d "${to}"

    cp --symbolic-link --recursive --remove-destination "$from/." "$to"

    find "$to" -name index.html -print0 | xargs --null -- rm -f
    find "$to" -type d | sort -r | xargs rmdir 2> /dev/null || true

    symlinks -cs "$to"
}

run_all_verb_scripts()
{
    local verb="$1"
    set -x
    for script in ${scriptsdir}/${verb}-kernels.*.sh ; do
        $script
    done
}

run_all_mirror_scripts()
{
    run_all_verb_scripts mirror
    copy_link_tree_remove_index_html "${mirrordir}" "${web_mirrordir}"
    copy_link_tree_remove_index_html "${ftp_top}/build-results" "${web_top}/build-results"
}

run_all_test_scripts()
{
    run_all_verb_scripts test
}

mkdir -p "$logdir"

( run_all_mirror_scripts ; run_all_test_scripts ) > "$logfile" 2>&1 < /dev/null
