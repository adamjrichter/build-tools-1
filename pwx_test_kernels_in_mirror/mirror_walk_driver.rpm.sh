# This is not a standalone program.  It is a library to be sourced by a shell
# script.

pkg_files_to_names_rpm () {
    rpm --query --package "$@"
}
