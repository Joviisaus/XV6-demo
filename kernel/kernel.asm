
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	b9c78793          	addi	a5,a5,-1124 # 80005c00 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc87f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3a8080e7          	jalr	936(ra) # 800024d4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8c450513          	addi	a0,a0,-1852 # 80010a50 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8b448493          	addi	s1,s1,-1868 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	94290913          	addi	s2,s2,-1726 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	152080e7          	jalr	338(ra) # 8000231e <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e9c080e7          	jalr	-356(ra) # 80002076 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	268080e7          	jalr	616(ra) # 8000247e <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	82650513          	addi	a0,a0,-2010 # 80010a50 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	81050513          	addi	a0,a0,-2032 # 80010a50 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	86f72823          	sw	a5,-1936(a4) # 80010ae8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	77e50513          	addi	a0,a0,1918 # 80010a50 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	232080e7          	jalr	562(ra) # 8000252a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	75050513          	addi	a0,a0,1872 # 80010a50 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	72c70713          	addi	a4,a4,1836 # 80010a50 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	70278793          	addi	a5,a5,1794 # 80010a50 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	76c7a783          	lw	a5,1900(a5) # 80010ae8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6c070713          	addi	a4,a4,1728 # 80010a50 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6b048493          	addi	s1,s1,1712 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	67470713          	addi	a4,a4,1652 # 80010a50 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6ef72f23          	sw	a5,1790(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	63878793          	addi	a5,a5,1592 # 80010a50 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6ac7a823          	sw	a2,1712(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6a450513          	addi	a0,a0,1700 # 80010ae8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c8e080e7          	jalr	-882(ra) # 800020da <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5ea50513          	addi	a0,a0,1514 # 80010a50 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	96a78793          	addi	a5,a5,-1686 # 80020de8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5c07a023          	sw	zero,1472(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	34f72623          	sw	a5,844(a4) # 800088d0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	550dad83          	lw	s11,1360(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4fa50513          	addi	a0,a0,1274 # 80010af8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	39650513          	addi	a0,a0,918 # 80010af8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	37a48493          	addi	s1,s1,890 # 80010af8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	33a50513          	addi	a0,a0,826 # 80010b18 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0c67a783          	lw	a5,198(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	09273703          	ld	a4,146(a4) # 800088d8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0927b783          	ld	a5,146(a5) # 800088e0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	2a8a0a13          	addi	s4,s4,680 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	06048493          	addi	s1,s1,96 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	06098993          	addi	s3,s3,96 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	834080e7          	jalr	-1996(ra) # 800020da <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	23650513          	addi	a0,a0,566 # 80010b18 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fde7a783          	lw	a5,-34(a5) # 800088d0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fe47b783          	ld	a5,-28(a5) # 800088e0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fd473703          	ld	a4,-44(a4) # 800088d8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	208a0a13          	addi	s4,s4,520 # 80010b18 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fc048493          	addi	s1,s1,-64 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fc090913          	addi	s2,s2,-64 # 800088e0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	746080e7          	jalr	1862(ra) # 80002076 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1d248493          	addi	s1,s1,466 # 80010b18 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f8f73323          	sd	a5,-122(a4) # 800088e0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	14848493          	addi	s1,s1,328 # 80010b18 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	56e78793          	addi	a5,a5,1390 # 80021f80 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	11e90913          	addi	s2,s2,286 # 80010b50 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	08250513          	addi	a0,a0,130 # 80010b50 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	49e50513          	addi	a0,a0,1182 # 80021f80 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	04c48493          	addi	s1,s1,76 # 80010b50 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	03450513          	addi	a0,a0,52 # 80010b50 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	00850513          	addi	a0,a0,8 # 80010b50 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a4470713          	addi	a4,a4,-1468 # 800088e8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	790080e7          	jalr	1936(ra) # 8000266a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	d5e080e7          	jalr	-674(ra) # 80005c40 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fda080e7          	jalr	-38(ra) # 80001ec4 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	6f0080e7          	jalr	1776(ra) # 80002642 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	710080e7          	jalr	1808(ra) # 8000266a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	cc8080e7          	jalr	-824(ra) # 80005c2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	cd6080e7          	jalr	-810(ra) # 80005c40 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	e90080e7          	jalr	-368(ra) # 80002e02 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	534080e7          	jalr	1332(ra) # 800034ae <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	4d2080e7          	jalr	1234(ra) # 80004454 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	dbe080e7          	jalr	-578(ra) # 80005d48 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	94f72423          	sw	a5,-1720(a4) # 800088e8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	93c7b783          	ld	a5,-1732(a5) # 800088f0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	68a7b023          	sd	a0,1664(a5) # 800088f0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	73a48493          	addi	s1,s1,1850 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	320a0a13          	addi	s4,s4,800 # 80016ba0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	8591                	srai	a1,a1,0x4
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	17048493          	addi	s1,s1,368
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	26e50513          	addi	a0,a0,622 # 80010b70 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	26e50513          	addi	a0,a0,622 # 80010b88 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	67648493          	addi	s1,s1,1654 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	25498993          	addi	s3,s3,596 # 80016ba0 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	8791                	srai	a5,a5,0x4
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	17048493          	addi	s1,s1,368
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1ea50513          	addi	a0,a0,490 # 80010ba0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	19270713          	addi	a4,a4,402 # 80010b70 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e4a7a783          	lw	a5,-438(a5) # 80008860 <first.1679>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c62080e7          	jalr	-926(ra) # 80002682 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a823          	sw	zero,-464(a5) # 80008860 <first.1679>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	9f4080e7          	jalr	-1548(ra) # 8000342e <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	12090913          	addi	s2,s2,288 # 80010b70 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e0278793          	addi	a5,a5,-510 # 80008864 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3c448493          	addi	s1,s1,964 # 80010fa0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	fbc90913          	addi	s2,s2,-68 # 80016ba0 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	17048493          	addi	s1,s1,368
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	c4a7b323          	sd	a0,-954(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	bb258593          	addi	a1,a1,-1102 # 80008870 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	154080e7          	jalr	340(ra) # 80003e50 <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	12050163          	beqz	a0,80001ec0 <fork+0x144>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054c63          	bltz	a0,80001e0e <fork+0x92>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask;
    80001dc2:	16892783          	lw	a5,360(s2)
    80001dc6:	16f9a423          	sw	a5,360(s3)
  np->parent = p;
    80001dca:	0329bc23          	sd	s2,56(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dce:	05893683          	ld	a3,88(s2)
    80001dd2:	87b6                	mv	a5,a3
    80001dd4:	0589b703          	ld	a4,88(s3)
    80001dd8:	12068693          	addi	a3,a3,288
    80001ddc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de0:	6788                	ld	a0,8(a5)
    80001de2:	6b8c                	ld	a1,16(a5)
    80001de4:	6f90                	ld	a2,24(a5)
    80001de6:	01073023          	sd	a6,0(a4)
    80001dea:	e708                	sd	a0,8(a4)
    80001dec:	eb0c                	sd	a1,16(a4)
    80001dee:	ef10                	sd	a2,24(a4)
    80001df0:	02078793          	addi	a5,a5,32
    80001df4:	02070713          	addi	a4,a4,32
    80001df8:	fed792e3          	bne	a5,a3,80001ddc <fork+0x60>
  np->trapframe->a0 = 0;
    80001dfc:	0589b783          	ld	a5,88(s3)
    80001e00:	0607b823          	sd	zero,112(a5)
    80001e04:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e08:	15000a13          	li	s4,336
    80001e0c:	a03d                	j	80001e3a <fork+0xbe>
    freeproc(np);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	d68080e7          	jalr	-664(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e18:	854e                	mv	a0,s3
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	e84080e7          	jalr	-380(ra) # 80000c9e <release>
    return -1;
    80001e22:	5a7d                	li	s4,-1
    80001e24:	a069                	j	80001eae <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00002097          	auipc	ra,0x2
    80001e2a:	6c0080e7          	jalr	1728(ra) # 800044e6 <filedup>
    80001e2e:	009987b3          	add	a5,s3,s1
    80001e32:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e34:	04a1                	addi	s1,s1,8
    80001e36:	01448763          	beq	s1,s4,80001e44 <fork+0xc8>
    if(p->ofile[i])
    80001e3a:	009907b3          	add	a5,s2,s1
    80001e3e:	6388                	ld	a0,0(a5)
    80001e40:	f17d                	bnez	a0,80001e26 <fork+0xaa>
    80001e42:	bfcd                	j	80001e34 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e44:	15093503          	ld	a0,336(s2)
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	824080e7          	jalr	-2012(ra) # 8000366c <idup>
    80001e50:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e54:	4641                	li	a2,16
    80001e56:	15890593          	addi	a1,s2,344
    80001e5a:	15898513          	addi	a0,s3,344
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	fda080e7          	jalr	-38(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e66:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e6a:	854e                	mv	a0,s3
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e32080e7          	jalr	-462(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e74:	0000f497          	auipc	s1,0xf
    80001e78:	d1448493          	addi	s1,s1,-748 # 80010b88 <wait_lock>
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d6c080e7          	jalr	-660(ra) # 80000bea <acquire>
  np->parent = p;
    80001e86:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e12080e7          	jalr	-494(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	d54080e7          	jalr	-684(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e9e:	478d                	li	a5,3
    80001ea0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea4:	854e                	mv	a0,s3
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	df8080e7          	jalr	-520(ra) # 80000c9e <release>
}
    80001eae:	8552                	mv	a0,s4
    80001eb0:	70a2                	ld	ra,40(sp)
    80001eb2:	7402                	ld	s0,32(sp)
    80001eb4:	64e2                	ld	s1,24(sp)
    80001eb6:	6942                	ld	s2,16(sp)
    80001eb8:	69a2                	ld	s3,8(sp)
    80001eba:	6a02                	ld	s4,0(sp)
    80001ebc:	6145                	addi	sp,sp,48
    80001ebe:	8082                	ret
    return -1;
    80001ec0:	5a7d                	li	s4,-1
    80001ec2:	b7f5                	j	80001eae <fork+0x132>

0000000080001ec4 <scheduler>:
{
    80001ec4:	7139                	addi	sp,sp,-64
    80001ec6:	fc06                	sd	ra,56(sp)
    80001ec8:	f822                	sd	s0,48(sp)
    80001eca:	f426                	sd	s1,40(sp)
    80001ecc:	f04a                	sd	s2,32(sp)
    80001ece:	ec4e                	sd	s3,24(sp)
    80001ed0:	e852                	sd	s4,16(sp)
    80001ed2:	e456                	sd	s5,8(sp)
    80001ed4:	e05a                	sd	s6,0(sp)
    80001ed6:	0080                	addi	s0,sp,64
    80001ed8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eda:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001edc:	00779a93          	slli	s5,a5,0x7
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	c9070713          	addi	a4,a4,-880 # 80010b70 <pid_lock>
    80001ee8:	9756                	add	a4,a4,s5
    80001eea:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	cba70713          	addi	a4,a4,-838 # 80010ba8 <cpus+0x8>
    80001ef6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef8:	498d                	li	s3,3
        p->state = RUNNING;
    80001efa:	4b11                	li	s6,4
        c->proc = p;
    80001efc:	079e                	slli	a5,a5,0x7
    80001efe:	0000fa17          	auipc	s4,0xf
    80001f02:	c72a0a13          	addi	s4,s4,-910 # 80010b70 <pid_lock>
    80001f06:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	00015917          	auipc	s2,0x15
    80001f0c:	c9890913          	addi	s2,s2,-872 # 80016ba0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f18:	10079073          	csrw	sstatus,a5
    80001f1c:	0000f497          	auipc	s1,0xf
    80001f20:	08448493          	addi	s1,s1,132 # 80010fa0 <proc>
    80001f24:	a03d                	j	80001f52 <scheduler+0x8e>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	6a4080e7          	jalr	1700(ra) # 800025d8 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d5c080e7          	jalr	-676(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4a:	17048493          	addi	s1,s1,368
    80001f4e:	fd2481e3          	beq	s1,s2,80001f10 <scheduler+0x4c>
      acquire(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c96080e7          	jalr	-874(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f5c:	4c9c                	lw	a5,24(s1)
    80001f5e:	ff3791e3          	bne	a5,s3,80001f40 <scheduler+0x7c>
    80001f62:	b7d1                	j	80001f26 <scheduler+0x62>

0000000080001f64 <sched>:
{
    80001f64:	7179                	addi	sp,sp,-48
    80001f66:	f406                	sd	ra,40(sp)
    80001f68:	f022                	sd	s0,32(sp)
    80001f6a:	ec26                	sd	s1,24(sp)
    80001f6c:	e84a                	sd	s2,16(sp)
    80001f6e:	e44e                	sd	s3,8(sp)
    80001f70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	a54080e7          	jalr	-1452(ra) # 800019c6 <myproc>
    80001f7a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	bf4080e7          	jalr	-1036(ra) # 80000b70 <holding>
    80001f84:	c93d                	beqz	a0,80001ffa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f86:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f88:	2781                	sext.w	a5,a5
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	be470713          	addi	a4,a4,-1052 # 80010b70 <pid_lock>
    80001f94:	97ba                	add	a5,a5,a4
    80001f96:	0a87a703          	lw	a4,168(a5)
    80001f9a:	4785                	li	a5,1
    80001f9c:	06f71763          	bne	a4,a5,8000200a <sched+0xa6>
  if(p->state == RUNNING)
    80001fa0:	4c98                	lw	a4,24(s1)
    80001fa2:	4791                	li	a5,4
    80001fa4:	06f70b63          	beq	a4,a5,8000201a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fac:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fae:	efb5                	bnez	a5,8000202a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb2:	0000f917          	auipc	s2,0xf
    80001fb6:	bbe90913          	addi	s2,s2,-1090 # 80010b70 <pid_lock>
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	97ca                	add	a5,a5,s2
    80001fc0:	0ac7a983          	lw	s3,172(a5)
    80001fc4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	0000f597          	auipc	a1,0xf
    80001fce:	bde58593          	addi	a1,a1,-1058 # 80010ba8 <cpus+0x8>
    80001fd2:	95be                	add	a1,a1,a5
    80001fd4:	06048513          	addi	a0,s1,96
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	600080e7          	jalr	1536(ra) # 800025d8 <swtch>
    80001fe0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe2:	2781                	sext.w	a5,a5
    80001fe4:	079e                	slli	a5,a5,0x7
    80001fe6:	97ca                	add	a5,a5,s2
    80001fe8:	0b37a623          	sw	s3,172(a5)
}
    80001fec:	70a2                	ld	ra,40(sp)
    80001fee:	7402                	ld	s0,32(sp)
    80001ff0:	64e2                	ld	s1,24(sp)
    80001ff2:	6942                	ld	s2,16(sp)
    80001ff4:	69a2                	ld	s3,8(sp)
    80001ff6:	6145                	addi	sp,sp,48
    80001ff8:	8082                	ret
    panic("sched p->lock");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	21e50513          	addi	a0,a0,542 # 80008218 <digits+0x1d8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	542080e7          	jalr	1346(ra) # 80000544 <panic>
    panic("sched locks");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	21e50513          	addi	a0,a0,542 # 80008228 <digits+0x1e8>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	532080e7          	jalr	1330(ra) # 80000544 <panic>
    panic("sched running");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	21e50513          	addi	a0,a0,542 # 80008238 <digits+0x1f8>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	522080e7          	jalr	1314(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	21e50513          	addi	a0,a0,542 # 80008248 <digits+0x208>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	512080e7          	jalr	1298(ra) # 80000544 <panic>

000000008000203a <yield>:
{
    8000203a:	1101                	addi	sp,sp,-32
    8000203c:	ec06                	sd	ra,24(sp)
    8000203e:	e822                	sd	s0,16(sp)
    80002040:	e426                	sd	s1,8(sp)
    80002042:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	982080e7          	jalr	-1662(ra) # 800019c6 <myproc>
    8000204c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b9c080e7          	jalr	-1124(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002056:	478d                	li	a5,3
    80002058:	cc9c                	sw	a5,24(s1)
  sched();
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	f0a080e7          	jalr	-246(ra) # 80001f64 <sched>
  release(&p->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c3a080e7          	jalr	-966(ra) # 80000c9e <release>
}
    8000206c:	60e2                	ld	ra,24(sp)
    8000206e:	6442                	ld	s0,16(sp)
    80002070:	64a2                	ld	s1,8(sp)
    80002072:	6105                	addi	sp,sp,32
    80002074:	8082                	ret

0000000080002076 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	89aa                	mv	s3,a0
    80002086:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	93e080e7          	jalr	-1730(ra) # 800019c6 <myproc>
    80002090:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b58080e7          	jalr	-1192(ra) # 80000bea <acquire>
  release(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	c02080e7          	jalr	-1022(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020a4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a8:	4789                	li	a5,2
    800020aa:	cc9c                	sw	a5,24(s1)

  sched();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	eb8080e7          	jalr	-328(ra) # 80001f64 <sched>

  // Tidy up.
  p->chan = 0;
    800020b4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	be4080e7          	jalr	-1052(ra) # 80000c9e <release>
  acquire(lk);
    800020c2:	854a                	mv	a0,s2
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b26080e7          	jalr	-1242(ra) # 80000bea <acquire>
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret

00000000800020da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020da:	7139                	addi	sp,sp,-64
    800020dc:	fc06                	sd	ra,56(sp)
    800020de:	f822                	sd	s0,48(sp)
    800020e0:	f426                	sd	s1,40(sp)
    800020e2:	f04a                	sd	s2,32(sp)
    800020e4:	ec4e                	sd	s3,24(sp)
    800020e6:	e852                	sd	s4,16(sp)
    800020e8:	e456                	sd	s5,8(sp)
    800020ea:	0080                	addi	s0,sp,64
    800020ec:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	0000f497          	auipc	s1,0xf
    800020f2:	eb248493          	addi	s1,s1,-334 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020f6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020f8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fa:	00015917          	auipc	s2,0x15
    800020fe:	aa690913          	addi	s2,s2,-1370 # 80016ba0 <tickslock>
    80002102:	a821                	j	8000211a <wakeup+0x40>
        p->state = RUNNABLE;
    80002104:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	b94080e7          	jalr	-1132(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002112:	17048493          	addi	s1,s1,368
    80002116:	03248463          	beq	s1,s2,8000213e <wakeup+0x64>
    if(p != myproc()){
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	8ac080e7          	jalr	-1876(ra) # 800019c6 <myproc>
    80002122:	fea488e3          	beq	s1,a0,80002112 <wakeup+0x38>
      acquire(&p->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	ac2080e7          	jalr	-1342(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002130:	4c9c                	lw	a5,24(s1)
    80002132:	fd379be3          	bne	a5,s3,80002108 <wakeup+0x2e>
    80002136:	709c                	ld	a5,32(s1)
    80002138:	fd4798e3          	bne	a5,s4,80002108 <wakeup+0x2e>
    8000213c:	b7e1                	j	80002104 <wakeup+0x2a>
    }
  }
}
    8000213e:	70e2                	ld	ra,56(sp)
    80002140:	7442                	ld	s0,48(sp)
    80002142:	74a2                	ld	s1,40(sp)
    80002144:	7902                	ld	s2,32(sp)
    80002146:	69e2                	ld	s3,24(sp)
    80002148:	6a42                	ld	s4,16(sp)
    8000214a:	6aa2                	ld	s5,8(sp)
    8000214c:	6121                	addi	sp,sp,64
    8000214e:	8082                	ret

0000000080002150 <reparent>:
{
    80002150:	7179                	addi	sp,sp,-48
    80002152:	f406                	sd	ra,40(sp)
    80002154:	f022                	sd	s0,32(sp)
    80002156:	ec26                	sd	s1,24(sp)
    80002158:	e84a                	sd	s2,16(sp)
    8000215a:	e44e                	sd	s3,8(sp)
    8000215c:	e052                	sd	s4,0(sp)
    8000215e:	1800                	addi	s0,sp,48
    80002160:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002162:	0000f497          	auipc	s1,0xf
    80002166:	e3e48493          	addi	s1,s1,-450 # 80010fa0 <proc>
      pp->parent = initproc;
    8000216a:	00006a17          	auipc	s4,0x6
    8000216e:	78ea0a13          	addi	s4,s4,1934 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002172:	00015997          	auipc	s3,0x15
    80002176:	a2e98993          	addi	s3,s3,-1490 # 80016ba0 <tickslock>
    8000217a:	a029                	j	80002184 <reparent+0x34>
    8000217c:	17048493          	addi	s1,s1,368
    80002180:	01348d63          	beq	s1,s3,8000219a <reparent+0x4a>
    if(pp->parent == p){
    80002184:	7c9c                	ld	a5,56(s1)
    80002186:	ff279be3          	bne	a5,s2,8000217c <reparent+0x2c>
      pp->parent = initproc;
    8000218a:	000a3503          	ld	a0,0(s4)
    8000218e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002190:	00000097          	auipc	ra,0x0
    80002194:	f4a080e7          	jalr	-182(ra) # 800020da <wakeup>
    80002198:	b7d5                	j	8000217c <reparent+0x2c>
}
    8000219a:	70a2                	ld	ra,40(sp)
    8000219c:	7402                	ld	s0,32(sp)
    8000219e:	64e2                	ld	s1,24(sp)
    800021a0:	6942                	ld	s2,16(sp)
    800021a2:	69a2                	ld	s3,8(sp)
    800021a4:	6a02                	ld	s4,0(sp)
    800021a6:	6145                	addi	sp,sp,48
    800021a8:	8082                	ret

00000000800021aa <exit>:
{
    800021aa:	7179                	addi	sp,sp,-48
    800021ac:	f406                	sd	ra,40(sp)
    800021ae:	f022                	sd	s0,32(sp)
    800021b0:	ec26                	sd	s1,24(sp)
    800021b2:	e84a                	sd	s2,16(sp)
    800021b4:	e44e                	sd	s3,8(sp)
    800021b6:	e052                	sd	s4,0(sp)
    800021b8:	1800                	addi	s0,sp,48
    800021ba:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	80a080e7          	jalr	-2038(ra) # 800019c6 <myproc>
    800021c4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c6:	00006797          	auipc	a5,0x6
    800021ca:	7327b783          	ld	a5,1842(a5) # 800088f8 <initproc>
    800021ce:	0d050493          	addi	s1,a0,208
    800021d2:	15050913          	addi	s2,a0,336
    800021d6:	02a79363          	bne	a5,a0,800021fc <exit+0x52>
    panic("init exiting");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	08650513          	addi	a0,a0,134 # 80008260 <digits+0x220>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	362080e7          	jalr	866(ra) # 80000544 <panic>
      fileclose(f);
    800021ea:	00002097          	auipc	ra,0x2
    800021ee:	34e080e7          	jalr	846(ra) # 80004538 <fileclose>
      p->ofile[fd] = 0;
    800021f2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f6:	04a1                	addi	s1,s1,8
    800021f8:	01248563          	beq	s1,s2,80002202 <exit+0x58>
    if(p->ofile[fd]){
    800021fc:	6088                	ld	a0,0(s1)
    800021fe:	f575                	bnez	a0,800021ea <exit+0x40>
    80002200:	bfdd                	j	800021f6 <exit+0x4c>
  begin_op();
    80002202:	00002097          	auipc	ra,0x2
    80002206:	e6a080e7          	jalr	-406(ra) # 8000406c <begin_op>
  iput(p->cwd);
    8000220a:	1509b503          	ld	a0,336(s3)
    8000220e:	00001097          	auipc	ra,0x1
    80002212:	656080e7          	jalr	1622(ra) # 80003864 <iput>
  end_op();
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	ed6080e7          	jalr	-298(ra) # 800040ec <end_op>
  p->cwd = 0;
    8000221e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	96648493          	addi	s1,s1,-1690 # 80010b88 <wait_lock>
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9be080e7          	jalr	-1602(ra) # 80000bea <acquire>
  reparent(p);
    80002234:	854e                	mv	a0,s3
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	f1a080e7          	jalr	-230(ra) # 80002150 <reparent>
  wakeup(p->parent);
    8000223e:	0389b503          	ld	a0,56(s3)
    80002242:	00000097          	auipc	ra,0x0
    80002246:	e98080e7          	jalr	-360(ra) # 800020da <wakeup>
  acquire(&p->lock);
    8000224a:	854e                	mv	a0,s3
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	99e080e7          	jalr	-1634(ra) # 80000bea <acquire>
  p->xstate = status;
    80002254:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002258:	4795                	li	a5,5
    8000225a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a3e080e7          	jalr	-1474(ra) # 80000c9e <release>
  sched();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	cfc080e7          	jalr	-772(ra) # 80001f64 <sched>
  panic("zombie exit");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	00050513          	mv	a0,a0
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2cc080e7          	jalr	716(ra) # 80000544 <panic>

0000000080002280 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002280:	7179                	addi	sp,sp,-48
    80002282:	f406                	sd	ra,40(sp)
    80002284:	f022                	sd	s0,32(sp)
    80002286:	ec26                	sd	s1,24(sp)
    80002288:	e84a                	sd	s2,16(sp)
    8000228a:	e44e                	sd	s3,8(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	d1048493          	addi	s1,s1,-752 # 80010fa0 <proc>
    80002298:	00015997          	auipc	s3,0x15
    8000229c:	90898993          	addi	s3,s3,-1784 # 80016ba0 <tickslock>
    acquire(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	948080e7          	jalr	-1720(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800022aa:	589c                	lw	a5,48(s1)
    800022ac:	01278d63          	beq	a5,s2,800022c6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9ec080e7          	jalr	-1556(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ba:	17048493          	addi	s1,s1,368
    800022be:	ff3491e3          	bne	s1,s3,800022a0 <kill+0x20>
  }
  return -1;
    800022c2:	557d                	li	a0,-1
    800022c4:	a829                	j	800022de <kill+0x5e>
      p->killed = 1;
    800022c6:	4785                	li	a5,1
    800022c8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022ca:	4c98                	lw	a4,24(s1)
    800022cc:	4789                	li	a5,2
    800022ce:	00f70f63          	beq	a4,a5,800022ec <kill+0x6c>
      release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9ca080e7          	jalr	-1590(ra) # 80000c9e <release>
      return 0;
    800022dc:	4501                	li	a0,0
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6145                	addi	sp,sp,48
    800022ea:	8082                	ret
        p->state = RUNNABLE;
    800022ec:	478d                	li	a5,3
    800022ee:	cc9c                	sw	a5,24(s1)
    800022f0:	b7cd                	j	800022d2 <kill+0x52>

00000000800022f2 <setkilled>:

void
setkilled(struct proc *p)
{
    800022f2:	1101                	addi	sp,sp,-32
    800022f4:	ec06                	sd	ra,24(sp)
    800022f6:	e822                	sd	s0,16(sp)
    800022f8:	e426                	sd	s1,8(sp)
    800022fa:	1000                	addi	s0,sp,32
    800022fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8ec080e7          	jalr	-1812(ra) # 80000bea <acquire>
  p->killed = 1;
    80002306:	4785                	li	a5,1
    80002308:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	992080e7          	jalr	-1646(ra) # 80000c9e <release>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <killed>:

int
killed(struct proc *p)
{
    8000231e:	1101                	addi	sp,sp,-32
    80002320:	ec06                	sd	ra,24(sp)
    80002322:	e822                	sd	s0,16(sp)
    80002324:	e426                	sd	s1,8(sp)
    80002326:	e04a                	sd	s2,0(sp)
    80002328:	1000                	addi	s0,sp,32
    8000232a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8be080e7          	jalr	-1858(ra) # 80000bea <acquire>
  k = p->killed;
    80002334:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	964080e7          	jalr	-1692(ra) # 80000c9e <release>
  return k;
}
    80002342:	854a                	mv	a0,s2
    80002344:	60e2                	ld	ra,24(sp)
    80002346:	6442                	ld	s0,16(sp)
    80002348:	64a2                	ld	s1,8(sp)
    8000234a:	6902                	ld	s2,0(sp)
    8000234c:	6105                	addi	sp,sp,32
    8000234e:	8082                	ret

0000000080002350 <wait>:
{
    80002350:	715d                	addi	sp,sp,-80
    80002352:	e486                	sd	ra,72(sp)
    80002354:	e0a2                	sd	s0,64(sp)
    80002356:	fc26                	sd	s1,56(sp)
    80002358:	f84a                	sd	s2,48(sp)
    8000235a:	f44e                	sd	s3,40(sp)
    8000235c:	f052                	sd	s4,32(sp)
    8000235e:	ec56                	sd	s5,24(sp)
    80002360:	e85a                	sd	s6,16(sp)
    80002362:	e45e                	sd	s7,8(sp)
    80002364:	e062                	sd	s8,0(sp)
    80002366:	0880                	addi	s0,sp,80
    80002368:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	65c080e7          	jalr	1628(ra) # 800019c6 <myproc>
    80002372:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	81450513          	addi	a0,a0,-2028 # 80010b88 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	86e080e7          	jalr	-1938(ra) # 80000bea <acquire>
    havekids = 0;
    80002384:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002386:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002388:	00015997          	auipc	s3,0x15
    8000238c:	81898993          	addi	s3,s3,-2024 # 80016ba0 <tickslock>
        havekids = 1;
    80002390:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002392:	0000ec17          	auipc	s8,0xe
    80002396:	7f6c0c13          	addi	s8,s8,2038 # 80010b88 <wait_lock>
    havekids = 0;
    8000239a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	c0448493          	addi	s1,s1,-1020 # 80010fa0 <proc>
    800023a4:	a0bd                	j	80002412 <wait+0xc2>
          pid = pp->pid;
    800023a6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023aa:	000b0e63          	beqz	s6,800023c6 <wait+0x76>
    800023ae:	4691                	li	a3,4
    800023b0:	02c48613          	addi	a2,s1,44
    800023b4:	85da                	mv	a1,s6
    800023b6:	05093503          	ld	a0,80(s2)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	2ca080e7          	jalr	714(ra) # 80001684 <copyout>
    800023c2:	02054563          	bltz	a0,800023ec <wait+0x9c>
          freeproc(pp);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	7b0080e7          	jalr	1968(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8cc080e7          	jalr	-1844(ra) # 80000c9e <release>
          release(&wait_lock);
    800023da:	0000e517          	auipc	a0,0xe
    800023de:	7ae50513          	addi	a0,a0,1966 # 80010b88 <wait_lock>
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8bc080e7          	jalr	-1860(ra) # 80000c9e <release>
          return pid;
    800023ea:	a0b5                	j	80002456 <wait+0x106>
            release(&pp->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8b0080e7          	jalr	-1872(ra) # 80000c9e <release>
            release(&wait_lock);
    800023f6:	0000e517          	auipc	a0,0xe
    800023fa:	79250513          	addi	a0,a0,1938 # 80010b88 <wait_lock>
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	8a0080e7          	jalr	-1888(ra) # 80000c9e <release>
            return -1;
    80002406:	59fd                	li	s3,-1
    80002408:	a0b9                	j	80002456 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240a:	17048493          	addi	s1,s1,368
    8000240e:	03348463          	beq	s1,s3,80002436 <wait+0xe6>
      if(pp->parent == p){
    80002412:	7c9c                	ld	a5,56(s1)
    80002414:	ff279be3          	bne	a5,s2,8000240a <wait+0xba>
        acquire(&pp->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7d0080e7          	jalr	2000(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002422:	4c9c                	lw	a5,24(s1)
    80002424:	f94781e3          	beq	a5,s4,800023a6 <wait+0x56>
        release(&pp->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	874080e7          	jalr	-1932(ra) # 80000c9e <release>
        havekids = 1;
    80002432:	8756                	mv	a4,s5
    80002434:	bfd9                	j	8000240a <wait+0xba>
    if(!havekids || killed(p)){
    80002436:	c719                	beqz	a4,80002444 <wait+0xf4>
    80002438:	854a                	mv	a0,s2
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	ee4080e7          	jalr	-284(ra) # 8000231e <killed>
    80002442:	c51d                	beqz	a0,80002470 <wait+0x120>
      release(&wait_lock);
    80002444:	0000e517          	auipc	a0,0xe
    80002448:	74450513          	addi	a0,a0,1860 # 80010b88 <wait_lock>
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	852080e7          	jalr	-1966(ra) # 80000c9e <release>
      return -1;
    80002454:	59fd                	li	s3,-1
}
    80002456:	854e                	mv	a0,s3
    80002458:	60a6                	ld	ra,72(sp)
    8000245a:	6406                	ld	s0,64(sp)
    8000245c:	74e2                	ld	s1,56(sp)
    8000245e:	7942                	ld	s2,48(sp)
    80002460:	79a2                	ld	s3,40(sp)
    80002462:	7a02                	ld	s4,32(sp)
    80002464:	6ae2                	ld	s5,24(sp)
    80002466:	6b42                	ld	s6,16(sp)
    80002468:	6ba2                	ld	s7,8(sp)
    8000246a:	6c02                	ld	s8,0(sp)
    8000246c:	6161                	addi	sp,sp,80
    8000246e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002470:	85e2                	mv	a1,s8
    80002472:	854a                	mv	a0,s2
    80002474:	00000097          	auipc	ra,0x0
    80002478:	c02080e7          	jalr	-1022(ra) # 80002076 <sleep>
    havekids = 0;
    8000247c:	bf39                	j	8000239a <wait+0x4a>

000000008000247e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	84aa                	mv	s1,a0
    80002490:	892e                	mv	s2,a1
    80002492:	89b2                	mv	s3,a2
    80002494:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	530080e7          	jalr	1328(ra) # 800019c6 <myproc>
  if(user_dst){
    8000249e:	c08d                	beqz	s1,800024c0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a0:	86d2                	mv	a3,s4
    800024a2:	864e                	mv	a2,s3
    800024a4:	85ca                	mv	a1,s2
    800024a6:	6928                	ld	a0,80(a0)
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	1dc080e7          	jalr	476(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
    memmove((char *)dst, src, len);
    800024c0:	000a061b          	sext.w	a2,s4
    800024c4:	85ce                	mv	a1,s3
    800024c6:	854a                	mv	a0,s2
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	87e080e7          	jalr	-1922(ra) # 80000d46 <memmove>
    return 0;
    800024d0:	8526                	mv	a0,s1
    800024d2:	bff9                	j	800024b0 <either_copyout+0x32>

00000000800024d4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	e052                	sd	s4,0(sp)
    800024e2:	1800                	addi	s0,sp,48
    800024e4:	892a                	mv	s2,a0
    800024e6:	84ae                	mv	s1,a1
    800024e8:	89b2                	mv	s3,a2
    800024ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	4da080e7          	jalr	1242(ra) # 800019c6 <myproc>
  if(user_src){
    800024f4:	c08d                	beqz	s1,80002516 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	212080e7          	jalr	530(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6a02                	ld	s4,0(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
    memmove(dst, (char*)src, len);
    80002516:	000a061b          	sext.w	a2,s4
    8000251a:	85ce                	mv	a1,s3
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	828080e7          	jalr	-2008(ra) # 80000d46 <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyin+0x32>

000000008000252a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000252a:	715d                	addi	sp,sp,-80
    8000252c:	e486                	sd	ra,72(sp)
    8000252e:	e0a2                	sd	s0,64(sp)
    80002530:	fc26                	sd	s1,56(sp)
    80002532:	f84a                	sd	s2,48(sp)
    80002534:	f44e                	sd	s3,40(sp)
    80002536:	f052                	sd	s4,32(sp)
    80002538:	ec56                	sd	s5,24(sp)
    8000253a:	e85a                	sd	s6,16(sp)
    8000253c:	e45e                	sd	s7,8(sp)
    8000253e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002540:	00006517          	auipc	a0,0x6
    80002544:	b8850513          	addi	a0,a0,-1144 # 800080c8 <digits+0x88>
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	046080e7          	jalr	70(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002550:	0000f497          	auipc	s1,0xf
    80002554:	ba848493          	addi	s1,s1,-1112 # 800110f8 <proc+0x158>
    80002558:	00014917          	auipc	s2,0x14
    8000255c:	7a090913          	addi	s2,s2,1952 # 80016cf8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002560:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002562:	00006997          	auipc	s3,0x6
    80002566:	d1e98993          	addi	s3,s3,-738 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000256a:	00006a97          	auipc	s5,0x6
    8000256e:	d1ea8a93          	addi	s5,s5,-738 # 80008288 <digits+0x248>
    printf("\n");
    80002572:	00006a17          	auipc	s4,0x6
    80002576:	b56a0a13          	addi	s4,s4,-1194 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257a:	00006b97          	auipc	s7,0x6
    8000257e:	d4eb8b93          	addi	s7,s7,-690 # 800082c8 <states.1723>
    80002582:	a00d                	j	800025a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002584:	ed86a583          	lw	a1,-296(a3)
    80002588:	8556                	mv	a0,s5
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	004080e7          	jalr	4(ra) # 8000058e <printf>
    printf("\n");
    80002592:	8552                	mv	a0,s4
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	ffa080e7          	jalr	-6(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000259c:	17048493          	addi	s1,s1,368
    800025a0:	03248163          	beq	s1,s2,800025c2 <procdump+0x98>
    if(p->state == UNUSED)
    800025a4:	86a6                	mv	a3,s1
    800025a6:	ec04a783          	lw	a5,-320(s1)
    800025aa:	dbed                	beqz	a5,8000259c <procdump+0x72>
      state = "???";
    800025ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ae:	fcfb6be3          	bltu	s6,a5,80002584 <procdump+0x5a>
    800025b2:	1782                	slli	a5,a5,0x20
    800025b4:	9381                	srli	a5,a5,0x20
    800025b6:	078e                	slli	a5,a5,0x3
    800025b8:	97de                	add	a5,a5,s7
    800025ba:	6390                	ld	a2,0(a5)
    800025bc:	f661                	bnez	a2,80002584 <procdump+0x5a>
      state = "???";
    800025be:	864e                	mv	a2,s3
    800025c0:	b7d1                	j	80002584 <procdump+0x5a>
  }
}
    800025c2:	60a6                	ld	ra,72(sp)
    800025c4:	6406                	ld	s0,64(sp)
    800025c6:	74e2                	ld	s1,56(sp)
    800025c8:	7942                	ld	s2,48(sp)
    800025ca:	79a2                	ld	s3,40(sp)
    800025cc:	7a02                	ld	s4,32(sp)
    800025ce:	6ae2                	ld	s5,24(sp)
    800025d0:	6b42                	ld	s6,16(sp)
    800025d2:	6ba2                	ld	s7,8(sp)
    800025d4:	6161                	addi	sp,sp,80
    800025d6:	8082                	ret

00000000800025d8 <swtch>:
    800025d8:	00153023          	sd	ra,0(a0)
    800025dc:	00253423          	sd	sp,8(a0)
    800025e0:	e900                	sd	s0,16(a0)
    800025e2:	ed04                	sd	s1,24(a0)
    800025e4:	03253023          	sd	s2,32(a0)
    800025e8:	03353423          	sd	s3,40(a0)
    800025ec:	03453823          	sd	s4,48(a0)
    800025f0:	03553c23          	sd	s5,56(a0)
    800025f4:	05653023          	sd	s6,64(a0)
    800025f8:	05753423          	sd	s7,72(a0)
    800025fc:	05853823          	sd	s8,80(a0)
    80002600:	05953c23          	sd	s9,88(a0)
    80002604:	07a53023          	sd	s10,96(a0)
    80002608:	07b53423          	sd	s11,104(a0)
    8000260c:	0005b083          	ld	ra,0(a1)
    80002610:	0085b103          	ld	sp,8(a1)
    80002614:	6980                	ld	s0,16(a1)
    80002616:	6d84                	ld	s1,24(a1)
    80002618:	0205b903          	ld	s2,32(a1)
    8000261c:	0285b983          	ld	s3,40(a1)
    80002620:	0305ba03          	ld	s4,48(a1)
    80002624:	0385ba83          	ld	s5,56(a1)
    80002628:	0405bb03          	ld	s6,64(a1)
    8000262c:	0485bb83          	ld	s7,72(a1)
    80002630:	0505bc03          	ld	s8,80(a1)
    80002634:	0585bc83          	ld	s9,88(a1)
    80002638:	0605bd03          	ld	s10,96(a1)
    8000263c:	0685bd83          	ld	s11,104(a1)
    80002640:	8082                	ret

0000000080002642 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002642:	1141                	addi	sp,sp,-16
    80002644:	e406                	sd	ra,8(sp)
    80002646:	e022                	sd	s0,0(sp)
    80002648:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000264a:	00006597          	auipc	a1,0x6
    8000264e:	cae58593          	addi	a1,a1,-850 # 800082f8 <states.1723+0x30>
    80002652:	00014517          	auipc	a0,0x14
    80002656:	54e50513          	addi	a0,a0,1358 # 80016ba0 <tickslock>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	500080e7          	jalr	1280(ra) # 80000b5a <initlock>
}
    80002662:	60a2                	ld	ra,8(sp)
    80002664:	6402                	ld	s0,0(sp)
    80002666:	0141                	addi	sp,sp,16
    80002668:	8082                	ret

000000008000266a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000266a:	1141                	addi	sp,sp,-16
    8000266c:	e422                	sd	s0,8(sp)
    8000266e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002670:	00003797          	auipc	a5,0x3
    80002674:	50078793          	addi	a5,a5,1280 # 80005b70 <kernelvec>
    80002678:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000267c:	6422                	ld	s0,8(sp)
    8000267e:	0141                	addi	sp,sp,16
    80002680:	8082                	ret

0000000080002682 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002682:	1141                	addi	sp,sp,-16
    80002684:	e406                	sd	ra,8(sp)
    80002686:	e022                	sd	s0,0(sp)
    80002688:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	33c080e7          	jalr	828(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002692:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002696:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002698:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000269c:	00005617          	auipc	a2,0x5
    800026a0:	96460613          	addi	a2,a2,-1692 # 80007000 <_trampoline>
    800026a4:	00005697          	auipc	a3,0x5
    800026a8:	95c68693          	addi	a3,a3,-1700 # 80007000 <_trampoline>
    800026ac:	8e91                	sub	a3,a3,a2
    800026ae:	040007b7          	lui	a5,0x4000
    800026b2:	17fd                	addi	a5,a5,-1
    800026b4:	07b2                	slli	a5,a5,0xc
    800026b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026be:	180026f3          	csrr	a3,satp
    800026c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c4:	6d38                	ld	a4,88(a0)
    800026c6:	6134                	ld	a3,64(a0)
    800026c8:	6585                	lui	a1,0x1
    800026ca:	96ae                	add	a3,a3,a1
    800026cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ce:	6d38                	ld	a4,88(a0)
    800026d0:	00000697          	auipc	a3,0x0
    800026d4:	13068693          	addi	a3,a3,304 # 80002800 <usertrap>
    800026d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026dc:	8692                	mv	a3,tp
    800026de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026f2:	6f18                	ld	a4,24(a4)
    800026f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026f8:	6928                	ld	a0,80(a0)
    800026fa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026fc:	00005717          	auipc	a4,0x5
    80002700:	9a070713          	addi	a4,a4,-1632 # 8000709c <userret>
    80002704:	8f11                	sub	a4,a4,a2
    80002706:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002708:	577d                	li	a4,-1
    8000270a:	177e                	slli	a4,a4,0x3f
    8000270c:	8d59                	or	a0,a0,a4
    8000270e:	9782                	jalr	a5
}
    80002710:	60a2                	ld	ra,8(sp)
    80002712:	6402                	ld	s0,0(sp)
    80002714:	0141                	addi	sp,sp,16
    80002716:	8082                	ret

0000000080002718 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002718:	1101                	addi	sp,sp,-32
    8000271a:	ec06                	sd	ra,24(sp)
    8000271c:	e822                	sd	s0,16(sp)
    8000271e:	e426                	sd	s1,8(sp)
    80002720:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002722:	00014497          	auipc	s1,0x14
    80002726:	47e48493          	addi	s1,s1,1150 # 80016ba0 <tickslock>
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	4be080e7          	jalr	1214(ra) # 80000bea <acquire>
  ticks++;
    80002734:	00006517          	auipc	a0,0x6
    80002738:	1cc50513          	addi	a0,a0,460 # 80008900 <ticks>
    8000273c:	411c                	lw	a5,0(a0)
    8000273e:	2785                	addiw	a5,a5,1
    80002740:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002742:	00000097          	auipc	ra,0x0
    80002746:	998080e7          	jalr	-1640(ra) # 800020da <wakeup>
  release(&tickslock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	552080e7          	jalr	1362(ra) # 80000c9e <release>
}
    80002754:	60e2                	ld	ra,24(sp)
    80002756:	6442                	ld	s0,16(sp)
    80002758:	64a2                	ld	s1,8(sp)
    8000275a:	6105                	addi	sp,sp,32
    8000275c:	8082                	ret

000000008000275e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000275e:	1101                	addi	sp,sp,-32
    80002760:	ec06                	sd	ra,24(sp)
    80002762:	e822                	sd	s0,16(sp)
    80002764:	e426                	sd	s1,8(sp)
    80002766:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002768:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000276c:	00074d63          	bltz	a4,80002786 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002770:	57fd                	li	a5,-1
    80002772:	17fe                	slli	a5,a5,0x3f
    80002774:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002776:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002778:	06f70363          	beq	a4,a5,800027de <devintr+0x80>
  }
}
    8000277c:	60e2                	ld	ra,24(sp)
    8000277e:	6442                	ld	s0,16(sp)
    80002780:	64a2                	ld	s1,8(sp)
    80002782:	6105                	addi	sp,sp,32
    80002784:	8082                	ret
     (scause & 0xff) == 9){
    80002786:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000278a:	46a5                	li	a3,9
    8000278c:	fed792e3          	bne	a5,a3,80002770 <devintr+0x12>
    int irq = plic_claim();
    80002790:	00003097          	auipc	ra,0x3
    80002794:	4e8080e7          	jalr	1256(ra) # 80005c78 <plic_claim>
    80002798:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000279a:	47a9                	li	a5,10
    8000279c:	02f50763          	beq	a0,a5,800027ca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a0:	4785                	li	a5,1
    800027a2:	02f50963          	beq	a0,a5,800027d4 <devintr+0x76>
    return 1;
    800027a6:	4505                	li	a0,1
    } else if(irq){
    800027a8:	d8f1                	beqz	s1,8000277c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027aa:	85a6                	mv	a1,s1
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	b5450513          	addi	a0,a0,-1196 # 80008300 <states.1723+0x38>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dda080e7          	jalr	-550(ra) # 8000058e <printf>
      plic_complete(irq);
    800027bc:	8526                	mv	a0,s1
    800027be:	00003097          	auipc	ra,0x3
    800027c2:	4de080e7          	jalr	1246(ra) # 80005c9c <plic_complete>
    return 1;
    800027c6:	4505                	li	a0,1
    800027c8:	bf55                	j	8000277c <devintr+0x1e>
      uartintr();
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	1e4080e7          	jalr	484(ra) # 800009ae <uartintr>
    800027d2:	b7ed                	j	800027bc <devintr+0x5e>
      virtio_disk_intr();
    800027d4:	00004097          	auipc	ra,0x4
    800027d8:	9f2080e7          	jalr	-1550(ra) # 800061c6 <virtio_disk_intr>
    800027dc:	b7c5                	j	800027bc <devintr+0x5e>
    if(cpuid() == 0){
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1bc080e7          	jalr	444(ra) # 8000199a <cpuid>
    800027e6:	c901                	beqz	a0,800027f6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ee:	14479073          	csrw	sip,a5
    return 2;
    800027f2:	4509                	li	a0,2
    800027f4:	b761                	j	8000277c <devintr+0x1e>
      clockintr();
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	f22080e7          	jalr	-222(ra) # 80002718 <clockintr>
    800027fe:	b7ed                	j	800027e8 <devintr+0x8a>

0000000080002800 <usertrap>:
{
    80002800:	1101                	addi	sp,sp,-32
    80002802:	ec06                	sd	ra,24(sp)
    80002804:	e822                	sd	s0,16(sp)
    80002806:	e426                	sd	s1,8(sp)
    80002808:	e04a                	sd	s2,0(sp)
    8000280a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002810:	1007f793          	andi	a5,a5,256
    80002814:	e3b1                	bnez	a5,80002858 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002816:	00003797          	auipc	a5,0x3
    8000281a:	35a78793          	addi	a5,a5,858 # 80005b70 <kernelvec>
    8000281e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	1a4080e7          	jalr	420(ra) # 800019c6 <myproc>
    8000282a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000282c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000282e:	14102773          	csrr	a4,sepc
    80002832:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002834:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002838:	47a1                	li	a5,8
    8000283a:	02f70763          	beq	a4,a5,80002868 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	f20080e7          	jalr	-224(ra) # 8000275e <devintr>
    80002846:	892a                	mv	s2,a0
    80002848:	c151                	beqz	a0,800028cc <usertrap+0xcc>
  if(killed(p))
    8000284a:	8526                	mv	a0,s1
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	ad2080e7          	jalr	-1326(ra) # 8000231e <killed>
    80002854:	c929                	beqz	a0,800028a6 <usertrap+0xa6>
    80002856:	a099                	j	8000289c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	ac850513          	addi	a0,a0,-1336 # 80008320 <states.1723+0x58>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	ce4080e7          	jalr	-796(ra) # 80000544 <panic>
    if(killed(p))
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	ab6080e7          	jalr	-1354(ra) # 8000231e <killed>
    80002870:	e921                	bnez	a0,800028c0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002872:	6cb8                	ld	a4,88(s1)
    80002874:	6f1c                	ld	a5,24(a4)
    80002876:	0791                	addi	a5,a5,4
    80002878:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000287e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002882:	10079073          	csrw	sstatus,a5
    syscall();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	2d4080e7          	jalr	724(ra) # 80002b5a <syscall>
  if(killed(p))
    8000288e:	8526                	mv	a0,s1
    80002890:	00000097          	auipc	ra,0x0
    80002894:	a8e080e7          	jalr	-1394(ra) # 8000231e <killed>
    80002898:	c911                	beqz	a0,800028ac <usertrap+0xac>
    8000289a:	4901                	li	s2,0
    exit(-1);
    8000289c:	557d                	li	a0,-1
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	90c080e7          	jalr	-1780(ra) # 800021aa <exit>
  if(which_dev == 2)
    800028a6:	4789                	li	a5,2
    800028a8:	04f90f63          	beq	s2,a5,80002906 <usertrap+0x106>
  usertrapret();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	dd6080e7          	jalr	-554(ra) # 80002682 <usertrapret>
}
    800028b4:	60e2                	ld	ra,24(sp)
    800028b6:	6442                	ld	s0,16(sp)
    800028b8:	64a2                	ld	s1,8(sp)
    800028ba:	6902                	ld	s2,0(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret
      exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	8e8080e7          	jalr	-1816(ra) # 800021aa <exit>
    800028ca:	b765                	j	80002872 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028cc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d0:	5890                	lw	a2,48(s1)
    800028d2:	00006517          	auipc	a0,0x6
    800028d6:	a6e50513          	addi	a0,a0,-1426 # 80008340 <states.1723+0x78>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	cb4080e7          	jalr	-844(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a8650513          	addi	a0,a0,-1402 # 80008370 <states.1723+0xa8>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c9c080e7          	jalr	-868(ra) # 8000058e <printf>
    setkilled(p);
    800028fa:	8526                	mv	a0,s1
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	9f6080e7          	jalr	-1546(ra) # 800022f2 <setkilled>
    80002904:	b769                	j	8000288e <usertrap+0x8e>
    yield();
    80002906:	fffff097          	auipc	ra,0xfffff
    8000290a:	734080e7          	jalr	1844(ra) # 8000203a <yield>
    8000290e:	bf79                	j	800028ac <usertrap+0xac>

0000000080002910 <kerneltrap>:
{
    80002910:	7179                	addi	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002922:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002926:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292a:	1004f793          	andi	a5,s1,256
    8000292e:	cb85                	beqz	a5,8000295e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002930:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002934:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002936:	ef85                	bnez	a5,8000296e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	e26080e7          	jalr	-474(ra) # 8000275e <devintr>
    80002940:	cd1d                	beqz	a0,8000297e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002942:	4789                	li	a5,2
    80002944:	06f50a63          	beq	a0,a5,800029b8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002948:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294c:	10049073          	csrw	sstatus,s1
}
    80002950:	70a2                	ld	ra,40(sp)
    80002952:	7402                	ld	s0,32(sp)
    80002954:	64e2                	ld	s1,24(sp)
    80002956:	6942                	ld	s2,16(sp)
    80002958:	69a2                	ld	s3,8(sp)
    8000295a:	6145                	addi	sp,sp,48
    8000295c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a3250513          	addi	a0,a0,-1486 # 80008390 <states.1723+0xc8>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	bde080e7          	jalr	-1058(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	a4a50513          	addi	a0,a0,-1462 # 800083b8 <states.1723+0xf0>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	bce080e7          	jalr	-1074(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000297e:	85ce                	mv	a1,s3
    80002980:	00006517          	auipc	a0,0x6
    80002984:	a5850513          	addi	a0,a0,-1448 # 800083d8 <states.1723+0x110>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c06080e7          	jalr	-1018(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002994:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	a5050513          	addi	a0,a0,-1456 # 800083e8 <states.1723+0x120>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bee080e7          	jalr	-1042(ra) # 8000058e <printf>
    panic("kerneltrap");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	a5850513          	addi	a0,a0,-1448 # 80008400 <states.1723+0x138>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b94080e7          	jalr	-1132(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	00e080e7          	jalr	14(ra) # 800019c6 <myproc>
    800029c0:	d541                	beqz	a0,80002948 <kerneltrap+0x38>
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	004080e7          	jalr	4(ra) # 800019c6 <myproc>
    800029ca:	4d18                	lw	a4,24(a0)
    800029cc:	4791                	li	a5,4
    800029ce:	f6f71de3          	bne	a4,a5,80002948 <kerneltrap+0x38>
    yield();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	668080e7          	jalr	1640(ra) # 8000203a <yield>
    800029da:	b7bd                	j	80002948 <kerneltrap+0x38>

00000000800029dc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029dc:	1101                	addi	sp,sp,-32
    800029de:	ec06                	sd	ra,24(sp)
    800029e0:	e822                	sd	s0,16(sp)
    800029e2:	e426                	sd	s1,8(sp)
    800029e4:	1000                	addi	s0,sp,32
    800029e6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	fde080e7          	jalr	-34(ra) # 800019c6 <myproc>
  switch (n) {
    800029f0:	4795                	li	a5,5
    800029f2:	0497e163          	bltu	a5,s1,80002a34 <argraw+0x58>
    800029f6:	048a                	slli	s1,s1,0x2
    800029f8:	00006717          	auipc	a4,0x6
    800029fc:	a5870713          	addi	a4,a4,-1448 # 80008450 <states.1723+0x188>
    80002a00:	94ba                	add	s1,s1,a4
    80002a02:	409c                	lw	a5,0(s1)
    80002a04:	97ba                	add	a5,a5,a4
    80002a06:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a08:	6d3c                	ld	a5,88(a0)
    80002a0a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0c:	60e2                	ld	ra,24(sp)
    80002a0e:	6442                	ld	s0,16(sp)
    80002a10:	64a2                	ld	s1,8(sp)
    80002a12:	6105                	addi	sp,sp,32
    80002a14:	8082                	ret
    return p->trapframe->a1;
    80002a16:	6d3c                	ld	a5,88(a0)
    80002a18:	7fa8                	ld	a0,120(a5)
    80002a1a:	bfcd                	j	80002a0c <argraw+0x30>
    return p->trapframe->a2;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	63c8                	ld	a0,128(a5)
    80002a20:	b7f5                	j	80002a0c <argraw+0x30>
    return p->trapframe->a3;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	67c8                	ld	a0,136(a5)
    80002a26:	b7dd                	j	80002a0c <argraw+0x30>
    return p->trapframe->a4;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	6bc8                	ld	a0,144(a5)
    80002a2c:	b7c5                	j	80002a0c <argraw+0x30>
    return p->trapframe->a5;
    80002a2e:	6d3c                	ld	a5,88(a0)
    80002a30:	6fc8                	ld	a0,152(a5)
    80002a32:	bfe9                	j	80002a0c <argraw+0x30>
  panic("argraw");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	9dc50513          	addi	a0,a0,-1572 # 80008410 <states.1723+0x148>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b08080e7          	jalr	-1272(ra) # 80000544 <panic>

0000000080002a44 <fetchaddr>:
{
    80002a44:	1101                	addi	sp,sp,-32
    80002a46:	ec06                	sd	ra,24(sp)
    80002a48:	e822                	sd	s0,16(sp)
    80002a4a:	e426                	sd	s1,8(sp)
    80002a4c:	e04a                	sd	s2,0(sp)
    80002a4e:	1000                	addi	s0,sp,32
    80002a50:	84aa                	mv	s1,a0
    80002a52:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f72080e7          	jalr	-142(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a5c:	653c                	ld	a5,72(a0)
    80002a5e:	02f4f863          	bgeu	s1,a5,80002a8e <fetchaddr+0x4a>
    80002a62:	00848713          	addi	a4,s1,8
    80002a66:	02e7e663          	bltu	a5,a4,80002a92 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6a:	46a1                	li	a3,8
    80002a6c:	8626                	mv	a2,s1
    80002a6e:	85ca                	mv	a1,s2
    80002a70:	6928                	ld	a0,80(a0)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	c9e080e7          	jalr	-866(ra) # 80001710 <copyin>
    80002a7a:	00a03533          	snez	a0,a0
    80002a7e:	40a00533          	neg	a0,a0
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6902                	ld	s2,0(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret
    return -1;
    80002a8e:	557d                	li	a0,-1
    80002a90:	bfcd                	j	80002a82 <fetchaddr+0x3e>
    80002a92:	557d                	li	a0,-1
    80002a94:	b7fd                	j	80002a82 <fetchaddr+0x3e>

0000000080002a96 <fetchstr>:
{
    80002a96:	7179                	addi	sp,sp,-48
    80002a98:	f406                	sd	ra,40(sp)
    80002a9a:	f022                	sd	s0,32(sp)
    80002a9c:	ec26                	sd	s1,24(sp)
    80002a9e:	e84a                	sd	s2,16(sp)
    80002aa0:	e44e                	sd	s3,8(sp)
    80002aa2:	1800                	addi	s0,sp,48
    80002aa4:	892a                	mv	s2,a0
    80002aa6:	84ae                	mv	s1,a1
    80002aa8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	f1c080e7          	jalr	-228(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ab2:	86ce                	mv	a3,s3
    80002ab4:	864a                	mv	a2,s2
    80002ab6:	85a6                	mv	a1,s1
    80002ab8:	6928                	ld	a0,80(a0)
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	ce2080e7          	jalr	-798(ra) # 8000179c <copyinstr>
    80002ac2:	00054e63          	bltz	a0,80002ade <fetchstr+0x48>
  return strlen(buf);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	3a2080e7          	jalr	930(ra) # 80000e6a <strlen>
}
    80002ad0:	70a2                	ld	ra,40(sp)
    80002ad2:	7402                	ld	s0,32(sp)
    80002ad4:	64e2                	ld	s1,24(sp)
    80002ad6:	6942                	ld	s2,16(sp)
    80002ad8:	69a2                	ld	s3,8(sp)
    80002ada:	6145                	addi	sp,sp,48
    80002adc:	8082                	ret
    return -1;
    80002ade:	557d                	li	a0,-1
    80002ae0:	bfc5                	j	80002ad0 <fetchstr+0x3a>

0000000080002ae2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	eee080e7          	jalr	-274(ra) # 800029dc <argraw>
    80002af6:	c088                	sw	a0,0(s1)
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	ece080e7          	jalr	-306(ra) # 800029dc <argraw>
    80002b16:	e088                	sd	a0,0(s1)
}
    80002b18:	60e2                	ld	ra,24(sp)
    80002b1a:	6442                	ld	s0,16(sp)
    80002b1c:	64a2                	ld	s1,8(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret

0000000080002b22 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b22:	7179                	addi	sp,sp,-48
    80002b24:	f406                	sd	ra,40(sp)
    80002b26:	f022                	sd	s0,32(sp)
    80002b28:	ec26                	sd	s1,24(sp)
    80002b2a:	e84a                	sd	s2,16(sp)
    80002b2c:	1800                	addi	s0,sp,48
    80002b2e:	84ae                	mv	s1,a1
    80002b30:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b32:	fd840593          	addi	a1,s0,-40
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	fcc080e7          	jalr	-52(ra) # 80002b02 <argaddr>
  return fetchstr(addr, buf, max);
    80002b3e:	864a                	mv	a2,s2
    80002b40:	85a6                	mv	a1,s1
    80002b42:	fd843503          	ld	a0,-40(s0)
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	f50080e7          	jalr	-176(ra) # 80002a96 <fetchstr>
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	6145                	addi	sp,sp,48
    80002b58:	8082                	ret

0000000080002b5a <syscall>:
[SYS_trace]   sys_trace,
};

void
syscall(void)
{
    80002b5a:	7179                	addi	sp,sp,-48
    80002b5c:	f406                	sd	ra,40(sp)
    80002b5e:	f022                	sd	s0,32(sp)
    80002b60:	ec26                	sd	s1,24(sp)
    80002b62:	e84a                	sd	s2,16(sp)
    80002b64:	e44e                	sd	s3,8(sp)
    80002b66:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e5e080e7          	jalr	-418(ra) # 800019c6 <myproc>
    80002b70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b72:	05853983          	ld	s3,88(a0)
    80002b76:	0a89b783          	ld	a5,168(s3)
    80002b7a:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7e:	37fd                	addiw	a5,a5,-1
    80002b80:	4755                	li	a4,21
    80002b82:	04f76263          	bltu	a4,a5,80002bc6 <syscall+0x6c>
    80002b86:	00391713          	slli	a4,s2,0x3
    80002b8a:	00006797          	auipc	a5,0x6
    80002b8e:	8de78793          	addi	a5,a5,-1826 # 80008468 <syscalls>
    80002b92:	97ba                	add	a5,a5,a4
    80002b94:	639c                	ld	a5,0(a5)
    80002b96:	cb85                	beqz	a5,80002bc6 <syscall+0x6c>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b98:	9782                	jalr	a5
    80002b9a:	06a9b823          	sd	a0,112(s3)
    if((1 << num) & p->mask) {
    80002b9e:	1684a683          	lw	a3,360(s1)
    80002ba2:	4126d6bb          	sraw	a3,a3,s2
    80002ba6:	8a85                	andi	a3,a3,1
    80002ba8:	ce95                	beqz	a3,80002be4 <syscall+0x8a>
      printf("%d: syscall %s -> %d\n", p->pid, p->name, p->trapframe->a0);
    80002baa:	6cbc                	ld	a5,88(s1)
    80002bac:	7bb4                	ld	a3,112(a5)
    80002bae:	15848613          	addi	a2,s1,344
    80002bb2:	588c                	lw	a1,48(s1)
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	86450513          	addi	a0,a0,-1948 # 80008418 <states.1723+0x150>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9d2080e7          	jalr	-1582(ra) # 8000058e <printf>
    80002bc4:	a005                	j	80002be4 <syscall+0x8a>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bc6:	86ca                	mv	a3,s2
    80002bc8:	15848613          	addi	a2,s1,344
    80002bcc:	588c                	lw	a1,48(s1)
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	86250513          	addi	a0,a0,-1950 # 80008430 <states.1723+0x168>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b8080e7          	jalr	-1608(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bde:	6cbc                	ld	a5,88(s1)
    80002be0:	577d                	li	a4,-1
    80002be2:	fbb8                	sd	a4,112(a5)
  }
}
    80002be4:	70a2                	ld	ra,40(sp)
    80002be6:	7402                	ld	s0,32(sp)
    80002be8:	64e2                	ld	s1,24(sp)
    80002bea:	6942                	ld	s2,16(sp)
    80002bec:	69a2                	ld	s3,8(sp)
    80002bee:	6145                	addi	sp,sp,48
    80002bf0:	8082                	ret

0000000080002bf2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bf2:	1101                	addi	sp,sp,-32
    80002bf4:	ec06                	sd	ra,24(sp)
    80002bf6:	e822                	sd	s0,16(sp)
    80002bf8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bfa:	fec40593          	addi	a1,s0,-20
    80002bfe:	4501                	li	a0,0
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	ee2080e7          	jalr	-286(ra) # 80002ae2 <argint>
  exit(n);
    80002c08:	fec42503          	lw	a0,-20(s0)
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	59e080e7          	jalr	1438(ra) # 800021aa <exit>
  return 0;  // not reached
}
    80002c14:	4501                	li	a0,0
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	6105                	addi	sp,sp,32
    80002c1c:	8082                	ret

0000000080002c1e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c1e:	1141                	addi	sp,sp,-16
    80002c20:	e406                	sd	ra,8(sp)
    80002c22:	e022                	sd	s0,0(sp)
    80002c24:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	da0080e7          	jalr	-608(ra) # 800019c6 <myproc>
}
    80002c2e:	5908                	lw	a0,48(a0)
    80002c30:	60a2                	ld	ra,8(sp)
    80002c32:	6402                	ld	s0,0(sp)
    80002c34:	0141                	addi	sp,sp,16
    80002c36:	8082                	ret

0000000080002c38 <sys_fork>:

uint64
sys_fork(void)
{
    80002c38:	1141                	addi	sp,sp,-16
    80002c3a:	e406                	sd	ra,8(sp)
    80002c3c:	e022                	sd	s0,0(sp)
    80002c3e:	0800                	addi	s0,sp,16
  return fork();
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	13c080e7          	jalr	316(ra) # 80001d7c <fork>
}
    80002c48:	60a2                	ld	ra,8(sp)
    80002c4a:	6402                	ld	s0,0(sp)
    80002c4c:	0141                	addi	sp,sp,16
    80002c4e:	8082                	ret

0000000080002c50 <sys_wait>:

uint64
sys_wait(void)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c58:	fe840593          	addi	a1,s0,-24
    80002c5c:	4501                	li	a0,0
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	ea4080e7          	jalr	-348(ra) # 80002b02 <argaddr>
  return wait(p);
    80002c66:	fe843503          	ld	a0,-24(s0)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	6e6080e7          	jalr	1766(ra) # 80002350 <wait>
}
    80002c72:	60e2                	ld	ra,24(sp)
    80002c74:	6442                	ld	s0,16(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret

0000000080002c7a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c7a:	7179                	addi	sp,sp,-48
    80002c7c:	f406                	sd	ra,40(sp)
    80002c7e:	f022                	sd	s0,32(sp)
    80002c80:	ec26                	sd	s1,24(sp)
    80002c82:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c84:	fdc40593          	addi	a1,s0,-36
    80002c88:	4501                	li	a0,0
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	e58080e7          	jalr	-424(ra) # 80002ae2 <argint>
  addr = myproc()->sz;
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d34080e7          	jalr	-716(ra) # 800019c6 <myproc>
    80002c9a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c9c:	fdc42503          	lw	a0,-36(s0)
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	080080e7          	jalr	128(ra) # 80001d20 <growproc>
    80002ca8:	00054863          	bltz	a0,80002cb8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cac:	8526                	mv	a0,s1
    80002cae:	70a2                	ld	ra,40(sp)
    80002cb0:	7402                	ld	s0,32(sp)
    80002cb2:	64e2                	ld	s1,24(sp)
    80002cb4:	6145                	addi	sp,sp,48
    80002cb6:	8082                	ret
    return -1;
    80002cb8:	54fd                	li	s1,-1
    80002cba:	bfcd                	j	80002cac <sys_sbrk+0x32>

0000000080002cbc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cbc:	7139                	addi	sp,sp,-64
    80002cbe:	fc06                	sd	ra,56(sp)
    80002cc0:	f822                	sd	s0,48(sp)
    80002cc2:	f426                	sd	s1,40(sp)
    80002cc4:	f04a                	sd	s2,32(sp)
    80002cc6:	ec4e                	sd	s3,24(sp)
    80002cc8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cca:	fcc40593          	addi	a1,s0,-52
    80002cce:	4501                	li	a0,0
    80002cd0:	00000097          	auipc	ra,0x0
    80002cd4:	e12080e7          	jalr	-494(ra) # 80002ae2 <argint>
  acquire(&tickslock);
    80002cd8:	00014517          	auipc	a0,0x14
    80002cdc:	ec850513          	addi	a0,a0,-312 # 80016ba0 <tickslock>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	f0a080e7          	jalr	-246(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002ce8:	00006917          	auipc	s2,0x6
    80002cec:	c1892903          	lw	s2,-1000(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002cf0:	fcc42783          	lw	a5,-52(s0)
    80002cf4:	cf9d                	beqz	a5,80002d32 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cf6:	00014997          	auipc	s3,0x14
    80002cfa:	eaa98993          	addi	s3,s3,-342 # 80016ba0 <tickslock>
    80002cfe:	00006497          	auipc	s1,0x6
    80002d02:	c0248493          	addi	s1,s1,-1022 # 80008900 <ticks>
    if(killed(myproc())){
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	cc0080e7          	jalr	-832(ra) # 800019c6 <myproc>
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	610080e7          	jalr	1552(ra) # 8000231e <killed>
    80002d16:	ed15                	bnez	a0,80002d52 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d18:	85ce                	mv	a1,s3
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	35a080e7          	jalr	858(ra) # 80002076 <sleep>
  while(ticks - ticks0 < n){
    80002d24:	409c                	lw	a5,0(s1)
    80002d26:	412787bb          	subw	a5,a5,s2
    80002d2a:	fcc42703          	lw	a4,-52(s0)
    80002d2e:	fce7ece3          	bltu	a5,a4,80002d06 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d32:	00014517          	auipc	a0,0x14
    80002d36:	e6e50513          	addi	a0,a0,-402 # 80016ba0 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	f64080e7          	jalr	-156(ra) # 80000c9e <release>
  return 0;
    80002d42:	4501                	li	a0,0
}
    80002d44:	70e2                	ld	ra,56(sp)
    80002d46:	7442                	ld	s0,48(sp)
    80002d48:	74a2                	ld	s1,40(sp)
    80002d4a:	7902                	ld	s2,32(sp)
    80002d4c:	69e2                	ld	s3,24(sp)
    80002d4e:	6121                	addi	sp,sp,64
    80002d50:	8082                	ret
      release(&tickslock);
    80002d52:	00014517          	auipc	a0,0x14
    80002d56:	e4e50513          	addi	a0,a0,-434 # 80016ba0 <tickslock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	f44080e7          	jalr	-188(ra) # 80000c9e <release>
      return -1;
    80002d62:	557d                	li	a0,-1
    80002d64:	b7c5                	j	80002d44 <sys_sleep+0x88>

0000000080002d66 <sys_kill>:

uint64
sys_kill(void)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d6e:	fec40593          	addi	a1,s0,-20
    80002d72:	4501                	li	a0,0
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	d6e080e7          	jalr	-658(ra) # 80002ae2 <argint>
  return kill(pid);
    80002d7c:	fec42503          	lw	a0,-20(s0)
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	500080e7          	jalr	1280(ra) # 80002280 <kill>
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	6105                	addi	sp,sp,32
    80002d8e:	8082                	ret

0000000080002d90 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	e0650513          	addi	a0,a0,-506 # 80016ba0 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	e48080e7          	jalr	-440(ra) # 80000bea <acquire>
  xticks = ticks;
    80002daa:	00006497          	auipc	s1,0x6
    80002dae:	b564a483          	lw	s1,-1194(s1) # 80008900 <ticks>
  release(&tickslock);
    80002db2:	00014517          	auipc	a0,0x14
    80002db6:	dee50513          	addi	a0,a0,-530 # 80016ba0 <tickslock>
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	ee4080e7          	jalr	-284(ra) # 80000c9e <release>
  return xticks;
}
    80002dc2:	02049513          	slli	a0,s1,0x20
    80002dc6:	9101                	srli	a0,a0,0x20
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	64a2                	ld	s1,8(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <sys_trace>:

//trace pid and system calls
uint64
sys_trace(void)
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80002dda:	fec40593          	addi	a1,s0,-20
    80002dde:	4501                	li	a0,0
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	d02080e7          	jalr	-766(ra) # 80002ae2 <argint>
  
  myproc()->mask = mask;
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	bde080e7          	jalr	-1058(ra) # 800019c6 <myproc>
    80002df0:	fec42783          	lw	a5,-20(s0)
    80002df4:	16f52423          	sw	a5,360(a0)
  return 0;
}
    80002df8:	4501                	li	a0,0
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	e052                	sd	s4,0(sp)
    80002e10:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e12:	00005597          	auipc	a1,0x5
    80002e16:	70e58593          	addi	a1,a1,1806 # 80008520 <syscalls+0xb8>
    80002e1a:	00014517          	auipc	a0,0x14
    80002e1e:	d9e50513          	addi	a0,a0,-610 # 80016bb8 <bcache>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	d38080e7          	jalr	-712(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e2a:	0001c797          	auipc	a5,0x1c
    80002e2e:	d8e78793          	addi	a5,a5,-626 # 8001ebb8 <bcache+0x8000>
    80002e32:	0001c717          	auipc	a4,0x1c
    80002e36:	fee70713          	addi	a4,a4,-18 # 8001ee20 <bcache+0x8268>
    80002e3a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e3e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e42:	00014497          	auipc	s1,0x14
    80002e46:	d8e48493          	addi	s1,s1,-626 # 80016bd0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e4a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e4c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e4e:	00005a17          	auipc	s4,0x5
    80002e52:	6daa0a13          	addi	s4,s4,1754 # 80008528 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e56:	2b893783          	ld	a5,696(s2)
    80002e5a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e5c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e60:	85d2                	mv	a1,s4
    80002e62:	01048513          	addi	a0,s1,16
    80002e66:	00001097          	auipc	ra,0x1
    80002e6a:	4c4080e7          	jalr	1220(ra) # 8000432a <initsleeplock>
    bcache.head.next->prev = b;
    80002e6e:	2b893783          	ld	a5,696(s2)
    80002e72:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e74:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e78:	45848493          	addi	s1,s1,1112
    80002e7c:	fd349de3          	bne	s1,s3,80002e56 <binit+0x54>
  }
}
    80002e80:	70a2                	ld	ra,40(sp)
    80002e82:	7402                	ld	s0,32(sp)
    80002e84:	64e2                	ld	s1,24(sp)
    80002e86:	6942                	ld	s2,16(sp)
    80002e88:	69a2                	ld	s3,8(sp)
    80002e8a:	6a02                	ld	s4,0(sp)
    80002e8c:	6145                	addi	sp,sp,48
    80002e8e:	8082                	ret

0000000080002e90 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	1800                	addi	s0,sp,48
    80002e9e:	89aa                	mv	s3,a0
    80002ea0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	d1650513          	addi	a0,a0,-746 # 80016bb8 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	d40080e7          	jalr	-704(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eb2:	0001c497          	auipc	s1,0x1c
    80002eb6:	fbe4b483          	ld	s1,-66(s1) # 8001ee70 <bcache+0x82b8>
    80002eba:	0001c797          	auipc	a5,0x1c
    80002ebe:	f6678793          	addi	a5,a5,-154 # 8001ee20 <bcache+0x8268>
    80002ec2:	02f48f63          	beq	s1,a5,80002f00 <bread+0x70>
    80002ec6:	873e                	mv	a4,a5
    80002ec8:	a021                	j	80002ed0 <bread+0x40>
    80002eca:	68a4                	ld	s1,80(s1)
    80002ecc:	02e48a63          	beq	s1,a4,80002f00 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ed0:	449c                	lw	a5,8(s1)
    80002ed2:	ff379ce3          	bne	a5,s3,80002eca <bread+0x3a>
    80002ed6:	44dc                	lw	a5,12(s1)
    80002ed8:	ff2799e3          	bne	a5,s2,80002eca <bread+0x3a>
      b->refcnt++;
    80002edc:	40bc                	lw	a5,64(s1)
    80002ede:	2785                	addiw	a5,a5,1
    80002ee0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee2:	00014517          	auipc	a0,0x14
    80002ee6:	cd650513          	addi	a0,a0,-810 # 80016bb8 <bcache>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	db4080e7          	jalr	-588(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002ef2:	01048513          	addi	a0,s1,16
    80002ef6:	00001097          	auipc	ra,0x1
    80002efa:	46e080e7          	jalr	1134(ra) # 80004364 <acquiresleep>
      return b;
    80002efe:	a8b9                	j	80002f5c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f00:	0001c497          	auipc	s1,0x1c
    80002f04:	f684b483          	ld	s1,-152(s1) # 8001ee68 <bcache+0x82b0>
    80002f08:	0001c797          	auipc	a5,0x1c
    80002f0c:	f1878793          	addi	a5,a5,-232 # 8001ee20 <bcache+0x8268>
    80002f10:	00f48863          	beq	s1,a5,80002f20 <bread+0x90>
    80002f14:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f16:	40bc                	lw	a5,64(s1)
    80002f18:	cf81                	beqz	a5,80002f30 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f1a:	64a4                	ld	s1,72(s1)
    80002f1c:	fee49de3          	bne	s1,a4,80002f16 <bread+0x86>
  panic("bget: no buffers");
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	61050513          	addi	a0,a0,1552 # 80008530 <syscalls+0xc8>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	61c080e7          	jalr	1564(ra) # 80000544 <panic>
      b->dev = dev;
    80002f30:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f34:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f38:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f3c:	4785                	li	a5,1
    80002f3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	c7850513          	addi	a0,a0,-904 # 80016bb8 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d56080e7          	jalr	-682(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002f50:	01048513          	addi	a0,s1,16
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	410080e7          	jalr	1040(ra) # 80004364 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f5c:	409c                	lw	a5,0(s1)
    80002f5e:	cb89                	beqz	a5,80002f70 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f60:	8526                	mv	a0,s1
    80002f62:	70a2                	ld	ra,40(sp)
    80002f64:	7402                	ld	s0,32(sp)
    80002f66:	64e2                	ld	s1,24(sp)
    80002f68:	6942                	ld	s2,16(sp)
    80002f6a:	69a2                	ld	s3,8(sp)
    80002f6c:	6145                	addi	sp,sp,48
    80002f6e:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f70:	4581                	li	a1,0
    80002f72:	8526                	mv	a0,s1
    80002f74:	00003097          	auipc	ra,0x3
    80002f78:	fc4080e7          	jalr	-60(ra) # 80005f38 <virtio_disk_rw>
    b->valid = 1;
    80002f7c:	4785                	li	a5,1
    80002f7e:	c09c                	sw	a5,0(s1)
  return b;
    80002f80:	b7c5                	j	80002f60 <bread+0xd0>

0000000080002f82 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	1000                	addi	s0,sp,32
    80002f8c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f8e:	0541                	addi	a0,a0,16
    80002f90:	00001097          	auipc	ra,0x1
    80002f94:	46e080e7          	jalr	1134(ra) # 800043fe <holdingsleep>
    80002f98:	cd01                	beqz	a0,80002fb0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f9a:	4585                	li	a1,1
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	00003097          	auipc	ra,0x3
    80002fa2:	f9a080e7          	jalr	-102(ra) # 80005f38 <virtio_disk_rw>
}
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret
    panic("bwrite");
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	59850513          	addi	a0,a0,1432 # 80008548 <syscalls+0xe0>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	58c080e7          	jalr	1420(ra) # 80000544 <panic>

0000000080002fc0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	e04a                	sd	s2,0(sp)
    80002fca:	1000                	addi	s0,sp,32
    80002fcc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fce:	01050913          	addi	s2,a0,16
    80002fd2:	854a                	mv	a0,s2
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	42a080e7          	jalr	1066(ra) # 800043fe <holdingsleep>
    80002fdc:	c92d                	beqz	a0,8000304e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fde:	854a                	mv	a0,s2
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	3da080e7          	jalr	986(ra) # 800043ba <releasesleep>

  acquire(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	bd050513          	addi	a0,a0,-1072 # 80016bb8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	bfa080e7          	jalr	-1030(ra) # 80000bea <acquire>
  b->refcnt--;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	37fd                	addiw	a5,a5,-1
    80002ffc:	0007871b          	sext.w	a4,a5
    80003000:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003002:	eb05                	bnez	a4,80003032 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003004:	68bc                	ld	a5,80(s1)
    80003006:	64b8                	ld	a4,72(s1)
    80003008:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000300a:	64bc                	ld	a5,72(s1)
    8000300c:	68b8                	ld	a4,80(s1)
    8000300e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003010:	0001c797          	auipc	a5,0x1c
    80003014:	ba878793          	addi	a5,a5,-1112 # 8001ebb8 <bcache+0x8000>
    80003018:	2b87b703          	ld	a4,696(a5)
    8000301c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000301e:	0001c717          	auipc	a4,0x1c
    80003022:	e0270713          	addi	a4,a4,-510 # 8001ee20 <bcache+0x8268>
    80003026:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003028:	2b87b703          	ld	a4,696(a5)
    8000302c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000302e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	b8650513          	addi	a0,a0,-1146 # 80016bb8 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c64080e7          	jalr	-924(ra) # 80000c9e <release>
}
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6902                	ld	s2,0(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret
    panic("brelse");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	50250513          	addi	a0,a0,1282 # 80008550 <syscalls+0xe8>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	4ee080e7          	jalr	1262(ra) # 80000544 <panic>

000000008000305e <bpin>:

void
bpin(struct buf *b) {
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	b4e50513          	addi	a0,a0,-1202 # 80016bb8 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	b78080e7          	jalr	-1160(ra) # 80000bea <acquire>
  b->refcnt++;
    8000307a:	40bc                	lw	a5,64(s1)
    8000307c:	2785                	addiw	a5,a5,1
    8000307e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003080:	00014517          	auipc	a0,0x14
    80003084:	b3850513          	addi	a0,a0,-1224 # 80016bb8 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	c16080e7          	jalr	-1002(ra) # 80000c9e <release>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret

000000008000309a <bunpin>:

void
bunpin(struct buf *b) {
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a6:	00014517          	auipc	a0,0x14
    800030aa:	b1250513          	addi	a0,a0,-1262 # 80016bb8 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	b3c080e7          	jalr	-1220(ra) # 80000bea <acquire>
  b->refcnt--;
    800030b6:	40bc                	lw	a5,64(s1)
    800030b8:	37fd                	addiw	a5,a5,-1
    800030ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	afc50513          	addi	a0,a0,-1284 # 80016bb8 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bda080e7          	jalr	-1062(ra) # 80000c9e <release>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	e04a                	sd	s2,0(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030e4:	00d5d59b          	srliw	a1,a1,0xd
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	1ac7a783          	lw	a5,428(a5) # 8001f294 <sb+0x1c>
    800030f0:	9dbd                	addw	a1,a1,a5
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	d9e080e7          	jalr	-610(ra) # 80002e90 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030fa:	0074f713          	andi	a4,s1,7
    800030fe:	4785                	li	a5,1
    80003100:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003104:	14ce                	slli	s1,s1,0x33
    80003106:	90d9                	srli	s1,s1,0x36
    80003108:	00950733          	add	a4,a0,s1
    8000310c:	05874703          	lbu	a4,88(a4)
    80003110:	00e7f6b3          	and	a3,a5,a4
    80003114:	c69d                	beqz	a3,80003142 <bfree+0x6c>
    80003116:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003118:	94aa                	add	s1,s1,a0
    8000311a:	fff7c793          	not	a5,a5
    8000311e:	8ff9                	and	a5,a5,a4
    80003120:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003124:	00001097          	auipc	ra,0x1
    80003128:	120080e7          	jalr	288(ra) # 80004244 <log_write>
  brelse(bp);
    8000312c:	854a                	mv	a0,s2
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e92080e7          	jalr	-366(ra) # 80002fc0 <brelse>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6902                	ld	s2,0(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
    panic("freeing free block");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	41650513          	addi	a0,a0,1046 # 80008558 <syscalls+0xf0>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3fa080e7          	jalr	1018(ra) # 80000544 <panic>

0000000080003152 <balloc>:
{
    80003152:	711d                	addi	sp,sp,-96
    80003154:	ec86                	sd	ra,88(sp)
    80003156:	e8a2                	sd	s0,80(sp)
    80003158:	e4a6                	sd	s1,72(sp)
    8000315a:	e0ca                	sd	s2,64(sp)
    8000315c:	fc4e                	sd	s3,56(sp)
    8000315e:	f852                	sd	s4,48(sp)
    80003160:	f456                	sd	s5,40(sp)
    80003162:	f05a                	sd	s6,32(sp)
    80003164:	ec5e                	sd	s7,24(sp)
    80003166:	e862                	sd	s8,16(sp)
    80003168:	e466                	sd	s9,8(sp)
    8000316a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	1107a783          	lw	a5,272(a5) # 8001f27c <sb+0x4>
    80003174:	10078163          	beqz	a5,80003276 <balloc+0x124>
    80003178:	8baa                	mv	s7,a0
    8000317a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000317c:	0001cb17          	auipc	s6,0x1c
    80003180:	0fcb0b13          	addi	s6,s6,252 # 8001f278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003184:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003186:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003188:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000318a:	6c89                	lui	s9,0x2
    8000318c:	a061                	j	80003214 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000318e:	974a                	add	a4,a4,s2
    80003190:	8fd5                	or	a5,a5,a3
    80003192:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	0ac080e7          	jalr	172(ra) # 80004244 <log_write>
        brelse(bp);
    800031a0:	854a                	mv	a0,s2
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	e1e080e7          	jalr	-482(ra) # 80002fc0 <brelse>
  bp = bread(dev, bno);
    800031aa:	85a6                	mv	a1,s1
    800031ac:	855e                	mv	a0,s7
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	ce2080e7          	jalr	-798(ra) # 80002e90 <bread>
    800031b6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031b8:	40000613          	li	a2,1024
    800031bc:	4581                	li	a1,0
    800031be:	05850513          	addi	a0,a0,88
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b24080e7          	jalr	-1244(ra) # 80000ce6 <memset>
  log_write(bp);
    800031ca:	854a                	mv	a0,s2
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	078080e7          	jalr	120(ra) # 80004244 <log_write>
  brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	dea080e7          	jalr	-534(ra) # 80002fc0 <brelse>
}
    800031de:	8526                	mv	a0,s1
    800031e0:	60e6                	ld	ra,88(sp)
    800031e2:	6446                	ld	s0,80(sp)
    800031e4:	64a6                	ld	s1,72(sp)
    800031e6:	6906                	ld	s2,64(sp)
    800031e8:	79e2                	ld	s3,56(sp)
    800031ea:	7a42                	ld	s4,48(sp)
    800031ec:	7aa2                	ld	s5,40(sp)
    800031ee:	7b02                	ld	s6,32(sp)
    800031f0:	6be2                	ld	s7,24(sp)
    800031f2:	6c42                	ld	s8,16(sp)
    800031f4:	6ca2                	ld	s9,8(sp)
    800031f6:	6125                	addi	sp,sp,96
    800031f8:	8082                	ret
    brelse(bp);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	dc4080e7          	jalr	-572(ra) # 80002fc0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003204:	015c87bb          	addw	a5,s9,s5
    80003208:	00078a9b          	sext.w	s5,a5
    8000320c:	004b2703          	lw	a4,4(s6)
    80003210:	06eaf363          	bgeu	s5,a4,80003276 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003214:	41fad79b          	sraiw	a5,s5,0x1f
    80003218:	0137d79b          	srliw	a5,a5,0x13
    8000321c:	015787bb          	addw	a5,a5,s5
    80003220:	40d7d79b          	sraiw	a5,a5,0xd
    80003224:	01cb2583          	lw	a1,28(s6)
    80003228:	9dbd                	addw	a1,a1,a5
    8000322a:	855e                	mv	a0,s7
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	c64080e7          	jalr	-924(ra) # 80002e90 <bread>
    80003234:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003236:	004b2503          	lw	a0,4(s6)
    8000323a:	000a849b          	sext.w	s1,s5
    8000323e:	8662                	mv	a2,s8
    80003240:	faa4fde3          	bgeu	s1,a0,800031fa <balloc+0xa8>
      m = 1 << (bi % 8);
    80003244:	41f6579b          	sraiw	a5,a2,0x1f
    80003248:	01d7d69b          	srliw	a3,a5,0x1d
    8000324c:	00c6873b          	addw	a4,a3,a2
    80003250:	00777793          	andi	a5,a4,7
    80003254:	9f95                	subw	a5,a5,a3
    80003256:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000325a:	4037571b          	sraiw	a4,a4,0x3
    8000325e:	00e906b3          	add	a3,s2,a4
    80003262:	0586c683          	lbu	a3,88(a3)
    80003266:	00d7f5b3          	and	a1,a5,a3
    8000326a:	d195                	beqz	a1,8000318e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	2605                	addiw	a2,a2,1
    8000326e:	2485                	addiw	s1,s1,1
    80003270:	fd4618e3          	bne	a2,s4,80003240 <balloc+0xee>
    80003274:	b759                	j	800031fa <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	2fa50513          	addi	a0,a0,762 # 80008570 <syscalls+0x108>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	310080e7          	jalr	784(ra) # 8000058e <printf>
  return 0;
    80003286:	4481                	li	s1,0
    80003288:	bf99                	j	800031de <balloc+0x8c>

000000008000328a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	e052                	sd	s4,0(sp)
    80003298:	1800                	addi	s0,sp,48
    8000329a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000329c:	47ad                	li	a5,11
    8000329e:	02b7e763          	bltu	a5,a1,800032cc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800032a2:	02059493          	slli	s1,a1,0x20
    800032a6:	9081                	srli	s1,s1,0x20
    800032a8:	048a                	slli	s1,s1,0x2
    800032aa:	94aa                	add	s1,s1,a0
    800032ac:	0504a903          	lw	s2,80(s1)
    800032b0:	06091e63          	bnez	s2,8000332c <bmap+0xa2>
      addr = balloc(ip->dev);
    800032b4:	4108                	lw	a0,0(a0)
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	e9c080e7          	jalr	-356(ra) # 80003152 <balloc>
    800032be:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032c2:	06090563          	beqz	s2,8000332c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800032c6:	0524a823          	sw	s2,80(s1)
    800032ca:	a08d                	j	8000332c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032cc:	ff45849b          	addiw	s1,a1,-12
    800032d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032d4:	0ff00793          	li	a5,255
    800032d8:	08e7e563          	bltu	a5,a4,80003362 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032dc:	08052903          	lw	s2,128(a0)
    800032e0:	00091d63          	bnez	s2,800032fa <bmap+0x70>
      addr = balloc(ip->dev);
    800032e4:	4108                	lw	a0,0(a0)
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	e6c080e7          	jalr	-404(ra) # 80003152 <balloc>
    800032ee:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032f2:	02090d63          	beqz	s2,8000332c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032f6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800032fa:	85ca                	mv	a1,s2
    800032fc:	0009a503          	lw	a0,0(s3)
    80003300:	00000097          	auipc	ra,0x0
    80003304:	b90080e7          	jalr	-1136(ra) # 80002e90 <bread>
    80003308:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000330a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000330e:	02049593          	slli	a1,s1,0x20
    80003312:	9181                	srli	a1,a1,0x20
    80003314:	058a                	slli	a1,a1,0x2
    80003316:	00b784b3          	add	s1,a5,a1
    8000331a:	0004a903          	lw	s2,0(s1)
    8000331e:	02090063          	beqz	s2,8000333e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003322:	8552                	mv	a0,s4
    80003324:	00000097          	auipc	ra,0x0
    80003328:	c9c080e7          	jalr	-868(ra) # 80002fc0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000332c:	854a                	mv	a0,s2
    8000332e:	70a2                	ld	ra,40(sp)
    80003330:	7402                	ld	s0,32(sp)
    80003332:	64e2                	ld	s1,24(sp)
    80003334:	6942                	ld	s2,16(sp)
    80003336:	69a2                	ld	s3,8(sp)
    80003338:	6a02                	ld	s4,0(sp)
    8000333a:	6145                	addi	sp,sp,48
    8000333c:	8082                	ret
      addr = balloc(ip->dev);
    8000333e:	0009a503          	lw	a0,0(s3)
    80003342:	00000097          	auipc	ra,0x0
    80003346:	e10080e7          	jalr	-496(ra) # 80003152 <balloc>
    8000334a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000334e:	fc090ae3          	beqz	s2,80003322 <bmap+0x98>
        a[bn] = addr;
    80003352:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003356:	8552                	mv	a0,s4
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	eec080e7          	jalr	-276(ra) # 80004244 <log_write>
    80003360:	b7c9                	j	80003322 <bmap+0x98>
  panic("bmap: out of range");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	22650513          	addi	a0,a0,550 # 80008588 <syscalls+0x120>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1da080e7          	jalr	474(ra) # 80000544 <panic>

0000000080003372 <iget>:
{
    80003372:	7179                	addi	sp,sp,-48
    80003374:	f406                	sd	ra,40(sp)
    80003376:	f022                	sd	s0,32(sp)
    80003378:	ec26                	sd	s1,24(sp)
    8000337a:	e84a                	sd	s2,16(sp)
    8000337c:	e44e                	sd	s3,8(sp)
    8000337e:	e052                	sd	s4,0(sp)
    80003380:	1800                	addi	s0,sp,48
    80003382:	89aa                	mv	s3,a0
    80003384:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003386:	0001c517          	auipc	a0,0x1c
    8000338a:	f1250513          	addi	a0,a0,-238 # 8001f298 <itable>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	85c080e7          	jalr	-1956(ra) # 80000bea <acquire>
  empty = 0;
    80003396:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003398:	0001c497          	auipc	s1,0x1c
    8000339c:	f1848493          	addi	s1,s1,-232 # 8001f2b0 <itable+0x18>
    800033a0:	0001e697          	auipc	a3,0x1e
    800033a4:	9a068693          	addi	a3,a3,-1632 # 80020d40 <log>
    800033a8:	a039                	j	800033b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033aa:	02090b63          	beqz	s2,800033e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ae:	08848493          	addi	s1,s1,136
    800033b2:	02d48a63          	beq	s1,a3,800033e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033b6:	449c                	lw	a5,8(s1)
    800033b8:	fef059e3          	blez	a5,800033aa <iget+0x38>
    800033bc:	4098                	lw	a4,0(s1)
    800033be:	ff3716e3          	bne	a4,s3,800033aa <iget+0x38>
    800033c2:	40d8                	lw	a4,4(s1)
    800033c4:	ff4713e3          	bne	a4,s4,800033aa <iget+0x38>
      ip->ref++;
    800033c8:	2785                	addiw	a5,a5,1
    800033ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033cc:	0001c517          	auipc	a0,0x1c
    800033d0:	ecc50513          	addi	a0,a0,-308 # 8001f298 <itable>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	8ca080e7          	jalr	-1846(ra) # 80000c9e <release>
      return ip;
    800033dc:	8926                	mv	s2,s1
    800033de:	a03d                	j	8000340c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e0:	f7f9                	bnez	a5,800033ae <iget+0x3c>
    800033e2:	8926                	mv	s2,s1
    800033e4:	b7e9                	j	800033ae <iget+0x3c>
  if(empty == 0)
    800033e6:	02090c63          	beqz	s2,8000341e <iget+0xac>
  ip->dev = dev;
    800033ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033f2:	4785                	li	a5,1
    800033f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033fc:	0001c517          	auipc	a0,0x1c
    80003400:	e9c50513          	addi	a0,a0,-356 # 8001f298 <itable>
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	89a080e7          	jalr	-1894(ra) # 80000c9e <release>
}
    8000340c:	854a                	mv	a0,s2
    8000340e:	70a2                	ld	ra,40(sp)
    80003410:	7402                	ld	s0,32(sp)
    80003412:	64e2                	ld	s1,24(sp)
    80003414:	6942                	ld	s2,16(sp)
    80003416:	69a2                	ld	s3,8(sp)
    80003418:	6a02                	ld	s4,0(sp)
    8000341a:	6145                	addi	sp,sp,48
    8000341c:	8082                	ret
    panic("iget: no inodes");
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	18250513          	addi	a0,a0,386 # 800085a0 <syscalls+0x138>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	11e080e7          	jalr	286(ra) # 80000544 <panic>

000000008000342e <fsinit>:
fsinit(int dev) {
    8000342e:	7179                	addi	sp,sp,-48
    80003430:	f406                	sd	ra,40(sp)
    80003432:	f022                	sd	s0,32(sp)
    80003434:	ec26                	sd	s1,24(sp)
    80003436:	e84a                	sd	s2,16(sp)
    80003438:	e44e                	sd	s3,8(sp)
    8000343a:	1800                	addi	s0,sp,48
    8000343c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000343e:	4585                	li	a1,1
    80003440:	00000097          	auipc	ra,0x0
    80003444:	a50080e7          	jalr	-1456(ra) # 80002e90 <bread>
    80003448:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000344a:	0001c997          	auipc	s3,0x1c
    8000344e:	e2e98993          	addi	s3,s3,-466 # 8001f278 <sb>
    80003452:	02000613          	li	a2,32
    80003456:	05850593          	addi	a1,a0,88
    8000345a:	854e                	mv	a0,s3
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	8ea080e7          	jalr	-1814(ra) # 80000d46 <memmove>
  brelse(bp);
    80003464:	8526                	mv	a0,s1
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	b5a080e7          	jalr	-1190(ra) # 80002fc0 <brelse>
  if(sb.magic != FSMAGIC)
    8000346e:	0009a703          	lw	a4,0(s3)
    80003472:	102037b7          	lui	a5,0x10203
    80003476:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000347a:	02f71263          	bne	a4,a5,8000349e <fsinit+0x70>
  initlog(dev, &sb);
    8000347e:	0001c597          	auipc	a1,0x1c
    80003482:	dfa58593          	addi	a1,a1,-518 # 8001f278 <sb>
    80003486:	854a                	mv	a0,s2
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	b40080e7          	jalr	-1216(ra) # 80003fc8 <initlog>
}
    80003490:	70a2                	ld	ra,40(sp)
    80003492:	7402                	ld	s0,32(sp)
    80003494:	64e2                	ld	s1,24(sp)
    80003496:	6942                	ld	s2,16(sp)
    80003498:	69a2                	ld	s3,8(sp)
    8000349a:	6145                	addi	sp,sp,48
    8000349c:	8082                	ret
    panic("invalid file system");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	11250513          	addi	a0,a0,274 # 800085b0 <syscalls+0x148>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	09e080e7          	jalr	158(ra) # 80000544 <panic>

00000000800034ae <iinit>:
{
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034bc:	00005597          	auipc	a1,0x5
    800034c0:	10c58593          	addi	a1,a1,268 # 800085c8 <syscalls+0x160>
    800034c4:	0001c517          	auipc	a0,0x1c
    800034c8:	dd450513          	addi	a0,a0,-556 # 8001f298 <itable>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	68e080e7          	jalr	1678(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800034d4:	0001c497          	auipc	s1,0x1c
    800034d8:	dec48493          	addi	s1,s1,-532 # 8001f2c0 <itable+0x28>
    800034dc:	0001e997          	auipc	s3,0x1e
    800034e0:	87498993          	addi	s3,s3,-1932 # 80020d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034e4:	00005917          	auipc	s2,0x5
    800034e8:	0ec90913          	addi	s2,s2,236 # 800085d0 <syscalls+0x168>
    800034ec:	85ca                	mv	a1,s2
    800034ee:	8526                	mv	a0,s1
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	e3a080e7          	jalr	-454(ra) # 8000432a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034f8:	08848493          	addi	s1,s1,136
    800034fc:	ff3498e3          	bne	s1,s3,800034ec <iinit+0x3e>
}
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret

000000008000350e <ialloc>:
{
    8000350e:	715d                	addi	sp,sp,-80
    80003510:	e486                	sd	ra,72(sp)
    80003512:	e0a2                	sd	s0,64(sp)
    80003514:	fc26                	sd	s1,56(sp)
    80003516:	f84a                	sd	s2,48(sp)
    80003518:	f44e                	sd	s3,40(sp)
    8000351a:	f052                	sd	s4,32(sp)
    8000351c:	ec56                	sd	s5,24(sp)
    8000351e:	e85a                	sd	s6,16(sp)
    80003520:	e45e                	sd	s7,8(sp)
    80003522:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003524:	0001c717          	auipc	a4,0x1c
    80003528:	d6072703          	lw	a4,-672(a4) # 8001f284 <sb+0xc>
    8000352c:	4785                	li	a5,1
    8000352e:	04e7fa63          	bgeu	a5,a4,80003582 <ialloc+0x74>
    80003532:	8aaa                	mv	s5,a0
    80003534:	8bae                	mv	s7,a1
    80003536:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003538:	0001ca17          	auipc	s4,0x1c
    8000353c:	d40a0a13          	addi	s4,s4,-704 # 8001f278 <sb>
    80003540:	00048b1b          	sext.w	s6,s1
    80003544:	0044d593          	srli	a1,s1,0x4
    80003548:	018a2783          	lw	a5,24(s4)
    8000354c:	9dbd                	addw	a1,a1,a5
    8000354e:	8556                	mv	a0,s5
    80003550:	00000097          	auipc	ra,0x0
    80003554:	940080e7          	jalr	-1728(ra) # 80002e90 <bread>
    80003558:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000355a:	05850993          	addi	s3,a0,88
    8000355e:	00f4f793          	andi	a5,s1,15
    80003562:	079a                	slli	a5,a5,0x6
    80003564:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003566:	00099783          	lh	a5,0(s3)
    8000356a:	c3a1                	beqz	a5,800035aa <ialloc+0x9c>
    brelse(bp);
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	a54080e7          	jalr	-1452(ra) # 80002fc0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003574:	0485                	addi	s1,s1,1
    80003576:	00ca2703          	lw	a4,12(s4)
    8000357a:	0004879b          	sext.w	a5,s1
    8000357e:	fce7e1e3          	bltu	a5,a4,80003540 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	05650513          	addi	a0,a0,86 # 800085d8 <syscalls+0x170>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	004080e7          	jalr	4(ra) # 8000058e <printf>
  return 0;
    80003592:	4501                	li	a0,0
}
    80003594:	60a6                	ld	ra,72(sp)
    80003596:	6406                	ld	s0,64(sp)
    80003598:	74e2                	ld	s1,56(sp)
    8000359a:	7942                	ld	s2,48(sp)
    8000359c:	79a2                	ld	s3,40(sp)
    8000359e:	7a02                	ld	s4,32(sp)
    800035a0:	6ae2                	ld	s5,24(sp)
    800035a2:	6b42                	ld	s6,16(sp)
    800035a4:	6ba2                	ld	s7,8(sp)
    800035a6:	6161                	addi	sp,sp,80
    800035a8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035aa:	04000613          	li	a2,64
    800035ae:	4581                	li	a1,0
    800035b0:	854e                	mv	a0,s3
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	734080e7          	jalr	1844(ra) # 80000ce6 <memset>
      dip->type = type;
    800035ba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035be:	854a                	mv	a0,s2
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	c84080e7          	jalr	-892(ra) # 80004244 <log_write>
      brelse(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	9f6080e7          	jalr	-1546(ra) # 80002fc0 <brelse>
      return iget(dev, inum);
    800035d2:	85da                	mv	a1,s6
    800035d4:	8556                	mv	a0,s5
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	d9c080e7          	jalr	-612(ra) # 80003372 <iget>
    800035de:	bf5d                	j	80003594 <ialloc+0x86>

00000000800035e0 <iupdate>:
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ee:	415c                	lw	a5,4(a0)
    800035f0:	0047d79b          	srliw	a5,a5,0x4
    800035f4:	0001c597          	auipc	a1,0x1c
    800035f8:	c9c5a583          	lw	a1,-868(a1) # 8001f290 <sb+0x18>
    800035fc:	9dbd                	addw	a1,a1,a5
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	890080e7          	jalr	-1904(ra) # 80002e90 <bread>
    80003608:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000360a:	05850793          	addi	a5,a0,88
    8000360e:	40c8                	lw	a0,4(s1)
    80003610:	893d                	andi	a0,a0,15
    80003612:	051a                	slli	a0,a0,0x6
    80003614:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003616:	04449703          	lh	a4,68(s1)
    8000361a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000361e:	04649703          	lh	a4,70(s1)
    80003622:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003626:	04849703          	lh	a4,72(s1)
    8000362a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000362e:	04a49703          	lh	a4,74(s1)
    80003632:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003636:	44f8                	lw	a4,76(s1)
    80003638:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000363a:	03400613          	li	a2,52
    8000363e:	05048593          	addi	a1,s1,80
    80003642:	0531                	addi	a0,a0,12
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	702080e7          	jalr	1794(ra) # 80000d46 <memmove>
  log_write(bp);
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	bf6080e7          	jalr	-1034(ra) # 80004244 <log_write>
  brelse(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	968080e7          	jalr	-1688(ra) # 80002fc0 <brelse>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6902                	ld	s2,0(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret

000000008000366c <idup>:
{
    8000366c:	1101                	addi	sp,sp,-32
    8000366e:	ec06                	sd	ra,24(sp)
    80003670:	e822                	sd	s0,16(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	1000                	addi	s0,sp,32
    80003676:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003678:	0001c517          	auipc	a0,0x1c
    8000367c:	c2050513          	addi	a0,a0,-992 # 8001f298 <itable>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	56a080e7          	jalr	1386(ra) # 80000bea <acquire>
  ip->ref++;
    80003688:	449c                	lw	a5,8(s1)
    8000368a:	2785                	addiw	a5,a5,1
    8000368c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000368e:	0001c517          	auipc	a0,0x1c
    80003692:	c0a50513          	addi	a0,a0,-1014 # 8001f298 <itable>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	608080e7          	jalr	1544(ra) # 80000c9e <release>
}
    8000369e:	8526                	mv	a0,s1
    800036a0:	60e2                	ld	ra,24(sp)
    800036a2:	6442                	ld	s0,16(sp)
    800036a4:	64a2                	ld	s1,8(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret

00000000800036aa <ilock>:
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	e04a                	sd	s2,0(sp)
    800036b4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036b6:	c115                	beqz	a0,800036da <ilock+0x30>
    800036b8:	84aa                	mv	s1,a0
    800036ba:	451c                	lw	a5,8(a0)
    800036bc:	00f05f63          	blez	a5,800036da <ilock+0x30>
  acquiresleep(&ip->lock);
    800036c0:	0541                	addi	a0,a0,16
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	ca2080e7          	jalr	-862(ra) # 80004364 <acquiresleep>
  if(ip->valid == 0){
    800036ca:	40bc                	lw	a5,64(s1)
    800036cc:	cf99                	beqz	a5,800036ea <ilock+0x40>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6902                	ld	s2,0(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("ilock");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	f1650513          	addi	a0,a0,-234 # 800085f0 <syscalls+0x188>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e62080e7          	jalr	-414(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ea:	40dc                	lw	a5,4(s1)
    800036ec:	0047d79b          	srliw	a5,a5,0x4
    800036f0:	0001c597          	auipc	a1,0x1c
    800036f4:	ba05a583          	lw	a1,-1120(a1) # 8001f290 <sb+0x18>
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	4088                	lw	a0,0(s1)
    800036fc:	fffff097          	auipc	ra,0xfffff
    80003700:	794080e7          	jalr	1940(ra) # 80002e90 <bread>
    80003704:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003706:	05850593          	addi	a1,a0,88
    8000370a:	40dc                	lw	a5,4(s1)
    8000370c:	8bbd                	andi	a5,a5,15
    8000370e:	079a                	slli	a5,a5,0x6
    80003710:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003712:	00059783          	lh	a5,0(a1)
    80003716:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000371a:	00259783          	lh	a5,2(a1)
    8000371e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003722:	00459783          	lh	a5,4(a1)
    80003726:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000372a:	00659783          	lh	a5,6(a1)
    8000372e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003732:	459c                	lw	a5,8(a1)
    80003734:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003736:	03400613          	li	a2,52
    8000373a:	05b1                	addi	a1,a1,12
    8000373c:	05048513          	addi	a0,s1,80
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	606080e7          	jalr	1542(ra) # 80000d46 <memmove>
    brelse(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	876080e7          	jalr	-1930(ra) # 80002fc0 <brelse>
    ip->valid = 1;
    80003752:	4785                	li	a5,1
    80003754:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003756:	04449783          	lh	a5,68(s1)
    8000375a:	fbb5                	bnez	a5,800036ce <ilock+0x24>
      panic("ilock: no type");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	e9c50513          	addi	a0,a0,-356 # 800085f8 <syscalls+0x190>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	de0080e7          	jalr	-544(ra) # 80000544 <panic>

000000008000376c <iunlock>:
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	e04a                	sd	s2,0(sp)
    80003776:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003778:	c905                	beqz	a0,800037a8 <iunlock+0x3c>
    8000377a:	84aa                	mv	s1,a0
    8000377c:	01050913          	addi	s2,a0,16
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	c7c080e7          	jalr	-900(ra) # 800043fe <holdingsleep>
    8000378a:	cd19                	beqz	a0,800037a8 <iunlock+0x3c>
    8000378c:	449c                	lw	a5,8(s1)
    8000378e:	00f05d63          	blez	a5,800037a8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	c26080e7          	jalr	-986(ra) # 800043ba <releasesleep>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6902                	ld	s2,0(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret
    panic("iunlock");
    800037a8:	00005517          	auipc	a0,0x5
    800037ac:	e6050513          	addi	a0,a0,-416 # 80008608 <syscalls+0x1a0>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	d94080e7          	jalr	-620(ra) # 80000544 <panic>

00000000800037b8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037b8:	7179                	addi	sp,sp,-48
    800037ba:	f406                	sd	ra,40(sp)
    800037bc:	f022                	sd	s0,32(sp)
    800037be:	ec26                	sd	s1,24(sp)
    800037c0:	e84a                	sd	s2,16(sp)
    800037c2:	e44e                	sd	s3,8(sp)
    800037c4:	e052                	sd	s4,0(sp)
    800037c6:	1800                	addi	s0,sp,48
    800037c8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037ca:	05050493          	addi	s1,a0,80
    800037ce:	08050913          	addi	s2,a0,128
    800037d2:	a021                	j	800037da <itrunc+0x22>
    800037d4:	0491                	addi	s1,s1,4
    800037d6:	01248d63          	beq	s1,s2,800037f0 <itrunc+0x38>
    if(ip->addrs[i]){
    800037da:	408c                	lw	a1,0(s1)
    800037dc:	dde5                	beqz	a1,800037d4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037de:	0009a503          	lw	a0,0(s3)
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	8f4080e7          	jalr	-1804(ra) # 800030d6 <bfree>
      ip->addrs[i] = 0;
    800037ea:	0004a023          	sw	zero,0(s1)
    800037ee:	b7dd                	j	800037d4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037f0:	0809a583          	lw	a1,128(s3)
    800037f4:	e185                	bnez	a1,80003814 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037f6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037fa:	854e                	mv	a0,s3
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	de4080e7          	jalr	-540(ra) # 800035e0 <iupdate>
}
    80003804:	70a2                	ld	ra,40(sp)
    80003806:	7402                	ld	s0,32(sp)
    80003808:	64e2                	ld	s1,24(sp)
    8000380a:	6942                	ld	s2,16(sp)
    8000380c:	69a2                	ld	s3,8(sp)
    8000380e:	6a02                	ld	s4,0(sp)
    80003810:	6145                	addi	sp,sp,48
    80003812:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003814:	0009a503          	lw	a0,0(s3)
    80003818:	fffff097          	auipc	ra,0xfffff
    8000381c:	678080e7          	jalr	1656(ra) # 80002e90 <bread>
    80003820:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003822:	05850493          	addi	s1,a0,88
    80003826:	45850913          	addi	s2,a0,1112
    8000382a:	a811                	j	8000383e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000382c:	0009a503          	lw	a0,0(s3)
    80003830:	00000097          	auipc	ra,0x0
    80003834:	8a6080e7          	jalr	-1882(ra) # 800030d6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003838:	0491                	addi	s1,s1,4
    8000383a:	01248563          	beq	s1,s2,80003844 <itrunc+0x8c>
      if(a[j])
    8000383e:	408c                	lw	a1,0(s1)
    80003840:	dde5                	beqz	a1,80003838 <itrunc+0x80>
    80003842:	b7ed                	j	8000382c <itrunc+0x74>
    brelse(bp);
    80003844:	8552                	mv	a0,s4
    80003846:	fffff097          	auipc	ra,0xfffff
    8000384a:	77a080e7          	jalr	1914(ra) # 80002fc0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000384e:	0809a583          	lw	a1,128(s3)
    80003852:	0009a503          	lw	a0,0(s3)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	880080e7          	jalr	-1920(ra) # 800030d6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000385e:	0809a023          	sw	zero,128(s3)
    80003862:	bf51                	j	800037f6 <itrunc+0x3e>

0000000080003864 <iput>:
{
    80003864:	1101                	addi	sp,sp,-32
    80003866:	ec06                	sd	ra,24(sp)
    80003868:	e822                	sd	s0,16(sp)
    8000386a:	e426                	sd	s1,8(sp)
    8000386c:	e04a                	sd	s2,0(sp)
    8000386e:	1000                	addi	s0,sp,32
    80003870:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003872:	0001c517          	auipc	a0,0x1c
    80003876:	a2650513          	addi	a0,a0,-1498 # 8001f298 <itable>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	370080e7          	jalr	880(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003882:	4498                	lw	a4,8(s1)
    80003884:	4785                	li	a5,1
    80003886:	02f70363          	beq	a4,a5,800038ac <iput+0x48>
  ip->ref--;
    8000388a:	449c                	lw	a5,8(s1)
    8000388c:	37fd                	addiw	a5,a5,-1
    8000388e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003890:	0001c517          	auipc	a0,0x1c
    80003894:	a0850513          	addi	a0,a0,-1528 # 8001f298 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	406080e7          	jalr	1030(ra) # 80000c9e <release>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ac:	40bc                	lw	a5,64(s1)
    800038ae:	dff1                	beqz	a5,8000388a <iput+0x26>
    800038b0:	04a49783          	lh	a5,74(s1)
    800038b4:	fbf9                	bnez	a5,8000388a <iput+0x26>
    acquiresleep(&ip->lock);
    800038b6:	01048913          	addi	s2,s1,16
    800038ba:	854a                	mv	a0,s2
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	aa8080e7          	jalr	-1368(ra) # 80004364 <acquiresleep>
    release(&itable.lock);
    800038c4:	0001c517          	auipc	a0,0x1c
    800038c8:	9d450513          	addi	a0,a0,-1580 # 8001f298 <itable>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	3d2080e7          	jalr	978(ra) # 80000c9e <release>
    itrunc(ip);
    800038d4:	8526                	mv	a0,s1
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	ee2080e7          	jalr	-286(ra) # 800037b8 <itrunc>
    ip->type = 0;
    800038de:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038e2:	8526                	mv	a0,s1
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	cfc080e7          	jalr	-772(ra) # 800035e0 <iupdate>
    ip->valid = 0;
    800038ec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	ac8080e7          	jalr	-1336(ra) # 800043ba <releasesleep>
    acquire(&itable.lock);
    800038fa:	0001c517          	auipc	a0,0x1c
    800038fe:	99e50513          	addi	a0,a0,-1634 # 8001f298 <itable>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	2e8080e7          	jalr	744(ra) # 80000bea <acquire>
    8000390a:	b741                	j	8000388a <iput+0x26>

000000008000390c <iunlockput>:
{
    8000390c:	1101                	addi	sp,sp,-32
    8000390e:	ec06                	sd	ra,24(sp)
    80003910:	e822                	sd	s0,16(sp)
    80003912:	e426                	sd	s1,8(sp)
    80003914:	1000                	addi	s0,sp,32
    80003916:	84aa                	mv	s1,a0
  iunlock(ip);
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	e54080e7          	jalr	-428(ra) # 8000376c <iunlock>
  iput(ip);
    80003920:	8526                	mv	a0,s1
    80003922:	00000097          	auipc	ra,0x0
    80003926:	f42080e7          	jalr	-190(ra) # 80003864 <iput>
}
    8000392a:	60e2                	ld	ra,24(sp)
    8000392c:	6442                	ld	s0,16(sp)
    8000392e:	64a2                	ld	s1,8(sp)
    80003930:	6105                	addi	sp,sp,32
    80003932:	8082                	ret

0000000080003934 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003934:	1141                	addi	sp,sp,-16
    80003936:	e422                	sd	s0,8(sp)
    80003938:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000393a:	411c                	lw	a5,0(a0)
    8000393c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000393e:	415c                	lw	a5,4(a0)
    80003940:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003942:	04451783          	lh	a5,68(a0)
    80003946:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000394a:	04a51783          	lh	a5,74(a0)
    8000394e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003952:	04c56783          	lwu	a5,76(a0)
    80003956:	e99c                	sd	a5,16(a1)
}
    80003958:	6422                	ld	s0,8(sp)
    8000395a:	0141                	addi	sp,sp,16
    8000395c:	8082                	ret

000000008000395e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000395e:	457c                	lw	a5,76(a0)
    80003960:	0ed7e963          	bltu	a5,a3,80003a52 <readi+0xf4>
{
    80003964:	7159                	addi	sp,sp,-112
    80003966:	f486                	sd	ra,104(sp)
    80003968:	f0a2                	sd	s0,96(sp)
    8000396a:	eca6                	sd	s1,88(sp)
    8000396c:	e8ca                	sd	s2,80(sp)
    8000396e:	e4ce                	sd	s3,72(sp)
    80003970:	e0d2                	sd	s4,64(sp)
    80003972:	fc56                	sd	s5,56(sp)
    80003974:	f85a                	sd	s6,48(sp)
    80003976:	f45e                	sd	s7,40(sp)
    80003978:	f062                	sd	s8,32(sp)
    8000397a:	ec66                	sd	s9,24(sp)
    8000397c:	e86a                	sd	s10,16(sp)
    8000397e:	e46e                	sd	s11,8(sp)
    80003980:	1880                	addi	s0,sp,112
    80003982:	8b2a                	mv	s6,a0
    80003984:	8bae                	mv	s7,a1
    80003986:	8a32                	mv	s4,a2
    80003988:	84b6                	mv	s1,a3
    8000398a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000398c:	9f35                	addw	a4,a4,a3
    return 0;
    8000398e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003990:	0ad76063          	bltu	a4,a3,80003a30 <readi+0xd2>
  if(off + n > ip->size)
    80003994:	00e7f463          	bgeu	a5,a4,8000399c <readi+0x3e>
    n = ip->size - off;
    80003998:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399c:	0a0a8963          	beqz	s5,80003a4e <readi+0xf0>
    800039a0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039a6:	5c7d                	li	s8,-1
    800039a8:	a82d                	j	800039e2 <readi+0x84>
    800039aa:	020d1d93          	slli	s11,s10,0x20
    800039ae:	020ddd93          	srli	s11,s11,0x20
    800039b2:	05890613          	addi	a2,s2,88
    800039b6:	86ee                	mv	a3,s11
    800039b8:	963a                	add	a2,a2,a4
    800039ba:	85d2                	mv	a1,s4
    800039bc:	855e                	mv	a0,s7
    800039be:	fffff097          	auipc	ra,0xfffff
    800039c2:	ac0080e7          	jalr	-1344(ra) # 8000247e <either_copyout>
    800039c6:	05850d63          	beq	a0,s8,80003a20 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039ca:	854a                	mv	a0,s2
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	5f4080e7          	jalr	1524(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d4:	013d09bb          	addw	s3,s10,s3
    800039d8:	009d04bb          	addw	s1,s10,s1
    800039dc:	9a6e                	add	s4,s4,s11
    800039de:	0559f763          	bgeu	s3,s5,80003a2c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039e2:	00a4d59b          	srliw	a1,s1,0xa
    800039e6:	855a                	mv	a0,s6
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	8a2080e7          	jalr	-1886(ra) # 8000328a <bmap>
    800039f0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039f4:	cd85                	beqz	a1,80003a2c <readi+0xce>
    bp = bread(ip->dev, addr);
    800039f6:	000b2503          	lw	a0,0(s6)
    800039fa:	fffff097          	auipc	ra,0xfffff
    800039fe:	496080e7          	jalr	1174(ra) # 80002e90 <bread>
    80003a02:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a04:	3ff4f713          	andi	a4,s1,1023
    80003a08:	40ec87bb          	subw	a5,s9,a4
    80003a0c:	413a86bb          	subw	a3,s5,s3
    80003a10:	8d3e                	mv	s10,a5
    80003a12:	2781                	sext.w	a5,a5
    80003a14:	0006861b          	sext.w	a2,a3
    80003a18:	f8f679e3          	bgeu	a2,a5,800039aa <readi+0x4c>
    80003a1c:	8d36                	mv	s10,a3
    80003a1e:	b771                	j	800039aa <readi+0x4c>
      brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	59e080e7          	jalr	1438(ra) # 80002fc0 <brelse>
      tot = -1;
    80003a2a:	59fd                	li	s3,-1
  }
  return tot;
    80003a2c:	0009851b          	sext.w	a0,s3
}
    80003a30:	70a6                	ld	ra,104(sp)
    80003a32:	7406                	ld	s0,96(sp)
    80003a34:	64e6                	ld	s1,88(sp)
    80003a36:	6946                	ld	s2,80(sp)
    80003a38:	69a6                	ld	s3,72(sp)
    80003a3a:	6a06                	ld	s4,64(sp)
    80003a3c:	7ae2                	ld	s5,56(sp)
    80003a3e:	7b42                	ld	s6,48(sp)
    80003a40:	7ba2                	ld	s7,40(sp)
    80003a42:	7c02                	ld	s8,32(sp)
    80003a44:	6ce2                	ld	s9,24(sp)
    80003a46:	6d42                	ld	s10,16(sp)
    80003a48:	6da2                	ld	s11,8(sp)
    80003a4a:	6165                	addi	sp,sp,112
    80003a4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	89d6                	mv	s3,s5
    80003a50:	bff1                	j	80003a2c <readi+0xce>
    return 0;
    80003a52:	4501                	li	a0,0
}
    80003a54:	8082                	ret

0000000080003a56 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a56:	457c                	lw	a5,76(a0)
    80003a58:	10d7e863          	bltu	a5,a3,80003b68 <writei+0x112>
{
    80003a5c:	7159                	addi	sp,sp,-112
    80003a5e:	f486                	sd	ra,104(sp)
    80003a60:	f0a2                	sd	s0,96(sp)
    80003a62:	eca6                	sd	s1,88(sp)
    80003a64:	e8ca                	sd	s2,80(sp)
    80003a66:	e4ce                	sd	s3,72(sp)
    80003a68:	e0d2                	sd	s4,64(sp)
    80003a6a:	fc56                	sd	s5,56(sp)
    80003a6c:	f85a                	sd	s6,48(sp)
    80003a6e:	f45e                	sd	s7,40(sp)
    80003a70:	f062                	sd	s8,32(sp)
    80003a72:	ec66                	sd	s9,24(sp)
    80003a74:	e86a                	sd	s10,16(sp)
    80003a76:	e46e                	sd	s11,8(sp)
    80003a78:	1880                	addi	s0,sp,112
    80003a7a:	8aaa                	mv	s5,a0
    80003a7c:	8bae                	mv	s7,a1
    80003a7e:	8a32                	mv	s4,a2
    80003a80:	8936                	mv	s2,a3
    80003a82:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a84:	00e687bb          	addw	a5,a3,a4
    80003a88:	0ed7e263          	bltu	a5,a3,80003b6c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a8c:	00043737          	lui	a4,0x43
    80003a90:	0ef76063          	bltu	a4,a5,80003b70 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a94:	0c0b0863          	beqz	s6,80003b64 <writei+0x10e>
    80003a98:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a9e:	5c7d                	li	s8,-1
    80003aa0:	a091                	j	80003ae4 <writei+0x8e>
    80003aa2:	020d1d93          	slli	s11,s10,0x20
    80003aa6:	020ddd93          	srli	s11,s11,0x20
    80003aaa:	05848513          	addi	a0,s1,88
    80003aae:	86ee                	mv	a3,s11
    80003ab0:	8652                	mv	a2,s4
    80003ab2:	85de                	mv	a1,s7
    80003ab4:	953a                	add	a0,a0,a4
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	a1e080e7          	jalr	-1506(ra) # 800024d4 <either_copyin>
    80003abe:	07850263          	beq	a0,s8,80003b22 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ac2:	8526                	mv	a0,s1
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	780080e7          	jalr	1920(ra) # 80004244 <log_write>
    brelse(bp);
    80003acc:	8526                	mv	a0,s1
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	4f2080e7          	jalr	1266(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad6:	013d09bb          	addw	s3,s10,s3
    80003ada:	012d093b          	addw	s2,s10,s2
    80003ade:	9a6e                	add	s4,s4,s11
    80003ae0:	0569f663          	bgeu	s3,s6,80003b2c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ae4:	00a9559b          	srliw	a1,s2,0xa
    80003ae8:	8556                	mv	a0,s5
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	7a0080e7          	jalr	1952(ra) # 8000328a <bmap>
    80003af2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af6:	c99d                	beqz	a1,80003b2c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003af8:	000aa503          	lw	a0,0(s5)
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	394080e7          	jalr	916(ra) # 80002e90 <bread>
    80003b04:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b06:	3ff97713          	andi	a4,s2,1023
    80003b0a:	40ec87bb          	subw	a5,s9,a4
    80003b0e:	413b06bb          	subw	a3,s6,s3
    80003b12:	8d3e                	mv	s10,a5
    80003b14:	2781                	sext.w	a5,a5
    80003b16:	0006861b          	sext.w	a2,a3
    80003b1a:	f8f674e3          	bgeu	a2,a5,80003aa2 <writei+0x4c>
    80003b1e:	8d36                	mv	s10,a3
    80003b20:	b749                	j	80003aa2 <writei+0x4c>
      brelse(bp);
    80003b22:	8526                	mv	a0,s1
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	49c080e7          	jalr	1180(ra) # 80002fc0 <brelse>
  }

  if(off > ip->size)
    80003b2c:	04caa783          	lw	a5,76(s5)
    80003b30:	0127f463          	bgeu	a5,s2,80003b38 <writei+0xe2>
    ip->size = off;
    80003b34:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b38:	8556                	mv	a0,s5
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	aa6080e7          	jalr	-1370(ra) # 800035e0 <iupdate>

  return tot;
    80003b42:	0009851b          	sext.w	a0,s3
}
    80003b46:	70a6                	ld	ra,104(sp)
    80003b48:	7406                	ld	s0,96(sp)
    80003b4a:	64e6                	ld	s1,88(sp)
    80003b4c:	6946                	ld	s2,80(sp)
    80003b4e:	69a6                	ld	s3,72(sp)
    80003b50:	6a06                	ld	s4,64(sp)
    80003b52:	7ae2                	ld	s5,56(sp)
    80003b54:	7b42                	ld	s6,48(sp)
    80003b56:	7ba2                	ld	s7,40(sp)
    80003b58:	7c02                	ld	s8,32(sp)
    80003b5a:	6ce2                	ld	s9,24(sp)
    80003b5c:	6d42                	ld	s10,16(sp)
    80003b5e:	6da2                	ld	s11,8(sp)
    80003b60:	6165                	addi	sp,sp,112
    80003b62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	89da                	mv	s3,s6
    80003b66:	bfc9                	j	80003b38 <writei+0xe2>
    return -1;
    80003b68:	557d                	li	a0,-1
}
    80003b6a:	8082                	ret
    return -1;
    80003b6c:	557d                	li	a0,-1
    80003b6e:	bfe1                	j	80003b46 <writei+0xf0>
    return -1;
    80003b70:	557d                	li	a0,-1
    80003b72:	bfd1                	j	80003b46 <writei+0xf0>

0000000080003b74 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b74:	1141                	addi	sp,sp,-16
    80003b76:	e406                	sd	ra,8(sp)
    80003b78:	e022                	sd	s0,0(sp)
    80003b7a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b7c:	4639                	li	a2,14
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	240080e7          	jalr	576(ra) # 80000dbe <strncmp>
}
    80003b86:	60a2                	ld	ra,8(sp)
    80003b88:	6402                	ld	s0,0(sp)
    80003b8a:	0141                	addi	sp,sp,16
    80003b8c:	8082                	ret

0000000080003b8e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b8e:	7139                	addi	sp,sp,-64
    80003b90:	fc06                	sd	ra,56(sp)
    80003b92:	f822                	sd	s0,48(sp)
    80003b94:	f426                	sd	s1,40(sp)
    80003b96:	f04a                	sd	s2,32(sp)
    80003b98:	ec4e                	sd	s3,24(sp)
    80003b9a:	e852                	sd	s4,16(sp)
    80003b9c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b9e:	04451703          	lh	a4,68(a0)
    80003ba2:	4785                	li	a5,1
    80003ba4:	00f71a63          	bne	a4,a5,80003bb8 <dirlookup+0x2a>
    80003ba8:	892a                	mv	s2,a0
    80003baa:	89ae                	mv	s3,a1
    80003bac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bae:	457c                	lw	a5,76(a0)
    80003bb0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bb2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb4:	e79d                	bnez	a5,80003be2 <dirlookup+0x54>
    80003bb6:	a8a5                	j	80003c2e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	a5850513          	addi	a0,a0,-1448 # 80008610 <syscalls+0x1a8>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	984080e7          	jalr	-1660(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	a6050513          	addi	a0,a0,-1440 # 80008628 <syscalls+0x1c0>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	974080e7          	jalr	-1676(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd8:	24c1                	addiw	s1,s1,16
    80003bda:	04c92783          	lw	a5,76(s2)
    80003bde:	04f4f763          	bgeu	s1,a5,80003c2c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003be2:	4741                	li	a4,16
    80003be4:	86a6                	mv	a3,s1
    80003be6:	fc040613          	addi	a2,s0,-64
    80003bea:	4581                	li	a1,0
    80003bec:	854a                	mv	a0,s2
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	d70080e7          	jalr	-656(ra) # 8000395e <readi>
    80003bf6:	47c1                	li	a5,16
    80003bf8:	fcf518e3          	bne	a0,a5,80003bc8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bfc:	fc045783          	lhu	a5,-64(s0)
    80003c00:	dfe1                	beqz	a5,80003bd8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c02:	fc240593          	addi	a1,s0,-62
    80003c06:	854e                	mv	a0,s3
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	f6c080e7          	jalr	-148(ra) # 80003b74 <namecmp>
    80003c10:	f561                	bnez	a0,80003bd8 <dirlookup+0x4a>
      if(poff)
    80003c12:	000a0463          	beqz	s4,80003c1a <dirlookup+0x8c>
        *poff = off;
    80003c16:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c1a:	fc045583          	lhu	a1,-64(s0)
    80003c1e:	00092503          	lw	a0,0(s2)
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	750080e7          	jalr	1872(ra) # 80003372 <iget>
    80003c2a:	a011                	j	80003c2e <dirlookup+0xa0>
  return 0;
    80003c2c:	4501                	li	a0,0
}
    80003c2e:	70e2                	ld	ra,56(sp)
    80003c30:	7442                	ld	s0,48(sp)
    80003c32:	74a2                	ld	s1,40(sp)
    80003c34:	7902                	ld	s2,32(sp)
    80003c36:	69e2                	ld	s3,24(sp)
    80003c38:	6a42                	ld	s4,16(sp)
    80003c3a:	6121                	addi	sp,sp,64
    80003c3c:	8082                	ret

0000000080003c3e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c3e:	711d                	addi	sp,sp,-96
    80003c40:	ec86                	sd	ra,88(sp)
    80003c42:	e8a2                	sd	s0,80(sp)
    80003c44:	e4a6                	sd	s1,72(sp)
    80003c46:	e0ca                	sd	s2,64(sp)
    80003c48:	fc4e                	sd	s3,56(sp)
    80003c4a:	f852                	sd	s4,48(sp)
    80003c4c:	f456                	sd	s5,40(sp)
    80003c4e:	f05a                	sd	s6,32(sp)
    80003c50:	ec5e                	sd	s7,24(sp)
    80003c52:	e862                	sd	s8,16(sp)
    80003c54:	e466                	sd	s9,8(sp)
    80003c56:	1080                	addi	s0,sp,96
    80003c58:	84aa                	mv	s1,a0
    80003c5a:	8b2e                	mv	s6,a1
    80003c5c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c5e:	00054703          	lbu	a4,0(a0)
    80003c62:	02f00793          	li	a5,47
    80003c66:	02f70363          	beq	a4,a5,80003c8c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c6a:	ffffe097          	auipc	ra,0xffffe
    80003c6e:	d5c080e7          	jalr	-676(ra) # 800019c6 <myproc>
    80003c72:	15053503          	ld	a0,336(a0)
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	9f6080e7          	jalr	-1546(ra) # 8000366c <idup>
    80003c7e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c80:	02f00913          	li	s2,47
  len = path - s;
    80003c84:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c86:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c88:	4c05                	li	s8,1
    80003c8a:	a865                	j	80003d42 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c8c:	4585                	li	a1,1
    80003c8e:	4505                	li	a0,1
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	6e2080e7          	jalr	1762(ra) # 80003372 <iget>
    80003c98:	89aa                	mv	s3,a0
    80003c9a:	b7dd                	j	80003c80 <namex+0x42>
      iunlockput(ip);
    80003c9c:	854e                	mv	a0,s3
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	c6e080e7          	jalr	-914(ra) # 8000390c <iunlockput>
      return 0;
    80003ca6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ca8:	854e                	mv	a0,s3
    80003caa:	60e6                	ld	ra,88(sp)
    80003cac:	6446                	ld	s0,80(sp)
    80003cae:	64a6                	ld	s1,72(sp)
    80003cb0:	6906                	ld	s2,64(sp)
    80003cb2:	79e2                	ld	s3,56(sp)
    80003cb4:	7a42                	ld	s4,48(sp)
    80003cb6:	7aa2                	ld	s5,40(sp)
    80003cb8:	7b02                	ld	s6,32(sp)
    80003cba:	6be2                	ld	s7,24(sp)
    80003cbc:	6c42                	ld	s8,16(sp)
    80003cbe:	6ca2                	ld	s9,8(sp)
    80003cc0:	6125                	addi	sp,sp,96
    80003cc2:	8082                	ret
      iunlock(ip);
    80003cc4:	854e                	mv	a0,s3
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	aa6080e7          	jalr	-1370(ra) # 8000376c <iunlock>
      return ip;
    80003cce:	bfe9                	j	80003ca8 <namex+0x6a>
      iunlockput(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	c3a080e7          	jalr	-966(ra) # 8000390c <iunlockput>
      return 0;
    80003cda:	89d2                	mv	s3,s4
    80003cdc:	b7f1                	j	80003ca8 <namex+0x6a>
  len = path - s;
    80003cde:	40b48633          	sub	a2,s1,a1
    80003ce2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ce6:	094cd463          	bge	s9,s4,80003d6e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cea:	4639                	li	a2,14
    80003cec:	8556                	mv	a0,s5
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	058080e7          	jalr	88(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	01279763          	bne	a5,s2,80003d08 <namex+0xca>
    path++;
    80003cfe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d00:	0004c783          	lbu	a5,0(s1)
    80003d04:	ff278de3          	beq	a5,s2,80003cfe <namex+0xc0>
    ilock(ip);
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	9a0080e7          	jalr	-1632(ra) # 800036aa <ilock>
    if(ip->type != T_DIR){
    80003d12:	04499783          	lh	a5,68(s3)
    80003d16:	f98793e3          	bne	a5,s8,80003c9c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d1a:	000b0563          	beqz	s6,80003d24 <namex+0xe6>
    80003d1e:	0004c783          	lbu	a5,0(s1)
    80003d22:	d3cd                	beqz	a5,80003cc4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d24:	865e                	mv	a2,s7
    80003d26:	85d6                	mv	a1,s5
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	e64080e7          	jalr	-412(ra) # 80003b8e <dirlookup>
    80003d32:	8a2a                	mv	s4,a0
    80003d34:	dd51                	beqz	a0,80003cd0 <namex+0x92>
    iunlockput(ip);
    80003d36:	854e                	mv	a0,s3
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	bd4080e7          	jalr	-1068(ra) # 8000390c <iunlockput>
    ip = next;
    80003d40:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d42:	0004c783          	lbu	a5,0(s1)
    80003d46:	05279763          	bne	a5,s2,80003d94 <namex+0x156>
    path++;
    80003d4a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d4c:	0004c783          	lbu	a5,0(s1)
    80003d50:	ff278de3          	beq	a5,s2,80003d4a <namex+0x10c>
  if(*path == 0)
    80003d54:	c79d                	beqz	a5,80003d82 <namex+0x144>
    path++;
    80003d56:	85a6                	mv	a1,s1
  len = path - s;
    80003d58:	8a5e                	mv	s4,s7
    80003d5a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d5c:	01278963          	beq	a5,s2,80003d6e <namex+0x130>
    80003d60:	dfbd                	beqz	a5,80003cde <namex+0xa0>
    path++;
    80003d62:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d64:	0004c783          	lbu	a5,0(s1)
    80003d68:	ff279ce3          	bne	a5,s2,80003d60 <namex+0x122>
    80003d6c:	bf8d                	j	80003cde <namex+0xa0>
    memmove(name, s, len);
    80003d6e:	2601                	sext.w	a2,a2
    80003d70:	8556                	mv	a0,s5
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	fd4080e7          	jalr	-44(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003d7a:	9a56                	add	s4,s4,s5
    80003d7c:	000a0023          	sb	zero,0(s4)
    80003d80:	bf9d                	j	80003cf6 <namex+0xb8>
  if(nameiparent){
    80003d82:	f20b03e3          	beqz	s6,80003ca8 <namex+0x6a>
    iput(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	adc080e7          	jalr	-1316(ra) # 80003864 <iput>
    return 0;
    80003d90:	4981                	li	s3,0
    80003d92:	bf19                	j	80003ca8 <namex+0x6a>
  if(*path == 0)
    80003d94:	d7fd                	beqz	a5,80003d82 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	85a6                	mv	a1,s1
    80003d9c:	b7d1                	j	80003d60 <namex+0x122>

0000000080003d9e <dirlink>:
{
    80003d9e:	7139                	addi	sp,sp,-64
    80003da0:	fc06                	sd	ra,56(sp)
    80003da2:	f822                	sd	s0,48(sp)
    80003da4:	f426                	sd	s1,40(sp)
    80003da6:	f04a                	sd	s2,32(sp)
    80003da8:	ec4e                	sd	s3,24(sp)
    80003daa:	e852                	sd	s4,16(sp)
    80003dac:	0080                	addi	s0,sp,64
    80003dae:	892a                	mv	s2,a0
    80003db0:	8a2e                	mv	s4,a1
    80003db2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003db4:	4601                	li	a2,0
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	dd8080e7          	jalr	-552(ra) # 80003b8e <dirlookup>
    80003dbe:	e93d                	bnez	a0,80003e34 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc0:	04c92483          	lw	s1,76(s2)
    80003dc4:	c49d                	beqz	s1,80003df2 <dirlink+0x54>
    80003dc6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc8:	4741                	li	a4,16
    80003dca:	86a6                	mv	a3,s1
    80003dcc:	fc040613          	addi	a2,s0,-64
    80003dd0:	4581                	li	a1,0
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	b8a080e7          	jalr	-1142(ra) # 8000395e <readi>
    80003ddc:	47c1                	li	a5,16
    80003dde:	06f51163          	bne	a0,a5,80003e40 <dirlink+0xa2>
    if(de.inum == 0)
    80003de2:	fc045783          	lhu	a5,-64(s0)
    80003de6:	c791                	beqz	a5,80003df2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de8:	24c1                	addiw	s1,s1,16
    80003dea:	04c92783          	lw	a5,76(s2)
    80003dee:	fcf4ede3          	bltu	s1,a5,80003dc8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003df2:	4639                	li	a2,14
    80003df4:	85d2                	mv	a1,s4
    80003df6:	fc240513          	addi	a0,s0,-62
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	000080e7          	jalr	ra # 80000dfa <strncpy>
  de.inum = inum;
    80003e02:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e06:	4741                	li	a4,16
    80003e08:	86a6                	mv	a3,s1
    80003e0a:	fc040613          	addi	a2,s0,-64
    80003e0e:	4581                	li	a1,0
    80003e10:	854a                	mv	a0,s2
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	c44080e7          	jalr	-956(ra) # 80003a56 <writei>
    80003e1a:	1541                	addi	a0,a0,-16
    80003e1c:	00a03533          	snez	a0,a0
    80003e20:	40a00533          	neg	a0,a0
}
    80003e24:	70e2                	ld	ra,56(sp)
    80003e26:	7442                	ld	s0,48(sp)
    80003e28:	74a2                	ld	s1,40(sp)
    80003e2a:	7902                	ld	s2,32(sp)
    80003e2c:	69e2                	ld	s3,24(sp)
    80003e2e:	6a42                	ld	s4,16(sp)
    80003e30:	6121                	addi	sp,sp,64
    80003e32:	8082                	ret
    iput(ip);
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	a30080e7          	jalr	-1488(ra) # 80003864 <iput>
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	b7dd                	j	80003e24 <dirlink+0x86>
      panic("dirlink read");
    80003e40:	00004517          	auipc	a0,0x4
    80003e44:	7f850513          	addi	a0,a0,2040 # 80008638 <syscalls+0x1d0>
    80003e48:	ffffc097          	auipc	ra,0xffffc
    80003e4c:	6fc080e7          	jalr	1788(ra) # 80000544 <panic>

0000000080003e50 <namei>:

struct inode*
namei(char *path)
{
    80003e50:	1101                	addi	sp,sp,-32
    80003e52:	ec06                	sd	ra,24(sp)
    80003e54:	e822                	sd	s0,16(sp)
    80003e56:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e58:	fe040613          	addi	a2,s0,-32
    80003e5c:	4581                	li	a1,0
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	de0080e7          	jalr	-544(ra) # 80003c3e <namex>
}
    80003e66:	60e2                	ld	ra,24(sp)
    80003e68:	6442                	ld	s0,16(sp)
    80003e6a:	6105                	addi	sp,sp,32
    80003e6c:	8082                	ret

0000000080003e6e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6e:	1141                	addi	sp,sp,-16
    80003e70:	e406                	sd	ra,8(sp)
    80003e72:	e022                	sd	s0,0(sp)
    80003e74:	0800                	addi	s0,sp,16
    80003e76:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e78:	4585                	li	a1,1
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	dc4080e7          	jalr	-572(ra) # 80003c3e <namex>
}
    80003e82:	60a2                	ld	ra,8(sp)
    80003e84:	6402                	ld	s0,0(sp)
    80003e86:	0141                	addi	sp,sp,16
    80003e88:	8082                	ret

0000000080003e8a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	e426                	sd	s1,8(sp)
    80003e92:	e04a                	sd	s2,0(sp)
    80003e94:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e96:	0001d917          	auipc	s2,0x1d
    80003e9a:	eaa90913          	addi	s2,s2,-342 # 80020d40 <log>
    80003e9e:	01892583          	lw	a1,24(s2)
    80003ea2:	02892503          	lw	a0,40(s2)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	fea080e7          	jalr	-22(ra) # 80002e90 <bread>
    80003eae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eb0:	02c92683          	lw	a3,44(s2)
    80003eb4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb6:	02d05763          	blez	a3,80003ee4 <write_head+0x5a>
    80003eba:	0001d797          	auipc	a5,0x1d
    80003ebe:	eb678793          	addi	a5,a5,-330 # 80020d70 <log+0x30>
    80003ec2:	05c50713          	addi	a4,a0,92
    80003ec6:	36fd                	addiw	a3,a3,-1
    80003ec8:	1682                	slli	a3,a3,0x20
    80003eca:	9281                	srli	a3,a3,0x20
    80003ecc:	068a                	slli	a3,a3,0x2
    80003ece:	0001d617          	auipc	a2,0x1d
    80003ed2:	ea660613          	addi	a2,a2,-346 # 80020d74 <log+0x34>
    80003ed6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed8:	4390                	lw	a2,0(a5)
    80003eda:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003edc:	0791                	addi	a5,a5,4
    80003ede:	0711                	addi	a4,a4,4
    80003ee0:	fed79ce3          	bne	a5,a3,80003ed8 <write_head+0x4e>
  }
  bwrite(buf);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	09c080e7          	jalr	156(ra) # 80002f82 <bwrite>
  brelse(buf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	0d0080e7          	jalr	208(ra) # 80002fc0 <brelse>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6902                	ld	s2,0(sp)
    80003f00:	6105                	addi	sp,sp,32
    80003f02:	8082                	ret

0000000080003f04 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f04:	0001d797          	auipc	a5,0x1d
    80003f08:	e687a783          	lw	a5,-408(a5) # 80020d6c <log+0x2c>
    80003f0c:	0af05d63          	blez	a5,80003fc6 <install_trans+0xc2>
{
    80003f10:	7139                	addi	sp,sp,-64
    80003f12:	fc06                	sd	ra,56(sp)
    80003f14:	f822                	sd	s0,48(sp)
    80003f16:	f426                	sd	s1,40(sp)
    80003f18:	f04a                	sd	s2,32(sp)
    80003f1a:	ec4e                	sd	s3,24(sp)
    80003f1c:	e852                	sd	s4,16(sp)
    80003f1e:	e456                	sd	s5,8(sp)
    80003f20:	e05a                	sd	s6,0(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	8b2a                	mv	s6,a0
    80003f26:	0001da97          	auipc	s5,0x1d
    80003f2a:	e4aa8a93          	addi	s5,s5,-438 # 80020d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f30:	0001d997          	auipc	s3,0x1d
    80003f34:	e1098993          	addi	s3,s3,-496 # 80020d40 <log>
    80003f38:	a035                	j	80003f64 <install_trans+0x60>
      bunpin(dbuf);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	15e080e7          	jalr	350(ra) # 8000309a <bunpin>
    brelse(lbuf);
    80003f44:	854a                	mv	a0,s2
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	07a080e7          	jalr	122(ra) # 80002fc0 <brelse>
    brelse(dbuf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	070080e7          	jalr	112(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f58:	2a05                	addiw	s4,s4,1
    80003f5a:	0a91                	addi	s5,s5,4
    80003f5c:	02c9a783          	lw	a5,44(s3)
    80003f60:	04fa5963          	bge	s4,a5,80003fb2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f64:	0189a583          	lw	a1,24(s3)
    80003f68:	014585bb          	addw	a1,a1,s4
    80003f6c:	2585                	addiw	a1,a1,1
    80003f6e:	0289a503          	lw	a0,40(s3)
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	f1e080e7          	jalr	-226(ra) # 80002e90 <bread>
    80003f7a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f7c:	000aa583          	lw	a1,0(s5)
    80003f80:	0289a503          	lw	a0,40(s3)
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	f0c080e7          	jalr	-244(ra) # 80002e90 <bread>
    80003f8c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f8e:	40000613          	li	a2,1024
    80003f92:	05890593          	addi	a1,s2,88
    80003f96:	05850513          	addi	a0,a0,88
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	dac080e7          	jalr	-596(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	fde080e7          	jalr	-34(ra) # 80002f82 <bwrite>
    if(recovering == 0)
    80003fac:	f80b1ce3          	bnez	s6,80003f44 <install_trans+0x40>
    80003fb0:	b769                	j	80003f3a <install_trans+0x36>
}
    80003fb2:	70e2                	ld	ra,56(sp)
    80003fb4:	7442                	ld	s0,48(sp)
    80003fb6:	74a2                	ld	s1,40(sp)
    80003fb8:	7902                	ld	s2,32(sp)
    80003fba:	69e2                	ld	s3,24(sp)
    80003fbc:	6a42                	ld	s4,16(sp)
    80003fbe:	6aa2                	ld	s5,8(sp)
    80003fc0:	6b02                	ld	s6,0(sp)
    80003fc2:	6121                	addi	sp,sp,64
    80003fc4:	8082                	ret
    80003fc6:	8082                	ret

0000000080003fc8 <initlog>:
{
    80003fc8:	7179                	addi	sp,sp,-48
    80003fca:	f406                	sd	ra,40(sp)
    80003fcc:	f022                	sd	s0,32(sp)
    80003fce:	ec26                	sd	s1,24(sp)
    80003fd0:	e84a                	sd	s2,16(sp)
    80003fd2:	e44e                	sd	s3,8(sp)
    80003fd4:	1800                	addi	s0,sp,48
    80003fd6:	892a                	mv	s2,a0
    80003fd8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fda:	0001d497          	auipc	s1,0x1d
    80003fde:	d6648493          	addi	s1,s1,-666 # 80020d40 <log>
    80003fe2:	00004597          	auipc	a1,0x4
    80003fe6:	66658593          	addi	a1,a1,1638 # 80008648 <syscalls+0x1e0>
    80003fea:	8526                	mv	a0,s1
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	b6e080e7          	jalr	-1170(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80003ff4:	0149a583          	lw	a1,20(s3)
    80003ff8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003ffa:	0109a783          	lw	a5,16(s3)
    80003ffe:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004000:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004004:	854a                	mv	a0,s2
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	e8a080e7          	jalr	-374(ra) # 80002e90 <bread>
  log.lh.n = lh->n;
    8000400e:	4d3c                	lw	a5,88(a0)
    80004010:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004012:	02f05563          	blez	a5,8000403c <initlog+0x74>
    80004016:	05c50713          	addi	a4,a0,92
    8000401a:	0001d697          	auipc	a3,0x1d
    8000401e:	d5668693          	addi	a3,a3,-682 # 80020d70 <log+0x30>
    80004022:	37fd                	addiw	a5,a5,-1
    80004024:	1782                	slli	a5,a5,0x20
    80004026:	9381                	srli	a5,a5,0x20
    80004028:	078a                	slli	a5,a5,0x2
    8000402a:	06050613          	addi	a2,a0,96
    8000402e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004030:	4310                	lw	a2,0(a4)
    80004032:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004034:	0711                	addi	a4,a4,4
    80004036:	0691                	addi	a3,a3,4
    80004038:	fef71ce3          	bne	a4,a5,80004030 <initlog+0x68>
  brelse(buf);
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	f84080e7          	jalr	-124(ra) # 80002fc0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004044:	4505                	li	a0,1
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	ebe080e7          	jalr	-322(ra) # 80003f04 <install_trans>
  log.lh.n = 0;
    8000404e:	0001d797          	auipc	a5,0x1d
    80004052:	d007af23          	sw	zero,-738(a5) # 80020d6c <log+0x2c>
  write_head(); // clear the log
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	e34080e7          	jalr	-460(ra) # 80003e8a <write_head>
}
    8000405e:	70a2                	ld	ra,40(sp)
    80004060:	7402                	ld	s0,32(sp)
    80004062:	64e2                	ld	s1,24(sp)
    80004064:	6942                	ld	s2,16(sp)
    80004066:	69a2                	ld	s3,8(sp)
    80004068:	6145                	addi	sp,sp,48
    8000406a:	8082                	ret

000000008000406c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	e426                	sd	s1,8(sp)
    80004074:	e04a                	sd	s2,0(sp)
    80004076:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004078:	0001d517          	auipc	a0,0x1d
    8000407c:	cc850513          	addi	a0,a0,-824 # 80020d40 <log>
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	b6a080e7          	jalr	-1174(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	cb848493          	addi	s1,s1,-840 # 80020d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004090:	4979                	li	s2,30
    80004092:	a039                	j	800040a0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004094:	85a6                	mv	a1,s1
    80004096:	8526                	mv	a0,s1
    80004098:	ffffe097          	auipc	ra,0xffffe
    8000409c:	fde080e7          	jalr	-34(ra) # 80002076 <sleep>
    if(log.committing){
    800040a0:	50dc                	lw	a5,36(s1)
    800040a2:	fbed                	bnez	a5,80004094 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a4:	509c                	lw	a5,32(s1)
    800040a6:	0017871b          	addiw	a4,a5,1
    800040aa:	0007069b          	sext.w	a3,a4
    800040ae:	0027179b          	slliw	a5,a4,0x2
    800040b2:	9fb9                	addw	a5,a5,a4
    800040b4:	0017979b          	slliw	a5,a5,0x1
    800040b8:	54d8                	lw	a4,44(s1)
    800040ba:	9fb9                	addw	a5,a5,a4
    800040bc:	00f95963          	bge	s2,a5,800040ce <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040c0:	85a6                	mv	a1,s1
    800040c2:	8526                	mv	a0,s1
    800040c4:	ffffe097          	auipc	ra,0xffffe
    800040c8:	fb2080e7          	jalr	-78(ra) # 80002076 <sleep>
    800040cc:	bfd1                	j	800040a0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ce:	0001d517          	auipc	a0,0x1d
    800040d2:	c7250513          	addi	a0,a0,-910 # 80020d40 <log>
    800040d6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	bc6080e7          	jalr	-1082(ra) # 80000c9e <release>
      break;
    }
  }
}
    800040e0:	60e2                	ld	ra,24(sp)
    800040e2:	6442                	ld	s0,16(sp)
    800040e4:	64a2                	ld	s1,8(sp)
    800040e6:	6902                	ld	s2,0(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret

00000000800040ec <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ec:	7139                	addi	sp,sp,-64
    800040ee:	fc06                	sd	ra,56(sp)
    800040f0:	f822                	sd	s0,48(sp)
    800040f2:	f426                	sd	s1,40(sp)
    800040f4:	f04a                	sd	s2,32(sp)
    800040f6:	ec4e                	sd	s3,24(sp)
    800040f8:	e852                	sd	s4,16(sp)
    800040fa:	e456                	sd	s5,8(sp)
    800040fc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040fe:	0001d497          	auipc	s1,0x1d
    80004102:	c4248493          	addi	s1,s1,-958 # 80020d40 <log>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004110:	509c                	lw	a5,32(s1)
    80004112:	37fd                	addiw	a5,a5,-1
    80004114:	0007891b          	sext.w	s2,a5
    80004118:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000411a:	50dc                	lw	a5,36(s1)
    8000411c:	efb9                	bnez	a5,8000417a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000411e:	06091663          	bnez	s2,8000418a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004122:	0001d497          	auipc	s1,0x1d
    80004126:	c1e48493          	addi	s1,s1,-994 # 80020d40 <log>
    8000412a:	4785                	li	a5,1
    8000412c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	b6e080e7          	jalr	-1170(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004138:	54dc                	lw	a5,44(s1)
    8000413a:	06f04763          	bgtz	a5,800041a8 <end_op+0xbc>
    acquire(&log.lock);
    8000413e:	0001d497          	auipc	s1,0x1d
    80004142:	c0248493          	addi	s1,s1,-1022 # 80020d40 <log>
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	aa2080e7          	jalr	-1374(ra) # 80000bea <acquire>
    log.committing = 0;
    80004150:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004154:	8526                	mv	a0,s1
    80004156:	ffffe097          	auipc	ra,0xffffe
    8000415a:	f84080e7          	jalr	-124(ra) # 800020da <wakeup>
    release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	b3e080e7          	jalr	-1218(ra) # 80000c9e <release>
}
    80004168:	70e2                	ld	ra,56(sp)
    8000416a:	7442                	ld	s0,48(sp)
    8000416c:	74a2                	ld	s1,40(sp)
    8000416e:	7902                	ld	s2,32(sp)
    80004170:	69e2                	ld	s3,24(sp)
    80004172:	6a42                	ld	s4,16(sp)
    80004174:	6aa2                	ld	s5,8(sp)
    80004176:	6121                	addi	sp,sp,64
    80004178:	8082                	ret
    panic("log.committing");
    8000417a:	00004517          	auipc	a0,0x4
    8000417e:	4d650513          	addi	a0,a0,1238 # 80008650 <syscalls+0x1e8>
    80004182:	ffffc097          	auipc	ra,0xffffc
    80004186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>
    wakeup(&log);
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	bb648493          	addi	s1,s1,-1098 # 80020d40 <log>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffe097          	auipc	ra,0xffffe
    80004198:	f46080e7          	jalr	-186(ra) # 800020da <wakeup>
  release(&log.lock);
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	b00080e7          	jalr	-1280(ra) # 80000c9e <release>
  if(do_commit){
    800041a6:	b7c9                	j	80004168 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a8:	0001da97          	auipc	s5,0x1d
    800041ac:	bc8a8a93          	addi	s5,s5,-1080 # 80020d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041b0:	0001da17          	auipc	s4,0x1d
    800041b4:	b90a0a13          	addi	s4,s4,-1136 # 80020d40 <log>
    800041b8:	018a2583          	lw	a1,24(s4)
    800041bc:	012585bb          	addw	a1,a1,s2
    800041c0:	2585                	addiw	a1,a1,1
    800041c2:	028a2503          	lw	a0,40(s4)
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	cca080e7          	jalr	-822(ra) # 80002e90 <bread>
    800041ce:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041d0:	000aa583          	lw	a1,0(s5)
    800041d4:	028a2503          	lw	a0,40(s4)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	cb8080e7          	jalr	-840(ra) # 80002e90 <bread>
    800041e0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e2:	40000613          	li	a2,1024
    800041e6:	05850593          	addi	a1,a0,88
    800041ea:	05848513          	addi	a0,s1,88
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	b58080e7          	jalr	-1192(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800041f6:	8526                	mv	a0,s1
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	d8a080e7          	jalr	-630(ra) # 80002f82 <bwrite>
    brelse(from);
    80004200:	854e                	mv	a0,s3
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	dbe080e7          	jalr	-578(ra) # 80002fc0 <brelse>
    brelse(to);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	db4080e7          	jalr	-588(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	2905                	addiw	s2,s2,1
    80004216:	0a91                	addi	s5,s5,4
    80004218:	02ca2783          	lw	a5,44(s4)
    8000421c:	f8f94ee3          	blt	s2,a5,800041b8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004220:	00000097          	auipc	ra,0x0
    80004224:	c6a080e7          	jalr	-918(ra) # 80003e8a <write_head>
    install_trans(0); // Now install writes to home locations
    80004228:	4501                	li	a0,0
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	cda080e7          	jalr	-806(ra) # 80003f04 <install_trans>
    log.lh.n = 0;
    80004232:	0001d797          	auipc	a5,0x1d
    80004236:	b207ad23          	sw	zero,-1222(a5) # 80020d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	c50080e7          	jalr	-944(ra) # 80003e8a <write_head>
    80004242:	bdf5                	j	8000413e <end_op+0x52>

0000000080004244 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004244:	1101                	addi	sp,sp,-32
    80004246:	ec06                	sd	ra,24(sp)
    80004248:	e822                	sd	s0,16(sp)
    8000424a:	e426                	sd	s1,8(sp)
    8000424c:	e04a                	sd	s2,0(sp)
    8000424e:	1000                	addi	s0,sp,32
    80004250:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004252:	0001d917          	auipc	s2,0x1d
    80004256:	aee90913          	addi	s2,s2,-1298 # 80020d40 <log>
    8000425a:	854a                	mv	a0,s2
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	98e080e7          	jalr	-1650(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004264:	02c92603          	lw	a2,44(s2)
    80004268:	47f5                	li	a5,29
    8000426a:	06c7c563          	blt	a5,a2,800042d4 <log_write+0x90>
    8000426e:	0001d797          	auipc	a5,0x1d
    80004272:	aee7a783          	lw	a5,-1298(a5) # 80020d5c <log+0x1c>
    80004276:	37fd                	addiw	a5,a5,-1
    80004278:	04f65e63          	bge	a2,a5,800042d4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000427c:	0001d797          	auipc	a5,0x1d
    80004280:	ae47a783          	lw	a5,-1308(a5) # 80020d60 <log+0x20>
    80004284:	06f05063          	blez	a5,800042e4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004288:	4781                	li	a5,0
    8000428a:	06c05563          	blez	a2,800042f4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000428e:	44cc                	lw	a1,12(s1)
    80004290:	0001d717          	auipc	a4,0x1d
    80004294:	ae070713          	addi	a4,a4,-1312 # 80020d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004298:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000429a:	4314                	lw	a3,0(a4)
    8000429c:	04b68c63          	beq	a3,a1,800042f4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042a0:	2785                	addiw	a5,a5,1
    800042a2:	0711                	addi	a4,a4,4
    800042a4:	fef61be3          	bne	a2,a5,8000429a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042a8:	0621                	addi	a2,a2,8
    800042aa:	060a                	slli	a2,a2,0x2
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	a9478793          	addi	a5,a5,-1388 # 80020d40 <log>
    800042b4:	963e                	add	a2,a2,a5
    800042b6:	44dc                	lw	a5,12(s1)
    800042b8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042ba:	8526                	mv	a0,s1
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	da2080e7          	jalr	-606(ra) # 8000305e <bpin>
    log.lh.n++;
    800042c4:	0001d717          	auipc	a4,0x1d
    800042c8:	a7c70713          	addi	a4,a4,-1412 # 80020d40 <log>
    800042cc:	575c                	lw	a5,44(a4)
    800042ce:	2785                	addiw	a5,a5,1
    800042d0:	d75c                	sw	a5,44(a4)
    800042d2:	a835                	j	8000430e <log_write+0xca>
    panic("too big a transaction");
    800042d4:	00004517          	auipc	a0,0x4
    800042d8:	38c50513          	addi	a0,a0,908 # 80008660 <syscalls+0x1f8>
    800042dc:	ffffc097          	auipc	ra,0xffffc
    800042e0:	268080e7          	jalr	616(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800042e4:	00004517          	auipc	a0,0x4
    800042e8:	39450513          	addi	a0,a0,916 # 80008678 <syscalls+0x210>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	258080e7          	jalr	600(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800042f4:	00878713          	addi	a4,a5,8
    800042f8:	00271693          	slli	a3,a4,0x2
    800042fc:	0001d717          	auipc	a4,0x1d
    80004300:	a4470713          	addi	a4,a4,-1468 # 80020d40 <log>
    80004304:	9736                	add	a4,a4,a3
    80004306:	44d4                	lw	a3,12(s1)
    80004308:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000430a:	faf608e3          	beq	a2,a5,800042ba <log_write+0x76>
  }
  release(&log.lock);
    8000430e:	0001d517          	auipc	a0,0x1d
    80004312:	a3250513          	addi	a0,a0,-1486 # 80020d40 <log>
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	988080e7          	jalr	-1656(ra) # 80000c9e <release>
}
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6902                	ld	s2,0(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
    80004336:	84aa                	mv	s1,a0
    80004338:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000433a:	00004597          	auipc	a1,0x4
    8000433e:	35e58593          	addi	a1,a1,862 # 80008698 <syscalls+0x230>
    80004342:	0521                	addi	a0,a0,8
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	816080e7          	jalr	-2026(ra) # 80000b5a <initlock>
  lk->name = name;
    8000434c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004350:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004354:	0204a423          	sw	zero,40(s1)
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004364:	1101                	addi	sp,sp,-32
    80004366:	ec06                	sd	ra,24(sp)
    80004368:	e822                	sd	s0,16(sp)
    8000436a:	e426                	sd	s1,8(sp)
    8000436c:	e04a                	sd	s2,0(sp)
    8000436e:	1000                	addi	s0,sp,32
    80004370:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004372:	00850913          	addi	s2,a0,8
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	872080e7          	jalr	-1934(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004380:	409c                	lw	a5,0(s1)
    80004382:	cb89                	beqz	a5,80004394 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004384:	85ca                	mv	a1,s2
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	cee080e7          	jalr	-786(ra) # 80002076 <sleep>
  while (lk->locked) {
    80004390:	409c                	lw	a5,0(s1)
    80004392:	fbed                	bnez	a5,80004384 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004394:	4785                	li	a5,1
    80004396:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	62e080e7          	jalr	1582(ra) # 800019c6 <myproc>
    800043a0:	591c                	lw	a5,48(a0)
    800043a2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a4:	854a                	mv	a0,s2
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	8f8080e7          	jalr	-1800(ra) # 80000c9e <release>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	81c080e7          	jalr	-2020(ra) # 80000bea <acquire>
  lk->locked = 0;
    800043d6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043da:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffe097          	auipc	ra,0xffffe
    800043e4:	cfa080e7          	jalr	-774(ra) # 800020da <wakeup>
  release(&lk->lk);
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043fe:	7179                	addi	sp,sp,-48
    80004400:	f406                	sd	ra,40(sp)
    80004402:	f022                	sd	s0,32(sp)
    80004404:	ec26                	sd	s1,24(sp)
    80004406:	e84a                	sd	s2,16(sp)
    80004408:	e44e                	sd	s3,8(sp)
    8000440a:	1800                	addi	s0,sp,48
    8000440c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000440e:	00850913          	addi	s2,a0,8
    80004412:	854a                	mv	a0,s2
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	7d6080e7          	jalr	2006(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	ef99                	bnez	a5,8000443c <holdingsleep+0x3e>
    80004420:	4481                	li	s1,0
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	87a080e7          	jalr	-1926(ra) # 80000c9e <release>
  return r;
}
    8000442c:	8526                	mv	a0,s1
    8000442e:	70a2                	ld	ra,40(sp)
    80004430:	7402                	ld	s0,32(sp)
    80004432:	64e2                	ld	s1,24(sp)
    80004434:	6942                	ld	s2,16(sp)
    80004436:	69a2                	ld	s3,8(sp)
    80004438:	6145                	addi	sp,sp,48
    8000443a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443c:	0284a983          	lw	s3,40(s1)
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	586080e7          	jalr	1414(ra) # 800019c6 <myproc>
    80004448:	5904                	lw	s1,48(a0)
    8000444a:	413484b3          	sub	s1,s1,s3
    8000444e:	0014b493          	seqz	s1,s1
    80004452:	bfc1                	j	80004422 <holdingsleep+0x24>

0000000080004454 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004454:	1141                	addi	sp,sp,-16
    80004456:	e406                	sd	ra,8(sp)
    80004458:	e022                	sd	s0,0(sp)
    8000445a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	24c58593          	addi	a1,a1,588 # 800086a8 <syscalls+0x240>
    80004464:	0001d517          	auipc	a0,0x1d
    80004468:	a2450513          	addi	a0,a0,-1500 # 80020e88 <ftable>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	6ee080e7          	jalr	1774(ra) # 80000b5a <initlock>
}
    80004474:	60a2                	ld	ra,8(sp)
    80004476:	6402                	ld	s0,0(sp)
    80004478:	0141                	addi	sp,sp,16
    8000447a:	8082                	ret

000000008000447c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	a0250513          	addi	a0,a0,-1534 # 80020e88 <ftable>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	75c080e7          	jalr	1884(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004496:	0001d497          	auipc	s1,0x1d
    8000449a:	a0a48493          	addi	s1,s1,-1526 # 80020ea0 <ftable+0x18>
    8000449e:	0001e717          	auipc	a4,0x1e
    800044a2:	9a270713          	addi	a4,a4,-1630 # 80021e40 <disk>
    if(f->ref == 0){
    800044a6:	40dc                	lw	a5,4(s1)
    800044a8:	cf99                	beqz	a5,800044c6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044aa:	02848493          	addi	s1,s1,40
    800044ae:	fee49ce3          	bne	s1,a4,800044a6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	9d650513          	addi	a0,a0,-1578 # 80020e88 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7e4080e7          	jalr	2020(ra) # 80000c9e <release>
  return 0;
    800044c2:	4481                	li	s1,0
    800044c4:	a819                	j	800044da <filealloc+0x5e>
      f->ref = 1;
    800044c6:	4785                	li	a5,1
    800044c8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ca:	0001d517          	auipc	a0,0x1d
    800044ce:	9be50513          	addi	a0,a0,-1602 # 80020e88 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7cc080e7          	jalr	1996(ra) # 80000c9e <release>
}
    800044da:	8526                	mv	a0,s1
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044f2:	0001d517          	auipc	a0,0x1d
    800044f6:	99650513          	addi	a0,a0,-1642 # 80020e88 <ftable>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6f0080e7          	jalr	1776(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004502:	40dc                	lw	a5,4(s1)
    80004504:	02f05263          	blez	a5,80004528 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004508:	2785                	addiw	a5,a5,1
    8000450a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	97c50513          	addi	a0,a0,-1668 # 80020e88 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	78a080e7          	jalr	1930(ra) # 80000c9e <release>
  return f;
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret
    panic("filedup");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	18850513          	addi	a0,a0,392 # 800086b0 <syscalls+0x248>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	014080e7          	jalr	20(ra) # 80000544 <panic>

0000000080004538 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004538:	7139                	addi	sp,sp,-64
    8000453a:	fc06                	sd	ra,56(sp)
    8000453c:	f822                	sd	s0,48(sp)
    8000453e:	f426                	sd	s1,40(sp)
    80004540:	f04a                	sd	s2,32(sp)
    80004542:	ec4e                	sd	s3,24(sp)
    80004544:	e852                	sd	s4,16(sp)
    80004546:	e456                	sd	s5,8(sp)
    80004548:	0080                	addi	s0,sp,64
    8000454a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000454c:	0001d517          	auipc	a0,0x1d
    80004550:	93c50513          	addi	a0,a0,-1732 # 80020e88 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	696080e7          	jalr	1686(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000455c:	40dc                	lw	a5,4(s1)
    8000455e:	06f05163          	blez	a5,800045c0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004562:	37fd                	addiw	a5,a5,-1
    80004564:	0007871b          	sext.w	a4,a5
    80004568:	c0dc                	sw	a5,4(s1)
    8000456a:	06e04363          	bgtz	a4,800045d0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000456e:	0004a903          	lw	s2,0(s1)
    80004572:	0094ca83          	lbu	s5,9(s1)
    80004576:	0104ba03          	ld	s4,16(s1)
    8000457a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000457e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004582:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	90250513          	addi	a0,a0,-1790 # 80020e88 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	710080e7          	jalr	1808(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004596:	4785                	li	a5,1
    80004598:	04f90d63          	beq	s2,a5,800045f2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000459c:	3979                	addiw	s2,s2,-2
    8000459e:	4785                	li	a5,1
    800045a0:	0527e063          	bltu	a5,s2,800045e0 <fileclose+0xa8>
    begin_op();
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	ac8080e7          	jalr	-1336(ra) # 8000406c <begin_op>
    iput(ff.ip);
    800045ac:	854e                	mv	a0,s3
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	2b6080e7          	jalr	694(ra) # 80003864 <iput>
    end_op();
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	b36080e7          	jalr	-1226(ra) # 800040ec <end_op>
    800045be:	a00d                	j	800045e0 <fileclose+0xa8>
    panic("fileclose");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	0f850513          	addi	a0,a0,248 # 800086b8 <syscalls+0x250>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f7c080e7          	jalr	-132(ra) # 80000544 <panic>
    release(&ftable.lock);
    800045d0:	0001d517          	auipc	a0,0x1d
    800045d4:	8b850513          	addi	a0,a0,-1864 # 80020e88 <ftable>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
  }
}
    800045e0:	70e2                	ld	ra,56(sp)
    800045e2:	7442                	ld	s0,48(sp)
    800045e4:	74a2                	ld	s1,40(sp)
    800045e6:	7902                	ld	s2,32(sp)
    800045e8:	69e2                	ld	s3,24(sp)
    800045ea:	6a42                	ld	s4,16(sp)
    800045ec:	6aa2                	ld	s5,8(sp)
    800045ee:	6121                	addi	sp,sp,64
    800045f0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045f2:	85d6                	mv	a1,s5
    800045f4:	8552                	mv	a0,s4
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	34c080e7          	jalr	844(ra) # 80004942 <pipeclose>
    800045fe:	b7cd                	j	800045e0 <fileclose+0xa8>

0000000080004600 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004600:	715d                	addi	sp,sp,-80
    80004602:	e486                	sd	ra,72(sp)
    80004604:	e0a2                	sd	s0,64(sp)
    80004606:	fc26                	sd	s1,56(sp)
    80004608:	f84a                	sd	s2,48(sp)
    8000460a:	f44e                	sd	s3,40(sp)
    8000460c:	0880                	addi	s0,sp,80
    8000460e:	84aa                	mv	s1,a0
    80004610:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004612:	ffffd097          	auipc	ra,0xffffd
    80004616:	3b4080e7          	jalr	948(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000461a:	409c                	lw	a5,0(s1)
    8000461c:	37f9                	addiw	a5,a5,-2
    8000461e:	4705                	li	a4,1
    80004620:	04f76763          	bltu	a4,a5,8000466e <filestat+0x6e>
    80004624:	892a                	mv	s2,a0
    ilock(f->ip);
    80004626:	6c88                	ld	a0,24(s1)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	082080e7          	jalr	130(ra) # 800036aa <ilock>
    stati(f->ip, &st);
    80004630:	fb840593          	addi	a1,s0,-72
    80004634:	6c88                	ld	a0,24(s1)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	2fe080e7          	jalr	766(ra) # 80003934 <stati>
    iunlock(f->ip);
    8000463e:	6c88                	ld	a0,24(s1)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	12c080e7          	jalr	300(ra) # 8000376c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004648:	46e1                	li	a3,24
    8000464a:	fb840613          	addi	a2,s0,-72
    8000464e:	85ce                	mv	a1,s3
    80004650:	05093503          	ld	a0,80(s2)
    80004654:	ffffd097          	auipc	ra,0xffffd
    80004658:	030080e7          	jalr	48(ra) # 80001684 <copyout>
    8000465c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004660:	60a6                	ld	ra,72(sp)
    80004662:	6406                	ld	s0,64(sp)
    80004664:	74e2                	ld	s1,56(sp)
    80004666:	7942                	ld	s2,48(sp)
    80004668:	79a2                	ld	s3,40(sp)
    8000466a:	6161                	addi	sp,sp,80
    8000466c:	8082                	ret
  return -1;
    8000466e:	557d                	li	a0,-1
    80004670:	bfc5                	j	80004660 <filestat+0x60>

0000000080004672 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004672:	7179                	addi	sp,sp,-48
    80004674:	f406                	sd	ra,40(sp)
    80004676:	f022                	sd	s0,32(sp)
    80004678:	ec26                	sd	s1,24(sp)
    8000467a:	e84a                	sd	s2,16(sp)
    8000467c:	e44e                	sd	s3,8(sp)
    8000467e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004680:	00854783          	lbu	a5,8(a0)
    80004684:	c3d5                	beqz	a5,80004728 <fileread+0xb6>
    80004686:	84aa                	mv	s1,a0
    80004688:	89ae                	mv	s3,a1
    8000468a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000468c:	411c                	lw	a5,0(a0)
    8000468e:	4705                	li	a4,1
    80004690:	04e78963          	beq	a5,a4,800046e2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004694:	470d                	li	a4,3
    80004696:	04e78d63          	beq	a5,a4,800046f0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000469a:	4709                	li	a4,2
    8000469c:	06e79e63          	bne	a5,a4,80004718 <fileread+0xa6>
    ilock(f->ip);
    800046a0:	6d08                	ld	a0,24(a0)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	008080e7          	jalr	8(ra) # 800036aa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046aa:	874a                	mv	a4,s2
    800046ac:	5094                	lw	a3,32(s1)
    800046ae:	864e                	mv	a2,s3
    800046b0:	4585                	li	a1,1
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	2aa080e7          	jalr	682(ra) # 8000395e <readi>
    800046bc:	892a                	mv	s2,a0
    800046be:	00a05563          	blez	a0,800046c8 <fileread+0x56>
      f->off += r;
    800046c2:	509c                	lw	a5,32(s1)
    800046c4:	9fa9                	addw	a5,a5,a0
    800046c6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	0a2080e7          	jalr	162(ra) # 8000376c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046d2:	854a                	mv	a0,s2
    800046d4:	70a2                	ld	ra,40(sp)
    800046d6:	7402                	ld	s0,32(sp)
    800046d8:	64e2                	ld	s1,24(sp)
    800046da:	6942                	ld	s2,16(sp)
    800046dc:	69a2                	ld	s3,8(sp)
    800046de:	6145                	addi	sp,sp,48
    800046e0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046e2:	6908                	ld	a0,16(a0)
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	3ce080e7          	jalr	974(ra) # 80004ab2 <piperead>
    800046ec:	892a                	mv	s2,a0
    800046ee:	b7d5                	j	800046d2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046f0:	02451783          	lh	a5,36(a0)
    800046f4:	03079693          	slli	a3,a5,0x30
    800046f8:	92c1                	srli	a3,a3,0x30
    800046fa:	4725                	li	a4,9
    800046fc:	02d76863          	bltu	a4,a3,8000472c <fileread+0xba>
    80004700:	0792                	slli	a5,a5,0x4
    80004702:	0001c717          	auipc	a4,0x1c
    80004706:	6e670713          	addi	a4,a4,1766 # 80020de8 <devsw>
    8000470a:	97ba                	add	a5,a5,a4
    8000470c:	639c                	ld	a5,0(a5)
    8000470e:	c38d                	beqz	a5,80004730 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004710:	4505                	li	a0,1
    80004712:	9782                	jalr	a5
    80004714:	892a                	mv	s2,a0
    80004716:	bf75                	j	800046d2 <fileread+0x60>
    panic("fileread");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	fb050513          	addi	a0,a0,-80 # 800086c8 <syscalls+0x260>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e24080e7          	jalr	-476(ra) # 80000544 <panic>
    return -1;
    80004728:	597d                	li	s2,-1
    8000472a:	b765                	j	800046d2 <fileread+0x60>
      return -1;
    8000472c:	597d                	li	s2,-1
    8000472e:	b755                	j	800046d2 <fileread+0x60>
    80004730:	597d                	li	s2,-1
    80004732:	b745                	j	800046d2 <fileread+0x60>

0000000080004734 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004734:	715d                	addi	sp,sp,-80
    80004736:	e486                	sd	ra,72(sp)
    80004738:	e0a2                	sd	s0,64(sp)
    8000473a:	fc26                	sd	s1,56(sp)
    8000473c:	f84a                	sd	s2,48(sp)
    8000473e:	f44e                	sd	s3,40(sp)
    80004740:	f052                	sd	s4,32(sp)
    80004742:	ec56                	sd	s5,24(sp)
    80004744:	e85a                	sd	s6,16(sp)
    80004746:	e45e                	sd	s7,8(sp)
    80004748:	e062                	sd	s8,0(sp)
    8000474a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000474c:	00954783          	lbu	a5,9(a0)
    80004750:	10078663          	beqz	a5,8000485c <filewrite+0x128>
    80004754:	892a                	mv	s2,a0
    80004756:	8aae                	mv	s5,a1
    80004758:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475a:	411c                	lw	a5,0(a0)
    8000475c:	4705                	li	a4,1
    8000475e:	02e78263          	beq	a5,a4,80004782 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004762:	470d                	li	a4,3
    80004764:	02e78663          	beq	a5,a4,80004790 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004768:	4709                	li	a4,2
    8000476a:	0ee79163          	bne	a5,a4,8000484c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000476e:	0ac05d63          	blez	a2,80004828 <filewrite+0xf4>
    int i = 0;
    80004772:	4981                	li	s3,0
    80004774:	6b05                	lui	s6,0x1
    80004776:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000477a:	6b85                	lui	s7,0x1
    8000477c:	c00b8b9b          	addiw	s7,s7,-1024
    80004780:	a861                	j	80004818 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	22e080e7          	jalr	558(ra) # 800049b2 <pipewrite>
    8000478c:	8a2a                	mv	s4,a0
    8000478e:	a045                	j	8000482e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	0cd76263          	bltu	a4,a3,80004860 <filewrite+0x12c>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001c717          	auipc	a4,0x1c
    800047a6:	64670713          	addi	a4,a4,1606 # 80020de8 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	679c                	ld	a5,8(a5)
    800047ae:	cbdd                	beqz	a5,80004864 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	8a2a                	mv	s4,a0
    800047b6:	a8a5                	j	8000482e <filewrite+0xfa>
    800047b8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	8b0080e7          	jalr	-1872(ra) # 8000406c <begin_op>
      ilock(f->ip);
    800047c4:	01893503          	ld	a0,24(s2)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	ee2080e7          	jalr	-286(ra) # 800036aa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047d0:	8762                	mv	a4,s8
    800047d2:	02092683          	lw	a3,32(s2)
    800047d6:	01598633          	add	a2,s3,s5
    800047da:	4585                	li	a1,1
    800047dc:	01893503          	ld	a0,24(s2)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	276080e7          	jalr	630(ra) # 80003a56 <writei>
    800047e8:	84aa                	mv	s1,a0
    800047ea:	00a05763          	blez	a0,800047f8 <filewrite+0xc4>
        f->off += r;
    800047ee:	02092783          	lw	a5,32(s2)
    800047f2:	9fa9                	addw	a5,a5,a0
    800047f4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047f8:	01893503          	ld	a0,24(s2)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	f70080e7          	jalr	-144(ra) # 8000376c <iunlock>
      end_op();
    80004804:	00000097          	auipc	ra,0x0
    80004808:	8e8080e7          	jalr	-1816(ra) # 800040ec <end_op>

      if(r != n1){
    8000480c:	009c1f63          	bne	s8,s1,8000482a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004810:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004814:	0149db63          	bge	s3,s4,8000482a <filewrite+0xf6>
      int n1 = n - i;
    80004818:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000481c:	84be                	mv	s1,a5
    8000481e:	2781                	sext.w	a5,a5
    80004820:	f8fb5ce3          	bge	s6,a5,800047b8 <filewrite+0x84>
    80004824:	84de                	mv	s1,s7
    80004826:	bf49                	j	800047b8 <filewrite+0x84>
    int i = 0;
    80004828:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000482a:	013a1f63          	bne	s4,s3,80004848 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000482e:	8552                	mv	a0,s4
    80004830:	60a6                	ld	ra,72(sp)
    80004832:	6406                	ld	s0,64(sp)
    80004834:	74e2                	ld	s1,56(sp)
    80004836:	7942                	ld	s2,48(sp)
    80004838:	79a2                	ld	s3,40(sp)
    8000483a:	7a02                	ld	s4,32(sp)
    8000483c:	6ae2                	ld	s5,24(sp)
    8000483e:	6b42                	ld	s6,16(sp)
    80004840:	6ba2                	ld	s7,8(sp)
    80004842:	6c02                	ld	s8,0(sp)
    80004844:	6161                	addi	sp,sp,80
    80004846:	8082                	ret
    ret = (i == n ? n : -1);
    80004848:	5a7d                	li	s4,-1
    8000484a:	b7d5                	j	8000482e <filewrite+0xfa>
    panic("filewrite");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e8c50513          	addi	a0,a0,-372 # 800086d8 <syscalls+0x270>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cf0080e7          	jalr	-784(ra) # 80000544 <panic>
    return -1;
    8000485c:	5a7d                	li	s4,-1
    8000485e:	bfc1                	j	8000482e <filewrite+0xfa>
      return -1;
    80004860:	5a7d                	li	s4,-1
    80004862:	b7f1                	j	8000482e <filewrite+0xfa>
    80004864:	5a7d                	li	s4,-1
    80004866:	b7e1                	j	8000482e <filewrite+0xfa>

0000000080004868 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004868:	7179                	addi	sp,sp,-48
    8000486a:	f406                	sd	ra,40(sp)
    8000486c:	f022                	sd	s0,32(sp)
    8000486e:	ec26                	sd	s1,24(sp)
    80004870:	e84a                	sd	s2,16(sp)
    80004872:	e44e                	sd	s3,8(sp)
    80004874:	e052                	sd	s4,0(sp)
    80004876:	1800                	addi	s0,sp,48
    80004878:	84aa                	mv	s1,a0
    8000487a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000487c:	0005b023          	sd	zero,0(a1)
    80004880:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004884:	00000097          	auipc	ra,0x0
    80004888:	bf8080e7          	jalr	-1032(ra) # 8000447c <filealloc>
    8000488c:	e088                	sd	a0,0(s1)
    8000488e:	c551                	beqz	a0,8000491a <pipealloc+0xb2>
    80004890:	00000097          	auipc	ra,0x0
    80004894:	bec080e7          	jalr	-1044(ra) # 8000447c <filealloc>
    80004898:	00aa3023          	sd	a0,0(s4)
    8000489c:	c92d                	beqz	a0,8000490e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	25c080e7          	jalr	604(ra) # 80000afa <kalloc>
    800048a6:	892a                	mv	s2,a0
    800048a8:	c125                	beqz	a0,80004908 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048aa:	4985                	li	s3,1
    800048ac:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048b0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048b4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048b8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048bc:	00004597          	auipc	a1,0x4
    800048c0:	e2c58593          	addi	a1,a1,-468 # 800086e8 <syscalls+0x280>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	296080e7          	jalr	662(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800048cc:	609c                	ld	a5,0(s1)
    800048ce:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048d2:	609c                	ld	a5,0(s1)
    800048d4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048d8:	609c                	ld	a5,0(s1)
    800048da:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048de:	609c                	ld	a5,0(s1)
    800048e0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048e4:	000a3783          	ld	a5,0(s4)
    800048e8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ec:	000a3783          	ld	a5,0(s4)
    800048f0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048f4:	000a3783          	ld	a5,0(s4)
    800048f8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048fc:	000a3783          	ld	a5,0(s4)
    80004900:	0127b823          	sd	s2,16(a5)
  return 0;
    80004904:	4501                	li	a0,0
    80004906:	a025                	j	8000492e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004908:	6088                	ld	a0,0(s1)
    8000490a:	e501                	bnez	a0,80004912 <pipealloc+0xaa>
    8000490c:	a039                	j	8000491a <pipealloc+0xb2>
    8000490e:	6088                	ld	a0,0(s1)
    80004910:	c51d                	beqz	a0,8000493e <pipealloc+0xd6>
    fileclose(*f0);
    80004912:	00000097          	auipc	ra,0x0
    80004916:	c26080e7          	jalr	-986(ra) # 80004538 <fileclose>
  if(*f1)
    8000491a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000491e:	557d                	li	a0,-1
  if(*f1)
    80004920:	c799                	beqz	a5,8000492e <pipealloc+0xc6>
    fileclose(*f1);
    80004922:	853e                	mv	a0,a5
    80004924:	00000097          	auipc	ra,0x0
    80004928:	c14080e7          	jalr	-1004(ra) # 80004538 <fileclose>
  return -1;
    8000492c:	557d                	li	a0,-1
}
    8000492e:	70a2                	ld	ra,40(sp)
    80004930:	7402                	ld	s0,32(sp)
    80004932:	64e2                	ld	s1,24(sp)
    80004934:	6942                	ld	s2,16(sp)
    80004936:	69a2                	ld	s3,8(sp)
    80004938:	6a02                	ld	s4,0(sp)
    8000493a:	6145                	addi	sp,sp,48
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	b7fd                	j	8000492e <pipealloc+0xc6>

0000000080004942 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	e04a                	sd	s2,0(sp)
    8000494c:	1000                	addi	s0,sp,32
    8000494e:	84aa                	mv	s1,a0
    80004950:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	298080e7          	jalr	664(ra) # 80000bea <acquire>
  if(writable){
    8000495a:	02090d63          	beqz	s2,80004994 <pipeclose+0x52>
    pi->writeopen = 0;
    8000495e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004962:	21848513          	addi	a0,s1,536
    80004966:	ffffd097          	auipc	ra,0xffffd
    8000496a:	774080e7          	jalr	1908(ra) # 800020da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000496e:	2204b783          	ld	a5,544(s1)
    80004972:	eb95                	bnez	a5,800049a6 <pipeclose+0x64>
    release(&pi->lock);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	328080e7          	jalr	808(ra) # 80000c9e <release>
    kfree((char*)pi);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	07e080e7          	jalr	126(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004988:	60e2                	ld	ra,24(sp)
    8000498a:	6442                	ld	s0,16(sp)
    8000498c:	64a2                	ld	s1,8(sp)
    8000498e:	6902                	ld	s2,0(sp)
    80004990:	6105                	addi	sp,sp,32
    80004992:	8082                	ret
    pi->readopen = 0;
    80004994:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004998:	21c48513          	addi	a0,s1,540
    8000499c:	ffffd097          	auipc	ra,0xffffd
    800049a0:	73e080e7          	jalr	1854(ra) # 800020da <wakeup>
    800049a4:	b7e9                	j	8000496e <pipeclose+0x2c>
    release(&pi->lock);
    800049a6:	8526                	mv	a0,s1
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2f6080e7          	jalr	758(ra) # 80000c9e <release>
}
    800049b0:	bfe1                	j	80004988 <pipeclose+0x46>

00000000800049b2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049b2:	7159                	addi	sp,sp,-112
    800049b4:	f486                	sd	ra,104(sp)
    800049b6:	f0a2                	sd	s0,96(sp)
    800049b8:	eca6                	sd	s1,88(sp)
    800049ba:	e8ca                	sd	s2,80(sp)
    800049bc:	e4ce                	sd	s3,72(sp)
    800049be:	e0d2                	sd	s4,64(sp)
    800049c0:	fc56                	sd	s5,56(sp)
    800049c2:	f85a                	sd	s6,48(sp)
    800049c4:	f45e                	sd	s7,40(sp)
    800049c6:	f062                	sd	s8,32(sp)
    800049c8:	ec66                	sd	s9,24(sp)
    800049ca:	1880                	addi	s0,sp,112
    800049cc:	84aa                	mv	s1,a0
    800049ce:	8aae                	mv	s5,a1
    800049d0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	ff4080e7          	jalr	-12(ra) # 800019c6 <myproc>
    800049da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	20c080e7          	jalr	524(ra) # 80000bea <acquire>
  while(i < n){
    800049e6:	0d405463          	blez	s4,80004aae <pipewrite+0xfc>
    800049ea:	8ba6                	mv	s7,s1
  int i = 0;
    800049ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049f0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f4:	21c48c13          	addi	s8,s1,540
    800049f8:	a08d                	j	80004a5a <pipewrite+0xa8>
      release(&pi->lock);
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	2a2080e7          	jalr	674(ra) # 80000c9e <release>
      return -1;
    80004a04:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a06:	854a                	mv	a0,s2
    80004a08:	70a6                	ld	ra,104(sp)
    80004a0a:	7406                	ld	s0,96(sp)
    80004a0c:	64e6                	ld	s1,88(sp)
    80004a0e:	6946                	ld	s2,80(sp)
    80004a10:	69a6                	ld	s3,72(sp)
    80004a12:	6a06                	ld	s4,64(sp)
    80004a14:	7ae2                	ld	s5,56(sp)
    80004a16:	7b42                	ld	s6,48(sp)
    80004a18:	7ba2                	ld	s7,40(sp)
    80004a1a:	7c02                	ld	s8,32(sp)
    80004a1c:	6ce2                	ld	s9,24(sp)
    80004a1e:	6165                	addi	sp,sp,112
    80004a20:	8082                	ret
      wakeup(&pi->nread);
    80004a22:	8566                	mv	a0,s9
    80004a24:	ffffd097          	auipc	ra,0xffffd
    80004a28:	6b6080e7          	jalr	1718(ra) # 800020da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a2c:	85de                	mv	a1,s7
    80004a2e:	8562                	mv	a0,s8
    80004a30:	ffffd097          	auipc	ra,0xffffd
    80004a34:	646080e7          	jalr	1606(ra) # 80002076 <sleep>
    80004a38:	a839                	j	80004a56 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a3a:	21c4a783          	lw	a5,540(s1)
    80004a3e:	0017871b          	addiw	a4,a5,1
    80004a42:	20e4ae23          	sw	a4,540(s1)
    80004a46:	1ff7f793          	andi	a5,a5,511
    80004a4a:	97a6                	add	a5,a5,s1
    80004a4c:	f9f44703          	lbu	a4,-97(s0)
    80004a50:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a54:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a56:	05495063          	bge	s2,s4,80004a96 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004a5a:	2204a783          	lw	a5,544(s1)
    80004a5e:	dfd1                	beqz	a5,800049fa <pipewrite+0x48>
    80004a60:	854e                	mv	a0,s3
    80004a62:	ffffe097          	auipc	ra,0xffffe
    80004a66:	8bc080e7          	jalr	-1860(ra) # 8000231e <killed>
    80004a6a:	f941                	bnez	a0,800049fa <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a6c:	2184a783          	lw	a5,536(s1)
    80004a70:	21c4a703          	lw	a4,540(s1)
    80004a74:	2007879b          	addiw	a5,a5,512
    80004a78:	faf705e3          	beq	a4,a5,80004a22 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a7c:	4685                	li	a3,1
    80004a7e:	01590633          	add	a2,s2,s5
    80004a82:	f9f40593          	addi	a1,s0,-97
    80004a86:	0509b503          	ld	a0,80(s3)
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	c86080e7          	jalr	-890(ra) # 80001710 <copyin>
    80004a92:	fb6514e3          	bne	a0,s6,80004a3a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a96:	21848513          	addi	a0,s1,536
    80004a9a:	ffffd097          	auipc	ra,0xffffd
    80004a9e:	640080e7          	jalr	1600(ra) # 800020da <wakeup>
  release(&pi->lock);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1fa080e7          	jalr	506(ra) # 80000c9e <release>
  return i;
    80004aac:	bfa9                	j	80004a06 <pipewrite+0x54>
  int i = 0;
    80004aae:	4901                	li	s2,0
    80004ab0:	b7dd                	j	80004a96 <pipewrite+0xe4>

0000000080004ab2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ab2:	715d                	addi	sp,sp,-80
    80004ab4:	e486                	sd	ra,72(sp)
    80004ab6:	e0a2                	sd	s0,64(sp)
    80004ab8:	fc26                	sd	s1,56(sp)
    80004aba:	f84a                	sd	s2,48(sp)
    80004abc:	f44e                	sd	s3,40(sp)
    80004abe:	f052                	sd	s4,32(sp)
    80004ac0:	ec56                	sd	s5,24(sp)
    80004ac2:	e85a                	sd	s6,16(sp)
    80004ac4:	0880                	addi	s0,sp,80
    80004ac6:	84aa                	mv	s1,a0
    80004ac8:	892e                	mv	s2,a1
    80004aca:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	efa080e7          	jalr	-262(ra) # 800019c6 <myproc>
    80004ad4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ad6:	8b26                	mv	s6,s1
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	110080e7          	jalr	272(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae2:	2184a703          	lw	a4,536(s1)
    80004ae6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aea:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aee:	02f71763          	bne	a4,a5,80004b1c <piperead+0x6a>
    80004af2:	2244a783          	lw	a5,548(s1)
    80004af6:	c39d                	beqz	a5,80004b1c <piperead+0x6a>
    if(killed(pr)){
    80004af8:	8552                	mv	a0,s4
    80004afa:	ffffe097          	auipc	ra,0xffffe
    80004afe:	824080e7          	jalr	-2012(ra) # 8000231e <killed>
    80004b02:	e941                	bnez	a0,80004b92 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b04:	85da                	mv	a1,s6
    80004b06:	854e                	mv	a0,s3
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	56e080e7          	jalr	1390(ra) # 80002076 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b10:	2184a703          	lw	a4,536(s1)
    80004b14:	21c4a783          	lw	a5,540(s1)
    80004b18:	fcf70de3          	beq	a4,a5,80004af2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b1c:	09505263          	blez	s5,80004ba0 <piperead+0xee>
    80004b20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b22:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b24:	2184a783          	lw	a5,536(s1)
    80004b28:	21c4a703          	lw	a4,540(s1)
    80004b2c:	02f70d63          	beq	a4,a5,80004b66 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b30:	0017871b          	addiw	a4,a5,1
    80004b34:	20e4ac23          	sw	a4,536(s1)
    80004b38:	1ff7f793          	andi	a5,a5,511
    80004b3c:	97a6                	add	a5,a5,s1
    80004b3e:	0187c783          	lbu	a5,24(a5)
    80004b42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b46:	4685                	li	a3,1
    80004b48:	fbf40613          	addi	a2,s0,-65
    80004b4c:	85ca                	mv	a1,s2
    80004b4e:	050a3503          	ld	a0,80(s4)
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	b32080e7          	jalr	-1230(ra) # 80001684 <copyout>
    80004b5a:	01650663          	beq	a0,s6,80004b66 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b5e:	2985                	addiw	s3,s3,1
    80004b60:	0905                	addi	s2,s2,1
    80004b62:	fd3a91e3          	bne	s5,s3,80004b24 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b66:	21c48513          	addi	a0,s1,540
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	570080e7          	jalr	1392(ra) # 800020da <wakeup>
  release(&pi->lock);
    80004b72:	8526                	mv	a0,s1
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	12a080e7          	jalr	298(ra) # 80000c9e <release>
  return i;
}
    80004b7c:	854e                	mv	a0,s3
    80004b7e:	60a6                	ld	ra,72(sp)
    80004b80:	6406                	ld	s0,64(sp)
    80004b82:	74e2                	ld	s1,56(sp)
    80004b84:	7942                	ld	s2,48(sp)
    80004b86:	79a2                	ld	s3,40(sp)
    80004b88:	7a02                	ld	s4,32(sp)
    80004b8a:	6ae2                	ld	s5,24(sp)
    80004b8c:	6b42                	ld	s6,16(sp)
    80004b8e:	6161                	addi	sp,sp,80
    80004b90:	8082                	ret
      release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	10a080e7          	jalr	266(ra) # 80000c9e <release>
      return -1;
    80004b9c:	59fd                	li	s3,-1
    80004b9e:	bff9                	j	80004b7c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba0:	4981                	li	s3,0
    80004ba2:	b7d1                	j	80004b66 <piperead+0xb4>

0000000080004ba4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ba4:	1141                	addi	sp,sp,-16
    80004ba6:	e422                	sd	s0,8(sp)
    80004ba8:	0800                	addi	s0,sp,16
    80004baa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bac:	8905                	andi	a0,a0,1
    80004bae:	c111                	beqz	a0,80004bb2 <flags2perm+0xe>
      perm = PTE_X;
    80004bb0:	4521                	li	a0,8
    if(flags & 0x2)
    80004bb2:	8b89                	andi	a5,a5,2
    80004bb4:	c399                	beqz	a5,80004bba <flags2perm+0x16>
      perm |= PTE_W;
    80004bb6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bba:	6422                	ld	s0,8(sp)
    80004bbc:	0141                	addi	sp,sp,16
    80004bbe:	8082                	ret

0000000080004bc0 <exec>:

int
exec(char *path, char **argv)
{
    80004bc0:	df010113          	addi	sp,sp,-528
    80004bc4:	20113423          	sd	ra,520(sp)
    80004bc8:	20813023          	sd	s0,512(sp)
    80004bcc:	ffa6                	sd	s1,504(sp)
    80004bce:	fbca                	sd	s2,496(sp)
    80004bd0:	f7ce                	sd	s3,488(sp)
    80004bd2:	f3d2                	sd	s4,480(sp)
    80004bd4:	efd6                	sd	s5,472(sp)
    80004bd6:	ebda                	sd	s6,464(sp)
    80004bd8:	e7de                	sd	s7,456(sp)
    80004bda:	e3e2                	sd	s8,448(sp)
    80004bdc:	ff66                	sd	s9,440(sp)
    80004bde:	fb6a                	sd	s10,432(sp)
    80004be0:	f76e                	sd	s11,424(sp)
    80004be2:	0c00                	addi	s0,sp,528
    80004be4:	84aa                	mv	s1,a0
    80004be6:	dea43c23          	sd	a0,-520(s0)
    80004bea:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	dd8080e7          	jalr	-552(ra) # 800019c6 <myproc>
    80004bf6:	892a                	mv	s2,a0

  begin_op();
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	474080e7          	jalr	1140(ra) # 8000406c <begin_op>

  if((ip = namei(path)) == 0){
    80004c00:	8526                	mv	a0,s1
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	24e080e7          	jalr	590(ra) # 80003e50 <namei>
    80004c0a:	c92d                	beqz	a0,80004c7c <exec+0xbc>
    80004c0c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	a9c080e7          	jalr	-1380(ra) # 800036aa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c16:	04000713          	li	a4,64
    80004c1a:	4681                	li	a3,0
    80004c1c:	e5040613          	addi	a2,s0,-432
    80004c20:	4581                	li	a1,0
    80004c22:	8526                	mv	a0,s1
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	d3a080e7          	jalr	-710(ra) # 8000395e <readi>
    80004c2c:	04000793          	li	a5,64
    80004c30:	00f51a63          	bne	a0,a5,80004c44 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c34:	e5042703          	lw	a4,-432(s0)
    80004c38:	464c47b7          	lui	a5,0x464c4
    80004c3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c40:	04f70463          	beq	a4,a5,80004c88 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c44:	8526                	mv	a0,s1
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	cc6080e7          	jalr	-826(ra) # 8000390c <iunlockput>
    end_op();
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	49e080e7          	jalr	1182(ra) # 800040ec <end_op>
  }
  return -1;
    80004c56:	557d                	li	a0,-1
}
    80004c58:	20813083          	ld	ra,520(sp)
    80004c5c:	20013403          	ld	s0,512(sp)
    80004c60:	74fe                	ld	s1,504(sp)
    80004c62:	795e                	ld	s2,496(sp)
    80004c64:	79be                	ld	s3,488(sp)
    80004c66:	7a1e                	ld	s4,480(sp)
    80004c68:	6afe                	ld	s5,472(sp)
    80004c6a:	6b5e                	ld	s6,464(sp)
    80004c6c:	6bbe                	ld	s7,456(sp)
    80004c6e:	6c1e                	ld	s8,448(sp)
    80004c70:	7cfa                	ld	s9,440(sp)
    80004c72:	7d5a                	ld	s10,432(sp)
    80004c74:	7dba                	ld	s11,424(sp)
    80004c76:	21010113          	addi	sp,sp,528
    80004c7a:	8082                	ret
    end_op();
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	470080e7          	jalr	1136(ra) # 800040ec <end_op>
    return -1;
    80004c84:	557d                	li	a0,-1
    80004c86:	bfc9                	j	80004c58 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c88:	854a                	mv	a0,s2
    80004c8a:	ffffd097          	auipc	ra,0xffffd
    80004c8e:	e00080e7          	jalr	-512(ra) # 80001a8a <proc_pagetable>
    80004c92:	8baa                	mv	s7,a0
    80004c94:	d945                	beqz	a0,80004c44 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c96:	e7042983          	lw	s3,-400(s0)
    80004c9a:	e8845783          	lhu	a5,-376(s0)
    80004c9e:	c7ad                	beqz	a5,80004d08 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ca0:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ca4:	6c85                	lui	s9,0x1
    80004ca6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004caa:	def43823          	sd	a5,-528(s0)
    80004cae:	ac0d                	j	80004ee0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cb0:	00004517          	auipc	a0,0x4
    80004cb4:	a4050513          	addi	a0,a0,-1472 # 800086f0 <syscalls+0x288>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	88c080e7          	jalr	-1908(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cc0:	8756                	mv	a4,s5
    80004cc2:	012d86bb          	addw	a3,s11,s2
    80004cc6:	4581                	li	a1,0
    80004cc8:	8526                	mv	a0,s1
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	c94080e7          	jalr	-876(ra) # 8000395e <readi>
    80004cd2:	2501                	sext.w	a0,a0
    80004cd4:	1aaa9a63          	bne	s5,a0,80004e88 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004cd8:	6785                	lui	a5,0x1
    80004cda:	0127893b          	addw	s2,a5,s2
    80004cde:	77fd                	lui	a5,0xfffff
    80004ce0:	01478a3b          	addw	s4,a5,s4
    80004ce4:	1f897563          	bgeu	s2,s8,80004ece <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004ce8:	02091593          	slli	a1,s2,0x20
    80004cec:	9181                	srli	a1,a1,0x20
    80004cee:	95ea                	add	a1,a1,s10
    80004cf0:	855e                	mv	a0,s7
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	386080e7          	jalr	902(ra) # 80001078 <walkaddr>
    80004cfa:	862a                	mv	a2,a0
    if(pa == 0)
    80004cfc:	d955                	beqz	a0,80004cb0 <exec+0xf0>
      n = PGSIZE;
    80004cfe:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d00:	fd9a70e3          	bgeu	s4,s9,80004cc0 <exec+0x100>
      n = sz - i;
    80004d04:	8ad2                	mv	s5,s4
    80004d06:	bf6d                	j	80004cc0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d08:	4a01                	li	s4,0
  iunlockput(ip);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	c00080e7          	jalr	-1024(ra) # 8000390c <iunlockput>
  end_op();
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	3d8080e7          	jalr	984(ra) # 800040ec <end_op>
  p = myproc();
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	caa080e7          	jalr	-854(ra) # 800019c6 <myproc>
    80004d24:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d26:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d2a:	6785                	lui	a5,0x1
    80004d2c:	17fd                	addi	a5,a5,-1
    80004d2e:	9a3e                	add	s4,s4,a5
    80004d30:	757d                	lui	a0,0xfffff
    80004d32:	00aa77b3          	and	a5,s4,a0
    80004d36:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d3a:	4691                	li	a3,4
    80004d3c:	6609                	lui	a2,0x2
    80004d3e:	963e                	add	a2,a2,a5
    80004d40:	85be                	mv	a1,a5
    80004d42:	855e                	mv	a0,s7
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	6e8080e7          	jalr	1768(ra) # 8000142c <uvmalloc>
    80004d4c:	8b2a                	mv	s6,a0
  ip = 0;
    80004d4e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d50:	12050c63          	beqz	a0,80004e88 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d54:	75f9                	lui	a1,0xffffe
    80004d56:	95aa                	add	a1,a1,a0
    80004d58:	855e                	mv	a0,s7
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	8f8080e7          	jalr	-1800(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d62:	7c7d                	lui	s8,0xfffff
    80004d64:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d66:	e0043783          	ld	a5,-512(s0)
    80004d6a:	6388                	ld	a0,0(a5)
    80004d6c:	c535                	beqz	a0,80004dd8 <exec+0x218>
    80004d6e:	e9040993          	addi	s3,s0,-368
    80004d72:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d76:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	0f2080e7          	jalr	242(ra) # 80000e6a <strlen>
    80004d80:	2505                	addiw	a0,a0,1
    80004d82:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d86:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d8a:	13896663          	bltu	s2,s8,80004eb6 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d8e:	e0043d83          	ld	s11,-512(s0)
    80004d92:	000dba03          	ld	s4,0(s11)
    80004d96:	8552                	mv	a0,s4
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	0d2080e7          	jalr	210(ra) # 80000e6a <strlen>
    80004da0:	0015069b          	addiw	a3,a0,1
    80004da4:	8652                	mv	a2,s4
    80004da6:	85ca                	mv	a1,s2
    80004da8:	855e                	mv	a0,s7
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	8da080e7          	jalr	-1830(ra) # 80001684 <copyout>
    80004db2:	10054663          	bltz	a0,80004ebe <exec+0x2fe>
    ustack[argc] = sp;
    80004db6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dba:	0485                	addi	s1,s1,1
    80004dbc:	008d8793          	addi	a5,s11,8
    80004dc0:	e0f43023          	sd	a5,-512(s0)
    80004dc4:	008db503          	ld	a0,8(s11)
    80004dc8:	c911                	beqz	a0,80004ddc <exec+0x21c>
    if(argc >= MAXARG)
    80004dca:	09a1                	addi	s3,s3,8
    80004dcc:	fb3c96e3          	bne	s9,s3,80004d78 <exec+0x1b8>
  sz = sz1;
    80004dd0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dd4:	4481                	li	s1,0
    80004dd6:	a84d                	j	80004e88 <exec+0x2c8>
  sp = sz;
    80004dd8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dda:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ddc:	00349793          	slli	a5,s1,0x3
    80004de0:	f9040713          	addi	a4,s0,-112
    80004de4:	97ba                	add	a5,a5,a4
    80004de6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004dea:	00148693          	addi	a3,s1,1
    80004dee:	068e                	slli	a3,a3,0x3
    80004df0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004df4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004df8:	01897663          	bgeu	s2,s8,80004e04 <exec+0x244>
  sz = sz1;
    80004dfc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e00:	4481                	li	s1,0
    80004e02:	a059                	j	80004e88 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e04:	e9040613          	addi	a2,s0,-368
    80004e08:	85ca                	mv	a1,s2
    80004e0a:	855e                	mv	a0,s7
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	878080e7          	jalr	-1928(ra) # 80001684 <copyout>
    80004e14:	0a054963          	bltz	a0,80004ec6 <exec+0x306>
  p->trapframe->a1 = sp;
    80004e18:	058ab783          	ld	a5,88(s5)
    80004e1c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e20:	df843783          	ld	a5,-520(s0)
    80004e24:	0007c703          	lbu	a4,0(a5)
    80004e28:	cf11                	beqz	a4,80004e44 <exec+0x284>
    80004e2a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e2c:	02f00693          	li	a3,47
    80004e30:	a039                	j	80004e3e <exec+0x27e>
      last = s+1;
    80004e32:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e36:	0785                	addi	a5,a5,1
    80004e38:	fff7c703          	lbu	a4,-1(a5)
    80004e3c:	c701                	beqz	a4,80004e44 <exec+0x284>
    if(*s == '/')
    80004e3e:	fed71ce3          	bne	a4,a3,80004e36 <exec+0x276>
    80004e42:	bfc5                	j	80004e32 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e44:	4641                	li	a2,16
    80004e46:	df843583          	ld	a1,-520(s0)
    80004e4a:	158a8513          	addi	a0,s5,344
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	fea080e7          	jalr	-22(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e56:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e5a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e5e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e62:	058ab783          	ld	a5,88(s5)
    80004e66:	e6843703          	ld	a4,-408(s0)
    80004e6a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e6c:	058ab783          	ld	a5,88(s5)
    80004e70:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e74:	85ea                	mv	a1,s10
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	cb0080e7          	jalr	-848(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e7e:	0004851b          	sext.w	a0,s1
    80004e82:	bbd9                	j	80004c58 <exec+0x98>
    80004e84:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e88:	e0843583          	ld	a1,-504(s0)
    80004e8c:	855e                	mv	a0,s7
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	c98080e7          	jalr	-872(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004e96:	da0497e3          	bnez	s1,80004c44 <exec+0x84>
  return -1;
    80004e9a:	557d                	li	a0,-1
    80004e9c:	bb75                	j	80004c58 <exec+0x98>
    80004e9e:	e1443423          	sd	s4,-504(s0)
    80004ea2:	b7dd                	j	80004e88 <exec+0x2c8>
    80004ea4:	e1443423          	sd	s4,-504(s0)
    80004ea8:	b7c5                	j	80004e88 <exec+0x2c8>
    80004eaa:	e1443423          	sd	s4,-504(s0)
    80004eae:	bfe9                	j	80004e88 <exec+0x2c8>
    80004eb0:	e1443423          	sd	s4,-504(s0)
    80004eb4:	bfd1                	j	80004e88 <exec+0x2c8>
  sz = sz1;
    80004eb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eba:	4481                	li	s1,0
    80004ebc:	b7f1                	j	80004e88 <exec+0x2c8>
  sz = sz1;
    80004ebe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec2:	4481                	li	s1,0
    80004ec4:	b7d1                	j	80004e88 <exec+0x2c8>
  sz = sz1;
    80004ec6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eca:	4481                	li	s1,0
    80004ecc:	bf75                	j	80004e88 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ece:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	2b05                	addiw	s6,s6,1
    80004ed4:	0389899b          	addiw	s3,s3,56
    80004ed8:	e8845783          	lhu	a5,-376(s0)
    80004edc:	e2fb57e3          	bge	s6,a5,80004d0a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ee0:	2981                	sext.w	s3,s3
    80004ee2:	03800713          	li	a4,56
    80004ee6:	86ce                	mv	a3,s3
    80004ee8:	e1840613          	addi	a2,s0,-488
    80004eec:	4581                	li	a1,0
    80004eee:	8526                	mv	a0,s1
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	a6e080e7          	jalr	-1426(ra) # 8000395e <readi>
    80004ef8:	03800793          	li	a5,56
    80004efc:	f8f514e3          	bne	a0,a5,80004e84 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80004f00:	e1842783          	lw	a5,-488(s0)
    80004f04:	4705                	li	a4,1
    80004f06:	fce796e3          	bne	a5,a4,80004ed2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80004f0a:	e4043903          	ld	s2,-448(s0)
    80004f0e:	e3843783          	ld	a5,-456(s0)
    80004f12:	f8f966e3          	bltu	s2,a5,80004e9e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f16:	e2843783          	ld	a5,-472(s0)
    80004f1a:	993e                	add	s2,s2,a5
    80004f1c:	f8f964e3          	bltu	s2,a5,80004ea4 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80004f20:	df043703          	ld	a4,-528(s0)
    80004f24:	8ff9                	and	a5,a5,a4
    80004f26:	f3d1                	bnez	a5,80004eaa <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f28:	e1c42503          	lw	a0,-484(s0)
    80004f2c:	00000097          	auipc	ra,0x0
    80004f30:	c78080e7          	jalr	-904(ra) # 80004ba4 <flags2perm>
    80004f34:	86aa                	mv	a3,a0
    80004f36:	864a                	mv	a2,s2
    80004f38:	85d2                	mv	a1,s4
    80004f3a:	855e                	mv	a0,s7
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	4f0080e7          	jalr	1264(ra) # 8000142c <uvmalloc>
    80004f44:	e0a43423          	sd	a0,-504(s0)
    80004f48:	d525                	beqz	a0,80004eb0 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f4a:	e2843d03          	ld	s10,-472(s0)
    80004f4e:	e2042d83          	lw	s11,-480(s0)
    80004f52:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f56:	f60c0ce3          	beqz	s8,80004ece <exec+0x30e>
    80004f5a:	8a62                	mv	s4,s8
    80004f5c:	4901                	li	s2,0
    80004f5e:	b369                	j	80004ce8 <exec+0x128>

0000000080004f60 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f60:	7179                	addi	sp,sp,-48
    80004f62:	f406                	sd	ra,40(sp)
    80004f64:	f022                	sd	s0,32(sp)
    80004f66:	ec26                	sd	s1,24(sp)
    80004f68:	e84a                	sd	s2,16(sp)
    80004f6a:	1800                	addi	s0,sp,48
    80004f6c:	892e                	mv	s2,a1
    80004f6e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f70:	fdc40593          	addi	a1,s0,-36
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	b6e080e7          	jalr	-1170(ra) # 80002ae2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f7c:	fdc42703          	lw	a4,-36(s0)
    80004f80:	47bd                	li	a5,15
    80004f82:	02e7eb63          	bltu	a5,a4,80004fb8 <argfd+0x58>
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	a40080e7          	jalr	-1472(ra) # 800019c6 <myproc>
    80004f8e:	fdc42703          	lw	a4,-36(s0)
    80004f92:	01a70793          	addi	a5,a4,26
    80004f96:	078e                	slli	a5,a5,0x3
    80004f98:	953e                	add	a0,a0,a5
    80004f9a:	611c                	ld	a5,0(a0)
    80004f9c:	c385                	beqz	a5,80004fbc <argfd+0x5c>
    return -1;
  if(pfd)
    80004f9e:	00090463          	beqz	s2,80004fa6 <argfd+0x46>
    *pfd = fd;
    80004fa2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fa6:	4501                	li	a0,0
  if(pf)
    80004fa8:	c091                	beqz	s1,80004fac <argfd+0x4c>
    *pf = f;
    80004faa:	e09c                	sd	a5,0(s1)
}
    80004fac:	70a2                	ld	ra,40(sp)
    80004fae:	7402                	ld	s0,32(sp)
    80004fb0:	64e2                	ld	s1,24(sp)
    80004fb2:	6942                	ld	s2,16(sp)
    80004fb4:	6145                	addi	sp,sp,48
    80004fb6:	8082                	ret
    return -1;
    80004fb8:	557d                	li	a0,-1
    80004fba:	bfcd                	j	80004fac <argfd+0x4c>
    80004fbc:	557d                	li	a0,-1
    80004fbe:	b7fd                	j	80004fac <argfd+0x4c>

0000000080004fc0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fc0:	1101                	addi	sp,sp,-32
    80004fc2:	ec06                	sd	ra,24(sp)
    80004fc4:	e822                	sd	s0,16(sp)
    80004fc6:	e426                	sd	s1,8(sp)
    80004fc8:	1000                	addi	s0,sp,32
    80004fca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	9fa080e7          	jalr	-1542(ra) # 800019c6 <myproc>
    80004fd4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fd6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd150>
    80004fda:	4501                	li	a0,0
    80004fdc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fde:	6398                	ld	a4,0(a5)
    80004fe0:	cb19                	beqz	a4,80004ff6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fe2:	2505                	addiw	a0,a0,1
    80004fe4:	07a1                	addi	a5,a5,8
    80004fe6:	fed51ce3          	bne	a0,a3,80004fde <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fea:	557d                	li	a0,-1
}
    80004fec:	60e2                	ld	ra,24(sp)
    80004fee:	6442                	ld	s0,16(sp)
    80004ff0:	64a2                	ld	s1,8(sp)
    80004ff2:	6105                	addi	sp,sp,32
    80004ff4:	8082                	ret
      p->ofile[fd] = f;
    80004ff6:	01a50793          	addi	a5,a0,26
    80004ffa:	078e                	slli	a5,a5,0x3
    80004ffc:	963e                	add	a2,a2,a5
    80004ffe:	e204                	sd	s1,0(a2)
      return fd;
    80005000:	b7f5                	j	80004fec <fdalloc+0x2c>

0000000080005002 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005002:	715d                	addi	sp,sp,-80
    80005004:	e486                	sd	ra,72(sp)
    80005006:	e0a2                	sd	s0,64(sp)
    80005008:	fc26                	sd	s1,56(sp)
    8000500a:	f84a                	sd	s2,48(sp)
    8000500c:	f44e                	sd	s3,40(sp)
    8000500e:	f052                	sd	s4,32(sp)
    80005010:	ec56                	sd	s5,24(sp)
    80005012:	e85a                	sd	s6,16(sp)
    80005014:	0880                	addi	s0,sp,80
    80005016:	8b2e                	mv	s6,a1
    80005018:	89b2                	mv	s3,a2
    8000501a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000501c:	fb040593          	addi	a1,s0,-80
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	e4e080e7          	jalr	-434(ra) # 80003e6e <nameiparent>
    80005028:	84aa                	mv	s1,a0
    8000502a:	16050063          	beqz	a0,8000518a <create+0x188>
    return 0;

  ilock(dp);
    8000502e:	ffffe097          	auipc	ra,0xffffe
    80005032:	67c080e7          	jalr	1660(ra) # 800036aa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005036:	4601                	li	a2,0
    80005038:	fb040593          	addi	a1,s0,-80
    8000503c:	8526                	mv	a0,s1
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	b50080e7          	jalr	-1200(ra) # 80003b8e <dirlookup>
    80005046:	8aaa                	mv	s5,a0
    80005048:	c931                	beqz	a0,8000509c <create+0x9a>
    iunlockput(dp);
    8000504a:	8526                	mv	a0,s1
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	8c0080e7          	jalr	-1856(ra) # 8000390c <iunlockput>
    ilock(ip);
    80005054:	8556                	mv	a0,s5
    80005056:	ffffe097          	auipc	ra,0xffffe
    8000505a:	654080e7          	jalr	1620(ra) # 800036aa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000505e:	000b059b          	sext.w	a1,s6
    80005062:	4789                	li	a5,2
    80005064:	02f59563          	bne	a1,a5,8000508e <create+0x8c>
    80005068:	044ad783          	lhu	a5,68(s5)
    8000506c:	37f9                	addiw	a5,a5,-2
    8000506e:	17c2                	slli	a5,a5,0x30
    80005070:	93c1                	srli	a5,a5,0x30
    80005072:	4705                	li	a4,1
    80005074:	00f76d63          	bltu	a4,a5,8000508e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005078:	8556                	mv	a0,s5
    8000507a:	60a6                	ld	ra,72(sp)
    8000507c:	6406                	ld	s0,64(sp)
    8000507e:	74e2                	ld	s1,56(sp)
    80005080:	7942                	ld	s2,48(sp)
    80005082:	79a2                	ld	s3,40(sp)
    80005084:	7a02                	ld	s4,32(sp)
    80005086:	6ae2                	ld	s5,24(sp)
    80005088:	6b42                	ld	s6,16(sp)
    8000508a:	6161                	addi	sp,sp,80
    8000508c:	8082                	ret
    iunlockput(ip);
    8000508e:	8556                	mv	a0,s5
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	87c080e7          	jalr	-1924(ra) # 8000390c <iunlockput>
    return 0;
    80005098:	4a81                	li	s5,0
    8000509a:	bff9                	j	80005078 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000509c:	85da                	mv	a1,s6
    8000509e:	4088                	lw	a0,0(s1)
    800050a0:	ffffe097          	auipc	ra,0xffffe
    800050a4:	46e080e7          	jalr	1134(ra) # 8000350e <ialloc>
    800050a8:	8a2a                	mv	s4,a0
    800050aa:	c921                	beqz	a0,800050fa <create+0xf8>
  ilock(ip);
    800050ac:	ffffe097          	auipc	ra,0xffffe
    800050b0:	5fe080e7          	jalr	1534(ra) # 800036aa <ilock>
  ip->major = major;
    800050b4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050b8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050bc:	4785                	li	a5,1
    800050be:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800050c2:	8552                	mv	a0,s4
    800050c4:	ffffe097          	auipc	ra,0xffffe
    800050c8:	51c080e7          	jalr	1308(ra) # 800035e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050cc:	000b059b          	sext.w	a1,s6
    800050d0:	4785                	li	a5,1
    800050d2:	02f58b63          	beq	a1,a5,80005108 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800050d6:	004a2603          	lw	a2,4(s4)
    800050da:	fb040593          	addi	a1,s0,-80
    800050de:	8526                	mv	a0,s1
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	cbe080e7          	jalr	-834(ra) # 80003d9e <dirlink>
    800050e8:	06054f63          	bltz	a0,80005166 <create+0x164>
  iunlockput(dp);
    800050ec:	8526                	mv	a0,s1
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	81e080e7          	jalr	-2018(ra) # 8000390c <iunlockput>
  return ip;
    800050f6:	8ad2                	mv	s5,s4
    800050f8:	b741                	j	80005078 <create+0x76>
    iunlockput(dp);
    800050fa:	8526                	mv	a0,s1
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	810080e7          	jalr	-2032(ra) # 8000390c <iunlockput>
    return 0;
    80005104:	8ad2                	mv	s5,s4
    80005106:	bf8d                	j	80005078 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005108:	004a2603          	lw	a2,4(s4)
    8000510c:	00003597          	auipc	a1,0x3
    80005110:	60458593          	addi	a1,a1,1540 # 80008710 <syscalls+0x2a8>
    80005114:	8552                	mv	a0,s4
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	c88080e7          	jalr	-888(ra) # 80003d9e <dirlink>
    8000511e:	04054463          	bltz	a0,80005166 <create+0x164>
    80005122:	40d0                	lw	a2,4(s1)
    80005124:	00003597          	auipc	a1,0x3
    80005128:	5f458593          	addi	a1,a1,1524 # 80008718 <syscalls+0x2b0>
    8000512c:	8552                	mv	a0,s4
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	c70080e7          	jalr	-912(ra) # 80003d9e <dirlink>
    80005136:	02054863          	bltz	a0,80005166 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000513a:	004a2603          	lw	a2,4(s4)
    8000513e:	fb040593          	addi	a1,s0,-80
    80005142:	8526                	mv	a0,s1
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	c5a080e7          	jalr	-934(ra) # 80003d9e <dirlink>
    8000514c:	00054d63          	bltz	a0,80005166 <create+0x164>
    dp->nlink++;  // for ".."
    80005150:	04a4d783          	lhu	a5,74(s1)
    80005154:	2785                	addiw	a5,a5,1
    80005156:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000515a:	8526                	mv	a0,s1
    8000515c:	ffffe097          	auipc	ra,0xffffe
    80005160:	484080e7          	jalr	1156(ra) # 800035e0 <iupdate>
    80005164:	b761                	j	800050ec <create+0xea>
  ip->nlink = 0;
    80005166:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000516a:	8552                	mv	a0,s4
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	474080e7          	jalr	1140(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005174:	8552                	mv	a0,s4
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	796080e7          	jalr	1942(ra) # 8000390c <iunlockput>
  iunlockput(dp);
    8000517e:	8526                	mv	a0,s1
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	78c080e7          	jalr	1932(ra) # 8000390c <iunlockput>
  return 0;
    80005188:	bdc5                	j	80005078 <create+0x76>
    return 0;
    8000518a:	8aaa                	mv	s5,a0
    8000518c:	b5f5                	j	80005078 <create+0x76>

000000008000518e <sys_dup>:
{
    8000518e:	7179                	addi	sp,sp,-48
    80005190:	f406                	sd	ra,40(sp)
    80005192:	f022                	sd	s0,32(sp)
    80005194:	ec26                	sd	s1,24(sp)
    80005196:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005198:	fd840613          	addi	a2,s0,-40
    8000519c:	4581                	li	a1,0
    8000519e:	4501                	li	a0,0
    800051a0:	00000097          	auipc	ra,0x0
    800051a4:	dc0080e7          	jalr	-576(ra) # 80004f60 <argfd>
    return -1;
    800051a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051aa:	02054363          	bltz	a0,800051d0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051ae:	fd843503          	ld	a0,-40(s0)
    800051b2:	00000097          	auipc	ra,0x0
    800051b6:	e0e080e7          	jalr	-498(ra) # 80004fc0 <fdalloc>
    800051ba:	84aa                	mv	s1,a0
    return -1;
    800051bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051be:	00054963          	bltz	a0,800051d0 <sys_dup+0x42>
  filedup(f);
    800051c2:	fd843503          	ld	a0,-40(s0)
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	320080e7          	jalr	800(ra) # 800044e6 <filedup>
  return fd;
    800051ce:	87a6                	mv	a5,s1
}
    800051d0:	853e                	mv	a0,a5
    800051d2:	70a2                	ld	ra,40(sp)
    800051d4:	7402                	ld	s0,32(sp)
    800051d6:	64e2                	ld	s1,24(sp)
    800051d8:	6145                	addi	sp,sp,48
    800051da:	8082                	ret

00000000800051dc <sys_read>:
{
    800051dc:	7179                	addi	sp,sp,-48
    800051de:	f406                	sd	ra,40(sp)
    800051e0:	f022                	sd	s0,32(sp)
    800051e2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051e4:	fd840593          	addi	a1,s0,-40
    800051e8:	4505                	li	a0,1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	918080e7          	jalr	-1768(ra) # 80002b02 <argaddr>
  argint(2, &n);
    800051f2:	fe440593          	addi	a1,s0,-28
    800051f6:	4509                	li	a0,2
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	8ea080e7          	jalr	-1814(ra) # 80002ae2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005200:	fe840613          	addi	a2,s0,-24
    80005204:	4581                	li	a1,0
    80005206:	4501                	li	a0,0
    80005208:	00000097          	auipc	ra,0x0
    8000520c:	d58080e7          	jalr	-680(ra) # 80004f60 <argfd>
    80005210:	87aa                	mv	a5,a0
    return -1;
    80005212:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005214:	0007cc63          	bltz	a5,8000522c <sys_read+0x50>
  return fileread(f, p, n);
    80005218:	fe442603          	lw	a2,-28(s0)
    8000521c:	fd843583          	ld	a1,-40(s0)
    80005220:	fe843503          	ld	a0,-24(s0)
    80005224:	fffff097          	auipc	ra,0xfffff
    80005228:	44e080e7          	jalr	1102(ra) # 80004672 <fileread>
}
    8000522c:	70a2                	ld	ra,40(sp)
    8000522e:	7402                	ld	s0,32(sp)
    80005230:	6145                	addi	sp,sp,48
    80005232:	8082                	ret

0000000080005234 <sys_write>:
{
    80005234:	7179                	addi	sp,sp,-48
    80005236:	f406                	sd	ra,40(sp)
    80005238:	f022                	sd	s0,32(sp)
    8000523a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000523c:	fd840593          	addi	a1,s0,-40
    80005240:	4505                	li	a0,1
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	8c0080e7          	jalr	-1856(ra) # 80002b02 <argaddr>
  argint(2, &n);
    8000524a:	fe440593          	addi	a1,s0,-28
    8000524e:	4509                	li	a0,2
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	892080e7          	jalr	-1902(ra) # 80002ae2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005258:	fe840613          	addi	a2,s0,-24
    8000525c:	4581                	li	a1,0
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	d00080e7          	jalr	-768(ra) # 80004f60 <argfd>
    80005268:	87aa                	mv	a5,a0
    return -1;
    8000526a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000526c:	0007cc63          	bltz	a5,80005284 <sys_write+0x50>
  return filewrite(f, p, n);
    80005270:	fe442603          	lw	a2,-28(s0)
    80005274:	fd843583          	ld	a1,-40(s0)
    80005278:	fe843503          	ld	a0,-24(s0)
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	4b8080e7          	jalr	1208(ra) # 80004734 <filewrite>
}
    80005284:	70a2                	ld	ra,40(sp)
    80005286:	7402                	ld	s0,32(sp)
    80005288:	6145                	addi	sp,sp,48
    8000528a:	8082                	ret

000000008000528c <sys_close>:
{
    8000528c:	1101                	addi	sp,sp,-32
    8000528e:	ec06                	sd	ra,24(sp)
    80005290:	e822                	sd	s0,16(sp)
    80005292:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005294:	fe040613          	addi	a2,s0,-32
    80005298:	fec40593          	addi	a1,s0,-20
    8000529c:	4501                	li	a0,0
    8000529e:	00000097          	auipc	ra,0x0
    800052a2:	cc2080e7          	jalr	-830(ra) # 80004f60 <argfd>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052a8:	02054463          	bltz	a0,800052d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	71a080e7          	jalr	1818(ra) # 800019c6 <myproc>
    800052b4:	fec42783          	lw	a5,-20(s0)
    800052b8:	07e9                	addi	a5,a5,26
    800052ba:	078e                	slli	a5,a5,0x3
    800052bc:	97aa                	add	a5,a5,a0
    800052be:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052c2:	fe043503          	ld	a0,-32(s0)
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	272080e7          	jalr	626(ra) # 80004538 <fileclose>
  return 0;
    800052ce:	4781                	li	a5,0
}
    800052d0:	853e                	mv	a0,a5
    800052d2:	60e2                	ld	ra,24(sp)
    800052d4:	6442                	ld	s0,16(sp)
    800052d6:	6105                	addi	sp,sp,32
    800052d8:	8082                	ret

00000000800052da <sys_fstat>:
{
    800052da:	1101                	addi	sp,sp,-32
    800052dc:	ec06                	sd	ra,24(sp)
    800052de:	e822                	sd	s0,16(sp)
    800052e0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052e2:	fe040593          	addi	a1,s0,-32
    800052e6:	4505                	li	a0,1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	81a080e7          	jalr	-2022(ra) # 80002b02 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052f0:	fe840613          	addi	a2,s0,-24
    800052f4:	4581                	li	a1,0
    800052f6:	4501                	li	a0,0
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	c68080e7          	jalr	-920(ra) # 80004f60 <argfd>
    80005300:	87aa                	mv	a5,a0
    return -1;
    80005302:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005304:	0007ca63          	bltz	a5,80005318 <sys_fstat+0x3e>
  return filestat(f, st);
    80005308:	fe043583          	ld	a1,-32(s0)
    8000530c:	fe843503          	ld	a0,-24(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	2f0080e7          	jalr	752(ra) # 80004600 <filestat>
}
    80005318:	60e2                	ld	ra,24(sp)
    8000531a:	6442                	ld	s0,16(sp)
    8000531c:	6105                	addi	sp,sp,32
    8000531e:	8082                	ret

0000000080005320 <sys_link>:
{
    80005320:	7169                	addi	sp,sp,-304
    80005322:	f606                	sd	ra,296(sp)
    80005324:	f222                	sd	s0,288(sp)
    80005326:	ee26                	sd	s1,280(sp)
    80005328:	ea4a                	sd	s2,272(sp)
    8000532a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000532c:	08000613          	li	a2,128
    80005330:	ed040593          	addi	a1,s0,-304
    80005334:	4501                	li	a0,0
    80005336:	ffffd097          	auipc	ra,0xffffd
    8000533a:	7ec080e7          	jalr	2028(ra) # 80002b22 <argstr>
    return -1;
    8000533e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005340:	10054e63          	bltz	a0,8000545c <sys_link+0x13c>
    80005344:	08000613          	li	a2,128
    80005348:	f5040593          	addi	a1,s0,-176
    8000534c:	4505                	li	a0,1
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	7d4080e7          	jalr	2004(ra) # 80002b22 <argstr>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005358:	10054263          	bltz	a0,8000545c <sys_link+0x13c>
  begin_op();
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	d10080e7          	jalr	-752(ra) # 8000406c <begin_op>
  if((ip = namei(old)) == 0){
    80005364:	ed040513          	addi	a0,s0,-304
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	ae8080e7          	jalr	-1304(ra) # 80003e50 <namei>
    80005370:	84aa                	mv	s1,a0
    80005372:	c551                	beqz	a0,800053fe <sys_link+0xde>
  ilock(ip);
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	336080e7          	jalr	822(ra) # 800036aa <ilock>
  if(ip->type == T_DIR){
    8000537c:	04449703          	lh	a4,68(s1)
    80005380:	4785                	li	a5,1
    80005382:	08f70463          	beq	a4,a5,8000540a <sys_link+0xea>
  ip->nlink++;
    80005386:	04a4d783          	lhu	a5,74(s1)
    8000538a:	2785                	addiw	a5,a5,1
    8000538c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005390:	8526                	mv	a0,s1
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	24e080e7          	jalr	590(ra) # 800035e0 <iupdate>
  iunlock(ip);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	3d0080e7          	jalr	976(ra) # 8000376c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053a4:	fd040593          	addi	a1,s0,-48
    800053a8:	f5040513          	addi	a0,s0,-176
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	ac2080e7          	jalr	-1342(ra) # 80003e6e <nameiparent>
    800053b4:	892a                	mv	s2,a0
    800053b6:	c935                	beqz	a0,8000542a <sys_link+0x10a>
  ilock(dp);
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	2f2080e7          	jalr	754(ra) # 800036aa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053c0:	00092703          	lw	a4,0(s2)
    800053c4:	409c                	lw	a5,0(s1)
    800053c6:	04f71d63          	bne	a4,a5,80005420 <sys_link+0x100>
    800053ca:	40d0                	lw	a2,4(s1)
    800053cc:	fd040593          	addi	a1,s0,-48
    800053d0:	854a                	mv	a0,s2
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	9cc080e7          	jalr	-1588(ra) # 80003d9e <dirlink>
    800053da:	04054363          	bltz	a0,80005420 <sys_link+0x100>
  iunlockput(dp);
    800053de:	854a                	mv	a0,s2
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	52c080e7          	jalr	1324(ra) # 8000390c <iunlockput>
  iput(ip);
    800053e8:	8526                	mv	a0,s1
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	47a080e7          	jalr	1146(ra) # 80003864 <iput>
  end_op();
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	cfa080e7          	jalr	-774(ra) # 800040ec <end_op>
  return 0;
    800053fa:	4781                	li	a5,0
    800053fc:	a085                	j	8000545c <sys_link+0x13c>
    end_op();
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	cee080e7          	jalr	-786(ra) # 800040ec <end_op>
    return -1;
    80005406:	57fd                	li	a5,-1
    80005408:	a891                	j	8000545c <sys_link+0x13c>
    iunlockput(ip);
    8000540a:	8526                	mv	a0,s1
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	500080e7          	jalr	1280(ra) # 8000390c <iunlockput>
    end_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	cd8080e7          	jalr	-808(ra) # 800040ec <end_op>
    return -1;
    8000541c:	57fd                	li	a5,-1
    8000541e:	a83d                	j	8000545c <sys_link+0x13c>
    iunlockput(dp);
    80005420:	854a                	mv	a0,s2
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	4ea080e7          	jalr	1258(ra) # 8000390c <iunlockput>
  ilock(ip);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	27e080e7          	jalr	638(ra) # 800036aa <ilock>
  ip->nlink--;
    80005434:	04a4d783          	lhu	a5,74(s1)
    80005438:	37fd                	addiw	a5,a5,-1
    8000543a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543e:	8526                	mv	a0,s1
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	1a0080e7          	jalr	416(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	4c2080e7          	jalr	1218(ra) # 8000390c <iunlockput>
  end_op();
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	c9a080e7          	jalr	-870(ra) # 800040ec <end_op>
  return -1;
    8000545a:	57fd                	li	a5,-1
}
    8000545c:	853e                	mv	a0,a5
    8000545e:	70b2                	ld	ra,296(sp)
    80005460:	7412                	ld	s0,288(sp)
    80005462:	64f2                	ld	s1,280(sp)
    80005464:	6952                	ld	s2,272(sp)
    80005466:	6155                	addi	sp,sp,304
    80005468:	8082                	ret

000000008000546a <sys_unlink>:
{
    8000546a:	7151                	addi	sp,sp,-240
    8000546c:	f586                	sd	ra,232(sp)
    8000546e:	f1a2                	sd	s0,224(sp)
    80005470:	eda6                	sd	s1,216(sp)
    80005472:	e9ca                	sd	s2,208(sp)
    80005474:	e5ce                	sd	s3,200(sp)
    80005476:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005478:	08000613          	li	a2,128
    8000547c:	f3040593          	addi	a1,s0,-208
    80005480:	4501                	li	a0,0
    80005482:	ffffd097          	auipc	ra,0xffffd
    80005486:	6a0080e7          	jalr	1696(ra) # 80002b22 <argstr>
    8000548a:	18054163          	bltz	a0,8000560c <sys_unlink+0x1a2>
  begin_op();
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	bde080e7          	jalr	-1058(ra) # 8000406c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005496:	fb040593          	addi	a1,s0,-80
    8000549a:	f3040513          	addi	a0,s0,-208
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	9d0080e7          	jalr	-1584(ra) # 80003e6e <nameiparent>
    800054a6:	84aa                	mv	s1,a0
    800054a8:	c979                	beqz	a0,8000557e <sys_unlink+0x114>
  ilock(dp);
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	200080e7          	jalr	512(ra) # 800036aa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054b2:	00003597          	auipc	a1,0x3
    800054b6:	25e58593          	addi	a1,a1,606 # 80008710 <syscalls+0x2a8>
    800054ba:	fb040513          	addi	a0,s0,-80
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	6b6080e7          	jalr	1718(ra) # 80003b74 <namecmp>
    800054c6:	14050a63          	beqz	a0,8000561a <sys_unlink+0x1b0>
    800054ca:	00003597          	auipc	a1,0x3
    800054ce:	24e58593          	addi	a1,a1,590 # 80008718 <syscalls+0x2b0>
    800054d2:	fb040513          	addi	a0,s0,-80
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	69e080e7          	jalr	1694(ra) # 80003b74 <namecmp>
    800054de:	12050e63          	beqz	a0,8000561a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054e2:	f2c40613          	addi	a2,s0,-212
    800054e6:	fb040593          	addi	a1,s0,-80
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	6a2080e7          	jalr	1698(ra) # 80003b8e <dirlookup>
    800054f4:	892a                	mv	s2,a0
    800054f6:	12050263          	beqz	a0,8000561a <sys_unlink+0x1b0>
  ilock(ip);
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	1b0080e7          	jalr	432(ra) # 800036aa <ilock>
  if(ip->nlink < 1)
    80005502:	04a91783          	lh	a5,74(s2)
    80005506:	08f05263          	blez	a5,8000558a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000550a:	04491703          	lh	a4,68(s2)
    8000550e:	4785                	li	a5,1
    80005510:	08f70563          	beq	a4,a5,8000559a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005514:	4641                	li	a2,16
    80005516:	4581                	li	a1,0
    80005518:	fc040513          	addi	a0,s0,-64
    8000551c:	ffffb097          	auipc	ra,0xffffb
    80005520:	7ca080e7          	jalr	1994(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005524:	4741                	li	a4,16
    80005526:	f2c42683          	lw	a3,-212(s0)
    8000552a:	fc040613          	addi	a2,s0,-64
    8000552e:	4581                	li	a1,0
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	524080e7          	jalr	1316(ra) # 80003a56 <writei>
    8000553a:	47c1                	li	a5,16
    8000553c:	0af51563          	bne	a0,a5,800055e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005540:	04491703          	lh	a4,68(s2)
    80005544:	4785                	li	a5,1
    80005546:	0af70863          	beq	a4,a5,800055f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000554a:	8526                	mv	a0,s1
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	3c0080e7          	jalr	960(ra) # 8000390c <iunlockput>
  ip->nlink--;
    80005554:	04a95783          	lhu	a5,74(s2)
    80005558:	37fd                	addiw	a5,a5,-1
    8000555a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000555e:	854a                	mv	a0,s2
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	080080e7          	jalr	128(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005568:	854a                	mv	a0,s2
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	3a2080e7          	jalr	930(ra) # 8000390c <iunlockput>
  end_op();
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	b7a080e7          	jalr	-1158(ra) # 800040ec <end_op>
  return 0;
    8000557a:	4501                	li	a0,0
    8000557c:	a84d                	j	8000562e <sys_unlink+0x1c4>
    end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	b6e080e7          	jalr	-1170(ra) # 800040ec <end_op>
    return -1;
    80005586:	557d                	li	a0,-1
    80005588:	a05d                	j	8000562e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000558a:	00003517          	auipc	a0,0x3
    8000558e:	19650513          	addi	a0,a0,406 # 80008720 <syscalls+0x2b8>
    80005592:	ffffb097          	auipc	ra,0xffffb
    80005596:	fb2080e7          	jalr	-78(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000559a:	04c92703          	lw	a4,76(s2)
    8000559e:	02000793          	li	a5,32
    800055a2:	f6e7f9e3          	bgeu	a5,a4,80005514 <sys_unlink+0xaa>
    800055a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055aa:	4741                	li	a4,16
    800055ac:	86ce                	mv	a3,s3
    800055ae:	f1840613          	addi	a2,s0,-232
    800055b2:	4581                	li	a1,0
    800055b4:	854a                	mv	a0,s2
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	3a8080e7          	jalr	936(ra) # 8000395e <readi>
    800055be:	47c1                	li	a5,16
    800055c0:	00f51b63          	bne	a0,a5,800055d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055c4:	f1845783          	lhu	a5,-232(s0)
    800055c8:	e7a1                	bnez	a5,80005610 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ca:	29c1                	addiw	s3,s3,16
    800055cc:	04c92783          	lw	a5,76(s2)
    800055d0:	fcf9ede3          	bltu	s3,a5,800055aa <sys_unlink+0x140>
    800055d4:	b781                	j	80005514 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055d6:	00003517          	auipc	a0,0x3
    800055da:	16250513          	addi	a0,a0,354 # 80008738 <syscalls+0x2d0>
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	f66080e7          	jalr	-154(ra) # 80000544 <panic>
    panic("unlink: writei");
    800055e6:	00003517          	auipc	a0,0x3
    800055ea:	16a50513          	addi	a0,a0,362 # 80008750 <syscalls+0x2e8>
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	f56080e7          	jalr	-170(ra) # 80000544 <panic>
    dp->nlink--;
    800055f6:	04a4d783          	lhu	a5,74(s1)
    800055fa:	37fd                	addiw	a5,a5,-1
    800055fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	fde080e7          	jalr	-34(ra) # 800035e0 <iupdate>
    8000560a:	b781                	j	8000554a <sys_unlink+0xe0>
    return -1;
    8000560c:	557d                	li	a0,-1
    8000560e:	a005                	j	8000562e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005610:	854a                	mv	a0,s2
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	2fa080e7          	jalr	762(ra) # 8000390c <iunlockput>
  iunlockput(dp);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	2f0080e7          	jalr	752(ra) # 8000390c <iunlockput>
  end_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	ac8080e7          	jalr	-1336(ra) # 800040ec <end_op>
  return -1;
    8000562c:	557d                	li	a0,-1
}
    8000562e:	70ae                	ld	ra,232(sp)
    80005630:	740e                	ld	s0,224(sp)
    80005632:	64ee                	ld	s1,216(sp)
    80005634:	694e                	ld	s2,208(sp)
    80005636:	69ae                	ld	s3,200(sp)
    80005638:	616d                	addi	sp,sp,240
    8000563a:	8082                	ret

000000008000563c <sys_open>:

uint64
sys_open(void)
{
    8000563c:	7131                	addi	sp,sp,-192
    8000563e:	fd06                	sd	ra,184(sp)
    80005640:	f922                	sd	s0,176(sp)
    80005642:	f526                	sd	s1,168(sp)
    80005644:	f14a                	sd	s2,160(sp)
    80005646:	ed4e                	sd	s3,152(sp)
    80005648:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000564a:	f4c40593          	addi	a1,s0,-180
    8000564e:	4505                	li	a0,1
    80005650:	ffffd097          	auipc	ra,0xffffd
    80005654:	492080e7          	jalr	1170(ra) # 80002ae2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005658:	08000613          	li	a2,128
    8000565c:	f5040593          	addi	a1,s0,-176
    80005660:	4501                	li	a0,0
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	4c0080e7          	jalr	1216(ra) # 80002b22 <argstr>
    8000566a:	87aa                	mv	a5,a0
    return -1;
    8000566c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000566e:	0a07c963          	bltz	a5,80005720 <sys_open+0xe4>

  begin_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	9fa080e7          	jalr	-1542(ra) # 8000406c <begin_op>

  if(omode & O_CREATE){
    8000567a:	f4c42783          	lw	a5,-180(s0)
    8000567e:	2007f793          	andi	a5,a5,512
    80005682:	cfc5                	beqz	a5,8000573a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005684:	4681                	li	a3,0
    80005686:	4601                	li	a2,0
    80005688:	4589                	li	a1,2
    8000568a:	f5040513          	addi	a0,s0,-176
    8000568e:	00000097          	auipc	ra,0x0
    80005692:	974080e7          	jalr	-1676(ra) # 80005002 <create>
    80005696:	84aa                	mv	s1,a0
    if(ip == 0){
    80005698:	c959                	beqz	a0,8000572e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000569a:	04449703          	lh	a4,68(s1)
    8000569e:	478d                	li	a5,3
    800056a0:	00f71763          	bne	a4,a5,800056ae <sys_open+0x72>
    800056a4:	0464d703          	lhu	a4,70(s1)
    800056a8:	47a5                	li	a5,9
    800056aa:	0ce7ed63          	bltu	a5,a4,80005784 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	dce080e7          	jalr	-562(ra) # 8000447c <filealloc>
    800056b6:	89aa                	mv	s3,a0
    800056b8:	10050363          	beqz	a0,800057be <sys_open+0x182>
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	904080e7          	jalr	-1788(ra) # 80004fc0 <fdalloc>
    800056c4:	892a                	mv	s2,a0
    800056c6:	0e054763          	bltz	a0,800057b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ca:	04449703          	lh	a4,68(s1)
    800056ce:	478d                	li	a5,3
    800056d0:	0cf70563          	beq	a4,a5,8000579a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056d4:	4789                	li	a5,2
    800056d6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056da:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056de:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056e2:	f4c42783          	lw	a5,-180(s0)
    800056e6:	0017c713          	xori	a4,a5,1
    800056ea:	8b05                	andi	a4,a4,1
    800056ec:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056f0:	0037f713          	andi	a4,a5,3
    800056f4:	00e03733          	snez	a4,a4
    800056f8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056fc:	4007f793          	andi	a5,a5,1024
    80005700:	c791                	beqz	a5,8000570c <sys_open+0xd0>
    80005702:	04449703          	lh	a4,68(s1)
    80005706:	4789                	li	a5,2
    80005708:	0af70063          	beq	a4,a5,800057a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	05e080e7          	jalr	94(ra) # 8000376c <iunlock>
  end_op();
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	9d6080e7          	jalr	-1578(ra) # 800040ec <end_op>

  return fd;
    8000571e:	854a                	mv	a0,s2
}
    80005720:	70ea                	ld	ra,184(sp)
    80005722:	744a                	ld	s0,176(sp)
    80005724:	74aa                	ld	s1,168(sp)
    80005726:	790a                	ld	s2,160(sp)
    80005728:	69ea                	ld	s3,152(sp)
    8000572a:	6129                	addi	sp,sp,192
    8000572c:	8082                	ret
      end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	9be080e7          	jalr	-1602(ra) # 800040ec <end_op>
      return -1;
    80005736:	557d                	li	a0,-1
    80005738:	b7e5                	j	80005720 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000573a:	f5040513          	addi	a0,s0,-176
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	712080e7          	jalr	1810(ra) # 80003e50 <namei>
    80005746:	84aa                	mv	s1,a0
    80005748:	c905                	beqz	a0,80005778 <sys_open+0x13c>
    ilock(ip);
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	f60080e7          	jalr	-160(ra) # 800036aa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005752:	04449703          	lh	a4,68(s1)
    80005756:	4785                	li	a5,1
    80005758:	f4f711e3          	bne	a4,a5,8000569a <sys_open+0x5e>
    8000575c:	f4c42783          	lw	a5,-180(s0)
    80005760:	d7b9                	beqz	a5,800056ae <sys_open+0x72>
      iunlockput(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	1a8080e7          	jalr	424(ra) # 8000390c <iunlockput>
      end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	980080e7          	jalr	-1664(ra) # 800040ec <end_op>
      return -1;
    80005774:	557d                	li	a0,-1
    80005776:	b76d                	j	80005720 <sys_open+0xe4>
      end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	974080e7          	jalr	-1676(ra) # 800040ec <end_op>
      return -1;
    80005780:	557d                	li	a0,-1
    80005782:	bf79                	j	80005720 <sys_open+0xe4>
    iunlockput(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	186080e7          	jalr	390(ra) # 8000390c <iunlockput>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	95e080e7          	jalr	-1698(ra) # 800040ec <end_op>
    return -1;
    80005796:	557d                	li	a0,-1
    80005798:	b761                	j	80005720 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000579a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000579e:	04649783          	lh	a5,70(s1)
    800057a2:	02f99223          	sh	a5,36(s3)
    800057a6:	bf25                	j	800056de <sys_open+0xa2>
    itrunc(ip);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	00e080e7          	jalr	14(ra) # 800037b8 <itrunc>
    800057b2:	bfa9                	j	8000570c <sys_open+0xd0>
      fileclose(f);
    800057b4:	854e                	mv	a0,s3
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	d82080e7          	jalr	-638(ra) # 80004538 <fileclose>
    iunlockput(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	14c080e7          	jalr	332(ra) # 8000390c <iunlockput>
    end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	924080e7          	jalr	-1756(ra) # 800040ec <end_op>
    return -1;
    800057d0:	557d                	li	a0,-1
    800057d2:	b7b9                	j	80005720 <sys_open+0xe4>

00000000800057d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057d4:	7175                	addi	sp,sp,-144
    800057d6:	e506                	sd	ra,136(sp)
    800057d8:	e122                	sd	s0,128(sp)
    800057da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	890080e7          	jalr	-1904(ra) # 8000406c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057e4:	08000613          	li	a2,128
    800057e8:	f7040593          	addi	a1,s0,-144
    800057ec:	4501                	li	a0,0
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	334080e7          	jalr	820(ra) # 80002b22 <argstr>
    800057f6:	02054963          	bltz	a0,80005828 <sys_mkdir+0x54>
    800057fa:	4681                	li	a3,0
    800057fc:	4601                	li	a2,0
    800057fe:	4585                	li	a1,1
    80005800:	f7040513          	addi	a0,s0,-144
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	7fe080e7          	jalr	2046(ra) # 80005002 <create>
    8000580c:	cd11                	beqz	a0,80005828 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	0fe080e7          	jalr	254(ra) # 8000390c <iunlockput>
  end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	8d6080e7          	jalr	-1834(ra) # 800040ec <end_op>
  return 0;
    8000581e:	4501                	li	a0,0
}
    80005820:	60aa                	ld	ra,136(sp)
    80005822:	640a                	ld	s0,128(sp)
    80005824:	6149                	addi	sp,sp,144
    80005826:	8082                	ret
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	8c4080e7          	jalr	-1852(ra) # 800040ec <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	b7fd                	j	80005820 <sys_mkdir+0x4c>

0000000080005834 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005834:	7135                	addi	sp,sp,-160
    80005836:	ed06                	sd	ra,152(sp)
    80005838:	e922                	sd	s0,144(sp)
    8000583a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	830080e7          	jalr	-2000(ra) # 8000406c <begin_op>
  argint(1, &major);
    80005844:	f6c40593          	addi	a1,s0,-148
    80005848:	4505                	li	a0,1
    8000584a:	ffffd097          	auipc	ra,0xffffd
    8000584e:	298080e7          	jalr	664(ra) # 80002ae2 <argint>
  argint(2, &minor);
    80005852:	f6840593          	addi	a1,s0,-152
    80005856:	4509                	li	a0,2
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	28a080e7          	jalr	650(ra) # 80002ae2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005860:	08000613          	li	a2,128
    80005864:	f7040593          	addi	a1,s0,-144
    80005868:	4501                	li	a0,0
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	2b8080e7          	jalr	696(ra) # 80002b22 <argstr>
    80005872:	02054b63          	bltz	a0,800058a8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005876:	f6841683          	lh	a3,-152(s0)
    8000587a:	f6c41603          	lh	a2,-148(s0)
    8000587e:	458d                	li	a1,3
    80005880:	f7040513          	addi	a0,s0,-144
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	77e080e7          	jalr	1918(ra) # 80005002 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000588c:	cd11                	beqz	a0,800058a8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	07e080e7          	jalr	126(ra) # 8000390c <iunlockput>
  end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	856080e7          	jalr	-1962(ra) # 800040ec <end_op>
  return 0;
    8000589e:	4501                	li	a0,0
}
    800058a0:	60ea                	ld	ra,152(sp)
    800058a2:	644a                	ld	s0,144(sp)
    800058a4:	610d                	addi	sp,sp,160
    800058a6:	8082                	ret
    end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	844080e7          	jalr	-1980(ra) # 800040ec <end_op>
    return -1;
    800058b0:	557d                	li	a0,-1
    800058b2:	b7fd                	j	800058a0 <sys_mknod+0x6c>

00000000800058b4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058b4:	7135                	addi	sp,sp,-160
    800058b6:	ed06                	sd	ra,152(sp)
    800058b8:	e922                	sd	s0,144(sp)
    800058ba:	e526                	sd	s1,136(sp)
    800058bc:	e14a                	sd	s2,128(sp)
    800058be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	106080e7          	jalr	262(ra) # 800019c6 <myproc>
    800058c8:	892a                	mv	s2,a0
  
  begin_op();
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	7a2080e7          	jalr	1954(ra) # 8000406c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058d2:	08000613          	li	a2,128
    800058d6:	f6040593          	addi	a1,s0,-160
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	246080e7          	jalr	582(ra) # 80002b22 <argstr>
    800058e4:	04054b63          	bltz	a0,8000593a <sys_chdir+0x86>
    800058e8:	f6040513          	addi	a0,s0,-160
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	564080e7          	jalr	1380(ra) # 80003e50 <namei>
    800058f4:	84aa                	mv	s1,a0
    800058f6:	c131                	beqz	a0,8000593a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	db2080e7          	jalr	-590(ra) # 800036aa <ilock>
  if(ip->type != T_DIR){
    80005900:	04449703          	lh	a4,68(s1)
    80005904:	4785                	li	a5,1
    80005906:	04f71063          	bne	a4,a5,80005946 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	e60080e7          	jalr	-416(ra) # 8000376c <iunlock>
  iput(p->cwd);
    80005914:	15093503          	ld	a0,336(s2)
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	f4c080e7          	jalr	-180(ra) # 80003864 <iput>
  end_op();
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	7cc080e7          	jalr	1996(ra) # 800040ec <end_op>
  p->cwd = ip;
    80005928:	14993823          	sd	s1,336(s2)
  return 0;
    8000592c:	4501                	li	a0,0
}
    8000592e:	60ea                	ld	ra,152(sp)
    80005930:	644a                	ld	s0,144(sp)
    80005932:	64aa                	ld	s1,136(sp)
    80005934:	690a                	ld	s2,128(sp)
    80005936:	610d                	addi	sp,sp,160
    80005938:	8082                	ret
    end_op();
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	7b2080e7          	jalr	1970(ra) # 800040ec <end_op>
    return -1;
    80005942:	557d                	li	a0,-1
    80005944:	b7ed                	j	8000592e <sys_chdir+0x7a>
    iunlockput(ip);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	fc4080e7          	jalr	-60(ra) # 8000390c <iunlockput>
    end_op();
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	79c080e7          	jalr	1948(ra) # 800040ec <end_op>
    return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	bfd1                	j	8000592e <sys_chdir+0x7a>

000000008000595c <sys_exec>:

uint64
sys_exec(void)
{
    8000595c:	7145                	addi	sp,sp,-464
    8000595e:	e786                	sd	ra,456(sp)
    80005960:	e3a2                	sd	s0,448(sp)
    80005962:	ff26                	sd	s1,440(sp)
    80005964:	fb4a                	sd	s2,432(sp)
    80005966:	f74e                	sd	s3,424(sp)
    80005968:	f352                	sd	s4,416(sp)
    8000596a:	ef56                	sd	s5,408(sp)
    8000596c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000596e:	e3840593          	addi	a1,s0,-456
    80005972:	4505                	li	a0,1
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	18e080e7          	jalr	398(ra) # 80002b02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000597c:	08000613          	li	a2,128
    80005980:	f4040593          	addi	a1,s0,-192
    80005984:	4501                	li	a0,0
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	19c080e7          	jalr	412(ra) # 80002b22 <argstr>
    8000598e:	87aa                	mv	a5,a0
    return -1;
    80005990:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005992:	0c07c263          	bltz	a5,80005a56 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005996:	10000613          	li	a2,256
    8000599a:	4581                	li	a1,0
    8000599c:	e4040513          	addi	a0,s0,-448
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	346080e7          	jalr	838(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059a8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059ac:	89a6                	mv	s3,s1
    800059ae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059b0:	02000a13          	li	s4,32
    800059b4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059b8:	00391513          	slli	a0,s2,0x3
    800059bc:	e3040593          	addi	a1,s0,-464
    800059c0:	e3843783          	ld	a5,-456(s0)
    800059c4:	953e                	add	a0,a0,a5
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	07e080e7          	jalr	126(ra) # 80002a44 <fetchaddr>
    800059ce:	02054a63          	bltz	a0,80005a02 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059d2:	e3043783          	ld	a5,-464(s0)
    800059d6:	c3b9                	beqz	a5,80005a1c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059d8:	ffffb097          	auipc	ra,0xffffb
    800059dc:	122080e7          	jalr	290(ra) # 80000afa <kalloc>
    800059e0:	85aa                	mv	a1,a0
    800059e2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059e6:	cd11                	beqz	a0,80005a02 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059e8:	6605                	lui	a2,0x1
    800059ea:	e3043503          	ld	a0,-464(s0)
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	0a8080e7          	jalr	168(ra) # 80002a96 <fetchstr>
    800059f6:	00054663          	bltz	a0,80005a02 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800059fa:	0905                	addi	s2,s2,1
    800059fc:	09a1                	addi	s3,s3,8
    800059fe:	fb491be3          	bne	s2,s4,800059b4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a02:	10048913          	addi	s2,s1,256
    80005a06:	6088                	ld	a0,0(s1)
    80005a08:	c531                	beqz	a0,80005a54 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a0a:	ffffb097          	auipc	ra,0xffffb
    80005a0e:	ff4080e7          	jalr	-12(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a12:	04a1                	addi	s1,s1,8
    80005a14:	ff2499e3          	bne	s1,s2,80005a06 <sys_exec+0xaa>
  return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	a835                	j	80005a56 <sys_exec+0xfa>
      argv[i] = 0;
    80005a1c:	0a8e                	slli	s5,s5,0x3
    80005a1e:	fc040793          	addi	a5,s0,-64
    80005a22:	9abe                	add	s5,s5,a5
    80005a24:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a28:	e4040593          	addi	a1,s0,-448
    80005a2c:	f4040513          	addi	a0,s0,-192
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	190080e7          	jalr	400(ra) # 80004bc0 <exec>
    80005a38:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3a:	10048993          	addi	s3,s1,256
    80005a3e:	6088                	ld	a0,0(s1)
    80005a40:	c901                	beqz	a0,80005a50 <sys_exec+0xf4>
    kfree(argv[i]);
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	fbc080e7          	jalr	-68(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4a:	04a1                	addi	s1,s1,8
    80005a4c:	ff3499e3          	bne	s1,s3,80005a3e <sys_exec+0xe2>
  return ret;
    80005a50:	854a                	mv	a0,s2
    80005a52:	a011                	j	80005a56 <sys_exec+0xfa>
  return -1;
    80005a54:	557d                	li	a0,-1
}
    80005a56:	60be                	ld	ra,456(sp)
    80005a58:	641e                	ld	s0,448(sp)
    80005a5a:	74fa                	ld	s1,440(sp)
    80005a5c:	795a                	ld	s2,432(sp)
    80005a5e:	79ba                	ld	s3,424(sp)
    80005a60:	7a1a                	ld	s4,416(sp)
    80005a62:	6afa                	ld	s5,408(sp)
    80005a64:	6179                	addi	sp,sp,464
    80005a66:	8082                	ret

0000000080005a68 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a68:	7139                	addi	sp,sp,-64
    80005a6a:	fc06                	sd	ra,56(sp)
    80005a6c:	f822                	sd	s0,48(sp)
    80005a6e:	f426                	sd	s1,40(sp)
    80005a70:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a72:	ffffc097          	auipc	ra,0xffffc
    80005a76:	f54080e7          	jalr	-172(ra) # 800019c6 <myproc>
    80005a7a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a7c:	fd840593          	addi	a1,s0,-40
    80005a80:	4501                	li	a0,0
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	080080e7          	jalr	128(ra) # 80002b02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a8a:	fc840593          	addi	a1,s0,-56
    80005a8e:	fd040513          	addi	a0,s0,-48
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	dd6080e7          	jalr	-554(ra) # 80004868 <pipealloc>
    return -1;
    80005a9a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a9c:	0c054463          	bltz	a0,80005b64 <sys_pipe+0xfc>
  fd0 = -1;
    80005aa0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aa4:	fd043503          	ld	a0,-48(s0)
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	518080e7          	jalr	1304(ra) # 80004fc0 <fdalloc>
    80005ab0:	fca42223          	sw	a0,-60(s0)
    80005ab4:	08054b63          	bltz	a0,80005b4a <sys_pipe+0xe2>
    80005ab8:	fc843503          	ld	a0,-56(s0)
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	504080e7          	jalr	1284(ra) # 80004fc0 <fdalloc>
    80005ac4:	fca42023          	sw	a0,-64(s0)
    80005ac8:	06054863          	bltz	a0,80005b38 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005acc:	4691                	li	a3,4
    80005ace:	fc440613          	addi	a2,s0,-60
    80005ad2:	fd843583          	ld	a1,-40(s0)
    80005ad6:	68a8                	ld	a0,80(s1)
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	bac080e7          	jalr	-1108(ra) # 80001684 <copyout>
    80005ae0:	02054063          	bltz	a0,80005b00 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ae4:	4691                	li	a3,4
    80005ae6:	fc040613          	addi	a2,s0,-64
    80005aea:	fd843583          	ld	a1,-40(s0)
    80005aee:	0591                	addi	a1,a1,4
    80005af0:	68a8                	ld	a0,80(s1)
    80005af2:	ffffc097          	auipc	ra,0xffffc
    80005af6:	b92080e7          	jalr	-1134(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005afa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005afc:	06055463          	bgez	a0,80005b64 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b00:	fc442783          	lw	a5,-60(s0)
    80005b04:	07e9                	addi	a5,a5,26
    80005b06:	078e                	slli	a5,a5,0x3
    80005b08:	97a6                	add	a5,a5,s1
    80005b0a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b0e:	fc042503          	lw	a0,-64(s0)
    80005b12:	0569                	addi	a0,a0,26
    80005b14:	050e                	slli	a0,a0,0x3
    80005b16:	94aa                	add	s1,s1,a0
    80005b18:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b1c:	fd043503          	ld	a0,-48(s0)
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	a18080e7          	jalr	-1512(ra) # 80004538 <fileclose>
    fileclose(wf);
    80005b28:	fc843503          	ld	a0,-56(s0)
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	a0c080e7          	jalr	-1524(ra) # 80004538 <fileclose>
    return -1;
    80005b34:	57fd                	li	a5,-1
    80005b36:	a03d                	j	80005b64 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b38:	fc442783          	lw	a5,-60(s0)
    80005b3c:	0007c763          	bltz	a5,80005b4a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b40:	07e9                	addi	a5,a5,26
    80005b42:	078e                	slli	a5,a5,0x3
    80005b44:	94be                	add	s1,s1,a5
    80005b46:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b4a:	fd043503          	ld	a0,-48(s0)
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	9ea080e7          	jalr	-1558(ra) # 80004538 <fileclose>
    fileclose(wf);
    80005b56:	fc843503          	ld	a0,-56(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	9de080e7          	jalr	-1570(ra) # 80004538 <fileclose>
    return -1;
    80005b62:	57fd                	li	a5,-1
}
    80005b64:	853e                	mv	a0,a5
    80005b66:	70e2                	ld	ra,56(sp)
    80005b68:	7442                	ld	s0,48(sp)
    80005b6a:	74a2                	ld	s1,40(sp)
    80005b6c:	6121                	addi	sp,sp,64
    80005b6e:	8082                	ret

0000000080005b70 <kernelvec>:
    80005b70:	7111                	addi	sp,sp,-256
    80005b72:	e006                	sd	ra,0(sp)
    80005b74:	e40a                	sd	sp,8(sp)
    80005b76:	e80e                	sd	gp,16(sp)
    80005b78:	ec12                	sd	tp,24(sp)
    80005b7a:	f016                	sd	t0,32(sp)
    80005b7c:	f41a                	sd	t1,40(sp)
    80005b7e:	f81e                	sd	t2,48(sp)
    80005b80:	fc22                	sd	s0,56(sp)
    80005b82:	e0a6                	sd	s1,64(sp)
    80005b84:	e4aa                	sd	a0,72(sp)
    80005b86:	e8ae                	sd	a1,80(sp)
    80005b88:	ecb2                	sd	a2,88(sp)
    80005b8a:	f0b6                	sd	a3,96(sp)
    80005b8c:	f4ba                	sd	a4,104(sp)
    80005b8e:	f8be                	sd	a5,112(sp)
    80005b90:	fcc2                	sd	a6,120(sp)
    80005b92:	e146                	sd	a7,128(sp)
    80005b94:	e54a                	sd	s2,136(sp)
    80005b96:	e94e                	sd	s3,144(sp)
    80005b98:	ed52                	sd	s4,152(sp)
    80005b9a:	f156                	sd	s5,160(sp)
    80005b9c:	f55a                	sd	s6,168(sp)
    80005b9e:	f95e                	sd	s7,176(sp)
    80005ba0:	fd62                	sd	s8,184(sp)
    80005ba2:	e1e6                	sd	s9,192(sp)
    80005ba4:	e5ea                	sd	s10,200(sp)
    80005ba6:	e9ee                	sd	s11,208(sp)
    80005ba8:	edf2                	sd	t3,216(sp)
    80005baa:	f1f6                	sd	t4,224(sp)
    80005bac:	f5fa                	sd	t5,232(sp)
    80005bae:	f9fe                	sd	t6,240(sp)
    80005bb0:	d61fc0ef          	jal	ra,80002910 <kerneltrap>
    80005bb4:	6082                	ld	ra,0(sp)
    80005bb6:	6122                	ld	sp,8(sp)
    80005bb8:	61c2                	ld	gp,16(sp)
    80005bba:	7282                	ld	t0,32(sp)
    80005bbc:	7322                	ld	t1,40(sp)
    80005bbe:	73c2                	ld	t2,48(sp)
    80005bc0:	7462                	ld	s0,56(sp)
    80005bc2:	6486                	ld	s1,64(sp)
    80005bc4:	6526                	ld	a0,72(sp)
    80005bc6:	65c6                	ld	a1,80(sp)
    80005bc8:	6666                	ld	a2,88(sp)
    80005bca:	7686                	ld	a3,96(sp)
    80005bcc:	7726                	ld	a4,104(sp)
    80005bce:	77c6                	ld	a5,112(sp)
    80005bd0:	7866                	ld	a6,120(sp)
    80005bd2:	688a                	ld	a7,128(sp)
    80005bd4:	692a                	ld	s2,136(sp)
    80005bd6:	69ca                	ld	s3,144(sp)
    80005bd8:	6a6a                	ld	s4,152(sp)
    80005bda:	7a8a                	ld	s5,160(sp)
    80005bdc:	7b2a                	ld	s6,168(sp)
    80005bde:	7bca                	ld	s7,176(sp)
    80005be0:	7c6a                	ld	s8,184(sp)
    80005be2:	6c8e                	ld	s9,192(sp)
    80005be4:	6d2e                	ld	s10,200(sp)
    80005be6:	6dce                	ld	s11,208(sp)
    80005be8:	6e6e                	ld	t3,216(sp)
    80005bea:	7e8e                	ld	t4,224(sp)
    80005bec:	7f2e                	ld	t5,232(sp)
    80005bee:	7fce                	ld	t6,240(sp)
    80005bf0:	6111                	addi	sp,sp,256
    80005bf2:	10200073          	sret
    80005bf6:	00000013          	nop
    80005bfa:	00000013          	nop
    80005bfe:	0001                	nop

0000000080005c00 <timervec>:
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	e10c                	sd	a1,0(a0)
    80005c06:	e510                	sd	a2,8(a0)
    80005c08:	e914                	sd	a3,16(a0)
    80005c0a:	6d0c                	ld	a1,24(a0)
    80005c0c:	7110                	ld	a2,32(a0)
    80005c0e:	6194                	ld	a3,0(a1)
    80005c10:	96b2                	add	a3,a3,a2
    80005c12:	e194                	sd	a3,0(a1)
    80005c14:	4589                	li	a1,2
    80005c16:	14459073          	csrw	sip,a1
    80005c1a:	6914                	ld	a3,16(a0)
    80005c1c:	6510                	ld	a2,8(a0)
    80005c1e:	610c                	ld	a1,0(a0)
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	30200073          	mret
	...

0000000080005c2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c2a:	1141                	addi	sp,sp,-16
    80005c2c:	e422                	sd	s0,8(sp)
    80005c2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c30:	0c0007b7          	lui	a5,0xc000
    80005c34:	4705                	li	a4,1
    80005c36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c38:	c3d8                	sw	a4,4(a5)
}
    80005c3a:	6422                	ld	s0,8(sp)
    80005c3c:	0141                	addi	sp,sp,16
    80005c3e:	8082                	ret

0000000080005c40 <plicinithart>:

void
plicinithart(void)
{
    80005c40:	1141                	addi	sp,sp,-16
    80005c42:	e406                	sd	ra,8(sp)
    80005c44:	e022                	sd	s0,0(sp)
    80005c46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	d52080e7          	jalr	-686(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c50:	0085171b          	slliw	a4,a0,0x8
    80005c54:	0c0027b7          	lui	a5,0xc002
    80005c58:	97ba                	add	a5,a5,a4
    80005c5a:	40200713          	li	a4,1026
    80005c5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c62:	00d5151b          	slliw	a0,a0,0xd
    80005c66:	0c2017b7          	lui	a5,0xc201
    80005c6a:	953e                	add	a0,a0,a5
    80005c6c:	00052023          	sw	zero,0(a0)
}
    80005c70:	60a2                	ld	ra,8(sp)
    80005c72:	6402                	ld	s0,0(sp)
    80005c74:	0141                	addi	sp,sp,16
    80005c76:	8082                	ret

0000000080005c78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c78:	1141                	addi	sp,sp,-16
    80005c7a:	e406                	sd	ra,8(sp)
    80005c7c:	e022                	sd	s0,0(sp)
    80005c7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c80:	ffffc097          	auipc	ra,0xffffc
    80005c84:	d1a080e7          	jalr	-742(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c88:	00d5179b          	slliw	a5,a0,0xd
    80005c8c:	0c201537          	lui	a0,0xc201
    80005c90:	953e                	add	a0,a0,a5
  return irq;
}
    80005c92:	4148                	lw	a0,4(a0)
    80005c94:	60a2                	ld	ra,8(sp)
    80005c96:	6402                	ld	s0,0(sp)
    80005c98:	0141                	addi	sp,sp,16
    80005c9a:	8082                	ret

0000000080005c9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c9c:	1101                	addi	sp,sp,-32
    80005c9e:	ec06                	sd	ra,24(sp)
    80005ca0:	e822                	sd	s0,16(sp)
    80005ca2:	e426                	sd	s1,8(sp)
    80005ca4:	1000                	addi	s0,sp,32
    80005ca6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	cf2080e7          	jalr	-782(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cb0:	00d5151b          	slliw	a0,a0,0xd
    80005cb4:	0c2017b7          	lui	a5,0xc201
    80005cb8:	97aa                	add	a5,a5,a0
    80005cba:	c3c4                	sw	s1,4(a5)
}
    80005cbc:	60e2                	ld	ra,24(sp)
    80005cbe:	6442                	ld	s0,16(sp)
    80005cc0:	64a2                	ld	s1,8(sp)
    80005cc2:	6105                	addi	sp,sp,32
    80005cc4:	8082                	ret

0000000080005cc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cc6:	1141                	addi	sp,sp,-16
    80005cc8:	e406                	sd	ra,8(sp)
    80005cca:	e022                	sd	s0,0(sp)
    80005ccc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cce:	479d                	li	a5,7
    80005cd0:	04a7cc63          	blt	a5,a0,80005d28 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005cd4:	0001c797          	auipc	a5,0x1c
    80005cd8:	16c78793          	addi	a5,a5,364 # 80021e40 <disk>
    80005cdc:	97aa                	add	a5,a5,a0
    80005cde:	0187c783          	lbu	a5,24(a5)
    80005ce2:	ebb9                	bnez	a5,80005d38 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ce4:	00451613          	slli	a2,a0,0x4
    80005ce8:	0001c797          	auipc	a5,0x1c
    80005cec:	15878793          	addi	a5,a5,344 # 80021e40 <disk>
    80005cf0:	6394                	ld	a3,0(a5)
    80005cf2:	96b2                	add	a3,a3,a2
    80005cf4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cf8:	6398                	ld	a4,0(a5)
    80005cfa:	9732                	add	a4,a4,a2
    80005cfc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d00:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d04:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d08:	953e                	add	a0,a0,a5
    80005d0a:	4785                	li	a5,1
    80005d0c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005d10:	0001c517          	auipc	a0,0x1c
    80005d14:	14850513          	addi	a0,a0,328 # 80021e58 <disk+0x18>
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	3c2080e7          	jalr	962(ra) # 800020da <wakeup>
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret
    panic("free_desc 1");
    80005d28:	00003517          	auipc	a0,0x3
    80005d2c:	a3850513          	addi	a0,a0,-1480 # 80008760 <syscalls+0x2f8>
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	814080e7          	jalr	-2028(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	a3850513          	addi	a0,a0,-1480 # 80008770 <syscalls+0x308>
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	804080e7          	jalr	-2044(ra) # 80000544 <panic>

0000000080005d48 <virtio_disk_init>:
{
    80005d48:	1101                	addi	sp,sp,-32
    80005d4a:	ec06                	sd	ra,24(sp)
    80005d4c:	e822                	sd	s0,16(sp)
    80005d4e:	e426                	sd	s1,8(sp)
    80005d50:	e04a                	sd	s2,0(sp)
    80005d52:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d54:	00003597          	auipc	a1,0x3
    80005d58:	a2c58593          	addi	a1,a1,-1492 # 80008780 <syscalls+0x318>
    80005d5c:	0001c517          	auipc	a0,0x1c
    80005d60:	20c50513          	addi	a0,a0,524 # 80021f68 <disk+0x128>
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	df6080e7          	jalr	-522(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d6c:	100017b7          	lui	a5,0x10001
    80005d70:	4398                	lw	a4,0(a5)
    80005d72:	2701                	sext.w	a4,a4
    80005d74:	747277b7          	lui	a5,0x74727
    80005d78:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d7c:	14f71e63          	bne	a4,a5,80005ed8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d80:	100017b7          	lui	a5,0x10001
    80005d84:	43dc                	lw	a5,4(a5)
    80005d86:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d88:	4709                	li	a4,2
    80005d8a:	14e79763          	bne	a5,a4,80005ed8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d8e:	100017b7          	lui	a5,0x10001
    80005d92:	479c                	lw	a5,8(a5)
    80005d94:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d96:	14e79163          	bne	a5,a4,80005ed8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d9a:	100017b7          	lui	a5,0x10001
    80005d9e:	47d8                	lw	a4,12(a5)
    80005da0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005da2:	554d47b7          	lui	a5,0x554d4
    80005da6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005daa:	12f71763          	bne	a4,a5,80005ed8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dae:	100017b7          	lui	a5,0x10001
    80005db2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db6:	4705                	li	a4,1
    80005db8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dba:	470d                	li	a4,3
    80005dbc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dbe:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dc0:	c7ffe737          	lui	a4,0xc7ffe
    80005dc4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7df>
    80005dc8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dca:	2701                	sext.w	a4,a4
    80005dcc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dce:	472d                	li	a4,11
    80005dd0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005dd2:	0707a903          	lw	s2,112(a5)
    80005dd6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005dd8:	00897793          	andi	a5,s2,8
    80005ddc:	10078663          	beqz	a5,80005ee8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005de0:	100017b7          	lui	a5,0x10001
    80005de4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005de8:	43fc                	lw	a5,68(a5)
    80005dea:	2781                	sext.w	a5,a5
    80005dec:	10079663          	bnez	a5,80005ef8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005df0:	100017b7          	lui	a5,0x10001
    80005df4:	5bdc                	lw	a5,52(a5)
    80005df6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005df8:	10078863          	beqz	a5,80005f08 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005dfc:	471d                	li	a4,7
    80005dfe:	10f77d63          	bgeu	a4,a5,80005f18 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	cf8080e7          	jalr	-776(ra) # 80000afa <kalloc>
    80005e0a:	0001c497          	auipc	s1,0x1c
    80005e0e:	03648493          	addi	s1,s1,54 # 80021e40 <disk>
    80005e12:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	ce6080e7          	jalr	-794(ra) # 80000afa <kalloc>
    80005e1c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e1e:	ffffb097          	auipc	ra,0xffffb
    80005e22:	cdc080e7          	jalr	-804(ra) # 80000afa <kalloc>
    80005e26:	87aa                	mv	a5,a0
    80005e28:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e2a:	6088                	ld	a0,0(s1)
    80005e2c:	cd75                	beqz	a0,80005f28 <virtio_disk_init+0x1e0>
    80005e2e:	0001c717          	auipc	a4,0x1c
    80005e32:	01a73703          	ld	a4,26(a4) # 80021e48 <disk+0x8>
    80005e36:	cb6d                	beqz	a4,80005f28 <virtio_disk_init+0x1e0>
    80005e38:	cbe5                	beqz	a5,80005f28 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005e3a:	6605                	lui	a2,0x1
    80005e3c:	4581                	li	a1,0
    80005e3e:	ffffb097          	auipc	ra,0xffffb
    80005e42:	ea8080e7          	jalr	-344(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e46:	0001c497          	auipc	s1,0x1c
    80005e4a:	ffa48493          	addi	s1,s1,-6 # 80021e40 <disk>
    80005e4e:	6605                	lui	a2,0x1
    80005e50:	4581                	li	a1,0
    80005e52:	6488                	ld	a0,8(s1)
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	e92080e7          	jalr	-366(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e5c:	6605                	lui	a2,0x1
    80005e5e:	4581                	li	a1,0
    80005e60:	6888                	ld	a0,16(s1)
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	e84080e7          	jalr	-380(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4721                	li	a4,8
    80005e70:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e72:	4098                	lw	a4,0(s1)
    80005e74:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e78:	40d8                	lw	a4,4(s1)
    80005e7a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e7e:	6498                	ld	a4,8(s1)
    80005e80:	0007069b          	sext.w	a3,a4
    80005e84:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e88:	9701                	srai	a4,a4,0x20
    80005e8a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e8e:	6898                	ld	a4,16(s1)
    80005e90:	0007069b          	sext.w	a3,a4
    80005e94:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005e98:	9701                	srai	a4,a4,0x20
    80005e9a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005e9e:	4685                	li	a3,1
    80005ea0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005ea2:	4705                	li	a4,1
    80005ea4:	00d48c23          	sb	a3,24(s1)
    80005ea8:	00e48ca3          	sb	a4,25(s1)
    80005eac:	00e48d23          	sb	a4,26(s1)
    80005eb0:	00e48da3          	sb	a4,27(s1)
    80005eb4:	00e48e23          	sb	a4,28(s1)
    80005eb8:	00e48ea3          	sb	a4,29(s1)
    80005ebc:	00e48f23          	sb	a4,30(s1)
    80005ec0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ec4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec8:	0727a823          	sw	s2,112(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6902                	ld	s2,0(sp)
    80005ed4:	6105                	addi	sp,sp,32
    80005ed6:	8082                	ret
    panic("could not find virtio disk");
    80005ed8:	00003517          	auipc	a0,0x3
    80005edc:	8b850513          	addi	a0,a0,-1864 # 80008790 <syscalls+0x328>
    80005ee0:	ffffa097          	auipc	ra,0xffffa
    80005ee4:	664080e7          	jalr	1636(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	8c850513          	addi	a0,a0,-1848 # 800087b0 <syscalls+0x348>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	654080e7          	jalr	1620(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80005ef8:	00003517          	auipc	a0,0x3
    80005efc:	8d850513          	addi	a0,a0,-1832 # 800087d0 <syscalls+0x368>
    80005f00:	ffffa097          	auipc	ra,0xffffa
    80005f04:	644080e7          	jalr	1604(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	8e850513          	addi	a0,a0,-1816 # 800087f0 <syscalls+0x388>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	634080e7          	jalr	1588(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	8f850513          	addi	a0,a0,-1800 # 80008810 <syscalls+0x3a8>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	624080e7          	jalr	1572(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80005f28:	00003517          	auipc	a0,0x3
    80005f2c:	90850513          	addi	a0,a0,-1784 # 80008830 <syscalls+0x3c8>
    80005f30:	ffffa097          	auipc	ra,0xffffa
    80005f34:	614080e7          	jalr	1556(ra) # 80000544 <panic>

0000000080005f38 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f38:	7159                	addi	sp,sp,-112
    80005f3a:	f486                	sd	ra,104(sp)
    80005f3c:	f0a2                	sd	s0,96(sp)
    80005f3e:	eca6                	sd	s1,88(sp)
    80005f40:	e8ca                	sd	s2,80(sp)
    80005f42:	e4ce                	sd	s3,72(sp)
    80005f44:	e0d2                	sd	s4,64(sp)
    80005f46:	fc56                	sd	s5,56(sp)
    80005f48:	f85a                	sd	s6,48(sp)
    80005f4a:	f45e                	sd	s7,40(sp)
    80005f4c:	f062                	sd	s8,32(sp)
    80005f4e:	ec66                	sd	s9,24(sp)
    80005f50:	e86a                	sd	s10,16(sp)
    80005f52:	1880                	addi	s0,sp,112
    80005f54:	892a                	mv	s2,a0
    80005f56:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f58:	00c52c83          	lw	s9,12(a0)
    80005f5c:	001c9c9b          	slliw	s9,s9,0x1
    80005f60:	1c82                	slli	s9,s9,0x20
    80005f62:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f66:	0001c517          	auipc	a0,0x1c
    80005f6a:	00250513          	addi	a0,a0,2 # 80021f68 <disk+0x128>
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	c7c080e7          	jalr	-900(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80005f76:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f78:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80005f7a:	0001cb17          	auipc	s6,0x1c
    80005f7e:	ec6b0b13          	addi	s6,s6,-314 # 80021e40 <disk>
  for(int i = 0; i < 3; i++){
    80005f82:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f84:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f86:	0001cc17          	auipc	s8,0x1c
    80005f8a:	fe2c0c13          	addi	s8,s8,-30 # 80021f68 <disk+0x128>
    80005f8e:	a8b5                	j	8000600a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80005f90:	00fb06b3          	add	a3,s6,a5
    80005f94:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f98:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f9a:	0207c563          	bltz	a5,80005fc4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005f9e:	2485                	addiw	s1,s1,1
    80005fa0:	0711                	addi	a4,a4,4
    80005fa2:	1f548a63          	beq	s1,s5,80006196 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80005fa6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fa8:	0001c697          	auipc	a3,0x1c
    80005fac:	e9868693          	addi	a3,a3,-360 # 80021e40 <disk>
    80005fb0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fb2:	0186c583          	lbu	a1,24(a3)
    80005fb6:	fde9                	bnez	a1,80005f90 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fb8:	2785                	addiw	a5,a5,1
    80005fba:	0685                	addi	a3,a3,1
    80005fbc:	ff779be3          	bne	a5,s7,80005fb2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005fc0:	57fd                	li	a5,-1
    80005fc2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fc4:	02905a63          	blez	s1,80005ff8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005fc8:	f9042503          	lw	a0,-112(s0)
    80005fcc:	00000097          	auipc	ra,0x0
    80005fd0:	cfa080e7          	jalr	-774(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd4:	4785                	li	a5,1
    80005fd6:	0297d163          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005fda:	f9442503          	lw	a0,-108(s0)
    80005fde:	00000097          	auipc	ra,0x0
    80005fe2:	ce8080e7          	jalr	-792(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe6:	4789                	li	a5,2
    80005fe8:	0097d863          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005fec:	f9842503          	lw	a0,-104(s0)
    80005ff0:	00000097          	auipc	ra,0x0
    80005ff4:	cd6080e7          	jalr	-810(ra) # 80005cc6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ff8:	85e2                	mv	a1,s8
    80005ffa:	0001c517          	auipc	a0,0x1c
    80005ffe:	e5e50513          	addi	a0,a0,-418 # 80021e58 <disk+0x18>
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	074080e7          	jalr	116(ra) # 80002076 <sleep>
  for(int i = 0; i < 3; i++){
    8000600a:	f9040713          	addi	a4,s0,-112
    8000600e:	84ce                	mv	s1,s3
    80006010:	bf59                	j	80005fa6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006012:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006016:	00479693          	slli	a3,a5,0x4
    8000601a:	0001c797          	auipc	a5,0x1c
    8000601e:	e2678793          	addi	a5,a5,-474 # 80021e40 <disk>
    80006022:	97b6                	add	a5,a5,a3
    80006024:	4685                	li	a3,1
    80006026:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006028:	0001c597          	auipc	a1,0x1c
    8000602c:	e1858593          	addi	a1,a1,-488 # 80021e40 <disk>
    80006030:	00a60793          	addi	a5,a2,10
    80006034:	0792                	slli	a5,a5,0x4
    80006036:	97ae                	add	a5,a5,a1
    80006038:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000603c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006040:	f6070693          	addi	a3,a4,-160
    80006044:	619c                	ld	a5,0(a1)
    80006046:	97b6                	add	a5,a5,a3
    80006048:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000604a:	6188                	ld	a0,0(a1)
    8000604c:	96aa                	add	a3,a3,a0
    8000604e:	47c1                	li	a5,16
    80006050:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006052:	4785                	li	a5,1
    80006054:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006058:	f9442783          	lw	a5,-108(s0)
    8000605c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006060:	0792                	slli	a5,a5,0x4
    80006062:	953e                	add	a0,a0,a5
    80006064:	05890693          	addi	a3,s2,88
    80006068:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000606a:	6188                	ld	a0,0(a1)
    8000606c:	97aa                	add	a5,a5,a0
    8000606e:	40000693          	li	a3,1024
    80006072:	c794                	sw	a3,8(a5)
  if(write)
    80006074:	100d0d63          	beqz	s10,8000618e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006078:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000607c:	00c7d683          	lhu	a3,12(a5)
    80006080:	0016e693          	ori	a3,a3,1
    80006084:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006088:	f9842583          	lw	a1,-104(s0)
    8000608c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006090:	0001c697          	auipc	a3,0x1c
    80006094:	db068693          	addi	a3,a3,-592 # 80021e40 <disk>
    80006098:	00260793          	addi	a5,a2,2
    8000609c:	0792                	slli	a5,a5,0x4
    8000609e:	97b6                	add	a5,a5,a3
    800060a0:	587d                	li	a6,-1
    800060a2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060a6:	0592                	slli	a1,a1,0x4
    800060a8:	952e                	add	a0,a0,a1
    800060aa:	f9070713          	addi	a4,a4,-112
    800060ae:	9736                	add	a4,a4,a3
    800060b0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800060b2:	6298                	ld	a4,0(a3)
    800060b4:	972e                	add	a4,a4,a1
    800060b6:	4585                	li	a1,1
    800060b8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ba:	4509                	li	a0,2
    800060bc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800060c0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060c4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800060c8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060cc:	6698                	ld	a4,8(a3)
    800060ce:	00275783          	lhu	a5,2(a4)
    800060d2:	8b9d                	andi	a5,a5,7
    800060d4:	0786                	slli	a5,a5,0x1
    800060d6:	97ba                	add	a5,a5,a4
    800060d8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800060dc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060e0:	6698                	ld	a4,8(a3)
    800060e2:	00275783          	lhu	a5,2(a4)
    800060e6:	2785                	addiw	a5,a5,1
    800060e8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060ec:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060f0:	100017b7          	lui	a5,0x10001
    800060f4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060f8:	00492703          	lw	a4,4(s2)
    800060fc:	4785                	li	a5,1
    800060fe:	02f71163          	bne	a4,a5,80006120 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006102:	0001c997          	auipc	s3,0x1c
    80006106:	e6698993          	addi	s3,s3,-410 # 80021f68 <disk+0x128>
  while(b->disk == 1) {
    8000610a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000610c:	85ce                	mv	a1,s3
    8000610e:	854a                	mv	a0,s2
    80006110:	ffffc097          	auipc	ra,0xffffc
    80006114:	f66080e7          	jalr	-154(ra) # 80002076 <sleep>
  while(b->disk == 1) {
    80006118:	00492783          	lw	a5,4(s2)
    8000611c:	fe9788e3          	beq	a5,s1,8000610c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006120:	f9042903          	lw	s2,-112(s0)
    80006124:	00290793          	addi	a5,s2,2
    80006128:	00479713          	slli	a4,a5,0x4
    8000612c:	0001c797          	auipc	a5,0x1c
    80006130:	d1478793          	addi	a5,a5,-748 # 80021e40 <disk>
    80006134:	97ba                	add	a5,a5,a4
    80006136:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000613a:	0001c997          	auipc	s3,0x1c
    8000613e:	d0698993          	addi	s3,s3,-762 # 80021e40 <disk>
    80006142:	00491713          	slli	a4,s2,0x4
    80006146:	0009b783          	ld	a5,0(s3)
    8000614a:	97ba                	add	a5,a5,a4
    8000614c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006150:	854a                	mv	a0,s2
    80006152:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	b70080e7          	jalr	-1168(ra) # 80005cc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000615e:	8885                	andi	s1,s1,1
    80006160:	f0ed                	bnez	s1,80006142 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006162:	0001c517          	auipc	a0,0x1c
    80006166:	e0650513          	addi	a0,a0,-506 # 80021f68 <disk+0x128>
    8000616a:	ffffb097          	auipc	ra,0xffffb
    8000616e:	b34080e7          	jalr	-1228(ra) # 80000c9e <release>
}
    80006172:	70a6                	ld	ra,104(sp)
    80006174:	7406                	ld	s0,96(sp)
    80006176:	64e6                	ld	s1,88(sp)
    80006178:	6946                	ld	s2,80(sp)
    8000617a:	69a6                	ld	s3,72(sp)
    8000617c:	6a06                	ld	s4,64(sp)
    8000617e:	7ae2                	ld	s5,56(sp)
    80006180:	7b42                	ld	s6,48(sp)
    80006182:	7ba2                	ld	s7,40(sp)
    80006184:	7c02                	ld	s8,32(sp)
    80006186:	6ce2                	ld	s9,24(sp)
    80006188:	6d42                	ld	s10,16(sp)
    8000618a:	6165                	addi	sp,sp,112
    8000618c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618e:	4689                	li	a3,2
    80006190:	00d79623          	sh	a3,12(a5)
    80006194:	b5e5                	j	8000607c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006196:	f9042603          	lw	a2,-112(s0)
    8000619a:	00a60713          	addi	a4,a2,10
    8000619e:	0712                	slli	a4,a4,0x4
    800061a0:	0001c517          	auipc	a0,0x1c
    800061a4:	ca850513          	addi	a0,a0,-856 # 80021e48 <disk+0x8>
    800061a8:	953a                	add	a0,a0,a4
  if(write)
    800061aa:	e60d14e3          	bnez	s10,80006012 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061ae:	00a60793          	addi	a5,a2,10
    800061b2:	00479693          	slli	a3,a5,0x4
    800061b6:	0001c797          	auipc	a5,0x1c
    800061ba:	c8a78793          	addi	a5,a5,-886 # 80021e40 <disk>
    800061be:	97b6                	add	a5,a5,a3
    800061c0:	0007a423          	sw	zero,8(a5)
    800061c4:	b595                	j	80006028 <virtio_disk_rw+0xf0>

00000000800061c6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061c6:	1101                	addi	sp,sp,-32
    800061c8:	ec06                	sd	ra,24(sp)
    800061ca:	e822                	sd	s0,16(sp)
    800061cc:	e426                	sd	s1,8(sp)
    800061ce:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061d0:	0001c497          	auipc	s1,0x1c
    800061d4:	c7048493          	addi	s1,s1,-912 # 80021e40 <disk>
    800061d8:	0001c517          	auipc	a0,0x1c
    800061dc:	d9050513          	addi	a0,a0,-624 # 80021f68 <disk+0x128>
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	a0a080e7          	jalr	-1526(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e8:	10001737          	lui	a4,0x10001
    800061ec:	533c                	lw	a5,96(a4)
    800061ee:	8b8d                	andi	a5,a5,3
    800061f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061f6:	689c                	ld	a5,16(s1)
    800061f8:	0204d703          	lhu	a4,32(s1)
    800061fc:	0027d783          	lhu	a5,2(a5)
    80006200:	04f70863          	beq	a4,a5,80006250 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006204:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006208:	6898                	ld	a4,16(s1)
    8000620a:	0204d783          	lhu	a5,32(s1)
    8000620e:	8b9d                	andi	a5,a5,7
    80006210:	078e                	slli	a5,a5,0x3
    80006212:	97ba                	add	a5,a5,a4
    80006214:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006216:	00278713          	addi	a4,a5,2
    8000621a:	0712                	slli	a4,a4,0x4
    8000621c:	9726                	add	a4,a4,s1
    8000621e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006222:	e721                	bnez	a4,8000626a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006224:	0789                	addi	a5,a5,2
    80006226:	0792                	slli	a5,a5,0x4
    80006228:	97a6                	add	a5,a5,s1
    8000622a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000622c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006230:	ffffc097          	auipc	ra,0xffffc
    80006234:	eaa080e7          	jalr	-342(ra) # 800020da <wakeup>

    disk.used_idx += 1;
    80006238:	0204d783          	lhu	a5,32(s1)
    8000623c:	2785                	addiw	a5,a5,1
    8000623e:	17c2                	slli	a5,a5,0x30
    80006240:	93c1                	srli	a5,a5,0x30
    80006242:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006246:	6898                	ld	a4,16(s1)
    80006248:	00275703          	lhu	a4,2(a4)
    8000624c:	faf71ce3          	bne	a4,a5,80006204 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006250:	0001c517          	auipc	a0,0x1c
    80006254:	d1850513          	addi	a0,a0,-744 # 80021f68 <disk+0x128>
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	a46080e7          	jalr	-1466(ra) # 80000c9e <release>
}
    80006260:	60e2                	ld	ra,24(sp)
    80006262:	6442                	ld	s0,16(sp)
    80006264:	64a2                	ld	s1,8(sp)
    80006266:	6105                	addi	sp,sp,32
    80006268:	8082                	ret
      panic("virtio_disk_intr status");
    8000626a:	00002517          	auipc	a0,0x2
    8000626e:	5de50513          	addi	a0,a0,1502 # 80008848 <syscalls+0x3e0>
    80006272:	ffffa097          	auipc	ra,0xffffa
    80006276:	2d2080e7          	jalr	722(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
