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
    local src dst
    which cscope 2>/dev/null 1>&2 || echo "[WARN] Pls install cscope!" && return
    [ $# -ne 2 ] && echo "[WARN] usage: gen_cs src dst" && return
    src=$1 && dst=$2

	find $src -type f \
		-name "*.h" -o -name "*.c" \
		-o -name "*.cc" -o -name "*.cpp" \
		-o -name "*.java" \
		-o -name "*.m" -o -name "*.mm" > cscope.files
	cscope -bkq -i cscope.files 2>/dev/null

	cs_files="cscope.files cscope.in.out cscope.out cscope.po.out "
	for csf in $cs_files; do
		[ -f $csf ] && mv $csf $dst
	done
}

# for tags and cppcomplete
function gen_ct
{
    local src dst
    which ctags 2>/dev/null 1>&2 || echo "[WARN] Pls install ctags!" && return
    [ $# -ne 2 ] && echo "[WARN] usage: gen_ct src dst" && return
    src=$1 && dst=$2

	ct_opt="-R --c++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java"
	(cd -P $dst 2>/dev/null && ctags $ct_opt $src 2>/dev/null;)

	ct_opt="-R --C++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java -n"
	(cd -P $dst 2>/dev/null && ctags $ct_opt -f cppcomplete.tags $src;)
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
