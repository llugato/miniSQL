Strict
Import mojo

Class FileSystem Extends DataConversion
Private
  Field _header:String = "MKYDATA"
	Field fileData:String
	Field index:StringMap<FileStream>
Public
	
	Method New()
		Self.LoadAll()
	End
	
	Method WriteFile:FileStream(filename:String)
		Local f:FileStream = New FileStream
		f.filename = filename
		f.fileptr = 0
		Self.index.Set(f.filename.ToLower(),f)
		Return f	
	End
	
	Method ReadFile:FileStream(filename:String)
		filename = filename.ToLower()
		Local f:FileStream
		f = Self.index.ValueForKey(filename)
		f.fileptr = 0
		Return f
	End
	
	Method FileExists:Bool(filename:String)
		filename = filename.ToLower()
		if Self.index.Contains(filename)
			Return True
		Else
			Return False
		End
	End
	
	Method ListDir:Void()
		Local filename:String
		Local stream:FileStream
		Print "Directory Listing:"
		For filename = EachIn Self.index.Keys()
			stream = Self.index.ValueForKey(filename)
			Print filename + "   " + stream.data.Length()+" byte(s)."
		Next
	End
	
	Method DeleteFile:Void(filename:String)
		filename = filename.ToLower()
		if Self.index.Contains(filename)
			Self.index.Remove(filename)
		End
	End
    
    Method DeleteAll:Void()
        For Local filename := EachIn Self.index.Keys()
			Self.index.Remove(filename)
		Next
    End
	
	Method SaveAll:Void()
		Local f:FileStream
		Self.fileData = Self._header'header
		self.fileData+= Self.IntToString(Self.index.Count())'number of files in index
		if Self.index.Count() > 0
			For f = EachIn Self.index.Values()
				'store filename
				Self.fileData+= Self.IntToString(f.filename.Length())
				if f.filename.Length() > 0
					Self.fileData+= f.filename
				End
				'store data
				Self.fileData+= Self.IntToString(f.data.Length())
				if f.data.Length() > 0
					Self.fileData+= f.data
				End
			Next
		End
		SaveState(Self.fileData)
	End
	
	Method LoadAll:Void()
		Local numFiles:Int
		Local stream:FileStream
		Local len:Int
		Local ptr:Int
		Self.fileData = LoadState()
		self.index = New StringMap<FileStream>
		if Self.fileData.Length() > 0
			if Self.fileData.StartsWith(Self._header)
				Self.index.Clear()
				ptr+=Self._header.Length()
				numFiles = Self.StringToInt(Self.fileData,ptr)
				ptr+=CharsPerInt
				if numFiles > 0
					For Local n:Int = 1 to numFiles
						stream = New FileStream
						'filename
						len = Self.StringToInt(Self.fileData,ptr)
						ptr+=CharsPerInt
						if len > 0
							stream.filename = Self.fileData[ptr..ptr+len]
							ptr+=len
						End
						'data
						len = Self.StringToInt(Self.fileData,ptr)
						ptr+=CharsPerInt
						if len > 0
							stream.data = Self.fileData[ptr..ptr+len]
							ptr+=len
						End
						Self.index.Set(stream.filename,stream)
					Next
				End
			End
		Else
			SaveState(Self._header+Self.IntToString(0))'save empty file and indicate no files stored
		End
	End
End



Class FileStream Extends DataConversion
	Field filename:String
	Field fileptr:Int
Private
	Field data:String
Public
	
	Method ReadInt:Int()
	    Self.fileptr+=CharsPerInt
        Return StringToInt(Self.data,Self.fileptr-CharsPerInt)
	End
	
	Method WriteInt:Void(val:Int)
		Self.data+=Self.IntToString(val)
	End
	
	Method ReadString:String()
		Local result:String
		Local strLen:Int = self.StringToInt(Self.data,Self.fileptr)
		Self.fileptr+=CharsPerInt
		if strLen > 0
			result = Self.data[Self.fileptr..self.fileptr+strLen]
			Self.fileptr+=strLen
			Return result
		End
		Return result
	End
	
	Method WriteString:Void(val:String)
		Self.data+=Self.IntToString(val.Length())
		if val.Length() > 0
			Self.data+=val
		End
	End
	
	Method ReadFloat:Float()
		Local result:float
		Local strLen:Int = self.StringToInt(Self.data,Self.fileptr)
		Self.fileptr+=CharsPerInt
		
        'swap these two calls along with the DataConversion implementations
        result = Self.StringToFloat(Self.data,Self.fileptr,strLen)
        'result = Self.StringToFloat(Self.data[Self.fileptr..Self.fileptr+strLen])
		
        Self.fileptr+=strLen
		Return result
	End
	
	Method WriteFloat:Void(val:Float)
		Local s:String = self.FloatToString(val)
		Self.data+=Self.IntToString(s.Length())
		Self.data+=s
	End
End
'#rem
Class DataConversion
    Global floatChars := ["","0","1","2","3","4","5","6","7","8","9","-",".","e"] '4-bit
    Const CharsPerInt:Int = 2
    
    Method FloatToString:String(val:Float)
        Local fString:String = String(val)
        Local output:String = ""
        Local currChar:Int = 0
        Local currShift:Int = 0 
        Local i:Int = fString.Length
        
        While i > 0
            i -= 1
            Local ch := fString[i]
            If ch >47 And ch<58
                currChar |= (ch-47) Shl currShift
            ElseIf ch = 45
                currChar |= 11 Shl currShift
            ElseIf ch = 46
                currChar |= 12 Shl currShift
            ElseIf ch = 69 Or ch = 101
                currChar |= 13 Shl currShift
            End
            
            currShift += 4
            If currShift = 16
                currShift = 0
                output = String.FromChar(currChar) + output
                currChar = 0
            End
        End
        
        If currShift <> 0
            output = String.FromChar(currChar) + output
        End
        
        Return output
    End		
        
    Method StringToFloat:Float(val:String,ind:Int,len:Int)
        Local fString:String = ""
        Local i:Int = ind
        While i < ind+len 
            Local charCode := val[i]
            For Local shift:Int = 12 To 0 Step -4
                Local index:Int = (charCode Shr shift) & $F 
                If index > 0
                    fString += floatChars[index]
                End
            End
            i += 1
        End
        
        Return Float(fString)
    End
    
    Method IntToString:String(val:Int)
        Local result:String
        result = String.FromChar((val Shr 16) & $FFFF )
        result+= String.FromChar(val & $FFFF)
        Return result
    End
        
    Method StringToInt:Int(val:String,ind:Int)
        Return (val[ind] Shl 16)|val[ind+1]
    End
End
'#end
#rem

Class DataConversion
    Const CharsPerInt:Int = 4
    
    Method IntToString:String(val:Int)
		Local result:String
		result = String.FromChar((val Shr 24) & $FF)
		result+= String.FromChar((val Shr 16) & $FF)
		result+= String.FromChar((val Shr 8) & $FF)
		result+= String.FromChar(val & $FF)
		Return result
	End

	Method FloatToString:String(val:Float)
		Return String(val)
	End		
	
	Method StringToInt:Int(val:String,ind:Int)
		Local result:Int
		result = (val[ind] Shl 24)
		result|= (val[ind+1] Shl 16)
		result|= (val[ind+2] Shl 8)
		result|= val[ind+3]
		Return result
	End

	Method StringToFloat:Float(val:String)
		Return Float(val)
	End		
End
#end
