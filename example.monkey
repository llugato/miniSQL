Import mojo
Import libMiniSQL

Class Game Extends App
  Field database:miniSQL

	Method OnCreate ()
		SetUpdateRate 60
		Self.database = New miniSQL
		
		Self.database.Execute("CREATE TABLE score (name,points,time,stage)")
		Print("score created........")
		Print("==============================") 
		Self.database.Execute("SHOW TABLES")
		Print("==============================") 
		
		Self.database.Execute("INSERT INTO score (Robert,10,01:00,10)")
		Self.database.Execute("INSERT INTO score (David,20,02:00,20)")
		Self.database.Execute("INSERT INTO score (Paul,30,03:00,35)")

		Self.database.Execute("SELECT COUNT(*) FROM score")
		Print("Total of registers = "+Self.database.queryResult)
		Print("==============================") 
		Self.database.Execute("SELECT * FROM score")
		Print(Self.database.queryResult)
		Print("==============================") 
		Self.database.Execute("SELECT stage,name FROM score")
		Print(Self.database.queryResult)
		Print("============================================")
		Local scoreData:String = "Raul,10,01:00,99"+"~n"+"Josef,20,01:00,88"
		Self.database.ImportData("score",scoreData,True)
		Print("============================================")
		Self.database.Execute("SELECT * FROM score")
		Print(Self.database.queryResult)
		Print("============================================")
	End
	
	Method OnUpdate()
	End
	
	Method OnRender ()
		Cls (0,0,0)
	End Method
End

Function Main()
	New Game
End
