#!/bin/sh

logdir=/home/ubuntu/pwx_test_kernels.cron_script.sh.log

exec > "$logdir" 2>&1

#for distribution in centos debian ubuntu ; do
for dist in centos ubuntu ; do
    pwx_test_kernels_in_mirror.sh --containers=lxc --distribution="$dist"
done
