; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2014  David Vogel
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

#Object_View2D_Chunk_Size_X = 256
#Object_View2D_Chunk_Size_Y = 256

Enumeration
  #Object_View2D_Menu_Settings
  #Object_View2D_Menu_Normalize
EndEnumeration

Enumeration
  #Object_View2D_Pixel_Format_24_RGB
  #Object_View2D_Pixel_Format_24_BGR
  #Object_View2D_Pixel_Format_32_RGBA
  #Object_View2D_Pixel_Format_32_BGRA
EndEnumeration

; ##################################################### Structures ##################################################

Structure Object_View2D_32
  A.a
  B.a
  C.a
  D.a
EndStructure

Structure Object_View2D_Main
  *Object_Type.Object_Type
EndStructure
Global Object_View2D_Main.Object_View2D_Main

Structure Object_View2D_Input_Chunk
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
  
  Width.q           ; Width of the Image in Pixels
  
  ; #### Image Chunks
  Map Chunk.Object_View2D_Input_Chunk()
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
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_View2D_Delete(*Object.Object)
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
      
      ;TODO: Free chunk images!
      
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
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Zoom", #NBT_Tag_Double)    : NBT_Tag_Set_Double(*NBT_Tag, *Object_View2D\Zoom)
  
  *NBT_Tag_List = NBT_Tag_Add(*Parent_Tag, "Inputs", #NBT_Tag_List, #NBT_Tag_Compound)
  If *NBT_Tag_List
    ForEach *Object\Input()
      *Object_View2D_Input = *Object\Input()\Custom_Data
      
      *NBT_Tag_Compound = NBT_Tag_Add(*NBT_Tag_List, "", #NBT_Tag_Compound)
      If *NBT_Tag_Compound
        ;*NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "ElementType", #NBT_Tag_Long) : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\ElementType)
        ;*NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "ElementSize", #NBT_Tag_Long) : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\ElementSize)
        ;*NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Manually", #NBT_Tag_Long)    : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Manually)
        ;*NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Offset", #NBT_Tag_Quad)      : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Offset)
        ;*NBT_Tag = NBT_Tag_Add(*NBT_Tag_Compound, "Color", #NBT_Tag_Long)       : NBT_Tag_Set_Number(*NBT_Tag, *Object_View2D_Input\Color)
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
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Zoom")   : *Object_View2D\Zoom = NBT_Tag_Get_Double(*NBT_Tag)
  
  ; #### Delete all inputs
  While FirstElement(*Object\Input())
    If *Object\Input()\Custom_Data
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
          ;*NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "ElementType") : *Object_View2D_Input\ElementType = NBT_Tag_Get_Number(*NBT_Tag)
          ;*NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "ElementSize") : *Object_View2D_Input\ElementSize = NBT_Tag_Get_Number(*NBT_Tag)
          ;*NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Manually")    : *Object_View2D_Input\Manually = NBT_Tag_Get_Number(*NBT_Tag)
          ;*NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Offset")      : *Object_View2D_Input\Offset = NBT_Tag_Get_Number(*NBT_Tag)
          ;*NBT_Tag = NBT_Tag(*NBT_Tag_Compound, "Color")       : *Object_View2D_Input\Color = NBT_Tag_Get_Number(*NBT_Tag)
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
  Protected Width, Height
  Protected ix, iy, ix_1, iy_1
  Protected X_M.d, Y_M.d, X_M_2.d, Y_M_2.d
  Protected X_R_1.d, Y_R_1.d, X_R_2.d, Y_R_2.d
  Protected Found
  
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
        ;*Object_View2D_Input\ElementSize = 1
        ;*Object_View2D_Input\ElementType = #PB_Ascii
        *Object_View2D_Input\Width = 1920  ; ################################################ Delete Me!
        *Object_View2D_Input\Line_Offset = 0
        *Object_View2D_Input\Pixel_Format = #Object_View2D_Pixel_Format_24_BGR
      EndIf
      
      ; #### Set Bits_Per_Pixel accordingly to the Pixel_Format
      Select *Object_View2D_Input\Pixel_Format
        Case #Object_View2D_Pixel_Format_24_RGB, #Object_View2D_Pixel_Format_24_BGR
          *Object_View2D_Input\Bits_Per_Pixel = 24
        Case #Object_View2D_Pixel_Format_32_RGBA, #Object_View2D_Pixel_Format_32_BGRA
          *Object_View2D_Input\Bits_Per_Pixel = 32
          
        Default
          *Object_View2D_Input\Bits_Per_Pixel = 24
          *Object_View2D_Input\Pixel_Format = #Object_View2D_Pixel_Format_24_RGB
      EndSelect
      
      ; #### Delete chunks which are outside of the viewport
      ForEach *Object_View2D_Input\Chunk()
        X_M.d = *Object_View2D_Input\Chunk()\X * *Object_View2D\Zoom + *Object_View2D\Offset_X
        Y_M.d = *Object_View2D_Input\Chunk()\Y * *Object_View2D\Zoom + *Object_View2D\Offset_Y
        X_M_2.d = (*Object_View2D_Input\Chunk()\X + *Object_View2D_Input\Chunk()\Width) * *Object_View2D\Zoom + *Object_View2D\Offset_X
        Y_M_2.d = (*Object_View2D_Input\Chunk()\Y + *Object_View2D_Input\Chunk()\Height) * *Object_View2D\Zoom + *Object_View2D\Offset_Y
        If X_M >= Width Or Y_M >= Height Or X_M_2 < 0 Or Y_M_2 < 0 Or *Object_View2D_Input\Chunk()\X > *Object_View2D_Input\Width
          If *Object_View2D_Input\Chunk()\Image_ID
            FreeImage(*Object_View2D_Input\Chunk()\Image_ID)
          EndIf
          DeleteMapElement(*Object_View2D_Input\Chunk())
        EndIf
      Next
      
      ; #### Create new chunks
      X_R_1 = - *Object_View2D\Offset_X / *Object_View2D\Zoom
      Y_R_1 = - *Object_View2D\Offset_Y / *Object_View2D\Zoom
      X_R_2 = (Width - *Object_View2D\Offset_X) / *Object_View2D\Zoom
      Y_R_2 = (Height - *Object_View2D\Offset_Y) / *Object_View2D\Zoom
      ix_1 = Round(X_R_1 / #Object_View2D_Chunk_Size_X, #PB_Round_Down)
      iy_1 = Round(Y_R_1 / #Object_View2D_Chunk_Size_Y, #PB_Round_Down)
      If ix_1 < 0 : ix_1 = 0 : EndIf
      If iy_1 < 0 : iy_1 = 0 : EndIf
      If X_R_2 > *Object_View2D_Input\Width : X_R_2 = *Object_View2D_Input\Width : EndIf
      
      For iy = iy_1 To Round(Y_R_2 / #Object_View2D_Chunk_Size_Y, #PB_Round_Down) ;TODO: Use integer rounding
        For ix = ix_1 To Round(X_R_2 / #Object_View2D_Chunk_Size_X, #PB_Round_Down)
          ;Found = #False
          ;ForEach *Object_View2D_Input\Chunk()
          ;  If *Object_View2D_Input\Chunk()\X = ix * #Object_View2D_Chunk_Size_X And *Object_View2D_Input\Chunk()\Y = iy * #Object_View2D_Chunk_Size_X
          ;    Found = #True
          ;    Break
          ;  EndIf
          ;Next
          ;If Not Found
          
          If Not FindMapElement(*Object_View2D_Input\Chunk(), Str(iy)+"|"+Str(ix))
            AddMapElement(*Object_View2D_Input\Chunk(), Str(iy)+"|"+Str(ix), #PB_Map_NoElementCheck)
            
            *Object_View2D_Input\Chunk()\X = ix * #Object_View2D_Chunk_Size_X
            *Object_View2D_Input\Chunk()\Y = iy * #Object_View2D_Chunk_Size_Y
            *Object_View2D_Input\Chunk()\Width = *Object_View2D_Input\Width - ix * #Object_View2D_Chunk_Size_X
            *Object_View2D_Input\Chunk()\Height = #Object_View2D_Chunk_Size_Y
            If *Object_View2D_Input\Chunk()\Width > #Object_View2D_Chunk_Size_X : *Object_View2D_Input\Chunk()\Width = #Object_View2D_Chunk_Size_X : EndIf
          EndIf
        Next
      Next
      
    EndIf
  Next
  
  ;SetGadgetAttribute(*Object_View2D\ScrollBar_X, #PB_ScrollBar_Maximum, *Object_View2D\Elements * *Object_View2D\Zoom_X)
  ;SetGadgetAttribute(*Object_View2D\ScrollBar_X, #PB_ScrollBar_PageLength, Width)
  ;SetGadgetState(*Object_View2D\ScrollBar_X, -*Object_View2D\Offset_X)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Get_Data(*Object.Object)
  Protected *Data, *Metadata, Data_Size
  Protected *Pointer.Object_View2D_32, *Pointer_Metadata.Ascii
  Protected Width, Height
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected ix, iy, X_Start.q, Y_Start.q
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
              
              DrawingMode(#PB_2DDrawing_AllChannels)
              ;Box(0, 0, #Object_View2D_Chunk_Size_X, #Object_View2D_Chunk_Size_Y, RGBA(Random(255),Random(255),Random(255),255))
              
              Data_Size = *Object_View2D_Input\Chunk()\Width * *Object_View2D_Input\Bits_Per_Pixel / 8
              *Data = AllocateMemory(Data_Size)
              *Metadata = AllocateMemory(Data_Size)
              
              X_Start = *Object_View2D_Input\Chunk()\X
              For iy = 0 To *Object_View2D_Input\Chunk()\Height - 1
                Y_Start = *Object_View2D_Input\Chunk()\Y + iy
                Position = (X_Start + Y_Start * *Object_View2D_Input\Width) * *Object_View2D_Input\Bits_Per_Pixel / 8 + Y_Start * *Object_View2D_Input\Line_Offset
                
                If Object_Input_Get_Data(*Object\Input(), Position, Data_Size, *Data, *Metadata)
                  *Pointer = *Data
                  *Pointer_Metadata = *Metadata
                  
                  For ix = 0 To *Object_View2D_Input\Chunk()\Width - 1
                    If *Pointer_Metadata\a & #Metadata_Readable
                      Select *Object_View2D_Input\Pixel_Format
                        Case #Object_View2D_Pixel_Format_24_RGB : Color = RGBA(*Pointer\A, *Pointer\B, *Pointer\C, 255) : *Pointer + 3 : *Pointer_Metadata + 3
                        Case #Object_View2D_Pixel_Format_24_BGR : Color = RGBA(*Pointer\C, *Pointer\B, *Pointer\A, 255) : *Pointer + 3 : *Pointer_Metadata + 3
                        Case #Object_View2D_Pixel_Format_32_RGBA : Color = RGBA(*Pointer\A, *Pointer\B, *Pointer\C, *Pointer\D) : *Pointer + 4 : *Pointer_Metadata + 4
                        Case #Object_View2D_Pixel_Format_32_BGRA : Color = RGBA(*Pointer\C, *Pointer\B, *Pointer\A, *Pointer\D) : *Pointer + 4 : *Pointer_Metadata + 4
                      EndSelect
                      
                      Plot(ix, iy, Color)
                    EndIf
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
        
        If ImageWidth(*Object_View2D_Input\Chunk()\Image_ID) <> *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom Or ImageHeight(*Object_View2D_Input\Chunk()\Image_ID) <> *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom
          ResizeImage(*Object_View2D_Input\Chunk()\Image_ID, *Object_View2D_Input\Chunk()\Width * *Object_View2D\Zoom, *Object_View2D_Input\Chunk()\Height * *Object_View2D\Zoom, #PB_Image_Raw)
          *Object_View2D_Input\Chunk()\Redraw = #True
          *Object_View2D\Redraw = #True
        EndIf
        
        DrawImage(ImageID(*Object_View2D_Input\Chunk()\Image_ID), X_M, Y_M)
        
        If *Object_View2D_Input\Chunk()\Redraw
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
  ResizeGadget(*Object_View2D\ScrollBar_Y, Data_Width, 0, ScrollBar_Y_Width, Data_Height)
  
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
    *Object_View2D\ScrollBar_Y = ScrollBarGadget(#PB_Any, Data_Width, 0, ScrollBar_Y_Width, Data_Height, 0, 10, 1, #PB_ScrollBar_Vertical)
    
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
  Object_View2D_Main\Object_Type\Date_Creation = Date(2014,01,28,14,42,00)
  Object_View2D_Main\Object_Type\Date_Modification = Date(2014,01,28,14,42,00)
  Object_View2D_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_View2D_Main\Object_Type\Description = "Just a normal Graph viewer."
  Object_View2D_Main\Object_Type\Function_Create = @Object_View2D_Create()
  Object_View2D_Main\Object_Type\Version = 0900
EndIf

; #### Object Popup-Menu
;Object_View2D_Main\PopupMenu = CreatePopupImageMenu(#PB_Any, #PB_Menu_ModernLook)
;MenuItem(#Object_View2D_PopupMenu_Cut, "Cut")
;MenuItem(#Object_View2D_PopupMenu_Copy, "Copy")
;MenuItem(#Object_View2D_PopupMenu_Paste, "Paste")
;MenuBar()
;MenuItem(#Object_View2D_PopupMenu_Close, "Close")

; ##################################################### Main ########################################################

; ##################################################### End #########################################################

; ##################################################### Data Sections ###############################################

DataSection
  Object_View2D_Icon_Normalize:   : IncludeBinary "../../../Data/Icons/Graph_Normalize.png"
EndDataSection
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 468
; FirstLine = 423
; Folding = ----
; EnableXP