#!/bin/sh

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
logdir=${scriptsdir}/logs
logfile=${logdir}/$(date +%Y%m%d.%H:%M:%S).log

update_web_mirrors()
{
    set +e
    symlinks -d "${web_mirrordir}"

    cp --symbolic-link --recursive --remove-destination \
       "${mirrordir}/." "${web_mirrordir}"

    find "${web_mirrordir}" -name index.html -print0 | xargs --null -- rm -f
    find "${web_mirrordir}" -type d | sort -r | xargs rmdir 2> /dev/null || true

    symlinks -cs "${web_mirrordir}"
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
    update_web_mirrors
}

run_all_test_scripts()
{
    run_all_verb_scripts test
}

mkdir -p "$logdir"

( run_all_mirror_scripts ; run_all_test_scripts ) > "$logfile" 2>&1 < /dev/null
