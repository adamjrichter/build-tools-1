#!/bin/bash
# ^^^^^^^^^ This is a bash script because it uses array subscripts,
# $'\n' for the newline character, and save_error() which calls
# bash_stack_trace(), which uses the bash-specific "caller" command.

scriptsdir=$PWD
. ${scriptsdir}/pwx-mirror-config.sh
. ${scriptsdir}/pwx-mirror-util.sh
mkdir -p ${mirrordir}
cd ${mirrordir} || exit $?

mirrordir=/home/ftp/mirrors


url_dir=snapshot.debian.org/archive/debian
top_url=http://$url_dir
top_dir=http/$url_dir

#arch=i386
arch=amd64

TIMESTAMPING=--timestamping
#TIMESTAMPING=--no-clobber

error_code=0

declare -A url_array
declare -A kernel_header_names

on_or_after_linux_3_10_release_date() {
    # Linux 3.10 was released on 2013.06.30, maybe the day before in some time
    # zone)
    # egrep '^(20130629|2013063|20130[7-9]|20131|201[4-9]|2[1-9]|[3-9])'
    #
    # Linux 3.10-rc1 was released on 2013.05.12, so start at 2015.05.11.
    egrep '^(2013051[1-9]|201305[23]|20130[6-9]|20131|201[4-9]|2[1-9]|[3-9])'
}

list_kernel_dir_urls() {
    cat "${top_dir}"/index.html\?year=* |
        extract_subdirs |
        egrep '^20[0-9]+(T[0-9]+)?+Z/$' |
        on_or_after_linux_3_10_release_date |
	sed "s|^\(.*\)\$|\
${top_url}/\1/pool/main/l/linux/\\
${top_url}/\1/pool/main/l/linux-tools/|"
}

directory_url_to_filename() {
    local url="$1"
    echo "$url" | sed 's|^\([a-zA-Z]\+\)://|\1/|;s|$|/index.html|'
}

directory_index_to_filename() {
    local index="$1"
    directory_url_to_filename "${url_array[$index]}"
}

linux_headers_after_3_9() {
    egrep '^linux-(compiler-|kbuild-|headers-(3\.[1-9][0-9]|[4-9]))'
}

remember_kernel_header_names() {
    local index="$1"
    local url=${url_array[$index]}
    local file=$(directory_url_to_filename "$url")
    if [[ ! -e "$file" ]] ; then
        # echo wget $TIMESTAMPING --protocol-directories --force-directories \
        #      --quiet "$url" >&2
        wget $TIMESTAMPING --protocol-directories --force-directories \
	     --quiet "$url"
	save_error
    fi
    kernel_header_names[$index]=$( extract_subdirs < "$file" |
				   linux_headers_after_3_9 )
}

extract_kernel_header_names() {
    local index="$1"
    if [[ -z "${kernel_header_names[$index]}" ]] ; then
        remember_kernel_header_names "$@"
    fi
    echo "${kernel_header_names[$index]}"
}

skip_directory_urls_already_mirrored() {
    local url url_type url_rest filename
    while read url ; do
        filename=$(directory_url_to_filename "$url")
        if [[ ! -e "$filename" ]] ; then
            echo "$url"
        fi
    done
}


# Mirror all index.html files in url_array in the inclusive range
# [start,end] that are different.

kernel_header_packages_different() {
    local start=$1
    local end=$2
    local start_names=$(extract_kernel_header_names "$start")
    local end_names=$(extract_kernel_header_names "$end")
    test ".${start_names}" != ".${end_names}"
}

# Pick a midpoint, preferably one for which index.html has already
# been downloaded and which is as close as possible to the average
# of start and end.
pick_a_midpoint() {
    local start="$1"
    local end="$2"
    local mid=$(( ( start + end ) / 2))
    local max_distance=$(( ( end - start ) / 2))
    local guess distance filename

    distance=0
    while [[ $distance -le $max_distance ]] ; do
        for guess in $((mid - distance)) $((mid + distance)) ; do
            if [[ "$guess" -gt "$start" ]] &&
               [[ "$guess" -lt "$end" ]] ; then
	    
		filename=$(directory_index_to_filename $guess)
		if [[ -e "$filename" ]] ; then
                    echo "pick_a_midpoint: cached guess $start < $guess < $end" >&2
                    echo "$guess"
                    return 0
		fi
            fi
        done
        distance=$((distance + 1))
    done
    echo "pick_a_midpoint: no cached midpoint found, returning $start < $mid < $end" >&2
    echo "$mid"
}

# binary_search start end command [args]
#  ... invokes command [args] start end.  If that command returns success
#  and there are integers between start and end, then descend.
binary_search() {
    local start=$1
    local end=$2
    local mid result

    shift 2

    if ! "$@" "$start" "$end" ; then
        result=$?
        # echo "binary_search $* ended by subcommand returning $result,"
        # echo "   meaning that the versions have the same contents or"
        # echo "   an error occurred."
        return $result
    fi

    if [[ $((start + 1)) -lt "$end" ]] ; then
        mid=$(pick_a_midpoint "$start" "$end")

        binary_search "$start" "$mid" "$@" &&
        binary_search "$mid" "$end" "$@"
    else
        # echo "binary_search $* ended by due to lack of middle index."
        true
    fi
}

mirror_kernel_dir_index_files_binary_search() {
    local urls_string=$(list_kernel_dir_urls | sort -u)
    local url_count

    # ^^^ url_array is indexed starting at 1.

    url_count=0
    for url in $urls_string ; do
        url_count=$((url_count + 1))
        url_array[$url_count]="$url"
    done
    
    binary_search 1 $url_count kernel_header_packages_different
}

mirror_kernel_dir_index_files_all() {
    list_kernel_dir_urls |
        skip_directory_urls_already_mirrored |
        xargs --no-run-if-empty -- \
            wget $TIMESTAMPING --protocol-directories --force-directories \
	        --quiet --accept='index.html*'
    save_error
}

mirror_top_level_directories() {
    wget $TIMESTAMPING --protocol-directories --mirror --quiet --level=1 \
         --accept='index.html*' "$top_url/"
    save_error
}

list_kernel_filenames_plus_directories() {
    local index_filename pkg_filename dir 
    for index_filename in \
	"${top_dir}"/*/pool/main/l/linux/index.html \
	"${top_dir}"/*/pool/main/l/linux-tools/index.html
    do
	dir=${index_filename%/index.html}
	extract_subdirs < "$index_filename" |
	    linux_headers_after_3_9 |
	    while read pkg_filename ; do
		case "$pkg_filename" in
		    linux-headers-*  ) echo "$pkg_filename" "$dir" ;;
		    linux-compiler-* ) echo "$pkg_filename" "$dir" ;;
		    linux-kbuild-* ) echo "$pkg_filename" "$dir" ;;
		esac
	    done
    done
}

first_unique_filenames() {
    sort | (
	old_filename=""
	while read filename dir ; do
	    if [[ ".$filename" != ".$old_filename" ]] ; then
		old_filename="$filename"
		echo "$dir/$filename"
	    fi
	done
    )
}

list_first_relative_paths() {
    list_kernel_filenames_plus_directories | first_unique_filenames
}

skip_existing_filenames() {
    local filename
    while read filename ; do
	if [[ ! -e "$filename" ]] ; then
	    echo "$filename"
	fi
    done
}

filenames_to_urls() {
    local url protocol rest
    while read url ; do
	protocol=${url%%/*}
	rest=${url#*/}
	echo "${protocol}://${rest}"
    done
}

list_pkg_urls_to_download() {
    list_first_relative_paths |
	sort -u |
        skip_existing_filenames |
        filenames_to_urls
}

mirror_pkg_files() {
    # list_pkg_urls_to_download: 1,344,589, takes 7min:14sec to
    # compute on mirrros.portworx.com.
    list_pkg_urls_to_download |
	egrep "_(${arch}|all)\.deb\$" |
        xargs --no-run-if-empty -- \
	    wget $TIMESTAMPING --protocol-directories --force-directories \
	        --quiet
    save_error
}

rename_bad_deb_files "$top_dir"
mirror_top_level_directories
save_error

# Do one of the following two:
mirror_kernel_dir_index_files_binary_search
save_error
# mirror_kernel_dir_index_files_all

# If we don't want to do the whole binary search song and dance, this
# should download all files.
mirror_pkg_files
save_error

exit $error_code
