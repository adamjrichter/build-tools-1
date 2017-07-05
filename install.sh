#!/bin/sh
( cd portworx-mirror-server && ./install.sh ) &&
( cd pwx_test_kernel_pkgs && ./install.sh ) &&
( cd pwx_test_kernels_in_mirror && ./install.sh )
