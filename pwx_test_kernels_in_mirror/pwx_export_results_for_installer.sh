#!/bin/bash

scriptsdir=$PWD

for_installer_dir="/home/ftp/build-results/pxfuse-for-installer"

usage()
{
    cat <<EOF
Usage:
        pwx_export_results_for_installer --recursive
		...or...
        pwx_export_results_for_installer [--logdir=... and other args
                accepted by pwx_test_kernel_pkgs] pkg_files...

The "--recursive" usage is probably normally the only one you want to invoke.
It calls pwx_export_results_for_install.sh via pwx_test_kernels_in_mirror for
a set of known distributions (currently, CentOS, Debian, Fedora, and Ubuntu).

pxw_export_results_for_install.sh installs directories in
${for_installer_dir} based
on the latest build results in /home/ftp/build-results/pxfuse.

EOF
}

logdir=

if [[ $# -eq 0 ]] ; then
    usage
    exit 0
fi

if [[ $# -eq 1 ]] && [[ ".$1" = ".--recursive" ]] ; then
    for dist in centos debian fedora ubuntu ; do
	pwx_test_kernels_in_mirror --distribution="$dist" --command="$0"
	symlinks -c "$for_installer_dir"
    done
    exit $?
fi

while [[ $# -gt 0 ]] ; do
    case "$1" in
	--  ) shift ; break ;;
	--logdir=* ) logdir=${1#--logdir=} ;;
	--* ) ;;
	* ) break ;;
    esac
    shift
done

set -e
[[ -e "$logdir/exit_code" ]]
read exit_code rest < "$logdir/exit_code"
guess_utsname=$(egrep 'make KERNELPATH=' < "$logdir/build.log" |
		       sed 's/^.* KERNELPATH=//;s/ .*//')
guess_utsname=${guess_utsname#kernels/}
guess_utsname=${guess_utsname#linux-header-}
dir="${for_installer_dir}/${guess_utsname}"
mkdir -p "$dir/packages"
ln --symbolic --force "$@" "$dir/packages/"
# symlinks -c "$dir/packages" > /dev/null
cp "${result_logdir}/px.ko" "$dir/"
