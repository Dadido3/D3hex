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

DeclareModule _Node_Copy
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Copy
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  #Chunk_Size = 1024*1024*10
  
  Enumeration
    #State_Off
    #State_A_2_B
    #State_B_2_A
  EndEnumeration
  
  Enumeration
    #Mode_Overwrite
    #Mode_Insert
    
    #Modes       ; The number of different modes
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    Button.i[10]
    Frame.i[10]
    Option.i[10]
    CheckBox.i[10]
    ProgressBar.i
    Text.i
    
    ; #### Settings
    
    Mode.i
    
    Append.i
    Truncate.i
    
    ; #### State
    
    State.i
    
    Position_Read.q
    Position_Write.q
    
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
  
  Declare   Set_State(*Node.Node::Object, State.i)
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input_A.Node::Conn_Input
    Protected *Input_B.Node::Conn_Input
    
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
    *Node\Color = RGBA(230,180,250,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### Add Input
    *Input_A = Node::Input_Add(*Node, "A", "A")
    *Input_A\Function_Event = @Input_Event()
    
    ; #### Add Input
    *Input_B = Node::Input_Add(*Node, "B", "B")
    *Input_B\Function_Event = @Input_Event()
    
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
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Mode", NBT::#Tag_Quad)      : NBT::Tag_Set_Number(*NBT_Tag, *Object\Mode)
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Append", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\Append)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Truncate", NBT::#Tag_Quad)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Truncate)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Mode")     : *Object\Mode     = NBT::Tag_Get_Number(*NBT_Tag)
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Append")   : *Object\Append   = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Truncate") : *Object\Truncate = NBT::Tag_Get_Number(*NBT_Tag)
    
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
    
    Select *Event\Type
      Case Node::#Link_Event_Update, Node::#Link_Event_Goto
        
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Event_Button()
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
    
    Select Event_Gadget
      Case *Object\Button[0]
        Set_State(*Node.Node::Object, #State_B_2_A)
        
      Case *Object\Button[1]
        Set_State(*Node.Node::Object, #State_A_2_B)
        
      Case *Object\Button[2]
        Set_State(*Node.Node::Object, #State_Off)
        
    EndSelect
    
  EndProcedure
  
  Procedure Window_Event_Option()
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
    
    Select Event_Gadget
      Case *Object\Option[0]
        *Object\Mode = #Mode_Overwrite
        
      Case *Object\Option[1]
        *Object\Mode = #Mode_Insert
        
    EndSelect
    
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
    
    Select Event_Gadget
      Case *Object\CheckBox[0]
        *Object\Append = GetGadgetState(Event_Gadget)
        
      Case *Object\CheckBox[1]
        *Object\Truncate = GetGadgetState(Event_Gadget)
        
    EndSelect
    
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
      
      Width = 210
      Height = 190
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Gadgets
      
      *Object\Button[0] = ButtonGadget(#PB_Any, 10, 10, 60, 40, "A <-- B")
      *Object\Button[1] = ButtonGadget(#PB_Any, 10, 90, 60, 40, "B <-- A")
      *Object\Button[2] = ButtonGadget(#PB_Any, 10, 50, 60, 40, "Stop")
      
      *Object\Frame[0] = FrameGadget(#PB_Any, 80, 10, 120, 120, "Settings")
      *Object\Option[0] = OptionGadget(#PB_Any, 90, 30, 100, 20, "Overwrite")
      *Object\Option[1] = OptionGadget(#PB_Any, 90, 50, 100, 20, "Insert")
      *Object\CheckBox[0] = CheckBoxGadget(#PB_Any, 90, 80, 100, 20, "Append")
      *Object\CheckBox[1] = CheckBoxGadget(#PB_Any, 90, 100, 100, 20, "Truncate")
      
      *Object\ProgressBar = ProgressBarGadget(#PB_Any, 10, 140, Width-20, 20, 0, 1000, #PB_ProgressBar_Smooth)
      *Object\Text = TextGadget(#PB_Any, 10, 160, Width-20, 20, "")
      
      ; #### Initialise states
      SetGadgetState(*Object\CheckBox[0], *Object\Append)
      SetGadgetState(*Object\CheckBox[1], *Object\Truncate)
      
      Select *Object\Mode
        Case #Mode_Overwrite  : SetGadgetState(*Object\Option[0], #True)
        Case #Mode_Insert     : SetGadgetState(*Object\Option[1], #True)
      EndSelect
      
      BindGadgetEvent(*Object\Button[0], @Window_Event_Button())
      BindGadgetEvent(*Object\Button[1], @Window_Event_Button())
      BindGadgetEvent(*Object\Button[2], @Window_Event_Button())
      BindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      BindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      BindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      BindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
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
      
      UnbindGadgetEvent(*Object\Button[0], @Window_Event_Button())
      UnbindGadgetEvent(*Object\Button[1], @Window_Event_Button())
      UnbindGadgetEvent(*Object\Button[2], @Window_Event_Button())
      UnbindGadgetEvent(*Object\Option[0], @Window_Event_Option())
      UnbindGadgetEvent(*Object\Option[1], @Window_Event_Option())
      UnbindGadgetEvent(*Object\CheckBox[0], @Window_Event_CheckBox())
      UnbindGadgetEvent(*Object\CheckBox[1], @Window_Event_CheckBox())
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
      Window::Delete(*Object\Window)
      *Object\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Set_State(*Node.Node::Object, State.i)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\State = State
    
    Select State
      Case #State_Off
        DisableGadget(*Object\Button[0],   #False)
        DisableGadget(*Object\Button[1],   #False)
        DisableGadget(*Object\CheckBox[0], #False)
        DisableGadget(*Object\CheckBox[1], #False)
        DisableGadget(*Object\Option[0],   #False)
        DisableGadget(*Object\Option[1],   #False)
        SetGadgetState(*Object\ProgressBar, 0)
        SetGadgetText(*Object\Text, "")
        
      Case #State_B_2_A
        *Object\Position_Read = 0
        If *Object\Append
          *Object\Position_Write = Node::Input_Get_Size(FirstElement(*Node\Input()))
        Else
          *Object\Position_Write = 0
        EndIf
        
        DisableGadget(*Object\Button[0],   #True)
        DisableGadget(*Object\Button[1],   #True)
        DisableGadget(*Object\CheckBox[0], #True)
        DisableGadget(*Object\CheckBox[1], #True)
        DisableGadget(*Object\Option[0],   #True)
        DisableGadget(*Object\Option[1],   #True)
        SetGadgetState(*Object\ProgressBar, 0)
        SetGadgetText(*Object\Text, "")
        
      Case #State_A_2_B
        *Object\Position_Read = 0
        If *Object\Append
          *Object\Position_Write = Node::Input_Get_Size(LastElement(*Node\Input()))
        Else
          *Object\Position_Write = 0
        EndIf
        
        DisableGadget(*Object\Button[0],   #True)
        DisableGadget(*Object\Button[1],   #True)
        DisableGadget(*Object\CheckBox[0], #True)
        DisableGadget(*Object\CheckBox[1], #True)
        DisableGadget(*Object\Option[0],   #True)
        DisableGadget(*Object\Option[1],   #True)
        SetGadgetState(*Object\ProgressBar, 0)
        SetGadgetText(*Object\Text, "")
        
    EndSelect
  EndProcedure
  
  Procedure Do(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected *Buffer, Buffer_Size.q
    Protected *Input_In.Node::Conn_Input
    Protected *Input_Out.Node::Conn_Input
    Protected Size_Input.q
    Protected Size_Output.q
    
    Select *Object\State
      Case #State_Off
        
      Case #State_A_2_B, #State_B_2_A
        Select *Object\State
          Case #State_A_2_B
            *Input_In = FirstElement(*Node\Input())
            *Input_Out = LastElement(*Node\Input())
          Case #State_B_2_A
            *Input_In = LastElement(*Node\Input())
            *Input_Out = FirstElement(*Node\Input())
        EndSelect
        
        Size_Input = Node::Input_Get_Size(*Input_In)
        Size_Output = Node::Input_Get_Size(*Input_Out)
        
        If *Object\Position_Read < Size_Input
          Buffer_Size = Size_Input - *Object\Position_Read
          If Buffer_Size > #Chunk_Size
            Buffer_Size = #Chunk_Size
          EndIf
          *Buffer = AllocateMemory(Buffer_Size)
          
          If Node::Input_Get_Data(*Input_In, *Object\Position_Read, Buffer_Size, *Buffer, #Null)
            
            Select *Object\Mode
              Case #Mode_Insert
                If Node::Input_Shift(*Input_Out, *Object\Position_Write, Buffer_Size)
                  If Not Node::Input_Set_Data(*Input_Out, *Object\Position_Write, Buffer_Size, *Buffer)
                    Set_State(*Node.Node::Object, #State_Off)
                  EndIf
                Else
                  *Object\State = #State_Off
                EndIf
                
              Case #Mode_Overwrite
                If Not Node::Input_Set_Data(*Input_Out, *Object\Position_Write, Buffer_Size, *Buffer)
                  Set_State(*Node.Node::Object, #State_Off)
                EndIf
            EndSelect
            
            *Object\Position_Write + Buffer_Size
            *Object\Position_Read + Buffer_Size
          Else
            Set_State(*Node.Node::Object, #State_Off)
          EndIf
          
          FreeMemory(*Buffer)
        Else
          If *Object\Truncate
            If *Object\Position_Write < Size_Output
              Node::Input_Shift(*Input_Out, *Object\Position_Write, *Object\Position_Write - Size_Output)
            EndIf
          EndIf
          
          Set_State(*Node.Node::Object, #State_Off)
        EndIf
        
    EndSelect
  EndProcedure
  
  Procedure ProgressBar_Update(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Size.q, Text.s
    
    Select *Object\State
      Case #State_A_2_B, #State_B_2_A
        
        Select *Object\State
          Case #State_A_2_B
            Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
          Case #State_B_2_A
            Size = Node::Input_Get_Size(LastElement(*Node\Input()))
        EndSelect
        
        Text = UnitEngine::Format_Integer(*Object\Position_Read, UnitEngine::#SiPrefix, "B")+"/"+UnitEngine::Format_Integer(Size, UnitEngine::#SiPrefix, "B")
        
        SetGadgetState(*Object\ProgressBar, *Object\Position_Read*1000/Size)
        SetGadgetText(*Object\Text, Text)
        
    EndSelect
  EndProcedure
  
  Procedure Main(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Do(*Node)
    
    If *Object\Window
      ProgressBar_Update(*Node)
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
    Main\Node_Type\Category = "Structure"
    Main\Node_Type\Name = "Copy"
    Main\Node_Type\UID = "D3__COPY"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,08,13,23,30,00)
    Main\Node_Type\Date_Modification = Date(2014,08,15,16,58,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Copies data from one input to another input."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 900
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 339
; FirstLine = 335
; Folding = ---
; EnableUnicode
; EnableXP