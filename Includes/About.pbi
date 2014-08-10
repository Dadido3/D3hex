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

; ##################################################### Structures ##################################################

Structure About_Main
  
EndStructure
Global About_Main.About_Main

Structure About
  Window_ID.i
  Window_Close.l
  
  ; #### Gadgets
  Canvas.i
  Editor.i
  
  Redraw.l
EndStructure
Global About.About

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

Global About_Image_Logo = CatchImage(#PB_Any, ?About_Image_Logo)

Global About_Font = LoadFont(#PB_Any, "Courier New", 10)

; ##################################################### Declares ####################################################

Declare   About_Close()

; ##################################################### Procedures ##################################################

Procedure About_Canvas_Redraw()
  Protected Width = GadgetWidth(About\Canvas)
  Protected Height = GadgetHeight(About\Canvas)
  Protected Text.s = "V. "+StrF(Main\Version*0.001, 3)
  
  If StartDrawing(CanvasOutput(About\Canvas))
    
    Box(0, 0, Width, Height, RGB(220,220,220))
    
    DrawImage(ImageID(About_Image_Logo), 0, 0, Width, Height)
    
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(About_Font))
    DrawText(Width-TextWidth(Text), Height-TextHeight(Text), Text, RGB(255,255,255))
    
    StopDrawing()
  EndIf
EndProcedure

Procedure About_Editor_Fill()
  ClearGadgetItems(About\Editor)
  
  SetGadgetFont(About\Editor, FontID(About_Font))
  
  AddGadgetItem(About\Editor, -1, "D3hex V."+StrF(Main\Version*0.001, 3))
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Created with PureBasic")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Times compiled: "+Str(#PB_Editor_CompileCount))
  AddGadgetItem(About\Editor, -1, "Times built: "+Str(#PB_Editor_BuildCount))
  AddGadgetItem(About\Editor, -1, "Build Timestamp: "+FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy", #PB_Compiler_Date))
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
    AddGadgetItem(About\Editor, -1, "Compiler Version: "+StrF(#PB_Compiler_Version/100, 2)+" (x86)")
  CompilerElse
    AddGadgetItem(About\Editor, -1, "Compiler Version: "+StrF(#PB_Compiler_Version/100, 2)+" (x64)")
  CompilerEndIf
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Programmer: David Vogel (Dadido3, Xaardas)")
  AddGadgetItem(About\Editor, -1, "Website: www.D3nexus.de")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "Used Includes:")
  AddGadgetItem(About\Editor, -1, "  - TabBarGadget.pbi by Stargate")
  AddGadgetItem(About\Editor, -1, "")
  AddGadgetItem(About\Editor, -1, "")
  
  AddGadgetItem(About\Editor, -1, "################")
  AddGadgetItem(About\Editor, -1, "# Object-Types #")
  AddGadgetItem(About\Editor, -1, "################")
  
  AddGadgetItem(About\Editor, -1, "")
  ForEach Object_Type()
    AddGadgetItem(About\Editor, -1, "Name: "+Object_Type()\Name+" (UID: "+Object_Type()\UID+")")
    AddGadgetItem(About\Editor, -1, "Description: "+Object_Type()\Description)
    AddGadgetItem(About\Editor, -1, "Author: "+Object_Type()\Author)
    AddGadgetItem(About\Editor, -1, "Created:  "+FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy", Object_Type()\Date_Creation))
    AddGadgetItem(About\Editor, -1, "Modified: "+FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy", Object_Type()\Date_Modification))
    AddGadgetItem(About\Editor, -1, "Compiled: "+FormatDate("%hh:%ii:%ss %dd.%mm.%yyyy", Object_Type()\Date_Compilation))
    AddGadgetItem(About\Editor, -1, "Version: "+StrF(Object_Type()\Version*0.001, 3))
    AddGadgetItem(About\Editor, -1, "")
    AddGadgetItem(About\Editor, -1, "########################################")
    AddGadgetItem(About\Editor, -1, "")
  Next
EndProcedure

Procedure About_Event_Canvas()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  
EndProcedure

Procedure About_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  
  About\Redraw = #True
EndProcedure

Procedure About_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  About\Redraw = #True
EndProcedure

Procedure About_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
EndProcedure

Procedure About_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;About_Close()
  About\Window_Close = #True
EndProcedure

Procedure About_Open()
  Protected Width, Height
  
  If About\Window_ID = 0
    
    Width = 500
    Height = 600
    
    About\Window_ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "About", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(Main_Window\ID))
    
    About\Canvas = CanvasGadget(#PB_Any, 0, 0, Width, 279)
    About\Editor = EditorGadget(#PB_Any, 0, 279, Width, Height-279, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    
    About_Editor_Fill()
    
    BindGadgetEvent(About\Canvas, @About_Event_Canvas())
    
    BindEvent(#PB_Event_SizeWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;BindEvent(#PB_Event_Repaint, @About_Event_SizeWindow(), About\Window_ID)
    ;BindEvent(#PB_Event_RestoreWindow, @About_Event_SizeWindow(), About\Window_ID)
    BindEvent(#PB_Event_Menu, @About_Event_Menu(), About\Window_ID)
    BindEvent(#PB_Event_CloseWindow, @About_Event_CloseWindow(), About\Window_ID)
    
    About\Redraw = #True
    
  EndIf
EndProcedure

Procedure About_Close()
  If About\Window_ID
    
    UnbindGadgetEvent(About\Canvas, @About_Event_Canvas())
    
    UnbindEvent(#PB_Event_SizeWindow, @About_Event_SizeWindow(), About\Window_ID)
    ;UnbindEvent(#PB_Event_Repaint, @About_Event_SizeWindow(), About\Window_ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @About_Event_SizeWindow(), About\Window_ID)
    UnbindEvent(#PB_Event_Menu, @About_Event_Menu(), About\Window_ID)
    UnbindEvent(#PB_Event_CloseWindow, @About_Event_CloseWindow(), About\Window_ID)
    
    CloseWindow(About\Window_ID)
    About\Window_ID = 0
  EndIf
EndProcedure

Procedure About_Main()
  If Not About\Window_ID
    ProcedureReturn #False
  EndIf
  
  If About\Redraw
    About\Redraw = #False
    About_Canvas_Redraw()
  EndIf
  
  If About\Window_Close
    About\Window_Close = #False
    About_Close()
  EndIf
  
EndProcedure

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

DataSection
  About_Image_Logo:
  IncludeBinary "../Data/Images/Logo.png"
EndDataSection

; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 2
; Folding = --
; EnableXP