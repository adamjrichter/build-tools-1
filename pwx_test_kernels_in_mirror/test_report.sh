#!/bin/bash
# ^^^^^^^^^ bash because this script uses an associative array..

cd /home/ftp/build-results/pxfuse/by-date/latest || exit $?

prev_test=/home/ftp/build-results/pxfuse/old/test_report

exit_code_files_to_dirs() {
    # Usage: exit_code_files_to_dirs subdir [grep_args...]
    #   Usually grep_args is "-l" or "-L"
    local subdir="$1"
    
    shift
    find "$subdir" -name exit_code -print0 |
	xargs --null --no-run-if-empty -- egrep "$@" '^0 ' |
	sort -u
}

output_html_header() {
    local title="$1"
cat <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>
           $title
        </title>
    </head>
<body>
    <h2>
        $title
    </h2>
EOF
}

output_html_trailer() {
    echo "</body>"
    echo "</html>"
}

output_html_link() {
    local link="$1"
    echo "<A href=\"${link}\">${link}</A>"
}

output_html_link_and_note_paragraph() {
    local link="$1"
    local note="$2"
    echo "<P>"
    output_html_link "$link"
    echo "($note)"
    echo "</P>"
    echo ""
}

files_to_html_link_page()
{
    local title="$1"
    local file exit_code rest

    output_html_header "$title"
    while read file ; do
	read exit_code rest < "$file"
	output_html_link_and_note_paragraph "../../${file%/exit_code}" "$rest"
    done
    output_html_trailer
}

regression_detected()
{
    echo ""
    echo "$0:"
    echo "\"regression_detected $*\" called."
    echo "This is a stub function that could perhaps be used to notify staff"
    echo "when a regression has beendetected by, sending e-mail, text"
    echo "message, etc."
    echo ""
}

if [[ -e test_report ]] ; then
    mkdir -p "$prev_test"
    rm -rf test_report/old
    mv "$prev_test" test_report/old
    mv test_report "$prev_test"

    # Trim logs at some point:
    rm -rf "$prev_test/old/old/old"

    # The .html files will not have valid links once the files have been
    # moved, so just remove those files, to avoid confusion.
    find "$prev_test" -name '*.html' -type f -print0 | xargs --null rm -f
fi

mkdir -p test_report
rm -f test_report/test_report.txt

what_we_are_doing="building Portworx px.ko kernel module"

output_html_header "Test report for $what_we_are_doing" \
		   > test_report/test_report.html

regression_distros=""
for dir in */ ; do

    case "$dir" in
	test_report*/ | old/ ) continue ;;
    esac

    distribution=${dir%/}
    out_dir="test_report/$distribution"
    mkdir -p "$out_dir"

    exit_code_files_to_dirs "$distribution" "-l" > "$out_dir/successes.txt"
    exit_code_files_to_dirs "$distribution" "-L" > "$out_dir/fails.txt"

    cat "$prev_test/$distribution/successes.txt" "$out_dir/fails.txt" |
	sort | uniq --repeated > "$out_dir/regressions.txt"

    cat "$prev_test/$distribution/fails.txt" "$out_dir/successes.txt" |
	sort | uniq --repeated > "$out_dir/fixed.txt"

    regression_count=$(wc -l < "$out_dir/regressions.txt")
    if [[ $regression_count -gt 0 ]] ; then
	regression_distros="$regression_distros $distribution"
    fi

    echo -n "${distribution}: " >> test_report/test_report.txt
    echo "<P>
          <A href=\"../${distribution}\"> ${distribution}:</A>" \
	 >> test_report/test_report.html

    maybe_comma=""
    for word in successes fails regressions fixed ; do
	files_to_html_link_page \
	    "$word for $what_we_are_doing on $distribution" \
	    < $out_dir/$word.txt > "${out_dir}/${word}.html"

	count=$(wc -l < "${out_dir}/${word}.txt")
	echo -n "$maybe_comma $count $word" >> test_report/test_report.txt
	maybe_comma=","
	echo "<A href=\"${distribution}/${word}.html\"> $count ${word}</A>," \
	     >> test_report/test_report.html
    done # for word in ...
    ( echo "" ; echo "</P>" ) >> test_report/test_report.html
done # for dir (distribution) in...

output_html_trailer >> test_report/test_report.html

if [[ -n "$regression_distros" ]] ; then
    regression_detected $regression_distros
fi
