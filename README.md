# build-tools

This directory tree currently has two subdirectories:

portworx-mirror-server :
	The older all-in-one package of mirroring
	scripts and automated kernel testing (although only the Ubuntu
	version is known to work).  To install this software on
	your intended server machine (or virtual machine), cd to
	this subdirectory and do "sudo ./install.sh".

portworx-kernel-tester :
	A rearrange of the part of portworx-mirror-server that deals
	with automated compilation testing, intended to make it more
	extensible and retargetable to different container systems
	for executing the tests.
