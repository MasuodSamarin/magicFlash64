; 
; Copyright (c) 2019 Andreas Zschunke
; 
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
; 

.include "magicFlash64Lib.inc"
.include "magicFlash64LibPgm.inc"
.include "zeropage.inc"

.import __ZEROPAGE_SIZE__
.import __ZEROPAGE_RUN__
.segment "LOADADDR"
.export __LOADADDR__
__LOADADDR__:
.lobytes $0801
.hibytes $0801

.segment "EXEHDR"
.byte $0B, $08, $F0, $02, $9E, $32, $30, $36, $31, $00, $00, $00


.segment "STARTUP"
.export __STARTUP__
__STARTUP__:
  sei

  ldx #0
:
    lda __ZEROPAGE_RUN__,x
    sta zpSave,x
    inx
    cpx #<__ZEROPAGE_SIZE__
    bne :-


  lda #$14
  jsr _ekLed

  jsr _ekGetSelected
  sta slot

  jsr _ekGetVersion
  
  ; if mj >= 1 ; bootLoader and recovery are present
  cmp #0
  beq :+
    lda #<(fw+FW_ADDR)
    ldx #>(fw+FW_ADDR)
    jmp updCont
:
  ; else if minor >= 1 ; old 0.x fw
  cpx #0
  beq :+
    lda #<fw
    ldx #>fw
    jmp updCont
:
  ; else 
  jsr _ekGetMode
  ;   if mode == 1 ; recovery mode active
  cmp #1 
  bne :+
    lda #55
    sta slot

    lda #<(fw+FW_ADDR)
    ldx #>(fw+FW_ADDR)
    jmp updCont
:
  ;   else if mode == 0 ; everything responded with 0 -> no magicFlash64 found
  cmp #0 
  bne :+++
    jsr restoreZp
    cli
    ldx #0
:
      lda nothingFoundMsg,x
      beq :+
      jsr $ffd2
      inx
      bne :-
:
    rts

:
  ;   else ; mode > 1 with ver=0.0 -> illegal
    jsr restoreZp
    cli
    ldx #0
:
      lda invalidModeMsg,x
      beq :+
      jsr $ffd2
      inx
      bne :-
:
    rts

updCont:
  jsr _ekFwUpd

  lda slot
  jsr _ekSelect

  jsr restoreZp


  cli

  ldx #0
:
    lda doneMsg,x
    beq :+
    jsr $ffd2
    inx
    bne :-
:

  rts
restoreZp:
  ldx #0
:
    lda zpSave,x
    sta __ZEROPAGE_RUN__,x
    inx
    cpx #<__ZEROPAGE_SIZE__
    bne :-
  rts
.bss
zpSave:
 .res   $80

.code
.export doneMsg
doneMsg:
  .byte "update done",13,0
.export nothingFoundMsg
nothingFoundMsg:
  .byte "no magicflash64 detected",13,0
.export invalidModeMsg
invalidModeMsg:
  .byte "invalid mode detected",13,0
.export fw
fw:
  .incbin "mf64-firmware.bin"
fwEnd:
  .res $1000-(fwEnd-fw),$ff
  


  
