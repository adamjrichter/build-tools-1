# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common RPM drivers.

# Change the following line to ...= false to inhibit saving .tar.xz files
# of successful versioned kernel builds.
chromiumos_save_kernel_builds=true
# chromiumos_save_kernel_builds=false

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
        set -x &&
        rm -rf ${chromiumos_remote_tmp_dir}/kernel &&
        mkdir -p ${chromiumos_remote_tmp_dir} &&
        mv $1/* ${chromiumos_remote_tmp_dir}/kernel"
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
    echo "${chromiumos_remote_tmp_dir}/kernel"
}

dist_clean_up_container_chromiumos()
{
    in_container rm -rf "${chromiumos_remote_tmp_dir}/kernel"
    dist_clean_up_container_ubuntu   "$@"
}

chromiumos_build() {
    local container_tmpdir="$1"
    local headers_dir="$2"
    local make_args="$3"
    local log_subdir="$4"
    local branch="$5"
    local commit_name=${log_subdir##*/}
    local commit_archive="/home/ftp/cache/kernels/chromiumos/${commit_name}.tar.xz"
    local build_dir
    local result

    # Currently, px.ko does not depend on any other kernel modules, so
    # we could probably skip making the kernel modules.  If you want to try
    # this optimization, set the variable make_modules_command to "true" (a
    # no-op) instead of "make modules":
    #
    local make_modules_command="true"
    # local make_modules_command="make modules"

    install_pkgs curl xz-utils
    # FIXME?  Is it necessory to "apt-get install" some other packages,
    # besides curl?

    if [[ -e "${commit_archive}" ]] &&
       ! tar -tJ < "${commit_archive}" > /dev/null ; then

        rm -f "${commit_archive}"
    fi

    if [[ -e "${commit_archive}" ]] ; then
        in_container sh -c \
            "rm -rf ${container_tmpdir}/kernel &&
             mkdir -p ${container_tmpdir}/kernel &&
             cd ${container_tmpdir} &&
             tar -xpJ kernel" < "${commit_archive}" || return $?
        headers_dir="${container_tmpdir}/kernel"
    else
        in_container sh -c \
               "cd ${chromiumos_remote_tmp_dir}/kernel &&
                git clean --force &&
                git checkout ${branch} &&
                ./chromeos/scripts/prepareconfig chromiumos-x86_64 &&
                make prepare &&
                make scripts" || return $?
    fi

    default_build_func "${container_tmpdir}" "${headers_dir}" "${make_args}" ||
        return $?

    if [[ -e "${commit_archive}" ]] ; then
        return 0
    fi

    if ( in_container cat ${chromiumos_remote_tmp_dir}/kernel/.config |
               grep '# CONFIG_MODVERSIONS is not set' ) ; then

        # No need to build and save kernel symbol versions if kernel symbol
        # versioning is disabled.
        return 0
    fi

    # Build the whole kernel (and possibly modules, depending on the
    # value of ${make_modules_command}), just to have kernel symbol
    # versioning information against which px.ko.
    in_container sh -c \
        "cd ${chromiumos_remote_tmp_dir}/kernel &&
         make vmlinux &&
         ${make_modules_command} &&
         cd ${container_tmpdir}/pxfuse_dir &&
         make KERNELPATH=$headers_dir clean" || return $?

    mkdir -p "${commit_archive%/*}" || return $?

    if $chromiumos_save_kernel_builds ; then
        in_container sh -c "cd ${chromiumos_remote_tmp_dir} && tar -cJ kernel" \
                     > "${commit_archive}"
        result=$?
        if [[ $result != 0 ]] ; then
            rm -f "${commit_archive}"
            return $result
        fi
    fi

    default_build_func "${container_tmpdir}" "${headers_dir}" "${make_args}"
}
