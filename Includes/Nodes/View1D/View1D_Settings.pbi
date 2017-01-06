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
  CheckBox_In.i
  Canvas_In.i
  Text_In.i [5]
  ComboBox_In.i
  Spin_In.i
  Button_In_Add.i
  Button_In_Delete.i
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Declares ####################################################

Declare   Settings_Window_Close(*Node.Node::Object)

; ##################################################### Procedures ##################################################

Procedure Settings_Update_ListIcon(*Node.Node::Object)
  Protected *Input.Node::Conn_Input
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
    *Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
  EndIf
  ClearGadgetItems(*Settings_Window\ListIcon_In)
  ForEach *Node\Input()
    *Input_Channel = *Node\Input()\Custom_Data
    If Not *Input_Channel
      ProcedureReturn #False
    EndIf
    AddGadgetItem(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Node\Input()\i))
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Manually), 1)
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\ElementType), 2)
    SetGadgetItemText(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), Str(*Input_Channel\Offset), 3)
    SetGadgetItemData(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), *Node\Input())
    
    Temp_Image = CreateImage(#PB_Any, 16, 16, 24, *Input_Channel\Color)
    If Temp_Image
      SetGadgetItemImage(*Settings_Window\ListIcon_In, ListIndex(*Node\Input()), ImageID(Temp_Image))
      FreeImage(Temp_Image)
    EndIf
    
  Next
  For i = 0 To CountGadgetItems(*Settings_Window\ListIcon_In) - 1
    If GetGadgetItemData(*Settings_Window\ListIcon_In, i) = *Input
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
  Protected *Input.Node::Conn_Input
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
    *Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
    DisableGadget(*Settings_Window\CheckBox_In, #False)
    DisableGadget(*Settings_Window\ComboBox_In, #False)
    DisableGadget(*Settings_Window\Spin_In, #False)
    DisableGadget(*Settings_Window\Button_In_Delete, #False)
  Else
    DisableGadget(*Settings_Window\CheckBox_In, #True)      : SetGadgetState(*Settings_Window\CheckBox_In, #False)
    DisableGadget(*Settings_Window\ComboBox_In, #True)      : SetGadgetState(*Settings_Window\ComboBox_In, -1)
    DisableGadget(*Settings_Window\Spin_In, #True)          : SetGadgetState(*Settings_Window\Spin_In, 0)
    DisableGadget(*Settings_Window\Button_In_Delete, #True)
  EndIf
  ForEach *Node\Input()
    If *Node\Input() = *Input
      
      *Input_Channel = *Input\Custom_Data
      If Not *Input_Channel
        ProcedureReturn #False
      EndIf
      
      SetGadgetData(*Settings_Window\Canvas_In, *Input_Channel\Color)
      If StartDrawing(CanvasOutput(*Settings_Window\Canvas_In))
        Box(0, 0, GadgetWidth(*Settings_Window\Canvas_In), GadgetHeight(*Settings_Window\Canvas_In), GetGadgetData(*Settings_Window\Canvas_In))
        StopDrawing()
      EndIf
      
      SetGadgetState(*Settings_Window\CheckBox_In, *Input_Channel\Manually)
      
      SetGadgetState(*Settings_Window\Spin_In, *Input_Channel\Offset)
      For i = 0 To CountGadgetItems(*Settings_Window\ComboBox_In) - 1
        If GetGadgetItemData(*Settings_Window\ComboBox_In, i) = *Input_Channel\ElementType
          SetGadgetState(*Settings_Window\ComboBox_In, i)
          Break
        EndIf
      Next
      If GetGadgetState(*Settings_Window\CheckBox_In)
        ;DisableGadget(*Settings_Window\Canvas_In, #False)
        DisableGadget(*Settings_Window\ComboBox_In, #False)
        DisableGadget(*Settings_Window\Spin_In, #False)
      Else
        ;DisableGadget(*Settings_Window\Canvas_In, #True)
        DisableGadget(*Settings_Window\ComboBox_In, #True)
        DisableGadget(*Settings_Window\Spin_In, #True)
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
  
  Settings_Update_Data(*Node)
  
EndProcedure

Procedure Settings_Window_Event_Value_Change()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Node_Input.Node::Conn_Input
  Protected *Input_Channel.Input_Channel
  Protected Result
  
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
        ProcedureReturn
      EndIf
      
      Select Event_Gadget
        Case *Settings_Window\CheckBox_In
          *Input_Channel\Manually = GetGadgetState(*Settings_Window\CheckBox_In)
          
          If GetGadgetState(*Settings_Window\CheckBox_In)
            DisableGadget(*Settings_Window\Canvas_In, #False)
            DisableGadget(*Settings_Window\ComboBox_In, #False)
            DisableGadget(*Settings_Window\Spin_In, #False)
          Else
            DisableGadget(*Settings_Window\Canvas_In, #True)
            DisableGadget(*Settings_Window\ComboBox_In, #True)
            DisableGadget(*Settings_Window\Spin_In, #True)
          EndIf
          
        Case *Settings_Window\Canvas_In
          Select Event_Type
            Case #PB_EventType_LeftClick
              Result = ColorRequester(GetGadgetData(*Settings_Window\Canvas_In))
              If Result >= 0
                *Input_Channel\Color = Result
                SetGadgetData(*Settings_Window\Canvas_In, Result)
                If StartDrawing(CanvasOutput(*Settings_Window\Canvas_In))
                  Box(0, 0, GadgetWidth(*Settings_Window\Canvas_In), GadgetHeight(*Settings_Window\Canvas_In), GetGadgetData(*Settings_Window\Canvas_In))
                  StopDrawing()
                EndIf
              EndIf
              
          EndSelect
          
        Case *Settings_Window\ComboBox_In
          If GetGadgetState(*Settings_Window\ComboBox_In) >= 0
            *Input_Channel\ElementType = GetGadgetItemData(*Settings_Window\ComboBox_In, GetGadgetState(*Settings_Window\ComboBox_In))
          EndIf
          
        Case *Settings_Window\Spin_In
          *Input_Channel\Offset = GetGadgetState(*Settings_Window\Spin_In)
          
      EndSelect
      
      *Object\Redraw = #True
      
      *Settings_Window\Update_ListIcon = #True
      
    EndIf
  Next
  
EndProcedure

Procedure Settings_Window_Event_Button_In_Add()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Input.Node::Conn_Input
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
  *Input = Node::Input_Add(*Node)
  *Input\Custom_Data = AllocateStructure(Input_Channel)
  *Input\Function_Event = @Input_Event()
  
  *Input_Channel = *Input\Custom_Data
  *Input_Channel\ElementType = #Integer_U_8
  
  *Settings_Window\Update_ListIcon = #True
EndProcedure

Procedure Settings_Window_Event_Button_In_Delete()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Input.Node::Conn_Input
  
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
    *Input = GetGadgetItemData(*Settings_Window\ListIcon_In, GetGadgetState(*Settings_Window\ListIcon_In))
  EndIf
  ForEach *Node\Input()
    If *Node\Input() = *Input
      If *Node\Input()\Custom_Data
        FreeStructure(*Node\Input()\Custom_Data)
        *Node\Input()\Custom_Data = #Null
      EndIf
      Node::Input_Delete(*Node, *Node\Input())
      
      *Settings_Window\Update_ListIcon = #True
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
    Height = 410
    
    *Settings_Window\Window = Window::Create(*Node, "View1D_Settings", "View1D_Settings", 0, 0, Width, Height)
    
    ; #### Gadgets
    
    *Settings_Window\Frame_In = FrameGadget(#PB_Any, 10, 10, 250, 390, "Inputs")
    *Settings_Window\ListIcon_In = ListIconGadget(#PB_Any, 20, 30, 230, 200, "Input", 40, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 1, "Manually", 60)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 2, "Type", 50)
    AddGadgetColumn(*Settings_Window\ListIcon_In, 3, "Offset", 50)
    
    *Settings_Window\CheckBox_In = CheckBoxGadget(#PB_Any, 20, 240, 230, 20, "Manually")
    
    *Settings_Window\Text_In[0] = TextGadget(#PB_Any, 20, 270, 50, 20, "Color:", #PB_Text_Right)
    *Settings_Window\Canvas_In = CanvasGadget(#PB_Any, 80, 270, 170, 20)
    
    *Settings_Window\Text_In[1] = TextGadget(#PB_Any, 20, 300, 50, 20, "Type:", #PB_Text_Right)
    *Settings_Window\ComboBox_In = ComboBoxGadget(#PB_Any, 80, 300, 170, 20)
    AddGadgetItem(*Settings_Window\ComboBox_In, 0, "uint8")  : SetGadgetItemData(*Settings_Window\ComboBox_In, 0, #Integer_U_8)
    AddGadgetItem(*Settings_Window\ComboBox_In, 1, "int8")   : SetGadgetItemData(*Settings_Window\ComboBox_In, 1, #Integer_S_8)
    AddGadgetItem(*Settings_Window\ComboBox_In, 2, "uint16") : SetGadgetItemData(*Settings_Window\ComboBox_In, 2, #Integer_U_16)
    AddGadgetItem(*Settings_Window\ComboBox_In, 3, "int16")  : SetGadgetItemData(*Settings_Window\ComboBox_In, 3, #Integer_S_16)
    AddGadgetItem(*Settings_Window\ComboBox_In, 4, "uint32") : SetGadgetItemData(*Settings_Window\ComboBox_In, 4, #Integer_U_32)
    AddGadgetItem(*Settings_Window\ComboBox_In, 5, "int32")  : SetGadgetItemData(*Settings_Window\ComboBox_In, 5, #Integer_S_32)
    AddGadgetItem(*Settings_Window\ComboBox_In, 6, "uint64") : SetGadgetItemData(*Settings_Window\ComboBox_In, 6, #Integer_U_64)
    AddGadgetItem(*Settings_Window\ComboBox_In, 7, "int64")  : SetGadgetItemData(*Settings_Window\ComboBox_In, 7, #Integer_S_64)
    AddGadgetItem(*Settings_Window\ComboBox_In, 8, "float32"): SetGadgetItemData(*Settings_Window\ComboBox_In, 8, #Float_32)
    AddGadgetItem(*Settings_Window\ComboBox_In, 9, "float64"): SetGadgetItemData(*Settings_Window\ComboBox_In, 9, #Float_64)
    
    *Settings_Window\Text_In[2] = TextGadget(#PB_Any, 20, 330, 50, 20, "Offset:", #PB_Text_Right)
    *Settings_Window\Spin_In = SpinGadget(#PB_Any, 80, 330, 170, 20, -2147483648, 2147483647, #PB_Spin_Numeric)
    ;*Settings_Window\Button_In_Color = ButtonGadget(#PB_Any, )
    *Settings_Window\Button_In_Add = ButtonGadget(#PB_Any, 100, 360, 70, 30, "Add")
    *Settings_Window\Button_In_Delete = ButtonGadget(#PB_Any, 180, 360, 70, 30, "Delete")
    
    BindGadgetEvent(*Settings_Window\ListIcon_In, @Settings_Window_Event_ListIcon_In())
    BindGadgetEvent(*Settings_Window\CheckBox_in, @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Canvas_In, @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\ComboBox_In, @Settings_Window_Event_Value_Change())
    BindGadgetEvent(*Settings_Window\Spin_In, @Settings_Window_Event_Value_Change())
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
    UnbindGadgetEvent(*Settings_Window\CheckBox_in, @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Canvas_In, @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\ComboBox_In, @Settings_Window_Event_Value_Change())
    UnbindGadgetEvent(*Settings_Window\Spin_In, @Settings_Window_Event_Value_Change())
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


; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 450
; FirstLine = 416
; Folding = --
; EnableXP