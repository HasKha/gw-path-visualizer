#include <StringConstants.au3>
#include <GuiConstantsEx.au3>
#include <GDIPlus.au3>
#include <Math.au3>


Opt('MustDeclareVars', 1)
Opt("GUIOnEventMode", 1)

_GDIPlus_Startup()

; =======================
; ==== Configuration ====
; =======================

; General global configuration
Global Const $bgWidth = 1362
Global Const $bgHeight = 1374
Global Const $bg = _GDIPlus_ImageLoadFromFile("data/Domain_of_Anguish_map_clean.jpg")

; The following values are used to align the image with the positions from the pathing map. Somewhat arbitraty.
Global Const $scale = 2
Global Const $translate_Y = -50
Global Const $width = $bgWidth/$scale - 1 ; because 680 is better than 681
Global Const $height = $bgHeight/$scale - 87 ; because 600

; Additional startup delay in milliseconds. Makes it easier to start recording software.
Global Const $additional_delay = 0

; Optional, define colors for convenience
Global Const $cyan = "0xFF00FFFF"
Global Const $white = "0xFFFFFFFF"
Global Const $yellow = "0xFFFFFF00"
Global Const $pink = "0xFFFF00FF"

; Path log input
Global Const $count = 6 ; set number of players
Global $players[$count][3] ; player info: [pos array, small pen, big pen]
LoadPlayerPath(0, "data/tt.log", $white)
LoadPlayerPath(1, "data/mt.log", $white)
LoadPlayerPath(2, "data/caller.log", $yellow)
LoadPlayerPath(3, "data/tk.log", $yellow)
LoadPlayerPath(4, "data/iau.log", $yellow)
LoadPlayerPath(5, "data/emo.log", $pink)

; Shadowstep brush (colors)
Global Const $penShadowStepBig = _GDIPlus_PenCreate($cyan, 2)
Global Const $penShadowStepSmall = _GDIPlus_PenCreate($cyan, 1)

; ==== End of Configuration ====

Func LoadPlayerPath($i, $file, $color)
	$players[$i][0] = PosArrFromFileArr(FileReadToArray($file))
	$players[$i][1] = _GDIPlus_PenCreate($color, 1)
	$players[$i][2] = _GDIPlus_PenCreate($color, 2)
EndFunc


Global Const $hGUI = GUICreate("Path test", $width, $height)
GUISetOnEvent($GUI_EVENT_CLOSE, "Close")
GUISetState(@SW_SHOW)

Global Const $Graphic = _GDIPlus_GraphicsCreateFromHWND ($hGUI) ;create graphic
Global Const $bufferBitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $Graphic) ; buffer bitmap
Global Const $bufferGraphics = _GDIPlus_ImageGetGraphicsContext($bufferBitmap)
_GDIPlus_GraphicsClear($bufferBitmap)

Global Const $shadingPathBitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $Graphic)
Global Const $shadingPathGraphics = _GDIPlus_ImageGetGraphicsContext($shadingPathBitmap)
_GDIPlus_GraphicsClear($shadingPathBitmap)

Global Const $currPosBitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $Graphic)
Global Const $currPosGraphics = _GDIPlus_ImageGetGraphicsContext($currPosBitmap)
_GDIPlus_GraphicsClear($currPosBitmap)

Global Const $thinPathBitmap = _GDIPlus_BitmapCreateFromGraphics($width, $height, $Graphic) ; path 2 bitmap (fading out)
Global Const $thinPathGraphics = _GDIPlus_ImageGetGraphicsContext($thinPathBitmap)
_GDIPlus_GraphicsClear($thinPathBitmap)

Global Const $brushWhite = _GDIPlus_BrushCreateSolid("0xFFFFFFFF")
Global Const $penBlackSmall = _GDIPlus_PenCreate("0xFF000000", 1)

Global Const $resizedBg = _GDIPlus_ImageResize($bg, $bgWidth/$scale, $bgHeight/$scale)

Global Const $textFormat = _GDIPlus_StringFormatCreate()
Global Const $textFamily = _GDIPlus_FontFamilyCreate("Arial")
Global Const $textFont = _GDIPlus_FontCreate($textFamily, 14)
Global Const $textLayout = _GDIPlus_RectFCreate(20, $height - 40, 200, 40)

Global $colorLUT[256][4]
For $i = 0 To 255
	$colorLUT[$i][0] = _Max(0, $i-1)
	$colorLUT[$i][1] = $i
	$colorLUT[$i][2] = $i
	$colorLUT[$i][3] = $i
Next
Global Const $effectLUT = _GDIPlus_EffectCreateColorLUT($colorLUT)

Global $index[$count]
Global $arrSize[$count]

For $i = 0 To $count-1
	$index[$i] = 2
Next

Global $currTime = 2000

_GDIPlus_GraphicsClear($bufferGraphics)
_GDIPlus_GraphicsDrawImage($bufferGraphics, $resizedBg, 0, $translate_Y)
_GDIPlus_GraphicsDrawImageRect($Graphic, $bufferBitmap, 0, 0, $width, $height) ;copy to bitmap

Sleep($additional_delay)

While 1
	_GDIPlus_BitmapApplyEffect($shadingPathBitmap, $effectLUT)
	_GDIPlus_GraphicsClear($currPosGraphics, "0x00000000")

	For $i = 0 To $count-1
		draw($i)
	Next

	_GDIPlus_GraphicsClear($bufferGraphics)
	_GDIPlus_GraphicsDrawImage($bufferGraphics, $resizedBg, 0, $translate_Y)
	_GDIPlus_GraphicsDrawImageRect($bufferGraphics, $thinPathBitmap, 0, 0, $width, $height)
	_GDIPlus_GraphicsDrawImageRect($bufferGraphics, $shadingPathBitmap, 0, 0, $width, $height)
	_GDIPlus_GraphicsDrawImageRect($bufferGraphics, $currPosBitmap, 0, 0, $width, $height)
	_GDIPlus_GraphicsDrawStringEx($bufferGraphics, formatTime($currTime), $textFont, $textLayout, $textFormat, $brushWhite)
	_GDIPlus_GraphicsDrawImageRect($Graphic, $bufferBitmap, 0, 0, $width, $height)

	Sleep(5)

	$currTime += 300
WEnd

Func formatTime($t)
	Local $sec = Floor($t / 1000)
	Local $min = Floor($sec / 60)
	Return StringFormat("%02d : %02d", $min, Mod($sec, 60))
EndFunc

Func draw($k)
	Local $lIndex = $index[$k]
	Local $lPosArr = $players[$k][0]

	If $lIndex > $lPosArr[0][0] Then Return

	If $lPosArr[$lIndex][0] > $currTime Then
		Local $oldX = $lPosArr[$lIndex-1][1]
		Local $oldY = $lPosArr[$lIndex-1][2]
		_GDIPlus_GraphicsFillEllipse($currPosGraphics, $oldX-2, $oldY-2, 5, 5)
		_GDIPlus_GraphicsDrawEllipse($currPosGraphics, $oldX-2, $oldY-2, 5, 5, $players[$k][1])
	Else
		Local $oldX = $lPosArr[$lIndex-1][1]
		Local $oldY = $lPosArr[$lIndex-1][2]
		Local $newX = $lPosArr[$lIndex][1]
		Local $newY = $lPosArr[$lIndex][2]
		If ComputeSqrDistance($oldX, $oldY, $newX, $newY) < 200 Then
			_GDIPlus_GraphicsDrawLine($shadingPathGraphics, $oldX, $oldY, $newX, $newY, $players[$k][2])
			_GDIPlus_GraphicsDrawLine($thinPathGraphics, $oldX, $oldY, $newX, $newY, $players[$k][1])
		Else
			_GDIPlus_GraphicsDrawLine($shadingPathGraphics, $oldX, $oldY, $newX, $newY, $penShadowStepBig)
			_GDIPlus_GraphicsDrawLine($thinPathGraphics, $oldX, $oldY, $newX, $newY, $penShadowStepSmall)
		EndIf
		_GDIPlus_GraphicsFillEllipse($currPosGraphics, $newX-2, $newY-2, 5, 5)
		_GDIPlus_GraphicsDrawEllipse($currPosGraphics, $newX-2, $newY-2, 5, 5, $players[$k][1])
		$index[$k] = $lIndex + 1
	EndIf
EndFunc

Func ComputeSqrDistance($aX1, $aY1, $aX2, $aY2)
	Return ($aX1 - $aX2) ^ 2 + ($aY1 - $aY2) ^ 2
EndFunc

Func MyFileReadLine($hFile)
	Local $line = FileReadLine($hFile)
	If @error = -1 Then Return SetError(1)

	Local $right = StringTrimLeft($line, 22) ; date and time takes 22 chars
	Local $split = StringSplit($right, " ",  $STR_ENTIRESPLIT + $STR_NOCOUNT)

	Local $timeStr = StringTrimLeft($split[0], 5)
	Local $xStr = StringTrimLeft($split[1], 2)
	Local $yStr = StringTrimLeft($split[2], 2)

	Local $lRet[3]
	$lRet[0] = Number($timeStr)
	$lRet[1] = convertCoordX(Number($xStr, 3))
	$lRet[2] = convertCoordY(Number($yStr, 3))
	Return $lRet
EndFunc

Func convertCoordX($x)
	Return $x / 70 + 340
EndFunc

Func convertCoordY($y)
	Return -$y / 70 + 340 + $translate_Y
EndFunc

Func PosArrFromFileArr($fileArr)
	Local $size = UBound($fileArr)
	Local $lPos[$size+1][3]
	$lPos[0][0] = $size
	For $i = 1 To $size
		Local $right = StringTrimLeft($fileArr[$i-1], 22) ; date and time takes 22 chars
		Local $split = StringSplit($right, " ",  $STR_ENTIRESPLIT + $STR_NOCOUNT)

		Local $timeStr = StringTrimLeft($split[0], 5)
		Local $xStr = StringTrimLeft($split[1], 2)
		Local $yStr = StringTrimLeft($split[2], 2)

		$lPos[$i][0] = Number($timeStr)
		$lPos[$i][1] = convertCoordX(Number($xStr, 3))
		$lPos[$i][2] = convertCoordY(Number($yStr, 3))
	Next
	Return $lPos
EndFunc

Func Close(); Clean up resources. Called on-event.
	_GDIPlus_GraphicsDispose($Graphic)

	_GDIPlus_BitmapDispose($bufferBitmap)
	_GDIPlus_GraphicsDispose($bufferGraphics)

	_GDIPlus_BitmapDispose($shadingPathBitmap)
	_GDIPlus_GraphicsDispose($shadingPathGraphics)

	_GDIPlus_BitmapDispose($thinPathBitmap)
	_GDIPlus_GraphicsDispose($thinPathGraphics)

	_GDIPlus_BitmapDispose($currPosBitmap)
	_GDIPlus_GraphicsDispose($currPosGraphics)

	_GDIPlus_PenDispose($penShadowStepBig)
	_GDIPlus_PenDispose($penShadowStepSmall)

	For $i = 0 To $count - 1
		_GDIPlus_PenDispose($players[$i][1])
		_GDIPlus_PenDispose($players[$i][2])
	Next

	_GDIPlus_Shutdown()
	Exit
EndFunc
