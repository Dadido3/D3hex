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
  #Window_Type_Normal
  #Window_Type_MDI
EndEnumeration

; ##################################################### Structures ##################################################

Structure Window
  ID.i
  Name.s
  Name_Short.s
  
  Tab_ID.s          ; Windows with the same Tab_ID will be grouped into tabs if possible
  
  *Object.Object
EndStructure
Global NewList Window.Window()

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Procedures ##################################################

Procedure Window_Get(ID.i)
  Protected *Result.Window = #Null
  
  PushListPosition(Window())
  
  ForEach Window()
    If Window()\ID = ID
      *Result = Window()
      Break
    EndIf
  Next
  
  PopListPosition(Window())
  
  ProcedureReturn *Result
EndProcedure

Procedure Window_Get_hWnd(hWnd.i)
  Protected *Result.Window = #Null
  
  PushListPosition(Window())
  
  ForEach Window()
    If Window()\ID And WindowID(Window()\ID) = hWnd
      *Result = Window()
      Break
    EndIf
  Next
  
  PopListPosition(Window())
  
  ProcedureReturn *Result
EndProcedure

Procedure Window_Get_Active()
  Protected *Result.Window = #Null
  Protected Active_Window_ID = D3docker::Window_Get_Active(Main_Window\D3docker)
  
  PushListPosition(Window())
  
  ForEach Window()
    If Window()\ID = Active_Window_ID
      *Result = Window()
      Break
    EndIf
  Next
  
  PopListPosition(Window())
  
  ProcedureReturn *Result
EndProcedure

Procedure Window_Set_Active(*Window.Window)
  If Not *Window
    ProcedureReturn #False
  EndIf
  
  D3docker::Window_Set_Active(*Window\ID)
  
  StatusBarText(Main_Window\StatusBar_ID, 0, "")
  StatusBarText(Main_Window\StatusBar_ID, 1, "")
  StatusBarText(Main_Window\StatusBar_ID, 2, "")
  
  ;PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
  
  ProcedureReturn #True
EndProcedure

Procedure Window_Bounds(*Window.Window, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
  If Not *Window
    ProcedureReturn #False
  EndIf
  
  D3docker::Window_Bounds(*Window\ID, Min_Width, Min_Height, Max_Width, Max_Height)
  
  ProcedureReturn #True
EndProcedure

Procedure Window_Event_ActivateWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  
  StatusBarText(Main_Window\StatusBar_ID, 0, "")
  StatusBarText(Main_Window\StatusBar_ID, 1, "")
  StatusBarText(Main_Window\StatusBar_ID, 2, "")
  
EndProcedure

Procedure Window_Event_MaximizeWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  ; TODO: Still needed?
  ;ForEach Window()
  ;  PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  ;Next
  
EndProcedure

Procedure Window_Event_MinimizeWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  ; TODO: Still needed?
  ;ForEach Window()
  ;  PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  ;Next
  
EndProcedure

Procedure Window_Event_RestoreWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  ; TODO: Still needed?
  ;ForEach Window()
    ;PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  ;Next
  
EndProcedure

Procedure Window_Create(*Object.Object, Name.s, Name_Short.s, Docked, X=#PB_Ignore, Y=#PB_Ignore, Width=#PB_Ignore, Height=#PB_Ignore, Resizable=#False, Resize_Priority.l=0, Tab_ID.s="")
  Protected *Window.Window
  
  If Not AddElement(Window())
    ProcedureReturn #Null
  EndIf
  
  *Window = Window()
  
  Protected Flags = #PB_Window_WindowCentered
  Protected *Container
  Protected *Window_Temp.Window
  
  If Resizable
    Flags | #PB_Window_SizeGadget
  EndIf
  
  ;*Window\MDI_Window = MDI
  *Window\Name = Name
  *Window\Name_Short = Name_Short
  ;If *Window\MDI_Window
  *Window\ID = D3docker::Window_Add(Main_Window\D3docker, X, Y, Width, Height, Name, Flags, Resize_Priority)
  ;EndIf
  *Window\Object = *Object
  *Window\Tab_ID = Tab_ID
  
  ;SmartWindowRefresh(*Window\ID, 1)
  
  BindEvent(#PB_Event_ActivateWindow, @Window_Event_ActivateWindow(), *Window\ID)
  BindEvent(#PB_Event_MaximizeWindow, @Window_Event_MaximizeWindow(), *Window\ID)
  BindEvent(#PB_Event_MinimizeWindow, @Window_Event_MinimizeWindow(), *Window\ID)
  BindEvent(#PB_Event_RestoreWindow, @Window_Event_RestoreWindow(), *Window\ID)
  
  If Docked
    ;*Window_Temp = Window_Get_Active()
    ;If *Window_Temp
    ;  *Container = D3docker::Window_Get_Container(*Window_Temp\ID)
    ;EndIf
    
    If Tab_ID
      ForEach Window()
        If Window()\Tab_ID = Tab_ID
          *Container = D3docker::Window_Get_Container(Window()\ID)
          If *Container
            Break
          EndIf
        EndIf
      Next
    EndIf
    
    If *Container
      D3docker::Docker_Add(Main_Window\D3docker, *Container, D3docker::#Direction_Inside, *Window\ID)
    Else
      *Container = D3docker::Root_Get(Main_Window\D3docker)
      If WindowWidth(*Window\ID) > WindowHeight(*Window\ID)
        D3docker::Docker_Add(Main_Window\D3docker, *Container, D3docker::#Direction_Bottom, *Window\ID)
      Else
        D3docker::Docker_Add(Main_Window\D3docker, *Container, D3docker::#Direction_Right, *Window\ID)
      EndIf
    EndIf
    
  EndIf
  
  ;If *Window\MDI_Window
  ;  AddTabBarGadgetItem(Main_Window\Panel, #PB_Default, Name_Short, #Null, *Window\ID)
  ;  SetWindowState(*Window\ID, #PB_Window_Maximize)
  ;  Main_Window_Refresh_Active()
  ;Else
    ; #### Test
  ;  SetParent_(WindowID(*Window\ID ), WindowID(Main_Window\ID))
  ;EndIf
  
  ;PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
  
  ProcedureReturn *Window
EndProcedure

Procedure Window_Delete(*Window.Window)
  Protected i
  Protected Window.i
  
  If Not *Window
    ProcedureReturn #False
  EndIf
  
  UnbindEvent(#PB_Event_ActivateWindow, @Window_Event_ActivateWindow(), *Window\ID)
  UnbindEvent(#PB_Event_MaximizeWindow, @Window_Event_MaximizeWindow(), *Window\ID)
  UnbindEvent(#PB_Event_MinimizeWindow, @Window_Event_MinimizeWindow(), *Window\ID)
  UnbindEvent(#PB_Event_RestoreWindow, @Window_Event_RestoreWindow(), *Window\ID)
  
  ;If *Window\MDI_Window
  ;  For i = 0 To CountTabBarGadgetItems(Main_Window\Panel) - 1
  ;    If GetTabBarGadgetItemData(Main_Window\Panel, i) = *Window\ID
  ;      RemoveTabBarGadgetItem(Main_Window\Panel, i)
  ;      Break
  ;    EndIf
  ;  Next
  ;EndIf
  
  Window = *Window\ID
  
  If ChangeCurrentElement(Window(), *Window)
    DeleteElement(Window())
  EndIf
  
  D3docker::Window_Close(Window)
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 253
; FirstLine = 221
; Folding = --
; EnableUnicode
; EnableXP