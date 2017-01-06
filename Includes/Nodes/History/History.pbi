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

DeclareModule _Node_History
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_History
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Includes ####################################################
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Operation_Type_Write
    #Operation_Type_Shift
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Operation
    Type.i
    
    Position.q
    *Data               ; For write operations
    Data_Size.i         ; For write operations
    
    Offset.q            ; For shift operations
    
    Temp_Size_Before.q  ; Temporary object-size before the operation
    Temp_Size.q         ; Temporary object-size after the operation
  EndStructure
  
  Structure Recursive_Window
    Source_Position.q
    Dest_Position.i
    
    Size.i
    
    *Current_Operation.Operation
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    Text.i
    CheckBox.i
    
    Update.l
    
    ; #### History stuff
    
    Always_Writable.l
    
    List Operation_Past.Operation()    ; All virtual operations made to the input-data
    List Operation_Future.Operation()  ; Available redo operations
    
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Init ########################################################
  
  Global Font = LoadFont(#PB_Any, "Courier New", 10)
  
  ; ################################################### Declares ####################################################
  
  Declare.q Recalculate_Past_Size(*Node.Node::Object)
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
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
  
  Procedure Undo(*Node.Node::Object, Combine=#False)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    Protected Combine_End
    
    While LastElement(*Object\Operation_Past())
      
      FirstElement(*Object\Operation_Future())
      If InsertElement(*Object\Operation_Future())
        CopyStructure(*Object\Operation_Past(), *Object\Operation_Future(), Operation)
        DeleteElement(*Object\Operation_Past())
        
        Event\Type = Node::#Link_Event_Goto
        Event\Position = *Object\Operation_Future()\Position
        Event\Size = 0
        Node::Output_Event(FirstElement(*Node\Output()), Event)
        
        Select *Object\Operation_Future()\Type
          Case #Operation_Type_Write
            Event\Type = Node::#Link_Event_Update
            Event\Position = *Object\Operation_Future()\Position
            Event\Size = *Object\Operation_Future()\Data_Size
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            Combine_End = #True
          Case #Operation_Type_Shift
            Event\Type = Node::#Link_Event_Update
            Event\Position = *Object\Operation_Future()\Position
            Event\Size = Recalculate_Past_Size(*Node) - *Object\Operation_Future()\Position
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            If *Object\Operation_Future()\Offset < 0
              Combine_End = #True
            EndIf
        EndSelect
        
      EndIf
      
      ; #### 
      If LastElement(*Object\Operation_Past())
        If Combine_End 
          If *Object\Operation_Past()\Type = #Operation_Type_Write
            Break
          ElseIf *Object\Operation_Past()\Type = #Operation_Type_Shift And *Object\Operation_Past()\Offset < 0
            Break
          EndIf
        EndIf
      EndIf
      If Not Combine
        Break
      EndIf
    Wend
    
    *Object\Update = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Redo(*Node.Node::Object, Combine=#False)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    
    While FirstElement(*Object\Operation_Future())
      
      LastElement(*Object\Operation_Past())
      If AddElement(*Object\Operation_Past())
        CopyStructure(*Object\Operation_Future(), *Object\Operation_Past(), Operation)
        DeleteElement(*Object\Operation_Future())
        
        Event\Type = Node::#Link_Event_Goto
        Event\Position = *Object\Operation_Past()\Position + *Object\Operation_Past()\Data_Size
        Event\Size = 0
        Node::Output_Event(FirstElement(*Node\Output()), Event)
        
        Select *Object\Operation_Past()\Type
          Case #Operation_Type_Write
            Event\Type = Node::#Link_Event_Update
            Event\Position = *Object\Operation_Past()\Position
            Event\Size = *Object\Operation_Past()\Data_Size
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            Break
          Case #Operation_Type_Shift
            Event\Type = Node::#Link_Event_Update
            Event\Position = *Object\Operation_Past()\Position
            Event\Size = Recalculate_Past_Size(*Node) - *Object\Operation_Past()\Position
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            If *Object\Operation_Past()\Offset < 0
              Break
            EndIf
        EndSelect
        
      EndIf
      
      ; #### 
      If Not Combine
        Break
      EndIf
    Wend
    
    *Object\Update = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Redo_Clear(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\Update = #True
    
    While FirstElement(*Object\Operation_Future())
      If *Object\Operation_Future()\Data
        FreeMemory(*Object\Operation_Future()\Data)
      EndIf
      DeleteElement(*Object\Operation_Future())
    Wend
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.q Recalculate_Past_Size(*Node.Node::Object)
    If Not *Node
      ProcedureReturn -1
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    Protected Temp_Size.q = Node::Input_Get_Size(FirstElement(*Node\Input()))
    
    PushListPosition(*Object\Operation_Past())
    
    ForEach *Object\Operation_Past()
      *Object\Operation_Past()\Temp_Size_Before = Temp_Size
      If *Object\Operation_Past()\Position >= 0 And *Object\Operation_Past()\Position <= Temp_Size
        Select *Object\Operation_Past()\Type
          Case #Operation_Type_Write
            If Temp_Size < *Object\Operation_Past()\Position + *Object\Operation_Past()\Data_Size
              Temp_Size = *Object\Operation_Past()\Position + *Object\Operation_Past()\Data_Size
            EndIf
            
          Case #Operation_Type_Shift
            Temp_Size + *Object\Operation_Past()\Offset
            If Temp_Size < *Object\Operation_Past()\Position
              Temp_Size = *Object\Operation_Past()\Position
            EndIf
            
        EndSelect
      EndIf
      *Object\Operation_Past()\Temp_Size = Temp_Size
    Next
    
    PopListPosition(*Object\Operation_Past())
    
    ProcedureReturn Temp_Size
  EndProcedure
  
  Procedure Write(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Redo_Clear(*Node)
    
    While FirstElement(*Object\Operation_Past())
      Select *Object\Operation_Past()\Type
        Case #Operation_Type_Write
          If Not Node::Input_Set_Data(FirstElement(*Node\Input()), *Object\Operation_Past()\Position, *Object\Operation_Past()\Data_Size, *Object\Operation_Past()\Data)
            Logger::Entry_Add_Error("Write failed", "Couldn't write to the destination. Aborting write process.")
            ProcedureReturn #False
          EndIf
          
        Case #Operation_Type_Shift
          If Not Node::Input_Shift(FirstElement(*Node\Input()), *Object\Operation_Past()\Position, *Object\Operation_Past()\Offset)
            Logger::Entry_Add_Error("Shifting failed", "Couldn't shift the destination. Aborting write process.")
            ProcedureReturn #False
          EndIf
          
        Default
          Logger::Entry_Add_Error("Unkown operation in the history", "If you see this, something really went wrong here!")
          ProcedureReturn #False
          
      EndSelect
      
      DeleteElement(*Object\Operation_Past())
    Wend
    
    *Object\Update = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input.Node::Conn_Input
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
    *Node\Color = RGBA(127,100,50,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### Add Input
    *Input = Node::Input_Add(*Node)
    *Input\Function_Event = @Input_Event()
    
    ; #### Add Output
    *Output = Node::Output_Add(*Node)
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Segments = @Get_Segments()
    *Output\Function_Get_Descriptor = @Get_Descriptor()
    *Output\Function_Get_Size = @Get_Size()
    *Output\Function_Get_Data = @Get_Data()
    *Output\Function_Set_Data = @Set_Data()
    *Output\Function_Shift = @Shift()
    *Output\Function_Set_Data_Check = @Set_Data_Check()
    *Output\Function_Shift_Check = @Shift_Check()
    
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
    
    ; #### Free the data of all events
    ForEach *Object\Operation_Past()
      If *Object\Operation_Past()\Data
        FreeMemory(*Object\Operation_Past()\Data)
        *Object\Operation_Past()\Data = #Null
      EndIf
    Next
    ForEach *Object\Operation_Future()
      If *Object\Operation_Future()\Data
        FreeMemory(*Object\Operation_Future()\Data)
        *Object\Operation_Future()\Data = #Null
      EndIf
    Next
    
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
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Always_Writable", NBT::#Tag_Quad)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Always_Writable)
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Always_Writable") : *Object\Always_Writable = NBT::Tag_Get_Number(*NBT_Tag)
    
    ProcedureReturn #True
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
    
    Protected *Descriptor.NBT::Element
    
    Select *Event\Type
      Case Node::#Link_Event_Update_Descriptor
        *Descriptor = Node::Input_Get_Descriptor(FirstElement(*Node\Input()))
        If *Descriptor
          *Node\Name_Inherited = *Node\Name + " ← " + NBT::Tag_Get_String(NBT::Tag(*Descriptor\Tag, "Name"))
          NBT::Error_Get()
        Else
          *Node\Name_Inherited = *Node\Name
        EndIf
        If *Object\Window
          SetWindowTitle(*Object\Window\ID, *Node\Name_Inherited)
        EndIf
        Node::Output_Event(FirstElement(*Node\Output()), *Event)
        
      Default
        ; TODO: Correct the event-range
        Node::Output_Event(FirstElement(*Node\Output()), *Event)
        
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
      Case Node::#Event_Undo
        Undo(*Node, *Event\Value[0])
        
      Case Node::#Event_Redo
        Redo(*Node, *Event\Value[0])
        
      Case Node::#Event_Save
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        Write(*Node)
        
      Case Node::#Event_SaveAs
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        Write(*Node)
        
      Default
        ; #### Todo: Correct the event-range!!!
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
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
    
    ProcedureReturn Node::Input_Get_Segments(FirstElement(*Node\Input()), Segment())
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
    
    ProcedureReturn Node::Input_Get_Descriptor(FirstElement(*Node\Input()))
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
    
    ProcedureReturn Recalculate_Past_Size(*Node)
  EndProcedure
  
  Procedure Get_Data_Recursively(*Node.Node::Object, Position.q, Size.i, *Data, *Metadata)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected NewList Window.Recursive_Window()
    Protected *Current_Operation.Operation, *Previous_Operation.Operation
    Protected *Temp_Data, *Temp_Metadata
    Protected Temp_Position_A.q, Temp_Position_B.q, Temp_Position_C.q
    Protected Temp_Size_A.q, Temp_Size_B.q, Temp_Size_C.q
    Protected Temp_A.q, Temp_B.q, Temp_C.q
    
    AddElement(Window())
    Window()\Current_Operation = LastElement(*Object\Operation_Past())
    Window()\Source_Position = Position
    Window()\Dest_Position = 0  ; Relative from *Data and *Metadata
    Window()\Size = Size
    
    While FirstElement(Window())
      *Current_Operation = Window()\Current_Operation
      If *Current_Operation
        ChangeCurrentElement(*Object\Operation_Past(), *Current_Operation)
      EndIf
      
      Repeat
        If *Current_Operation
          *Previous_Operation = PreviousElement(*Object\Operation_Past())
          
          ; #### Check if Operation is valid
          If *Current_Operation\Position >= 0 And *Current_Operation\Position <= *Current_Operation\Temp_Size_Before
            Select *Current_Operation\Type
              Case #Operation_Type_Write
                ; #### Check if Operation is inside the window
                If *Current_Operation\Position < Window()\Source_Position+Window()\Size And *Current_Operation\Position+*Current_Operation\Data_Size > Window()\Source_Position
                  ; #### Prepare everything
                  Temp_Position_A = Window()\Source_Position
                  Temp_Size_A = *Current_Operation\Position - Temp_Position_A
                  If Temp_Size_A < 0
                    Temp_Size_A = 0
                  EndIf
                  Temp_Position_B = *Current_Operation\Position
                  Temp_Size_B = *Current_Operation\Data_Size
                  If Temp_Position_B < Window()\Source_Position
                    Temp_B = Window()\Source_Position - Temp_Position_B
                    Temp_Position_B + Temp_B
                    Temp_Size_B - Temp_B
                  Else
                    Temp_B = 0
                  EndIf
                  If Temp_Size_B > Window()\Size - Temp_Size_A
                    Temp_Size_B = Window()\Size - Temp_Size_A
                  EndIf
                  Temp_Position_C = *Current_Operation\Position + *Current_Operation\Data_Size
                  Temp_Size_C = *Current_Operation\Temp_Size - Temp_Position_C
                  If Temp_Size_C > Window()\Size - Temp_Size_A - Temp_Size_B
                    Temp_Size_C = Window()\Size - Temp_Size_A - Temp_Size_B
                  EndIf
                  ; #### Write everything, create new windows...
                  If Temp_Size_B > 0
                    If *Data
                      CopyMemory(*Current_Operation\Data+Temp_B, *Data+Window()\Dest_Position+Temp_Size_A, Temp_Size_B)
                    EndIf
                    If *Metadata
                      FillMemory(*Metadata+Window()\Dest_Position+Temp_Size_A, Temp_Size_B, #Metadata_NoError | #Metadata_Readable | #Metadata_Writeable | #Metadata_Changed, #PB_Ascii)
                    EndIf
                  EndIf
                  If Temp_Size_C > 0
                    Temp_C = Window()\Dest_Position
                    PushListPosition(Window())
                    AddElement(Window())
                    Window()\Current_Operation = *Previous_Operation
                    Window()\Source_Position = Temp_Position_C
                    Window()\Dest_Position = Temp_C + Temp_Size_A + Temp_Size_B
                    Window()\Size = Temp_Size_C
                    PopListPosition(Window())
                  EndIf
                  If Temp_Size_A <= 0
                    DeleteElement(Window())
                    Break
                  ElseIf Window()\Size > Temp_Size_A
                    Window()\Size = Temp_Size_A
                    Window()\Current_Operation = *Previous_Operation
                  EndIf
                EndIf
                
              Case #Operation_Type_Shift
                ; #### Check if Operation is inside the window
                If *Current_Operation\Position < Window()\Source_Position+Window()\Size
                  ; #### Prepare everything
                  Temp_Position_A = Window()\Source_Position
                  Temp_Size_A = *Current_Operation\Position - Temp_Position_A
                  If Temp_Size_A < 0
                    Temp_Size_A = 0
                  EndIf
                  Temp_Position_B = *Current_Operation\Position
                  Temp_Size_B = *Current_Operation\Offset
                  If Temp_Position_B < Window()\Source_Position
                    Temp_B = Window()\Source_Position - Temp_Position_B
                    Temp_Position_B + Temp_B
                    Temp_Size_B - Temp_B
                  Else
                    Temp_B = 0
                  EndIf
                  If Temp_Size_B < 0
                    Temp_Size_B = 0
                  EndIf
                  If Temp_Size_B > Window()\Size - Temp_Size_A
                    Temp_Size_B = Window()\Size - Temp_Size_A
                  EndIf
                  Temp_Position_C = *Current_Operation\Position + *Current_Operation\Offset
                  If Temp_Position_C < *Current_Operation\Position
                    Temp_Position_C = *Current_Operation\Position
                  EndIf
                  Temp_Size_C = *Current_Operation\Temp_Size - Temp_Position_C
                  If Temp_Position_C < Window()\Source_Position
                    Temp_C = Window()\Source_Position - Temp_Position_C
                    Temp_Position_C + Temp_C
                    Temp_Size_C - Temp_C
                  EndIf
                  If Temp_Size_C > Window()\Size - Temp_Size_A - Temp_Size_B
                    Temp_Size_C = Window()\Size - Temp_Size_A - Temp_Size_B
                  EndIf
                  ; #### Write everything, create new windows...
                  If Temp_Size_B > 0
                    If *Data
                      FillMemory(*Data+Window()\Dest_Position+Temp_Size_A, Temp_Size_B, 0, #PB_Ascii)
                    EndIf
                    If *Metadata
                      FillMemory(*Metadata+Window()\Dest_Position+Temp_Size_A, Temp_Size_B, #Metadata_NoError | #Metadata_Readable | #Metadata_Writeable | #Metadata_Changed, #PB_Ascii)
                    EndIf
                  EndIf
                  If Temp_Size_C > 0
                    Temp_C = Window()\Dest_Position
                    PushListPosition(Window())
                    AddElement(Window())
                    Window()\Current_Operation = *Previous_Operation
                    Window()\Source_Position = Temp_Position_C-*Current_Operation\Offset
                    Window()\Dest_Position = Temp_C + Temp_Size_A + Temp_Size_B
                    Window()\Size = Temp_Size_C
                    PopListPosition(Window())
                  EndIf
                  If Temp_Size_A <= 0
                    DeleteElement(Window())
                    Break
                  ElseIf Window()\Size > Temp_Size_A
                    Window()\Size = Temp_Size_A
                    Window()\Current_Operation = *Previous_Operation
                  EndIf
                EndIf
                
            EndSelect
          EndIf
          
        Else
          ; #### No current element found --> You are at the root, so eat it... (aehm, read from it)
          If *Data
            *Temp_Data = *Data + Window()\Dest_Position
          Else
            *Temp_Data = #Null
          EndIf
          If *Metadata
            *Temp_Metadata = *Metadata + Window()\Dest_Position
          Else
            *Temp_Metadata = #Null
          EndIf
          Node::Input_Get_Data(FirstElement(*Node\Input()), Window()\Source_Position, Window()\Size, *Temp_Data, *Temp_Metadata)
          DeleteElement(Window())
          Break
        EndIf
        *Current_Operation = *Previous_Operation
      ForEver
      
    Wend
    
    ProcedureReturn #True
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
    
    Recalculate_Past_Size(*Node)
    
    Get_Data_Recursively(*Node, Position, Size, *Data, *Metadata)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Set_Data_Check_Recursively(*Node.Node::Object, Position.q, Size.i)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected NewList Window.Recursive_Window()
    Protected *Current_Operation.Operation, *Previous_Operation.Operation
    Protected Temp_Position_A.q, Temp_Position_B.q, Temp_Position_C.q
    Protected Temp_Size_A.q, Temp_Size_B.q, Temp_Size_C.q
    Protected Temp_A.q, Temp_B.q, Temp_C.q
    
    AddElement(Window())
    Window()\Current_Operation = LastElement(*Object\Operation_Past())
    Window()\Source_Position = Position
    Window()\Size = Size
    
    While FirstElement(Window())
      *Current_Operation = Window()\Current_Operation
      If *Current_Operation
        ChangeCurrentElement(*Object\Operation_Past(), *Current_Operation)
      EndIf
      
      Repeat
        If *Current_Operation
          *Previous_Operation = PreviousElement(*Object\Operation_Past())
          
          ; #### Check if Operation is valid
          If *Current_Operation\Position >= 0 And *Current_Operation\Position <= *Current_Operation\Temp_Size_Before
            Select *Current_Operation\Type
              Case #Operation_Type_Shift
                ; #### Check if Operation is inside the window
                If *Current_Operation\Position < Window()\Source_Position+Window()\Size
                  ; #### Prepare everything
                  Temp_Position_A = Window()\Source_Position
                  Temp_Size_A = *Current_Operation\Position - Temp_Position_A
                  If Temp_Size_A < 0
                    Temp_Size_A = 0
                  EndIf
                  Temp_Position_B = *Current_Operation\Position
                  Temp_Size_B = *Current_Operation\Offset
                  If Temp_Position_B < Window()\Source_Position
                    Temp_B = Window()\Source_Position - Temp_Position_B
                    Temp_Position_B + Temp_B
                    Temp_Size_B - Temp_B
                  Else
                    Temp_B = 0
                  EndIf
                  If Temp_Size_B < 0
                    Temp_Size_B = 0
                  EndIf
                  If Temp_Size_B > Window()\Size - Temp_Size_A
                    Temp_Size_B = Window()\Size - Temp_Size_A
                  EndIf
                  Temp_Position_C = *Current_Operation\Position + *Current_Operation\Offset
                  If Temp_Position_C < *Current_Operation\Position
                    Temp_Position_C = *Current_Operation\Position
                  EndIf
                  Temp_Size_C = *Current_Operation\Temp_Size - Temp_Position_C
                  If Temp_Position_C < Window()\Source_Position
                    Temp_C = Window()\Source_Position - Temp_Position_C
                    Temp_Position_C + Temp_C
                    Temp_Size_C - Temp_C
                  EndIf
                  If Temp_Size_C > Window()\Size - Temp_Size_A - Temp_Size_B
                    Temp_Size_C = Window()\Size - Temp_Size_A - Temp_Size_B
                  EndIf
                  ; #### Create new windows...
                  If Temp_Size_C > 0
                    Temp_C = Window()\Dest_Position
                    PushListPosition(Window())
                    AddElement(Window())
                    Window()\Current_Operation = *Previous_Operation
                    Window()\Source_Position = Temp_Position_C-*Current_Operation\Offset
                    Window()\Dest_Position = Temp_C + Temp_Size_A + Temp_Size_B
                    Window()\Size = Temp_Size_C
                    PopListPosition(Window())
                  EndIf
                  If Temp_Size_A <= 0
                    DeleteElement(Window())
                    Break
                  ElseIf Window()\Size > Temp_Size_A
                    Window()\Size = Temp_Size_A
                    Window()\Current_Operation = *Previous_Operation
                  EndIf
                EndIf
                
            EndSelect
          EndIf
          
        Else
          ; #### No current element found --> You are at the root
          If Not Node::Input_Set_Data_Check(FirstElement(*Node\Input()), Window()\Source_Position, Window()\Size)
            ProcedureReturn #False
          EndIf
          DeleteElement(Window())
          Break
        EndIf
        *Current_Operation = *Previous_Operation
      ForEver
      
    Wend
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
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
    
    If Size < 0
      ProcedureReturn #False
    EndIf
    If Size = 0
      ProcedureReturn #True
    EndIf
    
    If Not *Data
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    
    Recalculate_Past_Size(*Node)
    
    If Not *Object\Always_Writable And Not Set_Data_Check_Recursively(*Node, Position, Size)
      ProcedureReturn #False
    EndIf
    
    LastElement(*Object\Operation_Past())
    AddElement(*Object\Operation_Past())
    *Object\Operation_Past()\Type = #Operation_Type_Write
    *Object\Operation_Past()\Position = Position
    *Object\Operation_Past()\Data = AllocateMemory(Size)
    *Object\Operation_Past()\Data_Size = Size
    
    *Object\Update = #True
    
    CopyMemory(*Data, *Object\Operation_Past()\Data, Size)
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = Position
    Event\Size = Size
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    Redo_Clear(*Node)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Shift_Check_Recursively(*Node.Node::Object, Position.q, Offset.q)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If LastElement(*Object\Operation_Past())
      Repeat
        ; #### Check if Operation is valid
        If *Object\Operation_Past()\Position >= 0 And *Object\Operation_Past()\Position <= *Object\Operation_Past()\Temp_Size_Before
          Select *Object\Operation_Past()\Type
            Case #Operation_Type_Shift
              ; #### Check if Operation is inside the window
              If *Object\Operation_Past()\Position <= Position
                Position - *Object\Operation_Past()\Offset
                If Position < *Object\Operation_Past()\Position
                  Position = *Object\Operation_Past()\Position
                EndIf
              EndIf
              
          EndSelect
        EndIf
      Until Not PreviousElement(*Object\Operation_Past())
    EndIf
    
    ProcedureReturn Node::Input_Shift_Check(FirstElement(*Node\Input()), Position, Offset)
  EndProcedure
  
  Procedure Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
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
    
    Protected Event.Node::Event
    
    Recalculate_Past_Size(*Node)
    
    If Not *Object\Always_Writable And Not Shift_Check_Recursively(*Node, Position, Offset)
      ProcedureReturn #False
    EndIf
    
    LastElement(*Object\Operation_Past())
    AddElement(*Object\Operation_Past())
    *Object\Operation_Past()\Type = #Operation_Type_Shift
    *Object\Operation_Past()\Position = Position
    *Object\Operation_Past()\Offset = Offset
    
    *Object\Update = #True
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = Position
    Event\Size = Recalculate_Past_Size(*Node) - Position
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    Redo_Clear(*Node)
    
    ProcedureReturn #True
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
    
    Recalculate_Past_Size(*Node)
    
    If *Object\Always_Writable
      ProcedureReturn #True
    Else
      ProcedureReturn Set_Data_Check_Recursively(*Node, Position, Size)
    EndIf
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
    
    Recalculate_Past_Size(*Node)
    
    If *Object\Always_Writable
      ProcedureReturn #True
    Else
      ProcedureReturn Shift_Check_Recursively(*Node, Position, Offset)
    EndIf
  EndProcedure
  
  Procedure Window_Update(*Node.Node::Object)
    If Not *Node
      ProcedureReturn 
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn 
    EndIf
    
    Protected Text.s
    
    Text + "Past Operations:   "+ListSize(*Object\Operation_Past()) + #CRLF$
    Text + "Future Operations: "+ListSize(*Object\Operation_Future()) + #CRLF$
    
    SetGadgetText(*Object\Text, Text)
    
    SetGadgetState(*Object\CheckBox, *Object\Always_Writable)
    
  EndProcedure
  
  Procedure Window_Event_CheckBox_0()
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
    
    *Object\Always_Writable = GetGadgetState(*Object\CheckBox)
    
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
    
    ;ResizeGadget(*Object\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
    ;ResizeGadget(*Object\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
    
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
    
    ;Window_Close(*Node)
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
      
      Width = 300
      Height = 80
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Gadgets
      *Object\Text = TextGadget(#PB_Any, 10, 10, Width-20, Height-40, "")
      *Object\CheckBox = CheckBoxGadget(#PB_Any, 10, Height-30, Width-20, 20, "Always writable")
      
      SetGadgetFont(*Object\Text, FontID(Font))
      
      *Object\Update = #True
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\CheckBox, @Window_Event_CheckBox_0())
      
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
      UnbindGadgetEvent(*Object\CheckBox, @Window_Event_CheckBox_0())
      
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
      If *Object\Update
        *Object\Update = #False
        Window_Update(*Node)
      EndIf
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
    Main\Node_Type\Category = "Structure"
    Main\Node_Type\Name = "History"
    Main\Node_Type\UID = "D3__HIST"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,02,17,17,24,00)
    Main\Node_Type\Date_Modification = Date(2014,03,01,20,18,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Manages the history of the data."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 1010
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 271
; FirstLine = 248
; Folding = ------
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant