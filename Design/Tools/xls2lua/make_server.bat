chcp 65001
del server\setting\item\name2type.lua
del server\setting\item\showtype.lua
del server\setting\item\type2class.lua
del server\setting\item\allitemfile.lua
del server\setting\item\Type2OutFile.lua

call _make.bat "../../S数值表" "lua/数值表" setting_server.lua server/maker/ server/setting/

#lua server\maker\maker_物品搜索文件.lua
