; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; IRQ/NMI handlers

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "jumptab.inc"
.include "c64.inc"

; keyboard.s
.import _DoKeyboardScan

; var.s
.import KbdQueFlag
.import alarmWarnFlag
.import tempIRQAcc

; used by boot.s
.global _IRQHandler
.global _NMIHandler

.segment "irq"

_IRQHandler:
	cld
	sta tempIRQAcc
	pla
	pha
	and #%00010000
	beq @1
	pla
	jmp (BRKVector)
@1:	txa
	pha
	tya
	pha
.ifdef use2MHz
	LoadB clkreg, 0
.endif
	PushW CallRLo
	PushW returnAddress
	ldx #0
@2:	lda r0,x
	pha
	inx
	cpx #32
	bne @2
	PushB CPU_DATA
ASSERT_NOT_BELOW_IO
	LoadB CPU_DATA, IO_IN
	lda dblClickCount
	beq @3
	dec dblClickCount
@3:	ldy KbdQueFlag
	beq @4
	iny
	beq @4
	dec KbdQueFlag
@4:	jsr _DoKeyboardScan
	lda alarmWarnFlag
	beq @5
	dec alarmWarnFlag
@5:
.ifdef wheels_screensaver
.import ProcessMouse
	lda saverStatus
	lsr
	bcc @Y ; screensaver not running
	jsr ProcessMouse
	jsr GetRandom
	bra @X
.endif
@Y:	lda intTopVector
	ldx intTopVector+1
	jsr CallRoutine
	lda intBotVector
	ldx intBotVector+1
	jsr CallRoutine
@X:	lda #1
	sta grirq
	PopB CPU_DATA
ASSERT_NOT_BELOW_IO
.ifdef use2MHz
	lda #>IRQ2Handler
	sta $ffff
	lda #<IRQ2Handler
	sta $fffe
	LoadB rasreg, $fc
.endif
	ldx #31
@6:	pla
	sta r0,x
	dex
	bpl @6
	PopW returnAddress
	PopW CallRLo
	pla
	tay
	pla
	tax
	lda tempIRQAcc
_NMIHandler:
	rti
.ifdef use2MHz
IRQ2Handler:
	pha
	txa
	pha
	ldx CPU_DATA
ASSERT_NOT_BELOW_IO
	LoadB CPU_DATA, IO_IN
	lda rasreg
	and #%11110000
	beq @1
	cmp #$f0
	bne @2
@1:	LoadB clkreg, 1
@2:	LoadB rasreg, $2c
	LoadW $fffe, _IRQHandler
	inc grirq
	stx CPU_DATA
ASSERT_NOT_BELOW_IO
	pla
	tax
	pla
	rti
.endif
