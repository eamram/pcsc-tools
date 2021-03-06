#/bin/sh -e

# create a new directory named after the current directory name
# the directory name should be in the form foo-bar.x.y.z
# the use of "_" is not recommanded since it is a problem for Debian

dir=$(basename $(pwd))

echo -e "Using $dir as directory name\n"

rv=$(echo $dir | sed -e 's/.*-[0-9]\.[0-9]\+\.[0-9]\+/ok/')
if [ $rv != "ok" ]
then
	echo "ERROR: The directory name should be in the form foo-bar-x.y.z"
	exit
fi

if [ -e $dir ]
then
	echo -e "ERROR: $dir already exists\nremove it and restart"
	exit
fi

# clean
echo -n "cleaning..."
make clean &> /dev/null
echo "done"

# generate Changelog
echo -n "generating Changelog..."
make Changelog &> /dev/null
echo "done"

present_files=$(tempfile)
manifest_files=$(tempfile)
diff_result=$(tempfile)

# find files present
# remove ^debian and ^create_distrib.sh
find -type f | grep -v .git | cut -c 3- | grep -v ^create_distrib.sh | grep -v sync.sh | grep -v sort_smartcard_list.py | sort > $present_files
cat MANIFEST | sort > $manifest_files

# diff the two lists
diff $present_files $manifest_files | grep '<' | cut -c 2- > $diff_result

if [ -s $diff_result ]
then
	echo -e "WARGING! some files will not be included in the archive.\nAdd them in MANIFEST"
	cat $diff_result
	echo
fi

# remove temporary files
rm $present_files $manifest_files $diff_result

# create the temporary directory
mkdir $dir

for i in $(cat MANIFEST)
do
	if [ $(echo $i | grep /) ]
	then
		idir=$dir/${i%/*}
		if [ ! -d $idir ]
		then
			echo "mkdir $idir"
			mkdir $idir
		fi
	fi
	echo "cp $i $dir/$i"
	cp -a $i $dir/$i
done

tar czvf ../$dir.tar.gz $dir
rm -r $dir

