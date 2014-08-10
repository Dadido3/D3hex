
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


; IDE Options = PureBasic 5.22 LTS (Windows - x64)
; CursorPosition = 14
; Folding = -
; EnableUnicode
; EnableXP