#!/bin/bash
# author: uskee.org
# date  : 2012/12/03
#
# prerequired tools:
#   (a) ctags for c/cpp
#   (b) cscope for c/cp
#   (c) jtags for java [option]
#


#==============================================
# config for vim
#==============================================

#
# cscope and tags for vim:
function set_cs_tags
{
	vimrc_file=/tmp/tagsforvimrc.cfg
	if [ $# -eq 1 ]; then
		vimrc_file=$1
	fi

	had=""
	label="for src_insight"
	if [ -f $vimrc_file ]; then
		had=`sed -n /"$label"/p $vimrc_file`
	fi

	if test -n "$had"; then
		return
	fi

	# add config
	cat >> $vimrc_file <<EOF

" $label
if has("cscope")
	"set csprg=/usr/bin/cscope
	"set csto=0
	"set cst
	"set nocsverb

	" if cscope.out exists, add any database in current directory
	" else add database pointed to by environment
	if filereadable(".xtags/cscope.out")
		cs add .xtags/cscope.out
	elseif \$CSCOPE_DB != ""
		cs add \$CSCOPE_DB
	endif

	if filereadable(".xtags/tags")
		set tag+=.xtags/tags
	endif

	"set csverb
	"set cscopetag
	"set cscopequickfix=s-,g-,c-,d-,t-,e-,f-,i-
	set nu
endif

" for tab setting
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab " use spaces to expandtab, else <set noexpandtab>

EOF
}


#=========================================
# config for c/c++ files
#=========================================

RM="rm -rf"
XTAGS_ROOT=.xtags/

CS_SRC=.
CT_SRC=..

#
# for cscope 
function gen_cs
{
	if [ ! -e /usr/bin/cscope ]; then
		echo "[WARN] Pls install cscope!"
		return
	fi

	cs_files="cscope.files cscope.in.out cscope.out cscope.po.out "
	find $CS_SRC -type f \
		-name "*.h" -o -name "*.c" \
		-o -name "*.cc" -o -name "*.cpp" \
		-o -name "*.java" \
		-o -name "*.mm" > cscope.files
	cscope -bkq -i cscope.files

	for csf in $cs_files
	do
		if [ -f $csf ]; then
			mv $csf $XTAGS_ROOT
		fi
	done
}

#
# for tags and cppcomplete
function gen_ct
{
	if [ ! -e /usr/bin/ctags ]; then
		echo "[WARN] Pls install ctags!"
		return
	fi

	OPT="-R --c++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java"
	(cd $XTAGS_ROOT; ctags $OPT $CT_SRC)

	OPT="-R --C++-kinds=+p --fields=+iaS --extra=+q --languages=c++,c,java -n"
	(cd $XTAGS_ROOT; ctags $OPT -f cppcomplete.tags $CT_SRC)
}

#
# prepare
mkdir -p $XTAGS_ROOT
if [ ! -d $XTAGS_ROOT ]; then
	echo "failed to create dir: $XTAGS_ROOT"
	exit 1
fi

condition=0
if [ $# -eq 0 ]; then
	condition=1
elif [ $# -eq 1 ]; then
	if [[ $1 == "clean" ]]; then
		$RM $XTAGS_ROOT
		exit 0
	elif [ -d $1 ]; then
		CS_SRC=$1
		CT_SRC=$1
		if [[ ! $1 =~ ^/.* ]]; then
			CT_SRC=../$1
		fi
		condition=1
	fi
fi

if [ $condition -ne 1 ]; then
	echo "usage: $0 [clean|\$dir]"
	exit 1
fi

#
# generate
#gen_vimrc ~/.vimrc
set_cs_tags ~/.vimrc

gen_cs
gen_ct

exit 0
