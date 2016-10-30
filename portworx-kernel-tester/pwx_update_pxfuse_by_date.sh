#!/bin/sh

datedir=/home/ftp/build-results/pxfuse.by-date
rm -rf "$datedir"
mkdir -p "$datedir"
cd "$datedir" || exit $?

for dir in ../pxfuse-*/ ; do
    dir_no_slash=${dir%/}
    prefix=$( (TZ='' stat --format=%y "$dir_no_slash") | sed 's/ +0000$//;s/ /_/g' )
    suffix=${dir_no_slash#../}
    ln -s "$dir" "${prefix}-${suffix}"
done
