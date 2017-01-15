; ##################################################### License / Copyright #########################################
; 
;     D3hex
;     Copyright (C) 2016-2017  David Vogel
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

DeclareModule _Node_Julia
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Julia
  ; ################################################### Includes ####################################################
  UseModule Julia
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
    
    *jl_module.jl_value_t
  EndStructure
  Global Main.Main
  
  Structure Conn_Input
    *Node_Conn.Node::Conn_Input
    
    *Julia_Callback_Event.jl_function_t
  EndStructure
  
  Structure Conn_Output
    *Node_Conn.Node::Conn_Output
    
    *Julia_Callback_Event.jl_function_t
    ;*Julia_Callback_Get_Segments.jl_function_t
    ;*Julia_Callback_Get_Descriptor.jl_function_t
    *Julia_Callback_Get_Size.jl_function_t
    *Julia_Callback_Get_Data.jl_function_t
    *Julia_Callback_Set_Data.jl_function_t
    *Julia_Callback_Shift.jl_function_t
    *Julia_Callback_Set_Data_Check.jl_function_t
    *Julia_Callback_Shift_Check.jl_function_t
  EndStructure
  
  Structure Object
    *Window.Window::Object
    Window_Close.l
    
    ; #### Gadget stuff
    
    ; #### Connections
    List Input.Conn_Input()
    List Output.Conn_Output()
    
    ; #### Julia stuff
    *Julia_Module.jl_value_t      ; The module which contains the methods and object type
    *Julia_Object.jl_value_t      ; The object which stores custom data of that node object in julia
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Init ########################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   Main(*Node.Node::Object)
  Declare   _Delete(*Node.Node::Object)
  Declare   Window_Open(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Input_Event(*Input.Node::Conn_Input, *Event.Node::Event)
  
  Declare   Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
  Declare   Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
  Declare   Output_Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Output_Get_Size(*Output.Node::Conn_Output)
  Declare   Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  Declare   Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
  Declare   Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  Declare   Window_Close(*Node.Node::Object)
  
  Declare   Julia_API_Init()
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Output.Node::Conn_Output
    Protected JL_GC_Previous
    
    If Not *Node
      ProcedureReturn #False
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
    *Node\Color = RGBA(180,200,250,255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    ; #### DEBUG
    Julia_API_Init()
    
    ; #### Load some test file
    If Julia_API::Main\Initialised
      Protected Path.s = "C:\Users\David Vogel\Desktop\Dropbox\Purebasic\D3hex\2\Data\Scripts\Julia_Node\Histogram\Init.jl"
      JL_GC_Previous = jl_gc_enable(#False)
      Protected *func = jl_get_function(*jl_base_module\_, "include")
      Protected *argument = jl_pchar_to_string(Path, StringByteLength(Path, #PB_UTF8))
      jl_gc_enable(JL_GC_Previous)
      *Object\Julia_Module = jl_call1(*func, *argument)
      
      If jl_exception_occurred()
        Logger::Entry_Add_Error("Error while loading a Julia script", "Path: " + Path + #CRLF$ + "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
      EndIf
      
      ; #### Call constructor of the module
      If *Object\Julia_Module And jl_is_module(*Object\Julia_Module)
        JL_GC_Previous = jl_gc_enable(#False)
        *func = jl_get_function(*Object\Julia_Module, "Object")
        *argument = jl_box_int64(*Node\ID)
        jl_gc_enable(JL_GC_Previous)
        *Object\Julia_Object = jl_call1(*func, *argument)
        
        ; #### Prevent object from being garbage collected
        If *Object\Julia_Object
          Julia_API::JL_GC_Ref(*Object\Julia_Object)
        EndIf
        
        If jl_exception_occurred()
          Logger::Entry_Add_Error("Error while creating an instance of " + "Object", "Module: " + "Object" + #CRLF$ + "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
        EndIf
      EndIf
    EndIf
    
    ProcedureReturn *Node
  EndProcedure
  
  Procedure _Delete(*Node.Node::Object)
    If Not *Node
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Window_Close(*Node)
    
    ; #### Let the garbage collector delete the object later
    If *Object\Julia_Object
      Julia_API::JL_GC_Unref(*Object\Julia_Object)
    EndIf
    
    FreeStructure(*Object)
    *Node\Custom_Data = #Null
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    
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
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    
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
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(3-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Input()
      If *Object\Input()\Node_Conn = *Input
        If *Object\Input()\Julia_Callback_Event
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Input)
          *Argument(2) = jl_box_voidpointer(*Event)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Input()\Julia_Callback_Event, @*Argument(0), 3)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Event callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Event(*Output.Node::Conn_Output, *Event.Node::Event)
    If Not *Output
      ProcedureReturn #False
    EndIf
    If Not *Event
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(3-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Event
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_voidpointer(*Event)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Event, @*Argument(0), 3)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Event callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Get_Segments(*Output.Node::Conn_Output, List Segment.Node::Output_Segment())
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Get_Descriptor(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #Null
    EndIf
    
    ProcedureReturn *Output\Descriptor
  EndProcedure
  
  Procedure.q Output_Get_Size(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn -1
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn -1
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn -1
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(2-1)
    Protected *Result
    Protected Result.q = -1
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Get_Size
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Get_Size, @*Argument(0), 2)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia Get_Size callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn -1
  EndProcedure
  
  Procedure Output_Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
    If Not *Output
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected *array_type.jl_value_t
    Protected Dim *Argument.jl_value_t(5-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Get_Data
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_int64(Position)
          
          *array_type     = jl_apply_array_type(*jl_uint8_type\_, 1)
          If *Data
            *Argument(3)  = jl_ptr_to_array_1d(*array_type, *Data, Size, #False)
          Else
            *Argument(3)  = jl_alloc_array_1d(*array_type, 0)
          EndIf
          If *Metadata
            *Argument(4)  = jl_ptr_to_array_1d(*array_type, *Metadata, Size, #False)
          Else
            *Argument(4)  = jl_alloc_array_1d(*array_type, 0)
          EndIf
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Get_Data, @*Argument(0), 5)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Get_Data callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
    If Not *Output
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected *array_type.jl_value_t
    Protected Dim *Argument.jl_value_t(4-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Set_Data
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_int64(Position)
          
          *array_type     = jl_apply_array_type(*jl_uint8_type\_, 1)
          If *Data
            *Argument(3)  = jl_ptr_to_array_1d(*array_type, *Data, Size, #False)
          Else
            *Argument(3)  = jl_alloc_array_1d(*array_type, 0)
          EndIf
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Set_Data, @*Argument(0), 4)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Set_Data callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(4-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Shift
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_int64(Position)
          *Argument(3) = jl_box_int64(Offset)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Shift, @*Argument(0), 4)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Shift callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Set_Data_Check(*Output.Node::Conn_Output, Position.q, Size.i)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(4-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Set_Data_Check
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_int64(Position)
          *Argument(3) = jl_box_int64(Size)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Set_Data_Check, @*Argument(0), 4)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Set_Data_Check callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Output_Shift_Check(*Output.Node::Conn_Output, Position.q, Offset.q)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    Protected JL_GC_Previous
    Protected Dim *Argument.jl_value_t(4-1)
    Protected *Result
    Protected Result = #False
    
    ; #### Get the julia callback function
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        If *Object\Output()\Julia_Callback_Shift_Check
          
          JL_GC_Previous = jl_gc_enable(#False)
          
          *Argument(0) = *Object\Julia_Object
          *Argument(1) = jl_box_voidpointer(*Output)
          *Argument(2) = jl_box_int64(Position)
          *Argument(3) = jl_box_int64(Offset)
          
          jl_gc_enable(JL_GC_Previous)
          
          *Result = jl_call(*Object\Output()\Julia_Callback_Shift_Check, @*Argument(0), 4)
          If *Result
            Result = jl_unbox_int64(*Result)
          EndIf
          
          If jl_exception_occurred()
            Logger::Entry_Add_Error("Julia_Node Shift_Check callback failed", "Error: " + Julia_API::JL_GetError(jl_exception_occurred()))
          EndIf
          
          ProcedureReturn Result
        EndIf
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Window_Event_SizeWindow()
    Protected Event_Window = EventWindow()
    
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
    
    
    
  EndProcedure
  
  Procedure Window_Event_Menu()
    Protected Event_Window = EventWindow()
    Protected Event_Gadget = EventGadget()
    Protected Event_Type = EventType()
    Protected Event_Menu = EventMenu()
    
    Select Event_Menu
      
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
    
    *Object\Window_Close = #True
  EndProcedure
  
  Procedure Window_Open(*Node.Node::Object)
    Protected Width, Height
    
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Not *Object\Window
      
      Width = 350
      Height = 250
      
      *Object\Window = Window::Create(*Node, *Node\Name_Inherited, *Node\Name, 0, 0, Width, Height)
      
      ; #### Gadgets
      
      BindEvent(#PB_Event_SizeWindow, @Window_Event_SizeWindow(), *Object\Window\ID)
      BindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      BindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
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
      UnbindEvent(#PB_Event_Menu, @Window_Event_Menu(), *Object\Window\ID)
      UnbindEvent(#PB_Event_CloseWindow, @Window_Event_CloseWindow(), *Object\Window\ID)
      
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
      
    EndIf
    
    If *Object\Window_Close
      *Object\Window_Close = #False
      Window_Close(*Node)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Julia_API_Input_Add(*Node.Node::Object, Name.s="", Short_Name.s="")
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    AddElement(*Object\Input())
    *Object\Input()\Node_Conn = Node::Input_Add(*Node, Name, Short_Name)
    *Object\Input()\Node_Conn\Function_Event = @Input_Event()
    
    ProcedureReturn *Object\Input()\Node_Conn
  EndProcedure
  
  Procedure Julia_API_Input_Delete(*Input.Node::Conn_Input)
    If Not *Input
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Input\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Input()
      If *Object\Input()\Node_Conn = *Input
        DeleteElement(*Object\Input())
      EndIf
    Next
    ; #### The real node input will be deleted later TODO: Remove node input later
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Julia_API_Input_Callback(*Input.Node::Conn_Input, Event.s, *Julia_Callback)
    If Not *Input
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Input\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Input()
      If *Object\Input()\Node_Conn = *Input
        Select Event
          Case "Event"            : *Object\Input()\Julia_Callback_Event = *Julia_Callback
          Default                 : ProcedureReturn #False
        EndSelect
        ProcedureReturn #True
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Julia_API_Output_Add(*Node.Node::Object, Name.s="", Short_Name.s="")
    If Not *Node
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    AddElement(*Object\Output())
    *Object\Output()\Node_Conn = Node::Output_Add(*Node, Name, Short_Name)
    *Object\Output()\Node_Conn\Function_Event = @Output_Event()
    ;*Object\Output()\Node_Conn\Function_Get_Segments = @Output_Get_Segments()
    ;*Object\Output()\Node_Conn\Function_Get_Descriptor = @Output_Get_Descriptor()
    *Object\Output()\Node_Conn\Function_Get_Size = @Output_Get_Size() ; TODO: Add more callbacks to the julia node
    *Object\Output()\Node_Conn\Function_Get_Data = @Output_Get_Data()
    *Object\Output()\Node_Conn\Function_Set_Data = @Output_Set_Data()
    *Object\Output()\Node_Conn\Function_Shift = @Output_Shift()
    *Object\Output()\Node_Conn\Function_Set_Data_Check = @Output_Set_Data_Check()
    *Object\Output()\Node_Conn\Function_Shift_Check = @Output_Shift_Check()
    
    ProcedureReturn *Object\Output()\Node_Conn
  EndProcedure
  
  Procedure Julia_API_Output_Delete(*Output.Node::Conn_Output)
    If Not *Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        DeleteElement(*Object\Output())
      EndIf
    Next
    ; #### The real node output will be deleted later TODO: Remove node output later
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Julia_API_Output_Callback(*Output.Node::Conn_Output, Event.s, *Julia_Callback.jl_function_t)
    If Not *Output
      ProcedureReturn #Null
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    ForEach *Object\Output()
      If *Object\Output()\Node_Conn = *Output
        Select Event
          Case "Event"            : *Object\Output()\Julia_Callback_Event = *Julia_Callback
          ;Case "Get_Segments"     : *Object\Output()\Julia_Callback_Get_Segments = *Julia_Callback
          ;Case "Get_Descriptor"   : *Object\Output()\Julia_Callback_Get_Descriptor = *Julia_Callback
          Case "Get_Size"         : *Object\Output()\Julia_Callback_Get_Size = *Julia_Callback
          Case "Get_Data"         : *Object\Output()\Julia_Callback_Get_Data = *Julia_Callback
          Case "Set_Data"         : *Object\Output()\Julia_Callback_Set_Data = *Julia_Callback
          Case "Shift"            : *Object\Output()\Julia_Callback_Shift = *Julia_Callback
          Case "Set_Data_Check"   : *Object\Output()\Julia_Callback_Set_Data_Check = *Julia_Callback
          Case "Shift_Check"      : *Object\Output()\Julia_Callback_Shift_Check = *Julia_Callback
          Default                 : ProcedureReturn #False
        EndSelect
        ProcedureReturn #True
      EndIf
    Next
    
    ProcedureReturn #False
  EndProcedure
  
  Procedure Julia_API_Init()
    If Not Julia_API::Main\Initialised
      ProcedureReturn #False
    EndIf
    
    If Main\jl_module
      ProcedureReturn #True
    EndIf
    
    Protected Temp_String.s
    
    ; #### Node
    Temp_String = "module Node_Julia" + Julia_API::#Linebreak
    
    Temp_String + "using Node" + Julia_API::#Linebreak
    
    Temp_String + "Input_Add(node::Ptr{Node.Object}, name::String, short_name::String) = ccall(convert(Ptr{Void}, "+Str(@Julia_API_Input_Add())+"), Ptr{Node.Conn_Input}, (Ptr{Node.Object}, Cwstring, Cwstring), node, name, short_name)" + Julia_API::#Linebreak
    Temp_String + "Input_Delete(input::Ptr{Node.Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(@Julia_API_Input_Delete())+"), Csize_t, (Ptr{Node.Conn_Input},), input)" + Julia_API::#Linebreak
;     Temp_String + "function Input_Callback(input::Ptr{Node.Conn_Input}, event::String, callback::Function)" + Julia_API::#Linebreak +
;                  ~"  if event == \"Event\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Input}))" + Julia_API::#Linebreak +
;                  ~"  else" + Julia_API::#Linebreak +
;                   "    return nothing" + Julia_API::#Linebreak +
;                   "  end" + Julia_API::#Linebreak +
;                   "  return ccall(convert(Ptr{Void}, "+Str(@Julia_API_Input_Callback())+"), Csize_t, (Ptr{Node.Conn_Input}, Cwstring, Ptr{Void}), input, event, ccallback)" + Julia_API::#Linebreak +
;                   "end" + Julia_API::#Linebreak
    Temp_String + "function Input_Callback(input::Ptr{Node.Conn_Input}, event::String, callback::Function)" + Julia_API::#Linebreak +
                  "  return ccall(convert(Ptr{Void}, "+Str(@Julia_API_Input_Callback())+"), Csize_t, (Ptr{Node.Conn_Input}, Cwstring, Function), input, event, callback)" + Julia_API::#Linebreak +
                  "end" + Julia_API::#Linebreak
    
    Temp_String + "Output_Add(node::Ptr{Node.Object}, name::String, short_name::String) = ccall(convert(Ptr{Void}, "+Str(@Julia_API_Output_Add())+"), Ptr{Node.Conn_Output}, (Ptr{Node.Object}, Cwstring, Cwstring), node, name, short_name)" + Julia_API::#Linebreak
    Temp_String + "Output_Delete(output::Ptr{Node.Conn_Output}) = ccall(convert(Ptr{Void}, "+Str(@Julia_API_Output_Delete())+"), Csize_t, (Ptr{Node.Conn_Output},), output)" + Julia_API::#Linebreak
;     Temp_String + "function Output_Callback(output::Ptr{Node.Conn_Output}, event::String, callback::Function)" + Julia_API::#Linebreak +
;                  ~"  if event == \"Event\"" + Julia_API::#Linebreak + ; TODO: Pray that a switch statement will be implemented in julia. ⎺\_(ツ)_/⎺
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Get_Segments\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Get_Descriptor\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Get_Size\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Int64, (Any, Ptr{Node.Conn_Output}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Get_Data\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Int64, (Any, Ptr{Node.Conn_Output}, Int64, Array{UInt8,1}, Array{UInt8,1}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Set_Data\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}, Int64, Array{UInt8,1}))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Shift\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}, Int64, Int64))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Set_Data_Check\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}, Int64, Csize_t))" + Julia_API::#Linebreak +
;                  ~"  elseif event == \"Shift_Check\"" + Julia_API::#Linebreak +
;                   "    ccallback = cfunction(callback, Csize_t, (Any, Ptr{Node.Conn_Output}, Int64, Int64))" + Julia_API::#Linebreak +
;                  ~"  else" + Julia_API::#Linebreak +
;                   "    return nothing" + Julia_API::#Linebreak +
;                   "  end" + Julia_API::#Linebreak +
;                   "  return ccall(convert(Ptr{Void}, "+Str(@Julia_API_Output_Callback())+"), Csize_t, (Ptr{Node.Conn_Output}, Cwstring, Ptr{Void}), output, event, ccallback)" + Julia_API::#Linebreak +
;                   "end" + Julia_API::#Linebreak
    Temp_String + "function Output_Callback(output::Ptr{Node.Conn_Output}, event::String, callback::Function)" + Julia_API::#Linebreak +
                  "  return ccall(convert(Ptr{Void}, "+Str(@Julia_API_Output_Callback())+"), Csize_t, (Ptr{Node.Conn_Output}, Cwstring, Function), output, event, callback)" + Julia_API::#Linebreak +
                  "end" + Julia_API::#Linebreak
    
    Temp_String + "end"
    
    Main\jl_module = jl_eval_string(Temp_String)
    If jl_exception_occurred()
      Debug "Error: " + PeekS(jl_typeof_str(jl_exception_occurred()), -1, #PB_UTF8)
    EndIf
    
    If Not Main\jl_module
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Node_Type = Node_Type::Create()
  If Main\Node_Type
    Main\Node_Type\Category = "Scripting"
    Main\Node_Type\Name = "Julia"
    Main\Node_Type\UID = "D3_JULIA"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2016,12,30,16,43,00)
    Main\Node_Type\Date_Modification = Date(2016,12,30,16,43,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "A freely scriptable node."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 900
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
  ; ################################################### Debug #######################################################
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 697
; FirstLine = 650
; Folding = -----
; EnableUnicode
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant