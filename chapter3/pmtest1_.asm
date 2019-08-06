;====================
;pmtest1.asm
;编译方法： nasm pmtest1.asm -o pmtest1.bin 
;====================

%include	"pm.inc"	;常量	宏，以及一些说明

org	0100h
	jmp		LABEL_BEGIN

[SECTION .gdt]
;GDT
;								段基址，			段界限	 ，		属性
LABEL_GDT:			Descriptor	0,					   0 ,		0				;空描述符
LABEL_DESC_CODE32:	Descriptor	0,		SegCodeLen32 - 1 ,		DA_C + DA_32	;非一致代码段	
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	      0ffffh ,		DA_DRW			;显存首地址
;GDT 结束

GdtLen				equ		$ - LABEL_GDT	;GDT 长度 
GdtPtr				dw 		GdtLen - 1		;GDT 界限
					dd 		0				;GDT 基地址

;GDT 选择子
SelectorCode32		equ		LABEL_DESC_CODE32	- LABEL_GDT
SelectorVideo		equ		LABEL_DESC_VIDEO	- LABEL_GDT
;END of SECTION GDT

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov		ax,cs
	mov		ds,ax
	mov		es,ax
	mov		ss,ax
	mov		sp,0100h

	;初始化32位代码段描述符
	xor		eax, eax	;将eax值清零
	mov		ax , cs		;将16位的段值从cs 赋值到ax
	shl		eax, 4		;
	add		eax, LABEL_SEG_CODE32
	mov		word [LABEL_DESC_CODE32 + 2], ax
	shr		eax, 16
	mov		byte [LABEL_DESC_CODE32 + 4], al
	mov		byte [LABEL_DESC_CODE32 + 7], ah

	;为加载GDTR准备
	xor		eax, eax					; 清零
	mov		ax , ds
	shl		eax, 4
	add		eax, LABEL_GDT			;eax <- GDT 基地址
	mov		dword [GdtPtr + 2], eax		;[GdtPtr + 2] GDT 基地址

	;加载	GDTR
	lgdt 	[GdtPtr]

	;关中断
	cli	

	;打开地址线 A20
	in 		al , 92h
	or 		al , 00000010b
	out 	92h, al

	;准备切换到保护模式
	mov		eax, cr0
	or 		eax, 1
	mov		cr0, eax

	;进入到保护模式
	jmp 	dword SelectorCode32:0		;把selectorcode32装进cs
										;并跳转到SelectorCode:0处
;END of SECTION .s16


[SECTION .s32];32位代码段 由实模式跳入
[BITS 32]

LABEL_SEG_CODE32:
	mov		ax , SelectorVideo
	mov		gs , ax					;视频段选择子

	mov		edi, (80*11 + 79) * 2	;屏幕第11行,第79列
	mov		ah , 0Ch 				;0000:黑底	1100:红字
	mov		al , 'p'
	mov		[gs:edi] , ax

	;到此为止
	jmp		$

SegCodeLen32		equ $ - LABEL_SEG_CODE32;
;END of [SECTION .s32]