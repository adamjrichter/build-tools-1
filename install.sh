#!/bin/sh
( cd portworx-kernel-tester && ./install.sh ) &&
( cd portworx-mirror-server && ./install.sh )
