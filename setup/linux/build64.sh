#!/bin/bash

for i in `git tag --list --sort=committerdate`; do BUILDTAG=$i; done

for i in `git rev-parse HEAD`; do BUILDCOMMIT=$i; done
BUILDCOMMIT=${BUILDCOMMIT:0:8}

for i in `git rev-parse --abbrev-ref HEAD`; do BUILDBRANCH=$i; done

echo $BUILDTAG $BUILDCOMMIT $BUILDBRANCH

VERSION=${BUILDTAG:1}

printf "$BUILDTAG\r\n$BUILDCOMMIT\r\n$BUILDBRANCH\r\n" > ../../bin/data/version.txt

appdir=/tmp/Trixie16bit.AppDir

rm -rf $appdir

mkdir $appdir
cp appruns/AppRun-x86_64 $appdir/AppRun
chmod 777 $appdir/AppRun
cp ../../graphics/main.png $appdir/Trixie16bit.png
pushd $appdir
ln -s Trixie16bit.png .DirIcon
popd

cp Trixie16bit.desktop $appdir
mkdir $appdir/usr
mkdir $appdir/usr/bin
mkdir $appdir/usr/lib

cp /usr/lib64/libSDL-1.2.so* $appdir/usr/lib
cp /usr/lib64/libSDL_net-1.2.so* $appdir/usr/lib
cp /usr/lib64/libvga.so* $appdir/usr/lib
cp /usr/lib64/libpng16.so* $appdir/usr/lib

cp /usr/bin/dosbox $appdir/usr/bin
cp dosbox.conf $appdir/usr/bin
cp -r ../../bin $appdir/usr/bin/game

export ARCH=x86_64

echo "en" > $appdir/usr/bin/game/data/deflang
appimagetool-x86_64.AppImage $appdir /tmp/Trixie16bit-EN-$VERSION-DOSbox-x86_64.AppImage

echo "ru" > $appdir/usr/bin/game/data/deflang
appimagetool-x86_64.AppImage $appdir /tmp/Trixie16bit-RU-$VERSION-DOSbox-x86_64.AppImage
