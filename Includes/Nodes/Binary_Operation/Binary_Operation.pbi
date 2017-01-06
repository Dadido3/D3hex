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
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule _Node_Binary_Operation
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Binary_Operation
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #OR
    #AND
    #XOR
    
    #Types       ; The number of different operations
  EndEnumeration
  
  Enumeration
    #Size_Mode_Max
    #Size_Mode_Min
    #Size_Mode_A
    #Size_Mode_B
    #Size_Mode_Custom
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Object
    *Window.Window::Object
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
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Init ########################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
  Declare   Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
  Declare   Output_Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Output_Get_Size(*Output.Node::Conn_Output)
  Declare   Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  Declare   Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
  Declare   Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input_A.Node::Conn_Input
    Protected *Input_B.Node::Conn_Input
    Protected *Output.Node::Conn_Output
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    *Node\Type = Main\Node_Type
    *Node\Type_Base = Main\Node_Type
    
    *Node\Function_Delete = @_Delete()
    *Node\Function_Main = @Main()
    *Node\Function_Window = @Window_Open()
    *Node\Function_Configuration_Get = @Configuration_Get()
    *Node\Function_Configuration_Set = @Configuration_Set()
    
    *Node\Name = Main\Node_Type\Name
    *Node\Name_Inherited = *Node\Name
    *Node\Color = RGBA(180,200,250,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### Add Input
    *Input_A = Node::Input_Add(*Node, "A", "A")
    *Input_A\Function_Event = @Input_Event()
    
    ; #### Add Input
    *Input_B = Node::Input_Add(*Node, "B", "B")
    *Input_B\Function_Event = @Input_Event()
    
    ; #### Add Output
    *Output = Node::Output_Add(*Node)
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Segments = @Output_Get_Segments()
    *Output\Function_Get_Descriptor = @Output_Get_Descriptor()
    *Output\Function_Get_Size = @Output_Get_Size()
    *Output\Function_Get_Data = @Output_Get_Data()
    *Output\Function_Set_Data = @Output_Set_Data()
    *Output\Function_Shift = @Output_Shift()
    *Output\Function_Set_Data_Check = @Output_Set_Data_Check()
    *Output\Function_Shift_Check = @Output_Shift_Check()
    
    ProcedureReturn *Node
  EndProcedure
  
  Procedure _Delete(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Window_Close(*Node)
    
    FreeStructure(*Object)
    *Node\Custom_Data = #Null
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    If Not *Parent_Tag
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Negate", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\A_Negate)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Repeat", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\A_Repeat)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "A_Offset", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\A_Offset)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Negate", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\B_Negate)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Repeat", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\B_Repeat)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "B_Offset", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\B_Offset)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Operation", NBT::#Tag_Quad)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Operation)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Size_Mode", NBT::#Tag_Quad)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Size_Mode)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Size_Custom", NBT::#Tag_Quad) : NBT::Tag_Set_Number(*NBT_Tag, *Object\Size_Custom)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    If Not *Parent_Tag
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Negate")     : *Object\A_Negate     = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Repeat")     : *Object\A_Repeat     = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "A_Offset")     : *Object\A_Offset     = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Negate")     : *Object\B_Negate     = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Repeat")     : *Object\B_Repeat     = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "B_Offset")     : *Object\B_Offset     = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Operation")    : *Object\Operation    = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Size_Mode")    : *Object\Size_Mode    = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Size_Custom")  : *Object\Size_Custom  = NBT::Tag_Get_Number(*NBT_Tag)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.q Get_Size(*Node.Node::Object)
    If Not *Node
      ProcedureReturn -1
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    Protected Size.q = -1
    Protected Size_A.q
    Protected Size_B.q
    
    Select *Object\Size_Mode
      Case #Size_Mode_Max
        Size_A = Node::Input_Get_Size(FirstElement(*Node\Input())) - *Object\A_Offset
        Size_B = Node::Input_Get_Size(LastElement(*Node\Input())) - *Object\B_Offset
        Size = Size_A
        If Size < Size_B
          Size = Size_B
        EndIf
        
      Case #Size_Mode_Min
        Size_A = Node::Input_Get_Size(FirstElement(*Node\Input())) - *Object\A_Offset
        Size_B = Node::Input_Get_Size(LastElement(*Node\Input())) - *Object\B_Offset
        Size = Size_A
        If Size > Size_B
          Size = Size_B
        EndIf
        
      Case #Size_Mode_A
        Size = Node::Input_Get_Size(FirstElement(*Node\Input())) - *Object\A_Offset
        
      Case #Size_Mode_B
        Size = Node::Input_Get_Size(LastElement(*Node\Input())) - *Object\B_Offset
        
      Case #Size_Mode_Custom
        Size = *Object\Size_Custom
        
    EndSelect
    
    If Size < 0
      Size = 0
    EndIf
    
    ProcedureReturn Size
  EndProcedure
  
  Procedure Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
    If Not *Input
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Input\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    Protected Offset.q, Size.q
    
    Size = Get_Size(*Node)
    Select *Input\i
      Case 0 : Offset = *Object\A_Offset
      Case 1 : Offset = *Object\B_Offset
    EndSelect
    
    Select *Event\Type
      Case Node::#Link_Event_Update_Descriptor
        ;CopyStructure(*Event, Event, Event)
        ;Node::Conn_Output_Event(FirstElement(*Node\Output()), Event)
      
      Case Node::#Link_Event_Update, Node::#Link_Event_Goto
        ; #### Forward the event to the selection-output
        CopyStructure(*Event, Event, Node::Event)
        Event\Position - Offset
        If Event\Position < 0
          Event\Size + Event\Position
          Event\Position = 0
        EndIf
        If Event\Position + Event\Size > Size
          Event\Size = Size - Event\Position
        EndIf
        If Event\Size >= 0
          Node::Output_Event(FirstElement(*Node\Output()), Event)
        EndIf
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
    If Not *Output
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Select *Event\Type
      Case Node::#Event_Save
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_SaveAs
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_Undo
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_Redo
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ;TODO: Segments need to be forwarded
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Get_Descriptor(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Binary Operation")
    
    ProcedureReturn *Output\Descriptor
  EndProcedure
  
  Procedure.q Output_Get_Size(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn -1
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn -1
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    ProcedureReturn Get_Size(*Node)
  EndProcedure
  
  Procedure Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
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
    Protected Output_Size.q = Get_Size(*Node)
    Protected Size_A.q = Node::Input_Get_Size(FirstElement(*Node\Input()))
    Protected Size_B.q = Node::Input_Get_Size(LastElement(*Node\Input()))
    Protected Size_A_Buffer.q = Size_A - (Position + *Object\A_Offset)
    Protected Size_B_Buffer.q = Size_B - (Position + *Object\B_Offset)
    Protected Temp_Pos.q, Temp_Size.i, Temp_Pos_Real.q
    
    ; #### Limit the output to the borders
    If Size > Output_Size - Position
      Size = Output_Size - Position
    EndIf
    If Size <= 0
      ProcedureReturn #True
    EndIf
    
    ; #### If repeat is enabled, use "size" as size
    If *Object\A_Repeat
      Size_A_Buffer = Size
    EndIf
    If *Object\B_Repeat
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
      If *Object\A_Repeat
        If Size_A > 0
          For i = (Position+*Object\A_Offset)/Size_A To (Position+Size+*Object\A_Offset)/Size_A
            Temp_Pos_Real = 0
            Temp_Pos = i * Size_A - *Object\A_Offset
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
              Node::Input_Get_Data(FirstElement(*Node\Input()), Temp_Pos_Real, Temp_Size, *Temp_Data_A+Temp_Pos-Position, *Temp_Metadata_A+Temp_Pos-Position)
            EndIf
          Next
        EndIf
      Else
        Node::Input_Get_Data(FirstElement(*Node\Input()), Position+*Object\A_Offset, Size_A_Buffer, *Temp_Data_A, *Temp_Metadata_A)
      EndIf
    EndIf
    
    ; #### Prepare Buffer B
    If Size_B_Buffer > 0
      If *Object\B_Repeat
        If Size_B > 0
          For i = (Position+*Object\B_Offset)/Size_B To (Position+Size+*Object\B_Offset)/Size_B
            Temp_Pos_Real = 0
            Temp_Pos = i * Size_B - *Object\B_Offset
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
              Node::Input_Get_Data(LastElement(*Node\Input()), Temp_Pos_Real, Temp_Size, *Temp_Data_B+Temp_Pos-Position, *Temp_Metadata_B+Temp_Pos-Position)
            EndIf
          Next
        EndIf
      Else
        Node::Input_Get_Data(LastElement(*Node\Input()), Position+*Object\B_Offset, Size_B_Buffer, *Temp_Data_B, *Temp_Metadata_B)
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
      
      If *Object\A_Negate
        Temp_A = ~Temp_A
      EndIf
      
      If *Object\B_Negate
        Temp_B = ~Temp_B
      EndIf
      
      If *Data
        Select *Object\Operation
          Case #OR  : *Pointer_Data\a = Temp_A | Temp_B
          Case #AND : *Pointer_Data\a = Temp_A & Temp_B
          Case #XOR : *Pointer_Data\a = Temp_A ! Temp_B
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
  
  Procedure Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Window_Event_CheckBox()
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
    
    Protected Event.Node::Event
    
    Select Event_Gadget
      Case *Object\CheckBox[0]
        *Object\A_Negate = GetGadgetState(Event_Gadget)
        
      Case *Object\CheckBox[1]
        *Object\A_Repeat = GetGadgetState(Event_Gadget)
        
      Case *Object\CheckBox[2]
        *Object\B_Negate = GetGadgetState(Event_Gadget)
        
      Case *Object\CheckBox[3]
        *Object\B_Repeat = GetGadgetState(Event_Gadget)
        
    EndSelect
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = Get_Size(*Node)
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
  EndProcedure
  
  Procedure Window_Event_String()
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
    
    Protected Event.Node::Event
    
    Select Event_Gadget
      Case *Object\String[0]
        *Object\A_Offset = Val(GetGadgetText(Event_Gadget))
        If *Object\A_Offset < 0
          *Object\A_Offset = 0
          SetGadgetText(Event_Gadget, Str(0))
        EndIf
        
      Case *Object\String[1]
        *Object\B_Offset = Val(GetGadgetText(Event_Gadget))
        If *Object\B_Offset < 0
          *Object\B_Offset = 0
          SetGadgetText(Event_Gadget, Str(0))
        EndIf
        
      Case *Object\String[2]
        *Object\Size_Custom = Val(GetGadgetText(Event_Gadget))
        If *Object\Size_Custom < 0
          *Object\Size_Custom = 0
          SetGadgetText(Event_Gadget, Str(0))
        EndIf
        
    EndSelect
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = Get_Size(*Node)
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
  EndProcedure
  
  Procedure Window_Event_ComboBox()
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
    
    Protected Event.Node::Event
    
    *Object\Operation = GetGadgetState(Event_Gadget)
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = Get_Size(*Node)
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
  EndProcedure
  
  Procedure Window_Event_Option()
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
    
    Protected Event.Node::Event
    
    Select Event_Gadget
      Case *Object\Option[0]
        *Object\Size_Mode = #Size_Mode_Max
        
      Case *Object\Option[1]
        *Object\Size_Mode = #Size_Mode_Min
        
      Case *Object\Option[2]
        *Object\Size_Mode = #Size_Mode_A
        
      Case *Object\Option[3]
        *Object\Size_Mode = #Size_Mode_B
        
      Case *Object\Option[4]
        *Object\Size_Mode = #Size_Mode_Custom
        
    EndSelect
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = Get_Size(*Node)
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
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
    
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
    Select Event_Menu
      
    EndSelect
  EndProcedure
  
  Procedure Window_Event_CloseWindow()
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
    
    *Object\Window_Close = #True
  EndProcedure
  
  Procedure Window_Open(*Node.Node::Object)
    Protected Width, Height
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Window
      
      Width = 350
      Height = 250
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Gadgets
      
      *Object\Frame[0] = FrameGadget(#PB_Any, 10, 10, 160, 110, "A")
      *Object\CheckBox[0] = CheckBoxGadget(#PB_Any, 20, 30, 140, 20, "Negate")
      *Object\CheckBox[1] = CheckBoxGadget(#PB_Any, 20, 50, 140, 20, "Repeat")
      *Object\Text[0] = TextGadget(#PB_Any, 20, 70, 140, 20, "Offset:")
      *Object\String[0] = StringGadget(#PB_Any, 20, 90, 140, 20, "")
      
      *Object\Frame[1] = FrameGadget(#PB_Any, 10, 130, 160, 110, "B")
      *Object\CheckBox[2] = CheckBoxGadget(#PB_Any, 20, 150, 140, 20, "Negate")
      *Object\CheckBox[3] = CheckBoxGadget(#PB_Any, 20, 170, 140, 20, "Repeat")
      *Object\Text[1] = TextGadget(#PB_Any, 20, 190, 140, 20, "Offset:")
      *Object\String[1] = StringGadget(#PB_Any, 20, 210, 140, 20, "")
      
      *Object\Frame[2] = FrameGadget(#PB_Any, 180, 10, 160, 50, "Operation")
      *Object\ComboBox = ComboBoxGadget(#PB_Any, 190, 30, 140, 20)
      AddGadgetItem(*Object\ComboBox, #OR, "OR")
      AddGadgetItem(*Object\ComboBox, #AND, "AND")
      AddGadgetItem(*Object\ComboBox, #XOR, "XOR")
      
      *Object\Frame[3] = FrameGadget(#PB_Any, 180, 70, 160, 150, "Output-Size")
      *Object\Option[0] = OptionGadget(#PB_Any, 190, 90, 140, 20, "MAX (A, B)")
      *Object\Option[1] = OptionGadget(#PB_Any, 190, 110, 140, 20, "MIN (A, B)")
      *Object\Option[2] = OptionGadget(#PB_Any, 190, 130, 140, 20, "A")
      *Object\Option[3] = OptionGadget(#PB_Any, 190, 150, 140, 20, "B")
      *Object\Option[4] = OptionGadget(#PB_Any, 190, 170, 140, 20, "Custom:")
      *Object\String[2] = StringGadget(#PB_Any, 190, 190, 140, 20, "")
      
      ; #### Initialise states
      SetGadgetState(*Object\CheckBox[0], *Object\A_Negate)
      SetGadgetState(*Object\CheckBox[1], *Object\A_Repeat)
      SetGadgetText(*Object\String[0], Str(*Object\A_Offset))
      
      SetGadgetState(*Object\CheckBox[2], *Object\B_Negate)
      SetGadgetState(*Object\CheckBox[3], *Object\B_Repeat)
      SetGadgetText(*Object\String[1], Str(*Object\B_Offset))
      
      SetGadgetState(*Object\ComboBox, *Object\Operation)
      
      Select *Object\Size_Mode
        Case #Size_Mode_Max     : SetGadgetState(*Object\Option[0], #True)
        Case #Size_Mode_Min     : SetGadgetState(*Object\Option[1], #True)
        Case #Size_Mode_A       : SetGadgetState(*Object\Option[2], #True)
        Case #Size_Mode_B       : SetGadgetState(*Object\Option[3], #True)
        Case #Size_Mode_Custom  : SetGadgetState(*Object\Option[4], #True)
      EndSelect
      
      SetGadgetText(*Object\String[2], Str(*Object\Size_Custom))
      
      BindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[2], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[3], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\String[0], @Window_Event_String())
      BindGadgetEvent(*Object\String[1], @Window_Event_String())
      BindGadgetEvent(*Object\String[2], @Window_Event_String())
      BindGadgetEvent(*Object\ComboBox, @Window_Event_ComboBox())
      BindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[2], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[3], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[4], @Window_Event_Option())
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
    Else
      Window::Set_Active(*Object\Window)
    EndIf
  EndProcedure
  
  Procedure Window_Close(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window
      
      UnbindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[2], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[3], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\String[0], @Window_Event_String())
      UnbindGadgetEvent(*Object\String[1], @Window_Event_String())
      UnbindGadgetEvent(*Object\String[2], @Window_Event_String())
      UnbindGadgetEvent(*Object\ComboBox, @Window_Event_ComboBox())
      UnbindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[2], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[3], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[4], @Window_Event_Option())
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      Window::Delete(*Object\Window)
      *Object\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Main(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window
      
    EndIf
    
    If *Object\Window_Close
      *Object\Window_Close = #False
      Window_Close(*Node)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Node_Type = Node_Type::Create()
  If Main\Node_Type
    Main\Node_Type\Category = "Operation"
    Main\Node_Type\Name = "Binary Operation"
    Main\Node_Type\UID = "D3_BINOP"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,08,11,14,32,00)
    Main\Node_Type\Date_Modification = Date(2014,08,13,15,33,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Combines data per binary operation."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 900
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 871
; FirstLine = 867
; Folding = -----
; EnableUnicode
; EnableXP