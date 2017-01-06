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

DeclareModule _Node_Process
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Process
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Includes ####################################################
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    ListIcon.i
    Button_Open.i
    Button_Refresh.i
    
    Update.l
    Update_Disable.l
    
    ; #### Process stuff
    PID.i
    Process_Name.s
    hProcess.i
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
  
  Procedure Open(*Node.Node::Object)
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
    
    If *Object\hProcess
      CloseHandle_(*Object\hProcess)
    EndIf
    
    *Object\hProcess = OpenProcess_(#MAXIMUM_ALLOWED, #False, *Object\PID)
    
    ; #### Send event for the updated descriptor
    Event_Descriptor\Type = Node::#Link_Event_Update_Descriptor
    Node::Output_Event(FirstElement(*Node\Output()), Event_Descriptor)
    
    If *Object\hProcess
      ; #### Send event to update the data
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = Get_Size(FirstElement(*Node\Output()))
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    Else
      Logger::Entry_Add_Error("Couldn't open Process", "PID="+*Object\PID+" couldn't be opened.")
      ; #### Send event to update the data
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = 0
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    EndIf
    
    If *Object\Window
      If *Object\hProcess
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
    
    *Object\Update_Disable = #True
    
  EndProcedure
  
  Procedure Close(*Node.Node::Object)
    Protected Event.Node::Event
    Protected Event_Descriptor.Node::Event
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\hProcess
      CloseHandle_(*Object\hProcess)
      *Object\hProcess = #Null
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
      If *Object\hProcess
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
    EndIf
    
    *Object\Update_Disable = #True
    
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
    *Node\Color = RGBA(100,100,255,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
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
    
    If *Object\hProcess
      CloseHandle_(*Object\hProcess)
      *Object\hProcess = #Null
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
    
    ;*NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Cached", #NBT_Tag_Byte)        : NBT_Tag_Set_Number(*NBT_Tag, *Object\Cached)
    
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
    
    ;*NBT_Tag = NBT_Tag(*Parent_Tag, "Cached")       : *Object\Cached = NBT_Tag_Get_Number(*NBT_Tag)
    
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
    
    Protected MBI.MEMORY_BASIC_INFORMATION
    Protected Position.q
    
    While VirtualQueryEx_(*Object\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
      If LastElement(Segment()) And Segment()\Position >= MBI\BaseAddress
        Break
      EndIf
      AddElement(Segment())
      Segment()\Position = MBI\BaseAddress
      Segment()\Size = MBI\RegionSize
      Select MBI\Protect & $FF
        Case #PAGE_NOACCESS           : Segment()\Metadata = #Metadata_NoError
        Case #PAGE_READONLY           : Segment()\Metadata = #Metadata_NoError |                        #Metadata_Readable
        Case #PAGE_READWRITE          : Segment()\Metadata = #Metadata_NoError |                        #Metadata_Readable | #Metadata_Writeable
        Case #PAGE_WRITECOPY          : Segment()\Metadata = #Metadata_NoError |                        #Metadata_Readable | #Metadata_Writeable
        Case #PAGE_EXECUTE            : Segment()\Metadata = #Metadata_NoError | #Metadata_Executable
        Case #PAGE_EXECUTE_READ       : Segment()\Metadata = #Metadata_NoError | #Metadata_Executable | #Metadata_Readable
        Case #PAGE_EXECUTE_READWRITE  : Segment()\Metadata = #Metadata_NoError | #Metadata_Executable | #Metadata_Readable | #Metadata_Writeable
        Case #PAGE_EXECUTE_WRITECOPY  : Segment()\Metadata = #Metadata_NoError | #Metadata_Executable | #Metadata_Readable | #Metadata_Writeable
      EndSelect
      ;Segment()\Type_State = MBI\Type | MBI\State
      Position + MBI\RegionSize
    Wend
    
    ProcedureReturn #True
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
    
    If *Object\hProcess
      NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Process: "+*Object\Process_Name)
      NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Type", NBT::#Tag_String), "Process")
      NBT::Tag_Set_Number(NBT::Tag_Add(*Output\Descriptor\Tag, "Process_Handle", NBT::#Tag_Quad), *Object\hProcess)
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
    
    If Not *Object\hProcess
      ProcedureReturn -1
    EndIf
    
    Protected MBI.MEMORY_BASIC_INFORMATION
    Protected Position.q, Temp_Size.q, Last_BaseAdress.q
    
    While VirtualQueryEx_(*Object\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
      If Last_BaseAdress > MBI\BaseAddress
        Break
      EndIf
      Select MBI\State
        Case #MEM_RESERVE, #MEM_COMMIT
          Temp_Size = MBI\BaseAddress + MBI\RegionSize
      EndSelect
      Position = MBI\BaseAddress + MBI\RegionSize
      Last_BaseAdress = MBI\BaseAddress
    Wend
    
    ProcedureReturn Temp_Size
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
    
    If Not *Object\hProcess
      ;Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't read.")
      ProcedureReturn #False
    EndIf
    
    Protected MBI.MEMORY_BASIC_INFORMATION
    Protected Temp_Size.q
    
    While VirtualQueryEx_(*Object\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
      Temp_Size = Size
      If Temp_Size >= MBI\BaseAddress + MBI\RegionSize - Position : Temp_Size = MBI\BaseAddress + MBI\RegionSize - Position : EndIf
      
      If *Metadata
        Select MBI\Protect & $FF
          Case #PAGE_NOACCESS           : FillMemory(*Metadata, Temp_Size, #Metadata_NoError)
          Case #PAGE_READONLY           : FillMemory(*Metadata, Temp_Size, #Metadata_NoError |                        #Metadata_Readable)
          Case #PAGE_READWRITE          : FillMemory(*Metadata, Temp_Size, #Metadata_NoError |                        #Metadata_Readable | #Metadata_Writeable)
          Case #PAGE_WRITECOPY          : FillMemory(*Metadata, Temp_Size, #Metadata_NoError |                        #Metadata_Readable | #Metadata_Writeable)
          Case #PAGE_EXECUTE            : FillMemory(*Metadata, Temp_Size, #Metadata_NoError | #Metadata_Executable)
          Case #PAGE_EXECUTE_READ       : FillMemory(*Metadata, Temp_Size, #Metadata_NoError | #Metadata_Executable | #Metadata_Readable)
          Case #PAGE_EXECUTE_READWRITE  : FillMemory(*Metadata, Temp_Size, #Metadata_NoError | #Metadata_Executable | #Metadata_Readable | #Metadata_Writeable)
          Case #PAGE_EXECUTE_WRITECOPY  : FillMemory(*Metadata, Temp_Size, #Metadata_NoError | #Metadata_Executable | #Metadata_Readable | #Metadata_Writeable)
        EndSelect
      EndIf
      
      If *Data
        Select MBI\State
          Case #MEM_FREE
            
          Case #MEM_RESERVE
            If Not ReadProcessMemory_(*Object\hProcess, Position, *Data, Temp_Size, 0)
              If *Metadata
                FillMemory(*Metadata, Temp_Size)
              EndIf
            EndIf
          Case #MEM_COMMIT
            If Not ReadProcessMemory_(*Object\hProcess, Position, *Data, Temp_Size, 0)
              If *Metadata
                FillMemory(*Metadata, Temp_Size)
              EndIf
            EndIf
        EndSelect
      EndIf
      
      Size - Temp_Size
      If Size > 0
        Position + Temp_Size
        If *Data
          *Data + Temp_Size
        EndIf
        If *Metadata
          *Metadata + Temp_Size
        EndIf
      Else
        Break
      EndIf
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
    
    If Not *Object\hProcess
      Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't write.")
      ProcedureReturn #False
    EndIf
    
    Protected MBI.MEMORY_BASIC_INFORMATION
    Protected Event.Node::Event
    Protected Temp_Size.q
    Protected Result = #True
    
    While VirtualQueryEx_(*Object\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
      Temp_Size = Size
      If Temp_Size >= MBI\BaseAddress + MBI\RegionSize - Position : Temp_Size = MBI\BaseAddress + MBI\RegionSize - Position : EndIf
      
      Select MBI\Protect & $FF
        Case #PAGE_NOACCESS           : Result = #False
        Case #PAGE_READONLY           : Result = #False
        Case #PAGE_READWRITE          : 
        Case #PAGE_WRITECOPY          : 
        Case #PAGE_EXECUTE            : Result = #False
        Case #PAGE_EXECUTE_READ       : Result = #False
        Case #PAGE_EXECUTE_READWRITE  : 
        Case #PAGE_EXECUTE_WRITECOPY  : 
      EndSelect
      
      Select MBI\State
        Case #MEM_FREE
          Result = #False
        Case #MEM_RESERVE
          If Not WriteProcessMemory_(*Object\hProcess, Position, *Data, Temp_Size, 0)
            Result = #False
          EndIf
        Case #MEM_COMMIT
          If Not WriteProcessMemory_(*Object\hProcess, Position, *Data, Temp_Size, 0)
            Result = #False
          EndIf
      EndSelect
      
      Size - Temp_Size
      If Size > 0
        Position + Temp_Size
        *Data + Temp_Size
      Else
        Break
      EndIf
    Wend
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = Position
    Event\Size = Size
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    If Size = 0 And Result = #True
      ProcedureReturn #True
    Else
      Logger::Entry_Add_Error("Couldn't write all data to the Process", "Wasn't able to write all the data, at least one page you are writing to isn't accessible.")
      ProcedureReturn Result
    EndIf
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
    
    ; #### Shifting isn't available
    Logger::Entry_Add_Error("Shifting is not available", "It's not possible to shift process memory.")
    
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
    
    If Not *Object\hProcess
      Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't write.")
      ProcedureReturn #False
    EndIf
    
    Protected MBI.MEMORY_BASIC_INFORMATION
    Protected Temp_Size.q
    Protected Result = #True
    
    While VirtualQueryEx_(*Object\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
      Temp_Size = Size
      If Temp_Size >= MBI\BaseAddress + MBI\RegionSize - Position : Temp_Size = MBI\BaseAddress + MBI\RegionSize - Position : EndIf
      
      Select MBI\Protect & $FF
        Case #PAGE_NOACCESS           : Result = #False
        Case #PAGE_READONLY           : Result = #False
        Case #PAGE_READWRITE          : 
        Case #PAGE_WRITECOPY          : 
        Case #PAGE_EXECUTE            : Result = #False
        Case #PAGE_EXECUTE_READ       : Result = #False
        Case #PAGE_EXECUTE_READWRITE  : 
        Case #PAGE_EXECUTE_WRITECOPY  : 
      EndSelect
      
      Size - Temp_Size
      If Size > 0
        Position + Temp_Size
      Else
        Break
      EndIf
    Wend
    
    If Size = 0 And Result = #True
      ProcedureReturn #True
    Else
      Logger::Entry_Add_Error("Can't write data here", "It's not possible to write all the data, at least one page you are writing to isn't accessible.")
      ProcedureReturn Result
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
    
    ; #### Shifting isn't available
    Logger::Entry_Add_Error("Shifting is not available", "It's not possible to shift process memory.")
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Window_Update(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Process.PROCESSENTRY32\dwSize = SizeOf(PROCESSENTRY32)
    Protected Snapshot.i
    Protected Found
    Protected i
    
    ClearGadgetItems(*Object\ListIcon)
    
    Snapshot = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
    If Snapshot
      Found = Process32First_(Snapshot, Process)
      i = 0
      While Found
        AddGadgetItem(*Object\ListIcon, i, Str(Process\th32ProcessID))
        SetGadgetItemText(*Object\ListIcon, i, PeekS(@Process\szExeFile), 1)
        SetGadgetItemData(*Object\ListIcon, i, Process\th32ProcessID)
        If *Object\PID = Process\th32ProcessID
          SetGadgetState(*Object\ListIcon, i)
        EndIf
        i + 1
        Found = Process32Next_(Snapshot, Process)
      Wend
      CloseHandle_(Snapshot)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Update_Disable(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\hProcess
      DisableGadget(*Object\ListIcon, #True)
    Else
      DisableGadget(*Object\ListIcon, #False)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Event_ListIcon()
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
    
    If GetGadgetState(*Object\ListIcon) >= 0
      *Object\PID = GetGadgetItemData(*Object\ListIcon, GetGadgetState(*Object\ListIcon))
      *Object\Process_Name = GetGadgetItemText(*Object\ListIcon, GetGadgetState(*Object\ListIcon), 1)
    EndIf
    
    If Event_Type = #PB_EventType_LeftDoubleClick
      Open(*Node)
    EndIf
    
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
      Open(*Node)
    Else
      Close(*Node)
    EndIf
    
    *Object\Update_Disable = #True
    
  EndProcedure
  
  Procedure Window_Event_Button_Refresh()
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
    
    *Object\Update = #True
    
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
      
      Width = 400
      Height = 400
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Toolbar
      
      ; #### Gadgets
      *Object\ListIcon = ListIconGadget(#PB_Any, 0, 0, Width, Height-50, "ID", 50, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
      AddGadgetColumn(*Object\ListIcon, 1, "Name", 300)
      *Object\Button_Open = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "", #PB_Button_Toggle)
      *Object\Button_Refresh = ButtonGadget(#PB_Any, 10, Height-40, 90, 30, "Refresh")
      
      If *Object\hProcess
        SetGadgetText(*Object\Button_Open, "Close")
        SetGadgetState(*Object\Button_Open, #True)
      Else
        SetGadgetText(*Object\Button_Open, "Open")
        SetGadgetState(*Object\Button_Open, #False)
      EndIf
      
      *Object\Update = #True
      *Object\Update_Disable = #True
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      BindGadgetEvent(*Object\ListIcon, @Window_Event_ListIcon())
      BindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      BindGadgetEvent(*Object\Button_Refresh, @Window_Event_Button_Refresh())
    
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
      
      UnbindGadgetEvent(*Object\ListIcon, @Window_Event_ListIcon())
      UnbindGadgetEvent(*Object\Button_Open, @Window_Event_Button_Open())
      UnbindGadgetEvent(*Object\Button_Refresh, @Window_Event_Button_Refresh())
      
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
      
      If *Object\Update_Disable
        *Object\Update_Disable = #False
        Window_Update_Disable(*Node)
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
    Main\Node_Type\Category = "Data-Source"
    Main\Node_Type\Name = "Process"
    Main\Node_Type\UID = "D3__PROC"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,02,25,22,54,00)
    Main\Node_Type\Date_Modification = Date(2014,02,25,22,54,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Provides access to the virtual memory of a process."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 900
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 826
; FirstLine = 821
; Folding = -----
; EnableUnicode
; EnableXP