echo off
echo Last chance to CTRL-C before erasing build files
pause

cd tools\unterm
del *.sys
cd ..\..

cd tools\ulib
del *.obj
del ulib.lib
del ulib.bak
cd ..\..

cd tools\import
del *.exe
del *.obj
del *.map
cd ..\..

cd tools\acu
del *.exe
del *.obj
del *.map
cd ..\..

cd tools\cutils
del *.exe
del *.obj
del *.map
cd ..\..

cd kernel
del *.sys
del *.exe
del *.com
del *.obj
del *.map
del *.pub
del *.pss
del *.ndx
cd ..

cd apps
del *.sys
del *.exe
del *.com
del *.obj
del *.map
del *.pub
del *.pss
del *.ndx
cd ..

cd tools\cdlink
del *.sys
del *.exe
del *.com
del *.obj
del *.map
del *.pub
cd ..\..

echo Build files cleaned
