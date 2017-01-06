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
; 
; 
; 
; ###################################################################################################################
; ##################################################### Public ######################################################
; ###################################################################################################################

DeclareModule Helper
  EnableExplicit
  ; ################################################### Constants ###################################################
  
  ; ################################################### Macros ######################################################
  Macro Line(x, y, Width, Height, Color)
    LineXY((x), (y), (x)+(Width), (y)+(Height), (Color))
  EndMacro
  
  ; ################################################### Functions ###################################################
  Declare.s SHGetFolderPath(CSIDL)
  
  Declare.q Quad_Divide_Floor(A.q, B.q)
  Declare.q Quad_Divide_Ceil(A.q, B.q)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Helper
  
  ; ################################################### Structures ##################################################
  
  
  
  
  ; ################################################### Procedures ##################################################
  Procedure.s SHGetFolderPath(CSIDL)
    Protected *String = AllocateMemory(#MAX_PATH+1)
    SHGetFolderPath_(0, CSIDL, #Null, 0, *String)
    Protected String.s = PeekS(*String)
    FreeMemory(*String)
    ProcedureReturn String
  EndProcedure
  
  ; #### Works perfectly, A and B can be positive or negative. B must not be zero!
  Procedure.q Quad_Divide_Floor(A.q, B.q)
    Protected Temp.q = A / B
    If (((a ! b) < 0) And (a % b <> 0))
      ProcedureReturn Temp - 1
    Else
      ProcedureReturn Temp
    EndIf
  EndProcedure
  
  ; #### Works perfectly, A and B can be positive or negative. B must not be zero!
  Procedure.q Quad_Divide_Ceil(A.q, B.q)
    Protected Temp.q = A / B
    If (((a ! b) >= 0) And (a % b <> 0))
      ProcedureReturn Temp + 1
    Else
      ProcedureReturn Temp
    EndIf
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 45
; FirstLine = 9
; Folding = -
; EnableUnicode
; EnableXP