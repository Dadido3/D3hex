; ##################################################### License / Copyright #########################################
; 
;     D3NBT
;     Copyright (C) 2012-2014  David Vogel
; 
;     This library is free software; you can redistribute it and/or
;     modify it under the terms of the GNU Lesser General Public
;     License As published by the Free Software Foundation; either
;     version 2.1 of the License, Or (at your option) any later version.
; 
;     This library is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY Or FITNESS For A PARTICULAR PURPOSE.  See the GNU
;     Lesser General Public License For more details.
; 
;     You should have received a copy of the GNU Lesser General Public
;     License along With this library; if not, write to the Free Software
;     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
;     USA
;
; #################################################### Documentation #############################################

; Named Binary Tags - Include
; 
; V1.000 (27.07.2012)
;   - Everything is done, hopefully
; 
; V1.100 (28.07.2012)
;   - Better ZLib implementation in NBT_Read_Ram()
;   - Added Compression-Types
; 
; V1.110 (10.02.2014)
;   - Made it possible to write an empty array with NBT_Tag_Set_Array(*Tag.NBT_Tag, *Data_, 0)
;   - Changed the parameter "GZip" to "Compression" in NBT_Write_File
; 
; V1.111 (22.02.2014)
;   - Add child elements to the end of lists or compounds
; 
; V1.112 (24.02.2014)
;   - Added NBT_Error_Available()

; #################################################### Initstuff #################################################

; #################################################### Includes ##################################################

XIncludeFile "ZLib.pbi"

; #################################################### Constants #################################################

Enumeration
  #NBT_Tag_End
  #NBT_Tag_Byte
  #NBT_Tag_Word
  #NBT_Tag_Long
  #NBT_Tag_Quad
  #NBT_Tag_Float
  #NBT_Tag_Double
  #NBT_Tag_Byte_Array
  #NBT_Tag_String
  #NBT_Tag_List
  #NBT_Tag_Compound
  #NBT_Tag_Long_Array
EndEnumeration

#NBT_Buffer_Step_Size = 1024

Enumeration
  #NBT_Compression_None
  #NBT_Compression_Detect
  #NBT_Compression_GZip
  #NBT_Compression_ZLib
EndEnumeration

; #################################################### Structures ################################################

Structure NBT_Eight_Bytes
  A.a
  B.a
  C.a
  D.a
  E.a
  F.a
  G.a
  H.a
EndStructure

Structure NBT_Eight_Bytes_Ext
  StructureUnion
    Bytes.NBT_Eight_Bytes
    Ascii.a
    Byte.b
    
    Unicode.u
    Word.w
    
    Char.c
    
    Integer.i
    Long.l
    Quad.q
    
    Float.f
    Double.d
  EndStructureUnion
EndStructure

Structure NBT_Tag
  *Parent.NBT_Tag
  *NBT_Element.NBT_Element
  
  Type.a
  Name.s
  
  ; #### Payload
  Byte.b
  Word.w
  Long.l
  Quad.q
  Float.f
  Double.d
  List Child.NBT_Tag()
  String.s
  List_Type.a
  List_Size.l ; Only a temporary variable, it't DOESN'T represent the list-size!
  
  *Raw
  Raw_Size.l ; In elements
EndStructure

Structure NBT_Element
  Reserved.l
  
  NBT_Tag.NBT_Tag
EndStructure

Structure NBT_Main
  Error_String.s
EndStructure

; #################################################### Variables #################################################

Global NBT_Main.NBT_Main

Global NewList NBT_Element.NBT_Element()

NBT_Main\Error_String = ""

; #################################################### Declares ##################################################

; #################################################### Macros ####################################################

; #################################################### Procedures ################################################

Procedure NBT_Error_Available()
  If NBT_Main\Error_String <> ""
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure.s NBT_Error_Get()
  Protected Error.s = NBT_Main\Error_String
  NBT_Main\Error_String = ""
  ProcedureReturn Error
EndProcedure

Procedure NBT_Tag_Add(*Parent_Tag.NBT_Tag, Name.s, Type, List_Type=0)
  If Not *Parent_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
    ProcedureReturn #Null
  EndIf
  
  If *Parent_Tag\Type <> #NBT_Tag_List And *Parent_Tag\Type <> #NBT_Tag_Compound
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type = "+Str(*Parent_Tag\Type)+" can't contain tag's>"
    ProcedureReturn #Null
  EndIf
  
  If *Parent_Tag\Type = #NBT_Tag_List And Type <> *Parent_Tag\List_Type
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Type = "+Str(Type)+" != "+Str(*Parent_Tag\List_Type)+" = *Parent_Tag\List_Type>"
    ProcedureReturn #Null
  EndIf
  
  Select Type
    Case #NBT_Tag_Byte
    Case #NBT_Tag_Word
    Case #NBT_Tag_Long
    Case #NBT_Tag_Quad
    Case #NBT_Tag_Float
    Case #NBT_Tag_Double
    Case #NBT_Tag_Byte_Array
    Case #NBT_Tag_String
    Case #NBT_Tag_List
    Case #NBT_Tag_Compound
    Case #NBT_Tag_Long_Array
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Type = "+Str(Type)+" is invalid>"
      ProcedureReturn #Null
  EndSelect
  
  If *Parent_Tag\Type = #NBT_Tag_Compound
    ForEach *Parent_Tag\Child()
      If *Parent_Tag\Child()\Name = Name
        DeleteElement(*Parent_Tag\Child())
      EndIf
    Next
  Else
    Name = ""
  EndIf
  
  LastElement(*Parent_Tag\Child())
  If Not AddElement(*Parent_Tag\Child())
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
    ProcedureReturn #Null
  EndIf
  
  *Parent_Tag\Child()\Name = Name
  *Parent_Tag\Child()\Type = Type
  *Parent_Tag\Child()\Parent = *Parent_Tag
  *Parent_Tag\Child()\List_Type = List_Type
  
  ProcedureReturn *Parent_Tag\Child()
EndProcedure

Procedure NBT_Tag(*Parent_Tag.NBT_Tag, Name.s)
  If Not *Parent_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
    ProcedureReturn #Null
  EndIf
  
  Select *Parent_Tag\Type
    Case #NBT_Tag_Compound
      ForEach *Parent_Tag\Child()
        If *Parent_Tag\Child()\Name = Name
          ProcedureReturn *Parent_Tag\Child()
        EndIf
      Next
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type is incompatible>"
      ProcedureReturn #Null
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Child()\Name = '"+Name+"' Not found>"
  ProcedureReturn #Null
EndProcedure

Procedure NBT_Tag_Index(*Parent_Tag.NBT_Tag, Index)
  If Not *Parent_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
    ProcedureReturn #Null
  EndIf
  
  Select *Parent_Tag\Type
    Case #NBT_Tag_Compound
      If Index >= 0 And Index < ListSize(*Parent_Tag\Child())
        SelectElement(*Parent_Tag\Child(), Index)
        ProcedureReturn *Parent_Tag\Child()
      EndIf
    Case #NBT_Tag_List
      If Index >= 0 And Index < ListSize(*Parent_Tag\Child())
        SelectElement(*Parent_Tag\Child(), Index)
        ProcedureReturn *Parent_Tag\Child()
      EndIf
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type is incompatible>"
      ProcedureReturn #Null
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Index is out of *Parent_Tag\Child()>"
  ProcedureReturn #Null
EndProcedure

Procedure NBT_Tag_Count(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Byte_Array : ProcedureReturn *Tag\Raw_Size
    Case #NBT_Tag_Long_Array : ProcedureReturn *Tag\Raw_Size
    Case #NBT_Tag_Compound   : ProcedureReturn ListSize(*Tag\Child())
    Case #NBT_Tag_List       : ProcedureReturn ListSize(*Tag\Child())
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
  ProcedureReturn 0
EndProcedure

Procedure NBT_Tag_Set_Name(*Tag.NBT_Tag, Name.s)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  If *Tag\Parent And *Tag\Parent\Type = #NBT_Tag_List
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag can't have a name>"
    ProcedureReturn #False
  EndIf
  
  *Tag\Name = Name
  
  ProcedureReturn #True
EndProcedure

Procedure.s NBT_Tag_Get_Name(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn ""
  EndIf
  
  ProcedureReturn *Tag\Name
EndProcedure

Procedure NBT_Tag_Set_Number(*Tag.NBT_Tag, Value.q)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Byte : *Tag\Byte = Value
    Case #NBT_Tag_Word : *Tag\Word = Value
    Case #NBT_Tag_Long : *Tag\Long = Value
    Case #NBT_Tag_Quad : *Tag\Quad = Value
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure.q NBT_Tag_Get_Number(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Byte : ProcedureReturn *Tag\Byte
    Case #NBT_Tag_Word : ProcedureReturn *Tag\Word
    Case #NBT_Tag_Long : ProcedureReturn *Tag\Long
    Case #NBT_Tag_Quad : ProcedureReturn *Tag\Quad
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
  ProcedureReturn 0
EndProcedure

Procedure NBT_Tag_Set_Float(*Tag.NBT_Tag, Value.f)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Float : *Tag\Float = Value
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure.f NBT_Tag_Get_Float(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Float : ProcedureReturn *Tag\Float
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
  ProcedureReturn 0
EndProcedure

Procedure NBT_Tag_Set_Double(*Tag.NBT_Tag, Value.d)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Double : *Tag\Double = Value
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure.d NBT_Tag_Get_Double(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Double : ProcedureReturn *Tag\Double
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
  ProcedureReturn 0
EndProcedure

Procedure NBT_Tag_Set_String(*Tag.NBT_Tag, Value.s)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_String : *Tag\String = Value
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure.s NBT_Tag_Get_String(*Tag.NBT_Tag)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn ""
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_String : ProcedureReturn *Tag\String
  EndSelect
  
  NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
  ProcedureReturn ""
EndProcedure

Procedure NBT_Tag_Set_Array(*Tag.NBT_Tag, *Data_, Data_Size)
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Byte_Array
      If *Tag\Raw
        FreeMemory(*Tag\Raw) : *Tag\Raw = #Null : *Tag\Raw_Size = 0
      EndIf
      If *Data_ And Data_Size > 0
        *Tag\Raw_Size = Data_Size
        *Tag\Raw = AllocateMemory(*Tag\Raw_Size)
        If Not *Tag\Raw
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(*Tag\Raw_Size)+") failed>"
          ProcedureReturn #False
        EndIf
        CopyMemory(*Data_, *Tag\Raw, *Tag\Raw_Size)
      EndIf
    Case #NBT_Tag_Long_Array
      If *Tag\Raw
        FreeMemory(*Tag\Raw) : *Tag\Raw = #Null : *Tag\Raw_Size = 0
      EndIf
      If *Data_ And Data_Size > 0
        *Tag\Raw_Size = Data_Size / 4
        *Tag\Raw = AllocateMemory(*Tag\Raw_Size * 4)
        If Not *Tag\Raw
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(*Tag\Raw_Size * 4)+") failed>"
          ProcedureReturn #False
        EndIf
        CopyMemory(*Data_, *Tag\Raw, *Tag\Raw_Size * 4)
      EndIf
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure NBT_Tag_Get_Array(*Tag.NBT_Tag, *Pointer, Data_Size)
  Protected Max_Data_Size
  
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_Byte_Array
      If *Tag\Raw
        Max_Data_Size = *Tag\Raw_Size
        If Max_Data_Size > Data_Size : Max_Data_Size = Data_Size : EndIf
        If Max_Data_Size > 0
          CopyMemory(*Tag\Raw, *Pointer, Max_Data_Size)
        EndIf
        If Data_Size-Max_Data_Size > 0
          FillMemory(*Pointer+Max_Data_Size, Data_Size-Max_Data_Size)
        EndIf
      Else
        FillMemory(*Pointer, Data_Size)
      EndIf
    Case #NBT_Tag_Long_Array
      If *Tag\Raw
        Max_Data_Size = *Tag\Raw_Size * 4
        If Max_Data_Size > Data_Size : Max_Data_Size = Data_Size : EndIf
        If Max_Data_Size > 0
          CopyMemory(*Tag\Raw, *Pointer, Max_Data_Size)
        EndIf
        If Data_Size-Max_Data_Size > 0
          FillMemory(*Pointer+Max_Data_Size, Data_Size-Max_Data_Size)
        EndIf
      Else
        FillMemory(*Pointer, Data_Size)
      EndIf
    Default
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
      ProcedureReturn #False
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure NBT_Tag_Delete(*NBT_Tag.NBT_Tag)
  If Not *NBT_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Tag is #Null>"
    ProcedureReturn #False
  EndIf
  
  If *NBT_Tag\Raw
    FreeMemory(*NBT_Tag\Raw)
    *NBT_Tag\Raw = #Null
  EndIf
  
  While FirstElement(*NBT_Tag\Child())
    NBT_Tag_Delete(*NBT_Tag\Child())
  Wend
  
  If *NBT_Tag\Parent
    If ChangeCurrentElement(*NBT_Tag\Parent\Child(), *NBT_Tag)
      DeleteElement(*NBT_Tag\Parent\Child())
    EndIf
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure NBT_Element_Add()
  
  If Not AddElement(NBT_Element())
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(NBT_Element()) failed>"
    ProcedureReturn #Null
  EndIf
  
  NBT_Element()\NBT_Tag\Type = #NBT_Tag_Compound
  
  ProcedureReturn NBT_Element()
EndProcedure

Procedure NBT_Element_Delete(*NBT_Element.NBT_Element)
  If Not *NBT_Element
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Element is #Null>"
    ProcedureReturn #False
  EndIf
  
  NBT_Tag_Delete(*NBT_Element\NBT_Tag)
  
  ChangeCurrentElement(NBT_Element(), *NBT_Element)
  DeleteElement(NBT_Element())
  
  ProcedureReturn #True
EndProcedure

Procedure NBT_Get_Ram_Size_Helper(*NBT_Tag.NBT_Tag)
  Protected Size
  
  If Not *NBT_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  If *NBT_Tag\Parent And *NBT_Tag\Parent\Type = #NBT_Tag_List
    ; #### List-Elements only have a payload
  Else
    Size + 3 + StringByteLength(*NBT_Tag\Name, #PB_UTF8)
  EndIf
  ; #### Get Payload-Size
  Select *NBT_Tag\Type
    Case #NBT_Tag_Byte          : Size + 1
    Case #NBT_Tag_Word          : Size + 2
    Case #NBT_Tag_Long          : Size + 4
    Case #NBT_Tag_Quad          : Size + 8
    Case #NBT_Tag_Float         : Size + 4
    Case #NBT_Tag_Double        : Size + 8
    Case #NBT_Tag_Byte_Array    : Size + 4 + *NBT_Tag\Raw_Size
    Case #NBT_Tag_String        : Size + 2 + StringByteLength(*NBT_Tag\String, #PB_UTF8)
    Case #NBT_Tag_List
      Size + 5 ; Type, List-Size
      ForEach *NBT_Tag\Child()
        Size + NBT_Get_Ram_Size_Helper(*NBT_Tag\Child())
      Next
    Case #NBT_Tag_Compound
      ForEach *NBT_Tag\Child()
        Size + NBT_Get_Ram_Size_Helper(*NBT_Tag\Child())
      Next
      Size + 1 ; Tag_End
    Case #NBT_Tag_Long_Array    : Size + 4 + *NBT_Tag\Raw_Size * 4
  EndSelect
  
  ProcedureReturn Size
EndProcedure

Procedure NBT_Get_Ram_Size(*NBT_Element.NBT_Element)
  If Not *NBT_Element
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Element is #Null>"
    ProcedureReturn 0
  EndIf
  
  If Not *NBT_Element\NBT_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Element\NBT_Tag is #Null>"
    ProcedureReturn 0
  EndIf
  
  ProcedureReturn NBT_Get_Ram_Size_Helper(*NBT_Element\NBT_Tag)
EndProcedure

Procedure NBT_Read_Ram(*Memory, Memory_Size, Compression=#NBT_Compression_Detect)
  Protected *Buffer, Buffer_Size, Stream.z_stream, Temp_Result
  Protected *Position.NBT_Eight_Bytes, Read_Bytes, Temp_Length
  Protected *Parent_Tag.NBT_Tag
  Protected *Current_Tag.NBT_Tag
  Protected Temp_Value.NBT_Eight_Bytes_Ext
  Protected *Temp_Pointer.NBT_Eight_Bytes_Ext
  Protected Tag_Type
  Protected i
  
  If Not *Memory
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Memory is #Null>"
    ProcedureReturn #Null
  EndIf
  
  *Position = *Memory
  
  If Compression = #NBT_Compression_GZip Or Compression = #NBT_Compression_ZLib Or (Compression = #NBT_Compression_Detect And *Position\A = $1F And *Position\B = $8B)
    Buffer_Size = #NBT_Buffer_Step_Size
    *Buffer = AllocateMemory(Buffer_Size)
    
    If Not *Buffer
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Buffer is #Null>"
      ProcedureReturn #Null
    EndIf
    
    Stream\avail_in = Memory_Size
    Stream\avail_out = Buffer_Size
    Stream\next_in = *Memory
    Stream\next_out = *Buffer
    
    If Not inflateInit2_(Stream, 15+32, zlibVersion(), SizeOf(z_stream)) = #Z_OK
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": inflateInit2_(Stream, 15+16, zlibVersion(), SizeOf(z_stream)) != #Z_OK>"
      If *Buffer : FreeMemory(*Buffer) : EndIf
      ProcedureReturn #Null
    EndIf
    
    Repeat
      Temp_Result = inflate(Stream, #Z_NO_FLUSH)
      If Temp_Result <> #Z_OK And Temp_Result <> #Z_STREAM_END
        NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": inflate(Stream, #Z_FINISH) failed>"
        If *Buffer : FreeMemory(*Buffer) : EndIf
        inflateEnd(Stream)
        ProcedureReturn #Null
      EndIf
      If Temp_Result = #Z_OK
        Buffer_Size + #NBT_Buffer_Step_Size
        *Buffer = ReAllocateMemory(*Buffer, Buffer_Size)
        If Not *Buffer
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Buffer is #Null>"
          ; #### In this case there is the previous *Buffer left in memory (Causes a mem-leak, but that only happens if the memory is full)
          inflateEnd(Stream)
          ProcedureReturn #Null
        EndIf
        Stream\avail_out = #NBT_Buffer_Step_Size
        Stream\next_out = *Buffer + Buffer_Size - #NBT_Buffer_Step_Size
      EndIf
    Until Temp_Result = #Z_STREAM_END
    Buffer_Size = Stream\total_out
    inflateEnd(Stream)
    
    *Position = *Buffer
    Memory_Size = Buffer_Size
  EndIf
  
  If Not AddElement(NBT_Element())
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(NBT_Element()) failed>"
    If *Buffer : FreeMemory(*Buffer) : EndIf
    ProcedureReturn #Null
  EndIf
  
  *Parent_Tag = #Null
  
  While Read_Bytes < Memory_Size
    
    If *Parent_Tag And *Parent_Tag\Type = #NBT_Tag_List And ListSize(*Parent_Tag\Child()) >= *Parent_Tag\List_Size
      If *Parent_Tag\Parent
        *Parent_Tag = *Parent_Tag\Parent
      Else
        NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Parent not existant>"
        NBT_Element_Delete(NBT_Element())
        If *Buffer : FreeMemory(*Buffer) : EndIf
        ProcedureReturn #Null
      EndIf
    EndIf
    
    If *Parent_Tag And *Parent_Tag\Type = #NBT_Tag_List
      Tag_Type = *Parent_Tag\List_Type
      Select Tag_Type
        Case #NBT_Tag_Byte, #NBT_Tag_Word, #NBT_Tag_Long, #NBT_Tag_Quad, #NBT_Tag_Float, #NBT_Tag_Double, #NBT_Tag_Byte_Array, #NBT_Tag_String, #NBT_Tag_List, #NBT_Tag_Compound, #NBT_Tag_Long_Array
          If Not AddElement(*Parent_Tag\Child())
            NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
            NBT_Element_Delete(NBT_Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
          EndIf
          *Current_Tag = *Parent_Tag\Child()
          *Current_Tag\Type = Tag_Type
          *Current_Tag\Name = ""
          *Current_Tag\Parent = *Parent_Tag
          *Current_Tag\NBT_Element = NBT_Element()
        Default
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unkown: *Parent_Tag\List_Type = "+Str(Tag_Type)+">"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
      EndSelect
    Else
      Tag_Type = PeekA(*Position)
      Select Tag_Type
        Case #NBT_Tag_End
          *Position + 1 : Read_Bytes + 1
          If *Parent_Tag = #Null
            ; #### Root element, it's done!
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn NBT_Element()
          EndIf
          *Parent_Tag = *Parent_Tag\Parent
        Case #NBT_Tag_Byte, #NBT_Tag_Word, #NBT_Tag_Long, #NBT_Tag_Quad, #NBT_Tag_Float, #NBT_Tag_Double, #NBT_Tag_Byte_Array, #NBT_Tag_String, #NBT_Tag_List, #NBT_Tag_Compound, #NBT_Tag_Long_Array
          *Position + 1 : Read_Bytes + 1
          If *Parent_Tag
            If Not AddElement(*Parent_Tag\Child())
              NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
              NBT_Element_Delete(NBT_Element())
              If *Buffer : FreeMemory(*Buffer) : EndIf
              ProcedureReturn #Null
            EndIf
            *Current_Tag = *Parent_Tag\Child()
          Else
            *Current_Tag = NBT_Element()\NBT_Tag
          EndIf
          Temp_Length = *Position\A<<8 + *Position\B : *Position + 2 : Read_Bytes + 2
          *Current_Tag\Type = Tag_Type
          *Current_Tag\Name = PeekS(*Position, Temp_Length, #PB_UTF8) : *Position + Temp_Length : Read_Bytes + Temp_Length
          *Current_Tag\Parent = *Parent_Tag
          *Current_Tag\NBT_Element = NBT_Element()
        Default
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unkown: Tag_Type = PeekA(*Position) = "+Str(Tag_Type)+">"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
      EndSelect
    EndIf
    
    ; #### Read the payload
    Select Tag_Type
      Case #NBT_Tag_Byte
        *Current_Tag\Byte = *Position\A : *Position + 1 : Read_Bytes + 1
      Case #NBT_Tag_Word
        Temp_Value\Bytes\A = *Position\B
        Temp_Value\Bytes\B = *Position\A
        *Current_Tag\Word = Temp_Value\Word : *Position + 2 : Read_Bytes + 2
      Case #NBT_Tag_Long
        Temp_Value\Bytes\A = *Position\D
        Temp_Value\Bytes\B = *Position\C
        Temp_Value\Bytes\C = *Position\B
        Temp_Value\Bytes\D = *Position\A
        *Current_Tag\Long = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
      Case #NBT_Tag_Quad
        Temp_Value\Bytes\A = *Position\H
        Temp_Value\Bytes\B = *Position\G
        Temp_Value\Bytes\C = *Position\F
        Temp_Value\Bytes\D = *Position\E
        Temp_Value\Bytes\E = *Position\D
        Temp_Value\Bytes\F = *Position\C
        Temp_Value\Bytes\G = *Position\B
        Temp_Value\Bytes\H = *Position\A
        *Current_Tag\Quad = Temp_Value\Quad : *Position + 8 : Read_Bytes + 8
      Case #NBT_Tag_Float
        Temp_Value\Bytes\A = *Position\D
        Temp_Value\Bytes\B = *Position\C
        Temp_Value\Bytes\C = *Position\B
        Temp_Value\Bytes\D = *Position\A
        *Current_Tag\Float = Temp_Value\Float : *Position + 4 : Read_Bytes + 4
      Case #NBT_Tag_Double
        Temp_Value\Bytes\A = *Position\H
        Temp_Value\Bytes\B = *Position\G
        Temp_Value\Bytes\C = *Position\F
        Temp_Value\Bytes\D = *Position\E
        Temp_Value\Bytes\E = *Position\D
        Temp_Value\Bytes\F = *Position\C
        Temp_Value\Bytes\G = *Position\B
        Temp_Value\Bytes\H = *Position\A
        *Current_Tag\Double = Temp_Value\Double : *Position + 8 : Read_Bytes + 8
      Case #NBT_Tag_Byte_Array
        Temp_Value\Bytes\A = *Position\D
        Temp_Value\Bytes\B = *Position\C
        Temp_Value\Bytes\C = *Position\B
        Temp_Value\Bytes\D = *Position\A
        Temp_Length = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
        *Current_Tag\Raw_Size = Temp_Length
        If *Current_Tag\Raw_Size
          *Current_Tag\Raw = AllocateMemory(*Current_Tag\Raw_Size)
        EndIf
        If Not *Current_Tag\Raw And *Current_Tag\Raw_Size
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Current_Tag\Raw is #Null>"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
        EndIf
        If Read_Bytes + Temp_Length > Memory_Size
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Read_Bytes + Temp_Length > Memory_Size>"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
        EndIf
        If *Current_Tag\Raw
          CopyMemory(*Position, *Current_Tag\Raw, Temp_Length) : *Position + Temp_Length : Read_Bytes + Temp_Length
        EndIf
      Case #NBT_Tag_String
        Temp_Length = *Position\A<<8 + *Position\B : *Position + 2 : Read_Bytes + 2
        *Current_Tag\String = PeekS(*Position, Temp_Length, #PB_UTF8) : *Position + Temp_Length : Read_Bytes + Temp_Length
      Case #NBT_Tag_List
        *Current_Tag\List_Type = *Position\A : *Position + 1 : Read_Bytes + 1
        Temp_Value\Bytes\A = *Position\D
        Temp_Value\Bytes\B = *Position\C
        Temp_Value\Bytes\C = *Position\B
        Temp_Value\Bytes\D = *Position\A
        *Current_Tag\List_Size = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
        *Parent_Tag = *Current_Tag
      Case #NBT_Tag_Compound
        *Parent_Tag = *Current_Tag
      Case #NBT_Tag_Long_Array
        Temp_Value\Bytes\A = *Position\D
        Temp_Value\Bytes\B = *Position\C
        Temp_Value\Bytes\C = *Position\B
        Temp_Value\Bytes\D = *Position\A
        Temp_Length = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
        *Current_Tag\Raw_Size = Temp_Length
        If *Current_Tag\Raw_Size
          *Current_Tag\Raw = AllocateMemory(*Current_Tag\Raw_Size*4)
        EndIf
        If Not *Current_Tag\Raw And *Current_Tag\Raw_Size
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Current_Tag\Raw is #Null>"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
        EndIf
        If Read_Bytes + Temp_Length*4 > Memory_Size
          NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Read_Bytes + Temp_Length*4 > Memory_Size>"
          NBT_Element_Delete(NBT_Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
        EndIf
        *Temp_Pointer = *Current_Tag\Raw
        For i = 1 To Temp_Length
          *Temp_Pointer\Bytes\A = *Position\D
          *Temp_Pointer\Bytes\B = *Position\C
          *Temp_Pointer\Bytes\C = *Position\B
          *Temp_Pointer\Bytes\D = *Position\A
          *Temp_Pointer + 4
          *Position + 4 : Read_Bytes + 4
        Next
    EndSelect
  Wend
  
  If *Buffer : FreeMemory(*Buffer) : EndIf
  ProcedureReturn NBT_Element()
EndProcedure

Procedure NBT_Read_File(Filename.s, Compression=#NBT_Compression_Detect)
  Protected *NBT_Element.NBT_Element
  Protected File_ID, *Temp_Buffer, Temp_Buffer_Size
  
  File_ID = ReadFile(#PB_Any, Filename)
  If Not File_ID
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": ReadFile(#PB_Any, "+Filename+") failed>"
    ProcedureReturn #Null
  EndIf
  
  Temp_Buffer_Size = Lof(File_ID)
  *Temp_Buffer = AllocateMemory(Temp_Buffer_Size)
  
  If Not *Temp_Buffer
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Temp_Buffer_Size)+") failed>"
    CloseFile(File_ID)
    ProcedureReturn #Null
  EndIf
  
  If Not ReadData(File_ID, *Temp_Buffer, Temp_Buffer_Size) = Temp_Buffer_Size
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": ReadData("+Str(File_ID)+", "+Str(*Temp_Buffer)+", "+Str(Temp_Buffer_Size)+") != "+Str(Temp_Buffer_Size)+">"
    CloseFile(File_ID)
    FreeMemory(*Temp_Buffer)
    ProcedureReturn #Null
  EndIf
  
  CloseFile(File_ID)
  
  *NBT_Element = NBT_Read_Ram(*Temp_Buffer, Temp_Buffer_Size, Compression)
  
  FreeMemory(*Temp_Buffer)
  
  ProcedureReturn *NBT_Element
EndProcedure

Procedure NBT_Write_Ram_Helper(*NBT_Tag.NBT_Tag, *Memory.NBT_Eight_Bytes)
  Protected Temp_Value.NBT_Eight_Bytes_Ext
  
  If Not *Memory
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Memory is #Null>"
    ProcedureReturn #Null
  EndIf
  
  If Not *NBT_Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Tag is #Null>"
    ProcedureReturn #Null
  EndIf
  
  If *NBT_Tag\Parent And *NBT_Tag\Parent\Type = #NBT_Tag_List
    ; #### List-Elements only have a payload
  Else
    *Memory\A = *NBT_Tag\Type : *Memory + 1
    Temp_Value\Unicode = StringByteLength(*NBT_Tag\Name, #PB_UTF8)
    *Memory\B = Temp_Value\Bytes\A
    *Memory\A = Temp_Value\Bytes\B : *Memory + 2
    PokeS(*Memory, *NBT_Tag\Name, -1, #PB_UTF8)
    *Memory + Temp_Value\Unicode
  EndIf
  ; #### Get Payload-Size
  Select *NBT_Tag\Type
    Case #NBT_Tag_Byte
      Temp_Value\Byte = *NBT_Tag\Byte
      *Memory\A = Temp_Value\Bytes\A
      *Memory + 1
    Case #NBT_Tag_Word
      Temp_Value\Word = *NBT_Tag\Word
      *Memory\A = Temp_Value\Bytes\B
      *Memory\B = Temp_Value\Bytes\A
      *Memory + 2
    Case #NBT_Tag_Long
      Temp_Value\Long = *NBT_Tag\Long
      *Memory\A = Temp_Value\Bytes\D
      *Memory\B = Temp_Value\Bytes\C
      *Memory\C = Temp_Value\Bytes\B
      *Memory\D = Temp_Value\Bytes\A
      *Memory + 4
    Case #NBT_Tag_Quad
      Temp_Value\Quad = *NBT_Tag\Quad
      *Memory\A = Temp_Value\Bytes\H
      *Memory\B = Temp_Value\Bytes\G
      *Memory\C = Temp_Value\Bytes\F
      *Memory\D = Temp_Value\Bytes\E
      *Memory\E = Temp_Value\Bytes\D
      *Memory\F = Temp_Value\Bytes\C
      *Memory\G = Temp_Value\Bytes\B
      *Memory\H = Temp_Value\Bytes\A
      *Memory + 8
    Case #NBT_Tag_Float
      Temp_Value\Float = *NBT_Tag\Float
      *Memory\A = Temp_Value\Bytes\D
      *Memory\B = Temp_Value\Bytes\C
      *Memory\C = Temp_Value\Bytes\B
      *Memory\D = Temp_Value\Bytes\A
      *Memory + 4
    Case #NBT_Tag_Double
      Temp_Value\Double = *NBT_Tag\Double
      *Memory\A = Temp_Value\Bytes\H
      *Memory\B = Temp_Value\Bytes\G
      *Memory\C = Temp_Value\Bytes\F
      *Memory\D = Temp_Value\Bytes\E
      *Memory\E = Temp_Value\Bytes\D
      *Memory\F = Temp_Value\Bytes\C
      *Memory\G = Temp_Value\Bytes\B
      *Memory\H = Temp_Value\Bytes\A
      *Memory + 8
    Case #NBT_Tag_Byte_Array
      Temp_Value\Long = *NBT_Tag\Raw_Size
      *Memory\A = Temp_Value\Bytes\D
      *Memory\B = Temp_Value\Bytes\C
      *Memory\C = Temp_Value\Bytes\B
      *Memory\D = Temp_Value\Bytes\A
      *Memory + 4
      If *NBT_Tag\Raw And *NBT_Tag\Raw_Size
        CopyMemory(*NBT_Tag\Raw, *Memory, *NBT_Tag\Raw_Size)
      EndIf
      *Memory + *NBT_Tag\Raw_Size
    Case #NBT_Tag_String
      Temp_Value\Unicode = StringByteLength(*NBT_Tag\String, #PB_UTF8)
      *Memory\A = Temp_Value\Bytes\B
      *Memory\B = Temp_Value\Bytes\A
      *Memory + 2
      PokeS(*Memory, *NBT_Tag\String, -1, #PB_UTF8)
      *Memory + Temp_Value\Unicode
    Case #NBT_Tag_List
      Temp_Value\Byte = *NBT_Tag\List_Type
      *Memory\A = Temp_Value\Bytes\A
      *Memory + 1
      Temp_Value\Long = ListSize(*NBT_Tag\Child())
      *Memory\A = Temp_Value\Bytes\D
      *Memory\B = Temp_Value\Bytes\C
      *Memory\C = Temp_Value\Bytes\B
      *Memory\D = Temp_Value\Bytes\A
      *Memory + 4
      ForEach *NBT_Tag\Child()
        *Memory = NBT_Write_Ram_Helper(*NBT_Tag\Child(), *Memory)
      Next
    Case #NBT_Tag_Compound
      ForEach *NBT_Tag\Child()
        *Memory = NBT_Write_Ram_Helper(*NBT_Tag\Child(), *Memory)
      Next
      *Memory\A = 0 ; Tag_End
      *Memory + 1
    Case #NBT_Tag_Long_Array
      Temp_Value\Long = *NBT_Tag\Raw_Size
      *Memory\A = Temp_Value\Bytes\D
      *Memory\B = Temp_Value\Bytes\C
      *Memory\C = Temp_Value\Bytes\B
      *Memory\D = Temp_Value\Bytes\A
      *Memory + 4
      If *NBT_Tag\Raw And *NBT_Tag\Raw_Size*4
        CopyMemory(*NBT_Tag\Raw, *Memory, *NBT_Tag\Raw_Size*4)
      EndIf
      *Memory + *NBT_Tag\Raw_Size*4
  EndSelect
  
  ProcedureReturn *Memory
EndProcedure

Procedure NBT_Write_Ram(*NBT_Element.NBT_Element, *Memory, Memory_Size, Compression=#NBT_Compression_GZip)
  Protected *End_Adress, Written, Stream.z_stream
  Protected *Temp_Buffer, Compressed_Size, Window_Size
  
  If Not *NBT_Element
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Element is #Null>"
    ProcedureReturn 0
  EndIf
  
  If Compression = #NBT_Compression_GZip Or Compression = #NBT_Compression_ZLib
    
    *Temp_Buffer = AllocateMemory(Memory_Size)
    If Not *Temp_Buffer
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Memory_Size)+") failed>"
      ProcedureReturn 0
    EndIf
    
    *End_Adress = NBT_Write_Ram_Helper(*NBT_Element\NBT_Tag, *Temp_Buffer)
    If Not *End_Adress
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": NBT_Write_Ram_Helper("+Str(*NBT_Element)+", "+Str(*Temp_Buffer)+") failed>"
      FreeMemory(*Temp_Buffer)
      ProcedureReturn 0
    EndIf
    
    Select Compression
      Case #NBT_Compression_GZip
        Window_Size = 15+16
      Case #NBT_Compression_ZLib
        Window_Size = 15
    EndSelect
    
    Stream\avail_in = Memory_Size
    Stream\avail_out = Memory_Size
    Stream\next_in = *Temp_Buffer
    Stream\next_out = *Memory
    
    If Not deflateInit2_(Stream, #Z_DEFAULT_COMPRESSION, #Z_DEFLATED, Window_Size, 8, #Z_DEFAULT_STRATEGY, zlibVersion(), SizeOf(z_stream)) = #Z_OK
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": deflateInit2_(Stream, #Z_DEFAULT_COMPRESSION, #Z_DEFLATED, Window_Size, 8, #Z_DEFAULT_STRATEGY, zlibVersion(), SizeOf(z_stream)) != #Z_OK>"
      FreeMemory(*Temp_Buffer)
      ProcedureReturn 0
    EndIf
    
    If Not deflate(Stream, #Z_FINISH) = #Z_STREAM_END
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": deflate(Stream, #Z_FINISH) != #Z_STREAM_END>"
      FreeMemory(*Temp_Buffer)
      ProcedureReturn 0
    EndIf
    Compressed_Size = Stream\total_out
    deflateEnd(Stream)
    
    FreeMemory(*Temp_Buffer)
    
    ProcedureReturn Compressed_Size
  Else
    *End_Adress = NBT_Write_Ram_Helper(*NBT_Element\NBT_Tag, *Memory)
    If Not *End_Adress
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": NBT_Write_Ram_Helper("+Str(*NBT_Element)+", "+Str(*Memory)+") failed>"
      ProcedureReturn 0
    EndIf
    
    Written = *End_Adress - *Memory
    
    ProcedureReturn Written
  EndIf
EndProcedure

Procedure NBT_Write_File(*NBT_Element.NBT_Element, Filename.s, Compression=#NBT_Compression_GZip)
  Protected File_ID, *Temp_Buffer, Temp_Buffer_Size, Real_Size
  
  If Not *NBT_Element
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *NBT_Element is #Null>"
    ProcedureReturn #False
  EndIf
  
  Temp_Buffer_Size = NBT_Get_Ram_Size(*NBT_Element)
  *Temp_Buffer = AllocateMemory(Temp_Buffer_Size)
  If Not *Temp_Buffer
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Temp_Buffer_Size)+") failed>"
    ProcedureReturn #False
  EndIf
  
  Real_Size = NBT_Write_Ram(*NBT_Element, *Temp_Buffer, Temp_Buffer_Size, Compression)
  If Not Real_Size
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": NBT_Write_Ram(*NBT_Element, *Temp_Buffer, "+Str(Temp_Buffer_Size)+") failed>"
    FreeMemory(*Temp_Buffer)
    ProcedureReturn #False
  EndIf
  
  File_ID = CreateFile(#PB_Any, Filename)
  If Not File_ID
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": CreateFile(#PB_Any, "+Filename+") failed>"
    FreeMemory(*Temp_Buffer)
    ProcedureReturn #False
  EndIf
  
  WriteData(File_ID, *Temp_Buffer, Real_Size)
  
  CloseFile(File_ID)
  FreeMemory(*Temp_Buffer)
  
  ProcedureReturn #True
EndProcedure

Procedure.s NBT_Tag_Serialize(*Tag.NBT_Tag, Level=0)
  Protected Output.s = Space(Level*2)
  
  If Not *Tag
    NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
    ProcedureReturn "[Invalid_Element]"
  EndIf
  
  Select *Tag\Type
    Case #NBT_Tag_End
      Output + "[This shouldn't appear!]"
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type = #NBT_Tag_End>"
    Case #NBT_Tag_Byte
      Output + "TAG_Byte('"+*Tag\Name+"'): "+Str(*Tag\Byte)
    Case #NBT_Tag_Word
      Output + "TAG_Word('"+*Tag\Name+"'): "+Str(*Tag\Word)
    Case #NBT_Tag_Long
      Output + "TAG_Long('"+*Tag\Name+"'): "+Str(*Tag\Long)
    Case #NBT_Tag_Quad
      Output + "TAG_Quad('"+*Tag\Name+"'): "+Str(*Tag\Quad)
    Case #NBT_Tag_Float
      Output + "TAG_Float('"+*Tag\Name+"'): "+StrF(*Tag\Float)
    Case #NBT_Tag_Double
      Output + "TAG_Double('"+*Tag\Name+"'): "+StrD(*Tag\Double)
    Case #NBT_Tag_Byte_Array
      Output + "TAG_Byte_Array('"+*Tag\Name+"'): ["+Str(*Tag\Raw_Size)+" bytes]"
    Case #NBT_Tag_String
      Output + "TAG_String('"+*Tag\Name+"'): '"+*Tag\String+"'"
    Case #NBT_Tag_List
      Output + "TAG_List('"+*Tag\Name+"'): "+Str(ListSize(*Tag\Child()))+" entries" + #CRLF$
      Output + Space(Level*2) + "{" + #CRLF$
      ForEach *Tag\Child()
        Output + NBT_Tag_Serialize(*Tag\Child(), Level+1) + #CRLF$
      Next
      Output + Space(Level*2) + "}"
    Case #NBT_Tag_Compound
      Output + "TAG_Compound('"+*Tag\Name+"'): "+Str(ListSize(*Tag\Child()))+" entries" + #CRLF$
      Output + Space(Level*2) + "{" + #CRLF$
      ForEach *Tag\Child()
        Output + NBT_Tag_Serialize(*Tag\Child(), Level+1) + #CRLF$
      Next
      Output + Space(Level*2) + "}"
    Case #NBT_Tag_Long_Array
      Output + "TAG_Long_Array('"+*Tag\Name+"'): ["+Str(*Tag\Raw_Size)+" longs]"
    Default
      Output + "[Something went really wrong here!]"
      NBT_Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unknown: *Tag\Type = "+Str(*Tag\Type)+">"
  EndSelect
  
  ProcedureReturn Output
EndProcedure

; #################################################### Initstuff #################################################

; #################################################### Datasections ##############################################
; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 6
; Folding = -----
; EnableXP