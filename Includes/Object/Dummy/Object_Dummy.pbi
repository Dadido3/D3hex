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
; TODO: Object_Dummy_Get_Descriptor(...)
; 

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

#Object_Dummy_MemoryAllocation_Step = 1024*1024*1

; ##################################################### Structures ##################################################

Structure Object_Dummy_Main
  *Object_Type.Object_Type
EndStructure
Global Object_Dummy_Main.Object_Dummy_Main

Structure Object_Dummy
  *Raw_Data
  Raw_Data_Size.i
EndStructure

; ##################################################### Variables ###################################################

; ##################################################### Declares ####################################################

Declare   _Object_Dummy_Delete(*Object.Object)

Declare   Object_Dummy_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
Declare   Object_Dummy_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)

Declare   Object_Dummy_Get_Descriptor(*Object_Output.Object_Output)
Declare.q Object_Dummy_Get_Size(*Object_Output.Object_Output)
Declare   Object_Dummy_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
Declare   Object_Dummy_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
Declare   Object_Dummy_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)

; ##################################################### Procedures ##################################################

Procedure Object_Dummy_Create(Requester)
  Protected *Object.Object = _Object_Create()
  Protected *Object_Dummy.Object_Dummy
  Protected *Object_Output.Object_Output
  
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  *Object\Type = Object_Dummy_Main\Object_Type
  *Object\Type_Base = Object_Dummy_Main\Object_Type
  
  *Object\Function_Delete = @_Object_Dummy_Delete()
  *Object\Function_Configuration_Get = @Object_Dummy_Configuration_Get()
  *Object\Function_Configuration_Set = @Object_Dummy_Configuration_Set()
  
  *Object\Name = Object_Dummy_Main\Object_Type\Name
  *Object\Name_Inherited = *Object\Name
  *Object\Color = RGBA(127, 127, 100, 255)
  
  *Object\Custom_Data = AllocateStructure(Object_Dummy)
  *Object_Dummy = *Object\Custom_Data
  
  *Object_Dummy\Raw_Data = AllocateMemory(#Object_Dummy_MemoryAllocation_Step)
  
  ; #### Add Output
  *Object_Output = Object_Output_Add(*Object)
  *Object_Output\Function_Get_Descriptor = @Object_Dummy_Get_Descriptor()
  *Object_Output\Function_Get_Size = @Object_Dummy_Get_Size()
  *Object_Output\Function_Get_Data = @Object_Dummy_Get_Data()
  *Object_Output\Function_Set_Data = @Object_Dummy_Set_Data()
  *Object_Output\Function_Convolute = @Object_Dummy_Convolute()
  
  
  ; #### Debugdata
  ;Protected *Temp = AllocateMemory(1000000)
  ;Protected i
  
  ;For i = 0 To 1000000-1 Step 8
  ;  PokeD(*Temp + i, Sin(i/8/1000*2*#PI)*1000)
  ;Next
  
  ;Object_Dummy_Set_Data(*Object_Output, 0, 1000000, *Temp)
  
  ;FreeMemory(*Temp)
  
  ProcedureReturn *Object
EndProcedure

Procedure _Object_Dummy_Delete(*Object.Object)
  If Not *Object
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  
  If *Object_Dummy\Raw_Data
    FreeMemory(*Object_Dummy\Raw_Data)
  EndIf
  
  FreeStructure(*Object_Dummy)
  *Object\Custom_Data = #Null
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Dummy_Configuration_Get(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag_Add(*Parent_Tag, "Data", #NBT_Tag_Byte_Array)  : NBT_Tag_Set_Array(*NBT_Tag, *Object_Dummy\Raw_Data, *Object_Dummy\Raw_Data_Size)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Dummy_Configuration_Set(*Object.Object, *Parent_Tag.NBT_Tag)
  Protected *NBT_Tag.NBT_Tag
  Protected New_Size.i, *Temp
  
  If Not *Object
    ProcedureReturn #False
  EndIf
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  If Not *Parent_Tag
    ProcedureReturn #False
  EndIf
  
  *NBT_Tag = NBT_Tag(*Parent_Tag, "Data")  
  
  ; #### Reallocate Memory
  *Object_Dummy\Raw_Data_Size = NBT_Tag_Count(*NBT_Tag)
  New_Size = Quad_Divide_Ceil(*Object_Dummy\Raw_Data_Size, #Object_Dummy_MemoryAllocation_Step) * #Object_Dummy_MemoryAllocation_Step
  If New_Size <> MemorySize(*Object_Dummy\Raw_Data) And New_Size > 0
    *Temp = ReAllocateMemory(*Object_Dummy\Raw_Data, New_Size)
    If *Temp
      *Object_Dummy\Raw_Data = *Temp
    Else
      ProcedureReturn #False
    EndIf
  EndIf
  
  NBT_Tag_Get_Array(*NBT_Tag, *Object_Dummy\Raw_Data, *Object_Dummy\Raw_Data_Size)
  
  ProcedureReturn #True
EndProcedure

Procedure Object_Dummy_Get_Descriptor(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn #Null
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #Null
  EndIf
  
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #Null
  EndIf
  
  NBT_Tag_Set_String(NBT_Tag_Add(*Object_Output\Descriptor\NBT_Tag, "Name", #NBT_Tag_String), "Dummy")
  
  ProcedureReturn *Object_Output\Descriptor
EndProcedure

Procedure.q Object_Dummy_Get_Size(*Object_Output.Object_Output)
  If Not *Object_Output
    ProcedureReturn -1
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn -1
  EndIf
  
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn -1
  EndIf
  
  ProcedureReturn *Object_Dummy\Raw_Data_Size
EndProcedure

Procedure Object_Dummy_Get_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data, *Metadata)
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  
  If Position > *Object_Dummy\Raw_Data_Size
    ProcedureReturn #False
  EndIf
  If Size > *Object_Dummy\Raw_Data_Size - Position
    Size = *Object_Dummy\Raw_Data_Size - Position
  EndIf
  If Size <= 0
    ProcedureReturn #False
  EndIf
  
  If *Metadata
    FillMemory(*Metadata, Size, #Metadata_NoError | #Metadata_Readable | #Metadata_Writeable, #PB_Ascii)
  EndIf
  
  ProcedureReturn Memory::Range_Copy(*Object_Dummy\Raw_Data, Position, *Data, 0, Size, *Object_Dummy\Raw_Data_Size, Size)
EndProcedure

Procedure Object_Dummy_Set_Data(*Object_Output.Object_Output, Position.q, Size.i, *Data)
  Protected Result.i
  Protected Object_Event.Object_Event
  Protected Temp_Size.q, New_Size.i, *Temp
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  If Size <= 0
    ProcedureReturn #False
  EndIf
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  
  If Position > *Object_Dummy\Raw_Data_Size
    ProcedureReturn #False
  EndIf
  
  ; #### Reallocate if the operation increases the size of the object (Todo)
  Temp_Size = Position + Size - *Object_Dummy\Raw_Data_Size
  If Temp_Size > 0
    *Object_Dummy\Raw_Data_Size + Temp_Size
    New_Size = Quad_Divide_Ceil(*Object_Dummy\Raw_Data_Size, #Object_Dummy_MemoryAllocation_Step) * #Object_Dummy_MemoryAllocation_Step
    If New_Size <> MemorySize(*Object_Dummy\Raw_Data) And New_Size > 0
      *Temp = ReAllocateMemory(*Object_Dummy\Raw_Data, New_Size)
      If *Temp
        *Object_Dummy\Raw_Data = *Temp
      Else
        ProcedureReturn #False
      EndIf
    EndIf
  EndIf
  
  ;File_Size = Object_File_Get_Size(*Object_Output)
  ;If Size + Position > File_Size
  ;  Size = File_Size - Position
  ;EndIf
  
  Result = Memory::Range_Copy(*Data, 0, *Object_Dummy\Raw_Data, Position, Size, Size, *Object_Dummy\Raw_Data_Size)
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = Position
  Object_Event\Size = Size
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  ProcedureReturn Result
EndProcedure

Procedure Object_Dummy_Convolute(*Object_Output.Object_Output, Position.q, Offset.q)
  Protected New_Size.i, *Temp
  Protected Raw_Data_Size_Old.q
  Protected Object_Event.Object_Event
  
  If Not *Object_Output
    ProcedureReturn #False
  EndIf
  Protected *Object.Object = *Object_Output\Object
  If Not *Object
    ProcedureReturn #False
  EndIf
  If Position < 0
    ProcedureReturn #False
  EndIf
  
  Protected *Object_Dummy.Object_Dummy = *Object\Custom_Data
  If Not *Object_Dummy
    ProcedureReturn #False
  EndIf
  
  If Position > *Object_Dummy\Raw_Data_Size
    ProcedureReturn #False
  EndIf
  
  If Offset < Position - *Object_Dummy\Raw_Data_Size
    Offset = Position - *Object_Dummy\Raw_Data_Size
  EndIf
  
  Raw_Data_Size_Old = *Object_Dummy\Raw_Data_Size
  *Object_Dummy\Raw_Data_Size + Offset
  
  If Offset < 0
    Memory::Range_Move(*Object_Dummy\Raw_Data+Position, 0, *Object_Dummy\Raw_Data+Position, Offset, Raw_Data_Size_Old-Position, Raw_Data_Size_Old-Position, Raw_Data_Size_Old-Position)
  EndIf
  
  New_Size = Quad_Divide_Ceil(*Object_Dummy\Raw_Data_Size, #Object_Dummy_MemoryAllocation_Step) * #Object_Dummy_MemoryAllocation_Step
  If New_Size <> MemorySize(*Object_Dummy\Raw_Data) And New_Size > 0
    *Temp = ReAllocateMemory(*Object_Dummy\Raw_Data, New_Size)
    If *Temp
      *Object_Dummy\Raw_Data = *Temp
    Else
      ProcedureReturn #False
    EndIf
  EndIf
  
  If Offset > 0
    Memory::Range_Move(*Object_Dummy\Raw_Data, Position, *Object_Dummy\Raw_Data, Position+Offset, Raw_Data_Size_Old-Position, Raw_Data_Size_Old, *Object_Dummy\Raw_Data_Size)
    If Position + Offset <= *Object_Dummy\Raw_Data_Size ; probably redundant
      FillMemory(*Object_Dummy\Raw_Data+Position, Offset)
    EndIf
  EndIf
  
  Object_Event\Type = #Object_Link_Event_Update
  Object_Event\Position = Position
  Object_Event\Size = Raw_Data_Size_Old - Position
  Object_Output_Event(FirstElement(*Object\Output()), Object_Event)
  
  ProcedureReturn #True
EndProcedure

; ##################################################### Initialisation ##############################################

Object_Dummy_Main\Object_Type = Object_Type_Create()
If Object_Dummy_Main\Object_Type
  Object_Dummy_Main\Object_Type\Category = "Data-Source"
  Object_Dummy_Main\Object_Type\Name = "Dummy"
  Object_Dummy_Main\Object_Type\UID = "D3_DUMMY"
  Object_Dummy_Main\Object_Type\Author = "David Vogel (Dadido3)"
  Object_Dummy_Main\Object_Type\Date_Creation = Date(2014,01,12,14,02,00)
  Object_Dummy_Main\Object_Type\Date_Modification = Date(2014,01,12,14,02,00)
  Object_Dummy_Main\Object_Type\Date_Compilation = #PB_Compiler_Date
  Object_Dummy_Main\Object_Type\Description = "Virtual data object."
  Object_Dummy_Main\Object_Type\Function_Create = @Object_Dummy_Create()
  Object_Dummy_Main\Object_Type\Version = 1000
EndIf

; ##################################################### Main ########################################################

; ##################################################### End #########################################################


; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 363
; FirstLine = 352
; Folding = --
; EnableUnicode
; EnableXP