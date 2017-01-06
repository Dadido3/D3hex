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

DeclareModule _Node_Network_Terminal
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Network_Terminal
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Inits #######################################################
  
  InitNetwork() 
  
  ; ################################################### Includes ####################################################
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Mode_TCP
    #Mode_UDP
  EndEnumeration
  
  Enumeration
    #Mode_IPv4
    #Mode_IPv6
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Chunk
    Start.q
    
    *Data
    Size.i
    
    Sent.i
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    Text.i[10]
    String.i[10]
    Frame.i [10]
    Option.i [10]
    CheckBox.i[10]
    Button_Open.i
    Button_Clear_Output.i
    Button_Clear_Input.i
    
    ; #### Network stuff
    Connection_ID.i
    
    Transport_Protocol.i
    Internet_Protocol.i
    
    Segment_Output.i
    Segment_Input.i
    
    Adress.s
    Port.l
    
    List Output_Chunk.Chunk()
    List Input_Chunk.Chunk()
    
    Received.q
    Sent.q        ; Includes also data which isn't sent yet
    
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
  
  Declare   Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
  Declare   Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Get_Size(*Output.Node::Conn_Output)
  Declare   Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  Declare   Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
  Declare   Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Procedures ##################################################
  
  Procedure Connection_Open(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    Protected Type
    
    If *Object\Connection_ID
      CloseNetworkConnection(*Object\Connection_ID)
      *Object\Connection_ID = 0
    EndIf
    
    Select *Object\Transport_Protocol
      Case #Mode_TCP : Type = #PB_Network_TCP
      Case #Mode_UDP : Type = #PB_Network_UDP
    EndSelect
    
    Select *Object\Internet_Protocol
      Case #Mode_IPv4 : Type | #PB_Network_IPv4
      Case #Mode_IPv6 : Type | #PB_Network_IPv6
    EndSelect
    
    *Object\Connection_ID = OpenNetworkConnection(*Object\Adress, *Object\Port, Type, 1000)
    
    If *Object\Connection_ID
    Else
      Logger::Entry_Add_Error("Couldn't open connection", "'"+*Object\Adress+":"+Str(*Object\Port)+"' couldn't be opened.")
    EndIf
    
    ForEach *Object\Output_Chunk()
      If *Object\Output_Chunk()\Data And *Object\Output_Chunk()\Size > *Object\Output_Chunk()\Sent
        FreeMemory(*Object\Output_Chunk()\Data)
        DeleteElement(*Object\Output_Chunk())
      EndIf
    Next
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(Node::Output_Get(*Node, 0), Event_Descriptor)
    Node::Output_Event(Node::Output_Get(*Node, 1), Event_Descriptor)
    
    ; #### Send event to update the data
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = *Object\Sent
    Node::Output_Event(Node::Output_Get(*Node, 0), Event)
    
    ; #### Reorganize Output-Chunks
    *Object\Sent = 0
    ForEach *Object\Output_Chunk()
      *Object\Output_Chunk()\Start = *Object\Sent
      *Object\Sent + *Object\Output_Chunk()\Size
    Next
    
    If *Object\Window
      If *Object\Connection_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure Connection_Close(*Node.Node::Object)
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Connection_ID
      CloseNetworkConnection(*Object\Connection_ID)
      *Object\Connection_ID = 0
    EndIf
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(Node::Output_Get(*Node, 0), Event_Descriptor)
    Node::Output_Event(Node::Output_Get(*Node, 1), Event_Descriptor)
    
    If *Object\Window
      If *Object\Connection_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
  EndProcedure
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
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
    *Node\Color = RGBA(200,150,250,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object =  *Node\Custom_Data
    
    ; #### Add Output "Output"
    *Output = Node::Output_Add(*Node, "Send", "Send")
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Segments = @Get_Segments()
    *Output\Function_Get_Descriptor = @Get_Descriptor()
    *Output\Function_Get_Size = @Get_Size()
    *Output\Function_Get_Data = @Get_Data()
    *Output\Function_Set_Data = @Set_Data()
    *Output\Function_Shift = @Shift()
    *Output\Function_Set_Data_Check = @Set_Data_Check()
    *Output\Function_Shift_Check = @Shift_Check()
    
    ; #### Add Output "Input"
    *Output = Node::Output_Add(*Node, "Receive", "Receive")
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Segments = @Get_Segments()
    *Output\Function_Get_Descriptor = @Get_Descriptor()
    *Output\Function_Get_Size = @Get_Size()
    *Output\Function_Get_Data = @Get_Data()
    *Output\Function_Set_Data = @Set_Data()
    *Output\Function_Shift = @Shift()
    *Output\Function_Set_Data_Check = @Set_Data_Check()
    *Output\Function_Shift_Check = @Shift_Check()
    
    If Requester
      Window_Open(*Node)
    EndIf
    
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
    
    If *Object\Connection_ID
      CloseNetworkConnection(*Object\Connection_ID)
    EndIf
    
    ForEach *Object\Output_Chunk()
      If *Object\Output_Chunk()\Data
        FreeMemory(*Object\Output_Chunk()\Data)
      EndIf
      DeleteElement(*Object\Output_Chunk())
    Next
    
    ForEach *Object\Input_Chunk()
      If *Object\Input_Chunk()\Data
        FreeMemory(*Object\Input_Chunk()\Data)
      EndIf
      DeleteElement(*Object\Input_Chunk())
    Next
    
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
    
    If *Object\Connection_ID
      *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Opened", NBT::#Tag_Byte)            : NBT::Tag_Set_Number(*NBT_Tag, #True)
    Else
      *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Opened", NBT::#Tag_Byte)            : NBT::Tag_Set_Number(*NBT_Tag, #False)
    EndIf
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Adress", NBT::#Tag_String)            : NBT::Tag_Set_String(*NBT_Tag, *Object\Adress)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Port", NBT::#Tag_Long)                : NBT::Tag_Set_Number(*NBT_Tag, *Object\Port)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Internet_Protocol", NBT::#Tag_Long)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Internet_Protocol)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Transport_Protocol", NBT::#Tag_Long)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Transport_Protocol)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Segment_Output", NBT::#Tag_Long)      : NBT::Tag_Set_Number(*NBT_Tag, *Object\Segment_Output)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Segment_Input", NBT::#Tag_Long)       : NBT::Tag_Set_Number(*NBT_Tag, *Object\Segment_Input)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    Protected New_Size.i, *Temp
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Adress")             : *Object\Adress = NBT::Tag_Get_String(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Port")               : *Object\Port = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Internet_Protocol")  : *Object\Internet_Protocol = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Transport_Protocol") : *Object\Transport_Protocol = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Segment_Output")     : *Object\Segment_Output = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Segment_Input")      : *Object\Segment_Input = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Opened")
    If NBT::Tag_Get_Number(*NBT_Tag)
      Connection_Open(*Node)
    EndIf
    
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
      
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
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
    
    Select *Output\i
      Case 0 ; The "Output"
        If *Object\Segment_Output
          ForEach *Object\Output_Chunk()
            AddElement(Segment())
            Segment()\Position = *Object\Output_Chunk()\Start
            Segment()\Size = *Object\Output_Chunk()\Size
            Segment()\Metadata = #Metadata_NoError | #Metadata_Readable
          Next
        EndIf
        ProcedureReturn #True
        
      Case 1 ; The "Input"
        If *Object\Segment_Input
          ForEach *Object\Input_Chunk()
            AddElement(Segment())
            Segment()\Position = *Object\Input_Chunk()\Start
            Segment()\Size = *Object\Input_Chunk()\Size
            Segment()\Metadata = #Metadata_NoError | #Metadata_Readable
          Next
        EndIf
        ProcedureReturn #True
    EndSelect
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Get_Descriptor(*Output.Node::Conn_Output)
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
    
    If *Object\Connection_ID
      Select *Output\i
        Case 0 ; The "Output"
          NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Send: "+*Object\Adress+":"+Str(*Object\Port))
          
        Case 1 ; The "Input"
          NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Receive: "+*Object\Adress+":"+Str(*Object\Port))
          
      EndSelect
      ProcedureReturn *Output\Descriptor
    Else
      ; #### Delete all tags
      While NBT::Tag_Delete(NBT::Tag_Index(*Output\Descriptor\Tag, 0))
      Wend
      NBT::Error_Get()
    EndIf
    
    ProcedureReturn #Null
  EndProcedure
  
  Procedure.q Get_Size(*Output.Node::Conn_Output)
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
    
    Select *Output\i
      Case 0 ; The "Output"
        ProcedureReturn *Object\Sent
        
      Case 1 ; The "Input"
        ProcedureReturn *Object\Received
    EndSelect
    
    ProcedureReturn -1
  EndProcedure
  
  Procedure Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
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
    
    If *Metadata
      FillMemory(*Metadata, Size, 0)
    EndIf
    If *Data
      FillMemory(*Data, Size, 0)
    EndIf
    
    Select *Output\i
      Case 0 ; The "Output"
        ForEach *Object\Output_Chunk()
          If *Object\Output_Chunk()\Start < Position + Size And *Object\Output_Chunk()\Start + *Object\Output_Chunk()\Size > Position
            Memory::Range_Copy(*Object\Output_Chunk()\Data, 0, *Data, *Object\Output_Chunk()\Start-Position, *Object\Output_Chunk()\Size, *Object\Output_Chunk()\Size, Size)
            Memory::Range_Fill(#Metadata_NoError | #Metadata_Readable, *Object\Output_Chunk()\Size, *Metadata, *Object\Output_Chunk()\Start-Position, Size)
          EndIf
        Next
        ProcedureReturn #True
        
      Case 1 ; The "Input"
        ForEach *Object\Input_Chunk()
          If *Object\Input_Chunk()\Start < Position + Size And *Object\Input_Chunk()\Start + *Object\Input_Chunk()\Size > Position
            Memory::Range_Copy(*Object\Input_Chunk()\Data, 0, *Data, *Object\Input_Chunk()\Start-Position, *Object\Input_Chunk()\Size, *Object\Input_Chunk()\Size, Size)
            Memory::Range_Fill(#Metadata_NoError | #Metadata_Readable, *Object\Input_Chunk()\Size, *Metadata, *Object\Input_Chunk()\Start-Position, Size)
          EndIf
        Next
        ProcedureReturn #True
        
    EndSelect
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
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
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Connection_ID
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    Protected *Temp
    
    Select *Output\i
      Case 0 ; The "Output"
        If Position = *Object\Sent
          *Temp = AllocateMemory(Size)
          If *Temp
            LastElement(*Object\Output_Chunk())
            AddElement(*Object\Output_Chunk())
            *Object\Output_Chunk()\Start = *Object\Sent
            *Object\Output_Chunk()\Data = *Temp
            *Object\Output_Chunk()\Size = Size
            *Object\Sent + Size
            CopyMemory(*Data, *Temp, Size)
            
            Event\Type = Node::#Link_Event_Update
            Event\Position = *Object\Sent
            Event\Size = Size
            Node::Output_Event(Node::Output_Get(*Node, 0), Event)
          EndIf
          ProcedureReturn #True
        EndIf
        
      Case 1 ; The "Input"
        ProcedureReturn #False
        
    EndSelect
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
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
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
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
    If Not *Object\Connection_ID
      ProcedureReturn #False
    EndIf
    
    Select *Output\i
      Case 0 ; The "Output"
        If Position >= *Object\Sent
          ProcedureReturn #True
        EndIf
        
      Case 1 ; The "Input"
        ProcedureReturn #False
        
    EndSelect
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
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
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Window_Event_String_0()
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
    
    If Event_Type = #PB_EventType_LostFocus
      *Object\Adress = GetGadgetText(Event_Gadget)
      
      ; #### Reopen connection if one is opened
      If *Object\Connection_ID
        Connection_Open(*Node)
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_String_1()
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
    
    If Event_Type = #PB_EventType_LostFocus
      *Object\Port = Val(GetGadgetText(Event_Gadget))
      
      ; #### Reopen connection if one is opened
      If *Object\Connection_ID
        Connection_Open(*Node)
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_Button_Clear_Output()
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
    
    ForEach *Object\Output_Chunk()
      If *Object\Output_Chunk()\Data And *Object\Output_Chunk()\Size = *Object\Output_Chunk()\Sent
        FreeMemory(*Object\Output_Chunk()\Data)
        DeleteElement(*Object\Output_Chunk())
      EndIf
    Next
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = *Object\Sent
    Node::Output_Event(Node::Output_Get(*Node, 0), Event)
    
    ; #### Reorganize Output-Chunks
    *Object\Sent = 0
    ForEach *Object\Output_Chunk()
      *Object\Output_Chunk()\Start = *Object\Sent
      *Object\Sent + *Object\Output_Chunk()\Size
    Next
    
  EndProcedure
  
  Procedure Window_Event_Button_Clear_Input()
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
    
    ForEach *Object\Input_Chunk()
      If *Object\Input_Chunk()\Data
        FreeMemory(*Object\Input_Chunk()\Data)
        DeleteElement(*Object\Input_Chunk())
      EndIf
    Next
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = *Object\Received
    Node::Output_Event(Node::Output_Get(*Node, 1), Event)
    
    *Object\Received = 0
    
  EndProcedure
  
  Procedure Window_Event_Button_Open()
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
    
    If GetGadgetState(Event_Gadget)
      Connection_Open(*Node)
    Else
      Connection_Close(*Node)
    EndIf
    
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
    
    Select Event_Gadget
      Case *Object\Option[0] : *Object\Transport_Protocol = #Mode_TCP
      Case *Object\Option[1] : *Object\Transport_Protocol = #Mode_UDP
      
      Case *Object\Option[2] : *Object\Internet_Protocol = #Mode_IPv4
      Case *Object\Option[3] : *Object\Internet_Protocol = #Mode_IPv6
    EndSelect
    
    ; #### Reopen connection if one is opened
    If *Object\Connection_ID
      Connection_Open(*Node)
    EndIf
    
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
        *Object\Segment_Output = GetGadgetState(*Object\CheckBox[0])
        
        Event\Type = Node::#Link_Event_Update
        Event\Position = 0
        Event\Size = *Object\Sent
        Node::Output_Event(Node::Output_Get(*Node, 0), Event)
        
      Case *Object\CheckBox[1]
        *Object\Segment_Input  = GetGadgetState(*Object\CheckBox[1])
        
        Event\Type = Node::#Link_Event_Update
        Event\Position = 0
        Event\Size = *Object\Received
        Node::Output_Event(Node::Output_Get(*Node, 1), Event)
        
    EndSelect
    
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
  
  Procedure Window_Event_ActivateWindow()
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
      
      Width = 430
      Height = 150
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Toolbar
      
      ; #### Gadgets
      *Object\Text[0] = TextGadget(#PB_Any, 10, 10, 50, 20, "Address:", #PB_Text_Right)
      *Object\String[0] = StringGadget(#PB_Any, 70, 10, Width-80, 20, "")
      *Object\Text[1] = TextGadget(#PB_Any, 10, 40, 50, 20, "Port:", #PB_Text_Right)
      *Object\String[1] = StringGadget(#PB_Any, 70, 40, Width-80, 20, "", #PB_String_Numeric)
      *Object\Frame[0] = FrameGadget(#PB_Any, 10, 70, 100, 70, "Transport Protocol")
      *Object\Option[0] = OptionGadget(#PB_Any, 20, 90, 80, 20, "TCP")
      *Object\Option[1] = OptionGadget(#PB_Any, 20, 110, 80, 20, "UDP")
      *Object\Frame[0] = FrameGadget(#PB_Any, 120, 70, 100, 70, "Internet Protocol")
      *Object\Option[2] = OptionGadget(#PB_Any, 130, 90, 80, 20, "IPv4")
      *Object\Option[3] = OptionGadget(#PB_Any, 130, 110, 80, 20, "IPv6")
      *Object\Frame[1] = FrameGadget(#PB_Any, 230, 70, 100, 70, "Show Segments in")
      *Object\CheckBox[0] = CheckBoxGadget(#PB_Any, 240, 90, 80, 20, "Sent")
      *Object\CheckBox[1] = CheckBoxGadget(#PB_Any, 240, 110, 80, 20, "Received")
      *Object\Button_Clear_Output = ButtonGadget(#PB_Any, Width-90, Height-80, 80, 20, "Clear Sent")
      *Object\Button_Clear_Input = ButtonGadget(#PB_Any, Width-90, Height-60, 80, 20, "Clear Received")
      *Object\Button_Open = ButtonGadget(#PB_Any, Width-90, Height-40, 80, 30, "Open", #PB_Button_Toggle)
      
      SetGadgetText(*Object\String[0], *Object\Adress)
      SetGadgetText(*Object\String[1], Str(*Object\Port))
      
      Select *Object\Transport_Protocol
        Case #Mode_TCP  : SetGadgetState(*Object\Option[0], #True)
        Case #Mode_UDP  : SetGadgetState(*Object\Option[1], #True)
      EndSelect
      
      Select *Object\Internet_Protocol
        Case #Mode_IPv4 : SetGadgetState(*Object\Option[2], #True)
        Case #Mode_IPv6 : SetGadgetState(*Object\Option[3], #True)
      EndSelect
      
      If *Object\Segment_Output
        SetGadgetState(*Object\CheckBox[0], #True)
      Else
        SetGadgetState(*Object\CheckBox[0], #False)
      EndIf
      
      If *Object\Segment_Input
        SetGadgetState(*Object\CheckBox[1], #True)
      Else
        SetGadgetState(*Object\CheckBox[1], #False)
      EndIf
      
      If *Object\Connection_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\String[0], @Window_Event_String_0())
      BindGadgetEvent(*Object\String[1], @Window_Event_String_1())
      BindGadgetEvent(*Object\Button_Clear_Output, @Window_Event_Button_Clear_Output())
      BindGadgetEvent(*Object\Button_Clear_Input, @Window_Event_Button_Clear_Input())
      BindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      BindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[2], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[3], @Window_Event_Option())
      BindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
    
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
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      UnbindGadgetEvent(*Object\String[0], @Window_Event_String_0())
      UnbindGadgetEvent(*Object\String[1], @Window_Event_String_1())
      UnbindGadgetEvent(*Object\Button_Clear_Output, @Window_Event_Button_Clear_Output())
      UnbindGadgetEvent(*Object\Button_Clear_Input, @Window_Event_Button_Clear_Input())
      UnbindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      UnbindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[2], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[3], @Window_Event_Option())
      UnbindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      
      Window::Delete(*Object\Window)
      *Object\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Network_Available(Connection_ID.i)
    Protected Length.i
    Protected RetVal.i
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      RetVal = ioctlsocket_(Connection_ID, #FIONREAD, @Length)
    CompilerElse
      RetVal = ioctl_(Connection_ID, #FIONREAD, @Length)
    CompilerEndIf
    
    ProcedureReturn Length
  EndProcedure
  
  Procedure Network(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    Protected *Temp, Temp_Size.i
    Protected Network_Event
    Protected Result.i
    
    If *Object\Connection_ID
      Network_Event = NetworkClientEvent(*Object\Connection_ID)
      
      ; #### Send data
      ForEach *Object\Output_Chunk()
        If *Object\Output_Chunk()\Sent < *Object\Output_Chunk()\Size
          Result = SendNetworkData(*Object\Connection_ID, *Object\Output_Chunk()\Data+*Object\Output_Chunk()\Sent, *Object\Output_Chunk()\Size-*Object\Output_Chunk()\Sent)
          If Result > 0
            *Object\Output_Chunk()\Sent + Result
          EndIf
          Break
        EndIf
      Next
      
      ; #### Receive data
      Select Network_Event
        Case #PB_NetworkEvent_None
          ProcedureReturn #False
          
        Case #PB_NetworkEvent_Data
          Temp_Size = Network_Available(ConnectionID(*Object\Connection_ID))
          If Temp_Size > 0
            *Temp = AllocateMemory(Temp_Size)
            If *Temp
              LastElement(*Object\Input_Chunk())
              AddElement(*Object\Input_Chunk())
              *Object\Input_Chunk()\Start = *Object\Received
              *Object\Input_Chunk()\Data = *Temp
              *Object\Input_Chunk()\Size = Temp_Size
              *Object\Received + Temp_Size
              ReceiveNetworkData(*Object\Connection_ID, *Temp, Temp_Size)
              
              Event\Type = Node::#Link_Event_Update
              Event\Position = *Object\Input_Chunk()\Start
              Event\Size = *Object\Input_Chunk()\Size
              Node::Output_Event(Node::Output_Get(*Node, 1), Event)
              
            EndIf
          EndIf
          
        Case #PB_NetworkEvent_Disconnect
          *Object\Connection_ID = 0
          If *Object\Window
            SetGadgetText(*Object\Button_Open, "Open")
            SetGadgetState(*Object\Button_Open, #False)
            ; #### Send event for the updated descriptor
            Event\Type = Node::#Link_Event_Update_Descriptor
            Node::Output_Event(Node::Output_Get(*Node, 0), Event)
            Node::Output_Event(Node::Output_Get(*Node, 1), Event)
          EndIf
          
      EndSelect
      
      ProcedureReturn #True
    Else
      ProcedureReturn #False
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
    
    Protected Time.q
    
    Time = ElapsedMilliseconds() + 30
    While Network(*Node) And Time > ElapsedMilliseconds()
    Wend
    
    If *Object\Window_Close
      *Object\Window_Close = #False
      Window_Close(*Node)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Node_Type = Node_Type::Create()
  If Main\Node_Type
    Main\Node_Type\Category = "Data-Source"
    Main\Node_Type\Name = "Network Terminal"
    Main\Node_Type\UID = "D3NETERM"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,03,02,12,00,00)
    Main\Node_Type\Date_Modification = Date(2014,03,02,21,56,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Provides data in- and output with a network server."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 1000
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 937
; FirstLine = 932
; Folding = ------
; EnableUnicode
; EnableXP