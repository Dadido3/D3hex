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

; ##################################################### Includes ####################################################

; ##################################################### Prototypes ##################################################

; ##################################################### Structures ##################################################

; ##################################################### Constants ###################################################

; ##################################################### Structures ##################################################

Structure Crash_Main
  
EndStructure
Global Crash_Main.Crash_Main

; ##################################################### Variables ###################################################

; ##################################################### Icons ... ###################################################

; ##################################################### Init ########################################################

; ##################################################### Declares ####################################################

; ##################################################### Procedures ##################################################

Procedure Crash_Handler()
  OpenConsole()
  
  PrintN("A program crash was detected:")
  PrintN("")
  PrintN("Error Message:   " + ErrorMessage())
  PrintN("Error Code:      " + Str(ErrorCode()))
  PrintN("Code Address:    " + Str(ErrorAddress()))
  If ErrorCode() = #PB_OnError_InvalidMemory
    PrintN("Target Address:  " + Str(ErrorTargetAddress()))
  EndIf
  PrintN("Thread:          " + Str(#PB_Compiler_Thread))
  PrintN("")
  If ErrorLine() = -1
    PrintN("Sourcecode line: Enable OnError lines support to get code line information.")
  Else
    PrintN("Sourcecode line: " + Str(ErrorLine()))
    PrintN("Sourcecode file: " + ErrorFile())
  EndIf
  
  PrintN("")
  PrintN("Register content:")
  
  CompilerSelect #PB_Compiler_Processor
    CompilerCase #PB_Processor_x86
      PrintN("EAX = " + Str(ErrorRegister(#PB_OnError_EAX)))
      PrintN("EBX = " + Str(ErrorRegister(#PB_OnError_EBX)))
      PrintN("ECX = " + Str(ErrorRegister(#PB_OnError_ECX)))
      PrintN("EDX = " + Str(ErrorRegister(#PB_OnError_EDX)))
      PrintN("EBP = " + Str(ErrorRegister(#PB_OnError_EBP)))
      PrintN("ESI = " + Str(ErrorRegister(#PB_OnError_ESI)))
      PrintN("EDI = " + Str(ErrorRegister(#PB_OnError_EDI)))
      PrintN("ESP = " + Str(ErrorRegister(#PB_OnError_ESP)))
      
    CompilerCase #PB_Processor_x64
      PrintN("RAX = " + Str(ErrorRegister(#PB_OnError_RAX)))
      PrintN("RBX = " + Str(ErrorRegister(#PB_OnError_RBX)))
      PrintN("RCX = " + Str(ErrorRegister(#PB_OnError_RCX)))
      PrintN("RDX = " + Str(ErrorRegister(#PB_OnError_RDX)))
      PrintN("RBP = " + Str(ErrorRegister(#PB_OnError_RBP)))
      PrintN("RSI = " + Str(ErrorRegister(#PB_OnError_RSI)))
      PrintN("RDI = " + Str(ErrorRegister(#PB_OnError_RDI)))
      PrintN("RSP = " + Str(ErrorRegister(#PB_OnError_RSP)))
      PrintN("R8  = " + Str(ErrorRegister(#PB_OnError_R8)))
      PrintN("R9  = " + Str(ErrorRegister(#PB_OnError_R9)))
      PrintN("R10 = " + Str(ErrorRegister(#PB_OnError_R10)))
      PrintN("R11 = " + Str(ErrorRegister(#PB_OnError_R11)))
      PrintN("R12 = " + Str(ErrorRegister(#PB_OnError_R12)))
      PrintN("R13 = " + Str(ErrorRegister(#PB_OnError_R13)))
      PrintN("R14 = " + Str(ErrorRegister(#PB_OnError_R14)))
      PrintN("R15 = " + Str(ErrorRegister(#PB_OnError_R15)))
      
  CompilerEndSelect
  
  Input()
  
  End
EndProcedure

CompilerIf #PB_Compiler_Debugger = #False
  OnErrorCall(@Crash_Handler())
CompilerEndIf

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 3
; Folding = -
; EnableUnicode
; EnableXP