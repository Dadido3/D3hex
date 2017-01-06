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
; ##################################################### Includes ####################################################

; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule Node_Editor
  EnableExplicit
  ; ################################################### Constants ###################################################
  
  ; ################################################### Functions ###################################################
  Declare   Configuration_Clear()
  Declare   Configuration_Save(Filename.s)
  Declare   Configuration_Load(Filename.s)
  Declare   Align_Object(*Object.Node::Object, First_Iteration=#True)
  Declare   Open()
  Declare   Close()
  Declare   Main()
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Node_Editor
  ; ##################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ##################################################### Prototypes ##################################################
  
  ; ##################################################### Structures ##################################################
  
  ; ##################################################### Constants ###################################################
  
  #Text_Height = 20
  
  Enumeration
    #Object_PopupMenu_Window
    
    #Object_PopupMenu_Delete
    
    ; -------------------------------------
    
    #Menu_Clear_Config
    #Menu_Load_Config
    #Menu_Save_Config
    #Menu_Grid_Snapping
    #Menu_Align
  EndEnumeration
  
  ; ##################################################### Structures ##################################################
  
  Structure Main
    Object_PopupMenu.i
    
    Font_ID.i
    Font_ID_Small.i
  EndStructure
  Global Main.Main
  
  Structure Window
    *Window.Window::Object
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
    
    ; #### Node_Types (Treelist)
    TreeList.q
    Types_Refresh.l
  EndStructure
  Global Window.Window
  
  ; ##################################################### Variables ###################################################
  
  ; ##################################################### Fonts #######################################################
  
  Main\Font_ID = LoadFont(#PB_Any, "", 10, #PB_Font_Bold)
  Main\Font_ID_Small = LoadFont(#PB_Any, "", 6)
  
  ; ##################################################### Icons ... ###################################################
  
  Global Icon_Load_Config = CatchImage(#PB_Any, ?Icon_Load_Config)
  Global Icon_Save_Config = CatchImage(#PB_Any, ?Icon_Save_Config)
  Global Icon_Grid_Snapping = CatchImage(#PB_Any, ?Icon_Grid_Snapping)
  Global Icon_Align = CatchImage(#PB_Any, ?Icon_Align)
  
  ; ##################################################### Init ########################################################
  
  Window\Zoom = 1
  
  ; ##################################################### Declares ####################################################
  
  Declare   Close()
  
  ; ##################################################### Procedures ##################################################
  
  Procedure Configuration_Clear()
    While FirstElement(Node::Object())
      Node::Delete(Node::Object())
    Wend
    
    Node::Main\ID_Counter = 0
    
    Window\Offset_X = 0
    Window\Offset_Y = 0
    Window\Zoom = 1
    
    Window\Redraw = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Save(Filename.s)
    Protected *NBT_Element.NBT::Element
    Protected *NBT_Tag_Compound.NBT::Tag
    Protected *NBT_Tag_List.NBT::Tag
    Protected *NBT_Tag.NBT::Tag
    
    If LCase(GetExtensionPart(Filename)) <> LCase("D3hex")
      Filename + ".D3hex"
    EndIf
    
    *NBT_Element = NBT::Element_Add()
    
    If Not *NBT_Element
      Logger::Entry_Add_Error("Couldn't save configuration", "NBT_Element_Add() failed. ("+NBT::Error_Get()+")")
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag_Add(*NBT_Element\Tag, "Snapping", NBT::#Tag_Byte)   : NBT::Tag_Set_Number(*NBT_Tag, Window\Snapping)
    *NBT_Tag = NBT::Tag_Add(*NBT_Element\Tag, "Offset_X", NBT::#Tag_Double) : NBT::Tag_Set_Double(*NBT_Tag, Window\Offset_X)
    *NBT_Tag = NBT::Tag_Add(*NBT_Element\Tag, "Offset_Y", NBT::#Tag_Double) : NBT::Tag_Set_Double(*NBT_Tag, Window\Offset_Y)
    *NBT_Tag = NBT::Tag_Add(*NBT_Element\Tag, "Zoom", NBT::#Tag_Double)     : NBT::Tag_Set_Double(*NBT_Tag, Window\Zoom)
    
    ; #### Write the list of objects to the file
    *NBT_Tag_List = NBT::Tag_Add(*NBT_Element\Tag, "Objects", NBT::#Tag_List, NBT::#Tag_Compound)
    If *NBT_Tag_List
      ForEach Node::Object()
        If Node::Object()\Type
          *NBT_Tag_Compound = NBT::Tag_Add(*NBT_Tag_List, "", NBT::#Tag_Compound)
          If *NBT_Tag_Compound
            *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Type_UID", NBT::#Tag_String)  : NBT::Tag_Set_String(*NBT_Tag, Node::Object()\Type_Base\UID)
            *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "ID", NBT::#Tag_Quad)          : NBT::Tag_Set_Number(*NBT_Tag, Node::Object()\ID)
            *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "X", NBT::#Tag_Double)         : NBT::Tag_Set_Double(*NBT_Tag, Node::Object()\X)
            *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Y", NBT::#Tag_Double)         : NBT::Tag_Set_Double(*NBT_Tag, Node::Object()\Y)
          EndIf
          
          ; #### Custom data stuff
          *NBT_Tag_Compound = NBT::Tag_Add(*NBT_Tag_Compound, "Custom", NBT::#Tag_Compound)
          If *NBT_Tag_Compound
            If Node::Object()\Function_Configuration_Get
              Node::Object()\Function_Configuration_Get(Node::Object(), *NBT_Tag_Compound)
            EndIf
          EndIf
          
        EndIf
      Next
    EndIf
    
    ; #### Write the list of links to the file
    *NBT_Tag_List = NBT::Tag_Add(*NBT_Element\Tag, "Links", NBT::#Tag_List, NBT::#Tag_Compound)
    If *NBT_Tag_List
      ForEach Node::Object()
        ForEach Node::Object()\Input()
          If Node::Object()\Input()\Linked
            *NBT_Tag_Compound = NBT::Tag_Add(*NBT_Tag_List, "", NBT::#Tag_Compound)
            If *NBT_Tag_Compound
              *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Output_Object", NBT::#Tag_Quad)         : NBT::Tag_Set_Number(*NBT_Tag, Node::Object()\Input()\Linked\Object\ID)
              *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Output_Object_i", NBT::#Tag_Quad)       : NBT::Tag_Set_Number(*NBT_Tag, Node::Object()\Input()\Linked\i)
              *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Input_Object", NBT::#Tag_Quad)          : NBT::Tag_Set_Number(*NBT_Tag, Node::Object()\ID)
              *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Input_Object_i", NBT::#Tag_Quad)        : NBT::Tag_Set_Number(*NBT_Tag, Node::Object()\Input()\i)
            EndIf
          EndIf
        Next
      Next
    EndIf
    
    If NBT::Write_File(*NBT_Element, Filename)
      If NBT::Error_Available()
        Logger::Entry_Add_Error("Error while saving configuration", "NBT_Write_File(*NBT_Element, '"+Filename+"') failed. ("+NBT::Error_Get()+")")
      EndIf
      NBT::Element_Delete(*NBT_Element)
      ProcedureReturn #True
    Else
      Logger::Entry_Add_Error("Couldn't save configuration", "General NBT exception. ("+NBT::Error_Get()+")")
      NBT::Element_Delete(*NBT_Element)
      ProcedureReturn #False
    EndIf
  EndProcedure
  
  Procedure Configuration_Load(Filename.s)
    Protected Elements, i
    Protected Group_Name.s
    Protected *NBT_Element.NBT::Element
    Protected *NBT_Tag_Compound.NBT::Tag
    Protected *NBT_Tag_List.NBT::Tag
    Protected *NBT_Tag.NBT::Tag
    
    Protected *Node_Type.Node_Type::Object
    Protected *Object.Node::Object
    Protected *Object_Input.Node::Conn_Input
    Protected *Object_Output.Node::Conn_Output
    Protected Temp_Number.i
    
    Configuration_Clear()
    
    *NBT_Element = NBT::Read_File(Filename)
    
    If Not *NBT_Element
      Logger::Entry_Add_Error("Couldn't load configuration", "NBT_Read_File('"+Filename+"') failed. ("+NBT::Error_Get()+")")
      ProcedureReturn #False
    EndIf
    
    *NBT_Tag = NBT::Tag(*NBT_Element\Tag, "Snapping")  : Window\Snapping = NBT::Tag_Get_Number(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*NBT_Element\Tag, "Offset_X")  : Window\Offset_X = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*NBT_Element\Tag, "Offset_Y")  : Window\Offset_Y = NBT::Tag_Get_Double(*NBT_Tag)
    *NBT_Tag = NBT::Tag(*NBT_Element\Tag, "Zoom")      : Window\Zoom = NBT::Tag_Get_Double(*NBT_Tag)
    
    *NBT_Tag_List = NBT::Tag(*NBT_Element\Tag, "Objects")
    If *NBT_Tag_List
      Elements = NBT::Tag_Count(*NBT_Tag_List)
      
      For i = 0 To Elements-1
        *NBT_Tag_Compound = NBT::Tag_Index(*NBT_Tag_List, i)
        If *NBT_Tag_Compound
          *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Type_UID") : *Node_Type = Node_Type::Get_UID(NBT::Tag_Get_String(*NBT_Tag))
          If *Node_Type
            *Object = *Node_Type\Function_Create(#False)
            If *Object
              *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "ID")   : *Object\ID = NBT::Tag_Get_Number(*NBT_Tag)
              *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "X")    : *Object\X = NBT::Tag_Get_Double(*NBT_Tag)
              *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Y")    : *Object\Y = NBT::Tag_Get_Double(*NBT_Tag)
              
              If Node::Main\ID_Counter < *Object\ID
                Node::Main\ID_Counter = *Object\ID
              EndIf
              
              ; #### Custom data stuff
              *NBT_Tag_Compound = NBT::Tag(*NBT_Tag_Compound, "Custom")
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
    
    *NBT_Tag_List = NBT::Tag(*NBT_Element\Tag, "Links")
    If *NBT_Tag_List
      Elements = NBT::Tag_Count(*NBT_Tag_List)
      
      For i = 0 To Elements-1
        *NBT_Tag_Compound = NBT::Tag_Index(*NBT_Tag_List, i)
        If *NBT_Tag_Compound
          *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Output_Object")            : *Object = Node::Get(NBT::Tag_Get_Number(*NBT_Tag))
          If *Object
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Output_Object_i")        : Temp_Number = NBT::Tag_Get_Number(*NBT_Tag)
            ForEach *Object\Output()
              If *Object\Output()\i = Temp_Number
                *Object_Output = *Object\Output()
                Break
              EndIf
            Next
          EndIf
          *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Input_Object")             : *Object = Node::Get(NBT::Tag_Get_Number(*NBT_Tag))
          If *Object
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Input_Object_i")         : Temp_Number = NBT::Tag_Get_Number(*NBT_Tag)
            ForEach *Object\Input()
              If *Object\Input()\i = Temp_Number
                *Object_Input = *Object\Input()
                Break
              EndIf
            Next
          EndIf
          Node::Link_Connect(*Object_Output, *Object_Input)
        EndIf
      Next
      
    EndIf
    
    If NBT::Error_Available()
      Logger::Entry_Add_Error("Error while reading configuration", "General NBT exception. ("+NBT::Error_Get()+")")
    EndIf
    
    NBT::Element_Delete(*NBT_Element)
    
    If Window\Window
      SetToolBarButtonState(Window\ToolBar, #Menu_Grid_Snapping, Window\Snapping)
    EndIf
    
    Window\Redraw = #True
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Object_Redraw(*Object.Node::Object)
    Protected i
    
    If Not *Object\Image
      *Object\Image = CreateImage(#PB_Any, 100, 50, 32)
    EndIf
    
    If Not *Object\Image
      ProcedureReturn #False
    EndIf
    
    ; #### Resize
    If StartDrawing(ImageOutput(*Object\Image))
      DrawingFont(FontID(Main\Font_ID))
      *Object\Width = TextWidth(*Object\Name) + 20
      StopDrawing()
    EndIf
    
    *Object\Height = ListSize(*Object\Input()) * 20
    If *Object\Height < ListSize(*Object\Output()) * 20
      *Object\Height = ListSize(*Object\Output()) * 20
    EndIf
    *Object\Height + #Text_Height
    
    If *Object\Width < 100
      *Object\Width = 100
    EndIf
    If *Object\Height < 50
      *Object\Height = 50
    EndIf
    
    ResizeImage(*Object\Image, *Object\Width, *Object\Height, #PB_Image_Raw)
    
    If StartDrawing(ImageOutput(*Object\Image))
      
      DrawingMode(#PB_2DDrawing_AllChannels)
      DrawingFont(FontID(Main\Font_ID))
      Box(0, 0, *Object\Width, *Object\Height, RGBA(0, 0, 0, 0))
      
      RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, *Object\Color)
      DrawingMode(#PB_2DDrawing_Transparent | #PB_2DDrawing_Outlined)
      RoundBox(0, 0, *Object\Width, 20, 4, 4, RGBA(100,100,100,255))
      If *Object = Window\Selected_Object Or *Object = Window\Highlighted_Object
        RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, RGBA(255,255,0,255))
      Else
        RoundBox(0, 0, *Object\Width, *Object\Height, 4, 4, RGBA(0,0,0,255))
      EndIf
      DrawText(10, 1, *Object\Name)
      
      ; #### Debug
      DrawText(10, 15, Str(*Object\ID))
      
      DrawingMode(#PB_2DDrawing_AllChannels)
      DrawingFont(FontID(Main\Font_ID_Small))
      
      ForEach *Object\Input()
        i = *Object\Input()\i
        If *Object\Input() = Window\Highlighted_InOut
          Box(0, #Text_Height + i*20+4, 16, 10, RGBA(255,255,0,255))
        Else
          Box(0, #Text_Height + i*20+4, 16, 10, RGBA(0,0,0,255))
        EndIf
        Box(0, #Text_Height + i*20+5, 15, 8, RGBA(0,255,0,255))
        DrawingMode(#PB_2DDrawing_Transparent)
        DrawText(20, #Text_Height + i*20+4, *Object\Input()\Short_Name, 0)
        DrawingMode(#PB_2DDrawing_AllChannels)
      Next
      
      ForEach *Object\Output()
        i = *Object\Output()\i
        If *Object\Output() = Window\Highlighted_InOut
          Box(*Object\Width - 16, #Text_Height + i*20+4, 16, 10, RGBA(255,255,0,255))
        Else
          Box(*Object\Width - 16, #Text_Height + i*20+4, 16, 10, RGBA(0,0,0,255))
        EndIf
        Box(*Object\Width - 15, #Text_Height + i*20+5, 15, 8, RGBA(0,0,255,255))
        DrawingMode(#PB_2DDrawing_Transparent)
        DrawText(*Object\Width-20-TextWidth(*Object\Output()\Short_Name), #Text_Height + i*20+4, *Object\Output()\Short_Name, 0)
        DrawingMode(#PB_2DDrawing_AllChannels)
      Next
      
      StopDrawing()
    EndIf
  EndProcedure
  
  Procedure Canvas_Redraw()
    Protected Width = GadgetWidth(Window\Canvas)
    Protected Height = GadgetHeight(Window\Canvas)
    Protected S_X.d, S_Y.d, S_Width.d, S_Height.d
    Protected X1.d, Y1.d, X2.d, Y2.d
    Protected ix, iy, Raster_Size.d
    
    If Window\Zoom < 1/Pow(1.1, 20)
      Window\Zoom = 1/Pow(1.1, 20)
    EndIf
    
    If StartDrawing(CanvasOutput(Window\Canvas))
      
      Box(0, 0, Width, Height, RGB(220,220,220))
      
      Raster_Size = (50 * Window\Zoom)
      For ix = 0 To Width / Raster_Size
        Line(ix*Raster_Size + Mod(Window\Offset_X, Raster_Size), 0, 0, Height, RGB(255,255,255))
        Line(ix*Raster_Size + Mod(Window\Offset_X, Raster_Size)-1, 0, 0, Height, RGB(150,150,150))
      Next
      For iy = 0 To Height / Raster_Size
        Line(0, iy*Raster_Size + Mod(Window\Offset_Y, Raster_Size), Width, 0, RGB(255,255,255))
        Line(0, iy*Raster_Size + Mod(Window\Offset_Y, Raster_Size)-1, Width, 0, RGB(150,150,150))
      Next
      
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      
      If LastElement(Node::Object())
        Repeat
          S_X = Node::Object()\X * Window\Zoom + Window\Offset_X
          S_Y = Node::Object()\Y * Window\Zoom + Window\Offset_Y
          S_Width = Node::Object()\Width * Window\Zoom
          S_Height = Node::Object()\Height * Window\Zoom
          
          ; #### Draw Links
          ForEach Node::Object()\Output()
            X1 = Node::Object()\X + Node::Object()\Width
            Y1 = Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+9
            ForEach Node::Object()\Output()\Linked()
              X2 = Node::Object()\Output()\Linked()\Object\X
              Y2 = Node::Object()\Output()\Linked()\Object\Y + #Text_Height + Node::Object()\Output()\Linked()\i*20+9
              LineXY(X1*Window\Zoom+Window\Offset_X, Y1*Window\Zoom+Window\Offset_Y, X2*Window\Zoom+Window\Offset_X, Y2*Window\Zoom+Window\Offset_Y, RGBA(0,0,0,255))
            Next
            
            ; #### Draw the connection to the mouse while linking
            If Node::Object()\Output() = Window\Connection_Out
              X2 = Window\Connection_Out_X
              Y2 = Window\Connection_Out_Y
              LineXY(X1*Window\Zoom+Window\Offset_X, Y1*Window\Zoom+Window\Offset_Y, X2*Window\Zoom+Window\Offset_X, Y2*Window\Zoom+Window\Offset_Y, RGBA(0,0,0,255))
            EndIf
          Next
          
          If Node::Object()\Image
            DrawImage(ImageID(Node::Object()\Image), S_X, S_Y, S_Width, S_Height)
          EndIf
          
        Until Not PreviousElement(Node::Object())
      EndIf
      
      StopDrawing()
    EndIf
  EndProcedure
  
  ; #### Recursively sets the Y Coordinate of the objects the a negative value
  Procedure Align_Helper(*Object.Node::Object)
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    *Object\Y = - *Object\Height - 50
    
    ForEach *Object\Output()
      ForEach *Object\Output()\Linked()
        PushListPosition(*Object\Output())
        PushListPosition(*Object\Output()\Linked())
        Align_Helper(*Object\Output()\Linked()\Object)
        PopListPosition(*Object\Output())
        PopListPosition(*Object\Output()\Linked())
      Next
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Align_Object(*Object.Node::Object, First_Iteration=#True)
    Protected X.d, Y.d
    
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Object_Redraw(*Object)
    
    If First_Iteration
      Align_Helper(*Object)
    EndIf
    
    ; #### Search the first free row
    If First_Iteration
      ForEach Node::Object()
        If Node::Object() <> *Object
          If Y < Node::Object()\Y + Node::Object()\Height + 50
            Y = Node::Object()\Y + Node::Object()\Height + 50
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
        Object_Redraw(*Object\Output()\Linked()\Object)
        PopListPosition(*Object\Output())
        PopListPosition(*Object\Output()\Linked())
        
        *Object\Output()\Linked()\Object\X = X
        *Object\Output()\Linked()\Object\Y = Y
        Y + *Object\Output()\Linked()\Object\Height + 50
        Y - Mod(Y, 50)
        
        PushListPosition(*Object\Output())
        PushListPosition(*Object\Output()\Linked())
        Align_Object(*Object\Output()\Linked()\Object, #False)
        PopListPosition(*Object\Output())
        PopListPosition(*Object\Output()\Linked())
      Next
    Next
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Event_Canvas()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected Temp_Zoom.d
    Protected R_X.d, R_Y.d
    Static Move_Active, Move_X, Move_Y
    Protected Found.l
    
    Select Event_Type
      Case #PB_EventType_RightClick
        R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X) / Window\Zoom
        R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y) / Window\Zoom
        
        ; #### Get the first element under the mouse.
        ForEach Node::Object()
          If R_X >= Node::Object()\X And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y And R_Y < Node::Object()\Y + Node::Object()\Height
            
            
            ForEach Node::Object()\Input()
              If R_X >= Node::Object()\X And R_X < Node::Object()\X + 16 And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 + 10
                Found = #True
                
                Break
              EndIf
            Next
            
            ForEach Node::Object()\Output()
              If R_X >= Node::Object()\X + Node::Object()\Width - 16 And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 + 10
                Found = #True
                Break
              EndIf
            Next
            
            If Not Found
              Window\Menu_Object = Node::Object()
              DisplayPopupMenu(Main\Object_PopupMenu, WindowID(Window\Window\ID))
            EndIf
            
            Break
          EndIf
        Next
        ;Window\Redraw = #True
        
        
      Case #PB_EventType_RightButtonDown
        Move_Active = #True
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        
      Case #PB_EventType_RightButtonUp
        Move_Active = #False
        
      Case #PB_EventType_LeftDoubleClick
        R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X) / Window\Zoom
        R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y) / Window\Zoom
        ; #### Get the first element under the mouse.
        ForEach Node::Object()
          If R_X >= Node::Object()\X And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y And R_Y < Node::Object()\Y + Node::Object()\Height
            If Node::Object()\Function_Window
              Node::Object()\Function_Window(Node::Object())
            EndIf
            Break
          EndIf
        Next
        Window\Move_Object = #Null
        
      Case #PB_EventType_LeftButtonDown
        R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X) / Window\Zoom
        R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y) / Window\Zoom
        ; #### Get the first element under the mouse.
        ForEach Node::Object()
          If R_X >= Node::Object()\X And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y And R_Y < Node::Object()\Y + Node::Object()\Height
            PushListPosition(Node::Object())
            ForEach Node::Object()
              If Node::Object() = Window\Selected_Object
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            PopListPosition(Node::Object())
            Window\Selected_Object = Node::Object()
            Node::Object()\Redraw = #True
            
            Window\Selected_InOut = #Null
            
            ForEach Node::Object()\Input()
              If R_X >= Node::Object()\X And R_X < Node::Object()\X + 16 And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 + 10
                Window\Selected_InOut = Node::Object()\Input()
                If Node::Object()\Input()\Linked
                  Window\Connection_Out = Node::Object()\Input()\Linked
                  Window\Connection_Out_X = R_X
                  Window\Connection_Out_Y = R_Y
                  Node::Link_Disconnect(Node::Object()\Input())
                EndIf
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            
            ForEach Node::Object()\Output()
              If R_X >= Node::Object()\X + Node::Object()\Width - 16 And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 + 10
                Window\Selected_InOut = Node::Object()\Output()
                Window\Connection_Out = Node::Object()\Output()
                Window\Connection_Out_X = R_X
                Window\Connection_Out_Y = R_Y
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            
            ; #### Activate Movement, if no In/Output was selected
            If Window\Selected_InOut = #Null
              Window\Move_Object = Node::Object()
              Window\Move_X = R_X - Node::Object()\X
              Window\Move_Y = R_Y - Node::Object()\Y
            EndIf
            
            Found = #True
            
            Break
          EndIf
        Next
        If Not Found
          ForEach Node::Object()
            If Node::Object() = Window\Selected_Object
              Node::Object()\Redraw = #True
              Break
            EndIf
          Next
          Window\Selected_Object = #Null
        EndIf
        
      Case #PB_EventType_LeftButtonUp
        R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X) / Window\Zoom
        R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y) / Window\Zoom
        Window\Move_Object = #Null
        
        ; #### Get the first element under the mouse.
        ForEach Node::Object()
          If R_X >= Node::Object()\X And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y And R_Y < Node::Object()\Y + Node::Object()\Height
            
            
            ForEach Node::Object()\Input()
              If R_X >= Node::Object()\X And R_X < Node::Object()\X + 16 And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 + 10
                If Window\Connection_Out
                  Node::Link_Connect(Window\Connection_Out, Node::Object()\Input())
                EndIf
                Break
              EndIf
            Next
            
            ForEach Node::Object()\Output()
              If R_X >= Node::Object()\X + Node::Object()\Width - 16 And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 + 10
                
                Break
              EndIf
            Next
            
            Break
          EndIf
        Next
        Window\Connection_Out = #Null
        Window\Redraw = #True
        
      Case #PB_EventType_MouseMove
        If Move_Active
          Window\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
          Window\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
          Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
          Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
          Window\Redraw = #True
        EndIf
        R_X = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X) / Window\Zoom
        R_Y = (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y) / Window\Zoom
        ForEach Node::Object()
          If Node::Object() = Window\Move_Object
            Node::Object()\X = R_X - Window\Move_X
            Node::Object()\Y = R_Y - Window\Move_Y
            If Window\Snapping
              Node::Object()\X = Round(Node::Object()\X / 50, #PB_Round_Nearest) * 50
              Node::Object()\Y = Round(Node::Object()\Y / 50, #PB_Round_Nearest) * 50
            EndIf
            Node::Object()\Redraw = #True
          EndIf
        Next
        ; #### Get the first element under the mouse.
        Window\Highlighted_InOut = #Null
        ForEach Node::Object()
          If R_X >= Node::Object()\X And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y And R_Y < Node::Object()\Y + Node::Object()\Height
            PushListPosition(Node::Object())
            ForEach Node::Object()
              If Node::Object() = Window\Highlighted_Object
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            PopListPosition(Node::Object())
            Window\Highlighted_Object = Node::Object()
            Node::Object()\Redraw = #True
            
            ForEach Node::Object()\Input()
              If R_X >= Node::Object()\X And R_X < Node::Object()\X + 16 And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Input()\i*20+4 + 10
                Window\Highlighted_InOut = Node::Object()\Input()
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            
            ForEach Node::Object()\Output()
              If R_X >= Node::Object()\X + Node::Object()\Width - 16 And R_X < Node::Object()\X + Node::Object()\Width And R_Y >= Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 And R_Y < Node::Object()\Y + #Text_Height + Node::Object()\Output()\i*20+4 + 10
                Window\Highlighted_InOut = Node::Object()\Output()
                Node::Object()\Redraw = #True
                Break
              EndIf
            Next
            
            Found = #True
            
            Break
          EndIf
        Next
        If Not Found
          ForEach Node::Object()
            If Node::Object() = Window\Highlighted_Object
              Node::Object()\Redraw = #True
              Break
            EndIf
          Next
          Window\Highlighted_Object = #Null
        EndIf
        If Window\Connection_Out
          Window\Connection_Out_X = R_X
          Window\Connection_Out_Y = R_Y
          Window\Redraw = #True
        EndIf
        
      Case #PB_EventType_MouseWheel
        Temp_Zoom = Pow(1.1, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
        If Window\Zoom * Temp_Zoom < 1/Pow(1.1, 20)
          Temp_Zoom = 1/Pow(1.1, 20) / Window\Zoom
        EndIf
        ;If Window\Zoom * Temp_Zoom > Pow(1.1, 10)
        ;  Temp_Zoom = Pow(1.1, 10) / Window\Zoom
        ;EndIf
        If Window\Zoom * Temp_Zoom > 1
          Temp_Zoom = 1 / Window\Zoom
        EndIf
        Window\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Window\Offset_X)
        Window\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Window\Offset_Y)
        Window\Zoom * Temp_Zoom
        
        Window\Redraw = #True
        
    EndSelect
    
  EndProcedure
  
  Procedure Event_Canvas_Drop()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected R_X.d, R_Y.d
    Protected *Node_Type.Node_Type::Object
    Protected *Object.Node::Object
    Protected i, Filename.s
    Protected *A.Node::Object, *B.Node::Object, *C.Node::Object
    
    R_X = (EventDropX() - Window\Offset_X) / Window\Zoom
    R_Y = (EventDropY() - Window\Offset_Y) / Window\Zoom
    Select EventDropType()
      Case #PB_Drop_Private
        Select EventDropPrivate()
          Case #DragDrop_Private_Node_New
            *Node_Type = Node_Type::Get(GetGadgetItemData(Window\TreeList, GetGadgetState(Window\TreeList)))
            If  *Node_Type
              *Object = *Node_Type\Function_Create(#True)
              If *Object
                *Object\X = R_X
                *Object\Y = R_Y
                If Window\Snapping
                  *Object\X = Round(*Object\X / 50, #PB_Round_Nearest) * 50
                  *Object\Y = Round(*Object\Y / 50, #PB_Round_Nearest) * 50
                EndIf
              EndIf
            EndIf
            
        EndSelect
        
      Case #PB_Drop_Files
        For i = 1 To CountString(EventDropFiles(), Chr(10)) + 1
          Filename = StringField(EventDropFiles(), i, Chr(10))
          If Filename
            *A = _Node_File::Create_And_Open(Filename)
            If *A
              *B = _Node_History::Create(#False)
              If *B
                *C = _Node_Editor::Create(#False)
                Node::Link_Connect(Node::Output_Get(*A, 0), Node::Input_Get(*B, 0))
                Node::Link_Connect(Node::Output_Get(*B, 0), Node::Input_Get(*C, 0))
                If *C And *C\Function_Window
                  *C\Function_Window(*C)
                EndIf
                Node_Editor::Align_Object(*A)
              EndIf
            EndIf
          EndIf
        Next
        
    EndSelect
  EndProcedure
  
  Procedure TreeList_Refresh()
    Protected Width = GadgetWidth(Window\TreeList)
    Protected Height = GadgetHeight(Window\TreeList)
    
    Protected NewList Category.s()
    Protected Found
    Protected i
    
    ForEach Node_Type::Object()
      Found = #False
      ForEach Category()
        If Category() = Node_Type::Object()\Category
          Found = #True
          Break
        EndIf
      Next
      If Not Found
        AddElement(Category())
        Category() = Node_Type::Object()\Category
      EndIf
    Next
    
    ClearGadgetItems(Window\TreeList)
    
    i = 0
    ForEach Category()
      AddGadgetItem(Window\TreeList, i, Category(), #Null, 0)
      i + 1
      ForEach Node_Type::Object()
        If Node_Type::Object()\Category = Category()
          AddGadgetItem(Window\TreeList, i, Node_Type::Object()\Name, #Null, 1)
          SetGadgetItemData(Window\TreeList, i, Node_Type::Object()\ID)
          i + 1
        EndIf
      Next
    Next
    
  EndProcedure
  
  Procedure Event_TreeList()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Select Event_Type
      Case #PB_EventType_DragStart
        DragPrivate(#DragDrop_Private_Node_New, #PB_Drag_Copy)
        
    EndSelect
    
  EndProcedure
  
  Procedure Event_SizeWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Protected ToolBarHeight
    
    ToolBarHeight = ToolBarHeight(Window\ToolBar)
    
    ResizeGadget(Window\Canvas, #PB_Ignore, #PB_Ignore, WindowWidth(Window\Window\ID)-150, WindowHeight(Window\Window\ID)-ToolBarHeight)
    ResizeGadget(Window\TreeList, WindowWidth(Window\Window\ID)-150, #PB_Ignore, 150, WindowHeight(Window\Window\ID)-ToolBarHeight)
    
    ;Window\Redraw = #True
    Canvas_Redraw()
  EndProcedure
  
  Procedure Event_ActivateWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    Window\Redraw = #True
    ;Canvas_Redraw()
  EndProcedure
  
  Procedure Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
    Protected Filename.s
    
    Select Event_Menu
      Case #Object_PopupMenu_Window
        ForEach Node::Object()
          If Node::Object() = Window\Menu_Object
            If Node::Object()\Function_Window
              Node::Object()\Function_Window(Node::Object())
            EndIf
            Break
          EndIf
        Next
        
      Case #Object_PopupMenu_Delete
        ForEach Node::Object()
          If Node::Object() = Window\Menu_Object
            Node::Delete(Node::Object())
            Window\Redraw = #True
            Break
          EndIf
        Next
        
      Case #Menu_Clear_Config
        Configuration_Clear()
        
      Case #Menu_Load_Config
        Filename = OpenFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
        If Filename
          Configuration_Load(Filename)
        EndIf
        
      Case #Menu_Save_Config
        Filename = SaveFileRequester("Load Configuration", "", "D3hex Configuration|*.D3hex", 0)
        If Filename
          Configuration_Save(Filename)
        EndIf
        
      Case #Menu_Grid_Snapping
        Window\Snapping = GetToolBarButtonState(Window\ToolBar, #Menu_Grid_Snapping)
        
      Case #Menu_Align
        ForEach Node::Object()
          If Node::Object() = Window\Selected_Object
            Align_Object(Node::Object())
            Break
          EndIf
        Next
        
    EndSelect
  EndProcedure
  
  Procedure Event_CloseWindow()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    
    ;Close()
    Window\Window_Close = #True
  EndProcedure
  
  Procedure Open()
    Protected ToolBarHeight
    
    If Window\Window = #Null
      Window\Window = Window::Create(#Null, "Node Editor", "Node Editor", #PB_Ignore, #PB_Ignore, 500, 500, Window::#Flag_Resizeable | Window::#Flag_Docked | Window::#Flag_MaximizeGadget, 20)
      
      ; #### Toolbar
      Window\ToolBar = CreateToolBar(#PB_Any, WindowID(Window\Window\ID))
      ToolBarImageButton(#Menu_Clear_Config, ImageID(Icons::Icon_Node_Clear_Config))
      ToolBarImageButton(#Menu_Load_Config, ImageID(Icons::Icon_Node_Load_Config))
      ToolBarImageButton(#Menu_Save_Config, ImageID(Icons::Icon_Node_Save_Config))
      ToolBarSeparator()
      ToolBarImageButton(#Menu_Grid_Snapping, ImageID(Icon_Grid_Snapping), #PB_ToolBar_Toggle)
      ToolBarImageButton(#Menu_Align, ImageID(Icon_Align))
      
      ToolBarToolTip(Window\ToolBar, #Menu_Clear_Config, "Clear node configuration")
      ToolBarToolTip(Window\ToolBar, #Menu_Load_Config, "Load node configuration")
      ToolBarToolTip(Window\ToolBar, #Menu_Save_Config, "Save node configuration")
      ToolBarToolTip(Window\ToolBar, #Menu_Grid_Snapping, "Toggle grid snapping")
      ToolBarToolTip(Window\ToolBar, #Menu_Align, "Align selected nodes")
      
      SetToolBarButtonState(Window\ToolBar, #Menu_Grid_Snapping, Window\Snapping)
      
      ToolBarHeight = ToolBarHeight(Window\ToolBar)
      
      Window\Canvas = CanvasGadget(#PB_Any, 0, ToolBarHeight, 350, 500-ToolBarHeight, #PB_Canvas_Keyboard)
      
      Window\TreeList = TreeGadget(#PB_Any, 350, ToolBarHeight, 150, 500-ToolBarHeight)
      
      BindGadgetEvent(Window\Canvas, @Event_Canvas())
      EnableGadgetDrop(Window\Canvas, #PB_Drop_Private, #PB_Drag_Copy, #DragDrop_Private_Node_New)
      EnableGadgetDrop(Window\Canvas, #PB_Drop_Files, #PB_Drag_Copy)
      BindEvent(#PB_Event_GadgetDrop, @Event_Canvas_Drop(), Window\Window\ID, Window\Canvas)
      
      BindGadgetEvent(Window\TreeList, @Event_TreeList())
      
      BindEvent(#PB_Event_SizeWindow, @Event_SizeWindow(), Window\Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Event_SizeWindow(), Window\Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Event_SizeWindow(), Window\Window\ID)
      BindEvent(#PB_Event_Menu, @Event_Menu(), Window\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Event_CloseWindow(), Window\Window\ID)
      
      Window\Redraw = #True
      Window\Types_Refresh = #True
      
    Else
      Window::Set_Active(Window\Window)
    EndIf
  EndProcedure
  
  Procedure Close()
    If Window\Window
      
      UnbindGadgetEvent(Window\Canvas, @Event_Canvas())
      UnbindEvent(#PB_Event_GadgetDrop, @Event_Canvas_Drop(), Window\Window\ID, Window\Canvas)
      
      UnbindGadgetEvent(Window\TreeList, @Event_TreeList())
      
      UnbindEvent(#PB_Event_SizeWindow, @Event_SizeWindow(), Window\Window\ID)
      ;UnbindEvent(#PB_Event_Repaint, @Event_SizeWindow(), Window\Window\ID)
      ;UnbindEvent(#PB_Event_RestoreWindow, @Event_SizeWindow(), Window\Window\ID)
      UnbindEvent(#PB_Event_Menu, @Event_Menu(), Window\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Event_CloseWindow(), Window\Window\ID)
      
      Window::Delete(Window\Window)
      Window\Window = #Null
    EndIf
  EndProcedure
  
  Procedure Main()
    If Not Window\Window
      ProcedureReturn #False
    EndIf
    
    ForEach Node::Object()
      If Node::Object()\Redraw
        Node::Object()\Redraw = #False
        Window\Redraw = #True
        Object_Redraw(Node::Object())
      EndIf
    Next
    
    If Window\Redraw
      Window\Redraw = #False
      Canvas_Redraw()
    EndIf
    
    If Window\Types_Refresh
      Window\Types_Refresh = #False
      TreeList_Refresh()
    EndIf
    
    If Window\Window_Close
      Window\Window_Close = #False
      Close()
    EndIf
  EndProcedure
  
  ; ##################################################### Initialisation ##############################################
  
  ; #### Object Popup-Menu
  Main\Object_PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
  MenuItem(#Object_PopupMenu_Window, "Open window")
  MenuBar()
  MenuItem(#Object_PopupMenu_Delete, "Delete node")
  
  ; ##################################################### Main ########################################################
  
  ; ##################################################### End #########################################################
  
  ; ##################################################### Data Sections ###############################################
  
  DataSection
    Icon_Load_Config:   : IncludeBinary "../Data/Icons/Node_Load_Config.png"
    Icon_Save_Config:   : IncludeBinary "../Data/Icons/Node_Save_Config.png"
    Icon_Grid_Snapping: : IncludeBinary "../Data/Icons/Node_Grid_Snapping.png"
    Icon_Align:         : IncludeBinary "../Data/Icons/Node_Align.png"
  EndDataSection
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 401
; FirstLine = 372
; Folding = ----
; EnableUnicode
; EnableXP