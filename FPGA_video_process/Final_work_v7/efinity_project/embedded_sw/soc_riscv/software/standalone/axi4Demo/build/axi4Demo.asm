
build/axi4Demo.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00001197          	auipc	gp,0x1
    1004:	f0018193          	addi	gp,gp,-256 # 1f00 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00001117          	auipc	sp,0x1
    100c:	71810113          	addi	sp,sp,1816 # 2720 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00000517          	auipc	a0,0x0
    1014:	62c50513          	addi	a0,a0,1580 # 163c <_data>
	la a1, _data
    1018:	00000597          	auipc	a1,0x0
    101c:	62458593          	addi	a1,a1,1572 # 163c <_data>
	la a2, _edata
    1020:	81c18613          	addi	a2,gp,-2020 # 171c <__bss_start>
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
    103c:	81c18513          	addi	a0,gp,-2020 # 171c <__bss_start>
	la a1, _end
    1040:	82018593          	addi	a1,gp,-2016 # 1720 <_end>
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
    1058:	534000ef          	jal	ra,158c <main>

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
    1074:	5cc40413          	addi	s0,s0,1484 # 163c <_data>
    1078:	00000917          	auipc	s2,0x0
    107c:	5c490913          	addi	s2,s2,1476 # 163c <_data>
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
    10b0:	59040413          	addi	s0,s0,1424 # 163c <_data>
    10b4:	00000917          	auipc	s2,0x0
    10b8:	58890913          	addi	s2,s2,1416 # 163c <_data>
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

00001144 <bsp_printHex>:
#define ENABLE_BRIDGE_FULL_TO_LITE          1 // If this is enabled, bsp_printf_full can be called with bsp_printf. Enabling both ENABLE_BSP_PRINTF and ENABLE_BSP_PRINTF_FULL, bsp_printf_full will be remained as bsp_printf_full. Default: Enable
#define ENABLE_PRINTF_WARNING               1 // Print warning when the specifier not supported. Default: Enable

    //bsp_printHex is used in BSP_PRINTF
    static void bsp_printHex(uint32_t val)
    {
    1144:	ff010113          	addi	sp,sp,-16
    1148:	00112623          	sw	ra,12(sp)
    114c:	00812423          	sw	s0,8(sp)
    1150:	00912223          	sw	s1,4(sp)
    1154:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1158:	01c00413          	li	s0,28
    115c:	0280006f          	j	1184 <bsp_printHex+0x40>
            uart_write(BSP_UART_TERMINAL, "0123456789ABCDEF"[(val >> i) % 16]);
    1160:	0084d7b3          	srl	a5,s1,s0
    1164:	00f7f713          	andi	a4,a5,15
    1168:	000017b7          	lui	a5,0x1
    116c:	63c78793          	addi	a5,a5,1596 # 163c <_data>
    1170:	00e787b3          	add	a5,a5,a4
    1174:	0007c583          	lbu	a1,0(a5)
    1178:	f8010537          	lui	a0,0xf8010
    117c:	f8dff0ef          	jal	ra,1108 <uart_write>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1180:	ffc40413          	addi	s0,s0,-4
    1184:	fc045ee3          	bgez	s0,1160 <bsp_printHex+0x1c>
        }
    }
    1188:	00c12083          	lw	ra,12(sp)
    118c:	00812403          	lw	s0,8(sp)
    1190:	00412483          	lw	s1,4(sp)
    1194:	01010113          	addi	sp,sp,16
    1198:	00008067          	ret

0000119c <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
        {
    119c:	ff010113          	addi	sp,sp,-16
    11a0:	00112623          	sw	ra,12(sp)
    11a4:	00812423          	sw	s0,8(sp)
    11a8:	00912223          	sw	s1,4(sp)
    11ac:	00050493          	mv	s1,a0
            uint32_t digits;
            digits =8;

            for (int i = (4*digits)-4; i >= 0; i -= 4) {
    11b0:	01c00413          	li	s0,28
    11b4:	0280006f          	j	11dc <bsp_printHex_lower+0x40>
                uart_write(BSP_UART_TERMINAL, "0123456789abcdef"[(val >> i) % 16]);
    11b8:	0084d7b3          	srl	a5,s1,s0
    11bc:	00f7f713          	andi	a4,a5,15
    11c0:	000017b7          	lui	a5,0x1
    11c4:	65078793          	addi	a5,a5,1616 # 1650 <_data+0x14>
    11c8:	00e787b3          	add	a5,a5,a4
    11cc:	0007c583          	lbu	a1,0(a5)
    11d0:	f8010537          	lui	a0,0xf8010
    11d4:	f35ff0ef          	jal	ra,1108 <uart_write>
            for (int i = (4*digits)-4; i >= 0; i -= 4) {
    11d8:	ffc40413          	addi	s0,s0,-4
    11dc:	fc045ee3          	bgez	s0,11b8 <bsp_printHex_lower+0x1c>
            }
        }
    11e0:	00c12083          	lw	ra,12(sp)
    11e4:	00812403          	lw	s0,8(sp)
    11e8:	00412483          	lw	s1,4(sp)
    11ec:	01010113          	addi	sp,sp,16
    11f0:	00008067          	ret

000011f4 <bsp_printf_c>:
    }

    #endif //#if (ENABLE_FLOATING_POINT_SUPPORT)

    static void bsp_printf_c(int c)
    {
    11f4:	ff010113          	addi	sp,sp,-16
    11f8:	00112623          	sw	ra,12(sp)
        bsp_putChar(c);
    11fc:	0ff57593          	andi	a1,a0,255
    1200:	f8010537          	lui	a0,0xf8010
    1204:	f05ff0ef          	jal	ra,1108 <uart_write>
    }
    1208:	00c12083          	lw	ra,12(sp)
    120c:	01010113          	addi	sp,sp,16
    1210:	00008067          	ret

00001214 <bsp_printf_s>:
    
    static void bsp_printf_s(char *p)
    {
    1214:	ff010113          	addi	sp,sp,-16
    1218:	00112623          	sw	ra,12(sp)
    121c:	00812423          	sw	s0,8(sp)
    1220:	00050413          	mv	s0,a0
        while (*p)
    1224:	00044583          	lbu	a1,0(s0)
    1228:	00058a63          	beqz	a1,123c <bsp_printf_s+0x28>
            bsp_putChar(*(p++));
    122c:	00140413          	addi	s0,s0,1
    1230:	f8010537          	lui	a0,0xf8010
    1234:	ed5ff0ef          	jal	ra,1108 <uart_write>
    1238:	fedff06f          	j	1224 <bsp_printf_s+0x10>
    }
    123c:	00c12083          	lw	ra,12(sp)
    1240:	00812403          	lw	s0,8(sp)
    1244:	01010113          	addi	sp,sp,16
    1248:	00008067          	ret

0000124c <bsp_printf_d>:
    
    static void bsp_printf_d(int val)
    {
    124c:	fd010113          	addi	sp,sp,-48
    1250:	02112623          	sw	ra,44(sp)
    1254:	02812423          	sw	s0,40(sp)
    1258:	02912223          	sw	s1,36(sp)
    125c:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    1260:	00054663          	bltz	a0,126c <bsp_printf_d+0x20>
    {
    1264:	00010413          	mv	s0,sp
    1268:	02c0006f          	j	1294 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    126c:	02d00513          	li	a0,45
    1270:	f85ff0ef          	jal	ra,11f4 <bsp_printf_c>
            val = -val;
    1274:	409004b3          	neg	s1,s1
    1278:	fedff06f          	j	1264 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    127c:	00a00713          	li	a4,10
    1280:	02e4e7b3          	rem	a5,s1,a4
    1284:	03078793          	addi	a5,a5,48
    1288:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    128c:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    1290:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    1294:	fe0494e3          	bnez	s1,127c <bsp_printf_d+0x30>
    1298:	00010793          	mv	a5,sp
    129c:	fef400e3          	beq	s0,a5,127c <bsp_printf_d+0x30>
    12a0:	0100006f          	j	12b0 <bsp_printf_d+0x64>
        }
        while (p != buffer)
            bsp_printf_c(*(--p));
    12a4:	fff40413          	addi	s0,s0,-1
    12a8:	00044503          	lbu	a0,0(s0)
    12ac:	f49ff0ef          	jal	ra,11f4 <bsp_printf_c>
        while (p != buffer)
    12b0:	00010793          	mv	a5,sp
    12b4:	fef418e3          	bne	s0,a5,12a4 <bsp_printf_d+0x58>
    }
    12b8:	02c12083          	lw	ra,44(sp)
    12bc:	02812403          	lw	s0,40(sp)
    12c0:	02412483          	lw	s1,36(sp)
    12c4:	03010113          	addi	sp,sp,48
    12c8:	00008067          	ret

000012cc <bsp_printf_x>:
    
    static void bsp_printf_x(int val)
    {
    12cc:	ff010113          	addi	sp,sp,-16
    12d0:	00112623          	sw	ra,12(sp)
        int i,digi=2;
    
        for(i=0;i<8;i++)
    12d4:	00000713          	li	a4,0
    12d8:	00700793          	li	a5,7
    12dc:	02e7c063          	blt	a5,a4,12fc <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    12e0:	00271693          	slli	a3,a4,0x2
    12e4:	ff000793          	li	a5,-16
    12e8:	00d797b3          	sll	a5,a5,a3
    12ec:	00f577b3          	and	a5,a0,a5
    12f0:	00078663          	beqz	a5,12fc <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    12f4:	00170713          	addi	a4,a4,1
    12f8:	fe1ff06f          	j	12d8 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    12fc:	ea1ff0ef          	jal	ra,119c <bsp_printHex_lower>
    }
    1300:	00c12083          	lw	ra,12(sp)
    1304:	01010113          	addi	sp,sp,16
    1308:	00008067          	ret

0000130c <bsp_printf_X>:
    
    static void bsp_printf_X(int val)
        {
    130c:	ff010113          	addi	sp,sp,-16
    1310:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    1314:	00000713          	li	a4,0
    1318:	00700793          	li	a5,7
    131c:	02e7c063          	blt	a5,a4,133c <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1320:	00271693          	slli	a3,a4,0x2
    1324:	ff000793          	li	a5,-16
    1328:	00d797b3          	sll	a5,a5,a3
    132c:	00f577b3          	and	a5,a0,a5
    1330:	00078663          	beqz	a5,133c <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    1334:	00170713          	addi	a4,a4,1
    1338:	fe1ff06f          	j	1318 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    133c:	e09ff0ef          	jal	ra,1144 <bsp_printHex>
        }
    1340:	00c12083          	lw	ra,12(sp)
    1344:	01010113          	addi	sp,sp,16
    1348:	00008067          	ret

0000134c <plic_set_threshold>:
        else
            write_u32(read_u32(word) & ~mask, word);
    }
    
    static void plic_set_threshold(u32 plic, u32 target, u32 threshold){
        write_u32(threshold, plic + PLIC_THRESHOLD_BASE + target*PLIC_CONTEXT_PER_HART);
    134c:	00c59593          	slli	a1,a1,0xc
    1350:	00a585b3          	add	a1,a1,a0
    1354:	00200537          	lui	a0,0x200
    1358:	00a585b3          	add	a1,a1,a0
    135c:	00c5a023          	sw	a2,0(a1)
    }
    1360:	00008067          	ret

00001364 <plic_claim>:
    static u32 plic_get_threshold(u32 plic, u32 target){
        return read_u32(plic + PLIC_THRESHOLD_BASE + target*PLIC_CONTEXT_PER_HART);
    }
    
    static u32 plic_claim(u32 plic, u32 target){
        return read_u32(plic + PLIC_CLAIM_BASE + target*PLIC_CONTEXT_PER_HART);
    1364:	00c59593          	slli	a1,a1,0xc
    1368:	00a585b3          	add	a1,a1,a0
    136c:	00200537          	lui	a0,0x200
    1370:	00450513          	addi	a0,a0,4 # 200004 <__freertos_irq_stack_top+0x1fd8e4>
    1374:	00a585b3          	add	a1,a1,a0
        return *((volatile u32*) address);
    1378:	0005a503          	lw	a0,0(a1)
    }
    137c:	00008067          	ret

00001380 <bsp_printf>:

    static void bsp_printf(const char *format, ...)
    {
    1380:	fc010113          	addi	sp,sp,-64
    1384:	00112e23          	sw	ra,28(sp)
    1388:	00812c23          	sw	s0,24(sp)
    138c:	00912a23          	sw	s1,20(sp)
    1390:	00050493          	mv	s1,a0
    1394:	02b12223          	sw	a1,36(sp)
    1398:	02c12423          	sw	a2,40(sp)
    139c:	02d12623          	sw	a3,44(sp)
    13a0:	02e12823          	sw	a4,48(sp)
    13a4:	02f12a23          	sw	a5,52(sp)
    13a8:	03012c23          	sw	a6,56(sp)
    13ac:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;
    
        va_start(ap, format);
    13b0:	02410793          	addi	a5,sp,36
    13b4:	00f12623          	sw	a5,12(sp)
    
        for (i = 0; format[i]; i++)
    13b8:	00000413          	li	s0,0
    13bc:	01c0006f          	j	13d8 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    13c0:	00c12783          	lw	a5,12(sp)
    13c4:	00478713          	addi	a4,a5,4
    13c8:	00e12623          	sw	a4,12(sp)
    13cc:	0007a503          	lw	a0,0(a5)
    13d0:	e25ff0ef          	jal	ra,11f4 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    13d4:	00140413          	addi	s0,s0,1
    13d8:	008487b3          	add	a5,s1,s0
    13dc:	0007c503          	lbu	a0,0(a5)
    13e0:	0c050263          	beqz	a0,14a4 <bsp_printf+0x124>
            if (format[i] == '%') {
    13e4:	02500793          	li	a5,37
    13e8:	06f50663          	beq	a0,a5,1454 <bsp_printf+0xd4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    13ec:	e09ff0ef          	jal	ra,11f4 <bsp_printf_c>
    13f0:	fe5ff06f          	j	13d4 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    13f4:	00c12783          	lw	a5,12(sp)
    13f8:	00478713          	addi	a4,a5,4
    13fc:	00e12623          	sw	a4,12(sp)
    1400:	0007a503          	lw	a0,0(a5)
    1404:	e11ff0ef          	jal	ra,1214 <bsp_printf_s>
                        break;
    1408:	fcdff06f          	j	13d4 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    140c:	00c12783          	lw	a5,12(sp)
    1410:	00478713          	addi	a4,a5,4
    1414:	00e12623          	sw	a4,12(sp)
    1418:	0007a503          	lw	a0,0(a5)
    141c:	e31ff0ef          	jal	ra,124c <bsp_printf_d>
                        break;
    1420:	fb5ff06f          	j	13d4 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    1424:	00c12783          	lw	a5,12(sp)
    1428:	00478713          	addi	a4,a5,4
    142c:	00e12623          	sw	a4,12(sp)
    1430:	0007a503          	lw	a0,0(a5)
    1434:	ed9ff0ef          	jal	ra,130c <bsp_printf_X>
                        break;
    1438:	f9dff06f          	j	13d4 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    143c:	00c12783          	lw	a5,12(sp)
    1440:	00478713          	addi	a4,a5,4
    1444:	00e12623          	sw	a4,12(sp)
    1448:	0007a503          	lw	a0,0(a5)
    144c:	e81ff0ef          	jal	ra,12cc <bsp_printf_x>
                        break;
    1450:	f85ff06f          	j	13d4 <bsp_printf+0x54>
                while (format[++i]) {
    1454:	00140413          	addi	s0,s0,1
    1458:	008487b3          	add	a5,s1,s0
    145c:	0007c783          	lbu	a5,0(a5)
    1460:	f6078ae3          	beqz	a5,13d4 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    1464:	06300713          	li	a4,99
    1468:	f4e78ce3          	beq	a5,a4,13c0 <bsp_printf+0x40>
                    else if (format[i] == 's') {
    146c:	07300713          	li	a4,115
    1470:	f8e782e3          	beq	a5,a4,13f4 <bsp_printf+0x74>
                    else if (format[i] == 'd') {
    1474:	06400713          	li	a4,100
    1478:	f8e78ae3          	beq	a5,a4,140c <bsp_printf+0x8c>
                    else if (format[i] == 'X') {
    147c:	05800713          	li	a4,88
    1480:	fae782e3          	beq	a5,a4,1424 <bsp_printf+0xa4>
                    else if (format[i] == 'x') {
    1484:	07800713          	li	a4,120
    1488:	fae78ae3          	beq	a5,a4,143c <bsp_printf+0xbc>
                    else if (format[i] == 'f') {
    148c:	06600713          	li	a4,102
    1490:	fce792e3          	bne	a5,a4,1454 <bsp_printf+0xd4>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    1494:	00001537          	lui	a0,0x1
    1498:	66450513          	addi	a0,a0,1636 # 1664 <_data+0x28>
    149c:	d79ff0ef          	jal	ra,1214 <bsp_printf_s>
                        break;
    14a0:	f35ff06f          	j	13d4 <bsp_printf+0x54>
    
        va_end(ap);
    }
    14a4:	01c12083          	lw	ra,28(sp)
    14a8:	01812403          	lw	s0,24(sp)
    14ac:	01412483          	lw	s1,20(sp)
    14b0:	04010113          	addi	sp,sp,64
    14b4:	00008067          	ret

000014b8 <error_state>:
void trap();
void crash();
void trap_entry();
void axiInterrupt();

void error_state() {
    14b8:	ff010113          	addi	sp,sp,-16
    14bc:	00112623          	sw	ra,12(sp)
    bsp_printf("Failed! \r\n");
    14c0:	00001537          	lui	a0,0x1
    14c4:	6b050513          	addi	a0,a0,1712 # 16b0 <_data+0x74>
    14c8:	eb9ff0ef          	jal	ra,1380 <bsp_printf>
    while (1) {}
    14cc:	0000006f          	j	14cc <error_state+0x14>

000014d0 <crash>:
}

void crash(){
    14d0:	ff010113          	addi	sp,sp,-16
    14d4:	00112623          	sw	ra,12(sp)
    bsp_printf("\r\n*** CRASH ***\r\n");
    14d8:	00001537          	lui	a0,0x1
    14dc:	6bc50513          	addi	a0,a0,1724 # 16bc <_data+0x80>
    14e0:	ea1ff0ef          	jal	ra,1380 <bsp_printf>
    while(1);
    14e4:	0000006f          	j	14e4 <crash+0x14>

000014e8 <intr_init>:
}

void intr_init(){
    14e8:	ff010113          	addi	sp,sp,-16
    14ec:	00112623          	sw	ra,12(sp)
    //configure PLIC
    //cpu 0 accept all interrupts with priority above 0
    plic_set_threshold(BSP_PLIC, BSP_PLIC_CPU_0, 0); 
    14f0:	00000613          	li	a2,0
    14f4:	00000593          	li	a1,0
    14f8:	f8c00537          	lui	a0,0xf8c00
    14fc:	e51ff0ef          	jal	ra,134c <plic_set_threshold>
    plic_set_priority(BSP_PLIC, SYSTEM_PLIC_SYSTEM_AXI_A_INTERRUPT, 1);

#endif  
    //enable interrupts
    //Set the machine trap vector (../common/trap.S)
    csr_write(mtvec, trap_entry); 
    1500:	000017b7          	lui	a5,0x1
    1504:	5ac78793          	addi	a5,a5,1452 # 15ac <trap_entry>
    1508:	30579073          	csrw	mtvec,a5
    //Enable external interrupts
    csr_set(mie, MIE_MEIE); 
    150c:	000017b7          	lui	a5,0x1
    1510:	80078793          	addi	a5,a5,-2048 # 800 <regnum_t6+0x7e1>
    1514:	3047a073          	csrs	mie,a5
    csr_write(mstatus, MSTATUS_MPP | MSTATUS_MIE);
    1518:	000027b7          	lui	a5,0x2
    151c:	80878793          	addi	a5,a5,-2040 # 1808 <_end+0xe8>
    1520:	30079073          	csrw	mstatus,a5
}
    1524:	00c12083          	lw	ra,12(sp)
    1528:	01010113          	addi	sp,sp,16
    152c:	00008067          	ret

00001530 <axiInterrupt>:
    } else {
        crash();
    }
}

void axiInterrupt(){
    1530:	ff010113          	addi	sp,sp,-16
    1534:	00112623          	sw	ra,12(sp)

    uint32_t claim;
    //While there is pending interrupts
    while(claim = plic_claim(BSP_PLIC, BSP_PLIC_CPU_0)){
    1538:	00000593          	li	a1,0
    153c:	f8c00537          	lui	a0,0xf8c00
    1540:	e25ff0ef          	jal	ra,1364 <plic_claim>
    1544:	00051863          	bnez	a0,1554 <axiInterrupt+0x24>
        default: crash(); break;
        }
        //unmask the claimed interrupt
        plic_release(BSP_PLIC, BSP_PLIC_CPU_0, claim); 
    }
}
    1548:	00c12083          	lw	ra,12(sp)
    154c:	01010113          	addi	sp,sp,16
    1550:	00008067          	ret
        default: crash(); break;
    1554:	f7dff0ef          	jal	ra,14d0 <crash>

00001558 <trap>:
void trap(){
    1558:	ff010113          	addi	sp,sp,-16
    155c:	00112623          	sw	ra,12(sp)
    int32_t mcause    = csr_read(mcause);
    1560:	342027f3          	csrr	a5,mcause
    if(interrupt){
    1564:	0207d263          	bgez	a5,1588 <trap+0x30>
    1568:	00f7f713          	andi	a4,a5,15
        switch(cause){
    156c:	00b00793          	li	a5,11
    1570:	00f71a63          	bne	a4,a5,1584 <trap+0x2c>
        case CAUSE_MACHINE_EXTERNAL: axiInterrupt(); break;
    1574:	fbdff0ef          	jal	ra,1530 <axiInterrupt>
}
    1578:	00c12083          	lw	ra,12(sp)
    157c:	01010113          	addi	sp,sp,16
    1580:	00008067          	ret
        default: crash(); break;
    1584:	f4dff0ef          	jal	ra,14d0 <crash>
        crash();
    1588:	f49ff0ef          	jal	ra,14d0 <crash>

0000158c <main>:


void main() {
    158c:	ff010113          	addi	sp,sp,-16
    1590:	00112623          	sw	ra,12(sp)
    // write 0x0000 to clear AXI interrupt pin to '0'
    write_u32(0x0000, SYSTEM_AXI_A_BMB);    

#else

    bsp_printf("axi4 slave is disabled, please enable it to run this app. \r\n");
    1594:	00001537          	lui	a0,0x1
    1598:	6d050513          	addi	a0,a0,1744 # 16d0 <_data+0x94>
    159c:	de5ff0ef          	jal	ra,1380 <bsp_printf>

#endif

}
    15a0:	00c12083          	lw	ra,12(sp)
    15a4:	01010113          	addi	sp,sp,16
    15a8:	00008067          	ret

000015ac <trap_entry>:
.global  trap_entry
.align(2) //mtvec require 32 bits allignement
trap_entry:
  addi sp,sp, -16*4
    15ac:	fc010113          	addi	sp,sp,-64
  sw x1,   0*4(sp)
    15b0:	00112023          	sw	ra,0(sp)
  sw x5,   1*4(sp)
    15b4:	00512223          	sw	t0,4(sp)
  sw x6,   2*4(sp)
    15b8:	00612423          	sw	t1,8(sp)
  sw x7,   3*4(sp)
    15bc:	00712623          	sw	t2,12(sp)
  sw x10,  4*4(sp)
    15c0:	00a12823          	sw	a0,16(sp)
  sw x11,  5*4(sp)
    15c4:	00b12a23          	sw	a1,20(sp)
  sw x12,  6*4(sp)
    15c8:	00c12c23          	sw	a2,24(sp)
  sw x13,  7*4(sp)
    15cc:	00d12e23          	sw	a3,28(sp)
  sw x14,  8*4(sp)
    15d0:	02e12023          	sw	a4,32(sp)
  sw x15,  9*4(sp)
    15d4:	02f12223          	sw	a5,36(sp)
  sw x16, 10*4(sp)
    15d8:	03012423          	sw	a6,40(sp)
  sw x17, 11*4(sp)
    15dc:	03112623          	sw	a7,44(sp)
  sw x28, 12*4(sp)
    15e0:	03c12823          	sw	t3,48(sp)
  sw x29, 13*4(sp)
    15e4:	03d12a23          	sw	t4,52(sp)
  sw x30, 14*4(sp)
    15e8:	03e12c23          	sw	t5,56(sp)
  sw x31, 15*4(sp)
    15ec:	03f12e23          	sw	t6,60(sp)
  call trap
    15f0:	f69ff0ef          	jal	ra,1558 <trap>
  lw x1 ,  0*4(sp)
    15f4:	00012083          	lw	ra,0(sp)
  lw x5,   1*4(sp)
    15f8:	00412283          	lw	t0,4(sp)
  lw x6,   2*4(sp)
    15fc:	00812303          	lw	t1,8(sp)
  lw x7,   3*4(sp)
    1600:	00c12383          	lw	t2,12(sp)
  lw x10,  4*4(sp)
    1604:	01012503          	lw	a0,16(sp)
  lw x11,  5*4(sp)
    1608:	01412583          	lw	a1,20(sp)
  lw x12,  6*4(sp)
    160c:	01812603          	lw	a2,24(sp)
  lw x13,  7*4(sp)
    1610:	01c12683          	lw	a3,28(sp)
  lw x14,  8*4(sp)
    1614:	02012703          	lw	a4,32(sp)
  lw x15,  9*4(sp)
    1618:	02412783          	lw	a5,36(sp)
  lw x16, 10*4(sp)
    161c:	02812803          	lw	a6,40(sp)
  lw x17, 11*4(sp)
    1620:	02c12883          	lw	a7,44(sp)
  lw x28, 12*4(sp)
    1624:	03012e03          	lw	t3,48(sp)
  lw x29, 13*4(sp)
    1628:	03412e83          	lw	t4,52(sp)
  lw x30, 14*4(sp)
    162c:	03812f03          	lw	t5,56(sp)
  lw x31, 15*4(sp)
    1630:	03c12f83          	lw	t6,60(sp)
  addi sp,sp, 16*4
    1634:	04010113          	addi	sp,sp,64
  mret
    1638:	30200073          	mret
