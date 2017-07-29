# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common RPM drivers.

chromiumos_remote_tmp_dir=/tmp/chromiumos_remote_tmp_dir

pkg_files_to_names_chromiumos()       { pkg_files_to_names_ubuntu     "$@" ; }
pkg_files_to_dependencies_chromiumos() { pkg_files_to_dependencies_ubuntu "$@" ; }
install_pkgs_chromiumos()             { install_pkgs_ubuntu           "$@" ; }
uninstall_pkgs_chromiumos()           { uninstall_pkgs_ubuntu         "$@" ; }
pkgs_update_chromiumos()              { pkgs_update_ubuntu            "$@" ; }
dist_start_container_chromiumos()     { dist_start_container_ubuntu   "$@" ; }

start_container_chromiumos()
{
    # lxc-create does not provide a Chromiumos template, so build
    # under Ubuntu for now.

    start_container_generic --distribution=ubuntu "$@"
}

dist_init_container_chromiumos() { dist_init_container_ubuntu "$@" ; }

# Rely on dist_clean_up_container_chromiumos to remove the Chromiumos
# .iso files that were installed by install_pkgs_dir_chromiumos.  So,
# pkg_files_to_names_chromiumos and pkg_files_to_dependencies_chromiumoss
# do not output the names of any packages to remove or install.
pkg_files_to_names_chromiumos()        { true ; }
pkg_files_to_dependencies_chromiumos() { true ; }

install_pkgs_dir_chromiumos()
{
    in_container sh -c "
	set -x ;
	rm -rf $chromiumos_remote_tmp_dir
	mv $1/* $chromiumos_remote_tmp_dir"
}

get_dist_releases_chromiumos()
{
    # For now, build from the latest Ubuntu release only.  Chromiumos
    # does not include gcc by default.
    set -- $(get_dist_releases_ubuntu "$@")
    echo "$1"
}

pkg_files_to_kernel_dirs_chromiumos()
{
    echo "${chromiumos_remote_tmp_dir}"
}

dist_clean_up_container_chromiumos()
{
    in_container rm -rf "$chromiumos_remote_tmp_dir"
    dist_clean_up_container_ubuntu   "$@"
}

chromiumos_prepare_build() {
    local container_tmpdir="$1"
    local branch="$3"

    install_pkgs curl
    # FIXME?  Is it necessory to "apt-get install" some other packages,
    # besides curl?

    in_container sh -c \
               "cd ${chromiumos_remote_tmp_dir} &&
		git clean --force &&
		git checkout ${branch} &&
		./chromeos/scripts/prepareconfig chromiumos-x86_64 &&
		make prepare &&
		make scripts"
    # 		make &&
    #		make modules
    # "make && make modules" is for kernel symbol versioning.
}
