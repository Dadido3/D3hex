
;|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;| Title            : TabBarGadget
;| Version          : 1.3.0 (2012-09-01)
;| Copyright        : UnionBytes
;|                    (Martin Guttmann alias STARGÅTE)
;| PureBasic        : 4.60 +
;| String-Format    : Ascii, Unicode
;| Operating-System : All
;| Processor        : x86, x64
;| Description      : Gadget for displaying and using tabs like in the browser
;|__________________________________________________________________________________________________
;|
;| Titel            : Registerkartenleisten-Gadget
;| Beschreibung     : Gadget zum Darstellen und Benutzen von Registerkarten ähnlich wie im Browser
;|__________________________________________________________________________________________________



;EnableExplicit





;|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;-  1. Constants / Konstanten
;|__________________________________________________________________________________________________



; Attribute für das TabBarGadget
Enumeration
	#TabBarGadget_CloseButton     = 1<<0
	#TabBarGadget_NewTab          = 1<<1
	#TabBarGadget_TextCutting     = 1<<2
	#TabBarGadget_MirroredTabs    = 1<<3
	#TabBarGadget_Vertical        = 1<<4 ; für Später
	#TabBarGadget_NoTabMoving     = 1<<5
	#TabBarGadget_MultiLine       = 1<<6
	#TabBarGadget_BottomLine      = 1<<7
	#TabBarGadget_NormalTabLength = 1<<26 ; für Später
	#TabBarGadget_MaxTabLength    = 1<<27
	#TabBarGadget_MinTabLength    = 1<<28
	#TabBarGadget_TabRounding     = 1<<29
EndEnumeration

; Ereignisse von TabBarGadgetEvent
Enumeration
	#TabBarGadgetEvent_NewTab     = 1 ; ein neuer Tab wird angefordert
	#TabBarGadgetEvent_CloseTab   = 2 ; ein Tab soll geschlossen werden
	#TabBarGadgetEvent_Change     = 3 ; Der aktive Tab wurde geändert
	#TabBarGadgetEvent_TabSwapped = 4 ; Der aktive Tab wurde verschoben
EndEnumeration

; Positionskonstanten für "Item"-Befehle
Enumeration
	#TabBarGadgetItem_None        = -1
	#TabBarGadgetItem_NewTab      = -2
	#TabBarGadgetItem_Current     = -3
EndEnumeration


; Interne Konstanten
#TabBarGadget_NewItem         = 0
#TabBarGadget_Item            = 1
#TabBarGadget_AktiveItem      = 2
#TabBarGadget_PreviousArrow   = 1<<30
#TabBarGadget_NextArrow       = 1<<31
#TabBarGadgetItem_DisableFace = -1
#TabBarGadgetItem_NormalFace  = 0
#TabBarGadgetItem_HoverFace   = 1
#TabBarGadgetItem_ActiveFace  = 2
#TabBarGadgetItem_MoveFace    = 3





;|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;-  2. Structures / Strukturen
;|__________________________________________________________________________________________________



; Sortierter Eintrag für die Textkürzung
Structure TabBarGadgetSortedItem
	*Item.TabBarGadgetItem
	Len.i
EndStructure

; Farben für einen Eintrag
Structure TabBarGadgetItemColor
	Text.i       ; Textfarbe
	Background.i ; Hintergrundfarbe
EndStructure

Structure TabBarGadgetItemArea
	X.i
	Y.i
	Width.i
	Height.i
	Padding.i
EndStructure

; Registerkarte
Structure TabBarGadgetItem
	Text.s                      ; Text
	ShortText.s                 ; verkürzter Text
	Color.TabBarGadgetItemColor ; Farbattribute
	Image.i                     ; Image
	DataValue.i                 ; Datenwert
	Disabled.i                  ; Deaktiviert
	ToolTip.s
	Length.i                    ; Länge (TEMP)
	Row.i                       ; Zeile (TEMP)
	Position.i                  ; Position (TEMP)
	Visible.i                   ; Sichtbar und wird gezeichnet (TEMP)
	Face.i                      ; Aussehen (TEMP)
	Area.TabBarGadgetItemArea   ; Fläche die die Karte bedeckt (TEMP)
EndStructure

; Tooltips
Structure TabBarGadgetToolTip
	*Current                         ; Aktuelle ToolTip-Adresse
	*Old                             ; Alte ToolTip-Adresse
	ItemText.s                       ; Text für die Registerkarte
	NewText.s                        ; Text für die "Neu"-Registerkarte
	CloseText.s                      ; Text für den Schließen-Button
EndStructure


; Registerkartenleiste
Structure TabBarGadget
	Number.i                          ; #Nummer
	FontID.i                          ; Schrift
	DataValue.i                       ; Daten-Wert
	Attributes.i                      ; Attribute
	List	Item.TabBarGadgetItem()     ; Registerkarten
	NewTabItem.TabBarGadgetItem       ; "Neu"-Registerkarte
	*SelectedItem.TabBarGadgetItem    ; ausgewählte Registerkarte
	*MoveItem.TabBarGadgetItem        ; bewegte Registerkarte
	*HoverItem.TabBarGadgetItem       ; hervorgehobene Registerkarte
	HoverClose.i                      ; Schließenbutton hervorgehoben
	HoverArrow.i
	*ReadyToMoveItem.TabBarGadgetItem ; Registerkarte die bereit ist bewegt zu werden
	*LockedItem.TabBarGadgetItem      ; Registerkarte angeschlagen wurde (für Klicks)
	LockedClose.i                     ; Schließenbutton angeschlagen
	LockedArrow.i
	SaveMouseX.i                      ; gespeicherte Mausposition
	SaveMouseY.i
	MouseX.i                          ; X-Mausposition
	MouseY.i                          ; Y-Mausposition
	Event.i                           ; letztes Ereignis
	EventTab.i                        ; Registerkartenposition auf der das letzte Ereignis war
	Shift.i                           ; Verschiebung der Leiste
	FocusingSelectedTab.i             ; muss die ausgewählte Registerkarte fokussiert werden
	MaxLength.i                       ; maximal nutzbare Länge für Karten
	Length.i                          ; Länge aller sichtbaren Karten
	Radius.i                          ; Radius der Kartenrundung
	MinTabLength.i                    ; minimale Länge einer Karte
	MaxTabLength.i                    ; maximale Länge einer Karte
	NormalTabLength.i                 ; normale Länge einer Karte
	ToolTip.TabBarGadgetToolTip       ; ToolTip
	TabHeight.i
	Rows.i
	Resized.i
EndStructure

Structure TabBarGadgetRow
	Length.i
	Items.i
EndStructure

; Include für das Registerkartenleisten-Gadget
Structure TabBarGadgetInclude
	TabBarColor.i
	FaceColor.i
	HoverColorPlus.i
	ActivColorPlus.i
	BorderColor.i
	TextColor.i
	FontID.i
	Padding.i
	Margin.i
	ImageSpace.i
	CloseButtonSize.i
	ArrowWidth.i
	ArrowHeight.i
	Radius.i
	MinTabLength.i
	MaxTabLength.i
	NormalTabLength.i
	FadeOut.i
	WheelDirection.i
	RowDirection.i
EndStructure





;|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;-  3. Initializations / Initialisierungen
;|__________________________________________________________________________________________________



Global TabBarGadgetInclude.TabBarGadgetInclude

; Diese Werte können sowohl im Include, als auch im Hauptcode später über TabBarGadgetInclude\Feld geändert werden.
With TabBarGadgetInclude
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			\TabBarColor   = $FF<<24 | GetSysColor_(#COLOR_BTNFACE)
			\BorderColor   = $FF<<24 | GetSysColor_(#COLOR_3DSHADOW)
			\FaceColor     = $FF<<24 | GetSysColor_(#COLOR_BTNFACE)
			\TextColor     = $FF<<24 | GetSysColor_(#COLOR_BTNTEXT)
			\FontID        = GetGadgetFont(#PB_Default)
		CompilerDefault
			\TabBarColor   = $FFD0D0D0
			\BorderColor   = $FF808080
			\FaceColor     = $FFD0D0D0
			\TextColor     = $FF000000
			\FontID        = FontID(LoadFont(#PB_Any, "Arial", 8))
	CompilerEndSelect
	\HoverColorPlus    = $FF101010
	\ActivColorPlus    = $FF101010
	\Padding           = 6  ; Space from tab border to text
	\Margin            = 4  ; Space from tab to border
	\ImageSpace        = 3  ; Space from image zu text
	\CloseButtonSize   = 13 ; Size of the close cross
	\ArrowWidth        = 10 ; Width of the Arrow-Button in navigation
	\ArrowHeight       = 16 ; Height of the Arrow-Button in navigation
	\Radius            = 3  ; Radius of the edge of the tab
	\MinTabLength      = 0
	\MaxTabLength      = 32767
	\NormalTabLength   = 150
	\FadeOut           = 32 ; Length of fade out to the navi
	\WheelDirection    = 1
	\RowDirection      = 1
EndWith





;|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;-  4. Procedures & Macros / Prozeduren & Makros
;|__________________________________________________________________________________________________



;-  4.1 Private procedures for internal calculations ! Not for use !
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯


; Gitb die Adresse (ID) der Registerkarte zurück.
;   Position kann eine Konstante, Position oder ID sein.
Procedure.i TabBarGadget_ItemID(*TabBarGadget.TabBarGadget, Position.i) ; OK
	
	With *TabBarGadget
		
		Select Position
			Case #TabBarGadgetItem_Current
				If \SelectedItem
					ChangeCurrentElement(\Item(), \SelectedItem)
					ProcedureReturn @\Item()
				Else
					ProcedureReturn #Null
				EndIf
			Case #TabBarGadgetItem_NewTab
				ProcedureReturn @\NewTabItem
			Case #TabBarGadgetItem_None
				ProcedureReturn #Null
			Default 
				If Position >= 0 And Position < ListSize(\Item())
					ProcedureReturn SelectElement(\Item(), Position)
				ElseIf Position >= ListSize(\Item())
					ForEach \Item()
						If @\Item() = Position
							ProcedureReturn @\Item()
						EndIf
					Next
				EndIf
		EndSelect
		
	EndWith
	
EndProcedure



; Gibt die Ressourcen einer Registerkarte wieder frei.
Procedure TabBarGadget_ClearItem(*TabBarGadget.TabBarGadget, *Item.TabBarGadgetItem) ; OK
	
	If *Item\Image
		FreeImage(*Item\Image)
	EndIf
	
EndProcedure



; Gibt #True zurück, wenn die Maus innerhalb des Rechtecks ist.
;   Width und Height können auch negativ sein.
Procedure.i TabBarGadget_MouseIn(*TabBarGadget.TabBarGadget, X.i, Y.i, Width.i, Height.i) ; OK
	
	With *TabBarGadget
		
		If Width  < 0 : X + Width  : Width  * -1 : EndIf
		If Height < 0 : Y + Height : Height * -1 : EndIf
		If \MouseX >= X And \MouseX < X+Width And \MouseY >= Y And \MouseY < Y+Height
			ProcedureReturn #True
		EndIf
		
	EndWith
	
EndProcedure



; Farbaddition
Procedure.i TabBarGadget_ColorPlus(Color.i, Plus.i) ; OK
	
	If Color&$FF + Plus&$FF < $FF
		Color + Plus&$FF
	Else
		Color | $FF
	EndIf 
	If Color&$FF00 + Plus&$FF00 < $FF00
		Color + Plus&$FF00
	Else
		Color | $FF00
	EndIf 
	If Color&$FF0000 + Plus&$FF0000 < $FF0000
		Color + Plus&$FF0000
	Else
		Color | $FF0000
	EndIf 
	
	ProcedureReturn Color
	
EndProcedure



; Farbsubtraktion
Procedure.i TabBarGadget_ColorMinus(Color.i, Minus.i) ; OK
	
	If Color&$FF - Minus&$FF > 0
		Color - Minus&$FF
	Else
		Color & $FFFFFF00
	EndIf 
	If Color&$FF00 - Minus&$FF00 > 0
		Color - Minus&$FF00
	Else
		Color & $FFFF00FF
	EndIf 
	If Color&$FF0000 - Minus&$FF0000 > 0
		Color - Minus&$FF0000
	Else
		Color & $FF00FFFF
	EndIf 
	
	ProcedureReturn Color
	
EndProcedure



; Zeichnet ein (Schließen-)Kreuz
Procedure TabBarGadget_DrawCross(X.i, Y.i, Size.i, Color.i) ; OK
	
	Protected Alpha.i = Alpha(Color)/4
	
	Line(X  , Y+1     , Size-1,  Size-1, Color&$FFFFFF|Alpha<<24)
	Line(X+1, Y       , Size-1,  Size-1, Color&$FFFFFF|Alpha<<24)
	Line(X  , Y+Size-2, Size-1, -Size+1, Color&$FFFFFF|Alpha<<24)
	Line(X+1, Y+Size-1, Size-1, -Size+1, Color&$FFFFFF|Alpha<<24)
	Line(X  , Y       , Size  ,  Size  , Color)
	Line(X  , Y+Size-1, Size  , -Size  , Color)
	
EndProcedure



; Zeichnet einen Button
Procedure TabBarGadget_DrawButton(X.i, Y.i, Width.i, Height.i, Type.i, Color, Vertical.i=#False) ; OK
	
	If Type
		DrawingMode(#PB_2DDrawing_Transparent|#PB_2DDrawing_AlphaBlend|#PB_2DDrawing_Gradient)
		ResetGradientColors()
		If Type = 1
			GradientColor(0.0, TabBarGadget_ColorPlus(Color, $404040))
			GradientColor(0.5, Color)
			GradientColor(1.0, TabBarGadget_ColorMinus(Color, $404040))
		ElseIf Type = -1
			GradientColor(1.0, TabBarGadget_ColorPlus(Color, $404040))
			GradientColor(0.5, Color)
			GradientColor(0.0, TabBarGadget_ColorMinus(Color, $404040))
		EndIf
		If Vertical
			LinearGradient(X, Y, X+Width-1, Y)
			RoundBox(X, Y, Width, Height, 3, 3)
			DrawingMode(#PB_2DDrawing_Outlined|#PB_2DDrawing_AlphaBlend)
			RoundBox(X, Y, Width, Height, 3, 3, TabBarGadgetInclude\BorderColor&$FFFFFF|$80<<24)
		Else
			LinearGradient(X, Y, X, Y+Height-1)
			RoundBox(X, Y, Width, Height, 3, 3)
			DrawingMode(#PB_2DDrawing_Outlined|#PB_2DDrawing_AlphaBlend)
			RoundBox(X, Y, Width, Height, 3, 3, TabBarGadgetInclude\BorderColor&$FFFFFF|$80<<24)
		EndIf
		DrawingMode(#PB_2DDrawing_Transparent|#PB_2DDrawing_AlphaBlend)
	EndIf
	
EndProcedure



; Zeichnet einen Pfeil
Procedure TabBarGadget_DrawArrow(X.i, Y.i, Size.i, Color.i) ; OK
	
	Protected Index.i, Alpha.i = Alpha(Color)/4
	
	If Size > 0
		For Index = 1 To Size
			Line(X+Index, Y-Index, 1, Index*2, Color)
		Next
		LineXY(X, Y-1, X+Size, Y-1-Size, Color&$FFFFFF|Alpha<<24)
		LineXY(X, Y, X+Size, Y+Size, Color&$FFFFFF|Alpha<<24)
	ElseIf Size < 0
		For Index = 1 To -Size
			Line(X-Index, Y-Index, 1, Index*2, Color)
		Next
		LineXY(X, Y-1, X+Size, Y-1+Size, Color&$FFFFFF|Alpha<<24)
		LineXY(X, Y, X+Size, Y-Size, Color&$FFFFFF|Alpha<<24)
	EndIf
	
EndProcedure



; Gibt die Länge der Registerkate zurück.
Procedure.i TabBarGadget_ItemLength(*TabBarGadget.TabBarGadget, *Item.TabBarGadgetItem) ; OK
	
	Protected Length.i
	
	Length = TextWidth(*Item\ShortText) + 2*TabBarGadgetInclude\Padding
	If *TabBarGadget\Attributes & #TabBarGadget_CloseButton And *Item <> *TabBarGadget\NewTabItem
		Length + TabBarGadgetInclude\CloseButtonSize + TabBarGadgetInclude\ImageSpace
	EndIf
	If *Item\Image
		If *TabBarGadget\Attributes & #TabBarGadget_Vertical
			Length + ImageHeight(*Item\Image)
		Else
			Length + ImageWidth(*Item\Image)
		EndIf
		If *Item\ShortText
			Length + TabBarGadgetInclude\ImageSpace
		EndIf
	ElseIf *Item = *TabBarGadget\NewTabItem And *Item\Text = ""
		Length + 16
	EndIf
	If Length > *TabBarGadget\MaxTabLength And *Item <> *TabBarGadget\NewTabItem
		Length = *TabBarGadget\MaxTabLength
	EndIf
	If Length < *TabBarGadget\MinTabLength And *Item <> *TabBarGadget\NewTabItem
		Length = *TabBarGadget\MinTabLength
	EndIf
	
	ProcedureReturn Length
	
EndProcedure



; Gibt den maximal zur verfügungstehenden Platz für Registerkarten zurück.
Procedure.i TabBarGadget_MaxLength(*TabBarGadget.TabBarGadget, WithNewTab.i=#True) ; OK
	
	Protected Length.i
	
	If *TabBarGadget\Attributes & #TabBarGadget_Vertical
		Length = OutputHeight() - TabBarGadgetInclude\Margin*2
	Else
		Length = OutputWidth()  - TabBarGadgetInclude\Margin*2
	EndIf
	If *TabBarGadget\Attributes & #TabBarGadget_NewTab And WithNewTab
		Length - *TabBarGadget\NewTabItem\Length + 1
	EndIf
	If *TabBarGadget\Attributes & #TabBarGadget_PreviousArrow
		Length - TabBarGadgetInclude\ArrowWidth - TabBarGadgetInclude\FadeOut
	EndIf
	If *TabBarGadget\Attributes & #TabBarGadget_NextArrow
		Length - TabBarGadgetInclude\ArrowWidth
		If *TabBarGadget\Attributes & #TabBarGadget_NewTab
			Length - TabBarGadgetInclude\Margin
		EndIf
	EndIf
	
	ProcedureReturn Length
	
EndProcedure



; Führt eine Textkürzung durch, bis alle Karte in die Leiste passen.
Procedure.i TabBarGadget_TextCutting(*TabBarGadget.TabBarGadget) ; OK
	
	Protected NewList SortedItem.TabBarGadgetSortedItem()
	Protected *SortedItem.TabBarGadgetSortedItem
	Protected MaxLength.i, Length.i
	
	With *TabBarGadget
		
		; Der Textlänge nach (groß -> klein) sortierte Einträge anlegen.
		ForEach \Item()
			\Item()\ShortText  = \Item()\Text
			\Item()\Length     = TabBarGadget_ItemLength(*TabBarGadget, @\Item())
			LastElement(SortedItem())
			*SortedItem        = AddElement(SortedItem())
			*SortedItem\Item   = @\Item()
			*SortedItem\Len    = Len(\Item()\Text)
			While PreviousElement(SortedItem()) And *SortedItem\Item\Length > SortedItem()\Item\Length
				SwapElements(SortedItem(), @SortedItem(), *SortedItem)
				ChangeCurrentElement(SortedItem(), *SortedItem)
			Wend
			MaxLength + \Item()\Length - 1
		Next
		
		; Textkürzung durchführen, bis alle Karte in die maximale Breite passen.
		While MaxLength > \MaxLength And FirstElement(SortedItem())
			*SortedItem = @SortedItem()
			If *SortedItem\Len > 3 And *SortedItem\Item\Length > \MinTabLength
				*SortedItem\Len - 1
				*SortedItem\Item\ShortText = Left(*SortedItem\Item\Text, *SortedItem\Len)+".."
				Length = TabBarGadget_ItemLength(*TabBarGadget, *SortedItem\Item)
				MaxLength - (*SortedItem\Item\Length-Length)
				*SortedItem\Item\Length = Length
				While NextElement(SortedItem()) And *SortedItem\Item\Length < SortedItem()\Item\Length
					SwapElements(SortedItem(), @SortedItem(), *SortedItem)
					ChangeCurrentElement(SortedItem(), *SortedItem)
				Wend
			Else
				DeleteElement(SortedItem())
			EndIf
		Wend
		
	EndWith
	
	ProcedureReturn MaxLength
	
EndProcedure



; (Er-)setz ein neues Icon für die Karte
Procedure.i TabBarGadget_ReplaceImage(Image.i, NewImageID.i=#Null) ; OK
	
	If Image
		FreeImage(Image)
		Image = #Null
	EndIf
	If NewImageID
		Image = CreateImage(#PB_Any, 16, 16, 32|#PB_Image_Transparent)
		StartDrawing(ImageOutput(Image))
			DrawingMode(#PB_2DDrawing_AlphaBlend)
			DrawImage(NewImageID, 0, 0, 16, 16)
		StopDrawing()
	EndIf
	
	ProcedureReturn Image
	
EndProcedure



; Ermittelt den Bereich einer Karte
Procedure TabBarGadget_ItemArea(*TabBarGadget.TabBarGadget, *Item.TabBarGadgetItem) ; OK
	
	With TabBarGadgetInclude
		
		; Größe und Lage
		*Item\Area\X      = *Item\Position
		*Item\Area\Width  = *Item\Length
		*Item\Area\Height = *TabBarGadget\TabHeight + 2
		If *TabBarGadget\Attributes & #TabBarGadget_MirroredTabs
			*Item\Area\Y      = ((*TabBarGadget\TabHeight-1)*(*Item\Row)-1)
		Else
			*Item\Area\Y      = OutputHeight() - ((*TabBarGadget\TabHeight-1)*(*Item\Row+1)+1)
		EndIf
		If *Item = *TabBarGadget\SelectedItem
			*Item\Area\Width  + \Margin
			*Item\Area\Height + \Margin
			*Item\Area\X      - \Margin/2
			If *TabBarGadget\Attributes & #TabBarGadget_MirroredTabs = 0
				*Item\Area\Y    - \Margin
			EndIf
			*Item\Area\Padding = \Padding + \Margin/2
		Else
			*Item\Area\Padding = \Padding
		EndIf
		
	EndWith
	
EndProcedure



; Zeichnet eine Karte
Procedure TabBarGadget_DrawItem(*TabBarGadget.TabBarGadget, *Item.TabBarGadgetItem)
	
	Protected X.i, Y.i, ShiftY.i, ShiftHeight.i, Padding.i
	Protected Color.i, Width.i, Text.s, Len.i
	
	With TabBarGadgetInclude
		
		; Orientierung der Registerkarte
		If *TabBarGadget\Attributes & #TabBarGadget_MirroredTabs
			ShiftY = -*TabBarGadget\Radius-1
		EndIf
		ShiftHeight = *TabBarGadget\Radius
		
		; Aussehen
		ResetGradientColors()
		If *TabBarGadget\Attributes & #TabBarGadget_MirroredTabs
			LinearGradient(0, *Item\Area\Y+*Item\Area\Height-1, 0,*Item\Area\Y)
		Else
			LinearGradient(0, *Item\Area\Y, 0, *Item\Area\Y+*Item\Area\Height-1)
		EndIf
		Select *Item\Face
			Case #TabBarGadgetItem_MoveFace
				Color = TabBarGadget_ColorPlus(*Item\Color\Background, \ActivColorPlus)
				GradientColor(0.0, TabBarGadget_ColorPlus(Color, $FF101010)&$FFFFFF|$C0<<24)
				GradientColor(0.5, Color&$FFFFFF|$C0<<24)
				GradientColor(1.0, TabBarGadget_ColorMinus(Color, $FF101010)&$FFFFFF|$C0<<24)
			Case #TabBarGadgetItem_DisableFace
				GradientColor(0.0, TabBarGadget_ColorPlus(*Item\Color\Background, $FF202020)&$FFFFFF|$80<<24)
				GradientColor(0.5, *Item\Color\Background&$FFFFFF|$80<<24)
				GradientColor(0.6, TabBarGadget_ColorMinus(*Item\Color\Background, $FF101010)&$FFFFFF|$80<<24)
				GradientColor(1.0, TabBarGadget_ColorMinus(*Item\Color\Background, $FF303030)&$FFFFFF|$80<<24)
			Case #TabBarGadgetItem_NormalFace
				GradientColor(0.0, TabBarGadget_ColorPlus(*Item\Color\Background, $FF202020))
				GradientColor(0.5, *Item\Color\Background)
				GradientColor(0.6, TabBarGadget_ColorMinus(*Item\Color\Background, $FF101010))
				GradientColor(1.0, TabBarGadget_ColorMinus(*Item\Color\Background, $FF303030))
			Case #TabBarGadgetItem_HoverFace
				Color = TabBarGadget_ColorPlus(*Item\Color\Background, \HoverColorPlus)
				GradientColor(0.0, TabBarGadget_ColorPlus(Color, $FF202020))
				GradientColor(0.5, Color)
				GradientColor(0.6, TabBarGadget_ColorMinus(Color, $FF101010))
				GradientColor(1.0, TabBarGadget_ColorMinus(Color, $FF303030))
			Case #TabBarGadgetItem_ActiveFace
				Color = TabBarGadget_ColorPlus(*Item\Color\Background, \ActivColorPlus)
				GradientColor(0.0, TabBarGadget_ColorPlus(Color, $FF101010))
				GradientColor(0.5, Color)
				GradientColor(1.0, TabBarGadget_ColorMinus(Color, $FF101010))
		EndSelect
		
		; Registerkarte zeichnen
		DrawingMode(#PB_2DDrawing_Transparent|#PB_2DDrawing_AlphaBlend|#PB_2DDrawing_Gradient)
		RoundBox(*Item\Area\X, *Item\Area\Y+ShiftY, *Item\Area\Width, *Item\Area\Height+ShiftHeight, *TabBarGadget\Radius, *TabBarGadget\Radius)
		DrawingMode(#PB_2DDrawing_Transparent|#PB_2DDrawing_AlphaBlend|#PB_2DDrawing_Outlined)
		If *Item\Disabled
			RoundBox(*Item\Area\X, *Item\Area\Y+ShiftY, *Item\Area\Width, *Item\Area\Height+ShiftHeight, *TabBarGadget\Radius, *TabBarGadget\Radius, \BorderColor&$FFFFFF|$80<<24)
		Else
			RoundBox(*Item\Area\X, *Item\Area\Y+ShiftY, *Item\Area\Width, *Item\Area\Height+ShiftHeight, *TabBarGadget\Radius, *TabBarGadget\Radius, \BorderColor)
		EndIf
		DrawingMode(#PB_2DDrawing_Transparent|#PB_2DDrawing_AlphaBlend)
		Width = *Item\Area\Width - *Item\Area\Padding*2
		X     = *Item\Area\X + *Item\Area\Padding
		If *TabBarGadget\Attributes & #TabBarGadget_CloseButton
			Width - (\CloseButtonSize+\ImageSpace)
		EndIf
		If *Item\Image
			If *Item\Disabled
				DrawAlphaImage(ImageID(*Item\Image), *Item\Area\X+*Item\Area\Padding, *Item\Area\Y+(*Item\Area\Height-ImageHeight(*Item\Image))/2, $40)
			Else
				DrawAlphaImage(ImageID(*Item\Image), *Item\Area\X+*Item\Area\Padding, *Item\Area\Y+(*Item\Area\Height-ImageHeight(*Item\Image))/2, $FF)
			EndIf
			X     + ImageWidth(*Item\Image) + \ImageSpace
			Width - ImageWidth(*Item\Image) - \ImageSpace
		EndIf
		Y    = *Item\Area\Y + (*Item\Area\Height-TextHeight(*Item\ShortText))/2
		Text = *Item\ShortText
		Len  = Len(Text)
		While Len > 3 And TextWidth(Text) > Width
			Len - 1
			Text = Left(Text, Len)+".."
		Wend
		If *Item\Disabled
			DrawText(X, Y, Text, *Item\Color\Text&$FFFFFF|$40<<24)
		Else
			DrawText(X, Y, Text, *Item\Color\Text)
		EndIf
		
		; Schließen-Schaltfläche
		If *TabBarGadget\Attributes & #TabBarGadget_CloseButton 
			If *Item <> *TabBarGadget\NewTabItem
				Y = *Item\Area\Y + (*Item\Area\Height-\CloseButtonSize)/2
				X = *Item\Area\X + *Item\Area\Width - \CloseButtonSize - *Item\Area\Padding
				If *TabBarGadget\HoverItem = *Item And *TabBarGadget\HoverClose
					If *TabBarGadget\LockedClose And *TabBarGadget\LockedItem = *Item
						TabBarGadget_DrawButton(X, Y, \CloseButtonSize, \CloseButtonSize, -1, *Item\Color\Background)
					Else
						TabBarGadget_DrawButton(X, Y, \CloseButtonSize, \CloseButtonSize, 1, *Item\Color\Background)
					EndIf
				Else
					;TabBarGadget_DrawButton(X, Y, \CloseButtonSize, \CloseButtonSize, 1, 0)
				EndIf
				If *Item\Disabled
					TabBarGadget_DrawCross(X+3, Y+3, \CloseButtonSize-6, *Item\Color\Text&$FFFFFF|$40<<24)
				Else
					TabBarGadget_DrawCross(X+3, Y+3, \CloseButtonSize-6, *Item\Color\Text)
				EndIf
			EndIf
		EndIf
		
	EndWith
	
EndProcedure



; Ermittelt das Aussehen und die Lage der Tabs
Procedure TabBarGadget_Examine(*TabBarGadget.TabBarGadget)
	
	Protected MinLength.i, X.i, Y.i, Shift.i, MousePosition.i, Row.i
	
	With *TabBarGadget
		
		; Initialisierung
		\ToolTip\Current = #Null
		\MouseX      = GetGadgetAttribute(\Number, #PB_Canvas_MouseX)
		\MouseY      = GetGadgetAttribute(\Number, #PB_Canvas_MouseY)
		\Event       = #Null
		\EventTab    = #TabBarGadgetItem_None
		\HoverItem   = #Null
		\HoverClose  = #False
		\HoverArrow  = #Null
		
		; Events auf den Registerkarten
		If \MoveItem = #Null
			ForEach \Item()
				If \Item()\Visible And TabBarGadget_MouseIn(*TabBarGadget, \Item()\Area\X, \Item()\Area\Y,  \Item()\Area\Width-1, \Item()\Area\Height-1)
					\HoverItem = \Item()
				EndIf
			Next
			If \Attributes & #TabBarGadget_NewTab And TabBarGadget_MouseIn(*TabBarGadget, \NewTabItem\Area\X, \NewTabItem\Area\Y, \NewTabItem\Area\Width-1, \NewTabItem\Area\Height-1)
				\HoverItem = \NewTabItem
			EndIf
		EndIf
		If \Attributes & (#TabBarGadget_PreviousArrow|#TabBarGadget_NextArrow)
			If EventType() = #PB_EventType_MouseWheel
				Shift = TabBarGadgetInclude\WheelDirection * GetGadgetAttribute(\Number, #PB_Canvas_WheelDelta)
				If Shift < 0
					\Shift + Shift
					If \Shift < 0
						\Shift = 0
					EndIf
				ElseIf Shift > 0
					\Shift + Shift
					If \Shift > ListSize(\Item())
						\Shift = ListSize(\Item())
					EndIf
				EndIf
			EndIf
			Y = (OutputHeight()+TabBarGadgetInclude\Margin)/2
			If \Attributes & #TabBarGadget_PreviousArrow 
				If TabBarGadget_MouseIn(*TabBarGadget, 0, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight)
					\HoverArrow = #TabBarGadget_PreviousArrow
					\HoverItem = #Null
					Select EventType()
						Case #PB_EventType_LeftButtonDown
							\LockedArrow = #TabBarGadget_PreviousArrow
						Case #PB_EventType_LeftButtonUp
							If \LockedArrow = \HoverArrow
								\Shift - 1
							EndIf
					EndSelect
				EndIf
			EndIf
			If \Attributes & #TabBarGadget_NextArrow
				X = OutputWidth()-TabBarGadgetInclude\ArrowWidth
				If \Attributes & #TabBarGadget_NewTab
					X - \NewTabItem\Length-TabBarGadgetInclude\Margin
				EndIf
				If TabBarGadget_MouseIn(*TabBarGadget, X, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight)
					\HoverArrow = #TabBarGadget_NextArrow
					\HoverItem = #Null
					Select EventType()
						Case #PB_EventType_LeftButtonDown
							\LockedArrow = #TabBarGadget_NextArrow
						Case #PB_EventType_LeftButtonUp
							If \LockedArrow = \HoverArrow
								\Shift + 1
							EndIf
					EndSelect
				EndIf
			EndIf
		EndIf
		
		; Registerkarte unter der Maus
		If \HoverItem
			
			If \HoverItem\ToolTip
				\ToolTip\Current = @\HoverItem\ToolTip
			Else
				\ToolTip\Current = @\HoverItem\Text
			EndIf
			If \Attributes & #TabBarGadget_CloseButton And \HoverItem <> \NewTabItem
				Y = \HoverItem\Area\Y + (\HoverItem\Area\Height-TabBarGadgetInclude\CloseButtonSize)/2
				X = \HoverItem\Area\X + \HoverItem\Area\Width - \HoverItem\Area\Padding - TabBarGadgetInclude\CloseButtonSize
				If TabBarGadget_MouseIn(*TabBarGadget, X, Y, TabBarGadgetInclude\CloseButtonSize, TabBarGadgetInclude\CloseButtonSize)
					\HoverClose = #True
					\ToolTip\Current = @\ToolTip\CloseText
				EndIf
			EndIf
			
			If \HoverItem = \NewTabItem
				\EventTab = #TabBarGadgetItem_NewTab
				\ToolTip\Current = @\ToolTip\NewText
			Else
				ChangeCurrentElement(\Item(), \HoverItem)
				\EventTab = ListIndex(\Item())
			EndIf
			Select EventType()
				Case #PB_EventType_LeftButtonDown
					\LockedItem = \HoverItem
					If \LockedItem = \NewTabItem 
						\Event = #TabBarGadgetEvent_NewTab
					ElseIf \HoverClose
						\LockedClose = #True
					Else
						If \HoverItem\Disabled = #False
							If \SelectedItem <> \HoverItem
								\Event = #TabBarGadgetEvent_Change
							EndIf
							\SelectedItem = \HoverItem
						EndIf
						If Not \Attributes & #TabBarGadget_NoTabMoving
							\ReadyToMoveItem = \HoverItem
							\SaveMouseX = \MouseX
							\SaveMouseY = \MouseY
						EndIf
					EndIf
				Case #PB_EventType_MiddleButtonDown
					\LockedItem = \HoverItem
				Case #PB_EventType_LeftButtonUp
					If \HoverClose And \LockedItem = \HoverItem
						\Event = #TabBarGadgetEvent_CloseTab
					EndIf
				Case #PB_EventType_MiddleButtonUp
					If \LockedItem = \HoverItem And \LockedItem <> \NewTabItem 
						\Event           = #TabBarGadgetEvent_CloseTab
						\MoveItem        = #Null
						\ReadyToMoveItem = #Null
					EndIf
					\LockedItem = #Null
				Case #PB_EventType_MouseMove
					If \ReadyToMoveItem
						If Abs(\SaveMouseX-\MouseX) > 4 Or Abs(\SaveMouseY-\MouseY) > 4
							\MoveItem = \ReadyToMoveItem
						EndIf
					EndIf
			EndSelect
		
		ElseIf \HoverArrow = 0
			If EventType() = #PB_EventType_LeftDoubleClick
				\Event = #TabBarGadgetEvent_NewTab
			EndIf
		EndIf
		
		Select EventType()
			Case #PB_EventType_LeftButtonUp
				\LockedClose     = #False
				\MoveItem        = #Null
				\ReadyToMoveItem = #Null
				\LockedArrow     = #Null
			Case #PB_EventType_MouseLeave
				\HoverItem       = #Null
		EndSelect
		
		; Registerkartenverschiebung: Verschiebungspartner suchen und tauschen
		If \MoveItem
			If \Attributes & #TabBarGadget_MultiLine
				If \Attributes & #TabBarGadget_MirroredTabs
					Row = Int(\MouseY/\TabHeight)
				Else
					Row = Int(\Rows-\MouseY/\TabHeight)
				EndIf
				If Row < 0 : Row = 0 : ElseIf Row >= \Rows : Row = \Rows-1 : EndIf
				MousePosition = Row*\MaxLength + \MouseX
			Else
				MousePosition = \MouseX
			EndIf
			If Not \Event
				ChangeCurrentElement(\Item(), \MoveItem)
				While NextElement(\Item())
					If MousePosition > \Item()\Position + \MaxLength*\Item()\Row
						SwapElements(\Item(), @\Item(), \MoveItem)
						\Item()\Position = \MoveItem\Position
						\MoveItem\Position = \Item()\Position + \Item()\Length
						\Event = #TabBarGadgetEvent_TabSwapped
						PushListPosition(\Item())
						ChangeCurrentElement(\Item(), \MoveItem)
						\EventTab = ListIndex(\Item())
						PopListPosition(\Item())
					EndIf
				Wend
			EndIf
			If Not \Event
				ChangeCurrentElement(\Item(), \MoveItem)
				While PreviousElement(\Item()) And ListIndex(\Item()) >= \Shift-1
					If \MoveItem\Length < \Item()\Length
						MinLength = \MoveItem\Length
					Else
						MinLength = \Item()\Length 
					EndIf
					If MousePosition < \Item()\Position + \MaxLength*\Item()\Row + MinLength
						SwapElements(\Item(), @\Item(), \MoveItem)
						\MoveItem\Position = \Item()\Position
						\Item()\Position = \MoveItem\Position + \MoveItem\Length
						\Event = #TabBarGadgetEvent_TabSwapped
						PushListPosition(\Item())
						ChangeCurrentElement(\Item(), \MoveItem)
						\EventTab = ListIndex(\Item())
						PopListPosition(\Item())
					EndIf
				Wend
			EndIf
		EndIf
		
		; ToolTip aktualisieren
		If \ToolTip\Current <> \ToolTip\Old
			If \ToolTip\Current = #Null
				GadgetToolTip(\Number, "")
			ElseIf \ToolTip\Current = @\ToolTip\NewText Or \ToolTip\Current =  @\ToolTip\CloseText
				GadgetToolTip(\Number, PeekS(\ToolTip\Current))
			ElseIf \HoverItem And \ToolTip\Current = @\HoverItem\ToolTip
				GadgetToolTip(\Number, PeekS(\ToolTip\Current))
			Else
				GadgetToolTip(\Number, ReplaceString(\ToolTip\ItemText, "%ITEM", PeekS(\ToolTip\Current)))
			EndIf
			\ToolTip\Old = \ToolTip\Current
		EndIf
		
	EndWith
	
EndProcedure



; Ermittelt das Aussehen und die Lage der Tabs
Procedure TabBarGadget_Update(*TabBarGadget.TabBarGadget)
	
	Protected FocusingSelectedTab.i
	Protected ShowLength.i, X.i
	Protected OldAttributes.i
	Protected Difference.f, Factor.f, Position.i, Length.i, MaxWidth.i
	Protected *Item.TabBarGadgetItem, Row.i, Rows.i=1
	Protected *Current, *Last, AddLength.i, RowCount.i
	Protected Dim Row.TabBarGadgetRow(0)
	
	With *TabBarGadget
		
		DrawingFont(\FontID)
		
		\Attributes & ~(#TabBarGadget_PreviousArrow|#TabBarGadget_NextArrow)
		
		If \TabHeight = 0
			\TabHeight = OutputHeight() - TabBarGadgetInclude\Margin
		EndIf
		
		If \Attributes & #TabBarGadget_NewTab
			\NewTabItem\Length = TabBarGadget_ItemLength(*TabBarGadget, \NewTabItem)
			\NewTabItem\Row = 0
		EndIf
		
		If \Attributes & #TabBarGadget_MultiLine
			
			\MaxLength = TabBarGadget_MaxLength(*TabBarGadget)
			\Length    = \MaxLength
			\Shift     = 0
			
			; Breiten ermitteln
			Length = 1
			ForEach \Item()
				\Item()\Row = 0
				\Item()\Length  = TabBarGadget_ItemLength(*TabBarGadget, \Item())
				\Item()\Visible = #True
				Length - 1 + \Item()\Length
			Next
			
			
			; Mehrere Zeilen einrichten
			If Length > \MaxLength
				Row = 0
				Row(Row)\Length = 1
				ForEach \Item()
					If NextElement(\Item())
						PreviousElement(\Item())
						MaxWidth = TabBarGadget_MaxLength(*TabBarGadget, #False)
					Else
						LastElement(\Item())
						MaxWidth = TabBarGadget_MaxLength(*TabBarGadget)
					EndIf
					If Row(Row)\Length-1+\Item()\Length > MaxWidth
						;Row(Row)\Length - 1
						Row + 1
						ReDim Row(Row)
						Row(Row)\Length = 1
					EndIf
					Row(Row)\Length - 1 + \Item()\Length
					Row(Row)\Items + 1
					\Item()\Row = Row
				Next
			Else
				Row(Row)\Length = Length
			EndIf
			Rows = Row+1
			
			; Optimieren
			If #False
			Repeat
				Repeat
					*Item = LastElement(\Item())
					While PreviousElement(\Item())
						If *Item\Row <> \Item()\Row
							If Abs((Row(*Item\Row)\Length-1+\Item()\Length)-(Row(\Item()\Row)\Length-\Item()\Length+1)) < Abs(Row(*Item\Row)\Length-Row(\Item()\Row)\Length)
								Row(*Item\Row)\Length - 1 + \Item()\Length
								Row(*Item\Row)\Items + 1
								Row(\Item()\Row)\Length - \Item()\Length + 1
								Row(\Item()\Row)\Items - 1
								\Item()\Row = *Item\Row
								Break 2
							EndIf
						EndIf
						*Item = \Item()
					Wend
					Break 2
				ForEver
			ForEver
			EndIf
			
			; Verbreitern
			If Rows > 1
				ForEach \Item()
					AddLength = (TabBarGadget_MaxLength(*TabBarGadget, #False)-Row(\Item()\Row)\Length)/Row(\Item()\Row)\Items
					If \Item()\Row <> Rows-1 Or AddLength < 0
						\Item()\Length + AddLength
						Row(\Item()\Row)\Length + AddLength
						Row(\Item()\Row)\Items - 1
					EndIf
				Next
			EndIf
			
			; Positionen errechnen
			Length = TabBarGadgetInclude\Margin
			Row = 0
			ForEach \Item()
				If Row <> \Item()\Row
					Row + 1
					Length = TabBarGadgetInclude\Margin
				EndIf
				\Item()\Position = Length
				Length + \Item()\Length - 1
			Next
			\NewTabItem\Row = Rows-1
			\NewTabItem\Position = TabBarGadgetInclude\Margin+Row(\NewTabItem\Row)\Length - 1
			
		Else
			
			; Platzverbrauch bestimmen und ggf. Navigation hinzufügen
			Repeat
				
				FocusingSelectedTab = \FocusingSelectedTab
				\MaxLength = TabBarGadget_MaxLength(*TabBarGadget)
				
				; ggf. Textkürzung
				If \Attributes & #TabBarGadget_TextCutting
					\Length = TabBarGadget_TextCutting(*TabBarGadget)
					ShowLength = \Length
					If ShowLength <= \MaxLength
						\Shift = 0
						Break
					EndIf
				EndIf
				
				; Breiten ermitteln
				ForEach \Item()
					\Item()\Length = TabBarGadget_ItemLength(*TabBarGadget, \Item())
					\Item()\Row    = 0
				Next
				
				; ggf. aktuell ausgewählte Registerkarte in den sichtbaren Bereich bringen
				If FocusingSelectedTab And \SelectedItem
					ChangeCurrentElement(\Item(), \SelectedItem)
					If ListIndex(\Item()) < \Shift
						\Shift = ListIndex(\Item())
						FocusingSelectedTab = #False
					EndIf
				EndIf
				Repeat
					\Length = 0
					ShowLength = 0
					ForEach \Item()
						\Length + \Item()\Length-1
						If ListIndex(\Item()) >= \Shift
							ShowLength + \Item()\Length-1
						EndIf
						If \Item() = \SelectedItem And ShowLength < \MaxLength
							FocusingSelectedTab = #False
						EndIf
					Next
					If FocusingSelectedTab
						\Shift + 1
					EndIf
				Until FocusingSelectedTab = #False
				
				; Bei freiem Platz, Verschiebung anpassen
				Repeat
					If \Shift > 1 And SelectElement(\Item(), \Shift-1)
						If ShowLength + \Item()\Length < \MaxLength - TabBarGadgetInclude\ArrowWidth - TabBarGadgetInclude\FadeOut
							\Shift - 1
							ShowLength + \Item()\Length-1
						Else
							Break
						EndIf
					ElseIf \Shift = 1 And SelectElement(\Item(), \Shift-1)
						If ShowLength + \Item()\Length < \MaxLength
							\Shift - 1
							ShowLength + \Item()\Length-1
						Else
							Break
						EndIf
					Else
						Break
					EndIf
				ForEver
				
				; Navigation nötig ?
				OldAttributes = \Attributes
				If \Length >= \MaxLength
					If \Shift
						\Attributes | #TabBarGadget_PreviousArrow
					EndIf
					If ShowLength >= \MaxLength
						\Attributes | #TabBarGadget_NextArrow
					EndIf
				EndIf
				
			Until OldAttributes = \Attributes
			\FocusingSelectedTab = FocusingSelectedTab
			
			; Position der Tabs
			
			; vorherige Registerkarte
			If \Attributes & #TabBarGadget_PreviousArrow
				ForEach \Item()
					\Item()\Position = -$FFFF
					\Item()\Visible  = #False
					If ListIndex(\Item()) >= \Shift-1 : Break : EndIf
				Next
				X = TabBarGadgetInclude\ArrowWidth + TabBarGadgetInclude\Margin + TabBarGadgetInclude\FadeOut
				SelectElement(\Item(), \Shift-1)
				\Item()\Position = X - \Item()\Length + 1
				\Item()\Visible  = #True
			Else
				X = TabBarGadgetInclude\Margin
			EndIf
			
			; sichtbare Registerkarten
			\Length = 0
			If SelectElement(\Item(), \Shift)
				Repeat
					\Item()\Position = X + \Length
					\Item()\Visible  = #True
					If \Length + \Item()\Length - 1 > \MaxLength
						Break
					EndIf
					\Length + \Item()\Length - 1
				Until Not NextElement(\Item())
			EndIf
			
			; nächste Registerkarte
			If \Attributes & #TabBarGadget_NextArrow And ListIndex(\Item()) <> -1
				\Item()\Position = X + \Length
				If \Attributes & #TabBarGadget_NewTab
					\NewTabItem\Position = OutputWidth()-\NewTabItem\Length-TabBarGadgetInclude\Margin/2
				EndIf
				While NextElement(\Item())
					\Item()\Position = $FFFF
					\Item()\Visible  = #False
				Wend
			Else
				If \Attributes & #TabBarGadget_NewTab
					\NewTabItem\Position = X + \Length
				EndIf
			EndIf
			
			Row(0)\Length = X- TabBarGadgetInclude\Margin+\Length+1
			
		EndIf
		
		If Rows <> \Rows
			StopDrawing()
			ResizeGadget(\Number, #PB_Ignore, #PB_Ignore, #PB_Ignore, Rows*(\TabHeight-1)+1+TabBarGadgetInclude\Margin)
			StartDrawing(CanvasOutput(\Number))
			\Resized = #True
			\Rows = Rows
		EndIf
		
		; Animation der bewegten Registerkarte
		If \MoveItem
			Difference = Abs(\MoveItem\Position-(\MouseX-\MoveItem\Length/2))
			If Difference > 24
				Position = \MouseX - \MoveItem\Length/2
			Else
				Factor = Pow(Difference/24, 2)
				Position = \MoveItem\Position*(1-Factor) + (\MouseX-\MoveItem\Length/2)*Factor
			EndIf
			If Position < TabBarGadgetInclude\Margin And \Attributes & #TabBarGadget_PreviousArrow = #Null
				Position = TabBarGadgetInclude\Margin
			EndIf
			If Position + \MoveItem\Length + 1 - TabBarGadgetInclude\Margin > Row(\MoveItem\Row)\Length - 1 And \Attributes & #TabBarGadget_NextArrow = #Null
				Position = Row(\MoveItem\Row)\Length + TabBarGadgetInclude\Margin - \MoveItem\Length
			EndIf
			\MoveItem\Position = Position
		EndIf
		
		; Aussehen
		ForEach \Item()
			If \Item()\Disabled
				\Item()\Face = #TabBarGadgetItem_DisableFace
			ElseIf \Item() = \MoveItem
				\Item()\Face = #TabBarGadgetItem_MoveFace
			ElseIf \Item() = \SelectedItem
				\Item()\Face = #TabBarGadgetItem_ActiveFace
			ElseIf \Item() = \HoverItem
				\Item()\Face = #TabBarGadgetItem_HoverFace
			Else
				\Item()\Face = #TabBarGadgetItem_NormalFace
			EndIf
			TabBarGadget_ItemArea(*TabBarGadget, \Item())
		Next
		If \NewTabItem = \HoverItem
			\NewTabItem\Face = #TabBarGadgetItem_HoverFace
		Else
			\NewTabItem\Face = #TabBarGadgetItem_NormalFace
		EndIf
		TabBarGadget_ItemArea(*TabBarGadget, \NewTabItem)
		
	EndWith
	
EndProcedure



; Zeichnet das gesamte TabBarGadget
Procedure TabBarGadget_Draw(*TabBarGadget.TabBarGadget) ; OK
	
	Protected X.i, Y.i, SelectedItemDrawed.i, MoveItemDrawed.i, Row.i, *LastItem
	
	With *TabBarGadget
		
		; Initialisierung
		DrawingFont(\FontID)
		DrawingMode(#PB_2DDrawing_AllChannels)
		Box(0, 0, OutputWidth(), OutputHeight(), TabBarGadgetInclude\TabBarColor)
		DrawingMode(#PB_2DDrawing_AlphaBlend)
		
		; Sichtbare Registerkarten
		*LastItem = LastElement(\Item())
		For Row = \Rows-1 To 0 Step -1
			If *LastItem
				While \Item()\Row = Row
					If \Item()\Visible And \Item() <> \SelectedItem And \Item() <> \MoveItem
						TabBarGadget_DrawItem(*TabBarGadget, \Item())
					EndIf
					If Not PreviousElement(\Item())
						Break
					EndIf
				Wend
			EndIf
			; ggf. "Neu"-Registerkarte (wenn keine Navigation)
			If \NewTabItem\Row = Row And \Attributes & #TabBarGadget_NewTab And \Attributes & #TabBarGadget_NextArrow = #Null
				TabBarGadget_DrawItem(*TabBarGadget, \NewTabItem)
			EndIf
			; ggf. Unterlinien
			If Row = 0 And \Attributes & #TabBarGadget_BottomLine
				If \Attributes & #TabBarGadget_MirroredTabs
					Line(0, 0, OutputWidth(), 1, TabBarGadgetInclude\BorderColor)
				Else
					Line(0, OutputHeight()-1, OutputWidth(), 1, TabBarGadgetInclude\BorderColor)
				EndIf
			EndIf
			; ggf. aktive Registerkarte
			If \SelectedItem And \SelectedItem\Row = Row
				TabBarGadget_DrawItem(*TabBarGadget, \SelectedItem)
			EndIf
			; ggf. bewegte Registerkarte
			If \MoveItem And \MoveItem\Row = Row And \MoveItem <> \SelectedItem
				TabBarGadget_DrawItem(*TabBarGadget, \MoveItem)
			EndIf
		Next
		
		; Navigationsausblendung
		DrawingMode(#PB_2DDrawing_AlphaBlend|#PB_2DDrawing_Gradient)
		If \Attributes & #TabBarGadget_PreviousArrow
			ResetGradientColors()
			GradientColor(1.0, TabBarGadgetInclude\TabBarColor&$FFFFFF)
			GradientColor(0.5, TabBarGadgetInclude\TabBarColor&$FFFFFF|$A0<<24)
			GradientColor(0.0, TabBarGadgetInclude\TabBarColor&$FFFFFF|$FF<<24)
			X = TabBarGadgetInclude\Margin+TabBarGadgetInclude\ArrowWidth
			LinearGradient(X, 0, X+TabBarGadgetInclude\FadeOut, 0)
			Box(0, 0, X+TabBarGadgetInclude\FadeOut, OutputHeight())
		EndIf
		If \Attributes & #TabBarGadget_NextArrow
			ResetGradientColors()
			GradientColor(0.0, TabBarGadgetInclude\TabBarColor&$FFFFFF)
			GradientColor(0.5, TabBarGadgetInclude\TabBarColor&$FFFFFF|$A0<<24)
			GradientColor(1.0, TabBarGadgetInclude\TabBarColor&$FFFFFF|$FF<<24)
			X = OutputWidth()-TabBarGadgetInclude\Margin-TabBarGadgetInclude\ArrowWidth-TabBarGadgetInclude\FadeOut
			If \Attributes & #TabBarGadget_NewTab
				X - \NewTabItem\Length-TabBarGadgetInclude\Margin
			EndIf
			LinearGradient(X, 0, X+TabBarGadgetInclude\FadeOut, 0)
			Box(X, 0, OutputWidth()-X, OutputHeight())
		EndIf
		
		; Navigation
		DrawingMode(#PB_2DDrawing_AlphaBlend)
		Y = (OutputHeight()+TabBarGadgetInclude\Margin)/2
		If \Attributes & #TabBarGadget_PreviousArrow
			If \HoverArrow = #TabBarGadget_PreviousArrow
				If \HoverArrow = \LockedArrow
					TabBarGadget_DrawButton(0, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight, -1, TabBarGadgetInclude\FaceColor)
				Else
					TabBarGadget_DrawButton(0, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight, 1, TabBarGadgetInclude\FaceColor)
				EndIf
				TabBarGadget_DrawArrow(2, Y, TabBarGadgetInclude\ArrowWidth-6, TabBarGadgetInclude\TextColor)
			Else
				TabBarGadget_DrawArrow(2, Y, TabBarGadgetInclude\ArrowWidth-6, TabBarGadgetInclude\TextColor&$FFFFFF|$80<<24)
			EndIf
		EndIf
		If \Attributes & #TabBarGadget_NextArrow
			X = OutputWidth()-TabBarGadgetInclude\ArrowWidth
			If \Attributes & #TabBarGadget_NewTab
				X - \NewTabItem\Length-TabBarGadgetInclude\Margin
			EndIf
			If \HoverArrow = #TabBarGadget_NextArrow
				If \HoverArrow = \LockedArrow
					TabBarGadget_DrawButton(X, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight, -1, TabBarGadgetInclude\FaceColor)
				Else
					TabBarGadget_DrawButton(X, Y-TabBarGadgetInclude\ArrowHeight/2, TabBarGadgetInclude\ArrowWidth, TabBarGadgetInclude\ArrowHeight, 1, TabBarGadgetInclude\FaceColor)
				EndIf
				TabBarGadget_DrawArrow(X+TabBarGadgetInclude\ArrowWidth-3, Y, -TabBarGadgetInclude\ArrowWidth+6, TabBarGadgetInclude\TextColor)
			Else
				TabBarGadget_DrawArrow(X+TabBarGadgetInclude\ArrowWidth-3, Y, -TabBarGadgetInclude\ArrowWidth+6, TabBarGadgetInclude\TextColor&$FFFFFF|$80<<24)
			EndIf
		EndIf
		
		; "Neu"-Registerkarten (wenn Navigation)
		If \Attributes & #TabBarGadget_NewTab And \Attributes & #TabBarGadget_NextArrow 
			TabBarGadget_DrawItem(*TabBarGadget, \NewTabItem)
		EndIf
		
	EndWith
	
EndProcedure







;-  4.2 Procedures for the TabBarGadget
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯



; Führt nur eine Aktualisierung des Gadgets durch.
Procedure UpdateTabBarGadget(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If StartDrawing(CanvasOutput(Gadget))
		TabBarGadget_Update(*TabBarGadget)
		TabBarGadget_Draw(*TabBarGadget)
		StopDrawing()
	EndIf
	
EndProcedure



; Gibt das angegebene TabBarGadget wieder frei.
Procedure FreeTabBarGadget(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ForEach *TabBarGadget\Item()
		TabBarGadget_ClearItem(*TabBarGadget, *TabBarGadget\Item())
	Next
	ClearStructure(*TabBarGadget, TabBarGadget)
	FreeMemory(*TabBarGadget)
	FreeGadget(Gadget)
	
EndProcedure



; Erstellt ein neus TabBarGadget.
Procedure.i TabBarGadget(Gadget.i, X.i, Y.i, Width.i, Height.i, Attributes.i=#Null) ; OK
	
	Protected *TabBarGadget.TabBarGadget = AllocateMemory(SizeOf(TabBarGadget))
	Protected Result.i
	
	InitializeStructure(*TabBarGadget, TabBarGadget)
	Result = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Keyboard)
	If Gadget = #PB_Any
		Gadget = Result
	EndIf
	SetGadgetData(Gadget, *TabBarGadget)
	
	With *TabBarGadget
		\Attributes  = Attributes
		\Number = Gadget
		\NewTabItem\Color\Text       = TabBarGadgetInclude\TextColor
		\NewTabItem\Color\Background = TabBarGadgetInclude\FaceColor
		\Radius                      = TabBarGadgetInclude\Radius
		\MinTabLength                = TabBarGadgetInclude\MinTabLength
		\MaxTabLength                = TabBarGadgetInclude\MaxTabLength
		\NormalTabLength             = TabBarGadgetInclude\NormalTabLength
		\FontID                      = TabBarGadgetInclude\FontID
	EndWith
	
	UpdateTabBarGadget(Gadget)
	
	ProcedureReturn Result
	
EndProcedure



; Gibt das aktuelle Ereignis auf der Registerkartenleiste zurück und aktualisiert das Gadget.
Procedure.i TabBarGadgetEvent(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If StartDrawing(CanvasOutput(Gadget))
		TabBarGadget_Examine(*TabBarGadget)
		TabBarGadget_Update(*TabBarGadget)
		TabBarGadget_Draw(*TabBarGadget)
		StopDrawing()
	EndIf
	
	ProcedureReturn *TabBarGadget\Event
	
EndProcedure



; Gibt das aktuelle Ereignis auf der Registerkartenleiste zurück und aktualisiert das Gadget.
Procedure.i TabBarGadgetResized(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If *TabBarGadget\Resized
		*TabBarGadget\Resized = #False
		ProcedureReturn #True
	EndIf
	
EndProcedure



; Gibt die Position der Registerkarte zurück, auf dem das aktuelle Ereigniss stattfand.
Procedure.i EventTab(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ProcedureReturn *TabBarGadget\EventTab
	
EndProcedure



; Fügt eine Registerkarte an die angegebenen Position ein.
Procedure.i AddTabBarGadgetItem(Gadget.i, Position.i, Text.s, ImageID.i=#Null, DataValue.i=#Null) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	Protected *Item.TabBarGadgetItem
	
	If Position = #TabBarGadgetItem_NewTab
		*TabBarGadget\Attributes | #TabBarGadget_NewTab
		*Item = @*TabBarGadget\NewTabItem
	ElseIf Position = #PB_Default
		LastElement(*TabBarGadget\Item())
		*Item = AddElement(*TabBarGadget\Item())
		Position = ListIndex(*TabBarGadget\Item())
	ElseIf TabBarGadget_ItemID(*TabBarGadget, Position)
		*Item = InsertElement(*TabBarGadget\Item())
	EndIf
	
	With *Item
		\Text             = Text
		\ShortText        = Text
		\Image            = TabBarGadget_ReplaceImage(\Image, ImageID)
		\DataValue        = DataValue
		\Color\Text       = TabBarGadgetInclude\TextColor
		\Color\Background = TabBarGadgetInclude\FaceColor
	EndWith
	
	UpdateTabBarGadget(Gadget)
	
	ProcedureReturn Position
	
EndProcedure



; Gibt die einmalige ID der angegebenen Registerkarte zurück.
Procedure.i TabBarGadgetItemID(Gadget.i, Position.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ProcedureReturn TabBarGadget_ItemID(*TabBarGadget, Position)
	
EndProcedure



; Entfernt die Registerkarte mit der angegebenen Position.
Procedure RemoveTabBarGadgetItem(Gadget.i, Position.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If Position = #TabBarGadgetItem_NewTab
		*TabBarGadget\Attributes & ~#TabBarGadget_NewTab
	ElseIf TabBarGadget_ItemID(*TabBarGadget, Position)
		TabBarGadget_ClearItem(*TabBarGadget, *TabBarGadget\Item())
		If *TabBarGadget\SelectedItem = @*TabBarGadget\Item()
			DeleteElement(*TabBarGadget\Item())
			If NextElement(*TabBarGadget\Item())
				*TabBarGadget\SelectedItem = @*TabBarGadget\Item()
			Else
				*TabBarGadget\SelectedItem = LastElement(*TabBarGadget\Item())
			EndIf
		Else
			DeleteElement(*TabBarGadget\Item())
		EndIf
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Entfernt alle Registerkarten aus der Leiste.
Procedure ClearTabBarGadgetItems(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ForEach *TabBarGadget\Item()
		TabBarGadget_ClearItem(*TabBarGadget, *TabBarGadget\Item())
	Next
	ClearList(*TabBarGadget\Item())
	*TabBarGadget\SelectedItem = #Null
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt die Anzahl der Registerkarten zurück.
Procedure.i CountTabBarGadgetItems(Gadget.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ProcedureReturn ListSize(*TabBarGadget\Item())
	
EndProcedure



; Deaktiviert oder aktiviert eine Registerkarte.
Procedure DisableTabBarGadgetItem(Gadget.i, Position.i, State.i) ; OK
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	Protected *Item.TabBarGadgetItem = TabBarGadget_ItemID(*TabBarGadget, Position)
	
	If *Item And *Item <> *TabBarGadget\NewTabItem
		*Item\Disabled = State
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure





;-  4.3 Set- & Get-Prozeduren
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯



; Setz einen ToolTip für die Registerkartenleiste (für die Registerkarten, die "Neu"-Registerkarte und den Schließenbutton)
Procedure TabBarGadgetToolTip(Gadget.i, ItemText.s="", NewText.s="", CloseText.s="")
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	*TabBarGadget\ToolTip\ItemText  = ItemText
	*TabBarGadget\ToolTip\NewText   = NewText
	*TabBarGadget\ToolTip\CloseText = CloseText
	
EndProcedure



; Setz einen ToolTip für die Registerkarte.
Procedure TabBarGadgetItemToolTip(Gadget.i, Position.i, Text.s)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		*Item\ToolTip = Text
	EndIf
	
EndProcedure



; Ändert die zu nutzende Schrift.
Procedure SetTabBarGadgetFont(Gadget.i, FontID.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If FontID = #PB_Default
		*TabBarGadget\FontID = TabBarGadgetInclude\FontID
	Else
		*TabBarGadget\FontID = FontID
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Ändert den Daten-Wert der Registerkartenleiste.
Procedure SetTabBarGadgetData(Gadget.i, DataValue.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	*TabBarGadget\DataValue = DataValue
	
EndProcedure



; Gibt den Daten-Wert der Registerkartenleiste zurück.
Procedure.i GetTabBarGadgetData(Gadget.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	ProcedureReturn *TabBarGadget\DataValue
	
EndProcedure



; Ändert den Status der Registerkartenleiste.
Procedure SetTabBarGadgetState(Gadget.i, State.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	Select State
		Case #TabBarGadgetItem_None, #TabBarGadgetItem_NewTab
			*TabBarGadget\SelectedItem = #Null
		Case #TabBarGadgetItem_Current
		Default
			If TabBarGadget_ItemID(*TabBarGadget, State)
				*TabBarGadget\SelectedItem = @*TabBarGadget\Item()
				*TabBarGadget\FocusingSelectedTab = #True
			Else
				*TabBarGadget\SelectedItem = #Null
			EndIf
	EndSelect
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt den Status der Registerkartenleiste zurück.
Procedure.i GetTabBarGadgetState(Gadget.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If *TabBarGadget\SelectedItem
		ChangeCurrentElement(*TabBarGadget\Item(), *TabBarGadget\SelectedItem)
		ProcedureReturn ListIndex(*TabBarGadget\Item())
	EndIf
	
	ProcedureReturn #TabBarGadgetItem_None
	
EndProcedure



; Wechselt zur der Registerkarte mit dem angegebenen Text
Procedure SetTabBarGadgetText(Gadget.i, Text.s)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	*TabBarGadget\SelectedItem = #Null
	ForEach *TabBarGadget\Item()
		If *TabBarGadget\Item()\Text = Text
			*TabBarGadget\SelectedItem = @*TabBarGadget\Item()
			*TabBarGadget\FocusingSelectedTab = #True
			Break
		EndIf
	Next
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt den Text der aktuell ausgewählten Registerkarte zurück.
Procedure.s GetTabBarGadgetText(Gadget.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	If *TabBarGadget\SelectedItem
		ProcedureReturn *TabBarGadget\SelectedItem\Text
	EndIf
	
EndProcedure



; Ändert den Wert eines Attributs der Registerkartenleiste.
Procedure SetTabBarGadgetAttribute(Gadget.i, Attribute.i, Value.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	Select Attribute
		Case #TabBarGadget_TextCutting
			If Value
				*TabBarGadget\Attributes | Attribute
			Else
				ForEach *TabBarGadget\Item()
					*TabBarGadget\Item()\ShortText = *TabBarGadget\Item()\Text
				Next
				*TabBarGadget\Attributes & ~Attribute
			EndIf
		Case #TabBarGadget_CloseButton, #TabBarGadget_NewTab, #TabBarGadget_MirroredTabs, #TabBarGadget_NoTabMoving, #TabBarGadget_BottomLine, #TabBarGadget_MultiLine
			If Value
				*TabBarGadget\Attributes | Attribute
			Else
				*TabBarGadget\Attributes & ~Attribute
			EndIf
		Case #TabBarGadget_TabRounding
			*TabBarGadget\Radius = Value
		Case #TabBarGadget_MinTabLength
			*TabBarGadget\MinTabLength = Value
		Case #TabBarGadget_MaxTabLength
			*TabBarGadget\MaxTabLength = Value
	EndSelect
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt den Wert eines Attributs der Registerkartenleiste zurück.
Procedure.i GetTabBarGadgetAttribute(Gadget.i, Attribute.i)
	
	Protected *TabBarGadget.TabBarGadget = GetGadgetData(Gadget)
	
	Select Attribute
		Case #TabBarGadget_CloseButton, #TabBarGadget_NewTab, #TabBarGadget_MirroredTabs, #TabBarGadget_TextCutting, #TabBarGadget_NoTabMoving, #TabBarGadget_BottomLine, #TabBarGadget_MultiLine
			If *TabBarGadget\Attributes & Attribute
				ProcedureReturn #True
			Else
				ProcedureReturn #False
			EndIf
		Case #TabBarGadget_TabRounding
			ProcedureReturn *TabBarGadget\Radius
		Case #TabBarGadget_MinTabLength
			ProcedureReturn *TabBarGadget\MinTabLength
		Case #TabBarGadget_MaxTabLength
			ProcedureReturn *TabBarGadget\MaxTabLength
	EndSelect
	
EndProcedure



; Ändert den Daten-Wert der angegebenen Registerkarte.
Procedure SetTabBarGadgetItemData(Gadget.i, Position.i, DataValue.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		*Item\DataValue = DataValue
	EndIf
	
EndProcedure



; Gibt den Daten-Wert der angegebenen Registerkarte zurück.
Procedure.i GetTabBarGadgetItemData(Gadget.i, Position.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		ProcedureReturn *Item\DataValue
	EndIf
	
EndProcedure



; Ändert das Icon der angegebenen Registerkarte.
Procedure SetTabBarGadgetItemImage(Gadget.i, Position.i, ImageID.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		*Item\Image = TabBarGadget_ReplaceImage(*Item\Image, ImageID)
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Ändert die Farbe der angegebenen Registerkarte.
Procedure SetTabBarGadgetItemColor(Gadget.i, Position.i, Type.i, Color.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		Select Type
			Case #PB_Gadget_FrontColor
				If Color = #PB_Default
					Color = TabBarGadgetInclude\TextColor
				EndIf
				*Item\Color\Text = Color | $FF<<24
			Case #PB_Gadget_BackColor
				If Color = #PB_Default
					Color = TabBarGadgetInclude\FaceColor
				EndIf
				*Item\Color\Background = Color | $FF<<24
		EndSelect
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt die Farbe der angegebenen Registerkarte zurück.
Procedure.i GetTabBarGadgetItemColor(Gadget.i, Position.i, Type.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		Select Type
			Case #PB_Gadget_FrontColor
				ProcedureReturn *Item\Color\Text
			Case #PB_Gadget_BackColor
				ProcedureReturn *Item\Color\Background
		EndSelect
	EndIf
	
EndProcedure



; Ändert den Text der angegebenen Registerkarte.
Procedure SetTabBarGadgetItemText(Gadget.i, Position.i, Text.s)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		*Item\Text      = Text
		*Item\ShortText = Text
	EndIf
	
	UpdateTabBarGadget(Gadget)
	
EndProcedure



; Gibt den Text der angegebenen Registerkarte zurück.
Procedure.s GetTabBarGadgetItemText(Gadget.i, Position.i)
	
	Protected *Item.TabBarGadgetItem = TabBarGadgetItemID(Gadget, Position)
	
	If *Item
		ProcedureReturn *Item\Text
	EndIf
	
EndProcedure





; IDE Options = PureBasic 5.10 Beta 2 (Windows - x64)
; CursorPosition = 19
; FirstLine = 9
; Folding = -Lgxju--
; EnableXP