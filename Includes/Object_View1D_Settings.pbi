
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

Structure Object_View1D_Settings
  *Window.Window
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
  Button_In_Set.i
  Button_In_Add.i
  Button_In_Delete.i
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Fonts #######################################################

; ##################################################### Declares ####################################################

Declare   Object_View1D_Settings_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_View1D_Settings_Update_ListIcon(*Object.Object)
  Protected *Object_Input.Object_Input
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected i
  Protected Temp_Image
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn #False
  EndIf
  
  ; #### Fill the ListIcon
  If GetGadgetState(*Object_View1D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, GetGadgetState(*Object_View1D_Settings\ListIcon_In))
  EndIf
  ClearGadgetItems(*Object_View1D_Settings\ListIcon_In)
  ForEach *Object\Input()
    *Object_View1D_Input = *Object\Input()\Custom_Data
    If Not *Object_View1D_Input
      ProcedureReturn #False
    EndIf
    AddGadgetItem(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object\Input()\i))
    SetGadgetItemText(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View1D_Input\Manually), 1)
    SetGadgetItemText(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View1D_Input\ElementType), 2)
    SetGadgetItemText(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), Str(*Object_View1D_Input\Offset), 3)
    SetGadgetItemData(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), *Object\Input())
    
    Temp_Image = CreateImage(#PB_Any, 16, 16, 24, *Object_View1D_Input\Color)
    If Temp_Image
      SetGadgetItemImage(*Object_View1D_Settings\ListIcon_In, ListIndex(*Object\Input()), ImageID(Temp_Image))
      FreeImage(Temp_Image)
    EndIf
    
  Next
  For i = 0 To CountGadgetItems(*Object_View1D_Settings\ListIcon_In) - 1
    If GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, i) = *Object_Input
      SetGadgetState(*Object_View1D_Settings\ListIcon_In, i)
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_View1D_Settings_Update_Data(*Object.Object)
  Protected *Object_Input.Object_Input
  Protected *Object_View1D_Input.Object_View1D_Input
  Protected i
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn #False
  EndIf
  
  If GetGadgetState(*Object_View1D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, GetGadgetState(*Object_View1D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
      For i = 0 To CountGadgetItems(*Object_View1D_Settings\ListIcon_In) - 1
        If GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, i) = *Object_Input
          SetGadgetState(*Object_View1D_Settings\ListIcon_In, i)
          
          *Object_View1D_Input = *Object_Input\Custom_Data
          If Not *Object_View1D_Input
            ProcedureReturn #False
          EndIf
          
          SetGadgetData(*Object_View1D_Settings\Canvas_In, *Object_View1D_Input\Color)
          If StartDrawing(CanvasOutput(*Object_View1D_Settings\Canvas_In))
            Box(0, 0, GadgetWidth(*Object_View1D_Settings\Canvas_In), GadgetHeight(*Object_View1D_Settings\Canvas_In), GetGadgetData(*Object_View1D_Settings\Canvas_In))
            StopDrawing()
          EndIf
          
          SetGadgetState(*Object_View1D_Settings\CheckBox_In, *Object_View1D_Input\Manually)
          
          SetGadgetState(*Object_View1D_Settings\Spin_In, *Object_View1D_Input\Offset)
          For i = 0 To CountGadgetItems(*Object_View1D_Settings\ComboBox_In) - 1
            If GetGadgetItemData(*Object_View1D_Settings\ComboBox_In, i) = *Object_View1D_Input\ElementType
              SetGadgetState(*Object_View1D_Settings\ComboBox_In, i)
              Break
            EndIf
          Next
          If GetGadgetState(*Object_View1D_Settings\CheckBox_In)
            ;DisableGadget(*Object_View1D_Settings\Canvas_In, #False)
            DisableGadget(*Object_View1D_Settings\ComboBox_In, #False)
            DisableGadget(*Object_View1D_Settings\Spin_In, #False)
          Else
            ;DisableGadget(*Object_View1D_Settings\Canvas_In, #True)
            DisableGadget(*Object_View1D_Settings\ComboBox_In, #True)
            DisableGadget(*Object_View1D_Settings\Spin_In, #True)
          EndIf
          
          ProcedureReturn #True
        EndIf
      Next
    EndIf
  Next
  
  ProcedureReturn #False
EndProcedure

Procedure Object_View1D_Settings_Window_Event_ListIcon_In()
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  Object_View1D_Settings_Update_Data(*Object)
  
EndProcedure

Procedure Object_View1D_Settings_Window_Event_CheckBox_In()
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Object_View1D_Settings\CheckBox_In)
    DisableGadget(*Object_View1D_Settings\Canvas_In, #False)
    DisableGadget(*Object_View1D_Settings\ComboBox_In, #False)
    DisableGadget(*Object_View1D_Settings\Spin_In, #False)
  Else
    DisableGadget(*Object_View1D_Settings\Canvas_In, #True)
    DisableGadget(*Object_View1D_Settings\ComboBox_In, #True)
    DisableGadget(*Object_View1D_Settings\Spin_In, #True)
  EndIf
  
EndProcedure

Procedure Object_View1D_Settings_Window_Event_Canvas_In()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
  Protected *Object_View1D_Input.Object_View1D_Input
  
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  Select Event_Type
    Case #PB_EventType_LeftClick
      SetGadgetData(*Object_View1D_Settings\Canvas_In, ColorRequester(GetGadgetData(*Object_View1D_Settings\Canvas_In)))
      If StartDrawing(CanvasOutput(*Object_View1D_Settings\Canvas_In))
        Box(0, 0, GadgetWidth(*Object_View1D_Settings\Canvas_In), GadgetHeight(*Object_View1D_Settings\Canvas_In), GetGadgetData(*Object_View1D_Settings\Canvas_In))
        StopDrawing()
      EndIf
      
  EndSelect
  
EndProcedure

Procedure Object_View1D_Settings_Window_Event_Button_In_Set()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
  Protected *Object_View1D_Input.Object_View1D_Input
  
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Object_View1D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, GetGadgetState(*Object_View1D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
      *Object_View1D_Input = *Object_Input\Custom_Data
      If Not *Object_View1D_Input
        ProcedureReturn #False
      EndIf
      
      *Object_View1D_Input\Manually = GetGadgetState(*Object_View1D_Settings\CheckBox_In)
      If GetGadgetState(*Object_View1D_Settings\ComboBox_In) >= 0
        Select GetGadgetItemData(*Object_View1D_Settings\ComboBox_In, GetGadgetState(*Object_View1D_Settings\ComboBox_In))
          Case #PB_Ascii    : *Object_View1D_Input\ElementSize = 1 : *Object_View1D_Input\ElementType = #PB_Ascii
          Case #PB_Byte     : *Object_View1D_Input\ElementSize = 1 : *Object_View1D_Input\ElementType = #PB_Byte
          Case #PB_Unicode  : *Object_View1D_Input\ElementSize = 2 : *Object_View1D_Input\ElementType = #PB_Unicode
          Case #PB_Word     : *Object_View1D_Input\ElementSize = 2 : *Object_View1D_Input\ElementType = #PB_Word
          Case #PB_Long     : *Object_View1D_Input\ElementSize = 4 : *Object_View1D_Input\ElementType = #PB_Long
          Case #PB_Quad     : *Object_View1D_Input\ElementSize = 8 : *Object_View1D_Input\ElementType = #PB_Quad
          Case #PB_Float    : *Object_View1D_Input\ElementSize = 4 : *Object_View1D_Input\ElementType = #PB_Float
          Case #PB_Double   : *Object_View1D_Input\ElementSize = 8 : *Object_View1D_Input\ElementType = #PB_Double
        EndSelect
      EndIf
      
      *Object_View1D_Input\Color = GetGadgetData(*Object_View1D_Settings\Canvas_In)
      
      *Object_View1D_Input\Offset = GetGadgetState(*Object_View1D_Settings\Spin_In)
      
      *Object_View1D\Redraw = #True
      
      *Object_View1D_Settings\Update_ListIcon = #True
      
    EndIf
  Next
  
EndProcedure

Procedure Object_View1D_Settings_Window_Event_Button_In_Add()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
  Protected *Object_View1D_Input.Object_View1D_Input
  
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Custom_Data = AllocateMemory(SizeOf(Object_View1D_Input))
  InitializeStructure(*Object_Input\Custom_Data, Object_View1D_Input)
  *Object_Input\Function_Event = @Object_View1D_Input_Event()
  
  *Object_View1D_Settings\Update_ListIcon = #True
EndProcedure

Procedure Object_View1D_Settings_Window_Event_Button_In_Delete()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected *Object_Input.Object_Input
  
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  If GetGadgetState(*Object_View1D_Settings\ListIcon_In) >= 0
    *Object_Input = GetGadgetItemData(*Object_View1D_Settings\ListIcon_In, GetGadgetState(*Object_View1D_Settings\ListIcon_In))
  EndIf
  ForEach *Object\Input()
    If *Object\Input() = *Object_Input
      If *Object\Input()\Custom_Data
        ClearStructure(*Object\Input()\Custom_Data, Object_View1D_Input)
        FreeMemory(*Object\Input()\Custom_Data)
      EndIf
      Object_Input_Delete(*Object, *Object\Input())
      
      *Object_View1D_Settings\Update_ListIcon = #True
      Break
    EndIf
  Next
EndProcedure

Procedure Object_View1D_Settings_Window_Event_CloseWindow()
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
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn
  EndIf
  
  ;Object_View1D_Settings_Window_Close(*Object)
  *Object_View1D_Settings\Window_Close = #True
EndProcedure

Procedure Object_View1D_Settings_Window_Open(*Object.Object)
  Protected Width, Height, Data_Width, Data_Height, ToolBarHeight, Canvas_X_Height, Canvas_Y_Width, ScrollBar_X_Height, ScrollBar_Y_Width
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn #False
  EndIf
  
  If Not *Object_View1D_Settings\Window
    
    Width = 270
    Height = 410
    
    *Object_View1D_Settings\Window = Window_Create(*Object, "View1D_Settings", "View1D_Settings", #False, 0, 0, Width, Height)
    
    ; #### Gadgets
    
    *Object_View1D_Settings\Frame_In = FrameGadget(#PB_Any, 10, 10, 250, 390, "Inputs")
    *Object_View1D_Settings\ListIcon_In = ListIconGadget(#PB_Any, 20, 30, 230, 200, "Input", 40, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(*Object_View1D_Settings\ListIcon_In, 1, "Manually", 60)
    AddGadgetColumn(*Object_View1D_Settings\ListIcon_In, 2, "Type", 50)
    AddGadgetColumn(*Object_View1D_Settings\ListIcon_In, 3, "Offset", 50)
    
    *Object_View1D_Settings\CheckBox_In = CheckBoxGadget(#PB_Any, 20, 240, 230, 20, "Manually")
    
    *Object_View1D_Settings\Text_In[0] = TextGadget(#PB_Any, 20, 270, 50, 20, "Color:", #PB_Text_Right)
    *Object_View1D_Settings\Canvas_In = CanvasGadget(#PB_Any, 80, 270, 170, 20)
    
    *Object_View1D_Settings\Text_In[1] = TextGadget(#PB_Any, 20, 300, 50, 20, "Type:", #PB_Text_Right)
    *Object_View1D_Settings\ComboBox_In = ComboBoxGadget(#PB_Any, 80, 300, 170, 20)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 0, "uint8")  : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 0, #PB_Ascii)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 1, "int8")   : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 1, #PB_Byte)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 2, "uint16") : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 2, #PB_Unicode)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 3, "int16")  : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 3, #PB_Word)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 4, "int32")  : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 4, #PB_Long)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 5, "int64")  : SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 5, #PB_Quad)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 6, "float32"): SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 6, #PB_Float)
    AddGadgetItem(*Object_View1D_Settings\ComboBox_In, 7, "float64"): SetGadgetItemData(*Object_View1D_Settings\ComboBox_In, 7, #PB_Double)
    
    *Object_View1D_Settings\Text_In[2] = TextGadget(#PB_Any, 20, 330, 50, 20, "Offset:", #PB_Text_Right)
    *Object_View1D_Settings\Spin_In = SpinGadget(#PB_Any, 80, 330, 170, 20, 0, 1000000000, #PB_Spin_Numeric)
    ;*Object_View1D_Settings\Button_In_Color = ButtonGadget(#PB_Any, )
    *Object_View1D_Settings\Button_In_Set = ButtonGadget(#PB_Any, 20, 360, 70, 30, "Set")
    *Object_View1D_Settings\Button_In_Add = ButtonGadget(#PB_Any, 100, 360, 70, 30, "Add")
    *Object_View1D_Settings\Button_In_Delete = ButtonGadget(#PB_Any, 180, 360, 70, 30, "Delete")
    
    BindGadgetEvent(*Object_View1D_Settings\ListIcon_In, @Object_View1D_Settings_Window_Event_ListIcon_In())
    BindGadgetEvent(*Object_View1D_Settings\CheckBox_in, @Object_View1D_Settings_Window_Event_CheckBox_In())
    BindGadgetEvent(*Object_View1D_Settings\Canvas_In, @Object_View1D_Settings_Window_Event_Canvas_In())
    BindGadgetEvent(*Object_View1D_Settings\Button_In_Set, @Object_View1D_Settings_Window_Event_Button_In_Set())
    BindGadgetEvent(*Object_View1D_Settings\Button_In_Add, @Object_View1D_Settings_Window_Event_Button_In_Add())
    BindGadgetEvent(*Object_View1D_Settings\Button_In_Delete, @Object_View1D_Settings_Window_Event_Button_In_Delete())
    
    BindEvent(#PB_Event_CloseWindow, @Object_View1D_Settings_Window_Event_CloseWindow(), *Object_View1D_Settings\Window\ID)
    
    *Object_View1D_Settings\Update_ListIcon = #True
  Else
    Window_Set_Active(*Object_View1D_Settings\Window)
  EndIf
EndProcedure

Procedure Object_View1D_Settings_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn #False
  EndIf
  
  If *Object_View1D_Settings\Window
    
    UnbindGadgetEvent(*Object_View1D_Settings\ListIcon_In, @Object_View1D_Settings_Window_Event_ListIcon_In())
    UnbindGadgetEvent(*Object_View1D_Settings\CheckBox_in, @Object_View1D_Settings_Window_Event_CheckBox_In())
    UnbindGadgetEvent(*Object_View1D_Settings\Canvas_In, @Object_View1D_Settings_Window_Event_Canvas_In())
    UnbindGadgetEvent(*Object_View1D_Settings\Button_In_Set, @Object_View1D_Settings_Window_Event_Button_In_Set())
    UnbindGadgetEvent(*Object_View1D_Settings\Button_In_Add, @Object_View1D_Settings_Window_Event_Button_In_Add())
    UnbindGadgetEvent(*Object_View1D_Settings\Button_In_Delete, @Object_View1D_Settings_Window_Event_Button_In_Delete())
    
    UnbindEvent(#PB_Event_CloseWindow, @Object_View1D_Settings_Window_Event_CloseWindow(), *Object_View1D_Settings\Window\ID)
    
    Window_Delete(*Object_View1D_Settings\Window)
    *Object_View1D_Settings\Window = #Null
  EndIf
EndProcedure

Procedure Object_View1D_Settings_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D.Object_View1D = *Object\Custom_Data
  If Not *Object_View1D
    ProcedureReturn #False
  EndIf
  Protected *Object_View1D_Settings.Object_View1D_Settings = *Object_View1D\Settings
  If Not *Object_View1D_Settings
    ProcedureReturn #False
  EndIf
  
  If *Object_View1D_Settings\Window
    If *Object_View1D_Settings\Update_ListIcon
      *Object_View1D_Settings\Update_ListIcon = #False
      Object_View1D_Settings_Update_ListIcon(*Object.Object)
    EndIf
    If *Object_View1D_Settings\Update_Data
      *Object_View1D_Settings\Update_Data = #False
      Object_View1D_Settings_Update_Data(*Object.Object)
    EndIf
  EndIf
  
  If *Object_View1D_Settings\Window_Close
    *Object_View1D_Settings\Window_Close = #False
    Object_View1D_Settings_Window_Close(*Object)
  EndIf
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 Beta 1 (Windows - x64)
; CursorPosition = 304
; FirstLine = 7
; Folding = ---
; EnableXP