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
; ##################################################### Dokumentation ###############################################
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

DeclareModule Logger
  EnableExplicit
  
  ; ################################################### Constants ###################################################
  Enumeration
    #Entry_Type_Warning
    #Entry_Type_Error
  EndEnumeration
  
  ; ################################################### Functions ###################################################
  Declare   Entry_Add(Type, Name.s, Description.s, Include.s, Function.s, Line.l)
  
  Declare   Init(Parent_Window.i)
  Declare   Main()
  
  ; ################################################### Macros ######################################################
  Macro Entry_Add_Error(Name, Description)
    Logger::Entry_Add(Logger::#Entry_Type_Error, Name, Description, #PB_Compiler_Filename, #PB_Compiler_Procedure, #PB_Compiler_Line)
  EndMacro
  
  Macro Entry_Add_Warning(Name, Description)
    Logger::Entry_Add(Logger::#Entry_Type_Warning, Name, Description, #PB_Compiler_Filename, #PB_Compiler_Procedure, #PB_Compiler_Line)
  EndMacro
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Logger
  ; ################################################### Structures ##################################################
  Structure Main
    
    Parent_Window.i
    
    Open_Window_Window.l
    
  EndStructure
  Global Main.Main
  
  Structure Entry
    Type.i
    
    Name.s
    Description.s
    
    Shown.l
    
    ; #### Place
    Include.s
    Function.s
    Line.l
  EndStructure
  Global NewList Entry.Entry()
  
  Structure Window
    ID.i
    Close.l
    
    ; #### Gadgets
    Image.i
    Text.i[10]
    Editor.i
  EndStructure
  Global Window.Window
  
  ; ################################################### Init ########################################################
  Global Icon_Error = CatchImage(#PB_Any, ?Icon_Error)
  Global Icon_Warning = CatchImage(#PB_Any, ?Icon_Warning)
  
  Global Window_Font_Big = LoadFont(#PB_Any, "Courier New", 15)
  Global Window_Font_Small = LoadFont(#PB_Any, "Courier New", 10)
  
  ; ################################################### Declares ####################################################
  Declare   Window_Close()
  
  ; ################################################### Procedures ##################################################
  Procedure Entry_Add(Type, Name.s, Description.s, Include.s, Function.s, Line.l)
    LastElement(Entry())
    If AddElement(Entry())
      
      Select Type
        Case #Entry_Type_Error
          Main\Open_Window_Window = #True
      EndSelect
      
      Entry()\Type = Type
      Entry()\Name = Name
      Entry()\Description = Description
      Entry()\Include = Include
      Entry()\Function = Function
      Entry()\Line = Line
      
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Window_Fill()
    
    SetGadgetState(Window\Image, ImageID(Icon_Error))
    
    ForEach Entry()
      If Not Entry()\Shown
        SetGadgetText(Window\Text[0], Entry()\Name)
        SetGadgetText(Window\Text[1], Entry()\Description)
        Break
      EndIf
    Next
    
    
    ; #### Fill in last errors
    ClearGadgetItems(Window\Editor)
    SetGadgetFont(Window\Editor, FontID(Window_Font_Small))
    
    ForEach Entry()
      If Not Entry()\Shown
        AddGadgetItem(Window\Editor, -1, "Name: "+Entry()\Name)
        AddGadgetItem(Window\Editor, -1, "Description: "+Entry()\Description)
        AddGadgetItem(Window\Editor, -1, "Place: "+Entry()\Include+":"+Entry()\Function+":"+Str(Entry()\Line))
        AddGadgetItem(Window\Editor, -1, "")
        AddGadgetItem(Window\Editor, -1, "########################################")
        AddGadgetItem(Window\Editor, -1, "")
      EndIf
    Next
    
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
  EndProcedure
  
  Procedure Window_Event_ActivateWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
  EndProcedure
  
  Procedure Window_Event_CloseWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    ;Window_Close()
    Window\Close = #True
  EndProcedure
  
  Procedure Window_Open()
    Protected Width, Height
    
    If Window\ID = 0
      
      Width = 500
      Height = 250
      
      Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "Error", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main\Parent_Window))
      
      Window\Image = ImageGadget(#PB_Any, 10, 10, 32, 32, 0)
      Window\Text[0] = TextGadget(#PB_Any, 50, 00, Width-50, 30, "No Error")
      Window\Text[1] = TextGadget(#PB_Any, 50, 30, Width-50, 60, "-")
      Window\Editor = EditorGadget(#PB_Any, 0, 90, Width, Height-90, #PB_Editor_ReadOnly)
      
      SetGadgetFont(Window\Text[0], FontID(Window_Font_Big))
      SetGadgetFont(Window\Text[1], FontID(Window_Font_Small))
      
      Window_Fill()
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), Window\ID)
      
    Else
      Window_Fill()
    EndIf
  EndProcedure
  
  Procedure Window_Close()
    If Window\ID
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), Window\ID)
      ;UnbindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), Window\ID)
      ;UnbindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), Window\ID)
      
      CloseWindow(Window\ID)
      Window\ID = 0
      
      ForEach Entry()
        If Not Entry()\Shown
          Entry()\Shown = #True
        EndIf
      Next
      
    EndIf
  EndProcedure
  
  Procedure Init(Parent_Window.i)
    Main\Parent_Window = Parent_Window
  EndProcedure
  
  Procedure Main()
    If Main\Open_Window_Window
      Main\Open_Window_Window = #False
      Window_Open()
    EndIf
    
    If Window\Close
      Window\Close = #False
      Window_Close()
    EndIf
  EndProcedure
  
  ; ################################################### Data Sections ###############################################
  DataSection
    Icon_Error:
    IncludeBinary "../Data/Icons/Error.png"
    Icon_Warning:
    IncludeBinary "../Data/Icons/Warning.png"
  EndDataSection
  
EndModule
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 184
; FirstLine = 156
; Folding = ---
; EnableUnicode
; EnableXP