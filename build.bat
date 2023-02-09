@echo off

dir /a:d /b "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\" > temp.txt
set /p compiler_ver=<temp.txt

echo %compiler_ver%

SET compiler_dir="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\%compiler_ver%\bin\Hostx64\x64\cl.exe"


%compiler_dir% longship-engine.cpp /EHsc /Zi /Wall -Isrc\include SDL2main.lib SDL2.lib
%compiler_dir% render-geo-test.cpp /EHsc /Zi /Wall -Isrc/include SDL2main.lib SDL2.lib

del temp.txt

