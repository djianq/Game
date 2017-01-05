imports Extensibility
Imports System.Runtime.InteropServices
Imports Microsoft.Office.Core

#Region " Read me for Add-in installation and setup information. "
' When run, the Add-in wizard prepared the registry for the Add-in.
' At a later time, if the Add-in becomes unavailable for reasons such as:
'   1) You moved this project to a computer other than which is was originally created on.
'   2) You chose 'Yes' when presented with a message asking if you wish to remove the Add-in.
'   3) Registry corruption.
' you will need to re-register the Add-in by building the MakeBarSetup project, 
' right click the project in the Solution Explorer, then choose install.
#End Region

<GuidAttribute("366948D4-4A08-4161-9BDC-184CBB05319F"), ProgIdAttribute("MakeBar.Connect")> _
Public Class Connect
	
    Implements Extensibility.IDTExtensibility2

    Private EXCELAPP As Object
    Private addInInstance As Object
    Dim WithEvents objBtn As CommandBarButton
    'Attribute objBtn.VB_VarHelpID = -1

    Public Sub OnBeginShutdown(ByRef custom As System.Array) Implements Extensibility.IDTExtensibility2.OnBeginShutdown
        objBtn.Delete()
    End Sub

    Public Sub OnAddInsUpdate(ByRef custom As System.Array) Implements Extensibility.IDTExtensibility2.OnAddInsUpdate
    End Sub

    Public Sub OnStartupComplete(ByRef custom As System.Array) Implements Extensibility.IDTExtensibility2.OnStartupComplete
        Dim bars As Microsoft.Office.Core.CommandBars
        Dim bar As Microsoft.Office.Core.CommandBar
        Dim barCtrl As Microsoft.Office.Core.CommandBarControl
        Dim btn As Microsoft.Office.Core.CommandBarButton

        On Error Resume Next
        bars = EXCELAPP.CommandBars
        bar = bars.Item("Tools")
        'EXCELAPP.CommandBars("MakeToolBar").Delete()

        For Each barCtrl In bar.Controls
            If barCtrl.Caption = "点我导表" Then
                bar.Controls.Item("点我导表").Delete()
            End If
        Next barCtrl

        objBtn = bar.Controls.Add(Microsoft.Office.Core.MsoControlType.msoControlButton)

        'bar = EXCELAPP.CommandBars.Add("MakeToolBar")

        'btn = bar.Controls.Add(Type:=Microsoft.Office.Core.MsoControlType.msoControlButton)
        With objBtn
            .Caption = "点我导表"
            .Style = Microsoft.Office.Core.MsoButtonStyle.msoButtonCaption
            .Tag = "点我导表"
            .OnAction = "!<MakeBar.Connect>"
            .Visible = True
        End With
        'objBtn = btn
        'bar.Position = Microsoft.Office.Core.MsoBarPosition.msoBarTop
        'bar.Visible = True
    End Sub

    Public Sub OnDisconnection(ByVal RemoveMode As Extensibility.ext_DisconnectMode, ByRef custom As System.Array) Implements Extensibility.IDTExtensibility2.OnDisconnection
        On Error Resume Next
        If RemoveMode <> Extensibility.ext_DisconnectMode.ext_dm_HostShutdown Then Call OnBeginShutdown(custom)
        EXCELAPP = Nothing
    End Sub

    Public Sub OnConnection(ByVal application As Object, ByVal connectMode As Extensibility.ext_ConnectMode, ByVal addInInst As Object, ByRef custom As System.Array) Implements Extensibility.IDTExtensibility2.OnConnection
        EXCELAPP = application
        addInInstance = addInInst

        If (connectMode <> Extensibility.ext_ConnectMode.ext_cm_Startup) Then Call OnStartupComplete(custom)
    End Sub

    Public Function GetDriveLetter(ByVal PathString As String) As String
        Dim DriveStr As String
        DriveStr = Trim$(PathString)
        If InStr(DriveStr, ":") = 2 Then
            GetDriveLetter = Mid$(DriveStr, 1, 2)
        Else
            GetDriveLetter = "C:"
        End If
    End Function

    Private Function FRunCmd(ByVal cmd As String, ByRef errStr As String, Optional ByVal TimeOut As Integer = 3 * 60) As String
        Dim myProc As New Process()
        Dim myProcStInfo As New ProcessStartInfo("cmd.exe")
        myProcStInfo.UseShellExecute = False
        myProcStInfo.RedirectStandardOutput = True
        myProcStInfo.RedirectStandardError = True
        myProcStInfo.CreateNoWindow = True
        myProcStInfo.Arguments = "/c" & cmd
        myProcStInfo.StandardErrorEncoding = System.Text.Encoding.UTF8
        myProcStInfo.StandardOutputEncoding = System.Text.Encoding.UTF8
        myProc.StartInfo = myProcStInfo
        myProc.Start()
        'myProc.WaitForExit(TimeOut * 1000)
        Dim myStreamReader As IO.StreamReader = myProc.StandardOutput
        Dim myStreamErrReader As IO.StreamReader = myProc.StandardError
        Dim myString As String = ""
        Dim tmpStr As String
        Dim tmpErrStr As String
        Dim firstCode As Boolean = myProc.HasExited
        Dim lastCode As Boolean
        Do
            Application.DoEvents()
            tmpStr = myStreamReader.ReadToEnd()
            tmpErrStr = myStreamErrReader.ReadToEnd()
            myString = myString + tmpStr
            errStr = errStr + tmpErrStr
            'MsgBox(myString)
            lastCode = myProc.HasExited
        Loop Until (myProc.HasExited And tmpStr = "" And tmpErrStr = "")
        myProc.Close()
        Return myString
    End Function

    Private Sub ShowMsg(ByVal Msg As String, ByVal Succed As Boolean)
        Dim logFrm As Form1 = New Form1()
        logFrm.MsgLog.Text = Msg
        If Not Succed Then
            logFrm.MsgLog.ForeColor = System.Drawing.Color.FromArgb(255, 0, 0)
        End If
        logFrm.Show()
    End Sub

    Private Sub objBtn_Click(ByVal Ctrl As CommandBarButton, ByRef CancelDefault As Boolean) Handles objBtn.Click
        '导出程序实现代码
        Dim str As String
        Dim i As Integer
        Dim keySetting, keyArg, lua, ppath, script

        keySetting = "/S数值" '需导出的策划文档目录
        keyArg = "/M美术资源"  '需导出的美术文档目录
        ppath = "Tools/xls2lua/"      '中介程序所在目录
        lua = "lua.exe" '导出中介程序
        script = "proxy2.lua" '导出脚本

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
            ChDir(path)
            If Dir(wfile1) <> "" And Dir(wfile2) <> "" Then
                '执行转换脚本
                Dim runcmd As String
                runcmd = lua + " " + script + " " + InputPath
                Dim Msg
                'Msg = VB6DosRunFileName(runcmd)

                Dim stdouts As String
                Dim stderrs As String
                stdouts = FRunCmd(GetDriveLetter(path) + "&& cd " + path + "&&" + runcmd, stderrs)
                If InStr(stdouts, "成功转换") > 0 Then

                    ShowMsg(" ---------------- 文档转换成功 ------------- " + vbCrLf + vbCrLf + InputPath + stdouts, True)
                    If stderrs <> "" Then
                        ShowMsg("叫程序来看看:" + stderrs, True)
                    End If
                Else
                    ShowMsg("文档转换失败，错误信息如下，有疑问请直接拉程序来看看:" + vbCrLf + vbCrLf + stderrs + vbCrLf + stdouts, False)
                End If
            Else
                MsgBox("无法找到转换程序，叫程序过来看看 " + vbCrLf + wfile1)
            End If
        Else
            MsgBox("只能导出放置在策划文档路径的 <S数值表> 和 <M美术资源> 目录下的文档")
        End If

    End Sub
End Class
