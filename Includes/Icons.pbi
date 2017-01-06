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

DeclareModule Icons
  EnableExplicit
  ; ################################################### Load Icons ##################################################
  Global Icon_New = CatchImage(#PB_Any, ?Icon_New)
  Global Icon_Save = CatchImage(#PB_Any, ?Icon_Save)
  Global Icon_SaveAs = CatchImage(#PB_Any, ?Icon_SaveAs)
  Global Icon_Open_File = CatchImage(#PB_Any, ?Icon_Open_File)
  Global Icon_Undo = CatchImage(#PB_Any, ?Icon_Undo)
  Global Icon_Redo = CatchImage(#PB_Any, ?Icon_Redo)
  Global Icon_Cut = CatchImage(#PB_Any, ?Icon_Cut)
  Global Icon_Copy = CatchImage(#PB_Any, ?Icon_Copy)
  Global Icon_Paste = CatchImage(#PB_Any, ?Icon_Paste)
  Global Icon_Select_All = CatchImage(#PB_Any, ?Icon_Select_All)
  Global Icon_Open_Process = CatchImage(#PB_Any, ?Icon_Open_Process)
  Global Icon_Open_Clipboard = CatchImage(#PB_Any, ?Icon_Open_Clipboard)
  Global Icon_Open_Random = CatchImage(#PB_Any, ?Icon_Open_Random)
  Global Icon_Open_Network_Terminal = CatchImage(#PB_Any, ?Icon_Open_Network_Terminal)
  Global Icon_Node_Editor = CatchImage(#PB_Any, ?Icon_Node_Editor)
  Global Icon_Node_Clear_Config = CatchImage(#PB_Any, ?Icon_Node_Clear_Config)
  Global Icon_Node_Load_Config = CatchImage(#PB_Any, ?Icon_Node_Load_Config)
  Global Icon_Node_Save_Config = CatchImage(#PB_Any, ?Icon_Node_Save_Config)
  Global Icon_Close = CatchImage(#PB_Any, ?Icon_Close)
  Global Icon_Resize = CatchImage(#PB_Any, ?Icon_Resize)
  Global Icon_Hilbert = CatchImage(#PB_Any, ?Icon_Hilbert)
  Global Icon_Gear = CatchImage(#PB_Any, ?Icon_Gear)
  Global Icon_Grid = CatchImage(#PB_Any, ?Icon_Grid)
  Global Icon_Search = CatchImage(#PB_Any, ?Icon_Search)
  Global Icon_Search_Continue = CatchImage(#PB_Any, ?Icon_Search_Continue)
  Global Icon_Goto = CatchImage(#PB_Any, ?Icon_Goto)
  Global Icon_Refresh = CatchImage(#PB_Any, ?Icon_Refresh)
  Global Icon_Automatic = CatchImage(#PB_Any, ?Icon_Automatic)
  
  ; ################################################### Data Sections ###############################################
  DataSection
    Icon_New: : IncludeBinary "../Data/Icons/New.png"
    Icon_Save: : IncludeBinary "../Data/Icons/Save.png"
    Icon_SaveAs: : IncludeBinary "../Data/Icons/SaveAs.png"
    Icon_Open_File: : IncludeBinary "../Data/Icons/Open_File.png"
    Icon_Undo: : IncludeBinary "../Data/Icons/Undo.png"
    Icon_Redo: : IncludeBinary "../Data/Icons/Redo.png"
    Icon_Cut: : IncludeBinary "../Data/Icons/Cut.png"
    Icon_Copy: : IncludeBinary "../Data/Icons/Copy.png"
    Icon_Paste: : IncludeBinary "../Data/Icons/Paste.png"
    Icon_Select_All: : IncludeBinary "../Data/Icons/Select_All.png"
    Icon_Open_Process: : IncludeBinary "../Data/Icons/Open_Process.png"
    Icon_Open_Clipboard: : IncludeBinary "../Data/Icons/Open_Clipboard.png"
    Icon_Open_Random: : IncludeBinary "../Data/Icons/Open_Random.png"
    Icon_Open_Network_Terminal: : IncludeBinary "../Data/Icons/Open_Network_Terminal.png"
    Icon_Node_Editor: : IncludeBinary "../Data/Icons/Node_Editor.png"
    Icon_Node_Clear_Config: : IncludeBinary "../Data/Icons/Node_Clear_Config.png"
    Icon_Node_Load_Config: : IncludeBinary "../Data/Icons/Node_Load_Config.png"
    Icon_Node_Save_Config: : IncludeBinary "../Data/Icons/Node_Save_Config.png"
    Icon_Close: : IncludeBinary "../Data/Icons/Close.png"
    Icon_Resize: : IncludeBinary "../Data/Icons/Resize.png"
    Icon_Hilbert: : IncludeBinary "../Data/Icons/Hilbert.png"
    Icon_Gear: : IncludeBinary "../Data/Icons/Gear.png"
    Icon_Grid: : IncludeBinary "../Data/Icons/Grid.png"
    Icon_Search: : IncludeBinary "../Data/Icons/Search.png"
    Icon_Search_Continue: : IncludeBinary "../Data/Icons/Search_Continue.png"
    Icon_Goto: : IncludeBinary "../Data/Icons/Goto.png"
    Icon_Refresh: : IncludeBinary "../Data/Icons/Refresh.png"
    Icon_Automatic: : IncludeBinary "../Data/Icons/Automatic.png"
  EndDataSection
  
EndDeclareModule

; ###################################################################################################################
; ##################################################### Private #####################################################
; ###################################################################################################################

Module Icons
  
EndModule

; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 93
; FirstLine = 56
; EnableUnicode
; EnableXP