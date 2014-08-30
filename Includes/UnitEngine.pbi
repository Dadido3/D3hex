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

; ##################################################### Constants ###################################################

Enumeration
  #UnitEngine_SiPrefix
  #UnitEngine_BinaryPrefix
EndEnumeration

Enumeration
  #UnitEngine_SiPrefix_Yocto
  #UnitEngine_SiPrefix_Zepto
  #UnitEngine_SiPrefix_Atto
  #UnitEngine_SiPrefix_Femto
  #UnitEngine_SiPrefix_Pico
  #UnitEngine_SiPrefix_Nano
  #UnitEngine_SiPrefix_Micro
  #UnitEngine_SiPrefix_Milli
  #UnitEngine_SiPrefix_Centi
  #UnitEngine_SiPrefix_Deci
  
  #UnitEngine_SiPrefix_None
  
  #UnitEngine_SiPrefix_Deca
  #UnitEngine_SiPrefix_Hecto
  #UnitEngine_SiPrefix_Kilo
  #UnitEngine_SiPrefix_Mega
  #UnitEngine_SiPrefix_Giga
  #UnitEngine_SiPrefix_Tera
  #UnitEngine_SiPrefix_Peta
  #UnitEngine_SiPrefix_Exa
  #UnitEngine_SiPrefix_Zetta
  #UnitEngine_SiPrefix_Yotta
  
  #UnitEngine_SiPrefix_Amount
EndEnumeration

Enumeration
  #UnitEngine_BinaryPrefix_None
  
  #UnitEngine_BinaryPrefix_Kibi
  #UnitEngine_BinaryPrefix_Mebi
  #UnitEngine_BinaryPrefix_Gibi
  #UnitEngine_BinaryPrefix_Tebi
  #UnitEngine_BinaryPrefix_Pebi
  #UnitEngine_BinaryPrefix_Exbi
  #UnitEngine_BinaryPrefix_Zebi
  #UnitEngine_BinaryPrefix_Yobi
  
  #UnitEngine_BinaryPrefix_Amount
EndEnumeration

; ##################################################### Structures ##################################################

Structure UnitEngine_Main
  
EndStructure
Global UnitEngine_Main.UnitEngine_Main

Structure UnitEngine_SiPrefix
  Exponent.i  ; (Factor = 10^Exponent)
  
  Symbol.s{2}
EndStructure
Global Dim UnitEngine_SiPrefix.UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Amount-1)

Structure UnitEngine_BinaryPrefix
  Exponent.i  ; (Factor = 1024^Exponent)
  
  Symbol.s{2}
EndStructure
Global Dim UnitEngine_BinaryPrefix.UnitEngine_BinaryPrefix(#UnitEngine_BinaryPrefix_Amount-1)

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

; #### SI Prefixes
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Yocto)\Exponent  = -24
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Yocto)\Symbol    = "y"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Zepto)\Exponent  = -21
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Zepto)\Symbol    = "z"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Atto)\Exponent   = -18
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Atto)\Symbol     = "a"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Femto)\Exponent  = -15
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Femto)\Symbol    = "f"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Pico)\Exponent   = -12
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Pico)\Symbol     = "p"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Nano)\Exponent   = -9
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Nano)\Symbol     = "n"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Micro)\Exponent  = -6
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Micro)\Symbol    = "µ"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Milli)\Exponent  = -3
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Milli)\Symbol    = "m"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Centi)\Exponent  = -2
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Centi)\Symbol    = "c"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Deci)\Exponent   = -1
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Deci)\Symbol     = "d"

UnitEngine_SiPrefix(#UnitEngine_SiPrefix_None)\Exponent   = 0
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_None)\Symbol     = ""

UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Deca)\Exponent   = 1
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Deca)\Symbol     = "da"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Hecto)\Exponent  = 2
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Hecto)\Symbol    = "h"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Kilo)\Exponent   = 3
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Kilo)\Symbol     = "k"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Mega)\Exponent   = 6
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Mega)\Symbol     = "M"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Giga)\Exponent   = 9
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Giga)\Symbol     = "G"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Tera)\Exponent   = 12
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Tera)\Symbol     = "T"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Peta)\Exponent   = 15
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Peta)\Symbol     = "P"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Exa)\Exponent    = 18
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Exa)\Symbol      = "E"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Zetta)\Exponent  = 21
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Zetta)\Symbol    = "Z"
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Yotta)\Exponent  = 24
UnitEngine_SiPrefix(#UnitEngine_SiPrefix_Yotta)\Symbol    = "Y"

; #### Binary Prefixes
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_None)\Exponent = 0
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_None)\Symbol   = ""

UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Kibi)\Exponent = 1
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Kibi)\Symbol   = "Ki"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Mebi)\Exponent = 2
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Mebi)\Symbol   = "Mi"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Gibi)\Exponent = 3
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Gibi)\Symbol   = "Gi"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Tebi)\Exponent = 4
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Tebi)\Symbol   = "Ti"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Pebi)\Exponent = 5
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Pebi)\Symbol   = "Pi"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Exbi)\Exponent = 6
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Exbi)\Symbol   = "Ei"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Zebi)\Exponent = 7
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Zebi)\Symbol   = "Zi"
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Yobi)\Exponent = 8
UnitEngine_SiPrefix(#UnitEngine_BinaryPrefix_Yobi)\Symbol   = "Yi"


; ##################################################### Declares ####################################################

; ##################################################### Macros ######################################################

; ##################################################### Procedures ##################################################

Procedure.s UnitEngine_Format_Integer(Value.q, Prefix.i, Unit.s, NbDecimals.i=10)
  Protected Value_String.s
  Protected Factor.d
  Protected i
  
  Select Prefix
    Case #UnitEngine_SiPrefix
      For i = #UnitEngine_SiPrefix_Amount-1 To 0 Step -1
        Factor = Pow(10, UnitEngine_SiPrefix(i)\Exponent)
        If Value / Factor >= 1
          ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + UnitEngine_SiPrefix(i)\Symbol + Unit
        EndIf
      Next
      i = 0
      Factor = Pow(10, UnitEngine_SiPrefix(i)\Exponent)
      ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + UnitEngine_SiPrefix(i)\Symbol + Unit
      
    Case #UnitEngine_BinaryPrefix
      For i = #UnitEngine_BinaryPrefix_Amount-1 To 0 Step -1
        Factor = Pow(1024, UnitEngine_BinaryPrefix(i)\Exponent)
        If Value / Factor >= 1
          ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + UnitEngine_BinaryPrefix(i)\Symbol + Unit
        EndIf
      Next
      i = 0
      Factor = Pow(1024, UnitEngine_BinaryPrefix(i)\Exponent)
      ProcedureReturn RTrim(RTrim(StrD(Value / Factor, NbDecimals),"0"),".") + " " + UnitEngine_BinaryPrefix(i)\Symbol + Unit
      
  EndSelect
EndProcedure

; ##################################################### Initialisation ##############################################

; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.30 (Windows - x64)
; CursorPosition = 183
; FirstLine = 159
; Folding = -
; EnableUnicode
; EnableXP