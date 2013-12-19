#!/bin/bash
# author: uskee.org
# date  : 2012/12/03
#
# prerequired tools:
#   (a) ctags for c/cpp
#   (b) cscope for c/cp
#   (c) jtags for java [option]
#

#=========================================
# config for c/c++ files
#=========================================

RM="rm -rf"
XTAGS_ROOT=.xtags/
XCS_ROOT=.
XCT_ROOT=..

# for cscope 
function gen_cs
{
    testp=`which cscope`
	[ "AAA$testp" = "AAA" ] && echo "[WARN] Pls install cscope!" && return

    [ $# -ne 2 ] && echo "[WARN] gen_cs need two arguments" && return
    src_root=$1
    dst_root=$2

	find $src_root -type f \
		-name "*.h" -o -name "*.c" \
		-o -name "*.cc" -o -name "*.cpp" \
		-o -name "*.java" \
		-o -name "*.m" -o -name "*.mm" > cscope.files
	cscope -bkq -i cscope.files

	cs_files="cscope.files cscope.in.out cscope.out cscope.po.out "
	for csf in $cs_files; do
		[ -f $csf ] && mv $csf $dst_root
	done
}

# for tags and cppcomplete
function gen_ct
{
    testp=`which ctags`
	[ "AAA$testp" = "AAA" ] && echo "[WARN] Pls install ctags!" && return

    [ $# -ne 2 ] && echo "[WARN] gen_ct need two arguments" && return
    src_root=$1
    dst_root=$2

	ct_opt="-R --c++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java"
	(cd $dst_root; ctags $ct_opt $src_root)

	ct_opt="-R --C++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java -n"
	(cd $dst_root; ctags $ct_opt -f cppcomplete.tags $src_root)
}

function gen_clean()
{
    $RM $XTAGS_ROOT
}

function set_root()
{
    [ $# -ne 1 ] && return
	XCS_ROOT=$1
	XCT_ROOT=$1
	[[ ! $1 =~ ^/.* ]] && XCT_ROOT=../$1
}

################################

# check
mkdir -p $XTAGS_ROOT
[ ! -d $XTAGS_ROOT ] && echo "not found: $XTAGS_ROOT" && exit 1

[ $# -gt 1 ] && echo "usage: $0 [clean|\$dir]" && exit 1
[ $# -eq 1 ] && [ "$1" = "clean" ] && gen_clean && exit 0
[ $# -eq 1 ] && [ ! -d "$1" ] && echo "not found: $1" && exit 1
[ $# -eq 1 ] && [ -d "$1" ] && set_root "$1"

# generate
gen_cs "$XCS_ROOT" "$XTAGS_ROOT"
gen_ct "$XCT_ROOT" "$XTAGS_ROOT"

exit 0
