'��ȡ�ĵ�·��
Set excelApp=GetObject(,"Excel.Application")
Set wb = excelApp.ActiveWorkbook

'MsgBox wb.FullName
Dim name
name = wb.FullName

'����ļ�·���Ϸ���
Dim str
Dim i
Dim keySetting, keyArg, lua, ppath, script
keySetting = "/S��ֵ" '�赼���Ĳ߻��ĵ�Ŀ¼
keyArg = "/M������Դ"  '�赼���������ĵ�Ŀ¼
ppath = "tools/xls2lua/"      '�н��������Ŀ¼
lua = "lua.exe" '�����н����
script = "proxy.lua" '�����ű�

'����ĵ����·���Ƿ�Ϸ�
Dim InputPath
InputPath = wb.FullName
'InputPath = "D:\pet\design\trunk\��\sdfsf.et"
str = Replace(InputPath, "\", "/")
i = InStr(str, keySetting)
If i <= 0 Then
i = InStr(str, keyArg)
End If
if i<= 0 then
 MsgBox "����!!! ֻ�ܵ��������ڲ߻��ĵ�·���� <S��ֵ> �� <M������Դ> Ŀ¼�µ��ĵ�,ϸ�������Ҽ���ȷ��"
 WScript.Quit
end if

Function ReadFile(FilePath, CharSet)
	Dim Str
	Set stm = CreateObject("Adodb.Stream")
	stm.Type = 2
	stm.mode = 3
	stm.charset = CharSet
	stm.Open
	stm.loadfromfile FilePath
	Str = stm.readtext
	stm.Close
	Set stm = Nothing
	ReadFile = Str
End Function

'����ת���ű�
dim cmd,toolpath
toolpath = Left(str, i) + ppath
cmd = lua + " " + script + " " + InputPath
'cmd = "test.bat " + InputPath 
MsgBox cmd
Set shell = WScript.CreateObject("WScript.Shell")
shell.CurrentDirectory = toolpath
Dim rel
'Set rel = shell.Exec(cmd2)
Set rel = shell.Exec(cmd)
Do While rel.Status = 0 
          WScript.Sleep 100 
Loop 

Dim errMsg
Dim stdMsg
'errMsg = rel.StdErr.ReadAll()
'stdMsg = rel.StdOut.ReadAll()
errMsg = ReadFile(toolpath + "/tmperr.txt","utf-8")
stdMsg = ReadFile(toolpath + "/tmpout.txt","utf-8")

'�����
if len(errMsg) > 0 then
	'shell.run toolpath + "test.bat " + stdMsg
'	cmd = toolpath + "test.bat " + InputPath 
'	shell.run cmd
	MsgBox "����ʧ��,���������Խм�����,����ԭ������:" + errMsg
 	WScript.Quit
end if

if InStr(stdMsg, "OUTPUTSUCCEED") > 0 then
	MsgBox "����ɹ�! " + InputPath
else
	MsgBox "ת��ʧ��,ԭ������:" + stdMsg + UStr
end if

Set shell = Nothing

