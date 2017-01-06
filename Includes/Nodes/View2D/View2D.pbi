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

DeclareModule _Node_View2D
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_View2D
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Macros ######################################################
  
  ; ################################################### Constants ###################################################
  
  #Timeout = 50        ; in ms
  
  #Chunk_Size_X = 512
  #Chunk_Size_Y = 128
  
  Enumeration
    #Menu_Settings
    #Menu_Normalize
    #Menu_Fit_X
    #Menu_Fit_Y
  EndEnumeration
  
  ; ################################################### Structures ##################################################
  
  Structure Temp_32
    A.a
    B.a
    C.a
    D.a
  EndStructure
  
  Structure ARGB
    B.a
    G.a
    R.a
    A.a
  EndStructure
  
  Structure Temp_32_Union
    StructureUnion
      ABCD.Temp_32
      RGBA.ARGB
      Long.l
    EndStructureUnion
  EndStructure
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Input_Channel_Chunk_ID
    X.q
    Y.q
  EndStructure
  
  Structure Input_Channel_Chunk
    ID.Input_Channel_Chunk_ID
    
    X.q
    Y.q
    
    Width.i
    Height.i
    
    Image_ID.i
    
    Redraw.l
  EndStructure
  
  Structure Input_Channel
    ; #### Data-Array properties
    Manually.i
    
    Bits_Per_Pixel.i  ; in Bit
    Pixel_Format.i
    
    Offset.q          ; in Bytes
    Line_Offset.q     ; in Bytes
    
    Reverse_Y.l
    
    Width.q           ; Width of the Image in Pixels
    Height.q          ; Calculated out of Bits_Per_Pixel and the data size
    
    ; #### Image Chunks
    List Chunk.Input_Channel_Chunk()
    *D3HT_Chunk
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ToolBar.i
    
    ; #### Gadget stuff
    Canvas_Data.i
    
    Redraw.l
    
    ScrollBar_X.i
    ScrollBar_Y.i
    
    Offset_X.d
    Offset_Y.d
    Zoom.d
    
    Timeout_Start.q
    
    ;Elements.q      ; Amount of Elements
    
    ;Connect.i       ; #True: Connect the data points with lines
    
    ; #### Other Windows
    *Settings_Window.Settings_Window
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Fonts #######################################################
  
  ; ################################################### Icons ... ###################################################
  
  Global Icon_Normalize = CatchImage(#PB_Any, ?Icon_Normalize)
  Global Icon_Fit_X = CatchImage(#PB_Any, ?Icon_Fit_X)
  Global Icon_Fit_Y = CatchImage(#PB_Any, ?Icon_Fit_Y)
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Window_Close(*Node.Node::Object)
  
  ; ################################################### Includes ####################################################
  
  XIncludeFile "View2D_Settings.pbi"
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Input.Node::Conn_Input
    Protected *Input_Channel.Input_Channel
    
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
    
    *Object\Zoom = 1
    
    ; #### Add Input
    *Input = Node::Input_Add(*Node)
    *Input\Custom_Data = AllocateStructure(Input_Channel)
    *Input\Function_Event = @Input_Event()
    
    *Input_Channel = *Input\Custom_Data
    *Input_Channel\D3HT_Chunk = D3HT::Create(SizeOf(Input_Channel_Chunk_ID), SizeOf(Integer), 65536)
    *Input_Channel\Pixel_Format = #PixelFormat_24_BGR
    *Input_Channel\Bits_Per_Pixel = 24
    *Input_Channel\Width = 1024
    
    ProcedureReturn *Node
  EndProcedure
  
  Procedure _Delete(*Node.Node::Object)
    Protected *Input_Channel.Input_Channel
    
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
        *Input_Channel = *Node\Input()\Custom_Data
        
        ForEach *Input_Channel\Chunk()
          FreeImage(*Input_Channel\Chunk()\Image_ID)
          *Input_Channel\Chunk()\Image_ID = #Null
        Next
        
        D3HT::Destroy(*Input_Channel\D3HT_Chunk)
        
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
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Zoom", NBT::#Tag_Double)      : NBT::Tag_Set_Double(*NBT_Tag, *Object\Zoom)
    
    *NBT_Tag_List = NBT::Tag_Add(*Parent_Tag, "Inputs", NBT::#Tag_List, NBT::#Tag_Compound)
    If *NBT_Tag_List
      ForEach *Node\Input()
        *Input_Channel = *Node\Input()\Custom_Data
        
        *NBT_Tag_Compound = NBT::Tag_Add(*NBT_Tag_List, "", NBT::#Tag_Compound)
        If *NBT_Tag_Compound
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Manually", NBT::#Tag_Long)        : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Manually)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Pixel_Format", NBT::#Tag_Long)    : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Pixel_Format)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Bits_Per_Pixel", NBT::#Tag_Long)  : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Bits_Per_Pixel)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Width", NBT::#Tag_Quad)           : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Width)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Offset", NBT::#Tag_Quad)          : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Offset)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Line_Offset", NBT::#Tag_Quad)     : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Line_Offset)
          *NBT_Tag = NBT::Tag_Add(*NBT_Tag_Compound, "Reverse_Y", NBT::#Tag_Byte)       : NBT::Tag_Set_Number(*NBT_Tag, *Input_Channel\Reverse_Y)
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
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Zoom")     : *Object\Zoom = NBT::Tag_Get_Double(*NBT_Tag)
    
    ; #### Delete all inputs
    While FirstElement(*Node\Input())
      If *Node\Input()\Custom_Data
        *Input_Channel = *Node\Input()\Custom_Data
        
        ForEach *Input_Channel\Chunk()
          FreeImage(*Input_Channel\Chunk()\Image_ID)
          *Input_Channel\Chunk()\Image_ID = #Null
        Next
        
        D3HT::Destroy(*Input_Channel\D3HT_Chunk)
        
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
            *Input_Channel\D3HT_Chunk = D3HT::Create(SizeOf(Input_Channel_Chunk_ID), SizeOf(Integer), 65536)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Manually")       : *Input_Channel\Manually = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Pixel_Format")   : *Input_Channel\Pixel_Format = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Bits_Per_Pixel") : *Input_Channel\Bits_Per_Pixel  = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Width")          : *Input_Channel\Width = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Offset")         : *Input_Channel\Offset = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Line_Offset")    : *Input_Channel\Line_Offset = NBT::Tag_Get_Number(*NBT_Tag)
            *NBT_Tag = NBT::Tag(*NBT_Tag_Compound, "Reverse_Y")      : *Input_Channel\Reverse_Y = NBT::Tag_Get_Number(*NBT_Tag)
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
    Protected *Input_Channel.Input_Channel = *Input\Custom_Data
    If Not *Input_Channel
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
        
        ForEach *Input_Channel\Chunk()
          *Input_Channel\Chunk()\Redraw = #True
        Next
        
    EndSelect
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Organize(*Node.Node::Object)
    Protected *Input_Channel.Input_Channel
    Protected Width, Height, Max_Width, Min_Width, Max_Height, Min_Height
    Protected ix, iy, ix_1, iy_1, ix_2, iy_2
    Protected X_M.d, Y_M.d, X_M_2.d, Y_M_2.d
    Protected X_R_1.d, Y_R_1.d, X_R_2.d, Y_R_2.d
    Protected Found
    Protected Input_Chunk_ID.Input_Channel_Chunk_ID
    Protected Bytes_Per_Line_1.q, Bytes_Per_Line_2.q
    Protected Old_Bits_Per_Pixel.i
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Window values
    Width = GadgetWidth(*Object\Canvas_Data)
    Height = GadgetHeight(*Object\Canvas_Data)
    
    ; #### Limit Zoom
    If *Object\Zoom < Pow(2, -8)
      *Object\Zoom = Pow(2, -8)
    EndIf
    
    ; #### Iterate throught each input
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        
        ; #### Get the settings from the data descriptor of the output
        If Not *Input_Channel\Manually
          ;*Input_Channel\Width = 1920  ; TODO: Get settings from data-descriptor
          ;*Input_Channel\Line_Offset = 0
          ;*Input_Channel\Pixel_Format = #PixelFormat_24_BGR
          ;*Input_Channel\Reverse_Y = #True
        EndIf
        
        If *Input_Channel\Width < 1
          *Input_Channel\Width = 1
        EndIf
        
        Old_Bits_Per_Pixel = *Input_Channel\Bits_Per_Pixel
        
        ; #### Set Bits_Per_Pixel accordingly to the Pixel_Format
        Select *Input_Channel\Pixel_Format
          Case #PixelFormat_1_Gray, #PixelFormat_1_Indexed
            *Input_Channel\Bits_Per_Pixel = 1
          Case #PixelFormat_2_Gray, #PixelFormat_2_Indexed
            *Input_Channel\Bits_Per_Pixel = 2
          Case #PixelFormat_4_Gray, #PixelFormat_4_Indexed
            *Input_Channel\Bits_Per_Pixel = 4
          Case #PixelFormat_8_Gray, #PixelFormat_8_Indexed
            *Input_Channel\Bits_Per_Pixel = 8
          Case #PixelFormat_16_Gray, #PixelFormat_16_RGB_555, #PixelFormat_16_RGB_565, #PixelFormat_16_ARGB_1555, #PixelFormat_16_Indexed
            *Input_Channel\Bits_Per_Pixel = 16
          Case #PixelFormat_24_RGB, #PixelFormat_24_BGR
            *Input_Channel\Bits_Per_Pixel = 24
          Case #PixelFormat_32_ARGB, #PixelFormat_32_ABGR
            *Input_Channel\Bits_Per_Pixel = 32
        EndSelect
        
        If *Input_Channel\Line_Offset < 1 - (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel) / 8
          *Input_Channel\Line_Offset = 1 - (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel) / 8
          SetGadgetState(*Object\Settings_Window\Spin_In[2], *Input_Channel\Line_Offset)
        EndIf
        
        Bytes_Per_Line_1 = (*Input_Channel\Width * Old_Bits_Per_Pixel) / 8 + *Input_Channel\Line_Offset
        Bytes_Per_Line_2 = (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel) / 8 + *Input_Channel\Line_Offset
        If Bytes_Per_Line_1 > 0 And Bytes_Per_Line_2 > 0
          *Object\Offset_Y = *Object\Offset_Y * Bytes_Per_Line_1 / Bytes_Per_Line_2
        EndIf
        
        *Input_Channel\Height = Quad_Divide_Ceil(Node::Input_Get_Size(*Node\Input()) * 8 - *Input_Channel\Offset * 8, (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel + *Input_Channel\Line_Offset * 8))
        
        ; #### Determine the square surrounding the images of all inputs
        If Max_Width < *Input_Channel\Width
          Max_Width = *Input_Channel\Width
        EndIf
        ;If Min_Width > 0
        ;  Min_Width = 0 ; To be continued when the images are moveable
        ;EndIf
        If *Input_Channel\Reverse_Y
          If Min_Height > - *Input_Channel\Height
            Min_Height = - *Input_Channel\Height
          EndIf
        Else
          If Max_Height < *Input_Channel\Height
            Max_Height = *Input_Channel\Height
          EndIf
        EndIf
        
        ; #### Delete chunks which are outside of the viewport
        ForEach *Input_Channel\Chunk()
          X_M.d = *Input_Channel\Chunk()\X * *Object\Zoom + *Object\Offset_X
          Y_M.d = *Input_Channel\Chunk()\Y * *Object\Zoom + *Object\Offset_Y
          X_M_2.d = (*Input_Channel\Chunk()\X + *Input_Channel\Chunk()\Width) * *Object\Zoom + *Object\Offset_X
          Y_M_2.d = (*Input_Channel\Chunk()\Y + *Input_Channel\Chunk()\Height) * *Object\Zoom + *Object\Offset_Y
          If X_M >= Width Or Y_M >= Height Or X_M_2 < 0 Or Y_M_2 < 0 Or *Input_Channel\Chunk()\X > *Input_Channel\Width Or *Input_Channel\Chunk()\Y > *Input_Channel\Height Or *Input_Channel\Chunk()\Y + *Input_Channel\Chunk()\Height < - *Input_Channel\Height
            If *Input_Channel\Chunk()\Image_ID
              FreeImage(*Input_Channel\Chunk()\Image_ID)
            EndIf
            D3HT::Element_Free(*Input_Channel\D3HT_Chunk, *Input_Channel\Chunk()\ID)
            DeleteElement(*Input_Channel\Chunk())
          EndIf
        Next
        
        ; #### Create new chunks
        X_R_1 = - *Object\Offset_X / *Object\Zoom
        Y_R_1 = - *Object\Offset_Y / *Object\Zoom
        X_R_2 = (Width - *Object\Offset_X) / *Object\Zoom
        Y_R_2 = (Height - *Object\Offset_Y) / *Object\Zoom
        
        If X_R_1 < 0 : X_R_1 = 1 : EndIf
        If X_R_2 > *Input_Channel\Width : X_R_2 = *Input_Channel\Width : EndIf
        If Y_R_1 < - *Input_Channel\Height : Y_R_1 = - *Input_Channel\Height : EndIf
        If Y_R_2 > *Input_Channel\Height : Y_R_2 = *Input_Channel\Height : EndIf
        
        ix_1 = Quad_Divide_Floor(X_R_1, #Chunk_Size_X)
        iy_1 = Quad_Divide_Floor(Y_R_1, #Chunk_Size_Y)
        
        ix_2 = Quad_Divide_Floor(X_R_2, #Chunk_Size_X)
        iy_2 = Quad_Divide_Floor(Y_R_2, #Chunk_Size_Y)
        
        If *Input_Channel\Reverse_Y
          If iy_2 > -1 : iy_2 = -1 : EndIf
        Else
          If iy_1 < 0 : iy_1 = 0 : EndIf
        EndIf
        
        ResetList(*Input_Channel\Chunk())
        
        For iy = iy_1 To iy_2
          For ix = ix_1 To ix_2
            ;Found = #False
            ;ForEach *Input_Channel\Chunk()
            ;  If *Input_Channel\Chunk()\X = ix * #Chunk_Size_X And *Input_Channel\Chunk()\Y = iy * #Chunk_Size_X
            ;    Found = #True
            ;    Break
            ;  EndIf
            ;Next
            ;If Not Found
            
            Input_Chunk_ID\X = ix
            Input_Chunk_ID\Y = iy
            
            If Not D3HT::Element_Get(*Input_Channel\D3HT_Chunk, Input_Chunk_ID, #Null)
              AddElement(*Input_Channel\Chunk())
              
              *Input_Channel\Chunk()\ID = Input_Chunk_ID
              *Input_Channel\Chunk()\X = ix * #Chunk_Size_X
              *Input_Channel\Chunk()\Y = iy * #Chunk_Size_Y
              *Input_Channel\Chunk()\Width = #Chunk_Size_X
              *Input_Channel\Chunk()\Height = #Chunk_Size_Y
              
              D3HT::Element_Set(*Input_Channel\D3HT_Chunk, Input_Chunk_ID, *Input_Channel\Chunk(), #False)
            EndIf
          Next
        Next
        
      EndIf
    Next
    
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_Maximum, Max_Width * *Object\Zoom)
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_Minimum, Min_Width * *Object\Zoom)
    SetGadgetAttribute(*Object\ScrollBar_X, #PB_ScrollBar_PageLength, Width)
    SetGadgetState(*Object\ScrollBar_X, -*Object\Offset_X)
    
    SetGadgetAttribute(*Object\ScrollBar_Y, #PB_ScrollBar_Maximum, Max_Height * *Object\Zoom)
    SetGadgetAttribute(*Object\ScrollBar_Y, #PB_ScrollBar_Minimum, Min_Height * *Object\Zoom)
    SetGadgetAttribute(*Object\ScrollBar_Y, #PB_ScrollBar_PageLength, Height)
    SetGadgetState(*Object\ScrollBar_Y, -*Object\Offset_Y)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Data(*Node.Node::Object)
    Protected *Data, *Metadata, Data_Size
    Protected *Pointer.Temp_32_Union, *Pointer_Metadata.Ascii
    Protected Width, Height
    Protected *Input_Channel.Input_Channel
    Protected ix, iy, X_Start.q, Y_Start.q
    Protected *DrawingBuffer, DrawingBufferPitch, *Drawing_Temp.ARGB
    Protected Color.l
    Protected Position.q
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Width = GadgetWidth(*Object\Canvas_Data)
    Height = GadgetHeight(*Object\Canvas_Data)
    
    ; #### Iterate throught each input
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        
        ForEach *Input_Channel\Chunk()
          If Not *Input_Channel\Chunk()\Image_ID Or *Input_Channel\Chunk()\Redraw
            *Input_Channel\Chunk()\Redraw = #False
            
            If *Input_Channel\Chunk()\Image_ID
              FreeImage(*Input_Channel\Chunk()\Image_ID)
              *Input_Channel\Chunk()\Image_ID = #Null
            EndIf
            
            *Input_Channel\Chunk()\Image_ID = CreateImage(#PB_Any, *Input_Channel\Chunk()\Width, *Input_Channel\Chunk()\Height, 32, #PB_Image_Transparent)
            If *Input_Channel\Chunk()\Image_ID
              If StartDrawing(ImageOutput(*Input_Channel\Chunk()\Image_ID))
                
                *DrawingBuffer = DrawingBuffer()
                DrawingBufferPitch = DrawingBufferPitch()
                
                DrawingMode(#PB_2DDrawing_AllChannels)
                ;Box(0, 0, #Chunk_Size_X, #Chunk_Size_Y, RGBA(Random(255),Random(255),Random(255),255))
                
                Data_Size = *Input_Channel\Chunk()\Width * *Input_Channel\Bits_Per_Pixel / 8
                *Data = AllocateMemory(Data_Size)
                *Metadata = AllocateMemory(Data_Size)
                
                X_Start = *Input_Channel\Chunk()\X
                For iy = 0 To *Input_Channel\Chunk()\Height - 1
                  If *Input_Channel\Reverse_Y
                    Y_Start = - *Input_Channel\Chunk()\Y - iy - 1
                  Else
                    Y_Start = *Input_Channel\Chunk()\Y + iy
                  EndIf
                  Position = (X_Start + Y_Start * *Input_Channel\Width) * *Input_Channel\Bits_Per_Pixel / 8 + Y_Start * *Input_Channel\Line_Offset + *Input_Channel\Offset
                  
                  FillMemory(*Metadata, Data_Size)
                  
                  If Node::Input_Get_Data(*Node\Input(), Position, Data_Size, *Data, *Metadata)
                    *Pointer = *Data
                    *Pointer_Metadata = *Metadata
                    
                    *Drawing_Temp = *DrawingBuffer + (*Input_Channel\Chunk()\Height - 1) * DrawingBufferPitch - iy * DrawingBufferPitch
                    
                    For ix = 0 To *Input_Channel\Chunk()\Width - 1
                      If X_Start + ix >= *Input_Channel\Width
                        Break
                      EndIf
                      
                      If *Pointer_Metadata\a & #Metadata_Readable
                        Select *Input_Channel\Pixel_Format
                          ;Case #PixelFormat_1_Gray
                          ;Case #PixelFormat_1_Indexed
                          ;Case #PixelFormat_2_Gray
                          ;Case #PixelFormat_2_Indexed
                          ;Case #PixelFormat_4_Gray
                          ;Case #PixelFormat_4_Indexed
                          Case #PixelFormat_8_Gray
                            *Drawing_Temp\R = *Pointer\ABCD\A
                            *Drawing_Temp\G = *Pointer\ABCD\A
                            *Drawing_Temp\B = *Pointer\ABCD\A
                            *Drawing_Temp\A = 255
                            *Pointer + 1 : *Pointer_Metadata + 1
                            
                          ;Case #PixelFormat_8_Indexed
                            
                          Case #PixelFormat_16_Gray
                            *Drawing_Temp\R = *Pointer\ABCD\B
                            *Drawing_Temp\G = *Pointer\ABCD\B
                            *Drawing_Temp\B = *Pointer\ABCD\B
                            *Drawing_Temp\A = 255
                            *Pointer + 2 : *Pointer_Metadata + 2
                            
                          Case #PixelFormat_16_RGB_555
                            *Drawing_Temp\R = (*Pointer\Long & $7C00) >> 7
                            *Drawing_Temp\G = (*Pointer\Long & $03E0) >> 2
                            *Drawing_Temp\B = (*Pointer\Long & $001F) << 3
                            *Drawing_Temp\A = 255
                            *Pointer + 2 : *Pointer_Metadata + 2
                            
                          Case #PixelFormat_16_RGB_565
                            *Drawing_Temp\R = (*Pointer\Long & $F800) >> 8
                            *Drawing_Temp\G = (*Pointer\Long & $07E0) >> 3
                            *Drawing_Temp\B = (*Pointer\Long & $001F) << 3
                            *Drawing_Temp\A = 255
                            *Pointer + 2 : *Pointer_Metadata + 2
                            
                          Case #PixelFormat_16_ARGB_1555
                            *Drawing_Temp\R = (*Pointer\Long & $7C00) >> 7
                            *Drawing_Temp\G = (*Pointer\Long & $03E0) >> 2
                            *Drawing_Temp\B = (*Pointer\Long & $001F) << 3
                            *Drawing_Temp\A = ((*Pointer\Long & $8000) >> 15) * 255 ;TODO: Check ARGB 1555 code!
                            *Pointer + 2 : *Pointer_Metadata + 2
                            
                          ;Case #PixelFormat_16_Indexed
                            
                          Case #PixelFormat_24_RGB
                            *Drawing_Temp\R = *Pointer\ABCD\A
                            *Drawing_Temp\G = *Pointer\ABCD\B
                            *Drawing_Temp\B = *Pointer\ABCD\C
                            *Drawing_Temp\A = 255
                            *Pointer + 3 : *Pointer_Metadata + 3
                            
                          Case #PixelFormat_24_BGR
                            *Drawing_Temp\R = *Pointer\ABCD\C
                            *Drawing_Temp\G = *Pointer\ABCD\B
                            *Drawing_Temp\B = *Pointer\ABCD\A
                            *Drawing_Temp\A = 255
                            *Pointer + 3 : *Pointer_Metadata + 3
                            
                          Case #PixelFormat_32_ARGB
                            *Drawing_Temp\R = *Pointer\ABCD\B
                            *Drawing_Temp\G = *Pointer\ABCD\C
                            *Drawing_Temp\B = *Pointer\ABCD\D
                            *Drawing_Temp\A = *Pointer\ABCD\A
                            *Pointer + 4 : *Pointer_Metadata + 4
                            
                          Case #PixelFormat_32_ABGR
                            *Drawing_Temp\R = *Pointer\ABCD\D
                            *Drawing_Temp\G = *Pointer\ABCD\C
                            *Drawing_Temp\B = *Pointer\ABCD\B
                            *Drawing_Temp\A = *Pointer\ABCD\A
                            *Pointer + 4 : *Pointer_Metadata + 4
                            
                        EndSelect
                        
                      EndIf
                      
                      *Drawing_Temp + 4
                    Next
                    
                  EndIf
                Next
                
                StopDrawing()
                
                FreeMemory(*Data)
                FreeMemory(*Metadata)
                
                If *Object\Zoom > 1
                  ResizeImage(*Input_Channel\Chunk()\Image_ID, *Input_Channel\Chunk()\Width * *Object\Zoom, *Input_Channel\Chunk()\Height * *Object\Zoom, #PB_Image_Raw)
                ElseIf *Object\Zoom < 1
                  ResizeImage(*Input_Channel\Chunk()\Image_ID, *Input_Channel\Chunk()\Width * *Object\Zoom, *Input_Channel\Chunk()\Height * *Object\Zoom, #PB_Image_Smooth)
                EndIf
                
              EndIf
              
              If *Object\Timeout_Start + 100 < ElapsedMilliseconds()
                *Object\Redraw = #True
                Break 2
              EndIf
              
            EndIf
            
          EndIf
        Next
        
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
    Protected X_M.d, Y_M.d
    Protected X_R.d, Y_R.d
    Protected i, ix, iy
    Protected *Input_Channel.Input_Channel
    Protected Division_Size_X.d, Division_Size_Y.d, Divisions_X.q, Divisions_Y.q
    Protected Text.s, Text_Width, Text_Height
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ; #### Data Canvas
    Width = GadgetWidth(*Object\Canvas_Data)
    Height = GadgetHeight(*Object\Canvas_Data)
    If Not StartDrawing(CanvasOutput(*Object\Canvas_Data))
      ProcedureReturn #False
    EndIf
    
    Box(0, 0, Width, Height, RGB(255,255,255))
    
    DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Outlined)
    
    ;FrontColor(RGB(0,0,255))
    ;BackColor(RGB(255,255,255))
    
    ; #### Draw Grid
    ;Division_Size_X = Pow(10,Round(Log10(1 / *Object\Zoom_X),#PB_Round_Up))*20
    ;Division_Size_Y = Pow(10,Round(Log10(1 / *Object\Zoom_Y),#PB_Round_Up))*20
    ;Divisions_X = Round(Width / *Object\Zoom_X, #PB_Round_Up) / Division_Size_X
    ;Divisions_Y = Round(Height / *Object\Zoom_Y, #PB_Round_Up) / Division_Size_Y
    ;For ix = 0 To Divisions_X
    ;  X_M = ix * Division_Size_X * *Object\Zoom_X + *Object\Offset_X - Round(*Object\Offset_X / (Division_Size_X * *Object\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object\Zoom_X)
    ;  Line(X_M, 0, 0, Height, RGB(230,230,230))
    ;Next
    ;For iy = -Divisions_Y/2-1 To Divisions_Y/2
    ;  Y_M = iy * Division_Size_Y * *Object\Zoom_Y + Height/2 + *Object\Offset_Y - Round(*Object\Offset_Y / (Division_Size_Y * *Object\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object\Zoom_Y)
    ;  Line(0, Y_M, Width, 0, RGB(230,230,230))
    ;Next
    ;Line(0, *Object\Offset_Y + Height/2, Width, 0, RGB(180,180,180))
    ;Line(*Object\Offset_X, 0, 0, Height, RGB(180,180,180))
    
    ; #### Go throught each input
    ;Protected *Buffer     = DrawingBuffer()             ; Get the start address of the screen buffer
    ;Protected Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
    ForEach *Node\Input()
      *Input_Channel = *Node\Input()\Custom_Data
      If *Input_Channel
        
        ForEach *Input_Channel\Chunk()
          X_M = *Input_Channel\Chunk()\X * *Object\Zoom + *Object\Offset_X
          Y_M = *Input_Channel\Chunk()\Y * *Object\Zoom + *Object\Offset_Y
          
          If *Input_Channel\Chunk()\Image_ID
            If ImageWidth(*Input_Channel\Chunk()\Image_ID) <> *Input_Channel\Chunk()\Width * *Object\Zoom Or ImageHeight(*Input_Channel\Chunk()\Image_ID) <> *Input_Channel\Chunk()\Height * *Object\Zoom
              ResizeImage(*Input_Channel\Chunk()\Image_ID, *Input_Channel\Chunk()\Width * *Object\Zoom, *Input_Channel\Chunk()\Height * *Object\Zoom, #PB_Image_Raw)
              *Input_Channel\Chunk()\Redraw = #True
              *Object\Redraw = #True
            EndIf
            
            If ImageID(*Input_Channel\Chunk()\Image_ID)
              DrawImage(ImageID(*Input_Channel\Chunk()\Image_ID), X_M, Y_M)
            EndIf
          EndIf
          
          If *Input_Channel\Chunk()\Redraw Or *Input_Channel\Chunk()\Image_ID = #Null
            Box(X_M, Y_M, *Input_Channel\Chunk()\Width * *Object\Zoom, *Input_Channel\Chunk()\Height * *Object\Zoom, RGBA(255,0,0,50))
          EndIf
        Next
        
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
    Protected R_X.q, R_Y.q
    Protected Key, Modifiers
    Protected Temp_Zoom.d
    Protected i
    Static Move_Active
    Static Move_X, Move_Y
    Protected *Input_Channel.Input_Channel
    
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
        ; #### Calculate Position and stuff
        R_X = Round((GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object\Offset_X) / *Object\Zoom, #PB_Round_Down)
        R_Y = Round((GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - *Object\Offset_Y) / *Object\Zoom, #PB_Round_Down)
        StatusBarText(Main::Window\StatusBar_ID, 0, "X: "+Str(R_X)+" Y:"+Str(R_Y))
        If FirstElement(*Node\Input())
          *Input_Channel = *Node\Input()\Custom_Data
          If *Input_Channel
            If *Input_Channel\Reverse_Y
              StatusBarText(Main::Window\StatusBar_ID, 1, "Position (First image): "+Str((R_X * *Input_Channel\Bits_Per_Pixel + (-1-R_Y) * (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel + *Input_Channel\Line_Offset * 8)) / 8 + *Input_Channel\Offset)+" B")
            Else
              StatusBarText(Main::Window\StatusBar_ID, 1, "Position (First image): "+Str((R_X * *Input_Channel\Bits_Per_Pixel + R_Y * (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel + *Input_Channel\Line_Offset * 8)) / 8 + *Input_Channel\Offset)+" B")
            EndIf
          EndIf
        EndIf
        
      Case #PB_EventType_MouseWheel
        Temp_Zoom = Pow(2, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
        If *Object\Zoom * Temp_Zoom < Pow(2, -8)
          Temp_Zoom = Pow(2, -8) / *Object\Zoom
        EndIf
        If *Object\Zoom * Temp_Zoom > Pow(2, 4)
          Temp_Zoom = Pow(2, 4) / *Object\Zoom
        EndIf
        ;If *Object\Zoom_X * Temp_Zoom > 1
        ;  Temp_Zoom = 1 / *Object\Zoom_X
        ;EndIf
        *Object\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object\Offset_X)
        *Object\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - *Object\Offset_Y)
        *Object\Zoom * Temp_Zoom
        
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
          SetActiveGadget(*Object\Canvas_Data)
        EndIf
        
      Case #WM_VSCROLL
        Select wParam & $FFFF
          Case #SB_THUMBTRACK
            SCROLLINFO\fMask = #SIF_TRACKPOS
            SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
            GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
            *Object\Offset_Y = - SCROLLINFO\nTrackPos
            *Object\Redraw = #True
          Case #SB_PAGEUP
            *Object\Offset_Y + GadgetHeight(*Object\Canvas_Data)
            *Object\Redraw = #True
          Case #SB_PAGEDOWN
            *Object\Offset_Y - GadgetHeight(*Object\Canvas_Data)
            *Object\Redraw = #True
          Case #SB_LINEUP
            *Object\Offset_Y + 100
            *Object\Redraw = #True
          Case #SB_LINEDOWN
            *Object\Offset_Y - 100
            *Object\Redraw = #True
        EndSelect
        If *Object\Redraw
          *Object\Redraw = #False
          Organize(*Node)
          Get_Data(*Node)
          Canvas_Redraw(*Node)
          SetActiveGadget(*Object\Canvas_Data)
        EndIf
        
    EndSelect
    
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
    Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, ScrollBar_X_Height, ScrollBar_Y_Width
    
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
    
    ScrollBar_X_Height = 17
    ScrollBar_Y_Width = 17
    
    Data_Width = Width - ScrollBar_Y_Width
    Data_Height = Height - ScrollBar_X_Height - ToolBarHeight
    
    ; #### Add to offset
    *Object\Offset_X + (Data_Width - GadgetWidth(*Object\Canvas_Data)) / 2
    *Object\Offset_Y + (Data_Height - GadgetHeight(*Object\Canvas_Data)) / 2
    
    ; #### Gadgets
    ResizeGadget(*Object\ScrollBar_X, 0, Data_Height+ToolBarHeight, Data_Width, ScrollBar_X_Height)
    ResizeGadget(*Object\ScrollBar_Y, Data_Width, ToolBarHeight, ScrollBar_Y_Width, Data_Height)
    
    ResizeGadget(*Object\Canvas_Data, 0, ToolBarHeight, Data_Width, Data_Height)
    
    Canvas_Redraw(*Node)
    *Object\Redraw = #True
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
    Protected Min_Zoom.d, Temp_Zoom.d
    Protected X_Max.d, X_Min.d, Y_Max.d, Y_Min.d
    
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
        
      Case #Menu_Normalize
        *Object\Offset_X - (1.0/*Object\Zoom - 1) * (GadgetWidth(*Object\Canvas_Data)/2 - *Object\Offset_X)
        *Object\Offset_Y - (1.0/*Object\Zoom - 1) * (GadgetHeight(*Object\Canvas_Data)/2 - *Object\Offset_Y)
        *Object\Zoom = 1
        *Object\Redraw = #True
        
      Case #Menu_Fit_X
        ForEach *Node\Input()
          *Input_Channel = *Node\Input()\Custom_Data
          If *Input_Channel
            If X_Max < *Input_Channel\Width : X_Max = *Input_Channel\Width : EndIf
            If *Input_Channel\Reverse_Y
              If Y_Min > -*Input_Channel\Height : Y_Min = -*Input_Channel\Height : EndIf
            Else
              If Y_Max < *Input_Channel\Height : Y_Max = *Input_Channel\Height : EndIf
            EndIf
            Temp_Zoom = GadgetWidth(*Object\Canvas_Data) / *Input_Channel\Width
            Temp_Zoom = Pow(2, Round(Log(Temp_Zoom)/Log(2), #PB_Round_Down))
            If Min_Zoom > Temp_Zoom Or ListIndex(*Node\Input()) = 0
              Min_Zoom = Temp_Zoom
            EndIf
          EndIf
        Next
        If Min_Zoom > 0
          *Object\Zoom = Min_Zoom
        EndIf
        *Object\Offset_X = GadgetWidth(*Object\Canvas_Data)/2 - (X_Max + X_Min)/2 * *Object\Zoom
        *Object\Offset_Y = GadgetHeight(*Object\Canvas_Data)/2 - (Y_Max + Y_Min)/2 * *Object\Zoom
        *Object\Redraw = #True
        
      Case #Menu_Fit_Y
        ForEach *Node\Input()
          *Input_Channel = *Node\Input()\Custom_Data
          If *Input_Channel
            If X_Max < *Input_Channel\Width : X_Max = *Input_Channel\Width : EndIf
            If *Input_Channel\Reverse_Y
              If Y_Min > -*Input_Channel\Height : Y_Min = -*Input_Channel\Height : EndIf
            Else
              If Y_Max < *Input_Channel\Height : Y_Max = *Input_Channel\Height : EndIf
            EndIf
            Temp_Zoom = GadgetHeight(*Object\Canvas_Data) / *Input_Channel\Height
            Temp_Zoom = Pow(2, Round(Log(Temp_Zoom)/Log(2), #PB_Round_Down))
            If Min_Zoom > Temp_Zoom Or ListIndex(*Node\Input()) = 0
              Min_Zoom = Temp_Zoom
            EndIf
          EndIf
        Next
        If Min_Zoom > 0
          *Object\Zoom = Min_Zoom
        EndIf
        *Object\Offset_X = GadgetWidth(*Object\Canvas_Data)/2 - (X_Max + X_Min)/2 * *Object\Zoom
        *Object\Offset_Y = GadgetHeight(*Object\Canvas_Data)/2 - (Y_Max + Y_Min)/2 * *Object\Zoom
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
    Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, ScrollBar_X_Height, ScrollBar_Y_Width
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If *Object\Window = #Null
      
      Width = 500
      Height = 500
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, #PB_Ignore, #PB_Ignore, Width, Height, Window::#Flag_Resizeable | Window::#Flag_Docked | Window::#Flag_MaximizeGadget, 10, Main\Node_Type\UID)
      
      ; #### Toolbar
      *Object\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object\Window\ID))
      ToolBarImageButton(#Menu_Settings, ImageID(Icons::Icon_Gear))
      ToolBarImageButton(#Menu_Normalize, ImageID(Icon_Normalize))
      ToolBarImageButton(#Menu_Fit_X, ImageID(Icon_Fit_X))
      ToolBarImageButton(#Menu_Fit_Y, ImageID(Icon_Fit_Y))
      
      ToolBarToolTip(*Object\ToolBar, #Menu_Settings, "Settings")
      ToolBarToolTip(*Object\ToolBar, #Menu_Normalize, "Normalize zoom")
      ToolBarToolTip(*Object\ToolBar, #Menu_Fit_X, "Fit image horizontally")
      ToolBarToolTip(*Object\ToolBar, #Menu_Fit_Y, "Fit image vertically")
      
      ToolBarHeight = ToolBarHeight(*Object\ToolBar)
      
      ScrollBar_X_Height = 17
      ScrollBar_Y_Width = 17
      
      Data_Width = Width - ScrollBar_Y_Width
      Data_Height = Height - ScrollBar_X_Height - ToolBarHeight
      
      ; #### Gadgets
      *Object\ScrollBar_X = ScrollBarGadget(#PB_Any, 0, Data_Height+ToolBarHeight, Data_Width, ScrollBar_X_Height, 0, 10, 1)
      *Object\ScrollBar_Y = ScrollBarGadget(#PB_Any, Data_Width, ToolBarHeight, ScrollBar_Y_Width, Data_Height, 0, 10, 1, #PB_ScrollBar_Vertical)
      
      *Object\Canvas_Data = CanvasGadget(#PB_Any, 0, 0, Data_Width, Data_Height, #PB_Canvas_Keyboard)
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_Repaint, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_RestoreWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      ;BindEvent(#PB_Event_ActivateWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      BindGadgetEvent(*Object\Canvas_Data, @Window_Event_Canvas_Data())
      
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
        *Object\Timeout_Start = ElapsedMilliseconds()
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
    Main\Node_Type\Name = "View2D"
    Main\Node_Type\UID = "D3VIEW2D"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,12,14,21,55,00)
    Main\Node_Type\Date_Modification = Date(2015,01,05,18,38,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Viewer for 2D Data, mostly images."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 0900
  EndIf
  
  ; #### Object Popup-Menu
  ;Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
  ;MenuItem(#PopupMenu_Copy_Position, "Copy Address")
  ;MenuItem(#PopupMenu_Lock_To_Line, "Lock to this line")
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
  ; ################################################### Data Sections ###############################################
  
  DataSection
    Icon_Normalize:   : IncludeBinary "../../../Data/Icons/Graph_Normalize.png"
    Icon_Fit_X:       : IncludeBinary "../../../Data/Icons/Image_Fit_X.png"
    Icon_Fit_Y:       : IncludeBinary "../../../Data/Icons/Image_Fit_Y.png"
  EndDataSection
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 855
; FirstLine = 840
; Folding = ----
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant