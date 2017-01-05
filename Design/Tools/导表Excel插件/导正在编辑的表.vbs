'提取文档路径
Set excelApp=GetObject(,"Excel.Application")
Set wb = excelApp.ActiveWorkbook

'MsgBox wb.FullName
Dim name
name = wb.FullName

'检查文件路径合法性
Dim str
Dim i
Dim keySetting, keyArg, lua, ppath, script
keySetting = "/S数值" '需导出的策划文档目录
keyArg = "/M美术资源"  '需导出的美术文档目录
ppath = "tools/xls2lua/"      '中介程序所在目录
lua = "lua.exe" '导出中介程序
script = "proxy.lua" '导出脚本

'检查文档存放路径是否合法
Dim InputPath
InputPath = wb.FullName
'InputPath = "D:\pet\design\trunk\表\sdfsf.et"
str = Replace(InputPath, "\", "/")
i = InStr(str, keySetting)
If i <= 0 Then
i = InStr(str, keyArg)
End If
if i<= 0 then
 MsgBox "错误!!! 只能导出放置在策划文档路径的 <S数值> 和 <M美术资源> 目录下的文档,细节内容找技术确认"
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

'启动转换脚本
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

'检查结果
if len(errMsg) > 0 then
	'shell.run toolpath + "test.bat " + stdMsg
'	cmd = toolpath + "test.bat " + InputPath 
'	shell.run cmd
	MsgBox "导表失败,看不懂可以叫技术来,出错原因如下:" + errMsg
 	WScript.Quit
end if

if InStr(stdMsg, "OUTPUTSUCCEED") > 0 then
	MsgBox "导表成功! " + InputPath
else
	MsgBox "转换失败,原因如下:" + stdMsg + UStr
end if

Set shell = Nothing

