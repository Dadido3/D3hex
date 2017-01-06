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

; ##################################################### Prototypes ##################################################

; ##################################################### Macros ######################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure Settings_Window
  *Window.Window::Object
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

Declare   Settings_Window_Close(*Node.Node::Object)

; ##################################################### Procedures ##################################################

Procedure Settings_Update_ListIcon(*Node.Node::Object)
  Protected *Node_Input.Node::Conn_Input
  Protected *Input_Channel.Input_Channel
  Protected i
  Protected Temp_Image
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn #False
  EndIf
  
  ; #### Fill the ListIcon
  If GetGadgetState(*Settings_Window\ListIcon_In) >= 0
    *Node_Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
  EndIf
  ClearGadgetItems(*Settings_Window\ListIcon_In)
  ForEach *Node\Input()
    *Input_Channel = *Node\Input()\Custom_Data
    If Not *Input_Channel
      ProcedureReturn #False
    EndIf
    AddGadgetItem(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Node\Input()\i))
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Manually), 1)
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Pixel_Format), 2)
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Width), 3)
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Offset), 4)
    SetGadgetItemData(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), *Node\Input())
    
    ;Temp_Image = CreateImage(#PB_Any, 16, 16, 24, *Input_Channel\Color)
    ;If Temp_Image
    ;  SetGadgetItemImage(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), ImageID(Temp_Image))
    ;  FreeImage(Temp_Image)
    ;EndIf
    
  Next
  For i = 0 To CountGadgetItems(*Settings_Window\ListIcon_In) - 1
    If GetGadgetItemData(*Settings_Window\ListIcon_In, i) = *Node_Input
      SetGadgetState(*Settings_Window\ListIcon_In, i)
      ProcedureReturn #True
    EndIf
  Next
  
  If GetGadgetState(*Settings_Window\ListIcon_In) < 0
    SetGadgetState(*Settings_Window\ListIcon_In, 0)
  EndIf
  *Settings_Window\Update_Data = #True
  
  ProcedureReturn #True
EndProcedure

Procedure Settings_Update_Data(*Node.Node::Object)
  Protected *Node_Input.Node::Conn_Input
  Protected *Input_Channel.Input_Channel
  Protected i
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn #False
  EndIf
  
  If GetGadgetState(*Settings_Window\ListIcon_In) >= 0
    *Node_Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
    DisableGadget(*Settings_Window\CheckBox_In[0], #False)
    DisableGadget(*Settings_Window\ComboBox_In, #False)
    DisableGadget(*Settings_Window\Spin_In[0], #False)
    DisableGadget(*Settings_Window\Spin_In[1], #False)
    DisableGadget(*Settings_Window\Spin_In[2], #False)
    DisableGadget(*Settings_Window\CheckBox_In[1], #False)
    DisableGadget(*Settings_Window\Button_In_Delete, #False)
  Else
    DisableGadget(*Settings_Window\CheckBox_In[0], #True)   : SetGadgetState(*Settings_Window\CheckBox_In[0], #False)
    DisableGadget(*Settings_Window\ComboBox_In, #True)      : SetGadgetState(*Settings_Window\ComboBox_In, -1)
    DisableGadget(*Settings_Window\Spin_In[0], #True)       : SetGadgetState(*Settings_Window\Spin_In[0], 0)
    DisableGadget(*Settings_Window\Spin_In[1], #True)       : SetGadgetState(*Settings_Window\Spin_In[1], 0)
    DisableGadget(*Settings_Window\Spin_In[2], #True)       : SetGadgetState(*Settings_Window\Spin_In[2], 0)
    DisableGadget(*Settings_Window\CheckBox_In[1], #True)   : SetGadgetState(*Settings_Window\CheckBox_In[1], #False)
    DisableGadget(*Settings_Window\Button_In_Delete, #True)
  EndIf
  ForEach *Node\Input()
    If *Node\Input() = *Node_Input
      
      *Input_Channel = *Node_Input\Custom_Data
      If Not *Input_Channel
        ProcedureReturn #False
      EndIf
      
      SetGadgetState(*Settings_Window\CheckBox_In[0], *Input_Channel\Manually)
      
      SetGadgetState(*Settings_Window\Spin_In[0], *Input_Channel\Width)
      
      SetGadgetState(*Settings_Window\Spin_In[1], *Input_Channel\Offset)
      
      SetGadgetState(*Settings_Window\Spin_In[2], *Input_Channel\Line_Offset)
      
      SetGadgetState(*Settings_Window\CheckBox_In[1], *Input_Channel\Reverse_Y)
      
      For i = 0 To CountGadgetItems(*Settings_Window\ComboBox_In) - 1
        If GetGadgetItemData(*Settings_Window\ComboBox_In, i) = *Input_Channel\Pixel_Format
          SetGadgetState(*Settings_Window\ComboBox_In, i)
          Break
        EndIf
      Next
      
      If GetGadgetState(*Settings_Window\CheckBox_In[0])
        DisableGadget(*Settings_Window\ComboBox_In, #False)
        DisableGadget(*Settings_Window\Spin_In[0], #False)
        DisableGadget(*Settings_Window\Spin_In[1], #False)
        DisableGadget(*Settings_Window\Spin_In[2], #False)
        DisableGadget(*Settings_Window\CheckBox_In[1], #False)
      Else
        DisableGadget(*Settings_Window\ComboBox_In, #True)
        DisableGadget(*Settings_Window\Spin_In[0], #True)
        DisableGadget(*Settings_Window\Spin_In[1], #True)
        DisableGadget(*Settings_Window\Spin_In[2], #True)
        DisableGadget(*Settings_Window\CheckBox_In[1], #True)
      EndIf
      
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure Settings_Window_Event_ListIcon_In()
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
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn
  EndIf
  
  *Settings_Window\Update_Data = #True
  ;Settings_Update_Data(*Node)
  
EndProcedure

Procedure Settings_Window_Event_Value_Change()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Node_Input.Node::Conn_Input
  Protected *Input_Channel.Input_Channel
  
  Protected Bytes_Per_Line_1.q, Bytes_Per_Line_2.q
  
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
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Settings_Window\ListIcon_In) >= 0
    *Node_Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
  EndIf
  ForEach *Node\Input()
    If *Node\Input() = *Node_Input
      *Input_Channel = *Node_Input\Custom_Data
      If Not *Input_Channel
        ProcedureReturn #False
      EndIf
      
      Bytes_Per_Line_1 = (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel) / 8 + *Input_Channel\Line_Offset
      
      Select Event_Gadget
        Case *Settings_Window\CheckBox_In[0]
          *Input_Channel\Manually = GetGadgetState(*Settings_Window\CheckBox_In[0])
          
          If GetGadgetState(*Settings_Window\CheckBox_In[0])
            DisableGadget(*Settings_Window\ComboBox_In, #False)
            DisableGadget(*Settings_Window\Spin_In[0], #False)
            DisableGadget(*Settings_Window\Spin_In[1], #False)
            DisableGadget(*Settings_Window\Spin_In[2], #False)
            DisableGadget(*Settings_Window\CheckBox_In[1], #False)
          Else
            DisableGadget(*Settings_Window\ComboBox_In, #True)
            DisableGadget(*Settings_Window\Spin_In[0], #True)
            DisableGadget(*Settings_Window\Spin_In[1], #True)
            DisableGadget(*Settings_Window\Spin_In[2], #True)
            DisableGadget(*Settings_Window\CheckBox_In[1], #True)
          EndIf
          
        Case *Settings_Window\Spin_In[0]
          *Input_Channel\Width = GetGadgetState(*Settings_Window\Spin_In[0])
          
        Case *Settings_Window\Spin_In[1]
          *Input_Channel\Offset = GetGadgetState(*Settings_Window\Spin_In[1])
          
        Case *Settings_Window\Spin_In[2]
          *Input_Channel\Line_Offset = GetGadgetState(*Settings_Window\Spin_In[2])
          
        Case *Settings_Window\ComboBox_In
          If GetGadgetState(*Settings_Window\ComboBox_In) >= 0
            *Input_Channel\Pixel_Format = GetGadgetItemData(*Settings_Window\ComboBox_In, GetGadgetState(*Settings_Window\ComboBox_In))
          EndIf
          
        Case *Settings_Window\CheckBox_In[1]
          *Input_Channel\Reverse_Y = GetGadgetState(*Settings_Window\CheckBox_In[1])
          
      EndSelect
      
      Bytes_Per_Line_2 = (*Input_Channel\Width * *Input_Channel\Bits_Per_Pixel) / 8 + *Input_Channel\Line_Offset
      
      If Bytes_Per_Line_1 > 0 And Bytes_Per_Line_2 > 0
        *Object\Offset_Y = (*Object\Offset_Y - GadgetHeight(*Object\Canvas_Data)/2) * Bytes_Per_Line_1 / Bytes_Per_Line_2 + GadgetHeight(*Object\Canvas_Data)/2
      EndIf
      
      *Object\Redraw = #True
      
      ForEach *Input_Channel\Chunk()
        *Input_Channel\Chunk()\Redraw = #True
      Next
      
      *Settings_Window\Update_ListIcon = #True
      
    EndIf
  Next
  
EndProcedure

Procedure Settings_Window_Event_Button_In_Add()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Node_Input.Node::Conn_Input
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
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn
  EndIf
  
  ; #### Add Input
  *Node_Input = Node::Input_Add(*Node)
  *Node_Input\Custom_Data = AllocateStructure(Input_Channel)
  *Node_Input\Function_Event = @Input_Event()
  
  *Input_Channel = *Node_Input\Custom_Data
  *Input_Channel\D3HT_Chunk = D3HT::Create(SizeOf(Input_Channel_Chunk_ID), SizeOf(Integer), 65536)
  *Input_Channel\Pixel_Format = #PixelFormat_24_BGR
  *Input_Channel\Bits_Per_Pixel = 24
  *Input_Channel\Width = 1024
  
  *Settings_Window\Update_ListIcon = #True
  *Object\Redraw = #True
EndProcedure

Procedure Settings_Window_Event_Button_In_Delete()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Node_Input.Node::Conn_Input
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
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Settings_Window\ListIcon_In) >= 0
    *Node_Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
  EndIf
  ForEach *Node\Input()
    If *Node\Input() = *Node_Input
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
      
      *Settings_Window\Update_ListIcon = #True
      *Object\Redraw = #True
      Break
    EndIf
  Next
EndProcedure

Procedure Settings_Window_Event_CloseWindow()
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
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn
  EndIf
  
  ;Settings_Window_Close(*Node)
  *Settings_Window\Window_Close = #True
EndProcedure

Procedure Settings_Window_Open(*Node.Node::Object)
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, Canvas_X_Height, Canvas_Y_Width, ScrollBar_X_Height, ScrollBar_Y_Width
  
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn #False
  EndIf
  
  If Not *Settings_Window\Window
    
    Width = 270
    Height = 470
    
    *Settings_Window\Window = Window::Create(*Node, "View2D_Settings", "View2D_Settings", 0, 0, Width, Height)
    
    ; #### Gadgets
    
    *Settings_Window\Frame_In = FrameGadget(#PB_Any, 10, 10, 250, 450, "Inputs")
    *Settings_Window\ListIcon_In = ListIconGadget(#PB_Any, 20, 30, 230, 200, "Input", 40, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 1, "Manually", 60)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 2, "Format", 50)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 3, "Width", 50)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 4, "Offset", 50)
    
    *Settings_Window\CheckBox_In[0] = CheckBoxGadget(#PB_Any, 20, 240, 230, 20, "Manually")
    
    *Settings_Window\Text_In[0] = TextGadget(#PB_Any, 20, 270, 50, 20, "Width:", #PB_Text_Right)
    *Settings_Window\Spin_In[0] = SpinGadget(#PB_Any, 80, 270, 170, 20, 1, 2147483647, #PB_Spin_Numeric)
    
    *Settings_Window\Text_In[1] = TextGadget(#PB_Any, 20, 300, 50, 20, "Type:", #PB_Text_Right)
    *Settings_Window\ComboBox_In = ComboBoxGadget(#PB_Any, 80, 300, 170, 20)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 0,  "1 bbp Gray")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 0,  #PixelFormat_1_Gray)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 1,  "1 bbp Indexed")     : SetGadgetItemData(*Settings_Window\ComboBox_In, 1,  #PixelFormat_1_Indexed)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 2,  "2 bbp Gray")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 2,  #PixelFormat_2_Gray)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 3,  "2 bbp Indexed")     : SetGadgetItemData(*Settings_Window\ComboBox_In, 3,  #PixelFormat_2_Indexed)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 4,  "4 bbp Gray")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 4,  #PixelFormat_4_Gray)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 5,  "4 bbp Indexed")     : SetGadgetItemData(*Settings_Window\ComboBox_In, 5,  #PixelFormat_4_Indexed)
    AddGadgetItem(*Settings_Window\ComboBox_In, 0,  "8 bbp Gray")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 0,  #PixelFormat_8_Gray)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 7,  "8 bbp Indexed")     : SetGadgetItemData(*Settings_Window\ComboBox_In, 7,  #PixelFormat_8_Indexed)
    AddGadgetItem(*Settings_Window\ComboBox_In, 1,  "16 bbp Gray")       : SetGadgetItemData(*Settings_Window\ComboBox_In, 1,  #PixelFormat_16_Gray)
    AddGadgetItem(*Settings_Window\ComboBox_In, 2,  "16 bbp RGB 555")    : SetGadgetItemData(*Settings_Window\ComboBox_In, 2,  #PixelFormat_16_RGB_555)
    AddGadgetItem(*Settings_Window\ComboBox_In, 3, "16 bbp RGB 565")     : SetGadgetItemData(*Settings_Window\ComboBox_In, 3, #PixelFormat_16_RGB_565)
    AddGadgetItem(*Settings_Window\ComboBox_In, 4, "16 bbp ARGB 1555")   : SetGadgetItemData(*Settings_Window\ComboBox_In, 4, #PixelFormat_16_ARGB_1555)
    ;AddGadgetItem(*Settings_Window\ComboBox_In, 12, "16 bbp Indexed")    : SetGadgetItemData(*Settings_Window\ComboBox_In, 12, #PixelFormat_16_Indexed)
    AddGadgetItem(*Settings_Window\ComboBox_In, 5, "24 bbp RGB")         : SetGadgetItemData(*Settings_Window\ComboBox_In, 5, #PixelFormat_24_RGB)
    AddGadgetItem(*Settings_Window\ComboBox_In, 6, "24 bbp BGR")         : SetGadgetItemData(*Settings_Window\ComboBox_In, 6, #PixelFormat_24_BGR)
    AddGadgetItem(*Settings_Window\ComboBox_In, 7, "32 bbp ARGB")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 7, #PixelFormat_32_ARGB)
    AddGadgetItem(*Settings_Window\ComboBox_In, 8, "32 bbp ABGR")        : SetGadgetItemData(*Settings_Window\ComboBox_In, 8, #PixelFormat_32_ABGR)
    
    *Settings_Window\Text_In[2] = TextGadget(#PB_Any, 20, 330, 50, 20, "Offset:", #PB_Text_Right)
    *Settings_Window\Spin_In[1] = SpinGadget(#PB_Any, 80, 330, 170, 20, -2147483648, 2147483647, #PB_Spin_Numeric)
    
    *Settings_Window\Text_In[3] = TextGadget(#PB_Any, 20, 360, 50, 20, "L.-Offset:", #PB_Text_Right)
    *Settings_Window\Spin_In[2] = SpinGadget(#PB_Any, 80, 360, 170, 20, -2147483648, 2147483647, #PB_Spin_Numeric)
    
    *Settings_Window\Text_In[4] = TextGadget(#PB_Any, 20, 390, 50, 20, "Direction:", #PB_Text_Right)
    *Settings_Window\CheckBox_In[1] = CheckBoxGadget(#PB_Any, 80, 390, 170, 20, "Reverse Y")
    
    *Settings_Window\Button_In_Add = ButtonGadget(#PB_Any, 100, 420, 70, 30, "Add")
    *Settings_Window\Button_In_Delete = ButtonGadget(#PB_Any, 180, 420, 70, 30, "Delete")
    
    BindGadgetEvent(*Settings_Window\ListIcon_In, @Settings_Window_Event_ListIcon_In())
    BindGadgetEvent(*Settings_Window\CheckBox_In[0], @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Spin_In[0], @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Spin_In[1], @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Spin_In[2], @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\ComboBox_In, @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\CheckBox_In[1], @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Button_In_Add, @Settings_Window_Event_Button_In_Add())
    BindGadgetEvent(*Settings_Window\Button_In_Delete, @Settings_Window_Event_Button_In_Delete())
    
    BindEvent(#PB_Event_CloseWindow, @Settings_Window_Event_CloseWindow(), *Settings_Window\Window\ID)
    
    *Settings_Window\Update_ListIcon = #True
  Else
    Window::Set_Active(*Settings_Window\Window)
  EndIf
EndProcedure

Procedure Settings_Window_Close(*Node.Node::Object)
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn #False
  EndIf
  
  If *Settings_Window\Window
    
    UnbindGadgetEvent(*Settings_Window\ListIcon_In, @Settings_Window_Event_ListIcon_In())
    UnbindGadgetEvent(*Settings_Window\CheckBox_In[0], @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Spin_In[0], @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Spin_In[1], @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Spin_In[2], @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\ComboBox_In, @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\CheckBox_In[1], @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Button_In_Add, @Settings_Window_Event_Button_In_Add())
    UnbindGadgetEvent(*Settings_Window\Button_In_Delete, @Settings_Window_Event_Button_In_Delete())
    
    UnbindEvent(#PB_Event_CloseWindow, @Settings_Window_Event_CloseWindow(), *Settings_Window\Window\ID)
    
    Window::Delete(*Settings_Window\Window)
    *Settings_Window\Window = #Null
  EndIf
EndProcedure

Procedure Settings_Main(*Node.Node::Object)
  If Not *Node
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Node\Custom_Data
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Settings_Window.Settings_Window = *Object\Settings_Window
  If Not *Settings_Window
    ProcedureReturn #False
  EndIf
  
  If *Settings_Window\Window
    If *Settings_Window\Update_ListIcon
      *Settings_Window\Update_ListIcon = #False
      Settings_Update_ListIcon(*Node.Node::Object)
    EndIf
    If *Settings_Window\Update_Data
      *Settings_Window\Update_Data = #False
      Settings_Update_Data(*Node.Node::Object)
    EndIf
  EndIf
  
  If *Settings_Window\Window_Close
    *Settings_Window\Window_Close = #False
    Settings_Window_Close(*Node)
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 155
; FirstLine = 122
; Folding = --
; EnableXP