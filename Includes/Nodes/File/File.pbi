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

DeclareModule _Node_File
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  Declare   Create_And_Open(Filename.s)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_File
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Mode_Read
    #Mode_Write
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
    Editor.i
    Option.i[10]
    CheckBox.i[10]
    Button_File.i
    Button_Create.i
    Button_Open.i
    
    ; #### File stuff
    File_ID.i
    
    Mode.i
    Cached.i
    Shared_Read.i
    Shared_Write.i
    
    Filename.s
    
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
  
  Declare   Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Get_Size(*Output.Node::Conn_Output)
  Declare   Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  Declare   Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
  Declare   Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  Declare   Window_Open(*Node.Node::Object)
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Procedures ##################################################
  
  Procedure File_Create(*Node.Node::Object) ; #### That function doesn't create a file-object. It creates a file
    Protected Flags
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\File_ID
      CloseFile(*Object\File_ID)
      *Object\File_ID = 0
    EndIf
    
    If Not *Object\Cached
      Flags | #PB_File_NoBuffering
    EndIf
    If *Object\Shared_Read
      Flags | #PB_File_SharedRead
    EndIf
    If *Object\Shared_Write
      Flags | #PB_File_SharedWrite
    EndIf
    
    *Object\File_ID = CreateFile(#PB_Any, *Object\Filename, Flags) : *Object\Mode = #Mode_Write
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(FirstElement(*Node\Output()), Event_Descriptor)
    
    ; #### Send event to update the data
    If *Object\File_ID
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = Lof(*Object\File_ID)
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    Else
      Logger::Entry_Add_Error("Couldn't create file", "'"+*Object\Filename+"' couldn't be created. The file object now behaves like a new file.")
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = 0
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    EndIf
    
    If *Object\Window
      If *Object\File_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
  EndProcedure
  
  Procedure File_Open(*Node.Node::Object)
    Protected Flags
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\File_ID
      CloseFile(*Object\File_ID)
      *Object\File_ID = 0
    EndIf
    
    If Not *Object\Cached
      Flags | #PB_File_NoBuffering
    EndIf
    If *Object\Shared_Read
      Flags | #PB_File_SharedRead
    EndIf
    If *Object\Shared_Write
      Flags | #PB_File_SharedWrite
    EndIf
    
    Select *Object\Mode
      Case #Mode_Read   : *Object\File_ID = ReadFile(#PB_Any, *Object\Filename, Flags)
      Case #Mode_Write  : *Object\File_ID = OpenFile(#PB_Any, *Object\Filename, Flags)
    EndSelect
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(FirstElement(*Node\Output()), Event_Descriptor)
    
    ; #### Send event to update the data
    If *Object\File_ID
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = Lof(*Object\File_ID)
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    Else
      Logger::Entry_Add_Error("Couldn't open file", "'"+*Object\Filename+"' couldn't be opened. The file object now behaves like a new file.")
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = 0
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    EndIf
    
    If *Object\Window
      If *Object\File_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure File_Close(*Node.Node::Object)
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\File_ID
      CloseFile(*Object\File_ID)
      *Object\File_ID = 0
    EndIf
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(FirstElement(*Node\Output()), Event_Descriptor)
    
    ; #### Send event to update the data
    Event\Type = Node::#Link_Event_Update
    Event\Position = 0
    Event\Size = 0
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    If *Object\Window
      If *Object\File_ID
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
    Protected Filename.s
    
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
    *Node\Color = RGBA(176,137,0,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### Add Output
    *Output = Node::Output_Add(*Node)
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Descriptor = @Get_Descriptor()
    *Output\Function_Get_Size = @Get_Size()
    *Output\Function_Get_Data = @Get_Data()
    *Output\Function_Set_Data = @Set_Data()
    *Output\Function_Shift = @Shift()
    *Output\Function_Set_Data_Check = @Set_Data_Check()
    *Output\Function_Shift_Check = @Shift_Check()
    
    ; #### Open file
    If Requester
      *Object\Mode = #Mode_Write
      *Object\Cached = #True
      *Object\Shared_Read = #True
      *Object\Shared_Write = #True
      Filename = OpenFileRequester("Open File", "", "", 0)
      If Filename
        *Object\Filename = Filename
        File_Open(*Node)
      EndIf
    EndIf
    
    ProcedureReturn *Node
  EndProcedure
  
  Procedure Create_And_Open(Filename.s)
    Protected *Node.Node::Object = Create(#False)
    If Not *Node
      ProcedureReturn #Null
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\Mode = #Mode_Write
    *Object\Cached = #True
    *Object\Shared_Read = #True
    *Object\Shared_Write = #True
    *Object\Filename = Filename
    File_Open(*Node)
    
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
    
    If *Object\File_ID
      CloseFile(*Object\File_ID)
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
    
    If *Object\File_ID
      *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Opened", NBT::#Tag_Byte)      : NBT::Tag_Set_Number(*NBT_Tag, #True)
    Else
      *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Opened", NBT::#Tag_Byte)      : NBT::Tag_Set_Number(*NBT_Tag, #False)
    EndIf
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Filename", NBT::#Tag_String)    : NBT::Tag_Set_String(*NBT_Tag, *Object\Filename)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Mode", NBT::#Tag_Byte)          : NBT::Tag_Set_Number(*NBT_Tag, *Object\Mode)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Shared_Read", NBT::#Tag_Byte)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Shared_Read)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Shared_Write", NBT::#Tag_Byte)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Shared_Write)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Cached", NBT::#Tag_Byte)        : NBT::Tag_Set_Number(*NBT_Tag, *Object\Cached)
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Filename")     : *Object\Filename = NBT::Tag_Get_String(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Mode")         : *Object\Mode = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Shared_Read")  : *Object\Shared_Read = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Shared_Write") : *Object\Shared_Write = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Cached")       : *Object\Cached = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Opened")
    If NBT::Tag_Get_Number(*NBT_Tag)
      File_Open(*Node)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Event(*Node_Output.Node::Conn_Output, *Node_Event.Node::Event)
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    If Not *Node_Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Filename.s
    
    Select *Node_Event\Type
      Case Node::#Event_Save
        If Not *Object\File_ID
          ; #### Open file
          Filename = SaveFileRequester("Save File", "", "", 0)
          If Filename
            *Object\Filename = Filename
            *Object\Mode = #Mode_Write ; TODO: Update the GUI
            *Object\Cached = #True
            *Object\Shared_Read = #True
            *Object\Shared_Write = #True
            File_Create(*Node)
          EndIf
        EndIf
        
      Case Node::#Event_SaveAs
        If Not *Object\File_ID
          ; #### Open file
          Filename = SaveFileRequester("Save File", "", "", 0)
          If Filename
            *Object\Filename = Filename
            *Object\Mode = #Mode_Write ; TODO: Update the GUI
            *Object\Cached = #True
            *Object\Shared_Read = #True
            *Object\Shared_Write = #True
            File_Create(*Node)
          EndIf
        Else
          Filename = SaveFileRequester("Save File As", "", "", 0)
          If Filename
            If CopyFile(*Object\Filename, Filename)
              *Object\Filename = Filename
              *Object\Mode = #Mode_Write ; TODO: Update the GUI
              *Object\Cached = #True
              *Object\Shared_Read = #True
              *Object\Shared_Write = #True
              File_Open(*Node)
            EndIf
          EndIf
        EndIf
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Descriptor(*Node_Output.Node::Conn_Output)
    If Not *Node_Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    If *Object\File_ID
      NBT::Tag_Set_String(NBT::Tag_Add(*Node_Output\Descriptor\Tag, "Name", NBT::#Tag_String), GetFilePart(*Object\Filename))
      NBT::Tag_Set_String(NBT::Tag_Add(*Node_Output\Descriptor\Tag, "Type", NBT::#Tag_String), "File")
      NBT::Tag_Set_String(NBT::Tag_Add(*Node_Output\Descriptor\Tag, "Filename", NBT::#Tag_String), *Object\Filename)
      ProcedureReturn *Node_Output\Descriptor
    Else
      ; #### Delete all tags
      While NBT::Tag_Delete(NBT::Tag_Index(*Node_Output\Descriptor\Tag, 0))
      Wend
      NBT::Error_Get()
    EndIf
    
    ProcedureReturn #Null
  EndProcedure
  
  Procedure.q Get_Size(*Node_Output.Node::Conn_Output)
    If Not *Node_Output
      ProcedureReturn -1
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn -1
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    If *Object\File_ID
      ProcedureReturn Lof(*Object\File_ID)
    Else
      ProcedureReturn 0 ; Not initialized --> Behave like an empty file
    EndIf
  EndProcedure
  
  Procedure Get_Data(*Node_Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
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
    
    Protected Read_Size.i
    
    If *Object\File_ID
      
      If Lof(*Object\File_ID) < Position
        ProcedureReturn #False
      EndIf
      
      FileSeek(*Object\File_ID, Position)
      Read_Size = ReadData(*Object\File_ID, *Data, Size)
      
      If *Metadata
        If Size > 0
          FillMemory(*Metadata, Read_Size, #Metadata_NoError | #Metadata_Readable | #Metadata_Writeable, #PB_Ascii)
        EndIf
        If Size - Read_Size > 0
          FillMemory(*Metadata+Read_Size, Size-Read_Size, 0, #PB_Ascii)
        EndIf
      EndIf
      
      ProcedureReturn #True
    Else
      If *Metadata
        If Size > 0
          FillMemory(*Metadata, Size, 0, #PB_Ascii)
        EndIf
      EndIf
      ProcedureReturn #True ; Not initialized --> Behave like an empty file
    EndIf
  EndProcedure
  
  Procedure Set_Data(*Node_Output.Node::Conn_Output, Position.q, Size.i, *Data)
    Protected Result.i
    Protected Object_Event.Node::Event
    Protected File_Size.q
    
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    
    ; #### Don't write over the end of the file (REMOVED, ALL OBJECTS SHOULD ALLOW TO BE WRITTEN AT THE END WITHOUT SHIFTING)
    ;File_Size = Get_Size(*Node_Output)
    ;If Size + Position > File_Size
    ;  Size = File_Size - Position
    ;EndIf
    
    If Size <= 0
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\File_ID
      Logger::Entry_Add_Error("There is no file opened", "There is no file opened. Couldn't write.")
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Mode = #Mode_Write
      Logger::Entry_Add_Error("Couldn't write to the file", "The file is in read only mode.")
      ProcedureReturn #False
    EndIf
    
    If Lof(*Object\File_ID) < Position
      ProcedureReturn #False
    EndIf
    
    ;If Not *Object\File_ID
    ;  *Object\Filename = SaveFileRequester("Save file", "", "", 0)
    ;  *Object\File_ID = CreateFile(#PB_Any, *Object\Filename, #PB_File_SharedWrite | #PB_File_SharedRead)
    ;EndIf
    
    FileSeek(*Object\File_ID, Position)
    If WriteData(*Object\File_ID, *Data, Size)
      
      Object_Event\Type = Node::#Link_Event_Update
      Object_Event\Position = Position
      Object_Event\Size = Size
      Node::Output_Event(FirstElement(*Node\Output()), Object_Event)
      
      ProcedureReturn #True
    Else
      Logger::Entry_Add_Error("Couldn't write data to the file", "The file is probably in read only mode.")
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Shift(*Node_Output.Node::Conn_Output, Position.q, Offset.q)
    Protected i
    Protected Temp_Position.q, Temp_Read_Position.q, Temp_Offset.q
    Protected File_Size.q
    Protected *Temp_Memory, Temp_Memory_Size.i
    Protected Object_Event.Node::Event
    Protected Successful
    ;Protected Memory_Operation.Memory_Operation
    
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
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
    
    If Not *Object\File_ID
      Logger::Entry_Add_Error("There is no file opened", "There is no file opened. Couldn't write.")
      ProcedureReturn #False
    EndIf
    
    File_Size = Lof(*Object\File_ID)
    
    If Position > File_Size
      ProcedureReturn #False
    EndIf
    
    If Offset = 0
      ProcedureReturn #True
    EndIf
    
    If Not *Object\Mode = #Mode_Write
      Logger::Entry_Add_Error("Couldn't shift the file", "The file is in read only mode.")
      ProcedureReturn #False
    EndIf
    
    Temp_Offset = Offset
    
    If Temp_Offset < Position - File_Size
      Temp_Offset = Position - File_Size
    EndIf
    
    Temp_Memory_Size = File_Size - Position
    If Temp_Memory_Size > File_Size - Position + Temp_Offset
      Temp_Memory_Size = File_Size - Position + Temp_Offset
    EndIf
    If Temp_Memory_Size > 0
      *Temp_Memory = AllocateMemory(Temp_Memory_Size)
    EndIf
    
    If *Temp_Memory
      Temp_Read_Position = File_Size - Temp_Memory_Size
      FileSeek(*Object\File_ID, Temp_Read_Position)
      ReadData(*Object\File_ID, *Temp_Memory, Temp_Memory_Size)
    EndIf
    
    Successful = #True
    
    FileSeek(*Object\File_ID, Position)
    If Temp_Offset > 0
      For i = 1 To Temp_Offset
        If Not WriteAsciiCharacter(*Object\File_ID, 0)
          Successful = #False
          Break
        EndIf
      Next
    EndIf
    If *Temp_Memory
      If Not WriteData(*Object\File_ID, *Temp_Memory, Temp_Memory_Size)
        Successful = #False
      EndIf
    EndIf
    
    If *Temp_Memory
      FreeMemory(*Temp_Memory) : *Temp_Memory = #Null
    EndIf
    
    If Temp_Offset < 0
      FileSeek(*Object\File_ID, File_Size + Temp_Offset)
      If Not TruncateFile(*Object\File_ID)
        Successful = #False
      EndIf
    EndIf
    
    If Successful
      Object_Event\Type = Node::#Link_Event_Update
      Object_Event\Position = Position
      Object_Event\Size = File_Size - Position + Temp_Offset
      Node::Output_Event(FirstElement(*Node\Output()), Object_Event)
    Else
      Logger::Entry_Add_Error("Couldn't shift the file", "The file is probably in read only mode.")
    EndIf
    
    ProcedureReturn Successful
  EndProcedure
  
  Procedure Set_Data_Check(*Node_Output.Node::Conn_Output, Position.q, Size.i)
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Mode = #Mode_Write And *Object\File_ID
      Logger::Entry_Add_Error("Couldn't write to the file", "The file is in read only mode.")
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Shift_Check(*Node_Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Node_Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Node_Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Mode = #Mode_Write And *Object\File_ID
      Logger::Entry_Add_Error("Couldn't shift the file", "The file is in read only mode.")
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
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
    
    If Event_Type = #PB_EventType_LostFocus
      *Object\Filename = GetGadgetText(*Object\Editor)
      
      ; #### Reopen File if one is opened
      If *Object\File_ID
        File_Open(*Node)
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_Button_File()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Filename.s
    
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
    
    Filename = SaveFileRequester("Select File", *Object\Filename, "", 1)
    If Filename
      *Object\Filename = Filename
    EndIf
    
    SetGadgetText(*Object\Editor, *Object\Filename)
    
    ; #### Reopen File if one is opened
    If *Object\File_ID
      File_Open(*Node)
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_Button_Create()
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
    
    File_Create(*Node)
    
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
      File_Open(*Node)
    Else
      File_Close(*Node)
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
      Case *Object\Option[0] : *Object\Mode = #Mode_Read
      Case *Object\Option[1] : *Object\Mode = #Mode_Write
    EndSelect
    
    ; #### Reopen File if one is opened
    If *Object\File_ID
      File_Open(*Node)
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
    
    Select Event_Gadget
      Case *Object\CheckBox[0] : *Object\Shared_Read = GetGadgetState(*Object\CheckBox[0])
      Case *Object\CheckBox[1] : *Object\Shared_Write = GetGadgetState(*Object\CheckBox[1])
      Case *Object\CheckBox[2] : *Object\Cached = GetGadgetState(*Object\CheckBox[2])
    EndSelect
    
    ; #### Reopen File if one is opened
    If *Object\File_ID
      File_Open(*Node)
    EndIf
    
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
    
    ;*Object\Redraw = #True
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
    
    
    ;*Object\Redraw = #True
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
      
      Width = 500
      Height = 130
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Toolbar
      
      ; #### Gadgets
      *Object\Editor = EditorGadget(#PB_Any, 10, 10, Width-70, 40)
      *Object\Button_File = ButtonImageGadget(#PB_Any, Width-50, 10, 40, 40, 0)
      *Object\Option[0] = OptionGadget(#PB_Any, 10, 60, 100, 20, "Read")
      *Object\Option[1] = OptionGadget(#PB_Any, 10, 80, 100, 20, "Write")
      *Object\CheckBox[0] = CheckBoxGadget(#PB_Any, 110, 60, 100, 20, "Shared Read")
      *Object\CheckBox[1] = CheckBoxGadget(#PB_Any, 110, 80, 100, 20, "Shared Write")
      *Object\CheckBox[2] = CheckBoxGadget(#PB_Any, 110, 100, 100, 20, "Cached")
      *Object\Button_Create = ButtonGadget(#PB_Any, Width-200, Height-40, 90, 30, "Create")
      *Object\Button_Open = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "Open", #PB_Button_Toggle)
      
      SendMessage_(GadgetID(*Object\Editor),#EM_SETTARGETDEVICE,#Null,0) ; automatic word wrap
      SetGadgetText(*Object\Editor, *Object\Filename)
      
      Select *Object\Mode
        Case #Mode_Read   : SetGadgetState(*Object\Option[0], #True)
        Case #Mode_Write  : SetGadgetState(*Object\Option[1], #True)
      EndSelect
      
      If *Object\Shared_Read
        SetGadgetState(*Object\CheckBox[0], #True)
      Else
        SetGadgetState(*Object\CheckBox[0], #False)
      EndIf
      
      If *Object\Shared_Write
        SetGadgetState(*Object\CheckBox[1], #True)
      Else
        SetGadgetState(*Object\CheckBox[1], #False)
      EndIf
      
      If *Object\Cached
        SetGadgetState(*Object\CheckBox[2], #True)
      Else
        SetGadgetState(*Object\CheckBox[2], #False)
      EndIf
      
      If *Object\File_ID
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\Editor, @Window_Event_String())
      BindGadgetEvent(*Object\Button_File, @Window_Event_Button_File())
      BindGadgetEvent(*Object\Button_Create, @Window_Event_Button_Create())
      BindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      BindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      BindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[2], @Window_Event_CheckBox())
    
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
      ;UnbindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;UnbindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      UnbindGadgetEvent(*Object\Editor, @Window_Event_String())
      UnbindGadgetEvent(*Object\Button_File, @Window_Event_Button_File())
      UnbindGadgetEvent(*Object\Button_Create, @Window_Event_Button_Create())
      UnbindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      UnbindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      UnbindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[2], @Window_Event_CheckBox())
      
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
    Main\Node_Type\Category = "Data-Source"
    Main\Node_Type\Name = "File"
    Main\Node_Type\UID = "D3__FILE"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,01,14,12,00,00)
    Main\Node_Type\Date_Modification = Date(2014,03,02,13,51,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "File object."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 1000
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 476
; FirstLine = 449
; Folding = -----
; EnableUnicode
; EnableXP