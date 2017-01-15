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
; ##################################################### Documentation / Comments ####################################
; 
; API between D3hex and Julia.
; 
; 
; 
; 
; 
; ##################################################### Includes ####################################################

; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule Julia_API
  UseModule Julia
  
  EnableExplicit
  
  ; ################################################### Constants ###################################################
  #Linebreak = #CRLF$
  
  ; ################################################### Structures ##################################################
  Structure Main
    Initialised.i
  EndStructure
  Global Main.Main
  
  Structure JL_Module
    *Helper.jl_value_t
    *PB.jl_value_t
    *Logger.jl_value_t
    *Node.jl_value_t
  EndStructure
  Global JL_Module.JL_Module
  
  ; ################################################### Prototypes ##################################################
  PrototypeC.i JL_GC_Ref(*Value.jl_value_t)
  PrototypeC.i JL_GC_Unref(*Value.jl_value_t)
  
  ; ################################################### Variables ###################################################
  Global JL_GC_Ref.JL_GC_Ref
  Global JL_GC_Unref.JL_GC_Unref
  
  ; ################################################### Functions ###################################################
  Declare.s JL_GetError(*Error.jl_value_t)
  
  Declare   Init()
  Declare   Deinit()
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Julia_API
  ; ################################################### Procedures ##################################################
  Procedure.s JL_GetError(*Error.jl_value_t)
    Protected *Result
    Protected *Function = jl_get_function(JL_Module\Helper, "GetError")
    
    *Result = jl_call1(*Function, *Error)
    If *Result And jl_array_data(*Result)
      ProcedureReturn PeekS(jl_array_data(*Result), jl_array_len(*Result), #PB_UTF8)
    EndIf
    
    ProcedureReturn ""
  EndProcedure
  
  ; ################################################### Procedures exported to Julia ################################
  ProcedureC PB_Debug(Message.s)
    Debug "Julia-Debug: " + Message
  EndProcedure
  
  ProcedureC Logger_Entry_Add_Error(Name.s, Description.s)
    Logger::Entry_Add(Logger::#Entry_Type_Error, Name, Description, "Unknown", "Unknown", -1)
  EndProcedure
  
  ProcedureC Logger_Entry_Add_Warning(Name.s, Description.s)
    Logger::Entry_Add(Logger::#Entry_Type_Warning, Name, Description, "Unknown", "Unknown", -1)
  EndProcedure
  
  ; ################################################### Procedures to initialize Julia ##############################
  Procedure Register_Functions()
    Protected Temp_String.s
    
    ; #### Helper
    Temp_String = "module Helper" + #Linebreak
    
    Temp_String + "export gc_ref, gc_unref, GetError" + #Linebreak
    
    Temp_String + "function GetError(error)" + #Linebreak +
	                "  local stream = IOBuffer(true, true)" + #Linebreak +
	                "  showerror(stream, error)" + #Linebreak +
	               ;~"  write(stream, \"\nErrorObject: \")" + #Linebreak +
	               ; "  show(stream, error)" + #Linebreak +
	                "  seek(stream, 0)" + #Linebreak +
	                "  read(stream)" + #Linebreak +
                  "end" + #Linebreak
    
    Temp_String + "const gc_preserve = ObjectIdDict() # reference counted closures" + #Linebreak
    Temp_String + "function gc_ref(x::ANY)" + #Linebreak + 
                  "  global gc_preserve" + #Linebreak + 
                 ~"  isbits(x) && error(\"can't gc-preserve an isbits object\")" + #Linebreak + 
                  "  gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1" + #Linebreak + 
                  "  x" + #Linebreak + 
                  "end" + #Linebreak
    Temp_String + "function gc_unref(x::ANY)" + #Linebreak + 
                  "  global gc_preserve" + #Linebreak + 
                  "  @assert !isbits(x)" + #Linebreak + 
                  "  count = get(gc_preserve, x, 0)::Int-1" + #Linebreak + 
                  "  if count <= 0" + #Linebreak + 
                  "    delete!(gc_preserve, x)" + #Linebreak + 
                  "  end" + #Linebreak + 
                  "  nothing" + #Linebreak + 
                  "end" + #Linebreak
    Temp_String + "gc_ref_c = cfunction(gc_ref, Any, (Any,))" + #Linebreak
    Temp_String + "gc_unref_c = cfunction(gc_unref, Void, (Any,))" + #Linebreak
    
    Temp_String + "end"
    
    JL_Module\Helper = jl_eval_string(Temp_String)
    If jl_exception_occurred()
      Logger::Entry_Add_Error("Couldn't register Helper module in Julia", "jl_eval_string(Temp_String) failed: " + PeekS(jl_typeof_str(jl_exception_occurred()), -1, #PB_UTF8))
    EndIf
    
    ; #### PureBasic
    Temp_String = "module PB" + #Linebreak
    
    Temp_String + "Debug(message::String) = ccall(convert(Ptr{Void}, "+Str(@PB_Debug())+"), Void, (Cwstring,), message)" + #Linebreak
    
    Temp_String + "end"
    
    JL_Module\PB = jl_eval_string(Temp_String)
    If jl_exception_occurred()
      Logger::Entry_Add_Error("Couldn't register PB module in Julia", "jl_eval_string(Temp_String) failed: " + JL_GetError(jl_exception_occurred()))
    EndIf
    
    ; #### Logger
    Temp_String = "module Logger" + #Linebreak
    
    Temp_String + "Entry_Add_Error(name::String, description::String) = ccall(convert(Ptr{Void}, "+Str(@Logger_Entry_Add_Error())+"), Void, (Cwstring,Cwstring), name, description)" + #Linebreak
    Temp_String + "Entry_Add_Warning(name::String, description::String) = ccall(convert(Ptr{Void}, "+Str(@Logger_Entry_Add_Warning())+"), Void, (Cwstring,Cwstring), name, description)" + #Linebreak
    
    Temp_String + "end"
    
    JL_Module\Logger = jl_eval_string(Temp_String)
    If jl_exception_occurred()
      Logger::Entry_Add_Error("Couldn't register Logger module in Julia", "jl_eval_string(Temp_String) failed: " + JL_GetError(jl_exception_occurred()))
    EndIf
    
    ; #### GC Preserve
    
    ; #### Retrieve gc_ref and gc_unref functions
    If JL_Module\Helper
      JL_GC_Ref = jl_unbox_voidpointer(jl_get_function(JL_Module\Helper, "gc_ref_c"))       ; Not actually retrieving a jl_function here
      JL_GC_Unref = jl_unbox_voidpointer(jl_get_function(JL_Module\Helper, "gc_unref_c"))
    EndIf
    
    ; #### Node
    Temp_String = "module Node" + #Linebreak
    
    Temp_String + "const Event_Values = " + Node::#Event_Values + #Linebreak +
                  #Linebreak +
                  "const Event_Save = " + Node::#Event_Save + #Linebreak +
                  "const Event_SaveAs = " + Node::#Event_SaveAs + #Linebreak +
                  "const Event_Cut = " + Node::#Event_Cut + #Linebreak +
                  "const Event_Copy = " + Node::#Event_Copy + #Linebreak +
                  "const Event_Paste = " + Node::#Event_Paste + #Linebreak +
                  "const Event_Undo = " + Node::#Event_Undo + #Linebreak +
                  "const Event_Redo = " + Node::#Event_Redo + #Linebreak +
                  "const Event_Goto = " + Node::#Event_Goto + #Linebreak +
                  "const Event_Search = " + Node::#Event_Search + #Linebreak +
                  "const Event_Search_Continue = " + Node::#Event_Search_Continue + #Linebreak +
                  "const Event_Close = " + Node::#Event_Close + #Linebreak +
                  #Linebreak +
                  "const Link_Event_Update_Descriptor = " + Node::#Link_Event_Update_Descriptor + #Linebreak +
                  "const Link_Event_Update = " + Node::#Link_Event_Update + #Linebreak +
                  "const Link_Event_Goto = " + Node::#Link_Event_Goto + #Linebreak
    
    Temp_String + "type Object" + #Linebreak +
                  "end" + #Linebreak
    
    Temp_String + "type Event" + #Linebreak +
                  #Linebreak +
                  "  event_type::Int32" + #Linebreak +
                  "  position::Int64" + #Linebreak +
                  "  size::Int64" + #Linebreak +
                  #Linebreak +
                  "  value::NTuple{Event_Values, Int64}" + #Linebreak +
                  #Linebreak +
                  "  custom_data::Ptr{Void}" + #Linebreak +
                  "  function Event(event_type::Int64, position::Int64, size::Int64)" + #Linebreak +
                  "    event = new()" + #Linebreak +
                  "    event.event_type, event.position, event.size = Int32(event_type), position, size" + #Linebreak +
                  "    event" + #Linebreak +
                  "  end" + #Linebreak +
                  "end" + #Linebreak +
                  "@assert sizeof(Event) == " + SizeOf(Node::Event) + #Linebreak
    
    Temp_String + "type Conn_Input" + #Linebreak +
                  "end" + #Linebreak
    
    Temp_String + "type Conn_Output" + #Linebreak +
                  "end" + #Linebreak
    
    Temp_String + "Get(id::Int) = ccall(convert(Ptr{Void}, "+Str(Node::@Get())+"), Ptr{Object}, (Csize_t,), id)" + #Linebreak
    Temp_String + "Delete(node::Ptr{Object}) = ccall(convert(Ptr{Void}, "+Str(Node::@Delete())+"), Csize_t, (Ptr{Object},), node)" + #Linebreak
    Temp_String + "Event(node::Ptr{Object}, event::Ptr{Event}) = ccall(convert(Ptr{Void}, "+Str(Node::@Event())+"), Csize_t, (Ptr{Object}, Ptr{Event}), node, event)" + #Linebreak
    
    Temp_String + "Input_Get(node::Ptr{Object}, i::Int) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Get())+"), Ptr{Conn_Input}, (Ptr{Object}, Csize_t), node, i)" + #Linebreak
    Temp_String + "Input_Add(node::Ptr{Object}, name::String, short_name::String) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Add())+"), Ptr{Conn_Input}, (Ptr{Object}, Cwstring, Cwstring), node, name, short_name)" + #Linebreak
    Temp_String + "Input_Delete(node::Ptr{Object}, input::Ptr{Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Delete())+"), Csize_t, (Ptr{Object}, Ptr{Conn_Input}), node, input)" + #Linebreak
    
    Temp_String + "Output_Get(node::Ptr{Object}, i::Int) = ccall(convert(Ptr{Void}, "+Str(Node::@Output_Get())+"), Ptr{Conn_Output}, (Ptr{Object}, Csize_t), node, i)" + #Linebreak
    Temp_String + "Output_Add(node::Ptr{Object}, name::String, short_name::String) = ccall(convert(Ptr{Void}, "+Str(Node::@Output_Add())+"), Ptr{Conn_Output}, (Ptr{Object}, Cwstring, Cwstring), node, name, short_name)" + #Linebreak
    Temp_String + "Output_Delete(node::Ptr{Object}, output::Ptr{Conn_Output}) = ccall(convert(Ptr{Void}, "+Str(Node::@Output_Delete())+"), Csize_t, (Ptr{Object}, Ptr{Conn_Output}), node, output)" + #Linebreak
    
    Temp_String + "Link_Disconnect(input::Ptr{Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(Node::@Link_Disconnect())+"), Csize_t, (Ptr{Conn_Input},), input)" + #Linebreak
    Temp_String + "Link_Connect(output::Ptr{Conn_Output}, input::Ptr{Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(Node::@Link_Connect())+"), Csize_t, (Ptr{Conn_Output}, Ptr{Conn_Input}), output, input)" + #Linebreak
    
    Temp_String + "Input_Event(input::Ptr{Conn_Input}, event::Ref{Event}) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Event())+"), Csize_t, (Ptr{Conn_Input}, Ref{Event}), input, event)" + #Linebreak
    Temp_String + "Input_Event(input::Ptr{Conn_Input}, event::Event) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Event())+"), Csize_t, (Ptr{Conn_Input}, Ref{Event}), input, event)" + #Linebreak
    Temp_String + "Output_Event(output::Ptr{Conn_Output}, event::Ref{Event}) = ccall(convert(Ptr{Void}, "+Str(Node::@Output_Event())+"), Csize_t, (Ptr{Conn_Output}, Ref{Event}), output, event)" + #Linebreak
    Temp_String + "Output_Event(output::Ptr{Conn_Output}, event::Event) = ccall(convert(Ptr{Void}, "+Str(Node::@Output_Event())+"), Csize_t, (Ptr{Conn_Output}, Ref{Event}), output, event)" + #Linebreak
    Temp_String + "Input_Get_Descriptor(input::Ptr{Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Get_Descriptor())+"), Csize_t, (Ptr{Conn_Input},), input)" + #Linebreak
    ; TODO: Expose Input_Get_Segments to Julia
    Temp_String + "Input_Get_Size(input::Ptr{Conn_Input}) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Get_Size())+"), Int64, (Ptr{Conn_Input},), input)" + #Linebreak
    Temp_String + "function Input_Get_Data(input::Ptr{Conn_Input}, position::Int64, data::Array{UInt8,1}, metadata::Array{UInt8,1})" + #Linebreak +
                  "  size = min(sizeof(data), sizeof(metadata))" + #Linebreak +
                  "  ccall(convert(Ptr{Void}, "+Str(Node::@Input_Get_Data())+"), Csize_t, (Ptr{Conn_Input}, Int64, Csize_t, Ptr{Array{UInt8,1}}, Ptr{Array{UInt8,1}}), input, position, size, data, metadata)" + #Linebreak +
                  "end"+ #Linebreak
    Temp_String + "function Input_Get_Data(input::Ptr{Conn_Input}, position::Int64, data::Array{UInt8,1})" + #Linebreak +
                  "  size = sizeof(data)" + #Linebreak +
                  "  ccall(convert(Ptr{Void}, "+Str(Node::@Input_Get_Data())+"), Csize_t, (Ptr{Conn_Input}, Int64, Csize_t, Ptr{Array{UInt8,1}}, Ptr{Array{UInt8,1}}), input, position, size, data, C_NULL)" + #Linebreak +
                  "end"+ #Linebreak
    Temp_String + "function Input_Set_Data(input::Ptr{Conn_Input}, position::Int64, data::Array{UInt8,1})" + #Linebreak +
                  "  size = sizeof(data)" + #Linebreak +
                  "  ccall(convert(Ptr{Void}, "+Str(Node::@Input_Set_Data())+"), Csize_t, (Ptr{Conn_Input}, Int64, Csize_t, Ptr{Array{UInt8,1}}), input, position, size, data)" + #Linebreak +
                  "end"+ #Linebreak
    Temp_String + "Input_Shift(input::Ptr{Conn_Input}, position::Int64, offset::Int64) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Shift())+"), Csize_t, (Ptr{Conn_Input}, Int64, Int64), input, position, offset)" + #Linebreak
    Temp_String + "Input_Set_Data_Check(input::Ptr{Conn_Input}, position::Int64, size::Csize_t) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Set_Data_Check())+"), Csize_t, (Ptr{Conn_Input}, Int64, Csize_t), input, position, size)" + #Linebreak
    Temp_String + "Input_Shift_Check(input::Ptr{Conn_Input}, position::Int64, offset::Int64) = ccall(convert(Ptr{Void}, "+Str(Node::@Input_Shift_Check())+"), Csize_t, (Ptr{Conn_Input}, Int64, Int64), input, position, offset)" + #Linebreak
    
    Temp_String + "end"
    
    JL_Module\Node = jl_eval_string(Temp_String)
    If jl_exception_occurred()
      Logger::Entry_Add_Error("Couldn't register Node module in Julia", "jl_eval_string(Temp_String) failed: " + JL_GetError(jl_exception_occurred()))
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Init()
    ; #### Check if the library is loaded
    If Not IsLibrary(Julia::_JL_Library_ID)
      Main\Initialised = #False
      ProcedureReturn #False
    EndIf
    
    ; #### Init Julia
    If jl_init(#Null)
      Main\Initialised = #True
    Else
      Logger::Entry_Add_Error("Couldn't initialize Julia", "jl_init(#Null) failed.")
      Main\Initialised = #False
      ProcedureReturn #False
    EndIf
    
    ; #### Register D3hex functions inside Julia
    ProcedureReturn Register_Functions()
  EndProcedure
  
  Procedure Deinit()
    If Not Main\Initialised
      ProcedureReturn #True
    EndIf
    Main\Initialised = #False
    
    If IsLibrary(Julia::_JL_Library_ID)
      jl_atexit_hook(0)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 114
; FirstLine = 91
; Folding = --
; EnableUnicode
; EnableXP
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant