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
; Todo:
; - Each object HAS to return an segment-list via ...Get_Segments(...)
; - Store/Restore Window states/positions into/from the configurations.
;   
; - Editor:
;   - Autoscroll
;   
; - History-Object:
;   - Correct the event-range for event- forwarding
;   - Correct the range for segments
;   - Verbesserte Speicherroutine (Intelligentes speichern der Änderungsliste). Voraussetzung: Offsetliste
;   - Data_Source_Get cache nicht rekursiv abarbeiten (Eindimensionale Offsetliste erstellen)
;   
; - Analyseelemente:
;   - Datendeskriptor (Format: Array 1D, 2D, 3D, Bytereihenfolge, Wortgröße/Typ, ...)
;     - Via NBT
;   - Dateistrukturanalyse (Strukturdeskriptoren) wird in Datendeskriptor inkludiert. 
;   - Source verifier
;   - 1-Dimensional viewer:
;     - Make offset working
;   - 2-Dimensional viewer (Raw Image Viewer)
;     - BUG: Correct behaviour with negative offsets (A complete line is invisible when using negative offsets)
;     - Support More Pixel Formats
;     - Only redraw updated chunks on update events, not all
;     - Check for Division with 0
;   - 3-Dimensional viewer?
;   - Hilbert-Viewer
;   - Dateianalyse (Byteverteilung/Histogramm 1D 2D 3D)
;   - Blockweise Entropie
;   - Image-Format converter
;   - Vergleich
;   - Mathematische operationen (+, -, *, /, ...)
;   - Korrellation / Autokorrellation
;   - Checksum
;   - Diskrete Fourier Transformation (bzw. FFT)
;   - Disassembler (x86/64, 6809, ...)
;   - Audiowiedergabe
;   - Cheat-Engine like object
;   - Text-Viewer (Shows the data as text in a editor gadget)
;   
; - Data_Source elemente
;   - Signalgeneratoren (Ausgabe verschiedener Datentypen (Byte, Word, Long, Float, Double...))
;   - Physikalische / Logische Datenträger
;   - Clipboard
;   
; - Strukturelemente
;   - Split
;   - Array Split
;   - Netzwerk
;   - Lua-Element
;   
; Versionchanges:
; - V0.000 (0?.04.2011) (Old base)
;   
; - V0.610 (??.??.201?) (Old base)
;   
; - V0.700 (--.--.2013) (Old base)
;   
; - V0.900 (21.12.2013)
;   - Everything rewritten, base system is working.
;   
; - V0.910 (24.02.2014)
;   - Editor-Object:
;     - added Scrollbar (can handle more than 2^32 lines)
;     - Convolute the marked range when adding or deleting data.
;     - Update Scrollbar when needed
;     - Scroll screen to cursor
;     - Added hex input and nibble selection per keyboard and mouse
;     - Copy and Paste in hex or ascii field
;     - Goto
;     - Search
;     - Copy/Paste via menu (Also correct cursor handling for that)
;     - Display Metadata
;   - 1-Dimensional viewer
;   - Node-Editor can now save and load node configurations (via Named Binary Tags)
;   - Random Data Generator
;   - Added a GUI to the File-Object
;   - Added events to all kind of stuff: Save, SaveAs, Goto, Search, Continue, Load/Save-Config, Undo, Redo, Cut, Copy, Paste
;   - Added History Object
;   - Logging And Error messages
;   
; - V0.912 (25.02.2014)
;   - Less Window-Flickering with SmartWindowRefresh()
;   - Tab-Bar fires now a close-event to the window
;   
; - V0.920 (02.03.2014)
;   - Editor:
;     - Search:
;       - Corrected the Raw_Keyword_Size when including the zero byte with ucs-2 (Object_Editor_Search_Prepare_Keyword_Helper(Type))
;       - Corrected the single replace mode...  (Store the found position in the search element, and use that for replacement! Not the selected range!)
;       - Made search much faster
;       - Search now only searches in readable segments
;     - Added statusbar-text
;     - Nibble-writing is now cached
;     - Provide the selected range as output
;   - Added prcess data-source
;   - Using a flag instead of several object-types for opening and reopening
;   - Network terminal
;   
; - V0.925 (10.08.2014)
;   - Fixed loading of the default D3hex file
;   - Added names to object-inputs and outputs
;   - Editor:
;     - Fixed the goto stuff
;   - All Windows of the objects are now managed by Window.pbi
;   - Added Set_Data_Check and Convolute_Check functions
;   - Added Object_Datatypes
;   - Fixed crash because of wrong pointer returned from Window_Create(...)
;   
; - V0.930 (15.08.2014)
;   - Added Object_Binary_Operation
;   - Added Object_Copy
;   - Update every structure allocation to AllocateStructure(...) and FreeStructure(...)
;   
; - V0.940 (05.01.2015)
;   - Fixed possible crash with Object_Editor (String generation in search wrote Null-Bytes outside of the memory)
;   - NBT loading And saving is a bit faster
;   - Object_Copy: Display progress
;   - Added a unit engine To format numbers With SI-prefixes...
;   - Object_View1D: Fixed "Jumping out of the screen" when normalizing the x-axis
;   - Renamed And moved all object-includes
;   - Renamed the object "Datatypes" To "Data Inspector"
;   - Added View2D, viewer For raster graphics
;   - Object descriptor changed To NBT
;   - Object_Editor: limited marked output To selection
;   - Object_Random: limited output To size
;   
; - V0.941 (06.01.2015)
;   - Object_Editor: Fixed writing at the end of data
;   - Object_View2D: Added standard configuration
;   
; - V0.957 (INDEV)
;   - Object_File: Ignore result of File-requesters if it is ""
;   - Network_Terminal:
;     - Data_Set is not triggering an update event
;     - Object_History is now working with Network_Terminal
;     - Renamed output and input to sent and received
;   - Object_History:
;     - Added the option to allow write operations in any case
;   - Use D3docker.pbi instead of the mdi gadget
;   - Shortcuts now work in undocked windows
;   - Continued implementation of "Data descriptors"
;   - Names of the object-windows now depend on the parent objects
;   - Object_Data_Inspector:
;     - Resized the gadget a bit
;   - Fixed crash
;   - Statusbar works again for Object_Editor
;   - Many other small changes and refactoring
;   
; ##################################################### Begin #######################################################

EnableExplicit

UsePNGImageDecoder()
UsePNGImageEncoder()

; ##################################################### Includes ####################################################

XIncludeFile "Includes/D3docker/D3docker.pbi"
XIncludeFile "Includes/Memory.pbi"
XIncludeFile "Includes/D3HT.pbi"
XIncludeFile "Includes/D3NBT.pbi"
XIncludeFile "Includes/Crash.pbi"
XIncludeFile "Includes/UnitEngine.pbi"

; ##################################################### Constants ###################################################

#Version = 0957

Enumeration
  #Data_Raw
  #Integer_U_1; = #PB_Ascii
  #Integer_S_1; = #PB_Byte
  #Integer_U_2; = #PB_Unicode
  #Integer_S_2; = #PB_Word
  #Integer_U_4; = #PB_Long (Unsigned)
  #Integer_S_4; = #PB_Long
  #Integer_U_8; = #PB_Quad (Unsigned)
  #Integer_S_8; = #PB_Quad
  #Float_4    ; = #PB_Float
  #Float_8    ; = #PB_Double
  #String_Ascii
  #String_UTF8
  #String_UTF16
  #String_UTF32
  #String_UCS2
  #String_UCS4
EndEnumeration

Enumeration ; Image Pixelformat. Number is in bpp
  #PixelFormat_1_Gray
  #PixelFormat_1_Indexed
  #PixelFormat_2_Gray
  #PixelFormat_2_Indexed
  #PixelFormat_4_Gray
  #PixelFormat_4_Indexed
  #PixelFormat_8_Gray
  #PixelFormat_8_Indexed
  #PixelFormat_16_Gray
  #PixelFormat_16_RGB_555
  #PixelFormat_16_RGB_565
  #PixelFormat_16_ARGB_1555
  #PixelFormat_16_Indexed
  #PixelFormat_24_RGB
  #PixelFormat_24_BGR
  #PixelFormat_32_ARGB
  #PixelFormat_32_ABGR
EndEnumeration

#Metadata_Readable   = %00000001
#Metadata_Writeable  = %00000010
#Metadata_Executable = %00000100
#Metadata_Changed    = %01000000
#Metadata_NoError    = %10000000

Enumeration 1
  #DragDrop_Private_Objects
EndEnumeration

Enumeration 1
  #Menu_Dummy
  
  #Menu_New
  #Menu_Save
  #Menu_SaveAs
  #Menu_Close
  #Menu_Exit
  
  #Menu_Open_File
  #Menu_Open_Process
  #Menu_Open_Clipboard
  #Menu_Open_Random
  #Menu_Open_Network_Terminal
  
  #Menu_Node_Editor
  #Menu_Node_Clear_Config
  #Menu_Node_Load_Config
  #Menu_Node_Save_Config
  
  #Menu_Undo
  #Menu_Redo
  #Menu_Cut
  #Menu_Copy
  #Menu_Paste
  
  #Menu_Search
  #Menu_Search_Continue
  
  #Menu_Goto
  
  ;#Menu_TileV
  ;#Menu_TileH
  ;#Menu_Cascade
  ;#Menu_Arrange
  
  #Menu_Help
  #Menu_About
  
  #Menu_MDI_Windows_Start
EndEnumeration

; ##################################################### Structures ##################################################

Structure Main
  Version.i
  
  Quit.i
EndStructure
Global Main.Main

Structure Main_Window
  ID.i
  Menu_ID.i
  ToolBar_ID.i
  StatusBar_ID.i
  ;MDI.i
  ;Panel.i
  D3docker.i
  ; ####
  D3docker_Height.i
  D3docker_Width.i
  ;Panel_Height.i          ; Höhe des Panels
  Menu_Height.i           ; Höhe des Menüs
  ToolBar_Height.i        ; Höhe der ToolBar
  StatusBar_Height.i      ; Höhe der StatusBar
EndStructure
Global Main_Window.Main_Window

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

Global Icon_New = CatchImage(#PB_Any, ?Icon_New)
Global Icon_Save = CatchImage(#PB_Any, ?Icon_Save)
Global Icon_SaveAs = CatchImage(#PB_Any, ?Icon_SaveAs)
Global Icon_Open_File = CatchImage(#PB_Any, ?Icon_Open_File)
Global Icon_Undo = CatchImage(#PB_Any, ?Icon_Undo)
Global Icon_Redo = CatchImage(#PB_Any, ?Icon_Redo)
Global Icon_Cut = CatchImage(#PB_Any, ?Icon_Cut)
Global Icon_Copy = CatchImage(#PB_Any, ?Icon_Copy)
Global Icon_Paste = CatchImage(#PB_Any, ?Icon_Paste)
Global Icon_Select_All = CatchImage(#PB_Any, ?Icon_Select_All)
Global Icon_Open_Process = CatchImage(#PB_Any, ?Icon_Open_Process)
Global Icon_Open_Clipboard = CatchImage(#PB_Any, ?Icon_Open_Clipboard)
Global Icon_Open_Random = CatchImage(#PB_Any, ?Icon_Open_Random)
Global Icon_Open_Network_Terminal = CatchImage(#PB_Any, ?Icon_Open_Network_Terminal)
Global Icon_Node_Editor = CatchImage(#PB_Any, ?Icon_Node_Editor)
Global Icon_Node_Clear_Config = CatchImage(#PB_Any, ?Icon_Node_Clear_Config)
Global Icon_Node_Load_Config = CatchImage(#PB_Any, ?Icon_Node_Load_Config)
Global Icon_Node_Save_Config = CatchImage(#PB_Any, ?Icon_Node_Save_Config)
Global Icon_Close = CatchImage(#PB_Any, ?Icon_Close)
Global Icon_Resize = CatchImage(#PB_Any, ?Icon_Resize)
Global Icon_Hilbert = CatchImage(#PB_Any, ?Icon_Hilbert)
Global Icon_Gear = CatchImage(#PB_Any, ?Icon_Gear)
Global Icon_Grid = CatchImage(#PB_Any, ?Icon_Grid)
Global Icon_Search = CatchImage(#PB_Any, ?Icon_Search)
Global Icon_Search_Continue = CatchImage(#PB_Any, ?Icon_Search_Continue)
Global Icon_Goto = CatchImage(#PB_Any, ?Icon_Goto)

; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

Macro Line(x, y, Width, Height, Color)
  LineXY((x), (y), (x)+(Width), (y)+(Height), (Color))
EndMacro

; #### Works perfectly, A and B can be positive or negative. B must not be zero!
Procedure.q Quad_Divide_Floor(A.q, B.q)
  Protected Temp.q = A / B
  If (((a ! b) < 0) And (a % b <> 0))
    ProcedureReturn Temp - 1
  Else
    ProcedureReturn Temp
  EndIf
EndProcedure

; #### Works perfectly, A and B can be positive or negative. B must not be zero!
Procedure.q Quad_Divide_Ceil(A.q, B.q)
  Protected Temp.q = A / B
  If (((a ! b) >= 0) And (a % b <> 0))
    ProcedureReturn Temp + 1
  Else
    ProcedureReturn Temp
  EndIf
EndProcedure

; ##################################################### Includes ####################################################

XIncludeFile "Includes/Logging.pbi"
XIncludeFile "Includes/Object_Type.pbi"
XIncludeFile "Includes/Object.pbi"
XIncludeFile "Includes/About.pbi"
XIncludeFile "Includes/Window.pbi"
XIncludeFile "Includes/Node_Editor.pbi"
XIncludeFile "Includes/Object/File/Object_File.pbi"
XIncludeFile "Includes/Object/Dummy/Object_Dummy.pbi"
XIncludeFile "Includes/Object/Editor/Object_Editor.pbi"
XIncludeFile "Includes/Object/View1D/Object_View1D.pbi"
XIncludeFile "Includes/Object/View2D/Object_View2D.pbi"
XIncludeFile "Includes/Object/Random/Object_Random.pbi"
XIncludeFile "Includes/Object/History/Object_History.pbi"
XIncludeFile "Includes/Object/Process/Object_Process.pbi"
XIncludeFile "Includes/Object/Network_Terminal/Object_Network_Terminal.pbi"
;XIncludeFile "Includes/Object/Math/Object_Math.pbi"
;XIncludeFile "Includes/Object/MathFormula/Object_MathFormula.pbi"
XIncludeFile "Includes/Object/Data_Inspector/Object_Data_Inspector.pbi"
XIncludeFile "Includes/Object/Binary_Operation/Object_Binary_Operation.pbi"
XIncludeFile "Includes/Object/Copy/Object_Copy.pbi"

; ##################################################### Procedures ##################################################

Procedure.s SHGetFolderPath(CSIDL)
  Protected *String = AllocateMemory(#MAX_PATH+1)
  SHGetFolderPath_(0, CSIDL, #Null, 0, *String)
  Protected String.s = PeekS(*String)
  FreeMemory(*String)
  ProcedureReturn String
EndProcedure

Procedure Main_Window_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Main_Window\D3docker_Width = WindowWidth(Event_Window)
  Main_Window\D3docker_Height = WindowHeight(Event_Window) - Main_Window\Menu_Height - Main_Window\ToolBar_Height - Main_Window\StatusBar_Height
  ResizeGadget(Main_Window\D3docker, #PB_Ignore, #PB_Ignore, Main_Window\D3docker_Width, Main_Window\D3docker_Height)
EndProcedure

Procedure Main_Window_Open(Width, Height)
  
  Main_Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "D3hex V"+StrF(Main\Version*0.001,3), #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
  
  If Not Main_Window\ID
    ProcedureReturn 0
  EndIf
  
  SmartWindowRefresh(Main_Window\ID, #True)
  
  Main_Window\Menu_ID = CreateImageMenu(#PB_Any, WindowID(Main_Window\ID), #PB_Menu_ModernLook)
  If Not Main_Window\Menu_ID
    MessageRequester("D3hex", "Menü konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  MenuTitle("File")
  MenuItem(#Menu_New, "New", ImageID(Icon_New))
  MenuItem(#Menu_Save, "Save", ImageID(Icon_Save))
  MenuItem(#Menu_SaveAs, "Save as...", ImageID(Icon_SaveAs))
  MenuItem(#Menu_Close, "Close", ImageID(Icon_Close))
  MenuBar()
  MenuItem(#Menu_Open_File, "Open File...", ImageID(Icon_Open_File))
  MenuItem(#Menu_Open_Process, "Open Process...", ImageID(Icon_Open_Process))
  MenuItem(#Menu_Open_Clipboard, "Open Clipboard", ImageID(Icon_Open_Clipboard))  : DisableMenuItem(Main_Window\Menu_ID, #Menu_Open_Clipboard, #True)
  MenuItem(#Menu_Open_Random, "Open Random", ImageID(Icon_Open_Random))
  MenuItem(#Menu_Open_Network_Terminal, "Open Network Terminal", ImageID(Icon_Open_Network_Terminal))
  MenuBar()
  MenuItem(#Menu_Exit, "Exit")
  
  MenuTitle("Edit")
  MenuItem(#Menu_Undo, "Undo", ImageID(Icon_Undo))
  MenuItem(#Menu_Redo, "Redo", ImageID(Icon_Redo))
  MenuBar()
  MenuItem(#Menu_Cut, "Cut", ImageID(Icon_Cut))
  MenuItem(#Menu_Copy, "Copy", ImageID(Icon_Copy))
  MenuItem(#Menu_Paste, "Paste", ImageID(Icon_Paste))
  MenuBar()
  MenuItem(#Menu_Search, "Search", ImageID(Icon_Search))
  MenuItem(#Menu_Search_Continue, "Continue", ImageID(Icon_Search_Continue))
  MenuBar()
  MenuItem(#Menu_Goto, "Goto", ImageID(Icon_Goto))
  
  MenuTitle("Nodes")
  MenuItem(#Menu_Node_Editor, "Editor", ImageID(Icon_Node_Editor))
  MenuBar()
  MenuItem(#Menu_Node_Clear_Config, "Clear configuration", ImageID(Icon_Node_Clear_Config))
  MenuItem(#Menu_Node_Load_Config, "Load configuration", ImageID(Icon_Node_Load_Config))
  MenuItem(#Menu_Node_Save_Config, "Save configuration", ImageID(Icon_Node_Save_Config))
  
  ;MenuTitle("View")
  ;MenuItem(#Menu_View_Resize, "Resize", ImageID(Icon_Resize))
  
  ;MenuTitle("Visualisation")
  ;MenuItem(#Menu_Visualisation_Hilbert, "Hilbert View", ImageID(Icon_Hilbert))
  
  ;MenuTitle("Windows")
  ;MenuItem(#Menu_TileV, "Tile vertically")
  ;MenuItem(#Menu_TileH, "Tile horizontally")
  ;MenuItem(#Menu_Cascade, "Cascade")
  ;MenuItem(#Menu_Arrange, "Arrange")
  
  MenuTitle("?")
  MenuItem(#Menu_Help, "Help")
  MenuItem(#Menu_About, "About")
  
  ; ######################### Shortcuts
  
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_F, #Menu_Search)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_F3, #Menu_Search_Continue)
  
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_X, #Menu_Cut)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_C, #Menu_Copy)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_V, #Menu_Paste)
  
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_Z, #Menu_Undo)
  AddKeyboardShortcut(Main_Window\ID, #PB_Shortcut_Control | #PB_Shortcut_Y, #Menu_Redo)
  
  ; ######################### Toolbar
  
  Main_Window\ToolBar_ID = CreateToolBar(#PB_Any, WindowID(Main_Window\ID))
  If Not Main_Window\ToolBar_ID
    MessageRequester("D3hex", "ToolBar konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  ToolBarImageButton(#Menu_New, ImageID(Icon_New))
  ToolBarImageButton(#Menu_Save, ImageID(Icon_Save))
  ToolBarImageButton(#Menu_SaveAs, ImageID(Icon_SaveAs))
  ToolBarImageButton(#Menu_Close, ImageID(Icon_Close))
  ToolBarSeparator()
  ToolBarImageButton(#Menu_Open_File, ImageID(Icon_Open_File))
  ToolBarImageButton(#Menu_Open_Process, ImageID(Icon_Open_Process))
  ToolBarImageButton(#Menu_Open_Clipboard, ImageID(Icon_Open_Clipboard))  : DisableToolBarButton(Main_Window\ToolBar_ID, #Menu_Open_Clipboard, #True)
  ToolBarImageButton(#Menu_Open_Random, ImageID(Icon_Open_Random))
  ToolBarImageButton(#Menu_Open_Network_Terminal, ImageID(Icon_Open_Network_Terminal))
  ToolBarSeparator()
  ToolBarImageButton(#Menu_Node_Editor, ImageID(Icon_Node_Editor))
  
  ; ######################### Statusbar
  
  Main_Window\StatusBar_ID = CreateStatusBar(#PB_Any, WindowID(Main_Window\ID))
  If Not Main_Window\StatusBar_ID
    MessageRequester("D3hex", "Statusbar konnte nicht erstellt werden.")
    CloseWindow(Main_Window\ID)
    ProcedureReturn 0
  EndIf
  
  AddStatusBarField(150)
  AddStatusBarField(250)
  AddStatusBarField(150)
  
  ; ######################### Events
  
  BindEvent(#PB_Event_SizeWindow, @Main_Window_Event_SizeWindow(), Main_Window\ID)
  
  ; ######################### Größe
  
  Main_Window\Menu_Height = MenuHeight()
  Main_Window\ToolBar_Height =  ToolBarHeight(Main_Window\ToolBar_ID)
  Main_Window\StatusBar_Height =  StatusBarHeight(Main_Window\StatusBar_ID)
  
  Main_Window\D3docker_Width = Width
  Main_Window\D3docker_Height = Height - Main_Window\Menu_Height - Main_Window\ToolBar_Height - Main_Window\StatusBar_Height
  
  ; ################# Gadgets
  
  If UseGadgetList(WindowID(Main_Window\ID))
    Main_Window\D3docker = D3docker::Create(#PB_Any, 0, Main_Window\ToolBar_Height, Main_Window\D3docker_Width, Main_Window\D3docker_Height, Main_Window\ID)
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################

Main\Version = #Version

Main_Window_Open(1200, 700)

;Define *A.Object = Object_Dummy_Create()
;Define *B.Object = Object_Editor_Create()
;Object_Editor_Window_Open(*B)
;Define *C.Object = Object_Editor_Create()
;Object_Editor_Window_Open(*C)

;Object_Link_Connect(FirstElement(*A\Output()), FirstElement(*B\Input()))
;Object_Link_Connect(FirstElement(*A\Output()), FirstElement(*C\Input()))

;Node_Editor_Align_Object(*A)

Node_Editor_Open()

If FileSize(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex") < 0
  Node_Editor_Configuration_Load("Data\Default.D3hex")
Else
  Node_Editor_Configuration_Load(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex")
EndIf

; ##################################################### Main ########################################################

Repeat
  
  Define Event = WaitWindowEvent(10)
  Repeat
    Define Event_Window = EventWindow()
    Define Event_Type = EventType()
    
    Select Event_Window
      Case Main_Window\ID
        Select Event
          
          Case #PB_Event_Menu ; ####################
            Select EventMenu()
              Case #Menu_New
                Define *A.Object = Object_File_Create(#False)
                If *A
                  Define *B.Object = Object_History_Create(#False)
                  If *B
                    Define *C.Object = Object_Editor_Create(#False)
                    Object_Link_Connect(Object_Output_Get(*A, 0), Object_Input_Get(*B, 0))
                    Object_Link_Connect(Object_Output_Get(*B, 0), Object_Input_Get(*C, 0))
                    If *C And *C\Function_Window
                      *C\Function_Window(*C)
                    EndIf
                    Node_Editor_Align_Object(*A)
                  EndIf
                EndIf
                
              Case #Menu_Close
                
                
              Case #Menu_Save
                Define *Active_Window.Window = Window_Get_Active()
                Define Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Save
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_SaveAs
                Define *Active_Window.Window = Window_Get_Active()
                Define Object_Event.Object_Event
                Object_Event\Type = #Object_Event_SaveAs
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Open_File
                Define *A.Object = Object_File_Create(#True)
                If *A
                  Define *B.Object = Object_History_Create(#False)
                  If *B
                    Define *C.Object = Object_Editor_Create(#False)
                    Object_Link_Connect(Object_Output_Get(*A, 0), Object_Input_Get(*B, 0))
                    Object_Link_Connect(Object_Output_Get(*B, 0), Object_Input_Get(*C, 0))
                    If *C And *C\Function_Window
                      *C\Function_Window(*C)
                    EndIf
                    Node_Editor_Align_Object(*A)
                  EndIf
                EndIf
                
              Case #Menu_Open_Process
                Define *A.Object = Object_Process_Create(#True)
                If *A
                  Define *B.Object = Object_History_Create(#False)
                  If *B
                    Define *C.Object = Object_Editor_Create(#False)
                    Object_Link_Connect(Object_Output_Get(*A, 0), Object_Input_Get(*B, 0))
                    Object_Link_Connect(Object_Output_Get(*B, 0), Object_Input_Get(*C, 0))
                    If *C And *C\Function_Window
                      *C\Function_Window(*C)
                    EndIf
                    Node_Editor_Align_Object(*A)
                  EndIf
                EndIf
                
              Case #Menu_Open_Clipboard
                ;Object_Add("Clipboard", "CLP", Data_Source_Clipboard_Create())
                
              Case #Menu_Open_Random
                Define *A.Object = Object_Random_Create(#True)
                If *A
                  Define *B.Object = Object_History_Create(#False)
                  If *B
                    Define *C.Object = Object_Editor_Create(#False)
                    Object_Link_Connect(Object_Output_Get(*A, 0), Object_Input_Get(*B, 0))
                    Object_Link_Connect(Object_Output_Get(*B, 0), Object_Input_Get(*C, 0))
                    If *C And *C\Function_Window
                      *C\Function_Window(*C)
                    EndIf
                    Node_Editor_Align_Object(*A)
                  EndIf
                EndIf
                
              Case #Menu_Open_Network_Terminal
                Define *A.Object = Object_Network_Terminal_Create(#True)
                If *A
                  Define *B.Object = Object_Editor_Create(#False)
                  Define *C.Object = Object_Editor_Create(#False)
                  Object_Link_Connect(Object_Output_Get(*A, 0), Object_Input_Get(*B, 0))
                  Object_Link_Connect(Object_Output_Get(*A, 1), Object_Input_Get(*C, 0))
                  Node_Editor_Align_Object(*A)
                EndIf
                
              Case #Menu_Node_Editor
                Node_Editor_Open()
                
              Case #Menu_Node_Clear_Config
                Node_Editor_Configuration_Clear()
                
              Case #Menu_Node_Load_Config
                Define Filename.s = OpenFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
                If Filename
                  Node_Editor_Configuration_Load(Filename)
                EndIf
                
              Case #Menu_Node_Save_Config
                Define Filename.s = SaveFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
                If Filename
                  Node_Editor_Configuration_Save(Filename)
                EndIf
                
              Case #Menu_Cut
                Define *Active_Window.Window = Window_Get_Active()
                Define Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Cut
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Copy
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Copy
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Paste
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Paste
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Undo
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Undo
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Redo
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Redo
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Search
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Search
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Search_Continue
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Search_Continue
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_Goto
                *Active_Window.Window = Window_Get_Active()
                Object_Event.Object_Event
                Object_Event\Type = #Object_Event_Goto
                If *Active_Window And *Active_Window\Object And *Active_Window\Object\Function_Event
                  *Active_Window\Object\Function_Event(*Active_Window\Object, Object_Event)
                EndIf
                
              Case #Menu_About
                About_Open()
                
              Case #Menu_Exit
                Main\Quit = 1
                
            EndSelect
          
          Case #PB_Event_Gadget
            
          Case #PB_Event_CloseWindow
            Main\Quit = 1
            
          Case 0
            Break
            
        EndSelect
        
      Default
        If Not Event
          Break
        EndIf
        
    EndSelect
    
    Event = WindowEvent()
  ForEver
  
  ; ################## Main Function Calls
  
  Node_Editor_Main()
  About_Main()
  Logging_Main()
  
  ForEach Object()
    If Object()\Function_Main
      Object()\Function_Main(Object())
    EndIf
  Next
  
  ; ###################
  
  Delay(10)
  
Until Main\Quit

; ##################################################### End #########################################################

CreateDirectory(SHGetFolderPath(#CSIDL_APPDATA)+"\D3")
CreateDirectory(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor")

Node_Editor_Configuration_Save(SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex")

; ##################################################### Data Sections ###############################################

DataSection
  Icon_New: : IncludeBinary "Data/Icons/New.png"
  Icon_Save: : IncludeBinary "Data/Icons/Save.png"
  Icon_SaveAs: : IncludeBinary "Data/Icons/SaveAs.png"
  Icon_Open_File: : IncludeBinary "Data/Icons/Open_File.png"
  Icon_Undo: : IncludeBinary "Data/Icons/Undo.png"
  Icon_Redo: : IncludeBinary "Data/Icons/Redo.png"
  Icon_Cut: : IncludeBinary "Data/Icons/Cut.png"
  Icon_Copy: : IncludeBinary "Data/Icons/Copy.png"
  Icon_Paste: : IncludeBinary "Data/Icons/Paste.png"
  Icon_Select_All: : IncludeBinary "Data/Icons/Select_All.png"
  Icon_Open_Process: : IncludeBinary "Data/Icons/Open_Process.png"
  Icon_Open_Clipboard: : IncludeBinary "Data/Icons/Open_Clipboard.png"
  Icon_Open_Random: : IncludeBinary "Data/Icons/Open_Random.png"
  Icon_Open_Network_Terminal: : IncludeBinary "Data/Icons/Open_Network_Terminal.png"
  Icon_Node_Editor: : IncludeBinary "Data/Icons/Node_Editor.png"
  Icon_Node_Clear_Config: : IncludeBinary "Data/Icons/Node_Clear_Config.png"
  Icon_Node_Load_Config: : IncludeBinary "Data/Icons/Node_Load_Config.png"
  Icon_Node_Save_Config: : IncludeBinary "Data/Icons/Node_Save_Config.png"
  Icon_Close: : IncludeBinary "Data/Icons/Close.png"
  Icon_Resize: : IncludeBinary "Data/Icons/Resize.png"
  Icon_Hilbert: : IncludeBinary "Data/Icons/Hilbert.png"
  Icon_Gear: : IncludeBinary "Data/Icons/Gear.png"
  Icon_Grid: : IncludeBinary "Data/Icons/Grid.png"
  Icon_Search: : IncludeBinary "Data/Icons/Search.png"
  Icon_Search_Continue: : IncludeBinary "Data/Icons/Search_Continue.png"
  Icon_Goto: : IncludeBinary "Data/Icons/Goto.png"
  
EndDataSection
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 169
; FirstLine = 131
; Folding = --
; EnableUnicode
; EnableXP