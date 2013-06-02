'====================================================================================================================================
' Library		: MiniSQL
' Author		: Luiz Henrique Lugato
' Created Date	: 05/31/2013
'
' Description
' With this Libary is possible to use simple SQL commands in Monkey, all data is storage in the APP Save State.  
'
' Revisions
' - v 0.1 - 05/31/2013 - Initial release
' - v 0.5 - 06/02/2013 
'
' Commands
' - create table TableName (field1,field2,fieldN)
' - insert into TableName (fieldValue1,fieldValue2,fieldValueN)
' - select 
'   select count(*) from TableName
'   select * from TableName
'   select field1,field2 from TableName
' - ShowTables
' - Display DATA From TableName
' - Desc TableName
' - Truncate Table TableName
' - ImportData(tableName,data) -> data = string with many lines with all fields values "fieldValue1,fieldValue2,fieldValue3~n"
'
'
' Usage
' Import libMiniSQL
' Field database:miniSQL
' Self.database = New miniSQL
' Self.database.Execute("CREATE TABLE score (name,points,time,stage)")
' Self.database.Execute("SHOW TABLES")
' Self.database.Execute("DISPLAY DATA FROM app_table") '--> app_table is a master table with all tables structures
' Self.database.Execute("INSERT INTO score (Robert,10,01:00,10)")
' Self.database.Execute("SELECT points,name FROM score")
' Self.database.Execute("SELECT stage,name FROM score WHERE name=David,stage<21") (the where clauseres is separated by ","
' Self.database.Execute("TRUNCATE TABLE score")
' Self.database.ImportData(tableName,data)
' Self.database.ImportData(tableName,data,True) '-> truncate and import data to the table
'
' Select Return are stored in a class propertie variable called : queryResult
' Self.database.queryResult
' 
' To Do
' - Update 
' - Delete 
' - Create index
'
'====================================================================================================================================
Import mojo
Import fileSystem

Class miniSQL
	Field HD:FileSystem
	Field fileStream:FileStream
	Field tableStructureCache:StringList
	Field stringBuffer:String
	Field stringCommand:String
	Field queryResult:String

	Method New ()
		Self.HD 					= New FileSystem
		Self.fileStream 			= New FileStream
		Self.tableStructureCache 	= New StringList
		'-- Check if save state exist -----
		Local state$ = LoadState()
		If state Then 
			Self.HD.LoadAll()
			If Not Self.HD.FileExists("app_table") Then
				Self.InitializeDatabase()
			Else
				'-- Load app_table data and recharge the structure table cache -------------
				Self.fileStream = Self.HD.ReadFile("app_table")
				Self.stringBuffer = ""
				Self.stringBuffer = Self.fileStream.ReadString()
				Local table:String[] = Self.stringBuffer.Split("~n")
				For Local x:Int = 0 To table.Length()-1
					If table[x].Length() > 1 Then
						Local vectStructure:String[] = table[x].Split("|")
						Local strFields:String = "" 
						For Local y:Int=1 To vectStructure.Length()-1
							strFields = strFields + vectStructure[y] 
							If y < vectStructure.Length()-1 Then strFields = strFields + "|"
						End
						Self.tableStructureCache.AddLast(vectStructure[0]+"|"+strFields)
					End
				End
			End
		Else
			Self.InitializeDatabase()
		End
	End

	'==================================================================================
	'== INITIALIZE DATABASE ===========================================================
	'==================================================================================
	Method InitializeDatabase()
		Self.stringBuffer = ""
		Self.fileStream = Self.HD.WriteFile("app_table")
		Self.CreateTable("app_table","structure")
		Self.HD.SaveAll()
	End
	'==================================================================================
	'== CREATE TABLE ==================================================================
	'==================================================================================
	Method CreateTable(tableName:String,fields:String)
		If tableName = "app_table" Then 
			Self.Insert("app_table",tableName+"|"+fields)
			Self.HD.SaveAll()
		End
		If Not Self.TableExist(tableName) Then 
			'--- Save table structure in system app table ----- 
			fields = fields.Replace(",","|") '+"~n"
			Self.stringBuffer = ""
			If tableName <> "app_table" Then
				'--- Crate the file to table to store data --------
				Self.fileStream = Self.HD.WriteFile(tableName)
				'--- Save table structure in system app table ----- 
				Self.Insert("app_table",tableName+"|"+fields)
				'--- Save all infomation in save state ------------
				Self.HD.SaveAll()
			End
			'--- Append table structure in table cache -------
			Self.tableStructureCache.AddLast(tableName+"|"+fields)
		End
	End
	'==================================================================================
	'== SHOW DATABASES ================================================================
	'==================================================================================
	Method ShowTables()
		Self.HD.ListDir()
	End
	'==================================================================================
	'== DESC TABLE ====================================================================
	'==================================================================================
	Method DescTable(tableName:String)
		'== Load Stored Data =================================
		Self.fileStream = Self.HD.ReadFile("app_table")
		Self.stringBuffer = ""
		Self.stringBuffer = Self.fileStream.ReadString()
		Local table:String[] = Self.stringBuffer.Split("~n")
		For Local x:Int = 0 To table.Length()-1
			If table[x].StartsWith(tableName+"|")Then
				Local vectStructure:String[] = table[x].Split("|")
				For Local x:Int = 1 To vectStructure.Length()-1
					Print(vectStructure[x])
				End
				Exit
			End			
		End
	End
	'==================================================================================
	'== TRUNCATE TABLE ================================================================
	'==================================================================================
	Method TruncateTable(tableName:String)
		Self.fileStream = Self.HD.WriteFile(tableName)
		Self.stringBuffer = ""
		Self.fileStream.WriteString(Self.stringBuffer)
		Self.HD.SaveAll()
	End
	'==================================================================================
	'== INSERT ========================================================================
	'==================================================================================
	Method Insert(tableName:String,strData:String)
		'== Load Stored Data =================================
		Self.fileStream = Self.HD.ReadFile(tableName)
		Self.stringBuffer = ""
		Self.stringBuffer = Self.fileStream.ReadString()
		'-----------------------------------------------------
		'== Store data in the final of file file =============
		Self.fileStream = Self.HD.WriteFile(tableName)
		Self.stringBuffer = Self.stringBuffer + strData + "~n"
		Self.fileStream.WriteString(Self.stringBuffer)
		'-----------------------------------------------------
		Self.HD.SaveAll()
	End
	'==================================================================================
	'== DISPLAY DATA ==================================================================
	'==================================================================================
	Method DisplayData(tableName:String)
		Print("["+tableName+"]")
		Self.fileStream = Self.HD.ReadFile(tableName)
		Self.stringBuffer = Self.fileStream.ReadString()
		Print(Self.stringBuffer)
	End
	'==================================================================================
	'== SELECT ========================================================================
	'==================================================================================
	Method _Select(tableName:String,type:Int,returnFields:String="",whereClausure:String="")
		Self.queryResult = ""
		If Not Self.TableExist(tableName) Then
			Self.queryResult = "Table "+tableName+" Not exist!!"
		Else
			'== Type list =====================
			' 1) count(*) of a table without where
			' 2) return all fields * of a table without where clausure 
			' 3) return all fields * of a table with where clausure 
			If type = 1 Then 
				Self.fileStream = Self.HD.ReadFile(tableName)
				Self.stringBuffer = Self.fileStream.ReadString()
				Local vectData:String[] = Self.stringBuffer.Split("~n")
				Self.queryResult = String(vectData.Length()-1)
			End
			If type = 2 Then 
				Self.fileStream = Self.HD.ReadFile(tableName)
				Self.stringBuffer = Self.fileStream.ReadString()
				Self.queryResult = Self.stringBuffer
			End
			If type = 3 Then 
				Self.queryResult = Self.GetFieldsContent(tableName,returnFields,whereClausure)
			End
		End
	End
	'==================================================================================
	'== EXCUTE SELECT FILTERS IN TABLE DATA ===========================================
	'==================================================================================
	Method GetFieldsContent:String(tableName:String,fields:String,whereClausure:String="")
		Local validWhere:Bool
		Local strReturn:String = ""
		Local tableStructure:String[]
		'-- Find the table and store the structure -------------------------------------
	    For Local table$=Eachin Self.tableStructureCache
	        If table.StartsWith(tableName) Then
				tableStructure = table.Split("|")
	        End
	    Next
	    '--- Create a temporary storage for load data register -------------------------
	    Local tmpRegisterStorage:String[tableStructure.Length()]
		'--- Create a vector for fields return -------------------------------------------------------------
		If Not fields.Contains(",") Then fields = fields+"," '--> compatibility for create a vect via Split
		Local vectFieldsReturn:String[]
		vectFieldsReturn = fields.Split(",")
		For Local fr:Int=0 To vectFieldsReturn.Length()-1 '-> Fields Return
			vectFieldsReturn[fr] = vectFieldsReturn[fr].Trim()
		End
		'---------------------------------------------------------------------------------------------------
		'--- Create a vector for WHERE ---------------------------------------------------------------------
		If Not whereClausure.Contains(",") Then whereClausure = whereClausure + ","
		Local vectWhere:String[]
		vectWhere = whereClausure.Split(",")
		For Local w:Int=0 To vectWhere.Length()-1 '-> Where Clausures
			vectWhere[w] = vectWhere[w].Trim()
		End
		'---------------------------------------------------------------------------------------------------
		Local returnData:String = ""
		Self.fileStream = Self.HD.ReadFile(tableName)
		Self.stringBuffer = Self.fileStream.ReadString()
		
		Local vectData:String[] = Self.stringBuffer.Split("~n")
		For Local x:Int=0 To vectData.Length()-2
			'-- create a vect with fields of register -----------------------------
			Local vectRegister:String[] = vectData[x].Split("|")
			'-- iterate return fields to check the values ------------------------- 
			For Local fr:Int=0 To vectFieldsReturn.Length()-1 '-> Fields Return
				For Local ts:Int=0 To tableStructure.Length()-1 '-> table structure
					If vectFieldsReturn[fr].Contains(tableStructure[ts]) Then
						'-- initialize variable to inform that the Where Clausure are ok to true 
						validWhere = True						
						'-- Where validation ------------------------------------------
						For Local w:Int=0 To vectWhere.Length()-1 '-> Where Clausures
							'-- Check Equal condition ----
							If vectWhere[w].Contains("=") Then
								Local vectCondition:String[]	= vectWhere[w].Split("=")
								Local fieldToCheck:String		= vectCondition[0].Trim()
								Local valueToCheck:String 		= vectCondition[1].Trim()
								Local fieldValueToCheck:String 	= ""
								'-- Get the value of field to compare -----------------------------------------
								fieldValueToCheck = vectRegister[Self.GetFieldIdByName(tableName,fieldToCheck)]
								'-- Compare values and if not equal don't store value in return of query 
								If fieldValueToCheck <> valueToCheck Then validWhere = False
							End
							'-- Check > condition ----
							If vectWhere[w].Contains(">") Then
								Local vectCondition:String[]	= vectWhere[w].Split(">")
								Local fieldToCheck:String		= vectCondition[0].Trim()
								Local valueToCheck:String 		= vectCondition[1].Trim()
								Local fieldValueToCheck:String 	= ""
								'-- Get the value of field to compare -----------------------------------------
								fieldValueToCheck = vectRegister[Self.GetFieldIdByName(tableName,fieldToCheck)]
								If Int(fieldValueToCheck) <= Int(valueToCheck) Then validWhere = False
							End
							'-- Check < condition ----
							If vectWhere[w].Contains("<") Then
								Local vectCondition:String[]	= vectWhere[w].Split("<")
								Local fieldToCheck:String		= vectCondition[0].Trim()
								Local valueToCheck:String 		= vectCondition[1].Trim()
								Local fieldValueToCheck:String 	= ""
								'-- Get the value of field to compare -----------------------------------------
								fieldValueToCheck = vectRegister[Self.GetFieldIdByName(tableName,fieldToCheck)]
								If Int(fieldValueToCheck) >= Int(valueToCheck) Then validWhere = False
							End
						End
						'--------------------------------------------------------------
						'-- Append return string with value of filed --------
						If validWhere Then
							strReturn = strReturn + vectRegister[ts-1] + "|"
							Exit
						End
					End
				End
			End
			'-- Break the line of register and get next data ----------------
			If validWhere Then strReturn = strReturn + "~n"
		End
		'-- delete the last "|" in all lines --------------------------------
		strReturn = strReturn.Replace( "|~n", "~n" )
		'-- Adjust return sring --------------------
		Local vectReturn:String[] = strReturn.Split("~n")
		strReturn = ""
		For Local x:Int=0 To vectReturn.Length()-1
			If vectReturn[x].Length() > 2 Then 
				strReturn = strReturn + vectReturn[x]
				If x < vectReturn.Length()-2 strReturn = strReturn + "~n"
			End
		End
		'-------------------------------------------
		Return strReturn
	End
	'==================================================================================
	'== ANALYSE COMMANDS INPUTED BY EXECUTE ===========================================
	'==================================================================================
	Method Execute(str:String)
		Self.stringCommand = str
		If str.StartsWith("CREATE TABLE") 	Then 
			Self.stringCommand = Self.stringCommand.Replace("CREATE TABLE ","")
			Self.ParseCommand("CREATE")
		End
		If str.StartsWith("DESC ")	Then
			Self.stringCommand = Self.stringCommand.Replace("DESC ","")
			Self.ParseCommand("DESC")
		End
		If str.StartsWith("DISPLAY DATA FROM")	Then
			Self.stringCommand = Self.stringCommand.Replace("DISPLAY DATA FROM ","")
			Self.ParseCommand("DISPLAY")
		End
		If str.StartsWith("SHOW TABLES")	Then
			Self.stringCommand = Self.stringCommand.Replace("SHOW TABLES ","")
			Self.ParseCommand("SHOW")
		End
		If str.StartsWith("INSERT INTO") 		Then 
			Self.stringCommand = Self.stringCommand.Replace("INSERT INTO ","")
			Self.ParseCommand("INSERT")
		End
		If str.StartsWith("SELECT") 		Then 
			Self.stringCommand = Self.stringCommand.Replace("SELECT ","")
			Self.ParseCommand("SELECT")
		End
		If str.StartsWith("TRUNCATE TABLE") Then 
			Self.stringCommand = Self.stringCommand.Replace("TRUNCATE TABLE ","")
			Self.ParseCommand("TRUNCATE")
		End
		If str.StartsWith("UPDATE") Then Self.ParseCommand("UPDATE")
		If str.StartsWith("COMMIT") Then Self.ParseCommand("COMMIT")
	End
	'==================================================================================
	'== EXECUTE COMMANDS ==============================================================
	'==================================================================================
	Method ParseCommand(command:String)
		'Print(Self.stringCommand)
		Self.AdjustCommandString()
		'Print(Self.stringCommand)
		If command = "CREATE" Then
			'create table fruta (nome,pontos,dificuldade,resolvido)'
			Local tableName:String
			Local fields:String
			'-------------------------------------------------------
			Local vectString:String[] = Self.stringCommand.Split("(")
			Self.stringCommand = Self.stringCommand.Replace(vectString[0]+"(","")
			Self.stringCommand = Self.stringCommand.Replace("(","")
			Self.stringCommand = Self.stringCommand.Replace(")","")
			'-------------------------------------------------------
			tableName 		= vectString[0]
			fields			= Self.stringCommand
			Self.CreateTable(tableName,fields)
		End
		If command = "SHOW" Then
			Self.ShowTables()
		End
		If command = "DISPLAY" Then
			Local tableName:String
			tableName = Self.stringCommand
			Self.DisplayData(tableName)
		End
		If command = "DESC" Then
			Local tableName:String
			tableName = Self.stringCommand
			Self.DescTable(tableName)
		End
		If command = "TRUNCATE" Then
			Local tableName:String
			tableName = Self.stringCommand
			Self.TruncateTable(tableName)
		End
		If command = "INSERT" Then
			Local tableName:String
			Local strRegisterData:String
			'-------------------------------------------------------
			Local vectString:String[] = Self.stringCommand.Split("(")
			Self.stringCommand = Self.stringCommand.Replace(vectString[0]+"(","")
			Self.stringCommand = Self.stringCommand.Replace("(","")
			Self.stringCommand = Self.stringCommand.Replace(")","")
			Self.stringCommand = Self.stringCommand.Replace(",","|")
			'-------------------------------------------------------
			tableName 	= vectString[0]
			strRegisterData	= Self.stringCommand
			Self.Insert(tableName,strRegisterData)
		End
		If command = "SELECT" Then
			Local tableName:String
			Local returnFields:String
			Local whereClausure:String
			'==============
			'== COUNT =====
			'==============
			If Self.stringCommand.StartsWith("COUNT(*)") Then 
				tableName = ""
				Self.stringCommand = Self.stringCommand.Replace("COUNT(*) FROM ","")
				tableName = Self.stringCommand
				Self._Select(tableName,1)
			'===================================
			'== GET ALL RECORDS OF A TABLE =====
			'===================================
			Else If Self.stringCommand.StartsWith("* FROM") Then 
				tableName = ""
				Self.stringCommand = Self.stringCommand.Replace("* FROM ","")
				tableName = Self.stringCommand
				Self._Select(tableName,2)
			Else If Not Self.stringCommand.StartsWith("* FROM") And Not Self.stringCommand.StartsWith("COUNT(*)") Then
				tableName 		= ""
				returnFields 	= ""
				whereClausure	= "" 
				Local vetcSelect:String[] = Self.stringCommand.Split("FROM")
				returnFields = vetcSelect[0].Trim()
				If vetcSelect[1].Contains("WHERE") Then
					Local filterWhere:String[] = vetcSelect[1].Split("WHERE")
					tableName 		= filterWhere[0].Trim()
				    whereClausure	= filterWhere[1].Trim()
				Else
					tableName = vetcSelect[1].Trim()
				End
				Self._Select(tableName,3,returnFields,whereClausure)
			End
		End

	End
	'==================================================================================
	'== CLEAR COMMANDS FOR COMPATIBILITY FILTERS ======================================
	'==================================================================================
	Method AdjustCommandString()
		'-- adjust string command to parse -----------------------------
		Self.stringCommand = Self.stringCommand.Trim()

		Self.stringCommand = Self.stringCommand.Replace("   ("		,"(")
		Self.stringCommand = Self.stringCommand.Replace("  ("		,"(")
		Self.stringCommand = Self.stringCommand.Replace(" ("		,"(")

		Self.stringCommand = Self.stringCommand.Replace("   ,"		,",")
		Self.stringCommand = Self.stringCommand.Replace("  ,"		,",")
		Self.stringCommand = Self.stringCommand.Replace(" ,"		,",")

		Self.stringCommand = Self.stringCommand.Replace(",   "		,",")
		Self.stringCommand = Self.stringCommand.Replace(",  "		,",")
		Self.stringCommand = Self.stringCommand.Replace(", "		,",")

		Self.stringCommand = Self.stringCommand.Replace("   )"		,")")
		Self.stringCommand = Self.stringCommand.Replace("  )"		,")")
		Self.stringCommand = Self.stringCommand.Replace(" )"		,")")
	End
	'==================================================================================
	'== IMPORT DATA STRUCTURED TO A TABLE =============================================
	'==================================================================================
	Method ImportData(tableName:String,tableData:String,truncate:Bool=False)
		If Self.TableExist(tableName) Then
			tableData = tableData.Replace(",","|")
			'== Load Stored Data =================================
			Self.stringBuffer = ""
			If Not truncate Then 
				Self.fileStream = Self.HD.ReadFile(tableName)
				Self.stringBuffer = ""
				Self.stringBuffer = Self.fileStream.ReadString()
			End
			'-----------------------------------------------------
			Self.fileStream = Self.HD.WriteFile(tableName)
			'-- break data in lines and insert in the table -----------
			Local vectData:String[] = tableData.Split("~n")
			For Local x:Int=0 To vectData.Length()-1
				Self.stringBuffer = Self.stringBuffer + tableData + "~n"
				Self.fileStream.WriteString(Self.stringBuffer)
			End
			'-----------------------------------------------------
			Self.HD.SaveAll()
		End
	End 
	'==================================================================================
	'== VERIFY IF TABLE EXIST IN FILE SYSTEM ==========================================
	'==================================================================================
	Method TableExist:Bool(tableName:String)
		If Self.HD.FileExists(tableName)
			Return True
		Else
			Return False
		End
	End
	'==================================================================================
	'== VERIFY IF TABLE EXIST IN TABLE CACHE STRUCTURE ================================
	'==================================================================================
	Method TableExistInCache:Bool(tableName:String)
	    Local ret:Bool = False
	    For Local table$=Eachin Self.tableStructureCache
	        If table.StartsWith(tableName) Then
				ret = True
				Exit
	        End
	    Next
	    Return ret
	End
	'==================================================================================
	'== GET THE ID OF A FIELD IN TABLE STRUCTURE BY NAME  =============================
	'==================================================================================
	Method GetFieldIdByName:Int(tableName:String,fieldName:String)
	    Local ret:Int = -1
	    For Local table$=Eachin Self.tableStructureCache
	        If table.StartsWith(tableName) Then
				Local tableStructure:String[]
				tableStructure = table.Split("|")
				For Local x:Int=0 To tableStructure.Length()-1
					If tableStructure[x].Contains(fieldName) Then
						ret = x-1
						Exit
					End
				End
	        End
	    Next
	    '-- break with error if filed is invalid --------------------
	    Return ret
	End
	'==================================================================================
	'== SHOW TABLE CACHE DATA =========================================================
	'==================================================================================
	Method ShowTableCache()
	    For Local t$=Eachin tableStructureCache
	        Print t
	    Next	
	End

End
