Option Public
Uselsx "*LSXODBC"
Sub Initialize
	On Error Goto ERR_HANDLER
	Dim Session As  NotesSession 
	Dim Db As NotesDatabase
	Dim dbSystem As NotesDatabase
	Set Session=New NotesSession 
	Set Db=Session.CurrentDatabase
	Set dbSystem=session.GetDatabase(Db.Server,"China\wf\wf000084.NSF")
	
	Dim bolFlag As Boolean 	
	Dim bolResult As Boolean 
	
	'=============连接到ORACLE数据库==============	
	
	Dim odbcConn As New ODBCConnection
	Dim odbcQuery As New ODBCQuery
	Dim odbcRS As New ODBCResultSet	
	Dim strCommand As String
	If Not (odbcConn.ConnectTo ("test","note_adm","9N*o1T6eo")) Then
		MsgBox "OBDC连接错误，请联系统管理员！"
		Exit Sub
	End If	
	
	Msgbox "Leap上传_Oracle[HR_E_CAR_CARMILEAGECLAIM]主表和明细表开始。。"
	
	Set odbcQuery.Connection =odbcConn		
	
	Dim view As NotesView
	Dim docContext As NotesDocument
	Dim doctemp As NotesDocument
	
	'Set view = db.GetView("LeapUploadALLInfo")
	Set view = dbSystem.GetView("LeapUploadALLInfo_CarMileageClaim")
	Set docContext=view.GetFirstDocument()
	While Not(docContext Is Nothing)
		Set docTmp=view.GetNextDocument(docContext)
		
		bolResult=UploadPolicySetup(Session,docContext,odbcQuery,odbcRS,dbSystem)		
		
		bolResult=UploadDetailSetup(Session,docContext,odbcQuery,odbcRS)	
		'上传成功给文档赋值
		'正式库
	
		If(bolResult=True) Then		
			docContext.IsUpload="1"
			Call docContext.save(True,False)	
		Else
			MsgBox CStr(docContext.Serial(0))+"上传失败"
		End If
			

	
		
		Set docContext=docTmp
		
	Wend
	odbcRS.Close(DB_CLOSE)	
	odbcConn.Disconnect	
	MsgBox "Leap上传_Oracle[HR_E_CAR_CARMILEAGECLAIM]主表和明细表结束。。"
	Exit Sub	
ERR_HANDLER:
	Dim strErrorRemind As String 
	strErrorRemind= "Get Error "+Error+" on Line "+Cstr(Erl)+" in [上传主表和明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM]"
	Msgbox strErrorRemind
	Exit Sub	
	
End Sub
Function IllegalCharacter(strSource As String) As String
	On Error Goto ERR_HANDLER	
	IllegalCharacter=Replace(strSource,"'","''")
	Exit Function
ERR_HANDLER:
	IllegalCharacter=strSource
End Function
Function ExecuteUpload(strCommand As String,odbcQuery As ODBCQuery,odbcRS As ODBCResultSet) As Boolean 
	On Error Goto ERR_HANDLER	
	odbcQuery.SQL =strCommand	
	Set odbcRs.Query =odbcQuery	
	'odbcRS.Execute	
	If Not (odbcRS.Execute) Then
		Msgbox odbcRS.GetExtendedErrorMessage+"   "+odbcRS.GetErrorMessage
		ExecuteUpload=False
		Exit Function
	End If
	ExecuteUpload=True	
	Exit Function	
ERR_HANDLER:		
	'Print strCommand
	Msgbox "ERR_HANDLER"
	Msgbox "[上传主表和明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM] ==>ExecuteUpload"
	MsgBox "发生错误的语句为："+strCommand
	Msgbox Cstr(odbcRS.GetExtendedErrorMessage)+" "+Cstr(odbcRS.GetError) +" "+Cstr(odbcRS.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcRS.Error))
	Msgbox Cstr(odbcQuery.GetExtendedErrorMessage)+" "+Cstr(odbcQuery.GetError) +" "+Cstr(odbcQuery.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcQuery.Error))	
	ExecuteUpload=False
	Exit Function
End Function
Function UploadCheck(strTableName As String,strSerial As String,odbcQuery As ODBCQuery,odbcRS As ODBCResultSet,DataCome As String ) As Boolean  
%REM
函数功能：在执行上传操作之前，先检查该表中，是否已有相同Serial的记录，有-(true)则表示该文档被退回需要更新，无-(false)则添加新上传.
strTableName==>表名;strSerial==>报价单号
%END REM
	On Error Goto ERR_HANDLER
	'MsgBox 	"SELECT * FROM "+strTableName+" WHERE UNID='"+strSerial+"' and DataCome='"+DataCome+"'"
	odbcQuery.SQL ="SELECT * FROM "+strTableName+" WHERE UNID='"+strSerial+"' and DataCome='"+DataCome+"'"
	Set odbcRS.Query =odbcQuery	
	odbcRS.Execute	
	If (odbcRS.IsResultSetAvailable) Then				
		UploadCheck=True	
	Else			
		UploadCheck=False
	End If	
	Exit Function	
ERR_HANDLER:
	Msgbox "[上传主表和明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM]==>UploadCheck"
	Msgbox Cstr(odbcRS.GetExtendedErrorMessage)+" "+Cstr(odbcRS.GetError) +" "+Cstr(odbcRS.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcRS.Error))
	Msgbox Cstr(odbcQuery.GetExtendedErrorMessage)+" "+Cstr(odbcQuery.GetError) +" "+Cstr(odbcQuery.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcQuery.Error))		
	UploadCheck=False
	Exit Function
End Function
Function UploadCheckDetail(strTableName As String,strSerial As String,LINESTRING As String ,odbcQuery As ODBCQuery,odbcRS As ODBCResultSet) As Boolean 
%REM
函数功能：在执行上传操作之前，先检查该表中，是否已有相同Serial的记录，有-(true)则表示该文档被退回需要更新，无-(false)则添加新上传.
strTableName==>表名;strSerial==>报价单号
%END REM
	On Error GoTo ERR_HANDLER	
	'MsgBox "SELECT * FROM "+strTableName+" WHERE UNID='"+strSerial+"' and LINESTRING='"+LINESTRING+"'"
	odbcQuery.SQL ="SELECT * FROM "+strTableName+" WHERE UNID='"+strSerial+"' and LINESTRING='"+LINESTRING+"'"
	Set odbcRS.Query =odbcQuery	
	odbcRS.Execute	
	If (odbcRS.IsResultSetAvailable) Then				
		UploadCheckDetail=True	
	Else			
		UploadCheckDetail=False
	End If	
	Exit Function	
ERR_HANDLER:
	MsgBox "[上传主表和明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM]==>UploadCheckDetail"
	MsgBox CStr(odbcRS.GetExtendedErrorMessage)+" "+Cstr(odbcRS.GetError) +" "+Cstr(odbcRS.GetErrorMessage)	
	MsgBox CStr(WhatIsError(odbcRS.Error))
	MsgBox CStr(odbcQuery.GetExtendedErrorMessage)+" "+Cstr(odbcQuery.GetError) +" "+Cstr(odbcQuery.GetErrorMessage)	
	MsgBox CStr(WhatIsError(odbcQuery.Error))		
	UploadCheckDetail=False
	Exit Function
End Function
Function UploadPolicySetup(Session As notessession,docInsureQuotation As notesdocument,odbcQuery As ODBCQuery,odbcRS As ODBCResultSet,FlowDB As NotesDatabase) As Boolean 
	On Error Goto ERR_HANDLER
	UploadPolicySetup=False
	Dim DataCome As String
	DataCome=CStr("wf000084.nsf")
	
	Dim APPForm  As String
	Dim UNID  As String
	Dim WFDocType  As String
	Dim CATEGORY1  As String
	Dim WFStatus  As String
	Dim UploadDate  As String
	Dim RequestNo  As String
	Dim RequestB  As String
	Dim StaffNo  As String
	Dim CostCenterB  As String
	Dim EntityB  As String
	Dim DepartmentB  As String
	Dim LocationB  As String
	Dim PayrollCode  As String
	Dim DateB  As String
	Dim ProjectType  As String
	Dim ProjectNumber  As String
	Dim ProjectManager  As String
	Dim AttachDocID1  As String
	Dim CarPlateNumber  As String
	Dim ClaimingYears  As String
	Dim ClaimingMonth  As String
	Dim CarOdometerNumber  As String
	Dim TotalMiles  As String
	Dim TotalAllowance  As String
	Dim ApplicantType  As String
	Dim StepName  As String
	Dim Executor  As String
	Dim ActualExecutor  As String
	Dim ExecutorDate  As String
	Dim ExecutorComments  As String
	Dim History_Date  As String
	Dim History_Executor  As String
	Dim History_StepName  As String
	Dim History_Action  As String
	Dim RequestNoLabel  As String
	Dim AttachmentLinks  As String
	Dim AttachmentChange  As String
	Dim LeaveTypeText  As String
	Dim EntityText  As String
	Dim APPVersion  As String
	Dim WFInfo  As String
	Dim SendToList  As String

	APPForm  =IllegalCharacter(docInsureQuotation.form(0))
	UNID  =IllegalCharacter(docInsureQuotation.UNID(0))
	WFDocType  =IllegalCharacter(docInsureQuotation.WFDocType(0))
	CATEGORY1  =IllegalCharacter(docInsureQuotation.CATEGORY1(0))
	WFStatus  =IllegalCharacter(docInsureQuotation.WFStatus(0))
	RequestNo  =IllegalCharacter(docInsureQuotation.RequestNo(0))
	RequestB  =IllegalCharacter(docInsureQuotation.RequestB(0))
	StaffNo  =IllegalCharacter(docInsureQuotation.StaffNo(0))
	CostCenterB  =IllegalCharacter(docInsureQuotation.CostCenterB(0))
	EntityB  =IllegalCharacter(docInsureQuotation.EntityB(0))
	DepartmentB  =IllegalCharacter(docInsureQuotation.DepartmentB(0))
	LocationB  =IllegalCharacter(docInsureQuotation.LocationB(0))
	PayrollCode  =IllegalCharacter(docInsureQuotation.PayrollCode(0))
	DateB  =IllegalCharacter(docInsureQuotation.DateB(0))
	ProjectType  =IllegalCharacter(docInsureQuotation.ProjectType(0))
	ProjectNumber  =IllegalCharacter(docInsureQuotation.ProjectNumber(0))
	ProjectManager  =IllegalCharacter(docInsureQuotation.ProjectManager(0))
	AttachDocID1  =IllegalCharacter(docInsureQuotation.AttachDocID1(0))
	CarPlateNumber  =IllegalCharacter(docInsureQuotation.CarPlateNumber(0))
	ClaimingYears  =IllegalCharacter(docInsureQuotation.ClaimingYears(0))
	ClaimingMonth  =IllegalCharacter(docInsureQuotation.ClaimingMonth(0))
	CarOdometerNumber  =IllegalCharacter(docInsureQuotation.CarOdometerNumber(0))
	TotalMiles  =IllegalCharacter(docInsureQuotation.TotalMiles(0))
	TotalAllowance  =IllegalCharacter(docInsureQuotation.TotalAllowance(0))
	ApplicantType  =IllegalCharacter(docInsureQuotation.ApplicantType(0))

	
	RequestNoLabel  =IllegalCharacter(docInsureQuotation.RequestNoLabel(0))
	AttachmentLinks  =IllegalCharacter(docInsureQuotation.AttachmentLinks(0))
	AttachmentChange  =IllegalCharacter(docInsureQuotation.AttachmentChange(0))
	LeaveTypeText  =IllegalCharacter(docInsureQuotation.LeaveTypeText(0))
	EntityText  =IllegalCharacter(docInsureQuotation.EntityText(0))
	APPVersion  =IllegalCharacter(docInsureQuotation.APPVersion(0))
	WFInfo  =IllegalCharacter(docInsureQuotation.WFInfo(0))
	SendToList  =IllegalCharacter(docInsureQuotation.SendToList(0))
	

	
	
	'多值域赋值-历史记录
	History_Date=""
	If docInsureQuotation.HasItem("History_Date") Then
		Set itemfield=docInsureQuotation.GetFirstItem ("History_Date") '
		ForAll strValue In itemfield.Values					
			If (CStr(strValue)<>"") Then
				History_Date=History_Date+CStr(strValue)+"##"
				i=i+1
			End If			
		End ForAll
	End If
	
	History_Executor=""
	If docInsureQuotation.HasItem("History_Executor") Then
		Set itemfield=docInsureQuotation.GetFirstItem ("History_Executor") '
		ForAll strValue In itemfield.Values					
			If (CStr(strValue)<>"") Then
				History_Executor=History_Executor+CStr(strValue)+"##"
				i=i+1
			End If			
		End ForAll
	End If
	
	History_StepName=""
	If docInsureQuotation.HasItem("History_StepName") Then
		Set itemfield=docInsureQuotation.GetFirstItem ("History_StepName") '
		ForAll strValue In itemfield.Values					
			If (CStr(strValue)<>"") Then
				History_StepName=History_StepName+CStr(strValue)+"##"
				i=i+1
			End If			
		End ForAll
	End If
	
	History_Action=""
	If docInsureQuotation.HasItem("History_Action") Then
		Set itemfield=docInsureQuotation.GetFirstItem ("History_Action") '
		ForAll strValue In itemfield.Values					
			If (CStr(strValue)<>"") Then
				History_Action=History_Action+CStr(strValue)+"##"
				i=i+1
			End If			
		End ForAll
	End If
	
	
	
	If History_Date<>"" Then 
		History_Date=Left(History_Date,Len(History_Date)-2)
	End If
	
	If History_Executor<>"" Then 
		History_Executor=Left(History_Executor,Len(History_Executor)-2)
	End If
	
	If History_StepName<>"" Then 
		History_StepName=Left(History_StepName,Len(History_StepName)-2)
	End If
	
	If History_Action<>"" Then 
		History_Action=Left(History_Action,Len(History_Action)-2)
	End If
	
	'----------------------------
	Dim strTmp1 As String
	Dim strTmp2 As String
	Dim strTmp3 As String
	Dim strTmp4 As String
	Dim strTmp5 As String
	Dim strTmp(40) As String 
	
	'抓取流程环节信息名称
	

	Dim dbSystem As NotesDatabase
	Set Session=New NotesSession 
	Set Db=Session.CurrentDatabase
	Set dbSystem=session.GetDatabase(Db.Server,"China\wf\wf000084.NSF")
	
	Dim flowview As NotesView
	Dim flowdoc As NotesDocument
	'Set flowview=FlowDB.GetView("LeapFlowView")
	'Set flowdoc=flowview.Getdocumentbykey(CATEGORY1) 
	Set flowview=dbSystem.GetView("LeapFlowView")
	Set flowdoc=flowview.Getdocumentbykey(CATEGORY1) 
	
	If Not (flowdoc Is Nothing) Then
		strTmp(1)= flowdoc.Description_1(0)
		strTmp(2)= flowdoc.Description_2(0)
		strTmp(3)= flowdoc.Description_3(0)
		strTmp(4)= flowdoc.Description_4(0)
		strTmp(5)= flowdoc.Description_5(0)
		strTmp(6)= flowdoc.Description_6(0)
		strTmp(7)= flowdoc.Description_7(0)
		strTmp(8)= flowdoc.Description_8(0)
		strTmp(9)= flowdoc.Description_9(0)
		strTmp(10)= flowdoc.Description_10(0)
		strTmp(11)= flowdoc.Description_11(0)
		strTmp(12)= flowdoc.Description_12(0)
		strTmp(13)= flowdoc.Description_13(0)
		strTmp(14)= flowdoc.Description_14(0)
		strTmp(15)= flowdoc.Description_15(0)
		strTmp(16)= flowdoc.Description_16(0)
		strTmp(17)= flowdoc.Description_17(0)
		strTmp(18)= flowdoc.Description_18(0)
		strTmp(19)= flowdoc.Description_19(0)
		strTmp(20)= flowdoc.Description_20(0)
		strTmp(21)= flowdoc.Description_21(0)
		strTmp(22)= flowdoc.Description_22(0)
		strTmp(23)= flowdoc.Description_23(0)
		strTmp(24)= flowdoc.Description_24(0)
		strTmp(25)= flowdoc.Description_25(0)
		strTmp(26)= flowdoc.Description_26(0)
		strTmp(27)= flowdoc.Description_27(0)
		strTmp(28)= flowdoc.Description_28(0)
		strTmp(29)= flowdoc.Description_29(0)
		strTmp(30)= flowdoc.Description_30(0)
		strTmp(31)= flowdoc.Description_31(0)
		strTmp(32)= flowdoc.Description_32(0)
		strTmp(33)= flowdoc.Description_33(0)
		strTmp(34)= flowdoc.Description_34(0)
		strTmp(35)= flowdoc.Description_35(0)
		strTmp(36)= flowdoc.Description_36(0)
		strTmp(37)= flowdoc.Description_37(0)
		strTmp(38)= flowdoc.Description_38(0)
		strTmp(39)= flowdoc.Description_39(0)
		strTmp(40)= flowdoc.Description_40(0)
	End If
	
	 
	 
	

	
	'查看流程Field循环13次，对于中间字段为空的使用NULL
	For i= 1 To 40
		
		If i<10 Then 
			
			If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_1").text<>"" Then 					
				strTmp1=strTmp1+docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_1").text+"##"
				strTmp5=strTmp5+strTmp(i)+"##"
			End If
			If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_2").text <>"" Then 
					strTmp2=strTmp2+docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_2").text+"##"
				Else
					strTmp2=strTmp2+"NULL##"
				End If
			End If					
			If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_Date").text <>"" Then 
					strTmp3=strTmp3+docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_Date").text+"##"
				Else
					strTmp3=strTmp3+"NULL##"
				End If
			End If
			If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_Comments").text <>"" Then 
					strTmp4=strTmp4+docInsureQuotation.GetFirstItem ("Field0"+Cstr(i)+"_Comments").text+"##"
				Else
					strTmp4=strTmp4+"NULL##"
				End If
			End If
			
		Else
			
			If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_1").text<>"" Then 					
				strTmp1=strTmp1+docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_1").text+"##"	
				strTmp5=strTmp5+strTmp(i)+"##"					
			End If
			If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_2").text <>"" Then 
					strTmp2=strTmp2+docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_2").text+"##"
				Else
					strTmp2=strTmp2+"NULL##"
				End If
			End If					
			If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_Date").text <>"" Then 
					strTmp3=strTmp3+docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_Date").text+"##"
				Else
					strTmp3=strTmp3+"NULL##"
				End If
			End If
			If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_1").text<>"" Then 
				If docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_Comments").text <>"" Then 
					strTmp4=strTmp4+docInsureQuotation.GetFirstItem ("Field"+Cstr(i)+"_Comments").text+"##"
				Else
					strTmp4=strTmp4+"NULL##"
				End If
			End If
			
		End If
		
		
		
	Next
	If strTmp1<>"" Then 
		strTmp1=Left(strTmp1,Len(strTmp1)-2)
	End If
	If strTmp2<>"" Then 
		strTmp2=Left(strTmp2,Len(strTmp2)-2)
	End If
	If strTmp3<>"" Then 
		strTmp3=Left(strTmp3,Len(strTmp3)-2)
	End If
	If strTmp4<>"" Then 
		strTmp4=Left(strTmp4,Len(strTmp4)-2)
	End If
	If strTmp5<>"" Then 
		strTmp5=Left(strTmp5,Len(strTmp5)-2)
	End If
	
	'MsgBox strTmp5
	
	
	
	'把流程赋值
	StepName=strTmp5
	Executor=strTmp1
	ActualExecutor=strTmp2
	ExecutorDate=strTmp3
	ExecutorComments=strTmp4
	'
	StepName=IllegalCharacter(StepName)
	Executor=IllegalCharacter(Executor)
	ActualExecutor=IllegalCharacter(ActualExecutor)
	ExecutorDate=IllegalCharacter(ExecutorDate)
	ExecutorComments=IllegalCharacter(ExecutorComments)
	History_Date=IllegalCharacter(History_Date)
	History_Executor=IllegalCharacter(History_Executor)
	History_StepName=IllegalCharacter(History_StepName)
	History_Action=IllegalCharacter(History_Action)
	
	
	
	'==========组成的SQL语句============================	
	Dim bolResult As Boolean 	
	Dim strCommand As String
	Dim strUploadTable As String 		 '记录更新的表名
	Dim strErrorID As String			'记录更新失败的字段（每次10行）
	Dim strErrorName As String		'记录失败信息
	strCommand=""
	strUploadTable=""
	strErrorID="0"
	strErrorName=""
	
	'=====表：POLICY==========================
	%REM
上传字段
"SERIAL"	
	%END REM
	
	
	bolResult=UploadCheck("HR_E_CAR_CARMILEAGECLAIM",docInsureQuotation.UniversalID,odbcQuery,odbcRS,DataCome) '上传前的非空检查
	If Not(bolResult) Then
		strCommand="INSERT INTO NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM ("&_
		"""UNID"",""DATACOME"")"&_
		" VALUES "&_
		"('"+docInsureQuotation.UniversalID+"','"+DataCome+"')"
		
		'Msgbox strCommand
		bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句	
		
		If (bolResult) Then
			strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET WFDocType='"+WFDocType+"',"&_
			"APPForm='"+APPForm+"',"&_
			"CATEGORY1='"+CATEGORY1+"',"&_
			"UPLOADDATE=TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS') ,"&_
			"WFStatus='"+WFStatus+"',"&_
			"DataCome='"+DataCome+"',"&_
			"RequestNo='"+RequestNo+"',"&_
			"RequestB='"+RequestB+"',"&_
			"StaffNo='"+StaffNo+"',"&_
			"CostCenterB='"+CostCenterB+"',"&_
			"EntityB='"+EntityB+"',"&_
			"DepartmentB='"+DepartmentB+"',"&_
			"LocationB='"+LocationB+"',"&_
			"PayrollCode='"+PayrollCode+"',"&_
			"DateB='"+DateB+"',"&_
			"ProjectType='"+ProjectType+"',"&_
			"ProjectNumber='"+ProjectNumber+"',"&_
			"ProjectManager='"+ProjectManager+"',"&_
			"AttachDocID1='"+AttachDocID1+"' WHERE UNID='"&_   
			+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
			'Msgbox strCommand
			bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
			If Not(bolResult) Then
				strErrorID="1"
			End If
			
			strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET CarPlateNumber='"+CarPlateNumber+"',"&_
			"ClaimingYears='"+ClaimingYears+"',"&_
			"ClaimingMonth='"+ClaimingMonth+"',"&_
			"CarOdometerNumber='"+CarOdometerNumber+"',"&_
			"TotalMiles='"+TotalMiles+"',"&_
			"TotalAllowance='"+TotalAllowance+"',"&_
			"ApplicantType='"+ApplicantType+"',"&_
			"RequestNoLabel='"+RequestNoLabel+"',"&_
			"AttachmentLinks='"+AttachmentLinks+"',"&_
			"AttachmentChange='"+AttachmentChange+"',"&_
			"LeaveTypeText='"+LeaveTypeText+"',"&_
			"EntityText='"+EntityText+"',"&_
			"APPVersion='"+APPVersion+"',"&_
			"WFInfo='"+WFInfo+"',"&_
			"SendToList='"+SendToList+"' WHERE UNID='"&_   
			+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
			'MsgBox strCommand
			bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
			If Not(bolResult) Then
				strErrorID="2"
			End If
			
			
			strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET StepName='"+StepName+"',"&_
			"Executor='"+Executor+"',"&_
			"ActualExecutor='"+ActualExecutor+"',"&_
			"ExecutorDate='"+ExecutorDate+"',"&_
			"ExecutorComments='"+ExecutorComments+"',"&_
			"History_Date='"+History_Date+"',"&_
			"History_Executor='"+History_Executor+"',"&_
			"History_StepName='"+History_StepName+"',"&_
			"History_Action='"+History_Action+"' WHERE UNID='"&_   
			+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
			'MsgBox strCommand
			bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
			If Not(bolResult) Then
				strErrorID="3"
			End If
		
	
			
			
			If Not(strErrorID="0") Then
				strErrorName="修改记录失败！第"+strErrorID+"更新失败！"
			End If			
		Else
			strErrorName="插入记录失败！"
		End If	
	Else	
		'已经存在记录，该文档是回退文档，执行更新操作
		strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET WFDocType='"+WFDocType+"',"&_
		"APPForm='"+APPForm+"',"&_
		"CATEGORY1='"+CATEGORY1+"',"&_
		"UPLOADDATE=TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS') ,"&_
		"WFStatus='"+WFStatus+"',"&_
		"DataCome='"+DataCome+"',"&_
		"RequestNo='"+RequestNo+"',"&_
		"RequestB='"+RequestB+"',"&_
		"StaffNo='"+StaffNo+"',"&_
		"CostCenterB='"+CostCenterB+"',"&_
		"EntityB='"+EntityB+"',"&_
		"DepartmentB='"+DepartmentB+"',"&_
		"LocationB='"+LocationB+"',"&_
		"PayrollCode='"+PayrollCode+"',"&_
		"DateB='"+DateB+"',"&_
		"ProjectType='"+ProjectType+"',"&_
		"ProjectNumber='"+ProjectNumber+"',"&_
		"ProjectManager='"+ProjectManager+"',"&_
		"AttachDocID1='"+AttachDocID1+"' WHERE UNID='"&_   
		+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
		'Msgbox strCommand
		bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
		If Not(bolResult) Then
			strErrorID="1"
		End If
		
		strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET CarPlateNumber='"+CarPlateNumber+"',"&_
		"ClaimingYears='"+ClaimingYears+"',"&_
		"ClaimingMonth='"+ClaimingMonth+"',"&_
		"CarOdometerNumber='"+CarOdometerNumber+"',"&_
		"TotalMiles='"+TotalMiles+"',"&_
		"TotalAllowance='"+TotalAllowance+"',"&_
		"ApplicantType='"+ApplicantType+"',"&_
		"RequestNoLabel='"+RequestNoLabel+"',"&_
		"AttachmentLinks='"+AttachmentLinks+"',"&_
		"AttachmentChange='"+AttachmentChange+"',"&_
		"LeaveTypeText='"+LeaveTypeText+"',"&_
		"EntityText='"+EntityText+"',"&_
		"APPVersion='"+APPVersion+"',"&_
		"WFInfo='"+WFInfo+"',"&_
		"SendToList='"+SendToList+"' WHERE UNID='"&_   
		+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
		'MsgBox strCommand
		bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
		If Not(bolResult) Then
			strErrorID="2"
		End If
		
		
		strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM SET StepName='"+StepName+"',"&_
		"Executor='"+Executor+"',"&_
		"ActualExecutor='"+ActualExecutor+"',"&_
		"ExecutorDate='"+ExecutorDate+"',"&_
		"ExecutorComments='"+ExecutorComments+"',"&_
		"History_Date='"+History_Date+"',"&_
		"History_Executor='"+History_Executor+"',"&_
		"History_StepName='"+History_StepName+"',"&_
		"History_Action='"+History_Action+"' WHERE UNID='"&_   
		+docInsureQuotation.UniversalID+"' and DataCome='"+DataCome+"'"	
		'MsgBox strCommand
		bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
		If Not(bolResult) Then
			strErrorID="3"
		End If
		
		If Not(strErrorID="0") Then
			strErrorName="修改记录失败！第"+strErrorID+"更新失败！"
		End If		
	End If	
	
	

	
	
	'=====================================================
	If (strErrorName<>"") Then
		'Print "<script>"	
		'Print "alert('上传Oracle出现："+strErrorName+"请联系统管理员！')"
		'Print "window.close();"
		'Print "window.opener.location.href=window.opener.location.href;"
		'Print "</script>"
		Msgbox "上传Oracle出现："+strErrorName+"请联系统管理员"
		Exit Function
	End If	
	
	
	UploadPolicySetup=True	
	
	Exit Function
ERR_HANDLER:
	Msgbox "[上传主表和明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM] ==>UploadPolicySetup"
	Msgbox Cstr(odbcRS.GetExtendedErrorMessage)+" "+Cstr(odbcRS.GetError) +" "+Cstr(odbcRS.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcRS.Error))
	Msgbox Cstr(odbcQuery.GetExtendedErrorMessage)+" "+Cstr(odbcQuery.GetError) +" "+Cstr(odbcQuery.GetErrorMessage)	
	Msgbox Cstr(WhatIsError(odbcQuery.Error))	
	UploadPolicySetup=False
	Msgbox False2
	Exit Function
End Function
Function WhatIsError(number As Integer) As String
	Select Case number
	Case DBSTSACCS : WhatIsError = "DBSTSACCS"
	Case DBSTSAHVR : WhatIsError = "DBSTSAHVR"
	Case DBSTSBADP : WhatIsError = "DBSTSBADP"
	Case DBSTSCANF : WhatIsError = "DBSTSCANF"
	Case DBSTSCARR : WhatIsError = "DBSTSCARR"
	Case DBSTSCCON : WhatIsError = "DBSTSCCON"
	Case DBSTSCNVD : WhatIsError = "DBSTSCNVD"
	Case DBSTSCNVR : WhatIsError = "DBSTSCNVR"
	Case DBSTSCOAR : WhatIsError = "DBSTSCOAR"
	Case DBSTSCPAR : WhatIsError = "DBSTSCPAR"
	Case DBSTSCXIN : WhatIsError = "DBSTSCXIN"
	Case DBSTSENTR : WhatIsError = "DBSTSENTR"
	Case DBSTSEOFD : WhatIsError = "DBSTSEOFD"
	Case DBSTSFAIL : WhatIsError = "DBSTSFAIL"
	Case DBSTSHSTMT : WhatIsError = "DBSTSHSTMT"
	Case DBSTSILLG : WhatIsError = "DBSTSILLG"
	Case DBSTSINTR : WhatIsError = "DBSTSINTR"
	Case DBSTSINVC : WhatIsError = "DBSTSINVC"
	Case DBSTSINVR : WhatIsError = "DBSTSINVR"
	Case DBSTSMEMF : WhatIsError = "DBSTSMEMF"
	Case DBSTSNAFI : WhatIsError = "DBSTSNAFI"
	Case DBSTSNCOJ : WhatIsError = "DBSTSNCOJ"
	Case DBSTSNCOL : WhatIsError = "DBSTSNCOL"
	Case DBSTSNCON : WhatIsError = "DBSTSNCON"
	Case DBSTSNODA : WhatIsError = "DBSTSNODA"
	Case DBSTSNOEX : WhatIsError = "DBSTSNOEX"
	Case DBSTSNQOJ : WhatIsError = "DBSTSNQOJ"
	Case DBSTSNUNQ : WhatIsError = "DBSTSNUNQ"
	Case DBSTSODBC : WhatIsError = "DBSTSODBC"
	Case DBSTSPMIS : WhatIsError = "DBSTSPMIS"
	Case DBSTSRCHG : WhatIsError = "DBSTSRCHG"
	Case DBSTSRDON : WhatIsError = "DBSTSRDON"
	Case DBSTSROWD : WhatIsError = "DBSTSROWD"
	Case DBSTSRUNC : WhatIsError = "DBSTSRUNC"
	Case DBSTSSNFD : WhatIsError = "DBSTSSNFD"
	Case DBSTSUBLE : WhatIsError = "DBSTSUBLE"
	Case DBSTSUNIM : WhatIsError = "DBSTSUNIM"
	End Select
	Mid(WhatIsError, 3, 5) = "sts"
End Function
Function UploadDetailSetup(Session As NotesSession,docInsureQuotation As NotesDocument,odbcQuery As ODBCQuery,odbcRS As ODBCResultSet) As Boolean 
	On Error GoTo ERR_HANDLER
	'添加明细表
	UploadDetailSetup=False
	Dim DTAItem1 As String  '	Category(费用明细)
	Dim DTAItem2 As String  '   Description
	Dim DTAItem3 As String  '   Year 
	Dim DTAItem4 As String  '   Cost Center
	Dim DTAItem5 As String  '   Currency
	Dim DTAItem6 As String  '   EX-Rate
	Dim DTAItem7 As String  '   Original amount 

	Dim LineString As String  '行数
	
	Dim itemfield As NotesItem
	Dim listDetail1 List
	Dim listDetail2 List
	Dim listDetail3 List
	Dim listDetail4 List
	Dim listDetail5 List
	Dim listDetail6 List
	Dim listDetail7 List
	Dim Count3 As Integer
	Count3=1
	
	For i=1 To 9
		Count2=1
		If docInsureQuotation.HasItem("DTAItem"+Cstr(i)) Then
			Set itemfield=docInsureQuotation.GetFirstItem ("DTAItem"+Cstr(i)) '
			ForAll f In itemfield.Values					
				If (CStr(f)<>"") Then
					If i=1 Then 
						listDetail1(CStr(Count2))=f
					End If
					If i=2 Then 
						listDetail2(CStr(Count2))=f
					End If
					If i=3 Then 
						listDetail3(CStr(Count2))=f
					End If
					If i=4 Then 
						listDetail4(CStr(Count2))=f
					End If
					If i=5 Then 
						listDetail5(CStr(Count2))=f
					End If
					If i=6 Then 
						listDetail6(CStr(Count2))=f
					End If
					If i=7 Then 
						listDetail7(CStr(Count2))=f
					End If

					Count2=Count2+1
				End If			
			End ForAll
			
		End If
	Next
	
	
	'==========组成的SQL语句============================	
	Dim bolResult As Boolean 	
	Dim strCommand As String
	Dim strUploadTable As String 		 '记录更新的表名
	Dim strErrorID As String			'记录更新失败的字段（每次10行）
	Dim strErrorName As String		'记录失败信息
	strCommand=""
	strUploadTable=""
	strErrorID="0"
	strErrorName=""
	
	'=====表：HR_E_CAR_CARMILEAGECLAIM_Detail==========================
	
	
	If docInsureQuotation.HasItem("DTAItem1") Then
		Set itemfield=docInsureQuotation.GetFirstItem ("DTAItem1") '
		ForAll f In itemfield.Values
			If (CStr(f)<>"") Then	
				
			
			DTAItem1=""
			DTAItem2=""
			DTAItem3=""
			DTAItem4=""
			DTAItem5=""
			DTAItem6=""
			DTAItem7=""

			
			'赋值
			If  IsElement(listDetail1(CStr(Count3))) Then
				DTAItem1=listDetail1(CStr(Count3))
			End If
			If  IsElement(listDetail2(CStr(Count3))) Then
				DTAItem2=listDetail2(CStr(Count3))
			End If
			If  IsElement(listDetail3(CStr(Count3))) Then
				DTAItem3=listDetail3(CStr(Count3))
			End If
			If  IsElement(listDetail4(CStr(Count3))) Then
				DTAItem4=listDetail4(CStr(Count3))
			End If
			If  IsElement(listDetail5(CStr(Count3))) Then
				DTAItem5=listDetail5(CStr(Count3))
			End If
			If  IsElement(listDetail6(CStr(Count3))) Then
				DTAItem6=listDetail6(CStr(Count3))
			End If
			If  IsElement(listDetail7(CStr(Count3))) Then
				DTAItem7=listDetail7(CStr(Count3))
			End If
		
		
			DTAItem1=IllegalCharacter(DTAItem1)
			DTAItem2=IllegalCharacter(DTAItem2)
			DTAItem3=IllegalCharacter(DTAItem3)
			DTAItem4=IllegalCharacter(DTAItem4)
			DTAItem5=IllegalCharacter(DTAItem5)
			DTAItem6=IllegalCharacter(DTAItem6)
			DTAItem7=IllegalCharacter(DTAItem7)
			
			
			

			bolResult=UploadCheckDetail("HR_E_CAR_CARMILEAGECLAIM_Detail",docInsureQuotation.UniversalID,CStr(Count3),odbcQuery,odbcRS) '上传前的非空检查
			If Not(bolResult) Then
				
				strCommand="INSERT INTO NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM_Detail ("&_
				"""UNID"",""LINESTRING"")"&_
				" VALUES "&_
				"('"+docInsureQuotation.UniversalID+"','"+CStr(Count3)+"')"
				
				'MsgBox strCommand
				bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句	
				If (bolResult) Then
					strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM_Detail SET DTAItem1='"+DTAItem1+"',"&_
					"DTAItem2='"+DTAItem2+"',"&_
					"DTAItem3='"+DTAItem3+"',"&_
					"DTAItem4='"+DTAItem4+"',"&_
					"DTAItem5='"+DTAItem5+"',"&_
					"DTAItem6='"+DTAItem6+"',"&_
					"DTAItem7='"+DTAItem7+"' WHERE UNID='"&_   
					+docInsureQuotation.UniversalID+"' and LINESTRING='"+CStr(Count3)+"'"
					'MsgBox strCommand
					bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
					If Not(bolResult) Then
						strErrorID="1"
					End If
					If Not(strErrorID="0") Then
						strErrorName="修改记录失败！第"+strErrorID+"更新失败！"
					End If		
					
				End If
				
			Else	
				
				'已经存在记录，该文档是回退文档，执行更新操作
				strCommand="UPDATE NOTE_ADM.HR_E_CAR_CARMILEAGECLAIM_Detail SET DTAItem1='"+DTAItem1+"',"&_
				"DTAItem2='"+DTAItem2+"',"&_
				"DTAItem3='"+DTAItem3+"',"&_
				"DTAItem4='"+DTAItem4+"',"&_
				"DTAItem5='"+DTAItem5+"',"&_
				"DTAItem6='"+DTAItem6+"',"&_
				"DTAItem6='"+DTAItem6+"',"&_
				"DTAItem7='"+DTAItem7+"' WHERE UNID='"&_   
				+docInsureQuotation.UniversalID+"' and LINESTRING='"+CStr(Count3)+"'"
				'MsgBox strCommand			
				bolResult=ExecuteUpload(strCommand,odbcQuery,odbcRS)	'执行SQL语句
				If Not(bolResult) Then
					strErrorID="1"
				End If
				If Not(strErrorID="0") Then
					strErrorName="修改记录失败！第"+strErrorID+"更新失败！"
				End If		
				
			End If
			Count3=Count3+1
			End If
		End ForAll
	End If
	

	'=====================================================
	If (strErrorName<>"") Then
		'Print "<script>"	
		'Print "alert('上传Oracle出现："+strErrorName+"请联系统管理员！')"
		'Print "window.close();"
		'Print "window.opener.location.href=window.opener.location.href;"
		'Print "</script>"
		MsgBox "上传Oracle出现："+strErrorName+"请联系统管理员"
		Exit Function
	End If	
	UploadDetailSetup=True	
	
	
	
	
	
	Exit Function
ERR_HANDLER:
	MsgBox "[上传明细表到Oracle]_[HR_E_CAR_CARMILEAGECLAIM] 明细表出错 ==>UploaDetailSetup"
	MsgBox CStr(odbcRS.GetExtendedErrorMessage)+" "+Cstr(odbcRS.GetError) +" "+Cstr(odbcRS.GetErrorMessage)	
	MsgBox CStr(WhatIsError(odbcRS.Error))
	MsgBox CStr(odbcQuery.GetExtendedErrorMessage)+" "+Cstr(odbcQuery.GetError) +" "+Cstr(odbcQuery.GetErrorMessage)	
	MsgBox CStr(WhatIsError(odbcQuery.Error))	
	UploadDetailSetup=False	
	MsgBox False2
	Exit Function
End Function
