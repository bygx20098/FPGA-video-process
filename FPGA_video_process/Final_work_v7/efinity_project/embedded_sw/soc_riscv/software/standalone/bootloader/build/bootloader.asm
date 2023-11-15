
build/bootloader.elf:     file format elf32-littleriscv


Disassembly of section .init:

f9000000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
f9000000:	00001197          	auipc	gp,0x1
f9000004:	d1018193          	addi	gp,gp,-752 # f9000d10 <__global_pointer$>

f9000008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
f9000008:	92018113          	addi	sp,gp,-1760 # f9000630 <_sp>

	/* Load data section */
	la a0, _data_lma
f900000c:	81018513          	addi	a0,gp,-2032 # f9000520 <_data>
	la a1, _data
f9000010:	81018593          	addi	a1,gp,-2032 # f9000520 <_data>
	la a2, _edata
f9000014:	81c18613          	addi	a2,gp,-2020 # f900052c <__bss_start>
	bgeu a1, a2, 2f
f9000018:	00c5fc63          	bgeu	a1,a2,f9000030 <init+0x28>
1:
	lw t0, (a0)
f900001c:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
f9000020:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
f9000024:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
f9000028:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
f900002c:	fec5e8e3          	bltu	a1,a2,f900001c <init+0x14>
2:

	/* Clear bss section */
	la a0, __bss_start
f9000030:	81c18513          	addi	a0,gp,-2020 # f900052c <__bss_start>
	la a1, _end
f9000034:	82018593          	addi	a1,gp,-2016 # f9000530 <_end>
	bgeu a0, a1, 2f
f9000038:	00b57863          	bgeu	a0,a1,f9000048 <init+0x40>
1:
	sw zero, (a0)
f900003c:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
f9000040:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
f9000044:	feb56ce3          	bltu	a0,a1,f900003c <init+0x34>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
f9000048:	454000ef          	jal	ra,f900049c <__libc_init_array>
#endif

	call main
f900004c:	438000ef          	jal	ra,f9000484 <main>

f9000050 <mainDone>:
mainDone:
    j mainDone
f9000050:	0000006f          	j	f9000050 <mainDone>

f9000054 <_init>:


	.globl _init
_init:
    ret
f9000054:	00008067          	ret

Disassembly of section .text:

f9000058 <clint_uDelay>:
    
        return (((u64)hi) << 32) | lo;
    }
    
    static void clint_uDelay(u32 usec, u32 hz, u32 reg){
        u32 mTimePerUsec = hz/1000000;
f9000058:	000f47b7          	lui	a5,0xf4
f900005c:	24078793          	addi	a5,a5,576 # f4240 <__stack_size+0xf4140>
f9000060:	02f5d5b3          	divu	a1,a1,a5
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
f9000064:	0000c7b7          	lui	a5,0xc
f9000068:	ff878793          	addi	a5,a5,-8 # bff8 <__stack_size+0xbef8>
f900006c:	00f60633          	add	a2,a2,a5
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
f9000070:	00062783          	lw	a5,0(a2)
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
f9000074:	02a58533          	mul	a0,a1,a0
f9000078:	00f50533          	add	a0,a0,a5
f900007c:	00062783          	lw	a5,0(a2)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
f9000080:	40f507b3          	sub	a5,a0,a5
f9000084:	fe07dce3          	bgez	a5,f900007c <clint_uDelay+0x24>
    }
f9000088:	00008067          	ret

f900008c <spi_cmdAvailability>:
f900008c:	00452503          	lw	a0,4(a0)
        u32 ssDisable;
    } Spi_Config;
    
    static u32 spi_cmdAvailability(u32 reg){
        return read_u32(reg + SPI_BUFFER) & 0xFFFF;
    }
f9000090:	01051513          	slli	a0,a0,0x10
f9000094:	01055513          	srli	a0,a0,0x10
f9000098:	00008067          	ret

f900009c <spi_rspOccupancy>:
f900009c:	00452503          	lw	a0,4(a0)
    static u32 spi_rspOccupancy(u32 reg){
        return read_u32(reg + SPI_BUFFER) >> 16;
    }
f90000a0:	01055513          	srli	a0,a0,0x10
f90000a4:	00008067          	ret

f90000a8 <spi_write>:
    
    static void spi_write(u32 reg, u8 data){
f90000a8:	ff010113          	addi	sp,sp,-16
f90000ac:	00112623          	sw	ra,12(sp)
f90000b0:	00812423          	sw	s0,8(sp)
f90000b4:	00912223          	sw	s1,4(sp)
f90000b8:	00050413          	mv	s0,a0
f90000bc:	00058493          	mv	s1,a1
        while(spi_cmdAvailability(reg) == 0);
f90000c0:	00040513          	mv	a0,s0
f90000c4:	fc9ff0ef          	jal	ra,f900008c <spi_cmdAvailability>
f90000c8:	fe050ce3          	beqz	a0,f90000c0 <spi_write+0x18>
        write_u32(data | SPI_CMD_WRITE, reg + SPI_DATA);
f90000cc:	1004e493          	ori	s1,s1,256
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
f90000d0:	00942023          	sw	s1,0(s0)
    }
f90000d4:	00c12083          	lw	ra,12(sp)
f90000d8:	00812403          	lw	s0,8(sp)
f90000dc:	00412483          	lw	s1,4(sp)
f90000e0:	01010113          	addi	sp,sp,16
f90000e4:	00008067          	ret

f90000e8 <spi_read>:
    
    static u8 spi_read(u32 reg){
f90000e8:	ff010113          	addi	sp,sp,-16
f90000ec:	00112623          	sw	ra,12(sp)
f90000f0:	00812423          	sw	s0,8(sp)
f90000f4:	00050413          	mv	s0,a0
        while(spi_cmdAvailability(reg) == 0);
f90000f8:	00040513          	mv	a0,s0
f90000fc:	f91ff0ef          	jal	ra,f900008c <spi_cmdAvailability>
f9000100:	fe050ce3          	beqz	a0,f90000f8 <spi_read+0x10>
f9000104:	20000793          	li	a5,512
f9000108:	00f42023          	sw	a5,0(s0)
        write_u32(SPI_CMD_READ, reg + SPI_DATA);
        while(spi_rspOccupancy(reg) == 0);
f900010c:	00040513          	mv	a0,s0
f9000110:	f8dff0ef          	jal	ra,f900009c <spi_rspOccupancy>
f9000114:	fe050ce3          	beqz	a0,f900010c <spi_read+0x24>
        return *((volatile u32*) address);
f9000118:	00042503          	lw	a0,0(s0)
        return read_u32(reg + SPI_DATA);
    }
f900011c:	0ff57513          	andi	a0,a0,255
f9000120:	00c12083          	lw	ra,12(sp)
f9000124:	00812403          	lw	s0,8(sp)
f9000128:	01010113          	addi	sp,sp,16
f900012c:	00008067          	ret

f9000130 <spi_select>:
        write_u32(SPI_CMD_READ, reg + SPI_DATA);
        while(spi_rspOccupancy(reg) == 0);
        return read_u32(reg + SPI_READ_LARGE);
    }
    
    static void spi_select(u32 reg, u32 slaveId){
f9000130:	ff010113          	addi	sp,sp,-16
f9000134:	00112623          	sw	ra,12(sp)
f9000138:	00812423          	sw	s0,8(sp)
f900013c:	00912223          	sw	s1,4(sp)
f9000140:	00050413          	mv	s0,a0
f9000144:	00058493          	mv	s1,a1
        while(spi_cmdAvailability(reg) == 0);
f9000148:	00040513          	mv	a0,s0
f900014c:	f41ff0ef          	jal	ra,f900008c <spi_cmdAvailability>
f9000150:	fe050ce3          	beqz	a0,f9000148 <spi_select+0x18>
        write_u32(slaveId | 0x80 | SPI_CMD_SS, reg + SPI_DATA);
f9000154:	000017b7          	lui	a5,0x1
f9000158:	88078793          	addi	a5,a5,-1920 # 880 <__stack_size+0x780>
f900015c:	00f4e4b3          	or	s1,s1,a5
        *((volatile u32*) address) = data;
f9000160:	00942023          	sw	s1,0(s0)
    }
f9000164:	00c12083          	lw	ra,12(sp)
f9000168:	00812403          	lw	s0,8(sp)
f900016c:	00412483          	lw	s1,4(sp)
f9000170:	01010113          	addi	sp,sp,16
f9000174:	00008067          	ret

f9000178 <spi_diselect>:
    
    static void spi_diselect(u32 reg, u32 slaveId){
f9000178:	ff010113          	addi	sp,sp,-16
f900017c:	00112623          	sw	ra,12(sp)
f9000180:	00812423          	sw	s0,8(sp)
f9000184:	00912223          	sw	s1,4(sp)
f9000188:	00050413          	mv	s0,a0
f900018c:	00058493          	mv	s1,a1
        while(spi_cmdAvailability(reg) == 0);
f9000190:	00040513          	mv	a0,s0
f9000194:	ef9ff0ef          	jal	ra,f900008c <spi_cmdAvailability>
f9000198:	fe050ce3          	beqz	a0,f9000190 <spi_diselect+0x18>
        write_u32(slaveId | 0x00 | SPI_CMD_SS, reg + SPI_DATA);
f900019c:	000017b7          	lui	a5,0x1
f90001a0:	80078793          	addi	a5,a5,-2048 # 800 <__stack_size+0x700>
f90001a4:	00f4e4b3          	or	s1,s1,a5
f90001a8:	00942023          	sw	s1,0(s0)
    }
f90001ac:	00c12083          	lw	ra,12(sp)
f90001b0:	00812403          	lw	s0,8(sp)
f90001b4:	00412483          	lw	s1,4(sp)
f90001b8:	01010113          	addi	sp,sp,16
f90001bc:	00008067          	ret

f90001c0 <spi_applyConfig>:
    
    static void spi_applyConfig(u32 reg, Spi_Config *config){
        write_u32((config->cpol << 0) | (config->cpha << 1) | (config->mode << 4), reg + SPI_CONFIG);
f90001c0:	0005a783          	lw	a5,0(a1)
f90001c4:	0045a703          	lw	a4,4(a1)
f90001c8:	00171713          	slli	a4,a4,0x1
f90001cc:	00e7e7b3          	or	a5,a5,a4
f90001d0:	0085a703          	lw	a4,8(a1)
f90001d4:	00471713          	slli	a4,a4,0x4
f90001d8:	00e7e7b3          	or	a5,a5,a4
f90001dc:	00f52423          	sw	a5,8(a0)
        write_u32(config->clkDivider, reg + SPI_CLK_DIVIDER);
f90001e0:	00c5a783          	lw	a5,12(a1)
f90001e4:	02f52023          	sw	a5,32(a0)
        write_u32(config->ssSetup, reg + SPI_SS_SETUP);
f90001e8:	0105a783          	lw	a5,16(a1)
f90001ec:	02f52223          	sw	a5,36(a0)
        write_u32(config->ssHold, reg + SPI_SS_HOLD);
f90001f0:	0145a783          	lw	a5,20(a1)
f90001f4:	02f52423          	sw	a5,40(a0)
        write_u32(config->ssDisable, reg + SPI_SS_DISABLE);
f90001f8:	0185a783          	lw	a5,24(a1)
f90001fc:	02f52623          	sw	a5,44(a0)
    }
f9000200:	00008067          	ret

f9000204 <spiFlash_select>:
    static void spiFlash_diselect_withGpioCs(u32 gpio, u32 cs){
        gpio_setOutput(gpio, gpio_getOutput(gpio) | (1 << cs));
        bsp_uDelay(1);
    }
    
    static void spiFlash_select(u32 spi, u32 cs){
f9000204:	ff010113          	addi	sp,sp,-16
f9000208:	00112623          	sw	ra,12(sp)
        spi_select(spi, cs);
f900020c:	f25ff0ef          	jal	ra,f9000130 <spi_select>
    }
f9000210:	00c12083          	lw	ra,12(sp)
f9000214:	01010113          	addi	sp,sp,16
f9000218:	00008067          	ret

f900021c <spiFlash_diselect>:
    
    static void spiFlash_diselect(u32 spi, u32 cs){
f900021c:	ff010113          	addi	sp,sp,-16
f9000220:	00112623          	sw	ra,12(sp)
        spi_diselect(spi, cs);
f9000224:	f55ff0ef          	jal	ra,f9000178 <spi_diselect>
    }
f9000228:	00c12083          	lw	ra,12(sp)
f900022c:	01010113          	addi	sp,sp,16
f9000230:	00008067          	ret

f9000234 <spiFlash_init_>:
    
    static void spiFlash_init_(u32 spi){
f9000234:	fd010113          	addi	sp,sp,-48
f9000238:	02112623          	sw	ra,44(sp)
        Spi_Config spiCfg;
        spiCfg.cpol = 0;
f900023c:	00012223          	sw	zero,4(sp)
        spiCfg.cpha = 0;
f9000240:	00012423          	sw	zero,8(sp)
        spiCfg.mode = 0;
f9000244:	00012623          	sw	zero,12(sp)
        spiCfg.clkDivider = 2;
f9000248:	00200793          	li	a5,2
f900024c:	00f12823          	sw	a5,16(sp)
        spiCfg.ssSetup = 2;
f9000250:	00f12a23          	sw	a5,20(sp)
        spiCfg.ssHold = 2;
f9000254:	00f12c23          	sw	a5,24(sp)
        spiCfg.ssDisable = 2;
f9000258:	00f12e23          	sw	a5,28(sp)
        spi_applyConfig(spi, &spiCfg);
f900025c:	00410593          	addi	a1,sp,4
f9000260:	f61ff0ef          	jal	ra,f90001c0 <spi_applyConfig>
    }
f9000264:	02c12083          	lw	ra,44(sp)
f9000268:	03010113          	addi	sp,sp,48
f900026c:	00008067          	ret

f9000270 <spiFlash_init>:
        spiFlash_init_(spi);
        gpio_setOutputEnable(gpio, gpio_getOutputEnable(gpio) | (1 << cs));
        spiFlash_diselect_withGpioCs(gpio,cs);
    }
    
    static void spiFlash_init(u32 spi, u32 cs){
f9000270:	ff010113          	addi	sp,sp,-16
f9000274:	00112623          	sw	ra,12(sp)
f9000278:	00812423          	sw	s0,8(sp)
f900027c:	00912223          	sw	s1,4(sp)
f9000280:	00050413          	mv	s0,a0
f9000284:	00058493          	mv	s1,a1
        spiFlash_init_(spi);
f9000288:	fadff0ef          	jal	ra,f9000234 <spiFlash_init_>
        spiFlash_diselect(spi, cs);
f900028c:	00048593          	mv	a1,s1
f9000290:	00040513          	mv	a0,s0
f9000294:	f89ff0ef          	jal	ra,f900021c <spiFlash_diselect>
    }
f9000298:	00c12083          	lw	ra,12(sp)
f900029c:	00812403          	lw	s0,8(sp)
f90002a0:	00412483          	lw	s1,4(sp)
f90002a4:	01010113          	addi	sp,sp,16
f90002a8:	00008067          	ret

f90002ac <spiFlash_wake_>:
    
    static void spiFlash_wake_(u32 spi){
f90002ac:	ff010113          	addi	sp,sp,-16
f90002b0:	00112623          	sw	ra,12(sp)
        spi_write(spi, 0xAB);
f90002b4:	0ab00593          	li	a1,171
f90002b8:	df1ff0ef          	jal	ra,f90000a8 <spi_write>
#ifdef DEFAULT_ADDRESS_BYTE
        //return to 3-byte addressing
        bsp_uDelay(300);
        spi_write(spi, 0xE9);
#endif
    }
f90002bc:	00c12083          	lw	ra,12(sp)
f90002c0:	01010113          	addi	sp,sp,16
f90002c4:	00008067          	ret

f90002c8 <spiFlash_wake>:
        spiFlash_wake_(spi);
        spiFlash_diselect_withGpioCs(gpio,cs);
        bsp_uDelay(200);
    }
    
    static void spiFlash_wake(u32 spi, u32 cs){
f90002c8:	ff010113          	addi	sp,sp,-16
f90002cc:	00112623          	sw	ra,12(sp)
f90002d0:	00812423          	sw	s0,8(sp)
f90002d4:	00912223          	sw	s1,4(sp)
f90002d8:	00050413          	mv	s0,a0
f90002dc:	00058493          	mv	s1,a1
        spiFlash_select(spi,cs);
f90002e0:	f25ff0ef          	jal	ra,f9000204 <spiFlash_select>
        spiFlash_wake_(spi);
f90002e4:	00040513          	mv	a0,s0
f90002e8:	fc5ff0ef          	jal	ra,f90002ac <spiFlash_wake_>
        spiFlash_diselect(spi,cs);
f90002ec:	00048593          	mv	a1,s1
f90002f0:	00040513          	mv	a0,s0
f90002f4:	f29ff0ef          	jal	ra,f900021c <spiFlash_diselect>
        bsp_uDelay(200);
f90002f8:	f8b00637          	lui	a2,0xf8b00
f90002fc:	05f5e5b7          	lui	a1,0x5f5e
f9000300:	10058593          	addi	a1,a1,256 # 5f5e100 <__stack_size+0x5f5e000>
f9000304:	0c800513          	li	a0,200
f9000308:	d51ff0ef          	jal	ra,f9000058 <clint_uDelay>
    }
f900030c:	00c12083          	lw	ra,12(sp)
f9000310:	00812403          	lw	s0,8(sp)
f9000314:	00412483          	lw	s1,4(sp)
f9000318:	01010113          	addi	sp,sp,16
f900031c:	00008067          	ret

f9000320 <spiFlash_f2m_>:
        id = spiFlash_read_id_(spi);
        spiFlash_diselect(spi,cs);
        return id;
    }
    
    static void spiFlash_f2m_(u32 spi, u32 flashAddress, u32 memoryAddress, u32 size){
f9000320:	fe010113          	addi	sp,sp,-32
f9000324:	00112e23          	sw	ra,28(sp)
f9000328:	00812c23          	sw	s0,24(sp)
f900032c:	00912a23          	sw	s1,20(sp)
f9000330:	01212823          	sw	s2,16(sp)
f9000334:	01312623          	sw	s3,12(sp)
f9000338:	00050913          	mv	s2,a0
f900033c:	00058493          	mv	s1,a1
f9000340:	00060413          	mv	s0,a2
f9000344:	00068993          	mv	s3,a3
        spi_write(spi, 0x0B);
f9000348:	00b00593          	li	a1,11
f900034c:	d5dff0ef          	jal	ra,f90000a8 <spi_write>
        spi_write(spi, flashAddress >> 16);
f9000350:	0104d593          	srli	a1,s1,0x10
f9000354:	0ff5f593          	andi	a1,a1,255
f9000358:	00090513          	mv	a0,s2
f900035c:	d4dff0ef          	jal	ra,f90000a8 <spi_write>
        spi_write(spi, flashAddress >>  8);
f9000360:	0084d593          	srli	a1,s1,0x8
f9000364:	0ff5f593          	andi	a1,a1,255
f9000368:	00090513          	mv	a0,s2
f900036c:	d3dff0ef          	jal	ra,f90000a8 <spi_write>
        spi_write(spi, flashAddress >>  0);
f9000370:	0ff4f593          	andi	a1,s1,255
f9000374:	00090513          	mv	a0,s2
f9000378:	d31ff0ef          	jal	ra,f90000a8 <spi_write>
        spi_write(spi, 0);
f900037c:	00000593          	li	a1,0
f9000380:	00090513          	mv	a0,s2
f9000384:	d25ff0ef          	jal	ra,f90000a8 <spi_write>
        uint8_t *ram = (uint8_t *) memoryAddress;
        for(u32 idx = 0;idx < size;idx++){
f9000388:	00000493          	li	s1,0
f900038c:	0134fe63          	bgeu	s1,s3,f90003a8 <spiFlash_f2m_+0x88>
            u8 value = spi_read(spi);
f9000390:	00090513          	mv	a0,s2
f9000394:	d55ff0ef          	jal	ra,f90000e8 <spi_read>
            *ram++ = value;
f9000398:	00a40023          	sb	a0,0(s0)
        for(u32 idx = 0;idx < size;idx++){
f900039c:	00148493          	addi	s1,s1,1
            *ram++ = value;
f90003a0:	00140413          	addi	s0,s0,1
f90003a4:	fe9ff06f          	j	f900038c <spiFlash_f2m_+0x6c>
        }
    }
f90003a8:	01c12083          	lw	ra,28(sp)
f90003ac:	01812403          	lw	s0,24(sp)
f90003b0:	01412483          	lw	s1,20(sp)
f90003b4:	01012903          	lw	s2,16(sp)
f90003b8:	00c12983          	lw	s3,12(sp)
f90003bc:	02010113          	addi	sp,sp,32
f90003c0:	00008067          	ret

f90003c4 <spiFlash_f2m>:
        spiFlash_select_withGpioCs(gpio,cs);
        spiFlash_f2m_(spi, flashAddress, memoryAddress, size);
        spiFlash_diselect_withGpioCs(gpio,cs);
    }
    
    static void spiFlash_f2m(u32 spi, u32 cs, u32 flashAddress, u32 memoryAddress, u32 size){
f90003c4:	fe010113          	addi	sp,sp,-32
f90003c8:	00112e23          	sw	ra,28(sp)
f90003cc:	00812c23          	sw	s0,24(sp)
f90003d0:	00912a23          	sw	s1,20(sp)
f90003d4:	01212823          	sw	s2,16(sp)
f90003d8:	01312623          	sw	s3,12(sp)
f90003dc:	01412423          	sw	s4,8(sp)
f90003e0:	00050413          	mv	s0,a0
f90003e4:	00058493          	mv	s1,a1
f90003e8:	00060913          	mv	s2,a2
f90003ec:	00068993          	mv	s3,a3
f90003f0:	00070a13          	mv	s4,a4
        spiFlash_select(spi,cs);
f90003f4:	e11ff0ef          	jal	ra,f9000204 <spiFlash_select>
        spiFlash_f2m_(spi, flashAddress, memoryAddress, size);
f90003f8:	000a0693          	mv	a3,s4
f90003fc:	00098613          	mv	a2,s3
f9000400:	00090593          	mv	a1,s2
f9000404:	00040513          	mv	a0,s0
f9000408:	f19ff0ef          	jal	ra,f9000320 <spiFlash_f2m_>
        spiFlash_diselect(spi,cs);
f900040c:	00048593          	mv	a1,s1
f9000410:	00040513          	mv	a0,s0
f9000414:	e09ff0ef          	jal	ra,f900021c <spiFlash_diselect>
    }
f9000418:	01c12083          	lw	ra,28(sp)
f900041c:	01812403          	lw	s0,24(sp)
f9000420:	01412483          	lw	s1,20(sp)
f9000424:	01012903          	lw	s2,16(sp)
f9000428:	00c12983          	lw	s3,12(sp)
f900042c:	00812a03          	lw	s4,8(sp)
f9000430:	02010113          	addi	sp,sp,32
f9000434:	00008067          	ret

f9000438 <bspMain>:
#define USER_SOFTWARE_MEMORY 0x00001000
#define USER_SOFTWARE_FLASH    0x380000
#define USER_SOFTWARE_SIZE	   0x01F000


void bspMain() {
f9000438:	ff010113          	addi	sp,sp,-16
f900043c:	00112623          	sw	ra,12(sp)
#ifndef SIM
	spiFlash_init(SPI, SPI_CS);
f9000440:	00000593          	li	a1,0
f9000444:	f8014537          	lui	a0,0xf8014
f9000448:	e29ff0ef          	jal	ra,f9000270 <spiFlash_init>
	spiFlash_wake(SPI, SPI_CS);
f900044c:	00000593          	li	a1,0
f9000450:	f8014537          	lui	a0,0xf8014
f9000454:	e75ff0ef          	jal	ra,f90002c8 <spiFlash_wake>
	spiFlash_f2m(SPI, SPI_CS, USER_SOFTWARE_FLASH, USER_SOFTWARE_MEMORY, USER_SOFTWARE_SIZE);
f9000458:	0001f737          	lui	a4,0x1f
f900045c:	000016b7          	lui	a3,0x1
f9000460:	00380637          	lui	a2,0x380
f9000464:	00000593          	li	a1,0
f9000468:	f8014537          	lui	a0,0xf8014
f900046c:	f59ff0ef          	jal	ra,f90003c4 <spiFlash_f2m>

	void (*userMain)() = (void (*)())USER_SOFTWARE_MEMORY;
    #ifdef SMP
        smp_unlock(userMain);
    #endif
	userMain();
f9000470:	000017b7          	lui	a5,0x1
f9000474:	000780e7          	jalr	a5 # 1000 <__stack_size+0xf00>
}
f9000478:	00c12083          	lw	ra,12(sp)
f900047c:	01010113          	addi	sp,sp,16
f9000480:	00008067          	ret

f9000484 <main>:
///////////////////////////////////////////////////////////////////////////////////
#include "type.h"
#include "bsp.h"
#include "bootloaderConfig.h"

void main() {
f9000484:	ff010113          	addi	sp,sp,-16
f9000488:	00112623          	sw	ra,12(sp)
    bsp_init();
    bspMain();
f900048c:	fadff0ef          	jal	ra,f9000438 <bspMain>
}
f9000490:	00c12083          	lw	ra,12(sp)
f9000494:	01010113          	addi	sp,sp,16
f9000498:	00008067          	ret

f900049c <__libc_init_array>:
f900049c:	ff010113          	addi	sp,sp,-16
f90004a0:	00812423          	sw	s0,8(sp)
f90004a4:	01212023          	sw	s2,0(sp)
f90004a8:	81018413          	addi	s0,gp,-2032 # f9000520 <_data>
f90004ac:	81018913          	addi	s2,gp,-2032 # f9000520 <_data>
f90004b0:	40890933          	sub	s2,s2,s0
f90004b4:	00112623          	sw	ra,12(sp)
f90004b8:	00912223          	sw	s1,4(sp)
f90004bc:	40295913          	srai	s2,s2,0x2
f90004c0:	00090e63          	beqz	s2,f90004dc <__libc_init_array+0x40>
f90004c4:	00000493          	li	s1,0
f90004c8:	00042783          	lw	a5,0(s0)
f90004cc:	00148493          	addi	s1,s1,1
f90004d0:	00440413          	addi	s0,s0,4
f90004d4:	000780e7          	jalr	a5
f90004d8:	fe9918e3          	bne	s2,s1,f90004c8 <__libc_init_array+0x2c>
f90004dc:	81018413          	addi	s0,gp,-2032 # f9000520 <_data>
f90004e0:	81018913          	addi	s2,gp,-2032 # f9000520 <_data>
f90004e4:	40890933          	sub	s2,s2,s0
f90004e8:	40295913          	srai	s2,s2,0x2
f90004ec:	00090e63          	beqz	s2,f9000508 <__libc_init_array+0x6c>
f90004f0:	00000493          	li	s1,0
f90004f4:	00042783          	lw	a5,0(s0)
f90004f8:	00148493          	addi	s1,s1,1
f90004fc:	00440413          	addi	s0,s0,4
f9000500:	000780e7          	jalr	a5
f9000504:	fe9918e3          	bne	s2,s1,f90004f4 <__libc_init_array+0x58>
f9000508:	00c12083          	lw	ra,12(sp)
f900050c:	00812403          	lw	s0,8(sp)
f9000510:	00412483          	lw	s1,4(sp)
f9000514:	00012903          	lw	s2,0(sp)
f9000518:	01010113          	addi	sp,sp,16
f900051c:	00008067          	ret
