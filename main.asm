list p=16f1787
include <p16f1787.inc>
__CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF 


segundosL 		equ		0x20
segundosH		equ		0x21
minutosL		equ		0x22
minutosH		equ		0x23
control			equ		0x24
barr_display		equ		PORTA
display_reg		equ		0x25
dec1_ms			equ		0x26
dec2_ms			equ		0x27
alarma1_ms		equ		0x28
alarma2_ms		equ		0x29
alarma3_ms		equ		0x30
cont_beep		equ		0x31

			org		0x00
			goto		INICIO
			org		0x04
			goto		INT
			org		0x05

INICIO
			banksel OSCCON
			movlw 	0x6F
			movwf 	OSCCON
			banksel ANSELA
			clrf 	ANSELA
			clrf 	ANSELB
			clrf	ANSELD
			banksel	TRISA
			movlw	0xe0
			movwf	TRISA
			clrf	TRISB
			movlw	0xf8		; b'11111000' Nible alto para entradas y nible bajo para salidas
			movwf	TRISC
			movlw	0xfc
			movwf	TRISD
			banksel	OPTION_REG
			movlw	0x01
			movwf	OPTION_REG
	
			; Configuraci�n de interrupciones
			movlw	b'11101000'
			movwf	INTCON

			banksel	IOCCN
			movlw	0xf0
			movwf	IOCCN
	
			; Limpiando los registros
			clrf	BSR	
			clrf	segundosL
			clrf	segundosH
			clrf	minutosL
			clrf	minutosH
			clrf	barr_display
			clrf	PORTA
			clrf	PORTB
			clrf	PORTC
			clrf	PORTD
			clrf	FSR0L
			clrf	FSR0H
			clrf	FSR1L
			clrf	FSR0H
			clrf	control
			clrf	cont_beep
			
			; Inicialización de registro de barrido de display
			movlw	0x01
			movwf	barr_display

			; Inicialización de registro de display
			movlw	segundosL
			movwf	display_reg
	
			; Base de tiempo para el decremento (100*10)ms = 1000ms = 1s
			movlw	.100
			movwf	dec1_ms
			movlw	.10
			movwf	dec2_ms

			; Base de tiempo de alarma (250*2)ms = 500ms <- tiempo de un beep
			movlw	.250
			movwf	alarma1_ms
			movlw	.2
			movwf	alarma2_ms


LOOP			goto	$


INT			btfsc	INTCON, TMR0IF
			goto	TMR_INT
			goto	NIVEL_INT
			

TMR_INT			call	ALARMA
			call	BARR_DISP
			call	SHOW_DIG
			call	DECREMENTA
			bcf	INTCON, TMR0IF
			movlw	.6
			movwf	TMR0
			retfie


NIVEL_INT		call	TECLA_PRES
			clrf	PORTC
			banksel	IOCCF
			clrf	IOCCF
			clrf	BSR
			retfie


BARR_DISP		rlf	barr_display, F
			btfsc	barr_display, 4
			goto	FIX_BARR
			incf	display_reg, F
			movf	display_reg, W
			movwf	FSR0L
			return
FIX_BARR		movlw	0x01
			movwf	barr_display
			movlw	segundosL
			movwf	display_reg
			movwf	FSR0L
			return


SHOW_DIG 		movf	INDF0, W
			call	TABLA_7SEG
			movwf	PORTB
			call	DOT_ON
			return


DOT_ON			movlw	minutosL
			xorwf	display_reg, W
			btfss	STATUS, Z
			return
			bcf	PORTB, 7
			return


TECLA_PRES		movlw	b'11111011'
			movwf	PORTC
			btfss	PORTC, 4
			goto	COLUMNA1A
			btfss	PORTC, 5
			goto	COLUMNA1B
			btfss	PORTC, 6
			goto	COLUMNA1C
			btfss	PORTC, 7
			goto	COLUMNA1D

			movlw	b'11111101'
			movwf	PORTC
			btfss	PORTC, 4
			goto	COLUMNA2A
			btfss	PORTC, 5
			goto	COLUMNA2B
			btfss	PORTC, 6
			goto	COLUMNA2C
			btfss	PORTC, 7
			goto	COLUMNA2D

			movlw	b'11111110'
			movwf	PORTC
			btfss	PORTC, 4
			goto	COLUMNA3A
			btfss	PORTC, 5
			goto	COLUMNA3B
			btfss	PORTC, 6
			goto	COLUMNA3C
			btfss	PORTC, 7
			goto	COLUMNA3D


COLUMNA3A		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.3
			movwf	segundosL
			return
COLUMNA3B		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.6
			movwf	segundosL
			return
COLUMNA3C		btfsc	control, 3 ; Con el bit 3 de control, se comprueba si el reloj ya fue ajustado
			return		   ; Si fue ajustado, se retorna sin hacer más nada
			call	ROTA_DIG
			movlw	.9
			movwf	segundosL
			return
COLUMNA3D		call	SERA_CERO  ; Si se presiona el botón Start
			btfsc	control, 1 ; y el reloj se encuentra en cero
			return		   ; se retorna sin hacer más nada
			btfss	control, 3 ; control[3]=1: Reloj ajustado; control[3]=0 Reloj no ajustado
			bsf	control, 3 ; La primera vez que se pulsa el botón Start/Pause el bit 3 de control se coloca en 1
			btfss	control, 2 ; control[2]=0: Reloj pausado ; control[2]=1: Reloj en curso
			goto	$+4
			bcf	control, 2
			bcf	PORTD, 0
			return
			bsf	control, 2
			bsf	PORTD, 0
			return
COLUMNA2A		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.2
			movwf	segundosL
			return
COLUMNA2B		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.5
			movwf	segundosL
			return
COLUMNA2C		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.8
			movwf	segundosL
			return
COLUMNA2D		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.0
			movwf	segundosL
			return
COLUMNA1A		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.1
			movwf	segundosL
			return
COLUMNA1B		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.4
			movwf	segundosL
			return
COLUMNA1C		btfsc	control, 3
			return
			call	ROTA_DIG
			movlw	.7
			movwf	segundosL
			return
COLUMNA1D		clrf	segundosL
			clrf	segundosH
			clrf	minutosL
			clrf	minutosH
			bcf	PORTD, 0
			bcf	PORTD, 1
			clrf	control
			return



ROTA_DIG		movf	minutosL, W
			movwf	minutosH
			movf	segundosH, W
			movwf	minutosL
			movf	segundosL, W
			movwf	segundosH
			return


; Modifica todo el reloj, pero decrementa solo un segundo
DECREMENTA		;=====================================
			;Se evalúa si se tiene que decrementar
			;=====================================
			call	SERA_CERO
			btfsc	control, 1 ; <- control[1] = 1: El reloj llego a cero; control[1] = 0: El reloj aun tiene datos
			return
			btfss	control, 2
			return
			;=====================================

			;========================
			;Se espera  a que pase 1s
			;========================
			decfsz	dec1_ms, F
			return
			movlw	.100
			movwf	dec1_ms
			decfsz	dec2_ms, F
			return
			movlw	.10
			movwf	dec2_ms
			;========================

			;===============================
			;Se hace el decremento del reloj
			;===============================
			movlw	.0
			xorwf	segundosL, W
			btfsc	STATUS, Z
			goto	$+3		; Salta 3 instrupciones [llega a: movlw .9]
			decf	segundosL, F
			return
			movlw	.9
			movwf	segundosL
			movlw	.0
			xorwf	segundosH, W	
			btfsc	STATUS, Z
			goto	$+3
			decf	segundosH, F
			return
			movlw	.5
			movwf	segundosH
			movlw	.0
			xorwf	minutosL, W
			btfsc	STATUS, Z
			goto	$+3
			decf	minutosL, F
			return
			movlw	.9
			movwf	minutosL
			movlw	.0
			xorwf	minutosH, W
			btfsc	STATUS, Z
			return
			decf	minutosH, F
			return
			;===============================

;=================================================================================================
;Comprueba si los registros de los display est�n en 0; Si lo est�n control[1]=1, sino control[1]=0
;=================================================================================================
SERA_CERO		movlw	segundosL-1	; Una dirección menos que segundosL; W = 0x1f
			movwf	FSR1L
INC_FSR			incf	FSR1L, W	; El primer incremento hace que FSR1L apunte a 0x20
			movwf	FSR1L
			movlw	minutosH+1	; Una dirección más que minutosH; W = 0x24
			xorwf	FSR1L, W
			btfsc	STATUS, Z	; 
			goto	FIN_VERIF
			movf	INDF1, W
			xorlw	.0
			btfsc	STATUS, Z
			goto	INC_FSR
			bcf	control, 1
			return
FIN_VERIF		bsf	control, 1 ; Si el bit 1 de control est� en 1, todos los registro del display est�n en 0
			bcf	control, 2 ; Se pausa el reloj
			btfsc	control, 3 ; Si fue ajustado y lleg� a cero
			bsf	control, 4 ; control[4] se pone a uno
			bcf	PORTD, 0
			return
;=================================================================================================


ALARMA			;==================================
			;Verifica que el reloj llegó a cero
			;==================================
			btfss	control, 4
			return
			btfss	control, 1
			return
			;==================================

			;================================
			;Se espera a que transcurra 500ms
			;================================
			decfsz	alarma1_ms, F
			return
			movlw	.250
			movwf	alarma1_ms
			decfsz	alarma2_ms, F
			return
			movlw	.2
			movwf	alarma2_ms
			call	BEEP
			;================================

			;==================================================
			;Cuenta 3 beeps (3 flancos de subida y 3 de bajada)
			;==================================================
			movlw	.6
			xorwf	cont_beep, W
			btfss	STATUS, Z
			goto	$+2
			goto	FIN_ALARMA
			incf	cont_beep, F
			return
			;==================================================

;==================================================================
;Limpia los registros y devuelve al programa pricipal (LOOP goto $)
;==================================================================
FIN_ALARMA		bcf	PORTD, 1
			clrf	control
			clrf	cont_beep
			retfie
;==================================================================

;========================================
;Alterna el estado del bit 1 del puerto D
;========================================
BEEP			btfss	PORTD, 1
			goto	$+3
			bcf	PORTD, 1
			return
			bsf	PORTD, 1
			return
;========================================


TABLA_7SEG		brw	
			retlw b'11000000'	; 0
			retlw b'11111001'	; 1
			retlw b'10100100'	; 2
			retlw b'10110000'	; 3
			retlw b'10011001'	; 4
			retlw b'10010010'	; 5
			retlw b'10000010'	; 6
			retlw b'11111000'	; 7
			retlw b'10000000'	; 8
			retlw b'10010000'	; 9

end