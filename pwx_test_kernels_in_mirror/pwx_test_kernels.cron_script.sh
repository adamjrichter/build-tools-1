#!/bin/sh

scriptsdir=$PWD

log_file=/var/log/pwx_test_kernels_in_mirror/pwx_test_kernels.cron_script.log

mkdir -p "${log_file%/*}"

if [ -e "$log_file" ] ; then
    mv --force "$log_file" "${log_file}.old"
fi
exec > "$log_file" 2>&1 < /dev/null

PATH=/usr/local/bin:$PATH
export PATH

stop_lxc_test_containers() {
    local dist="$1"

    lxc-ls -1 |
	egrep "^pwx_test_${dist}_" |
	while read container ; do
	    lxc-stop --name "$container"
	done
}

result=0
for dist in centos debian fedora ubuntu ; do
    if ! pwx_test_kernels_in_mirror --distribution="$dist" \
	 --command-args="--leave-containers-running --containers=lxc" ; then
	result=$?
    fi
    stop_lxc_test_containers "$dist"
done

$scriptsdir/pwx_update_pxfuse_by_date.sh
$scriptsdir/test_report.sh

echo "pwx_test_kernels.cron_script.sh: result=$result"

exit $result
