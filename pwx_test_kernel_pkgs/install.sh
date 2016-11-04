#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/pwx_test_kernel_pkgs/scripts
bindir=${prefix}/bin

set -e

install_scripts() {
    local dir="$1"
    shift
    mkdir -p "$dir"
    for file in "$@" ; do
	sed -e "s|^scriptsdir=.*\$|scriptsdir=${scriptsdir}|" \
	    < "$file" > "$dir/$file"
    done
}

apt-get install --yes --quiet rpm
# Needed for Centos support, for extracting information from .rpm files.

mkdir -p "${scriptsdir}" "${bindir}"

install_scripts "${scriptsdir}" \
		container_driver.*.sh \
		container_driver.sh \
		distro_driver.*.sh \
		distro_driver.sh

install_scripts "${bindir}" pwx_test_kernel_pkgs.sh

chmod a+x "${bindir}/pwx_test_kernel_pkgs.sh"


