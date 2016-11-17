#!/bin/bash
# ^^^^^^^^^ bash because this script uses an associative array..

cd /home/ftp/build-results/pxfuse/by-date/latest || exit $?

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

EOF
}

output_html_tailer() {
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


mkdir -p test_report
rm -f test_report/test_report.txt

output_html_header "Portworx kernel testing report" \
    > test_report/test_report.html

for dir in */ ; do
    if [[ "$dir" = "test_report/" ]] ; then
        continue
    fi

    distribution=${dir%/}
    out_dir="test_report/$distribution"
    mkdir -p "$out_dir"

    success_count=$(find "$distribution" -name exit_code -print0 | xargs --null --no-run-if-empty -- egrep -l '^0 ' | wc -l)
    fail_count=$(find "$distribution" -name exit_code -print0 | xargs --null --no-run-if-empty -- egrep -L '^0 ' | wc -l)

    find "$distribution" -name exit_code | sort --unique |
        while read filename ; do
            read exit_code rest < "$filename"

            if [ ".$exit_code" = ".0" ] ; then
                out_file="${out_dir}/successes.html"
            else
                out_file="${out_dir}/failures.html"
            fi
            link="../../${filename%/exit_code}"
	    output_html_link_and_note_paragraph "$link" "$rest" >> "$out_file"
        done
    echo "${distribution}: $success_count pass, $fail_count fail." >> test_report/test_report.txt

    echo "
<P>
<A href=\"../${distribution}\"> ${distribution}:</A>
<A href=\"${distribution}/successes.html\"> $success_count pass</A>,
<A href=\"${distribution}/failures.html\"> $fail_count fail</A>.
</P>
" >> test_report/test_report.html

done

cat >> test_report/test_report.html <<EOF
</body>
</html>
EOF
