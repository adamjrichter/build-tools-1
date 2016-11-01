#
# This file is intended to be sourced from a shell script.

url_to_dir()
{
    local url="$1"
    local prefix="${url%%://*}"
    local suffix="${url#*://}"
    echo "$prefix/$suffix"
}

echo_word_per_line() {
    local word
    for word in "$@" ; do
	echo "$word"
    done
}

newlines_around_angle_brackets() {
    sed 's/</\'$'\n''</g;s/>/>\'$'\n''/g;'
}

# I think there is a perl program named extract-urls that will do this better.
extract_subdirs() {
    newlines_around_angle_brackets |
	egrep '^<a href="' |
	sed 's/^[^"]*"//;s/"[^"]*$//'
}

subdirs_to_urls() {
    local top_url="$1"
    local subdir

    while read subdir ; do
        echo "$top_url/$subdir"
    done
}
