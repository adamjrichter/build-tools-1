#!/bin/sh

# This self test script is not guaranteed to work.  It is included
# for reference so that you can adjust it and make it work.

pxfuse_dir=/home/ubuntu/git/px-fuse

if [[ ! -e "$pxfuse_dir" ]] ; then
    ( cd ${pxfuse_dir%/*} && git clone https://github.com/portworx/px-fuse.git )
fi

logdir=/tmp/self-test.debian.logdir

rm -f ${logdir}/done

sudo /home/ubuntu/build-tools/pwx_test_kernel_pkgs/install.sh &&
    sudo -- pwx_test_kernel_pkgs \
	 --arch=amd64 --containers=lxc --distribution=debian \
	 --logdir="$logdir" \
	 --pxfuse="${pxfuse_dir}" \
	/home/ftp/mirrors/http/snapshot.debian.org/archive/debian/./20151215T160159Z/pool/main/l/linux/linux-headers-4.2.0-0.bpo.1-all_4.2.6-3~bpo8+2_amd64.deb \
	/home/ftp/mirrors/http/snapshot.debian.org/archive/debian/./20151215T160159Z/pool/main/l/linux/linux-headers-4.2.0-0.bpo.1-all-amd64_4.2.6-3~bpo8+2_amd64.deb \
	/home/ftp/mirrors/http/snapshot.debian.org/archive/debian/./20151215T160159Z/pool/main/l/linux/linux-headers-4.2.0-0.bpo.1-amd64_4.2.6-3~bpo8+2_amd64.deb \
	/home/ftp/mirrors/http/snapshot.debian.org/archive/debian/./20151215T160159Z/pool/main/l/linux/linux-headers-4.2.0-0.bpo.1-common_4.2.6-3~bpo8+2_amd64.deb

echo AJR exit code $?
