DeclareModule Lua
  
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Windows
      CompilerSelect #PB_Compiler_Processor
        CompilerCase #PB_Processor_x86
          #Lua_Library_File = "/Binaries/x86/lua53.lib" ; Windows x86
        CompilerCase #PB_Processor_x64
          #Lua_Library_File = "/Binaries/x64/lua53.lib" ; Windows x64
      CompilerEndSelect
      
  ; CompilerCase #PB_OS_Linux
  ;   CompilerSelect #PB_Compiler_Processor
  ;     CompilerCase #PB_Processor_x86
  ;       Import "/usr/lib/libm.so"
  ;       EndImport
  ;       Import "/usr/lib/libdl.so"
  ;       EndImport
  ;       #Library_File = "/Lib/lua53.x86.a"
  ;     CompilerCase #PB_Processor_x64
  ;       #Library_File = "/Lib/lua53.x86.a"
  ;   CompilerEndSelect
      
    CompilerDefault
      CompilerError "Lua-Module: OS not supported."
      
  CompilerEndSelect
  
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
  ; #### In zlib uInt is defined as "unsigned int" and uLong as "unsigned long".
  Macro C_int : l : EndMacro
  Macro C_uInt : l : EndMacro
  CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS
    Macro C_long : i : EndMacro
    Macro C_uLong : i : EndMacro
  CompilerElse
    Macro C_long : l : EndMacro
    Macro C_uLong : l : EndMacro
  CompilerEndIf
  
  ;  ===============================================================
  ;-                   ======== lua.h ========
  ;  ===============================================================
  
  ; $Id: lua.h,v 1.325 2014/12/26 17:24:27 roberto Exp $
  ; Lua - A Scripting Language
  ; Lua.org, PUC-Rio, Brazil (http://www.lua.org)
  ; See Copyright Notice at the End of this file
  
  #LUA_VERSION_MAJOR    = "5"
  #LUA_VERSION_MINOR    = "3"
  #LUA_VERSION_NUM      = 503
  #LUA_VERSION_RELEASE  = "0"
  
  #LUA_VERSION          = "Lua " + #LUA_VERSION_MAJOR + "." + #LUA_VERSION_MINOR
  #LUA_RELEASE          = #LUA_VERSION + "." + #LUA_VERSION_RELEASE
  #LUA_COPYRIGHT        = #LUA_RELEASE + "  Copyright (C) 1994-2015 Lua.org, PUC-Rio"
  #LUA_AUTHORS          = "R. Ierusalimschy, L. H. de Figueiredo, W. Celes"
  
  ; mark For precompiled code ('<esc>Lua')
  #LUA_SIGNATURE        = Chr($1B) + "Lua"
  
  ; option For multiple returns in 'lua_pcall' And 'lua_call'
  #LUA_MULTRET          = -1
  
  ; pseudo-indices
  ;#LUA_REGISTRYINDEX    = #LUAI_FIRSTPSEUDOIDX
  ;Macro lua_upvalueindex(i) : (#LUA_REGISTRYINDEX - (i)) : EndMacro
  
  ; thread status
  #LUA_OK               = 0
  #LUA_YIELD            = 1
  #LUA_ERRRUN           = 2
  #LUA_ERRSYNTAX        = 3
  #LUA_ERRMEM           = 4
  #LUA_ERRGCMM          = 5
  #LUA_ERRERR           = 6
  
  Structure lua_State : EndStructure
  
  ; basic types
  #LUA_TNONE            = -1
  
  #LUA_TNIL             = 0
  #LUA_TBOOLEAN         = 1
  #LUA_TLIGHTUSERDATA   = 2
  #LUA_TNUMBER          = 3
  #LUA_TSTRING          = 4
  #LUA_TTABLE           = 5
  #LUA_TFUNCTION        = 6
  #LUA_TUSERDATA        = 7
  #LUA_TTHREAD          = 8
  
  #LUA_NUMTAGS          = 9
  
  ; minimum Lua stack available To a C function
  #LUA_MINSTACK         = 20
  
  ; predefined values in the registry
  #LUA_RIDX_MAINTHREAD  = 1
  #LUA_RIDX_GLOBALS     = 2
  #LUA_RIDX_LAST        = #LUA_RIDX_GLOBALS
  
  ; type of numbers in Lua
  Macro lua_Number : d : EndMacro
  
  
  ; type For integer functions
  Macro lua_Integer : q : EndMacro
  
  ; unsigned integer type
  Macro lua_Unsigned : q : EndMacro
  
  ; type For continuation-function contexts
  Structure lua_KContext : EndStructure
  
  ; Type For C functions registered With Lua
  PrototypeC.C_int lua_CFunction(*L.lua_State)
  
  ; Type For continuation functions
  PrototypeC.C_int lua_KFunction(*L.lua_State, status.C_int, *ctx.lua_KContext)
  
  
  ; Type For functions that Read/write blocks when loading/dumping Lua chunks
  PrototypeC.i lua_Reader(*L.lua_State, *ud, *sz.Integer)  ; Returns pointer to a string
  
  PrototypeC.C_int lua_Writer(*L.lua_State, p.p-utf8, sz.i, *ud)
  
  
  ; Type For memory-allocation functions
  PrototypeC lua_Alloc(*ud, *ptr, osize.i, nsize.i)
  
  ImportC #Lua_Library_File
    
    ; /*
    ; ** state manipulation
    ; */
    
    lua_newstate.i          (*f.lua_Alloc, *ud)
    lua_close               (*L.lua_State)
    lua_newthread.i         (*L.lua_State)
    
    lua_atpanic.i           (*L.lua_State, *panicf.lua_CFunction)
    
    lua_version.i           (*L.lua_State)                          ; Returns pointer to a lua_Number
    
    
    ; /*
    ; ** basic stack manipulation
    ; */
    
    lua_absindex.C_int      (*L.lua_State, idx.C_int)
    lua_gettop.C_int        (*L.lua_State)
    lua_settop              (*L.lua_State, idx.C_int)
    lua_pushvalue           (*L.lua_State, idx.C_int)
    lua_rotate              (*L.lua_State, idx.C_int, n.C_int)
    lua_copy                (*L.lua_State, fromidx.C_int, toidx.C_int)
    lua_checkstack.C_int    (*L.lua_State, sz.C_int)
    
    lua_xmove               (*from.lua_State, *to.lua_State, n.C_int)
    
    
    ; /*
    ; ** access functions (stack -> C)
    ; */
    
    lua_isnumber.C_int      (*L.lua_State, idx.C_int)
    lua_isstring.C_int      (*L.lua_State, idx.C_int)
    lua_iscfunction.C_int   (*L.lua_State, idx.C_int)
    lua_isinteger.C_int     (*L.lua_State, idx.C_int)
    lua_isuserdata.C_int    (*L.lua_State, idx.C_int)
    lua_type.C_int          (*L.lua_State, idx.C_int)
    lua_typename.i          (*L.lua_State, tp.C_int)  ; Returns pointer to a string
    
    lua_tonumberx.lua_Number      (*L.lua_State, idx.C_int, *isnum)
    lua_tointegerx.lua_Integer    (*L.lua_State, idx.C_int, *isnum)
    lua_toboolean                 (*L.lua_State, idx.C_int)
    lua_tolstring.i               (*L.lua_State, idx.C_int, *len.Integer)  ; Returns pointer to a string
    lua_rawlen.i                  (*L.lua_State, idx.C_int)
    lua_tocfunction.lua_CFunction (*L.lua_State, idx.C_int)
    lua_touserdata                (*L.lua_State, idx.C_int)
    lua_tothread.i                (*L.lua_State, idx.C_int)
    lua_topointer.i               (*L.lua_State, idx.C_int)
    
  EndImport
  
  ; /*
  ; ** Comparison And arithmetic functions
  ; */
  
  #LUA_OPADD  = 0   ; ORDER TM, ORDER OP
  #LUA_OPSUB  = 1
  #LUA_OPMUL  = 2
  #LUA_OPMOD  = 3
  #LUA_OPPOW  = 4
  #LUA_OPDIV  = 5
  #LUA_OPIDIV = 6
  #LUA_OPBAND = 7
  #LUA_OPBOR  = 8
  #LUA_OPBXOR = 9
  #LUA_OPSHL  = 10
  #LUA_OPSHR  = 11
  #LUA_OPUNM  = 12
  #LUA_OPBNOT = 13
  
  #LUA_OPEQ = 0
  #LUA_OPLT = 1
  #LUA_OPLE = 2
  
  ImportC #Lua_Library_File
    
    lua_arith               (*L.lua_State, op.C_int)
    
    lua_rawequal.C_int      (*L.lua_State, idx1.C_int, idx2.C_int)
    lua_compare.C_int       (*L.lua_State, idx1.C_int, idx2.C_int, op.C_int)
    
    
    ; /*
    ; ** push functions (C -> stack)
    ; */
    lua_pushnil             (*L.lua_State)
    lua_pushnumber          (*L.lua_State, n.lua_Number)
    lua_pushinteger         (*L.lua_State, n.lua_Integer)
    lua_pushlstring.i       (*L.lua_State, s.p-utf8, len.i)           ; Returns pointer to a string
    lua_pushstring.i        (*L.lua_State, s.p-utf8)                  ; Returns pointer to a string
    ;lua_pushvfstring.i      (*L.lua_State, fmt.p-utf8, argp.va_list)  ; Returns pointer to a string
    lua_pushfstring.i       (*L.lua_State, fmt.p-utf8);, ...)         ; Returns pointer to a string
    lua_pushcclosure        (*L.lua_State, *fn.lua_CFunction, n.C_int)
    lua_pushboolean         (*L.lua_State, b.C_int)
    lua_pushlightuserdata   (*L.lua_State, *p)
    lua_pushthread.C_int    (*L.lua_State)
    
    
    ; /*
    ; ** get functions (Lua -> stack)
    ; */
    lua_getglobal.C_int     (*L.lua_State, name.p-utf8)
    lua_gettable.C_int      (*L.lua_State, idx.C_int)
    lua_getfield.C_int      (*L.lua_State, idx.C_int, k.p-utf8)
    lua_geti.C_int          (*L.lua_State, idx.C_int, n.lua_Integer)
    lua_rawget.C_int        (*L.lua_State, idx.C_int)
    lua_rawgeti.C_int       (*L.lua_State, idx.C_int, n.lua_Integer)
    lua_rawgetp.C_int       (*L.lua_State, idx.C_int, p.p-utf8)
    
    lua_createtable         (*L.lua_State, narr.C_int, nrec.C_int)
    lua_newuserdata.i       (*L.lua_State, sz.i)
    lua_getmetatable.C_int  (*L.lua_State, objindex.C_int)
    lua_getuservalue.C_int  (*L.lua_State, idx.C_int)
    
    
    ; /*
    ; ** set functions (stack -> Lua)
    ; */
    lua_setglobal           (*L.lua_State, name.p-utf8)
    lua_settable            (*L.lua_State, idx.C_int)
    lua_setfield            (*L.lua_State, idx.C_int, k.p-utf8)
    lua_seti                (*L.lua_State, idx.C_int, n.lua_Integer)
    lua_rawset              (*L.lua_State, idx.C_int)
    lua_rawseti             (*L.lua_State, idx.C_int, n.lua_Integer)
    lua_rawsetp             (*L.lua_State, idx.C_int, p.p-utf8)
    lua_setmetatable.C_int  (*L.lua_State, objindex.C_int)
    lua_setuservalue        (*L.lua_State, idx.C_int)
    
    
    ; /*
    ; ** 'load' And 'call' functions (load And run Lua code)
    ; */
    lua_callk               (*L.lua_State, nargs.C_int, nresults.C_int, *ctx.lua_KContext, k.lua_KFunction)
    Macro lua_call(L,n,r) : lua_callk(L, (n), (r), 0, #Null) : EndMacro
    
    lua_pcallk.C_int        (*L.lua_State, nargs.C_int, nresults.C_int, errfunc.C_int, *ctx.lua_KContext, k.lua_KFunction)
    Macro lua_pcall(L,n,r,f) : (lua_pcallk(L, (n), (r), (f), 0, #Null)) : EndMacro
    
    lua_load.C_int          (*L.lua_State, reader.lua_Reader, *dt, chunkname.p-utf8, mode.p-utf8)
    
    lua_dump.C_int          (*L.lua_State, writer.lua_Writer, *Data, strip.C_int)
    
    
    ; /*
    ; ** coroutine functions
    ; */
    lua_yieldk.C_int        (*L.lua_State, nresults.C_int, *ctx.lua_KContext, k.lua_KFunction)
    lua_resume.C_int        (*L.lua_State, *from.lua_State, narg.C_int)
    lua_status.C_int        (*L.lua_State)
    lua_isyieldable.C_int   (*L.lua_State)
    
    Macro lua_yield(L,n) : lua_yieldk(L, (n), 0, #Null) : EndMacro
    
  EndImport
  
  
  ; /*
  ; ** garbage-collection function And options
  ; */
  
  #LUA_GCSTOP       = 0
  #LUA_GCRESTART		= 1
  #LUA_GCCOLLECT		= 2
  #LUA_GCCOUNT      = 3
  #LUA_GCCOUNTB     = 4
  #LUA_GCSTEP       = 5
  #LUA_GCSETPAUSE   = 6
  #LUA_GCSETSTEPMUL = 7
  #LUA_GCISRUNNING  = 9
  
  ImportC #Lua_Library_File
    
    lua_gc.C_int            (*L.lua_State, what.C_int, _Data.C_int)
    
    
    ; /*
    ; ** miscellaneous functions
    ; */
    
    lua_error.C_int         (*L.lua_State)
    
    lua_next.C_int          (*L.lua_State, idx.C_int)
    
    lua_concat              (*L.lua_State, n.C_int)
    lua_len                 (*L.lua_State, idx.C_int)
    
    lua_stringtonumber.i    (*L.lua_State, s.p-utf8)
    
    lua_getallocf.i         (*L.lua_State, *ud)
    lua_setallocf           (*L.lua_State, *f.lua_Alloc, *ud)
    
  EndImport
  
  ; /*
  ; ** {==============================================================
  ; ** some useful macros
  ; ** ===============================================================
  ; */
  
  ;Macro lua_getextraspace(L) : ((void *)((char *)(L) - #LUA_EXTRASPACE)) : EndMacro
  
  Macro lua_tonumber(L,i) : lua_tonumberx(L,(i),#Null) : EndMacro
  Macro lua_tointeger(L,i) : lua_tointegerx(L,(i),#Null) : EndMacro
  
  Macro lua_pop(L,n) : lua_settop(L, -(n)-1) : EndMacro
  
  Macro lua_newtable(L) : lua_createtable(L, 0, 0) : EndMacro
  
  Macro lua_register(L,n,f)
    lua_pushcfunction(L, (f))
    lua_setglobal(L, (n))
  EndMacro
  
  Macro lua_pushcfunction(L,f) : lua_pushcclosure(L, (f), 0) : EndMacro
  
  Macro lua_isfunction(L,n) : Bool(lua_type(L, (n)) = #UA_TFUNCTION) : EndMacro
  Macro lua_istable(L,n) : Bool(lua_type(L, (n)) = #LUA_TTABLE) : EndMacro
  Macro lua_islightuserdata(L,n) : Bool(lua_type(L, (n)) = #LUA_TLIGHTUSERDATA) : EndMacro
  Macro lua_isnil(L,n) : Bool(lua_type(L, (n)) = #LUA_TNIL) : EndMacro
  Macro lua_isboolean(L,n) : Bool(lua_type(L, (n)) = #LUA_TBOOLEAN) : EndMacro
  Macro lua_isthread(L,n) : Bool(lua_type(L, (n)) = #LUA_TTHREAD) : EndMacro
  Macro lua_isnone(L,n) : Bool(lua_type(L, (n)) = #LUA_TNONE) : EndMacro
  Macro lua_isnoneornil(L, n) : Bool(lua_type(L, (n)) <= 0) : EndMacro
  
  Macro lua_pushliteral(L, s) : lua_pushlstring(L, s, (SizeOf(s)/SizeOf(Character))-1) : EndMacro
  
  Macro lua_pushglobaltable(L) : lua_rawgeti(L, #LUA_REGISTRYINDEX, #LUA_RIDX_GLOBALS) : EndMacro
  
  Macro lua_tostring(L,i) : lua_tolstring(L, (i), #Null) : EndMacro
  
  
  Macro lua_insert(L,idx) : lua_rotate(L, (idx), 1) : EndMacro
  
  Macro lua_remove(L,idx) : Bool(lua_rotate(L, (idx), -1) And lua_pop(L, 1)) : EndMacro
  
  Macro lua_replace(L,idx) : Bool(lua_copy(L, -1, (idx)) And lua_pop(L, 1)) : EndMacro
  
  ; /* }============================================================== */
  
  
  ; /*
  ; ** {==============================================================
  ; ** compatibility macros For unsigned conversions
  ; ** ===============================================================
  ; */
  CompilerIf Defined(LUA_COMPAT_APIINTCASTS, #PB_Constant)
    
    Macro lua_pushunsigned(L,n) : lua_pushinteger(L, (n)) : EndMacro
    Macro lua_tounsignedx(L,i,is) : lua_tointegerx(L,i,is) : EndMacro
    Macro lua_tounsigned(L,i) : lua_tounsignedx(L,(i),#Null) : EndMacro
    
  CompilerEndIf
  
  ;  ===============================================================
  ;-                  ======== lualib.h ========
  ;  ===============================================================
  
  #LUA_COLIBNAME    = "coroutine"
  #LUA_TABLIBNAME   = "table"
  #LUA_IOLIBNAME    = "io"
  #LUA_OSLIBNAME    = "os"
  #LUA_STRLIBNAME   = "string"
  #LUA_UTF8LIBNAME  = "utf8"
  #LUA_BITLIBNAME   = "bit32"
  #LUA_MATHLIBNAME  = "math"
  #LUA_DBLIBNAME    = "debug"
  #LUA_LOADLIBNAME  = "package"
  
  ImportC #Lua_Library_File
    
    luaopen_base.C_int        (*L.lua_State)
    
    
    luaopen_coroutine.C_int   (*L.lua_State)
    
    luaopen_table.C_int       (*L.lua_State)
    
    luaopen_io.C_int          (*L.lua_State)
    
    luaopen_os.C_int          (*L.lua_State)
    
    luaopen_string.C_int      (*L.lua_State)
    
    luaopen_utf8.C_int        (*L.lua_State)
    
    luaopen_bit32.C_int       (*L.lua_State)
    
    luaopen_math.C_int        (*L.lua_State)
    
    luaopen_debug.C_int       (*L.lua_State)
    
    luaopen_package.C_int     (*L.lua_State)
    
    
    ; open all previous libraries
    luaL_openlibs             (*L.lua_State)
    
  EndImport
  
  ;  ===============================================================
  ;-                  ======== lauxlib.h ========
  ;  ===============================================================
  
  ; extra error code For 'luaL_load'
  #LUA_ERRFILE = #LUA_ERRERR+1
  
  Structure luaL_Reg
    name.i                ; Pointer to a string
    func.lua_CFunction
  EndStructure
  
  ;#LUAL_NUMSIZES = SizeOf(lua_Integer)*16 + SizeOf(lua_Number)
  #LUAL_NUMSIZES = 8*16 + 8
  
  ImportC #Lua_Library_File
    
    luaL_checkversion_      (*L.lua_State, ver.lua_Number, sz.i)
    Macro luaL_checkversion(L) : luaL_checkversion_(L, #LUA_VERSION_NUM, #LUAL_NUMSIZES) : EndMacro
    
    luaL_getmetafield.C_int (*L.lua_State, obj.C_int, e.p-utf8)
    luaL_callmeta.C_int     (*L.lua_State, obj.C_int, e.p-utf8)
    luaL_tolstring.i        (*L.lua_State, idx.C_int, *len.Integer)             ; Returns pointer to a string
    luaL_argerror.C_int     (*L.lua_State, arg.C_int, extramsg.p-utf8)
    luaL_checklstring.i     (*L.lua_State, arg.C_int, *len.Integer)             ; Returns pointer to a string
    luaL_optlstring.i       (*L.lua_State, arg.C_int, def.p-utf8, *len.Integer) ; Returns pointer to a string
    luaL_checknumber.lua_Number   (*L.lua_State, arg.C_int)
    luaL_optnumber.lua_Number     (*L.lua_State, arg.C_int, def.lua_Number)
    
    luaL_checkinteger.lua_Integer (*L.lua_State, arg.C_int)
    luaL_optinteger.lua_Integer   (*L.lua_State, arg.C_int, def.lua_Integer)
    
    luaL_checkstack         (*L.lua_State, sz.C_int, msg.p-utf8)
    luaL_checktype          (*L.lua_State, arg.C_int, t.C_int)
    luaL_checkany           (*L.lua_State, arg.C_int)
    
    luaL_newmetatable.C_int (*L.lua_State, tname.p-utf8)
    luaL_setmetatable       (*L.lua_State, tname.p-utf8)
    luaL_testudata.i        (*L.lua_State, ud.C_int, tname.p-utf8)
    luaL_checkudata.i       (*L.lua_State, ud.C_int, tname.p-utf8)
    
    luaL_where              (*L.lua_State, lvl.C_int)
    luaL_error.C_int        (*L.lua_State, fmt.p-utf8);, ...)
    
    luaL_checkoption.C_int  (*L.lua_State, arg.C_int, def.p-utf8, *lst)
    
    luaL_fileresult.C_int   (*L.lua_State, stat.C_int, fname.p-utf8)
    luaL_execresult.C_int   (*L.lua_State, stat.C_int)
    
  EndImport
  
  ; pre-defined references
  #LUA_NOREF  = -2
  #LUA_REFNIL = -1
  
  ImportC #Lua_Library_File
    
    luaL_ref.C_int          (*L.lua_State, t.C_int)
    luaL_unref              (*L.lua_State, t.C_int, ref.C_int)
    
    luaL_loadfilex.C_int    (*L.lua_State, filename.p-utf8, mode.p-utf8)
    
    Macro luaL_loadfile(L,f) : luaL_loadfilex(L,f,#Null) : EndMacro
    
    luaL_loadbufferx.C_int  (*L.lua_State, buff.p-utf8, sz.i, name.p-utf8, mode.p-utf8)
    luaL_loadstring.C_int   (*L.lua_State, s.p-utf8)
    
    luaL_newstate.i         ()
    
    luaL_len.lua_Integer    (*L.lua_State, idx.C_int)
    
    luaL_gsub.i             (*L.lua_State, s.p-utf8, p.p-utf8, r.p-utf8)  ; Returns pointer to a string
    
    luaL_setfuncs           (*L.lua_State, *lr.luaL_Reg, nup.C_int)
    
    luaL_getsubtable.C_int  (*L.lua_State, idx.C_int, fname.p-utf8)
    
    luaL_traceback          (*L.lua_State, *L1.lua_State, msg.p-utf8, level.C_int)
    
    luaL_requiref           (*L.lua_State, modname.p-utf8, openf.lua_CFunction, glb.C_int)
    
  EndImport
  
  ; /*
  ; ** ===============================================================
  ; ** some useful macros
  ; ** ===============================================================
  ; */
  
  
  ;Macro luaL_newlibtable(L,l) : lua_createtable(L, 0, SizeOf(l)/SizeOf((l)[0]) - 1) : EndMacro
  
  ;Macro luaL_newlib(L,l) : Bool(luaL_checkversion(L) And luaL_newlibtable(L,l) And luaL_setfuncs(L,l,0)) : EndMacro
  
  Macro luaL_argcheck(L, cond,arg,extramsg) : Bool((cond) Or luaL_argerror(L, (arg), (extramsg))) : EndMacro
  Macro luaL_checkstring(L,n) : luaL_checklstring(L, (n), #Null) : EndMacro
  Macro luaL_optstring(L,n,d) : luaL_optlstring(L, (n), (d), #Null) : EndMacro
  
  Macro luaL_typename(L,i) : lua_typename(L, lua_type(L,(i))) : EndMacro
  
  Macro luaL_dofile(L, fn) : Bool(luaL_loadfile(L, fn) Or lua_pcall(L, 0, #LUA_MULTRET, 0)) : EndMacro    ; FIXME: All these functions should return the amount of pushed stack items. Bool and Or is preventing that
  
  Macro luaL_dostring(L, s) : Bool(luaL_loadstring(L, s) Or lua_pcall(L, 0, #LUA_MULTRET, 0)) : EndMacro
  
  Macro luaL_getmetatable(L,n) : lua_getfield(L, #LUA_REGISTRYINDEX, (n)) : EndMacro
  
  ;Macro luaL_opt(L,f,n,d) : (lua_isnoneornil(L,(n)) ? (d) : f(L,(n))) : EndMacro
  
  Macro luaL_loadbuffer(L,s,sz,n) : luaL_loadbufferx(L,s,sz,n,#Null) : EndMacro
  
EndDeclareModule

Module Lua
  
  ; ################## Procedures and Macros for some exceptions ##################
  
  ; ###########################
  ; #### Just a short test ####
  ; ###########################
  ProcedureC Test(*Lua_State)
    Debug PeekS(lua_tostring(*Lua_State, 1),-1, #PB_UTF8)
    ProcedureReturn 0 ; Anzahl der Rückgabeargumente
  EndProcedure
  
  *Lua_State = luaL_newstate()
  
  lua_pushcclosure(*Lua_State, @luaL_openlibs(), 0)
  lua_call(*Lua_State, 0, 0)
  ;lua_callk(*Lua_State, 0, 0, 0, #Null)
  
  lua_register(*Lua_State, "Test", @Test())
  
  Debug PeekD(lua_version(*Lua_State))
  
  Debug luaL_dostring(*Lua_State, "Test('test: 㩛ä+¡m↓')")
  
  ;Debug PeekS(lua_tostring(*Lua_State, -1), -1, #PB_UTF8)
  
  ;Input()
  ; ###########################
  ; #### Just a short test ####
  ; ###########################
  
  
EndModule

; /******************************************************************************
; * Copyright (C) 1994-2015 Lua.org, PUC-Rio.
; *
; * Permission is hereby granted, free of charge, To any person obtaining
; * a copy of this software And associated documentation files (the
; * "Software"), To deal in the Software without restriction, including
; * without limitation the rights To use, copy, modify, merge, publish,
; * distribute, sublicense, And/Or sell copies of the Software, And To
; * permit persons To whom the Software is furnished To do so, subject To
; * the following conditions:
; *
; * The above copyright notice And this permission notice shall be
; * included in all copies Or substantial portions of the Software.
; *
; * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; * EXPRESS Or IMPLIED, INCLUDING BUT Not LIMITED To THE WARRANTIES OF
; * MERCHANTABILITY, FITNESS For A PARTICULAR PURPOSE And NONINFRINGEMENT.
; * IN NO EVENT SHALL THE AUTHORS Or COPYRIGHT HOLDERS BE LIABLE For ANY
; * CLAIM, DAMAGES Or OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
; * TORT Or OTHERWISE, ARISING FROM, OUT OF Or IN CONNECTION With THE
; * SOFTWARE Or THE USE Or OTHER DEALINGS IN THE SOFTWARE.
; ******************************************************************************/
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 578
; FirstLine = 545
; Folding = --------
; EnableUnicode
; EnableXP