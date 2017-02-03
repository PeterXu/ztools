The Bash Extend
===============

Automatic scripts for bash, e.g. vim, java, ant/mvn, jump/marks, android sdk/ndk, and etc.


Install
-------

In any directory, run the following commands:

```
$> git clone https://github.com/peterxu/ztools.git

$> cd ztools
$> sh zero_setting.sh         # show help
$> sh zero_setting.sh set     # config bash
$> sh zero_setting.sh clean   # clean bash
```

Usage
-----

### 0). Prepare

For Mac OSX, please install `homebrew`,

For Linux(Ubuntu/Debian/Centos), please install `apt/yum/...`,

The help document: `$> Help`


### 1). `mark` for bash

You can mark one dir and then jump to this dir from any directory.

The usage, e.g.

```
$> Help mark   # show document for mark

$> cd /path/to/dir
$> mark        # mark this dir </path/to/dir>
$> cd          # goto <~/>
$> jump        # back to </path/to/dir>
$> marks       # show all marks
```

`$> jump` is equal to `$> cd`,   
`$> jump .` goto the root direcotry of `mark`,   
`$> jump ..` is equal to `$> cd ..`,  
`$> jump ...` goto the root directory of project `ztools`.

### 2). `srcin` for vim (c/c++)

Install dependencies: `$> brew|apt|yum install ctags cscope`

The usage, e.g.

```
$> Help srcin              # show document for srcin

$> srcin c_cpp_source_dir  # generate ctags/cscope files recursively
$> srcin clean             # clean ctags/cscope files
```

### 3). `ycm` for vim (c/c++)

The config for ycm,

```
$> Help ycm              # show document for ycm

$> ycm-config vundle     # get project vundle
$> ycm-config ycm        # get project YouCompleteMe
$> ycm-config clang      # build with clang

$> ycm-config install    # install local config
$> ycm-config clean      # clean local config
```

The usage, e.g.

```
$> cd /path/to/dir
$> ycm-here c99|cpp      # generate c99/cpp tags
$> ycm-here clean        # clean c99/cpp tags
```

### 4) `printx`: echo colorful text for bash

The document for printx,

```
$> Help printx
usage: 
  printx [@opt] string
      options:
          backgound
          black|red[r]|green[g]|yellow[y]|blue[b]|purple[p]|cyan[c]|white
          bold|bright|uscore|blink|invert
```

The usage, e.g.

```
$> printx "font is normal\n"
$> printx @cyan "font is cyan\n"
$> printx @cyan @bold "font is cyan and bold\n"
$> printx @background @cyan "backgroud is cyan and font unchanged\n"
$> printx @background @cyan @bold "backgroud is cyan and font is bold\n"
```

### 5) hash `map` for bash

The document for map,

```
$> Help map
usage:
       mapset vname key value
       mapget vname key
       mapdel vname key
       mapkey vname
       mapunkey vname
```

The usage, e.g: 

```
$> mapset school student_num 500
$> mapset school teacher_num 50
$> mapget school student_num
500
$> mapget school teacher_num
50
$> mapkey school
student_num teacher_num
```

### 6) string `regex` for bash

The document for regex,

```
$> Help regex
...
```
