#!/bin/bash

set_ios ()
{
    [ "$ARCH" = "" ] && ARCH=armv7

    CC=clang
    CXX=clang++
    if [[ "$ARCH" =~ "86" ]]; then
        SDKTYPE=iPhoneSimulator
    else
        SDKTYPE=iPhoneOS
    fi
    SDKTYPE_=`echo $SDKTYPE | tr A-Z a-z`
    SDK=`xcrun --sdk $SDKTYPE_ --show-sdk-version`

    SDK_MIN=5.1
    XCODE=`xcode-select -p`
    SDKROOT=$XCODE/Platforms/$SDKTYPE.platform/Developer/SDKs/"$SDKTYPE""$SDK".sdk
    CFLAGS="-arch $ARCH -isysroot $SDKROOT -miphoneos-version-min=$SDK_MIN -DAPPLE_IOS"
    LDFLAGS="-arch $ARCH -isysroot $SDKROOT -miphoneos-version-min=$SDK_MIN"
    return 0
}


make_ios ()
{
    export CC="$CC"
    export OSIP_CFLAGS="-I`pwd`/../libosip2-4.1.0/include"
    export CFLAGS="$CFLAGS $OSIP_CFLAGS"
    export LDFLAGS="$LDFLAGS"

    ./configure --host=arm --disable-shared --disable-tools || exit 1
    make clean && make || exit 1
}


arch_list="armv7 i386"
mod_list="eXosip2"
tmpdir="./tmplibs" && mkdir -p $tmpdir

for arch in $arch_list; do
    ARCH=$arch && set_ios
    make_ios 
    for mod in $mod_list; do
        find src -name lib$mod.a -exec cp -f {} $tmpdir/lib${mod}_${arch}.a \;
    done
done

for mod in $mod_list; do
    lib_list="" 
    for arch in $arch_list; do
        lib_list="$lib_list -arch $arch $tmpdir/lib${mod}_${arch}.a"
    done
    lipo $lib_list -output lib$mod.a -create
done
#rm -rf $tmpdir

exit 0
