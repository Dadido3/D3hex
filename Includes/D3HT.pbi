; ##################################################### License / Copyright #########################################
; 
;     The MIT License (MIT)
;     
;     Copyright (c) 2011-2015  David Vogel
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
; 
; D3HT - D3 HashTable
; 
; Version History:
; - 0.000 05.03.2011
; 
; - 1.000 05.03.2011
;     - Implemented everything
; 
; - 1.100 06.03.2011
;     - Optimised the code
;     - Added different algorithms
; 
; - 1.200 06.03.2011
;     - Optimised the code (CopyMemory instead of Movememory)
;     - Optimised Element_Set()
; 
; - 1.210 03.01.2015
;     - Element_Get now accepts *Value = #Null. In this case it will just return whether there is an element or not
; 
; - 1.211 29.06.2015
;     - Conversion to module
; 
; Documentation:
; - Table-Element:
;     - Metadata  (1 Byte)
;     - Key       (Depends on the Key_Size)
;     - Value     (Depends on the Value_Size)
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule D3HT
  EnableExplicit
  ; ################################################### Constants ###################################################
  #Version = 1211
  
  #Result_Fail = #False
  #Result_Success = #True
  
  #Default = -1
  
  Enumeration
    #Alg_CRC32
    #Alg_SDBM
    #Alg_Bernsteins
    #Alg_STL
  EndEnumeration
  
  ; ################################################### Functions ###################################################
  Declare   Element_Set(*Table, *Key.Ascii, *Value, Check_Collision=1)
  Declare   Element_Set_Byte(*Table, *Key, Value.b, Check_Collision=1)
  Declare   Element_Set_Ascii(*Table, *Key, Value.a, Check_Collision=1)
  Declare   Element_Set_Word(*Table, *Key, Value.w, Check_Collision=1)
  Declare   Element_Set_Unicode(*Table, *Key, Value.u, Check_Collision=1)
  Declare   Element_Set_Long(*Table, *Key, Value.l, Check_Collision=1)
  Declare   Element_Set_Quad(*Table, *Key, Value.q, Check_Collision=1)
  Declare   Element_Set_Integer(*Table, *Key, Value.i, Check_Collision=1)
  Declare   Element_Set_Float(*Table, *Key, Value.f, Check_Collision=1)
  Declare   Element_Set_Double(*Table, *Key, Value.d, Check_Collision=1)
  
  Declare   Element_Get(*Table, *Key.Ascii, *Value)
  Declare.b Element_Get_Byte(*Table, *Key)
  Declare.a Element_Get_Ascii(*Table, *Key)
  Declare.w Element_Get_Word(*Table, *Key)
  Declare.u Element_Get_Unicode(*Table, *Key)
  Declare.l Element_Get_Long(*Table, *Key)
  Declare.q Element_Get_Quad(*Table, *Key)
  Declare.i Element_Get_Integer(*Table, *Key)
  Declare.f Element_Get_Float(*Table, *Key)
  Declare.d Element_Get_Double(*Table, *Key)
  
  Declare   Element_Free(*Table, *Key.Ascii)
  
  Declare   Clear(*Table)
  Declare   Get_Elements(*Table)
  Declare   Get_Memoryusage(*Table)
  
  Declare   Create(Key_Size, Value_Size, Buffer_Elements=#Default, Sidesearch_Deep=#Default, Algorithm=#Alg_CRC32)
  Declare   Destroy(*Table)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module D3HT
  ; ################################################### Prototypes ##################################################
  Prototype Hash(*Key.Ascii, Key_Size, Start_Hash)
  
  ; ################################################### Constants ###################################################
  #Buffer_Elements_Default = 1024
  #Sidesearch_Deep_Default = 2
  
  ; ################################################### Structures / Variables ######################################
  Structure Table_Buffer
    Start_Hash.i
    
    *Memory
    
    Elements.i
  EndStructure
  
  Structure Table
    Element_Key_Size.i    ; Size of the Key of each Element
    Element_Value_Size.i  ; Size of the Value of each Element
    Element_Size.i        ; Size of each Element (Metadata + Key + Value)
    
    Hash_Mask.i           ; Mask for the hash, depends on Buffer_Elements
    
    Elements.i            ; Amount of elements
    Buffer_Elements.i     ; Elements per Buffer
    Sidesearch_Deep.i     ; Amount of iterations to search "sideways" (Slower, but more memory friendly)
    List Buffer.Table_Buffer()
    
    Hash_Function.Hash
  EndStructure
  
  ; ################################################### Procedures ##################################################
  Procedure Hash_CRC32(*Key.Ascii, Key_Size, Start_Hash)
    ProcedureReturn CRC32Fingerprint(*Key, Key_Size, Start_Hash)
  EndProcedure
  
  Procedure Hash_SDBM(*Key.Ascii, Key_Size, Start_Hash)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = *Key\a + (Start_Hash << 6) + (Start_Hash >> 16) - Start_Hash
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  Procedure Hash_Bernsteins(*Key.Ascii, Key_Size, Start_Hash)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = ((Start_Hash << 5) + Start_Hash) + *Key\a
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  Procedure Hash_STL(*Key.Ascii, Key_Size, Start_Hash)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = 5*Start_Hash + *Key\a
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  Procedure Create(Key_Size, Value_Size, Buffer_Elements=#Default, Sidesearch_Deep=#Default, Algorithm=#Alg_CRC32)
    Protected *Table.Table
    
    If Buffer_Elements < 0
      Buffer_Elements = #Buffer_Elements_Default
    EndIf
    
    Select Buffer_Elements
      Case 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608
      Default : ProcedureReturn #Result_Fail
    EndSelect
    
    If Not Key_Size > 0
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not Value_Size > 0
      ProcedureReturn #Result_Fail
    EndIf
    
    If Sidesearch_Deep < 0
      Sidesearch_Deep = #Sidesearch_Deep_Default
    EndIf
    
    *Table = AllocateMemory(SizeOf(Table))
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    InitializeStructure(*Table, Table)
    
    *Table\Hash_Mask = Buffer_Elements-1
    
    *Table\Buffer_Elements = Buffer_Elements
    *Table\Sidesearch_Deep = Sidesearch_Deep
    *Table\Element_Key_Size = Key_Size
    *Table\Element_Value_Size = Value_Size
    
    *Table\Element_Size = (1 + *Table\Element_Key_Size + *Table\Element_Value_Size)
    
    Select Algorithm
      Case #Alg_CRC32      : *Table\Hash_Function = @Hash_CRC32()
      Case #Alg_SDBM       : *Table\Hash_Function = @Hash_SDBM()
      Case #Alg_Bernsteins : *Table\Hash_Function = @Hash_Bernsteins()
      Case #Alg_STL        : *Table\Hash_Function = @Hash_STL()
      Default : Destroy(*Table) : ProcedureReturn #Result_Fail
    EndSelect
    
    ProcedureReturn *Table
  EndProcedure
  
  Procedure Destroy(*Table.Table)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    While LastElement(*Table\Buffer())
      If *Table\Buffer()\Memory
        FreeMemory(*Table\Buffer()\Memory)
      EndIf
      DeleteElement(*Table\Buffer())
    Wend
    
    ClearStructure(*Table, Table)
    FreeMemory(*Table)
    
    ProcedureReturn #Result_Success
  EndProcedure
  
  Procedure Clear(*Table.Table)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    While LastElement(*Table\Buffer())
      If *Table\Buffer()\Memory
        FreeMemory(*Table\Buffer()\Memory)
      EndIf
      DeleteElement(*Table\Buffer())
    Wend
    
    *Table\Elements = 0
    
    ProcedureReturn #Result_Success
  EndProcedure
  
  Procedure Get_Elements(*Table.Table)
    If Not *Table
      ProcedureReturn -1 ; Invalid amount of elements
    EndIf
    
    ProcedureReturn *Table\Elements
  EndProcedure
  
  Procedure Get_Memoryusage(*Table.Table)
    Protected Memoryusage = SizeOf(Table)
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    ForEach *Table\Buffer()
      Memoryusage + SizeOf(Table_Buffer)
      Memoryusage + MemorySize(*Table\Buffer()\Memory)
    Next
    
    ProcedureReturn Memoryusage
  EndProcedure
  
  Procedure Element_Set(*Table.Table, *Key.Ascii, *Value, Check_Collision=1)
    Protected Element_Pos
    Protected *Pointer.Ascii
    Protected Sidesearch_Iteration
    Protected *Free_Element_Buffer.Table_Buffer
    Protected Free_Element_Pos
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Key
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Value
      ProcedureReturn #Result_Fail
    EndIf
    
    If Check_Collision
      ; #### Look if the element already exists
      ForEach *Table\Buffer()
        Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
        
        Sidesearch_Iteration = *Table\Sidesearch_Deep + 1
        Repeat
          *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
          If *Pointer\a & $01 ; If element is used
            *Pointer + 1
            If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *Table\Element_Key_Size)
              ; #### Found element, overwrite its value now
              *Pointer + *Table\Element_Key_Size
              CopyMemory(*Value, *Pointer, *Table\Element_Value_Size)
              ProcedureReturn #Result_Success
            EndIf
          ElseIf Not *Free_Element_Buffer
            ; #### Element is unused, remeber it for later use
            *Free_Element_Buffer = *Table\Buffer()
            Free_Element_Pos = Element_Pos
          EndIf
          
          Element_Pos + 1
          Sidesearch_Iteration - 1
        Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Buffer_Elements
      Next
    Else
      ; #### Dont check for collisions, just search a free element.
      ForEach *Table\Buffer()
        Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
        
        Sidesearch_Iteration = *Table\Sidesearch_Deep + 1
        Repeat
          *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
          If Not *Pointer\a & $01 ; If element is unused
            ; #### Element is unused, remeber it for later use
            *Free_Element_Buffer = *Table\Buffer()
            Free_Element_Pos = Element_Pos
            Break 2
          EndIf
          
          Element_Pos + 1
          Sidesearch_Iteration - 1
        Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Buffer_Elements
      Next
    EndIf
    
    If *Free_Element_Buffer
    ; #### Haven't found the element, but i found a free position. Write the key and value now
      *Pointer = *Free_Element_Buffer\Memory + (Free_Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
      *Pointer\a | $01
      *Free_Element_Buffer\Elements + 1
      *Table\Elements + 1
      *Pointer + 1
      CopyMemory(*Key, *Pointer, *Table\Element_Key_Size)
      *Pointer + *Table\Element_Key_Size
      CopyMemory(*Value, *Pointer, *Table\Element_Value_Size)
      ProcedureReturn #Result_Success
    Else
      ; #### Haven't even found a free element in existing buffers, so create a new buffer...
      LastElement(*Table\Buffer())
      If Not AddElement(*Table\Buffer())
        ProcedureReturn #Result_Fail
      EndIf
      *Table\Buffer()\Memory = AllocateMemory(*Table\Buffer_Elements * *Table\Element_Size)
      If Not *Table\Buffer()\Memory
        DeleteElement(*Table\Buffer())
        ProcedureReturn #Result_Fail
      EndIf
      *Table\Buffer()\Start_Hash = Random(2147483647)
      
      Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
      
      *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
      
      ; #### write its key and value now
      *Pointer\a | $01
      *Table\Buffer()\Elements + 1
      *Table\Elements + 1
      *Pointer + 1
      CopyMemory(*Key, *Pointer, *Table\Element_Key_Size)
      *Pointer + *Table\Element_Key_Size
      CopyMemory(*Value, *Pointer, *Table\Element_Value_Size)
    EndIf
      
    ProcedureReturn #Result_Success
  EndProcedure
  
  Procedure Element_Set_Byte(*Table.Table, *Key, Value.b, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Byte)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Ascii(*Table.Table, *Key, Value.a, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Ascii)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Word(*Table.Table, *Key, Value.w, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Word)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Unicode(*Table.Table, *Key, Value.u, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Unicode)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Long(*Table.Table, *Key, Value.l, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Long)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Quad(*Table.Table, *Key, Value.q, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Quad)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Integer(*Table.Table, *Key, Value.i, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Integer)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Float(*Table.Table, *Key, Value.f, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Float)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Double(*Table.Table, *Key, Value.d, Check_Collision=1)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Double)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Get(*Table.Table, *Key.Ascii, *Value)
    Protected Element_Pos
    Protected *Pointer.Ascii
    Protected Sidesearch_Iteration
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Key
      ProcedureReturn #Result_Fail
    EndIf
    
    ;If Not *Value
    ;  ProcedureReturn #Result_Fail
    ;EndIf
    
    ; #### Look if the element already exists
    ForEach *Table\Buffer()
      Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
      
      Sidesearch_Iteration = *Table\Sidesearch_Deep + 1
      Repeat
        *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
        If *Pointer\a & $01 ; If element is used
          *Pointer + 1
          If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *Table\Element_Key_Size)
            ; #### Found element, return its value now
            *Pointer + *Table\Element_Key_Size
            If *Value
              CopyMemory(*Pointer, *Value, *Table\Element_Value_Size)
            EndIf
            ProcedureReturn #Result_Success
          EndIf
        EndIf
        
        Element_Pos + 1
        Sidesearch_Iteration - 1
      Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Buffer_Elements
    Next
    
    ProcedureReturn #Result_Fail
  EndProcedure
  
  Procedure.b Element_Get_Byte(*Table.Table, *Key)
    Protected Value.b
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Byte)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.a Element_Get_Ascii(*Table.Table, *Key)
    Protected Value.a
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Ascii)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.w Element_Get_Word(*Table.Table, *Key)
    Protected Value.w
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Word)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.u Element_Get_Unicode(*Table.Table, *Key)
    Protected Value.u
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Unicode)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.l Element_Get_Long(*Table.Table, *Key)
    Protected Value.l
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Long)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.q Element_Get_Quad(*Table.Table, *Key)
    Protected Value.q
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Quad)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.i Element_Get_Integer(*Table.Table, *Key)
    Protected Value.i
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Integer)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value
  EndProcedure
  
  Procedure.f Element_Get_Float(*Table.Table, *Key)
    Protected Value.f
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Float)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value 
  EndProcedure
  
  Procedure.d Element_Get_Double(*Table.Table, *Key)
    Protected Value.d
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Double)
      ProcedureReturn #Result_Fail
    EndIf
    
    Element_Get(*Table.Table, *Key, @Value)
    
    ProcedureReturn Value 
  EndProcedure
  
  Procedure Element_Free(*Table.Table, *Key.Ascii)
    Protected Element_Pos
    Protected *Pointer.Ascii
    Protected Sidesearch_Iteration
    
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Key
      ProcedureReturn #Result_Fail
    EndIf
    
    ; #### Look if the element already exists
    ForEach *Table\Buffer()
      Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
      
      Sidesearch_Iteration = *Table\Sidesearch_Deep + 1
      Repeat
        *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
        If *Pointer\a & $01 ; If element is used
          *Pointer + 1
          If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *Table\Element_Key_Size)
            ; #### Found element, delete it
            *Pointer - 1
            *Pointer\a & ~$01
            *Table\Buffer()\Elements - 1
            *Table\Elements - 1
            If *Table\Buffer()\Elements = 0
              ; #### No more elements in the buffer, delete it
              FreeMemory(*Table\Buffer()\Memory)
              DeleteElement(*Table\Buffer())
            EndIf
            ProcedureReturn #Result_Success
          EndIf
        EndIf
        
        Element_Pos + 1
        Sidesearch_Iteration - 1
      Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Buffer_Elements
    Next
    
    ProcedureReturn #Result_Fail
  EndProcedure
  
EndModule

; #################################################### Declares ##################################################



; #################################################### Macros ####################################################

; #################################################### Procedures ################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 506
; FirstLine = 27
; Folding = ------
; EnableXP
; DisableDebugger