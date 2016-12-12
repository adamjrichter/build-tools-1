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

#arch=i386
arch=amd64

TIMESTAMPING=--timestamping
#TIMESTAMPING=--no-clobber

error_code=0
debug_binary_search=false

urls_string=""	# Global variable for caching list of URL's.
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

# Return true if the file needs to be retrieved (that is, the file
# is absent), but, before testing, remove the file if it is empty.
remove_if_empty_check_if_absent()
{
    local file="$1"
    if [[ -s "$file" ]] ; then
	return 1
    fi
    if [[ -e "$file" ]] ; then
	rm -f "$file"
    fi
    return 0
}

list_kernel_dir_urls() {
    local top_url="$1"
    local top_dir="$2"

    cat "${top_dir}"/index.html\?year=* |
        extract_subdirs |
        egrep '^20[0-9]+(T[0-9]+)?+Z/$' |
        on_or_after_linux_3_10_release_date |
	sed "s|^|${top_url}/|"
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
    if remove_if_empty_check_if_absent "$file" ; then
        # echo wget $TIMESTAMPING --protocol-directories --force-directories \
        #      --quiet "$url" >&2
        if wget $TIMESTAMPING --protocol-directories --force-directories \
		--quiet "$url" ; then
	    # The "if <condition> ; then ... true ; else ... ; fi" structure
	    # preserves the wget exit code for save_error while still
	    # testing it.
	    true
	else
	    save_error
	    rm "$file"
	    return 1
	fi
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
	if remove_if_empty_check_if_absent "$filename" ; then
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
    local result
    [[ ".${start_names}" != ".${end_names}" ]]
    result=$?
    if [[ $result != 0 ]] && $debug_binary_search ; then
	echo "kernel_header_packages_different: same start=$start end=$end" >&2
	echo "    url_array[start]=${url_array[$start]}." >&2
	echo "    url_array[end]=${url_array[$end]}." >&2
	echo "    start_names=$start_names." >&2
	echo "    end_names=$end_names." >&2
    fi
    return $result
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
		if [[ -s "$filename" ]] ; then
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
        # echo "binary_search $* ended due to lack of middle index."
        true
    fi
}

mirror_kernel_dir_index_files_binary_search() {
    local top_url="$1"
    local top_dir="$2"
    local subdir="$3"
    local url_count

    url_count=0
    for url in $urls_string ; do
        url_count=$((url_count + 1))
	# ^^^ url_array is indexed starting at 1.
        url_array[$url_count]="$url$subdir"
	if $debug_binary_search ; then
	    echo "mirror_kernel_dir_index_files_binary_search: url_array[$url_count]=$url." >&2
	fi
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
    local top_url="$1"
    wget $TIMESTAMPING --protocol-directories --mirror --quiet --level=1 \
         --accept='index.html*' "$top_url/"
    save_error
}

list_kernel_filenames_plus_directories() {
    local top_dir="$1"
    local subdir="$2"	# For example "/pool/main/l/linux-tools/"
    local index_filename pkg_filename dir 
    for index_filename in \
	"${top_dir}"/*/"${subdir}/index.html" \
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
    local top_dir="$1"
    local subdir="$2"
    list_kernel_filenames_plus_directories "$top_dir" "$subdir" |
	first_unique_filenames
}

skip_existing_filenames() {
    local filename
    while read filename ; do
	if remove_if_empty_check_if_absent "$filename" ; then
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
    local top_dir="$1"
    local subdir="$2"
    list_first_relative_paths "$top_dir" "$subdir" |
	sort -u |
        skip_existing_filenames |
        filenames_to_urls
}

mirror_pkg_files() {
    local top_dir="$1"
    local subdir="$2"
    # list_pkg_urls_to_download: 1,344,589, takes 7min:14sec to
    # compute on mirrros.portworx.com.
    list_pkg_urls_to_download "$top_dir" "$subdir" |
	egrep "_(${arch}|all)\.deb\$" |
        xargs --no-run-if-empty -- \
	    wget $TIMESTAMPING --protocol-directories --force-directories \
	        --quiet
    save_error
}

mirror_debian()
{
    local top_url="$1"
    local top_dir=$(url_to_dir "$top_url")

    rename_bad_deb_files "$top_dir"
    mirror_top_level_directories "$top_url"
    save_error

    urls_string=$(list_kernel_dir_urls "$top_url" "$top_dir" | sort -u)
    # ^^^^ This takes a lot of exec'ing to compute, so save it as a global
    # variable so it does not have to be recomputed in each iteration of
    # the following loop.

    for subdir in "/pool/main/l/linux/" "/pool/main/l/linux-tools/" ; do
	# Do one of the following two:
	mirror_kernel_dir_index_files_binary_search \
	    "$top_url" "$top_dir" "$subdir"
	# mirror_kernel_dir_index_files_all
	save_error

	# If we don't want to do the whole binary search song and dance,
	# this should download all files.
	mirror_pkg_files "$top_dir" "$subdir"
	save_error
    done
}

mirror_debian "http://snapshot.debian.org/archive/debian"
mirror_debian "http://security.debian.org/debian-security"

exit $error_code
