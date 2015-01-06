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

; ##################################################### Prototypes ##################################################

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

#Object_View2D_Timeout = 50        ; in ms

#Object_View2D_Chunk_Size_X = 512
#Object_View2D_Chunk_Size_Y = 128

Enumeration
  #Object_View2D_Menu_Settings
  #Object_View2D_Menu_Normalize
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_View2D_32
  A.a
  B.a
  C.a
  D.a
EndStructure

Structure Object_View2D_ARGB
  B.a
  G.a
  R.a
  A.a
EndStructure

Structure Object_View2D_32_Union
  StructureUnion
    ABCD.Object_View2D_32
    RGBA.Object_View2D_ARGB
    Long.l
  EndStructureUnion
EndStructure

Structure Object_View2D_Main
  *Object_Type.Object_Type
EndStructure
Global Object_View2D_Main.Object_View2D_Main

Structure Object_View2D_Input_Chunk_ID
  X.q
  Y.q
EndStructure

Structure Object_View2D_Input_Chunk
  ID.Object_View2D_Input_Chunk_ID
  
  X.q
  Y.q
  
  Width.i
  Height.i
  
  Image_ID.i
  
  Redraw.l
EndStructure

Structure Object_View2D_Input
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
  List Chunk.Object_View2D_Input_Chunk()
  *D3HT_Chunk
EndStructure

Structure Object_View2D
  *Window.Window
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
  *Settings.Object_View2D_Settings
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Icons ... ###################################################

Global Object_View2D_Icon_Normalize = CatchImage(#PB_Any, ?Object_View2D_Icon_Normalize)

; ##################################################### Declares ####################################################

Declare   Object_View2D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_View2D_Main(*Object.Object)
Declare   _Object_View2D_Delete(*Object.Object)
Declare   Object_View2D_Window_Open(*Object.Object)

Declare   Object_View2D_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_View2D_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_View2D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_View2D_Window_Close(*Object.Object)

; ##################################################### Includes ####################################################

XIncludeFile "Object_View2D_Settings.pbi"

; ##################################################### Procedures ##################################################

Procedure Object_View2D_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_View2D.Object_View2D
  Protected *Object_Input.Object_Input
  Protected *Object_View2D_Input.Object_View2D_Input
  
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  *Object\Type = Object_View2D_Main\Object_Type
  *Object\Type_Base = Object_View2D_Main\Object_Type
  
  *Object\Function_Delete = @_Object_View2D_Delete()
  *Object\Function_Main = @Object_View2D_Main()
  *Object\Function_Window = @Object_View2D_Window_Open()
  *Object\Function_Configuration_Get = @Object_View2D_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_View2D_Configuration_Set()
  
  *Object\Name = "View2D"
  *Object\Color = RGBA(200, 127, 127, 255)
  
  *Object\Custom_Data = AllocateStructure(Object_View2D)
  *Object_View2D = *Object\Custom_Data
  
  *Object_View2D\Settings = AllocateStructure(Object_View2D_Settings)
  
  *Object_View2D\Zoom = 1
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Custom_Data = AllocateStructure(Object_View2D_Input)
  *Object_Input\Function_Event = @Object_View2D_Input_Event()
  
  *Object_View2D_Input = *Object_Input\Custom_Data
  *Object_View2D_Input\D3HT_Chunk = D3HT_Create(SizeOf(Object_View2D_Input_Chunk_ID), SizeOf(Integer), 65536)
  *Object_View2D_Input\Pixel_Format = #PixelFormat_24_BGR
  *Object_View2D_Input\Bits_Per_Pixel = 24
  *Object_View2D_Input\Width = 1024
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_View2D_Delete(*Object.Object)
  Protected *Object_View2D_Input.Object_View2D_Input
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  Object_View2D_Window_Close(*Object)
  Object_View2D_Settings_Window_Close(*Object)
  
  ForEach *Object\Input()
    If *Object\Input()\Custom_Data
      *Object_View2D_Input = *Object\Input()\Custom_Data
      
      ForEach *Object_View2D_Input\Chunk()
        FreeImage(*Object_View2D_Input\Chunk()\Image_ID)
        *Object_View2D_Input\Chunk()\Image_ID = #Null
      Next
      
      D3HT_Destroy(*Object_View2D_Input\D3HT_Chunk)
      
      FreeStructure(*Object\Input()\Custom_Data)
      *Object\Input()\Custom_Data = #Null
    EndIf
  Next
  
  FreeStructure(*Object_View2D\Settings)
  *Object_View2D\Settings = #Null
  
  FreeStructure(*Object_View2D)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  Protected *NBT_Tag.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *Object_View2D_Input.Object_View2D_Input
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Offset_X", #NBT_Tag_Double)  : NBT_Tag_Set_Double(*NBT_Tag, *Object_View2D\Offset_X)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Offset_Y", #NBT_Tag_Double)  : NBT_Tag_Set_Double(*NBT_Tag, *Object_View2D\Offset_Y)
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Zoom", #NBT_Tag_Double)      : NBT_Tag_Set_Double(*NBT_Tag, *Object_View2D\Zoom)
  
  *NBT_Tag_List = NBT_Tag_Add(*Parent_Tag, "Inputs", #NBT_Tag_List, #NBT_Tag_Compound)
  If *NBT_Tag_List
    ForEach *Object\Input()
      *Object_View2D_Input = *Object\Input()\Custom_Data
      
      *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_List, "", #NBT_Tag_Compound)
      If *NBT_Tag_Compound
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Manually", #NBT_Tag_Long)        : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Manually)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Pixel_Format", #NBT_Tag_Long)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Pixel_Format)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Bits_Per_Pixel", #NBT_Tag_Long)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Bits_Per_Pixel)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Width", #NBT_Tag_Quad)           : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Width)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Offset", #NBT_Tag_Quad)          : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Offset)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Line_Offset", #NBT_Tag_Quad)     : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Line_Offset)
        *NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Reverse_Y", #NBT_Tag_Byte)       : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Reverse_Y)
      EndIf
    Next
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  Protected *NBT_Tag.NBT_Tag
  Protected *NBT_Tag_List.NBT_Tag
  Protected *NBT_Tag_Compound.NBT_Tag
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected *Object_Input.Object_Input
  Protected Elements, i
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Offset_X") : *Object_View2D\Offset_X = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Offset_Y") : *Object_View2D\Offset_Y = NBT_Tag_Get_Double(*NBT_Tag)
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Zoom")     : *Object_View2D\Zoom = NBT_Tag_Get_Double(*NBT_Tag)
  
  ; #### Delete all inputs
  While FirstElement(*Object\Input())
    If *Object\Input()\Custom_Data
      *Object_View2D_Input = *Object\Input()\Custom_Data
      
      ForEach *Object_View2D_Input\Chunk()
        FreeImage(*Object_View2D_Input\Chunk()\Image_ID)
        *Object_View2D_Input\Chunk()\Image_ID = #Null
      Next
      
      D3HT_Destroy(*Object_View2D_Input\D3HT_Chunk)
      
      FreeStructure(*Object\Input()\Custom_Data)
      *Object\Input()\Custom_Data = #Null
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
        *Object_Input\Custom_Data = AllocateStructure(Object_View2D_Input)
        *Object_Input\Function_Event = @Object_View2D_Input_Event()
        *Object_View2D_Input = *Object_Input\Custom_Data
        If *Object_View2D_Input
          *Object_View2D_Input\D3HT_Chunk = D3HT_Create(SizeOf(Object_View2D_Input_Chunk_ID), SizeOf(Integer), 65536)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Manually")       : *Object_View2D_Input\Manually = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Pixel_Format")   : *Object_View2D_Input\Pixel_Format = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Bits_Per_Pixel") : *Object_View2D_Input\Bits_Per_Pixel  = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Width")          : *Object_View2D_Input\Width = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Offset")         : *Object_View2D_Input\Offset = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Line_Offset")    : *Object_View2D_Input\Line_Offset = NBT_Tag_Get_Number(*NBT_Tag)
          *NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Reverse_Y")      : *Object_View2D_Input\Reverse_Y = NBT_Tag_Get_Number(*NBT_Tag)
        EndIf
        
      EndIf
    Next
    
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Event(*Object.Object, *Object_Event.Object_Event)
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
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

Procedure Object_View2D_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object_Input\Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Input.Object_View2D_Input = *Object_Input\Custom_Data
  If Not *Object_View2D_Input
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update
      *Object_View2D\Redraw = #True
      
      ForEach *Object_View2D_Input\Chunk()
        *Object_View2D_Input\Chunk()\Redraw = #True
      Next
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Organize(*Object.Object)
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected Width, Height, Max_Width, Min_Width, Max_Height, Min_Height
  Protected ix, iy, ix_1, iy_1, ix_2, iy_2
  Protected X_M.d, Y_M.d, X_M_2.d, Y_M_2.d
  Protected X_R_1.d, Y_R_1.d, X_R_2.d, Y_R_2.d
  Protected Found
  Protected Object_View2D_Input_Chunk_ID.Object_View2D_Input_Chunk_ID
  Protected Bytes_Per_Line_1.q, Bytes_Per_Line_2.q
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  ; #### Window values
  Width = GadgetWidth(*Object_View2D\Canvas_Data)
  Height = GadgetHeight(*Object_View2D\Canvas_Data)
  
  ; #### Limit Zoom
  If *Object_View2D\Zoom < Pow(2, -8)
    *Object_View2D\Zoom = Pow(2, -8)
  EndIf
  
  ; #### Iterate throught each input
  ForEach *Object\Input()
    *Object_View2D_Input = *Object\Input()\Custom_Data
    If *Object_View2D_Input
      
      ; #### Get the settings from the data descriptor of the output
      If Not *Object_View2D_Input\Manually
        ;*Object_View2D_Input\Width = 1920  ; ################################################ Delete Me!
        ;*Object_View2D_Input\Line_Offset = 0
        ;*Object_View2D_Input\Pixel_Format = #PixelFormat_24_BGR
        ;*Object_View2D_Input\Reverse_Y = #True
      EndIf
      
      If *Object_View2D_Input\Width < 1
        *Object_View2D_Input\Width = 1
      EndIf
      
      Bytes_Per_Line_1 = (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel) / 8 + *Object_View2D_Input\Line_Offset
      
      ; #### Set Bits_Per_Pixel accordingly to the Pixel_Format
      Select *Object_View2D_Input\Pixel_Format
        Case #PixelFormat_1_Gray, #PixelFormat_1_Indexed
          *Object_View2D_Input\Bits_Per_Pixel = 1
        Case #PixelFormat_2_Gray, #PixelFormat_2_Indexed
          *Object_View2D_Input\Bits_Per_Pixel = 2
        Case #PixelFormat_4_Gray, #PixelFormat_4_Indexed
          *Object_View2D_Input\Bits_Per_Pixel = 4
        Case #PixelFormat_8_Gray, #PixelFormat_8_Indexed
          *Object_View2D_Input\Bits_Per_Pixel = 8
        Case #PixelFormat_16_Gray, #PixelFormat_16_RGB_555, #PixelFormat_16_RGB_565, #PixelFormat_16_ARGB_1555, #PixelFormat_16_Indexed
          *Object_View2D_Input\Bits_Per_Pixel = 16
        Case #PixelFormat_24_RGB, #PixelFormat_24_BGR
          *Object_View2D_Input\Bits_Per_Pixel = 24
        Case #PixelFormat_32_ARGB, #PixelFormat_32_ABGR
          *Object_View2D_Input\Bits_Per_Pixel = 32
      EndSelect
      
      Bytes_Per_Line_2 = (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel) / 8 + *Object_View2D_Input\Line_Offset
      *Object_View2D\Offset_Y = (*Object_View2D\Offset_Y) * Bytes_Per_Line_1 / Bytes_Per_Line_2
      
      *Object_View2D_Input\Height = Quad_Divide_Ceil(Object_Input_Get_Size(*Object\Input()) * 8 - *Object_View2D_Input\Offset * 8, (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel + *Object_View2D_Input\Line_Offset * 8))
      
      ; #### Determine the square surrounding the images of all inputs
      If Max_Width < *Object_View2D_Input\Width
        Max_Width = *Object_View2D_Input\Width
      EndIf
      ;If Min_Width > 0
      ;  Min_Width = 0 ; To be continued when the images are moveable
      ;EndIf
      If *Object_View2D_Input\Reverse_Y
        If Min_Height > - *Object_View2D_Input\Height
          Min_Height = - *Object_View2D_Input\Height
        EndIf
      Else
        If Max_Height < *Object_View2D_Input\Height
          Max_Height = *Object_View2D_Input\Height
        EndIf
      EndIf
      
      ; #### Delete chunks which are outside of the viewport
      ForEach *Object_View2D_Input\Chunk()
        X_M.d = *Object_View2D_Input\Chunk()\X * *Object_View2D\Zoom + *Object_View2D\Offset_X
        Y_M.d = *Object_View2D_Input\Chunk()\Y * *Object_View2D\Zoom + *Object_View2D\Offset_Y
        X_M_2.d = (*Object_View2D_Input\Chunk()\X + *Object_View2D_Input\Chunk()\Width) * *Object_View2D\Zoom + *Object_View2D\Offset_X
        Y_M_2.d = (*Object_View2D_Input\Chunk()\Y + *Object_View2D_Input\Chunk()\Height) * *Object_View2D\Zoom + *Object_View2D\Offset_Y
        If X_M >= Width Or Y_M >= Height Or X_M_2 < 0 Or Y_M_2 < 0 Or *Object_View2D_Input\Chunk()\X > *Object_View2D_Input\Width Or *Object_View2D_Input\Chunk()\Y > *Object_View2D_Input\Height Or *Object_View2D_Input\Chunk()\Y + *Object_View2D_Input\Chunk()\Height < - *Object_View2D_Input\Height
          If *Object_View2D_Input\Chunk()\Image_ID
            FreeImage(*Object_View2D_Input\Chunk()\Image_ID)
          EndIf
          D3HT_Element_Free(*Object_View2D_Input\D3HT_Chunk, *Object_View2D_Input\Chunk()\ID)
          DeleteElement(*Object_View2D_Input\Chunk())
        EndIf
      Next
      
      ; #### Create new chunks
      X_R_1 = - *Object_View2D\Offset_X / *Object_View2D\Zoom
      Y_R_1 = - *Object_View2D\Offset_Y / *Object_View2D\Zoom
      X_R_2 = (Width - *Object_View2D\Offset_X) / *Object_View2D\Zoom
      Y_R_2 = (Height - *Object_View2D\Offset_Y) / *Object_View2D\Zoom
      
      If X_R_1 < 0 : X_R_1 = 1 : EndIf
      If X_R_2 > *Object_View2D_Input\Width : X_R_2 = *Object_View2D_Input\Width : EndIf
      If Y_R_1 < - *Object_View2D_Input\Height : Y_R_1 = - *Object_View2D_Input\Height : EndIf
      If Y_R_2 > *Object_View2D_Input\Height : Y_R_2 = *Object_View2D_Input\Height : EndIf
      
      ix_1 = Quad_Divide_Floor(X_R_1, #Object_View2D_Chunk_Size_X)
      iy_1 = Quad_Divide_Floor(Y_R_1, #Object_View2D_Chunk_Size_Y)
      
      ix_2 = Quad_Divide_Floor(X_R_2, #Object_View2D_Chunk_Size_X)
      iy_2 = Quad_Divide_Floor(Y_R_2, #Object_View2D_Chunk_Size_Y)
      
      If *Object_View2D_Input\Reverse_Y
        If iy_2 > -1 : iy_2 = -1 : EndIf
      Else
        If iy_1 < 0 : iy_1 = 0 : EndIf
      EndIf
      
      ResetList(*Object_View2D_Input\Chunk())
      
      For iy = iy_1 To iy_2
        For ix = ix_1 To ix_2
          ;Found = #False
          ;ForEach *Object_View2D_Input\Chunk()
          ;  If *Object_View2D_Input\Chunk()\X = ix * #Object_View2D_Chunk_Size_X And *Object_View2D_Input\Chunk()\Y = iy * #Object_View2D_Chunk_Size_X
          ;    Found = #True
          ;    Break
          ;  EndIf
          ;Next
          ;If Not Found
          
          Object_View2D_Input_Chunk_ID\X = ix
          Object_View2D_Input_Chunk_ID\Y = iy
          
          If Not D3HT_Element_Get(*Object_View2D_Input\D3HT_Chunk, Object_View2D_Input_Chunk_ID, #Null)
            AddElement(*Object_View2D_Input\Chunk())
            
            *Object_View2D_Input\Chunk()\ID = Object_View2D_Input_Chunk_ID
            *Object_View2D_Input\Chunk()\X = ix * #Object_View2D_Chunk_Size_X
            *Object_View2D_Input\Chunk()\Y = iy * #Object_View2D_Chunk_Size_Y
            *Object_View2D_Input\Chunk()\Width = #Object_View2D_Chunk_Size_X
            *Object_View2D_Input\Chunk()\Height = #Object_View2D_Chunk_Size_Y
            
            D3HT_Element_Set(*Object_View2D_Input\D3HT_Chunk, Object_View2D_Input_Chunk_ID, *Object_View2D_Input\Chunk(), #False)
          EndIf
        Next
      Next
      
    EndIf
  Next
  
  SetGadgetAttribute(*Object_View2D\ScrollBar_X, #PB_ScrollBar_Maximum, Max_Width * *Object_View2D\Zoom)
  SetGadgetAttribute(*Object_View2D\ScrollBar_X, #PB_ScrollBar_Minimum, Min_Width * *Object_View2D\Zoom)
  SetGadgetAttribute(*Object_View2D\ScrollBar_X, #PB_ScrollBar_PageLength, Width)
  SetGadgetState(*Object_View2D\ScrollBar_X, -*Object_View2D\Offset_X)
  
  SetGadgetAttribute(*Object_View2D\ScrollBar_Y, #PB_ScrollBar_Maximum, Max_Height * *Object_View2D\Zoom)
  SetGadgetAttribute(*Object_View2D\ScrollBar_Y, #PB_ScrollBar_Minimum, Min_Height * *Object_View2D\Zoom)
  SetGadgetAttribute(*Object_View2D\ScrollBar_Y, #PB_ScrollBar_PageLength, Height)
  SetGadgetState(*Object_View2D\ScrollBar_Y, -*Object_View2D\Offset_Y)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Get_Data(*Object.Object)
  Protected *Data, *Metadata, Data_Size
  Protected *Pointer.Object_View2D_32_Union, *Pointer_Metadata.Ascii
  Protected Width, Height
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected ix, iy, X_Start.q, Y_Start.q
  Protected *DrawingBuffer, DrawingBufferPitch, *Drawing_Temp.Object_View2D_ARGB
  Protected Color.l
  Protected Position.q
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  Width = GadgetWidth(*Object_View2D\Canvas_Data)
  Height = GadgetHeight(*Object_View2D\Canvas_Data)
  
  ; #### Iterate throught each input
  ForEach *Object\Input()
    *Object_View2D_Input = *Object\Input()\Custom_Data
    If *Object_View2D_Input
      
      ForEach *Object_View2D_Input\Chunk()
        If Not *Object_View2D_Input\Chunk()\Image_ID Or *Object_View2D_Input\Chunk()\Redraw
          *Object_View2D_Input\Chunk()\Redraw = #False
          
          If *Object_View2D_Input\Chunk()\Image_ID
            FreeImage(*Object_View2D_Input\Chunk()\Image_ID)
            *Object_View2D_Input\Chunk()\Image_ID = #Null
          EndIf
          
          *Object_View2D_Input\Chunk()\Image_ID = CreateImage(#PB_Any, *Object_View2D_Input\Chunk()\Width, *Object_View2D_Input\Chunk()\Height, 32, #PB_Image_Transparent)
          If *Object_View2D_Input\Chunk()\Image_ID
            If StartDrawing(ImageOutput(*Object_View2D_Input\Chunk()\Image_ID))
              
              *DrawingBuffer = DrawingBuffer()
              DrawingBufferPitch = DrawingBufferPitch()
              
              DrawingMode(#PB_2DDrawing_AllChannels)
              ;Box(0, 0, #Object_View2D_Chunk_Size_X, #Object_View2D_Chunk_Size_Y, RGBA(Random(255),Random(255),Random(255),255))
              
              Data_Size = *Object_View2D_Input\Chunk()\Width * *Object_View2D_Input\Bits_Per_Pixel / 8
              *Data = AllocateMemory(Data_Size)
              *Metadata = AllocateMemory(Data_Size)
              
              X_Start = *Object_View2D_Input\Chunk()\X
              For iy = 0 To *Object_View2D_Input\Chunk()\Height - 1
                If *Object_View2D_Input\Reverse_Y
                  Y_Start = - *Object_View2D_Input\Chunk()\Y - iy - 1
                Else
                  Y_Start = *Object_View2D_Input\Chunk()\Y + iy
                EndIf
                Position = (X_Start + Y_Start * *Object_View2D_Input\Width) * *Object_View2D_Input\Bits_Per_Pixel / 8 + Y_Start * *Object_View2D_Input\Line_Offset + *Object_View2D_Input\Offset
                
                FillMemory(*Metadata, Data_Size)
                
                If Object_Input_Get_Data(*Object\Input(), Position, Data_Size, *Data, *Metadata)
                  *Pointer = *Data
                  *Pointer_Metadata = *Metadata
                  
                  *Drawing_Temp = *DrawingBuffer + (*Object_View2D_Input\Chunk()\Height - 1) * DrawingBufferPitch - iy * DrawingBufferPitch
                  
                  For ix = 0 To *Object_View2D_Input\Chunk()\Width - 1
                    If X_Start + ix >= *Object_View2D_Input\Width
                      Break
                    EndIf
                    
                    If *Pointer_Metadata\a & #Metadata_Readable
                      Select *Object_View2D_Input\Pixel_Format
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
              
              If *Object_View2D\Zoom > 1
                ResizeImage(*Object_View2D_Input\Chunk()\Image_ID, *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom, *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom, #PB_Image_Raw)
              ElseIf *Object_View2D\Zoom < 1
                ResizeImage(*Object_View2D_Input\Chunk()\Image_ID, *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom, *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom, #PB_Image_Smooth)
              EndIf
              
            EndIf
            
            If *Object_View2D\Timeout_Start + 100 < ElapsedMilliseconds()
              *Object_View2D\Redraw = #True
              Break 2
            EndIf
            
          EndIf
          
        EndIf
      Next
      
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Canvas_Redraw_Filter_Blink(x, y, SourceColor, TargetColor)
  If (x+y) & 1
    ProcedureReturn ~TargetColor
  Else
    ProcedureReturn TargetColor
  EndIf
EndProcedure

Procedure Object_View2D_Canvas_Redraw_Filter_Inverse(x, y, SourceColor, TargetColor)
  ProcedureReturn ~TargetColor
EndProcedure

Procedure Object_View2D_Canvas_Redraw(*Object.Object)
  Protected Width, Height
  Protected X_M.d, Y_M.d
  Protected X_R.d, Y_R.d
  Protected i, ix, iy
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected Division_Size_X.d, Division_Size_Y.d, Divisions_X.q, Divisions_Y.q
  Protected Text.s, Text_Width, Text_Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  ; #### Data Canvas
  Width = GadgetWidth(*Object_View2D\Canvas_Data)
  Height = GadgetHeight(*Object_View2D\Canvas_Data)
  If Not StartDrawing(CanvasOutput(*Object_View2D\Canvas_Data))
    ProcedureReturn #False
  EndIf
  
  Box(0, 0, Width, Height, RGB(255,255,255))
  
  DrawingMode(#PB_2DDrawing_AlphaBlend | #PB_2DDrawing_Outlined)
  
  ;FrontColor(RGB(0,0,255))
  ;BackColor(RGB(255,255,255))
  
  ; #### Draw Grid
  ;Division_Size_X = Pow(10,Round(Log10(1 / *Object_View2D\Zoom_X),#PB_Round_Up))*20
  ;Division_Size_Y = Pow(10,Round(Log10(1 / *Object_View2D\Zoom_Y),#PB_Round_Up))*20
  ;Divisions_X = Round(Width / *Object_View2D\Zoom_X, #PB_Round_Up) / Division_Size_X
  ;Divisions_Y = Round(Height / *Object_View2D\Zoom_Y, #PB_Round_Up) / Division_Size_Y
  ;For ix = 0 To Divisions_X
  ;  X_M = ix * Division_Size_X * *Object_View2D\Zoom_X + *Object_View2D\Offset_X - Round(*Object_View2D\Offset_X / (Division_Size_X * *Object_View2D\Zoom_X), #PB_Round_Down) * (Division_Size_X * *Object_View2D\Zoom_X)
  ;  Line(X_M, 0, 0, Height, RGB(230,230,230))
  ;Next
  ;For iy = -Divisions_Y/2-1 To Divisions_Y/2
  ;  Y_M = iy * Division_Size_Y * *Object_View2D\Zoom_Y + Height/2 + *Object_View2D\Offset_Y - Round(*Object_View2D\Offset_Y / (Division_Size_Y * *Object_View2D\Zoom_Y), #PB_Round_Down) * (Division_Size_Y * *Object_View2D\Zoom_Y)
  ;  Line(0, Y_M, Width, 0, RGB(230,230,230))
  ;Next
  ;Line(0, *Object_View2D\Offset_Y + Height/2, Width, 0, RGB(180,180,180))
  ;Line(*Object_View2D\Offset_X, 0, 0, Height, RGB(180,180,180))
  
  ; #### Go throught each input
  ;Protected *Buffer     = DrawingBuffer()             ; Get the start address of the screen buffer
  ;Protected Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
  ForEach *Object\Input()
    *Object_View2D_Input = *Object\Input()\Custom_Data
    If *Object_View2D_Input
      
      ForEach *Object_View2D_Input\Chunk()
        X_M = *Object_View2D_Input\Chunk()\X * *Object_View2D\Zoom + *Object_View2D\Offset_X
        Y_M = *Object_View2D_Input\Chunk()\Y * *Object_View2D\Zoom + *Object_View2D\Offset_Y
        
        If *Object_View2D_Input\Chunk()\Image_ID
          If ImageWidth(*Object_View2D_Input\Chunk()\Image_ID) <> *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom Or ImageHeight(*Object_View2D_Input\Chunk()\Image_ID) <> *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom
            ResizeImage(*Object_View2D_Input\Chunk()\Image_ID, *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom, *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom, #PB_Image_Raw)
            *Object_View2D_Input\Chunk()\Redraw = #True
            *Object_View2D\Redraw = #True
          EndIf
          
          DrawImage(ImageID(*Object_View2D_Input\Chunk()\Image_ID), X_M, Y_M)
        EndIf
        
        If *Object_View2D_Input\Chunk()\Redraw Or *Object_View2D_Input\Chunk()\Image_ID = #Null
          Box(X_M, Y_M, *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom, *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom, RGBA(255,0,0,50))
        EndIf
      Next
      
    EndIf
  Next
  
  StopDrawing()
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Window_Event_Canvas_Data()
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
  Protected *Object_View2D_Input.Object_View2D_Input
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn 
  EndIf
  
  Select Event_Type
    Case #PB_EventType_RightClick
      ;*Object_View2D\Menu_Object = *Object
      ;DisplayPopupMenu(Object_View2D_Main\PopupMenu, WindowID(*Object_View2D\Window\ID))
      
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
      *Object_View2D\Redraw = #True
      
    Case #PB_EventType_LeftButtonUp
      M_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
      M_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
      *Object_View2D\Redraw = #True
      
    Case #PB_EventType_MouseMove
      If Move_Active
        *Object_View2D\Offset_X + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - Move_X
        *Object_View2D\Offset_Y + GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - Move_Y
        Move_X = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX)
        Move_Y = GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY)
        *Object_View2D\Redraw = #True
      EndIf
      ; #### Calculate Position and stuff
      R_X = Round((GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object_View2D\Offset_X) / *Object_View2D\Zoom, #PB_Round_Down)
      R_Y = Round((GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - *Object_View2D\Offset_Y) / *Object_View2D\Zoom, #PB_Round_Down)
      StatusBarText(Main_Window\StatusBar_ID, 0, "X: "+Str(R_X)+" Y:"+Str(R_Y))
      If FirstElement(*Object\Input())
        *Object_View2D_Input = *Object\Input()\Custom_Data
        If *Object_View2D_Input
          If *Object_View2D_Input\Reverse_Y
            StatusBarText(Main_Window\StatusBar_ID, 1, "Position (First image): "+Str((R_X * *Object_View2D_Input\Bits_Per_Pixel + (-1-R_Y) * (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel + *Object_View2D_Input\Line_Offset * 8)) / 8 + *Object_View2D_Input\Offset)+" B")
          Else
            StatusBarText(Main_Window\StatusBar_ID, 1, "Position (First image): "+Str((R_X * *Object_View2D_Input\Bits_Per_Pixel + R_Y * (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel + *Object_View2D_Input\Line_Offset * 8)) / 8 + *Object_View2D_Input\Offset)+" B")
          EndIf
        EndIf
      EndIf
      
    Case #PB_EventType_MouseWheel
      Temp_Zoom = Pow(2, GetGadgetAttribute(Event_Gadget, #PB_Canvas_WheelDelta))
      If *Object_View2D\Zoom * Temp_Zoom < Pow(2, -8)
        Temp_Zoom = Pow(2, -8) / *Object_View2D\Zoom
      EndIf
      If *Object_View2D\Zoom * Temp_Zoom > Pow(2, 4)
        Temp_Zoom = Pow(2, 4) / *Object_View2D\Zoom
      EndIf
      ;If *Object_View2D\Zoom_X * Temp_Zoom > 1
      ;  Temp_Zoom = 1 / *Object_View2D\Zoom_X
      ;EndIf
      *Object_View2D\Offset_X - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseX) - *Object_View2D\Offset_X)
      *Object_View2D\Offset_Y - (Temp_Zoom - 1) * (GetGadgetAttribute(Event_Gadget, #PB_Canvas_MouseY) - *Object_View2D\Offset_Y)
      *Object_View2D\Zoom * Temp_Zoom
      
      *Object_View2D\Redraw = #True
      
    Case #PB_EventType_KeyDown
      Key = GetGadgetAttribute(*Object_View2D\Canvas_Data, #PB_Canvas_Key)
      Modifiers = GetGadgetAttribute(*Object_View2D\Canvas_Data, #PB_Canvas_Modifiers)
      Select Key
        Case #PB_Shortcut_Insert
          
        Case #PB_Shortcut_Right
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_Left
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_Home
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_End
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_PageUp
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_PageDown
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_A
          ;*Object_View2D\Redraw = #True
          
        Case #PB_Shortcut_C
          
        Case #PB_Shortcut_V
          
        Case #PB_Shortcut_Back
          
        Case #PB_Shortcut_Delete
          
      EndSelect
      
  EndSelect
  
EndProcedure

Procedure Object_View2D_Window_Callback(hWnd, uMsg, wParam, lParam)
  Protected SCROLLINFO.SCROLLINFO
  
  Protected *Window.Window = Window_Get_hWnd(hWnd)
  If Not *Window
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndIf
  
  Select uMsg
    Case #WM_HSCROLL
      Select wParam & $FFFF
        Case #SB_THUMBTRACK
          SCROLLINFO\fMask = #SIF_TRACKPOS
          SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
          GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
          *Object_View2D\Offset_X = - SCROLLINFO\nTrackPos
          *Object_View2D\Redraw = #True
        Case #SB_PAGEUP
          *Object_View2D\Offset_X + GadgetWidth(*Object_View2D\Canvas_Data)
          *Object_View2D\Redraw = #True
        Case #SB_PAGEDOWN
          *Object_View2D\Offset_X - GadgetWidth(*Object_View2D\Canvas_Data)
          *Object_View2D\Redraw = #True
        Case #SB_LINEUP
          *Object_View2D\Offset_X + 100
          *Object_View2D\Redraw = #True
        Case #SB_LINEDOWN
          *Object_View2D\Offset_X - 100
          *Object_View2D\Redraw = #True
      EndSelect
      If *Object_View2D\Redraw
        *Object_View2D\Redraw = #False
        Object_View2D_Organize(*Object)
        Object_View2D_Get_Data(*Object)
        Object_View2D_Canvas_Redraw(*Object)
      EndIf
      
    Case #WM_VSCROLL
      Select wParam & $FFFF
        Case #SB_THUMBTRACK
          SCROLLINFO\fMask = #SIF_TRACKPOS
          SCROLLINFO\cbSize = SizeOf(SCROLLINFO)
          GetScrollInfo_(lParam, #SB_CTL, @SCROLLINFO)
          *Object_View2D\Offset_Y = - SCROLLINFO\nTrackPos
          *Object_View2D\Redraw = #True
        Case #SB_PAGEUP
          *Object_View2D\Offset_Y + GadgetHeight(*Object_View2D\Canvas_Data)
          *Object_View2D\Redraw = #True
        Case #SB_PAGEDOWN
          *Object_View2D\Offset_Y - GadgetHeight(*Object_View2D\Canvas_Data)
          *Object_View2D\Redraw = #True
        Case #SB_LINEUP
          *Object_View2D\Offset_Y + 100
          *Object_View2D\Redraw = #True
        Case #SB_LINEDOWN
          *Object_View2D\Offset_Y - 100
          *Object_View2D\Redraw = #True
      EndSelect
      If *Object_View2D\Redraw
        *Object_View2D\Redraw = #False
        Object_View2D_Organize(*Object)
        Object_View2D_Get_Data(*Object)
        Object_View2D_Canvas_Redraw(*Object)
      EndIf
      
  EndSelect
  
  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure

Procedure Object_View2D_Window_Event_SizeWindow()
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, ScrollBar_X_Height, ScrollBar_Y_Width
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
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn 
  EndIf
  
  Width = WindowWidth(Event_Window)
  Height = WindowHeight(Event_Window)
  
  ToolBarHeight = ToolBarHeight(*Object_View2D\ToolBar)
  
  ScrollBar_X_Height = 17
  ScrollBar_Y_Width = 17
  
  Data_Width = Width - ScrollBar_Y_Width
  Data_Height = Height - ScrollBar_X_Height - ToolBarHeight
  
  ; #### Gadgets
  ResizeGadget(*Object_View2D\ScrollBar_X, 0, Data_Height+ToolBarHeight, Data_Width, ScrollBar_X_Height)
  ResizeGadget(*Object_View2D\ScrollBar_Y, Data_Width, ToolBarHeight, ScrollBar_Y_Width, Data_Height)
  
  ResizeGadget(*Object_View2D\Canvas_Data, 0, ToolBarHeight, Data_Width, Data_Height)
  
  *Object_View2D\Redraw = #True
EndProcedure

Procedure Object_View2D_Window_Event_ActivateWindow()
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
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn 
  EndIf
  
  *Object_View2D\Redraw = #True
EndProcedure

Procedure Object_View2D_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected Max.d, Min.d
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn 
  EndIf
  
  Select Event_Menu
    Case #Object_View2D_Menu_Settings
      Object_View2D_Settings_Window_Open(*Object)
      
    Case #Object_View2D_Menu_Normalize
      *Object_View2D\Offset_X - (1.0/*Object_View2D\Zoom - 1) * ( - *Object_View2D\Offset_X)
      *Object_View2D\Offset_Y - (1.0/*Object_View2D\Zoom - 1) * ( - *Object_View2D\Offset_Y)
      *Object_View2D\Zoom = 1
      *Object_View2D\Redraw = #True
      
  EndSelect
EndProcedure

Procedure Object_View2D_Window_Event_CloseWindow()
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
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn 
  EndIf
  
  ;Object_View2D_Window_Close(*Object)
  *Object_View2D\Window_Close = #True
EndProcedure

Procedure Object_View2D_Window_Open(*Object.Object)
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, ScrollBar_X_Height, ScrollBar_Y_Width
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  If *Object_View2D\Window = #Null
    
    Width = 500
    Height = 500
    
    *Object_View2D\Window = Window_Create(*Object, "View2D", "View2D", #True, #PB_Ignore, #PB_Ignore, Width, Height)
    
    ; #### Toolbar
    *Object_View2D\ToolBar = CreateToolBar(#PB_Any, WindowID(*Object_View2D\Window\ID))
    ToolBarImageButton(#Object_View2D_Menu_Settings, ImageID(Icon_Gear))
    ToolBarImageButton(#Object_View2D_Menu_Normalize, ImageID(Object_View2D_Icon_Normalize))
    
    ToolBarHeight = ToolBarHeight(*Object_View2D\ToolBar)
    
    ScrollBar_X_Height = 17
    ScrollBar_Y_Width = 17
    
    Data_Width = Width - ScrollBar_Y_Width
    Data_Height = Height - ScrollBar_X_Height - ToolBarHeight
    
    ; #### Gadgets
    *Object_View2D\ScrollBar_X = ScrollBarGadget(#PB_Any, 0, Data_Height+ToolBarHeight, Data_Width, ScrollBar_X_Height, 0, 10, 1)
    *Object_View2D\ScrollBar_Y = ScrollBarGadget(#PB_Any, Data_Width, ToolBarHeight, ScrollBar_Y_Width, Data_Height, 0, 10, 1, #PB_ScrollBar_Vertical)
    
    *Object_View2D\Canvas_Data = CanvasGadget(#PB_Any, 0, 0, Data_Width, Data_Height, #PB_Canvas_Keyboard)
    
    BindEvent(#PB_Event_SizeWindow, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    ;BindEvent(#PB_Event_Repaint, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    ;BindEvent(#PB_Event_RestoreWindow, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    ;BindEvent(#PB_Event_ActivateWindow, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_View2D_Window_Event_Menu(), *Object_View2D\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_View2D_Window_Event_CloseWindow(), *Object_View2D\Window\ID)
    BindGadgetEvent(*Object_View2D\Canvas_Data, @Object_View2D_Window_Event_Canvas_Data())
    
    SetWindowCallback(@Object_View2D_Window_Callback(), *Object_View2D\Window\ID)
    
    *Object_View2D\Redraw = #True
    
  Else
    Window_Set_Active(*Object_View2D\Window)
  EndIf
EndProcedure

Procedure Object_View2D_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  If *Object_View2D\Window
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    ;UnbindEvent(#PB_Event_Repaint, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    ;UnbindEvent(#PB_Event_RestoreWindow, @Object_View2D_Window_Event_SizeWindow(), *Object_View2D\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_View2D_Window_Event_Menu(), *Object_View2D\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_View2D_Window_Event_CloseWindow(), *Object_View2D\Window\ID)
    UnbindGadgetEvent(*Object_View2D\Canvas_Data, @Object_View2D_Window_Event_Canvas_Data())
    
    SetWindowCallback(#Null, *Object_View2D\Window\ID)
    
    Window_Delete(*Object_View2D\Window)
    *Object_View2D\Window = #Null
  EndIf
EndProcedure

Procedure Object_View2D_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  
  If *Object_View2D\Window
    If *Object_View2D\Redraw
      *Object_View2D\Redraw = #False
      Object_View2D_Organize(*Object)
      *Object_View2D\Timeout_Start = ElapsedMilliseconds()
      Object_View2D_Get_Data(*Object)
      Object_View2D_Canvas_Redraw(*Object)
    EndIf
  EndIf
  
  Object_View2D_Settings_Main(*Object)
  
  If *Object_View2D\Window_Close
    *Object_View2D\Window_Close = #False
    Object_View2D_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_View2D_Main\Object_Type = Object_Type_Create()
If Object_View2D_Main\Object_Type
  Object_View2D_Main\Object_Type\Category = "Viewer"
  Object_View2D_Main\Object_Type\Name = "View2D"
  Object_View2D_Main\Object_Type\UID = "D3VIEW2D"
  Object_View2D_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_View2D_Main\Object_Type\Date_Creation = Date(2014,12,14,21,55,00)
  Object_View2D_Main\Object_Type\Date_Modification = Date(2015,01,05,18,38,00)
  Object_View2D_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_View2D_Main\Object_Type\Description = "Viewer for 2D Data, mostly images."
  Object_View2D_Main\Object_Type\Function_Create = @Object_View2D_Create()
  Object_View2D_Main\Object_Type\Version = 0900
EndIf

; #### Object Popup-Menu
;Object_View2D_Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
;MenuItem(#Object_View2D_PopupMenu_Copy_Position, "Copy Address")
;MenuItem(#Object_View2D_PopupMenu_Lock_To_Line, "Lock to this line")

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

DataSection
  Object_View2D_Icon_Normalize:   : IncludeBinary "../../../Data/Icons/Graph_Normalize.png"
EndDataSection
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 205
; FirstLine = 175
; Folding = ----
; EnableXP