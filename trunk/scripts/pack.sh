#!/bin/sh
# 
# This script creates an EZPDO distribution package
# 
# @author Oak Nauhygon <ezpdo4php@gmail.com>
# @version $Revision: 943 $ $Date: 2006-05-12 15:29:02 -0400 (Fri, 12 May 2006) $
# @package ezpdo
# @subpackage script

# timestamp
timestamp=`date +%Y-%m-%d`; 

# this script
script=$0;

# release directory
rel_dir=$1;

# the source root directory
src_dir='';

# the tmp directory
tmp_dir='';

# the nightly lnk
nightly_lnk='ezpdo.latest';

# function: cd to EZPDO root 
# assumption: this script is in root/scripts. up one level is root.
pk_get_src_dir() {
    
    local last_dir;
    
    last_dir=`pwd`;
    cd "`dirname $script`/..";
    src_dir=`pwd`;
    cd $last_dir;
    return 0;
}

# function: make tmp directory
pk_make_tmp_dir() {
    
    local last_dir;
    
    # tmp directory for packaging 
    tmp_dir="/tmp/ezpdo.$timestamp";
    
    # create tmp dir if not existing
    if [ ! -e $tmp_dir ]; then
	mkdir $tmp_dir;
    fi
    
    # cd to tmp dir and remove everything under
    last_dir=`pwd`;
    cd $tmp_dir;
    \rm -rf *;
    cd $last_dir;
    
    return 0;
}

# function: cp all to a tmp directory
pk_copy_to_tmp() {
    
    # check if source root is set
    if [ -z $src_dir]; then
	pk_get_src_dir;
    fi
    
    # check if tmp dir is setup
    if [ -z $tmp_dir]; then
	pk_make_tmp_dir;
    fi
    
    # copy everything from ezpdo root dir
    cp -r $src_dir/* $tmp_dir;    
    
    return 0;
}

# function: recursively cleanup dir (remove CVS, test results)
# @param dir to be cleaned up
pk_clean_up_dir() {
    
    # check if path is specified
    path="$1";
    if [ -z "$path" ]; then
	# if not work on the current dir
	path='.';
    fi
    
    # cd to path
    cd $path;

    # rm .svn
    if [ -d ".svn" ]; then
        \rm -rf .svn
    fi

    # rm CVS
    if [ -d "CVS" ]; then
        \rm -rf CVS
    fi

    # rm XML
    if [ -d "XML" ]; then
        \rm -rf CVS
    fi

    # rm compiled
    if [ -d "compiled" ]; then
        \rm -rf compiled/*
    fi

    # rm output
    if [ -d "output" ]; then
        \rm -rf output/*
    fi

    # rm pack.sh
    if [ -f "pack.sh" ]; then
        \rm -f pack.sh
    fi

    # recursion
    for i in *; do
	if [ -d "$i" ]; then
	    pk_clean_up_dir $i;
	fi
    done
    
    # done with this dir
    cd ..;
    
    return 0;
}

# function: cleanup derived (testing/example output) files
pk_do_packaging() {
    
    local last_dir;
    
    # check if tmp dir is setup
    if [ -z $tmp_dir]; then
	pk_copy_to_tmp;
    fi
    
    # remember the last dir
    last_dir=`pwd`;
    
    # go to the tmp dir
    pk_clean_up_dir $tmp_dir;
    
    # tar and zip the tmp dir
    cd $tmp_dir/..;
    tmp_base=`basename $tmp_dir`;
    
    tar cfz $rel_dir/$tmp_base.tar.gz $tmp_base/*;
    echo "tarball $tmp_base.tar.gz released in $rel_dir";
    
    zip -r -q $rel_dir/$tmp_base.zip $tmp_base/*;
    echo "zipball $tmp_base.zip released in $rel_dir";
    
    # setup nightly link (only if release dir is given)
    if [ "$rel_dir" != '.' ]; then
	
	# unlink nightly link (.tar.gz)
	if [ -e $rel_dir/$nightly_lnk.tar.gz ]; then
	    unlink $rel_dir/$nightly_lnk.tar.gz;
	fi
	# relink nightly (.tar.gz)
	ln -s $rel_dir/$tmp_base.tar.gz $rel_dir/$nightly_lnk.tar.gz;
	
	# unlink nightly link (.zip)
	if [ -e $rel_dir/$nightly_lnk.zip ]; then
	    unlink $rel_dir/$nightly_lnk.zip;
	fi
	# relink nightly (.tar.gz)
	ln -s $rel_dir/$tmp_base.zip $rel_dir/$nightly_lnk.zip;
	
    fi
    
    # go back to the last dir
    cd $last_dir;
    
    return 0;
}

# check if user type --help or -help
if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "Usage: ${0##*/} [<release_dir>]";
    exit 1;
fi

# check if release dir specified is valid
if [ -z $rel_dir ]; then
    rel_dir='.';
else
    
    # check if dir exists
    if [ ! -e $rel_dir ]; then
	echo "release_dir ($rel_dir) dose not exist";
	exit -1;
    fi
    
    # check if dir writable
    if [ ! -w $rel_dir ]; then
	echo "release_dir ($rel_dir) is not writable. change permission.";
	exit -2;
    fi
    
    # get absolute path for rel dir
    last_dir=`pwd`;
    cd $rel_dir;
    rel_dir=`pwd`;
    cd $last_dir;

fi

# do packaging now
pk_do_packaging;

exit 0;
