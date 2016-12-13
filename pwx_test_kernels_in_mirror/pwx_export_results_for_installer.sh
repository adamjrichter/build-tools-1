#!/bin/bash

scriptsdir=$PWD

for_installer_dir="/home/ftp/build-results/pxfuse/for-installer"

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
pxfuse_dir=

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
	--pxfuse=* ) pxfuse_dir=${1#--pxfuse=} ;;
	--* ) ;;
	* ) break ;;
    esac
    shift
done

if [[ ! -e "$logdir/exit_code" ]] ; then
    exit 0
fi

if ! read exit_code rest < "$logdir/exit_code" ; then
    exit $?
fi

if [[ ".$exit_code" != ".0" ]] ; then
    exit 0
fi

guess_utsname=$(egrep 'make KERNELPATH=' < "$logdir/build.log" |
		       sed 's/^.* KERNELPATH=//;s/ .*//' | sort -u)
guess_utsname=${guess_utsname#/usr/src/}
guess_utsname=${guess_utsname#kernels/}
guess_utsname=${guess_utsname#linux-header-}

pxd_version=$(set -- $(egrep '^#define PXD_VERSION ' < "${pxfuse_dir}/pxd.h") ; echo $3)

dir="${for_installer_dir}/${pxd_version}/${guess_utsname}"
rm -rf "$dir/packages"
mkdir -p "$dir/packages"
ln --symbolic --force "$@" "$dir/packages/"
# symlinks -c "$dir/packages" > /dev/null
cp "${logdir}/px.ko" "$dir/"
