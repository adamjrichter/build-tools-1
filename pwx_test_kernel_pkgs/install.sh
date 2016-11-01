#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/portworx-kernel-tester/scripts
#build_results_dir=/var/lib/portworx-kernel-tester/build-results
build_results_dir=/home/ftp/build-results
bindir=${prefix}/bin

set -e

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

apt-get install --yes --quiet rpm
# Needed for Centos support, for extracting information from .rpm files.

mkdir -p "${scriptsdir}" "${bindir}" "${build_results_dir}"

install_scripts "${scriptsdir}" \
		container_driver.*.sh \
		container_driver.sh \
		distro_driver.*.sh \
		distro_driver.sh

install_scripts "${bindir}" pwx_test_kernel_pkgs.sh

chmod a+x "${bindir}/pwx_test_kernel_pkgs.sh"


