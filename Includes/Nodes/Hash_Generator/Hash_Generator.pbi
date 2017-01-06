; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2015-2017  David Vogel
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
; TODO: Add more hash-functions
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule _Node_Hash_Generator
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Hash_Generator
  ; ################################################### Init ########################################################
  UseCRC32Fingerprint()
  UseMD5Fingerprint()
  UseSHA1Fingerprint()
  UseSHA2Fingerprint()
  UseSHA3Fingerprint()
  
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Menu_Automatic
    #Menu_Refresh
  EndEnumeration
  
  Enumeration
    #Hash_State_Idle
    #Hash_State_Calculate
    #Hash_State_Done
  EndEnumeration
  
  #Chunk_Size = 1024*100
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Hash
    Name.s
    
    Plugin.i
    Bits.i
    
    Item_State.i
    State.i
    Position.i
    
    Result.s
    
    Fingerprint_ID.i      ; From Examine...Fingerprint()
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    ToolBar.i
    ListIcon.i
    
    Update_ListIcon.i
    
    ; #### Hash state
    Automatic.i
    
    Size.q
    
    List Hash.Hash()
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Init ########################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Window_Close(*Node.Node::Object)
  
  Declare   Hash_Reset(*Node.Node::Object, *Hash.Hash, Force_Calculate = #False)
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input.Node::Conn_Input
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    *Node\Type = Main\Node_Type
    *Node\Type_Base = Main\Node_Type
    
    *Node\Function_Delete = @_Delete()
    *Node\Function_Main = @Main()
    *Node\Function_Window = @Window_Open()
    *Node\Function_Configuration_Get = @Configuration_Get()
    *Node\Function_Configuration_Set = @Configuration_Set()
    
    *Node\Name = Main\Node_Type\Name
    *Node\Name_Inherited = *Node\Name
    *Node\Color = RGBA(150,50,100,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### Add Input
    *Input = Node::Input_Add(*Node)
    *Input\Function_Event = @Input_Event()
    
    ; #### Add hash functions
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "CRC32"
    *Object\Hash()\Plugin = #PB_Cipher_CRC32
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "MD5"
    *Object\Hash()\Plugin = #PB_Cipher_MD5
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-1"
    *Object\Hash()\Plugin = #PB_Cipher_SHA1
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-2 (224)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA2
    *Object\Hash()\Bits = 224
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-2 (256)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA2
    *Object\Hash()\Bits = 256
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-2 (384)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA2
    *Object\Hash()\Bits = 384
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-2 (512)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA2
    *Object\Hash()\Bits = 512
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-3 (224)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA3
    *Object\Hash()\Bits = 224
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-3 (256)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA3
    *Object\Hash()\Bits = 256
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-3 (384)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA3
    *Object\Hash()\Bits = 384
    
    AddElement(*Object\Hash())
    *Object\Hash()\Name = "SHA-3 (512)"
    *Object\Hash()\Plugin = #PB_Cipher_SHA3
    *Object\Hash()\Bits = 512
    
    ProcedureReturn *Node
  EndProcedure
  
  Procedure _Delete(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Window_Close(*Node)
    
    FreeStructure(*Object)
    *Node\Custom_Data = #Null
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    If Not *Parent_Tag
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Automatic", NBT::#Tag_Byte) : NBT::Tag_Set_Number(*NBT_Tag, *Object\Automatic)
    
    ForEach *Object\Hash()
      *NBT_Tag = NBT::Tag_Add(*Parent_Tag, *Object\Hash()\Name+"_Activated", NBT::#Tag_Byte) : NBT::Tag_Set_Number(*NBT_Tag, *Object\Hash()\Item_State)
    Next
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    Protected New_Size.i, *Temp
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    If Not *Parent_Tag
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Automatic") : *Object\Automatic = NBT::Tag_Get_Number(*NBT_Tag)
    
    ForEach *Object\Hash()
      *NBT_Tag = NBT::Tag(*Parent_Tag, *Object\Hash()\Name+"_Activated") : *Object\Hash()\Item_State = NBT::Tag_Get_Number(*NBT_Tag)
    Next
    
    If *Object\Automatic
      ForEach *Object\Hash()
        Hash_Reset(*Node, *Object\Hash())
      Next
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Update_ListIcon(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Hash()
      ; #### Update message
      Select *Object\Hash()\State
        Case #Hash_State_Idle
          SetGadgetItemText(*Object\ListIcon, ListIndex(*Object\Hash()), "", 1)
          
        Case #Hash_State_Calculate
          If *Object\Hash()\Item_State & #PB_ListIcon_Checked
            SetGadgetItemText(*Object\ListIcon, ListIndex(*Object\Hash()), "Calculating "+StrF(*Object\Hash()\Position / *Object\Size * 100,2)+"%", 1)
          Else
            SetGadgetItemText(*Object\ListIcon, ListIndex(*Object\Hash()), "", 1)
          EndIf
          
        Case #Hash_State_Done
          SetGadgetItemText(*Object\ListIcon, ListIndex(*Object\Hash()), *Object\Hash()\Result, 1)
          
      EndSelect
      
      ; #### Update checkboxes
      SetGadgetItemState(*Object\ListIcon, ListIndex(*Object\Hash()), *Object\Hash()\Item_State)
    Next
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
    If Not *Input
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Input\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected *Descriptor.NBT::Element
    
    Select *Event\Type
      Case Node::#Link_Event_Update_Descriptor
        *Descriptor = Node::Input_Get_Descriptor(*Input)
        If *Descriptor
          *Node\Name_Inherited = *Node\Name + " ← " + NBT::Tag_Get_String(NBT::Tag(*Descriptor\Tag, "Name"))
          NBT::Error_Get()
        Else
          *Node\Name_Inherited = *Node\Name
        EndIf
        If *Object\Window
          SetWindowTitle(*Object\Window\ID, *Node\Name_Inherited)
        EndIf
        
      Case Node::#Link_Event_Update
        *Object\Update_ListIcon = #True
        
        ForEach *Object\Hash()
          ForEach *Object\Hash()
            Hash_Reset(*Node, *Object\Hash())
          Next
        Next
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Event_ListIcon()
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
    
    ForEach *Object\Hash()
      *Object\Hash()\Item_State = GetGadgetItemState(Event_Gadget, ListIndex(*Object\Hash()))
    Next
    
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
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
    
    ResizeGadget(*Object\ListIcon, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window), WindowHeight(Event_Window)-ToolBarHeight(*Object\ToolBar))
    
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
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
    
    Select Event_Menu
      Case #Menu_Automatic
        *Object\Automatic = GetToolBarButtonState(*Object\ToolBar, #Menu_Automatic)
        If *Object\Automatic
          ForEach *Object\Hash()
            If *Object\Hash()\State = #Hash_State_Idle
              Hash_Reset(*Node, *Object\Hash())
            EndIf
          Next
        EndIf
        
      Case #Menu_Refresh
        ForEach *Object\Hash()
          Hash_Reset(*Node, *Object\Hash(), #True)
        Next
        
    EndSelect
  EndProcedure
  
  Procedure Window_Event_CloseWindow()
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
    
    *Object\Window_Close = #True
  EndProcedure
  
  Procedure Window_Open(*Node.Node::Object)
    Protected Width, Height
    Protected ToolBarHeight
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Window
      
      Width = 500
      Height = 200
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height, Window::#Flag_Resizeable)
      
      ; #### Toolbar
      *Object\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object\Window\ID))
      ToolBarImageButton(#Menu_Automatic, ImageID(Icons::Icon_Automatic), #PB_ToolBar_Toggle) : SetToolBarButtonState(*Object\ToolBar, #Menu_Automatic, *Object\Automatic)
      ToolBarImageButton(#Menu_Refresh, ImageID(Icons::Icon_Refresh))
      
      ToolBarToolTip(*Object\ToolBar, #Menu_Automatic, "Refresh automatically")
      ToolBarToolTip(*Object\ToolBar, #Menu_Refresh, "Refresh") 
      
      ToolBarHeight = ToolBarHeight(*Object\ToolBar)
      
      ; #### Gadgets
      
      *Object\ListIcon = ListIconGadget(#PB_Any, 0, ToolBarHeight, Width, Height - ToolBarHeight, "Function", 100, #PB_ListIcon_CheckBoxes | #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
      AddGadgetColumn(*Object\ListIcon, 1, "Hash", 500)
      
      ; #### Add ListIcon items
      ForEach *Object\Hash()
        AddGadgetItem(*Object\ListIcon,  ListIndex(*Object\Hash()), *Object\Hash()\Name)
      Next
      
      BindGadgetEvent(*Object\ListIcon, @Window_Event_ListIcon())
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      *Object\Update_ListIcon = #True
      
    Else
      Window::Set_Active(*Object\Window)
    EndIf
  EndProcedure
  
  Procedure Window_Close(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window
      
      UnbindGadgetEvent(*Object\ListIcon, @Window_Event_ListIcon())
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      Window::Delete(*Object\Window)
      *Object\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Hash_Reset(*Node.Node::Object, *Hash.Hash, Force_Calculate = #False)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Hash\Position = 0
    
    If *Hash\Fingerprint_ID
      FinishFingerprint(*Hash\Fingerprint_ID)
      *Hash\Fingerprint_ID = 0
    EndIf
    
    If *Object\Automatic Or Force_Calculate
      *Hash\State = #Hash_State_Calculate
    Else
      *Hash\State = #Hash_State_Idle
    EndIf
    
    *Object\Update_ListIcon = #True
    
  EndProcedure
  
  Procedure Calculate(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Calculate
    Protected Position.q
    Protected Data_Size.i, *Data
    Protected Start_Time.q = ElapsedMilliseconds()
    
    *Object\Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
    
    If *Object\Size < 0
      ProcedureReturn #False
    EndIf
    
    ; #### Initialize the hash functions if it doesn't have precalculated values
    ForEach *Object\Hash()
      If *Object\Hash()\State = #Hash_State_Calculate And *Object\Hash()\Item_State & #PB_ListIcon_Checked
        If Not *Object\Hash()\Fingerprint_ID
          *Object\Hash()\Fingerprint_ID = StartFingerprint(#PB_Any, *Object\Hash()\Plugin, *Object\Hash()\Bits)
        EndIf
      EndIf
    Next
    
    Repeat
      Calculate = #False
      
      ; #### Get the lowest position of all hash functions
      Position = *Object\Size
      ForEach *Object\Hash()
        If *Object\Hash()\State = #Hash_State_Calculate And *Object\Hash()\Item_State & #PB_ListIcon_Checked
          If Position > *Object\Hash()\Position
            Position = *Object\Hash()\Position
          EndIf
        EndIf
      Next
      
      ; #### Get the data
      If Position < *Object\Size
        Data_Size = *Object\Size - Position
        If Data_Size > #Chunk_Size
          Data_Size = #Chunk_Size
        EndIf
        *Data = AllocateMemory(Data_Size)
        If Node::Input_Get_Data(FirstElement(*Node\Input()), Position, Data_Size, *Data, #Null)
          
          ; #### Calculate the hash
          ForEach *Object\Hash()
            If *Object\Hash()\State = #Hash_State_Calculate And *Object\Hash()\Item_State & #PB_ListIcon_Checked And *Object\Hash()\Position = Position And *Object\Hash()\Fingerprint_ID
              AddFingerprintBuffer(*Object\Hash()\Fingerprint_ID, *Data, Data_Size)
              *Object\Hash()\Position + Data_Size
              *Object\Update_ListIcon = #True
              Calculate = #True
            EndIf
          Next
          
        EndIf
        
        FreeMemory(*Data) : *Data = #Null
      Else
        
        ; #### finish the hash
        ForEach *Object\Hash()
          If *Object\Hash()\State = #Hash_State_Calculate And *Object\Hash()\Item_State & #PB_ListIcon_Checked And *Object\Hash()\Fingerprint_ID
            *Object\Hash()\Result = UCase(FinishFingerprint(*Object\Hash()\Fingerprint_ID)) : *Object\Hash()\Fingerprint_ID = 0
            *Object\Hash()\State = #Hash_State_Done
            *Object\Update_ListIcon = #True
          EndIf
        Next
        
      EndIf
      
    Until Calculate = #False Or Start_Time + 15 < ElapsedMilliseconds()
    
  EndProcedure
  
  Procedure Main(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Calculate(*Node)
    
    If *Object\Window
      If *Object\Update_ListIcon
        *Object\Update_ListIcon = #False
        Update_ListIcon(*Node)
      EndIf
    EndIf
    
    If *Object\Window_Close
      *Object\Window_Close = #False
      Window_Close(*Node)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Node_Type = Node_Type::Create()
  If Main\Node_Type
    Main\Node_Type\Category = "Viewer"
    Main\Node_Type\Name = "Hash Generator"
    Main\Node_Type\UID = "D3__HASH"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2015,06,30,22,52,00)
    Main\Node_Type\Date_Modification = Date(2015,07,03,23,39,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Calculates and displays hashes of the given data"
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 510
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.40 LTS Beta 1 (Windows - x64)
; CursorPosition = 30
; FirstLine = 78
; Folding = ---
; EnableUnicode
; EnableXP