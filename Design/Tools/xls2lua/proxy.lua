---------------------------------------------------------------------------
-- $Id: proxy.lua 60664 2011-11-28 11:22:55Z liangyj@NETEASE.COM $
-- ���ɷ���������������������ļ�
---------------------------------------------------------------------------

OUTPUTBASE = ""
------------------
-- ��ʼ��xls������
dofile("xlslua_reader/util/class.lua")
dofile("xlslua_reader/util/common.lua")
dofile("xlslua_reader/util/sheet.lua")
dofile("xlslua_reader/util/colrule.lua")
dofile("xlslua_reader/util/sheetx.lua")
dofile("xlslua_reader/util/maker.lua")
dofile("xlslua_reader/util/asmaker.lua")

----------------------------
-- ���ؽ����ļ�������ָ��xls
-------

local InputFile = arg[1] or "D:/pet/design/trunk/S��ֵ��/������BUFF��/����ʵ�ֱ�.xls"
print("\n InputFile", InputFile)

InputFile = InputFile:gsub("\\", "/")

os.execute(string.format("lua proxy2.lua \"%s\" 1> tmpout.txt 2> tmperr.txt", InputFile))
os.exit()
