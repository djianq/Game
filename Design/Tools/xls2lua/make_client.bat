chcp 65001
echo "生成待转换的文件列表......"
cd dist
xls2lua.exe "../../../S数值表" "lua/数值表"
cd ..
echo ========完成S数值表 *.xls到*.xls.lua的转换========

del client\setting\name2type.lua
del client\setting\item_showname.lua
del client\setting\icon_table.lua
del client\setting\item_cfg.lua
call _make.bat "../../../M美术资源/J接口目录" "lua/资源表/J接口目录" setting_client.lua client/maker/ client/setting/
