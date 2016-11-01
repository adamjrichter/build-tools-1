#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/pwx_test_kernels_in_mirror/scripts
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
		mirror_walk_driver.*.sh \
		mirror_walk_driver.sh \
		pwx_test_kernels.cron_script.sh \
		pwx_update_pxfuse_by_date.sh

install_scripts "${bindir}" pwx_test_kernels_in_mirror.sh

chmod a+x \
      "${bindir}/pwx_test_kernels_in_mirror.sh" \
      "${scriptsdir}/pwx_test_kernels.cron_script.sh" \
      "${scriptsdir}/pwx_update_pxfuse_by_date.sh"

old_crontab=$( ( crontab -u root -l 2> /dev/null ) |
	      egrep -v pwx_test_kernels.cron_script.sh |
	      egrep -v '^#' ) || true
( echo "$old_crontab" ;
  echo "15 1 * * * $scriptsdir/pwx_test_kernels.cron_script.sh" ) |
    crontab -u root -

rm -f /var/www/html/build-results
ln -s ${build_results_dir} /var/www/html/build-results
