; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2014-2015  David Vogel
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

#Object_Random_Chunk_Size = 128

; ##################################################### Structures ##################################################

Structure Object_Random_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Random_Main.Object_Random_Main

Structure Object_Random
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Text.i[10]
  String.i[10]
  
  ; #### Random stuff
  
  Size.q
  Seed.q
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   Object_Random_Main(*Object.Object)
Declare   _Object_Random_Delete(*Object.Object)
Declare   Object_Random_Window_Open(*Object.Object)

Declare   Object_Random_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
Declare   Object_Random_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)

Declare   Object_Random_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Random_Get_Size(*Object_Output.Object_Output)
Declare   Object_Random_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Random_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Random_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Random_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Random_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Random_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Random_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Random.Object_Random
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Random_Main\Object_Type
  *Object\Type_Base = Object_Random_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Random_Delete()
  *Object\Function_Main = @Object_Random_Main()
  *Object\Function_Window = @Object_Random_Window_Open()
  *Object\Function_Configuration_Get = @Object_Random_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Random_Configuration_Set()
  
  *Object\Name = Object_Random_Main\Object_Type\Name
  *Object\Name_Inherited = *Object\Name
  *Object\Color = RGBA(Random(100)+50,Random(100)+50,Random(100)+50,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Random)
  *Object_Random = *Object\Custom_Data
  
  *Object_Random\Size = 1000000
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Get_Descriptor = @Object_Random_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Random_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Random_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Random_Set_Data()
  *Object_Output\Function_Convolute = @Object_Random_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Random_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Random_Convolute_Check()
  
  If Requester
    Object_Random_Window_Open(*Object)
  EndIf
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Random_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  
  Object_Random_Window_Close(*Object)
  
  FreeStructure(*Object_Random)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Random_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Size", NBT::#Tag_Quad)  : NBT::Tag_Set_Number(*NBT_Tag, *Object_Random\Size)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Seed", NBT::#Tag_Quad)  : NBT::Tag_Set_Number(*NBT_Tag, *Object_Random\Seed)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Random_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT::Tag(*Parent_Tag, "Size") : *Object_Random\Size = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "Seed") : *Object_Random\Seed = NBT::Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Random_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #Null
  EndIf
  
  NBT::Tag_Set_String(NBT::Tag_Add(*Object_Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Random data")
  
  ProcedureReturn *Object_Output\Descriptor
EndProcedure

Procedure.q Object_Random_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn *Object_Random\Size
EndProcedure

Procedure Object_Random_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  
  If Position > *Object_Random\Size
    ProcedureReturn #False
  EndIf
  If Size > *Object_Random\Size - Position
    Size = *Object_Random\Size - Position
  EndIf
  If Size <= 0
    ProcedureReturn #False
  EndIf
  
  Protected *Temp, Temp_Size
  Protected N_Position.q ; Normalized position
  Protected i, Chunks.q, Start_Chunk.q
  
  Start_Chunk = Position / #Object_Random_Chunk_Size
  N_Position = Start_Chunk * #Object_Random_Chunk_Size
  Chunks = Quad_Divide_Ceil((Position - N_Position) + Size, #Object_Random_Chunk_Size)
  Temp_Size = Chunks * #Object_Random_Chunk_Size
  If Temp_Size
    *Temp = AllocateMemory(Temp_Size)
    If *Temp
      
      For i = 0 To Chunks-1
        RandomSeed(*Object_Random\Seed)
        RandomSeed(Start_Chunk + i + Random(2147483647))
        RandomData(*Temp+i*#Object_Random_Chunk_Size, #Object_Random_Chunk_Size)
      Next
      
      CopyMemory(*Temp + (Position - N_Position), *Data, Size)
      
      FreeMemory(*Temp)
      
    EndIf
  EndIf
  
  If *Metadata
    FillMemory(*Metadata, Size, #Metadata_NoError | #Metadata_Readable, #PB_Ascii)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Random_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Random_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Random_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Random_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Random_Window_Event_String_0()
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
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  If Event_Type = #PB_EventType_Change
    *Object_Random\Size = Val(GetGadgetText(Event_Gadget))
    
    If *Object_Random\Size < 0
      *Object_Random\Size = 0
    EndIf
    
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = *Object_Random\Size
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
    
  EndIf
  
EndProcedure

Procedure Object_Random_Window_Event_String_1()
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
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  If Event_Type = #PB_EventType_Change
    *Object_Random\Seed = Val(GetGadgetText(Event_Gadget))
    
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = *Object_Random\Size
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
    
  EndIf
  
EndProcedure

Procedure Object_Random_Window_Event_SizeWindow()
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
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn 
  EndIf
  
  ;ResizeGadget(*Object_Random\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ;ResizeGadget(*Object_Random\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
EndProcedure

Procedure Object_Random_Window_Event_ActivateWindow()
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
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn 
  EndIf
  
EndProcedure

Procedure Object_Random_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Random_Window_Event_CloseWindow()
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
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn 
  EndIf
  
  ;Object_Random_Window_Close(*Object)
  *Object_Random\Window_Close = #True
EndProcedure

Procedure Object_Random_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Random\Window
    
    Width = 200
    Height = 60
    
    *Object_Random\Window = Window_Create(*Object, *Object\Name_Inherited, *Object\Name, #False, 0, 0, Width, Height, #False)
    
    ; #### Toolbar
    
    ; #### Gadgets
    *Object_Random\Text[0] = TextGadget(#PB_Any, 10, 10, 50, 20, "Size:", #PB_Text_Right)
    *Object_Random\Text[1] = TextGadget(#PB_Any, 10, 30, 50, 20, "Seed:", #PB_Text_Right)
    *Object_Random\String[0] = StringGadget(#PB_Any, 70, 10, Width-80, 20, Str(*Object_Random\Size))
    *Object_Random\String[1] = StringGadget(#PB_Any, 70, 30, Width-80, 20, Str(*Object_Random\Seed), #PB_String_Numeric)
    
    BindEvent(#PB_Event_SizeWindow, @Object_Random_Window_Event_SizeWindow(), *Object_Random\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Random_Window_Event_Menu(), *Object_Random\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Random_Window_Event_CloseWindow(), *Object_Random\Window\ID)
    BindGadgetEvent(*Object_Random\String[0], @Object_Random_Window_Event_String_0())
    BindGadgetEvent(*Object_Random\String[1], @Object_Random_Window_Event_String_1())
    
  Else
    Window_Set_Active(*Object_Random\Window)
  EndIf
EndProcedure

Procedure Object_Random_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  
  If *Object_Random\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Random_Window_Event_SizeWindow(), *Object_Random\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Random_Window_Event_Menu(), *Object_Random\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Random_Window_Event_CloseWindow(), *Object_Random\Window\ID)
    UnbindGadgetEvent(*Object_Random\String[0], @Object_Random_Window_Event_String_0())
    UnbindGadgetEvent(*Object_Random\String[1], @Object_Random_Window_Event_String_1())
    
    Window_Delete(*Object_Random\Window)
    *Object_Random\Window = #Null
  EndIf
EndProcedure

Procedure Object_Random_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Random.Object_Random = *Object\Custom_Data
  If Not *Object_Random
    ProcedureReturn #False
  EndIf
  
  If *Object_Random\Window
    
  EndIf
  
  If *Object_Random\Window_Close
    *Object_Random\Window_Close = #False
    Object_Random_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Random_Main\Object_Type = Object_Type_Create()
If Object_Random_Main\Object_Type
  Object_Random_Main\Object_Type\Category = "Data-Source"
  Object_Random_Main\Object_Type\Name = "Random"
  Object_Random_Main\Object_Type\UID = "D3__RAND"
  Object_Random_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Random_Main\Object_Type\Date_Creation = Date(2014,02,17,07,43,00)
  Object_Random_Main\Object_Type\Date_Modification = Date(2014,02,17,07,43,00)
  Object_Random_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Random_Main\Object_Type\Description = "Random data."
  Object_Random_Main\Object_Type\Function_Create = @Object_Random_Create()
  Object_Random_Main\Object_Type\Version = 1000
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 200
; FirstLine = 181
; Folding = ----
; EnableXP