#!/bin/sh

cd /home/ftp/build-results/pxfuse/by-date/latest || exit $?
for distribution in */ ; do
    pass=$( find "$distribution" -name exit_code | xargs egrep -l '^0 ' | wc -l)
    fail=$( find "$distribution" -name exit_code | xargs egrep -L '^0 ' | wc -l)
    echo "${distribution%/}: $pass pass, $fail fail."
done > test-report.txt

