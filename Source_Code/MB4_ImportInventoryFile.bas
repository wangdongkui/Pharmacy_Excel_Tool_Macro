Attribute VB_Name = "MB4_ImportInventoryFile"
Option Explicit
Option Base 1

Dim arrQualifiedRows()

Sub subMain_ImportInventoryFiles()
    If Not fIsDev() Then On Error GoTo error_handling
    'On Error GoTo error_handling
    
    Set shtCurrMenu = shtMenuCompInvt
    fInitialization
    
    gsRptID = "IMPORT_INVENTORY_FILE"
    Call fUnProtectSheet(shtInventoryRawDataRpt)
    
    Call fReadSysConfig_InputTxtSheetFile
    
    Set dictCompList = fReadConfigCompanyList
    Call fValidateUserInputAndSetToConfigSheet
    
    Call fSetBackToConfigSheetAndUpdategDict_UserTicket
    Call fSetBackToConfigSheetAndUpdategDict_InputFiles
    
    gsRptFilePath = fReadSysConfig_Output(, gsRptType)
    
    Dim i As Integer
    Dim iCnt As Integer
    iCnt = 0
    For i = 0 To dictCompList.count - 1
        gsCompanyID = dictCompList.Keys(i)
        
        If fGetCompany_UserTicked(gsCompanyID) = "Y" Then
            iCnt = iCnt + 1
        End If
    Next
    
    If iCnt <= 0 Then fErr "No Company is selected."
    
    If fIfClearImport Then
        Call fCleanSheetOutputResetSheetOutput(shtInventoryRawDataRpt)
        Call fPrepareOutputSheetHeaderAndTextColumns(shtInventoryRawDataRpt)
    End If
    
    fClearContentLeaveHeader shtSalesCompInvUnified
    Call fSetReplaceUnifyErrorRowCount_SCompInventory(100)
    
    For i = 0 To dictCompList.count - 1
        gsCompanyID = dictCompList.Keys(i)
        
        If fGetCompany_UserTicked(gsCompanyID) = "Y" Then
            'Call fLoadFilesAndRead2Variables
            
            Call fLoadFileByFileTag(gsCompanyID)
            
            Call fReadMasterSheetData(gsCompanyID)
            
'            If gsCompanyID = "PW" Then
'                arrMaster = fFileterTwoDimensionArray(arrMaster, dictMstColIndex("RecordType"), "销售出库")
'            ElseIf gsCompanyID = "SYY" Then
'                arrMaster = fFileterOutTwoDimensionArray(arrMaster, dictMstColIndex("Hospital"), "广州医药有限公司大众药品销售分公司")
'            End If

            Call fGetQualfiedRows
            Call fProcessDataAll
            
            Erase arrMaster
            
            Call fDeleteSheet(gsCompanyID)
            
            Call fAppendArray2Sheet(shtInventoryRawDataRpt, arrOutput)
        End If
    Next
    
    Call fReSequenceSeqNo
    
'    Call fSortDataInSheetSortSheetData(shtInventoryRawDataRpt, Array(dictRptColIndex("SalesCompanyName") _
                                                                , dictRptColIndex("Hospital") _
                                                                , dictRptColIndex("SalesDate") _
                                                                , dictRptColIndex("ProductProducer") _
                                                                , dictRptColIndex("ProductName") _
                                                                , dictRptColIndex("ProductUnit")))
    Call fFormatOutputSheet(shtInventoryRawDataRpt)
    
   ' Call fProtectSheetAndAllowEdit(shtInventoryRawDataRpt, shtInventoryRawDataRpt.Columns(4), UBound(arrOutput, 1) + 1, UBound(arrOutput, 2), False)
    Call fPostProcess(shtInventoryRawDataRpt)
    
    shtInventoryRawDataRpt.Rows(1).RowHeight = 25
    shtInventoryRawDataRpt.Visible = xlSheetVisible
    shtInventoryRawDataRpt.Activate
    shtInventoryRawDataRpt.Range("A1").Select
    
    Call fModifyMoveActiveXButtonOnSheet(shtInventoryRawDataRpt.Cells(1, fGetValidMaxCol(shtInventoryRawDataRpt) + 1) _
                                        , "btnReplaceUnify", 1, 1, , 25, RGB(255, 20, 134), RGB(255, 255, 255))
error_handling:
    If fCheckIfGotBusinessError Then
        GoTo reset_excel_options
    End If
    
    If fCheckIfUnCapturedExceptionAbnormalError Then
        GoTo reset_excel_options
    End If
     
    fMsgBox "成功整合在工作表：[" & shtInventoryRawDataRpt.Name & "] 中，请检查！", vbInformation
    
reset_excel_options:
    Err.Clear
    fClearRefVariables
    fEnableExcelOptionsAll
    'End
End Sub

'Private Function fLoadFilesAndRead2Variables()
'    'gsCompanyID
'    Call fLoadFileByFileTag(gsCompanyID)
'    Call fReadMasterSheetData(gsCompanyID)
'
'End Function

Private Function fValidateUserInputAndSetToConfigSheet()
    Dim ckb As Object
    Dim i As Integer
    Dim sEachCompanyID As String
    Dim sFilePathRange As String
    Dim sEachFilePath  As String
    
    For i = 0 To dictCompList.count - 1
        sEachCompanyID = dictCompList.Keys(i)
        'sFilePathRange = "rngSalesFilePath_" & sEachCompanyID
        
        If Not fActiveXControlExistsInSheet(shtCurrMenu, fGetCompany_CheckBoxName(sEachCompanyID), ckb) Then
            fErr "the checkbox in this sheet does not exist, please check the configureation : [Sales Company List](CheckBox Name)" & fGetCompany_CheckBoxName(sEachCompanyID)
        End If
        
        If ckb.Value Then
            sFilePathRange = fGetCompany_InputFileTextBoxName(sEachCompanyID)
            sEachFilePath = Trim(shtCurrMenu.Range(sFilePathRange).Value)
            
            If Not fFileExists(sEachFilePath) Then
                shtCurrMenu.Activate
                shtCurrMenu.Range(sFilePathRange).Select
                fErr Split(dictCompList(sEachCompanyID), DELIMITER)(1) & ": 输入的文件不存在，请检查：" & vbCr & sEachFilePath
            End If
        
         'Call fSetSalesInfoFileToMainConfig(sEachCompanyID, sEachFilePath)
        End If
    Next
End Function


'Function fSetSalesInfoFileToMainConfig(sCompanyId As String, sFile As String)
'    Call fSetSpecifiedConfigCellAddress(shtSysConf, "[Input Files]", "File Full Path", "Company ID=" & sCompanyId, sFile)
'End Function

Private Function fProcessDataAll()
    Dim lEachOutputRow As Long
    Dim lEachSourceRow As Long
   ' Dim sCompanyLongID As String
    Dim sCompanyName As String
'    Dim iCnt As Long
    Dim sProducer As String
    Dim sProductNameOrig As String
    Dim sProductName As String
    Dim sProductSeries As String
    
    If fUbound(arrQualifiedRows) <= 0 Then Exit Function
    
    'Call fRedimArrOutputBaseArrMaster
    ReDim arrOutput(1 To fUbound(arrQualifiedRows), 1 To fGetReportMaxColumn())
    
  '  sCompanyLongID = fGetCompany_CompanyLongID(gsCompanyID)
    'sCompanyName = fGetCompany_CompanyName(gsCompanyID)
    sCompanyName = fGetCompanyNameByID_Common(gsCompanyID)
    
'    iCnt = 0
'    For lEachRow = LBound(arrMaster, 1) To UBound(arrMaster, 1)
    For lEachOutputRow = LBound(arrQualifiedRows) To UBound(arrQualifiedRows)
        lEachSourceRow = arrQualifiedRows(lEachOutputRow)
        
        arrOutput(lEachOutputRow, dictRptColIndex("SalesCompanyID")) = gsCompanyID
        arrOutput(lEachOutputRow, dictRptColIndex("SalesCompanyName")) = sCompanyName
        arrOutput(lEachOutputRow, dictRptColIndex("OrigInventoryID")) = Left(gsCompanyID & String(15, "_"), 12) _
                                                                & Format(arrMaster(lEachSourceRow, dictMstColIndex("InventoryDate")), "YYYYMMDD") _
                                                                & Format(lEachSourceRow, "00000")
        arrOutput(lEachOutputRow, dictRptColIndex("SeqNo")) = lEachOutputRow
        
        arrOutput(lEachOutputRow, dictRptColIndex("InventoryDate")) = arrMaster(lEachSourceRow, dictMstColIndex("InventoryDate"))
        
        sProducer = Trim(arrMaster(lEachSourceRow, dictMstColIndex("ProductProducer")))
        sProductNameOrig = Trim(arrMaster(lEachSourceRow, dictMstColIndex("ProductName")))
        sProductSeries = Trim(arrMaster(lEachSourceRow, dictMstColIndex("ProductSeries")))
        
        If gsCompanyID = "ZSY" Then
            If InStr(sProducer, "/") > 0 Then sProducer = Trim(Split(sProducer, "/")(1))
        End If
         
        arrOutput(lEachOutputRow, dictRptColIndex("ProductProducer")) = sProducer
        
        sProductName = sProductNameOrig
        If gsCompanyID = "GKYX" Then
            If InStr(sProductNameOrig, "/") > 0 Then
                sProductName = Trim(Split(sProductNameOrig, "/")(0))
                sProductSeries = Trim(Split(sProductNameOrig, "/")(1))
            End If
        End If
        
        arrOutput(lEachOutputRow, dictRptColIndex("ProductName")) = sProductName
        arrOutput(lEachOutputRow, dictRptColIndex("ProductSeries")) = sProductSeries
        
        arrOutput(lEachOutputRow, dictRptColIndex("Quantity")) = arrMaster(lEachSourceRow, dictMstColIndex("Quantity"))
        arrOutput(lEachOutputRow, dictRptColIndex("LotNum")) = "'" & arrMaster(lEachSourceRow, dictMstColIndex("LotNum"))
        
        If dictMstColIndex.Exists("ProductUnit") Then
            arrOutput(lEachOutputRow, dictRptColIndex("ProductUnit")) = arrMaster(lEachSourceRow, dictMstColIndex("ProductUnit"))
        End If
        
        If dictMstColIndex.Exists("SellAmount") Then
            arrOutput(lEachOutputRow, dictRptColIndex("SellAmount")) = arrMaster(lEachSourceRow, dictMstColIndex("SellAmount"))
        End If
        
        
    Next
End Function

Private Function fGetQualfiedRows()
    Dim sProductProducer As String
    Dim sProductName As String
    Dim sProductSeries As String
    Dim iQualifiedCnt As Long
    Dim lEachRow As Long
    
    ReDim arrQualifiedRows(LBound(arrMaster, 1) To UBound(arrMaster, 1))
    
    iQualifiedCnt = 0
    
    For lEachRow = LBound(arrMaster, 1) To UBound(arrMaster, 1)
        If gsCompanyID = "PW" Then
'            If Trim(arrMaster(lEachRow, dictMstColIndex("RecordType"))) = "销售出库" Then
'            Else
'                GoTo next_row
'            End If
        ElseIf gsCompanyID = "SYY" Then
'            If Trim(arrMaster(lEachRow, dictMstColIndex("Hospital"))) = "广州医药有限公司大众药品销售分公司" Then
'                GoTo next_row
'            End If
        Else
        End If
        
        sProductProducer = Trim(arrMaster(lEachRow, dictMstColIndex("ProductProducer")))
        sProductName = Trim(arrMaster(lEachRow, dictMstColIndex("ProductName")))
        sProductSeries = Trim(arrMaster(lEachRow, dictMstColIndex("ProductSeries")))
'
'        If sProductProducer = "津金世" And sProductName = "金世力德(匹多莫德颗粒)" And sProductSeries = "2g:0.4g*6袋" Then
'            GoTo next_row
'        End If
        
        If fProductExistsInExcludingProductListConfig(sProductProducer, sProductName, sProductSeries) Then GoTo next_row
        
        iQualifiedCnt = iQualifiedCnt + 1
        arrQualifiedRows(iQualifiedCnt) = lEachRow
next_row:
    Next
    
    If iQualifiedCnt > 0 Then
        ReDim Preserve arrQualifiedRows(1 To iQualifiedCnt)
    Else
        arrQualifiedRows = Array()
    End If
End Function

Function fReSequenceSeqNo()
    Dim arr()
    Dim lMaxRow As Long
    Dim lCol As Long
    Dim eachRow As Long
    
    lMaxRow = fGetValidMaxRow(shtInventoryRawDataRpt)
    lCol = dictRptColIndex("SeqNo")
    
    arr = fReadRangeDatatoArrayByStartEndPos(shtInventoryRawDataRpt, 2, lCol, lMaxRow, lCol)
    
    lMaxRow = lMaxRow - 1
    For eachRow = LBound(arr, 1) To UBound(arr, 1)
        arr(eachRow, 1) = lMaxRow & "_" & Format(arr(eachRow, 1), "0000")
    Next
    
    shtInventoryRawDataRpt.Cells(2, lCol).Resize(UBound(arr, 1), 1).Value = arr
    Erase arr
End Function

'Private Function fIfClearImport() As Boolean
'    fIfClearImport = shtCurrMenu.OBClearImport.Value
'
'    Dim response As VbMsgBoxResult
'
'    If fIfClearImport Then
'        response = MsgBox(Prompt:="您确定要清空现有导入的数据吗？无法撤消的哦" _
'                            & vbCr & "继续，请点【Yes】" & vbCr & "否则，请点【No】" _
'                            , Buttons:=vbCritical + vbYesNo + vbDefaultButton2)
'        If response <> vbYes Then fErr
'    Else
'        response = MsgBox(Prompt:="您现在选择的是追加导入，请检查您要导入的数据是否有问题，否则可能会因为重复导入而出现重复的销售流向。" _
'                            & vbCr & "继续，请点【Yes】" & vbCr & "否则，请点【No】" _
'                            , Buttons:=vbCritical + vbYesNo + vbDefaultButton2)
'        If response <> vbYes Then fErr
'    End If
'End Function


