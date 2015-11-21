#!/usr/bin/env bash

prefix=/var/lib/glusterfs

rootfs="$prefix/rootfs"
mkdir -p $rootfs/{sbin,lib/systemd/system,etc/init.d}
pydir=$(python -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())')
mkdir -p $rootfs/$pydir

opts="--prefix=$prefix"
opts="$opts --with-pythondir=$rootfs/$pydir"
opts="$opts --with-mountutildir=$rootfs/sbin"
opts="$opts --with-systemddir=$rootfs/lib/systemd/system"
opts="$opts --with-initdir=$rootfs/etc/init.d"
./configure $opts


#
# For configure.ac
#+AC_ARG_WITH(pythondir,
#+            [  --with-pythondir=DIR python lib files in DIR @<:@auto@:>@],
#+            [pythondir=$withval],
#+            [pythondir='auto'])
#+AC_SUBST(pythondir)
#-   BUILD_PYTHON_SITE_PACKAGES=`$PYTHON -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())'`
#+   if test "x$pythondir" = "xauto"; then
#+      BUILD_PYTHON_SITE_PACKAGES=`$PYTHON -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib())'`
#+   else
#+      BUILD_PYTHON_SITE_PACKAGES=$pythondir
#+   fi

