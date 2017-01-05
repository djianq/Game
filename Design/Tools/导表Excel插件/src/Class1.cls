VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Class1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit


  Private Const NORMAL_PRIORITY_CLASS = &H20&
  Private Const INFINITE = -1&
  Private Const STARTF_USESTDHANDLES = &H100&
  Private Const SW_HIDE = 0
  Private Const STARTF_USESHOWWINDOW = &H1
  Private Const SW_SHOWNORMAL = 1
    
  Private Type SECURITY_ATTRIBUTES
        nLength   As Long
        lpSecurityDescriptor   As Long
        bInheritHandle   As Long
  End Type
    
  Private Type STARTUPINFO
        cb                               As Long
        lpReserved               As String
        lpDesktop                 As String
        lpTitle                     As String
        dwX                             As Long
        dwY                             As Long
        dwXSize                     As Long
        dwYSize                     As Long
        dwXCountChars         As Long
        dwYCountChars         As Long
        dwFillAttribute     As Long
        dwFlags                     As Long
        wShowWindow             As Integer
        cbReserved2             As Integer
        lpReserved2             As Long
        hStdInput                 As Long
        hStdOutput               As Long
        hStdError                 As Long
  End Type
    
  Private Type PROCESS_INFORMATION
        hProcess                   As Long
        hThread                     As Long
        dwProcessID             As Long
        dwThreadID               As Long
  End Type
    
  Private Declare Function ShellExecute Lib "shell32.dll" Alias _
  "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal _
  lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, _
  ByVal nShowCmd As Long) As Long
    
  Private Declare Function FindExecutable Lib "shell32.dll" Alias _
  "FindExecutableA" (ByVal lpFile As String, ByVal lpDirectory As String, _
  ByVal lpResult As String) As Long
    
  Private Declare Function CreatePipe Lib "kernel32" (phReadPipe As Long, _
  phWritePipe As Long, lpPipeAttributes As Any, ByVal nSize As Long) As Long
    
  Private Declare Function ReadFile Lib "kernel32" (ByVal HFile As Long, ByVal _
  lpBuffer As String, ByVal nNumberOfBytesToRead As Long, lpNumberOfBytesRead _
  As Long, ByVal lpOverlapped As Any) As Long
    
  Private Declare Function GetFileSize Lib "kernel32" (ByVal HFile As Long, _
  lpFileSizeHigh As Long) As Long
    
  Private Declare Function WaitForSingleObject Lib "kernel32" (ByVal hHandle _
  As Long, ByVal dwMilliseconds As Long) As Long
    
  Private Declare Function CreateProcessA Lib "kernel32" (ByVal _
  lpApplicationName As Long, ByVal lpCommandLine As String, _
  lpProcessAttributes As Any, lpThreadAttributes As Any, ByVal bInheritHandles _
  As Long, ByVal dwCreationFlags As Long, ByVal lpEnvironment As Long, ByVal _
  lpCurrentDirectory As Long, lpStartupInfo As Any, lpProcessInformation As _
  Any) As Long
    
  Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long
    
  Private Declare Function TerminateProcess Lib "kernel32" (ByVal hProcess As _
  Long, ByVal uExitCode As Long) As Long
    
  Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)


Implements IDTExtensibility2
Private EXCELAPP As Excel.Application
Private WithEvents objBtn As Office.CommandBarButton
Attribute objBtn.VB_VarHelpID = -1

Private Sub IDTExtensibility2_OnAddInsUpdate(custom() As Variant)
'
End Sub

Private Sub IDTExtensibility2_OnBeginShutdown(custom() As Variant)
'
End Sub

Private Sub IDTExtensibility2_OnConnection(ByVal Application As Object, ByVal ConnectMode As AddInDesignerObjects.ext_ConnectMode, ByVal AddInInst As Object, custom() As Variant)
    Dim bar As Office.CommandBar
    Dim btn As Office.CommandBarButton
    
    Set EXCELAPP = Application
    
    On Error Resume Next
    EXCELAPP.CommandBars("Toolbar_lzr").Delete
    
    Set bar = EXCELAPP.CommandBars.Add("Toolbar_lzr")
    Set btn = bar.Controls.Add(Type:=msoControlButton)
    With btn
        .Caption = "点击开始导表"
        .Style = msoButtonCaption
    End With
    Set objBtn = btn
    bar.Position = msoBarTop
    bar.Visible = True
    
End Sub

Private Sub IDTExtensibility2_OnDisconnection(ByVal RemoveMode As AddInDesignerObjects.ext_DisconnectMode, custom() As Variant)
    On Error Resume Next
    
    EXCELAPP.CommandBars("Toolbar_lzr").Delete
    Set objBtn = Nothing
    Set EXCELAPP = Nothing
End Sub

Private Sub IDTExtensibility2_OnStartupComplete(custom() As Variant)
'
End Sub


    
Public Function GetDriveLetter(ByVal PathString As String) As String
        Dim DriveStr     As String
        DriveStr = Trim$(PathString)
        If InStr(DriveStr, ":") = 2 Then
                GetDriveLetter = Mid$(DriveStr, 1, 2)
        Else
                GetDriveLetter = "C:"
        End If
End Function
    
Public Sub StartProcess(BatchFile As String, InitialPath As String, strOutput As _
  String, strError As String)
    Dim ProcInfo                   As PROCESS_INFORMATION
    Dim ret                             As Long
    Dim lSuccess                   As Long
    Dim StartInfo                 As STARTUPINFO
    Dim SecAttr                     As SECURITY_ATTRIBUTES
    Dim hReadPipe1               As Long
    Dim hWritePipe1             As Long
    Dim hReadPipe2               As Long
    Dim hWritePipe2             As Long
    Dim BytesRead                 As Long
    Dim stdoutBuff               As String
    Dim stderrBuff               As String
    Dim BytesLeft                 As Long
    Dim CurrFolder               As String
    Dim StdOutCharCount     As Integer
    Dim StdErrCharCount     As Integer
    Dim ShowPipeError         As Boolean
    Dim fName                         As String
    
    strOutput = ""
    strError = ""
    ShowPipeError = False
    
    On Error Resume Next
    SecAttr.nLength = Len(SecAttr)
    SecAttr.bInheritHandle = 1&
    SecAttr.lpSecurityDescriptor = 0&
    
    ret = CreatePipe(hReadPipe1, hWritePipe1, SecAttr, 0)
    If ret = 0 Then Exit Sub
    
    ret = CreatePipe(hReadPipe2, hWritePipe2, SecAttr, 0)
    If ret = 0 Then
          CloseHandle (hReadPipe1)
          CloseHandle (hWritePipe1)
          Exit Sub
    End If
    
    StartInfo.cb = Len(StartInfo)
    StartInfo.dwFlags = STARTF_USESTDHANDLES Or STARTF_USESHOWWINDOW
    StartInfo.hStdOutput = hWritePipe1
    StartInfo.hStdError = hWritePipe2
    StartInfo.wShowWindow = SW_HIDE
    
    If InitialPath <> "" Then
          CurrFolder = CurDir
          ChDrive GetDriveLetter(InitialPath)
          ChDir (InitialPath)
    End If
    
    strOutput = strOutput & "Running   command   :   " & BatchFile & vbCrLf & vbCrLf
    ret = CreateProcessA(0&, "" & BatchFile$, SecAttr, SecAttr, 1&, NORMAL_PRIORITY_CLASS, 0&, 0&, StartInfo, ProcInfo)
    
    If ret <> 1 Then
          CloseHandle (hReadPipe1)
          CloseHandle (hWritePipe1)
          CloseHandle (hReadPipe2)
          CloseHandle (hWritePipe2)
          Exit Sub
    End If
    
    StdOutCharCount = 0
    StdErrCharCount = 0
    
    Do
          Do
                BytesLeft = GetFileSize(hReadPipe1, 0&)
                If BytesLeft = -1 Then ShowPipeError = True
                If BytesLeft > 0 Then
                      stdoutBuff = String(BytesLeft, "   ")
                      lSuccess = ReadFile(hReadPipe1, stdoutBuff, BytesLeft, BytesRead, 0&)
                      DoEvents
                      If lSuccess = 1 Then
                            StdOutCharCount = StdOutCharCount + Len(Mid(stdoutBuff, 1, BytesRead))
                            strOutput = strOutput + Mid(stdoutBuff, 1, BytesRead)
                            'strOutput.SelStart   =   Len(strOutput)
                            'strOutput.Refresh
                            DoEvents
                      End If
                End If
          Loop Until BytesLeft <= 0
    
          Do
                BytesLeft = GetFileSize(hReadPipe2, 0&)
                If BytesLeft = -1 Then ShowPipeError = True
                If BytesLeft > 0 Then
                      stderrBuff = String(BytesLeft, "   ")
                      lSuccess = ReadFile(hReadPipe2, stderrBuff, BytesLeft, BytesRead, 0&)
                      DoEvents
                      If lSuccess = 1 Then
                            StdErrCharCount = StdErrCharCount + Len(Mid(stderrBuff, 1, BytesRead))
                            strError = strError + Mid(stderrBuff, 1, BytesRead)
                            'strError.SelStart   =   Len(strOutput)
                            'strError.Refresh
                            DoEvents
                      End If
                End If
          Loop Until BytesLeft <= 0
    
          lSuccess = WaitForSingleObject(ProcInfo.hProcess, 1)
          BytesLeft = GetFileSize(hReadPipe1, 0&) + GetFileSize(hReadPipe2, 0&)
    Loop Until lSuccess = 0 And BytesLeft <= 0
    
    CloseHandle (ProcInfo.hProcess)
    CloseHandle (ProcInfo.hThread)
    CloseHandle (hReadPipe1)
    CloseHandle (hWritePipe1)
    CloseHandle (hReadPipe2)
    CloseHandle (hWritePipe2)
    
    
    If CurrFolder <> "" Then
          ChDrive GetDriveLetter(CurrFolder)
          ChDir (CurrFolder)
    End If
    
  End Sub
  
Private Sub ShowMsg(Msg As String, Succed As Boolean)
    Form1.Text.Text = Msg
    If Not Succed Then
        Form1.Text.ForeColor = RGB(255, 0, 0)
    End If
    Form1.Show 1
End Sub
'
Private Sub objBtn_Click(ByVal Ctrl As Office.CommandBarButton, CancelDefault As Boolean)

     '导出程序实现代码
    Dim str As String
    Dim i As Integer
    Dim keySetting, keyArg, lua, ppath, script
    
    keySetting = "/S数值" '需导出的策划文档目录
    keyArg = "/M美术资源"  '需导出的美术文档目录
    ppath = "Tools/xls2lua/"      '中介程序所在目录
    lua = "lua.exe" '导出中介程序
    script = "proxy.lua" '导出脚本
    
    '检查文档存放路径是否合法
    'str = Replace(ActiveWorkbook.FullName, "\", "/")
    Dim InputPath
    InputPath = EXCELAPP.ActiveWorkbook.FullName
    'InputPath = "D:\pet\design\trunk\S数值表\sdfsf.et"
    str = Replace(InputPath, "\", "/")
    i = InStr(str, keySetting)
    If i <= 0 Then
        i = InStr(str, keyArg)
    End If
   
    If i > 0 Then
        '启动转换程序
        Dim path As String
        Dim wfile1, wfile2
        Dim arg As String
        path = Mid(str, 1, i) + ppath
        wfile1 = path + lua
        wfile2 = path + script
        '切换当前目录
        ChDir (path)
        If Dir(wfile1) <> "" And Dir(wfile2) <> "" Then
            '执行转换脚本
            Dim runcmd As String
            runcmd = lua + " " + script + " " + InputPath
            Dim Msg
            'Msg = VB6DosRunFileName(runcmd)
            
            Dim stdouts As String
            Dim stderrs As String
            
            StartProcess runcmd, path, stdouts, stderrs
           
            If InStr(stdouts, "成功转换") > 0 Then
               
                ShowMsg " ---------------- 文档转换成功 ------------- " + vbCrLf + vbCrLf + InputPath + stdouts, True
                If stderrs <> "" Then
                    ShowMsg "叫程序来看看:" + stderrs, True
                End If
            Else
                ShowMsg "文档转换失败，错误信息如下，有疑问请直接拉程序来看看:" + vbCrLf + vbCrLf + stderrs + vbCrLf + stdouts, False
            End If
        Else
            MsgBox "无法找到转换程序，叫祥子或其他程序过来看看 " + vbCrLf + wfile1
        End If
    Else
        MsgBox "只能导出放置在策划文档路径的 <S数值> 和 <M美术资源> 目录下的文档"
    End If

End Sub
