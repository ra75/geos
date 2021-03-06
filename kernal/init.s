; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Generic initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "jumptab.inc"
.include "c64.inc"

; filesys.s
.import _EnterDeskTop

; graph.s
.import _RecoverRectangle

; hw.s
.import _DoFirstInitIO

; icons.s
.import InitMsePic

; main.s
.import _InterruptMain

; memory.s
.import _InitRam

; panic.s
.import _Panic

; var.s
.import NumTimers
.import clkBoxTemp

.global InitGEOEnv
.ifdef wheels
.global _InitMachine
.else
.global _InitMachine
.endif
.global _FirstInit

.segment "init1"

.ifdef wheels
_InitMachine:
.else
_InitMachine:
.endif
	jsr _DoFirstInitIO
InitGEOEnv:
	LoadW r0, InitRamTab
.ifdef wheels
	.assert * = _InitRam, error, "Code must run into _InitRam"
.else
	jmp _InitRam
.endif

.segment "init2"

;---------------------------------------------------------------
; FirstInit                                               $C271
;
; Function:  Initialize GEOS
;
; Pass:      nothing
; Destroyed: a, y, r0 - r2l
;---------------------------------------------------------------
_FirstInit:
	sei
	cld
.ifdef wheels
	jsr InitMachine
.else
	jsr _InitMachine
.endif
	LoadW EnterDeskTop+1, _EnterDeskTop
	LoadB maxMouseSpeed, iniMaxMouseSpeed
.ifdef wheels_size_and_speed
	.assert iniMouseAccel = iniMaxMouseSpeed, error, "iniMouseAccel != iniMaxMouseSpeed!"
	sta mouseAccel
.endif
	LoadB minMouseSpeed, iniMinMouseSpeed
.ifndef wheels_size_and_speed
	LoadB mouseAccel, iniMouseAccel
.endif

.ifdef wheels
.import sysScrnColors
	MoveB sysScrnColors, screencolors
.else
	LoadB screencolors, (DKGREY << 4)+LTGREY
	sta @1
	jsr i_FillRam
	.word 1000
	.word COLOR_MATRIX
@1:	.byte (DKGREY << 4)+LTGREY
	ldx CPU_DATA
ASSERT_NOT_BELOW_IO
	LoadB CPU_DATA, IO_IN
	LoadB mob0clr, BLUE
	sta mob1clr
	LoadB extclr, BLACK
	stx CPU_DATA
ASSERT_NOT_BELOW_IO
.endif
	ldy #62
@2:	lda #0
	sta mousePicData,Y
	dey
	bpl @2
	ldx #24
@3:	lda InitMsePic-1,x
	sta mousePicData-1,x
	dex
	bne @3
.ifdef wheels
.import sysMob0Clr
.import sysExtClr
.import DrawCheckeredScreen
.global _FirstInit2
.global _FirstInit3
_FirstInit2:
	jsr DrawCheckeredScreen
	lda screencolors
	sta LC54D
	jsr i_ColorRectangle
	.byte 0, 0                 ; origin
	.byte 40, 25               ; size
LC54D:  .byte (DKGREY << 4)+LTGREY ; value
; ----------------------------------------------------------------------------
_FirstInit3:
	ldx     CPU_DATA
ASSERT_NOT_BELOW_IO
	LoadB CPU_DATA, IO_IN
	lda sysExtClr
	sta extclr
	MoveB sysMob0Clr, mob0clr
	sta mob1clr
	stx CPU_DATA
ASSERT_NOT_BELOW_IO
        rts
.else
	jmp UNK_6
.endif

.segment "init3"

.ifndef wheels
UNK_6:
	lda #$bf
	sta A8FF0
	ldx #7
	lda #$bb
@1:	sta A8FE8,x
	dex
	bpl @1
	rts
.endif

.segment "init4"

InitRamTab:
	.word currentMode
	.byte 12
	.byte 0                       ; currentMode
	.byte ST_WR_FORE | ST_WR_BACK ; dispBufferOn
	.byte 0                       ; mouseOn
	.word mousePicData            ; msePicPtr
	.byte 0                       ; windowTop
	.byte SC_PIX_HEIGHT-1         ; windowBottom
	.word 0                       ; leftMargin
	.word SC_PIX_WIDTH-1          ; rightMargin
	.byte 0                       ; pressFlag

	.word appMain
	.byte 28
	.word 0                       ; appMain
	.word _InterruptMain          ; intTopVector
	.word 0                       ; intBotVector
	.word 0                       ; mouseVector
	.word 0                       ; keyVector
	.word 0                       ; inputVector
	.word 0                       ; mouseFaultVec
	.word 0                       ; otherPressVec
	.word 0                       ; StringFaultVec
	.word 0                       ; alarmTmtVector
	.word _Panic                  ; BRKVector
	.word _RecoverRectangle       ; RecoverVector
	.byte SelectFlashDelay        ; selectionFlash
	.byte 0                       ; alphaFlag
	.byte ST_FLASH                ; iconSelFlg
	.byte 0                       ; faultData

	.word NumTimers
	.byte 2
	.byte 0                       ; NumTimers
	.byte 0                       ; menuNumber

	.word clkBoxTemp
	.byte 1
	.byte 0                       ; clkBoxTemp

	.word IconDescVecH
	.byte 1
	.byte 0                       ; IconDescVecH

.ifdef wheels_dlgbox_dblclick
	.word   dblDBData
	.byte   1
	.byte   OPEN
.endif
	.word obj0Pointer
	.byte 8
	.byte $28, $29, $2a, $2b
	.byte $2c, $2d, $2e, $2f

	.word 0
