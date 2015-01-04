; ##################################################### License / Copyright #########################################
; 
;     D3HT
;     Copyright (C) 2011-2015  David Vogel
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
;     - Optimised D3HT_Element_Set()
; 
; - 1.210 03.01.2015
;     - D3HT_Element_Get now accepts *Value = #Null. In this case it will just return whether there is an element or not
; 
; Documentation:
; - Table-Element:
;     - Metadata  (1 Byte)
;     - Key       (Depends on the Key_Size)
;     - Value     (Depends on the Value_Size)
; 
; #################################################### Constants #################################################

#D3HT_Version = 1210

#D3HT_Result_Fail = 0
#D3HT_Result_Success = 1

#D3HT_Default = -1

#D3HT_Buffer_Elements_Default = 1024
#D3HT_Sidesearch_Deep_Default = 2

Enumeration
  #D3HT_Alg_CRC32
  #D3HT_Alg_SDBM
  #D3HT_Alg_Bernsteins
  #D3HT_Alg_STL
EndEnumeration

; #################################################### Prototypes ################################################

Prototype D3HT_Hash(*Key.Ascii, Key_Size, Start_Hash)

; #################################################### Structures / Variables ####################################

Structure D3HT_Table_Buffer
  Start_Hash.i
  
  *Memory
  
  Elements.i
EndStructure

Structure D3HT_Table
  Element_Key_Size.i    ; Size of the Key of each Element
  Element_Value_Size.i  ; Size of the Value of each Element
  Element_Size.i        ; Size of each Element (Metadata + Key + Value)
  
  Hash_Mask.i           ; Mask for the hash, depends on Buffer_Elements
  
  Elements.i            ; Amount of elements
  Buffer_Elements.i     ; Elements per Buffer
  Sidesearch_Deep.i     ; Amount of iterations to search "sideways" (Slower, but more memory friendly)
  List Buffer.D3HT_Table_Buffer()
  
  Hash_Function.D3HT_Hash
EndStructure

; #################################################### Declares ##################################################

Declare   D3HT_Destroy(*D3HT_Table.D3HT_Table)

; #################################################### Macros ####################################################

; #################################################### Procedures ################################################

Procedure D3HT_Hash_CRC32(*Key.Ascii, Key_Size, Start_Hash)
  ProcedureReturn CRC32Fingerprint(*Key, Key_Size, Start_Hash)
EndProcedure

Procedure D3HT_Hash_SDBM(*Key.Ascii, Key_Size, Start_Hash)
  Protected i
  
  For i = 1 To Key_Size
    Start_Hash = *Key\a + (Start_Hash << 6) + (Start_Hash >> 16) - Start_Hash
    *Key + 1
  Next
  
  ProcedureReturn Start_Hash
EndProcedure

Procedure D3HT_Hash_Bernsteins(*Key.Ascii, Key_Size, Start_Hash)
  Protected i
  
  For i = 1 To Key_Size
    Start_Hash = ((Start_Hash << 5) + Start_Hash) + *Key\a
    *Key + 1
  Next
  
  ProcedureReturn Start_Hash
EndProcedure

Procedure D3HT_Hash_STL(*Key.Ascii, Key_Size, Start_Hash)
  Protected i
  
  For i = 1 To Key_Size
    Start_Hash = 5*Start_Hash + *Key\a
    *Key + 1
  Next
  
  ProcedureReturn Start_Hash
EndProcedure

Procedure D3HT_Create(Key_Size, Value_Size, Buffer_Elements=-1, Sidesearch_Deep=-1, Algorithm=#D3HT_Alg_CRC32)
  Protected *D3HT_Table.D3HT_Table
  
  If Buffer_Elements < 0
    Buffer_Elements = #D3HT_Buffer_Elements_Default
  EndIf
  
  Select Buffer_Elements
    Case 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608
    Default : ProcedureReturn #D3HT_Result_Fail
  EndSelect
  
  If Not Key_Size > 0
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not Value_Size > 0
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Sidesearch_Deep < 0
    Sidesearch_Deep = #D3HT_Sidesearch_Deep_Default
  EndIf
  
  *D3HT_Table = AllocateMemory(SizeOf(D3HT_Table))
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  InitializeStructure(*D3HT_Table, D3HT_Table)
  
  *D3HT_Table\Hash_Mask = Buffer_Elements-1
  
  *D3HT_Table\Buffer_Elements = Buffer_Elements
  *D3HT_Table\Sidesearch_Deep = Sidesearch_Deep
  *D3HT_Table\Element_Key_Size = Key_Size
  *D3HT_Table\Element_Value_Size = Value_Size
  
  *D3HT_Table\Element_Size = (1 + *D3HT_Table\Element_Key_Size + *D3HT_Table\Element_Value_Size)
  
  Select Algorithm
    Case #D3HT_Alg_CRC32      : *D3HT_Table\Hash_Function = @D3HT_Hash_CRC32()
    Case #D3HT_Alg_SDBM       : *D3HT_Table\Hash_Function = @D3HT_Hash_SDBM()
    Case #D3HT_Alg_Bernsteins : *D3HT_Table\Hash_Function = @D3HT_Hash_Bernsteins()
    Case #D3HT_Alg_STL        : *D3HT_Table\Hash_Function = @D3HT_Hash_STL()
    Default : D3HT_Destroy(*D3HT_Table) : ProcedureReturn #D3HT_Result_Fail
  EndSelect
  
  ProcedureReturn *D3HT_Table
EndProcedure

Procedure D3HT_Destroy(*D3HT_Table.D3HT_Table)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  While LastElement(*D3HT_Table\Buffer())
    If *D3HT_Table\Buffer()\Memory
      FreeMemory(*D3HT_Table\Buffer()\Memory)
    EndIf
    DeleteElement(*D3HT_Table\Buffer())
  Wend
  
  ClearStructure(*D3HT_Table, D3HT_Table)
  FreeMemory(*D3HT_Table)
  
  ProcedureReturn #D3HT_Result_Success
EndProcedure

Procedure D3HT_Clear(*D3HT_Table.D3HT_Table)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  While LastElement(*D3HT_Table\Buffer())
    If *D3HT_Table\Buffer()\Memory
      FreeMemory(*D3HT_Table\Buffer()\Memory)
    EndIf
    DeleteElement(*D3HT_Table\Buffer())
  Wend
  
  *D3HT_Table\Elements = 0
  
  ProcedureReturn #D3HT_Result_Success
EndProcedure

Procedure D3HT_Get_Elements(*D3HT_Table.D3HT_Table)
  If Not *D3HT_Table
    ProcedureReturn -1 ; Invalid amount of elements
  EndIf
  
  ProcedureReturn *D3HT_Table\Elements
EndProcedure

Procedure D3HT_Get_Memoryusage(*D3HT_Table.D3HT_Table)
  Protected Memoryusage = SizeOf(D3HT_Table)
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ForEach *D3HT_Table\Buffer()
    Memoryusage + SizeOf(D3HT_Table_Buffer)
    Memoryusage + MemorySize(*D3HT_Table\Buffer()\Memory)
  Next
  
  ProcedureReturn Memoryusage
EndProcedure

Procedure D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key.Ascii, *Value, Check_Collision=1)
  Protected Element_Pos
  Protected *Pointer.Ascii
  Protected Sidesearch_Iteration
  Protected *Free_Element_Buffer.D3HT_Table_Buffer
  Protected Free_Element_Pos
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *Key
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *Value
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Check_Collision
    ; #### Look if the element already exists
    ForEach *D3HT_Table\Buffer()
      Element_Pos = *D3HT_Table\Hash_Function(*Key, *D3HT_Table\Element_Key_Size, *D3HT_Table\Buffer()\Start_Hash)
      
      Sidesearch_Iteration = *D3HT_Table\Sidesearch_Deep + 1
      Repeat
        *Pointer = *D3HT_Table\Buffer()\Memory + (Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
        If *Pointer\a & $01 ; If element is used
          *Pointer + 1
          If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *D3HT_Table\Element_Key_Size)
            ; #### Found element, overwrite its value now
            *Pointer + *D3HT_Table\Element_Key_Size
            CopyMemory(*Value, *Pointer, *D3HT_Table\Element_Value_Size)
            ProcedureReturn #D3HT_Result_Success
          EndIf
        ElseIf Not *Free_Element_Buffer
          ; #### Element is unused, remeber it for later use
          *Free_Element_Buffer = *D3HT_Table\Buffer()
          Free_Element_Pos = Element_Pos
        EndIf
        
        Element_Pos + 1
        Sidesearch_Iteration - 1
      Until Sidesearch_Iteration = 0; Or Element_Pos = *D3HT_Table\Buffer_Elements
    Next
  Else
    ; #### Dont check for collisions, just search a free element.
    ForEach *D3HT_Table\Buffer()
      Element_Pos = *D3HT_Table\Hash_Function(*Key, *D3HT_Table\Element_Key_Size, *D3HT_Table\Buffer()\Start_Hash)
      
      Sidesearch_Iteration = *D3HT_Table\Sidesearch_Deep + 1
      Repeat
        *Pointer = *D3HT_Table\Buffer()\Memory + (Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
        If Not *Pointer\a & $01 ; If element is unused
          ; #### Element is unused, remeber it for later use
          *Free_Element_Buffer = *D3HT_Table\Buffer()
          Free_Element_Pos = Element_Pos
          Break 2
        EndIf
        
        Element_Pos + 1
        Sidesearch_Iteration - 1
      Until Sidesearch_Iteration = 0; Or Element_Pos = *D3HT_Table\Buffer_Elements
    Next
  EndIf
  
  If *Free_Element_Buffer
  ; #### Haven't found the element, but i found a free position. Write the key and value now
    *Pointer = *Free_Element_Buffer\Memory + (Free_Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
    *Pointer\a | $01
    *Free_Element_Buffer\Elements + 1
    *D3HT_Table\Elements + 1
    *Pointer + 1
    CopyMemory(*Key, *Pointer, *D3HT_Table\Element_Key_Size)
    *Pointer + *D3HT_Table\Element_Key_Size
    CopyMemory(*Value, *Pointer, *D3HT_Table\Element_Value_Size)
    ProcedureReturn #D3HT_Result_Success
  Else
    ; #### Haven't even found a free element in existing buffers, so create a new buffer...
    LastElement(*D3HT_Table\Buffer())
    If Not AddElement(*D3HT_Table\Buffer())
      ProcedureReturn #D3HT_Result_Fail
    EndIf
    *D3HT_Table\Buffer()\Memory = AllocateMemory(*D3HT_Table\Buffer_Elements * *D3HT_Table\Element_Size)
    If Not *D3HT_Table\Buffer()\Memory
      DeleteElement(*D3HT_Table\Buffer())
      ProcedureReturn #D3HT_Result_Fail
    EndIf
    *D3HT_Table\Buffer()\Start_Hash = Random(2147483647)
    
    Element_Pos = *D3HT_Table\Hash_Function(*Key, *D3HT_Table\Element_Key_Size, *D3HT_Table\Buffer()\Start_Hash)
    
    *Pointer = *D3HT_Table\Buffer()\Memory + (Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
    
    ; #### write its key and value now
    *Pointer\a | $01
    *D3HT_Table\Buffer()\Elements + 1
    *D3HT_Table\Elements + 1
    *Pointer + 1
    CopyMemory(*Key, *Pointer, *D3HT_Table\Element_Key_Size)
    *Pointer + *D3HT_Table\Element_Key_Size
    CopyMemory(*Value, *Pointer, *D3HT_Table\Element_Value_Size)
  EndIf
    
  ProcedureReturn #D3HT_Result_Success
EndProcedure

Procedure D3HT_Element_Set_Byte(*D3HT_Table.D3HT_Table, *Key, Value.b, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Byte)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Ascii(*D3HT_Table.D3HT_Table, *Key, Value.a, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Ascii)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Word(*D3HT_Table.D3HT_Table, *Key, Value.w, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Word)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Unicode(*D3HT_Table.D3HT_Table, *Key, Value.u, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Unicode)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Long(*D3HT_Table.D3HT_Table, *Key, Value.l, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Long)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Quad(*D3HT_Table.D3HT_Table, *Key, Value.q, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Quad)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Integer(*D3HT_Table.D3HT_Table, *Key, Value.i, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Integer)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Float(*D3HT_Table.D3HT_Table, *Key, Value.f, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Float)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Set_Double(*D3HT_Table.D3HT_Table, *Key, Value.d, Check_Collision=1)
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Double)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ProcedureReturn D3HT_Element_Set(*D3HT_Table.D3HT_Table, *Key, @Value, Check_Collision)
EndProcedure

Procedure D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key.Ascii, *Value)
  Protected Element_Pos
  Protected *Pointer.Ascii
  Protected Sidesearch_Iteration
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *Key
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ;If Not *Value
  ;  ProcedureReturn #D3HT_Result_Fail
  ;EndIf
  
  ; #### Look if the element already exists
  ForEach *D3HT_Table\Buffer()
    Element_Pos = *D3HT_Table\Hash_Function(*Key, *D3HT_Table\Element_Key_Size, *D3HT_Table\Buffer()\Start_Hash)
    
    Sidesearch_Iteration = *D3HT_Table\Sidesearch_Deep + 1
    Repeat
      *Pointer = *D3HT_Table\Buffer()\Memory + (Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
      If *Pointer\a & $01 ; If element is used
        *Pointer + 1
        If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *D3HT_Table\Element_Key_Size)
          ; #### Found element, return its value now
          *Pointer + *D3HT_Table\Element_Key_Size
          If *Value
            CopyMemory(*Pointer, *Value, *D3HT_Table\Element_Value_Size)
          EndIf
          ProcedureReturn #D3HT_Result_Success
        EndIf
      EndIf
      
      Element_Pos + 1
      Sidesearch_Iteration - 1
    Until Sidesearch_Iteration = 0; Or Element_Pos = *D3HT_Table\Buffer_Elements
  Next
  
  ProcedureReturn #D3HT_Result_Fail
EndProcedure

Procedure.b D3HT_Element_Get_Byte(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.b
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Byte)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.a D3HT_Element_Get_Ascii(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.a
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Ascii)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.w D3HT_Element_Get_Word(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.w
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Word)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.u D3HT_Element_Get_Unicode(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.u
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Unicode)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.l D3HT_Element_Get_Long(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.l
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Long)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.q D3HT_Element_Get_Quad(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.q
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Quad)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.i D3HT_Element_Get_Integer(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.i
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Integer)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value
EndProcedure

Procedure.f D3HT_Element_Get_Float(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.f
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Float)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value 
EndProcedure

Procedure.d D3HT_Element_Get_Double(*D3HT_Table.D3HT_Table, *Key)
  Protected Value.d
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *D3HT_Table\Element_Value_Size = SizeOf(Double)
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  D3HT_Element_Get(*D3HT_Table.D3HT_Table, *Key, @Value)
  
  ProcedureReturn Value 
EndProcedure

Procedure D3HT_Element_Free(*D3HT_Table.D3HT_Table, *Key.Ascii)
  Protected Element_Pos
  Protected *Pointer.Ascii
  Protected Sidesearch_Iteration
  
  If Not *D3HT_Table
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  If Not *Key
    ProcedureReturn #D3HT_Result_Fail
  EndIf
  
  ; #### Look if the element already exists
  ForEach *D3HT_Table\Buffer()
    Element_Pos = *D3HT_Table\Hash_Function(*Key, *D3HT_Table\Element_Key_Size, *D3HT_Table\Buffer()\Start_Hash)
    
    Sidesearch_Iteration = *D3HT_Table\Sidesearch_Deep + 1
    Repeat
      *Pointer = *D3HT_Table\Buffer()\Memory + (Element_Pos & *D3HT_Table\Hash_Mask) * *D3HT_Table\Element_Size
      If *Pointer\a & $01 ; If element is used
        *Pointer + 1
        If *Pointer\a = *Key\a And CompareMemory(*Key, *Pointer, *D3HT_Table\Element_Key_Size)
          ; #### Found element, delete it
          *Pointer - 1
          *Pointer\a & ~$01
          *D3HT_Table\Buffer()\Elements - 1
          *D3HT_Table\Elements - 1
          If *D3HT_Table\Buffer()\Elements = 0
            ; #### No more elements in the buffer, delete it
            FreeMemory(*D3HT_Table\Buffer()\Memory)
            DeleteElement(*D3HT_Table\Buffer())
          EndIf
          ProcedureReturn #D3HT_Result_Success
        EndIf
      EndIf
      
      Element_Pos + 1
      Sidesearch_Iteration - 1
    Until Sidesearch_Iteration = 0; Or Element_Pos = *D3HT_Table\Buffer_Elements
  Next
  
  ProcedureReturn #D3HT_Result_Fail
EndProcedure
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 186
; FirstLine = 134
; Folding = ------
; EnableXP
; DisableDebugger