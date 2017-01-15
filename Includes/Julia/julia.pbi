; #### Translated to PB by David Vogel (Dadido3)
; #### Updated: 15.01.2017
; #### http://github.com/Dadido3
; #### http://D3nexus.de

DeclareModule Julia
  
  ; #### Information about the data types:
  ; #### On x64 Windows LLP64 is used. on x64 Linux and MacOS X LP64 is used. The x86 version of Windows, Linux and MacOS use ILP32. Therefore:
  ; ╔══════╤══════════╤═════════════════╗
  ; ║      │ Windows  │ Linux, MacOS    ║
  ; ║      │          ├────────┬────────╢
  ; ║      │ x86, x64 │ x86    │ x64    ║
  ; ╟──────┼──────────┼────────┼────────╢
  ; ║ int  │ 32 bit   │ 32 bit │ 32 bit ║
  ; ╟──────┼──────────┼────────┼────────╢
  ; ║ long │ 32 bit   │ 32 bit │ 64 bit ║
  ; ╚══════╧══════════╧════════╧════════╝
  ; #### uInt is defined as "unsigned int" and uLong as "unsigned long".
  CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS
    Macro C_long : i : EndMacro
    Macro C_uLong : i : EndMacro
  CompilerElse
    Macro C_long : l : EndMacro
    Macro C_uLong : l : EndMacro
  CompilerEndIf
  
  ; #### Configuration options that affect the Julia ABI
  ; If this is not defined, only individual dimension sizes are
  ; stored and not total length, to save space.
  #STORE_ARRAY_LEN = 1
  ; #### End Configuration options
  
  ;- core Data types ------------------------------------------------------------
  
  ; the common fields are hidden before the pointer, but the following Macro is
  ; used To indicate which types below are subtypes of jl_value_t
  Macro JL_DATA_TYPE : : EndMacro
  
  Structure jl_value_t
  EndStructure
  ; #### Pointer on jl_value_t
  Structure jl_value_t_p
    *_.jl_value_t
  EndStructure
  
  Structure _jl_taggedvalue_bits
    *gc
  EndStructure
  
  Structure jl_taggedvalue_t
    StructureUnion
      *header
      *Next.jl_taggedvalue_t
      *type.jl_value_t ; 16-byte aligned
      bits._jl_taggedvalue_bits
    EndStructureUnion
  EndStructure
  
  Declare.i jl_astaggedvalue(*v)
  Declare.i jl_valueof(*v)
  Declare.i jl_typeof(*v)
  Declare   jl_set_typeof(*v, *t)
  
  Macro jl_typeis(v,t) : Bool(jl_typeof(v) = (t)) : EndMacro
  
  ; Symbols are interned strings (hash-consed) stored As an invasive binary tree.
  ; The string Data is nul-terminated And hangs off the End of the struct.
  Structure jl_sym_t
      JL_DATA_TYPE
      *left.jl_sym_t
      *right.jl_sym_t
      hash.i            ; precomputed hash value
      ; JL_ATTRIBUTE_ALIGN_PTRSIZE(char name[]);
  EndStructure
  ; #### Pointer on jl_sym_t
  Structure jl_sym_t_p
    *_.jl_sym_t
  EndStructure
  
  ; A numbered SSA value, For optimized code analysis And generation
  ; the `id` is a unique, small number
  Structure jl_ssavalue_t
  EndStructure
  
  ; A SimpleVector is an immutable pointer Array
  ; Data is stored at the End of this variable-length struct.
  Structure jl_svec_t
  EndStructure
  ; #### Pointer on jl_svec_t
  Structure jl_svec_t_p
    *_.jl_svec_t
  EndStructure
  
  Structure jl_array_flags_t
      ; how - allocation style
      ; 0 = Data is inlined, Or a foreign pointer we don't manage
      ; 1 = julia-allocated buffer that needs To be marked
      ; 2 = malloc-allocated pointer this Array object manages
      ; 3 = has a pointer To the Array that owns the Data
  EndStructure
  
  Structure jl_array_t
    *_data
    CompilerIf Defined(STORE_ARRAY_LEN, #PB_Constant)
    length.i
    CompilerEndIf
    flags.jl_array_flags_t
    elsize.u
    offset.l        ; for 1-d only. does not need to get big.
    nrows.i
    StructureUnion
      ; 1d
      maxsize.i
      ; Nd
      ncols.i
    EndStructureUnion
    ; other dim sizes go here for ndims > 2

    ; followed by alignment padding and inline data, or owner pointer
  EndStructure
  
  ; compute # of extra words needed To store dimensions
  Declare jl_array_ndimwords(ndims.l)
  
  Structure jl_tupletype_t : EndStructure
  Structure _jl_method_instance_t : EndStructure
  
  ; TypeMap is an implicitly defined type
  ; that can consist of any of the following nodes:
  ;   typedef TypeMap Union{TypeMapLevel, TypeMapEntry, Void}
  ; it forms a roughly tree-shaped Structure, consisting of nodes of TypeMapLevels
  ; which split the tree when possible, For example based on the key into the tuple type at `offs`
  ; when key is a leaftype, (but only when the tree has enough entries For this To be
  ; more efficient than storing them sorted linearly)
  ; otherwise the leaf entries are stored sorted, linearly
  Structure jl_typemap_t
    StructureUnion
      *node._jl_typemap_level_t
      *leaf._jl_typemap_entry_t
      *unknown._jl_value_t      ; nothing
    EndStructureUnion
  EndStructure
  
  ; "jlcall" calling convention signatures.
  ; This defines the Default ABI used by compiled julia functions.
  ;typedef jl_value_t *(*jl_fptr_t)(jl_value_t*, jl_value_t**, uint32_t);
  ;typedef jl_value_t *(*jl_fptr_sparam_t)(jl_svec_t*, jl_value_t*, jl_value_t**, uint32_t);
  ;typedef jl_value_t *(*jl_fptr_linfo_t)(struct _jl_method_instance_t*, jl_value_t**, uint32_t, jl_svec_t*);
  
  ; TODO: Add jl_fptr_t structure
;   Structure jl_generic_fptr_t
;     StructureUnion
;       fptr.jl_fptr_t
;       fptr1.jl_fptr_t
;       ; constant fptr2;
;       fptr3.jl_fptr_sparam_t
;       fptr4.jl_fptr_linfo_t
;     EndStructureUnion
;     jlcall_api.a
;   EndStructure
  
  Structure jl_llvm_functions_t
  EndStructure
  
  ; This type describes a single function body
  Structure jl_code_info_t
  EndStructure
  
  ; This type describes a single method definition, And stores Data
  ; Shared by the specializations of a function.
  Structure jl_method_t
  EndStructure
  
  ; This type caches the Data For a specType signature specialization of a Method
  Structure jl_method_instance_t
  EndStructure
  
  ; all values are callable As Functions
  Structure jl_function_t
    jl_value_t.jl_value_t
  EndStructure
  
  ; a TypeConstructor (typealias)
  ; For example, Vector{T}:
  ;   body is the Vector{T} <: Type
  ;   parameters is the set {T}, the bound TypeVars in body
  Structure jl_typector_t
  EndStructure
  
  ; represents the "name" part of a DataType, describing the syntactic Structure
  ; of a type And storing all Data common To different instantiations of the type,
  ; including a cache For hash-consed allocation of DataType objects.
  Structure jl_typename_t
  EndStructure
  ; #### Pointer on jl_typename_t
  Structure jl_typename_t_p
    *_.jl_typename_t
  EndStructure
  
  Structure jl_uniontype_t
  EndStructure
  
  ; in little-endian, isptr is always the first bit, avoiding the need For a branch in computing isptr
  Structure jl_fielddesc8_t
  EndStructure
  
  Structure jl_fielddesc16_t
  EndStructure
  
  Structure jl_fielddesc32_t
  EndStructure
  
  Structure jl_datatype_layout_t
  EndStructure
  
  Structure jl_datatype_t
    JL_DATA_TYPE
    *name.jl_typename_t
    *super._jl_datatype_t
    *parameters.jl_svec_t
    *types.jl_svec_t
    *instance.jl_value_t  ; for singletons
    *layout.jl_datatype_layout_t
    size.l                ; TODO: move to _jl_datatype_layout_t
    ninitialized.l
    uid.l
    abstract.a
    mutabl.a
    ; memoized properties
    *struct_decl          ; llvm::Type*
    *ditype               ; llvm::MDNode* to be used as llvm::DIType(ditype)
    depth.l
    hastypevars.b         ; bound
    haswildcard.b         ; unbound
    isleaftype.b
  EndStructure
  ; #### Pointer on jl_datatype_t
  Structure jl_datatype_t_p
    *_.jl_datatype_t
  EndStructure
  
  Structure jl_tvar_t
  EndStructure
  ; #### Pointer on jl_tvar_t
  Structure jl_tvar_t_p
    *_.jl_tvar_t
  EndStructure
  
  Structure jl_weakref_t
  EndStructure
  
  Structure jl_binding_t
  EndStructure
  
  Structure jl_module_t
  EndStructure
   ; #### Pointer on jl_module_t
  Structure jl_module_t_p
    *_.jl_module_t
  EndStructure
  
  ; one Type-To-Value entry
  Structure jl_typemap_entry_t
  EndStructure
  
  ; one level in a TypeMap tree
  ; indexed by key If it is a sublevel in an Array
  Structure jl_ordereddict_t
  EndStructure
  Structure jl_typemap_level_t
  EndStructure
  
  ; contains the TypeMap For one Type
  Structure jl_methtable_t
  EndStructure
  
  Structure jl_expr_t
  EndStructure
  
  ;- constants And type objects -------------------------------------------------
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
      _JL_Library_ID = OpenLibrary(#PB_Any, "libjulia.dll")
      
;     CompilerCase #PB_OS_Linux
;       _JL_Library_ID = OpenLibrary(#PB_Any, "libjulia.so") ; TODO: Test julia on linux
      
    CompilerDefault
      CompilerError "Julia module: OS not supported."
  
  CompilerEndSelect
  
  If _JL_Library_ID
    Global *jl_any_type.jl_datatype_t_p              = GetFunction(_JL_Library_ID, "jl_any_type")
    Global *jl_type_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_type_type")
    Global *jl_typetype_tvar.jl_tvar_t_p             = GetFunction(_JL_Library_ID, "jl_typetype_tvar")
    Global *jl_typetype_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_typetype_type")
    Global *jl_ANY_flag.jl_value_t_p                 = GetFunction(_JL_Library_ID, "jl_ANY_flag")
    Global *jl_typename_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_typename_type")
    Global *jl_typector_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_typector_type")
    Global *jl_sym_type.jl_datatype_t_p              = GetFunction(_JL_Library_ID, "jl_sym_type")
    Global *jl_symbol_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_symbol_type")
    Global *jl_ssavalue_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_ssavalue_type")
    Global *jl_abstractslot_type.jl_datatype_t_p     = GetFunction(_JL_Library_ID, "jl_abstractslot_type")
    Global *jl_slotnumber_type.jl_datatype_t_p       = GetFunction(_JL_Library_ID, "jl_slotnumber_type")
    Global *jl_typedslot_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_typedslot_type")
    Global *jl_simplevector_type.jl_datatype_t_p     = GetFunction(_JL_Library_ID, "jl_simplevector_type")
    Global *jl_tuple_typename.jl_typename_t_p        = GetFunction(_JL_Library_ID, "jl_tuple_typename")
    Global *jl_vecelement_typename.jl_typename_t_p   = GetFunction(_JL_Library_ID, "jl_vecelement_typename")
    Global *jl_anytuple_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_anytuple_type")
    Macro jl_tuple_type : jl_anytuple_type : EndMacro
    Global *jl_anytuple_type_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_anytuple_type_type")
    Global *jl_vararg_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_vararg_type")
    Global *jl_tvar_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_tvar_type")
    Global *jl_task_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_task_type")
    Global *jl_function_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_function_type")
    Global *jl_builtin_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_builtin_type")
    
    Global *jl_uniontype_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_uniontype_type")
    Global *jl_datatype_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_datatype_type")
    
    Global *jl_bottom_type.jl_value_t_p              = GetFunction(_JL_Library_ID, "jl_bottom_type")
    Global *jl_lambda_info_type.jl_datatype_t_p      = GetFunction(_JL_Library_ID, "jl_lambda_info_type")
    Global *jl_method_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_method_type")
    Global *jl_module_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_module_type")
    Global *jl_abstractarray_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_abstractarray_type")
    Global *jl_densearray_type.jl_datatype_t_p       = GetFunction(_JL_Library_ID, "jl_densearray_type")
    Global *jl_array_type.jl_datatype_t_p            = GetFunction(_JL_Library_ID, "jl_array_type")
    Global *jl_array_typename.jl_typename_t_p        = GetFunction(_JL_Library_ID, "jl_array_typename")
    Global *jl_weakref_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_weakref_type")
    Global *jl_string_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_string_type")
    Global *jl_errorexception_type.jl_datatype_t_p   = GetFunction(_JL_Library_ID, "jl_errorexception_type")
    Global *jl_argumenterror_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_argumenterror_type")
    Global *jl_loaderror_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_loaderror_type")
    Global *jl_initerror_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_initerror_type")
    Global *jl_typeerror_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_typeerror_type")
    Global *jl_methoderror_type.jl_datatype_t_p      = GetFunction(_JL_Library_ID, "jl_methoderror_type")
    Global *jl_undefvarerror_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_undefvarerror_type")
    Global *jl_stackovf_exception.jl_value_t_p       = GetFunction(_JL_Library_ID, "jl_stackovf_exception")
    Global *jl_memory_exception.jl_value_t_p         = GetFunction(_JL_Library_ID, "jl_memory_exception")
    Global *jl_readonlymemory_exception.jl_value_t_p = GetFunction(_JL_Library_ID, "jl_readonlymemory_exception")
    Global *jl_diverror_exception.jl_value_t_p       = GetFunction(_JL_Library_ID, "jl_diverror_exception")
    Global *jl_domain_exception.jl_value_t_p         = GetFunction(_JL_Library_ID, "jl_domain_exception")
    Global *jl_overflow_exception.jl_value_t_p       = GetFunction(_JL_Library_ID, "jl_overflow_exception")
    Global *jl_inexact_exception.jl_value_t_p        = GetFunction(_JL_Library_ID, "jl_inexact_exception")
    Global *jl_undefref_exception.jl_value_t_p       = GetFunction(_JL_Library_ID, "jl_undefref_exception")
    Global *jl_interrupt_exception.jl_value_t_p      = GetFunction(_JL_Library_ID, "jl_interrupt_exception")
    Global *jl_boundserror_type.jl_datatype_t_p      = GetFunction(_JL_Library_ID, "jl_boundserror_type")
    Global *jl_an_empty_vec_any.jl_value_t_p         = GetFunction(_JL_Library_ID, "jl_an_empty_vec_any")
    
    Global *jl_bool_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_bool_type")
    Global *jl_char_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_char_type")
    Global *jl_int8_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_int8_type")
    Global *jl_uint8_type.jl_datatype_t_p            = GetFunction(_JL_Library_ID, "jl_uint8_type")
    Global *jl_int16_type.jl_datatype_t_p            = GetFunction(_JL_Library_ID, "jl_int16_type")
    Global *jl_uint16_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_uint16_type")
    Global *jl_int32_type.jl_datatype_t_p            = GetFunction(_JL_Library_ID, "jl_int32_type")
    Global *jl_uint32_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_uint32_type")
    Global *jl_int64_type.jl_datatype_t_p            = GetFunction(_JL_Library_ID, "jl_int64_type")
    Global *jl_uint64_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_uint64_type")
    Global *jl_float16_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_float16_type")
    Global *jl_float32_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_float32_type")
    Global *jl_float64_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_float64_type")
    Global *jl_floatingpoint_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_floatingpoint_type")
    Global *jl_number_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_number_type")
    Global *jl_void_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_void_type")
    Global *jl_complex_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_complex_type")
    Global *jl_signed_type.jl_datatype_t_p           = GetFunction(_JL_Library_ID, "jl_signed_type")
    Global *jl_voidpointer_type.jl_datatype_t_p      = GetFunction(_JL_Library_ID, "jl_voidpointer_type")
    Global *jl_pointer_type.jl_datatype_t_p          = GetFunction(_JL_Library_ID, "jl_pointer_type")
    Global *jl_ref_type.jl_datatype_t_p              = GetFunction(_JL_Library_ID, "jl_ref_type")
    
    Global *jl_array_uint8_type.jl_value_t_p         = GetFunction(_JL_Library_ID, "jl_array_uint8_type")
    Global *jl_array_any_type.jl_value_t_p           = GetFunction(_JL_Library_ID, "jl_array_any_type")
    Global *jl_array_symbol_type.jl_value_t_p        = GetFunction(_JL_Library_ID, "jl_array_symbol_type")
    Global *jl_expr_type.jl_datatype_t_p             = GetFunction(_JL_Library_ID, "jl_expr_type")
    Global *jl_globalref_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_globalref_type")
    Global *jl_linenumbernode_type.jl_datatype_t_p   = GetFunction(_JL_Library_ID, "jl_linenumbernode_type")
    Global *jl_labelnode_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_labelnode_type")
    Global *jl_gotonode_type.jl_datatype_t_p         = GetFunction(_JL_Library_ID, "jl_gotonode_type")
    Global *jl_quotenode_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_quotenode_type")
    Global *jl_newvarnode_type.jl_datatype_t_p       = GetFunction(_JL_Library_ID, "jl_newvarnode_type")
    Global *jl_intrinsic_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_intrinsic_type")
    Global *jl_methtable_type.jl_datatype_t_p        = GetFunction(_JL_Library_ID, "jl_methtable_type")
    Global *jl_typemap_level_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_typemap_level_type")
    Global *jl_typemap_entry_type.jl_datatype_t_p    = GetFunction(_JL_Library_ID, "jl_typemap_entry_type")
    
    Global *jl_emptysvec.jl_svec_t_p                 = GetFunction(_JL_Library_ID, "jl_emptysvec")
    Global *jl_emptytuple.jl_value_t_p               = GetFunction(_JL_Library_ID, "jl_emptytuple")
    Global *jl_true.jl_value_t_p                     = GetFunction(_JL_Library_ID, "jl_true")
    Global *jl_false.jl_value_t_p                    = GetFunction(_JL_Library_ID, "jl_false")
    Global *jl_nothing.jl_value_t_p                  = GetFunction(_JL_Library_ID, "jl_nothing")
    
    ; some important symbols
    Global *call_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "call_sym")
    Global *invoke_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "invoke_sym")
    Global *empty_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "empty_sym")
    Global *body_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "body_sym")
    Global *dots_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "dots_sym")
    Global *vararg_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "vararg_sym")
    Global *quote_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "quote_sym")
    Global *newvar_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "newvar_sym")
    Global *top_sym.jl_sym_t_p               = GetFunction(_JL_Library_ID, "top_sym")
    Global *dot_sym.jl_sym_t_p               = GetFunction(_JL_Library_ID, "dot_sym")
    Global *line_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "line_sym")
    Global *toplevel_sym.jl_sym_t_p          = GetFunction(_JL_Library_ID, "toplevel_sym")
    Global *core_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "core_sym")
    Global *globalref_sym.jl_sym_t_p         = GetFunction(_JL_Library_ID, "globalref_sym")
    Global *jl_incomplete_sym.jl_sym_t_p     = GetFunction(_JL_Library_ID, "jl_incomplete_sym")
    Global *error_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "error_sym")
    Global *amp_sym.jl_sym_t_p               = GetFunction(_JL_Library_ID, "amp_sym")
    Global *module_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "module_sym")
    Global *colons_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "colons_sym")
    Global *export_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "export_sym")
    Global *import_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "import_sym")
    Global *importall_sym.jl_sym_t_p         = GetFunction(_JL_Library_ID, "importall_sym")
    Global *using_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "using_sym")
    Global *goto_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "goto_sym")
    Global *goto_ifnot_sym.jl_sym_t_p        = GetFunction(_JL_Library_ID, "goto_ifnot_sym")
    Global *label_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "label_sym")
    Global *return_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "return_sym")
    Global *lambda_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "lambda_sym")
    Global *assign_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "assign_sym")
    Global *method_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "method_sym")
    Global *slot_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "slot_sym")
    Global *enter_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "enter_sym")
    Global *leave_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "leave_sym")
    Global *exc_sym.jl_sym_t_p               = GetFunction(_JL_Library_ID, "exc_sym")
    Global *new_sym.jl_sym_t_p               = GetFunction(_JL_Library_ID, "new_sym")
    Global *compiler_temp_sym.jl_sym_t_p     = GetFunction(_JL_Library_ID, "compiler_temp_sym")
    Global *const_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "const_sym")
    Global *thunk_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "thunk_sym")
    Global *anonymous_sym.jl_sym_t_p         = GetFunction(_JL_Library_ID, "anonymous_sym")
    Global *underscore_sym.jl_sym_t_p        = GetFunction(_JL_Library_ID, "underscore_sym")
    Global *abstracttype_sym.jl_sym_t_p      = GetFunction(_JL_Library_ID, "abstracttype_sym")
    Global *bitstype_sym.jl_sym_t_p          = GetFunction(_JL_Library_ID, "bitstype_sym")
    Global *compositetype_sym.jl_sym_t_p     = GetFunction(_JL_Library_ID, "compositetype_sym")
    Global *global_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "global_sym")
    Global *unused_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "unused_sym")
    Global *boundscheck_sym.jl_sym_t_p       = GetFunction(_JL_Library_ID, "boundscheck_sym")
    Global *inbounds_sym.jl_sym_t_p          = GetFunction(_JL_Library_ID, "inbounds_sym")
    Global *copyast_sym.jl_sym_t_p           = GetFunction(_JL_Library_ID, "copyast_sym")
    Global *fastmath_sym.jl_sym_t_p          = GetFunction(_JL_Library_ID, "fastmath_sym")
    Global *pure_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "pure_sym")
    Global *simdloop_sym.jl_sym_t_p          = GetFunction(_JL_Library_ID, "simdloop_sym")
    Global *meta_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "meta_sym")
    Global *list_sym.jl_sym_t_p              = GetFunction(_JL_Library_ID, "list_sym")
    Global *inert_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "inert_sym")
    Global *static_parameter_sym.jl_sym_t_p  = GetFunction(_JL_Library_ID, "static_parameter_sym")
    Global *polly_sym.jl_sym_t_p             = GetFunction(_JL_Library_ID, "polly_sym")
    Global *inline_sym.jl_sym_t_p            = GetFunction(_JL_Library_ID, "inline_sym")
  EndIf
  
  ;- threading ------------------------------------------------------------------
  ; This includes all the thread local states we care about for a thread.
  #JL_MAX_BT_SIZE = 80000
  ; Whether it is safe to execute GC at the same time.
  #JL_GC_STATE_WAITING = 1    ; gc_state = 1 means the thread is doing GC or is waiting For the GC to finish.
  #JL_GC_STATE_SAFE = 2       ; gc_state = 2 means the thread is running unmanaged code that can be execute at the same time with the GC.
  Structure jl_tls_states_t
    *pgcstack.jl_gcframe_t
    *exception_in_transit.jl_value_t
    *safepoint.Integer
    gc_state.b                ; Whether it is safe to execute GC at the same time.
    in_finalizer.b
    disable_gc.b
    defer_signal.i
    *current_module.jl_module_t
    *current_task.jl_task_t
    *root_task.jl_task_t
    *task_arg_in_transit.jl_value_t
    *stackbase
    *stack_lo
    *stack_hi
    *jmp_target.jl_jmp_buf
    *base_ctx.jl_jmp_buf    ; base context of stack
    *safe_restore.jl_jmp_buf
    tid.w
    bt_size.i
    ; JL_MAX_BT_SIZE + 1 elements long
    *bt_data.Integer
    ; Atomically set by the sender, reset by the handler.
    signal_request.i
    ; Allow the sigint To be raised asynchronously
    ; this is limited To the few places we do synchronous IO
    ; we can make this more general (similar To defer_signal) If necessary
    io_wait.i
;     heap.jl_thread_heap_t ; TODO: Add structure jl_thread_heap_t
;     CompilerIf Not #PB_Compiler_OS = #PB_OS_Windows
;     ; These are only used on unix now
;     system_id.i
;     *signal_stack
;     CompilerEndIf
;     ; execution of certain certain impure
;     ; statements is prohibited from certain
;     ; callbacks (such As generated functions)
;     ; As it may make compilation undecidable
;     in_pure_callback.l
;     ; Counter To disable finalizer **on the current thread**
;     finalizers_inhibited.l
;     finalizersarraylist_t
  EndStructure
  Macro jl_ptls_t : jl_tls_states_t : EndMacro
  
  PrototypeC.i jl_get_ptls_states() ; Returns *jl_ptls_t.jl_ptls_t
  If _JL_Library_ID
    Global jl_get_ptls_states.jl_get_ptls_states = GetFunction(_JL_Library_ID, "jl_get_ptls_states")
  EndIf
  
  ;- gc -------------------------------------------------------------------------
  
  Structure jl_gcframe_t
    nroots.i
    *prev._jl_gcframe_t
    ; actual roots go here
  EndStructure
  
  ; NOTE: it is the caller's responsibility to make sure arguments are
  ; rooted such that the gc can see them on the stack.
  ; `foo(f(), g())` is not safe,
  ; since the result of `f()` is not rooted during the call to `g()`,
  ; and the arguments to foo are not gc-protected during the call to foo.
  ; foo can't do anything about it, so the caller must do:
  ; jl_value_t *x=NULL, *y=NULL; JL_GC_PUSH2(&x, &y);
  ; x = f(); y = g(); foo(x, y)
  
  Declare.i jl_pgcstack()
  Declare   JL_GC_PUSH1(arg1)
  Declare   JL_GC_PUSH2(arg1, arg2)
  Declare   JL_GC_PUSH3(arg1, arg2, arg3)
  Declare   JL_GC_PUSH4(arg1, arg2, arg3, arg4)
  Declare   JL_GC_PUSH5(arg1, arg2, arg3, arg4, arg5)
  Declare   JL_GC_POP()
  
  ; #define JL_GC_PUSHARGS(rts_var,n)                               \
  ;   rts_var = ((jl_value_t**)alloca(((n)+2)*SizeOf(jl_value_t*)))+2;    \
  ;   ((void**)rts_var)[-2] = (void*)(((size_t)(n))<<1);                  \
  ;   ((void**)rts_var)[-1] = jl_pgcstack;                          \
  ;   memset((void*)rts_var, 0, (n)*SizeOf(jl_value_t*));           \
  ;   jl_pgcstack = (jl_gcframe_t*)&(((void**)rts_var)[-2])
  
  PrototypeC.l jl_gc_enable(on.l)
  PrototypeC.l jl_gc_is_enabled()
  PrototypeC.q jl_gc_total_bytes()
  PrototypeC.q jl_gc_total_hrtime()
  PrototypeC.q jl_gc_diff_total_bytes()
  
  PrototypeC   jl_gc_collect(int.l)
  
  PrototypeC   jl_gc_add_finalizer(*v.jl_value_t, *f.jl_function_t)
  PrototypeC   jl_finalize(*o.jl_value_t)
  PrototypeC.i jl_gc_new_weakref(*value.jl_value_t) ; Returns *jl_weakref_t.jl_weakref_t
  PrototypeC.i jl_gc_alloc_0w()                     ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_gc_alloc_1w()                     ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_gc_alloc_2w()                     ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_gc_alloc_3w()                     ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_gc_allocobj(sz.i)                 ; Returns *jl_value_t.jl_value_t
  
  PrototypeC   jl_clear_malloc_data()
  
  ; GC write barriers
  PrototypeC   jl_gc_queue_root(*root.jl_value_t)   ; root is a jl_value_t*
  
  ; ; Do NOT put a safepoint here
  ; STATIC_INLINE void jl_gc_wb(void *parent, void *ptr)
  ; {
  ;     ; parent and ptr isa jl_value_t*
  ;     If (__unlikely(jl_astaggedvalue(parent)->bits.gc == 3 &&
  ;                    (jl_astaggedvalue(ptr)->bits.gc & 1) == 0))
  ;         jl_gc_queue_root((jl_value_t*)parent);
  ; }
  ; 
  ; STATIC_INLINE void jl_gc_wb_back(void *ptr) ; ptr isa jl_value_t*
  ; {
  ;     ; if ptr is old
  ;     If (__unlikely(jl_astaggedvalue(ptr)->bits.gc == 3)) {
  ;         jl_gc_queue_root((jl_value_t*)ptr);
  ;     }
  ; }
  
  PrototypeC.i jl_gc_managed_malloc(sz.i)
  PrototypeC.i jl_gc_managed_realloc(*d, sz.i, oldsz.i, isaligned.l, *owner.jl_value_t)
  
  If _JL_Library_ID
    Global jl_gc_enable.jl_gc_enable                     = GetFunction(_JL_Library_ID, "jl_gc_enable")
    Global jl_gc_is_enabled.jl_gc_is_enabled             = GetFunction(_JL_Library_ID, "jl_gc_is_enabled")
    Global jl_gc_total_bytes.jl_gc_total_bytes           = GetFunction(_JL_Library_ID, "jl_gc_total_bytes")
    Global jl_gc_total_hrtime.jl_gc_total_hrtime         = GetFunction(_JL_Library_ID, "jl_gc_total_hrtime")
    Global jl_gc_diff_total_bytes.jl_gc_diff_total_bytes = GetFunction(_JL_Library_ID, "jl_gc_diff_total_bytes")
    
    Global jl_gc_collect.jl_gc_collect                   = GetFunction(_JL_Library_ID, "jl_gc_collect")
    
    Global jl_gc_add_finalizer.jl_gc_add_finalizer       = GetFunction(_JL_Library_ID, "jl_gc_add_finalizer")
    Global jl_finalize.jl_finalize                       = GetFunction(_JL_Library_ID, "jl_finalize")
    Global jl_gc_new_weakref.jl_gc_new_weakref           = GetFunction(_JL_Library_ID, "jl_gc_new_weakref")
    Global jl_gc_alloc_0w.jl_gc_alloc_0w                 = GetFunction(_JL_Library_ID, "jl_gc_alloc_0w")
    Global jl_gc_alloc_1w.jl_gc_alloc_1w                 = GetFunction(_JL_Library_ID, "jl_gc_alloc_1w")
    Global jl_gc_alloc_2w.jl_gc_alloc_2w                 = GetFunction(_JL_Library_ID, "jl_gc_alloc_2w")
    Global jl_gc_alloc_3w.jl_gc_alloc_3w                 = GetFunction(_JL_Library_ID, "jl_gc_alloc_3w")
    Global jl_gc_allocobj.jl_gc_allocobj                 = GetFunction(_JL_Library_ID, "jl_gc_allocobj")
    
    Global jl_clear_malloc_data.jl_clear_malloc_data     = GetFunction(_JL_Library_ID, "jl_clear_malloc_data")
    
    Global jl_gc_queue_root.jl_gc_queue_root             = GetFunction(_JL_Library_ID, "jl_gc_queue_root")
    
    Global jl_gc_managed_malloc.jl_gc_managed_malloc     = GetFunction(_JL_Library_ID, "jl_gc_managed_malloc")
    Global jl_gc_managed_realloc.jl_gc_managed_realloc   = GetFunction(_JL_Library_ID, "jl_gc_managed_realloc")
  EndIf
  
  ;- object accessors -----------------------------------------------------------
  
;   #define jl_svec_len(t)              (((jl_svec_t*)(t))->length)
;   #define jl_svec_set_len_unsafe(t,n) (((jl_svec_t*)(t))->length=(n))
;   #define jl_svec_data(t) ((jl_value_t**)((char*)(t) + SizeOf(jl_svec_t)))
;   
;   STATIC_INLINE jl_value_t *jl_svecref(void *t, size_t i)
;   {
;       assert(jl_typeis(t,jl_simplevector_type));
;       assert(i < jl_svec_len(t));
;       Return jl_svec_data(t)[i];
;   }
;   STATIC_INLINE jl_value_t *jl_svecset(void *t, size_t i, void *x)
;   {
;       assert(jl_typeis(t,jl_simplevector_type));
;       assert(i < jl_svec_len(t));
;       jl_svec_data(t)[i] = (jl_value_t*)x;
;       If (x) jl_gc_wb(t, x);
;       Return (jl_value_t*)x;
;   }
;   
CompilerIf Defined(STORE_ARRAY_LEN, #PB_Constant)
  Declare.i jl_array_len(*a.jl_array_t)
CompilerElse
  PrototypeC.i jl_array_len_(*a.jl_array_t)
  Declare.i jl_array_len(*a.jl_array_t)
CompilerEndIf
  Declare.i jl_array_data(*a.jl_array_t)
;   #define jl_array_dim(a,i) ((&((jl_array_t*)(a))->nrows)[i])
;   #define jl_array_dim0(a)  (((jl_array_t*)(a))->nrows)
;   #define jl_array_nrows(a) (((jl_array_t*)(a))->nrows)
;   #define jl_array_ndims(a) ((int32_t)(((jl_array_t*)a)->flags.ndims))
;   #define jl_array_data_owner_offset(ndims) (OffsetOf(jl_array_t,ncols) + SizeOf(size_t)*(1+jl_array_ndimwords(ndims))) ; in bytes
;   #define jl_array_data_owner(a) (*((jl_value_t**)((char*)a + jl_array_data_owner_offset(jl_array_ndims(a)))))
;   
;   STATIC_INLINE jl_value_t *jl_array_ptr_ref(void *a, size_t i)
;   {
;       assert(i < jl_array_len(a));
;       Return ((jl_value_t**)(jl_array_data(a)))[i];
;   }
;   STATIC_INLINE jl_value_t *jl_array_ptr_set(void *a, size_t i, void *x)
;   {
;       assert(i < jl_array_len(a));
;       ((jl_value_t**)(jl_array_data(a)))[i] = (jl_value_t*)x;
;       If (x) {
;           If (((jl_array_t*)a)->flags.how == 3) {
;               a = jl_array_data_owner(a);
;           }
;           jl_gc_wb(a, x);
;       }
;       Return (jl_value_t*)x;
;   }
;   
;   STATIC_INLINE uint8_t jl_array_uint8_ref(void *a, size_t i)
;   {
;       assert(i < jl_array_len(a));
;       assert(jl_typeis(a, jl_array_uint8_type));
;       Return ((uint8_t*)(jl_array_data(a)))[i];
;   }
;   STATIC_INLINE void jl_array_uint8_set(void *a, size_t i, uint8_t x)
;   {
;       assert(i < jl_array_len(a));
;       assert(jl_typeis(a, jl_array_uint8_type));
;       ((uint8_t*)(jl_array_data(a)))[i] = x;
;   }
;   
;   #define jl_exprarg(e,n) (((jl_value_t**)jl_array_data(((jl_expr_t*)(e))->args))[n])
;   #define jl_exprargset(e, n, v) jl_array_ptr_set(((jl_expr_t*)(e))->args, n, v)
;   #define jl_expr_nargs(e) jl_array_len(((jl_expr_t*)(e))->args)
;   
;   #define jl_fieldref(s,i) jl_get_nth_field(((jl_value_t*)s),i)
;   #define jl_nfields(v)    jl_datatype_nfields(jl_typeof(v))
;   
;   ; Not using jl_fieldref to avoid allocations
;   #define jl_linenode_line(x) (((intptr_t*)x)[0])
;   #define jl_labelnode_label(x) (((intptr_t*)x)[0])
;   #define jl_slot_number(x) (((intptr_t*)x)[0])
;   #define jl_typedslot_get_type(x) (((jl_value_t**)x)[1])
;   #define jl_gotonode_label(x) (((intptr_t*)x)[0])
;   #define jl_globalref_mod(s) (*(jl_module_t**)s)
;   #define jl_globalref_name(s) (((jl_sym_t**)s)[1])
;   
;   #define jl_nparams(t)  jl_svec_len(((jl_datatype_t*)(t))->parameters)
;   #define jl_tparam0(t)  jl_svecref(((jl_datatype_t*)(t))->parameters, 0)
;   #define jl_tparam1(t)  jl_svecref(((jl_datatype_t*)(t))->parameters, 1)
;   #define jl_tparam(t,i) jl_svecref(((jl_datatype_t*)(t))->parameters, i)
;   
;   ; get a pointer to the data in a datatype
;   #define jl_data_ptr(v)  ((jl_value_t**)v)
;   
;   #define jl_array_ptr_data(a)   ((jl_value_t**)((jl_array_t*)a)->Data)
;   #define jl_string_data(s) ((char*)((jl_array_t*)jl_data_ptr(s)[0])->Data)
;   #define jl_string_len(s)  (jl_array_len((jl_array_t*)(jl_data_ptr(s)[0])))
;   #define jl_iostr_data(s)  ((char*)((jl_array_t*)jl_data_ptr(s)[0])->Data)
;   
;   #define jl_gf_mtable(f) (((jl_datatype_t*)jl_typeof(f))->name->mt)
;   #define jl_gf_name(f)   (jl_gf_mtable(f)->name)
;   
;   ; struct type info
;   #define jl_field_name(st,i)    (jl_sym_t*)jl_svecref(((jl_datatype_t*)st)->name->names, (i))
;   #define jl_field_type(st,i)    jl_svecref(((jl_datatype_t*)st)->types, (i))
;   #define jl_field_count(st)     jl_svec_len(((jl_datatype_t*)st)->types)
;   #define jl_datatype_size(t)    (((jl_datatype_t*)t)->size)
;   #define jl_datatype_nfields(t) (((jl_datatype_t*)(t))->layout->nfields)
;   
;   ; inline version with strong type check to detect typos in a `->name` chain
;   STATIC_INLINE char *jl_symbol_name_(jl_sym_t *s)
;   {
;       Return (char*)s + LLT_ALIGN(SizeOf(jl_sym_t), SizeOf(void*));
;   }
;   #define jl_symbol_name(s) jl_symbol_name_(s)
;   
;   #define jl_dt_layout_fields(d) ((const char*)(d) + SizeOf(jl_datatype_layout_t))
;   
;   #define DEFINE_FIELD_ACCESSORS(f)                                             \
;       Static inline uint32_t jl_field_##f(jl_datatype_t *st, int i)             \
;       {                                                                         \
;           const jl_datatype_layout_t *ly = st->layout;                          \
;           assert(i >= 0 && (size_t)i < ly->nfields);                            \
;           If (ly->fielddesc_type == 0) {                                        \
;               Return ((const jl_fielddesc8_t*)jl_dt_layout_fields(ly))[i].f;    \
;           }                                                                     \
;           Else If (ly->fielddesc_type == 1) {                                   \
;               Return ((const jl_fielddesc16_t*)jl_dt_layout_fields(ly))[i].f;   \
;           }                                                                     \
;           Else {                                                                \
;               Return ((const jl_fielddesc32_t*)jl_dt_layout_fields(ly))[i].f;   \
;           }                                                                     \
;       }                                                                         \
;   
;   DEFINE_FIELD_ACCESSORS(offset)
;   DEFINE_FIELD_ACCESSORS(size)
;   Static inline int jl_field_isptr(jl_datatype_t *st, int i)
;   {
;       const jl_datatype_layout_t *ly = st->layout;
;       assert(i >= 0 && (size_t)i < ly->nfields);
;       Return ((const jl_fielddesc8_t*)(jl_dt_layout_fields(ly) + (i << (ly->fielddesc_type + 1))))->isptr;
;   }
;   
;   Static inline uint32_t jl_fielddesc_size(int8_t fielddesc_type)
;   {
;       If (fielddesc_type == 0) {
;           Return SizeOf(jl_fielddesc8_t);
;       }
;       Else If (fielddesc_type == 1) {
;           Return SizeOf(jl_fielddesc16_t);
;       }
;       Else {
;           Return SizeOf(jl_fielddesc32_t);
;       }
;   }
;   
;   #undef DEFINE_FIELD_ACCESSORS
  
  If _JL_Library_ID
  CompilerIf Not Defined(STORE_ARRAY_LEN, #PB_Constant)
    Global jl_array_len_.jl_array_len_                   = GetFunction(_JL_Library_ID, "jl_array_len_")
  CompilerEndIf
  EndIf
  
  ;- basic predicates -----------------------------------------------------------
  Macro jl_is_nothing(v)            : ((v) =  *jl_nothing\_)                                                    : EndMacro
  ; Macro jl_is_tuple(v)              : (((jl_datatype_t*)jl_typeof(v))->name == jl_tuple_typename)               : EndMacro
  Macro jl_is_svec(v)               : jl_typeis(v, *jl_simplevector_type\_)                                     : EndMacro
  Macro jl_is_simplevector(v)       : jl_is_svec(v)                                                             : EndMacro
  Macro jl_is_datatype(v)           : jl_typeis(v, *jl_datatype_type\_)                                         : EndMacro
  ; Macro jl_is_mutable(t)            : (((jl_datatype_t*)t)->mutabl)                                             : EndMacro
  ; Macro jl_is_mutable_datatype(t)   : (jl_is_datatype(t) && (((jl_datatype_t*)t)->mutabl))                      : EndMacro
  ; Macro jl_is_immutable(t)          : (!((jl_datatype_t*)t)->mutabl)                                            : EndMacro
  ; Macro jl_is_immutable_datatype(t) : (jl_is_datatype(t) && (!((jl_datatype_t*)t)->mutabl))                     : EndMacro
  Macro jl_is_uniontype(v)          : jl_typeis(v, *jl_uniontype_type\_)                                        : EndMacro
  Macro jl_is_typevar(v)            : jl_typeis(v, *jl_tvar_type\_)                                             : EndMacro
  Macro jl_is_typector(v)           : jl_typeis(v, *jl_typector_type\_)                                         : EndMacro
  Macro jl_is_TypeConstructor(v)    : jl_typeis(v, *jl_typector_type\_)                                         : EndMacro
  Macro jl_is_typename(v)           : jl_typeis(v, *jl_typename_type\_)                                         : EndMacro
  Macro jl_is_int8(v)               : jl_typeis(v, *jl_int8_type\_)                                             : EndMacro
  Macro jl_is_int16(v)              : jl_typeis(v, *jl_int16_type\_)                                            : EndMacro
  Macro jl_is_int32(v)              : jl_typeis(v, *jl_int32_type\_)                                            : EndMacro
  Macro jl_is_int64(v)              : jl_typeis(v, *jl_int64_type\_)                                            : EndMacro
  Macro jl_is_uint8(v)              : jl_typeis(v, *jl_uint8_type\_)                                            : EndMacro
  Macro jl_is_uint16(v)             : jl_typeis(v, *jl_uint16_type\_)                                           : EndMacro
  Macro jl_is_uint32(v)             : jl_typeis(v, *jl_uint32_type\_)                                           : EndMacro
  Macro jl_is_uint64(v)             : jl_typeis(v, *jl_uint64_type\_)                                           : EndMacro
  Macro jl_is_float(v)              : jl_subtype(v, *jl_floatingpoint_type\_,1)                                 : EndMacro
  Macro jl_is_floattype(v)          : jl_subtype(v, *jl_floatingpoint_type\_,0)                                 : EndMacro
  Macro jl_is_float32(v)            : jl_typeis(v, *jl_float32_type\_)                                          : EndMacro
  Macro jl_is_float64(v)            : jl_typeis(v, *jl_float64_type\_)                                          : EndMacro
  Macro jl_is_bool(v)               : jl_typeis(v, *jl_bool_type\_)                                             : EndMacro
  Macro jl_is_symbol(v)             : jl_typeis(v, *jl_sym_type\_)                                              : EndMacro
  Macro jl_is_ssavalue(v)           : jl_typeis(v, *jl_ssavalue_type\_)                                         : EndMacro
  Macro jl_is_slot(v)               : (jl_typeis(v, *jl_slotnumber_type\_) || jl_typeis(v, *jl_typedslot_type\_)) : EndMacro
  Macro jl_is_expr(v)               : jl_typeis(v, *jl_expr_type\_)                                             : EndMacro
  Macro jl_is_globalref(v)          : jl_typeis(v, *jl_globalref_type\_)                                        : EndMacro
  Macro jl_is_labelnode(v)          : jl_typeis(v, *jl_labelnode_type\_)                                        : EndMacro
  Macro jl_is_gotonode(v)           : jl_typeis(v, *jl_gotonode_type\_)                                         : EndMacro
  Macro jl_is_quotenode(v)          : jl_typeis(v, *jl_quotenode_type\_)                                        : EndMacro
  Macro jl_is_newvarnode(v)         : jl_typeis(v, *jl_newvarnode_type\_)                                       : EndMacro
  Macro jl_is_linenode(v)           : jl_typeis(v, *jl_linenumbernode_type\_)                                   : EndMacro
  Macro jl_is_lambda_info(v)        : jl_typeis(v, *jl_lambda_info_type\_)                                      : EndMacro
  Macro jl_is_method(v)             : jl_typeis(v, *jl_method_type\_)                                           : EndMacro
  Macro jl_is_module(v)             : jl_typeis(v, *jl_module_type\_)                                           : EndMacro
  Macro jl_is_mtable(v)             : jl_typeis(v, *jl_methtable_type\_)                                        : EndMacro
  Macro jl_is_task(v)               : jl_typeis(v, *jl_task_type\_)                                             : EndMacro
  Macro jl_is_string(v)             : jl_typeis(v, *jl_string_type\_)                                           : EndMacro
  Macro jl_is_cpointer(v)           : jl_is_cpointer_type(jl_typeof(v))                                         : EndMacro
  Macro jl_is_pointer(v)            : jl_is_cpointer_type(jl_typeof(v))                                         : EndMacro
  
  ; STATIC_INLINE int jl_is_bitstype(void *v)
  ; {
  ;     Return (jl_is_datatype(v) && jl_is_immutable(v) &&
  ;             ((jl_datatype_t*)(v))->layout &&
  ;             jl_datatype_nfields(v) == 0 &&
  ;             ((jl_datatype_t*)(v))->size > 0);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_structtype(void *v)
  ; {
  ;     Return (jl_is_datatype(v) &&
  ;             (jl_field_count(v) > 0 ||
  ;              ((jl_datatype_t*)(v))->size == 0) &&
  ;             !((jl_datatype_t*)(v))->abstract);
  ; }
  ; 
  ; STATIC_INLINE int jl_isbits(void *t)   ; corresponding to isbits() in julia
  ; {
  ;     Return (jl_is_datatype(t) && ((jl_datatype_t*)t)->layout &&
  ;             !((jl_datatype_t*)t)->mutabl && ((jl_datatype_t*)t)->layout->pointerfree);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_datatype_singleton(jl_datatype_t *d)
  ; {
  ;     Return (d->instance != NULL);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_datatype_make_singleton(jl_datatype_t *d)
  ; {
  ;     Return (!d->abstract && d->size == 0 && d != jl_sym_type && d->name != jl_array_typename &&
  ;             d->uid != 0 && (d->name->names == jl_emptysvec || !d->mutabl));
  ; }
  ; 
  ; STATIC_INLINE int jl_is_abstracttype(void *v)
  ; {
  ;     Return (jl_is_datatype(v) && ((jl_datatype_t*)(v))->abstract);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_array_type(void *t)
  ; {
  ;     Return (jl_is_datatype(t) &&
  ;             ((jl_datatype_t*)(t))->name == jl_array_typename);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_array(void *v)
  ; {
  ;     jl_value_t *t = jl_typeof(v);
  ;     Return jl_is_array_type(t);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_cpointer_type(jl_value_t *t)
  ; {
  ;     Return (jl_is_datatype(t) &&
  ;             ((jl_datatype_t*)(t))->name == jl_pointer_type->name);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_abstract_ref_type(jl_value_t *t)
  ; {
  ;     Return (jl_is_datatype(t) &&
  ;             ((jl_datatype_t*)(t))->name == jl_ref_type->name);
  ; }
  ; 
  ; STATIC_INLINE jl_value_t *jl_is_ref_type(jl_value_t *t)
  ; {
  ;     If (!jl_is_datatype(t)) Return 0;
  ;     jl_datatype_t *dt = (jl_datatype_t*)t;
  ;     While (dt != jl_any_type && dt->name != dt->super->name) {
  ;         If (dt->name == jl_ref_type->name)
  ;             Return (jl_value_t*)dt;
  ;         dt = dt->super;
  ;     }
  ;     Return 0;
  ; }
  ; 
  ; STATIC_INLINE int jl_is_tuple_type(void *t)
  ; {
  ;     Return (jl_is_datatype(t) &&
  ;             ((jl_datatype_t*)(t))->name == jl_tuple_typename);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_vecelement_type(jl_value_t* t)
  ; {
  ;     Return (jl_is_datatype(t) &&
  ;             ((jl_datatype_t*)(t))->name == jl_vecelement_typename);
  ; }
  ; 
  ; STATIC_INLINE int jl_is_type_type(jl_value_t *v)
  ; {
  ;     Return (jl_is_datatype(v) &&
  ;             ((jl_datatype_t*)(v))->name == jl_type_type->name);
  ; }
  
  ; object identity
  PrototypeC.l jl_egal(*a.jl_value_t, *b.jl_value_t)
  PrototypeC.i jl_object_id(*v.jl_value_t)
  
  ; type predicates and basic operations
  PrototypeC.l jl_is_leaf_type(*v.jl_value_t)
  PrototypeC.l jl_has_typevars(*v.jl_value_t)
  PrototypeC.l jl_subtype(*a.jl_value_t, *b.jl_value_t, ta.l)
  PrototypeC.l jl_types_equal(*a.jl_value_t, *b.jl_value_t)
  PrototypeC.i jl_type_union(*typesjl_svec_t)                     ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_type_intersection(*a.jl_value_t, *b.jl_value_t) ; Returns *jl_value_t.jl_value_t
  PrototypeC.l jl_args_morespecific(*a.jl_value_t, *b.jl_value_t)
  PrototypeC.i jl_typename_str(*v.jl_value_t)                     ; Returns a pointer to a string
  PrototypeC.i jl_typeof_str(*v.jl_value_t)                       ; Returns a pointer to a string
  PrototypeC.l jl_type_morespecific(*a.jl_value_t, *b.jl_value_t)
  
  ; #ifdef NDEBUG
  ; STATIC_INLINE int jl_is_leaf_type_(jl_value_t *v)
  ; {
  ;     Return jl_is_datatype(v) && ((jl_datatype_t*)v)->isleaftype;
  ; }
  ; #define jl_is_leaf_type(v) jl_is_leaf_type_(v)
  ; #endif
  
  ; type constructors
  PrototypeC.i jl_new_typename(*name.jl_sym_t)								; Returns *jl_typename_t.jl_typename_t
  PrototypeC.i jl_new_typevar(*name.jl_sym_t,*lb.jl_value_t, *ub.jl_value_t)	; Returns *jl_tvar_t.jl_tvar_t
  PrototypeC.i jl_apply_type(*tc.jl_value_t, *params.jl_svec_t)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_apply_tuple_type(*params.jl_svec_t)							; Returns *jl_tupletype_t.jl_tupletype_t
  ; PrototypeC.i jl_apply_tuple_type_v(**p.jl_value_t, np.i)					; Returns *jl_tupletype_t.jl_tupletype_t
  PrototypeC.i jl_new_datatype(*name.jl_sym_t, *super.jl_datatype_t, *parameters.jl_svec_t, *fnames.jl_svec_t, *ftypes.jl_svec_t, abstract.l, mutabl.l, ninitialized.l)	; Returns *jl_datatype_t.jl_datatype_t
  PrototypeC.i jl_new_bitstype(*name.jl_value_t, *super.jl_datatype_t, *parameters.jl_svec_t, nbits.i)	; Returns *jl_datatype_t.jl_datatype_t
  
  ; constructors
  PrototypeC.i jl_new_bits(*bt.jl_value_t, *Data)								; Returns *jl_value_t.jl_value_t
  ; PrototypeC.i jl_new_struct(*type.jl_datatype_t, ...)						; Returns *jl_value_t.jl_value_t
  ; PrototypeC.i jl_new_structv(*type.jl_datatype_t, **args.jl_value_t, na.l)	; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_new_struct_uninit(*type.jl_datatype_t)						; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_new_lambda_info_uninit()									; Returns *jl_lambda_info_t.jl_lambda_info_t
  PrototypeC.i jl_new_lambda_info_from_ast(*ast.jl_expr_t)					; Returns *jl_lambda_info_t.jl_lambda_info_t
  ; PrototypeC.i jl_new_method(*definition.jl_lambda_info_t, *name.jl_sym_t, *sig.jl_tupletype_t, *tvars.jl_svec_t, isstaged.l)	; Returns *jl_method_t.jl_method_t
  ; PrototypeC.i jl_svec(n.i, ...)					; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_svec1(*a)							; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_svec2(*a, *b)						; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_alloc_svec(n.i)						; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_alloc_svec_uninit(n.i)				; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_svec_copy(*a.jl_svec_t)				; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_svec_fill(n.i, *x.jl_value_t)		; Returns *jl_svec_t.jl_svec_t
  PrototypeC.i jl_tupletype_fill(n.i, *v.jl_value_t)	; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_symbol(str.p-utf8)						; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_symbol_lookup(str.p-utf8)				; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_symbol_n(str.p-utf8, len.l)				; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_gensym()							; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_tagged_gensym(str.p-utf8, len.l)			; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_get_root_symbol()					; Returns *jl_sym_t.jl_sym_t
  ; PrototypeC.i jl_generic_function_def(*name.jl_sym_t, **bp.jl_value_t, *bp_owner.jl_value_t, *bnd.jl_binding_t)	; Returns *jl_value_t.jl_value_t
  ; PrototypeC   jl_method_def(*argdata.jl_svec_t, *f.jl_lambda_info_t, *isstaged.jl_value_t)
  PrototypeC.i jl_get_kwsorter(*tn.jl_typename_t)		; Returns *jl_function_t.jl_function_t
  PrototypeC.i jl_box_bool(x.b)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_int8(x.b)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_uint8(x.a)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_int16(x.w)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_uint16(x.u)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_int32(x.l)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_uint32(x.l)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_char(x.l)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_int64(x.q)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_uint64(x.q)					; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_float32(x.f)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_float64(x.d)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_voidpointer(*x)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_ssavalue(x.i)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box_slotnumber(x.i)				; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box8 (*t.jl_datatype_t, x.b)	; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box16(*t.jl_datatype_t, x.w)	; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box32(*t.jl_datatype_t, x.l)	; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_box64(*t.jl_datatype_t, x.q)	; Returns *jl_value_t.jl_value_t
  PrototypeC.b jl_unbox_bool(*v.jl_value_t)
  PrototypeC.b jl_unbox_int8(*v.jl_value_t)
  PrototypeC.a jl_unbox_uint8(*v.jl_value_t)
  PrototypeC.w jl_unbox_int16(*v.jl_value_t)
  PrototypeC.u jl_unbox_uint16(*v.jl_value_t)
  PrototypeC.l jl_unbox_int32(*v.jl_value_t)
  PrototypeC.l jl_unbox_uint32(*v.jl_value_t)
  PrototypeC.q jl_unbox_int64(*v.jl_value_t)
  PrototypeC.q jl_unbox_uint64(*v.jl_value_t)
  PrototypeC.f jl_unbox_float32(*v.jl_value_t)
  PrototypeC.d jl_unbox_float64(*v.jl_value_t)
  PrototypeC.i jl_unbox_voidpointer(*v.jl_value_t)
  
  PrototypeC.l jl_get_size(*val.jl_value_t, *pnt.Integer)
  
  If _JL_Library_ID
    Global jl_egal.jl_egal                               = GetFunction(_JL_Library_ID, "jl_egal")
    Global jl_object_id.jl_object_id                     = GetFunction(_JL_Library_ID, "jl_object_id")
    
    Global jl_is_leaf_type.jl_is_leaf_type               = GetFunction(_JL_Library_ID, "jl_is_leaf_type")
    Global jl_has_typevars.jl_has_typevars               = GetFunction(_JL_Library_ID, "jl_has_typevars")
    Global jl_subtype.jl_subtype                         = GetFunction(_JL_Library_ID, "jl_subtype")
    Global jl_types_equal.jl_types_equal                 = GetFunction(_JL_Library_ID, "jl_types_equal")
    Global jl_type_union.jl_type_union                   = GetFunction(_JL_Library_ID, "jl_type_union")
    Global jl_type_intersection.jl_type_intersection     = GetFunction(_JL_Library_ID, "jl_type_intersection")
    Global jl_args_morespecific.jl_args_morespecific     = GetFunction(_JL_Library_ID, "jl_args_morespecific")
    Global jl_typename_str.jl_typename_str               = GetFunction(_JL_Library_ID, "jl_typename_str")
    Global jl_typeof_str.jl_typeof_str                   = GetFunction(_JL_Library_ID, "jl_typeof_str")
    Global jl_type_morespecific.jl_type_morespecific     = GetFunction(_JL_Library_ID, "jl_type_morespecific")
  
    Global jl_new_typename.jl_new_typename               = GetFunction(_JL_Library_ID, "jl_new_typename")
    Global jl_new_typevar.jl_new_typevar                 = GetFunction(_JL_Library_ID, "jl_new_typevar")
    Global jl_apply_type.jl_apply_type                   = GetFunction(_JL_Library_ID, "jl_apply_type")
    Global jl_apply_tuple_type.jl_apply_tuple_type       = GetFunction(_JL_Library_ID, "jl_apply_tuple_type")
    ; Global jl_apply_tuple_type_v.jl_apply_tuple_type_v   = GetFunction(_JL_Library_ID, "jl_apply_tuple_type_v")
    Global jl_new_datatype.jl_new_datatype               = GetFunction(_JL_Library_ID, "jl_new_datatype")
    Global jl_new_bitstype.jl_new_bitstype               = GetFunction(_JL_Library_ID, "jl_new_bitstype")
  
    Global jl_new_bits.jl_new_bits                       = GetFunction(_JL_Library_ID, "jl_new_bits")
    ; Global jl_new_struct.jl_new_struct                   = GetFunction(_JL_Library_ID, "jl_new_struct")
    ; Global jl_new_structv.jl_new_structv                 = GetFunction(_JL_Library_ID, "jl_new_structv")
    Global jl_new_struct_uninit.jl_new_struct_uninit                 = GetFunction(_JL_Library_ID, "jl_new_struct_uninit")
    Global jl_new_lambda_info_uninit.jl_new_lambda_info_uninit       = GetFunction(_JL_Library_ID, "jl_new_lambda_info_uninit")
    Global jl_new_lambda_info_from_ast.jl_new_lambda_info_from_ast   = GetFunction(_JL_Library_ID, "jl_new_lambda_info_from_ast")
    ; Global jl_new_method.jl_new_method                               = GetFunction(_JL_Library_ID, "jl_new_method")
    ; Global jl_svec.jl_svec                               = GetFunction(_JL_Library_ID, "jl_svec")
    Global jl_svec1.jl_svec1                             = GetFunction(_JL_Library_ID, "jl_svec1")
    Global jl_svec2.jl_svec2                             = GetFunction(_JL_Library_ID, "jl_svec2")
    Global jl_alloc_svec.jl_alloc_svec                   = GetFunction(_JL_Library_ID, "jl_alloc_svec")
    Global jl_alloc_svec_uninit.jl_alloc_svec_uninit     = GetFunction(_JL_Library_ID, "jl_alloc_svec_uninit")
    Global jl_svec_copy.jl_svec_copy                     = GetFunction(_JL_Library_ID, "jl_svec_copy")
    Global jl_svec_fill.jl_svec_fill                     = GetFunction(_JL_Library_ID, "jl_svec_fill")
    Global jl_tupletype_fill.jl_tupletype_fill           = GetFunction(_JL_Library_ID, "jl_tupletype_fill")
    Global jl_symbol.jl_symbol                           = GetFunction(_JL_Library_ID, "jl_symbol")
    Global jl_symbol_lookup.jl_symbol_lookup             = GetFunction(_JL_Library_ID, "jl_symbol_lookup")
    Global jl_symbol_n.jl_symbol_n                       = GetFunction(_JL_Library_ID, "jl_symbol_n")
    Global jl_gensym.jl_gensym                           = GetFunction(_JL_Library_ID, "jl_gensym")
    Global jl_tagged_gensym.jl_tagged_gensym             = GetFunction(_JL_Library_ID, "jl_tagged_gensym")
    Global jl_get_root_symbol.jl_get_root_symbol                 = GetFunction(_JL_Library_ID, "jl_get_root_symbol")
    ; Global jl_generic_function_def.jl_generic_function_def       = GetFunction(_JL_Library_ID, "jl_generic_function_def")
  
    Global jl_get_kwsorter.jl_get_kwsorter               = GetFunction(_JL_Library_ID, "jl_get_kwsorter")
    Global jl_box_bool.jl_box_bool                       = GetFunction(_JL_Library_ID, "jl_box_bool")
    Global jl_box_int8.jl_box_int8                       = GetFunction(_JL_Library_ID, "jl_box_int8")
    Global jl_box_uint8.jl_box_uint8                     = GetFunction(_JL_Library_ID, "jl_box_uint8")
    Global jl_box_int16.jl_box_int16                     = GetFunction(_JL_Library_ID, "jl_box_int16")
    Global jl_box_uint16.jl_box_uint16                   = GetFunction(_JL_Library_ID, "jl_box_uint16")
    Global jl_box_int32.jl_box_int32                     = GetFunction(_JL_Library_ID, "jl_box_int32")
    Global jl_box_uint32.jl_box_uint32                   = GetFunction(_JL_Library_ID, "jl_box_uint32")
    Global jl_box_char.jl_box_char                       = GetFunction(_JL_Library_ID, "jl_box_char")
    Global jl_box_int64.jl_box_int64                     = GetFunction(_JL_Library_ID, "jl_box_int64")
    Global jl_box_uint64.jl_box_uint64                   = GetFunction(_JL_Library_ID, "jl_box_uint64")
    Global jl_box_float32.jl_box_float32                 = GetFunction(_JL_Library_ID, "jl_box_float32")
    Global jl_box_float64.jl_box_float64                 = GetFunction(_JL_Library_ID, "jl_box_float64")
    Global jl_box_voidpointer.jl_box_voidpointer         = GetFunction(_JL_Library_ID, "jl_box_voidpointer")
    Global jl_box_ssavalue.jl_box_ssavalue               = GetFunction(_JL_Library_ID, "jl_box_ssavalue")
    Global jl_box_slotnumber.jl_box_slotnumber           = GetFunction(_JL_Library_ID, "jl_box_slotnumber")
    Global jl_box8 .jl_box8                              = GetFunction(_JL_Library_ID, "jl_box8 ")
    Global jl_box16.jl_box16                             = GetFunction(_JL_Library_ID, "jl_box16")
    Global jl_box32.jl_box32                             = GetFunction(_JL_Library_ID, "jl_box32")
    Global jl_box64.jl_box64                             = GetFunction(_JL_Library_ID, "jl_box64")
    Global jl_unbox_bool.jl_unbox_bool                   = GetFunction(_JL_Library_ID, "jl_unbox_bool")
    Global jl_unbox_int8.jl_unbox_int8                   = GetFunction(_JL_Library_ID, "jl_unbox_int8")
    Global jl_unbox_uint8.jl_unbox_uint8                 = GetFunction(_JL_Library_ID, "jl_unbox_uint8")
    Global jl_unbox_int16.jl_unbox_int16                 = GetFunction(_JL_Library_ID, "jl_unbox_int16")
    Global jl_unbox_uint16.jl_unbox_uint16               = GetFunction(_JL_Library_ID, "jl_unbox_uint16")
    Global jl_unbox_int32.jl_unbox_int32                 = GetFunction(_JL_Library_ID, "jl_unbox_int32")
    Global jl_unbox_uint32.jl_unbox_uint32               = GetFunction(_JL_Library_ID, "jl_unbox_uint32")
    Global jl_unbox_int64.jl_unbox_int64                 = GetFunction(_JL_Library_ID, "jl_unbox_int64")
    Global jl_unbox_uint64.jl_unbox_uint64               = GetFunction(_JL_Library_ID, "jl_unbox_uint64")
    Global jl_unbox_float32.jl_unbox_float32             = GetFunction(_JL_Library_ID, "jl_unbox_float32")
    Global jl_unbox_float64.jl_unbox_float64             = GetFunction(_JL_Library_ID, "jl_unbox_float64")
    Global jl_unbox_voidpointer.jl_unbox_voidpointer     = GetFunction(_JL_Library_ID, "jl_unbox_voidpointer")
  
    Global jl_get_size.jl_get_size                       = GetFunction(_JL_Library_ID, "jl_get_size")
  EndIf
  
  ; #ifdef _P64
  ; #define jl_box_long(x)   jl_box_int64(x)
  ; #define jl_box_ulong(x)  jl_box_uint64(x)
  ; #define jl_unbox_long(x) jl_unbox_int64(x)
  ; #define jl_is_long(x)    jl_is_int64(x)
  ; #define jl_long_type     jl_int64_type
  ; #else
  ; #define jl_box_long(x)   jl_box_int32(x)
  ; #define jl_box_ulong(x)  jl_box_uint32(x)
  ; #define jl_unbox_long(x) jl_unbox_int32(x)
  ; #define jl_is_long(x)    jl_is_int32(x)
  ; #define jl_long_type     jl_int32_type
  ; #endif
  
  ; Each tuple can exist in one of 4 Vararg states:
  ;   NONE: no vararg                            Tuple{Int,Float32}
  ;   INT: vararg with integer length            Tuple{Int,Vararg{Float32,2}}
  ;   BOUND: vararg with bound TypeVar length    Tuple{Int,Vararg{Float32,N}}
  ;   UNBOUND: vararg with unbound length        Tuple{Int,Vararg{Float32}}
  Enumeration ; jl_vararg_kind_t
    #JL_VARARG_NONE    = 0
    #JL_VARARG_INT     = 1
    #JL_VARARG_BOUND   = 2
    #JL_VARARG_UNBOUND = 3
  EndEnumeration
  
  ; STATIC_INLINE int jl_is_vararg_type(jl_value_t *v)
  ; {
  ;     Return (jl_is_datatype(v) &&
  ;             ((jl_datatype_t*)(v))->name == jl_vararg_type->name);
  ; }
  ; 
  ; STATIC_INLINE jl_vararg_kind_t jl_vararg_kind(jl_value_t *v)
  ; {
  ;     If (!jl_is_vararg_type(v))
  ;         Return JL_VARARG_NONE;
  ;     jl_value_t *lenv = jl_tparam1(v);
  ;     If (jl_is_long(lenv))
  ;         Return JL_VARARG_INT;
  ;     If (jl_is_typevar(lenv))
  ;         Return ((jl_tvar_t*)lenv)->bound ? JL_VARARG_BOUND : JL_VARARG_UNBOUND;
  ;     Return JL_VARARG_UNBOUND;
  ; }
  ; 
  ; STATIC_INLINE int jl_is_va_tuple(jl_datatype_t *t)
  ; {
  ;     assert(jl_is_tuple_type(t));
  ;     size_t l = jl_svec_len(t->parameters);
  ;     Return (l>0 && jl_is_vararg_type(jl_tparam(t,l-1)));
  ; }
  ; 
  ; STATIC_INLINE jl_vararg_kind_t jl_va_tuple_kind(jl_datatype_t *t)
  ; {
  ;     assert(jl_is_tuple_type(t));
  ;     size_t l = jl_svec_len(t->parameters);
  ;     If (l == 0)
  ;         Return JL_VARARG_NONE;
  ;     Return jl_vararg_kind(jl_tparam(t,l-1));
  ; }
  
  ; structs
  PrototypeC.l jl_field_index(*t.jl_datatype_t, *fld.jl_sym_t, err.l)
  PrototypeC.i jl_get_nth_field(*v.jl_value_t, i.i)                           ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_get_nth_field_checked(*v.jl_value_t, i.i)                   ; Returns *jl_value_t.jl_value_t
  PrototypeC   jl_set_nth_field(*v.jl_value_t, i.i, *rhs.jl_value_t)
  PrototypeC.l jl_field_isdefined(*v.jl_value_t, i.i)
  PrototypeC   jl_get_field(*o.jl_value_t, fld.p-utf8)                     ; Returns *jl_value_t.jl_value_t
  PrototypeC   jl_value_ptr(*a.jl_value_t)                                    ; Returns *jl_value_t.jl_value_t
  
  ; arrays
  PrototypeC.i jl_new_array(*atype.jl_value_t, *dims.jl_value_t)                          ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_reshape_array(*atype.jl_value_t, *data.jl_array_t, *dims.jl_value_t)    ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_ptr_to_array_1d(*atype.jl_value_t, *data, nel.i, own_buffer.l)          ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_ptr_to_array(*atype.jl_value_t, *data, *dims.jl_value_t, own_buffer.l)  ; Returns *jl_array_t.jl_array_t
  
  PrototypeC.i jl_alloc_array_1d(*atype.jl_value_t, nr.i)                     ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_alloc_array_2d(*atype.jl_value_t, nr.i, nc.i)               ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_alloc_array_3d(*atype.jl_value_t, nr.i, nc.i, z.i)          ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_pchar_to_array(str.p-utf8, len.i)                        ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_pchar_to_string(str.p-utf8, len.i)                       ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_cstr_to_string(str.p-utf8)                               ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_array_to_string(*a.jl_array_t)                              ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_alloc_vec_any(n.i)                                          ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_arrayref(*a.jl_array_t, i.i)                                ; Returns *jl_value_t.jl_value_t  ; 0-indexed
  PrototypeC   jl_arrayset(*a.jl_array_t, *v.jl_value_t, i.i)                 ; 0-indexed
  PrototypeC   jl_arrayunset(*a.jl_array_t, i.i)                              ; 0-indexed
  PrototypeC   jl_array_grow_end(*a.jl_array_t, inc.i)
  PrototypeC   jl_array_del_end(*a.jl_array_t, dec.i)
  PrototypeC   jl_array_grow_beg(*a.jl_array_t, inc.i)
  PrototypeC   jl_array_del_beg(*a.jl_array_t, dec.i)
  PrototypeC   jl_array_sizehint(*a.jl_array_t, sz.i)
  PrototypeC   jl_array_ptr_1d_push(*a.jl_array_t, *item.jl_value_t)
  PrototypeC   jl_array_ptr_1d_push2(*a.jl_array_t, *b.jl_value_t, *c.jl_value_t)
  PrototypeC.i jl_apply_array_type(*type.jl_datatype_t, _dim.i)               ; Returns *jl_value_t.jl_value_t
  ; property access
  PrototypeC   jl_array_ptr(*a.jl_array_t)
  PrototypeC   jl_array_eltype(*a.jl_value_t)
  PrototypeC.l jl_array_rank(*a.jl_value_t)
  PrototypeC.i jl_array_size(*a.jl_value_t, d.l)
  
  ; strings
  PrototypeC.i jl_string_ptr(*s.jl_value_t)
  
  If _JL_Library_ID
    Global jl_field_index.jl_field_index                     = GetFunction(_JL_Library_ID, "jl_field_index")
    Global jl_get_nth_field.jl_get_nth_field                 = GetFunction(_JL_Library_ID, "jl_get_nth_field")
    Global jl_get_nth_field_checked.jl_get_nth_field_checked = GetFunction(_JL_Library_ID, "jl_get_nth_field_checked")
    Global jl_set_nth_field.jl_set_nth_field                 = GetFunction(_JL_Library_ID, "jl_set_nth_field")
    Global jl_field_isdefined.jl_field_isdefined             = GetFunction(_JL_Library_ID, "jl_field_isdefined")
    Global jl_get_field.jl_get_field                         = GetFunction(_JL_Library_ID, "jl_get_field")
    Global jl_value_ptr.jl_value_ptr                         = GetFunction(_JL_Library_ID, "jl_value_ptr")
    
    Global jl_new_array.jl_new_array                         = GetFunction(_JL_Library_ID, "jl_new_array")
    Global jl_reshape_array.jl_reshape_array                 = GetFunction(_JL_Library_ID, "jl_reshape_array")
    Global jl_ptr_to_array_1d.jl_ptr_to_array_1d             = GetFunction(_JL_Library_ID, "jl_ptr_to_array_1d")
    Global jl_ptr_to_array.jl_ptr_to_array                   = GetFunction(_JL_Library_ID, "jl_ptr_to_array")
    
    Global jl_alloc_array_1d.jl_alloc_array_1d               = GetFunction(_JL_Library_ID, "jl_alloc_array_1d")
    Global jl_alloc_array_2d.jl_alloc_array_2d               = GetFunction(_JL_Library_ID, "jl_alloc_array_2d")
    Global jl_alloc_array_3d.jl_alloc_array_3d               = GetFunction(_JL_Library_ID, "jl_alloc_array_3d")
    Global jl_pchar_to_array.jl_pchar_to_array               = GetFunction(_JL_Library_ID, "jl_pchar_to_array")
    Global jl_pchar_to_string.jl_pchar_to_string             = GetFunction(_JL_Library_ID, "jl_pchar_to_string")
    Global jl_cstr_to_string.jl_cstr_to_string               = GetFunction(_JL_Library_ID, "jl_cstr_to_string")
    Global jl_array_to_string.jl_array_to_string             = GetFunction(_JL_Library_ID, "jl_array_to_string")
    Global jl_alloc_vec_any.jl_alloc_vec_any                 = GetFunction(_JL_Library_ID, "jl_alloc_vec_any")
    Global jl_arrayref.jl_arrayref                           = GetFunction(_JL_Library_ID, "jl_arrayref")
    Global jl_arrayset.jl_arrayset                           = GetFunction(_JL_Library_ID, "jl_arrayset")
    Global jl_arrayunset.jl_arrayunset                       = GetFunction(_JL_Library_ID, "jl_arrayunset")
    Global jl_array_grow_end.jl_array_grow_end               = GetFunction(_JL_Library_ID, "jl_array_grow_end")
    Global jl_array_del_end.jl_array_del_end                 = GetFunction(_JL_Library_ID, "jl_array_del_end")
    Global jl_array_grow_beg.jl_array_grow_beg               = GetFunction(_JL_Library_ID, "jl_array_grow_beg")
    Global jl_array_del_beg.jl_array_del_beg                 = GetFunction(_JL_Library_ID, "jl_array_del_beg")
    Global jl_array_sizehint.jl_array_sizehint               = GetFunction(_JL_Library_ID, "jl_array_sizehint")
    Global jl_array_ptr_1d_push.jl_array_ptr_1d_push         = GetFunction(_JL_Library_ID, "jl_array_ptr_1d_push")
    Global jl_array_ptr_1d_push2.jl_array_ptr_1d_push2       = GetFunction(_JL_Library_ID, "jl_array_ptr_1d_push2")
    Global jl_apply_array_type.jl_apply_array_type           = GetFunction(_JL_Library_ID, "jl_apply_array_type")
    
    Global jl_array_ptr.jl_array_ptr                         = GetFunction(_JL_Library_ID, "jl_array_ptr")
    Global jl_array_eltype.jl_array_eltype                   = GetFunction(_JL_Library_ID, "jl_array_eltype")
    Global jl_array_rank.jl_array_rank                       = GetFunction(_JL_Library_ID, "jl_array_rank")
    Global jl_array_size.jl_array_size                       = GetFunction(_JL_Library_ID, "jl_array_size")
    
    Global jl_string_ptr.jl_string_ptr                       = GetFunction(_JL_Library_ID, "jl_string_ptr")
  EndIf
  
  ; modules and global variables
  If _JL_Library_ID
    Global *jl_main_module.jl_module_t_p             = GetFunction(_JL_Library_ID, "jl_main_module")
    Global *jl_internal_main_module.jl_module_t_p    = GetFunction(_JL_Library_ID, "jl_internal_main_module")
    Global *jl_core_module.jl_module_t_p             = GetFunction(_JL_Library_ID, "jl_core_module")
    Global *jl_base_module.jl_module_t_p             = GetFunction(_JL_Library_ID, "jl_base_module")
    Global *jl_top_module.jl_module_t_p              = GetFunction(_JL_Library_ID, "jl_top_module")
  EndIf
  PrototypeC.i jl_new_module(*name.jl_sym_t)                                  ; Returns *jl_module_t.jl_module_t
  ; get binding for reading
  PrototypeC.i jl_get_binding(*m.jl_module_t, *var.jl_sym_t)                  ; Returns *jl_binding_t.jl_binding_t
  PrototypeC.i jl_get_binding_or_error(*m.jl_module_t, *var.jl_sym_t)         ; Returns *jl_binding_t.jl_binding_t
  PrototypeC.i jl_module_globalref(*m.jl_module_t, *var.jl_sym_t)             ; Returns *jl_value_t.jl_value_t
  ; get binding for assignment
  PrototypeC.i jl_get_binding_wr(*m.jl_module_t, *var.jl_sym_t)               ; Returns *jl_binding_t.jl_binding_t
  PrototypeC.i jl_get_binding_for_method_def(*m.jl_module_t, *var.jl_sym_t)   ; Returns *jl_binding_t.jl_binding_t
  PrototypeC.l jl_boundp(*m.jl_module_t, *var.jl_sym_t)
  PrototypeC.l jl_defines_or_exports_p(*m.jl_module_t, *var.jl_sym_t)
  PrototypeC.l jl_binding_resolved_p(*m.jl_module_t, *var.jl_sym_t)
  PrototypeC.l jl_is_const(*m.jl_module_t, *var.jl_sym_t)
  PrototypeC.i jl_get_global(*m.jl_module_t, *var.jl_sym_t)                   ; Returns *jl_value_t.jl_value_t
  PrototypeC   jl_set_global(*m.jl_module_t, *var.jl_sym_t, *val.jl_value_t)
  PrototypeC   jl_set_const(*m.jl_module_t, *var.jl_sym_t, *val.jl_value_t)
  PrototypeC   jl_checked_assignment(*b.jl_binding_t, *rhs.jl_value_t)
  PrototypeC   jl_declare_constant(*b.jl_binding_t)
  PrototypeC   jl_module_using(*to.jl_module_t, *from.jl_module_t)
  PrototypeC   jl_module_use(*to,jl_module_t, *from.jl_module_t, *s.jl_sym_t)
  PrototypeC   jl_module_import(*to.jl_module_t, *from.jl_module_t, *s.jl_sym_t)
  PrototypeC   jl_module_importall(*to.jl_module_t, *from.jl_module_t)
  PrototypeC   jl_module_export(*from.jl_module_t, *s.jl_sym_t)
  PrototypeC.l jl_is_imported(*m.jl_module_t, *s.jl_sym_t)
  PrototypeC.i jl_new_main_module()                                           ; Returns *jl_module_t.jl_module_t
  PrototypeC   jl_add_standard_imports(*m.jl_module_t)
  Declare.i jl_get_function(*m.jl_module_t, name.s)
  PrototypeC.l jl_is_submodule(*child.jl_module_t, *parent.jl_module_t)
  
  ; eq hash tables
  PrototypeC.i jl_eqtable_put(*h.jl_array_t, *key, *val)                      ; Returns *jl_array_t.jl_array_t
  PrototypeC.i jl_eqtable_get(*h.jl_array_t, *key, *deflt.jl_value_t)         ; Returns *jl_array_t.jl_array_t
  
  ; system information
  PrototypeC.l jl_errno()
  PrototypeC   jl_set_errno(e.l)
  PrototypeC.l jl_stat(path.p-utf8, statbuf.p-utf8)
  PrototypeC.l jl_cpu_cores()
  PrototypeC.C_long jl_getpagesize()
  PrototypeC.C_long jl_getallocationgranularity()
  PrototypeC.l jl_is_debugbuild()
  PrototypeC.i jl_get_UNAME()                                                 ; Returns *jl_sym_t.jl_sym_t
  PrototypeC.i jl_get_ARCH()                                                  ; Returns *jl_sym_t.jl_sym_t
  
  ; environment entries
  PrototypeC.i jl_environ(i.l)                                                ; Returns *jl_value_t.jl_value_t
  
  ; throwing common exceptions
  PrototypeC   jl_error(str.p-utf8)
  ; PrototypeC   jl_errorf(fmt.p-utf8, ...)
  ; PrototypeC   jl_exceptionf(*ty.jl_datatype_t, fmt.p-utf8, ...);
  PrototypeC   jl_too_few_args(fname.p-utf8, min.l);
  PrototypeC   jl_too_many_args(fname.p-utf8, max.l);
  PrototypeC   jl_type_error(fname.p-utf8, *expected.jl_value_t, *got.jl_value_t)
  PrototypeC   jl_type_error_rt(fname.p-utf8, context.p-utf8, *ty.jl_value_t, *got.jl_value_t)
  PrototypeC   jl_undefined_var_error(*var.jl_sym_t)
  PrototypeC   jl_bounds_error(*v.jl_value_t, *t.jl_value_t)
  ; PrototypeC   jl_bounds_error_v(*v.jl_value_t, **idxs.jl_value_t, nidxs.i)
  PrototypeC   jl_bounds_error_int(*v.jl_value_t, i.i)
  ; PrototypeC   jl_bounds_error_tuple_int(**v.jl_value_t, nv.i, i.i)
  PrototypeC   jl_bounds_error_unboxed_int(*v, *vt.jl_value_t, i.i)
  PrototypeC   jl_bounds_error_ints(*v.jl_value_t, *idxs.Integer, nidxs.i)
  PrototypeC   jl_eof_error()
  PrototypeC.i jl_exception_occurred()                                        ; Returns *jl_value_t.jl_value_t
  PrototypeC   jl_exception_clear()
  
  ; #define JL_NARGS(fname, min, max)                               \
  ;     If (nargs < min) jl_too_few_args(#fname, min);              \
  ;     Else If (nargs > max) jl_too_many_args(#fname, max);
  ; 
  ; #define JL_NARGSV(fname, min)                           \
  ;     If (nargs < min) jl_too_few_args(#fname, min);
  ; 
  ; #define JL_TYPECHK(fname, type, v)                                      \
  ;     If (!jl_is_##type(v)) {                                             \
  ;         jl_type_error(#fname, (jl_value_t*)jl_##type##_type, (v));      \
  ;     }
  ; #define JL_TYPECHKS(fname, type, v)                                     \
  ;     If (!jl_is_##type(v)) {                                             \
  ;         jl_type_error(fname, (jl_value_t*)jl_##type##_type, (v));       \
  ;     }
  
  If _JL_Library_ID
    Global jl_new_module.jl_new_module                                   = GetFunction(_JL_Library_ID, "jl_new_module")
    
    Global jl_get_binding.jl_get_binding                                 = GetFunction(_JL_Library_ID, "jl_get_binding")
    Global jl_get_binding_or_error.jl_get_binding_or_error               = GetFunction(_JL_Library_ID, "jl_get_binding_or_error")
    Global jl_module_globalref.jl_module_globalref                       = GetFunction(_JL_Library_ID, "jl_module_globalref")
    
    Global jl_get_binding_wr.jl_get_binding_wr                           = GetFunction(_JL_Library_ID, "jl_get_binding_wr")
    Global jl_get_binding_for_method_def.jl_get_binding_for_method_def   = GetFunction(_JL_Library_ID, "jl_get_binding_for_method_def")
    Global jl_boundp.jl_boundp                                           = GetFunction(_JL_Library_ID, "jl_boundp")
    Global jl_defines_or_exports_p.jl_defines_or_exports_p               = GetFunction(_JL_Library_ID, "jl_defines_or_exports_p")
    Global jl_binding_resolved_p.jl_binding_resolved_p                   = GetFunction(_JL_Library_ID, "jl_binding_resolved_p")
    Global jl_is_const.jl_is_const                                       = GetFunction(_JL_Library_ID, "jl_is_const")
    Global jl_get_global.jl_get_global                                   = GetFunction(_JL_Library_ID, "jl_get_global")
    Global jl_set_global.jl_set_global                                   = GetFunction(_JL_Library_ID, "jl_set_global")
    Global jl_set_const.jl_set_const                                     = GetFunction(_JL_Library_ID, "jl_set_const")
    Global jl_checked_assignment.jl_checked_assignment                   = GetFunction(_JL_Library_ID, "jl_checked_assignment")
    Global jl_declare_constant.jl_declare_constant                       = GetFunction(_JL_Library_ID, "jl_declare_constant")
    Global jl_module_using.jl_module_using                               = GetFunction(_JL_Library_ID, "jl_module_using")
    Global jl_module_use.jl_module_use                                   = GetFunction(_JL_Library_ID, "jl_module_use")
    Global jl_module_import.jl_module_import                             = GetFunction(_JL_Library_ID, "jl_module_import")
    Global jl_module_importall.jl_module_importall                       = GetFunction(_JL_Library_ID, "jl_module_importall")
    Global jl_module_export.jl_module_export                             = GetFunction(_JL_Library_ID, "jl_module_export")
    Global jl_is_imported.jl_is_imported                                 = GetFunction(_JL_Library_ID, "jl_is_imported")
    Global jl_new_main_module.jl_new_main_module                         = GetFunction(_JL_Library_ID, "jl_new_main_module")
    Global jl_add_standard_imports.jl_add_standard_imports               = GetFunction(_JL_Library_ID, "jl_add_standard_imports")
    Global jl_is_submodule.jl_is_submodule                               = GetFunction(_JL_Library_ID, "jl_is_submodule")
    
    Global jl_eqtable_put.jl_eqtable_put                                 = GetFunction(_JL_Library_ID, "jl_eqtable_put")
    Global jl_eqtable_get.jl_eqtable_get                                 = GetFunction(_JL_Library_ID, "jl_eqtable_get")
    
    Global jl_errno.jl_errno                                             = GetFunction(_JL_Library_ID, "jl_errno")
    Global jl_set_errno.jl_set_errno                                     = GetFunction(_JL_Library_ID, "jl_set_errno")
    Global jl_stat.jl_stat                                               = GetFunction(_JL_Library_ID, "jl_stat")
    Global jl_cpu_cores.jl_cpu_cores                                     = GetFunction(_JL_Library_ID, "jl_cpu_cores")
    Global jl_getpagesize.jl_getpagesize                                 = GetFunction(_JL_Library_ID, "jl_getpagesize")
    Global jl_getallocationgranularity.jl_getallocationgranularity       = GetFunction(_JL_Library_ID, "jl_getallocationgranularity")
    Global jl_is_debugbuild.jl_is_debugbuild                             = GetFunction(_JL_Library_ID, "jl_is_debugbuild")
    Global jl_get_UNAME.jl_get_UNAME                                     = GetFunction(_JL_Library_ID, "jl_get_UNAME")
    Global jl_get_ARCH.jl_get_ARCH                                       = GetFunction(_JL_Library_ID, "jl_get_ARCH")
    
    Global jl_environ.jl_environ                                         = GetFunction(_JL_Library_ID, "jl_environ")
    
    Global jl_error.jl_error                                             = GetFunction(_JL_Library_ID, "jl_error")
    ; Global jl_errorf.jl_errorf                                           = GetFunction(_JL_Library_ID, "jl_errorf")
    ; Global jl_exceptionf.jl_exceptionf                                   = GetFunction(_JL_Library_ID, "jl_exceptionf")
    Global jl_too_few_args.jl_too_few_args                               = GetFunction(_JL_Library_ID, "jl_too_few_args")
    Global jl_too_many_args.jl_too_many_args                             = GetFunction(_JL_Library_ID, "jl_too_many_args")
    Global jl_type_error.jl_type_error                                   = GetFunction(_JL_Library_ID, "jl_type_error")
    Global jl_type_error_rt.jl_type_error_rt                             = GetFunction(_JL_Library_ID, "jl_type_error_rt")
    Global jl_undefined_var_error.jl_undefined_var_error                 = GetFunction(_JL_Library_ID, "jl_undefined_var_error")
    Global jl_bounds_error.jl_bounds_error                               = GetFunction(_JL_Library_ID, "jl_bounds_error")
    ; Global jl_bounds_error_v.jl_bounds_error_v                           = GetFunction(_JL_Library_ID, "jl_bounds_error_v")
    Global jl_bounds_error_int.jl_bounds_error_int                       = GetFunction(_JL_Library_ID, "jl_bounds_error_int")
    ; Global jl_bounds_error_tuple_int.jl_bounds_error_tuple_int           = GetFunction(_JL_Library_ID, "jl_bounds_error_tuple_int")
    Global jl_bounds_error_unboxed_int.jl_bounds_error_unboxed_int       = GetFunction(_JL_Library_ID, "jl_bounds_error_unboxed_int")
    Global jl_bounds_error_ints.jl_bounds_error_ints                     = GetFunction(_JL_Library_ID, "jl_bounds_error_ints")
    Global jl_eof_error.jl_eof_error                                     = GetFunction(_JL_Library_ID, "jl_eof_error")
    Global jl_exception_occurred.jl_exception_occurred                   = GetFunction(_JL_Library_ID, "jl_exception_occurred")
    Global jl_exception_clear.jl_exception_clear                         = GetFunction(_JL_Library_ID, "jl_exception_clear")
  EndIf
  
  ; initialization functions
  Enumeration ; JL_IMAGE_SEARCH
    #JL_IMAGE_CWD = 0
    #JL_IMAGE_JULIA_HOME = 1
    ;#JL_IMAGE_LIBJULIA = 2
  EndEnumeration
  PrototypeC   julia_init(rel)                                              ; rel is from enumeration JL_IMAGE_SEARCH
  PrototypeC   jl_init(*julia_home_dir) ; jl_init(julia_home_dir.p-utf8)
  PrototypeC   jl_init_with_image(*julia_home_dir, *image_relative_path) ; jl_init_with_image(julia_home_dir.p-utf8, image_relative_path.p-utf8)
  PrototypeC.l jl_is_initialized()
  PrototypeC   jl_atexit_hook(status.l)
  PrototypeC   jl_exit(status.l)
  
  ; PrototypeC.l jl_deserialize_verify_header(*s.ios_t) ; TODO: Add ios_t structure
  PrototypeC   jl_preload_sysimg_so(fname.p-utf8)
  PrototypeC.i jl_create_system_image()                                     ; Returns *ios_t.ios_t
  PrototypeC   jl_save_system_image(fname.p-utf8)
  PrototypeC   jl_restore_system_image(fname.p-utf8)
  PrototypeC   jl_restore_system_image_data(buf.p-utf8, len.i)
  PrototypeC.l jl_save_incremental(fname.p-utf8, *worklist.jl_array_t)
  PrototypeC.i jl_restore_incremental(fname.p-utf8)                      ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_restore_incremental_from_buf(buf.p-utf8, sz.i)         ; Returns *jl_value_t.jl_value_t
  
  ; front end interface
  PrototypeC.i jl_parse_input_line(str.p-utf8, len.i, filename.p-utf8, filename_len.i)  ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_parse_string(str.p-utf8, len.i, pos0.l, greedy.l)      ; Returns *jl_value_t.jl_value_t
  PrototypeC.l jl_parse_depwarn(warn.l)
  PrototypeC.i jl_load_file_string(text.p-utf8, len.i, *filename)        ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_expand(*expr.jl_value_t)                                  ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_eval_string(str.p-utf8)                                ; Returns *jl_value_t.jl_value_t
  
  If _JL_Library_ID
    Global julia_init.julia_init                                             = GetFunction(_JL_Library_ID, "julia_init")
    Global jl_init.jl_init                                                   = GetFunction(_JL_Library_ID, "jl_init")
    Global jl_init_with_image.jl_init_with_image                             = GetFunction(_JL_Library_ID, "jl_init_with_image")
    Global jl_is_initialized.jl_is_initialized                               = GetFunction(_JL_Library_ID, "jl_is_initialized")
    Global jl_atexit_hook.jl_atexit_hook                                     = GetFunction(_JL_Library_ID, "jl_atexit_hook")
    Global jl_exit.jl_exit                                                   = GetFunction(_JL_Library_ID, "jl_exit")
    
    ; Global jl_deserialize_verify_header.jl_deserialize_verify_header         = GetFunction(_JL_Library_ID, "jl_deserialize_verify_header")
    Global jl_preload_sysimg_so.jl_preload_sysimg_so                         = GetFunction(_JL_Library_ID, "jl_preload_sysimg_so")
    Global jl_create_system_image.jl_create_system_image                     = GetFunction(_JL_Library_ID, "jl_create_system_image")
    Global jl_save_system_image.jl_save_system_image                         = GetFunction(_JL_Library_ID, "jl_save_system_image")
    Global jl_restore_system_image.jl_restore_system_image                   = GetFunction(_JL_Library_ID, "jl_restore_system_image")
    Global jl_restore_system_image_data.jl_restore_system_image_data         = GetFunction(_JL_Library_ID, "jl_restore_system_image_data")
    Global jl_save_incremental.jl_save_incremental                           = GetFunction(_JL_Library_ID, "jl_save_incremental")
    Global jl_restore_incremental.jl_restore_incremental                     = GetFunction(_JL_Library_ID, "jl_restore_incremental")
    Global jl_restore_incremental_from_buf.jl_restore_incremental_from_buf   = GetFunction(_JL_Library_ID, "jl_restore_incremental_from_buf")
    
    Global jl_parse_input_line.jl_parse_input_line                           = GetFunction(_JL_Library_ID, "jl_parse_input_line")
    Global jl_parse_string.jl_parse_string                                   = GetFunction(_JL_Library_ID, "jl_parse_string")
    Global jl_parse_depwarn.jl_parse_depwarn                                 = GetFunction(_JL_Library_ID, "jl_parse_depwarn")
    Global jl_load_file_string.jl_load_file_string                           = GetFunction(_JL_Library_ID, "jl_load_file_string")
    Global jl_expand.jl_expand                                               = GetFunction(_JL_Library_ID, "jl_expand")
    Global jl_eval_string.jl_eval_string                                     = GetFunction(_JL_Library_ID, "jl_eval_string")
  EndIf
  
  ; external libraries
  Enumeration ; JL_RTLD_CONSTANT
    #JL_RTLD_LOCAL    = 1
    #JL_RTLD_GLOBAL   = 2
    #JL_RTLD_LAZY     = 4
    #JL_RTLD_NOW      = 8
    ; Linux/glibc And MacOS X:
    #JL_RTLD_NODELETE = 16
    #JL_RTLD_NOLOAD   = 32
    ; Linux/glibc:
    #JL_RTLD_DEEPBIND = 64
    ; MacOS X 10.5+:
    #JL_RTLD_FIRST    = 128
  EndEnumeration
  #JL_RTLD_DEFAULT = #JL_RTLD_LAZY | #JL_RTLD_DEEPBIND
  
  Structure jl_uv_libhandle ; compatible with dlopen (void*) / LoadLibrary (HMODULE)
  EndStructure
  PrototypeC.i jl_load_dynamic_library(fname.p-utf8, flags)              ; Returns *jl_uv_libhandle.jl_uv_libhandle
  PrototypeC.i jl_load_dynamic_library_e(fname.p-utf8, flags)
  PrototypeC.i jl_dlopen(filename.p-utf8, flags)
  PrototypeC.l jl_dlclose(*handle.jl_uv_libhandle)
  PrototypeC.i jl_dlsym_e(*handle.jl_uv_libhandle, symbol.p-utf8)
  PrototypeC.i jl_dlsym(*handle.jl_uv_libhandle, symbol.p-utf8)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  PrototypeC.i jl_lookup_soname(pfx.p-utf8, n.i)                         ; Returns pointer to a string
  CompilerEndIf
  
  ; compiler
  PrototypeC.i jl_toplevel_eval(*v.jl_value_t)                              ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_toplevel_eval_in(*m.jl_module_t, *ex.jl_value_t)          ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_load(fname.p-utf8)                                     ; Returns *jl_value_t.jl_value_t
  ; PrototypeC.i jl_interpret_toplevel_expr_in(*m.jl_module_t, *e.jl_value_t, *lam.jl_lambda_info_t)  ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_base_relative_to(*m.jl_module_t)                          ; Returns *jl_module_t.jl_module_t
  
  ; tracing
  ; PrototypeC   jl_callback_lambda_info_t(*tracee.jl_lambda_info_t)
  PrototypeC   jl_callback_method_t(*tracee.jl_method_t)
  
  PrototypeC   jl_trace_method(*m.jl_method_t)
  PrototypeC   jl_untrace_method(*m.jl_method_t)
  ; PrototypeC   jl_trace_linfo(*linfo.jl_lambda_info_t)
  ; PrototypeC   jl_untrace_linfo(*linfo.jl_lambda_info_t)
  ; PrototypeC   jl_register_linfo_tracer(*callback.jl_callback_lambda_info_t)
  ; PrototypeC   jl_register_method_tracer(*callback.jl_callback_lambda_info_t)
  ; PrototypeC   jl_register_newmeth_tracer(*callback.jl_callback_method_t)
  
  ; AST access
  PrototypeC.l jl_is_rest_arg(*ex.jl_value_t)
  
  PrototypeC.i jl_copy_ast(*expr.jl_value_t)                                ; Returns *jl_value_t.jl_value_t
  
  ; PrototypeC.i jl_compress_ast(*li.jl_lambda_info_t, *ast.jl_array_t)       ; Returns *jl_array_t.jl_array_t
  ; PrototypeC.i jl_uncompress_ast(*li.jl_lambda_info_t, *data.jl_array_t)    ; Returns *jl_array_t.jl_array_t
  
  PrototypeC.l jl_is_operator(sym.p-utf8)
  PrototypeC.l jl_operator_precedence(sym.p-utf8)
  
  Declare.l jl_vinfo_sa(vi.a)
  
  Declare.l jl_vinfo_usedundef(vi.a)
  
  If _JL_Library_ID
    Global jl_load_dynamic_library.jl_load_dynamic_library               = GetFunction(_JL_Library_ID, "jl_load_dynamic_library")
    Global jl_load_dynamic_library_e.jl_load_dynamic_library_e           = GetFunction(_JL_Library_ID, "jl_load_dynamic_library_e")
    Global jl_dlopen.jl_dlopen                                           = GetFunction(_JL_Library_ID, "jl_dlopen")
    Global jl_dlclose.jl_dlclose                                         = GetFunction(_JL_Library_ID, "jl_dlclose")
    Global jl_dlsym_e.jl_dlsym_e                                         = GetFunction(_JL_Library_ID, "jl_dlsym_e")
    Global jl_dlsym.jl_dlsym                                             = GetFunction(_JL_Library_ID, "jl_dlsym")
    
    ; Global jl_lookup_soname.jl_lookup_soname                             = GetFunction(_JL_Library_ID, "jl_lookup_soname")
    
    Global jl_toplevel_eval.jl_toplevel_eval                             = GetFunction(_JL_Library_ID, "jl_toplevel_eval")
    Global jl_toplevel_eval_in.jl_toplevel_eval_in                       = GetFunction(_JL_Library_ID, "jl_toplevel_eval_in")
    Global jl_load.jl_load                                               = GetFunction(_JL_Library_ID, "jl_load")
    ; Global jl_interpret_toplevel_expr_in.jl_interpret_toplevel_expr_in   = GetFunction(_JL_Library_ID, "jl_interpret_toplevel_expr_in")
    Global jl_base_relative_to.jl_base_relative_to                       = GetFunction(_JL_Library_ID, "jl_base_relative_to")
    
    ; Global jl_callback_lambda_info_t.jl_callback_lambda_info_t           = GetFunction(_JL_Library_ID, "jl_callback_lambda_info_t")
    Global jl_callback_method_t.jl_callback_method_t                     = GetFunction(_JL_Library_ID, "jl_callback_method_t")
    
    Global jl_trace_method.jl_trace_method                               = GetFunction(_JL_Library_ID, "jl_trace_method")
    Global jl_untrace_method.jl_untrace_method                           = GetFunction(_JL_Library_ID, "jl_untrace_method")
    ; Global jl_trace_linfo.jl_trace_linfo                                 = GetFunction(_JL_Library_ID, "jl_trace_linfo")
    ; Global jl_untrace_linfo.jl_untrace_linfo                             = GetFunction(_JL_Library_ID, "jl_untrace_linfo")
    ; Global jl_register_linfo_tracer.jl_register_linfo_tracer             = GetFunction(_JL_Library_ID, "jl_register_linfo_tracer")
    ; Global jl_register_method_tracer.jl_register_method_tracer           = GetFunction(_JL_Library_ID, "jl_register_method_tracer")
    ; Global jl_register_newmeth_tracer.jl_register_newmeth_tracer         = GetFunction(_JL_Library_ID, "jl_register_newmeth_tracer")
    
    Global jl_is_rest_arg.jl_is_rest_arg                                 = GetFunction(_JL_Library_ID, "jl_is_rest_arg")
    
    Global jl_copy_ast.jl_copy_ast                                       = GetFunction(_JL_Library_ID, "jl_copy_ast")
    
    ; Global jl_compress_ast.jl_compress_ast                               = GetFunction(_JL_Library_ID, "jl_compress_ast")
    ; Global jl_uncompress_ast.jl_uncompress_ast                           = GetFunction(_JL_Library_ID, "jl_uncompress_ast")
    
    Global jl_is_operator.jl_is_operator                                 = GetFunction(_JL_Library_ID, "jl_is_operator")
    Global jl_operator_precedence.jl_operator_precedence                 = GetFunction(_JL_Library_ID, "jl_operator_precedence")
  EndIf
  
  ;- calling into julia ---------------------------------------------------------
  
  ; PrototypeC.i jl_apply_generic(**args.jl_value_t, nargs.l)                 ; Returns *jl_value_t.jl_value_t
  ; PrototypeC.i jl_invoke(*meth.jl_lambda_info_t, **args.jl_value_t, nargs.l); Returns *jl_value_t.jl_value_t
  
  ; Procedure.i jl_apply(**args.jl_value_t, nargs.l)                           ; Returns *jl_value_t.jl_value_t
  ;   ProcedureReturn jl_apply_generic(args, nargs)
  ; EndProcedure
  
  Structure jl_value_t_array
    *value.jl_value_t[0]
  EndStructure
  
  PrototypeC.i jl_call(*f.jl_function_t, *args.jl_value_t_array, nargs.l)               ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_call0(*f.jl_function_t)                                               ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_call1(*f.jl_function_t, *a.jl_value_t)                                ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_call2(*f.jl_function_t, *a.jl_value_t, *b.jl_value_t)                 ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_call3(*f.jl_function_t, *a.jl_value_t, *b.jl_value_t, *c.jl_value_t)  ; Returns *jl_value_t.jl_value_t
  
  ; interfacing with Task runtime
  PrototypeC   jl_yield()
  
  ;- async signal handling ------------------------------------------------------
  
  PrototypeC   jl_install_sigint_handler()
  PrototypeC   jl_sigatomic_begin()
  PrototypeC   jl_sigatomic_end()
  
  If _JL_Library_ID
    Global jl_call.jl_call                                     = GetFunction(_JL_Library_ID, "jl_call")
    Global jl_call0.jl_call0                                   = GetFunction(_JL_Library_ID, "jl_call0")
    Global jl_call1.jl_call1                                   = GetFunction(_JL_Library_ID, "jl_call1")
    Global jl_call2.jl_call2                                   = GetFunction(_JL_Library_ID, "jl_call2")
    Global jl_call3.jl_call3                                   = GetFunction(_JL_Library_ID, "jl_call3")
    
    Global jl_yield.jl_yield                                   = GetFunction(_JL_Library_ID, "jl_yield")
    
    Global jl_install_sigint_handler.jl_install_sigint_handler = GetFunction(_JL_Library_ID, "jl_install_sigint_handler")
    Global jl_sigatomic_begin.jl_sigatomic_begin               = GetFunction(_JL_Library_ID, "jl_sigatomic_begin")
    Global jl_sigatomic_end.jl_sigatomic_end                   = GetFunction(_JL_Library_ID, "jl_sigatomic_end")
  EndIf
  
  ;- tasks and exceptions -------------------------------------------------------
  
  Macro _jl_timing_block_t : jl_timing_block_t : EndMacro
  ; info describing an exception handler
  Structure jl_handler_t
;     eh_ctx.jl_jmp_buf ; TODO: Add structure jl_jmp_buf
;     *gcstack.jl_gcframe_t
;     *prev.jl_handler_t
;     gc_state.b
;     CompilerIf Defined(JULIA_ENABLE_THREADING, #PB_Constant)
;     locks_len.i
;     CompilerEndIf
;     defer_signal.sig_atomic_t
;     finalizers_inhibited.l
;     *timing_stack.jl_timing_block_t
  EndStructure
  
  Structure jl_task_t
;     JL_DATA_TYPE
;     *parent.jl_task_t
;     *tls.jl_value_t
;     *state.jl_sym_t
;     *consumersjl_value_t
;     *donenotifyjl_value_t
;     *resultjl_value_t
;     *exceptionjl_value_t
;     *backtracejl_value_t
;     *start.jl_function_t
;     ctx.jl_jmp_buf
;     bufsz.i
;     *stkbuf
;     
;     ssize.i
;     started.i   ; First bit
;     
;     ; current exception handler
;     *eh.jl_handler_t
;     ; saved gc stack top for context switches
;     *gcstack.jl_gcframe_t
;     ; current module, or NULL if this task has not set one
;     *current_module.jl_module_t
;     
;     ; id of owning thread
;     ; does not need to be defined until the task runs
;     tid.w
;     CompilerIf Defined(JULIA_ENABLE_THREADING, #PB_Constant)
;     ; This is statically initialized when the task is not holding any locks
;     locks.arraylist_t
;     CompilerEndIf
;     *timing_stack.jl_timing_block_t
  EndStructure
  
  PrototypeC.i jl_new_task(*start.jl_function_t, ssize.i)                   ; Returns *jl_task_t.jl_task_t
  PrototypeC.i jl_switchto(*t.jl_task_t, *arg.jl_value_t)                   ; Returns *jl_value_t.jl_value_t
  PrototypeC   jl_throw(*e.jl_value_t)
  PrototypeC   jl_rethrow()
  PrototypeC   jl_rethrow_other(*e.jl_value_t)
  
  If _JL_Library_ID
    Global jl_new_task.jl_new_task               = GetFunction(_JL_Library_ID, "jl_new_task")
    Global jl_switchto.jl_switchto               = GetFunction(_JL_Library_ID, "jl_switchto")
    Global jl_throw.jl_throw                     = GetFunction(_JL_Library_ID, "jl_throw")
    Global jl_rethrow.jl_rethrow                 = GetFunction(_JL_Library_ID, "jl_rethrow")
    Global jl_rethrow_other.jl_rethrow_other     = GetFunction(_JL_Library_ID, "jl_rethrow_other")
  EndIf
  
  CompilerIf Defined(JULIA_ENABLE_THREADING, #PB_Constant)
  ; Declare jl_lock_frame_push(*lock.jl_mutex_t)
  
  ; Declare jl_lock_frame_pop()
  CompilerElse
  ; Declare jl_lock_frame_push(*lock.jl_mutex_t)
  ; Declare jl_lock_frame_pop()
  CompilerEndIf
  
  ; Declare jl_eh_restore_state(*eh.jl_handler_t)
  
  PrototypeC   jl_enter_handler(*eh.jl_handler_t)
  PrototypeC   jl_pop_handler(n.l)
  
  If _JL_Library_ID
    Global jl_enter_handler.jl_enter_handler   = GetFunction(_JL_Library_ID, "jl_enter_handler")
    Global jl_pop_handler.jl_pop_handler       = GetFunction(_JL_Library_ID, "jl_pop_handler")
  EndIf
  
  ; #if Defined(_OS_WINDOWS_)
  ; #if Defined(_COMPILER_MINGW_)
  ; int __attribute__ ((__nothrow__,__returns_twice__)) jl_setjmp(jmp_buf _Buf);
  ; __declspec(noreturn) __attribute__ ((__nothrow__)) void jl_longjmp(jmp_buf _Buf,int _Value);
  ; #else
  ; int jl_setjmp(jmp_buf _Buf);
  ; void jl_longjmp(jmp_buf _Buf,int _Value);
  ; #endif
  ; #define jl_setjmp_f jl_setjmp
  ; #define jl_setjmp_name "jl_setjmp"
  ; #define jl_setjmp(a,b) jl_setjmp(a)
  ; #define jl_longjmp(a,b) jl_longjmp(a,b)
  ; #else
  ; ; determine actual entry point name
  ; #if Defined(sigsetjmp)
  ; #define jl_setjmp_f    __sigsetjmp
  ; #define jl_setjmp_name "__sigsetjmp"
  ; #else
  ; #define jl_setjmp_f    sigsetjmp
  ; #define jl_setjmp_name "sigsetjmp"
  ; #endif
  ; #define jl_setjmp(a,b) sigsetjmp(a,b)
  ; #define jl_longjmp(a,b) siglongjmp(a,b)
  ; #endif
  
  ; #define JL_TRY                                                    \
  ;     int i__tr, i__ca; jl_handler_t __eh;                          \
  ;     jl_enter_handler(&__eh);                                      \
  ;     If (!jl_setjmp(__eh.eh_ctx,0))                                \
  ;         For (i__tr=1; i__tr; i__tr=0, jl_eh_restore_state(&__eh))
  ; 
  ; #define JL_EH_POP() jl_eh_restore_state(&__eh)
  ; 
  ; #ifdef _OS_WINDOWS_
  ; #define JL_CATCH                                                \
  ;     Else                                                        \
  ;         For (i__ca=1, jl_eh_restore_state(&__eh); i__ca; i__ca=0) \
  ;             If (((jl_get_ptls_states()->exception_in_transit==jl_stackovf_exception) && _resetstkoflw()) || 1)
  ; #else
  ; #define JL_CATCH                                                \
  ;     Else                                                        \
  ;         For (i__ca=1, jl_eh_restore_state(&__eh); i__ca; i__ca=0)
  ; #endif
  
  ;- I/O system -----------------------------------------------------------------
  
  Macro JL_STREAM : uv_stream_t   : EndMacro ; TODO: Add uv_stream_t structure
  Macro JL_STDOUT : jl_uv_stdout  : EndMacro
  Macro JL_STDERR : jl_uv_stderr  : EndMacro
  Macro JL_STDIN  : jl_uv_stdin   : EndMacro
  
  ; PrototypeC   jl_run_event_loop(*loop.uv_loop_t) ; TODO: Add uv_loop_t structure
  ; PrototypeC.l jl_run_once(*loop.uv_loop_t)
  ; PrototypeC.l jl_process_events(*loop.uv_loop_t)
  
  PrototypeC.i jl_global_event_loop()                                       ; Returns *uv_loop_t.uv_loop_t
  
  ; PrototypeC   jl_close_uv(*handle.uv_handle_t) ; TODO: Add uv_handle_t structure
  
  ; PrototypeC.l jl_tcp_bind(*handle.uv_tcp_t, port.u, host.l, flags.l) ; TODO: Add uv_tcp_t structure
  
  PrototypeC.l jl_sizeof_ios_t()
  
  ; PrototypeC.i jl_takebuf_array(*s.ios_t)                                   ; Returns *jl_array_t.jl_array_t
  ; PrototypeC.i jl_takebuf_string(*s.ios_t)                                  ; Returns *jl_value_t.jl_value_t
  ; PrototypeC.i jl_takebuf_raw(*s.ios_t)
  ; PrototypeC.i jl_readuntil(*s.ios_t, delim.a)                              ; Returns *jl_value_t.jl_value_t
  
  If _JL_Library_ID
    ; Global jl_run_event_loop.jl_run_event_loop         = GetFunction(_JL_Library_ID, "jl_run_event_loop")
    ; Global jl_run_once.jl_run_once                     = GetFunction(_JL_Library_ID, "jl_run_once")
    ; Global jl_process_events.jl_process_events         = GetFunction(_JL_Library_ID, "jl_process_events")
    
    Global jl_global_event_loop.jl_global_event_loop   = GetFunction(_JL_Library_ID, "jl_global_event_loop")
    
    ; Global jl_close_uv.jl_close_uv                     = GetFunction(_JL_Library_ID, "jl_close_uv")
    
    ; Global jl_tcp_bind.jl_tcp_bind                     = GetFunction(_JL_Library_ID, "jl_tcp_bind")
    
    Global jl_sizeof_ios_t.jl_sizeof_ios_t             = GetFunction(_JL_Library_ID, "jl_sizeof_ios_t")
    
    ; Global jl_takebuf_array.jl_takebuf_array           = GetFunction(_JL_Library_ID, "jl_takebuf_array")
    ; Global jl_takebuf_string.jl_takebuf_string         = GetFunction(_JL_Library_ID, "jl_takebuf_string")
    ; Global jl_takebuf_raw.jl_takebuf_raw               = GetFunction(_JL_Library_ID, "jl_takebuf_raw")
    ; Global jl_readuntil.jl_readuntil                   = GetFunction(_JL_Library_ID, "jl_readuntil")
  EndIf
  
  Structure jl_uv_file_t
    *data
    *loop.uv_loop_t
;     type.uv_handle_type
;     file.uv_file
  EndStructure
  
  ; #ifdef __GNUC__
  ; #define _JL_FORMAT_ATTR(type, str, arg) \
  ;     __attribute__((format(type, str, arg)))
  ; #else
  ; #define _JL_FORMAT_ATTR(type, str, arg)
  ; #endif
  
  ; PrototypeC.l jl_printf(*s.uv_stream_t, format.p-utf8, ...)
      ; _JL_FORMAT_ATTR(printf, 2, 3);
  ; PrototypeC.l jl_vprintf(*s.uv_stream_t, format.p-utf8, *args.va_list)
      ; _JL_FORMAT_ATTR(printf, 2, 0);
  ; PrototypeC   jl_safe_printf(str.p-utf8, ...)
      ; _JL_FORMAT_ATTR(printf, 1, 2);
  
  Structure JL_STREAM
  EndStructure
  Structure JL_STREAM_p
    *_.JL_STREAM
  EndStructure
  
  Global *JL_STDIN.JL_STREAM_p
  Global *JL_STDOUT.JL_STREAM_p
  Global *JL_STDERR.JL_STREAM_p
  
  PrototypeC.i jl_stdout_stream()                                           ; Returns *JL_STREAM.JL_STREAM
  PrototypeC.i jl_stdin_stream()                                            ; Returns *JL_STREAM.JL_STREAM
  PrototypeC.i jl_stderr_stream()                                           ; Returns *JL_STREAM.JL_STREAM
  
  ; showing and std streams
  PrototypeC   jl_show(*stream.jl_value_t, *v.jl_value_t)
  PrototypeC   jl_flush_cstdio()
  PrototypeC.i jl_stdout_obj()                                              ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_stderr_obj()                                              ; Returns *jl_value_t.jl_value_t
  PrototypeC.i jl_static_show(*out.JL_STREAM, *v.jl_value_t)
  PrototypeC.i jl_static_show_func_sig(*s.JL_STREAM, *type.jl_value_t)
  PrototypeC   jlbacktrace()
  ; Mainly for debugging, use `void*` so that no type cast is needed in C++.
  PrototypeC   jl_(*jl_value)
  
  If _JL_Library_ID
    ; Global jl_printf.jl_printf                               = GetFunction(_JL_Library_ID, "jl_printf")
    ; Global jl_vprintf.jl_vprintf                             = GetFunction(_JL_Library_ID, "jl_vprintf")
    ; Global jl_safe_printf.jl_safe_printf                     = GetFunction(_JL_Library_ID, "jl_safe_printf")
    
    Global *JL_STDIN                                         = GetFunction(_JL_Library_ID, "JL_STDIN")
    Global *JL_STDOUT                                        = GetFunction(_JL_Library_ID, "JL_STDOUT")
    Global *JL_STDERR                                        = GetFunction(_JL_Library_ID, "JL_STDERR")
    
    Global jl_stdout_stream.jl_stdout_stream                 = GetFunction(_JL_Library_ID, "jl_stdout_stream")
    Global jl_stdin_stream.jl_stdin_stream                   = GetFunction(_JL_Library_ID, "jl_stdin_stream")
    Global jl_stderr_stream.jl_stderr_stream                 = GetFunction(_JL_Library_ID, "jl_stderr_stream")
    
    Global jl_show.jl_show                                   = GetFunction(_JL_Library_ID, "jl_show")
    Global jl_flush_cstdio.jl_flush_cstdio                   = GetFunction(_JL_Library_ID, "jl_flush_cstdio")
    Global jl_stdout_obj.jl_stdout_obj                       = GetFunction(_JL_Library_ID, "jl_stdout_obj")
    Global jl_stderr_obj.jl_stderr_obj                       = GetFunction(_JL_Library_ID, "jl_stderr_obj")
    Global jl_static_show.jl_static_show                     = GetFunction(_JL_Library_ID, "jl_static_show")
    Global jl_static_show_func_sig.jl_static_show_func_sig   = GetFunction(_JL_Library_ID, "jl_static_show_func_sig")
    Global jlbacktrace.jlbacktrace                           = GetFunction(_JL_Library_ID, "jlbacktrace")
    Global jl_.jl_                                           = GetFunction(_JL_Library_ID, "jl_")
  EndIf
  
  ;- julia options -----------------------------------------------------------
  ; NOTE: This struct needs to be kept in sync with JLOptions type in base/options.jl
  Structure jl_options_t
    quiet.b
    *julia_home                 ; String
    *julia_bin                  ; String
    *eval                       ; String
    *print                      ; String
    *postboot                   ; String
    *load                       ; String
    *image_file                 ; String
    *cpu_target                 ; String
    nprocs.l
    *machinefile                ; String
    isinteractive.b
    color.b
    historyfile.b
    startupfile.b
    compile_enabled.b
    code_coverage.b
    malloc_log.b
    opt_level.b
    check_bounds.b
    depwarn.b
    can_inline.b
    fast_math.b
    *worker                     ; String
    handle_signals.b
    use_precompiled.b
    use_compilecache.b
    *bindto                     ; String
    *outputbc                   ; String
    *outputo                    ; String
    *outputji                   ; String
    incremental.b
    image_file_specified.b
  EndStructure
  ; #### Pointer on jl_options_t
  Structure jl_options_t_p
    *_.jl_options_t
  EndStructure
  
  If _JL_Library_ID
    Global *jl_options.jl_options_t_p = GetFunction(_JL_Library_ID, "jl_options_t")
  EndIf
  
  ; Parse an argc/argv pair to extract general julia options, passing back out
  ; any arguments that should be passed on to the script.
  ;PrototypeC   jl_parse_opts(*argcp.Long, ***argvp)
  
  ; Set julia-level ARGS array according to the arguments provided in
  ; argc/argv
  ;PrototypeC   jl_set_ARGS(argc.l, **argv)
  
  PrototypeC.l jl_generating_output()
  
  If _JL_Library_ID
    Global jl_generating_output.jl_generating_output = GetFunction(_JL_Library_ID, "jl_generating_output")
  EndIf
  
  ; Settings for code_coverage and malloc_log
  ; NOTE: if these numbers change, test/cmdlineargs.jl will have to be updated
  #JL_LOG_NONE = 0
  #JL_LOG_USER = 1
  #JL_LOG_ALL  = 2
  
  #JL_OPTIONS_CHECK_BOUNDS_DEFAULT = 0
  #JL_OPTIONS_CHECK_BOUNDS_ON = 1
  #JL_OPTIONS_CHECK_BOUNDS_OFF = 2
  
  #JL_OPTIONS_COMPILE_DEFAULT = 1
  #JL_OPTIONS_COMPILE_OFF = 0
  #JL_OPTIONS_COMPILE_ON  = 1
  #JL_OPTIONS_COMPILE_ALL = 2
  #JL_OPTIONS_COMPILE_MIN = 3
  
  #JL_OPTIONS_COLOR_ON = 1
  #JL_OPTIONS_COLOR_OFF = 2
  
  #JL_OPTIONS_HISTORYFILE_ON = 1
  #JL_OPTIONS_HISTORYFILE_OFF = 0
  
  #JL_OPTIONS_STARTUPFILE_ON = 1
  #JL_OPTIONS_STARTUPFILE_OFF = 2
  
  #JL_OPTIONS_DEPWARN_OFF = 0
  #JL_OPTIONS_DEPWARN_ON = 1
  #JL_OPTIONS_DEPWARN_ERROR = 2
  
  #JL_OPTIONS_FAST_MATH_ON = 1
  #JL_OPTIONS_FAST_MATH_OFF = 2
  #JL_OPTIONS_FAST_MATH_DEFAULT = 0
  
  #JL_OPTIONS_HANDLE_SIGNALS_ON = 1
  #JL_OPTIONS_HANDLE_SIGNALS_OFF = 0
  
  #JL_OPTIONS_USE_PRECOMPILED_YES = 1
  #JL_OPTIONS_USE_PRECOMPILED_NO = 0
  
  #JL_OPTIONS_USE_COMPILECACHE_YES = 1
  #JL_OPTIONS_USE_COMPILECACHE_NO = 0
  
  ; Version information
  ; XIncludeFile <julia_version.h>
  
  PrototypeC.l jl_ver_major()
  PrototypeC.l jl_ver_minor()
  PrototypeC.l jl_ver_patch()
  PrototypeC.l jl_ver_is_release()
  PrototypeC.i jl_ver_string()                    ; Returns a pointer to a string
  PrototypeC.i jl_git_branch()                    ; Returns a pointer to a string
  PrototypeC.i jl_git_commit()                    ; Returns a pointer to a string
  
  If _JL_Library_ID
    Global jl_ver_major.jl_ver_major           = GetFunction(_JL_Library_ID, "jl_ver_major")
    Global jl_ver_minor.jl_ver_minor           = GetFunction(_JL_Library_ID, "jl_ver_minor")
    Global jl_ver_patch.jl_ver_patch           = GetFunction(_JL_Library_ID, "jl_ver_patch")
    Global jl_ver_is_release.jl_ver_is_release = GetFunction(_JL_Library_ID, "jl_ver_is_release")
    Global jl_ver_string.jl_ver_string         = GetFunction(_JL_Library_ID, "jl_ver_string")
    Global jl_git_branch.jl_git_branch         = GetFunction(_JL_Library_ID, "jl_git_branch")
    Global jl_git_commit.jl_git_commit         = GetFunction(_JL_Library_ID, "jl_git_commit")
  EndIf
  
  ; nullable struct representations
  Structure jl_nullable_float64_t
    isnull.a
    value.d
  EndStructure
  
  Structure jl_nullable_float32_t
    isnull.a
    value.f
  EndStructure
  
  ; #define jl_current_module (jl_get_ptls_states()->current_module)
  ; #define jl_current_task (jl_get_ptls_states()->current_task)
  ; #define jl_root_task (jl_get_ptls_states()->root_task)
  ; #define jl_exception_in_transit (jl_get_ptls_states()->exception_in_transit)
  ; #define jl_task_arg_in_transit (jl_get_ptls_states()->task_arg_in_transit)
  
  ; #ifdef __cplusplus
  ; }
  ; #endif
  ; 
  ; #endif
  
EndDeclareModule

Module Julia
  
  ;- core Data types ------------------------------------------------------------
  
  Procedure jl_astaggedvalue(*v)
    Protected *tagged.jl_taggedvalue_t = *v - SizeOf(jl_taggedvalue_t)
    
    ProcedureReturn *tagged
  EndProcedure
  
  Procedure.i jl_valueof(*v)
    Protected *value.jl_value_t = *v + SizeOf(jl_taggedvalue_t)
    
    ProcedureReturn *value
  EndProcedure
  
  Procedure.i jl_typeof(*v)
    Protected *tagged.jl_taggedvalue_t = jl_astaggedvalue(*v)
    
    ProcedureReturn *tagged\header & ~15
  EndProcedure
  
  Procedure jl_set_typeof(*v, *t)
      ; Do Not call this on a value that is already initialized.
      *tag.jl_taggedvalue_t = jl_astaggedvalue(*v)
      *tag\type = *t
  EndProcedure
  
  Procedure jl_array_ndimwords(ndims.l)
    If ndims < 3
      ProcedureReturn 0
    Else
      ndims - 2
    EndIf
  EndProcedure
  
  ;- gc -------------------------------------------------------------------------
  
  Procedure.i jl_pgcstack()
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    ProcedureReturn *jl_ptls_t\pgcstack ; is jl_gcframe_t
  EndProcedure
  
  Procedure JL_GC_PUSH1(arg1)
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = AllocateMemory(SizeOf(Integer) * 3)
    
    PokeI(*Temp                     , 3)
    PokeI(*Temp + SizeOf(Integer)   , *jl_ptls_t\pgcstack)
    PokeI(*Temp + SizeOf(Integer)*2 , arg1)
    
    *jl_ptls_t\pgcstack = *Temp
  EndProcedure
  
  Procedure JL_GC_PUSH2(arg1, arg2)
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = AllocateMemory(SizeOf(Integer) * 4)
    
    PokeI(*Temp                     , 5)
    PokeI(*Temp + SizeOf(Integer)   , *jl_ptls_t\pgcstack)
    PokeI(*Temp + SizeOf(Integer)*2 , arg1)
    PokeI(*Temp + SizeOf(Integer)*3 , arg2)
    
    *jl_ptls_t\pgcstack = *Temp
  EndProcedure
  
  Procedure JL_GC_PUSH3(arg1, arg2, arg3)
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = AllocateMemory(SizeOf(Integer) * 5)
    
    PokeI(*Temp                     , 7)
    PokeI(*Temp + SizeOf(Integer)   , *jl_ptls_t\pgcstack)
    PokeI(*Temp + SizeOf(Integer)*2 , arg1)
    PokeI(*Temp + SizeOf(Integer)*3 , arg2)
    PokeI(*Temp + SizeOf(Integer)*4 , arg3)
    
    *jl_ptls_t\pgcstack = *Temp
  EndProcedure
  
  Procedure JL_GC_PUSH4(arg1, arg2, arg3, arg4)
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = AllocateMemory(SizeOf(Integer) * 6)
    
    PokeI(*Temp                     , 9)
    PokeI(*Temp + SizeOf(Integer)   , *jl_ptls_t\pgcstack)
    PokeI(*Temp + SizeOf(Integer)*2 , arg1)
    PokeI(*Temp + SizeOf(Integer)*3 , arg2)
    PokeI(*Temp + SizeOf(Integer)*4 , arg3)
    PokeI(*Temp + SizeOf(Integer)*5 , arg4)
    
    *jl_ptls_t\pgcstack = *Temp
  EndProcedure
  
  Procedure JL_GC_PUSH5(arg1, arg2, arg3, arg4, arg5)
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = AllocateMemory(SizeOf(Integer) * 7)
    
    PokeI(*Temp                     , 11)
    PokeI(*Temp + SizeOf(Integer)   , *jl_ptls_t\pgcstack)
    PokeI(*Temp + SizeOf(Integer)*2 , arg1)
    PokeI(*Temp + SizeOf(Integer)*3 , arg2)
    PokeI(*Temp + SizeOf(Integer)*4 , arg3)
    PokeI(*Temp + SizeOf(Integer)*5 , arg4)
    PokeI(*Temp + SizeOf(Integer)*6 , arg5)
    
    *jl_ptls_t\pgcstack = *Temp
  EndProcedure
  
  Procedure JL_GC_POP()
    Protected *jl_ptls_t.jl_ptls_t = jl_get_ptls_states()
    
    *Temp.jl_gcframe_t = *jl_ptls_t\pgcstack
    
    *jl_ptls_t\pgcstack = *jl_ptls_t\pgcstack\prev
    
    FreeMemory(*Temp)
  EndProcedure
  
  ;- object accessors -----------------------------------------------------------
  
CompilerIf Defined(STORE_ARRAY_LEN, #PB_Constant)
  Procedure.i jl_array_len(*a.jl_array_t)
    ProcedureReturn *a\length
  EndProcedure
CompilerElse
  Procedure.i jl_array_len(*a.jl_array_t)
    ProcedureReturn jl_array_len_(*a)
  EndProcedure
CompilerEndIf
  Procedure.i jl_array_data(*a.jl_array_t)
    ProcedureReturn *a\_data
  EndProcedure
  
  ;- basic predicates -----------------------------------------------------------
  
  Procedure.i jl_get_function(*m.jl_module_t, name.s)
    ProcedureReturn jl_get_global(*m, jl_symbol(name))                        ; Returns *jl_function_t.jl_function_t
  EndProcedure
  
  Procedure.l jl_vinfo_sa(vi.a)
    ProcedureReturn Bool((vi & 16) <> 0)
  EndProcedure
  
  Procedure.l jl_vinfo_usedundef(vi.a)
    ProcedureReturn Bool((vi & 32) <> 0)
  EndProcedure
  
  ;- tasks and exceptions -------------------------------------------------------
  
CompilerIf Defined(JULIA_ENABLE_THREADING, #PB_Constant)
  Procedure jl_lock_frame_push(*lock.jl_mutex_t)
    *ptls.jl_ptls_t = jl_get_ptls_states()
    ; For early bootstrap
    If Not ptls.current_task
      ProcedureReturn
    EndIf
    *locks.arraylist_t = *ptls.current_task.locks
    len.i = *locks.Len
    If len >= *locks.max
      arraylist_grow(*locks, 1)
    Else
      *locks.len = len + 1
    EndIf
    *locks.items[len] = *lock
  EndProcedure
  
  Procedure jl_lock_frame_pop()
    *ptls.jl_ptls_t = jl_get_ptls_states()
    If *ptls.current_task
      *ptls.current_task.locks.len - 1
    EndIf
  EndProcedure
CompilerElse
;   Procedure jl_lock_frame_push(*lock.jl_mutex_t)
;   EndProcedure
;   Procedure jl_lock_frame_pop()
;   EndProcedure
CompilerEndIf
  
;   Procedure jl_eh_restore_state(*eh.jl_handler_t)
;     *ptls.jl_ptls_t = jl_get_ptls_states()
;     *current_task.jl_task_t = *ptls\current_task
;     ; `eh` may not be `ptls->current_task->eh`. See `jl_pop_handler`
;     ; This function should **NOT** have any safepoint before the ones at the
;     ; end.
;     old_defer_signal.sig_atomic_t = *ptls.defer_signal
;     old_gc_state.b = *ptls.gc_state
;     *current_task.eh = *eh.prev
;     *ptls.pgcstack = *eh.gcstack
;     CompilerIf Defined(JULIA_ENABLE_THREADING, #PB_Constant)
;     *locks.arraylist_t = @*current_task.locks
;     If (*locks.len > *eh.locks_len)
;       For i.i = *locks.len To *eh.locks_len + 1 Step -1
;         jl_mutex_unlock_nogc(*locks.items[i - 1])
;       Next
;       *locks.len = *eh.locks_len
;     EndIf
;     CompilerEndIf
;     *ptls.defer_signal = *eh.defer_signal
;     *ptls.gc_state = *eh.gc_state
;     *ptls.finalizers_inhibited = *eh.finalizers_inhibited
;     If old_gc_state And Not *eh.gc_state
;       jl_gc_safepoint_(*ptls)
;     EndIf
;     If old_defer_signal And Not *eh.defer_signal
;       jl_sigint_safepoint(*ptls)
;     EndIf
;   EndProcedure
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 2104
; FirstLine = 2088
; Folding = -------------
; EnableUnicode
; EnableXP
; EnableCompileCount = 10
; EnableBuildCount = 0
; EnableExeConstant