
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
  #Logging_Entry_Type_Warning
  #Logging_Entry_Type_Error
EndEnumeration

; ##################################################### Structures ##################################################

Structure Logging_Main
  
  Open_Error_Window.l
  
EndStructure
Global Logging_Main.Logging_Main

Structure Logging_Entry
  Type.i
  
  Name.s
  Description.s
  
  Shown.l
  
  ; #### Place
  Include.s
  Function.s
  Line.l
EndStructure
Global NewList Logging_Entry.Logging_Entry()

Structure Logging_Error
  Window_ID.i
  Window_Close.l
  
  ; #### Gadgets
  Image.i
  Text.i[10]
  Editor.i
EndStructure
Global Logging_Error.Logging_Error

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

Global Logging_Icon_Error = CatchImage(#PB_Any, ?Logging_Icon_Error)
Global Logging_Icon_Warning = CatchImage(#PB_Any, ?Logging_Icon_Warning)

Global Logging_Error_Font_Big = LoadFont(#PB_Any, "Courier New", 15)
Global Logging_Error_Font_Small = LoadFont(#PB_Any, "Courier New", 10)

; ##################################################### Declares ####################################################

Declare   Logging_Error_Close()

; ##################################################### Procedures ##################################################

Macro Logging_Entry_Add_Error(Name, Description)
  Logging_Entry_Add(#Logging_Entry_Type_Error, Name, Description, #PB_Compiler_Filename, #PB_Compiler_Procedure, #PB_Compiler_Line)
EndMacro

Macro Logging_Entry_Add_Warning(Name, Description)
  Logging_Entry_Add(#Logging_Entry_Type_Warning, Name, Description, #PB_Compiler_Filename, #PB_Compiler_Procedure, #PB_Compiler_Line)
EndMacro

Procedure Logging_Entry_Add(Type, Name.s, Description.s, Include.s, Function.s, Line.l)
  LastElement(Logging_Entry())
  If AddElement(Logging_Entry())
    
    Select Type
      Case #Logging_Entry_Type_Error
        Logging_Main\Open_Error_Window = #True
    EndSelect
    
    Logging_Entry()\Type = Type
    Logging_Entry()\Name = Name
    Logging_Entry()\Description = Description
    Logging_Entry()\Include = Include
    Logging_Entry()\Function = Function
    Logging_Entry()\Line = Line
    
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure Logging_Error_Fill()
  
  SetGadgetState(Logging_Error\Image, ImageID(Logging_Icon_Error))
  
  ForEach Logging_Entry()
    If Not Logging_Entry()\Shown
      SetGadgetText(Logging_Error\Text[0], Logging_Entry()\Name)
      SetGadgetText(Logging_Error\Text[1], Logging_Entry()\Description)
      Break
    EndIf
  Next
  
  
  ; #### Fill in last errors
  ClearGadgetItems(Logging_Error\Editor)
  SetGadgetFont(Logging_Error\Editor, FontID(Logging_Error_Font_Small))
  
  ForEach Logging_Entry()
    If Not Logging_Entry()\Shown
      AddGadgetItem(Logging_Error\Editor, -1, "Name: "+Logging_Entry()\Name)
      AddGadgetItem(Logging_Error\Editor, -1, "Description: "+Logging_Entry()\Description)
      AddGadgetItem(Logging_Error\Editor, -1, "Place: "+Logging_Entry()\Include+":"+Logging_Entry()\Function+":"+Str(Logging_Entry()\Line))
      AddGadgetItem(Logging_Error\Editor, -1, "")
      AddGadgetItem(Logging_Error\Editor, -1, "########################################")
      AddGadgetItem(Logging_Error\Editor, -1, "")
    EndIf
  Next
  
EndProcedure

Procedure Logging_Error_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
EndProcedure

Procedure Logging_Error_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
EndProcedure

Procedure Logging_Error_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
EndProcedure

Procedure Logging_Error_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;Logging_Error_Close()
  Logging_Error\Window_Close = #True
EndProcedure

Procedure Logging_Error_Open()
  Protected Width, Height
  
  If Logging_Error\Window_ID = 0
    
    Width = 500
    Height = 250
    
    Logging_Error\Window_ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "Error", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main_Window\ID))
    
    Logging_Error\Image = ImageGadget(#PB_Any, 10, 10, 32, 32, 0)
    Logging_Error\Text[0] = TextGadget(#PB_Any, 50, 00, Width-50, 30, "No Error")
    Logging_Error\Text[1] = TextGadget(#PB_Any, 50, 30, Width-50, 60, "-")
    Logging_Error\Editor = EditorGadget(#PB_Any, 0, 90, Width, Height-90, #PB_Editor_ReadOnly)
    
    SetGadgetFont(Logging_Error\Text[0], FontID(Logging_Error_Font_Big))
    SetGadgetFont(Logging_Error\Text[1], FontID(Logging_Error_Font_Small))
    
    Logging_Error_Fill()
    
    BindEvent(#PB_Event_SizeWindow, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    ;BindEvent(#PB_Event_Repaint, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    BindEvent(#PB_Event_Menu, @Logging_Error_Event_Menu(), Logging_Error\Window_ID)
    BindEvent(#PB_Event_CloseWindow, @Logging_Error_Event_CloseWindow(), Logging_Error\Window_ID)
    
  Else
    Logging_Error_Fill()
  EndIf
EndProcedure

Procedure Logging_Error_Close()
  If Logging_Error\Window_ID
    
    UnbindEvent(#PB_Event_SizeWindow, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    ;UnbindEvent(#PB_Event_Repaint, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Logging_Error_Event_SizeWindow(), Logging_Error\Window_ID)
    UnbindEvent(#PB_Event_Menu, @Logging_Error_Event_Menu(), Logging_Error\Window_ID)
    UnbindEvent(#PB_Event_CloseWindow, @Logging_Error_Event_CloseWindow(), Logging_Error\Window_ID)
    
    CloseWindow(Logging_Error\Window_ID)
    Logging_Error\Window_ID = 0
    
    ForEach Logging_Entry()
      If Not Logging_Entry()\Shown
        Logging_Entry()\Shown = #True
      EndIf
    Next
    
  EndIf
EndProcedure

Procedure Logging_Main()
  
  If Logging_Main\Open_Error_Window
    Logging_Main\Open_Error_Window = #False
    Logging_Error_Open()
  EndIf
  
  If Logging_Error\Window_Close
    Logging_Error\Window_Close = #False
    Logging_Error_Close()
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

DataSection
  Logging_Icon_Error:
  IncludeBinary "../Data/Icons/Error.png"
  Logging_Icon_Warning:
  IncludeBinary "../Data/Icons/Warning.png"
EndDataSection

; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 242
; FirstLine = 186
; Folding = --
; EnableUnicode
; EnableXP