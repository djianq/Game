VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "转换输出log"
   ClientHeight    =   7590
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   10350
   LinkTopic       =   "Form1"
   ScaleHeight     =   7590
   ScaleWidth      =   10350
   StartUpPosition =   1  '所有者中心
   Begin VB.TextBox Text 
      Height          =   7335
      Left            =   120
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   0
      Text            =   "Form1.frx":0000
      Top             =   120
      Width           =   10095
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub Form_Load()
    Me.Text.Text = "sdfksd;flkjsldffjjj" + vbCrLf + vbCrLf
End Sub
