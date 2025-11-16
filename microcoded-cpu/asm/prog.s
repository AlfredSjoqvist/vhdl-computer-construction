;;; r0: Current value.
;;; r1: Next Value.
;;; r2: Swap indicator
;;; r3: Address counter 
;;; DC: $00FF -- Array End
;;; DD: $00E0 -- Array start
;;; DE: ONE
;;; DF: ZERO
;;; E0: Start of array
;;; FF: Array end
START:
	load r2 dir $DF		; Set swap indicator to 0.
	load r3 dir $DD		; Set start pointer to $E0
ITER:				; Single address pair iteration
        load r1 idx $01		; Load indexed from pointer + 1
	cmp r1	idx $00		; Compare next to current
	bge NEXT_ADDR		; If next >= current, continue iteration
SWAP:	
	load r0 idx $00		; Load current value
	store r1 idx $00	; Store next in current
	store r0 idx $01	; Store current in next
	load r2 dir $DE		; Set swapped flag to 1
NEXT_ADDR:
	add r3 dir $DE		; PTR++
	cmp r3 dir $DC 		; PTR == $FF ?
	bne ITER		; Not finished if not equal
	cmp r2 dir $DF		; Have swapped?
	bne START		; If yes, repeat
	halt
	

	
