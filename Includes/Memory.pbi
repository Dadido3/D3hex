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
; ##################################################### Documentation ###############################################
; 
;
; ##################################################### Includes ####################################################

; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule Memory
  EnableExplicit
  ; ################################################### Constants ###################################################
  
  ; ################################################### Structures ##################################################
  Structure Operation
    Src_Offset.q
    Src_Size.q
    
    Dst_Offset.q
    Dst_Size.q
    
    Copy_Size.q
  EndStructure
  
  ; ################################################### Functions ###################################################
  Declare   Operation_Check(*Operation.Operation)
  Declare   Range_Fill(Ascii.a, Fill_Size.q, *Dst, Dst_Offset.q, Dst_Size.q=-1)
  Declare   Range_Copy(*Src, Src_Offset.q, *Dst, Dst_Offset.q, Copy_Size.q, Src_Size.q=-1, Dst_Size.q=-1)
  Declare   Range_Move(*Src, Src_Offset.q, *Dst, Dst_Offset.q, Copy_Size.q, Src_Size.q=-1, Dst_Size.q=-1)
  Declare   Mirror(*Memory, Size)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Memory
  ; ################################################### Functions ###################################################
  
  ; #### Cuts the Offset's / Sizes of the memory operation to prevent memory violations
  Procedure Operation_Check(*Operation.Operation)
    Protected Temp.q
    
    If *Operation\Src_Offset < 0
      *Operation\Copy_Size  + *Operation\Src_Offset
      *Operation\Dst_Offset - *Operation\Src_Offset
      *Operation\Src_Offset - *Operation\Src_Offset
    EndIf
    
    If *Operation\Dst_Offset < 0
      *Operation\Copy_Size  + *Operation\Dst_Offset
      *Operation\Src_Offset - *Operation\Dst_Offset
      *Operation\Dst_Offset - *Operation\Dst_Offset
    EndIf
    
    Temp = *Operation\Src_Size - *Operation\Src_Offset
    If *Operation\Copy_Size > Temp
      *Operation\Copy_Size = Temp
    EndIf
    
    Temp = *Operation\Dst_Size - *Operation\Dst_Offset
    If *Operation\Copy_Size > Temp
      *Operation\Copy_Size = Temp
    EndIf
    
    If *Operation\Copy_Size < 0
      *Operation\Copy_Size = 0
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### Fills a *Destination with a specified amount of data.
  ; #### It cuts everything, to prevent memory violations
  Procedure Range_Fill(Ascii.a, Fill_Size.q, *Dst, Dst_Offset.q, Dst_Size.q=-1)
    Protected Temp.q
    
    If Not *Dst
      ProcedureReturn #False
    EndIf
    
    If Dst_Size = -1
      Dst_Size.q = MemorySize(*Dst)
    EndIf
    
    If Dst_Offset < 0
      Fill_Size  + Dst_Offset
      Dst_Offset - Dst_Offset
    EndIf
    
    Temp = Dst_Size - Dst_Offset
    If Fill_Size > Temp
      Fill_Size = Temp
    EndIf
    
    If Fill_Size > 0
      FillMemory(*Dst+Dst_Offset, Fill_Size, Ascii)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### Copies a specified amount of data (Copy_Size) from the source to the destination.
  ; #### It cuts everything, to prevent memory violations
  Procedure Range_Copy(*Src, Src_Offset.q, *Dst, Dst_Offset.q, Copy_Size.q, Src_Size.q=-1, Dst_Size.q=-1)
    Protected Temp.q
    If Not *Src
      ProcedureReturn #False
    EndIf
    
    If Not *Dst
      ProcedureReturn #False
    EndIf
    
    If Src_Size = -1
      Src_Size.q = MemorySize(*Src)
    EndIf
    If Dst_Size = -1
      Dst_Size.q = MemorySize(*Dst)
    EndIf
    
    If Src_Offset < 0
      Copy_Size  + Src_Offset
      Dst_Offset - Src_Offset
      Src_Offset - Src_Offset
    EndIf
    
    If Dst_Offset < 0
      Copy_Size  + Dst_Offset
      Src_Offset - Dst_Offset
      Dst_Offset - Dst_Offset
    EndIf
    
    Temp = Src_Size - Src_Offset
    If Copy_Size > Temp
      Copy_Size = Temp
    EndIf
    
    Temp = Dst_Size - Dst_Offset
    If Copy_Size > Temp
      Copy_Size = Temp
    EndIf
    
    If Copy_Size > 0
      CopyMemory(*Src+Src_Offset, *Dst+Dst_Offset, Copy_Size)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### Copies (MoveMemory) a specified amount of data (Copy_Size) from the source to the destination.
  ; #### It cuts everything, to prevent memory violations
  Procedure Range_Move(*Src, Src_Offset.q, *Dst, Dst_Offset.q, Copy_Size.q, Src_Size.q=-1, Dst_Size.q=-1)
    Protected Temp.q
    If Not *Src
      ProcedureReturn #False
    EndIf
    
    If Not *Dst
      ProcedureReturn #False
    EndIf
    
    If Src_Size = -1
      Src_Size.q = MemorySize(*Src)
    EndIf
    If Dst_Size = -1
      Dst_Size.q = MemorySize(*Dst)
    EndIf
    
    If Src_Offset < 0
      Copy_Size  + Src_Offset
      Dst_Offset - Src_Offset
      Src_Offset - Src_Offset
    EndIf
    
    If Dst_Offset < 0
      Copy_Size  + Dst_Offset
      Src_Offset - Dst_Offset
      Dst_Offset - Dst_Offset
    EndIf
    
    Temp = Src_Size - Src_Offset
    If Copy_Size > Temp
      Copy_Size = Temp
    EndIf
    
    Temp = Dst_Size - Dst_Offset
    If Copy_Size > Temp
      Copy_Size = Temp
    EndIf
    
    If Copy_Size > 0
      MoveMemory(*Src+Src_Offset, *Dst+Dst_Offset, Copy_Size)
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; #### Mirrors the memory, usable for little/big endian switching
  Procedure Mirror(*Memory, Size)
    Protected Elements, i
    Protected Temp.a, *A.Ascii, *B.Ascii
    
    If Not *Memory
      ProcedureReturn #False
    EndIf
    
    If Size < 1
      ProcedureReturn #True
    EndIf
    
    Elements = Size/2
    *A = *Memory
    *B = *Memory + Size - 1
    
    For i = 0 To Elements - 1
      Temp = *A\a
      *A\a = *B\a
      *B\a = Temp
      *A + 1
      *B - 1
    Next
    
    ProcedureReturn #True
  EndProcedure
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 246
; FirstLine = 201
; Folding = -
; EnableXP
; DisableDebugger