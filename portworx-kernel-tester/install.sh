#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/portworx-kernel-tester/scripts
build_results_dir=/var/lib/portworx-kernel-tester/build-results
bindir=${prefix}/bin

install_scripts() {
    local dir="$1"
    shift
    mkdir -p "$dir"
    for file in "$@" ; do
	sed -e "s|^scriptsdir=.*\$|scriptsdir=${scriptsdir}|" \
	    -e "s|^build_results_dir=.*\$|build_results_dir=${build_results_dir}|" \
	    < "$file" > "$dir/$file"
    done
}

install_scripts "${scriptsdir}" \
		container_driver.*.sh \
		container_driver.sh \
		distro_driver.*.sh \
		distro_driver.sh

install_scripts "${bindir}" \
		pwx_test_kernel_pkgs.sh \
		pwx_test_kernels_in_mirror.sh

chmod a+x "${bindir}/pwx_test_kernel_pkgs.sh" "${bindir}/pwx_test_kernels_in_mirror.sh"

