@echo off

set /p drive=Enter the disk drive letter (e.g., C, D, E): 

echo Deleting *.lnk files...
del /s /q %drive%:\*.lnk

echo Deleting autorun.inf files...
del /s /q %drive%:\autorun.inf

echo Unhiding files...
attrib /s /d -h -r -s %drive%:\*.* 

@echo complete