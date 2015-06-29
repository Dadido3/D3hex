; ##################################################### License / Copyright #########################################
; 
;     The MIT License (MIT)
;     
;     Copyright (c) 2012-2015  David Vogel
;     
;     Permission is hereby granted, free of charge, To any person obtaining a copy
;     of this software And associated documentation files (the "Software"), To deal
;     in the Software without restriction, including without limitation the rights
;     To use, copy, modify, merge, publish, distribute, sublicense, And/Or sell
;     copies of the Software, And To permit persons To whom the Software is
;     furnished To do so, subject To the following conditions:
;     
;     The above copyright notice And this permission notice shall be included in all
;     copies Or substantial portions of the Software.
;     
;     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS Or
;     IMPLIED, INCLUDING BUT Not LIMITED To THE WARRANTIES OF MERCHANTABILITY,
;     FITNESS For A PARTICULAR PURPOSE And NONINFRINGEMENT. IN NO EVENT SHALL THE
;     AUTHORS Or COPYRIGHT HOLDERS BE LIABLE For ANY CLAIM, DAMAGES Or OTHER
;     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT Or OTHERWISE, ARISING FROM,
;     OUT OF Or IN CONNECTION With THE SOFTWARE Or THE USE Or OTHER DEALINGS IN THE
;     SOFTWARE.
;
; #################################################### Documentation #############################################

; Named Binary Tags - Include
; 
; V1.000 (27.07.2012)
;   - Everything is done, hopefully
; 
; V1.100 (28.07.2012)
;   - Better ZLib implementation in NBT::Read_Ram()
;   - Added Compression-Types
; 
; V1.110 (10.02.2014)
;   - Made it possible to write an empty array with NBT::Tag_Set_Array(*Tag.Tag, *Data_, 0)
;   - Changed the parameter "GZip" to "Compression" in NBT::Write_File
; 
; V1.111 (22.02.2014)
;   - Add child elements to the end of lists or compounds
; 
; V1.112 (24.02.2014)
;   - Added NBT::Error_Available()
; 
; V1.113 (29.06.2015)
;   - Conversion to module
; 
; 
; ##################################################### Includes ####################################################

XIncludeFile "ZLib.pbi"

; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule NBT
  EnableExplicit
  ; ################################################### Constants ###################################################
  #Version = 1113
  
  Enumeration
    #Tag_End
    #Tag_Byte
    #Tag_Word
    #Tag_Long
    #Tag_Quad
    #Tag_Float
    #Tag_Double
    #Tag_Byte_Array
    #Tag_String
    #Tag_List
    #Tag_Compound
    #Tag_Long_Array
  EndEnumeration
  
  #Buffer_Step_Size = 1024*1024*10
  
  Enumeration
    #Compression_None
    #Compression_Detect
    #Compression_GZip
    #Compression_ZLib
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  Structure Tag
    *Parent.Tag
    *Element.Element
    
    Type.a
    Name.s
    
    ; #### Payload
    Byte.b
    Word.w
    Long.l
    Quad.q
    Float.f
    Double.d
    List Child.Tag()
    String.s
    List_Type.a
    List_Size.l ; Only a temporary variable, it't DOESN'T represent the list-size!
    
    *Raw
    Raw_Size.l ; In elements
  EndStructure
  
  Structure Element
    Reserved.l
    
    Tag.Tag
  EndStructure
  
  ; ################################################### Functions ###################################################
  Declare   Error_Available()
  Declare.s Error_Get()
  
  Declare   Tag_Add(*Parent_Tag.Tag, Name.s, Type, List_Type=0)
  Declare   Tag_Delete(*Tag.Tag)
  
  Declare   Tag(*Parent_Tag.Tag, Name.s)
  Declare   Tag_Index(*Parent_Tag.Tag, Index)
  Declare   Tag_Count(*Tag.Tag)
  
  Declare   Tag_Set_Name(*Tag.Tag, Name.s)
  Declare   Tag_Set_Number(*Tag.Tag, Value.q)
  Declare   Tag_Set_Float(*Tag.Tag, Value.f)
  Declare   Tag_Set_Double(*Tag.Tag, Value.d)
  Declare   Tag_Set_String(*Tag.Tag, Value.s)
  Declare   Tag_Set_Array(*Tag.Tag, *Data_, Data_Size)
  
  Declare.s Tag_Get_Name(*Tag.Tag)
  Declare.q Tag_Get_Number(*Tag.Tag)
  Declare.f Tag_Get_Float(*Tag.Tag)
  Declare.d Tag_Get_Double(*Tag.Tag)
  Declare.s Tag_Get_String(*Tag.Tag)
  Declare   Tag_Get_Array(*Tag.Tag, *Pointer, Data_Size)
  
  Declare   Element_Add()
  Declare   Element_Delete(*Element.Element)
  
  Declare   Get_Ram_Size(*Element.Element)
  
  Declare   Read_Ram(*Memory, Memory_Size, Compression=#Compression_Detect)
  Declare   Read_File(Filename.s, Compression=#Compression_Detect)
  
  Declare   Write_Ram(*Element.Element, *Memory, Memory_Size, Compression=#Compression_GZip)
  Declare   Write_File(*Element.Element, Filename.s, Compression=#Compression_GZip)
  
  Declare.s Tag_Serialize(*Tag.Tag, Level=0)
  
EndDeclareModule

Module NBT
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  Structure Eight_Bytes
    A.a
    B.a
    C.a
    D.a
    E.a
    F.a
    G.a
    H.a
  EndStructure
  
  Structure Eight_Bytes_Ext
    StructureUnion
      Bytes.Eight_Bytes
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
  
  Structure Main
    Error_String.s
  EndStructure
  
  ; ################################################### Variables ###################################################
  Global Main.Main
  
  Global NewList Element.Element()
  
  Main\Error_String = ""
  
  ; ################################################### Procedures ##################################################
  Procedure Error_Available()
    If Main\Error_String <> ""
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure.s Error_Get()
    Protected Error.s = Main\Error_String
    Main\Error_String = ""
    ProcedureReturn Error
  EndProcedure
  
  Procedure Tag_Add(*Parent_Tag.Tag, Name.s, Type, List_Type=0)
    If Not *Parent_Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
      ProcedureReturn #Null
    EndIf
    
    If *Parent_Tag\Type <> #Tag_List And *Parent_Tag\Type <> #Tag_Compound
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type = "+Str(*Parent_Tag\Type)+" can't contain tag's>"
      ProcedureReturn #Null
    EndIf
    
    If *Parent_Tag\Type = #Tag_List And Type <> *Parent_Tag\List_Type
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Type = "+Str(Type)+" != "+Str(*Parent_Tag\List_Type)+" = *Parent_Tag\List_Type>"
      ProcedureReturn #Null
    EndIf
    
    Select Type
      Case #Tag_Byte
      Case #Tag_Word
      Case #Tag_Long
      Case #Tag_Quad
      Case #Tag_Float
      Case #Tag_Double
      Case #Tag_Byte_Array
      Case #Tag_String
      Case #Tag_List
      Case #Tag_Compound
      Case #Tag_Long_Array
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Type = "+Str(Type)+" is invalid>"
        ProcedureReturn #Null
    EndSelect
    
    If *Parent_Tag\Type = #Tag_Compound
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
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
      ProcedureReturn #Null
    EndIf
    
    *Parent_Tag\Child()\Name = Name
    *Parent_Tag\Child()\Type = Type
    *Parent_Tag\Child()\Parent = *Parent_Tag
    *Parent_Tag\Child()\List_Type = List_Type
    
    ProcedureReturn *Parent_Tag\Child()
  EndProcedure
  
  Procedure Tag(*Parent_Tag.Tag, Name.s)
    If Not *Parent_Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
      ProcedureReturn #Null
    EndIf
    
    Select *Parent_Tag\Type
      Case #Tag_Compound
        ForEach *Parent_Tag\Child()
          If *Parent_Tag\Child()\Name = Name
            ProcedureReturn *Parent_Tag\Child()
          EndIf
        Next
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type is incompatible>"
        ProcedureReturn #Null
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Child()\Name = '"+Name+"' Not found>"
    ProcedureReturn #Null
  EndProcedure
  
  Procedure Tag_Index(*Parent_Tag.Tag, Index)
    If Not *Parent_Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag is #Null>"
      ProcedureReturn #Null
    EndIf
    
    Select *Parent_Tag\Type
      Case #Tag_Compound
        If Index >= 0 And Index < ListSize(*Parent_Tag\Child())
          SelectElement(*Parent_Tag\Child(), Index)
          ProcedureReturn *Parent_Tag\Child()
        EndIf
      Case #Tag_List
        If Index >= 0 And Index < ListSize(*Parent_Tag\Child())
          SelectElement(*Parent_Tag\Child(), Index)
          ProcedureReturn *Parent_Tag\Child()
        EndIf
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Type is incompatible>"
        ProcedureReturn #Null
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Index is out of *Parent_Tag\Child()>"
    ProcedureReturn #Null
  EndProcedure
  
  Procedure Tag_Count(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    Select *Tag\Type
      Case #Tag_Byte_Array : ProcedureReturn *Tag\Raw_Size
      Case #Tag_Long_Array : ProcedureReturn *Tag\Raw_Size
      Case #Tag_Compound   : ProcedureReturn ListSize(*Tag\Child())
      Case #Tag_List       : ProcedureReturn ListSize(*Tag\Child())
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
    ProcedureReturn 0
  EndProcedure
  
  Procedure Tag_Set_Name(*Tag.Tag, Name.s)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    If *Tag\Parent And *Tag\Parent\Type = #Tag_List
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag can't have a name>"
      ProcedureReturn #False
    EndIf
    
    *Tag\Name = Name
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.s Tag_Get_Name(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn ""
    EndIf
    
    ProcedureReturn *Tag\Name
  EndProcedure
  
  Procedure Tag_Set_Number(*Tag.Tag, Value.q)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_Byte : *Tag\Byte = Value
      Case #Tag_Word : *Tag\Word = Value
      Case #Tag_Long : *Tag\Long = Value
      Case #Tag_Quad : *Tag\Quad = Value
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.q Tag_Get_Number(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    Select *Tag\Type
      Case #Tag_Byte : ProcedureReturn *Tag\Byte
      Case #Tag_Word : ProcedureReturn *Tag\Word
      Case #Tag_Long : ProcedureReturn *Tag\Long
      Case #Tag_Quad : ProcedureReturn *Tag\Quad
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
    ProcedureReturn 0
  EndProcedure
  
  Procedure Tag_Set_Float(*Tag.Tag, Value.f)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_Float : *Tag\Float = Value
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.f Tag_Get_Float(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    Select *Tag\Type
      Case #Tag_Float : ProcedureReturn *Tag\Float
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
    ProcedureReturn 0
  EndProcedure
  
  Procedure Tag_Set_Double(*Tag.Tag, Value.d)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_Double : *Tag\Double = Value
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.d Tag_Get_Double(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    Select *Tag\Type
      Case #Tag_Double : ProcedureReturn *Tag\Double
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
    ProcedureReturn 0
  EndProcedure
  
  Procedure Tag_Set_String(*Tag.Tag, Value.s)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_String : *Tag\String = Value
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.s Tag_Get_String(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn ""
    EndIf
    
    Select *Tag\Type
      Case #Tag_String : ProcedureReturn *Tag\String
    EndSelect
    
    Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
    ProcedureReturn ""
  EndProcedure
  
  Procedure Tag_Set_Array(*Tag.Tag, *Data_, Data_Size)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_Byte_Array
        If *Tag\Raw
          FreeMemory(*Tag\Raw) : *Tag\Raw = #Null : *Tag\Raw_Size = 0
        EndIf
        If *Data_ And Data_Size > 0
          *Tag\Raw_Size = Data_Size
          *Tag\Raw = AllocateMemory(*Tag\Raw_Size)
          If Not *Tag\Raw
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(*Tag\Raw_Size)+") failed>"
            ProcedureReturn #False
          EndIf
          CopyMemory(*Data_, *Tag\Raw, *Tag\Raw_Size)
        EndIf
      Case #Tag_Long_Array
        If *Tag\Raw
          FreeMemory(*Tag\Raw) : *Tag\Raw = #Null : *Tag\Raw_Size = 0
        EndIf
        If *Data_ And Data_Size > 0
          *Tag\Raw_Size = Data_Size / 4
          *Tag\Raw = AllocateMemory(*Tag\Raw_Size * 4)
          If Not *Tag\Raw
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(*Tag\Raw_Size * 4)+") failed>"
            ProcedureReturn #False
          EndIf
          CopyMemory(*Data_, *Tag\Raw, *Tag\Raw_Size * 4)
        EndIf
      Default
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Tag_Get_Array(*Tag.Tag, *Pointer, Data_Size)
    Protected Max_Data_Size
    
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    Select *Tag\Type
      Case #Tag_Byte_Array
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
      Case #Tag_Long_Array
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
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type is incompatible>"
        ProcedureReturn #False
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Tag_Delete(*Tag.Tag)
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #False
    EndIf
    
    If *Tag\Raw
      FreeMemory(*Tag\Raw)
      *Tag\Raw = #Null
    EndIf
    
    While FirstElement(*Tag\Child())
      Tag_Delete(*Tag\Child())
    Wend
    
    If *Tag\Parent
      If ChangeCurrentElement(*Tag\Parent\Child(), *Tag)
        DeleteElement(*Tag\Parent\Child())
      EndIf
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Element_Add()
    
    If Not AddElement(Element())
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(Element()) failed>"
      ProcedureReturn #Null
    EndIf
    
    Element()\Tag\Type = #Tag_Compound
    
    ProcedureReturn Element()
  EndProcedure
  
  Procedure Element_Delete(*Element.Element)
    If Not *Element
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Element is #Null>"
      ProcedureReturn #False
    EndIf
    
    Tag_Delete(*Element\Tag)
    
    ChangeCurrentElement(Element(), *Element)
    DeleteElement(Element())
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Ram_Size_Helper(*Tag.Tag)
    Protected Size
    
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    If *Tag\Parent And *Tag\Parent\Type = #Tag_List
      ; #### List-Elements only have a payload
    Else
      Size + 3 + StringByteLength(*Tag\Name, #PB_UTF8)
    EndIf
    ; #### Get Payload-Size
    Select *Tag\Type
      Case #Tag_Byte          : Size + 1
      Case #Tag_Word          : Size + 2
      Case #Tag_Long          : Size + 4
      Case #Tag_Quad          : Size + 8
      Case #Tag_Float         : Size + 4
      Case #Tag_Double        : Size + 8
      Case #Tag_Byte_Array    : Size + 4 + *Tag\Raw_Size
      Case #Tag_String        : Size + 2 + StringByteLength(*Tag\String, #PB_UTF8)
      Case #Tag_List
        Size + 5 ; Type, List-Size
        ForEach *Tag\Child()
          Size + Get_Ram_Size_Helper(*Tag\Child())
        Next
      Case #Tag_Compound
        ForEach *Tag\Child()
          Size + Get_Ram_Size_Helper(*Tag\Child())
        Next
        Size + 1 ; Tag_End
      Case #Tag_Long_Array    : Size + 4 + *Tag\Raw_Size * 4
    EndSelect
    
    ProcedureReturn Size
  EndProcedure
  
  Procedure Get_Ram_Size(*Element.Element)
    If Not *Element
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Element is #Null>"
      ProcedureReturn 0
    EndIf
    
    If Not *Element\Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Element\Tag is #Null>"
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn Get_Ram_Size_Helper(*Element\Tag)
  EndProcedure
  
  Procedure Read_Ram(*Memory, Memory_Size, Compression=#Compression_Detect)
    Protected *Buffer, Buffer_Size, Stream.ZLIB::z_stream, Temp_Result
    Protected *Position.Eight_Bytes, Read_Bytes, Temp_Length
    Protected *Parent_Tag.Tag
    Protected *Current_Tag.Tag
    Protected Temp_Value.Eight_Bytes_Ext
    Protected *Temp_Pointer.Eight_Bytes_Ext
    Protected Tag_Type
    Protected i
    
    If Not *Memory
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Memory is #Null>"
      ProcedureReturn #Null
    EndIf
    
    *Position = *Memory
    
    If Compression = #Compression_GZip Or Compression = #Compression_ZLib Or (Compression = #Compression_Detect And *Position\A = $1F And *Position\B = $8B)
      Buffer_Size = #Buffer_Step_Size
      *Buffer = AllocateMemory(Buffer_Size)
      
      If Not *Buffer
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Buffer is #Null>"
        ProcedureReturn #Null
      EndIf
      
      Stream\avail_in = Memory_Size
      Stream\avail_out = Buffer_Size
      Stream\next_in = *Memory
      Stream\next_out = *Buffer
      
      If Not ZLIB::inflateInit2_(Stream, 15+32, ZLIB::ZLIBVersion(), SizeOf(ZLIB::z_stream)) = ZLIB::#Z_OK
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": inflateInit2_(Stream, 15+16, ZLIBVersion(), SizeOf(z_stream)) != #Z_OK>"
        If *Buffer : FreeMemory(*Buffer) : EndIf
        ProcedureReturn #Null
      EndIf
      
      Repeat
        Temp_Result = ZLIB::inflate(Stream, ZLIB::#Z_NO_FLUSH)
        If Temp_Result <> ZLIB::#Z_OK And Temp_Result <> ZLIB::#Z_STREAM_END
          Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": inflate(Stream, #Z_FINISH) failed>"
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ZLIB::inflateEnd(Stream)
          ProcedureReturn #Null
        EndIf
        If Temp_Result = ZLIB::#Z_OK
          Buffer_Size + #Buffer_Step_Size
          *Buffer = ReAllocateMemory(*Buffer, Buffer_Size)
          If Not *Buffer
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Buffer is #Null>"
            ; #### In this case there is the previous *Buffer left in memory (Causes a mem-leak, but that only happens if the memory is full)
            ZLIB::inflateEnd(Stream)
            ProcedureReturn #Null
          EndIf
          Stream\avail_out = #Buffer_Step_Size
          Stream\next_out = *Buffer + Buffer_Size - #Buffer_Step_Size
        EndIf
      Until Temp_Result = ZLIB::#Z_STREAM_END
      Buffer_Size = Stream\total_out
      ZLIB::inflateEnd(Stream)
      
      *Position = *Buffer
      Memory_Size = Buffer_Size
    EndIf
    
    If Not AddElement(Element())
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(Element()) failed>"
      If *Buffer : FreeMemory(*Buffer) : EndIf
      ProcedureReturn #Null
    EndIf
    
    *Parent_Tag = #Null
    
    While Read_Bytes < Memory_Size
      
      If *Parent_Tag And *Parent_Tag\Type = #Tag_List And ListSize(*Parent_Tag\Child()) >= *Parent_Tag\List_Size
        If *Parent_Tag\Parent
          *Parent_Tag = *Parent_Tag\Parent
        Else
          Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Parent_Tag\Parent not existant>"
          Element_Delete(Element())
          If *Buffer : FreeMemory(*Buffer) : EndIf
          ProcedureReturn #Null
        EndIf
      EndIf
      
      If *Parent_Tag And *Parent_Tag\Type = #Tag_List
        Tag_Type = *Parent_Tag\List_Type
        Select Tag_Type
          Case #Tag_Byte, #Tag_Word, #Tag_Long, #Tag_Quad, #Tag_Float, #Tag_Double, #Tag_Byte_Array, #Tag_String, #Tag_List, #Tag_Compound, #Tag_Long_Array
            If Not AddElement(*Parent_Tag\Child())
              Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
              Element_Delete(Element())
              If *Buffer : FreeMemory(*Buffer) : EndIf
              ProcedureReturn #Null
            EndIf
            *Current_Tag = *Parent_Tag\Child()
            *Current_Tag\Type = Tag_Type
            *Current_Tag\Name = ""
            *Current_Tag\Parent = *Parent_Tag
            *Current_Tag\Element = Element()
          Default
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unkown: *Parent_Tag\List_Type = "+Str(Tag_Type)+">"
            Element_Delete(Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
        EndSelect
      Else
        Tag_Type = PeekA(*Position)
        Select Tag_Type
          Case #Tag_End
            *Position + 1 : Read_Bytes + 1
            If *Parent_Tag = #Null
              ; #### Root element, it's done!
              If *Buffer : FreeMemory(*Buffer) : EndIf
              ProcedureReturn Element()
            EndIf
            *Parent_Tag = *Parent_Tag\Parent
          Case #Tag_Byte, #Tag_Word, #Tag_Long, #Tag_Quad, #Tag_Float, #Tag_Double, #Tag_Byte_Array, #Tag_String, #Tag_List, #Tag_Compound, #Tag_Long_Array
            *Position + 1 : Read_Bytes + 1
            If *Parent_Tag
              If Not AddElement(*Parent_Tag\Child())
                Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AddElement(*Parent_Tag\Child()) failed>"
                Element_Delete(Element())
                If *Buffer : FreeMemory(*Buffer) : EndIf
                ProcedureReturn #Null
              EndIf
              *Current_Tag = *Parent_Tag\Child()
            Else
              *Current_Tag = Element()\Tag
            EndIf
            Temp_Length = *Position\A<<8 + *Position\B : *Position + 2 : Read_Bytes + 2
            *Current_Tag\Type = Tag_Type
            *Current_Tag\Name = PeekS(*Position, Temp_Length, #PB_UTF8) : *Position + Temp_Length : Read_Bytes + Temp_Length
            *Current_Tag\Parent = *Parent_Tag
            *Current_Tag\Element = Element()
          Default
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unkown: Tag_Type = PeekA(*Position) = "+Str(Tag_Type)+">"
            Element_Delete(Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
        EndSelect
      EndIf
      
      ; #### Read the payload
      Select Tag_Type
        Case #Tag_Byte
          *Current_Tag\Byte = *Position\A : *Position + 1 : Read_Bytes + 1
        Case #Tag_Word
          Temp_Value\Bytes\A = *Position\B
          Temp_Value\Bytes\B = *Position\A
          *Current_Tag\Word = Temp_Value\Word : *Position + 2 : Read_Bytes + 2
        Case #Tag_Long
          Temp_Value\Bytes\A = *Position\D
          Temp_Value\Bytes\B = *Position\C
          Temp_Value\Bytes\C = *Position\B
          Temp_Value\Bytes\D = *Position\A
          *Current_Tag\Long = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
        Case #Tag_Quad
          Temp_Value\Bytes\A = *Position\H
          Temp_Value\Bytes\B = *Position\G
          Temp_Value\Bytes\C = *Position\F
          Temp_Value\Bytes\D = *Position\E
          Temp_Value\Bytes\E = *Position\D
          Temp_Value\Bytes\F = *Position\C
          Temp_Value\Bytes\G = *Position\B
          Temp_Value\Bytes\H = *Position\A
          *Current_Tag\Quad = Temp_Value\Quad : *Position + 8 : Read_Bytes + 8
        Case #Tag_Float
          Temp_Value\Bytes\A = *Position\D
          Temp_Value\Bytes\B = *Position\C
          Temp_Value\Bytes\C = *Position\B
          Temp_Value\Bytes\D = *Position\A
          *Current_Tag\Float = Temp_Value\Float : *Position + 4 : Read_Bytes + 4
        Case #Tag_Double
          Temp_Value\Bytes\A = *Position\H
          Temp_Value\Bytes\B = *Position\G
          Temp_Value\Bytes\C = *Position\F
          Temp_Value\Bytes\D = *Position\E
          Temp_Value\Bytes\E = *Position\D
          Temp_Value\Bytes\F = *Position\C
          Temp_Value\Bytes\G = *Position\B
          Temp_Value\Bytes\H = *Position\A
          *Current_Tag\Double = Temp_Value\Double : *Position + 8 : Read_Bytes + 8
        Case #Tag_Byte_Array
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
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Current_Tag\Raw is #Null>"
            Element_Delete(Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
          EndIf
          If Read_Bytes + Temp_Length > Memory_Size
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Read_Bytes + Temp_Length > Memory_Size>"
            Element_Delete(Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
          EndIf
          If *Current_Tag\Raw
            CopyMemory(*Position, *Current_Tag\Raw, Temp_Length) : *Position + Temp_Length : Read_Bytes + Temp_Length
          EndIf
        Case #Tag_String
          Temp_Length = *Position\A<<8 + *Position\B : *Position + 2 : Read_Bytes + 2
          *Current_Tag\String = PeekS(*Position, Temp_Length, #PB_UTF8) : *Position + Temp_Length : Read_Bytes + Temp_Length
        Case #Tag_List
          *Current_Tag\List_Type = *Position\A : *Position + 1 : Read_Bytes + 1
          Temp_Value\Bytes\A = *Position\D
          Temp_Value\Bytes\B = *Position\C
          Temp_Value\Bytes\C = *Position\B
          Temp_Value\Bytes\D = *Position\A
          *Current_Tag\List_Size = Temp_Value\Long : *Position + 4 : Read_Bytes + 4
          *Parent_Tag = *Current_Tag
        Case #Tag_Compound
          *Parent_Tag = *Current_Tag
        Case #Tag_Long_Array
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
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Current_Tag\Raw is #Null>"
            Element_Delete(Element())
            If *Buffer : FreeMemory(*Buffer) : EndIf
            ProcedureReturn #Null
          EndIf
          If Read_Bytes + Temp_Length*4 > Memory_Size
            Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Read_Bytes + Temp_Length*4 > Memory_Size>"
            Element_Delete(Element())
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
    ProcedureReturn Element()
  EndProcedure
  
  Procedure Read_File(Filename.s, Compression=#Compression_Detect)
    Protected *Element.Element
    Protected File_ID, *Temp_Buffer, Temp_Buffer_Size
    
    File_ID = ReadFile(#PB_Any, Filename)
    If Not File_ID
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": ReadFile(#PB_Any, "+Filename+") failed>"
      ProcedureReturn #Null
    EndIf
    
    Temp_Buffer_Size = Lof(File_ID)
    *Temp_Buffer = AllocateMemory(Temp_Buffer_Size)
    
    If Not *Temp_Buffer
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Temp_Buffer_Size)+") failed>"
      CloseFile(File_ID)
      ProcedureReturn #Null
    EndIf
    
    If Not ReadData(File_ID, *Temp_Buffer, Temp_Buffer_Size) = Temp_Buffer_Size
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": ReadData("+Str(File_ID)+", "+Str(*Temp_Buffer)+", "+Str(Temp_Buffer_Size)+") != "+Str(Temp_Buffer_Size)+">"
      CloseFile(File_ID)
      FreeMemory(*Temp_Buffer)
      ProcedureReturn #Null
    EndIf
    
    CloseFile(File_ID)
    
    *Element = Read_Ram(*Temp_Buffer, Temp_Buffer_Size, Compression)
    
    FreeMemory(*Temp_Buffer)
    
    ProcedureReturn *Element
  EndProcedure
  
  Procedure Write_Ram_Helper(*Tag.Tag, *Memory.Eight_Bytes)
    Protected Temp_Value.Eight_Bytes_Ext
    
    If Not *Memory
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Memory is #Null>"
      ProcedureReturn #Null
    EndIf
    
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn #Null
    EndIf
    
    If *Tag\Parent And *Tag\Parent\Type = #Tag_List
      ; #### List-Elements only have a payload
    Else
      *Memory\A = *Tag\Type : *Memory + 1
      Temp_Value\Unicode = StringByteLength(*Tag\Name, #PB_UTF8)
      *Memory\B = Temp_Value\Bytes\A
      *Memory\A = Temp_Value\Bytes\B : *Memory + 2
      PokeS(*Memory, *Tag\Name, -1, #PB_UTF8)
      *Memory + Temp_Value\Unicode
    EndIf
    ; #### Get Payload-Size
    Select *Tag\Type
      Case #Tag_Byte
        Temp_Value\Byte = *Tag\Byte
        *Memory\A = Temp_Value\Bytes\A
        *Memory + 1
      Case #Tag_Word
        Temp_Value\Word = *Tag\Word
        *Memory\A = Temp_Value\Bytes\B
        *Memory\B = Temp_Value\Bytes\A
        *Memory + 2
      Case #Tag_Long
        Temp_Value\Long = *Tag\Long
        *Memory\A = Temp_Value\Bytes\D
        *Memory\B = Temp_Value\Bytes\C
        *Memory\C = Temp_Value\Bytes\B
        *Memory\D = Temp_Value\Bytes\A
        *Memory + 4
      Case #Tag_Quad
        Temp_Value\Quad = *Tag\Quad
        *Memory\A = Temp_Value\Bytes\H
        *Memory\B = Temp_Value\Bytes\G
        *Memory\C = Temp_Value\Bytes\F
        *Memory\D = Temp_Value\Bytes\E
        *Memory\E = Temp_Value\Bytes\D
        *Memory\F = Temp_Value\Bytes\C
        *Memory\G = Temp_Value\Bytes\B
        *Memory\H = Temp_Value\Bytes\A
        *Memory + 8
      Case #Tag_Float
        Temp_Value\Float = *Tag\Float
        *Memory\A = Temp_Value\Bytes\D
        *Memory\B = Temp_Value\Bytes\C
        *Memory\C = Temp_Value\Bytes\B
        *Memory\D = Temp_Value\Bytes\A
        *Memory + 4
      Case #Tag_Double
        Temp_Value\Double = *Tag\Double
        *Memory\A = Temp_Value\Bytes\H
        *Memory\B = Temp_Value\Bytes\G
        *Memory\C = Temp_Value\Bytes\F
        *Memory\D = Temp_Value\Bytes\E
        *Memory\E = Temp_Value\Bytes\D
        *Memory\F = Temp_Value\Bytes\C
        *Memory\G = Temp_Value\Bytes\B
        *Memory\H = Temp_Value\Bytes\A
        *Memory + 8
      Case #Tag_Byte_Array
        Temp_Value\Long = *Tag\Raw_Size
        *Memory\A = Temp_Value\Bytes\D
        *Memory\B = Temp_Value\Bytes\C
        *Memory\C = Temp_Value\Bytes\B
        *Memory\D = Temp_Value\Bytes\A
        *Memory + 4
        If *Tag\Raw And *Tag\Raw_Size
          CopyMemory(*Tag\Raw, *Memory, *Tag\Raw_Size)
        EndIf
        *Memory + *Tag\Raw_Size
      Case #Tag_String
        Temp_Value\Unicode = StringByteLength(*Tag\String, #PB_UTF8)
        *Memory\A = Temp_Value\Bytes\B
        *Memory\B = Temp_Value\Bytes\A
        *Memory + 2
        PokeS(*Memory, *Tag\String, -1, #PB_UTF8)
        *Memory + Temp_Value\Unicode
      Case #Tag_List
        Temp_Value\Byte = *Tag\List_Type
        *Memory\A = Temp_Value\Bytes\A
        *Memory + 1
        Temp_Value\Long = ListSize(*Tag\Child())
        *Memory\A = Temp_Value\Bytes\D
        *Memory\B = Temp_Value\Bytes\C
        *Memory\C = Temp_Value\Bytes\B
        *Memory\D = Temp_Value\Bytes\A
        *Memory + 4
        ForEach *Tag\Child()
          *Memory = Write_Ram_Helper(*Tag\Child(), *Memory)
        Next
      Case #Tag_Compound
        ForEach *Tag\Child()
          *Memory = Write_Ram_Helper(*Tag\Child(), *Memory)
        Next
        *Memory\A = 0 ; Tag_End
        *Memory + 1
      Case #Tag_Long_Array
        Temp_Value\Long = *Tag\Raw_Size
        *Memory\A = Temp_Value\Bytes\D
        *Memory\B = Temp_Value\Bytes\C
        *Memory\C = Temp_Value\Bytes\B
        *Memory\D = Temp_Value\Bytes\A
        *Memory + 4
        If *Tag\Raw And *Tag\Raw_Size*4
          CopyMemory(*Tag\Raw, *Memory, *Tag\Raw_Size*4)
        EndIf
        *Memory + *Tag\Raw_Size*4
    EndSelect
    
    ProcedureReturn *Memory
  EndProcedure
  
  Procedure Write_Ram(*Element.Element, *Memory, Memory_Size, Compression=#Compression_GZip)
    Protected *End_Adress, Written, Stream.ZLIB::z_stream
    Protected *Temp_Buffer, Compressed_Size, Window_Size
    
    If Not *Element
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Element is #Null>"
      ProcedureReturn 0
    EndIf
    
    If Compression = #Compression_GZip Or Compression = #Compression_ZLib
      
      *Temp_Buffer = AllocateMemory(Memory_Size)
      If Not *Temp_Buffer
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Memory_Size)+") failed>"
        ProcedureReturn 0
      EndIf
      
      *End_Adress = Write_Ram_Helper(*Element\Tag, *Temp_Buffer)
      If Not *End_Adress
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Write_Ram_Helper("+Str(*Element)+", "+Str(*Temp_Buffer)+") failed>"
        FreeMemory(*Temp_Buffer)
        ProcedureReturn 0
      EndIf
      
      Select Compression
        Case #Compression_GZip
          Window_Size = 15+16
        Case #Compression_ZLib
          Window_Size = 15
      EndSelect
      
      Stream\avail_in = Memory_Size
      Stream\avail_out = Memory_Size
      Stream\next_in = *Temp_Buffer
      Stream\next_out = *Memory
      
      If Not ZLIB::deflateInit2_(Stream, ZLIB::#Z_DEFAULT_COMPRESSION, ZLIB::#Z_DEFLATED, Window_Size, 8, ZLIB::#Z_DEFAULT_STRATEGY, ZLIB::ZLIBVersion(), SizeOf(ZLIB::z_stream)) = ZLIB::#Z_OK
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": deflateInit2_(Stream, #Z_DEFAULT_COMPRESSION, #Z_DEFLATED, Window_Size, 8, #Z_DEFAULT_STRATEGY, ZLIBVersion(), SizeOf(z_stream)) != #Z_OK>"
        FreeMemory(*Temp_Buffer)
        ProcedureReturn 0
      EndIf
      
      If Not ZLIB::deflate(Stream, ZLIB::#Z_FINISH) = ZLIB::#Z_STREAM_END
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": deflate(Stream, #Z_FINISH) != #Z_STREAM_END>"
        FreeMemory(*Temp_Buffer)
        ProcedureReturn 0
      EndIf
      Compressed_Size = Stream\total_out
      ZLIB::deflateEnd(Stream)
      
      FreeMemory(*Temp_Buffer)
      
      ProcedureReturn Compressed_Size
    Else
      *End_Adress = Write_Ram_Helper(*Element\Tag, *Memory)
      If Not *End_Adress
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Write_Ram_Helper("+Str(*Element)+", "+Str(*Memory)+") failed>"
        ProcedureReturn 0
      EndIf
      
      Written = *End_Adress - *Memory
      
      ProcedureReturn Written
    EndIf
  EndProcedure
  
  Procedure Write_File(*Element.Element, Filename.s, Compression=#Compression_GZip)
    Protected File_ID, *Temp_Buffer, Temp_Buffer_Size, Real_Size
    
    If Not *Element
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Element is #Null>"
      ProcedureReturn #False
    EndIf
    
    Temp_Buffer_Size = Get_Ram_Size(*Element)
    *Temp_Buffer = AllocateMemory(Temp_Buffer_Size)
    If Not *Temp_Buffer
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": AllocateMemory("+Str(Temp_Buffer_Size)+") failed>"
      ProcedureReturn #False
    EndIf
    
    Real_Size = Write_Ram(*Element, *Temp_Buffer, Temp_Buffer_Size, Compression)
    If Not Real_Size
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": Write_Ram(*Element, *Temp_Buffer, "+Str(Temp_Buffer_Size)+") failed>"
      FreeMemory(*Temp_Buffer)
      ProcedureReturn #False
    EndIf
    
    File_ID = CreateFile(#PB_Any, Filename)
    If Not File_ID
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": CreateFile(#PB_Any, "+Filename+") failed>"
      FreeMemory(*Temp_Buffer)
      ProcedureReturn #False
    EndIf
    
    WriteData(File_ID, *Temp_Buffer, Real_Size)
    
    CloseFile(File_ID)
    FreeMemory(*Temp_Buffer)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.s Tag_Serialize(*Tag.Tag, Level=0)
    Protected Output.s = Space(Level*2)
    
    If Not *Tag
      Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag is #Null>"
      ProcedureReturn "[Invalid_Element]"
    EndIf
    
    Select *Tag\Type
      Case #Tag_End
        Output + "[This shouldn't appear!]"
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": *Tag\Type = #Tag_End>"
      Case #Tag_Byte
        Output + "TAG_Byte('"+*Tag\Name+"'): "+Str(*Tag\Byte)
      Case #Tag_Word
        Output + "TAG_Word('"+*Tag\Name+"'): "+Str(*Tag\Word)
      Case #Tag_Long
        Output + "TAG_Long('"+*Tag\Name+"'): "+Str(*Tag\Long)
      Case #Tag_Quad
        Output + "TAG_Quad('"+*Tag\Name+"'): "+Str(*Tag\Quad)
      Case #Tag_Float
        Output + "TAG_Float('"+*Tag\Name+"'): "+StrF(*Tag\Float)
      Case #Tag_Double
        Output + "TAG_Double('"+*Tag\Name+"'): "+StrD(*Tag\Double)
      Case #Tag_Byte_Array
        Output + "TAG_Byte_Array('"+*Tag\Name+"'): ["+Str(*Tag\Raw_Size)+" bytes]"
      Case #Tag_String
        Output + "TAG_String('"+*Tag\Name+"'): '"+*Tag\String+"'"
      Case #Tag_List
        Output + "TAG_List('"+*Tag\Name+"'): "+Str(ListSize(*Tag\Child()))+" entries" + #CRLF$
        Output + Space(Level*2) + "{" + #CRLF$
        ForEach *Tag\Child()
          Output + Tag_Serialize(*Tag\Child(), Level+1) + #CRLF$
        Next
        Output + Space(Level*2) + "}"
      Case #Tag_Compound
        Output + "TAG_Compound('"+*Tag\Name+"'): "+Str(ListSize(*Tag\Child()))+" entries" + #CRLF$
        Output + Space(Level*2) + "{" + #CRLF$
        ForEach *Tag\Child()
          Output + Tag_Serialize(*Tag\Child(), Level+1) + #CRLF$
        Next
        Output + Space(Level*2) + "}"
      Case #Tag_Long_Array
        Output + "TAG_Long_Array('"+*Tag\Name+"'): ["+Str(*Tag\Raw_Size)+" longs]"
      Default
        Output + "[Something went really wrong here!]"
        Main\Error_String + "<"+#PB_Compiler_Procedure+"|"+Str(#PB_Compiler_Line)+": unknown: *Tag\Type = "+Str(*Tag\Type)+">"
    EndSelect
    
    ProcedureReturn Output
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 46
; FirstLine = 6
; Folding = -----
; EnableXP