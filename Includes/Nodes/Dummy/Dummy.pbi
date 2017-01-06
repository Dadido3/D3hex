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
; TODO: Get_Descriptor(...)
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule _Node_Dummy
  EnableExplicit
  
  ; ################################################### Functions ###################################################
  Declare   Create(Requester)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module _Node_Dummy
  ; ################################################### Includes ####################################################
  UseModule Constants
  UseModule Helper
  
  ; ################################################### Prototypes ##################################################
  
  ; ################################################### Structures ##################################################
  
  ; ################################################### Constants ###################################################
  
  #MemoryAllocation_Step = 1024*1024*1
  
  ; ################################################### Structures ##################################################
  
  Structure Main
    *Node_Type.Node_Type::Object
  EndStructure
  Global Main.Main
  
  Structure Object
    *Raw_Data
    Raw_Data_Size.i
  EndStructure
  
  ; ################################################### Variables ###################################################
  
  ; ################################################### Declares ####################################################
  
  Declare   _Delete(*Node.Node::Object)
  
  Declare   Configuration_Get(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  Declare   Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
  
  Declare   Get_Descriptor(*Output.Node::Conn_Output)
  Declare.q Get_Size(*Output.Node::Conn_Output)
  Declare   Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
  Declare   Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
  Declare   Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
  
  ; ################################################### Procedures ##################################################
  
  Procedure Create(Requester)
    Protected *Node.Node::Object = Node::_Create()
    Protected *Object.Object
    Protected *Output.Node::Conn_Output
    
    If Not *Node
      ProcedureReturn #Null
    EndIf
    
    *Node\Type = Main\Node_Type
    *Node\Type_Base = Main\Node_Type
    
    *Node\Function_Delete = @_Delete()
    *Node\Function_Configuration_Get = @Configuration_Get()
    *Node\Function_Configuration_Set = @Configuration_Set()
    
    *Node\Name = Main\Node_Type\Name
    *Node\Name_Inherited = *Node\Name
    *Node\Color = RGBA(127, 127, 100, 255)
    
    *Node\Custom_Data = AllocateStructure(Object)
    *Object = *Node\Custom_Data
    
    *Object\Raw_Data = AllocateMemory(#MemoryAllocation_Step)
    
    ; #### Add Output
    *Output = Node::Output_Add(*Node)
    *Output\Function_Get_Descriptor = @Get_Descriptor()
    *Output\Function_Get_Size = @Get_Size()
    *Output\Function_Get_Data = @Get_Data()
    *Output\Function_Set_Data = @Set_Data()
    *Output\Function_Shift = @Shift()
    
    
    ; #### Debugdata
    ;Protected *Temp = AllocateMemory(1000000)
    ;Protected i
    
    ;For i = 0 To 1000000-1 Step 8
    ;  PokeD(*Temp + i, Sin(i/8/1000*2*#PI)*1000)
    ;Next
    
    ;Set_Data(*Output, 0, 1000000, *Temp)
    
    ;FreeMemory(*Temp)
    
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
    
    If *Object\Raw_Data
      FreeMemory(*Object\Raw_Data)
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
    
    *NBT_Tag = NBT::Tag_Add(*Parent_Tag, "Data", NBT::#Tag_Byte_Array)  : NBT::Tag_Set_Array(*NBT_Tag, *Object\Raw_Data, *Object\Raw_Data_Size)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Configuration_Set(*Node.Node::Object, *Parent_Tag.NBT::Tag)
    Protected *NBT_Tag.NBT::Tag
    Protected New_Size.i, *Temp
    
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
    
    *NBT_Tag = NBT::Tag(*Parent_Tag, "Data")  
    
    ; #### Reallocate Memory
    *Object\Raw_Data_Size = NBT::Tag_Count(*NBT_Tag)
    New_Size = Quad_Divide_Ceil(*Object\Raw_Data_Size, #MemoryAllocation_Step) * #MemoryAllocation_Step
    If New_Size <> MemorySize(*Object\Raw_Data) And New_Size > 0
      *Temp = ReAllocateMemory(*Object\Raw_Data, New_Size)
      If *Temp
        *Object\Raw_Data = *Temp
      Else
        ProcedureReturn #False
      EndIf
    EndIf
    
    NBT::Tag_Get_Array(*NBT_Tag, *Object\Raw_Data, *Object\Raw_Data_Size)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure Get_Descriptor(*Output.Node::Conn_Output)
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
    
    NBT::Tag_Set_String(NBT::Tag_Add(*Output\Descriptor\Tag, "Name", NBT::#Tag_String), "Dummy")
    
    ProcedureReturn *Output\Descriptor
  EndProcedure
  
  Procedure.q Get_Size(*Output.Node::Conn_Output)
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
    
    ProcedureReturn *Object\Raw_Data_Size
  EndProcedure
  
  Procedure Get_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data, *Metadata)
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Position > *Object\Raw_Data_Size
      ProcedureReturn #False
    EndIf
    If Size > *Object\Raw_Data_Size - Position
      Size = *Object\Raw_Data_Size - Position
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    
    If *Metadata
      FillMemory(*Metadata, Size, #Metadata_NoError | #Metadata_Readable | #Metadata_Writeable, #PB_Ascii)
    EndIf
    
    ProcedureReturn Memory::Range_Copy(*Object\Raw_Data, Position, *Data, 0, Size, *Object\Raw_Data_Size, Size)
  EndProcedure
  
  Procedure Set_Data(*Output.Node::Conn_Output, Position.q, Size.i, *Data)
    Protected Result.i
    Protected Event.Node::Event
    Protected Temp_Size.q, New_Size.i, *Temp
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    If Size <= 0
      ProcedureReturn #False
    EndIf
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Position > *Object\Raw_Data_Size
      ProcedureReturn #False
    EndIf
    
    ; #### Reallocate if the operation increases the size of the object (Todo)
    Temp_Size = Position + Size - *Object\Raw_Data_Size
    If Temp_Size > 0
      *Object\Raw_Data_Size + Temp_Size
      New_Size = Quad_Divide_Ceil(*Object\Raw_Data_Size, #MemoryAllocation_Step) * #MemoryAllocation_Step
      If New_Size <> MemorySize(*Object\Raw_Data) And New_Size > 0
        *Temp = ReAllocateMemory(*Object\Raw_Data, New_Size)
        If *Temp
          *Object\Raw_Data = *Temp
        Else
          ProcedureReturn #False
        EndIf
      EndIf
    EndIf
    
    ;File_Size = Object_File_Get_Size(*Output)
    ;If Size + Position > File_Size
    ;  Size = File_Size - Position
    ;EndIf
    
    Result = Memory::Range_Copy(*Data, 0, *Object\Raw_Data, Position, Size, Size, *Object\Raw_Data_Size)
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = Position
    Event\Size = Size
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    ProcedureReturn Result
  EndProcedure
  
  Procedure Shift(*Output.Node::Conn_Output, Position.q, Offset.q)
    Protected New_Size.i, *Temp
    Protected Raw_Data_Size_Old.q
    Protected Event.Node::Event
    
    If Not *Output
      ProcedureReturn #False
    EndIf
    Protected *Node.Node::Object = *Output\Object
    If Not *Node
      ProcedureReturn #False
    EndIf
    If Position < 0
      ProcedureReturn #False
    EndIf
    
    Protected *Object.Object = *Node\Custom_Data
    If Not *Object
      ProcedureReturn #False
    EndIf
    
    If Position > *Object\Raw_Data_Size
      ProcedureReturn #False
    EndIf
    
    If Offset < Position - *Object\Raw_Data_Size
      Offset = Position - *Object\Raw_Data_Size
    EndIf
    
    Raw_Data_Size_Old = *Object\Raw_Data_Size
    *Object\Raw_Data_Size + Offset
    
    If Offset < 0
      Memory::Range_Move(*Object\Raw_Data+Position, 0, *Object\Raw_Data+Position, Offset, Raw_Data_Size_Old-Position, Raw_Data_Size_Old-Position, Raw_Data_Size_Old-Position)
    EndIf
    
    New_Size = Quad_Divide_Ceil(*Object\Raw_Data_Size, #MemoryAllocation_Step) * #MemoryAllocation_Step
    If New_Size <> MemorySize(*Object\Raw_Data) And New_Size > 0
      *Temp = ReAllocateMemory(*Object\Raw_Data, New_Size)
      If *Temp
        *Object\Raw_Data = *Temp
      Else
        ProcedureReturn #False
      EndIf
    EndIf
    
    If Offset > 0
      Memory::Range_Move(*Object\Raw_Data, Position, *Object\Raw_Data, Position+Offset, Raw_Data_Size_Old-Position, Raw_Data_Size_Old, *Object\Raw_Data_Size)
      If Position + Offset <= *Object\Raw_Data_Size ; probably redundant
        FillMemory(*Object\Raw_Data+Position, Offset)
      EndIf
    EndIf
    
    Event\Type = Node::#Link_Event_Update
    Event\Position = Position
    Event\Size = Raw_Data_Size_Old - Position
    Node::Output_Event(FirstElement(*Node\Output()), Event)
    
    ProcedureReturn #True
  EndProcedure
  
  ; ################################################### Initialisation ##############################################
  
  Main\Node_Type = Node_Type::Create()
  If Main\Node_Type
    Main\Node_Type\Category = "Data-Source"
    Main\Node_Type\Name = "Dummy"
    Main\Node_Type\UID = "D3_DUMMY"
    Main\Node_Type\Author = "David Vogel (Dadido3)"
    Main\Node_Type\Date_Creation = Date(2014,01,12,14,02,00)
    Main\Node_Type\Date_Modification = Date(2014,01,12,14,02,00)
    Main\Node_Type\Date_Compilation = #PB_Compiler_Date
    Main\Node_Type\Description = "Virtual data object."
    Main\Node_Type\Function_Create = @Create()
    Main\Node_Type\Version = 1000
  EndIf
  
  ; ################################################### Main ########################################################
  
  ; ################################################### End #########################################################
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 270
; FirstLine = 243
; Folding = --
; EnableUnicode
; EnableXP