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

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

Enumeration
  #Object_Datatypes_Binary
  #Object_Datatypes_Integer_U_1; = #PB_Ascii
  #Object_Datatypes_Integer_S_1; = #PB_Byte
  #Object_Datatypes_Integer_U_2; = #PB_Unicode
  #Object_Datatypes_Integer_S_2; = #PB_Word
  #Object_Datatypes_Integer_U_4; = #PB_Long (Unsigned)
  #Object_Datatypes_Integer_S_4; = #PB_Long
  #Object_Datatypes_Integer_U_8; = #PB_Quad (Unsigned)
  #Object_Datatypes_Integer_S_8; = #PB_Quad
  #Object_Datatypes_Float_4    ; = #PB_Float
  #Object_Datatypes_Float_8    ; = #PB_Double
  #Object_Datatypes_String_Ascii
  #Object_Datatypes_String_UTF8
  #Object_Datatypes_String_UTF16
  #Object_Datatypes_String_UTF32
  #Object_Datatypes_String_UCS2
  #Object_Datatypes_String_UCS4
  
  #Object_Datatypes_Types       ; The number of different datatypes
EndEnumeration

#Object_Datatypes_Flag_Big_Endian     = %01
#Object_Datatypes_Flag_Null_Character = %10

; ##################################################### Structures ##################################################

Structure Object_Datatypes_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Datatypes_Main.Object_Datatypes_Main

Structure Object_Datatypes_Input
  ; #### Data-Array properties
  
  Offset.q      ; in Bytes
  
  Color.l
  
  ; #### Temp Values
  List Value.Object_View1D_Input_Value()
EndStructure

Structure Object_Datatypes
  *Window.Window
  Window_Close.l
  
  ; #### Gadget stuff
  ListIcon.i
  Editor.i
  Button_Set.i
  CheckBox.i[10]
  
  Update_ListIcon.i
  
  ; #### Math stuff
  
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Init ########################################################

Global Object_Datatypes_Font = LoadFont(#PB_Any, "Courier New", 10)

; ##################################################### Declares ####################################################

Declare   Object_Datatypes_Main(*Object.Object)
Declare   _Object_Datatypes_Delete(*Object.Object)
Declare   Object_Datatypes_Window_Open(*Object.Object)

Declare   Object_Datatypes_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Datatypes_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Datatypes_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)

Declare   Object_Datatypes_Window_Close(*Object.Object)

; ##################################################### Procedures ##################################################

Procedure Object_Datatypes_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Datatypes.Object_Datatypes
  Protected *Object_Input.Object_Input
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  *Object\Type = Object_Datatypes_Main\Object_Type
  *Object\Type_Base = Object_Datatypes_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Datatypes_Delete()
  *Object\Function_Main = @Object_Datatypes_Main()
  *Object\Function_Window = @Object_Datatypes_Window_Open()
  *Object\Function_Configuration_Get = @Object_Datatypes_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Datatypes_Configuration_Set()
  
  *Object\Name = "Datatype Editor"
  *Object\Color = RGBA(150,100,150,255)
  
  *Object_Datatypes = AllocateMemory(SizeOf(Object_Datatypes))
  *Object\Custom_Data = *Object_Datatypes
  InitializeStructure(*Object_Datatypes, Object_Datatypes)
  
  ; #### Add Input
  *Object_Input = Object_Input_Add(*Object)
  *Object_Input\Function_Event = @Object_Datatypes_Input_Event()
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Datatypes_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  Object_Datatypes_Window_Close(*Object)
  
  ClearStructure(*Object_Datatypes, Object_Datatypes)
  FreeMemory(*Object_Datatypes)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Datatypes_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Size", #NBT_Tag_Quad)  : NBT_Tag_Set_Number(*NBT_Tag, *Object_Datatypes\Size)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Datatypes_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  ;*NBT_Tag = NBT_Tag(*Parent_Tag, "Size") : *Object_Datatypes\Size = NBT_Tag_Get_Number(*NBT_Tag)
  
  ProcedureReturn #True
EndProcedure

Procedure.s Object_Datatypes_Data_2_String(*Object.Object, Type.i, Flags.i)
  Protected Size.q
  Protected String.s
  Protected i.i
  Protected Ascii_Metadata.a
  Protected Ascii_Data.a
  Protected Other_Data.q
  Protected *Temp_Data, *Temp_Metadata
  
  If Not *Object
    ProcedureReturn ""
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn ""
  EndIf
  
  Size = Object_Input_Get_Size(FirstElement(*Object\Input()))
  
  If Size <= 0
    ProcedureReturn ""
  EndIf
  
  Select Type
    Case #Object_Datatypes_Binary
      ; #### Limit Size
      If Size > 1000
        Size = 1000
      EndIf
      For i = 0 To Size-1
        If Object_Input_Get_Data(FirstElement(*Object\Input()), i, 1, @Ascii_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            String + RSet(Bin(Ascii_Data, #PB_Ascii), 8, "0") + " "
          Else
            String + "???????? "
          EndIf
        Else
          String + "XXXXXXXX "
        EndIf
      Next
      
    Case #Object_Datatypes_Integer_U_1; = #PB_Ascii
      If Size >= 1
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 1, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            ProcedureReturn StrU(PeekA(@Other_Data), #PB_Ascii)
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_S_1; = #PB_Byte
      If Size >= 1
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 1, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            ProcedureReturn Str(PeekB(@Other_Data))
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_U_2; = #PB_Unicode
      If Size >= 2
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 2, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 2)
            EndIf
            ProcedureReturn StrU(PeekU(@Other_Data), #PB_Unicode)
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_S_2; = #PB_Word
      If Size >= 2
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 2, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 2)
            EndIf
            ProcedureReturn Str(PeekW(@Other_Data))
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_U_4; = #PB_Long (Unsigned)
      If Size >= 4
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 4)
            EndIf
            ProcedureReturn StrU(PeekL(@Other_Data), #PB_Long)
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_S_4; = #PB_Long
      If Size >= 4
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 4)
            EndIf
            ProcedureReturn Str(PeekL(@Other_Data))
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_U_8; = #PB_Quad (Unsigned)
      If Size >= 8
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 8)
            EndIf
            ProcedureReturn StrU(PeekQ(@Other_Data), #PB_Quad)
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Integer_S_8; = #PB_Quad
      If Size >= 8
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 8)
            EndIf
            ProcedureReturn Str(PeekQ(@Other_Data))
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Float_4    ; = #PB_Float
      If Size >= 4
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 4)
            EndIf
            ProcedureReturn RTrim(RTrim(StrF(PeekF(@Other_Data), 50), "0"), ".")
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_Float_8    ; = #PB_Double
      If Size >= 8
        If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data, @Ascii_Metadata)
          If Ascii_Metadata & #Metadata_Readable
            If Flags & #Object_Datatypes_Flag_Big_Endian
              Memory_Mirror(@Other_Data, 8)
            EndIf
            ProcedureReturn RTrim(RTrim(StrD(PeekD(@Other_Data), 350), "0"), ".")
          EndIf
        EndIf
      EndIf
      
    Case #Object_Datatypes_String_Ascii
      ; #### Limit Size
      If Size > 10000000
        Size = 10000000
      EndIf
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn ""
      EndIf
      *Temp_Metadata = AllocateMemory(Size+2)
      If Not *Temp_Metadata
        FreeMemory(*Temp_Data)
        ProcedureReturn ""
      EndIf
      
      If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
        String = PeekS(*Temp_Data, Size, #PB_Ascii)
      EndIf
      
      FreeMemory(*Temp_Data)
      FreeMemory(*Temp_Metadata)
      
    Case #Object_Datatypes_String_UTF8
      ; #### Limit Size
      If Size > 10000000
        Size = 10000000
      EndIf
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn ""
      EndIf
      *Temp_Metadata = AllocateMemory(Size+2)
      If Not *Temp_Metadata
        FreeMemory(*Temp_Data)
        ProcedureReturn ""
      EndIf
      
      If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
        String = PeekS(*Temp_Data, Size, #PB_UTF8)
      EndIf
      
      FreeMemory(*Temp_Data)
      FreeMemory(*Temp_Metadata)
      
    ;Case #Object_Datatypes_String_UTF16
    ;Case #Object_Datatypes_String_UTF32
    
    Case #Object_Datatypes_String_UCS2
      ; #### Limit Size
      If Size > 10000000
        Size = 10000000
      EndIf
      ; #### Only allow even sizes
      Size & ~1
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn ""
      EndIf
      *Temp_Metadata = AllocateMemory(Size+2)
      If Not *Temp_Metadata
        FreeMemory(*Temp_Data)
        ProcedureReturn ""
      EndIf
      
      If Object_Input_Get_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data, *Temp_Metadata)
        If Flags & #Object_Datatypes_Flag_Big_Endian
          For i = 0 To Size/2-1
            Memory_Mirror(*Temp_Data+i*2, 2)
          Next
        EndIf
        String = PeekS(*Temp_Data, Size, #PB_Unicode)
      EndIf
      
      FreeMemory(*Temp_Data)
      FreeMemory(*Temp_Metadata)
      
    ;Case #Object_Datatypes_String_UCS4
    
  EndSelect
  
  ProcedureReturn String
EndProcedure

Procedure Object_Datatypes_String_2_Data(*Object.Object, Type.i, String.s, Flags.i)
  Protected Size.q
  Protected Part_String.s
  Protected Result.i
  Protected i.i
  Protected Ascii_Metadata.a
  Protected Ascii_Data.a
  Protected Other_Data.q
  Protected *Temp_Data, *Temp_Metadata
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  Select Type
    Case #Object_Datatypes_Binary
      String = ReplaceString(String, " ", "")
      For i = 0 To (Len(String)/8)-1
        Part_String = Mid(String, i*8 + 1, 8)
        PokeA(@Ascii_Data, Val("%"+Part_String))
        Object_Input_Set_Data(FirstElement(*Object\Input()), i, 1, @Ascii_Data)
      Next
      ProcedureReturn #True
      
    Case #Object_Datatypes_Integer_U_1; = #PB_Ascii
      PokeA(@Other_Data, Val(String))
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 1, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_S_1; = #PB_Byte
      PokeB(@Other_Data, Val(String))
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 1, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_U_2; = #PB_Unicode
      PokeU(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 2)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 2, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_S_2; = #PB_Word
      PokeW(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 2)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 2, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_U_4; = #PB_Long (Unsigned)
      PokeL(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 2)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_S_4; = #PB_Long
      PokeL(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 4)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_U_8; = #PB_Quad (Unsigned)
      PokeQ(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 8)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Integer_S_8; = #PB_Quad
      PokeQ(@Other_Data, Val(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 8)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Float_4    ; = #PB_Float
      PokeF(@Other_Data, ValF(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 4)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 4, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_Float_8    ; = #PB_Double
      PokeD(@Other_Data, ValD(String))
      If Flags & #Object_Datatypes_Flag_Big_Endian
        Memory_Mirror(@Other_Data, 8)
      EndIf
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, 8, @Other_Data)
        ProcedureReturn #True
      EndIf
      
    Case #Object_Datatypes_String_Ascii
      Size = StringByteLength(String, #PB_Ascii)
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn #False
      EndIf
      
      PokeS(*Temp_Data, String, Size, #PB_Ascii)
      
      If Flags & #Object_Datatypes_Flag_Null_Character
        Size + 1
      EndIf
      
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data)
        Result = #True
      EndIf
      
      FreeMemory(*Temp_Data)
      
    Case #Object_Datatypes_String_UTF8
      Size = StringByteLength(String, #PB_UTF8)
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn #False
      EndIf
      
      PokeS(*Temp_Data, String, Size, #PB_UTF8)
      
      If Flags & #Object_Datatypes_Flag_Null_Character
        Size + 1
      EndIf
      
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data)
        Result = #True
      EndIf
      
      FreeMemory(*Temp_Data)
      
    ;Case #Object_Datatypes_String_UTF16
    ;Case #Object_Datatypes_String_UTF32
    
    Case #Object_Datatypes_String_UCS2
      Size = StringByteLength(String, #PB_Unicode)
      *Temp_Data = AllocateMemory(Size+2)
      If Not *Temp_Data
        ProcedureReturn #False
      EndIf
      
      PokeS(*Temp_Data, String, Size, #PB_Unicode)
      
      If Flags & #Object_Datatypes_Flag_Big_Endian
        For i = 0 To Size/2-1
          Memory_Mirror(*Temp_Data+i*2, 2)
        Next
      EndIf
      
      If Flags & #Object_Datatypes_Flag_Null_Character
        Size + 2
      EndIf
      
      If Object_Input_Set_Data(FirstElement(*Object\Input()), 0, Size, *Temp_Data)
        Result = #True
      EndIf
      
      FreeMemory(*Temp_Data)
      
    ;Case #Object_Datatypes_String_UCS4
    
  EndSelect
  
  ProcedureReturn Result
EndProcedure

Procedure Object_Datatypes_Update_ListIcon(*Object.Object)
  Protected i.i
  Protected Type.i
  Protected String.s
  Protected Flags.i
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  ;ClearGadgetItems(*Object_Datatypes\ListIcon)
  
  For i = 0 To CountGadgetItems(*Object_Datatypes\ListIcon)-1
    Type = GetGadgetItemData(*Object_Datatypes\ListIcon, i)
    If GetGadgetState(*Object_Datatypes\CheckBox[0])
      Flags | #Object_Datatypes_Flag_Big_Endian
    EndIf
    If GetGadgetState(*Object_Datatypes\CheckBox[1])
      Flags | #Object_Datatypes_Flag_Null_Character
    EndIf
    String = Object_Datatypes_Data_2_String(*Object, Type, Flags)
    
    SetGadgetItemText(*Object_Datatypes\ListIcon, i, String, 1)
  Next
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Datatypes_Input_Event(*Object_Input.Object_Input, *Object_Event.Object_Event)
  If Not *Object_Input
    ProcedureReturn #False
  EndIf
  If Not *Object_Event
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Input\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  Select *Object_Event\Type
    Case #Object_Link_Event_Update
      *Object_Datatypes\Update_ListIcon = #True
      
  EndSelect
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Datatypes_Window_Event_ListIcon()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected String.s
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(Event_Gadget) >= 0
    String = GetGadgetItemText(Event_Gadget, GetGadgetState(Event_Gadget), 1)
    SetGadgetText(*Object_Datatypes\Editor, String)
  EndIf
  
EndProcedure

Procedure Object_Datatypes_Window_Event_Button_Set()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  
  Protected Type.i
  Protected Flags.i
  
  Protected *Window.Window = Window_Get(Event_Window)
  If Not *Window
    ProcedureReturn 
  EndIf
  Protected *Object.Object = *Window\Object
  If Not *Object
    ProcedureReturn 
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn 
  EndIf
  
  If GetGadgetState(*Object_Datatypes\ListIcon) >= 0
    Type = GetGadgetItemData(*Object_Datatypes\ListIcon, GetGadgetState(*Object_Datatypes\ListIcon))
    If GetGadgetState(*Object_Datatypes\CheckBox[0])
      Flags | #Object_Datatypes_Flag_Big_Endian
    EndIf
    If GetGadgetState(*Object_Datatypes\CheckBox[1])
      Flags | #Object_Datatypes_Flag_Null_Character
    EndIf
    Object_Datatypes_String_2_Data(*Object, Type, GetGadgetText(*Object_Datatypes\Editor), Flags)
  EndIf
  
EndProcedure

Procedure Object_Datatypes_Window_Event_CheckBox()
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
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn 
  EndIf
  
  *Object_Datatypes\Update_ListIcon = #True
  
EndProcedure

Procedure Object_Datatypes_Window_Event_SizeWindow()
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
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn 
  EndIf
  
  ResizeGadget(*Object_Datatypes\ListIcon, #PB_Ignore, #PB_Ignore, WindowWidth(Event_Window)-20, 320)
  ResizeGadget(*Object_Datatypes\Editor, #PB_Ignore, 340, WindowWidth(Event_Window)-20, WindowHeight(Event_Window)-380)
  ResizeGadget(*Object_Datatypes\Button_Set, WindowWidth(Event_Window)-100, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
  
  ResizeGadget(*Object_Datatypes\CheckBox[0], #PB_Ignore, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
  ResizeGadget(*Object_Datatypes\CheckBox[1], #PB_Ignore, WindowHeight(Event_Window)-30, #PB_Ignore, #PB_Ignore)
  
EndProcedure

Procedure Object_Datatypes_Window_Event_Menu()
  Protected Event_Window = EventWindow()
  Protected Event_Gadget = EventGadget()
  Protected Event_Type = EventType()
  Protected Event_Menu = EventMenu()
  
  Select Event_Menu
    
  EndSelect
EndProcedure

Procedure Object_Datatypes_Window_Event_CloseWindow()
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
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn 
  EndIf
  
  *Object_Datatypes\Window_Close = #True
EndProcedure

Procedure Object_Datatypes_Window_Open(*Object.Object)
  Protected Width, Height
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  If Not *Object_Datatypes\Window
    
    Width = 300
    Height = 460
    
    *Object_Datatypes\Window = Window_Create(*Object, "Datatype Editor", "Types", #False, 0, 0, Width, Height, #True)
    
    ; #### Gadgets
    
    *Object_Datatypes\ListIcon = ListIconGadget(#PB_Any, 10, 10, Width-20, Height-100, "Type", 50, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(*Object_Datatypes\ListIcon, 1, "Value", 500)
    
    ; #### Add ListIcon items
    AddGadgetItem(*Object_Datatypes\ListIcon,  0, "Binary")   : SetGadgetItemData(*Object_Datatypes\ListIcon,  0,  0)
    AddGadgetItem(*Object_Datatypes\ListIcon,  1, "uint8")    : SetGadgetItemData(*Object_Datatypes\ListIcon,  1,  1)
    AddGadgetItem(*Object_Datatypes\ListIcon,  2, "int8")     : SetGadgetItemData(*Object_Datatypes\ListIcon,  2,  2)
    AddGadgetItem(*Object_Datatypes\ListIcon,  3, "uint16")   : SetGadgetItemData(*Object_Datatypes\ListIcon,  3,  3)
    AddGadgetItem(*Object_Datatypes\ListIcon,  4, "int16")    : SetGadgetItemData(*Object_Datatypes\ListIcon,  4,  4)
    AddGadgetItem(*Object_Datatypes\ListIcon,  5, "uint32")   : SetGadgetItemData(*Object_Datatypes\ListIcon,  5,  5)
    AddGadgetItem(*Object_Datatypes\ListIcon,  6, "int32")    : SetGadgetItemData(*Object_Datatypes\ListIcon,  6,  6)
    AddGadgetItem(*Object_Datatypes\ListIcon,  7, "uint64")   : SetGadgetItemData(*Object_Datatypes\ListIcon,  7,  7)
    AddGadgetItem(*Object_Datatypes\ListIcon,  8, "int64")    : SetGadgetItemData(*Object_Datatypes\ListIcon,  8,  8)
    AddGadgetItem(*Object_Datatypes\ListIcon,  9, "float32")   : SetGadgetItemData(*Object_Datatypes\ListIcon,  9,  9)
    AddGadgetItem(*Object_Datatypes\ListIcon, 10, "float64")   : SetGadgetItemData(*Object_Datatypes\ListIcon, 10, 10)
    AddGadgetItem(*Object_Datatypes\ListIcon, 11, "Ascii")    : SetGadgetItemData(*Object_Datatypes\ListIcon, 11, 11)
    AddGadgetItem(*Object_Datatypes\ListIcon, 12, "UTF8")     : SetGadgetItemData(*Object_Datatypes\ListIcon, 12, 12)
    ;AddGadgetItem(*Object_Datatypes\ListIcon, 13, "UTF16")    : SetGadgetItemData(*Object_Datatypes\ListIcon, 13, 13)
    ;AddGadgetItem(*Object_Datatypes\ListIcon, 14, "UTF32")    : SetGadgetItemData(*Object_Datatypes\ListIcon, 14, 14)
    AddGadgetItem(*Object_Datatypes\ListIcon, 13, "UCS2")     : SetGadgetItemData(*Object_Datatypes\ListIcon, 13, 15)
    ;AddGadgetItem(*Object_Datatypes\ListIcon, 16, "UCS4")     : SetGadgetItemData(*Object_Datatypes\ListIcon, 16, 16)
    
    *Object_Datatypes\Editor = EditorGadget(#PB_Any, 10, Height-80, Width-20, 40)
    
    *Object_Datatypes\Button_Set = ButtonGadget(#PB_Any, Width-100, Height-30, 90, 20, "Write")
    
    *Object_Datatypes\CheckBox[0] = CheckBoxGadget(#PB_Any, 10, Height-30, 70, 20, "Big Endian")
    *Object_Datatypes\CheckBox[1] = CheckBoxGadget(#PB_Any, 90, Height-30, 90, 20, "Null-Character")
    
    BindGadgetEvent(*Object_Datatypes\ListIcon, @Object_Datatypes_Window_Event_ListIcon())
    BindGadgetEvent(*Object_Datatypes\Button_Set, @Object_Datatypes_Window_Event_Button_Set())
    BindGadgetEvent(*Object_Datatypes\CheckBox[0], @Object_Datatypes_Window_Event_CheckBox())
    BindGadgetEvent(*Object_Datatypes\CheckBox[1], @Object_Datatypes_Window_Event_CheckBox())
    
    BindEvent(#PB_Event_SizeWindow, @Object_Datatypes_Window_Event_SizeWindow(), *Object_Datatypes\Window\ID)
    BindEvent(#PB_Event_Menu, @Object_Datatypes_Window_Event_Menu(), *Object_Datatypes\Window\ID)
    BindEvent(#PB_Event_CloseWindow, @Object_Datatypes_Window_Event_CloseWindow(), *Object_Datatypes\Window\ID)
    
    *Object_Datatypes\Update_ListIcon = #True
    
  Else
    Window_Set_Active(*Object_Datatypes\Window)
  EndIf
EndProcedure

Procedure Object_Datatypes_Window_Close(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  If *Object_Datatypes\Window
    
    UnbindGadgetEvent(*Object_Datatypes\ListIcon, @Object_Datatypes_Window_Event_ListIcon())
    UnbindGadgetEvent(*Object_Datatypes\Button_Set, @Object_Datatypes_Window_Event_Button_Set())
    UnbindGadgetEvent(*Object_Datatypes\CheckBox[0], @Object_Datatypes_Window_Event_CheckBox())
    UnbindGadgetEvent(*Object_Datatypes\CheckBox[1], @Object_Datatypes_Window_Event_CheckBox())
    
    UnbindEvent(#PB_Event_SizeWindow, @Object_Datatypes_Window_Event_SizeWindow(), *Object_Datatypes\Window\ID)
    UnbindEvent(#PB_Event_Menu, @Object_Datatypes_Window_Event_Menu(), *Object_Datatypes\Window\ID)
    UnbindEvent(#PB_Event_CloseWindow, @Object_Datatypes_Window_Event_CloseWindow(), *Object_Datatypes\Window\ID)
    
    Window_Delete(*Object_Datatypes\Window)
    *Object_Datatypes\Window = #Null
  EndIf
EndProcedure

Procedure Object_Datatypes_Main(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Datatypes.Object_Datatypes = *Object\Custom_Data
  If Not *Object_Datatypes
    ProcedureReturn #False
  EndIf
  
  If *Object_Datatypes\Window
    If *Object_Datatypes\Update_ListIcon
      *Object_Datatypes\Update_ListIcon = #False
      Object_Datatypes_Update_ListIcon(*Object)
    EndIf
  EndIf
  
  If *Object_Datatypes\Window_Close
    *Object_Datatypes\Window_Close = #False
    Object_Datatypes_Window_Close(*Object)
  EndIf
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Datatypes_Main\Object_Type = Object_Type_Create()
If Object_Datatypes_Main\Object_Type
  Object_Datatypes_Main\Object_Type\Category = "Manipulator"
  Object_Datatypes_Main\Object_Type\Name = "Datatype Editor"
  Object_Datatypes_Main\Object_Type\UID = "D3_TYPES"
  Object_Datatypes_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Datatypes_Main\Object_Type\Date_Creation = Date(2014,08,08,19,56,00)
  Object_Datatypes_Main\Object_Type\Date_Modification = Date(2014,08,09,19,24,00)
  Object_Datatypes_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Datatypes_Main\Object_Type\Description = "Displays Data interpreted as different datatypes."
  Object_Datatypes_Main\Object_Type\Function_Create = @Object_Datatypes_Create()
  Object_Datatypes_Main\Object_Type\Version = 900
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 470
; FirstLine = 434
; Folding = ---
; EnableUnicode
; EnableXP