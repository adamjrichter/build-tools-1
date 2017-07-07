# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common RPM drivers.

coreos_remote_tmp_dir=/tmp/coreos_remote_tmp_dir

pkg_files_to_names_coreos()       { pkg_files_to_names_rpm        "$@" ; }
pkg_files_to_dependencies_coreos() { pkg_files_to_dependencies_rpm "$@" ; }
install_pkgs_coreos()             { install_pkgs_rpm              "$@" ; }
install_pkgs_dir_coreos()         { install_pkgs_dir_rpm          "$@" ; }
uninstall_pkgs_coreos()           { uninstall_pkgs_rpm            "$@" ; }
pkgs_update_coreos()              { pkgs_update_rpm               "$@" ; }
dist_start_container_coreos()     { dist_start_container_rpm      "$@" ; }

start_container_coreos()
{
    # lxc-create does not provide a CoreOS template, so build
    # under CentOS for now.

    start_container_generic --distribution=centos "$@"
}

dist_init_container_coreos() { dist_init_container_rpm "$@" ; }

install_pkgs_coreos()             { install_pkgs_rpm              "$@" ; }
install_pkgs_dir_coreos()         { install_pkgs_dir_rpm          "$@" ; }
uninstall_pkgs_coreos()           { uninstall_pkgs_rpm            "$@" ; }

# Rely on dist_clean_up_container_coreos to remove the CoreOS
# .iso files that were installed by install_pkgs_dir_coreos.  So,
# pkg_files_to_names_coreos and pkg_files_to_dependencies_coreoss
# do not output the names of any packages to remove or install.
pkg_files_to_names_coreos()        { true ; }
pkg_files_to_dependencies_coreos() { true ; }

install_pkgs_dir_coreos()
{
    install_pkgs genisoimage squashfs-tools
    in_container sh -c "
	set -x ;
	rm -rf $coreos_remote_tmp_dir/squashfs-root ;
	mkdir -p $coreos_remote_tmp_dir &&
	for iso_file in $1/* ; do
		isoinfo -J -R -x /coreos/cpio.gz -i \$iso_file |
			gunzip |
			( cd $coreos_remote_tmp_dir && cpio --extract usr.squashfs ) &&
		( cd $coreos_remote_tmp_dir && unsquashfs usr.squashfs lib lib64/modules ) ;
	done"
}

get_dist_releases_coreos()
{
    # For now, build from the latest Centos release only.  CoreOS
    # does not include gcc by default.
    set -- $(get_dist_releases_centos "$@")
    echo "$1"
}

pkg_files_to_kernel_dirs_coreos()
{
    in_container sh -c "echo $coreos_remote_tmp_dir/squashfs-root/lib/modules/[0-9]*/build"
}

dist_clean_up_container_coreos()
{
    in_container rm -rf "$coreos_remote_tmp_dir"
    dist_clean_up_container_rpm   "$@"
}
