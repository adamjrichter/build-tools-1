# build-tools

This directory tree currently has three subdirectories:

portworx-mirror-server :
	The older all-in-one package of mirroring
	scripts and automated kernel testing (although only the Ubuntu
	version is known to work).  To install this software on
	your intended server machine (or virtual machine), cd to
	this subdirectory and do "sudo ./install.sh".

pwx_test_kernel_pkgs :
	Attempts to do a compilation test in a container on the a set of
	package files that defined the kernel headers for a single header.

pwx_test_kernels_in_mirror :
	Walks a mirror directory tree container kernel header packages
	files, figures out which ones are related to the same kernel,
	and invokes a test program on them.  The default test
	program is pwx_test_kernel_pkgs.
