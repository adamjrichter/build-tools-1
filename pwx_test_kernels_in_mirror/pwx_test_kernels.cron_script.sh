#!/bin/sh

scriptsdir=$PWD

log_file=/home/ubuntu/pwx_test_kernels.cron_script.sh.log

exec > "$log_file" 2>&1

result=0
for dist in centos debian fedora ubuntu ; do
    if ! pwx_test_kernels_in_mirror.sh --containers=lxc --distribution="$dist" ; then
	result=$?
    fi
done

$scriptsdir/pwx_update_pxfuse_by_date.sh

exit $result
