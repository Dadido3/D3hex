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

DeclareModule Constants
  EnableExplicit
  ; ################################################### Constants ###################################################
  Enumeration
    #Data_Raw
    #Integer_U_8    ; = #PB_Ascii
    #Integer_S_8    ; = #PB_Byte
    #Integer_U_16   ; = #PB_Unicode
    #Integer_S_16   ; = #PB_Word
    #Integer_U_32   ; = #PB_Long (Unsigned)
    #Integer_S_32   ; = #PB_Long
    #Integer_U_64   ; = #PB_Quad (Unsigned)
    #Integer_S_64   ; = #PB_Quad
    #Float_32       ; = #PB_Float
    #Float_64       ; = #PB_Double
    #String_Ascii
    #String_UTF8
    #String_UTF16
    #String_UTF32
    #String_UCS2
    #String_UCS4
  EndEnumeration
  
  Enumeration ; Image Pixelformat. Number is in bpp
    #PixelFormat_1_Gray
    #PixelFormat_1_Indexed
    #PixelFormat_2_Gray
    #PixelFormat_2_Indexed
    #PixelFormat_4_Gray
    #PixelFormat_4_Indexed
    #PixelFormat_8_Gray
    #PixelFormat_8_Indexed
    #PixelFormat_16_Gray
    #PixelFormat_16_RGB_555
    #PixelFormat_16_RGB_565
    #PixelFormat_16_ARGB_1555
    #PixelFormat_16_Indexed
    #PixelFormat_24_RGB
    #PixelFormat_24_BGR
    #PixelFormat_32_ARGB
    #PixelFormat_32_ABGR
  EndEnumeration
  
  #Metadata_Readable   = %00000001
  #Metadata_Writeable  = %00000010
  #Metadata_Executable = %00000100
  #Metadata_Changed    = %01000000
  #Metadata_NoError    = %10000000
  
  Enumeration
    ; #### Add custom global drag and drop constants here
    
    #DragDrop_Private_Node_New      ; A new node is being dragged
  EndEnumeration
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Constants
  
EndModule

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 46
; FirstLine = 26
; EnableUnicode
; EnableXP