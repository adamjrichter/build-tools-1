#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/pwxmirror/scripts
build_resuls_dir=/var/lib/pwxmirror/build-results
bindir=${prefix}/bin

install_scripts() {
    local dir="$1"
    shift
    mkdir -p "$dir"
    for file in "$@" ; do
	sed -e "s|^scriptsdir=.*\$|scriptsdir=${scriptsdir}|" -e "s|^build_results_dir=.*\$|build_results_dir=${build_results_dir}|" \
	    < "$file" > "$dir/$file"
    done
}

install_scripts "${scriptsdir}" \
		container_driver.*.sh \
		container_driver.sh \
		distro_driver.*.sh \
		distro_driver.sh

install_scripts "${bindir}" \
		test_kernel_pkgs.sh \
		test_kernels_in_mirror.sh
