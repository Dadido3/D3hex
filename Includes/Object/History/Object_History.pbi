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
  #Object_History_Operation_Type_Write
  #Object_History_Operation_Type_Convolute
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_History_Main
  *Object_Type.Object_Type
EndStructure
Global Object_History_Main.Object_History_Main

Structure Object_History_Operation
  Type.i
  
  Position.q
  *Data               ; For write operations
  Data_Size.i         ; For write operations
  
  Offset.q            ; For convolution operations
  
  Temp_Size_Before.q  ; Temporary object-size before the operation
  Temp_Size.q         ; Temporary object-size after the operation
EndStructure

Structure Object_History_Recursive_Window
  Source_Position.q
  Dest_Position.i
  
  Size.i
  
  *Current_Operation.Object_History_Operation
EndStructure

Structure Object_History
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Text.i
  CheckBox.i
  
  Update.l
  
  ; #### History stuff
  
  Always_Writable.l
  
  List Operation_Past.Object_History_Operation()    ; All virtual operations made to the input-data
  List Operation_Future.Object_History_Operation()  ; Available redo operations
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Init ########################################################

Global Object_History_Font = LoadFont(#PB_Any, "Courier New", 10)

; ##################################################### Declares ####################################################

Declare.q Object_History_Recalculate_Past_Size(*Object.Object)

Declare   Object_History_Main(*Object.Object)
Declare   _Object_History_Delete(*Object.Object)
Declare   Object_History_Window_Open(*Object.Object)

Declare   Object_History_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_History_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_History_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
Declare   Object_History_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)

Declare   Object_History_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
Declare   Object_History_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_History_Get_Size(*Object_Output.Object_Output)
Declare   Object_History_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_History_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_History_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
Declare   Object_History_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
Declare   Object_History_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)

Declare   Object_History_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_History_Undo(*Object.Object, Combine=#False)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  Protected Combine_End
  
  While LastElement(*Object_History\Operation_Past())
    
    FirstElement(*Object_History\Operation_Future())
    If InsertElement(*Object_History\Operation_Future())
      CopyStructure(*Object_History\Operation_Past(), *Object_History\Operation_Future(), Object_History_Operation)
      DeleteElement(*Object_History\Operation_Past())
      
      Object_Event\Type = #Object_Link_Event_Goto
      Object_Event\Position = *Object_History\Operation_Future()\Position
      Object_Event\Size = 0
      Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
      
      Select *Object_History\Operation_Future()\Type
        Case #Object_History_Operation_Type_Write
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = *Object_History\Operation_Future()\Position
          Object_Event\Size = *Object_History\Operation_Future()\Data_Size
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          Combine_End = #True
        Case #Object_History_Operation_Type_Convolute
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = *Object_History\Operation_Future()\Position
          Object_Event\Size = Object_History_Recalculate_Past_Size(*Object) - *Object_History\Operation_Future()\Position
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          If *Object_History\Operation_Future()\Offset < 0
            Combine_End = #True
          EndIf
      EndSelect
      
    EndIf
    
    ; #### 
    If LastElement(*Object_History\Operation_Past())
      If Combine_End 
        If *Object_History\Operation_Past()\Type = #Object_History_Operation_Type_Write
          Break
        ElseIf *Object_History\Operation_Past()\Type = #Object_History_Operation_Type_Convolute And *Object_History\Operation_Past()\Offset < 0
          Break
        EndIf
      EndIf
    EndIf
    If Not Combine
      Break
    EndIf
  Wend
  
  *Object_History\Update = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Redo(*Object.Object, Combine=#False)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  
  While FirstElement(*Object_History\Operation_Future())
    
    LastElement(*Object_History\Operation_Past())
    If AddElement(*Object_History\Operation_Past())
      CopyStructure(*Object_History\Operation_Future(), *Object_History\Operation_Past(), Object_History_Operation)
      DeleteElement(*Object_History\Operation_Future())
      
      Object_Event\Type = #Object_Link_Event_Goto
      Object_Event\Position = *Object_History\Operation_Past()\Position + *Object_History\Operation_Past()\Data_Size
      Object_Event\Size = 0
      Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
      
      Select *Object_History\Operation_Past()\Type
        Case #Object_History_Operation_Type_Write
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = *Object_History\Operation_Past()\Position
          Object_Event\Size = *Object_History\Operation_Past()\Data_Size
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          Break
        Case #Object_History_Operation_Type_Convolute
          Object_Event\Type = #Object_Link_Event_Update
          Object_Event\Position = *Object_History\Operation_Past()\Position
          Object_Event\Size = Object_History_Recalculate_Past_Size(*Object) - *Object_History\Operation_Past()\Position
          Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
          If *Object_History\Operation_Past()\Offset < 0
            Break
          EndIf
      EndSelect
      
    EndIf
    
    ; #### 
    If Not Combine
      Break
    EndIf
  Wend
  
  *Object_History\Update = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Redo_Clear(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  *Object_History\Update = #True
  
  ClearList(*Object_History\Operation_Future())
  
  ProcedureReturn #True
EndProcedure

Procedure.q Object_History_Recalculate_Past_Size(*Object.Object)
  If Not *Object
    ProcedureReturn -1
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn -1
  EndIf
  
  Protected Temp_Size.q = Object_Input_Get_Size(FirstElement(*Object\Input()))
  
  PushListPosition(*Object_History\Operation_Past())
  
  ForEach *Object_History\Operation_Past()
    *Object_History\Operation_Past()\Temp_Size_Before = Temp_Size
    If *Object_History\Operation_Past()\Position >= 0 And *Object_History\Operation_Past()\Position <= Temp_Size
      Select *Object_History\Operation_Past()\Type
        Case #Object_History_Operation_Type_Write
          If Temp_Size < *Object_History\Operation_Past()\Position + *Object_History\Operation_Past()\Data_Size
            Temp_Size = *Object_History\Operation_Past()\Position + *Object_History\Operation_Past()\Data_Size
          EndIf
          
        Case #Object_History_Operation_Type_Convolute
          Temp_Size + *Object_History\Operation_Past()\Offset
          If Temp_Size < *Object_History\Operation_Past()\Position
            Temp_Size = *Object_History\Operation_Past()\Position
          EndIf
          
      EndSelect
    EndIf
    *Object_History\Operation_Past()\Temp_Size = Temp_Size
  Next
  
  PopListPosition(*Object_History\Operation_Past())
  
  ProcedureReturn Temp_Size
EndProcedure

Procedure Object_History_Write(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Object_History_Redo_Clear(*Object)
  
  While FirstElement(*Object_History\Operation_Past())
    Select *Object_History\Operation_Past()\Type
      Case #Object_History_Operation_Type_Write
        If Not Object_Input_Set_Data(FirstElement(*Object\Input()), *Object_History\Operation_Past()\Position, *Object_History\Operation_Past()\Data_Size, *Object_History\Operation_Past()\Data)
          Logging_Entry_Add_Error("Write failed", "Couldn't write to the destination. Aborting write process.")
          ProcedureReturn #False
        EndIf
        
      Case #Object_History_Operation_Type_Convolute
        If Not Object_Input_Convolute(FirstElement(*Object\Input()), *Object_History\Operation_Past()\Position, *Object_History\Operation_Past()\Offset)
          Logging_Entry_Add_Error("Convolute failed", "Couldn't convolute the destination. Aborting write process.")
          ProcedureReturn #False
        EndIf
        
      Default
        Logging_Entry_Add_Error("Unkown operation in the history", "If you see this, something really went wrong here!")
        ProcedureReturn #False
        
    EndSelect
    
    DeleteElement(*Object_History\Operation_Past())
  Wend
  
  *Object_History\Update = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_History.Object_History
  Protected *Object_Input.Object_Input
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_History_Main\Object_Type
  *Object\Type_Base = Object_History_Main\Object_Type
  
  *Object\Function_Delete = @_Object_History_Delete()
  *Object\Function_Main = @Object_History_Main()
  *Object\Function_Window = @Object_History_Window_Open()
  *Object\Function_Configuration_Get = @Object_History_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_History_Configuration_Set()
  
  *Object\Name = "History"
  *Object\Color = RGBA(127,100,50,255)
  
  *Object\Custom_Data = AllocateStructure(Object_History)
  *Object_History = *Object\Custom_Data
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Function_Event = @Object_History_Input_Event()
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Event = @Object_History_Output_Event()
  *Object_Output\Function_Get_Segments = @Object_History_Get_Segments()
  *Object_Output\Function_Get_Descriptor = @Object_History_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_History_Get_Size()
  *Object_Output\Function_Get_Data = @Object_History_Get_Data()
  *Object_Output\Function_Set_Data = @Object_History_Set_Data()
  *Object_Output\Function_Convolute = @Object_History_Convolute()
  *Object_Output\Function_Set_Data_Check = @Object_History_Set_Data_Check()
  *Object_Output\Function_Convolute_Check = @Object_History_Convolute_Check()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_History_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Object_History_Window_Close(*Object)
  
  ; #### Free the data of all events
  ForEach *Object_History\Operation_Past()
    If *Object_History\Operation_Past()\Data
      FreeMemory(*Object_History\Operation_Past()\Data)
      *Object_History\Operation_Past()\Data = #Null
    EndIf
  Next
  ForEach *Object_History\Operation_Future()
    If *Object_History\Operation_Future()\Data
      FreeMemory(*Object_History\Operation_Future()\Data)
      *Object_History\Operation_Future()\Data = #Null
    EndIf
  Next
  
  FreeStructure(*Object_History)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Always_Writable", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_History\Always_Writable)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Always_Writable") : *Object_History\Always_Writable = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  ;Select *Object_Event\Type
  ;  Default
      ; #### Todo: Correct the event-range!!!
      Object_Output_Event(FirstElement(*Object\Output()), *Object_Event)
      
  ;EndSelect
  
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Event_Undo
      Object_History_Undo(*Object, *Object_Event\Value[0])
      
    Case #Object_Event_Redo
      Object_History_Redo(*Object, *Object_Event\Value[0])
      
    Case #Object_Event_Save
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      Object_History_Write(*Object)
      
    Case #Object_Event_SaveAs
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      Object_History_Write(*Object)
      
    Default
      ; #### Todo: Correct the event-range!!!
      Object_Input_Event(FirstElement(*Object\Input()), *Object_Event)
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Get_Segments(*Object_Output.Object_Output, List Segment.Object_Output_Segment())
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn Object_Input_Get_Segments(FirstElement(*Object\Input()), Segment())
EndProcedure

Procedure Object_History_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #Null
  EndIf
  
  ProcedureReturn Object_Input_Get_Descriptor(FirstElement(*Object\Input()))
EndProcedure

Procedure.q Object_History_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn Object_History_Recalculate_Past_Size(*Object)
EndProcedure

Procedure Object_History_Get_Data_Recursively(*Object.Object, Position.q, Size.i, *Data, *Metadata)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Protected NewList Window.Object_History_Recursive_Window()
  Protected *Current_Operation.Object_history_Operation, *Previous_Operation.Object_history_Operation
  Protected *Temp_Data, *Temp_Metadata
  Protected Temp_Position_A.q, Temp_Position_B.q, Temp_Position_C.q
  Protected Temp_Size_A.q, Temp_Size_B.q, Temp_Size_C.q
  Protected Temp_A.q, Temp_B.q, Temp_C.q
  
  AddElement(Window())
  Window()\Current_Operation = LastElement(*Object_History\Operation_Past())
  Window()\Source_Position = Position
  Window()\Dest_Position = 0  ; Relative from *Data and *Metadata
  Window()\Size = Size
  
  While FirstElement(Window())
    *Current_Operation = Window()\Current_Operation
    If *Current_Operation
      ChangeCurrentElement(*Object_History\Operation_Past(), *Current_Operation)
    EndIf
    
    Repeat
      If *Current_Operation
        *Previous_Operation = PreviousElement(*Object_History\Operation_Past())
        
        ; #### Check if Operation is valid
        If *Current_Operation\Position >= 0 And *Current_Operation\Position <= *Current_Operation\Temp_Size_Before
          Select *Current_Operation\Type
            Case #Object_History_Operation_Type_Write
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
              
            Case #Object_History_Operation_Type_Convolute
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
        Object_Input_Get_Data(FirstElement(*Object\Input()), Window()\Source_Position, Window()\Size, *Temp_Data, *Temp_Metadata)
        DeleteElement(Window())
        Break
      EndIf
      *Current_Operation = *Previous_Operation
    ForEver
    
  Wend
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
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
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Object_History_Recalculate_Past_Size(*Object)
  
  Object_History_Get_Data_Recursively(*Object, Position, Size, *Data, *Metadata)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Set_Data_Check_Recursively(*Object.Object, Position.q, Size.i)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Protected NewList Window.Object_History_Recursive_Window()
  Protected *Current_Operation.Object_history_Operation, *Previous_Operation.Object_history_Operation
  Protected Temp_Position_A.q, Temp_Position_B.q, Temp_Position_C.q
  Protected Temp_Size_A.q, Temp_Size_B.q, Temp_Size_C.q
  Protected Temp_A.q, Temp_B.q, Temp_C.q
  
  AddElement(Window())
  Window()\Current_Operation = LastElement(*Object_History\Operation_Past())
  Window()\Source_Position = Position
  Window()\Size = Size
  
  While FirstElement(Window())
    *Current_Operation = Window()\Current_Operation
    If *Current_Operation
      ChangeCurrentElement(*Object_History\Operation_Past(), *Current_Operation)
    EndIf
    
    Repeat
      If *Current_Operation
        *Previous_Operation = PreviousElement(*Object_History\Operation_Past())
        
        ; #### Check if Operation is valid
        If *Current_Operation\Position >= 0 And *Current_Operation\Position <= *Current_Operation\Temp_Size_Before
          Select *Current_Operation\Type
            Case #Object_History_Operation_Type_Convolute
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
        If Not Object_Input_Set_Data_Check(FirstElement(*Object\Input()), Window()\Source_Position, Window()\Size)
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

Procedure Object_History_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
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
  
  Protected Object_Event.Object_Event
  
  Object_History_Recalculate_Past_Size(*Object)
  
  If Not *Object_History\Always_Writable And Not Object_History_Set_Data_Check_Recursively(*Object, Position, Size)
    ProcedureReturn #False
  EndIf
  
  LastElement(*Object_History\Operation_Past())
  AddElement(*Object_History\Operation_Past())
  *Object_History\Operation_Past()\Type = #Object_History_Operation_Type_Write
  *Object_History\Operation_Past()\Position = Position
  *Object_History\Operation_Past()\Data = AllocateMemory(Size)
  *Object_History\Operation_Past()\Data_Size = Size
  
  *Object_History\Update = #True
  
  CopyMemory(*Data, *Object_History\Operation_Past()\Data, Size)
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = Position
  Object_Event\Size = Size
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  Object_History_Redo_Clear(*Object)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Convolute_Check_Recursively(*Object.Object, Position.q, Offset.q)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  If LastElement(*Object_History\Operation_Past())
    Repeat
      ; #### Check if Operation is valid
      If *Object_History\Operation_Past()\Position >= 0 And *Object_History\Operation_Past()\Position <= *Object_History\Operation_Past()\Temp_Size_Before
        Select *Object_History\Operation_Past()\Type
          Case #Object_History_Operation_Type_Convolute
            ; #### Check if Operation is inside the window
            If *Object_History\Operation_Past()\Position <= Position
              Position - *Object_History\Operation_Past()\Offset
              If Position < *Object_History\Operation_Past()\Position
                Position = *Object_History\Operation_Past()\Position
              EndIf
            EndIf
            
        EndSelect
      EndIf
    Until Not PreviousElement(*Object_History\Operation_Past())
  EndIf
  
  ProcedureReturn Object_Input_Convolute_Check(FirstElement(*Object\Input()), Position, Offset)
EndProcedure

Procedure Object_History_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Protected Object_Event.Object_Event
  
  Object_History_Recalculate_Past_Size(*Object)
  
  If Not *Object_History\Always_Writable And Not Object_History_Convolute_Check_Recursively(*Object, Position, Offset)
    ProcedureReturn #False
  EndIf
  
  LastElement(*Object_History\Operation_Past())
  AddElement(*Object_History\Operation_Past())
  *Object_History\Operation_Past()\Type = #Object_History_Operation_Type_Convolute
  *Object_History\Operation_Past()\Position = Position
  *Object_History\Operation_Past()\Offset = Offset
  
  *Object_History\Update = #True
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = Position
  Object_Event\Size = Object_History_Recalculate_Past_Size(*Object) - Position
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  Object_History_Redo_Clear(*Object)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_History_Set_Data_Check(*Object_Output.Object_Output, Position.q, Size.i)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Object_History_Recalculate_Past_Size(*Object)
  
  If *Object_History\Always_Writable
    ProcedureReturn #True
  Else
    ProcedureReturn Object_History_Set_Data_Check_Recursively(*Object, Position, Size)
  EndIf
EndProcedure

Procedure Object_History_Convolute_Check(*Object_Output.Object_Output, Position.q, Offset.q)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  Object_History_Recalculate_Past_Size(*Object)
  
  If *Object_History\Always_Writable
    ProcedureReturn #True
  Else
    ProcedureReturn Object_History_Convolute_Check_Recursively(*Object, Position, Offset)
  EndIf
EndProcedure

Procedure Object_History_Window_Update(*Object.Object)
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn 
  EndIf
  
  Protected Text.s
  
  Text + "Past Operations:   "+ListSize(*Object_History\Operation_Past()) + #CRLF$
  Text + "Future Operations: "+ListSize(*Object_History\Operation_Future()) + #CRLF$
  
  SetGadgetText(*Object_History\Text, Text)
  
  SetGadgetState(*Object_History\CheckBox, *Object_History\Always_Writable)
  
EndProcedure

Procedure Object_History_Window_Event_CheckBox_0()
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn 
  EndIf
  
  *Object_History\Always_Writable = GetGadgetState(*Object_History\CheckBox)
  
EndProcedure

Procedure Object_History_Window_Event_SizeWindow()
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn 
  EndIf
  
  ;ResizeGadget(*Object_History\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
  ;ResizeGadget(*Object_History\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
  
EndProcedure

Procedure Object_History_Window_Event_ActivateWindow()
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn 
  EndIf
  
EndProcedure

Procedure Object_History_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_History_Window_Event_CloseWindow()
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
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn 
  EndIf
  
  ;Object_History_Window_Close(*Object)
  *Object_History\Window_Close = #True
EndProcedure

Procedure Object_History_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  If Not *Object_History\Window
    
    Width = 300
    Height = 80
    
    *Object_History\Window = Window_Create(*Object, "History", "History", #False, 0, 0, Width, Height)
    
    ; #### Gadgets
    *Object_History\Text = TextGadget(#PB_Any, 10, 10, Width-20, Height-40, "")
    *Object_History\CheckBox = CheckBoxGadget(#PB_Any, 10, Height-30, Width-20, 20, "Always writable")
    
    SetGadgetFont(*Object_History\Text, FontID(Object_History_Font))
    
    *Object_History\Update = #True
    
    BindEvent(#PB_Event_SizeWindow, @Object_History_Window_Event_SizeWindow(), *Object_History\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_History_Window_Event_Menu(), *Object_History\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_History_Window_Event_CloseWindow(), *Object_History\Window\ID)
    BindGadgetEvent(*Object_History\CheckBox, @Object_History_Window_Event_CheckBox_0())
    
  Else
    Window_Set_Active(*Object_History\Window)
  EndIf
EndProcedure

Procedure Object_History_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  If *Object_History\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_History_Window_Event_SizeWindow(), *Object_History\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_History_Window_Event_Menu(), *Object_History\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_History_Window_Event_CloseWindow(), *Object_History\Window\ID)
    UnbindGadgetEvent(*Object_History\CheckBox, @Object_History_Window_Event_CheckBox_0())
    
    Window_Delete(*Object_History\Window)
    *Object_History\Window = #Null
  EndIf
EndProcedure

Procedure Object_History_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_History.Object_History = *Object\Custom_Data
  If Not *Object_History
    ProcedureReturn #False
  EndIf
  
  If *Object_History\Window
    If *Object_History\Update
      *Object_History\Update = #False
      Object_HIstory_Window_Update(*Object)
    EndIf
  EndIf
  
  If *Object_History\Window_Close
    *Object_History\Window_Close = #False
    Object_History_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_History_Main\Object_Type = Object_Type_Create()
If Object_History_Main\Object_Type
  Object_History_Main\Object_Type\Category = "Structure"
  Object_History_Main\Object_Type\Name = "History"
  Object_History_Main\Object_Type\UID = "D3__HIST"
  Object_History_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_History_Main\Object_Type\Date_Creation = Date(2014,02,17,17,24,00)
  Object_History_Main\Object_Type\Date_Modification = Date(2014,03,01,20,18,00)
  Object_History_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_History_Main\Object_Type\Description = "Manages the history of the data."
  Object_History_Main\Object_Type\Function_Create = @Object_History_Create()
  Object_History_Main\Object_Type\Version = 1010
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 982
; FirstLine = 964
; Folding = ------
; EnableXP