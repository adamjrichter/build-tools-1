# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Opensuse drivers.

pkg_files_to_kernel_dirs_opensuse() { pkg_files_to_kernel_dirs_rpm  "$@" ; }
pkg_files_to_names_opensuse()       { pkg_files_to_names_rpm        "$@" ; }
pkg_files_to_dependencies_opensuse() { pkg_files_to_dependencies_rpm "$@" ; }
dist_init_container_opensuse()      { dist_init_container_rpm       "$@" ; }
dist_clean_up_container_opensuse()  { dist_clean_up_container_rpm   "$@" ; }
dist_start_container_opensuse()     { dist_start_container_rpm      "$@"; }

install_pkgs_opensuse()
{
    in_container zypper --non-interactive --gpg-auto-import-keys install "$@"
}

install_pkgs_dir_opensuse()
{
    # FIXME.  What about dependencies?
    # in_container sh -c "rpm --install $1/*"
    echo "AJR install_pkgs_dir_opensuse: packages: " >&2
    in_container sh -c "cd $1 && ls -l" >&2
    in_container sh -c "zypper --non-interactive --gpg-auto-import-keys install $1/*"
}

uninstall_pkgs_opensuse()
{
    in_container zypper --non-interactive --gpg-auto-import-keys remove "$@"
}

pkgs_update_opensuse()
{
    in_container zypper --non-interactive --gpg-auto-import-keys update
}

#dist_init_container_opensuse()
#{
#    # in_container zypper --non-interactive --gpg-auto-import-keys install yum
#    dist_init_container_rpm "$@"
#}

get_dist_releases_opensuse()
{
    echo "42.2 13.2"
}
