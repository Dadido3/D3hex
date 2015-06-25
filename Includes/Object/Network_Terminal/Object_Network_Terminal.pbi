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

; ##################################################### Inits #######################################################

InitNetwork() 

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

Enumeration
  #Object_Network_Terminal_Mode_TCP
  #Object_Network_Terminal_Mode_UDP
EndEnumeration

Enumeration
  #Object_Network_Terminal_Mode_IPv4
  #Object_Network_Terminal_Mode_IPv6
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_Network_Terminal_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Network_Terminal_Main.Object_Network_Terminal_Main

Structure Object_Network_Terminal_Chunk
  Start.q
  
  *Data
  Size.i
  
  Sent.i
EndStructure

Structure Object_Network_Terminal
  *Window.Window
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
  
  List Output_Chunk.Object_Network_Terminal_Chunk()
  List Input_Chunk.Object_Network_Terminal_Chunk()
  
  Received.q
  Sent.q        ; Includes also data which isn't sent yet
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   Object_Network_Terminal_Main(*Object.Object)
Declare   _Object_Network_Terminal_Delete(*Object.Object)
Declare   Object_Network_Terminal_Window_Open(*Object.Object)

Declare   Object_Network_Terminal_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Network_Terminal_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Network_Terminal_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare   Object_Network_Terminal_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare.s Object_Network_Terminal_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Network_Terminal_Get_Size(*Object_Output.Object_Output)
Declare   Object_Network_Terminal_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Network_Terminal_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Network_Terminal_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_Network_Terminal_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_Network_Terminal_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_Network_Terminal_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Network_Terminal_Connection_Open(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  Protected Type
  
  If *Object_Network_Terminal\Connection_ID
    CloseNetworkConnection(*Object_Network_Terminal\Connection_ID)
    *Object_Network_Terminal\Connection_ID = 0
  EndIf
  
  Select *Object_Network_Terminal\Transport_Protocol
    Case #Object_Network_Terminal_Mode_TCP : Type = #PB_Network_TCP
    Case #Object_Network_Terminal_Mode_UDP : Type = #PB_Network_UDP
  EndSelect
  
  Select *Object_Network_Terminal\Internet_Protocol
    Case #Object_Network_Terminal_Mode_IPv4 : Type | #PB_Network_IPv4
    Case #Object_Network_Terminal_Mode_IPv6 : Type | #PB_Network_IPv6
  EndSelect
  
  *Object_Network_Terminal\Connection_ID = OpenNetworkConnection(*Object_Network_Terminal\Adress, *Object_Network_Terminal\Port, Type, 1000)
  
  If *Object_Network_Terminal\Connection_ID
  Else
    Logging_Entry_Add_Error("Couldn't open connection", "'"+*Object_Network_Terminal\Adress+":"+Str(*Object_Network_Terminal\Port)+"' couldn't be opened.")
  EndIf
  
  ForEach *Object_Network_Terminal\Output_Chunk()
    If *Object_Network_Terminal\Output_Chunk()\Data And *Object_Network_Terminal\Output_Chunk()\Size > *Object_Network_Terminal\Output_Chunk()\Sent
      FreeMemory(*Object_Network_Terminal\Output_Chunk()\Data)
      DeleteElement(*Object_Network_Terminal\Output_Chunk())
    EndIf
  Next
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = *Object_Network_Terminal\Sent
  Object_Output_Event(Object_Output_Get(*Object, 0), Object_Event)
  
  ; #### Reorganize Output-Chunks
  *Object_Network_Terminal\Sent = 0
  ForEach *Object_Network_Terminal\Output_Chunk()
    *Object_Network_Terminal\Output_Chunk()\Start = *Object_Network_Terminal\Sent
    *Object_Network_Terminal\Sent + *Object_Network_Terminal\Output_Chunk()\Size
  Next
  
  If *Object_Network_Terminal\Window
    If *Object_Network_Terminal\Connection_ID
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Close")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #True)
    Else
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Open")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #False)
    EndIf
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Connection_Close(*Object.Object)
  Protected Object_Event.Object_Event
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If *Object_Network_Terminal\Connection_ID
    CloseNetworkConnection(*Object_Network_Terminal\Connection_ID)
    *Object_Network_Terminal\Connection_ID = 0
  EndIf
  
  If *Object_Network_Terminal\Window
    If *Object_Network_Terminal\Connection_ID
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Close")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #True)
    Else
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Open")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #False)
    EndIf
  EndIf
EndProcedure

Procedure Object_Network_Terminal_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Network_Terminal.Object_Network_Terminal
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Network_Terminal_Main\Object_Type
  *Object\Type_Base = Object_Network_Terminal_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Network_Terminal_Delete()
  *Object\Function_Main = @Object_Network_Terminal_Main()
  *Object\Function_Window = @Object_Network_Terminal_Window_Open()
  *Object\Function_Configuration_Get = @Object_Network_Terminal_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Network_Terminal_Configuration_Set()
  
  *Object\Name = "Network Terminal"
  *Object\Color = RGBA(200,150,250,255)
  
  *Object\Custom_Data = AllocateStructure(Object_Network_Terminal)
  *Object_Network_Terminal =  *Object\Custom_Data
  
  ; #### Add Output "Output"
  *Object_Output = Object_Output_Add(*Object, "Send", "Send")
  *Object_Output\Function_Event = @Object_Network_Terminal_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Network_Terminal_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Network_Terminal_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Network_Terminal_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Network_Terminal_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Network_Terminal_Set_Data()
  *Object_Output\Function_Convolute = @Object_Network_Terminal_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Network_Terminal_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Network_Terminal_Convolute_Check()
  
  ; #### Add Output "Input"
  *Object_Output = Object_Output_Add(*Object, "Receive", "Receive")
  *Object_Output\Function_Event = @Object_Network_Terminal_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_Network_Terminal_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_Network_Terminal_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Network_Terminal_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Network_Terminal_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Network_Terminal_Set_Data()
  *Object_Output\Function_Convolute = @Object_Network_Terminal_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_Network_Terminal_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_Network_Terminal_Convolute_Check()
  
  If Requester
    Object_Network_Terminal_Window_Open(*Object)
  EndIf
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Network_Terminal_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If *Object_Network_Terminal\Connection_ID
    CloseNetworkConnection(*Object_Network_Terminal\Connection_ID)
  EndIf
  
  ForEach *Object_Network_Terminal\Output_Chunk()
    If *Object_Network_Terminal\Output_Chunk()\Data
      FreeMemory(*Object_Network_Terminal\Output_Chunk()\Data)
    EndIf
    DeleteElement(*Object_Network_Terminal\Output_Chunk())
  Next
  
  ForEach *Object_Network_Terminal\Input_Chunk()
    If *Object_Network_Terminal\Input_Chunk()\Data
      FreeMemory(*Object_Network_Terminal\Input_Chunk()\Data)
    EndIf
    DeleteElement(*Object_Network_Terminal\Input_Chunk())
  Next
  
  Object_Network_Terminal_Window_Close(*Object)
  
  FreeStructure(*Object_Network_Terminal)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Network_Terminal_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  If *Object_Network_Terminal\Connection_ID
    *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Opened", #NBT_Tag_Byte)            : NBT_Tag_Set_Number(*NBT_Tag, #True)
  Else
    *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Opened", #NBT_Tag_Byte)            : NBT_Tag_Set_Number(*NBT_Tag, #False)
  EndIf
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Adress", #NBT_Tag_String)            : NBT_Tag_Set_String(*NBT_Tag, *Object_Network_Terminal\Adress)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Port", #NBT_Tag_Long)                : NBT_Tag_Set_Number(*NBT_Tag, *Object_Network_Terminal\Port)
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Internet_Protocol", #NBT_Tag_Long)   : NBT_Tag_Set_Number(*NBT_Tag, *Object_Network_Terminal\Internet_Protocol)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Transport_Protocol", #NBT_Tag_Long)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_Network_Terminal\Transport_Protocol)
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Segment_Output", #NBT_Tag_Long)      : NBT_Tag_Set_Number(*NBT_Tag, *Object_Network_Terminal\Segment_Output)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Segment_Input", #NBT_Tag_Long)       : NBT_Tag_Set_Number(*NBT_Tag, *Object_Network_Terminal\Segment_Input)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Network_Terminal_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Adress")             : *Object_Network_Terminal\Adress = NBT_Tag_Get_String(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Port")               : *Object_Network_Terminal\Port = NBT_Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Internet_Protocol")  : *Object_Network_Terminal\Internet_Protocol = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Transport_Protocol") : *Object_Network_Terminal\Transport_Protocol = NBT_Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Segment_Output")     : *Object_Network_Terminal\Segment_Output = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Segment_Input")      : *Object_Network_Terminal\Segment_Input = NBT_Tag_Get_Number(*NBT_Tag)
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Opened")
  If NBT_Tag_Get_Number(*NBT_Tag)
    Object_Network_Terminal_Connection_Open(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Network_Terminal_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Network_Terminal_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  Select *Object_Output\i
    Case 0 ; The "Output"
      If *Object_Network_Terminal\Segment_Output
        ForEach *Object_Network_Terminal\Output_Chunk()
          AddElement(Segment())
          Segment()\Position = *Object_Network_Terminal\Output_Chunk()\Start
          Segment()\Size = *Object_Network_Terminal\Output_Chunk()\Size
          Segment()\Metadata = #Metadata_NoError | #Metadata_Readable
        Next
      EndIf
      ProcedureReturn #True
      
    Case 1 ; The "Input"
      If *Object_Network_Terminal\Segment_Input
        ForEach *Object_Network_Terminal\Input_Chunk()
          AddElement(Segment())
          Segment()\Position = *Object_Network_Terminal\Input_Chunk()\Start
          Segment()\Size = *Object_Network_Terminal\Input_Chunk()\Size
          Segment()\Metadata = #Metadata_NoError | #Metadata_Readable
        Next
      EndIf
      ProcedureReturn #True
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure.s Object_Network_Terminal_Get_Descriptor(*Object_Output.Object_Output)
  Protected Descriptor.s
  If Not *Object_Output
    ProcedureReturn ""
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn ""
  EndIf
  
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn ""
  EndIf
  
  ProcedureReturn ""
EndProcedure

Procedure.q Object_Network_Terminal_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn -1
  EndIf
  
  Select *Object_Output\i
    Case 0 ; The "Output"
      ProcedureReturn *Object_Network_Terminal\Sent
      
    Case 1 ; The "Input"
      ProcedureReturn *Object_Network_Terminal\Received
  EndSelect
  
  ProcedureReturn -1
EndProcedure

Procedure Object_Network_Terminal_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If *Metadata
    FillMemory(*Metadata, Size, 0)
  EndIf
  If *Data
    FillMemory(*Data, Size, 0)
  EndIf
  
  Select *Object_Output\i
    Case 0 ; The "Output"
      ForEach *Object_Network_Terminal\Output_Chunk()
        If *Object_Network_Terminal\Output_Chunk()\Start < Position + Size And *Object_Network_Terminal\Output_Chunk()\Start + *Object_Network_Terminal\Output_Chunk()\Size > Position
          Memory_Range_Copy(*Object_Network_Terminal\Output_Chunk()\Data, 0, *Data, *Object_Network_Terminal\Output_Chunk()\Start-Position, *Object_Network_Terminal\Output_Chunk()\Size, *Object_Network_Terminal\Output_Chunk()\Size, Size)
          Memory_Range_Fill(#Metadata_NoError | #Metadata_Readable, *Object_Network_Terminal\Output_Chunk()\Size, *Metadata, *Object_Network_Terminal\Output_Chunk()\Start-Position, Size)
        EndIf
      Next
      ProcedureReturn #True
      
    Case 1 ; The "Input"
      ForEach *Object_Network_Terminal\Input_Chunk()
        If *Object_Network_Terminal\Input_Chunk()\Start < Position + Size And *Object_Network_Terminal\Input_Chunk()\Start + *Object_Network_Terminal\Input_Chunk()\Size > Position
          Memory_Range_Copy(*Object_Network_Terminal\Input_Chunk()\Data, 0, *Data, *Object_Network_Terminal\Input_Chunk()\Start-Position, *Object_Network_Terminal\Input_Chunk()\Size, *Object_Network_Terminal\Input_Chunk()\Size, Size)
          Memory_Range_Fill(#Metadata_NoError | #Metadata_Readable, *Object_Network_Terminal\Input_Chunk()\Size, *Metadata, *Object_Network_Terminal\Input_Chunk()\Start-Position, Size)
        EndIf
      Next
      ProcedureReturn #True
      
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Network_Terminal_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Network_Terminal\Connection_ID
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  Protected *Temp
  
  Select *Object_Output\i
    Case 0 ; The "Output"
      If Position = *Object_Network_Terminal\Sent
        *Temp = AllocateMemory(Size)
        If *Temp
          LastElement(*Object_Network_Terminal\Output_Chunk())
          AddElement(*Object_Network_Terminal\Output_Chunk())
          *Object_Network_Terminal\Output_Chunk()\Start = *Object_Network_Terminal\Sent
          *Object_Network_Terminal\Output_Chunk()\Data = *Temp
          *Object_Network_Terminal\Output_Chunk()\Size = Size
          *Object_Network_Terminal\Sent + Size
          CopyMemory(*Data, *Temp, Size)
          
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = *Object_Network_Terminal\Sent
          Object_Event\Size = Size
          Object_Output_Event(Object_Output_Get(*Object, 0), Object_Event)
        EndIf
        ProcedureReturn #True
      EndIf
      
    Case 1 ; The "Input"
      ProcedureReturn #False
      
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Network_Terminal_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Network_Terminal_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  If Not *Object_Network_Terminal\Connection_ID
    ProcedureReturn #False
  EndIf
  
  Select *Object_Output\i
    Case 0 ; The "Output"
      If Position >= *Object_Network_Terminal\Sent
        ProcedureReturn #True
      EndIf
      
    Case 1 ; The "Input"
      ProcedureReturn #False
      
  EndSelect
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Network_Terminal_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Object_Network_Terminal_Window_Event_String_0()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  If Event_Type = #PB_EventType_LostFocus
    *Object_Network_Terminal\Adress = GetGadgetText(Event_Gadget)
    
    ; #### Reopen connection if one is opened
    If *Object_Network_Terminal\Connection_ID
      Object_Network_Terminal_Connection_Open(*Object)
    EndIf
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_String_1()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  If Event_Type = #PB_EventType_LostFocus
    *Object_Network_Terminal\Port = Val(GetGadgetText(Event_Gadget))
    
    ; #### Reopen connection if one is opened
    If *Object_Network_Terminal\Connection_ID
      Object_Network_Terminal_Connection_Open(*Object)
    EndIf
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_Button_Clear_Output()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  ForEach *Object_Network_Terminal\Output_Chunk()
    If *Object_Network_Terminal\Output_Chunk()\Data And *Object_Network_Terminal\Output_Chunk()\Size = *Object_Network_Terminal\Output_Chunk()\Sent
      FreeMemory(*Object_Network_Terminal\Output_Chunk()\Data)
      DeleteElement(*Object_Network_Terminal\Output_Chunk())
    EndIf
  Next
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = *Object_Network_Terminal\Sent
  Object_Output_Event(Object_Output_Get(*Object, 0), Object_Event)
  
  ; #### Reorganize Output-Chunks
  *Object_Network_Terminal\Sent = 0
  ForEach *Object_Network_Terminal\Output_Chunk()
    *Object_Network_Terminal\Output_Chunk()\Start = *Object_Network_Terminal\Sent
    *Object_Network_Terminal\Sent + *Object_Network_Terminal\Output_Chunk()\Size
  Next
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_Button_Clear_Input()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  ForEach *Object_Network_Terminal\Input_Chunk()
    If *Object_Network_Terminal\Input_Chunk()\Data
      FreeMemory(*Object_Network_Terminal\Input_Chunk()\Data)
      DeleteElement(*Object_Network_Terminal\Input_Chunk())
    EndIf
  Next
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = *Object_Network_Terminal\Received
  Object_Output_Event(Object_Output_Get(*Object, 1), Object_Event)
  
  *Object_Network_Terminal\Received = 0
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_Button_Open()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(Event_Gadget)
    Object_Network_Terminal_Connection_Open(*Object)
  Else
    Object_Network_Terminal_Connection_Close(*Object)
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_Option()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  Select Event_Gadget
    Case *Object_Network_Terminal\Option[0] : *Object_Network_Terminal\Transport_Protocol = #Object_Network_Terminal_Mode_TCP
    Case *Object_Network_Terminal\Option[1] : *Object_Network_Terminal\Transport_Protocol = #Object_Network_Terminal_Mode_UDP
    
    Case *Object_Network_Terminal\Option[2] : *Object_Network_Terminal\Internet_Protocol = #Object_Network_Terminal_Mode_IPv4
    Case *Object_Network_Terminal\Option[3] : *Object_Network_Terminal\Internet_Protocol = #Object_Network_Terminal_Mode_IPv6
  EndSelect
  
  ; #### Reopen connection if one is opened
  If *Object_Network_Terminal\Connection_ID
    Object_Network_Terminal_Connection_Open(*Object)
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_CheckBox()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  Protected Object_Event.Object_Event
  
  Select Event_Gadget
    Case *Object_Network_Terminal\CheckBox[0]
      *Object_Network_Terminal\Segment_Output = GetGadgetState(*Object_Network_Terminal\CheckBox[0])
      
      Object_Event\Type = #Object_Link_Event_Update
      Object_Event\Position = 0
      Object_Event\Size = *Object_Network_Terminal\Sent
      Object_Output_Event(Object_Output_Get(*Object, 0), Object_Event)
      
    Case *Object_Network_Terminal\CheckBox[1]
      *Object_Network_Terminal\Segment_Input  = GetGadgetState(*Object_Network_Terminal\CheckBox[1])
      
      Object_Event\Type = #Object_Link_Event_Update
      Object_Event\Position = 0
      Object_Event\Size = *Object_Network_Terminal\Received
      Object_Output_Event(Object_Output_Get(*Object, 1), Object_Event)
      
  EndSelect
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_SizeWindow()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_ActivateWindow()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  
EndProcedure

Procedure Object_Network_Terminal_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Network_Terminal_Window_Event_CloseWindow()
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
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn 
  EndIf
  
  *Object_Network_Terminal\Window_Close = #True
EndProcedure

Procedure Object_Network_Terminal_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Network_Terminal\Window
    
    Width = 430
    Height = 150
    
    *Object_Network_Terminal\Window = Window_Create(*Object, "Network Terminal", "Network Terminal", #False, 0, 0, Width, Height, #False)
    
    ; #### Toolbar
    
    ; #### Gadgets
    *Object_Network_Terminal\Text[0] = TextGadget(#PB_Any, 10, 10, 50, 20, "Address:", #PB_Text_Right)
    *Object_Network_Terminal\String[0] = StringGadget(#PB_Any, 70, 10, Width-80, 20, "")
    *Object_Network_Terminal\Text[1] = TextGadget(#PB_Any, 10, 40, 50, 20, "Port:", #PB_Text_Right)
    *Object_Network_Terminal\String[1] = StringGadget(#PB_Any, 70, 40, Width-80, 20, "", #PB_String_Numeric)
    *Object_Network_Terminal\Frame[0] = FrameGadget(#PB_Any, 10, 70, 100, 70, "Transport Protocol")
    *Object_Network_Terminal\Option[0] = OptionGadget(#PB_Any, 20, 90, 80, 20, "TCP")
    *Object_Network_Terminal\Option[1] = OptionGadget(#PB_Any, 20, 110, 80, 20, "UDP")
    *Object_Network_Terminal\Frame[0] = FrameGadget(#PB_Any, 120, 70, 100, 70, "Internet Protocol")
    *Object_Network_Terminal\Option[2] = OptionGadget(#PB_Any, 130, 90, 80, 20, "IPv4")
    *Object_Network_Terminal\Option[3] = OptionGadget(#PB_Any, 130, 110, 80, 20, "IPv6")
    *Object_Network_Terminal\Frame[1] = FrameGadget(#PB_Any, 230, 70, 100, 70, "Show Segments in")
    *Object_Network_Terminal\CheckBox[0] = CheckBoxGadget(#PB_Any, 240, 90, 80, 20, "Sent")
    *Object_Network_Terminal\CheckBox[1] = CheckBoxGadget(#PB_Any, 240, 110, 80, 20, "Received")
    *Object_Network_Terminal\Button_Clear_Output = ButtonGadget(#PB_Any, Width-90, Height-80, 80, 20, "Clear Sent")
    *Object_Network_Terminal\Button_Clear_Input = ButtonGadget(#PB_Any, Width-90, Height-60, 80, 20, "Clear Received")
    *Object_Network_Terminal\Button_Open = ButtonGadget(#PB_Any, Width-90, Height-40, 80, 30, "Open", #PB_Button_Toggle)
    
    SetGadgetText(*Object_Network_Terminal\String[0], *Object_Network_Terminal\Adress)
    SetGadgetText(*Object_Network_Terminal\String[1], Str(*Object_Network_Terminal\Port))
    
    Select *Object_Network_Terminal\Transport_Protocol
      Case #Object_Network_Terminal_Mode_TCP  : SetGadgetState(*Object_Network_Terminal\Option[0], #True)
      Case #Object_Network_Terminal_Mode_UDP  : SetGadgetState(*Object_Network_Terminal\Option[1], #True)
    EndSelect
    
    Select *Object_Network_Terminal\Internet_Protocol
      Case #Object_Network_Terminal_Mode_IPv4 : SetGadgetState(*Object_Network_Terminal\Option[2], #True)
      Case #Object_Network_Terminal_Mode_IPv6 : SetGadgetState(*Object_Network_Terminal\Option[3], #True)
    EndSelect
    
    If *Object_Network_Terminal\Segment_Output
      SetGadgetState(*Object_Network_Terminal\CheckBox[0], #True)
    Else
      SetGadgetState(*Object_Network_Terminal\CheckBox[0], #False)
    EndIf
    
    If *Object_Network_Terminal\Segment_Input
      SetGadgetState(*Object_Network_Terminal\CheckBox[1], #True)
    Else
      SetGadgetState(*Object_Network_Terminal\CheckBox[1], #False)
    EndIf
    
    If *Object_Network_Terminal\Connection_ID
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Close")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #True)
    Else
      SetGadgetText(*Object_Network_Terminal\Button_Open, "Open")
      SetGadgetState(*Object_Network_Terminal\Button_Open, #False)
    EndIf
    
    BindEvent(#PB_Event_SizeWindow, @Object_Network_Terminal_Window_Event_SizeWindow(), *Object_Network_Terminal\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Network_Terminal_Window_Event_Menu(), *Object_Network_Terminal\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Network_Terminal_Window_Event_CloseWindow(), *Object_Network_Terminal\Window\ID)
    BindGadgetEvent(*Object_Network_Terminal\String[0], @Object_Network_Terminal_Window_Event_String_0())
    BindGadgetEvent(*Object_Network_Terminal\String[1], @Object_Network_Terminal_Window_Event_String_1())
    BindGadgetEvent(*Object_Network_Terminal\Button_Clear_Output, @Object_Network_Terminal_Window_Event_Button_Clear_Output())
    BindGadgetEvent(*Object_Network_Terminal\Button_Clear_Input, @Object_Network_Terminal_Window_Event_Button_Clear_Input())
    BindGadgetEvent(*Object_Network_Terminal\Button_Open, @Object_Network_Terminal_Window_Event_Button_Open())
    BindGadgetEvent(*Object_Network_Terminal\Option[0], @Object_Network_Terminal_Window_Event_Option())
    BindGadgetEvent(*Object_Network_Terminal\Option[1], @Object_Network_Terminal_Window_Event_Option())
    BindGadgetEvent(*Object_Network_Terminal\Option[2], @Object_Network_Terminal_Window_Event_Option())
    BindGadgetEvent(*Object_Network_Terminal\Option[3], @Object_Network_Terminal_Window_Event_Option())
    BindGadgetEvent(*Object_Network_Terminal\CheckBox[0], @Object_Network_Terminal_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Network_Terminal\CheckBox[1], @Object_Network_Terminal_Window_Event_CheckBox())
  
  Else
    Window_Set_Active(*Object_Network_Terminal\Window)
  EndIf
EndProcedure

Procedure Object_Network_Terminal_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  If *Object_Network_Terminal\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Network_Terminal_Window_Event_SizeWindow(), *Object_Network_Terminal\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Network_Terminal_Window_Event_Menu(), *Object_Network_Terminal\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Network_Terminal_Window_Event_CloseWindow(), *Object_Network_Terminal\Window\ID)
    UnbindGadgetEvent(*Object_Network_Terminal\String[0], @Object_Network_Terminal_Window_Event_String_0())
    UnbindGadgetEvent(*Object_Network_Terminal\String[1], @Object_Network_Terminal_Window_Event_String_1())
    UnbindGadgetEvent(*Object_Network_Terminal\Button_Clear_Output, @Object_Network_Terminal_Window_Event_Button_Clear_Output())
    UnbindGadgetEvent(*Object_Network_Terminal\Button_Clear_Input, @Object_Network_Terminal_Window_Event_Button_Clear_Input())
    UnbindGadgetEvent(*Object_Network_Terminal\Button_Open, @Object_Network_Terminal_Window_Event_Button_Open())
    UnbindGadgetEvent(*Object_Network_Terminal\Option[0], @Object_Network_Terminal_Window_Event_Option())
    UnbindGadgetEvent(*Object_Network_Terminal\Option[1], @Object_Network_Terminal_Window_Event_Option())
    UnbindGadgetEvent(*Object_Network_Terminal\Option[2], @Object_Network_Terminal_Window_Event_Option())
    UnbindGadgetEvent(*Object_Network_Terminal\Option[3], @Object_Network_Terminal_Window_Event_Option())
    UnbindGadgetEvent(*Object_Network_Terminal\CheckBox[0], @Object_Network_Terminal_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Network_Terminal\CheckBox[1], @Object_Network_Terminal_Window_Event_CheckBox())
    
    Window_Delete(*Object_Network_Terminal\Window)
    *Object_Network_Terminal\Window = #Null
  EndIf
EndProcedure

Procedure Object_Network_Terminal_Network_Available(Connection_ID.i)
  Protected Length.i
  Protected RetVal.i
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    RetVal = ioctlsocket_(Connection_ID, #FIONREAD, @Length)
  CompilerElse
    RetVal = ioctl_(Connection_ID, #FIONREAD, @Length)
  CompilerEndIf
  
  ProcedureReturn Length
EndProcedure

Procedure Object_Network_Terminal_Network(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  Protected *Temp, Temp_Size.i
  Protected Network_Event
  Protected Result.i
  
  If *Object_Network_Terminal\Connection_ID
    Network_Event = NetworkClientEvent(*Object_Network_Terminal\Connection_ID)
    
    ; #### Send data
    ForEach *Object_Network_Terminal\Output_Chunk()
      If *Object_Network_Terminal\Output_Chunk()\Sent < *Object_Network_Terminal\Output_Chunk()\Size
        Result = SendNetworkData(*Object_Network_Terminal\Connection_ID, *Object_Network_Terminal\Output_Chunk()\Data+*Object_Network_Terminal\Output_Chunk()\Sent, *Object_Network_Terminal\Output_Chunk()\Size-*Object_Network_Terminal\Output_Chunk()\Sent)
        If Result > 0
          *Object_Network_Terminal\Output_Chunk()\Sent + Result
        EndIf
        Break
      EndIf
    Next
    
    ; #### Receive data
    Select Network_Event
      Case #PB_NetworkEvent_None
        ProcedureReturn #False
        
      Case #PB_NetworkEvent_Data
        Temp_Size = Object_Network_Terminal_Network_Available(ConnectionID(*Object_Network_Terminal\Connection_ID))
        If Temp_Size > 0
          *Temp = AllocateMemory(Temp_Size)
          If *Temp
            LastElement(*Object_Network_Terminal\Input_Chunk())
            AddElement(*Object_Network_Terminal\Input_Chunk())
            *Object_Network_Terminal\Input_Chunk()\Start = *Object_Network_Terminal\Received
            *Object_Network_Terminal\Input_Chunk()\Data = *Temp
            *Object_Network_Terminal\Input_Chunk()\Size = Temp_Size
            *Object_Network_Terminal\Received + Temp_Size
            ReceiveNetworkData(*Object_Network_Terminal\Connection_ID, *Temp, Temp_Size)
            
            Object_Event\Type = #Object_Link_Event_Update
            Object_Event\Position = *Object_Network_Terminal\Input_Chunk()\Start
            Object_Event\Size = *Object_Network_Terminal\Input_Chunk()\Size
            Object_Output_Event(Object_Output_Get(*Object, 1), Object_Event)
            
          EndIf
        EndIf
        
      Case #PB_NetworkEvent_Disconnect
        *Object_Network_Terminal\Connection_ID = 0
        If *Object_Network_Terminal\Window
          SetGadgetText(*Object_Network_Terminal\Button_Open, "Open")
          SetGadgetState(*Object_Network_Terminal\Button_Open, #False)
        EndIf
        
    EndSelect
    
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure Object_Network_Terminal_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Network_Terminal.Object_Network_Terminal = *Object\Custom_Data
  If Not *Object_Network_Terminal
    ProcedureReturn #False
  EndIf
  
  Protected Time.q
  
  Time = ElapsedMilliseconds() + 30
  While Object_Network_Terminal_Network(*Object) And Time > ElapsedMilliseconds()
  Wend
  
  If *Object_Network_Terminal\Window_Close
    *Object_Network_Terminal\Window_Close = #False
    Object_Network_Terminal_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Network_Terminal_Main\Object_Type = Object_Type_Create()
If Object_Network_Terminal_Main\Object_Type
  Object_Network_Terminal_Main\Object_Type\Category = "Data-Source"
  Object_Network_Terminal_Main\Object_Type\Name = "Network Terminal"
  Object_Network_Terminal_Main\Object_Type\UID = "D3NETERM"
  Object_Network_Terminal_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Network_Terminal_Main\Object_Type\Date_Creation = Date(2014,03,02,12,00,00)
  Object_Network_Terminal_Main\Object_Type\Date_Modification = Date(2014,03,02,21,56,00)
  Object_Network_Terminal_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Network_Terminal_Main\Object_Type\Description = "Provides data in- and output with a network server."
  Object_Network_Terminal_Main\Object_Type\Function_Create = @Object_Network_Terminal_Create()
  Object_Network_Terminal_Main\Object_Type\Version = 1000
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 975
; FirstLine = 953
; Folding = ------
; EnableUnicode
; EnableXP