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
; Can handle up to $7FFFFFFFFFFFFFFF bytes of data
; 
; 
; 
; 
; 
; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure Object_Editor_Goto
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  Frame.i
  Text.i[10]
  String.i[10]
  Button_Goto.i
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Declares ####################################################

Declare   Object_Editor_Goto_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Editor_Goto_Window_Event_Button_Goto()
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
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn
  EndIf
  Protected *Object_Editor_Goto.Object_Editor_Goto = *Object_Editor\Window_Goto
  If Not *Object_Editor_Goto
    ProcedureReturn
  EndIf
  
  Protected Select_Start.q = -1
  Protected Select_End.q = -1
  
  If GetGadgetText(*Object_Editor_Goto\String[0])
    Select_Start = Val(GetGadgetText(*Object_Editor_Goto\String[0]))
  ElseIf GetGadgetText(*Object_Editor_Goto\String[1])
    Select_Start = Val(GetGadgetText(*Object_Editor_Goto\String[1]))
  Else
    Select_Start = *Object_Editor\Select_Start
  EndIf
  
  If GetGadgetText(*Object_Editor_Goto\String[1])
    Select_End = Val(GetGadgetText(*Object_Editor_Goto\String[1]))
  ElseIf GetGadgetText(*Object_Editor_Goto\String[0])
    Select_End = Val(GetGadgetText(*Object_Editor_Goto\String[0]))
  Else
    Select_End = *Object_Editor\Select_End
  EndIf
  
  If Select_Start < 0
    Select_Start = 0
  EndIf
  If Select_End < 0
    Select_End = 0
  EndIf
  If Select_Start > *Object_Editor\Data_Size
    Select_Start = *Object_Editor\Data_Size
  EndIf
  If Select_End > *Object_Editor\Data_Size
    Select_End = *Object_Editor\Data_Size
  EndIf
  
  Object_Editor_Range_Set(*Object, Select_Start, Select_End, #False, #True)
  
EndProcedure

Procedure Object_Editor_Goto_Window_Event_CloseWindow()
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
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn
  EndIf
  Protected *Object_Editor_Goto.Object_Editor_Goto = *Object_Editor\Window_Goto
  If Not *Object_Editor_Goto
    ProcedureReturn
  EndIf
  
  ;Object_Editor_Goto_Window_Close(*Object)
  *Object_Editor_Goto\Window_Close = #True
EndProcedure

Procedure Object_Editor_Goto_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor_Goto.Object_Editor_Goto = *Object_Editor\Window_Goto
  If Not *Object_Editor_Goto
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Editor_Goto\Window
    
    Width = 270
    Height = 130
    
    *Object_Editor_Goto\Window = Window_Create(*Object, "Editor_Goto", "Editor_Goto", #False, 0, 0, Width, Height, #False)
    
    ; #### Gadgets
    *Object_Editor_Goto\Frame = FrameGadget(#PB_Any, 10, 10, Width-20, 70, "Position")
    *Object_Editor_Goto\Text[0] = TextGadget(#PB_Any, 20, 30, 50, 20, "Start:", #PB_Text_Right)
    *Object_Editor_Goto\Text[1] = TextGadget(#PB_Any, 20, 50, 50, 20, "End:", #PB_Text_Right)
    *Object_Editor_Goto\String[0] = StringGadget(#PB_Any, 80, 30, Width-100, 20, Str(*Object_Editor\Select_Start))
    *Object_Editor_Goto\String[1] = StringGadget(#PB_Any, 80, 50, Width-100, 20, Str(*Object_Editor\Select_End))
    If *Object_Editor\Select_Start = *Object_Editor\Select_End
      SetGadgetText(*Object_Editor_Goto\String[1], "")
    EndIf
    *Object_Editor_Goto\Button_Goto = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "Goto")
    
    BindGadgetEvent(*Object_Editor_Goto\Button_Goto, @Object_Editor_Goto_Window_Event_Button_Goto())
    
    BindEvent(#PB_Event_CloseWindow, @Object_Editor_Goto_Window_Event_CloseWindow(), *Object_Editor_Goto\Window\ID)
    
  EndIf
EndProcedure

Procedure Object_Editor_Goto_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor_Goto.Object_Editor_Goto = *Object_Editor\Window_Goto
  If Not *Object_Editor_Goto
    ProcedureReturn #False
  EndIf
  
  If *Object_Editor_Goto\Window
    
    UnbindGadgetEvent(*Object_Editor_Goto\Button_Goto, @Object_Editor_Goto_Window_Event_Button_Goto())
    
    UnbindEvent(#PB_Event_CloseWindow, @Object_Editor_Goto_Window_Event_CloseWindow(), *Object_Editor_Goto\Window\ID)
    
    Window_Delete(*Object_Editor_Goto\Window)
    *Object_Editor_Goto\Window = #Null
  EndIf
EndProcedure

Procedure Object_Editor_Goto_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor.Object_Editor = *Object\Custom_Data
  If Not *Object_Editor
    ProcedureReturn #False
  EndIf
  Protected *Object_Editor_Goto.Object_Editor_Goto = *Object_Editor\Window_Goto
  If Not *Object_Editor_Goto
    ProcedureReturn #False
  EndIf
  
  If *Object_Editor_Goto\Window
    
  EndIf
  
  If *Object_Editor_Goto\Window_Close
    *Object_Editor_Goto\Window_Close = #False
    Object_Editor_Goto_Window_Close(*Object)
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 162
; FirstLine = 134
; Folding = -
; EnableUnicode
; EnableXP