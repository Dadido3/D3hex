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

Enumeration
  #Object_File_Mode_Read
  #Object_File_Mode_Write
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_File_Main
  *Object_Type.Object_Type
EndStructure
Global Object_File_Main.Object_File_Main

Structure Object_File
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Editor.i
  Option.i [10]
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

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   Object_File_Main(*Object.Object)
Declare   _Object_File_Delete(*Object.Object)
Declare   Object_File_Window_Open(*Object.Object)

Declare   Object_File_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_File_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_File_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare.s Object_File_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_File_Get_Size(*Object_Output.Object_Output)
Declare   Object_File_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_File_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_File_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_File_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_File_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_File_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_File_HDD_Create(*Object.Object) ; #### That function doesn't create a file-object. It creates a file
  Protected Flags
  Protected Object_Event.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\File_ID
    CloseFile(*Object_File\File_ID)
    *Object_File\File_ID = 0
  EndIf
  
  If Not *Object_File\Cached
    Flags | #PB_File_NoBuffering
  EndIf
  If *Object_File\Shared_Read
    Flags | #PB_File_SharedRead
  EndIf
  If *Object_File\Shared_Write
    Flags | #PB_File_SharedWrite
  EndIf
  
  *Object_File\File_ID = CreateFile(#PB_Any, *Object_File\Filename, Flags) : *Object_File\Mode = #Object_File_Mode_Write
  
  If *Object_File\File_ID
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = Lof(*Object_File\File_ID)
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  Else
    Logging_Entry_Add_Error("Couldn't create file", "'"+*Object_File\Filename+"' couldn't be created. The file object now behaves like a new file.")
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = 0
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  EndIf
  
  If *Object_File\Window
    If *Object_File\File_ID
      SetGadgetText(*Object_File\Button_Open, "Close")
      SetGadgetState(*Object_File\Button_Open, #True)
    Else
      SetGadgetText(*Object_File\Button_Open, "Open")
      SetGadgetState(*Object_File\Button_Open, #False)
    EndIf
  EndIf
EndProcedure

Procedure Object_File_HDD_Open(*Object.Object)
  Protected Flags
  Protected Object_Event.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\File_ID
    CloseFile(*Object_File\File_ID)
    *Object_File\File_ID = 0
  EndIf
  
  If Not *Object_File\Cached
    Flags | #PB_File_NoBuffering
  EndIf
  If *Object_File\Shared_Read
    Flags | #PB_File_SharedRead
  EndIf
  If *Object_File\Shared_Write
    Flags | #PB_File_SharedWrite
  EndIf
  
  Select *Object_File\Mode
    Case #Object_File_Mode_Read   : *Object_File\File_ID = ReadFile(#PB_Any, *Object_File\Filename, Flags)
    Case #Object_File_Mode_Write  : *Object_File\File_ID = OpenFile(#PB_Any, *Object_File\Filename, Flags)
  EndSelect
  
  If *Object_File\File_ID
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = Lof(*Object_File\File_ID)
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  Else
    Logging_Entry_Add_Error("Couldn't open file", "'"+*Object_File\Filename+"' couldn't be opened. The file object now behaves like a new file.")
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = 0
    Object_Event\Size = 0
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  EndIf
  
  If *Object_File\Window
    If *Object_File\File_ID
      SetGadgetText(*Object_File\Button_Open, "Close")
      SetGadgetState(*Object_File\Button_Open, #True)
    Else
      SetGadgetText(*Object_File\Button_Open, "Open")
      SetGadgetState(*Object_File\Button_Open, #False)
    EndIf
  EndIf
  
EndProcedure

Procedure Object_File_HDD_Close(*Object.Object)
  Protected Object_Event.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\File_ID
    CloseFile(*Object_File\File_ID)
    *Object_File\File_ID = 0
  EndIf
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = 0
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  If *Object_File\Window
    If *Object_File\File_ID
      SetGadgetText(*Object_File\Button_Open, "Close")
      SetGadgetState(*Object_File\Button_Open, #True)
    Else
      SetGadgetText(*Object_File\Button_Open, "Open")
      SetGadgetState(*Object_File\Button_Open, #False)
    EndIf
  EndIf
EndProcedure

Procedure Object_File_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_File.Object_File
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_File_Main\Object_Type
  *Object\Type_Base = Object_File_Main\Object_Type
  
  *Object\Function_Delete = @_Object_File_Delete()
  *Object\Function_Main = @Object_File_Main()
  *Object\Function_Window = @Object_File_Window_Open()
  *Object\Function_Configuration_Get = @Object_File_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_File_Configuration_Set()
  
  *Object\Name = "File"
  *Object\Color = RGBA(176,137,0,255)
  
  *Object_File = AllocateMemory(SizeOf(Object_File))
  *Object\Custom_Data = *Object_File
  InitializeStructure(*Object_File, Object_File)
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Event = @Object_File_Output_Event()
  *Object_Output\Function_Get_Descriptor = @Object_File_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_File_Get_Size()
  *Object_Output\Function_Get_Data = @Object_File_Get_Data()
  *Object_Output\Function_Set_Data = @Object_File_Set_Data()
  *Object_Output\Function_Convolute = @Object_File_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_File_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_File_Convolute_Check()
  
  ; #### Open file
  If Requester
    *Object_File\Filename = OpenFileRequester("Open File", "", "", 0)
    *Object_File\Mode = #Object_File_Mode_Write
    *Object_File\Cached = #True
    *Object_File\Shared_Read = #True
    *Object_File\Shared_Write = #True
    Object_File_HDD_Open(*Object)
  EndIf
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_File_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\File_ID
    CloseFile(*Object_File\File_ID)
  EndIf
  
  Object_File_Window_Close(*Object)
  
  ClearStructure(*Object_File, Object_File)
  FreeMemory(*Object_File)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_File_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  If *Object_File\File_ID
    *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Opened", #NBT_Tag_Byte)      : NBT_Tag_Set_Number(*NBT_Tag, #True)
  Else
    *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Opened", #NBT_Tag_Byte)      : NBT_Tag_Set_Number(*NBT_Tag, #False)
  EndIf
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Filename", #NBT_Tag_String)    : NBT_Tag_Set_String(*NBT_Tag, *Object_File\Filename)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Mode", #NBT_Tag_Byte)          : NBT_Tag_Set_Number(*NBT_Tag, *Object_File\Mode)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Shared_Read", #NBT_Tag_Byte)   : NBT_Tag_Set_Number(*NBT_Tag, *Object_File\Shared_Read)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Shared_Write", #NBT_Tag_Byte)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_File\Shared_Write)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Cached", #NBT_Tag_Byte)        : NBT_Tag_Set_Number(*NBT_Tag, *Object_File\Cached)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_File_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Filename")     : *Object_File\Filename = NBT_Tag_Get_String(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Mode")         : *Object_File\Mode = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Shared_Read")  : *Object_File\Shared_Read = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Shared_Write") : *Object_File\Shared_Write = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Cached")       : *Object_File\Cached = NBT_Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Opened")
  If NBT_Tag_Get_Number(*NBT_Tag)
    Object_File_HDD_Open(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_File_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  Protected Filename.s
  
  Select *Object_Event\Type
    Case #Object_Event_Save
      If Not *Object_File\File_ID
        ; #### Open file
        *Object_File\Filename = SaveFileRequester("Save File", "", "", 0)
        *Object_File\Mode = #Object_File_Mode_Write
        *Object_File\Cached = #True
        *Object_File\Shared_Read = #True
        *Object_File\Shared_Write = #True
        Object_File_HDD_Create(*Object)
      EndIf
      
    Case #Object_Event_SaveAs
      If Not *Object_File\File_ID
        ; #### Open file
        *Object_File\Filename = SaveFileRequester("Save File", "", "", 0)
        *Object_File\Mode = #Object_File_Mode_Write
        *Object_File\Cached = #True
        *Object_File\Shared_Read = #True
        *Object_File\Shared_Write = #True
        Object_File_HDD_Create(*Object)
      Else
        Filename = SaveFileRequester("Save File As", "", "", 0)
        If CopyFile(*Object_File\Filename, Filename)
          *Object_File\Filename = Filename
          *Object_File\Mode = #Object_File_Mode_Write
          *Object_File\Cached = #True
          *Object_File\Shared_Read = #True
          *Object_File\Shared_Write = #True
          Object_File_HDD_Open(*Object)
        EndIf
      EndIf
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure.s Object_File_Get_Descriptor(*Object_Output.Object_Output)
  Protected Descriptor.s
  If Not *Object_Output
    ProcedureReturn ""
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn ""
  EndIf
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn ""
  EndIf
  
  If *Object_File\File_ID
    Descriptor + "[File]" + #CRLF$
    Descriptor + "Extension = " + GetExtensionPart(*Object_File\Filename) + #CRLF$
    ProcedureReturn Descriptor
  Else
    ProcedureReturn "" ; Not initialized --> Behave like an empty file
  EndIf
EndProcedure

Procedure.q Object_File_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn -1
  EndIf
  
  If *Object_File\File_ID
    ProcedureReturn Lof(*Object_File\File_ID)
  Else
    ProcedureReturn 0 ; Not initialized --> Behave like an empty file
  EndIf
EndProcedure

Procedure Object_File_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  Protected Read_Size.i
  
  If *Object_File\File_ID
    
    If Lof(*Object_File\File_ID) < Position
      ProcedureReturn #False
    EndIf
    
    FileSeek(*Object_File\File_ID, Position)
    Read_Size = ReadData(*Object_File\File_ID, *Data, Size)
    
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

Procedure Object_File_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  Protected Result.i
  Protected Object_Event.Object_Event
  Protected File_Size.q
  
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
  
  ; #### Don't write over the end of the file (REMOVED, ALL ELEMENTS SHOULD ALLOW TO BE WRITTEN AT THE END WITHOUT CONVOLUTION)
  ;File_Size = Object_File_Get_Size(*Object_Output)
  ;If Size + Position > File_Size
  ;  Size = File_Size - Position
  ;EndIf
  
  If Size <= 0
    ProcedureReturn #False
  EndIf
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\File_ID
    Logging_Entry_Add_Error("There is no file opened", "There is no file opened. Couldn't write.")
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\Mode = #Object_File_Mode_Write
    Logging_Entry_Add_Error("Couldn't write to the file", "The file is in read only mode.")
    ProcedureReturn #False
  EndIf
  
  If Lof(*Object_File\File_ID) < Position
    ProcedureReturn #False
  EndIf
  
  ;If Not *Object_File\File_ID
  ;  *Object_File\Filename = SaveFileRequester("Save file", "", "", 0)
  ;  *Object_File\File_ID = CreateFile(#PB_Any, *Object_File\Filename, #PB_File_SharedWrite | #PB_File_SharedRead)
  ;EndIf
  
  FileSeek(*Object_File\File_ID, Position)
  If WriteData(*Object_File\File_ID, *Data, Size)
    
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = Position
    Object_Event\Size = Size
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
    
    ProcedureReturn #True
  Else
    Logging_Entry_Add_Error("Couldn't write data to the file", "The file is probably in read only mode.")
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_File_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  Protected i
  Protected Temp_Position.q, Temp_Read_Position.q, Temp_Offset.q
  Protected File_Size.q
  Protected *Temp_Memory, Temp_Memory_Size.i
  Protected Object_Event.Object_Event
  Protected Successful
  ;Protected Memory_Operation.Memory_Operation
  
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
  
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\File_ID
    Logging_Entry_Add_Error("There is no file opened", "There is no file opened. Couldn't write.")
    ProcedureReturn #False
  EndIf
  
  File_Size = Lof(*Object_File\File_ID)
  
  If Position > File_Size
    ProcedureReturn #False
  EndIf
  
  If Offset = 0
    ProcedureReturn #True
  EndIf
  
  If Not *Object_File\Mode = #Object_File_Mode_Write
    Logging_Entry_Add_Error("Couldn't convolute the file", "The file is in read only mode.")
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
    FileSeek(*Object_File\File_ID, Temp_Read_Position)
    ReadData(*Object_File\File_ID, *Temp_Memory, Temp_Memory_Size)
  EndIf
  
  Successful = #True
  
  FileSeek(*Object_File\File_ID, Position)
  If Temp_Offset > 0
    For i = 1 To Temp_Offset
      If Not WriteAsciiCharacter(*Object_File\File_ID, 0)
        Successful = #False
        Break
      EndIf
    Next
  EndIf
  If *Temp_Memory
    If Not WriteData(*Object_File\File_ID, *Temp_Memory, Temp_Memory_Size)
      Successful = #False
    EndIf
  EndIf
  
  If *Temp_Memory
    FreeMemory(*Temp_Memory) : *Temp_Memory = #Null
  EndIf
  
  If Temp_Offset < 0
    FileSeek(*Object_File\File_ID, File_Size + Temp_Offset)
    If Not TruncateFile(*Object_File\File_ID)
      Successful = #False
    EndIf
  EndIf
  
  If Successful
    Object_Event\Type = #Object_Link_Event_Update
    Object_Event\Position = Position
    Object_Event\Size = File_Size - Position + Temp_Offset
    Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  Else
    Logging_Entry_Add_Error("Couldn't convolute the file", "The file is probably in read only mode.")
  EndIf
  
  ProcedureReturn Successful
EndProcedure

Procedure Object_File_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\Mode = #Object_File_Mode_Write And *Object_File\File_ID
    Logging_Entry_Add_Error("Couldn't write to the file", "The file is in read only mode.")
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_File_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\Mode = #Object_File_Mode_Write And *Object_File\File_ID
    Logging_Entry_Add_Error("Couldn't convolute the file", "The file is in read only mode.")
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_File_Window_Event_String()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  If Event_Type = #PB_EventType_LostFocus
    *Object_File\Filename = GetGadgetText(*Object_File\Editor)
    
    ; #### Reopen File if one is opened
    If *Object_File\File_ID
      Object_File_HDD_Open(*Object)
    EndIf
  EndIf
  
EndProcedure

Procedure Object_File_Window_Event_Button_File()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  *Object_File\Filename = SaveFileRequester("Select File", *Object_File\Filename, "", 1)
  
  SetGadgetText(*Object_File\Editor, *Object_File\Filename)
  
  ; #### Reopen File if one is opened
  If *Object_File\File_ID
    Object_File_HDD_Open(*Object)
  EndIf
  
EndProcedure

Procedure Object_File_Window_Event_Button_Create()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  Object_File_HDD_Create(*Object)
  
EndProcedure

Procedure Object_File_Window_Event_Button_Open()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(Event_Gadget)
    Object_File_HDD_Open(*Object)
  Else
    Object_File_HDD_Close(*Object)
  EndIf
  
EndProcedure

Procedure Object_File_Window_Event_Option()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_File\Option[0] : *Object_File\Mode = #Object_File_Mode_Read
    Case *Object_File\Option[1] : *Object_File\Mode = #Object_File_Mode_Write
  EndSelect
  
  ; #### Reopen File if one is opened
  If *Object_File\File_ID
    Object_File_HDD_Open(*Object)
  EndIf
  
EndProcedure

Procedure Object_File_Window_Event_CheckBox()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_File\CheckBox[0] : *Object_File\Shared_Read = GetGadgetState(*Object_File\CheckBox[0])
    Case *Object_File\CheckBox[1] : *Object_File\Shared_Write = GetGadgetState(*Object_File\CheckBox[1])
    Case *Object_File\CheckBox[2] : *Object_File\Cached = GetGadgetState(*Object_File\CheckBox[2])
  EndSelect
  
  ; #### Reopen File if one is opened
  If *Object_File\File_ID
    Object_File_HDD_Open(*Object)
  EndIf
  
EndProcedure

Procedure Object_File_Window_Event_SizeWindow()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  ;ResizeGadget(*Object_File\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ;ResizeGadget(*Object_File\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
  ;*Object_File\Redraw = #True
EndProcedure

Procedure Object_File_Window_Event_ActivateWindow()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  
  ;*Object_File\Redraw = #True
EndProcedure

Procedure Object_File_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_File_Window_Event_CloseWindow()
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
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn 
  EndIf
  
  ;Object_File_Window_Close(*Object)
  *Object_File\Window_Close = #True
EndProcedure

Procedure Object_File_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If Not *Object_File\Window
    
    Width = 500
    Height = 130
    
    *Object_File\Window = Window_Create(*Object, "File", "File", #False, 0, 0, Width, Height)
    
    ; #### Toolbar
    
    ; #### Gadgets
    *Object_File\Editor = EditorGadget(#PB_Any, 10, 10, Width-70, 40)
    *Object_File\Button_File = ButtonImageGadget(#PB_Any, Width-50, 10, 40, 40, 0)
    *Object_File\Option[0] = OptionGadget(#PB_Any, 10, 60, 100, 20, "Read")
    *Object_File\Option[1] = OptionGadget(#PB_Any, 10, 80, 100, 20, "Write")
    *Object_File\CheckBox[0] = CheckBoxGadget(#PB_Any, 110, 60, 100, 20, "Shared Read")
    *Object_File\CheckBox[1] = CheckBoxGadget(#PB_Any, 110, 80, 100, 20, "Shared Write")
    *Object_File\CheckBox[2] = CheckBoxGadget(#PB_Any, 110, 100, 100, 20, "Cached")
    *Object_File\Button_Create = ButtonGadget(#PB_Any, Width-200, Height-40, 90, 30, "Create")
    *Object_File\Button_Open = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "Open", #PB_Button_Toggle)
    
    SendMessage_(GadgetID(*Object_File\Editor),#EM_SETTARGETDEVICE,#Null,0) ; automatic word wrap
    SetGadgetText(*Object_File\Editor, *Object_File\Filename)
    
    Select *Object_File\Mode
      Case #Object_File_Mode_Read   : SetGadgetState(*Object_File\Option[0], #True)
      Case #Object_File_Mode_Write  : SetGadgetState(*Object_File\Option[1], #True)
    EndSelect
    
    If *Object_File\Shared_Read
      SetGadgetState(*Object_File\CheckBox[0], #True)
    Else
      SetGadgetState(*Object_File\CheckBox[0], #False)
    EndIf
    
    If *Object_File\Shared_Write
      SetGadgetState(*Object_File\CheckBox[1], #True)
    Else
      SetGadgetState(*Object_File\CheckBox[1], #False)
    EndIf
    
    If *Object_File\Cached
      SetGadgetState(*Object_File\CheckBox[2], #True)
    Else
      SetGadgetState(*Object_File\CheckBox[2], #False)
    EndIf
    
    If *Object_File\File_ID
      SetGadgetText(*Object_File\Button_Open, "Close")
      SetGadgetState(*Object_File\Button_Open, #True)
    Else
      SetGadgetText(*Object_File\Button_Open, "Open")
      SetGadgetState(*Object_File\Button_Open, #False)
    EndIf
    
    BindEvent(#PB_Event_SizeWindow, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    ;BindEvent(#PB_Event_Repaint, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_File_Window_Event_Menu(), *Object_File\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_File_Window_Event_CloseWindow(), *Object_File\Window\ID)
    BindGadgetEvent(*Object_File\Editor, @Object_File_Window_Event_String())
    BindGadgetEvent(*Object_File\Button_File, @Object_File_Window_Event_Button_File())
    BindGadgetEvent(*Object_File\Button_Create, @Object_File_Window_Event_Button_Create())
    BindGadgetEvent(*Object_File\Button_Open, @Object_File_Window_Event_Button_Open())
    BindGadgetEvent(*Object_File\Option[0], @Object_File_Window_Event_Option())
    BindGadgetEvent(*Object_File\Option[1], @Object_File_Window_Event_Option())
    BindGadgetEvent(*Object_File\CheckBox[0], @Object_File_Window_Event_CheckBox())
    BindGadgetEvent(*Object_File\CheckBox[1], @Object_File_Window_Event_CheckBox())
    BindGadgetEvent(*Object_File\CheckBox[2], @Object_File_Window_Event_CheckBox())
  
  Else
    Window_Set_Active(*Object_File\Window)
  EndIf
EndProcedure

Procedure Object_File_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    ;UnbindEvent(#PB_Event_Repaint, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Object_File_Window_Event_SizeWindow(), *Object_File\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_File_Window_Event_Menu(), *Object_File\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_File_Window_Event_CloseWindow(), *Object_File\Window\ID)
    UnbindGadgetEvent(*Object_File\Editor, @Object_File_Window_Event_String())
    UnbindGadgetEvent(*Object_File\Button_File, @Object_File_Window_Event_Button_File())
    UnbindGadgetEvent(*Object_File\Button_Create, @Object_File_Window_Event_Button_Create())
    UnbindGadgetEvent(*Object_File\Button_Open, @Object_File_Window_Event_Button_Open())
    UnbindGadgetEvent(*Object_File\Option[0], @Object_File_Window_Event_Option())
    UnbindGadgetEvent(*Object_File\Option[1], @Object_File_Window_Event_Option())
    UnbindGadgetEvent(*Object_File\CheckBox[0], @Object_File_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_File\CheckBox[1], @Object_File_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_File\CheckBox[2], @Object_File_Window_Event_CheckBox())
    
    Window_Delete(*Object_File\Window)
    *Object_File\Window = #Null
    
  EndIf
EndProcedure

Procedure Object_File_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_File.Object_File = *Object\Custom_Data
  If Not *Object_File
    ProcedureReturn #False
  EndIf
  
  If *Object_File\Window
    
  EndIf
  
  If *Object_File\Window_Close
    *Object_File\Window_Close = #False
    Object_File_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_File_Main\Object_Type = Object_Type_Create()
If Object_File_Main\Object_Type
  Object_File_Main\Object_Type\Category = "Data-Source"
  Object_File_Main\Object_Type\Name = "File"
  Object_File_Main\Object_Type\UID = "D3__FILE"
  Object_File_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_File_Main\Object_Type\Date_Creation = Date(2014,01,14,12,00,00)
  Object_File_Main\Object_Type\Date_Modification = Date(2014,03,02,13,51,00)
  Object_File_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_File_Main\Object_Type\Description = "File object."
  Object_File_Main\Object_Type\Function_Create = @Object_File_Create()
  Object_File_Main\Object_Type\Version = 1000
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 1006
; FirstLine = 978
; Folding = -----
; EnableUnicode
; EnableXP