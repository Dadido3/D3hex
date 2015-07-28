; #################################################### License / Copyright ######################################
; 
;     The MIT License (MIT)
;     
;     Copyright (c) 2015  David Vogel
;     
;     Permission is hereby granted, free of charge, To any person obtaining a copy
;     of this software And associated documentation files (the "Software"), To deal
;     in the Software without restriction, including without limitation the rights
;     To use, copy, modify, merge, publish, distribute, sublicense, And/Or sell
;     copies of the Software, And To permit persons To whom the Software is
;     furnished To do so, subject To the following conditions:
;     
;     The above copyright notice And this permission notice shall be included in all
;     copies Or substantial portions of the Software.
;     
;     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS Or
;     IMPLIED, INCLUDING BUT Not LIMITED To THE WARRANTIES OF MERCHANTABILITY,
;     FITNESS For A PARTICULAR PURPOSE And NONINFRINGEMENT. IN NO EVENT SHALL THE
;     AUTHORS Or COPYRIGHT HOLDERS BE LIABLE For ANY CLAIM, DAMAGES Or OTHER
;     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT Or OTHERWISE, ARISING FROM,
;     OUT OF Or IN CONNECTION With THE SOFTWARE Or THE USE Or OTHER DEALINGS IN THE
;     SOFTWARE.
;
; #################################################### Documentation #############################################
; 
; D3docker - D3 Docker Gadget
;
; Version History:
; - 0.000 07.06.2015
; 
; - 0.800 22.06.2015
;   - Implemented mostly everything necessary
;   
; - 0.815 (INDEV)
;   - Docker containers can now be dragged
;   - Removed fixed window-flags inside Window_Add(...)
;   - Determine the mouse position with GetCursorPos_(...)
;   - Fixed an issue with Container_Resize_Between(...)
;   - Fixed the redraw issues of the empty space between containers
;   - A lot of bugfixes and little changes
;   - Reduced the amount of #PB_Event_ActivateWindow events
;   - Also hide the "Empty" gadgets
; 
; 
; 
; TODO: Loading and Saving layouts from/to json or xml...
; TODO: Merge the Container_Docker bar with the tab bar of the tabbed container
; TODO: Allow the docking to undocked windows
; TODO: Add static containers (not movable and/or not removable)
; TODO: When switching the active window, restore the active gadget of that window
; FIXME: Tabulator key changes to elements outside of the window
; 
; #################################################### Includes #################################################

XIncludeFile "CustomGadget.pbi"

; ###############################################################################################################
; #################################################### Public ###################################################
; ###############################################################################################################

DeclareModule D3docker
  EnableExplicit
  ; ################################################## Constants ################################################
  #PB_GadgetType_D3docker=20150607
  #Version = 815
  
  ; #### Directions for placing a docker
  Enumeration
    #Direction_Inside
    #Direction_Top
    #Direction_Right
    #Direction_Left
    #Direction_Bottom
  EndEnumeration
  
  ; ################################################## Functions ################################################
  Declare   Window_Add(Gadget, X, Y, Width, Height, Title.s, Flags, Resize_Priority.l=0)
  Declare   Window_Close(Window)
  Declare   Window_Bounds(Window, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
  Declare   Window_Set_Active(Window)
  Declare   Window_Get_Active(Gadget)
  Declare   Window_Set_Callback(Window, *Callback)
  Declare   Window_Get_Container(Window)
  
  Declare   Container_Delete(Gadget, *Container)
  Declare   Docker_Add(Gadget, *Container, Direction, Window)
  Declare   Root_Get(Gadget)
  
  Declare   Create(Gadget, X, Y, Width, Height, Parent_Window.i)
  Declare   Free(Gadget)
  
EndDeclareModule

; ###############################################################################################################
; #################################################### Private ##################################################
; ###############################################################################################################

Module D3docker
  ; ################################################## Init #####################################################
  UsePNGImageDecoder()
  
  ; ################################################## Includes #################################################
  XIncludeFile "TabBarGadget.pbi"
  UseModule CustomGadget
  
  ; ################################################## Constants ################################################
  #Color_Gadget_Background        = $707070
  #Color_Docker_Background        = $B0B0B0
  #Color_Docker_Background_Active = $FF8D70
  #Color_Docker_Border            = #Color_Docker_Background;$A0A0A0
  #Color_Splitter_Background      = #Color_Gadget_Background
  #Color_Tabbed_Background        = #Color_Gadget_Background
  
  #Color_Button_Hover             = $D0D0D0
  #Color_Button_Pressed           = $909090
  
  TabBarGadgetInclude\TabBarColor = #Color_Tabbed_Background
  
  #Container_Size_Max = 1000000
  #Container_Size_Ignore = -1
  
  #Container_Docker_Bar_Height = 16
  #Container_Tabbed_Bar_Height = 20
  
  #Container_Docker_Drag_Start_Min = 5        ; Amount of pixels the mouse has to move before dragging starts
  
  Enumeration
    #Container_Type_Root
    #Container_Type_Docker
    #Container_Type_Split_H
    #Container_Type_Split_V
    #Container_Type_Spliter
    #Container_Type_Tabbed
  EndEnumeration
  
  #Diamond_Size = 32
  
  #Splitter_Size = 6
  
  Enumeration
    #Canvas_Button_State_Normal
    #Canvas_Button_State_Hover
    #Canvas_Button_State_Pressed
    #Canvas_Button_State_Pressed_Outside
  EndEnumeration
  
  ; ################################################## Prototypes ###############################################
  Prototype Window_Callback(hWnd, Message, wParam, lParam)
  
  ; ################################################## Structures ###############################################
  Structure Canvas_Button
    X.l
    Y.l
    Width.l
    Height.l
    
    Image.i
    
    State.l
  EndStructure
  
  Structure Diamond
    Window.i
    hWnd.i
    
    *Gadget.GADGET
    *Container.Container
    
    Direction.l
    
    X.l
    Y.l
    
    Gadget_Canvas.i
  EndStructure
  
  Structure Window
    Window.i
    hWnd.i
    
    *Gadget.GADGET
    *Container.Container
    
    *Callback.Window_Callback
    
    Max_Width.l
    Min_Width.l
    Max_Height.l
    Min_Height.l
    
    Resize_Priority.l
    
    Flags_Normal.l
    Flags_Docked.l
    
    Mouse_Drag_X.l
    Mouse_Drag_Y.l
    Mouse_Drag_X_Offset.l
    Mouse_Drag_Y_Offset.l
    Mouse_Drag.l
    *Mouse_Drag_Container.Container
  EndStructure
  
  Structure Container
    Type.l
    
    *Gadget.GADGET
    *Parent.Container
    
    X.l
    Y.l
    Width.d
    Height.d
    
    Max_Width.l
    Min_Width.l
    Max_Height.l
    Min_Height.l
    
    Priority.l            ; Priority for resizing
    Priority_Inerhit.l
    
    List *Container.Container()
    
    Hidden.l              ; #True when this and all child containers should be hidden. If it is #False, it depends on all the ancestors if it is visible
    Hidden_Inherit.l
    
    Tabbed_Selection.l
    
    *Window.Window
    
    Gadget_Container.i
    Gadget_Text.i
    Gadget_Canvas.i
    Gadget_TabBar.i
    Gadget_Empty.i[2]     ; Gadget to fill empty spaces to prevent redraw issues. (A hack until a better way is implemented)
    
    ; #### Docker
    Docker_Button_Close.Canvas_Button
    Docker_Button_Undock.Canvas_Button
    
    Title.s
    
    Drag_X.l
    Drag_Y.l
    Drag.l
  EndStructure
  
  Structure GADGET_PARAMS
    Root.Container
    
    Parent_Window.i
    
    FontID.i
    
    List Diamond.Diamond()
    List Window.Window()
    *Active_Window.Window
  EndStructure
  
  Structure Temp_Size
    Size.l
    Min_Size.l
    Max_Size.l
    
    Priority.l
    
    Finished.l
    
    *Container.Container
  EndStructure
  
  ; ################################################## Declares #################################################
  Declare    Diamond_Delete(*Gadget.GADGET, *Diamond.Diamond)
  
  Declare   _Window_Bounds(*Gadget.GADGET, *Window.Window, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
  Declare   _Window_Set_Active(*Gadget.GADGET, *Window.Window, Post_Event=#False, Tabbed_Select=#True)
  Declare    Window_Get_By_Handle(hWnd)
  Declare    Window_Get_By_Number(Window)
  
  Declare    Container_Docker_Redraw(*Gadget.GADGET, *Container.Container)
  Declare    Container_Tabbed_Select(*Gadget.GADGET, *Container.Container, *Selection.Container, SetGadgetState=#True, Activate_Window=#True)
  Declare    Container_Get_By_Coordinate(*Gadget.GADGET, *Container.Container, X, Y)
  Declare    Container_Merge_To_Parent(*Gadget.GADGET, *Container.Container)
  Declare    Container_Update_Limits(*Gadget.GADGET, *Container.Container)
  Declare   _Container_Delete(*Gadget.GADGET, *Container.Container, Iteration=0, Recursive=#True)
  Declare    Container_Set_Parent(*Gadget.GADGET, *Container.Container, *Parent.Container, Position)
  Declare    Container_Resize(*Gadget.GADGET, *Container.Container, X.l, Y.l, Width.d, Height.d, *Exclude_Resize.Container=#Null, Iteration=0)
  Declare    Container_Resize_Between(*Gadget.GADGET, *Container.Container, Index, Difference)
  
  Declare   _Docker_Add(*Gadget.GADGET, *Container.Container, Direction, *Window.Window, Iteration=0)
  
  ; ################################################## Image Init ###############################################
  Global Image_Diamond_Root_Left    = CatchImage(#PB_Any, ?Diamond_Root_Left)
  Global Image_Diamond_Root_Top     = CatchImage(#PB_Any, ?Diamond_Root_Top)
  Global Image_Diamond_Root_Right   = CatchImage(#PB_Any, ?Diamond_Root_Right)
  Global Image_Diamond_Root_Bottom  = CatchImage(#PB_Any, ?Diamond_Root_Bottom)
  Global Image_Diamond_Root_Inside  = CatchImage(#PB_Any, ?Diamond_Root_Inside)
  Global Image_Diamond_Left         = CatchImage(#PB_Any, ?Diamond_Left)
  Global Image_Diamond_Top          = CatchImage(#PB_Any, ?Diamond_Top)
  Global Image_Diamond_Right        = CatchImage(#PB_Any, ?Diamond_Right)
  Global Image_Diamond_Bottom       = CatchImage(#PB_Any, ?Diamond_Bottom)
  Global Image_Diamond_Tabbed       = CatchImage(#PB_Any, ?Diamond_Tabbed)
  Global Image_Button_Undock        = CatchImage(#PB_Any, ?Button_Undock)
  Global Image_Button_Close         = CatchImage(#PB_Any, ?Button_Close)
  
  ; ################################################## Functions ################################################
  Procedure.i GetManager()
    Static manager.GADGET_MANAGER
    ProcedureReturn @manager
  EndProcedure
  
  Procedure.i GetParams(*Gadget.GADGET)
    Protected *manager.GADGET_MANAGER=GetManager()
    ProcedureReturn *manager\GadgetParams(""+*Gadget)
  EndProcedure
  
  Procedure.i GetParams_By_Window(hWnd)
    Protected *manager.GADGET_MANAGER=GetManager()
    Protected *params.GADGET_PARAMS
    ForEach *manager\GadgetParams()
      *params = *manager\GadgetParams()
      ForEach *params\Window()
        If *params\Window()\hWnd = hWnd
          ProcedureReturn *params
        EndIf
      Next
    Next
  EndProcedure
  
  Procedure _FreeGadget(*Gadget.GADGET)
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      UnmanageGadget(GetManager(), \Root\Gadget_Container)
    EndWith
  EndProcedure
  
  Procedure _ResizeGadget(*Gadget.GADGET, x.l, y.l, w.l, h.l)
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      ManageGadgetCommands(GetManager(), \Root\Gadget_Container, #False) ;use default PB commands
      SendMessage_(GadgetID(\Root\Gadget_Container), #WM_SETREDRAW, #False, 0)
      ResizeGadget(\Root\Gadget_Container, x, y, w, h)
      ManageGadgetCommands(GetManager(), \Root\Gadget_Container, #True) ;use custom PB commands
      
      Container_Resize(*Gadget, \Root, 0, 0, w, h)
    EndWith
  EndProcedure
  
  Procedure _SetGadgetState(*Gadget.GADGET, State)
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
    EndWith
  EndProcedure
  
  Procedure.i _GetGadgetState(*Gadget.GADGET)
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
    EndWith
  EndProcedure
  
  Procedure Diamond_Create(*Gadget.GADGET, *Container.Container, X, Y, Direction, hWnd)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      AddElement(\Diamond())
      
      \Diamond()\Window = OpenWindow(#PB_Any, X, Y, #Diamond_Size, #Diamond_Size, "", #PB_Window_BorderLess | #PB_Window_NoActivate, hWnd)
      \Diamond()\hWnd = WindowID(\Diamond()\Window)
      \Diamond()\Gadget = *Gadget
      \Diamond()\X = X
      \Diamond()\Y = Y
      \Diamond()\Container = *Container
      \Diamond()\Direction = Direction
      
      \Diamond()\Gadget_Canvas = CanvasGadget(#PB_Any, 0, 0, #Diamond_Size, #Diamond_Size)
      
      If *Container = \Root
        Select Direction
          Case #Direction_Left
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Root_Left))
          Case #Direction_Top
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Root_Top))
          Case #Direction_Right
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Root_Right))
          Case #Direction_Bottom
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Root_Bottom))
          Case #Direction_Inside
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Root_Inside))
        EndSelect
      Else
        Select Direction
          Case #Direction_Left
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Left))
          Case #Direction_Top
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Top))
          Case #Direction_Right
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Right))
          Case #Direction_Bottom
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Bottom))
          Case #Direction_Inside
            SetGadgetAttribute(\Diamond()\Gadget_Canvas, #PB_Canvas_Image, ImageID(Image_Diamond_Tabbed))
        EndSelect
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Diamond_Delete(*Gadget.GADGET, *Diamond.Diamond)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    If Not *Diamond
      ProcedureReturn #Null
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      FreeGadget(*Diamond\Gadget_Canvas)
      
      ;unBindEvent(#PB_Event_MoveWindow, @Window_Callback_Move(), *Diamond\Window)
      CloseWindow(*Diamond\Window)
      
      ForEach \Diamond()
        If \Diamond() = *Diamond
          DeleteElement(\Diamond())
          Break
        EndIf
      Next
      
    EndWith
  EndProcedure
  
  Procedure Diamond_Get_By_Coordinate(*Gadget.GADGET, X, Y)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      ForEach \Diamond()
        If X >= \Diamond()\X And X < \Diamond()\X + #Diamond_Size And Y >= \Diamond()\Y And Y < \Diamond()\Y + #Diamond_Size
          ProcedureReturn \Diamond()
        EndIf
      Next
    EndWith
    ProcedureReturn #Null
  EndProcedure
  
  Procedure Window_Callback(hWnd, Message, wParam, lParam)
    Protected *Window.Window = Window_Get_By_Handle(hWnd)
    Protected *params.GADGET_PARAMS
    Protected *Container.Container
    Protected *Diamond.Diamond
    Protected *Rect.RECT
    Protected rect.RECT
    Protected *Points.POINTS
    Protected pt.Point
    Protected Center_X.l, Center_Y.l
    Protected i
    
    If Not *Window
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
    
    Select Message
      Case #WM_PARENTNOTIFY ; #WM_PARENTNOTIFY because of the canvas gadget
        Select wParam 
          Case #WM_LBUTTONDOWN, #WM_MBUTTONDOWN, #WM_RBUTTONDOWN, #WM_XBUTTONDOWN ; TODO: Find a bulletproof way to determine the active window (Not enabling the "Child" flag could help)
            If *Window\Container
              _Window_Set_Active(*Window\Gadget, *Window, #True)
            EndIf
        EndSelect
        
      Case #WM_LBUTTONDOWN, #WM_RBUTTONDOWN, #WM_XBUTTONDOWN
        _Window_Set_Active(*Window\Gadget, *Window, #True)
        
      Case #WM_ACTIVATE
        *params = GetParams(*Window\Gadget)
        With *params
          Select wParam
            Case #WA_ACTIVE
              _Window_Set_Active(*Window\Gadget, *Window, #False)
            Case #WA_CLICKACTIVE
              _Window_Set_Active(*Window\Gadget, *Window, #False)
            Case #WA_INACTIVE
              If \Active_Window = *Window
                ;_Window_Set_Active(*Window\Gadget, #Null, #False)
              EndIf
          EndSelect
        EndWith
        
      Case #WM_SETTEXT
        If *Window\Container
          *Window\Container\Title = PeekS(lParam)
          Container_Docker_Redraw(*Window\Gadget, *Window\Container)
          If *Window\Container\Parent And *Window\Container\Parent\Type = #Container_Type_Tabbed And *Window\Container\Parent\Gadget_TabBar
            For i = 0 To CountTabBarGadgetItems(*Window\Container\Parent\Gadget_TabBar)-1
              If GetTabBarGadgetItemData(*Window\Container\Parent\Gadget_TabBar, i) = *Window\Container
                SetTabBarGadgetItemText(*Window\Container\Parent\Gadget_TabBar, i, *Window\Container\Title)
                Break
              EndIf
            Next
          EndIf
        EndIf
        
      Case #WM_EXITSIZEMOVE
        *params = GetParams(*Window\Gadget)
        With *params
          If *Window\Mouse_Drag = #True
            *Window\Mouse_Drag = #False
            
            SetWindowLong_(*Window\hWnd,#GWL_EXSTYLE,GetWindowLong_(*Window\hWnd, #GWL_EXSTYLE) & ~#WS_EX_LAYERED)
            
            *Window\Mouse_Drag_Container = #Null
            
            *Diamond = Diamond_Get_By_Coordinate(*Window\Gadget, *Window\Mouse_Drag_X, *Window\Mouse_Drag_Y)
            If *Diamond
              _Docker_Add(*Window\Gadget, *Diamond\Container, *Diamond\Direction, *Window)
            EndIf
            
            ForEach \Diamond()
              Diamond_Delete(*Window\Gadget, \Diamond())
            Next
          EndIf
        EndWith
        
      Case #WM_MOVING
        *params = GetParams(*Window\Gadget)
        With *params
          *Rect = lParam
          GetWindowRect_(GadgetID(*params\Root\Gadget_Container), rect)
          If *Window\Mouse_Drag = #False
            *Window\Mouse_Drag = #True
            If ListSize(\Root\Container()) = 0
              Diamond_Create(*Window\Gadget, \Root, (rect\left+rect\right)/2-#Diamond_Size/2, (rect\top+rect\bottom)/2-#Diamond_Size/2, #Direction_Inside, *Window\hWnd)
            Else
              Diamond_Create(*Window\Gadget, \Root, rect\left, (rect\top+rect\bottom)/2-#Diamond_Size/2, #Direction_Left, *Window\hWnd)
              Diamond_Create(*Window\Gadget, \Root, (rect\left+rect\right)/2-#Diamond_Size/2, rect\top, #Direction_Top, *Window\hWnd)
              Diamond_Create(*Window\Gadget, \Root, rect\right-#Diamond_Size, (rect\top+rect\bottom)/2-#Diamond_Size/2, #Direction_Right, *Window\hWnd)
              Diamond_Create(*Window\Gadget, \Root, (rect\left+rect\right)/2-#Diamond_Size/2, rect\bottom-#Diamond_Size, #Direction_Bottom, *Window\hWnd)
            EndIf
          EndIf
          GetCursorPos_(pt)
          *Window\Mouse_Drag_X = pt\x;*Rect\left + *Window\Mouse_Drag_X_Offset
          *Window\Mouse_Drag_Y = pt\y;*Rect\top + *Window\Mouse_Drag_Y_Offset
          *Diamond = Diamond_Get_By_Coordinate(*Window\Gadget, *Window\Mouse_Drag_X, *Window\Mouse_Drag_Y)
          If *Diamond
            SetWindowLong_(*Window\hWnd,#GWL_EXSTYLE,GetWindowLong_(*Window\hWnd, #GWL_EXSTYLE) | #WS_EX_LAYERED)
            SetLayeredWindowAttributes_(*Window\hWnd,0,127,#LWA_ALPHA)
          Else
            SetWindowLong_(*Window\hWnd,#GWL_EXSTYLE,GetWindowLong_(*Window\hWnd, #GWL_EXSTYLE) & ~#WS_EX_LAYERED)
            ;SetLayeredWindowAttributes_(*Window\hWnd,0,255,#LWA_ALPHA)
            *Container = Container_Get_By_Coordinate(*Window\Gadget, *params\Root, *Window\Mouse_Drag_X - rect\left, *Window\Mouse_Drag_Y - rect\top)
            If *Window\Mouse_Drag_Container <> *Container
              If *Container <> *Window\Mouse_Drag_Container
                ForEach \Diamond()
                  If \Diamond()\Container = *Window\Mouse_Drag_Container
                    Diamond_Delete(*Window\Gadget, \Diamond())
                  EndIf
                Next
              EndIf
              *Window\Mouse_Drag_Container = *Container
              If *Container And *Container\Type = #Container_Type_Docker
                Center_X = *Container\X + *Container\Width/2 + rect\left
                Center_Y = *Container\Y + *Container\Height/2 + rect\top
                Diamond_Create(*Window\Gadget, *Container, Center_X - #Diamond_Size/2, Center_Y - #Diamond_Size/2, #Direction_Inside, *Window\hWnd)
                Diamond_Create(*Window\Gadget, *Container, Center_X - #Diamond_Size/2 - #Diamond_Size, Center_Y - #Diamond_Size/2, #Direction_Left, *Window\hWnd)
                Diamond_Create(*Window\Gadget, *Container, Center_X - #Diamond_Size/2, Center_Y - #Diamond_Size/2 - #Diamond_Size, #Direction_Top, *Window\hWnd)
                Diamond_Create(*Window\Gadget, *Container, Center_X - #Diamond_Size/2 + #Diamond_Size, Center_Y - #Diamond_Size/2, #Direction_Right, *Window\hWnd)
                Diamond_Create(*Window\Gadget, *Container, Center_X - #Diamond_Size/2, Center_Y - #Diamond_Size/2 + #Diamond_Size, #Direction_Bottom, *Window\hWnd)
              EndIf
            EndIf
          EndIf
        EndWith
        
      ;Case #WM_NCLBUTTONDOWN
        ;GetWindowRect_(hWnd, rect)
        ;*Points = @lParam
        ;*Window\Mouse_Drag_X_Offset = *Points\x - rect\left
        ;*Window\Mouse_Drag_Y_Offset = *Points\y - rect\top
        
    EndSelect
    
    If *Window\Callback
      ProcedureReturn *Window\Callback(hWnd, Message, wParam, lParam)
    Else
      ProcedureReturn #PB_ProcessPureBasicEvents
    EndIf
  EndProcedure
  
  Procedure Window_Add(Gadget, X, Y, Width, Height, Title.s, Flags, Resize_Priority.l=0)
    Protected *Gadget.GADGET = IsGadget(Gadget)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    Protected *Window.Window
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      *Window = AddElement(\Window())
      
      *Window\Window = OpenWindow(#PB_Any, X, Y, Width, Height, Title, Flags, WindowID(\Parent_Window))
      *Window\hWnd = WindowID(*Window\Window)
      *Window\Gadget = *Gadget
      ;SetWindowData(*Window\Window, *Window)
      SetWindowCallback(@Window_Callback(), *Window\Window)
      
      SmartWindowRefresh(*Window\Window, #True)
      
      *Window\Resize_Priority = Resize_Priority
      
      *Window\Flags_Normal = GetWindowLong_(*Window\hWnd, #GWL_STYLE)
      *Window\Flags_Docked = *Window\Flags_Normal
      *Window\Flags_Docked & ~#WS_POPUP
      *Window\Flags_Docked & ~#WS_SIZEBOX
      *Window\Flags_Docked & ~#WS_DLGFRAME
      *Window\Flags_Docked & ~#WS_BORDER
      *Window\Flags_Docked | #WS_CHILD
      ;*Window\Flags_Docked | #WS_EX_MDICHILD
      
      _Window_Set_Active(*Gadget, *Window, #False)
      
      If *Window\Flags_Normal & #WS_SIZEBOX
        _Window_Bounds(*Gadget, *Window, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
      Else
        *Window\Min_Width = Width
        *Window\Min_Height = Height
        *Window\Max_Width = *Window\Min_Width
        *Window\Max_Height = *Window\Min_Height
      EndIf
      
      ProcedureReturn *Window\Window
    EndWith
  EndProcedure
  
  Procedure _Window_Close(*Gadget.GADGET, *Window.Window)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Window
      ProcedureReturn #False
    EndIf
    Protected *Container.Container
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      If \Active_Window = *Window
        _Window_Set_Active(*Gadget, #Null)
      EndIf
      
      SetWindowCallback(#Null, *Window\Window)
      CloseWindow(*Window\Window) : *Window\Window = 0
      
      *Container = *Window\Container
      
      If ChangeCurrentElement(\Window(), *Window)
        DeleteElement(\Window())
      EndIf
      
      If *Container
        _Container_Delete(*Gadget, *Window\Container)
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Window_Close(Window)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Window
      ProcedureReturn #False
    EndIf
    ProcedureReturn _Window_Close(*Window\Gadget, *Window)
  EndProcedure
  
  Procedure _Window_Bounds(*Gadget.GADGET, *Window.Window, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Window
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If Min_Width = #PB_Default  : Min_Width  = GetSystemMetrics_(#SM_CXMINTRACK) : EndIf
      If Min_Height = #PB_Default : Min_Height = GetSystemMetrics_(#SM_CYMINTRACK) : EndIf
      If Max_Width = #PB_Default  : Max_Width  = GetSystemMetrics_(#SM_CXMAXTRACK) : EndIf
      If Max_Height = #PB_Default : Max_Height = GetSystemMetrics_(#SM_CYMAXTRACK) : EndIf
      If *Window\Flags_Normal & #WS_SIZEBOX
        *Window\Min_Width = Min_Width
        *Window\Min_Height = Min_Height
        *Window\Max_Width = Max_Width
        *Window\Max_Height = Max_Height
        WindowBounds(*Window\Window, Min_Width, Min_Height, Max_Width, Max_Height)
      Else
        *Window\Min_Width = WindowWidth(*Window\Window)
        *Window\Min_Height = WindowHeight(*Window\Window)
        *Window\Max_Width = *Window\Min_Width
        *Window\Max_Height = *Window\Min_Height
      EndIf
      
      If *Window\Container
        Container_Update_Limits(*Gadget, *Window\Container)
        ;Container_Resize(*Gadget, *Window\Container, *Window\Container\X, *Window\Container\Y, *Window\Container\Width, *Window\Container\Height)
        Container_Resize(*Gadget, \Root, 0, 0, GadgetWidth(\Root\Gadget_Container), GadgetHeight(\Root\Gadget_Container))
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Window_Bounds(Window, Min_Width.l, Min_Height.l, Max_Width.l, Max_Height.l)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Window
      ProcedureReturn #False
    EndIf
    ProcedureReturn _Window_Bounds(*Window\Gadget, *Window, Min_Width, Min_Height, Max_Width, Max_Height)
  EndProcedure
  
  Procedure _Window_Set_Active(*Gadget.GADGET, *Window.Window, Post_Event=#False, Tabbed_Select=#True)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    Protected *Old_Container.Container
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If \Active_Window = *Window
        ProcedureReturn #True
      EndIf
      
      If \Active_Window
        *Old_Container = \Active_Window\Container
      EndIf
      
      \Active_Window = *Window
      
      ; #### Redraw the previously active container
      If *Old_Container
        Container_Docker_Redraw(*Gadget, *Old_Container)
      EndIf
      
      If *Window
        If *Window\Container
          ; #### Change the current tab, if it is in any
          If Tabbed_Select
            Container_Tabbed_Select(*Gadget, *Window\Container, 0)
          EndIf
          
          ; #### Redraw the active container
          ;SetActiveWindow(\Parent_Window)
          Container_Docker_Redraw(*Gadget, *Window\Container)
          If Post_Event
            PostEvent(#PB_Event_ActivateWindow, *Window\Window, 0)
          EndIf
        Else
          SetActiveWindow(*Window\Window)
        EndIf
      EndIf
      
    EndWith
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Set_Active(Window)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Window
      ProcedureReturn #False
    EndIf
    ProcedureReturn _Window_Set_Active(*Window\Gadget, *Window, #True)
  EndProcedure
  
  Procedure Window_Get_Active(Gadget)
    Protected *Gadget.GADGET = IsGadget(Gadget)
    If Not *Gadget
      ProcedureReturn 0
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If \Active_Window
        ProcedureReturn \Active_Window\Window
      Else
        ProcedureReturn 0
      EndIf
    EndWith
  EndProcedure
  
  Procedure Window_Set_Callback(Window, *Callback)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Window
      ProcedureReturn #False
    EndIf
    *Window\Callback = *Callback
    ProcedureReturn #True
  EndProcedure
  
  Procedure Window_Get_Container(Window)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Window
      ProcedureReturn #Null
    EndIf
    
    ProcedureReturn *Window\Container
  EndProcedure
  
  Procedure.i Window_Get_By_Handle(hWnd)
    Protected *manager.GADGET_MANAGER=GetManager()
    Protected *params.GADGET_PARAMS
    ForEach *manager\GadgetParams()
      *params = *manager\GadgetParams()
      ForEach *params\Window()
        If *params\Window()\hWnd = hWnd
          ProcedureReturn *params\Window()
        EndIf
      Next
    Next
    ProcedureReturn #Null
  EndProcedure
  
  Procedure.i Window_Get_By_Number(Window)
    Protected *manager.GADGET_MANAGER=GetManager()
    Protected *params.GADGET_PARAMS
    ForEach *manager\GadgetParams()
      *params = *manager\GadgetParams()
      ForEach *params\Window()
        If *params\Window()\Window = Window
          ProcedureReturn *params\Window()
        EndIf
      Next
    Next
    ProcedureReturn #Null
  EndProcedure
  
  Procedure Container_Docker_Button_Redraw(*Button.Canvas_Button)
    DrawingMode(#PB_2DDrawing_Default)
    Select *Button\State
      Case #Canvas_Button_State_Hover
        Box(*Button\X, *Button\Y, *Button\Width, *Button\Height, #Color_Button_Hover)
      Case #Canvas_Button_State_Pressed
        Box(*Button\X, *Button\Y, *Button\Width, *Button\Height, #Color_Button_Pressed)
    EndSelect
    
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    
    DrawImage(ImageID(*Button\Image), *Button\X, *Button\Y)
  EndProcedure
  
  Procedure Container_Docker_Redraw(*Gadget.GADGET, *Container.Container)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If StartDrawing(CanvasOutput(*Container\Gadget_Canvas))
        If *Container\Window And \Active_Window = *Container\Window
          Box(0, 0, *Container\Width, *Container\Height, #Color_Docker_Background_Active)
        Else
          Box(0, 0, *Container\Width, *Container\Height, #Color_Docker_Background)
        EndIf
        DrawingMode(#PB_2DDrawing_Transparent)
        DrawingFont(\FontID)
        DrawText(1, 1, *Container\Title, 0)
        If *Container\Window And \Active_Window = *Container\Window
          Box(*Container\Width-32, 0, 32, *Container\Height, #Color_Docker_Background_Active)
        Else
          Box(*Container\Width-32, 0, 32, *Container\Height, #Color_Docker_Background)
        EndIf
        Container_Docker_Button_Redraw(*Container\Docker_Button_Close)
        Container_Docker_Button_Redraw(*Container\Docker_Button_Undock)
        StopDrawing()
      EndIf
    EndWith
  EndProcedure
  
  Procedure Container_Docker_Button_Handler(*Gadget.GADGET, *Container.Container, *Button.Canvas_Button)
    Protected Event_Type = EventType()
    Protected X, Y
    Protected Result = #False
    Protected Changed = #False
    
    Select Event_Type
      Case #PB_EventType_LeftButtonDown
        X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        If X >= *Button\X And Y >= *Button\Y And X < *Button\X + *Button\Width And Y < *Button\Y + *Button\Height
          *Button\State = #Canvas_Button_State_Pressed : Changed = #True
        EndIf
        
      Case #PB_EventType_MouseMove
        X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        If X >= *Button\X And Y >= *Button\Y And X < *Button\X + *Button\Width And Y < *Button\Y + *Button\Height
          Select *Button\State
            Case #Canvas_Button_State_Pressed_Outside : *Button\State = #Canvas_Button_State_Pressed : Changed = #True
            Case #Canvas_Button_State_Normal : *Button\State = #Canvas_Button_State_Hover : Changed = #True
          EndSelect
        Else
          Select *Button\State
            Case #Canvas_Button_State_Pressed : *Button\State = #Canvas_Button_State_Pressed_Outside : Changed = #True
            Case #Canvas_Button_State_Hover : *Button\State = #Canvas_Button_State_Normal : Changed = #True
          EndSelect
        EndIf
        
      Case #PB_EventType_MouseLeave
        Select *Button\State
          Case #Canvas_Button_State_Hover : *Button\State = #Canvas_Button_State_Normal : Changed = #True
        EndSelect
        
      Case #PB_EventType_LeftButtonUp
        X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        If X >= *Button\X And Y >= *Button\Y And X < *Button\X + *Button\Width And Y < *Button\Y + *Button\Height
          If *Button\State = #Canvas_Button_State_Pressed
            Result = #True
          EndIf
          *Button\State = #Canvas_Button_State_Hover : Changed = #True
        Else
          *Button\State = #Canvas_Button_State_Normal : Changed = #True
        EndIf
        
    EndSelect
    
    If Changed
      Container_Docker_Redraw(*Gadget, *Container)
    EndIf
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure Container_Docker_Callback_Gadget_Canvas()
    Protected *Container.Container = GetGadgetData(EventGadget())
    Protected Event_Type = EventType()
    Protected *params.GADGET_PARAMS
    Protected *Window.Window
    Protected rect.RECT, pt.Point, pts.POINTS
    Protected X, Y
    
    ; #### Buttons
    ; TODO: Put the buttons into their own canvas
    If Container_Docker_Button_Handler(*Container\Gadget, *Container, *Container\Docker_Button_Close)
      If *Container\Window
        PostEvent(#PB_Event_CloseWindow, *Container\Window\Window, 0)
      EndIf
    EndIf
    If Container_Docker_Button_Handler(*Container\Gadget, *Container, *Container\Docker_Button_Undock)
      If *Container\Window
        _Container_Delete(*Container\Gadget, *Container)
      EndIf
    EndIf
    
    ; #### Drag window stuff
    Select Event_Type
      Case #PB_EventType_LeftButtonDown
        *Container\Drag = #True
        *Container\Drag_X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        *Container\Drag_Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        _Window_Set_Active(*Container\Gadget, *Container\Window, #True, #False)
        
      Case #PB_EventType_MouseMove
        If *Container\Drag
          X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
          Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
          If Abs(X - *Container\Drag_X) > #Container_Docker_Drag_Start_Min Or Abs(Y - *Container\Drag_Y) > #Container_Docker_Drag_Start_Min
            *Container\Drag = #False
            *Window = *Container\Window
            GetCursorPos_(pt)
            pts\x = pt\x
            pts\y = pt\y
            _Container_Delete(*Container\Gadget, *Container)
            ResizeWindow(*Window\Window, WindowX(*Window\Window) + X - *Container\Drag_X, WindowY(*Window\Window) + Y - *Container\Drag_Y, #PB_Ignore, #PB_Ignore)
            SendMessage_(*Window\hWnd, #WM_NCLBUTTONDOWN, #HTCAPTION, PeekL(pts))
          EndIf
        EndIf
        
      Case #PB_EventType_LeftButtonUp
        *Container\Drag = #False
        
    EndSelect
    
  EndProcedure
  
  Procedure Container_Callback_Gadget_Canvas()
    Protected *Container.Container = GetGadgetData(EventGadget())
    Protected Event_Type = EventType()
    Protected *params.GADGET_PARAMS
    Protected rect.RECT
    Protected Index
    Protected Difference
    
    Select Event_Type
      Case #PB_EventType_LeftButtonDown
        *Container\Drag = #True
        *Container\Drag_X = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX)
        *Container\Drag_Y = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY)
        
      Case #PB_EventType_MouseMove
        If *Container\Parent And *Container\Drag
          ForEach *Container\Parent\Container()
            If *Container\Parent\Container() = *Container
              Index = ListIndex(*Container\Parent\Container())
              Break
            EndIf
          Next
          Select *Container\Parent\Type
            Case #Container_Type_Split_H : Difference = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseX) - *Container\Drag_X
            Case #Container_Type_Split_V : Difference = GetGadgetAttribute(EventGadget(), #PB_Canvas_MouseY) - *Container\Drag_Y
          EndSelect
          If Difference
            Container_Resize_Between(*Container\Gadget, *Container\Parent, Index, Difference)
          EndIf
        EndIf
        
      Case #PB_EventType_LeftButtonUp
        *Container\Drag = #False
        ;*params = GetParams(*Container\Gadget)
        ;With *params
          ;GetClientRect_(GadgetID(\Root\Gadget_Container), rect)
          ;InvalidateRect_(GadgetID(\Root\Gadget_Container), rect, #True)
        ;EndWith
        
    EndSelect
    
  EndProcedure
  
  Procedure Container_Callback_Gadget_TabBar()
    Protected *Container.Container = GetTabBarGadgetData(EventGadget())
    Protected Event_Type = EventType()
    Protected *params.GADGET_PARAMS
    Protected Index
    
    Select Event_Type
      Case #TabBarGadget_EventType_Change
        ForEach *Container\Container()
          If *Container\Container() = GetTabBarGadgetItemData(EventGadget(), #TabBarGadgetItem_Event)
            Container_Tabbed_Select(*Container\Gadget, *Container, ListIndex(*Container\Container()), #False)
            Break
          EndIf
        Next
        
    EndSelect
    
  EndProcedure
  
  Procedure Container_Hide(*Gadget.GADGET, *Container.Container, State, Iteration=0)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      If Iteration = 0
        *Container\Hidden = State
      Else
        *Container\Hidden_Inherit = State
      EndIf
      
      If *Container\Hidden_Inherit Or *Container\Hidden
        State = #True
      EndIf
      
      Select *Container\Type
        Case #Container_Type_Root
          ForEach *Container\Container()
            Container_Hide(*Gadget, *Container\Container(), State, Iteration+1)
          Next
          
        Case #Container_Type_Docker
          If *Container\Window
            HideWindow(*Container\Window\Window, State)
          EndIf
          HideGadget(*Container\Gadget_Canvas, State)
          
        Case #Container_Type_Split_H
          ForEach *Container\Container()
            Container_Hide(*Gadget, *Container\Container(), State, Iteration+1)
          Next
          
        Case #Container_Type_Split_V
          ForEach *Container\Container()
            Container_Hide(*Gadget, *Container\Container(), State, Iteration+1)
          Next
          
        Case #Container_Type_Spliter
          HideGadget(*Container\Gadget_Canvas, State)
          
        Case #Container_Type_Tabbed
          HideGadget(*Container\Gadget_TabBar, State)
          ForEach *Container\Container()
            Container_Hide(*Gadget, *Container\Container(), State, Iteration+1)
          Next
          
      EndSelect
      
      If *Container\Gadget_Empty[0]
        HideGadget(*Container\Gadget_Empty[0], State)
      EndIf
      If *Container\Gadget_Empty[1]
        HideGadget(*Container\Gadget_Empty[1], State)
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Container_Tabbed_Select(*Gadget.GADGET, *Container.Container, Selection, SetGadgetState=#True, Activate_Window=#True)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected i
    Protected *Selection.Container
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      ; #### Recursively go throught the parents and select the according tabs
      If *Container\Parent
        If *Container\Parent\Type = #Container_Type_Tabbed
          ForEach *Container\Parent\Container()
            If *Container\Parent\Container() = *Container
              Container_Tabbed_Select(*Gadget, *Container\Parent, ListIndex(*Container\Parent\Container()), SetGadgetState, #False)
              Break
            EndIf
          Next
        Else
          Container_Tabbed_Select(*Gadget, *Container\Parent, 0, SetGadgetState, #False)
        EndIf
      EndIf
      
      If *Container\Type = #Container_Type_Tabbed
        
        If Selection > ListSize(*Container\Container())-1
          Selection = ListSize(*Container\Container())-1
        ElseIf Selection < 0 ; #### -1 will point to the end of the list
          Selection = ListSize(*Container\Container())-1
        EndIf
        
        *Container\Tabbed_Selection = Selection
        
        ForEach *Container\Container()
          If ListIndex(*Container\Container()) = *Container\Tabbed_Selection
            *Selection = *Container\Container()
            Container_Hide(*Gadget, *Container\Container(), #False)
            If Activate_Window
              _Window_Set_Active(*Gadget, *Container\Container()\Window, #True, #False)
            EndIf
          Else
            Container_Hide(*Gadget, *Container\Container(), #True)
          EndIf
        Next
        
        ; #### Set the GadgetState
        If SetGadgetState And *Selection And *Container\Gadget_TabBar
          For i = 0 To CountTabBarGadgetItems(*Container\Gadget_TabBar)-1
            If GetTabBarGadgetItemData(*Container\Gadget_TabBar, i) = *Selection
              SetTabBarGadgetState(*Container\Gadget_TabBar, i)
              Break
            EndIf
          Next
        EndIf
        
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Container_Update_Priority(*Gadget.GADGET, *Container.Container)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected Temp, Min
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      Min = *Container\Priority
      PushListPosition(*Container\Container())
      ForEach *Container\Container()
        Temp = Container_Update_Priority(*Gadget, *Container\Container())
        If Min < Temp
          Min = Temp
        EndIf
      Next
      PopListPosition(*Container\Container())
      *Container\Priority_Inerhit = Min
      ProcedureReturn Min
    EndWith
  EndProcedure
  
  Procedure Container_Update_Limits(*Gadget.GADGET, *Container.Container)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      Select *Container\Type
        Case #Container_Type_Root
          *Container\Min_Width = 0
          *Container\Min_Height = 0
          *Container\Max_Width = #Container_Size_Max
          *Container\Max_Height = #Container_Size_Max
          If FirstElement(*Container\Container())
            *Container\Min_Width = *Container\Container()\Min_Width
            *Container\Min_Height = *Container\Container()\Min_Height
            *Container\Max_Width = *Container\Container()\Max_Width
            *Container\Max_Height = *Container\Container()\Max_Height
          EndIf
        Case #Container_Type_Docker
          If *Container\Window
            *Container\Min_Width = *Container\Window\Min_Width
            *Container\Min_Height = *Container\Window\Min_Height + #Container_Docker_Bar_Height
            *Container\Max_Width = *Container\Window\Max_Width
            *Container\Max_Height = *Container\Window\Max_Height + #Container_Docker_Bar_Height
          Else
            *Container\Min_Width = 100
            *Container\Min_Height = 100
            *Container\Max_Width = #Container_Size_Max
            *Container\Max_Height = #Container_Size_Max
          EndIf
          
        Case #Container_Type_Split_H
          *Container\Min_Width = 0
          *Container\Min_Height = 0
          *Container\Max_Width = 0
          *Container\Max_Height = 0;#Container_Size_Max
          ForEach *Container\Container()
            *Container\Min_Width + *Container\Container()\Min_Width
            *Container\Max_Width + *Container\Container()\Max_Width
            If *Container\Min_Height < *Container\Container()\Min_Height
              *Container\Min_Height = *Container\Container()\Min_Height
            EndIf
            If *Container\Max_Height < *Container\Container()\Max_Height
              *Container\Max_Height = *Container\Container()\Max_Height
            EndIf
          Next
        Case #Container_Type_Split_V
          *Container\Min_Width = 0
          *Container\Min_Height = 0
          *Container\Max_Width = 0;#Container_Size_Max
          *Container\Max_Height = 0
          ForEach *Container\Container()
            *Container\Min_Height + *Container\Container()\Min_Height
            *Container\Max_Height + *Container\Container()\Max_Height
            If *Container\Min_Width < *Container\Container()\Min_Width
              *Container\Min_Width = *Container\Container()\Min_Width
            EndIf
            If *Container\Max_Width < *Container\Container()\Max_Width
              *Container\Max_Width = *Container\Container()\Max_Width
            EndIf
          Next
        Case #Container_Type_Spliter
          If *Container\Parent
            Select *Container\Parent\Type
              Case #Container_Type_Split_H
                *Container\Min_Width = #Splitter_Size
                *Container\Max_Width = #Splitter_Size
                *Container\Min_Height = #Container_Size_Ignore
                *Container\Max_Height = #Container_Size_Ignore
              Case #Container_Type_Split_V
                *Container\Min_Width = #Container_Size_Ignore
                *Container\Max_Width = #Container_Size_Ignore
                *Container\Min_Height = #Splitter_Size
                *Container\Max_Height = #Splitter_Size
            EndSelect
          EndIf
        Case #Container_Type_Tabbed
          *Container\Min_Width = 0
          *Container\Min_Height = 0
          *Container\Max_Width = 0
          *Container\Max_Height = 0
          ForEach *Container\Container()
            If *Container\Min_Width < *Container\Container()\Min_Width
              *Container\Min_Width = *Container\Container()\Min_Width
            EndIf
            If *Container\Max_Width < *Container\Container()\Max_Width
              *Container\Max_Width = *Container\Container()\Max_Width
            EndIf
            If *Container\Min_Height < *Container\Container()\Min_Height + #Container_Tabbed_Bar_Height
              *Container\Min_Height = *Container\Container()\Min_Height + #Container_Tabbed_Bar_Height
            EndIf
            If *Container\Max_Height < *Container\Container()\Max_Height + #Container_Tabbed_Bar_Height
              *Container\Max_Height = *Container\Container()\Max_Height + #Container_Tabbed_Bar_Height
            EndIf
          Next
      EndSelect
      ; #### Recursively go throught the tree
      If *Container\Parent
        Container_Update_Limits(*Gadget, *Container\Parent)
      EndIf
    EndWith
  EndProcedure
  
  Procedure Container_Add(*Gadget.GADGET, X.l, Y.l, Width.l, Height.l, Type, *Window.Window=#Null)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    Protected *Container.Container
    Protected GWL_Style
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      *Container = AllocateStructure(Container)
      *Container\Gadget = *Gadget
      *Container\Type = Type
      *Container\X = X
      *Container\Y = Y
      *Container\Width = Width
      *Container\Height = Height
      *Container\Window = *Window
      *Container\Priority = -2147483648
      
      Select *Container\Type
        Case #Container_Type_Docker
          OpenGadgetList(\Root\Gadget_Container)
          *Container\Gadget_Canvas = CanvasGadget(#PB_Any, *Container\X, *Container\Y, *Container\Width, #Container_Docker_Bar_Height)
          *Container\Docker_Button_Close\Width = 16 : *Container\Docker_Button_Close\Height = 16 : *Container\Docker_Button_Close\Image = Image_Button_Close
          *Container\Docker_Button_Undock\Width = 16 : *Container\Docker_Button_Undock\Height = 16 : *Container\Docker_Button_Undock\Image = Image_Button_Undock
          BindGadgetEvent(*Container\Gadget_Canvas, @Container_Docker_Callback_Gadget_Canvas()) : SetGadgetData(*Container\Gadget_Canvas, *Container)
          *Container\Gadget_Empty[0] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          *Container\Gadget_Empty[1] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          If *Container\Window
            *Container\Priority = *Container\Window\Resize_Priority
            *Container\Title = GetWindowTitle(*Window\Window)
            *Container\Window\Container = *Container
          EndIf
          CloseGadgetList()
          If *Container\Window
            SetWindowLong_(*Container\Window\hWnd, #GWL_STYLE, *Container\Window\Flags_Docked)
            SetParent_(*Container\Window\hWnd, GadgetID(\Root\Gadget_Container))
            ResizeWindow(*Container\Window\Window, *Container\X, *Container\Y+#Container_Docker_Bar_Height, *Container\Width, *Container\Height-#Container_Docker_Bar_Height)
            PostEvent(#PB_Event_SizeWindow, *Container\Window\Window, 0)
          EndIf
          
        Case #Container_Type_Split_H
          OpenGadgetList(\Root\Gadget_Container)
          *Container\Gadget_Empty[0] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          *Container\Gadget_Empty[1] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          CloseGadgetList()
          
        Case #Container_Type_Split_V
          OpenGadgetList(\Root\Gadget_Container)
          *Container\Gadget_Empty[0] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          *Container\Gadget_Empty[1] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          CloseGadgetList()
          
        Case #Container_Type_Spliter
          OpenGadgetList(\Root\Gadget_Container)
          *Container\Gadget_Canvas = CanvasGadget(#PB_Any, *Container\X, *Container\Y, *Container\Width, *Container\Height)
          BindGadgetEvent(*Container\Gadget_Canvas, @Container_Callback_Gadget_Canvas()) : SetGadgetData(*Container\Gadget_Canvas, *Container)
          CloseGadgetList()
          
        Case #Container_Type_Tabbed
          OpenGadgetList(\Root\Gadget_Container)
          *Container\Gadget_TabBar = TabBarGadget(#PB_Any, *Container\X, *Container\Y, *Container\Width, #Container_Tabbed_Bar_Height, #TabBarGadget_None, \Parent_Window)
          BindGadgetEvent(*Container\Gadget_TabBar, @Container_Callback_Gadget_TabBar()) : SetTabBarGadgetData(*Container\Gadget_TabBar, *Container)
          *Container\Gadget_Empty[0] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          *Container\Gadget_Empty[1] = CanvasGadget(#PB_Any, 0, 0, 0, 0)
          CloseGadgetList()
          
        Default
          FreeStructure(*Container) : *Container = #Null
          ProcedureReturn #Null
      EndSelect
    EndWith
    
    ; #### Merge containers of the same type
    ForEach *Container\Container()
      If *Container\Container()\Type = *Container\Type
        Container_Merge_To_Parent(*Gadget, *Container\Container())
      EndIf
    Next
    
    ProcedureReturn *Container
  EndProcedure
  
  Procedure _Container_Delete(*Gadget.GADGET, *Container.Container, Iteration=0, Recursive=#True)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    Protected Splitter_Bool
    Protected rect.RECT
    Protected i
    Protected Active_Gadget.i
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If Recursive
        ForEach *Container\Container()
          _Container_Delete(*Gadget, *Container\Container(), Iteration+1)
        Next
      EndIf
      
      If *Container\Window
        *Container\Window\Container = #Null
      EndIf
      
      If *Container\Parent
        ; #### Remove pointer from the parent
        ForEach *Container\Parent\Container()
          If *Container\Parent\Container() = *Container
            DeleteElement(*Container\Parent\Container())
            Break
          EndIf
        Next
        
        ; #### Remove tab if the parent is #Container_Type_Tabbed
        If *Container\Parent\Type = #Container_Type_Tabbed And *Container\Parent\Gadget_TabBar And Iteration = 0
          For i = 0 To CountTabBarGadgetItems(*Container\Parent\Gadget_TabBar)-1
            If GetTabBarGadgetItemData(*Container\Parent\Gadget_TabBar, i) = *Container
              RemoveTabBarGadgetItem(*Container\Parent\Gadget_TabBar, i)
              Container_Tabbed_Select(*Gadget, *Container\Parent, *Container\Parent\Tabbed_Selection)
              Break
            EndIf
          Next
        EndIf
      EndIf
      
      ; #### Remove splitters
      If *Container\Parent And Iteration = 0
        Splitter_Bool = #False
        ForEach *Container\Parent\Container()
          Select *Container\Parent\Container()\Type
            Case #Container_Type_Spliter
              If Splitter_Bool = #False Or ListIndex(*Container\Parent\Container()) = ListSize(*Container\Parent\Container())-1
                _Container_Delete(*Gadget, *Container\Parent\Container(), Iteration+1)
                ;FirstElement(*Container\Parent\Container())
              EndIf
              Splitter_Bool = #False
            Default
              Splitter_Bool = #True
          EndSelect
        Next
      EndIf
      
       ; #### Update limits and resize
      If *Container\Parent And Iteration = 0
        Container_Update_Limits(*Gadget, *Container\Parent)
        Container_Resize(*Gadget, \Root, 0, 0, GadgetWidth(\Root\Gadget_Container), GadgetHeight(\Root\Gadget_Container))
      EndIf
      
      ; #### Clean tree
      If *Container\Parent And Iteration = 0
        If ListSize(*Container\Parent\Container()) < 2
          Container_Merge_To_Parent(*Gadget, *Container\Parent)
        EndIf
      EndIf
      
      ; #### Unregister events, Unparent window
      Select *Container\Type
        Case #Container_Type_Docker
          If IsGadget(*Container\Gadget_Canvas) : UnbindGadgetEvent(*Container\Gadget_Canvas, @Container_Docker_Callback_Gadget_Canvas()) : EndIf
          If *Container\Window And IsWindow(*Container\Window\Window)
            GetWindowRect_(GadgetID(\Root\Gadget_Container), rect)
            Active_Gadget = GetActiveGadget()
            SetWindowLong_(*Container\Window\hWnd, #GWL_STYLE, *Container\Window\Flags_Normal)
            SetParent_(*Container\Window\hWnd, #Null)
            If Active_Gadget : SetActiveGadget(Active_Gadget) : EndIf
            rect\left + *Container\X
            rect\top + *Container\Y + #Container_Docker_Bar_Height
            rect\right = rect\left + *Container\Width
            rect\bottom = rect\top + *Container\Height - #Container_Docker_Bar_Height
            AdjustWindowRectEx_(rect, GetWindowLong_(*Container\Window\hWnd, #GWL_STYLE), #Null, GetWindowLong_(*Container\Window\hWnd, #GWL_EXSTYLE))
            ResizeWindow(*Container\Window\Window, rect\left, rect\top, *Container\Width, *Container\Height-#Container_Docker_Bar_Height)
         EndIf
         
        Case #Container_Type_Spliter
          If IsGadget(*Container\Gadget_Canvas) : UnbindGadgetEvent(*Container\Gadget_Canvas, @Container_Callback_Gadget_Canvas()) : EndIf
          
        Case #Container_Type_Tabbed
          If IsGadget(*Container\Gadget_TabBar) : UnbindGadgetEvent(*Container\Gadget_TabBar, @Container_Callback_Gadget_TabBar()) : EndIf
          
      EndSelect
      
      ; #### Free gadgets....
      If IsGadget(*Container\Gadget_Canvas)     : FreeGadget(*Container\Gadget_Canvas)        : EndIf
      If IsGadget(*Container\Gadget_Text)       : FreeGadget(*Container\Gadget_Text)          : EndIf
      If IsGadget(*Container\Gadget_Container)  : FreeGadget(*Container\Gadget_Container)     : EndIf
      If IsGadget(*Container\Gadget_TabBar)     : FreeTabBarGadget(*Container\Gadget_TabBar)  : EndIf
      If IsGadget(*Container\Gadget_Empty[0])   : FreeGadget(*Container\Gadget_Empty[0])      : EndIf
      If IsGadget(*Container\Gadget_Empty[1])   : FreeGadget(*Container\Gadget_Empty[1])      : EndIf
      
      FreeStructure(*Container)
      
    EndWith
  EndProcedure
  
  Procedure Container_Delete(Gadget, *Container.Container)
    ProcedureReturn _Container_Delete(IsGadget(Gadget), *Container)
  EndProcedure
  
  Procedure Container_Get_By_Coordinate(*Gadget.GADGET, *Container.Container, X, Y)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    If Not *Container
      ProcedureReturn #Null
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      If X >= *Container\X And Y >= *Container\Y And X < *Container\X + *Container\Width And Y < *Container\Y + *Container\Height And *Container\Hidden = #False And *Container\Hidden_Inherit = #False
        ForEach *Container\Container()
          If X >= *Container\Container()\X And Y >= *Container\Container()\Y And X < *Container\Container()\X + *Container\Container()\Width And Y < *Container\Container()\Y + *Container\Container()\Height And *Container\Container()\Hidden = #False And *Container\Container()\Hidden_Inherit = #False
            ProcedureReturn Container_Get_By_Coordinate(*Gadget, *Container\Container(), X, Y)
          EndIf
        Next
        
        ProcedureReturn *Container
      EndIf
    EndWith
    
    ProcedureReturn #Null
  EndProcedure
  
  Procedure Container_Merge_To_Parent(*Gadget.GADGET, *Container.Container)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    If Not *Container\Parent
      ProcedureReturn #False
    EndIf
    Protected List_Index
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      ForEach *Container\Parent\Container()
        If *Container\Parent\Container() = *Container
          List_Index = ListIndex(*Container\Parent\Container())
          Break
        EndIf
      Next
      While LastElement(*Container\Container())
        Container_Set_Parent(*Gadget, *Container\Container(), *Container\Parent, List_Index)
      Wend
      
      _Container_Delete(*Gadget, *Container, 0, #False)
      
      ; #### Merge containers of the same type
      ; TODO: Check recursion in Container_Merge_To_Parent
      If *Container\Parent
        ForEach *Container\Parent\Container()
          If *Container\Parent\Container()\Type = *Container\Parent\Type
            Container_Merge_To_Parent(*Gadget, *Container\Parent\Container())
          EndIf
        Next
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Container_Set_Parent(*Gadget.GADGET, *Container.Container, *Parent.Container, Position)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    If Not *Parent
      ProcedureReturn #False
    EndIf
    Protected Index, i
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      If *Container\Parent
        ; #### Detach from old parent
        ForEach *Container\Parent\Container()
          If *Container\Parent\Container() = *Container
            DeleteElement(*Container\Parent\Container())
            Break
          EndIf
        Next
        Container_Update_Limits(*Gadget, *Container\Parent)
        
        ; #### Remove tab if the parent is #Container_Type_Tabbed
        If *Container\Parent\Type = #Container_Type_Tabbed And *Container\Parent\Gadget_TabBar
          For i = 0 To CountTabBarGadgetItems(*Container\Parent\Gadget_TabBar)-1
            If GetTabBarGadgetItemData(*Container\Parent\Gadget_TabBar, i) = *Container
              RemoveTabBarGadgetItem(*Container\Parent\Gadget_TabBar, i)
              Break
            EndIf
          Next
        EndIf
      EndIf
      
      *Container\Parent = *Parent
      If Position >= 0 And SelectElement(*Container\Parent\Container(), Position)
        InsertElement(*Container\Parent\Container())
      Else
        LastElement(*Container\Parent\Container())
        AddElement(*Container\Parent\Container())
      EndIf
      *Container\Parent\Container() = *Container
      
      Select *Container\Parent\Type
        Case #Container_Type_Tabbed
          Index = AddTabBarGadgetItem(*Container\Parent\Gadget_TabBar, #PB_Default, *Container\Title)
          SetTabBarGadgetItemData(*Container\Parent\Gadget_TabBar, Index, *Container)
          Container_Tabbed_Select(*Gadget, *Container\Parent, Position)
          ;UpdateTabBarGadget(*Container\Parent\Gadget_TabBar)
          
      EndSelect
      
      Container_Hide(*Gadget, *Container\Parent, *Container\Parent\Hidden)
      
      Container_Update_Priority(*Gadget, \Root)
      Container_Update_Limits(*Gadget, *Container)
      ;Container_Resize(*Gadget, \Root, 0, 0, GadgetWidth(\Root\Gadget_Container), GadgetHeight(\Root\Gadget_Container))
      
    EndWith
  EndProcedure
  
  Procedure Container_Resize(*Gadget.GADGET, *Container.Container, X.l, Y.l, Width.d, Height.d, *Resize_Lowpriority.Container=#Null, Iteration=0)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    If Not *Container
      ProcedureReturn #False
    EndIf
    ;Protected Effective_Size.d
    Protected Position
    Protected Scale.d, Total_Size.l
    Protected Width_Pre_Limit.l, Height_Pre_Limit.l
    Protected Old_Size, Difference
    Protected Found
    Protected NewList Temp_Size.Temp_Size()
    Protected NewList Priority.l()
    Protected hWnd, rect.RECT
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      Width_Pre_Limit = Width
      Height_Pre_Limit = Height
      
      If Width < 0  : Width = 0  : EndIf
      If Height < 0 : Height = 0 : EndIf
      If *Container\Min_Width >= 0  And Width < *Container\Min_Width   : Width = *Container\Min_Width   : EndIf
      If *Container\Min_Height >= 0 And Height < *Container\Min_Height : Height = *Container\Min_Height : EndIf
      If *Container\Max_Width >= 0  And Width > *Container\Max_Width   : Width = *Container\Max_Width   : EndIf
      If *Container\Max_Height >= 0 And Height > *Container\Max_Height : Height = *Container\Max_Height : EndIf
      
      If Iteration = 0
        SendMessage_(GadgetID(\Root\Gadget_Container), #WM_SETREDRAW, #False, 0)
      EndIf
      
      Select *Container\Type
        Case #Container_Type_Root
          ForEach *Container\Container()
            Container_Resize(*Gadget, *Container\Container(), X, Y, Width, Height, *Resize_Lowpriority, Iteration+1)
          Next
          
        Case #Container_Type_Split_H
          ForEach *Container\Container()
            AddElement(Temp_Size())
            Temp_Size()\Container = *Container\Container()
            Temp_Size()\Min_Size = *Container\Container()\Min_Width
            Temp_Size()\Max_Size = *Container\Container()\Max_Width
            If Temp_Size()\Container = *Resize_Lowpriority
              Temp_Size()\Priority = -2147483648
            Else
              Temp_Size()\Priority = *Container\Container()\Priority_Inerhit
            EndIf
            Temp_Size()\Size = *Container\Container()\Width
            If Temp_Size()\Min_Size >= 0 And Temp_Size()\Size < Temp_Size()\Min_Size : Temp_Size()\Size = Temp_Size()\Min_Size : EndIf
            If Temp_Size()\Max_Size >= 0 And Temp_Size()\Size > Temp_Size()\Max_Size : Temp_Size()\Size = Temp_Size()\Max_Size : EndIf
            Old_Size + Temp_Size()\Size
            Found = #False
            ForEach Priority()
              If Priority() = Temp_Size()\Priority
                Found = #True
                Break
              EndIf
            Next
            If Not Found
              AddElement(Priority())
              Priority() = Temp_Size()\Priority
            EndIf
          Next
          
          Difference = Width - Old_Size
          
          SortList(Priority(), #PB_Sort_Descending)
          
          ForEach Priority()
            Repeat
              Found = #False
              Total_Size = 0
              ; #### Get the total size of all elements of a specific priority
              ForEach Temp_Size()
                If Temp_Size()\Priority = Priority() And Not Temp_Size()\Finished
                  Total_Size + Temp_Size()\Size
                EndIf
              Next
              Scale = Difference / Total_Size
              ; #### Scale the elements of a specific priority
              ForEach Temp_Size()
                If Temp_Size()\Priority = Priority() And Not Temp_Size()\Finished
                  
                  Difference - Temp_Size()\Size * Scale
                  Temp_Size()\Size * (Scale + 1)
                  If Temp_Size()\Size < Temp_Size()\Min_Size
                    Found = #True
                    Difference + (Temp_Size()\Size - Temp_Size()\Min_Size)
                    Temp_Size()\Size = Temp_Size()\Min_Size
                    Temp_Size()\Finished = #True
                  ElseIf Temp_Size()\Max_Size >= 0 And Temp_Size()\Size > Temp_Size()\Max_Size
                    Found = #True
                    Difference + (Temp_Size()\Size - Temp_Size()\Max_Size)
                    Temp_Size()\Size = Temp_Size()\Max_Size
                    Temp_Size()\Finished = #True
                  EndIf
                EndIf
              Next
              
            Until Not Found
          Next
          
          Position = X
          ForEach Temp_Size()
            Container_Resize(*Gadget, Temp_Size()\Container, Position, Y, Temp_Size()\Size, Height, *Resize_Lowpriority, Iteration+1)
            Position + Temp_Size()\Size
          Next
          
        Case #Container_Type_Split_V
          ForEach *Container\Container()
            AddElement(Temp_Size())
            Temp_Size()\Container = *Container\Container()
            Temp_Size()\Min_Size = *Container\Container()\Min_Height
            Temp_Size()\Max_Size = *Container\Container()\Max_Height
            If Temp_Size()\Container = *Resize_Lowpriority
              Temp_Size()\Priority = -2147483648
            Else
              Temp_Size()\Priority = *Container\Container()\Priority_Inerhit
            EndIf
            Temp_Size()\Size = *Container\Container()\Height
            If Temp_Size()\Min_Size >= 0 And Temp_Size()\Size < Temp_Size()\Min_Size : Temp_Size()\Size = Temp_Size()\Min_Size : EndIf
            If Temp_Size()\Max_Size >= 0 And Temp_Size()\Size > Temp_Size()\Max_Size : Temp_Size()\Size = Temp_Size()\Max_Size : EndIf
            Old_Size + Temp_Size()\Size
            Found = #False
            ForEach Priority()
              If Priority() = Temp_Size()\Priority
                Found = #True
                Break
              EndIf
            Next
            If Not Found
              AddElement(Priority())
              Priority() = Temp_Size()\Priority
            EndIf
          Next
          
          Difference = Height - Old_Size
          
          SortList(Priority(), #PB_Sort_Descending)
          
          ForEach Priority()
            Repeat
              Found = #False
              Total_Size = 0
              ; #### Get the total size of all elements of a specific priority
              ForEach Temp_Size()
                If Temp_Size()\Priority = Priority() And Not Temp_Size()\Finished
                  Total_Size + Temp_Size()\Size
                EndIf
              Next
              Scale = Difference / Total_Size
              ; #### Scale the elements of a specific priority
              ForEach Temp_Size()
                If Temp_Size()\Priority = Priority() And Not Temp_Size()\Finished
                  
                  Difference - Temp_Size()\Size * Scale
                  Temp_Size()\Size * (Scale + 1)
                  If Temp_Size()\Size < Temp_Size()\Min_Size
                    Found = #True
                    Difference + (Temp_Size()\Size - Temp_Size()\Min_Size)
                    Temp_Size()\Size = Temp_Size()\Min_Size
                    Temp_Size()\Finished = #True
                  ElseIf Temp_Size()\Max_Size >= 0 And Temp_Size()\Size > Temp_Size()\Max_Size
                    Found = #True
                    Difference + (Temp_Size()\Size - Temp_Size()\Max_Size)
                    Temp_Size()\Size = Temp_Size()\Max_Size
                    Temp_Size()\Finished = #True
                  EndIf
                EndIf
              Next
              
            Until Not Found
          Next
          
          Position = Y
          ForEach Temp_Size()
            Container_Resize(*Gadget, Temp_Size()\Container, X, Position, Width, Temp_Size()\Size, *Resize_Lowpriority, Iteration+1)
            Position + Temp_Size()\Size
          Next
          
        Case #Container_Type_Spliter
          If *Container\Parent
            Select *Container\Parent\Type
              Case #Container_Type_Split_H
                ;Height = *Container\Parent\Height
                SetGadgetAttribute(*Container\Gadget_Canvas, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
              Case #Container_Type_Split_V
                ;Width = *Container\Parent\Width
                SetGadgetAttribute(*Container\Gadget_Canvas, #PB_Canvas_Cursor, #PB_Cursor_UpDown)
            EndSelect
          EndIf
          
        Case #Container_Type_Tabbed
          ForEach *Container\Container()
            Container_Resize(*Gadget, *Container\Container(), X, Y+#Container_Tabbed_Bar_Height, Width, Height-#Container_Tabbed_Bar_Height, *Resize_Lowpriority, Iteration+1)
          Next
          
      EndSelect
      
      ;If *Container\X <> X Or *Container\Y <> Y Or *Container\Width <> Width Or *Container\Height <> Height
        *Container\X = X
        *Container\Y = Y
        *Container\Width = Width
        *Container\Height = Height
        
        Select *Container\Type
          Case #Container_Type_Docker
            ResizeGadget(*Container\Gadget_Canvas, *Container\X, *Container\Y, *Container\Width, #Container_Docker_Bar_Height)
            *Container\Docker_Button_Close\X = *Container\Width - 16
            *Container\Docker_Button_Undock\X = *Container\Width - 32
            Container_Docker_Redraw(*Gadget, *Container)
            If *Container\Window
              ResizeWindow(*Container\Window\Window, *Container\X, *Container\Y+#Container_Docker_Bar_Height, *Container\Width, *Container\Height-#Container_Docker_Bar_Height)
            EndIf
            
          Case #Container_Type_Spliter
            ResizeGadget(*Container\Gadget_Canvas, *Container\X, *Container\Y, *Container\Width, *Container\Height)
            If StartDrawing(CanvasOutput(*Container\Gadget_Canvas))
              Box(0, 0, *Container\Width, *Container\Height, #Color_Splitter_Background)
              If *Container\Parent
                Select *Container\Parent\Type
                  Case #Container_Type_Split_H
                    ;Box(1, 0, *Container\Width-2, *Container\Height, #Color_Docker_Border)
                  Case #Container_Type_Split_V
                    ;Box(0, 1, *Container\Width, *Container\Height-2, #Color_Docker_Border)
                EndSelect
              EndIf
              StopDrawing()
            EndIf
            
          Case #Container_Type_Tabbed
            ResizeGadget(*Container\Gadget_TabBar, *Container\X, *Container\Y, *Container\Width, #Container_Tabbed_Bar_Height)
            UpdateTabBarGadget(*Container\Gadget_TabBar)
            
        EndSelect
      ;EndIf
      
      ; #### Resize the "empty" gadgets to fill the empty space
      If IsGadget(*Container\Gadget_Empty[0]) And Width < Width_Pre_Limit
        ResizeGadget(*Container\Gadget_Empty[0], *Container\X + Width, *Container\Y, Width_Pre_Limit - Width, Height_Pre_Limit)
        If StartDrawing(CanvasOutput(*Container\Gadget_Empty[0]))
          Box(0, 0, Width_Pre_Limit - Width, Height_Pre_Limit, #Color_Splitter_Background)
          StopDrawing()
        EndIf
      ElseIf IsGadget(*Container\Gadget_Empty[0]) And 
        ResizeGadget(*Container\Gadget_Empty[0], 0, 0, 0, 0)
      EndIf
      If IsGadget(*Container\Gadget_Empty[1]) And Height < Height_Pre_Limit
        ResizeGadget(*Container\Gadget_Empty[1], *Container\X, *Container\Y + Height, *Container\Width, Height_Pre_Limit - Height)
        If StartDrawing(CanvasOutput(*Container\Gadget_Empty[1]))
          Box(0, 0, *Container\Width, Height_Pre_Limit - Height, #Color_Splitter_Background)
          StopDrawing()
        EndIf
      ElseIf IsGadget(*Container\Gadget_Empty[1]) And 
        ResizeGadget(*Container\Gadget_Empty[1], 0, 0, 0, 0)
      EndIf
      
      ; FIXME: Fix flickering when resizing window
      If Iteration = 0
        SendMessage_(GadgetID(\Root\Gadget_Container), #WM_SETREDRAW, #True, 0)
        GetClientRect_(GadgetID(\Root\Gadget_Container), rect)
        InvalidateRect_(GadgetID(\Root\Gadget_Container), rect, #False)
        ;UpdateWindow_(GadgetID(\Root\Gadget_Container))
      EndIf
      
    EndWith
  EndProcedure
  
  Procedure Container_Resize_Between(*Gadget.GADGET, *Container.Container, Index, Difference)
    If Not *Gadget
      ProcedureReturn 0
    EndIf
    If Not *Container
      ProcedureReturn 0
    EndIf
    If *Container\Type <> #Container_Type_Split_H And *Container\Type <> #Container_Type_Split_V
      ProcedureReturn 0
    EndIf
    If Index <= 0 Or Index >= ListSize(*Container\Container())
      ProcedureReturn 0
    EndIf
    Protected Temp_Difference
    Protected rect.RECT
    Protected Position
    Protected NewList Temp_Size.Temp_Size()
    Protected *A.Temp_Size, *B.Temp_Size
    Protected A_Difference_Min, A_Difference_Max, B_Difference_Min, B_Difference_Max
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      
      Select *Container\Type
        Case #Container_Type_Split_H
          ForEach *Container\Container()
            AddElement(Temp_Size())
            Temp_Size()\Container = *Container\Container()
            Temp_Size()\Size = *Container\Container()\Width
            Temp_Size()\Min_Size = *Container\Container()\Min_Width
            Temp_Size()\Max_Size = *Container\Container()\Max_Width
          Next
        Case #Container_Type_Split_V
          ForEach *Container\Container()
            AddElement(Temp_Size())
            Temp_Size()\Container = *Container\Container()
            Temp_Size()\Size = *Container\Container()\Height
            Temp_Size()\Min_Size = *Container\Container()\Min_Height
            Temp_Size()\Max_Size = *Container\Container()\Max_Height
          Next
      EndSelect
      
      *A = SelectElement(Temp_Size(), Index-1)
      *B = SelectElement(Temp_Size(), Index)
      
      While *A And *B
        A_Difference_Max = *A\Max_Size - *A\Size
        A_Difference_Min = *A\Min_Size - *A\Size
        B_Difference_Max = *B\Size - *B\Min_Size
        B_Difference_Min = *B\Size - *B\Max_Size
        Temp_Difference = Difference
        
        If Temp_Difference > A_Difference_Max
          Temp_Difference = A_Difference_Max
        EndIf
        If Temp_Difference < A_Difference_Min
          Temp_Difference = A_Difference_Min
        EndIf
        If Temp_Difference > B_Difference_Max
          Temp_Difference = B_Difference_Max
        EndIf
        If Temp_Difference < B_Difference_Min
          Temp_Difference = B_Difference_Min
        EndIf
        
        *A\Size + Temp_Difference
        *B\Size - Temp_Difference
        Difference - Temp_Difference
        
        If ( Difference > 0 And A_Difference_Max = 0 ) Or ( Difference < 0 And A_Difference_Min = 0 )
          ChangeCurrentElement(Temp_Size(), *A)
          *A = PreviousElement(Temp_Size())
        EndIf
        If ( Difference > 0 And B_Difference_Max = 0 ) Or ( Difference < 0 And B_Difference_Min = 0 )
          ChangeCurrentElement(Temp_Size(), *B)
          *B = NextElement(Temp_Size())
        EndIf
        If Difference = 0
          Break
        EndIf
      Wend
      
      SendMessage_(GadgetID(\Root\Gadget_Container), #WM_SETREDRAW, #False, 0)
      
      Select *Container\Type
        Case #Container_Type_Split_H
          Position = *Container\X
          ForEach Temp_Size()
            Container_Resize(*Gadget, Temp_Size()\Container, Position, Temp_Size()\Container\Y, Temp_Size()\Size, *Container\Height, #Null, 1)
            Position + Temp_Size()\Size
          Next
        Case #Container_Type_Split_V
          Position = *Container\Y
          ForEach Temp_Size()
            Container_Resize(*Gadget, Temp_Size()\Container, Temp_Size()\Container\X, Position, *Container\Width, Temp_Size()\Size, #Null, 1)
            Position + Temp_Size()\Size
          Next
      EndSelect
      
      SendMessage_(GadgetID(\Root\Gadget_Container), #WM_SETREDRAW, #True, 0)
      
      GetClientRect_(GadgetID(\Root\Gadget_Container), rect)
      InvalidateRect_(GadgetID(\Root\Gadget_Container), rect, #False)
      UpdateWindow_(GadgetID(\Root\Gadget_Container))
      ;RedrawWindow_(GadgetID(\Root\Gadget_Container), 0, 0, 0)
      
      ;Container_Resize(*Gadget, *Container, *Container\X, *Container\Y, *Container\Width, *Container\Height)
      ;Container_Resize(*Gadget, \Root, 0, 0, GadgetWidth(\Root\Gadget_Container), GadgetHeight(\Root\Gadget_Container))
      
    EndWith
  EndProcedure
  
  Procedure _Docker_Add(*Gadget.GADGET, *Container.Container, Direction, *Window.Window, Iteration=0)
    If Not *Gadget
      ProcedureReturn #Null
    EndIf
    If Not *Container
      ProcedureReturn #Null
    EndIf
    If Not *Window
      ProcedureReturn #Null
    EndIf
    Protected Parent_Position
    Protected *Docker.Container, *Container_Split.Container, *Container_Spliter.Container, *Container_Tabbed.Container
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      If *Container\Parent
        ; #### *Container has a parent
        
        ForEach *Container\Parent\Container()
          If *Container\Parent\Container() = *Container
            Parent_Position = ListIndex(*Container\Parent\Container())
            Break
          EndIf
        Next
        Select *Container\Parent\Type
          Case #Container_Type_Split_H
            *Docker = Container_Add(*Gadget, 0, 0, WindowWidth(*Window\Window), WindowHeight(*Window\Window)+#Container_Docker_Bar_Height, #Container_Type_Docker, *Window)
            Select Direction
              Case #Direction_Left
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Docker, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container\Parent, Parent_Position+1)
              Case #Direction_Right
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Docker, *Container\Parent, Parent_Position+1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container\Parent, Parent_Position+1)
              Case #Direction_Top
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_V)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Bottom
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_V)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Inside
                *Container_Tabbed = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Tabbed)
                Container_Set_Parent(*Gadget, *Container_Tabbed, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Tabbed, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Tabbed, 1)
            EndSelect
            
          Case #Container_Type_Split_V
            *Docker = Container_Add(*Gadget, 0, 0, WindowWidth(*Window\Window), WindowHeight(*Window\Window)+#Container_Docker_Bar_Height, #Container_Type_Docker, *Window)
            Select Direction
              Case #Direction_Top
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Docker, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container\Parent, Parent_Position+1)
              Case #Direction_Bottom
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Docker, *Container\Parent, Parent_Position+1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container\Parent, Parent_Position+1)
              Case #Direction_Left
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_H)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Right
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_H)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Inside
                *Container_Tabbed = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Tabbed)
                Container_Set_Parent(*Gadget, *Container_Tabbed, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Tabbed, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Tabbed, 1)
            EndSelect
            
          Case #Container_Type_Tabbed
            Select Direction
              Case #Direction_Top, #Direction_Bottom, #Direction_Left, #Direction_Right
                *Docker = _Docker_Add(*Gadget, *Container\Parent, Direction, *Window, Iteration+1)
              Case #Direction_Inside
                *Docker = Container_Add(*Gadget, 0, 0, WindowWidth(*Window\Window), WindowHeight(*Window\Window)+#Container_Docker_Bar_Height, #Container_Type_Docker, *Window)
                Container_Set_Parent(*Gadget, *Docker, *Container\Parent, -1)
            EndSelect
            
          Case #Container_Type_Root
            *Docker = Container_Add(*Gadget, 0, 0, WindowWidth(*Window\Window), WindowHeight(*Window\Window)+#Container_Docker_Bar_Height, #Container_Type_Docker, *Window)
            Select Direction
              Case #Direction_Top
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_V)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Bottom
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_V)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, 0, #Splitter_Size, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Left
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_H)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Right
                *Container_Split = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Split_H)
                *Container_Spliter = Container_Add(*Gadget, 0, 0, #Splitter_Size, 0, #Container_Type_Spliter)
                Container_Set_Parent(*Gadget, *Container_Split, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Split, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Split, 1)
                Container_Set_Parent(*Gadget, *Container_Spliter, *Container_Split, 1)
              Case #Direction_Inside
                *Container_Tabbed = Container_Add(*Gadget, 0, 0, *Container\Width, *Container\Height, #Container_Type_Tabbed)
                Container_Set_Parent(*Gadget, *Container_Tabbed, *Container\Parent, Parent_Position)
                Container_Set_Parent(*Gadget, *Container, *Container_Tabbed, 0)
                Container_Set_Parent(*Gadget, *Docker, *Container_Tabbed, 1)
            EndSelect
            
        EndSelect
      Else
        ; #### *Container has no parent
        If FirstElement(*Container\Container())
          *Docker = _Docker_Add(*Gadget, *Container\Container(), Direction, *Window, Iteration+1)
        Else
          *Docker = Container_Add(*Gadget, 0, 0, WindowWidth(*Window\Window), WindowHeight(*Window\Window)+#Container_Docker_Bar_Height, #Container_Type_Docker, *Window)
          Container_Set_Parent(*Gadget, *Docker, *Container, 0)
        EndIf
      EndIf
      
      ; #### Merge containers of the same type
      If *Container\Parent
        ForEach *Container\Parent\Container()
          If *Container\Parent\Container()\Type = *Container\Parent\Type
            Container_Merge_To_Parent(*Gadget, *Container\Parent\Container())
          EndIf
        Next
      EndIf
      
      If *Docker And Iteration = 0
        Container_Resize(*Gadget, \Root, 0, 0, GadgetWidth(\Root\Gadget_Container), GadgetHeight(\Root\Gadget_Container), *Docker)
      EndIf
      
    EndWith
    
    ProcedureReturn *Docker
  EndProcedure
  
  Procedure Docker_Add(Gadget, *Container.Container, Direction, Window)
    Protected *Window.Window = Window_Get_By_Number(Window)
    If Not *Container
      ProcedureReturn #Null
    EndIf
    If Not *Window
      ProcedureReturn #Null
    EndIf
    ProcedureReturn _Docker_Add(IsGadget(Gadget), *Container, Direction, *Window)
  EndProcedure
  
  Procedure Root_Get(Gadget)
    Protected *Gadget.GADGET = IsGadget(Gadget)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      ProcedureReturn \Root
    EndWith
  EndProcedure
  
  Procedure Create(Gadget, X, Y, Width, Height, Parent_Window.i)
    Protected Style_Flags
    If Not Parent_Window
      ProcedureReturn #Null
    EndIf
    Protected Result = ContainerGadget(Gadget, 0, 0, 0, 0, #PB_Container_BorderLess)
    If Result
      If Gadget=#PB_Any : Gadget = Result : EndIf
      
      ; #### initialize custom params and custom manager
      Protected *params.GADGET_PARAMS = AllocateStructure(GADGET_PARAMS)
      Protected *manager.GADGET_MANAGER = GetManager()
      ManageGadget(*manager, Gadget, *params, #PB_GadgetType_D3docker)
      
      SetGadgetColor(Result, #PB_Gadget_BackColor, #Color_Gadget_Background)
      
      ; #### create and save custom elements and custom params
      With *params
        \Root\Gadget_Container = Gadget
        
        \Parent_Window = Parent_Window
        
        \FontID = GetGadgetFont(#PB_Default)
        
        CloseGadgetList()
      EndWith
      
      ; #### define custom PB commands
      With *manager\NewVT
        ;\FreeGadget = @_FreeGadget()
        ;\GetGadgetState = @_GetGadgetState()
        ;\SetGadgetState = @_SetGadgetState()
        \ResizeGadget = @_ResizeGadget()
      EndWith
      
      ; #### redraw gadget once and reset its state
      ResizeGadget(Gadget, X, Y, Width, Height)
      
      ProcedureReturn Result
    EndIf
  EndProcedure
  
  Procedure Free(Gadget)
    Protected *Gadget.GADGET = IsGadget(Gadget)
    If Not *Gadget
      ProcedureReturn #False
    EndIf
    Protected *params.GADGET_PARAMS=GetParams(*Gadget)
    With *params
      While FirstElement(\Window())
        _Window_Close(*Gadget, \Window())
      Wend
      
      While FirstElement(\Diamond())
        Diamond_Delete(*Gadget, \Diamond())
      Wend
      
      While FirstElement(\Root\Container())
        _Container_Delete(*Gadget, \Root\Container())
      Wend
      
      FreeGadget(\Root\Gadget_Container)
    EndWith
  EndProcedure
  
  ; ################################################## Data Section #############################################
  DataSection
    Diamond_Root_Left:   : IncludeBinary "Data/Diamond_Root_Left.png"
    Diamond_Root_Top:    : IncludeBinary "Data/Diamond_Root_Top.png"
    Diamond_Root_Right:  : IncludeBinary "Data/Diamond_Root_Right.png"
    Diamond_Root_Bottom: : IncludeBinary "Data/Diamond_Root_Bottom.png"
    Diamond_Root_Inside: : IncludeBinary "Data/Diamond_Root_Inside.png"
    Diamond_Left:   : IncludeBinary "Data/Diamond_Left.png"
    Diamond_Top:    : IncludeBinary "Data/Diamond_Top.png"
    Diamond_Right:  : IncludeBinary "Data/Diamond_Right.png"
    Diamond_Bottom: : IncludeBinary "Data/Diamond_Bottom.png"
    Diamond_Tabbed: : IncludeBinary "Data/Diamond_Tabbed.png"
    Button_Undock:  : IncludeBinary "Data/Undock.png"
    Button_Close:   : IncludeBinary "Data/Close.png"
  EndDataSection
  
EndModule
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 42
; FirstLine = 24
; Folding = ---------
; EnableUnicode
; EnableXP