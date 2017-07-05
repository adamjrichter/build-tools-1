#!/bin/sh

prefix=/usr/local
scriptsdir=${prefix}/share/pwx_test_kernels_in_mirror/scripts
build_results_dir=/home/ftp/build-results
downloads_dir=/home/ftp/downloads
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

install_crontab() {
    old_crontab=$( ( crontab -u root -l 2> /dev/null ) |
		       egrep -v pwx_test_kernels.cron_script.sh |
		       egrep -v '^#' ) || true

    ( echo "$old_crontab" ;
      echo "15 1 * * * $scriptsdir/pwx_test_kernels.cron_script.sh" ) |
	crontab -u root -
}

apt-get install --yes --quiet git rpm
# git is used by pwx_run_mirrors_in_script to clone px-fuse in a working
# directory if it is provided.
#
# rpm is needed for Centos support, for extracting information from .rpm files.

mkdir -p "${scriptsdir}" "${bindir}" "${build_results_dir}/pxfuse/by-checksum"

install_scripts "${scriptsdir}" \
		mirror_walk_driver.*.sh \
		mirror_walk_driver.sh \
		pwx_export_results_for_installer.sh \
		pwx_test_kernels.cron_script.sh \
		pwx_update_pxfuse_by_date.sh \
		test_report.sh

install_scripts "${bindir}" pwx_test_kernels_in_mirror

chmod a+x \
      "${bindir}/pwx_test_kernels_in_mirror" \
      "${scriptsdir}/pwx_export_results_for_installer.sh" \
      "${scriptsdir}/pwx_test_kernels.cron_script.sh" \
      "${scriptsdir}/pwx_update_pxfuse_by_date.sh" \
      "${scriptsdir}/test_report.sh"

# For now, comment out the installation of the crontab, as the cron
# script will be run by Jenson.
#
# install_crontab

for dist in centos debian fedora suse ubuntu ; do
    mkdir -p "${downloads_dir}/${dist}"
done

rm -f /var/www/html/build-results /var/www/html/downloads
ln -s "$build_results_dir" /var/www/html/build-results
ln -s "$downloads_dir" /var/www/html/downloads
