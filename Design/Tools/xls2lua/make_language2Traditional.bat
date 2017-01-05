chcp 65001
@echo off
set input_path="../../S数值表/Z多语言"
set output_path="lua/数值表"
set output_dir="language/"
set maker_dir="server/maker/"
set error_file="error_language.txt"

set has_error=0

echo 转换多语言配置文件
cd dist
xls2lua.exe ../%input_path% ../%output_path% 1> ../xlsout.txt 2> ../%error_file%
cd ..

findstr /N /C:"Traceback" %error_file% && set has_error=1 || set has_error=0
if %has_error%==1 goto:traceback

echo 开始导表
lua.exe _make_language.lua %maker_dir% %output_dir% true 2> %error_file% 

findstr /N /C:"stack traceback:" %error_file% && set has_error=1 || set has_error=0

if %has_error%==0 goto:done

:traceback
color 0C
echo *****************************************
echo ********* 异常出现 **********************
echo *****************************************
type %error_file%
pause
color
goto:eof

:done
del /Q %error_file%
color 0A
echo ============执行成功==============
color
pause
