@ *****************************************************************
@
@               The Compcert verified compiler
@
@           Xavier Leroy, INRIA Paris-Rocquencourt
@
@ Copyright (c) 2013 Institut National de Recherche en Informatique et
@  en Automatique.
@
@ Redistribution and use in source and binary forms, with or without
@ modification, are permitted provided that the following conditions are met:
@     * Redistributions of source code must retain the above copyright
@       notice, this list of conditions and the following disclaimer.
@     * Redistributions in binary form must reproduce the above copyright
@       notice, this list of conditions and the following disclaimer in the
@       documentation and/or other materials provided with the distribution.
@     * Neither the name of the <organization> nor the
@       names of its contributors may be used to endorse or promote products
@       derived from this software without specific prior written permission.
@ 
@ THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
@ "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
@ LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
@ A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT
@ HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
@ EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
@ PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
@ PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
@ LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
@ NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
@ SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
@
@ *********************************************************************

@ Helper functions for 64-bit integer arithmetic.  ARM version.

        .text

@@@ Conversion from signed 64-bit integer to single float
	
	.global __i64_stof
__i64_stof:
    @ Check whether -2^53 <= X < 2^53
        mov r2, r1, asr #21
        mov r3, r1, asr #31     @ (r2,r3) = X >> 53
        adds r2, r2, #1
        adc r3, r3, #0          @ (r2,r3) = X >> 53 + 1
        cmp r3, #2
        blo 1f
   @ X is large enough that double rounding can occur.
   @ Avoid it by nudging X away from the points where double rounding
   @ occurs (the "round to odd" technique)
	mov r2, #0x700
        orr r2, r2, #0xFF       @ r2 = 0x7FF
        and r3, r0, r2          @ extract bits 0 to 11 of X
        add r3, r3, r2          @ r3 = (X & 0x7FF) + 0x7FF
   @ bit 12 of r3 is 0 if all low 12 bits of X are 0, 1 otherwise
   @ bits 13-31 of r3 are 0
        orr r0, r0, r3          @ correct bit number 12 of X
	bic r0, r0, r2          @ set to 0 bits 0 to 11 of X
   @ Convert to double
1:      fmsr s0, r0
        fuitod d0, s0           @ convert low half to double (unsigned)
        fmsr s2, r1
        fsitod d1, s2           @ convert high half to double (signed)
        fldd d2, .LC1           @ d2 = 2^32
        fmacd d0, d1, d2        @ d0 = d0 + d1 * d2 = double value of int64
   @ Round to single
        fcvtsd s0, d0
   @ Return result in r0
	fmrs r0, s0
        bx lr
	.type __i64_stof, %function
	.size __i64_stof, . - __i64_stof

        .balign 8
.LC1:   .quad 0x41f0000000000000 @ 2^32 in double precision
