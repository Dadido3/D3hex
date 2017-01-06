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

Structure Goto_Window
  *Window.Window::Object
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

Declare   Goto_Window_Close(*Node.Node::Object)

; ##################################################### Procedures ##################################################

Procedure Goto_Window_Event_Button_Goto()
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
  Protected *Goto_Window.Goto_Window = *Object\Window_Goto
  If Not *Goto_Window
    ProcedureReturn
  EndIf
  
  Protected Select_Start.q = -1
  Protected Select_End.q = -1
  
  If GetGadgetText(*Goto_Window\String[0])
    Select_Start = Val(GetGadgetText(*Goto_Window\String[0]))
  ElseIf GetGadgetText(*Goto_Window\String[1])
    Select_Start = Val(GetGadgetText(*Goto_Window\String[1]))
  Else
    Select_Start = *Object\Select_Start
  EndIf
  
  If GetGadgetText(*Goto_Window\String[1])
    Select_End = Val(GetGadgetText(*Goto_Window\String[1]))
  ElseIf GetGadgetText(*Goto_Window\String[0])
    Select_End = Val(GetGadgetText(*Goto_Window\String[0]))
  Else
    Select_End = *Object\Select_End
  EndIf
  
  If Select_Start < 0
    Select_Start = 0
  EndIf
  If Select_End < 0
    Select_End = 0
  EndIf
  If Select_Start > *Object\Data_Size
    Select_Start = *Object\Data_Size
  EndIf
  If Select_End > *Object\Data_Size
    Select_End = *Object\Data_Size
  EndIf
  
  Range_Set(*Node, Select_Start, Select_End, #False, #True)
  
EndProcedure

Procedure Goto_Window_Event_CloseWindow()
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
  Protected *Goto_Window.Goto_Window = *Object\Window_Goto
  If Not *Goto_Window
    ProcedureReturn
  EndIf
  
  ;Goto_Window_Close(*Node)
  *Goto_Window\Window_Close = #True
EndProcedure

Procedure Goto_Window_Open(*Node.Node::Object)
  Protected Width, Height
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Goto_Window.Goto_Window = *Object\Window_Goto
  If Not *Goto_Window
    ProcedureReturn #False
  EndIf
  
  If Not *Goto_Window\Window
    
    Width = 270
    Height = 130
    
    *Goto_Window\Window = Window::Create(*Node, "Editor_Goto", "Editor_Goto", 0, 0, Width, Height)
    
    ; #### Gadgets
    *Goto_Window\Frame = FrameGadget(#PB_Any, 10, 10, Width-20, 70, "Position")
    *Goto_Window\Text[0] = TextGadget(#PB_Any, 20, 30, 50, 20, "Start:", #PB_Text_Right)
    *Goto_Window\Text[1] = TextGadget(#PB_Any, 20, 50, 50, 20, "End:", #PB_Text_Right)
    *Goto_Window\String[0] = StringGadget(#PB_Any, 80, 30, Width-100, 20, Str(*Object\Select_Start))
    *Goto_Window\String[1] = StringGadget(#PB_Any, 80, 50, Width-100, 20, Str(*Object\Select_End))
    If *Object\Select_Start = *Object\Select_End
      SetGadgetText(*Goto_Window\String[1], "")
    EndIf
    *Goto_Window\Button_Goto = ButtonGadget(#PB_Any, Width-100, Height-40, 90, 30, "Goto")
    
    BindGadgetEvent(*Goto_Window\Button_Goto, @Goto_Window_Event_Button_Goto())
    
    BindEvent(#PB_Event_CloseWindow, @Goto_Window_Event_CloseWindow(), *Goto_Window\Window\ID)
    
  Else
    Window::Set_Active(*Goto_Window\Window)
  EndIf
EndProcedure

Procedure Goto_Window_Close(*Node.Node::Object)
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Goto_Window.Goto_Window = *Object\Window_Goto
  If Not *Goto_Window
    ProcedureReturn #False
  EndIf
  
  If *Goto_Window\Window
    
    UnbindGadgetEvent(*Goto_Window\Button_Goto, @Goto_Window_Event_Button_Goto())
    
    UnbindEvent(#PB_Event_CloseWindow, @Goto_Window_Event_CloseWindow(), *Goto_Window\Window\ID)
    
    Window::Delete(*Goto_Window\Window)
    *Goto_Window\Window = #Null
  EndIf
EndProcedure

Procedure Goto_Main(*Node.Node::Object)
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Goto_Window.Goto_Window = *Object\Window_Goto
  If Not *Goto_Window
    ProcedureReturn #False
  EndIf
  
  If *Goto_Window\Window
    
  EndIf
  
  If *Goto_Window\Window_Close
    *Goto_Window\Window_Close = #False
    Goto_Window_Close(*Node)
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 162
; FirstLine = 152
; Folding = -
; EnableUnicode
; EnableXP