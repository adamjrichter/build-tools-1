#!/bin/sh

# This self test script is not guaranteed to work.  It is included
# for reference so that you can adjust it and make it work.

pxfuse_dir=/home/ubuntu/git/px-fuse

if [ ! -e "$pxfuse_dir" ] ; then
    cd ${pxfuse_dir%/*} && git clone https://github.com/portworx/px-fuse.git
fi

logdir=/tmp/self-test.ubuntu.logdir

rm -f ${logdir}/done

sudo /home/ubuntu/build-tools/pwx_test_kernel_pkgs/install.sh &&
    sudo pwx_test_kernel_pkgs.sh \
	 --arch=amd64 --containers=lxc --distribution=ubuntu \
	 --logdir="$logdir" \
	 --pxfuse="${pxfuse_dir}" \
	 /home/ftp/mirrors/http/kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.11-ckt35-trusty/linux-headers-3.13.11-031311ckt35-generic_3.13.11-031311ckt35.201602161330_amd64.deb \
	 /home/ftp/mirrors/http/kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.11-ckt35-trusty/linux-headers-3.13.11-031311ckt35_3.13.11-031311ckt35.201602161330_all.deb

echo AJR exit code $?
