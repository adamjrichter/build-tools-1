#
# This file is intended to be sourced from a shell script.
#
# This file contains common declarations used by mirror-kernels.*.sh.

# Used for selecting kernels version 3.10 or later:
above_3_9_regexp='(3\.[1-9][0-9]|[4-9]|[1-9][0-9])'

bash_stack_trace()
{
    # bash_stack_trace uses the bash-specific "caller" command.
    local depth line func file
    depth=0
    while true ; do
	set -- $(caller $depth)
	if [ $# = 0 ] ; then
	    break
	fi
	line="$1"
	func="$2"
	file="$3"
	echo "${file}:${line} ${func}"
	depth=$((depth + 1))
    done
}

save_error()
{
    local saved_code=$?

    if [ $saved_code != 0 ] ; then

	error_code=$saved_code

	echo "pwx-mirror-util.sh save_error: error in shell script detected.  Trace: " >&2
	bash_stack_trace >&2
	echo "" >&2
    fi
}

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
