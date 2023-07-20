
user/_prime:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <prime>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int prime(int num)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
    int i;
    if(num == 2) return 1;
   6:	ffe5069b          	addiw	a3,a0,-2
   a:	4705                	li	a4,1
   c:	02d77a63          	bgeu	a4,a3,40 <prime+0x40>
  10:	0005079b          	sext.w	a5,a0
    if(num == 3) return 1;
    for(i = 2;i<num;i++)
  14:	4709                	li	a4,2
  16:	02a75163          	bge	a4,a0,38 <prime+0x38>
    {
        if(num %i == 0) break;
  1a:	8b85                	andi	a5,a5,1
  1c:	c385                	beqz	a5,3c <prime+0x3c>
    for(i = 2;i<num;i++)
  1e:	478d                	li	a5,3
        if(num %i == 0) break;
  20:	02f5673b          	remw	a4,a0,a5
  24:	c701                	beqz	a4,2c <prime+0x2c>
    for(i = 2;i<num;i++)
  26:	2785                	addiw	a5,a5,1
  28:	fea7cce3          	blt	a5,a0,20 <prime+0x20>
    }
    if(i == num) return(1);
  2c:	8d1d                	sub	a0,a0,a5
    if(num == 2) return 1;
  2e:	00153513          	seqz	a0,a0
    return(0);
}
  32:	6422                	ld	s0,8(sp)
  34:	0141                	addi	sp,sp,16
  36:	8082                	ret
    for(i = 2;i<num;i++)
  38:	4789                	li	a5,2
  3a:	bfcd                	j	2c <prime+0x2c>
  3c:	4789                	li	a5,2
  3e:	b7fd                	j	2c <prime+0x2c>
    if(num == 2) return 1;
  40:	4505                	li	a0,1
  42:	bfc5                	j	32 <prime+0x32>

0000000000000044 <main>:

void main(int args, char* argv[])
{
  44:	7139                	addi	sp,sp,-64
  46:	fc06                	sd	ra,56(sp)
  48:	f822                	sd	s0,48(sp)
  4a:	f426                	sd	s1,40(sp)
  4c:	f04a                	sd	s2,32(sp)
  4e:	ec4e                	sd	s3,24(sp)
  50:	e852                	sd	s4,16(sp)
  52:	0080                	addi	s0,sp,64
    int p[2];
    int num;
    int pid;

    if(pipe(p)<0)
  54:	fc840513          	addi	a0,s0,-56
  58:	00000097          	auipc	ra,0x0
  5c:	388080e7          	jalr	904(ra) # 3e0 <pipe>
  60:	0a054763          	bltz	a0,10e <main+0xca>
    {
        fprintf(2,"error:unable to build pipes \n");
    }

    for(int i = 2;i <= 35;i ++)
  64:	4789                	li	a5,2
  66:	fcf42023          	sw	a5,-64(s0)
  6a:	02300493          	li	s1,35
    {
        write(p[1],&i,sizeof(i));
  6e:	4611                	li	a2,4
  70:	fc040593          	addi	a1,s0,-64
  74:	fcc42503          	lw	a0,-52(s0)
  78:	00000097          	auipc	ra,0x0
  7c:	378080e7          	jalr	888(ra) # 3f0 <write>
    for(int i = 2;i <= 35;i ++)
  80:	fc042783          	lw	a5,-64(s0)
  84:	2785                	addiw	a5,a5,1
  86:	0007871b          	sext.w	a4,a5
  8a:	fcf42023          	sw	a5,-64(s0)
  8e:	fee4d0e3          	bge	s1,a4,6e <main+0x2a>
    }

    pid = fork();
  92:	00000097          	auipc	ra,0x0
  96:	336080e7          	jalr	822(ra) # 3c8 <fork>

    while (1)
    {
        if(pid > 0)
  9a:	08a04463          	bgtz	a0,122 <main+0xde>
        {
            wait((int*)0);
            exit(0);
        }
        else if (pid == 0)
  9e:	e931                	bnez	a0,f2 <main+0xae>
        {
            while(1)
            {
                read(p[0],&num,sizeof(num));
                if(num == 35)
  a0:	02300913          	li	s2,35
                {
                   exit(0);
                }
                if(prime(num)==1)
  a4:	4985                	li	s3,1
                {
                    fprintf(1,"prime %d \n",num);
  a6:	00001a17          	auipc	s4,0x1
  aa:	87aa0a13          	addi	s4,s4,-1926 # 920 <malloc+0x112>
                read(p[0],&num,sizeof(num));
  ae:	4611                	li	a2,4
  b0:	fc440593          	addi	a1,s0,-60
  b4:	fc842503          	lw	a0,-56(s0)
  b8:	00000097          	auipc	ra,0x0
  bc:	330080e7          	jalr	816(ra) # 3e8 <read>
                if(num == 35)
  c0:	fc442483          	lw	s1,-60(s0)
  c4:	07248963          	beq	s1,s2,136 <main+0xf2>
                if(prime(num)==1)
  c8:	8526                	mv	a0,s1
  ca:	00000097          	auipc	ra,0x0
  ce:	f36080e7          	jalr	-202(ra) # 0 <prime>
  d2:	fd351ee3          	bne	a0,s3,ae <main+0x6a>
                    fprintf(1,"prime %d \n",num);
  d6:	8626                	mv	a2,s1
  d8:	85d2                	mv	a1,s4
  da:	854e                	mv	a0,s3
  dc:	00000097          	auipc	ra,0x0
  e0:	646080e7          	jalr	1606(ra) # 722 <fprintf>
                    pid = fork();
  e4:	00000097          	auipc	ra,0x0
  e8:	2e4080e7          	jalr	740(ra) # 3c8 <fork>
        if(pid > 0)
  ec:	02a04b63          	bgtz	a0,122 <main+0xde>
        else if (pid == 0)
  f0:	dd5d                	beqz	a0,ae <main+0x6a>
            }


        }
        else{
            fprintf(2,"error:fork failed \n");
  f2:	00001597          	auipc	a1,0x1
  f6:	83e58593          	addi	a1,a1,-1986 # 930 <malloc+0x122>
  fa:	4509                	li	a0,2
  fc:	00000097          	auipc	ra,0x0
 100:	626080e7          	jalr	1574(ra) # 722 <fprintf>
            exit(1);
 104:	4505                	li	a0,1
 106:	00000097          	auipc	ra,0x0
 10a:	2ca080e7          	jalr	714(ra) # 3d0 <exit>
        fprintf(2,"error:unable to build pipes \n");
 10e:	00000597          	auipc	a1,0x0
 112:	7f258593          	addi	a1,a1,2034 # 900 <malloc+0xf2>
 116:	4509                	li	a0,2
 118:	00000097          	auipc	ra,0x0
 11c:	60a080e7          	jalr	1546(ra) # 722 <fprintf>
 120:	b791                	j	64 <main+0x20>
            wait((int*)0);
 122:	4501                	li	a0,0
 124:	00000097          	auipc	ra,0x0
 128:	2b4080e7          	jalr	692(ra) # 3d8 <wait>
            exit(0);
 12c:	4501                	li	a0,0
 12e:	00000097          	auipc	ra,0x0
 132:	2a2080e7          	jalr	674(ra) # 3d0 <exit>
                   exit(0);
 136:	4501                	li	a0,0
 138:	00000097          	auipc	ra,0x0
 13c:	298080e7          	jalr	664(ra) # 3d0 <exit>

0000000000000140 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 140:	1141                	addi	sp,sp,-16
 142:	e406                	sd	ra,8(sp)
 144:	e022                	sd	s0,0(sp)
 146:	0800                	addi	s0,sp,16
  extern int main();
  main();
 148:	00000097          	auipc	ra,0x0
 14c:	efc080e7          	jalr	-260(ra) # 44 <main>
  exit(0);
 150:	4501                	li	a0,0
 152:	00000097          	auipc	ra,0x0
 156:	27e080e7          	jalr	638(ra) # 3d0 <exit>

000000000000015a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 15a:	1141                	addi	sp,sp,-16
 15c:	e422                	sd	s0,8(sp)
 15e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 160:	87aa                	mv	a5,a0
 162:	0585                	addi	a1,a1,1
 164:	0785                	addi	a5,a5,1
 166:	fff5c703          	lbu	a4,-1(a1)
 16a:	fee78fa3          	sb	a4,-1(a5)
 16e:	fb75                	bnez	a4,162 <strcpy+0x8>
    ;
  return os;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	addi	sp,sp,16
 174:	8082                	ret

0000000000000176 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 176:	1141                	addi	sp,sp,-16
 178:	e422                	sd	s0,8(sp)
 17a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 17c:	00054783          	lbu	a5,0(a0)
 180:	cb91                	beqz	a5,194 <strcmp+0x1e>
 182:	0005c703          	lbu	a4,0(a1)
 186:	00f71763          	bne	a4,a5,194 <strcmp+0x1e>
    p++, q++;
 18a:	0505                	addi	a0,a0,1
 18c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 18e:	00054783          	lbu	a5,0(a0)
 192:	fbe5                	bnez	a5,182 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 194:	0005c503          	lbu	a0,0(a1)
}
 198:	40a7853b          	subw	a0,a5,a0
 19c:	6422                	ld	s0,8(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret

00000000000001a2 <strlen>:

uint
strlen(const char *s)
{
 1a2:	1141                	addi	sp,sp,-16
 1a4:	e422                	sd	s0,8(sp)
 1a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1a8:	00054783          	lbu	a5,0(a0)
 1ac:	cf91                	beqz	a5,1c8 <strlen+0x26>
 1ae:	0505                	addi	a0,a0,1
 1b0:	87aa                	mv	a5,a0
 1b2:	4685                	li	a3,1
 1b4:	9e89                	subw	a3,a3,a0
 1b6:	00f6853b          	addw	a0,a3,a5
 1ba:	0785                	addi	a5,a5,1
 1bc:	fff7c703          	lbu	a4,-1(a5)
 1c0:	fb7d                	bnez	a4,1b6 <strlen+0x14>
    ;
  return n;
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret
  for(n = 0; s[n]; n++)
 1c8:	4501                	li	a0,0
 1ca:	bfe5                	j	1c2 <strlen+0x20>

00000000000001cc <memset>:

void*
memset(void *dst, int c, uint n)
{
 1cc:	1141                	addi	sp,sp,-16
 1ce:	e422                	sd	s0,8(sp)
 1d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1d2:	ce09                	beqz	a2,1ec <memset+0x20>
 1d4:	87aa                	mv	a5,a0
 1d6:	fff6071b          	addiw	a4,a2,-1
 1da:	1702                	slli	a4,a4,0x20
 1dc:	9301                	srli	a4,a4,0x20
 1de:	0705                	addi	a4,a4,1
 1e0:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1e2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1e6:	0785                	addi	a5,a5,1
 1e8:	fee79de3          	bne	a5,a4,1e2 <memset+0x16>
  }
  return dst;
}
 1ec:	6422                	ld	s0,8(sp)
 1ee:	0141                	addi	sp,sp,16
 1f0:	8082                	ret

00000000000001f2 <strchr>:

char*
strchr(const char *s, char c)
{
 1f2:	1141                	addi	sp,sp,-16
 1f4:	e422                	sd	s0,8(sp)
 1f6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1f8:	00054783          	lbu	a5,0(a0)
 1fc:	cb99                	beqz	a5,212 <strchr+0x20>
    if(*s == c)
 1fe:	00f58763          	beq	a1,a5,20c <strchr+0x1a>
  for(; *s; s++)
 202:	0505                	addi	a0,a0,1
 204:	00054783          	lbu	a5,0(a0)
 208:	fbfd                	bnez	a5,1fe <strchr+0xc>
      return (char*)s;
  return 0;
 20a:	4501                	li	a0,0
}
 20c:	6422                	ld	s0,8(sp)
 20e:	0141                	addi	sp,sp,16
 210:	8082                	ret
  return 0;
 212:	4501                	li	a0,0
 214:	bfe5                	j	20c <strchr+0x1a>

0000000000000216 <gets>:

char*
gets(char *buf, int max)
{
 216:	711d                	addi	sp,sp,-96
 218:	ec86                	sd	ra,88(sp)
 21a:	e8a2                	sd	s0,80(sp)
 21c:	e4a6                	sd	s1,72(sp)
 21e:	e0ca                	sd	s2,64(sp)
 220:	fc4e                	sd	s3,56(sp)
 222:	f852                	sd	s4,48(sp)
 224:	f456                	sd	s5,40(sp)
 226:	f05a                	sd	s6,32(sp)
 228:	ec5e                	sd	s7,24(sp)
 22a:	1080                	addi	s0,sp,96
 22c:	8baa                	mv	s7,a0
 22e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 230:	892a                	mv	s2,a0
 232:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 234:	4aa9                	li	s5,10
 236:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 238:	89a6                	mv	s3,s1
 23a:	2485                	addiw	s1,s1,1
 23c:	0344d863          	bge	s1,s4,26c <gets+0x56>
    cc = read(0, &c, 1);
 240:	4605                	li	a2,1
 242:	faf40593          	addi	a1,s0,-81
 246:	4501                	li	a0,0
 248:	00000097          	auipc	ra,0x0
 24c:	1a0080e7          	jalr	416(ra) # 3e8 <read>
    if(cc < 1)
 250:	00a05e63          	blez	a0,26c <gets+0x56>
    buf[i++] = c;
 254:	faf44783          	lbu	a5,-81(s0)
 258:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 25c:	01578763          	beq	a5,s5,26a <gets+0x54>
 260:	0905                	addi	s2,s2,1
 262:	fd679be3          	bne	a5,s6,238 <gets+0x22>
  for(i=0; i+1 < max; ){
 266:	89a6                	mv	s3,s1
 268:	a011                	j	26c <gets+0x56>
 26a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 26c:	99de                	add	s3,s3,s7
 26e:	00098023          	sb	zero,0(s3)
  return buf;
}
 272:	855e                	mv	a0,s7
 274:	60e6                	ld	ra,88(sp)
 276:	6446                	ld	s0,80(sp)
 278:	64a6                	ld	s1,72(sp)
 27a:	6906                	ld	s2,64(sp)
 27c:	79e2                	ld	s3,56(sp)
 27e:	7a42                	ld	s4,48(sp)
 280:	7aa2                	ld	s5,40(sp)
 282:	7b02                	ld	s6,32(sp)
 284:	6be2                	ld	s7,24(sp)
 286:	6125                	addi	sp,sp,96
 288:	8082                	ret

000000000000028a <stat>:

int
stat(const char *n, struct stat *st)
{
 28a:	1101                	addi	sp,sp,-32
 28c:	ec06                	sd	ra,24(sp)
 28e:	e822                	sd	s0,16(sp)
 290:	e426                	sd	s1,8(sp)
 292:	e04a                	sd	s2,0(sp)
 294:	1000                	addi	s0,sp,32
 296:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 298:	4581                	li	a1,0
 29a:	00000097          	auipc	ra,0x0
 29e:	176080e7          	jalr	374(ra) # 410 <open>
  if(fd < 0)
 2a2:	02054563          	bltz	a0,2cc <stat+0x42>
 2a6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2a8:	85ca                	mv	a1,s2
 2aa:	00000097          	auipc	ra,0x0
 2ae:	17e080e7          	jalr	382(ra) # 428 <fstat>
 2b2:	892a                	mv	s2,a0
  close(fd);
 2b4:	8526                	mv	a0,s1
 2b6:	00000097          	auipc	ra,0x0
 2ba:	142080e7          	jalr	322(ra) # 3f8 <close>
  return r;
}
 2be:	854a                	mv	a0,s2
 2c0:	60e2                	ld	ra,24(sp)
 2c2:	6442                	ld	s0,16(sp)
 2c4:	64a2                	ld	s1,8(sp)
 2c6:	6902                	ld	s2,0(sp)
 2c8:	6105                	addi	sp,sp,32
 2ca:	8082                	ret
    return -1;
 2cc:	597d                	li	s2,-1
 2ce:	bfc5                	j	2be <stat+0x34>

00000000000002d0 <atoi>:

int
atoi(const char *s)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2d6:	00054603          	lbu	a2,0(a0)
 2da:	fd06079b          	addiw	a5,a2,-48
 2de:	0ff7f793          	andi	a5,a5,255
 2e2:	4725                	li	a4,9
 2e4:	02f76963          	bltu	a4,a5,316 <atoi+0x46>
 2e8:	86aa                	mv	a3,a0
  n = 0;
 2ea:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2ec:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2ee:	0685                	addi	a3,a3,1
 2f0:	0025179b          	slliw	a5,a0,0x2
 2f4:	9fa9                	addw	a5,a5,a0
 2f6:	0017979b          	slliw	a5,a5,0x1
 2fa:	9fb1                	addw	a5,a5,a2
 2fc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 300:	0006c603          	lbu	a2,0(a3)
 304:	fd06071b          	addiw	a4,a2,-48
 308:	0ff77713          	andi	a4,a4,255
 30c:	fee5f1e3          	bgeu	a1,a4,2ee <atoi+0x1e>
  return n;
}
 310:	6422                	ld	s0,8(sp)
 312:	0141                	addi	sp,sp,16
 314:	8082                	ret
  n = 0;
 316:	4501                	li	a0,0
 318:	bfe5                	j	310 <atoi+0x40>

000000000000031a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 31a:	1141                	addi	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 320:	02b57663          	bgeu	a0,a1,34c <memmove+0x32>
    while(n-- > 0)
 324:	02c05163          	blez	a2,346 <memmove+0x2c>
 328:	fff6079b          	addiw	a5,a2,-1
 32c:	1782                	slli	a5,a5,0x20
 32e:	9381                	srli	a5,a5,0x20
 330:	0785                	addi	a5,a5,1
 332:	97aa                	add	a5,a5,a0
  dst = vdst;
 334:	872a                	mv	a4,a0
      *dst++ = *src++;
 336:	0585                	addi	a1,a1,1
 338:	0705                	addi	a4,a4,1
 33a:	fff5c683          	lbu	a3,-1(a1)
 33e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 342:	fee79ae3          	bne	a5,a4,336 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 346:	6422                	ld	s0,8(sp)
 348:	0141                	addi	sp,sp,16
 34a:	8082                	ret
    dst += n;
 34c:	00c50733          	add	a4,a0,a2
    src += n;
 350:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 352:	fec05ae3          	blez	a2,346 <memmove+0x2c>
 356:	fff6079b          	addiw	a5,a2,-1
 35a:	1782                	slli	a5,a5,0x20
 35c:	9381                	srli	a5,a5,0x20
 35e:	fff7c793          	not	a5,a5
 362:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 364:	15fd                	addi	a1,a1,-1
 366:	177d                	addi	a4,a4,-1
 368:	0005c683          	lbu	a3,0(a1)
 36c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 370:	fee79ae3          	bne	a5,a4,364 <memmove+0x4a>
 374:	bfc9                	j	346 <memmove+0x2c>

0000000000000376 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 376:	1141                	addi	sp,sp,-16
 378:	e422                	sd	s0,8(sp)
 37a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 37c:	ca05                	beqz	a2,3ac <memcmp+0x36>
 37e:	fff6069b          	addiw	a3,a2,-1
 382:	1682                	slli	a3,a3,0x20
 384:	9281                	srli	a3,a3,0x20
 386:	0685                	addi	a3,a3,1
 388:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 38a:	00054783          	lbu	a5,0(a0)
 38e:	0005c703          	lbu	a4,0(a1)
 392:	00e79863          	bne	a5,a4,3a2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 396:	0505                	addi	a0,a0,1
    p2++;
 398:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 39a:	fed518e3          	bne	a0,a3,38a <memcmp+0x14>
  }
  return 0;
 39e:	4501                	li	a0,0
 3a0:	a019                	j	3a6 <memcmp+0x30>
      return *p1 - *p2;
 3a2:	40e7853b          	subw	a0,a5,a4
}
 3a6:	6422                	ld	s0,8(sp)
 3a8:	0141                	addi	sp,sp,16
 3aa:	8082                	ret
  return 0;
 3ac:	4501                	li	a0,0
 3ae:	bfe5                	j	3a6 <memcmp+0x30>

00000000000003b0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3b0:	1141                	addi	sp,sp,-16
 3b2:	e406                	sd	ra,8(sp)
 3b4:	e022                	sd	s0,0(sp)
 3b6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3b8:	00000097          	auipc	ra,0x0
 3bc:	f62080e7          	jalr	-158(ra) # 31a <memmove>
}
 3c0:	60a2                	ld	ra,8(sp)
 3c2:	6402                	ld	s0,0(sp)
 3c4:	0141                	addi	sp,sp,16
 3c6:	8082                	ret

00000000000003c8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3c8:	4885                	li	a7,1
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3d0:	4889                	li	a7,2
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3d8:	488d                	li	a7,3
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3e0:	4891                	li	a7,4
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <read>:
.global read
read:
 li a7, SYS_read
 3e8:	4895                	li	a7,5
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <write>:
.global write
write:
 li a7, SYS_write
 3f0:	48c1                	li	a7,16
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <close>:
.global close
close:
 li a7, SYS_close
 3f8:	48d5                	li	a7,21
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <kill>:
.global kill
kill:
 li a7, SYS_kill
 400:	4899                	li	a7,6
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <exec>:
.global exec
exec:
 li a7, SYS_exec
 408:	489d                	li	a7,7
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <open>:
.global open
open:
 li a7, SYS_open
 410:	48bd                	li	a7,15
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 418:	48c5                	li	a7,17
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 420:	48c9                	li	a7,18
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 428:	48a1                	li	a7,8
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <link>:
.global link
link:
 li a7, SYS_link
 430:	48cd                	li	a7,19
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 438:	48d1                	li	a7,20
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 440:	48a5                	li	a7,9
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <dup>:
.global dup
dup:
 li a7, SYS_dup
 448:	48a9                	li	a7,10
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 450:	48ad                	li	a7,11
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 458:	48b1                	li	a7,12
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 460:	48b5                	li	a7,13
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 468:	48b9                	li	a7,14
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <trace>:
.global trace
trace:
 li a7, SYS_trace
 470:	48d9                	li	a7,22
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 478:	1101                	addi	sp,sp,-32
 47a:	ec06                	sd	ra,24(sp)
 47c:	e822                	sd	s0,16(sp)
 47e:	1000                	addi	s0,sp,32
 480:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 484:	4605                	li	a2,1
 486:	fef40593          	addi	a1,s0,-17
 48a:	00000097          	auipc	ra,0x0
 48e:	f66080e7          	jalr	-154(ra) # 3f0 <write>
}
 492:	60e2                	ld	ra,24(sp)
 494:	6442                	ld	s0,16(sp)
 496:	6105                	addi	sp,sp,32
 498:	8082                	ret

000000000000049a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 49a:	7139                	addi	sp,sp,-64
 49c:	fc06                	sd	ra,56(sp)
 49e:	f822                	sd	s0,48(sp)
 4a0:	f426                	sd	s1,40(sp)
 4a2:	f04a                	sd	s2,32(sp)
 4a4:	ec4e                	sd	s3,24(sp)
 4a6:	0080                	addi	s0,sp,64
 4a8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4aa:	c299                	beqz	a3,4b0 <printint+0x16>
 4ac:	0805c863          	bltz	a1,53c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4b0:	2581                	sext.w	a1,a1
  neg = 0;
 4b2:	4881                	li	a7,0
 4b4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4b8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4ba:	2601                	sext.w	a2,a2
 4bc:	00000517          	auipc	a0,0x0
 4c0:	49450513          	addi	a0,a0,1172 # 950 <digits>
 4c4:	883a                	mv	a6,a4
 4c6:	2705                	addiw	a4,a4,1
 4c8:	02c5f7bb          	remuw	a5,a1,a2
 4cc:	1782                	slli	a5,a5,0x20
 4ce:	9381                	srli	a5,a5,0x20
 4d0:	97aa                	add	a5,a5,a0
 4d2:	0007c783          	lbu	a5,0(a5)
 4d6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4da:	0005879b          	sext.w	a5,a1
 4de:	02c5d5bb          	divuw	a1,a1,a2
 4e2:	0685                	addi	a3,a3,1
 4e4:	fec7f0e3          	bgeu	a5,a2,4c4 <printint+0x2a>
  if(neg)
 4e8:	00088b63          	beqz	a7,4fe <printint+0x64>
    buf[i++] = '-';
 4ec:	fd040793          	addi	a5,s0,-48
 4f0:	973e                	add	a4,a4,a5
 4f2:	02d00793          	li	a5,45
 4f6:	fef70823          	sb	a5,-16(a4)
 4fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4fe:	02e05863          	blez	a4,52e <printint+0x94>
 502:	fc040793          	addi	a5,s0,-64
 506:	00e78933          	add	s2,a5,a4
 50a:	fff78993          	addi	s3,a5,-1
 50e:	99ba                	add	s3,s3,a4
 510:	377d                	addiw	a4,a4,-1
 512:	1702                	slli	a4,a4,0x20
 514:	9301                	srli	a4,a4,0x20
 516:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 51a:	fff94583          	lbu	a1,-1(s2)
 51e:	8526                	mv	a0,s1
 520:	00000097          	auipc	ra,0x0
 524:	f58080e7          	jalr	-168(ra) # 478 <putc>
  while(--i >= 0)
 528:	197d                	addi	s2,s2,-1
 52a:	ff3918e3          	bne	s2,s3,51a <printint+0x80>
}
 52e:	70e2                	ld	ra,56(sp)
 530:	7442                	ld	s0,48(sp)
 532:	74a2                	ld	s1,40(sp)
 534:	7902                	ld	s2,32(sp)
 536:	69e2                	ld	s3,24(sp)
 538:	6121                	addi	sp,sp,64
 53a:	8082                	ret
    x = -xx;
 53c:	40b005bb          	negw	a1,a1
    neg = 1;
 540:	4885                	li	a7,1
    x = -xx;
 542:	bf8d                	j	4b4 <printint+0x1a>

0000000000000544 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 544:	7119                	addi	sp,sp,-128
 546:	fc86                	sd	ra,120(sp)
 548:	f8a2                	sd	s0,112(sp)
 54a:	f4a6                	sd	s1,104(sp)
 54c:	f0ca                	sd	s2,96(sp)
 54e:	ecce                	sd	s3,88(sp)
 550:	e8d2                	sd	s4,80(sp)
 552:	e4d6                	sd	s5,72(sp)
 554:	e0da                	sd	s6,64(sp)
 556:	fc5e                	sd	s7,56(sp)
 558:	f862                	sd	s8,48(sp)
 55a:	f466                	sd	s9,40(sp)
 55c:	f06a                	sd	s10,32(sp)
 55e:	ec6e                	sd	s11,24(sp)
 560:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 562:	0005c903          	lbu	s2,0(a1)
 566:	18090f63          	beqz	s2,704 <vprintf+0x1c0>
 56a:	8aaa                	mv	s5,a0
 56c:	8b32                	mv	s6,a2
 56e:	00158493          	addi	s1,a1,1
  state = 0;
 572:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 574:	02500a13          	li	s4,37
      if(c == 'd'){
 578:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 57c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 580:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 584:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 588:	00000b97          	auipc	s7,0x0
 58c:	3c8b8b93          	addi	s7,s7,968 # 950 <digits>
 590:	a839                	j	5ae <vprintf+0x6a>
        putc(fd, c);
 592:	85ca                	mv	a1,s2
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	ee2080e7          	jalr	-286(ra) # 478 <putc>
 59e:	a019                	j	5a4 <vprintf+0x60>
    } else if(state == '%'){
 5a0:	01498f63          	beq	s3,s4,5be <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5a4:	0485                	addi	s1,s1,1
 5a6:	fff4c903          	lbu	s2,-1(s1)
 5aa:	14090d63          	beqz	s2,704 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5ae:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5b2:	fe0997e3          	bnez	s3,5a0 <vprintf+0x5c>
      if(c == '%'){
 5b6:	fd479ee3          	bne	a5,s4,592 <vprintf+0x4e>
        state = '%';
 5ba:	89be                	mv	s3,a5
 5bc:	b7e5                	j	5a4 <vprintf+0x60>
      if(c == 'd'){
 5be:	05878063          	beq	a5,s8,5fe <vprintf+0xba>
      } else if(c == 'l') {
 5c2:	05978c63          	beq	a5,s9,61a <vprintf+0xd6>
      } else if(c == 'x') {
 5c6:	07a78863          	beq	a5,s10,636 <vprintf+0xf2>
      } else if(c == 'p') {
 5ca:	09b78463          	beq	a5,s11,652 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5ce:	07300713          	li	a4,115
 5d2:	0ce78663          	beq	a5,a4,69e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5d6:	06300713          	li	a4,99
 5da:	0ee78e63          	beq	a5,a4,6d6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5de:	11478863          	beq	a5,s4,6ee <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5e2:	85d2                	mv	a1,s4
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	e92080e7          	jalr	-366(ra) # 478 <putc>
        putc(fd, c);
 5ee:	85ca                	mv	a1,s2
 5f0:	8556                	mv	a0,s5
 5f2:	00000097          	auipc	ra,0x0
 5f6:	e86080e7          	jalr	-378(ra) # 478 <putc>
      }
      state = 0;
 5fa:	4981                	li	s3,0
 5fc:	b765                	j	5a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5fe:	008b0913          	addi	s2,s6,8
 602:	4685                	li	a3,1
 604:	4629                	li	a2,10
 606:	000b2583          	lw	a1,0(s6)
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	e8e080e7          	jalr	-370(ra) # 49a <printint>
 614:	8b4a                	mv	s6,s2
      state = 0;
 616:	4981                	li	s3,0
 618:	b771                	j	5a4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 61a:	008b0913          	addi	s2,s6,8
 61e:	4681                	li	a3,0
 620:	4629                	li	a2,10
 622:	000b2583          	lw	a1,0(s6)
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	e72080e7          	jalr	-398(ra) # 49a <printint>
 630:	8b4a                	mv	s6,s2
      state = 0;
 632:	4981                	li	s3,0
 634:	bf85                	j	5a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 636:	008b0913          	addi	s2,s6,8
 63a:	4681                	li	a3,0
 63c:	4641                	li	a2,16
 63e:	000b2583          	lw	a1,0(s6)
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	e56080e7          	jalr	-426(ra) # 49a <printint>
 64c:	8b4a                	mv	s6,s2
      state = 0;
 64e:	4981                	li	s3,0
 650:	bf91                	j	5a4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 652:	008b0793          	addi	a5,s6,8
 656:	f8f43423          	sd	a5,-120(s0)
 65a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 65e:	03000593          	li	a1,48
 662:	8556                	mv	a0,s5
 664:	00000097          	auipc	ra,0x0
 668:	e14080e7          	jalr	-492(ra) # 478 <putc>
  putc(fd, 'x');
 66c:	85ea                	mv	a1,s10
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	e08080e7          	jalr	-504(ra) # 478 <putc>
 678:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 67a:	03c9d793          	srli	a5,s3,0x3c
 67e:	97de                	add	a5,a5,s7
 680:	0007c583          	lbu	a1,0(a5)
 684:	8556                	mv	a0,s5
 686:	00000097          	auipc	ra,0x0
 68a:	df2080e7          	jalr	-526(ra) # 478 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 68e:	0992                	slli	s3,s3,0x4
 690:	397d                	addiw	s2,s2,-1
 692:	fe0914e3          	bnez	s2,67a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 696:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 69a:	4981                	li	s3,0
 69c:	b721                	j	5a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 69e:	008b0993          	addi	s3,s6,8
 6a2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6a6:	02090163          	beqz	s2,6c8 <vprintf+0x184>
        while(*s != 0){
 6aa:	00094583          	lbu	a1,0(s2)
 6ae:	c9a1                	beqz	a1,6fe <vprintf+0x1ba>
          putc(fd, *s);
 6b0:	8556                	mv	a0,s5
 6b2:	00000097          	auipc	ra,0x0
 6b6:	dc6080e7          	jalr	-570(ra) # 478 <putc>
          s++;
 6ba:	0905                	addi	s2,s2,1
        while(*s != 0){
 6bc:	00094583          	lbu	a1,0(s2)
 6c0:	f9e5                	bnez	a1,6b0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6c2:	8b4e                	mv	s6,s3
      state = 0;
 6c4:	4981                	li	s3,0
 6c6:	bdf9                	j	5a4 <vprintf+0x60>
          s = "(null)";
 6c8:	00000917          	auipc	s2,0x0
 6cc:	28090913          	addi	s2,s2,640 # 948 <malloc+0x13a>
        while(*s != 0){
 6d0:	02800593          	li	a1,40
 6d4:	bff1                	j	6b0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6d6:	008b0913          	addi	s2,s6,8
 6da:	000b4583          	lbu	a1,0(s6)
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	d98080e7          	jalr	-616(ra) # 478 <putc>
 6e8:	8b4a                	mv	s6,s2
      state = 0;
 6ea:	4981                	li	s3,0
 6ec:	bd65                	j	5a4 <vprintf+0x60>
        putc(fd, c);
 6ee:	85d2                	mv	a1,s4
 6f0:	8556                	mv	a0,s5
 6f2:	00000097          	auipc	ra,0x0
 6f6:	d86080e7          	jalr	-634(ra) # 478 <putc>
      state = 0;
 6fa:	4981                	li	s3,0
 6fc:	b565                	j	5a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 6fe:	8b4e                	mv	s6,s3
      state = 0;
 700:	4981                	li	s3,0
 702:	b54d                	j	5a4 <vprintf+0x60>
    }
  }
}
 704:	70e6                	ld	ra,120(sp)
 706:	7446                	ld	s0,112(sp)
 708:	74a6                	ld	s1,104(sp)
 70a:	7906                	ld	s2,96(sp)
 70c:	69e6                	ld	s3,88(sp)
 70e:	6a46                	ld	s4,80(sp)
 710:	6aa6                	ld	s5,72(sp)
 712:	6b06                	ld	s6,64(sp)
 714:	7be2                	ld	s7,56(sp)
 716:	7c42                	ld	s8,48(sp)
 718:	7ca2                	ld	s9,40(sp)
 71a:	7d02                	ld	s10,32(sp)
 71c:	6de2                	ld	s11,24(sp)
 71e:	6109                	addi	sp,sp,128
 720:	8082                	ret

0000000000000722 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 722:	715d                	addi	sp,sp,-80
 724:	ec06                	sd	ra,24(sp)
 726:	e822                	sd	s0,16(sp)
 728:	1000                	addi	s0,sp,32
 72a:	e010                	sd	a2,0(s0)
 72c:	e414                	sd	a3,8(s0)
 72e:	e818                	sd	a4,16(s0)
 730:	ec1c                	sd	a5,24(s0)
 732:	03043023          	sd	a6,32(s0)
 736:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 73a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 73e:	8622                	mv	a2,s0
 740:	00000097          	auipc	ra,0x0
 744:	e04080e7          	jalr	-508(ra) # 544 <vprintf>
}
 748:	60e2                	ld	ra,24(sp)
 74a:	6442                	ld	s0,16(sp)
 74c:	6161                	addi	sp,sp,80
 74e:	8082                	ret

0000000000000750 <printf>:

void
printf(const char *fmt, ...)
{
 750:	711d                	addi	sp,sp,-96
 752:	ec06                	sd	ra,24(sp)
 754:	e822                	sd	s0,16(sp)
 756:	1000                	addi	s0,sp,32
 758:	e40c                	sd	a1,8(s0)
 75a:	e810                	sd	a2,16(s0)
 75c:	ec14                	sd	a3,24(s0)
 75e:	f018                	sd	a4,32(s0)
 760:	f41c                	sd	a5,40(s0)
 762:	03043823          	sd	a6,48(s0)
 766:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 76a:	00840613          	addi	a2,s0,8
 76e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 772:	85aa                	mv	a1,a0
 774:	4505                	li	a0,1
 776:	00000097          	auipc	ra,0x0
 77a:	dce080e7          	jalr	-562(ra) # 544 <vprintf>
}
 77e:	60e2                	ld	ra,24(sp)
 780:	6442                	ld	s0,16(sp)
 782:	6125                	addi	sp,sp,96
 784:	8082                	ret

0000000000000786 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 786:	1141                	addi	sp,sp,-16
 788:	e422                	sd	s0,8(sp)
 78a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 78c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 790:	00001797          	auipc	a5,0x1
 794:	8707b783          	ld	a5,-1936(a5) # 1000 <freep>
 798:	a805                	j	7c8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 79a:	4618                	lw	a4,8(a2)
 79c:	9db9                	addw	a1,a1,a4
 79e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7a2:	6398                	ld	a4,0(a5)
 7a4:	6318                	ld	a4,0(a4)
 7a6:	fee53823          	sd	a4,-16(a0)
 7aa:	a091                	j	7ee <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7ac:	ff852703          	lw	a4,-8(a0)
 7b0:	9e39                	addw	a2,a2,a4
 7b2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7b4:	ff053703          	ld	a4,-16(a0)
 7b8:	e398                	sd	a4,0(a5)
 7ba:	a099                	j	800 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7bc:	6398                	ld	a4,0(a5)
 7be:	00e7e463          	bltu	a5,a4,7c6 <free+0x40>
 7c2:	00e6ea63          	bltu	a3,a4,7d6 <free+0x50>
{
 7c6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c8:	fed7fae3          	bgeu	a5,a3,7bc <free+0x36>
 7cc:	6398                	ld	a4,0(a5)
 7ce:	00e6e463          	bltu	a3,a4,7d6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d2:	fee7eae3          	bltu	a5,a4,7c6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7d6:	ff852583          	lw	a1,-8(a0)
 7da:	6390                	ld	a2,0(a5)
 7dc:	02059713          	slli	a4,a1,0x20
 7e0:	9301                	srli	a4,a4,0x20
 7e2:	0712                	slli	a4,a4,0x4
 7e4:	9736                	add	a4,a4,a3
 7e6:	fae60ae3          	beq	a2,a4,79a <free+0x14>
    bp->s.ptr = p->s.ptr;
 7ea:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7ee:	4790                	lw	a2,8(a5)
 7f0:	02061713          	slli	a4,a2,0x20
 7f4:	9301                	srli	a4,a4,0x20
 7f6:	0712                	slli	a4,a4,0x4
 7f8:	973e                	add	a4,a4,a5
 7fa:	fae689e3          	beq	a3,a4,7ac <free+0x26>
  } else
    p->s.ptr = bp;
 7fe:	e394                	sd	a3,0(a5)
  freep = p;
 800:	00001717          	auipc	a4,0x1
 804:	80f73023          	sd	a5,-2048(a4) # 1000 <freep>
}
 808:	6422                	ld	s0,8(sp)
 80a:	0141                	addi	sp,sp,16
 80c:	8082                	ret

000000000000080e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 80e:	7139                	addi	sp,sp,-64
 810:	fc06                	sd	ra,56(sp)
 812:	f822                	sd	s0,48(sp)
 814:	f426                	sd	s1,40(sp)
 816:	f04a                	sd	s2,32(sp)
 818:	ec4e                	sd	s3,24(sp)
 81a:	e852                	sd	s4,16(sp)
 81c:	e456                	sd	s5,8(sp)
 81e:	e05a                	sd	s6,0(sp)
 820:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 822:	02051493          	slli	s1,a0,0x20
 826:	9081                	srli	s1,s1,0x20
 828:	04bd                	addi	s1,s1,15
 82a:	8091                	srli	s1,s1,0x4
 82c:	0014899b          	addiw	s3,s1,1
 830:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 832:	00000517          	auipc	a0,0x0
 836:	7ce53503          	ld	a0,1998(a0) # 1000 <freep>
 83a:	c515                	beqz	a0,866 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 83c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 83e:	4798                	lw	a4,8(a5)
 840:	02977f63          	bgeu	a4,s1,87e <malloc+0x70>
 844:	8a4e                	mv	s4,s3
 846:	0009871b          	sext.w	a4,s3
 84a:	6685                	lui	a3,0x1
 84c:	00d77363          	bgeu	a4,a3,852 <malloc+0x44>
 850:	6a05                	lui	s4,0x1
 852:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 856:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 85a:	00000917          	auipc	s2,0x0
 85e:	7a690913          	addi	s2,s2,1958 # 1000 <freep>
  if(p == (char*)-1)
 862:	5afd                	li	s5,-1
 864:	a88d                	j	8d6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 866:	00000797          	auipc	a5,0x0
 86a:	7aa78793          	addi	a5,a5,1962 # 1010 <base>
 86e:	00000717          	auipc	a4,0x0
 872:	78f73923          	sd	a5,1938(a4) # 1000 <freep>
 876:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 878:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 87c:	b7e1                	j	844 <malloc+0x36>
      if(p->s.size == nunits)
 87e:	02e48b63          	beq	s1,a4,8b4 <malloc+0xa6>
        p->s.size -= nunits;
 882:	4137073b          	subw	a4,a4,s3
 886:	c798                	sw	a4,8(a5)
        p += p->s.size;
 888:	1702                	slli	a4,a4,0x20
 88a:	9301                	srli	a4,a4,0x20
 88c:	0712                	slli	a4,a4,0x4
 88e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 890:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 894:	00000717          	auipc	a4,0x0
 898:	76a73623          	sd	a0,1900(a4) # 1000 <freep>
      return (void*)(p + 1);
 89c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8a0:	70e2                	ld	ra,56(sp)
 8a2:	7442                	ld	s0,48(sp)
 8a4:	74a2                	ld	s1,40(sp)
 8a6:	7902                	ld	s2,32(sp)
 8a8:	69e2                	ld	s3,24(sp)
 8aa:	6a42                	ld	s4,16(sp)
 8ac:	6aa2                	ld	s5,8(sp)
 8ae:	6b02                	ld	s6,0(sp)
 8b0:	6121                	addi	sp,sp,64
 8b2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8b4:	6398                	ld	a4,0(a5)
 8b6:	e118                	sd	a4,0(a0)
 8b8:	bff1                	j	894 <malloc+0x86>
  hp->s.size = nu;
 8ba:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8be:	0541                	addi	a0,a0,16
 8c0:	00000097          	auipc	ra,0x0
 8c4:	ec6080e7          	jalr	-314(ra) # 786 <free>
  return freep;
 8c8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8cc:	d971                	beqz	a0,8a0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ce:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8d0:	4798                	lw	a4,8(a5)
 8d2:	fa9776e3          	bgeu	a4,s1,87e <malloc+0x70>
    if(p == freep)
 8d6:	00093703          	ld	a4,0(s2)
 8da:	853e                	mv	a0,a5
 8dc:	fef719e3          	bne	a4,a5,8ce <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8e0:	8552                	mv	a0,s4
 8e2:	00000097          	auipc	ra,0x0
 8e6:	b76080e7          	jalr	-1162(ra) # 458 <sbrk>
  if(p == (char*)-1)
 8ea:	fd5518e3          	bne	a0,s5,8ba <malloc+0xac>
        return 0;
 8ee:	4501                	li	a0,0
 8f0:	bf45                	j	8a0 <malloc+0x92>
