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
; Todo:
; - Each node HAS to return an segment-list via ...Get_Segments(...)
; - Store/Restore Window states/positions into/from the configurations.
; - Negative positions in Output_Get_Data() should be allowed, but shouldn't return #Metadata_NoError
; - Support different code pages
;   
; - Editor:
;   - Autoscroll
;   - Implement Boyer-Moore as search algorithm
;   
; - History node:
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
;   - Diskrete Fourier Transformation (bzw. FFT)
;   - Disassembler (x86/64, 6809, ...)
;   - Audiowiedergabe
;   - Cheat-Engine like node
;   - Text-Editor
;   
; - Data_Source elemente
;   - Signalgeneratoren (Ausgabe verschiedener Datentypen (Byte, Word, Long, Float, Double...))
;   - Physikalische / Logische Datenträger
;   - Serial Port
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
;   - Node "Editor":
;     - added Scrollbar (can handle more than 2^32 lines)
;     - Shift the marked range when adding or deleting data.
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
;   - Added a GUI to the "File" node
;   - Added events to all kind of stuff: Save, SaveAs, Goto, Search, Continue, Load/Save-Config, Undo, Redo, Cut, Copy, Paste
;   - Added History Node
;   - Logging And Error messages
;   
; - V0.912 (25.02.2014)
;   - Less Window-Flickering with SmartWindowRefresh()
;   - Tab-Bar fires now a close-event to the window
;   
; - V0.920 (02.03.2014)
;   - Node "Editor":
;     - Search:
;       - Corrected the Raw_Keyword_Size when including the zero byte with ucs-2 (Search_Prepare_Keyword_Helper(Type))
;       - Corrected the single replace mode...  (Store the found position in the search element, and use that for replacement! Not the selected range!)
;       - Made search much faster
;       - Search now only searches in readable segments
;     - Added statusbar-text
;     - Nibble-writing is now cached
;     - Provide the selected range as output
;   - Added process data-source
;   - Using a flag instead of several node-types for opening and reopening
;   - Network terminal
;   
; - V0.925 (10.08.2014)
;   - Fixed loading of the default D3hex file
;   - Added names to node-inputs and outputs
;   - Node: Editor:
;     - Fixed the goto stuff
;   - All Windows of the nodes are now managed by Window.pbi
;   - Added Set_Data_Check and Shift_Check functions
;   - Added node "Datatypes"
;   - Fixed crash because of wrong pointer returned from Window_Create(...)
;   
; - V0.930 (15.08.2014)
;   - Added node "Binary_Operation"
;   - Added node "Copy"
;   - Update every structure allocation to AllocateStructure(...) and FreeStructure(...)
;   
; - V0.940 (05.01.2015)
;   - Fixed possible crash with node "Editor" (String generation in search wrote Null-Bytes outside of the memory)
;   - NBT loading And saving is a bit faster
;   - Node "Copy": Display progress
;   - Added a unit engine To format numbers With SI-prefixes...
;   - Node "View1D": Fixed "Jumping out of the screen" when normalizing the x-axis
;   - Renamed And moved all node-includes
;   - Renamed the node "Datatypes" To "Data Inspector"
;   - Added View2D, viewer For raster graphics
;   - Data descriptor changed To NBT
;   - Node "Editor": limited marked output To selection
;   - Node "Random": limited output To size
;   
; - V0.941 (06.01.2015)
;   - Node "Editor": Fixed writing at the end of data
;   - Node "View2D": Added standard configuration
;   
; - V0.967 (13.07.2015)
;   - Node "File": Ignore result of File-requesters if it is ""
;   - Network_Terminal:
;     - Data_Set is not triggering an update event
;     - "History" node is now working with Network_Terminal
;     - Renamed output and input to sent and received
;   - Node "History":
;     - Added the option to allow write operations in any case
;   - Use D3docker.pbi instead of the mdi gadget
;   - Shortcuts now work in undocked windows
;   - Continued implementation of "Data descriptors"
;   - Names of the node-windows now depend on the parent nodes
;   - Node "Data_Inspector":
;     - Resized the gadget a bit
;   - Fixed crash
;   - Statusbar works again for node "Editor"
;   - Splitted the code in modules
;   - Added node for hash-generation
;   - Scrollbars and window dragging doesn't block the program anymore
;   - Files can be dragged inside the Node-Editor
;   - Window::Create(...) has now a flag variable
;   - Bugfixing and improvements in View1D and View2D
;     - Added uint32 and uint64 to View1D
;   - Fixed the string encoding
;   - Added Tooltips
;   - Changed colors in node "Editor"
;   - Added an event distributor for shortcut, menu and toolbar events
;   - Many other small changes and refactoring
;   
; - V0.969 (INDEV)
;   - Editor node:
;     - Select all does now trigger an update event
;   - Hash generator node:
;     - More hashfunctions (CRC32, MD5, SHA-1, SHA-2 (244), SHA-2 (256), SHA-2 (384), SHA-2 (512), SHA-3 (244), SHA-3 (256), SHA-3 (384), SHA-3 (512))
;   
;   
; ##################################################### Begin #######################################################

EnableExplicit

UsePNGImageDecoder()
UsePNGImageEncoder()

; ##################################################### External Includes ###########################################

XIncludeFile "Includes/Julia/julia.pbi"
XIncludeFile "Includes/D3docker/D3docker.pbi"
XIncludeFile "Includes/D3HT.pbi"
XIncludeFile "Includes/D3NBT.pbi"

; ##################################################### Includes ####################################################

XIncludeFile "Includes/Helper.pbi"
XIncludeFile "Includes/Memory.pbi"
XIncludeFile "Includes/Crash.pbi"
XIncludeFile "Includes/UnitEngine.pbi"
XIncludeFile "Includes/Logger.pbi"
XIncludeFile "Includes/Constants.pbi"
XIncludeFile "Includes/Icons.pbi"

DeclareModule Main
  EnableExplicit
  ; ################################################### Constants ###################################################
  #Version = 0969
  
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
    
    #Menu_Select_All
    #Menu_Goto
    
    ;#Menu_TileV
    ;#Menu_TileH
    ;#Menu_Cascade
    ;#Menu_Arrange
    
    #Menu_Help
    #Menu_About
    
    #Menu_Custom_Shortcuts
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  Structure Main
    Version.i
    
    Quit.i
  EndStructure
  Global Main.Main
  
  Structure Window
    ID.i
    Menu_ID.i
    ToolBar_ID.i
    StatusBar_ID.i
    
    D3docker.i
    D3docker_Height.i
    D3docker_Width.i
    
    Menu_Height.i
    ToolBar_Height.i
    StatusBar_Height.i
  EndStructure
  Global Window.Window
  
  ; ################################################### Variables ###################################################

  ; ################################################### Functions ###################################################
  Declare   Window_KeyboardShortcut_Update()
  
EndDeclareModule

; ##################################################### Includes ####################################################

XIncludeFile "Includes/Node_Type.pbi"
XIncludeFile "Includes/Node.pbi"
XIncludeFile "Includes/About.pbi"
XIncludeFile "Includes/Window.pbi"

XIncludeFile "Includes/Julia_API.pbi"

XIncludeFile "Includes/Nodes/Binary_Operation/Binary_Operation.pbi"
XIncludeFile "Includes/Nodes/Copy/Copy.pbi"
XIncludeFile "Includes/Nodes/Data_Inspector/Data_Inspector.pbi"
XIncludeFile "Includes/Nodes/Dummy/Dummy.pbi"
XIncludeFile "Includes/Nodes/Editor/Editor.pbi"
XIncludeFile "Includes/Nodes/File/File.pbi"
XIncludeFile "Includes/Nodes/Hash_Generator/Hash_Generator.pbi"
XIncludeFile "Includes/Nodes/History/History.pbi"
;XIncludeFile "Includes/Nodes/Math/Math.pbi"
;XIncludeFile "Includes/Nodes/MathFormula/MathFormula.pbi"
XIncludeFile "Includes/Nodes/Network_Terminal/Network_Terminal.pbi"
XIncludeFile "Includes/Nodes/Process/Process.pbi"
XIncludeFile "Includes/Nodes/Random/Random.pbi"
XIncludeFile "Includes/Nodes/View1D/View1D.pbi"
XIncludeFile "Includes/Nodes/View2D/View2D.pbi"
XIncludeFile "Includes/Nodes/Julia/Julia.pbi"

XIncludeFile "Includes/Node_Editor.pbi"

Module Main
  ; ################################################### Includes ####################################################
  UseModule Icons
  
  ; ################################################### Declares ####################################################
  Declare   Main()
  
  ; ################################################### Procedures ##################################################
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    Window\D3docker_Width = WindowWidth(Event_Window)
    Window\D3docker_Height = WindowHeight(Event_Window) - Window\Menu_Height - Window\ToolBar_Height - Window\StatusBar_Height
    ResizeGadget(Window\D3docker, #PB_Ignore, #PB_Ignore, Window\D3docker_Width, Window\D3docker_Height)
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Menu = EventMenu()
    
    Protected *Node.Node::Object
    Protected *A.Node::Object, *B.Node::Object, *C.Node::Object
    Protected *Active_Window.Window::Object
    Protected Node_Event.Node::Event
    
    Protected Filename.s
    
    Select Event_Menu
      Case #Menu_New
        *A.Node::Object = _Node_File::Create(#False)
        If *A
          *B.Node::Object = _Node_History::Create(#False)
          If *B
            *C.Node::Object = _Node_Editor::Create(#False)
            Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
            Node::Link_Connect(Node::Output_Get(*B, 0), Node::Input_Get(*C, 0))
            If *C And *C\Function_Window
              *C\Function_Window(*C)
            EndIf
            Node_Editor::Align_Object(*A)
          EndIf
        EndIf
        
      Case #Menu_Close
        
      Case #Menu_Open_File
        *A.Node::Object = _Node_File::Create(#True)
        If *A
          *B.Node::Object = _Node_History::Create(#False)
          If *B
            *C.Node::Object = _Node_Editor::Create(#False)
            Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
            Node::Link_Connect(Node::Output_Get(*B, 0), Node::Input_Get(*C, 0))
            If *C And *C\Function_Window
              *C\Function_Window(*C)
            EndIf
            Node_Editor::Align_Object(*A)
          EndIf
        EndIf
        
      Case #Menu_Open_Process
        *A.Node::Object = _Node_Process::Create(#True)
        If *A
          *B.Node::Object = _Node_History::Create(#False)
          If *B
            *C.Node::Object = _Node_Editor::Create(#False)
            Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
            Node::Link_Connect(Node::Output_Get(*B, 0), Node::Input_Get(*C, 0))
            If *C And *C\Function_Window
              *C\Function_Window(*C)
            EndIf
            Node_Editor::Align_Object(*A)
          EndIf
        EndIf
        
      Case #Menu_Open_Clipboard
        ;Object_Add("Clipboard", "CLP", Data_Source_Clipboard_Create())
        
      Case #Menu_Open_Random
        *A.Node::Object = _Node_Random::Create(#True)
        If *A
          *B.Node::Object = _Node_History::Create(#False)
          If *B
            *C.Node::Object = _Node_Editor::Create(#False)
            Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
            Node::Link_Connect(Node::Output_Get(*B, 0), Node::Input_Get(*C, 0))
            If *C And *C\Function_Window
              *C\Function_Window(*C)
            EndIf
            Node_Editor::Align_Object(*A)
          EndIf
        EndIf
        
      Case #Menu_Open_Network_Terminal
        *A.Node::Object = _Node_Network_Terminal::Create(#True)
        If *A
          *B.Node::Object = _Node_Editor::Create(#False)
          *C.Node::Object = _Node_Editor::Create(#False)
          Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
          Node::Link_Connect(Node::Output_Get(*A, 1), Node::Input_Get(*C, 0))
          Node_Editor::Align_Object(*A)
        EndIf
        
      Case #Menu_Node_Editor
        Node_Editor::Open()
        
      Case #Menu_Node_Clear_Config
        Node_Editor::Configuration_Clear()
        
      Case #Menu_Node_Load_Config
        Filename.s = OpenFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
        If Filename
          Node_Editor::Configuration_Load(Filename)
        EndIf
        
      Case #Menu_Node_Save_Config
        Filename.s = SaveFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
        If Filename
          Node_Editor::Configuration_Save(Filename)
        EndIf
        
      Case #Menu_About
        About::Open()
        
      Case #Menu_Exit
        Main\Quit = 1
        
      Default
        *Active_Window.Window::Object = Window::Get_Active()
        If *Active_Window
          If Event_Menu - #Menu_Custom_Shortcuts >= 0
            ; #### Custom menu event
            If SelectElement(*Active_Window\KeyboardShortcut(), Event_Menu - #Menu_Custom_Shortcuts)
              PostEvent(#PB_Event_Menu, *Active_Window\ID, *Active_Window\KeyboardShortcut()\Event_Menu)
            EndIf
          Else
            ; #### Menu event of the main window
            ForEach *Active_Window\KeyboardShortcut()
              If *Active_Window\KeyboardShortcut()\Main_Menu = Event_Menu
                PostEvent(#PB_Event_Menu, *Active_Window\ID, *Active_Window\KeyboardShortcut()\Event_Menu)
                Break
              EndIf
            Next
          EndIf
        EndIf
        
    EndSelect
  EndProcedure
  
  Procedure Window_Event_Timer()
    Main()
  EndProcedure
  
  Procedure Window_Event_CloseWindow()
    Main\Quit = 1
  EndProcedure
  
  Procedure Window_KeyboardShortcut_Update()
    Protected *Active_Window.Window::Object = Window::Get_Active()
    
    RemoveKeyboardShortcut(Window\ID, #PB_Shortcut_All)
    
    DisableToolBarButton(Window\ToolBar_ID, #Menu_Save, #True)
    DisableToolBarButton(Window\ToolBar_ID, #Menu_SaveAs, #True)
    DisableToolBarButton(Window\ToolBar_ID, #Menu_Close, #True)
    
    DisableMenuItem(Window\Menu_ID, #Menu_Save, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_SaveAs, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Close, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Undo, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Redo, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Cut, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Copy, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Paste, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Search, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Search_Continue, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Select_All, #True)
    DisableMenuItem(Window\Menu_ID, #Menu_Goto, #True)
    
    If *Active_Window
      ForEach *Active_Window\KeyboardShortcut()
        If *Active_Window\KeyboardShortcut()\Key
          AddKeyboardShortcut(Window\ID, *Active_Window\KeyboardShortcut()\Key, #Menu_Custom_Shortcuts + ListIndex(*Active_Window\KeyboardShortcut()))
        EndIf
        
        If *Active_Window\KeyboardShortcut()\Main_Menu
          DisableToolBarButton(Window\ToolBar_ID, *Active_Window\KeyboardShortcut()\Main_Menu, #False)
          DisableMenuItem(Window\Menu_ID, *Active_Window\KeyboardShortcut()\Main_Menu, #False)
        EndIf
      Next
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Open(Width, Height)
    
    Window\ID = OpenWindow(#PB_Any, 0, 0, Width, Height, "D3hex V"+StrF(Main\Version*0.001,3), #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
    
    If Not Window\ID
      ProcedureReturn 0
    EndIf
    
    SmartWindowRefresh(Window\ID, #True)
    
    Window\Menu_ID = CreateImageMenu(#PB_Any, WindowID(Window\ID))
    If Not Window\Menu_ID
      MessageRequester("D3hex", "Menü konnte nicht erstellt werden.")
      CloseWindow(Window\ID)
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
    MenuItem(#Menu_Open_Clipboard, "Open Clipboard", ImageID(Icon_Open_Clipboard))  : DisableMenuItem(Window\Menu_ID, #Menu_Open_Clipboard, #True)
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
    MenuItem(#Menu_Select_All, "Select all")
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
    
    ; ######################### Shortcuts (Only global ones. No undo, copy, paste, ...)
    
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_F, #Menu_Search)
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_F3, #Menu_Search_Continue)
    
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_X, #Menu_Cut)
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_C, #Menu_Copy)
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_V, #Menu_Paste)
    
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_Z, #Menu_Undo)
    ;AddKeyboardShortcut(Window\ID, #PB_Shortcut_Control | #PB_Shortcut_Y, #Menu_Redo)
    
    ; ######################### Toolbar
    
    Window\ToolBar_ID = CreateToolBar(#PB_Any, WindowID(Window\ID))
    If Not Window\ToolBar_ID
      MessageRequester("D3hex", "Failed to create ToolBar. Program will shutdown.")
      CloseWindow(Window\ID)
      End
    EndIf
    
    ToolBarImageButton(#Menu_New, ImageID(Icon_New))
    ToolBarImageButton(#Menu_Save, ImageID(Icon_Save))
    ToolBarImageButton(#Menu_SaveAs, ImageID(Icon_SaveAs))
    ToolBarImageButton(#Menu_Close, ImageID(Icon_Close))
    ToolBarSeparator()
    ToolBarImageButton(#Menu_Open_File, ImageID(Icon_Open_File))
    ToolBarImageButton(#Menu_Open_Process, ImageID(Icon_Open_Process))
    ToolBarImageButton(#Menu_Open_Clipboard, ImageID(Icon_Open_Clipboard))  : DisableToolBarButton(Window\ToolBar_ID, #Menu_Open_Clipboard, #True)
    ToolBarImageButton(#Menu_Open_Random, ImageID(Icon_Open_Random))
    ToolBarImageButton(#Menu_Open_Network_Terminal, ImageID(Icon_Open_Network_Terminal))
    ToolBarSeparator()
    ToolBarImageButton(#Menu_Node_Editor, ImageID(Icon_Node_Editor))
    
    ; ######################### Statusbar
    
    Window\StatusBar_ID = CreateStatusBar(#PB_Any, WindowID(Window\ID))
    If Not Window\StatusBar_ID
      MessageRequester("D3hex", "Failed to create StatusBar. Program will shutdown.")
      CloseWindow(Window\ID)
      End
    EndIf
    
    AddStatusBarField(150)
    AddStatusBarField(250)
    AddStatusBarField(150)
    
    ; ######################### Timer
    
    AddWindowTimer(Window\ID, 0, 100)
    
    ; ######################### Events
    
    BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), Window\ID)
    BindEvent(#PB_Event_Menu, @Window_Event_Menu(), Window\ID)
    BindEvent(#PB_Event_Timer, @Window_Event_Timer(), Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), Window\ID)
    
    ; ######################### Größe
    
    Window\Menu_Height = MenuHeight()
    Window\ToolBar_Height =  ToolBarHeight(Window\ToolBar_ID)
    Window\StatusBar_Height =  StatusBarHeight(Window\StatusBar_ID)
    
    Window\D3docker_Width = Width
    Window\D3docker_Height = Height - Window\Menu_Height - Window\ToolBar_Height - Window\StatusBar_Height
    
    ; ################# Gadgets
    
    If UseGadgetList(WindowID(Window\ID))
      Window\D3docker = D3docker::Create(#PB_Any, 0, Window\ToolBar_Height, Window\D3docker_Width, Window\D3docker_Height, Window\ID)
    EndIf
    
    ; ################# Other
    
    Window_KeyboardShortcut_Update()
  EndProcedure
  
  Procedure Main()
    
    Node_Editor::Main()
    About::Main()
    Logger::Main()
    
    ForEach Node::Object()
      If Node::Object()\Function_Main
        Node::Object()\Function_Main(Node::Object())
      EndIf
    Next
    
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Version = #Version
  
  Window_Open(1200, 700)
  
  Logger::Init(Window\ID)
  Window::Init(Window\ID, Window\D3docker, Window\StatusBar_ID)
  
  ; #### Init Julia
  Julia_API::Init()
  
  Node_Editor::Open()
  
  If FileSize(Helper::SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex") < 0
    Node_Editor::Configuration_Load("Data\Default.D3hex")
  Else
    Node_Editor::Configuration_Load(Helper::SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex")
  EndIf
  
  ; ################################################### Main ########################################################
  
  Repeat
    
    If WaitWindowEvent(10)
      While WindowEvent()
      Wend
    EndIf
    
    ; ################### Main functions of all modules
    
    Main()
    
  Until Main\Quit
  
  ; ################################################### End #########################################################
  
  CreateDirectory(Helper::SHGetFolderPath(#CSIDL_APPDATA)+"\D3")
  CreateDirectory(Helper::SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor")
  
  Node_Editor::Configuration_Save(Helper::SHGetFolderPath(#CSIDL_APPDATA)+"\D3\Hexeditor\Node_Configuration.D3hex")
  
  ; #### Deinit Julia
  Julia_API::Deinit()
  
  ; ################################################### Data Sections ###############################################
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 718
; FirstLine = 671
; Folding = --
; EnableUnicode
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant