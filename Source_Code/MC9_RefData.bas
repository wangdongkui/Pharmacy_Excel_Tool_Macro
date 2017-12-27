Attribute VB_Name = "MC9_RefData"
Option Explicit
Option Base 1

Enum Company
    REPORT_ID = 1
    ID = 2
    Name = 3
    Commission = 4
    CheckBoxName = 5
    InputFileTextBoxName = 6
    Selected = 7
End Enum
 
Dim dictHospitalMaster As Dictionary
Dim dictHospitalReplace As Dictionary

Dim dictProducerMaster As Dictionary
Dim dictProducerReplace As Dictionary

Dim dictProductNameMaster As Dictionary
Dim dictProductNameReplace As Dictionary

Dim dictProductMaster As Dictionary
Dim dictProductSeriesReplace As Dictionary
'Dim dictProductUnit As Dictionary
Dim dictProductUnitRatio As Dictionary
'Dim dictProductUnitRatio As Dictionary

Dim dictFirstLevelComm As Dictionary
Dim dictSecondLevelComm As Dictionary

Dim dictCompanyNameID As Dictionary

'Dim bFirstLCommDefaultGot As Boolean
'Dim dblFirstLCommDefault As Double
Dim dictDefaultCommConfiged As Dictionary
'Dim bSecondLCommDefaultGot As Boolean
'Dim SecondLCommDefault As TypeSecondLCommDefault

Dim dictSelfSalesDeductFrom As Dictionary
Dim dictSelfSalesColIndex As Dictionary
Dim arrSelfSales()

Dim dictSalesManCommFrom As Dictionary
Dim dictSalesManCommColIndex As Dictionary
Dim arrSalesManComm()

Function fReadConfigCompanyList(Optional ByRef dictCompanyNameID As Dictionary) As Dictionary
    Dim asTag As String
    Dim arrColsName()
    Dim rngToFindIn As Range
    Dim arrConfigData()
    Dim lConfigStartRow As Long
    Dim lConfigStartCol As Long
    Dim lConfigEndRow As Long
    Dim lConfigHeaderAtRow As Long

    asTag = "[Sales Company List]"
    ReDim arrColsName(Company.REPORT_ID To Company.Selected)
    
    arrColsName(Company.REPORT_ID) = "Company ID"
    arrColsName(Company.ID) = "Company ID In DB"
    arrColsName(Company.Name) = "Company Name"
    arrColsName(Company.Commission) = "Default Commission"
    arrColsName(Company.CheckBoxName) = "CheckBox Name"
    arrColsName(Company.InputFileTextBoxName) = "Input File TextBox Name"
    arrColsName(Company.Selected) = "User Ticked"
     
    arrConfigData = fReadConfigBlockToArrayNet(asTag:=asTag, shtParam:=shtStaticData _
                                , arrColsName:=arrColsName _
                                , lConfigStartRow:=lConfigStartRow _
                                , lConfigStartCol:=lConfigStartCol _
                                , lConfigEndRow:=lConfigEndRow _
                                , lOutConfigHeaderAtRow:=lConfigHeaderAtRow _
                                , abNoDataConfigThenError:=True _
                                )
    Call fValidateDuplicateInArray(arrConfigData, Company.REPORT_ID, False, shtStaticData, lConfigHeaderAtRow, lConfigStartCol, "Company ID")
    Call fValidateDuplicateInArray(arrConfigData, Company.ID, False, shtStaticData, lConfigHeaderAtRow, lConfigStartCol, "Company ID In DB")
    Call fValidateDuplicateInArray(arrConfigData, Company.Name, False, shtStaticData, lConfigHeaderAtRow, lConfigStartCol, "Company Name")
    Call fValidateDuplicateInArray(arrConfigData, Company.CheckBoxName, False, shtStaticData, lConfigHeaderAtRow, lConfigStartCol, "Company Name")
    Call fValidateDuplicateInArray(arrConfigData, Company.InputFileTextBoxName, False, shtStaticData, lConfigHeaderAtRow, lConfigStartCol, "Company Name")
    
'    Call fValidateBlankInArray(arrConfigData, Company.Report_ID, shtstaticdata, lConfigHeaderAtRow, lConfigStartCol, "Company ID")
'    Call fValidateBlankInArray(arrConfigData, Company.ID, shtstaticdata, lConfigHeaderAtRow, lConfigStartCol, "Company ID In DB")
'    Call fValidateBlankInArray(arrConfigData, Company.Name, shtstaticdata, lConfigHeaderAtRow, lConfigStartCol, "Company Name")
    
'    Set fReadConfigCompanyList = fReadArray2DictionaryWithMultipleColsCombined(arrConfigData, Company.Report_ID _
'            , Array(Company.ID, Company.Name, Company.Commission, Company.CheckBoxName, Company.InputFileTextBoxName, Company.Selected) _
'            , DELIMITER)

    Dim dictOut As Dictionary
    Set dictOut = New Dictionary
    
    Set dictCompanyNameID = New Dictionary
    
    Dim lEachRow As Long
    Dim sFileTag As String
    Dim sValueStr As String
    
    For lEachRow = LBound(arrConfigData, 1) To UBound(arrConfigData, 1)
        If fArrayRowIsBlankHasNoData(arrConfigData, lEachRow) Then GoTo next_row
        
'        sRptNameStr = DELIMITER & arrConfigData(lEachRow, 1) & DELIMITER
'        If InStr(sRptNameStr, DELIMITER & asReportID & DELIMITER) <= 0 Then GoTo next_row
        
        'lActualRow = lConfigHeaderAtRow + lEachRow
        
        sFileTag = Trim(arrConfigData(lEachRow, Company.REPORT_ID))
        sValueStr = fComposeStrForDictCompanyList(arrConfigData, lEachRow)
        
        dictOut.Add sFileTag, sValueStr
        
        dictCompanyNameID.Add arrConfigData(lEachRow, Company.Name), arrConfigData(lEachRow, Company.REPORT_ID)
next_row:
    Next
    
    Erase arrColsName
    Erase arrConfigData
    Set fReadConfigCompanyList = dictOut
    Set dictOut = Nothing
End Function

Function fComposeStrForDictCompanyList(arrConfigData, lEachRow As Long) As String
    Dim sOut As String
    Dim i As Integer
    
    For i = Company.ID To Company.Selected
        sOut = sOut & DELIMITER & Trim(arrConfigData(lEachRow, i))
    Next
    
    fComposeStrForDictCompanyList = Right(sOut, Len(sOut) - 1)
End Function

Function fGetCompany_InputFileTextBoxName(asCompanyID As String) As String
    fGetCompany_InputFileTextBoxName = Split(dictCompList(asCompanyID), DELIMITER)(Company.InputFileTextBoxName - Company.REPORT_ID - 1)
End Function
Function fGetCompany_CheckBoxName(asCompanyID As String) As String
    fGetCompany_CheckBoxName = Split(dictCompList(asCompanyID), DELIMITER)(Company.CheckBoxName - Company.REPORT_ID - 1)
End Function
Function fGetCompany_UserTicked(asCompanyID As String) As String
    fGetCompany_UserTicked = Split(dictCompList(asCompanyID), DELIMITER)(Company.Selected - Company.REPORT_ID - 1)
End Function
Function fGetCompany_CompanyLongID(asCompanyID As String) As String
    fGetCompany_CompanyLongID = Split(dictCompList(asCompanyID), DELIMITER)(Company.ID - Company.REPORT_ID - 1)
End Function
Function fGetCompany_CompanyName(asCompanyID As String) As String
    fGetCompany_CompanyName = Split(dictCompList(asCompanyID), DELIMITER)(Company.Name - Company.REPORT_ID - 1)
End Function

'====================== Hospital Master =================================================================
Function fReadSheetHospitalMaster2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("HOSPITAL_MASTER", dictColIndex, arrData, , , , , shtHospital)
    Set dictHospitalMaster = fReadArray2DictionaryOnlyKeys(arrData, dictColIndex("Hospital"))
    
    Set dictColIndex = Nothing
End Function
Function fHospitalExistsInHospitalMaster(sHospital As String) As Boolean
    If dictHospitalMaster Is Nothing Then Call fReadSheetHospitalMaster2Dictionary
    
    fHospitalExistsInHospitalMaster = dictHospitalMaster.Exists(sHospital)
End Function
'------------------------------------------------------------------------------

'====================== Hospital Replacement =================================================================
Function fReadSheetHospitalReplace2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("HOSPITAL_REPLACE_SHEET", dictColIndex, arrData, , , , , shtHospitalReplace)
    Set dictHospitalReplace = fReadArray2DictionaryWithSingleCol(arrData, dictColIndex("FromHospital"), dictColIndex("ToHospital"))
    
    Set dictColIndex = Nothing
End Function
Function fFindInConfigedReplaceHospital(sHospital As String) As String
    If dictHospitalReplace Is Nothing Then Call fReadSheetHospitalReplace2Dictionary
    
    If dictHospitalReplace.Exists(sHospital) Then
        fFindInConfigedReplaceHospital = dictHospitalReplace(sHospital)
    Else
        fFindInConfigedReplaceHospital = ""
    End If
End Function
'------------------------------------------------------------------------------

'====================== Producer Master =================================================================
Function fReadSheetProducerMaster2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCER_MASTER", dictColIndex, arrData, , , , , shtProductProducerMaster)
    Set dictProducerMaster = fReadArray2DictionaryOnlyKeys(arrData, dictColIndex("ProductProducer"), True, False)
    
    Set dictColIndex = Nothing
End Function
Function fProducerExistsInProducerMaster(sProducer As String) As Boolean
    If dictProducerMaster Is Nothing Then Call fReadSheetProducerMaster2Dictionary
    
    fProducerExistsInProducerMaster = dictProducerMaster.Exists(sProducer)
End Function
'------------------------------------------------------------------------------

'====================== Producer Replacement =================================================================
Function fReadSheetProducerReplace2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCER_REPLACE_SHEET", dictColIndex, arrData, , , , , shtProductProducerReplace)
    Set dictProducerReplace = fReadArray2DictionaryWithSingleCol(arrData, dictColIndex("FromProducer"), dictColIndex("ToProducer"))
    
    Set dictColIndex = Nothing
End Function
Function fFindInConfigedReplaceProducer(sProducer As String) As String
    If dictProducerReplace Is Nothing Then Call fReadSheetProducerReplace2Dictionary
    
    If dictProducerReplace.Exists(sProducer) Then
        fFindInConfigedReplaceProducer = dictProducerReplace(sProducer)
    Else
        fFindInConfigedReplaceProducer = ""
    End If
End Function
'------------------------------------------------------------------------------


'====================== ProductName Master =================================================================
Function fReadSheetProductNameMaster2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCER_NAME_MASTER", dictColIndex, arrData, , , , , shtProductNameMaster)
    Call fValidateDuplicateInArray(arrData, Array(dictColIndex("ProductProducer"), dictColIndex("ProductName")), False, shtProductNameMaster, 1, 1, "厂家 + 名称")
    
    Set dictProductNameMaster = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
                                    , Array(dictColIndex("ProductProducer"), dictColIndex("ProductName")) _
                                    , Array(dictColIndex("ProductName")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fProductNameExistsInProductNameMaster(sProductProducer As String, sProductName As String) As Boolean
    If dictProductNameMaster Is Nothing Then Call fReadSheetProductNameMaster2Dictionary
    
    fProductNameExistsInProductNameMaster = dictProductNameMaster.Exists(sProductProducer & DELIMITER & sProductName)
End Function
'------------------------------------------------------------------------------

'====================== ProductName Replacement =================================================================
Function fReadSheetProductNameReplace2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCT_NAME_REPLACE_SHEET", dictColIndex, arrData, , , , , shtProductNameReplace)
    Set dictProductNameReplace = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
                                    , Array(dictColIndex("ProductProducer"), dictColIndex("FromProductName")) _
                                    , Array(dictColIndex("ToProductName")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fFindInConfigedReplaceProductName(sProductProducer As String, sProductName As String) As String
    Dim sKey As String
    
    If dictProductNameReplace Is Nothing Then Call fReadSheetProductNameReplace2Dictionary
    
    sKey = sProductProducer & DELIMITER & sProductName
    
    If dictProductNameReplace.Exists(sKey) Then
        fFindInConfigedReplaceProductName = dictProductNameReplace(sKey)
    Else
        fFindInConfigedReplaceProductName = ""
    End If
End Function
'------------------------------------------------------------------------------


'====================== ProductSeries Master =================================================================
Function fReadSheetProductMaster2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCT_MASTER", dictColIndex, arrData, , , , , shtProductMaster)
    Call fValidateDuplicateInArray(arrData, Array(dictColIndex("ProductProducer"), dictColIndex("ProductName"), dictColIndex("ProductSeries")), False, shtProductMaster, 1, 1, "厂家 + 名称 + 规格")
    
    Set dictProductMaster = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
                                    , Array(dictColIndex("ProductProducer"), dictColIndex("ProductName"), dictColIndex("ProductSeries")) _
                                    , Array(dictColIndex("ProductUnit"), dictColIndex("LatestPrice")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fProductSeriesExistsInProductMaster(sProductProducer As String, sProductName As String, sProductSeries As String) As Boolean
    If dictProductMaster Is Nothing Then Call fReadSheetProductMaster2Dictionary
    
    fProductSeriesExistsInProductMaster = dictProductMaster.Exists(sProductProducer & DELIMITER & sProductName & DELIMITER & sProductSeries)
End Function
Function fProductKeysExistsInProductMaster(sProductProducer As String, sProductName As String, sProductSeries As String) As Boolean
    fProductKeysExistsInProductMaster = fProductSeriesExistsInProductMaster(sProductProducer, sProductName, sProductSeries)
End Function
'------------------------------------------------------------------------------

'====================== ProductSeries Replacement =================================================================
Function fReadSheetProductSeriesReplace2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCT_SERIES_REPLACE_SHEET", dictColIndex, arrData, , , , , shtProductSeriesReplace)
    Set dictProductSeriesReplace = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
                                    , Array(dictColIndex("ProductProducer"), dictColIndex("ProductName"), dictColIndex("FromProductSeries")) _
                                    , Array(dictColIndex("ToProductSeries")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fFindInConfigedReplaceProductSeries(sProductProducer As String, sProductName As String, sOrigProductSeries As String) As String
    Dim sKey As String
    
    If dictProductSeriesReplace Is Nothing Then Call fReadSheetProductSeriesReplace2Dictionary
    
    sKey = sProductProducer & DELIMITER & sProductName & DELIMITER & sOrigProductSeries
    
    If dictProductSeriesReplace.Exists(sKey) Then
        fFindInConfigedReplaceProductSeries = dictProductSeriesReplace(sKey)
    Else
        fFindInConfigedReplaceProductSeries = ""
    End If
End Function
'------------------------------------------------------------------------------

'====================== ProductUnit Ratio =================================================================
Function fReadSheetProductUnitRatio2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("PRODUCT_UNIT_RATIO_SHEET", dictColIndex, arrData, , , , , shtProductUnitRatio)
    Set dictProductUnitRatio = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
                                    , Array(dictColIndex("ProductProducer"), dictColIndex("ProductName"), dictColIndex("ProductSeries"), dictColIndex("FromUnit")) _
                                    , Array(dictColIndex("ProductUnit"), dictColIndex("Ratio")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fFindInConfigedReplaceProductUnit(sProductProducer As String, sProductName As String, sProductSeries As String _
                            , sOrigProductUnit As String _
                            , ByRef dblRatio As Double) As String
    Dim sKey As String
    
    If dictProductUnitRatio Is Nothing Then Call fReadSheetProductUnitRatio2Dictionary
    
    sKey = sProductProducer & DELIMITER & sProductName & DELIMITER & sProductSeries & DELIMITER & sOrigProductUnit
    
    If dictProductUnitRatio.Exists(sKey) Then
        dblRatio = Split(dictProductUnitRatio(sKey), DELIMITER)(1)
        fFindInConfigedReplaceProductUnit = Split(dictProductUnitRatio(sKey), DELIMITER)(0)
    Else
        dblRatio = 1
        fFindInConfigedReplaceProductUnit = ""
    End If
End Function

Function fGetProductMasterUnit(sProductProducer As String, sProductName As String, sProductSeries As String) As String
    Dim sKey As String
    
    If dictProductMaster Is Nothing Then Call fReadSheetProductMaster2Dictionary
    
    sKey = sProductProducer & DELIMITER & sProductName & DELIMITER & sProductSeries
    
    If Not dictProductMaster.Exists(sKey) Then _
        fErr "药品厂家+名称+规格 还不存在于药品主表中, 会计单位找不到的情况下，计算无法进行：" & vbCr & sProductProducer & vbCr & sProductName & vbCr & sProductSeries
    
    fGetProductMasterUnit = Split(dictProductMaster(sKey), DELIMITER)(0)
End Function
'------------------------------------------------------------------------------

'====================== 1st Level Commission =================================================================
Function fReadSheetFirstLevelComm2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("FIRST_LEVEL_COMMISSION", dictColIndex, arrData, , , , , shtFirstLevelCommission)
    Set dictFirstLevelComm = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
            , Array(dictColIndex("SalesCompany") _
                  , dictColIndex("ProductProducer") _
                  , dictColIndex("ProductName") _
                  , dictColIndex("ProductSeries")) _
            , Array(dictColIndex("Commission")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fGetFirstLevelComm(sFirstLevelKey As String, ByRef dblFirstComm As Double) As Boolean
    If dictFirstLevelComm Is Nothing Then Call fReadSheetFirstLevelComm2Dictionary
    
    Dim bOut As Boolean
    
    bOut = dictFirstLevelComm.Exists(sFirstLevelKey)
    
    dblFirstComm = 0
    If bOut Then dblFirstComm = dictFirstLevelComm(sFirstLevelKey)
    
    fGetFirstLevelComm = bOut
End Function
'------------------------------------------------------------------------------


'====================== 2nd Level Commission =================================================================
Function fReadSheetSecondLevelComm2Dictionary()
    Dim arrData()
    Dim dictColIndex As Dictionary
    
    Call fReadSheetDataByConfig("SECOND_LEVEL_COMMISSION", dictColIndex, arrData, , , , , shtSecondLevelCommission)
    Set dictSecondLevelComm = fReadArray2DictionaryMultipleKeysWithMultipleColsCombined(arrData _
            , Array(dictColIndex("SalesCompany") _
                  , dictColIndex("Hospital") _
                  , dictColIndex("ProductProducer") _
                  , dictColIndex("ProductName") _
                  , dictColIndex("ProductSeries")) _
            , Array(dictColIndex("Commission")), DELIMITER, DELIMITER)
    Set dictColIndex = Nothing
End Function
Function fGetSecondLevelComm(sSecondLevelCommKey As String, ByRef dblSecondComm As Double) As Boolean
    If dictSecondLevelComm Is Nothing Then Call fReadSheetSecondLevelComm2Dictionary
    
    If dictSecondLevelComm.Exists(sSecondLevelCommKey) Then
        dblSecondComm = dictSecondLevelComm(sSecondLevelCommKey)
        
        fGetSecondLevelComm = True
    Else
        dblSecondComm = 0
        fGetSecondLevelComm = False
    End If
End Function
'------------------------------------------------------------------------------

Function fGetConfigFirstLevelDefaultComm() As Double
    If dictDefaultCommConfiged Is Nothing Then Call fReadConfigSecondLCommDefault2Dictionary
    
    If Not dictDefaultCommConfiged.Exists("FIRST_LEVEL_COMMISSION_DEFAULT") Then fErr "配置没有设置采芝林默认配送费：FIRST_LEVEL_COMMISSION_DEFAULT"
    fGetConfigFirstLevelDefaultComm = dictDefaultCommConfiged("FIRST_LEVEL_COMMISSION_DEFAULT")
End Function

Function fGetConfigSecondLevelDefaultComm(sSalesCompName As String) As Double
    If dictDefaultCommConfiged Is Nothing Then Call fReadConfigSecondLCommDefault2Dictionary

    Dim sCompID As String
    Dim dblDefault As Double
    
    sCompID = fGetCompanyIdByCompanyName(sSalesCompName)
    
    dblDefault = dictDefaultCommConfiged("SECOND_LEVEL_COMMISSION_DEFAULT_" & sCompID)
    
    If sCompID = "CZL" Then
        If dblDefault <> 0 Then fMsgBox "这是采芝林公司，但是配送费却不是0， 请检查是否有误。"
    Else
        If dblDefault = 0 Then fMsgBox "这是" & sSalesCompName & "公司，但是配送费却是0，请检查是否有误。"
    End If
    
    fGetConfigSecondLevelDefaultComm = dblDefault
End Function

Function fReadConfigSecondLCommDefault2Dictionary()
    Dim asTag As String
    Dim arrColsName(3)
    Dim rngToFindIn As Range
    Dim arrConfigData()
    Dim arrColsIndex()
    Dim lConfigStartRow As Long
    Dim lConfigStartCol As Long
    Dim lConfigEndRow As Long
    Dim lConfigHeaderAtRow As Long
                                
    asTag = "[System Misc Settings]"
    arrColsName(1) = "Setting Item ID"
    arrColsName(2) = "Value"
    arrColsName(3) = "Value Type"
                                
    Call fReadConfigBlockToArray(asTag:=asTag, shtParam:=shtSysConf _
                                , arrColsName:=arrColsName _
                                , arrConfigData:=arrConfigData _
                                , arrColsIndex:=arrColsIndex _
                                , lConfigStartRow:=lConfigStartRow _
                                , lConfigStartCol:=lConfigStartCol _
                                , lConfigEndRow:=lConfigEndRow _
                                , lOutConfigHeaderAtRow:=lConfigHeaderAtRow _
                                , abNoDataConfigThenError:=True)
    
    Call fValidateDuplicateInArray(arrConfigData, 1, False, shtSysConf, lConfigHeaderAtRow, lConfigStartCol, "Setting Item ID")
    
    Dim lEachRow As Long
    Dim lActualRow As Long
    Dim sKey As String
    Dim sValueType As String
    
    Set dictDefaultCommConfiged = New Dictionary
    
    For lEachRow = LBound(arrConfigData, 1) To UBound(arrConfigData, 1)
        If fArrayRowIsBlankHasNoData(arrConfigData, lEachRow) Then GoTo next_row
        
        lActualRow = lConfigHeaderAtRow + lEachRow
        
        sKey = Trim(arrConfigData(lEachRow, arrColsIndex(1)))
        sValueType = Trim(arrConfigData(lEachRow, arrColsIndex(3)))
        
        If sValueType = "GET_VALUE" Then
            dictDefaultCommConfiged.Add sKey, arrConfigData(lEachRow, arrColsIndex(2))
        ElseIf sValueType = "GET_ADDRESS" Then
            dictDefaultCommConfiged.Add sKey, shtSysConf.Cells(lActualRow, lConfigStartCol + arrColsIndex(2) - 1).Address(external:=True)
        Else
            fErr "the Value Type cannot be blank at row " & lActualRow & vbCr & "sheet:" & shtSysConf.Name
        End If
next_row:
    Next
    
    Erase arrConfigData
    Erase arrColsName
    Erase arrColsIndex
End Function

Function fGetSysMiscConfig(sSettingItemID As String, Optional sMsgHeader As String = "")
    If dictDefaultCommConfiged Is Nothing Then Call fReadConfigSecondLCommDefault2Dictionary
    
    If Not dictDefaultCommConfiged.Exists(sSettingItemID) Then
        fErr "[System Misc Settings] has not such config item: " & sSettingItemID & vbCr & vbCr & sMsgHeader
    End If
    
    fGetSysMiscConfig = dictDefaultCommConfiged(sSettingItemID)
End Function

Function fGetCompanyIdByCompanyName(sSalesCompName As String) As String
    sSalesCompName = Trim(sSalesCompName)
    If dictCompanyNameID Is Nothing Then Call fReadConfigCompanyList(dictCompanyNameID)
    
    If Not dictCompanyNameID.Exists(sSalesCompName) Then fErr "公司名称有错误，请检查。"
    
    fGetCompanyIdByCompanyName = Trim(dictCompanyNameID(sSalesCompName))
End Function

'====================== Self Sales =================================================================
Function fReadSelfSalesOrder2Dictionary()
    Dim sTmpKey As String
    Dim sProducer As String, sProductName As String, sProductSeries As String
    Dim dblSellQuantity As Double
    Dim dblHospitalQuantity As Double
    Dim dictSelfSalesDeductTo As Dictionary
    Dim lEachRow As Long

    Call fSortDataInSheetSortSheetDataByFileSpec("SELF_SALES_ORDER", Array("ProductProducer" _
                                    , "ProductName" _
                                    , "ProductSeries" _
                                    , "SalesDate"), , shtSelfSalesCal)
    
    Call fReadSheetDataByConfig("SELF_SALES_ORDER", dictSelfSalesColIndex, arrSelfSales, , , , , shtSelfSalesCal)
    
    Set dictSelfSalesDeductTo = New Dictionary
    Set dictSelfSalesDeductFrom = New Dictionary
    For lEachRow = LBound(arrSelfSales, 1) To UBound(arrSelfSales, 1)
        dblSellQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("SellQuantity"))
        dblHospitalQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("HospitalSellQuantity"))
        
        
        If dblSellQuantity < dblHospitalQuantity Then fErr "数据出错，医院销售数量不应该大于出货数量" _
                        & vbCr & "工作表：" & shtSelfSalesCal.Name _
                        & vbCr & "行号：" & lEachRow + 1
        If dblSellQuantity = dblHospitalQuantity Then GoTo next_row
        
        sProducer = arrSelfSales(lEachRow, dictSelfSalesColIndex("ProductProducer"))
        sProductName = arrSelfSales(lEachRow, dictSelfSalesColIndex("ProductName"))
        sProductSeries = arrSelfSales(lEachRow, dictSelfSalesColIndex("ProductSeries"))
        
        sTmpKey = sProducer & DELIMITER & sProductName & DELIMITER & sProductSeries
        
        If Not dictSelfSalesDeductFrom.Exists(sTmpKey) Then
            dictSelfSalesDeductFrom.Add sTmpKey, lEachRow
        End If
        dictSelfSalesDeductTo(sTmpKey) = lEachRow
next_row:
    Next
    
    For lEachRow = 0 To dictSelfSalesDeductFrom.Count - 1
        dictSelfSalesDeductFrom(dictSelfSalesDeductFrom.Keys(lEachRow)) = dictSelfSalesDeductFrom.Items(lEachRow) _
                    & DELIMITER & dictSelfSalesDeductTo.Items(lEachRow)
    Next
    
   ' Set dictSelfSalesColIndex = Nothing
    Set dictSelfSalesDeductTo = Nothing
End Function
Function fCalculateCostPriceFromSelfSalesOrder(sProductKey As String _
                    , ByRef dblSalesQuantity As Double, ByRef dblCostPrice As Double) As Boolean
    If dblSalesQuantity > 0 Then
        fCalculateCostPriceFromSelfSalesOrder = fCalculateCostPriceFromSelfSalesOrderNoraml(sProductKey, dblSalesQuantity, dblCostPrice)
    ElseIf dblSalesQuantity < 0 Then
        fCalculateCostPriceFromSelfSalesOrder = fCalculateCostPriceFromSelfSalesOrderWithdraw(sProductKey, dblSalesQuantity, dblCostPrice)
    Else
        fErr "销售数量为0"
    End If
End Function
Function fCalculateCostPriceFromSelfSalesOrderNoraml(sProductKey As String _
                    , ByRef dblSalesQuantity As Double, ByRef dblCostPrice As Double) As Boolean
    If dictSelfSalesDeductFrom Is Nothing Then Call fReadSelfSalesOrder2Dictionary
    
    Dim bOut As Boolean
    Dim lDeductStartRow As Long
    Dim lDeductEndRow As Long
    Dim dblSelfSellQuantity As Double
    Dim dblHospitalQuantity As Double
    Dim dblBalance As Double
    Dim dblCurrRowBalance As Double
    Dim dblToDeduct As Double
    Dim lEachRow As Long
    Dim dblAccAmt As Double
    Dim dblPrice As Double
    
    bOut = False
    
    If Not dictSelfSalesDeductFrom.Exists(sProductKey) Then GoTo exit_fun
    
    lDeductStartRow = Split(dictSelfSalesDeductFrom(sProductKey), DELIMITER)(0)
    lDeductEndRow = Split(dictSelfSalesDeductFrom(sProductKey), DELIMITER)(1)
    
    dblAccAmt = 0
    dblBalance = dblSalesQuantity
    For lEachRow = lDeductStartRow To lDeductEndRow
        If dblBalance <= 0 Then Exit For
        
        dblSelfSellQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("SellQuantity"))
        dblHospitalQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("HospitalSellQuantity"))
        dblPrice = arrSelfSales(lEachRow, dictSelfSalesColIndex("SellPrice"))
        
        If dblSelfSellQuantity <= dblHospitalQuantity Then fErr "这一行的日期晚，不应该出现抵扣" _
                        & vbCr & "工作表：" & shtSelfSalesCal.Name _
                        & vbCr & "行号：" & lEachRow + 1
        
        dblCurrRowBalance = dblSelfSellQuantity - dblHospitalQuantity
        dblBalance = dblBalance - dblCurrRowBalance
        
        If dblBalance > 0 Then  'still has to find next row to deduct
            dblToDeduct = dblSelfSellQuantity
            
            If lEachRow < lDeductEndRow Then
                dictSelfSalesDeductFrom(sProductKey) = lEachRow + 1 & DELIMITER & lDeductEndRow
            Else
                dictSelfSalesDeductFrom.Remove sProductKey
            End If
            
            dblAccAmt = dblAccAmt + dblCurrRowBalance * dblPrice
        Else
            dblAccAmt = dblAccAmt + (dblCurrRowBalance + dblBalance) * dblPrice
            dblToDeduct = (dblCurrRowBalance + dblBalance) + dblHospitalQuantity
        End If
        
        arrSelfSales(lEachRow, dictSelfSalesColIndex("HospitalSellQuantity")) = dblToDeduct
    Next
    
    If dblBalance <= 0 Then
        bOut = True
        dblCostPrice = dblAccAmt / dblSalesQuantity
    End If
    
exit_fun:
    fCalculateCostPriceFromSelfSalesOrderNoraml = bOut
End Function




Function fCalculateCostPriceFromSelfSalesOrderWithdraw(sProductKey As String _
                    , ByRef dblSalesQuantity As Double, ByRef dblCostPrice As Double) As Boolean
    If dictSelfSalesDeductFrom Is Nothing Then Call fReadSelfSalesOrder2Dictionary
    
    Dim bOut As Boolean
    Dim lDeductStartRow As Long
    Dim lDeductEndRow As Long
    Dim dblSelfSellQuantity As Double
    Dim dblHospitalQuantity As Double
    Dim dblBalance As Double
    Dim dblCurrRowBalance As Double
    Dim dblToDeduct As Double
    Dim lEachRow As Long
    Dim dblAccAmt As Double
    Dim dblPrice As Double
    
    bOut = False
    
    If Not dictSelfSalesDeductFrom.Exists(sProductKey) Then GoTo exit_fun
    
    lDeductStartRow = Split(dictSelfSalesDeductFrom(sProductKey), DELIMITER)(0)
    lDeductEndRow = Split(dictSelfSalesDeductFrom(sProductKey), DELIMITER)(1)
    
    dblAccAmt = 0
    dblBalance = dblSalesQuantity
    For lEachRow = lDeductEndRow To lDeductStartRow Step -1
        If dblBalance >= 0 Then Exit For
        
        dblSelfSellQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("SellQuantity"))
        dblHospitalQuantity = arrSelfSales(lEachRow, dictSelfSalesColIndex("HospitalSellQuantity"))
        dblPrice = arrSelfSales(lEachRow, dictSelfSalesColIndex("SellPrice"))
        
        If dblSelfSellQuantity <= dblHospitalQuantity Then fErr "这一行的日期晚，不应该出现抵扣" _
                        & vbCr & "工作表：" & shtSelfSalesCal.Name _
                        & vbCr & "行号：" & lEachRow + 1
        
        'dblCurrRowBalance = dblSelfSellQuantity - dblHospitalQuantity
        dblCurrRowBalance = dblHospitalQuantity
        dblBalance = dblBalance + dblCurrRowBalance
        
        If dblBalance < 0 Then  'still has to find next row to deduct
'            dblToDeduct = dblSelfSellQuantity
            dblToDeduct = 0
            
'            If lEachRow < lDeductEndRow Then
'                dictSelfSalesDeductFrom(sProductKey) = lEachRow + 1 & DELIMITER & lDeductEndRow
'            Else
'                dictSelfSalesDeductFrom.Remove sProductKey
'            End If
            
            dblAccAmt = dblAccAmt + dblCurrRowBalance * dblPrice
        Else
            'dblAccAmt = dblAccAmt + (dblCurrRowBalance + dblBalance) * dblPrice
            dblAccAmt = dblAccAmt + (dblCurrRowBalance - dblBalance) * dblPrice
            dblToDeduct = (dblCurrRowBalance - dblBalance) + dblHospitalQuantity
        End If
        
        arrSelfSales(lEachRow, dictSelfSalesColIndex("HospitalSellQuantity")) = dblToDeduct
    Next
    
    If dblBalance >= 0 Then
        bOut = True
        dblCostPrice = dblAccAmt / dblSalesQuantity
    End If
    
exit_fun:
    fCalculateCostPriceFromSelfSalesOrderWithdraw = bOut
End Function
Function fSetBackToshtSelfSalesCalWithDeductedData()
    If UBound(arrSelfSales, 1) > 0 Then
        shtSelfSalesCal.Range("A2").Resize(UBound(arrSelfSales, 1), UBound(arrSelfSales, 2)).Value2 = arrSelfSales
    End If
End Function
'------------------------------------------------------------------------------
Function fGetLatestPriceFromProductMaster(sProductKey As String) As Double
    If dictProductMaster Is Nothing Then Call fReadSheetProductMaster2Dictionary
    
    If Not dictProductMaster.Exists(sProductKey) Then
        fErr "药品不 存在于药品主表，前面应该已经判断过的。统一后的销售数据可能被人修改过。" & vbCr & sProductKey
    End If
    
    Dim sLatestPrice
    sLatestPrice = Split(dictProductMaster(sProductKey), DELIMITER)(1)
    
    If Len(Trim(sLatestPrice)) > 0 Then
        If Not IsNumeric(sLatestPrice) Then fErr "药品的最新单价不是数值：" & sLatestPrice
        fGetLatestPriceFromProductMaster = sLatestPrice
    Else
        fGetLatestPriceFromProductMaster = 0
    End If
End Function

Function fGetTaxRate() As Double
    If dictDefaultCommConfiged Is Nothing Then Call fReadConfigSecondLCommDefault2Dictionary
    
    fGetTaxRate = dictDefaultCommConfiged("TAX_RATE")
End Function

'====================== Salesman commssion config =================================================================
Function fReadSalesManCommissionConfig2Dictionary()
    Dim sTmpKey As String
    Dim sSalesCompany As String, sHospital As String
    Dim sProducer As String, sProductName As String, sProductSeries As String
    Dim dblSellQuantity As Double
    Dim dblHospitalQuantity As Double
    Dim dictSalesManCommTo As Dictionary
    Dim dblBidPrice As Double
    Dim lEachRow As Long

    Call fSortDataInSheetSortSheetDataByFileSpec("SALESMAN_COMMISSION_CONFIG", Array("SalesCompany", "Hospital", "ProductProducer" _
                                    , "ProductName" _
                                    , "ProductSeries" _
                                    , "BidPrice"), , shtSalesManCommConfig)
    
    Call fReadSheetDataByConfig("SALESMAN_COMMISSION_CONFIG", dictSalesManCommColIndex, arrSalesManComm, , , , , shtSalesManCommConfig)
    
    Set dictSalesManCommTo = New Dictionary
    Set dictSalesManCommFrom = New Dictionary
    For lEachRow = LBound(arrSalesManComm, 1) To UBound(arrSalesManComm, 1)
        sSalesCompany = Trim(arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesCompany")))
        sHospital = Trim(arrSalesManComm(lEachRow, dictSalesManCommColIndex("Hospital")))
        sProducer = Trim(arrSalesManComm(lEachRow, dictSalesManCommColIndex("ProductProducer")))
        sProductName = Trim(arrSalesManComm(lEachRow, dictSalesManCommColIndex("ProductName")))
        sProductSeries = Trim(arrSalesManComm(lEachRow, dictSalesManCommColIndex("ProductSeries")))
        dblBidPrice = arrSalesManComm(lEachRow, dictSalesManCommColIndex("BidPrice"))
        
        sTmpKey = sSalesCompany & DELIMITER & sHospital & DELIMITER _
                & sProducer & DELIMITER & sProductName & DELIMITER & sProductSeries & DELIMITER & dblBidPrice
        
        If Not dictSalesManCommFrom.Exists(sTmpKey) Then
            dictSalesManCommFrom.Add sTmpKey, lEachRow
        Else
            fErr "一个中标价只能有一条记录三个业务员设置！请检查业务员佣金设置表" & vbCr & sTmpKey
        End If
        dictSalesManCommTo(sTmpKey) = lEachRow
next_row:
    Next
    
    For lEachRow = 0 To dictSalesManCommFrom.Count - 1
        dictSalesManCommFrom(dictSalesManCommFrom.Keys(lEachRow)) = dictSalesManCommFrom.Items(lEachRow) _
                    & DELIMITER & dictSalesManCommTo.Items(lEachRow)
    Next
    
    Set dictSalesManCommTo = Nothing
End Function

Function fCalculateSalesManCommissionFromshtSalesManCommConfig(sSalesManKey As String _
                            , ByRef sSalesMan_1 As String, ByRef sSalesMan_2 As String, ByRef sSalesMan_3 As String _
                            , ByRef dblComm_1 As Double, ByRef dblComm_2 As Double, ByRef dblComm_3 As Double) As Boolean
    If dictSalesManCommFrom Is Nothing Then Call fReadSalesManCommissionConfig2Dictionary
    
    Dim bOut  As Boolean
    Dim lStartRow As Long
    Dim lEndRow As Long
    Dim lEachRow As Long
    'Dim iSalesManCnt As Long
    
    sSalesMan_1 = ""
    sSalesMan_2 = ""
    sSalesMan_3 = ""
    dblComm_1 = 0
    dblComm_2 = 0
    dblComm_3 = 0
    
    bOut = dictSalesManCommFrom.Exists(sSalesManKey)
    If Not bOut Then GoTo exit_fun
    
    lStartRow = Split(dictSalesManCommFrom(sSalesManKey), DELIMITER)(0)
    lEndRow = Split(dictSalesManCommFrom(sSalesManKey), DELIMITER)(1)
    
'    iSalesManCnt = 0
    For lEachRow = lStartRow To lEndRow
'        iSalesManCnt = iSalesManCnt + 1
        
'        If iSalesManCnt = 1 Then
'            sSalesMan_1 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan"))
'            dblComm_1 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission"))
'        ElseIf iSalesManCnt = 2 Then
'            sSalesMan_2 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan"))
'            dblComm_2 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission"))
'        ElseIf iSalesManCnt = 3 Then
'            sSalesMan_3 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan"))
'            dblComm_3 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission"))
'        Else
'            fErr "最多只能有3个业务员，请从【业务员佣金表】中删除一个。" & vbCr & sSalesManKey & vbCr & "行号：" & lEachRow + 1
'        End If

        sSalesMan_1 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan1"))
        dblComm_1 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission1"))
        sSalesMan_2 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan2"))
        dblComm_2 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission2"))
        sSalesMan_3 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("SalesMan3"))
        dblComm_3 = arrSalesManComm(lEachRow, dictSalesManCommColIndex("Commission3"))
    Next
    
exit_fun:
    fCalculateSalesManCommissionFromshtSalesManCommConfig = bOut
End Function
'------------------------------------------------------------------------------

Function fGetReplaceUnifyErrorRowCount() As Long
    fGetReplaceUnifyErrorRowCount = CLng(fGetSpecifiedConfigCellValue(shtSysConf, "[Facility For Testing]", "Value", "Setting Item ID=REPLACE_UNIFY_ERR_ROW_COUNT"))
End Function

Function fSetReplaceUnifyErrorRowCount(ByVal rowCnt As Long) As Long
    Call fSetSpecifiedConfigCellValue(shtSysConf, "[Facility For Testing]", "Value", "Setting Item ID=REPLACE_UNIFY_ERR_ROW_COUNT", CStr(rowCnt))
End Function

