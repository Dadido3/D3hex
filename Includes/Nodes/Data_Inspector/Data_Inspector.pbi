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
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule _Node_Data_Inspector
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Data_Inspector
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  #Flag_Big_Endian     = %01
  #Flag_Null_Character = %10
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    ListIcon.i
    Editor.i
    Button_Set.i
    CheckBox.i[10]
    
    Update_ListIcon.i
    
    ; #### Math stuff
    
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
    *Node\Color = RGBA(150,100,150,255)
    
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
    
    ;*NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Size", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object\Size)
    
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
    
    ;*NBT_Tag = NBT_Tag(*Parent_Tag, "Size") : *Object\Size = NBT_Tag_Get_Number(*NBT_Tag)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.s Data_2_String(*Node.Node::Object, Type.i, Flags.i)
    Protected Size.q
    Protected String.s
    Protected i.i
    Protected Ascii_Metadata.a
    Protected Ascii_Data.a
    Protected Other_Data.q
    Protected *Temp_Data, *Temp_Metadata
    
    If Not *Node
      ProcedureReturn ""
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn ""
    EndIf
    
    Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
    
    If Size <= 0
      ProcedureReturn ""
    EndIf
    
    Select Type
      Case #Data_Raw
        ; #### Limit Size
        If Size > 1000
          Size = 1000
        EndIf
        For i = 0 To Size-1
          If Node::Input_Get_Data(FirstElement(*Node\Input()), i, 1, @Ascii_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              String + RSet(Bin(Ascii_Data, #PB_Ascii), 8, "0") + " "
            Else
              String + "???????? "
            EndIf
          Else
            String + "XXXXXXXX "
          EndIf
        Next
        
      Case #Integer_U_8; = #PB_Ascii
        If Size >= 1
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 1, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              ProcedureReturn StrU(PeekA(@Other_Data), #PB_Ascii)
            EndIf
          EndIf
        EndIf
        
      Case #Integer_S_8; = #PB_Byte
        If Size >= 1
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 1, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              ProcedureReturn Str(PeekB(@Other_Data))
            EndIf
          EndIf
        EndIf
        
      Case #Integer_U_16; = #PB_Unicode
        If Size >= 2
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 2, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 2)
              EndIf
              ProcedureReturn StrU(PeekU(@Other_Data), #PB_Unicode)
            EndIf
          EndIf
        EndIf
        
      Case #Integer_S_16; = #PB_Word
        If Size >= 2
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 2, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 2)
              EndIf
              ProcedureReturn Str(PeekW(@Other_Data))
            EndIf
          EndIf
        EndIf
        
      Case #Integer_U_32; = #PB_Long (Unsigned)
        If Size >= 4
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 4)
              EndIf
              ProcedureReturn StrU(PeekL(@Other_Data), #PB_Long)
            EndIf
          EndIf
        EndIf
        
      Case #Integer_S_32; = #PB_Long
        If Size >= 4
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 4)
              EndIf
              ProcedureReturn Str(PeekL(@Other_Data))
            EndIf
          EndIf
        EndIf
        
      Case #Integer_U_64; = #PB_Quad (Unsigned)
        If Size >= 8
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 8)
              EndIf
              ProcedureReturn StrU(PeekQ(@Other_Data), #PB_Quad)
            EndIf
          EndIf
        EndIf
        
      Case #Integer_S_64; = #PB_Quad
        If Size >= 8
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 8)
              EndIf
              ProcedureReturn Str(PeekQ(@Other_Data))
            EndIf
          EndIf
        EndIf
        
      Case #Float_32    ; = #PB_Float
        If Size >= 4
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 4)
              EndIf
              ProcedureReturn RTrim(RTrim(StrF(PeekF(@Other_Data), 50), "0"), ".")
            EndIf
          EndIf
        EndIf
        
      Case #Float_64    ; = #PB_Double
        If Size >= 8
          If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
            If Ascii_Metadata & #Metadata_Readable
              If Flags & #Flag_Big_Endian
                Memory::Mirror(@Other_Data, 8)
              EndIf
              ProcedureReturn RTrim(RTrim(StrD(PeekD(@Other_Data), 350), "0"), ".")
            EndIf
          EndIf
        EndIf
        
      Case #String_Ascii
        ; #### Limit Size
        If Size > 10000000
          Size = 10000000
        EndIf
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn ""
        EndIf
        *Temp_Metadata = AllocateMemory(Size+2)
        If Not *Temp_Metadata
          FreeMemory(*Temp_Data)
          ProcedureReturn ""
        EndIf
        
        If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
          String = PeekS(*Temp_Data, Size, #PB_Ascii)
        EndIf
        
        FreeMemory(*Temp_Data)
        FreeMemory(*Temp_Metadata)
        
      Case #String_UTF8
        ; #### Limit Size
        If Size > 10000000
          Size = 10000000
        EndIf
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn ""
        EndIf
        *Temp_Metadata = AllocateMemory(Size+2)
        If Not *Temp_Metadata
          FreeMemory(*Temp_Data)
          ProcedureReturn ""
        EndIf
        
        If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
          String = PeekS(*Temp_Data, Size, #PB_UTF8)
        EndIf
        
        FreeMemory(*Temp_Data)
        FreeMemory(*Temp_Metadata)
        
      Case #String_UTF16
        ; #### Limit Size
        If Size > 10000000
          Size = 10000000
        EndIf
        ; #### Only allow even sizes
        Size & ~1
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn ""
        EndIf
        *Temp_Metadata = AllocateMemory(Size+2)
        If Not *Temp_Metadata
          FreeMemory(*Temp_Data)
          ProcedureReturn ""
        EndIf
        
        If Node::Input_Get_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
          If Flags & #Flag_Big_Endian
            For i = 0 To Size/2-1
              Memory::Mirror(*Temp_Data+i*2, 2)
            Next
          EndIf
          String = PeekS(*Temp_Data, Size, #PB_Unicode)
        EndIf
        
        FreeMemory(*Temp_Data)
        FreeMemory(*Temp_Metadata)
        
      ;Case #String_UTF32
      ;Case #String_UCS2
      ;Case #String_UCS4
      
    EndSelect
    
    ProcedureReturn String
  EndProcedure
  
  Procedure String_2_Data(*Node.Node::Object, Type.i, String.s, Flags.i)
    Protected Size.q
    Protected Part_String.s
    Protected Result.i
    Protected i.i
    Protected Ascii_Metadata.a
    Protected Ascii_Data.a
    Protected Other_Data.q
    Protected *Temp_Data, *Temp_Metadata
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Select Type
      Case #Data_Raw
        String = ReplaceString(String, " ", "")
        For i = 0 To (Len(String)/8)-1
          Part_String = Mid(String, i*8 + 1, 8)
          PokeA(@Ascii_Data, Val("%"+Part_String))
          Node::Input_Set_Data(FirstElement(*Node\Input()), i, 1, @Ascii_Data)
        Next
        ProcedureReturn #True
        
      Case #Integer_U_8; = #PB_Ascii
        PokeA(@Other_Data, Val(String))
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 1, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_S_8; = #PB_Byte
        PokeB(@Other_Data, Val(String))
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 1, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_U_16; = #PB_Unicode
        PokeU(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 2)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 2, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_S_16; = #PB_Word
        PokeW(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 2)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 2, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_U_32; = #PB_Long (Unsigned)
        PokeL(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 2)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_S_32; = #PB_Long
        PokeL(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 4)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_U_64; = #PB_Quad (Unsigned)
        PokeQ(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 8)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Integer_S_64; = #PB_Quad
        PokeQ(@Other_Data, Val(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 8)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Float_32    ; = #PB_Float
        PokeF(@Other_Data, ValF(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 4)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 4, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #Float_64    ; = #PB_Double
        PokeD(@Other_Data, ValD(String))
        If Flags & #Flag_Big_Endian
          Memory::Mirror(@Other_Data, 8)
        EndIf
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, 8, @Other_Data)
          ProcedureReturn #True
        EndIf
        
      Case #String_Ascii
        Size = StringByteLength(String, #PB_Ascii)
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn #False
        EndIf
        
        PokeS(*Temp_Data, String, Size, #PB_Ascii)
        
        If Flags & #Flag_Null_Character
          Size + 1
        EndIf
        
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data)
          Result = #True
        EndIf
        
        FreeMemory(*Temp_Data)
        
      Case #String_UTF8
        Size = StringByteLength(String, #PB_UTF8)
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn #False
        EndIf
        
        PokeS(*Temp_Data, String, Size, #PB_UTF8)
        
        If Flags & #Flag_Null_Character
          Size + 1
        EndIf
        
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data)
          Result = #True
        EndIf
        
        FreeMemory(*Temp_Data)
        
      Case #String_UTF16
        Size = StringByteLength(String, #PB_Unicode)
        *Temp_Data = AllocateMemory(Size+2)
        If Not *Temp_Data
          ProcedureReturn #False
        EndIf
        
        PokeS(*Temp_Data, String, Size, #PB_Unicode)
        
        If Flags & #Flag_Big_Endian
          For i = 0 To Size/2-1
            Memory::Mirror(*Temp_Data+i*2, 2)
          Next
        EndIf
        
        If Flags & #Flag_Null_Character
          Size + 2
        EndIf
        
        If Node::Input_Set_Data(FirstElement(*Node\Input()), 0, Size, *Temp_Data)
          Result = #True
        EndIf
        
        FreeMemory(*Temp_Data)
        
      ;Case #String_UTF32
      ;Case #String_UCS2
      ;Case #String_UCS4
      
    EndSelect
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure Update_ListIcon(*Node.Node::Object)
    Protected i.i
    Protected Type.i
    Protected String.s
    Protected Flags.i
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ;ClearGadgetItems(*Object\ListIcon)
    
    For i = 0 To CountGadgetItems(*Object\ListIcon)-1
      Type = GetGadgetItemData(*Object\ListIcon, i)
      If GetGadgetState(*Object\CheckBox[0])
        Flags | #Flag_Big_Endian
      EndIf
      If GetGadgetState(*Object\CheckBox[1])
        Flags | #Flag_Null_Character
      EndIf
      String = Data_2_String(*Node, Type, Flags)
      
      SetGadgetItemText(*Object\ListIcon, i, String, 1)
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
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Event_ListIcon()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected String.s
    
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
    
    If GetGadgetState(Event_Gadget) >= 0
      String = GetGadgetItemText(Event_Gadget, GetGadgetState(Event_Gadget), 1)
      SetGadgetText(*Object\Editor, String)
      DisableGadget(*Object\Editor, #False)
      DisableGadget(*Object\Button_Set, #False)
    Else
      SetGadgetText(*Object\Editor, "")
      DisableGadget(*Object\Editor, #True)
      DisableGadget(*Object\Button_Set, #True)
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_Button_Set()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected Type.i
    Protected Flags.i
    
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
    
    If GetGadgetState(*Object\ListIcon) >= 0
      Type = GetGadgetItemData(*Object\ListIcon, GetGadgetState(*Object\ListIcon))
      If GetGadgetState(*Object\CheckBox[0])
        Flags | #Flag_Big_Endian
      EndIf
      If GetGadgetState(*Object\CheckBox[1])
        Flags | #Flag_Null_Character
      EndIf
      String_2_Data(*Node, Type, GetGadgetText(*Object\Editor), Flags)
    EndIf
    
  EndProcedure
  
  Procedure Window_Event_CheckBox()
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
    
    *Object\Update_ListIcon = #True
    
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
    
    ResizeGadget(*Object\ListIcon, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window), 320)
    ResizeGadget(*Object\Editor, #PB_Ignore, 330, WindowWidth(Event_Window), WindowHeight(Event_Window)-370)
    ResizeGadget(*Object\Button_Set, WindowWidth(Event_Window)-100, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
    
    ResizeGadget(*Object\CheckBox[0], #PB_Ignore, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
    ResizeGadget(*Object\CheckBox[1], #PB_Ignore, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
    
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
    Select Event_Menu
      
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
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Window
      
      Width = 300
      Height = 430
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height, Window::#Flag_Resizeable)
      
      ; #### Gadgets
      
      *Object\ListIcon = ListIconGadget(#PB_Any, 0, 0, Width, 320, "Type", 50, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
      AddGadgetColumn(*Object\ListIcon, 1, "Value", 500)
      
      ; #### Add ListIcon items
      AddGadgetItem(*Object\ListIcon,  0, "Binary")   : SetGadgetItemData(*Object\ListIcon,  0, #Data_Raw)
      AddGadgetItem(*Object\ListIcon,  1, "uint8")    : SetGadgetItemData(*Object\ListIcon,  1, #Integer_U_8)
      AddGadgetItem(*Object\ListIcon,  2, "int8")     : SetGadgetItemData(*Object\ListIcon,  2, #Integer_S_8)
      AddGadgetItem(*Object\ListIcon,  3, "uint16")   : SetGadgetItemData(*Object\ListIcon,  3, #Integer_U_16)
      AddGadgetItem(*Object\ListIcon,  4, "int16")    : SetGadgetItemData(*Object\ListIcon,  4, #Integer_S_16)
      AddGadgetItem(*Object\ListIcon,  5, "uint32")   : SetGadgetItemData(*Object\ListIcon,  5, #Integer_U_32)
      AddGadgetItem(*Object\ListIcon,  6, "int32")    : SetGadgetItemData(*Object\ListIcon,  6, #Integer_S_32)
      AddGadgetItem(*Object\ListIcon,  7, "uint64")   : SetGadgetItemData(*Object\ListIcon,  7, #Integer_U_64)
      AddGadgetItem(*Object\ListIcon,  8, "int64")    : SetGadgetItemData(*Object\ListIcon,  8, #Integer_S_64)
      AddGadgetItem(*Object\ListIcon,  9, "float32")  : SetGadgetItemData(*Object\ListIcon,  9, #Float_32)
      AddGadgetItem(*Object\ListIcon, 10, "float64")  : SetGadgetItemData(*Object\ListIcon, 10, #Float_64)
      AddGadgetItem(*Object\ListIcon, 11, "Ascii")    : SetGadgetItemData(*Object\ListIcon, 11, #String_Ascii)
      AddGadgetItem(*Object\ListIcon, 12, "UTF8")     : SetGadgetItemData(*Object\ListIcon, 12, #String_UTF8)
      AddGadgetItem(*Object\ListIcon, 13, "UTF16")    : SetGadgetItemData(*Object\ListIcon, 13, #String_UTF16)
      ;AddGadgetItem(*Object\ListIcon, 14, "UTF32")    : SetGadgetItemData(*Object\ListIcon, 14, #String_UTF32)
      ;AddGadgetItem(*Object\ListIcon, 15, "UCS2")     : SetGadgetItemData(*Object\ListIcon, 15, #String_UCS2)
      ;AddGadgetItem(*Object\ListIcon, 16, "UCS4")     : SetGadgetItemData(*Object\ListIcon, 16, #String_UCS4)
      
      *Object\Editor = EditorGadget(#PB_Any, 0, 330, Width, Height-370)
      
      *Object\Button_Set = ButtonGadget(#PB_Any, Width-100, Height-30, 90, 20, "Write")
      
      *Object\CheckBox[0] = CheckBoxGadget(#PB_Any, 10, Height-30, 70, 20, "Big Endian")
      *Object\CheckBox[1] = CheckBoxGadget(#PB_Any, 90, Height-30, 90, 20, "Null-Character")
      
      DisableGadget(*Object\Editor, #True)
      DisableGadget(*Object\Button_Set, #True)
      
      BindGadgetEvent(*Object\ListIcon, @Window_Event_ListIcon())
      BindGadgetEvent(*Object\Button_Set, @Window_Event_Button_Set())
      BindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      Window::Bounds(*Object\Window, 300, 430, #PB_Default, #PB_Default)
      
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
      UnbindGadgetEvent(*Object\Button_Set, @Window_Event_Button_Set())
      UnbindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      Window::Delete(*Object\Window)
      *Object\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Main(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
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
    Main\Node_Type\Category = "Manipulator"
    Main\Node_Type\Name = "Data Inspector"
    Main\Node_Type\UID = "D3_DATAI"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,08,08,19,56,00)
    Main\Node_Type\Date_Modification = Date(2014,08,09,19,24,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Displays data interpreted as different datatypes"
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 900
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 860
; FirstLine = 838
; Folding = ---
; EnableUnicode
; EnableXP