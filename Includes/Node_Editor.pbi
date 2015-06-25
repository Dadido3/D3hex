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

#Node_Editor_Text_Height = 20

Enumeration
  #Node_Editor_Object_PopupMenu_Window
  
  #Node_Editor_Object_PopupMenu_Delete
  
  ; -------------------------------------
  
  #Node_Editor_Menu_Clear_Config
  #Node_Editor_Menu_Load_Config
  #Node_Editor_Menu_Save_Config
  #Node_Editor_Menu_Grid_Snapping
  #Node_Editor_Menu_Align
EndEnumeration

; ##################################################### Structures ##################################################

Structure Node_Editor_Main
  Object_PopupMenu.i
  
  Font_ID.i
  Font_ID_Small.i
EndStructure
Global Node_Editor_Main.Node_Editor_Main

Structure Node_Editor
  *Window.Window
  Window_Close.l
  
  ToolBar.i
  
  ; #### Objects (Canvas)
  Canvas.i
  Redraw.l
  
  Snapping.i
  
  Offset_X.d
  Offset_Y.d
  Zoom.d
  
  *Highlighted_Object   ; 
  *Selected_Object      ; 
  *Move_Object          ; Currently moving object
  Move_X.d              ; Where the Object is grabbed
  Move_Y.d              ; Where the Object is grabbed
  *Highlighted_InOut    ; The highlighted....
  *Selected_InOut       ; The currently selected In/Output
  *Connection_Out       ; The current output, which is being connected.
  Connection_Out_X.d    ; Position where the mouse is
  Connection_Out_Y.d    ; Position where the mouse is
  *Menu_Object          ; Object the menu is displayed for
  
  ; #### Object_Types (Treelist)
  TreeList.q
  Types_Refresh.l
EndStructure
Global Node_Editor.Node_Editor

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

Node_Editor_Main\Font_ID = LoadFont(#PB_Any, "", 10, #PB_Font_Bold)
Node_Editor_Main\Font_ID_Small = LoadFont(#PB_Any, "", 6)

; ##################################################### Icons ... ###################################################

Global Node_Editor_Icon_Load_Config = CatchImage(#PB_Any, ?Node_Editor_Icon_Load_Config)
Global Node_Editor_Icon_Save_Config = CatchImage(#PB_Any, ?Node_Editor_Icon_Save_Config)
Global Node_Editor_Icon_Grid_Snapping = CatchImage(#PB_Any, ?Node_Editor_Icon_Grid_Snapping)
Global Node_Editor_Icon_Align = CatchImage(#PB_Any, ?Node_Editor_Icon_Align)

; ##################################################### Init ########################################################

Node_Editor\Zoom = 1

; ##################################################### Declares ####################################################

Declare   Node_Editor_Close()

; ##################################################### Procedures ##################################################

Procedure Node_Editor_Configuration_Clear()
  While FirstElement(Object())
    Object_Delete(Object())
  Wend
  
  Object_Main\ID_Counter = 0
  
  Node_Editor\Offset_X = 0
  Node_Editor\Offset_Y = 0
  Node_Editor\Zoom = 1
  
  Node_Editor\Redraw = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Node_Editor_Configuration_Save(Filename.s)
  Protected *NBT_Element.NBT_Element
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag.NBT_Tag
  
  If LCase(GetExtensionPart(Filename)) <> LCase("D3hex")
    Filename + ".D3hex"
  EndIf
  
  *NBT_Element = NBT_Element_Add()
  
  If Not *NBT_Element
    Logging_Entry_Add_Error("Couldn't save configuration", "NBT_Element_Add() failed. ("+NBT_Error_Get()+")")
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Snapping", #NBT_Tag_Byte)   : NBT_Tag_Set_Number(*NBT_Tag, Node_Editor\Snapping)
  *NBT_Tag = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Offset_X", #NBT_Tag_Double) : NBT_Tag_Set_Double(*NBT_Tag, Node_Editor\Offset_X)
  *NBT_Tag = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Offset_Y", #NBT_Tag_Double) : NBT_Tag_Set_Double(*NBT_Tag, Node_Editor\Offset_Y)
  *NBT_Tag = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Zoom", #NBT_Tag_Double)     : NBT_Tag_Set_Double(*NBT_Tag, Node_Editor\Zoom)
  
  ; #### Write the list of objects to the file
  *NBT_Tag_List = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Objects", #NBT_Tag_List, #NBT_Tag_Compound)
  If *NBT_Tag_List
    ForEach Object()
      If Object()\Type
        *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_List, "", #NBT_Tag_Compound)
        If *NBT_Tag_Compound
          *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Type_UID", #NBT_Tag_String)  : NBT_Tag_Set_String(*NBT_Tag, Object()\Type_Base\UID)
          *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "ID", #NBT_Tag_Quad)          : NBT_Tag_Set_Number(*NBT_Tag, Object()\ID)
          *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "X", #NBT_Tag_Double)         : NBT_Tag_Set_Double(*NBT_Tag, Object()\X)
          *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Y", #NBT_Tag_Double)         : NBT_Tag_Set_Double(*NBT_Tag, Object()\Y)
        EndIf
        
        ; #### Custom data stuff
        *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_Compound, "Custom", #NBT_Tag_Compound)
        If *NBT_Tag_Compound
          If Object()\Function_Configuration_Get
            Object()\Function_Configuration_Get(Object(), *NBT_Tag_Compound)
          EndIf
        EndIf
        
      EndIf
    Next
  EndIf
  
  ; #### Write the list of links to the file
  *NBT_Tag_List = NBT_Tag_Add(*NBT_Element\NBT_Tag, "Links", #NBT_Tag_List, #NBT_Tag_Compound)
  If *NBT_Tag_List
    ForEach Object()
      ForEach Object()\Input()
        If Object()\Input()\Linked
          *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_List, "", #NBT_Tag_Compound)
          If *NBT_Tag_Compound
            *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Output_Object", #NBT_Tag_Quad)         : NBT_Tag_Set_Number(*NBT_Tag, Object()\Input()\Linked\Object\ID)
            *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Output_Object_i", #NBT_Tag_Quad)       : NBT_Tag_Set_Number(*NBT_Tag, Object()\Input()\Linked\i)
            *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Input_Object", #NBT_Tag_Quad)          : NBT_Tag_Set_Number(*NBT_Tag, Object()\ID)
            *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Input_Object_i", #NBT_Tag_Quad)        : NBT_Tag_Set_Number(*NBT_Tag, Object()\Input()\i)
          EndIf
        EndIf
      Next
    Next
  EndIf
  
  If NBT_Write_File(*NBT_Element, Filename)
    If NBT_Error_Available()
      Logging_Entry_Add_Error("Error while saving configuration", "NBT_Write_File(*NBT_Element, '"+Filename+"') failed. ("+NBT_Error_Get()+")")
    EndIf
    NBT_Element_Delete(*NBT_Element)
    ProcedureReturn #True
  Else
    Logging_Entry_Add_Error("Couldn't save configuration", "General NBT exception. ("+NBT_Error_Get()+")")
    NBT_Element_Delete(*NBT_Element)
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure Node_Editor_Configuration_Load(Filename.s)
  Protected Elements, i
  Protected Group_Name.s
  Protected *NBT_Element.NBT_Element
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag.NBT_Tag
  
  Protected *Object_Type.Object_Type
  Protected *Object.Object
  Protected *Object_Input.Object_Input
  Protected *Object_Output.Object_Output
  Protected Temp_Number.i
  
  Node_Editor_Configuration_Clear()
  
  *NBT_Element = NBT_Read_File(Filename)
  
  If Not *NBT_Element
    Logging_Entry_Add_Error("Couldn't load configuration", "NBT_Read_File('"+Filename+"') failed. ("+NBT_Error_Get()+")")
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*NBT_Element\NBT_Tag, "Snapping")  : Node_Editor\Snapping = NBT_Tag_Get_Number(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*NBT_Element\NBT_Tag, "Offset_X")  : Node_Editor\Offset_X = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*NBT_Element\NBT_Tag, "Offset_Y")  : Node_Editor\Offset_Y = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*NBT_Element\NBT_Tag, "Zoom")      : Node_Editor\Zoom = NBT_Tag_Get_Double(*NBT_Tag)
  
  *NBT_Tag_List = NBT_Tag(*NBT_Element\NBT_Tag, "Objects")
  If *NBT_Tag_List
    Elements = NBT_Tag_Count(*NBT_Tag_List)
    
    For i = 0 To Elements-1
      *NBT_Tag_Compound = NBT_Tag_Index(*NBT_Tag_List, i)
      If *NBT_Tag_Compound
        *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Type_UID") : *Object_Type = Object_Type_Get_UID(NBT_Tag_Get_String(*NBT_Tag))
        If *Object_Type
          *Object = *Object_Type\Function_Create(#False)
          If *Object
            *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "ID")   : *Object\ID = NBT_Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "X")    : *Object\X = NBT_Tag_Get_Double(*NBT_Tag)
            *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Y")    : *Object\Y = NBT_Tag_Get_Double(*NBT_Tag)
            
            If Object_Main\ID_Counter < *Object\ID
              Object_Main\ID_Counter = *Object\ID
            EndIf
            
            ; #### Custom data stuff
            *NBT_Tag_Compound = NBT_Tag(*NBT_Tag_Compound, "Custom")
            If *NBT_Tag_Compound
              If *Object\Function_Configuration_Set
                *Object\Function_Configuration_Set(*Object, *NBT_Tag_Compound)
              EndIf
            EndIf
            
          EndIf
        EndIf
      EndIf
    Next
    
  EndIf
  
  *NBT_Tag_List = NBT_Tag(*NBT_Element\NBT_Tag, "Links")
  If *NBT_Tag_List
    Elements = NBT_Tag_Count(*NBT_Tag_List)
    
    For i = 0 To Elements-1
      *NBT_Tag_Compound = NBT_Tag_Index(*NBT_Tag_List, i)
      If *NBT_Tag_Compound
        *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Output_Object")            : *Object = Object_Get(NBT_Tag_Get_Number(*NBT_Tag))
        If *Object
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Output_Object_i")        : Temp_Number = NBT_Tag_Get_Number(*NBT_Tag)
          ForEach *Object\Output()
            If *Object\Output()\i = Temp_Number
              *Object_Output = *Object\Output()
              Break
            EndIf
          Next
        EndIf
        *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Input_Object")             : *Object = Object_Get(NBT_Tag_Get_Number(*NBT_Tag))
        If *Object
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Input_Object_i")         : Temp_Number = NBT_Tag_Get_Number(*NBT_Tag)
          ForEach *Object\Input()
            If *Object\Input()\i = Temp_Number
              *Object_Input = *Object\Input()
              Break
            EndIf
          Next
        EndIf
        Object_Link_Connect(*Object_Output, *Object_Input)
      EndIf
    Next
    
  EndIf
  
  If NBT_Error_Available()
    Logging_Entry_Add_Error("Error while reading configuration", "General NBT exception. ("+NBT_Error_Get()+")")
  EndIf
  
  NBT_Element_Delete(*NBT_Element)
  
  SetToolBarButtonState(Node_Editor\ToolBar, #Node_Editor_Menu_Grid_Snapping, Node_Editor\Snapping)
  
  Node_Editor\Redraw = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Node_Editor_Object_Redraw(*Object.Object)
  Protected i
  
  If Not *Object\Image
    *Object\Image = CreateImage(#PB_Any, 100, 50, 32)
  EndIf
  
  If Not *Object\Image
    ProcedureReturn #False
  EndIf
  
  ; #### Resize
  If StartDrawing(ImageOutput(*Object\Image))
    DrawingFont(FontID(Node_Editor_Main\Font_ID))
    *Object\Width = TextWidth(*Object\Name) + 20
    StopDrawing()
  EndIf
  
  *Object\Height = ListSize(*Object\Input()) * 20
  If *Object\Height < ListSize(*Object\Output()) * 20
    *Object\Height = ListSize(*Object\Output()) * 20
  EndIf
  *Object\Height + #Node_Editor_Text_Height
  
  If *Object\Width < 100
    *Object\Width = 100
  EndIf
  If *Object\Height < 50
    *Object\Height = 50
  EndIf
  
  ResizeImage(*Object\Image, *Object\Width, *Object\Height, #PB_Image_Raw)
  
  If StartDrawing(ImageOutput(*Object\Image))
    
    DrawingMode(#PB_2DDrawing_AllChannels)
    DrawingFont(FontID(Node_Editor_Main\Font_ID))
    Box(0, 0, *Object\Width, *Object\Height, RGBA(0, 0, 0, 0))
    
    RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, *Object\Color)
    DrawingMode(#PB_2DDrawing_Transparent | #PB_2DDrawing_Outlined)
    RoundBox(0, 0, *Object\Width, 20, 4, 4, RGBA(100,100,100,255))
    If *Object = Node_Editor\Selected_Object Or *Object = Node_Editor\Highlighted_Object
      RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, RGBA(255,255,0,255))
    Else
      RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, RGBA(0,0,0,255))
    EndIf
    DrawText(10, 1, *Object\Name)
    
    DrawingMode(#PB_2DDrawing_AllChannels)
    DrawingFont(FontID(Node_Editor_Main\Font_ID_Small))
    
    ForEach *Object\Input()
      i = *Object\Input()\i
      If *Object\Input() = Node_Editor\Highlighted_InOut
        Box(0, #Node_Editor_Text_Height + i*20+4, 16, 10, RGBA(255,255,0,255))
      Else
        Box(0, #Node_Editor_Text_Height + i*20+4, 16, 10, RGBA(0,0,0,255))
      EndIf
      Box(0, #Node_Editor_Text_Height + i*20+5, 15, 8, RGBA(0,255,0,255))
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawText(20, #Node_Editor_Text_Height + i*20+4, *Object\Input()\Short_Name, 0)
      DrawingMode(#PB_2DDrawing_AllChannels)
    Next
    
    ForEach *Object\Output()
      i = *Object\Output()\i
      If *Object\Output() = Node_Editor\Highlighted_InOut
        Box(*Object\Width - 16, #Node_Editor_Text_Height + i*20+4, 16, 10, RGBA(255,255,0,255))
      Else
        Box(*Object\Width - 16, #Node_Editor_Text_Height + i*20+4, 16, 10, RGBA(0,0,0,255))
      EndIf
      Box(*Object\Width - 15, #Node_Editor_Text_Height + i*20+5, 15, 8, RGBA(0,0,255,255))
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawText(*Object\Width-20-TextWidth(*Object\Output()\Short_Name), #Node_Editor_Text_Height + i*20+4, *Object\Output()\Short_Name, 0)
      DrawingMode(#PB_2DDrawing_AllChannels)
    Next
    
    StopDrawing()
  EndIf
EndProcedure

Procedure Node_Editor_Canvas_Redraw()
  Protected Width = GadgetWidth(Node_Editor\Canvas)
  Protected Height = GadgetHeight(Node_Editor\Canvas)
  Protected S_X.d, S_Y.d, S_Width.d, S_Height.d
  Protected X1.d, Y1.d, X2.d, Y2.d
  Protected ix, iy, Raster_Size.d
  
  If Node_Editor\Zoom < 1/Pow(1.1, 20)
    Node_Editor\Zoom = 1/Pow(1.1, 20)
  EndIf
  
  If StartDrawing(CanvasOutput(Node_Editor\Canvas))
    
    Box(0, 0, Width, Height, RGB(220,220,220))
    
    Raster_Size = (50 * Node_Editor\Zoom)
    For ix = 0 To Width / Raster_Size
      Line(ix*Raster_Size + Mod(Node_Editor\Offset_X, Raster_Size), 0, 0, Height, RGB(255,255,255))
      Line(ix*Raster_Size + Mod(Node_Editor\Offset_X, Raster_Size)-1, 0, 0, Height, RGB(150,150,150))
    Next
    For iy = 0 To Height / Raster_Size
      Line(0, iy*Raster_Size + Mod(Node_Editor\Offset_Y, Raster_Size), Width, 0, RGB(255,255,255))
      Line(0, iy*Raster_Size + Mod(Node_Editor\Offset_Y, Raster_Size)-1, Width, 0, RGB(150,150,150))
    Next
    
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    
    If LastElement(Object())
      Repeat
        S_X = Object()\X * Node_Editor\Zoom + Node_Editor\Offset_X
        S_Y = Object()\Y * Node_Editor\Zoom + Node_Editor\Offset_Y
        S_Width = Object()\Width * Node_Editor\Zoom
        S_Height = Object()\Height * Node_Editor\Zoom
        
        ; #### Draw Links
        ForEach Object()\Output()
          X1 = Object()\X + Object()\Width
          Y1 = Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+9
          ForEach Object()\Output()\Linked()
            X2 = Object()\Output()\Linked()\Object\X
            Y2 = Object()\Output()\Linked()\Object\Y + #Node_Editor_Text_Height + Object()\Output()\Linked()\i*20+9
            LineXY(X1*Node_Editor\Zoom+Node_Editor\Offset_X, Y1*Node_Editor\Zoom+Node_Editor\Offset_Y, X2*Node_Editor\Zoom+Node_Editor\Offset_X, Y2*Node_Editor\Zoom+Node_Editor\Offset_Y, RGBA(0,0,0,255))
          Next
          
          ; #### Draw the connection to the mouse while linking
          If Object()\Output() = Node_Editor\Connection_Out
            X2 = Node_Editor\Connection_Out_X
            Y2 = Node_Editor\Connection_Out_Y
            LineXY(X1*Node_Editor\Zoom+Node_Editor\Offset_X, Y1*Node_Editor\Zoom+Node_Editor\Offset_Y, X2*Node_Editor\Zoom+Node_Editor\Offset_X, Y2*Node_Editor\Zoom+Node_Editor\Offset_Y, RGBA(0,0,0,255))
          EndIf
        Next
        
        DrawImage(ImageID(Object()\Image), S_X, S_Y, S_Width, S_Height)
        
      Until Not PreviousElement(Object())
    EndIf
    
    StopDrawing()
  EndIf
EndProcedure

; #### Recursively sets the Y Coordinate of the objects the a negative value
Procedure Node_Editor_Align_Helper(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Y = - *Object\Height - 50
  
  ForEach *Object\Output()
    ForEach *Object\Output()\Linked()
      PushListPosition(*Object\Output())
      PushListPosition(*Object\Output()\Linked())
      Node_Editor_Align_Helper(*Object\Output()\Linked()\Object)
      PopListPosition(*Object\Output())
      PopListPosition(*Object\Output()\Linked())
    Next
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure Node_Editor_Align_Object(*Object.Object, First_Iteration=#True)
  Protected X.d, Y.d
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Node_Editor_Object_Redraw(*Object)
  
  If First_Iteration
    Node_Editor_Align_Helper(*Object)
  EndIf
  
  ; #### Search the first free row
  If First_Iteration
    ForEach Object()
      If Object() <> *Object
        If Y < Object()\Y + Object()\Height + 50
          Y = Object()\Y + Object()\Height + 50
        EndIf
      EndIf
    Next
    
    Y - Mod(Y, 50)
  EndIf
  
  If First_Iteration
    *Object\X = X
    *Object\Y = Y
  Else
    X = *Object\X
    Y = *Object\Y
  EndIf
  
  X + *Object\Width + 50
  
  ForEach *Object\Output()
    ForEach *Object\Output()\Linked()
      PushListPosition(*Object\Output())
      PushListPosition(*Object\Output()\Linked())
      Node_Editor_Object_Redraw(*Object\Output()\Linked()\Object)
      PopListPosition(*Object\Output())
      PopListPosition(*Object\Output()\Linked())
      
      *Object\Output()\Linked()\Object\X = X
      *Object\Output()\Linked()\Object\Y = Y
      Y + *Object\Output()\Linked()\Object\Height + 50
      Y - Mod(Y, 50)
      
      PushListPosition(*Object\Output())
      PushListPosition(*Object\Output()\Linked())
      Node_Editor_Align_Object(*Object\Output()\Linked()\Object, #False)
      PopListPosition(*Object\Output())
      PopListPosition(*Object\Output()\Linked())
    Next
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Node_Editor_Event_Canvas()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected Temp_Zoom.d
  Protected R_X.d, R_Y.d
  Static Move_Active, Move_X, Move_Y
  Protected Found.l
  
  Select Event_Type
    Case #PB_EventType_RightClick
      R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X) / Node_Editor\Zoom
      R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y) / Node_Editor\Zoom
      
      ; #### Get the first element under the mouse.
      ForEach Object()
        If R_X >= Object()\X And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y And R_Y < Object()\Y + Object()\Height
          
          
          ForEach Object()\Input()
            If R_X >= Object()\X And R_X < Object()\X + 16 And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 + 10
              Found = #True
              
              Break
            EndIf
          Next
          
          ForEach Object()\Output()
            If R_X >= Object()\X + Object()\Width - 16 And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 + 10
              Found = #True
              Break
            EndIf
          Next
          
          If Not Found
            Node_Editor\Menu_Object = Object()
            DisplayPopupMenu(Node_Editor_Main\Object_PopupMenu, WindowID(Node_Editor\Window\ID))
          EndIf
          
          Break
        EndIf
      Next
      ;Node_Editor\Redraw = #True
      
      
    Case #PB_EventType_RightButtonDown
      Move_Active = #True
      Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      
    Case #PB_EventType_RightButtonUp
      Move_Active = #False
      
    Case #PB_EventType_LeftDoubleClick
      R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X) / Node_Editor\Zoom
      R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y) / Node_Editor\Zoom
      ; #### Get the first element under the mouse.
      ForEach Object()
        If R_X >= Object()\X And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y And R_Y < Object()\Y + Object()\Height
          If Object()\Function_Window
            Object()\Function_Window(Object())
          EndIf
          Break
        EndIf
      Next
      Node_Editor\Move_Object = #Null
      
    Case #PB_EventType_LeftButtonDown
      R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X) / Node_Editor\Zoom
      R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y) / Node_Editor\Zoom
      ; #### Get the first element under the mouse.
      ForEach Object()
        If R_X >= Object()\X And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y And R_Y < Object()\Y + Object()\Height
          PushListPosition(Object())
          ForEach Object()
            If Object() = Node_Editor\Selected_Object
              Object()\Redraw = #True
              Break
            EndIf
          Next
          PopListPosition(Object())
          Node_Editor\Selected_Object = Object()
          Object()\Redraw = #True
          
          Node_Editor\Selected_InOut = #Null
          
          ForEach Object()\Input()
            If R_X >= Object()\X And R_X < Object()\X + 16 And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 + 10
              Node_Editor\Selected_InOut = Object()\Input()
              If Object()\Input()\Linked
                Node_Editor\Connection_Out = Object()\Input()\Linked
                Node_Editor\Connection_Out_X = R_X
                Node_Editor\Connection_Out_Y = R_Y
                Object_Link_Disconnect(Object()\Input())
              EndIf
              Object()\Redraw = #True
              Break
            EndIf
          Next
          
          ForEach Object()\Output()
            If R_X >= Object()\X + Object()\Width - 16 And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 + 10
              Node_Editor\Selected_InOut = Object()\Output()
              Node_Editor\Connection_Out = Object()\Output()
              Node_Editor\Connection_Out_X = R_X
              Node_Editor\Connection_Out_Y = R_Y
              Object()\Redraw = #True
              Break
            EndIf
          Next
          
          ; #### Activate Movement, if no In/Output was selected
          If Node_Editor\Selected_InOut = #Null
            Node_Editor\Move_Object = Object()
            Node_Editor\Move_X = R_X - Object()\X
            Node_Editor\Move_Y = R_Y - Object()\Y
          EndIf
          
          Found = #True
          
          Break
        EndIf
      Next
      If Not Found
        ForEach Object()
          If Object() = Node_Editor\Selected_Object
            Object()\Redraw = #True
            Break
          EndIf
        Next
        Node_Editor\Selected_Object = #Null
      EndIf
      
    Case #PB_EventType_LeftButtonUp
      R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X) / Node_Editor\Zoom
      R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y) / Node_Editor\Zoom
      Node_Editor\Move_Object = #Null
      
      ; #### Get the first element under the mouse.
      ForEach Object()
        If R_X >= Object()\X And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y And R_Y < Object()\Y + Object()\Height
          
          
          ForEach Object()\Input()
            If R_X >= Object()\X And R_X < Object()\X + 16 And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 + 10
              If Node_Editor\Connection_Out
                Object_Link_Connect(Node_Editor\Connection_Out, Object()\Input())
              EndIf
              Break
            EndIf
          Next
          
          ForEach Object()\Output()
            If R_X >= Object()\X + Object()\Width - 16 And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 + 10
              
              Break
            EndIf
          Next
          
          Break
        EndIf
      Next
      Node_Editor\Connection_Out = #Null
      Node_Editor\Redraw = #True
      
    Case #PB_EventType_MouseMove
      If Move_Active
        Node_Editor\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
        Node_Editor\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        Node_Editor\Redraw = #True
      EndIf
      R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X) / Node_Editor\Zoom
      R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y) / Node_Editor\Zoom
      ForEach Object()
        If Object() = Node_Editor\Move_Object
          Object()\X = R_X - Node_Editor\Move_X
          Object()\Y = R_Y - Node_Editor\Move_Y
          If Node_Editor\Snapping
            Object()\X = Round(Object()\X / 50, #PB_Round_Nearest) * 50
            Object()\Y = Round(Object()\Y / 50, #PB_Round_Nearest) * 50
          EndIf
          Object()\Redraw = #True
        EndIf
      Next
      ; #### Get the first element under the mouse.
      Node_Editor\Highlighted_InOut = #Null
      ForEach Object()
        If R_X >= Object()\X And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y And R_Y < Object()\Y + Object()\Height
          PushListPosition(Object())
          ForEach Object()
            If Object() = Node_Editor\Highlighted_Object
              Object()\Redraw = #True
              Break
            EndIf
          Next
          PopListPosition(Object())
          Node_Editor\Highlighted_Object = Object()
          Object()\Redraw = #True
          
          ForEach Object()\Input()
            If R_X >= Object()\X And R_X < Object()\X + 16 And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Input()\i*20+4 + 10
              Node_Editor\Highlighted_InOut = Object()\Input()
              Object()\Redraw = #True
              Break
            EndIf
          Next
          
          ForEach Object()\Output()
            If R_X >= Object()\X + Object()\Width - 16 And R_X < Object()\X + Object()\Width And R_Y >= Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 And R_Y < Object()\Y + #Node_Editor_Text_Height + Object()\Output()\i*20+4 + 10
              Node_Editor\Highlighted_InOut = Object()\Output()
              Object()\Redraw = #True
              Break
            EndIf
          Next
          
          Found = #True
          
          Break
        EndIf
      Next
      If Not Found
        ForEach Object()
          If Object() = Node_Editor\Highlighted_Object
            Object()\Redraw = #True
            Break
          EndIf
        Next
        Node_Editor\Highlighted_Object = #Null
      EndIf
      If Node_Editor\Connection_Out
        Node_Editor\Connection_Out_X = R_X
        Node_Editor\Connection_Out_Y = R_Y
        Node_Editor\Redraw = #True
      EndIf
      
    Case #PB_EventType_MouseWheel
      Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
      If Node_Editor\Zoom * Temp_Zoom < 1/Pow(1.1, 20)
        Temp_Zoom = 1/Pow(1.1, 20) / Node_Editor\Zoom
      EndIf
      ;If Node_Editor\Zoom * Temp_Zoom > Pow(1.1, 10)
      ;  Temp_Zoom = Pow(1.1, 10) / Node_Editor\Zoom
      ;EndIf
      If Node_Editor\Zoom * Temp_Zoom > 1
        Temp_Zoom = 1 / Node_Editor\Zoom
      EndIf
      Node_Editor\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Node_Editor\Offset_X)
      Node_Editor\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Node_Editor\Offset_Y)
      Node_Editor\Zoom * Temp_Zoom
      
      Node_Editor\Redraw = #True
      
  EndSelect
  
EndProcedure

Procedure Node_Editor_Event_Canvas_Drop()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected R_X.d, R_Y.d
  Protected *Object_Type.Object_Type
  Protected *Object.Object
  
  R_X = (EventDropX() - Node_Editor\Offset_X) / Node_Editor\Zoom
  R_Y = (EventDropY() - Node_Editor\Offset_Y) / Node_Editor\Zoom
  If EventDropAction() = #DragDrop_Private_Objects
    *Object_Type = Object_Type_Get(GetGadgetItemData(Node_Editor\TreeList, GetGadgetState(Node_Editor\TreeList)))
    If  *Object_Type
      *Object = *Object_Type\Function_Create(#True)
      If *Object
        *Object\X = R_X
        *Object\Y = R_Y
        If Node_Editor\Snapping
          *Object\X = Round(*Object\X / 50, #PB_Round_Nearest) * 50
          *Object\Y = Round(*Object\Y / 50, #PB_Round_Nearest) * 50
        EndIf
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure Node_Editor_TreeList_Refresh()
  Protected Width = GadgetWidth(Node_Editor\TreeList)
  Protected Height = GadgetHeight(Node_Editor\TreeList)
  
  Protected NewList Category.s()
  Protected Found
  Protected i
  
  ForEach Object_Type()
    Found = #False
    ForEach Category()
      If Category() = Object_Type()\Category
        Found = #True
        Break
      EndIf
    Next
    If Not Found
      AddElement(Category())
      Category() = Object_Type()\Category
    EndIf
  Next
  
  ClearGadgetItems(Node_Editor\TreeList)
  
  i = 0
  ForEach Category()
    AddGadgetItem(Node_Editor\TreeList, i, Category(), #Null, 0)
    i + 1
    ForEach Object_Type()
      If Object_Type()\Category = Category()
        AddGadgetItem(Node_Editor\TreeList, i, Object_Type()\Name, #Null, 1)
        SetGadgetItemData(Node_Editor\TreeList, i, Object_Type()\ID)
        i + 1
      EndIf
    Next
  Next
  
EndProcedure

Procedure Node_Editor_Event_TreeList()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Select Event_Type
    Case #PB_EventType_DragStart
      DragPrivate(#DragDrop_Private_Objects, #PB_Drag_Copy)
      
  EndSelect
  
EndProcedure

Procedure Node_Editor_Event_SizeWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected ToolBarHeight
  
  ToolBarHeight = ToolBarHeight(Node_Editor\ToolBar)
  
  ResizeGadget(Node_Editor\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Node_Editor\Window\ID)-150, WindowHeight(Node_Editor\Window\ID)-ToolBarHeight)
  ResizeGadget(Node_Editor\TreeList, WindowWidth(Node_Editor\Window\ID)-150, #PB_Ignore, 150, WindowHeight(Node_Editor\Window\ID)-ToolBarHeight)
  
  ;Node_Editor\Redraw = #True
  Node_Editor_Canvas_Redraw()
EndProcedure

Procedure Node_Editor_Event_ActivateWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Node_Editor\Redraw = #True
  ;Node_Editor_Canvas_Redraw()
EndProcedure

Procedure Node_Editor_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Protected Filename.s
  
  Select Event_Menu
    Case #Node_Editor_Object_PopupMenu_Window
      ForEach Object()
        If Object() = Node_Editor\Menu_Object
          If Object()\Function_Window
            Object()\Function_Window(Object())
          EndIf
          Break
        EndIf
      Next
      
    Case #Node_Editor_Object_PopupMenu_Delete
      ForEach Object()
        If Object() = Node_Editor\Menu_Object
          Object_Delete(Object())
          Node_Editor\Redraw = #True
          Break
        EndIf
      Next
      
    Case #Node_Editor_Menu_Clear_Config
      Node_Editor_Configuration_Clear()
      
    Case #Node_Editor_Menu_Load_Config
      Filename = OpenFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
      If Filename
        Node_Editor_Configuration_Load(Filename)
      EndIf
      
    Case #Node_Editor_Menu_Save_Config
      Filename = SaveFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
      If Filename
        Node_Editor_Configuration_Save(Filename)
      EndIf
      
    Case #Node_Editor_Menu_Grid_Snapping
      Node_Editor\Snapping = GetToolBarButtonState(Node_Editor\ToolBar, #Node_Editor_Menu_Grid_Snapping)
      
    Case #Node_Editor_Menu_Align
      ForEach Object()
        If Object() = Node_Editor\Selected_Object
          Node_Editor_Align_Object(Object())
          Break
        EndIf
      Next
      
  EndSelect
EndProcedure

Procedure Node_Editor_Event_CloseWindow()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  ;Node_Editor_Close()
  Node_Editor\Window_Close = #True
EndProcedure

Procedure Node_Editor_Open()
  Protected ToolBarHeight
  
  If Node_Editor\Window = #Null
    Node_Editor\Window = Window_Create(#Null, "Node Editor", "Node Editor", #True, #PB_Ignore, #PB_Ignore, 500, 500, #True, 20)
    
    ; #### Toolbar
    Node_Editor\ToolBar = CreateToolBar(#PB_Any, WindowID(Node_Editor\Window\ID))
    ToolBarImageButton(#Node_Editor_Menu_Clear_Config, ImageID(Icon_Node_Clear_Config))
    ToolBarImageButton(#Node_Editor_Menu_Load_Config, ImageID(Icon_Node_Load_Config))
    ToolBarImageButton(#Node_Editor_Menu_Save_Config, ImageID(Icon_Node_Save_Config))
    ToolBarSeparator()
    ToolBarImageButton(#Node_Editor_Menu_Grid_Snapping, ImageID(Node_Editor_Icon_Grid_Snapping), #PB_ToolBar_Toggle)
    ToolBarImageButton(#Node_Editor_Menu_Align, ImageID(Node_Editor_Icon_Align))
    
    SetToolBarButtonState(Node_Editor\ToolBar, #Node_Editor_Menu_Grid_Snapping, Node_Editor\Snapping)
    
    ToolBarHeight = ToolBarHeight(Node_Editor\ToolBar)
    
    Node_Editor\Canvas = CanvasGadget(#PB_Any, 0, ToolBarHeight, 350, 500-ToolBarHeight, #PB_Canvas_Keyboard)
    
    Node_Editor\TreeList = TreeGadget(#PB_Any, 350, ToolBarHeight, 150, 500-ToolBarHeight)
    
    BindGadgetEvent(Node_Editor\Canvas, @Node_Editor_Event_Canvas())
    EnableGadgetDrop(Node_Editor\Canvas, #PB_Drop_Private, #PB_Drag_Copy, #DragDrop_Private_Objects)
    BindEvent(#PB_Event_GadgetDrop, @Node_Editor_Event_Canvas_Drop(), Node_Editor\Window\ID, Node_Editor\Canvas)
    
    BindGadgetEvent(Node_Editor\TreeList, @Node_Editor_Event_TreeList())
    
    BindEvent(#PB_Event_SizeWindow, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    ;BindEvent(#PB_Event_Repaint, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    BindEvent(#PB_Event_Menu, @Node_Editor_Event_Menu(), Node_Editor\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Node_Editor_Event_CloseWindow(), Node_Editor\Window\ID)
    
    Node_Editor\Redraw = #True
    Node_Editor\Types_Refresh = #True
    
  Else
    Window_Set_Active(Node_Editor\Window)
  EndIf
EndProcedure

Procedure Node_Editor_Close()
  If Node_Editor\Window
    
    UnbindGadgetEvent(Node_Editor\Canvas, @Node_Editor_Event_Canvas())
    UnbindEvent(#PB_Event_GadgetDrop, @Node_Editor_Event_Canvas_Drop(), Node_Editor\Window\ID, Node_Editor\Canvas)
    
    UnbindGadgetEvent(Node_Editor\TreeList, @Node_Editor_Event_TreeList())
    
    UnbindEvent(#PB_Event_SizeWindow, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    ;UnbindEvent(#PB_Event_Repaint, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Node_Editor_Event_SizeWindow(), Node_Editor\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Node_Editor_Event_Menu(), Node_Editor\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Node_Editor_Event_CloseWindow(), Node_Editor\Window\ID)
    
    Window_Delete(Node_Editor\Window)
    Node_Editor\Window = #Null
  EndIf
EndProcedure

Procedure Node_Editor_Main()
  If Not Node_Editor\Window
    ProcedureReturn #False
  EndIf
  
  ForEach Object()
    If Object()\Redraw
      Object()\Redraw = #False
      Node_Editor\Redraw = #True
      Node_Editor_Object_Redraw(Object())
    EndIf
  Next
  
  If Node_Editor\Redraw
    Node_Editor\Redraw = #False
    Node_Editor_Canvas_Redraw()
  EndIf
  
  If Node_Editor\Types_Refresh
    Node_Editor\Types_Refresh = #False
    Node_Editor_TreeList_Refresh()
  EndIf
  
  If Node_Editor\Window_Close
    Node_Editor\Window_Close = #False
    Node_Editor_Close()
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################

; #### Object Popup-Menu
Node_Editor_Main\Object_PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
MenuItem(#Node_Editor_Object_PopupMenu_Window, "Window")
MenuBar()
MenuItem(#Node_Editor_Object_PopupMenu_Delete, "Delete")

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

DataSection
  Node_Editor_Icon_Load_Config:   : IncludeBinary "../Data/Icons/Node_Load_Config.png"
  Node_Editor_Icon_Save_Config:   : IncludeBinary "../Data/Icons/Node_Save_Config.png"
  Node_Editor_Icon_Grid_Snapping: : IncludeBinary "../Data/Icons/Node_Grid_Snapping.png"
  Node_Editor_Icon_Align:         : IncludeBinary "../Data/Icons/Node_Align.png"
EndDataSection
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 979
; FirstLine = 972
; Folding = ----
; EnableUnicode
; EnableXP