﻿; ##################################################### License / Copyright #########################################
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

; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule Node
  EnableExplicit
  ; ################################################### Constants ###################################################
  #Event_Values = 10
  
  Enumeration
    ; #### Normal events
    #Event_Save
    #Event_SaveAs
    #Event_Cut
    #Event_Copy
    #Event_Paste
    #Event_Undo
    #Event_Redo
    #Event_Goto
    #Event_Search
    #Event_Search_Continue
    #Event_Close
    
    ; #### Link events
    #Link_Event_Update_Descriptor
    #Link_Event_Update
    #Link_Event_Goto
    
  EndEnumeration
  
  ; ################################################### Structures A ################################################
  Structure Output_Segment
    Position.q
    Size.q
    
    Metadata.a
  EndStructure
  
  ; ################################################### Prototypes ##################################################
  Prototype   Function_Main(*Object)
  Prototype   Function_Delete(*Object)
  Prototype   Function_Window(*Object)
  
  Prototype   Function_Configuration_Get(*Object, *Parent_Tag.NBT::Tag)
  Prototype   Function_Configuration_Set(*Object, *Parent_Tag.NBT::Tag)
  
  Prototype   Function_Event(*Object, *Event)
  
  Prototype   Function_Link_Event(*InOut, *Event)
  
  Prototype   Function_Get_Segments(*Output, List Range.Output_Segment())
  Prototype   Function_Get_Descriptor(*Output)
  Prototype.q Function_Get_Size(*Output)
  Prototype   Function_Get_Data(*Output, Position.q, Size.i, *Data, *Metadata)
  Prototype   Function_Set_Data(*Output, Position.q, Size.i, *Data)
  Prototype   Function_Convolute(*Output, Position.q, Offset.q)
  Prototype   Function_Set_Data_Check(*Output, Position.q, Size.i)
  Prototype   Function_Convolute_Check(*Output, Position.q, Offset.q)
  
  ; ################################################### Structures B ################################################
  Structure Main
    ID_Counter.q
  EndStructure
  Global Main.Main
  
  Structure Event
    Type.l
    
    Position.q    ; Position of the event, if it has any
    Size.q        ; Size of the event, if it has any
    
    Value.q [#Event_Values]
    
    *Custom_Data
  EndStructure
  
  Structure Conn_Input
    *Object.Object
    *Linked.Conn_Output
    
    Short_Name.s
    Name.s
    
    ; #### Custom Data
    *Custom_Data
    
    i.l
    
    ; #### Functions
    Function_Event.Function_Link_Event
  EndStructure
  
  Structure Conn_Output
    *Object.Object
    List *Linked.Conn_Input()
    
    Short_Name.s
    Name.s
    Name_Inherited.s
    
    ; #### Custom Data
    *Custom_Data
    
    *Descriptor.NBT::Element
    
    i.l
    
    ; #### Functions
    Function_Event.Function_Link_Event
    
    Function_Get_Segments.Function_Get_Segments
    Function_Get_Descriptor.Function_Get_Descriptor
    Function_Get_Size.Function_Get_Size
    Function_Get_Data.Function_Get_Data
    Function_Set_Data.Function_Set_Data
    Function_Convolute.Function_Convolute
    Function_Set_Data_Check.Function_Set_Data_Check
    Function_Convolute_Check.Function_Convolute_Check
  EndStructure
  
  Structure Object
    ID.q
    Color.l
    
    Name.s
    Name_Inherited.s
    
    *Type.Node_Type::Object
    *Type_Base.Node_Type::Object
    
    ; #### Window_Objects Data
    X.d
    Y.d
    Width.d
    Height.d
    Image.i
    Redraw.l
    
    List Input.Conn_Input()
    List Output.Conn_Output()
    
    *Custom_Data ; Custom data-structure
    
    ; #### Functions
    Function_Delete.Function_Delete
    Function_Main.Function_Main
    Function_Window.Function_Window
    
    Function_Configuration_Get.Function_Configuration_Get
    Function_Configuration_Set.Function_Configuration_Set
    
    Function_Event.Function_Event
  EndStructure
  Global NewList Object.Object()
  
  ; ################################################### Functions ###################################################
  Declare   Get(ID.i)
  Declare   _Create()
  Declare   Delete(*Object.Object)
  Declare   Event(*Object.Object, *Event.Event)
  
  Declare   Input_Get(*Object.Object, i)
  Declare   Input_Add(*Object.Object, Name.s="", Short_Name.s="")
  Declare   Input_Delete(*Object.Object, *Input.Conn_Input)
  
  Declare   Output_Get(*Object.Object, i)
  Declare   Output_Add(*Object.Object, Name.s="", Short_Name.s="")
  Declare   Output_Delete(*Object.Object, *Output.Conn_Output)
  
  Declare   Link_Disconnect(*Input.Conn_Input)
  Declare   Link_Connect(*Output.Conn_Output, *Input.Conn_Input)
  
  Declare   Input_Event(*Input.Conn_Input, *Event.Event)
  Declare   Output_Event(*Output.Conn_Output, *Event.Event)
  Declare   Input_Get_Descriptor(*Input.Conn_Input)
  Declare.q Input_Get_Segments(*Input.Conn_Input, List Segment.Output_Segment())
  Declare.q Input_Get_Size(*Input.Conn_Input)
  Declare   Input_Get_Data(*Input.Conn_Input, Position.q, Size.i, *Data, *Metadata)
  Declare   Input_Set_Data(*Input.Conn_Input, Position.q, Size.i, *Data)
  Declare   Input_Convolute(*Input.Conn_Input, Position.q, Offset.q)
  Declare   Input_Set_Data_Check(*Input.Conn_Input, Position.q, Size.i)
  Declare   Input_Convolute_Check(*Input.Conn_Input, Position.q, Offset.q)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Node
  ; ################################################### Procedures ##################################################
  Procedure Get(ID.i)
    Protected *Result.Object = #Null
    
    PushListPosition(Object())
    
    ForEach Object()
      If Object()\ID = ID
        *Result = Object()
        Break
      EndIf
    Next
    
    PopListPosition(Object())
    
    ProcedureReturn *Result
  EndProcedure
  
  Procedure _Create()
    If Not AddElement(Object())
      ProcedureReturn #Null
    EndIf
    
    Object()\Redraw = #True
    Object()\Name = "Empty"
    Main\ID_Counter + 1
    Object()\ID = Main\ID_Counter
    
    ProcedureReturn Object()
  EndProcedure
  
  Procedure Delete(*Object.Object)
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\Function_Delete(*Object)
    
    ForEach *Object\Input()
      *Object\Input()\Function_Event = #Null  ; Prevent the eventhandler, of the (half) deleted object, of being called.
      Link_Disconnect(*Object\Input())
    Next
    
    ForEach *Object\Output()
      While FirstElement(*Object\Output()\Linked())
        Link_Disconnect(*Object\Output()\Linked())
      Wend
    Next
    
    If ChangeCurrentElement(Object(), *Object)
      DeleteElement(Object())
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Input_Get(*Object.Object, i)
    Protected *Input.Conn_Input
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    PushListPosition(*Object\Input())
    *Input = SelectElement(*Object\Input(), i)
    PopListPosition(*Object\Input())
    
    ProcedureReturn *Input
  EndProcedure
  
  Procedure Output_Get(*Object.Object, i)
    Protected *Output.Conn_Output
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    PushListPosition(*Object\Output())
    *Output = SelectElement(*Object\Output(), i)
    PopListPosition(*Object\Output())
    
    ProcedureReturn *Output
  EndProcedure
  
  Procedure Output_Add(*Object.Object, Name.s="", Short_Name.s="")
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    AddElement(*Object\Output())
    *Object\Output()\Object = *Object
    *Object\Output()\Name = Name
    *Object\Output()\Short_Name = Short_Name
    
    PushListPosition(*Object\Output())
    ForEach *Object\Output()
      *Object\Output()\i = ListIndex(*Object\Output())
    Next
    PopListPosition(*Object\Output())
    
    *Object\Output()\Descriptor = NBT::Element_Add()
    
    *Object\Redraw = #True
    
    ProcedureReturn *Object\Output()
  EndProcedure
  
  Procedure Input_Add(*Object.Object, Name.s="", Short_Name.s="")
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    AddElement(*Object\Input())
    *Object\Input()\Object = *Object
    *Object\Input()\Name = Name
    *Object\Input()\Short_Name = Short_Name
    
    PushListPosition(*Object\Input())
    ForEach *Object\Input()
      *Object\Input()\i = ListIndex(*Object\Input())
    Next
    PopListPosition(*Object\Input())
    
    *Object\Redraw = #True
    
    ProcedureReturn *Object\Input()
  EndProcedure
  
  Procedure Output_Delete(*Object.Object, *Output.Conn_Output)
    If Not *Object
      ProcedureReturn #False
    EndIf
    If  Not *Output
      ProcedureReturn #False
    EndIf
    
    ForEach *Output\Linked()
      Link_Disconnect(*Output\Linked())
    Next
    
    NBT::Element_Delete(*Object\Output()\Descriptor)
    
    ForEach *Object\Output()
      If *Object\Output() = *Output
        DeleteElement(*Object\Output())
        Break
      EndIf
    Next
    
    ForEach *Object\Output()
      *Object\Output()\i = ListIndex(*Object\Output())
    Next
    
    *Object\Redraw = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Input_Delete(*Object.Object, *Input.Conn_Input)
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Link_Disconnect(*Input)
    
    ForEach *Object\Input()
      If *Object\Input() = *Input
        DeleteElement(*Object\Input())
        Break
      EndIf
    Next
    
    ForEach *Object\Input()
      *Object\Input()\i = ListIndex(*Object\Input())
    Next
    
    *Object\Redraw = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Link_Disconnect(*Input.Conn_Input)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    If *Input\Linked
      ForEach *Input\Linked\Linked()
        If *Input\Linked\Linked() = *Input
          DeleteElement(*Input\Linked\Linked())
        EndIf
      Next
    EndIf
    
    *Input\Linked = #Null
    
    ; #### Send update event
    Protected Event.Event
    Event\Type = #Link_Event_Update
    Event\Position = 0
    Event\Size = 0
    If *Input\Function_Event
      *Input\Function_Event(*Input, Event)
    EndIf
    
    ; #### Send "update descriptor" event
    Protected Event_Descriptor.Event
    Event_Descriptor\Type = #Link_Event_Update_Descriptor
    If *Input\Function_Event
      *Input\Function_Event(*Input, Event_Descriptor)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Link_Connect(*Output.Conn_Output, *Input.Conn_Input)
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    If *Input\Object = *Output\Object
      ProcedureReturn #False
    EndIf
    
    If *Input\Linked
      Link_Disconnect(*Input)
    EndIf
    
    AddElement(*Output\Linked())
    *Output\Linked() = *Input
    
    *Input\Linked = *Output
    
    ; #### Send update event
    Protected Event.Event
    Event\Type = #Link_Event_Update
    Event\Position = 0
    Event\Size = *Output\Function_Get_Size(*Output)
    If *Input\Function_Event
      *Input\Function_Event(*Input, Event)
    EndIf
    
    ; #### Send "update descriptor" event
    Protected Event_Descriptor.Event
    Event_Descriptor\Type = #Link_Event_Update_Descriptor
    If *Input\Function_Event
      *Input\Function_Event(*Input, Event_Descriptor)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Event(*Input.Conn_Input, *Event.Event)
    If Not *Event
      ProcedureReturn #False
    EndIf
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Event
      ProcedureReturn *Output\Function_Event(*Output, *Event)
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object input.
  Procedure Output_Event(*Output.Conn_Output, *Event.Event)
    If Not *Event
      ProcedureReturn #False
    EndIf
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    ForEach *Output\Linked()
      If *Output\Linked()
        If *Output\Linked()\Function_Event
          *Output\Linked()\Function_Event(*Output\Linked(), *Event)
        EndIf
      EndIf
    Next
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Get_Descriptor(*Input.Conn_Input)
    If Not *Input
      ProcedureReturn #Null
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #Null
    EndIf
    
    If *Output\Function_Get_Descriptor
      ProcedureReturn *Output\Function_Get_Descriptor(*Output)
    EndIf
    
    ProcedureReturn #Null
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure.q Input_Get_Segments(*Input.Conn_Input, List Segment.Output_Segment())
    If Not *Input
      ProcedureReturn 0
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn 0
    EndIf
    
    If *Output\Function_Get_Segments
      ProcedureReturn *Output\Function_Get_Segments(*Output, Segment())
    EndIf
    
    ProcedureReturn 0
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure.q Input_Get_Size(*Input.Conn_Input)
    If Not *Input
      ProcedureReturn -1
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn -1
    EndIf
    
    If *Output\Function_Get_Size
      ProcedureReturn *Output\Function_Get_Size(*Output)
    EndIf
    
    ProcedureReturn -1
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Get_Data(*Input.Conn_Input, Position.q, Size.i, *Data, *Metadata)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Get_Data
      ProcedureReturn *Output\Function_Get_Data(*Output, Position.q, Size.i, *Data, *Metadata)
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Set_Data(*Input.Conn_Input, Position.q, Size.i, *Data)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Set_Data
      ProcedureReturn *Output\Function_Set_Data(*Output, Position.q, Size.i, *Data)
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Convolute(*Input.Conn_Input, Position.q, Offset.q)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Convolute
      ProcedureReturn *Output\Function_Convolute(*Output, Position.q, Offset)
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Set_Data_Check(*Input.Conn_Input, Position.q, Size.i)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Set_Data_Check
      ProcedureReturn *Output\Function_Set_Data_Check(*Output, Position.q, Size.i)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### This function calls the corresponding function in the others object output.
  Procedure Input_Convolute_Check(*Input.Conn_Input, Position.q, Offset.q)
    If Not *Input
      ProcedureReturn #False
    EndIf
    
    Protected *Output.Conn_Output = *Input\Linked
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    
    If *Output\Function_Convolute_Check
      ProcedureReturn *Output\Function_Convolute_Check(*Output, Position.q, Offset.q)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### This function calls the corresponding function in the object.
  Procedure Event(*Object.Object, *Event.Event)
    If Not *Event
      ProcedureReturn #False
    EndIf
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Function_Event
      ProcedureReturn *Object\Function_Event(*Object, *Event)
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 668
; FirstLine = 639
; Folding = ----
; EnableXP