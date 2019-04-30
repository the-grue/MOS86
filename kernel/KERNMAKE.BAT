echo off
cls
echo Building Base Operating System Kernel
path=%PATH%;c:\bin
set TMP=c:\TMP
mkdir %TMP%
set DIST=c:\DISTRO
mkdir %DIST%

set INCLUDE=..\include;..\build\include
set LIB=..\lib;..\build\libs

echo Generating Serial Number
make -f makeser.mak all
echo Creating registration script

echo Building Kernel
make -f kernel.mak $$eval.sys
ren $$EVAL.SYS $$MOS.SYS

echo Distributing Kernel
copy $$MOS.SYS %DIST%

echo Distribution Complete
