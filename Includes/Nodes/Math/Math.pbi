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
; 
; 
; 
; 
; 
; 

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

Enumeration
  #Object_Math_Operation_None
  
  ; #### Unary operations
  #Object_Math_Operation_Initialize
  #Object_Math_Operation_Reciproce
  #Object_Math_Operation_Floor
  #Object_Math_Operation_Ceil
  #Object_Math_Operation_Nearest
  #Object_Math_Operation_Absolute
  
  ; #### Binary operations
  #Object_Math_Operation_Add
  #Object_Math_Operation_Subtract
  #Object_Math_Operation_Multiply
  #Object_Math_Operation_Divide
  #Object_Math_Operation_Modulo
  #Object_Math_Operation_Powtence
  #Object_Math_Operation_Root
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_Math_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Math_Main.Object_Math_Main

Structure Object_Math_Input
  ; #### Data-Array properties
  
  Offset.q      ; in Bytes
  
  Color.l
  
  ; #### Temp Values
  List Value.Object_View1D_Input_Value()
EndStructure

Structure Object_Math
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Frame.i [10]
  ListIcon.i
  CheckBox.i [5]
  Canvas.i
  Text.i [10]
  ComboBox.i [10]
  Spin.i
  Button_Set.i
  Button_Add.i
  Button_Delete.i
  
  Update_ListIcon.i
  
  ; #### Math stuff
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Init ########################################################

Global Object_Math_Font = LoadFont(#PB_Any, "Courier New", 10)

; ##################################################### Declares ####################################################

Declare   Object_Math_Main(*Object.Object)
Declare   _Object_Math_Delete(*Object.Object)
Declare   Object_Math_Window_Open(*Object.Object)

Declare   Object_Math_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Math_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Math_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
Declare   Object_Math_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare   Object_Math_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare   Object_Math_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Math_Get_Size(*Object_Output.Object_Output)
Declare   Object_Math_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Math_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Math_Shift(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Math_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Math_Shift_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Math_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Math_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Math.Object_Math
  Protected *Object_Input.Object_Input
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Math_Main\Object_Type
  *Object\Type_Base = Object_Math_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Math_Delete()
  *Object\Function_Main = @Object_Math_Main()
  *Object\Function_Window = @Object_Math_Window_Open()
  *Object\Function_Configuration_Get = @Object_Math_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Math_Configuration_Set()
  
  *Object\Name = "Math"
  *Object\Color = RGBA(150,150,200,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Math)
  *Object_Math = *Object\Custom_Data
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Function_Event = @Object_Math_Input_Event()
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Event = @Object_Math_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Math_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Math_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Math_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Math_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Math_Set_Data()
  *Object_Output\Function_Shift = @Object_Math_Shift()
  *Object_Output\Function_Set_Data_Check = @Object_Math_Set_Data_Check()
  *Object_Output\Function_Shift_Check = @Object_Math_Shift_Check()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Math_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  Object_Math_Window_Close(*Object)
  
  FreeStructure(*Object_Math)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Math_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Size", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_Math\Size)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Math_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag(*Parent_Tag, "Size") : *Object_Math\Size = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Math_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
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
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Output_Event(FirstElement(*Object\Output()), *Object_Event)
EndProcedure

Procedure Object_Math_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
EndProcedure

Procedure Object_Math_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Input_Get_Segments(FirstElement(*Object\Input()), Segment())
EndProcedure

Procedure Object_Math_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #Null
  EndIf
  
  ProcedureReturn Object_Input_Get_Descriptor(FirstElement(*Object\Input()))
EndProcedure

Procedure.q Object_Math_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn 0
EndProcedure

Procedure Object_Math_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Math_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Math_Shift(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Math_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Math_Shift_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Math_Window_Event_Something()
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
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn 
  EndIf
  
  ; #### Some gadgetstuff here
  
EndProcedure

Procedure Object_Math_Window_Event_SizeWindow()
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
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn 
  EndIf
  
  ;ResizeGadget(*Object_Math\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ;ResizeGadget(*Object_Math\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
EndProcedure

Procedure Object_Math_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Math_Window_Event_CloseWindow()
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
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn 
  EndIf
  
  *Object_Math\Window_Close = #True
EndProcedure

Procedure Object_Math_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Math\Window
    
    Width = 300
    Height = 460
    
    *Object_Math\Window = Window_Create(*Object, "Math", "Math", #False, 0, 0, Width, Height, #False)
    
    ; #### Gadgets
    
    *Object_Math\Frame[0] = FrameGadget(#PB_Any, 10, 10, 280, 50, "Calculation")
    *Object_Math\Text[0] = TextGadget(#PB_Any, 20, 30, 50, 20, "Type:", #PB_Text_Right)
    *Object_Math\ComboBox[0] = ComboBoxGadget(#PB_Any, 80, 30, 200, 20)
    AddGadgetItem(*Object_Math\ComboBox[0], 0, "Unsigned 1 Byte Integer") : SetGadgetItemData(*Object_Math\ComboBox[0], 0, #PB_Ascii)
    AddGadgetItem(*Object_Math\ComboBox[0], 1, "Signed 1 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[0], 1, #PB_Byte)
    AddGadgetItem(*Object_Math\ComboBox[0], 2, "Unsigned 2 Byte Integer") : SetGadgetItemData(*Object_Math\ComboBox[0], 2, #PB_Unicode)
    AddGadgetItem(*Object_Math\ComboBox[0], 3, "Signed 2 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[0], 3, #PB_Word)
    AddGadgetItem(*Object_Math\ComboBox[0], 4, "Signed 4 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[0], 4, #PB_Long)
    AddGadgetItem(*Object_Math\ComboBox[0], 5, "Signed 8 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[0], 5, #PB_Quad)
    AddGadgetItem(*Object_Math\ComboBox[0], 6, "4 Byte Float")            : SetGadgetItemData(*Object_Math\ComboBox[0], 6, #PB_Float)
    AddGadgetItem(*Object_Math\ComboBox[0], 7, "8 Byte Float")            : SetGadgetItemData(*Object_Math\ComboBox[0], 7, #PB_Double)
    
    *Object_Math\Frame[0] = FrameGadget(#PB_Any, 10, 70, 280, 380, "Inputs")
    *Object_Math\ListIcon = ListIconGadget(#PB_Any, 20, 90, 260, 160, "Input", 40, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(*Object_Math\ListIcon, 1, "Operation", 70)
    AddGadgetColumn(*Object_Math\ListIcon, 2, "Manually", 60)
    AddGadgetColumn(*Object_Math\ListIcon, 3, "Type", 50)
    AddGadgetColumn(*Object_Math\ListIcon, 4, "Offset", 50)
    *Object_Math\Checkbox[0] = CheckBoxGadget(#PB_Any, 20, 260, 260, 20, "Manually")
    *Object_Math\Text[1] = TextGadget(#PB_Any, 20, 290, 70, 20, "Color:", #PB_Text_Right)
    *Object_Math\Canvas = CanvasGadget(#PB_Any, 100, 290, 180, 20)
    
    *Object_Math\Text[2] = TextGadget(#PB_Any, 20, 320, 70, 20, "Type:", #PB_Text_Right)
    *Object_Math\ComboBox[1] = ComboBoxGadget(#PB_Any, 100, 320, 180, 20)
    AddGadgetItem(*Object_Math\ComboBox[1], 0, "Unsigned 1 Byte Integer") : SetGadgetItemData(*Object_Math\ComboBox[1], 0, #PB_Ascii)
    AddGadgetItem(*Object_Math\ComboBox[1], 1, "Signed 1 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[1], 1, #PB_Byte)
    AddGadgetItem(*Object_Math\ComboBox[1], 2, "Unsigned 2 Byte Integer") : SetGadgetItemData(*Object_Math\ComboBox[1], 2, #PB_Unicode)
    AddGadgetItem(*Object_Math\ComboBox[1], 3, "Signed 2 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[1], 3, #PB_Word)
    AddGadgetItem(*Object_Math\ComboBox[1], 4, "Signed 4 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[1], 4, #PB_Long)
    AddGadgetItem(*Object_Math\ComboBox[1], 5, "Signed 8 Byte Integer")   : SetGadgetItemData(*Object_Math\ComboBox[1], 5, #PB_Quad)
    AddGadgetItem(*Object_Math\ComboBox[1], 6, "4 Byte Float")            : SetGadgetItemData(*Object_Math\ComboBox[1], 6, #PB_Float)
    AddGadgetItem(*Object_Math\ComboBox[1], 7, "8 Byte Float")            : SetGadgetItemData(*Object_Math\ComboBox[1], 7, #PB_Double)
    
    *Object_Math\Text[3] = TextGadget(#PB_Any, 20, 350, 70, 20, "Offset:", #PB_Text_Right)
    *Object_Math\Spin = SpinGadget(#PB_Any, 100, 350, 180, 20, 0, 0)
    
    *Object_Math\Text[4] = TextGadget(#PB_Any, 20, 380, 70, 20, "Operation:", #PB_Text_Right)
    *Object_Math\ComboBox[2] = ComboBoxGadget(#PB_Any, 100, 380, 180, 20)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Initialize") : SetGadgetItemData(*Object_Math\ComboBox[2], 0, #Object_Math_Operation_Initialize)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Reciproce") : SetGadgetItemData(*Object_Math\ComboBox[2], 1, #Object_Math_Operation_Reciproce)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Floor") : SetGadgetItemData(*Object_Math\ComboBox[2], 2, #Object_Math_Operation_Floor)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Ceil") : SetGadgetItemData(*Object_Math\ComboBox[2], 3, #Object_Math_Operation_Ceil)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Nearest") : SetGadgetItemData(*Object_Math\ComboBox[2], 4, #Object_Math_Operation_Nearest)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Absolute") : SetGadgetItemData(*Object_Math\ComboBox[2], 5, #Object_Math_Operation_Absolute)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "--------") : SetGadgetItemData(*Object_Math\ComboBox[2], 6, -1)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Add") : SetGadgetItemData(*Object_Math\ComboBox[2], 7, #Object_Math_Operation_Add)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Subtract") : SetGadgetItemData(*Object_Math\ComboBox[2], 8, #Object_Math_Operation_Subtract)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Multiply") : SetGadgetItemData(*Object_Math\ComboBox[2], 9, #Object_Math_Operation_Multiply)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Divide") : SetGadgetItemData(*Object_Math\ComboBox[2], 10, #Object_Math_Operation_Divide)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Modulo") : SetGadgetItemData(*Object_Math\ComboBox[2], 11, #Object_Math_Operation_Modulo)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Powtence") : SetGadgetItemData(*Object_Math\ComboBox[2], 12, #Object_Math_Operation_Powtence)
    AddGadgetItem(*Object_Math\ComboBox[2], 0, "Root") : SetGadgetItemData(*Object_Math\ComboBox[2], 13, #Object_Math_Operation_Root)
    
    *Object_Math\Button_Set = ButtonGadget(#PB_Any, 20, 410, 80, 30, "Set")
    *Object_Math\Button_Add = ButtonGadget(#PB_Any, 110, 410, 80, 30, "Add")
    *Object_Math\Button_Delete = ButtonGadget(#PB_Any, 200, 410, 80, 30, "Delete")
    
    ;BindGadgetEvent(*Object_Math\ListIcon_In, @Object_Math_Window_Event_ListIcon_In())
    ;BindGadgetEvent(*Object_Math\CheckBox_in, @Object_Math_Window_Event_CheckBox_In())
    ;BindGadgetEvent(*Object_Math\Canvas_In, @Object_Math_Window_Event_Canvas_In())
    ;BindGadgetEvent(*Object_Math\Button_In_Set, @Object_Math_Window_Event_Button_In_Set())
    ;BindGadgetEvent(*Object_Math\Button_In_Add, @Object_Math_Window_Event_Button_In_Add())
    ;BindGadgetEvent(*Object_Math\Button_In_Delete, @Object_Math_Window_Event_Button_In_Delete())
    
    BindEvent(#PB_Event_SizeWindow, @Object_Math_Window_Event_SizeWindow(), *Object_Math\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Math_Window_Event_Menu(), *Object_Math\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Math_Window_Event_CloseWindow(), *Object_Math\Window\ID)
    
    *Object_Math\Update_ListIcon = #True
    
  Else
    Window_Set_Active(*Object_Math\Window)
  EndIf
EndProcedure

Procedure Object_Math_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  If *Object_Math\Window
    
    ;UnbindGadgetEvent(*Object_Math\ListIcon_In, @Object_Math_Window_Event_ListIcon_In())
    ;UnbindGadgetEvent(*Object_Math\CheckBox_in, @Object_Math_Window_Event_CheckBox_In())
    ;UnbindGadgetEvent(*Object_Math\Canvas_In, @Object_Math_Window_Event_Canvas_In())
    ;UnbindGadgetEvent(*Object_Math\Button_In_Set, @Object_Math_Window_Event_Button_In_Set())
    ;UnbindGadgetEvent(*Object_Math\Button_In_Add, @Object_Math_Window_Event_Button_In_Add())
    ;UnbindGadgetEvent(*Object_Math\Button_In_Delete, @Object_Math_Window_Event_Button_In_Delete())
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Math_Window_Event_SizeWindow(), *Object_Math\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Math_Window_Event_Menu(), *Object_Math\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Math_Window_Event_CloseWindow(), *Object_Math\Window\ID)
    
    Window_Delete(*Object_Math\Window)
    *Object_Math\Window = #Null
  EndIf
EndProcedure

Procedure Object_Math_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Math.Object_Math = *Object\Custom_Data
  If Not *Object_Math
    ProcedureReturn #False
  EndIf
  
  If *Object_Math\Window
    
  EndIf
  
  If *Object_Math\Window_Close
    *Object_Math\Window_Close = #False
    Object_Math_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Math_Main\Object_Type = Object_Type_Create()
If Object_Math_Main\Object_Type
  Object_Math_Main\Object_Type\Category = "Analysation"
  Object_Math_Main\Object_Type\Name = "Math"
  Object_Math_Main\Object_Type\UID = "D3__MATH"
  Object_Math_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Math_Main\Object_Type\Date_Creation = Date(2014,03,07,13,39,00)
  Object_Math_Main\Object_Type\Date_Modification = Date(2014,03,07,13,39,00)
  Object_Math_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Math_Main\Object_Type\Description = "Does mathematical operations with some data."
  Object_Math_Main\Object_Type\Function_Create = @Object_Math_Create()
  Object_Math_Main\Object_Type\Version = 900
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 389
; FirstLine = 344
; Folding = ----
; EnableXP