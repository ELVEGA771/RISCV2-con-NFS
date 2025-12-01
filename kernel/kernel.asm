
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000f117          	auipc	sp,0xf
    80000004:	80013103          	ld	sp,-2048(sp) # 8000e800 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcf7e7>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	1ce020ef          	jal	800022e0 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00016517          	auipc	a0,0x16
    80000190:	74450513          	addi	a0,a0,1860 # 800168d0 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00016497          	auipc	s1,0x16
    8000019c:	73848493          	addi	s1,s1,1848 # 800168d0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00016917          	auipc	s2,0x16
    800001a4:	7c890913          	addi	s2,s2,1992 # 80016968 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	73e010ef          	jal	800018f6 <myproc>
    800001bc:	7b7010ef          	jal	80002172 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	575010ef          	jal	80001f3a <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00016717          	auipc	a4,0x16
    800001dc:	6f870713          	addi	a4,a4,1784 # 800168d0 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	08c020ef          	jal	80002296 <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00016517          	auipc	a0,0x16
    80000226:	6ae50513          	addi	a0,a0,1710 # 800168d0 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00016717          	auipc	a4,0x16
    80000250:	70f72e23          	sw	a5,1820(a4) # 80016968 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00016517          	auipc	a0,0x16
    80000266:	66e50513          	addi	a0,a0,1646 # 800168d0 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00016517          	auipc	a0,0x16
    800002ba:	61a50513          	addi	a0,a0,1562 # 800168d0 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	052020ef          	jal	8000232a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00016517          	auipc	a0,0x16
    800002e0:	5f450513          	addi	a0,a0,1524 # 800168d0 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00016717          	auipc	a4,0x16
    800002fe:	5d670713          	addi	a4,a4,1494 # 800168d0 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00016797          	auipc	a5,0x16
    80000324:	5b078793          	addi	a5,a5,1456 # 800168d0 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00016797          	auipc	a5,0x16
    80000352:	61a7a783          	lw	a5,1562(a5) # 80016968 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00016717          	auipc	a4,0x16
    80000368:	56c70713          	addi	a4,a4,1388 # 800168d0 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00016497          	auipc	s1,0x16
    80000378:	55c48493          	addi	s1,s1,1372 # 800168d0 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00016717          	auipc	a4,0x16
    800003ba:	51a70713          	addi	a4,a4,1306 # 800168d0 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00016717          	auipc	a4,0x16
    800003d0:	5af72223          	sw	a5,1444(a4) # 80016970 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00016797          	auipc	a5,0x16
    800003ee:	4e678793          	addi	a5,a5,1254 # 800168d0 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00016797          	auipc	a5,0x16
    80000412:	54c7af23          	sw	a2,1374(a5) # 8001696c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00016517          	auipc	a0,0x16
    8000041a:	55250513          	addi	a0,a0,1362 # 80016968 <cons+0x98>
    8000041e:	369010ef          	jal	80001f86 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	0000a597          	auipc	a1,0xa
    80000430:	bd458593          	addi	a1,a1,-1068 # 8000a000 <etext>
    80000434:	00016517          	auipc	a0,0x16
    80000438:	49c50513          	addi	a0,a0,1180 # 800168d0 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00027797          	auipc	a5,0x27
    80000448:	f5c78793          	addi	a5,a5,-164 # 800273a0 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	0000a617          	auipc	a2,0xa
    80000482:	5c260613          	addi	a2,a2,1474 # 8000aa40 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000e797          	auipc	a5,0xe
    8000051c:	30c7a783          	lw	a5,780(a5) # 8000e824 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00016517          	auipc	a0,0x16
    80000564:	41850513          	addi	a0,a0,1048 # 80016978 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	0000ab97          	auipc	s7,0xa
    8000072c:	318b8b93          	addi	s7,s7,792 # 8000aa40 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	0000a917          	auipc	s2,0xa
    8000078c:	88090913          	addi	s2,s2,-1920 # 8000a008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000e797          	auipc	a5,0xe
    800007c0:	0687a783          	lw	a5,104(a5) # 8000e824 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00016517          	auipc	a0,0x16
    800007d6:	1a650513          	addi	a0,a0,422 # 80016978 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000e797          	auipc	a5,0xe
    800007f4:	0327aa23          	sw	s2,52(a5) # 8000e824 <panicking>
  printf("panic: ");
    800007f8:	0000a517          	auipc	a0,0xa
    800007fc:	82050513          	addi	a0,a0,-2016 # 8000a018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	0000a517          	auipc	a0,0xa
    8000080a:	81a50513          	addi	a0,a0,-2022 # 8000a020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000e797          	auipc	a5,0xe
    80000816:	0127a723          	sw	s2,14(a5) # 8000e820 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	0000a597          	auipc	a1,0xa
    80000828:	80458593          	addi	a1,a1,-2044 # 8000a028 <etext+0x28>
    8000082c:	00016517          	auipc	a0,0x16
    80000830:	14c50513          	addi	a0,a0,332 # 80016978 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00009597          	auipc	a1,0x9
    80000880:	7b458593          	addi	a1,a1,1972 # 8000a030 <etext+0x30>
    80000884:	00016517          	auipc	a0,0x16
    80000888:	10c50513          	addi	a0,a0,268 # 80016990 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00016517          	auipc	a0,0x16
    800008ac:	0e850513          	addi	a0,a0,232 # 80016990 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000e497          	auipc	s1,0xe
    800008ca:	f6648493          	addi	s1,s1,-154 # 8000e82c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00016997          	auipc	s3,0x16
    800008d2:	0c298993          	addi	s3,s3,194 # 80016990 <tx_lock>
    800008d6:	0000e917          	auipc	s2,0xe
    800008da:	f5290913          	addi	s2,s2,-174 # 8000e828 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	650010ef          	jal	80001f3a <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00016517          	auipc	a0,0x16
    80000918:	07c50513          	addi	a0,a0,124 # 80016990 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000e797          	auipc	a5,0xe
    8000093c:	eec7a783          	lw	a5,-276(a5) # 8000e824 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000e797          	auipc	a5,0xe
    80000946:	ede7a783          	lw	a5,-290(a5) # 8000e820 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000e797          	auipc	a5,0xe
    8000096c:	ebc7a783          	lw	a5,-324(a5) # 8000e824 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00016517          	auipc	a0,0x16
    800009c8:	fcc50513          	addi	a0,a0,-52 # 80016990 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00016517          	auipc	a0,0x16
    800009e4:	fb050513          	addi	a0,a0,-80 # 80016990 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000e797          	auipc	a5,0xe
    800009f4:	e207ae23          	sw	zero,-452(a5) # 8000e82c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000e517          	auipc	a0,0xe
    800009fc:	e3050513          	addi	a0,a0,-464 # 8000e828 <tx_chan>
    80000a00:	586010ef          	jal	80001f86 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	0002e797          	auipc	a5,0x2e
    80000a34:	5e878793          	addi	a5,a5,1512 # 8002f018 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00016917          	auipc	s2,0x16
    80000a50:	f5c90913          	addi	s2,s2,-164 # 800169a8 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00009517          	auipc	a0,0x9
    80000a7a:	5c250513          	addi	a0,a0,1474 # 8000a038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00009597          	auipc	a1,0x9
    80000ad6:	56e58593          	addi	a1,a1,1390 # 8000a040 <etext+0x40>
    80000ada:	00016517          	auipc	a0,0x16
    80000ade:	ece50513          	addi	a0,a0,-306 # 800169a8 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	0002e517          	auipc	a0,0x2e
    80000aee:	52e50513          	addi	a0,a0,1326 # 8002f018 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00016497          	auipc	s1,0x16
    80000b0c:	ea048493          	addi	s1,s1,-352 # 800169a8 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00016517          	auipc	a0,0x16
    80000b20:	e8c50513          	addi	a0,a0,-372 # 800169a8 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00016517          	auipc	a0,0x16
    80000b44:	e6850513          	addi	a0,a0,-408 # 800169a8 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	563000ef          	jal	800018da <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	535000ef          	jal	800018da <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	52d000ef          	jal	800018da <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	519000ef          	jal	800018da <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf6:	4e5000ef          	jal	800018da <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00009517          	auipc	a0,0x9
    80000c0a:	44250513          	addi	a0,a0,1090 # 8000a048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	4c1000ef          	jal	800018da <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00009517          	auipc	a0,0x9
    80000c52:	40250513          	addi	a0,a0,1026 # 8000a050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00009517          	auipc	a0,0x9
    80000c5e:	40e50513          	addi	a0,a0,1038 # 8000a068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c80:	0310000f          	fence	rw,w
    80000c84:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00009517          	auipc	a0,0x9
    80000c9a:	3da50513          	addi	a0,a0,986 # 8000a070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffcffe9>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	287000ef          	jal	800018ca <cpuid>
    printf("xv6: VFS and network stack initialized\n");
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	0000e717          	auipc	a4,0xe
    80000e4c:	9e870713          	addi	a4,a4,-1560 # 8000e830 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e5c:	26f000ef          	jal	800018ca <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00009517          	auipc	a0,0x9
    80000e66:	27650513          	addi	a0,a0,630 # 8000a0d8 <etext+0xd8>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	0a8000ef          	jal	80000f16 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	5ea010ef          	jal	8000245c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	6b8040ef          	jal	8000552e <plicinithart>
  }

  scheduler();        
    80000e7a:	729000ef          	jal	80001da2 <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00009517          	auipc	a0,0x9
    80000e8a:	1f250513          	addi	a0,a0,498 # 8000a078 <etext+0x78>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00009517          	auipc	a0,0x9
    80000e96:	1ee50513          	addi	a0,a0,494 # 8000a080 <etext+0x80>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00009517          	auipc	a0,0x9
    80000ea2:	1da50513          	addi	a0,a0,474 # 8000a078 <etext+0x78>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2f2000ef          	jal	800011a0 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	064000ef          	jal	80000f16 <kvminithart>
    procinit();      // process table
    80000eb6:	15f000ef          	jal	80001814 <procinit>
    trapinit();      // trap vectors
    80000eba:	57e010ef          	jal	80002438 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	59e010ef          	jal	8000245c <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	64c040ef          	jal	8000550e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	668040ef          	jal	8000552e <plicinithart>
    binit();         // buffer cache
    80000eca:	435010ef          	jal	80002afe <binit>
    iinit();         // inode table
    80000ece:	10e020ef          	jal	80002fdc <iinit>
    fileinit();      // file table
    80000ed2:	0ac030ef          	jal	80003f7e <fileinit>
    vfs_init();      // virtual file system
    80000ed6:	437040ef          	jal	80005b0c <vfs_init>
    xv6fs_register(); // register xv6fs
    80000eda:	570050ef          	jal	8000644a <xv6fs_register>
    net_init();      // network stack
    80000ede:	59e050ef          	jal	8000647c <net_init>
    nfs_register();  // register NFS
    80000ee2:	3ed070ef          	jal	80008ace <nfs_register>
    printf("DEBUG: init disk\n");    
    80000ee6:	00009517          	auipc	a0,0x9
    80000eea:	1b250513          	addi	a0,a0,434 # 8000a098 <etext+0x98>
    80000eee:	e0cff0ef          	jal	800004fa <printf>
    virtio_disk_init(); // emulated hard disk
    80000ef2:	72c040ef          	jal	8000561e <virtio_disk_init>
    printf("xv6: VFS and network stack initialized\n");
    80000ef6:	00009517          	auipc	a0,0x9
    80000efa:	1ba50513          	addi	a0,a0,442 # 8000a0b0 <etext+0xb0>
    80000efe:	dfcff0ef          	jal	800004fa <printf>
    userinit();      // first user process
    80000f02:	4f5000ef          	jal	80001bf6 <userinit>
    __sync_synchronize();
    80000f06:	0330000f          	fence	rw,rw
    started = 1;
    80000f0a:	4785                	li	a5,1
    80000f0c:	0000e717          	auipc	a4,0xe
    80000f10:	92f72223          	sw	a5,-1756(a4) # 8000e830 <started>
    80000f14:	b79d                	j	80000e7a <main+0x3e>

0000000080000f16 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f16:	1141                	addi	sp,sp,-16
    80000f18:	e422                	sd	s0,8(sp)
    80000f1a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f1c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f20:	0000e797          	auipc	a5,0xe
    80000f24:	9187b783          	ld	a5,-1768(a5) # 8000e838 <kernel_pagetable>
    80000f28:	83b1                	srli	a5,a5,0xc
    80000f2a:	577d                	li	a4,-1
    80000f2c:	177e                	slli	a4,a4,0x3f
    80000f2e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f30:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f34:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f38:	6422                	ld	s0,8(sp)
    80000f3a:	0141                	addi	sp,sp,16
    80000f3c:	8082                	ret

0000000080000f3e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f3e:	7139                	addi	sp,sp,-64
    80000f40:	fc06                	sd	ra,56(sp)
    80000f42:	f822                	sd	s0,48(sp)
    80000f44:	f426                	sd	s1,40(sp)
    80000f46:	f04a                	sd	s2,32(sp)
    80000f48:	ec4e                	sd	s3,24(sp)
    80000f4a:	e852                	sd	s4,16(sp)
    80000f4c:	e456                	sd	s5,8(sp)
    80000f4e:	e05a                	sd	s6,0(sp)
    80000f50:	0080                	addi	s0,sp,64
    80000f52:	84aa                	mv	s1,a0
    80000f54:	89ae                	mv	s3,a1
    80000f56:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f58:	57fd                	li	a5,-1
    80000f5a:	83e9                	srli	a5,a5,0x1a
    80000f5c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f5e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f60:	02b7fc63          	bgeu	a5,a1,80000f98 <walk+0x5a>
    panic("walk");
    80000f64:	00009517          	auipc	a0,0x9
    80000f68:	18c50513          	addi	a0,a0,396 # 8000a0f0 <etext+0xf0>
    80000f6c:	875ff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f70:	060a8263          	beqz	s5,80000fd4 <walk+0x96>
    80000f74:	b8bff0ef          	jal	80000afe <kalloc>
    80000f78:	84aa                	mv	s1,a0
    80000f7a:	c139                	beqz	a0,80000fc0 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f7c:	6605                	lui	a2,0x1
    80000f7e:	4581                	li	a1,0
    80000f80:	d23ff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f84:	00c4d793          	srli	a5,s1,0xc
    80000f88:	07aa                	slli	a5,a5,0xa
    80000f8a:	0017e793          	ori	a5,a5,1
    80000f8e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f92:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffcffdf>
    80000f94:	036a0063          	beq	s4,s6,80000fb4 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f98:	0149d933          	srl	s2,s3,s4
    80000f9c:	1ff97913          	andi	s2,s2,511
    80000fa0:	090e                	slli	s2,s2,0x3
    80000fa2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fa4:	00093483          	ld	s1,0(s2)
    80000fa8:	0014f793          	andi	a5,s1,1
    80000fac:	d3f1                	beqz	a5,80000f70 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fae:	80a9                	srli	s1,s1,0xa
    80000fb0:	04b2                	slli	s1,s1,0xc
    80000fb2:	b7c5                	j	80000f92 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000fb4:	00c9d513          	srli	a0,s3,0xc
    80000fb8:	1ff57513          	andi	a0,a0,511
    80000fbc:	050e                	slli	a0,a0,0x3
    80000fbe:	9526                	add	a0,a0,s1
}
    80000fc0:	70e2                	ld	ra,56(sp)
    80000fc2:	7442                	ld	s0,48(sp)
    80000fc4:	74a2                	ld	s1,40(sp)
    80000fc6:	7902                	ld	s2,32(sp)
    80000fc8:	69e2                	ld	s3,24(sp)
    80000fca:	6a42                	ld	s4,16(sp)
    80000fcc:	6aa2                	ld	s5,8(sp)
    80000fce:	6b02                	ld	s6,0(sp)
    80000fd0:	6121                	addi	sp,sp,64
    80000fd2:	8082                	ret
        return 0;
    80000fd4:	4501                	li	a0,0
    80000fd6:	b7ed                	j	80000fc0 <walk+0x82>

0000000080000fd8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	00b7f463          	bgeu	a5,a1,80000fe4 <walkaddr+0xc>
    return 0;
    80000fe0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fe2:	8082                	ret
{
    80000fe4:	1141                	addi	sp,sp,-16
    80000fe6:	e406                	sd	ra,8(sp)
    80000fe8:	e022                	sd	s0,0(sp)
    80000fea:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fec:	4601                	li	a2,0
    80000fee:	f51ff0ef          	jal	80000f3e <walk>
  if(pte == 0)
    80000ff2:	c105                	beqz	a0,80001012 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000ff4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000ff6:	0117f693          	andi	a3,a5,17
    80000ffa:	4745                	li	a4,17
    return 0;
    80000ffc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000ffe:	00e68663          	beq	a3,a4,8000100a <walkaddr+0x32>
}
    80001002:	60a2                	ld	ra,8(sp)
    80001004:	6402                	ld	s0,0(sp)
    80001006:	0141                	addi	sp,sp,16
    80001008:	8082                	ret
  pa = PTE2PA(*pte);
    8000100a:	83a9                	srli	a5,a5,0xa
    8000100c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001010:	bfcd                	j	80001002 <walkaddr+0x2a>
    return 0;
    80001012:	4501                	li	a0,0
    80001014:	b7fd                	j	80001002 <walkaddr+0x2a>

0000000080001016 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001016:	715d                	addi	sp,sp,-80
    80001018:	e486                	sd	ra,72(sp)
    8000101a:	e0a2                	sd	s0,64(sp)
    8000101c:	fc26                	sd	s1,56(sp)
    8000101e:	f84a                	sd	s2,48(sp)
    80001020:	f44e                	sd	s3,40(sp)
    80001022:	f052                	sd	s4,32(sp)
    80001024:	ec56                	sd	s5,24(sp)
    80001026:	e85a                	sd	s6,16(sp)
    80001028:	e45e                	sd	s7,8(sp)
    8000102a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000102c:	03459793          	slli	a5,a1,0x34
    80001030:	e7a9                	bnez	a5,8000107a <mappages+0x64>
    80001032:	8aaa                	mv	s5,a0
    80001034:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001036:	03461793          	slli	a5,a2,0x34
    8000103a:	e7b1                	bnez	a5,80001086 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    8000103c:	ca39                	beqz	a2,80001092 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    8000103e:	77fd                	lui	a5,0xfffff
    80001040:	963e                	add	a2,a2,a5
    80001042:	00b609b3          	add	s3,a2,a1
  a = va;
    80001046:	892e                	mv	s2,a1
    80001048:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000104c:	6b85                	lui	s7,0x1
    8000104e:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001052:	4605                	li	a2,1
    80001054:	85ca                	mv	a1,s2
    80001056:	8556                	mv	a0,s5
    80001058:	ee7ff0ef          	jal	80000f3e <walk>
    8000105c:	c539                	beqz	a0,800010aa <mappages+0x94>
    if(*pte & PTE_V)
    8000105e:	611c                	ld	a5,0(a0)
    80001060:	8b85                	andi	a5,a5,1
    80001062:	ef95                	bnez	a5,8000109e <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001064:	80b1                	srli	s1,s1,0xc
    80001066:	04aa                	slli	s1,s1,0xa
    80001068:	0164e4b3          	or	s1,s1,s6
    8000106c:	0014e493          	ori	s1,s1,1
    80001070:	e104                	sd	s1,0(a0)
    if(a == last)
    80001072:	05390863          	beq	s2,s3,800010c2 <mappages+0xac>
    a += PGSIZE;
    80001076:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001078:	bfd9                	j	8000104e <mappages+0x38>
    panic("mappages: va not aligned");
    8000107a:	00009517          	auipc	a0,0x9
    8000107e:	07e50513          	addi	a0,a0,126 # 8000a0f8 <etext+0xf8>
    80001082:	f5eff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    80001086:	00009517          	auipc	a0,0x9
    8000108a:	09250513          	addi	a0,a0,146 # 8000a118 <etext+0x118>
    8000108e:	f52ff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    80001092:	00009517          	auipc	a0,0x9
    80001096:	0a650513          	addi	a0,a0,166 # 8000a138 <etext+0x138>
    8000109a:	f46ff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    8000109e:	00009517          	auipc	a0,0x9
    800010a2:	0aa50513          	addi	a0,a0,170 # 8000a148 <etext+0x148>
    800010a6:	f3aff0ef          	jal	800007e0 <panic>
      return -1;
    800010aa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010ac:	60a6                	ld	ra,72(sp)
    800010ae:	6406                	ld	s0,64(sp)
    800010b0:	74e2                	ld	s1,56(sp)
    800010b2:	7942                	ld	s2,48(sp)
    800010b4:	79a2                	ld	s3,40(sp)
    800010b6:	7a02                	ld	s4,32(sp)
    800010b8:	6ae2                	ld	s5,24(sp)
    800010ba:	6b42                	ld	s6,16(sp)
    800010bc:	6ba2                	ld	s7,8(sp)
    800010be:	6161                	addi	sp,sp,80
    800010c0:	8082                	ret
  return 0;
    800010c2:	4501                	li	a0,0
    800010c4:	b7e5                	j	800010ac <mappages+0x96>

00000000800010c6 <kvmmap>:
{
    800010c6:	1141                	addi	sp,sp,-16
    800010c8:	e406                	sd	ra,8(sp)
    800010ca:	e022                	sd	s0,0(sp)
    800010cc:	0800                	addi	s0,sp,16
    800010ce:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010d0:	86b2                	mv	a3,a2
    800010d2:	863e                	mv	a2,a5
    800010d4:	f43ff0ef          	jal	80001016 <mappages>
    800010d8:	e509                	bnez	a0,800010e2 <kvmmap+0x1c>
}
    800010da:	60a2                	ld	ra,8(sp)
    800010dc:	6402                	ld	s0,0(sp)
    800010de:	0141                	addi	sp,sp,16
    800010e0:	8082                	ret
    panic("kvmmap");
    800010e2:	00009517          	auipc	a0,0x9
    800010e6:	07650513          	addi	a0,a0,118 # 8000a158 <etext+0x158>
    800010ea:	ef6ff0ef          	jal	800007e0 <panic>

00000000800010ee <kvmmake>:
{
    800010ee:	1101                	addi	sp,sp,-32
    800010f0:	ec06                	sd	ra,24(sp)
    800010f2:	e822                	sd	s0,16(sp)
    800010f4:	e426                	sd	s1,8(sp)
    800010f6:	e04a                	sd	s2,0(sp)
    800010f8:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010fa:	a05ff0ef          	jal	80000afe <kalloc>
    800010fe:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001100:	6605                	lui	a2,0x1
    80001102:	4581                	li	a1,0
    80001104:	b9fff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001108:	4719                	li	a4,6
    8000110a:	6685                	lui	a3,0x1
    8000110c:	10000637          	lui	a2,0x10000
    80001110:	100005b7          	lui	a1,0x10000
    80001114:	8526                	mv	a0,s1
    80001116:	fb1ff0ef          	jal	800010c6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE * 8, PTE_R | PTE_W);
    8000111a:	4719                	li	a4,6
    8000111c:	66a1                	lui	a3,0x8
    8000111e:	10001637          	lui	a2,0x10001
    80001122:	100015b7          	lui	a1,0x10001
    80001126:	8526                	mv	a0,s1
    80001128:	f9fff0ef          	jal	800010c6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    8000112c:	4719                	li	a4,6
    8000112e:	040006b7          	lui	a3,0x4000
    80001132:	0c000637          	lui	a2,0xc000
    80001136:	0c0005b7          	lui	a1,0xc000
    8000113a:	8526                	mv	a0,s1
    8000113c:	f8bff0ef          	jal	800010c6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001140:	00009917          	auipc	s2,0x9
    80001144:	ec090913          	addi	s2,s2,-320 # 8000a000 <etext>
    80001148:	4729                	li	a4,10
    8000114a:	80009697          	auipc	a3,0x80009
    8000114e:	eb668693          	addi	a3,a3,-330 # a000 <_entry-0x7fff6000>
    80001152:	4605                	li	a2,1
    80001154:	067e                	slli	a2,a2,0x1f
    80001156:	85b2                	mv	a1,a2
    80001158:	8526                	mv	a0,s1
    8000115a:	f6dff0ef          	jal	800010c6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000115e:	46c5                	li	a3,17
    80001160:	06ee                	slli	a3,a3,0x1b
    80001162:	4719                	li	a4,6
    80001164:	412686b3          	sub	a3,a3,s2
    80001168:	864a                	mv	a2,s2
    8000116a:	85ca                	mv	a1,s2
    8000116c:	8526                	mv	a0,s1
    8000116e:	f59ff0ef          	jal	800010c6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001172:	4729                	li	a4,10
    80001174:	6685                	lui	a3,0x1
    80001176:	00008617          	auipc	a2,0x8
    8000117a:	e8a60613          	addi	a2,a2,-374 # 80009000 <_trampoline>
    8000117e:	040005b7          	lui	a1,0x4000
    80001182:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001184:	05b2                	slli	a1,a1,0xc
    80001186:	8526                	mv	a0,s1
    80001188:	f3fff0ef          	jal	800010c6 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000118c:	8526                	mv	a0,s1
    8000118e:	5ee000ef          	jal	8000177c <proc_mapstacks>
}
    80001192:	8526                	mv	a0,s1
    80001194:	60e2                	ld	ra,24(sp)
    80001196:	6442                	ld	s0,16(sp)
    80001198:	64a2                	ld	s1,8(sp)
    8000119a:	6902                	ld	s2,0(sp)
    8000119c:	6105                	addi	sp,sp,32
    8000119e:	8082                	ret

00000000800011a0 <kvminit>:
{
    800011a0:	1141                	addi	sp,sp,-16
    800011a2:	e406                	sd	ra,8(sp)
    800011a4:	e022                	sd	s0,0(sp)
    800011a6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011a8:	f47ff0ef          	jal	800010ee <kvmmake>
    800011ac:	0000d797          	auipc	a5,0xd
    800011b0:	68a7b623          	sd	a0,1676(a5) # 8000e838 <kernel_pagetable>
}
    800011b4:	60a2                	ld	ra,8(sp)
    800011b6:	6402                	ld	s0,0(sp)
    800011b8:	0141                	addi	sp,sp,16
    800011ba:	8082                	ret

00000000800011bc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011bc:	1101                	addi	sp,sp,-32
    800011be:	ec06                	sd	ra,24(sp)
    800011c0:	e822                	sd	s0,16(sp)
    800011c2:	e426                	sd	s1,8(sp)
    800011c4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011c6:	939ff0ef          	jal	80000afe <kalloc>
    800011ca:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011cc:	c509                	beqz	a0,800011d6 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011ce:	6605                	lui	a2,0x1
    800011d0:	4581                	li	a1,0
    800011d2:	ad1ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011d6:	8526                	mv	a0,s1
    800011d8:	60e2                	ld	ra,24(sp)
    800011da:	6442                	ld	s0,16(sp)
    800011dc:	64a2                	ld	s1,8(sp)
    800011de:	6105                	addi	sp,sp,32
    800011e0:	8082                	ret

00000000800011e2 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011e2:	7139                	addi	sp,sp,-64
    800011e4:	fc06                	sd	ra,56(sp)
    800011e6:	f822                	sd	s0,48(sp)
    800011e8:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011ea:	03459793          	slli	a5,a1,0x34
    800011ee:	e38d                	bnez	a5,80001210 <uvmunmap+0x2e>
    800011f0:	f04a                	sd	s2,32(sp)
    800011f2:	ec4e                	sd	s3,24(sp)
    800011f4:	e852                	sd	s4,16(sp)
    800011f6:	e456                	sd	s5,8(sp)
    800011f8:	e05a                	sd	s6,0(sp)
    800011fa:	8a2a                	mv	s4,a0
    800011fc:	892e                	mv	s2,a1
    800011fe:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001200:	0632                	slli	a2,a2,0xc
    80001202:	00b609b3          	add	s3,a2,a1
    80001206:	6b05                	lui	s6,0x1
    80001208:	0535f963          	bgeu	a1,s3,8000125a <uvmunmap+0x78>
    8000120c:	f426                	sd	s1,40(sp)
    8000120e:	a015                	j	80001232 <uvmunmap+0x50>
    80001210:	f426                	sd	s1,40(sp)
    80001212:	f04a                	sd	s2,32(sp)
    80001214:	ec4e                	sd	s3,24(sp)
    80001216:	e852                	sd	s4,16(sp)
    80001218:	e456                	sd	s5,8(sp)
    8000121a:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    8000121c:	00009517          	auipc	a0,0x9
    80001220:	f4450513          	addi	a0,a0,-188 # 8000a160 <etext+0x160>
    80001224:	dbcff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001228:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000122c:	995a                	add	s2,s2,s6
    8000122e:	03397563          	bgeu	s2,s3,80001258 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001232:	4601                	li	a2,0
    80001234:	85ca                	mv	a1,s2
    80001236:	8552                	mv	a0,s4
    80001238:	d07ff0ef          	jal	80000f3e <walk>
    8000123c:	84aa                	mv	s1,a0
    8000123e:	d57d                	beqz	a0,8000122c <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001240:	611c                	ld	a5,0(a0)
    80001242:	0017f713          	andi	a4,a5,1
    80001246:	d37d                	beqz	a4,8000122c <uvmunmap+0x4a>
    if(do_free){
    80001248:	fe0a80e3          	beqz	s5,80001228 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000124c:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000124e:	00c79513          	slli	a0,a5,0xc
    80001252:	fcaff0ef          	jal	80000a1c <kfree>
    80001256:	bfc9                	j	80001228 <uvmunmap+0x46>
    80001258:	74a2                	ld	s1,40(sp)
    8000125a:	7902                	ld	s2,32(sp)
    8000125c:	69e2                	ld	s3,24(sp)
    8000125e:	6a42                	ld	s4,16(sp)
    80001260:	6aa2                	ld	s5,8(sp)
    80001262:	6b02                	ld	s6,0(sp)
  }
}
    80001264:	70e2                	ld	ra,56(sp)
    80001266:	7442                	ld	s0,48(sp)
    80001268:	6121                	addi	sp,sp,64
    8000126a:	8082                	ret

000000008000126c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000126c:	1101                	addi	sp,sp,-32
    8000126e:	ec06                	sd	ra,24(sp)
    80001270:	e822                	sd	s0,16(sp)
    80001272:	e426                	sd	s1,8(sp)
    80001274:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001276:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001278:	00b67d63          	bgeu	a2,a1,80001292 <uvmdealloc+0x26>
    8000127c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000127e:	6785                	lui	a5,0x1
    80001280:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001282:	00f60733          	add	a4,a2,a5
    80001286:	76fd                	lui	a3,0xfffff
    80001288:	8f75                	and	a4,a4,a3
    8000128a:	97ae                	add	a5,a5,a1
    8000128c:	8ff5                	and	a5,a5,a3
    8000128e:	00f76863          	bltu	a4,a5,8000129e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001292:	8526                	mv	a0,s1
    80001294:	60e2                	ld	ra,24(sp)
    80001296:	6442                	ld	s0,16(sp)
    80001298:	64a2                	ld	s1,8(sp)
    8000129a:	6105                	addi	sp,sp,32
    8000129c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000129e:	8f99                	sub	a5,a5,a4
    800012a0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012a2:	4685                	li	a3,1
    800012a4:	0007861b          	sext.w	a2,a5
    800012a8:	85ba                	mv	a1,a4
    800012aa:	f39ff0ef          	jal	800011e2 <uvmunmap>
    800012ae:	b7d5                	j	80001292 <uvmdealloc+0x26>

00000000800012b0 <uvmalloc>:
  if(newsz < oldsz)
    800012b0:	08b66f63          	bltu	a2,a1,8000134e <uvmalloc+0x9e>
{
    800012b4:	7139                	addi	sp,sp,-64
    800012b6:	fc06                	sd	ra,56(sp)
    800012b8:	f822                	sd	s0,48(sp)
    800012ba:	ec4e                	sd	s3,24(sp)
    800012bc:	e852                	sd	s4,16(sp)
    800012be:	e456                	sd	s5,8(sp)
    800012c0:	0080                	addi	s0,sp,64
    800012c2:	8aaa                	mv	s5,a0
    800012c4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800012c6:	6785                	lui	a5,0x1
    800012c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012ca:	95be                	add	a1,a1,a5
    800012cc:	77fd                	lui	a5,0xfffff
    800012ce:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012d2:	08c9f063          	bgeu	s3,a2,80001352 <uvmalloc+0xa2>
    800012d6:	f426                	sd	s1,40(sp)
    800012d8:	f04a                	sd	s2,32(sp)
    800012da:	e05a                	sd	s6,0(sp)
    800012dc:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012de:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012e2:	81dff0ef          	jal	80000afe <kalloc>
    800012e6:	84aa                	mv	s1,a0
    if(mem == 0){
    800012e8:	c515                	beqz	a0,80001314 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012ea:	6605                	lui	a2,0x1
    800012ec:	4581                	li	a1,0
    800012ee:	9b5ff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012f2:	875a                	mv	a4,s6
    800012f4:	86a6                	mv	a3,s1
    800012f6:	6605                	lui	a2,0x1
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8556                	mv	a0,s5
    800012fc:	d1bff0ef          	jal	80001016 <mappages>
    80001300:	e915                	bnez	a0,80001334 <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001302:	6785                	lui	a5,0x1
    80001304:	993e                	add	s2,s2,a5
    80001306:	fd496ee3          	bltu	s2,s4,800012e2 <uvmalloc+0x32>
  return newsz;
    8000130a:	8552                	mv	a0,s4
    8000130c:	74a2                	ld	s1,40(sp)
    8000130e:	7902                	ld	s2,32(sp)
    80001310:	6b02                	ld	s6,0(sp)
    80001312:	a811                	j	80001326 <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    80001314:	864e                	mv	a2,s3
    80001316:	85ca                	mv	a1,s2
    80001318:	8556                	mv	a0,s5
    8000131a:	f53ff0ef          	jal	8000126c <uvmdealloc>
      return 0;
    8000131e:	4501                	li	a0,0
    80001320:	74a2                	ld	s1,40(sp)
    80001322:	7902                	ld	s2,32(sp)
    80001324:	6b02                	ld	s6,0(sp)
}
    80001326:	70e2                	ld	ra,56(sp)
    80001328:	7442                	ld	s0,48(sp)
    8000132a:	69e2                	ld	s3,24(sp)
    8000132c:	6a42                	ld	s4,16(sp)
    8000132e:	6aa2                	ld	s5,8(sp)
    80001330:	6121                	addi	sp,sp,64
    80001332:	8082                	ret
      kfree(mem);
    80001334:	8526                	mv	a0,s1
    80001336:	ee6ff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000133a:	864e                	mv	a2,s3
    8000133c:	85ca                	mv	a1,s2
    8000133e:	8556                	mv	a0,s5
    80001340:	f2dff0ef          	jal	8000126c <uvmdealloc>
      return 0;
    80001344:	4501                	li	a0,0
    80001346:	74a2                	ld	s1,40(sp)
    80001348:	7902                	ld	s2,32(sp)
    8000134a:	6b02                	ld	s6,0(sp)
    8000134c:	bfe9                	j	80001326 <uvmalloc+0x76>
    return oldsz;
    8000134e:	852e                	mv	a0,a1
}
    80001350:	8082                	ret
  return newsz;
    80001352:	8532                	mv	a0,a2
    80001354:	bfc9                	j	80001326 <uvmalloc+0x76>

0000000080001356 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
    80001366:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001368:	84aa                	mv	s1,a0
    8000136a:	6905                	lui	s2,0x1
    8000136c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000136e:	4985                	li	s3,1
    80001370:	a819                	j	80001386 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001372:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001374:	00c79513          	slli	a0,a5,0xc
    80001378:	fdfff0ef          	jal	80001356 <freewalk>
      pagetable[i] = 0;
    8000137c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001380:	04a1                	addi	s1,s1,8
    80001382:	01248f63          	beq	s1,s2,800013a0 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    80001386:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001388:	00f7f713          	andi	a4,a5,15
    8000138c:	ff3703e3          	beq	a4,s3,80001372 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001390:	8b85                	andi	a5,a5,1
    80001392:	d7fd                	beqz	a5,80001380 <freewalk+0x2a>
      panic("freewalk: leaf");
    80001394:	00009517          	auipc	a0,0x9
    80001398:	de450513          	addi	a0,a0,-540 # 8000a178 <etext+0x178>
    8000139c:	c44ff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    800013a0:	8552                	mv	a0,s4
    800013a2:	e7aff0ef          	jal	80000a1c <kfree>
}
    800013a6:	70a2                	ld	ra,40(sp)
    800013a8:	7402                	ld	s0,32(sp)
    800013aa:	64e2                	ld	s1,24(sp)
    800013ac:	6942                	ld	s2,16(sp)
    800013ae:	69a2                	ld	s3,8(sp)
    800013b0:	6a02                	ld	s4,0(sp)
    800013b2:	6145                	addi	sp,sp,48
    800013b4:	8082                	ret

00000000800013b6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013b6:	1101                	addi	sp,sp,-32
    800013b8:	ec06                	sd	ra,24(sp)
    800013ba:	e822                	sd	s0,16(sp)
    800013bc:	e426                	sd	s1,8(sp)
    800013be:	1000                	addi	s0,sp,32
    800013c0:	84aa                	mv	s1,a0
  if(sz > 0)
    800013c2:	e989                	bnez	a1,800013d4 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013c4:	8526                	mv	a0,s1
    800013c6:	f91ff0ef          	jal	80001356 <freewalk>
}
    800013ca:	60e2                	ld	ra,24(sp)
    800013cc:	6442                	ld	s0,16(sp)
    800013ce:	64a2                	ld	s1,8(sp)
    800013d0:	6105                	addi	sp,sp,32
    800013d2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	95be                	add	a1,a1,a5
    800013da:	4685                	li	a3,1
    800013dc:	00c5d613          	srli	a2,a1,0xc
    800013e0:	4581                	li	a1,0
    800013e2:	e01ff0ef          	jal	800011e2 <uvmunmap>
    800013e6:	bff9                	j	800013c4 <uvmfree+0xe>

00000000800013e8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013e8:	ce49                	beqz	a2,80001482 <uvmcopy+0x9a>
{
    800013ea:	715d                	addi	sp,sp,-80
    800013ec:	e486                	sd	ra,72(sp)
    800013ee:	e0a2                	sd	s0,64(sp)
    800013f0:	fc26                	sd	s1,56(sp)
    800013f2:	f84a                	sd	s2,48(sp)
    800013f4:	f44e                	sd	s3,40(sp)
    800013f6:	f052                	sd	s4,32(sp)
    800013f8:	ec56                	sd	s5,24(sp)
    800013fa:	e85a                	sd	s6,16(sp)
    800013fc:	e45e                	sd	s7,8(sp)
    800013fe:	0880                	addi	s0,sp,80
    80001400:	8aaa                	mv	s5,a0
    80001402:	8b2e                	mv	s6,a1
    80001404:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001406:	4481                	li	s1,0
    80001408:	a029                	j	80001412 <uvmcopy+0x2a>
    8000140a:	6785                	lui	a5,0x1
    8000140c:	94be                	add	s1,s1,a5
    8000140e:	0544fe63          	bgeu	s1,s4,8000146a <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001412:	4601                	li	a2,0
    80001414:	85a6                	mv	a1,s1
    80001416:	8556                	mv	a0,s5
    80001418:	b27ff0ef          	jal	80000f3e <walk>
    8000141c:	d57d                	beqz	a0,8000140a <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    8000141e:	6118                	ld	a4,0(a0)
    80001420:	00177793          	andi	a5,a4,1
    80001424:	d3fd                	beqz	a5,8000140a <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001426:	00a75593          	srli	a1,a4,0xa
    8000142a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000142e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001432:	eccff0ef          	jal	80000afe <kalloc>
    80001436:	89aa                	mv	s3,a0
    80001438:	c105                	beqz	a0,80001458 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000143a:	6605                	lui	a2,0x1
    8000143c:	85de                	mv	a1,s7
    8000143e:	8c1ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001442:	874a                	mv	a4,s2
    80001444:	86ce                	mv	a3,s3
    80001446:	6605                	lui	a2,0x1
    80001448:	85a6                	mv	a1,s1
    8000144a:	855a                	mv	a0,s6
    8000144c:	bcbff0ef          	jal	80001016 <mappages>
    80001450:	dd4d                	beqz	a0,8000140a <uvmcopy+0x22>
      kfree(mem);
    80001452:	854e                	mv	a0,s3
    80001454:	dc8ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001458:	4685                	li	a3,1
    8000145a:	00c4d613          	srli	a2,s1,0xc
    8000145e:	4581                	li	a1,0
    80001460:	855a                	mv	a0,s6
    80001462:	d81ff0ef          	jal	800011e2 <uvmunmap>
  return -1;
    80001466:	557d                	li	a0,-1
    80001468:	a011                	j	8000146c <uvmcopy+0x84>
  return 0;
    8000146a:	4501                	li	a0,0
}
    8000146c:	60a6                	ld	ra,72(sp)
    8000146e:	6406                	ld	s0,64(sp)
    80001470:	74e2                	ld	s1,56(sp)
    80001472:	7942                	ld	s2,48(sp)
    80001474:	79a2                	ld	s3,40(sp)
    80001476:	7a02                	ld	s4,32(sp)
    80001478:	6ae2                	ld	s5,24(sp)
    8000147a:	6b42                	ld	s6,16(sp)
    8000147c:	6ba2                	ld	s7,8(sp)
    8000147e:	6161                	addi	sp,sp,80
    80001480:	8082                	ret
  return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	8082                	ret

0000000080001486 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001486:	1141                	addi	sp,sp,-16
    80001488:	e406                	sd	ra,8(sp)
    8000148a:	e022                	sd	s0,0(sp)
    8000148c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000148e:	4601                	li	a2,0
    80001490:	aafff0ef          	jal	80000f3e <walk>
  if(pte == 0)
    80001494:	c901                	beqz	a0,800014a4 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001496:	611c                	ld	a5,0(a0)
    80001498:	9bbd                	andi	a5,a5,-17
    8000149a:	e11c                	sd	a5,0(a0)
}
    8000149c:	60a2                	ld	ra,8(sp)
    8000149e:	6402                	ld	s0,0(sp)
    800014a0:	0141                	addi	sp,sp,16
    800014a2:	8082                	ret
    panic("uvmclear");
    800014a4:	00009517          	auipc	a0,0x9
    800014a8:	ce450513          	addi	a0,a0,-796 # 8000a188 <etext+0x188>
    800014ac:	b34ff0ef          	jal	800007e0 <panic>

00000000800014b0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014b0:	c6dd                	beqz	a3,8000155e <copyinstr+0xae>
{
    800014b2:	715d                	addi	sp,sp,-80
    800014b4:	e486                	sd	ra,72(sp)
    800014b6:	e0a2                	sd	s0,64(sp)
    800014b8:	fc26                	sd	s1,56(sp)
    800014ba:	f84a                	sd	s2,48(sp)
    800014bc:	f44e                	sd	s3,40(sp)
    800014be:	f052                	sd	s4,32(sp)
    800014c0:	ec56                	sd	s5,24(sp)
    800014c2:	e85a                	sd	s6,16(sp)
    800014c4:	e45e                	sd	s7,8(sp)
    800014c6:	0880                	addi	s0,sp,80
    800014c8:	8a2a                	mv	s4,a0
    800014ca:	8b2e                	mv	s6,a1
    800014cc:	8bb2                	mv	s7,a2
    800014ce:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014d0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014d2:	6985                	lui	s3,0x1
    800014d4:	a825                	j	8000150c <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014d6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014da:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014dc:	37fd                	addiw	a5,a5,-1
    800014de:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014e2:	60a6                	ld	ra,72(sp)
    800014e4:	6406                	ld	s0,64(sp)
    800014e6:	74e2                	ld	s1,56(sp)
    800014e8:	7942                	ld	s2,48(sp)
    800014ea:	79a2                	ld	s3,40(sp)
    800014ec:	7a02                	ld	s4,32(sp)
    800014ee:	6ae2                	ld	s5,24(sp)
    800014f0:	6b42                	ld	s6,16(sp)
    800014f2:	6ba2                	ld	s7,8(sp)
    800014f4:	6161                	addi	sp,sp,80
    800014f6:	8082                	ret
    800014f8:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014fc:	9742                	add	a4,a4,a6
      --max;
    800014fe:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    80001502:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001506:	04e58463          	beq	a1,a4,8000154e <copyinstr+0x9e>
{
    8000150a:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    8000150c:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001510:	85a6                	mv	a1,s1
    80001512:	8552                	mv	a0,s4
    80001514:	ac5ff0ef          	jal	80000fd8 <walkaddr>
    if(pa0 == 0)
    80001518:	cd0d                	beqz	a0,80001552 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000151a:	417486b3          	sub	a3,s1,s7
    8000151e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001520:	00d97363          	bgeu	s2,a3,80001526 <copyinstr+0x76>
    80001524:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001526:	955e                	add	a0,a0,s7
    80001528:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000152a:	c695                	beqz	a3,80001556 <copyinstr+0xa6>
    8000152c:	87da                	mv	a5,s6
    8000152e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001530:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001534:	96da                	add	a3,a3,s6
    80001536:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001538:	00f60733          	add	a4,a2,a5
    8000153c:	00074703          	lbu	a4,0(a4)
    80001540:	db59                	beqz	a4,800014d6 <copyinstr+0x26>
        *dst = *p;
    80001542:	00e78023          	sb	a4,0(a5)
      dst++;
    80001546:	0785                	addi	a5,a5,1
    while(n > 0){
    80001548:	fed797e3          	bne	a5,a3,80001536 <copyinstr+0x86>
    8000154c:	b775                	j	800014f8 <copyinstr+0x48>
    8000154e:	4781                	li	a5,0
    80001550:	b771                	j	800014dc <copyinstr+0x2c>
      return -1;
    80001552:	557d                	li	a0,-1
    80001554:	b779                	j	800014e2 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001556:	6b85                	lui	s7,0x1
    80001558:	9ba6                	add	s7,s7,s1
    8000155a:	87da                	mv	a5,s6
    8000155c:	b77d                	j	8000150a <copyinstr+0x5a>
  int got_null = 0;
    8000155e:	4781                	li	a5,0
  if(got_null){
    80001560:	37fd                	addiw	a5,a5,-1
    80001562:	0007851b          	sext.w	a0,a5
}
    80001566:	8082                	ret

0000000080001568 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001568:	1141                	addi	sp,sp,-16
    8000156a:	e406                	sd	ra,8(sp)
    8000156c:	e022                	sd	s0,0(sp)
    8000156e:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001570:	4601                	li	a2,0
    80001572:	9cdff0ef          	jal	80000f3e <walk>
  if (pte == 0) {
    80001576:	c519                	beqz	a0,80001584 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001578:	6108                	ld	a0,0(a0)
    8000157a:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000157c:	60a2                	ld	ra,8(sp)
    8000157e:	6402                	ld	s0,0(sp)
    80001580:	0141                	addi	sp,sp,16
    80001582:	8082                	ret
    return 0;
    80001584:	4501                	li	a0,0
    80001586:	bfdd                	j	8000157c <ismapped+0x14>

0000000080001588 <vmfault>:
{
    80001588:	7179                	addi	sp,sp,-48
    8000158a:	f406                	sd	ra,40(sp)
    8000158c:	f022                	sd	s0,32(sp)
    8000158e:	ec26                	sd	s1,24(sp)
    80001590:	e44e                	sd	s3,8(sp)
    80001592:	1800                	addi	s0,sp,48
    80001594:	89aa                	mv	s3,a0
    80001596:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001598:	35e000ef          	jal	800018f6 <myproc>
  if (va >= p->sz)
    8000159c:	653c                	ld	a5,72(a0)
    8000159e:	00f4ea63          	bltu	s1,a5,800015b2 <vmfault+0x2a>
    return 0;
    800015a2:	4981                	li	s3,0
}
    800015a4:	854e                	mv	a0,s3
    800015a6:	70a2                	ld	ra,40(sp)
    800015a8:	7402                	ld	s0,32(sp)
    800015aa:	64e2                	ld	s1,24(sp)
    800015ac:	69a2                	ld	s3,8(sp)
    800015ae:	6145                	addi	sp,sp,48
    800015b0:	8082                	ret
    800015b2:	e84a                	sd	s2,16(sp)
    800015b4:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015b6:	77fd                	lui	a5,0xfffff
    800015b8:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015ba:	85a6                	mv	a1,s1
    800015bc:	854e                	mv	a0,s3
    800015be:	fabff0ef          	jal	80001568 <ismapped>
    return 0;
    800015c2:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015c4:	c119                	beqz	a0,800015ca <vmfault+0x42>
    800015c6:	6942                	ld	s2,16(sp)
    800015c8:	bff1                	j	800015a4 <vmfault+0x1c>
    800015ca:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015cc:	d32ff0ef          	jal	80000afe <kalloc>
    800015d0:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015d2:	c90d                	beqz	a0,80001604 <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015d4:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015d6:	6605                	lui	a2,0x1
    800015d8:	4581                	li	a1,0
    800015da:	ec8ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015de:	4759                	li	a4,22
    800015e0:	86d2                	mv	a3,s4
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85a6                	mv	a1,s1
    800015e6:	05093503          	ld	a0,80(s2)
    800015ea:	a2dff0ef          	jal	80001016 <mappages>
    800015ee:	e501                	bnez	a0,800015f6 <vmfault+0x6e>
    800015f0:	6942                	ld	s2,16(sp)
    800015f2:	6a02                	ld	s4,0(sp)
    800015f4:	bf45                	j	800015a4 <vmfault+0x1c>
    kfree((void *)mem);
    800015f6:	8552                	mv	a0,s4
    800015f8:	c24ff0ef          	jal	80000a1c <kfree>
    return 0;
    800015fc:	4981                	li	s3,0
    800015fe:	6942                	ld	s2,16(sp)
    80001600:	6a02                	ld	s4,0(sp)
    80001602:	b74d                	j	800015a4 <vmfault+0x1c>
    80001604:	6942                	ld	s2,16(sp)
    80001606:	6a02                	ld	s4,0(sp)
    80001608:	bf71                	j	800015a4 <vmfault+0x1c>

000000008000160a <copyout>:
  while(len > 0){
    8000160a:	c2cd                	beqz	a3,800016ac <copyout+0xa2>
{
    8000160c:	711d                	addi	sp,sp,-96
    8000160e:	ec86                	sd	ra,88(sp)
    80001610:	e8a2                	sd	s0,80(sp)
    80001612:	e4a6                	sd	s1,72(sp)
    80001614:	f852                	sd	s4,48(sp)
    80001616:	f05a                	sd	s6,32(sp)
    80001618:	ec5e                	sd	s7,24(sp)
    8000161a:	e862                	sd	s8,16(sp)
    8000161c:	1080                	addi	s0,sp,96
    8000161e:	8c2a                	mv	s8,a0
    80001620:	8b2e                	mv	s6,a1
    80001622:	8bb2                	mv	s7,a2
    80001624:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001626:	74fd                	lui	s1,0xfffff
    80001628:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    8000162a:	57fd                	li	a5,-1
    8000162c:	83e9                	srli	a5,a5,0x1a
    8000162e:	0897e163          	bltu	a5,s1,800016b0 <copyout+0xa6>
    80001632:	e0ca                	sd	s2,64(sp)
    80001634:	fc4e                	sd	s3,56(sp)
    80001636:	f456                	sd	s5,40(sp)
    80001638:	e466                	sd	s9,8(sp)
    8000163a:	e06a                	sd	s10,0(sp)
    8000163c:	6d05                	lui	s10,0x1
    8000163e:	8cbe                	mv	s9,a5
    80001640:	a015                	j	80001664 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001642:	409b0533          	sub	a0,s6,s1
    80001646:	0009861b          	sext.w	a2,s3
    8000164a:	85de                	mv	a1,s7
    8000164c:	954a                	add	a0,a0,s2
    8000164e:	eb0ff0ef          	jal	80000cfe <memmove>
    len -= n;
    80001652:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001656:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001658:	040a0363          	beqz	s4,8000169e <copyout+0x94>
    if(va0 >= MAXVA)
    8000165c:	055cec63          	bltu	s9,s5,800016b4 <copyout+0xaa>
    80001660:	84d6                	mv	s1,s5
    80001662:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80001664:	85a6                	mv	a1,s1
    80001666:	8562                	mv	a0,s8
    80001668:	971ff0ef          	jal	80000fd8 <walkaddr>
    8000166c:	892a                	mv	s2,a0
    if(pa0 == 0) {
    8000166e:	e901                	bnez	a0,8000167e <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001670:	4601                	li	a2,0
    80001672:	85a6                	mv	a1,s1
    80001674:	8562                	mv	a0,s8
    80001676:	f13ff0ef          	jal	80001588 <vmfault>
    8000167a:	892a                	mv	s2,a0
    8000167c:	c139                	beqz	a0,800016c2 <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    8000167e:	4601                	li	a2,0
    80001680:	85a6                	mv	a1,s1
    80001682:	8562                	mv	a0,s8
    80001684:	8bbff0ef          	jal	80000f3e <walk>
    if((*pte & PTE_W) == 0)
    80001688:	611c                	ld	a5,0(a0)
    8000168a:	8b91                	andi	a5,a5,4
    8000168c:	c3b1                	beqz	a5,800016d0 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    8000168e:	01a48ab3          	add	s5,s1,s10
    80001692:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    80001696:	fb3a76e3          	bgeu	s4,s3,80001642 <copyout+0x38>
    8000169a:	89d2                	mv	s3,s4
    8000169c:	b75d                	j	80001642 <copyout+0x38>
  return 0;
    8000169e:	4501                	li	a0,0
    800016a0:	6906                	ld	s2,64(sp)
    800016a2:	79e2                	ld	s3,56(sp)
    800016a4:	7aa2                	ld	s5,40(sp)
    800016a6:	6ca2                	ld	s9,8(sp)
    800016a8:	6d02                	ld	s10,0(sp)
    800016aa:	a80d                	j	800016dc <copyout+0xd2>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
    800016b2:	a02d                	j	800016dc <copyout+0xd2>
    800016b4:	557d                	li	a0,-1
    800016b6:	6906                	ld	s2,64(sp)
    800016b8:	79e2                	ld	s3,56(sp)
    800016ba:	7aa2                	ld	s5,40(sp)
    800016bc:	6ca2                	ld	s9,8(sp)
    800016be:	6d02                	ld	s10,0(sp)
    800016c0:	a831                	j	800016dc <copyout+0xd2>
        return -1;
    800016c2:	557d                	li	a0,-1
    800016c4:	6906                	ld	s2,64(sp)
    800016c6:	79e2                	ld	s3,56(sp)
    800016c8:	7aa2                	ld	s5,40(sp)
    800016ca:	6ca2                	ld	s9,8(sp)
    800016cc:	6d02                	ld	s10,0(sp)
    800016ce:	a039                	j	800016dc <copyout+0xd2>
      return -1;
    800016d0:	557d                	li	a0,-1
    800016d2:	6906                	ld	s2,64(sp)
    800016d4:	79e2                	ld	s3,56(sp)
    800016d6:	7aa2                	ld	s5,40(sp)
    800016d8:	6ca2                	ld	s9,8(sp)
    800016da:	6d02                	ld	s10,0(sp)
}
    800016dc:	60e6                	ld	ra,88(sp)
    800016de:	6446                	ld	s0,80(sp)
    800016e0:	64a6                	ld	s1,72(sp)
    800016e2:	7a42                	ld	s4,48(sp)
    800016e4:	7b02                	ld	s6,32(sp)
    800016e6:	6be2                	ld	s7,24(sp)
    800016e8:	6c42                	ld	s8,16(sp)
    800016ea:	6125                	addi	sp,sp,96
    800016ec:	8082                	ret

00000000800016ee <copyin>:
  while(len > 0){
    800016ee:	c6c9                	beqz	a3,80001778 <copyin+0x8a>
{
    800016f0:	715d                	addi	sp,sp,-80
    800016f2:	e486                	sd	ra,72(sp)
    800016f4:	e0a2                	sd	s0,64(sp)
    800016f6:	fc26                	sd	s1,56(sp)
    800016f8:	f84a                	sd	s2,48(sp)
    800016fa:	f44e                	sd	s3,40(sp)
    800016fc:	f052                	sd	s4,32(sp)
    800016fe:	ec56                	sd	s5,24(sp)
    80001700:	e85a                	sd	s6,16(sp)
    80001702:	e45e                	sd	s7,8(sp)
    80001704:	e062                	sd	s8,0(sp)
    80001706:	0880                	addi	s0,sp,80
    80001708:	8baa                	mv	s7,a0
    8000170a:	8aae                	mv	s5,a1
    8000170c:	8932                	mv	s2,a2
    8000170e:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001710:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001712:	6b05                	lui	s6,0x1
    80001714:	a035                	j	80001740 <copyin+0x52>
    80001716:	412984b3          	sub	s1,s3,s2
    8000171a:	94da                	add	s1,s1,s6
    if(n > len)
    8000171c:	009a7363          	bgeu	s4,s1,80001722 <copyin+0x34>
    80001720:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001722:	413905b3          	sub	a1,s2,s3
    80001726:	0004861b          	sext.w	a2,s1
    8000172a:	95aa                	add	a1,a1,a0
    8000172c:	8556                	mv	a0,s5
    8000172e:	dd0ff0ef          	jal	80000cfe <memmove>
    len -= n;
    80001732:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001736:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001738:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000173c:	020a0163          	beqz	s4,8000175e <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001740:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ce                	mv	a1,s3
    80001746:	855e                	mv	a0,s7
    80001748:	891ff0ef          	jal	80000fd8 <walkaddr>
    if(pa0 == 0) {
    8000174c:	f569                	bnez	a0,80001716 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000174e:	4601                	li	a2,0
    80001750:	85ce                	mv	a1,s3
    80001752:	855e                	mv	a0,s7
    80001754:	e35ff0ef          	jal	80001588 <vmfault>
    80001758:	fd5d                	bnez	a0,80001716 <copyin+0x28>
        return -1;
    8000175a:	557d                	li	a0,-1
    8000175c:	a011                	j	80001760 <copyin+0x72>
  return 0;
    8000175e:	4501                	li	a0,0
}
    80001760:	60a6                	ld	ra,72(sp)
    80001762:	6406                	ld	s0,64(sp)
    80001764:	74e2                	ld	s1,56(sp)
    80001766:	7942                	ld	s2,48(sp)
    80001768:	79a2                	ld	s3,40(sp)
    8000176a:	7a02                	ld	s4,32(sp)
    8000176c:	6ae2                	ld	s5,24(sp)
    8000176e:	6b42                	ld	s6,16(sp)
    80001770:	6ba2                	ld	s7,8(sp)
    80001772:	6c02                	ld	s8,0(sp)
    80001774:	6161                	addi	sp,sp,80
    80001776:	8082                	ret
  return 0;
    80001778:	4501                	li	a0,0
}
    8000177a:	8082                	ret

000000008000177c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000177c:	7139                	addi	sp,sp,-64
    8000177e:	fc06                	sd	ra,56(sp)
    80001780:	f822                	sd	s0,48(sp)
    80001782:	f426                	sd	s1,40(sp)
    80001784:	f04a                	sd	s2,32(sp)
    80001786:	ec4e                	sd	s3,24(sp)
    80001788:	e852                	sd	s4,16(sp)
    8000178a:	e456                	sd	s5,8(sp)
    8000178c:	e05a                	sd	s6,0(sp)
    8000178e:	0080                	addi	s0,sp,64
    80001790:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001792:	00015497          	auipc	s1,0x15
    80001796:	66648493          	addi	s1,s1,1638 # 80016df8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000179a:	8b26                	mv	s6,s1
    8000179c:	04fa5937          	lui	s2,0x4fa5
    800017a0:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    800017a4:	0932                	slli	s2,s2,0xc
    800017a6:	fa590913          	addi	s2,s2,-91
    800017aa:	0932                	slli	s2,s2,0xc
    800017ac:	fa590913          	addi	s2,s2,-91
    800017b0:	0932                	slli	s2,s2,0xc
    800017b2:	fa590913          	addi	s2,s2,-91
    800017b6:	040009b7          	lui	s3,0x4000
    800017ba:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800017bc:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017be:	0001ba97          	auipc	s5,0x1b
    800017c2:	03aa8a93          	addi	s5,s5,58 # 8001c7f8 <tickslock>
    char *pa = kalloc();
    800017c6:	b38ff0ef          	jal	80000afe <kalloc>
    800017ca:	862a                	mv	a2,a0
    if(pa == 0)
    800017cc:	cd15                	beqz	a0,80001808 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017ce:	416485b3          	sub	a1,s1,s6
    800017d2:	858d                	srai	a1,a1,0x3
    800017d4:	032585b3          	mul	a1,a1,s2
    800017d8:	2585                	addiw	a1,a1,1
    800017da:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017de:	4719                	li	a4,6
    800017e0:	6685                	lui	a3,0x1
    800017e2:	40b985b3          	sub	a1,s3,a1
    800017e6:	8552                	mv	a0,s4
    800017e8:	8dfff0ef          	jal	800010c6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017ec:	16848493          	addi	s1,s1,360
    800017f0:	fd549be3          	bne	s1,s5,800017c6 <proc_mapstacks+0x4a>
  }
}
    800017f4:	70e2                	ld	ra,56(sp)
    800017f6:	7442                	ld	s0,48(sp)
    800017f8:	74a2                	ld	s1,40(sp)
    800017fa:	7902                	ld	s2,32(sp)
    800017fc:	69e2                	ld	s3,24(sp)
    800017fe:	6a42                	ld	s4,16(sp)
    80001800:	6aa2                	ld	s5,8(sp)
    80001802:	6b02                	ld	s6,0(sp)
    80001804:	6121                	addi	sp,sp,64
    80001806:	8082                	ret
      panic("kalloc");
    80001808:	00009517          	auipc	a0,0x9
    8000180c:	99050513          	addi	a0,a0,-1648 # 8000a198 <etext+0x198>
    80001810:	fd1fe0ef          	jal	800007e0 <panic>

0000000080001814 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001814:	7139                	addi	sp,sp,-64
    80001816:	fc06                	sd	ra,56(sp)
    80001818:	f822                	sd	s0,48(sp)
    8000181a:	f426                	sd	s1,40(sp)
    8000181c:	f04a                	sd	s2,32(sp)
    8000181e:	ec4e                	sd	s3,24(sp)
    80001820:	e852                	sd	s4,16(sp)
    80001822:	e456                	sd	s5,8(sp)
    80001824:	e05a                	sd	s6,0(sp)
    80001826:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001828:	00009597          	auipc	a1,0x9
    8000182c:	97858593          	addi	a1,a1,-1672 # 8000a1a0 <etext+0x1a0>
    80001830:	00015517          	auipc	a0,0x15
    80001834:	19850513          	addi	a0,a0,408 # 800169c8 <pid_lock>
    80001838:	b16ff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    8000183c:	00009597          	auipc	a1,0x9
    80001840:	96c58593          	addi	a1,a1,-1684 # 8000a1a8 <etext+0x1a8>
    80001844:	00015517          	auipc	a0,0x15
    80001848:	19c50513          	addi	a0,a0,412 # 800169e0 <wait_lock>
    8000184c:	b02ff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001850:	00015497          	auipc	s1,0x15
    80001854:	5a848493          	addi	s1,s1,1448 # 80016df8 <proc>
      initlock(&p->lock, "proc");
    80001858:	00009b17          	auipc	s6,0x9
    8000185c:	960b0b13          	addi	s6,s6,-1696 # 8000a1b8 <etext+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001860:	8aa6                	mv	s5,s1
    80001862:	04fa5937          	lui	s2,0x4fa5
    80001866:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    8000186a:	0932                	slli	s2,s2,0xc
    8000186c:	fa590913          	addi	s2,s2,-91
    80001870:	0932                	slli	s2,s2,0xc
    80001872:	fa590913          	addi	s2,s2,-91
    80001876:	0932                	slli	s2,s2,0xc
    80001878:	fa590913          	addi	s2,s2,-91
    8000187c:	040009b7          	lui	s3,0x4000
    80001880:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001882:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001884:	0001ba17          	auipc	s4,0x1b
    80001888:	f74a0a13          	addi	s4,s4,-140 # 8001c7f8 <tickslock>
      initlock(&p->lock, "proc");
    8000188c:	85da                	mv	a1,s6
    8000188e:	8526                	mv	a0,s1
    80001890:	abeff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    80001894:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001898:	415487b3          	sub	a5,s1,s5
    8000189c:	878d                	srai	a5,a5,0x3
    8000189e:	032787b3          	mul	a5,a5,s2
    800018a2:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffcffe9>
    800018a4:	00d7979b          	slliw	a5,a5,0xd
    800018a8:	40f987b3          	sub	a5,s3,a5
    800018ac:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ae:	16848493          	addi	s1,s1,360
    800018b2:	fd449de3          	bne	s1,s4,8000188c <procinit+0x78>
  }
}
    800018b6:	70e2                	ld	ra,56(sp)
    800018b8:	7442                	ld	s0,48(sp)
    800018ba:	74a2                	ld	s1,40(sp)
    800018bc:	7902                	ld	s2,32(sp)
    800018be:	69e2                	ld	s3,24(sp)
    800018c0:	6a42                	ld	s4,16(sp)
    800018c2:	6aa2                	ld	s5,8(sp)
    800018c4:	6b02                	ld	s6,0(sp)
    800018c6:	6121                	addi	sp,sp,64
    800018c8:	8082                	ret

00000000800018ca <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018ca:	1141                	addi	sp,sp,-16
    800018cc:	e422                	sd	s0,8(sp)
    800018ce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018d0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018d2:	2501                	sext.w	a0,a0
    800018d4:	6422                	ld	s0,8(sp)
    800018d6:	0141                	addi	sp,sp,16
    800018d8:	8082                	ret

00000000800018da <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018da:	1141                	addi	sp,sp,-16
    800018dc:	e422                	sd	s0,8(sp)
    800018de:	0800                	addi	s0,sp,16
    800018e0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018e2:	2781                	sext.w	a5,a5
    800018e4:	079e                	slli	a5,a5,0x7
  return c;
}
    800018e6:	00015517          	auipc	a0,0x15
    800018ea:	11250513          	addi	a0,a0,274 # 800169f8 <cpus>
    800018ee:	953e                	add	a0,a0,a5
    800018f0:	6422                	ld	s0,8(sp)
    800018f2:	0141                	addi	sp,sp,16
    800018f4:	8082                	ret

00000000800018f6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018f6:	1101                	addi	sp,sp,-32
    800018f8:	ec06                	sd	ra,24(sp)
    800018fa:	e822                	sd	s0,16(sp)
    800018fc:	e426                	sd	s1,8(sp)
    800018fe:	1000                	addi	s0,sp,32
  push_off();
    80001900:	a8eff0ef          	jal	80000b8e <push_off>
    80001904:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001906:	2781                	sext.w	a5,a5
    80001908:	079e                	slli	a5,a5,0x7
    8000190a:	00015717          	auipc	a4,0x15
    8000190e:	0be70713          	addi	a4,a4,190 # 800169c8 <pid_lock>
    80001912:	97ba                	add	a5,a5,a4
    80001914:	7b84                	ld	s1,48(a5)
  pop_off();
    80001916:	afcff0ef          	jal	80000c12 <pop_off>
  return p;
}
    8000191a:	8526                	mv	a0,s1
    8000191c:	60e2                	ld	ra,24(sp)
    8000191e:	6442                	ld	s0,16(sp)
    80001920:	64a2                	ld	s1,8(sp)
    80001922:	6105                	addi	sp,sp,32
    80001924:	8082                	ret

0000000080001926 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001926:	7179                	addi	sp,sp,-48
    80001928:	f406                	sd	ra,40(sp)
    8000192a:	f022                	sd	s0,32(sp)
    8000192c:	ec26                	sd	s1,24(sp)
    8000192e:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001930:	fc7ff0ef          	jal	800018f6 <myproc>
    80001934:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001936:	b30ff0ef          	jal	80000c66 <release>

  if (first) {
    8000193a:	0000d797          	auipc	a5,0xd
    8000193e:	d467a783          	lw	a5,-698(a5) # 8000e680 <first.1>
    80001942:	c7a5                	beqz	a5,800019aa <forkret+0x84>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001944:	4505                	li	a0,1
    80001946:	3ff010ef          	jal	80003544 <fsinit>

    printf("DEBUG: vfs_mount\n");
    8000194a:	00009517          	auipc	a0,0x9
    8000194e:	87650513          	addi	a0,a0,-1930 # 8000a1c0 <etext+0x1c0>
    80001952:	ba9fe0ef          	jal	800004fa <printf>
    if(vfs_mount("rootdisk", "/", "xv6fs", 0) < 0)
    80001956:	4681                	li	a3,0
    80001958:	00009617          	auipc	a2,0x9
    8000195c:	88060613          	addi	a2,a2,-1920 # 8000a1d8 <etext+0x1d8>
    80001960:	00009597          	auipc	a1,0x9
    80001964:	88058593          	addi	a1,a1,-1920 # 8000a1e0 <etext+0x1e0>
    80001968:	00009517          	auipc	a0,0x9
    8000196c:	88050513          	addi	a0,a0,-1920 # 8000a1e8 <etext+0x1e8>
    80001970:	28a040ef          	jal	80005bfa <vfs_mount>
    80001974:	06054663          	bltz	a0,800019e0 <forkret+0xba>
      panic("vfs_mount root failed");

    first = 0;
    80001978:	0000d797          	auipc	a5,0xd
    8000197c:	d007a423          	sw	zero,-760(a5) # 8000e680 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001980:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001984:	00009517          	auipc	a0,0x9
    80001988:	88c50513          	addi	a0,a0,-1908 # 8000a210 <etext+0x210>
    8000198c:	fca43823          	sd	a0,-48(s0)
    80001990:	fc043c23          	sd	zero,-40(s0)
    80001994:	fd040593          	addi	a1,s0,-48
    80001998:	4c9020ef          	jal	80004660 <kexec>
    8000199c:	6cbc                	ld	a5,88(s1)
    8000199e:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    800019a0:	6cbc                	ld	a5,88(s1)
    800019a2:	7bb8                	ld	a4,112(a5)
    800019a4:	57fd                	li	a5,-1
    800019a6:	04f70363          	beq	a4,a5,800019ec <forkret+0xc6>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    800019aa:	2cb000ef          	jal	80002474 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800019ae:	68a8                	ld	a0,80(s1)
    800019b0:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800019b2:	04000737          	lui	a4,0x4000
    800019b6:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800019b8:	0732                	slli	a4,a4,0xc
    800019ba:	00007797          	auipc	a5,0x7
    800019be:	6e278793          	addi	a5,a5,1762 # 8000909c <userret>
    800019c2:	00007697          	auipc	a3,0x7
    800019c6:	63e68693          	addi	a3,a3,1598 # 80009000 <_trampoline>
    800019ca:	8f95                	sub	a5,a5,a3
    800019cc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019ce:	577d                	li	a4,-1
    800019d0:	177e                	slli	a4,a4,0x3f
    800019d2:	8d59                	or	a0,a0,a4
    800019d4:	9782                	jalr	a5
}
    800019d6:	70a2                	ld	ra,40(sp)
    800019d8:	7402                	ld	s0,32(sp)
    800019da:	64e2                	ld	s1,24(sp)
    800019dc:	6145                	addi	sp,sp,48
    800019de:	8082                	ret
      panic("vfs_mount root failed");
    800019e0:	00009517          	auipc	a0,0x9
    800019e4:	81850513          	addi	a0,a0,-2024 # 8000a1f8 <etext+0x1f8>
    800019e8:	df9fe0ef          	jal	800007e0 <panic>
      panic("exec");
    800019ec:	00009517          	auipc	a0,0x9
    800019f0:	82c50513          	addi	a0,a0,-2004 # 8000a218 <etext+0x218>
    800019f4:	dedfe0ef          	jal	800007e0 <panic>

00000000800019f8 <allocpid>:
{
    800019f8:	1101                	addi	sp,sp,-32
    800019fa:	ec06                	sd	ra,24(sp)
    800019fc:	e822                	sd	s0,16(sp)
    800019fe:	e426                	sd	s1,8(sp)
    80001a00:	e04a                	sd	s2,0(sp)
    80001a02:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a04:	00015917          	auipc	s2,0x15
    80001a08:	fc490913          	addi	s2,s2,-60 # 800169c8 <pid_lock>
    80001a0c:	854a                	mv	a0,s2
    80001a0e:	9c0ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    80001a12:	0000d797          	auipc	a5,0xd
    80001a16:	c7278793          	addi	a5,a5,-910 # 8000e684 <nextpid>
    80001a1a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a1c:	0014871b          	addiw	a4,s1,1
    80001a20:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a22:	854a                	mv	a0,s2
    80001a24:	a42ff0ef          	jal	80000c66 <release>
}
    80001a28:	8526                	mv	a0,s1
    80001a2a:	60e2                	ld	ra,24(sp)
    80001a2c:	6442                	ld	s0,16(sp)
    80001a2e:	64a2                	ld	s1,8(sp)
    80001a30:	6902                	ld	s2,0(sp)
    80001a32:	6105                	addi	sp,sp,32
    80001a34:	8082                	ret

0000000080001a36 <proc_pagetable>:
{
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	e04a                	sd	s2,0(sp)
    80001a40:	1000                	addi	s0,sp,32
    80001a42:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a44:	f78ff0ef          	jal	800011bc <uvmcreate>
    80001a48:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a4a:	cd05                	beqz	a0,80001a82 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a4c:	4729                	li	a4,10
    80001a4e:	00007697          	auipc	a3,0x7
    80001a52:	5b268693          	addi	a3,a3,1458 # 80009000 <_trampoline>
    80001a56:	6605                	lui	a2,0x1
    80001a58:	040005b7          	lui	a1,0x4000
    80001a5c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a5e:	05b2                	slli	a1,a1,0xc
    80001a60:	db6ff0ef          	jal	80001016 <mappages>
    80001a64:	02054663          	bltz	a0,80001a90 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a68:	4719                	li	a4,6
    80001a6a:	05893683          	ld	a3,88(s2)
    80001a6e:	6605                	lui	a2,0x1
    80001a70:	020005b7          	lui	a1,0x2000
    80001a74:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a76:	05b6                	slli	a1,a1,0xd
    80001a78:	8526                	mv	a0,s1
    80001a7a:	d9cff0ef          	jal	80001016 <mappages>
    80001a7e:	00054f63          	bltz	a0,80001a9c <proc_pagetable+0x66>
}
    80001a82:	8526                	mv	a0,s1
    80001a84:	60e2                	ld	ra,24(sp)
    80001a86:	6442                	ld	s0,16(sp)
    80001a88:	64a2                	ld	s1,8(sp)
    80001a8a:	6902                	ld	s2,0(sp)
    80001a8c:	6105                	addi	sp,sp,32
    80001a8e:	8082                	ret
    uvmfree(pagetable, 0);
    80001a90:	4581                	li	a1,0
    80001a92:	8526                	mv	a0,s1
    80001a94:	923ff0ef          	jal	800013b6 <uvmfree>
    return 0;
    80001a98:	4481                	li	s1,0
    80001a9a:	b7e5                	j	80001a82 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a9c:	4681                	li	a3,0
    80001a9e:	4605                	li	a2,1
    80001aa0:	040005b7          	lui	a1,0x4000
    80001aa4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa6:	05b2                	slli	a1,a1,0xc
    80001aa8:	8526                	mv	a0,s1
    80001aaa:	f38ff0ef          	jal	800011e2 <uvmunmap>
    uvmfree(pagetable, 0);
    80001aae:	4581                	li	a1,0
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	905ff0ef          	jal	800013b6 <uvmfree>
    return 0;
    80001ab6:	4481                	li	s1,0
    80001ab8:	b7e9                	j	80001a82 <proc_pagetable+0x4c>

0000000080001aba <proc_freepagetable>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
    80001ac6:	84aa                	mv	s1,a0
    80001ac8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aca:	4681                	li	a3,0
    80001acc:	4605                	li	a2,1
    80001ace:	040005b7          	lui	a1,0x4000
    80001ad2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ad4:	05b2                	slli	a1,a1,0xc
    80001ad6:	f0cff0ef          	jal	800011e2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ada:	4681                	li	a3,0
    80001adc:	4605                	li	a2,1
    80001ade:	020005b7          	lui	a1,0x2000
    80001ae2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ae4:	05b6                	slli	a1,a1,0xd
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	efaff0ef          	jal	800011e2 <uvmunmap>
  uvmfree(pagetable, sz);
    80001aec:	85ca                	mv	a1,s2
    80001aee:	8526                	mv	a0,s1
    80001af0:	8c7ff0ef          	jal	800013b6 <uvmfree>
}
    80001af4:	60e2                	ld	ra,24(sp)
    80001af6:	6442                	ld	s0,16(sp)
    80001af8:	64a2                	ld	s1,8(sp)
    80001afa:	6902                	ld	s2,0(sp)
    80001afc:	6105                	addi	sp,sp,32
    80001afe:	8082                	ret

0000000080001b00 <freeproc>:
{
    80001b00:	1101                	addi	sp,sp,-32
    80001b02:	ec06                	sd	ra,24(sp)
    80001b04:	e822                	sd	s0,16(sp)
    80001b06:	e426                	sd	s1,8(sp)
    80001b08:	1000                	addi	s0,sp,32
    80001b0a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b0c:	6d28                	ld	a0,88(a0)
    80001b0e:	c119                	beqz	a0,80001b14 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001b10:	f0dfe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001b14:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b18:	68a8                	ld	a0,80(s1)
    80001b1a:	c501                	beqz	a0,80001b22 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001b1c:	64ac                	ld	a1,72(s1)
    80001b1e:	f9dff0ef          	jal	80001aba <proc_freepagetable>
  p->pagetable = 0;
    80001b22:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b26:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b2a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b2e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b32:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b36:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b3a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b3e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b42:	0004ac23          	sw	zero,24(s1)
}
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6105                	addi	sp,sp,32
    80001b4e:	8082                	ret

0000000080001b50 <allocproc>:
{
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	e04a                	sd	s2,0(sp)
    80001b5a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5c:	00015497          	auipc	s1,0x15
    80001b60:	29c48493          	addi	s1,s1,668 # 80016df8 <proc>
    80001b64:	0001b917          	auipc	s2,0x1b
    80001b68:	c9490913          	addi	s2,s2,-876 # 8001c7f8 <tickslock>
    acquire(&p->lock);
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	860ff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b72:	4c9c                	lw	a5,24(s1)
    80001b74:	cb91                	beqz	a5,80001b88 <allocproc+0x38>
      release(&p->lock);
    80001b76:	8526                	mv	a0,s1
    80001b78:	8eeff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7c:	16848493          	addi	s1,s1,360
    80001b80:	ff2496e3          	bne	s1,s2,80001b6c <allocproc+0x1c>
  return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	a089                	j	80001bc8 <allocproc+0x78>
  p->pid = allocpid();
    80001b88:	e71ff0ef          	jal	800019f8 <allocpid>
    80001b8c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b8e:	4785                	li	a5,1
    80001b90:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b92:	f6dfe0ef          	jal	80000afe <kalloc>
    80001b96:	892a                	mv	s2,a0
    80001b98:	eca8                	sd	a0,88(s1)
    80001b9a:	cd15                	beqz	a0,80001bd6 <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	e99ff0ef          	jal	80001a36 <proc_pagetable>
    80001ba2:	892a                	mv	s2,a0
    80001ba4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ba6:	c121                	beqz	a0,80001be6 <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001ba8:	07000613          	li	a2,112
    80001bac:	4581                	li	a1,0
    80001bae:	06048513          	addi	a0,s1,96
    80001bb2:	8f0ff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001bb6:	00000797          	auipc	a5,0x0
    80001bba:	d7078793          	addi	a5,a5,-656 # 80001926 <forkret>
    80001bbe:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bc0:	60bc                	ld	a5,64(s1)
    80001bc2:	6705                	lui	a4,0x1
    80001bc4:	97ba                	add	a5,a5,a4
    80001bc6:	f4bc                	sd	a5,104(s1)
}
    80001bc8:	8526                	mv	a0,s1
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret
    freeproc(p);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	f29ff0ef          	jal	80001b00 <freeproc>
    release(&p->lock);
    80001bdc:	8526                	mv	a0,s1
    80001bde:	888ff0ef          	jal	80000c66 <release>
    return 0;
    80001be2:	84ca                	mv	s1,s2
    80001be4:	b7d5                	j	80001bc8 <allocproc+0x78>
    freeproc(p);
    80001be6:	8526                	mv	a0,s1
    80001be8:	f19ff0ef          	jal	80001b00 <freeproc>
    release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	878ff0ef          	jal	80000c66 <release>
    return 0;
    80001bf2:	84ca                	mv	s1,s2
    80001bf4:	bfd1                	j	80001bc8 <allocproc+0x78>

0000000080001bf6 <userinit>:
{
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c00:	f51ff0ef          	jal	80001b50 <allocproc>
    80001c04:	84aa                	mv	s1,a0
  initproc = p;
    80001c06:	0000d797          	auipc	a5,0xd
    80001c0a:	c2a7bd23          	sd	a0,-966(a5) # 8000e840 <initproc>
  p->cwd = namei("/");
    80001c0e:	00008517          	auipc	a0,0x8
    80001c12:	5d250513          	addi	a0,a0,1490 # 8000a1e0 <etext+0x1e0>
    80001c16:	651010ef          	jal	80003a66 <namei>
    80001c1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c1e:	478d                	li	a5,3
    80001c20:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c22:	8526                	mv	a0,s1
    80001c24:	842ff0ef          	jal	80000c66 <release>
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <growproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
    80001c3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c40:	cb7ff0ef          	jal	800018f6 <myproc>
    80001c44:	892a                	mv	s2,a0
  sz = p->sz;
    80001c46:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c48:	02905963          	blez	s1,80001c7a <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c4c:	00b48633          	add	a2,s1,a1
    80001c50:	020007b7          	lui	a5,0x2000
    80001c54:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c56:	07b6                	slli	a5,a5,0xd
    80001c58:	02c7ea63          	bltu	a5,a2,80001c8c <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c5c:	4691                	li	a3,4
    80001c5e:	6928                	ld	a0,80(a0)
    80001c60:	e50ff0ef          	jal	800012b0 <uvmalloc>
    80001c64:	85aa                	mv	a1,a0
    80001c66:	c50d                	beqz	a0,80001c90 <growproc+0x5e>
  p->sz = sz;
    80001c68:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c6c:	4501                	li	a0,0
}
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
  } else if(n < 0){
    80001c7a:	fe04d7e3          	bgez	s1,80001c68 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c7e:	00b48633          	add	a2,s1,a1
    80001c82:	6928                	ld	a0,80(a0)
    80001c84:	de8ff0ef          	jal	8000126c <uvmdealloc>
    80001c88:	85aa                	mv	a1,a0
    80001c8a:	bff9                	j	80001c68 <growproc+0x36>
      return -1;
    80001c8c:	557d                	li	a0,-1
    80001c8e:	b7c5                	j	80001c6e <growproc+0x3c>
      return -1;
    80001c90:	557d                	li	a0,-1
    80001c92:	bff1                	j	80001c6e <growproc+0x3c>

0000000080001c94 <kfork>:
{
    80001c94:	7139                	addi	sp,sp,-64
    80001c96:	fc06                	sd	ra,56(sp)
    80001c98:	f822                	sd	s0,48(sp)
    80001c9a:	f04a                	sd	s2,32(sp)
    80001c9c:	e456                	sd	s5,8(sp)
    80001c9e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ca0:	c57ff0ef          	jal	800018f6 <myproc>
    80001ca4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ca6:	eabff0ef          	jal	80001b50 <allocproc>
    80001caa:	0e050a63          	beqz	a0,80001d9e <kfork+0x10a>
    80001cae:	e852                	sd	s4,16(sp)
    80001cb0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001cb2:	048ab603          	ld	a2,72(s5)
    80001cb6:	692c                	ld	a1,80(a0)
    80001cb8:	050ab503          	ld	a0,80(s5)
    80001cbc:	f2cff0ef          	jal	800013e8 <uvmcopy>
    80001cc0:	04054a63          	bltz	a0,80001d14 <kfork+0x80>
    80001cc4:	f426                	sd	s1,40(sp)
    80001cc6:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001cc8:	048ab783          	ld	a5,72(s5)
    80001ccc:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001cd0:	058ab683          	ld	a3,88(s5)
    80001cd4:	87b6                	mv	a5,a3
    80001cd6:	058a3703          	ld	a4,88(s4)
    80001cda:	12068693          	addi	a3,a3,288
    80001cde:	0007b803          	ld	a6,0(a5)
    80001ce2:	6788                	ld	a0,8(a5)
    80001ce4:	6b8c                	ld	a1,16(a5)
    80001ce6:	6f90                	ld	a2,24(a5)
    80001ce8:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001cec:	e708                	sd	a0,8(a4)
    80001cee:	eb0c                	sd	a1,16(a4)
    80001cf0:	ef10                	sd	a2,24(a4)
    80001cf2:	02078793          	addi	a5,a5,32
    80001cf6:	02070713          	addi	a4,a4,32
    80001cfa:	fed792e3          	bne	a5,a3,80001cde <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001cfe:	058a3783          	ld	a5,88(s4)
    80001d02:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001d06:	0d0a8493          	addi	s1,s5,208
    80001d0a:	0d0a0913          	addi	s2,s4,208
    80001d0e:	150a8993          	addi	s3,s5,336
    80001d12:	a831                	j	80001d2e <kfork+0x9a>
    freeproc(np);
    80001d14:	8552                	mv	a0,s4
    80001d16:	debff0ef          	jal	80001b00 <freeproc>
    release(&np->lock);
    80001d1a:	8552                	mv	a0,s4
    80001d1c:	f4bfe0ef          	jal	80000c66 <release>
    return -1;
    80001d20:	597d                	li	s2,-1
    80001d22:	6a42                	ld	s4,16(sp)
    80001d24:	a0b5                	j	80001d90 <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001d26:	04a1                	addi	s1,s1,8
    80001d28:	0921                	addi	s2,s2,8
    80001d2a:	01348963          	beq	s1,s3,80001d3c <kfork+0xa8>
    if(p->ofile[i])
    80001d2e:	6088                	ld	a0,0(s1)
    80001d30:	d97d                	beqz	a0,80001d26 <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d32:	2ce020ef          	jal	80004000 <filedup>
    80001d36:	00a93023          	sd	a0,0(s2)
    80001d3a:	b7f5                	j	80001d26 <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d3c:	150ab503          	ld	a0,336(s5)
    80001d40:	4da010ef          	jal	8000321a <idup>
    80001d44:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d48:	4641                	li	a2,16
    80001d4a:	158a8593          	addi	a1,s5,344
    80001d4e:	158a0513          	addi	a0,s4,344
    80001d52:	88eff0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001d56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001d5a:	8552                	mv	a0,s4
    80001d5c:	f0bfe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001d60:	00015497          	auipc	s1,0x15
    80001d64:	c8048493          	addi	s1,s1,-896 # 800169e0 <wait_lock>
    80001d68:	8526                	mv	a0,s1
    80001d6a:	e65fe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001d6e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	ef3fe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001d78:	8552                	mv	a0,s4
    80001d7a:	e55fe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001d7e:	478d                	li	a5,3
    80001d80:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d84:	8552                	mv	a0,s4
    80001d86:	ee1fe0ef          	jal	80000c66 <release>
  return pid;
    80001d8a:	74a2                	ld	s1,40(sp)
    80001d8c:	69e2                	ld	s3,24(sp)
    80001d8e:	6a42                	ld	s4,16(sp)
}
    80001d90:	854a                	mv	a0,s2
    80001d92:	70e2                	ld	ra,56(sp)
    80001d94:	7442                	ld	s0,48(sp)
    80001d96:	7902                	ld	s2,32(sp)
    80001d98:	6aa2                	ld	s5,8(sp)
    80001d9a:	6121                	addi	sp,sp,64
    80001d9c:	8082                	ret
    return -1;
    80001d9e:	597d                	li	s2,-1
    80001da0:	bfc5                	j	80001d90 <kfork+0xfc>

0000000080001da2 <scheduler>:
{
    80001da2:	715d                	addi	sp,sp,-80
    80001da4:	e486                	sd	ra,72(sp)
    80001da6:	e0a2                	sd	s0,64(sp)
    80001da8:	fc26                	sd	s1,56(sp)
    80001daa:	f84a                	sd	s2,48(sp)
    80001dac:	f44e                	sd	s3,40(sp)
    80001dae:	f052                	sd	s4,32(sp)
    80001db0:	ec56                	sd	s5,24(sp)
    80001db2:	e85a                	sd	s6,16(sp)
    80001db4:	e45e                	sd	s7,8(sp)
    80001db6:	e062                	sd	s8,0(sp)
    80001db8:	0880                	addi	s0,sp,80
    80001dba:	8792                	mv	a5,tp
  int id = r_tp();
    80001dbc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001dbe:	00779b13          	slli	s6,a5,0x7
    80001dc2:	00015717          	auipc	a4,0x15
    80001dc6:	c0670713          	addi	a4,a4,-1018 # 800169c8 <pid_lock>
    80001dca:	975a                	add	a4,a4,s6
    80001dcc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001dd0:	00015717          	auipc	a4,0x15
    80001dd4:	c3070713          	addi	a4,a4,-976 # 80016a00 <cpus+0x8>
    80001dd8:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001dda:	4c11                	li	s8,4
        c->proc = p;
    80001ddc:	079e                	slli	a5,a5,0x7
    80001dde:	00015a17          	auipc	s4,0x15
    80001de2:	beaa0a13          	addi	s4,s4,-1046 # 800169c8 <pid_lock>
    80001de6:	9a3e                	add	s4,s4,a5
        found = 1;
    80001de8:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dea:	0001b997          	auipc	s3,0x1b
    80001dee:	a0e98993          	addi	s3,s3,-1522 # 8001c7f8 <tickslock>
    80001df2:	a83d                	j	80001e30 <scheduler+0x8e>
      release(&p->lock);
    80001df4:	8526                	mv	a0,s1
    80001df6:	e71fe0ef          	jal	80000c66 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dfa:	16848493          	addi	s1,s1,360
    80001dfe:	03348563          	beq	s1,s3,80001e28 <scheduler+0x86>
      acquire(&p->lock);
    80001e02:	8526                	mv	a0,s1
    80001e04:	dcbfe0ef          	jal	80000bce <acquire>
      if(p->state == RUNNABLE) {
    80001e08:	4c9c                	lw	a5,24(s1)
    80001e0a:	ff2795e3          	bne	a5,s2,80001df4 <scheduler+0x52>
        p->state = RUNNING;
    80001e0e:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001e12:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001e16:	06048593          	addi	a1,s1,96
    80001e1a:	855a                	mv	a0,s6
    80001e1c:	5b2000ef          	jal	800023ce <swtch>
        c->proc = 0;
    80001e20:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001e24:	8ade                	mv	s5,s7
    80001e26:	b7f9                	j	80001df4 <scheduler+0x52>
    if(found == 0) {
    80001e28:	000a9463          	bnez	s5,80001e30 <scheduler+0x8e>
      asm volatile("wfi");
    80001e2c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e38:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001e40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e42:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001e46:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e48:	00015497          	auipc	s1,0x15
    80001e4c:	fb048493          	addi	s1,s1,-80 # 80016df8 <proc>
      if(p->state == RUNNABLE) {
    80001e50:	490d                	li	s2,3
    80001e52:	bf45                	j	80001e02 <scheduler+0x60>

0000000080001e54 <sched>:
{
    80001e54:	7179                	addi	sp,sp,-48
    80001e56:	f406                	sd	ra,40(sp)
    80001e58:	f022                	sd	s0,32(sp)
    80001e5a:	ec26                	sd	s1,24(sp)
    80001e5c:	e84a                	sd	s2,16(sp)
    80001e5e:	e44e                	sd	s3,8(sp)
    80001e60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e62:	a95ff0ef          	jal	800018f6 <myproc>
    80001e66:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e68:	cfdfe0ef          	jal	80000b64 <holding>
    80001e6c:	c92d                	beqz	a0,80001ede <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e6e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001e70:	2781                	sext.w	a5,a5
    80001e72:	079e                	slli	a5,a5,0x7
    80001e74:	00015717          	auipc	a4,0x15
    80001e78:	b5470713          	addi	a4,a4,-1196 # 800169c8 <pid_lock>
    80001e7c:	97ba                	add	a5,a5,a4
    80001e7e:	0a87a703          	lw	a4,168(a5)
    80001e82:	4785                	li	a5,1
    80001e84:	06f71363          	bne	a4,a5,80001eea <sched+0x96>
  if(p->state == RUNNING)
    80001e88:	4c98                	lw	a4,24(s1)
    80001e8a:	4791                	li	a5,4
    80001e8c:	06f70563          	beq	a4,a5,80001ef6 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e94:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e96:	e7b5                	bnez	a5,80001f02 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e98:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e9a:	00015917          	auipc	s2,0x15
    80001e9e:	b2e90913          	addi	s2,s2,-1234 # 800169c8 <pid_lock>
    80001ea2:	2781                	sext.w	a5,a5
    80001ea4:	079e                	slli	a5,a5,0x7
    80001ea6:	97ca                	add	a5,a5,s2
    80001ea8:	0ac7a983          	lw	s3,172(a5)
    80001eac:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001eae:	2781                	sext.w	a5,a5
    80001eb0:	079e                	slli	a5,a5,0x7
    80001eb2:	00015597          	auipc	a1,0x15
    80001eb6:	b4e58593          	addi	a1,a1,-1202 # 80016a00 <cpus+0x8>
    80001eba:	95be                	add	a1,a1,a5
    80001ebc:	06048513          	addi	a0,s1,96
    80001ec0:	50e000ef          	jal	800023ce <swtch>
    80001ec4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ec6:	2781                	sext.w	a5,a5
    80001ec8:	079e                	slli	a5,a5,0x7
    80001eca:	993e                	add	s2,s2,a5
    80001ecc:	0b392623          	sw	s3,172(s2)
}
    80001ed0:	70a2                	ld	ra,40(sp)
    80001ed2:	7402                	ld	s0,32(sp)
    80001ed4:	64e2                	ld	s1,24(sp)
    80001ed6:	6942                	ld	s2,16(sp)
    80001ed8:	69a2                	ld	s3,8(sp)
    80001eda:	6145                	addi	sp,sp,48
    80001edc:	8082                	ret
    panic("sched p->lock");
    80001ede:	00008517          	auipc	a0,0x8
    80001ee2:	34250513          	addi	a0,a0,834 # 8000a220 <etext+0x220>
    80001ee6:	8fbfe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001eea:	00008517          	auipc	a0,0x8
    80001eee:	34650513          	addi	a0,a0,838 # 8000a230 <etext+0x230>
    80001ef2:	8effe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001ef6:	00008517          	auipc	a0,0x8
    80001efa:	34a50513          	addi	a0,a0,842 # 8000a240 <etext+0x240>
    80001efe:	8e3fe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f02:	00008517          	auipc	a0,0x8
    80001f06:	34e50513          	addi	a0,a0,846 # 8000a250 <etext+0x250>
    80001f0a:	8d7fe0ef          	jal	800007e0 <panic>

0000000080001f0e <yield>:
{
    80001f0e:	1101                	addi	sp,sp,-32
    80001f10:	ec06                	sd	ra,24(sp)
    80001f12:	e822                	sd	s0,16(sp)
    80001f14:	e426                	sd	s1,8(sp)
    80001f16:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f18:	9dfff0ef          	jal	800018f6 <myproc>
    80001f1c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f1e:	cb1fe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80001f22:	478d                	li	a5,3
    80001f24:	cc9c                	sw	a5,24(s1)
  sched();
    80001f26:	f2fff0ef          	jal	80001e54 <sched>
  release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	d3bfe0ef          	jal	80000c66 <release>
}
    80001f30:	60e2                	ld	ra,24(sp)
    80001f32:	6442                	ld	s0,16(sp)
    80001f34:	64a2                	ld	s1,8(sp)
    80001f36:	6105                	addi	sp,sp,32
    80001f38:	8082                	ret

0000000080001f3a <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f3a:	7179                	addi	sp,sp,-48
    80001f3c:	f406                	sd	ra,40(sp)
    80001f3e:	f022                	sd	s0,32(sp)
    80001f40:	ec26                	sd	s1,24(sp)
    80001f42:	e84a                	sd	s2,16(sp)
    80001f44:	e44e                	sd	s3,8(sp)
    80001f46:	1800                	addi	s0,sp,48
    80001f48:	89aa                	mv	s3,a0
    80001f4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f4c:	9abff0ef          	jal	800018f6 <myproc>
    80001f50:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f52:	c7dfe0ef          	jal	80000bce <acquire>
  release(lk);
    80001f56:	854a                	mv	a0,s2
    80001f58:	d0ffe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80001f5c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f60:	4789                	li	a5,2
    80001f62:	cc9c                	sw	a5,24(s1)

  sched();
    80001f64:	ef1ff0ef          	jal	80001e54 <sched>

  // Tidy up.
  p->chan = 0;
    80001f68:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	cf9fe0ef          	jal	80000c66 <release>
  acquire(lk);
    80001f72:	854a                	mv	a0,s2
    80001f74:	c5bfe0ef          	jal	80000bce <acquire>
}
    80001f78:	70a2                	ld	ra,40(sp)
    80001f7a:	7402                	ld	s0,32(sp)
    80001f7c:	64e2                	ld	s1,24(sp)
    80001f7e:	6942                	ld	s2,16(sp)
    80001f80:	69a2                	ld	s3,8(sp)
    80001f82:	6145                	addi	sp,sp,48
    80001f84:	8082                	ret

0000000080001f86 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f86:	7139                	addi	sp,sp,-64
    80001f88:	fc06                	sd	ra,56(sp)
    80001f8a:	f822                	sd	s0,48(sp)
    80001f8c:	f426                	sd	s1,40(sp)
    80001f8e:	f04a                	sd	s2,32(sp)
    80001f90:	ec4e                	sd	s3,24(sp)
    80001f92:	e852                	sd	s4,16(sp)
    80001f94:	e456                	sd	s5,8(sp)
    80001f96:	0080                	addi	s0,sp,64
    80001f98:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	00015497          	auipc	s1,0x15
    80001f9e:	e5e48493          	addi	s1,s1,-418 # 80016df8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001fa2:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001fa4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	0001b917          	auipc	s2,0x1b
    80001faa:	85290913          	addi	s2,s2,-1966 # 8001c7f8 <tickslock>
    80001fae:	a801                	j	80001fbe <wakeup+0x38>
      }
      release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	cb5fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb6:	16848493          	addi	s1,s1,360
    80001fba:	03248263          	beq	s1,s2,80001fde <wakeup+0x58>
    if(p != myproc()){
    80001fbe:	939ff0ef          	jal	800018f6 <myproc>
    80001fc2:	fea48ae3          	beq	s1,a0,80001fb6 <wakeup+0x30>
      acquire(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	c07fe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff3791e3          	bne	a5,s3,80001fb0 <wakeup+0x2a>
    80001fd2:	709c                	ld	a5,32(s1)
    80001fd4:	fd479ee3          	bne	a5,s4,80001fb0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001fd8:	0154ac23          	sw	s5,24(s1)
    80001fdc:	bfd1                	j	80001fb0 <wakeup+0x2a>
    }
  }
}
    80001fde:	70e2                	ld	ra,56(sp)
    80001fe0:	7442                	ld	s0,48(sp)
    80001fe2:	74a2                	ld	s1,40(sp)
    80001fe4:	7902                	ld	s2,32(sp)
    80001fe6:	69e2                	ld	s3,24(sp)
    80001fe8:	6a42                	ld	s4,16(sp)
    80001fea:	6aa2                	ld	s5,8(sp)
    80001fec:	6121                	addi	sp,sp,64
    80001fee:	8082                	ret

0000000080001ff0 <reparent>:
{
    80001ff0:	7179                	addi	sp,sp,-48
    80001ff2:	f406                	sd	ra,40(sp)
    80001ff4:	f022                	sd	s0,32(sp)
    80001ff6:	ec26                	sd	s1,24(sp)
    80001ff8:	e84a                	sd	s2,16(sp)
    80001ffa:	e44e                	sd	s3,8(sp)
    80001ffc:	e052                	sd	s4,0(sp)
    80001ffe:	1800                	addi	s0,sp,48
    80002000:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002002:	00015497          	auipc	s1,0x15
    80002006:	df648493          	addi	s1,s1,-522 # 80016df8 <proc>
      pp->parent = initproc;
    8000200a:	0000da17          	auipc	s4,0xd
    8000200e:	836a0a13          	addi	s4,s4,-1994 # 8000e840 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002012:	0001a997          	auipc	s3,0x1a
    80002016:	7e698993          	addi	s3,s3,2022 # 8001c7f8 <tickslock>
    8000201a:	a029                	j	80002024 <reparent+0x34>
    8000201c:	16848493          	addi	s1,s1,360
    80002020:	01348b63          	beq	s1,s3,80002036 <reparent+0x46>
    if(pp->parent == p){
    80002024:	7c9c                	ld	a5,56(s1)
    80002026:	ff279be3          	bne	a5,s2,8000201c <reparent+0x2c>
      pp->parent = initproc;
    8000202a:	000a3503          	ld	a0,0(s4)
    8000202e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002030:	f57ff0ef          	jal	80001f86 <wakeup>
    80002034:	b7e5                	j	8000201c <reparent+0x2c>
}
    80002036:	70a2                	ld	ra,40(sp)
    80002038:	7402                	ld	s0,32(sp)
    8000203a:	64e2                	ld	s1,24(sp)
    8000203c:	6942                	ld	s2,16(sp)
    8000203e:	69a2                	ld	s3,8(sp)
    80002040:	6a02                	ld	s4,0(sp)
    80002042:	6145                	addi	sp,sp,48
    80002044:	8082                	ret

0000000080002046 <kexit>:
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	e052                	sd	s4,0(sp)
    80002054:	1800                	addi	s0,sp,48
    80002056:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002058:	89fff0ef          	jal	800018f6 <myproc>
    8000205c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000205e:	0000c797          	auipc	a5,0xc
    80002062:	7e27b783          	ld	a5,2018(a5) # 8000e840 <initproc>
    80002066:	0d050493          	addi	s1,a0,208
    8000206a:	15050913          	addi	s2,a0,336
    8000206e:	00a79f63          	bne	a5,a0,8000208c <kexit+0x46>
    panic("init exiting");
    80002072:	00008517          	auipc	a0,0x8
    80002076:	1f650513          	addi	a0,a0,502 # 8000a268 <etext+0x268>
    8000207a:	f66fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    8000207e:	7c9010ef          	jal	80004046 <fileclose>
      p->ofile[fd] = 0;
    80002082:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002086:	04a1                	addi	s1,s1,8
    80002088:	01248563          	beq	s1,s2,80002092 <kexit+0x4c>
    if(p->ofile[fd]){
    8000208c:	6088                	ld	a0,0(s1)
    8000208e:	f965                	bnez	a0,8000207e <kexit+0x38>
    80002090:	bfdd                	j	80002086 <kexit+0x40>
  begin_op();
    80002092:	3a9010ef          	jal	80003c3a <begin_op>
  iput(p->cwd);
    80002096:	1509b503          	ld	a0,336(s3)
    8000209a:	338010ef          	jal	800033d2 <iput>
  end_op();
    8000209e:	407010ef          	jal	80003ca4 <end_op>
  p->cwd = 0;
    800020a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800020a6:	00015497          	auipc	s1,0x15
    800020aa:	93a48493          	addi	s1,s1,-1734 # 800169e0 <wait_lock>
    800020ae:	8526                	mv	a0,s1
    800020b0:	b1ffe0ef          	jal	80000bce <acquire>
  reparent(p);
    800020b4:	854e                	mv	a0,s3
    800020b6:	f3bff0ef          	jal	80001ff0 <reparent>
  wakeup(p->parent);
    800020ba:	0389b503          	ld	a0,56(s3)
    800020be:	ec9ff0ef          	jal	80001f86 <wakeup>
  acquire(&p->lock);
    800020c2:	854e                	mv	a0,s3
    800020c4:	b0bfe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    800020c8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800020cc:	4795                	li	a5,5
    800020ce:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	b93fe0ef          	jal	80000c66 <release>
  sched();
    800020d8:	d7dff0ef          	jal	80001e54 <sched>
  panic("zombie exit");
    800020dc:	00008517          	auipc	a0,0x8
    800020e0:	19c50513          	addi	a0,a0,412 # 8000a278 <etext+0x278>
    800020e4:	efcfe0ef          	jal	800007e0 <panic>

00000000800020e8 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800020f8:	00015497          	auipc	s1,0x15
    800020fc:	d0048493          	addi	s1,s1,-768 # 80016df8 <proc>
    80002100:	0001a997          	auipc	s3,0x1a
    80002104:	6f898993          	addi	s3,s3,1784 # 8001c7f8 <tickslock>
    acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	ac5fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    8000210e:	589c                	lw	a5,48(s1)
    80002110:	01278b63          	beq	a5,s2,80002126 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	b51fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000211a:	16848493          	addi	s1,s1,360
    8000211e:	ff3495e3          	bne	s1,s3,80002108 <kkill+0x20>
  }
  return -1;
    80002122:	557d                	li	a0,-1
    80002124:	a819                	j	8000213a <kkill+0x52>
      p->killed = 1;
    80002126:	4785                	li	a5,1
    80002128:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000212a:	4c98                	lw	a4,24(s1)
    8000212c:	4789                	li	a5,2
    8000212e:	00f70d63          	beq	a4,a5,80002148 <kkill+0x60>
      release(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	b33fe0ef          	jal	80000c66 <release>
      return 0;
    80002138:	4501                	li	a0,0
}
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6145                	addi	sp,sp,48
    80002146:	8082                	ret
        p->state = RUNNABLE;
    80002148:	478d                	li	a5,3
    8000214a:	cc9c                	sw	a5,24(s1)
    8000214c:	b7dd                	j	80002132 <kkill+0x4a>

000000008000214e <setkilled>:

void
setkilled(struct proc *p)
{
    8000214e:	1101                	addi	sp,sp,-32
    80002150:	ec06                	sd	ra,24(sp)
    80002152:	e822                	sd	s0,16(sp)
    80002154:	e426                	sd	s1,8(sp)
    80002156:	1000                	addi	s0,sp,32
    80002158:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000215a:	a75fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    8000215e:	4785                	li	a5,1
    80002160:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	b03fe0ef          	jal	80000c66 <release>
}
    80002168:	60e2                	ld	ra,24(sp)
    8000216a:	6442                	ld	s0,16(sp)
    8000216c:	64a2                	ld	s1,8(sp)
    8000216e:	6105                	addi	sp,sp,32
    80002170:	8082                	ret

0000000080002172 <killed>:

int
killed(struct proc *p)
{
    80002172:	1101                	addi	sp,sp,-32
    80002174:	ec06                	sd	ra,24(sp)
    80002176:	e822                	sd	s0,16(sp)
    80002178:	e426                	sd	s1,8(sp)
    8000217a:	e04a                	sd	s2,0(sp)
    8000217c:	1000                	addi	s0,sp,32
    8000217e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002180:	a4ffe0ef          	jal	80000bce <acquire>
  k = p->killed;
    80002184:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	addfe0ef          	jal	80000c66 <release>
  return k;
}
    8000218e:	854a                	mv	a0,s2
    80002190:	60e2                	ld	ra,24(sp)
    80002192:	6442                	ld	s0,16(sp)
    80002194:	64a2                	ld	s1,8(sp)
    80002196:	6902                	ld	s2,0(sp)
    80002198:	6105                	addi	sp,sp,32
    8000219a:	8082                	ret

000000008000219c <kwait>:
{
    8000219c:	715d                	addi	sp,sp,-80
    8000219e:	e486                	sd	ra,72(sp)
    800021a0:	e0a2                	sd	s0,64(sp)
    800021a2:	fc26                	sd	s1,56(sp)
    800021a4:	f84a                	sd	s2,48(sp)
    800021a6:	f44e                	sd	s3,40(sp)
    800021a8:	f052                	sd	s4,32(sp)
    800021aa:	ec56                	sd	s5,24(sp)
    800021ac:	e85a                	sd	s6,16(sp)
    800021ae:	e45e                	sd	s7,8(sp)
    800021b0:	e062                	sd	s8,0(sp)
    800021b2:	0880                	addi	s0,sp,80
    800021b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021b6:	f40ff0ef          	jal	800018f6 <myproc>
    800021ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021bc:	00015517          	auipc	a0,0x15
    800021c0:	82450513          	addi	a0,a0,-2012 # 800169e0 <wait_lock>
    800021c4:	a0bfe0ef          	jal	80000bce <acquire>
    havekids = 0;
    800021c8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800021ca:	4a15                	li	s4,5
        havekids = 1;
    800021cc:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ce:	0001a997          	auipc	s3,0x1a
    800021d2:	62a98993          	addi	s3,s3,1578 # 8001c7f8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d6:	00015c17          	auipc	s8,0x15
    800021da:	80ac0c13          	addi	s8,s8,-2038 # 800169e0 <wait_lock>
    800021de:	a871                	j	8000227a <kwait+0xde>
          pid = pp->pid;
    800021e0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800021e4:	000b0c63          	beqz	s6,800021fc <kwait+0x60>
    800021e8:	4691                	li	a3,4
    800021ea:	02c48613          	addi	a2,s1,44
    800021ee:	85da                	mv	a1,s6
    800021f0:	05093503          	ld	a0,80(s2)
    800021f4:	c16ff0ef          	jal	8000160a <copyout>
    800021f8:	02054b63          	bltz	a0,8000222e <kwait+0x92>
          freeproc(pp);
    800021fc:	8526                	mv	a0,s1
    800021fe:	903ff0ef          	jal	80001b00 <freeproc>
          release(&pp->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	a63fe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    80002208:	00014517          	auipc	a0,0x14
    8000220c:	7d850513          	addi	a0,a0,2008 # 800169e0 <wait_lock>
    80002210:	a57fe0ef          	jal	80000c66 <release>
}
    80002214:	854e                	mv	a0,s3
    80002216:	60a6                	ld	ra,72(sp)
    80002218:	6406                	ld	s0,64(sp)
    8000221a:	74e2                	ld	s1,56(sp)
    8000221c:	7942                	ld	s2,48(sp)
    8000221e:	79a2                	ld	s3,40(sp)
    80002220:	7a02                	ld	s4,32(sp)
    80002222:	6ae2                	ld	s5,24(sp)
    80002224:	6b42                	ld	s6,16(sp)
    80002226:	6ba2                	ld	s7,8(sp)
    80002228:	6c02                	ld	s8,0(sp)
    8000222a:	6161                	addi	sp,sp,80
    8000222c:	8082                	ret
            release(&pp->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	a37fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    80002234:	00014517          	auipc	a0,0x14
    80002238:	7ac50513          	addi	a0,a0,1964 # 800169e0 <wait_lock>
    8000223c:	a2bfe0ef          	jal	80000c66 <release>
            return -1;
    80002240:	59fd                	li	s3,-1
    80002242:	bfc9                	j	80002214 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002244:	16848493          	addi	s1,s1,360
    80002248:	03348063          	beq	s1,s3,80002268 <kwait+0xcc>
      if(pp->parent == p){
    8000224c:	7c9c                	ld	a5,56(s1)
    8000224e:	ff279be3          	bne	a5,s2,80002244 <kwait+0xa8>
        acquire(&pp->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	97bfe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    80002258:	4c9c                	lw	a5,24(s1)
    8000225a:	f94783e3          	beq	a5,s4,800021e0 <kwait+0x44>
        release(&pp->lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	a07fe0ef          	jal	80000c66 <release>
        havekids = 1;
    80002264:	8756                	mv	a4,s5
    80002266:	bff9                	j	80002244 <kwait+0xa8>
    if(!havekids || killed(p)){
    80002268:	cf19                	beqz	a4,80002286 <kwait+0xea>
    8000226a:	854a                	mv	a0,s2
    8000226c:	f07ff0ef          	jal	80002172 <killed>
    80002270:	e919                	bnez	a0,80002286 <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002272:	85e2                	mv	a1,s8
    80002274:	854a                	mv	a0,s2
    80002276:	cc5ff0ef          	jal	80001f3a <sleep>
    havekids = 0;
    8000227a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227c:	00015497          	auipc	s1,0x15
    80002280:	b7c48493          	addi	s1,s1,-1156 # 80016df8 <proc>
    80002284:	b7e1                	j	8000224c <kwait+0xb0>
      release(&wait_lock);
    80002286:	00014517          	auipc	a0,0x14
    8000228a:	75a50513          	addi	a0,a0,1882 # 800169e0 <wait_lock>
    8000228e:	9d9fe0ef          	jal	80000c66 <release>
      return -1;
    80002292:	59fd                	li	s3,-1
    80002294:	b741                	j	80002214 <kwait+0x78>

0000000080002296 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002296:	7179                	addi	sp,sp,-48
    80002298:	f406                	sd	ra,40(sp)
    8000229a:	f022                	sd	s0,32(sp)
    8000229c:	ec26                	sd	s1,24(sp)
    8000229e:	e84a                	sd	s2,16(sp)
    800022a0:	e44e                	sd	s3,8(sp)
    800022a2:	e052                	sd	s4,0(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	84aa                	mv	s1,a0
    800022a8:	892e                	mv	s2,a1
    800022aa:	89b2                	mv	s3,a2
    800022ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022ae:	e48ff0ef          	jal	800018f6 <myproc>
  if(user_dst){
    800022b2:	cc99                	beqz	s1,800022d0 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    800022b4:	86d2                	mv	a3,s4
    800022b6:	864e                	mv	a2,s3
    800022b8:	85ca                	mv	a1,s2
    800022ba:	6928                	ld	a0,80(a0)
    800022bc:	b4eff0ef          	jal	8000160a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800022c0:	70a2                	ld	ra,40(sp)
    800022c2:	7402                	ld	s0,32(sp)
    800022c4:	64e2                	ld	s1,24(sp)
    800022c6:	6942                	ld	s2,16(sp)
    800022c8:	69a2                	ld	s3,8(sp)
    800022ca:	6a02                	ld	s4,0(sp)
    800022cc:	6145                	addi	sp,sp,48
    800022ce:	8082                	ret
    memmove((char *)dst, src, len);
    800022d0:	000a061b          	sext.w	a2,s4
    800022d4:	85ce                	mv	a1,s3
    800022d6:	854a                	mv	a0,s2
    800022d8:	a27fe0ef          	jal	80000cfe <memmove>
    return 0;
    800022dc:	8526                	mv	a0,s1
    800022de:	b7cd                	j	800022c0 <either_copyout+0x2a>

00000000800022e0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	e052                	sd	s4,0(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	892a                	mv	s2,a0
    800022f2:	84ae                	mv	s1,a1
    800022f4:	89b2                	mv	s3,a2
    800022f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022f8:	dfeff0ef          	jal	800018f6 <myproc>
  if(user_src){
    800022fc:	cc99                	beqz	s1,8000231a <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800022fe:	86d2                	mv	a3,s4
    80002300:	864e                	mv	a2,s3
    80002302:	85ca                	mv	a1,s2
    80002304:	6928                	ld	a0,80(a0)
    80002306:	be8ff0ef          	jal	800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000230a:	70a2                	ld	ra,40(sp)
    8000230c:	7402                	ld	s0,32(sp)
    8000230e:	64e2                	ld	s1,24(sp)
    80002310:	6942                	ld	s2,16(sp)
    80002312:	69a2                	ld	s3,8(sp)
    80002314:	6a02                	ld	s4,0(sp)
    80002316:	6145                	addi	sp,sp,48
    80002318:	8082                	ret
    memmove(dst, (char*)src, len);
    8000231a:	000a061b          	sext.w	a2,s4
    8000231e:	85ce                	mv	a1,s3
    80002320:	854a                	mv	a0,s2
    80002322:	9ddfe0ef          	jal	80000cfe <memmove>
    return 0;
    80002326:	8526                	mv	a0,s1
    80002328:	b7cd                	j	8000230a <either_copyin+0x2a>

000000008000232a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000232a:	715d                	addi	sp,sp,-80
    8000232c:	e486                	sd	ra,72(sp)
    8000232e:	e0a2                	sd	s0,64(sp)
    80002330:	fc26                	sd	s1,56(sp)
    80002332:	f84a                	sd	s2,48(sp)
    80002334:	f44e                	sd	s3,40(sp)
    80002336:	f052                	sd	s4,32(sp)
    80002338:	ec56                	sd	s5,24(sp)
    8000233a:	e85a                	sd	s6,16(sp)
    8000233c:	e45e                	sd	s7,8(sp)
    8000233e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002340:	00008517          	auipc	a0,0x8
    80002344:	d3850513          	addi	a0,a0,-712 # 8000a078 <etext+0x78>
    80002348:	9b2fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000234c:	00015497          	auipc	s1,0x15
    80002350:	c0448493          	addi	s1,s1,-1020 # 80016f50 <proc+0x158>
    80002354:	0001a917          	auipc	s2,0x1a
    80002358:	5fc90913          	addi	s2,s2,1532 # 8001c950 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000235c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000235e:	00008997          	auipc	s3,0x8
    80002362:	f2a98993          	addi	s3,s3,-214 # 8000a288 <etext+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    80002366:	00008a97          	auipc	s5,0x8
    8000236a:	f2aa8a93          	addi	s5,s5,-214 # 8000a290 <etext+0x290>
    printf("\n");
    8000236e:	00008a17          	auipc	s4,0x8
    80002372:	d0aa0a13          	addi	s4,s4,-758 # 8000a078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002376:	00008b97          	auipc	s7,0x8
    8000237a:	6e2b8b93          	addi	s7,s7,1762 # 8000aa58 <states.0>
    8000237e:	a829                	j	80002398 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002380:	ed86a583          	lw	a1,-296(a3)
    80002384:	8556                	mv	a0,s5
    80002386:	974fe0ef          	jal	800004fa <printf>
    printf("\n");
    8000238a:	8552                	mv	a0,s4
    8000238c:	96efe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002390:	16848493          	addi	s1,s1,360
    80002394:	03248263          	beq	s1,s2,800023b8 <procdump+0x8e>
    if(p->state == UNUSED)
    80002398:	86a6                	mv	a3,s1
    8000239a:	ec04a783          	lw	a5,-320(s1)
    8000239e:	dbed                	beqz	a5,80002390 <procdump+0x66>
      state = "???";
    800023a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023a2:	fcfb6fe3          	bltu	s6,a5,80002380 <procdump+0x56>
    800023a6:	02079713          	slli	a4,a5,0x20
    800023aa:	01d75793          	srli	a5,a4,0x1d
    800023ae:	97de                	add	a5,a5,s7
    800023b0:	6390                	ld	a2,0(a5)
    800023b2:	f679                	bnez	a2,80002380 <procdump+0x56>
      state = "???";
    800023b4:	864e                	mv	a2,s3
    800023b6:	b7e9                	j	80002380 <procdump+0x56>
  }
}
    800023b8:	60a6                	ld	ra,72(sp)
    800023ba:	6406                	ld	s0,64(sp)
    800023bc:	74e2                	ld	s1,56(sp)
    800023be:	7942                	ld	s2,48(sp)
    800023c0:	79a2                	ld	s3,40(sp)
    800023c2:	7a02                	ld	s4,32(sp)
    800023c4:	6ae2                	ld	s5,24(sp)
    800023c6:	6b42                	ld	s6,16(sp)
    800023c8:	6ba2                	ld	s7,8(sp)
    800023ca:	6161                	addi	sp,sp,80
    800023cc:	8082                	ret

00000000800023ce <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800023ce:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800023d2:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800023d6:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800023d8:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800023da:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800023de:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800023e2:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800023e6:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800023ea:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800023ee:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800023f2:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800023f6:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800023fa:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800023fe:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002402:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002406:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    8000240a:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    8000240c:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    8000240e:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002412:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002416:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    8000241a:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    8000241e:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002422:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002426:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    8000242a:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    8000242e:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002432:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002436:	8082                	ret

0000000080002438 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002438:	1141                	addi	sp,sp,-16
    8000243a:	e406                	sd	ra,8(sp)
    8000243c:	e022                	sd	s0,0(sp)
    8000243e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002440:	00008597          	auipc	a1,0x8
    80002444:	e9058593          	addi	a1,a1,-368 # 8000a2d0 <etext+0x2d0>
    80002448:	0001a517          	auipc	a0,0x1a
    8000244c:	3b050513          	addi	a0,a0,944 # 8001c7f8 <tickslock>
    80002450:	efefe0ef          	jal	80000b4e <initlock>
}
    80002454:	60a2                	ld	ra,8(sp)
    80002456:	6402                	ld	s0,0(sp)
    80002458:	0141                	addi	sp,sp,16
    8000245a:	8082                	ret

000000008000245c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000245c:	1141                	addi	sp,sp,-16
    8000245e:	e422                	sd	s0,8(sp)
    80002460:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002462:	00003797          	auipc	a5,0x3
    80002466:	04e78793          	addi	a5,a5,78 # 800054b0 <kernelvec>
    8000246a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000246e:	6422                	ld	s0,8(sp)
    80002470:	0141                	addi	sp,sp,16
    80002472:	8082                	ret

0000000080002474 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002474:	1141                	addi	sp,sp,-16
    80002476:	e406                	sd	ra,8(sp)
    80002478:	e022                	sd	s0,0(sp)
    8000247a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000247c:	c7aff0ef          	jal	800018f6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002480:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002484:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002486:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000248a:	04000737          	lui	a4,0x4000
    8000248e:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80002490:	0732                	slli	a4,a4,0xc
    80002492:	00007797          	auipc	a5,0x7
    80002496:	b6e78793          	addi	a5,a5,-1170 # 80009000 <_trampoline>
    8000249a:	00007697          	auipc	a3,0x7
    8000249e:	b6668693          	addi	a3,a3,-1178 # 80009000 <_trampoline>
    800024a2:	8f95                	sub	a5,a5,a3
    800024a4:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800024a6:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800024aa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800024ac:	18002773          	csrr	a4,satp
    800024b0:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800024b2:	6d38                	ld	a4,88(a0)
    800024b4:	613c                	ld	a5,64(a0)
    800024b6:	6685                	lui	a3,0x1
    800024b8:	97b6                	add	a5,a5,a3
    800024ba:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800024bc:	6d3c                	ld	a5,88(a0)
    800024be:	00000717          	auipc	a4,0x0
    800024c2:	10470713          	addi	a4,a4,260 # 800025c2 <usertrap>
    800024c6:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800024c8:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800024ca:	8712                	mv	a4,tp
    800024cc:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024ce:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800024d2:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800024d6:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024da:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800024de:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024e0:	6f9c                	ld	a5,24(a5)
    800024e2:	14179073          	csrw	sepc,a5
}
    800024e6:	60a2                	ld	ra,8(sp)
    800024e8:	6402                	ld	s0,0(sp)
    800024ea:	0141                	addi	sp,sp,16
    800024ec:	8082                	ret

00000000800024ee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800024ee:	1101                	addi	sp,sp,-32
    800024f0:	ec06                	sd	ra,24(sp)
    800024f2:	e822                	sd	s0,16(sp)
    800024f4:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800024f6:	bd4ff0ef          	jal	800018ca <cpuid>
    800024fa:	cd11                	beqz	a0,80002516 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    800024fc:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002500:	000f4737          	lui	a4,0xf4
    80002504:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002508:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    8000250a:	14d79073          	csrw	stimecmp,a5
}
    8000250e:	60e2                	ld	ra,24(sp)
    80002510:	6442                	ld	s0,16(sp)
    80002512:	6105                	addi	sp,sp,32
    80002514:	8082                	ret
    80002516:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002518:	0001a497          	auipc	s1,0x1a
    8000251c:	2e048493          	addi	s1,s1,736 # 8001c7f8 <tickslock>
    80002520:	8526                	mv	a0,s1
    80002522:	eacfe0ef          	jal	80000bce <acquire>
    ticks++;
    80002526:	0000c517          	auipc	a0,0xc
    8000252a:	32250513          	addi	a0,a0,802 # 8000e848 <ticks>
    8000252e:	411c                	lw	a5,0(a0)
    80002530:	2785                	addiw	a5,a5,1
    80002532:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002534:	a53ff0ef          	jal	80001f86 <wakeup>
    release(&tickslock);
    80002538:	8526                	mv	a0,s1
    8000253a:	f2cfe0ef          	jal	80000c66 <release>
    8000253e:	64a2                	ld	s1,8(sp)
    80002540:	bf75                	j	800024fc <clockintr+0xe>

0000000080002542 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002542:	1101                	addi	sp,sp,-32
    80002544:	ec06                	sd	ra,24(sp)
    80002546:	e822                	sd	s0,16(sp)
    80002548:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000254a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    8000254e:	57fd                	li	a5,-1
    80002550:	17fe                	slli	a5,a5,0x3f
    80002552:	07a5                	addi	a5,a5,9
    80002554:	00f70c63          	beq	a4,a5,8000256c <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002558:	57fd                	li	a5,-1
    8000255a:	17fe                	slli	a5,a5,0x3f
    8000255c:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    8000255e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    80002560:	04f70d63          	beq	a4,a5,800025ba <devintr+0x78>
  }
}
    80002564:	60e2                	ld	ra,24(sp)
    80002566:	6442                	ld	s0,16(sp)
    80002568:	6105                	addi	sp,sp,32
    8000256a:	8082                	ret
    8000256c:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    8000256e:	7f5020ef          	jal	80005562 <plic_claim>
    80002572:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002574:	47a9                	li	a5,10
    80002576:	00f50c63          	beq	a0,a5,8000258e <devintr+0x4c>
    } else if(irq == VIRTIO0_IRQ){
    8000257a:	4785                	li	a5,1
    8000257c:	02f50163          	beq	a0,a5,8000259e <devintr+0x5c>
    } else if(irq == 2){  // VIRTIO1_IRQ for network
    80002580:	4789                	li	a5,2
    80002582:	02f50163          	beq	a0,a5,800025a4 <devintr+0x62>
    return 1;
    80002586:	4505                	li	a0,1
    } else if(irq){
    80002588:	e08d                	bnez	s1,800025aa <devintr+0x68>
    8000258a:	64a2                	ld	s1,8(sp)
    8000258c:	bfe1                	j	80002564 <devintr+0x22>
      uartintr();
    8000258e:	c22fe0ef          	jal	800009b0 <uartintr>
      plic_complete(irq);
    80002592:	8526                	mv	a0,s1
    80002594:	7ef020ef          	jal	80005582 <plic_complete>
    return 1;
    80002598:	4505                	li	a0,1
    8000259a:	64a2                	ld	s1,8(sp)
    8000259c:	b7e1                	j	80002564 <devintr+0x22>
      virtio_disk_intr();
    8000259e:	48a030ef          	jal	80005a28 <virtio_disk_intr>
    if(irq)
    800025a2:	bfc5                	j	80002592 <devintr+0x50>
      virtio_net_intr();
    800025a4:	498040ef          	jal	80006a3c <virtio_net_intr>
    if(irq)
    800025a8:	b7ed                	j	80002592 <devintr+0x50>
      printf("unexpected interrupt irq=%d\n", irq);
    800025aa:	85a6                	mv	a1,s1
    800025ac:	00008517          	auipc	a0,0x8
    800025b0:	d2c50513          	addi	a0,a0,-724 # 8000a2d8 <etext+0x2d8>
    800025b4:	f47fd0ef          	jal	800004fa <printf>
    if(irq)
    800025b8:	bfe9                	j	80002592 <devintr+0x50>
    clockintr();
    800025ba:	f35ff0ef          	jal	800024ee <clockintr>
    return 2;
    800025be:	4509                	li	a0,2
    800025c0:	b755                	j	80002564 <devintr+0x22>

00000000800025c2 <usertrap>:
{
    800025c2:	1101                	addi	sp,sp,-32
    800025c4:	ec06                	sd	ra,24(sp)
    800025c6:	e822                	sd	s0,16(sp)
    800025c8:	e426                	sd	s1,8(sp)
    800025ca:	e04a                	sd	s2,0(sp)
    800025cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800025d2:	1007f793          	andi	a5,a5,256
    800025d6:	eba5                	bnez	a5,80002646 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025d8:	00003797          	auipc	a5,0x3
    800025dc:	ed878793          	addi	a5,a5,-296 # 800054b0 <kernelvec>
    800025e0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800025e4:	b12ff0ef          	jal	800018f6 <myproc>
    800025e8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800025ea:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025ec:	14102773          	csrr	a4,sepc
    800025f0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025f2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800025f6:	47a1                	li	a5,8
    800025f8:	04f70d63          	beq	a4,a5,80002652 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800025fc:	f47ff0ef          	jal	80002542 <devintr>
    80002600:	892a                	mv	s2,a0
    80002602:	e945                	bnez	a0,800026b2 <usertrap+0xf0>
    80002604:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002608:	47bd                	li	a5,15
    8000260a:	08f70863          	beq	a4,a5,8000269a <usertrap+0xd8>
    8000260e:	14202773          	csrr	a4,scause
    80002612:	47b5                	li	a5,13
    80002614:	08f70363          	beq	a4,a5,8000269a <usertrap+0xd8>
    80002618:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000261c:	5890                	lw	a2,48(s1)
    8000261e:	00008517          	auipc	a0,0x8
    80002622:	cfa50513          	addi	a0,a0,-774 # 8000a318 <etext+0x318>
    80002626:	ed5fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000262a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000262e:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002632:	00008517          	auipc	a0,0x8
    80002636:	d1650513          	addi	a0,a0,-746 # 8000a348 <etext+0x348>
    8000263a:	ec1fd0ef          	jal	800004fa <printf>
    setkilled(p);
    8000263e:	8526                	mv	a0,s1
    80002640:	b0fff0ef          	jal	8000214e <setkilled>
    80002644:	a035                	j	80002670 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002646:	00008517          	auipc	a0,0x8
    8000264a:	cb250513          	addi	a0,a0,-846 # 8000a2f8 <etext+0x2f8>
    8000264e:	992fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    80002652:	b21ff0ef          	jal	80002172 <killed>
    80002656:	ed15                	bnez	a0,80002692 <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002658:	6cb8                	ld	a4,88(s1)
    8000265a:	6f1c                	ld	a5,24(a4)
    8000265c:	0791                	addi	a5,a5,4
    8000265e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002660:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002664:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002668:	10079073          	csrw	sstatus,a5
    syscall();
    8000266c:	246000ef          	jal	800028b2 <syscall>
  if(killed(p))
    80002670:	8526                	mv	a0,s1
    80002672:	b01ff0ef          	jal	80002172 <killed>
    80002676:	e139                	bnez	a0,800026bc <usertrap+0xfa>
  prepare_return();
    80002678:	dfdff0ef          	jal	80002474 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000267c:	68a8                	ld	a0,80(s1)
    8000267e:	8131                	srli	a0,a0,0xc
    80002680:	57fd                	li	a5,-1
    80002682:	17fe                	slli	a5,a5,0x3f
    80002684:	8d5d                	or	a0,a0,a5
}
    80002686:	60e2                	ld	ra,24(sp)
    80002688:	6442                	ld	s0,16(sp)
    8000268a:	64a2                	ld	s1,8(sp)
    8000268c:	6902                	ld	s2,0(sp)
    8000268e:	6105                	addi	sp,sp,32
    80002690:	8082                	ret
      kexit(-1);
    80002692:	557d                	li	a0,-1
    80002694:	9b3ff0ef          	jal	80002046 <kexit>
    80002698:	b7c1                	j	80002658 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000269a:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000269e:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800026a2:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    800026a4:	00163613          	seqz	a2,a2
    800026a8:	68a8                	ld	a0,80(s1)
    800026aa:	edffe0ef          	jal	80001588 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800026ae:	f169                	bnez	a0,80002670 <usertrap+0xae>
    800026b0:	b7a5                	j	80002618 <usertrap+0x56>
  if(killed(p))
    800026b2:	8526                	mv	a0,s1
    800026b4:	abfff0ef          	jal	80002172 <killed>
    800026b8:	c511                	beqz	a0,800026c4 <usertrap+0x102>
    800026ba:	a011                	j	800026be <usertrap+0xfc>
    800026bc:	4901                	li	s2,0
    kexit(-1);
    800026be:	557d                	li	a0,-1
    800026c0:	987ff0ef          	jal	80002046 <kexit>
  if(which_dev == 2)
    800026c4:	4789                	li	a5,2
    800026c6:	faf919e3          	bne	s2,a5,80002678 <usertrap+0xb6>
    yield();
    800026ca:	845ff0ef          	jal	80001f0e <yield>
    800026ce:	b76d                	j	80002678 <usertrap+0xb6>

00000000800026d0 <kerneltrap>:
{
    800026d0:	7179                	addi	sp,sp,-48
    800026d2:	f406                	sd	ra,40(sp)
    800026d4:	f022                	sd	s0,32(sp)
    800026d6:	ec26                	sd	s1,24(sp)
    800026d8:	e84a                	sd	s2,16(sp)
    800026da:	e44e                	sd	s3,8(sp)
    800026dc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026de:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026e6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800026ea:	1004f793          	andi	a5,s1,256
    800026ee:	c795                	beqz	a5,8000271a <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026f4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800026f6:	eb85                	bnez	a5,80002726 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800026f8:	e4bff0ef          	jal	80002542 <devintr>
    800026fc:	c91d                	beqz	a0,80002732 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    800026fe:	4789                	li	a5,2
    80002700:	04f50a63          	beq	a0,a5,80002754 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002704:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002708:	10049073          	csrw	sstatus,s1
}
    8000270c:	70a2                	ld	ra,40(sp)
    8000270e:	7402                	ld	s0,32(sp)
    80002710:	64e2                	ld	s1,24(sp)
    80002712:	6942                	ld	s2,16(sp)
    80002714:	69a2                	ld	s3,8(sp)
    80002716:	6145                	addi	sp,sp,48
    80002718:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000271a:	00008517          	auipc	a0,0x8
    8000271e:	c5650513          	addi	a0,a0,-938 # 8000a370 <etext+0x370>
    80002722:	8befe0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002726:	00008517          	auipc	a0,0x8
    8000272a:	c7250513          	addi	a0,a0,-910 # 8000a398 <etext+0x398>
    8000272e:	8b2fe0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002732:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002736:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000273a:	85ce                	mv	a1,s3
    8000273c:	00008517          	auipc	a0,0x8
    80002740:	c7c50513          	addi	a0,a0,-900 # 8000a3b8 <etext+0x3b8>
    80002744:	db7fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    80002748:	00008517          	auipc	a0,0x8
    8000274c:	c9850513          	addi	a0,a0,-872 # 8000a3e0 <etext+0x3e0>
    80002750:	890fe0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    80002754:	9a2ff0ef          	jal	800018f6 <myproc>
    80002758:	d555                	beqz	a0,80002704 <kerneltrap+0x34>
    yield();
    8000275a:	fb4ff0ef          	jal	80001f0e <yield>
    8000275e:	b75d                	j	80002704 <kerneltrap+0x34>

0000000080002760 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002760:	1101                	addi	sp,sp,-32
    80002762:	ec06                	sd	ra,24(sp)
    80002764:	e822                	sd	s0,16(sp)
    80002766:	e426                	sd	s1,8(sp)
    80002768:	1000                	addi	s0,sp,32
    8000276a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000276c:	98aff0ef          	jal	800018f6 <myproc>
  switch (n) {
    80002770:	4795                	li	a5,5
    80002772:	0497e163          	bltu	a5,s1,800027b4 <argraw+0x54>
    80002776:	048a                	slli	s1,s1,0x2
    80002778:	00008717          	auipc	a4,0x8
    8000277c:	31070713          	addi	a4,a4,784 # 8000aa88 <states.0+0x30>
    80002780:	94ba                	add	s1,s1,a4
    80002782:	409c                	lw	a5,0(s1)
    80002784:	97ba                	add	a5,a5,a4
    80002786:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002788:	6d3c                	ld	a5,88(a0)
    8000278a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000278c:	60e2                	ld	ra,24(sp)
    8000278e:	6442                	ld	s0,16(sp)
    80002790:	64a2                	ld	s1,8(sp)
    80002792:	6105                	addi	sp,sp,32
    80002794:	8082                	ret
    return p->trapframe->a1;
    80002796:	6d3c                	ld	a5,88(a0)
    80002798:	7fa8                	ld	a0,120(a5)
    8000279a:	bfcd                	j	8000278c <argraw+0x2c>
    return p->trapframe->a2;
    8000279c:	6d3c                	ld	a5,88(a0)
    8000279e:	63c8                	ld	a0,128(a5)
    800027a0:	b7f5                	j	8000278c <argraw+0x2c>
    return p->trapframe->a3;
    800027a2:	6d3c                	ld	a5,88(a0)
    800027a4:	67c8                	ld	a0,136(a5)
    800027a6:	b7dd                	j	8000278c <argraw+0x2c>
    return p->trapframe->a4;
    800027a8:	6d3c                	ld	a5,88(a0)
    800027aa:	6bc8                	ld	a0,144(a5)
    800027ac:	b7c5                	j	8000278c <argraw+0x2c>
    return p->trapframe->a5;
    800027ae:	6d3c                	ld	a5,88(a0)
    800027b0:	6fc8                	ld	a0,152(a5)
    800027b2:	bfe9                	j	8000278c <argraw+0x2c>
  panic("argraw");
    800027b4:	00008517          	auipc	a0,0x8
    800027b8:	c3c50513          	addi	a0,a0,-964 # 8000a3f0 <etext+0x3f0>
    800027bc:	824fe0ef          	jal	800007e0 <panic>

00000000800027c0 <fetchaddr>:
{
    800027c0:	1101                	addi	sp,sp,-32
    800027c2:	ec06                	sd	ra,24(sp)
    800027c4:	e822                	sd	s0,16(sp)
    800027c6:	e426                	sd	s1,8(sp)
    800027c8:	e04a                	sd	s2,0(sp)
    800027ca:	1000                	addi	s0,sp,32
    800027cc:	84aa                	mv	s1,a0
    800027ce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800027d0:	926ff0ef          	jal	800018f6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800027d4:	653c                	ld	a5,72(a0)
    800027d6:	02f4f663          	bgeu	s1,a5,80002802 <fetchaddr+0x42>
    800027da:	00848713          	addi	a4,s1,8
    800027de:	02e7e463          	bltu	a5,a4,80002806 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800027e2:	46a1                	li	a3,8
    800027e4:	8626                	mv	a2,s1
    800027e6:	85ca                	mv	a1,s2
    800027e8:	6928                	ld	a0,80(a0)
    800027ea:	f05fe0ef          	jal	800016ee <copyin>
    800027ee:	00a03533          	snez	a0,a0
    800027f2:	40a00533          	neg	a0,a0
}
    800027f6:	60e2                	ld	ra,24(sp)
    800027f8:	6442                	ld	s0,16(sp)
    800027fa:	64a2                	ld	s1,8(sp)
    800027fc:	6902                	ld	s2,0(sp)
    800027fe:	6105                	addi	sp,sp,32
    80002800:	8082                	ret
    return -1;
    80002802:	557d                	li	a0,-1
    80002804:	bfcd                	j	800027f6 <fetchaddr+0x36>
    80002806:	557d                	li	a0,-1
    80002808:	b7fd                	j	800027f6 <fetchaddr+0x36>

000000008000280a <fetchstr>:
{
    8000280a:	7179                	addi	sp,sp,-48
    8000280c:	f406                	sd	ra,40(sp)
    8000280e:	f022                	sd	s0,32(sp)
    80002810:	ec26                	sd	s1,24(sp)
    80002812:	e84a                	sd	s2,16(sp)
    80002814:	e44e                	sd	s3,8(sp)
    80002816:	1800                	addi	s0,sp,48
    80002818:	892a                	mv	s2,a0
    8000281a:	84ae                	mv	s1,a1
    8000281c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000281e:	8d8ff0ef          	jal	800018f6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002822:	86ce                	mv	a3,s3
    80002824:	864a                	mv	a2,s2
    80002826:	85a6                	mv	a1,s1
    80002828:	6928                	ld	a0,80(a0)
    8000282a:	c87fe0ef          	jal	800014b0 <copyinstr>
    8000282e:	00054c63          	bltz	a0,80002846 <fetchstr+0x3c>
  return strlen(buf);
    80002832:	8526                	mv	a0,s1
    80002834:	ddefe0ef          	jal	80000e12 <strlen>
}
    80002838:	70a2                	ld	ra,40(sp)
    8000283a:	7402                	ld	s0,32(sp)
    8000283c:	64e2                	ld	s1,24(sp)
    8000283e:	6942                	ld	s2,16(sp)
    80002840:	69a2                	ld	s3,8(sp)
    80002842:	6145                	addi	sp,sp,48
    80002844:	8082                	ret
    return -1;
    80002846:	557d                	li	a0,-1
    80002848:	bfc5                	j	80002838 <fetchstr+0x2e>

000000008000284a <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	e426                	sd	s1,8(sp)
    80002852:	1000                	addi	s0,sp,32
    80002854:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002856:	f0bff0ef          	jal	80002760 <argraw>
    8000285a:	c088                	sw	a0,0(s1)
}
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6105                	addi	sp,sp,32
    80002864:	8082                	ret

0000000080002866 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002866:	1101                	addi	sp,sp,-32
    80002868:	ec06                	sd	ra,24(sp)
    8000286a:	e822                	sd	s0,16(sp)
    8000286c:	e426                	sd	s1,8(sp)
    8000286e:	1000                	addi	s0,sp,32
    80002870:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002872:	eefff0ef          	jal	80002760 <argraw>
    80002876:	e088                	sd	a0,0(s1)
}
    80002878:	60e2                	ld	ra,24(sp)
    8000287a:	6442                	ld	s0,16(sp)
    8000287c:	64a2                	ld	s1,8(sp)
    8000287e:	6105                	addi	sp,sp,32
    80002880:	8082                	ret

0000000080002882 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002882:	7179                	addi	sp,sp,-48
    80002884:	f406                	sd	ra,40(sp)
    80002886:	f022                	sd	s0,32(sp)
    80002888:	ec26                	sd	s1,24(sp)
    8000288a:	e84a                	sd	s2,16(sp)
    8000288c:	1800                	addi	s0,sp,48
    8000288e:	84ae                	mv	s1,a1
    80002890:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002892:	fd840593          	addi	a1,s0,-40
    80002896:	fd1ff0ef          	jal	80002866 <argaddr>
  return fetchstr(addr, buf, max);
    8000289a:	864a                	mv	a2,s2
    8000289c:	85a6                	mv	a1,s1
    8000289e:	fd843503          	ld	a0,-40(s0)
    800028a2:	f69ff0ef          	jal	8000280a <fetchstr>
}
    800028a6:	70a2                	ld	ra,40(sp)
    800028a8:	7402                	ld	s0,32(sp)
    800028aa:	64e2                	ld	s1,24(sp)
    800028ac:	6942                	ld	s2,16(sp)
    800028ae:	6145                	addi	sp,sp,48
    800028b0:	8082                	ret

00000000800028b2 <syscall>:
[SYS_umount]  sys_umount,
};

void
syscall(void)
{
    800028b2:	1101                	addi	sp,sp,-32
    800028b4:	ec06                	sd	ra,24(sp)
    800028b6:	e822                	sd	s0,16(sp)
    800028b8:	e426                	sd	s1,8(sp)
    800028ba:	e04a                	sd	s2,0(sp)
    800028bc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800028be:	838ff0ef          	jal	800018f6 <myproc>
    800028c2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800028c4:	05853903          	ld	s2,88(a0)
    800028c8:	0a893783          	ld	a5,168(s2)
    800028cc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800028d0:	37fd                	addiw	a5,a5,-1
    800028d2:	4759                	li	a4,22
    800028d4:	00f76f63          	bltu	a4,a5,800028f2 <syscall+0x40>
    800028d8:	00369713          	slli	a4,a3,0x3
    800028dc:	00008797          	auipc	a5,0x8
    800028e0:	1c478793          	addi	a5,a5,452 # 8000aaa0 <syscalls>
    800028e4:	97ba                	add	a5,a5,a4
    800028e6:	639c                	ld	a5,0(a5)
    800028e8:	c789                	beqz	a5,800028f2 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800028ea:	9782                	jalr	a5
    800028ec:	06a93823          	sd	a0,112(s2)
    800028f0:	a829                	j	8000290a <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800028f2:	15848613          	addi	a2,s1,344
    800028f6:	588c                	lw	a1,48(s1)
    800028f8:	00008517          	auipc	a0,0x8
    800028fc:	b0050513          	addi	a0,a0,-1280 # 8000a3f8 <etext+0x3f8>
    80002900:	bfbfd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002904:	6cbc                	ld	a5,88(s1)
    80002906:	577d                	li	a4,-1
    80002908:	fbb8                	sd	a4,112(a5)
  }
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6902                	ld	s2,0(sp)
    80002912:	6105                	addi	sp,sp,32
    80002914:	8082                	ret

0000000080002916 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002916:	1101                	addi	sp,sp,-32
    80002918:	ec06                	sd	ra,24(sp)
    8000291a:	e822                	sd	s0,16(sp)
    8000291c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000291e:	fec40593          	addi	a1,s0,-20
    80002922:	4501                	li	a0,0
    80002924:	f27ff0ef          	jal	8000284a <argint>
  kexit(n);
    80002928:	fec42503          	lw	a0,-20(s0)
    8000292c:	f1aff0ef          	jal	80002046 <kexit>
  return 0;  // not reached
}
    80002930:	4501                	li	a0,0
    80002932:	60e2                	ld	ra,24(sp)
    80002934:	6442                	ld	s0,16(sp)
    80002936:	6105                	addi	sp,sp,32
    80002938:	8082                	ret

000000008000293a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000293a:	1141                	addi	sp,sp,-16
    8000293c:	e406                	sd	ra,8(sp)
    8000293e:	e022                	sd	s0,0(sp)
    80002940:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002942:	fb5fe0ef          	jal	800018f6 <myproc>
}
    80002946:	5908                	lw	a0,48(a0)
    80002948:	60a2                	ld	ra,8(sp)
    8000294a:	6402                	ld	s0,0(sp)
    8000294c:	0141                	addi	sp,sp,16
    8000294e:	8082                	ret

0000000080002950 <sys_fork>:

uint64
sys_fork(void)
{
    80002950:	1141                	addi	sp,sp,-16
    80002952:	e406                	sd	ra,8(sp)
    80002954:	e022                	sd	s0,0(sp)
    80002956:	0800                	addi	s0,sp,16
  return kfork();
    80002958:	b3cff0ef          	jal	80001c94 <kfork>
}
    8000295c:	60a2                	ld	ra,8(sp)
    8000295e:	6402                	ld	s0,0(sp)
    80002960:	0141                	addi	sp,sp,16
    80002962:	8082                	ret

0000000080002964 <sys_wait>:

uint64
sys_wait(void)
{
    80002964:	1101                	addi	sp,sp,-32
    80002966:	ec06                	sd	ra,24(sp)
    80002968:	e822                	sd	s0,16(sp)
    8000296a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000296c:	fe840593          	addi	a1,s0,-24
    80002970:	4501                	li	a0,0
    80002972:	ef5ff0ef          	jal	80002866 <argaddr>
  return kwait(p);
    80002976:	fe843503          	ld	a0,-24(s0)
    8000297a:	823ff0ef          	jal	8000219c <kwait>
}
    8000297e:	60e2                	ld	ra,24(sp)
    80002980:	6442                	ld	s0,16(sp)
    80002982:	6105                	addi	sp,sp,32
    80002984:	8082                	ret

0000000080002986 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002990:	fd840593          	addi	a1,s0,-40
    80002994:	4501                	li	a0,0
    80002996:	eb5ff0ef          	jal	8000284a <argint>
  argint(1, &t);
    8000299a:	fdc40593          	addi	a1,s0,-36
    8000299e:	4505                	li	a0,1
    800029a0:	eabff0ef          	jal	8000284a <argint>
  addr = myproc()->sz;
    800029a4:	f53fe0ef          	jal	800018f6 <myproc>
    800029a8:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    800029aa:	fdc42703          	lw	a4,-36(s0)
    800029ae:	4785                	li	a5,1
    800029b0:	02f70763          	beq	a4,a5,800029de <sys_sbrk+0x58>
    800029b4:	fd842783          	lw	a5,-40(s0)
    800029b8:	0207c363          	bltz	a5,800029de <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    800029bc:	97a6                	add	a5,a5,s1
    800029be:	0297ee63          	bltu	a5,s1,800029fa <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    800029c2:	02000737          	lui	a4,0x2000
    800029c6:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    800029c8:	0736                	slli	a4,a4,0xd
    800029ca:	02f76a63          	bltu	a4,a5,800029fe <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    800029ce:	f29fe0ef          	jal	800018f6 <myproc>
    800029d2:	fd842703          	lw	a4,-40(s0)
    800029d6:	653c                	ld	a5,72(a0)
    800029d8:	97ba                	add	a5,a5,a4
    800029da:	e53c                	sd	a5,72(a0)
    800029dc:	a039                	j	800029ea <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    800029de:	fd842503          	lw	a0,-40(s0)
    800029e2:	a50ff0ef          	jal	80001c32 <growproc>
    800029e6:	00054863          	bltz	a0,800029f6 <sys_sbrk+0x70>
  }
  return addr;
}
    800029ea:	8526                	mv	a0,s1
    800029ec:	70a2                	ld	ra,40(sp)
    800029ee:	7402                	ld	s0,32(sp)
    800029f0:	64e2                	ld	s1,24(sp)
    800029f2:	6145                	addi	sp,sp,48
    800029f4:	8082                	ret
      return -1;
    800029f6:	54fd                	li	s1,-1
    800029f8:	bfcd                	j	800029ea <sys_sbrk+0x64>
      return -1;
    800029fa:	54fd                	li	s1,-1
    800029fc:	b7fd                	j	800029ea <sys_sbrk+0x64>
      return -1;
    800029fe:	54fd                	li	s1,-1
    80002a00:	b7ed                	j	800029ea <sys_sbrk+0x64>

0000000080002a02 <sys_pause>:

uint64
sys_pause(void)
{
    80002a02:	7139                	addi	sp,sp,-64
    80002a04:	fc06                	sd	ra,56(sp)
    80002a06:	f822                	sd	s0,48(sp)
    80002a08:	f04a                	sd	s2,32(sp)
    80002a0a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002a0c:	fcc40593          	addi	a1,s0,-52
    80002a10:	4501                	li	a0,0
    80002a12:	e39ff0ef          	jal	8000284a <argint>
  if(n < 0)
    80002a16:	fcc42783          	lw	a5,-52(s0)
    80002a1a:	0607c763          	bltz	a5,80002a88 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002a1e:	0001a517          	auipc	a0,0x1a
    80002a22:	dda50513          	addi	a0,a0,-550 # 8001c7f8 <tickslock>
    80002a26:	9a8fe0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002a2a:	0000c917          	auipc	s2,0xc
    80002a2e:	e1e92903          	lw	s2,-482(s2) # 8000e848 <ticks>
  while(ticks - ticks0 < n){
    80002a32:	fcc42783          	lw	a5,-52(s0)
    80002a36:	cf8d                	beqz	a5,80002a70 <sys_pause+0x6e>
    80002a38:	f426                	sd	s1,40(sp)
    80002a3a:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a3c:	0001a997          	auipc	s3,0x1a
    80002a40:	dbc98993          	addi	s3,s3,-580 # 8001c7f8 <tickslock>
    80002a44:	0000c497          	auipc	s1,0xc
    80002a48:	e0448493          	addi	s1,s1,-508 # 8000e848 <ticks>
    if(killed(myproc())){
    80002a4c:	eabfe0ef          	jal	800018f6 <myproc>
    80002a50:	f22ff0ef          	jal	80002172 <killed>
    80002a54:	ed0d                	bnez	a0,80002a8e <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002a56:	85ce                	mv	a1,s3
    80002a58:	8526                	mv	a0,s1
    80002a5a:	ce0ff0ef          	jal	80001f3a <sleep>
  while(ticks - ticks0 < n){
    80002a5e:	409c                	lw	a5,0(s1)
    80002a60:	412787bb          	subw	a5,a5,s2
    80002a64:	fcc42703          	lw	a4,-52(s0)
    80002a68:	fee7e2e3          	bltu	a5,a4,80002a4c <sys_pause+0x4a>
    80002a6c:	74a2                	ld	s1,40(sp)
    80002a6e:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002a70:	0001a517          	auipc	a0,0x1a
    80002a74:	d8850513          	addi	a0,a0,-632 # 8001c7f8 <tickslock>
    80002a78:	9eefe0ef          	jal	80000c66 <release>
  return 0;
    80002a7c:	4501                	li	a0,0
}
    80002a7e:	70e2                	ld	ra,56(sp)
    80002a80:	7442                	ld	s0,48(sp)
    80002a82:	7902                	ld	s2,32(sp)
    80002a84:	6121                	addi	sp,sp,64
    80002a86:	8082                	ret
    n = 0;
    80002a88:	fc042623          	sw	zero,-52(s0)
    80002a8c:	bf49                	j	80002a1e <sys_pause+0x1c>
      release(&tickslock);
    80002a8e:	0001a517          	auipc	a0,0x1a
    80002a92:	d6a50513          	addi	a0,a0,-662 # 8001c7f8 <tickslock>
    80002a96:	9d0fe0ef          	jal	80000c66 <release>
      return -1;
    80002a9a:	557d                	li	a0,-1
    80002a9c:	74a2                	ld	s1,40(sp)
    80002a9e:	69e2                	ld	s3,24(sp)
    80002aa0:	bff9                	j	80002a7e <sys_pause+0x7c>

0000000080002aa2 <sys_kill>:

uint64
sys_kill(void)
{
    80002aa2:	1101                	addi	sp,sp,-32
    80002aa4:	ec06                	sd	ra,24(sp)
    80002aa6:	e822                	sd	s0,16(sp)
    80002aa8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002aaa:	fec40593          	addi	a1,s0,-20
    80002aae:	4501                	li	a0,0
    80002ab0:	d9bff0ef          	jal	8000284a <argint>
  return kkill(pid);
    80002ab4:	fec42503          	lw	a0,-20(s0)
    80002ab8:	e30ff0ef          	jal	800020e8 <kkill>
}
    80002abc:	60e2                	ld	ra,24(sp)
    80002abe:	6442                	ld	s0,16(sp)
    80002ac0:	6105                	addi	sp,sp,32
    80002ac2:	8082                	ret

0000000080002ac4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ac4:	1101                	addi	sp,sp,-32
    80002ac6:	ec06                	sd	ra,24(sp)
    80002ac8:	e822                	sd	s0,16(sp)
    80002aca:	e426                	sd	s1,8(sp)
    80002acc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ace:	0001a517          	auipc	a0,0x1a
    80002ad2:	d2a50513          	addi	a0,a0,-726 # 8001c7f8 <tickslock>
    80002ad6:	8f8fe0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002ada:	0000c497          	auipc	s1,0xc
    80002ade:	d6e4a483          	lw	s1,-658(s1) # 8000e848 <ticks>
  release(&tickslock);
    80002ae2:	0001a517          	auipc	a0,0x1a
    80002ae6:	d1650513          	addi	a0,a0,-746 # 8001c7f8 <tickslock>
    80002aea:	97cfe0ef          	jal	80000c66 <release>
  return xticks;
}
    80002aee:	02049513          	slli	a0,s1,0x20
    80002af2:	9101                	srli	a0,a0,0x20
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002afe:	7179                	addi	sp,sp,-48
    80002b00:	f406                	sd	ra,40(sp)
    80002b02:	f022                	sd	s0,32(sp)
    80002b04:	ec26                	sd	s1,24(sp)
    80002b06:	e84a                	sd	s2,16(sp)
    80002b08:	e44e                	sd	s3,8(sp)
    80002b0a:	e052                	sd	s4,0(sp)
    80002b0c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002b0e:	00008597          	auipc	a1,0x8
    80002b12:	90a58593          	addi	a1,a1,-1782 # 8000a418 <etext+0x418>
    80002b16:	0001a517          	auipc	a0,0x1a
    80002b1a:	cfa50513          	addi	a0,a0,-774 # 8001c810 <bcache>
    80002b1e:	830fe0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002b22:	00022797          	auipc	a5,0x22
    80002b26:	cee78793          	addi	a5,a5,-786 # 80024810 <bcache+0x8000>
    80002b2a:	00022717          	auipc	a4,0x22
    80002b2e:	f4e70713          	addi	a4,a4,-178 # 80024a78 <bcache+0x8268>
    80002b32:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002b36:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b3a:	0001a497          	auipc	s1,0x1a
    80002b3e:	cee48493          	addi	s1,s1,-786 # 8001c828 <bcache+0x18>
    b->next = bcache.head.next;
    80002b42:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002b44:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002b46:	00008a17          	auipc	s4,0x8
    80002b4a:	8daa0a13          	addi	s4,s4,-1830 # 8000a420 <etext+0x420>
    b->next = bcache.head.next;
    80002b4e:	2b893783          	ld	a5,696(s2)
    80002b52:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002b54:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b58:	85d2                	mv	a1,s4
    80002b5a:	01048513          	addi	a0,s1,16
    80002b5e:	322010ef          	jal	80003e80 <initsleeplock>
    bcache.head.next->prev = b;
    80002b62:	2b893783          	ld	a5,696(s2)
    80002b66:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b68:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b6c:	45848493          	addi	s1,s1,1112
    80002b70:	fd349fe3          	bne	s1,s3,80002b4e <binit+0x50>
  }
}
    80002b74:	70a2                	ld	ra,40(sp)
    80002b76:	7402                	ld	s0,32(sp)
    80002b78:	64e2                	ld	s1,24(sp)
    80002b7a:	6942                	ld	s2,16(sp)
    80002b7c:	69a2                	ld	s3,8(sp)
    80002b7e:	6a02                	ld	s4,0(sp)
    80002b80:	6145                	addi	sp,sp,48
    80002b82:	8082                	ret

0000000080002b84 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002b84:	7179                	addi	sp,sp,-48
    80002b86:	f406                	sd	ra,40(sp)
    80002b88:	f022                	sd	s0,32(sp)
    80002b8a:	ec26                	sd	s1,24(sp)
    80002b8c:	e84a                	sd	s2,16(sp)
    80002b8e:	e44e                	sd	s3,8(sp)
    80002b90:	1800                	addi	s0,sp,48
    80002b92:	892a                	mv	s2,a0
    80002b94:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002b96:	0001a517          	auipc	a0,0x1a
    80002b9a:	c7a50513          	addi	a0,a0,-902 # 8001c810 <bcache>
    80002b9e:	830fe0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ba2:	00022497          	auipc	s1,0x22
    80002ba6:	f264b483          	ld	s1,-218(s1) # 80024ac8 <bcache+0x82b8>
    80002baa:	00022797          	auipc	a5,0x22
    80002bae:	ece78793          	addi	a5,a5,-306 # 80024a78 <bcache+0x8268>
    80002bb2:	02f48b63          	beq	s1,a5,80002be8 <bread+0x64>
    80002bb6:	873e                	mv	a4,a5
    80002bb8:	a021                	j	80002bc0 <bread+0x3c>
    80002bba:	68a4                	ld	s1,80(s1)
    80002bbc:	02e48663          	beq	s1,a4,80002be8 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002bc0:	449c                	lw	a5,8(s1)
    80002bc2:	ff279ce3          	bne	a5,s2,80002bba <bread+0x36>
    80002bc6:	44dc                	lw	a5,12(s1)
    80002bc8:	ff3799e3          	bne	a5,s3,80002bba <bread+0x36>
      b->refcnt++;
    80002bcc:	40bc                	lw	a5,64(s1)
    80002bce:	2785                	addiw	a5,a5,1
    80002bd0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bd2:	0001a517          	auipc	a0,0x1a
    80002bd6:	c3e50513          	addi	a0,a0,-962 # 8001c810 <bcache>
    80002bda:	88cfe0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002bde:	01048513          	addi	a0,s1,16
    80002be2:	2d4010ef          	jal	80003eb6 <acquiresleep>
      return b;
    80002be6:	a889                	j	80002c38 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002be8:	00022497          	auipc	s1,0x22
    80002bec:	ed84b483          	ld	s1,-296(s1) # 80024ac0 <bcache+0x82b0>
    80002bf0:	00022797          	auipc	a5,0x22
    80002bf4:	e8878793          	addi	a5,a5,-376 # 80024a78 <bcache+0x8268>
    80002bf8:	00f48863          	beq	s1,a5,80002c08 <bread+0x84>
    80002bfc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002bfe:	40bc                	lw	a5,64(s1)
    80002c00:	cb91                	beqz	a5,80002c14 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c02:	64a4                	ld	s1,72(s1)
    80002c04:	fee49de3          	bne	s1,a4,80002bfe <bread+0x7a>
  panic("bget: no buffers");
    80002c08:	00008517          	auipc	a0,0x8
    80002c0c:	82050513          	addi	a0,a0,-2016 # 8000a428 <etext+0x428>
    80002c10:	bd1fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002c14:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002c18:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002c1c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002c20:	4785                	li	a5,1
    80002c22:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002c24:	0001a517          	auipc	a0,0x1a
    80002c28:	bec50513          	addi	a0,a0,-1044 # 8001c810 <bcache>
    80002c2c:	83afe0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002c30:	01048513          	addi	a0,s1,16
    80002c34:	282010ef          	jal	80003eb6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002c38:	409c                	lw	a5,0(s1)
    80002c3a:	cb89                	beqz	a5,80002c4c <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002c3c:	8526                	mv	a0,s1
    80002c3e:	70a2                	ld	ra,40(sp)
    80002c40:	7402                	ld	s0,32(sp)
    80002c42:	64e2                	ld	s1,24(sp)
    80002c44:	6942                	ld	s2,16(sp)
    80002c46:	69a2                	ld	s3,8(sp)
    80002c48:	6145                	addi	sp,sp,48
    80002c4a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002c4c:	4581                	li	a1,0
    80002c4e:	8526                	mv	a0,s1
    80002c50:	3c7020ef          	jal	80005816 <virtio_disk_rw>
    b->valid = 1;
    80002c54:	4785                	li	a5,1
    80002c56:	c09c                	sw	a5,0(s1)
  return b;
    80002c58:	b7d5                	j	80002c3c <bread+0xb8>

0000000080002c5a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	1000                	addi	s0,sp,32
    80002c64:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c66:	0541                	addi	a0,a0,16
    80002c68:	2cc010ef          	jal	80003f34 <holdingsleep>
    80002c6c:	c911                	beqz	a0,80002c80 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002c6e:	4585                	li	a1,1
    80002c70:	8526                	mv	a0,s1
    80002c72:	3a5020ef          	jal	80005816 <virtio_disk_rw>
}
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	64a2                	ld	s1,8(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret
    panic("bwrite");
    80002c80:	00007517          	auipc	a0,0x7
    80002c84:	7c050513          	addi	a0,a0,1984 # 8000a440 <etext+0x440>
    80002c88:	b59fd0ef          	jal	800007e0 <panic>

0000000080002c8c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	e426                	sd	s1,8(sp)
    80002c94:	e04a                	sd	s2,0(sp)
    80002c96:	1000                	addi	s0,sp,32
    80002c98:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c9a:	01050913          	addi	s2,a0,16
    80002c9e:	854a                	mv	a0,s2
    80002ca0:	294010ef          	jal	80003f34 <holdingsleep>
    80002ca4:	c135                	beqz	a0,80002d08 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002ca6:	854a                	mv	a0,s2
    80002ca8:	254010ef          	jal	80003efc <releasesleep>

  acquire(&bcache.lock);
    80002cac:	0001a517          	auipc	a0,0x1a
    80002cb0:	b6450513          	addi	a0,a0,-1180 # 8001c810 <bcache>
    80002cb4:	f1bfd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002cb8:	40bc                	lw	a5,64(s1)
    80002cba:	37fd                	addiw	a5,a5,-1
    80002cbc:	0007871b          	sext.w	a4,a5
    80002cc0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002cc2:	e71d                	bnez	a4,80002cf0 <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002cc4:	68b8                	ld	a4,80(s1)
    80002cc6:	64bc                	ld	a5,72(s1)
    80002cc8:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002cca:	68b8                	ld	a4,80(s1)
    80002ccc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002cce:	00022797          	auipc	a5,0x22
    80002cd2:	b4278793          	addi	a5,a5,-1214 # 80024810 <bcache+0x8000>
    80002cd6:	2b87b703          	ld	a4,696(a5)
    80002cda:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002cdc:	00022717          	auipc	a4,0x22
    80002ce0:	d9c70713          	addi	a4,a4,-612 # 80024a78 <bcache+0x8268>
    80002ce4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ce6:	2b87b703          	ld	a4,696(a5)
    80002cea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002cec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002cf0:	0001a517          	auipc	a0,0x1a
    80002cf4:	b2050513          	addi	a0,a0,-1248 # 8001c810 <bcache>
    80002cf8:	f6ffd0ef          	jal	80000c66 <release>
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6902                	ld	s2,0(sp)
    80002d04:	6105                	addi	sp,sp,32
    80002d06:	8082                	ret
    panic("brelse");
    80002d08:	00007517          	auipc	a0,0x7
    80002d0c:	74050513          	addi	a0,a0,1856 # 8000a448 <etext+0x448>
    80002d10:	ad1fd0ef          	jal	800007e0 <panic>

0000000080002d14 <bpin>:

void
bpin(struct buf *b) {
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	1000                	addi	s0,sp,32
    80002d1e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d20:	0001a517          	auipc	a0,0x1a
    80002d24:	af050513          	addi	a0,a0,-1296 # 8001c810 <bcache>
    80002d28:	ea7fd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80002d2c:	40bc                	lw	a5,64(s1)
    80002d2e:	2785                	addiw	a5,a5,1
    80002d30:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d32:	0001a517          	auipc	a0,0x1a
    80002d36:	ade50513          	addi	a0,a0,-1314 # 8001c810 <bcache>
    80002d3a:	f2dfd0ef          	jal	80000c66 <release>
}
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	64a2                	ld	s1,8(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret

0000000080002d48 <bunpin>:

void
bunpin(struct buf *b) {
    80002d48:	1101                	addi	sp,sp,-32
    80002d4a:	ec06                	sd	ra,24(sp)
    80002d4c:	e822                	sd	s0,16(sp)
    80002d4e:	e426                	sd	s1,8(sp)
    80002d50:	1000                	addi	s0,sp,32
    80002d52:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d54:	0001a517          	auipc	a0,0x1a
    80002d58:	abc50513          	addi	a0,a0,-1348 # 8001c810 <bcache>
    80002d5c:	e73fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002d60:	40bc                	lw	a5,64(s1)
    80002d62:	37fd                	addiw	a5,a5,-1
    80002d64:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d66:	0001a517          	auipc	a0,0x1a
    80002d6a:	aaa50513          	addi	a0,a0,-1366 # 8001c810 <bcache>
    80002d6e:	ef9fd0ef          	jal	80000c66 <release>
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	e426                	sd	s1,8(sp)
    80002d84:	e04a                	sd	s2,0(sp)
    80002d86:	1000                	addi	s0,sp,32
    80002d88:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d8a:	00d5d59b          	srliw	a1,a1,0xd
    80002d8e:	00022797          	auipc	a5,0x22
    80002d92:	15e7a783          	lw	a5,350(a5) # 80024eec <sb+0x1c>
    80002d96:	9dbd                	addw	a1,a1,a5
    80002d98:	dedff0ef          	jal	80002b84 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002d9c:	0074f713          	andi	a4,s1,7
    80002da0:	4785                	li	a5,1
    80002da2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002da6:	14ce                	slli	s1,s1,0x33
    80002da8:	90d9                	srli	s1,s1,0x36
    80002daa:	00950733          	add	a4,a0,s1
    80002dae:	05874703          	lbu	a4,88(a4)
    80002db2:	00e7f6b3          	and	a3,a5,a4
    80002db6:	c29d                	beqz	a3,80002ddc <bfree+0x60>
    80002db8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002dba:	94aa                	add	s1,s1,a0
    80002dbc:	fff7c793          	not	a5,a5
    80002dc0:	8f7d                	and	a4,a4,a5
    80002dc2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002dc6:	7f9000ef          	jal	80003dbe <log_write>
  brelse(bp);
    80002dca:	854a                	mv	a0,s2
    80002dcc:	ec1ff0ef          	jal	80002c8c <brelse>
}
    80002dd0:	60e2                	ld	ra,24(sp)
    80002dd2:	6442                	ld	s0,16(sp)
    80002dd4:	64a2                	ld	s1,8(sp)
    80002dd6:	6902                	ld	s2,0(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret
    panic("freeing free block");
    80002ddc:	00007517          	auipc	a0,0x7
    80002de0:	67450513          	addi	a0,a0,1652 # 8000a450 <etext+0x450>
    80002de4:	9fdfd0ef          	jal	800007e0 <panic>

0000000080002de8 <balloc>:
{
    80002de8:	711d                	addi	sp,sp,-96
    80002dea:	ec86                	sd	ra,88(sp)
    80002dec:	e8a2                	sd	s0,80(sp)
    80002dee:	e4a6                	sd	s1,72(sp)
    80002df0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002df2:	00022797          	auipc	a5,0x22
    80002df6:	0e27a783          	lw	a5,226(a5) # 80024ed4 <sb+0x4>
    80002dfa:	0e078f63          	beqz	a5,80002ef8 <balloc+0x110>
    80002dfe:	e0ca                	sd	s2,64(sp)
    80002e00:	fc4e                	sd	s3,56(sp)
    80002e02:	f852                	sd	s4,48(sp)
    80002e04:	f456                	sd	s5,40(sp)
    80002e06:	f05a                	sd	s6,32(sp)
    80002e08:	ec5e                	sd	s7,24(sp)
    80002e0a:	e862                	sd	s8,16(sp)
    80002e0c:	e466                	sd	s9,8(sp)
    80002e0e:	8baa                	mv	s7,a0
    80002e10:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002e12:	00022b17          	auipc	s6,0x22
    80002e16:	0beb0b13          	addi	s6,s6,190 # 80024ed0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e1a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002e1c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e1e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002e20:	6c89                	lui	s9,0x2
    80002e22:	a0b5                	j	80002e8e <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002e24:	97ca                	add	a5,a5,s2
    80002e26:	8e55                	or	a2,a2,a3
    80002e28:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002e2c:	854a                	mv	a0,s2
    80002e2e:	791000ef          	jal	80003dbe <log_write>
        brelse(bp);
    80002e32:	854a                	mv	a0,s2
    80002e34:	e59ff0ef          	jal	80002c8c <brelse>
  bp = bread(dev, bno);
    80002e38:	85a6                	mv	a1,s1
    80002e3a:	855e                	mv	a0,s7
    80002e3c:	d49ff0ef          	jal	80002b84 <bread>
    80002e40:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002e42:	40000613          	li	a2,1024
    80002e46:	4581                	li	a1,0
    80002e48:	05850513          	addi	a0,a0,88
    80002e4c:	e57fd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    80002e50:	854a                	mv	a0,s2
    80002e52:	76d000ef          	jal	80003dbe <log_write>
  brelse(bp);
    80002e56:	854a                	mv	a0,s2
    80002e58:	e35ff0ef          	jal	80002c8c <brelse>
}
    80002e5c:	6906                	ld	s2,64(sp)
    80002e5e:	79e2                	ld	s3,56(sp)
    80002e60:	7a42                	ld	s4,48(sp)
    80002e62:	7aa2                	ld	s5,40(sp)
    80002e64:	7b02                	ld	s6,32(sp)
    80002e66:	6be2                	ld	s7,24(sp)
    80002e68:	6c42                	ld	s8,16(sp)
    80002e6a:	6ca2                	ld	s9,8(sp)
}
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	60e6                	ld	ra,88(sp)
    80002e70:	6446                	ld	s0,80(sp)
    80002e72:	64a6                	ld	s1,72(sp)
    80002e74:	6125                	addi	sp,sp,96
    80002e76:	8082                	ret
    brelse(bp);
    80002e78:	854a                	mv	a0,s2
    80002e7a:	e13ff0ef          	jal	80002c8c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e7e:	015c87bb          	addw	a5,s9,s5
    80002e82:	00078a9b          	sext.w	s5,a5
    80002e86:	004b2703          	lw	a4,4(s6)
    80002e8a:	04eaff63          	bgeu	s5,a4,80002ee8 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002e8e:	41fad79b          	sraiw	a5,s5,0x1f
    80002e92:	0137d79b          	srliw	a5,a5,0x13
    80002e96:	015787bb          	addw	a5,a5,s5
    80002e9a:	40d7d79b          	sraiw	a5,a5,0xd
    80002e9e:	01cb2583          	lw	a1,28(s6)
    80002ea2:	9dbd                	addw	a1,a1,a5
    80002ea4:	855e                	mv	a0,s7
    80002ea6:	cdfff0ef          	jal	80002b84 <bread>
    80002eaa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002eac:	004b2503          	lw	a0,4(s6)
    80002eb0:	000a849b          	sext.w	s1,s5
    80002eb4:	8762                	mv	a4,s8
    80002eb6:	fca4f1e3          	bgeu	s1,a0,80002e78 <balloc+0x90>
      m = 1 << (bi % 8);
    80002eba:	00777693          	andi	a3,a4,7
    80002ebe:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002ec2:	41f7579b          	sraiw	a5,a4,0x1f
    80002ec6:	01d7d79b          	srliw	a5,a5,0x1d
    80002eca:	9fb9                	addw	a5,a5,a4
    80002ecc:	4037d79b          	sraiw	a5,a5,0x3
    80002ed0:	00f90633          	add	a2,s2,a5
    80002ed4:	05864603          	lbu	a2,88(a2)
    80002ed8:	00c6f5b3          	and	a1,a3,a2
    80002edc:	d5a1                	beqz	a1,80002e24 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002ede:	2705                	addiw	a4,a4,1
    80002ee0:	2485                	addiw	s1,s1,1
    80002ee2:	fd471ae3          	bne	a4,s4,80002eb6 <balloc+0xce>
    80002ee6:	bf49                	j	80002e78 <balloc+0x90>
    80002ee8:	6906                	ld	s2,64(sp)
    80002eea:	79e2                	ld	s3,56(sp)
    80002eec:	7a42                	ld	s4,48(sp)
    80002eee:	7aa2                	ld	s5,40(sp)
    80002ef0:	7b02                	ld	s6,32(sp)
    80002ef2:	6be2                	ld	s7,24(sp)
    80002ef4:	6c42                	ld	s8,16(sp)
    80002ef6:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002ef8:	00007517          	auipc	a0,0x7
    80002efc:	57050513          	addi	a0,a0,1392 # 8000a468 <etext+0x468>
    80002f00:	dfafd0ef          	jal	800004fa <printf>
  return 0;
    80002f04:	4481                	li	s1,0
    80002f06:	b79d                	j	80002e6c <balloc+0x84>

0000000080002f08 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	1800                	addi	s0,sp,48
    80002f16:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002f18:	47ad                	li	a5,11
    80002f1a:	02b7e663          	bltu	a5,a1,80002f46 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002f1e:	02059793          	slli	a5,a1,0x20
    80002f22:	01e7d593          	srli	a1,a5,0x1e
    80002f26:	00b504b3          	add	s1,a0,a1
    80002f2a:	0804a903          	lw	s2,128(s1)
    80002f2e:	06091a63          	bnez	s2,80002fa2 <bmap+0x9a>
      addr = balloc(ip->dev);
    80002f32:	4108                	lw	a0,0(a0)
    80002f34:	eb5ff0ef          	jal	80002de8 <balloc>
    80002f38:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f3c:	06090363          	beqz	s2,80002fa2 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80002f40:	0924a023          	sw	s2,128(s1)
    80002f44:	a8b9                	j	80002fa2 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002f46:	ff45849b          	addiw	s1,a1,-12
    80002f4a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002f4e:	0ff00793          	li	a5,255
    80002f52:	06e7ee63          	bltu	a5,a4,80002fce <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002f56:	0b052903          	lw	s2,176(a0)
    80002f5a:	00091d63          	bnez	s2,80002f74 <bmap+0x6c>
      addr = balloc(ip->dev);
    80002f5e:	4108                	lw	a0,0(a0)
    80002f60:	e89ff0ef          	jal	80002de8 <balloc>
    80002f64:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f68:	02090d63          	beqz	s2,80002fa2 <bmap+0x9a>
    80002f6c:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002f6e:	0b29a823          	sw	s2,176(s3)
    80002f72:	a011                	j	80002f76 <bmap+0x6e>
    80002f74:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80002f76:	85ca                	mv	a1,s2
    80002f78:	0009a503          	lw	a0,0(s3)
    80002f7c:	c09ff0ef          	jal	80002b84 <bread>
    80002f80:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f82:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f86:	02049713          	slli	a4,s1,0x20
    80002f8a:	01e75593          	srli	a1,a4,0x1e
    80002f8e:	00b784b3          	add	s1,a5,a1
    80002f92:	0004a903          	lw	s2,0(s1)
    80002f96:	00090e63          	beqz	s2,80002fb2 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002f9a:	8552                	mv	a0,s4
    80002f9c:	cf1ff0ef          	jal	80002c8c <brelse>
    return addr;
    80002fa0:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80002fa2:	854a                	mv	a0,s2
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret
      addr = balloc(ip->dev);
    80002fb2:	0009a503          	lw	a0,0(s3)
    80002fb6:	e33ff0ef          	jal	80002de8 <balloc>
    80002fba:	0005091b          	sext.w	s2,a0
      if(addr){
    80002fbe:	fc090ee3          	beqz	s2,80002f9a <bmap+0x92>
        a[bn] = addr;
    80002fc2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002fc6:	8552                	mv	a0,s4
    80002fc8:	5f7000ef          	jal	80003dbe <log_write>
    80002fcc:	b7f9                	j	80002f9a <bmap+0x92>
    80002fce:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80002fd0:	00007517          	auipc	a0,0x7
    80002fd4:	4b050513          	addi	a0,a0,1200 # 8000a480 <etext+0x480>
    80002fd8:	809fd0ef          	jal	800007e0 <panic>

0000000080002fdc <iinit>:
{
    80002fdc:	7179                	addi	sp,sp,-48
    80002fde:	f406                	sd	ra,40(sp)
    80002fe0:	f022                	sd	s0,32(sp)
    80002fe2:	ec26                	sd	s1,24(sp)
    80002fe4:	e84a                	sd	s2,16(sp)
    80002fe6:	e44e                	sd	s3,8(sp)
    80002fe8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80002fea:	00007597          	auipc	a1,0x7
    80002fee:	4ae58593          	addi	a1,a1,1198 # 8000a498 <etext+0x498>
    80002ff2:	00022517          	auipc	a0,0x22
    80002ff6:	efe50513          	addi	a0,a0,-258 # 80024ef0 <itable>
    80002ffa:	b55fd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    80002ffe:	00022497          	auipc	s1,0x22
    80003002:	f1a48493          	addi	s1,s1,-230 # 80024f18 <itable+0x28>
    80003006:	00024997          	auipc	s3,0x24
    8000300a:	30298993          	addi	s3,s3,770 # 80027308 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000300e:	00007917          	auipc	s2,0x7
    80003012:	49290913          	addi	s2,s2,1170 # 8000a4a0 <etext+0x4a0>
    80003016:	85ca                	mv	a1,s2
    80003018:	8526                	mv	a0,s1
    8000301a:	667000ef          	jal	80003e80 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000301e:	0b848493          	addi	s1,s1,184
    80003022:	ff349ae3          	bne	s1,s3,80003016 <iinit+0x3a>
}
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6942                	ld	s2,16(sp)
    8000302e:	69a2                	ld	s3,8(sp)
    80003030:	6145                	addi	sp,sp,48
    80003032:	8082                	ret

0000000080003034 <iupdate>:
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	e04a                	sd	s2,0(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003042:	415c                	lw	a5,4(a0)
    80003044:	0047d79b          	srliw	a5,a5,0x4
    80003048:	00022597          	auipc	a1,0x22
    8000304c:	ea05a583          	lw	a1,-352(a1) # 80024ee8 <sb+0x18>
    80003050:	9dbd                	addw	a1,a1,a5
    80003052:	4108                	lw	a0,0(a0)
    80003054:	b31ff0ef          	jal	80002b84 <bread>
    80003058:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000305a:	05850793          	addi	a5,a0,88
    8000305e:	40d8                	lw	a4,4(s1)
    80003060:	8b3d                	andi	a4,a4,15
    80003062:	071a                	slli	a4,a4,0x6
    80003064:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003066:	06049703          	lh	a4,96(s1)
    8000306a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000306e:	06249703          	lh	a4,98(s1)
    80003072:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003076:	06449703          	lh	a4,100(s1)
    8000307a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000307e:	06649703          	lh	a4,102(s1)
    80003082:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003086:	54b8                	lw	a4,104(s1)
    80003088:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000308a:	03400613          	li	a2,52
    8000308e:	08048593          	addi	a1,s1,128
    80003092:	00c78513          	addi	a0,a5,12
    80003096:	c69fd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    8000309a:	854a                	mv	a0,s2
    8000309c:	523000ef          	jal	80003dbe <log_write>
  brelse(bp);
    800030a0:	854a                	mv	a0,s2
    800030a2:	bebff0ef          	jal	80002c8c <brelse>
}
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	64a2                	ld	s1,8(sp)
    800030ac:	6902                	ld	s2,0(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <iget>:
{
    800030b2:	7179                	addi	sp,sp,-48
    800030b4:	f406                	sd	ra,40(sp)
    800030b6:	f022                	sd	s0,32(sp)
    800030b8:	ec26                	sd	s1,24(sp)
    800030ba:	e84a                	sd	s2,16(sp)
    800030bc:	e44e                	sd	s3,8(sp)
    800030be:	e052                	sd	s4,0(sp)
    800030c0:	1800                	addi	s0,sp,48
    800030c2:	89aa                	mv	s3,a0
    800030c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800030c6:	00022517          	auipc	a0,0x22
    800030ca:	e2a50513          	addi	a0,a0,-470 # 80024ef0 <itable>
    800030ce:	b01fd0ef          	jal	80000bce <acquire>
  empty = 0;
    800030d2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800030d4:	00022497          	auipc	s1,0x22
    800030d8:	e3448493          	addi	s1,s1,-460 # 80024f08 <itable+0x18>
    800030dc:	00024697          	auipc	a3,0x24
    800030e0:	21c68693          	addi	a3,a3,540 # 800272f8 <log>
    800030e4:	a039                	j	800030f2 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800030e6:	02090963          	beqz	s2,80003118 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800030ea:	0b848493          	addi	s1,s1,184
    800030ee:	02d48863          	beq	s1,a3,8000311e <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800030f2:	449c                	lw	a5,8(s1)
    800030f4:	fef059e3          	blez	a5,800030e6 <iget+0x34>
    800030f8:	4098                	lw	a4,0(s1)
    800030fa:	ff3716e3          	bne	a4,s3,800030e6 <iget+0x34>
    800030fe:	40d8                	lw	a4,4(s1)
    80003100:	ff4713e3          	bne	a4,s4,800030e6 <iget+0x34>
      ip->ref++;
    80003104:	2785                	addiw	a5,a5,1
    80003106:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003108:	00022517          	auipc	a0,0x22
    8000310c:	de850513          	addi	a0,a0,-536 # 80024ef0 <itable>
    80003110:	b57fd0ef          	jal	80000c66 <release>
      return ip;
    80003114:	8926                	mv	s2,s1
    80003116:	a02d                	j	80003140 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003118:	fbe9                	bnez	a5,800030ea <iget+0x38>
      empty = ip;
    8000311a:	8926                	mv	s2,s1
    8000311c:	b7f9                	j	800030ea <iget+0x38>
  if(empty == 0)
    8000311e:	02090a63          	beqz	s2,80003152 <iget+0xa0>
  ip->dev = dev;
    80003122:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003126:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000312a:	4785                	li	a5,1
    8000312c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003130:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003134:	00022517          	auipc	a0,0x22
    80003138:	dbc50513          	addi	a0,a0,-580 # 80024ef0 <itable>
    8000313c:	b2bfd0ef          	jal	80000c66 <release>
}
    80003140:	854a                	mv	a0,s2
    80003142:	70a2                	ld	ra,40(sp)
    80003144:	7402                	ld	s0,32(sp)
    80003146:	64e2                	ld	s1,24(sp)
    80003148:	6942                	ld	s2,16(sp)
    8000314a:	69a2                	ld	s3,8(sp)
    8000314c:	6a02                	ld	s4,0(sp)
    8000314e:	6145                	addi	sp,sp,48
    80003150:	8082                	ret
    panic("iget: no inodes");
    80003152:	00007517          	auipc	a0,0x7
    80003156:	35650513          	addi	a0,a0,854 # 8000a4a8 <etext+0x4a8>
    8000315a:	e86fd0ef          	jal	800007e0 <panic>

000000008000315e <ialloc>:
{
    8000315e:	7139                	addi	sp,sp,-64
    80003160:	fc06                	sd	ra,56(sp)
    80003162:	f822                	sd	s0,48(sp)
    80003164:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003166:	00022717          	auipc	a4,0x22
    8000316a:	d7672703          	lw	a4,-650(a4) # 80024edc <sb+0xc>
    8000316e:	4785                	li	a5,1
    80003170:	06e7f063          	bgeu	a5,a4,800031d0 <ialloc+0x72>
    80003174:	f426                	sd	s1,40(sp)
    80003176:	f04a                	sd	s2,32(sp)
    80003178:	ec4e                	sd	s3,24(sp)
    8000317a:	e852                	sd	s4,16(sp)
    8000317c:	e456                	sd	s5,8(sp)
    8000317e:	e05a                	sd	s6,0(sp)
    80003180:	8aaa                	mv	s5,a0
    80003182:	8b2e                	mv	s6,a1
    80003184:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003186:	00022a17          	auipc	s4,0x22
    8000318a:	d4aa0a13          	addi	s4,s4,-694 # 80024ed0 <sb>
    8000318e:	00495593          	srli	a1,s2,0x4
    80003192:	018a2783          	lw	a5,24(s4)
    80003196:	9dbd                	addw	a1,a1,a5
    80003198:	8556                	mv	a0,s5
    8000319a:	9ebff0ef          	jal	80002b84 <bread>
    8000319e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800031a0:	05850993          	addi	s3,a0,88
    800031a4:	00f97793          	andi	a5,s2,15
    800031a8:	079a                	slli	a5,a5,0x6
    800031aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800031ac:	00099783          	lh	a5,0(s3)
    800031b0:	cb9d                	beqz	a5,800031e6 <ialloc+0x88>
    brelse(bp);
    800031b2:	adbff0ef          	jal	80002c8c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800031b6:	0905                	addi	s2,s2,1
    800031b8:	00ca2703          	lw	a4,12(s4)
    800031bc:	0009079b          	sext.w	a5,s2
    800031c0:	fce7e7e3          	bltu	a5,a4,8000318e <ialloc+0x30>
    800031c4:	74a2                	ld	s1,40(sp)
    800031c6:	7902                	ld	s2,32(sp)
    800031c8:	69e2                	ld	s3,24(sp)
    800031ca:	6a42                	ld	s4,16(sp)
    800031cc:	6aa2                	ld	s5,8(sp)
    800031ce:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800031d0:	00007517          	auipc	a0,0x7
    800031d4:	2e850513          	addi	a0,a0,744 # 8000a4b8 <etext+0x4b8>
    800031d8:	b22fd0ef          	jal	800004fa <printf>
  return 0;
    800031dc:	4501                	li	a0,0
}
    800031de:	70e2                	ld	ra,56(sp)
    800031e0:	7442                	ld	s0,48(sp)
    800031e2:	6121                	addi	sp,sp,64
    800031e4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800031e6:	04000613          	li	a2,64
    800031ea:	4581                	li	a1,0
    800031ec:	854e                	mv	a0,s3
    800031ee:	ab5fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    800031f2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800031f6:	8526                	mv	a0,s1
    800031f8:	3c7000ef          	jal	80003dbe <log_write>
      brelse(bp);
    800031fc:	8526                	mv	a0,s1
    800031fe:	a8fff0ef          	jal	80002c8c <brelse>
      return iget(dev, inum);
    80003202:	0009059b          	sext.w	a1,s2
    80003206:	8556                	mv	a0,s5
    80003208:	eabff0ef          	jal	800030b2 <iget>
    8000320c:	74a2                	ld	s1,40(sp)
    8000320e:	7902                	ld	s2,32(sp)
    80003210:	69e2                	ld	s3,24(sp)
    80003212:	6a42                	ld	s4,16(sp)
    80003214:	6aa2                	ld	s5,8(sp)
    80003216:	6b02                	ld	s6,0(sp)
    80003218:	b7d9                	j	800031de <ialloc+0x80>

000000008000321a <idup>:
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	1000                	addi	s0,sp,32
    80003224:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003226:	00022517          	auipc	a0,0x22
    8000322a:	cca50513          	addi	a0,a0,-822 # 80024ef0 <itable>
    8000322e:	9a1fd0ef          	jal	80000bce <acquire>
  ip->ref++;
    80003232:	449c                	lw	a5,8(s1)
    80003234:	2785                	addiw	a5,a5,1
    80003236:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003238:	00022517          	auipc	a0,0x22
    8000323c:	cb850513          	addi	a0,a0,-840 # 80024ef0 <itable>
    80003240:	a27fd0ef          	jal	80000c66 <release>
}
    80003244:	8526                	mv	a0,s1
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <ilock>:
{
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000325a:	cd19                	beqz	a0,80003278 <ilock+0x28>
    8000325c:	84aa                	mv	s1,a0
    8000325e:	451c                	lw	a5,8(a0)
    80003260:	00f05c63          	blez	a5,80003278 <ilock+0x28>
  acquiresleep(&ip->lock);
    80003264:	0541                	addi	a0,a0,16
    80003266:	451000ef          	jal	80003eb6 <acquiresleep>
  if(ip->valid == 0){
    8000326a:	40bc                	lw	a5,64(s1)
    8000326c:	cf89                	beqz	a5,80003286 <ilock+0x36>
}
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret
    80003278:	e04a                	sd	s2,0(sp)
    panic("ilock");
    8000327a:	00007517          	auipc	a0,0x7
    8000327e:	25650513          	addi	a0,a0,598 # 8000a4d0 <etext+0x4d0>
    80003282:	d5efd0ef          	jal	800007e0 <panic>
    80003286:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003288:	40dc                	lw	a5,4(s1)
    8000328a:	0047d79b          	srliw	a5,a5,0x4
    8000328e:	00022597          	auipc	a1,0x22
    80003292:	c5a5a583          	lw	a1,-934(a1) # 80024ee8 <sb+0x18>
    80003296:	9dbd                	addw	a1,a1,a5
    80003298:	4088                	lw	a0,0(s1)
    8000329a:	8ebff0ef          	jal	80002b84 <bread>
    8000329e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800032a0:	05850593          	addi	a1,a0,88
    800032a4:	40dc                	lw	a5,4(s1)
    800032a6:	8bbd                	andi	a5,a5,15
    800032a8:	079a                	slli	a5,a5,0x6
    800032aa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800032ac:	00059783          	lh	a5,0(a1)
    800032b0:	06f49023          	sh	a5,96(s1)
    ip->major = dip->major;
    800032b4:	00259783          	lh	a5,2(a1)
    800032b8:	06f49123          	sh	a5,98(s1)
    ip->minor = dip->minor;
    800032bc:	00459783          	lh	a5,4(a1)
    800032c0:	06f49223          	sh	a5,100(s1)
    ip->nlink = dip->nlink;
    800032c4:	00659783          	lh	a5,6(a1)
    800032c8:	06f49323          	sh	a5,102(s1)
    ip->size = dip->size;
    800032cc:	459c                	lw	a5,8(a1)
    800032ce:	d4bc                	sw	a5,104(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800032d0:	03400613          	li	a2,52
    800032d4:	05b1                	addi	a1,a1,12
    800032d6:	08048513          	addi	a0,s1,128
    800032da:	a25fd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    800032de:	854a                	mv	a0,s2
    800032e0:	9adff0ef          	jal	80002c8c <brelse>
    ip->valid = 1;
    800032e4:	4785                	li	a5,1
    800032e6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800032e8:	06049783          	lh	a5,96(s1)
    800032ec:	c399                	beqz	a5,800032f2 <ilock+0xa2>
    800032ee:	6902                	ld	s2,0(sp)
    800032f0:	bfbd                	j	8000326e <ilock+0x1e>
      panic("ilock: no type");
    800032f2:	00007517          	auipc	a0,0x7
    800032f6:	1e650513          	addi	a0,a0,486 # 8000a4d8 <etext+0x4d8>
    800032fa:	ce6fd0ef          	jal	800007e0 <panic>

00000000800032fe <iunlock>:
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000330a:	c505                	beqz	a0,80003332 <iunlock+0x34>
    8000330c:	84aa                	mv	s1,a0
    8000330e:	01050913          	addi	s2,a0,16
    80003312:	854a                	mv	a0,s2
    80003314:	421000ef          	jal	80003f34 <holdingsleep>
    80003318:	cd09                	beqz	a0,80003332 <iunlock+0x34>
    8000331a:	449c                	lw	a5,8(s1)
    8000331c:	00f05b63          	blez	a5,80003332 <iunlock+0x34>
  releasesleep(&ip->lock);
    80003320:	854a                	mv	a0,s2
    80003322:	3db000ef          	jal	80003efc <releasesleep>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	64a2                	ld	s1,8(sp)
    8000332c:	6902                	ld	s2,0(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret
    panic("iunlock");
    80003332:	00007517          	auipc	a0,0x7
    80003336:	1b650513          	addi	a0,a0,438 # 8000a4e8 <etext+0x4e8>
    8000333a:	ca6fd0ef          	jal	800007e0 <panic>

000000008000333e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000333e:	7179                	addi	sp,sp,-48
    80003340:	f406                	sd	ra,40(sp)
    80003342:	f022                	sd	s0,32(sp)
    80003344:	ec26                	sd	s1,24(sp)
    80003346:	e84a                	sd	s2,16(sp)
    80003348:	e44e                	sd	s3,8(sp)
    8000334a:	1800                	addi	s0,sp,48
    8000334c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000334e:	08050493          	addi	s1,a0,128
    80003352:	0b050913          	addi	s2,a0,176
    80003356:	a021                	j	8000335e <itrunc+0x20>
    80003358:	0491                	addi	s1,s1,4
    8000335a:	01248b63          	beq	s1,s2,80003370 <itrunc+0x32>
    if(ip->addrs[i]){
    8000335e:	408c                	lw	a1,0(s1)
    80003360:	dde5                	beqz	a1,80003358 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003362:	0009a503          	lw	a0,0(s3)
    80003366:	a17ff0ef          	jal	80002d7c <bfree>
      ip->addrs[i] = 0;
    8000336a:	0004a023          	sw	zero,0(s1)
    8000336e:	b7ed                	j	80003358 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003370:	0b09a583          	lw	a1,176(s3)
    80003374:	ed89                	bnez	a1,8000338e <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003376:	0609a423          	sw	zero,104(s3)
  iupdate(ip);
    8000337a:	854e                	mv	a0,s3
    8000337c:	cb9ff0ef          	jal	80003034 <iupdate>
}
    80003380:	70a2                	ld	ra,40(sp)
    80003382:	7402                	ld	s0,32(sp)
    80003384:	64e2                	ld	s1,24(sp)
    80003386:	6942                	ld	s2,16(sp)
    80003388:	69a2                	ld	s3,8(sp)
    8000338a:	6145                	addi	sp,sp,48
    8000338c:	8082                	ret
    8000338e:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003390:	0009a503          	lw	a0,0(s3)
    80003394:	ff0ff0ef          	jal	80002b84 <bread>
    80003398:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000339a:	05850493          	addi	s1,a0,88
    8000339e:	45850913          	addi	s2,a0,1112
    800033a2:	a021                	j	800033aa <itrunc+0x6c>
    800033a4:	0491                	addi	s1,s1,4
    800033a6:	01248963          	beq	s1,s2,800033b8 <itrunc+0x7a>
      if(a[j])
    800033aa:	408c                	lw	a1,0(s1)
    800033ac:	dde5                	beqz	a1,800033a4 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800033ae:	0009a503          	lw	a0,0(s3)
    800033b2:	9cbff0ef          	jal	80002d7c <bfree>
    800033b6:	b7fd                	j	800033a4 <itrunc+0x66>
    brelse(bp);
    800033b8:	8552                	mv	a0,s4
    800033ba:	8d3ff0ef          	jal	80002c8c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800033be:	0b09a583          	lw	a1,176(s3)
    800033c2:	0009a503          	lw	a0,0(s3)
    800033c6:	9b7ff0ef          	jal	80002d7c <bfree>
    ip->addrs[NDIRECT] = 0;
    800033ca:	0a09a823          	sw	zero,176(s3)
    800033ce:	6a02                	ld	s4,0(sp)
    800033d0:	b75d                	j	80003376 <itrunc+0x38>

00000000800033d2 <iput>:
{
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	1000                	addi	s0,sp,32
    800033dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033de:	00022517          	auipc	a0,0x22
    800033e2:	b1250513          	addi	a0,a0,-1262 # 80024ef0 <itable>
    800033e6:	fe8fd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033ea:	4498                	lw	a4,8(s1)
    800033ec:	4785                	li	a5,1
    800033ee:	02f70063          	beq	a4,a5,8000340e <iput+0x3c>
  ip->ref--;
    800033f2:	449c                	lw	a5,8(s1)
    800033f4:	37fd                	addiw	a5,a5,-1
    800033f6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033f8:	00022517          	auipc	a0,0x22
    800033fc:	af850513          	addi	a0,a0,-1288 # 80024ef0 <itable>
    80003400:	867fd0ef          	jal	80000c66 <release>
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	64a2                	ld	s1,8(sp)
    8000340a:	6105                	addi	sp,sp,32
    8000340c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000340e:	40bc                	lw	a5,64(s1)
    80003410:	d3ed                	beqz	a5,800033f2 <iput+0x20>
    80003412:	06649783          	lh	a5,102(s1)
    80003416:	fff1                	bnez	a5,800033f2 <iput+0x20>
    80003418:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    8000341a:	01048913          	addi	s2,s1,16
    8000341e:	854a                	mv	a0,s2
    80003420:	297000ef          	jal	80003eb6 <acquiresleep>
    release(&itable.lock);
    80003424:	00022517          	auipc	a0,0x22
    80003428:	acc50513          	addi	a0,a0,-1332 # 80024ef0 <itable>
    8000342c:	83bfd0ef          	jal	80000c66 <release>
    itrunc(ip);
    80003430:	8526                	mv	a0,s1
    80003432:	f0dff0ef          	jal	8000333e <itrunc>
    ip->type = 0;
    80003436:	06049023          	sh	zero,96(s1)
    iupdate(ip);
    8000343a:	8526                	mv	a0,s1
    8000343c:	bf9ff0ef          	jal	80003034 <iupdate>
    ip->valid = 0;
    80003440:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003444:	854a                	mv	a0,s2
    80003446:	2b7000ef          	jal	80003efc <releasesleep>
    acquire(&itable.lock);
    8000344a:	00022517          	auipc	a0,0x22
    8000344e:	aa650513          	addi	a0,a0,-1370 # 80024ef0 <itable>
    80003452:	f7cfd0ef          	jal	80000bce <acquire>
    80003456:	6902                	ld	s2,0(sp)
    80003458:	bf69                	j	800033f2 <iput+0x20>

000000008000345a <iunlockput>:
{
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	e426                	sd	s1,8(sp)
    80003462:	1000                	addi	s0,sp,32
    80003464:	84aa                	mv	s1,a0
  iunlock(ip);
    80003466:	e99ff0ef          	jal	800032fe <iunlock>
  iput(ip);
    8000346a:	8526                	mv	a0,s1
    8000346c:	f67ff0ef          	jal	800033d2 <iput>
}
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret

000000008000347a <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000347a:	00022717          	auipc	a4,0x22
    8000347e:	a6272703          	lw	a4,-1438(a4) # 80024edc <sb+0xc>
    80003482:	4785                	li	a5,1
    80003484:	0ae7ff63          	bgeu	a5,a4,80003542 <ireclaim+0xc8>
{
    80003488:	7139                	addi	sp,sp,-64
    8000348a:	fc06                	sd	ra,56(sp)
    8000348c:	f822                	sd	s0,48(sp)
    8000348e:	f426                	sd	s1,40(sp)
    80003490:	f04a                	sd	s2,32(sp)
    80003492:	ec4e                	sd	s3,24(sp)
    80003494:	e852                	sd	s4,16(sp)
    80003496:	e456                	sd	s5,8(sp)
    80003498:	e05a                	sd	s6,0(sp)
    8000349a:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000349c:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000349e:	00050a1b          	sext.w	s4,a0
    800034a2:	00022a97          	auipc	s5,0x22
    800034a6:	a2ea8a93          	addi	s5,s5,-1490 # 80024ed0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800034aa:	00007b17          	auipc	s6,0x7
    800034ae:	046b0b13          	addi	s6,s6,70 # 8000a4f0 <etext+0x4f0>
    800034b2:	a099                	j	800034f8 <ireclaim+0x7e>
    800034b4:	85ce                	mv	a1,s3
    800034b6:	855a                	mv	a0,s6
    800034b8:	842fd0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    800034bc:	85ce                	mv	a1,s3
    800034be:	8552                	mv	a0,s4
    800034c0:	bf3ff0ef          	jal	800030b2 <iget>
    800034c4:	89aa                	mv	s3,a0
    brelse(bp);
    800034c6:	854a                	mv	a0,s2
    800034c8:	fc4ff0ef          	jal	80002c8c <brelse>
    if (ip) {
    800034cc:	00098f63          	beqz	s3,800034ea <ireclaim+0x70>
      begin_op();
    800034d0:	76a000ef          	jal	80003c3a <begin_op>
      ilock(ip);
    800034d4:	854e                	mv	a0,s3
    800034d6:	d7bff0ef          	jal	80003250 <ilock>
      iunlock(ip);
    800034da:	854e                	mv	a0,s3
    800034dc:	e23ff0ef          	jal	800032fe <iunlock>
      iput(ip);
    800034e0:	854e                	mv	a0,s3
    800034e2:	ef1ff0ef          	jal	800033d2 <iput>
      end_op();
    800034e6:	7be000ef          	jal	80003ca4 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034ea:	0485                	addi	s1,s1,1
    800034ec:	00caa703          	lw	a4,12(s5)
    800034f0:	0004879b          	sext.w	a5,s1
    800034f4:	02e7fd63          	bgeu	a5,a4,8000352e <ireclaim+0xb4>
    800034f8:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800034fc:	0044d593          	srli	a1,s1,0x4
    80003500:	018aa783          	lw	a5,24(s5)
    80003504:	9dbd                	addw	a1,a1,a5
    80003506:	8552                	mv	a0,s4
    80003508:	e7cff0ef          	jal	80002b84 <bread>
    8000350c:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000350e:	05850793          	addi	a5,a0,88
    80003512:	00f9f713          	andi	a4,s3,15
    80003516:	071a                	slli	a4,a4,0x6
    80003518:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    8000351a:	00079703          	lh	a4,0(a5)
    8000351e:	c701                	beqz	a4,80003526 <ireclaim+0xac>
    80003520:	00679783          	lh	a5,6(a5)
    80003524:	dbc1                	beqz	a5,800034b4 <ireclaim+0x3a>
    brelse(bp);
    80003526:	854a                	mv	a0,s2
    80003528:	f64ff0ef          	jal	80002c8c <brelse>
    if (ip) {
    8000352c:	bf7d                	j	800034ea <ireclaim+0x70>
}
    8000352e:	70e2                	ld	ra,56(sp)
    80003530:	7442                	ld	s0,48(sp)
    80003532:	74a2                	ld	s1,40(sp)
    80003534:	7902                	ld	s2,32(sp)
    80003536:	69e2                	ld	s3,24(sp)
    80003538:	6a42                	ld	s4,16(sp)
    8000353a:	6aa2                	ld	s5,8(sp)
    8000353c:	6b02                	ld	s6,0(sp)
    8000353e:	6121                	addi	sp,sp,64
    80003540:	8082                	ret
    80003542:	8082                	ret

0000000080003544 <fsinit>:
fsinit(int dev) {
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	e84a                	sd	s2,16(sp)
    8000354e:	e44e                	sd	s3,8(sp)
    80003550:	1800                	addi	s0,sp,48
    80003552:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003554:	4585                	li	a1,1
    80003556:	e2eff0ef          	jal	80002b84 <bread>
    8000355a:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000355c:	00022997          	auipc	s3,0x22
    80003560:	97498993          	addi	s3,s3,-1676 # 80024ed0 <sb>
    80003564:	02000613          	li	a2,32
    80003568:	05850593          	addi	a1,a0,88
    8000356c:	854e                	mv	a0,s3
    8000356e:	f90fd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    80003572:	854a                	mv	a0,s2
    80003574:	f18ff0ef          	jal	80002c8c <brelse>
  if(sb.magic != FSMAGIC)
    80003578:	0009a703          	lw	a4,0(s3)
    8000357c:	102037b7          	lui	a5,0x10203
    80003580:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003584:	02f71363          	bne	a4,a5,800035aa <fsinit+0x66>
  initlog(dev, &sb);
    80003588:	00022597          	auipc	a1,0x22
    8000358c:	94858593          	addi	a1,a1,-1720 # 80024ed0 <sb>
    80003590:	8526                	mv	a0,s1
    80003592:	62a000ef          	jal	80003bbc <initlog>
  ireclaim(dev);
    80003596:	8526                	mv	a0,s1
    80003598:	ee3ff0ef          	jal	8000347a <ireclaim>
}
    8000359c:	70a2                	ld	ra,40(sp)
    8000359e:	7402                	ld	s0,32(sp)
    800035a0:	64e2                	ld	s1,24(sp)
    800035a2:	6942                	ld	s2,16(sp)
    800035a4:	69a2                	ld	s3,8(sp)
    800035a6:	6145                	addi	sp,sp,48
    800035a8:	8082                	ret
    panic("invalid file system");
    800035aa:	00007517          	auipc	a0,0x7
    800035ae:	f6650513          	addi	a0,a0,-154 # 8000a510 <etext+0x510>
    800035b2:	a2efd0ef          	jal	800007e0 <panic>

00000000800035b6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800035b6:	1141                	addi	sp,sp,-16
    800035b8:	e422                	sd	s0,8(sp)
    800035ba:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800035bc:	411c                	lw	a5,0(a0)
    800035be:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800035c0:	415c                	lw	a5,4(a0)
    800035c2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800035c4:	06051783          	lh	a5,96(a0)
    800035c8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800035cc:	06651783          	lh	a5,102(a0)
    800035d0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800035d4:	06856783          	lwu	a5,104(a0)
    800035d8:	e99c                	sd	a5,16(a1)
}
    800035da:	6422                	ld	s0,8(sp)
    800035dc:	0141                	addi	sp,sp,16
    800035de:	8082                	ret

00000000800035e0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035e0:	553c                	lw	a5,104(a0)
    800035e2:	0ed7eb63          	bltu	a5,a3,800036d8 <readi+0xf8>
{
    800035e6:	7159                	addi	sp,sp,-112
    800035e8:	f486                	sd	ra,104(sp)
    800035ea:	f0a2                	sd	s0,96(sp)
    800035ec:	eca6                	sd	s1,88(sp)
    800035ee:	e0d2                	sd	s4,64(sp)
    800035f0:	fc56                	sd	s5,56(sp)
    800035f2:	f85a                	sd	s6,48(sp)
    800035f4:	f45e                	sd	s7,40(sp)
    800035f6:	1880                	addi	s0,sp,112
    800035f8:	8b2a                	mv	s6,a0
    800035fa:	8bae                	mv	s7,a1
    800035fc:	8a32                	mv	s4,a2
    800035fe:	84b6                	mv	s1,a3
    80003600:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003602:	9f35                	addw	a4,a4,a3
    return 0;
    80003604:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003606:	0cd76063          	bltu	a4,a3,800036c6 <readi+0xe6>
    8000360a:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    8000360c:	00e7f463          	bgeu	a5,a4,80003614 <readi+0x34>
    n = ip->size - off;
    80003610:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003614:	080a8f63          	beqz	s5,800036b2 <readi+0xd2>
    80003618:	e8ca                	sd	s2,80(sp)
    8000361a:	f062                	sd	s8,32(sp)
    8000361c:	ec66                	sd	s9,24(sp)
    8000361e:	e86a                	sd	s10,16(sp)
    80003620:	e46e                	sd	s11,8(sp)
    80003622:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003624:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003628:	5c7d                	li	s8,-1
    8000362a:	a80d                	j	8000365c <readi+0x7c>
    8000362c:	020d1d93          	slli	s11,s10,0x20
    80003630:	020ddd93          	srli	s11,s11,0x20
    80003634:	05890613          	addi	a2,s2,88
    80003638:	86ee                	mv	a3,s11
    8000363a:	963a                	add	a2,a2,a4
    8000363c:	85d2                	mv	a1,s4
    8000363e:	855e                	mv	a0,s7
    80003640:	c57fe0ef          	jal	80002296 <either_copyout>
    80003644:	05850763          	beq	a0,s8,80003692 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003648:	854a                	mv	a0,s2
    8000364a:	e42ff0ef          	jal	80002c8c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000364e:	013d09bb          	addw	s3,s10,s3
    80003652:	009d04bb          	addw	s1,s10,s1
    80003656:	9a6e                	add	s4,s4,s11
    80003658:	0559f763          	bgeu	s3,s5,800036a6 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    8000365c:	00a4d59b          	srliw	a1,s1,0xa
    80003660:	855a                	mv	a0,s6
    80003662:	8a7ff0ef          	jal	80002f08 <bmap>
    80003666:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000366a:	c5b1                	beqz	a1,800036b6 <readi+0xd6>
    bp = bread(ip->dev, addr);
    8000366c:	000b2503          	lw	a0,0(s6)
    80003670:	d14ff0ef          	jal	80002b84 <bread>
    80003674:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003676:	3ff4f713          	andi	a4,s1,1023
    8000367a:	40ec87bb          	subw	a5,s9,a4
    8000367e:	413a86bb          	subw	a3,s5,s3
    80003682:	8d3e                	mv	s10,a5
    80003684:	2781                	sext.w	a5,a5
    80003686:	0006861b          	sext.w	a2,a3
    8000368a:	faf671e3          	bgeu	a2,a5,8000362c <readi+0x4c>
    8000368e:	8d36                	mv	s10,a3
    80003690:	bf71                	j	8000362c <readi+0x4c>
      brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	df8ff0ef          	jal	80002c8c <brelse>
      tot = -1;
    80003698:	59fd                	li	s3,-1
      break;
    8000369a:	6946                	ld	s2,80(sp)
    8000369c:	7c02                	ld	s8,32(sp)
    8000369e:	6ce2                	ld	s9,24(sp)
    800036a0:	6d42                	ld	s10,16(sp)
    800036a2:	6da2                	ld	s11,8(sp)
    800036a4:	a831                	j	800036c0 <readi+0xe0>
    800036a6:	6946                	ld	s2,80(sp)
    800036a8:	7c02                	ld	s8,32(sp)
    800036aa:	6ce2                	ld	s9,24(sp)
    800036ac:	6d42                	ld	s10,16(sp)
    800036ae:	6da2                	ld	s11,8(sp)
    800036b0:	a801                	j	800036c0 <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800036b2:	89d6                	mv	s3,s5
    800036b4:	a031                	j	800036c0 <readi+0xe0>
    800036b6:	6946                	ld	s2,80(sp)
    800036b8:	7c02                	ld	s8,32(sp)
    800036ba:	6ce2                	ld	s9,24(sp)
    800036bc:	6d42                	ld	s10,16(sp)
    800036be:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800036c0:	0009851b          	sext.w	a0,s3
    800036c4:	69a6                	ld	s3,72(sp)
}
    800036c6:	70a6                	ld	ra,104(sp)
    800036c8:	7406                	ld	s0,96(sp)
    800036ca:	64e6                	ld	s1,88(sp)
    800036cc:	6a06                	ld	s4,64(sp)
    800036ce:	7ae2                	ld	s5,56(sp)
    800036d0:	7b42                	ld	s6,48(sp)
    800036d2:	7ba2                	ld	s7,40(sp)
    800036d4:	6165                	addi	sp,sp,112
    800036d6:	8082                	ret
    return 0;
    800036d8:	4501                	li	a0,0
}
    800036da:	8082                	ret

00000000800036dc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036dc:	553c                	lw	a5,104(a0)
    800036de:	10d7e063          	bltu	a5,a3,800037de <writei+0x102>
{
    800036e2:	7159                	addi	sp,sp,-112
    800036e4:	f486                	sd	ra,104(sp)
    800036e6:	f0a2                	sd	s0,96(sp)
    800036e8:	e8ca                	sd	s2,80(sp)
    800036ea:	e0d2                	sd	s4,64(sp)
    800036ec:	fc56                	sd	s5,56(sp)
    800036ee:	f85a                	sd	s6,48(sp)
    800036f0:	f45e                	sd	s7,40(sp)
    800036f2:	1880                	addi	s0,sp,112
    800036f4:	8aaa                	mv	s5,a0
    800036f6:	8bae                	mv	s7,a1
    800036f8:	8a32                	mv	s4,a2
    800036fa:	8936                	mv	s2,a3
    800036fc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800036fe:	00e687bb          	addw	a5,a3,a4
    80003702:	0ed7e063          	bltu	a5,a3,800037e2 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003706:	00043737          	lui	a4,0x43
    8000370a:	0cf76e63          	bltu	a4,a5,800037e6 <writei+0x10a>
    8000370e:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003710:	0a0b0f63          	beqz	s6,800037ce <writei+0xf2>
    80003714:	eca6                	sd	s1,88(sp)
    80003716:	f062                	sd	s8,32(sp)
    80003718:	ec66                	sd	s9,24(sp)
    8000371a:	e86a                	sd	s10,16(sp)
    8000371c:	e46e                	sd	s11,8(sp)
    8000371e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003720:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003724:	5c7d                	li	s8,-1
    80003726:	a825                	j	8000375e <writei+0x82>
    80003728:	020d1d93          	slli	s11,s10,0x20
    8000372c:	020ddd93          	srli	s11,s11,0x20
    80003730:	05848513          	addi	a0,s1,88
    80003734:	86ee                	mv	a3,s11
    80003736:	8652                	mv	a2,s4
    80003738:	85de                	mv	a1,s7
    8000373a:	953a                	add	a0,a0,a4
    8000373c:	ba5fe0ef          	jal	800022e0 <either_copyin>
    80003740:	05850a63          	beq	a0,s8,80003794 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003744:	8526                	mv	a0,s1
    80003746:	678000ef          	jal	80003dbe <log_write>
    brelse(bp);
    8000374a:	8526                	mv	a0,s1
    8000374c:	d40ff0ef          	jal	80002c8c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003750:	013d09bb          	addw	s3,s10,s3
    80003754:	012d093b          	addw	s2,s10,s2
    80003758:	9a6e                	add	s4,s4,s11
    8000375a:	0569f063          	bgeu	s3,s6,8000379a <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    8000375e:	00a9559b          	srliw	a1,s2,0xa
    80003762:	8556                	mv	a0,s5
    80003764:	fa4ff0ef          	jal	80002f08 <bmap>
    80003768:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000376c:	c59d                	beqz	a1,8000379a <writei+0xbe>
    bp = bread(ip->dev, addr);
    8000376e:	000aa503          	lw	a0,0(s5)
    80003772:	c12ff0ef          	jal	80002b84 <bread>
    80003776:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003778:	3ff97713          	andi	a4,s2,1023
    8000377c:	40ec87bb          	subw	a5,s9,a4
    80003780:	413b06bb          	subw	a3,s6,s3
    80003784:	8d3e                	mv	s10,a5
    80003786:	2781                	sext.w	a5,a5
    80003788:	0006861b          	sext.w	a2,a3
    8000378c:	f8f67ee3          	bgeu	a2,a5,80003728 <writei+0x4c>
    80003790:	8d36                	mv	s10,a3
    80003792:	bf59                	j	80003728 <writei+0x4c>
      brelse(bp);
    80003794:	8526                	mv	a0,s1
    80003796:	cf6ff0ef          	jal	80002c8c <brelse>
  }

  if(off > ip->size)
    8000379a:	068aa783          	lw	a5,104(s5)
    8000379e:	0327fa63          	bgeu	a5,s2,800037d2 <writei+0xf6>
    ip->size = off;
    800037a2:	072aa423          	sw	s2,104(s5)
    800037a6:	64e6                	ld	s1,88(sp)
    800037a8:	7c02                	ld	s8,32(sp)
    800037aa:	6ce2                	ld	s9,24(sp)
    800037ac:	6d42                	ld	s10,16(sp)
    800037ae:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800037b0:	8556                	mv	a0,s5
    800037b2:	883ff0ef          	jal	80003034 <iupdate>

  return tot;
    800037b6:	0009851b          	sext.w	a0,s3
    800037ba:	69a6                	ld	s3,72(sp)
}
    800037bc:	70a6                	ld	ra,104(sp)
    800037be:	7406                	ld	s0,96(sp)
    800037c0:	6946                	ld	s2,80(sp)
    800037c2:	6a06                	ld	s4,64(sp)
    800037c4:	7ae2                	ld	s5,56(sp)
    800037c6:	7b42                	ld	s6,48(sp)
    800037c8:	7ba2                	ld	s7,40(sp)
    800037ca:	6165                	addi	sp,sp,112
    800037cc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800037ce:	89da                	mv	s3,s6
    800037d0:	b7c5                	j	800037b0 <writei+0xd4>
    800037d2:	64e6                	ld	s1,88(sp)
    800037d4:	7c02                	ld	s8,32(sp)
    800037d6:	6ce2                	ld	s9,24(sp)
    800037d8:	6d42                	ld	s10,16(sp)
    800037da:	6da2                	ld	s11,8(sp)
    800037dc:	bfd1                	j	800037b0 <writei+0xd4>
    return -1;
    800037de:	557d                	li	a0,-1
}
    800037e0:	8082                	ret
    return -1;
    800037e2:	557d                	li	a0,-1
    800037e4:	bfe1                	j	800037bc <writei+0xe0>
    return -1;
    800037e6:	557d                	li	a0,-1
    800037e8:	bfd1                	j	800037bc <writei+0xe0>

00000000800037ea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800037ea:	1141                	addi	sp,sp,-16
    800037ec:	e406                	sd	ra,8(sp)
    800037ee:	e022                	sd	s0,0(sp)
    800037f0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800037f2:	4639                	li	a2,14
    800037f4:	d7afd0ef          	jal	80000d6e <strncmp>
}
    800037f8:	60a2                	ld	ra,8(sp)
    800037fa:	6402                	ld	s0,0(sp)
    800037fc:	0141                	addi	sp,sp,16
    800037fe:	8082                	ret

0000000080003800 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003800:	7139                	addi	sp,sp,-64
    80003802:	fc06                	sd	ra,56(sp)
    80003804:	f822                	sd	s0,48(sp)
    80003806:	f426                	sd	s1,40(sp)
    80003808:	f04a                	sd	s2,32(sp)
    8000380a:	ec4e                	sd	s3,24(sp)
    8000380c:	e852                	sd	s4,16(sp)
    8000380e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003810:	06051703          	lh	a4,96(a0)
    80003814:	4785                	li	a5,1
    80003816:	00f71a63          	bne	a4,a5,8000382a <dirlookup+0x2a>
    8000381a:	892a                	mv	s2,a0
    8000381c:	89ae                	mv	s3,a1
    8000381e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003820:	553c                	lw	a5,104(a0)
    80003822:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003824:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003826:	e39d                	bnez	a5,8000384c <dirlookup+0x4c>
    80003828:	a095                	j	8000388c <dirlookup+0x8c>
    panic("dirlookup not DIR");
    8000382a:	00007517          	auipc	a0,0x7
    8000382e:	cfe50513          	addi	a0,a0,-770 # 8000a528 <etext+0x528>
    80003832:	faffc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003836:	00007517          	auipc	a0,0x7
    8000383a:	d0a50513          	addi	a0,a0,-758 # 8000a540 <etext+0x540>
    8000383e:	fa3fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003842:	24c1                	addiw	s1,s1,16
    80003844:	06892783          	lw	a5,104(s2)
    80003848:	04f4f163          	bgeu	s1,a5,8000388a <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000384c:	4741                	li	a4,16
    8000384e:	86a6                	mv	a3,s1
    80003850:	fc040613          	addi	a2,s0,-64
    80003854:	4581                	li	a1,0
    80003856:	854a                	mv	a0,s2
    80003858:	d89ff0ef          	jal	800035e0 <readi>
    8000385c:	47c1                	li	a5,16
    8000385e:	fcf51ce3          	bne	a0,a5,80003836 <dirlookup+0x36>
    if(de.inum == 0)
    80003862:	fc045783          	lhu	a5,-64(s0)
    80003866:	dff1                	beqz	a5,80003842 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003868:	fc240593          	addi	a1,s0,-62
    8000386c:	854e                	mv	a0,s3
    8000386e:	f7dff0ef          	jal	800037ea <namecmp>
    80003872:	f961                	bnez	a0,80003842 <dirlookup+0x42>
      if(poff)
    80003874:	000a0463          	beqz	s4,8000387c <dirlookup+0x7c>
        *poff = off;
    80003878:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000387c:	fc045583          	lhu	a1,-64(s0)
    80003880:	00092503          	lw	a0,0(s2)
    80003884:	82fff0ef          	jal	800030b2 <iget>
    80003888:	a011                	j	8000388c <dirlookup+0x8c>
  return 0;
    8000388a:	4501                	li	a0,0
}
    8000388c:	70e2                	ld	ra,56(sp)
    8000388e:	7442                	ld	s0,48(sp)
    80003890:	74a2                	ld	s1,40(sp)
    80003892:	7902                	ld	s2,32(sp)
    80003894:	69e2                	ld	s3,24(sp)
    80003896:	6a42                	ld	s4,16(sp)
    80003898:	6121                	addi	sp,sp,64
    8000389a:	8082                	ret

000000008000389c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000389c:	711d                	addi	sp,sp,-96
    8000389e:	ec86                	sd	ra,88(sp)
    800038a0:	e8a2                	sd	s0,80(sp)
    800038a2:	e4a6                	sd	s1,72(sp)
    800038a4:	e0ca                	sd	s2,64(sp)
    800038a6:	fc4e                	sd	s3,56(sp)
    800038a8:	f852                	sd	s4,48(sp)
    800038aa:	f456                	sd	s5,40(sp)
    800038ac:	f05a                	sd	s6,32(sp)
    800038ae:	ec5e                	sd	s7,24(sp)
    800038b0:	e862                	sd	s8,16(sp)
    800038b2:	e466                	sd	s9,8(sp)
    800038b4:	1080                	addi	s0,sp,96
    800038b6:	84aa                	mv	s1,a0
    800038b8:	8b2e                	mv	s6,a1
    800038ba:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800038bc:	00054703          	lbu	a4,0(a0)
    800038c0:	02f00793          	li	a5,47
    800038c4:	00f70e63          	beq	a4,a5,800038e0 <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800038c8:	82efe0ef          	jal	800018f6 <myproc>
    800038cc:	15053503          	ld	a0,336(a0)
    800038d0:	94bff0ef          	jal	8000321a <idup>
    800038d4:	8a2a                	mv	s4,a0
  while(*path == '/')
    800038d6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800038da:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800038dc:	4b85                	li	s7,1
    800038de:	a871                	j	8000397a <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    800038e0:	4585                	li	a1,1
    800038e2:	4505                	li	a0,1
    800038e4:	fceff0ef          	jal	800030b2 <iget>
    800038e8:	8a2a                	mv	s4,a0
    800038ea:	b7f5                	j	800038d6 <namex+0x3a>
      iunlockput(ip);
    800038ec:	8552                	mv	a0,s4
    800038ee:	b6dff0ef          	jal	8000345a <iunlockput>
      return 0;
    800038f2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800038f4:	8552                	mv	a0,s4
    800038f6:	60e6                	ld	ra,88(sp)
    800038f8:	6446                	ld	s0,80(sp)
    800038fa:	64a6                	ld	s1,72(sp)
    800038fc:	6906                	ld	s2,64(sp)
    800038fe:	79e2                	ld	s3,56(sp)
    80003900:	7a42                	ld	s4,48(sp)
    80003902:	7aa2                	ld	s5,40(sp)
    80003904:	7b02                	ld	s6,32(sp)
    80003906:	6be2                	ld	s7,24(sp)
    80003908:	6c42                	ld	s8,16(sp)
    8000390a:	6ca2                	ld	s9,8(sp)
    8000390c:	6125                	addi	sp,sp,96
    8000390e:	8082                	ret
      iunlock(ip);
    80003910:	8552                	mv	a0,s4
    80003912:	9edff0ef          	jal	800032fe <iunlock>
      return ip;
    80003916:	bff9                	j	800038f4 <namex+0x58>
      iunlockput(ip);
    80003918:	8552                	mv	a0,s4
    8000391a:	b41ff0ef          	jal	8000345a <iunlockput>
      return 0;
    8000391e:	8a4e                	mv	s4,s3
    80003920:	bfd1                	j	800038f4 <namex+0x58>
  len = path - s;
    80003922:	40998633          	sub	a2,s3,s1
    80003926:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000392a:	099c5063          	bge	s8,s9,800039aa <namex+0x10e>
    memmove(name, s, DIRSIZ);
    8000392e:	4639                	li	a2,14
    80003930:	85a6                	mv	a1,s1
    80003932:	8556                	mv	a0,s5
    80003934:	bcafd0ef          	jal	80000cfe <memmove>
    80003938:	84ce                	mv	s1,s3
  while(*path == '/')
    8000393a:	0004c783          	lbu	a5,0(s1)
    8000393e:	01279763          	bne	a5,s2,8000394c <namex+0xb0>
    path++;
    80003942:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003944:	0004c783          	lbu	a5,0(s1)
    80003948:	ff278de3          	beq	a5,s2,80003942 <namex+0xa6>
    ilock(ip);
    8000394c:	8552                	mv	a0,s4
    8000394e:	903ff0ef          	jal	80003250 <ilock>
    if(ip->type != T_DIR){
    80003952:	060a1783          	lh	a5,96(s4)
    80003956:	f9779be3          	bne	a5,s7,800038ec <namex+0x50>
    if(nameiparent && *path == '\0'){
    8000395a:	000b0563          	beqz	s6,80003964 <namex+0xc8>
    8000395e:	0004c783          	lbu	a5,0(s1)
    80003962:	d7dd                	beqz	a5,80003910 <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003964:	4601                	li	a2,0
    80003966:	85d6                	mv	a1,s5
    80003968:	8552                	mv	a0,s4
    8000396a:	e97ff0ef          	jal	80003800 <dirlookup>
    8000396e:	89aa                	mv	s3,a0
    80003970:	d545                	beqz	a0,80003918 <namex+0x7c>
    iunlockput(ip);
    80003972:	8552                	mv	a0,s4
    80003974:	ae7ff0ef          	jal	8000345a <iunlockput>
    ip = next;
    80003978:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000397a:	0004c783          	lbu	a5,0(s1)
    8000397e:	01279763          	bne	a5,s2,8000398c <namex+0xf0>
    path++;
    80003982:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003984:	0004c783          	lbu	a5,0(s1)
    80003988:	ff278de3          	beq	a5,s2,80003982 <namex+0xe6>
  if(*path == 0)
    8000398c:	cb8d                	beqz	a5,800039be <namex+0x122>
  while(*path != '/' && *path != 0)
    8000398e:	0004c783          	lbu	a5,0(s1)
    80003992:	89a6                	mv	s3,s1
  len = path - s;
    80003994:	4c81                	li	s9,0
    80003996:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003998:	01278963          	beq	a5,s2,800039aa <namex+0x10e>
    8000399c:	d3d9                	beqz	a5,80003922 <namex+0x86>
    path++;
    8000399e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800039a0:	0009c783          	lbu	a5,0(s3)
    800039a4:	ff279ce3          	bne	a5,s2,8000399c <namex+0x100>
    800039a8:	bfad                	j	80003922 <namex+0x86>
    memmove(name, s, len);
    800039aa:	2601                	sext.w	a2,a2
    800039ac:	85a6                	mv	a1,s1
    800039ae:	8556                	mv	a0,s5
    800039b0:	b4efd0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    800039b4:	9cd6                	add	s9,s9,s5
    800039b6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800039ba:	84ce                	mv	s1,s3
    800039bc:	bfbd                	j	8000393a <namex+0x9e>
  if(nameiparent){
    800039be:	f20b0be3          	beqz	s6,800038f4 <namex+0x58>
    iput(ip);
    800039c2:	8552                	mv	a0,s4
    800039c4:	a0fff0ef          	jal	800033d2 <iput>
    return 0;
    800039c8:	4a01                	li	s4,0
    800039ca:	b72d                	j	800038f4 <namex+0x58>

00000000800039cc <dirlink>:
{
    800039cc:	7139                	addi	sp,sp,-64
    800039ce:	fc06                	sd	ra,56(sp)
    800039d0:	f822                	sd	s0,48(sp)
    800039d2:	f04a                	sd	s2,32(sp)
    800039d4:	ec4e                	sd	s3,24(sp)
    800039d6:	e852                	sd	s4,16(sp)
    800039d8:	0080                	addi	s0,sp,64
    800039da:	892a                	mv	s2,a0
    800039dc:	8a2e                	mv	s4,a1
    800039de:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800039e0:	4601                	li	a2,0
    800039e2:	e1fff0ef          	jal	80003800 <dirlookup>
    800039e6:	e535                	bnez	a0,80003a52 <dirlink+0x86>
    800039e8:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039ea:	06892483          	lw	s1,104(s2)
    800039ee:	c48d                	beqz	s1,80003a18 <dirlink+0x4c>
    800039f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039f2:	4741                	li	a4,16
    800039f4:	86a6                	mv	a3,s1
    800039f6:	fc040613          	addi	a2,s0,-64
    800039fa:	4581                	li	a1,0
    800039fc:	854a                	mv	a0,s2
    800039fe:	be3ff0ef          	jal	800035e0 <readi>
    80003a02:	47c1                	li	a5,16
    80003a04:	04f51b63          	bne	a0,a5,80003a5a <dirlink+0x8e>
    if(de.inum == 0)
    80003a08:	fc045783          	lhu	a5,-64(s0)
    80003a0c:	c791                	beqz	a5,80003a18 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a0e:	24c1                	addiw	s1,s1,16
    80003a10:	06892783          	lw	a5,104(s2)
    80003a14:	fcf4efe3          	bltu	s1,a5,800039f2 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003a18:	4639                	li	a2,14
    80003a1a:	85d2                	mv	a1,s4
    80003a1c:	fc240513          	addi	a0,s0,-62
    80003a20:	b84fd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003a24:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a28:	4741                	li	a4,16
    80003a2a:	86a6                	mv	a3,s1
    80003a2c:	fc040613          	addi	a2,s0,-64
    80003a30:	4581                	li	a1,0
    80003a32:	854a                	mv	a0,s2
    80003a34:	ca9ff0ef          	jal	800036dc <writei>
    80003a38:	1541                	addi	a0,a0,-16
    80003a3a:	00a03533          	snez	a0,a0
    80003a3e:	40a00533          	neg	a0,a0
    80003a42:	74a2                	ld	s1,40(sp)
}
    80003a44:	70e2                	ld	ra,56(sp)
    80003a46:	7442                	ld	s0,48(sp)
    80003a48:	7902                	ld	s2,32(sp)
    80003a4a:	69e2                	ld	s3,24(sp)
    80003a4c:	6a42                	ld	s4,16(sp)
    80003a4e:	6121                	addi	sp,sp,64
    80003a50:	8082                	ret
    iput(ip);
    80003a52:	981ff0ef          	jal	800033d2 <iput>
    return -1;
    80003a56:	557d                	li	a0,-1
    80003a58:	b7f5                	j	80003a44 <dirlink+0x78>
      panic("dirlink read");
    80003a5a:	00007517          	auipc	a0,0x7
    80003a5e:	af650513          	addi	a0,a0,-1290 # 8000a550 <etext+0x550>
    80003a62:	d7ffc0ef          	jal	800007e0 <panic>

0000000080003a66 <namei>:

struct inode*
namei(char *path)
{
    80003a66:	1101                	addi	sp,sp,-32
    80003a68:	ec06                	sd	ra,24(sp)
    80003a6a:	e822                	sd	s0,16(sp)
    80003a6c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003a6e:	fe040613          	addi	a2,s0,-32
    80003a72:	4581                	li	a1,0
    80003a74:	e29ff0ef          	jal	8000389c <namex>
}
    80003a78:	60e2                	ld	ra,24(sp)
    80003a7a:	6442                	ld	s0,16(sp)
    80003a7c:	6105                	addi	sp,sp,32
    80003a7e:	8082                	ret

0000000080003a80 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003a80:	1141                	addi	sp,sp,-16
    80003a82:	e406                	sd	ra,8(sp)
    80003a84:	e022                	sd	s0,0(sp)
    80003a86:	0800                	addi	s0,sp,16
    80003a88:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003a8a:	4585                	li	a1,1
    80003a8c:	e11ff0ef          	jal	8000389c <namex>
}
    80003a90:	60a2                	ld	ra,8(sp)
    80003a92:	6402                	ld	s0,0(sp)
    80003a94:	0141                	addi	sp,sp,16
    80003a96:	8082                	ret

0000000080003a98 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	e04a                	sd	s2,0(sp)
    80003aa2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003aa4:	00024917          	auipc	s2,0x24
    80003aa8:	85490913          	addi	s2,s2,-1964 # 800272f8 <log>
    80003aac:	01892583          	lw	a1,24(s2)
    80003ab0:	02492503          	lw	a0,36(s2)
    80003ab4:	8d0ff0ef          	jal	80002b84 <bread>
    80003ab8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003aba:	02892603          	lw	a2,40(s2)
    80003abe:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ac0:	00c05f63          	blez	a2,80003ade <write_head+0x46>
    80003ac4:	00024717          	auipc	a4,0x24
    80003ac8:	86070713          	addi	a4,a4,-1952 # 80027324 <log+0x2c>
    80003acc:	87aa                	mv	a5,a0
    80003ace:	060a                	slli	a2,a2,0x2
    80003ad0:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003ad2:	4314                	lw	a3,0(a4)
    80003ad4:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003ad6:	0711                	addi	a4,a4,4
    80003ad8:	0791                	addi	a5,a5,4
    80003ada:	fec79ce3          	bne	a5,a2,80003ad2 <write_head+0x3a>
  }
  bwrite(buf);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	97aff0ef          	jal	80002c5a <bwrite>
  brelse(buf);
    80003ae4:	8526                	mv	a0,s1
    80003ae6:	9a6ff0ef          	jal	80002c8c <brelse>
}
    80003aea:	60e2                	ld	ra,24(sp)
    80003aec:	6442                	ld	s0,16(sp)
    80003aee:	64a2                	ld	s1,8(sp)
    80003af0:	6902                	ld	s2,0(sp)
    80003af2:	6105                	addi	sp,sp,32
    80003af4:	8082                	ret

0000000080003af6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003af6:	00024797          	auipc	a5,0x24
    80003afa:	82a7a783          	lw	a5,-2006(a5) # 80027320 <log+0x28>
    80003afe:	0af05e63          	blez	a5,80003bba <install_trans+0xc4>
{
    80003b02:	715d                	addi	sp,sp,-80
    80003b04:	e486                	sd	ra,72(sp)
    80003b06:	e0a2                	sd	s0,64(sp)
    80003b08:	fc26                	sd	s1,56(sp)
    80003b0a:	f84a                	sd	s2,48(sp)
    80003b0c:	f44e                	sd	s3,40(sp)
    80003b0e:	f052                	sd	s4,32(sp)
    80003b10:	ec56                	sd	s5,24(sp)
    80003b12:	e85a                	sd	s6,16(sp)
    80003b14:	e45e                	sd	s7,8(sp)
    80003b16:	0880                	addi	s0,sp,80
    80003b18:	8b2a                	mv	s6,a0
    80003b1a:	00024a97          	auipc	s5,0x24
    80003b1e:	80aa8a93          	addi	s5,s5,-2038 # 80027324 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b22:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b24:	00007b97          	auipc	s7,0x7
    80003b28:	a3cb8b93          	addi	s7,s7,-1476 # 8000a560 <etext+0x560>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b2c:	00023a17          	auipc	s4,0x23
    80003b30:	7cca0a13          	addi	s4,s4,1996 # 800272f8 <log>
    80003b34:	a025                	j	80003b5c <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b36:	000aa603          	lw	a2,0(s5)
    80003b3a:	85ce                	mv	a1,s3
    80003b3c:	855e                	mv	a0,s7
    80003b3e:	9bdfc0ef          	jal	800004fa <printf>
    80003b42:	a839                	j	80003b60 <install_trans+0x6a>
    brelse(lbuf);
    80003b44:	854a                	mv	a0,s2
    80003b46:	946ff0ef          	jal	80002c8c <brelse>
    brelse(dbuf);
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	940ff0ef          	jal	80002c8c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b50:	2985                	addiw	s3,s3,1
    80003b52:	0a91                	addi	s5,s5,4
    80003b54:	028a2783          	lw	a5,40(s4)
    80003b58:	04f9d663          	bge	s3,a5,80003ba4 <install_trans+0xae>
    if(recovering) {
    80003b5c:	fc0b1de3          	bnez	s6,80003b36 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b60:	018a2583          	lw	a1,24(s4)
    80003b64:	013585bb          	addw	a1,a1,s3
    80003b68:	2585                	addiw	a1,a1,1
    80003b6a:	024a2503          	lw	a0,36(s4)
    80003b6e:	816ff0ef          	jal	80002b84 <bread>
    80003b72:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003b74:	000aa583          	lw	a1,0(s5)
    80003b78:	024a2503          	lw	a0,36(s4)
    80003b7c:	808ff0ef          	jal	80002b84 <bread>
    80003b80:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003b82:	40000613          	li	a2,1024
    80003b86:	05890593          	addi	a1,s2,88
    80003b8a:	05850513          	addi	a0,a0,88
    80003b8e:	970fd0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003b92:	8526                	mv	a0,s1
    80003b94:	8c6ff0ef          	jal	80002c5a <bwrite>
    if(recovering == 0)
    80003b98:	fa0b16e3          	bnez	s6,80003b44 <install_trans+0x4e>
      bunpin(dbuf);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	9aaff0ef          	jal	80002d48 <bunpin>
    80003ba2:	b74d                	j	80003b44 <install_trans+0x4e>
}
    80003ba4:	60a6                	ld	ra,72(sp)
    80003ba6:	6406                	ld	s0,64(sp)
    80003ba8:	74e2                	ld	s1,56(sp)
    80003baa:	7942                	ld	s2,48(sp)
    80003bac:	79a2                	ld	s3,40(sp)
    80003bae:	7a02                	ld	s4,32(sp)
    80003bb0:	6ae2                	ld	s5,24(sp)
    80003bb2:	6b42                	ld	s6,16(sp)
    80003bb4:	6ba2                	ld	s7,8(sp)
    80003bb6:	6161                	addi	sp,sp,80
    80003bb8:	8082                	ret
    80003bba:	8082                	ret

0000000080003bbc <initlog>:
{
    80003bbc:	7179                	addi	sp,sp,-48
    80003bbe:	f406                	sd	ra,40(sp)
    80003bc0:	f022                	sd	s0,32(sp)
    80003bc2:	ec26                	sd	s1,24(sp)
    80003bc4:	e84a                	sd	s2,16(sp)
    80003bc6:	e44e                	sd	s3,8(sp)
    80003bc8:	1800                	addi	s0,sp,48
    80003bca:	892a                	mv	s2,a0
    80003bcc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003bce:	00023497          	auipc	s1,0x23
    80003bd2:	72a48493          	addi	s1,s1,1834 # 800272f8 <log>
    80003bd6:	00007597          	auipc	a1,0x7
    80003bda:	9aa58593          	addi	a1,a1,-1622 # 8000a580 <etext+0x580>
    80003bde:	8526                	mv	a0,s1
    80003be0:	f6ffc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003be4:	0149a583          	lw	a1,20(s3)
    80003be8:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003bea:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	f95fe0ef          	jal	80002b84 <bread>
  log.lh.n = lh->n;
    80003bf4:	4d30                	lw	a2,88(a0)
    80003bf6:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003bf8:	00c05f63          	blez	a2,80003c16 <initlog+0x5a>
    80003bfc:	87aa                	mv	a5,a0
    80003bfe:	00023717          	auipc	a4,0x23
    80003c02:	72670713          	addi	a4,a4,1830 # 80027324 <log+0x2c>
    80003c06:	060a                	slli	a2,a2,0x2
    80003c08:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003c0a:	4ff4                	lw	a3,92(a5)
    80003c0c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c0e:	0791                	addi	a5,a5,4
    80003c10:	0711                	addi	a4,a4,4
    80003c12:	fec79ce3          	bne	a5,a2,80003c0a <initlog+0x4e>
  brelse(buf);
    80003c16:	876ff0ef          	jal	80002c8c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003c1a:	4505                	li	a0,1
    80003c1c:	edbff0ef          	jal	80003af6 <install_trans>
  log.lh.n = 0;
    80003c20:	00023797          	auipc	a5,0x23
    80003c24:	7007a023          	sw	zero,1792(a5) # 80027320 <log+0x28>
  write_head(); // clear the log
    80003c28:	e71ff0ef          	jal	80003a98 <write_head>
}
    80003c2c:	70a2                	ld	ra,40(sp)
    80003c2e:	7402                	ld	s0,32(sp)
    80003c30:	64e2                	ld	s1,24(sp)
    80003c32:	6942                	ld	s2,16(sp)
    80003c34:	69a2                	ld	s3,8(sp)
    80003c36:	6145                	addi	sp,sp,48
    80003c38:	8082                	ret

0000000080003c3a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003c3a:	1101                	addi	sp,sp,-32
    80003c3c:	ec06                	sd	ra,24(sp)
    80003c3e:	e822                	sd	s0,16(sp)
    80003c40:	e426                	sd	s1,8(sp)
    80003c42:	e04a                	sd	s2,0(sp)
    80003c44:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003c46:	00023517          	auipc	a0,0x23
    80003c4a:	6b250513          	addi	a0,a0,1714 # 800272f8 <log>
    80003c4e:	f81fc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003c52:	00023497          	auipc	s1,0x23
    80003c56:	6a648493          	addi	s1,s1,1702 # 800272f8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c5a:	4979                	li	s2,30
    80003c5c:	a029                	j	80003c66 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003c5e:	85a6                	mv	a1,s1
    80003c60:	8526                	mv	a0,s1
    80003c62:	ad8fe0ef          	jal	80001f3a <sleep>
    if(log.committing){
    80003c66:	509c                	lw	a5,32(s1)
    80003c68:	fbfd                	bnez	a5,80003c5e <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c6a:	4cd8                	lw	a4,28(s1)
    80003c6c:	2705                	addiw	a4,a4,1
    80003c6e:	0027179b          	slliw	a5,a4,0x2
    80003c72:	9fb9                	addw	a5,a5,a4
    80003c74:	0017979b          	slliw	a5,a5,0x1
    80003c78:	5494                	lw	a3,40(s1)
    80003c7a:	9fb5                	addw	a5,a5,a3
    80003c7c:	00f95763          	bge	s2,a5,80003c8a <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003c80:	85a6                	mv	a1,s1
    80003c82:	8526                	mv	a0,s1
    80003c84:	ab6fe0ef          	jal	80001f3a <sleep>
    80003c88:	bff9                	j	80003c66 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003c8a:	00023517          	auipc	a0,0x23
    80003c8e:	66e50513          	addi	a0,a0,1646 # 800272f8 <log>
    80003c92:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003c94:	fd3fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003c98:	60e2                	ld	ra,24(sp)
    80003c9a:	6442                	ld	s0,16(sp)
    80003c9c:	64a2                	ld	s1,8(sp)
    80003c9e:	6902                	ld	s2,0(sp)
    80003ca0:	6105                	addi	sp,sp,32
    80003ca2:	8082                	ret

0000000080003ca4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003ca4:	7139                	addi	sp,sp,-64
    80003ca6:	fc06                	sd	ra,56(sp)
    80003ca8:	f822                	sd	s0,48(sp)
    80003caa:	f426                	sd	s1,40(sp)
    80003cac:	f04a                	sd	s2,32(sp)
    80003cae:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003cb0:	00023497          	auipc	s1,0x23
    80003cb4:	64848493          	addi	s1,s1,1608 # 800272f8 <log>
    80003cb8:	8526                	mv	a0,s1
    80003cba:	f15fc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80003cbe:	4cdc                	lw	a5,28(s1)
    80003cc0:	37fd                	addiw	a5,a5,-1
    80003cc2:	0007891b          	sext.w	s2,a5
    80003cc6:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003cc8:	509c                	lw	a5,32(s1)
    80003cca:	ef9d                	bnez	a5,80003d08 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003ccc:	04091763          	bnez	s2,80003d1a <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003cd0:	00023497          	auipc	s1,0x23
    80003cd4:	62848493          	addi	s1,s1,1576 # 800272f8 <log>
    80003cd8:	4785                	li	a5,1
    80003cda:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003cdc:	8526                	mv	a0,s1
    80003cde:	f89fc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003ce2:	549c                	lw	a5,40(s1)
    80003ce4:	04f04b63          	bgtz	a5,80003d3a <end_op+0x96>
    acquire(&log.lock);
    80003ce8:	00023497          	auipc	s1,0x23
    80003cec:	61048493          	addi	s1,s1,1552 # 800272f8 <log>
    80003cf0:	8526                	mv	a0,s1
    80003cf2:	eddfc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80003cf6:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003cfa:	8526                	mv	a0,s1
    80003cfc:	a8afe0ef          	jal	80001f86 <wakeup>
    release(&log.lock);
    80003d00:	8526                	mv	a0,s1
    80003d02:	f65fc0ef          	jal	80000c66 <release>
}
    80003d06:	a025                	j	80003d2e <end_op+0x8a>
    80003d08:	ec4e                	sd	s3,24(sp)
    80003d0a:	e852                	sd	s4,16(sp)
    80003d0c:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003d0e:	00007517          	auipc	a0,0x7
    80003d12:	87a50513          	addi	a0,a0,-1926 # 8000a588 <etext+0x588>
    80003d16:	acbfc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80003d1a:	00023497          	auipc	s1,0x23
    80003d1e:	5de48493          	addi	s1,s1,1502 # 800272f8 <log>
    80003d22:	8526                	mv	a0,s1
    80003d24:	a62fe0ef          	jal	80001f86 <wakeup>
  release(&log.lock);
    80003d28:	8526                	mv	a0,s1
    80003d2a:	f3dfc0ef          	jal	80000c66 <release>
}
    80003d2e:	70e2                	ld	ra,56(sp)
    80003d30:	7442                	ld	s0,48(sp)
    80003d32:	74a2                	ld	s1,40(sp)
    80003d34:	7902                	ld	s2,32(sp)
    80003d36:	6121                	addi	sp,sp,64
    80003d38:	8082                	ret
    80003d3a:	ec4e                	sd	s3,24(sp)
    80003d3c:	e852                	sd	s4,16(sp)
    80003d3e:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d40:	00023a97          	auipc	s5,0x23
    80003d44:	5e4a8a93          	addi	s5,s5,1508 # 80027324 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003d48:	00023a17          	auipc	s4,0x23
    80003d4c:	5b0a0a13          	addi	s4,s4,1456 # 800272f8 <log>
    80003d50:	018a2583          	lw	a1,24(s4)
    80003d54:	012585bb          	addw	a1,a1,s2
    80003d58:	2585                	addiw	a1,a1,1
    80003d5a:	024a2503          	lw	a0,36(s4)
    80003d5e:	e27fe0ef          	jal	80002b84 <bread>
    80003d62:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003d64:	000aa583          	lw	a1,0(s5)
    80003d68:	024a2503          	lw	a0,36(s4)
    80003d6c:	e19fe0ef          	jal	80002b84 <bread>
    80003d70:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003d72:	40000613          	li	a2,1024
    80003d76:	05850593          	addi	a1,a0,88
    80003d7a:	05848513          	addi	a0,s1,88
    80003d7e:	f81fc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    80003d82:	8526                	mv	a0,s1
    80003d84:	ed7fe0ef          	jal	80002c5a <bwrite>
    brelse(from);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	f03fe0ef          	jal	80002c8c <brelse>
    brelse(to);
    80003d8e:	8526                	mv	a0,s1
    80003d90:	efdfe0ef          	jal	80002c8c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d94:	2905                	addiw	s2,s2,1
    80003d96:	0a91                	addi	s5,s5,4
    80003d98:	028a2783          	lw	a5,40(s4)
    80003d9c:	faf94ae3          	blt	s2,a5,80003d50 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003da0:	cf9ff0ef          	jal	80003a98 <write_head>
    install_trans(0); // Now install writes to home locations
    80003da4:	4501                	li	a0,0
    80003da6:	d51ff0ef          	jal	80003af6 <install_trans>
    log.lh.n = 0;
    80003daa:	00023797          	auipc	a5,0x23
    80003dae:	5607ab23          	sw	zero,1398(a5) # 80027320 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003db2:	ce7ff0ef          	jal	80003a98 <write_head>
    80003db6:	69e2                	ld	s3,24(sp)
    80003db8:	6a42                	ld	s4,16(sp)
    80003dba:	6aa2                	ld	s5,8(sp)
    80003dbc:	b735                	j	80003ce8 <end_op+0x44>

0000000080003dbe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003dbe:	1101                	addi	sp,sp,-32
    80003dc0:	ec06                	sd	ra,24(sp)
    80003dc2:	e822                	sd	s0,16(sp)
    80003dc4:	e426                	sd	s1,8(sp)
    80003dc6:	e04a                	sd	s2,0(sp)
    80003dc8:	1000                	addi	s0,sp,32
    80003dca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003dcc:	00023917          	auipc	s2,0x23
    80003dd0:	52c90913          	addi	s2,s2,1324 # 800272f8 <log>
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	df9fc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003dda:	02892603          	lw	a2,40(s2)
    80003dde:	47f5                	li	a5,29
    80003de0:	04c7cc63          	blt	a5,a2,80003e38 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003de4:	00023797          	auipc	a5,0x23
    80003de8:	5307a783          	lw	a5,1328(a5) # 80027314 <log+0x1c>
    80003dec:	04f05c63          	blez	a5,80003e44 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003df0:	4781                	li	a5,0
    80003df2:	04c05f63          	blez	a2,80003e50 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003df6:	44cc                	lw	a1,12(s1)
    80003df8:	00023717          	auipc	a4,0x23
    80003dfc:	52c70713          	addi	a4,a4,1324 # 80027324 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003e00:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003e02:	4314                	lw	a3,0(a4)
    80003e04:	04b68663          	beq	a3,a1,80003e50 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003e08:	2785                	addiw	a5,a5,1
    80003e0a:	0711                	addi	a4,a4,4
    80003e0c:	fef61be3          	bne	a2,a5,80003e02 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003e10:	0621                	addi	a2,a2,8
    80003e12:	060a                	slli	a2,a2,0x2
    80003e14:	00023797          	auipc	a5,0x23
    80003e18:	4e478793          	addi	a5,a5,1252 # 800272f8 <log>
    80003e1c:	97b2                	add	a5,a5,a2
    80003e1e:	44d8                	lw	a4,12(s1)
    80003e20:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003e22:	8526                	mv	a0,s1
    80003e24:	ef1fe0ef          	jal	80002d14 <bpin>
    log.lh.n++;
    80003e28:	00023717          	auipc	a4,0x23
    80003e2c:	4d070713          	addi	a4,a4,1232 # 800272f8 <log>
    80003e30:	571c                	lw	a5,40(a4)
    80003e32:	2785                	addiw	a5,a5,1
    80003e34:	d71c                	sw	a5,40(a4)
    80003e36:	a80d                	j	80003e68 <log_write+0xaa>
    panic("too big a transaction");
    80003e38:	00006517          	auipc	a0,0x6
    80003e3c:	76050513          	addi	a0,a0,1888 # 8000a598 <etext+0x598>
    80003e40:	9a1fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80003e44:	00006517          	auipc	a0,0x6
    80003e48:	76c50513          	addi	a0,a0,1900 # 8000a5b0 <etext+0x5b0>
    80003e4c:	995fc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80003e50:	00878693          	addi	a3,a5,8
    80003e54:	068a                	slli	a3,a3,0x2
    80003e56:	00023717          	auipc	a4,0x23
    80003e5a:	4a270713          	addi	a4,a4,1186 # 800272f8 <log>
    80003e5e:	9736                	add	a4,a4,a3
    80003e60:	44d4                	lw	a3,12(s1)
    80003e62:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003e64:	faf60fe3          	beq	a2,a5,80003e22 <log_write+0x64>
  }
  release(&log.lock);
    80003e68:	00023517          	auipc	a0,0x23
    80003e6c:	49050513          	addi	a0,a0,1168 # 800272f8 <log>
    80003e70:	df7fc0ef          	jal	80000c66 <release>
}
    80003e74:	60e2                	ld	ra,24(sp)
    80003e76:	6442                	ld	s0,16(sp)
    80003e78:	64a2                	ld	s1,8(sp)
    80003e7a:	6902                	ld	s2,0(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret

0000000080003e80 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	e426                	sd	s1,8(sp)
    80003e88:	e04a                	sd	s2,0(sp)
    80003e8a:	1000                	addi	s0,sp,32
    80003e8c:	84aa                	mv	s1,a0
    80003e8e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003e90:	00006597          	auipc	a1,0x6
    80003e94:	74058593          	addi	a1,a1,1856 # 8000a5d0 <etext+0x5d0>
    80003e98:	0521                	addi	a0,a0,8
    80003e9a:	cb5fc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    80003e9e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003ea2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003ea6:	0204a423          	sw	zero,40(s1)
}
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6902                	ld	s2,0(sp)
    80003eb2:	6105                	addi	sp,sp,32
    80003eb4:	8082                	ret

0000000080003eb6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003eb6:	1101                	addi	sp,sp,-32
    80003eb8:	ec06                	sd	ra,24(sp)
    80003eba:	e822                	sd	s0,16(sp)
    80003ebc:	e426                	sd	s1,8(sp)
    80003ebe:	e04a                	sd	s2,0(sp)
    80003ec0:	1000                	addi	s0,sp,32
    80003ec2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003ec4:	00850913          	addi	s2,a0,8
    80003ec8:	854a                	mv	a0,s2
    80003eca:	d05fc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80003ece:	409c                	lw	a5,0(s1)
    80003ed0:	c799                	beqz	a5,80003ede <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003ed2:	85ca                	mv	a1,s2
    80003ed4:	8526                	mv	a0,s1
    80003ed6:	864fe0ef          	jal	80001f3a <sleep>
  while (lk->locked) {
    80003eda:	409c                	lw	a5,0(s1)
    80003edc:	fbfd                	bnez	a5,80003ed2 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003ede:	4785                	li	a5,1
    80003ee0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003ee2:	a15fd0ef          	jal	800018f6 <myproc>
    80003ee6:	591c                	lw	a5,48(a0)
    80003ee8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003eea:	854a                	mv	a0,s2
    80003eec:	d7bfc0ef          	jal	80000c66 <release>
}
    80003ef0:	60e2                	ld	ra,24(sp)
    80003ef2:	6442                	ld	s0,16(sp)
    80003ef4:	64a2                	ld	s1,8(sp)
    80003ef6:	6902                	ld	s2,0(sp)
    80003ef8:	6105                	addi	sp,sp,32
    80003efa:	8082                	ret

0000000080003efc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003efc:	1101                	addi	sp,sp,-32
    80003efe:	ec06                	sd	ra,24(sp)
    80003f00:	e822                	sd	s0,16(sp)
    80003f02:	e426                	sd	s1,8(sp)
    80003f04:	e04a                	sd	s2,0(sp)
    80003f06:	1000                	addi	s0,sp,32
    80003f08:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003f0a:	00850913          	addi	s2,a0,8
    80003f0e:	854a                	mv	a0,s2
    80003f10:	cbffc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    80003f14:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003f18:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003f1c:	8526                	mv	a0,s1
    80003f1e:	868fe0ef          	jal	80001f86 <wakeup>
  release(&lk->lk);
    80003f22:	854a                	mv	a0,s2
    80003f24:	d43fc0ef          	jal	80000c66 <release>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret

0000000080003f34 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003f34:	7179                	addi	sp,sp,-48
    80003f36:	f406                	sd	ra,40(sp)
    80003f38:	f022                	sd	s0,32(sp)
    80003f3a:	ec26                	sd	s1,24(sp)
    80003f3c:	e84a                	sd	s2,16(sp)
    80003f3e:	1800                	addi	s0,sp,48
    80003f40:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003f42:	00850913          	addi	s2,a0,8
    80003f46:	854a                	mv	a0,s2
    80003f48:	c87fc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f4c:	409c                	lw	a5,0(s1)
    80003f4e:	ef81                	bnez	a5,80003f66 <holdingsleep+0x32>
    80003f50:	4481                	li	s1,0
  release(&lk->lk);
    80003f52:	854a                	mv	a0,s2
    80003f54:	d13fc0ef          	jal	80000c66 <release>
  return r;
}
    80003f58:	8526                	mv	a0,s1
    80003f5a:	70a2                	ld	ra,40(sp)
    80003f5c:	7402                	ld	s0,32(sp)
    80003f5e:	64e2                	ld	s1,24(sp)
    80003f60:	6942                	ld	s2,16(sp)
    80003f62:	6145                	addi	sp,sp,48
    80003f64:	8082                	ret
    80003f66:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f68:	0284a983          	lw	s3,40(s1)
    80003f6c:	98bfd0ef          	jal	800018f6 <myproc>
    80003f70:	5904                	lw	s1,48(a0)
    80003f72:	413484b3          	sub	s1,s1,s3
    80003f76:	0014b493          	seqz	s1,s1
    80003f7a:	69a2                	ld	s3,8(sp)
    80003f7c:	bfd9                	j	80003f52 <holdingsleep+0x1e>

0000000080003f7e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003f7e:	1141                	addi	sp,sp,-16
    80003f80:	e406                	sd	ra,8(sp)
    80003f82:	e022                	sd	s0,0(sp)
    80003f84:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80003f86:	00006597          	auipc	a1,0x6
    80003f8a:	65a58593          	addi	a1,a1,1626 # 8000a5e0 <etext+0x5e0>
    80003f8e:	00023517          	auipc	a0,0x23
    80003f92:	4b250513          	addi	a0,a0,1202 # 80027440 <ftable>
    80003f96:	bb9fc0ef          	jal	80000b4e <initlock>
}
    80003f9a:	60a2                	ld	ra,8(sp)
    80003f9c:	6402                	ld	s0,0(sp)
    80003f9e:	0141                	addi	sp,sp,16
    80003fa0:	8082                	ret

0000000080003fa2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80003fa2:	1101                	addi	sp,sp,-32
    80003fa4:	ec06                	sd	ra,24(sp)
    80003fa6:	e822                	sd	s0,16(sp)
    80003fa8:	e426                	sd	s1,8(sp)
    80003faa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80003fac:	00023517          	auipc	a0,0x23
    80003fb0:	49450513          	addi	a0,a0,1172 # 80027440 <ftable>
    80003fb4:	c1bfc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003fb8:	00023497          	auipc	s1,0x23
    80003fbc:	4a048493          	addi	s1,s1,1184 # 80027458 <ftable+0x18>
    80003fc0:	00024717          	auipc	a4,0x24
    80003fc4:	43870713          	addi	a4,a4,1080 # 800283f8 <disk>
    if(f->ref == 0){
    80003fc8:	40dc                	lw	a5,4(s1)
    80003fca:	cf89                	beqz	a5,80003fe4 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003fcc:	02848493          	addi	s1,s1,40
    80003fd0:	fee49ce3          	bne	s1,a4,80003fc8 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80003fd4:	00023517          	auipc	a0,0x23
    80003fd8:	46c50513          	addi	a0,a0,1132 # 80027440 <ftable>
    80003fdc:	c8bfc0ef          	jal	80000c66 <release>
  return 0;
    80003fe0:	4481                	li	s1,0
    80003fe2:	a809                	j	80003ff4 <filealloc+0x52>
      f->ref = 1;
    80003fe4:	4785                	li	a5,1
    80003fe6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80003fe8:	00023517          	auipc	a0,0x23
    80003fec:	45850513          	addi	a0,a0,1112 # 80027440 <ftable>
    80003ff0:	c77fc0ef          	jal	80000c66 <release>
}
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	60e2                	ld	ra,24(sp)
    80003ff8:	6442                	ld	s0,16(sp)
    80003ffa:	64a2                	ld	s1,8(sp)
    80003ffc:	6105                	addi	sp,sp,32
    80003ffe:	8082                	ret

0000000080004000 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004000:	1101                	addi	sp,sp,-32
    80004002:	ec06                	sd	ra,24(sp)
    80004004:	e822                	sd	s0,16(sp)
    80004006:	e426                	sd	s1,8(sp)
    80004008:	1000                	addi	s0,sp,32
    8000400a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000400c:	00023517          	auipc	a0,0x23
    80004010:	43450513          	addi	a0,a0,1076 # 80027440 <ftable>
    80004014:	bbbfc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004018:	40dc                	lw	a5,4(s1)
    8000401a:	02f05063          	blez	a5,8000403a <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000401e:	2785                	addiw	a5,a5,1
    80004020:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004022:	00023517          	auipc	a0,0x23
    80004026:	41e50513          	addi	a0,a0,1054 # 80027440 <ftable>
    8000402a:	c3dfc0ef          	jal	80000c66 <release>
  return f;
}
    8000402e:	8526                	mv	a0,s1
    80004030:	60e2                	ld	ra,24(sp)
    80004032:	6442                	ld	s0,16(sp)
    80004034:	64a2                	ld	s1,8(sp)
    80004036:	6105                	addi	sp,sp,32
    80004038:	8082                	ret
    panic("filedup");
    8000403a:	00006517          	auipc	a0,0x6
    8000403e:	5ae50513          	addi	a0,a0,1454 # 8000a5e8 <etext+0x5e8>
    80004042:	f9efc0ef          	jal	800007e0 <panic>

0000000080004046 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004046:	7139                	addi	sp,sp,-64
    80004048:	fc06                	sd	ra,56(sp)
    8000404a:	f822                	sd	s0,48(sp)
    8000404c:	f426                	sd	s1,40(sp)
    8000404e:	0080                	addi	s0,sp,64
    80004050:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004052:	00023517          	auipc	a0,0x23
    80004056:	3ee50513          	addi	a0,a0,1006 # 80027440 <ftable>
    8000405a:	b75fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    8000405e:	40dc                	lw	a5,4(s1)
    80004060:	04f05a63          	blez	a5,800040b4 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    80004064:	37fd                	addiw	a5,a5,-1
    80004066:	0007871b          	sext.w	a4,a5
    8000406a:	c0dc                	sw	a5,4(s1)
    8000406c:	04e04e63          	bgtz	a4,800040c8 <fileclose+0x82>
    80004070:	f04a                	sd	s2,32(sp)
    80004072:	ec4e                	sd	s3,24(sp)
    80004074:	e852                	sd	s4,16(sp)
    80004076:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004078:	0004a903          	lw	s2,0(s1)
    8000407c:	0094ca83          	lbu	s5,9(s1)
    80004080:	0104ba03          	ld	s4,16(s1)
    80004084:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004088:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000408c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004090:	00023517          	auipc	a0,0x23
    80004094:	3b050513          	addi	a0,a0,944 # 80027440 <ftable>
    80004098:	bcffc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    8000409c:	4785                	li	a5,1
    8000409e:	04f90063          	beq	s2,a5,800040de <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800040a2:	3979                	addiw	s2,s2,-2
    800040a4:	4785                	li	a5,1
    800040a6:	0527f563          	bgeu	a5,s2,800040f0 <fileclose+0xaa>
    800040aa:	7902                	ld	s2,32(sp)
    800040ac:	69e2                	ld	s3,24(sp)
    800040ae:	6a42                	ld	s4,16(sp)
    800040b0:	6aa2                	ld	s5,8(sp)
    800040b2:	a00d                	j	800040d4 <fileclose+0x8e>
    800040b4:	f04a                	sd	s2,32(sp)
    800040b6:	ec4e                	sd	s3,24(sp)
    800040b8:	e852                	sd	s4,16(sp)
    800040ba:	e456                	sd	s5,8(sp)
    panic("fileclose");
    800040bc:	00006517          	auipc	a0,0x6
    800040c0:	53450513          	addi	a0,a0,1332 # 8000a5f0 <etext+0x5f0>
    800040c4:	f1cfc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    800040c8:	00023517          	auipc	a0,0x23
    800040cc:	37850513          	addi	a0,a0,888 # 80027440 <ftable>
    800040d0:	b97fc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800040d4:	70e2                	ld	ra,56(sp)
    800040d6:	7442                	ld	s0,48(sp)
    800040d8:	74a2                	ld	s1,40(sp)
    800040da:	6121                	addi	sp,sp,64
    800040dc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800040de:	85d6                	mv	a1,s5
    800040e0:	8552                	mv	a0,s4
    800040e2:	348000ef          	jal	8000442a <pipeclose>
    800040e6:	7902                	ld	s2,32(sp)
    800040e8:	69e2                	ld	s3,24(sp)
    800040ea:	6a42                	ld	s4,16(sp)
    800040ec:	6aa2                	ld	s5,8(sp)
    800040ee:	b7dd                	j	800040d4 <fileclose+0x8e>
    begin_op();
    800040f0:	b4bff0ef          	jal	80003c3a <begin_op>
    iput(ff.ip);
    800040f4:	854e                	mv	a0,s3
    800040f6:	adcff0ef          	jal	800033d2 <iput>
    end_op();
    800040fa:	babff0ef          	jal	80003ca4 <end_op>
    800040fe:	7902                	ld	s2,32(sp)
    80004100:	69e2                	ld	s3,24(sp)
    80004102:	6a42                	ld	s4,16(sp)
    80004104:	6aa2                	ld	s5,8(sp)
    80004106:	b7f9                	j	800040d4 <fileclose+0x8e>

0000000080004108 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004108:	715d                	addi	sp,sp,-80
    8000410a:	e486                	sd	ra,72(sp)
    8000410c:	e0a2                	sd	s0,64(sp)
    8000410e:	fc26                	sd	s1,56(sp)
    80004110:	f44e                	sd	s3,40(sp)
    80004112:	0880                	addi	s0,sp,80
    80004114:	84aa                	mv	s1,a0
    80004116:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004118:	fdefd0ef          	jal	800018f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000411c:	409c                	lw	a5,0(s1)
    8000411e:	37f9                	addiw	a5,a5,-2
    80004120:	4705                	li	a4,1
    80004122:	04f76063          	bltu	a4,a5,80004162 <filestat+0x5a>
    80004126:	f84a                	sd	s2,48(sp)
    80004128:	892a                	mv	s2,a0
    ilock(f->ip);
    8000412a:	6c88                	ld	a0,24(s1)
    8000412c:	924ff0ef          	jal	80003250 <ilock>
    stati(f->ip, &st);
    80004130:	fb840593          	addi	a1,s0,-72
    80004134:	6c88                	ld	a0,24(s1)
    80004136:	c80ff0ef          	jal	800035b6 <stati>
    iunlock(f->ip);
    8000413a:	6c88                	ld	a0,24(s1)
    8000413c:	9c2ff0ef          	jal	800032fe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004140:	46e1                	li	a3,24
    80004142:	fb840613          	addi	a2,s0,-72
    80004146:	85ce                	mv	a1,s3
    80004148:	05093503          	ld	a0,80(s2)
    8000414c:	cbefd0ef          	jal	8000160a <copyout>
    80004150:	41f5551b          	sraiw	a0,a0,0x1f
    80004154:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004156:	60a6                	ld	ra,72(sp)
    80004158:	6406                	ld	s0,64(sp)
    8000415a:	74e2                	ld	s1,56(sp)
    8000415c:	79a2                	ld	s3,40(sp)
    8000415e:	6161                	addi	sp,sp,80
    80004160:	8082                	ret
  return -1;
    80004162:	557d                	li	a0,-1
    80004164:	bfcd                	j	80004156 <filestat+0x4e>

0000000080004166 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004166:	7179                	addi	sp,sp,-48
    80004168:	f406                	sd	ra,40(sp)
    8000416a:	f022                	sd	s0,32(sp)
    8000416c:	e84a                	sd	s2,16(sp)
    8000416e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004170:	00854783          	lbu	a5,8(a0)
    80004174:	cbc5                	beqz	a5,80004224 <fileread+0xbe>
    80004176:	ec26                	sd	s1,24(sp)
    80004178:	e44e                	sd	s3,8(sp)
    8000417a:	84aa                	mv	s1,a0
    8000417c:	89ae                	mv	s3,a1
    8000417e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004180:	411c                	lw	a5,0(a0)
    80004182:	4705                	li	a4,1
    80004184:	02e78863          	beq	a5,a4,800041b4 <fileread+0x4e>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004188:	470d                	li	a4,3
    8000418a:	02e78c63          	beq	a5,a4,800041c2 <fileread+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000418e:	4709                	li	a4,2
    80004190:	08e79463          	bne	a5,a4,80004218 <fileread+0xb2>
    // Use VFS dispatch if operations are set
    if(f->ip->i_fop && f->ip->i_fop->read) {
    80004194:	6d08                	ld	a0,24(a0)
    80004196:	6d3c                	ld	a5,88(a0)
    80004198:	cbb9                	beqz	a5,800041ee <fileread+0x88>
    8000419a:	639c                	ld	a5,0(a5)
    8000419c:	cba9                	beqz	a5,800041ee <fileread+0x88>
      r = f->ip->i_fop->read(f, addr, n);
    8000419e:	8526                	mv	a0,s1
    800041a0:	9782                	jalr	a5
    800041a2:	892a                	mv	s2,a0
    800041a4:	64e2                	ld	s1,24(sp)
    800041a6:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800041a8:	854a                	mv	a0,s2
    800041aa:	70a2                	ld	ra,40(sp)
    800041ac:	7402                	ld	s0,32(sp)
    800041ae:	6942                	ld	s2,16(sp)
    800041b0:	6145                	addi	sp,sp,48
    800041b2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800041b4:	6908                	ld	a0,16(a0)
    800041b6:	3b0000ef          	jal	80004566 <piperead>
    800041ba:	892a                	mv	s2,a0
    800041bc:	64e2                	ld	s1,24(sp)
    800041be:	69a2                	ld	s3,8(sp)
    800041c0:	b7e5                	j	800041a8 <fileread+0x42>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800041c2:	02451783          	lh	a5,36(a0)
    800041c6:	03079693          	slli	a3,a5,0x30
    800041ca:	92c1                	srli	a3,a3,0x30
    800041cc:	4725                	li	a4,9
    800041ce:	04d76d63          	bltu	a4,a3,80004228 <fileread+0xc2>
    800041d2:	0792                	slli	a5,a5,0x4
    800041d4:	00023717          	auipc	a4,0x23
    800041d8:	1cc70713          	addi	a4,a4,460 # 800273a0 <devsw>
    800041dc:	97ba                	add	a5,a5,a4
    800041de:	639c                	ld	a5,0(a5)
    800041e0:	cba1                	beqz	a5,80004230 <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    800041e2:	4505                	li	a0,1
    800041e4:	9782                	jalr	a5
    800041e6:	892a                	mv	s2,a0
    800041e8:	64e2                	ld	s1,24(sp)
    800041ea:	69a2                	ld	s3,8(sp)
    800041ec:	bf75                	j	800041a8 <fileread+0x42>
      ilock(f->ip);
    800041ee:	862ff0ef          	jal	80003250 <ilock>
      if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800041f2:	874a                	mv	a4,s2
    800041f4:	5094                	lw	a3,32(s1)
    800041f6:	864e                	mv	a2,s3
    800041f8:	4585                	li	a1,1
    800041fa:	6c88                	ld	a0,24(s1)
    800041fc:	be4ff0ef          	jal	800035e0 <readi>
    80004200:	892a                	mv	s2,a0
    80004202:	00a05563          	blez	a0,8000420c <fileread+0xa6>
        f->off += r;
    80004206:	509c                	lw	a5,32(s1)
    80004208:	9fa9                	addw	a5,a5,a0
    8000420a:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    8000420c:	6c88                	ld	a0,24(s1)
    8000420e:	8f0ff0ef          	jal	800032fe <iunlock>
    80004212:	64e2                	ld	s1,24(sp)
    80004214:	69a2                	ld	s3,8(sp)
    80004216:	bf49                	j	800041a8 <fileread+0x42>
    panic("fileread");
    80004218:	00006517          	auipc	a0,0x6
    8000421c:	3e850513          	addi	a0,a0,1000 # 8000a600 <etext+0x600>
    80004220:	dc0fc0ef          	jal	800007e0 <panic>
    return -1;
    80004224:	597d                	li	s2,-1
    80004226:	b749                	j	800041a8 <fileread+0x42>
      return -1;
    80004228:	597d                	li	s2,-1
    8000422a:	64e2                	ld	s1,24(sp)
    8000422c:	69a2                	ld	s3,8(sp)
    8000422e:	bfad                	j	800041a8 <fileread+0x42>
    80004230:	597d                	li	s2,-1
    80004232:	64e2                	ld	s1,24(sp)
    80004234:	69a2                	ld	s3,8(sp)
    80004236:	bf8d                	j	800041a8 <fileread+0x42>

0000000080004238 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004238:	00954783          	lbu	a5,9(a0)
    8000423c:	10078863          	beqz	a5,8000434c <filewrite+0x114>
{
    80004240:	715d                	addi	sp,sp,-80
    80004242:	e486                	sd	ra,72(sp)
    80004244:	e0a2                	sd	s0,64(sp)
    80004246:	fc26                	sd	s1,56(sp)
    80004248:	f44e                	sd	s3,40(sp)
    8000424a:	ec56                	sd	s5,24(sp)
    8000424c:	0880                	addi	s0,sp,80
    8000424e:	84aa                	mv	s1,a0
    80004250:	8aae                	mv	s5,a1
    80004252:	89b2                	mv	s3,a2
    return -1;

  if(f->type == FD_PIPE){
    80004254:	411c                	lw	a5,0(a0)
    80004256:	4705                	li	a4,1
    80004258:	00e78f63          	beq	a5,a4,80004276 <filewrite+0x3e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000425c:	470d                	li	a4,3
    8000425e:	02e78063          	beq	a5,a4,8000427e <filewrite+0x46>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004262:	4709                	li	a4,2
    80004264:	0ce79963          	bne	a5,a4,80004336 <filewrite+0xfe>
    // Use VFS dispatch if operations are set
    if(f->ip->i_fop && f->ip->i_fop->write) {
    80004268:	6d1c                	ld	a5,24(a0)
    8000426a:	6fbc                	ld	a5,88(a5)
    8000426c:	c3b1                	beqz	a5,800042b0 <filewrite+0x78>
    8000426e:	679c                	ld	a5,8(a5)
    80004270:	c3a1                	beqz	a5,800042b0 <filewrite+0x78>
      ret = f->ip->i_fop->write(f, addr, n);
    80004272:	9782                	jalr	a5
    80004274:	a03d                	j	800042a2 <filewrite+0x6a>
    ret = pipewrite(f->pipe, addr, n);
    80004276:	6908                	ld	a0,16(a0)
    80004278:	20a000ef          	jal	80004482 <pipewrite>
    8000427c:	a01d                	j	800042a2 <filewrite+0x6a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000427e:	02451783          	lh	a5,36(a0)
    80004282:	03079693          	slli	a3,a5,0x30
    80004286:	92c1                	srli	a3,a3,0x30
    80004288:	4725                	li	a4,9
    8000428a:	0cd76363          	bltu	a4,a3,80004350 <filewrite+0x118>
    8000428e:	0792                	slli	a5,a5,0x4
    80004290:	00023717          	auipc	a4,0x23
    80004294:	11070713          	addi	a4,a4,272 # 800273a0 <devsw>
    80004298:	97ba                	add	a5,a5,a4
    8000429a:	679c                	ld	a5,8(a5)
    8000429c:	cfc5                	beqz	a5,80004354 <filewrite+0x11c>
    ret = devsw[f->major].write(1, addr, n);
    8000429e:	4505                	li	a0,1
    800042a0:	9782                	jalr	a5
  } else {
    panic("filewrite");
  }

  return ret;
}
    800042a2:	60a6                	ld	ra,72(sp)
    800042a4:	6406                	ld	s0,64(sp)
    800042a6:	74e2                	ld	s1,56(sp)
    800042a8:	79a2                	ld	s3,40(sp)
    800042aa:	6ae2                	ld	s5,24(sp)
    800042ac:	6161                	addi	sp,sp,80
    800042ae:	8082                	ret
    800042b0:	f052                	sd	s4,32(sp)
    800042b2:	e45e                	sd	s7,8(sp)
    800042b4:	e062                	sd	s8,0(sp)
      while(i < n){
    800042b6:	4a01                	li	s4,0
        if(n1 > max)
    800042b8:	6b85                	lui	s7,0x1
    800042ba:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800042be:	6c05                	lui	s8,0x1
    800042c0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
      while(i < n){
    800042c4:	07305263          	blez	s3,80004328 <filewrite+0xf0>
    800042c8:	f84a                	sd	s2,48(sp)
    800042ca:	e85a                	sd	s6,16(sp)
    800042cc:	a089                	j	8000430e <filewrite+0xd6>
        if(n1 > max)
    800042ce:	00090b1b          	sext.w	s6,s2
        begin_op();
    800042d2:	969ff0ef          	jal	80003c3a <begin_op>
        ilock(f->ip);
    800042d6:	6c88                	ld	a0,24(s1)
    800042d8:	f79fe0ef          	jal	80003250 <ilock>
        if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800042dc:	875a                	mv	a4,s6
    800042de:	5094                	lw	a3,32(s1)
    800042e0:	015a0633          	add	a2,s4,s5
    800042e4:	4585                	li	a1,1
    800042e6:	6c88                	ld	a0,24(s1)
    800042e8:	bf4ff0ef          	jal	800036dc <writei>
    800042ec:	892a                	mv	s2,a0
    800042ee:	00a05563          	blez	a0,800042f8 <filewrite+0xc0>
          f->off += r;
    800042f2:	509c                	lw	a5,32(s1)
    800042f4:	9fa9                	addw	a5,a5,a0
    800042f6:	d09c                	sw	a5,32(s1)
        iunlock(f->ip);
    800042f8:	6c88                	ld	a0,24(s1)
    800042fa:	804ff0ef          	jal	800032fe <iunlock>
        end_op();
    800042fe:	9a7ff0ef          	jal	80003ca4 <end_op>
        if(r != n1){
    80004302:	032b1163          	bne	s6,s2,80004324 <filewrite+0xec>
        i += r;
    80004306:	01490a3b          	addw	s4,s2,s4
      while(i < n){
    8000430a:	013a5a63          	bge	s4,s3,8000431e <filewrite+0xe6>
        int n1 = n - i;
    8000430e:	4149893b          	subw	s2,s3,s4
        if(n1 > max)
    80004312:	0009079b          	sext.w	a5,s2
    80004316:	fafbdce3          	bge	s7,a5,800042ce <filewrite+0x96>
    8000431a:	8962                	mv	s2,s8
    8000431c:	bf4d                	j	800042ce <filewrite+0x96>
    8000431e:	7942                	ld	s2,48(sp)
    80004320:	6b42                	ld	s6,16(sp)
    80004322:	a019                	j	80004328 <filewrite+0xf0>
    80004324:	7942                	ld	s2,48(sp)
    80004326:	6b42                	ld	s6,16(sp)
      ret = (i == n ? n : -1);
    80004328:	03499863          	bne	s3,s4,80004358 <filewrite+0x120>
    8000432c:	854e                	mv	a0,s3
    8000432e:	7a02                	ld	s4,32(sp)
    80004330:	6ba2                	ld	s7,8(sp)
    80004332:	6c02                	ld	s8,0(sp)
    80004334:	b7bd                	j	800042a2 <filewrite+0x6a>
    80004336:	f84a                	sd	s2,48(sp)
    80004338:	f052                	sd	s4,32(sp)
    8000433a:	e85a                	sd	s6,16(sp)
    8000433c:	e45e                	sd	s7,8(sp)
    8000433e:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004340:	00006517          	auipc	a0,0x6
    80004344:	2d050513          	addi	a0,a0,720 # 8000a610 <etext+0x610>
    80004348:	c98fc0ef          	jal	800007e0 <panic>
    return -1;
    8000434c:	557d                	li	a0,-1
}
    8000434e:	8082                	ret
      return -1;
    80004350:	557d                	li	a0,-1
    80004352:	bf81                	j	800042a2 <filewrite+0x6a>
    80004354:	557d                	li	a0,-1
    80004356:	b7b1                	j	800042a2 <filewrite+0x6a>
      ret = (i == n ? n : -1);
    80004358:	557d                	li	a0,-1
    8000435a:	7a02                	ld	s4,32(sp)
    8000435c:	6ba2                	ld	s7,8(sp)
    8000435e:	6c02                	ld	s8,0(sp)
    80004360:	b789                	j	800042a2 <filewrite+0x6a>

0000000080004362 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004362:	7179                	addi	sp,sp,-48
    80004364:	f406                	sd	ra,40(sp)
    80004366:	f022                	sd	s0,32(sp)
    80004368:	ec26                	sd	s1,24(sp)
    8000436a:	e052                	sd	s4,0(sp)
    8000436c:	1800                	addi	s0,sp,48
    8000436e:	84aa                	mv	s1,a0
    80004370:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004372:	0005b023          	sd	zero,0(a1)
    80004376:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000437a:	c29ff0ef          	jal	80003fa2 <filealloc>
    8000437e:	e088                	sd	a0,0(s1)
    80004380:	c549                	beqz	a0,8000440a <pipealloc+0xa8>
    80004382:	c21ff0ef          	jal	80003fa2 <filealloc>
    80004386:	00aa3023          	sd	a0,0(s4)
    8000438a:	cd25                	beqz	a0,80004402 <pipealloc+0xa0>
    8000438c:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000438e:	f70fc0ef          	jal	80000afe <kalloc>
    80004392:	892a                	mv	s2,a0
    80004394:	c12d                	beqz	a0,800043f6 <pipealloc+0x94>
    80004396:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004398:	4985                	li	s3,1
    8000439a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000439e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800043a2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800043a6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800043aa:	00006597          	auipc	a1,0x6
    800043ae:	27658593          	addi	a1,a1,630 # 8000a620 <etext+0x620>
    800043b2:	f9cfc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800043b6:	609c                	ld	a5,0(s1)
    800043b8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800043bc:	609c                	ld	a5,0(s1)
    800043be:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800043c2:	609c                	ld	a5,0(s1)
    800043c4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800043c8:	609c                	ld	a5,0(s1)
    800043ca:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800043ce:	000a3783          	ld	a5,0(s4)
    800043d2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800043d6:	000a3783          	ld	a5,0(s4)
    800043da:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800043de:	000a3783          	ld	a5,0(s4)
    800043e2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800043e6:	000a3783          	ld	a5,0(s4)
    800043ea:	0127b823          	sd	s2,16(a5)
  return 0;
    800043ee:	4501                	li	a0,0
    800043f0:	6942                	ld	s2,16(sp)
    800043f2:	69a2                	ld	s3,8(sp)
    800043f4:	a01d                	j	8000441a <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800043f6:	6088                	ld	a0,0(s1)
    800043f8:	c119                	beqz	a0,800043fe <pipealloc+0x9c>
    800043fa:	6942                	ld	s2,16(sp)
    800043fc:	a029                	j	80004406 <pipealloc+0xa4>
    800043fe:	6942                	ld	s2,16(sp)
    80004400:	a029                	j	8000440a <pipealloc+0xa8>
    80004402:	6088                	ld	a0,0(s1)
    80004404:	c10d                	beqz	a0,80004426 <pipealloc+0xc4>
    fileclose(*f0);
    80004406:	c41ff0ef          	jal	80004046 <fileclose>
  if(*f1)
    8000440a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000440e:	557d                	li	a0,-1
  if(*f1)
    80004410:	c789                	beqz	a5,8000441a <pipealloc+0xb8>
    fileclose(*f1);
    80004412:	853e                	mv	a0,a5
    80004414:	c33ff0ef          	jal	80004046 <fileclose>
  return -1;
    80004418:	557d                	li	a0,-1
}
    8000441a:	70a2                	ld	ra,40(sp)
    8000441c:	7402                	ld	s0,32(sp)
    8000441e:	64e2                	ld	s1,24(sp)
    80004420:	6a02                	ld	s4,0(sp)
    80004422:	6145                	addi	sp,sp,48
    80004424:	8082                	ret
  return -1;
    80004426:	557d                	li	a0,-1
    80004428:	bfcd                	j	8000441a <pipealloc+0xb8>

000000008000442a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000442a:	1101                	addi	sp,sp,-32
    8000442c:	ec06                	sd	ra,24(sp)
    8000442e:	e822                	sd	s0,16(sp)
    80004430:	e426                	sd	s1,8(sp)
    80004432:	e04a                	sd	s2,0(sp)
    80004434:	1000                	addi	s0,sp,32
    80004436:	84aa                	mv	s1,a0
    80004438:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000443a:	f94fc0ef          	jal	80000bce <acquire>
  if(writable){
    8000443e:	02090763          	beqz	s2,8000446c <pipeclose+0x42>
    pi->writeopen = 0;
    80004442:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004446:	21848513          	addi	a0,s1,536
    8000444a:	b3dfd0ef          	jal	80001f86 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000444e:	2204b783          	ld	a5,544(s1)
    80004452:	e785                	bnez	a5,8000447a <pipeclose+0x50>
    release(&pi->lock);
    80004454:	8526                	mv	a0,s1
    80004456:	811fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    8000445a:	8526                	mv	a0,s1
    8000445c:	dc0fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004460:	60e2                	ld	ra,24(sp)
    80004462:	6442                	ld	s0,16(sp)
    80004464:	64a2                	ld	s1,8(sp)
    80004466:	6902                	ld	s2,0(sp)
    80004468:	6105                	addi	sp,sp,32
    8000446a:	8082                	ret
    pi->readopen = 0;
    8000446c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004470:	21c48513          	addi	a0,s1,540
    80004474:	b13fd0ef          	jal	80001f86 <wakeup>
    80004478:	bfd9                	j	8000444e <pipeclose+0x24>
    release(&pi->lock);
    8000447a:	8526                	mv	a0,s1
    8000447c:	feafc0ef          	jal	80000c66 <release>
}
    80004480:	b7c5                	j	80004460 <pipeclose+0x36>

0000000080004482 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004482:	711d                	addi	sp,sp,-96
    80004484:	ec86                	sd	ra,88(sp)
    80004486:	e8a2                	sd	s0,80(sp)
    80004488:	e4a6                	sd	s1,72(sp)
    8000448a:	e0ca                	sd	s2,64(sp)
    8000448c:	fc4e                	sd	s3,56(sp)
    8000448e:	f852                	sd	s4,48(sp)
    80004490:	f456                	sd	s5,40(sp)
    80004492:	1080                	addi	s0,sp,96
    80004494:	84aa                	mv	s1,a0
    80004496:	8aae                	mv	s5,a1
    80004498:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000449a:	c5cfd0ef          	jal	800018f6 <myproc>
    8000449e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800044a0:	8526                	mv	a0,s1
    800044a2:	f2cfc0ef          	jal	80000bce <acquire>
  while(i < n){
    800044a6:	0b405a63          	blez	s4,8000455a <pipewrite+0xd8>
    800044aa:	f05a                	sd	s6,32(sp)
    800044ac:	ec5e                	sd	s7,24(sp)
    800044ae:	e862                	sd	s8,16(sp)
  int i = 0;
    800044b0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800044b2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800044b4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800044b8:	21c48b93          	addi	s7,s1,540
    800044bc:	a81d                	j	800044f2 <pipewrite+0x70>
      release(&pi->lock);
    800044be:	8526                	mv	a0,s1
    800044c0:	fa6fc0ef          	jal	80000c66 <release>
      return -1;
    800044c4:	597d                	li	s2,-1
    800044c6:	7b02                	ld	s6,32(sp)
    800044c8:	6be2                	ld	s7,24(sp)
    800044ca:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800044cc:	854a                	mv	a0,s2
    800044ce:	60e6                	ld	ra,88(sp)
    800044d0:	6446                	ld	s0,80(sp)
    800044d2:	64a6                	ld	s1,72(sp)
    800044d4:	6906                	ld	s2,64(sp)
    800044d6:	79e2                	ld	s3,56(sp)
    800044d8:	7a42                	ld	s4,48(sp)
    800044da:	7aa2                	ld	s5,40(sp)
    800044dc:	6125                	addi	sp,sp,96
    800044de:	8082                	ret
      wakeup(&pi->nread);
    800044e0:	8562                	mv	a0,s8
    800044e2:	aa5fd0ef          	jal	80001f86 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800044e6:	85a6                	mv	a1,s1
    800044e8:	855e                	mv	a0,s7
    800044ea:	a51fd0ef          	jal	80001f3a <sleep>
  while(i < n){
    800044ee:	05495b63          	bge	s2,s4,80004544 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    800044f2:	2204a783          	lw	a5,544(s1)
    800044f6:	d7e1                	beqz	a5,800044be <pipewrite+0x3c>
    800044f8:	854e                	mv	a0,s3
    800044fa:	c79fd0ef          	jal	80002172 <killed>
    800044fe:	f161                	bnez	a0,800044be <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004500:	2184a783          	lw	a5,536(s1)
    80004504:	21c4a703          	lw	a4,540(s1)
    80004508:	2007879b          	addiw	a5,a5,512
    8000450c:	fcf70ae3          	beq	a4,a5,800044e0 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004510:	4685                	li	a3,1
    80004512:	01590633          	add	a2,s2,s5
    80004516:	faf40593          	addi	a1,s0,-81
    8000451a:	0509b503          	ld	a0,80(s3)
    8000451e:	9d0fd0ef          	jal	800016ee <copyin>
    80004522:	03650e63          	beq	a0,s6,8000455e <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004526:	21c4a783          	lw	a5,540(s1)
    8000452a:	0017871b          	addiw	a4,a5,1
    8000452e:	20e4ae23          	sw	a4,540(s1)
    80004532:	1ff7f793          	andi	a5,a5,511
    80004536:	97a6                	add	a5,a5,s1
    80004538:	faf44703          	lbu	a4,-81(s0)
    8000453c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004540:	2905                	addiw	s2,s2,1
    80004542:	b775                	j	800044ee <pipewrite+0x6c>
    80004544:	7b02                	ld	s6,32(sp)
    80004546:	6be2                	ld	s7,24(sp)
    80004548:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    8000454a:	21848513          	addi	a0,s1,536
    8000454e:	a39fd0ef          	jal	80001f86 <wakeup>
  release(&pi->lock);
    80004552:	8526                	mv	a0,s1
    80004554:	f12fc0ef          	jal	80000c66 <release>
  return i;
    80004558:	bf95                	j	800044cc <pipewrite+0x4a>
  int i = 0;
    8000455a:	4901                	li	s2,0
    8000455c:	b7fd                	j	8000454a <pipewrite+0xc8>
    8000455e:	7b02                	ld	s6,32(sp)
    80004560:	6be2                	ld	s7,24(sp)
    80004562:	6c42                	ld	s8,16(sp)
    80004564:	b7dd                	j	8000454a <pipewrite+0xc8>

0000000080004566 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004566:	715d                	addi	sp,sp,-80
    80004568:	e486                	sd	ra,72(sp)
    8000456a:	e0a2                	sd	s0,64(sp)
    8000456c:	fc26                	sd	s1,56(sp)
    8000456e:	f84a                	sd	s2,48(sp)
    80004570:	f44e                	sd	s3,40(sp)
    80004572:	f052                	sd	s4,32(sp)
    80004574:	ec56                	sd	s5,24(sp)
    80004576:	0880                	addi	s0,sp,80
    80004578:	84aa                	mv	s1,a0
    8000457a:	892e                	mv	s2,a1
    8000457c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000457e:	b78fd0ef          	jal	800018f6 <myproc>
    80004582:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004584:	8526                	mv	a0,s1
    80004586:	e48fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000458a:	2184a703          	lw	a4,536(s1)
    8000458e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004592:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004596:	02f71563          	bne	a4,a5,800045c0 <piperead+0x5a>
    8000459a:	2244a783          	lw	a5,548(s1)
    8000459e:	cb85                	beqz	a5,800045ce <piperead+0x68>
    if(killed(pr)){
    800045a0:	8552                	mv	a0,s4
    800045a2:	bd1fd0ef          	jal	80002172 <killed>
    800045a6:	ed19                	bnez	a0,800045c4 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800045a8:	85a6                	mv	a1,s1
    800045aa:	854e                	mv	a0,s3
    800045ac:	98ffd0ef          	jal	80001f3a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800045b0:	2184a703          	lw	a4,536(s1)
    800045b4:	21c4a783          	lw	a5,540(s1)
    800045b8:	fef701e3          	beq	a4,a5,8000459a <piperead+0x34>
    800045bc:	e85a                	sd	s6,16(sp)
    800045be:	a809                	j	800045d0 <piperead+0x6a>
    800045c0:	e85a                	sd	s6,16(sp)
    800045c2:	a039                	j	800045d0 <piperead+0x6a>
      release(&pi->lock);
    800045c4:	8526                	mv	a0,s1
    800045c6:	ea0fc0ef          	jal	80000c66 <release>
      return -1;
    800045ca:	59fd                	li	s3,-1
    800045cc:	a8b9                	j	8000462a <piperead+0xc4>
    800045ce:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800045d0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800045d2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800045d4:	05505363          	blez	s5,8000461a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800045d8:	2184a783          	lw	a5,536(s1)
    800045dc:	21c4a703          	lw	a4,540(s1)
    800045e0:	02f70d63          	beq	a4,a5,8000461a <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    800045e4:	1ff7f793          	andi	a5,a5,511
    800045e8:	97a6                	add	a5,a5,s1
    800045ea:	0187c783          	lbu	a5,24(a5)
    800045ee:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800045f2:	4685                	li	a3,1
    800045f4:	fbf40613          	addi	a2,s0,-65
    800045f8:	85ca                	mv	a1,s2
    800045fa:	050a3503          	ld	a0,80(s4)
    800045fe:	80cfd0ef          	jal	8000160a <copyout>
    80004602:	03650e63          	beq	a0,s6,8000463e <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004606:	2184a783          	lw	a5,536(s1)
    8000460a:	2785                	addiw	a5,a5,1
    8000460c:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004610:	2985                	addiw	s3,s3,1
    80004612:	0905                	addi	s2,s2,1
    80004614:	fd3a92e3          	bne	s5,s3,800045d8 <piperead+0x72>
    80004618:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000461a:	21c48513          	addi	a0,s1,540
    8000461e:	969fd0ef          	jal	80001f86 <wakeup>
  release(&pi->lock);
    80004622:	8526                	mv	a0,s1
    80004624:	e42fc0ef          	jal	80000c66 <release>
    80004628:	6b42                	ld	s6,16(sp)
  return i;
}
    8000462a:	854e                	mv	a0,s3
    8000462c:	60a6                	ld	ra,72(sp)
    8000462e:	6406                	ld	s0,64(sp)
    80004630:	74e2                	ld	s1,56(sp)
    80004632:	7942                	ld	s2,48(sp)
    80004634:	79a2                	ld	s3,40(sp)
    80004636:	7a02                	ld	s4,32(sp)
    80004638:	6ae2                	ld	s5,24(sp)
    8000463a:	6161                	addi	sp,sp,80
    8000463c:	8082                	ret
      if(i == 0)
    8000463e:	fc099ee3          	bnez	s3,8000461a <piperead+0xb4>
        i = -1;
    80004642:	89aa                	mv	s3,a0
    80004644:	bfd9                	j	8000461a <piperead+0xb4>

0000000080004646 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004646:	1141                	addi	sp,sp,-16
    80004648:	e422                	sd	s0,8(sp)
    8000464a:	0800                	addi	s0,sp,16
    8000464c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000464e:	8905                	andi	a0,a0,1
    80004650:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004652:	8b89                	andi	a5,a5,2
    80004654:	c399                	beqz	a5,8000465a <flags2perm+0x14>
      perm |= PTE_W;
    80004656:	00456513          	ori	a0,a0,4
    return perm;
}
    8000465a:	6422                	ld	s0,8(sp)
    8000465c:	0141                	addi	sp,sp,16
    8000465e:	8082                	ret

0000000080004660 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80004660:	df010113          	addi	sp,sp,-528
    80004664:	20113423          	sd	ra,520(sp)
    80004668:	20813023          	sd	s0,512(sp)
    8000466c:	ffa6                	sd	s1,504(sp)
    8000466e:	fbca                	sd	s2,496(sp)
    80004670:	0c00                	addi	s0,sp,528
    80004672:	892a                	mv	s2,a0
    80004674:	dea43c23          	sd	a0,-520(s0)
    80004678:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000467c:	a7afd0ef          	jal	800018f6 <myproc>
    80004680:	84aa                	mv	s1,a0

  begin_op();
    80004682:	db8ff0ef          	jal	80003c3a <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004686:	854a                	mv	a0,s2
    80004688:	bdeff0ef          	jal	80003a66 <namei>
    8000468c:	c931                	beqz	a0,800046e0 <kexec+0x80>
    8000468e:	f3d2                	sd	s4,480(sp)
    80004690:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004692:	bbffe0ef          	jal	80003250 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004696:	04000713          	li	a4,64
    8000469a:	4681                	li	a3,0
    8000469c:	e5040613          	addi	a2,s0,-432
    800046a0:	4581                	li	a1,0
    800046a2:	8552                	mv	a0,s4
    800046a4:	f3dfe0ef          	jal	800035e0 <readi>
    800046a8:	04000793          	li	a5,64
    800046ac:	00f51a63          	bne	a0,a5,800046c0 <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800046b0:	e5042703          	lw	a4,-432(s0)
    800046b4:	464c47b7          	lui	a5,0x464c4
    800046b8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800046bc:	02f70663          	beq	a4,a5,800046e8 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800046c0:	8552                	mv	a0,s4
    800046c2:	d99fe0ef          	jal	8000345a <iunlockput>
    end_op();
    800046c6:	ddeff0ef          	jal	80003ca4 <end_op>
  }
  return -1;
    800046ca:	557d                	li	a0,-1
    800046cc:	7a1e                	ld	s4,480(sp)
}
    800046ce:	20813083          	ld	ra,520(sp)
    800046d2:	20013403          	ld	s0,512(sp)
    800046d6:	74fe                	ld	s1,504(sp)
    800046d8:	795e                	ld	s2,496(sp)
    800046da:	21010113          	addi	sp,sp,528
    800046de:	8082                	ret
    end_op();
    800046e0:	dc4ff0ef          	jal	80003ca4 <end_op>
    return -1;
    800046e4:	557d                	li	a0,-1
    800046e6:	b7e5                	j	800046ce <kexec+0x6e>
    800046e8:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800046ea:	8526                	mv	a0,s1
    800046ec:	b4afd0ef          	jal	80001a36 <proc_pagetable>
    800046f0:	8b2a                	mv	s6,a0
    800046f2:	2c050b63          	beqz	a0,800049c8 <kexec+0x368>
    800046f6:	f7ce                	sd	s3,488(sp)
    800046f8:	efd6                	sd	s5,472(sp)
    800046fa:	e7de                	sd	s7,456(sp)
    800046fc:	e3e2                	sd	s8,448(sp)
    800046fe:	ff66                	sd	s9,440(sp)
    80004700:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004702:	e7042d03          	lw	s10,-400(s0)
    80004706:	e8845783          	lhu	a5,-376(s0)
    8000470a:	12078963          	beqz	a5,8000483c <kexec+0x1dc>
    8000470e:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004710:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004712:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004714:	6c85                	lui	s9,0x1
    80004716:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000471a:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000471e:	6a85                	lui	s5,0x1
    80004720:	a085                	j	80004780 <kexec+0x120>
      panic("loadseg: address should exist");
    80004722:	00006517          	auipc	a0,0x6
    80004726:	f0650513          	addi	a0,a0,-250 # 8000a628 <etext+0x628>
    8000472a:	8b6fc0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    8000472e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004730:	8726                	mv	a4,s1
    80004732:	012c06bb          	addw	a3,s8,s2
    80004736:	4581                	li	a1,0
    80004738:	8552                	mv	a0,s4
    8000473a:	ea7fe0ef          	jal	800035e0 <readi>
    8000473e:	2501                	sext.w	a0,a0
    80004740:	24a49a63          	bne	s1,a0,80004994 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004744:	012a893b          	addw	s2,s5,s2
    80004748:	03397363          	bgeu	s2,s3,8000476e <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    8000474c:	02091593          	slli	a1,s2,0x20
    80004750:	9181                	srli	a1,a1,0x20
    80004752:	95de                	add	a1,a1,s7
    80004754:	855a                	mv	a0,s6
    80004756:	883fc0ef          	jal	80000fd8 <walkaddr>
    8000475a:	862a                	mv	a2,a0
    if(pa == 0)
    8000475c:	d179                	beqz	a0,80004722 <kexec+0xc2>
    if(sz - i < PGSIZE)
    8000475e:	412984bb          	subw	s1,s3,s2
    80004762:	0004879b          	sext.w	a5,s1
    80004766:	fcfcf4e3          	bgeu	s9,a5,8000472e <kexec+0xce>
    8000476a:	84d6                	mv	s1,s5
    8000476c:	b7c9                	j	8000472e <kexec+0xce>
    sz = sz1;
    8000476e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004772:	2d85                	addiw	s11,s11,1
    80004774:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004778:	e8845783          	lhu	a5,-376(s0)
    8000477c:	08fdd063          	bge	s11,a5,800047fc <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004780:	2d01                	sext.w	s10,s10
    80004782:	03800713          	li	a4,56
    80004786:	86ea                	mv	a3,s10
    80004788:	e1840613          	addi	a2,s0,-488
    8000478c:	4581                	li	a1,0
    8000478e:	8552                	mv	a0,s4
    80004790:	e51fe0ef          	jal	800035e0 <readi>
    80004794:	03800793          	li	a5,56
    80004798:	1cf51663          	bne	a0,a5,80004964 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    8000479c:	e1842783          	lw	a5,-488(s0)
    800047a0:	4705                	li	a4,1
    800047a2:	fce798e3          	bne	a5,a4,80004772 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    800047a6:	e4043483          	ld	s1,-448(s0)
    800047aa:	e3843783          	ld	a5,-456(s0)
    800047ae:	1af4ef63          	bltu	s1,a5,8000496c <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800047b2:	e2843783          	ld	a5,-472(s0)
    800047b6:	94be                	add	s1,s1,a5
    800047b8:	1af4ee63          	bltu	s1,a5,80004974 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    800047bc:	df043703          	ld	a4,-528(s0)
    800047c0:	8ff9                	and	a5,a5,a4
    800047c2:	1a079d63          	bnez	a5,8000497c <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800047c6:	e1c42503          	lw	a0,-484(s0)
    800047ca:	e7dff0ef          	jal	80004646 <flags2perm>
    800047ce:	86aa                	mv	a3,a0
    800047d0:	8626                	mv	a2,s1
    800047d2:	85ca                	mv	a1,s2
    800047d4:	855a                	mv	a0,s6
    800047d6:	adbfc0ef          	jal	800012b0 <uvmalloc>
    800047da:	e0a43423          	sd	a0,-504(s0)
    800047de:	1a050363          	beqz	a0,80004984 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800047e2:	e2843b83          	ld	s7,-472(s0)
    800047e6:	e2042c03          	lw	s8,-480(s0)
    800047ea:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800047ee:	00098463          	beqz	s3,800047f6 <kexec+0x196>
    800047f2:	4901                	li	s2,0
    800047f4:	bfa1                	j	8000474c <kexec+0xec>
    sz = sz1;
    800047f6:	e0843903          	ld	s2,-504(s0)
    800047fa:	bfa5                	j	80004772 <kexec+0x112>
    800047fc:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800047fe:	8552                	mv	a0,s4
    80004800:	c5bfe0ef          	jal	8000345a <iunlockput>
  end_op();
    80004804:	ca0ff0ef          	jal	80003ca4 <end_op>
  p = myproc();
    80004808:	8eefd0ef          	jal	800018f6 <myproc>
    8000480c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000480e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004812:	6985                	lui	s3,0x1
    80004814:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004816:	99ca                	add	s3,s3,s2
    80004818:	77fd                	lui	a5,0xfffff
    8000481a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    8000481e:	4691                	li	a3,4
    80004820:	6609                	lui	a2,0x2
    80004822:	964e                	add	a2,a2,s3
    80004824:	85ce                	mv	a1,s3
    80004826:	855a                	mv	a0,s6
    80004828:	a89fc0ef          	jal	800012b0 <uvmalloc>
    8000482c:	892a                	mv	s2,a0
    8000482e:	e0a43423          	sd	a0,-504(s0)
    80004832:	e519                	bnez	a0,80004840 <kexec+0x1e0>
  if(pagetable)
    80004834:	e1343423          	sd	s3,-504(s0)
    80004838:	4a01                	li	s4,0
    8000483a:	aab1                	j	80004996 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000483c:	4901                	li	s2,0
    8000483e:	b7c1                	j	800047fe <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004840:	75f9                	lui	a1,0xffffe
    80004842:	95aa                	add	a1,a1,a0
    80004844:	855a                	mv	a0,s6
    80004846:	c41fc0ef          	jal	80001486 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    8000484a:	7bfd                	lui	s7,0xfffff
    8000484c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000484e:	e0043783          	ld	a5,-512(s0)
    80004852:	6388                	ld	a0,0(a5)
    80004854:	cd39                	beqz	a0,800048b2 <kexec+0x252>
    80004856:	e9040993          	addi	s3,s0,-368
    8000485a:	f9040c13          	addi	s8,s0,-112
    8000485e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004860:	db2fc0ef          	jal	80000e12 <strlen>
    80004864:	0015079b          	addiw	a5,a0,1
    80004868:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000486c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004870:	11796e63          	bltu	s2,s7,8000498c <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004874:	e0043d03          	ld	s10,-512(s0)
    80004878:	000d3a03          	ld	s4,0(s10)
    8000487c:	8552                	mv	a0,s4
    8000487e:	d94fc0ef          	jal	80000e12 <strlen>
    80004882:	0015069b          	addiw	a3,a0,1
    80004886:	8652                	mv	a2,s4
    80004888:	85ca                	mv	a1,s2
    8000488a:	855a                	mv	a0,s6
    8000488c:	d7ffc0ef          	jal	8000160a <copyout>
    80004890:	10054063          	bltz	a0,80004990 <kexec+0x330>
    ustack[argc] = sp;
    80004894:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004898:	0485                	addi	s1,s1,1
    8000489a:	008d0793          	addi	a5,s10,8
    8000489e:	e0f43023          	sd	a5,-512(s0)
    800048a2:	008d3503          	ld	a0,8(s10)
    800048a6:	c909                	beqz	a0,800048b8 <kexec+0x258>
    if(argc >= MAXARG)
    800048a8:	09a1                	addi	s3,s3,8
    800048aa:	fb899be3          	bne	s3,s8,80004860 <kexec+0x200>
  ip = 0;
    800048ae:	4a01                	li	s4,0
    800048b0:	a0dd                	j	80004996 <kexec+0x336>
  sp = sz;
    800048b2:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800048b6:	4481                	li	s1,0
  ustack[argc] = 0;
    800048b8:	00349793          	slli	a5,s1,0x3
    800048bc:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffcff78>
    800048c0:	97a2                	add	a5,a5,s0
    800048c2:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800048c6:	00148693          	addi	a3,s1,1
    800048ca:	068e                	slli	a3,a3,0x3
    800048cc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800048d0:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800048d4:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800048d8:	f5796ee3          	bltu	s2,s7,80004834 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800048dc:	e9040613          	addi	a2,s0,-368
    800048e0:	85ca                	mv	a1,s2
    800048e2:	855a                	mv	a0,s6
    800048e4:	d27fc0ef          	jal	8000160a <copyout>
    800048e8:	0e054263          	bltz	a0,800049cc <kexec+0x36c>
  p->trapframe->a1 = sp;
    800048ec:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800048f0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800048f4:	df843783          	ld	a5,-520(s0)
    800048f8:	0007c703          	lbu	a4,0(a5)
    800048fc:	cf11                	beqz	a4,80004918 <kexec+0x2b8>
    800048fe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004900:	02f00693          	li	a3,47
    80004904:	a039                	j	80004912 <kexec+0x2b2>
      last = s+1;
    80004906:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000490a:	0785                	addi	a5,a5,1
    8000490c:	fff7c703          	lbu	a4,-1(a5)
    80004910:	c701                	beqz	a4,80004918 <kexec+0x2b8>
    if(*s == '/')
    80004912:	fed71ce3          	bne	a4,a3,8000490a <kexec+0x2aa>
    80004916:	bfc5                	j	80004906 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004918:	4641                	li	a2,16
    8000491a:	df843583          	ld	a1,-520(s0)
    8000491e:	158a8513          	addi	a0,s5,344
    80004922:	cbefc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004926:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000492a:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000492e:	e0843783          	ld	a5,-504(s0)
    80004932:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004936:	058ab783          	ld	a5,88(s5)
    8000493a:	e6843703          	ld	a4,-408(s0)
    8000493e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004940:	058ab783          	ld	a5,88(s5)
    80004944:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004948:	85e6                	mv	a1,s9
    8000494a:	970fd0ef          	jal	80001aba <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000494e:	0004851b          	sext.w	a0,s1
    80004952:	79be                	ld	s3,488(sp)
    80004954:	7a1e                	ld	s4,480(sp)
    80004956:	6afe                	ld	s5,472(sp)
    80004958:	6b5e                	ld	s6,464(sp)
    8000495a:	6bbe                	ld	s7,456(sp)
    8000495c:	6c1e                	ld	s8,448(sp)
    8000495e:	7cfa                	ld	s9,440(sp)
    80004960:	7d5a                	ld	s10,432(sp)
    80004962:	b3b5                	j	800046ce <kexec+0x6e>
    80004964:	e1243423          	sd	s2,-504(s0)
    80004968:	7dba                	ld	s11,424(sp)
    8000496a:	a035                	j	80004996 <kexec+0x336>
    8000496c:	e1243423          	sd	s2,-504(s0)
    80004970:	7dba                	ld	s11,424(sp)
    80004972:	a015                	j	80004996 <kexec+0x336>
    80004974:	e1243423          	sd	s2,-504(s0)
    80004978:	7dba                	ld	s11,424(sp)
    8000497a:	a831                	j	80004996 <kexec+0x336>
    8000497c:	e1243423          	sd	s2,-504(s0)
    80004980:	7dba                	ld	s11,424(sp)
    80004982:	a811                	j	80004996 <kexec+0x336>
    80004984:	e1243423          	sd	s2,-504(s0)
    80004988:	7dba                	ld	s11,424(sp)
    8000498a:	a031                	j	80004996 <kexec+0x336>
  ip = 0;
    8000498c:	4a01                	li	s4,0
    8000498e:	a021                	j	80004996 <kexec+0x336>
    80004990:	4a01                	li	s4,0
  if(pagetable)
    80004992:	a011                	j	80004996 <kexec+0x336>
    80004994:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004996:	e0843583          	ld	a1,-504(s0)
    8000499a:	855a                	mv	a0,s6
    8000499c:	91efd0ef          	jal	80001aba <proc_freepagetable>
  return -1;
    800049a0:	557d                	li	a0,-1
  if(ip){
    800049a2:	000a1b63          	bnez	s4,800049b8 <kexec+0x358>
    800049a6:	79be                	ld	s3,488(sp)
    800049a8:	7a1e                	ld	s4,480(sp)
    800049aa:	6afe                	ld	s5,472(sp)
    800049ac:	6b5e                	ld	s6,464(sp)
    800049ae:	6bbe                	ld	s7,456(sp)
    800049b0:	6c1e                	ld	s8,448(sp)
    800049b2:	7cfa                	ld	s9,440(sp)
    800049b4:	7d5a                	ld	s10,432(sp)
    800049b6:	bb21                	j	800046ce <kexec+0x6e>
    800049b8:	79be                	ld	s3,488(sp)
    800049ba:	6afe                	ld	s5,472(sp)
    800049bc:	6b5e                	ld	s6,464(sp)
    800049be:	6bbe                	ld	s7,456(sp)
    800049c0:	6c1e                	ld	s8,448(sp)
    800049c2:	7cfa                	ld	s9,440(sp)
    800049c4:	7d5a                	ld	s10,432(sp)
    800049c6:	b9ed                	j	800046c0 <kexec+0x60>
    800049c8:	6b5e                	ld	s6,464(sp)
    800049ca:	b9dd                	j	800046c0 <kexec+0x60>
  sz = sz1;
    800049cc:	e0843983          	ld	s3,-504(s0)
    800049d0:	b595                	j	80004834 <kexec+0x1d4>

00000000800049d2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800049d2:	7179                	addi	sp,sp,-48
    800049d4:	f406                	sd	ra,40(sp)
    800049d6:	f022                	sd	s0,32(sp)
    800049d8:	ec26                	sd	s1,24(sp)
    800049da:	e84a                	sd	s2,16(sp)
    800049dc:	1800                	addi	s0,sp,48
    800049de:	892e                	mv	s2,a1
    800049e0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800049e2:	fdc40593          	addi	a1,s0,-36
    800049e6:	e65fd0ef          	jal	8000284a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800049ea:	fdc42703          	lw	a4,-36(s0)
    800049ee:	47bd                	li	a5,15
    800049f0:	02e7e963          	bltu	a5,a4,80004a22 <argfd+0x50>
    800049f4:	f03fc0ef          	jal	800018f6 <myproc>
    800049f8:	fdc42703          	lw	a4,-36(s0)
    800049fc:	01a70793          	addi	a5,a4,26
    80004a00:	078e                	slli	a5,a5,0x3
    80004a02:	953e                	add	a0,a0,a5
    80004a04:	611c                	ld	a5,0(a0)
    80004a06:	c385                	beqz	a5,80004a26 <argfd+0x54>
    return -1;
  if(pfd)
    80004a08:	00090463          	beqz	s2,80004a10 <argfd+0x3e>
    *pfd = fd;
    80004a0c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004a10:	4501                	li	a0,0
  if(pf)
    80004a12:	c091                	beqz	s1,80004a16 <argfd+0x44>
    *pf = f;
    80004a14:	e09c                	sd	a5,0(s1)
}
    80004a16:	70a2                	ld	ra,40(sp)
    80004a18:	7402                	ld	s0,32(sp)
    80004a1a:	64e2                	ld	s1,24(sp)
    80004a1c:	6942                	ld	s2,16(sp)
    80004a1e:	6145                	addi	sp,sp,48
    80004a20:	8082                	ret
    return -1;
    80004a22:	557d                	li	a0,-1
    80004a24:	bfcd                	j	80004a16 <argfd+0x44>
    80004a26:	557d                	li	a0,-1
    80004a28:	b7fd                	j	80004a16 <argfd+0x44>

0000000080004a2a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004a2a:	1101                	addi	sp,sp,-32
    80004a2c:	ec06                	sd	ra,24(sp)
    80004a2e:	e822                	sd	s0,16(sp)
    80004a30:	e426                	sd	s1,8(sp)
    80004a32:	1000                	addi	s0,sp,32
    80004a34:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004a36:	ec1fc0ef          	jal	800018f6 <myproc>
    80004a3a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004a3c:	0d050793          	addi	a5,a0,208
    80004a40:	4501                	li	a0,0
    80004a42:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004a44:	6398                	ld	a4,0(a5)
    80004a46:	cb19                	beqz	a4,80004a5c <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004a48:	2505                	addiw	a0,a0,1
    80004a4a:	07a1                	addi	a5,a5,8
    80004a4c:	fed51ce3          	bne	a0,a3,80004a44 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004a50:	557d                	li	a0,-1
}
    80004a52:	60e2                	ld	ra,24(sp)
    80004a54:	6442                	ld	s0,16(sp)
    80004a56:	64a2                	ld	s1,8(sp)
    80004a58:	6105                	addi	sp,sp,32
    80004a5a:	8082                	ret
      p->ofile[fd] = f;
    80004a5c:	01a50793          	addi	a5,a0,26
    80004a60:	078e                	slli	a5,a5,0x3
    80004a62:	963e                	add	a2,a2,a5
    80004a64:	e204                	sd	s1,0(a2)
      return fd;
    80004a66:	b7f5                	j	80004a52 <fdalloc+0x28>

0000000080004a68 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004a68:	715d                	addi	sp,sp,-80
    80004a6a:	e486                	sd	ra,72(sp)
    80004a6c:	e0a2                	sd	s0,64(sp)
    80004a6e:	fc26                	sd	s1,56(sp)
    80004a70:	f84a                	sd	s2,48(sp)
    80004a72:	f44e                	sd	s3,40(sp)
    80004a74:	ec56                	sd	s5,24(sp)
    80004a76:	e85a                	sd	s6,16(sp)
    80004a78:	0880                	addi	s0,sp,80
    80004a7a:	8b2e                	mv	s6,a1
    80004a7c:	89b2                	mv	s3,a2
    80004a7e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004a80:	fb040593          	addi	a1,s0,-80
    80004a84:	ffdfe0ef          	jal	80003a80 <nameiparent>
    80004a88:	84aa                	mv	s1,a0
    80004a8a:	10050a63          	beqz	a0,80004b9e <create+0x136>
    return 0;

  ilock(dp);
    80004a8e:	fc2fe0ef          	jal	80003250 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a92:	4601                	li	a2,0
    80004a94:	fb040593          	addi	a1,s0,-80
    80004a98:	8526                	mv	a0,s1
    80004a9a:	d67fe0ef          	jal	80003800 <dirlookup>
    80004a9e:	8aaa                	mv	s5,a0
    80004aa0:	c129                	beqz	a0,80004ae2 <create+0x7a>
    iunlockput(dp);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	9b7fe0ef          	jal	8000345a <iunlockput>
    ilock(ip);
    80004aa8:	8556                	mv	a0,s5
    80004aaa:	fa6fe0ef          	jal	80003250 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004aae:	4789                	li	a5,2
    80004ab0:	02fb1463          	bne	s6,a5,80004ad8 <create+0x70>
    80004ab4:	060ad783          	lhu	a5,96(s5)
    80004ab8:	37f9                	addiw	a5,a5,-2
    80004aba:	17c2                	slli	a5,a5,0x30
    80004abc:	93c1                	srli	a5,a5,0x30
    80004abe:	4705                	li	a4,1
    80004ac0:	00f76c63          	bltu	a4,a5,80004ad8 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004ac4:	8556                	mv	a0,s5
    80004ac6:	60a6                	ld	ra,72(sp)
    80004ac8:	6406                	ld	s0,64(sp)
    80004aca:	74e2                	ld	s1,56(sp)
    80004acc:	7942                	ld	s2,48(sp)
    80004ace:	79a2                	ld	s3,40(sp)
    80004ad0:	6ae2                	ld	s5,24(sp)
    80004ad2:	6b42                	ld	s6,16(sp)
    80004ad4:	6161                	addi	sp,sp,80
    80004ad6:	8082                	ret
    iunlockput(ip);
    80004ad8:	8556                	mv	a0,s5
    80004ada:	981fe0ef          	jal	8000345a <iunlockput>
    return 0;
    80004ade:	4a81                	li	s5,0
    80004ae0:	b7d5                	j	80004ac4 <create+0x5c>
    80004ae2:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004ae4:	85da                	mv	a1,s6
    80004ae6:	4088                	lw	a0,0(s1)
    80004ae8:	e76fe0ef          	jal	8000315e <ialloc>
    80004aec:	8a2a                	mv	s4,a0
    80004aee:	cd15                	beqz	a0,80004b2a <create+0xc2>
  ilock(ip);
    80004af0:	f60fe0ef          	jal	80003250 <ilock>
  ip->major = major;
    80004af4:	073a1123          	sh	s3,98(s4)
  ip->minor = minor;
    80004af8:	072a1223          	sh	s2,100(s4)
  ip->nlink = 1;
    80004afc:	4905                	li	s2,1
    80004afe:	072a1323          	sh	s2,102(s4)
  iupdate(ip);
    80004b02:	8552                	mv	a0,s4
    80004b04:	d30fe0ef          	jal	80003034 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004b08:	032b0763          	beq	s6,s2,80004b36 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b0c:	004a2603          	lw	a2,4(s4)
    80004b10:	fb040593          	addi	a1,s0,-80
    80004b14:	8526                	mv	a0,s1
    80004b16:	eb7fe0ef          	jal	800039cc <dirlink>
    80004b1a:	06054563          	bltz	a0,80004b84 <create+0x11c>
  iunlockput(dp);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	93bfe0ef          	jal	8000345a <iunlockput>
  return ip;
    80004b24:	8ad2                	mv	s5,s4
    80004b26:	7a02                	ld	s4,32(sp)
    80004b28:	bf71                	j	80004ac4 <create+0x5c>
    iunlockput(dp);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	92ffe0ef          	jal	8000345a <iunlockput>
    return 0;
    80004b30:	8ad2                	mv	s5,s4
    80004b32:	7a02                	ld	s4,32(sp)
    80004b34:	bf41                	j	80004ac4 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004b36:	004a2603          	lw	a2,4(s4)
    80004b3a:	00006597          	auipc	a1,0x6
    80004b3e:	b0e58593          	addi	a1,a1,-1266 # 8000a648 <etext+0x648>
    80004b42:	8552                	mv	a0,s4
    80004b44:	e89fe0ef          	jal	800039cc <dirlink>
    80004b48:	02054e63          	bltz	a0,80004b84 <create+0x11c>
    80004b4c:	40d0                	lw	a2,4(s1)
    80004b4e:	00006597          	auipc	a1,0x6
    80004b52:	b0258593          	addi	a1,a1,-1278 # 8000a650 <etext+0x650>
    80004b56:	8552                	mv	a0,s4
    80004b58:	e75fe0ef          	jal	800039cc <dirlink>
    80004b5c:	02054463          	bltz	a0,80004b84 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b60:	004a2603          	lw	a2,4(s4)
    80004b64:	fb040593          	addi	a1,s0,-80
    80004b68:	8526                	mv	a0,s1
    80004b6a:	e63fe0ef          	jal	800039cc <dirlink>
    80004b6e:	00054b63          	bltz	a0,80004b84 <create+0x11c>
    dp->nlink++;  // for ".."
    80004b72:	0664d783          	lhu	a5,102(s1)
    80004b76:	2785                	addiw	a5,a5,1
    80004b78:	06f49323          	sh	a5,102(s1)
    iupdate(dp);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	cb6fe0ef          	jal	80003034 <iupdate>
    80004b82:	bf71                	j	80004b1e <create+0xb6>
  ip->nlink = 0;
    80004b84:	060a1323          	sh	zero,102(s4)
  iupdate(ip);
    80004b88:	8552                	mv	a0,s4
    80004b8a:	caafe0ef          	jal	80003034 <iupdate>
  iunlockput(ip);
    80004b8e:	8552                	mv	a0,s4
    80004b90:	8cbfe0ef          	jal	8000345a <iunlockput>
  iunlockput(dp);
    80004b94:	8526                	mv	a0,s1
    80004b96:	8c5fe0ef          	jal	8000345a <iunlockput>
  return 0;
    80004b9a:	7a02                	ld	s4,32(sp)
    80004b9c:	b725                	j	80004ac4 <create+0x5c>
    return 0;
    80004b9e:	8aaa                	mv	s5,a0
    80004ba0:	b715                	j	80004ac4 <create+0x5c>

0000000080004ba2 <sys_dup>:
{
    80004ba2:	7179                	addi	sp,sp,-48
    80004ba4:	f406                	sd	ra,40(sp)
    80004ba6:	f022                	sd	s0,32(sp)
    80004ba8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004baa:	fd840613          	addi	a2,s0,-40
    80004bae:	4581                	li	a1,0
    80004bb0:	4501                	li	a0,0
    80004bb2:	e21ff0ef          	jal	800049d2 <argfd>
    return -1;
    80004bb6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004bb8:	02054363          	bltz	a0,80004bde <sys_dup+0x3c>
    80004bbc:	ec26                	sd	s1,24(sp)
    80004bbe:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004bc0:	fd843903          	ld	s2,-40(s0)
    80004bc4:	854a                	mv	a0,s2
    80004bc6:	e65ff0ef          	jal	80004a2a <fdalloc>
    80004bca:	84aa                	mv	s1,a0
    return -1;
    80004bcc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004bce:	00054d63          	bltz	a0,80004be8 <sys_dup+0x46>
  filedup(f);
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	c2cff0ef          	jal	80004000 <filedup>
  return fd;
    80004bd8:	87a6                	mv	a5,s1
    80004bda:	64e2                	ld	s1,24(sp)
    80004bdc:	6942                	ld	s2,16(sp)
}
    80004bde:	853e                	mv	a0,a5
    80004be0:	70a2                	ld	ra,40(sp)
    80004be2:	7402                	ld	s0,32(sp)
    80004be4:	6145                	addi	sp,sp,48
    80004be6:	8082                	ret
    80004be8:	64e2                	ld	s1,24(sp)
    80004bea:	6942                	ld	s2,16(sp)
    80004bec:	bfcd                	j	80004bde <sys_dup+0x3c>

0000000080004bee <sys_read>:
{
    80004bee:	7179                	addi	sp,sp,-48
    80004bf0:	f406                	sd	ra,40(sp)
    80004bf2:	f022                	sd	s0,32(sp)
    80004bf4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004bf6:	fd840593          	addi	a1,s0,-40
    80004bfa:	4505                	li	a0,1
    80004bfc:	c6bfd0ef          	jal	80002866 <argaddr>
  argint(2, &n);
    80004c00:	fe440593          	addi	a1,s0,-28
    80004c04:	4509                	li	a0,2
    80004c06:	c45fd0ef          	jal	8000284a <argint>
  if(argfd(0, 0, &f) < 0)
    80004c0a:	fe840613          	addi	a2,s0,-24
    80004c0e:	4581                	li	a1,0
    80004c10:	4501                	li	a0,0
    80004c12:	dc1ff0ef          	jal	800049d2 <argfd>
    80004c16:	87aa                	mv	a5,a0
    return -1;
    80004c18:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c1a:	0007ca63          	bltz	a5,80004c2e <sys_read+0x40>
  return fileread(f, p, n);
    80004c1e:	fe442603          	lw	a2,-28(s0)
    80004c22:	fd843583          	ld	a1,-40(s0)
    80004c26:	fe843503          	ld	a0,-24(s0)
    80004c2a:	d3cff0ef          	jal	80004166 <fileread>
}
    80004c2e:	70a2                	ld	ra,40(sp)
    80004c30:	7402                	ld	s0,32(sp)
    80004c32:	6145                	addi	sp,sp,48
    80004c34:	8082                	ret

0000000080004c36 <sys_write>:
{
    80004c36:	7179                	addi	sp,sp,-48
    80004c38:	f406                	sd	ra,40(sp)
    80004c3a:	f022                	sd	s0,32(sp)
    80004c3c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c3e:	fd840593          	addi	a1,s0,-40
    80004c42:	4505                	li	a0,1
    80004c44:	c23fd0ef          	jal	80002866 <argaddr>
  argint(2, &n);
    80004c48:	fe440593          	addi	a1,s0,-28
    80004c4c:	4509                	li	a0,2
    80004c4e:	bfdfd0ef          	jal	8000284a <argint>
  if(argfd(0, 0, &f) < 0)
    80004c52:	fe840613          	addi	a2,s0,-24
    80004c56:	4581                	li	a1,0
    80004c58:	4501                	li	a0,0
    80004c5a:	d79ff0ef          	jal	800049d2 <argfd>
    80004c5e:	87aa                	mv	a5,a0
    return -1;
    80004c60:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c62:	0007ca63          	bltz	a5,80004c76 <sys_write+0x40>
  return filewrite(f, p, n);
    80004c66:	fe442603          	lw	a2,-28(s0)
    80004c6a:	fd843583          	ld	a1,-40(s0)
    80004c6e:	fe843503          	ld	a0,-24(s0)
    80004c72:	dc6ff0ef          	jal	80004238 <filewrite>
}
    80004c76:	70a2                	ld	ra,40(sp)
    80004c78:	7402                	ld	s0,32(sp)
    80004c7a:	6145                	addi	sp,sp,48
    80004c7c:	8082                	ret

0000000080004c7e <sys_close>:
{
    80004c7e:	1101                	addi	sp,sp,-32
    80004c80:	ec06                	sd	ra,24(sp)
    80004c82:	e822                	sd	s0,16(sp)
    80004c84:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004c86:	fe040613          	addi	a2,s0,-32
    80004c8a:	fec40593          	addi	a1,s0,-20
    80004c8e:	4501                	li	a0,0
    80004c90:	d43ff0ef          	jal	800049d2 <argfd>
    return -1;
    80004c94:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004c96:	02054063          	bltz	a0,80004cb6 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004c9a:	c5dfc0ef          	jal	800018f6 <myproc>
    80004c9e:	fec42783          	lw	a5,-20(s0)
    80004ca2:	07e9                	addi	a5,a5,26
    80004ca4:	078e                	slli	a5,a5,0x3
    80004ca6:	953e                	add	a0,a0,a5
    80004ca8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004cac:	fe043503          	ld	a0,-32(s0)
    80004cb0:	b96ff0ef          	jal	80004046 <fileclose>
  return 0;
    80004cb4:	4781                	li	a5,0
}
    80004cb6:	853e                	mv	a0,a5
    80004cb8:	60e2                	ld	ra,24(sp)
    80004cba:	6442                	ld	s0,16(sp)
    80004cbc:	6105                	addi	sp,sp,32
    80004cbe:	8082                	ret

0000000080004cc0 <sys_fstat>:
{
    80004cc0:	1101                	addi	sp,sp,-32
    80004cc2:	ec06                	sd	ra,24(sp)
    80004cc4:	e822                	sd	s0,16(sp)
    80004cc6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004cc8:	fe040593          	addi	a1,s0,-32
    80004ccc:	4505                	li	a0,1
    80004cce:	b99fd0ef          	jal	80002866 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004cd2:	fe840613          	addi	a2,s0,-24
    80004cd6:	4581                	li	a1,0
    80004cd8:	4501                	li	a0,0
    80004cda:	cf9ff0ef          	jal	800049d2 <argfd>
    80004cde:	87aa                	mv	a5,a0
    return -1;
    80004ce0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004ce2:	0007c863          	bltz	a5,80004cf2 <sys_fstat+0x32>
  return filestat(f, st);
    80004ce6:	fe043583          	ld	a1,-32(s0)
    80004cea:	fe843503          	ld	a0,-24(s0)
    80004cee:	c1aff0ef          	jal	80004108 <filestat>
}
    80004cf2:	60e2                	ld	ra,24(sp)
    80004cf4:	6442                	ld	s0,16(sp)
    80004cf6:	6105                	addi	sp,sp,32
    80004cf8:	8082                	ret

0000000080004cfa <sys_link>:
{
    80004cfa:	7169                	addi	sp,sp,-304
    80004cfc:	f606                	sd	ra,296(sp)
    80004cfe:	f222                	sd	s0,288(sp)
    80004d00:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d02:	08000613          	li	a2,128
    80004d06:	ed040593          	addi	a1,s0,-304
    80004d0a:	4501                	li	a0,0
    80004d0c:	b77fd0ef          	jal	80002882 <argstr>
    return -1;
    80004d10:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d12:	0c054e63          	bltz	a0,80004dee <sys_link+0xf4>
    80004d16:	08000613          	li	a2,128
    80004d1a:	f5040593          	addi	a1,s0,-176
    80004d1e:	4505                	li	a0,1
    80004d20:	b63fd0ef          	jal	80002882 <argstr>
    return -1;
    80004d24:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d26:	0c054463          	bltz	a0,80004dee <sys_link+0xf4>
    80004d2a:	ee26                	sd	s1,280(sp)
  begin_op();
    80004d2c:	f0ffe0ef          	jal	80003c3a <begin_op>
  if((ip = namei(old)) == 0){
    80004d30:	ed040513          	addi	a0,s0,-304
    80004d34:	d33fe0ef          	jal	80003a66 <namei>
    80004d38:	84aa                	mv	s1,a0
    80004d3a:	c53d                	beqz	a0,80004da8 <sys_link+0xae>
  ilock(ip);
    80004d3c:	d14fe0ef          	jal	80003250 <ilock>
  if(ip->type == T_DIR){
    80004d40:	06049703          	lh	a4,96(s1)
    80004d44:	4785                	li	a5,1
    80004d46:	06f70663          	beq	a4,a5,80004db2 <sys_link+0xb8>
    80004d4a:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004d4c:	0664d783          	lhu	a5,102(s1)
    80004d50:	2785                	addiw	a5,a5,1
    80004d52:	06f49323          	sh	a5,102(s1)
  iupdate(ip);
    80004d56:	8526                	mv	a0,s1
    80004d58:	adcfe0ef          	jal	80003034 <iupdate>
  iunlock(ip);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	da0fe0ef          	jal	800032fe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004d62:	fd040593          	addi	a1,s0,-48
    80004d66:	f5040513          	addi	a0,s0,-176
    80004d6a:	d17fe0ef          	jal	80003a80 <nameiparent>
    80004d6e:	892a                	mv	s2,a0
    80004d70:	cd21                	beqz	a0,80004dc8 <sys_link+0xce>
  ilock(dp);
    80004d72:	cdefe0ef          	jal	80003250 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004d76:	00092703          	lw	a4,0(s2)
    80004d7a:	409c                	lw	a5,0(s1)
    80004d7c:	04f71363          	bne	a4,a5,80004dc2 <sys_link+0xc8>
    80004d80:	40d0                	lw	a2,4(s1)
    80004d82:	fd040593          	addi	a1,s0,-48
    80004d86:	854a                	mv	a0,s2
    80004d88:	c45fe0ef          	jal	800039cc <dirlink>
    80004d8c:	02054b63          	bltz	a0,80004dc2 <sys_link+0xc8>
  iunlockput(dp);
    80004d90:	854a                	mv	a0,s2
    80004d92:	ec8fe0ef          	jal	8000345a <iunlockput>
  iput(ip);
    80004d96:	8526                	mv	a0,s1
    80004d98:	e3afe0ef          	jal	800033d2 <iput>
  end_op();
    80004d9c:	f09fe0ef          	jal	80003ca4 <end_op>
  return 0;
    80004da0:	4781                	li	a5,0
    80004da2:	64f2                	ld	s1,280(sp)
    80004da4:	6952                	ld	s2,272(sp)
    80004da6:	a0a1                	j	80004dee <sys_link+0xf4>
    end_op();
    80004da8:	efdfe0ef          	jal	80003ca4 <end_op>
    return -1;
    80004dac:	57fd                	li	a5,-1
    80004dae:	64f2                	ld	s1,280(sp)
    80004db0:	a83d                	j	80004dee <sys_link+0xf4>
    iunlockput(ip);
    80004db2:	8526                	mv	a0,s1
    80004db4:	ea6fe0ef          	jal	8000345a <iunlockput>
    end_op();
    80004db8:	eedfe0ef          	jal	80003ca4 <end_op>
    return -1;
    80004dbc:	57fd                	li	a5,-1
    80004dbe:	64f2                	ld	s1,280(sp)
    80004dc0:	a03d                	j	80004dee <sys_link+0xf4>
    iunlockput(dp);
    80004dc2:	854a                	mv	a0,s2
    80004dc4:	e96fe0ef          	jal	8000345a <iunlockput>
  ilock(ip);
    80004dc8:	8526                	mv	a0,s1
    80004dca:	c86fe0ef          	jal	80003250 <ilock>
  ip->nlink--;
    80004dce:	0664d783          	lhu	a5,102(s1)
    80004dd2:	37fd                	addiw	a5,a5,-1
    80004dd4:	06f49323          	sh	a5,102(s1)
  iupdate(ip);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	a5afe0ef          	jal	80003034 <iupdate>
  iunlockput(ip);
    80004dde:	8526                	mv	a0,s1
    80004de0:	e7afe0ef          	jal	8000345a <iunlockput>
  end_op();
    80004de4:	ec1fe0ef          	jal	80003ca4 <end_op>
  return -1;
    80004de8:	57fd                	li	a5,-1
    80004dea:	64f2                	ld	s1,280(sp)
    80004dec:	6952                	ld	s2,272(sp)
}
    80004dee:	853e                	mv	a0,a5
    80004df0:	70b2                	ld	ra,296(sp)
    80004df2:	7412                	ld	s0,288(sp)
    80004df4:	6155                	addi	sp,sp,304
    80004df6:	8082                	ret

0000000080004df8 <sys_unlink>:
{
    80004df8:	7151                	addi	sp,sp,-240
    80004dfa:	f586                	sd	ra,232(sp)
    80004dfc:	f1a2                	sd	s0,224(sp)
    80004dfe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004e00:	08000613          	li	a2,128
    80004e04:	f3040593          	addi	a1,s0,-208
    80004e08:	4501                	li	a0,0
    80004e0a:	a79fd0ef          	jal	80002882 <argstr>
    80004e0e:	16054063          	bltz	a0,80004f6e <sys_unlink+0x176>
    80004e12:	eda6                	sd	s1,216(sp)
  begin_op();
    80004e14:	e27fe0ef          	jal	80003c3a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004e18:	fb040593          	addi	a1,s0,-80
    80004e1c:	f3040513          	addi	a0,s0,-208
    80004e20:	c61fe0ef          	jal	80003a80 <nameiparent>
    80004e24:	84aa                	mv	s1,a0
    80004e26:	c945                	beqz	a0,80004ed6 <sys_unlink+0xde>
  ilock(dp);
    80004e28:	c28fe0ef          	jal	80003250 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004e2c:	00006597          	auipc	a1,0x6
    80004e30:	81c58593          	addi	a1,a1,-2020 # 8000a648 <etext+0x648>
    80004e34:	fb040513          	addi	a0,s0,-80
    80004e38:	9b3fe0ef          	jal	800037ea <namecmp>
    80004e3c:	10050e63          	beqz	a0,80004f58 <sys_unlink+0x160>
    80004e40:	00006597          	auipc	a1,0x6
    80004e44:	81058593          	addi	a1,a1,-2032 # 8000a650 <etext+0x650>
    80004e48:	fb040513          	addi	a0,s0,-80
    80004e4c:	99ffe0ef          	jal	800037ea <namecmp>
    80004e50:	10050463          	beqz	a0,80004f58 <sys_unlink+0x160>
    80004e54:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004e56:	f2c40613          	addi	a2,s0,-212
    80004e5a:	fb040593          	addi	a1,s0,-80
    80004e5e:	8526                	mv	a0,s1
    80004e60:	9a1fe0ef          	jal	80003800 <dirlookup>
    80004e64:	892a                	mv	s2,a0
    80004e66:	0e050863          	beqz	a0,80004f56 <sys_unlink+0x15e>
  ilock(ip);
    80004e6a:	be6fe0ef          	jal	80003250 <ilock>
  if(ip->nlink < 1)
    80004e6e:	06691783          	lh	a5,102(s2)
    80004e72:	06f05763          	blez	a5,80004ee0 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004e76:	06091703          	lh	a4,96(s2)
    80004e7a:	4785                	li	a5,1
    80004e7c:	06f70963          	beq	a4,a5,80004eee <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004e80:	4641                	li	a2,16
    80004e82:	4581                	li	a1,0
    80004e84:	fc040513          	addi	a0,s0,-64
    80004e88:	e1bfb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e8c:	4741                	li	a4,16
    80004e8e:	f2c42683          	lw	a3,-212(s0)
    80004e92:	fc040613          	addi	a2,s0,-64
    80004e96:	4581                	li	a1,0
    80004e98:	8526                	mv	a0,s1
    80004e9a:	843fe0ef          	jal	800036dc <writei>
    80004e9e:	47c1                	li	a5,16
    80004ea0:	08f51b63          	bne	a0,a5,80004f36 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004ea4:	06091703          	lh	a4,96(s2)
    80004ea8:	4785                	li	a5,1
    80004eaa:	08f70d63          	beq	a4,a5,80004f44 <sys_unlink+0x14c>
  iunlockput(dp);
    80004eae:	8526                	mv	a0,s1
    80004eb0:	daafe0ef          	jal	8000345a <iunlockput>
  ip->nlink--;
    80004eb4:	06695783          	lhu	a5,102(s2)
    80004eb8:	37fd                	addiw	a5,a5,-1
    80004eba:	06f91323          	sh	a5,102(s2)
  iupdate(ip);
    80004ebe:	854a                	mv	a0,s2
    80004ec0:	974fe0ef          	jal	80003034 <iupdate>
  iunlockput(ip);
    80004ec4:	854a                	mv	a0,s2
    80004ec6:	d94fe0ef          	jal	8000345a <iunlockput>
  end_op();
    80004eca:	ddbfe0ef          	jal	80003ca4 <end_op>
  return 0;
    80004ece:	4501                	li	a0,0
    80004ed0:	64ee                	ld	s1,216(sp)
    80004ed2:	694e                	ld	s2,208(sp)
    80004ed4:	a849                	j	80004f66 <sys_unlink+0x16e>
    end_op();
    80004ed6:	dcffe0ef          	jal	80003ca4 <end_op>
    return -1;
    80004eda:	557d                	li	a0,-1
    80004edc:	64ee                	ld	s1,216(sp)
    80004ede:	a061                	j	80004f66 <sys_unlink+0x16e>
    80004ee0:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004ee2:	00005517          	auipc	a0,0x5
    80004ee6:	77650513          	addi	a0,a0,1910 # 8000a658 <etext+0x658>
    80004eea:	8f7fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004eee:	06892703          	lw	a4,104(s2)
    80004ef2:	02000793          	li	a5,32
    80004ef6:	f8e7f5e3          	bgeu	a5,a4,80004e80 <sys_unlink+0x88>
    80004efa:	e5ce                	sd	s3,200(sp)
    80004efc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f00:	4741                	li	a4,16
    80004f02:	86ce                	mv	a3,s3
    80004f04:	f1840613          	addi	a2,s0,-232
    80004f08:	4581                	li	a1,0
    80004f0a:	854a                	mv	a0,s2
    80004f0c:	ed4fe0ef          	jal	800035e0 <readi>
    80004f10:	47c1                	li	a5,16
    80004f12:	00f51c63          	bne	a0,a5,80004f2a <sys_unlink+0x132>
    if(de.inum != 0)
    80004f16:	f1845783          	lhu	a5,-232(s0)
    80004f1a:	efa1                	bnez	a5,80004f72 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f1c:	29c1                	addiw	s3,s3,16
    80004f1e:	06892783          	lw	a5,104(s2)
    80004f22:	fcf9efe3          	bltu	s3,a5,80004f00 <sys_unlink+0x108>
    80004f26:	69ae                	ld	s3,200(sp)
    80004f28:	bfa1                	j	80004e80 <sys_unlink+0x88>
      panic("isdirempty: readi");
    80004f2a:	00005517          	auipc	a0,0x5
    80004f2e:	74650513          	addi	a0,a0,1862 # 8000a670 <etext+0x670>
    80004f32:	8affb0ef          	jal	800007e0 <panic>
    80004f36:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80004f38:	00005517          	auipc	a0,0x5
    80004f3c:	75050513          	addi	a0,a0,1872 # 8000a688 <etext+0x688>
    80004f40:	8a1fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80004f44:	0664d783          	lhu	a5,102(s1)
    80004f48:	37fd                	addiw	a5,a5,-1
    80004f4a:	06f49323          	sh	a5,102(s1)
    iupdate(dp);
    80004f4e:	8526                	mv	a0,s1
    80004f50:	8e4fe0ef          	jal	80003034 <iupdate>
    80004f54:	bfa9                	j	80004eae <sys_unlink+0xb6>
    80004f56:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	d00fe0ef          	jal	8000345a <iunlockput>
  end_op();
    80004f5e:	d47fe0ef          	jal	80003ca4 <end_op>
  return -1;
    80004f62:	557d                	li	a0,-1
    80004f64:	64ee                	ld	s1,216(sp)
}
    80004f66:	70ae                	ld	ra,232(sp)
    80004f68:	740e                	ld	s0,224(sp)
    80004f6a:	616d                	addi	sp,sp,240
    80004f6c:	8082                	ret
    return -1;
    80004f6e:	557d                	li	a0,-1
    80004f70:	bfdd                	j	80004f66 <sys_unlink+0x16e>
    iunlockput(ip);
    80004f72:	854a                	mv	a0,s2
    80004f74:	ce6fe0ef          	jal	8000345a <iunlockput>
    goto bad;
    80004f78:	694e                	ld	s2,208(sp)
    80004f7a:	69ae                	ld	s3,200(sp)
    80004f7c:	bff1                	j	80004f58 <sys_unlink+0x160>

0000000080004f7e <sys_open>:

uint64
sys_open(void)
{
    80004f7e:	7131                	addi	sp,sp,-192
    80004f80:	fd06                	sd	ra,184(sp)
    80004f82:	f922                	sd	s0,176(sp)
    80004f84:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004f86:	f5c40593          	addi	a1,s0,-164
    80004f8a:	4505                	li	a0,1
    80004f8c:	8bffd0ef          	jal	8000284a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004f90:	08000613          	li	a2,128
    80004f94:	f6040593          	addi	a1,s0,-160
    80004f98:	4501                	li	a0,0
    80004f9a:	8e9fd0ef          	jal	80002882 <argstr>
    80004f9e:	87aa                	mv	a5,a0
    return -1;
    80004fa0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004fa2:	0e07c163          	bltz	a5,80005084 <sys_open+0x106>
    80004fa6:	f526                	sd	s1,168(sp)

  begin_op();
    80004fa8:	c93fe0ef          	jal	80003c3a <begin_op>

  if(omode & O_CREATE){
    80004fac:	f5c42783          	lw	a5,-164(s0)
    80004fb0:	2007f793          	andi	a5,a5,512
    80004fb4:	0e078a63          	beqz	a5,800050a8 <sys_open+0x12a>
    ip = create(path, T_FILE, 0, 0);
    80004fb8:	4681                	li	a3,0
    80004fba:	4601                	li	a2,0
    80004fbc:	4589                	li	a1,2
    80004fbe:	f6040513          	addi	a0,s0,-160
    80004fc2:	aa7ff0ef          	jal	80004a68 <create>
    80004fc6:	f4a43823          	sd	a0,-176(s0)
    if(ip == 0){
    80004fca:	c169                	beqz	a0,8000508c <sys_open+0x10e>
      end_op();
      return -1;
    }
    char name[DIRSIZ];
    struct inode *dp = vfs_nameiparent(path, name); // Usar versión VFS
    80004fcc:	f4040593          	addi	a1,s0,-192
    80004fd0:	f6040513          	addi	a0,s0,-160
    80004fd4:	022010ef          	jal	80005ff6 <vfs_nameiparent>
    80004fd8:	84aa                	mv	s1,a0
    if(dp == 0){
    80004fda:	cd45                	beqz	a0,80005092 <sys_open+0x114>
      end_op();
      return -1;
    }
    ilock(dp);
    80004fdc:	a74fe0ef          	jal	80003250 <ilock>
    if(vfs_create(dp, name, T_FILE, &ip) < 0){ // Usar versión VFS
    80004fe0:	f5040693          	addi	a3,s0,-176
    80004fe4:	4609                	li	a2,2
    80004fe6:	f4040593          	addi	a1,s0,-192
    80004fea:	8526                	mv	a0,s1
    80004fec:	0e8010ef          	jal	800060d4 <vfs_create>
    80004ff0:	0a054463          	bltz	a0,80005098 <sys_open+0x11a>
      iunlockput(dp);
      end_op();
      return -1;
    }
    iunlockput(dp);
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	c64fe0ef          	jal	8000345a <iunlockput>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004ffa:	f5043503          	ld	a0,-176(s0)
    80004ffe:	06051703          	lh	a4,96(a0)
    80005002:	478d                	li	a5,3
    80005004:	00f71763          	bne	a4,a5,80005012 <sys_open+0x94>
    80005008:	06255703          	lhu	a4,98(a0)
    8000500c:	47a5                	li	a5,9
    8000500e:	0ce7ec63          	bltu	a5,a4,800050e6 <sys_open+0x168>
    80005012:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005014:	f8ffe0ef          	jal	80003fa2 <filealloc>
    80005018:	892a                	mv	s2,a0
    8000501a:	0e050063          	beqz	a0,800050fa <sys_open+0x17c>
    8000501e:	a0dff0ef          	jal	80004a2a <fdalloc>
    80005022:	84aa                	mv	s1,a0
    80005024:	0c054863          	bltz	a0,800050f4 <sys_open+0x176>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005028:	f5043783          	ld	a5,-176(s0)
    8000502c:	06079703          	lh	a4,96(a5)
    80005030:	478d                	li	a5,3
    80005032:	0cf70e63          	beq	a4,a5,8000510e <sys_open+0x190>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005036:	4789                	li	a5,2
    80005038:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000503c:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005040:	f5043503          	ld	a0,-176(s0)
    80005044:	00a93c23          	sd	a0,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005048:	f5c42783          	lw	a5,-164(s0)
    8000504c:	0017c713          	xori	a4,a5,1
    80005050:	8b05                	andi	a4,a4,1
    80005052:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005056:	0037f713          	andi	a4,a5,3
    8000505a:	00e03733          	snez	a4,a4
    8000505e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005062:	4007f793          	andi	a5,a5,1024
    80005066:	c791                	beqz	a5,80005072 <sys_open+0xf4>
    80005068:	06051703          	lh	a4,96(a0)
    8000506c:	4789                	li	a5,2
    8000506e:	0af70963          	beq	a4,a5,80005120 <sys_open+0x1a2>
    itrunc(ip);
  }

  iunlock(ip);
    80005072:	f5043503          	ld	a0,-176(s0)
    80005076:	a88fe0ef          	jal	800032fe <iunlock>
  end_op();
    8000507a:	c2bfe0ef          	jal	80003ca4 <end_op>

  return fd;
    8000507e:	8526                	mv	a0,s1
    80005080:	74aa                	ld	s1,168(sp)
    80005082:	790a                	ld	s2,160(sp)
}
    80005084:	70ea                	ld	ra,184(sp)
    80005086:	744a                	ld	s0,176(sp)
    80005088:	6129                	addi	sp,sp,192
    8000508a:	8082                	ret
      end_op();
    8000508c:	c19fe0ef          	jal	80003ca4 <end_op>
      return -1;
    80005090:	a809                	j	800050a2 <sys_open+0x124>
      end_op();
    80005092:	c13fe0ef          	jal	80003ca4 <end_op>
      return -1;
    80005096:	a031                	j	800050a2 <sys_open+0x124>
      iunlockput(dp);
    80005098:	8526                	mv	a0,s1
    8000509a:	bc0fe0ef          	jal	8000345a <iunlockput>
      end_op();
    8000509e:	c07fe0ef          	jal	80003ca4 <end_op>
      return -1;
    800050a2:	557d                	li	a0,-1
    800050a4:	74aa                	ld	s1,168(sp)
    800050a6:	bff9                	j	80005084 <sys_open+0x106>
    if((ip = vfs_namei(path)) == 0){ 
    800050a8:	f6040513          	addi	a0,s0,-160
    800050ac:	5cb000ef          	jal	80005e76 <vfs_namei>
    800050b0:	f4a43823          	sd	a0,-176(s0)
    800050b4:	c505                	beqz	a0,800050dc <sys_open+0x15e>
    ilock(ip);
    800050b6:	99afe0ef          	jal	80003250 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800050ba:	f5043503          	ld	a0,-176(s0)
    800050be:	06051703          	lh	a4,96(a0)
    800050c2:	4785                	li	a5,1
    800050c4:	f2f71be3          	bne	a4,a5,80004ffa <sys_open+0x7c>
    800050c8:	f5c42783          	lw	a5,-164(s0)
    800050cc:	d3b9                	beqz	a5,80005012 <sys_open+0x94>
      iunlockput(ip);
    800050ce:	b8cfe0ef          	jal	8000345a <iunlockput>
      end_op();
    800050d2:	bd3fe0ef          	jal	80003ca4 <end_op>
      return -1;
    800050d6:	557d                	li	a0,-1
    800050d8:	74aa                	ld	s1,168(sp)
    800050da:	b76d                	j	80005084 <sys_open+0x106>
      end_op();
    800050dc:	bc9fe0ef          	jal	80003ca4 <end_op>
      return -1;
    800050e0:	557d                	li	a0,-1
    800050e2:	74aa                	ld	s1,168(sp)
    800050e4:	b745                	j	80005084 <sys_open+0x106>
    iunlockput(ip);
    800050e6:	b74fe0ef          	jal	8000345a <iunlockput>
    end_op();
    800050ea:	bbbfe0ef          	jal	80003ca4 <end_op>
    return -1;
    800050ee:	557d                	li	a0,-1
    800050f0:	74aa                	ld	s1,168(sp)
    800050f2:	bf49                	j	80005084 <sys_open+0x106>
      fileclose(f);
    800050f4:	854a                	mv	a0,s2
    800050f6:	f51fe0ef          	jal	80004046 <fileclose>
    iunlockput(ip);
    800050fa:	f5043503          	ld	a0,-176(s0)
    800050fe:	b5cfe0ef          	jal	8000345a <iunlockput>
    end_op();
    80005102:	ba3fe0ef          	jal	80003ca4 <end_op>
    return -1;
    80005106:	557d                	li	a0,-1
    80005108:	74aa                	ld	s1,168(sp)
    8000510a:	790a                	ld	s2,160(sp)
    8000510c:	bfa5                	j	80005084 <sys_open+0x106>
    f->type = FD_DEVICE;
    8000510e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005112:	f5043783          	ld	a5,-176(s0)
    80005116:	06279783          	lh	a5,98(a5)
    8000511a:	02f91223          	sh	a5,36(s2)
    8000511e:	b70d                	j	80005040 <sys_open+0xc2>
    itrunc(ip);
    80005120:	a1efe0ef          	jal	8000333e <itrunc>
    80005124:	b7b9                	j	80005072 <sys_open+0xf4>

0000000080005126 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005126:	7175                	addi	sp,sp,-144
    80005128:	e506                	sd	ra,136(sp)
    8000512a:	e122                	sd	s0,128(sp)
    8000512c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000512e:	b0dfe0ef          	jal	80003c3a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005132:	08000613          	li	a2,128
    80005136:	f7040593          	addi	a1,s0,-144
    8000513a:	4501                	li	a0,0
    8000513c:	f46fd0ef          	jal	80002882 <argstr>
    80005140:	02054363          	bltz	a0,80005166 <sys_mkdir+0x40>
    80005144:	4681                	li	a3,0
    80005146:	4601                	li	a2,0
    80005148:	4585                	li	a1,1
    8000514a:	f7040513          	addi	a0,s0,-144
    8000514e:	91bff0ef          	jal	80004a68 <create>
    80005152:	c911                	beqz	a0,80005166 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005154:	b06fe0ef          	jal	8000345a <iunlockput>
  end_op();
    80005158:	b4dfe0ef          	jal	80003ca4 <end_op>
  return 0;
    8000515c:	4501                	li	a0,0
}
    8000515e:	60aa                	ld	ra,136(sp)
    80005160:	640a                	ld	s0,128(sp)
    80005162:	6149                	addi	sp,sp,144
    80005164:	8082                	ret
    end_op();
    80005166:	b3ffe0ef          	jal	80003ca4 <end_op>
    return -1;
    8000516a:	557d                	li	a0,-1
    8000516c:	bfcd                	j	8000515e <sys_mkdir+0x38>

000000008000516e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000516e:	7135                	addi	sp,sp,-160
    80005170:	ed06                	sd	ra,152(sp)
    80005172:	e922                	sd	s0,144(sp)
    80005174:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005176:	ac5fe0ef          	jal	80003c3a <begin_op>
  argint(1, &major);
    8000517a:	f6c40593          	addi	a1,s0,-148
    8000517e:	4505                	li	a0,1
    80005180:	ecafd0ef          	jal	8000284a <argint>
  argint(2, &minor);
    80005184:	f6840593          	addi	a1,s0,-152
    80005188:	4509                	li	a0,2
    8000518a:	ec0fd0ef          	jal	8000284a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000518e:	08000613          	li	a2,128
    80005192:	f7040593          	addi	a1,s0,-144
    80005196:	4501                	li	a0,0
    80005198:	eeafd0ef          	jal	80002882 <argstr>
    8000519c:	02054563          	bltz	a0,800051c6 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800051a0:	f6841683          	lh	a3,-152(s0)
    800051a4:	f6c41603          	lh	a2,-148(s0)
    800051a8:	458d                	li	a1,3
    800051aa:	f7040513          	addi	a0,s0,-144
    800051ae:	8bbff0ef          	jal	80004a68 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051b2:	c911                	beqz	a0,800051c6 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051b4:	aa6fe0ef          	jal	8000345a <iunlockput>
  end_op();
    800051b8:	aedfe0ef          	jal	80003ca4 <end_op>
  return 0;
    800051bc:	4501                	li	a0,0
}
    800051be:	60ea                	ld	ra,152(sp)
    800051c0:	644a                	ld	s0,144(sp)
    800051c2:	610d                	addi	sp,sp,160
    800051c4:	8082                	ret
    end_op();
    800051c6:	adffe0ef          	jal	80003ca4 <end_op>
    return -1;
    800051ca:	557d                	li	a0,-1
    800051cc:	bfcd                	j	800051be <sys_mknod+0x50>

00000000800051ce <sys_chdir>:

uint64
sys_chdir(void)
{
    800051ce:	7135                	addi	sp,sp,-160
    800051d0:	ed06                	sd	ra,152(sp)
    800051d2:	e922                	sd	s0,144(sp)
    800051d4:	e14a                	sd	s2,128(sp)
    800051d6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800051d8:	f1efc0ef          	jal	800018f6 <myproc>
    800051dc:	892a                	mv	s2,a0
  
  begin_op();
    800051de:	a5dfe0ef          	jal	80003c3a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = vfs_namei(path)) == 0){
    800051e2:	08000613          	li	a2,128
    800051e6:	f6040593          	addi	a1,s0,-160
    800051ea:	4501                	li	a0,0
    800051ec:	e96fd0ef          	jal	80002882 <argstr>
    800051f0:	04054363          	bltz	a0,80005236 <sys_chdir+0x68>
    800051f4:	e526                	sd	s1,136(sp)
    800051f6:	f6040513          	addi	a0,s0,-160
    800051fa:	47d000ef          	jal	80005e76 <vfs_namei>
    800051fe:	84aa                	mv	s1,a0
    80005200:	c915                	beqz	a0,80005234 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005202:	84efe0ef          	jal	80003250 <ilock>
  if(ip->type != T_DIR){
    80005206:	06049703          	lh	a4,96(s1)
    8000520a:	4785                	li	a5,1
    8000520c:	02f71963          	bne	a4,a5,8000523e <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005210:	8526                	mv	a0,s1
    80005212:	8ecfe0ef          	jal	800032fe <iunlock>
  iput(p->cwd);
    80005216:	15093503          	ld	a0,336(s2)
    8000521a:	9b8fe0ef          	jal	800033d2 <iput>
  end_op();
    8000521e:	a87fe0ef          	jal	80003ca4 <end_op>
  p->cwd = ip;
    80005222:	14993823          	sd	s1,336(s2)
  return 0;
    80005226:	4501                	li	a0,0
    80005228:	64aa                	ld	s1,136(sp)
}
    8000522a:	60ea                	ld	ra,152(sp)
    8000522c:	644a                	ld	s0,144(sp)
    8000522e:	690a                	ld	s2,128(sp)
    80005230:	610d                	addi	sp,sp,160
    80005232:	8082                	ret
    80005234:	64aa                	ld	s1,136(sp)
    end_op();
    80005236:	a6ffe0ef          	jal	80003ca4 <end_op>
    return -1;
    8000523a:	557d                	li	a0,-1
    8000523c:	b7fd                	j	8000522a <sys_chdir+0x5c>
    iunlockput(ip);
    8000523e:	8526                	mv	a0,s1
    80005240:	a1afe0ef          	jal	8000345a <iunlockput>
    end_op();
    80005244:	a61fe0ef          	jal	80003ca4 <end_op>
    return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	64aa                	ld	s1,136(sp)
    8000524c:	bff9                	j	8000522a <sys_chdir+0x5c>

000000008000524e <sys_exec>:

uint64
sys_exec(void)
{
    8000524e:	7121                	addi	sp,sp,-448
    80005250:	ff06                	sd	ra,440(sp)
    80005252:	fb22                	sd	s0,432(sp)
    80005254:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005256:	e4840593          	addi	a1,s0,-440
    8000525a:	4505                	li	a0,1
    8000525c:	e0afd0ef          	jal	80002866 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005260:	08000613          	li	a2,128
    80005264:	f5040593          	addi	a1,s0,-176
    80005268:	4501                	li	a0,0
    8000526a:	e18fd0ef          	jal	80002882 <argstr>
    8000526e:	87aa                	mv	a5,a0
    return -1;
    80005270:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005272:	0c07c463          	bltz	a5,8000533a <sys_exec+0xec>
    80005276:	f726                	sd	s1,424(sp)
    80005278:	f34a                	sd	s2,416(sp)
    8000527a:	ef4e                	sd	s3,408(sp)
    8000527c:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    8000527e:	10000613          	li	a2,256
    80005282:	4581                	li	a1,0
    80005284:	e5040513          	addi	a0,s0,-432
    80005288:	a1bfb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000528c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005290:	89a6                	mv	s3,s1
    80005292:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005294:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005298:	00391513          	slli	a0,s2,0x3
    8000529c:	e4040593          	addi	a1,s0,-448
    800052a0:	e4843783          	ld	a5,-440(s0)
    800052a4:	953e                	add	a0,a0,a5
    800052a6:	d1afd0ef          	jal	800027c0 <fetchaddr>
    800052aa:	02054663          	bltz	a0,800052d6 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    800052ae:	e4043783          	ld	a5,-448(s0)
    800052b2:	c3a9                	beqz	a5,800052f4 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800052b4:	84bfb0ef          	jal	80000afe <kalloc>
    800052b8:	85aa                	mv	a1,a0
    800052ba:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800052be:	cd01                	beqz	a0,800052d6 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800052c0:	6605                	lui	a2,0x1
    800052c2:	e4043503          	ld	a0,-448(s0)
    800052c6:	d44fd0ef          	jal	8000280a <fetchstr>
    800052ca:	00054663          	bltz	a0,800052d6 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    800052ce:	0905                	addi	s2,s2,1
    800052d0:	09a1                	addi	s3,s3,8
    800052d2:	fd4913e3          	bne	s2,s4,80005298 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052d6:	f5040913          	addi	s2,s0,-176
    800052da:	6088                	ld	a0,0(s1)
    800052dc:	c931                	beqz	a0,80005330 <sys_exec+0xe2>
    kfree(argv[i]);
    800052de:	f3efb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052e2:	04a1                	addi	s1,s1,8
    800052e4:	ff249be3          	bne	s1,s2,800052da <sys_exec+0x8c>
  return -1;
    800052e8:	557d                	li	a0,-1
    800052ea:	74ba                	ld	s1,424(sp)
    800052ec:	791a                	ld	s2,416(sp)
    800052ee:	69fa                	ld	s3,408(sp)
    800052f0:	6a5a                	ld	s4,400(sp)
    800052f2:	a0a1                	j	8000533a <sys_exec+0xec>
      argv[i] = 0;
    800052f4:	0009079b          	sext.w	a5,s2
    800052f8:	078e                	slli	a5,a5,0x3
    800052fa:	fd078793          	addi	a5,a5,-48
    800052fe:	97a2                	add	a5,a5,s0
    80005300:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    80005304:	e5040593          	addi	a1,s0,-432
    80005308:	f5040513          	addi	a0,s0,-176
    8000530c:	b54ff0ef          	jal	80004660 <kexec>
    80005310:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005312:	f5040993          	addi	s3,s0,-176
    80005316:	6088                	ld	a0,0(s1)
    80005318:	c511                	beqz	a0,80005324 <sys_exec+0xd6>
    kfree(argv[i]);
    8000531a:	f02fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000531e:	04a1                	addi	s1,s1,8
    80005320:	ff349be3          	bne	s1,s3,80005316 <sys_exec+0xc8>
  return ret;
    80005324:	854a                	mv	a0,s2
    80005326:	74ba                	ld	s1,424(sp)
    80005328:	791a                	ld	s2,416(sp)
    8000532a:	69fa                	ld	s3,408(sp)
    8000532c:	6a5a                	ld	s4,400(sp)
    8000532e:	a031                	j	8000533a <sys_exec+0xec>
  return -1;
    80005330:	557d                	li	a0,-1
    80005332:	74ba                	ld	s1,424(sp)
    80005334:	791a                	ld	s2,416(sp)
    80005336:	69fa                	ld	s3,408(sp)
    80005338:	6a5a                	ld	s4,400(sp)
}
    8000533a:	70fa                	ld	ra,440(sp)
    8000533c:	745a                	ld	s0,432(sp)
    8000533e:	6139                	addi	sp,sp,448
    80005340:	8082                	ret

0000000080005342 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005342:	7139                	addi	sp,sp,-64
    80005344:	fc06                	sd	ra,56(sp)
    80005346:	f822                	sd	s0,48(sp)
    80005348:	f426                	sd	s1,40(sp)
    8000534a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000534c:	daafc0ef          	jal	800018f6 <myproc>
    80005350:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005352:	fd840593          	addi	a1,s0,-40
    80005356:	4501                	li	a0,0
    80005358:	d0efd0ef          	jal	80002866 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000535c:	fc840593          	addi	a1,s0,-56
    80005360:	fd040513          	addi	a0,s0,-48
    80005364:	ffffe0ef          	jal	80004362 <pipealloc>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000536a:	0a054463          	bltz	a0,80005412 <sys_pipe+0xd0>
  fd0 = -1;
    8000536e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005372:	fd043503          	ld	a0,-48(s0)
    80005376:	eb4ff0ef          	jal	80004a2a <fdalloc>
    8000537a:	fca42223          	sw	a0,-60(s0)
    8000537e:	08054163          	bltz	a0,80005400 <sys_pipe+0xbe>
    80005382:	fc843503          	ld	a0,-56(s0)
    80005386:	ea4ff0ef          	jal	80004a2a <fdalloc>
    8000538a:	fca42023          	sw	a0,-64(s0)
    8000538e:	06054063          	bltz	a0,800053ee <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005392:	4691                	li	a3,4
    80005394:	fc440613          	addi	a2,s0,-60
    80005398:	fd843583          	ld	a1,-40(s0)
    8000539c:	68a8                	ld	a0,80(s1)
    8000539e:	a6cfc0ef          	jal	8000160a <copyout>
    800053a2:	00054e63          	bltz	a0,800053be <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053a6:	4691                	li	a3,4
    800053a8:	fc040613          	addi	a2,s0,-64
    800053ac:	fd843583          	ld	a1,-40(s0)
    800053b0:	0591                	addi	a1,a1,4
    800053b2:	68a8                	ld	a0,80(s1)
    800053b4:	a56fc0ef          	jal	8000160a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800053b8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053ba:	04055c63          	bgez	a0,80005412 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800053be:	fc442783          	lw	a5,-60(s0)
    800053c2:	07e9                	addi	a5,a5,26
    800053c4:	078e                	slli	a5,a5,0x3
    800053c6:	97a6                	add	a5,a5,s1
    800053c8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800053cc:	fc042783          	lw	a5,-64(s0)
    800053d0:	07e9                	addi	a5,a5,26
    800053d2:	078e                	slli	a5,a5,0x3
    800053d4:	94be                	add	s1,s1,a5
    800053d6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800053da:	fd043503          	ld	a0,-48(s0)
    800053de:	c69fe0ef          	jal	80004046 <fileclose>
    fileclose(wf);
    800053e2:	fc843503          	ld	a0,-56(s0)
    800053e6:	c61fe0ef          	jal	80004046 <fileclose>
    return -1;
    800053ea:	57fd                	li	a5,-1
    800053ec:	a01d                	j	80005412 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800053ee:	fc442783          	lw	a5,-60(s0)
    800053f2:	0007c763          	bltz	a5,80005400 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800053f6:	07e9                	addi	a5,a5,26
    800053f8:	078e                	slli	a5,a5,0x3
    800053fa:	97a6                	add	a5,a5,s1
    800053fc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005400:	fd043503          	ld	a0,-48(s0)
    80005404:	c43fe0ef          	jal	80004046 <fileclose>
    fileclose(wf);
    80005408:	fc843503          	ld	a0,-56(s0)
    8000540c:	c3bfe0ef          	jal	80004046 <fileclose>
    return -1;
    80005410:	57fd                	li	a5,-1
}
    80005412:	853e                	mv	a0,a5
    80005414:	70e2                	ld	ra,56(sp)
    80005416:	7442                	ld	s0,48(sp)
    80005418:	74a2                	ld	s1,40(sp)
    8000541a:	6121                	addi	sp,sp,64
    8000541c:	8082                	ret

000000008000541e <sys_mount>:

uint64
sys_mount(void)
{
    8000541e:	712d                	addi	sp,sp,-288
    80005420:	ee06                	sd	ra,280(sp)
    80005422:	ea22                	sd	s0,272(sp)
    80005424:	1200                	addi	s0,sp,288
  char source[MAXPATH];
  char target[MAXPATH];
  char fstype[16];

  if(argstr(0, source, MAXPATH) < 0 ||
    80005426:	08000613          	li	a2,128
    8000542a:	f7040593          	addi	a1,s0,-144
    8000542e:	4501                	li	a0,0
    80005430:	c52fd0ef          	jal	80002882 <argstr>
     argstr(1, target, MAXPATH) < 0 ||
     argstr(2, fstype, 16) < 0)
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argstr(0, source, MAXPATH) < 0 ||
    80005436:	02054f63          	bltz	a0,80005474 <sys_mount+0x56>
     argstr(1, target, MAXPATH) < 0 ||
    8000543a:	08000613          	li	a2,128
    8000543e:	ef040593          	addi	a1,s0,-272
    80005442:	4505                	li	a0,1
    80005444:	c3efd0ef          	jal	80002882 <argstr>
    return -1;
    80005448:	57fd                	li	a5,-1
  if(argstr(0, source, MAXPATH) < 0 ||
    8000544a:	02054563          	bltz	a0,80005474 <sys_mount+0x56>
     argstr(2, fstype, 16) < 0)
    8000544e:	4641                	li	a2,16
    80005450:	ee040593          	addi	a1,s0,-288
    80005454:	4509                	li	a0,2
    80005456:	c2cfd0ef          	jal	80002882 <argstr>
    return -1;
    8000545a:	57fd                	li	a5,-1
     argstr(1, target, MAXPATH) < 0 ||
    8000545c:	00054c63          	bltz	a0,80005474 <sys_mount+0x56>

  return vfs_mount(source, target, fstype, 0);
    80005460:	4681                	li	a3,0
    80005462:	ee040613          	addi	a2,s0,-288
    80005466:	ef040593          	addi	a1,s0,-272
    8000546a:	f7040513          	addi	a0,s0,-144
    8000546e:	78c000ef          	jal	80005bfa <vfs_mount>
    80005472:	87aa                	mv	a5,a0
}
    80005474:	853e                	mv	a0,a5
    80005476:	60f2                	ld	ra,280(sp)
    80005478:	6452                	ld	s0,272(sp)
    8000547a:	6115                	addi	sp,sp,288
    8000547c:	8082                	ret

000000008000547e <sys_umount>:

uint64
sys_umount(void)
{
    8000547e:	7175                	addi	sp,sp,-144
    80005480:	e506                	sd	ra,136(sp)
    80005482:	e122                	sd	s0,128(sp)
    80005484:	0900                	addi	s0,sp,144
  char target[MAXPATH];

  if(argstr(0, target, MAXPATH) < 0)
    80005486:	08000613          	li	a2,128
    8000548a:	f7040593          	addi	a1,s0,-144
    8000548e:	4501                	li	a0,0
    80005490:	bf2fd0ef          	jal	80002882 <argstr>
    80005494:	87aa                	mv	a5,a0
    return -1;
    80005496:	557d                	li	a0,-1
  if(argstr(0, target, MAXPATH) < 0)
    80005498:	0007c663          	bltz	a5,800054a4 <sys_umount+0x26>

  return vfs_umount(target);
    8000549c:	f7040513          	addi	a0,s0,-144
    800054a0:	125000ef          	jal	80005dc4 <vfs_umount>
}
    800054a4:	60aa                	ld	ra,136(sp)
    800054a6:	640a                	ld	s0,128(sp)
    800054a8:	6149                	addi	sp,sp,144
    800054aa:	8082                	ret
    800054ac:	0000                	unimp
	...

00000000800054b0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800054b0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800054b2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800054b4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800054b6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800054b8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800054ba:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800054bc:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800054be:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800054c0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800054c2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800054c4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800054c6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800054c8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800054ca:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800054cc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800054ce:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800054d0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800054d2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800054d4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800054d6:	9fafd0ef          	jal	800026d0 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800054da:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800054dc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800054de:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800054e0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800054e2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800054e4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800054e6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800054e8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800054ea:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800054ec:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800054ee:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800054f0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800054f2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800054f4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800054f6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800054f8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800054fa:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800054fc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800054fe:	10200073          	sret
	...

000000008000550e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000550e:	1141                	addi	sp,sp,-16
    80005510:	e422                	sd	s0,8(sp)
    80005512:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005514:	0c0007b7          	lui	a5,0xc000
    80005518:	4705                	li	a4,1
    8000551a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000551c:	0c0007b7          	lui	a5,0xc000
    80005520:	c3d8                	sw	a4,4(a5)
  *(uint32*)(PLIC + 2*4) = 1;  // VIRTIO1_IRQ for network
    80005522:	0c0007b7          	lui	a5,0xc000
    80005526:	c798                	sw	a4,8(a5)
}
    80005528:	6422                	ld	s0,8(sp)
    8000552a:	0141                	addi	sp,sp,16
    8000552c:	8082                	ret

000000008000552e <plicinithart>:

void
plicinithart(void)
{
    8000552e:	1141                	addi	sp,sp,-16
    80005530:	e406                	sd	ra,8(sp)
    80005532:	e022                	sd	s0,0(sp)
    80005534:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005536:	b94fc0ef          	jal	800018ca <cpuid>

  // set enable bits for this hart's S-mode
  // for the uart, virtio disk, and virtio network.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ) | (1 << 2);
    8000553a:	0085171b          	slliw	a4,a0,0x8
    8000553e:	0c0027b7          	lui	a5,0xc002
    80005542:	97ba                	add	a5,a5,a4
    80005544:	40600713          	li	a4,1030
    80005548:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    8000554c:	00d5151b          	slliw	a0,a0,0xd
    80005550:	0c2017b7          	lui	a5,0xc201
    80005554:	97aa                	add	a5,a5,a0
    80005556:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    8000555a:	60a2                	ld	ra,8(sp)
    8000555c:	6402                	ld	s0,0(sp)
    8000555e:	0141                	addi	sp,sp,16
    80005560:	8082                	ret

0000000080005562 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005562:	1141                	addi	sp,sp,-16
    80005564:	e406                	sd	ra,8(sp)
    80005566:	e022                	sd	s0,0(sp)
    80005568:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000556a:	b60fc0ef          	jal	800018ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    8000556e:	00d5151b          	slliw	a0,a0,0xd
    80005572:	0c2017b7          	lui	a5,0xc201
    80005576:	97aa                	add	a5,a5,a0
  return irq;
}
    80005578:	43c8                	lw	a0,4(a5)
    8000557a:	60a2                	ld	ra,8(sp)
    8000557c:	6402                	ld	s0,0(sp)
    8000557e:	0141                	addi	sp,sp,16
    80005580:	8082                	ret

0000000080005582 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005582:	1101                	addi	sp,sp,-32
    80005584:	ec06                	sd	ra,24(sp)
    80005586:	e822                	sd	s0,16(sp)
    80005588:	e426                	sd	s1,8(sp)
    8000558a:	1000                	addi	s0,sp,32
    8000558c:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000558e:	b3cfc0ef          	jal	800018ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005592:	00d5151b          	slliw	a0,a0,0xd
    80005596:	0c2017b7          	lui	a5,0xc201
    8000559a:	97aa                	add	a5,a5,a0
    8000559c:	c3c4                	sw	s1,4(a5)
}
    8000559e:	60e2                	ld	ra,24(sp)
    800055a0:	6442                	ld	s0,16(sp)
    800055a2:	64a2                	ld	s1,8(sp)
    800055a4:	6105                	addi	sp,sp,32
    800055a6:	8082                	ret

00000000800055a8 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800055a8:	1141                	addi	sp,sp,-16
    800055aa:	e406                	sd	ra,8(sp)
    800055ac:	e022                	sd	s0,0(sp)
    800055ae:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800055b0:	479d                	li	a5,7
    800055b2:	04a7ca63          	blt	a5,a0,80005606 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800055b6:	00023797          	auipc	a5,0x23
    800055ba:	e4278793          	addi	a5,a5,-446 # 800283f8 <disk>
    800055be:	97aa                	add	a5,a5,a0
    800055c0:	0187c783          	lbu	a5,24(a5)
    800055c4:	e7b9                	bnez	a5,80005612 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800055c6:	00451693          	slli	a3,a0,0x4
    800055ca:	00023797          	auipc	a5,0x23
    800055ce:	e2e78793          	addi	a5,a5,-466 # 800283f8 <disk>
    800055d2:	6398                	ld	a4,0(a5)
    800055d4:	9736                	add	a4,a4,a3
    800055d6:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800055da:	6398                	ld	a4,0(a5)
    800055dc:	9736                	add	a4,a4,a3
    800055de:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800055e2:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800055e6:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800055ea:	97aa                	add	a5,a5,a0
    800055ec:	4705                	li	a4,1
    800055ee:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800055f2:	00023517          	auipc	a0,0x23
    800055f6:	e1e50513          	addi	a0,a0,-482 # 80028410 <disk+0x18>
    800055fa:	98dfc0ef          	jal	80001f86 <wakeup>
}
    800055fe:	60a2                	ld	ra,8(sp)
    80005600:	6402                	ld	s0,0(sp)
    80005602:	0141                	addi	sp,sp,16
    80005604:	8082                	ret
    panic("free_desc 1");
    80005606:	00005517          	auipc	a0,0x5
    8000560a:	09250513          	addi	a0,a0,146 # 8000a698 <etext+0x698>
    8000560e:	9d2fb0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    80005612:	00005517          	auipc	a0,0x5
    80005616:	09650513          	addi	a0,a0,150 # 8000a6a8 <etext+0x6a8>
    8000561a:	9c6fb0ef          	jal	800007e0 <panic>

000000008000561e <virtio_disk_init>:
{
    8000561e:	1101                	addi	sp,sp,-32
    80005620:	ec06                	sd	ra,24(sp)
    80005622:	e822                	sd	s0,16(sp)
    80005624:	e426                	sd	s1,8(sp)
    80005626:	e04a                	sd	s2,0(sp)
    80005628:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000562a:	00005597          	auipc	a1,0x5
    8000562e:	08e58593          	addi	a1,a1,142 # 8000a6b8 <etext+0x6b8>
    80005632:	00023517          	auipc	a0,0x23
    80005636:	eee50513          	addi	a0,a0,-274 # 80028520 <disk+0x128>
    8000563a:	d14fb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000563e:	100017b7          	lui	a5,0x10001
    80005642:	4398                	lw	a4,0(a5)
    80005644:	2701                	sext.w	a4,a4
    80005646:	747277b7          	lui	a5,0x74727
    8000564a:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000564e:	18f71063          	bne	a4,a5,800057ce <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005652:	100017b7          	lui	a5,0x10001
    80005656:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005658:	439c                	lw	a5,0(a5)
    8000565a:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000565c:	4709                	li	a4,2
    8000565e:	16e79863          	bne	a5,a4,800057ce <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005662:	100017b7          	lui	a5,0x10001
    80005666:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005668:	439c                	lw	a5,0(a5)
    8000566a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000566c:	16e79163          	bne	a5,a4,800057ce <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005670:	100017b7          	lui	a5,0x10001
    80005674:	47d8                	lw	a4,12(a5)
    80005676:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005678:	554d47b7          	lui	a5,0x554d4
    8000567c:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005680:	14f71763          	bne	a4,a5,800057ce <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005684:	100017b7          	lui	a5,0x10001
    80005688:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000568c:	4705                	li	a4,1
    8000568e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005690:	470d                	li	a4,3
    80005692:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005694:	10001737          	lui	a4,0x10001
    80005698:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000569a:	c7ffe737          	lui	a4,0xc7ffe
    8000569e:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf747>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800056a2:	8ef9                	and	a3,a3,a4
    800056a4:	10001737          	lui	a4,0x10001
    800056a8:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800056aa:	472d                	li	a4,11
    800056ac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800056ae:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800056b2:	439c                	lw	a5,0(a5)
    800056b4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800056b8:	8ba1                	andi	a5,a5,8
    800056ba:	12078063          	beqz	a5,800057da <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800056be:	100017b7          	lui	a5,0x10001
    800056c2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800056c6:	100017b7          	lui	a5,0x10001
    800056ca:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800056ce:	439c                	lw	a5,0(a5)
    800056d0:	2781                	sext.w	a5,a5
    800056d2:	10079a63          	bnez	a5,800057e6 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800056d6:	100017b7          	lui	a5,0x10001
    800056da:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800056de:	439c                	lw	a5,0(a5)
    800056e0:	2781                	sext.w	a5,a5
  if(max == 0)
    800056e2:	10078863          	beqz	a5,800057f2 <virtio_disk_init+0x1d4>
  if(max < NUM)
    800056e6:	471d                	li	a4,7
    800056e8:	10f77b63          	bgeu	a4,a5,800057fe <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800056ec:	c12fb0ef          	jal	80000afe <kalloc>
    800056f0:	00023497          	auipc	s1,0x23
    800056f4:	d0848493          	addi	s1,s1,-760 # 800283f8 <disk>
    800056f8:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800056fa:	c04fb0ef          	jal	80000afe <kalloc>
    800056fe:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005700:	bfefb0ef          	jal	80000afe <kalloc>
    80005704:	87aa                	mv	a5,a0
    80005706:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005708:	6088                	ld	a0,0(s1)
    8000570a:	10050063          	beqz	a0,8000580a <virtio_disk_init+0x1ec>
    8000570e:	00023717          	auipc	a4,0x23
    80005712:	cf273703          	ld	a4,-782(a4) # 80028400 <disk+0x8>
    80005716:	0e070a63          	beqz	a4,8000580a <virtio_disk_init+0x1ec>
    8000571a:	0e078863          	beqz	a5,8000580a <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    8000571e:	6605                	lui	a2,0x1
    80005720:	4581                	li	a1,0
    80005722:	d80fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005726:	00023497          	auipc	s1,0x23
    8000572a:	cd248493          	addi	s1,s1,-814 # 800283f8 <disk>
    8000572e:	6605                	lui	a2,0x1
    80005730:	4581                	li	a1,0
    80005732:	6488                	ld	a0,8(s1)
    80005734:	d6efb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005738:	6605                	lui	a2,0x1
    8000573a:	4581                	li	a1,0
    8000573c:	6888                	ld	a0,16(s1)
    8000573e:	d64fb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005742:	100017b7          	lui	a5,0x10001
    80005746:	4721                	li	a4,8
    80005748:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000574a:	4098                	lw	a4,0(s1)
    8000574c:	100017b7          	lui	a5,0x10001
    80005750:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005754:	40d8                	lw	a4,4(s1)
    80005756:	100017b7          	lui	a5,0x10001
    8000575a:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000575e:	649c                	ld	a5,8(s1)
    80005760:	0007869b          	sext.w	a3,a5
    80005764:	10001737          	lui	a4,0x10001
    80005768:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    8000576c:	9781                	srai	a5,a5,0x20
    8000576e:	10001737          	lui	a4,0x10001
    80005772:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005776:	689c                	ld	a5,16(s1)
    80005778:	0007869b          	sext.w	a3,a5
    8000577c:	10001737          	lui	a4,0x10001
    80005780:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005784:	9781                	srai	a5,a5,0x20
    80005786:	10001737          	lui	a4,0x10001
    8000578a:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000578e:	10001737          	lui	a4,0x10001
    80005792:	4785                	li	a5,1
    80005794:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005796:	00f48c23          	sb	a5,24(s1)
    8000579a:	00f48ca3          	sb	a5,25(s1)
    8000579e:	00f48d23          	sb	a5,26(s1)
    800057a2:	00f48da3          	sb	a5,27(s1)
    800057a6:	00f48e23          	sb	a5,28(s1)
    800057aa:	00f48ea3          	sb	a5,29(s1)
    800057ae:	00f48f23          	sb	a5,30(s1)
    800057b2:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800057b6:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800057ba:	100017b7          	lui	a5,0x10001
    800057be:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800057c2:	60e2                	ld	ra,24(sp)
    800057c4:	6442                	ld	s0,16(sp)
    800057c6:	64a2                	ld	s1,8(sp)
    800057c8:	6902                	ld	s2,0(sp)
    800057ca:	6105                	addi	sp,sp,32
    800057cc:	8082                	ret
    panic("could not find virtio disk");
    800057ce:	00005517          	auipc	a0,0x5
    800057d2:	efa50513          	addi	a0,a0,-262 # 8000a6c8 <etext+0x6c8>
    800057d6:	80afb0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    800057da:	00005517          	auipc	a0,0x5
    800057de:	f0e50513          	addi	a0,a0,-242 # 8000a6e8 <etext+0x6e8>
    800057e2:	ffffa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    800057e6:	00005517          	auipc	a0,0x5
    800057ea:	f2250513          	addi	a0,a0,-222 # 8000a708 <etext+0x708>
    800057ee:	ff3fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    800057f2:	00005517          	auipc	a0,0x5
    800057f6:	f3650513          	addi	a0,a0,-202 # 8000a728 <etext+0x728>
    800057fa:	fe7fa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    800057fe:	00005517          	auipc	a0,0x5
    80005802:	f4a50513          	addi	a0,a0,-182 # 8000a748 <etext+0x748>
    80005806:	fdbfa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    8000580a:	00005517          	auipc	a0,0x5
    8000580e:	f5e50513          	addi	a0,a0,-162 # 8000a768 <etext+0x768>
    80005812:	fcffa0ef          	jal	800007e0 <panic>

0000000080005816 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005816:	7159                	addi	sp,sp,-112
    80005818:	f486                	sd	ra,104(sp)
    8000581a:	f0a2                	sd	s0,96(sp)
    8000581c:	eca6                	sd	s1,88(sp)
    8000581e:	e8ca                	sd	s2,80(sp)
    80005820:	e4ce                	sd	s3,72(sp)
    80005822:	e0d2                	sd	s4,64(sp)
    80005824:	fc56                	sd	s5,56(sp)
    80005826:	f85a                	sd	s6,48(sp)
    80005828:	f45e                	sd	s7,40(sp)
    8000582a:	f062                	sd	s8,32(sp)
    8000582c:	ec66                	sd	s9,24(sp)
    8000582e:	1880                	addi	s0,sp,112
    80005830:	8a2a                	mv	s4,a0
    80005832:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005834:	00c52c83          	lw	s9,12(a0)
    80005838:	001c9c9b          	slliw	s9,s9,0x1
    8000583c:	1c82                	slli	s9,s9,0x20
    8000583e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005842:	00023517          	auipc	a0,0x23
    80005846:	cde50513          	addi	a0,a0,-802 # 80028520 <disk+0x128>
    8000584a:	b84fb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    8000584e:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005850:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005852:	00023b17          	auipc	s6,0x23
    80005856:	ba6b0b13          	addi	s6,s6,-1114 # 800283f8 <disk>
  for(int i = 0; i < 3; i++){
    8000585a:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000585c:	00023c17          	auipc	s8,0x23
    80005860:	cc4c0c13          	addi	s8,s8,-828 # 80028520 <disk+0x128>
    80005864:	a8b9                	j	800058c2 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005866:	00fb0733          	add	a4,s6,a5
    8000586a:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    8000586e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005870:	0207c563          	bltz	a5,8000589a <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005874:	2905                	addiw	s2,s2,1
    80005876:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005878:	05590963          	beq	s2,s5,800058ca <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    8000587c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000587e:	00023717          	auipc	a4,0x23
    80005882:	b7a70713          	addi	a4,a4,-1158 # 800283f8 <disk>
    80005886:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005888:	01874683          	lbu	a3,24(a4)
    8000588c:	fee9                	bnez	a3,80005866 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    8000588e:	2785                	addiw	a5,a5,1
    80005890:	0705                	addi	a4,a4,1
    80005892:	fe979be3          	bne	a5,s1,80005888 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005896:	57fd                	li	a5,-1
    80005898:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000589a:	01205d63          	blez	s2,800058b4 <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    8000589e:	f9042503          	lw	a0,-112(s0)
    800058a2:	d07ff0ef          	jal	800055a8 <free_desc>
      for(int j = 0; j < i; j++)
    800058a6:	4785                	li	a5,1
    800058a8:	0127d663          	bge	a5,s2,800058b4 <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    800058ac:	f9442503          	lw	a0,-108(s0)
    800058b0:	cf9ff0ef          	jal	800055a8 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800058b4:	85e2                	mv	a1,s8
    800058b6:	00023517          	auipc	a0,0x23
    800058ba:	b5a50513          	addi	a0,a0,-1190 # 80028410 <disk+0x18>
    800058be:	e7cfc0ef          	jal	80001f3a <sleep>
  for(int i = 0; i < 3; i++){
    800058c2:	f9040613          	addi	a2,s0,-112
    800058c6:	894e                	mv	s2,s3
    800058c8:	bf55                	j	8000587c <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800058ca:	f9042503          	lw	a0,-112(s0)
    800058ce:	00451693          	slli	a3,a0,0x4

  if(write)
    800058d2:	00023797          	auipc	a5,0x23
    800058d6:	b2678793          	addi	a5,a5,-1242 # 800283f8 <disk>
    800058da:	00a50713          	addi	a4,a0,10
    800058de:	0712                	slli	a4,a4,0x4
    800058e0:	973e                	add	a4,a4,a5
    800058e2:	01703633          	snez	a2,s7
    800058e6:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800058e8:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800058ec:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800058f0:	6398                	ld	a4,0(a5)
    800058f2:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800058f4:	0a868613          	addi	a2,a3,168
    800058f8:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800058fa:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800058fc:	6390                	ld	a2,0(a5)
    800058fe:	00d605b3          	add	a1,a2,a3
    80005902:	4741                	li	a4,16
    80005904:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005906:	4805                	li	a6,1
    80005908:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    8000590c:	f9442703          	lw	a4,-108(s0)
    80005910:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005914:	0712                	slli	a4,a4,0x4
    80005916:	963a                	add	a2,a2,a4
    80005918:	058a0593          	addi	a1,s4,88
    8000591c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000591e:	0007b883          	ld	a7,0(a5)
    80005922:	9746                	add	a4,a4,a7
    80005924:	40000613          	li	a2,1024
    80005928:	c710                	sw	a2,8(a4)
  if(write)
    8000592a:	001bb613          	seqz	a2,s7
    8000592e:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005932:	00166613          	ori	a2,a2,1
    80005936:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    8000593a:	f9842583          	lw	a1,-104(s0)
    8000593e:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005942:	00250613          	addi	a2,a0,2
    80005946:	0612                	slli	a2,a2,0x4
    80005948:	963e                	add	a2,a2,a5
    8000594a:	577d                	li	a4,-1
    8000594c:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005950:	0592                	slli	a1,a1,0x4
    80005952:	98ae                	add	a7,a7,a1
    80005954:	03068713          	addi	a4,a3,48
    80005958:	973e                	add	a4,a4,a5
    8000595a:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    8000595e:	6398                	ld	a4,0(a5)
    80005960:	972e                	add	a4,a4,a1
    80005962:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005966:	4689                	li	a3,2
    80005968:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    8000596c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005970:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005974:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005978:	6794                	ld	a3,8(a5)
    8000597a:	0026d703          	lhu	a4,2(a3)
    8000597e:	8b1d                	andi	a4,a4,7
    80005980:	0706                	slli	a4,a4,0x1
    80005982:	96ba                	add	a3,a3,a4
    80005984:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005988:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000598c:	6798                	ld	a4,8(a5)
    8000598e:	00275783          	lhu	a5,2(a4)
    80005992:	2785                	addiw	a5,a5,1
    80005994:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005998:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000599c:	100017b7          	lui	a5,0x10001
    800059a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800059a4:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800059a8:	00023917          	auipc	s2,0x23
    800059ac:	b7890913          	addi	s2,s2,-1160 # 80028520 <disk+0x128>
  while(b->disk == 1) {
    800059b0:	4485                	li	s1,1
    800059b2:	01079a63          	bne	a5,a6,800059c6 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    800059b6:	85ca                	mv	a1,s2
    800059b8:	8552                	mv	a0,s4
    800059ba:	d80fc0ef          	jal	80001f3a <sleep>
  while(b->disk == 1) {
    800059be:	004a2783          	lw	a5,4(s4)
    800059c2:	fe978ae3          	beq	a5,s1,800059b6 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    800059c6:	f9042903          	lw	s2,-112(s0)
    800059ca:	00290713          	addi	a4,s2,2
    800059ce:	0712                	slli	a4,a4,0x4
    800059d0:	00023797          	auipc	a5,0x23
    800059d4:	a2878793          	addi	a5,a5,-1496 # 800283f8 <disk>
    800059d8:	97ba                	add	a5,a5,a4
    800059da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800059de:	00023997          	auipc	s3,0x23
    800059e2:	a1a98993          	addi	s3,s3,-1510 # 800283f8 <disk>
    800059e6:	00491713          	slli	a4,s2,0x4
    800059ea:	0009b783          	ld	a5,0(s3)
    800059ee:	97ba                	add	a5,a5,a4
    800059f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800059f4:	854a                	mv	a0,s2
    800059f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800059fa:	bafff0ef          	jal	800055a8 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800059fe:	8885                	andi	s1,s1,1
    80005a00:	f0fd                	bnez	s1,800059e6 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005a02:	00023517          	auipc	a0,0x23
    80005a06:	b1e50513          	addi	a0,a0,-1250 # 80028520 <disk+0x128>
    80005a0a:	a5cfb0ef          	jal	80000c66 <release>
}
    80005a0e:	70a6                	ld	ra,104(sp)
    80005a10:	7406                	ld	s0,96(sp)
    80005a12:	64e6                	ld	s1,88(sp)
    80005a14:	6946                	ld	s2,80(sp)
    80005a16:	69a6                	ld	s3,72(sp)
    80005a18:	6a06                	ld	s4,64(sp)
    80005a1a:	7ae2                	ld	s5,56(sp)
    80005a1c:	7b42                	ld	s6,48(sp)
    80005a1e:	7ba2                	ld	s7,40(sp)
    80005a20:	7c02                	ld	s8,32(sp)
    80005a22:	6ce2                	ld	s9,24(sp)
    80005a24:	6165                	addi	sp,sp,112
    80005a26:	8082                	ret

0000000080005a28 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005a28:	1101                	addi	sp,sp,-32
    80005a2a:	ec06                	sd	ra,24(sp)
    80005a2c:	e822                	sd	s0,16(sp)
    80005a2e:	e426                	sd	s1,8(sp)
    80005a30:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005a32:	00023497          	auipc	s1,0x23
    80005a36:	9c648493          	addi	s1,s1,-1594 # 800283f8 <disk>
    80005a3a:	00023517          	auipc	a0,0x23
    80005a3e:	ae650513          	addi	a0,a0,-1306 # 80028520 <disk+0x128>
    80005a42:	98cfb0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005a46:	100017b7          	lui	a5,0x10001
    80005a4a:	53b8                	lw	a4,96(a5)
    80005a4c:	8b0d                	andi	a4,a4,3
    80005a4e:	100017b7          	lui	a5,0x10001
    80005a52:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005a54:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005a58:	689c                	ld	a5,16(s1)
    80005a5a:	0204d703          	lhu	a4,32(s1)
    80005a5e:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005a62:	04f70663          	beq	a4,a5,80005aae <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005a66:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005a6a:	6898                	ld	a4,16(s1)
    80005a6c:	0204d783          	lhu	a5,32(s1)
    80005a70:	8b9d                	andi	a5,a5,7
    80005a72:	078e                	slli	a5,a5,0x3
    80005a74:	97ba                	add	a5,a5,a4
    80005a76:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005a78:	00278713          	addi	a4,a5,2
    80005a7c:	0712                	slli	a4,a4,0x4
    80005a7e:	9726                	add	a4,a4,s1
    80005a80:	01074703          	lbu	a4,16(a4)
    80005a84:	e321                	bnez	a4,80005ac4 <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a86:	0789                	addi	a5,a5,2
    80005a88:	0792                	slli	a5,a5,0x4
    80005a8a:	97a6                	add	a5,a5,s1
    80005a8c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a8e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a92:	cf4fc0ef          	jal	80001f86 <wakeup>

    disk.used_idx += 1;
    80005a96:	0204d783          	lhu	a5,32(s1)
    80005a9a:	2785                	addiw	a5,a5,1
    80005a9c:	17c2                	slli	a5,a5,0x30
    80005a9e:	93c1                	srli	a5,a5,0x30
    80005aa0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005aa4:	6898                	ld	a4,16(s1)
    80005aa6:	00275703          	lhu	a4,2(a4)
    80005aaa:	faf71ee3          	bne	a4,a5,80005a66 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005aae:	00023517          	auipc	a0,0x23
    80005ab2:	a7250513          	addi	a0,a0,-1422 # 80028520 <disk+0x128>
    80005ab6:	9b0fb0ef          	jal	80000c66 <release>
}
    80005aba:	60e2                	ld	ra,24(sp)
    80005abc:	6442                	ld	s0,16(sp)
    80005abe:	64a2                	ld	s1,8(sp)
    80005ac0:	6105                	addi	sp,sp,32
    80005ac2:	8082                	ret
      panic("virtio_disk_intr status");
    80005ac4:	00005517          	auipc	a0,0x5
    80005ac8:	cbc50513          	addi	a0,a0,-836 # 8000a780 <etext+0x780>
    80005acc:	d15fa0ef          	jal	800007e0 <panic>

0000000080005ad0 <vfs_follow_mount>:
}

// Follow a path component, handling mount points
static struct inode*
vfs_follow_mount(struct inode *ip)
{
    80005ad0:	1101                	addi	sp,sp,-32
    80005ad2:	ec06                	sd	ra,24(sp)
    80005ad4:	e822                	sd	s0,16(sp)
    80005ad6:	e426                	sd	s1,8(sp)
    80005ad8:	e04a                	sd	s2,0(sp)
    80005ada:	1000                	addi	s0,sp,32
    80005adc:	892a                	mv	s2,a0
  while(ip && vfs_is_mountpoint(ip)) {
    80005ade:	84aa                	mv	s1,a0
    80005ae0:	cd19                	beqz	a0,80005afe <vfs_follow_mount+0x2e>
  return ip->i_mount != 0;
    80005ae2:	07893783          	ld	a5,120(s2)
  while(ip && vfs_is_mountpoint(ip)) {
    80005ae6:	cb99                	beqz	a5,80005afc <vfs_follow_mount+0x2c>
    struct vfsmount *mnt = ip->i_mount;
    struct inode *mounted = mnt->mnt_root;
    80005ae8:	6b84                	ld	s1,16(a5)
    idup(mounted);
    80005aea:	8526                	mv	a0,s1
    80005aec:	f2efd0ef          	jal	8000321a <idup>
    iput(ip);
    80005af0:	854a                	mv	a0,s2
    80005af2:	8e1fd0ef          	jal	800033d2 <iput>
  while(ip && vfs_is_mountpoint(ip)) {
    80005af6:	c481                	beqz	s1,80005afe <vfs_follow_mount+0x2e>
    80005af8:	8926                	mv	s2,s1
    80005afa:	b7e5                	j	80005ae2 <vfs_follow_mount+0x12>
    80005afc:	84ca                	mv	s1,s2
    ip = mounted;
  }
  return ip;
}
    80005afe:	8526                	mv	a0,s1
    80005b00:	60e2                	ld	ra,24(sp)
    80005b02:	6442                	ld	s0,16(sp)
    80005b04:	64a2                	ld	s1,8(sp)
    80005b06:	6902                	ld	s2,0(sp)
    80005b08:	6105                	addi	sp,sp,32
    80005b0a:	8082                	ret

0000000080005b0c <vfs_init>:
{
    80005b0c:	1141                	addi	sp,sp,-16
    80005b0e:	e406                	sd	ra,8(sp)
    80005b10:	e022                	sd	s0,0(sp)
    80005b12:	0800                	addi	s0,sp,16
  initlock(&vfs_lock, "vfs");
    80005b14:	00005597          	auipc	a1,0x5
    80005b18:	c8458593          	addi	a1,a1,-892 # 8000a798 <etext+0x798>
    80005b1c:	00023517          	auipc	a0,0x23
    80005b20:	a1c50513          	addi	a0,a0,-1508 # 80028538 <vfs_lock>
    80005b24:	82afb0ef          	jal	80000b4e <initlock>
}
    80005b28:	60a2                	ld	ra,8(sp)
    80005b2a:	6402                	ld	s0,0(sp)
    80005b2c:	0141                	addi	sp,sp,16
    80005b2e:	8082                	ret

0000000080005b30 <vfs_register_filesystem>:
  if(!fs || !fs->name[0] || !fs->mount)
    80005b30:	c529                	beqz	a0,80005b7a <vfs_register_filesystem+0x4a>
{
    80005b32:	1101                	addi	sp,sp,-32
    80005b34:	ec06                	sd	ra,24(sp)
    80005b36:	e822                	sd	s0,16(sp)
    80005b38:	e426                	sd	s1,8(sp)
    80005b3a:	1000                	addi	s0,sp,32
    80005b3c:	84aa                	mv	s1,a0
  if(!fs || !fs->name[0] || !fs->mount)
    80005b3e:	00054783          	lbu	a5,0(a0)
    80005b42:	cf95                	beqz	a5,80005b7e <vfs_register_filesystem+0x4e>
    80005b44:	6d1c                	ld	a5,24(a0)
    80005b46:	cf95                	beqz	a5,80005b82 <vfs_register_filesystem+0x52>
    80005b48:	e04a                	sd	s2,0(sp)
  acquire(&vfs_lock);
    80005b4a:	00023917          	auipc	s2,0x23
    80005b4e:	9ee90913          	addi	s2,s2,-1554 # 80028538 <vfs_lock>
    80005b52:	854a                	mv	a0,s2
    80005b54:	87afb0ef          	jal	80000bce <acquire>
  fs->next = filesystems;
    80005b58:	00009797          	auipc	a5,0x9
    80005b5c:	d0878793          	addi	a5,a5,-760 # 8000e860 <filesystems>
    80005b60:	6398                	ld	a4,0(a5)
    80005b62:	f498                	sd	a4,40(s1)
  filesystems = fs;
    80005b64:	e384                	sd	s1,0(a5)
  release(&vfs_lock);
    80005b66:	854a                	mv	a0,s2
    80005b68:	8fefb0ef          	jal	80000c66 <release>
  return 0;
    80005b6c:	4501                	li	a0,0
    80005b6e:	6902                	ld	s2,0(sp)
}
    80005b70:	60e2                	ld	ra,24(sp)
    80005b72:	6442                	ld	s0,16(sp)
    80005b74:	64a2                	ld	s1,8(sp)
    80005b76:	6105                	addi	sp,sp,32
    80005b78:	8082                	ret
    return -1;
    80005b7a:	557d                	li	a0,-1
}
    80005b7c:	8082                	ret
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	bfc5                	j	80005b70 <vfs_register_filesystem+0x40>
    80005b82:	557d                	li	a0,-1
    80005b84:	b7f5                	j	80005b70 <vfs_register_filesystem+0x40>

0000000080005b86 <vfs_find_mount>:
{
    80005b86:	1101                	addi	sp,sp,-32
    80005b88:	ec06                	sd	ra,24(sp)
    80005b8a:	e822                	sd	s0,16(sp)
    80005b8c:	e426                	sd	s1,8(sp)
    80005b8e:	e04a                	sd	s2,0(sp)
    80005b90:	1000                	addi	s0,sp,32
    80005b92:	892a                	mv	s2,a0
  acquire(&vfs_lock);
    80005b94:	00023517          	auipc	a0,0x23
    80005b98:	9a450513          	addi	a0,a0,-1628 # 80028538 <vfs_lock>
    80005b9c:	832fb0ef          	jal	80000bce <acquire>
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    80005ba0:	00009497          	auipc	s1,0x9
    80005ba4:	cb04b483          	ld	s1,-848(s1) # 8000e850 <vfs_mounts>
    80005ba8:	c899                	beqz	s1,80005bbe <vfs_find_mount+0x38>
    if(strncmp(mnt->mnt_dirname, path, MAXPATH) == 0) {
    80005baa:	08000613          	li	a2,128
    80005bae:	85ca                	mv	a1,s2
    80005bb0:	03048513          	addi	a0,s1,48
    80005bb4:	9bafb0ef          	jal	80000d6e <strncmp>
    80005bb8:	c10d                	beqz	a0,80005bda <vfs_find_mount+0x54>
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    80005bba:	78c4                	ld	s1,176(s1)
    80005bbc:	f4fd                	bnez	s1,80005baa <vfs_find_mount+0x24>
  release(&vfs_lock);
    80005bbe:	00023517          	auipc	a0,0x23
    80005bc2:	97a50513          	addi	a0,a0,-1670 # 80028538 <vfs_lock>
    80005bc6:	8a0fb0ef          	jal	80000c66 <release>
  return 0;
    80005bca:	4481                	li	s1,0
}
    80005bcc:	8526                	mv	a0,s1
    80005bce:	60e2                	ld	ra,24(sp)
    80005bd0:	6442                	ld	s0,16(sp)
    80005bd2:	64a2                	ld	s1,8(sp)
    80005bd4:	6902                	ld	s2,0(sp)
    80005bd6:	6105                	addi	sp,sp,32
    80005bd8:	8082                	ret
      release(&vfs_lock);
    80005bda:	00023517          	auipc	a0,0x23
    80005bde:	95e50513          	addi	a0,a0,-1698 # 80028538 <vfs_lock>
    80005be2:	884fb0ef          	jal	80000c66 <release>
      return mnt;
    80005be6:	b7dd                	j	80005bcc <vfs_find_mount+0x46>

0000000080005be8 <vfs_is_mountpoint>:
{
    80005be8:	1141                	addi	sp,sp,-16
    80005bea:	e422                	sd	s0,8(sp)
    80005bec:	0800                	addi	s0,sp,16
  return ip->i_mount != 0;
    80005bee:	7d28                	ld	a0,120(a0)
}
    80005bf0:	00a03533          	snez	a0,a0
    80005bf4:	6422                	ld	s0,8(sp)
    80005bf6:	0141                	addi	sp,sp,16
    80005bf8:	8082                	ret

0000000080005bfa <vfs_mount>:
{
    80005bfa:	7139                	addi	sp,sp,-64
    80005bfc:	fc06                	sd	ra,56(sp)
    80005bfe:	f822                	sd	s0,48(sp)
    80005c00:	f426                	sd	s1,40(sp)
    80005c02:	f04a                	sd	s2,32(sp)
    80005c04:	ec4e                	sd	s3,24(sp)
    80005c06:	e852                	sd	s4,16(sp)
    80005c08:	e456                	sd	s5,8(sp)
    80005c0a:	e05a                	sd	s6,0(sp)
    80005c0c:	0080                	addi	s0,sp,64
    80005c0e:	8b2a                	mv	s6,a0
    80005c10:	8aae                	mv	s5,a1
    80005c12:	89b2                	mv	s3,a2
    80005c14:	8a36                	mv	s4,a3
  acquire(&vfs_lock);
    80005c16:	00023517          	auipc	a0,0x23
    80005c1a:	92250513          	addi	a0,a0,-1758 # 80028538 <vfs_lock>
    80005c1e:	fb1fa0ef          	jal	80000bce <acquire>
  for(fs = filesystems; fs; fs = fs->next) {
    80005c22:	00009917          	auipc	s2,0x9
    80005c26:	c3e93903          	ld	s2,-962(s2) # 8000e860 <filesystems>
    80005c2a:	00090d63          	beqz	s2,80005c44 <vfs_mount+0x4a>
    if(strncmp(fs->name, name, 16) == 0) {
    80005c2e:	4641                	li	a2,16
    80005c30:	85ce                	mv	a1,s3
    80005c32:	854a                	mv	a0,s2
    80005c34:	93afb0ef          	jal	80000d6e <strncmp>
    80005c38:	84aa                	mv	s1,a0
    80005c3a:	c505                	beqz	a0,80005c62 <vfs_mount+0x68>
  for(fs = filesystems; fs; fs = fs->next) {
    80005c3c:	02893903          	ld	s2,40(s2)
    80005c40:	fe0917e3          	bnez	s2,80005c2e <vfs_mount+0x34>
  release(&vfs_lock);
    80005c44:	00023517          	auipc	a0,0x23
    80005c48:	8f450513          	addi	a0,a0,-1804 # 80028538 <vfs_lock>
    80005c4c:	81afb0ef          	jal	80000c66 <release>
    printf("vfs_mount: unknown filesystem type: %s\n", fstype);
    80005c50:	85ce                	mv	a1,s3
    80005c52:	00005517          	auipc	a0,0x5
    80005c56:	b4e50513          	addi	a0,a0,-1202 # 8000a7a0 <etext+0x7a0>
    80005c5a:	8a1fa0ef          	jal	800004fa <printf>
    return -1;
    80005c5e:	54fd                	li	s1,-1
    80005c60:	a855                	j	80005d14 <vfs_mount+0x11a>
      release(&vfs_lock);
    80005c62:	00023517          	auipc	a0,0x23
    80005c66:	8d650513          	addi	a0,a0,-1834 # 80028538 <vfs_lock>
    80005c6a:	ffdfa0ef          	jal	80000c66 <release>
  if(!vfs_root_mnt) {
    80005c6e:	00009997          	auipc	s3,0x9
    80005c72:	bea9b983          	ld	s3,-1046(s3) # 8000e858 <vfs_root_mnt>
    80005c76:	0a098a63          	beqz	s3,80005d2a <vfs_mount+0x130>
    mountpoint = namei((char*)target);
    80005c7a:	8556                	mv	a0,s5
    80005c7c:	debfd0ef          	jal	80003a66 <namei>
    80005c80:	89aa                	mv	s3,a0
    if(!mountpoint) {
    80005c82:	0e050263          	beqz	a0,80005d66 <vfs_mount+0x16c>
    if(vfs_is_mountpoint(mountpoint)) {
    80005c86:	7d3c                	ld	a5,120(a0)
    80005c88:	0e079863          	bnez	a5,80005d78 <vfs_mount+0x17e>
  sb = fs->mount(dev, data);
    80005c8c:	01893783          	ld	a5,24(s2)
    80005c90:	85d2                	mv	a1,s4
    80005c92:	4505                	li	a0,1
    80005c94:	9782                	jalr	a5
    80005c96:	8a2a                	mv	s4,a0
  if(!sb) {
    80005c98:	0e050b63          	beqz	a0,80005d8e <vfs_mount+0x194>
  mnt = (struct vfsmount*)kalloc();
    80005c9c:	e63fa0ef          	jal	80000afe <kalloc>
    80005ca0:	892a                	mv	s2,a0
  if(!mnt) {
    80005ca2:	10050163          	beqz	a0,80005da4 <vfs_mount+0x1aa>
  mnt->mnt_sb = sb;
    80005ca6:	01493023          	sd	s4,0(s2)
  mnt->mnt_mountpoint = mountpoint;
    80005caa:	01393423          	sd	s3,8(s2)
  mnt->mnt_root = sb->s_root;
    80005cae:	020a3783          	ld	a5,32(s4)
    80005cb2:	00f93823          	sd	a5,16(s2)
  mnt->mnt_parent = vfs_root_mnt;
    80005cb6:	00009a17          	auipc	s4,0x9
    80005cba:	ba2a0a13          	addi	s4,s4,-1118 # 8000e858 <vfs_root_mnt>
    80005cbe:	000a3783          	ld	a5,0(s4)
    80005cc2:	00f93c23          	sd	a5,24(s2)
  safestrcpy(mnt->mnt_devname, source, 16);
    80005cc6:	4641                	li	a2,16
    80005cc8:	85da                	mv	a1,s6
    80005cca:	02090513          	addi	a0,s2,32
    80005cce:	912fb0ef          	jal	80000de0 <safestrcpy>
  safestrcpy(mnt->mnt_dirname, target, MAXPATH);
    80005cd2:	08000613          	li	a2,128
    80005cd6:	85d6                	mv	a1,s5
    80005cd8:	03090513          	addi	a0,s2,48
    80005cdc:	904fb0ef          	jal	80000de0 <safestrcpy>
  acquire(&vfs_lock);
    80005ce0:	00023517          	auipc	a0,0x23
    80005ce4:	85850513          	addi	a0,a0,-1960 # 80028538 <vfs_lock>
    80005ce8:	ee7fa0ef          	jal	80000bce <acquire>
  mnt->next = vfs_mounts;
    80005cec:	00009797          	auipc	a5,0x9
    80005cf0:	b6478793          	addi	a5,a5,-1180 # 8000e850 <vfs_mounts>
    80005cf4:	6398                	ld	a4,0(a5)
    80005cf6:	0ae93823          	sd	a4,176(s2)
  vfs_mounts = mnt;
    80005cfa:	0127b023          	sd	s2,0(a5)
  if(!vfs_root_mnt) {
    80005cfe:	000a3783          	ld	a5,0(s4)
    80005d02:	cfc5                	beqz	a5,80005dba <vfs_mount+0x1c0>
    mountpoint->i_mount = mnt;
    80005d04:	0729bc23          	sd	s2,120(s3)
  release(&vfs_lock);
    80005d08:	00023517          	auipc	a0,0x23
    80005d0c:	83050513          	addi	a0,a0,-2000 # 80028538 <vfs_lock>
    80005d10:	f57fa0ef          	jal	80000c66 <release>
}
    80005d14:	8526                	mv	a0,s1
    80005d16:	70e2                	ld	ra,56(sp)
    80005d18:	7442                	ld	s0,48(sp)
    80005d1a:	74a2                	ld	s1,40(sp)
    80005d1c:	7902                	ld	s2,32(sp)
    80005d1e:	69e2                	ld	s3,24(sp)
    80005d20:	6a42                	ld	s4,16(sp)
    80005d22:	6aa2                	ld	s5,8(sp)
    80005d24:	6b02                	ld	s6,0(sp)
    80005d26:	6121                	addi	sp,sp,64
    80005d28:	8082                	ret
    if(strncmp(target, "/", MAXPATH) != 0) {
    80005d2a:	08000613          	li	a2,128
    80005d2e:	00004597          	auipc	a1,0x4
    80005d32:	4b258593          	addi	a1,a1,1202 # 8000a1e0 <etext+0x1e0>
    80005d36:	8556                	mv	a0,s5
    80005d38:	836fb0ef          	jal	80000d6e <strncmp>
    80005d3c:	ed09                	bnez	a0,80005d56 <vfs_mount+0x15c>
  sb = fs->mount(dev, data);
    80005d3e:	01893783          	ld	a5,24(s2)
    80005d42:	85d2                	mv	a1,s4
    80005d44:	4505                	li	a0,1
    80005d46:	9782                	jalr	a5
    80005d48:	8a2a                	mv	s4,a0
  if(!sb) {
    80005d4a:	c529                	beqz	a0,80005d94 <vfs_mount+0x19a>
  mnt = (struct vfsmount*)kalloc();
    80005d4c:	db3fa0ef          	jal	80000afe <kalloc>
    80005d50:	892a                	mv	s2,a0
  if(!mnt) {
    80005d52:	f931                	bnez	a0,80005ca6 <vfs_mount+0xac>
    80005d54:	a899                	j	80005daa <vfs_mount+0x1b0>
      printf("vfs_mount: first mount must be at /\n");
    80005d56:	00005517          	auipc	a0,0x5
    80005d5a:	a7250513          	addi	a0,a0,-1422 # 8000a7c8 <etext+0x7c8>
    80005d5e:	f9cfa0ef          	jal	800004fa <printf>
      return -1;
    80005d62:	54fd                	li	s1,-1
    80005d64:	bf45                	j	80005d14 <vfs_mount+0x11a>
      printf("vfs_mount: mount point not found: %s\n", target);
    80005d66:	85d6                	mv	a1,s5
    80005d68:	00005517          	auipc	a0,0x5
    80005d6c:	a8850513          	addi	a0,a0,-1400 # 8000a7f0 <etext+0x7f0>
    80005d70:	f8afa0ef          	jal	800004fa <printf>
      return -1;
    80005d74:	54fd                	li	s1,-1
    80005d76:	bf79                	j	80005d14 <vfs_mount+0x11a>
      iput(mountpoint);
    80005d78:	e5afd0ef          	jal	800033d2 <iput>
      printf("vfs_mount: already a mount point: %s\n", target);
    80005d7c:	85d6                	mv	a1,s5
    80005d7e:	00005517          	auipc	a0,0x5
    80005d82:	a9a50513          	addi	a0,a0,-1382 # 8000a818 <etext+0x818>
    80005d86:	f74fa0ef          	jal	800004fa <printf>
      return -1;
    80005d8a:	54fd                	li	s1,-1
    80005d8c:	b761                	j	80005d14 <vfs_mount+0x11a>
      iput(mountpoint);
    80005d8e:	854e                	mv	a0,s3
    80005d90:	e42fd0ef          	jal	800033d2 <iput>
    printf("vfs_mount: mount failed\n");
    80005d94:	00005517          	auipc	a0,0x5
    80005d98:	aac50513          	addi	a0,a0,-1364 # 8000a840 <etext+0x840>
    80005d9c:	f5efa0ef          	jal	800004fa <printf>
    return -1;
    80005da0:	54fd                	li	s1,-1
    80005da2:	bf8d                	j	80005d14 <vfs_mount+0x11a>
      iput(mountpoint);
    80005da4:	854e                	mv	a0,s3
    80005da6:	e2cfd0ef          	jal	800033d2 <iput>
    printf("vfs_mount: out of memory\n");
    80005daa:	00005517          	auipc	a0,0x5
    80005dae:	ab650513          	addi	a0,a0,-1354 # 8000a860 <etext+0x860>
    80005db2:	f48fa0ef          	jal	800004fa <printf>
    return -1;
    80005db6:	54fd                	li	s1,-1
    80005db8:	bfb1                	j	80005d14 <vfs_mount+0x11a>
    vfs_root_mnt = mnt;
    80005dba:	00009797          	auipc	a5,0x9
    80005dbe:	a927bf23          	sd	s2,-1378(a5) # 8000e858 <vfs_root_mnt>
    80005dc2:	b799                	j	80005d08 <vfs_mount+0x10e>

0000000080005dc4 <vfs_umount>:
{
    80005dc4:	7179                	addi	sp,sp,-48
    80005dc6:	f406                	sd	ra,40(sp)
    80005dc8:	f022                	sd	s0,32(sp)
    80005dca:	ec26                	sd	s1,24(sp)
    80005dcc:	e84a                	sd	s2,16(sp)
    80005dce:	e44e                	sd	s3,8(sp)
    80005dd0:	1800                	addi	s0,sp,48
    80005dd2:	89aa                	mv	s3,a0
  acquire(&vfs_lock);
    80005dd4:	00022517          	auipc	a0,0x22
    80005dd8:	76450513          	addi	a0,a0,1892 # 80028538 <vfs_lock>
    80005ddc:	df3fa0ef          	jal	80000bce <acquire>
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    80005de0:	00009497          	auipc	s1,0x9
    80005de4:	a704b483          	ld	s1,-1424(s1) # 8000e850 <vfs_mounts>
    80005de8:	c485                	beqz	s1,80005e10 <vfs_umount+0x4c>
    80005dea:	e052                	sd	s4,0(sp)
  prev = &vfs_mounts;
    80005dec:	00009a17          	auipc	s4,0x9
    80005df0:	a64a0a13          	addi	s4,s4,-1436 # 8000e850 <vfs_mounts>
    if(strncmp(mnt->mnt_dirname, target, MAXPATH) == 0) {
    80005df4:	08000613          	li	a2,128
    80005df8:	85ce                	mv	a1,s3
    80005dfa:	03048513          	addi	a0,s1,48
    80005dfe:	f71fa0ef          	jal	80000d6e <strncmp>
    80005e02:	892a                	mv	s2,a0
    80005e04:	c50d                	beqz	a0,80005e2e <vfs_umount+0x6a>
    prev = &mnt->next;
    80005e06:	0b048a13          	addi	s4,s1,176
  for(mnt = vfs_mounts; mnt; mnt = mnt->next) {
    80005e0a:	78c4                	ld	s1,176(s1)
    80005e0c:	f4e5                	bnez	s1,80005df4 <vfs_umount+0x30>
    80005e0e:	6a02                	ld	s4,0(sp)
  release(&vfs_lock);
    80005e10:	00022517          	auipc	a0,0x22
    80005e14:	72850513          	addi	a0,a0,1832 # 80028538 <vfs_lock>
    80005e18:	e4ffa0ef          	jal	80000c66 <release>
  return -1;
    80005e1c:	597d                	li	s2,-1
}
    80005e1e:	854a                	mv	a0,s2
    80005e20:	70a2                	ld	ra,40(sp)
    80005e22:	7402                	ld	s0,32(sp)
    80005e24:	64e2                	ld	s1,24(sp)
    80005e26:	6942                	ld	s2,16(sp)
    80005e28:	69a2                	ld	s3,8(sp)
    80005e2a:	6145                	addi	sp,sp,48
    80005e2c:	8082                	ret
      if(mnt == vfs_root_mnt) {
    80005e2e:	00009797          	auipc	a5,0x9
    80005e32:	a2a7b783          	ld	a5,-1494(a5) # 8000e858 <vfs_root_mnt>
    80005e36:	02978763          	beq	a5,s1,80005e64 <vfs_umount+0xa0>
      *prev = mnt->next;
    80005e3a:	78dc                	ld	a5,176(s1)
    80005e3c:	00fa3023          	sd	a5,0(s4)
      if(mnt->mnt_mountpoint) {
    80005e40:	649c                	ld	a5,8(s1)
    80005e42:	c791                	beqz	a5,80005e4e <vfs_umount+0x8a>
        mnt->mnt_mountpoint->i_mount = 0;
    80005e44:	0607bc23          	sd	zero,120(a5)
        iput(mnt->mnt_mountpoint);
    80005e48:	6488                	ld	a0,8(s1)
    80005e4a:	d88fd0ef          	jal	800033d2 <iput>
      release(&vfs_lock);
    80005e4e:	00022517          	auipc	a0,0x22
    80005e52:	6ea50513          	addi	a0,a0,1770 # 80028538 <vfs_lock>
    80005e56:	e11fa0ef          	jal	80000c66 <release>
      kfree(mnt);
    80005e5a:	8526                	mv	a0,s1
    80005e5c:	bc1fa0ef          	jal	80000a1c <kfree>
      return 0;
    80005e60:	6a02                	ld	s4,0(sp)
    80005e62:	bf75                	j	80005e1e <vfs_umount+0x5a>
        release(&vfs_lock);
    80005e64:	00022517          	auipc	a0,0x22
    80005e68:	6d450513          	addi	a0,a0,1748 # 80028538 <vfs_lock>
    80005e6c:	dfbfa0ef          	jal	80000c66 <release>
        return -1;
    80005e70:	597d                	li	s2,-1
    80005e72:	6a02                	ld	s4,0(sp)
    80005e74:	b76d                	j	80005e1e <vfs_umount+0x5a>

0000000080005e76 <vfs_namei>:

// Path resolution with mount point handling
struct inode*
vfs_namei(const char *path)
{
    80005e76:	7159                	addi	sp,sp,-112
    80005e78:	f486                	sd	ra,104(sp)
    80005e7a:	f0a2                	sd	s0,96(sp)
    80005e7c:	eca6                	sd	s1,88(sp)
    80005e7e:	e4ce                	sd	s3,72(sp)
    80005e80:	1880                	addi	s0,sp,112
    80005e82:	84aa                	mv	s1,a0
  char name[DIRSIZ];
  struct inode *ip, *next;
  //const char *s;
  int len;

  if(*path == '/') {
    80005e84:	00054703          	lbu	a4,0(a0)
    80005e88:	02f00793          	li	a5,47
    80005e8c:	02f71163          	bne	a4,a5,80005eae <vfs_namei+0x38>
    // Absolute path - start from root mount
    if(!vfs_root_mnt || !vfs_root_mnt->mnt_root)
    80005e90:	00009997          	auipc	s3,0x9
    80005e94:	9c89b983          	ld	s3,-1592(s3) # 8000e858 <vfs_root_mnt>
    80005e98:	14098263          	beqz	s3,80005fdc <vfs_namei+0x166>
    80005e9c:	0109b983          	ld	s3,16(s3)
    80005ea0:	12098e63          	beqz	s3,80005fdc <vfs_namei+0x166>
      return 0;
    ip = vfs_root_mnt->mnt_root;
    idup(ip);
    80005ea4:	854e                	mv	a0,s3
    80005ea6:	b74fd0ef          	jal	8000321a <idup>
    path++;
    80005eaa:	0485                	addi	s1,s1,1
    80005eac:	a801                	j	80005ebc <vfs_namei+0x46>
  } else {
    // Relative path - start from cwd
    ip = myproc()->cwd;
    80005eae:	a49fb0ef          	jal	800018f6 <myproc>
    80005eb2:	15053983          	ld	s3,336(a0)
    idup(ip);
    80005eb6:	854e                	mv	a0,s3
    80005eb8:	b62fd0ef          	jal	8000321a <idup>
  }

  // Follow mount point if at one
  ip = vfs_follow_mount(ip);
    80005ebc:	854e                	mv	a0,s3
    80005ebe:	c13ff0ef          	jal	80005ad0 <vfs_follow_mount>
    80005ec2:	89aa                	mv	s3,a0

  // Parse path components
  while(*path) {
    80005ec4:	0004c783          	lbu	a5,0(s1)
    80005ec8:	10078a63          	beqz	a5,80005fdc <vfs_namei+0x166>
    80005ecc:	e8ca                	sd	s2,80(sp)
    80005ece:	e0d2                	sd	s4,64(sp)
    80005ed0:	fc56                	sd	s5,56(sp)
    80005ed2:	f85a                	sd	s6,48(sp)
    80005ed4:	f45e                	sd	s7,40(sp)
    // Skip slashes
    while(*path == '/')
    80005ed6:	02f00913          	li	s2,47
    if(*path == 0)
      break;

    // Extract next component
    // s = path;
    len = 0;
    80005eda:	4b01                	li	s6,0
    while(*path && *path != '/' && len < DIRSIZ) {
    80005edc:	4a39                	li	s4,14

    // Look up component
    ilock(ip);

    // Check if directory
    if(ip->type != T_DIR) {
    80005ede:	4a85                	li	s5,1
    80005ee0:	a8a9                	j	80005f3a <vfs_namei+0xc4>
    len = 0;
    80005ee2:	4701                	li	a4,0
    80005ee4:	a079                	j	80005f72 <vfs_namei+0xfc>
      iunlockput(ip);
    80005ee6:	854e                	mv	a0,s3
    80005ee8:	d72fd0ef          	jal	8000345a <iunlockput>
      return 0;
    80005eec:	4981                	li	s3,0
    80005eee:	6946                	ld	s2,80(sp)
    80005ef0:	6a06                	ld	s4,64(sp)
    80005ef2:	7ae2                	ld	s5,56(sp)
    80005ef4:	7b42                	ld	s6,48(sp)
    80005ef6:	7ba2                	ld	s7,40(sp)
    80005ef8:	a0d5                	j	80005fdc <vfs_namei+0x166>

    // Use inode operations if available, otherwise fall back to namex
    if(ip->i_op && ip->i_op->lookup) {
      iunlock(ip);
      if(ip->i_op->lookup(ip, name, &next) < 0) {
        iput(ip);
    80005efa:	854e                	mv	a0,s3
    80005efc:	cd6fd0ef          	jal	800033d2 <iput>
        return 0;
    80005f00:	4981                	li	s3,0
    80005f02:	6946                	ld	s2,80(sp)
    80005f04:	6a06                	ld	s4,64(sp)
    80005f06:	7ae2                	ld	s5,56(sp)
    80005f08:	7b42                	ld	s6,48(sp)
    80005f0a:	7ba2                	ld	s7,40(sp)
    80005f0c:	a8c1                	j	80005fdc <vfs_namei+0x166>
      iput(ip);
      ip = next;
    } else {
      // Fall back to original dirlookup for xv6fs
      uint off;
      if((next = dirlookup(ip, name, &off)) == 0) {
    80005f0e:	f9440613          	addi	a2,s0,-108
    80005f12:	fa040593          	addi	a1,s0,-96
    80005f16:	854e                	mv	a0,s3
    80005f18:	8e9fd0ef          	jal	80003800 <dirlookup>
    80005f1c:	8baa                	mv	s7,a0
    80005f1e:	f8a43c23          	sd	a0,-104(s0)
    80005f22:	cd51                	beqz	a0,80005fbe <vfs_namei+0x148>
        iunlockput(ip);
        return 0;
      }
      iunlockput(ip);
    80005f24:	854e                	mv	a0,s3
    80005f26:	d34fd0ef          	jal	8000345a <iunlockput>
      ip = next;
    80005f2a:	f9843503          	ld	a0,-104(s0)
    }

    // Follow mount point if needed
    ip = vfs_follow_mount(ip);
    80005f2e:	ba3ff0ef          	jal	80005ad0 <vfs_follow_mount>
    80005f32:	89aa                	mv	s3,a0
  while(*path) {
    80005f34:	0004c783          	lbu	a5,0(s1)
    80005f38:	cbcd                	beqz	a5,80005fea <vfs_namei+0x174>
    while(*path == '/')
    80005f3a:	0004c783          	lbu	a5,0(s1)
    80005f3e:	01279763          	bne	a5,s2,80005f4c <vfs_namei+0xd6>
      path++;
    80005f42:	0485                	addi	s1,s1,1
    while(*path == '/')
    80005f44:	0004c783          	lbu	a5,0(s1)
    80005f48:	ff278de3          	beq	a5,s2,80005f42 <vfs_namei+0xcc>
    if(*path == 0)
    80005f4c:	c3d9                	beqz	a5,80005fd2 <vfs_namei+0x15c>
    while(*path && *path != '/' && len < DIRSIZ) {
    80005f4e:	0004c783          	lbu	a5,0(s1)
    80005f52:	dbc1                	beqz	a5,80005ee2 <vfs_namei+0x6c>
    80005f54:	fa040693          	addi	a3,s0,-96
    len = 0;
    80005f58:	875a                	mv	a4,s6
    while(*path && *path != '/' && len < DIRSIZ) {
    80005f5a:	01278c63          	beq	a5,s2,80005f72 <vfs_namei+0xfc>
    80005f5e:	01470a63          	beq	a4,s4,80005f72 <vfs_namei+0xfc>
      name[len++] = *path++;
    80005f62:	0485                	addi	s1,s1,1
    80005f64:	2705                	addiw	a4,a4,1
    80005f66:	00f68023          	sb	a5,0(a3)
    while(*path && *path != '/' && len < DIRSIZ) {
    80005f6a:	0004c783          	lbu	a5,0(s1)
    80005f6e:	0685                	addi	a3,a3,1
    80005f70:	f7ed                	bnez	a5,80005f5a <vfs_namei+0xe4>
    name[len] = 0;
    80005f72:	fb070793          	addi	a5,a4,-80
    80005f76:	00878733          	add	a4,a5,s0
    80005f7a:	fe070823          	sb	zero,-16(a4)
    ilock(ip);
    80005f7e:	854e                	mv	a0,s3
    80005f80:	ad0fd0ef          	jal	80003250 <ilock>
    if(ip->type != T_DIR) {
    80005f84:	06099783          	lh	a5,96(s3)
    80005f88:	f5579fe3          	bne	a5,s5,80005ee6 <vfs_namei+0x70>
    if(ip->i_op && ip->i_op->lookup) {
    80005f8c:	0509b783          	ld	a5,80(s3)
    80005f90:	dfbd                	beqz	a5,80005f0e <vfs_namei+0x98>
    80005f92:	639c                	ld	a5,0(a5)
    80005f94:	dfad                	beqz	a5,80005f0e <vfs_namei+0x98>
      iunlock(ip);
    80005f96:	854e                	mv	a0,s3
    80005f98:	b66fd0ef          	jal	800032fe <iunlock>
      if(ip->i_op->lookup(ip, name, &next) < 0) {
    80005f9c:	0509b783          	ld	a5,80(s3)
    80005fa0:	639c                	ld	a5,0(a5)
    80005fa2:	f9840613          	addi	a2,s0,-104
    80005fa6:	fa040593          	addi	a1,s0,-96
    80005faa:	854e                	mv	a0,s3
    80005fac:	9782                	jalr	a5
    80005fae:	f40546e3          	bltz	a0,80005efa <vfs_namei+0x84>
      iput(ip);
    80005fb2:	854e                	mv	a0,s3
    80005fb4:	c1efd0ef          	jal	800033d2 <iput>
      ip = next;
    80005fb8:	f9843503          	ld	a0,-104(s0)
    80005fbc:	bf8d                	j	80005f2e <vfs_namei+0xb8>
        iunlockput(ip);
    80005fbe:	854e                	mv	a0,s3
    80005fc0:	c9afd0ef          	jal	8000345a <iunlockput>
        return 0;
    80005fc4:	89de                	mv	s3,s7
    80005fc6:	6946                	ld	s2,80(sp)
    80005fc8:	6a06                	ld	s4,64(sp)
    80005fca:	7ae2                	ld	s5,56(sp)
    80005fcc:	7b42                	ld	s6,48(sp)
    80005fce:	7ba2                	ld	s7,40(sp)
    80005fd0:	a031                	j	80005fdc <vfs_namei+0x166>
    80005fd2:	6946                	ld	s2,80(sp)
    80005fd4:	6a06                	ld	s4,64(sp)
    80005fd6:	7ae2                	ld	s5,56(sp)
    80005fd8:	7b42                	ld	s6,48(sp)
    80005fda:	7ba2                	ld	s7,40(sp)
  }

  return ip;
}
    80005fdc:	854e                	mv	a0,s3
    80005fde:	70a6                	ld	ra,104(sp)
    80005fe0:	7406                	ld	s0,96(sp)
    80005fe2:	64e6                	ld	s1,88(sp)
    80005fe4:	69a6                	ld	s3,72(sp)
    80005fe6:	6165                	addi	sp,sp,112
    80005fe8:	8082                	ret
    80005fea:	6946                	ld	s2,80(sp)
    80005fec:	6a06                	ld	s4,64(sp)
    80005fee:	7ae2                	ld	s5,56(sp)
    80005ff0:	7b42                	ld	s6,48(sp)
    80005ff2:	7ba2                	ld	s7,40(sp)
    80005ff4:	b7e5                	j	80005fdc <vfs_namei+0x166>

0000000080005ff6 <vfs_nameiparent>:

// Path resolution returning parent
struct inode*
vfs_nameiparent(const char *path, char *name)
{
    80005ff6:	1141                	addi	sp,sp,-16
    80005ff8:	e406                	sd	ra,8(sp)
    80005ffa:	e022                	sd	s0,0(sp)
    80005ffc:	0800                	addi	s0,sp,16
  // For now, use the original nameiparent
  // TODO: Implement proper VFS version
  return nameiparent((char*)path, name);
    80005ffe:	a83fd0ef          	jal	80003a80 <nameiparent>
}
    80006002:	60a2                	ld	ra,8(sp)
    80006004:	6402                	ld	s0,0(sp)
    80006006:	0141                	addi	sp,sp,16
    80006008:	8082                	ret

000000008000600a <vfs_open>:

// VFS open operation
int
vfs_open(struct inode *ip, struct file *f)
{
  if(ip->i_fop && ip->i_fop->open)
    8000600a:	6d38                	ld	a4,88(a0)
    8000600c:	cf19                	beqz	a4,8000602a <vfs_open+0x20>
    8000600e:	87aa                	mv	a5,a0
    80006010:	6b18                	ld	a4,16(a4)
    return ip->i_fop->open(ip, f);

  // No special open needed
  return 0;
    80006012:	4501                	li	a0,0
  if(ip->i_fop && ip->i_fop->open)
    80006014:	cf09                	beqz	a4,8000602e <vfs_open+0x24>
{
    80006016:	1141                	addi	sp,sp,-16
    80006018:	e406                	sd	ra,8(sp)
    8000601a:	e022                	sd	s0,0(sp)
    8000601c:	0800                	addi	s0,sp,16
    return ip->i_fop->open(ip, f);
    8000601e:	853e                	mv	a0,a5
    80006020:	9702                	jalr	a4
}
    80006022:	60a2                	ld	ra,8(sp)
    80006024:	6402                	ld	s0,0(sp)
    80006026:	0141                	addi	sp,sp,16
    80006028:	8082                	ret
  return 0;
    8000602a:	4501                	li	a0,0
    8000602c:	8082                	ret
}
    8000602e:	8082                	ret

0000000080006030 <vfs_read>:

// VFS read operation
int
vfs_read(struct file *f, uint64 addr, int n)
{
  if(!f->readable)
    80006030:	00854783          	lbu	a5,8(a0)
    80006034:	c385                	beqz	a5,80006054 <vfs_read+0x24>
    return -1;

  if(f->ip && f->ip->i_fop && f->ip->i_fop->read)
    80006036:	6d1c                	ld	a5,24(a0)
    80006038:	c385                	beqz	a5,80006058 <vfs_read+0x28>
    8000603a:	6fbc                	ld	a5,88(a5)
    8000603c:	c385                	beqz	a5,8000605c <vfs_read+0x2c>
    8000603e:	639c                	ld	a5,0(a5)
    80006040:	c385                	beqz	a5,80006060 <vfs_read+0x30>
{
    80006042:	1141                	addi	sp,sp,-16
    80006044:	e406                	sd	ra,8(sp)
    80006046:	e022                	sd	s0,0(sp)
    80006048:	0800                	addi	s0,sp,16
    return f->ip->i_fop->read(f, addr, n);
    8000604a:	9782                	jalr	a5

  return -1;
}
    8000604c:	60a2                	ld	ra,8(sp)
    8000604e:	6402                	ld	s0,0(sp)
    80006050:	0141                	addi	sp,sp,16
    80006052:	8082                	ret
    return -1;
    80006054:	557d                	li	a0,-1
    80006056:	8082                	ret
  return -1;
    80006058:	557d                	li	a0,-1
    8000605a:	8082                	ret
    8000605c:	557d                	li	a0,-1
    8000605e:	8082                	ret
    80006060:	557d                	li	a0,-1
}
    80006062:	8082                	ret

0000000080006064 <vfs_write>:

// VFS write operation
int
vfs_write(struct file *f, uint64 addr, int n)
{
  if(!f->writable)
    80006064:	00954783          	lbu	a5,9(a0)
    80006068:	c385                	beqz	a5,80006088 <vfs_write+0x24>
    return -1;

  if(f->ip && f->ip->i_fop && f->ip->i_fop->write)
    8000606a:	6d1c                	ld	a5,24(a0)
    8000606c:	c385                	beqz	a5,8000608c <vfs_write+0x28>
    8000606e:	6fbc                	ld	a5,88(a5)
    80006070:	c385                	beqz	a5,80006090 <vfs_write+0x2c>
    80006072:	679c                	ld	a5,8(a5)
    80006074:	c385                	beqz	a5,80006094 <vfs_write+0x30>
{
    80006076:	1141                	addi	sp,sp,-16
    80006078:	e406                	sd	ra,8(sp)
    8000607a:	e022                	sd	s0,0(sp)
    8000607c:	0800                	addi	s0,sp,16
    return f->ip->i_fop->write(f, addr, n);
    8000607e:	9782                	jalr	a5

  return -1;
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret
    return -1;
    80006088:	557d                	li	a0,-1
    8000608a:	8082                	ret
  return -1;
    8000608c:	557d                	li	a0,-1
    8000608e:	8082                	ret
    80006090:	557d                	li	a0,-1
    80006092:	8082                	ret
    80006094:	557d                	li	a0,-1
}
    80006096:	8082                	ret

0000000080006098 <vfs_stat>:

// VFS stat operation
int
vfs_stat(struct inode *ip, struct stat *st)
{
  if(ip->i_op && ip->i_op->getattr)
    80006098:	693c                	ld	a5,80(a0)
    8000609a:	cf81                	beqz	a5,800060b2 <vfs_stat+0x1a>
    8000609c:	7b9c                	ld	a5,48(a5)
    8000609e:	cb91                	beqz	a5,800060b2 <vfs_stat+0x1a>
{
    800060a0:	1141                	addi	sp,sp,-16
    800060a2:	e406                	sd	ra,8(sp)
    800060a4:	e022                	sd	s0,0(sp)
    800060a6:	0800                	addi	s0,sp,16
    return ip->i_op->getattr(ip, st);
    800060a8:	9782                	jalr	a5
  st->type = ip->type;
  st->nlink = ip->nlink;
  st->size = ip->size;

  return 0;
}
    800060aa:	60a2                	ld	ra,8(sp)
    800060ac:	6402                	ld	s0,0(sp)
    800060ae:	0141                	addi	sp,sp,16
    800060b0:	8082                	ret
  st->dev = ip->dev;
    800060b2:	411c                	lw	a5,0(a0)
    800060b4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800060b6:	415c                	lw	a5,4(a0)
    800060b8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800060ba:	06051783          	lh	a5,96(a0)
    800060be:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800060c2:	06651783          	lh	a5,102(a0)
    800060c6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800060ca:	06856783          	lwu	a5,104(a0)
    800060ce:	e99c                	sd	a5,16(a1)
  return 0;
    800060d0:	4501                	li	a0,0
}
    800060d2:	8082                	ret

00000000800060d4 <vfs_create>:

// VFS create operation
int
vfs_create(struct inode *dir, const char *name, short type, struct inode **result)
{
  if(!dir || dir->type != T_DIR)
    800060d4:	c11d                	beqz	a0,800060fa <vfs_create+0x26>
    800060d6:	06051703          	lh	a4,96(a0)
    800060da:	4785                	li	a5,1
    800060dc:	02f71163          	bne	a4,a5,800060fe <vfs_create+0x2a>
    return -1;

  if(dir->i_op && dir->i_op->create)
    800060e0:	693c                	ld	a5,80(a0)
    800060e2:	c385                	beqz	a5,80006102 <vfs_create+0x2e>
    800060e4:	679c                	ld	a5,8(a5)
    800060e6:	c385                	beqz	a5,80006106 <vfs_create+0x32>
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
    return dir->i_op->create(dir, name, type, result);
    800060f0:	9782                	jalr	a5

  return -1;
}
    800060f2:	60a2                	ld	ra,8(sp)
    800060f4:	6402                	ld	s0,0(sp)
    800060f6:	0141                	addi	sp,sp,16
    800060f8:	8082                	ret
    return -1;
    800060fa:	557d                	li	a0,-1
    800060fc:	8082                	ret
    800060fe:	557d                	li	a0,-1
    80006100:	8082                	ret
  return -1;
    80006102:	557d                	li	a0,-1
    80006104:	8082                	ret
    80006106:	557d                	li	a0,-1
}
    80006108:	8082                	ret

000000008000610a <vfs_mkdir>:

// VFS mkdir operation
int
vfs_mkdir(struct inode *dir, const char *name)
{
  if(!dir || dir->type != T_DIR)
    8000610a:	c11d                	beqz	a0,80006130 <vfs_mkdir+0x26>
    8000610c:	06051703          	lh	a4,96(a0)
    80006110:	4785                	li	a5,1
    80006112:	02f71163          	bne	a4,a5,80006134 <vfs_mkdir+0x2a>
    return -1;

  if(dir->i_op && dir->i_op->mkdir)
    80006116:	693c                	ld	a5,80(a0)
    80006118:	c385                	beqz	a5,80006138 <vfs_mkdir+0x2e>
    8000611a:	739c                	ld	a5,32(a5)
    8000611c:	c385                	beqz	a5,8000613c <vfs_mkdir+0x32>
{
    8000611e:	1141                	addi	sp,sp,-16
    80006120:	e406                	sd	ra,8(sp)
    80006122:	e022                	sd	s0,0(sp)
    80006124:	0800                	addi	s0,sp,16
    return dir->i_op->mkdir(dir, name);
    80006126:	9782                	jalr	a5

  return -1;
}
    80006128:	60a2                	ld	ra,8(sp)
    8000612a:	6402                	ld	s0,0(sp)
    8000612c:	0141                	addi	sp,sp,16
    8000612e:	8082                	ret
    return -1;
    80006130:	557d                	li	a0,-1
    80006132:	8082                	ret
    80006134:	557d                	li	a0,-1
    80006136:	8082                	ret
  return -1;
    80006138:	557d                	li	a0,-1
    8000613a:	8082                	ret
    8000613c:	557d                	li	a0,-1
}
    8000613e:	8082                	ret

0000000080006140 <vfs_unlink>:

// VFS unlink operation
int
vfs_unlink(struct inode *dir, const char *name)
{
  if(!dir || dir->type != T_DIR)
    80006140:	c11d                	beqz	a0,80006166 <vfs_unlink+0x26>
    80006142:	06051703          	lh	a4,96(a0)
    80006146:	4785                	li	a5,1
    80006148:	02f71163          	bne	a4,a5,8000616a <vfs_unlink+0x2a>
    return -1;

  if(dir->i_op && dir->i_op->unlink)
    8000614c:	693c                	ld	a5,80(a0)
    8000614e:	c385                	beqz	a5,8000616e <vfs_unlink+0x2e>
    80006150:	6f9c                	ld	a5,24(a5)
    80006152:	c385                	beqz	a5,80006172 <vfs_unlink+0x32>
{
    80006154:	1141                	addi	sp,sp,-16
    80006156:	e406                	sd	ra,8(sp)
    80006158:	e022                	sd	s0,0(sp)
    8000615a:	0800                	addi	s0,sp,16
    return dir->i_op->unlink(dir, name);
    8000615c:	9782                	jalr	a5

  return -1;
}
    8000615e:	60a2                	ld	ra,8(sp)
    80006160:	6402                	ld	s0,0(sp)
    80006162:	0141                	addi	sp,sp,16
    80006164:	8082                	ret
    return -1;
    80006166:	557d                	li	a0,-1
    80006168:	8082                	ret
    8000616a:	557d                	li	a0,-1
    8000616c:	8082                	ret
  return -1;
    8000616e:	557d                	li	a0,-1
    80006170:	8082                	ret
    80006172:	557d                	li	a0,-1
}
    80006174:	8082                	ret

0000000080006176 <vfs_link>:

// VFS link operation
int
vfs_link(struct inode *ip, struct inode *dir, const char *name)
{
  if(!ip || !dir || dir->type != T_DIR)
    80006176:	c505                	beqz	a0,8000619e <vfs_link+0x28>
    80006178:	c58d                	beqz	a1,800061a2 <vfs_link+0x2c>
    8000617a:	06059703          	lh	a4,96(a1)
    8000617e:	4785                	li	a5,1
    80006180:	02f71363          	bne	a4,a5,800061a6 <vfs_link+0x30>
    return -1;

  if(dir->i_op && dir->i_op->link)
    80006184:	69bc                	ld	a5,80(a1)
    80006186:	c395                	beqz	a5,800061aa <vfs_link+0x34>
    80006188:	6b9c                	ld	a5,16(a5)
    8000618a:	c395                	beqz	a5,800061ae <vfs_link+0x38>
{
    8000618c:	1141                	addi	sp,sp,-16
    8000618e:	e406                	sd	ra,8(sp)
    80006190:	e022                	sd	s0,0(sp)
    80006192:	0800                	addi	s0,sp,16
    return dir->i_op->link(ip, dir, name);
    80006194:	9782                	jalr	a5

  return -1;
}
    80006196:	60a2                	ld	ra,8(sp)
    80006198:	6402                	ld	s0,0(sp)
    8000619a:	0141                	addi	sp,sp,16
    8000619c:	8082                	ret
    return -1;
    8000619e:	557d                	li	a0,-1
    800061a0:	8082                	ret
    800061a2:	557d                	li	a0,-1
    800061a4:	8082                	ret
    800061a6:	557d                	li	a0,-1
    800061a8:	8082                	ret
  return -1;
    800061aa:	557d                	li	a0,-1
    800061ac:	8082                	ret
    800061ae:	557d                	li	a0,-1
}
    800061b0:	8082                	ret

00000000800061b2 <xv6fs_file_write>:
}

// Wrapper for file write
static int
xv6fs_file_write(struct file *f, uint64 addr, int n)
{
    800061b2:	711d                	addi	sp,sp,-96
    800061b4:	ec86                	sd	ra,88(sp)
    800061b6:	e8a2                	sd	s0,80(sp)
    800061b8:	e0ca                	sd	s2,64(sp)
    800061ba:	fc4e                	sd	s3,56(sp)
    800061bc:	f852                	sd	s4,48(sp)
    800061be:	1080                	addi	s0,sp,96
    800061c0:	8a32                	mv	s4,a2
  struct inode *ip = f->ip;
    800061c2:	01853983          	ld	s3,24(a0)
  int r;
  int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
  int i = 0;

  while(i < n){
    800061c6:	08c05463          	blez	a2,8000624e <xv6fs_file_write+0x9c>
    800061ca:	e4a6                	sd	s1,72(sp)
    800061cc:	f456                	sd	s5,40(sp)
    800061ce:	f05a                	sd	s6,32(sp)
    800061d0:	ec5e                	sd	s7,24(sp)
    800061d2:	e862                	sd	s8,16(sp)
    800061d4:	e466                	sd	s9,8(sp)
    800061d6:	8aaa                	mv	s5,a0
    800061d8:	8bae                	mv	s7,a1
  int i = 0;
    800061da:	4901                	li	s2,0
    int n1 = n - i;
    if(n1 > max)
    800061dc:	6c05                	lui	s8,0x1
    800061de:	c00c0c13          	addi	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800061e2:	6c85                	lui	s9,0x1
    800061e4:	c00c8c9b          	addiw	s9,s9,-1024 # c00 <_entry-0x7ffff400>
    800061e8:	a0a1                	j	80006230 <xv6fs_file_write+0x7e>
    800061ea:	00048b1b          	sext.w	s6,s1
      n1 = max;

    begin_op();
    800061ee:	a4dfd0ef          	jal	80003c3a <begin_op>
    ilock(ip);
    800061f2:	854e                	mv	a0,s3
    800061f4:	85cfd0ef          	jal	80003250 <ilock>
    if ((r = writei(ip, 1, addr + i, f->off, n1)) > 0)
    800061f8:	875a                	mv	a4,s6
    800061fa:	020aa683          	lw	a3,32(s5)
    800061fe:	01790633          	add	a2,s2,s7
    80006202:	4585                	li	a1,1
    80006204:	854e                	mv	a0,s3
    80006206:	cd6fd0ef          	jal	800036dc <writei>
    8000620a:	84aa                	mv	s1,a0
    8000620c:	00a05763          	blez	a0,8000621a <xv6fs_file_write+0x68>
      f->off += r;
    80006210:	020aa783          	lw	a5,32(s5)
    80006214:	9fa9                	addw	a5,a5,a0
    80006216:	02faa023          	sw	a5,32(s5)
    iunlock(ip);
    8000621a:	854e                	mv	a0,s3
    8000621c:	8e2fd0ef          	jal	800032fe <iunlock>
    end_op();
    80006220:	a85fd0ef          	jal	80003ca4 <end_op>

    if(r != n1)
    80006224:	029b1763          	bne	s6,s1,80006252 <xv6fs_file_write+0xa0>
      break;
    i += r;
    80006228:	0124893b          	addw	s2,s1,s2
  while(i < n){
    8000622c:	01495a63          	bge	s2,s4,80006240 <xv6fs_file_write+0x8e>
    int n1 = n - i;
    80006230:	412a04bb          	subw	s1,s4,s2
    if(n1 > max)
    80006234:	0004879b          	sext.w	a5,s1
    80006238:	fafc59e3          	bge	s8,a5,800061ea <xv6fs_file_write+0x38>
    8000623c:	84e6                	mv	s1,s9
    8000623e:	b775                	j	800061ea <xv6fs_file_write+0x38>
    80006240:	64a6                	ld	s1,72(sp)
    80006242:	7aa2                	ld	s5,40(sp)
    80006244:	7b02                	ld	s6,32(sp)
    80006246:	6be2                	ld	s7,24(sp)
    80006248:	6c42                	ld	s8,16(sp)
    8000624a:	6ca2                	ld	s9,8(sp)
    8000624c:	a809                	j	8000625e <xv6fs_file_write+0xac>
  int i = 0;
    8000624e:	4901                	li	s2,0
    80006250:	a039                	j	8000625e <xv6fs_file_write+0xac>
    80006252:	64a6                	ld	s1,72(sp)
    80006254:	7aa2                	ld	s5,40(sp)
    80006256:	7b02                	ld	s6,32(sp)
    80006258:	6be2                	ld	s7,24(sp)
    8000625a:	6c42                	ld	s8,16(sp)
    8000625c:	6ca2                	ld	s9,8(sp)
  }

  return (i == n ? n : -1);
    8000625e:	012a1a63          	bne	s4,s2,80006272 <xv6fs_file_write+0xc0>
    80006262:	8552                	mv	a0,s4
}
    80006264:	60e6                	ld	ra,88(sp)
    80006266:	6446                	ld	s0,80(sp)
    80006268:	6906                	ld	s2,64(sp)
    8000626a:	79e2                	ld	s3,56(sp)
    8000626c:	7a42                	ld	s4,48(sp)
    8000626e:	6125                	addi	sp,sp,96
    80006270:	8082                	ret
  return (i == n ? n : -1);
    80006272:	557d                	li	a0,-1
    80006274:	bfc5                	j	80006264 <xv6fs_file_write+0xb2>

0000000080006276 <xv6fs_file_read>:
{
    80006276:	7179                	addi	sp,sp,-48
    80006278:	f406                	sd	ra,40(sp)
    8000627a:	f022                	sd	s0,32(sp)
    8000627c:	ec26                	sd	s1,24(sp)
    8000627e:	e84a                	sd	s2,16(sp)
    80006280:	e44e                	sd	s3,8(sp)
    80006282:	e052                	sd	s4,0(sp)
    80006284:	1800                	addi	s0,sp,48
    80006286:	84aa                	mv	s1,a0
    80006288:	892e                	mv	s2,a1
    8000628a:	8a32                	mv	s4,a2
  struct inode *ip = f->ip;
    8000628c:	01853983          	ld	s3,24(a0)
  ilock(ip);
    80006290:	854e                	mv	a0,s3
    80006292:	fbffc0ef          	jal	80003250 <ilock>
  if((r = readi(ip, 1, addr, f->off, n)) > 0)
    80006296:	8752                	mv	a4,s4
    80006298:	5094                	lw	a3,32(s1)
    8000629a:	864a                	mv	a2,s2
    8000629c:	4585                	li	a1,1
    8000629e:	854e                	mv	a0,s3
    800062a0:	b40fd0ef          	jal	800035e0 <readi>
    800062a4:	892a                	mv	s2,a0
    800062a6:	00a05563          	blez	a0,800062b0 <xv6fs_file_read+0x3a>
    f->off += r;
    800062aa:	509c                	lw	a5,32(s1)
    800062ac:	9fa9                	addw	a5,a5,a0
    800062ae:	d09c                	sw	a5,32(s1)
  iunlock(ip);
    800062b0:	854e                	mv	a0,s3
    800062b2:	84cfd0ef          	jal	800032fe <iunlock>
}
    800062b6:	854a                	mv	a0,s2
    800062b8:	70a2                	ld	ra,40(sp)
    800062ba:	7402                	ld	s0,32(sp)
    800062bc:	64e2                	ld	s1,24(sp)
    800062be:	6942                	ld	s2,16(sp)
    800062c0:	69a2                	ld	s3,8(sp)
    800062c2:	6a02                	ld	s4,0(sp)
    800062c4:	6145                	addi	sp,sp,48
    800062c6:	8082                	ret

00000000800062c8 <xv6fs_getattr>:
}

// Wrapper for getattr
static int
xv6fs_getattr(struct inode *ip, struct stat *st)
{
    800062c8:	1101                	addi	sp,sp,-32
    800062ca:	ec06                	sd	ra,24(sp)
    800062cc:	e822                	sd	s0,16(sp)
    800062ce:	e426                	sd	s1,8(sp)
    800062d0:	e04a                	sd	s2,0(sp)
    800062d2:	1000                	addi	s0,sp,32
    800062d4:	84aa                	mv	s1,a0
    800062d6:	892e                	mv	s2,a1
  ilock(ip);
    800062d8:	f79fc0ef          	jal	80003250 <ilock>
  stati(ip, st);
    800062dc:	85ca                	mv	a1,s2
    800062de:	8526                	mv	a0,s1
    800062e0:	ad6fd0ef          	jal	800035b6 <stati>
  iunlock(ip);
    800062e4:	8526                	mv	a0,s1
    800062e6:	818fd0ef          	jal	800032fe <iunlock>
  return 0;
}
    800062ea:	4501                	li	a0,0
    800062ec:	60e2                	ld	ra,24(sp)
    800062ee:	6442                	ld	s0,16(sp)
    800062f0:	64a2                	ld	s1,8(sp)
    800062f2:	6902                	ld	s2,0(sp)
    800062f4:	6105                	addi	sp,sp,32
    800062f6:	8082                	ret

00000000800062f8 <xv6fs_lookup>:
{
    800062f8:	7139                	addi	sp,sp,-64
    800062fa:	fc06                	sd	ra,56(sp)
    800062fc:	f822                	sd	s0,48(sp)
    800062fe:	f426                	sd	s1,40(sp)
    80006300:	f04a                	sd	s2,32(sp)
    80006302:	ec4e                	sd	s3,24(sp)
    80006304:	0080                	addi	s0,sp,64
    80006306:	84aa                	mv	s1,a0
    80006308:	892e                	mv	s2,a1
    8000630a:	89b2                	mv	s3,a2
  ilock(dir);
    8000630c:	f45fc0ef          	jal	80003250 <ilock>
  ip = dirlookup(dir, (char*)name, &off);
    80006310:	fcc40613          	addi	a2,s0,-52
    80006314:	85ca                	mv	a1,s2
    80006316:	8526                	mv	a0,s1
    80006318:	ce8fd0ef          	jal	80003800 <dirlookup>
    8000631c:	892a                	mv	s2,a0
  iunlock(dir);
    8000631e:	8526                	mv	a0,s1
    80006320:	fdffc0ef          	jal	800032fe <iunlock>
  if(!ip)
    80006324:	00090c63          	beqz	s2,8000633c <xv6fs_lookup+0x44>
  *result = ip;
    80006328:	0129b023          	sd	s2,0(s3)
  return 0;
    8000632c:	4501                	li	a0,0
}
    8000632e:	70e2                	ld	ra,56(sp)
    80006330:	7442                	ld	s0,48(sp)
    80006332:	74a2                	ld	s1,40(sp)
    80006334:	7902                	ld	s2,32(sp)
    80006336:	69e2                	ld	s3,24(sp)
    80006338:	6121                	addi	sp,sp,64
    8000633a:	8082                	ret
    return -1;
    8000633c:	557d                	li	a0,-1
    8000633e:	bfc5                	j	8000632e <xv6fs_lookup+0x36>

0000000080006340 <xv6fs_kill_sb>:

// Unmount function for xv6fs
void
xv6fs_kill_sb(struct vfs_superblock *sb)
{
  if(!sb)
    80006340:	c51d                	beqz	a0,8000636e <xv6fs_kill_sb+0x2e>
{
    80006342:	1101                	addi	sp,sp,-32
    80006344:	ec06                	sd	ra,24(sp)
    80006346:	e822                	sd	s0,16(sp)
    80006348:	e426                	sd	s1,8(sp)
    8000634a:	1000                	addi	s0,sp,32
    8000634c:	84aa                	mv	s1,a0
    return;

  // Release root inode
  if(sb->s_root)
    8000634e:	7108                	ld	a0,32(a0)
    80006350:	c119                	beqz	a0,80006356 <xv6fs_kill_sb+0x16>
    iput(sb->s_root);
    80006352:	880fd0ef          	jal	800033d2 <iput>

  // Free superblock info
  if(sb->s_fs_info)
    80006356:	6888                	ld	a0,16(s1)
    80006358:	c119                	beqz	a0,8000635e <xv6fs_kill_sb+0x1e>
    kfree(sb->s_fs_info);
    8000635a:	ec2fa0ef          	jal	80000a1c <kfree>

  // Free VFS superblock
  kfree(sb);
    8000635e:	8526                	mv	a0,s1
    80006360:	ebcfa0ef          	jal	80000a1c <kfree>
}
    80006364:	60e2                	ld	ra,24(sp)
    80006366:	6442                	ld	s0,16(sp)
    80006368:	64a2                	ld	s1,8(sp)
    8000636a:	6105                	addi	sp,sp,32
    8000636c:	8082                	ret
    8000636e:	8082                	ret

0000000080006370 <xv6fs_init_inode>:
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e422                	sd	s0,8(sp)
    80006374:	0800                	addi	s0,sp,16
  ip->i_sb = sb;
    80006376:	e52c                	sd	a1,72(a0)
  if(ip->type == T_DIR) {
    80006378:	06051683          	lh	a3,96(a0)
    8000637c:	4705                	li	a4,1
    ip->i_op = &xv6fs_inode_ops;
    8000637e:	00008797          	auipc	a5,0x8
    80006382:	36a78793          	addi	a5,a5,874 # 8000e6e8 <xv6fs_inode_ops>
  if(ip->type == T_DIR) {
    80006386:	00e68f63          	beq	a3,a4,800063a4 <xv6fs_init_inode+0x34>
    8000638a:	e93c                	sd	a5,80(a0)
  ip->i_fop = &xv6fs_file_ops;
    8000638c:	00008797          	auipc	a5,0x8
    80006390:	39478793          	addi	a5,a5,916 # 8000e720 <xv6fs_file_ops>
    80006394:	ed3c                	sd	a5,88(a0)
  ip->i_private = 0;                 // xv6fs uses fields directly in inode
    80006396:	06053823          	sd	zero,112(a0)
  ip->i_mount = 0;
    8000639a:	06053c23          	sd	zero,120(a0)
}
    8000639e:	6422                	ld	s0,8(sp)
    800063a0:	0141                	addi	sp,sp,16
    800063a2:	8082                	ret
    ip->i_op = &xv6fs_dir_ops;
    800063a4:	00008797          	auipc	a5,0x8
    800063a8:	30c78793          	addi	a5,a5,780 # 8000e6b0 <xv6fs_dir_ops>
    800063ac:	bff9                	j	8000638a <xv6fs_init_inode+0x1a>

00000000800063ae <xv6fs_mount>:
{
    800063ae:	7179                	addi	sp,sp,-48
    800063b0:	f406                	sd	ra,40(sp)
    800063b2:	f022                	sd	s0,32(sp)
    800063b4:	ec26                	sd	s1,24(sp)
    800063b6:	e84a                	sd	s2,16(sp)
    800063b8:	1800                	addi	s0,sp,48
    800063ba:	892a                	mv	s2,a0
  vfs_sb = (struct vfs_superblock*)kalloc();
    800063bc:	f42fa0ef          	jal	80000afe <kalloc>
    800063c0:	84aa                	mv	s1,a0
  if(!vfs_sb)
    800063c2:	cd31                	beqz	a0,8000641e <xv6fs_mount+0x70>
    800063c4:	e44e                	sd	s3,8(sp)
  sbi = (struct xv6fs_sb_info*)kalloc();
    800063c6:	f38fa0ef          	jal	80000afe <kalloc>
    800063ca:	89aa                	mv	s3,a0
  if(!sbi) {
    800063cc:	c125                	beqz	a0,8000642c <xv6fs_mount+0x7e>
  sbi->dev = dev;
    800063ce:	03252023          	sw	s2,32(a0)
  vfs_sb->dev = dev;
    800063d2:	0124a023          	sw	s2,0(s1)
  vfs_sb->s_op = &xv6fs_super_ops;
    800063d6:	00022797          	auipc	a5,0x22
    800063da:	17a78793          	addi	a5,a5,378 # 80028550 <xv6fs_super_ops>
    800063de:	e49c                	sd	a5,8(s1)
  vfs_sb->s_fs_info = sbi;
    800063e0:	e888                	sd	a0,16(s1)
  vfs_sb->s_type = 0;                // Will be set by vfs_mount
    800063e2:	0004bc23          	sd	zero,24(s1)
  vfs_sb->s_blocksize = BSIZE;
    800063e6:	40000793          	li	a5,1024
    800063ea:	d49c                	sw	a5,40(s1)
  initlock(&vfs_sb->s_lock, "xv6fs_sb");
    800063ec:	00004597          	auipc	a1,0x4
    800063f0:	49458593          	addi	a1,a1,1172 # 8000a880 <etext+0x880>
    800063f4:	03048513          	addi	a0,s1,48
    800063f8:	f56fa0ef          	jal	80000b4e <initlock>
  vfs_sb->s_root = iget(dev, ROOTINO);
    800063fc:	4585                	li	a1,1
    800063fe:	854a                	mv	a0,s2
    80006400:	cb3fc0ef          	jal	800030b2 <iget>
    80006404:	892a                	mv	s2,a0
    80006406:	f088                	sd	a0,32(s1)
  if(!vfs_sb->s_root) {
    80006408:	c905                	beqz	a0,80006438 <xv6fs_mount+0x8a>
  ilock(vfs_sb->s_root);
    8000640a:	e47fc0ef          	jal	80003250 <ilock>
  xv6fs_init_inode(vfs_sb->s_root, vfs_sb);
    8000640e:	85a6                	mv	a1,s1
    80006410:	7088                	ld	a0,32(s1)
    80006412:	f5fff0ef          	jal	80006370 <xv6fs_init_inode>
  iunlock(vfs_sb->s_root);
    80006416:	7088                	ld	a0,32(s1)
    80006418:	ee7fc0ef          	jal	800032fe <iunlock>
    8000641c:	69a2                	ld	s3,8(sp)
}
    8000641e:	8526                	mv	a0,s1
    80006420:	70a2                	ld	ra,40(sp)
    80006422:	7402                	ld	s0,32(sp)
    80006424:	64e2                	ld	s1,24(sp)
    80006426:	6942                	ld	s2,16(sp)
    80006428:	6145                	addi	sp,sp,48
    8000642a:	8082                	ret
    kfree(vfs_sb);
    8000642c:	8526                	mv	a0,s1
    8000642e:	deefa0ef          	jal	80000a1c <kfree>
    return 0;
    80006432:	84ce                	mv	s1,s3
    80006434:	69a2                	ld	s3,8(sp)
    80006436:	b7e5                	j	8000641e <xv6fs_mount+0x70>
    kfree(sbi);
    80006438:	854e                	mv	a0,s3
    8000643a:	de2fa0ef          	jal	80000a1c <kfree>
    kfree(vfs_sb);
    8000643e:	8526                	mv	a0,s1
    80006440:	ddcfa0ef          	jal	80000a1c <kfree>
    return 0;
    80006444:	84ca                	mv	s1,s2
    80006446:	69a2                	ld	s3,8(sp)
    80006448:	bfd9                	j	8000641e <xv6fs_mount+0x70>

000000008000644a <xv6fs_register>:
};

// Register xv6fs with VFS
int
xv6fs_register(void)
{
    8000644a:	1101                	addi	sp,sp,-32
    8000644c:	ec06                	sd	ra,24(sp)
    8000644e:	e822                	sd	s0,16(sp)
    80006450:	e426                	sd	s1,8(sp)
    80006452:	1000                	addi	s0,sp,32
  // Initialize the name
  safestrcpy(xv6fs_type.name, "xv6fs", 16);
    80006454:	00008497          	auipc	s1,0x8
    80006458:	2ec48493          	addi	s1,s1,748 # 8000e740 <xv6fs_type>
    8000645c:	4641                	li	a2,16
    8000645e:	00004597          	auipc	a1,0x4
    80006462:	d7a58593          	addi	a1,a1,-646 # 8000a1d8 <etext+0x1d8>
    80006466:	8526                	mv	a0,s1
    80006468:	979fa0ef          	jal	80000de0 <safestrcpy>
  return vfs_register_filesystem(&xv6fs_type);
    8000646c:	8526                	mv	a0,s1
    8000646e:	ec2ff0ef          	jal	80005b30 <vfs_register_filesystem>
}
    80006472:	60e2                	ld	ra,24(sp)
    80006474:	6442                	ld	s0,16(sp)
    80006476:	64a2                	ld	s1,8(sp)
    80006478:	6105                	addi	sp,sp,32
    8000647a:	8082                	ret

000000008000647c <net_init>:
#include "spinlock.h"
#include "defs.h"

void
net_init(void)
{
    8000647c:	1141                	addi	sp,sp,-16
    8000647e:	e406                	sd	ra,8(sp)
    80006480:	e022                	sd	s0,0(sp)
    80006482:	0800                	addi	s0,sp,16
  // Initialize network layers in order
  arp_init();
    80006484:	7da000ef          	jal	80006c5e <arp_init>
  ip_init();
    80006488:	43f000ef          	jal	800070c6 <ip_init>
  udp_init();
    8000648c:	01c010ef          	jal	800074a8 <udp_init>
  rpc_init();
    80006490:	71c010ef          	jal	80007bac <rpc_init>

  // Initialize network device
  virtio_net_init();
    80006494:	06c000ef          	jal	80006500 <virtio_net_init>
}
    80006498:	60a2                	ld	ra,8(sp)
    8000649a:	6402                	ld	s0,0(sp)
    8000649c:	0141                	addi	sp,sp,16
    8000649e:	8082                	ret

00000000800064a0 <free_tx_desc>:
  printf("virtio_net: initialized\n");
}

static void
free_tx_desc(int i)
{
    800064a0:	1141                	addi	sp,sp,-16
    800064a2:	e406                	sd	ra,8(sp)
    800064a4:	e022                	sd	s0,0(sp)
    800064a6:	0800                	addi	s0,sp,16
  if(i >= NUM) panic("free_tx_desc");
    800064a8:	479d                	li	a5,7
    800064aa:	02a7cf63          	blt	a5,a0,800064e8 <free_tx_desc+0x48>
  if(tx_free[i]) panic("free_tx_desc");
    800064ae:	00008797          	auipc	a5,0x8
    800064b2:	3c278793          	addi	a5,a5,962 # 8000e870 <tx_free>
    800064b6:	97aa                	add	a5,a5,a0
    800064b8:	0007c783          	lbu	a5,0(a5)
    800064bc:	ef85                	bnez	a5,800064f4 <free_tx_desc+0x54>
  tx_desc[i].addr = 0;
    800064be:	00451713          	slli	a4,a0,0x4
    800064c2:	00008797          	auipc	a5,0x8
    800064c6:	3d67b783          	ld	a5,982(a5) # 8000e898 <tx_desc>
    800064ca:	97ba                	add	a5,a5,a4
    800064cc:	0007b023          	sd	zero,0(a5)
  tx_free[i] = 1;
    800064d0:	00008797          	auipc	a5,0x8
    800064d4:	3a078793          	addi	a5,a5,928 # 8000e870 <tx_free>
    800064d8:	97aa                	add	a5,a5,a0
    800064da:	4705                	li	a4,1
    800064dc:	00e78023          	sb	a4,0(a5)
}
    800064e0:	60a2                	ld	ra,8(sp)
    800064e2:	6402                	ld	s0,0(sp)
    800064e4:	0141                	addi	sp,sp,16
    800064e6:	8082                	ret
  if(i >= NUM) panic("free_tx_desc");
    800064e8:	00004517          	auipc	a0,0x4
    800064ec:	3a850513          	addi	a0,a0,936 # 8000a890 <etext+0x890>
    800064f0:	af0fa0ef          	jal	800007e0 <panic>
  if(tx_free[i]) panic("free_tx_desc");
    800064f4:	00004517          	auipc	a0,0x4
    800064f8:	39c50513          	addi	a0,a0,924 # 8000a890 <etext+0x890>
    800064fc:	ae4fa0ef          	jal	800007e0 <panic>

0000000080006500 <virtio_net_init>:
{
    80006500:	7179                	addi	sp,sp,-48
    80006502:	f406                	sd	ra,40(sp)
    80006504:	f022                	sd	s0,32(sp)
    80006506:	1800                	addi	s0,sp,48
  initlock(&vnet_lock, "virtio_net");
    80006508:	00004597          	auipc	a1,0x4
    8000650c:	39858593          	addi	a1,a1,920 # 8000a8a0 <etext+0x8a0>
    80006510:	00022517          	auipc	a0,0x22
    80006514:	06850513          	addi	a0,a0,104 # 80028578 <vnet_lock>
    80006518:	e36fa0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000651c:	100087b7          	lui	a5,0x10008
    80006520:	4398                	lw	a4,0(a5)
    80006522:	2701                	sext.w	a4,a4
    80006524:	747277b7          	lui	a5,0x74727
    80006528:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000652c:	02f71463          	bne	a4,a5,80006554 <virtio_net_init+0x54>
     *R(VIRTIO_MMIO_DEVICE_ID) != 1 ||
    80006530:	100087b7          	lui	a5,0x10008
    80006534:	07a1                	addi	a5,a5,8 # 10008008 <_entry-0x6fff7ff8>
    80006536:	439c                	lw	a5,0(a5)
    80006538:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000653a:	4705                	li	a4,1
    8000653c:	00e79c63          	bne	a5,a4,80006554 <virtio_net_init+0x54>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006540:	100087b7          	lui	a5,0x10008
    80006544:	47d8                	lw	a4,12(a5)
    80006546:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 1 ||
    80006548:	554d47b7          	lui	a5,0x554d4
    8000654c:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006550:	00f70e63          	beq	a4,a5,8000656c <virtio_net_init+0x6c>
    printf("virtio_net: Device not found at 0x%lx\n", (uint64)VIRTIO_NET_BASE);
    80006554:	100085b7          	lui	a1,0x10008
    80006558:	00004517          	auipc	a0,0x4
    8000655c:	35850513          	addi	a0,a0,856 # 8000a8b0 <etext+0x8b0>
    80006560:	f9bf90ef          	jal	800004fa <printf>
}
    80006564:	70a2                	ld	ra,40(sp)
    80006566:	7402                	ld	s0,32(sp)
    80006568:	6145                	addi	sp,sp,48
    8000656a:	8082                	ret
    8000656c:	ec26                	sd	s1,24(sp)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000656e:	100087b7          	lui	a5,0x10008
    80006572:	0607a823          	sw	zero,112(a5) # 10008070 <_entry-0x6fff7f90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006576:	4585                	li	a1,1
    80006578:	dbac                	sw	a1,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000657a:	470d                	li	a4,3
    8000657c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_DEVICE_FEATURES_SEL) = 0;
    8000657e:	100086b7          	lui	a3,0x10008
    80006582:	0006aa23          	sw	zero,20(a3) # 10008014 <_entry-0x6fff7fec>
  features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006586:	10008737          	lui	a4,0x10008
    8000658a:	4b08                	lw	a0,16(a4)
  *R(VIRTIO_MMIO_DEVICE_FEATURES_SEL) = 1;
    8000658c:	cacc                	sw	a1,20(a3)
  features |= ((uint64)(*R(VIRTIO_MMIO_DEVICE_FEATURES)) << 32);
    8000658e:	4b10                	lw	a2,16(a4)
  *R(VIRTIO_MMIO_DRIVER_FEATURES_SEL) = 0;
    80006590:	100086b7          	lui	a3,0x10008
    80006594:	0206a223          	sw	zero,36(a3) # 10008024 <_entry-0x6fff7fdc>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = (uint32)features;
    80006598:	10008737          	lui	a4,0x10008
    8000659c:	d308                	sw	a0,32(a4)
  *R(VIRTIO_MMIO_DRIVER_FEATURES_SEL) = 1;
    8000659e:	d2cc                	sw	a1,36(a3)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = (uint32)(features >> 32);
    800065a0:	d310                	sw	a2,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065a2:	472d                	li	a4,11
    800065a4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065a6:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800065aa:	439c                	lw	a5,0(a5)
    800065ac:	0007849b          	sext.w	s1,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK)){
    800065b0:	8ba1                	andi	a5,a5,8
    800065b2:	26078563          	beqz	a5,8000681c <virtio_net_init+0x31c>
    800065b6:	e84a                	sd	s2,16(sp)
    800065b8:	e44e                	sd	s3,8(sp)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065ba:	100087b7          	lui	a5,0x10008
    800065be:	0207a823          	sw	zero,48(a5) # 10008030 <_entry-0x6fff7fd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800065c2:	100087b7          	lui	a5,0x10008
    800065c6:	04478793          	addi	a5,a5,68 # 10008044 <_entry-0x6fff7fbc>
    800065ca:	439c                	lw	a5,0(a5)
    800065cc:	2781                	sext.w	a5,a5
    800065ce:	24079f63          	bnez	a5,8000682c <virtio_net_init+0x32c>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065d2:	100087b7          	lui	a5,0x10008
    800065d6:	03478793          	addi	a5,a5,52 # 10008034 <_entry-0x6fff7fcc>
    800065da:	439c                	lw	a5,0(a5)
    800065dc:	2781                	sext.w	a5,a5
  if(max == 0) panic("virtio net has no queue 0");
    800065de:	24078d63          	beqz	a5,80006838 <virtio_net_init+0x338>
  if(max < NUM) panic("virtio net max queue too short");
    800065e2:	471d                	li	a4,7
    800065e4:	26f77063          	bgeu	a4,a5,80006844 <virtio_net_init+0x344>
  rx_desc = kalloc();
    800065e8:	d16fa0ef          	jal	80000afe <kalloc>
    800065ec:	00008917          	auipc	s2,0x8
    800065f0:	2c490913          	addi	s2,s2,708 # 8000e8b0 <rx_desc>
    800065f4:	00a93023          	sd	a0,0(s2)
  rx_avail = kalloc();
    800065f8:	d06fa0ef          	jal	80000afe <kalloc>
    800065fc:	00008797          	auipc	a5,0x8
    80006600:	2aa7b623          	sd	a0,684(a5) # 8000e8a8 <rx_avail>
  rx_used = kalloc();
    80006604:	cfafa0ef          	jal	80000afe <kalloc>
    80006608:	87aa                	mv	a5,a0
    8000660a:	00008717          	auipc	a4,0x8
    8000660e:	28a73b23          	sd	a0,662(a4) # 8000e8a0 <rx_used>
  if(!rx_desc || !rx_avail || !rx_used)
    80006612:	00093503          	ld	a0,0(s2)
    80006616:	22050d63          	beqz	a0,80006850 <virtio_net_init+0x350>
    8000661a:	00008717          	auipc	a4,0x8
    8000661e:	28e73703          	ld	a4,654(a4) # 8000e8a8 <rx_avail>
    80006622:	22070763          	beqz	a4,80006850 <virtio_net_init+0x350>
    80006626:	22078563          	beqz	a5,80006850 <virtio_net_init+0x350>
  memset(rx_desc, 0, PGSIZE);
    8000662a:	6605                	lui	a2,0x1
    8000662c:	4581                	li	a1,0
    8000662e:	e74fa0ef          	jal	80000ca2 <memset>
  memset(rx_avail, 0, PGSIZE);
    80006632:	00008997          	auipc	s3,0x8
    80006636:	27698993          	addi	s3,s3,630 # 8000e8a8 <rx_avail>
    8000663a:	6605                	lui	a2,0x1
    8000663c:	4581                	li	a1,0
    8000663e:	0009b503          	ld	a0,0(s3)
    80006642:	e60fa0ef          	jal	80000ca2 <memset>
  memset(rx_used, 0, PGSIZE);
    80006646:	00008917          	auipc	s2,0x8
    8000664a:	25a90913          	addi	s2,s2,602 # 8000e8a0 <rx_used>
    8000664e:	6605                	lui	a2,0x1
    80006650:	4581                	li	a1,0
    80006652:	00093503          	ld	a0,0(s2)
    80006656:	e4cfa0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000665a:	100087b7          	lui	a5,0x10008
    8000665e:	4721                	li	a4,8
    80006660:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)rx_desc;
    80006662:	00008717          	auipc	a4,0x8
    80006666:	24e70713          	addi	a4,a4,590 # 8000e8b0 <rx_desc>
    8000666a:	4314                	lw	a3,0(a4)
    8000666c:	100087b7          	lui	a5,0x10008
    80006670:	08d7a023          	sw	a3,128(a5) # 10008080 <_entry-0x6fff7f80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)rx_desc >> 32;
    80006674:	4358                	lw	a4,4(a4)
    80006676:	100087b7          	lui	a5,0x10008
    8000667a:	08e7a223          	sw	a4,132(a5) # 10008084 <_entry-0x6fff7f7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)rx_avail;
    8000667e:	0009a703          	lw	a4,0(s3)
    80006682:	100087b7          	lui	a5,0x10008
    80006686:	08e7a823          	sw	a4,144(a5) # 10008090 <_entry-0x6fff7f70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)rx_avail >> 32;
    8000668a:	0049a703          	lw	a4,4(s3)
    8000668e:	100087b7          	lui	a5,0x10008
    80006692:	08e7aa23          	sw	a4,148(a5) # 10008094 <_entry-0x6fff7f6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)rx_used;
    80006696:	00092703          	lw	a4,0(s2)
    8000669a:	100087b7          	lui	a5,0x10008
    8000669e:	0ae7a023          	sw	a4,160(a5) # 100080a0 <_entry-0x6fff7f60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)rx_used >> 32;
    800066a2:	00492703          	lw	a4,4(s2)
    800066a6:	100087b7          	lui	a5,0x10008
    800066aa:	0ae7a223          	sw	a4,164(a5) # 100080a4 <_entry-0x6fff7f5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066ae:	10008737          	lui	a4,0x10008
    800066b2:	4785                	li	a5,1
    800066b4:	c37c                	sw	a5,68(a4)
  for(int i = 0; i < NUM; i++) rx_free[i] = 1;
    800066b6:	00008717          	auipc	a4,0x8
    800066ba:	1ca70713          	addi	a4,a4,458 # 8000e880 <rx_free>
    800066be:	00f70023          	sb	a5,0(a4)
    800066c2:	00f700a3          	sb	a5,1(a4)
    800066c6:	00f70123          	sb	a5,2(a4)
    800066ca:	00f701a3          	sb	a5,3(a4)
    800066ce:	00f70223          	sb	a5,4(a4)
    800066d2:	00f702a3          	sb	a5,5(a4)
    800066d6:	00f70323          	sb	a5,6(a4)
    800066da:	00f703a3          	sb	a5,7(a4)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 1;
    800066de:	10008737          	lui	a4,0x10008
    800066e2:	db1c                	sw	a5,48(a4)
  tx_desc = kalloc();
    800066e4:	c1afa0ef          	jal	80000afe <kalloc>
    800066e8:	00008917          	auipc	s2,0x8
    800066ec:	1b090913          	addi	s2,s2,432 # 8000e898 <tx_desc>
    800066f0:	00a93023          	sd	a0,0(s2)
  tx_avail = kalloc();
    800066f4:	c0afa0ef          	jal	80000afe <kalloc>
    800066f8:	00008797          	auipc	a5,0x8
    800066fc:	18a7bc23          	sd	a0,408(a5) # 8000e890 <tx_avail>
  tx_used = kalloc();
    80006700:	bfefa0ef          	jal	80000afe <kalloc>
    80006704:	87aa                	mv	a5,a0
    80006706:	00008717          	auipc	a4,0x8
    8000670a:	18a73123          	sd	a0,386(a4) # 8000e888 <tx_used>
  if(!tx_desc || !tx_avail || !tx_used)
    8000670e:	00093503          	ld	a0,0(s2)
    80006712:	14050563          	beqz	a0,8000685c <virtio_net_init+0x35c>
    80006716:	00008717          	auipc	a4,0x8
    8000671a:	17a73703          	ld	a4,378(a4) # 8000e890 <tx_avail>
    8000671e:	12070f63          	beqz	a4,8000685c <virtio_net_init+0x35c>
    80006722:	12078d63          	beqz	a5,8000685c <virtio_net_init+0x35c>
  memset(tx_desc, 0, PGSIZE);
    80006726:	6605                	lui	a2,0x1
    80006728:	4581                	li	a1,0
    8000672a:	d78fa0ef          	jal	80000ca2 <memset>
  memset(tx_avail, 0, PGSIZE);
    8000672e:	00008997          	auipc	s3,0x8
    80006732:	16298993          	addi	s3,s3,354 # 8000e890 <tx_avail>
    80006736:	6605                	lui	a2,0x1
    80006738:	4581                	li	a1,0
    8000673a:	0009b503          	ld	a0,0(s3)
    8000673e:	d64fa0ef          	jal	80000ca2 <memset>
  memset(tx_used, 0, PGSIZE);
    80006742:	00008917          	auipc	s2,0x8
    80006746:	14690913          	addi	s2,s2,326 # 8000e888 <tx_used>
    8000674a:	6605                	lui	a2,0x1
    8000674c:	4581                	li	a1,0
    8000674e:	00093503          	ld	a0,0(s2)
    80006752:	d50fa0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006756:	100087b7          	lui	a5,0x10008
    8000675a:	4721                	li	a4,8
    8000675c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)tx_desc;
    8000675e:	00008717          	auipc	a4,0x8
    80006762:	13a70713          	addi	a4,a4,314 # 8000e898 <tx_desc>
    80006766:	4314                	lw	a3,0(a4)
    80006768:	100087b7          	lui	a5,0x10008
    8000676c:	08d7a023          	sw	a3,128(a5) # 10008080 <_entry-0x6fff7f80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)tx_desc >> 32;
    80006770:	4358                	lw	a4,4(a4)
    80006772:	100087b7          	lui	a5,0x10008
    80006776:	08e7a223          	sw	a4,132(a5) # 10008084 <_entry-0x6fff7f7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)tx_avail;
    8000677a:	0009a703          	lw	a4,0(s3)
    8000677e:	100087b7          	lui	a5,0x10008
    80006782:	08e7a823          	sw	a4,144(a5) # 10008090 <_entry-0x6fff7f70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)tx_avail >> 32;
    80006786:	0049a703          	lw	a4,4(s3)
    8000678a:	100087b7          	lui	a5,0x10008
    8000678e:	08e7aa23          	sw	a4,148(a5) # 10008094 <_entry-0x6fff7f6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)tx_used;
    80006792:	00092703          	lw	a4,0(s2)
    80006796:	100087b7          	lui	a5,0x10008
    8000679a:	0ae7a023          	sw	a4,160(a5) # 100080a0 <_entry-0x6fff7f60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)tx_used >> 32;
    8000679e:	00492703          	lw	a4,4(s2)
    800067a2:	100087b7          	lui	a5,0x10008
    800067a6:	0ae7a223          	sw	a4,164(a5) # 100080a4 <_entry-0x6fff7f5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800067aa:	10008737          	lui	a4,0x10008
    800067ae:	4785                	li	a5,1
    800067b0:	c37c                	sw	a5,68(a4)
  for(int i = 0; i < NUM; i++) tx_free[i] = 1;
    800067b2:	00008717          	auipc	a4,0x8
    800067b6:	0be70713          	addi	a4,a4,190 # 8000e870 <tx_free>
    800067ba:	00f70023          	sb	a5,0(a4)
    800067be:	00f700a3          	sb	a5,1(a4)
    800067c2:	00f70123          	sb	a5,2(a4)
    800067c6:	00f701a3          	sb	a5,3(a4)
    800067ca:	00f70223          	sb	a5,4(a4)
    800067ce:	00f702a3          	sb	a5,5(a4)
    800067d2:	00f70323          	sb	a5,6(a4)
    800067d6:	00f703a3          	sb	a5,7(a4)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800067da:	0044e493          	ori	s1,s1,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800067de:	100087b7          	lui	a5,0x10008
    800067e2:	dba4                	sw	s1,112(a5)
  for(int i = 0; i < NUM; i++) {
    800067e4:	00022597          	auipc	a1,0x22
    800067e8:	5ac58593          	addi	a1,a1,1452 # 80028d90 <rx_buf>
    800067ec:	00026e97          	auipc	t4,0x26
    800067f0:	5a4e8e93          	addi	t4,t4,1444 # 8002cd90 <arp_lock>
  for(int i = 0; i < NUM; i++){
    800067f4:	4e01                	li	t3,0
    800067f6:	4621                	li	a2,8
  return -1;
    800067f8:	5f7d                	li	t5,-1
      rx_free[i] = 0;
    800067fa:	00008f97          	auipc	t6,0x8
    800067fe:	086f8f93          	addi	t6,t6,134 # 8000e880 <rx_free>
    rx_desc[idx].addr = (uint64)rx_buf[i];
    80006802:	00008317          	auipc	t1,0x8
    80006806:	0ae30313          	addi	t1,t1,174 # 8000e8b0 <rx_desc>
    rx_desc[idx].len = RX_BUF_SIZE;
    8000680a:	6505                	lui	a0,0x1
    8000680c:	80050513          	addi	a0,a0,-2048 # 800 <_entry-0x7ffff800>
    rx_desc[idx].flags = VRING_DESC_F_WRITE;
    80006810:	4889                	li	a7,2
    rx_avail->ring[rx_avail->idx % NUM] = idx;
    80006812:	00008817          	auipc	a6,0x8
    80006816:	09680813          	addi	a6,a6,150 # 8000e8a8 <rx_avail>
    8000681a:	a859                	j	800068b0 <virtio_net_init+0x3b0>
    printf("virtio_net: FEATURES_OK unset (Negotiation failed)\n");
    8000681c:	00004517          	auipc	a0,0x4
    80006820:	0bc50513          	addi	a0,a0,188 # 8000a8d8 <etext+0x8d8>
    80006824:	cd7f90ef          	jal	800004fa <printf>
    return;
    80006828:	64e2                	ld	s1,24(sp)
    8000682a:	bb2d                	j	80006564 <virtio_net_init+0x64>
    panic("virtio net rx queue ready");
    8000682c:	00004517          	auipc	a0,0x4
    80006830:	0e450513          	addi	a0,a0,228 # 8000a910 <etext+0x910>
    80006834:	fadf90ef          	jal	800007e0 <panic>
  if(max == 0) panic("virtio net has no queue 0");
    80006838:	00004517          	auipc	a0,0x4
    8000683c:	0f850513          	addi	a0,a0,248 # 8000a930 <etext+0x930>
    80006840:	fa1f90ef          	jal	800007e0 <panic>
  if(max < NUM) panic("virtio net max queue too short");
    80006844:	00004517          	auipc	a0,0x4
    80006848:	10c50513          	addi	a0,a0,268 # 8000a950 <etext+0x950>
    8000684c:	f95f90ef          	jal	800007e0 <panic>
    panic("virtio net rx kalloc");
    80006850:	00004517          	auipc	a0,0x4
    80006854:	12050513          	addi	a0,a0,288 # 8000a970 <etext+0x970>
    80006858:	f89f90ef          	jal	800007e0 <panic>
    panic("virtio net tx kalloc");
    8000685c:	00004517          	auipc	a0,0x4
    80006860:	12c50513          	addi	a0,a0,300 # 8000a988 <etext+0x988>
    80006864:	f7df90ef          	jal	800007e0 <panic>
      rx_free[i] = 0;
    80006868:	00ff8733          	add	a4,t6,a5
    8000686c:	00070023          	sb	zero,0(a4)
    rx_desc[idx].addr = (uint64)rx_buf[i];
    80006870:	00479693          	slli	a3,a5,0x4
    80006874:	00033703          	ld	a4,0(t1)
    80006878:	9736                	add	a4,a4,a3
    8000687a:	e30c                	sd	a1,0(a4)
    rx_desc[idx].len = RX_BUF_SIZE;
    8000687c:	c708                	sw	a0,8(a4)
    rx_desc[idx].flags = VRING_DESC_F_WRITE;
    8000687e:	01171623          	sh	a7,12(a4)
    rx_desc[idx].next = 0;
    80006882:	00071723          	sh	zero,14(a4)
    rx_avail->ring[rx_avail->idx % NUM] = idx;
    80006886:	00083683          	ld	a3,0(a6)
    8000688a:	0026d703          	lhu	a4,2(a3)
    8000688e:	8b1d                	andi	a4,a4,7
    80006890:	0706                	slli	a4,a4,0x1
    80006892:	96ba                	add	a3,a3,a4
    80006894:	00f69223          	sh	a5,4(a3)
    __sync_synchronize();
    80006898:	0330000f          	fence	rw,rw
    rx_avail->idx++;
    8000689c:	00083703          	ld	a4,0(a6)
    800068a0:	00275783          	lhu	a5,2(a4)
    800068a4:	2785                	addiw	a5,a5,1 # 10008001 <_entry-0x6fff7fff>
    800068a6:	00f71123          	sh	a5,2(a4)
  for(int i = 0; i < NUM; i++) {
    800068aa:	95aa                	add	a1,a1,a0
    800068ac:	02be8063          	beq	t4,a1,800068cc <virtio_net_init+0x3cc>
  for(int i = 0; i < NUM; i++){
    800068b0:	00008717          	auipc	a4,0x8
    800068b4:	fd070713          	addi	a4,a4,-48 # 8000e880 <rx_free>
    800068b8:	87f2                	mv	a5,t3
    if(rx_free[i]){
    800068ba:	00074683          	lbu	a3,0(a4)
    800068be:	f6cd                	bnez	a3,80006868 <virtio_net_init+0x368>
  for(int i = 0; i < NUM; i++){
    800068c0:	2785                	addiw	a5,a5,1
    800068c2:	0705                	addi	a4,a4,1
    800068c4:	fec79be3          	bne	a5,a2,800068ba <virtio_net_init+0x3ba>
  return -1;
    800068c8:	87fa                	mv	a5,t5
    800068ca:	b75d                	j	80006870 <virtio_net_init+0x370>
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    800068cc:	100087b7          	lui	a5,0x10008
    800068d0:	0407a823          	sw	zero,80(a5) # 10008050 <_entry-0x6fff7fb0>
  printf("virtio_net: initialized\n");
    800068d4:	00004517          	auipc	a0,0x4
    800068d8:	0cc50513          	addi	a0,a0,204 # 8000a9a0 <etext+0x9a0>
    800068dc:	c1ff90ef          	jal	800004fa <printf>
    800068e0:	64e2                	ld	s1,24(sp)
    800068e2:	6942                	ld	s2,16(sp)
    800068e4:	69a2                	ld	s3,8(sp)
    800068e6:	b9bd                	j	80006564 <virtio_net_init+0x64>

00000000800068e8 <virtio_net_send>:

int
virtio_net_send(void *data, int len)
{
    800068e8:	7139                	addi	sp,sp,-64
    800068ea:	fc06                	sd	ra,56(sp)
    800068ec:	f822                	sd	s0,48(sp)
    800068ee:	f426                	sd	s1,40(sp)
    800068f0:	f04a                	sd	s2,32(sp)
    800068f2:	ec4e                	sd	s3,24(sp)
    800068f4:	0080                	addi	s0,sp,64
    800068f6:	89aa                	mv	s3,a0
    800068f8:	892e                	mv	s2,a1
  acquire(&vnet_lock);
    800068fa:	00022517          	auipc	a0,0x22
    800068fe:	c7e50513          	addi	a0,a0,-898 # 80028578 <vnet_lock>
    80006902:	accfa0ef          	jal	80000bce <acquire>
  for(int i = 0; i < NUM; i++){
    80006906:	00008797          	auipc	a5,0x8
    8000690a:	f6a78793          	addi	a5,a5,-150 # 8000e870 <tx_free>
    8000690e:	4481                	li	s1,0
    80006910:	46a1                	li	a3,8
    if(tx_free[i]){
    80006912:	0007c703          	lbu	a4,0(a5)
    80006916:	ef09                	bnez	a4,80006930 <virtio_net_send+0x48>
  for(int i = 0; i < NUM; i++){
    80006918:	2485                	addiw	s1,s1,1
    8000691a:	0785                	addi	a5,a5,1
    8000691c:	fed49be3          	bne	s1,a3,80006912 <virtio_net_send+0x2a>
  int idx = alloc_tx_desc();
  if(idx < 0) {
    release(&vnet_lock);
    80006920:	00022517          	auipc	a0,0x22
    80006924:	c5850513          	addi	a0,a0,-936 # 80028578 <vnet_lock>
    80006928:	b3efa0ef          	jal	80000c66 <release>
    return -1;
    8000692c:	557d                	li	a0,-1
    8000692e:	a0ed                	j	80006a18 <virtio_net_send+0x130>
      tx_free[i] = 0;
    80006930:	00008797          	auipc	a5,0x8
    80006934:	f4078793          	addi	a5,a5,-192 # 8000e870 <tx_free>
    80006938:	97a6                	add	a5,a5,s1
    8000693a:	00078023          	sb	zero,0(a5)
  if(idx < 0) {
    8000693e:	fe04c1e3          	bltz	s1,80006920 <virtio_net_send+0x38>
  }

  struct virtio_net_hdr hdr;
  memset(&hdr, 0, sizeof(hdr));
    80006942:	4631                	li	a2,12
    80006944:	4581                	li	a1,0
    80006946:	fc040513          	addi	a0,s0,-64
    8000694a:	b58fa0ef          	jal	80000ca2 <memset>

  if(sizeof(hdr) + len > TX_BUF_SIZE) {
    8000694e:	00c90713          	addi	a4,s2,12
    80006952:	6785                	lui	a5,0x1
    80006954:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    80006958:	0ce7e763          	bltu	a5,a4,80006a26 <virtio_net_send+0x13e>
    free_tx_desc(idx);
    release(&vnet_lock);
    return -1;
  }

  memmove(tx_buf, &hdr, sizeof(hdr));
    8000695c:	4631                	li	a2,12
    8000695e:	fc040593          	addi	a1,s0,-64
    80006962:	00022517          	auipc	a0,0x22
    80006966:	c2e50513          	addi	a0,a0,-978 # 80028590 <tx_buf>
    8000696a:	b94fa0ef          	jal	80000cfe <memmove>
  memmove(tx_buf + sizeof(hdr), data, len);
    8000696e:	2901                	sext.w	s2,s2
    80006970:	864a                	mv	a2,s2
    80006972:	85ce                	mv	a1,s3
    80006974:	00022517          	auipc	a0,0x22
    80006978:	c2850513          	addi	a0,a0,-984 # 8002859c <tx_buf+0xc>
    8000697c:	b82fa0ef          	jal	80000cfe <memmove>

  tx_desc[idx].addr = (uint64)tx_buf;
    80006980:	00449713          	slli	a4,s1,0x4
    80006984:	00008797          	auipc	a5,0x8
    80006988:	f147b783          	ld	a5,-236(a5) # 8000e898 <tx_desc>
    8000698c:	97ba                	add	a5,a5,a4
    8000698e:	00022717          	auipc	a4,0x22
    80006992:	c0270713          	addi	a4,a4,-1022 # 80028590 <tx_buf>
    80006996:	e398                	sd	a4,0(a5)
  tx_desc[idx].len = sizeof(hdr) + len;
    80006998:	2931                	addiw	s2,s2,12
    8000699a:	0127a423          	sw	s2,8(a5)
  tx_desc[idx].flags = 0;
    8000699e:	00079623          	sh	zero,12(a5)
  tx_desc[idx].next = 0;
    800069a2:	00079723          	sh	zero,14(a5)

  tx_avail->ring[tx_avail->idx % NUM] = idx;
    800069a6:	00008697          	auipc	a3,0x8
    800069aa:	eea68693          	addi	a3,a3,-278 # 8000e890 <tx_avail>
    800069ae:	6298                	ld	a4,0(a3)
    800069b0:	00275783          	lhu	a5,2(a4)
    800069b4:	8b9d                	andi	a5,a5,7
    800069b6:	0786                	slli	a5,a5,0x1
    800069b8:	973e                	add	a4,a4,a5
    800069ba:	00971223          	sh	s1,4(a4)
  __sync_synchronize();
    800069be:	0330000f          	fence	rw,rw
  tx_avail->idx++;
    800069c2:	6298                	ld	a4,0(a3)
    800069c4:	00275783          	lhu	a5,2(a4)
    800069c8:	2785                	addiw	a5,a5,1
    800069ca:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 1;
    800069ce:	100087b7          	lui	a5,0x10008
    800069d2:	4705                	li	a4,1
    800069d4:	cbb8                	sw	a4,80(a5)

  while(tx_used_idx == tx_used->idx);
    800069d6:	00008697          	auipc	a3,0x8
    800069da:	eb26b683          	ld	a3,-334(a3) # 8000e888 <tx_used>
    800069de:	00008497          	auipc	s1,0x8
    800069e2:	e8a4d483          	lhu	s1,-374(s1) # 8000e868 <tx_used_idx>
    800069e6:	0026d703          	lhu	a4,2(a3)
    800069ea:	0004879b          	sext.w	a5,s1
    800069ee:	00f70063          	beq	a4,a5,800069ee <virtio_net_send+0x106>

  int used_idx = tx_used->ring[tx_used_idx % NUM].id;
    800069f2:	0074f793          	andi	a5,s1,7
    800069f6:	078e                	slli	a5,a5,0x3
    800069f8:	96be                	add	a3,a3,a5
  free_tx_desc(used_idx);
    800069fa:	42c8                	lw	a0,4(a3)
    800069fc:	aa5ff0ef          	jal	800064a0 <free_tx_desc>
  tx_used_idx++;
    80006a00:	2485                	addiw	s1,s1,1
    80006a02:	00008797          	auipc	a5,0x8
    80006a06:	e6979323          	sh	s1,-410(a5) # 8000e868 <tx_used_idx>

  release(&vnet_lock);
    80006a0a:	00022517          	auipc	a0,0x22
    80006a0e:	b6e50513          	addi	a0,a0,-1170 # 80028578 <vnet_lock>
    80006a12:	a54fa0ef          	jal	80000c66 <release>
  return 0;
    80006a16:	4501                	li	a0,0
}
    80006a18:	70e2                	ld	ra,56(sp)
    80006a1a:	7442                	ld	s0,48(sp)
    80006a1c:	74a2                	ld	s1,40(sp)
    80006a1e:	7902                	ld	s2,32(sp)
    80006a20:	69e2                	ld	s3,24(sp)
    80006a22:	6121                	addi	sp,sp,64
    80006a24:	8082                	ret
    free_tx_desc(idx);
    80006a26:	8526                	mv	a0,s1
    80006a28:	a79ff0ef          	jal	800064a0 <free_tx_desc>
    release(&vnet_lock);
    80006a2c:	00022517          	auipc	a0,0x22
    80006a30:	b4c50513          	addi	a0,a0,-1204 # 80028578 <vnet_lock>
    80006a34:	a32fa0ef          	jal	80000c66 <release>
    return -1;
    80006a38:	557d                	li	a0,-1
    80006a3a:	bff9                	j	80006a18 <virtio_net_send+0x130>

0000000080006a3c <virtio_net_intr>:

void
virtio_net_intr(void)
{
    80006a3c:	711d                	addi	sp,sp,-96
    80006a3e:	ec86                	sd	ra,88(sp)
    80006a40:	e8a2                	sd	s0,80(sp)
    80006a42:	1080                	addi	s0,sp,96
  acquire(&vnet_lock);
    80006a44:	00022517          	auipc	a0,0x22
    80006a48:	b3450513          	addi	a0,a0,-1228 # 80028578 <vnet_lock>
    80006a4c:	982fa0ef          	jal	80000bce <acquire>
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a50:	100087b7          	lui	a5,0x10008
    80006a54:	53b8                	lw	a4,96(a5)
    80006a56:	8b0d                	andi	a4,a4,3
    80006a58:	100087b7          	lui	a5,0x10008
    80006a5c:	d3f8                	sw	a4,100(a5)

  while(rx_used_idx != rx_used->idx) {
    80006a5e:	00008717          	auipc	a4,0x8
    80006a62:	e4273703          	ld	a4,-446(a4) # 8000e8a0 <rx_used>
    80006a66:	00008797          	auipc	a5,0x8
    80006a6a:	e127d783          	lhu	a5,-494(a5) # 8000e878 <rx_used_idx>
    80006a6e:	00275683          	lhu	a3,2(a4)
    80006a72:	0cf68e63          	beq	a3,a5,80006b4e <virtio_net_intr+0x112>
    80006a76:	e4a6                	sd	s1,72(sp)
    80006a78:	e0ca                	sd	s2,64(sp)
    80006a7a:	fc4e                	sd	s3,56(sp)
    80006a7c:	f852                	sd	s4,48(sp)
    80006a7e:	f456                	sd	s5,40(sp)
    80006a80:	f05a                	sd	s6,32(sp)
    80006a82:	ec5e                	sd	s7,24(sp)
    80006a84:	e862                	sd	s8,16(sp)
    80006a86:	e466                	sd	s9,8(sp)
    80006a88:	e06a                	sd	s10,0(sp)
    int id = rx_used->ring[rx_used_idx % NUM].id;
    int len = rx_used->ring[rx_used_idx % NUM].len;

    if(len > sizeof(struct virtio_net_hdr)) {
    80006a8a:	4c31                	li	s8,12
      char *pkt = rx_buf[id] + sizeof(struct virtio_net_hdr);
    80006a8c:	00022997          	auipc	s3,0x22
    80006a90:	30498993          	addi	s3,s3,772 # 80028d90 <rx_buf>
      int pkt_len = len - sizeof(struct virtio_net_hdr);
      net_recv(pkt, pkt_len);
    }

    rx_desc[id].addr = (uint64)rx_buf[id];
    80006a94:	00008b97          	auipc	s7,0x8
    80006a98:	e1cb8b93          	addi	s7,s7,-484 # 8000e8b0 <rx_desc>
    rx_desc[id].len = RX_BUF_SIZE;
    80006a9c:	6a05                	lui	s4,0x1
    80006a9e:	800a0a13          	addi	s4,s4,-2048 # 800 <_entry-0x7ffff800>
    rx_desc[id].flags = VRING_DESC_F_WRITE;
    80006aa2:	4b09                	li	s6,2
    rx_avail->ring[rx_avail->idx % NUM] = id;
    80006aa4:	00008917          	auipc	s2,0x8
    80006aa8:	e0490913          	addi	s2,s2,-508 # 8000e8a8 <rx_avail>
    __sync_synchronize();
    rx_avail->idx++;
    rx_used_idx++;
    80006aac:	00008497          	auipc	s1,0x8
    80006ab0:	dcc48493          	addi	s1,s1,-564 # 8000e878 <rx_used_idx>
  while(rx_used_idx != rx_used->idx) {
    80006ab4:	00008a97          	auipc	s5,0x8
    80006ab8:	deca8a93          	addi	s5,s5,-532 # 8000e8a0 <rx_used>
    80006abc:	a8a9                	j	80006b16 <virtio_net_intr+0xda>
    rx_desc[id].addr = (uint64)rx_buf[id];
    80006abe:	004c9713          	slli	a4,s9,0x4
    80006ac2:	000bb783          	ld	a5,0(s7)
    80006ac6:	97ba                	add	a5,a5,a4
    80006ac8:	0cae                	slli	s9,s9,0xb
    80006aca:	9cce                	add	s9,s9,s3
    80006acc:	0197b023          	sd	s9,0(a5)
    rx_desc[id].len = RX_BUF_SIZE;
    80006ad0:	0147a423          	sw	s4,8(a5)
    rx_desc[id].flags = VRING_DESC_F_WRITE;
    80006ad4:	01679623          	sh	s6,12(a5)
    rx_avail->ring[rx_avail->idx % NUM] = id;
    80006ad8:	00093703          	ld	a4,0(s2)
    80006adc:	00275783          	lhu	a5,2(a4)
    80006ae0:	8b9d                	andi	a5,a5,7
    80006ae2:	0786                	slli	a5,a5,0x1
    80006ae4:	973e                	add	a4,a4,a5
    80006ae6:	01a71223          	sh	s10,4(a4)
    __sync_synchronize();
    80006aea:	0330000f          	fence	rw,rw
    rx_avail->idx++;
    80006aee:	00093703          	ld	a4,0(s2)
    80006af2:	00275783          	lhu	a5,2(a4)
    80006af6:	2785                	addiw	a5,a5,1
    80006af8:	00f71123          	sh	a5,2(a4)
    rx_used_idx++;
    80006afc:	0004d783          	lhu	a5,0(s1)
    80006b00:	2785                	addiw	a5,a5,1
    80006b02:	17c2                	slli	a5,a5,0x30
    80006b04:	93c1                	srli	a5,a5,0x30
    80006b06:	00f49023          	sh	a5,0(s1)
  while(rx_used_idx != rx_used->idx) {
    80006b0a:	000ab703          	ld	a4,0(s5)
    80006b0e:	00275683          	lhu	a3,2(a4)
    80006b12:	02f68463          	beq	a3,a5,80006b3a <virtio_net_intr+0xfe>
    int id = rx_used->ring[rx_used_idx % NUM].id;
    80006b16:	8b9d                	andi	a5,a5,7
    80006b18:	078e                	slli	a5,a5,0x3
    80006b1a:	973e                	add	a4,a4,a5
    80006b1c:	00472d03          	lw	s10,4(a4)
    80006b20:	000d0c9b          	sext.w	s9,s10
    int len = rx_used->ring[rx_used_idx % NUM].len;
    80006b24:	470c                	lw	a1,8(a4)
    if(len > sizeof(struct virtio_net_hdr)) {
    80006b26:	f8bc7ce3          	bgeu	s8,a1,80006abe <virtio_net_intr+0x82>
      char *pkt = rx_buf[id] + sizeof(struct virtio_net_hdr);
    80006b2a:	00bc9513          	slli	a0,s9,0xb
    80006b2e:	0531                	addi	a0,a0,12
      net_recv(pkt, pkt_len);
    80006b30:	35d1                	addiw	a1,a1,-12
    80006b32:	954e                	add	a0,a0,s3
    80006b34:	116000ef          	jal	80006c4a <net_recv>
    80006b38:	b759                	j	80006abe <virtio_net_intr+0x82>
    80006b3a:	64a6                	ld	s1,72(sp)
    80006b3c:	6906                	ld	s2,64(sp)
    80006b3e:	79e2                	ld	s3,56(sp)
    80006b40:	7a42                	ld	s4,48(sp)
    80006b42:	7aa2                	ld	s5,40(sp)
    80006b44:	7b02                	ld	s6,32(sp)
    80006b46:	6be2                	ld	s7,24(sp)
    80006b48:	6c42                	ld	s8,16(sp)
    80006b4a:	6ca2                	ld	s9,8(sp)
    80006b4c:	6d02                	ld	s10,0(sp)
  }
  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006b4e:	100087b7          	lui	a5,0x10008
    80006b52:	0407a823          	sw	zero,80(a5) # 10008050 <_entry-0x6fff7fb0>
  release(&vnet_lock);
    80006b56:	00022517          	auipc	a0,0x22
    80006b5a:	a2250513          	addi	a0,a0,-1502 # 80028578 <vnet_lock>
    80006b5e:	908fa0ef          	jal	80000c66 <release>
}
    80006b62:	60e6                	ld	ra,88(sp)
    80006b64:	6446                	ld	s0,80(sp)
    80006b66:	6125                	addi	sp,sp,96
    80006b68:	8082                	ret

0000000080006b6a <net_send>:

int
net_send(void *data, int len)
{
    80006b6a:	1141                	addi	sp,sp,-16
    80006b6c:	e406                	sd	ra,8(sp)
    80006b6e:	e022                	sd	s0,0(sp)
    80006b70:	0800                	addi	s0,sp,16
  return virtio_net_send(data, len);
    80006b72:	d77ff0ef          	jal	800068e8 <virtio_net_send>
}
    80006b76:	60a2                	ld	ra,8(sp)
    80006b78:	6402                	ld	s0,0(sp)
    80006b7a:	0141                	addi	sp,sp,16
    80006b7c:	8082                	ret

0000000080006b7e <eth_send>:
uchar local_mac[ETH_ADDR_LEN] = {0x52, 0x54, 0x00, 0x12, 0x34, 0x56};

// Send an Ethernet frame
int
eth_send(uchar *dst_mac, ushort type, void *payload, int len)
{
    80006b7e:	7139                	addi	sp,sp,-64
    80006b80:	fc06                	sd	ra,56(sp)
    80006b82:	f822                	sd	s0,48(sp)
    80006b84:	f426                	sd	s1,40(sp)
    80006b86:	f04a                	sd	s2,32(sp)
    80006b88:	ec4e                	sd	s3,24(sp)
    80006b8a:	e852                	sd	s4,16(sp)
    80006b8c:	e456                	sd	s5,8(sp)
    80006b8e:	0080                	addi	s0,sp,64
    80006b90:	8aaa                	mv	s5,a0
    80006b92:	89ae                	mv	s3,a1
    80006b94:	8a32                	mv	s4,a2
    80006b96:	8936                	mv	s2,a3
  uchar *packet = kalloc();  // Max Ethernet frame
    80006b98:	f67f90ef          	jal	80000afe <kalloc>
    80006b9c:	84aa                	mv	s1,a0
  struct eth_hdr *hdr = (struct eth_hdr *)packet;

  if(len > 1514 - sizeof(struct eth_hdr)){
    80006b9e:	2901                	sext.w	s2,s2
    80006ba0:	5dc00793          	li	a5,1500
    80006ba4:	0527ec63          	bltu	a5,s2,80006bfc <eth_send+0x7e>
    kfree(packet);
    return -1;
  }

  // Build Ethernet header
  memmove(hdr->dst, dst_mac, ETH_ADDR_LEN);
    80006ba8:	4619                	li	a2,6
    80006baa:	85d6                	mv	a1,s5
    80006bac:	952fa0ef          	jal	80000cfe <memmove>
  memmove(hdr->src, local_mac, ETH_ADDR_LEN);
    80006bb0:	4619                	li	a2,6
    80006bb2:	00008597          	auipc	a1,0x8
    80006bb6:	ad658593          	addi	a1,a1,-1322 # 8000e688 <local_mac>
    80006bba:	00648513          	addi	a0,s1,6
    80006bbe:	940fa0ef          	jal	80000cfe <memmove>
  hdr->type = htons(type);
    80006bc2:	0089d79b          	srliw	a5,s3,0x8
    80006bc6:	00f48623          	sb	a5,12(s1)
    80006bca:	013486a3          	sb	s3,13(s1)

  // Copy payload
  memmove(packet + sizeof(struct eth_hdr), payload, len);
    80006bce:	864a                	mv	a2,s2
    80006bd0:	85d2                	mv	a1,s4
    80006bd2:	00e48513          	addi	a0,s1,14
    80006bd6:	928fa0ef          	jal	80000cfe <memmove>

  kfree(packet);
    80006bda:	8526                	mv	a0,s1
    80006bdc:	e41f90ef          	jal	80000a1c <kfree>
  // Send via network driver
  return net_send(packet, sizeof(struct eth_hdr) + len);
    80006be0:	00e9059b          	addiw	a1,s2,14
    80006be4:	8526                	mv	a0,s1
    80006be6:	f85ff0ef          	jal	80006b6a <net_send>
}
    80006bea:	70e2                	ld	ra,56(sp)
    80006bec:	7442                	ld	s0,48(sp)
    80006bee:	74a2                	ld	s1,40(sp)
    80006bf0:	7902                	ld	s2,32(sp)
    80006bf2:	69e2                	ld	s3,24(sp)
    80006bf4:	6a42                	ld	s4,16(sp)
    80006bf6:	6aa2                	ld	s5,8(sp)
    80006bf8:	6121                	addi	sp,sp,64
    80006bfa:	8082                	ret
    kfree(packet);
    80006bfc:	e21f90ef          	jal	80000a1c <kfree>
    return -1;
    80006c00:	557d                	li	a0,-1
    80006c02:	b7e5                	j	80006bea <eth_send+0x6c>

0000000080006c04 <eth_recv>:

// Receive and process an Ethernet frame
void
eth_recv(void *packet, int len)
{
  if(len < sizeof(struct eth_hdr))
    80006c04:	4735                	li	a4,13
    80006c06:	04b77163          	bgeu	a4,a1,80006c48 <eth_recv+0x44>
{
    80006c0a:	1141                	addi	sp,sp,-16
    80006c0c:	e406                	sd	ra,8(sp)
    80006c0e:	e022                	sd	s0,0(sp)
    80006c10:	0800                	addi	s0,sp,16
    80006c12:	87aa                	mv	a5,a0
    return;

  struct eth_hdr *hdr = (struct eth_hdr *)packet;
  void *payload = packet + sizeof(struct eth_hdr);
    80006c14:	0539                	addi	a0,a0,14
  int payload_len = len - sizeof(struct eth_hdr);
    80006c16:	35c9                	addiw	a1,a1,-14
  ushort type = ntohs(hdr->type);
    80006c18:	00c7c683          	lbu	a3,12(a5)
    80006c1c:	00d7c783          	lbu	a5,13(a5)
    80006c20:	07a2                	slli	a5,a5,0x8
    80006c22:	00d7e733          	or	a4,a5,a3

  // Dispatch based on EtherType
  switch(type) {
    80006c26:	46a1                	li	a3,8
    80006c28:	00d70d63          	beq	a4,a3,80006c42 <eth_recv+0x3e>
    80006c2c:	2701                	sext.w	a4,a4
    80006c2e:	60800793          	li	a5,1544
    80006c32:	00f71463          	bne	a4,a5,80006c3a <eth_recv+0x36>
    case ETH_TYPE_ARP:
      arp_recv(payload, payload_len);
    80006c36:	294000ef          	jal	80006eca <arp_recv>
      break;
    default:
      // Unknown protocol, drop packet
      break;
  }
}
    80006c3a:	60a2                	ld	ra,8(sp)
    80006c3c:	6402                	ld	s0,0(sp)
    80006c3e:	0141                	addi	sp,sp,16
    80006c40:	8082                	ret
      ip_recv(payload, payload_len);
    80006c42:	6e8000ef          	jal	8000732a <ip_recv>
      break;
    80006c46:	bfd5                	j	80006c3a <eth_recv+0x36>
    80006c48:	8082                	ret

0000000080006c4a <net_recv>:

// Network driver calls this when a packet is received
void
net_recv(void *data, int len)
{
    80006c4a:	1141                	addi	sp,sp,-16
    80006c4c:	e406                	sd	ra,8(sp)
    80006c4e:	e022                	sd	s0,0(sp)
    80006c50:	0800                	addi	s0,sp,16
  eth_recv(data, len);
    80006c52:	fb3ff0ef          	jal	80006c04 <eth_recv>
}
    80006c56:	60a2                	ld	ra,8(sp)
    80006c58:	6402                	ld	s0,0(sp)
    80006c5a:	0141                	addi	sp,sp,16
    80006c5c:	8082                	ret

0000000080006c5e <arp_init>:
static struct arp_entry arp_cache[ARP_CACHE_SIZE];
static struct spinlock arp_lock;

void
arp_init(void)
{
    80006c5e:	1141                	addi	sp,sp,-16
    80006c60:	e406                	sd	ra,8(sp)
    80006c62:	e022                	sd	s0,0(sp)
    80006c64:	0800                	addi	s0,sp,16
  initlock(&arp_lock, "arp");
    80006c66:	00004597          	auipc	a1,0x4
    80006c6a:	d5a58593          	addi	a1,a1,-678 # 8000a9c0 <etext+0x9c0>
    80006c6e:	00026517          	auipc	a0,0x26
    80006c72:	12250513          	addi	a0,a0,290 # 8002cd90 <arp_lock>
    80006c76:	ed9f90ef          	jal	80000b4e <initlock>
  memset(arp_cache, 0, sizeof(arp_cache));
    80006c7a:	10000613          	li	a2,256
    80006c7e:	4581                	li	a1,0
    80006c80:	00026517          	auipc	a0,0x26
    80006c84:	12850513          	addi	a0,a0,296 # 8002cda8 <arp_cache>
    80006c88:	81afa0ef          	jal	80000ca2 <memset>
}
    80006c8c:	60a2                	ld	ra,8(sp)
    80006c8e:	6402                	ld	s0,0(sp)
    80006c90:	0141                	addi	sp,sp,16
    80006c92:	8082                	ret

0000000080006c94 <arp_lookup>:

// Look up MAC address for IP
int
arp_lookup(uint32 ip, uchar *mac)
{
    80006c94:	1101                	addi	sp,sp,-32
    80006c96:	ec06                	sd	ra,24(sp)
    80006c98:	e822                	sd	s0,16(sp)
    80006c9a:	e426                	sd	s1,8(sp)
    80006c9c:	e04a                	sd	s2,0(sp)
    80006c9e:	1000                	addi	s0,sp,32
    80006ca0:	84aa                	mv	s1,a0
    80006ca2:	892e                	mv	s2,a1
  acquire(&arp_lock);
    80006ca4:	00026517          	auipc	a0,0x26
    80006ca8:	0ec50513          	addi	a0,a0,236 # 8002cd90 <arp_lock>
    80006cac:	f23f90ef          	jal	80000bce <acquire>
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    80006cb0:	00026797          	auipc	a5,0x26
    80006cb4:	0f878793          	addi	a5,a5,248 # 8002cda8 <arp_cache>
    80006cb8:	4701                	li	a4,0
    80006cba:	4641                	li	a2,16
    80006cbc:	a029                	j	80006cc6 <arp_lookup+0x32>
    80006cbe:	2705                	addiw	a4,a4,1
    80006cc0:	07c1                	addi	a5,a5,16
    80006cc2:	02c70963          	beq	a4,a2,80006cf4 <arp_lookup+0x60>
    if(arp_cache[i].valid && arp_cache[i].ip == ip) {
    80006cc6:	47d4                	lw	a3,12(a5)
    80006cc8:	dafd                	beqz	a3,80006cbe <arp_lookup+0x2a>
    80006cca:	4394                	lw	a3,0(a5)
    80006ccc:	fe9699e3          	bne	a3,s1,80006cbe <arp_lookup+0x2a>
      memmove(mac, arp_cache[i].mac, ETH_ADDR_LEN);
    80006cd0:	0712                	slli	a4,a4,0x4
    80006cd2:	4619                	li	a2,6
    80006cd4:	00026597          	auipc	a1,0x26
    80006cd8:	0d858593          	addi	a1,a1,216 # 8002cdac <arp_cache+0x4>
    80006cdc:	95ba                	add	a1,a1,a4
    80006cde:	854a                	mv	a0,s2
    80006ce0:	81efa0ef          	jal	80000cfe <memmove>
      release(&arp_lock);
    80006ce4:	00026517          	auipc	a0,0x26
    80006ce8:	0ac50513          	addi	a0,a0,172 # 8002cd90 <arp_lock>
    80006cec:	f7bf90ef          	jal	80000c66 <release>
      return 0;
    80006cf0:	4501                	li	a0,0
    80006cf2:	a801                	j	80006d02 <arp_lookup+0x6e>
    }
  }
  release(&arp_lock);
    80006cf4:	00026517          	auipc	a0,0x26
    80006cf8:	09c50513          	addi	a0,a0,156 # 8002cd90 <arp_lock>
    80006cfc:	f6bf90ef          	jal	80000c66 <release>
  return -1;
    80006d00:	557d                	li	a0,-1
}
    80006d02:	60e2                	ld	ra,24(sp)
    80006d04:	6442                	ld	s0,16(sp)
    80006d06:	64a2                	ld	s1,8(sp)
    80006d08:	6902                	ld	s2,0(sp)
    80006d0a:	6105                	addi	sp,sp,32
    80006d0c:	8082                	ret

0000000080006d0e <arp_add>:

// Add or update ARP cache entry
void
arp_add(uint32 ip, uchar *mac)
{
    80006d0e:	7179                	addi	sp,sp,-48
    80006d10:	f406                	sd	ra,40(sp)
    80006d12:	f022                	sd	s0,32(sp)
    80006d14:	ec26                	sd	s1,24(sp)
    80006d16:	e84a                	sd	s2,16(sp)
    80006d18:	1800                	addi	s0,sp,48
    80006d1a:	892a                	mv	s2,a0
    80006d1c:	84ae                	mv	s1,a1
  acquire(&arp_lock);
    80006d1e:	00026517          	auipc	a0,0x26
    80006d22:	07250513          	addi	a0,a0,114 # 8002cd90 <arp_lock>
    80006d26:	ea9f90ef          	jal	80000bce <acquire>

  // Check if already exists
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    80006d2a:	00026797          	auipc	a5,0x26
    80006d2e:	07e78793          	addi	a5,a5,126 # 8002cda8 <arp_cache>
    80006d32:	4701                	li	a4,0
    80006d34:	4641                	li	a2,16
    80006d36:	a029                	j	80006d40 <arp_add+0x32>
    80006d38:	2705                	addiw	a4,a4,1
    80006d3a:	07c1                	addi	a5,a5,16
    80006d3c:	02c70863          	beq	a4,a2,80006d6c <arp_add+0x5e>
    if(arp_cache[i].valid && arp_cache[i].ip == ip) {
    80006d40:	47d4                	lw	a3,12(a5)
    80006d42:	dafd                	beqz	a3,80006d38 <arp_add+0x2a>
    80006d44:	4394                	lw	a3,0(a5)
    80006d46:	ff2699e3          	bne	a3,s2,80006d38 <arp_add+0x2a>
      memmove(arp_cache[i].mac, mac, ETH_ADDR_LEN);
    80006d4a:	0712                	slli	a4,a4,0x4
    80006d4c:	4619                	li	a2,6
    80006d4e:	85a6                	mv	a1,s1
    80006d50:	00026517          	auipc	a0,0x26
    80006d54:	05c50513          	addi	a0,a0,92 # 8002cdac <arp_cache+0x4>
    80006d58:	953a                	add	a0,a0,a4
    80006d5a:	fa5f90ef          	jal	80000cfe <memmove>
      release(&arp_lock);
    80006d5e:	00026517          	auipc	a0,0x26
    80006d62:	03250513          	addi	a0,a0,50 # 8002cd90 <arp_lock>
    80006d66:	f01f90ef          	jal	80000c66 <release>
      return;
    80006d6a:	a099                	j	80006db0 <arp_add+0xa2>
    80006d6c:	e44e                	sd	s3,8(sp)
    80006d6e:	00026717          	auipc	a4,0x26
    80006d72:	04670713          	addi	a4,a4,70 # 8002cdb4 <arp_cache+0xc>
    }
  }

  // Find free slot
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    80006d76:	4781                	li	a5,0
    80006d78:	4641                	li	a2,16
    if(!arp_cache[i].valid) {
    80006d7a:	4314                	lw	a3,0(a4)
    80006d7c:	c2a1                	beqz	a3,80006dbc <arp_add+0xae>
  for(int i = 0; i < ARP_CACHE_SIZE; i++) {
    80006d7e:	2785                	addiw	a5,a5,1
    80006d80:	0741                	addi	a4,a4,16
    80006d82:	fec79ce3          	bne	a5,a2,80006d7a <arp_add+0x6c>
      return;
    }
  }

  // Cache full, replace first entry
  arp_cache[0].ip = ip;
    80006d86:	00026997          	auipc	s3,0x26
    80006d8a:	00a98993          	addi	s3,s3,10 # 8002cd90 <arp_lock>
    80006d8e:	0129ac23          	sw	s2,24(s3)
  memmove(arp_cache[0].mac, mac, ETH_ADDR_LEN);
    80006d92:	4619                	li	a2,6
    80006d94:	85a6                	mv	a1,s1
    80006d96:	00026517          	auipc	a0,0x26
    80006d9a:	01650513          	addi	a0,a0,22 # 8002cdac <arp_cache+0x4>
    80006d9e:	f61f90ef          	jal	80000cfe <memmove>
  arp_cache[0].valid = 1;
    80006da2:	4785                	li	a5,1
    80006da4:	02f9a223          	sw	a5,36(s3)

  release(&arp_lock);
    80006da8:	854e                	mv	a0,s3
    80006daa:	ebdf90ef          	jal	80000c66 <release>
    80006dae:	69a2                	ld	s3,8(sp)
}
    80006db0:	70a2                	ld	ra,40(sp)
    80006db2:	7402                	ld	s0,32(sp)
    80006db4:	64e2                	ld	s1,24(sp)
    80006db6:	6942                	ld	s2,16(sp)
    80006db8:	6145                	addi	sp,sp,48
    80006dba:	8082                	ret
    80006dbc:	e052                	sd	s4,0(sp)
      arp_cache[i].ip = ip;
    80006dbe:	00026997          	auipc	s3,0x26
    80006dc2:	fd298993          	addi	s3,s3,-46 # 8002cd90 <arp_lock>
    80006dc6:	0792                	slli	a5,a5,0x4
    80006dc8:	00f98a33          	add	s4,s3,a5
    80006dcc:	012a2c23          	sw	s2,24(s4)
      memmove(arp_cache[i].mac, mac, ETH_ADDR_LEN);
    80006dd0:	4619                	li	a2,6
    80006dd2:	85a6                	mv	a1,s1
    80006dd4:	00026517          	auipc	a0,0x26
    80006dd8:	fd850513          	addi	a0,a0,-40 # 8002cdac <arp_cache+0x4>
    80006ddc:	953e                	add	a0,a0,a5
    80006dde:	f21f90ef          	jal	80000cfe <memmove>
      arp_cache[i].valid = 1;
    80006de2:	4785                	li	a5,1
    80006de4:	02fa2223          	sw	a5,36(s4)
      release(&arp_lock);
    80006de8:	854e                	mv	a0,s3
    80006dea:	e7df90ef          	jal	80000c66 <release>
      return;
    80006dee:	69a2                	ld	s3,8(sp)
    80006df0:	6a02                	ld	s4,0(sp)
    80006df2:	bf7d                	j	80006db0 <arp_add+0xa2>

0000000080006df4 <arp_request>:

// Send ARP request
int
arp_request(uint32 ip)
{
    80006df4:	711d                	addi	sp,sp,-96
    80006df6:	ec86                	sd	ra,88(sp)
    80006df8:	e8a2                	sd	s0,80(sp)
    80006dfa:	e4a6                	sd	s1,72(sp)
    80006dfc:	e0ca                	sd	s2,64(sp)
    80006dfe:	fc4e                	sd	s3,56(sp)
    80006e00:	1080                	addi	s0,sp,96
    80006e02:	84aa                	mv	s1,a0
  struct arp_packet req;
  uchar broadcast[ETH_ADDR_LEN] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
    80006e04:	57fd                	li	a5,-1
    80006e06:	faf42423          	sw	a5,-88(s0)
    80006e0a:	faf41623          	sh	a5,-84(s0)

  // Build ARP request
  req.htype = htons(ARP_HW_ETHER);
    80006e0e:	10000793          	li	a5,256
    80006e12:	faf41823          	sh	a5,-80(s0)
  req.ptype = htons(ARP_PROTO_IP);
    80006e16:	4721                	li	a4,8
    80006e18:	fae41923          	sh	a4,-78(s0)
  req.hlen = ETH_ADDR_LEN;
    80006e1c:	4719                	li	a4,6
    80006e1e:	fae40a23          	sb	a4,-76(s0)
  req.plen = 4;
    80006e22:	4711                	li	a4,4
    80006e24:	fae40aa3          	sb	a4,-75(s0)
  req.op = htons(ARP_OP_REQUEST);
    80006e28:	faf41b23          	sh	a5,-74(s0)
  memmove(req.sha, local_mac, ETH_ADDR_LEN);
    80006e2c:	4619                	li	a2,6
    80006e2e:	00008597          	auipc	a1,0x8
    80006e32:	85a58593          	addi	a1,a1,-1958 # 8000e688 <local_mac>
    80006e36:	fb840513          	addi	a0,s0,-72
    80006e3a:	ec5f90ef          	jal	80000cfe <memmove>
  req.spa = htonl(local_ip);
    80006e3e:	00008717          	auipc	a4,0x8
    80006e42:	85e72703          	lw	a4,-1954(a4) # 8000e69c <local_ip>
    80006e46:	0187179b          	slliw	a5,a4,0x18
    80006e4a:	0187569b          	srliw	a3,a4,0x18
    80006e4e:	8fd5                	or	a5,a5,a3
    80006e50:	0087169b          	slliw	a3,a4,0x8
    80006e54:	00ff09b7          	lui	s3,0xff0
    80006e58:	0136f6b3          	and	a3,a3,s3
    80006e5c:	8fd5                	or	a5,a5,a3
    80006e5e:	0087571b          	srliw	a4,a4,0x8
    80006e62:	6941                	lui	s2,0x10
    80006e64:	f0090913          	addi	s2,s2,-256 # ff00 <_entry-0x7fff0100>
    80006e68:	01277733          	and	a4,a4,s2
    80006e6c:	8fd9                	or	a5,a5,a4
    80006e6e:	faf41f23          	sh	a5,-66(s0)
    80006e72:	0107d79b          	srliw	a5,a5,0x10
    80006e76:	fcf41023          	sh	a5,-64(s0)
  memset(req.tha, 0, ETH_ADDR_LEN);
    80006e7a:	4619                	li	a2,6
    80006e7c:	4581                	li	a1,0
    80006e7e:	fc240513          	addi	a0,s0,-62
    80006e82:	e21f90ef          	jal	80000ca2 <memset>
  req.tpa = htonl(ip);
    80006e86:	0184979b          	slliw	a5,s1,0x18
    80006e8a:	0184d71b          	srliw	a4,s1,0x18
    80006e8e:	8fd9                	or	a5,a5,a4
    80006e90:	0084971b          	slliw	a4,s1,0x8
    80006e94:	01377733          	and	a4,a4,s3
    80006e98:	8fd9                	or	a5,a5,a4
    80006e9a:	0084d49b          	srliw	s1,s1,0x8
    80006e9e:	0124f4b3          	and	s1,s1,s2
    80006ea2:	8fc5                	or	a5,a5,s1
    80006ea4:	fcf42423          	sw	a5,-56(s0)

  return eth_send(broadcast, ETH_TYPE_ARP, &req, sizeof(req));
    80006ea8:	46f1                	li	a3,28
    80006eaa:	fb040613          	addi	a2,s0,-80
    80006eae:	6585                	lui	a1,0x1
    80006eb0:	80658593          	addi	a1,a1,-2042 # 806 <_entry-0x7ffff7fa>
    80006eb4:	fa840513          	addi	a0,s0,-88
    80006eb8:	cc7ff0ef          	jal	80006b7e <eth_send>
}
    80006ebc:	60e6                	ld	ra,88(sp)
    80006ebe:	6446                	ld	s0,80(sp)
    80006ec0:	64a6                	ld	s1,72(sp)
    80006ec2:	6906                	ld	s2,64(sp)
    80006ec4:	79e2                	ld	s3,56(sp)
    80006ec6:	6125                	addi	sp,sp,96
    80006ec8:	8082                	ret

0000000080006eca <arp_recv>:

// Process received ARP packet
void
arp_recv(void *data, int len)
{
  if(len < sizeof(struct arp_packet))
    80006eca:	47ed                	li	a5,27
    80006ecc:	1eb7fc63          	bgeu	a5,a1,800070c4 <arp_recv+0x1fa>
{
    80006ed0:	715d                	addi	sp,sp,-80
    80006ed2:	e486                	sd	ra,72(sp)
    80006ed4:	e0a2                	sd	s0,64(sp)
    80006ed6:	fc26                	sd	s1,56(sp)
    80006ed8:	0880                	addi	s0,sp,80
    80006eda:	84aa                	mv	s1,a0
    return;

  struct arp_packet *arp = (struct arp_packet *)data;

  // Validate packet
  if(ntohs(arp->htype) != ARP_HW_ETHER ||
    80006edc:	00054703          	lbu	a4,0(a0)
    80006ee0:	00154783          	lbu	a5,1(a0)
    80006ee4:	07a2                	slli	a5,a5,0x8
    80006ee6:	8fd9                	or	a5,a5,a4
    80006ee8:	0087971b          	slliw	a4,a5,0x8
    80006eec:	0087d79b          	srliw	a5,a5,0x8
    80006ef0:	8fd9                	or	a5,a5,a4
    80006ef2:	0107979b          	slliw	a5,a5,0x10
    80006ef6:	4107d79b          	sraiw	a5,a5,0x10
    80006efa:	4705                	li	a4,1
    80006efc:	02e79e63          	bne	a5,a4,80006f38 <arp_recv+0x6e>
     ntohs(arp->ptype) != ARP_PROTO_IP ||
    80006f00:	00254703          	lbu	a4,2(a0)
    80006f04:	00354783          	lbu	a5,3(a0)
    80006f08:	07a2                	slli	a5,a5,0x8
    80006f0a:	8fd9                	or	a5,a5,a4
    80006f0c:	0087971b          	slliw	a4,a5,0x8
    80006f10:	0087d79b          	srliw	a5,a5,0x8
    80006f14:	8fd9                	or	a5,a5,a4
  if(ntohs(arp->htype) != ARP_HW_ETHER ||
    80006f16:	0107979b          	slliw	a5,a5,0x10
    80006f1a:	4107d79b          	sraiw	a5,a5,0x10
    80006f1e:	8007879b          	addiw	a5,a5,-2048
    80006f22:	eb99                	bnez	a5,80006f38 <arp_recv+0x6e>
     ntohs(arp->ptype) != ARP_PROTO_IP ||
    80006f24:	00454703          	lbu	a4,4(a0)
    80006f28:	4799                	li	a5,6
    80006f2a:	00f71763          	bne	a4,a5,80006f38 <arp_recv+0x6e>
     arp->hlen != ETH_ADDR_LEN ||
    80006f2e:	00554703          	lbu	a4,5(a0)
    80006f32:	4791                	li	a5,4
    80006f34:	00f70763          	beq	a4,a5,80006f42 <arp_recv+0x78>
      eth_send(arp->sha, ETH_TYPE_ARP, &reply, sizeof(reply));
    }
  } else if(op == ARP_OP_REPLY) {
    // ARP reply already added to cache above
  }
}
    80006f38:	60a6                	ld	ra,72(sp)
    80006f3a:	6406                	ld	s0,64(sp)
    80006f3c:	74e2                	ld	s1,56(sp)
    80006f3e:	6161                	addi	sp,sp,80
    80006f40:	8082                	ret
    80006f42:	f84a                	sd	s2,48(sp)
    80006f44:	f44e                	sd	s3,40(sp)
    80006f46:	f052                	sd	s4,32(sp)
  uint32 spa = ntohl(arp->spa);
    80006f48:	00e54703          	lbu	a4,14(a0)
    80006f4c:	00f54783          	lbu	a5,15(a0)
    80006f50:	07a2                	slli	a5,a5,0x8
    80006f52:	8fd9                	or	a5,a5,a4
    80006f54:	01054703          	lbu	a4,16(a0)
    80006f58:	0742                	slli	a4,a4,0x10
    80006f5a:	8f5d                	or	a4,a4,a5
    80006f5c:	01154783          	lbu	a5,17(a0)
    80006f60:	07e2                	slli	a5,a5,0x18
    80006f62:	8fd9                	or	a5,a5,a4
    80006f64:	0007871b          	sext.w	a4,a5
  uint32 tpa = ntohl(arp->tpa);
    80006f68:	01854683          	lbu	a3,24(a0)
    80006f6c:	01954603          	lbu	a2,25(a0)
    80006f70:	0622                	slli	a2,a2,0x8
    80006f72:	8e55                	or	a2,a2,a3
    80006f74:	01a54683          	lbu	a3,26(a0)
    80006f78:	06c2                	slli	a3,a3,0x10
    80006f7a:	8ed1                	or	a3,a3,a2
    80006f7c:	01b54903          	lbu	s2,27(a0)
    80006f80:	0962                	slli	s2,s2,0x18
    80006f82:	00d96933          	or	s2,s2,a3
    80006f86:	2901                	sext.w	s2,s2
  ushort op = ntohs(arp->op);
    80006f88:	00654683          	lbu	a3,6(a0)
    80006f8c:	00754983          	lbu	s3,7(a0)
    80006f90:	09a2                	slli	s3,s3,0x8
    80006f92:	00d9e9b3          	or	s3,s3,a3
  arp_add(spa, arp->sha);
    80006f96:	00850a13          	addi	s4,a0,8
  uint32 spa = ntohl(arp->spa);
    80006f9a:	0187951b          	slliw	a0,a5,0x18
    80006f9e:	0187579b          	srliw	a5,a4,0x18
    80006fa2:	8d5d                	or	a0,a0,a5
    80006fa4:	0087179b          	slliw	a5,a4,0x8
    80006fa8:	00ff06b7          	lui	a3,0xff0
    80006fac:	8ff5                	and	a5,a5,a3
    80006fae:	8d5d                	or	a0,a0,a5
    80006fb0:	0087571b          	srliw	a4,a4,0x8
    80006fb4:	67c1                	lui	a5,0x10
    80006fb6:	f0078793          	addi	a5,a5,-256 # ff00 <_entry-0x7fff0100>
    80006fba:	8f7d                	and	a4,a4,a5
    80006fbc:	8d59                	or	a0,a0,a4
  arp_add(spa, arp->sha);
    80006fbe:	85d2                	mv	a1,s4
    80006fc0:	2501                	sext.w	a0,a0
    80006fc2:	d4dff0ef          	jal	80006d0e <arp_add>
  if(op == ARP_OP_REQUEST) {
    80006fc6:	2981                	sext.w	s3,s3
    80006fc8:	10000793          	li	a5,256
    80006fcc:	00f98663          	beq	s3,a5,80006fd8 <arp_recv+0x10e>
    80006fd0:	7942                	ld	s2,48(sp)
    80006fd2:	79a2                	ld	s3,40(sp)
    80006fd4:	7a02                	ld	s4,32(sp)
    80006fd6:	b78d                	j	80006f38 <arp_recv+0x6e>
  uint32 tpa = ntohl(arp->tpa);
    80006fd8:	0189179b          	slliw	a5,s2,0x18
    80006fdc:	0189571b          	srliw	a4,s2,0x18
    80006fe0:	8fd9                	or	a5,a5,a4
    80006fe2:	0089171b          	slliw	a4,s2,0x8
    80006fe6:	00ff06b7          	lui	a3,0xff0
    80006fea:	8f75                	and	a4,a4,a3
    80006fec:	8f5d                	or	a4,a4,a5
    80006fee:	0089579b          	srliw	a5,s2,0x8
    80006ff2:	66c1                	lui	a3,0x10
    80006ff4:	f0068693          	addi	a3,a3,-256 # ff00 <_entry-0x7fff0100>
    80006ff8:	8ff5                	and	a5,a5,a3
    80006ffa:	8fd9                	or	a5,a5,a4
    if(tpa == local_ip) {
    80006ffc:	00007717          	auipc	a4,0x7
    80007000:	6a072703          	lw	a4,1696(a4) # 8000e69c <local_ip>
    80007004:	2781                	sext.w	a5,a5
    80007006:	00f70663          	beq	a4,a5,80007012 <arp_recv+0x148>
    8000700a:	7942                	ld	s2,48(sp)
    8000700c:	79a2                	ld	s3,40(sp)
    8000700e:	7a02                	ld	s4,32(sp)
    80007010:	b725                	j	80006f38 <arp_recv+0x6e>
      reply.htype = htons(ARP_HW_ETHER);
    80007012:	10000793          	li	a5,256
    80007016:	faf41823          	sh	a5,-80(s0)
      reply.ptype = htons(ARP_PROTO_IP);
    8000701a:	47a1                	li	a5,8
    8000701c:	faf41923          	sh	a5,-78(s0)
      reply.hlen = ETH_ADDR_LEN;
    80007020:	4799                	li	a5,6
    80007022:	faf40a23          	sb	a5,-76(s0)
      reply.plen = 4;
    80007026:	4791                	li	a5,4
    80007028:	faf40aa3          	sb	a5,-75(s0)
      reply.op = htons(ARP_OP_REPLY);
    8000702c:	20000793          	li	a5,512
    80007030:	faf41b23          	sh	a5,-74(s0)
      memmove(reply.sha, local_mac, ETH_ADDR_LEN);
    80007034:	4619                	li	a2,6
    80007036:	00007597          	auipc	a1,0x7
    8000703a:	65258593          	addi	a1,a1,1618 # 8000e688 <local_mac>
    8000703e:	fb840513          	addi	a0,s0,-72
    80007042:	cbdf90ef          	jal	80000cfe <memmove>
      reply.spa = htonl(local_ip);
    80007046:	00007717          	auipc	a4,0x7
    8000704a:	65672703          	lw	a4,1622(a4) # 8000e69c <local_ip>
    8000704e:	0187179b          	slliw	a5,a4,0x18
    80007052:	0187569b          	srliw	a3,a4,0x18
    80007056:	8fd5                	or	a5,a5,a3
    80007058:	0087169b          	slliw	a3,a4,0x8
    8000705c:	00ff0637          	lui	a2,0xff0
    80007060:	8ef1                	and	a3,a3,a2
    80007062:	8fd5                	or	a5,a5,a3
    80007064:	0087571b          	srliw	a4,a4,0x8
    80007068:	66c1                	lui	a3,0x10
    8000706a:	f0068693          	addi	a3,a3,-256 # ff00 <_entry-0x7fff0100>
    8000706e:	8f75                	and	a4,a4,a3
    80007070:	8fd9                	or	a5,a5,a4
    80007072:	faf41f23          	sh	a5,-66(s0)
    80007076:	0107d79b          	srliw	a5,a5,0x10
    8000707a:	fcf41023          	sh	a5,-64(s0)
      memmove(reply.tha, arp->sha, ETH_ADDR_LEN);
    8000707e:	4619                	li	a2,6
    80007080:	85d2                	mv	a1,s4
    80007082:	fc240513          	addi	a0,s0,-62
    80007086:	c79f90ef          	jal	80000cfe <memmove>
      reply.tpa = arp->spa;
    8000708a:	00e4c703          	lbu	a4,14(s1)
    8000708e:	00f4c783          	lbu	a5,15(s1)
    80007092:	07a2                	slli	a5,a5,0x8
    80007094:	8fd9                	or	a5,a5,a4
    80007096:	0104c703          	lbu	a4,16(s1)
    8000709a:	0742                	slli	a4,a4,0x10
    8000709c:	8f5d                	or	a4,a4,a5
    8000709e:	0114c783          	lbu	a5,17(s1)
    800070a2:	07e2                	slli	a5,a5,0x18
    800070a4:	8fd9                	or	a5,a5,a4
    800070a6:	fcf42423          	sw	a5,-56(s0)
      eth_send(arp->sha, ETH_TYPE_ARP, &reply, sizeof(reply));
    800070aa:	46f1                	li	a3,28
    800070ac:	fb040613          	addi	a2,s0,-80
    800070b0:	6585                	lui	a1,0x1
    800070b2:	80658593          	addi	a1,a1,-2042 # 806 <_entry-0x7ffff7fa>
    800070b6:	8552                	mv	a0,s4
    800070b8:	ac7ff0ef          	jal	80006b7e <eth_send>
    800070bc:	7942                	ld	s2,48(sp)
    800070be:	79a2                	ld	s3,40(sp)
    800070c0:	7a02                	ld	s4,32(sp)
    800070c2:	bd9d                	j	80006f38 <arp_recv+0x6e>
    800070c4:	8082                	ret

00000000800070c6 <ip_init>:
static uint16 ip_id = 1;
static struct spinlock ip_lock;

void
ip_init(void)
{
    800070c6:	1141                	addi	sp,sp,-16
    800070c8:	e406                	sd	ra,8(sp)
    800070ca:	e022                	sd	s0,0(sp)
    800070cc:	0800                	addi	s0,sp,16
  initlock(&ip_lock, "ip");
    800070ce:	00004597          	auipc	a1,0x4
    800070d2:	8fa58593          	addi	a1,a1,-1798 # 8000a9c8 <etext+0x9c8>
    800070d6:	00026517          	auipc	a0,0x26
    800070da:	dd250513          	addi	a0,a0,-558 # 8002cea8 <ip_lock>
    800070de:	a71f90ef          	jal	80000b4e <initlock>
}
    800070e2:	60a2                	ld	ra,8(sp)
    800070e4:	6402                	ld	s0,0(sp)
    800070e6:	0141                	addi	sp,sp,16
    800070e8:	8082                	ret

00000000800070ea <ip_checksum>:

// Calculate IP checksum
ushort
ip_checksum(void *data, int len)
{
    800070ea:	1141                	addi	sp,sp,-16
    800070ec:	e422                	sd	s0,8(sp)
    800070ee:	0800                	addi	s0,sp,16
  ushort *p = (ushort *)data;
  uint32 sum = 0;

  for(int i = 0; i < len / 2; i++)
    800070f0:	01f5d89b          	srliw	a7,a1,0x1f
    800070f4:	00b888bb          	addw	a7,a7,a1
    800070f8:	4785                	li	a5,1
    800070fa:	06b7d563          	bge	a5,a1,80007164 <ip_checksum+0x7a>
    800070fe:	4018d89b          	sraiw	a7,a7,0x1
    80007102:	862a                	mv	a2,a0
    80007104:	4681                	li	a3,0
  uint32 sum = 0;
    80007106:	4701                	li	a4,0
    sum += ntohs(p[i]);
    80007108:	00065783          	lhu	a5,0(a2) # ff0000 <_entry-0x7f010000>
    8000710c:	0087981b          	slliw	a6,a5,0x8
    80007110:	83a1                	srli	a5,a5,0x8
    80007112:	0107e7b3          	or	a5,a5,a6
    80007116:	0107979b          	slliw	a5,a5,0x10
    8000711a:	0107d79b          	srliw	a5,a5,0x10
    8000711e:	9f3d                	addw	a4,a4,a5
  for(int i = 0; i < len / 2; i++)
    80007120:	2685                	addiw	a3,a3,1
    80007122:	0609                	addi	a2,a2,2
    80007124:	ff16c2e3          	blt	a3,a7,80007108 <ip_checksum+0x1e>

  if(len & 1)
    80007128:	0015f793          	andi	a5,a1,1
    8000712c:	c799                	beqz	a5,8000713a <ip_checksum+0x50>
    sum += ((uchar *)data)[len - 1] << 8;
    8000712e:	952e                	add	a0,a0,a1
    80007130:	fff54783          	lbu	a5,-1(a0)
    80007134:	0087979b          	slliw	a5,a5,0x8
    80007138:	9f3d                	addw	a4,a4,a5

  while(sum >> 16)
    8000713a:	0107579b          	srliw	a5,a4,0x10
    8000713e:	cb91                	beqz	a5,80007152 <ip_checksum+0x68>
    sum = (sum & 0xFFFF) + (sum >> 16);
    80007140:	66c1                	lui	a3,0x10
    80007142:	16fd                	addi	a3,a3,-1 # ffff <_entry-0x7fff0001>
    80007144:	8f75                	and	a4,a4,a3
    80007146:	9fb9                	addw	a5,a5,a4
    80007148:	0007871b          	sext.w	a4,a5
  while(sum >> 16)
    8000714c:	0107d79b          	srliw	a5,a5,0x10
    80007150:	fbf5                	bnez	a5,80007144 <ip_checksum+0x5a>

  return ~sum;
    80007152:	fff74513          	not	a0,a4
    80007156:	1542                	slli	a0,a0,0x30
    80007158:	9141                	srli	a0,a0,0x30
}
    8000715a:	6422                	ld	s0,8(sp)
    8000715c:	0141                	addi	sp,sp,16
    8000715e:	8082                	ret
  uint32 sum = 0;
    80007160:	4701                	li	a4,0
    80007162:	b7f1                	j	8000712e <ip_checksum+0x44>
  if(len & 1)
    80007164:	0015f793          	andi	a5,a1,1
    80007168:	ffe5                	bnez	a5,80007160 <ip_checksum+0x76>
  uint32 sum = 0;
    8000716a:	4701                	li	a4,0
    8000716c:	b7dd                	j	80007152 <ip_checksum+0x68>

000000008000716e <ip_send>:

// Send an IP packet
int
ip_send(uint32 dst_ip, uchar proto, void *data, int len)
{
    8000716e:	711d                	addi	sp,sp,-96
    80007170:	ec86                	sd	ra,88(sp)
    80007172:	e8a2                	sd	s0,80(sp)
    80007174:	e4a6                	sd	s1,72(sp)
    80007176:	e0ca                	sd	s2,64(sp)
    80007178:	fc4e                	sd	s3,56(sp)
    8000717a:	f852                	sd	s4,48(sp)
    8000717c:	f456                	sd	s5,40(sp)
    8000717e:	f05a                	sd	s6,32(sp)
    80007180:	1080                	addi	s0,sp,96
    80007182:	892a                	mv	s2,a0
    80007184:	8b2e                	mv	s6,a1
    80007186:	8a32                	mv	s4,a2
    80007188:	89b6                	mv	s3,a3
  uchar *packet = kalloc();
    8000718a:	975f90ef          	jal	80000afe <kalloc>
    8000718e:	84aa                	mv	s1,a0
  struct ip_hdr *hdr = (struct ip_hdr *)packet;
  uchar dst_mac[ETH_ADDR_LEN];
  uint32 next_hop;

  if(len > 1500 - sizeof(struct ip_hdr)){
    80007190:	00098a9b          	sext.w	s5,s3
    80007194:	5c800793          	li	a5,1480
    80007198:	1757ef63          	bltu	a5,s5,80007316 <ip_send+0x1a8>
    8000719c:	ec5e                	sd	s7,24(sp)
    kfree(packet);
    return -1;
  }

  // Determine next hop
  if((dst_ip & netmask) == (local_ip & netmask)) {
    8000719e:	00007797          	auipc	a5,0x7
    800071a2:	4fe7a783          	lw	a5,1278(a5) # 8000e69c <local_ip>
    800071a6:	0127c7b3          	xor	a5,a5,s2
    800071aa:	00007717          	auipc	a4,0x7
    800071ae:	4ea72703          	lw	a4,1258(a4) # 8000e694 <netmask>
    800071b2:	8ff9                	and	a5,a5,a4
    // Same network
    next_hop = dst_ip;
    800071b4:	8bca                	mv	s7,s2
  if((dst_ip & netmask) == (local_ip & netmask)) {
    800071b6:	c789                	beqz	a5,800071c0 <ip_send+0x52>
  } else {
    // Different network, use gateway
    next_hop = gateway_ip;
    800071b8:	00007b97          	auipc	s7,0x7
    800071bc:	4e0bab83          	lw	s7,1248(s7) # 8000e698 <gateway_ip>
  }

  // Resolve MAC address
  if(arp_lookup(next_hop, dst_mac) < 0) {
    800071c0:	fa840593          	addi	a1,s0,-88
    800071c4:	855e                	mv	a0,s7
    800071c6:	acfff0ef          	jal	80006c94 <arp_lookup>
    800071ca:	14054a63          	bltz	a0,8000731e <ip_send+0x1b0>
    // In real implementation, queue packet
    return -1;
  }

  // Build IP header
  hdr->ver_ihl = 0x45;  // IPv4, 20 byte header
    800071ce:	04500793          	li	a5,69
    800071d2:	00f48023          	sb	a5,0(s1)
  hdr->tos = 0;
    800071d6:	000480a3          	sb	zero,1(s1)
  hdr->len = htons(sizeof(struct ip_hdr) + len);
    800071da:	0149879b          	addiw	a5,s3,20 # ff0014 <_entry-0x7f00ffec>
    800071de:	0087979b          	slliw	a5,a5,0x8
    800071e2:	09d1                	addi	s3,s3,20
    800071e4:	0089d993          	srli	s3,s3,0x8
    800071e8:	00f9e7b3          	or	a5,s3,a5
    800071ec:	01348123          	sb	s3,2(s1)
    800071f0:	83a1                	srli	a5,a5,0x8
    800071f2:	00f481a3          	sb	a5,3(s1)

  acquire(&ip_lock);
    800071f6:	00026997          	auipc	s3,0x26
    800071fa:	cb298993          	addi	s3,s3,-846 # 8002cea8 <ip_lock>
    800071fe:	854e                	mv	a0,s3
    80007200:	9cff90ef          	jal	80000bce <acquire>
  hdr->id = htons(ip_id); // Usamos el valor actual
    80007204:	00007717          	auipc	a4,0x7
    80007208:	48c70713          	addi	a4,a4,1164 # 8000e690 <ip_id>
    8000720c:	00075783          	lhu	a5,0(a4)
    80007210:	0087d69b          	srliw	a3,a5,0x8
    80007214:	00d48223          	sb	a3,4(s1)
    80007218:	00f482a3          	sb	a5,5(s1)
  ip_id++;
    8000721c:	2785                	addiw	a5,a5,1
    8000721e:	00f71023          	sh	a5,0(a4)
  release(&ip_lock);
    80007222:	854e                	mv	a0,s3
    80007224:	a43f90ef          	jal	80000c66 <release>

  hdr->flags_offset = 0;
    80007228:	00048323          	sb	zero,6(s1)
    8000722c:	000483a3          	sb	zero,7(s1)
  hdr->ttl = 64;
    80007230:	04000793          	li	a5,64
    80007234:	00f48423          	sb	a5,8(s1)
  hdr->proto = proto;
    80007238:	016484a3          	sb	s6,9(s1)
  hdr->checksum = 0;
    8000723c:	00048523          	sb	zero,10(s1)
    80007240:	000485a3          	sb	zero,11(s1)
  hdr->src = htonl(local_ip);
    80007244:	00007797          	auipc	a5,0x7
    80007248:	4587a783          	lw	a5,1112(a5) # 8000e69c <local_ip>
    8000724c:	0187971b          	slliw	a4,a5,0x18
    80007250:	0187d69b          	srliw	a3,a5,0x18
    80007254:	8f55                	or	a4,a4,a3
    80007256:	0087969b          	slliw	a3,a5,0x8
    8000725a:	00ff0637          	lui	a2,0xff0
    8000725e:	8ef1                	and	a3,a3,a2
    80007260:	8f55                	or	a4,a4,a3
    80007262:	0087d79b          	srliw	a5,a5,0x8
    80007266:	66c1                	lui	a3,0x10
    80007268:	f0068693          	addi	a3,a3,-256 # ff00 <_entry-0x7fff0100>
    8000726c:	8ff5                	and	a5,a5,a3
    8000726e:	00e48623          	sb	a4,12(s1)
    80007272:	83a1                	srli	a5,a5,0x8
    80007274:	00f486a3          	sb	a5,13(s1)
    80007278:	0107579b          	srliw	a5,a4,0x10
    8000727c:	00f48723          	sb	a5,14(s1)
    80007280:	0187571b          	srliw	a4,a4,0x18
    80007284:	00e487a3          	sb	a4,15(s1)
  hdr->dst = htonl(dst_ip);
    80007288:	0189179b          	slliw	a5,s2,0x18
    8000728c:	0189571b          	srliw	a4,s2,0x18
    80007290:	8fd9                	or	a5,a5,a4
    80007292:	0089171b          	slliw	a4,s2,0x8
    80007296:	8f71                	and	a4,a4,a2
    80007298:	8fd9                	or	a5,a5,a4
    8000729a:	0089591b          	srliw	s2,s2,0x8
    8000729e:	00d97933          	and	s2,s2,a3
    800072a2:	00f48823          	sb	a5,16(s1)
    800072a6:	00895913          	srli	s2,s2,0x8
    800072aa:	012488a3          	sb	s2,17(s1)
    800072ae:	0107d71b          	srliw	a4,a5,0x10
    800072b2:	00e48923          	sb	a4,18(s1)
    800072b6:	0187d79b          	srliw	a5,a5,0x18
    800072ba:	00f489a3          	sb	a5,19(s1)

  // Calculate checksum
  hdr->checksum = htons(ip_checksum(hdr, sizeof(struct ip_hdr)));
    800072be:	45d1                	li	a1,20
    800072c0:	8526                	mv	a0,s1
    800072c2:	e29ff0ef          	jal	800070ea <ip_checksum>
    800072c6:	0085179b          	slliw	a5,a0,0x8
    800072ca:	4085551b          	sraiw	a0,a0,0x8
    800072ce:	8fc9                	or	a5,a5,a0
    800072d0:	00a48523          	sb	a0,10(s1)
    800072d4:	83a1                	srli	a5,a5,0x8
    800072d6:	00f485a3          	sb	a5,11(s1)

  // Copy payload
  memmove(packet + sizeof(struct ip_hdr), data, len);
    800072da:	8656                	mv	a2,s5
    800072dc:	85d2                	mv	a1,s4
    800072de:	01448513          	addi	a0,s1,20
    800072e2:	a1df90ef          	jal	80000cfe <memmove>

  kfree(packet);
    800072e6:	8526                	mv	a0,s1
    800072e8:	f34f90ef          	jal	80000a1c <kfree>

  // Send via Ethernet
  return eth_send(dst_mac, ETH_TYPE_IP, packet, sizeof(struct ip_hdr) + len);
    800072ec:	014a869b          	addiw	a3,s5,20
    800072f0:	8626                	mv	a2,s1
    800072f2:	6585                	lui	a1,0x1
    800072f4:	80058593          	addi	a1,a1,-2048 # 800 <_entry-0x7ffff800>
    800072f8:	fa840513          	addi	a0,s0,-88
    800072fc:	883ff0ef          	jal	80006b7e <eth_send>
    80007300:	6be2                	ld	s7,24(sp)
}
    80007302:	60e6                	ld	ra,88(sp)
    80007304:	6446                	ld	s0,80(sp)
    80007306:	64a6                	ld	s1,72(sp)
    80007308:	6906                	ld	s2,64(sp)
    8000730a:	79e2                	ld	s3,56(sp)
    8000730c:	7a42                	ld	s4,48(sp)
    8000730e:	7aa2                	ld	s5,40(sp)
    80007310:	7b02                	ld	s6,32(sp)
    80007312:	6125                	addi	sp,sp,96
    80007314:	8082                	ret
    kfree(packet);
    80007316:	f06f90ef          	jal	80000a1c <kfree>
    return -1;
    8000731a:	557d                	li	a0,-1
    8000731c:	b7dd                	j	80007302 <ip_send+0x194>
    arp_request(next_hop);
    8000731e:	855e                	mv	a0,s7
    80007320:	ad5ff0ef          	jal	80006df4 <arp_request>
    return -1;
    80007324:	557d                	li	a0,-1
    80007326:	6be2                	ld	s7,24(sp)
    80007328:	bfe9                	j	80007302 <ip_send+0x194>

000000008000732a <ip_recv>:

// Receive and process IP packet
void
ip_recv(void *data, int len)
{
  if(len < sizeof(struct ip_hdr))
    8000732a:	47cd                	li	a5,19
    8000732c:	16b7fd63          	bgeu	a5,a1,800074a6 <ip_recv+0x17c>
{
    80007330:	7179                	addi	sp,sp,-48
    80007332:	f406                	sd	ra,40(sp)
    80007334:	f022                	sd	s0,32(sp)
    80007336:	ec26                	sd	s1,24(sp)
    80007338:	1800                	addi	s0,sp,48
    8000733a:	84aa                	mv	s1,a0
    return;

  struct ip_hdr *hdr = (struct ip_hdr *)data;

  // Verify version and header length
  if((hdr->ver_ihl >> 4) != 4)
    8000733c:	00054783          	lbu	a5,0(a0)
    80007340:	0047d693          	srli	a3,a5,0x4
    80007344:	4711                	li	a4,4
    80007346:	14e69363          	bne	a3,a4,8000748c <ip_recv+0x162>
    8000734a:	e84a                	sd	s2,16(sp)
    8000734c:	e052                	sd	s4,0(sp)
    return;

  int hdr_len = (hdr->ver_ihl & 0x0F) * 4;
    8000734e:	8bbd                	andi	a5,a5,15
    80007350:	0027991b          	slliw	s2,a5,0x2
    80007354:	00090a1b          	sext.w	s4,s2
  if(hdr_len < sizeof(struct ip_hdr) || hdr_len > len)
    80007358:	47cd                	li	a5,19
    8000735a:	1347f763          	bgeu	a5,s4,80007488 <ip_recv+0x15e>
    8000735e:	0145d563          	bge	a1,s4,80007368 <ip_recv+0x3e>
    80007362:	6942                	ld	s2,16(sp)
    80007364:	6a02                	ld	s4,0(sp)
    80007366:	a21d                	j	8000748c <ip_recv+0x162>
    80007368:	e44e                	sd	s3,8(sp)
    return;

  // Verify checksum
  ushort saved_checksum = hdr->checksum;
    8000736a:	00a54783          	lbu	a5,10(a0)
    8000736e:	00b54983          	lbu	s3,11(a0)
    80007372:	09a2                	slli	s3,s3,0x8
    80007374:	00f9e9b3          	or	s3,s3,a5
  hdr->checksum = 0;
    80007378:	00050523          	sb	zero,10(a0)
    8000737c:	000505a3          	sb	zero,11(a0)
  if(ip_checksum(hdr, hdr_len) != ntohs(saved_checksum))
    80007380:	85d2                	mv	a1,s4
    80007382:	d69ff0ef          	jal	800070ea <ip_checksum>
    80007386:	0089979b          	slliw	a5,s3,0x8
    8000738a:	0089d71b          	srliw	a4,s3,0x8
    8000738e:	8fd9                	or	a5,a5,a4
    80007390:	2501                	sext.w	a0,a0
    80007392:	17c2                	slli	a5,a5,0x30
    80007394:	93c1                	srli	a5,a5,0x30
    80007396:	10f51063          	bne	a0,a5,80007496 <ip_recv+0x16c>
    return;
  hdr->checksum = saved_checksum;
    8000739a:	01348523          	sb	s3,10(s1)
    8000739e:	0089d993          	srli	s3,s3,0x8
    800073a2:	013485a3          	sb	s3,11(s1)

  // Check if packet is for us
  uint32 dst = ntohl(hdr->dst);
    800073a6:	0104c703          	lbu	a4,16(s1)
    800073aa:	0114c783          	lbu	a5,17(s1)
    800073ae:	07a2                	slli	a5,a5,0x8
    800073b0:	8fd9                	or	a5,a5,a4
    800073b2:	0124c703          	lbu	a4,18(s1)
    800073b6:	0742                	slli	a4,a4,0x10
    800073b8:	8f5d                	or	a4,a4,a5
    800073ba:	0134c783          	lbu	a5,19(s1)
    800073be:	07e2                	slli	a5,a5,0x18
    800073c0:	8fd9                	or	a5,a5,a4
    800073c2:	0007871b          	sext.w	a4,a5
    800073c6:	0187979b          	slliw	a5,a5,0x18
    800073ca:	0187569b          	srliw	a3,a4,0x18
    800073ce:	8fd5                	or	a5,a5,a3
    800073d0:	0087169b          	slliw	a3,a4,0x8
    800073d4:	00ff0637          	lui	a2,0xff0
    800073d8:	8ef1                	and	a3,a3,a2
    800073da:	8fd5                	or	a5,a5,a3
    800073dc:	0087571b          	srliw	a4,a4,0x8
    800073e0:	66c1                	lui	a3,0x10
    800073e2:	f0068693          	addi	a3,a3,-256 # ff00 <_entry-0x7fff0100>
    800073e6:	8f75                	and	a4,a4,a3
    800073e8:	8fd9                	or	a5,a5,a4
    800073ea:	2781                	sext.w	a5,a5
  if(dst != local_ip && dst != 0xFFFFFFFF)  // Not for us and not broadcast
    800073ec:	00007717          	auipc	a4,0x7
    800073f0:	2b072703          	lw	a4,688(a4) # 8000e69c <local_ip>
    800073f4:	00f70563          	beq	a4,a5,800073fe <ip_recv+0xd4>
    800073f8:	577d                	li	a4,-1
    800073fa:	0ae79263          	bne	a5,a4,8000749e <ip_recv+0x174>
  // Extract payload
  void *payload = data + hdr_len;
  int payload_len = ntohs(hdr->len) - hdr_len;

  // Dispatch based on protocol
  switch(hdr->proto) {
    800073fe:	0094c703          	lbu	a4,9(s1)
    80007402:	47c5                	li	a5,17
    80007404:	00f70663          	beq	a4,a5,80007410 <ip_recv+0xe6>
    80007408:	6942                	ld	s2,16(sp)
    8000740a:	69a2                	ld	s3,8(sp)
    8000740c:	6a02                	ld	s4,0(sp)
    8000740e:	a8bd                	j	8000748c <ip_recv+0x162>
    case IP_PROTO_ICMP:
      // ICMP not implemented
      break;
    case IP_PROTO_UDP:
      udp_recv(ntohl(hdr->src), payload, payload_len);
    80007410:	00c4c703          	lbu	a4,12(s1)
    80007414:	00d4c783          	lbu	a5,13(s1)
    80007418:	07a2                	slli	a5,a5,0x8
    8000741a:	8fd9                	or	a5,a5,a4
    8000741c:	00e4c703          	lbu	a4,14(s1)
    80007420:	0742                	slli	a4,a4,0x10
    80007422:	8f5d                	or	a4,a4,a5
    80007424:	00f4c783          	lbu	a5,15(s1)
    80007428:	07e2                	slli	a5,a5,0x18
    8000742a:	8fd9                	or	a5,a5,a4
    8000742c:	0007869b          	sext.w	a3,a5
  int payload_len = ntohs(hdr->len) - hdr_len;
    80007430:	0024c603          	lbu	a2,2(s1)
    80007434:	0034c703          	lbu	a4,3(s1)
    80007438:	0722                	slli	a4,a4,0x8
    8000743a:	8f51                	or	a4,a4,a2
    8000743c:	0087159b          	slliw	a1,a4,0x8
    80007440:	00875613          	srli	a2,a4,0x8
    80007444:	8e4d                	or	a2,a2,a1
    80007446:	0106161b          	slliw	a2,a2,0x10
    8000744a:	0106561b          	srliw	a2,a2,0x10
      udp_recv(ntohl(hdr->src), payload, payload_len);
    8000744e:	0187951b          	slliw	a0,a5,0x18
    80007452:	0186d79b          	srliw	a5,a3,0x18
    80007456:	8d5d                	or	a0,a0,a5
    80007458:	0086979b          	slliw	a5,a3,0x8
    8000745c:	00ff0737          	lui	a4,0xff0
    80007460:	8ff9                	and	a5,a5,a4
    80007462:	8d5d                	or	a0,a0,a5
    80007464:	0086d79b          	srliw	a5,a3,0x8
    80007468:	6741                	lui	a4,0x10
    8000746a:	f0070713          	addi	a4,a4,-256 # ff00 <_entry-0x7fff0100>
    8000746e:	8ff9                	and	a5,a5,a4
    80007470:	8d5d                	or	a0,a0,a5
    80007472:	4126063b          	subw	a2,a2,s2
    80007476:	014485b3          	add	a1,s1,s4
    8000747a:	2501                	sext.w	a0,a0
    8000747c:	1b2000ef          	jal	8000762e <udp_recv>
    80007480:	6942                	ld	s2,16(sp)
    80007482:	69a2                	ld	s3,8(sp)
    80007484:	6a02                	ld	s4,0(sp)
      break;
    80007486:	a019                	j	8000748c <ip_recv+0x162>
    80007488:	6942                	ld	s2,16(sp)
    8000748a:	6a02                	ld	s4,0(sp)
      break;
    default:
      // Unknown protocol
      break;
  }
}
    8000748c:	70a2                	ld	ra,40(sp)
    8000748e:	7402                	ld	s0,32(sp)
    80007490:	64e2                	ld	s1,24(sp)
    80007492:	6145                	addi	sp,sp,48
    80007494:	8082                	ret
    80007496:	6942                	ld	s2,16(sp)
    80007498:	69a2                	ld	s3,8(sp)
    8000749a:	6a02                	ld	s4,0(sp)
    8000749c:	bfc5                	j	8000748c <ip_recv+0x162>
    8000749e:	6942                	ld	s2,16(sp)
    800074a0:	69a2                	ld	s3,8(sp)
    800074a2:	6a02                	ld	s4,0(sp)
    800074a4:	b7e5                	j	8000748c <ip_recv+0x162>
    800074a6:	8082                	ret

00000000800074a8 <udp_init>:
static struct udp_socket udp_sockets[MAX_UDP_SOCKETS];
static struct spinlock udp_lock;

void
udp_init(void)
{
    800074a8:	1141                	addi	sp,sp,-16
    800074aa:	e406                	sd	ra,8(sp)
    800074ac:	e022                	sd	s0,0(sp)
    800074ae:	0800                	addi	s0,sp,16
  initlock(&udp_lock, "udp");
    800074b0:	00003597          	auipc	a1,0x3
    800074b4:	52058593          	addi	a1,a1,1312 # 8000a9d0 <etext+0x9d0>
    800074b8:	00026517          	auipc	a0,0x26
    800074bc:	a0850513          	addi	a0,a0,-1528 # 8002cec0 <udp_lock>
    800074c0:	e8ef90ef          	jal	80000b4e <initlock>
  memset(udp_sockets, 0, sizeof(udp_sockets));
    800074c4:	10000613          	li	a2,256
    800074c8:	4581                	li	a1,0
    800074ca:	00026517          	auipc	a0,0x26
    800074ce:	a0e50513          	addi	a0,a0,-1522 # 8002ced8 <udp_sockets>
    800074d2:	fd0f90ef          	jal	80000ca2 <memset>
}
    800074d6:	60a2                	ld	ra,8(sp)
    800074d8:	6402                	ld	s0,0(sp)
    800074da:	0141                	addi	sp,sp,16
    800074dc:	8082                	ret

00000000800074de <udp_bind>:

// Bind to a UDP port
int
udp_bind(ushort port, void (*handler)(uint32, ushort, void*, int))
{
    800074de:	7179                	addi	sp,sp,-48
    800074e0:	f406                	sd	ra,40(sp)
    800074e2:	f022                	sd	s0,32(sp)
    800074e4:	ec26                	sd	s1,24(sp)
    800074e6:	e84a                	sd	s2,16(sp)
    800074e8:	e44e                	sd	s3,8(sp)
    800074ea:	1800                	addi	s0,sp,48
    800074ec:	892a                	mv	s2,a0
    800074ee:	89ae                	mv	s3,a1
  acquire(&udp_lock);
    800074f0:	00026517          	auipc	a0,0x26
    800074f4:	9d050513          	addi	a0,a0,-1584 # 8002cec0 <udp_lock>
    800074f8:	ed6f90ef          	jal	80000bce <acquire>

  // Check if port already in use
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    800074fc:	00026697          	auipc	a3,0x26
    80007500:	9dc68693          	addi	a3,a3,-1572 # 8002ced8 <udp_sockets>
    80007504:	00026617          	auipc	a2,0x26
    80007508:	ad460613          	addi	a2,a2,-1324 # 8002cfd8 <rpc_lock>
  acquire(&udp_lock);
    8000750c:	87b6                	mv	a5,a3
    if(udp_sockets[i].used && udp_sockets[i].port == port) {
    8000750e:	0009081b          	sext.w	a6,s2
    80007512:	a021                	j	8000751a <udp_bind+0x3c>
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    80007514:	07c1                	addi	a5,a5,16
    80007516:	02c78063          	beq	a5,a2,80007536 <udp_bind+0x58>
    if(udp_sockets[i].used && udp_sockets[i].port == port) {
    8000751a:	4398                	lw	a4,0(a5)
    8000751c:	df65                	beqz	a4,80007514 <udp_bind+0x36>
    8000751e:	0047d703          	lhu	a4,4(a5)
    80007522:	ff0719e3          	bne	a4,a6,80007514 <udp_bind+0x36>
      release(&udp_lock);
    80007526:	00026517          	auipc	a0,0x26
    8000752a:	99a50513          	addi	a0,a0,-1638 # 8002cec0 <udp_lock>
    8000752e:	f38f90ef          	jal	80000c66 <release>
      return -1;
    80007532:	54fd                	li	s1,-1
    80007534:	a005                	j	80007554 <udp_bind+0x76>
    }
  }

  // Find free socket
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    80007536:	4481                	li	s1,0
    80007538:	4741                	li	a4,16
    if(!udp_sockets[i].used) {
    8000753a:	429c                	lw	a5,0(a3)
    8000753c:	c785                	beqz	a5,80007564 <udp_bind+0x86>
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    8000753e:	2485                	addiw	s1,s1,1
    80007540:	06c1                	addi	a3,a3,16
    80007542:	fee49ce3          	bne	s1,a4,8000753a <udp_bind+0x5c>
      release(&udp_lock);
      return i;
    }
  }

  release(&udp_lock);
    80007546:	00026517          	auipc	a0,0x26
    8000754a:	97a50513          	addi	a0,a0,-1670 # 8002cec0 <udp_lock>
    8000754e:	f18f90ef          	jal	80000c66 <release>
  return -1;  // No free sockets
    80007552:	54fd                	li	s1,-1
}
    80007554:	8526                	mv	a0,s1
    80007556:	70a2                	ld	ra,40(sp)
    80007558:	7402                	ld	s0,32(sp)
    8000755a:	64e2                	ld	s1,24(sp)
    8000755c:	6942                	ld	s2,16(sp)
    8000755e:	69a2                	ld	s3,8(sp)
    80007560:	6145                	addi	sp,sp,48
    80007562:	8082                	ret
      udp_sockets[i].used = 1;
    80007564:	00026517          	auipc	a0,0x26
    80007568:	95c50513          	addi	a0,a0,-1700 # 8002cec0 <udp_lock>
    8000756c:	00449793          	slli	a5,s1,0x4
    80007570:	97aa                	add	a5,a5,a0
    80007572:	4705                	li	a4,1
    80007574:	cf98                	sw	a4,24(a5)
      udp_sockets[i].port = port;
    80007576:	01279e23          	sh	s2,28(a5)
      udp_sockets[i].handler = handler;
    8000757a:	0337b023          	sd	s3,32(a5)
      release(&udp_lock);
    8000757e:	ee8f90ef          	jal	80000c66 <release>
      return i;
    80007582:	bfc9                	j	80007554 <udp_bind+0x76>

0000000080007584 <udp_send>:

// Send a UDP packet
int
udp_send(uint32 dst_ip, ushort dst_port, ushort src_port, void *data, int len)
{
    80007584:	715d                	addi	sp,sp,-80
    80007586:	e486                	sd	ra,72(sp)
    80007588:	e0a2                	sd	s0,64(sp)
    8000758a:	fc26                	sd	s1,56(sp)
    8000758c:	f84a                	sd	s2,48(sp)
    8000758e:	f44e                	sd	s3,40(sp)
    80007590:	f052                	sd	s4,32(sp)
    80007592:	ec56                	sd	s5,24(sp)
    80007594:	e85a                	sd	s6,16(sp)
    80007596:	e45e                	sd	s7,8(sp)
    80007598:	0880                	addi	s0,sp,80
    8000759a:	89aa                	mv	s3,a0
    8000759c:	8bae                	mv	s7,a1
    8000759e:	8b32                	mv	s6,a2
    800075a0:	8a36                	mv	s4,a3
    800075a2:	893a                	mv	s2,a4
  uchar *packet = kalloc();
    800075a4:	d5af90ef          	jal	80000afe <kalloc>
    800075a8:	84aa                	mv	s1,a0
  struct udp_hdr *hdr = (struct udp_hdr *)packet;

  if(len > 1500 - sizeof(struct udp_hdr)){
    800075aa:	00090a9b          	sext.w	s5,s2
    800075ae:	5d400793          	li	a5,1492
    800075b2:	0757ea63          	bltu	a5,s5,80007626 <udp_send+0xa2>
    kfree(packet);
    return -1;
  }

  // Build UDP header
  hdr->src_port = htons(src_port);
    800075b6:	008b579b          	srliw	a5,s6,0x8
    800075ba:	00f50023          	sb	a5,0(a0)
    800075be:	016500a3          	sb	s6,1(a0)
  hdr->dst_port = htons(dst_port);
    800075c2:	008bd79b          	srliw	a5,s7,0x8
    800075c6:	00f50123          	sb	a5,2(a0)
    800075ca:	017501a3          	sb	s7,3(a0)
  hdr->len = htons(sizeof(struct udp_hdr) + len);
    800075ce:	0089079b          	addiw	a5,s2,8
    800075d2:	0087979b          	slliw	a5,a5,0x8
    800075d6:	0921                	addi	s2,s2,8
    800075d8:	00895913          	srli	s2,s2,0x8
    800075dc:	00f967b3          	or	a5,s2,a5
    800075e0:	01250223          	sb	s2,4(a0)
    800075e4:	83a1                	srli	a5,a5,0x8
    800075e6:	00f502a3          	sb	a5,5(a0)
  hdr->checksum = 0;  // Optional for IPv4
    800075ea:	00050323          	sb	zero,6(a0)
    800075ee:	000503a3          	sb	zero,7(a0)

  // Copy payload
  memmove(packet + sizeof(struct udp_hdr), data, len);
    800075f2:	8656                	mv	a2,s5
    800075f4:	85d2                	mv	a1,s4
    800075f6:	0521                	addi	a0,a0,8
    800075f8:	f06f90ef          	jal	80000cfe <memmove>

  kfree(packet);
    800075fc:	8526                	mv	a0,s1
    800075fe:	c1ef90ef          	jal	80000a1c <kfree>

  // Send via IP layer
  return ip_send(dst_ip, IP_PROTO_UDP, packet, sizeof(struct udp_hdr) + len);
    80007602:	008a869b          	addiw	a3,s5,8
    80007606:	8626                	mv	a2,s1
    80007608:	45c5                	li	a1,17
    8000760a:	854e                	mv	a0,s3
    8000760c:	b63ff0ef          	jal	8000716e <ip_send>
}
    80007610:	60a6                	ld	ra,72(sp)
    80007612:	6406                	ld	s0,64(sp)
    80007614:	74e2                	ld	s1,56(sp)
    80007616:	7942                	ld	s2,48(sp)
    80007618:	79a2                	ld	s3,40(sp)
    8000761a:	7a02                	ld	s4,32(sp)
    8000761c:	6ae2                	ld	s5,24(sp)
    8000761e:	6b42                	ld	s6,16(sp)
    80007620:	6ba2                	ld	s7,8(sp)
    80007622:	6161                	addi	sp,sp,80
    80007624:	8082                	ret
    kfree(packet);
    80007626:	bf6f90ef          	jal	80000a1c <kfree>
    return -1;
    8000762a:	557d                	li	a0,-1
    8000762c:	b7d5                	j	80007610 <udp_send+0x8c>

000000008000762e <udp_recv>:

// Receive and process UDP packet
void
udp_recv(uint32 src_ip, void *data, int len)
{
  if(len < sizeof(struct udp_hdr))
    8000762e:	479d                	li	a5,7
    80007630:	10c7f863          	bgeu	a5,a2,80007740 <udp_recv+0x112>
{
    80007634:	7139                	addi	sp,sp,-64
    80007636:	fc06                	sd	ra,56(sp)
    80007638:	f822                	sd	s0,48(sp)
    8000763a:	f426                	sd	s1,40(sp)
    8000763c:	ec4e                	sd	s3,24(sp)
    8000763e:	e852                	sd	s4,16(sp)
    80007640:	0080                	addi	s0,sp,64
    80007642:	8a2a                	mv	s4,a0
    80007644:	89ae                	mv	s3,a1
    return;

  struct udp_hdr *hdr = (struct udp_hdr *)data;
  void *payload = data + sizeof(struct udp_hdr);
  int payload_len = ntohs(hdr->len) - sizeof(struct udp_hdr);
    80007646:	0045c683          	lbu	a3,4(a1)
    8000764a:	0055c783          	lbu	a5,5(a1)
    8000764e:	07a2                	slli	a5,a5,0x8
    80007650:	8fd5                	or	a5,a5,a3
    80007652:	0087969b          	slliw	a3,a5,0x8
    80007656:	0087d493          	srli	s1,a5,0x8
    8000765a:	8cd5                	or	s1,s1,a3
    8000765c:	0104949b          	slliw	s1,s1,0x10
    80007660:	0104d49b          	srliw	s1,s1,0x10
    80007664:	34e1                	addiw	s1,s1,-8
  ushort dst_port = ntohs(hdr->dst_port);
  ushort src_port = ntohs(hdr->src_port);

  if(payload_len < 0 || payload_len > len - sizeof(struct udp_hdr))
    80007666:	0004c663          	bltz	s1,80007672 <udp_recv+0x44>
    8000766a:	ff860713          	addi	a4,a2,-8
    8000766e:	00977963          	bgeu	a4,s1,80007680 <udp_recv+0x52>
    }
  }
  release(&udp_lock);

  // No handler for this port, drop packet
}
    80007672:	70e2                	ld	ra,56(sp)
    80007674:	7442                	ld	s0,48(sp)
    80007676:	74a2                	ld	s1,40(sp)
    80007678:	69e2                	ld	s3,24(sp)
    8000767a:	6a42                	ld	s4,16(sp)
    8000767c:	6121                	addi	sp,sp,64
    8000767e:	8082                	ret
    80007680:	f04a                	sd	s2,32(sp)
    80007682:	e456                	sd	s5,8(sp)
    80007684:	e05a                	sd	s6,0(sp)
  ushort dst_port = ntohs(hdr->dst_port);
    80007686:	0025c703          	lbu	a4,2(a1)
    8000768a:	0035c783          	lbu	a5,3(a1)
    8000768e:	07a2                	slli	a5,a5,0x8
    80007690:	8fd9                	or	a5,a5,a4
    80007692:	0087971b          	slliw	a4,a5,0x8
    80007696:	0087d693          	srli	a3,a5,0x8
    8000769a:	8ed9                	or	a3,a3,a4
    8000769c:	03069a93          	slli	s5,a3,0x30
    800076a0:	030ada93          	srli	s5,s5,0x30
  ushort src_port = ntohs(hdr->src_port);
    800076a4:	0005c703          	lbu	a4,0(a1)
    800076a8:	0015c783          	lbu	a5,1(a1)
    800076ac:	07a2                	slli	a5,a5,0x8
    800076ae:	00e7eb33          	or	s6,a5,a4
  acquire(&udp_lock);
    800076b2:	00026517          	auipc	a0,0x26
    800076b6:	80e50513          	addi	a0,a0,-2034 # 8002cec0 <udp_lock>
    800076ba:	d14f90ef          	jal	80000bce <acquire>
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    800076be:	00026797          	auipc	a5,0x26
    800076c2:	81a78793          	addi	a5,a5,-2022 # 8002ced8 <udp_sockets>
    800076c6:	4901                	li	s2,0
    if(udp_sockets[i].used && udp_sockets[i].port == dst_port) {
    800076c8:	000a869b          	sext.w	a3,s5
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    800076cc:	4641                	li	a2,16
    800076ce:	a081                	j	8000770e <udp_recv+0xe0>
        release(&udp_lock);
    800076d0:	00025a97          	auipc	s5,0x25
    800076d4:	7f0a8a93          	addi	s5,s5,2032 # 8002cec0 <udp_lock>
    800076d8:	8556                	mv	a0,s5
    800076da:	d8cf90ef          	jal	80000c66 <release>
  ushort src_port = ntohs(hdr->src_port);
    800076de:	008b159b          	slliw	a1,s6,0x8
    800076e2:	008b579b          	srliw	a5,s6,0x8
    800076e6:	8ddd                	or	a1,a1,a5
        udp_sockets[i].handler(src_ip, src_port, payload, payload_len);
    800076e8:	0912                	slli	s2,s2,0x4
    800076ea:	9aca                	add	s5,s5,s2
    800076ec:	020ab783          	ld	a5,32(s5)
    800076f0:	86a6                	mv	a3,s1
    800076f2:	00898613          	addi	a2,s3,8
    800076f6:	15c2                	slli	a1,a1,0x30
    800076f8:	91c1                	srli	a1,a1,0x30
    800076fa:	8552                	mv	a0,s4
    800076fc:	9782                	jalr	a5
        return;
    800076fe:	7902                	ld	s2,32(sp)
    80007700:	6aa2                	ld	s5,8(sp)
    80007702:	6b02                	ld	s6,0(sp)
    80007704:	b7bd                	j	80007672 <udp_recv+0x44>
  for(int i = 0; i < MAX_UDP_SOCKETS; i++) {
    80007706:	2905                	addiw	s2,s2,1
    80007708:	07c1                	addi	a5,a5,16
    8000770a:	02c90163          	beq	s2,a2,8000772c <udp_recv+0xfe>
    if(udp_sockets[i].used && udp_sockets[i].port == dst_port) {
    8000770e:	4398                	lw	a4,0(a5)
    80007710:	db7d                	beqz	a4,80007706 <udp_recv+0xd8>
    80007712:	0047d703          	lhu	a4,4(a5)
    80007716:	fed718e3          	bne	a4,a3,80007706 <udp_recv+0xd8>
      if(udp_sockets[i].handler) {
    8000771a:	00491713          	slli	a4,s2,0x4
    8000771e:	00025797          	auipc	a5,0x25
    80007722:	7a278793          	addi	a5,a5,1954 # 8002cec0 <udp_lock>
    80007726:	97ba                	add	a5,a5,a4
    80007728:	739c                	ld	a5,32(a5)
    8000772a:	f3dd                	bnez	a5,800076d0 <udp_recv+0xa2>
  release(&udp_lock);
    8000772c:	00025517          	auipc	a0,0x25
    80007730:	79450513          	addi	a0,a0,1940 # 8002cec0 <udp_lock>
    80007734:	d32f90ef          	jal	80000c66 <release>
    80007738:	7902                	ld	s2,32(sp)
    8000773a:	6aa2                	ld	s5,8(sp)
    8000773c:	6b02                	ld	s6,0(sp)
    8000773e:	bf15                	j	80007672 <udp_recv+0x44>
    80007740:	8082                	ret

0000000080007742 <udp_unbind>:

// Unbind from a UDP port
void
udp_unbind(int sock)
{
  if(sock < 0 || sock >= MAX_UDP_SOCKETS)
    80007742:	47bd                	li	a5,15
    80007744:	00a7f363          	bgeu	a5,a0,8000774a <udp_unbind+0x8>
    80007748:	8082                	ret
{
    8000774a:	1101                	addi	sp,sp,-32
    8000774c:	ec06                	sd	ra,24(sp)
    8000774e:	e822                	sd	s0,16(sp)
    80007750:	e426                	sd	s1,8(sp)
    80007752:	e04a                	sd	s2,0(sp)
    80007754:	1000                	addi	s0,sp,32
    80007756:	84aa                	mv	s1,a0
    return;

  acquire(&udp_lock);
    80007758:	00025917          	auipc	s2,0x25
    8000775c:	76890913          	addi	s2,s2,1896 # 8002cec0 <udp_lock>
    80007760:	854a                	mv	a0,s2
    80007762:	c6cf90ef          	jal	80000bce <acquire>
  udp_sockets[sock].used = 0;
    80007766:	00449793          	slli	a5,s1,0x4
    8000776a:	97ca                	add	a5,a5,s2
    8000776c:	0007ac23          	sw	zero,24(a5)
  udp_sockets[sock].port = 0;
    80007770:	00079e23          	sh	zero,28(a5)
  udp_sockets[sock].handler = 0;
    80007774:	0207b023          	sd	zero,32(a5)
  release(&udp_lock);
    80007778:	854a                	mv	a0,s2
    8000777a:	cecf90ef          	jal	80000c66 <release>
}
    8000777e:	60e2                	ld	ra,24(sp)
    80007780:	6442                	ld	s0,16(sp)
    80007782:	64a2                	ld	s1,8(sp)
    80007784:	6902                	ld	s2,0(sp)
    80007786:	6105                	addi	sp,sp,32
    80007788:	8082                	ret

000000008000778a <xdr_init>:
#include "xdr.h"

// Initialize XDR buffer
void
xdr_init(struct xdr_buf *xdr, void *data, int len)
{
    8000778a:	1141                	addi	sp,sp,-16
    8000778c:	e422                	sd	s0,8(sp)
    8000778e:	0800                	addi	s0,sp,16
  xdr->data = (uchar *)data;
    80007790:	e10c                	sd	a1,0(a0)
  xdr->pos = 0;
    80007792:	00052423          	sw	zero,8(a0)
  xdr->len = len;
    80007796:	c550                	sw	a2,12(a0)
}
    80007798:	6422                	ld	s0,8(sp)
    8000779a:	0141                	addi	sp,sp,16
    8000779c:	8082                	ret

000000008000779e <xdr_encode_uint32>:

// Encode uint32 (big-endian)
int
xdr_encode_uint32(struct xdr_buf *xdr, uint32 val)
{
    8000779e:	1141                	addi	sp,sp,-16
    800077a0:	e422                	sd	s0,8(sp)
    800077a2:	0800                	addi	s0,sp,16
  if(xdr->pos + 4 > xdr->len)
    800077a4:	451c                	lw	a5,8(a0)
    800077a6:	0037869b          	addiw	a3,a5,3
    800077aa:	4558                	lw	a4,12(a0)
    800077ac:	04e6db63          	bge	a3,a4,80007802 <xdr_encode_uint32+0x64>
    return -1;

  xdr->data[xdr->pos++] = (val >> 24) & 0xFF;
    800077b0:	6118                	ld	a4,0(a0)
    800077b2:	0017869b          	addiw	a3,a5,1
    800077b6:	c514                	sw	a3,8(a0)
    800077b8:	97ba                	add	a5,a5,a4
    800077ba:	0185d71b          	srliw	a4,a1,0x18
    800077be:	00e78023          	sb	a4,0(a5)
  xdr->data[xdr->pos++] = (val >> 16) & 0xFF;
    800077c2:	611c                	ld	a5,0(a0)
    800077c4:	4518                	lw	a4,8(a0)
    800077c6:	0017069b          	addiw	a3,a4,1
    800077ca:	c514                	sw	a3,8(a0)
    800077cc:	97ba                	add	a5,a5,a4
    800077ce:	0105d71b          	srliw	a4,a1,0x10
    800077d2:	00e78023          	sb	a4,0(a5)
  xdr->data[xdr->pos++] = (val >> 8) & 0xFF;
    800077d6:	611c                	ld	a5,0(a0)
    800077d8:	4518                	lw	a4,8(a0)
    800077da:	0017069b          	addiw	a3,a4,1
    800077de:	c514                	sw	a3,8(a0)
    800077e0:	97ba                	add	a5,a5,a4
    800077e2:	0085d71b          	srliw	a4,a1,0x8
    800077e6:	00e78023          	sb	a4,0(a5)
  xdr->data[xdr->pos++] = val & 0xFF;
    800077ea:	611c                	ld	a5,0(a0)
    800077ec:	4518                	lw	a4,8(a0)
    800077ee:	0017069b          	addiw	a3,a4,1
    800077f2:	c514                	sw	a3,8(a0)
    800077f4:	97ba                	add	a5,a5,a4
    800077f6:	00b78023          	sb	a1,0(a5)

  return 0;
    800077fa:	4501                	li	a0,0
}
    800077fc:	6422                	ld	s0,8(sp)
    800077fe:	0141                	addi	sp,sp,16
    80007800:	8082                	ret
    return -1;
    80007802:	557d                	li	a0,-1
    80007804:	bfe5                	j	800077fc <xdr_encode_uint32+0x5e>

0000000080007806 <xdr_encode_uint64>:

// Encode uint64 (big-endian)
int
xdr_encode_uint64(struct xdr_buf *xdr, uint64 val)
{
    80007806:	1101                	addi	sp,sp,-32
    80007808:	ec06                	sd	ra,24(sp)
    8000780a:	e822                	sd	s0,16(sp)
    8000780c:	e426                	sd	s1,8(sp)
    8000780e:	e04a                	sd	s2,0(sp)
    80007810:	1000                	addi	s0,sp,32
    80007812:	892a                	mv	s2,a0
    80007814:	84ae                	mv	s1,a1
  if(xdr_encode_uint32(xdr, (uint32)(val >> 32)) < 0)
    80007816:	9581                	srai	a1,a1,0x20
    80007818:	f87ff0ef          	jal	8000779e <xdr_encode_uint32>
    8000781c:	00054f63          	bltz	a0,8000783a <xdr_encode_uint64+0x34>
    return -1;
  if(xdr_encode_uint32(xdr, (uint32)(val & 0xFFFFFFFF)) < 0)
    80007820:	0004859b          	sext.w	a1,s1
    80007824:	854a                	mv	a0,s2
    80007826:	f79ff0ef          	jal	8000779e <xdr_encode_uint32>
    8000782a:	41f5551b          	sraiw	a0,a0,0x1f
    return -1;
  return 0;
}
    8000782e:	60e2                	ld	ra,24(sp)
    80007830:	6442                	ld	s0,16(sp)
    80007832:	64a2                	ld	s1,8(sp)
    80007834:	6902                	ld	s2,0(sp)
    80007836:	6105                	addi	sp,sp,32
    80007838:	8082                	ret
    return -1;
    8000783a:	557d                	li	a0,-1
    8000783c:	bfcd                	j	8000782e <xdr_encode_uint64+0x28>

000000008000783e <xdr_encode_bytes>:

// Encode variable-length bytes
int
xdr_encode_bytes(struct xdr_buf *xdr, void *data, int len)
{
    8000783e:	7139                	addi	sp,sp,-64
    80007840:	fc06                	sd	ra,56(sp)
    80007842:	f822                	sd	s0,48(sp)
    80007844:	f426                	sd	s1,40(sp)
    80007846:	f04a                	sd	s2,32(sp)
    80007848:	e852                	sd	s4,16(sp)
    8000784a:	e456                	sd	s5,8(sp)
    8000784c:	0080                	addi	s0,sp,64
    8000784e:	892a                	mv	s2,a0
    80007850:	8aae                	mv	s5,a1
    80007852:	84b2                	mv	s1,a2
  // Encode length
  if(xdr_encode_uint32(xdr, len) < 0)
    80007854:	00060a1b          	sext.w	s4,a2
    80007858:	85d2                	mv	a1,s4
    8000785a:	f45ff0ef          	jal	8000779e <xdr_encode_uint32>
    8000785e:	06054363          	bltz	a0,800078c4 <xdr_encode_bytes+0x86>
    80007862:	ec4e                	sd	s3,24(sp)
    return -1;

  // Encode data (padded to 4-byte boundary)
  int padded = (len + 3) & ~3;
    80007864:	0034879b          	addiw	a5,s1,3
    80007868:	9bf1                	andi	a5,a5,-4
    8000786a:	0007899b          	sext.w	s3,a5
  if(xdr->pos + padded > xdr->len)
    8000786e:	00892703          	lw	a4,8(s2)
    80007872:	9fb9                	addw	a5,a5,a4
    80007874:	00c92683          	lw	a3,12(s2)
    80007878:	04f6c863          	blt	a3,a5,800078c8 <xdr_encode_bytes+0x8a>
    return -1;

  memmove(xdr->data + xdr->pos, data, len);
    8000787c:	00093503          	ld	a0,0(s2)
    80007880:	8652                	mv	a2,s4
    80007882:	85d6                	mv	a1,s5
    80007884:	953a                	add	a0,a0,a4
    80007886:	c78f90ef          	jal	80000cfe <memmove>

  // Zero padding
  for(int i = len; i < padded; i++)
    8000788a:	0134dd63          	bge	s1,s3,800078a4 <xdr_encode_bytes+0x66>
    xdr->data[xdr->pos + i] = 0;
    8000788e:	00892703          	lw	a4,8(s2)
    80007892:	9f25                	addw	a4,a4,s1
    80007894:	00093783          	ld	a5,0(s2)
    80007898:	97ba                	add	a5,a5,a4
    8000789a:	00078023          	sb	zero,0(a5)
  for(int i = len; i < padded; i++)
    8000789e:	2485                	addiw	s1,s1,1
    800078a0:	fe9997e3          	bne	s3,s1,8000788e <xdr_encode_bytes+0x50>

  xdr->pos += padded;
    800078a4:	00892783          	lw	a5,8(s2)
    800078a8:	013787bb          	addw	a5,a5,s3
    800078ac:	00f92423          	sw	a5,8(s2)
  return 0;
    800078b0:	4501                	li	a0,0
    800078b2:	69e2                	ld	s3,24(sp)
}
    800078b4:	70e2                	ld	ra,56(sp)
    800078b6:	7442                	ld	s0,48(sp)
    800078b8:	74a2                	ld	s1,40(sp)
    800078ba:	7902                	ld	s2,32(sp)
    800078bc:	6a42                	ld	s4,16(sp)
    800078be:	6aa2                	ld	s5,8(sp)
    800078c0:	6121                	addi	sp,sp,64
    800078c2:	8082                	ret
    return -1;
    800078c4:	557d                	li	a0,-1
    800078c6:	b7fd                	j	800078b4 <xdr_encode_bytes+0x76>
    return -1;
    800078c8:	557d                	li	a0,-1
    800078ca:	69e2                	ld	s3,24(sp)
    800078cc:	b7e5                	j	800078b4 <xdr_encode_bytes+0x76>

00000000800078ce <xdr_encode_opaque>:

// Encode fixed-length opaque data
int
xdr_encode_opaque(struct xdr_buf *xdr, void *data, int len)
{
    800078ce:	7179                	addi	sp,sp,-48
    800078d0:	f406                	sd	ra,40(sp)
    800078d2:	f022                	sd	s0,32(sp)
    800078d4:	e44e                	sd	s3,8(sp)
    800078d6:	1800                	addi	s0,sp,48
  // Encode data (padded to 4-byte boundary)
  int padded = (len + 3) & ~3;
    800078d8:	0036079b          	addiw	a5,a2,3
    800078dc:	9bf1                	andi	a5,a5,-4
    800078de:	0007899b          	sext.w	s3,a5
  if(xdr->pos + padded > xdr->len)
    800078e2:	4518                	lw	a4,8(a0)
    800078e4:	9fb9                	addw	a5,a5,a4
    800078e6:	4554                	lw	a3,12(a0)
    800078e8:	04f6c563          	blt	a3,a5,80007932 <xdr_encode_opaque+0x64>
    800078ec:	ec26                	sd	s1,24(sp)
    800078ee:	e84a                	sd	s2,16(sp)
    800078f0:	892a                	mv	s2,a0
    800078f2:	84b2                	mv	s1,a2
    return -1;

  memmove(xdr->data + xdr->pos, data, len);
    800078f4:	6108                	ld	a0,0(a0)
    800078f6:	953a                	add	a0,a0,a4
    800078f8:	c06f90ef          	jal	80000cfe <memmove>

  // Zero padding
  for(int i = len; i < padded; i++)
    800078fc:	0134dd63          	bge	s1,s3,80007916 <xdr_encode_opaque+0x48>
    xdr->data[xdr->pos + i] = 0;
    80007900:	00892703          	lw	a4,8(s2)
    80007904:	9f25                	addw	a4,a4,s1
    80007906:	00093783          	ld	a5,0(s2)
    8000790a:	97ba                	add	a5,a5,a4
    8000790c:	00078023          	sb	zero,0(a5)
  for(int i = len; i < padded; i++)
    80007910:	2485                	addiw	s1,s1,1
    80007912:	fe9997e3          	bne	s3,s1,80007900 <xdr_encode_opaque+0x32>

  xdr->pos += padded;
    80007916:	00892783          	lw	a5,8(s2)
    8000791a:	013787bb          	addw	a5,a5,s3
    8000791e:	00f92423          	sw	a5,8(s2)
  return 0;
    80007922:	4501                	li	a0,0
    80007924:	64e2                	ld	s1,24(sp)
    80007926:	6942                	ld	s2,16(sp)
}
    80007928:	70a2                	ld	ra,40(sp)
    8000792a:	7402                	ld	s0,32(sp)
    8000792c:	69a2                	ld	s3,8(sp)
    8000792e:	6145                	addi	sp,sp,48
    80007930:	8082                	ret
    return -1;
    80007932:	557d                	li	a0,-1
    80007934:	bfd5                	j	80007928 <xdr_encode_opaque+0x5a>

0000000080007936 <xdr_encode_string>:

// Encode string
int
xdr_encode_string(struct xdr_buf *xdr, const char *str)
{
    80007936:	1101                	addi	sp,sp,-32
    80007938:	ec06                	sd	ra,24(sp)
    8000793a:	e822                	sd	s0,16(sp)
    8000793c:	e426                	sd	s1,8(sp)
    8000793e:	e04a                	sd	s2,0(sp)
    80007940:	1000                	addi	s0,sp,32
    80007942:	892a                	mv	s2,a0
    80007944:	84ae                	mv	s1,a1
  return xdr_encode_bytes(xdr, (void *)str, strlen(str));
    80007946:	852e                	mv	a0,a1
    80007948:	ccaf90ef          	jal	80000e12 <strlen>
    8000794c:	862a                	mv	a2,a0
    8000794e:	85a6                	mv	a1,s1
    80007950:	854a                	mv	a0,s2
    80007952:	eedff0ef          	jal	8000783e <xdr_encode_bytes>
}
    80007956:	60e2                	ld	ra,24(sp)
    80007958:	6442                	ld	s0,16(sp)
    8000795a:	64a2                	ld	s1,8(sp)
    8000795c:	6902                	ld	s2,0(sp)
    8000795e:	6105                	addi	sp,sp,32
    80007960:	8082                	ret

0000000080007962 <xdr_decode_uint32>:

// Decode uint32 (big-endian)
int
xdr_decode_uint32(struct xdr_buf *xdr, uint32 *val)
{
    80007962:	1141                	addi	sp,sp,-16
    80007964:	e422                	sd	s0,8(sp)
    80007966:	0800                	addi	s0,sp,16
  if(xdr->pos + 4 > xdr->len)
    80007968:	451c                	lw	a5,8(a0)
    8000796a:	0037869b          	addiw	a3,a5,3
    8000796e:	4558                	lw	a4,12(a0)
    80007970:	02e6dd63          	bge	a3,a4,800079aa <xdr_decode_uint32+0x48>
    return -1;

  *val = ((uint32)xdr->data[xdr->pos] << 24) |
    80007974:	6118                	ld	a4,0(a0)
    80007976:	973e                	add	a4,a4,a5
    80007978:	00074783          	lbu	a5,0(a4)
    8000797c:	0187979b          	slliw	a5,a5,0x18
         ((uint32)xdr->data[xdr->pos + 1] << 16) |
         ((uint32)xdr->data[xdr->pos + 2] << 8) |
         ((uint32)xdr->data[xdr->pos + 3]);
    80007980:	00374683          	lbu	a3,3(a4)
         ((uint32)xdr->data[xdr->pos + 2] << 8) |
    80007984:	8fd5                	or	a5,a5,a3
         ((uint32)xdr->data[xdr->pos + 1] << 16) |
    80007986:	00174683          	lbu	a3,1(a4)
    8000798a:	0106969b          	slliw	a3,a3,0x10
         ((uint32)xdr->data[xdr->pos + 2] << 8) |
    8000798e:	8fd5                	or	a5,a5,a3
    80007990:	00274703          	lbu	a4,2(a4)
    80007994:	0087171b          	slliw	a4,a4,0x8
    80007998:	8fd9                	or	a5,a5,a4
  *val = ((uint32)xdr->data[xdr->pos] << 24) |
    8000799a:	c19c                	sw	a5,0(a1)

  xdr->pos += 4;
    8000799c:	451c                	lw	a5,8(a0)
    8000799e:	2791                	addiw	a5,a5,4
    800079a0:	c51c                	sw	a5,8(a0)
  return 0;
    800079a2:	4501                	li	a0,0
}
    800079a4:	6422                	ld	s0,8(sp)
    800079a6:	0141                	addi	sp,sp,16
    800079a8:	8082                	ret
    return -1;
    800079aa:	557d                	li	a0,-1
    800079ac:	bfe5                	j	800079a4 <xdr_decode_uint32+0x42>

00000000800079ae <xdr_decode_uint64>:

// Decode uint64 (big-endian)
int
xdr_decode_uint64(struct xdr_buf *xdr, uint64 *val)
{
    800079ae:	7179                	addi	sp,sp,-48
    800079b0:	f406                	sd	ra,40(sp)
    800079b2:	f022                	sd	s0,32(sp)
    800079b4:	ec26                	sd	s1,24(sp)
    800079b6:	e84a                	sd	s2,16(sp)
    800079b8:	1800                	addi	s0,sp,48
    800079ba:	84aa                	mv	s1,a0
    800079bc:	892e                	mv	s2,a1
  uint32 high, low;
  if(xdr_decode_uint32(xdr, &high) < 0)
    800079be:	fdc40593          	addi	a1,s0,-36
    800079c2:	fa1ff0ef          	jal	80007962 <xdr_decode_uint32>
    800079c6:	02054863          	bltz	a0,800079f6 <xdr_decode_uint64+0x48>
    return -1;
  if(xdr_decode_uint32(xdr, &low) < 0)
    800079ca:	fd840593          	addi	a1,s0,-40
    800079ce:	8526                	mv	a0,s1
    800079d0:	f93ff0ef          	jal	80007962 <xdr_decode_uint32>
    800079d4:	02054363          	bltz	a0,800079fa <xdr_decode_uint64+0x4c>
    return -1;
  *val = ((uint64)high << 32) | low;
    800079d8:	fdc46783          	lwu	a5,-36(s0)
    800079dc:	1782                	slli	a5,a5,0x20
    800079de:	fd846703          	lwu	a4,-40(s0)
    800079e2:	8fd9                	or	a5,a5,a4
    800079e4:	00f93023          	sd	a5,0(s2)
  return 0;
    800079e8:	4501                	li	a0,0
}
    800079ea:	70a2                	ld	ra,40(sp)
    800079ec:	7402                	ld	s0,32(sp)
    800079ee:	64e2                	ld	s1,24(sp)
    800079f0:	6942                	ld	s2,16(sp)
    800079f2:	6145                	addi	sp,sp,48
    800079f4:	8082                	ret
    return -1;
    800079f6:	557d                	li	a0,-1
    800079f8:	bfcd                	j	800079ea <xdr_decode_uint64+0x3c>
    return -1;
    800079fa:	557d                	li	a0,-1
    800079fc:	b7fd                	j	800079ea <xdr_decode_uint64+0x3c>

00000000800079fe <xdr_decode_bytes>:

// Decode variable-length bytes
int
xdr_decode_bytes(struct xdr_buf *xdr, void *data, int maxlen)
{
    800079fe:	7139                	addi	sp,sp,-64
    80007a00:	fc06                	sd	ra,56(sp)
    80007a02:	f822                	sd	s0,48(sp)
    80007a04:	f426                	sd	s1,40(sp)
    80007a06:	ec4e                	sd	s3,24(sp)
    80007a08:	e852                	sd	s4,16(sp)
    80007a0a:	0080                	addi	s0,sp,64
    80007a0c:	84aa                	mv	s1,a0
    80007a0e:	8a2e                	mv	s4,a1
    80007a10:	89b2                	mv	s3,a2
  uint32 len;
  if(xdr_decode_uint32(xdr, &len) < 0)
    80007a12:	fcc40593          	addi	a1,s0,-52
    80007a16:	f4dff0ef          	jal	80007962 <xdr_decode_uint32>
    80007a1a:	04054763          	bltz	a0,80007a68 <xdr_decode_bytes+0x6a>
    80007a1e:	f04a                	sd	s2,32(sp)
    return -1;

  if(len > maxlen)
    80007a20:	fcc42903          	lw	s2,-52(s0)
    80007a24:	0009861b          	sext.w	a2,s3
    80007a28:	05266263          	bltu	a2,s2,80007a6c <xdr_decode_bytes+0x6e>
    return -1;

  int padded = (len + 3) & ~3;
    80007a2c:	0039079b          	addiw	a5,s2,3
    80007a30:	9bf1                	andi	a5,a5,-4
    80007a32:	0007899b          	sext.w	s3,a5
  if(xdr->pos + padded > xdr->len)
    80007a36:	4498                	lw	a4,8(s1)
    80007a38:	9fb9                	addw	a5,a5,a4
    80007a3a:	44d4                	lw	a3,12(s1)
    80007a3c:	02f6cb63          	blt	a3,a5,80007a72 <xdr_decode_bytes+0x74>
    return -1;

  memmove(data, xdr->data + xdr->pos, len);
    80007a40:	608c                	ld	a1,0(s1)
    80007a42:	864a                	mv	a2,s2
    80007a44:	95ba                	add	a1,a1,a4
    80007a46:	8552                	mv	a0,s4
    80007a48:	ab6f90ef          	jal	80000cfe <memmove>
  xdr->pos += padded;
    80007a4c:	449c                	lw	a5,8(s1)
    80007a4e:	013787bb          	addw	a5,a5,s3
    80007a52:	c49c                	sw	a5,8(s1)

  return len;
    80007a54:	0009051b          	sext.w	a0,s2
    80007a58:	7902                	ld	s2,32(sp)
}
    80007a5a:	70e2                	ld	ra,56(sp)
    80007a5c:	7442                	ld	s0,48(sp)
    80007a5e:	74a2                	ld	s1,40(sp)
    80007a60:	69e2                	ld	s3,24(sp)
    80007a62:	6a42                	ld	s4,16(sp)
    80007a64:	6121                	addi	sp,sp,64
    80007a66:	8082                	ret
    return -1;
    80007a68:	557d                	li	a0,-1
    80007a6a:	bfc5                	j	80007a5a <xdr_decode_bytes+0x5c>
    return -1;
    80007a6c:	557d                	li	a0,-1
    80007a6e:	7902                	ld	s2,32(sp)
    80007a70:	b7ed                	j	80007a5a <xdr_decode_bytes+0x5c>
    return -1;
    80007a72:	557d                	li	a0,-1
    80007a74:	7902                	ld	s2,32(sp)
    80007a76:	b7d5                	j	80007a5a <xdr_decode_bytes+0x5c>

0000000080007a78 <xdr_decode_opaque>:

// Decode fixed-length opaque data
int
xdr_decode_opaque(struct xdr_buf *xdr, void *data, int len)
{
    80007a78:	7179                	addi	sp,sp,-48
    80007a7a:	f406                	sd	ra,40(sp)
    80007a7c:	f022                	sd	s0,32(sp)
    80007a7e:	e84a                	sd	s2,16(sp)
    80007a80:	e44e                	sd	s3,8(sp)
    80007a82:	1800                	addi	s0,sp,48
    80007a84:	892a                	mv	s2,a0
  int padded = (len + 3) & ~3;
    80007a86:	0036079b          	addiw	a5,a2,3
    80007a8a:	9bf1                	andi	a5,a5,-4
    80007a8c:	0007899b          	sext.w	s3,a5
  if(xdr->pos + padded > xdr->len)
    80007a90:	4518                	lw	a4,8(a0)
    80007a92:	9fb9                	addw	a5,a5,a4
    80007a94:	4554                	lw	a3,12(a0)
    80007a96:	02f6c863          	blt	a3,a5,80007ac6 <xdr_decode_opaque+0x4e>
    80007a9a:	ec26                	sd	s1,24(sp)
    80007a9c:	852e                	mv	a0,a1
    80007a9e:	84b2                	mv	s1,a2
    return -1;

  memmove(data, xdr->data + xdr->pos, len);
    80007aa0:	00093583          	ld	a1,0(s2)
    80007aa4:	95ba                	add	a1,a1,a4
    80007aa6:	a58f90ef          	jal	80000cfe <memmove>
  xdr->pos += padded;
    80007aaa:	00892783          	lw	a5,8(s2)
    80007aae:	013787bb          	addw	a5,a5,s3
    80007ab2:	00f92423          	sw	a5,8(s2)

  return len;
    80007ab6:	8526                	mv	a0,s1
    80007ab8:	64e2                	ld	s1,24(sp)
}
    80007aba:	70a2                	ld	ra,40(sp)
    80007abc:	7402                	ld	s0,32(sp)
    80007abe:	6942                	ld	s2,16(sp)
    80007ac0:	69a2                	ld	s3,8(sp)
    80007ac2:	6145                	addi	sp,sp,48
    80007ac4:	8082                	ret
    return -1;
    80007ac6:	557d                	li	a0,-1
    80007ac8:	bfcd                	j	80007aba <xdr_decode_opaque+0x42>

0000000080007aca <xdr_decode_string>:

// Decode string
int
xdr_decode_string(struct xdr_buf *xdr, char *str, int maxlen)
{
    80007aca:	1101                	addi	sp,sp,-32
    80007acc:	ec06                	sd	ra,24(sp)
    80007ace:	e822                	sd	s0,16(sp)
    80007ad0:	e426                	sd	s1,8(sp)
    80007ad2:	1000                	addi	s0,sp,32
    80007ad4:	84ae                	mv	s1,a1
  int len = xdr_decode_bytes(xdr, str, maxlen - 1);
    80007ad6:	367d                	addiw	a2,a2,-1
    80007ad8:	f27ff0ef          	jal	800079fe <xdr_decode_bytes>
  if(len < 0)
    80007adc:	00054b63          	bltz	a0,80007af2 <xdr_decode_string+0x28>
    return -1;
  str[len] = '\0';
    80007ae0:	00a485b3          	add	a1,s1,a0
    80007ae4:	00058023          	sb	zero,0(a1)
  return len;
}
    80007ae8:	60e2                	ld	ra,24(sp)
    80007aea:	6442                	ld	s0,16(sp)
    80007aec:	64a2                	ld	s1,8(sp)
    80007aee:	6105                	addi	sp,sp,32
    80007af0:	8082                	ret
    return -1;
    80007af2:	557d                	li	a0,-1
    80007af4:	bfd5                	j	80007ae8 <xdr_decode_string+0x1e>

0000000080007af6 <xdr_skip>:

// Skip n bytes
int
xdr_skip(struct xdr_buf *xdr, int n)
{
    80007af6:	1141                	addi	sp,sp,-16
    80007af8:	e422                	sd	s0,8(sp)
    80007afa:	0800                	addi	s0,sp,16
  int padded = (n + 3) & ~3;
    80007afc:	258d                	addiw	a1,a1,3
    80007afe:	99f1                	andi	a1,a1,-4
  if(xdr->pos + padded > xdr->len)
    80007b00:	451c                	lw	a5,8(a0)
    80007b02:	9fad                	addw	a5,a5,a1
    80007b04:	0007871b          	sext.w	a4,a5
    80007b08:	4554                	lw	a3,12(a0)
    80007b0a:	00e6c763          	blt	a3,a4,80007b18 <xdr_skip+0x22>
    return -1;
  xdr->pos += padded;
    80007b0e:	c51c                	sw	a5,8(a0)
  return 0;
    80007b10:	4501                	li	a0,0
}
    80007b12:	6422                	ld	s0,8(sp)
    80007b14:	0141                	addi	sp,sp,16
    80007b16:	8082                	ret
    return -1;
    80007b18:	557d                	li	a0,-1
    80007b1a:	bfe5                	j	80007b12 <xdr_skip+0x1c>

0000000080007b1c <rpc_recv_handler>:
}

// UDP handler for RPC replies
static void
rpc_recv_handler(uint32 src_ip, ushort src_port, void *data, int len)
{
    80007b1c:	715d                	addi	sp,sp,-80
    80007b1e:	e486                	sd	ra,72(sp)
    80007b20:	e0a2                	sd	s0,64(sp)
    80007b22:	fc26                	sd	s1,56(sp)
    80007b24:	f84a                	sd	s2,48(sp)
    80007b26:	f44e                	sd	s3,40(sp)
    80007b28:	0880                	addi	s0,sp,80
    80007b2a:	8932                	mv	s2,a2
    80007b2c:	84b6                	mv	s1,a3
  acquire(&rpc_lock);
    80007b2e:	00025517          	auipc	a0,0x25
    80007b32:	4aa50513          	addi	a0,a0,1194 # 8002cfd8 <rpc_lock>
    80007b36:	898f90ef          	jal	80000bce <acquire>

  // Check if we're expecting a reply
  if(len <= sizeof(rpc_reply_buf)) {
    80007b3a:	0004899b          	sext.w	s3,s1
    80007b3e:	6789                	lui	a5,0x2
    80007b40:	0137ff63          	bgeu	a5,s3,80007b5e <rpc_recv_handler+0x42>
        rpc_reply_received = 1;
      }
    }
  }

  release(&rpc_lock);
    80007b44:	00025517          	auipc	a0,0x25
    80007b48:	49450513          	addi	a0,a0,1172 # 8002cfd8 <rpc_lock>
    80007b4c:	91af90ef          	jal	80000c66 <release>
}
    80007b50:	60a6                	ld	ra,72(sp)
    80007b52:	6406                	ld	s0,64(sp)
    80007b54:	74e2                	ld	s1,56(sp)
    80007b56:	7942                	ld	s2,48(sp)
    80007b58:	79a2                	ld	s3,40(sp)
    80007b5a:	6161                	addi	sp,sp,80
    80007b5c:	8082                	ret
    xdr_init(&xdr, data, len);
    80007b5e:	8626                	mv	a2,s1
    80007b60:	85ca                	mv	a1,s2
    80007b62:	fc040513          	addi	a0,s0,-64
    80007b66:	c25ff0ef          	jal	8000778a <xdr_init>
    if(xdr_decode_uint32(&xdr, &xid) == 0) {
    80007b6a:	fbc40593          	addi	a1,s0,-68
    80007b6e:	fc040513          	addi	a0,s0,-64
    80007b72:	df1ff0ef          	jal	80007962 <xdr_decode_uint32>
    80007b76:	f579                	bnez	a0,80007b44 <rpc_recv_handler+0x28>
      if(xid == rpc_expected_xid) {
    80007b78:	fbc42703          	lw	a4,-68(s0)
    80007b7c:	00007797          	auipc	a5,0x7
    80007b80:	d3c7a783          	lw	a5,-708(a5) # 8000e8b8 <rpc_expected_xid>
    80007b84:	fcf710e3          	bne	a4,a5,80007b44 <rpc_recv_handler+0x28>
        memmove(rpc_reply_buf, data, len);
    80007b88:	864e                	mv	a2,s3
    80007b8a:	85ca                	mv	a1,s2
    80007b8c:	00025517          	auipc	a0,0x25
    80007b90:	46450513          	addi	a0,a0,1124 # 8002cff0 <rpc_reply_buf>
    80007b94:	96af90ef          	jal	80000cfe <memmove>
        rpc_reply_len = len;
    80007b98:	00007797          	auipc	a5,0x7
    80007b9c:	d297a223          	sw	s1,-732(a5) # 8000e8bc <rpc_reply_len>
        rpc_reply_received = 1;
    80007ba0:	4785                	li	a5,1
    80007ba2:	00007717          	auipc	a4,0x7
    80007ba6:	d0f72f23          	sw	a5,-738(a4) # 8000e8c0 <rpc_reply_received>
    80007baa:	bf69                	j	80007b44 <rpc_recv_handler+0x28>

0000000080007bac <rpc_init>:
{
    80007bac:	1141                	addi	sp,sp,-16
    80007bae:	e406                	sd	ra,8(sp)
    80007bb0:	e022                	sd	s0,0(sp)
    80007bb2:	0800                	addi	s0,sp,16
  initlock(&rpc_lock, "rpc");
    80007bb4:	00003597          	auipc	a1,0x3
    80007bb8:	e2458593          	addi	a1,a1,-476 # 8000a9d8 <etext+0x9d8>
    80007bbc:	00025517          	auipc	a0,0x25
    80007bc0:	41c50513          	addi	a0,a0,1052 # 8002cfd8 <rpc_lock>
    80007bc4:	f8bf80ef          	jal	80000b4e <initlock>
  rpc_reply_received = 0;
    80007bc8:	00007797          	auipc	a5,0x7
    80007bcc:	ce07ac23          	sw	zero,-776(a5) # 8000e8c0 <rpc_reply_received>
}
    80007bd0:	60a2                	ld	ra,8(sp)
    80007bd2:	6402                	ld	s0,0(sp)
    80007bd4:	0141                	addi	sp,sp,16
    80007bd6:	8082                	ret

0000000080007bd8 <rpc_call>:

// Make an RPC call
int
rpc_call(uint32 server_ip, ushort port, uint32 prog, uint32 vers, uint32 proc,
         void *args, int args_len, void *result, int result_max)
{
    80007bd8:	7131                	addi	sp,sp,-192
    80007bda:	fd06                	sd	ra,184(sp)
    80007bdc:	f922                	sd	s0,176(sp)
    80007bde:	f526                	sd	s1,168(sp)
    80007be0:	f14a                	sd	s2,160(sp)
    80007be2:	ed4e                	sd	s3,152(sp)
    80007be4:	e952                	sd	s4,144(sp)
    80007be6:	e15a                	sd	s6,128(sp)
    80007be8:	f0ea                	sd	s10,96(sp)
    80007bea:	ecee                	sd	s11,88(sp)
    80007bec:	0180                	addi	s0,sp,192
    80007bee:	f4a43c23          	sd	a0,-168(s0)
    80007bf2:	f4b43823          	sd	a1,-176(s0)
    80007bf6:	8b32                	mv	s6,a2
    80007bf8:	8a36                	mv	s4,a3
    80007bfa:	89ba                	mv	s3,a4
    80007bfc:	893e                	mv	s2,a5
    80007bfe:	8dc2                	mv	s11,a6
    80007c00:	f5143423          	sd	a7,-184(s0)
    80007c04:	00042d03          	lw	s10,0(s0)
  uchar *call_buf;
  struct xdr_buf xdr;
  uint32 xid;
  int retries = 3;

  call_buf = (uchar*)kalloc();
    80007c08:	ef7f80ef          	jal	80000afe <kalloc>
  if(call_buf == 0)
    80007c0c:	2a050c63          	beqz	a0,80007ec4 <rpc_call+0x2ec>
    80007c10:	e556                	sd	s5,136(sp)
    80007c12:	fcde                	sd	s7,120(sp)
    80007c14:	f8e2                	sd	s8,112(sp)
    80007c16:	8aaa                	mv	s5,a0
    return -1;
  memset(call_buf, 0, PGSIZE);
    80007c18:	6605                	lui	a2,0x1
    80007c1a:	4581                	li	a1,0
    80007c1c:	886f90ef          	jal	80000ca2 <memset>

  // Generate XID
  acquire(&rpc_lock);
    80007c20:	00025b97          	auipc	s7,0x25
    80007c24:	3b8b8b93          	addi	s7,s7,952 # 8002cfd8 <rpc_lock>
    80007c28:	855e                	mv	a0,s7
    80007c2a:	fa5f80ef          	jal	80000bce <acquire>
  xid = rpc_xid++;
    80007c2e:	00007797          	auipc	a5,0x7
    80007c32:	a7278793          	addi	a5,a5,-1422 # 8000e6a0 <rpc_xid>
    80007c36:	0007ac03          	lw	s8,0(a5)
    80007c3a:	001c071b          	addiw	a4,s8,1
    80007c3e:	c398                	sw	a4,0(a5)
  rpc_expected_xid = xid;
    80007c40:	00007797          	auipc	a5,0x7
    80007c44:	c787ac23          	sw	s8,-904(a5) # 8000e8b8 <rpc_expected_xid>
  rpc_reply_received = 0;
    80007c48:	00007797          	auipc	a5,0x7
    80007c4c:	c607ac23          	sw	zero,-904(a5) # 8000e8c0 <rpc_reply_received>
  release(&rpc_lock);
    80007c50:	855e                	mv	a0,s7
    80007c52:	814f90ef          	jal	80000c66 <release>

  // Encode RPC call header
  xdr_init(&xdr, call_buf, sizeof(call_buf));
    80007c56:	4621                	li	a2,8
    80007c58:	85d6                	mv	a1,s5
    80007c5a:	f8040513          	addi	a0,s0,-128
    80007c5e:	b2dff0ef          	jal	8000778a <xdr_init>
  xdr_encode_uint32(&xdr, xid);
    80007c62:	85e2                	mv	a1,s8
    80007c64:	f8040513          	addi	a0,s0,-128
    80007c68:	b37ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, RPC_CALL);
    80007c6c:	4581                	li	a1,0
    80007c6e:	f8040513          	addi	a0,s0,-128
    80007c72:	b2dff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, 2);        // RPC version
    80007c76:	4589                	li	a1,2
    80007c78:	f8040513          	addi	a0,s0,-128
    80007c7c:	b23ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, prog);
    80007c80:	85da                	mv	a1,s6
    80007c82:	f8040513          	addi	a0,s0,-128
    80007c86:	b19ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, vers);
    80007c8a:	85d2                	mv	a1,s4
    80007c8c:	f8040513          	addi	a0,s0,-128
    80007c90:	b0fff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, proc);
    80007c94:	85ce                	mv	a1,s3
    80007c96:	f8040513          	addi	a0,s0,-128
    80007c9a:	b05ff0ef          	jal	8000779e <xdr_encode_uint32>

  // AUTH_NULL credentials
  xdr_encode_uint32(&xdr, RPC_AUTH_NULL);
    80007c9e:	4581                	li	a1,0
    80007ca0:	f8040513          	addi	a0,s0,-128
    80007ca4:	afbff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, 0);        // cred length
    80007ca8:	4581                	li	a1,0
    80007caa:	f8040513          	addi	a0,s0,-128
    80007cae:	af1ff0ef          	jal	8000779e <xdr_encode_uint32>

  // AUTH_NULL verifier
  xdr_encode_uint32(&xdr, RPC_AUTH_NULL);
    80007cb2:	4581                	li	a1,0
    80007cb4:	f8040513          	addi	a0,s0,-128
    80007cb8:	ae7ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, 0);        // verf length
    80007cbc:	4581                	li	a1,0
    80007cbe:	f8040513          	addi	a0,s0,-128
    80007cc2:	addff0ef          	jal	8000779e <xdr_encode_uint32>

  // Append procedure arguments
  if(args && args_len > 0) {
    80007cc6:	02090063          	beqz	s2,80007ce6 <rpc_call+0x10e>
    80007cca:	01b05e63          	blez	s11,80007ce6 <rpc_call+0x10e>
    if(xdr.pos + args_len > sizeof(call_buf))
    80007cce:	f8842503          	lw	a0,-120(s0)
    80007cd2:	01b5073b          	addw	a4,a0,s11
    80007cd6:	47a1                	li	a5,8
    80007cd8:	1ee7e863          	bltu	a5,a4,80007ec8 <rpc_call+0x2f0>
      return -1;
    memmove(call_buf + xdr.pos, args, args_len);
    80007cdc:	866e                	mv	a2,s11
    80007cde:	85ca                	mv	a1,s2
    80007ce0:	9556                	add	a0,a0,s5
    80007ce2:	81cf90ef          	jal	80000cfe <memmove>
  }

  int total_len = xdr.pos + args_len;
    80007ce6:	f8842783          	lw	a5,-120(s0)
    80007cea:	01b78dbb          	addw	s11,a5,s11

  // Bind to temporary port for replies
  ushort reply_port = 7000 + (xid % 1000);
    80007cee:	3e800b13          	li	s6,1000
    80007cf2:	036c7b3b          	remuw	s6,s8,s6
    80007cf6:	6789                	lui	a5,0x2
    80007cf8:	b587879b          	addiw	a5,a5,-1192 # 1b58 <_entry-0x7fffe4a8>
    80007cfc:	00fb0b3b          	addw	s6,s6,a5
    80007d00:	1b42                	slli	s6,s6,0x30
    80007d02:	030b5b13          	srli	s6,s6,0x30
  int sock = udp_bind(reply_port, rpc_recv_handler);
    80007d06:	00000597          	auipc	a1,0x0
    80007d0a:	e1658593          	addi	a1,a1,-490 # 80007b1c <rpc_recv_handler>
    80007d0e:	855a                	mv	a0,s6
    80007d10:	fceff0ef          	jal	800074de <udp_bind>
    80007d14:	8baa                	mv	s7,a0
  if(sock < 0)
    80007d16:	1a054e63          	bltz	a0,80007ed2 <rpc_call+0x2fa>
    80007d1a:	f4e6                	sd	s9,104(sp)
    80007d1c:	4c8d                	li	s9,3
    return -1;

  // Send request with retries
  while(retries-- > 0) {
    if(udp_send(server_ip, port, reply_port, call_buf, total_len) < 0)
    80007d1e:	876e                	mv	a4,s11
    80007d20:	86d6                	mv	a3,s5
    80007d22:	865a                	mv	a2,s6
    80007d24:	f5043583          	ld	a1,-176(s0)
    80007d28:	f5843503          	ld	a0,-168(s0)
    80007d2c:	859ff0ef          	jal	80007584 <udp_send>
    80007d30:	02054e63          	bltz	a0,80007d6c <rpc_call+0x194>
    80007d34:	06400493          	li	s1,100
      continue;

    // Wait for reply with timeout
    int timeout = 100;  // ~1 second
    while(timeout-- > 0) {
      acquire(&rpc_lock);
    80007d38:	00025917          	auipc	s2,0x25
    80007d3c:	2a090913          	addi	s2,s2,672 # 8002cfd8 <rpc_lock>
      if(rpc_reply_received) {
    80007d40:	00007a17          	auipc	s4,0x7
    80007d44:	b80a0a13          	addi	s4,s4,-1152 # 8000e8c0 <rpc_reply_received>
        release(&rpc_lock);
        goto got_reply;
      }
      release(&rpc_lock);
    80007d48:	000f49b7          	lui	s3,0xf4
    80007d4c:	24098993          	addi	s3,s3,576 # f4240 <_entry-0x7ff0bdc0>
      acquire(&rpc_lock);
    80007d50:	854a                	mv	a0,s2
    80007d52:	e7df80ef          	jal	80000bce <acquire>
      if(rpc_reply_received) {
    80007d56:	000a2783          	lw	a5,0(s4)
    80007d5a:	e78d                	bnez	a5,80007d84 <rpc_call+0x1ac>
      release(&rpc_lock);
    80007d5c:	854a                	mv	a0,s2
    80007d5e:	f09f80ef          	jal	80000c66 <release>
    80007d62:	87ce                	mv	a5,s3

      // Simple busy-wait (in real impl, use sleep)
      for(int i = 0; i < 1000000; i++)
    80007d64:	37fd                	addiw	a5,a5,-1
    80007d66:	fffd                	bnez	a5,80007d64 <rpc_call+0x18c>
    while(timeout-- > 0) {
    80007d68:	34fd                	addiw	s1,s1,-1
    80007d6a:	f0fd                	bnez	s1,80007d50 <rpc_call+0x178>
  while(retries-- > 0) {
    80007d6c:	3cfd                	addiw	s9,s9,-1
    80007d6e:	fa0c98e3          	bnez	s9,80007d1e <rpc_call+0x146>
        ;
    }
  }

  // Timeout
  udp_unbind(sock);
    80007d72:	855e                	mv	a0,s7
    80007d74:	9cfff0ef          	jal	80007742 <udp_unbind>
  return -1;
    80007d78:	54fd                	li	s1,-1
    80007d7a:	6aaa                	ld	s5,136(sp)
    80007d7c:	7be6                	ld	s7,120(sp)
    80007d7e:	7c46                	ld	s8,112(sp)
    80007d80:	7ca6                	ld	s9,104(sp)
    80007d82:	a8c5                	j	80007e72 <rpc_call+0x29a>
        release(&rpc_lock);
    80007d84:	00025517          	auipc	a0,0x25
    80007d88:	25450513          	addi	a0,a0,596 # 8002cfd8 <rpc_lock>
    80007d8c:	edbf80ef          	jal	80000c66 <release>

got_reply:
  // Parse reply
  xdr_init(&xdr, rpc_reply_buf, rpc_reply_len);
    80007d90:	00007617          	auipc	a2,0x7
    80007d94:	b2c62603          	lw	a2,-1236(a2) # 8000e8bc <rpc_reply_len>
    80007d98:	00025597          	auipc	a1,0x25
    80007d9c:	25858593          	addi	a1,a1,600 # 8002cff0 <rpc_reply_buf>
    80007da0:	f8040513          	addi	a0,s0,-128
    80007da4:	9e7ff0ef          	jal	8000778a <xdr_init>

  uint32 reply_xid, msg_type, reply_stat, accept_stat;

  if(xdr_decode_uint32(&xdr, &reply_xid) < 0 ||
    80007da8:	f7c40593          	addi	a1,s0,-132
    80007dac:	f8040513          	addi	a0,s0,-128
    80007db0:	bb3ff0ef          	jal	80007962 <xdr_decode_uint32>
    80007db4:	0e054663          	bltz	a0,80007ea0 <rpc_call+0x2c8>
     xdr_decode_uint32(&xdr, &msg_type) < 0)
    80007db8:	f7840593          	addi	a1,s0,-136
    80007dbc:	f8040513          	addi	a0,s0,-128
    80007dc0:	ba3ff0ef          	jal	80007962 <xdr_decode_uint32>
  if(xdr_decode_uint32(&xdr, &reply_xid) < 0 ||
    80007dc4:	0c054e63          	bltz	a0,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  if(reply_xid != xid || msg_type != RPC_REPLY)
    80007dc8:	f7c42783          	lw	a5,-132(s0)
    80007dcc:	0d879a63          	bne	a5,s8,80007ea0 <rpc_call+0x2c8>
    80007dd0:	f7842703          	lw	a4,-136(s0)
    80007dd4:	4785                	li	a5,1
    80007dd6:	0cf71563          	bne	a4,a5,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  if(xdr_decode_uint32(&xdr, &reply_stat) < 0)
    80007dda:	f7440593          	addi	a1,s0,-140
    80007dde:	f8040513          	addi	a0,s0,-128
    80007de2:	b81ff0ef          	jal	80007962 <xdr_decode_uint32>
    80007de6:	0a054d63          	bltz	a0,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  if(reply_stat != RPC_MSG_ACCEPTED)
    80007dea:	f7442783          	lw	a5,-140(s0)
    80007dee:	ebcd                	bnez	a5,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  // Skip verifier
  uint32 verf_flavor, verf_len;
  if(xdr_decode_uint32(&xdr, &verf_flavor) < 0 ||
    80007df0:	f6c40593          	addi	a1,s0,-148
    80007df4:	f8040513          	addi	a0,s0,-128
    80007df8:	b6bff0ef          	jal	80007962 <xdr_decode_uint32>
    80007dfc:	0a054263          	bltz	a0,80007ea0 <rpc_call+0x2c8>
     xdr_decode_uint32(&xdr, &verf_len) < 0)
    80007e00:	f6840593          	addi	a1,s0,-152
    80007e04:	f8040513          	addi	a0,s0,-128
    80007e08:	b5bff0ef          	jal	80007962 <xdr_decode_uint32>
  if(xdr_decode_uint32(&xdr, &verf_flavor) < 0 ||
    80007e0c:	08054a63          	bltz	a0,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  xdr_skip(&xdr, verf_len);
    80007e10:	f6842583          	lw	a1,-152(s0)
    80007e14:	f8040513          	addi	a0,s0,-128
    80007e18:	cdfff0ef          	jal	80007af6 <xdr_skip>

  if(xdr_decode_uint32(&xdr, &accept_stat) < 0)
    80007e1c:	f7040593          	addi	a1,s0,-144
    80007e20:	f8040513          	addi	a0,s0,-128
    80007e24:	b3fff0ef          	jal	80007962 <xdr_decode_uint32>
    80007e28:	06054c63          	bltz	a0,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  if(accept_stat != RPC_SUCCESS)
    80007e2c:	f7042783          	lw	a5,-144(s0)
    80007e30:	eba5                	bnez	a5,80007ea0 <rpc_call+0x2c8>
    goto bad_reply;

  // Copy result
  int result_len = rpc_reply_len - xdr.pos;
    80007e32:	f8842703          	lw	a4,-120(s0)
    80007e36:	00007797          	auipc	a5,0x7
    80007e3a:	a867a783          	lw	a5,-1402(a5) # 8000e8bc <rpc_reply_len>
    80007e3e:	9f99                	subw	a5,a5,a4
  if(result_len > result_max)
    80007e40:	863e                	mv	a2,a5
    80007e42:	2781                	sext.w	a5,a5
    80007e44:	00fd5363          	bge	s10,a5,80007e4a <rpc_call+0x272>
    80007e48:	866a                	mv	a2,s10
    80007e4a:	0006049b          	sext.w	s1,a2
    result_len = result_max;
  if(result_len > 0)
    80007e4e:	02904e63          	bgtz	s1,80007e8a <rpc_call+0x2b2>
    memmove(result, rpc_reply_buf + xdr.pos, result_len);

  udp_unbind(sock);
    80007e52:	855e                	mv	a0,s7
    80007e54:	8efff0ef          	jal	80007742 <udp_unbind>
  release(&rpc_lock);
    80007e58:	00025517          	auipc	a0,0x25
    80007e5c:	18050513          	addi	a0,a0,384 # 8002cfd8 <rpc_lock>
    80007e60:	e07f80ef          	jal	80000c66 <release>
  kfree(call_buf);
    80007e64:	8556                	mv	a0,s5
    80007e66:	bb7f80ef          	jal	80000a1c <kfree>
  return result_len;
    80007e6a:	6aaa                	ld	s5,136(sp)
    80007e6c:	7be6                	ld	s7,120(sp)
    80007e6e:	7c46                	ld	s8,112(sp)
    80007e70:	7ca6                	ld	s9,104(sp)
bad_reply:
  udp_unbind(sock);
  release(&rpc_lock);
  kfree(call_buf);  
  return -1;
}
    80007e72:	8526                	mv	a0,s1
    80007e74:	70ea                	ld	ra,184(sp)
    80007e76:	744a                	ld	s0,176(sp)
    80007e78:	74aa                	ld	s1,168(sp)
    80007e7a:	790a                	ld	s2,160(sp)
    80007e7c:	69ea                	ld	s3,152(sp)
    80007e7e:	6a4a                	ld	s4,144(sp)
    80007e80:	6b0a                	ld	s6,128(sp)
    80007e82:	7d06                	ld	s10,96(sp)
    80007e84:	6de6                	ld	s11,88(sp)
    80007e86:	6129                	addi	sp,sp,192
    80007e88:	8082                	ret
    memmove(result, rpc_reply_buf + xdr.pos, result_len);
    80007e8a:	8626                	mv	a2,s1
    80007e8c:	00025597          	auipc	a1,0x25
    80007e90:	16458593          	addi	a1,a1,356 # 8002cff0 <rpc_reply_buf>
    80007e94:	95ba                	add	a1,a1,a4
    80007e96:	f4843503          	ld	a0,-184(s0)
    80007e9a:	e65f80ef          	jal	80000cfe <memmove>
    80007e9e:	bf55                	j	80007e52 <rpc_call+0x27a>
  udp_unbind(sock);
    80007ea0:	855e                	mv	a0,s7
    80007ea2:	8a1ff0ef          	jal	80007742 <udp_unbind>
  release(&rpc_lock);
    80007ea6:	00025517          	auipc	a0,0x25
    80007eaa:	13250513          	addi	a0,a0,306 # 8002cfd8 <rpc_lock>
    80007eae:	db9f80ef          	jal	80000c66 <release>
  kfree(call_buf);  
    80007eb2:	8556                	mv	a0,s5
    80007eb4:	b69f80ef          	jal	80000a1c <kfree>
  return -1;
    80007eb8:	54fd                	li	s1,-1
    80007eba:	6aaa                	ld	s5,136(sp)
    80007ebc:	7be6                	ld	s7,120(sp)
    80007ebe:	7c46                	ld	s8,112(sp)
    80007ec0:	7ca6                	ld	s9,104(sp)
    80007ec2:	bf45                	j	80007e72 <rpc_call+0x29a>
    return -1;
    80007ec4:	54fd                	li	s1,-1
    80007ec6:	b775                	j	80007e72 <rpc_call+0x29a>
      return -1;
    80007ec8:	54fd                	li	s1,-1
    80007eca:	6aaa                	ld	s5,136(sp)
    80007ecc:	7be6                	ld	s7,120(sp)
    80007ece:	7c46                	ld	s8,112(sp)
    80007ed0:	b74d                	j	80007e72 <rpc_call+0x29a>
    return -1;
    80007ed2:	54fd                	li	s1,-1
    80007ed4:	6aaa                	ld	s5,136(sp)
    80007ed6:	7be6                	ld	s7,120(sp)
    80007ed8:	7c46                	ld	s8,112(sp)
    80007eda:	bf61                	j	80007e72 <rpc_call+0x29a>

0000000080007edc <nfs_null>:
#include "nfs.h"

// NULL procedure (ping)
int
nfs_null(struct nfs_mount *mnt)
{
    80007edc:	712d                	addi	sp,sp,-288
    80007ede:	ee06                	sd	ra,280(sp)
    80007ee0:	ea22                	sd	s0,272(sp)
    80007ee2:	1200                	addi	s0,sp,288
  uchar result[256];

  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
    80007ee4:	10000793          	li	a5,256
    80007ee8:	e03e                	sd	a5,0(sp)
    80007eea:	ef040893          	addi	a7,s0,-272
    80007eee:	4801                	li	a6,0
    80007ef0:	4781                	li	a5,0
    80007ef2:	4701                	li	a4,0
    80007ef4:	4689                	li	a3,2
    80007ef6:	6661                	lui	a2,0x18
    80007ef8:	6a360613          	addi	a2,a2,1699 # 186a3 <_entry-0x7ffe795d>
    80007efc:	00455583          	lhu	a1,4(a0)
    80007f00:	4108                	lw	a0,0(a0)
    80007f02:	cd7ff0ef          	jal	80007bd8 <rpc_call>
                     NFSPROC_NULL, 0, 0, result, sizeof(result));

  return len >= 0 ? 0 : -1;
}
    80007f06:	41f5551b          	sraiw	a0,a0,0x1f
    80007f0a:	60f2                	ld	ra,280(sp)
    80007f0c:	6452                	ld	s0,272(sp)
    80007f0e:	6115                	addi	sp,sp,288
    80007f10:	8082                	ret

0000000080007f12 <nfs_getattr>:

// Get file attributes
int
nfs_getattr(struct nfs_mount *mnt, struct nfs_fh *fh, struct nfs_fattr *attr)
{
    80007f12:	d2010113          	addi	sp,sp,-736
    80007f16:	2c113c23          	sd	ra,728(sp)
    80007f1a:	2c813823          	sd	s0,720(sp)
    80007f1e:	2c913423          	sd	s1,712(sp)
    80007f22:	2d213023          	sd	s2,704(sp)
    80007f26:	2b313c23          	sd	s3,696(sp)
    80007f2a:	1580                	addi	s0,sp,736
    80007f2c:	892a                	mv	s2,a0
    80007f2e:	89ae                	mv	s3,a1
    80007f30:	84b2                	mv	s1,a2
  uchar args[128];
  uchar result[512];
  struct xdr_buf xdr;

  // Encode arguments (file handle)
  xdr_init(&xdr, args, sizeof(args));
    80007f32:	08000613          	li	a2,128
    80007f36:	f5040593          	addi	a1,s0,-176
    80007f3a:	d4040513          	addi	a0,s0,-704
    80007f3e:	84dff0ef          	jal	8000778a <xdr_init>
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);
    80007f42:	02000613          	li	a2,32
    80007f46:	85ce                	mv	a1,s3
    80007f48:	d4040513          	addi	a0,s0,-704
    80007f4c:	983ff0ef          	jal	800078ce <xdr_encode_opaque>

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
    80007f50:	20000793          	li	a5,512
    80007f54:	e03e                	sd	a5,0(sp)
    80007f56:	d5040893          	addi	a7,s0,-688
    80007f5a:	d4842803          	lw	a6,-696(s0)
    80007f5e:	f5040793          	addi	a5,s0,-176
    80007f62:	4705                	li	a4,1
    80007f64:	4689                	li	a3,2
    80007f66:	6661                	lui	a2,0x18
    80007f68:	6a360613          	addi	a2,a2,1699 # 186a3 <_entry-0x7ffe795d>
    80007f6c:	00495583          	lhu	a1,4(s2)
    80007f70:	00092503          	lw	a0,0(s2)
    80007f74:	c65ff0ef          	jal	80007bd8 <rpc_call>
                     NFSPROC_GETATTR, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    80007f78:	14054963          	bltz	a0,800080ca <nfs_getattr+0x1b8>
    80007f7c:	862a                	mv	a2,a0
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
    80007f7e:	d5040593          	addi	a1,s0,-688
    80007f82:	d4040513          	addi	a0,s0,-704
    80007f86:	805ff0ef          	jal	8000778a <xdr_init>

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    80007f8a:	d3c40593          	addi	a1,s0,-708
    80007f8e:	d4040513          	addi	a0,s0,-704
    80007f92:	9d1ff0ef          	jal	80007962 <xdr_decode_uint32>
    80007f96:	12054c63          	bltz	a0,800080ce <nfs_getattr+0x1bc>
    return -1;

  if(status != NFS_OK)
    80007f9a:	d3c42783          	lw	a5,-708(s0)
    80007f9e:	12079a63          	bnez	a5,800080d2 <nfs_getattr+0x1c0>
    return -1;

  // Decode attributes
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
    80007fa2:	85a6                	mv	a1,s1
    80007fa4:	d4040513          	addi	a0,s0,-704
    80007fa8:	9bbff0ef          	jal	80007962 <xdr_decode_uint32>
    80007fac:	12054563          	bltz	a0,800080d6 <nfs_getattr+0x1c4>
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
    80007fb0:	00448593          	addi	a1,s1,4
    80007fb4:	d4040513          	addi	a0,s0,-704
    80007fb8:	9abff0ef          	jal	80007962 <xdr_decode_uint32>
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
    80007fbc:	10054f63          	bltz	a0,800080da <nfs_getattr+0x1c8>
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
    80007fc0:	00848593          	addi	a1,s1,8
    80007fc4:	d4040513          	addi	a0,s0,-704
    80007fc8:	99bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
    80007fcc:	10054963          	bltz	a0,800080de <nfs_getattr+0x1cc>
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
    80007fd0:	00c48593          	addi	a1,s1,12
    80007fd4:	d4040513          	addi	a0,s0,-704
    80007fd8:	98bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
    80007fdc:	10054363          	bltz	a0,800080e2 <nfs_getattr+0x1d0>
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
    80007fe0:	01048593          	addi	a1,s1,16
    80007fe4:	d4040513          	addi	a0,s0,-704
    80007fe8:	97bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
    80007fec:	0e054d63          	bltz	a0,800080e6 <nfs_getattr+0x1d4>
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
    80007ff0:	01448593          	addi	a1,s1,20
    80007ff4:	d4040513          	addi	a0,s0,-704
    80007ff8:	96bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
    80007ffc:	0e054763          	bltz	a0,800080ea <nfs_getattr+0x1d8>
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
    80008000:	01848593          	addi	a1,s1,24
    80008004:	d4040513          	addi	a0,s0,-704
    80008008:	95bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
    8000800c:	0e054163          	bltz	a0,800080ee <nfs_getattr+0x1dc>
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
    80008010:	01c48593          	addi	a1,s1,28
    80008014:	d4040513          	addi	a0,s0,-704
    80008018:	94bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
    8000801c:	0c054b63          	bltz	a0,800080f2 <nfs_getattr+0x1e0>
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
    80008020:	02048593          	addi	a1,s1,32
    80008024:	d4040513          	addi	a0,s0,-704
    80008028:	93bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
    8000802c:	0c054563          	bltz	a0,800080f6 <nfs_getattr+0x1e4>
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
    80008030:	02448593          	addi	a1,s1,36
    80008034:	d4040513          	addi	a0,s0,-704
    80008038:	92bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
    8000803c:	0a054f63          	bltz	a0,800080fa <nfs_getattr+0x1e8>
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
    80008040:	02848593          	addi	a1,s1,40
    80008044:	d4040513          	addi	a0,s0,-704
    80008048:	91bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
    8000804c:	0a054963          	bltz	a0,800080fe <nfs_getattr+0x1ec>
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
    80008050:	02c48593          	addi	a1,s1,44
    80008054:	d4040513          	addi	a0,s0,-704
    80008058:	90bff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
    8000805c:	0a054363          	bltz	a0,80008102 <nfs_getattr+0x1f0>
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
    80008060:	03048593          	addi	a1,s1,48
    80008064:	d4040513          	addi	a0,s0,-704
    80008068:	8fbff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
    8000806c:	08054d63          	bltz	a0,80008106 <nfs_getattr+0x1f4>
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
    80008070:	03448593          	addi	a1,s1,52
    80008074:	d4040513          	addi	a0,s0,-704
    80008078:	8ebff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
    8000807c:	08054763          	bltz	a0,8000810a <nfs_getattr+0x1f8>
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
    80008080:	03848593          	addi	a1,s1,56
    80008084:	d4040513          	addi	a0,s0,-704
    80008088:	8dbff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
    8000808c:	08054163          	bltz	a0,8000810e <nfs_getattr+0x1fc>
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
    80008090:	03c48593          	addi	a1,s1,60
    80008094:	d4040513          	addi	a0,s0,-704
    80008098:	8cbff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
    8000809c:	06054b63          	bltz	a0,80008112 <nfs_getattr+0x200>
     xdr_decode_uint32(&xdr, &attr->ctime_usec) < 0)
    800080a0:	04048593          	addi	a1,s1,64
    800080a4:	d4040513          	addi	a0,s0,-704
    800080a8:	8bbff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
    800080ac:	41f5551b          	sraiw	a0,a0,0x1f
    return -1;

  return 0;
}
    800080b0:	2d813083          	ld	ra,728(sp)
    800080b4:	2d013403          	ld	s0,720(sp)
    800080b8:	2c813483          	ld	s1,712(sp)
    800080bc:	2c013903          	ld	s2,704(sp)
    800080c0:	2b813983          	ld	s3,696(sp)
    800080c4:	2e010113          	addi	sp,sp,736
    800080c8:	8082                	ret
    return -1;
    800080ca:	557d                	li	a0,-1
    800080cc:	b7d5                	j	800080b0 <nfs_getattr+0x19e>
    return -1;
    800080ce:	557d                	li	a0,-1
    800080d0:	b7c5                	j	800080b0 <nfs_getattr+0x19e>
    return -1;
    800080d2:	557d                	li	a0,-1
    800080d4:	bff1                	j	800080b0 <nfs_getattr+0x19e>
    return -1;
    800080d6:	557d                	li	a0,-1
    800080d8:	bfe1                	j	800080b0 <nfs_getattr+0x19e>
    800080da:	557d                	li	a0,-1
    800080dc:	bfd1                	j	800080b0 <nfs_getattr+0x19e>
    800080de:	557d                	li	a0,-1
    800080e0:	bfc1                	j	800080b0 <nfs_getattr+0x19e>
    800080e2:	557d                	li	a0,-1
    800080e4:	b7f1                	j	800080b0 <nfs_getattr+0x19e>
    800080e6:	557d                	li	a0,-1
    800080e8:	b7e1                	j	800080b0 <nfs_getattr+0x19e>
    800080ea:	557d                	li	a0,-1
    800080ec:	b7d1                	j	800080b0 <nfs_getattr+0x19e>
    800080ee:	557d                	li	a0,-1
    800080f0:	b7c1                	j	800080b0 <nfs_getattr+0x19e>
    800080f2:	557d                	li	a0,-1
    800080f4:	bf75                	j	800080b0 <nfs_getattr+0x19e>
    800080f6:	557d                	li	a0,-1
    800080f8:	bf65                	j	800080b0 <nfs_getattr+0x19e>
    800080fa:	557d                	li	a0,-1
    800080fc:	bf55                	j	800080b0 <nfs_getattr+0x19e>
    800080fe:	557d                	li	a0,-1
    80008100:	bf45                	j	800080b0 <nfs_getattr+0x19e>
    80008102:	557d                	li	a0,-1
    80008104:	b775                	j	800080b0 <nfs_getattr+0x19e>
    80008106:	557d                	li	a0,-1
    80008108:	b765                	j	800080b0 <nfs_getattr+0x19e>
    8000810a:	557d                	li	a0,-1
    8000810c:	b755                	j	800080b0 <nfs_getattr+0x19e>
    8000810e:	557d                	li	a0,-1
    80008110:	b745                	j	800080b0 <nfs_getattr+0x19e>
    80008112:	557d                	li	a0,-1
    80008114:	bf71                	j	800080b0 <nfs_getattr+0x19e>

0000000080008116 <nfs_lookup>:

// Look up a file name in a directory
int
nfs_lookup(struct nfs_mount *mnt, struct nfs_fh *dir_fh, const char *name,
           struct nfs_fh *fh, struct nfs_fattr *attr)
{
    80008116:	99010113          	addi	sp,sp,-1648
    8000811a:	66113423          	sd	ra,1640(sp)
    8000811e:	66813023          	sd	s0,1632(sp)
    80008122:	64913c23          	sd	s1,1624(sp)
    80008126:	65213823          	sd	s2,1616(sp)
    8000812a:	65313423          	sd	s3,1608(sp)
    8000812e:	65413023          	sd	s4,1600(sp)
    80008132:	63513c23          	sd	s5,1592(sp)
    80008136:	67010413          	addi	s0,sp,1648
    8000813a:	892a                	mv	s2,a0
    8000813c:	8a2e                	mv	s4,a1
    8000813e:	89b2                	mv	s3,a2
    80008140:	8ab6                	mv	s5,a3
    80008142:	84ba                	mv	s1,a4
  uchar args[512];
  uchar result[1024];
  struct xdr_buf xdr;

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
    80008144:	20000613          	li	a2,512
    80008148:	dc040593          	addi	a1,s0,-576
    8000814c:	9b040513          	addi	a0,s0,-1616
    80008150:	e3aff0ef          	jal	8000778a <xdr_init>
  xdr_encode_opaque(&xdr, dir_fh->data, NFS_FHSIZE);
    80008154:	02000613          	li	a2,32
    80008158:	85d2                	mv	a1,s4
    8000815a:	9b040513          	addi	a0,s0,-1616
    8000815e:	f70ff0ef          	jal	800078ce <xdr_encode_opaque>
  xdr_encode_string(&xdr, name);
    80008162:	85ce                	mv	a1,s3
    80008164:	9b040513          	addi	a0,s0,-1616
    80008168:	fceff0ef          	jal	80007936 <xdr_encode_string>

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
    8000816c:	40000793          	li	a5,1024
    80008170:	e03e                	sd	a5,0(sp)
    80008172:	9c040893          	addi	a7,s0,-1600
    80008176:	9b842803          	lw	a6,-1608(s0)
    8000817a:	dc040793          	addi	a5,s0,-576
    8000817e:	4711                	li	a4,4
    80008180:	4689                	li	a3,2
    80008182:	6661                	lui	a2,0x18
    80008184:	6a360613          	addi	a2,a2,1699 # 186a3 <_entry-0x7ffe795d>
    80008188:	00495583          	lhu	a1,4(s2)
    8000818c:	00092503          	lw	a0,0(s2)
    80008190:	a49ff0ef          	jal	80007bd8 <rpc_call>
                     NFSPROC_LOOKUP, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    80008194:	16054663          	bltz	a0,80008300 <nfs_lookup+0x1ea>
    80008198:	862a                	mv	a2,a0
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
    8000819a:	9c040593          	addi	a1,s0,-1600
    8000819e:	9b040513          	addi	a0,s0,-1616
    800081a2:	de8ff0ef          	jal	8000778a <xdr_init>

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    800081a6:	9ac40593          	addi	a1,s0,-1620
    800081aa:	9b040513          	addi	a0,s0,-1616
    800081ae:	fb4ff0ef          	jal	80007962 <xdr_decode_uint32>
    800081b2:	14054963          	bltz	a0,80008304 <nfs_lookup+0x1ee>
    return -1;

  if(status != NFS_OK)
    800081b6:	9ac42783          	lw	a5,-1620(s0)
    800081ba:	14079763          	bnez	a5,80008308 <nfs_lookup+0x1f2>
    return -1;

  // Decode file handle
  if(xdr_decode_opaque(&xdr, fh->data, NFS_FHSIZE) < 0)
    800081be:	02000613          	li	a2,32
    800081c2:	85d6                	mv	a1,s5
    800081c4:	9b040513          	addi	a0,s0,-1616
    800081c8:	8b1ff0ef          	jal	80007a78 <xdr_decode_opaque>
    800081cc:	14054063          	bltz	a0,8000830c <nfs_lookup+0x1f6>
    return -1;

  // Decode attributes
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
    800081d0:	85a6                	mv	a1,s1
    800081d2:	9b040513          	addi	a0,s0,-1616
    800081d6:	f8cff0ef          	jal	80007962 <xdr_decode_uint32>
    800081da:	12054b63          	bltz	a0,80008310 <nfs_lookup+0x1fa>
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
    800081de:	00448593          	addi	a1,s1,4
    800081e2:	9b040513          	addi	a0,s0,-1616
    800081e6:	f7cff0ef          	jal	80007962 <xdr_decode_uint32>
  if(xdr_decode_uint32(&xdr, &attr->type) < 0 ||
    800081ea:	12054563          	bltz	a0,80008314 <nfs_lookup+0x1fe>
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
    800081ee:	00848593          	addi	a1,s1,8
    800081f2:	9b040513          	addi	a0,s0,-1616
    800081f6:	f6cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mode) < 0 ||
    800081fa:	10054f63          	bltz	a0,80008318 <nfs_lookup+0x202>
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
    800081fe:	00c48593          	addi	a1,s1,12
    80008202:	9b040513          	addi	a0,s0,-1616
    80008206:	f5cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->nlink) < 0 ||
    8000820a:	10054963          	bltz	a0,8000831c <nfs_lookup+0x206>
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
    8000820e:	01048593          	addi	a1,s1,16
    80008212:	9b040513          	addi	a0,s0,-1616
    80008216:	f4cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->uid) < 0 ||
    8000821a:	10054363          	bltz	a0,80008320 <nfs_lookup+0x20a>
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
    8000821e:	01448593          	addi	a1,s1,20
    80008222:	9b040513          	addi	a0,s0,-1616
    80008226:	f3cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->gid) < 0 ||
    8000822a:	0e054d63          	bltz	a0,80008324 <nfs_lookup+0x20e>
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
    8000822e:	01848593          	addi	a1,s1,24
    80008232:	9b040513          	addi	a0,s0,-1616
    80008236:	f2cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->size) < 0 ||
    8000823a:	0e054763          	bltz	a0,80008328 <nfs_lookup+0x212>
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
    8000823e:	01c48593          	addi	a1,s1,28
    80008242:	9b040513          	addi	a0,s0,-1616
    80008246:	f1cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->blocksize) < 0 ||
    8000824a:	0e054163          	bltz	a0,8000832c <nfs_lookup+0x216>
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
    8000824e:	02048593          	addi	a1,s1,32
    80008252:	9b040513          	addi	a0,s0,-1616
    80008256:	f0cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->rdev) < 0 ||
    8000825a:	0c054b63          	bltz	a0,80008330 <nfs_lookup+0x21a>
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
    8000825e:	02448593          	addi	a1,s1,36
    80008262:	9b040513          	addi	a0,s0,-1616
    80008266:	efcff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->blocks) < 0 ||
    8000826a:	0c054563          	bltz	a0,80008334 <nfs_lookup+0x21e>
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
    8000826e:	02848593          	addi	a1,s1,40
    80008272:	9b040513          	addi	a0,s0,-1616
    80008276:	eecff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->fsid) < 0 ||
    8000827a:	0a054f63          	bltz	a0,80008338 <nfs_lookup+0x222>
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
    8000827e:	02c48593          	addi	a1,s1,44
    80008282:	9b040513          	addi	a0,s0,-1616
    80008286:	edcff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->fileid) < 0 ||
    8000828a:	0a054963          	bltz	a0,8000833c <nfs_lookup+0x226>
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
    8000828e:	03048593          	addi	a1,s1,48
    80008292:	9b040513          	addi	a0,s0,-1616
    80008296:	eccff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->atime_sec) < 0 ||
    8000829a:	0a054363          	bltz	a0,80008340 <nfs_lookup+0x22a>
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
    8000829e:	03448593          	addi	a1,s1,52
    800082a2:	9b040513          	addi	a0,s0,-1616
    800082a6:	ebcff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->atime_usec) < 0 ||
    800082aa:	08054d63          	bltz	a0,80008344 <nfs_lookup+0x22e>
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
    800082ae:	03848593          	addi	a1,s1,56
    800082b2:	9b040513          	addi	a0,s0,-1616
    800082b6:	eacff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mtime_sec) < 0 ||
    800082ba:	08054763          	bltz	a0,80008348 <nfs_lookup+0x232>
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
    800082be:	03c48593          	addi	a1,s1,60
    800082c2:	9b040513          	addi	a0,s0,-1616
    800082c6:	e9cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->mtime_usec) < 0 ||
    800082ca:	08054163          	bltz	a0,8000834c <nfs_lookup+0x236>
     xdr_decode_uint32(&xdr, &attr->ctime_usec) < 0)
    800082ce:	04048593          	addi	a1,s1,64
    800082d2:	9b040513          	addi	a0,s0,-1616
    800082d6:	e8cff0ef          	jal	80007962 <xdr_decode_uint32>
     xdr_decode_uint32(&xdr, &attr->ctime_sec) < 0 ||
    800082da:	41f5551b          	sraiw	a0,a0,0x1f
    return -1;

  return 0;
}
    800082de:	66813083          	ld	ra,1640(sp)
    800082e2:	66013403          	ld	s0,1632(sp)
    800082e6:	65813483          	ld	s1,1624(sp)
    800082ea:	65013903          	ld	s2,1616(sp)
    800082ee:	64813983          	ld	s3,1608(sp)
    800082f2:	64013a03          	ld	s4,1600(sp)
    800082f6:	63813a83          	ld	s5,1592(sp)
    800082fa:	67010113          	addi	sp,sp,1648
    800082fe:	8082                	ret
    return -1;
    80008300:	557d                	li	a0,-1
    80008302:	bff1                	j	800082de <nfs_lookup+0x1c8>
    return -1;
    80008304:	557d                	li	a0,-1
    80008306:	bfe1                	j	800082de <nfs_lookup+0x1c8>
    return -1;
    80008308:	557d                	li	a0,-1
    8000830a:	bfd1                	j	800082de <nfs_lookup+0x1c8>
    return -1;
    8000830c:	557d                	li	a0,-1
    8000830e:	bfc1                	j	800082de <nfs_lookup+0x1c8>
    return -1;
    80008310:	557d                	li	a0,-1
    80008312:	b7f1                	j	800082de <nfs_lookup+0x1c8>
    80008314:	557d                	li	a0,-1
    80008316:	b7e1                	j	800082de <nfs_lookup+0x1c8>
    80008318:	557d                	li	a0,-1
    8000831a:	b7d1                	j	800082de <nfs_lookup+0x1c8>
    8000831c:	557d                	li	a0,-1
    8000831e:	b7c1                	j	800082de <nfs_lookup+0x1c8>
    80008320:	557d                	li	a0,-1
    80008322:	bf75                	j	800082de <nfs_lookup+0x1c8>
    80008324:	557d                	li	a0,-1
    80008326:	bf65                	j	800082de <nfs_lookup+0x1c8>
    80008328:	557d                	li	a0,-1
    8000832a:	bf55                	j	800082de <nfs_lookup+0x1c8>
    8000832c:	557d                	li	a0,-1
    8000832e:	bf45                	j	800082de <nfs_lookup+0x1c8>
    80008330:	557d                	li	a0,-1
    80008332:	b775                	j	800082de <nfs_lookup+0x1c8>
    80008334:	557d                	li	a0,-1
    80008336:	b765                	j	800082de <nfs_lookup+0x1c8>
    80008338:	557d                	li	a0,-1
    8000833a:	b755                	j	800082de <nfs_lookup+0x1c8>
    8000833c:	557d                	li	a0,-1
    8000833e:	b745                	j	800082de <nfs_lookup+0x1c8>
    80008340:	557d                	li	a0,-1
    80008342:	bf71                	j	800082de <nfs_lookup+0x1c8>
    80008344:	557d                	li	a0,-1
    80008346:	bf61                	j	800082de <nfs_lookup+0x1c8>
    80008348:	557d                	li	a0,-1
    8000834a:	bf51                	j	800082de <nfs_lookup+0x1c8>
    8000834c:	557d                	li	a0,-1
    8000834e:	bf41                	j	800082de <nfs_lookup+0x1c8>

0000000080008350 <nfs_read>:

// Read from a file
int
nfs_read(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
         uint32 count, void *buf, uint32 *bytes_read)
{
    80008350:	7109                	addi	sp,sp,-384
    80008352:	fe86                	sd	ra,376(sp)
    80008354:	faa2                	sd	s0,368(sp)
    80008356:	f6a6                	sd	s1,360(sp)
    80008358:	f2ca                	sd	s2,352(sp)
    8000835a:	eece                	sd	s3,344(sp)
    8000835c:	ead2                	sd	s4,336(sp)
    8000835e:	e6d6                	sd	s5,328(sp)
    80008360:	e2da                	sd	s6,320(sp)
    80008362:	fe5e                	sd	s7,312(sp)
    80008364:	fa62                	sd	s8,304(sp)
    80008366:	0300                	addi	s0,sp,384
    80008368:	89aa                	mv	s3,a0
    8000836a:	8bae                	mv	s7,a1
    8000836c:	8b32                	mv	s6,a2
    8000836e:	8aba                	mv	s5,a4
    80008370:	8a3e                	mv	s4,a5
  uchar args[256];
  uchar *result;
  struct xdr_buf xdr;

  // Limit read size
  if(count > 8192)
    80008372:	8936                	mv	s2,a3
    80008374:	6789                	lui	a5,0x2
    80008376:	00d7f363          	bgeu	a5,a3,8000837c <nfs_read+0x2c>
    8000837a:	6909                	lui	s2,0x2
    8000837c:	00090c1b          	sext.w	s8,s2
    count = 8192;

  result = (uchar*)kalloc();
    80008380:	f7ef80ef          	jal	80000afe <kalloc>
    80008384:	84aa                	mv	s1,a0
  if(result == 0)
    80008386:	0e050463          	beqz	a0,8000846e <nfs_read+0x11e>
    return -1;
  memset(result, 0, PGSIZE);
    8000838a:	6605                	lui	a2,0x1
    8000838c:	4581                	li	a1,0
    8000838e:	915f80ef          	jal	80000ca2 <memset>

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
    80008392:	10000613          	li	a2,256
    80008396:	eb040593          	addi	a1,s0,-336
    8000839a:	ea040513          	addi	a0,s0,-352
    8000839e:	becff0ef          	jal	8000778a <xdr_init>
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);
    800083a2:	02000613          	li	a2,32
    800083a6:	85de                	mv	a1,s7
    800083a8:	ea040513          	addi	a0,s0,-352
    800083ac:	d22ff0ef          	jal	800078ce <xdr_encode_opaque>
  xdr_encode_uint32(&xdr, offset);
    800083b0:	85da                	mv	a1,s6
    800083b2:	ea040513          	addi	a0,s0,-352
    800083b6:	be8ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, count);
    800083ba:	85e2                	mv	a1,s8
    800083bc:	ea040513          	addi	a0,s0,-352
    800083c0:	bdeff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, 0);  // totalcount (unused in NFS v2)
    800083c4:	4581                	li	a1,0
    800083c6:	ea040513          	addi	a0,s0,-352
    800083ca:	bd4ff0ef          	jal	8000779e <xdr_encode_uint32>

  if (count > 4000) count = 4000;
    800083ce:	864a                	mv	a2,s2
    800083d0:	6785                	lui	a5,0x1
    800083d2:	fa078793          	addi	a5,a5,-96 # fa0 <_entry-0x7ffff060>
    800083d6:	0187f563          	bgeu	a5,s8,800083e0 <nfs_read+0x90>
    800083da:	6605                	lui	a2,0x1
    800083dc:	fa06061b          	addiw	a2,a2,-96 # fa0 <_entry-0x7ffff060>
    800083e0:	0006091b          	sext.w	s2,a2

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
    800083e4:	47a1                	li	a5,8
    800083e6:	e03e                	sd	a5,0(sp)
    800083e8:	88a6                	mv	a7,s1
    800083ea:	ea842803          	lw	a6,-344(s0)
    800083ee:	eb040793          	addi	a5,s0,-336
    800083f2:	4719                	li	a4,6
    800083f4:	4689                	li	a3,2
    800083f6:	6661                	lui	a2,0x18
    800083f8:	6a360613          	addi	a2,a2,1699 # 186a3 <_entry-0x7ffe795d>
    800083fc:	0049d583          	lhu	a1,4(s3)
    80008400:	0009a503          	lw	a0,0(s3)
    80008404:	fd4ff0ef          	jal	80007bd8 <rpc_call>
    80008408:	862a                	mv	a2,a0
                     NFSPROC_READ, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    8000840a:	06054463          	bltz	a0,80008472 <nfs_read+0x122>
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
    8000840e:	85a6                	mv	a1,s1
    80008410:	ea040513          	addi	a0,s0,-352
    80008414:	b76ff0ef          	jal	8000778a <xdr_init>

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    80008418:	e9c40593          	addi	a1,s0,-356
    8000841c:	ea040513          	addi	a0,s0,-352
    80008420:	d42ff0ef          	jal	80007962 <xdr_decode_uint32>
    80008424:	04054963          	bltz	a0,80008476 <nfs_read+0x126>
    return -1;

  if(status != NFS_OK)
    80008428:	e9c42783          	lw	a5,-356(s0)
    8000842c:	e7b9                	bnez	a5,8000847a <nfs_read+0x12a>
    return -1;

  // Skip attributes (17 uint32s)
  xdr_skip(&xdr, 17 * 4);
    8000842e:	04400593          	li	a1,68
    80008432:	ea040513          	addi	a0,s0,-352
    80008436:	ec0ff0ef          	jal	80007af6 <xdr_skip>

  // Decode data
  int data_len = xdr_decode_bytes(&xdr, buf, count);
    8000843a:	864a                	mv	a2,s2
    8000843c:	85d6                	mv	a1,s5
    8000843e:	ea040513          	addi	a0,s0,-352
    80008442:	dbcff0ef          	jal	800079fe <xdr_decode_bytes>
  if(data_len < 0)
    80008446:	02054c63          	bltz	a0,8000847e <nfs_read+0x12e>
    return -1;

  *bytes_read = data_len;
    8000844a:	00aa2023          	sw	a0,0(s4)
  kfree(result);
    8000844e:	8526                	mv	a0,s1
    80008450:	dccf80ef          	jal	80000a1c <kfree>
  return 0;
    80008454:	4501                	li	a0,0
}
    80008456:	70f6                	ld	ra,376(sp)
    80008458:	7456                	ld	s0,368(sp)
    8000845a:	74b6                	ld	s1,360(sp)
    8000845c:	7916                	ld	s2,352(sp)
    8000845e:	69f6                	ld	s3,344(sp)
    80008460:	6a56                	ld	s4,336(sp)
    80008462:	6ab6                	ld	s5,328(sp)
    80008464:	6b16                	ld	s6,320(sp)
    80008466:	7bf2                	ld	s7,312(sp)
    80008468:	7c52                	ld	s8,304(sp)
    8000846a:	6119                	addi	sp,sp,384
    8000846c:	8082                	ret
    return -1;
    8000846e:	557d                	li	a0,-1
    80008470:	b7dd                	j	80008456 <nfs_read+0x106>
    return -1;
    80008472:	557d                	li	a0,-1
    80008474:	b7cd                	j	80008456 <nfs_read+0x106>
    return -1;
    80008476:	557d                	li	a0,-1
    80008478:	bff9                	j	80008456 <nfs_read+0x106>
    return -1;
    8000847a:	557d                	li	a0,-1
    8000847c:	bfe9                	j	80008456 <nfs_read+0x106>
    return -1;
    8000847e:	557d                	li	a0,-1
    80008480:	bfd9                	j	80008456 <nfs_read+0x106>

0000000080008482 <nfs_write>:

// Write to a file
int
nfs_write(struct nfs_mount *mnt, struct nfs_fh *fh, uint32 offset,
          uint32 count, void *buf)
{
    80008482:	d9010113          	addi	sp,sp,-624
    80008486:	26113423          	sd	ra,616(sp)
    8000848a:	26813023          	sd	s0,608(sp)
    8000848e:	24913c23          	sd	s1,600(sp)
    80008492:	25213823          	sd	s2,592(sp)
    80008496:	25313423          	sd	s3,584(sp)
    8000849a:	25413023          	sd	s4,576(sp)
    8000849e:	23513c23          	sd	s5,568(sp)
    800084a2:	23613823          	sd	s6,560(sp)
    800084a6:	1c80                	addi	s0,sp,624
    800084a8:	89aa                	mv	s3,a0
    800084aa:	8b2e                	mv	s6,a1
    800084ac:	8ab2                	mv	s5,a2
    800084ae:	8a3a                	mv	s4,a4
  uchar *args;
  uchar result[512];
  struct xdr_buf xdr;

  // Limit write size
  if(count > 4000)
    800084b0:	8936                	mv	s2,a3
    800084b2:	6785                	lui	a5,0x1
    800084b4:	fa078793          	addi	a5,a5,-96 # fa0 <_entry-0x7ffff060>
    800084b8:	00d7f563          	bgeu	a5,a3,800084c2 <nfs_write+0x40>
    800084bc:	6905                	lui	s2,0x1
    800084be:	fa09091b          	addiw	s2,s2,-96 # fa0 <_entry-0x7ffff060>
    count = 4000;

  args = (uchar*)kalloc();
    800084c2:	e3cf80ef          	jal	80000afe <kalloc>
    800084c6:	84aa                	mv	s1,a0
  if(args == 0)
    800084c8:	c571                	beqz	a0,80008594 <nfs_write+0x112>
    return -1;
  memset(args, 0, PGSIZE);
    800084ca:	6605                	lui	a2,0x1
    800084cc:	4581                	li	a1,0
    800084ce:	fd4f80ef          	jal	80000ca2 <memset>

  // Encode arguments
  xdr_init(&xdr, args, sizeof(args));
    800084d2:	4621                	li	a2,8
    800084d4:	85a6                	mv	a1,s1
    800084d6:	db040513          	addi	a0,s0,-592
    800084da:	ab0ff0ef          	jal	8000778a <xdr_init>
  xdr_encode_opaque(&xdr, fh->data, NFS_FHSIZE);
    800084de:	02000613          	li	a2,32
    800084e2:	85da                	mv	a1,s6
    800084e4:	db040513          	addi	a0,s0,-592
    800084e8:	be6ff0ef          	jal	800078ce <xdr_encode_opaque>
  xdr_encode_uint32(&xdr, 0);      // beginoffset (unused)
    800084ec:	4581                	li	a1,0
    800084ee:	db040513          	addi	a0,s0,-592
    800084f2:	aacff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, offset);
    800084f6:	85d6                	mv	a1,s5
    800084f8:	db040513          	addi	a0,s0,-592
    800084fc:	aa2ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_uint32(&xdr, 0);      // totalcount (unused)
    80008500:	4581                	li	a1,0
    80008502:	db040513          	addi	a0,s0,-592
    80008506:	a98ff0ef          	jal	8000779e <xdr_encode_uint32>
  xdr_encode_bytes(&xdr, buf, count);
    8000850a:	2901                	sext.w	s2,s2
    8000850c:	864a                	mv	a2,s2
    8000850e:	85d2                	mv	a1,s4
    80008510:	db040513          	addi	a0,s0,-592
    80008514:	b2aff0ef          	jal	8000783e <xdr_encode_bytes>

  // Make RPC call
  int len = rpc_call(mnt->server_ip, mnt->port, NFS_PROGRAM, NFS_VERSION,
    80008518:	20000793          	li	a5,512
    8000851c:	e03e                	sd	a5,0(sp)
    8000851e:	dc040893          	addi	a7,s0,-576
    80008522:	db842803          	lw	a6,-584(s0)
    80008526:	87a6                	mv	a5,s1
    80008528:	471d                	li	a4,7
    8000852a:	4689                	li	a3,2
    8000852c:	6661                	lui	a2,0x18
    8000852e:	6a360613          	addi	a2,a2,1699 # 186a3 <_entry-0x7ffe795d>
    80008532:	0049d583          	lhu	a1,4(s3)
    80008536:	0009a503          	lw	a0,0(s3)
    8000853a:	e9eff0ef          	jal	80007bd8 <rpc_call>
    8000853e:	862a                	mv	a2,a0
                     NFSPROC_WRITE, args, xdr.pos, result, sizeof(result));

  if(len < 0)
    80008540:	04054c63          	bltz	a0,80008598 <nfs_write+0x116>
    return -1;

  // Decode result
  xdr_init(&xdr, result, len);
    80008544:	dc040593          	addi	a1,s0,-576
    80008548:	db040513          	addi	a0,s0,-592
    8000854c:	a3eff0ef          	jal	8000778a <xdr_init>

  uint32 status;
  if(xdr_decode_uint32(&xdr, &status) < 0)
    80008550:	dac40593          	addi	a1,s0,-596
    80008554:	db040513          	addi	a0,s0,-592
    80008558:	c0aff0ef          	jal	80007962 <xdr_decode_uint32>
    8000855c:	04054063          	bltz	a0,8000859c <nfs_write+0x11a>
    return -1;

  if(status != NFS_OK)
    80008560:	dac42783          	lw	a5,-596(s0)
    80008564:	ef95                	bnez	a5,800085a0 <nfs_write+0x11e>
    return -1;

  kfree(args);
    80008566:	8526                	mv	a0,s1
    80008568:	cb4f80ef          	jal	80000a1c <kfree>
  return count;
}
    8000856c:	854a                	mv	a0,s2
    8000856e:	26813083          	ld	ra,616(sp)
    80008572:	26013403          	ld	s0,608(sp)
    80008576:	25813483          	ld	s1,600(sp)
    8000857a:	25013903          	ld	s2,592(sp)
    8000857e:	24813983          	ld	s3,584(sp)
    80008582:	24013a03          	ld	s4,576(sp)
    80008586:	23813a83          	ld	s5,568(sp)
    8000858a:	23013b03          	ld	s6,560(sp)
    8000858e:	27010113          	addi	sp,sp,624
    80008592:	8082                	ret
    return -1;
    80008594:	597d                	li	s2,-1
    80008596:	bfd9                	j	8000856c <nfs_write+0xea>
    return -1;
    80008598:	597d                	li	s2,-1
    8000859a:	bfc9                	j	8000856c <nfs_write+0xea>
    return -1;
    8000859c:	597d                	li	s2,-1
    8000859e:	b7f9                	j	8000856c <nfs_write+0xea>
    return -1;
    800085a0:	597d                	li	s2,-1
    800085a2:	b7e9                	j	8000856c <nfs_write+0xea>

00000000800085a4 <nfs_file_write>:
}

// NFS file write operation
static int
nfs_file_write(struct file *f, uint64 addr, int n)
{
    800085a4:	ba010113          	addi	sp,sp,-1120
    800085a8:	44113c23          	sd	ra,1112(sp)
    800085ac:	44813823          	sd	s0,1104(sp)
    800085b0:	44913423          	sd	s1,1096(sp)
    800085b4:	45213023          	sd	s2,1088(sp)
    800085b8:	43313c23          	sd	s3,1080(sp)
    800085bc:	43413823          	sd	s4,1072(sp)
    800085c0:	43513423          	sd	s5,1064(sp)
    800085c4:	43613023          	sd	s6,1056(sp)
    800085c8:	41713c23          	sd	s7,1048(sp)
    800085cc:	41813823          	sd	s8,1040(sp)
    800085d0:	41913423          	sd	s9,1032(sp)
    800085d4:	46010413          	addi	s0,sp,1120
    800085d8:	89aa                	mv	s3,a0
    800085da:	8a2e                	mv	s4,a1
    800085dc:	8932                	mv	s2,a2
  struct inode *ip = f->ip;
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
    800085de:	6d1c                	ld	a5,24(a0)
    800085e0:	0707bb03          	ld	s6,112(a5)
  uchar buf[1024];
  int total = 0;
    800085e4:	4a81                	li	s5,0

  while(n > 0) {
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    800085e6:	40000b93          	li	s7,1024
    800085ea:	40000c13          	li	s8,1024
  while(n > 0) {
    800085ee:	a0b1                	j	8000863a <nfs_file_write+0x96>
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    800085f0:	00048c9b          	sext.w	s9,s1

    // Copy from user space
    if(copyin(myproc()->pagetable, (char *)buf, addr, chunk) < 0)
    800085f4:	b02f90ef          	jal	800018f6 <myproc>
    800085f8:	86e6                	mv	a3,s9
    800085fa:	8652                	mv	a2,s4
    800085fc:	ba040593          	addi	a1,s0,-1120
    80008600:	6928                	ld	a0,80(a0)
    80008602:	8ecf90ef          	jal	800016ee <copyin>
    80008606:	04054363          	bltz	a0,8000864c <nfs_file_write+0xa8>
      return -1;

    int w = nfs_write(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf);
    8000860a:	ba040713          	addi	a4,s0,-1120
    8000860e:	86e6                	mv	a3,s9
    80008610:	0209a603          	lw	a2,32(s3)
    80008614:	85da                	mv	a1,s6
    80008616:	020b3503          	ld	a0,32(s6)
    8000861a:	e69ff0ef          	jal	80008482 <nfs_write>

    if(w <= 0)
    8000861e:	02a05863          	blez	a0,8000864e <nfs_file_write+0xaa>
      break;

    f->off += w;
    80008622:	0209a783          	lw	a5,32(s3)
    80008626:	9fa9                	addw	a5,a5,a0
    80008628:	02f9a023          	sw	a5,32(s3)
    addr += w;
    8000862c:	9a2a                	add	s4,s4,a0
    total += w;
    8000862e:	00aa8abb          	addw	s5,s5,a0
    n -= w;
    80008632:	40a9093b          	subw	s2,s2,a0

    if(w < chunk)
    80008636:	01954c63          	blt	a0,s9,8000864e <nfs_file_write+0xaa>
  while(n > 0) {
    8000863a:	01205a63          	blez	s2,8000864e <nfs_file_write+0xaa>
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    8000863e:	84ca                	mv	s1,s2
    80008640:	0009079b          	sext.w	a5,s2
    80008644:	fafbf6e3          	bgeu	s7,a5,800085f0 <nfs_file_write+0x4c>
    80008648:	84e2                	mv	s1,s8
    8000864a:	b75d                	j	800085f0 <nfs_file_write+0x4c>
      return -1;
    8000864c:	5afd                	li	s5,-1
      break;
  }

  return total;
}
    8000864e:	8556                	mv	a0,s5
    80008650:	45813083          	ld	ra,1112(sp)
    80008654:	45013403          	ld	s0,1104(sp)
    80008658:	44813483          	ld	s1,1096(sp)
    8000865c:	44013903          	ld	s2,1088(sp)
    80008660:	43813983          	ld	s3,1080(sp)
    80008664:	43013a03          	ld	s4,1072(sp)
    80008668:	42813a83          	ld	s5,1064(sp)
    8000866c:	42013b03          	ld	s6,1056(sp)
    80008670:	41813b83          	ld	s7,1048(sp)
    80008674:	41013c03          	ld	s8,1040(sp)
    80008678:	40813c83          	ld	s9,1032(sp)
    8000867c:	46010113          	addi	sp,sp,1120
    80008680:	8082                	ret

0000000080008682 <nfs_file_read>:
{
    80008682:	ba010113          	addi	sp,sp,-1120
    80008686:	44113c23          	sd	ra,1112(sp)
    8000868a:	44813823          	sd	s0,1104(sp)
    8000868e:	43513423          	sd	s5,1064(sp)
    80008692:	43613023          	sd	s6,1056(sp)
    80008696:	46010413          	addi	s0,sp,1120
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
    8000869a:	6d1c                	ld	a5,24(a0)
    8000869c:	0707ba83          	ld	s5,112(a5)
  while(n > 0) {
    800086a0:	0cc05a63          	blez	a2,80008774 <nfs_file_read+0xf2>
    800086a4:	44913423          	sd	s1,1096(sp)
    800086a8:	45213023          	sd	s2,1088(sp)
    800086ac:	43313c23          	sd	s3,1080(sp)
    800086b0:	43413823          	sd	s4,1072(sp)
    800086b4:	41713c23          	sd	s7,1048(sp)
    800086b8:	41813823          	sd	s8,1040(sp)
    800086bc:	89aa                	mv	s3,a0
    800086be:	8a2e                	mv	s4,a1
    800086c0:	84b2                	mv	s1,a2
  int total = 0;
    800086c2:	4b01                	li	s6,0
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    800086c4:	40000b93          	li	s7,1024
    800086c8:	40000c13          	li	s8,1024
    800086cc:	a09d                	j	80008732 <nfs_file_read+0xb0>
    800086ce:	2901                	sext.w	s2,s2
    uint32 bytes_read = 0;
    800086d0:	ba042623          	sw	zero,-1108(s0)
    int r = nfs_read(nfs_ip->mnt, &nfs_ip->fh, f->off, chunk, buf, &bytes_read);
    800086d4:	bac40793          	addi	a5,s0,-1108
    800086d8:	bb040713          	addi	a4,s0,-1104
    800086dc:	86ca                	mv	a3,s2
    800086de:	0209a603          	lw	a2,32(s3)
    800086e2:	85d6                	mv	a1,s5
    800086e4:	020ab503          	ld	a0,32(s5)
    800086e8:	c69ff0ef          	jal	80008350 <nfs_read>
    if(r < 0)
    800086ec:	08054663          	bltz	a0,80008778 <nfs_file_read+0xf6>
    if(bytes_read == 0)
    800086f0:	bac42783          	lw	a5,-1108(s0)
    800086f4:	cbd5                	beqz	a5,800087a8 <nfs_file_read+0x126>
    if(copyout(myproc()->pagetable, addr, (char *)buf, bytes_read) < 0)
    800086f6:	a00f90ef          	jal	800018f6 <myproc>
    800086fa:	bac46683          	lwu	a3,-1108(s0)
    800086fe:	bb040613          	addi	a2,s0,-1104
    80008702:	85d2                	mv	a1,s4
    80008704:	6928                	ld	a0,80(a0)
    80008706:	f05f80ef          	jal	8000160a <copyout>
    8000870a:	02054a63          	bltz	a0,8000873e <nfs_file_read+0xbc>
    f->off += bytes_read;
    8000870e:	bac42783          	lw	a5,-1108(s0)
    80008712:	0209a703          	lw	a4,32(s3)
    80008716:	9f3d                	addw	a4,a4,a5
    80008718:	02e9a023          	sw	a4,32(s3)
    addr += bytes_read;
    8000871c:	02079713          	slli	a4,a5,0x20
    80008720:	9301                	srli	a4,a4,0x20
    80008722:	9a3a                	add	s4,s4,a4
    total += bytes_read;
    80008724:	00fb0b3b          	addw	s6,s6,a5
    n -= bytes_read;
    80008728:	9c9d                	subw	s1,s1,a5
    if(bytes_read < chunk)
    8000872a:	0927ec63          	bltu	a5,s2,800087c2 <nfs_file_read+0x140>
  while(n > 0) {
    8000872e:	02905663          	blez	s1,8000875a <nfs_file_read+0xd8>
    int chunk = n > sizeof(buf) ? sizeof(buf) : n;
    80008732:	2481                	sext.w	s1,s1
    80008734:	8926                	mv	s2,s1
    80008736:	f89bfce3          	bgeu	s7,s1,800086ce <nfs_file_read+0x4c>
    8000873a:	8962                	mv	s2,s8
    8000873c:	bf49                	j	800086ce <nfs_file_read+0x4c>
      return -1;
    8000873e:	5b7d                	li	s6,-1
    80008740:	44813483          	ld	s1,1096(sp)
    80008744:	44013903          	ld	s2,1088(sp)
    80008748:	43813983          	ld	s3,1080(sp)
    8000874c:	43013a03          	ld	s4,1072(sp)
    80008750:	41813b83          	ld	s7,1048(sp)
    80008754:	41013c03          	ld	s8,1040(sp)
    80008758:	a825                	j	80008790 <nfs_file_read+0x10e>
    8000875a:	44813483          	ld	s1,1096(sp)
    8000875e:	44013903          	ld	s2,1088(sp)
    80008762:	43813983          	ld	s3,1080(sp)
    80008766:	43013a03          	ld	s4,1072(sp)
    8000876a:	41813b83          	ld	s7,1048(sp)
    8000876e:	41013c03          	ld	s8,1040(sp)
    80008772:	a839                	j	80008790 <nfs_file_read+0x10e>
  int total = 0;
    80008774:	4b01                	li	s6,0
    80008776:	a829                	j	80008790 <nfs_file_read+0x10e>
    80008778:	44813483          	ld	s1,1096(sp)
    8000877c:	44013903          	ld	s2,1088(sp)
    80008780:	43813983          	ld	s3,1080(sp)
    80008784:	43013a03          	ld	s4,1072(sp)
    80008788:	41813b83          	ld	s7,1048(sp)
    8000878c:	41013c03          	ld	s8,1040(sp)
}
    80008790:	855a                	mv	a0,s6
    80008792:	45813083          	ld	ra,1112(sp)
    80008796:	45013403          	ld	s0,1104(sp)
    8000879a:	42813a83          	ld	s5,1064(sp)
    8000879e:	42013b03          	ld	s6,1056(sp)
    800087a2:	46010113          	addi	sp,sp,1120
    800087a6:	8082                	ret
    800087a8:	44813483          	ld	s1,1096(sp)
    800087ac:	44013903          	ld	s2,1088(sp)
    800087b0:	43813983          	ld	s3,1080(sp)
    800087b4:	43013a03          	ld	s4,1072(sp)
    800087b8:	41813b83          	ld	s7,1048(sp)
    800087bc:	41013c03          	ld	s8,1040(sp)
    800087c0:	bfc1                	j	80008790 <nfs_file_read+0x10e>
    800087c2:	44813483          	ld	s1,1096(sp)
    800087c6:	44013903          	ld	s2,1088(sp)
    800087ca:	43813983          	ld	s3,1080(sp)
    800087ce:	43013a03          	ld	s4,1072(sp)
    800087d2:	41813b83          	ld	s7,1048(sp)
    800087d6:	41013c03          	ld	s8,1040(sp)
    800087da:	bf5d                	j	80008790 <nfs_file_read+0x10e>

00000000800087dc <nfs_vfs_getattr>:
}

// NFS getattr operation
static int
nfs_vfs_getattr(struct inode *ip, struct stat *st)
{
    800087dc:	7119                	addi	sp,sp,-128
    800087de:	fc86                	sd	ra,120(sp)
    800087e0:	f8a2                	sd	s0,112(sp)
    800087e2:	f4a6                	sd	s1,104(sp)
    800087e4:	f0ca                	sd	s2,96(sp)
    800087e6:	ecce                	sd	s3,88(sp)
    800087e8:	e8d2                	sd	s4,80(sp)
    800087ea:	0100                	addi	s0,sp,128
    800087ec:	89aa                	mv	s3,a0
    800087ee:	84ae                	mv	s1,a1
  struct nfs_inode_info *nfs_ip = (struct nfs_inode_info *)ip->i_private;
    800087f0:	07053903          	ld	s2,112(a0)

  // Use cached attributes if valid
  if(nfs_ip->cached_valid) {
    800087f4:	03092a03          	lw	s4,48(s2)
    800087f8:	020a0c63          	beqz	s4,80008830 <nfs_vfs_getattr+0x54>
    st->dev = 0;
    800087fc:	0005a023          	sw	zero,0(a1)
    st->ino = nfs_ip->cached_attr.fileid;
    80008800:	05c92783          	lw	a5,92(s2)
    80008804:	c1dc                	sw	a5,4(a1)
    st->type = ip->type;
    80008806:	06051783          	lh	a5,96(a0)
    8000880a:	00f59423          	sh	a5,8(a1)
    st->nlink = nfs_ip->cached_attr.nlink;
    8000880e:	03c92783          	lw	a5,60(s2)
    80008812:	00f59523          	sh	a5,10(a1)
    st->size = nfs_ip->cached_attr.size;
    80008816:	04896783          	lwu	a5,72(s2)
    8000881a:	e99c                	sd	a5,16(a1)
    return 0;
    8000881c:	4a01                	li	s4,0
  // Update cache
  memmove(&nfs_ip->cached_attr, &attr, sizeof(attr));
  nfs_ip->cached_valid = 1;

  return 0;
}
    8000881e:	8552                	mv	a0,s4
    80008820:	70e6                	ld	ra,120(sp)
    80008822:	7446                	ld	s0,112(sp)
    80008824:	74a6                	ld	s1,104(sp)
    80008826:	7906                	ld	s2,96(sp)
    80008828:	69e6                	ld	s3,88(sp)
    8000882a:	6a46                	ld	s4,80(sp)
    8000882c:	6109                	addi	sp,sp,128
    8000882e:	8082                	ret
  if(nfs_getattr(nfs_ip->mnt, &nfs_ip->fh, &attr) < 0)
    80008830:	f8840613          	addi	a2,s0,-120
    80008834:	85ca                	mv	a1,s2
    80008836:	02093503          	ld	a0,32(s2)
    8000883a:	ed8ff0ef          	jal	80007f12 <nfs_getattr>
    8000883e:	02054e63          	bltz	a0,8000887a <nfs_vfs_getattr+0x9e>
  st->dev = 0;
    80008842:	0004a023          	sw	zero,0(s1)
  st->ino = attr.fileid;
    80008846:	fb042783          	lw	a5,-80(s0)
    8000884a:	c0dc                	sw	a5,4(s1)
  st->type = ip->type;
    8000884c:	06099783          	lh	a5,96(s3)
    80008850:	00f49423          	sh	a5,8(s1)
  st->nlink = attr.nlink;
    80008854:	f9042783          	lw	a5,-112(s0)
    80008858:	00f49523          	sh	a5,10(s1)
  st->size = attr.size;
    8000885c:	f9c46783          	lwu	a5,-100(s0)
    80008860:	e89c                	sd	a5,16(s1)
  memmove(&nfs_ip->cached_attr, &attr, sizeof(attr));
    80008862:	04400613          	li	a2,68
    80008866:	f8840593          	addi	a1,s0,-120
    8000886a:	03490513          	addi	a0,s2,52
    8000886e:	c90f80ef          	jal	80000cfe <memmove>
  nfs_ip->cached_valid = 1;
    80008872:	4785                	li	a5,1
    80008874:	02f92823          	sw	a5,48(s2)
  return 0;
    80008878:	b75d                	j	8000881e <nfs_vfs_getattr+0x42>
    return -1;
    8000887a:	5a7d                	li	s4,-1
    8000887c:	b74d                	j	8000881e <nfs_vfs_getattr+0x42>

000000008000887e <nfs_mount>:
}

// NFS mount function
struct vfs_superblock*
nfs_mount(uint dev, void *data)
{
    8000887e:	7171                	addi	sp,sp,-176
    80008880:	f506                	sd	ra,168(sp)
    80008882:	f122                	sd	s0,160(sp)
    80008884:	ed26                	sd	s1,152(sp)
    80008886:	1900                	addi	s0,sp,176
  safestrcpy(path, "/export", MAXPATH);
    80008888:	08000613          	li	a2,128
    8000888c:	00002597          	auipc	a1,0x2
    80008890:	15458593          	addi	a1,a1,340 # 8000a9e0 <etext+0x9e0>
    80008894:	f5040513          	addi	a0,s0,-176
    80008898:	d48f80ef          	jal	80000de0 <safestrcpy>
  // Parse mount options
  if(parse_nfs_mount((const char *)data, &server_ip, path) < 0)
    return 0;

  // Allocate VFS superblock
  sb = (struct vfs_superblock*)kalloc();
    8000889c:	a62f80ef          	jal	80000afe <kalloc>
    800088a0:	84aa                	mv	s1,a0
  if(!sb)
    800088a2:	c969                	beqz	a0,80008974 <nfs_mount+0xf6>
    800088a4:	e94a                	sd	s2,144(sp)
    return 0;

  // Allocate NFS mount info
  mnt = (struct nfs_mount*)kalloc();
    800088a6:	a58f80ef          	jal	80000afe <kalloc>
    800088aa:	892a                	mv	s2,a0
  if(!mnt) {
    800088ac:	c971                	beqz	a0,80008980 <nfs_mount+0x102>
    800088ae:	e152                	sd	s4,128(sp)
    kfree(sb);
    return 0;
  }

  // Initialize mount
  mnt->server_ip = server_ip;
    800088b0:	0a0007b7          	lui	a5,0xa000
    800088b4:	20178793          	addi	a5,a5,513 # a000201 <_entry-0x75fffdff>
    800088b8:	c11c                	sw	a5,0(a0)
  mnt->port = NFS_PORT;
    800088ba:	6785                	lui	a5,0x1
    800088bc:	80178793          	addi	a5,a5,-2047 # 801 <_entry-0x7ffff7ff>
    800088c0:	00f51223          	sh	a5,4(a0)

  // Get root file handle via MOUNT protocol
  // For simplicity, assume we have it. In real implementation,
  // would call MOUNT protocol to get root FH.
  // For now, zero FH (server should handle root)
  memset(&mnt->root_fh, 0, sizeof(mnt->root_fh));
    800088c4:	00650a13          	addi	s4,a0,6
    800088c8:	02000613          	li	a2,32
    800088cc:	4581                	li	a1,0
    800088ce:	8552                	mv	a0,s4
    800088d0:	bd2f80ef          	jal	80000ca2 <memset>

  // Test connection
  if(nfs_null(mnt) < 0) {
    800088d4:	854a                	mv	a0,s2
    800088d6:	e06ff0ef          	jal	80007edc <nfs_null>
    800088da:	0a054963          	bltz	a0,8000898c <nfs_mount+0x10e>
    800088de:	e54e                	sd	s3,136(sp)
    kfree(sb);
    return 0;
  }

  // Initialize VFS superblock
  sb->dev = 0;  // No device for network FS
    800088e0:	0004a023          	sw	zero,0(s1)
  sb->s_op = &nfs_super_ops;
    800088e4:	00026797          	auipc	a5,0x26
    800088e8:	70c78793          	addi	a5,a5,1804 # 8002eff0 <nfs_super_ops>
    800088ec:	e49c                	sd	a5,8(s1)
  sb->s_fs_info = mnt;
    800088ee:	0124b823          	sd	s2,16(s1)
  sb->s_blocksize = 8192;
    800088f2:	6789                	lui	a5,0x2
    800088f4:	d49c                	sw	a5,40(s1)
  initlock(&sb->s_lock, "nfs_sb");
    800088f6:	00002597          	auipc	a1,0x2
    800088fa:	11a58593          	addi	a1,a1,282 # 8000aa10 <etext+0xa10>
    800088fe:	03048513          	addi	a0,s1,48
    80008902:	a4cf80ef          	jal	80000b4e <initlock>

  // Create root inode
  sb->s_root = ialloc(0, T_DIR);
    80008906:	4585                	li	a1,1
    80008908:	4501                	li	a0,0
    8000890a:	855fa0ef          	jal	8000315e <ialloc>
    8000890e:	89aa                	mv	s3,a0
    80008910:	f088                	sd	a0,32(s1)
  if(!sb->s_root) {
    80008912:	cd49                	beqz	a0,800089ac <nfs_mount+0x12e>
    kfree(sb);
    return 0;
  }

  // Initialize root inode
  sb->s_root->i_sb = sb;
    80008914:	e524                	sd	s1,72(a0)
  sb->s_root->i_op = &nfs_inode_ops;
    80008916:	709c                	ld	a5,32(s1)
    80008918:	00006717          	auipc	a4,0x6
    8000891c:	e5870713          	addi	a4,a4,-424 # 8000e770 <nfs_inode_ops>
    80008920:	ebb8                	sd	a4,80(a5)
  sb->s_root->i_fop = &nfs_file_ops;
    80008922:	709c                	ld	a5,32(s1)
    80008924:	00006717          	auipc	a4,0x6
    80008928:	e8470713          	addi	a4,a4,-380 # 8000e7a8 <nfs_file_ops>
    8000892c:	efb8                	sd	a4,88(a5)
  sb->s_root->type = T_DIR;
    8000892e:	7098                	ld	a4,32(s1)
    80008930:	4785                	li	a5,1
    80008932:	06f71023          	sh	a5,96(a4)
  sb->s_root->valid = 1;
    80008936:	7098                	ld	a4,32(s1)
    80008938:	c33c                	sw	a5,64(a4)

  // Allocate root inode private data
  struct nfs_inode_info *nfs_root = kalloc();
    8000893a:	9c4f80ef          	jal	80000afe <kalloc>
    8000893e:	89aa                	mv	s3,a0
  if(!nfs_root) {
    80008940:	c149                	beqz	a0,800089c2 <nfs_mount+0x144>
    kfree(mnt);
    kfree(sb);
    return 0;
  }

  memmove(&nfs_root->fh, &mnt->root_fh, sizeof(mnt->root_fh));
    80008942:	02000613          	li	a2,32
    80008946:	85d2                	mv	a1,s4
    80008948:	bb6f80ef          	jal	80000cfe <memmove>
  nfs_root->mnt = mnt;
    8000894c:	0329b023          	sd	s2,32(s3)
  nfs_root->cached_valid = 0;
    80008950:	0209a823          	sw	zero,48(s3)
  sb->s_root->i_private = nfs_root;
    80008954:	709c                	ld	a5,32(s1)
    80008956:	0737b823          	sd	s3,112(a5) # 2070 <_entry-0x7fffdf90>

  printf("nfs_mount: mounted NFS from %x\n", server_ip);
    8000895a:	0a0005b7          	lui	a1,0xa000
    8000895e:	20158593          	addi	a1,a1,513 # a000201 <_entry-0x75fffdff>
    80008962:	00002517          	auipc	a0,0x2
    80008966:	0b650513          	addi	a0,a0,182 # 8000aa18 <etext+0xa18>
    8000896a:	b91f70ef          	jal	800004fa <printf>
    8000896e:	694a                	ld	s2,144(sp)
    80008970:	69aa                	ld	s3,136(sp)
    80008972:	6a0a                	ld	s4,128(sp)
  return sb;
}
    80008974:	8526                	mv	a0,s1
    80008976:	70aa                	ld	ra,168(sp)
    80008978:	740a                	ld	s0,160(sp)
    8000897a:	64ea                	ld	s1,152(sp)
    8000897c:	614d                	addi	sp,sp,176
    8000897e:	8082                	ret
    kfree(sb);
    80008980:	8526                	mv	a0,s1
    80008982:	89af80ef          	jal	80000a1c <kfree>
    return 0;
    80008986:	84ca                	mv	s1,s2
    80008988:	694a                	ld	s2,144(sp)
    8000898a:	b7ed                	j	80008974 <nfs_mount+0xf6>
    printf("nfs_mount: cannot contact NFS server\n");
    8000898c:	00002517          	auipc	a0,0x2
    80008990:	05c50513          	addi	a0,a0,92 # 8000a9e8 <etext+0x9e8>
    80008994:	b67f70ef          	jal	800004fa <printf>
    kfree(mnt);
    80008998:	854a                	mv	a0,s2
    8000899a:	882f80ef          	jal	80000a1c <kfree>
    kfree(sb);
    8000899e:	8526                	mv	a0,s1
    800089a0:	87cf80ef          	jal	80000a1c <kfree>
    return 0;
    800089a4:	4481                	li	s1,0
    800089a6:	694a                	ld	s2,144(sp)
    800089a8:	6a0a                	ld	s4,128(sp)
    800089aa:	b7e9                	j	80008974 <nfs_mount+0xf6>
    kfree(mnt);
    800089ac:	854a                	mv	a0,s2
    800089ae:	86ef80ef          	jal	80000a1c <kfree>
    kfree(sb);
    800089b2:	8526                	mv	a0,s1
    800089b4:	868f80ef          	jal	80000a1c <kfree>
    return 0;
    800089b8:	84ce                	mv	s1,s3
    800089ba:	694a                	ld	s2,144(sp)
    800089bc:	69aa                	ld	s3,136(sp)
    800089be:	6a0a                	ld	s4,128(sp)
    800089c0:	bf55                	j	80008974 <nfs_mount+0xf6>
    iput(sb->s_root);
    800089c2:	7088                	ld	a0,32(s1)
    800089c4:	a0ffa0ef          	jal	800033d2 <iput>
    kfree(mnt);
    800089c8:	854a                	mv	a0,s2
    800089ca:	852f80ef          	jal	80000a1c <kfree>
    kfree(sb);
    800089ce:	8526                	mv	a0,s1
    800089d0:	84cf80ef          	jal	80000a1c <kfree>
    return 0;
    800089d4:	84ce                	mv	s1,s3
    800089d6:	694a                	ld	s2,144(sp)
    800089d8:	69aa                	ld	s3,136(sp)
    800089da:	6a0a                	ld	s4,128(sp)
    800089dc:	bf61                	j	80008974 <nfs_mount+0xf6>

00000000800089de <nfs_vfs_lookup>:
{
    800089de:	7135                	addi	sp,sp,-160
    800089e0:	ed06                	sd	ra,152(sp)
    800089e2:	e922                	sd	s0,144(sp)
    800089e4:	e14a                	sd	s2,128(sp)
    800089e6:	fcce                	sd	s3,120(sp)
    800089e8:	f8d2                	sd	s4,112(sp)
    800089ea:	1100                	addi	s0,sp,160
    800089ec:	892a                	mv	s2,a0
    800089ee:	89b2                	mv	s3,a2
  struct nfs_inode_info *nfs_dir = (struct nfs_inode_info *)dir->i_private;
    800089f0:	07053a03          	ld	s4,112(a0)
  if(nfs_lookup(nfs_dir->mnt, &nfs_dir->fh, name, &fh, &attr) < 0)
    800089f4:	f6840713          	addi	a4,s0,-152
    800089f8:	fb040693          	addi	a3,s0,-80
    800089fc:	862e                	mv	a2,a1
    800089fe:	85d2                	mv	a1,s4
    80008a00:	020a3503          	ld	a0,32(s4)
    80008a04:	f12ff0ef          	jal	80008116 <nfs_lookup>
    80008a08:	0a054e63          	bltz	a0,80008ac4 <nfs_vfs_lookup+0xe6>
    80008a0c:	e526                	sd	s1,136(sp)
  struct inode *ip = ialloc(0, nfs_type_to_xv6(attr.type));
    80008a0e:	f6842783          	lw	a5,-152(s0)
  switch(nfs_type) {
    80008a12:	4709                	li	a4,2
    80008a14:	4585                	li	a1,1
    80008a16:	00e78663          	beq	a5,a4,80008a22 <nfs_vfs_lookup+0x44>
    80008a1a:	37f5                	addiw	a5,a5,-3
    case NFBLK: return T_DEVICE;
    80008a1c:	0027b593          	sltiu	a1,a5,2
    80008a20:	0589                	addi	a1,a1,2
  struct inode *ip = ialloc(0, nfs_type_to_xv6(attr.type));
    80008a22:	4501                	li	a0,0
    80008a24:	f3afa0ef          	jal	8000315e <ialloc>
    80008a28:	84aa                	mv	s1,a0
  if(!ip)
    80008a2a:	cd59                	beqz	a0,80008ac8 <nfs_vfs_lookup+0xea>
  ip->i_sb = dir->i_sb;
    80008a2c:	04893783          	ld	a5,72(s2)
    80008a30:	e53c                	sd	a5,72(a0)
  ip->i_op = dir->i_op;
    80008a32:	05093783          	ld	a5,80(s2)
    80008a36:	e93c                	sd	a5,80(a0)
  ip->i_fop = &nfs_file_ops;
    80008a38:	00006797          	auipc	a5,0x6
    80008a3c:	d7078793          	addi	a5,a5,-656 # 8000e7a8 <nfs_file_ops>
    80008a40:	ed3c                	sd	a5,88(a0)
  ip->type = nfs_type_to_xv6(attr.type);
    80008a42:	f6842703          	lw	a4,-152(s0)
  switch(nfs_type) {
    80008a46:	4689                	li	a3,2
    80008a48:	4785                	li	a5,1
    80008a4a:	00d70663          	beq	a4,a3,80008a56 <nfs_vfs_lookup+0x78>
    80008a4e:	3775                	addiw	a4,a4,-3
    case NFBLK: return T_DEVICE;
    80008a50:	00273793          	sltiu	a5,a4,2
    80008a54:	0789                	addi	a5,a5,2
  ip->type = nfs_type_to_xv6(attr.type);
    80008a56:	06f49023          	sh	a5,96(s1)
  ip->size = attr.size;
    80008a5a:	f7c42783          	lw	a5,-132(s0)
    80008a5e:	d4bc                	sw	a5,104(s1)
  ip->nlink = attr.nlink;
    80008a60:	f7042783          	lw	a5,-144(s0)
    80008a64:	06f49323          	sh	a5,102(s1)
  ip->valid = 1;
    80008a68:	4785                	li	a5,1
    80008a6a:	c0bc                	sw	a5,64(s1)
  struct nfs_inode_info *nfs_ip = kalloc();
    80008a6c:	892f80ef          	jal	80000afe <kalloc>
    80008a70:	892a                	mv	s2,a0
  if(!nfs_ip) {
    80008a72:	c139                	beqz	a0,80008ab8 <nfs_vfs_lookup+0xda>
  memmove(&nfs_ip->fh, &fh, sizeof(fh));
    80008a74:	02000613          	li	a2,32
    80008a78:	fb040593          	addi	a1,s0,-80
    80008a7c:	a82f80ef          	jal	80000cfe <memmove>
  nfs_ip->mnt = nfs_dir->mnt;
    80008a80:	020a3783          	ld	a5,32(s4)
    80008a84:	02f93023          	sd	a5,32(s2)
  nfs_ip->cached_valid = 1;
    80008a88:	4785                	li	a5,1
    80008a8a:	02f92823          	sw	a5,48(s2)
  memmove(&nfs_ip->cached_attr, &attr, sizeof(attr));
    80008a8e:	04400613          	li	a2,68
    80008a92:	f6840593          	addi	a1,s0,-152
    80008a96:	03490513          	addi	a0,s2,52
    80008a9a:	a64f80ef          	jal	80000cfe <memmove>
  ip->i_private = nfs_ip;
    80008a9e:	0724b823          	sd	s2,112(s1)
  *result = ip;
    80008aa2:	0099b023          	sd	s1,0(s3)
  return 0;
    80008aa6:	4501                	li	a0,0
    80008aa8:	64aa                	ld	s1,136(sp)
}
    80008aaa:	60ea                	ld	ra,152(sp)
    80008aac:	644a                	ld	s0,144(sp)
    80008aae:	690a                	ld	s2,128(sp)
    80008ab0:	79e6                	ld	s3,120(sp)
    80008ab2:	7a46                	ld	s4,112(sp)
    80008ab4:	610d                	addi	sp,sp,160
    80008ab6:	8082                	ret
    iput(ip);
    80008ab8:	8526                	mv	a0,s1
    80008aba:	919fa0ef          	jal	800033d2 <iput>
    return -1;
    80008abe:	557d                	li	a0,-1
    80008ac0:	64aa                	ld	s1,136(sp)
    80008ac2:	b7e5                	j	80008aaa <nfs_vfs_lookup+0xcc>
    return -1;
    80008ac4:	557d                	li	a0,-1
    80008ac6:	b7d5                	j	80008aaa <nfs_vfs_lookup+0xcc>
    return -1;
    80008ac8:	557d                	li	a0,-1
    80008aca:	64aa                	ld	s1,136(sp)
    80008acc:	bff9                	j	80008aaa <nfs_vfs_lookup+0xcc>

0000000080008ace <nfs_register>:
};

// Register NFS filesystem
int
nfs_register(void)
{
    80008ace:	1101                	addi	sp,sp,-32
    80008ad0:	ec06                	sd	ra,24(sp)
    80008ad2:	e822                	sd	s0,16(sp)
    80008ad4:	e426                	sd	s1,8(sp)
    80008ad6:	1000                	addi	s0,sp,32
  safestrcpy(nfs_type.name, "nfs", 16);
    80008ad8:	00006497          	auipc	s1,0x6
    80008adc:	cf048493          	addi	s1,s1,-784 # 8000e7c8 <nfs_type>
    80008ae0:	4641                	li	a2,16
    80008ae2:	00002597          	auipc	a1,0x2
    80008ae6:	f5658593          	addi	a1,a1,-170 # 8000aa38 <etext+0xa38>
    80008aea:	8526                	mv	a0,s1
    80008aec:	af4f80ef          	jal	80000de0 <safestrcpy>
  return vfs_register_filesystem(&nfs_type);
    80008af0:	8526                	mv	a0,s1
    80008af2:	83efd0ef          	jal	80005b30 <vfs_register_filesystem>
}
    80008af6:	60e2                	ld	ra,24(sp)
    80008af8:	6442                	ld	s0,16(sp)
    80008afa:	64a2                	ld	s1,8(sp)
    80008afc:	6105                	addi	sp,sp,32
    80008afe:	8082                	ret
	...

0000000080009000 <_trampoline>:
    80009000:	14051073          	csrw	sscratch,a0
    80009004:	02000537          	lui	a0,0x2000
    80009008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000900a:	0536                	slli	a0,a0,0xd
    8000900c:	02153423          	sd	ra,40(a0)
    80009010:	02253823          	sd	sp,48(a0)
    80009014:	02353c23          	sd	gp,56(a0)
    80009018:	04453023          	sd	tp,64(a0)
    8000901c:	04553423          	sd	t0,72(a0)
    80009020:	04653823          	sd	t1,80(a0)
    80009024:	04753c23          	sd	t2,88(a0)
    80009028:	f120                	sd	s0,96(a0)
    8000902a:	f524                	sd	s1,104(a0)
    8000902c:	fd2c                	sd	a1,120(a0)
    8000902e:	e150                	sd	a2,128(a0)
    80009030:	e554                	sd	a3,136(a0)
    80009032:	e958                	sd	a4,144(a0)
    80009034:	ed5c                	sd	a5,152(a0)
    80009036:	0b053023          	sd	a6,160(a0)
    8000903a:	0b153423          	sd	a7,168(a0)
    8000903e:	0b253823          	sd	s2,176(a0)
    80009042:	0b353c23          	sd	s3,184(a0)
    80009046:	0d453023          	sd	s4,192(a0)
    8000904a:	0d553423          	sd	s5,200(a0)
    8000904e:	0d653823          	sd	s6,208(a0)
    80009052:	0d753c23          	sd	s7,216(a0)
    80009056:	0f853023          	sd	s8,224(a0)
    8000905a:	0f953423          	sd	s9,232(a0)
    8000905e:	0fa53823          	sd	s10,240(a0)
    80009062:	0fb53c23          	sd	s11,248(a0)
    80009066:	11c53023          	sd	t3,256(a0)
    8000906a:	11d53423          	sd	t4,264(a0)
    8000906e:	11e53823          	sd	t5,272(a0)
    80009072:	11f53c23          	sd	t6,280(a0)
    80009076:	140022f3          	csrr	t0,sscratch
    8000907a:	06553823          	sd	t0,112(a0)
    8000907e:	00853103          	ld	sp,8(a0)
    80009082:	02053203          	ld	tp,32(a0)
    80009086:	01053283          	ld	t0,16(a0)
    8000908a:	00053303          	ld	t1,0(a0)
    8000908e:	12000073          	sfence.vma
    80009092:	18031073          	csrw	satp,t1
    80009096:	12000073          	sfence.vma
    8000909a:	9282                	jalr	t0

000000008000909c <userret>:
    8000909c:	12000073          	sfence.vma
    800090a0:	18051073          	csrw	satp,a0
    800090a4:	12000073          	sfence.vma
    800090a8:	02000537          	lui	a0,0x2000
    800090ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800090ae:	0536                	slli	a0,a0,0xd
    800090b0:	02853083          	ld	ra,40(a0)
    800090b4:	03053103          	ld	sp,48(a0)
    800090b8:	03853183          	ld	gp,56(a0)
    800090bc:	04053203          	ld	tp,64(a0)
    800090c0:	04853283          	ld	t0,72(a0)
    800090c4:	05053303          	ld	t1,80(a0)
    800090c8:	05853383          	ld	t2,88(a0)
    800090cc:	7120                	ld	s0,96(a0)
    800090ce:	7524                	ld	s1,104(a0)
    800090d0:	7d2c                	ld	a1,120(a0)
    800090d2:	6150                	ld	a2,128(a0)
    800090d4:	6554                	ld	a3,136(a0)
    800090d6:	6958                	ld	a4,144(a0)
    800090d8:	6d5c                	ld	a5,152(a0)
    800090da:	0a053803          	ld	a6,160(a0)
    800090de:	0a853883          	ld	a7,168(a0)
    800090e2:	0b053903          	ld	s2,176(a0)
    800090e6:	0b853983          	ld	s3,184(a0)
    800090ea:	0c053a03          	ld	s4,192(a0)
    800090ee:	0c853a83          	ld	s5,200(a0)
    800090f2:	0d053b03          	ld	s6,208(a0)
    800090f6:	0d853b83          	ld	s7,216(a0)
    800090fa:	0e053c03          	ld	s8,224(a0)
    800090fe:	0e853c83          	ld	s9,232(a0)
    80009102:	0f053d03          	ld	s10,240(a0)
    80009106:	0f853d83          	ld	s11,248(a0)
    8000910a:	10053e03          	ld	t3,256(a0)
    8000910e:	10853e83          	ld	t4,264(a0)
    80009112:	11053f03          	ld	t5,272(a0)
    80009116:	11853f83          	ld	t6,280(a0)
    8000911a:	7928                	ld	a0,112(a0)
    8000911c:	10200073          	sret
	...
