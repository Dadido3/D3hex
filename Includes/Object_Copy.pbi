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

#Object_Copy_Chunk_Size = 1000000

Enumeration
  #Object_Copy_State_Off
  #Object_Copy_State_A_2_B
  #Object_Copy_State_B_2_A
EndEnumeration

Enumeration
  #Object_Copy_Mode_Overwrite
  #Object_Copy_Mode_Insert
  
  #Object_Copy_Modes       ; The number of different modes
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_Copy_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Copy_Main.Object_Copy_Main

Structure Object_Copy
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Button.i[10]
  Frame.i[10]
  Option.i[10]
  CheckBox.i[10]
  ProgressBar.i
  
  ; #### Settings
  
  Mode.i
  
  Append.i
  Truncate.i
  
  ; #### State
  
  State.i
  
  Position_Read.q
  Position_Write.q
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Init ########################################################

; ##################################################### Declares ####################################################

Declare   Object_Copy_Main(*Object.Object)
Declare   _Object_Copy_Delete(*Object.Object)
Declare   Object_Copy_Window_Open(*Object.Object)

Declare   Object_Copy_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Copy_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Copy_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_Copy_Window_Close(*Object.Object)

Declare   Object_Copy_Set_State(*Object.Object, State.i)

; ##################################################### Procedures ##################################################

Procedure Object_Copy_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Copy.Object_Copy
  Protected *Object_Input_A.Object_Input
  Protected *Object_Input_B.Object_Input
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Copy_Main\Object_Type
  *Object\Type_Base = Object_Copy_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Copy_Delete()
  *Object\Function_Main = @Object_Copy_Main()
  *Object\Function_Window = @Object_Copy_Window_Open()
  *Object\Function_Configuration_Get = @Object_Copy_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Copy_Configuration_Set()
  
  *Object\Name = "Copy"
  *Object\Color = RGBA(230,180,250,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Copy)
  *Object_Copy = *Object\Custom_Data
  
  ; #### Add Input
  *Object_Input_A = Object_Input_Add(*Object, "A", "A")
  *Object_Input_A\Function_Event = @Object_Copy_Input_Event()
  
  ; #### Add Input
  *Object_Input_B = Object_Input_Add(*Object, "B", "B")
  *Object_Input_B\Function_Event = @Object_Copy_Input_Event()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Copy_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  Object_Copy_Window_Close(*Object)
  
  FreeStructure(*Object_Copy)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Copy_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Mode", #NBT_Tag_Quad)      : NBT_Tag_Set_Number(*NBT_Tag, *Object_Copy\Mode)
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Append", #NBT_Tag_Quad)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_Copy\Append)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Truncate", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_Copy\Truncate)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Copy_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Mode")     : *Object_Copy\Mode     = NBT_Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Append")   : *Object_Copy\Append   = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Truncate") : *Object_Copy\Truncate = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Copy_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update, #Object_Link_Event_Goto
      
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Copy_Window_Event_Button()
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_Copy\Button[0]
      Object_Copy_Set_State(*Object.Object, #Object_Copy_State_B_2_A)
      
    Case *Object_Copy\Button[1]
      Object_Copy_Set_State(*Object.Object, #Object_Copy_State_A_2_B)
      
    Case *Object_Copy\Button[2]
      Object_Copy_Set_State(*Object.Object, #Object_Copy_State_Off)
      
  EndSelect
  
EndProcedure

Procedure Object_Copy_Window_Event_Option()
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_Copy\Option[0]
      *Object_Copy\Mode = #Object_Copy_Mode_Overwrite
      
    Case *Object_Copy\Option[1]
      *Object_Copy\Mode = #Object_Copy_Mode_Insert
      
  EndSelect
  
EndProcedure

Procedure Object_Copy_Window_Event_CheckBox()
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_Copy\CheckBox[0]
      *Object_Copy\Append = GetGadgetState(Event_Gadget)
      
    Case *Object_Copy\CheckBox[1]
      *Object_Copy\Truncate = GetGadgetState(Event_Gadget)
      
  EndSelect
  
EndProcedure

Procedure Object_Copy_Window_Event_SizeWindow()
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn 
  EndIf
  
EndProcedure

Procedure Object_Copy_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Copy_Window_Event_CloseWindow()
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
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn 
  EndIf
  
  *Object_Copy\Window_Close = #True
EndProcedure

Procedure Object_Copy_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Copy\Window
    
    Width = 210
    Height = 170
    
    *Object_Copy\Window = Window_Create(*Object, "Copy", "Copy", #False, 0, 0, Width, Height, #False)
    
    ; #### Gadgets
    
    *Object_Copy\Button[0] = ButtonGadget(#PB_Any, 10, 10, 60, 40, "A <-- B")
    *Object_Copy\Button[1] = ButtonGadget(#PB_Any, 10, 90, 60, 40, "B <-- A")
    *Object_Copy\Button[2] = ButtonGadget(#PB_Any, 10, 50, 60, 40, "Stop")
    
    *Object_Copy\Frame[0] = FrameGadget(#PB_Any, 80, 10, 120, 120, "Settings")
    *Object_Copy\Option[0] = OptionGadget(#PB_Any, 90, 30, 100, 20, "Overwrite")
    *Object_Copy\Option[1] = OptionGadget(#PB_Any, 90, 50, 100, 20, "Insert")
    *Object_Copy\CheckBox[0] = CheckBoxGadget(#PB_Any, 90, 80, 100, 20, "Append")
    *Object_Copy\CheckBox[1] = CheckBoxGadget(#PB_Any, 90, 100, 100, 20, "Truncate")
    
    *Object_Copy\ProgressBar = ProgressBarGadget(#PB_Any, 10, 140, Width-20, 20, 0, 1000, #PB_ProgressBar_Smooth)
    
    ; #### Initialise states
    SetGadgetState(*Object_Copy\CheckBox[0], *Object_Copy\Append)
    SetGadgetState(*Object_Copy\CheckBox[1], *Object_Copy\Truncate)
    
    Select *Object_Copy\Mode
      Case #Object_Copy_Mode_Overwrite  : SetGadgetState(*Object_Copy\Option[0], #True)
      Case #Object_Copy_Mode_Insert     : SetGadgetState(*Object_Copy\Option[1], #True)
    EndSelect
    
    BindGadgetEvent(*Object_Copy\Button[0], @Object_Copy_Window_Event_Button())
    BindGadgetEvent(*Object_Copy\Button[1], @Object_Copy_Window_Event_Button())
    BindGadgetEvent(*Object_Copy\Button[2], @Object_Copy_Window_Event_Button())
    BindGadgetEvent(*Object_Copy\Option[0], @Object_Copy_Window_Event_Option())
    BindGadgetEvent(*Object_Copy\Option[1], @Object_Copy_Window_Event_Option())
    BindGadgetEvent(*Object_Copy\CheckBox[0], @Object_Copy_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Copy\CheckBox[1], @Object_Copy_Window_Event_CheckBox())
    
    BindEvent(#PB_Event_SizeWindow, @Object_Copy_Window_Event_SizeWindow(), *Object_Copy\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Copy_Window_Event_Menu(), *Object_Copy\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Copy_Window_Event_CloseWindow(), *Object_Copy\Window\ID)
    
  Else
    Window_Set_Active(*Object_Copy\Window)
  EndIf
EndProcedure

Procedure Object_Copy_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  If *Object_Copy\Window
    
    UnbindGadgetEvent(*Object_Copy\Button[0], @Object_Copy_Window_Event_Button())
    UnbindGadgetEvent(*Object_Copy\Button[1], @Object_Copy_Window_Event_Button())
    UnbindGadgetEvent(*Object_Copy\Button[2], @Object_Copy_Window_Event_Button())
    UnbindGadgetEvent(*Object_Copy\Option[0], @Object_Copy_Window_Event_Option())
    UnbindGadgetEvent(*Object_Copy\Option[1], @Object_Copy_Window_Event_Option())
    UnbindGadgetEvent(*Object_Copy\CheckBox[0], @Object_Copy_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Copy\CheckBox[1], @Object_Copy_Window_Event_CheckBox())
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Copy_Window_Event_SizeWindow(), *Object_Copy\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Copy_Window_Event_Menu(), *Object_Copy\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Copy_Window_Event_CloseWindow(), *Object_Copy\Window\ID)
    
    Window_Delete(*Object_Copy\Window)
    *Object_Copy\Window = #Null
  EndIf
EndProcedure

Procedure Object_Copy_Set_State(*Object.Object, State.i)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  *Object_Copy\State = State
  
  Select State
    Case #Object_Copy_State_Off
      DisableGadget(*Object_Copy\Button[0],   #False)
      DisableGadget(*Object_Copy\Button[1],   #False)
      DisableGadget(*Object_Copy\CheckBox[0], #False)
      DisableGadget(*Object_Copy\CheckBox[1], #False)
      DisableGadget(*Object_Copy\Option[0],   #False)
      DisableGadget(*Object_Copy\Option[1],   #False)
      SetGadgetState(*Object_Copy\ProgressBar, 0)
      
    Case #Object_Copy_State_B_2_A
      *Object_Copy\Position_Read = 0
      If *Object_Copy\Append
        *Object_Copy\Position_Write = Object_Input_Get_Size(FirstElement(*Object\Input()))
      Else
        *Object_Copy\Position_Write = 0
      EndIf
      
      DisableGadget(*Object_Copy\Button[0],   #True)
      DisableGadget(*Object_Copy\Button[1],   #True)
      DisableGadget(*Object_Copy\CheckBox[0], #True)
      DisableGadget(*Object_Copy\CheckBox[1], #True)
      DisableGadget(*Object_Copy\Option[0],   #True)
      DisableGadget(*Object_Copy\Option[1],   #True)
      SetGadgetState(*Object_Copy\ProgressBar, 0)
      
    Case #Object_Copy_State_A_2_B
      *Object_Copy\Position_Read = 0
      If *Object_Copy\Append
        *Object_Copy\Position_Write = Object_Input_Get_Size(LastElement(*Object\Input()))
      Else
        *Object_Copy\Position_Write = 0
      EndIf
      
      DisableGadget(*Object_Copy\Button[0],   #True)
      DisableGadget(*Object_Copy\Button[1],   #True)
      DisableGadget(*Object_Copy\CheckBox[0], #True)
      DisableGadget(*Object_Copy\CheckBox[1], #True)
      DisableGadget(*Object_Copy\Option[0],   #True)
      DisableGadget(*Object_Copy\Option[1],   #True)
      SetGadgetState(*Object_Copy\ProgressBar, 0)
      
  EndSelect
EndProcedure

Procedure Object_Copy_Do(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  Protected *Buffer, Buffer_Size.q
  Protected *Object_Input_In.Object_Input
  Protected *Object_Input_Out.Object_Input
  Protected Size_Input.q
  Protected Size_Output.q
  
  Select *Object_Copy\State
    Case #Object_Copy_State_Off
      
    Case #Object_Copy_State_A_2_B, #Object_Copy_State_B_2_A
      Select *Object_Copy\State
        Case #Object_Copy_State_A_2_B
          *Object_Input_In = FirstElement(*Object\Input())
          *Object_Input_Out = LastElement(*Object\Input())
        Case #Object_Copy_State_B_2_A
          *Object_Input_In = LastElement(*Object\Input())
          *Object_Input_Out = FirstElement(*Object\Input())
      EndSelect
      
      Size_Input = Object_Input_Get_Size(*Object_Input_In)
      Size_Output = Object_Input_Get_Size(*Object_Input_Out)
      
      If *Object_Copy\Position_Read < Size_Input
        Buffer_Size = Size_Input - *Object_Copy\Position_Read
        If Buffer_Size > #Object_Copy_Chunk_Size
          Buffer_Size = #Object_Copy_Chunk_Size
        EndIf
        *Buffer = AllocateMemory(Buffer_Size)
        
        If Object_Input_Get_Data(*Object_Input_In, *Object_Copy\Position_Read, Buffer_Size, *Buffer, #Null)
          
          Select *Object_Copy\Mode
            Case #Object_Copy_Mode_Insert
              If Object_Input_Convolute(*Object_Input_Out, *Object_Copy\Position_Write, Buffer_Size)
                If Not Object_Input_Set_Data(*Object_Input_Out, *Object_Copy\Position_Write, Buffer_Size, *Buffer)
                  Object_Copy_Set_State(*Object.Object, #Object_Copy_State_Off)
                EndIf
              Else
                *Object_Copy\State = #Object_Copy_State_Off
              EndIf
              
            Case #Object_Copy_Mode_Overwrite
              If Not Object_Input_Set_Data(*Object_Input_Out, *Object_Copy\Position_Write, Buffer_Size, *Buffer)
                Object_Copy_Set_State(*Object.Object, #Object_Copy_State_Off)
              EndIf
          EndSelect
          
          *Object_Copy\Position_Write + Buffer_Size
          *Object_Copy\Position_Read + Buffer_Size
        Else
          Object_Copy_Set_State(*Object.Object, #Object_Copy_State_Off)
        EndIf
        
        FreeMemory(*Buffer)
      Else
        If *Object_Copy\Truncate
          If *Object_Copy\Position_Write < Size_Output
            Object_Input_Convolute(*Object_Input_Out, *Object_Copy\Position_Write, *Object_Copy\Position_Write - Size_Output)
          EndIf
        EndIf
        
        Object_Copy_Set_State(*Object.Object, #Object_Copy_State_Off)
      EndIf
      
  EndSelect
EndProcedure

Procedure Object_Copy_ProgressBar_Update(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  Protected Size.q
  
  Select *Object_Copy\State
    Case #Object_Copy_State_A_2_B, #Object_Copy_State_B_2_A
      
      Select *Object_Copy\State
        Case #Object_Copy_State_A_2_B
          Size = Object_Input_Get_Size(FirstElement(*Object\Input()))
        Case #Object_Copy_State_B_2_A
          Size = Object_Input_Get_Size(LastElement(*Object\Input()))
      EndSelect
      
      SetGadgetState(*Object_Copy\ProgressBar, *Object_Copy\Position_Read*1000/Size)
      
  EndSelect
EndProcedure

Procedure Object_Copy_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Copy.Object_Copy = *Object\Custom_Data
  If Not *Object_Copy
    ProcedureReturn #False
  EndIf
  
  Object_Copy_Do(*Object)
  
  If *Object_Copy\Window
    Object_Copy_ProgressBar_Update(*Object)
  EndIf
  
  If *Object_Copy\Window_Close
    *Object_Copy\Window_Close = #False
    Object_Copy_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Copy_Main\Object_Type = Object_Type_Create()
If Object_Copy_Main\Object_Type
  Object_Copy_Main\Object_Type\Category = "Structure"
  Object_Copy_Main\Object_Type\Name = "Copy"
  Object_Copy_Main\Object_Type\UID = "D3__COPY"
  Object_Copy_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Copy_Main\Object_Type\Date_Creation = Date(2014,08,13,23,30,00)
  Object_Copy_Main\Object_Type\Date_Modification = Date(2014,08,15,16,58,00)
  Object_Copy_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Copy_Main\Object_Type\Description = "Copies data from one input to another input."
  Object_Copy_Main\Object_Type\Function_Create = @Object_Copy_Create()
  Object_Copy_Main\Object_Type\Version = 900
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 647
; FirstLine = 600
; Folding = ---
; EnableUnicode
; EnableXP