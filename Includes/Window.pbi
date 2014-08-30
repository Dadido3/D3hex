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
  #Window_Type_Normal
  #Window_Type_MDI
EndEnumeration

; ##################################################### Structures ##################################################

Structure Window
  ID.i
  Name.s
  Name_Short.s
  
  MDI_Window.i      ; #True if the window is embedded in a MDI
  
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
  Protected Active_Window_ID = GetGadgetState(Main_Window\MDI)
  
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
  
  If *Window\MDI_Window
    SetGadgetState(Main_Window\MDI, *Window\ID)
    
    Main_Window_Refresh_Active()
  Else
    SetActiveWindow(*Window\ID)
  EndIf
  
  StatusBarText(Main_Window\StatusBar_ID, 0, "")
  StatusBarText(Main_Window\StatusBar_ID, 1, "")
  StatusBarText(Main_Window\StatusBar_ID, 2, "")
  
  PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
  
  ProcedureReturn #True
EndProcedure

Procedure Window_Event_ActivateWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  
  If *Window\MDI_Window
    Main_Window_Refresh_Active()
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
  
  ForEach Window()
    PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  Next
  
EndProcedure

Procedure Window_Event_MinimizeWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  
  ForEach Window()
    PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  Next
  
EndProcedure

Procedure Window_Event_RestoreWindow()
  Protected Window_ID = EventWindow()
  Protected i
  
  Protected *Window.Window = Window_Get(Window_ID)
  If Not *Window
    ProcedureReturn
  EndIf
  
  ForEach Window()
    PostEvent(#PB_Event_SizeWindow, Window()\ID, 0)
  Next
  
EndProcedure

Procedure Window_Create(*Object.Object, Name.s, Name_Short.s, MDI, X=#PB_Ignore, Y=#PB_Ignore, Width=#PB_Ignore, Height=#PB_Ignore, Resizable=#False)
  Protected *Window.Window
  
  If Not AddElement(Window())
    ProcedureReturn #Null
  EndIf
  
  *Window = Window()
  
  Protected Flags
  
  *Window\MDI_Window = MDI
  *Window\Name = Name
  *Window\Name_Short = Name_Short
  If *Window\MDI_Window
    *Window\ID = AddGadgetItem(Main_Window\MDI, #PB_Any, Name)
    ResizeWindow(*Window\ID, X, Y, Width, Height)
  Else
    If Resizable
      Flags = #PB_Window_SizeGadget
    EndIf
    *Window\ID = OpenWindow(#PB_Any, X, Y, Width, Height, Name, #PB_Window_SystemMenu | #PB_Window_WindowCentered | Flags, WindowID(Main_Window\ID))
  EndIf
  *Window\Object = *Object
  
  SmartWindowRefresh(*Window\ID, 1)
  
  BindEvent(#PB_Event_ActivateWindow, @Window_Event_ActivateWindow(), *Window\ID)
  BindEvent(#PB_Event_MaximizeWindow, @Window_Event_MaximizeWindow(), *Window\ID)
  BindEvent(#PB_Event_MinimizeWindow, @Window_Event_MinimizeWindow(), *Window\ID)
  BindEvent(#PB_Event_RestoreWindow, @Window_Event_RestoreWindow(), *Window\ID)
  
  If *Window\MDI_Window
    AddTabBarGadgetItem(Main_Window\Panel, #PB_Default, Name_Short, #Null, *Window\ID)
    SetWindowState(*Window\ID, #PB_Window_Maximize)
    Main_Window_Refresh_Active()
  ;Else
    ; #### Test
  ;  SetParent_(WindowID(*Window\ID ), WindowID(Main_Window\ID))
  EndIf
  
  PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
  
  ProcedureReturn *Window
EndProcedure

Procedure Window_Delete(*Window.Window)
  Protected i
  
  If Not *Window
    ProcedureReturn #False
  EndIf
  
  UnbindEvent(#PB_Event_ActivateWindow, @Window_Event_ActivateWindow(), *Window\ID)
  UnbindEvent(#PB_Event_MaximizeWindow, @Window_Event_MaximizeWindow(), *Window\ID)
  UnbindEvent(#PB_Event_MinimizeWindow, @Window_Event_MinimizeWindow(), *Window\ID)
  UnbindEvent(#PB_Event_RestoreWindow, @Window_Event_RestoreWindow(), *Window\ID)
  
  If *Window\MDI_Window
    For i = 0 To CountTabBarGadgetItems(Main_Window\Panel) - 1
      If GetTabBarGadgetItemData(Main_Window\Panel, i) = *Window\ID
        RemoveTabBarGadgetItem(Main_Window\Panel, i)
        Break
      EndIf
    Next
  EndIf
  
  CloseWindow(*Window\ID)
  
  If ChangeCurrentElement(Window(), *Window)
    DeleteElement(Window())
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 235
; FirstLine = 198
; Folding = --
; EnableUnicode
; EnableXP