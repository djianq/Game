chcp 65001
echo "���ɴ�ת�����ļ��б�......"
cd dist
xls2lua.exe "../../../S��ֵ��" "lua/��ֵ��"
cd ..
echo ========���S��ֵ�� *.xls��*.xls.lua��ת��========

del client\setting\name2type.lua
del client\setting\item_showname.lua
del client\setting\icon_table.lua
del client\setting\item_cfg.lua
call _make.bat "../../../M������Դ/J�ӿ�Ŀ¼" "lua/��Դ��/J�ӿ�Ŀ¼" setting_client.lua client/maker/ client/setting/
