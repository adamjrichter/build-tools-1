# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Opensuse drivers.

pkg_files_to_names_suse()       { pkg_files_to_names_rpm        "$@" ; }

get_default_mirror_dirs_suse()
{
    echo \
	/home/ftp/mirrors/http/download.opensuse.org/distribution \
	/home/ftp/mirrors/http/download.opensuse.org/update \
	/home/ftp/mirrors/dvd/suse

	# echo /home/ftp/mirrors/http/dev.suse.org
}

list_noarch_dirs_suse() {
    local noarch_dir="$1"
    local dvds_dir="/home/ftp/mirrors/dvd/suse"

    echo "$noarch_dir"

    # Skip directories that are not named to indicate a CD or DVD image.
    case "$noarch_dir" in
	${dvds_dir}/SLE-*-DVD[0-9] ) ;;
	${dvds_dir}/SLE-*-DVD[0-9]/* ) ;;
	${dvds_dir}/SLE-*-CD[0-9] ) ;;
	${dvds_dir}/SLE-*-CD[0-9]/* ) ;;
	* ) return 0 ;;
    esac

    within_discs_dir=${noarch_dir#${dvds_dir}/}
    disc=${within_discs_dir%%/*}
    disc_no_number=${disc%[0-9]}
    parent_disc_no_number=$(echo "$disc_no_number" |
	sed 's/^SLE\(S\?-[0-9]\+\(-SP[0-9]\+\)\?\-\)[A-Za-z]\+-/SLE\1Server-/')

    (
	cd "$dvds_dir" &&
	    for dir in $dvds_dir/${disc_no_number}[0-9]/suse/noarch $dvds_dir/${parent_disc_no_number}[0-9]/suse/noarch ; do
		if [[ -e "$dir" ]] ; then
		    echo "$dir"
		fi
	    done
    )
}

find_noarch_file_suse()
{
    local all_archs_dir="$1"
    local name_hyphen_version="$2"
    local file="${name_hyphen_vesion}.noarch.rpm"
    local dir dir_and_file

    for dir in $(list_noarch_dirs_suse "$all_archs_dir") ; do
	dir_and_file="$dir/$file"
	if [ ! -e "$dir_and_file" ] ; then
	    dir_and_file=$(find "$dir" -maxdepth 1 -name "${name_hyphen_version}.[0-9]*.noarch.rpm" -print | sort -r | head -1)
	fi
	if [ -e "$dir_and_file" ] ; then
	    echo "$dir_and_file"
	    break
	fi
    done
}

maybe_add_deps_rpms_suse() {
    local full_path="$1"
    local all_archs_dir=${full_path%/*/*}
    local dep deps

    deps=$(rpm -qpR "$full_path" 2> /dev/null |
		     egrep ' = ' |
		     sed 's/ *= */-/' |
		     sort -u)
    for dep in $deps ; do
	find_noarch_file_suse "$all_archs_dir" "${dep}"
    done
}

walk_arch_file_suse()
{
    local rpm_arch="$1"
    local arch_full_path="$2"
    local all_archs_dir=${arch_full_path%/*/*}

    local filename=${arch_full_path##*/}
    local arch_filename=${filename%.${rpm_arch}.rpm}
    local version=${arch_filename#kernel-*-devel-}
    local return_status=0
    local noarch_full_path dir

    noarch_full_path=$( find_noarch_file_suse "$all_archs_dir" \
			 "kernel-devel-${version}" )
    shift 2

    "$@" "$arch_full_path" "$noarch_full_path" \
	 $(maybe_add_deps_rpms_suse "$arch_full_path")
}

read0_walk_arch_files_suse()
{
    local rpm_arch="$1"
    local return_status=0
    local arch_file rpm_arch

    shift

    while read -r -d $'\0' arch_file ; do
	if ! walk_arch_file_suse "$rpm_arch" "$arch_file" "$@" ; then
	    return_status=$?
	fi
    done
    return $return_status
}


walk_mirror_suse()
{
    local mirror_tree="$1"
    local kernel_regexp rpm_arch

    shift

    if [[ ".$arch" = ".amd64" ]] ; then
	rpm_arch=x86_64
    else
	rpm_arch="$arch"
    fi

    kernel_regexp=".*/kernel-.*-devel-${above_3_9_regexp}[0-9.]*-[0-9.]*\.${rpm_arch}\.rpm"

   find "$mirror_tree" -regextype egrep -regex "$kernel_regexp" -type f \
	 -print0 |
	read0_walk_arch_files_suse "$rpm_arch" "$@"
}
