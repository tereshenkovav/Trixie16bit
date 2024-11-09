for i in `git tag --list --sort=v:refname`; do BUILDTAG=$i; done

for i in `git rev-parse HEAD`; do BUILDCOMMIT=$i; done
BUILDCOMMIT=${BUILDCOMMIT:0:8}

for i in `git rev-parse --abbrev-ref HEAD`; do BUILDBRANCH=$i; done

echo $BUILDTAG $BUILDCOMMIT $BUILDBRANCH

VERSION=${BUILDTAG:1}

printf "$BUILDTAG\r\n$BUILDCOMMIT\r\n$BUILDBRANCH\r\n" > ../../bin/data/version.txt

appdir=/tmp/Trixie16bit.app
mkdir $appdir
mkdir $appdir/Contents
mkdir $appdir/Contents/MacOS
mkdir $appdir/Contents/Resources

cp Info.plist $appdir/Contents
cp Pkginfo $appdir/Contents
cp Trixie16bit.icns $appdir/Contents/Resources

cp dosbox.conf $appdir/Contents/MacOS
cp osx-x64/* $appdir/Contents/MacOS
cp -r ../../bin $appdir/Contents/MacOS

chmod 777 $appdir/Contents/MacOS/DOSBox
chmod 777 $appdir/Contents/MacOS/Trixie16bit

cd /tmp 

echo "en" > $appdir/Contents/MacOS/bin/data/deflang
zip -r9 Trixie16bit-EN-$VERSION-DOSbox-MacOS.app.zip Trixie16bit.app
hdiutil create -srcfolder $appdir -volname "Trixie16bit" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO -size 14000k -imagekey zlib-level=9 Trixie16bit-EN-$VERSION-DOSbox-MacOS.dmg

echo "ru" > $appdir/Contents/MacOS/bin/data/deflang
zip -r9 Trixie16bit-RU-$VERSION-DOSbox-MacOS.app.zip Trixie16bit.app
hdiutil create -srcfolder $appdir -volname "Trixie16bit" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO -size 14000k -imagekey zlib-level=9 Trixie16bit-RU-$VERSION-DOSbox-MacOS.dmg
