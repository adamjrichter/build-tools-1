# TODO list

1. Add some "browse by date" links for /home/ftp/build-results/pxfuse-*.

2. Investigate adding support for mirroring Ubuntu repository https://bugs.launchpad.net/~canonical-kernel-team/+archive/ubuntu/ppa

3. Investigate linux-headers-4.2.0-36-generic_4.2.0-36.41_amd64.deb found by Ankit on https://bugs.launchpad.net/ ~canonical-kernel-team/+archive/ubuntu/ppa/+build/9593535

4. Make build logs directory tree more human readable by replacing some of the first elements of the directory paths with single element nicknames (for example, "https/kernel.ubuntu.com/~kernel-ppa/..." might become "ubuntu_kernel").

5. Maybe deal with kernel source-only RPM's on vault.centos.org.  Apparently the generated kernel header RPM's are not archived.  Maybe we should rebuild all of these from source.

