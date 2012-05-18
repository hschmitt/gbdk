#ifndef _HARDWARE_H
#define _HARDWARE_H

#include <types.h>

#define P1_REG		(*(UBYTE *)0xFF00)	/* Joystick: 1.1.P15.P14.P13.P12.P11.P10 */
#define SB_REG		(*(UBYTE *)0xFF01)	/* Serial IO data buffer */
#define SC_REG		(*(UBYTE *)0xFF02)	/* Serial IO control register */
#define DIV_REG		(*(UBYTE *)0xFF04)	/* Divider register */
#define TIMA_REG	(*(UBYTE *)0xFF05)	/* Timer counter */
#define TMA_REG		(*(UBYTE *)0xFF06)	/* Timer modulo */
#define TAC_REG		(*(UBYTE *)0xFF07)	/* Timer control */
#define IF_REG		(*(UBYTE *)0xFF0F)	/* Interrupt flags: 0.0.0.JOY.SIO.TIM.LCD.VBL */
#define NR10_REG	(*(UBYTE *)0xFF10)	/* Sound register */
#define NR11_REG	(*(UBYTE *)0xFF11)	/* Sound register */
#define NR12_REG	(*(UBYTE *)0xFF12)	/* Sound register */
#define NR13_REG	(*(UBYTE *)0xFF13)	/* Sound register */
#define NR14_REG	(*(UBYTE *)0xFF14)	/* Sound register */
#define NR21_REG	(*(UBYTE *)0xFF16)	/* Sound register */
#define NR22_REG	(*(UBYTE *)0xFF17)	/* Sound register */
#define NR23_REG	(*(UBYTE *)0xFF18)	/* Sound register */
#define NR24_REG	(*(UBYTE *)0xFF19)	/* Sound register */
#define NR30_REG	(*(UBYTE *)0xFF1A)	/* Sound register */
#define NR31_REG	(*(UBYTE *)0xFF1B)	/* Sound register */
#define NR32_REG	(*(UBYTE *)0xFF1C)	/* Sound register */
#define NR33_REG	(*(UBYTE *)0xFF1D)	/* Sound register */
#define NR34_REG	(*(UBYTE *)0xFF1E)	/* Sound register */
#define NR41_REG	(*(UBYTE *)0xFF20)	/* Sound register */
#define NR42_REG	(*(UBYTE *)0xFF21)	/* Sound register */
#define NR43_REG	(*(UBYTE *)0xFF22)	/* Sound register */
#define NR44_REG	(*(UBYTE *)0xFF23)	/* Sound register */
#define NR50_REG	(*(UBYTE *)0xFF24)	/* Sound register */
#define NR51_REG	(*(UBYTE *)0xFF25)	/* Sound register */
#define NR52_REG	(*(UBYTE *)0xFF26)	/* Sound register */
#define LCDC_REG	(*(UBYTE *)0xFF40)	/* LCD control */
#define STAT_REG	(*(UBYTE *)0xFF41)	/* LCD status */
#define SCY_REG		(*(UBYTE *)0xFF42)	/* Scroll Y */
#define SCX_REG		(*(UBYTE *)0xFF43)	/* Scroll X */
#define LY_REG		(*(UBYTE *)0xFF44)	/* LCDC Y-coordinate */
#define LYC_REG		(*(UBYTE *)0xFF45)	/* LY compare */
#define DMA_REG		(*(UBYTE *)0xFF46)	/* DMA transfer */
#define BGP_REG		(*(UBYTE *)0xFF47)	/* BG palette data */
#define OBP0_REG	(*(UBYTE *)0xFF48)	/* OBJ palette 0 data */
#define OBP1_REG	(*(UBYTE *)0xFF49)	/* OBJ palette 1 data */
#define WY_REG		(*(UBYTE *)0xFF4A)	/* Window Y coordinate */
#define WX_REG		(*(UBYTE *)0xFF4B)	/* Window X coordinate */
#define KEY1_REG	(*(UBYTE *)0xFF4D)	/* CPU speed */
#define VBK_REG		(*(UBYTE *)0xFF4F)	/* VRAM bank */
#define HDMA1_REG	(*(UBYTE *)0xFF51)	/* DMA control 1 */
#define HDMA2_REG	(*(UBYTE *)0xFF52)	/* DMA control 2 */
#define HDMA3_REG	(*(UBYTE *)0xFF53)	/* DMA control 3 */
#define HDMA4_REG	(*(UBYTE *)0xFF54)	/* DMA control 4 */
#define HDMA5_REG	(*(UBYTE *)0xFF55)	/* DMA control 5 */
#define RP_REG		(*(UBYTE *)0xFF56)	/* IR port */
#define BCPS_REG	(*(UBYTE *)0xFF68)	/* BG color palette specification */
#define BCPD_REG	(*(UBYTE *)0xFF69)	/* BG color palette data */
#define OCPS_REG	(*(UBYTE *)0xFF6A)	/* OBJ color palette specification */
#define OCPD_REG	(*(UBYTE *)0xFF6B)	/* OBJ color palette data */
#define SVBK_REG	(*(UBYTE *)0xFF70)	/* WRAM bank */
#define IE_REG		(*(UBYTE *)0xFFFF)	/* Interrupt enable */

#endif /* _HARDWARE_H */
