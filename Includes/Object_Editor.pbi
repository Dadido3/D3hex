; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2014  David Vogel
; 
;     This program is free software; you can redistribute it and/or modify
;     it under the terms of the GNU General Public License As published by
;     the Free Software Foundation; either version 2 of the License, or
;     (at your option) any later version.
; 
;     This program is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY Or FITNESS For A PARTICULAR PURPOSE.  See the
;     GNU General Public License For more details.
; 
;     You should have received a copy of the GNU General Public License along
;     With this program; if not, write to the Free Software Foundation, Inc.,
;     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
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

Procedure Object_Editor_InRange(Position_A.q, Position_B.q, Position.q)
  If Position >= Position_A And Position < Position_B
    ProcedureReturn #True
  ElseIf Position >= Position_B And Position < Position_A
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure

; ##################################################### Constants ###################################################

Enumeration
  #Object_Editor_Menu_Search
  #Object_Editor_Menu_Search_Continue
  #Object_Editor_Menu_Goto
  
  #Object_Editor_Menu_Cut
  #Object_Editor_Menu_Copy
  #Object_Editor_Menu_Paste
  
  #Object_Editor_Menu_Undo
  #Object_Editor_Menu_Redo
  
  ; ----------------------------
  
  #Object_Editor_PopupMenu_Cut
  #Object_Editor_PopupMenu_Copy
  #Object_Editor_PopupMenu_Paste
  
  #Object_Editor_PopupMenu_Select_All
EndEnumeration

Enumeration
  #Object_Editor_WriteMode_Overwrite
  #Object_Editor_WriteMode_Insert
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_Editor_Main
  *Object_Type.Object_Type
  
  Font_ID.i
  Font_Width.l
  Font_Height.l
  
  PopUpMenu.i
EndStructure
Global Object_Editor_Main.Object_Editor_Main

Structure Object_Editor_Segment
  Line_Start.q            ; Line where the segment starts
  Line_Amount.q           ; Amount of lines, including the range-description line
  
  Start.q
  Size.q
  
  Metadata.a
  Name.s
  
  Collapsed.l             ; True if the element should be hidden.
  
  *Raw_Data               ; Temp_Data, to be updated in Object_Editor_Organize()
  *Raw_Metadata           ; Temp_Metadata, to be updated in Object_Editor_Organize()
  Raw_Data_Size.q         ; Size of the Data
  Raw_Data_Start.q        ; Where the data starts. (Absolute in bytes)
  Raw_Data_Line_Start.q   ; Line where the data starts. (Absolute in lines)
  Raw_Data_Byte_Start.l   ; X-Position (Byte) where the data starts.
  
  Temp_New.l              ; The segment is new
EndStructure

Structure Object_Editor
  *Window.Window
  Window_Close.l
  
  ; #### Editor-Gadget stuff
  ToolBar.i
  Canvas.i
  ScrollBar.i
  Redraw.l
  X0.l                    ; X-Offset of the data stuff
  X1.l                    ; X-Offset of the ascii stuff
  X2.l                    ; X-Offset of the end of the ascii stuff
  Y0.l                    ; Y-Offset of ascii/data stuff
  List Segment.Object_Editor_Segment()
  
  Data_Size.q
  
  Scroll_Line.q           ; Offset of the top line
  Scroll_Lines.q          ; Number of scrollable lines
  Scroll_Divider.q        ; Divider for the scrollbar, because it can only handle 2^32 lines
  Lines.q                 ; Visible lines in the Editor-Window
  Adress_Length.l         ; Length of the adress in chars
  
  Line_Bytes.l            ; Amount of Bytes per Line
  
  *Menu_Object            ; Object the menu is displayed for
  
  ; #### Selection
  Select_Field.l          ; Whether it is the Hex-field (0) or the Ascii-field (1)
  Select_Start.q
  Select_End.q
  Select_Active.l
  Select_Nibble.l         ; If the next nibble of the byte is selected.
  
  Temp_Nibble.i           ; True if "Temp_Nibble_Value" contains a value
  Temp_Nibble_Value.a     ; The first nibble of each byte while writing goes here.
  
  Write_Mode.l
  
  ; #### Other Windows
  *Window_Goto.Object_Editor_Goto
  *Window_Search.Object_Editor_Search
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

Object_Editor_Main\Font_ID = LoadFont(#PB_Any, "Courier New", 10)
Define Temp_Image = CreateImage(#PB_Any, 1, 1)
If StartDrawing(ImageOutput(Temp_Image))
  DrawingFont(FontID(Object_Editor_Main\Font_ID))
  Object_Editor_Main\Font_Width = TextWidth("0")
  Object_Editor_Main\Font_Height = TextHeight("0")
  StopDrawing()
EndIf
FreeImage(Temp_Image)

; ##################################################### Declares ####################################################

Declare   Object_Editor_Main(*Object.Object)
Declare   _Object_Editor_Delete(*Object.Object)
Declare   Object_Editor_Window_Open(*Object.Object)

Declare   Object_Editor_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Editor_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Editor_Event(*Object.Object, *Object_Event.Object_Event)
Declare   Object_Editor_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_Editor_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare   Object_Editor_Output_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare.s Object_Editor_Output_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Editor_Output_Get_Size(*Object_Output.Object_Output)
Declare   Object_Editor_Output_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Editor_Output_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Editor_Output_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Editor_Output_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Editor_Output_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Editor_Cut(*Object.Object)
Declare   Object_Editor_Copy(*Object.Object)
Declare   Object_Editor_Paste(*Object.Object)

Declare   Object_Editor_Remove_Data(*Object.Object, Bytes.q, Backspace=#False)
Declare   Object_Editor_Write_Data(*Object.Object, *Data, Size.i)
Declare   Object_Editor_Write_Nibble(*Object.Object, Char.a, Abort.i=#False)

Declare   Object_Editor_Scroll_2_Cursor(*Object.Object)
Declare   Object_Editor_Range_Set(*Object.Object, Select_Start.q, Select_End.q, Select_Nibble.i, Scroll_2_Cursor=#False, Redraw=#True)

Declare   Object_Editor_Window_Close(*Object.Object)

; ##################################################### Includes ####################################################

XIncludeFile "Object_Editor_Goto.pbi"
XIncludeFile "Object_Editor_Search.pbi"

; ##################################################### Procedures ##################################################

Procedure Object_Editor_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Editor.Object_Editor
  Protected *Object_Output.Object_Output
  Protected *Object_Input.Object_Input
  
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  *Object\Type = Object_Editor_Main\Object_Type
  *Object\Type_Base = Object_Editor_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Editor_Delete()
  *Object\Function_Main = @Object_Editor_Main()
  *Object\Function_Event = @Object_Editor_Event()
  *Object\Function_Window = @Object_Editor_Window_Open()
  *Object\Function_Configuration_Get = @Object_Editor_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Editor_Configuration_Set()
  
  *Object\Name = "Editor"
  *Object\Color = RGBA(127, 127, 127, 255)
  
  *Object_Editor = AllocateMemory(SizeOf(Object_Editor))
  *Object\Custom_Data = *Object_Editor
  InitializeStructure(*Object_Editor, Object_Editor)
  
  *Object_Editor\Window_Goto = AllocateMemory(SizeOf(Object_Editor_Goto))
  InitializeStructure(*Object_Editor\Window_Goto, Object_Editor_Goto)
  
  *Object_Editor\Window_Search = AllocateMemory(SizeOf(Object_Editor_Search))
  InitializeStructure(*Object_Editor\Window_Search, Object_Editor_Search)
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Function_Event = @Object_Editor_Input_Event()
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object, "Selection", "Selection")
  *Object_Output\Function_Event = @Object_Editor_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Editor_Output_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Editor_Output_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Editor_Output_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Editor_Output_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Editor_Output_Set_Data()
  *Object_Output\Function_Convolute = @Object_Editor_Output_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Editor_Output_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Editor_Output_Convolute_Check()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Editor_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Object_Editor_Window_Close(*Object)
  Object_Editor_Goto_Window_Close(*Object)
  Object_Editor_Search_Window_Close(*Object)
  
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Raw_Data
      FreeMemory(*Object_Editor\Segment()\Raw_Data)
    EndIf
  Next
  
  ClearStructure(*Object_Editor\Window_Goto, Object_Editor_Goto)
  FreeMemory(*Object_Editor\Window_Goto)
  
  ClearStructure(*Object_Editor\Window_Search, Object_Editor_Search)
  FreeMemory(*Object_Editor\Window_Search)
  
  ClearStructure(*Object_Editor, Object_Editor)
  FreeMemory(*Object_Editor)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Scroll_Line", #NBT_Tag_Quad)   : NBT_Tag_Set_Number(*NBT_Tag, *Object_Editor\Scroll_Line)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Select_Start", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_Editor\Select_Start)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Select_End", #NBT_Tag_Quad)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_Editor\Select_End)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Select_Nibble", #NBT_Tag_Quad) : NBT_Tag_Set_Number(*NBT_Tag, *Object_Editor\Select_Nibble)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Write_Mode", #NBT_Tag_Quad)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_Editor\Write_Mode)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Scroll_Line")    : *Object_Editor\Scroll_Line = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Select_Start")   : *Object_Editor\Select_Start = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Select_End")     : *Object_Editor\Select_End = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Select_Nibble")  : *Object_Editor\Select_Nibble = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Write_Mode")     : *Object_Editor\Write_Mode = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Event(*Object.Object, *Object_Event.Object_Event)
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select *Object_Event\Type
    Case #Object_Event_Save
      Object_Event\Type = #Object_Event_Save
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Event_SaveAs
      Object_Event\Type = #Object_Event_SaveAs
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Event_Undo
      Object_Event\Type = #Object_Event_Undo
      Object_Event\Value[0] = #True ; Combine Convolution and Write
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Event_Redo
      Object_Event\Type = #Object_Event_Redo
      Object_Event\Value[0] = #True ; Combine Convolution and Write
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Event_Cut
      Object_Editor_Cut(*Object)
      
    Case #Object_Event_Copy
      Object_Editor_Copy(*Object)
      
    Case #Object_Event_Paste
      Object_Editor_Paste(*Object)
      
    Case #Object_Event_Goto
      Object_Editor_Goto_Window_Open(*Object)
      
    Case #Object_Event_Search
      Object_Editor_Search_Window_Open(*Object)
      
    Case #Object_Event_Search_Continue
      Object_Editor_Search_Continue(*Object)
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Input\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q
  Protected Object_Event.Object_Event
  
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Start = *Object_Editor\Select_Start
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Start = *Object_Editor\Select_End
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update
      *Object_Editor\Redraw = #True
      ; #### Forward the event to the selection-output
      ;If *Object_Event\Position + *Object_Event\Size > Start And *Object_Event\Position < Start + Length
        Object_Event\Type = #Object_Link_Event_Update
        Object_Event\Position = *Object_Event\Position - Start
        Object_Event\Size = *Object_Event\Size
        Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
      ;EndIf
      
    Case #Object_Link_Event_Goto
      *Object_Editor\Select_Start = *Object_Event\Position
      *Object_Editor\Select_End = *Object_Event\Position + *Object_Event\Size
      *Object_Editor\Select_Nibble = #False
      *Object_Editor\Temp_Nibble = #False ; #### Throw away the nibble-operation
      Object_Editor_Scroll_2_Cursor(*Object)
      *Object_Editor\Redraw = #True
      ; #### Send a Update event to the selection-output
      Object_Event\Type = #Object_Link_Event_Update
      Object_Event\Position = 0
      Object_Event\Size = Length
      Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Event_Save
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      
    Case #Object_Event_SaveAs
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      
    Case #Object_Event_Undo
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      
    Case #Object_Event_Redo
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Output_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure.s Object_Editor_Output_Get_Descriptor(*Object_Output.Object_Output)
  Protected Descriptor.s
  If Not *Object_Output
    ProcedureReturn ""
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn ""
  EndIf
  
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn ""
  EndIf
  
  ProcedureReturn ""
EndProcedure

Procedure.q Object_Editor_Output_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn -1
  EndIf
  
  Protected Start.q, Length.q
  
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Start = *Object_Editor\Select_Start
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Start = *Object_Editor\Select_End
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If Start > Object_Input_Get_Size(FirstElement(*Object\Input()))
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn Length
EndProcedure

Procedure Object_Editor_Output_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  If Size <= 0
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q
  
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Start = *Object_Editor\Select_Start
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Start = *Object_Editor\Select_End
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  ProcedureReturn Object_Input_Get_Data(FirstElement(*Object\Input()), Start+Position, Size, *Data, *Metadata)
EndProcedure

Procedure Object_Editor_Output_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Not *Data
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  If Size <= 0
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q
  
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Start = *Object_Editor\Select_Start
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Start = *Object_Editor\Select_End
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If Start + Position <= Object_Input_Get_Size(FirstElement(*Object\Input()))
    If Object_Input_Set_Data(FirstElement(*Object\Input()), Start + Position, Size, *Data)
      If *Object_Editor\Select_End >= *Object_Editor\Select_Start
        If Start + Position + Size > *Object_Editor\Select_End
          Object_Editor_Range_Set(*Object, -1, Start + Position + Size, #False, #True)
        EndIf
      Else
        If Start + Position + Size > *Object_Editor\Select_Start
          Object_Editor_Range_Set(*Object, Start + Position + Size, -1, #False, #True)
        EndIf
      EndIf
      ProcedureReturn #True
    EndIf
  EndIf
  
  ProcedureReturn 
EndProcedure

Procedure Object_Editor_Output_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q
  
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Start = *Object_Editor\Select_Start
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Start = *Object_Editor\Select_End
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If -Offset > Length - Position
    Offset = - Length + Position
  EndIf
  
  If Start + Position <= Object_Input_Get_Size(FirstElement(*Object\Input()))
    If Object_Input_Convolute(FirstElement(*Object\Input()), Start + Position, Offset)
      If *Object_Editor\Select_End >= *Object_Editor\Select_Start
        Object_Editor_Range_Set(*Object, -1, *Object_Editor\Select_End + Offset, #False, #True)
      Else
        Object_Editor_Range_Set(*Object, *Object_Editor\Select_Start + Offset, -1, #False, #True)
      EndIf
      ProcedureReturn #True
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Editor_Output_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Input_Set_Data_Check(FirstElement(*Object\Input()), Position.q, Size.i)
EndProcedure

Procedure Object_Editor_Output_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Input_Convolute_Check(FirstElement(*Object\Input()), Position.q, Offset.q)
EndProcedure

Procedure Object_Editor_Organize(*Object.Object)
  Protected Temp_Line.q
  Protected NewList Object_Output_Segment.Object_Output_Segment()
  Protected *Object_Output_Segment.Object_Output_Segment
  Protected *Object_Editor_Segment.Object_Editor_Segment
  Protected Temp_Index
  ;Protected Found
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ; #### Set general information
  
  *Object_Editor\Line_Bytes = 16
  
  ; #### Get general information
  
  *Object_Editor\Data_Size = Object_Input_Get_Size(FirstElement(*Object\Input()))
  
  If *Object_Editor\Data_Size < 0
    ; #### No data is available
    *Object_Editor\Data_Size = 0
    
    While FirstElement(*Object_Editor\Segment())
      If *Object_Editor\Segment()\Raw_Data
        FreeMemory(*Object_Editor\Segment()\Raw_Data)
      EndIf
      DeleteElement(*Object_Editor\Segment())
    Wend
    
  Else
    
    ; #### Get segments
    Object_Input_Get_Segments(FirstElement(*Object\Input()), Object_Output_Segment())
    
    ; #### Update semgents of the editor with the segments of the input
    *Object_Output_Segment = FirstElement(Object_Output_Segment())
    *Object_Editor_Segment = FirstElement(*Object_Editor\Segment())
    While *Object_Output_Segment And *Object_Editor_Segment
      If *Object_Output_Segment\Position = *Object_Editor_Segment\Start
        If *Object_Editor_Segment\Size <> *Object_Output_Segment\Size
          ; #### Just update the length of the segment
          *Object_Editor_Segment\Metadata = *Object_Output_Segment\Metadata
          *Object_Editor_Segment\Size = *Object_Output_Segment\Size
          If *Object_Editor_Segment\Line_Start + *Object_Editor_Segment\Line_Amount <= *Object_Editor\Scroll_Line
            *Object_Editor\Scroll_Line - *Object_Editor_Segment\Line_Amount
          EndIf
          If *Object_Output_Segment\Metadata & #Metadata_Readable
            *Object_Editor_Segment\Collapsed = #False
          Else
            *Object_Editor_Segment\Collapsed = #True
          EndIf
          *Object_Editor_Segment\Temp_New = #True
        EndIf
        *Object_Output_Segment = NextElement(Object_Output_Segment())
        *Object_Editor_Segment = NextElement(*Object_Editor\Segment())
      ElseIf *Object_Editor_Segment\Start < *Object_Output_Segment\Position
        ; #### Remove the segment
        If *Object_Editor_Segment\Line_Start + *Object_Editor_Segment\Line_Amount <= *Object_Editor\Scroll_Line
          *Object_Editor\Scroll_Line - *Object_Editor_Segment\Line_Amount
        EndIf
        Temp_Index = ListIndex(*Object_Editor\Segment())
        DeleteElement(*Object_Editor\Segment(), #True)
        *Object_Editor_Segment = SelectElement(*Object_Editor\Segment(), Temp_Index)
      Else
        ; #### Insert a segment
        *Object_Editor_Segment = InsertElement(*Object_Editor\Segment())
        *Object_Editor_Segment\Metadata = *Object_Output_Segment\Metadata
        *Object_Editor_Segment\Start = *Object_Output_Segment\Position
        *Object_Editor_Segment\Size = *Object_Output_Segment\Size
        *Object_Editor_Segment\Temp_New = #True
        If *Object_Output_Segment\Metadata & #Metadata_Readable
          *Object_Editor_Segment\Collapsed = #False
        Else
          *Object_Editor_Segment\Collapsed = #True
        EndIf
      EndIf
    Wend
    While ListSize(Object_Output_Segment()) < ListSize(*Object_Editor\Segment())
      ; #### Remove the last segment
      If LastElement(*Object_Editor\Segment())
        If *Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount <= *Object_Editor\Scroll_Line
          *Object_Editor\Scroll_Line - *Object_Editor\Segment()\Line_Amount
        EndIf
        DeleteElement(*Object_Editor\Segment())
      EndIf
    Wend
    While ListSize(Object_Output_Segment()) > ListSize(*Object_Editor\Segment())
      If SelectElement(Object_Output_Segment(), ListSize(*Object_Editor\Segment()))
        ; #### Insert a segment
        LastElement(*Object_Editor\Segment())
        If AddElement(*Object_Editor\Segment())
          *Object_Editor\Segment()\Metadata = Object_Output_Segment()\Metadata
          *Object_Editor\Segment()\Start = Object_Output_Segment()\Position
          *Object_Editor\Segment()\Size = Object_Output_Segment()\Size
          *Object_Editor\Segment()\Temp_New = #True
          If Object_Output_Segment()\Metadata & #Metadata_Readable
            *Object_Editor\Segment()\Collapsed = #False
          Else
            *Object_Editor\Segment()\Collapsed = #True
          EndIf
        EndIf
      EndIf
    Wend
    
    ; #### If no segments available, create one
    If ListSize(Object_Output_Segment()) = 0
      If ListSize(*Object_Editor\Segment()) = 0
        AddElement(*Object_Editor\Segment())
      EndIf
      If FirstElement(*Object_Editor\Segment())
        *Object_Editor\Segment()\Start = 0
        *Object_Editor\Segment()\Size = *Object_Editor\Data_Size
      EndIf
    EndIf
    
  EndIf
  
  ; #### Calculate Segment stuff
  Temp_Line = 0
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Size < 0
      *Object_Editor\Segment()\Size = 0
    EndIf
    
    ; #### Arrange the segments one after another
    *Object_Editor\Segment()\Line_Start = Temp_Line
    
    ; #### Update the amount of lines the segment needs (including range header)
    If *Object_Editor\Segment()\Collapsed
      *Object_Editor\Segment()\Line_Amount = 1
    Else
      *Object_Editor\Segment()\Line_Amount = 2 + (*Object_Editor\Segment()\Size + *Object_Editor\Segment()\Start % *Object_Editor\Line_Bytes) / *Object_Editor\Line_Bytes
    EndIf
    
    If *Object_Editor\Segment()\Temp_New
      *Object_Editor\Segment()\Temp_New = #False
      If *Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount <= *Object_Editor\Scroll_Line
        *Object_Editor\Scroll_Line + *Object_Editor\Segment()\Line_Amount
      EndIf
    EndIf
    
    Temp_Line + *Object_Editor\Segment()\Line_Amount
  Next
  *Object_Editor\Scroll_Lines = Temp_Line
  
  ; #### Window values
  Protected Width = GadgetWidth(*Object_Editor\Canvas)
  Protected Height = GadgetHeight(*Object_Editor\Canvas)
  
  *Object_Editor\Adress_Length = Len(Hex(*Object_Editor\Data_Size, #PB_Quad))
  
  *Object_Editor\Y0 = Object_Editor_Main\Font_Height * 1.5
  *Object_Editor\X0 = Object_Editor_Main\Font_Width * (*Object_Editor\Adress_Length + 2)
  *Object_Editor\X1 = *Object_Editor\X0 + Object_Editor_Main\Font_Width * (*Object_Editor\Line_Bytes * 3 + 1)
  *Object_Editor\X2 = *Object_Editor\X1 + Object_Editor_Main\Font_Width * (*Object_Editor\Line_Bytes + 1)
  
  *Object_Editor\Lines = Quad_Divide_Ceil(Height - *Object_Editor\Y0, Object_Editor_Main\Font_Height)
  
  *Object_Editor\Scroll_Divider = Quad_Divide_Ceil(*Object_Editor\Scroll_Lines, 2147483647)
  If *Object_Editor\Scroll_Divider < 1 : *Object_Editor\Scroll_Divider = 1 : EndIf
  SetGadgetAttribute(*Object_Editor\ScrollBar, #PB_ScrollBar_Maximum, *Object_Editor\Scroll_Lines / *Object_Editor\Scroll_Divider)
  SetGadgetAttribute(*Object_Editor\ScrollBar, #PB_ScrollBar_PageLength, *Object_Editor\Lines / *Object_Editor\Scroll_Divider)
  SetGadgetState(*Object_Editor\ScrollBar, *Object_Editor\Scroll_Line / *Object_Editor\Scroll_Divider)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Get_Data(*Object.Object)
  Protected Data_Size.q
  Protected Raw_Data_End.q
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Collapsed
      *Object_Editor\Segment()\Raw_Data_Start = 0
      *Object_Editor\Segment()\Raw_Data_Size = 0
    Else
      If *Object_Editor\Segment()\Line_Start < *Object_Editor\Scroll_Line + *Object_Editor\Lines And *Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount > *Object_Editor\Scroll_Line
        
        ; #### Calculate the start of the raw_data
        *Object_Editor\Segment()\Raw_Data_Start = *Object_Editor\Segment()\Start - *Object_Editor\Segment()\Start % *Object_Editor\Line_Bytes
        *Object_Editor\Segment()\Raw_Data_Start - (*Object_Editor\Segment()\Line_Start + 1 - *Object_Editor\Scroll_Line) * *Object_Editor\Line_Bytes
        
        If *Object_Editor\Segment()\Raw_Data_Start < *Object_Editor\Segment()\Start
          *Object_Editor\Segment()\Raw_Data_Start = *Object_Editor\Segment()\Start
        EndIf
        
        *Object_Editor\Segment()\Raw_Data_Byte_Start = *Object_Editor\Segment()\Raw_Data_Start % *Object_Editor\Line_Bytes
        
        ; #### Figure out which line (absolute) that actually is.
        *Object_Editor\Segment()\Raw_Data_Line_Start = *Object_Editor\Segment()\Line_Start + 1 + (*Object_Editor\Segment()\Raw_Data_Start - *Object_Editor\Segment()\Start + *Object_Editor\Segment()\Start % *Object_Editor\Line_Bytes) / *Object_Editor\Line_Bytes
        
        ; #### Calculate the size of the raw_data (Get the maximum possible size from the Raw_Data_Start to the end of the segment)
        *Object_Editor\Segment()\Raw_Data_Size = *Object_Editor\Segment()\Size - (*Object_Editor\Segment()\Raw_Data_Start - *Object_Editor\Segment()\Start)
        
        ; #### Cut it to the window if needed.
        If *Object_Editor\Segment()\Raw_Data_Size > (*Object_Editor\Scroll_Line + *Object_Editor\Lines - *Object_Editor\Segment()\Line_Start - 1) * *Object_Editor\Line_Bytes - *Object_Editor\Segment()\Raw_Data_Byte_Start - (*Object_Editor\Segment()\Raw_Data_Start - *Object_Editor\Segment()\Start)
          *Object_Editor\Segment()\Raw_Data_Size = (*Object_Editor\Scroll_Line + *Object_Editor\Lines - *Object_Editor\Segment()\Line_Start - 1) * *Object_Editor\Line_Bytes - *Object_Editor\Segment()\Raw_Data_Byte_Start - (*Object_Editor\Segment()\Raw_Data_Start - *Object_Editor\Segment()\Start)
        EndIf
        
        ; #### Allocate the memory
        If *Object_Editor\Segment()\Raw_Data
          FreeMemory(*Object_Editor\Segment()\Raw_Data)
          FreeMemory(*Object_Editor\Segment()\Raw_Metadata)
          *Object_Editor\Segment()\Raw_Data = #Null
          *Object_Editor\Segment()\Raw_Metadata = #Null
        EndIf
        If *Object_Editor\Segment()\Raw_Data_Size > 0
          *Object_Editor\Segment()\Raw_Data = AllocateMemory(*Object_Editor\Segment()\Raw_Data_Size)
          *Object_Editor\Segment()\Raw_Metadata = AllocateMemory(*Object_Editor\Segment()\Raw_Data_Size)
        EndIf
        
        ; #### Get the data.
        If *Object_Editor\Segment()\Raw_Data_Size > 0
          Object_Input_Get_Data(FirstElement(*Object\Input()), *Object_Editor\Segment()\Raw_Data_Start, *Object_Editor\Segment()\Raw_Data_Size, *Object_Editor\Segment()\Raw_Data, *Object_Editor\Segment()\Raw_Metadata)
        EndIf
        
      EndIf
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Canvas_Redraw_Filter_Blink(x, y, SourceColor, TargetColor)
  If (x+y) & 1
    ProcedureReturn ~TargetColor
  Else
    ProcedureReturn TargetColor
  EndIf
EndProcedure

Procedure Object_Editor_Canvas_Redraw_Filter_Inverse(x, y, SourceColor, TargetColor)
  ProcedureReturn ~TargetColor
EndProcedure

Procedure Object_Editor_Canvas_Redraw(*Object.Object)
  Protected i
  Protected D_X.q, D_Y.q  ; Data-Coordinates
  Protected S_Y.q         ; Y-Screen-Coordinate of a line (Offset, Hex, Ascii)
  Protected Hex_X.q       ; X-Screen-Coordinates of the hexfield
  Protected Ascii_X.q     ; X-Screen-Coordinates of the Asciifield
  Protected Temp_Adress.q
  Protected Color_Front, Color_Back
  Protected Metadata.a
  Protected String_Ascii.s{1}
  Protected String_Hex.s{2}
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  Protected Width = GadgetWidth(*Object_Editor\Canvas)
  Protected Height = GadgetHeight(*Object_Editor\Canvas)
  
  If Not StartDrawing(CanvasOutput(*Object_Editor\Canvas))
    ProcedureReturn #False
  EndIf
  
  Box(0, 0, Width, Height, RGB(255,255,255))
  
  DrawingFont(FontID(Object_Editor_Main\Font_ID))
  
  FrontColor(RGB(0,0,255))
  BackColor(RGB(255,255,255))
  
  DrawText(0, 0, Str(*Object_Editor\Scroll_Line))
  
  ; #### Display the Adress in X-Direction
  For i = 0 To *Object_Editor\Line_Bytes - 1
    Hex_X = *Object_Editor\X0 + i * Object_Editor_Main\Font_Width * 3
    DrawText(Hex_X, 0, RSet(Hex(i),2,"0"))
  Next
  
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Line_Start < *Object_Editor\Scroll_Line + *Object_Editor\Lines And *Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount > *Object_Editor\Scroll_Line
      
      ; #### Display the range of the segment
      FrontColor(RGB(255,0,0))
      D_X = 0
      D_Y = *Object_Editor\Segment()\Line_Start - *Object_Editor\Scroll_Line
      If D_Y >= 0 And D_Y < *Object_Editor\Lines
        Hex_X = *Object_Editor\X0 + D_X * Object_Editor_Main\Font_Width * 3
        S_Y = *Object_Editor\Y0 + D_Y * Object_Editor_Main\Font_Height
        Line(0, S_Y-1, Width, 0, RGB(200,200,200))
        If *Object_Editor\Segment()\Size > 0
          If *Object_Editor\Segment()\Collapsed
            DrawText(Hex_X, S_Y, "[+] Range = [h"+RSet(Hex(*Object_Editor\Segment()\Start),*Object_Editor\Adress_Length,"0")+"-h"+RSet(Hex(*Object_Editor\Segment()\Start+*Object_Editor\Segment()\Size-1),*Object_Editor\Adress_Length,"0")+"]; Size = h"+RSet(Hex(*Object_Editor\Segment()\Size),*Object_Editor\Adress_Length,"0"))
          Else
            DrawText(Hex_X, S_Y, "[-] Range = [h"+RSet(Hex(*Object_Editor\Segment()\Start),*Object_Editor\Adress_Length,"0")+"-h"+RSet(Hex(*Object_Editor\Segment()\Start+*Object_Editor\Segment()\Size-1),*Object_Editor\Adress_Length,"0")+"]; Size = h"+RSet(Hex(*Object_Editor\Segment()\Size),*Object_Editor\Adress_Length,"0"))
          EndIf
        Else
          If *Object_Editor\Segment()\Collapsed
            DrawText(Hex_X, S_Y, "[+] Size = h"+RSet(Hex(*Object_Editor\Segment()\Size),*Object_Editor\Adress_Length,"0"))
          Else
            DrawText(Hex_X, S_Y, "[-] Size = h"+RSet(Hex(*Object_Editor\Segment()\Size),*Object_Editor\Adress_Length,"0"))
          EndIf
        EndIf
      EndIf
      
      ; #### Draw the adresses left of the data
      D_Y = *Object_Editor\Segment()\Raw_Data_Line_Start - *Object_Editor\Scroll_Line
      Temp_Adress = *Object_Editor\Segment()\Raw_Data_Start
      Temp_Adress - Temp_Adress % *Object_Editor\Line_Bytes
      For i = 0 To (*Object_Editor\Segment()\Raw_Data_Size + *Object_Editor\Segment()\Raw_Data_Byte_Start) / *Object_Editor\Line_Bytes ;Int_Divide_RUP(*Object_Editor\Segment()\Raw_Data_Size, *Object_Editor\Line_Bytes)
        S_Y = *Object_Editor\Y0 + D_Y * Object_Editor_Main\Font_Height
        DrawText(0, S_Y, RSet(Hex(Temp_Adress),*Object_Editor\Adress_Length,"0"), RGB(0,0,255))
        Temp_Adress + *Object_Editor\Line_Bytes
        D_Y + 1
      Next
      
      ; #### Display the data of the segment
      FrontColor(RGB(0,0,0))
      D_X = *Object_Editor\Segment()\Raw_Data_Byte_Start
      D_Y = *Object_Editor\Segment()\Raw_Data_Line_Start - *Object_Editor\Scroll_Line
      S_Y = *Object_Editor\Y0 + D_Y * Object_Editor_Main\Font_Height
      Temp_Adress = *Object_Editor\Segment()\Raw_Data_Start
      
      For i = 0 To *Object_Editor\Segment()\Raw_Data_Size-1
        
        Metadata = PeekA(*Object_Editor\Segment()\Raw_Metadata+i)
        
        If Object_Editor_InRange(*Object_Editor\Select_Start, *Object_Editor\Select_End, Temp_Adress)
          Color_Front = RGB(255,255,255)
          Color_Back = RGB(51,153,255)
          If Metadata & #Metadata_NoError
            If Metadata & #Metadata_Readable
              String_Hex = RSet(Hex(PeekA(*Object_Editor\Segment()\Raw_Data+i)),2,"0")
              String_Ascii = PeekS(*Object_Editor\Segment()\Raw_Data+i, 1, #PB_Ascii)
            Else
              String_Hex = "??"
              String_Ascii = "?"
            EndIf
          Else
            String_Hex = "!!"
            String_Ascii = "!"
          EndIf
        Else
          If Metadata & #Metadata_NoError
            If Metadata & #Metadata_Readable
              If Metadata & #Metadata_Changed
                Color_Front = RGB(0,0,255)
                Color_Back = RGB(255,255,255)
              Else
                Color_Front = RGB(0,0,0)
                Color_Back = RGB(255,255,255)
              EndIf
              String_Hex = RSet(Hex(PeekA(*Object_Editor\Segment()\Raw_Data+i)),2,"0")
              String_Ascii = PeekS(*Object_Editor\Segment()\Raw_Data+i, 1, #PB_Ascii)
            Else
              Color_Front = RGB(255,0,0)
              Color_Back = RGB(255,255,255)
              String_Hex = "??"
              String_Ascii = "?"
            EndIf
          Else
            Color_Front = RGB(255,0,0)
            Color_Back = RGB(255,255,255)
            String_Hex = "!!"
            String_Ascii = "!"
          EndIf
        EndIf
        
        ; #### Draw the Text
        Hex_X = *Object_Editor\X0 + D_X * Object_Editor_Main\Font_Width * 3
        DrawText(Hex_X, S_Y, String_Hex+" ", Color_Front, Color_Back)
        Ascii_X = *Object_Editor\X1 + D_X * Object_Editor_Main\Font_Width
        DrawText(Ascii_X, S_Y, String_Ascii, Color_Front, Color_Back)
        
        ; #### Draw the cursors
        If Temp_Adress = *Object_Editor\Select_End
          ; #### Draw the Temp_Nibble
          If *Object_Editor\Temp_Nibble
            DrawText(Hex_X, S_Y, Hex(*Object_Editor\Temp_Nibble_Value), RGB(0,0,255), Color_Back)
          EndIf
          
          DrawingMode(#PB_2DDrawing_Outlined | #PB_2DDrawing_CustomFilter)
          If *Object_Editor\Select_Field = 0
            ; #### Hex selected
            CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Inverse())
            If *Object_Editor\Select_Nibble
              Hex_X + Object_Editor_Main\Font_Width
            EndIf
            If *Object_Editor\Write_Mode = 0
              Box(Hex_X, S_Y + Object_Editor_Main\Font_Height, Object_Editor_Main\Font_Width, -2)
            Else
              Box(Hex_X, S_Y, 2, Object_Editor_Main\Font_Height)
            EndIf
            CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Blink())
            Box(Ascii_X, S_Y, Object_Editor_Main\Font_Width, Object_Editor_Main\Font_Height)
          Else
            ; #### Ascii selected
            CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Blink())
            Box(Hex_X, S_Y, Object_Editor_Main\Font_Width, Object_Editor_Main\Font_Height)
            CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Inverse())
            If *Object_Editor\Write_Mode = 0
              Box(Ascii_X, S_Y + Object_Editor_Main\Font_Height, Object_Editor_Main\Font_Width, -2)
            Else
              Box(Ascii_X, S_Y, 2, Object_Editor_Main\Font_Height)
            EndIf
          EndIf
          DrawingMode(#PB_2DDrawing_Default)
        EndIf
        
        D_X + 1
        Temp_Adress + 1
        If D_X >= *Object_Editor\Line_Bytes
          D_X = 0
          D_Y + 1
          S_Y = *Object_Editor\Y0 + D_Y * Object_Editor_Main\Font_Height
          If D_Y >= *Object_Editor\Lines
            Break
          EndIf
        EndIf
      Next
      
      ; #### Draw the cursors (Even if outside of the segment's data)
      If Temp_Adress = *Object_Editor\Select_End
        Hex_X = *Object_Editor\X0 + D_X * Object_Editor_Main\Font_Width * 3
        Ascii_X = *Object_Editor\X1 + D_X * Object_Editor_Main\Font_Width
        ; #### Draw the Temp_Nibble
        If *Object_Editor\Temp_Nibble
          DrawText(Hex_X, S_Y, Hex(*Object_Editor\Temp_Nibble_Value), RGB(0,0,255), RGB(255,255,255))
        EndIf
        DrawingMode(#PB_2DDrawing_Outlined | #PB_2DDrawing_CustomFilter)
        If *Object_Editor\Select_Field = 0
          ; #### Hex selected
          CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Inverse())
          If *Object_Editor\Select_Nibble
            Hex_X + Object_Editor_Main\Font_Width
          EndIf
          If *Object_Editor\Write_Mode = 0
            Box(Hex_X, S_Y + Object_Editor_Main\Font_Height, Object_Editor_Main\Font_Width, -2)
          Else
            Box(Hex_X, S_Y, 2, Object_Editor_Main\Font_Height)
          EndIf
          CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Blink())
          Box(Ascii_X, S_Y, Object_Editor_Main\Font_Width, Object_Editor_Main\Font_Height)
        Else
          ; #### Ascii selected
          CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Blink())
          Box(Hex_X, S_Y, Object_Editor_Main\Font_Width, Object_Editor_Main\Font_Height)
          CustomFilterCallback(@Object_Editor_Canvas_Redraw_Filter_Inverse())
          If *Object_Editor\Write_Mode = 0
            Box(Ascii_X, S_Y + Object_Editor_Main\Font_Height, Object_Editor_Main\Font_Width, -2)
          Else
            Box(Ascii_X, S_Y, 2, Object_Editor_Main\Font_Height)
          EndIf
        EndIf
        DrawingMode(#PB_2DDrawing_Default)
      EndIf
      
    EndIf
  Next
  
  StopDrawing()
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Statusbar_Update(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  If *Object_Editor\Window\ID = GetGadgetState(Main_Window\MDI)
    If *Object_Editor\Select_Start < *Object_Editor\Select_End
      StatusBarText(Main_Window\StatusBar_ID, 0, "Offset: "+Hex(*Object_Editor\Select_Start))
    Else
      StatusBarText(Main_Window\StatusBar_ID, 0, "Offset: "+Hex(*Object_Editor\Select_End))
    EndIf
    
    If *Object_Editor\Select_Start <> *Object_Editor\Select_End
      If *Object_Editor\Select_Start < *Object_Editor\Select_End
        StatusBarText(Main_Window\StatusBar_ID, 1, "Block: "+Hex(*Object_Editor\Select_Start)+" - "+Hex(*Object_Editor\Select_End-1))
        StatusBarText(Main_Window\StatusBar_ID, 2, "Length: "+Hex(*Object_Editor\Select_End-*Object_Editor\Select_Start))
      Else
        StatusBarText(Main_Window\StatusBar_ID, 1, "Block: "+Hex(*Object_Editor\Select_End)+" - "+Hex(*Object_Editor\Select_Start-1))
        StatusBarText(Main_Window\StatusBar_ID, 2, "Length: "+Hex(*Object_Editor\Select_Start-*Object_Editor\Select_End))
      EndIf
    Else
      StatusBarText(Main_Window\StatusBar_ID, 1, "")
      StatusBarText(Main_Window\StatusBar_ID, 2, "")
    EndIf
  EndIf
  
EndProcedure

Procedure Object_Editor_Cut(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q, *Text.String, Text.s
  Protected i
  
  If *Object_Editor\Select_Start <> *Object_Editor\Select_End
    If *Object_Editor\Select_Start < *Object_Editor\Select_End
      Start = *Object_Editor\Select_Start
      Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
    Else
      Start = *Object_Editor\Select_End
      Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
    EndIf
    If Length < 100000000
      *Text = AllocateMemory(Length + 1)
        Object_Input_Get_Data(FirstElement(*Object\Input()), Start, Length, *Text, #Null)
      If *Object_Editor\Select_Field = 0 ; Hex
        For i = 0 To Length-1
          Text + RSet(Hex(PeekA(*Text+i)),2,"0")
          If i < Length-1
            Text + " "
          EndIf
        Next
        SetClipboardText(Text)
      Else
        SetClipboardText(PeekS(*Text, Length, #PB_Ascii))
      EndIf
      
      Object_Editor_Remove_Data(*Object, 0)
      
      FreeMemory(*Text)
    EndIf
    *Object_Editor\Redraw = #True
  EndIf
EndProcedure

Procedure Object_Editor_Copy(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q, *Text.String, Text.s
  Protected i
  
  If *Object_Editor\Select_Start <> *Object_Editor\Select_End
    If *Object_Editor\Select_Start < *Object_Editor\Select_End
      Start = *Object_Editor\Select_Start
      Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
    Else
      Start = *Object_Editor\Select_End
      Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
    EndIf
    If Length < 100000000
      *Text = AllocateMemory(Length + 1)
        Object_Input_Get_Data(FirstElement(*Object\Input()), Start, Length, *Text, #Null)
      If *Object_Editor\Select_Field = 0 ; Hex
        For i = 0 To Length-1
          Text + RSet(Hex(PeekA(*Text+i)),2,"0")
          If i < Length-1
            Text + " "
          EndIf
        Next
        SetClipboardText(Text)
      Else
        SetClipboardText(PeekS(*Text, Length, #PB_Ascii))
      EndIf
      FreeMemory(*Text)
    EndIf
    *Object_Editor\Redraw = #True
  EndIf
EndProcedure

Procedure Object_Editor_Paste(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Start.q, Length.q, *Text.String, Text.s, Hex_Elements.i
  Protected i
  
  Text.s = GetClipboardText()
  Length = Len(Text)
  *Text = AllocateMemory(Length + 1)
  If *Object_Editor\Select_Field = 0 ; Hex
    Text = Trim(Text)
    Hex_Elements = CountString(Text, " ") + 1
    For i = 0 To Hex_Elements - 1
      PokeA(*Text+i, Val("$"+StringField(Text, i+1, " ")))
    Next
    Length = Hex_Elements
  Else
    PokeS(*Text, Text, Length, #PB_Ascii)
  EndIf
  Object_Editor_Write_Data(*Object, *Text, Length)
  Object_Editor_Scroll_2_Cursor(*Object)
  FreeMemory(*Text)
EndProcedure

Procedure Object_Editor_Remove_Data(*Object.Object, Bytes.q, Backspace=#False)
  Protected Select_Start.q, Select_Length.q
  
  If Bytes < 0
    ProcedureReturn #False
  EndIf
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ; #### Determine the start and length of the selected range
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Select_Start = *Object_Editor\Select_Start
    Select_Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Select_Start = *Object_Editor\Select_End
    Select_Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If Select_Length > 0
    ; #### Remove-Convolute the selected range
    Object_Input_Convolute(FirstElement(*Object\Input()), Select_Start, -Select_Length)
    ; #### Change the selection from range to a single position
    Object_Editor_Range_Set(*Object, Select_Start, Select_Start, #False, #True)
  ElseIf Bytes > 0
    ; #### Abort current nibble-operation
    Object_Editor_Write_Nibble(*Object, 0, #True)
    
    If Backspace
      ; #### Crop the amount of bytes to the available bytes
      If Bytes > Select_Start
        Bytes = Select_Start
      EndIf
      If Object_Input_Convolute(FirstElement(*Object\Input()), Select_Start-Bytes, -Bytes)
        Object_Editor_Range_Set(*Object, Select_Start-Bytes, Select_Start-Bytes, #False, #True)
      EndIf
    Else
      Object_Input_Convolute(FirstElement(*Object\Input()), Select_Start, -Bytes)
      Object_Editor_Range_Set(*Object, Select_Start, Select_Start, #False, #True)
    EndIf
    *Object_Editor\Redraw = #True
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Write_Data(*Object.Object, *Data, Size.i)
  Protected Select_Start.q, Select_Length.q
  Protected Result = #False
  Protected Char.a
  
  If Size < 0
    ProcedureReturn #False
  EndIf
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ; #### Determine the start and length of the selected range
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Select_Start = *Object_Editor\Select_Start
    Select_Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Select_Start = *Object_Editor\Select_End
    Select_Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  ; #### Remove-Convolute the selected range (If insert-mode is enabled)
  If *Object_Editor\Write_Mode = #Object_Editor_WriteMode_Insert
    Object_Editor_Remove_Data(*Object, 0)
  Else
    ; #### Change the selection from range to a single position
    Object_Editor_Range_Set(*Object, Select_Start, Select_Start, #False, #False)
  EndIf
  
  ; #### Write the data
  If *Data And Size > 0
    Select *Object_Editor\Write_Mode
      Case #Object_Editor_WriteMode_Overwrite
        Result = Object_Input_Set_Data(FirstElement(*Object\Input()), Select_Start, Size, *Data)
        
      Case #Object_Editor_WriteMode_Insert
        If Object_Input_Convolute(FirstElement(*Object\Input()), Select_Start, Size)
          Result = Object_Input_Set_Data(FirstElement(*Object\Input()), Select_Start, Size, *Data)
        EndIf
        
    EndSelect
  EndIf
  
  If Result
    Object_Editor_Range_Set(*Object, Select_Start + Size, Select_Start + Size, #False, #True)
  EndIf
  
  *Object_Editor\Redraw = #True
  
  ProcedureReturn Result
EndProcedure

Procedure Object_Editor_Write_Nibble(*Object.Object, Char.a, Abort.i=#False)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Select_Start.q, Select_Length.q
  Protected Result = #False
  Protected Temp_Char.a
  
  ; #### Determine the start and length of the selected range
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Select_Start = *Object_Editor\Select_Start
    Select_Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Select_Start = *Object_Editor\Select_End
    Select_Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If Abort
    ; #### Abort nibble operation. Write the stored nibble...
    
    If *Object_Editor\Temp_Nibble
      If Select_Length = 0
        If Object_Input_Get_Data(FirstElement(*Object\Input()), Select_Start, 1, @Temp_Char, #Null)
          Temp_Char & $0F
          Temp_Char | *Object_Editor\Temp_Nibble_Value << 4
          Result = Object_Input_Set_Data(FirstElement(*Object\Input()), Select_Start, 1, @Temp_Char)
        EndIf
      EndIf
      *Object_Editor\Temp_Nibble = #False
    EndIf
    
  Else
    
    ; #### Remove-Convolute the selected range (If insert-mode is enabled)
    If *Object_Editor\Write_Mode = #Object_Editor_WriteMode_Insert
      Object_Editor_Remove_Data(*Object, 0)
    Else
      ; #### Change the selection from range to a single position
      ;Object_Editor_Range_Set(*Object, Select_Start, Select_Start, #False, #False)
    EndIf
    
    If *Object_Editor\Select_Nibble
      If Object_Input_Get_Data(FirstElement(*Object\Input()), Select_Start, 1, @Temp_Char, #Null)
        If *Object_Editor\Temp_Nibble
          Temp_Char & $0F
          Temp_Char | *Object_Editor\Temp_Nibble_Value << 4
        EndIf
        Temp_Char & $F0
        Temp_Char | Char
        Result = Object_Input_Set_Data(FirstElement(*Object\Input()), Select_Start, 1, @Temp_Char)
        If Not Result
          *Object_Editor\Select_Nibble = #False
        EndIf
        *Object_Editor\Temp_Nibble = #False
      EndIf
    Else
      Select *Object_Editor\Write_Mode
        Case #Object_Editor_WriteMode_Overwrite
          *Object_Editor\Temp_Nibble = #True
          *Object_Editor\Temp_Nibble_Value = Char
          Result = #True
        Case #Object_Editor_WriteMode_Insert
          If Object_Input_Convolute(FirstElement(*Object\Input()), Select_Start, 1)
            Temp_Char = Char << 4
            Result = Object_Input_Set_Data(FirstElement(*Object\Input()), Select_Start, 1, @Temp_Char)
          EndIf
      EndSelect
    EndIf
    
    If Result
      If *Object_Editor\Select_Nibble
        *Object_Editor\Select_Start = Select_Start + 1
        *Object_Editor\Select_End = Select_Start + 1
        *Object_Editor\Select_Nibble = #False
      Else
        *Object_Editor\Select_Start = Select_Start
        *Object_Editor\Select_End = Select_Start
        *Object_Editor\Select_Nibble = #True
      EndIf
    EndIf
  EndIf
  
  *Object_Editor\Redraw = #True
  
  ProcedureReturn Result
EndProcedure

Procedure Object_Editor_Scroll_2_Cursor(*Object.Object)
  Protected Cursor_Line.q
  Protected *Nearest_Segment.Object_Editor_Segment
  Protected Temp_Distance ; in Bytes
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  ; #### Find the nearest segment
  Temp_Distance = 10000
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Start <= *Object_Editor\Select_End And *Object_Editor\Segment()\Start + *Object_Editor\Segment()\Size > *Object_Editor\Select_End
      ; Inside of a segment
      *Nearest_Segment = *Object_Editor\Segment()
      Break
    Else
      ; Check distance from the start
      If *Object_Editor\Segment()\Start - *Object_Editor\Select_End > 0
        If Temp_Distance > *Object_Editor\Segment()\Start - *Object_Editor\Select_End
          Temp_Distance = *Object_Editor\Segment()\Start - *Object_Editor\Select_End
          *Nearest_Segment = *Object_Editor\Segment()
        EndIf
      EndIf
      ; Check distance from the end
      If *Object_Editor\Select_End - (*Object_Editor\Segment()\Start + *Object_Editor\Segment()\Size) > 0
        If Temp_Distance > *Object_Editor\Select_End - (*Object_Editor\Segment()\Start + *Object_Editor\Segment()\Size)
          Temp_Distance = *Object_Editor\Select_End - (*Object_Editor\Segment()\Start + *Object_Editor\Segment()\Size)
          *Nearest_Segment = *Object_Editor\Segment()
        EndIf
      EndIf
    EndIf
  Next
  
  If *Nearest_Segment
    If *Nearest_Segment\Collapsed
      Cursor_Line = *Nearest_Segment\Line_Start
    Else
      Cursor_Line = *Nearest_Segment\Line_Start + 1 + Quad_Divide_Floor(*Nearest_Segment\Start % *Object_Editor\Line_Bytes + *Object_Editor\Select_End - *Nearest_Segment\Start, *Object_Editor\Line_Bytes)
    EndIf
    
    If *Object_Editor\Scroll_Line > Cursor_Line
      *Object_Editor\Scroll_Line = Cursor_Line
      *Object_Editor\Redraw = #True
    EndIf
    
    If *Object_Editor\Scroll_Line + *Object_Editor\Lines - 2 < Cursor_Line
      *Object_Editor\Scroll_Line = Cursor_Line - *Object_Editor\Lines + 2
      *Object_Editor\Redraw = #True
    EndIf
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Editor_Range_Set(*Object.Object, Select_Start.q, Select_End.q, Select_Nibble.i, Scroll_2_Cursor=#False, Redraw=#True)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Protected Length.q
  Protected Object_Event.Object_Event
  
  ; #### Abort current nibble operation
  Object_Editor_Write_Nibble(*Object, 0, #True)
  
  If Select_Start >= 0
    *Object_Editor\Select_Start = Select_Start
  EndIf
  If Select_End >= 0
    *Object_Editor\Select_End = Select_End
  EndIf
  If Select_Nibble >= 0
    *Object_Editor\Select_Nibble = Select_Nibble
  EndIf
  
  If *Object_Editor\Select_Start <> *Object_Editor\Select_End
    *Object_Editor\Select_Nibble = #False
  EndIf
  
  If Scroll_2_Cursor
    Object_Editor_Scroll_2_Cursor(*Object)
  EndIf
  
  ; #### Determine the start and length of the selected range
  If *Object_Editor\Select_Start < *Object_Editor\Select_End
    Length = *Object_Editor\Select_End-*Object_Editor\Select_Start
  Else
    Length = *Object_Editor\Select_Start-*Object_Editor\Select_End
  EndIf
  
  If Redraw
    *Object_Editor\Redraw = #True
    
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = Length
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure.q Object_Editor_Canvas_Mouse_2_Position(*Object.Object, Mouse_X, Mouse_Y, Field, Set_Start, Set_End, Set_Nibble)
  Protected Mouse_Line.q, Mouse_Byte.q
  Protected Position.q, Nibble.i
  Protected *Nearest_Segment.Object_Editor_Segment
  Protected Temp_Distance.q ; in Lines
  
  If Not *Object
    ProcedureReturn 0
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 0
  EndIf
  
  Mouse_Line = Quad_Divide_Floor(Mouse_Y - *Object_Editor\Y0, Object_Editor_Main\Font_Height)
  
  ; #### Find the nearest segment
  Temp_Distance = 10000
  ForEach *Object_Editor\Segment()
    If *Object_Editor\Segment()\Line_Start - *Object_Editor\Scroll_Line <= Mouse_Line And *Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount - *Object_Editor\Scroll_Line > Mouse_Line
      ; Inside of a segment
      *Nearest_Segment = *Object_Editor\Segment()
      Break
    Else
      ; Check distance from the mouse to the start
      If *Object_Editor\Segment()\Line_Start - (Mouse_Line + *Object_Editor\Scroll_Line) >= 0
        If Temp_Distance > *Object_Editor\Segment()\Line_Start - (Mouse_Line + *Object_Editor\Scroll_Line)
          Temp_Distance = *Object_Editor\Segment()\Line_Start - (Mouse_Line + *Object_Editor\Scroll_Line)
          *Nearest_Segment = *Object_Editor\Segment()
        EndIf
      EndIf
      ; Check distance from the mouse to the end
      If (Mouse_Line + *Object_Editor\Scroll_Line) - (*Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount) >= 0
        If Temp_Distance > (Mouse_Line + *Object_Editor\Scroll_Line) - (*Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount)
          Temp_Distance = (Mouse_Line + *Object_Editor\Scroll_Line) - (*Object_Editor\Segment()\Line_Start + *Object_Editor\Segment()\Line_Amount)
          *Nearest_Segment = *Object_Editor\Segment()
        EndIf
      EndIf
    EndIf
  Next
  
  If *Nearest_Segment
    Select Field
      Case 0 ; #### Hex
        If Set_Nibble
          Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object_Editor\X0 + Object_Editor_Main\Font_Width * 0.5, Object_Editor_Main\Font_Width * 3)
          If (Mouse_X - *Object_Editor\X0 - Object_Editor_Main\Font_Width * 0.5 - Mouse_Byte*Object_Editor_Main\Font_Width*3) > 0
            Nibble = #True
          Else
            Nibble = #False
          EndIf
        Else
          Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object_Editor\X0 + Object_Editor_Main\Font_Width * 1.5, Object_Editor_Main\Font_Width * 3)
        EndIf
      Case 1 ; #### Ascii
        Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object_Editor\X1 + Object_Editor_Main\Font_Width * 0.5, Object_Editor_Main\Font_Width)
    EndSelect
    
    If Mouse_Byte < 0
      Mouse_Byte = 0
      Nibble = #False
    EndIf
    If Mouse_Byte > *Object_Editor\Line_Bytes
      Mouse_Byte = *Object_Editor\Line_Bytes
      Nibble = #False
    EndIf
    
    If *Nearest_Segment\Collapsed
      Position = *Nearest_Segment\Start
    Else
      Position = *Nearest_Segment\Start - *Nearest_Segment\Start % *Object_Editor\Line_Bytes + Mouse_Byte + (Mouse_Line+*Object_Editor\Scroll_Line-*Nearest_Segment\Line_Start-1) * *Object_Editor\Line_Bytes
    EndIf
    
    If Position < *Nearest_Segment\Start
      Position = *Nearest_Segment\Start
      Nibble = #False
    EndIf
    If Position >= *Nearest_Segment\Start + *Nearest_Segment\Size ; #### it's really Greater or Equal because of the nibble state!
      Position = *Nearest_Segment\Start + *Nearest_Segment\Size
      Nibble = #False
    EndIf
    
    ; #### Set everything
    If Set_Start Or Set_End Or Set_Nibble
      Object_Editor_Write_Nibble(*Object, 0, #True)
    EndIf
    If Set_Start
      Object_Editor_Range_Set(*Object, Position, -1, -1, #False)
    EndIf
    If Set_End
      Object_Editor_Range_Set(*Object, -1, Position, -1, #True)
    EndIf
    If Set_Nibble
      Object_Editor_Range_Set(*Object, -1, -1, Nibble, #False)
    EndIf
  EndIf
  
  ProcedureReturn Position
EndProcedure

Procedure Object_Editor_Window_Event_Canvas()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected M_X.l, M_Y.l
  Protected Key, Modifiers
  Protected i
  Protected Start.q, Length.q, Text.s, *Text.String, Hex_Elements.i
  Protected Select_Start.q, Select_Length.q
  Protected Char.a
  Protected Selection.q
  Protected Object_Event.Object_Event
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 
  EndIf
  
  Select Event_Type
    Case #PB_EventType_RightButtonDown
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      Modifiers = GetGadgetAttribute(Event_Gadget, #PB_Canvas_Modifiers)
      If M_X < *Object_Editor\X2 And M_Y > *Object_Editor\Y0
        If M_X < *Object_Editor\X1 - 5
          *Object_Editor\Select_Field = 0
        Else
          *Object_Editor\Select_Field = 1
        EndIf
        If *Object_Editor\Select_Start < *Object_Editor\Select_End
          Select_Start = *Object_Editor\Select_Start
          Select_Length = *Object_Editor\Select_End - *Object_Editor\Select_Start
        Else
          Select_Start = *Object_Editor\Select_End
          Select_Length = *Object_Editor\Select_Start - *Object_Editor\Select_End
        EndIf
        Selection = Object_Editor_Canvas_Mouse_2_Position(*Object, M_X, M_Y, *Object_Editor\Select_Field, #False, #False, #False)
        If Select_Start > Selection Or Select_Start+Select_Length < Selection
          Object_Editor_Range_Set(*Object, Selection, Selection, #False, #True)
        EndIf
      EndIf
      
    Case #PB_EventType_RightClick
      *Object_Editor\Menu_Object = *Object
      DisplayPopupMenu(Object_Editor_Main\PopupMenu, WindowID(*Object_Editor\Window\ID))
      
    Case #PB_EventType_LeftButtonDown
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      Modifiers = GetGadgetAttribute(Event_Gadget, #PB_Canvas_Modifiers)
      If M_X < *Object_Editor\X2 And M_Y > *Object_Editor\Y0
        If M_X < *Object_Editor\X1 - 5
          *Object_Editor\Select_Field = 0
        Else
          *Object_Editor\Select_Field = 1
        EndIf
        If Modifiers & #PB_Canvas_Shift
          Object_Editor_Canvas_Mouse_2_Position(*Object, M_X, M_Y, *Object_Editor\Select_Field, #False, #True, #False)
        Else
          Object_Editor_Canvas_Mouse_2_Position(*Object, M_X, M_Y, *Object_Editor\Select_Field, #True, #True, #True)
        EndIf
        *Object_Editor\Select_Active = #True
      EndIf
      
    Case #PB_EventType_LeftButtonUp
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      If *Object_Editor\Select_Active
        Object_Editor_Canvas_Mouse_2_Position(*Object, M_X, M_Y, *Object_Editor\Select_Field, #False, #True, *Object_Editor\Select_Nibble)
        *Object_Editor\Select_Active = #False
      EndIf
      
    Case #PB_EventType_MouseMove
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      If *Object_Editor\Select_Active
        Object_Editor_Canvas_Mouse_2_Position(*Object, M_X, M_Y, *Object_Editor\Select_Field, #False, #True, *Object_Editor\Select_Nibble)
      EndIf
      ; #### Do cursor stuff
      If (M_X < *Object_Editor\X2 And M_Y > *Object_Editor\Y0) Or *Object_Editor\Select_Active
        SetGadgetAttribute(*Object_Editor\Canvas, #PB_Canvas_Cursor, #PB_Cursor_IBeam)
      Else
        SetGadgetAttribute(*Object_Editor\Canvas, #PB_Canvas_Cursor, #PB_Cursor_Default)
      EndIf
      
    Case #PB_EventType_MouseWheel
      *Object_Editor\Scroll_Line - GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta) * 3
      If *Object_Editor\Scroll_Line > *Object_Editor\Scroll_Lines - *Object_Editor\Lines + 1
        *Object_Editor\Scroll_Line = *Object_Editor\Scroll_Lines - *Object_Editor\Lines + 1
      EndIf
      If *Object_Editor\Scroll_Line < 0
        *Object_Editor\Scroll_Line = 0
      EndIf
      *Object_Editor\Redraw = #True
      
    Case #PB_EventType_Input
      If *Object_Editor\Select_Field = 1 ; #### Ascii
        Char = GetGadgetAttribute(*Object_Editor\Canvas, #PB_Canvas_Input)
        Object_Editor_Write_Data(*Object, @Char, 1)
      EndIf
      
    Case #PB_EventType_KeyDown
      Key = GetGadgetAttribute(*Object_Editor\Canvas, #PB_Canvas_Key)
      Modifiers = GetGadgetAttribute(*Object_Editor\Canvas, #PB_Canvas_Modifiers)
      If *Object_Editor\Select_Field = 0 ; #### Hex
        Select Key
          Case #PB_Shortcut_0 To #PB_Shortcut_9, #PB_Shortcut_A To #PB_Shortcut_F, #PB_Shortcut_Pad0 To #PB_Shortcut_Pad9
            If Modifiers = 0
              If Key >= #PB_Shortcut_0 And Key <= #PB_Shortcut_9
                Char = Key - #PB_Shortcut_0
              ElseIf Key >= #PB_Shortcut_Pad0 And Key <= #PB_Shortcut_Pad9
                Char = Key - #PB_Shortcut_Pad0
              ElseIf Key >= #PB_Shortcut_A And Key <= #PB_Shortcut_F
                Char = Key - #PB_Shortcut_A + 10
              EndIf
              Object_Editor_Write_Nibble(*Object, Char)
            EndIf
        EndSelect
      EndIf
      Select Key
        Case #PB_Shortcut_Insert
          If *Object_Editor\Write_Mode = #Object_Editor_WriteMode_Overwrite
            *Object_Editor\Write_Mode = #Object_Editor_WriteMode_Insert
          Else
            *Object_Editor\Write_Mode = #Object_Editor_WriteMode_Overwrite
          EndIf
          *Object_Editor\Redraw = #True
          
        Case #PB_Shortcut_Up
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End - *Object_Editor\Line_Bytes
          If *Object_Editor\Select_End < 0
            *Object_Editor\Select_End = 0
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          Else
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Control
            *Object_Editor\Select_Nibble = #False
          EndIf
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_Down
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End + *Object_Editor\Line_Bytes
          If *Object_Editor\Select_End > *Object_Editor\Data_Size
            *Object_Editor\Select_End = *Object_Editor\Data_Size
          EndIf
          If *Object_Editor\Select_End >= *Object_Editor\Data_Size
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          Else
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Control
            *Object_Editor\Select_Nibble = #False
          EndIf
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_Right
          Object_Editor_Write_Nibble(*Object, 0, #True)
          If Modifiers & #PB_Canvas_Control
            If *Object_Editor\Select_Nibble
              *Object_Editor\Select_Nibble = #False
              *Object_Editor\Select_End + 1
            Else
              *Object_Editor\Select_Nibble = #True
            EndIf
          Else
            *Object_Editor\Select_End + 1
            *Object_Editor\Select_Nibble = #False
          EndIf
          If *Object_Editor\Select_End > *Object_Editor\Data_Size
            *Object_Editor\Select_End = *Object_Editor\Data_Size
          EndIf
          If *Object_Editor\Select_End >= *Object_Editor\Data_Size
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          Else
            *Object_Editor\Select_Nibble = #False
          EndIf
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_Left
          Object_Editor_Write_Nibble(*Object, 0, #True)
          If Modifiers & #PB_Canvas_Control
            If *Object_Editor\Select_Nibble
              *Object_Editor\Select_Nibble = #False
            Else
              *Object_Editor\Select_Nibble = #True
              *Object_Editor\Select_End - 1
            EndIf
          Else
            If Not *Object_Editor\Select_Nibble
              *Object_Editor\Select_End - 1
            EndIf
            *Object_Editor\Select_Nibble = #False
          EndIf
          If *Object_Editor\Select_End < 0
            *Object_Editor\Select_End = 0
            *Object_Editor\Select_Nibble = #False
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          Else
            *Object_Editor\Select_Nibble = #False
          EndIf
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_Home
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End = 0
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          EndIf
          *Object_Editor\Select_Nibble = #False
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_End
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End = *Object_Editor\Data_Size
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          EndIf
          *Object_Editor\Select_Nibble = #False
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_PageUp
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End - *Object_Editor\Lines * *Object_Editor\Line_Bytes
          If *Object_Editor\Select_End < 0
            *Object_Editor\Select_End = 0
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          EndIf
          *Object_Editor\Select_Nibble = #False
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_PageDown
          Object_Editor_Write_Nibble(*Object, 0, #True)
          *Object_Editor\Select_End + *Object_Editor\Lines * *Object_Editor\Line_Bytes
          If *Object_Editor\Select_End > *Object_Editor\Data_Size
            *Object_Editor\Select_End = *Object_Editor\Data_Size
          EndIf
          If Not Modifiers & #PB_Canvas_Shift
            *Object_Editor\Select_Start = *Object_Editor\Select_End
          EndIf
          *Object_Editor\Select_Nibble = #False
          Object_Editor_Scroll_2_Cursor(*Object)
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_A
          If Modifiers & #PB_Canvas_Control
            Object_Editor_Write_Nibble(*Object, 0, #True)
            *Object_Editor\Select_Start = 0
            *Object_Editor\Select_End = *Object_Editor\Data_Size
            *Object_Editor\Select_Nibble = #False
            *Object_Editor\Temp_Nibble = #False
          EndIf
          *Object_Editor\Redraw = #True
          ; #### Selection changed. Update selection-output
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = 0
          Object_Event\Size = 0
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          
        Case #PB_Shortcut_Back
          Object_Editor_Remove_Data(*Object, 1, #True)
          Object_Editor_Scroll_2_Cursor(*Object)
          
        Case #PB_Shortcut_Delete
          Object_Editor_Remove_Data(*Object, 1, #False)
          Object_Editor_Scroll_2_Cursor(*Object)
          
      EndSelect
      
  EndSelect
  
EndProcedure

Procedure Object_Editor_Window_Callback(hWnd, uMsg, wParam, lParam)
  Protected SCROLLINFO.SCROLLINFO
  
  Protected *Window.Window = Window_Get_hWnd(hWnd)
  If Not *Window
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  If Not *Object\Type = Object_Editor_Main\Object_Type
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  
  Select uMsg
    Case #WM_VSCROLL
      Select wParam & $FFFF
        Case #SB_THUMBTRACK
          SCROLLINFO\fMask = #SIF_TRACKPOS
          SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
          GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
          If SCROLLINFO\nTrackPos = *Object_Editor\Scroll_Lines / *Object_Editor\Scroll_Divider
            *Object_Editor\Scroll_Line = *Object_Editor\Scroll_Lines-*Object_Editor\Lines
          Else
            *Object_Editor\Scroll_Line = SCROLLINFO\nTrackPos * *Object_Editor\Scroll_Divider
          EndIf
          *Object_Editor\Redraw = #True
        Case #SB_PAGEUP
          *Object_Editor\Scroll_Line - *Object_Editor\Lines
          *Object_Editor\Redraw = #True
        Case #SB_PAGEDOWN
          *Object_Editor\Scroll_Line + *Object_Editor\Lines
          *Object_Editor\Redraw = #True
        Case #SB_LINEUP
          *Object_Editor\Scroll_Line - 1
          *Object_Editor\Redraw = #True
        Case #SB_LINEDOWN
          *Object_Editor\Scroll_Line + 1
          *Object_Editor\Redraw = #True
      EndSelect
      
      If *Object_Editor\Redraw
        *Object_Editor\Redraw = #False
        Object_Editor_Organize(*Object)
        Object_Editor_Get_Data(*Object)
        Object_Editor_Canvas_Redraw(*Object)
      EndIf
      
  EndSelect
  
  
  
  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure

Procedure Object_Editor_Window_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected ToolBarHeight
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 
  EndIf
  
  ToolBarHeight = ToolBarHeight(*Object_Editor\ToolBar)
  
  ResizeGadget(*Object_Editor\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ResizeGadget(*Object_Editor\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
  *Object_Editor\Redraw = #True
EndProcedure

Procedure Object_Editor_Window_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 
  EndIf
  
  
  *Object_Editor\Redraw = #True
EndProcedure

Procedure Object_Editor_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select Event_Menu
    Case #Object_Editor_Menu_Search
      Object_Editor_Search_Window_Open(*Object)
      
    Case #Object_Editor_Menu_Search_Continue
      Object_Editor_Search_Continue(*Object)
      
    Case #Object_Editor_Menu_Goto
      Object_Editor_Goto_Window_Open(*Object)
      
    Case #Object_Editor_Menu_Undo
      Object_Event\Type = #Object_Event_Undo
      Object_Event\Value[0] = #True ; Combine Convolution and Write
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Editor_Menu_Redo
      Object_Event\Type = #Object_Event_Redo
      Object_Event\Value[0] = #True ; Combine Convolution and Write
      Object_Input_Event(FirstElement(*Object\Input()), Object_Event)
      
    Case #Object_Editor_Menu_Cut, #Object_Editor_PopupMenu_Cut
      Object_Editor_Cut(*Object)
      
    Case #Object_Editor_Menu_Copy, #Object_Editor_PopupMenu_Copy
      Object_Editor_Copy(*Object)
      
    Case #Object_Editor_Menu_Paste, #Object_Editor_PopupMenu_Paste
      Object_Editor_Paste(*Object)
      
    Case #Object_Editor_PopupMenu_Select_All
      *Object_Editor\Select_Start = 0
      *Object_Editor\Select_End = *Object_Editor\Data_Size
      *Object_Editor\Select_Nibble = #False
      *Object_Editor\Temp_Nibble = #False
      *Object_Editor\Redraw = #True
      
  EndSelect
EndProcedure

Procedure Object_Editor_Window_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn 
  EndIf
  
  ;Object_Editor_Window_Close(*Object)
  *Object_Editor\Window_Close = #True
EndProcedure

Procedure Object_Editor_Window_Open(*Object.Object)
  Protected ToolBarHeight
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  If *Object_Editor\Window = #Null
    *Object_Editor\Window = Window_Create(*Object, "Editor", "Editor", #True, #PB_Ignore, #PB_Ignore, 500, 500)
    
    ; #### Toolbar
    *Object_Editor\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object_Editor\Window\ID))
    ToolBarImageButton(#Object_Editor_Menu_Search, ImageID(Icon_Search))
    ToolBarImageButton(#Object_Editor_Menu_Search_Continue, ImageID(Icon_Search_Continue))
    ToolBarSeparator()
    ToolBarImageButton(#Object_Editor_Menu_Cut, ImageID(Icon_Cut))
    ToolBarImageButton(#Object_Editor_Menu_Copy, ImageID(Icon_Copy))
    ToolBarImageButton(#Object_Editor_Menu_Paste, ImageID(Icon_Paste))
    ToolBarSeparator()
    ToolBarImageButton(#Object_Editor_Menu_Goto, ImageID(Icon_Goto))
    ToolBarSeparator()
    ToolBarImageButton(#Object_Editor_Menu_Undo, ImageID(Icon_Undo))
    ToolBarImageButton(#Object_Editor_Menu_Redo, ImageID(Icon_Redo))
    
    ToolBarHeight = ToolBarHeight(*Object_Editor\ToolBar)
    
    *Object_Editor\Canvas = CanvasGadget(#PB_Any, 0, ToolBarHeight, 483, 500-ToolBarHeight, #PB_Canvas_Keyboard)
    *Object_Editor\ScrollBar = ScrollBarGadget(#PB_Any, 483, ToolBarHeight, 17, 500-ToolBarHeight, 0, 0, 0, #PB_ScrollBar_Vertical)
    
    BindEvent(#PB_Event_SizeWindow, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    ;BindEvent(#PB_Event_Repaint, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Editor_Window_Event_Menu(), *Object_Editor\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Editor_Window_Event_CloseWindow(), *Object_Editor\Window\ID)
    BindGadgetEvent(*Object_Editor\Canvas, @Object_Editor_Window_Event_Canvas())
    
    SetWindowCallback(@Object_Editor_Window_Callback(), *Object_Editor\Window\ID)
    
    *Object_Editor\Redraw = #True
    
  Else
    Window_Set_Active(*Object_Editor\Window)
  EndIf
EndProcedure

Procedure Object_Editor_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  If *Object_Editor\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    ;UnbindEvent(#PB_Event_Repaint, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Object_Editor_Window_Event_SizeWindow(), *Object_Editor\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Editor_Window_Event_Menu(), *Object_Editor\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Editor_Window_Event_CloseWindow(), *Object_Editor\Window\ID)
    UnbindGadgetEvent(*Object_Editor\Canvas, @Object_Editor_Window_Event_Canvas())
    
    SetWindowCallback(#Null, *Object_Editor\Window\ID)
    
    Window_Delete(*Object_Editor\Window)
    *Object_Editor\Window = #Null
  EndIf
EndProcedure

Procedure Object_Editor_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  
  Object_Editor_Goto_Main(*Object)
  Object_Editor_Search_Main(*Object)
  
  If *Object_Editor\Window
    If *Object_Editor\Redraw
      *Object_Editor\Redraw = #False
      Object_Editor_Organize(*Object)
      Object_Editor_Get_Data(*Object)
      Object_Editor_Canvas_Redraw(*Object)
      Object_Editor_Statusbar_Update(*Object)
    EndIf
  EndIf
  
  If *Object_Editor\Window_Close
    *Object_Editor\Window_Close = #False
    Object_Editor_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Editor_Main\Object_Type = Object_Type_Create()
If Object_Editor_Main\Object_Type
  Object_Editor_Main\Object_Type\Category = "Manipulator"
  Object_Editor_Main\Object_Type\Name = "Editor"
  Object_Editor_Main\Object_Type\UID = "D3EDITOR"
  Object_Editor_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Editor_Main\Object_Type\Date_Creation = Date(2014,01,12,14,02,00)
  Object_Editor_Main\Object_Type\Date_Modification = Date(2014,10,08,16,45,00)
  Object_Editor_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Editor_Main\Object_Type\Description = "Just a normal hex-editor."
  Object_Editor_Main\Object_Type\Function_Create = @Object_Editor_Create()
  Object_Editor_Main\Object_Type\Version = 1200
EndIf

; #### Object Popup-Menu
Object_Editor_Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
MenuItem(#Object_Editor_PopupMenu_Cut, "Cut", ImageID(Icon_Cut))
MenuItem(#Object_Editor_PopupMenu_Copy, "Copy", ImageID(Icon_Copy))
MenuItem(#Object_Editor_PopupMenu_Paste, "Paste", ImageID(Icon_Paste))
MenuBar()
MenuItem(#Object_Editor_PopupMenu_Select_All, "Select All", ImageID(Icon_Select_All))

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 18
; Folding = -------
; EnableUnicode
; EnableXP