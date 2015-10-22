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
; Maps a fixed length key to a fixed length value
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
; - 1.300 22.10.2015
;     - Added several hashing algorithms:
;       - MurmurHash3
;       - MeiyanHash
;       - FNV32
;     - Improved CRC32
;     - Refactoring and cleanup of the code
; 
; Documentation:
; - Table-Element:
;     - Metadata  (1 Byte)
;     - Key       (Depends on the Key_Size)
;     - Value     (Depends on the Value_Size)
; 
; Tips and tricks:
; - Lower the sidesearch depth for more speed (And less memory efficiency)
; - Set Table_Size a bit larger than the amount of objects the list should contain --> good speed/memory tradeoff
;   - Table_Size too large --> list needs more memory than necessary
;   - Table_Size too small --> operations will be slow
; - #Alg_CRC32 seems best for most cases
; - #Alg_FNV32 in combination with a huge table size can be faster than #Alg_CRC32, but it is more memory intensive
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule D3HT
  EnableExplicit
  ; ################################################### Constants ###################################################
  #Version = 1300
  
  #Result_Fail = #False
  #Result_Success = #True
  
  #Default = -1
  
  Enumeration
    #Alg_CRC32
    ;#Alg_ADLER32
    #Alg_SDBM
    #Alg_Bernsteins
    #Alg_STL
    #Alg_MurmurHash3
    #Alg_MeiyanHash
    #Alg_FNV32
  EndEnumeration
  
  ; ################################################### Functions ###################################################
  Declare   Element_Set(*Table, *Key, *Value, Check_Collision=#True)
  Declare   Element_Set_Byte(*Table, *Key, Value.b, Check_Collision=#True)
  Declare   Element_Set_Ascii(*Table, *Key, Value.a, Check_Collision=#True)
  Declare   Element_Set_Word(*Table, *Key, Value.w, Check_Collision=#True)
  Declare   Element_Set_Unicode(*Table, *Key, Value.u, Check_Collision=#True)
  Declare   Element_Set_Long(*Table, *Key, Value.l, Check_Collision=#True)
  Declare   Element_Set_Quad(*Table, *Key, Value.q, Check_Collision=#True)
  Declare   Element_Set_Integer(*Table, *Key, Value.i, Check_Collision=#True)
  Declare   Element_Set_Float(*Table, *Key, Value.f, Check_Collision=#True)
  Declare   Element_Set_Double(*Table, *Key, Value.d, Check_Collision=#True)
  
  Declare   Element_Get(*Table, *Key, *Value)
  Declare.b Element_Get_Byte(*Table, *Key)
  Declare.a Element_Get_Ascii(*Table, *Key)
  Declare.w Element_Get_Word(*Table, *Key)
  Declare.u Element_Get_Unicode(*Table, *Key)
  Declare.l Element_Get_Long(*Table, *Key)
  Declare.q Element_Get_Quad(*Table, *Key)
  Declare.i Element_Get_Integer(*Table, *Key)
  Declare.f Element_Get_Float(*Table, *Key)
  Declare.d Element_Get_Double(*Table, *Key)
  
  Declare   Element_Free(*Table, *Key)
  
  Declare   Clear(*Table)
  Declare   Get_Elements(*Table)
  Declare   Get_Memoryusage(*Table)
  
  Declare   Create(Key_Size, Value_Size, Table_Size=#Default, Sidesearch_Depth=#Default, Algorithm=#Alg_CRC32)
  Declare   Destroy(*Table)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module D3HT
  ; ################################################### Imports #####################################################
  ;ImportC "zlib.lib"
  ;  adler32 (adler.l, *buf, len.l)
  ;EndImport
  
  ; ################################################### Prototypes ##################################################
  Prototype.l Hash(*Key.Ascii, Key_Size, Start_Hash.l)
  
  ; ################################################### Constants ###################################################
  #Table_Size_Default = 16384
  #Sidesearch_Depth_Default = 1
  
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
    
    Hash_Mask.i           ; Mask for the hash, depends on Table_Size
    
    Elements.i            ; Amount of elements
    Table_Size.i          ; Elements per Buffer
    Sidesearch_Depth.i    ; Amount of iterations to search "sideways" (Slower, but more memory friendly)
    List Buffer.Table_Buffer()
    
    Hash_Function.Hash
  EndStructure
  
  ; ################################################### Procedures ##################################################
  Procedure.l Hash_CRC32(*Key.Ascii, Key_Size, Start_Hash.l)
    EnableASM
    
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      ;push  esi ;TODO: preserve esi register!
      mov   esi, *Key
      mov   eax, Start_Hash
      XOr   edx, edx
      Or    eax, -1
      mov   ecx, Key_Size
      
      loop:
      mov   dl, [esi]
      XOr   dl, al
      shr   eax, 8
      inc   esi
      XOr   eax, [d3ht.l_crc32_table + 4*edx]
      dec   ecx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [esi]
      XOr   dl, al
      shr   eax, 8
      inc   esi
      XOr   eax, [d3ht.l_crc32_table + 4*edx]
      dec   ecx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [esi]
      XOr   dl, al
      shr   eax, 8
      inc   esi
      XOr   eax, [d3ht.l_crc32_table + 4*edx]
      dec   ecx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [esi]
      XOr   dl, al
      shr   eax, 8
      inc   esi
      XOr   eax, [d3ht.l_crc32_table + 4*edx]
      dec   ecx
      jnz   d3ht.ll_hash_crc32_loop
      
      quit:
      Not   eax
      ;pop   esi
    CompilerElse
      mov   r9, d3ht.l_crc32_table
      mov   r8, *Key
      mov   eax, Start_Hash
      XOr   rdx, rdx
      Or    eax, -1
      mov   rcx, Key_Size
      
      loop:
      mov   dl, [r8]
      XOr   dl, al
      shr   eax, 8
      inc   r8
      XOr   eax, [r9 + 4*rdx]
      dec   rcx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [r8]
      XOr   dl, al
      shr   eax, 8
      inc   r8
      XOr   eax, [r9 + 4*rdx]
      dec   rcx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [r8]
      XOr   dl, al
      shr   eax, 8
      inc   r8
      XOr   eax, [r9 + 4*rdx]
      dec   rcx
      jz    d3ht.ll_hash_crc32_quit
      
      ; #### unrolling
      mov   dl, [r8]
      XOr   dl, al
      shr   eax, 8
      inc   r8
      XOr   eax, [r9 + 4*rdx]
      dec   rcx
      jnz   d3ht.ll_hash_crc32_loop
      
      quit:
      Not   eax
    CompilerEndIf
    
    DisableASM
    
    ProcedureReturn
  EndProcedure
  
  ;Procedure.l Hash_ADLER32(*Key.Ascii, Key_Size, Start_Hash.l)
  ;  ProcedureReturn adler32(Start_Hash, *Key, Key_Size)
  ;EndProcedure
  
  Procedure.l Hash_SDBM(*Key.Ascii, Key_Size, Start_Hash.l)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = *Key\a + (Start_Hash << 6) + (Start_Hash >> 16) - Start_Hash
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  Procedure.l Hash_Bernsteins(*Key.Ascii, Key_Size, Start_Hash.l)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = ((Start_Hash << 5) + Start_Hash) + *Key\a
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  Procedure.l Hash_STL(*Key.Ascii, Key_Size, Start_Hash.l)
    Protected i
    
    For i = 1 To Key_Size
      Start_Hash = 5*Start_Hash + *Key\a
      *Key + 1
    Next
    
    ProcedureReturn Start_Hash
  EndProcedure
  
  ; **********************************************
  ; * MurmurHash3 was written by Austin Appleby, *
  ; * and is placed in the public domain.        *
  ; * The author disclaims copyright to this     *
  ; * source code.                               *
  ; *                                            *
  ; * PureBasic conversion by Wilbert            *
  ; * Last update : 2012/02/29                   *
  ; **********************************************
  Procedure.l Hash_MurmurHash3(*Key.Ascii, Key_Size.l, Start_Hash.l)
    EnableASM
    MOV eax, Start_Hash
    MOV ecx, Key_Size
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      MOV edx, *Key
      !push ebx
      !push ecx
    CompilerElse
      MOV rdx, *Key
      !push rbx
      !push rcx
    CompilerEndIf
    !mov ebx, eax
    !sub ecx, 4
    !js mh3_tail
    ; body
    !mh3_body_loop:
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !mov eax, [edx]
      !add edx, 4
    CompilerElse
      !mov eax, [rdx]
      !add rdx, 4
    CompilerEndIf
    !imul eax, 0xcc9e2d51
    !rol eax, 15
    !imul eax, 0x1b873593
    !xor ebx, eax
    !rol ebx, 13
    !imul ebx, 5
    !add ebx, 0xe6546b64
    !sub ecx, 4
    !jns mh3_body_loop
    ; tail
    !mh3_tail:
    !xor eax, eax
    !add ecx, 3
    !js mh3_finalize
    !jz mh3_t1
    !dec ecx
    !jz mh3_t2
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !mov al, [edx + 2]
      !shl eax, 16
      !mh3_t2: mov ah, [edx + 1]
      !mh3_t1: mov al, [edx]
    CompilerElse
      !mov al, [rdx + 2]
      !shl eax, 16
      !mh3_t2: mov ah, [rdx + 1]
      !mh3_t1: mov al, [rdx]
    CompilerEndIf
    !imul eax, 0xcc9e2d51
    !rol eax, 15
    !imul eax, 0x1b873593
    !xor ebx, eax
    ; finalization
    !mh3_finalize:
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !pop ecx
    CompilerElse
      !pop rcx
    CompilerEndIf
    !xor ebx, ecx
    !mov eax, ebx
    !shr ebx, 16
    !xor eax, ebx
    !imul eax, 0x85ebca6b
    !mov ebx, eax
    !shr ebx, 13
    !xor eax, ebx
    !imul eax, 0xc2b2ae35
    !mov ebx, eax
    !shr ebx, 16
    !xor eax, ebx
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !pop ebx
    CompilerElse
      !pop rbx 
    CompilerEndIf
    DisableASM
    ProcedureReturn
  EndProcedure
  
  ; ******************************************
  ; * The Meiyan hash algorithm              *
  ; * was written by Sanmayce                *
  ; * http://www.sanmayce.com/Fastest_Hash/  *
  ; *                                        *
  ; * PureBasic conversion by Wilbert        *
  ; * Last update : 2012/03/09               *
  ; ******************************************
  Procedure.l Hash_MeiyanHash(*Key.Ascii, Key_Size.l, Start_Hash.l)
    EnableASM
    MOV eax, Start_Hash
    MOV ecx, Key_Size
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      MOV edx, *Key
      !push ebx
      !mov ebx, edx
    CompilerElse
      MOV r8, *Key
    CompilerEndIf
    !sub ecx, 8
    !js meiyan_tail
    ; body
    !meiyan_body_loop:
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !mov edx, [ebx]
      !rol edx, 5
      !xor eax, edx
      !mov edx, [ebx + 4]
      !add ebx, 8
    CompilerElse
      !mov edx, [r8]
      !rol edx, 5
      !xor eax, edx
      !mov edx, [r8 + 4]
      !add r8, 8
    CompilerEndIf
    !xor eax, edx
    !imul eax, 709607
    !sub ecx, 8
    !jns meiyan_body_loop
    ; tail
    !meiyan_tail:
    !add ecx, 8
    !test ecx, 4
    !jz meiyan_t2
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !movzx edx, word [ebx]
      !xor eax, edx
      !imul eax, 709607
      !movzx edx, word [ebx + 2]
      !add ebx, 4
    CompilerElse
      !movzx edx, word [r8]
      !xor eax, edx
      !imul eax, 709607
      !movzx edx, word [r8 + 2]
      !add r8, 4
    CompilerEndIf
    !xor eax, edx
    !imul eax, 709607
    !meiyan_t2:
    !test ecx, 2
    !jz meiyan_t3
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !movzx edx, word [ebx]
      !add ebx, 2
    CompilerElse
      !movzx edx, word [r8]
      !add r8, 2
    CompilerEndIf
    !xor eax, edx
    !imul eax, 709607
    !meiyan_t3:
    !test ecx, 1
    !jz meiyan_t4
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !movzx edx, byte [ebx]
    CompilerElse
      !movzx edx, byte [r8]
    CompilerEndIf
    !xor eax, edx
    !imul eax, 709607
    !meiyan_t4:
    !mov edx, eax
    !shr edx, 16
    !xor eax, edx
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      !pop ebx
    CompilerEndIf
    DisableASM
    ProcedureReturn
  EndProcedure
  
  ; #### Source: http://www.purebasic.fr/english/viewtopic.php?p=43376
  ; #### (Wayne Diamond)
  Procedure.l Hash_FNV32(*Key.Ascii, Key_Size, Start_Hash.l)
    EnableASM
    
    ;TODO: Preserve esi, edi and ebx
    
    CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      MOV esi, *Key           ;esi = ptr to buffer
      MOV ecx, Key_Size       ;ecx = length of buffer (counter)
      MOV eax, Start_Hash     ;set to 0 for FNV-0, or 2166136261 for FNV-1
      MOV edi, $01000193      ;FNV_32_PRIME = 16777619
      XOr ebx, ebx            ;ebx = 0
      
      loop:
      MUL edi                 ;eax = eax * FNV_32_PRIME
      MOV bl, [esi]           ;bl = byte from esi
      XOr eax, ebx            ;al = al xor bl
      INC esi                 ;esi = esi + 1 (buffer pos)
      DEC ecx                 ;ecx = ecx - 1 (counter)
      JNZ d3ht.ll_hash_fnv32_loop ;if ecx is 0, jmp to NextByte
    CompilerElse
      MOV r8, *Key            ;esi = ptr to buffer
      MOV rcx, Key_Size       ;ecx = length of buffer (counter)
      MOV eax, Start_Hash     ;set to 0 for FNV-0, or 2166136261 for FNV-1
      MOV r9, $01000193       ;FNV_32_PRIME = 16777619
      XOr ebx, ebx            ;ebx = 0
      
      loop:
      MUL r9                  ;eax = eax * FNV_32_PRIME
      MOV bl, [r8]            ;bl = byte from esi
      XOr eax, ebx            ;al = al xor bl
      INC r8                  ;esi = esi + 1 (buffer pos)
      DEC rcx                 ;ecx = ecx - 1 (counter)
      JNZ d3ht.ll_hash_fnv32_loop ;if ecx is 0, jmp to NextByte
    CompilerEndIf
    
    DisableASM
    ProcedureReturn
  EndProcedure
  
  Procedure Create(Key_Size, Value_Size, Table_Size=#Default, Sidesearch_Depth=#Default, Algorithm=#Alg_CRC32)
    Protected *Table.Table
    
    If Table_Size < 0
      Table_Size = #Table_Size_Default
    EndIf
    
    Select Table_Size
      Case 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608
      Default : ProcedureReturn #Result_Fail
    EndSelect
    
    If Not Key_Size > 0
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not Value_Size > 0
      ProcedureReturn #Result_Fail
    EndIf
    
    If Sidesearch_Depth < 0
      Sidesearch_Depth = #Sidesearch_Depth_Default
    EndIf
    
    *Table = AllocateStructure(Table)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    *Table\Hash_Mask = Table_Size-1
    
    *Table\Table_Size = Table_Size
    *Table\Sidesearch_Depth = Sidesearch_Depth
    *Table\Element_Key_Size = Key_Size
    *Table\Element_Value_Size = Value_Size
    
    *Table\Element_Size = (1 + *Table\Element_Key_Size + *Table\Element_Value_Size)
    
    Select Algorithm
      Case #Alg_CRC32           : *Table\Hash_Function = @Hash_CRC32()
      ;Case #Alg_ADLER32         : *Table\Hash_Function = @Hash_ADLER32()
      Case #Alg_SDBM            : *Table\Hash_Function = @Hash_SDBM()
      Case #Alg_Bernsteins      : *Table\Hash_Function = @Hash_Bernsteins()
      Case #Alg_STL             : *Table\Hash_Function = @Hash_STL()
      Case #Alg_MurmurHash3     : *Table\Hash_Function = @Hash_MurmurHash3()
      Case #Alg_MeiyanHash      : *Table\Hash_Function = @Hash_MeiyanHash()
      Case #Alg_FNV32           : *Table\Hash_Function = @Hash_FNV32()
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
    
    FreeStructure(*Table)
    
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
  
  Procedure Element_Set(*Table.Table, *Key.Ascii, *Value, Check_Collision=#True)
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
        
        Sidesearch_Iteration = *Table\Sidesearch_Depth + 1
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
            ; #### Element is unused, remember it for later use
            *Free_Element_Buffer = *Table\Buffer()
            Free_Element_Pos = Element_Pos
          EndIf
          
          Element_Pos + 1
          Sidesearch_Iteration - 1
        Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Table_Size
      Next
    Else
      ; #### Dont check for collisions, just search a free element.
      ForEach *Table\Buffer()
        Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
        
        Sidesearch_Iteration = *Table\Sidesearch_Depth + 1
        Repeat
          *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
          If Not *Pointer\a & $01 ; If element is unused
            ; #### Element is unused, remember it for later use
            *Free_Element_Buffer = *Table\Buffer()
            Free_Element_Pos = Element_Pos
            Break 2
          EndIf
          
          Element_Pos + 1
          Sidesearch_Iteration - 1
        Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Table_Size
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
      *Table\Buffer()\Memory = AllocateMemory(*Table\Table_Size * *Table\Element_Size)
      If Not *Table\Buffer()\Memory
        DeleteElement(*Table\Buffer())
        ProcedureReturn #Result_Fail
      EndIf
      *Table\Buffer()\Start_Hash = Random(2147483647)
      
      Element_Pos = *Table\Hash_Function(*Key, *Table\Element_Key_Size, *Table\Buffer()\Start_Hash)
      
      *Pointer = *Table\Buffer()\Memory + (Element_Pos & *Table\Hash_Mask) * *Table\Element_Size
      
      ; #### Now write the key and value
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
  
  Procedure Element_Set_Byte(*Table.Table, *Key, Value.b, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Byte)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Ascii(*Table.Table, *Key, Value.a, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Ascii)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Word(*Table.Table, *Key, Value.w, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Word)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Unicode(*Table.Table, *Key, Value.u, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Unicode)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Long(*Table.Table, *Key, Value.l, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Long)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Quad(*Table.Table, *Key, Value.q, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Quad)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Integer(*Table.Table, *Key, Value.i, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Integer)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Float(*Table.Table, *Key, Value.f, Check_Collision=#True)
    If Not *Table
      ProcedureReturn #Result_Fail
    EndIf
    
    If Not *Table\Element_Value_Size = SizeOf(Float)
      ProcedureReturn #Result_Fail
    EndIf
    
    ProcedureReturn Element_Set(*Table.Table, *Key, @Value, Check_Collision)
  EndProcedure
  
  Procedure Element_Set_Double(*Table.Table, *Key, Value.d, Check_Collision=#True)
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
      
      Sidesearch_Iteration = *Table\Sidesearch_Depth + 1
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
      Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Table_Size
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
      
      Sidesearch_Iteration = *Table\Sidesearch_Depth + 1
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
      Until Sidesearch_Iteration = 0; Or Element_Pos = *Table\Table_Size
    Next
    
    ProcedureReturn #Result_Fail
  EndProcedure
  
  ; ################################################### Datasections ################################################
  DataSection
    CRC32_Table:
    Data.l $00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3
    Data.l $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91
    Data.l $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7
    Data.l $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5
    Data.l $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B
    Data.l $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59
    Data.l $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F
    Data.l $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D
    Data.l $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433
    Data.l $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01
    Data.l $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457
    Data.l $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65
    Data.l $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB
    Data.l $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9
    Data.l $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F
    Data.l $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD
    Data.l $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683
    Data.l $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1
    Data.l $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7
    Data.l $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5
    Data.l $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B
    Data.l $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79
    Data.l $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F
    Data.l $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D
    Data.l $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713
    Data.l $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21
    Data.l $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777
    Data.l $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45
    Data.l $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB
    Data.l $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9
    Data.l $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF
    Data.l $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D
  EndDataSection
  
EndModule

; #################################################### Declares ##################################################



; #################################################### Macros ####################################################

; #################################################### Procedures ################################################


; IDE Options = PureBasic 5.40 LTS Beta 8 (Windows - x64)
; CursorPosition = 49
; FirstLine = 25
; Folding = ------
; EnableXP