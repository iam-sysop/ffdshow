;*****************************************************************************
;* predict-a.asm: h264 encoder library
;*****************************************************************************
;* Copyright (C) 2005 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*
;* This program is free software; you can redistribute it and/or modify
;* it under the terms of the GNU General Public License as published by
;* the Free Software Foundation; either version 2 of the License, or
;* (at your option) any later version.
;*
;* This program is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;* GNU General Public License for more details.
;*
;* You should have received a copy of the GNU General Public License
;* along with this program; if not, write to the Free Software
;* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
;*****************************************************************************

BITS 32

;=============================================================================
; Macros and other preprocessor constants
;=============================================================================

%include "i386inc.asm"

%macro STORE8x8 2
    movq        [edx + 0*FDEC_STRIDE], %1
    movq        [edx + 1*FDEC_STRIDE], %1
    movq        [edx + 2*FDEC_STRIDE], %1
    movq        [edx + 3*FDEC_STRIDE], %1
    movq        [edx + 4*FDEC_STRIDE], %2
    movq        [edx + 5*FDEC_STRIDE], %2
    movq        [edx + 6*FDEC_STRIDE], %2
    movq        [edx + 7*FDEC_STRIDE], %2
%endmacro

%macro STORE16x16 2
    mov         eax, 4
.loop:
    movq        [edx + 0*FDEC_STRIDE], %1
    movq        [edx + 1*FDEC_STRIDE], %1
    movq        [edx + 2*FDEC_STRIDE], %1
    movq        [edx + 3*FDEC_STRIDE], %1
    movq        [edx + 0*FDEC_STRIDE + 8], %2
    movq        [edx + 1*FDEC_STRIDE + 8], %2
    movq        [edx + 2*FDEC_STRIDE + 8], %2
    movq        [edx + 3*FDEC_STRIDE + 8], %2
    add         edx, 4*FDEC_STRIDE
    dec         eax
    jg          .loop
    nop
%endmacro

%macro STORE16x16_SSE2 1
    mov         eax, 4
.loop:
    movdqa      [edx + 0*FDEC_STRIDE], %1
    movdqa      [edx + 1*FDEC_STRIDE], %1
    movdqa      [edx + 2*FDEC_STRIDE], %1
    movdqa      [edx + 3*FDEC_STRIDE], %1
    add         edx, 4*FDEC_STRIDE
    dec         eax
    jg          .loop
    nop
%endmacro

SECTION_RODATA

ALIGN 16
pb_1:       times 16 db 1
pw_2:       times 4 dw 2
pw_4:       times 4 dw 4
pw_8:       times 8 dw 8
pw_76543210:
pw_3210:    dw 0, 1, 2, 3, 4, 5, 6, 7
pb_00s_ff:  times 8 db 0
pb_0s_ff:   times 7 db 0 
            db 0xff

;=============================================================================
; Code
;=============================================================================

SECTION .text

; dest, left, right, src, tmp
; output: %1 = (t[n-1] + t[n]*2 + t[n+1] + 2) >> 2
; dest, left, right, src, tmp
; output: %1 = (t[n-1] + t[n]*2 + t[n+1] + 2) >> 2
%macro PRED8x8_LOWPASS0 6
    mov%6       %5, %2
    pavgb       %2, %3
    pxor        %3, %5
    mov%6       %1, %4
    pand        %3, [pb_1 GLOBAL]
    psubusb     %2, %3
    pavgb       %1, %2
%endmacro
%macro PRED8x8_LOWPASS 5
    PRED8x8_LOWPASS0 %1, %2, %3, %4, %5, q
%endmacro
%macro PRED8x8_LOWPASS_XMM 5
    PRED8x8_LOWPASS0 %1, %2, %3, %4, %5, dqa
%endmacro


;-----------------------------------------------------------------------------
; void predict_4x4_ddl_mmxext( uint8_t *src )
;-----------------------------------------------------------------------------
cglobal predict_4x4_ddl_mmxext
    mov         eax, [esp + 4]
    picgetgot   ecx
    movq        mm3, [eax - FDEC_STRIDE    ]
    movq        mm1, [eax - FDEC_STRIDE - 1]
    movq        mm2, mm3
    movq        mm4, [pb_0s_ff GLOBAL]
    psrlq       mm2, 8
    pand        mm4, mm3
    por         mm2, mm4
    PRED8x8_LOWPASS mm0, mm1, mm2, mm3, mm5
%assign Y 0
%rep 4
    psrlq       mm0, 8
    movd        [eax + Y * FDEC_STRIDE], mm0
%assign Y (Y+1)
%endrep
    ret

;-----------------------------------------------------------------------------
; void predict_4x4_vl_mmxext( uint8_t *src )
;-----------------------------------------------------------------------------
cglobal predict_4x4_vl_mmxext
    mov         eax, [esp + 4]
    picgetgot   ecx
    movq        mm1, [eax - FDEC_STRIDE]
    movq        mm3, mm1
    movq        mm2, mm1
    psrlq       mm3, 8
    psrlq       mm2, 16
    movq        mm4, mm3
    pavgb       mm4, mm1
    PRED8x8_LOWPASS mm0, mm1, mm2, mm3, mm5
    movd        [eax + 0*FDEC_STRIDE], mm4
    movd        [eax + 1*FDEC_STRIDE], mm0
    psrlq       mm4, 8
    psrlq       mm0, 8
    movd        [eax + 2*FDEC_STRIDE], mm4
    movd        [eax + 3*FDEC_STRIDE], mm0

    ret


;-----------------------------------------------------------------------------
; void predict_8x8_v_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_v_mmxext
    mov         eax, [esp+8]
    mov         edx, [esp+4]
    movq        mm0, [eax+16]
    STORE8x8    mm0, mm0
    ret

;-----------------------------------------------------------------------------
; void predict_8x8_dc_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_dc_mmxext
    picgetgot   ecx
    mov         eax, [esp + 8]
    mov         edx, [esp + 4]
    pxor        mm0, mm0
    pxor        mm1, mm1
    psadbw      mm0, [eax+7]
    psadbw      mm1, [eax+16]
    paddw       mm0, [pw_8 GLOBAL]
    paddw       mm0, mm1
    psrlw       mm0, 4
    pshufw      mm0, mm0, 0
    packuswb    mm0, mm0
    STORE8x8    mm0, mm0
    ret

;-----------------------------------------------------------------------------
; void predict_8x8_top_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
%macro PRED8x8_DC 2
cglobal %1
    picgetgot   ecx
    mov         eax, [esp + 8]
    mov         edx, [esp + 4]
    pxor        mm0, mm0
    psadbw      mm0, [eax+%2]
    paddw       mm0, [pw_4 GLOBAL]
    psrlw       mm0, 3
    pshufw      mm0, mm0, 0
    packuswb    mm0, mm0
    STORE8x8    mm0, mm0
    ret
%endmacro

PRED8x8_DC predict_8x8_dc_top_mmxext, 16
PRED8x8_DC predict_8x8_dc_left_mmxext, 7

;-----------------------------------------------------------------------------
; void predict_8x8_ddl_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddl_mmxext
    picgetgot   ecx
    mov         eax, [esp + 8]
    mov         edx, [esp + 4]
    movq        mm1, [eax + 15]
    movq        mm2, [eax + 17]
    movq        mm3, [eax + 23]
    movq        mm4, [eax + 25]
    PRED8x8_LOWPASS mm0, mm1, mm2, [eax + 16], mm7
    PRED8x8_LOWPASS mm1, mm3, mm4, [eax + 24], mm6

%assign Y 7
%rep 6
    movq        [edx + Y*FDEC_STRIDE], mm1
    movq        mm2, mm0
    psllq       mm1, 8
    psrlq       mm2, 56
    psllq       mm0, 8
    por         mm1, mm2
%assign Y (Y-1)
%endrep
    movq        [edx + Y*FDEC_STRIDE], mm1
    psllq       mm1, 8
    psrlq       mm0, 56
    por         mm1, mm0
%assign Y (Y-1)
    movq        [edx + Y*FDEC_STRIDE], mm1

    ret

;-----------------------------------------------------------------------------
; void predict_8x8_ddr_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddr_mmxext
    picgetgot   ecx
    mov         eax, [esp + 8]
    mov         edx, [esp + 4]
    movq        mm1, [eax + 7]
    movq        mm2, [eax + 9]
    movq        mm3, [eax + 15]
    movq        mm4, [eax + 17]
    PRED8x8_LOWPASS mm0, mm1, mm2, [eax + 8], mm7
    PRED8x8_LOWPASS mm1, mm3, mm4, [eax + 16], mm6

%assign Y 7
%rep 6
    movq        [edx + Y*FDEC_STRIDE], mm0
    movq        mm2, mm1
    psrlq       mm0, 8
    psllq       mm2, 56
    psrlq       mm1, 8
    por         mm0, mm2
%assign Y (Y-1)
%endrep
    movq        [edx + Y*FDEC_STRIDE], mm0
    psrlq       mm0, 8
    psllq       mm1, 56
    por         mm0, mm1
%assign Y (Y-1)
    movq        [edx + Y*FDEC_STRIDE], mm0

    ret

;-----------------------------------------------------------------------------
; void predict_8x8_vr_core_mmxext( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------

; fills only some pixels:
; f01234567
; 0........
; 1,,,,,,,,
; 2 .......
; 3 ,,,,,,,
; 4  ......
; 5  ,,,,,,
; 6   .....
; 7   ,,,,,

cglobal predict_8x8_vr_core_mmxext
    picgetgot   ecx
    mov         eax, [esp + 8]
    mov         edx, [esp + 4]
    movq        mm2, [eax + 16]
    movq        mm3, [eax + 15]
    movq        mm1, [eax + 14]
    movq        mm4, mm3
    pavgb       mm3, mm2
    PRED8x8_LOWPASS mm0, mm1, mm2, mm4, mm7

%assign Y 0
%rep 3
    movq        [edx +  Y   *FDEC_STRIDE], mm3
    movq        [edx + (Y+1)*FDEC_STRIDE], mm0
    psllq       mm3, 8
    psllq       mm0, 8
%assign Y (Y+2)
%endrep
    movq        [edx +  Y   *FDEC_STRIDE], mm3
    movq        [edx + (Y+1)*FDEC_STRIDE], mm0

    ret

;-----------------------------------------------------------------------------
; void predict_8x8c_v_mmx( uint8_t *src )
;-----------------------------------------------------------------------------
cglobal predict_8x8c_v_mmx
    mov         edx, [esp + 4]
    movq        mm0, [edx - FDEC_STRIDE]
    STORE8x8    mm0, mm0
    ret

;-----------------------------------------------------------------------------
; void predict_8x8c_dc_core_mmxext( uint8_t *src, int s2, int s3 )
;-----------------------------------------------------------------------------
cglobal predict_8x8c_dc_core_mmxext
    picgetgot   ecx

    mov         edx, [esp + 4]

    movq        mm0, [edx - FDEC_STRIDE]
    pxor        mm1, mm1
    pxor        mm2, mm2
    punpckhbw   mm1, mm0
    punpcklbw   mm0, mm2
    psadbw      mm1, mm2        ; s1
    psadbw      mm0, mm2        ; s0

    paddw       mm0, [esp +  8]
    pshufw      mm2, [esp + 12], 0
    psrlw       mm0, 3
    paddw       mm1, [pw_2 GLOBAL]
    movq        mm3, mm2
    pshufw      mm1, mm1, 0
    pshufw      mm0, mm0, 0     ; dc0 (w)
    paddw       mm3, mm1
    psrlw       mm3, 3          ; dc3 (w)
    psrlw       mm2, 2          ; dc2 (w)
    psrlw       mm1, 2          ; dc1 (w)

    packuswb    mm0, mm1        ; dc0,dc1 (b)
    packuswb    mm2, mm3        ; dc2,dc3 (b)

    STORE8x8    mm0, mm2
    ret

;-----------------------------------------------------------------------------
; void predict_8x8c_p_core_mmxext( uint8_t *src, int i00, int b, int c )
;-----------------------------------------------------------------------------
cglobal predict_8x8c_p_core_mmxext
    picgetgot   ecx

    mov         edx, [esp + 4]
    pshufw      mm0, [esp + 8], 0
    pshufw      mm2, [esp +12], 0
    pshufw      mm4, [esp +16], 0
    movq        mm1, mm2
    pmullw      mm2, [pw_3210 GLOBAL]
    psllw       mm1, 2
    paddsw      mm0, mm2        ; mm0 = {i+0*b, i+1*b, i+2*b, i+3*b}
    paddsw      mm1, mm0        ; mm1 = {i+4*b, i+5*b, i+6*b, i+7*b}

    mov         eax, 8
ALIGN 4
.loop:
    movq        mm5, mm0
    movq        mm6, mm1
    psraw       mm5, 5
    psraw       mm6, 5
    packuswb    mm5, mm6
    movq        [edx], mm5

    paddsw      mm0, mm4
    paddsw      mm1, mm4
    add         edx, FDEC_STRIDE
    dec         eax
    jg          .loop

    nop
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_p_core_mmxext( uint8_t *src, int i00, int b, int c )
;-----------------------------------------------------------------------------
cglobal predict_16x16_p_core_mmxext
    picgetgot   ecx

    mov         edx, [esp + 4]
    pshufw      mm0, [esp + 8], 0
    pshufw      mm2, [esp +12], 0
    pshufw      mm4, [esp +16], 0
    movq        mm5, mm2
    movq        mm1, mm2
    pmullw      mm5, [pw_3210 GLOBAL]
    psllw       mm2, 3
    psllw       mm1, 2
    movq        mm3, mm2
    paddsw      mm0, mm5        ; mm0 = {i+ 0*b, i+ 1*b, i+ 2*b, i+ 3*b}
    paddsw      mm1, mm0        ; mm1 = {i+ 4*b, i+ 5*b, i+ 6*b, i+ 7*b}
    paddsw      mm2, mm0        ; mm2 = {i+ 8*b, i+ 9*b, i+10*b, i+11*b}
    paddsw      mm3, mm1        ; mm3 = {i+12*b, i+13*b, i+14*b, i+15*b}

    mov         eax, 16
ALIGN 4
.loop:
    movq        mm5, mm0
    movq        mm6, mm1
    psraw       mm5, 5
    psraw       mm6, 5
    packuswb    mm5, mm6
    movq        [edx], mm5

    movq        mm5, mm2
    movq        mm6, mm3
    psraw       mm5, 5
    psraw       mm6, 5
    packuswb    mm5, mm6
    movq        [edx+8], mm5

    paddsw      mm0, mm4
    paddsw      mm1, mm4
    paddsw      mm2, mm4
    paddsw      mm3, mm4
    add         edx, FDEC_STRIDE
    dec         eax
    jg          .loop

    nop
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_p_core_sse2( uint8_t *src, int i00, int b, int c )
;-----------------------------------------------------------------------------
cglobal predict_16x16_p_core_sse2
    picgetgot   ecx

    mov         edx,  [esp + 4 ]
    movd        xmm0, [esp + 8 ]
    movd        xmm1, [esp + 12]
    movd        xmm2, [esp + 16]
    pshuflw     xmm0, xmm0, 0
    pshuflw     xmm1, xmm1, 0
    pshuflw     xmm2, xmm2, 0
    punpcklqdq  xmm0, xmm0
    punpcklqdq  xmm1, xmm1
    punpcklqdq  xmm2, xmm2
    movdqa      xmm3, xmm1
    pmullw      xmm3, [pw_76543210 GLOBAL]
    psllw       xmm1, 3
    paddsw      xmm0, xmm3  ; xmm0 = {i+ 0*b, i+ 1*b, i+ 2*b, i+ 3*b, i+ 4*b, i+ 5*b, i+ 6*b, i+ 7*b}
    paddsw      xmm1, xmm0  ; xmm1 = {i+ 8*b, i+ 9*b, i+10*b, i+11*b, i+12*b, i+13*b, i+14*b, i+15*b}

    mov         eax, 16
ALIGN 4
.loop:
    movdqa      xmm3, xmm0
    movdqa      xmm4, xmm1
    psraw       xmm3, 5
    psraw       xmm4, 5
    packuswb    xmm3, xmm4
    movdqa      [edx], xmm3

    paddsw      xmm0, xmm2
    paddsw      xmm1, xmm2
    add         edx, FDEC_STRIDE
    dec         eax
    jg          .loop

    nop
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_v_mmx( uint8_t *src )
;-----------------------------------------------------------------------------
cglobal predict_16x16_v_mmx
    mov         edx, [esp + 4]
    movq        mm0, [edx - FDEC_STRIDE]
    movq        mm1, [edx + 8 - FDEC_STRIDE]
    STORE16x16  mm0, mm1
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_v_sse2( uint8_t *src )
;-----------------------------------------------------------------------------
cglobal predict_16x16_v_sse2
    mov         edx, [esp + 4]
    movdqa      xmm0, [edx - FDEC_STRIDE]
    STORE16x16_SSE2 xmm0
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_dc_core_mmxext( uint8_t *src, int i_dc_left )
;-----------------------------------------------------------------------------

%macro PRED16x16_DC 2
    mov         edx, [esp+4]
    pxor        mm0, mm0
    pxor        mm1, mm1
    psadbw      mm0, [edx - FDEC_STRIDE]
    psadbw      mm1, [edx - FDEC_STRIDE + 8]
    paddusw     mm0, mm1
    paddusw     mm0, %1
    psrlw       mm0, %2                 ; dc
    pshufw      mm0, mm0, 0
    packuswb    mm0, mm0                ; dc in bytes
    STORE16x16  mm0, mm0
%endmacro

cglobal predict_16x16_dc_core_mmxext
    PRED16x16_DC [esp+8], 5
    ret

cglobal predict_16x16_dc_top_mmxext
    picgetgot ecx
    PRED16x16_DC [pw_8 GLOBAL], 4
    ret

;-----------------------------------------------------------------------------
; void predict_16x16_dc_core_sse2( uint8_t *src, int i_dc_left )
;-----------------------------------------------------------------------------

%macro PRED16x16_DC_SSE2 2
    mov         edx, [esp+4]
    pxor        xmm0, xmm0
    psadbw      xmm0, [edx - FDEC_STRIDE]
    movhlps     xmm1, xmm0
    paddw       xmm0, xmm1
    paddusw     xmm0, %1
    psrlw       xmm0, %2                ; dc
    pshuflw     xmm0, xmm0, 0
    punpcklqdq  xmm0, xmm0
    packuswb    xmm0, xmm0              ; dc in bytes
    STORE16x16_SSE2 xmm0
%endmacro

cglobal predict_16x16_dc_core_sse2
    movd xmm2, [esp+8]
    PRED16x16_DC_SSE2 xmm2, 5
    ret

cglobal predict_16x16_dc_top_sse2
    picgetgot ecx
    PRED16x16_DC_SSE2 [pw_8 GLOBAL], 4
    ret
    
;-----------------------------------------------------------------------------
; void predict_8x8_ddr_sse2( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddr_sse2
    mov         edx,  [esp + 8]
    mov         eax,  [esp + 4]
    picgetgot   ecx
    movdqu      xmm3, [edx + 8]
    movdqu      xmm1, [edx + 7]
    movdqa      xmm2, xmm3
    psrldq      xmm2, 1
    PRED8x8_LOWPASS_XMM xmm0, xmm1, xmm2, xmm3, xmm4
    movdqa      xmm1, xmm0
    psrldq      xmm1, 1
%assign Y 7
%rep 3
    movq        [eax + Y     * FDEC_STRIDE], xmm0
    movq        [eax + (Y-1) * FDEC_STRIDE], xmm1
    psrldq      xmm0, 2
    psrldq      xmm1, 2
%assign Y (Y-2)
%endrep
    movq        [eax + 1 * FDEC_STRIDE], xmm0
    movq        [eax + 0 * FDEC_STRIDE], xmm1
    ret

;-----------------------------------------------------------------------------
; void predict_8x8_ddl_sse2( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddl_sse2
    mov         edx,  [esp + 8]
    mov         eax,  [esp + 4]
    picgetgot   ecx
    movdqa      xmm3, [edx + 16]
    movdqu      xmm2, [edx + 17]
    movdqa      xmm1, xmm3
    pslldq      xmm1, 1
    PRED8x8_LOWPASS_XMM xmm0, xmm1, xmm2, xmm3, xmm4
%assign Y 0
%rep 8
    psrldq      xmm0, 1
    movq        [eax + Y * FDEC_STRIDE], xmm0
%assign Y (Y+1)
%endrep
    ret

;-----------------------------------------------------------------------------
; void predict_8x8_vl_sse2( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_vl_sse2
    mov         edx,  [esp + 8]
    mov         eax,  [esp + 4]
    picgetgot   ecx
    movdqa      xmm4, [edx + 16]
    movdqa      xmm2, xmm4
    movdqa      xmm1, xmm4
    movdqa      xmm3, xmm4
    psrldq      xmm2, 1
    pslldq      xmm1, 1
    pavgb       xmm3, xmm2
    PRED8x8_LOWPASS_XMM xmm0, xmm1, xmm2, xmm4, xmm5
; xmm0: (t0 + 2*t1 + t2 + 2) >> 2
; xmm3: (t0 + t1 + 1) >> 1
%assign Y 0
%rep 3
    psrldq      xmm0, 1
    movq        [eax + Y     * FDEC_STRIDE], xmm3
    movq        [eax + (Y+1) * FDEC_STRIDE], xmm0
    psrldq      xmm3, 1
%assign Y (Y+2)
%endrep
    psrldq      xmm0, 1
    movq        [eax + Y     * FDEC_STRIDE], xmm3
    movq        [eax + (Y+1) * FDEC_STRIDE], xmm0
    ret
