# This is not a standalone program.  It is a library to be sourced by a shell
# script.

# For now, just default everything to the common Debian drivers.

debian_tmpdir=/tmp/pwx-kernel-tester.distro-driver.debian.$$
debian_find_txt="${debian_tmpdir}/find.sorted.txt"

get_default_mirror_dirs_debian()
{
    echo /home/ftp/mirrors/http/snapshot.debian.org/archive/debian
    echo /home/ftp/mirrors/http/security.debian.org/debian-security
}

pkg_files_to_names_debian()       { pkg_files_to_names_deb        "$@" ; }

debian_pkgs_to_dependencies() {
    local pkgfile
    for pkgfile in "$@" ; do
	dpkg --info "$pkgfile"
    done |
	egrep '^ Depends: ' |
	sed 's/(.*)/ /g;s/,/ /g;s/^ Depends: //;s/ /\n/g' |
	sort -u
}

echo_word_per_line() {
    local word
    for word in "$@" ; do
	echo "$word"
    done
}

debian_find_pkgs_in_mirror() {
    local mirror_tree="$1"
    local pkgname

    shift 1
    for pkgname in "$@" ; do
	fgrep "/${pkgname}_" < "$debian_find_txt" |
	    egrep "_${arch}.deb\$" |
	    tail -1
    done |
	sort -u
}

debian_process_common_deb_file()
{
        local mirror_tree="$1"
        local file="$2"
        local pkg_name dir
	local prefix suffix middle possible_file header_files files
	local deps depfiles

	shift 2

	prefix="${file%-common_*}"
	suffix="${file#*-common_}"

        pkg_name=$(pkg_files_to_names_deb "${mirror_tree}/${file}")
        dir=${file%/*}

	header_files=""
	for middle in common all all-${arch} ${arch} ; do
	    possible_file="${mirror_tree}/${prefix}-${middle}_${suffix}"
	    if [[ -e "$possible_file" ]] ; then
		header_files="$header_files $possible_file"
	    fi
	done

	deps=$(debian_pkgs_to_dependencies $header_files |
		      egrep -v '^linux-headers-' )

	depfiles=$(debian_find_pkgs_in_mirror "$mirror_tree" $deps)

	"$@" $header_files $depfiles
}

walk_mirror_debian() {
    local mirror_tree="$1"
    local file return_status

    shift 1
    return_status=0
    mkdir -p "$debian_tmpdir"
    # ( cd "$mirror_tree" && find . -name '*.deb' -type f | sort -u ) \
    #	> "$debian_find_txt"
    find "$mirror_tree" -name '*.deb' -type f | sort -u > "$debian_find_txt"
    cp "$debian_find_txt" /tmp/ # AJR

    # Only process kernel headers version 3.10 and later:
    ( cd "$mirror_tree" &&
      find . \( -name "linux-headers-3.[1-9][0-9]*-common_*_${arch}.deb" -o \
	        -name "linux-headers-[4-9]*-common_*_${arch}.deb" \) \
	     -type f -print0 ) |
    while read -r -d $'\0' file ; do
        if ! debian_process_common_deb_file "$mirror_tree" "$file" "$@" < /dev/null ; then
	    return_status=$?
	fi
    done
    rm -rf "$debian_tmpdir"
    return $return_status
}
