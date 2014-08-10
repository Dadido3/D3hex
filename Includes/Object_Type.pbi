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

Prototype   Object_Type_Function_Create(Requester)

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure Object_Type_Main
  ID_Counter.i
EndStructure
Global Object_Type_Main.Object_Type_Main

Structure Object_Type
  ID.i
  
  UID.s {8}
  
  Name.s
  Description.s
  Category.s
  Author.s
  Date_Creation.q
  Date_Modification.q
  Date_Compilation.q
  Version.l
  
  Function_Create.Object_Type_Function_Create
EndStructure
Global NewList Object_Type.Object_Type()

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Procedures ##################################################

Procedure Object_Type_Get_UID(UID.s)
  Protected *Result.Object_Type = #Null
  
  PushListPosition(Object_Type())
  
  ForEach Object_Type()
    If Object_Type()\UID = UID
      *Result = Object_Type()
      Break
    EndIf
  Next
  
  PopListPosition(Object_Type())
  
  ProcedureReturn *Result
EndProcedure

Procedure Object_Type_Get(ID.i)
  Protected *Result.Object_Type = #Null
  
  PushListPosition(Object_Type())
  
  ForEach Object_Type()
    If Object_Type()\ID = ID
      *Result = Object_Type()
      Break
    EndIf
  Next
  
  PopListPosition(Object_Type())
  
  ProcedureReturn *Result
EndProcedure

Procedure Object_Type_Create()
  If Not AddElement(Object_Type())
    ProcedureReturn #Null
  EndIf
  
  Object_Type()\Name = "Empty"
  Object_Type_Main\ID_Counter + 1
  Object_Type()\ID = Object_Type_Main\ID_Counter
  
  ProcedureReturn Object_Type()
EndProcedure

Procedure Object_Type_Delete(*Object_Type.Object_Type)
  If Not *Object_Type
    ProcedureReturn #False
  EndIf
  
  If ChangeCurrentElement(Object_Type(), *Object_Type)
    DeleteElement(Object_Type())
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 18
; Folding = -
; EnableUnicode
; EnableXP