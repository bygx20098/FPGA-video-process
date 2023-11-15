
build/gpioDemo.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00001197          	auipc	gp,0x1
    1004:	13018193          	addi	gp,gp,304 # 2130 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00002117          	auipc	sp,0x2
    100c:	94810113          	addi	sp,sp,-1720 # 2950 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00000517          	auipc	a0,0x0
    1014:	7ac50513          	addi	a0,a0,1964 # 17bc <_data>
	la a1, _data
    1018:	00000597          	auipc	a1,0x0
    101c:	7a458593          	addi	a1,a1,1956 # 17bc <_data>
	la a2, _edata
    1020:	81c18613          	addi	a2,gp,-2020 # 194c <__bss_start>
	bgeu a1, a2, 2f
    1024:	00c5fc63          	bgeu	a1,a2,103c <init+0x34>
1:
	lw t0, (a0)
    1028:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    102c:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1030:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    1034:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    1038:	fec5e8e3          	bltu	a1,a2,1028 <init+0x20>
2:

	/* Clear bss section */
	la a0, __bss_start
    103c:	81c18513          	addi	a0,gp,-2020 # 194c <__bss_start>
	la a1, _end
    1040:	82018593          	addi	a1,gp,-2016 # 1950 <_end>
	bgeu a0, a1, 2f
    1044:	00b57863          	bgeu	a0,a1,1054 <init+0x4c>
1:
	sw zero, (a0)
    1048:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    104c:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    1050:	feb56ce3          	bltu	a0,a1,1048 <init+0x40>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
    1054:	010000ef          	jal	ra,1064 <__libc_init_array>
#endif

	call main
    1058:	62c000ef          	jal	ra,1684 <main>

0000105c <mainDone>:
mainDone:
    j mainDone
    105c:	0000006f          	j	105c <mainDone>

00001060 <_init>:


	.globl _init
_init:
    ret
    1060:	00008067          	ret

Disassembly of section .text:

00001064 <__libc_init_array>:
    1064:	ff010113          	addi	sp,sp,-16
    1068:	00812423          	sw	s0,8(sp)
    106c:	01212023          	sw	s2,0(sp)
    1070:	00000417          	auipc	s0,0x0
    1074:	74c40413          	addi	s0,s0,1868 # 17bc <_data>
    1078:	00000917          	auipc	s2,0x0
    107c:	74490913          	addi	s2,s2,1860 # 17bc <_data>
    1080:	40890933          	sub	s2,s2,s0
    1084:	00112623          	sw	ra,12(sp)
    1088:	00912223          	sw	s1,4(sp)
    108c:	40295913          	srai	s2,s2,0x2
    1090:	00090e63          	beqz	s2,10ac <__libc_init_array+0x48>
    1094:	00000493          	li	s1,0
    1098:	00042783          	lw	a5,0(s0)
    109c:	00148493          	addi	s1,s1,1
    10a0:	00440413          	addi	s0,s0,4
    10a4:	000780e7          	jalr	a5
    10a8:	fe9918e3          	bne	s2,s1,1098 <__libc_init_array+0x34>
    10ac:	00000417          	auipc	s0,0x0
    10b0:	71040413          	addi	s0,s0,1808 # 17bc <_data>
    10b4:	00000917          	auipc	s2,0x0
    10b8:	70890913          	addi	s2,s2,1800 # 17bc <_data>
    10bc:	40890933          	sub	s2,s2,s0
    10c0:	40295913          	srai	s2,s2,0x2
    10c4:	00090e63          	beqz	s2,10e0 <__libc_init_array+0x7c>
    10c8:	00000493          	li	s1,0
    10cc:	00042783          	lw	a5,0(s0)
    10d0:	00148493          	addi	s1,s1,1
    10d4:	00440413          	addi	s0,s0,4
    10d8:	000780e7          	jalr	a5
    10dc:	fe9918e3          	bne	s2,s1,10cc <__libc_init_array+0x68>
    10e0:	00c12083          	lw	ra,12(sp)
    10e4:	00812403          	lw	s0,8(sp)
    10e8:	00412483          	lw	s1,4(sp)
    10ec:	00012903          	lw	s2,0(sp)
    10f0:	01010113          	addi	sp,sp,16
    10f4:	00008067          	ret

000010f8 <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    10f8:	00452503          	lw	a0,4(a0)
        enum UartStop stop;
        u32 clockDivider;
    } Uart_Config;
    
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    10fc:	01055513          	srli	a0,a0,0x10
    }
    1100:	0ff57513          	andi	a0,a0,255
    1104:	00008067          	ret

00001108 <uart_write>:
    static u32 uart_readOccupancy(u32 reg){
        return read_u32(reg + UART_STATUS) >> 24;
    }
    
    static void uart_write(u32 reg, char data){
    1108:	ff010113          	addi	sp,sp,-16
    110c:	00112623          	sw	ra,12(sp)
    1110:	00812423          	sw	s0,8(sp)
    1114:	00912223          	sw	s1,4(sp)
    1118:	00050413          	mv	s0,a0
    111c:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1120:	00040513          	mv	a0,s0
    1124:	fd5ff0ef          	jal	ra,10f8 <uart_writeAvailability>
    1128:	fe050ce3          	beqz	a0,1120 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    112c:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1130:	00c12083          	lw	ra,12(sp)
    1134:	00812403          	lw	s0,8(sp)
    1138:	00412483          	lw	s1,4(sp)
    113c:	01010113          	addi	sp,sp,16
    1140:	00008067          	ret

00001144 <clint_uDelay>:
    
        return (((u64)hi) << 32) | lo;
    }
    
    static void clint_uDelay(u32 usec, u32 hz, u32 reg){
        u32 mTimePerUsec = hz/1000000;
    1144:	000f47b7          	lui	a5,0xf4
    1148:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xf18f0>
    114c:	02f5d5b3          	divu	a1,a1,a5
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    1150:	0000c7b7          	lui	a5,0xc
    1154:	ff878793          	addi	a5,a5,-8 # bff8 <__freertos_irq_stack_top+0x96a8>
    1158:	00f60633          	add	a2,a2,a5
        return *((volatile u32*) address);
    115c:	00062783          	lw	a5,0(a2)
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    1160:	02a58533          	mul	a0,a1,a0
    1164:	00f50533          	add	a0,a0,a5
    1168:	00062783          	lw	a5,0(a2)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    116c:	40f507b3          	sub	a5,a0,a5
    1170:	fe07dce3          	bgez	a5,1168 <clint_uDelay+0x24>
    }
    1174:	00008067          	ret

00001178 <bsp_printHex>:
#define ENABLE_BRIDGE_FULL_TO_LITE          1 // If this is enabled, bsp_printf_full can be called with bsp_printf. Enabling both ENABLE_BSP_PRINTF and ENABLE_BSP_PRINTF_FULL, bsp_printf_full will be remained as bsp_printf_full. Default: Enable
#define ENABLE_PRINTF_WARNING               1 // Print warning when the specifier not supported. Default: Enable

    //bsp_printHex is used in BSP_PRINTF
    static void bsp_printHex(uint32_t val)
    {
    1178:	ff010113          	addi	sp,sp,-16
    117c:	00112623          	sw	ra,12(sp)
    1180:	00812423          	sw	s0,8(sp)
    1184:	00912223          	sw	s1,4(sp)
    1188:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    118c:	01c00413          	li	s0,28
    1190:	0280006f          	j	11b8 <bsp_printHex+0x40>
            uart_write(BSP_UART_TERMINAL, "0123456789ABCDEF"[(val >> i) % 16]);
    1194:	0084d7b3          	srl	a5,s1,s0
    1198:	00f7f713          	andi	a4,a5,15
    119c:	000017b7          	lui	a5,0x1
    11a0:	7bc78793          	addi	a5,a5,1980 # 17bc <_data>
    11a4:	00e787b3          	add	a5,a5,a4
    11a8:	0007c583          	lbu	a1,0(a5)
    11ac:	f8010537          	lui	a0,0xf8010
    11b0:	f59ff0ef          	jal	ra,1108 <uart_write>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    11b4:	ffc40413          	addi	s0,s0,-4
    11b8:	fc045ee3          	bgez	s0,1194 <bsp_printHex+0x1c>
        }
    }
    11bc:	00c12083          	lw	ra,12(sp)
    11c0:	00812403          	lw	s0,8(sp)
    11c4:	00412483          	lw	s1,4(sp)
    11c8:	01010113          	addi	sp,sp,16
    11cc:	00008067          	ret

000011d0 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
        {
    11d0:	ff010113          	addi	sp,sp,-16
    11d4:	00112623          	sw	ra,12(sp)
    11d8:	00812423          	sw	s0,8(sp)
    11dc:	00912223          	sw	s1,4(sp)
    11e0:	00050493          	mv	s1,a0
            uint32_t digits;
            digits =8;

            for (int i = (4*digits)-4; i >= 0; i -= 4) {
    11e4:	01c00413          	li	s0,28
    11e8:	0280006f          	j	1210 <bsp_printHex_lower+0x40>
                uart_write(BSP_UART_TERMINAL, "0123456789abcdef"[(val >> i) % 16]);
    11ec:	0084d7b3          	srl	a5,s1,s0
    11f0:	00f7f713          	andi	a4,a5,15
    11f4:	000017b7          	lui	a5,0x1
    11f8:	7d078793          	addi	a5,a5,2000 # 17d0 <_data+0x14>
    11fc:	00e787b3          	add	a5,a5,a4
    1200:	0007c583          	lbu	a1,0(a5)
    1204:	f8010537          	lui	a0,0xf8010
    1208:	f01ff0ef          	jal	ra,1108 <uart_write>
            for (int i = (4*digits)-4; i >= 0; i -= 4) {
    120c:	ffc40413          	addi	s0,s0,-4
    1210:	fc045ee3          	bgez	s0,11ec <bsp_printHex_lower+0x1c>
            }
        }
    1214:	00c12083          	lw	ra,12(sp)
    1218:	00812403          	lw	s0,8(sp)
    121c:	00412483          	lw	s1,4(sp)
    1220:	01010113          	addi	sp,sp,16
    1224:	00008067          	ret

00001228 <bsp_printf_c>:
    }

    #endif //#if (ENABLE_FLOATING_POINT_SUPPORT)

    static void bsp_printf_c(int c)
    {
    1228:	ff010113          	addi	sp,sp,-16
    122c:	00112623          	sw	ra,12(sp)
        bsp_putChar(c);
    1230:	0ff57593          	andi	a1,a0,255
    1234:	f8010537          	lui	a0,0xf8010
    1238:	ed1ff0ef          	jal	ra,1108 <uart_write>
    }
    123c:	00c12083          	lw	ra,12(sp)
    1240:	01010113          	addi	sp,sp,16
    1244:	00008067          	ret

00001248 <bsp_printf_s>:
    
    static void bsp_printf_s(char *p)
    {
    1248:	ff010113          	addi	sp,sp,-16
    124c:	00112623          	sw	ra,12(sp)
    1250:	00812423          	sw	s0,8(sp)
    1254:	00050413          	mv	s0,a0
        while (*p)
    1258:	00044583          	lbu	a1,0(s0)
    125c:	00058a63          	beqz	a1,1270 <bsp_printf_s+0x28>
            bsp_putChar(*(p++));
    1260:	00140413          	addi	s0,s0,1
    1264:	f8010537          	lui	a0,0xf8010
    1268:	ea1ff0ef          	jal	ra,1108 <uart_write>
    126c:	fedff06f          	j	1258 <bsp_printf_s+0x10>
    }
    1270:	00c12083          	lw	ra,12(sp)
    1274:	00812403          	lw	s0,8(sp)
    1278:	01010113          	addi	sp,sp,16
    127c:	00008067          	ret

00001280 <bsp_printf_d>:
    
    static void bsp_printf_d(int val)
    {
    1280:	fd010113          	addi	sp,sp,-48
    1284:	02112623          	sw	ra,44(sp)
    1288:	02812423          	sw	s0,40(sp)
    128c:	02912223          	sw	s1,36(sp)
    1290:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    1294:	00054663          	bltz	a0,12a0 <bsp_printf_d+0x20>
    {
    1298:	00010413          	mv	s0,sp
    129c:	02c0006f          	j	12c8 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    12a0:	02d00513          	li	a0,45
    12a4:	f85ff0ef          	jal	ra,1228 <bsp_printf_c>
            val = -val;
    12a8:	409004b3          	neg	s1,s1
    12ac:	fedff06f          	j	1298 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    12b0:	00a00713          	li	a4,10
    12b4:	02e4e7b3          	rem	a5,s1,a4
    12b8:	03078793          	addi	a5,a5,48
    12bc:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    12c0:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    12c4:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    12c8:	fe0494e3          	bnez	s1,12b0 <bsp_printf_d+0x30>
    12cc:	00010793          	mv	a5,sp
    12d0:	fef400e3          	beq	s0,a5,12b0 <bsp_printf_d+0x30>
    12d4:	0100006f          	j	12e4 <bsp_printf_d+0x64>
        }
        while (p != buffer)
            bsp_printf_c(*(--p));
    12d8:	fff40413          	addi	s0,s0,-1
    12dc:	00044503          	lbu	a0,0(s0)
    12e0:	f49ff0ef          	jal	ra,1228 <bsp_printf_c>
        while (p != buffer)
    12e4:	00010793          	mv	a5,sp
    12e8:	fef418e3          	bne	s0,a5,12d8 <bsp_printf_d+0x58>
    }
    12ec:	02c12083          	lw	ra,44(sp)
    12f0:	02812403          	lw	s0,40(sp)
    12f4:	02412483          	lw	s1,36(sp)
    12f8:	03010113          	addi	sp,sp,48
    12fc:	00008067          	ret

00001300 <bsp_printf_x>:
    
    static void bsp_printf_x(int val)
    {
    1300:	ff010113          	addi	sp,sp,-16
    1304:	00112623          	sw	ra,12(sp)
        int i,digi=2;
    
        for(i=0;i<8;i++)
    1308:	00000713          	li	a4,0
    130c:	00700793          	li	a5,7
    1310:	02e7c063          	blt	a5,a4,1330 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1314:	00271693          	slli	a3,a4,0x2
    1318:	ff000793          	li	a5,-16
    131c:	00d797b3          	sll	a5,a5,a3
    1320:	00f577b3          	and	a5,a0,a5
    1324:	00078663          	beqz	a5,1330 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1328:	00170713          	addi	a4,a4,1
    132c:	fe1ff06f          	j	130c <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    1330:	ea1ff0ef          	jal	ra,11d0 <bsp_printHex_lower>
    }
    1334:	00c12083          	lw	ra,12(sp)
    1338:	01010113          	addi	sp,sp,16
    133c:	00008067          	ret

00001340 <bsp_printf_X>:
    
    static void bsp_printf_X(int val)
        {
    1340:	ff010113          	addi	sp,sp,-16
    1344:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    1348:	00000713          	li	a4,0
    134c:	00700793          	li	a5,7
    1350:	02e7c063          	blt	a5,a4,1370 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1354:	00271693          	slli	a3,a4,0x2
    1358:	ff000793          	li	a5,-16
    135c:	00d797b3          	sll	a5,a5,a3
    1360:	00f577b3          	and	a5,a0,a5
    1364:	00078663          	beqz	a5,1370 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    1368:	00170713          	addi	a4,a4,1
    136c:	fe1ff06f          	j	134c <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    1370:	e09ff0ef          	jal	ra,1178 <bsp_printHex>
        }
    1374:	00c12083          	lw	ra,12(sp)
    1378:	01010113          	addi	sp,sp,16
    137c:	00008067          	ret

00001380 <plic_set_priority>:
#define PLIC_CLAIM_BASE         0x200004
#define PLIC_ENABLE_PER_HART    0x80
#define PLIC_CONTEXT_PER_HART   0x1000

    static void plic_set_priority(u32 plic, u32 gateway, u32 priority){
        write_u32(priority, plic + PLIC_PRIORITY_BASE + gateway*4);
    1380:	00259593          	slli	a1,a1,0x2
    1384:	00a585b3          	add	a1,a1,a0
        *((volatile u32*) address) = data;
    1388:	00c5a023          	sw	a2,0(a1)
    }
    138c:	00008067          	ret

00001390 <plic_set_enable>:
    static u32 plic_get_priority(u32 plic, u32 gateway){
        return read_u32(plic + PLIC_PRIORITY_BASE + gateway*4);
    }
    
    static void plic_set_enable(u32 plic, u32 target,u32 gateway, u32 enable){
        u32 word = plic + PLIC_ENABLE_BASE + target * PLIC_ENABLE_PER_HART + (gateway / 32 * 4);
    1390:	00759593          	slli	a1,a1,0x7
    1394:	00a58533          	add	a0,a1,a0
    1398:	00565593          	srli	a1,a2,0x5
    139c:	00259593          	slli	a1,a1,0x2
    13a0:	00b50533          	add	a0,a0,a1
    13a4:	000025b7          	lui	a1,0x2
    13a8:	00b50533          	add	a0,a0,a1
        u32 mask = 1 << (gateway % 32);
    13ac:	00100793          	li	a5,1
    13b0:	00c797b3          	sll	a5,a5,a2
        if (enable)
    13b4:	00068a63          	beqz	a3,13c8 <plic_set_enable+0x38>
        return *((volatile u32*) address);
    13b8:	00052603          	lw	a2,0(a0) # f8010000 <__freertos_irq_stack_top+0xf800d6b0>
            write_u32(read_u32(word) | mask, word);
    13bc:	00c7e7b3          	or	a5,a5,a2
        *((volatile u32*) address) = data;
    13c0:	00f52023          	sw	a5,0(a0)
    13c4:	00008067          	ret
        return *((volatile u32*) address);
    13c8:	00052603          	lw	a2,0(a0)
        else
            write_u32(read_u32(word) & ~mask, word);
    13cc:	fff7c793          	not	a5,a5
    13d0:	00c7f7b3          	and	a5,a5,a2
        *((volatile u32*) address) = data;
    13d4:	00f52023          	sw	a5,0(a0)
    }
    13d8:	00008067          	ret

000013dc <plic_set_threshold>:
    
    static void plic_set_threshold(u32 plic, u32 target, u32 threshold){
        write_u32(threshold, plic + PLIC_THRESHOLD_BASE + target*PLIC_CONTEXT_PER_HART);
    13dc:	00c59593          	slli	a1,a1,0xc
    13e0:	00a585b3          	add	a1,a1,a0
    13e4:	00200537          	lui	a0,0x200
    13e8:	00a585b3          	add	a1,a1,a0
    13ec:	00c5a023          	sw	a2,0(a1) # 2000 <_end+0x6b0>
    }
    13f0:	00008067          	ret

000013f4 <plic_claim>:
    static u32 plic_get_threshold(u32 plic, u32 target){
        return read_u32(plic + PLIC_THRESHOLD_BASE + target*PLIC_CONTEXT_PER_HART);
    }
    
    static u32 plic_claim(u32 plic, u32 target){
        return read_u32(plic + PLIC_CLAIM_BASE + target*PLIC_CONTEXT_PER_HART);
    13f4:	00c59593          	slli	a1,a1,0xc
    13f8:	00a585b3          	add	a1,a1,a0
    13fc:	00200537          	lui	a0,0x200
    1400:	00450513          	addi	a0,a0,4 # 200004 <__freertos_irq_stack_top+0x1fd6b4>
    1404:	00a585b3          	add	a1,a1,a0
        return *((volatile u32*) address);
    1408:	0005a503          	lw	a0,0(a1)
    }
    140c:	00008067          	ret

00001410 <plic_release>:
    
    static void plic_release(u32 plic, u32 target, u32 gateway){
        write_u32(gateway,plic + PLIC_CLAIM_BASE + target*PLIC_CONTEXT_PER_HART);
    1410:	00c59593          	slli	a1,a1,0xc
    1414:	00a585b3          	add	a1,a1,a0
    1418:	00200537          	lui	a0,0x200
    141c:	00450513          	addi	a0,a0,4 # 200004 <__freertos_irq_stack_top+0x1fd6b4>
    1420:	00a585b3          	add	a1,a1,a0
        *((volatile u32*) address) = data;
    1424:	00c5a023          	sw	a2,0(a1)
    }
    1428:	00008067          	ret

0000142c <bsp_printf>:

    static void bsp_printf(const char *format, ...)
    {
    142c:	fc010113          	addi	sp,sp,-64
    1430:	00112e23          	sw	ra,28(sp)
    1434:	00812c23          	sw	s0,24(sp)
    1438:	00912a23          	sw	s1,20(sp)
    143c:	00050493          	mv	s1,a0
    1440:	02b12223          	sw	a1,36(sp)
    1444:	02c12423          	sw	a2,40(sp)
    1448:	02d12623          	sw	a3,44(sp)
    144c:	02e12823          	sw	a4,48(sp)
    1450:	02f12a23          	sw	a5,52(sp)
    1454:	03012c23          	sw	a6,56(sp)
    1458:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;
    
        va_start(ap, format);
    145c:	02410793          	addi	a5,sp,36
    1460:	00f12623          	sw	a5,12(sp)
    
        for (i = 0; format[i]; i++)
    1464:	00000413          	li	s0,0
    1468:	01c0006f          	j	1484 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    146c:	00c12783          	lw	a5,12(sp)
    1470:	00478713          	addi	a4,a5,4
    1474:	00e12623          	sw	a4,12(sp)
    1478:	0007a503          	lw	a0,0(a5)
    147c:	dadff0ef          	jal	ra,1228 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    1480:	00140413          	addi	s0,s0,1
    1484:	008487b3          	add	a5,s1,s0
    1488:	0007c503          	lbu	a0,0(a5)
    148c:	0c050263          	beqz	a0,1550 <bsp_printf+0x124>
            if (format[i] == '%') {
    1490:	02500793          	li	a5,37
    1494:	06f50663          	beq	a0,a5,1500 <bsp_printf+0xd4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    1498:	d91ff0ef          	jal	ra,1228 <bsp_printf_c>
    149c:	fe5ff06f          	j	1480 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    14a0:	00c12783          	lw	a5,12(sp)
    14a4:	00478713          	addi	a4,a5,4
    14a8:	00e12623          	sw	a4,12(sp)
    14ac:	0007a503          	lw	a0,0(a5)
    14b0:	d99ff0ef          	jal	ra,1248 <bsp_printf_s>
                        break;
    14b4:	fcdff06f          	j	1480 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    14b8:	00c12783          	lw	a5,12(sp)
    14bc:	00478713          	addi	a4,a5,4
    14c0:	00e12623          	sw	a4,12(sp)
    14c4:	0007a503          	lw	a0,0(a5)
    14c8:	db9ff0ef          	jal	ra,1280 <bsp_printf_d>
                        break;
    14cc:	fb5ff06f          	j	1480 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    14d0:	00c12783          	lw	a5,12(sp)
    14d4:	00478713          	addi	a4,a5,4
    14d8:	00e12623          	sw	a4,12(sp)
    14dc:	0007a503          	lw	a0,0(a5)
    14e0:	e61ff0ef          	jal	ra,1340 <bsp_printf_X>
                        break;
    14e4:	f9dff06f          	j	1480 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    14e8:	00c12783          	lw	a5,12(sp)
    14ec:	00478713          	addi	a4,a5,4
    14f0:	00e12623          	sw	a4,12(sp)
    14f4:	0007a503          	lw	a0,0(a5)
    14f8:	e09ff0ef          	jal	ra,1300 <bsp_printf_x>
                        break;
    14fc:	f85ff06f          	j	1480 <bsp_printf+0x54>
                while (format[++i]) {
    1500:	00140413          	addi	s0,s0,1
    1504:	008487b3          	add	a5,s1,s0
    1508:	0007c783          	lbu	a5,0(a5)
    150c:	f6078ae3          	beqz	a5,1480 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    1510:	06300713          	li	a4,99
    1514:	f4e78ce3          	beq	a5,a4,146c <bsp_printf+0x40>
                    else if (format[i] == 's') {
    1518:	07300713          	li	a4,115
    151c:	f8e782e3          	beq	a5,a4,14a0 <bsp_printf+0x74>
                    else if (format[i] == 'd') {
    1520:	06400713          	li	a4,100
    1524:	f8e78ae3          	beq	a5,a4,14b8 <bsp_printf+0x8c>
                    else if (format[i] == 'X') {
    1528:	05800713          	li	a4,88
    152c:	fae782e3          	beq	a5,a4,14d0 <bsp_printf+0xa4>
                    else if (format[i] == 'x') {
    1530:	07800713          	li	a4,120
    1534:	fae78ae3          	beq	a5,a4,14e8 <bsp_printf+0xbc>
                    else if (format[i] == 'f') {
    1538:	06600713          	li	a4,102
    153c:	fce792e3          	bne	a5,a4,1500 <bsp_printf+0xd4>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    1540:	00001537          	lui	a0,0x1
    1544:	7e450513          	addi	a0,a0,2020 # 17e4 <_data+0x28>
    1548:	d01ff0ef          	jal	ra,1248 <bsp_printf_s>
                        break;
    154c:	f35ff06f          	j	1480 <bsp_printf+0x54>
    
        va_end(ap);
    }
    1550:	01c12083          	lw	ra,28(sp)
    1554:	01812403          	lw	s0,24(sp)
    1558:	01412483          	lw	s1,20(sp)
    155c:	04010113          	addi	sp,sp,64
    1560:	00008067          	ret

00001564 <init>:
void trap();
void crash();
void trap_entry();
void externalInterrupt();

void init(){
    1564:	ff010113          	addi	sp,sp,-16
    1568:	00112623          	sw	ra,12(sp)
    //configure PLIC
    //cpu 0 accept all interrupts with priority above 0
    plic_set_threshold(BSP_PLIC, BSP_PLIC_CPU_0, 0); 
    156c:	00000613          	li	a2,0
    1570:	00000593          	li	a1,0
    1574:	f8c00537          	lui	a0,0xf8c00
    1578:	e65ff0ef          	jal	ra,13dc <plic_set_threshold>
    plic_set_enable(BSP_PLIC, BSP_PLIC_CPU_0, SYSTEM_PLIC_SYSTEM_GPIO_0_IO_INTERRUPTS_0, 1);
    157c:	00100693          	li	a3,1
    1580:	00c00613          	li	a2,12
    1584:	00000593          	li	a1,0
    1588:	f8c00537          	lui	a0,0xf8c00
    158c:	e05ff0ef          	jal	ra,1390 <plic_set_enable>
    plic_set_priority(BSP_PLIC, SYSTEM_PLIC_SYSTEM_GPIO_0_IO_INTERRUPTS_0, 1);
    1590:	00100613          	li	a2,1
    1594:	00c00593          	li	a1,12
    1598:	f8c00537          	lui	a0,0xf8c00
    159c:	de5ff0ef          	jal	ra,1380 <plic_set_priority>
    15a0:	f80157b7          	lui	a5,0xf8015
    15a4:	00100713          	li	a4,1
    15a8:	02e7a023          	sw	a4,32(a5) # f8015020 <__freertos_irq_stack_top+0xf80126d0>
    //Enable rising edge interrupts
    gpio_setInterruptRiseEnable(GPIO0, 1); 
    //enable interrupts
    //Set the machine trap vector (../common/trap.S)
    csr_write(mtvec, trap_entry); 
    15ac:	000017b7          	lui	a5,0x1
    15b0:	72c78793          	addi	a5,a5,1836 # 172c <trap_entry>
    15b4:	30579073          	csrw	mtvec,a5
    //Enable external interrupts
    csr_set(mie, MIE_MEIE); 
    15b8:	000017b7          	lui	a5,0x1
    15bc:	80078793          	addi	a5,a5,-2048 # 800 <regnum_t6+0x7e1>
    15c0:	3047a073          	csrs	mie,a5
    csr_write(mstatus, MSTATUS_MPP | MSTATUS_MIE);
    15c4:	000027b7          	lui	a5,0x2
    15c8:	80878793          	addi	a5,a5,-2040 # 1808 <_data+0x4c>
    15cc:	30079073          	csrw	mstatus,a5
}
    15d0:	00c12083          	lw	ra,12(sp)
    15d4:	01010113          	addi	sp,sp,16
    15d8:	00008067          	ret

000015dc <crash>:
        plic_release(BSP_PLIC, BSP_PLIC_CPU_0, claim); 
    }
}

//Used on unexpected trap/interrupt codes
void crash(){
    15dc:	ff010113          	addi	sp,sp,-16
    15e0:	00112623          	sw	ra,12(sp)
    bsp_printf("\r\n*** CRASH ***\r\n");
    15e4:	00002537          	lui	a0,0x2
    15e8:	83050513          	addi	a0,a0,-2000 # 1830 <_data+0x74>
    15ec:	e41ff0ef          	jal	ra,142c <bsp_printf>
    while(1);
    15f0:	0000006f          	j	15f0 <crash+0x14>

000015f4 <externalInterrupt>:
void externalInterrupt(){
    15f4:	ff010113          	addi	sp,sp,-16
    15f8:	00112623          	sw	ra,12(sp)
    15fc:	00812423          	sw	s0,8(sp)
    while(claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0)){
    1600:	00000593          	li	a1,0
    1604:	f8c00537          	lui	a0,0xf8c00
    1608:	dedff0ef          	jal	ra,13f4 <plic_claim>
    160c:	00050413          	mv	s0,a0
    1610:	02050863          	beqz	a0,1640 <externalInterrupt+0x4c>
        switch(claim){
    1614:	00c00793          	li	a5,12
    1618:	02f41263          	bne	s0,a5,163c <externalInterrupt+0x48>
        case SYSTEM_PLIC_SYSTEM_GPIO_0_IO_INTERRUPTS_0: bsp_printf("gpio 0 interrupt routine \r\n"); break;
    161c:	00002537          	lui	a0,0x2
    1620:	84450513          	addi	a0,a0,-1980 # 1844 <_data+0x88>
    1624:	e09ff0ef          	jal	ra,142c <bsp_printf>
        plic_release(BSP_PLIC, BSP_PLIC_CPU_0, claim); 
    1628:	00040613          	mv	a2,s0
    162c:	00000593          	li	a1,0
    1630:	f8c00537          	lui	a0,0xf8c00
    1634:	dddff0ef          	jal	ra,1410 <plic_release>
    1638:	fc9ff06f          	j	1600 <externalInterrupt+0xc>
        default: crash(); break;
    163c:	fa1ff0ef          	jal	ra,15dc <crash>
}
    1640:	00c12083          	lw	ra,12(sp)
    1644:	00812403          	lw	s0,8(sp)
    1648:	01010113          	addi	sp,sp,16
    164c:	00008067          	ret

00001650 <trap>:
void trap(){
    1650:	ff010113          	addi	sp,sp,-16
    1654:	00112623          	sw	ra,12(sp)
    int32_t mcause = csr_read(mcause);
    1658:	342027f3          	csrr	a5,mcause
    if(interrupt){
    165c:	0207d263          	bgez	a5,1680 <trap+0x30>
    1660:	00f7f713          	andi	a4,a5,15
        switch(cause){
    1664:	00b00793          	li	a5,11
    1668:	00f71a63          	bne	a4,a5,167c <trap+0x2c>
        case CAUSE_MACHINE_EXTERNAL: externalInterrupt(); break;
    166c:	f89ff0ef          	jal	ra,15f4 <externalInterrupt>
}
    1670:	00c12083          	lw	ra,12(sp)
    1674:	01010113          	addi	sp,sp,16
    1678:	00008067          	ret
        default: crash(); break;
    167c:	f61ff0ef          	jal	ra,15dc <crash>
        crash();
    1680:	f5dff0ef          	jal	ra,15dc <crash>

00001684 <main>:
}

void main() {
    1684:	ff010113          	addi	sp,sp,-16
    1688:	00112623          	sw	ra,12(sp)
    168c:	00812423          	sw	s0,8(sp)
    bsp_init();
    bsp_printf("gpio 0 demo ! \r\n");
    1690:	00002537          	lui	a0,0x2
    1694:	86050513          	addi	a0,a0,-1952 # 1860 <_data+0xa4>
    1698:	d95ff0ef          	jal	ra,142c <bsp_printf>
    bsp_printf("onboard LEDs blinking \r\n");
    169c:	00002537          	lui	a0,0x2
    16a0:	87450513          	addi	a0,a0,-1932 # 1874 <_data+0xb8>
    16a4:	d89ff0ef          	jal	ra,142c <bsp_printf>
    16a8:	f80157b7          	lui	a5,0xf8015
    16ac:	00e00713          	li	a4,14
    16b0:	00e7a423          	sw	a4,8(a5) # f8015008 <__freertos_irq_stack_top+0xf80126b8>
    16b4:	0007a223          	sw	zero,4(a5)
    //configure 4 bits gpio 0
    gpio_setOutputEnable(GPIO0, 0xe);
    gpio_setOutput(GPIO0, 0x0);
    for (int i=0; i<200; i=i+1) {
    16b8:	00000413          	li	s0,0
    16bc:	0300006f          	j	16ec <main+0x68>
        return *((volatile u32*) address);
    16c0:	f8015737          	lui	a4,0xf8015
    16c4:	00472783          	lw	a5,4(a4) # f8015004 <__freertos_irq_stack_top+0xf80126b4>
        gpio_setOutput(GPIO0, gpio_getOutput(GPIO0) ^ 0xe);
    16c8:	00e7c793          	xori	a5,a5,14
        *((volatile u32*) address) = data;
    16cc:	00f72223          	sw	a5,4(a4)
        bsp_uDelay(LOOP_UDELAY);
    16d0:	f8b00637          	lui	a2,0xf8b00
    16d4:	05f5e5b7          	lui	a1,0x5f5e
    16d8:	10058593          	addi	a1,a1,256 # 5f5e100 <__freertos_irq_stack_top+0x5f5b7b0>
    16dc:	00018537          	lui	a0,0x18
    16e0:	6a050513          	addi	a0,a0,1696 # 186a0 <__freertos_irq_stack_top+0x15d50>
    16e4:	a61ff0ef          	jal	ra,1144 <clint_uDelay>
    for (int i=0; i<200; i=i+1) {
    16e8:	00140413          	addi	s0,s0,1
    16ec:	0c700793          	li	a5,199
    16f0:	fc87d8e3          	bge	a5,s0,16c0 <main+0x3c>
    }   
    bsp_printf("gpio 0 interrupt demo ! \r\n");
    16f4:	00002537          	lui	a0,0x2
    16f8:	89050513          	addi	a0,a0,-1904 # 1890 <_data+0xd4>
    16fc:	d31ff0ef          	jal	ra,142c <bsp_printf>
    bsp_printf("Ti180 press and release onboard button sw4 \r\n");
    1700:	00002537          	lui	a0,0x2
    1704:	8ac50513          	addi	a0,a0,-1876 # 18ac <_data+0xf0>
    1708:	d25ff0ef          	jal	ra,142c <bsp_printf>
    bsp_printf("Ti60 press and release onboard button sw6 \r\n");
    170c:	00002537          	lui	a0,0x2
    1710:	8dc50513          	addi	a0,a0,-1828 # 18dc <_data+0x120>
    1714:	d19ff0ef          	jal	ra,142c <bsp_printf>
    bsp_printf("T120 press and release onboard button sw7 \r\n");
    1718:	00002537          	lui	a0,0x2
    171c:	90c50513          	addi	a0,a0,-1780 # 190c <_data+0x150>
    1720:	d0dff0ef          	jal	ra,142c <bsp_printf>
    init();
    1724:	e41ff0ef          	jal	ra,1564 <init>
    while(1); 
    1728:	0000006f          	j	1728 <main+0xa4>

0000172c <trap_entry>:
.global  trap_entry
.align(2) //mtvec require 32 bits allignement
trap_entry:
  addi sp,sp, -16*4
    172c:	fc010113          	addi	sp,sp,-64
  sw x1,   0*4(sp)
    1730:	00112023          	sw	ra,0(sp)
  sw x5,   1*4(sp)
    1734:	00512223          	sw	t0,4(sp)
  sw x6,   2*4(sp)
    1738:	00612423          	sw	t1,8(sp)
  sw x7,   3*4(sp)
    173c:	00712623          	sw	t2,12(sp)
  sw x10,  4*4(sp)
    1740:	00a12823          	sw	a0,16(sp)
  sw x11,  5*4(sp)
    1744:	00b12a23          	sw	a1,20(sp)
  sw x12,  6*4(sp)
    1748:	00c12c23          	sw	a2,24(sp)
  sw x13,  7*4(sp)
    174c:	00d12e23          	sw	a3,28(sp)
  sw x14,  8*4(sp)
    1750:	02e12023          	sw	a4,32(sp)
  sw x15,  9*4(sp)
    1754:	02f12223          	sw	a5,36(sp)
  sw x16, 10*4(sp)
    1758:	03012423          	sw	a6,40(sp)
  sw x17, 11*4(sp)
    175c:	03112623          	sw	a7,44(sp)
  sw x28, 12*4(sp)
    1760:	03c12823          	sw	t3,48(sp)
  sw x29, 13*4(sp)
    1764:	03d12a23          	sw	t4,52(sp)
  sw x30, 14*4(sp)
    1768:	03e12c23          	sw	t5,56(sp)
  sw x31, 15*4(sp)
    176c:	03f12e23          	sw	t6,60(sp)
  call trap
    1770:	ee1ff0ef          	jal	ra,1650 <trap>
  lw x1 ,  0*4(sp)
    1774:	00012083          	lw	ra,0(sp)
  lw x5,   1*4(sp)
    1778:	00412283          	lw	t0,4(sp)
  lw x6,   2*4(sp)
    177c:	00812303          	lw	t1,8(sp)
  lw x7,   3*4(sp)
    1780:	00c12383          	lw	t2,12(sp)
  lw x10,  4*4(sp)
    1784:	01012503          	lw	a0,16(sp)
  lw x11,  5*4(sp)
    1788:	01412583          	lw	a1,20(sp)
  lw x12,  6*4(sp)
    178c:	01812603          	lw	a2,24(sp)
  lw x13,  7*4(sp)
    1790:	01c12683          	lw	a3,28(sp)
  lw x14,  8*4(sp)
    1794:	02012703          	lw	a4,32(sp)
  lw x15,  9*4(sp)
    1798:	02412783          	lw	a5,36(sp)
  lw x16, 10*4(sp)
    179c:	02812803          	lw	a6,40(sp)
  lw x17, 11*4(sp)
    17a0:	02c12883          	lw	a7,44(sp)
  lw x28, 12*4(sp)
    17a4:	03012e03          	lw	t3,48(sp)
  lw x29, 13*4(sp)
    17a8:	03412e83          	lw	t4,52(sp)
  lw x30, 14*4(sp)
    17ac:	03812f03          	lw	t5,56(sp)
  lw x31, 15*4(sp)
    17b0:	03c12f83          	lw	t6,60(sp)
  addi sp,sp, 16*4
    17b4:	04010113          	addi	sp,sp,64
  mret
    17b8:	30200073          	mret
