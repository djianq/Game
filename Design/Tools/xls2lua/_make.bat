chcp 65001
@echo off
echo ================设置变量==================
set input_path=%1
echo 输入路径: %input_path%

set output_path=%2
echo 输出路径: %output_path%

set setting_file=%3
echo 配置文件: %setting_file%

set maker_dir=%4
echo maker所在目录: %maker_dir%

set output_dir=%5
echo 输出目录：%output_dir%

set error_file=error_%setting_file%.txt
echo 发生错误时保存到的文件:%error_file%

rem 删除上次错误文件
del /Q %error_file%  >nul 2>nul

set has_error=0

echo ========开始执行*.xls到*.xls.lua的转换========
echo "获取最新版本的策划配置文档......"
@echo svn up %input_path%
@echo svn up %output_path%

echo 生成待转换的文件列表......
cd dist
xls2lua.exe ../%input_path% ../%output_path% 1> ../xlsout.txt 2> ../%error_file%
cd ..

rem 检查是否exe转换出现Traceback(T是大写的-_-)
findstr /N /C:"Traceback" %error_file% && set has_error=1 || set has_error=0
if %has_error%==1 goto:traceback

echo ========完成*.xls到*.xls.lua的转换========


echo ========开始执行%setting_file%========
rem 导表并输出标准输出、标准错误到文件
lua.exe _make.lua %setting_file% %maker_dir% %output_dir% 2> %error_file%

rem 检查是否存在脚本traceback
findstr /N /C:"stack traceback:" %error_file% && set has_error=1 || set has_error=0

if %has_error%==0 goto:done

:traceback
color 0C
echo ************************************************
echo *************出现错误部分的日志如下*************
echo ************************************************
type %error_file%
echo !!!!!!!!!!!!!!! 出现错误，请查看 !!!!!!!!!!!!!!! 
pause
color
goto:eof


:done
del /Q %error_file%
color 0A
echo ========全部执行成功========
pause
color
