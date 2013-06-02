miniSQL
=======

Author : Luiz Henrique Lugato

Description
-----------
With this Libary is possible to use simple SQL commands in Monkey, all data is stored in text format in the APP Save State.  

Targets: all Monkey targets

Revisions
v 0.1 - Initial release (instable version .. test only) - 05/31/2013
v 0.5 - 06/02/2013


Commands examples
=================
CREATE TABLE TableName (field1,field2,fieldN)

INSERT INTO TableName (fieldValue1,fieldValue2,fieldValueN)

SELECT 

 SELECT COUNT(*) FROM TableName
 
 SELECT * FROM TableName
 
 SELECT field1,field2 FROM TableName

 ShowTables

 Display DATA FROM TableName
 
 DESC TableName
 
 TRUNCATE TABLE TableName
 
 ImportData(tableName,data,BOOL) 
 
 -> data = string with many lines with all fields values "fieldValue1,fieldValue2,fieldValue3~n"
 
 -> BOOL:
 
 if true do a auto truncate in table data and append the data content in the table
 
 if false or ommited, load table informations and append data content 
           

Usage
=====
Import libMiniSQL

Field database:miniSQL

Self.database = New miniSQL

Self.database.Execute("CREATE TABLE score (name,points,time,stage)")

Self.database.Execute("SHOW TABLES")

Self.database.Execute("DISPLAY DATA FROM app_tables") '--> app_tables is a master table with all tables structures

Self.database.Execute("SELECT stage,name FROM score WHERE name=David,stage<21") 

- The where clauseres need to be separated by ","

Self.database.Execute("INSERT INTO score (Robert,10,01:00,10)")

Self.database.Execute("SELECT points,name FROM score")

Self.database.Execute("TRUNCATE TABLE score")

Self.database.ImportData(tableName,data)

Self.database.ImportData(tableName,data,True) '-> truncate and import data to the table


OBS: The return of a Select command is stored in the class property variable : queryResult

Self.database.queryResult 


To Do
-----
- Update 
- Delete 
- Create index


Thanks
------
Thanks for GfK that created the fileSystem.monkey :) and all Monkey forum users !!!! 
http://monkeycoder.co.nz/Community/posts.php?topic=1395#12689
