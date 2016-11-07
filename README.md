# build-tools

# Quick install

To install this directory tree, unpack it anywhere, cd to the top of the
tree and do:

     	sudo ./install.sh


# Organization of this directory tree

This directory tree currently has three subdirectories:

portworx-mirror-server :
	The scripts that do the mirroring.  The scripts in this
	directory install in /home/pwxmirror, and are the only
	ones that know anything about the pwxmirror user, which
	exists so the mirror scripts do not have to run
	as superuser.

pwx_test_kernel_pkgs :
	Attempts to do a compilation test in a container on the a set of
	package files that defined the kernel headers for a single header.

pwx_test_kernels_in_mirror :
	Walks a mirror directory tree container kernel header packages
	files, figures out which ones are related to the same kernel,
	and invokes a test program on them.  The default test
	program is pwx_test_kernel_pkgs.
