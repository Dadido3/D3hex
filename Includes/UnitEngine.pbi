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

DeclareModule UnitEngine
  EnableExplicit
  ; ################################################### Constants ###################################################
  Enumeration
    #SiPrefix
    #BinaryPrefix
  EndEnumeration
  
  Enumeration
    #SiPrefix_Yocto
    #SiPrefix_Zepto
    #SiPrefix_Atto
    #SiPrefix_Femto
    #SiPrefix_Pico
    #SiPrefix_Nano
    #SiPrefix_Micro
    #SiPrefix_Milli
    #SiPrefix_Centi
    #SiPrefix_Deci
    
    #SiPrefix_None
    
    #SiPrefix_Deca
    #SiPrefix_Hecto
    #SiPrefix_Kilo
    #SiPrefix_Mega
    #SiPrefix_Giga
    #SiPrefix_Tera
    #SiPrefix_Peta
    #SiPrefix_Exa
    #SiPrefix_Zetta
    #SiPrefix_Yotta
    
    #SiPrefix_Amount
  EndEnumeration
  
  Enumeration
    #BinaryPrefix_None
    
    #BinaryPrefix_Kibi
    #BinaryPrefix_Mebi
    #BinaryPrefix_Gibi
    #BinaryPrefix_Tebi
    #BinaryPrefix_Pebi
    #BinaryPrefix_Exbi
    #BinaryPrefix_Zebi
    #BinaryPrefix_Yobi
    
    #BinaryPrefix_Amount
  EndEnumeration
  
  ; ################################################### Functions ###################################################
  Declare.s Format_Integer(Value.q, Prefix.i, Unit.s, NbDecimals.i=10)
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module UnitEngine
  
  ; ################################################### Structures ##################################################
  Structure Main
    
  EndStructure
  Global Main.Main
  
  Structure SiPrefix
    Exponent.i  ; (Factor = 10^Exponent)
    
    Symbol.s{2}
  EndStructure
  Global Dim SiPrefix.SiPrefix(#SiPrefix_Amount-1)
  
  Structure BinaryPrefix
    Exponent.i  ; (Factor = 1024^Exponent)
    
    Symbol.s{2}
  EndStructure
  Global Dim BinaryPrefix.BinaryPrefix(#BinaryPrefix_Amount-1)
  
  ; ##################################################### Init ########################################################
  ; #### SI Prefixes
  SiPrefix(#SiPrefix_Yocto)\Exponent  = -24
  SiPrefix(#SiPrefix_Yocto)\Symbol    = "y"
  SiPrefix(#SiPrefix_Zepto)\Exponent  = -21
  SiPrefix(#SiPrefix_Zepto)\Symbol    = "z"
  SiPrefix(#SiPrefix_Atto)\Exponent   = -18
  SiPrefix(#SiPrefix_Atto)\Symbol     = "a"
  SiPrefix(#SiPrefix_Femto)\Exponent  = -15
  SiPrefix(#SiPrefix_Femto)\Symbol    = "f"
  SiPrefix(#SiPrefix_Pico)\Exponent   = -12
  SiPrefix(#SiPrefix_Pico)\Symbol     = "p"
  SiPrefix(#SiPrefix_Nano)\Exponent   = -9
  SiPrefix(#SiPrefix_Nano)\Symbol     = "n"
  SiPrefix(#SiPrefix_Micro)\Exponent  = -6
  SiPrefix(#SiPrefix_Micro)\Symbol    = "µ"
  SiPrefix(#SiPrefix_Milli)\Exponent  = -3
  SiPrefix(#SiPrefix_Milli)\Symbol    = "m"
  SiPrefix(#SiPrefix_Centi)\Exponent  = -2
  SiPrefix(#SiPrefix_Centi)\Symbol    = "c"
  SiPrefix(#SiPrefix_Deci)\Exponent   = -1
  SiPrefix(#SiPrefix_Deci)\Symbol     = "d"
  
  SiPrefix(#SiPrefix_None)\Exponent   = 0
  SiPrefix(#SiPrefix_None)\Symbol     = ""
  
  SiPrefix(#SiPrefix_Deca)\Exponent   = 1
  SiPrefix(#SiPrefix_Deca)\Symbol     = "da"
  SiPrefix(#SiPrefix_Hecto)\Exponent  = 2
  SiPrefix(#SiPrefix_Hecto)\Symbol    = "h"
  SiPrefix(#SiPrefix_Kilo)\Exponent   = 3
  SiPrefix(#SiPrefix_Kilo)\Symbol     = "k"
  SiPrefix(#SiPrefix_Mega)\Exponent   = 6
  SiPrefix(#SiPrefix_Mega)\Symbol     = "M"
  SiPrefix(#SiPrefix_Giga)\Exponent   = 9
  SiPrefix(#SiPrefix_Giga)\Symbol     = "G"
  SiPrefix(#SiPrefix_Tera)\Exponent   = 12
  SiPrefix(#SiPrefix_Tera)\Symbol     = "T"
  SiPrefix(#SiPrefix_Peta)\Exponent   = 15
  SiPrefix(#SiPrefix_Peta)\Symbol     = "P"
  SiPrefix(#SiPrefix_Exa)\Exponent    = 18
  SiPrefix(#SiPrefix_Exa)\Symbol      = "E"
  SiPrefix(#SiPrefix_Zetta)\Exponent  = 21
  SiPrefix(#SiPrefix_Zetta)\Symbol    = "Z"
  SiPrefix(#SiPrefix_Yotta)\Exponent  = 24
  SiPrefix(#SiPrefix_Yotta)\Symbol    = "Y"
  
  ; #### Binary Prefixes
  SiPrefix(#BinaryPrefix_None)\Exponent = 0
  SiPrefix(#BinaryPrefix_None)\Symbol   = ""
  
  SiPrefix(#BinaryPrefix_Kibi)\Exponent = 1
  SiPrefix(#BinaryPrefix_Kibi)\Symbol   = "Ki"
  SiPrefix(#BinaryPrefix_Mebi)\Exponent = 2
  SiPrefix(#BinaryPrefix_Mebi)\Symbol   = "Mi"
  SiPrefix(#BinaryPrefix_Gibi)\Exponent = 3
  SiPrefix(#BinaryPrefix_Gibi)\Symbol   = "Gi"
  SiPrefix(#BinaryPrefix_Tebi)\Exponent = 4
  SiPrefix(#BinaryPrefix_Tebi)\Symbol   = "Ti"
  SiPrefix(#BinaryPrefix_Pebi)\Exponent = 5
  SiPrefix(#BinaryPrefix_Pebi)\Symbol   = "Pi"
  SiPrefix(#BinaryPrefix_Exbi)\Exponent = 6
  SiPrefix(#BinaryPrefix_Exbi)\Symbol   = "Ei"
  SiPrefix(#BinaryPrefix_Zebi)\Exponent = 7
  SiPrefix(#BinaryPrefix_Zebi)\Symbol   = "Zi"
  SiPrefix(#BinaryPrefix_Yobi)\Exponent = 8
  SiPrefix(#BinaryPrefix_Yobi)\Symbol   = "Yi"
  
  ; ##################################################### Procedures ##################################################
  Procedure.s Format_Integer(Value.q, Prefix.i, Unit.s, NbDecimals.i=10)
    Protected Value_String.s
    Protected Factor.d
    Protected i
    
    Select Prefix
      Case #SiPrefix
        For i = #SiPrefix_Amount-1 To 0 Step -1
          Factor = Pow(10, SiPrefix(i)\Exponent)
          If Value / Factor >= 1
            ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + SiPrefix(i)\Symbol + Unit
          EndIf
        Next
        i = 0
        Factor = Pow(10, SiPrefix(i)\Exponent)
        ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + SiPrefix(i)\Symbol + Unit
        
      Case #BinaryPrefix
        For i = #BinaryPrefix_Amount-1 To 0 Step -1
          Factor = Pow(1024, BinaryPrefix(i)\Exponent)
          If Value / Factor >= 1
            ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + BinaryPrefix(i)\Symbol + Unit
          EndIf
        Next
        i = 0
        Factor = Pow(1024, BinaryPrefix(i)\Exponent)
        ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + BinaryPrefix(i)\Symbol + Unit
        
    EndSelect
  EndProcedure
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 84
; FirstLine = 49
; Folding = -
; EnableUnicode
; EnableXP