
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

OnErrorCall(@Crash_Handler())

; ##################################################### Initialisation ##############################################



; ##################################################### Data Sections ###############################################

; IDE Options = PureBasic 5.21 LTS Beta 1 (Windows - x64)
; CursorPosition = 21
; FirstLine = 43
; Folding = -
; EnableUnicode
; EnableXP