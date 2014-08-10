
; ##################################################### Dokumentation / Kommentare ##################################
; 
; 
; 
; 
; 
; 
; 

; ##################################################### Prototypes ##################################################

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

Enumeration
  #Object_View1D_Menu_Settings
  #Object_View1D_Menu_X_Normalize
  #Object_View1D_Menu_Y_Normalize
  #Object_View1D_Menu_Y_Fit
  #Object_View1D_Menu_Lines
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_View1D_RGB
  R.a
  G.a
  B.a
EndStructure

Structure Object_View1D_Main
  *Object_Type.Object_Type
  
  Font_ID.i
  Font_Width.l
  Font_Height.l
EndStructure
Global Object_View1D_Main.Object_View1D_Main

Structure Object_View1D_Input_Value
  Value.d
  Position.q
EndStructure

Structure Object_View1D_Input
  ; #### Data-Array properties
  Manually.i
  
  ElementSize.i ; in Bytes
  ElementType.i
  
  Offset.q      ; in Bytes
  
  Color.l
  
  ; #### Temp Values
  List Value.Object_View1D_Input_Value()
EndStructure

Structure Object_View1D
  *Window.Window
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
  
  Elements.q      ; Amount of Elements
  
  Connect.i       ; #True: Connect the data points with lines
  
  ; #### Other Windows
  *Settings.Object_View1D_Settings
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

Object_View1D_Main\Font_ID = LoadFont(#PB_Any, "Courier New", 8)
Define Temp_Image = CreateImage(#PB_Any, 1, 1)
If StartDrawing(ImageOutput(Temp_Image))
  DrawingFont(FontID(Object_View1D_Main\Font_ID))
  Object_View1D_Main\Font_Width = TextWidth("0")
  Object_View1D_Main\Font_Height = TextHeight("0")
  StopDrawing()
EndIf
FreeImage(Temp_Image)

; ##################################################### Icons ... ###################################################

Global Object_View1D_Icon_Dots = CatchImage(#PB_Any, ?Object_View1D_Icon_Dots)
Global Object_View1D_Icon_Lines = CatchImage(#PB_Any, ?Object_View1D_Icon_Lines)
Global Object_View1D_Icon_Fit_Y = CatchImage(#PB_Any, ?Object_View1D_Icon_Fit_Y)
Global Object_View1D_Icon_Normalize_X = CatchImage(#PB_Any, ?Object_View1D_Icon_Normalize_X)
Global Object_View1D_Icon_Normalize_Y = CatchImage(#PB_Any, ?Object_View1D_Icon_Normalize_Y)

; ##################################################### Declares ####################################################

Declare   Object_View1D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_View1D_Main(*Object.Object)
Declare   _Object_View1D_Delete(*Object.Object)
Declare   Object_View1D_Window_Open(*Object.Object)

Declare   Object_View1D_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_View1D_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_View1D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_View1D_Window_Close(*Object.Object)

; ##################################################### Includes ####################################################

XIncludeFile "Object_View1D_Settings.pbi"

; ##################################################### Procedures ##################################################

Procedure Object_View1D_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_View1D.Object_View1D
  Protected *Object_Input.Object_Input
  
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  *Object\Type = Object_View1D_Main\Object_Type
  *Object\Type_Base = Object_View1D_Main\Object_Type
  
  *Object\Function_Delete = @_Object_View1D_Delete()
  *Object\Function_Main = @Object_View1D_Main()
  *Object\Function_Window = @Object_View1D_Window_Open()
  *Object\Function_Configuration_Get = @Object_View1D_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_View1D_Configuration_Set()
  
  *Object\Name = "View1D"
  *Object\Color = RGBA(200, 127, 127, 255)
  
  *Object_View1D = AllocateMemory(SizeOf(Object_View1D))
  *Object\Custom_Data = *Object_View1D
  InitializeStructure(*Object_View1D, Object_View1D)
  
  *Object_View1D\Settings = AllocateMemory(SizeOf(Object_View1D_Settings))
  InitializeStructure(*Object_View1D\Settings, Object_View1D_Settings)
  
  *Object_View1D\Zoom_X = 1
  *Object_View1D\Zoom_Y = 1
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Custom_Data = AllocateMemory(SizeOf(Object_View1D_Input))
  InitializeStructure(*Object_Input\Custom_Data, Object_View1D_Input)
  *Object_Input\Function_Event = @Object_View1D_Input_Event()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_View1D_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  Object_View1D_Window_Close(*Object)
  Object_View1D_Settings_Window_Close(*Object)
  
  ForEach *Object\Input()
    If *Object\Input()\Custom_Data
      ClearStructure(*Object\Input()\Custom_Data, Object_View1D_Input)
      FreeMemory(*Object\Input()\Custom_Data)
    EndIf
  Next
  
  ClearStructure(*Object_View1D\Settings, Object_View1D_Settings)
  FreeMemory(*Object_View1D\Settings)
  
  ClearStructure(*Object_View1D, Object_View1D)
  FreeMemory(*Object_View1D)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  Protected *NBT_Tag.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *Object_View1D_Input.Object_View1D_Input
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Offset_X", #NBT_Tag_Double)  : NBT_Tag_Set_Double(*NBT_Tag, *Object_View1D\Offset_X)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Offset_Y", #NBT_Tag_Double)  : NBT_Tag_Set_Double(*NBT_Tag, *Object_View1D\Offset_Y)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Zoom_X", #NBT_Tag_Double)    : NBT_Tag_Set_Double(*NBT_Tag, *Object_View1D\Zoom_X)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Zoom_Y", #NBT_Tag_Double)    : NBT_Tag_Set_Double(*NBT_Tag, *Object_View1D\Zoom_Y)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Connect", #NBT_Tag_Byte)     : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D\Connect)
  
  *NBT_Tag_List = NBT_Tag_Add(*Parent_Tag, "Inputs", #NBT_Tag_List, #NBT_Tag_Compound)
  If *NBT_Tag_List
    ForEach *Object\Input()
      *Object_View1D_Input = *Object\Input()\Custom_Data
      
      *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_List, "", #NBT_Tag_Compound)
      If *NBT_Tag_Compound
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "ElementType", #NBT_Tag_Long) : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D_Input\ElementType)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "ElementSize", #NBT_Tag_Long) : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D_Input\ElementSize)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Manually", #NBT_Tag_Long)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D_Input\Manually)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Offset", #NBT_Tag_Quad)      : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D_Input\Offset)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Color", #NBT_Tag_Long)       : NBT_Tag_Set_Number(*NBT_Tag, *Object_View1D_Input\Color)
      EndIf
    Next
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  Protected *NBT_Tag.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected *Object_Input.Object_Input
  Protected Elements, i
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Offset_X") : *Object_View1D\Offset_X = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Offset_Y") : *Object_View1D\Offset_Y = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Zoom_X")   : *Object_View1D\Zoom_X = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Zoom_Y")   : *Object_View1D\Zoom_Y = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Connect")  : *Object_View1D\Connect = NBT_Tag_Get_Number(*NBT_Tag)
  
  ; #### Delete all inputs
  While FirstElement(*Object\Input())
    If *Object\Input()\Custom_Data
      ClearStructure(*Object\Input()\Custom_Data, Object_View1D_Input)
      FreeMemory(*Object\Input()\Custom_Data)
    EndIf
    Object_Input_Delete(*Object, *Object\Input())
  Wend
  
  *NBT_Tag_List = NBT_Tag(*Parent_Tag, "Inputs")
  If *NBT_Tag_List
    Elements = NBT_Tag_Count(*NBT_Tag_List)
    
    For i = 0 To Elements-1
      *NBT_Tag_Compound = NBT_Tag_Index(*NBT_Tag_List, i)
      If *NBT_Tag_Compound
        
        ; #### Add Input
        *Object_Input = Object_Input_Add(*Object)
        *Object_Input\Custom_Data = AllocateMemory(SizeOf(Object_View1D_Input))
        InitializeStructure(*Object_Input\Custom_Data, Object_View1D_Input)
        *Object_Input\Function_Event = @Object_View1D_Input_Event()
        *Object_View1D_Input = *Object_Input\Custom_Data
        If *Object_View1D_Input
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "ElementType") : *Object_View1D_Input\ElementType = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "ElementSize") : *Object_View1D_Input\ElementSize = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Manually")    : *Object_View1D_Input\Manually = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Offset")      : *Object_View1D_Input\Offset = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Color")       : *Object_View1D_Input\Color = NBT_Tag_Get_Number(*NBT_Tag)
        EndIf
        
      EndIf
    Next
    
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Event(*Object.Object, *Object_Event.Object_Event)
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Event_Save
      
    Case #Object_Event_SaveAs
      
    Case #Object_Event_Undo
      
    Case #Object_Event_Redo
      
    Case #Object_Event_Goto
      ; #### Open window here
      
    Case #Object_Event_Search
      ; #### Open window here
      
    Case #Object_Event_Search_Continue
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object_Input\Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update
      *Object_View1D\Redraw = #True
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Organize(*Object.Object)
  Protected *Object_View1D_Input.Object_View1D_Input
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  *Object_View1D\Elements = 0
  
  ; #### Limit Zoom in X
  If *Object_View1D\Zoom_X < 0.0001
    *Object_View1D\Zoom_X = 0.0001
  EndIf
  
  ; #### Go throught each input
  ForEach *Object\Input()
    *Object_View1D_Input = *Object\Input()\Custom_Data
    If *Object_View1D_Input
      ; #### Get max. amount of elements
      If *Object_View1D_Input\ElementSize > 0
        If *Object_View1D\Elements < Object_Input_Get_Size(*Object\Input()) / *Object_View1D_Input\ElementSize
          *Object_View1D\Elements = Object_Input_Get_Size(*Object\Input()) / *Object_View1D_Input\ElementSize
        EndIf
      EndIf
      
      ; #### Get the settings from the data descriptor of the output
      If Not *Object_View1D_Input\Manually
        *Object_View1D_Input\ElementSize = 1
        *Object_View1D_Input\ElementType = #PB_Ascii
      EndIf
    EndIf
  Next
  
  ; #### Window values
  Protected Width = GadgetWidth(*Object_View1D\Canvas_Data)
  Protected Height = GadgetHeight(*Object_View1D\Canvas_Data)
  
  SetGadgetAttribute(*Object_View1D\ScrollBar_X, #PB_ScrollBar_Maximum, *Object_View1D\Elements * *Object_View1D\Zoom_X)
  SetGadgetAttribute(*Object_View1D\ScrollBar_X, #PB_ScrollBar_PageLength, Width)
  SetGadgetState(*Object_View1D\ScrollBar_X, -*Object_View1D\Offset_X)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Get_Data(*Object.Object)
  Protected *Temp, Temp_Size, Elements, Temp_Start.q
  Protected Width
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected i
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  Width = GadgetWidth(*Object_View1D\Canvas_Data)
  
  ; #### Go throught each input
  ForEach *Object\Input()
    *Object_View1D_Input = *Object\Input()\Custom_Data
    If *Object_View1D_Input
      
      ClearList(*Object_View1D_Input\Value())
      
      Temp_Start = (-*Object_View1D\Offset_X / *Object_View1D\Zoom_X)
      Temp_Start * *Object_View1D_Input\ElementSize
      If Temp_Start < 0
        Temp_Start = 0
      EndIf
      
      Elements = Width / *Object_View1D\Zoom_X
      Temp_Size = Elements * *Object_View1D_Input\ElementSize
      If Temp_Start + Temp_Size > Object_Input_Get_Size(*Object\Input())
        Temp_Size = Object_Input_Get_Size(*Object\Input()) - Temp_Start
        Elements = Temp_Size / *Object_View1D_Input\ElementSize
      EndIf
      If Temp_Size > 0
        *Temp = AllocateMemory(Temp_Size)
        If *Temp
          Object_Input_Get_Data(*Object\Input(), Temp_Start, Temp_Size, *Temp, #Null)
          For i = 0 To Elements-1
            AddElement(*Object_View1D_Input\Value())
            *Object_View1D_Input\Value()\Position = Temp_Start / *Object_View1D_Input\ElementSize + i
            Select *Object_View1D_Input\ElementType
              Case #PB_Byte    : *Object_View1D_Input\Value()\Value = PeekB(*Temp+i)
              Case #PB_Ascii   : *Object_View1D_Input\Value()\Value = PeekA(*Temp+i)
              Case #PB_Word    : *Object_View1D_Input\Value()\Value = PeekW(*Temp+i*2)
              Case #PB_Unicode : *Object_View1D_Input\Value()\Value = PeekU(*Temp+i*2)
              Case #PB_Long    : *Object_View1D_Input\Value()\Value = PeekL(*Temp+i*4)
              Case #PB_Quad    : *Object_View1D_Input\Value()\Value = PeekQ(*Temp+i*8)
              Case #PB_Float   : *Object_View1D_Input\Value()\Value = PeekF(*Temp+i*4)
              Case #PB_Double  : *Object_View1D_Input\Value()\Value = PeekD(*Temp+i*8)
            EndSelect
          Next
          FreeMemory(*Temp)
        EndIf
      EndIf
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Canvas_Redraw_Filter_Blink(x, y, SourceColor, TargetColor)
  If (x+y) & 1
    ProcedureReturn ~TargetColor
  Else
    ProcedureReturn TargetColor
  EndIf
EndProcedure

Procedure Object_View1D_Canvas_Redraw_Filter_Inverse(x, y, SourceColor, TargetColor)
  ProcedureReturn ~TargetColor
EndProcedure

Procedure Object_View1D_Canvas_Redraw(*Object.Object)
  Protected Width, Height
  Protected X_M.d, Y_M.d, X_M_O.d, Y_M_O.d, First
  Protected X_R.d, Y_R.d
  Protected i, ix, iy
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected Division_Size_X.d, Division_Size_Y.d, Divisions_X.q, Divisions_Y.q
  Protected Text.s, Text_Width, Text_Height
  Protected *Color_Temp.Object_View1D_RGB
  
  Debug "Test"
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  ; #### X Canvas
  Width = GadgetWidth(*Object_View1D\Canvas_X)
  Height = GadgetHeight(*Object_View1D\Canvas_X)
  If Not StartDrawing(CanvasOutput(*Object_View1D\Canvas_X))
    ProcedureReturn #False
  EndIf
  
  Box(0, 0, Width, Height, GetSysColor_(#COLOR_BTNFACE))
  
  DrawingFont(FontID(Object_View1D_Main\Font_ID))
  
  DrawingMode(#PB_2DDrawing_Transparent)
  
  FrontColor(RGB(0,0,255))
  BackColor(RGB(255,255,255))
  
  ; #### Draw Grid
  Division_Size_X = Pow(10,Round(Log10(1 / *Object_View1D\Zoom_X),#PB_Round_Up))*20
  Divisions_X = Round((Width + 100) / *Object_View1D\Zoom_X, #PB_Round_Up) / Division_Size_X
  For ix = 0 To Divisions_X
    X_M = ix * Division_Size_X * *Object_View1D\Zoom_X + *Object_View1D\Offset_X - Round(*Object_View1D\Offset_X / (Division_Size_X * *Object_View1D\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object_View1D\Zoom_X)
    X_R = (X_M - *Object_View1D\Offset_X) / *Object_View1D\Zoom_X
    Text = LSet(StrD(X_R), 13)
    Text_Width = TextWidth(Text)
    Text_Height = TextHeight(Text)
    DrawRotatedText(X_M-0.9*Text_Width-0.9*Text_Height, 0.9*Text_Width-0.9*Text_Height, Text, 45)
    LineXY(X_M, 0, X_M-80, 80)
  Next
  
  StopDrawing()
  
  ; #### Y Canvas
  Width = GadgetWidth(*Object_View1D\Canvas_Y)
  Height = GadgetHeight(*Object_View1D\Canvas_Y)
  If Not StartDrawing(CanvasOutput(*Object_View1D\Canvas_Y))
    ProcedureReturn #False
  EndIf
  
  Box(0, 0, Width, Height, GetSysColor_(#COLOR_BTNFACE))
  
  DrawingFont(FontID(Object_View1D_Main\Font_ID))
  
  DrawingMode(#PB_2DDrawing_Transparent)
  
  FrontColor(RGB(0,0,255))
  BackColor(RGB(255,255,255))
  
  ; #### Draw Grid
  Division_Size_Y = Pow(10,Round(Log10(1 / *Object_View1D\Zoom_Y),#PB_Round_Up))*20
  Divisions_Y = Round(Height / *Object_View1D\Zoom_Y, #PB_Round_Up) / Division_Size_Y
  For iy = -Divisions_Y/2-1 To Divisions_Y/2
    Y_M = iy * Division_Size_Y * *Object_View1D\Zoom_Y + Height/2 + *Object_View1D\Offset_Y - Round(*Object_View1D\Offset_Y / (Division_Size_Y * *Object_View1D\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object_View1D\Zoom_Y)
    Y_R = (Height/2 + *Object_View1D\Offset_Y - Y_M) / *Object_View1D\Zoom_Y
    Text = LSet(StrD(Y_R), 13)
    Text_Width = TextWidth(Text)
    Text_Height = TextHeight(Text)
    DrawText(Width - Text_Width, Y_M-Text_Height, Text)
    LineXY(Width-100, Y_M, Width, Y_M)
  Next
  
  StopDrawing()
  
  ; #### Data Canvas
  Width = GadgetWidth(*Object_View1D\Canvas_Data)
  Height = GadgetHeight(*Object_View1D\Canvas_Data)
  If Not StartDrawing(CanvasOutput(*Object_View1D\Canvas_Data))
    ProcedureReturn #False
  EndIf
  
  Box(0, 0, Width, Height, RGB(255,255,255))
  
  DrawingFont(FontID(Object_View1D_Main\Font_ID))
  
  FrontColor(RGB(0,0,255))
  BackColor(RGB(255,255,255))
  
  ; #### Draw Grid
  Division_Size_X = Pow(10,Round(Log10(1 / *Object_View1D\Zoom_X),#PB_Round_Up))*20
  Division_Size_Y = Pow(10,Round(Log10(1 / *Object_View1D\Zoom_Y),#PB_Round_Up))*20
  Divisions_X = Round(Width / *Object_View1D\Zoom_X, #PB_Round_Up) / Division_Size_X
  Divisions_Y = Round(Height / *Object_View1D\Zoom_Y, #PB_Round_Up) / Division_Size_Y
  For ix = 0 To Divisions_X
    X_M = ix * Division_Size_X * *Object_View1D\Zoom_X + *Object_View1D\Offset_X - Round(*Object_View1D\Offset_X / (Division_Size_X * *Object_View1D\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object_View1D\Zoom_X)
    Line(X_M, 0, 0, Height, RGB(230,230,230))
  Next
  For iy = -Divisions_Y/2-1 To Divisions_Y/2
    Y_M = iy * Division_Size_Y * *Object_View1D\Zoom_Y + Height/2 + *Object_View1D\Offset_Y - Round(*Object_View1D\Offset_Y / (Division_Size_Y * *Object_View1D\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object_View1D\Zoom_Y)
    Line(0, Y_M, Width, 0, RGB(230,230,230))
  Next
  Line(0, *Object_View1D\Offset_Y + Height/2, Width, 0, RGB(180,180,180))
  Line(*Object_View1D\Offset_X, 0, 0, Height, RGB(180,180,180))
  
  ; #### Go throught each input
  ;Protected *Buffer     = DrawingBuffer()             ; Get the start address of the screen buffer
  ;Protected Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
  ForEach *Object\Input()
    *Object_View1D_Input = *Object\Input()\Custom_Data
    If *Object_View1D_Input
      If *Object_View1D\Connect
        First = #True
        ForEach *Object_View1D_Input\Value()
          X_M = *Object_View1D_Input\Value()\Position * *Object_View1D\Zoom_X + *Object_View1D\Offset_X
          Y_M = Height/2 - *Object_View1D_Input\Value()\Value * *Object_View1D\Zoom_Y + *Object_View1D\Offset_Y
          
          If Not First
            LineXY(X_M, Y_M, X_M_O, Y_M_O, *Object_View1D_Input\Color)
          Else
            First = #False
          EndIf
          
          X_M_O = X_M
          Y_M_O = Y_M
        Next
      Else
        ForEach *Object_View1D_Input\Value()
          X_M = *Object_View1D_Input\Value()\Position * *Object_View1D\Zoom_X + *Object_View1D\Offset_X
          Y_M = Height/2 - *Object_View1D_Input\Value()\Value * *Object_View1D\Zoom_Y + *Object_View1D\Offset_Y
          ;Circle(X_M, Y_M, 0, RGB(0,0,0))
          If Int(X_M) >= 0 And Int(X_M) < Width And Int(Y_M) >= 0 And Int(Y_M) < Height
            ;*Color_Temp = *Buffer + Int(X_M)*3 + Int(Height-1-Y_M) * Pitch
            ;*Color_Temp\R = 0
            ;*Color_Temp\G = 0
            ;*Color_Temp\B = 0
            Plot(Int(X_M), Int(Y_M), *Object_View1D_Input\Color)
          EndIf
        Next
      EndIf
    EndIf
  Next
  
  StopDrawing()
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Window_Event_Canvas_Data()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected M_X.l, M_Y.l
  Protected Key, Modifiers
  Protected Temp_Zoom.d
  Protected i
  Static Move_Active
  Static Move_X, Move_Y
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn 
  EndIf
  
  Select Event_Type
    Case #PB_EventType_RightClick
      ;*Object_View1D\Menu_Object = *Object
      ;DisplayPopupMenu(Object_View1D_Main\PopupMenu, WindowID(*Object_View1D\Window\ID))
      
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
      *Object_View1D\Redraw = #True
      
    Case #PB_EventType_LeftButtonUp
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      *Object_View1D\Redraw = #True
      
    Case #PB_EventType_MouseMove
      If Move_Active
        *Object_View1D\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
        *Object_View1D\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        *Object_View1D\Redraw = #True
      EndIf
      
    Case #PB_EventType_MouseWheel
      Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
      ;If *Object_View1D\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
      ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object_View1D\Zoom_X
      ;EndIf
      ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
      ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
      ;EndIf
      ;If *Object_View1D\Zoom_X * Temp_Zoom > 1
      ;  Temp_Zoom = 1 / *Object_View1D\Zoom_X
      ;EndIf
      *Object_View1D\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object_View1D\Offset_X)
      *Object_View1D\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object_View1D\Offset_Y)
      *Object_View1D\Zoom_X * Temp_Zoom
      *Object_View1D\Zoom_Y * Temp_Zoom
      
      *Object_View1D\Redraw = #True
      
    Case #PB_EventType_KeyDown
      Key = GetGadgetAttribute(*Object_View1D\Canvas_Data, #PB_Canvas_Key)
      Modifiers = GetGadgetAttribute(*Object_View1D\Canvas_Data, #PB_Canvas_Modifiers)
      Select Key
        Case #PB_Shortcut_Insert
          
        Case #PB_Shortcut_Right
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_Left
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_Home
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_End
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_PageUp
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_PageDown
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_A
          ;*Object_View1D\Redraw = #True
          
        Case #PB_Shortcut_C
          
        Case #PB_Shortcut_V
          
        Case #PB_Shortcut_Back
          
        Case #PB_Shortcut_Delete
          
      EndSelect
      
  EndSelect
  
EndProcedure

Procedure Object_View1D_Window_Event_Canvas_X()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected M_X.l, M_Y.l
  Protected Key, Modifiers
  Protected Temp_Zoom.d
  Protected i
  Static Move_Active
  Static Move_X, Move_Y
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
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
        *Object_View1D\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
        ;*Object_View1D\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        *Object_View1D\Redraw = #True
      EndIf
      
    Case #PB_EventType_MouseWheel
      Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
      ;If *Object_View1D\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
      ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object_View1D\Zoom_X
      ;EndIf
      ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
      ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
      ;EndIf
      ;If *Object_View1D\Zoom_X * Temp_Zoom > 1
      ;  Temp_Zoom = 1 / *Object_View1D\Zoom_X
      ;EndIf
      *Object_View1D\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object_View1D\Offset_X)
      ;*Object_View1D\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object_View1D\Offset_Y)
      *Object_View1D\Zoom_X * Temp_Zoom
      ;*Object_View1D\Zoom_Y * Temp_Zoom
      
      *Object_View1D\Redraw = #True
      
  EndSelect
  
EndProcedure

Procedure Object_View1D_Window_Event_Canvas_Y()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected M_X.l, M_Y.l
  Protected Key, Modifiers
  Protected Temp_Zoom.d
  Protected i
  Static Move_Active
  Static Move_X, Move_Y
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
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
        ;*Object_View1D\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
        *Object_View1D\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        *Object_View1D\Redraw = #True
      EndIf
      
    Case #PB_EventType_MouseWheel
      Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
      ;If *Object_View1D\Zoom_X * Temp_Zoom < 1/Pow(1.1, 20)
      ;  Temp_Zoom = 1/Pow(1.1, 20) / *Object_View1D\Zoom_X
      ;EndIf
      ;If Window_Objects\Zoom * Temp_Zoom > Pow(1.1, 10)
      ;  Temp_Zoom = Pow(1.1, 10) / Window_Objects\Zoom
      ;EndIf
      ;If *Object_View1D\Zoom_X * Temp_Zoom > 1
      ;  Temp_Zoom = 1 / *Object_View1D\Zoom_X
      ;EndIf
      ;*Object_View1D\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object_View1D\Offset_X)
      *Object_View1D\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - GadgetHeight(Event_Gadget)/2 - *Object_View1D\Offset_Y)
      ;*Object_View1D\Zoom_X * Temp_Zoom
      *Object_View1D\Zoom_Y * Temp_Zoom
      
      *Object_View1D\Redraw = #True
      
  EndSelect
  
EndProcedure

Procedure Object_View1D_Window_Callback(hWnd, uMsg, wParam, lParam)
  Protected SCROLLINFO.SCROLLINFO
  
  Protected *Window.Window = Window_Get_hWnd(hWnd)
  If Not *Window
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  
  Select uMsg
    Case #WM_HSCROLL
      Select wParam & $FFFF
        Case #SB_THUMBTRACK
          SCROLLINFO\fMask = #SIF_TRACKPOS
          SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
          GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
          *Object_View1D\Offset_X = - SCROLLINFO\nTrackPos
          *Object_View1D\Redraw = #True
        Case #SB_PAGEUP
          *Object_View1D\Offset_X + GadgetWidth(*Object_View1D\Canvas_Data)
          *Object_View1D\Redraw = #True
        Case #SB_PAGEDOWN
          *Object_View1D\Offset_X - GadgetWidth(*Object_View1D\Canvas_Data)
          *Object_View1D\Redraw = #True
        Case #SB_LINEUP
          *Object_View1D\Offset_X + 100
          *Object_View1D\Redraw = #True
        Case #SB_LINEDOWN
          *Object_View1D\Offset_X - 100
          *Object_View1D\Redraw = #True
      EndSelect
      If *Object_View1D\Redraw
        *Object_View1D\Redraw = #False
        Object_View1D_Organize(*Object)
        Object_View1D_Get_Data(*Object)
        Object_View1D_Canvas_Redraw(*Object)
      EndIf
      
  EndSelect
  
  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure

Procedure Object_View1D_Window_Event_SizeWindow()
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, Canvas_X_Height, Canvas_Y_Width, ScrollBar_X_Height
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn 
  EndIf
  
  Width = WindowWidth(Event_Window)
  Height = WindowHeight(Event_Window)
  
  ToolBarHeight = ToolBarHeight(*Object_View1D\ToolBar)
  
  Canvas_X_Height = 100
  Canvas_Y_Width = 100
  
  ScrollBar_X_Height = 17
  
  Data_Width = Width - Canvas_Y_Width
  Data_Height = Height - ScrollBar_X_Height - Canvas_X_Height - ToolBarHeight
  
  ; #### Gadgets
  ResizeGadget(*Object_View1D\ScrollBar_X, Canvas_Y_Width, Height-ScrollBar_X_Height, Data_Width, ScrollBar_X_Height)
  
  ResizeGadget(*Object_View1D\Canvas_X, Canvas_Y_Width, ToolBarHeight+Data_Height, Data_Width, Canvas_X_Height)
  ResizeGadget(*Object_View1D\Canvas_Y, 0, ToolBarHeight, Canvas_Y_Width, Data_Height)
  ResizeGadget(*Object_View1D\Canvas_Data, Canvas_Y_Width, ToolBarHeight, Data_Width, Data_Height)
  
  *Object_View1D\Redraw = #True
EndProcedure

Procedure Object_View1D_Window_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn 
  EndIf
  
  *Object_View1D\Redraw = #True
EndProcedure

Procedure Object_View1D_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected Max.d, Min.d
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn 
  EndIf
  
  Select Event_Menu
    Case #Object_View1D_Menu_Settings
      Object_View1D_Settings_Window_Open(*Object)
      
    Case #Object_View1D_Menu_X_Normalize
      *Object_View1D\Zoom_X = 1
      *Object_View1D\Redraw = #True
      
    Case #Object_View1D_Menu_Y_Normalize
      *Object_View1D\Zoom_Y = 1
      *Object_View1D\Redraw = #True
      
    Case #Object_View1D_Menu_Y_Fit
      Max = -Infinity()
      Min = Infinity()
      ForEach *Object\Input()
        *Object_View1D_Input = *Object\Input()\Custom_Data
        If *Object_View1D_Input
          ForEach *Object_View1D_Input\Value()
            If Max < *Object_View1D_Input\Value()\Value
              Max = *Object_View1D_Input\Value()\Value
            EndIf
            If Min > *Object_View1D_Input\Value()\Value
              Min = *Object_View1D_Input\Value()\Value
            EndIf
          Next
        EndIf
      Next
      If Max - Min > 0.1
        *Object_View1D\Zoom_Y = GadgetHeight(*Object_View1D\Canvas_Data) / (Max - Min)
        *Object_View1D\Offset_Y = (Max + Min) / 2 * *Object_View1D\Zoom_Y
        *Object_View1D\Redraw = #True
      EndIf
      
    Case #Object_View1D_Menu_Lines
      *Object_View1D\Connect = GetToolBarButtonState(*Object_View1D\ToolBar, #Object_View1D_Menu_Lines)
      *Object_View1D\Redraw = #True
      
  EndSelect
EndProcedure

Procedure Object_View1D_Window_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn 
  EndIf
  
  ;Object_View1D_Window_Close(*Object)
  *Object_View1D\Window_Close = #True
EndProcedure

Procedure Object_View1D_Window_Open(*Object.Object)
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, Canvas_X_Height, Canvas_Y_Width, ScrollBar_X_Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  If *Object_View1D\Window = #Null
    
    Width = 500
    Height = 500
    
    *Object_View1D\Window = Window_Create(*Object, "View1D", "View1D", #True, #PB_Ignore, #PB_Ignore, Width, Height)
    
    ; #### Toolbar
    *Object_View1D\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object_View1D\Window\ID))
    ToolBarImageButton(#Object_View1D_Menu_Settings, ImageID(Icon_Gear))
    ToolBarImageButton(#Object_View1D_Menu_X_Normalize, ImageID(Object_View1D_Icon_Normalize_X))
    ToolBarImageButton(#Object_View1D_Menu_Y_Normalize, ImageID(Object_View1D_Icon_Normalize_Y))
    ToolBarImageButton(#Object_View1D_Menu_Y_Fit, ImageID(Object_View1D_Icon_Fit_Y))
    ToolBarImageButton(#Object_View1D_Menu_Lines, ImageID(Object_View1D_Icon_Lines), #PB_ToolBar_Toggle)
    SetToolBarButtonState(*Object_View1D\ToolBar, #Object_View1D_Menu_Lines, *Object_View1D\Connect)
    
    ToolBarHeight = ToolBarHeight(*Object_View1D\ToolBar)
    
    Canvas_X_Height = 100
    Canvas_Y_Width = 100
    
    ScrollBar_X_Height = 17
    
    Data_Width = Width - Canvas_Y_Width
    Data_Height = Height - ScrollBar_X_Height - Canvas_X_Height - ToolBarHeight
    
    ; #### Gadgets
    *Object_View1D\ScrollBar_X = ScrollBarGadget(#PB_Any, Canvas_Y_Width, Height-ScrollBar_X_Height, Data_Width, ScrollBar_X_Height, 0, 10, 1)
    
    *Object_View1D\Canvas_X = CanvasGadget(#PB_Any, Canvas_Y_Width, ToolBarHeight+Data_Height, Data_Width, Canvas_X_Height, #PB_Canvas_Keyboard)
    *Object_View1D\Canvas_Y = CanvasGadget(#PB_Any, 0, ToolBarHeight, Canvas_Y_Width, Data_Height, #PB_Canvas_Keyboard)
    *Object_View1D\Canvas_Data = CanvasGadget(#PB_Any, Canvas_Y_Width, ToolBarHeight, Data_Width, Data_Height, #PB_Canvas_Keyboard)
    
    BindEvent(#PB_Event_SizeWindow, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    ;BindEvent(#PB_Event_Repaint, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    ;BindEvent(#PB_Event_ActivateWindow, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_View1D_Window_Event_Menu(), *Object_View1D\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_View1D_Window_Event_CloseWindow(), *Object_View1D\Window\ID)
    BindGadgetEvent(*Object_View1D\Canvas_Data, @Object_View1D_Window_Event_Canvas_Data())
    BindGadgetEvent(*Object_View1D\Canvas_X, @Object_View1D_Window_Event_Canvas_X())
    BindGadgetEvent(*Object_View1D\Canvas_Y, @Object_View1D_Window_Event_Canvas_Y())
    
    SetWindowCallback(@Object_View1D_Window_Callback(), *Object_View1D\Window\ID)
    
    *Object_View1D\Redraw = #True
    
  Else
    Window_Set_Active(*Object_View1D\Window)
  EndIf
EndProcedure

Procedure Object_View1D_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  If *Object_View1D\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    ;UnbindEvent(#PB_Event_Repaint, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Object_View1D_Window_Event_SizeWindow(), *Object_View1D\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_View1D_Window_Event_Menu(), *Object_View1D\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_View1D_Window_Event_CloseWindow(), *Object_View1D\Window\ID)
    UnbindGadgetEvent(*Object_View1D\Canvas_Data, @Object_View1D_Window_Event_Canvas_Data())
    UnbindGadgetEvent(*Object_View1D\Canvas_X, @Object_View1D_Window_Event_Canvas_X())
    UnbindGadgetEvent(*Object_View1D\Canvas_Y, @Object_View1D_Window_Event_Canvas_Y())
    
    SetWindowCallback(#Null, *Object_View1D\Window\ID)
    
    Window_Delete(*Object_View1D\Window)
    *Object_View1D\Window = #Null
  EndIf
EndProcedure

Procedure Object_View1D_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  
  If *Object_View1D\Window
    If *Object_View1D\Redraw
      *Object_View1D\Redraw = #False
      Object_View1D_Organize(*Object)
      Object_View1D_Get_Data(*Object)
      Object_View1D_Canvas_Redraw(*Object)
    EndIf
  EndIf
  
  Object_View1D_Settings_Main(*Object)
  
  If *Object_View1D\Window_Close
    *Object_View1D\Window_Close = #False
    Object_View1D_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_View1D_Main\Object_Type = Object_Type_Create()
If Object_View1D_Main\Object_Type
  Object_View1D_Main\Object_Type\Category = "Viewer"
  Object_View1D_Main\Object_Type\Name = "View1D"
  Object_View1D_Main\Object_Type\UID = "D3VIEW1D"
  Object_View1D_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_View1D_Main\Object_Type\Date_Creation = Date(2014,01,28,14,42,00)
  Object_View1D_Main\Object_Type\Date_Modification = Date(2014,01,28,14,42,00)
  Object_View1D_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_View1D_Main\Object_Type\Description = "Just a normal Graph viewer."
  Object_View1D_Main\Object_Type\Function_Create = @Object_View1D_Create()
  Object_View1D_Main\Object_Type\Version = 0900
EndIf

; #### Object Popup-Menu
;Object_View1D_Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
;MenuItem(#Object_View1D_PopupMenu_Cut, "Cut")
;MenuItem(#Object_View1D_PopupMenu_Copy, "Copy")
;MenuItem(#Object_View1D_PopupMenu_Paste, "Paste")
;MenuBar()
;MenuItem(#Object_View1D_PopupMenu_Close, "Close")

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

DataSection
  Object_View1D_Icon_Dots:        : IncludeBinary "../Data/Icons/Graph_Dots.png"
  Object_View1D_Icon_Lines:       : IncludeBinary "../Data/Icons/Graph_Lines.png"
  Object_View1D_Icon_Fit_Y:       : IncludeBinary "../Data/Icons/Graph_Fit_Y.png"
  Object_View1D_Icon_Normalize_X: : IncludeBinary "../Data/Icons/Graph_Normalize_X.png"
  Object_View1D_Icon_Normalize_Y: : IncludeBinary "../Data/Icons/Graph_Normalize_Y.png"
EndDataSection
; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 1236
; FirstLine = 1179
; Folding = ----
; EnableXP