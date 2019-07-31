;==================================
;pmtest1.asm
;compliation method: nasm pmtest1.asm -o pmtest1.bin
;==================================

%include "pm.inc";

org 07c00h
	jmp LABEL_BEGIN

[SECTION .gdt]
;GDT
;段基址,     段界限       , 属性  
LABEL_GDT:		Descriptor	0,	0,	0	  	  ;empty descriptor
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len - 1,DA_C + DA_32;非一致代码段 	
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0ffffh,DA_DRW	  ;显存首地址

GdtLen	equ	$ - LABEL_GDT	;GDT length
GdtPtr	dw	GdtLen - 1	;GDT limit
	dd	0		;GDT basic addr

;GDT selection
SelectorCode32	equ	LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo	equ	LABEL_DESC_VIDEO  - LABEL_GDT
;END of [section .gdt]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,0100h
	
	;init 32 code segement descriptor
	xor eax,eax
	mov ax,cs
	shl eax,4
	add eax,LABEL_SEG_CODE32
	mov word[LABEL_DESC_CODE32 + 2],ax
	shr eax,16
	mov byte[LABEL_DESC_CODE32 + 4],al
	mov byte[LABEL_DESC_CODE32 + 7],ah
	
	;For preparing load GDTR
	xor eax,eax
	mov ax,ds
	shl eax,4
	add eax,LABEL_GDT; eax <- gdt basic addr
	mov dword[GdtPtr + 2],eax;[GdtPtr + 2] <- gdt basic addr
	
	;load GDTR
	lgdt	[GdtPtr]

	;关中断 
	cli

	;open address line A20
	in	al,92h
	or	al,00000010b
	out	92h,al

	;prepare to switch on protect mode
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	;get into real protect mode
	jmp	dword SelectorCode32:0	;put SelectorCode32 in cs
	;and jump to code32Selector32:0 
	;END of [Section .s16]


[SECTION .s32];32 位代码段. 由实模式跳入
[BITS 32]

LABEL_SEG_CODE32:
	mov ax,SelectorVideo
	mov gs,ax

	mov edi,(80*11 +  79)*2;screen row 11(hang),span 79(lie)
	mov ah,0Ch	;0000:black background ,1100: red word
	mov al,'P'
	mov [gs:edi],ax;
	
	;stop
	jmp $

SegCode32Len	equ	$ - LABEL_SEG_CODE32
;END of [SECTION .s32]











