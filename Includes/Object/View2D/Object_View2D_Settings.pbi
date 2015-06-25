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

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure Object_View2D_Settings
  *Window.Window
  Window_Close.l
  
  Update_ListIcon.i
  Update_Data.i
  
  ; #### Input
  Frame_In.i
  ListIcon_In.i
  CheckBox_In.i [5]
  Text_In.i [10]
  ComboBox_In.i
  Spin_In.i [5]
  Button_In_Add.i
  Button_In_Delete.i
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Declares ####################################################

Declare   Object_View2D_Settings_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_View2D_Settings_Update_ListIcon(*Object.Object)
  Protected *Object_Input.Object_Input
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected i
  Protected Temp_Image
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn #False
  EndIf
  
  ; #### Fill the ListIcon
  If GetGadgetState(*Object_View2D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, GetGadgetState(*Object_View2D_Settings\ListIcon_In))
  EndIf
  ClearGadgetItems(*Object_View2D_Settings\ListIcon_In)
  ForEach *Object\Input()
    *Object_View2D_Input = *Object\Input()\Custom_Data
    If Not *Object_View2D_Input
      ProcedureReturn #False
    EndIf
    AddGadgetItem(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object\Input()\i))
    SetGadgetItemText(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View2D_Input\Manually), 1)
    SetGadgetItemText(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View2D_Input\Pixel_Format), 2)
    SetGadgetItemText(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View2D_Input\Width), 3)
    SetGadgetItemText(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View2D_Input\Offset), 4)
    SetGadgetItemData(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), *Object\Input())
    
    ;Temp_Image = CreateImage(#PB_Any, 16, 16, 24, *Object_View2D_Input\Color)
    ;If Temp_Image
    ;  SetGadgetItemImage(*Object_View2D_Settings\ListIcon_In, ListIndex(*Object\Input()), ImageID(Temp_Image))
    ;  FreeImage(Temp_Image)
    ;EndIf
    
  Next
  For i = 0 To CountGadgetItems(*Object_View2D_Settings\ListIcon_In) - 1
    If GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, i) = *Object_Input
      SetGadgetState(*Object_View2D_Settings\ListIcon_In, i)
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View2D_Settings_Update_Data(*Object.Object)
  Protected *Object_Input.Object_Input
  Protected *Object_View2D_Input.Object_View2D_Input
  Protected i
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn #False
  EndIf
  
  If GetGadgetState(*Object_View2D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, GetGadgetState(*Object_View2D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
      For i = 0 To CountGadgetItems(*Object_View2D_Settings\ListIcon_In) - 1
        If GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, i) = *Object_Input
          SetGadgetState(*Object_View2D_Settings\ListIcon_In, i)
          
          *Object_View2D_Input = *Object_Input\Custom_Data
          If Not *Object_View2D_Input
            ProcedureReturn #False
          EndIf
          
          SetGadgetState(*Object_View2D_Settings\CheckBox_In[0], *Object_View2D_Input\Manually)
          
          SetGadgetState(*Object_View2D_Settings\Spin_In[0], *Object_View2D_Input\Width)
          
          SetGadgetState(*Object_View2D_Settings\Spin_In[1], *Object_View2D_Input\Offset)
          
          SetGadgetState(*Object_View2D_Settings\Spin_In[2], *Object_View2D_Input\Line_Offset)
          
          SetGadgetState(*Object_View2D_Settings\CheckBox_In[1], *Object_View2D_Input\Reverse_Y)
          
          For i = 0 To CountGadgetItems(*Object_View2D_Settings\ComboBox_In) - 1
            If GetGadgetItemData(*Object_View2D_Settings\ComboBox_In, i) = *Object_View2D_Input\Pixel_Format
              SetGadgetState(*Object_View2D_Settings\ComboBox_In, i)
              Break
            EndIf
          Next
          
          If GetGadgetState(*Object_View2D_Settings\CheckBox_In[0])
            DisableGadget(*Object_View2D_Settings\ComboBox_In, #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[0], #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[1], #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[2], #False)
            DisableGadget(*Object_View2D_Settings\CheckBox_In[1], #False)
          Else
            DisableGadget(*Object_View2D_Settings\ComboBox_In, #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[0], #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[1], #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[2], #True)
            DisableGadget(*Object_View2D_Settings\CheckBox_In[1], #True)
          EndIf
          
          ProcedureReturn #True
        EndIf
      Next
    EndIf
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure Object_View2D_Settings_Window_Event_ListIcon_In()
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
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn
  EndIf
  
  Object_View2D_Settings_Update_Data(*Object)
  
EndProcedure

Procedure Object_View2D_Settings_Window_Event_Value_Change()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
  Protected *Object_View2D_Input.Object_View2D_Input
  
  Protected Bytes_Per_Line_1.q, Bytes_Per_Line_2.q
  
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
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Object_View2D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, GetGadgetState(*Object_View2D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
      *Object_View2D_Input = *Object_Input\Custom_Data
      If Not *Object_View2D_Input
        ProcedureReturn #False
      EndIf
      
      Bytes_Per_Line_1 = (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel) / 8 + *Object_View2D_Input\Line_Offset
      
      Select Event_Gadget
        Case *Object_View2D_Settings\CheckBox_In[0]
          *Object_View2D_Input\Manually = GetGadgetState(*Object_View2D_Settings\CheckBox_In[0])
          
          If GetGadgetState(*Object_View2D_Settings\CheckBox_In[0])
            DisableGadget(*Object_View2D_Settings\ComboBox_In, #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[0], #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[1], #False)
            DisableGadget(*Object_View2D_Settings\Spin_In[2], #False)
            DisableGadget(*Object_View2D_Settings\CheckBox_In[1], #False)
          Else
            DisableGadget(*Object_View2D_Settings\ComboBox_In, #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[0], #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[1], #True)
            DisableGadget(*Object_View2D_Settings\Spin_In[2], #True)
            DisableGadget(*Object_View2D_Settings\CheckBox_In[1], #True)
          EndIf
          
        Case *Object_View2D_Settings\Spin_In[0]
          *Object_View2D_Input\Width = GetGadgetState(*Object_View2D_Settings\Spin_In[0])
          
        Case *Object_View2D_Settings\Spin_In[1]
          *Object_View2D_Input\Offset = GetGadgetState(*Object_View2D_Settings\Spin_In[1])
          
        Case *Object_View2D_Settings\Spin_In[2]
          *Object_View2D_Input\Line_Offset = GetGadgetState(*Object_View2D_Settings\Spin_In[2])
          
        Case *Object_View2D_Settings\ComboBox_In
          If GetGadgetState(*Object_View2D_Settings\ComboBox_In) >= 0
            *Object_View2D_Input\Pixel_Format = GetGadgetItemData(*Object_View2D_Settings\ComboBox_In, GetGadgetState(*Object_View2D_Settings\ComboBox_In))
          EndIf
          
        Case *Object_View2D_Settings\CheckBox_In[1]
          *Object_View2D_Input\Reverse_Y = GetGadgetState(*Object_View2D_Settings\CheckBox_In[1])
          
      EndSelect
      
      Bytes_Per_Line_2 = (*Object_View2D_Input\Width * *Object_View2D_Input\Bits_Per_Pixel) / 8 + *Object_View2D_Input\Line_Offset
      
      *Object_View2D\Offset_Y = (*Object_View2D\Offset_Y) * Bytes_Per_Line_1 / Bytes_Per_Line_2
      
      *Object_View2D\Redraw = #True
      
      ForEach *Object_View2D_Input\Chunk()
        *Object_View2D_Input\Chunk()\Redraw = #True
      Next
      
      *Object_View2D_Settings\Update_ListIcon = #True
      
    EndIf
  Next
  
EndProcedure

Procedure Object_View2D_Settings_Window_Event_Button_In_Add()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
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
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn
  EndIf
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Custom_Data = AllocateStructure(Object_View2D_Input)
  *Object_Input\Function_Event = @Object_View2D_Input_Event()
  
  *Object_View2D_Input = *Object_Input\Custom_Data
  *Object_View2D_Input\D3HT_Chunk = D3HT_Create(SizeOf(Object_View2D_Input_Chunk_ID), SizeOf(Integer), 65536)
  *Object_View2D_Input\Pixel_Format = #PixelFormat_24_BGR
  *Object_View2D_Input\Bits_Per_Pixel = 24
  *Object_View2D_Input\Width = 1024
  
  *Object_View2D_Settings\Update_ListIcon = #True
  *Object_View2D\Redraw = #True
EndProcedure

Procedure Object_View2D_Settings_Window_Event_Button_In_Delete()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
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
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Object_View2D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View2D_Settings\ListIcon_In, GetGadgetState(*Object_View2D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
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
      
      *Object_View2D_Settings\Update_ListIcon = #True
      *Object_View2D\Redraw = #True
      Break
    EndIf
  Next
EndProcedure

Procedure Object_View2D_Settings_Window_Event_CloseWindow()
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
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn
  EndIf
  
  ;Object_View2D_Settings_Window_Close(*Object)
  *Object_View2D_Settings\Window_Close = #True
EndProcedure

Procedure Object_View2D_Settings_Window_Open(*Object.Object)
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, Canvas_X_Height, Canvas_Y_Width, ScrollBar_X_Height, ScrollBar_Y_Width
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn #False
  EndIf
  
  If Not *Object_View2D_Settings\Window
    
    Width = 270
    Height = 470
    
    *Object_View2D_Settings\Window = Window_Create(*Object, "View2D_Settings", "View2D_Settings", #False, 0, 0, Width, Height, #False)
    
    ; #### Gadgets
    
    *Object_View2D_Settings\Frame_In = FrameGadget(#PB_Any, 10, 10, 250, 450, "Inputs")
    *Object_View2D_Settings\ListIcon_In = ListIconGadget(#PB_Any, 20, 30, 230, 200, "Input", 40, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(*Object_View2D_Settings\ListIcon_In, 1, "Manually", 60)
    AddGadgetColumn(*Object_View2D_Settings\ListIcon_In, 2, "Format", 50)
    AddGadgetColumn(*Object_View2D_Settings\ListIcon_In, 3, "Width", 50)
    AddGadgetColumn(*Object_View2D_Settings\ListIcon_In, 4, "Offset", 50)
    
    *Object_View2D_Settings\CheckBox_In[0] = CheckBoxGadget(#PB_Any, 20, 240, 230, 20, "Manually")
    
    *Object_View2D_Settings\Text_In[0] = TextGadget(#PB_Any, 20, 270, 50, 20, "Width:", #PB_Text_Right)
    *Object_View2D_Settings\Spin_In[0] = SpinGadget(#PB_Any, 80, 270, 170, 20, 1, 2147483647, #PB_Spin_Numeric)
    
    *Object_View2D_Settings\Text_In[1] = TextGadget(#PB_Any, 20, 300, 50, 20, "Type:", #PB_Text_Right)
    *Object_View2D_Settings\ComboBox_In = ComboBoxGadget(#PB_Any, 80, 300, 170, 20)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 0,  "1 bbp Gray")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 0,  #PixelFormat_1_Gray)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 1,  "1 bbp Indexed")     : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 1,  #PixelFormat_1_Indexed)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 2,  "2 bbp Gray")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 2,  #PixelFormat_2_Gray)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 3,  "2 bbp Indexed")     : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 3,  #PixelFormat_2_Indexed)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 4,  "4 bbp Gray")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 4,  #PixelFormat_4_Gray)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 5,  "4 bbp Indexed")     : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 5,  #PixelFormat_4_Indexed)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 6,  "8 bbp Gray")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 6,  #PixelFormat_8_Gray)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 7,  "8 bbp Indexed")     : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 7,  #PixelFormat_8_Indexed)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 8,  "16 bbp Gray")       : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 8,  #PixelFormat_16_Gray)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 9,  "16 bbp RGB 555")    : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 9,  #PixelFormat_16_RGB_555)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 10, "16 bbp RGB 565")    : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 10, #PixelFormat_16_RGB_565)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 11, "16 bbp ARGB 1555")  : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 11, #PixelFormat_16_ARGB_1555)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 12, "16 bbp Indexed")    : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 12, #PixelFormat_16_Indexed)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 13, "24 bbp RGB")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 13, #PixelFormat_24_RGB)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 14, "24 bbp BGR")        : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 14, #PixelFormat_24_BGR)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 15, "32 bbp ARGB")       : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 15, #PixelFormat_32_ARGB)
    AddGadgetItem(*Object_View2D_Settings\ComboBox_In, 16, "32 bbp ABGR")       : SetGadgetItemData(*Object_View2D_Settings\ComboBox_In, 16, #PixelFormat_32_ABGR)
    
    *Object_View2D_Settings\Text_In[2] = TextGadget(#PB_Any, 20, 330, 50, 20, "Offset:", #PB_Text_Right)
    *Object_View2D_Settings\Spin_In[1] = SpinGadget(#PB_Any, 80, 330, 170, 20, -2147483648, 2147483647, #PB_Spin_Numeric)
    
    *Object_View2D_Settings\Text_In[3] = TextGadget(#PB_Any, 20, 360, 50, 20, "L.-Offset:", #PB_Text_Right)
    *Object_View2D_Settings\Spin_In[2] = SpinGadget(#PB_Any, 80, 360, 170, 20, -2147483648, 2147483647, #PB_Spin_Numeric)
    
    *Object_View2D_Settings\Text_In[4] = TextGadget(#PB_Any, 20, 390, 50, 20, "Direction:", #PB_Text_Right)
    *Object_View2D_Settings\CheckBox_In[1] = CheckBoxGadget(#PB_Any, 80, 390, 170, 20, "Reverse Y")
    
    *Object_View2D_Settings\Button_In_Add = ButtonGadget(#PB_Any, 100, 420, 70, 30, "Add")
    *Object_View2D_Settings\Button_In_Delete = ButtonGadget(#PB_Any, 180, 420, 70, 30, "Delete")
    
    BindGadgetEvent(*Object_View2D_Settings\ListIcon_In, @Object_View2D_Settings_Window_Event_ListIcon_In())
    BindGadgetEvent(*Object_View2D_Settings\CheckBox_In[0], @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\Spin_In[0], @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\Spin_In[1], @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\Spin_In[2], @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\ComboBox_In, @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\CheckBox_In[1], @Object_View2D_Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Object_View2D_Settings\Button_In_Add, @Object_View2D_Settings_Window_Event_Button_In_Add())
    BindGadgetEvent(*Object_View2D_Settings\Button_In_Delete, @Object_View2D_Settings_Window_Event_Button_In_Delete())
    
    BindEvent(#PB_Event_CloseWindow, @Object_View2D_Settings_Window_Event_CloseWindow(), *Object_View2D_Settings\Window\ID)
    
    *Object_View2D_Settings\Update_ListIcon = #True
  Else
    Window_Set_Active(*Object_View2D_Settings\Window)
  EndIf
EndProcedure

Procedure Object_View2D_Settings_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn #False
  EndIf
  
  If *Object_View2D_Settings\Window
    
    UnbindGadgetEvent(*Object_View2D_Settings\ListIcon_In, @Object_View2D_Settings_Window_Event_ListIcon_In())
    UnbindGadgetEvent(*Object_View2D_Settings\CheckBox_In[0], @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\Spin_In[0], @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\Spin_In[1], @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\Spin_In[2], @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\ComboBox_In, @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\CheckBox_In[1], @Object_View2D_Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Object_View2D_Settings\Button_In_Add, @Object_View2D_Settings_Window_Event_Button_In_Add())
    UnbindGadgetEvent(*Object_View2D_Settings\Button_In_Delete, @Object_View2D_Settings_Window_Event_Button_In_Delete())
    
    UnbindEvent(#PB_Event_CloseWindow, @Object_View2D_Settings_Window_Event_CloseWindow(), *Object_View2D_Settings\Window\ID)
    
    Window_Delete(*Object_View2D_Settings\Window)
    *Object_View2D_Settings\Window = #Null
  EndIf
EndProcedure

Procedure Object_View2D_Settings_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D.Object_View2D = *Object\Custom_Data
  If Not *Object_View2D
    ProcedureReturn #False
  EndIf
  Protected *Object_View2D_Settings.Object_View2D_Settings = *Object_View2D\Settings
  If Not *Object_View2D_Settings
    ProcedureReturn #False
  EndIf
  
  If *Object_View2D_Settings\Window
    If *Object_View2D_Settings\Update_ListIcon
      *Object_View2D_Settings\Update_ListIcon = #False
      Object_View2D_Settings_Update_ListIcon(*Object.Object)
    EndIf
    If *Object_View2D_Settings\Update_Data
      *Object_View2D_Settings\Update_Data = #False
      Object_View2D_Settings_Update_Data(*Object.Object)
    EndIf
  EndIf
  
  If *Object_View2D_Settings\Window_Close
    *Object_View2D_Settings\Window_Close = #False
    Object_View2D_Settings_Window_Close(*Object)
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 445
; FirstLine = 426
; Folding = --
; EnableXP