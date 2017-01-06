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

DeclareModule Window
  EnableExplicit
  ; ################################################### Constants ###################################################
  Enumeration
    #Flag_Resizeable      = %001
    #Flag_MaximizeGadget  = %010
    #Flag_Docked          = %100
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  Structure KeyboardShortcut
    Key.i             ; Key combination
    
    Event_Menu.i      ; Menu event which will get posted to the child window
    Main_Menu.i       ; Menu of the main window (like undo, copy, ...)
  EndStructure
  
  Structure Object
    ID.i
    Name.s
    Name_Short.s
    
    Tab_ID.s          ; Windows with the same Tab_ID will be grouped into tabs if possible
    
    List KeyboardShortcut.KeyboardShortcut()
    
    *Node
  EndStructure
  Global NewList Object.Object()
  
  ; ################################################### Functions ###################################################
  Declare   Get(ID.i)
  Declare   Get_hWnd(hWnd.i)
  Declare   Get_Active()
  Declare   Set_Active(*Window.Object)
  Declare   Bounds(*Window.Object, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
  Declare   Remove_KeyboardShortcut(*Window.Object, Key.i)
  Declare   Set_KeyboardShortcut(*Window.Object, Key.i, Event_Menu.i, Main_Menu.i=0)
  
  Declare   Create(*Object, Name.s, Name_Short.s, X=#PB_Ignore, Y=#PB_Ignore, Width=#PB_Ignore, Height=#PB_Ignore, Flags=0, Resize_Priority.l=0, Tab_ID.s="")
  Declare   Delete(*Window.Object)
  
  Declare   Init(Parent_Window, Docker, StatusBar)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Window
  ; ################################################### Structures ##################################################
  Structure Main
    Parent_Window.i
    
    Docker.i
    StatusBar.i
  EndStructure
  Global Main.Main
  
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
  
  Procedure Get_hWnd(hWnd.i)
    Protected *Result.Object = #Null
    
    PushListPosition(Object())
    
    ForEach Object()
      If Object()\ID And WindowID(Object()\ID) = hWnd
        *Result = Object()
        Break
      EndIf
    Next
    
    PopListPosition(Object())
    
    ProcedureReturn *Result
  EndProcedure
  
  Procedure Get_Active()
    Protected *Result.Object = #Null
    Protected Active_ID = D3docker::Window_Get_Active(Main\Docker)
    
    PushListPosition(Object())
    
    ForEach Object()
      If Object()\ID = Active_ID
        *Result = Object()
        Break
      EndIf
    Next
    
    PopListPosition(Object())
    
    ProcedureReturn *Result
  EndProcedure
  
  Procedure Set_Active(*Window.Object)
    If Not *Window
      ProcedureReturn #False
    EndIf
    
    D3docker::Window_Set_Active(*Window\ID)
    
    StatusBarText(Main\StatusBar, 0, "")
    StatusBarText(Main\StatusBar, 1, "")
    StatusBarText(Main\StatusBar, 2, "")
    
    ;PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Bounds(*Window.Object, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
    If Not *Window
      ProcedureReturn #False
    EndIf
    
    D3docker::Window_Bounds(*Window\ID, Min_Width, Min_Height, Max_Width, Max_Height)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Remove_KeyboardShortcut(*Window.Object, Key.i)
    If Not *Window
      ProcedureReturn #False
    EndIf
    
    ForEach *Window\KeyboardShortcut()
      If *Window\KeyboardShortcut()\Key = Key
        DeleteElement(*Window\KeyboardShortcut())
      EndIf
    Next
    
    If Key
      RemoveKeyboardShortcut(*Window\ID, Key)
    EndIf
    
    Main::Window_KeyboardShortcut_Update() ; #### Indirectly executed throught Set_KeyboardShortcut
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Set_KeyboardShortcut(*Window.Object, Key.i, Event_Menu.i, Main_Menu.i=0)
    If Not *Window
      ProcedureReturn #False
    EndIf
    
    Remove_KeyboardShortcut(*Window, Key)
    
    AddElement(*Window\KeyboardShortcut())
    *Window\KeyboardShortcut()\Key = Key
    *Window\KeyboardShortcut()\Event_Menu = Event_Menu
    *Window\KeyboardShortcut()\Main_Menu = Main_Menu
    
    If Key
      AddKeyboardShortcut(*Window\ID, Key, Event_Menu)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Event_ActivateWindow()
    Protected ID = EventWindow()
    
    Protected *Window.Object = Get(ID)
    If Not *Window
      ProcedureReturn
    EndIf
    
    Main::Window_KeyboardShortcut_Update()
    
    StatusBarText(Main\StatusBar, 0, "")
    StatusBarText(Main\StatusBar, 1, "")
    StatusBarText(Main\StatusBar, 2, "")
    
  EndProcedure
  
  Procedure Event_MaximizeWindow()
    Protected ID = EventWindow()
    Protected i
    
    Protected *Window.Object = Get(ID)
    If Not *Window
      ProcedureReturn
    EndIf
    ; TODO: Still needed?
    ;ForEach Object()
    ;  PostEvent(#PB_Event_SizeWindow, Object()\ID, 0)
    ;Next
    
  EndProcedure
  
  Procedure Event_MinimizeWindow()
    Protected ID = EventWindow()
    Protected i
    
    Protected *Window.Object = Get(ID)
    If Not *Window
      ProcedureReturn
    EndIf
    ; TODO: Still needed?
    ;ForEach Object()
    ;  PostEvent(#PB_Event_SizeWindow, Object()\ID, 0)
    ;Next
    
  EndProcedure
  
  Procedure Event_RestoreWindow()
    Protected ID = EventWindow()
    Protected i
    
    Protected *Window.Object = Get(ID)
    If Not *Window
      ProcedureReturn
    EndIf
    ; TODO: Still needed?
    ;ForEach Object()
      ;PostEvent(#PB_Event_SizeWindow, Object()\ID, 0)
    ;Next
    
  EndProcedure
  
  Procedure Create(*Object, Name.s, Name_Short.s, X=#PB_Ignore, Y=#PB_Ignore, Width=#PB_Ignore, Height=#PB_Ignore, Flags=0, Resize_Priority.l=0, Tab_ID.s="")
    Protected *Window.Object
    
    If Not AddElement(Object())
      ProcedureReturn #Null
    EndIf
    
    *Window = Object()
    
    Protected Window_Flags
    Protected *Container
    Protected *Temp.Object
    
    If Flags & #Flag_Resizeable
      Window_Flags = #PB_Window_WindowCentered | #PB_Window_SystemMenu | #PB_Window_SizeGadget
    Else
      Window_Flags = #PB_Window_WindowCentered | #PB_Window_SystemMenu
    EndIf
    
    If Flags & #Flag_MaximizeGadget
      Window_Flags | #PB_Window_MaximizeGadget
    Else
      Window_Flags | #PB_Window_Tool
    EndIf
    
    ;*Window\MDI_Window = MDI
    *Window\Name = Name
    *Window\Name_Short = Name_Short
    ;If *Window\MDI_Window
    *Window\ID = D3docker::Window_Add(Main\Docker, X, Y, Width, Height, Name, Window_Flags, Resize_Priority)
    ;EndIf
    *Window\Node = *Object
    *Window\Tab_ID = Tab_ID
    
    ;SmartWindowRefresh(*Window\ID, 1)
    
    BindEvent(#PB_Event_ActivateWindow, @Event_ActivateWindow(), *Window\ID)
    ;BindEvent(#PB_Event_MaximizeWindow, @Event_MaximizeWindow(), *Window\ID)
    ;BindEvent(#PB_Event_MinimizeWindow, @Event_MinimizeWindow(), *Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Event_RestoreWindow(), *Window\ID)
    
    If Flags & #Flag_Docked
      ;*Temp = Get_Active()
      ;If *Temp
      ;  *Container = D3docker::Get_Container(*Temp\ID)
      ;EndIf
      
      If Tab_ID
        ForEach Object()
          If Object()\Tab_ID = Tab_ID
            *Container = D3docker::Window_Get_Container(Object()\ID)
            If *Container
              Break
            EndIf
          EndIf
        Next
      EndIf
      
      If *Container
        D3docker::Docker_Add(Main\Docker, *Container, D3docker::#Direction_Inside, *Window\ID)
      Else
        *Container = D3docker::Root_Get(Main\Docker)
        If WindowWidth(*Window\ID) > WindowHeight(*Window\ID)
          D3docker::Docker_Add(Main\Docker, *Container, D3docker::#Direction_Bottom, *Window\ID)
        Else
          D3docker::Docker_Add(Main\Docker, *Container, D3docker::#Direction_Right, *Window\ID)
        EndIf
      EndIf
      
    EndIf
    
    ;If *Window\MDI_Window
    ;  AddTabBarGadgetItem(Main_Window\Panel, #PB_Default, Name_Short, #Null, *Window\ID)
    ;  SetWindowState(*Window\ID, #PB_Maximize)
    ;  Main_Refresh_Active()
    ;Else
      ; #### Test
    ;  SetParent_(WindowID(*Window\ID ), WindowID(Main_Window\ID))
    ;EndIf
    
    ;PostEvent(#PB_Event_SizeWindow, *Window\ID, 0)
    
    ProcedureReturn *Window
  EndProcedure
  
  Procedure Delete(*Window.Object)
    Protected i
    Protected Window.i
    
    If Not *Window
      ProcedureReturn #False
    EndIf
    
    UnbindEvent(#PB_Event_ActivateWindow, @Event_ActivateWindow(), *Window\ID)
    UnbindEvent(#PB_Event_MaximizeWindow, @Event_MaximizeWindow(), *Window\ID)
    UnbindEvent(#PB_Event_MinimizeWindow, @Event_MinimizeWindow(), *Window\ID)
    UnbindEvent(#PB_Event_RestoreWindow, @Event_RestoreWindow(), *Window\ID)
    
    ;If *Window\MDI_Window
    ;  For i = 0 To CountTabBarGadgetItems(Main_Window\Panel) - 1
    ;    If GetTabBarGadgetItemData(Main_Window\Panel, i) = *Window\ID
    ;      RemoveTabBarGadgetItem(Main_Window\Panel, i)
    ;      Break
    ;    EndIf
    ;  Next
    ;EndIf
    
    Window = *Window\ID
    
    If ChangeCurrentElement(Object(), *Window)
      DeleteElement(Object())
    EndIf
    
    D3docker::Window_Close(Window)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Init(Parent_Window, Docker, StatusBar)
    Main\Parent_Window = Parent_Window
    Main\Docker = Docker
    Main\StatusBar = StatusBar
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 313
; FirstLine = 293
; Folding = ---
; EnableUnicode
; EnableXP