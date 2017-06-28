# This is not a standalone program.  It is a library to be sourced by a shell
# script.

dist_init_container_rpm() {
    # dist_init_container_rpm calls {,un}install_pkgs rather than
    # {,un}install_pkgs_rpm so that OpenSUSE can use this function
    # while still having {,un}install_pkgs_opensuse.
    local iteration
    iteration=1
    while [[ $iteration -lt 10 ]] ; do
        install_pkgs autoconf automake gcc gcc-c++ git make tar
	if in_container autoreconf --help > /dev/null 2>&1 ; then
	    break
	fi
	iteration=$((iteration + 1))
    done
    echo "AJR dist_init_container_rpm: packages loaded after iteration=$iteration" >&2
    
    uninstall_pkgs kernel-devel   # FIXME? Is this command necessary?
}

pkg_files_to_kernel_dirs_rpm() {
    rpm --query --list --package "$@" |
	awk '{print $NF}' |
	egrep '^(\.?/usr/src/kernels/|/usr/src/linux-[0-9])' |
	sed 's:^\.\?\(/usr/src/\(kernels/\|linux-[0-9]\)[^/]*\)/.*$:\1:' |
	uniq |
	sort -u
	# | egrep -v '^/usr/src/linux-[0-9.]+-[0-9.]+-obj$'
}

pkg_files_to_names_rpm () {
    rpm --query --package --qf '%{NAME}\n' "$@"
}

pkg_files_to_dependencies_rpm() {
    local pkgfile
    for pkgfile in "$@" ; do
	rpm --query --package --requires "$pkgfile"
    done |
	sed 's/[( <=].*$//' |
	sort -u
}

#install_pkgs_dir_rpm() { in_container sh -c "rpm --install $1/*" ; }
install_pkgs_dir_rpm() {
    in_container sh -c "yum --assumeyes upgrade $1/*"
    in_container sh -c "yum --assumeyes install $1/*"
}

install_pkgs_dir_rpm_notyet()
{
    # in_container sh -c "yum --assumeyes install $1/*" ;
    # yum fails when asked to install a file that is already installed.
    # So, try to install the packages one by one, until all installs fail.
    in_container sh -c "yum --assumeyes --skip-broken install $1/*" ;
    return $?	 # AJR
    while in_container sh -c \
	"for pkgfile in $1/* ; do yum --assumeyes install \$pkgfile && exit 0 ; done ; false" ; do
	true
    done
}

install_pkgs_rpm()     { in_container yum --assumeyes --quiet install "$@" ; }
#uninstall_pkgs_rpm()   { in_container rpm --erase "$@" ; }
uninstall_pkgs_rpm()   { in_container yum --assumeyes remove "$@" ; }
pkgs_update_rpm()      { in_container yum --assumeyes --quiet update ; }
dist_clean_up_container_rpm() { true; }	# No-op for now.
dist_start_container_rpm() { true; }
