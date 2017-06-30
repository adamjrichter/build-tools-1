#!/bin/sh
# Usage:
# extract-suse-kernels-from-dvd-files.sh file1.iso file2.iso ....

for iso in "$@" ; do
    no_dir=${iso##*/}
    no_iso=${no_dir%.iso}
    mount -o ro,loop -t iso9660 "$iso" /mnt
    unpack_dir="/home/adam/portworx/dvd_excerpts/$no_iso"
    mkdir -p "$unpack_dir"
    (cd /mnt && (
	    find . \( -name 'kernel-*devel*.rpm' -o \
		 -name 'kernel-*source*.rpm' \) -print0 |
		xargs --null -- tar -cp ) ) |
	( cd "$unpack_dir" && tar xp )
    umount /mnt
done
