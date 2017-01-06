; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2014-2017  David Vogel
;     
;     This program is free software: you can redistribute it and/or modify
;     it under the terms of the GNU General Public License as published by
;     the Free Software Foundation, either version 3 of the License, or
;     (at your option) any later version.
;     
;     This program is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;     GNU General Public License for more details.
;     
;     You should have received a copy of the GNU General Public License
;     along with this program.  If not, see <http://www.gnu.org/licenses/>.
; 
; ##################################################### Dokumentation / Kommentare ##################################
; 
; Can handle up to $7FFFFFFFFFFFFFFF bytes of data
; 
; 
; 
; 
; 
; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

#Search_Chunk_Size = 1000000

Enumeration
  #Search_Direction_Forward
  #Search_Direction_Backward
EndEnumeration

Enumeration
  #Search_State_None
  #Search_State_Search
  #Search_State_Search_Wait
  #Search_State_Replace_All
EndEnumeration

; ##################################################### Structures ##################################################

Structure Search
  *Window.Window::Object
  Window_Close.l
  
  ; #### Gadget stuff
  String.i[10]
  Frame.i[10]
  ComboBox.i[10]
  CheckBox.i[10]
  Option.i[10]
  Button_Search.i
  Button_Continue.i
  Button_Replace.i
  Button_ReplaceAll.i
  ProgressBar.i
  Text.i[10]
  
  Update_State.i
  Update_Input.i
  
  ; #### State
  State.i
  
  Fast_Compare_Amount.a
  Fast_Compare.a[2]
  
  Position.q
  Position_Start.q        ; For the ProgressBar
  
  Speed_Position.q        ; For measuring the speed
  Speed_Time.q            ; For measuring the speed
  Speed.d                 ; in B/s
  
  Keyword.s
  *Raw_Keyword
  Raw_Keyword_Size.i
  *Raw_Keyword_UC         ; Uppercase variation of the keyword (only for strings)
  Raw_Keyword_UC_Size.i
  *Raw_Keyword_LC         ; Lowercase variation of the keyword (only for strings)
  Raw_Keyword_LC_Size.i
  
  Replacement.s
  *Raw_Replacement
  Raw_Replacement_Size.i
  
  Found.i
  Found_Position.q
  Found_Size.q
  
  Direction.i
  From_Cursor.i
  
  No_Shifting.i
  
  Type.i
  Case_Sensitive.i
  Zero_Byte.i
  Big_Endian.i
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Declares ####################################################

Declare   Search_Window_Close(*Node.Node::Object)

; ##################################################### Procedures ##################################################

Procedure Search_Window_Update_State(*Node.Node::Object)
  Protected i
  Protected Progress.d
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  ; #### Calculate Speed
  If ElapsedMilliseconds() - *Object_Search\Speed_Time > 1000
    If *Object_Search\Speed_Position > *Object_Search\Position
      *Object_Search\Speed = *Object_Search\Speed_Position - *Object_Search\Position
    Else
      *Object_Search\Speed = *Object_Search\Position - *Object_Search\Speed_Position
    EndIf
    *Object_Search\Speed * 1000/(ElapsedMilliseconds() - *Object_Search\Speed_Time)
    *Object_Search\Speed_Time = ElapsedMilliseconds()
    *Object_Search\Speed_Position = *Object_Search\Position
  EndIf
  
  ; #### Calculate progress
  If *Object_Search\Direction = #Search_Direction_Forward
    Progress = (*Object_Search\Position - *Object_Search\Position_Start) / (Node::Input_Get_Size(FirstElement(*Node\Input())) - *Object_Search\Position_Start)
  Else
    Progress = (*Object_Search\Position_Start - *Object_Search\Position) / (*Object_Search\Position_Start)
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None
      SetGadgetState(*Object_Search\ProgressBar, 0)
      SetGadgetText(*Object_Search\Text[2], "Stopped.")
      
    Case #Search_State_Search
      SetGadgetState(*Object_Search\ProgressBar, Progress * 1000)
      SetGadgetText(*Object_Search\Text[2], "Position: "+Str(*Object_Search\Position)+" Speed: "+StrD(*Object_Search\Speed/1000000,1)+"MB/s")
      
    Case #Search_State_Search_Wait
      SetGadgetState(*Object_Search\ProgressBar, Progress * 1000)
      SetGadgetText(*Object_Search\Text[2], "Position: "+Str(*Object_Search\Position))
      
    Case #Search_State_Replace_All
      SetGadgetState(*Object_Search\ProgressBar, Progress * 1000)
      SetGadgetText(*Object_Search\Text[2], "Position: "+Str(*Object_Search\Position)+" Speed: "+StrD(*Object_Search\Speed/1000000,1)+"MB/s")
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Update_Input(*Node.Node::Object)
  Protected i
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None
      SetGadgetText(*Object_Search\Button_Search, "Search")
      SetGadgetText(*Object_Search\Button_ReplaceAll, "Replace All")
      DisableGadget(*Object_Search\Button_Search, #False)
      DisableGadget(*Object_Search\Button_Continue, #True)
      DisableGadget(*Object_Search\Button_Replace, #True)
      DisableGadget(*Object_Search\Button_ReplaceAll, #False)
      DisableGadget(*Object_Search\String[0], #False)
      DisableGadget(*Object_Search\String[1], #False)
      DisableGadget(*Object_Search\ComboBox[0], #False)
      Select *Object_Search\Type
        Case #Data_Raw
          DisableGadget(*Object_Search\CheckBox[0], #True)
          DisableGadget(*Object_Search\CheckBox[1], #True)
          DisableGadget(*Object_Search\CheckBox[2], #True)
        Case #Integer_U_8, #Integer_S_8, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
          DisableGadget(*Object_Search\CheckBox[0], #True)
          DisableGadget(*Object_Search\CheckBox[1], #True)
          DisableGadget(*Object_Search\CheckBox[2], #False)
        Case #String_Ascii, #String_UTF8
          DisableGadget(*Object_Search\CheckBox[0], #False)
          DisableGadget(*Object_Search\CheckBox[1], #False)
          DisableGadget(*Object_Search\CheckBox[2], #True)
        Case #String_UTF16, #String_UTF32, #String_UCS2, #String_UCS4
          DisableGadget(*Object_Search\CheckBox[0], #False)
          DisableGadget(*Object_Search\CheckBox[1], #False)
          DisableGadget(*Object_Search\CheckBox[2], #False)
          
      EndSelect
      DisableGadget(*Object_Search\CheckBox[3], #False)
      DisableGadget(*Object_Search\Option[0], #False)
      DisableGadget(*Object_Search\Option[1], #False)
      DisableGadget(*Object_Search\CheckBox[4], #False)
      
    Case #Search_State_Search
      SetGadgetText(*Object_Search\Button_Search, "Stop")
      SetGadgetText(*Object_Search\Button_ReplaceAll, "Replace All")
      DisableGadget(*Object_Search\Button_Search, #False)
      DisableGadget(*Object_Search\Button_Continue, #True)
      DisableGadget(*Object_Search\Button_Replace, #True)
      DisableGadget(*Object_Search\Button_ReplaceAll, #True)
      DisableGadget(*Object_Search\String[0], #True)
      DisableGadget(*Object_Search\String[1], #True)
      DisableGadget(*Object_Search\ComboBox[0], #True)
      DisableGadget(*Object_Search\CheckBox[0], #True)
      DisableGadget(*Object_Search\CheckBox[1], #True)
      DisableGadget(*Object_Search\CheckBox[2], #True)
      DisableGadget(*Object_Search\CheckBox[3], #True)
      DisableGadget(*Object_Search\Option[0], #True)
      DisableGadget(*Object_Search\Option[1], #True)
      DisableGadget(*Object_Search\CheckBox[4], #True)
      
    Case #Search_State_Search_Wait
      SetGadgetText(*Object_Search\Button_Search, "Cancel")
      SetGadgetText(*Object_Search\Button_ReplaceAll, "Replace All")
      DisableGadget(*Object_Search\Button_Search, #False)
      DisableGadget(*Object_Search\Button_Continue, #False)
      DisableGadget(*Object_Search\Button_Replace, #False)
      DisableGadget(*Object_Search\Button_ReplaceAll, #False)
      DisableGadget(*Object_Search\String[0], #False)
      DisableGadget(*Object_Search\String[1], #False)
      DisableGadget(*Object_Search\ComboBox[0], #False)
      Select *Object_Search\Type
        Case #Data_Raw
          DisableGadget(*Object_Search\CheckBox[0], #True)
          DisableGadget(*Object_Search\CheckBox[1], #True)
          DisableGadget(*Object_Search\CheckBox[2], #True)
        Case #Integer_U_8, #Integer_S_8, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
          DisableGadget(*Object_Search\CheckBox[0], #True)
          DisableGadget(*Object_Search\CheckBox[1], #True)
          DisableGadget(*Object_Search\CheckBox[2], #False)
        Case #String_Ascii, #String_UTF8, #String_UTF16, #String_UTF32, #String_UCS2, #String_UCS4
          DisableGadget(*Object_Search\CheckBox[0], #False)
          DisableGadget(*Object_Search\CheckBox[1], #False)
          DisableGadget(*Object_Search\CheckBox[2], #True)
          
      EndSelect
      DisableGadget(*Object_Search\CheckBox[3], #False)
      DisableGadget(*Object_Search\Option[0], #False)
      DisableGadget(*Object_Search\Option[1], #False)
      DisableGadget(*Object_Search\CheckBox[4], #False)
      
    Case #Search_State_Replace_All
      SetGadgetText(*Object_Search\Button_Search, "Search")
      SetGadgetText(*Object_Search\Button_ReplaceAll, "Cancel")
      DisableGadget(*Object_Search\Button_Search, #True)
      DisableGadget(*Object_Search\Button_Continue, #True)
      DisableGadget(*Object_Search\Button_Replace, #True)
      DisableGadget(*Object_Search\Button_ReplaceAll, #False)
      DisableGadget(*Object_Search\String[0], #True)
      DisableGadget(*Object_Search\String[1], #True)
      DisableGadget(*Object_Search\ComboBox[0], #True)
      DisableGadget(*Object_Search\CheckBox[0], #True)
      DisableGadget(*Object_Search\CheckBox[1], #True)
      DisableGadget(*Object_Search\CheckBox[2], #True)
      DisableGadget(*Object_Search\CheckBox[3], #True)
      DisableGadget(*Object_Search\Option[0], #True)
      DisableGadget(*Object_Search\Option[1], #True)
      DisableGadget(*Object_Search\CheckBox[4], #True)
      
  EndSelect
  
  SetGadgetText(*Object_Search\String[0], *Object_Search\Keyword)
  SetGadgetText(*Object_Search\String[1], *Object_Search\Replacement)
  
  For i = 0 To CountGadgetItems(*Object_Search\ComboBox[0]) - 1
    If GetGadgetItemData(*Object_Search\ComboBox[0], i) = *Object_Search\Type
      SetGadgetState(*Object_Search\ComboBox[0], i)
      Break
    EndIf
  Next
  
  SetGadgetState(*Object_Search\CheckBox[3], *Object_Search\From_Cursor)
  
  Select *Object_Search\Direction
    Case #Search_Direction_Forward  : SetGadgetState(*Object_Search\Option[0], #True)
    Case #Search_Direction_Backward : SetGadgetState(*Object_Search\Option[1], #True)
  EndSelect
  
  If *Object_Search\Case_Sensitive : SetGadgetState(*Object_Search\CheckBox[0], #PB_Checkbox_Checked) : Else : SetGadgetState(*Object_Search\CheckBox[0], #PB_Checkbox_Unchecked) : EndIf
  If *Object_Search\Zero_Byte      : SetGadgetState(*Object_Search\CheckBox[1], #PB_Checkbox_Checked) : Else : SetGadgetState(*Object_Search\CheckBox[1], #PB_Checkbox_Unchecked) : EndIf
  If *Object_Search\Big_Endian     : SetGadgetState(*Object_Search\CheckBox[2], #PB_Checkbox_Checked) : Else : SetGadgetState(*Object_Search\CheckBox[2], #PB_Checkbox_Unchecked) : EndIf
  
  If *Object_Search\No_Shifting    : SetGadgetState(*Object_Search\CheckBox[4], #PB_Checkbox_Checked) : Else : SetGadgetState(*Object_Search\CheckBox[4], #PB_Checkbox_Unchecked) : EndIf
  
EndProcedure

Macro Search_Prepare_Keyword_Helper(_Type)
  *Object_Search\Raw_Keyword_Size = StringByteLength(*Object_Search\Keyword, _Type)
  If *Object_Search\Zero_Byte
    If *Object_Search\Type = #String_UTF16
      *Object_Search\Raw_Keyword_Size + 2
    Else
      *Object_Search\Raw_Keyword_Size + 1
    EndIf
  EndIf
  If *Object_Search\Raw_Keyword_Size > 0
    *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size+2)
    If *Object_Search\Raw_Keyword
      PokeS(*Object_Search\Raw_Keyword, *Object_Search\Keyword, -1, _Type)
    EndIf
  EndIf
  
  *Object_Search\Raw_Keyword_UC_Size = StringByteLength(UCase(*Object_Search\Keyword), _Type)
  If *Object_Search\Zero_Byte
    If *Object_Search\Type = #String_UTF16
      *Object_Search\Raw_Keyword_UC_Size + 2
    Else
      *Object_Search\Raw_Keyword_UC_Size + 1
    EndIf
  EndIf
  If *Object_Search\Raw_Keyword_UC_Size > 0
    *Object_Search\Raw_Keyword_UC = AllocateMemory(*Object_Search\Raw_Keyword_UC_Size+2)
    If *Object_Search\Raw_Keyword_UC
      PokeS(*Object_Search\Raw_Keyword_UC, UCase(*Object_Search\Keyword), -1, _Type)
    EndIf
  EndIf
  
  *Object_Search\Raw_Keyword_LC_Size = StringByteLength(LCase(*Object_Search\Keyword), _Type)
  If *Object_Search\Zero_Byte
    If *Object_Search\Type = #String_UTF16
      *Object_Search\Raw_Keyword_LC_Size + 2
    Else
      *Object_Search\Raw_Keyword_LC_Size + 1
    EndIf
  EndIf
  If *Object_Search\Raw_Keyword_LC_Size > 0
    *Object_Search\Raw_Keyword_LC = AllocateMemory(*Object_Search\Raw_Keyword_LC_Size+2)
    If *Object_Search\Raw_Keyword_LC
      PokeS(*Object_Search\Raw_Keyword_LC, LCase(*Object_Search\Keyword), -1, _Type)
    EndIf
  EndIf
EndMacro

Procedure Search_Prepare_Keyword(*Node.Node::Object)
  Protected i, Counter, Temp.s
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  If *Object_Search\Raw_Keyword
    FreeMemory(*Object_Search\Raw_Keyword)
    *Object_Search\Raw_Keyword = #Null
    *Object_Search\Raw_Keyword_Size = 0
  EndIf
  If *Object_Search\Raw_Keyword_UC
    FreeMemory(*Object_Search\Raw_Keyword_UC)
    *Object_Search\Raw_Keyword_UC = #Null
    *Object_Search\Raw_Keyword_UC_Size = 0
  EndIf
  If *Object_Search\Raw_Keyword_LC
    FreeMemory(*Object_Search\Raw_Keyword_LC)
    *Object_Search\Raw_Keyword_LC = #Null
    *Object_Search\Raw_Keyword_LC_Size = 0
  EndIf
  
  Select *Object_Search\Type
    Case #Data_Raw
      i = 0
      Counter = 0
      Repeat
        i + 1
        Temp = Trim(StringField(*Object_Search\Keyword, i, " "))
        If Temp = ""
          Break
        EndIf
        Counter + 1
      ForEver
      If Counter > 0
        *Object_Search\Raw_Keyword_Size = Counter
        *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
        If *Object_Search\Raw_Keyword
          For i = 0 To *Object_Search\Raw_Keyword_Size-1
            Temp = Trim(StringField(*Object_Search\Keyword, i+1, " "))
            PokeA(*Object_Search\Raw_Keyword+i, Val(Temp))
          Next
        EndIf
      EndIf
      
    Case #Integer_U_8
      *Object_Search\Raw_Keyword_Size = 1
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeA(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Integer_S_8
      *Object_Search\Raw_Keyword_Size = 1
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeB(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Integer_U_16
      *Object_Search\Raw_Keyword_Size = 2
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeU(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Integer_S_16
      *Object_Search\Raw_Keyword_Size = 2
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeW(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Integer_S_32
      *Object_Search\Raw_Keyword_Size = 4
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeL(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Integer_S_64
      *Object_Search\Raw_Keyword_Size = 8
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeQ(*Object_Search\Raw_Keyword, Val(*Object_Search\Keyword))
      EndIf
      
    Case #Float_32
      *Object_Search\Raw_Keyword_Size = 4
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeF(*Object_Search\Raw_Keyword, ValF(*Object_Search\Keyword))
      EndIf
      
    Case #Float_64
      *Object_Search\Raw_Keyword_Size = 8
      *Object_Search\Raw_Keyword = AllocateMemory(*Object_Search\Raw_Keyword_Size)
      If *Object_Search\Raw_Keyword
        PokeD(*Object_Search\Raw_Keyword, ValD(*Object_Search\Keyword))
      EndIf
      
    Case #String_Ascii
      Search_Prepare_Keyword_Helper(#PB_Ascii)
      
    Case #String_UTF8
      Search_Prepare_Keyword_Helper(#PB_UTF8)
      
    Case #String_UTF16
      Search_Prepare_Keyword_Helper(#PB_Unicode)
      If *Object_Search\Big_Endian
        For i = 0 To *Object_Search\Raw_Keyword_Size-1 Step 2
          Memory::Mirror(*Object_Search\Raw_Keyword + i, 2)
        Next
        For i = 0 To *Object_Search\Raw_Keyword_LC_Size-1 Step 2
          Memory::Mirror(*Object_Search\Raw_Keyword_LC + i, 2)
        Next
        For i = 0 To *Object_Search\Raw_Keyword_UC_Size-1 Step 2
          Memory::Mirror(*Object_Search\Raw_Keyword_UC + i, 2)
        Next
      EndIf
      
  EndSelect
  
  Select *Object_Search\Type
    Case #Integer_U_8, #Integer_S_8, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
      If *Object_Search\Big_Endian
        Memory::Mirror(*Object_Search\Raw_Keyword, *Object_Search\Raw_Keyword_Size)
      EndIf
  EndSelect
  
  *Object_Search\Fast_Compare_Amount = 0
  
  ; #### Setup the fast compare stuff
  Select *Object_Search\Type
    Case #Data_Raw, #Integer_U_8, #Integer_S_8, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
      If *Object_Search\Raw_Keyword And *Object_Search\Raw_Keyword_Size > 0
        *Object_Search\Fast_Compare_Amount = 1
        *Object_Search\Fast_Compare[0] = PeekA(*Object_Search\Raw_Keyword)
      EndIf
    
    Case #String_Ascii, #String_UTF8, #String_UTF16, #String_UTF32, #String_UCS2, #String_UCS4
      If *Object_Search\Case_Sensitive
        If *Object_Search\Raw_Keyword And *Object_Search\Raw_Keyword_Size > 0
          *Object_Search\Fast_Compare_Amount = 1
          *Object_Search\Fast_Compare[0] = PeekA(*Object_Search\Raw_Keyword)
        EndIf
      Else
        If *Object_Search\Raw_Keyword_UC And *Object_Search\Raw_Keyword_UC_Size > 0 And *Object_Search\Raw_Keyword_LC And *Object_Search\Raw_Keyword_LC_Size > 0
          *Object_Search\Fast_Compare_Amount = 2
          *Object_Search\Fast_Compare[0] = PeekA(*Object_Search\Raw_Keyword_UC)
          *Object_Search\Fast_Compare[1] = PeekA(*Object_Search\Raw_Keyword_LC)
        EndIf
      EndIf
      
  EndSelect
  
EndProcedure

Procedure Search_Prepare_Replacement(*Node.Node::Object)
  Protected i, Counter, Temp.s
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  If *Object_Search\Raw_Replacement
    FreeMemory(*Object_Search\Raw_Replacement)
    *Object_Search\Raw_Replacement = #Null
  EndIf
  
  Select *Object_Search\Type
    Case #Data_Raw
      i = 0
      Counter = 0
      Repeat
        i + 1
        Temp = Trim(StringField(*Object_Search\Replacement, i, " "))
        If Temp = ""
          Break
        EndIf
        Counter + 1
      ForEver
      If Counter > 0
        *Object_Search\Raw_Replacement_Size = Counter
        *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
        If *Object_Search\Raw_Replacement
          For i = 0 To *Object_Search\Raw_Replacement_Size-1
            Temp = Trim(StringField(*Object_Search\Replacement, i+1, " "))
            PokeA(*Object_Search\Raw_Replacement+i, Val(Temp))
          Next
        EndIf
      EndIf
      
    Case #Integer_U_8
      *Object_Search\Raw_Replacement_Size = 1
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeA(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Integer_S_8
      *Object_Search\Raw_Replacement_Size = 1
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeB(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Integer_U_16
      *Object_Search\Raw_Replacement_Size = 2
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeU(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Integer_S_16
      *Object_Search\Raw_Replacement_Size = 2
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeW(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Integer_S_32
      *Object_Search\Raw_Replacement_Size = 4
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeL(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Integer_S_64
      *Object_Search\Raw_Replacement_Size = 8
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeQ(*Object_Search\Raw_Replacement, Val(*Object_Search\Replacement))
      EndIf
      
    Case #Float_32
      *Object_Search\Raw_Replacement_Size = 4
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeF(*Object_Search\Raw_Replacement, ValF(*Object_Search\Replacement))
      EndIf
      
    Case #Float_64
      *Object_Search\Raw_Replacement_Size = 8
      *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size)
      If *Object_Search\Raw_Replacement
        PokeD(*Object_Search\Raw_Replacement, ValD(*Object_Search\Replacement))
      EndIf
      
    Case #String_Ascii
      *Object_Search\Raw_Replacement_Size = StringByteLength(*Object_Search\Replacement, #PB_Ascii)
      If *Object_Search\Zero_Byte
        *Object_Search\Raw_Replacement_Size + 1
      EndIf
      If *Object_Search\Raw_Replacement_Size > 0
        *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size+1)
        If *Object_Search\Raw_Replacement
          PokeS(*Object_Search\Raw_Replacement, *Object_Search\Replacement, -1, #PB_Ascii)
        EndIf
      EndIf
      
    Case #String_UTF8
      *Object_Search\Raw_Replacement_Size = StringByteLength(*Object_Search\Replacement, #PB_UTF8)
      If *Object_Search\Zero_Byte
        *Object_Search\Raw_Replacement_Size + 1
      EndIf
      If *Object_Search\Raw_Replacement_Size > 0
        *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size+1)
        If *Object_Search\Raw_Replacement
          PokeS(*Object_Search\Raw_Replacement, *Object_Search\Replacement, -1, #PB_UTF8)
        EndIf
      EndIf
      
    Case #String_UTF16
      *Object_Search\Raw_Replacement_Size = StringByteLength(*Object_Search\Replacement, #PB_Unicode)
      If *Object_Search\Zero_Byte
        *Object_Search\Raw_Replacement_Size + 2
      EndIf
      If *Object_Search\Raw_Replacement_Size > 0
        *Object_Search\Raw_Replacement = AllocateMemory(*Object_Search\Raw_Replacement_Size+2)
        If *Object_Search\Raw_Replacement
          PokeS(*Object_Search\Raw_Replacement, *Object_Search\Replacement, -1, #PB_Unicode)
        EndIf
      EndIf
      If *Object_Search\Big_Endian
        For i = 0 To *Object_Search\Raw_Replacement_Size-1 Step 2
          Memory::Mirror(*Object_Search\Raw_Replacement + i, 2)
        Next
      EndIf
      
  EndSelect
  
  Select *Object_Search\Type
    Case #Integer_U_8, #Integer_S_8, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
      If *Object_Search\Big_Endian
        Memory::Mirror(*Object_Search\Raw_Replacement, *Object_Search\Raw_Replacement_Size)
      EndIf
  EndSelect
  
EndProcedure

Procedure Search_Continue(*Node.Node::Object)
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_Search_Wait
      *Object_Search\State = #Search_State_Search
      *Object_Search\Update_Input = #True
      
  EndSelect
  
  *Object_Search\Update_State = #True
  
EndProcedure

Procedure Search_Window_Event_String_0()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\Keyword = GetGadgetText(Event_Gadget)
      
      Search_Prepare_Keyword(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_String_1()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\Replacement = GetGadgetText(Event_Gadget)
      
      Search_Prepare_Replacement(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_ComboBox()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      If GetGadgetState(Event_Gadget) <> -1
        *Object_Search\Type = GetGadgetItemData(Event_Gadget, GetGadgetState(Event_Gadget))
      EndIf
      
      *Object_Search\Update_Input = #True
      
      Search_Prepare_Keyword(*Node)
      Search_Prepare_Replacement(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_CheckBox_0()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\Case_Sensitive = GetGadgetState(Event_Gadget)
      
      Search_Prepare_Keyword(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_CheckBox_1()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\Zero_Byte = GetGadgetState(Event_Gadget)
      
      Search_Prepare_Keyword(*Node)
      Search_Prepare_Replacement(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_CheckBox_2()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\Big_Endian = GetGadgetState(Event_Gadget)
      
      Search_Prepare_Keyword(*Node)
      Search_Prepare_Replacement(*Node)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_CheckBox_3()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\From_Cursor = GetGadgetState(Event_Gadget)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_CheckBox_4()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      *Object_Search\No_Shifting = GetGadgetState(Event_Gadget)
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_Option_0()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      If GetGadgetState(Event_Gadget) = #True
        *Object_Search\Direction = #Search_Direction_Forward
      EndIf
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_Option_1()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None, #Search_State_Search_Wait
      If GetGadgetState(Event_Gadget) = #True
        *Object_Search\Direction = #Search_Direction_Backward
      EndIf
      
  EndSelect
  
EndProcedure

Procedure Search_Window_Event_Button_Search()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None
      *Object_Search\State = #Search_State_Search
      *Object_Search\Update_Input = #True
      
      If *Object_Search\From_Cursor
        *Object_Search\Position = *Object\Select_End
      Else
        Select *Object_Search\Direction
          Case #Search_Direction_Forward  : *Object_Search\Position = 0
          Case #Search_Direction_Backward : *Object_Search\Position = Node::Input_Get_Size(FirstElement(*Node\Input()))
        EndSelect
      EndIf
      *Object_Search\Position_Start = *Object_Search\Position
      *Object_Search\Found = #False
      
    Case #Search_State_Search
      *Object_Search\State = #Search_State_Search_Wait
      *Object_Search\Update_Input = #True
      
    Case #Search_State_Search_Wait
      *Object_Search\State = #Search_State_None
      *Object_Search\Update_Input = #True
      
  EndSelect
  
  *Object_Search\Update_State = #True
  
EndProcedure

Procedure Search_Window_Event_Button_Continue()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_Search_Wait
      *Object_Search\State = #Search_State_Search
      *Object_Search\Update_Input = #True
      *Object_Search\Found = #False
      
  EndSelect
  
  *Object_Search\Update_State = #True
  
EndProcedure

Procedure Search_Window_Event_Button_Replace()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Protected Shift_Difference.q
  
  Select *Object_Search\State
    Case #Search_State_Search_Wait
      
      If *Object_Search\Found
        Shift_Difference = *Object_Search\Raw_Replacement_Size - *Object_Search\Raw_Keyword_Size
        If *Object_Search\No_Shifting Or Shift_Difference = 0
          If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
            Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
            *Object_Search\State = #Search_State_None
            *Object_Search\Update_Input = #True
          EndIf
        Else
          If Node::Input_Shift(FirstElement(*Node\Input()), *Object_Search\Found_Position, Shift_Difference)
            *Object_Search\Position + Shift_Difference
            If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
              Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
              *Object_Search\State = #Search_State_None
              *Object_Search\Update_Input = #True
            EndIf
          Else
            Logger::Entry_Add_Error("Shifting failed", "The destination can't be shifted. Replace-Operation not successful.")
            *Object_Search\State = #Search_State_None
            *Object_Search\Update_Input = #True
          EndIf
        EndIf
      EndIf
      
      *Object_Search\State = #Search_State_Search
      *Object_Search\Update_Input = #True
      *Object_Search\Found = #False
      
  EndSelect
  
  *Object_Search\Update_State = #True
  
EndProcedure

Procedure Search_Window_Event_Button_ReplaceAll()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_None
      *Object_Search\State = #Search_State_Replace_All
      *Object_Search\Update_Input = #True
      
      If *Object_Search\From_Cursor
        *Object_Search\Position = *Object\Select_End
      Else
        Select *Object_Search\Direction
          Case #Search_Direction_Forward  : *Object_Search\Position = 0
          Case #Search_Direction_Backward : *Object_Search\Position = Node::Input_Get_Size(FirstElement(*Node\Input()))
        EndSelect
      EndIf
      *Object_Search\Position_Start = *Object_Search\Position
      *Object_Search\Found = #False
      
    Case #Search_State_Search_Wait
      *Object_Search\State = #Search_State_Replace_All
      *Object_Search\Update_Input = #True
      
    Case #Search_State_Replace_All
      *Object_Search\State = #Search_State_None
      *Object_Search\Update_Input = #True
      
  EndSelect
  
  *Object_Search\Update_State = #True
  
EndProcedure

Procedure Search_Window_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window::Object = Window::Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Node.Node::Object = *Window\Node
  If Not *Node
    ProcedureReturn
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn
  EndIf
  
  ;Search_Window_Close(*Node)
  *Object_Search\Window_Close = #True
EndProcedure

Procedure Search_Window_Open(*Node.Node::Object)
  Protected Width, Height
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Search\Window
    
    Width = 410
    Height = 320
    
    *Object_Search\Window = Window::Create(*Node, "Editor_Search", "Editor_Search", 0, 0, Width, Height)
    
    ; #### Gadgets
    *Object_Search\Text[0] = TextGadget(#PB_Any, 10, 10, 100, 20, "Search for:", #PB_Text_Right)
    *Object_Search\Text[1] = TextGadget(#PB_Any, 10, 40, 100, 20, "Replace with:", #PB_Text_Right)
    *Object_Search\String[0] = StringGadget(#PB_Any, 120, 10, Width-130, 20, "")
    *Object_Search\String[1] = StringGadget(#PB_Any, 120, 40, Width-130, 20, "")
    
    GadgetToolTip(*Object_Search\String[0], "Input examples: $FF (Hexadecimal), %10101010 (Binary)")
    GadgetToolTip(*Object_Search\String[1], "Input examples: $FF (Hexadecimal), %10101010 (Binary)")
    
    *Object_Search\Frame[0] = FrameGadget(#PB_Any, 10, 70, Width-130, 140, "Type")
    *Object_Search\ComboBox[0] = ComboBoxGadget(#PB_Any, 20, 90, Width-150, 20)
    AddGadgetItem(*Object_Search\ComboBox[0], 0, "Raw Data")                 : SetGadgetItemData(*Object_Search\ComboBox[0], 0, #Data_Raw)
    AddGadgetItem(*Object_Search\ComboBox[0], 1, "Unsigned 1 Byte Integer")  : SetGadgetItemData(*Object_Search\ComboBox[0], 1, #Integer_U_8)
    AddGadgetItem(*Object_Search\ComboBox[0], 2, "Signed 1 Byte Integer")    : SetGadgetItemData(*Object_Search\ComboBox[0], 2, #Integer_S_8)
    AddGadgetItem(*Object_Search\ComboBox[0], 3, "Unsigned 2 Byte Integer")  : SetGadgetItemData(*Object_Search\ComboBox[0], 3, #Integer_U_16)
    AddGadgetItem(*Object_Search\ComboBox[0], 4, "Signed 2 Byte Integer")    : SetGadgetItemData(*Object_Search\ComboBox[0], 4, #Integer_S_16)
    AddGadgetItem(*Object_Search\ComboBox[0], 5, "Signed 4 Byte Integer")    : SetGadgetItemData(*Object_Search\ComboBox[0], 5, #Integer_S_32)
    AddGadgetItem(*Object_Search\ComboBox[0], 6, "Signed 8 Byte Integer")    : SetGadgetItemData(*Object_Search\ComboBox[0], 6, #Integer_S_64)
    AddGadgetItem(*Object_Search\ComboBox[0], 7, "4 Byte Float")             : SetGadgetItemData(*Object_Search\ComboBox[0], 7, #Float_32)
    AddGadgetItem(*Object_Search\ComboBox[0], 8, "8 Byte Float")             : SetGadgetItemData(*Object_Search\ComboBox[0], 8, #Float_64)
    AddGadgetItem(*Object_Search\ComboBox[0], 9, "Ascii String")             : SetGadgetItemData(*Object_Search\ComboBox[0], 9, #String_Ascii)
    AddGadgetItem(*Object_Search\ComboBox[0], 10, "UTF-8 String")            : SetGadgetItemData(*Object_Search\ComboBox[0], 10, #String_UTF8)
    AddGadgetItem(*Object_Search\ComboBox[0], 11, "UTF-16 String")           : SetGadgetItemData(*Object_Search\ComboBox[0], 11, #String_UTF16)
    
    *Object_Search\CheckBox[0] = CheckBoxGadget(#PB_Any, 20, 120, Width-150, 20, "Case Sensitive")
    *Object_Search\CheckBox[1] = CheckBoxGadget(#PB_Any, 20, 150, Width-150, 20, "Zero-Byte")
    *Object_Search\CheckBox[2] = CheckBoxGadget(#PB_Any, 20, 180, Width-150, 20, "Big Endian")
    
    *Object_Search\Frame[1] = FrameGadget(#PB_Any, Width-110, 70, 100, 100, "Direction")
    *Object_Search\CheckBox[3] = CheckBoxGadget(#PB_Any, Width-100, 90, 80, 20, "From Cursor")
    *Object_Search\Option[0] = OptionGadget(#PB_Any, Width-100, 120, 80, 20, "Forward")
    *Object_Search\Option[1] = OptionGadget(#PB_Any, Width-100, 140, 80, 20, "Backward")
    
    *Object_Search\CheckBox[4] = CheckBoxGadget(#PB_Any, Width-110, 180, 100, 20, "No shifting")
    
    GadgetToolTip(*Object_Search\CheckBox[4], "Overwrite data instead of replacing it. This prevents the data from being shifted.")
    
    *Object_Search\Button_Search = ButtonGadget(#PB_Any, 10, 220, 90, 30, "Search")
    *Object_Search\Button_Continue = ButtonGadget(#PB_Any, 110, 220, 90, 30, "Continue")
    *Object_Search\Button_Replace = ButtonGadget(#PB_Any, 210, 220, 90, 30, "Replace")
    *Object_Search\Button_ReplaceAll = ButtonGadget(#PB_Any, 310, 220, 90, 30, "Replace All")
    
    *Object_Search\ProgressBar = ProgressBarGadget(#PB_Any, 10, Height-60, Width-20, 20, 0, 1000)
    *Object_Search\Text[2] = TextGadget(#PB_Any, 10, Height-30, Width-20, 20, "")
    
    *Object_Search\Update_Input = #True
    *Object_Search\Update_State = #True
    
    BindGadgetEvent(*Object_Search\String[0], @Search_Window_Event_String_0())
    BindGadgetEvent(*Object_Search\String[1], @Search_Window_Event_String_1())
    BindGadgetEvent(*Object_Search\ComboBox[0], @Search_Window_Event_ComboBox())
    BindGadgetEvent(*Object_Search\CheckBox[0], @Search_Window_Event_CheckBox_0())
    BindGadgetEvent(*Object_Search\CheckBox[1], @Search_Window_Event_CheckBox_1())
    BindGadgetEvent(*Object_Search\CheckBox[2], @Search_Window_Event_CheckBox_2())
    BindGadgetEvent(*Object_Search\CheckBox[3], @Search_Window_Event_CheckBox_3())
    BindGadgetEvent(*Object_Search\CheckBox[4], @Search_Window_Event_CheckBox_4())
    BindGadgetEvent(*Object_Search\Option[0], @Search_Window_Event_Option_0())
    BindGadgetEvent(*Object_Search\Option[1], @Search_Window_Event_Option_1())
    BindGadgetEvent(*Object_Search\Button_Search, @Search_Window_Event_Button_Search())
    BindGadgetEvent(*Object_Search\Button_Continue, @Search_Window_Event_Button_Continue())
    BindGadgetEvent(*Object_Search\Button_Replace, @Search_Window_Event_Button_Replace())
    BindGadgetEvent(*Object_Search\Button_ReplaceAll, @Search_Window_Event_Button_ReplaceAll())
    
    BindEvent(#PB_Event_CloseWindow, @Search_Window_Event_CloseWindow(), *Object_Search\Window\ID)
    
  Else
    Window::Set_Active(*Object_Search\Window)
  EndIf
EndProcedure

Procedure Search_Window_Close(*Node.Node::Object)
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  If *Object_Search\Window
    
    UnbindGadgetEvent(*Object_Search\String[0], @Search_Window_Event_String_0())
    UnbindGadgetEvent(*Object_Search\String[1], @Search_Window_Event_String_1())
    UnbindGadgetEvent(*Object_Search\ComboBox[0], @Search_Window_Event_ComboBox())
    UnbindGadgetEvent(*Object_Search\CheckBox[0], @Search_Window_Event_CheckBox_0())
    UnbindGadgetEvent(*Object_Search\CheckBox[1], @Search_Window_Event_CheckBox_1())
    UnbindGadgetEvent(*Object_Search\CheckBox[2], @Search_Window_Event_CheckBox_2())
    UnbindGadgetEvent(*Object_Search\CheckBox[3], @Search_Window_Event_CheckBox_3())
    UnbindGadgetEvent(*Object_Search\CheckBox[4], @Search_Window_Event_CheckBox_4())
    UnbindGadgetEvent(*Object_Search\Option[0], @Search_Window_Event_Option_0())
    UnbindGadgetEvent(*Object_Search\Option[1], @Search_Window_Event_Option_1())
    UnbindGadgetEvent(*Object_Search\Button_Search, @Search_Window_Event_Button_Search())
    UnbindGadgetEvent(*Object_Search\Button_Continue, @Search_Window_Event_Button_Continue())
    UnbindGadgetEvent(*Object_Search\Button_Replace, @Search_Window_Event_Button_Replace())
    UnbindGadgetEvent(*Object_Search\Button_ReplaceAll, @Search_Window_Event_Button_ReplaceAll())
    
    UnbindEvent(#PB_Event_CloseWindow, @Search_Window_Event_CloseWindow(), *Object_Search\Window\ID)
    
    Window::Delete(*Object_Search\Window)
    *Object_Search\Window = #Null
  EndIf
EndProcedure

Procedure Search_Do_Helper(*Node.Node::Object, Position.q, *Fast_Memory=#Null, Fast_Memory_Size.i=0)
  Protected *Temp, Temp_Size.i, Temp_String.s
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  Select *Object_Search\Type
    Case #Integer_U_8, #Integer_S_8
      ; #### The First byte matches --> Found
      ProcedureReturn #True
      
    Case #Data_Raw, #Integer_U_16, #Integer_S_16, #Integer_S_32, #Integer_S_64, #Float_32, #Float_64
      If *Fast_Memory
        ; #### Fast Memory available
        If CompareMemory(*Object_Search\Raw_Keyword, *Fast_Memory, *Object_Search\Raw_Keyword_Size)
          ProcedureReturn #True
        EndIf
      Else
        *Temp = AllocateMemory(*Object_Search\Raw_Keyword_Size)
        If *Temp
          If Node::Input_Get_Data(FirstElement(*Node\Input()), Position, *Object_Search\Raw_Keyword_Size, *Temp, #Null)
            If CompareMemory(*Object_Search\Raw_Keyword, *Temp, *Object_Search\Raw_Keyword_Size)
              FreeMemory(*Temp)
              ProcedureReturn #True
            EndIf
          EndIf
          FreeMemory(*Temp)
        EndIf
      EndIf
      
    Case #String_Ascii, #String_UTF8, #String_UTF16
      If *Object_Search\Case_Sensitive
        
        If *Fast_Memory
          ; #### Fast Memory available
          If CompareMemory(*Object_Search\Raw_Keyword, *Fast_Memory, *Object_Search\Raw_Keyword_Size)
            ProcedureReturn #True
          EndIf
        Else
          *Temp = AllocateMemory(*Object_Search\Raw_Keyword_Size)
          If *Temp
            If Node::Input_Get_Data(FirstElement(*Node\Input()), Position, Temp_Size, *Temp, #Null)
              If CompareMemory(*Object_Search\Raw_Keyword, *Temp, Temp_Size)
                FreeMemory(*Temp)
                ProcedureReturn #True
              EndIf
            EndIf
            FreeMemory(*Temp)
          EndIf
        EndIf
        
      Else
        
        Temp_Size = Fast_Memory_Size
        *Temp = *Fast_Memory
        
        If Not *Temp
          Temp_Size = *Object_Search\Raw_Keyword_Size
          *Temp = AllocateMemory(Temp_Size)
          If *Temp
            If Not Node::Input_Get_Data(FirstElement(*Node\Input()), Position, Temp_Size, *Temp, #Null)
              FreeMemory(*Temp)
              ProcedureReturn #False
            EndIf
          EndIf
        EndIf
        
        ; #### Probably not the best solution for finding case insensitive strings. But it works
        If *Temp
          Select *Object_Search\Type
            Case #String_Ascii  : Temp_String = PeekS(*Temp, Temp_Size, #PB_Ascii)
            Case #String_UTF8   : Temp_String = PeekS(*Temp, Temp_Size, #PB_UTF8)      ; Here the "Length" parameter is the amount of bytes to read
            Case #String_UTF16  : Temp_String = PeekS(*Temp, Temp_Size/2, #PB_Unicode) ; Here the "Length" parameter is the amount of words to read (Not necessarily the amount of characters)
          EndSelect
          
          If LCase(Temp_String) = LCase(*Object_Search\Keyword)
            If Not *Fast_Memory
              FreeMemory(*Temp)
            EndIf
            ProcedureReturn #True
          EndIf
          
          If Not *Fast_Memory
            FreeMemory(*Temp)
          EndIf
        EndIf
        
        
        
      EndIf
      
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure Search_Do(*Node.Node::Object)
  Protected *Temp, Temp_Size.i
  Protected Data_Size.q
  Protected *Ascii.Ascii
  Protected i
  Protected Temp_Pos.q
  Protected *Fast_Memory, Fast_Memory_Size.i
  Protected *Current_Segment.Node::Output_Segment
  Protected NewList Object_Output_Segment.Node::Output_Segment()
  Protected Shift_Difference.q
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  Node::Input_Get_Segments(FirstElement(*Node\Input()), Object_Output_Segment())
  If ListSize(Object_Output_Segment()) = 0
    AddElement(Object_Output_Segment())
    Object_Output_Segment()\Position = 0
    Object_Output_Segment()\Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
    Object_Output_Segment()\Metadata = #Metadata_NoError | #Metadata_Readable
  EndIf
  
  Select *Object_Search\State
    Case #Search_State_Search
      ; #### Get the current segment
      Select *Object_Search\Direction
        Case #Search_Direction_Forward
          ForEach Object_Output_Segment()
            If Object_Output_Segment()\Metadata & #Metadata_Readable
              If Object_Output_Segment()\Position + Object_Output_Segment()\Size > *Object_Search\Position
                *Current_Segment = Object_Output_Segment()
                Break
              EndIf
            EndIf
          Next
          
        Case #Search_Direction_Backward
          If LastElement(Object_Output_Segment())
            Repeat
              If Object_Output_Segment()\Metadata & #Metadata_Readable
                If Object_Output_Segment()\Position < *Object_Search\Position
                  *Current_Segment = Object_Output_Segment()
                  Break
                EndIf
              EndIf
            Until Not PreviousElement(Object_Output_Segment())
          EndIf
          
      EndSelect
      
      If *Current_Segment
        ; #### Crop range to the segment
        Temp_Size = #Search_Chunk_Size
        If *Object_Search\Position < *Current_Segment\Position
          *Object_Search\Position = *Current_Segment\Position
        EndIf
        If *Object_Search\Position > *Current_Segment\Position + *Current_Segment\Size
          *Object_Search\Position = *Current_Segment\Position + *Current_Segment\Size
        EndIf
        Select *Object_Search\Direction
          Case #Search_Direction_Forward
            If Temp_Size > *Current_Segment\Size
              Temp_Size = *Current_Segment\Size
            EndIf
            If Temp_Size > *Current_Segment\Position + *Current_Segment\Size - *Object_Search\Position
              Temp_Size = *Current_Segment\Position + *Current_Segment\Size - *Object_Search\Position
            EndIf
            Temp_Pos = *Object_Search\Position
            
          Case #Search_Direction_Backward
            If Temp_Size > *Current_Segment\Size
              Temp_Size = *Current_Segment\Size
            EndIf
            If Temp_Size > *Object_Search\Position - *Current_Segment\Position
              Temp_Size = *Object_Search\Position - *Current_Segment\Position
            EndIf
            Temp_Pos = *Object_Search\Position - Temp_Size
            
        EndSelect
        
      Else
        ; #### Stop searching
        *Object_Search\State = #Search_State_None
        *Object_Search\Update_Input = #True
        ProcedureReturn #True
      EndIf
      
      *Temp = AllocateMemory(Temp_Size)
      If *Temp
        
        If Node::Input_Get_Data(FirstElement(*Node\Input()), Temp_Pos, Temp_Size, *Temp, #Null)
          
          Select *Object_Search\Direction
            Case #Search_Direction_Forward
              *Ascii = *Temp
              Temp_Pos = *Object_Search\Position
            Case #Search_Direction_Backward
              *Ascii = *Temp + Temp_Size - 1
              Temp_Pos = *Object_Search\Position - 1
          EndSelect
          
          If *Object_Search\Fast_Compare_Amount > 0
            For i = 1 To Temp_Size
              If *Ascii\a = *Object_Search\Fast_Compare[0]
                ; #### Give the helper function direct access to *Temp if possible
                If Temp_Size - (*Ascii - *Temp) >= *Object_Search\Raw_Keyword_Size
                  *Fast_Memory = *Ascii
                  Fast_Memory_Size = *Object_Search\Raw_Keyword_Size
                Else
                  *Fast_Memory = #Null
                  Fast_Memory_Size = 0
                EndIf
                If Search_Do_Helper(*Node, Temp_Pos, *Fast_Memory, Fast_Memory_Size)
                  *Object_Search\Found = #True
                  *Object_Search\Found_Position = Temp_Pos
                  *Object_Search\Found_Size = *Object_Search\Raw_Keyword_Size
                  Range_Set(*Node, Temp_Pos, Temp_Pos + *Object_Search\Raw_Keyword_Size, #False, #True)
                  If *Object_Search\Direction = #Search_Direction_Forward
                    Temp_Pos + *Object_Search\Raw_Keyword_Size
                  Else
                    Temp_Pos - 1
                  EndIf
                  *Object_Search\State = #Search_State_Search_Wait
                  *Object_Search\Update_Input = #True
                  Break
                EndIf
              EndIf
              If *Object_Search\Fast_Compare_Amount > 1
                If *Ascii\a = *Object_Search\Fast_Compare[1]
                  ; #### Give the helper function direct access to *Temp if possible
                  If Temp_Size - (*Ascii - *Temp) >= *Object_Search\Raw_Keyword_Size
                    *Fast_Memory = *Ascii
                    Fast_Memory_Size = *Object_Search\Raw_Keyword_Size
                  Else
                    *Fast_Memory = #Null
                    Fast_Memory_Size = 0
                  EndIf
                  If Search_Do_Helper(*Node, Temp_Pos, *Fast_Memory, Fast_Memory_Size)
                    *Object_Search\Found = #True
                    *Object_Search\Found_Position = Temp_Pos
                    *Object_Search\Found_Size = *Object_Search\Raw_Keyword_Size
                    Range_Set(*Node, Temp_Pos, Temp_Pos + *Object_Search\Raw_Keyword_Size, #False, #True)
                    If *Object_Search\Direction = #Search_Direction_Forward
                      Temp_Pos + *Object_Search\Raw_Keyword_Size
                    Else
                      Temp_Pos - 1
                    EndIf
                    *Object_Search\State = #Search_State_Search_Wait
                    *Object_Search\Update_Input = #True
                    Break
                  EndIf
                EndIf
              EndIf
              
              If *Object_Search\Direction = #Search_Direction_Forward
                *Ascii + 1 : Temp_Pos + 1
              Else
                *Ascii - 1 : Temp_Pos - 1
              EndIf
              
            Next
          Else
            *Object_Search\State = #Search_State_None
            *Object_Search\Update_Input = #True
            FreeMemory(*Temp)
            ProcedureReturn #True
          EndIf
          
          If *Object_Search\Direction = #Search_Direction_Backward
            Temp_Pos + 1
          EndIf
          
          *Object_Search\Position = Temp_Pos
          
        EndIf
        FreeMemory(*Temp)
      EndIf
      
    Case #Search_State_Replace_All
      ; #### Get the current segment
      Select *Object_Search\Direction
        Case #Search_Direction_Forward
          ForEach Object_Output_Segment()
            If Object_Output_Segment()\Metadata & #Metadata_Readable
              If Object_Output_Segment()\Position + Object_Output_Segment()\Size > *Object_Search\Position
                *Current_Segment = Object_Output_Segment()
                Break
              EndIf
            EndIf
          Next
          
        Case #Search_Direction_Backward
          If LastElement(Object_Output_Segment())
            Repeat
              If Object_Output_Segment()\Metadata & #Metadata_Readable
                If Object_Output_Segment()\Position < *Object_Search\Position
                  *Current_Segment = Object_Output_Segment()
                  Break
                EndIf
              EndIf
            Until Not PreviousElement(Object_Output_Segment())
          EndIf
          
      EndSelect
      
      If *Current_Segment
        ; #### Crop range to the segment
        Temp_Size = #Search_Chunk_Size
        If *Object_Search\Position < *Current_Segment\Position
          *Object_Search\Position = *Current_Segment\Position
        EndIf
        If *Object_Search\Position > *Current_Segment\Position + *Current_Segment\Size
          *Object_Search\Position = *Current_Segment\Position + *Current_Segment\Size
        EndIf
        Select *Object_Search\Direction
          Case #Search_Direction_Forward
            If Temp_Size > *Current_Segment\Size
              Temp_Size = *Current_Segment\Size
            EndIf
            If Temp_Size > *Current_Segment\Position + *Current_Segment\Size - *Object_Search\Position
              Temp_Size = *Current_Segment\Position + *Current_Segment\Size - *Object_Search\Position
            EndIf
            Temp_Pos = *Object_Search\Position
            
          Case #Search_Direction_Backward
            If Temp_Size > *Current_Segment\Size
              Temp_Size = *Current_Segment\Size
            EndIf
            If Temp_Size > *Object_Search\Position - *Current_Segment\Position
              Temp_Size = *Object_Search\Position - *Current_Segment\Position
            EndIf
            Temp_Pos = *Object_Search\Position - Temp_Size
            
        EndSelect
        
      Else
        ; #### Stop searching
        *Object_Search\State = #Search_State_None
        *Object_Search\Update_Input = #True
        ProcedureReturn #True
      EndIf
      
      *Temp = AllocateMemory(Temp_Size)
      If *Temp
        
        If Node::Input_Get_Data(FirstElement(*Node\Input()), Temp_Pos, Temp_Size, *Temp, #Null)
          
          Select *Object_Search\Direction
            Case #Search_Direction_Forward
              *Ascii = *Temp
              Temp_Pos = *Object_Search\Position
            Case #Search_Direction_Backward
              *Ascii = *Temp + Temp_Size - 1
              Temp_Pos = *Object_Search\Position - 1
          EndSelect
          
          If *Object_Search\Fast_Compare_Amount > 0
            For i = 1 To Temp_Size
              If *Ascii\a = *Object_Search\Fast_Compare[0]
                ; #### Give the helper function direct access to *Temp if possible
                If Temp_Size - (*Ascii - *Temp) >= *Object_Search\Raw_Keyword_Size
                  *Fast_Memory = *Ascii
                  Fast_Memory_Size = *Object_Search\Raw_Keyword_Size
                Else
                  *Fast_Memory = #Null
                  Fast_Memory_Size = 0
                EndIf
                If Search_Do_Helper(*Node, Temp_Pos, *Fast_Memory, Fast_Memory_Size)
                  *Object_Search\Found = #True
                  *Object_Search\Found_Position = Temp_Pos
                  *Object_Search\Found_Size = *Object_Search\Raw_Keyword_Size
                  Range_Set(*Node, Temp_Pos, Temp_Pos + *Object_Search\Raw_Replacement_Size, #False, #False, #False)
                  If *Object_Search\Direction = #Search_Direction_Forward
                    Temp_Pos + *Object_Search\Raw_Replacement_Size
                  Else
                    Temp_Pos - 1
                  EndIf
                  
                  Shift_Difference = *Object_Search\Raw_Replacement_Size - *Object_Search\Raw_Keyword_Size
                  If *Object_Search\No_Shifting Or Shift_Difference = 0
                    If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
                      Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
                      *Object_Search\State = #Search_State_None
                      *Object_Search\Update_Input = #True
                    EndIf
                  Else
                    If Node::Input_Shift(FirstElement(*Node\Input()), *Object_Search\Found_Position, Shift_Difference)
                      If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
                        Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
                        *Object_Search\State = #Search_State_None
                        *Object_Search\Update_Input = #True
                      EndIf
                    Else
                      Logger::Entry_Add_Error("Shifting failed", "The destination can't be shifted. Replace-Operation not successful.")
                      *Object_Search\State = #Search_State_None
                      *Object_Search\Update_Input = #True
                    EndIf
                  EndIf
                  
                  Break
                EndIf
              EndIf
              If *Object_Search\Fast_Compare_Amount > 1
                If *Ascii\a = *Object_Search\Fast_Compare[1]
                  ; #### Give the helper function direct access to *Temp if possible
                  If Temp_Size - (*Ascii - *Temp) >= *Object_Search\Raw_Keyword_Size
                    *Fast_Memory = *Ascii
                    Fast_Memory_Size = *Object_Search\Raw_Keyword_Size
                  Else
                    *Fast_Memory = #Null
                    Fast_Memory_Size = 0
                  EndIf
                  If Search_Do_Helper(*Node, Temp_Pos, *Fast_Memory, Fast_Memory_Size)
                    *Object_Search\Found = #True
                    *Object_Search\Found_Position = Temp_Pos
                    *Object_Search\Found_Size = *Object_Search\Raw_Keyword_Size
                    Range_Set(*Node, Temp_Pos, Temp_Pos + *Object_Search\Raw_Replacement_Size, #False, #False, #False)
                    If *Object_Search\Direction = #Search_Direction_Forward
                      Temp_Pos + *Object_Search\Raw_Replacement_Size
                    Else
                      Temp_Pos - 1
                    EndIf
                    
                    Shift_Difference = *Object_Search\Raw_Replacement_Size - *Object_Search\Raw_Keyword_Size
                    If *Object_Search\No_Shifting Or Shift_Difference = 0
                      If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
                        Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
                        *Object_Search\State = #Search_State_None
                        *Object_Search\Update_Input = #True
                      EndIf
                    Else
                      If Node::Input_Shift(FirstElement(*Node\Input()), *Object_Search\Found_Position, Shift_Difference)
                        If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object_Search\Found_Position, *Object_Search\Raw_Replacement_Size, *Object_Search\Raw_Replacement)
                          Logger::Entry_Add_Error("Couldn't replace keyword", "The destination is probably in read only mode. Replace-Operation not successful.")
                          *Object_Search\State = #Search_State_None
                          *Object_Search\Update_Input = #True
                        EndIf
                      Else
                        Logger::Entry_Add_Error("Shifting failed", "The destination can't be shifted. Replace-Operation not successful.")
                        *Object_Search\State = #Search_State_None
                        *Object_Search\Update_Input = #True
                      EndIf
                    EndIf
                    
                    Break
                  EndIf
                EndIf
              EndIf
              
              If *Object_Search\Direction = #Search_Direction_Forward
                *Ascii + 1 : Temp_Pos + 1
              Else
                *Ascii - 1 : Temp_Pos - 1
              EndIf

            Next
          Else
            *Object_Search\State = #Search_State_None
            *Object_Search\Update_Input = #True
            FreeMemory(*Temp)
            ProcedureReturn #True
          EndIf
          
          If *Object_Search\Direction = #Search_Direction_Backward
            Temp_Pos + 1
          EndIf
          
          *Object_Search\Position = Temp_Pos
          
        EndIf
        FreeMemory(*Temp)
      EndIf
      
      
  EndSelect
  
EndProcedure

Procedure Search_Main(*Node.Node::Object)
  Protected Time
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Search.Search = *Object\Window_Search
  If Not *Object_Search
    ProcedureReturn #False
  EndIf
  
  If *Object_Search\State = #Search_State_Search Or *Object_Search\State = #Search_State_Replace_All
    Time = ElapsedMilliseconds() + 30
    Repeat
      Search_Do(*Node)
    Until Time < ElapsedMilliseconds()
    
    *Object_Search\Update_State = #True
  EndIf
  
  If *Object_Search\Window
    If *Object_Search\Update_State
      *Object_Search\Update_State = #False
      Search_Window_Update_State(*Node)
    EndIf
    If *Object_Search\Update_Input
      *Object_Search\Update_Input = #False
      Search_Window_Update_Input(*Node)
    EndIf
  EndIf
  
  If *Object_Search\Window_Close
    *Object_Search\Window_Close = #False
    Search_Window_Close(*Node)
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1407
; FirstLine = 1438
; Folding = -----
; EnableUnicode
; EnableXP