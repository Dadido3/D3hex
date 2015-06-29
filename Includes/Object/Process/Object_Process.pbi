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

; ##################################################### Structures ##################################################

Structure Object_Process_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Process_Main.Object_Process_Main

Structure Object_Process
  *Window.Window
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

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   Object_Process_Main(*Object.Object)
Declare   _Object_Process_Delete(*Object.Object)
Declare   Object_Process_Window_Open(*Object.Object)

Declare   Object_Process_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
Declare   Object_Process_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)

Declare   Object_Process_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare   Object_Process_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare   Object_Process_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Process_Get_Size(*Object_Output.Object_Output)
Declare   Object_Process_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Process_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Process_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Process_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Process_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Process_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Process_Open(*Object.Object)
  Protected Flags
  Protected Object_Event.Object_Event
  Protected Object_Event_Descriptor.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\hProcess
    CloseHandle_(*Object_Process\hProcess)
  EndIf
  
  *Object_Process\hProcess = OpenProcess_(#MAXIMUM_ALLOWED, #False, *Object_Process\PID)
  
  ; #### Send event for the updated descriptor
  Object_Event_Descriptor\Type = #Object_Link_Event_Update_Descriptor
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event_Descriptor)
  
  If *Object_Process\hProcess
    ; #### Send event to update the data
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = Object_Process_Get_Size(FirstElement(*Object\Output()))
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  Else
    Logger::Entry_Add_Error("Couldn't open Process", "PID="+*Object_Process\PID+" couldn't be opened.")
    ; #### Send event to update the data
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = 0
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  EndIf
  
  If *Object_Process\Window
    If *Object_Process\hProcess
      SetGadgetText(*Object_Process\Button_Open, "Close")
      SetGadgetState(*Object_Process\Button_Open, #True)
    Else
      SetGadgetText(*Object_Process\Button_Open, "Open")
      SetGadgetState(*Object_Process\Button_Open, #False)
    EndIf
  EndIf
  
  *Object_Process\Update_Disable = #True
  
EndProcedure

Procedure Object_Process_Close(*Object.Object)
  Protected Object_Event.Object_Event
  Protected Object_Event_Descriptor.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\hProcess
    CloseHandle_(*Object_Process\hProcess)
    *Object_Process\hProcess = #Null
  EndIf
  
  ; #### Send event for the updated descriptor
  Object_Event_Descriptor\Type = #Object_Link_Event_Update_Descriptor
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event_Descriptor)
  
  ; #### Send event to update the data
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = 0
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  If *Object_Process\Window
    If *Object_Process\hProcess
      SetGadgetText(*Object_Process\Button_Open, "Close")
      SetGadgetState(*Object_Process\Button_Open, #True)
    Else
      SetGadgetText(*Object_Process\Button_Open, "Open")
      SetGadgetState(*Object_Process\Button_Open, #False)
    EndIf
  EndIf
  
  *Object_Process\Update_Disable = #True
  
EndProcedure

Procedure Object_Process_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Process.Object_Process
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Process_Main\Object_Type
  *Object\Type_Base = Object_Process_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Process_Delete()
  *Object\Function_Main = @Object_Process_Main()
  *Object\Function_Window = @Object_Process_Window_Open()
  *Object\Function_Configuration_Get = @Object_Process_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Process_Configuration_Set()
  
  *Object\Name = Object_Process_Main\Object_Type\Name
  *Object\Name_Inherited = *Object\Name
  *Object\Color = RGBA(100,100,255,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Process)
  *Object_Process = *Object\Custom_Data
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Event = @Object_Process_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Process_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Process_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Process_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Process_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Process_Set_Data()
  *Object_Output\Function_Convolute = @Object_Process_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Process_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Process_Convolute_Check()
  
  If Requester
    Object_Process_Window_Open(*Object)
  EndIf
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Process_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\hProcess
    CloseHandle_(*Object_Process\hProcess)
    *Object_Process\hProcess = #Null
  EndIf
  
  Object_Process_Window_Close(*Object)
  
  FreeStructure(*Object_Process)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Configuration_Get(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Cached", #NBT_Tag_Byte)        : NBT_Tag_Set_Number(*NBT_Tag, *Object_Process\Cached)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Configuration_Set(*Object.Object, *Parent_Tag.NBT::Tag)
  Protected *NBT_Tag.NBT::Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag(*Parent_Tag, "Cached")       : *Object_Process\Cached = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  Protected MBI.MEMORY_BASIC_INFORMATION
  Protected Position.q
  
  While VirtualQueryEx_(*Object_Process\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
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

Procedure Object_Process_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #Null
  EndIf
  
  If *Object_Process\hProcess
    NBT::Tag_Set_String(NBT::Tag_Add(*Object_Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Process: "+*Object_Process\Process_Name)
    NBT::Tag_Set_String(NBT::Tag_Add(*Object_Output\Descriptor\Tag, "Type", NBT::#Tag_String), "Process")
    NBT::Tag_Set_Number(NBT::Tag_Add(*Object_Output\Descriptor\Tag, "Process_Handle", NBT::#Tag_Quad), *Object_Process\hProcess)
    ProcedureReturn *Object_Output\Descriptor
  Else
    ; #### Delete all tags
    While NBT::Tag_Delete(NBT::Tag_Index(*Object_Output\Descriptor\Tag, 0))
    Wend
    NBT::Error_Get()
  EndIf
  
  ProcedureReturn #Null
EndProcedure

Procedure.q Object_Process_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn -1
  EndIf
  
  If Not *Object_Process\hProcess
    ProcedureReturn -1
  EndIf
  
  Protected MBI.MEMORY_BASIC_INFORMATION
  Protected Position.q, Temp_Size.q, Last_BaseAdress.q
  
  While VirtualQueryEx_(*Object_Process\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
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

Procedure Object_Process_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Process\hProcess
    ;Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't read.")
    ProcedureReturn #False
  EndIf
  
  Protected MBI.MEMORY_BASIC_INFORMATION
  Protected Temp_Size.q
  
  While VirtualQueryEx_(*Object_Process\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
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
          If Not ReadProcessMemory_(*Object_Process\hProcess, Position, *Data, Temp_Size, 0)
            If *Metadata
              FillMemory(*Metadata, Temp_Size)
            EndIf
          EndIf
        Case #MEM_COMMIT
          If Not ReadProcessMemory_(*Object_Process\hProcess, Position, *Data, Temp_Size, 0)
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

Procedure Object_Process_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
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
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Process\hProcess
    Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't write.")
    ProcedureReturn #False
  EndIf
  
  Protected MBI.MEMORY_BASIC_INFORMATION
  Protected Object_Event.Object_Event
  Protected Temp_Size.q
  Protected Result = #True
  
  While VirtualQueryEx_(*Object_Process\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
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
        If Not WriteProcessMemory_(*Object_Process\hProcess, Position, *Data, Temp_Size, 0)
          Result = #False
        EndIf
      Case #MEM_COMMIT
        If Not WriteProcessMemory_(*Object_Process\hProcess, Position, *Data, Temp_Size, 0)
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
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = Position
  Object_Event\Size = Size
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  If Size = 0 And Result = #True
    ProcedureReturn #True
  Else
    Logger::Entry_Add_Error("Couldn't write all data to the Process", "Wasn't able to write all the data, at least one page you are writing to isn't accessible.")
    ProcedureReturn Result
  EndIf
EndProcedure

Procedure Object_Process_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
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
  
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  ; #### Convolution isn't available
  Logger::Entry_Add_Error("Convolution not available", "It's not possible to convolute process memory.")
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Process_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Process\hProcess
    Logger::Entry_Add_Error("There is no Process opened", "There is no Process opened. Couldn't write.")
    ProcedureReturn #False
  EndIf
  
  Protected MBI.MEMORY_BASIC_INFORMATION
  Protected Temp_Size.q
  Protected Result = #True
  
  While VirtualQueryEx_(*Object_Process\hProcess, Position, MBI, SizeOf(MEMORY_BASIC_INFORMATION))
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

Procedure Object_Process_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  ; #### Convolution isn't available
  Logger::Entry_Add_Error("Convolution not available", "It's not possible to convolute process memory.")
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Process_Window_Update(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  Protected Process.PROCESSENTRY32\dwSize = SizeOf(PROCESSENTRY32)
  Protected Snapshot.i
  Protected Found
  Protected i
  
  ClearGadgetItems(*Object_Process\ListIcon)
  
  Snapshot = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  If Snapshot
    Found = Process32First_(Snapshot, Process)
    i = 0
    While Found
      AddGadgetItem(*Object_Process\ListIcon, i, Str(Process\th32ProcessID))
      SetGadgetItemText(*Object_Process\ListIcon, i, PeekS(@Process\szExeFile), 1)
      SetGadgetItemData(*Object_Process\ListIcon, i, Process\th32ProcessID)
      If *Object_Process\PID = Process\th32ProcessID
        SetGadgetState(*Object_Process\ListIcon, i)
      EndIf
      i + 1
      Found = Process32Next_(Snapshot, Process)
    Wend
    CloseHandle_(Snapshot)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Window_Update_Disable(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\hProcess
    DisableGadget(*Object_Process\ListIcon, #True)
  Else
    DisableGadget(*Object_Process\ListIcon, #False)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Process_Window_Event_ListIcon()
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(*Object_Process\ListIcon) >= 0
    *Object_Process\PID = GetGadgetItemData(*Object_Process\ListIcon, GetGadgetState(*Object_Process\ListIcon))
    *Object_Process\Process_Name = GetGadgetItemText(*Object_Process\ListIcon, GetGadgetState(*Object_Process\ListIcon), 1)
  EndIf
  
  If Event_Type = #PB_EventType_LeftDoubleClick
    Object_Process_Open(*Object)
  EndIf
  
EndProcedure

Procedure Object_Process_Window_Event_Button_Open()
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(Event_Gadget)
    Object_Process_Open(*Object)
  Else
    Object_Process_Close(*Object)
  EndIf
  
  *Object_Process\Update_Disable = #True
  
EndProcedure

Procedure Object_Process_Window_Event_Button_Refresh()
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn 
  EndIf
  
  *Object_Process\Update = #True
  
EndProcedure

Procedure Object_Process_Window_Event_SizeWindow()
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn 
  EndIf
  
  ;ResizeGadget(*Object_Process\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ;ResizeGadget(*Object_Process\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
  ;*Object_Process\Redraw = #True
EndProcedure

Procedure Object_Process_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Process_Window_Event_CloseWindow()
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
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn 
  EndIf
  
  ;Object_Process_Window_Close(*Object)
  *Object_Process\Window_Close = #True
EndProcedure

Procedure Object_Process_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Process\Window
    
    Width = 400
    Height = 400
    
    *Object_Process\Window = Window_Create(*Object, *Object\Name_Inherited, *Object\Name, #False, 0, 0, Width, Height, #False)
    
    ; #### Toolbar
    
    ; #### Gadgets
    *Object_Process\ListIcon = ListIconGadget(#PB_Any, 0, 0, Width, Height-50, "ID", 50, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(*Object_Process\ListIcon, 1, "Name", 300)
    *Object_Process\Button_Open = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "", #PB_Button_Toggle)
    *Object_Process\Button_Refresh = ButtonGadget(#PB_Any, 10, Height-40, 90, 30, "Refresh")
    
    If *Object_Process\hProcess
      SetGadgetText(*Object_Process\Button_Open, "Close")
      SetGadgetState(*Object_Process\Button_Open, #True)
    Else
      SetGadgetText(*Object_Process\Button_Open, "Open")
      SetGadgetState(*Object_Process\Button_Open, #False)
    EndIf
    
    *Object_Process\Update = #True
    *Object_Process\Update_Disable = #True
    
    BindEvent(#PB_Event_SizeWindow, @Object_Process_Window_Event_SizeWindow(), *Object_Process\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Process_Window_Event_Menu(), *Object_Process\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Process_Window_Event_CloseWindow(), *Object_Process\Window\ID)
    
    BindGadgetEvent(*Object_Process\ListIcon, @Object_Process_Window_Event_ListIcon())
    BindGadgetEvent(*Object_Process\Button_Open, @Object_Process_Window_Event_Button_Open())
    BindGadgetEvent(*Object_Process\Button_Refresh, @Object_Process_Window_Event_Button_Refresh())
  
  Else
    Window_Set_Active(*Object_Process\Window)
  EndIf
EndProcedure

Procedure Object_Process_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Process_Window_Event_SizeWindow(), *Object_Process\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Process_Window_Event_Menu(), *Object_Process\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Process_Window_Event_CloseWindow(), *Object_Process\Window\ID)
    
    UnbindGadgetEvent(*Object_Process\ListIcon, @Object_Process_Window_Event_ListIcon())
    UnbindGadgetEvent(*Object_Process\Button_Open, @Object_Process_Window_Event_Button_Open())
    UnbindGadgetEvent(*Object_Process\Button_Refresh, @Object_Process_Window_Event_Button_Refresh())
    
    Window_Delete(*Object_Process\Window)
    *Object_Process\Window = #Null
  EndIf
EndProcedure

Procedure Object_Process_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Process.Object_Process = *Object\Custom_Data
  If Not *Object_Process
    ProcedureReturn #False
  EndIf
  
  If *Object_Process\Window
    If *Object_Process\Update
      *Object_Process\Update = #False
      Object_Process_Window_Update(*Object)
    EndIf
    
    If *Object_Process\Update_Disable
      *Object_Process\Update_Disable = #False
      Object_Process_Window_Update_Disable(*Object)
    EndIf
  EndIf
  
  If *Object_Process\Window_Close
    *Object_Process\Window_Close = #False
    Object_Process_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Process_Main\Object_Type = Object_Type_Create()
If Object_Process_Main\Object_Type
  Object_Process_Main\Object_Type\Category = "Data-Source"
  Object_Process_Main\Object_Type\Name = "Process"
  Object_Process_Main\Object_Type\UID = "D3__PROC"
  Object_Process_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Process_Main\Object_Type\Date_Creation = Date(2014,02,25,22,54,00)
  Object_Process_Main\Object_Type\Date_Modification = Date(2014,02,25,22,54,00)
  Object_Process_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Process_Main\Object_Type\Description = "Provides access to the virtual memory of a process."
  Object_Process_Main\Object_Type\Function_Create = @Object_Process_Create()
  Object_Process_Main\Object_Type\Version = 900
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 375
; FirstLine = 349
; Folding = -----
; EnableUnicode
; EnableXP