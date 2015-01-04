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

; ##################################################### Structures A ################################################

Structure Object_Output_Segment
  Position.q
  Size.q
  
  Metadata.a
EndStructure

; ##################################################### Prototypes ##################################################

Prototype   Object_Function_Main(*Object)
Prototype   Object_Function_Delete(*Object)
Prototype   Object_Function_Window(*Object)

Prototype   Object_Function_Configuration_Get(*Object, *Parent_Tag.NBT_Tag)
Prototype   Object_Function_Configuration_Set(*Object, *Parent_Tag.NBT_Tag)

Prototype   Object_Function_Event(*Object, *Object_Event)

Prototype   Object_Function_Link_Event(*Object_InOut, *Object_Event)

Prototype   Object_Function_Get_Segments(*Object_Output, List Range.Object_Output_Segment())
Prototype   Object_Function_Get_Descriptor(*Object_Output)
Prototype.q Object_Function_Get_Size(*Object_Output)
Prototype   Object_Function_Get_Data(*Object_Output, Position.q, Size.i, *Data, *Metadata)
Prototype   Object_Function_Set_Data(*Object_Output, Position.q, Size.i, *Data)
Prototype   Object_Function_Convolute(*Object_Output, Position.q, Offset.q)
Prototype   Object_Function_Set_Data_Check(*Object_Output, Position.q, Size.i)
Prototype   Object_Function_Convolute_Check(*Object_Output, Position.q, Offset.q)

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

#Object_Event_Values = 10

Enumeration
  ; #### Normal events
  #Object_Event_Save
  #Object_Event_SaveAs
  #Object_Event_Cut
  #Object_Event_Copy
  #Object_Event_Paste
  #Object_Event_Undo
  #Object_Event_Redo
  #Object_Event_Goto
  #Object_Event_Search
  #Object_Event_Search_Continue
  #Object_Event_Close
  
  ; #### Link events
  #Object_Link_Event_Update
  #Object_Link_Event_Goto
  
EndEnumeration

; ##################################################### Structures B ################################################

Structure Object_Main
  ID_Counter.q
EndStructure
Global Object_Main.Object_Main

Structure Object_Event
  Type.l
  
  Position.q    ; Position of the event, if it has any
  Size.q        ; Size of the event, if it has any
  
  Value.q [#Object_Event_Values]
  
  *Custom_Data
EndStructure

Structure Object_Input
  *Object.Object
  *Linked.Object_Output
  
  Short_Name.s
  Name.s
  
  ; #### Custom Data
  *Custom_Data
  
  i.l
  
  ; #### Functions
  Function_Event.Object_Function_Link_Event
EndStructure

Structure Object_Output
  *Object.Object
  List *Linked.Object_Input()
  
  Short_Name.s
  Name.s
  
  ; #### Custom Data
  *Custom_Data
  
  *Descriptor.NBT_Element
  
  i.l
  
  ; #### Functions
  Function_Event.Object_Function_Link_Event
  
  Function_Get_Segments.Object_Function_Get_Segments
  Function_Get_Descriptor.Object_Function_Get_Descriptor
  Function_Get_Size.Object_Function_Get_Size
  Function_Get_Data.Object_Function_Get_Data
  Function_Set_Data.Object_Function_Set_Data
  Function_Convolute.Object_Function_Convolute
  Function_Set_Data_Check.Object_Function_Set_Data_Check
  Function_Convolute_Check.Object_Function_Convolute_Check
EndStructure

Structure Object
  ID.q
  Name.s
  Color.l
  
  *Type.Object_Type
  *Type_Base.Object_Type
  
  ; #### Window_Objects Data
  X.d
  Y.d
  Width.d
  Height.d
  Image.i
  Redraw.l
  
  List Input.Object_Input()
  List Output.Object_Output()
  
  *Custom_Data ; Custom data-structure
  
  ; #### Functions
  Function_Delete.Object_Function_Delete
  Function_Main.Object_Function_Main
  Function_Window.Object_Function_Window
  
  Function_Configuration_Get.Object_Function_Configuration_Get
  Function_Configuration_Set.Object_Function_Configuration_Set
  
  Function_Event.Object_Function_Event
EndStructure
Global NewList Object.Object()

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   Object_Link_Disconnect(*Object_Input.Object_Input)
Declare   Object_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

; ##################################################### Procedures ##################################################

Procedure Object_Get(ID.i)
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

Procedure _Object_Create()
  If Not AddElement(Object())
    ProcedureReturn #Null
  EndIf
  
  Object()\Redraw = #True
  Object()\Name = "Empty"
  Object_Main\ID_Counter + 1
  Object()\ID = Object_Main\ID_Counter
  
  ProcedureReturn Object()
EndProcedure

Procedure Object_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Function_Delete(*Object)
  
  ForEach *Object\Input()
    *Object\Input()\Function_Event = #Null  ; Prevent the eventhandler, of the (half) deleted object, of being called.
    Object_Link_Disconnect(*Object\Input())
  Next
  
  ForEach *Object\Output()
    While FirstElement(*Object\Output()\Linked())
      Object_Link_Disconnect(*Object\Output()\Linked())
    Wend
  Next
  
  If ChangeCurrentElement(Object(), *Object)
    DeleteElement(Object())
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Input_Get(*Object.Object, i)
  Protected *Object_Input.Object_Input
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  PushListPosition(*Object\Input())
  *Object_Input = SelectElement(*Object\Input(), i)
  PopListPosition(*Object\Input())
  
  ProcedureReturn *Object_Input
EndProcedure

Procedure Object_Output_Get(*Object.Object, i)
  Protected *Object_Output.Object_Output
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  PushListPosition(*Object\Output())
  *Object_Output = SelectElement(*Object\Output(), i)
  PopListPosition(*Object\Output())
  
  ProcedureReturn *Object_Output
EndProcedure

Procedure Object_Output_Add(*Object.Object, Name.s="", Short_Name.s="")
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
  
  *Object\Output()\Descriptor = NBT_Element_Add()
  
  *Object\Redraw = #True
  
  ProcedureReturn *Object\Output()
EndProcedure

Procedure Object_Input_Add(*Object.Object, Name.s="", Short_Name.s="")
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

Procedure Object_Output_Delete(*Object.Object, *Object_Output.Object_Output)
  If Not *Object
    ProcedureReturn #False
  EndIf
  If  Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  ForEach *Object_Output\Linked()
    Object_Link_Disconnect(*Object_Output\Linked())
  Next
  
  NBT_Element_Delete(*Object\Output()\Descriptor)
  
  ForEach *Object\Output()
    If *Object\Output() = *Object_Output
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

Procedure Object_Input_Delete(*Object.Object, *Object_Input.Object_Input)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Object_Link_Disconnect(*Object_Input)
  
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
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

Procedure Object_Link_Disconnect(*Object_Input.Object_Input)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  If *Object_Input\Linked
    ForEach *Object_Input\Linked\Linked()
      If *Object_Input\Linked\Linked() = *Object_Input
        DeleteElement(*Object_Input\Linked\Linked())
      EndIf
    Next
  EndIf
  
  *Object_Input\Linked = #Null
  
  ; #### Send update event
  Protected Object_Event.Object_Event
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = 0
  If *Object_Input\Function_Event
    *Object_Input\Function_Event(*Object_Input, Object_Event)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Link_Connect(*Object_Output.Object_Output, *Object_Input.Object_Input)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  If *Object_Input\Object = *Object_Output\Object
    ProcedureReturn #False
  EndIf
  
  If *Object_Input\Linked
    Object_Link_Disconnect(*Object_Input)
  EndIf
  
  AddElement(*Object_Output\Linked())
  *Object_Output\Linked() = *Object_Input
  
  *Object_Input\Linked = *Object_Output
  
  ; #### Send update event
  Protected Object_Event.Object_Event
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = 0
  Object_Event\Size = *Object_Output\Function_Get_Size(*Object_Output)
  If *Object_Input\Function_Event
    *Object_Input\Function_Event(*Object_Input, Object_Event)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Event
    ProcedureReturn *Object_Output\Function_Event(*Object_Output, *Object_Event)
  EndIf
  
  ProcedureReturn #False
EndProcedure

; #### This function calls the corresponding function in the others object input.
Procedure Object_Output_Event(*Object_Output.Object_Output, *Object_Event.Object_Event)
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  ForEach *Object_Output\Linked()
    If *Object_Output\Linked()
      If *Object_Output\Linked()\Function_Event
        *Object_Output\Linked()\Function_Event(*Object_Output\Linked(), *Object_Event)
      EndIf
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Get_Descriptor(*Object_Input.Object_Input)
  If Not *Object_Input
    ProcedureReturn #Null
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  
  If *Object_Output\Function_Get_Descriptor
    ProcedureReturn *Object_Output\Function_Get_Descriptor(*Object_Output)
  EndIf
  
  ProcedureReturn #Null
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure.q Object_Input_Get_Segments(*Object_Input.Object_Input, List Segment.Object_Output_Segment())
  If Not *Object_Input
    ProcedureReturn 0
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn 0
  EndIf
  
  If *Object_Output\Function_Get_Segments
    ProcedureReturn *Object_Output\Function_Get_Segments(*Object_Output, Segment())
  EndIf
  
  ProcedureReturn 0
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure.q Object_Input_Get_Size(*Object_Input.Object_Input)
  If Not *Object_Input
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  
  If *Object_Output\Function_Get_Size
    ProcedureReturn *Object_Output\Function_Get_Size(*Object_Output)
  EndIf
  
  ProcedureReturn -1
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Get_Data(*Object_Input.Object_Input, Position.q, Size.i, *Data, *Metadata)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Get_Data
    ProcedureReturn *Object_Output\Function_Get_Data(*Object_Output, Position.q, Size.i, *Data, *Metadata)
  EndIf
  
  ProcedureReturn #False
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Set_Data(*Object_Input.Object_Input, Position.q, Size.i, *Data)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Set_Data
    ProcedureReturn *Object_Output\Function_Set_Data(*Object_Output, Position.q, Size.i, *Data)
  EndIf
  
  ProcedureReturn #False
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Convolute(*Object_Input.Object_Input, Position.q, Offset.q)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Convolute
    ProcedureReturn *Object_Output\Function_Convolute(*Object_Output, Position.q, Offset)
  EndIf
  
  ProcedureReturn #False
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Set_Data_Check(*Object_Input.Object_Input, Position.q, Size.i)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Set_Data_Check
    ProcedureReturn *Object_Output\Function_Set_Data_Check(*Object_Output, Position.q, Size.i)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; #### This function calls the corresponding function in the others object output.
Procedure Object_Input_Convolute_Check(*Object_Input.Object_Input, Position.q, Offset.q)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Output.Object_Output = *Object_Input\Linked
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  
  If *Object_Output\Function_Convolute_Check
    ProcedureReturn *Object_Output\Function_Convolute_Check(*Object_Output, Position.q, Offset.q)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; #### This function calls the corresponding function in the object.
Procedure Object_Event(*Object.Object, *Object_Event.Object_Event)
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  If *Object\Function_Event
    ProcedureReturn *Object\Function_Event(*Object, *Object_Event)
  EndIf
  
  ProcedureReturn #False
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 3
; Folding = ----
; EnableXP