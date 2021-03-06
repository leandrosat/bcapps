# this shell file runs on bcpc (under cygwin) and creates a file dump
# (plus other things) with a backup, so is never out of date while
# running the dump (pretty much what bc-weekly-backup.pl was doing,
# but now local); this is a cygwin sh file, not a bat file, despite
# the extension, MUST be invoked as "sh $0"
/usr/bin/date > /cygdrive/c/bcpc-files.txt.new
/usr/bin/find / -ls >> /cygdrive/c/bcpc-files.txt.new
/usr/bin/date >> /cygdrive/c/bcpc-files.txt.new
echo EOF >> /cygdrive/c/bcpc-files.txt.new
mv /cygdrive/c/bcpc-files.txt.bz2 /cygdrive/c/bcpc-files.txt.old.bz2
mv /cygdrive/c/bcpc-files.txt.new /cygdrive/c/bcpc-files.txt
perl -nle 's%^.*?\/%/%; print $_' /cygdrive/c/bcpc-files.txt | rev | sort > /cygdrive/c/bcpc-files-rev.txt
bzip2 -f -v /cygdrive/c/bcpc-files.txt
