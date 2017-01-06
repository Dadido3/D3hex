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
; Can handle up to $7FFFFFFFFFFFFFFF bytes of data
; 
; 
; 
; 
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule _Node_Editor
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Editor
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Macros ######################################################
  
  Procedure InRange(Position_A.q, Position_B.q, Position.q)
    If Position >= Position_A And Position < Position_B
      ProcedureReturn #True
    ElseIf Position >= Position_B And Position < Position_A
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Menu_Save
    #Menu_SaveAs
    
    #Menu_Search
    #Menu_Search_Continue
    #Menu_Goto
    
    #Menu_Cut
    #Menu_Copy
    #Menu_Paste
    
    #Menu_Undo
    #Menu_Redo
    
    ; ----------------------------
    
    #PopupMenu_Cut
    #PopupMenu_Copy
    #PopupMenu_Paste
    
    #PopupMenu_Select_All
  EndEnumeration
  
  Enumeration
    #WriteMode_Overwrite
    #WriteMode_Insert
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
    
    Font_ID.i
    Font_Width.l
    Font_Height.l
    
    PopUpMenu.i
  EndStructure
  Global Main.Main
  
  Structure Segment
    Line_Start.q            ; Line where the segment starts
    Line_Amount.q           ; Amount of lines, including the range-description line
    
    Start.q
    Size.q
    
    Metadata.a
    Name.s
    
    Collapsed.l             ; True if the element should be hidden.
    
    *Raw_Data               ; Temp_Data, to be updated in Organize()
    *Raw_Metadata           ; Temp_Metadata, to be updated in Organize()
    Raw_Data_Size.q         ; Size of the Data
    Raw_Data_Start.q        ; Where the data starts. (Absolute in bytes)
    Raw_Data_Line_Start.q   ; Line where the data starts. (Absolute in lines)
    Raw_Data_Byte_Start.l   ; X-Position (Byte) where the data starts.
    
    Temp_New.l              ; The segment is new
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Editor-Gadget stuff
    ToolBar.i
    Canvas.i
    ScrollBar.i
    Redraw.l
    X0.l                    ; X-Offset of the data stuff
    X1.l                    ; X-Offset of the ascii stuff
    X2.l                    ; X-Offset of the end of the ascii stuff
    Y0.l                    ; Y-Offset of ascii/data stuff
    List Segment.Segment()
    
    Data_Size.q
    
    Scroll_Line.q           ; Offset of the top line
    Scroll_Lines.q          ; Number of scrollable lines
    Scroll_Divider.q        ; Divider for the scrollbar, because it can only handle 2^32 lines
    Lines.q                 ; Visible lines in the Editor-Window
    Adress_Length.l         ; Length of the adress in chars
    
    Line_Bytes.l            ; Amount of Bytes per Line
    
    *Menu_Object            ; Object the menu is displayed for
    
    ; #### Selection
    Select_Field.l          ; Whether it is the Hex-field (0) or the Ascii-field (1)
    Select_Start.q
    Select_End.q
    Select_Active.l
    Select_Nibble.l         ; If the next nibble of the byte is selected.
    
    Temp_Nibble.i           ; True if "Temp_Nibble_Value" contains a value
    Temp_Nibble_Value.a     ; The first nibble of each byte while writing goes here.
    
    Write_Mode.l
    
    ; #### Other Windows
    *Window_Goto.Goto
    *Window_Search.Search
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Fonts #######################################################
  
  Main\Font_ID = LoadFont(#PB_Any, "Courier New", 10)
  Define Temp_Image = CreateImage(#PB_Any, 1, 1)
  If StartDrawing(ImageOutput(Temp_Image))
    DrawingFont(FontID(Main\Font_ID))
    Main\Font_Width = TextWidth("0")
    Main\Font_Height = TextHeight("0")
    StopDrawing()
  EndIf
  FreeImage(Temp_Image)
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Event(*Node.Node::Object, *Event.Node::Event)
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
  Declare   Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
  Declare   Output_Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Output_Get_Size(*Output.Node::Conn_Output)
  Declare   Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  Declare   Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
  Declare   Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  Declare   Cut(*Node.Node::Object)
  Declare   Copy(*Node.Node::Object)
  Declare   Paste(*Node.Node::Object)
  
  Declare   Remove_Data(*Node.Node::Object, Bytes.q, Backspace=#False)
  Declare   Write_Data(*Node.Node::Object, *Data, Size.i)
  Declare   Write_Nibble(*Node.Node::Object, Char.a, Abort.i=#False)
  
  Declare   Scroll_2_Cursor(*Node.Node::Object)
  Declare   Range_Set(*Node.Node::Object, Select_Start.q, Select_End.q, Select_Nibble.i, Scroll_2_Cursor=#False, Redraw=#True)
  
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Includes ####################################################
  
  XIncludeFile "Editor_Goto.pbi"
  XIncludeFile "Editor_Search.pbi"
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Output.Node::Conn_Output
    Protected *Input.Node::Conn_Input
    
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    *Node\Type = Main\Node_Type
    *Node\Type_Base = Main\Node_Type
    
    *Node\Function_Delete = @_Delete()
    *Node\Function_Main = @Main()
    *Node\Function_Event = @Event()
    *Node\Function_Window = @Window_Open()
    *Node\Function_Configuration_Get = @Configuration_Get()
    *Node\Function_Configuration_Set = @Configuration_Set()
    
    *Node\Name = Main\Node_Type\Name
    *Node\Name_Inherited = *Node\Name
    *Node\Color = RGBA(127, 127, 127, 255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    *Object\Window_Goto = AllocateStructure(Goto_Window)
    
    *Object\Window_Search = AllocateStructure(Search)
    
    ; #### Add Input
    *Input = Node::Input_Add(*Node)
    *Input\Function_Event = @Input_Event()
    
    ; #### Add Output
    *Output = Node::Output_Add(*Node, "Selection", "Selection")
    *Output\Function_Event = @Output_Event()
    *Output\Function_Get_Segments = @Output_Get_Segments()
    *Output\Function_Get_Descriptor = @Output_Get_Descriptor()
    *Output\Function_Get_Size = @Output_Get_Size()
    *Output\Function_Get_Data = @Output_Get_Data()
    *Output\Function_Set_Data = @Output_Set_Data()
    *Output\Function_Shift = @Output_Shift()
    *Output\Function_Set_Data_Check = @Output_Set_Data_Check()
    *Output\Function_Shift_Check = @Output_Shift_Check()
    
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
    Goto_Window_Close(*Node)
    Search_Window_Close(*Node)
    
    ForEach *Object\Segment()
      If *Object\Segment()\Raw_Data
        FreeMemory(*Object\Segment()\Raw_Data)
      EndIf
    Next
    
    FreeStructure(*Object\Window_Goto)
    *Object\Window_Goto = #Null
    
    FreeStructure(*Object\Window_Search)
    *Object\Window_Search = #Null
    
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
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Scroll_Line", NBT::#Tag_Quad)   : NBT::Tag_Set_Number(*NBT_Tag, *Object\Scroll_Line)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Select_Start", NBT::#Tag_Quad)  : NBT::Tag_Set_Number(*NBT_Tag, *Object\Select_Start)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Select_End", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\Select_End)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Select_Nibble", NBT::#Tag_Quad) : NBT::Tag_Set_Number(*NBT_Tag, *Object\Select_Nibble)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Write_Mode", NBT::#Tag_Quad)    : NBT::Tag_Set_Number(*NBT_Tag, *Object\Write_Mode)
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Scroll_Line")    : *Object\Scroll_Line = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Select_Start")   : *Object\Select_Start = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Select_End")     : *Object\Select_End = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Select_Nibble")  : *Object\Select_Nibble = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Write_Mode")     : *Object\Write_Mode = NBT::Tag_Get_Number(*NBT_Tag)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Event(*Node.Node::Object, *Event.Node::Event)
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Event.Node::Event
    
    Select *Event\Type
      Case Node::#Event_Save
        Event\Type = Node::#Event_Save
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case Node::#Event_SaveAs
        Event\Type = Node::#Event_SaveAs
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case Node::#Event_Undo
        Event\Type = Node::#Event_Undo
        Event\Value[0] = #True ; Undo a shift and write operation at once
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case Node::#Event_Redo
        Event\Type = Node::#Event_Redo
        Event\Value[0] = #True ; Redo a shift and write operation at once
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case Node::#Event_Cut
        Cut(*Node)
        
      Case Node::#Event_Copy
        Copy(*Node)
        
      Case Node::#Event_Paste
        Paste(*Node)
        
      Case Node::#Event_Goto
        Goto_Window_Open(*Node)
        
      Case Node::#Event_Search
        Search_Window_Open(*Node)
        
      Case Node::#Event_Search_Continue
        Search_Continue(*Node)
        
    EndSelect
    
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
    Protected Start.q, Length.q
    Protected Event.Node::Event
    
    If *Object\Select_Start < *Object\Select_End
      Start = *Object\Select_Start
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Start = *Object\Select_End
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
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
        Node::Output_Event(FirstElement(*Node\Output()), *Event)
        
      Case Node::#Link_Event_Update
        *Object\Redraw = #True
        ; #### Forward the event to the selection-output
        ;If *Event\Position + *Event\Size > Start And *Event\Position < Start + Length
          Event\Type = Node::#Link_Event_Update
          Event\Position = *Event\Position - Start
          Event\Size = *Event\Size
          Node::Output_Event(FirstElement(*Node\Output()), Event)
        ;EndIf
        
      Case Node::#Link_Event_Goto
        *Object\Select_Start = *Event\Position
        *Object\Select_End = *Event\Position + *Event\Size
        *Object\Select_Nibble = #False
        *Object\Temp_Nibble = #False ; #### Throw away the nibble-operation
        Scroll_2_Cursor(*Node)
        *Object\Redraw = #True
        ; #### Send a Update event to the selection-output
        Event\Type = Node::#Link_Event_Update
        Event\Position = 0
        Event\Size = Length
        Node::Output_Event(FirstElement(*Node\Output()), Event)
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
    If Not *Output
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Select *Event\Type
      Case Node::#Event_Save
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_SaveAs
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_Undo
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
        
      Case Node::#Event_Redo
        Node::Input_Event(FirstElement(*Node\Input()), *Event)
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Output_Get_Descriptor(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Selection of "+*Node\Name_Inherited)
    
    ProcedureReturn *Output\Descriptor
  EndProcedure
  
  Procedure.q Output_Get_Size(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn -1
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn -1
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    Protected Start.q, Length.q
    
    If *Object\Select_Start < *Object\Select_End
      Start = *Object\Select_Start
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Start = *Object\Select_End
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Start > Node::Input_Get_Size(FirstElement(*Node\Input()))
      ProcedureReturn -1
    EndIf
    
    ProcedureReturn Length
  EndProcedure
  
  Procedure Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q
    
    If *Object\Select_Start < *Object\Select_End
      Start = *Object\Select_Start
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Start = *Object\Select_End
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Size > Length - Position
      Size = Length - Position
    EndIf
    
    ProcedureReturn Node::Input_Get_Data(FirstElement(*Node\Input()), Start+Position, Size, *Data, *Metadata)
  EndProcedure
  
  Procedure Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Not *Data
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q
    
    If *Object\Select_Start < *Object\Select_End
      Start = *Object\Select_Start
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Start = *Object\Select_End
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Position > Length
      ProcedureReturn #False
    EndIf
    
    If Start + Position <= Node::Input_Get_Size(FirstElement(*Node\Input()))
      If Node::Input_Set_Data(FirstElement(*Node\Input()), Start + Position, Size, *Data)
        If *Object\Select_End >= *Object\Select_Start
          If Start + Position + Size > *Object\Select_End
            Range_Set(*Node, -1, Start + Position + Size, #False, #True)
          EndIf
        Else
          If Start + Position + Size > *Object\Select_Start
            Range_Set(*Node, Start + Position + Size, -1, #False, #True)
          EndIf
        EndIf
        ProcedureReturn #True
      EndIf
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q
    
    If *Object\Select_Start < *Object\Select_End
      Start = *Object\Select_Start
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Start = *Object\Select_End
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If -Offset > Length - Position
      Offset = - Length + Position
    EndIf
    
    If Position > Length
      ProcedureReturn #False
    EndIf
    
    If Start + Position <= Node::Input_Get_Size(FirstElement(*Node\Input()))
      If Node::Input_Shift(FirstElement(*Node\Input()), Start + Position, Offset)
        If *Object\Select_End >= *Object\Select_Start
          Range_Set(*Node, -1, *Object\Select_End + Offset, #False, #True)
        Else
          Range_Set(*Node, *Object\Select_Start + Offset, -1, #False, #True)
        EndIf
        ProcedureReturn #True
      EndIf
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Node::Input_Set_Data_Check(FirstElement(*Node\Input()), Position.q, Size.i)
  EndProcedure
  
  Procedure Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Node::Input_Shift_Check(FirstElement(*Node\Input()), Position.q, Offset.q)
  EndProcedure
  
  Procedure Organize(*Node.Node::Object)
    Protected Temp_Line.q
    Protected NewList Output_Segment.Node::Output_Segment()
    Protected *Output_Segment.Node::Output_Segment
    Protected *Object_Segment.Segment
    Protected Temp_Index
    ;Protected Found
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Set general information
    
    *Object\Line_Bytes = 16
    
    ; #### Get general information
    
    *Object\Data_Size = Node::Input_Get_Size(FirstElement(*Node\Input()))
    
    If *Object\Data_Size < 0
      ; #### No data is available
      *Object\Data_Size = 0
      
      While FirstElement(*Object\Segment())
        If *Object\Segment()\Raw_Data
          FreeMemory(*Object\Segment()\Raw_Data)
        EndIf
        DeleteElement(*Object\Segment())
      Wend
      
    Else
      
      ; #### Get segments
      Node::Input_Get_Segments(FirstElement(*Node\Input()), Output_Segment())
      
      ; #### Update semgents of the editor with the segments of the input
      *Output_Segment = FirstElement(Output_Segment())
      *Object_Segment = FirstElement(*Object\Segment())
      While *Output_Segment And *Object_Segment
        If *Output_Segment\Position = *Object_Segment\Start
          If *Object_Segment\Size <> *Output_Segment\Size
            ; #### Just update the length of the segment
            *Object_Segment\Metadata = *Output_Segment\Metadata
            *Object_Segment\Size = *Output_Segment\Size
            If *Object_Segment\Line_Start + *Object_Segment\Line_Amount <= *Object\Scroll_Line
              *Object\Scroll_Line - *Object_Segment\Line_Amount
            EndIf
            If *Output_Segment\Metadata & #Metadata_Readable
              *Object_Segment\Collapsed = #False
            Else
              *Object_Segment\Collapsed = #True
            EndIf
            *Object_Segment\Temp_New = #True
          EndIf
          *Output_Segment = NextElement(Output_Segment())
          *Object_Segment = NextElement(*Object\Segment())
        ElseIf *Object_Segment\Start < *Output_Segment\Position
          ; #### Remove the segment
          If *Object_Segment\Line_Start + *Object_Segment\Line_Amount <= *Object\Scroll_Line
            *Object\Scroll_Line - *Object_Segment\Line_Amount
          EndIf
          Temp_Index = ListIndex(*Object\Segment())
          DeleteElement(*Object\Segment(), #True)
          *Object_Segment = SelectElement(*Object\Segment(), Temp_Index)
        Else
          ; #### Insert a segment
          *Object_Segment = InsertElement(*Object\Segment())
          *Object_Segment\Metadata = *Output_Segment\Metadata
          *Object_Segment\Start = *Output_Segment\Position
          *Object_Segment\Size = *Output_Segment\Size
          *Object_Segment\Temp_New = #True
          If *Output_Segment\Metadata & #Metadata_Readable
            *Object_Segment\Collapsed = #False
          Else
            *Object_Segment\Collapsed = #True
          EndIf
        EndIf
      Wend
      While ListSize(Output_Segment()) < ListSize(*Object\Segment())
        ; #### Remove the last segment
        If LastElement(*Object\Segment())
          If *Object\Segment()\Line_Start + *Object\Segment()\Line_Amount <= *Object\Scroll_Line
            *Object\Scroll_Line - *Object\Segment()\Line_Amount
          EndIf
          DeleteElement(*Object\Segment())
        EndIf
      Wend
      While ListSize(Output_Segment()) > ListSize(*Object\Segment())
        If SelectElement(Output_Segment(), ListSize(*Object\Segment()))
          ; #### Insert a segment
          LastElement(*Object\Segment())
          If AddElement(*Object\Segment())
            *Object\Segment()\Metadata = Output_Segment()\Metadata
            *Object\Segment()\Start = Output_Segment()\Position
            *Object\Segment()\Size = Output_Segment()\Size
            *Object\Segment()\Temp_New = #True
            If Output_Segment()\Metadata & #Metadata_Readable
              *Object\Segment()\Collapsed = #False
            Else
              *Object\Segment()\Collapsed = #True
            EndIf
          EndIf
        EndIf
      Wend
      
      ; #### If no segments available, create one
      If ListSize(Output_Segment()) = 0
        If ListSize(*Object\Segment()) = 0
          AddElement(*Object\Segment())
        EndIf
        If FirstElement(*Object\Segment())
          *Object\Segment()\Start = 0
          *Object\Segment()\Size = *Object\Data_Size
        EndIf
      EndIf
      
    EndIf
    
    ; #### Calculate Segment stuff
    Temp_Line = 0
    ForEach *Object\Segment()
      If *Object\Segment()\Size < 0
        *Object\Segment()\Size = 0
      EndIf
      
      ; #### Arrange the segments one after another
      *Object\Segment()\Line_Start = Temp_Line
      
      ; #### Update the amount of lines the segment needs (including range header)
      If *Object\Segment()\Collapsed
        *Object\Segment()\Line_Amount = 1
      Else
        *Object\Segment()\Line_Amount = 2 + (*Object\Segment()\Size + *Object\Segment()\Start % *Object\Line_Bytes) / *Object\Line_Bytes
      EndIf
      
      If *Object\Segment()\Temp_New
        *Object\Segment()\Temp_New = #False
        If *Object\Segment()\Line_Start + *Object\Segment()\Line_Amount <= *Object\Scroll_Line
          *Object\Scroll_Line + *Object\Segment()\Line_Amount
        EndIf
      EndIf
      
      Temp_Line + *Object\Segment()\Line_Amount
    Next
    *Object\Scroll_Lines = Temp_Line
    
    ; #### Window values
    Protected Width = GadgetWidth(*Object\Canvas)
    Protected Height = GadgetHeight(*Object\Canvas)
    
    *Object\Adress_Length = Len(Hex(*Object\Data_Size, #PB_Quad))
    
    *Object\Y0 = Main\Font_Height * 1.5
    *Object\X0 = Main\Font_Width * (*Object\Adress_Length + 2)
    *Object\X1 = Main\Font_Width * (*Object\Line_Bytes * 3 + 1)
    *Object\X2 = Main\Font_Width * (*Object\Line_Bytes + 1)       ; FIXME: Undo when the bug in PureBasic is fixed. Right now it's a silly workaround!
    *Object\X1 + *Object\X0
    *Object\X2 + *Object\X1
    
    *Object\Lines = Quad_Divide_Ceil(Height - *Object\Y0, Main\Font_Height)
    
    *Object\Scroll_Divider = Quad_Divide_Ceil(*Object\Scroll_Lines, 2147483647)
    If *Object\Scroll_Divider < 1 : *Object\Scroll_Divider = 1 : EndIf
    SetGadgetAttribute(*Object\ScrollBar, #PB_ScrollBar_Maximum, *Object\Scroll_Lines / *Object\Scroll_Divider)
    SetGadgetAttribute(*Object\ScrollBar, #PB_ScrollBar_PageLength, *Object\Lines / *Object\Scroll_Divider)
    SetGadgetState(*Object\ScrollBar, *Object\Scroll_Line / *Object\Scroll_Divider)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Data(*Node.Node::Object)
    Protected Data_Size.q
    Protected Raw_Data_End.q
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Segment()
      If *Object\Segment()\Collapsed
        *Object\Segment()\Raw_Data_Start = 0
        *Object\Segment()\Raw_Data_Size = 0
      Else
        If *Object\Segment()\Line_Start < *Object\Scroll_Line + *Object\Lines And *Object\Segment()\Line_Start + *Object\Segment()\Line_Amount > *Object\Scroll_Line
          
          ; #### Calculate the start of the raw_data
          *Object\Segment()\Raw_Data_Start = *Object\Segment()\Start - *Object\Segment()\Start % *Object\Line_Bytes
          *Object\Segment()\Raw_Data_Start - (*Object\Segment()\Line_Start + 1 - *Object\Scroll_Line) * *Object\Line_Bytes
          
          If *Object\Segment()\Raw_Data_Start < *Object\Segment()\Start
            *Object\Segment()\Raw_Data_Start = *Object\Segment()\Start
          EndIf
          
          *Object\Segment()\Raw_Data_Byte_Start = *Object\Segment()\Raw_Data_Start % *Object\Line_Bytes
          
          ; #### Figure out which line (absolute) that actually is.
          *Object\Segment()\Raw_Data_Line_Start = *Object\Segment()\Line_Start + 1 + (*Object\Segment()\Raw_Data_Start - *Object\Segment()\Start + *Object\Segment()\Start % *Object\Line_Bytes) / *Object\Line_Bytes
          
          ; #### Calculate the size of the raw_data (Get the maximum possible size from the Raw_Data_Start to the end of the segment)
          *Object\Segment()\Raw_Data_Size = *Object\Segment()\Size - (*Object\Segment()\Raw_Data_Start - *Object\Segment()\Start)
          
          ; #### Cut it to the window if needed.
          If *Object\Segment()\Raw_Data_Size > (*Object\Scroll_Line + *Object\Lines - *Object\Segment()\Line_Start - 1) * *Object\Line_Bytes - *Object\Segment()\Raw_Data_Byte_Start - (*Object\Segment()\Raw_Data_Start - *Object\Segment()\Start)
            *Object\Segment()\Raw_Data_Size = (*Object\Scroll_Line + *Object\Lines - *Object\Segment()\Line_Start - 1) * *Object\Line_Bytes - *Object\Segment()\Raw_Data_Byte_Start - (*Object\Segment()\Raw_Data_Start - *Object\Segment()\Start)
          EndIf
          
          ; #### Allocate the memory
          If *Object\Segment()\Raw_Data
            FreeMemory(*Object\Segment()\Raw_Data)
            FreeMemory(*Object\Segment()\Raw_Metadata)
            *Object\Segment()\Raw_Data = #Null
            *Object\Segment()\Raw_Metadata = #Null
          EndIf
          If *Object\Segment()\Raw_Data_Size > 0
            *Object\Segment()\Raw_Data = AllocateMemory(*Object\Segment()\Raw_Data_Size)
            *Object\Segment()\Raw_Metadata = AllocateMemory(*Object\Segment()\Raw_Data_Size)
          EndIf
          
          ; #### Get the data.
          If *Object\Segment()\Raw_Data_Size > 0
            Node::Input_Get_Data(FirstElement(*Node\Input()), *Object\Segment()\Raw_Data_Start, *Object\Segment()\Raw_Data_Size, *Object\Segment()\Raw_Data, *Object\Segment()\Raw_Metadata)
          EndIf
          
        EndIf
      EndIf
    Next
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Canvas_Redraw_Filter_Blink(x, y, SourceColor, TargetColor)
    If (x+y) & 1
      ProcedureReturn ~TargetColor
    Else
      ProcedureReturn TargetColor
    EndIf
  EndProcedure
  
  Procedure Canvas_Redraw_Filter_Inverse(x, y, SourceColor, TargetColor)
    ProcedureReturn ~TargetColor
  EndProcedure
  
  Procedure Canvas_Redraw(*Node.Node::Object)
    Protected i
    Protected D_X.q, D_Y.q  ; Data-Coordinates
    Protected S_Y.q         ; Y-Screen-Coordinate of a line (Offset, Hex, Ascii)
    Protected Hex_X.q       ; X-Screen-Coordinates of the hexfield
    Protected Ascii_X.q     ; X-Screen-Coordinates of the Asciifield
    Protected Temp_Adress.q
    Protected Color_Front_Hex, Color_Front_Ascii, Color_Back_Hex, Color_Back_Ascii
    Protected Metadata.a
    Protected String_Ascii.s{1}
    Protected String_Hex.s{2}
    Protected *String_Temp_Buffer, String_Temp_Size.i ; String_Temp_Size is in characters (#PB_Unicode --> #PB_UTF16 --> 16 bit)
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    Protected Width = GadgetWidth(*Object\Canvas)
    Protected Height = GadgetHeight(*Object\Canvas)
    Protected Active
    
    If GetActiveGadget() = *Object\Canvas
      Active = #True
    Else
      Active = #False
    EndIf
    
    If Not StartDrawing(CanvasOutput(*Object\Canvas))
      ProcedureReturn #False
    EndIf
    
    Box(0, 0, Width, Height, RGB(255,255,255))
    
    DrawingFont(FontID(Main\Font_ID))
    
    FrontColor(RGB(0,0,255))
    BackColor(RGB(255,255,255))
    
    ;DrawText(0, 0, Str(*Object\Scroll_Line))
    
    ; #### Display the Adress in X-Direction
    For i = 0 To *Object\Line_Bytes - 1
      Hex_X = *Object\X0 + i * Main\Font_Width * 3
      DrawText(Hex_X, 0, RSet(Hex(i),2,"0"))
    Next
    
    ForEach *Object\Segment()
      If *Object\Segment()\Line_Start < *Object\Scroll_Line + *Object\Lines And *Object\Segment()\Line_Start + *Object\Segment()\Line_Amount > *Object\Scroll_Line
        
        ; #### Display the range of the segment
        FrontColor(RGB(255,0,0))
        D_X = 0
        D_Y = *Object\Segment()\Line_Start - *Object\Scroll_Line
        If D_Y >= 0 And D_Y < *Object\Lines
          Hex_X = *Object\X0 + D_X * Main\Font_Width * 3
          S_Y = *Object\Y0 + D_Y * Main\Font_Height
          Line(0, S_Y-1, Width, 0, RGB(200,200,200))
          If *Object\Segment()\Size > 0
            If *Object\Segment()\Collapsed
              DrawText(Hex_X, S_Y, "[+] Range = [h"+RSet(Hex(*Object\Segment()\Start),*Object\Adress_Length,"0")+"-h"+RSet(Hex(*Object\Segment()\Start+*Object\Segment()\Size-1),*Object\Adress_Length,"0")+"]; Size = h"+RSet(Hex(*Object\Segment()\Size),*Object\Adress_Length,"0"))
            Else
              DrawText(Hex_X, S_Y, "[-] Range = [h"+RSet(Hex(*Object\Segment()\Start),*Object\Adress_Length,"0")+"-h"+RSet(Hex(*Object\Segment()\Start+*Object\Segment()\Size-1),*Object\Adress_Length,"0")+"]; Size = h"+RSet(Hex(*Object\Segment()\Size),*Object\Adress_Length,"0"))
            EndIf
          Else
            If *Object\Segment()\Collapsed
              DrawText(Hex_X, S_Y, "[+] Size = h"+RSet(Hex(*Object\Segment()\Size),*Object\Adress_Length,"0"))
            Else
              DrawText(Hex_X, S_Y, "[-] Size = h"+RSet(Hex(*Object\Segment()\Size),*Object\Adress_Length,"0"))
            EndIf
          EndIf
        EndIf
        
        ; #### Draw the adresses left of the data
        D_Y = *Object\Segment()\Raw_Data_Line_Start - *Object\Scroll_Line
        Temp_Adress = *Object\Segment()\Raw_Data_Start
        Temp_Adress - Temp_Adress % *Object\Line_Bytes
        For i = 0 To (*Object\Segment()\Raw_Data_Size + *Object\Segment()\Raw_Data_Byte_Start) / *Object\Line_Bytes ;Int_Divide_RUP(*Object\Segment()\Raw_Data_Size, *Object\Line_Bytes)
          S_Y = *Object\Y0 + D_Y * Main\Font_Height
          DrawText(0, S_Y, RSet(Hex(Temp_Adress),*Object\Adress_Length,"0"), RGB(0,0,255))
          Temp_Adress + *Object\Line_Bytes
          D_Y + 1
        Next
        
        ; #### Display the data of the segment
        FrontColor(RGB(0,0,0))
        D_X = *Object\Segment()\Raw_Data_Byte_Start
        D_Y = *Object\Segment()\Raw_Data_Line_Start - *Object\Scroll_Line
        S_Y = *Object\Y0 + D_Y * Main\Font_Height
        Temp_Adress = *Object\Segment()\Raw_Data_Start
        
        For i = 0 To *Object\Segment()\Raw_Data_Size-1
          
          Metadata = PeekA(*Object\Segment()\Raw_Metadata+i)
          
          If InRange(*Object\Select_Start, *Object\Select_End, Temp_Adress)
            If Active
              If *Object\Select_Field = 0
                ; #### Hex selected
                Color_Front_Hex = RGB(255,255,255)
                Color_Front_Ascii = RGB(0,0,0)
                Color_Back_Hex = RGB(51,153,255)
                Color_Back_Ascii = RGB(169,212,255)
              Else
                ; #### Ascii selected
                Color_Front_Hex = RGB(0,0,0)
                Color_Front_Ascii = RGB(255,255,255)
                Color_Back_Hex = RGB(169,212,255)
                Color_Back_Ascii = RGB(51,153,255)
              EndIf
            Else
              If *Object\Select_Field = 0
                ; #### Hex selected
                Color_Front_Hex = RGB(255,255,255)
                Color_Front_Ascii = RGB(0,0,0)
                Color_Back_Hex = RGB(127,127,127)
                Color_Back_Ascii = RGB(200,200,200)
              Else
                ; #### Ascii selected
                Color_Front_Hex = RGB(0,0,0)
                Color_Front_Ascii = RGB(255,255,255)
                Color_Back_Hex = RGB(200,200,200)
                Color_Back_Ascii = RGB(127,127,127)
              EndIf
            EndIf
            If Metadata & #Metadata_NoError
              If Metadata & #Metadata_Readable
                String_Hex = RSet(Hex(PeekA(*Object\Segment()\Raw_Data+i)),2,"0")
                If PeekA(*Object\Segment()\Raw_Data+i) = 0
                  String_Ascii = " "
                Else
                  String_Temp_Size = MultiByteToWideChar_(437, #MB_USEGLYPHCHARS, *Object\Segment()\Raw_Data+i, 1, #Null, 0)
                  *String_Temp_Buffer = AllocateMemory(String_Temp_Size*2)
                  MultiByteToWideChar_(437, #MB_USEGLYPHCHARS, *Object\Segment()\Raw_Data+i, 1, *String_Temp_Buffer, String_Temp_Size)
                  String_Ascii = PeekS(*String_Temp_Buffer, String_Temp_Size, #PB_Unicode)
                  FreeMemory(*String_Temp_Buffer)
                EndIf
              Else
                String_Hex = "??"
                String_Ascii = "?"
              EndIf
            Else
              String_Hex = "!!"
              String_Ascii = "!"
            EndIf
          Else
            If Metadata & #Metadata_NoError
              If Metadata & #Metadata_Readable
                If Metadata & #Metadata_Changed
                  Color_Front_Hex = RGB(0,0,255)
                  Color_Back_Hex = RGB(255,255,255)
                Else
                  Color_Front_Hex = RGB(0,0,0)
                  Color_Back_Hex = RGB(255,255,255)
                EndIf
                String_Hex = RSet(Hex(PeekA(*Object\Segment()\Raw_Data+i)),2,"0")
                If PeekA(*Object\Segment()\Raw_Data+i) = 0
                  String_Ascii = " "
                Else
                  String_Temp_Size = MultiByteToWideChar_(437, #MB_USEGLYPHCHARS, *Object\Segment()\Raw_Data+i, 1, #Null, 0)
                  *String_Temp_Buffer = AllocateMemory(String_Temp_Size*2)
                  MultiByteToWideChar_(437, #MB_USEGLYPHCHARS, *Object\Segment()\Raw_Data+i, 1, *String_Temp_Buffer, String_Temp_Size)
                  String_Ascii = PeekS(*String_Temp_Buffer, String_Temp_Size, #PB_Unicode)
                  FreeMemory(*String_Temp_Buffer)
                EndIf
              Else
                Color_Front_Hex = RGB(255,0,0)
                Color_Back_Hex = RGB(255,255,255)
                String_Hex = "??"
                String_Ascii = "?"
              EndIf
            Else
              Color_Front_Hex = RGB(255,0,0)
              Color_Back_Hex = RGB(255,255,255)
              String_Hex = "!!"
              String_Ascii = "!"
            EndIf
            Color_Front_Ascii = Color_Front_Hex
            Color_Back_Ascii = Color_Back_Hex
          EndIf
          
          ; #### Draw the Text
          Hex_X = *Object\X0 + D_X * Main\Font_Width * 3
          DrawText(Hex_X, S_Y, String_Hex+" ", Color_Front_Hex, Color_Back_Hex)
          Ascii_X = *Object\X1 + D_X * Main\Font_Width
          DrawText(Ascii_X, S_Y, String_Ascii, Color_Front_Ascii, Color_Back_Ascii)
          
          ; #### Draw the cursors
          If Temp_Adress = *Object\Select_End
            ; #### Draw the Temp_Nibble
            If *Object\Temp_Nibble
              DrawText(Hex_X, S_Y, Hex(*Object\Temp_Nibble_Value), RGB(0,0,255), Color_Back_Hex)
            EndIf
            
            DrawingMode(#PB_2DDrawing_Outlined | #PB_2DDrawing_CustomFilter)
            If *Object\Select_Field = 0
              ; #### Hex selected
              CustomFilterCallback(@Canvas_Redraw_Filter_Inverse())
              If *Object\Select_Nibble
                Hex_X + Main\Font_Width
              EndIf
              If *Object\Write_Mode = 0
                Box(Hex_X, S_Y + Main\Font_Height, Main\Font_Width, -2)
              Else
                Box(Hex_X, S_Y, 2, Main\Font_Height)
              EndIf
              CustomFilterCallback(@Canvas_Redraw_Filter_Blink())
              Box(Ascii_X, S_Y, Main\Font_Width, Main\Font_Height)
            Else
              ; #### Ascii selected
              CustomFilterCallback(@Canvas_Redraw_Filter_Blink())
              Box(Hex_X, S_Y, Main\Font_Width, Main\Font_Height)
              CustomFilterCallback(@Canvas_Redraw_Filter_Inverse())
              If *Object\Write_Mode = 0
                Box(Ascii_X, S_Y + Main\Font_Height, Main\Font_Width, -2)
              Else
                Box(Ascii_X, S_Y, 2, Main\Font_Height)
              EndIf
            EndIf
            DrawingMode(#PB_2DDrawing_Default)
          EndIf
          
          D_X + 1
          Temp_Adress + 1
          If D_X >= *Object\Line_Bytes
            D_X = 0
            D_Y + 1
            S_Y = *Object\Y0 + D_Y * Main\Font_Height
            If D_Y >= *Object\Lines
              Break
            EndIf
          EndIf
        Next
        
        ; #### Draw the cursors (Even if outside of the segment's data)
        If Temp_Adress = *Object\Select_End
          Hex_X = *Object\X0 + D_X * Main\Font_Width * 3
          Ascii_X = *Object\X1 + D_X * Main\Font_Width
          ; #### Draw the Temp_Nibble
          If *Object\Temp_Nibble
            DrawText(Hex_X, S_Y, Hex(*Object\Temp_Nibble_Value), RGB(0,0,255), RGB(255,255,255))
          EndIf
          DrawingMode(#PB_2DDrawing_Outlined | #PB_2DDrawing_CustomFilter)
          If *Object\Select_Field = 0
            ; #### Hex selected
            CustomFilterCallback(@Canvas_Redraw_Filter_Inverse())
            If *Object\Select_Nibble
              Hex_X + Main\Font_Width
            EndIf
            If *Object\Write_Mode = 0
              Box(Hex_X, S_Y + Main\Font_Height, Main\Font_Width, -2)
            Else
              Box(Hex_X, S_Y, 2, Main\Font_Height)
            EndIf
            CustomFilterCallback(@Canvas_Redraw_Filter_Blink())
            Box(Ascii_X, S_Y, Main\Font_Width, Main\Font_Height)
          Else
            ; #### Ascii selected
            CustomFilterCallback(@Canvas_Redraw_Filter_Blink())
            Box(Hex_X, S_Y, Main\Font_Width, Main\Font_Height)
            CustomFilterCallback(@Canvas_Redraw_Filter_Inverse())
            If *Object\Write_Mode = 0
              Box(Ascii_X, S_Y + Main\Font_Height, Main\Font_Width, -2)
            Else
              Box(Ascii_X, S_Y, 2, Main\Font_Height)
            EndIf
          EndIf
          DrawingMode(#PB_2DDrawing_Default)
        EndIf
        
      EndIf
    Next
    
    StopDrawing()
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Statusbar_Update(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window = Window::Get_Active()
      If *Object\Select_Start < *Object\Select_End
        StatusBarText(Main::Window\StatusBar_ID, 0, "Offset: "+Hex(*Object\Select_Start))
      Else
        StatusBarText(Main::Window\StatusBar_ID, 0, "Offset: "+Hex(*Object\Select_End))
      EndIf
      
      If *Object\Select_Start <> *Object\Select_End
        If *Object\Select_Start < *Object\Select_End
          StatusBarText(Main::Window\StatusBar_ID, 1, "Block: "+Hex(*Object\Select_Start)+" - "+Hex(*Object\Select_End-1))
          StatusBarText(Main::Window\StatusBar_ID, 2, "Length: "+Hex(*Object\Select_End-*Object\Select_Start))
        Else
          StatusBarText(Main::Window\StatusBar_ID, 1, "Block: "+Hex(*Object\Select_End)+" - "+Hex(*Object\Select_Start-1))
          StatusBarText(Main::Window\StatusBar_ID, 2, "Length: "+Hex(*Object\Select_Start-*Object\Select_End))
        EndIf
      Else
        StatusBarText(Main::Window\StatusBar_ID, 1, "")
        StatusBarText(Main::Window\StatusBar_ID, 2, "")
      EndIf
    EndIf
    
  EndProcedure
  
  Procedure Cut(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q, *Text.String, Text.s
    Protected i
    
    If *Object\Select_Start <> *Object\Select_End
      If *Object\Select_Start < *Object\Select_End
        Start = *Object\Select_Start
        Length = *Object\Select_End-*Object\Select_Start
      Else
        Start = *Object\Select_End
        Length = *Object\Select_Start-*Object\Select_End
      EndIf
      If Length < 100000000
        *Text = AllocateMemory(Length + 1)
          Node::Input_Get_Data(FirstElement(*Node\Input()), Start, Length, *Text, #Null)
        If *Object\Select_Field = 0 ; Hex
          For i = 0 To Length-1
            Text + RSet(Hex(PeekA(*Text+i)),2,"0")
            If i < Length-1
              Text + " "
            EndIf
          Next
          SetClipboardText(Text)
        Else
          SetClipboardText(PeekS(*Text, Length, #PB_Ascii))
        EndIf
        
        Remove_Data(*Node, 0)
        
        FreeMemory(*Text)
      EndIf
      *Object\Redraw = #True
    EndIf
  EndProcedure
  
  Procedure Copy(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q, *Text.String, Text.s
    Protected i
    
    If *Object\Select_Start <> *Object\Select_End
      If *Object\Select_Start < *Object\Select_End
        Start = *Object\Select_Start
        Length = *Object\Select_End-*Object\Select_Start
      Else
        Start = *Object\Select_End
        Length = *Object\Select_Start-*Object\Select_End
      EndIf
      If Length < 100000000
        *Text = AllocateMemory(Length + 1)
          Node::Input_Get_Data(FirstElement(*Node\Input()), Start, Length, *Text, #Null)
        If *Object\Select_Field = 0 ; Hex
          For i = 0 To Length-1
            Text + RSet(Hex(PeekA(*Text+i)),2,"0")
            If i < Length-1
              Text + " "
            EndIf
          Next
          SetClipboardText(Text)
        Else
          SetClipboardText(PeekS(*Text, Length, #PB_Ascii))
        EndIf
        FreeMemory(*Text)
      EndIf
      *Object\Redraw = #True
    EndIf
  EndProcedure
  
  Procedure Paste(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Start.q, Length.q, *Text.String, Text.s, Hex_Elements.i
    Protected i
    
    Text.s = GetClipboardText()
    Length = Len(Text)
    *Text = AllocateMemory(Length + 1)
    If *Object\Select_Field = 0 ; Hex
      Text = Trim(Text)
      Hex_Elements = CountString(Text, " ") + 1
      For i = 0 To Hex_Elements - 1
        PokeA(*Text+i, Val("$"+StringField(Text, i+1, " ")))
      Next
      Length = Hex_Elements
    Else
      PokeS(*Text, Text, Length, #PB_Ascii)
    EndIf
    Write_Data(*Node, *Text, Length)
    Scroll_2_Cursor(*Node)
    FreeMemory(*Text)
  EndProcedure
  
  Procedure Remove_Data(*Node.Node::Object, Bytes.q, Backspace=#False)
    Protected Select_Start.q, Select_Length.q
    
    If Bytes < 0
      ProcedureReturn #False
    EndIf
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Determine the start and length of the selected range
    If *Object\Select_Start < *Object\Select_End
      Select_Start = *Object\Select_Start
      Select_Length = *Object\Select_End-*Object\Select_Start
    Else
      Select_Start = *Object\Select_End
      Select_Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Select_Length > 0
      ; #### Remove the selected range (throught negative shifting)
      Node::Input_Shift(FirstElement(*Node\Input()), Select_Start, -Select_Length)
      ; #### Change the selection from range to a single position
      Range_Set(*Node, Select_Start, Select_Start, #False, #True)
    ElseIf Bytes > 0
      ; #### Abort current nibble-operation
      Write_Nibble(*Node, 0, #True)
      
      If Backspace
        ; #### Crop the amount of bytes to the available bytes
        If Bytes > Select_Start
          Bytes = Select_Start
        EndIf
        If Node::Input_Shift(FirstElement(*Node\Input()), Select_Start-Bytes, -Bytes)
          Range_Set(*Node, Select_Start-Bytes, Select_Start-Bytes, #False, #True)
        EndIf
      Else
        Node::Input_Shift(FirstElement(*Node\Input()), Select_Start, -Bytes)
        Range_Set(*Node, Select_Start, Select_Start, #False, #True)
      EndIf
      *Object\Redraw = #True
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Write_Data(*Node.Node::Object, *Data, Size.i)
    Protected Select_Start.q, Select_Length.q
    Protected Result = #False
    Protected Char.a
    
    If Size < 0
      ProcedureReturn #False
    EndIf
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Determine the start and length of the selected range
    If *Object\Select_Start < *Object\Select_End
      Select_Start = *Object\Select_Start
      Select_Length = *Object\Select_End-*Object\Select_Start
    Else
      Select_Start = *Object\Select_End
      Select_Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    ; #### Remove the selected range (throught negative shifting) (If insert-mode is enabled)
    If *Object\Write_Mode = #WriteMode_Insert
      Remove_Data(*Node, 0)
    Else
      ; #### Change the selection from range to a single position
      Range_Set(*Node, Select_Start, Select_Start, #False, #False)
    EndIf
    
    ; #### Write the data
    If *Data And Size > 0
      Select *Object\Write_Mode
        Case #WriteMode_Overwrite
          Result = Node::Input_Set_Data(FirstElement(*Node\Input()), Select_Start, Size, *Data)
          
        Case #WriteMode_Insert
          If Node::Input_Shift(FirstElement(*Node\Input()), Select_Start, Size)
            Result = Node::Input_Set_Data(FirstElement(*Node\Input()), Select_Start, Size, *Data)
          EndIf
          
      EndSelect
    EndIf
    
    If Result
      Range_Set(*Node, Select_Start + Size, Select_Start + Size, #False, #True)
    EndIf
    
    *Object\Redraw = #True
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure Write_Nibble(*Node.Node::Object, Char.a, Abort.i=#False)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Select_Start.q, Select_Length.q
    Protected Result = #False
    Protected Temp_Char.a
    Protected Found
    
    ; #### Determine the start and length of the selected range
    If *Object\Select_Start < *Object\Select_End
      Select_Start = *Object\Select_Start
      Select_Length = *Object\Select_End-*Object\Select_Start
    Else
      Select_Start = *Object\Select_End
      Select_Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Abort
      ; #### Abort nibble operation. Write the stored nibble...
      
      If *Object\Temp_Nibble
        If Select_Length = 0
          If Node::Input_Get_Data(FirstElement(*Node\Input()), Select_Start, 1, @Temp_Char, #Null)
            Temp_Char & $0F
            Temp_Char | *Object\Temp_Nibble_Value << 4
            Result = Node::Input_Set_Data(FirstElement(*Node\Input()), Select_Start, 1, @Temp_Char)
          EndIf
        EndIf
        *Object\Temp_Nibble = #False
      EndIf
      
    Else
      
      ; #### Remove the selected range (throught negative shifting) (If insert-mode is enabled)
      If *Object\Write_Mode = #WriteMode_Insert
        Remove_Data(*Node, 0)
      Else
        ; #### Change the selection from range to a single position
        ;Range_Set(*Node, Select_Start, Select_Start, #False, #False)
      EndIf
      
      If *Object\Select_Nibble
        If Node::Input_Get_Data(FirstElement(*Node\Input()), Select_Start, 1, @Temp_Char, #Null)
          Found = #True
        EndIf
        If *Object\Temp_Nibble
          Temp_Char & $0F
          Temp_Char | *Object\Temp_Nibble_Value << 4
          Found = #True
        EndIf
        If Found
          Temp_Char & $F0
          Temp_Char | Char
          Result = Node::Input_Set_Data(FirstElement(*Node\Input()), Select_Start, 1, @Temp_Char)
          If Not Result
            *Object\Select_Nibble = #False
          EndIf
          *Object\Temp_Nibble = #False
        EndIf
      Else
        Select *Object\Write_Mode
          Case #WriteMode_Overwrite
            *Object\Temp_Nibble = #True
            *Object\Temp_Nibble_Value = Char
            Result = #True
          Case #WriteMode_Insert
            If Node::Input_Shift(FirstElement(*Node\Input()), Select_Start, 1)
              Temp_Char = Char << 4
              Result = Node::Input_Set_Data(FirstElement(*Node\Input()), Select_Start, 1, @Temp_Char)
            EndIf
        EndSelect
      EndIf
      
      If Result
        If *Object\Select_Nibble
          *Object\Select_Start = Select_Start + 1
          *Object\Select_End = Select_Start + 1
          *Object\Select_Nibble = #False
        Else
          *Object\Select_Start = Select_Start
          *Object\Select_End = Select_Start
          *Object\Select_Nibble = #True
        EndIf
      EndIf
    EndIf
    
    *Object\Redraw = #True
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure Scroll_2_Cursor(*Node.Node::Object)
    Protected Cursor_Line.q
    Protected *Nearest_Segment.Segment
    Protected Temp_Distance ; in Bytes
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Find the nearest segment
    Temp_Distance = 10000
    ForEach *Object\Segment()
      If *Object\Segment()\Start <= *Object\Select_End And *Object\Segment()\Start + *Object\Segment()\Size > *Object\Select_End
        ; Inside of a segment
        *Nearest_Segment = *Object\Segment()
        Break
      Else
        ; Check distance from the start
        If *Object\Segment()\Start - *Object\Select_End > 0
          If Temp_Distance > *Object\Segment()\Start - *Object\Select_End
            Temp_Distance = *Object\Segment()\Start - *Object\Select_End
            *Nearest_Segment = *Object\Segment()
          EndIf
        EndIf
        ; Check distance from the end
        If *Object\Select_End - (*Object\Segment()\Start + *Object\Segment()\Size) > 0
          If Temp_Distance > *Object\Select_End - (*Object\Segment()\Start + *Object\Segment()\Size)
            Temp_Distance = *Object\Select_End - (*Object\Segment()\Start + *Object\Segment()\Size)
            *Nearest_Segment = *Object\Segment()
          EndIf
        EndIf
      EndIf
    Next
    
    If *Nearest_Segment
      If *Nearest_Segment\Collapsed
        Cursor_Line = *Nearest_Segment\Line_Start
      Else
        Cursor_Line = *Nearest_Segment\Line_Start + 1 + Quad_Divide_Floor(*Nearest_Segment\Start % *Object\Line_Bytes + *Object\Select_End - *Nearest_Segment\Start, *Object\Line_Bytes)
      EndIf
      
      If *Object\Scroll_Line > Cursor_Line
        *Object\Scroll_Line = Cursor_Line
        *Object\Redraw = #True
      EndIf
      
      If *Object\Scroll_Line + *Object\Lines - 2 < Cursor_Line
        *Object\Scroll_Line = Cursor_Line - *Object\Lines + 2
        *Object\Redraw = #True
      EndIf
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Range_Set(*Node.Node::Object, Select_Start.q, Select_End.q, Select_Nibble.i, Scroll_2_Cursor=#False, Redraw=#True)
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected Length.q
    Protected Event.Node::Event
    
    ; #### Abort current nibble operation
    Write_Nibble(*Node, 0, #True)
    
    If Select_Start >= 0
      *Object\Select_Start = Select_Start
    EndIf
    If Select_End >= 0
      *Object\Select_End = Select_End
    EndIf
    If Select_Nibble >= 0
      *Object\Select_Nibble = Select_Nibble
    EndIf
    
    If *Object\Select_Start <> *Object\Select_End
      *Object\Select_Nibble = #False
    EndIf
    
    If Scroll_2_Cursor
      Scroll_2_Cursor(*Node)
    EndIf
    
    ; #### Determine the start and length of the selected range
    If *Object\Select_Start < *Object\Select_End
      Length = *Object\Select_End-*Object\Select_Start
    Else
      Length = *Object\Select_Start-*Object\Select_End
    EndIf
    
    If Redraw
      *Object\Redraw = #True
      
      Event\Type = Node::#Link_Event_Update
      Event\Position = 0
      Event\Size = Length
      Node::Output_Event(FirstElement(*Node\Output()), Event)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure.q Canvas_Mouse_2_Position(*Node.Node::Object, Mouse_X, Mouse_Y, Field, Set_Start, Set_End, Set_Nibble)
    Protected Mouse_Line.q, Mouse_Byte.q
    Protected Position.q, Nibble.i
    Protected *Nearest_Segment.Segment
    Protected Temp_Distance.q ; in Lines
    
    If Not *Node
      ProcedureReturn 0
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn 0
    EndIf
    
    Mouse_Line = Quad_Divide_Floor(Mouse_Y - *Object\Y0, Main\Font_Height)
    
    ; #### Find the nearest segment
    Temp_Distance = 10000
    ForEach *Object\Segment()
      If *Object\Segment()\Line_Start - *Object\Scroll_Line <= Mouse_Line And *Object\Segment()\Line_Start + *Object\Segment()\Line_Amount - *Object\Scroll_Line > Mouse_Line
        ; Inside of a segment
        *Nearest_Segment = *Object\Segment()
        Break
      Else
        ; Check distance from the mouse to the start
        If *Object\Segment()\Line_Start - (Mouse_Line + *Object\Scroll_Line) >= 0
          If Temp_Distance > *Object\Segment()\Line_Start - (Mouse_Line + *Object\Scroll_Line)
            Temp_Distance = *Object\Segment()\Line_Start - (Mouse_Line + *Object\Scroll_Line)
            *Nearest_Segment = *Object\Segment()
          EndIf
        EndIf
        ; Check distance from the mouse to the end
        If (Mouse_Line + *Object\Scroll_Line) - (*Object\Segment()\Line_Start + *Object\Segment()\Line_Amount) >= 0
          If Temp_Distance > (Mouse_Line + *Object\Scroll_Line) - (*Object\Segment()\Line_Start + *Object\Segment()\Line_Amount)
            Temp_Distance = (Mouse_Line + *Object\Scroll_Line) - (*Object\Segment()\Line_Start + *Object\Segment()\Line_Amount)
            *Nearest_Segment = *Object\Segment()
          EndIf
        EndIf
      EndIf
    Next
    
    If *Nearest_Segment
      Select Field
        Case 0 ; #### Hex
          If Set_Nibble
            Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object\X0 + Main\Font_Width * 1.0, Main\Font_Width * 3)
            If (Mouse_X - *Object\X0 - Main\Font_Width * 0.3 - Mouse_Byte * Main\Font_Width*3) > 0
              Nibble = #True
            Else
              Nibble = #False
            EndIf
          Else
            Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object\X0 + Main\Font_Width * 1.5, Main\Font_Width * 3)
          EndIf
        Case 1 ; #### Ascii
          Mouse_Byte = Quad_Divide_Floor(Mouse_X - *Object\X1 + Main\Font_Width * 0.5, Main\Font_Width)
      EndSelect
      
      If Mouse_Byte < 0
        Mouse_Byte = 0
        Nibble = #False
      EndIf
      If Mouse_Byte > *Object\Line_Bytes
        Mouse_Byte = *Object\Line_Bytes
        Nibble = #False
      EndIf
      
      If *Nearest_Segment\Collapsed
        Position = *Nearest_Segment\Start
      Else
        Position = *Nearest_Segment\Start - *Nearest_Segment\Start % *Object\Line_Bytes + Mouse_Byte + (Mouse_Line+*Object\Scroll_Line-*Nearest_Segment\Line_Start-1) * *Object\Line_Bytes
      EndIf
      
      If Position < *Nearest_Segment\Start
        Position = *Nearest_Segment\Start
        Nibble = #False
      EndIf
      If Position >= *Nearest_Segment\Start + *Nearest_Segment\Size ; #### it's really Greater or Equal because of the nibble state!
        Position = *Nearest_Segment\Start + *Nearest_Segment\Size
        Nibble = #False
      EndIf
      
      ; #### Set everything
      If Set_Start Or Set_End Or Set_Nibble
        Write_Nibble(*Node, 0, #True)
      EndIf
      If Set_Start
        Range_Set(*Node, Position, -1, -1, #False)
      EndIf
      If Set_End
        Range_Set(*Node, -1, Position, -1, #True)
      EndIf
      If Set_Nibble
        Range_Set(*Node, -1, -1, Nibble, #False)
      EndIf
    EndIf
    
    ProcedureReturn Position
  EndProcedure
  
  Procedure Window_Event_Canvas()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected M_X.l, M_Y.l
    Protected Key, Modifiers
    Protected i
    Protected Start.q, Length.q, Text.s, *Text.String, Hex_Elements.i
    Protected Select_Start.q, Select_Length.q
    Protected Char.a
    Protected Selection.q
    Protected Event.Node::Event
    
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
    
    Select Event_Type
      Case #PB_EventType_RightButtonDown
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        Modifiers = GetGadgetAttribute(Event_Gadget, #PB_Canvas_Modifiers)
        If M_X < *Object\X2 And M_Y > *Object\Y0
          If M_X < *Object\X1 - 5
            *Object\Select_Field = 0
          Else
            *Object\Select_Field = 1
          EndIf
          If *Object\Select_Start < *Object\Select_End
            Select_Start = *Object\Select_Start
            Select_Length = *Object\Select_End - *Object\Select_Start
          Else
            Select_Start = *Object\Select_End
            Select_Length = *Object\Select_Start - *Object\Select_End
          EndIf
          Selection = Canvas_Mouse_2_Position(*Node, M_X, M_Y, *Object\Select_Field, #False, #False, #False)
          If Select_Start > Selection Or Select_Start+Select_Length < Selection
            Range_Set(*Node, Selection, Selection, #False, #True)
          EndIf
        EndIf
        
      Case #PB_EventType_RightClick
        *Object\Menu_Object = *Node
        DisplayPopupMenu(Main\PopupMenu, WindowID(*Object\Window\ID))
        
      Case #PB_EventType_LeftButtonDown
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        Modifiers = GetGadgetAttribute(Event_Gadget, #PB_Canvas_Modifiers)
        If M_X < *Object\X2 And M_Y > *Object\Y0
          If M_X < *Object\X1 - 5
            *Object\Select_Field = 0
          Else
            *Object\Select_Field = 1
          EndIf
          If Modifiers & #PB_Canvas_Shift
            Canvas_Mouse_2_Position(*Node, M_X, M_Y, *Object\Select_Field, #False, #True, #False)
          Else
            Canvas_Mouse_2_Position(*Node, M_X, M_Y, *Object\Select_Field, #True, #True, #True)
          EndIf
          *Object\Select_Active = #True
        EndIf
        
      Case #PB_EventType_LeftButtonUp
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        If *Object\Select_Active
          Canvas_Mouse_2_Position(*Node, M_X, M_Y, *Object\Select_Field, #False, #True, *Object\Select_Nibble)
          *Object\Select_Active = #False
        EndIf
        
      Case #PB_EventType_MouseMove
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        If *Object\Select_Active
          Canvas_Mouse_2_Position(*Node, M_X, M_Y, *Object\Select_Field, #False, #True, *Object\Select_Nibble)
        EndIf
        ; #### Do cursor stuff
        If (M_X < *Object\X2 And M_Y > *Object\Y0) Or *Object\Select_Active
          SetGadgetAttribute(*Object\Canvas, #PB_Canvas_Cursor, #PB_Cursor_IBeam)
        Else
          SetGadgetAttribute(*Object\Canvas, #PB_Canvas_Cursor, #PB_Cursor_Default)
        EndIf
        
      Case #PB_EventType_MouseWheel
        *Object\Scroll_Line - GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta) * 3
        If *Object\Scroll_Line > *Object\Scroll_Lines - *Object\Lines + 1
          *Object\Scroll_Line = *Object\Scroll_Lines - *Object\Lines + 1
        EndIf
        If *Object\Scroll_Line < 0
          *Object\Scroll_Line = 0
        EndIf
        *Object\Redraw = #True
        
      Case #PB_EventType_Input
        If *Object\Select_Field = 1 ; #### Ascii
          Char = GetGadgetAttribute(*Object\Canvas, #PB_Canvas_Input)
          Write_Data(*Node, @Char, 1)
        EndIf
        
      Case #PB_EventType_Focus, #PB_EventType_LostFocus
        *Object\Redraw = #True
        
      Case #PB_EventType_KeyDown
        Key = GetGadgetAttribute(*Object\Canvas, #PB_Canvas_Key)
        Modifiers = GetGadgetAttribute(*Object\Canvas, #PB_Canvas_Modifiers)
        If *Object\Select_Field = 0 ; #### Hex
          Select Key
            Case #PB_Shortcut_0 To #PB_Shortcut_9, #PB_Shortcut_A To #PB_Shortcut_F, #PB_Shortcut_Pad0 To #PB_Shortcut_Pad9
              If Modifiers = 0
                If Key >= #PB_Shortcut_0 And Key <= #PB_Shortcut_9
                  Char = Key - #PB_Shortcut_0
                ElseIf Key >= #PB_Shortcut_Pad0 And Key <= #PB_Shortcut_Pad9
                  Char = Key - #PB_Shortcut_Pad0
                ElseIf Key >= #PB_Shortcut_A And Key <= #PB_Shortcut_F
                  Char = Key - #PB_Shortcut_A + 10
                EndIf
                Write_Nibble(*Node, Char)
              EndIf
          EndSelect
        EndIf
        Select Key
          Case #PB_Shortcut_Insert
            If *Object\Write_Mode = #WriteMode_Overwrite
              *Object\Write_Mode = #WriteMode_Insert
            Else
              *Object\Write_Mode = #WriteMode_Overwrite
            EndIf
            *Object\Redraw = #True
            
          Case #PB_Shortcut_Up
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End - *Object\Line_Bytes
            If *Object\Select_End < 0
              *Object\Select_End = 0
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            Else
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Control
              *Object\Select_Nibble = #False
            EndIf
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_Down
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End + *Object\Line_Bytes
            If *Object\Select_End > *Object\Data_Size
              *Object\Select_End = *Object\Data_Size
            EndIf
            If *Object\Select_End >= *Object\Data_Size
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            Else
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Control
              *Object\Select_Nibble = #False
            EndIf
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_Right
            Write_Nibble(*Node, 0, #True)
            If Modifiers & #PB_Canvas_Control
              If *Object\Select_Nibble
                *Object\Select_Nibble = #False
                *Object\Select_End + 1
              Else
                *Object\Select_Nibble = #True
              EndIf
            Else
              *Object\Select_End + 1
              *Object\Select_Nibble = #False
            EndIf
            If *Object\Select_End > *Object\Data_Size
              *Object\Select_End = *Object\Data_Size
            EndIf
            If *Object\Select_End >= *Object\Data_Size
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            Else
              *Object\Select_Nibble = #False
            EndIf
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_Left
            Write_Nibble(*Node, 0, #True)
            If Modifiers & #PB_Canvas_Control
              If *Object\Select_Nibble
                *Object\Select_Nibble = #False
              Else
                *Object\Select_Nibble = #True
                *Object\Select_End - 1
              EndIf
            Else
              If Not *Object\Select_Nibble
                *Object\Select_End - 1
              EndIf
              *Object\Select_Nibble = #False
            EndIf
            If *Object\Select_End < 0
              *Object\Select_End = 0
              *Object\Select_Nibble = #False
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            Else
              *Object\Select_Nibble = #False
            EndIf
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_Home
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End = 0
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            EndIf
            *Object\Select_Nibble = #False
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_End
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End = *Object\Data_Size
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            EndIf
            *Object\Select_Nibble = #False
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_PageUp
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End - *Object\Lines * *Object\Line_Bytes
            If *Object\Select_End < 0
              *Object\Select_End = 0
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            EndIf
            *Object\Select_Nibble = #False
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_PageDown
            Write_Nibble(*Node, 0, #True)
            *Object\Select_End + *Object\Lines * *Object\Line_Bytes
            If *Object\Select_End > *Object\Data_Size
              *Object\Select_End = *Object\Data_Size
            EndIf
            If Not Modifiers & #PB_Canvas_Shift
              *Object\Select_Start = *Object\Select_End
            EndIf
            *Object\Select_Nibble = #False
            Scroll_2_Cursor(*Node)
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_A
            If Modifiers & #PB_Canvas_Control
              Write_Nibble(*Node, 0, #True)
              *Object\Select_Start = 0
              *Object\Select_End = *Object\Data_Size
              *Object\Select_Nibble = #False
              *Object\Temp_Nibble = #False
            EndIf
            *Object\Redraw = #True
            ; #### Selection changed. Update selection-output
            Event\Type = Node::#Link_Event_Update
            Event\Position = 0
            Event\Size = 0
            Node::Output_Event(FirstElement(*Node\Output()), Event)
            
          Case #PB_Shortcut_Back
            Remove_Data(*Node, 1, #True)
            Scroll_2_Cursor(*Node)
            
          Case #PB_Shortcut_Delete
            Remove_Data(*Node, 1, #False)
            Scroll_2_Cursor(*Node)
            
        EndSelect
        
    EndSelect
    
  EndProcedure
  
  Procedure Window_Callback(hWnd, uMsg, wParam, lParam)
    Protected SCROLLINFO.SCROLLINFO
    
    Protected *Window.Window::Object = Window::Get_hWnd(hWnd)
    If Not *Window
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    Protected *Node.Node::Object = *Window\Node
    If Not *Node
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    If Not *Node\Type = Main\Node_Type
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    
    Select uMsg
      Case #WM_VSCROLL
        Select wParam & $FFFF
          Case #SB_THUMBTRACK
            SCROLLINFO\fMask = #SIF_TRACKPOS
            SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
            GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
            If SCROLLINFO\nTrackPos = *Object\Scroll_Lines / *Object\Scroll_Divider
              *Object\Scroll_Line = *Object\Scroll_Lines-*Object\Lines
            Else
              *Object\Scroll_Line = SCROLLINFO\nTrackPos * *Object\Scroll_Divider
            EndIf
            *Object\Redraw = #True
          Case #SB_PAGEUP
            *Object\Scroll_Line - *Object\Lines
            *Object\Redraw = #True
          Case #SB_PAGEDOWN
            *Object\Scroll_Line + *Object\Lines
            *Object\Redraw = #True
          Case #SB_LINEUP
            *Object\Scroll_Line - 1
            *Object\Redraw = #True
          Case #SB_LINEDOWN
            *Object\Scroll_Line + 1
            *Object\Redraw = #True
        EndSelect
        
        If *Object\Redraw
          *Object\Redraw = #False
          Organize(*Node)
          Get_Data(*Node)
          Canvas_Redraw(*Node)
          SetActiveGadget(*Object\Canvas)
        EndIf
        
    EndSelect
    
    
    
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected ToolBarHeight
    
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
    
    ToolBarHeight = ToolBarHeight(*Object\ToolBar)
    
    ResizeGadget(*Object\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-17, WindowHeight(Event_Window)-ToolBarHeight)
    ResizeGadget(*Object\ScrollBar, WindowWidth(Event_Window)-17, #PB_Ignore, 17, WindowHeight(Event_Window)-ToolBarHeight)
    
    Organize(*Node)
    Get_Data(*Node)
    Canvas_Redraw(*Node)
    Statusbar_Update(*Node)
  EndProcedure
  
  Procedure Window_Event_ActivateWindow()
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
    
    *Object\Redraw = #True
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
    
    Protected Event.Node::Event
    
    Select Event_Menu
      Case #Menu_Save
        Event\Type = Node::#Event_Save
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case #Menu_SaveAs
        Event\Type = Node::#Event_SaveAs
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case #Menu_Search
        Search_Window_Open(*Node)
        
      Case #Menu_Search_Continue
        Search_Continue(*Node)
        
      Case #Menu_Goto
        Goto_Window_Open(*Node)
        
      Case #Menu_Undo
        Event\Type = Node::#Event_Undo
        Event\Value[0] = #True ; Undo a shift and write operation at once
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case #Menu_Redo
        Event\Type = Node::#Event_Redo
        Event\Value[0] = #True ; Redo a shift and write operation at once
        Node::Input_Event(FirstElement(*Node\Input()), Event)
        
      Case #Menu_Cut, #PopupMenu_Cut
        Cut(*Node)
        
      Case #Menu_Copy, #PopupMenu_Copy
        Copy(*Node)
        
      Case #Menu_Paste, #PopupMenu_Paste
        Paste(*Node)
        
      Case #PopupMenu_Select_All
        *Object\Select_Start = 0
        *Object\Select_End = *Object\Data_Size
        *Object\Select_Nibble = #False
        *Object\Temp_Nibble = #False
        *Object\Redraw = #True
        ; #### Send an Update event to the selection-output
        Event\Type = Node::#Link_Event_Update
        Event\Position = 0
        Event\Size = *Object\Data_Size
        Node::Output_Event(FirstElement(*Node\Output()), Event)
        
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
    
    ;Window_Close(*Node)
    *Object\Window_Close = #True
  EndProcedure
  
  Procedure Window_Open(*Node.Node::Object)
    Protected ToolBarHeight
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window = #Null
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, #PB_Ignore, #PB_Ignore, 630, 650, Window::#Flag_Resizeable | Window::#Flag_Docked | Window::#Flag_MaximizeGadget, -10, Main\Node_Type\UID)
      
      ; #### Toolbar
      *Object\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object\Window\ID))
      ToolBarImageButton(#Menu_Search, ImageID(Icons::Icon_Search))
      ToolBarImageButton(#Menu_Search_Continue, ImageID(Icons::Icon_Search_Continue))
      ToolBarSeparator()
      ToolBarImageButton(#Menu_Cut, ImageID(Icons::Icon_Cut))
      ToolBarImageButton(#Menu_Copy, ImageID(Icons::Icon_Copy))
      ToolBarImageButton(#Menu_Paste, ImageID(Icons::Icon_Paste))
      ToolBarSeparator()
      ToolBarImageButton(#Menu_Goto, ImageID(Icons::Icon_Goto))
      ToolBarSeparator()
      ToolBarImageButton(#Menu_Undo, ImageID(Icons::Icon_Undo))
      ToolBarImageButton(#Menu_Redo, ImageID(Icons::Icon_Redo))
      
      ToolBarHeight = ToolBarHeight(*Object\ToolBar)
      
      *Object\Canvas = CanvasGadget(#PB_Any, 0, ToolBarHeight, 483, 500-ToolBarHeight, #PB_Canvas_Keyboard)
      *Object\ScrollBar = ScrollBarGadget(#PB_Any, 483, ToolBarHeight, 17, 500-ToolBarHeight, 0, 0, 0, #PB_ScrollBar_Vertical)
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\Canvas, @Window_Event_Canvas())
      
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_S, #Menu_Save, Main::#Menu_Save)
      Window::Set_KeyboardShortcut(*Object\Window, 0, #Menu_SaveAs, Main::#Menu_SaveAs)
      
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_F, #Menu_Search, Main::#Menu_Search)
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_F3, #Menu_Search_Continue, Main::#Menu_Search_Continue)
      
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_X, #Menu_Cut, Main::#Menu_Cut)
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_C, #Menu_Copy, Main::#Menu_Copy)
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_V, #Menu_Paste, Main::#Menu_Paste)
      
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_Z, #Menu_Undo, Main::#Menu_Undo)
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_Y, #Menu_Redo, Main::#Menu_Redo)
      
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_A, #PopupMenu_Select_All, Main::#Menu_Select_All)
      Window::Set_KeyboardShortcut(*Object\Window, #PB_Shortcut_Control | #PB_Shortcut_G, #Menu_Goto, Main::#Menu_Goto)
      
      D3docker::Window_Set_Callback(*Object\Window\ID, @Window_Callback())
      
      *Object\Redraw = #True
      
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
      
      UnbindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;UnbindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;UnbindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      UnbindGadgetEvent(*Object\Canvas, @Window_Event_Canvas())
      
      D3docker::Window_Set_Callback(*Object\Window\ID, #Null)
      
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
    
    Goto_Main(*Node)
    Search_Main(*Node)
    
    If *Object\Window
      If *Object\Redraw
        *Object\Redraw = #False
        Organize(*Node)
        Get_Data(*Node)
        Canvas_Redraw(*Node)
        Statusbar_Update(*Node)
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
    Main\Node_Type\Name = "Editor"
    Main\Node_Type\UID = "D3EDITOR"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,01,12,14,02,00)
    Main\Node_Type\Date_Modification = Date(2014,10,08,16,45,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Just a normal hex-editor."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 1200
  EndIf
  
  ; #### Object Popup-Menu
  Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
  MenuItem(#PopupMenu_Cut, "Cut", ImageID(Icons::Icon_Cut))
  MenuItem(#PopupMenu_Copy, "Copy", ImageID(Icons::Icon_Copy))
  MenuItem(#PopupMenu_Paste, "Paste", ImageID(Icons::Icon_Paste))
  MenuBar()
  MenuItem(#PopupMenu_Select_All, "Select All", ImageID(Icons::Icon_Select_All))
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 2366
; FirstLine = 2347
; Folding = --------
; EnableUnicode
; EnableXP