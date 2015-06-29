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

Enumeration
  #Object_Binary_Operation_OR
  #Object_Binary_Operation_AND
  #Object_Binary_Operation_XOR
  
  #Object_Binary_Operation_Types       ; The number of different operations
EndEnumeration

Enumeration
  #Object_Binary_Operation_Size_Mode_Max
  #Object_Binary_Operation_Size_Mode_Min
  #Object_Binary_Operation_Size_Mode_A
  #Object_Binary_Operation_Size_Mode_B
  #Object_Binary_Operation_Size_Mode_Custom
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_Binary_Operation_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Binary_Operation_Main.Object_Binary_Operation_Main

Structure Object_Binary_Operation
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Frame.i[10]
  Text.i[10]
  CheckBox.i[10]
  Option.i[10]
  ComboBox.i
  String.i[10]
  
  ; #### Settings
  A_Negate.i
  A_Repeat.i
  A_Offset.q
  
  B_Negate.i
  B_Repeat.i
  B_Offset.q
  
  Operation.i
  
  Size_Mode.i
  Size_Custom.q
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Init ########################################################

; ##################################################### Declares ####################################################

Declare   Object_Binary_Operation_Main(*Object.Object)
Declare   _Object_Binary_Operation_Delete(*Object.Object)
Declare   Object_Binary_Operation_Window_Open(*Object.Object)

Declare   Object_Binary_Operation_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
Declare   Object_Binary_Operation_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)

Declare   Object_Binary_Operation_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_Binary_Operation_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
Declare   Object_Binary_Operation_Output_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare   Object_Binary_Operation_Output_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Binary_Operation_Output_Get_Size(*Object_Output.Object_Output)
Declare   Object_Binary_Operation_Output_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Binary_Operation_Output_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Binary_Operation_Output_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Binary_Operation_Output_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Binary_Operation_Output_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Binary_Operation_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Binary_Operation_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Binary_Operation.Object_Binary_Operation
  Protected *Object_Input_A.Object_Input
  Protected *Object_Input_B.Object_Input
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Binary_Operation_Main\Object_Type
  *Object\Type_Base = Object_Binary_Operation_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Binary_Operation_Delete()
  *Object\Function_Main = @Object_Binary_Operation_Main()
  *Object\Function_Window = @Object_Binary_Operation_Window_Open()
  *Object\Function_Configuration_Get = @Object_Binary_Operation_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Binary_Operation_Configuration_Set()
  
  *Object\Name = Object_Binary_Operation_Main\Object_Type\Name
  *Object\Name_Inherited = *Object\Name
  *Object\Color = RGBA(180,200,250,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Binary_Operation)
  *Object_Binary_Operation = *Object\Custom_Data
  
  ; #### Add Input
  *Object_Input_A = Object_Input_Add(*Object, "A", "A")
  *Object_Input_A\Function_Event = @Object_Binary_Operation_Input_Event()
  
  ; #### Add Input
  *Object_Input_B = Object_Input_Add(*Object, "B", "B")
  *Object_Input_B\Function_Event = @Object_Binary_Operation_Input_Event()
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Event = @Object_Binary_Operation_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Binary_Operation_Output_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Binary_Operation_Output_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Binary_Operation_Output_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Binary_Operation_Output_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Binary_Operation_Output_Set_Data()
  *Object_Output\Function_Convolute = @Object_Binary_Operation_Output_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Binary_Operation_Output_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Binary_Operation_Output_Convolute_Check()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Binary_Operation_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  Object_Binary_Operation_Window_Close(*Object)
  
  FreeStructure(*Object_Binary_Operation)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Binary_Operation_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Negate", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\A_Negate)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Repeat", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\A_Repeat)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Offset", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\A_Offset)
  
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Negate", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\B_Negate)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Repeat", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\B_Repeat)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Offset", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\B_Offset)
  
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Operation", NBT::#Tag_Quad)   : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\Operation)
  
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Size_Mode", NBT::#Tag_Quad)   : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\Size_Mode)
  *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Size_Custom", NBT::#Tag_Quad) : NBT::Tag_Set_Number(*NBT_Tag, *Object_Binary_Operation\Size_Custom)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Binary_Operation_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Negate")     : *Object_Binary_Operation\A_Negate     = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Repeat")     : *Object_Binary_Operation\A_Repeat     = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Offset")     : *Object_Binary_Operation\A_Offset     = NBT::Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Negate")     : *Object_Binary_Operation\B_Negate     = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Repeat")     : *Object_Binary_Operation\B_Repeat     = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Offset")     : *Object_Binary_Operation\B_Offset     = NBT::Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT::Tag(*Parent_Tag, "Operation")    : *Object_Binary_Operation\Operation    = NBT::Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT::Tag(*Parent_Tag, "Size_Mode")    : *Object_Binary_Operation\Size_Mode    = NBT::Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT::Tag(*Parent_Tag, "Size_Custom")  : *Object_Binary_Operation\Size_Custom  = NBT::Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure.q Object_Binary_Operation_Get_Size(*Object.Object)
  If Not *Object
    ProcedureReturn -1
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn -1
  EndIf
  
  Protected Size.q = -1
  Protected Size_A.q
  Protected Size_B.q
  
  Select *Object_Binary_Operation\Size_Mode
    Case #Object_Binary_Operation_Size_Mode_Max
      Size_A = Object_Input_Get_Size(FirstElement(*Object\Input())) - *Object_Binary_Operation\A_Offset
      Size_B = Object_Input_Get_Size(LastElement(*Object\Input())) - *Object_Binary_Operation\B_Offset
      Size = Size_A
      If Size < Size_B
        Size = Size_B
      EndIf
      
    Case #Object_Binary_Operation_Size_Mode_Min
      Size_A = Object_Input_Get_Size(FirstElement(*Object\Input())) - *Object_Binary_Operation\A_Offset
      Size_B = Object_Input_Get_Size(LastElement(*Object\Input())) - *Object_Binary_Operation\B_Offset
      Size = Size_A
      If Size > Size_B
        Size = Size_B
      EndIf
      
    Case #Object_Binary_Operation_Size_Mode_A
      Size = Object_Input_Get_Size(FirstElement(*Object\Input())) - *Object_Binary_Operation\A_Offset
      
    Case #Object_Binary_Operation_Size_Mode_B
      Size = Object_Input_Get_Size(LastElement(*Object\Input())) - *Object_Binary_Operation\B_Offset
      
    Case #Object_Binary_Operation_Size_Mode_Custom
      Size = *Object_Binary_Operation\Size_Custom
      
  EndSelect
  
  If Size < 0
    Size = 0
  EndIf
  
  ProcedureReturn Size
EndProcedure

Procedure Object_Binary_Operation_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  Protected Offset.q, Size.q
  
  Size = Object_Binary_Operation_Get_Size(*Object)
  Select *Object_Input\i
    Case 0 : Offset = *Object_Binary_Operation\A_Offset
    Case 1 : Offset = *Object_Binary_Operation\B_Offset
  EndSelect
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update_Descriptor
      ;CopyStructure(*Object_Event, Object_Event, Object_Event)
      ;Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
    
    Case #Object_Link_Event_Update, #Object_Link_Event_Goto
      ; #### Forward the event to the selection-output
      CopyStructure(*Object_Event, Object_Event, Object_Event)
      Object_Event\Position - Offset
      If Object_Event\Position < 0
        Object_Event\Size + Object_Event\Position
        Object_Event\Position = 0
      EndIf
      If Object_Event\Position + Object_Event\Size > Size
        Object_Event\Size = Size - Object_Event\Position
      EndIf
      If Object_Event\Size >= 0
        Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
      EndIf
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Binary_Operation_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
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

Procedure Object_Binary_Operation_Output_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  ;TODO: Segments need to be forwarded
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Binary_Operation_Output_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #Null
  EndIf
  
  NBT::Tag_Set_String(NBT::Tag_Add(*Object_Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Binary Operation")
  
  ProcedureReturn *Object_Output\Descriptor
EndProcedure

Procedure.q Object_Binary_Operation_Output_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn Object_Binary_Operation_Get_Size(*Object)
EndProcedure

Procedure Object_Binary_Operation_Output_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  Protected i.i
  Protected *Pointer_Data.Ascii
  Protected *Pointer_Metadata.Ascii
  Protected *Pointer_Data_A.Ascii
  Protected *Pointer_Metadata_A.Ascii
  Protected *Pointer_Data_B.Ascii
  Protected *Pointer_Metadata_B.Ascii
  Protected Temp_A.a, Temp_B.a
  Protected Temp_Metadata.a
  Protected Output_Size.q = Object_Binary_Operation_Get_Size(*Object)
  Protected Size_A.q = Object_Input_Get_Size(FirstElement(*Object\Input()))
  Protected Size_B.q = Object_Input_Get_Size(LastElement(*Object\Input()))
  Protected Size_A_Buffer.q = Size_A - (Position + *Object_Binary_Operation\A_Offset)
  Protected Size_B_Buffer.q = Size_B - (Position + *Object_Binary_Operation\B_Offset)
  Protected Temp_Pos.q, Temp_Size.i, Temp_Pos_Real.q
  
  ; #### Limit the output to the borders
  If Size > Output_Size - Position
    Size = Output_Size - Position
  EndIf
  If Size <= 0
    ProcedureReturn #True
  EndIf
  
  ; #### If repeat is enabled, use "size" as size
  If *Object_Binary_Operation\A_Repeat
    Size_A_Buffer = Size
  EndIf
  If *Object_Binary_Operation\B_Repeat
    Size_B_Buffer = Size
  EndIf
  
  ; #### Limit the input to the borders
  If Size_A_Buffer > Size
    Size_A_Buffer = Size
  EndIf
  If Size_B_Buffer > Size
    Size_B_Buffer = Size
  EndIf
  
  ; #### Allocate everything
  If Size_A_Buffer > 0
    Protected *Temp_Data_A = AllocateMemory(Size_A_Buffer)
    If Not *Temp_Data_A
      ProcedureReturn #False
    EndIf
    Protected *Temp_Metadata_A = AllocateMemory(Size_A_Buffer)
    If Not *Temp_Metadata_A
      FreeMemory(*Temp_Data_A)
      ProcedureReturn #False
    EndIf
  EndIf
  If Size_B_Buffer > 0
    Protected *Temp_Data_B = AllocateMemory(Size_B_Buffer)
    If Not *Temp_Data_B
      FreeMemory(*Temp_Data_A)
      FreeMemory(*Temp_Metadata_A)
      ProcedureReturn #False
    EndIf
    Protected *Temp_Metadata_B = AllocateMemory(Size_B_Buffer)
    If Not *Temp_Metadata_B
      FreeMemory(*Temp_Data_A)
      FreeMemory(*Temp_Metadata_A)
      FreeMemory(*Temp_Data_B)
      ProcedureReturn #False
    EndIf
  EndIf
  
  ; #### Prepare Buffer A
  If Size_A_Buffer > 0
    If *Object_Binary_Operation\A_Repeat
      If Size_A > 0
        For i = (Position+*Object_Binary_Operation\A_Offset)/Size_A To (Position+Size+*Object_Binary_Operation\A_Offset)/Size_A
          Temp_Pos_Real = 0
          Temp_Pos = i * Size_A - *Object_Binary_Operation\A_Offset
          Temp_Size = Size_A
          If Temp_Pos < Position
            Temp_Size + Temp_Pos - Position
            Temp_Pos_Real = Position - Temp_Pos
            Temp_Pos = Position
          EndIf
          If Temp_Pos + Temp_Size > Position + Size
            Temp_Size = Position + Size - Temp_Pos
          EndIf
          If Temp_Size > 0
            Object_Input_Get_Data(FirstElement(*Object\Input()), Temp_Pos_Real, Temp_Size, *Temp_Data_A+Temp_Pos-Position, *Temp_Metadata_A+Temp_Pos-Position)
          EndIf
        Next
      EndIf
    Else
      Object_Input_Get_Data(FirstElement(*Object\Input()), Position+*Object_Binary_Operation\A_Offset, Size_A_Buffer, *Temp_Data_A, *Temp_Metadata_A)
    EndIf
  EndIf
  
  ; #### Prepare Buffer B
  If Size_B_Buffer > 0
    If *Object_Binary_Operation\B_Repeat
      If Size_B > 0
        For i = (Position+*Object_Binary_Operation\B_Offset)/Size_B To (Position+Size+*Object_Binary_Operation\B_Offset)/Size_B
          Temp_Pos_Real = 0
          Temp_Pos = i * Size_B - *Object_Binary_Operation\B_Offset
          Temp_Size = Size_B
          If Temp_Pos < Position
            Temp_Size + Temp_Pos - Position
            Temp_Pos_Real = Position - Temp_Pos
            Temp_Pos = Position
          EndIf
          If Temp_Pos + Temp_Size > Position + Size
            Temp_Size = Position + Size - Temp_Pos
          EndIf
          If Temp_Size > 0
            Object_Input_Get_Data(LastElement(*Object\Input()), Temp_Pos_Real, Temp_Size, *Temp_Data_B+Temp_Pos-Position, *Temp_Metadata_B+Temp_Pos-Position)
          EndIf
        Next
      EndIf
    Else
      Object_Input_Get_Data(LastElement(*Object\Input()), Position+*Object_Binary_Operation\B_Offset, Size_B_Buffer, *Temp_Data_B, *Temp_Metadata_B)
    EndIf
  EndIf
  
  ; #### Probably not the fastest method doing this, but still better than peeking and poking the shit out of it
  *Pointer_Data = *Data
  *Pointer_Metadata = *Metadata
  *Pointer_Data_A = *Temp_Data_A
  *Pointer_Metadata_A = *Temp_Metadata_A
  *Pointer_Data_B = *Temp_Data_B
  *Pointer_Metadata_B = *Temp_Metadata_B
  For i = 0 To Size-1
    
    Temp_Metadata = #Metadata_NoError | #Metadata_Readable
    
    If i < Size_A_Buffer
      If *Pointer_Metadata_A\a
        Temp_A = *Pointer_Data_A\a
      Else
        Temp_Metadata & ~#Metadata_NoError
      EndIf
    Else
      Temp_A = 0
    EndIf
    
    If i < Size_B_Buffer
      If *Pointer_Metadata_B\a
        Temp_B = *Pointer_Data_B\a
      Else
        Temp_Metadata & ~#Metadata_NoError
      EndIf
    Else
      Temp_B = 0
    EndIf
    
    If *Object_Binary_Operation\A_Negate
      Temp_A = ~Temp_A
    EndIf
    
    If *Object_Binary_Operation\B_Negate
      Temp_B = ~Temp_B
    EndIf
    
    If *Data
      Select *Object_Binary_Operation\Operation
        Case #Object_Binary_Operation_OR  : *Pointer_Data\a = Temp_A | Temp_B
        Case #Object_Binary_Operation_AND : *Pointer_Data\a = Temp_A & Temp_B
        Case #Object_Binary_Operation_XOR : *Pointer_Data\a = Temp_A ! Temp_B
      EndSelect
    EndIf
    
    If *Metadata
      *Pointer_Metadata\a = Temp_Metadata
    EndIf
    
    *Pointer_Data + 1
    *Pointer_Metadata + 1
    *Pointer_Data_A + 1
    *Pointer_Metadata_A + 1
    *Pointer_Data_B + 1
    *Pointer_Metadata_B + 1
  Next
  
  If Size_A_Buffer > 0
    FreeMemory(*Temp_Data_A)
    FreeMemory(*Temp_Metadata_A)
  EndIf
  If Size_B_Buffer > 0
    FreeMemory(*Temp_Data_B)
    FreeMemory(*Temp_Metadata_B)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Binary_Operation_Output_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Binary_Operation_Output_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Binary_Operation_Output_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Binary_Operation_Output_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Binary_Operation_Window_Event_CheckBox()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select Event_Gadget
    Case *Object_Binary_Operation\CheckBox[0]
      *Object_Binary_Operation\A_Negate = GetGadgetState(Event_Gadget)
      
    Case *Object_Binary_Operation\CheckBox[1]
      *Object_Binary_Operation\A_Repeat = GetGadgetState(Event_Gadget)
      
    Case *Object_Binary_Operation\CheckBox[2]
      *Object_Binary_Operation\B_Negate = GetGadgetState(Event_Gadget)
      
    Case *Object_Binary_Operation\CheckBox[3]
      *Object_Binary_Operation\B_Repeat = GetGadgetState(Event_Gadget)
      
  EndSelect
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = Object_Binary_Operation_Get_Size(*Object)
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
EndProcedure

Procedure Object_Binary_Operation_Window_Event_String()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select Event_Gadget
    Case *Object_Binary_Operation\String[0]
      *Object_Binary_Operation\A_Offset = Val(GetGadgetText(Event_Gadget))
      If *Object_Binary_Operation\A_Offset < 0
        *Object_Binary_Operation\A_Offset = 0
        SetGadgetText(Event_Gadget, Str(0))
      EndIf
      
    Case *Object_Binary_Operation\String[1]
      *Object_Binary_Operation\B_Offset = Val(GetGadgetText(Event_Gadget))
      If *Object_Binary_Operation\B_Offset < 0
        *Object_Binary_Operation\B_Offset = 0
        SetGadgetText(Event_Gadget, Str(0))
      EndIf
      
    Case *Object_Binary_Operation\String[2]
      *Object_Binary_Operation\Size_Custom = Val(GetGadgetText(Event_Gadget))
      If *Object_Binary_Operation\Size_Custom < 0
        *Object_Binary_Operation\Size_Custom = 0
        SetGadgetText(Event_Gadget, Str(0))
      EndIf
      
  EndSelect
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = Object_Binary_Operation_Get_Size(*Object)
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
EndProcedure

Procedure Object_Binary_Operation_Window_Event_ComboBox()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  *Object_Binary_Operation\Operation = GetGadgetState(Event_Gadget)
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = Object_Binary_Operation_Get_Size(*Object)
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
EndProcedure

Procedure Object_Binary_Operation_Window_Event_Option()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select Event_Gadget
    Case *Object_Binary_Operation\Option[0]
      *Object_Binary_Operation\Size_Mode = #Object_Binary_Operation_Size_Mode_Max
      
    Case *Object_Binary_Operation\Option[1]
      *Object_Binary_Operation\Size_Mode = #Object_Binary_Operation_Size_Mode_Min
      
    Case *Object_Binary_Operation\Option[2]
      *Object_Binary_Operation\Size_Mode = #Object_Binary_Operation_Size_Mode_A
      
    Case *Object_Binary_Operation\Option[3]
      *Object_Binary_Operation\Size_Mode = #Object_Binary_Operation_Size_Mode_B
      
    Case *Object_Binary_Operation\Option[4]
      *Object_Binary_Operation\Size_Mode = #Object_Binary_Operation_Size_Mode_Custom
      
  EndSelect
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = Object_Binary_Operation_Get_Size(*Object)
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
EndProcedure

Procedure Object_Binary_Operation_Window_Event_SizeWindow()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
EndProcedure

Procedure Object_Binary_Operation_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Binary_Operation_Window_Event_CloseWindow()
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
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn 
  EndIf
  
  *Object_Binary_Operation\Window_Close = #True
EndProcedure

Procedure Object_Binary_Operation_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Binary_Operation\Window
    
    Width = 350
    Height = 250
    
    *Object_Binary_Operation\Window = Window_Create(*Object, *Object\Name_Inherited, *Object\Name, #False, 0, 0, Width, Height, #False)
    
    ; #### Gadgets
    
    *Object_Binary_Operation\Frame[0] = FrameGadget(#PB_Any, 10, 10, 160, 110, "A")
    *Object_Binary_Operation\CheckBox[0] = CheckBoxGadget(#PB_Any, 20, 30, 140, 20, "Negate")
    *Object_Binary_Operation\CheckBox[1] = CheckBoxGadget(#PB_Any, 20, 50, 140, 20, "Repeat")
    *Object_Binary_Operation\Text[0] = TextGadget(#PB_Any, 20, 70, 140, 20, "Offset:")
    *Object_Binary_Operation\String[0] = StringGadget(#PB_Any, 20, 90, 140, 20, "")
    
    *Object_Binary_Operation\Frame[1] = FrameGadget(#PB_Any, 10, 130, 160, 110, "B")
    *Object_Binary_Operation\CheckBox[2] = CheckBoxGadget(#PB_Any, 20, 150, 140, 20, "Negate")
    *Object_Binary_Operation\CheckBox[3] = CheckBoxGadget(#PB_Any, 20, 170, 140, 20, "Repeat")
    *Object_Binary_Operation\Text[1] = TextGadget(#PB_Any, 20, 190, 140, 20, "Offset:")
    *Object_Binary_Operation\String[1] = StringGadget(#PB_Any, 20, 210, 140, 20, "")
    
    *Object_Binary_Operation\Frame[2] = FrameGadget(#PB_Any, 180, 10, 160, 50, "Operation")
    *Object_Binary_Operation\ComboBox = ComboBoxGadget(#PB_Any, 190, 30, 140, 20)
    AddGadgetItem(*Object_Binary_Operation\ComboBox, #Object_Binary_Operation_OR, "OR")
    AddGadgetItem(*Object_Binary_Operation\ComboBox, #Object_Binary_Operation_AND, "AND")
    AddGadgetItem(*Object_Binary_Operation\ComboBox, #Object_Binary_Operation_XOR, "XOR")
    
    *Object_Binary_Operation\Frame[3] = FrameGadget(#PB_Any, 180, 70, 160, 150, "Output-Size")
    *Object_Binary_Operation\Option[0] = OptionGadget(#PB_Any, 190, 90, 140, 20, "MAX (A, B)")
    *Object_Binary_Operation\Option[1] = OptionGadget(#PB_Any, 190, 110, 140, 20, "MIN (A, B)")
    *Object_Binary_Operation\Option[2] = OptionGadget(#PB_Any, 190, 130, 140, 20, "A")
    *Object_Binary_Operation\Option[3] = OptionGadget(#PB_Any, 190, 150, 140, 20, "B")
    *Object_Binary_Operation\Option[4] = OptionGadget(#PB_Any, 190, 170, 140, 20, "Custom:")
    *Object_Binary_Operation\String[2] = StringGadget(#PB_Any, 190, 190, 140, 20, "")
    
    ; #### Initialise states
    SetGadgetState(*Object_Binary_Operation\CheckBox[0], *Object_Binary_Operation\A_Negate)
    SetGadgetState(*Object_Binary_Operation\CheckBox[1], *Object_Binary_Operation\A_Repeat)
    SetGadgetText(*Object_Binary_Operation\String[0], Str(*Object_Binary_Operation\A_Offset))
    
    SetGadgetState(*Object_Binary_Operation\CheckBox[2], *Object_Binary_Operation\B_Negate)
    SetGadgetState(*Object_Binary_Operation\CheckBox[3], *Object_Binary_Operation\B_Repeat)
    SetGadgetText(*Object_Binary_Operation\String[1], Str(*Object_Binary_Operation\B_Offset))
    
    SetGadgetState(*Object_Binary_Operation\ComboBox, *Object_Binary_Operation\Operation)
    
    Select *Object_Binary_Operation\Size_Mode
      Case #Object_Binary_Operation_Size_Mode_Max     : SetGadgetState(*Object_Binary_Operation\Option[0], #True)
      Case #Object_Binary_Operation_Size_Mode_Min     : SetGadgetState(*Object_Binary_Operation\Option[1], #True)
      Case #Object_Binary_Operation_Size_Mode_A       : SetGadgetState(*Object_Binary_Operation\Option[2], #True)
      Case #Object_Binary_Operation_Size_Mode_B       : SetGadgetState(*Object_Binary_Operation\Option[3], #True)
      Case #Object_Binary_Operation_Size_Mode_Custom  : SetGadgetState(*Object_Binary_Operation\Option[4], #True)
    EndSelect
    
    SetGadgetText(*Object_Binary_Operation\String[2], Str(*Object_Binary_Operation\Size_Custom))
    
    BindGadgetEvent(*Object_Binary_Operation\CheckBox[0], @Object_Binary_Operation_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Binary_Operation\CheckBox[1], @Object_Binary_Operation_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Binary_Operation\CheckBox[2], @Object_Binary_Operation_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Binary_Operation\CheckBox[3], @Object_Binary_Operation_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Binary_Operation\String[0], @Object_Binary_Operation_Window_Event_String())
    BindGadgetEvent(*Object_Binary_Operation\String[1], @Object_Binary_Operation_Window_Event_String())
    BindGadgetEvent(*Object_Binary_Operation\String[2], @Object_Binary_Operation_Window_Event_String())
    BindGadgetEvent(*Object_Binary_Operation\ComboBox, @Object_Binary_Operation_Window_Event_ComboBox())
    BindGadgetEvent(*Object_Binary_Operation\Option[0], @Object_Binary_Operation_Window_Event_Option())
    BindGadgetEvent(*Object_Binary_Operation\Option[1], @Object_Binary_Operation_Window_Event_Option())
    BindGadgetEvent(*Object_Binary_Operation\Option[2], @Object_Binary_Operation_Window_Event_Option())
    BindGadgetEvent(*Object_Binary_Operation\Option[3], @Object_Binary_Operation_Window_Event_Option())
    BindGadgetEvent(*Object_Binary_Operation\Option[4], @Object_Binary_Operation_Window_Event_Option())
    
    BindEvent(#PB_Event_SizeWindow, @Object_Binary_Operation_Window_Event_SizeWindow(), *Object_Binary_Operation\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Binary_Operation_Window_Event_Menu(), *Object_Binary_Operation\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Binary_Operation_Window_Event_CloseWindow(), *Object_Binary_Operation\Window\ID)
    
  Else
    Window_Set_Active(*Object_Binary_Operation\Window)
  EndIf
EndProcedure

Procedure Object_Binary_Operation_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  If *Object_Binary_Operation\Window
    
    UnbindGadgetEvent(*Object_Binary_Operation\CheckBox[0], @Object_Binary_Operation_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Binary_Operation\CheckBox[1], @Object_Binary_Operation_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Binary_Operation\CheckBox[2], @Object_Binary_Operation_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Binary_Operation\CheckBox[3], @Object_Binary_Operation_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Binary_Operation\String[0], @Object_Binary_Operation_Window_Event_String())
    UnbindGadgetEvent(*Object_Binary_Operation\String[1], @Object_Binary_Operation_Window_Event_String())
    UnbindGadgetEvent(*Object_Binary_Operation\String[2], @Object_Binary_Operation_Window_Event_String())
    UnbindGadgetEvent(*Object_Binary_Operation\ComboBox, @Object_Binary_Operation_Window_Event_ComboBox())
    UnbindGadgetEvent(*Object_Binary_Operation\Option[0], @Object_Binary_Operation_Window_Event_Option())
    UnbindGadgetEvent(*Object_Binary_Operation\Option[1], @Object_Binary_Operation_Window_Event_Option())
    UnbindGadgetEvent(*Object_Binary_Operation\Option[2], @Object_Binary_Operation_Window_Event_Option())
    UnbindGadgetEvent(*Object_Binary_Operation\Option[3], @Object_Binary_Operation_Window_Event_Option())
    UnbindGadgetEvent(*Object_Binary_Operation\Option[4], @Object_Binary_Operation_Window_Event_Option())
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Binary_Operation_Window_Event_SizeWindow(), *Object_Binary_Operation\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Binary_Operation_Window_Event_Menu(), *Object_Binary_Operation\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Binary_Operation_Window_Event_CloseWindow(), *Object_Binary_Operation\Window\ID)
    
    Window_Delete(*Object_Binary_Operation\Window)
    *Object_Binary_Operation\Window = #Null
  EndIf
EndProcedure

Procedure Object_Binary_Operation_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Binary_Operation.Object_Binary_Operation = *Object\Custom_Data
  If Not *Object_Binary_Operation
    ProcedureReturn #False
  EndIf
  
  If *Object_Binary_Operation\Window
    
  EndIf
  
  If *Object_Binary_Operation\Window_Close
    *Object_Binary_Operation\Window_Close = #False
    Object_Binary_Operation_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Binary_Operation_Main\Object_Type = Object_Type_Create()
If Object_Binary_Operation_Main\Object_Type
  Object_Binary_Operation_Main\Object_Type\Category = "Operation"
  Object_Binary_Operation_Main\Object_Type\Name = "Binary Operation"
  Object_Binary_Operation_Main\Object_Type\UID = "D3_BINOP"
  Object_Binary_Operation_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Binary_Operation_Main\Object_Type\Date_Creation = Date(2014,08,11,14,32,00)
  Object_Binary_Operation_Main\Object_Type\Date_Modification = Date(2014,08,13,15,33,00)
  Object_Binary_Operation_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Binary_Operation_Main\Object_Type\Description = "Combines data per binary operation."
  Object_Binary_Operation_Main\Object_Type\Function_Create = @Object_Binary_Operation_Create()
  Object_Binary_Operation_Main\Object_Type\Version = 900
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 407
; FirstLine = 391
; Folding = -----
; EnableUnicode
; EnableXP