;-TOP
; Comment   : Create custom PB gadget
; Author    : eddy
; Web       : http://www.purebasic.fr/english/viewtopic.php?f=12&p=418722
; File:     : CustomGadget.pbi
; Version   : v0.7

DeclareModule CustomGadget
  Prototype Events(*Params, EventWindow, EventGadget, EventType)
  Prototype Call(*Gadget)
  Prototype CallByItem(*Gadget, Item)
  Prototype Resize(*Gadget, x.l, y.l, w.l, h.l)
  Prototype.i GetInteger(*Gadget)
  Prototype SetInteger(*Gadget, Value)
  Prototype.s GetString(*Gadget)
  Prototype SetString(*Gadget, Value$)
  Prototype.s GetStringByItem(*Gadget, Item)
  Prototype SetStringByItem(*Gadget, Item, Value$)
  Prototype.i GetIntegerByAttribute(*Gadget, Attribute)
  Prototype SetIntegerByAttribute(*Gadget, Attribute, Value)
  Prototype.i GetIntegerByItem(*Gadget, Item)
  Prototype SetIntegerByItemAttribute(*Gadget, Item, Attribute, Value, Column=#PB_Ignore)
  Prototype.i GetIntegerByItemAttribute(*Gadget, Item, Attribute, Column=#PB_Ignore)
  Prototype SetIntegerByItem(*Gadget, Item, Value)
  Structure GADGET_VT
    GadgetType.l    ; gadget type (used by GadgetType command)
    SizeOf.l        ; Size of structure
    
    *GadgetCallback
    *FreeGadget.Call
    *GetGadgetState.GetInteger
    *SetGadgetState.SetInteger
    *GetGadgetText.GetString
    *SetGadgetText.SetString
    *AddGadgetItem2
    *AddGadgetItem3
    *RemoveGadgetItem.CallByItem
    *ClearGadgetItems.Call
    *ResizeGadget.Resize
    *CountGadgetItems.GetInteger
    *GetGadgetItemState.GetIntegerByItem
    *SetGadgetItemState.SetIntegerByItem
    *GetGadgetItemText.GetStringByItem
    *SetGadgetItemText.SetStringByItem
    *OpenGadgetList2
    *GadgetX.GetInteger
    *GadgetY.GetInteger
    *GadgetWidth.GetInteger
    *GadgetHeight.GetInteger
    *HideGadget.SetInteger
    *AddGadgetColumn
    *RemoveGadgetColumn
    *GetGadgetAttribute.GetIntegerByAttribute
    *SetGadgetAttribute.SetIntegerByAttribute
    *GetGadgetItemAttribute.GetIntegerByItemAttribute
    *SetGadgetItemAttribute.SetIntegerByItemAttribute
    *SetGadgetColor
    *GetGadgetColor
    *SetGadgetItemColor2
    *GetGadgetItemColor2
    *SetGadgetItemData
    *GetGadgetItemData
    *GetRequiredSize
    *SetActiveGadget
    *GetGadgetFont
    *SetGadgetFont
    *SetGadgetItemImage
  EndStructure
  Structure GADGET
    *Handle             ; gadget OS handle
    *VT.GADGET_VT       ; gadget commands
    *UserData           ; gadget data (used by SetGadgetData)
    *OldCallback        ; original OS callback  (used by purebasic CALLBACK)
    Daten.i[4]          ; .....
  EndStructure
  Structure GADGET_MANAGER
    GadgetCount.i       ;gadget counter (optional)
    *OldVT.GADGET_VT    ;old commands pointers
    *NewVT.GADGET_VT    ;new commands pointers
    Map *GadgetParams() ;gadget custom parameters
  EndStructure
  
  Declare ManageGadgetCommands(*manager.GADGET_MANAGER, Gadget, State)
  Declare ManageGadget(*manager.GADGET_MANAGER, Gadget, *params, GadgetType)
  Declare UnmanageGadget(*manager.GADGET_MANAGER, Gadget)
EndDeclareModule

Module CustomGadget
  EnableExplicit
  Procedure ManageGadgetCommands(*manager.GADGET_MANAGER, Gadget, State)
    Protected *gadget.GADGET=IsGadget(Gadget)
    If State
      *gadget\VT=*manager\NewVT
    Else
      *gadget\VT=*manager\OldVT
    EndIf
  EndProcedure
  Procedure ManageGadget(*manager.GADGET_MANAGER, Gadget, *params, GadgetType)
    Protected *gadget.GADGET=IsGadget(Gadget)
    With *manager
      If \OldVT=#Null And \NewVT=#Null
        ; define manager: custom events, custom VT, custom gadget type
        \OldVT=*gadget\VT
        \NewVT=AllocateMemory(SizeOf(GADGET_VT))
        CopyMemory(\OldVT, \NewVT, SizeOf(GADGET_VT))
        \NewVT\GadgetType=GadgetType
      EndIf
      ; use custom PB commands
      ManageGadgetCommands(*manager, Gadget, #True)
      
      ; save gadget params and increment counter
      \GadgetParams(""+*gadget)=*params
      \GadgetCount+1
    EndWith
  EndProcedure
  Procedure UnmanageGadget(*manager.GADGET_MANAGER, Gadget)
    Protected *gadget.GADGET=IsGadget(Gadget)
    With *manager
      \GadgetCount-1
      Protected *params=*manager\GadgetParams()
      DeleteMapElement(*manager\GadgetParams(), ""+*Gadget)
      If *params
        FreeStructure(*params)
      EndIf
    EndWith
  EndProcedure
EndModule
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 68
; FirstLine = 67
; Folding = -
; EnableUnicode
; EnableXP