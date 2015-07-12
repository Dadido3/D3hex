; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2015  David Vogel
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
; TODO: Refactor this node. Make a list of hash-functions instead of hardcoding everything.
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
    #Hash_State_Calculate
    #Hash_State_Done
  EndEnumeration
  
  #Chunk_Size = 1024*100
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Hash_Temp_Value
    Position.q
    
    StructureUnion
      CRC32.l
    EndStructureUnion
  EndStructure
  
  Structure Hash
    Item_State.i
    State.i
    
    Result.s
    
    Fingerprint_ID.i      ; From Examine...Fingerprint()
    List Temp_Value.Hash_Temp_Value()
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
    
    Calculate.i
    Size.q
    
    Hash_CRC32.Hash
    Hash_MD5.Hash
    Hash_SHA1.Hash
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
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "CRC32_Activated", NBT::#Tag_Byte) : NBT::Tag_Set_Number(*NBT_Tag, *Object\Hash_CRC32\Item_State)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "MD5_Activated", NBT::#Tag_Byte)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Hash_MD5\Item_State)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "SHA1_Activated", NBT::#Tag_Byte)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Hash_SHA1\Item_State)
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "CRC32_Activated") : *Object\Hash_CRC32\Item_State = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "MD5_Activated")   : *Object\Hash_MD5\Item_State   = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "SHA1_Activated")  : *Object\Hash_SHA1\Item_State  = NBT::Tag_Get_Number(*NBT_Tag)
    
    If *Object\Automatic
      *Object\Calculate = #True
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
    
    If LastElement(*Object\Hash_CRC32\Temp_Value())
      If *Object\Hash_CRC32\Temp_Value()\Position = *Object\Size
        SetGadgetItemText(*Object\ListIcon, 0, *Object\Hash_CRC32\Result, 1)
      Else
        SetGadgetItemText(*Object\ListIcon, 0, "Calculating "+StrF(*Object\Hash_CRC32\Temp_Value()\Position / *Object\Size * 100,2)+"%", 1)
      EndIf
    Else
      SetGadgetItemText(*Object\ListIcon, 0, "", 1)
    EndIf
    If LastElement(*Object\Hash_MD5\Temp_Value())
      If *Object\Hash_MD5\Temp_Value()\Position = *Object\Size
        SetGadgetItemText(*Object\ListIcon, 1, *Object\Hash_MD5\Result, 1)
      Else
        SetGadgetItemText(*Object\ListIcon, 1, "Calculating "+StrF(*Object\Hash_MD5\Temp_Value()\Position / *Object\Size * 100,2)+"%", 1)
      EndIf
    Else
      SetGadgetItemText(*Object\ListIcon, 1, "", 1)
    EndIf
    If LastElement(*Object\Hash_SHA1\Temp_Value())
      If *Object\Hash_SHA1\Temp_Value()\Position = *Object\Size
        SetGadgetItemText(*Object\ListIcon, 2, *Object\Hash_SHA1\Result, 1)
      Else
        SetGadgetItemText(*Object\ListIcon, 2, "Calculating "+StrF(*Object\Hash_SHA1\Temp_Value()\Position / *Object\Size * 100,2)+"%", 1)
      EndIf
    Else
      SetGadgetItemText(*Object\ListIcon, 2, "", 1)
    EndIf
    
    ; #### Update checkboxes
    SetGadgetItemState(*Object\ListIcon, 0, *Object\Hash_CRC32\Item_State)
    SetGadgetItemState(*Object\ListIcon, 1, *Object\Hash_MD5\Item_State)
    SetGadgetItemState(*Object\ListIcon, 2, *Object\Hash_SHA1\Item_State)
    
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
        If *Object\Automatic
          *Object\Calculate = #True
        Else
          *Object\Calculate = #False
        EndIf
        *Object\Update_ListIcon = #True
      
        ; #### Delete precalculated values
        *Object\Hash_CRC32\State = #Hash_State_Calculate
        ForEach *Object\Hash_CRC32\Temp_Value()
          If *Object\Hash_CRC32\Temp_Value()\Position > *Event\Position
            DeleteElement(*Object\Hash_CRC32\Temp_Value())
          EndIf
        Next
        
        ClearList(*Object\Hash_MD5\Temp_Value())
        
        ClearList(*Object\Hash_SHA1\Temp_Value())
        
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
    
    *Object\Hash_CRC32\Item_State = GetGadgetItemState(Event_Gadget, 0)
    *Object\Hash_MD5\Item_State = GetGadgetItemState(Event_Gadget, 1)
    *Object\Hash_SHA1\Item_State = GetGadgetItemState(Event_Gadget, 2)
    
    If *Object\Automatic
      *Object\Calculate = #True
    EndIf
    
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
        *Object\Calculate = #True
        
      Case #Menu_Refresh
        *Object\Calculate = #True
        ; #### Delete precalculated values
        ClearList(*Object\Hash_CRC32\Temp_Value())
        ClearList(*Object\Hash_MD5\Temp_Value())
        ClearList(*Object\Hash_SHA1\Temp_Value())
        
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
      AddGadgetItem(*Object\ListIcon,  0, "CRC32")
      AddGadgetItem(*Object\ListIcon,  1, "MD5")
      AddGadgetItem(*Object\ListIcon,  2, "SHA1")
      
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
  
  Procedure Calculate(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Position.q
    Protected Data_Size.i, *Data
    Protected Start_Time.q = ElapsedMilliseconds()
    
    *Object\Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
    
    If *Object\Size < 0
      ProcedureReturn #False
    EndIf
    
    ; #### Initialize the hash function if it doesn't have precalculated values
    If Not LastElement(*Object\Hash_CRC32\Temp_Value()) And *Object\Hash_CRC32\Item_State & #PB_ListIcon_Checked
      *Object\Hash_CRC32\State = #Hash_State_Calculate
      AddElement(*Object\Hash_CRC32\Temp_Value())
    EndIf
    If Not LastElement(*Object\Hash_MD5\Temp_Value()) And *Object\Hash_MD5\Item_State & #PB_ListIcon_Checked
      If *Object\Hash_MD5\Fingerprint_ID : FinishFingerprint(*Object\Hash_MD5\Fingerprint_ID) : EndIf
      *Object\Hash_MD5\Fingerprint_ID = ExamineMD5Fingerprint(#PB_Any)
      *Object\Hash_MD5\State = #Hash_State_Calculate
      AddElement(*Object\Hash_MD5\Temp_Value())
    EndIf
    If Not LastElement(*Object\Hash_SHA1\Temp_Value()) And *Object\Hash_SHA1\Item_State & #PB_ListIcon_Checked
      If *Object\Hash_SHA1\Fingerprint_ID : FinishFingerprint(*Object\Hash_SHA1\Fingerprint_ID) : EndIf
      *Object\Hash_SHA1\Fingerprint_ID = ExamineSHA1Fingerprint(#PB_Any)
      *Object\Hash_SHA1\State = #Hash_State_Calculate
      AddElement(*Object\Hash_SHA1\Temp_Value())
    EndIf
    
    Repeat
      
      *Object\Calculate = #False
      
      ; #### Get the lowest position of all hash functions
      Position = 9223372036854775807
      If *Object\Hash_CRC32\Item_State & #PB_ListIcon_Checked
        If Position > *Object\Hash_CRC32\Temp_Value()\Position
          Position = *Object\Hash_CRC32\Temp_Value()\Position
        EndIf
      EndIf
      If *Object\Hash_MD5\Item_State & #PB_ListIcon_Checked
        If Position > *Object\Hash_MD5\Temp_Value()\Position
          Position = *Object\Hash_MD5\Temp_Value()\Position
        EndIf
      EndIf
      If *Object\Hash_SHA1\Item_State & #PB_ListIcon_Checked
        If Position > *Object\Hash_SHA1\Temp_Value()\Position
          Position = *Object\Hash_SHA1\Temp_Value()\Position
        EndIf
      EndIf
      
      ; #### Get the data
      If Position < *Object\Size
        Data_Size = *Object\Size - Position
        If Data_Size > #Chunk_Size
          Data_Size = #Chunk_Size
        EndIf
        *Data = AllocateMemory(Data_Size)
        If Node::Input_Get_Data(FirstElement(*Node\Input()), Position, Data_Size, *Data, #Null)
          
          ; #### Calculate the hash
          If *Object\Hash_CRC32\Item_State & #PB_ListIcon_Checked And *Object\Hash_CRC32\Temp_Value()\Position = Position
            *Object\Hash_CRC32\Temp_Value()\CRC32 = CRC32Fingerprint(*Data, Data_Size, *Object\Hash_CRC32\Temp_Value()\CRC32)
            *Object\Hash_CRC32\Temp_Value()\Position + Data_Size
            *Object\Calculate = #True
          EndIf
          If *Object\Hash_MD5\Item_State & #PB_ListIcon_Checked And *Object\Hash_MD5\Temp_Value()\Position = Position And *Object\Hash_MD5\Fingerprint_ID
            NextFingerprint(*Object\Hash_MD5\Fingerprint_ID, *Data, Data_Size)
            *Object\Hash_MD5\Temp_Value()\Position + Data_Size
            *Object\Calculate = #True
          EndIf
          If *Object\Hash_SHA1\Item_State & #PB_ListIcon_Checked And *Object\Hash_SHA1\Temp_Value()\Position = Position And *Object\Hash_SHA1\Fingerprint_ID
            NextFingerprint(*Object\Hash_SHA1\Fingerprint_ID, *Data, Data_Size)
            *Object\Hash_SHA1\Temp_Value()\Position + Data_Size
            *Object\Calculate = #True
          EndIf
          
        EndIf
        
        FreeMemory(*Data) : *Data = #Null
      Else
        
        ; #### finish the hash
        If *Object\Hash_CRC32\Item_State & #PB_ListIcon_Checked And *Object\Hash_CRC32\State = #Hash_State_Calculate
          *Object\Hash_CRC32\State = #Hash_State_Done
          *Object\Hash_CRC32\Result = RSet(Hex(*Object\Hash_CRC32\Temp_Value()\CRC32, #PB_Long), 8, "0")
        EndIf
        If *Object\Hash_MD5\Item_State & #PB_ListIcon_Checked And *Object\Hash_MD5\State = #Hash_State_Calculate And *Object\Hash_MD5\Fingerprint_ID
          *Object\Hash_MD5\State = #Hash_State_Done
          *Object\Hash_MD5\Result = UCase(FinishFingerprint(*Object\Hash_MD5\Fingerprint_ID)) : *Object\Hash_MD5\Fingerprint_ID = 0
        EndIf
        If *Object\Hash_SHA1\Item_State & #PB_ListIcon_Checked And *Object\Hash_SHA1\State = #Hash_State_Calculate And *Object\Hash_SHA1\Fingerprint_ID
          *Object\Hash_SHA1\State = #Hash_State_Done
          *Object\Hash_SHA1\Result = UCase(FinishFingerprint(*Object\Hash_SHA1\Fingerprint_ID)) : *Object\Hash_SHA1\Fingerprint_ID = 0
        EndIf
        
      EndIf
      
    Until *Object\Calculate = #False Or Start_Time + 15 < ElapsedMilliseconds()
    
  EndProcedure
  
  Procedure Main(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Calculate
      *Object\Update_ListIcon = #True
      Calculate(*Node)
    EndIf
    
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

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 363
; FirstLine = 358
; Folding = ---
; EnableUnicode
; EnableXP