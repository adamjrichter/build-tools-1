#!/bin/sh

datedir=/home/ftp/build-results/pxfuse/by-date
rm -rf "$datedir"
mkdir -p "$datedir"
cd "$datedir" || exit $?

for dir in ../by-checksum/*/ ; do
    dir_no_slash=${dir%/}

    prefix=$( (TZ='' stat --format=%y "$dir_no_slash") |
	      sed 's/ +0000$//;s/ /_/g' )

    suffix=${dir_no_slash#../by-checksum/}
    ln -s "$dir_no_slash" "${prefix}-${suffix}"
done

latest=$(ls -1dtr ../by-checksum/*/ | tail -1)
rm -f latest
ln -s "${latest%/}" latest
