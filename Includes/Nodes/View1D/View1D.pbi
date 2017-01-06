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

DeclareModule _Node_View1D
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_View1D
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Macros ######################################################
  
  ; ################################################### Constants ###################################################
  
  Enumeration
    #Menu_Settings
    #Menu_X_Normalize
    #Menu_Y_Normalize
    #Menu_Y_Fit
    #Menu_Lines
  EndEnumeration
  
  #Canvas_X_Height = 100
  #Canvas_Y_Width = 100
  #ScrollBar_X_Height = 17
  
  ; ################################################### Structures ##################################################
  
  Structure RGB
    R.a
    G.a
    B.a
  EndStructure
  
  Structure Main
    *Node_Type.Node_Type::Object
    
    Font_ID.i
    Font_Width.l
    Font_Height.l
  EndStructure
  Global Main.Main
  
  Structure Input_Channel_Value
    Value.d
    Position.q
  EndStructure
  
  Structure Input_Channel
    ; #### Data-Array properties
    Manually.i
    
    ElementSize.i ; in Bytes
    ElementType.i
    
    Offset.q      ; in Bytes
    
    Color.l
    
    ; #### Temp Values
    List Value.Input_Channel_Value()
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ToolBar.i
    
    ; #### Gadget stuff
    Canvas_Y.i
    Canvas_X.i
    Canvas_Data.i
    
    Redraw.l
    
    ScrollBar_X.i
    
    Offset_X.d
    Offset_Y.d
    Zoom_X.d
    Zoom_Y.d
    
    Position_Min.d      ; Position of the most left data-point
    Position_Max.d      ; Position of the most right data-point
    
    Connect.i       ; #True: Connect the data points with lines
    
    ; #### Other Windows
    *Settings_Window.Settings_Window
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Fonts #######################################################
  
  Main\Font_ID = LoadFont(#PB_Any, "Courier New", 8)
  Define Temp_Image = CreateImage(#PB_Any, 1, 1)
  If StartDrawing(ImageOutput(Temp_Image))
    DrawingFont(FontID(Main\Font_ID))
    Main\Font_Width = TextWidth("0")
    Main\Font_Height = TextHeight("0")
    StopDrawing()
  EndIf
  FreeImage(Temp_Image)
  
  ; ################################################### Icons ... ###################################################
  
  Global Icon_Dots = CatchImage(#PB_Any, ?Icon_Dots)
  Global Icon_Lines = CatchImage(#PB_Any, ?Icon_Lines)
  Global Icon_Fit_Y = CatchImage(#PB_Any, ?Icon_Fit_Y)
  Global Icon_Normalize_X = CatchImage(#PB_Any, ?Icon_Normalize_X)
  Global Icon_Normalize_Y = CatchImage(#PB_Any, ?Icon_Normalize_Y)
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Includes ####################################################
  
  XIncludeFile "View1D_Settings.pbi"
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input.Node::Conn_Input
    
    If Not *Node
      ProcedureReturn #Null
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
    *Node\Color = RGBA(200, 127, 127, 255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    *Object\Settings_Window = AllocateStructure(Settings_Window)
    
    *Object\Zoom_X = 1
    *Object\Zoom_Y = 1
    
    ; #### Add Input
    *Input = Node::Input_Add(*Node)
    *Input\Custom_Data = AllocateStructure(Input_Channel)
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
    Settings_Window_Close(*Node)
    
    ForEach *Node\Input()
      If *Node\Input()\Custom_Data
        FreeStructure(*Node\Input()\Custom_Data)
        *Node\Input()\Custom_Data = #Null
      EndIf
    Next
    
    FreeStructure(*Object\Settings_Window)
    *Object\Settings_Window = #Null
    
    FreeStructure(*Object)
    *Node\Custom_Data = #Null
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
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
    
    Protected *NBT_Tag.NBT::Tag
    Protected *NBT_Tag_List.NBT::Tag
    Protected *NBT_Tag_Compound.NBT::Tag
    Protected *Input_Channel.Input_Channel
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Offset_X", NBT::#Tag_Double)  : NBT::Tag_Set_Double(*NBT_Tag, *Object\Offset_X)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Offset_Y", NBT::#Tag_Double)  : NBT::Tag_Set_Double(*NBT_Tag, *Object\Offset_Y)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Zoom_X", NBT::#Tag_Double)    : NBT::Tag_Set_Double(*NBT_Tag, *Object\Zoom_X)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Zoom_Y", NBT::#Tag_Double)    : NBT::Tag_Set_Double(*NBT_Tag, *Object\Zoom_Y)
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Connect", NBT::#Tag_Byte)     : NBT::Tag_Set_Number(*NBT_Tag, *Object\Connect)
    
    *NBT_Tag_List = NBT::Tag_Add(*Parent_Tag, "Inputs", NBT::#Tag_List, NBT::#Tag_Compound)
    If *NBT_Tag_List
      ForEach *Node\Input()
        *Input_Channel = *Node\Input()\Custom_Data
        
        *NBT_Tag_Compound = NBT::Tag_Add(*NBT_Tag_List, "", NBT::#Tag_Compound)
        If *NBT_Tag_Compound
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "ElementType", NBT::#Tag_Long) : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\ElementType)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "ElementSize", NBT::#Tag_Long) : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\ElementSize)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Manually", NBT::#Tag_Long)    : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Manually)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Offset", NBT::#Tag_Quad)      : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Offset)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Color", NBT::#Tag_Long)       : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Color)
        EndIf
      Next
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
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
    
    Protected *NBT_Tag.NBT::Tag
    Protected *NBT_Tag_List.NBT::Tag
    Protected *NBT_Tag_Compound.NBT::Tag
    Protected *Input_Channel.Input_Channel
    Protected *Input.Node::Conn_Input
    Protected Elements, i
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Offset_X") : *Object\Offset_X = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Offset_Y") : *Object\Offset_Y = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Zoom_X")   : *Object\Zoom_X = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Zoom_Y")   : *Object\Zoom_Y = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Connect")  : *Object\Connect = NBT::Tag_Get_Number(*NBT_Tag)
    
    ; #### Delete all inputs
    While FirstElement(*Node\Input())
      If *Node\Input()\Custom_Data
        FreeStructure(*Node\Input()\Custom_Data)
        *Node\Input()\Custom_Data = #Null
      EndIf
      Node::Input_Delete(*Node, *Node\Input())
    Wend
    
    *NBT_Tag_List = NBT::Tag(*Parent_Tag, "Inputs")
    If *NBT_Tag_List
      Elements = NBT::Tag_Count(*NBT_Tag_List)
      
      For i = 0 To Elements-1
        *NBT_Tag_Compound = NBT::Tag_Index(*NBT_Tag_List, i)
        If *NBT_Tag_Compound
          
          ; #### Add Input
          *Input = Node::Input_Add(*Node)
          *Input\Custom_Data = AllocateStructure(Input_Channel)
          *Input\Function_Event = @Input_Event()
          *Input_Channel = *Input\Custom_Data
          If *Input_Channel
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "ElementType") : *Input_Channel\ElementType = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "ElementSize") : *Input_Channel\ElementSize = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Manually")    : *Input_Channel\Manually = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Offset")      : *Input_Channel\Offset = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Color")       : *Input_Channel\Color = NBT::Tag_Get_Number(*NBT_Tag)
          EndIf
          
        EndIf
      Next
      
    EndIf
    
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
    
    Select *Event\Type
      
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
    Protected *Object.Object = *Input\Object\Custom_Data
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
        *Object\Redraw = #True
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Organize(*Node.Node::Object)
    Protected *Input_Channel.Input_Channel
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\Position_Min = Infinity()
    *Object\Position_Max = -Infinity()
    
    ; #### Limit Zoom in X
    If *Object\Zoom_X < 0.0001
      *Object\Zoom_X = 0.0001
    EndIf
    
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        ; #### Get the settings from the data descriptor of the output
        If Not *Input_Channel\Manually
          ; TODO: Get settings from data-descriptor
          *Input_Channel\ElementType = #Integer_U_8
        EndIf
        
        ; #### Set ElementSize
        Select *Input_Channel\ElementType
          Case #Integer_U_8   : *Input_Channel\ElementSize = 1
          Case #Integer_S_8   : *Input_Channel\ElementSize = 1
          Case #Integer_U_16  : *Input_Channel\ElementSize = 2
          Case #Integer_S_16  : *Input_Channel\ElementSize = 2
          Case #Integer_U_32  : *Input_Channel\ElementSize = 4
          Case #Integer_S_32  : *Input_Channel\ElementSize = 4
          Case #Integer_U_64  : *Input_Channel\ElementSize = 8
          Case #Integer_S_64  : *Input_Channel\ElementSize = 8
          Case #Float_32      : *Input_Channel\ElementSize = 4
          Case #Float_64      : *Input_Channel\ElementSize = 8
        EndSelect
        
        ; #### Get range of all points
        If *Input_Channel\ElementSize > 0
          If *Object\Position_Min > *Input_Channel\Offset / *Input_Channel\ElementSize
            *Object\Position_Min = *Input_Channel\Offset / *Input_Channel\ElementSize
          EndIf
          If *Object\Position_Max < (*Input_Channel\Offset + Node::Input_Get_Size(*Node\Input())) / *Input_Channel\ElementSize
            *Object\Position_Max = (*Input_Channel\Offset + Node::Input_Get_Size(*Node\Input())) / *Input_Channel\ElementSize
          EndIf
        EndIf
      EndIf
    Next
    
    ; #### Window values
    Protected Width = GadgetWidth(*Object\Canvas_Data)
    Protected Height = GadgetHeight(*Object\Canvas_Data)
    
    
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_Maximum, *Object\Position_Max * *Object\Zoom_X)
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_Minimum, *Object\Position_Min * *Object\Zoom_X)
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_PageLength, Width)
    SetGadgetState(*Object\ScrollBar_X, -*Object\Offset_X)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Data(*Node.Node::Object)
    Protected *Temp, Temp_Size.q, Elements.q, Temp_Start.q, Difference.q
    Protected Width
    Protected *Input_Channel.Input_Channel
    Protected Temp_Value.q, Temp_Value_2.q
    Protected i
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Width = GadgetWidth(*Object\Canvas_Data)
    
    ; #### Go throught each input
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        
        ClearList(*Input_Channel\Value())
        
        Elements = Width / *Object\Zoom_X + 3
        Temp_Size = Elements * *Input_Channel\ElementSize
        
        Temp_Start = (-*Object\Offset_X / *Object\Zoom_X) - 1
        Temp_Start * *Input_Channel\ElementSize
        Temp_Start - *Input_Channel\Offset
        If Temp_Start < 0
          Difference = Quad_Divide_Floor(Temp_Start, *Input_Channel\ElementSize) * *Input_Channel\ElementSize
          Temp_Size + Difference
          Elements = Temp_Size / *Input_Channel\ElementSize
          Temp_Start - Difference
        EndIf
        
        If Temp_Start + Temp_Size > Node::Input_Get_Size(*Node\Input())
          Temp_Size = Node::Input_Get_Size(*Node\Input()) - Temp_Start
          Elements = Temp_Size / *Input_Channel\ElementSize
        EndIf
        If Temp_Size > 0
          *Temp = AllocateMemory(Temp_Size)
          If *Temp
            Node::Input_Get_Data(*Node\Input(), Temp_Start, Temp_Size, *Temp, #Null)
            For i = 0 To Elements-1
              AddElement(*Input_Channel\Value())
              *Input_Channel\Value()\Position = (Temp_Start + *Input_Channel\Offset) / *Input_Channel\ElementSize + i
              Select *Input_Channel\ElementType
                Case #Integer_U_8   : *Input_Channel\Value()\Value = PeekA(*Temp+i)
                Case #Integer_S_8   : *Input_Channel\Value()\Value = PeekB(*Temp+i)
                Case #Integer_U_16  : *Input_Channel\Value()\Value = PeekU(*Temp+i*2)
                Case #Integer_S_16  : *Input_Channel\Value()\Value = PeekW(*Temp+i*2)
                Case #Integer_U_32
                  Temp_Value = PeekL(*Temp+i*4)
                  Temp_Value_2 = Temp_Value & $7FFFFFFF
                  If Temp_Value & $80000000
                    *Input_Channel\Value()\Value = Temp_Value_2 + 2147483648.0
                  Else
                    *Input_Channel\Value()\Value = Temp_Value_2
                  EndIf
                Case #Integer_S_32  : *Input_Channel\Value()\Value = PeekL(*Temp+i*4)
                Case #Integer_U_64
                  Temp_Value = PeekQ(*Temp+i*8)
                  Temp_Value_2 = Temp_Value & $7FFFFFFFFFFFFFFF
                  If Temp_Value & $8000000000000000
                    *Input_Channel\Value()\Value = Temp_Value_2 + 9223372036854775807.0 ; #### 9223372036854775808.0 (The correct value) somehow gets casted to a quad and will result in -1
                  Else
                    *Input_Channel\Value()\Value = Temp_Value_2
                  EndIf
                Case #Integer_S_64  : *Input_Channel\Value()\Value = PeekQ(*Temp+i*8)
                Case #Float_32      : *Input_Channel\Value()\Value = PeekF(*Temp+i*4)
                Case #Float_64      : *Input_Channel\Value()\Value = PeekD(*Temp+i*8)
              EndSelect
            Next
            FreeMemory(*Temp)
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
    Protected Width, Height
    Protected X_M.d, Y_M.d, X_M_O.d, Y_M_O.d, First
    Protected X_R.d, Y_R.d
    Protected i, ix, iy
    Protected *Input_Channel.Input_Channel
    Protected Division_Size_X.d, Division_Size_Y.d, Divisions_X.q, Divisions_Y.q
    Protected Text.s, Text_Width, Text_Height
    Protected *Color_Temp.RGB
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### X Canvas
    Width = GadgetWidth(*Object\Canvas_X)
    Height = GadgetHeight(*Object\Canvas_X)
    If Not StartDrawing(CanvasOutput(*Object\Canvas_X))
      ProcedureReturn #False
    EndIf
    
    Box(0, 0, Width, Height, GetSysColor_(#COLOR_BTNFACE))
    
    DrawingFont(FontID(Main\Font_ID))
    
    DrawingMode(#PB_2DDrawing_Transparent)
    
    FrontColor(RGB(0,0,255))
    BackColor(RGB(255,255,255))
    
    ; #### Draw Grid
    Division_Size_X = Pow(10,Round(Log10(1 / *Object\Zoom_X),#PB_Round_Up))*20
    Divisions_X = Round((Width + 100) / *Object\Zoom_X, #PB_Round_Up) / Division_Size_X
    For ix = -1 To Divisions_X
      X_M = ix * Division_Size_X * *Object\Zoom_X + *Object\Offset_X - Round(*Object\Offset_X / (Division_Size_X * *Object\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object\Zoom_X) + #Canvas_Y_Width
      X_R = (X_M - #Canvas_Y_Width - *Object\Offset_X) / *Object\Zoom_X
      Text = LSet(RTrim(RTrim(StrD(X_R,3), "0"), "."), 13)
      Text_Width = TextWidth(Text)
      Text_Height = TextHeight(Text)
      DrawRotatedText(X_M-0.9*Text_Width-0.9*Text_Height, 0.9*Text_Width-0.9*Text_Height, Text, 45)
      LineXY(X_M, 0, X_M-80, 80)
    Next
    
    StopDrawing()
    
    ; #### Y Canvas
    Width = GadgetWidth(*Object\Canvas_Y)
    Height = GadgetHeight(*Object\Canvas_Y)
    If Not StartDrawing(CanvasOutput(*Object\Canvas_Y))
      ProcedureReturn #False
    EndIf
    
    Box(0, 0, Width, Height, GetSysColor_(#COLOR_BTNFACE))
    
    DrawingFont(FontID(Main\Font_ID))
    
    DrawingMode(#PB_2DDrawing_Transparent)
    
    FrontColor(RGB(0,0,255))
    BackColor(RGB(255,255,255))
    
    ; #### Draw Grid
    Division_Size_Y = Pow(10,Round(Log10(1 / *Object\Zoom_Y),#PB_Round_Up))*20
    Divisions_Y = Round(Height / *Object\Zoom_Y, #PB_Round_Up) / Division_Size_Y
    For iy = -Divisions_Y/2-1 To Divisions_Y/2
      Y_M = iy * Division_Size_Y * *Object\Zoom_Y + Height/2 + *Object\Offset_Y - Round(*Object\Offset_Y / (Division_Size_Y * *Object\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object\Zoom_Y)
      Y_R = (Height/2 + *Object\Offset_Y - Y_M) / *Object\Zoom_Y
      Text = LSet(RTrim(RTrim(StrD(Y_R,3), "0"), "."), 13)
      Text_Width = TextWidth(Text)
      Text_Height = TextHeight(Text)
      DrawText(Width - Text_Width, Y_M-Text_Height, Text)
      LineXY(Width-100, Y_M, Width, Y_M)
    Next
    
    StopDrawing()
    
    ; #### Data Canvas
    Width = GadgetWidth(*Object\Canvas_Data)
    Height = GadgetHeight(*Object\Canvas_Data)
    If Not StartDrawing(CanvasOutput(*Object\Canvas_Data))
      ProcedureReturn #False
    EndIf
    
    Box(0, 0, Width, Height, RGB(255,255,255))
    
    DrawingFont(FontID(Main\Font_ID))
    
    FrontColor(RGB(0,0,255))
    BackColor(RGB(255,255,255))
    
    ; #### Draw Grid
    Division_Size_X = Pow(10,Round(Log10(1 / *Object\Zoom_X),#PB_Round_Up))*20
    Division_Size_Y = Pow(10,Round(Log10(1 / *Object\Zoom_Y),#PB_Round_Up))*20
    Divisions_X = Round(Width / *Object\Zoom_X, #PB_Round_Up) / Division_Size_X
    Divisions_Y = Round(Height / *Object\Zoom_Y, #PB_Round_Up) / Division_Size_Y
    For ix = 0 To Divisions_X
      X_M = ix * Division_Size_X * *Object\Zoom_X + *Object\Offset_X - Round(*Object\Offset_X / (Division_Size_X * *Object\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object\Zoom_X)
      Line(X_M, 0, 0, Height, RGB(230,230,230))
    Next
    For iy = -Divisions_Y/2-1 To Divisions_Y/2
      Y_M = iy * Division_Size_Y * *Object\Zoom_Y + Height/2 + *Object\Offset_Y - Round(*Object\Offset_Y / (Division_Size_Y * *Object\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object\Zoom_Y)
      Line(0, Y_M, Width, 0, RGB(230,230,230))
    Next
    Line(0, *Object\Offset_Y + Height/2, Width, 0, RGB(180,180,180))
    Line(*Object\Offset_X, 0, 0, Height, RGB(180,180,180))
    
    ; #### Go throught each input
    ;Protected *Buffer     = DrawingBuffer()             ; Get the start address of the screen buffer
    ;Protected Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        If *Object\Connect
          First = #True
          ForEach *Input_Channel\Value()
            X_M = *Input_Channel\Value()\Position * *Object\Zoom_X + *Object\Offset_X
            Y_M = Height/2 - *Input_Channel\Value()\Value * *Object\Zoom_Y + *Object\Offset_Y
            
            ; #### Limit Y_M to a reasonable range
            If Y_M > 100000 : Y_M = 100000 : EndIf
            If Y_M < -100000 : Y_M = -100000 : EndIf
            
            If Not First
              LineXY(X_M, Y_M, X_M_O, Y_M_O, *Input_Channel\Color)
            Else
              First = #False
            EndIf
            
            X_M_O = X_M
            Y_M_O = Y_M
          Next
        Else
          ForEach *Input_Channel\Value()
            X_M = *Input_Channel\Value()\Position * *Object\Zoom_X + *Object\Offset_X
            Y_M = Height/2 - *Input_Channel\Value()\Value * *Object\Zoom_Y + *Object\Offset_Y
            ;Circle(X_M, Y_M, 0, RGB(0,0,0))
            If Int(X_M) >= 0 And Int(X_M) < Width And Int(Y_M) >= 0 And Int(Y_M) < Height
              ;*Color_Temp = *Buffer + Int(X_M)*3 + Int(Height-1-Y_M) * Pitch
              ;*Color_Temp\R = 0
              ;*Color_Temp\G = 0
              ;*Color_Temp\B = 0
              Plot(Int(X_M), Int(Y_M), *Input_Channel\Color)
            EndIf
          Next
        EndIf
      EndIf
    Next
    
    StopDrawing()
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Event_Canvas_Data()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected M_X.l, M_Y.l
    Protected Key, Modifiers
    Protected Temp_Zoom.d
    Protected i
    Static Move_Active
    Static Move_X, Move_Y
    
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
      Case #PB_EventType_RightClick
        ;*Object\Menu_Object = *Node
        ;DisplayPopupMenu(Main\PopupMenu, WindowID(*Object\Window\ID))
        
      Case #PB_EventType_RightButtonDown
        Move_Active = #True
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        
      Case #PB_EventType_RightButtonUp
        Move_Active = #False
        
      Case #PB_EventType_LeftButtonDown
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        Modifiers = GetGadgetAttribute(Event_Gadget, #PB_Canvas_Modifiers)
        *Object\Redraw = #True
        
      Case #PB_EventType_LeftButtonUp
        M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        *Object\Redraw = #True
        
      Case #PB_EventType_MouseMove
        If Move_Active
          *Object\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
          *Object\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
          Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
          Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
          *Object\Redraw = #True
        EndIf
        
      Case #PB_EventType_MouseWheel
        Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
        ;If *Object\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
        ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object\Zoom_X
        ;EndIf
        ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
        ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
        ;EndIf
        ;If *Object\Zoom_X * Temp_Zoom > 1
        ;  Temp_Zoom = 1 / *Object\Zoom_X
        ;EndIf
        *Object\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object\Offset_X)
        *Object\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object\Offset_Y)
        *Object\Zoom_X * Temp_Zoom
        *Object\Zoom_Y * Temp_Zoom
        
        *Object\Redraw = #True
        
      Case #PB_EventType_KeyDown
        Key = GetGadgetAttribute(*Object\Canvas_Data, #PB_Canvas_Key)
        Modifiers = GetGadgetAttribute(*Object\Canvas_Data, #PB_Canvas_Modifiers)
        Select Key
          Case #PB_Shortcut_Insert
            
          Case #PB_Shortcut_Right
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_Left
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_Home
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_End
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_PageUp
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_PageDown
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_A
            ;*Object\Redraw = #True
            
          Case #PB_Shortcut_C
            
          Case #PB_Shortcut_V
            
          Case #PB_Shortcut_Back
            
          Case #PB_Shortcut_Delete
            
        EndSelect
        
    EndSelect
    
  EndProcedure
  
  Procedure Window_Event_Canvas_X()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected M_X.l, M_Y.l
    Protected Key, Modifiers
    Protected Temp_Zoom.d
    Protected i
    Static Move_Active
    Static Move_X, Move_Y
    
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
        Move_Active = #True
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        
      Case #PB_EventType_RightButtonUp
        Move_Active = #False
        
      Case #PB_EventType_MouseMove
        If Move_Active
          *Object\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
          ;*Object\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
          Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
          Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
          *Object\Redraw = #True
        EndIf
        
      Case #PB_EventType_MouseWheel
        Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
        ;If *Object\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
        ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object\Zoom_X
        ;EndIf
        ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
        ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
        ;EndIf
        ;If *Object\Zoom_X * Temp_Zoom > 1
        ;  Temp_Zoom = 1 / *Object\Zoom_X
        ;EndIf
        *Object\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - #Canvas_Y_Width - *Object\Offset_X)
        ;*Object\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object\Offset_Y)
        *Object\Zoom_X * Temp_Zoom
        ;*Object\Zoom_Y * Temp_Zoom
        
        *Object\Redraw = #True
        
    EndSelect
    
  EndProcedure
  
  Procedure Window_Event_Canvas_Y()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected M_X.l, M_Y.l
    Protected Key, Modifiers
    Protected Temp_Zoom.d
    Protected i
    Static Move_Active
    Static Move_X, Move_Y
    
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
        Move_Active = #True
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        
      Case #PB_EventType_RightButtonUp
        Move_Active = #False
        
      Case #PB_EventType_MouseMove
        If Move_Active
          ;*Object\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
          *Object\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
          Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
          Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
          *Object\Redraw = #True
        EndIf
        
      Case #PB_EventType_MouseWheel
        Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
        ;If *Object\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
        ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object\Zoom_X
        ;EndIf
        ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
        ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
        ;EndIf
        ;If *Object\Zoom_X * Temp_Zoom > 1
        ;  Temp_Zoom = 1 / *Object\Zoom_X
        ;EndIf
        ;*Object\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object\Offset_X)
        *Object\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object\Offset_Y)
        ;*Object\Zoom_X * Temp_Zoom
        *Object\Zoom_Y * Temp_Zoom
        
        *Object\Redraw = #True
        
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
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    
    Select uMsg
      Case #WM_HSCROLL
        Select wParam & $FFFF
          Case #SB_THUMBTRACK
            SCROLLINFO\fMask = #SIF_TRACKPOS
            SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
            GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
            *Object\Offset_X = - SCROLLINFO\nTrackPos
            *Object\Redraw = #True
          Case #SB_PAGEUP
            *Object\Offset_X + GadgetWidth(*Object\Canvas_Data)
            *Object\Redraw = #True
          Case #SB_PAGEDOWN
            *Object\Offset_X - GadgetWidth(*Object\Canvas_Data)
            *Object\Redraw = #True
          Case #SB_LINEUP
            *Object\Offset_X + 100
            *Object\Redraw = #True
          Case #SB_LINEDOWN
            *Object\Offset_X - 100
            *Object\Redraw = #True
        EndSelect
        If *Object\Redraw
          *Object\Redraw = #False
          Organize(*Node)
          Get_Data(*Node)
          Canvas_Redraw(*Node)
          If GetActiveGadget() <> *Object\Canvas_Data And GetActiveGadget() <> *Object\Canvas_X And GetActiveGadget() <> *Object\Canvas_Y
            SetActiveGadget(*Object\Canvas_X)
          EndIf
        EndIf
        
    EndSelect
    
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
    Protected Width, Height, Data_Width, Data_Height, ToolBarHeight
    
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
    
    Width = WindowWidth(Event_Window)
    Height = WindowHeight(Event_Window)
    
    ToolBarHeight = ToolBarHeight(*Object\ToolBar)
    
    Data_Width = Width - #Canvas_Y_Width
    Data_Height = Height - #ScrollBar_X_Height - #Canvas_X_Height - ToolBarHeight
    
    ; #### Gadgets
    ResizeGadget(*Object\ScrollBar_X, 0, Height-#ScrollBar_X_Height, Data_Width+#Canvas_Y_Width, #ScrollBar_X_Height)
    
    ResizeGadget(*Object\Canvas_X, 0, ToolBarHeight+Data_Height, Data_Width+#Canvas_Y_Width, #Canvas_X_Height)
    ResizeGadget(*Object\Canvas_Y, 0, ToolBarHeight, #Canvas_Y_Width, Data_Height)
    ResizeGadget(*Object\Canvas_Data, #Canvas_Y_Width, ToolBarHeight, Data_Width, Data_Height)
    
    Organize(*Node)
    Get_Data(*Node)
    Canvas_Redraw(*Node)
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
    
    Protected *Input_Channel.Input_Channel
    Protected Max.d, Min.d
    
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
      Case #Menu_Settings
        Settings_Window_Open(*Node)
        
      Case #Menu_X_Normalize
        *Object\Offset_X - (1.0/*Object\Zoom_X - 1) * ( - *Object\Offset_X)
        *Object\Zoom_X = 1
        *Object\Redraw = #True
        
      Case #Menu_Y_Normalize
        *Object\Zoom_Y = 1
        *Object\Redraw = #True
        
      Case #Menu_Y_Fit
        Max = -Infinity()
        Min = Infinity()
        ForEach *Node\Input()
          *Input_Channel = *Node\Input()\Custom_Data
          If *Input_Channel
            ForEach *Input_Channel\Value()
              If Max < *Input_Channel\Value()\Value
                Max = *Input_Channel\Value()\Value
              EndIf
              If Min > *Input_Channel\Value()\Value
                Min = *Input_Channel\Value()\Value
              EndIf
            Next
          EndIf
        Next
        If Max - Min > 0.1
          *Object\Zoom_Y = GadgetHeight(*Object\Canvas_Data) / (Max - Min)
          *Object\Offset_Y = (Max + Min) / 2 * *Object\Zoom_Y
          *Object\Redraw = #True
        EndIf
        
      Case #Menu_Lines
        *Object\Connect = GetToolBarButtonState(*Object\ToolBar, #Menu_Lines)
        *Object\Redraw = #True
        
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
    Protected Width, Height, Data_Width, Data_Height, ToolBarHeight
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window = #Null
      
      Width = 500
      Height = 300
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, #PB_Ignore, #PB_Ignore, Width, Height, Window::#Flag_Resizeable | Window::#Flag_Docked | Window::#Flag_MaximizeGadget, 10, Main\Node_Type\UID)
      
      ; #### Toolbar
      *Object\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object\Window\ID))
      ToolBarImageButton(#Menu_Settings, ImageID(Icons::Icon_Gear))
      ToolBarImageButton(#Menu_X_Normalize, ImageID(Icon_Normalize_X))
      ToolBarImageButton(#Menu_Y_Normalize, ImageID(Icon_Normalize_Y))
      ToolBarImageButton(#Menu_Y_Fit, ImageID(Icon_Fit_Y))
      ToolBarImageButton(#Menu_Lines, ImageID(Icon_Lines), #PB_ToolBar_Toggle)
      SetToolBarButtonState(*Object\ToolBar, #Menu_Lines, *Object\Connect)
      
      ToolBarToolTip(*Object\ToolBar, #Menu_Settings, "Settings")
      ToolBarToolTip(*Object\ToolBar, #Menu_X_Normalize, "Normalize X")
      ToolBarToolTip(*Object\ToolBar, #Menu_Y_Normalize, "Normalize Y")
      ToolBarToolTip(*Object\ToolBar, #Menu_Y_Fit, "Fit vertically")
      ToolBarToolTip(*Object\ToolBar, #Menu_Lines, "Toggle lines")
      
      ToolBarHeight = ToolBarHeight(*Object\ToolBar)
      
      Data_Width = Width - #Canvas_Y_Width
      Data_Height = Height - #ScrollBar_X_Height - #Canvas_X_Height - ToolBarHeight
      
      ; #### Gadgets
      *Object\ScrollBar_X = ScrollBarGadget(#PB_Any, 0, Height-#ScrollBar_X_Height, Data_Width+#Canvas_Y_Width, #ScrollBar_X_Height, 0, 10, 1)
      
      *Object\Canvas_X = CanvasGadget(#PB_Any, 0, ToolBarHeight+Data_Height, Data_Width+#Canvas_Y_Width, #Canvas_X_Height, #PB_Canvas_Keyboard | #PB_Canvas_DrawFocus)
      *Object\Canvas_Y = CanvasGadget(#PB_Any, 0, ToolBarHeight, #Canvas_Y_Width, Data_Height, #PB_Canvas_Keyboard | #PB_Canvas_DrawFocus)
      *Object\Canvas_Data = CanvasGadget(#PB_Any, #Canvas_Y_Width, ToolBarHeight, Data_Width, Data_Height, #PB_Canvas_Keyboard)
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_ActivateWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\Canvas_Data, @Window_Event_Canvas_Data())
      BindGadgetEvent(*Object\Canvas_X, @Window_Event_Canvas_X())
      BindGadgetEvent(*Object\Canvas_Y, @Window_Event_Canvas_Y())
      
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
      UnbindGadgetEvent(*Object\Canvas_Data, @Window_Event_Canvas_Data())
      UnbindGadgetEvent(*Object\Canvas_X, @Window_Event_Canvas_X())
      UnbindGadgetEvent(*Object\Canvas_Y, @Window_Event_Canvas_Y())
      
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
    
    If *Object\Window
      If *Object\Redraw
        *Object\Redraw = #False
        Organize(*Node)
        Get_Data(*Node)
        Canvas_Redraw(*Node)
      EndIf
    EndIf
    
    Settings_Main(*Node)
    
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
    Main\Node_Type\Name = "View1D"
    Main\Node_Type\UID = "D3VIEW1D"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,01,28,14,42,00)
    Main\Node_Type\Date_Modification = Date(2014,01,28,14,42,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Just a normal Graph viewer."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 0900
  EndIf
  
  ; #### Object Popup-Menu
  ;Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
  ;MenuItem(#PopupMenu_Cut, "Cut")
  ;MenuItem(#PopupMenu_Copy, "Copy")
  ;MenuItem(#PopupMenu_Paste, "Paste")
  ;MenuBar()
  ;MenuItem(#PopupMenu_Close, "Close")
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
  ; ################################################### Data Sections ###############################################
  
  DataSection
    Icon_Dots:        : IncludeBinary "../../../Data/Icons/Graph_Dots.png"
    Icon_Lines:       : IncludeBinary "../../../Data/Icons/Graph_Lines.png"
    Icon_Fit_Y:       : IncludeBinary "../../../Data/Icons/Graph_Fit_Y.png"
    Icon_Normalize_X: : IncludeBinary "../../../Data/Icons/Graph_Normalize_X.png"
    Icon_Normalize_Y: : IncludeBinary "../../../Data/Icons/Graph_Normalize_Y.png"
  EndDataSection
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 541
; FirstLine = 529
; Folding = ----
; EnableXP