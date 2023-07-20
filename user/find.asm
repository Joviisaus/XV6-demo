
user/_find:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	31a080e7          	jalr	794(ra) # 32a <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	2ee080e7          	jalr	750(ra) # 32a <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	2cc080e7          	jalr	716(ra) # 32a <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	faa98993          	addi	s3,s3,-86 # 1010 <buf.1108>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	42c080e7          	jalr	1068(ra) # 4a2 <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	2aa080e7          	jalr	682(ra) # 32a <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	29c080e7          	jalr	668(ra) # 32a <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	2ac080e7          	jalr	684(ra) # 354 <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <find>:

void
find(char *path,char *name)
{
  b4:	d9010113          	addi	sp,sp,-624
  b8:	26113423          	sd	ra,616(sp)
  bc:	26813023          	sd	s0,608(sp)
  c0:	24913c23          	sd	s1,600(sp)
  c4:	25213823          	sd	s2,592(sp)
  c8:	25313423          	sd	s3,584(sp)
  cc:	25413023          	sd	s4,576(sp)
  d0:	23513c23          	sd	s5,568(sp)
  d4:	23613823          	sd	s6,560(sp)
  d8:	1c80                	addi	s0,sp,624
  da:	892a                	mv	s2,a0
  dc:	89ae                	mv	s3,a1
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  de:	4581                	li	a1,0
  e0:	00000097          	auipc	ra,0x0
  e4:	4b8080e7          	jalr	1208(ra) # 598 <open>
  e8:	06054a63          	bltz	a0,15c <find+0xa8>
  ec:	84aa                	mv	s1,a0
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  ee:	d9840593          	addi	a1,s0,-616
  f2:	00000097          	auipc	ra,0x0
  f6:	4be080e7          	jalr	1214(ra) # 5b0 <fstat>
  fa:	06054c63          	bltz	a0,172 <find+0xbe>
    fprintf(2, "find: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
  fe:	da041783          	lh	a5,-608(s0)
 102:	0007869b          	sext.w	a3,a5
 106:	4705                	li	a4,1
 108:	0ae68a63          	beq	a3,a4,1bc <find+0x108>
 10c:	37f9                	addiw	a5,a5,-2
 10e:	17c2                	slli	a5,a5,0x30
 110:	93c1                	srli	a5,a5,0x30
 112:	00f76d63          	bltu	a4,a5,12c <find+0x78>
  case T_DEVICE:
  case T_FILE:
    if(strcmp(fmtname(path),name)==0) printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 116:	854a                	mv	a0,s2
 118:	00000097          	auipc	ra,0x0
 11c:	ee8080e7          	jalr	-280(ra) # 0 <fmtname>
 120:	85ce                	mv	a1,s3
 122:	00000097          	auipc	ra,0x0
 126:	1dc080e7          	jalr	476(ra) # 2fe <strcmp>
 12a:	c525                	beqz	a0,192 <find+0xde>
      find(buf,name);
      //printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 12c:	8526                	mv	a0,s1
 12e:	00000097          	auipc	ra,0x0
 132:	452080e7          	jalr	1106(ra) # 580 <close>
}
 136:	26813083          	ld	ra,616(sp)
 13a:	26013403          	ld	s0,608(sp)
 13e:	25813483          	ld	s1,600(sp)
 142:	25013903          	ld	s2,592(sp)
 146:	24813983          	ld	s3,584(sp)
 14a:	24013a03          	ld	s4,576(sp)
 14e:	23813a83          	ld	s5,568(sp)
 152:	23013b03          	ld	s6,560(sp)
 156:	27010113          	addi	sp,sp,624
 15a:	8082                	ret
    fprintf(2, "find: cannot open %s\n", path);
 15c:	864a                	mv	a2,s2
 15e:	00001597          	auipc	a1,0x1
 162:	92258593          	addi	a1,a1,-1758 # a80 <malloc+0xea>
 166:	4509                	li	a0,2
 168:	00000097          	auipc	ra,0x0
 16c:	742080e7          	jalr	1858(ra) # 8aa <fprintf>
    return;
 170:	b7d9                	j	136 <find+0x82>
    fprintf(2, "find: cannot stat %s\n", path);
 172:	864a                	mv	a2,s2
 174:	00001597          	auipc	a1,0x1
 178:	92458593          	addi	a1,a1,-1756 # a98 <malloc+0x102>
 17c:	4509                	li	a0,2
 17e:	00000097          	auipc	ra,0x0
 182:	72c080e7          	jalr	1836(ra) # 8aa <fprintf>
    close(fd);
 186:	8526                	mv	a0,s1
 188:	00000097          	auipc	ra,0x0
 18c:	3f8080e7          	jalr	1016(ra) # 580 <close>
    return;
 190:	b75d                	j	136 <find+0x82>
    if(strcmp(fmtname(path),name)==0) printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
 192:	854a                	mv	a0,s2
 194:	00000097          	auipc	ra,0x0
 198:	e6c080e7          	jalr	-404(ra) # 0 <fmtname>
 19c:	85aa                	mv	a1,a0
 19e:	da843703          	ld	a4,-600(s0)
 1a2:	d9c42683          	lw	a3,-612(s0)
 1a6:	da041603          	lh	a2,-608(s0)
 1aa:	00001517          	auipc	a0,0x1
 1ae:	90650513          	addi	a0,a0,-1786 # ab0 <malloc+0x11a>
 1b2:	00000097          	auipc	ra,0x0
 1b6:	726080e7          	jalr	1830(ra) # 8d8 <printf>
 1ba:	bf8d                	j	12c <find+0x78>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 1bc:	854a                	mv	a0,s2
 1be:	00000097          	auipc	ra,0x0
 1c2:	16c080e7          	jalr	364(ra) # 32a <strlen>
 1c6:	2541                	addiw	a0,a0,16
 1c8:	20000793          	li	a5,512
 1cc:	00a7fb63          	bgeu	a5,a0,1e2 <find+0x12e>
      printf("find: path too long\n");
 1d0:	00001517          	auipc	a0,0x1
 1d4:	8f050513          	addi	a0,a0,-1808 # ac0 <malloc+0x12a>
 1d8:	00000097          	auipc	ra,0x0
 1dc:	700080e7          	jalr	1792(ra) # 8d8 <printf>
      break;
 1e0:	b7b1                	j	12c <find+0x78>
    strcpy(buf, path);
 1e2:	85ca                	mv	a1,s2
 1e4:	dc040513          	addi	a0,s0,-576
 1e8:	00000097          	auipc	ra,0x0
 1ec:	0fa080e7          	jalr	250(ra) # 2e2 <strcpy>
    p = buf+strlen(buf);
 1f0:	dc040513          	addi	a0,s0,-576
 1f4:	00000097          	auipc	ra,0x0
 1f8:	136080e7          	jalr	310(ra) # 32a <strlen>
 1fc:	02051913          	slli	s2,a0,0x20
 200:	02095913          	srli	s2,s2,0x20
 204:	dc040793          	addi	a5,s0,-576
 208:	993e                	add	s2,s2,a5
    *p++ = '/';
 20a:	00190a93          	addi	s5,s2,1
 20e:	02f00793          	li	a5,47
 212:	00f90023          	sb	a5,0(s2)
      if(!strcmp(de.name,".")||!strcmp(de.name,"..")) continue;
 216:	00001a17          	auipc	s4,0x1
 21a:	8c2a0a13          	addi	s4,s4,-1854 # ad8 <malloc+0x142>
 21e:	00001b17          	auipc	s6,0x1
 222:	8c2b0b13          	addi	s6,s6,-1854 # ae0 <malloc+0x14a>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 226:	4641                	li	a2,16
 228:	db040593          	addi	a1,s0,-592
 22c:	8526                	mv	a0,s1
 22e:	00000097          	auipc	ra,0x0
 232:	342080e7          	jalr	834(ra) # 570 <read>
 236:	47c1                	li	a5,16
 238:	eef51ae3          	bne	a0,a5,12c <find+0x78>
      if(de.inum == 0)
 23c:	db045783          	lhu	a5,-592(s0)
 240:	d3fd                	beqz	a5,226 <find+0x172>
      memmove(p, de.name, DIRSIZ);
 242:	4639                	li	a2,14
 244:	db240593          	addi	a1,s0,-590
 248:	8556                	mv	a0,s5
 24a:	00000097          	auipc	ra,0x0
 24e:	258080e7          	jalr	600(ra) # 4a2 <memmove>
      p[DIRSIZ] = 0;
 252:	000907a3          	sb	zero,15(s2)
      if(!strcmp(de.name,".")||!strcmp(de.name,"..")) continue;
 256:	85d2                	mv	a1,s4
 258:	db240513          	addi	a0,s0,-590
 25c:	00000097          	auipc	ra,0x0
 260:	0a2080e7          	jalr	162(ra) # 2fe <strcmp>
 264:	d169                	beqz	a0,226 <find+0x172>
 266:	85da                	mv	a1,s6
 268:	db240513          	addi	a0,s0,-590
 26c:	00000097          	auipc	ra,0x0
 270:	092080e7          	jalr	146(ra) # 2fe <strcmp>
 274:	d94d                	beqz	a0,226 <find+0x172>
      find(buf,name);
 276:	85ce                	mv	a1,s3
 278:	dc040513          	addi	a0,s0,-576
 27c:	00000097          	auipc	ra,0x0
 280:	e38080e7          	jalr	-456(ra) # b4 <find>
 284:	b74d                	j	226 <find+0x172>

0000000000000286 <main>:

int
main(int argc, char *argv[])
{
 286:	1141                	addi	sp,sp,-16
 288:	e406                	sd	ra,8(sp)
 28a:	e022                	sd	s0,0(sp)
 28c:	0800                	addi	s0,sp,16
  if(argc != 3){
 28e:	470d                	li	a4,3
 290:	02e50063          	beq	a0,a4,2b0 <main+0x2a>
    fprintf(2, "usage: find <path> <name>\n");
 294:	00001597          	auipc	a1,0x1
 298:	85458593          	addi	a1,a1,-1964 # ae8 <malloc+0x152>
 29c:	4509                	li	a0,2
 29e:	00000097          	auipc	ra,0x0
 2a2:	60c080e7          	jalr	1548(ra) # 8aa <fprintf>
    exit(1);
 2a6:	4505                	li	a0,1
 2a8:	00000097          	auipc	ra,0x0
 2ac:	2b0080e7          	jalr	688(ra) # 558 <exit>
 2b0:	87ae                	mv	a5,a1
  }
  find(argv[1],argv[2]);
 2b2:	698c                	ld	a1,16(a1)
 2b4:	6788                	ld	a0,8(a5)
 2b6:	00000097          	auipc	ra,0x0
 2ba:	dfe080e7          	jalr	-514(ra) # b4 <find>
  exit(0);
 2be:	4501                	li	a0,0
 2c0:	00000097          	auipc	ra,0x0
 2c4:	298080e7          	jalr	664(ra) # 558 <exit>

00000000000002c8 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 2c8:	1141                	addi	sp,sp,-16
 2ca:	e406                	sd	ra,8(sp)
 2cc:	e022                	sd	s0,0(sp)
 2ce:	0800                	addi	s0,sp,16
  extern int main();
  main();
 2d0:	00000097          	auipc	ra,0x0
 2d4:	fb6080e7          	jalr	-74(ra) # 286 <main>
  exit(0);
 2d8:	4501                	li	a0,0
 2da:	00000097          	auipc	ra,0x0
 2de:	27e080e7          	jalr	638(ra) # 558 <exit>

00000000000002e2 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 2e2:	1141                	addi	sp,sp,-16
 2e4:	e422                	sd	s0,8(sp)
 2e6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2e8:	87aa                	mv	a5,a0
 2ea:	0585                	addi	a1,a1,1
 2ec:	0785                	addi	a5,a5,1
 2ee:	fff5c703          	lbu	a4,-1(a1)
 2f2:	fee78fa3          	sb	a4,-1(a5)
 2f6:	fb75                	bnez	a4,2ea <strcpy+0x8>
    ;
  return os;
}
 2f8:	6422                	ld	s0,8(sp)
 2fa:	0141                	addi	sp,sp,16
 2fc:	8082                	ret

00000000000002fe <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2fe:	1141                	addi	sp,sp,-16
 300:	e422                	sd	s0,8(sp)
 302:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 304:	00054783          	lbu	a5,0(a0)
 308:	cb91                	beqz	a5,31c <strcmp+0x1e>
 30a:	0005c703          	lbu	a4,0(a1)
 30e:	00f71763          	bne	a4,a5,31c <strcmp+0x1e>
    p++, q++;
 312:	0505                	addi	a0,a0,1
 314:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 316:	00054783          	lbu	a5,0(a0)
 31a:	fbe5                	bnez	a5,30a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 31c:	0005c503          	lbu	a0,0(a1)
}
 320:	40a7853b          	subw	a0,a5,a0
 324:	6422                	ld	s0,8(sp)
 326:	0141                	addi	sp,sp,16
 328:	8082                	ret

000000000000032a <strlen>:

uint
strlen(const char *s)
{
 32a:	1141                	addi	sp,sp,-16
 32c:	e422                	sd	s0,8(sp)
 32e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 330:	00054783          	lbu	a5,0(a0)
 334:	cf91                	beqz	a5,350 <strlen+0x26>
 336:	0505                	addi	a0,a0,1
 338:	87aa                	mv	a5,a0
 33a:	4685                	li	a3,1
 33c:	9e89                	subw	a3,a3,a0
 33e:	00f6853b          	addw	a0,a3,a5
 342:	0785                	addi	a5,a5,1
 344:	fff7c703          	lbu	a4,-1(a5)
 348:	fb7d                	bnez	a4,33e <strlen+0x14>
    ;
  return n;
}
 34a:	6422                	ld	s0,8(sp)
 34c:	0141                	addi	sp,sp,16
 34e:	8082                	ret
  for(n = 0; s[n]; n++)
 350:	4501                	li	a0,0
 352:	bfe5                	j	34a <strlen+0x20>

0000000000000354 <memset>:

void*
memset(void *dst, int c, uint n)
{
 354:	1141                	addi	sp,sp,-16
 356:	e422                	sd	s0,8(sp)
 358:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 35a:	ce09                	beqz	a2,374 <memset+0x20>
 35c:	87aa                	mv	a5,a0
 35e:	fff6071b          	addiw	a4,a2,-1
 362:	1702                	slli	a4,a4,0x20
 364:	9301                	srli	a4,a4,0x20
 366:	0705                	addi	a4,a4,1
 368:	972a                	add	a4,a4,a0
    cdst[i] = c;
 36a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 36e:	0785                	addi	a5,a5,1
 370:	fee79de3          	bne	a5,a4,36a <memset+0x16>
  }
  return dst;
}
 374:	6422                	ld	s0,8(sp)
 376:	0141                	addi	sp,sp,16
 378:	8082                	ret

000000000000037a <strchr>:

char*
strchr(const char *s, char c)
{
 37a:	1141                	addi	sp,sp,-16
 37c:	e422                	sd	s0,8(sp)
 37e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 380:	00054783          	lbu	a5,0(a0)
 384:	cb99                	beqz	a5,39a <strchr+0x20>
    if(*s == c)
 386:	00f58763          	beq	a1,a5,394 <strchr+0x1a>
  for(; *s; s++)
 38a:	0505                	addi	a0,a0,1
 38c:	00054783          	lbu	a5,0(a0)
 390:	fbfd                	bnez	a5,386 <strchr+0xc>
      return (char*)s;
  return 0;
 392:	4501                	li	a0,0
}
 394:	6422                	ld	s0,8(sp)
 396:	0141                	addi	sp,sp,16
 398:	8082                	ret
  return 0;
 39a:	4501                	li	a0,0
 39c:	bfe5                	j	394 <strchr+0x1a>

000000000000039e <gets>:

char*
gets(char *buf, int max)
{
 39e:	711d                	addi	sp,sp,-96
 3a0:	ec86                	sd	ra,88(sp)
 3a2:	e8a2                	sd	s0,80(sp)
 3a4:	e4a6                	sd	s1,72(sp)
 3a6:	e0ca                	sd	s2,64(sp)
 3a8:	fc4e                	sd	s3,56(sp)
 3aa:	f852                	sd	s4,48(sp)
 3ac:	f456                	sd	s5,40(sp)
 3ae:	f05a                	sd	s6,32(sp)
 3b0:	ec5e                	sd	s7,24(sp)
 3b2:	1080                	addi	s0,sp,96
 3b4:	8baa                	mv	s7,a0
 3b6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3b8:	892a                	mv	s2,a0
 3ba:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3bc:	4aa9                	li	s5,10
 3be:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3c0:	89a6                	mv	s3,s1
 3c2:	2485                	addiw	s1,s1,1
 3c4:	0344d863          	bge	s1,s4,3f4 <gets+0x56>
    cc = read(0, &c, 1);
 3c8:	4605                	li	a2,1
 3ca:	faf40593          	addi	a1,s0,-81
 3ce:	4501                	li	a0,0
 3d0:	00000097          	auipc	ra,0x0
 3d4:	1a0080e7          	jalr	416(ra) # 570 <read>
    if(cc < 1)
 3d8:	00a05e63          	blez	a0,3f4 <gets+0x56>
    buf[i++] = c;
 3dc:	faf44783          	lbu	a5,-81(s0)
 3e0:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3e4:	01578763          	beq	a5,s5,3f2 <gets+0x54>
 3e8:	0905                	addi	s2,s2,1
 3ea:	fd679be3          	bne	a5,s6,3c0 <gets+0x22>
  for(i=0; i+1 < max; ){
 3ee:	89a6                	mv	s3,s1
 3f0:	a011                	j	3f4 <gets+0x56>
 3f2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3f4:	99de                	add	s3,s3,s7
 3f6:	00098023          	sb	zero,0(s3)
  return buf;
}
 3fa:	855e                	mv	a0,s7
 3fc:	60e6                	ld	ra,88(sp)
 3fe:	6446                	ld	s0,80(sp)
 400:	64a6                	ld	s1,72(sp)
 402:	6906                	ld	s2,64(sp)
 404:	79e2                	ld	s3,56(sp)
 406:	7a42                	ld	s4,48(sp)
 408:	7aa2                	ld	s5,40(sp)
 40a:	7b02                	ld	s6,32(sp)
 40c:	6be2                	ld	s7,24(sp)
 40e:	6125                	addi	sp,sp,96
 410:	8082                	ret

0000000000000412 <stat>:

int
stat(const char *n, struct stat *st)
{
 412:	1101                	addi	sp,sp,-32
 414:	ec06                	sd	ra,24(sp)
 416:	e822                	sd	s0,16(sp)
 418:	e426                	sd	s1,8(sp)
 41a:	e04a                	sd	s2,0(sp)
 41c:	1000                	addi	s0,sp,32
 41e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 420:	4581                	li	a1,0
 422:	00000097          	auipc	ra,0x0
 426:	176080e7          	jalr	374(ra) # 598 <open>
  if(fd < 0)
 42a:	02054563          	bltz	a0,454 <stat+0x42>
 42e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 430:	85ca                	mv	a1,s2
 432:	00000097          	auipc	ra,0x0
 436:	17e080e7          	jalr	382(ra) # 5b0 <fstat>
 43a:	892a                	mv	s2,a0
  close(fd);
 43c:	8526                	mv	a0,s1
 43e:	00000097          	auipc	ra,0x0
 442:	142080e7          	jalr	322(ra) # 580 <close>
  return r;
}
 446:	854a                	mv	a0,s2
 448:	60e2                	ld	ra,24(sp)
 44a:	6442                	ld	s0,16(sp)
 44c:	64a2                	ld	s1,8(sp)
 44e:	6902                	ld	s2,0(sp)
 450:	6105                	addi	sp,sp,32
 452:	8082                	ret
    return -1;
 454:	597d                	li	s2,-1
 456:	bfc5                	j	446 <stat+0x34>

0000000000000458 <atoi>:

int
atoi(const char *s)
{
 458:	1141                	addi	sp,sp,-16
 45a:	e422                	sd	s0,8(sp)
 45c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 45e:	00054603          	lbu	a2,0(a0)
 462:	fd06079b          	addiw	a5,a2,-48
 466:	0ff7f793          	andi	a5,a5,255
 46a:	4725                	li	a4,9
 46c:	02f76963          	bltu	a4,a5,49e <atoi+0x46>
 470:	86aa                	mv	a3,a0
  n = 0;
 472:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 474:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 476:	0685                	addi	a3,a3,1
 478:	0025179b          	slliw	a5,a0,0x2
 47c:	9fa9                	addw	a5,a5,a0
 47e:	0017979b          	slliw	a5,a5,0x1
 482:	9fb1                	addw	a5,a5,a2
 484:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 488:	0006c603          	lbu	a2,0(a3)
 48c:	fd06071b          	addiw	a4,a2,-48
 490:	0ff77713          	andi	a4,a4,255
 494:	fee5f1e3          	bgeu	a1,a4,476 <atoi+0x1e>
  return n;
}
 498:	6422                	ld	s0,8(sp)
 49a:	0141                	addi	sp,sp,16
 49c:	8082                	ret
  n = 0;
 49e:	4501                	li	a0,0
 4a0:	bfe5                	j	498 <atoi+0x40>

00000000000004a2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4a2:	1141                	addi	sp,sp,-16
 4a4:	e422                	sd	s0,8(sp)
 4a6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4a8:	02b57663          	bgeu	a0,a1,4d4 <memmove+0x32>
    while(n-- > 0)
 4ac:	02c05163          	blez	a2,4ce <memmove+0x2c>
 4b0:	fff6079b          	addiw	a5,a2,-1
 4b4:	1782                	slli	a5,a5,0x20
 4b6:	9381                	srli	a5,a5,0x20
 4b8:	0785                	addi	a5,a5,1
 4ba:	97aa                	add	a5,a5,a0
  dst = vdst;
 4bc:	872a                	mv	a4,a0
      *dst++ = *src++;
 4be:	0585                	addi	a1,a1,1
 4c0:	0705                	addi	a4,a4,1
 4c2:	fff5c683          	lbu	a3,-1(a1)
 4c6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4ca:	fee79ae3          	bne	a5,a4,4be <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4ce:	6422                	ld	s0,8(sp)
 4d0:	0141                	addi	sp,sp,16
 4d2:	8082                	ret
    dst += n;
 4d4:	00c50733          	add	a4,a0,a2
    src += n;
 4d8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4da:	fec05ae3          	blez	a2,4ce <memmove+0x2c>
 4de:	fff6079b          	addiw	a5,a2,-1
 4e2:	1782                	slli	a5,a5,0x20
 4e4:	9381                	srli	a5,a5,0x20
 4e6:	fff7c793          	not	a5,a5
 4ea:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4ec:	15fd                	addi	a1,a1,-1
 4ee:	177d                	addi	a4,a4,-1
 4f0:	0005c683          	lbu	a3,0(a1)
 4f4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4f8:	fee79ae3          	bne	a5,a4,4ec <memmove+0x4a>
 4fc:	bfc9                	j	4ce <memmove+0x2c>

00000000000004fe <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4fe:	1141                	addi	sp,sp,-16
 500:	e422                	sd	s0,8(sp)
 502:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 504:	ca05                	beqz	a2,534 <memcmp+0x36>
 506:	fff6069b          	addiw	a3,a2,-1
 50a:	1682                	slli	a3,a3,0x20
 50c:	9281                	srli	a3,a3,0x20
 50e:	0685                	addi	a3,a3,1
 510:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 512:	00054783          	lbu	a5,0(a0)
 516:	0005c703          	lbu	a4,0(a1)
 51a:	00e79863          	bne	a5,a4,52a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 51e:	0505                	addi	a0,a0,1
    p2++;
 520:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 522:	fed518e3          	bne	a0,a3,512 <memcmp+0x14>
  }
  return 0;
 526:	4501                	li	a0,0
 528:	a019                	j	52e <memcmp+0x30>
      return *p1 - *p2;
 52a:	40e7853b          	subw	a0,a5,a4
}
 52e:	6422                	ld	s0,8(sp)
 530:	0141                	addi	sp,sp,16
 532:	8082                	ret
  return 0;
 534:	4501                	li	a0,0
 536:	bfe5                	j	52e <memcmp+0x30>

0000000000000538 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 538:	1141                	addi	sp,sp,-16
 53a:	e406                	sd	ra,8(sp)
 53c:	e022                	sd	s0,0(sp)
 53e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 540:	00000097          	auipc	ra,0x0
 544:	f62080e7          	jalr	-158(ra) # 4a2 <memmove>
}
 548:	60a2                	ld	ra,8(sp)
 54a:	6402                	ld	s0,0(sp)
 54c:	0141                	addi	sp,sp,16
 54e:	8082                	ret

0000000000000550 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 550:	4885                	li	a7,1
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <exit>:
.global exit
exit:
 li a7, SYS_exit
 558:	4889                	li	a7,2
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <wait>:
.global wait
wait:
 li a7, SYS_wait
 560:	488d                	li	a7,3
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 568:	4891                	li	a7,4
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <read>:
.global read
read:
 li a7, SYS_read
 570:	4895                	li	a7,5
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <write>:
.global write
write:
 li a7, SYS_write
 578:	48c1                	li	a7,16
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <close>:
.global close
close:
 li a7, SYS_close
 580:	48d5                	li	a7,21
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <kill>:
.global kill
kill:
 li a7, SYS_kill
 588:	4899                	li	a7,6
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <exec>:
.global exec
exec:
 li a7, SYS_exec
 590:	489d                	li	a7,7
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <open>:
.global open
open:
 li a7, SYS_open
 598:	48bd                	li	a7,15
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5a0:	48c5                	li	a7,17
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5a8:	48c9                	li	a7,18
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5b0:	48a1                	li	a7,8
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <link>:
.global link
link:
 li a7, SYS_link
 5b8:	48cd                	li	a7,19
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5c0:	48d1                	li	a7,20
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5c8:	48a5                	li	a7,9
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5d0:	48a9                	li	a7,10
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5d8:	48ad                	li	a7,11
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5e0:	48b1                	li	a7,12
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5e8:	48b5                	li	a7,13
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5f0:	48b9                	li	a7,14
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <trace>:
.global trace
trace:
 li a7, SYS_trace
 5f8:	48d9                	li	a7,22
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 600:	1101                	addi	sp,sp,-32
 602:	ec06                	sd	ra,24(sp)
 604:	e822                	sd	s0,16(sp)
 606:	1000                	addi	s0,sp,32
 608:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 60c:	4605                	li	a2,1
 60e:	fef40593          	addi	a1,s0,-17
 612:	00000097          	auipc	ra,0x0
 616:	f66080e7          	jalr	-154(ra) # 578 <write>
}
 61a:	60e2                	ld	ra,24(sp)
 61c:	6442                	ld	s0,16(sp)
 61e:	6105                	addi	sp,sp,32
 620:	8082                	ret

0000000000000622 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 622:	7139                	addi	sp,sp,-64
 624:	fc06                	sd	ra,56(sp)
 626:	f822                	sd	s0,48(sp)
 628:	f426                	sd	s1,40(sp)
 62a:	f04a                	sd	s2,32(sp)
 62c:	ec4e                	sd	s3,24(sp)
 62e:	0080                	addi	s0,sp,64
 630:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 632:	c299                	beqz	a3,638 <printint+0x16>
 634:	0805c863          	bltz	a1,6c4 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 638:	2581                	sext.w	a1,a1
  neg = 0;
 63a:	4881                	li	a7,0
 63c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 640:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 642:	2601                	sext.w	a2,a2
 644:	00000517          	auipc	a0,0x0
 648:	4cc50513          	addi	a0,a0,1228 # b10 <digits>
 64c:	883a                	mv	a6,a4
 64e:	2705                	addiw	a4,a4,1
 650:	02c5f7bb          	remuw	a5,a1,a2
 654:	1782                	slli	a5,a5,0x20
 656:	9381                	srli	a5,a5,0x20
 658:	97aa                	add	a5,a5,a0
 65a:	0007c783          	lbu	a5,0(a5)
 65e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 662:	0005879b          	sext.w	a5,a1
 666:	02c5d5bb          	divuw	a1,a1,a2
 66a:	0685                	addi	a3,a3,1
 66c:	fec7f0e3          	bgeu	a5,a2,64c <printint+0x2a>
  if(neg)
 670:	00088b63          	beqz	a7,686 <printint+0x64>
    buf[i++] = '-';
 674:	fd040793          	addi	a5,s0,-48
 678:	973e                	add	a4,a4,a5
 67a:	02d00793          	li	a5,45
 67e:	fef70823          	sb	a5,-16(a4)
 682:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 686:	02e05863          	blez	a4,6b6 <printint+0x94>
 68a:	fc040793          	addi	a5,s0,-64
 68e:	00e78933          	add	s2,a5,a4
 692:	fff78993          	addi	s3,a5,-1
 696:	99ba                	add	s3,s3,a4
 698:	377d                	addiw	a4,a4,-1
 69a:	1702                	slli	a4,a4,0x20
 69c:	9301                	srli	a4,a4,0x20
 69e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6a2:	fff94583          	lbu	a1,-1(s2)
 6a6:	8526                	mv	a0,s1
 6a8:	00000097          	auipc	ra,0x0
 6ac:	f58080e7          	jalr	-168(ra) # 600 <putc>
  while(--i >= 0)
 6b0:	197d                	addi	s2,s2,-1
 6b2:	ff3918e3          	bne	s2,s3,6a2 <printint+0x80>
}
 6b6:	70e2                	ld	ra,56(sp)
 6b8:	7442                	ld	s0,48(sp)
 6ba:	74a2                	ld	s1,40(sp)
 6bc:	7902                	ld	s2,32(sp)
 6be:	69e2                	ld	s3,24(sp)
 6c0:	6121                	addi	sp,sp,64
 6c2:	8082                	ret
    x = -xx;
 6c4:	40b005bb          	negw	a1,a1
    neg = 1;
 6c8:	4885                	li	a7,1
    x = -xx;
 6ca:	bf8d                	j	63c <printint+0x1a>

00000000000006cc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6cc:	7119                	addi	sp,sp,-128
 6ce:	fc86                	sd	ra,120(sp)
 6d0:	f8a2                	sd	s0,112(sp)
 6d2:	f4a6                	sd	s1,104(sp)
 6d4:	f0ca                	sd	s2,96(sp)
 6d6:	ecce                	sd	s3,88(sp)
 6d8:	e8d2                	sd	s4,80(sp)
 6da:	e4d6                	sd	s5,72(sp)
 6dc:	e0da                	sd	s6,64(sp)
 6de:	fc5e                	sd	s7,56(sp)
 6e0:	f862                	sd	s8,48(sp)
 6e2:	f466                	sd	s9,40(sp)
 6e4:	f06a                	sd	s10,32(sp)
 6e6:	ec6e                	sd	s11,24(sp)
 6e8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6ea:	0005c903          	lbu	s2,0(a1)
 6ee:	18090f63          	beqz	s2,88c <vprintf+0x1c0>
 6f2:	8aaa                	mv	s5,a0
 6f4:	8b32                	mv	s6,a2
 6f6:	00158493          	addi	s1,a1,1
  state = 0;
 6fa:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6fc:	02500a13          	li	s4,37
      if(c == 'd'){
 700:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 704:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 708:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 70c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 710:	00000b97          	auipc	s7,0x0
 714:	400b8b93          	addi	s7,s7,1024 # b10 <digits>
 718:	a839                	j	736 <vprintf+0x6a>
        putc(fd, c);
 71a:	85ca                	mv	a1,s2
 71c:	8556                	mv	a0,s5
 71e:	00000097          	auipc	ra,0x0
 722:	ee2080e7          	jalr	-286(ra) # 600 <putc>
 726:	a019                	j	72c <vprintf+0x60>
    } else if(state == '%'){
 728:	01498f63          	beq	s3,s4,746 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 72c:	0485                	addi	s1,s1,1
 72e:	fff4c903          	lbu	s2,-1(s1)
 732:	14090d63          	beqz	s2,88c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 736:	0009079b          	sext.w	a5,s2
    if(state == 0){
 73a:	fe0997e3          	bnez	s3,728 <vprintf+0x5c>
      if(c == '%'){
 73e:	fd479ee3          	bne	a5,s4,71a <vprintf+0x4e>
        state = '%';
 742:	89be                	mv	s3,a5
 744:	b7e5                	j	72c <vprintf+0x60>
      if(c == 'd'){
 746:	05878063          	beq	a5,s8,786 <vprintf+0xba>
      } else if(c == 'l') {
 74a:	05978c63          	beq	a5,s9,7a2 <vprintf+0xd6>
      } else if(c == 'x') {
 74e:	07a78863          	beq	a5,s10,7be <vprintf+0xf2>
      } else if(c == 'p') {
 752:	09b78463          	beq	a5,s11,7da <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 756:	07300713          	li	a4,115
 75a:	0ce78663          	beq	a5,a4,826 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 75e:	06300713          	li	a4,99
 762:	0ee78e63          	beq	a5,a4,85e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 766:	11478863          	beq	a5,s4,876 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 76a:	85d2                	mv	a1,s4
 76c:	8556                	mv	a0,s5
 76e:	00000097          	auipc	ra,0x0
 772:	e92080e7          	jalr	-366(ra) # 600 <putc>
        putc(fd, c);
 776:	85ca                	mv	a1,s2
 778:	8556                	mv	a0,s5
 77a:	00000097          	auipc	ra,0x0
 77e:	e86080e7          	jalr	-378(ra) # 600 <putc>
      }
      state = 0;
 782:	4981                	li	s3,0
 784:	b765                	j	72c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 786:	008b0913          	addi	s2,s6,8
 78a:	4685                	li	a3,1
 78c:	4629                	li	a2,10
 78e:	000b2583          	lw	a1,0(s6)
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	e8e080e7          	jalr	-370(ra) # 622 <printint>
 79c:	8b4a                	mv	s6,s2
      state = 0;
 79e:	4981                	li	s3,0
 7a0:	b771                	j	72c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7a2:	008b0913          	addi	s2,s6,8
 7a6:	4681                	li	a3,0
 7a8:	4629                	li	a2,10
 7aa:	000b2583          	lw	a1,0(s6)
 7ae:	8556                	mv	a0,s5
 7b0:	00000097          	auipc	ra,0x0
 7b4:	e72080e7          	jalr	-398(ra) # 622 <printint>
 7b8:	8b4a                	mv	s6,s2
      state = 0;
 7ba:	4981                	li	s3,0
 7bc:	bf85                	j	72c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7be:	008b0913          	addi	s2,s6,8
 7c2:	4681                	li	a3,0
 7c4:	4641                	li	a2,16
 7c6:	000b2583          	lw	a1,0(s6)
 7ca:	8556                	mv	a0,s5
 7cc:	00000097          	auipc	ra,0x0
 7d0:	e56080e7          	jalr	-426(ra) # 622 <printint>
 7d4:	8b4a                	mv	s6,s2
      state = 0;
 7d6:	4981                	li	s3,0
 7d8:	bf91                	j	72c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7da:	008b0793          	addi	a5,s6,8
 7de:	f8f43423          	sd	a5,-120(s0)
 7e2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7e6:	03000593          	li	a1,48
 7ea:	8556                	mv	a0,s5
 7ec:	00000097          	auipc	ra,0x0
 7f0:	e14080e7          	jalr	-492(ra) # 600 <putc>
  putc(fd, 'x');
 7f4:	85ea                	mv	a1,s10
 7f6:	8556                	mv	a0,s5
 7f8:	00000097          	auipc	ra,0x0
 7fc:	e08080e7          	jalr	-504(ra) # 600 <putc>
 800:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 802:	03c9d793          	srli	a5,s3,0x3c
 806:	97de                	add	a5,a5,s7
 808:	0007c583          	lbu	a1,0(a5)
 80c:	8556                	mv	a0,s5
 80e:	00000097          	auipc	ra,0x0
 812:	df2080e7          	jalr	-526(ra) # 600 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 816:	0992                	slli	s3,s3,0x4
 818:	397d                	addiw	s2,s2,-1
 81a:	fe0914e3          	bnez	s2,802 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 81e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 822:	4981                	li	s3,0
 824:	b721                	j	72c <vprintf+0x60>
        s = va_arg(ap, char*);
 826:	008b0993          	addi	s3,s6,8
 82a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 82e:	02090163          	beqz	s2,850 <vprintf+0x184>
        while(*s != 0){
 832:	00094583          	lbu	a1,0(s2)
 836:	c9a1                	beqz	a1,886 <vprintf+0x1ba>
          putc(fd, *s);
 838:	8556                	mv	a0,s5
 83a:	00000097          	auipc	ra,0x0
 83e:	dc6080e7          	jalr	-570(ra) # 600 <putc>
          s++;
 842:	0905                	addi	s2,s2,1
        while(*s != 0){
 844:	00094583          	lbu	a1,0(s2)
 848:	f9e5                	bnez	a1,838 <vprintf+0x16c>
        s = va_arg(ap, char*);
 84a:	8b4e                	mv	s6,s3
      state = 0;
 84c:	4981                	li	s3,0
 84e:	bdf9                	j	72c <vprintf+0x60>
          s = "(null)";
 850:	00000917          	auipc	s2,0x0
 854:	2b890913          	addi	s2,s2,696 # b08 <malloc+0x172>
        while(*s != 0){
 858:	02800593          	li	a1,40
 85c:	bff1                	j	838 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 85e:	008b0913          	addi	s2,s6,8
 862:	000b4583          	lbu	a1,0(s6)
 866:	8556                	mv	a0,s5
 868:	00000097          	auipc	ra,0x0
 86c:	d98080e7          	jalr	-616(ra) # 600 <putc>
 870:	8b4a                	mv	s6,s2
      state = 0;
 872:	4981                	li	s3,0
 874:	bd65                	j	72c <vprintf+0x60>
        putc(fd, c);
 876:	85d2                	mv	a1,s4
 878:	8556                	mv	a0,s5
 87a:	00000097          	auipc	ra,0x0
 87e:	d86080e7          	jalr	-634(ra) # 600 <putc>
      state = 0;
 882:	4981                	li	s3,0
 884:	b565                	j	72c <vprintf+0x60>
        s = va_arg(ap, char*);
 886:	8b4e                	mv	s6,s3
      state = 0;
 888:	4981                	li	s3,0
 88a:	b54d                	j	72c <vprintf+0x60>
    }
  }
}
 88c:	70e6                	ld	ra,120(sp)
 88e:	7446                	ld	s0,112(sp)
 890:	74a6                	ld	s1,104(sp)
 892:	7906                	ld	s2,96(sp)
 894:	69e6                	ld	s3,88(sp)
 896:	6a46                	ld	s4,80(sp)
 898:	6aa6                	ld	s5,72(sp)
 89a:	6b06                	ld	s6,64(sp)
 89c:	7be2                	ld	s7,56(sp)
 89e:	7c42                	ld	s8,48(sp)
 8a0:	7ca2                	ld	s9,40(sp)
 8a2:	7d02                	ld	s10,32(sp)
 8a4:	6de2                	ld	s11,24(sp)
 8a6:	6109                	addi	sp,sp,128
 8a8:	8082                	ret

00000000000008aa <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8aa:	715d                	addi	sp,sp,-80
 8ac:	ec06                	sd	ra,24(sp)
 8ae:	e822                	sd	s0,16(sp)
 8b0:	1000                	addi	s0,sp,32
 8b2:	e010                	sd	a2,0(s0)
 8b4:	e414                	sd	a3,8(s0)
 8b6:	e818                	sd	a4,16(s0)
 8b8:	ec1c                	sd	a5,24(s0)
 8ba:	03043023          	sd	a6,32(s0)
 8be:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8c2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8c6:	8622                	mv	a2,s0
 8c8:	00000097          	auipc	ra,0x0
 8cc:	e04080e7          	jalr	-508(ra) # 6cc <vprintf>
}
 8d0:	60e2                	ld	ra,24(sp)
 8d2:	6442                	ld	s0,16(sp)
 8d4:	6161                	addi	sp,sp,80
 8d6:	8082                	ret

00000000000008d8 <printf>:

void
printf(const char *fmt, ...)
{
 8d8:	711d                	addi	sp,sp,-96
 8da:	ec06                	sd	ra,24(sp)
 8dc:	e822                	sd	s0,16(sp)
 8de:	1000                	addi	s0,sp,32
 8e0:	e40c                	sd	a1,8(s0)
 8e2:	e810                	sd	a2,16(s0)
 8e4:	ec14                	sd	a3,24(s0)
 8e6:	f018                	sd	a4,32(s0)
 8e8:	f41c                	sd	a5,40(s0)
 8ea:	03043823          	sd	a6,48(s0)
 8ee:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8f2:	00840613          	addi	a2,s0,8
 8f6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8fa:	85aa                	mv	a1,a0
 8fc:	4505                	li	a0,1
 8fe:	00000097          	auipc	ra,0x0
 902:	dce080e7          	jalr	-562(ra) # 6cc <vprintf>
}
 906:	60e2                	ld	ra,24(sp)
 908:	6442                	ld	s0,16(sp)
 90a:	6125                	addi	sp,sp,96
 90c:	8082                	ret

000000000000090e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 90e:	1141                	addi	sp,sp,-16
 910:	e422                	sd	s0,8(sp)
 912:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 914:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 918:	00000797          	auipc	a5,0x0
 91c:	6e87b783          	ld	a5,1768(a5) # 1000 <freep>
 920:	a805                	j	950 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 922:	4618                	lw	a4,8(a2)
 924:	9db9                	addw	a1,a1,a4
 926:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 92a:	6398                	ld	a4,0(a5)
 92c:	6318                	ld	a4,0(a4)
 92e:	fee53823          	sd	a4,-16(a0)
 932:	a091                	j	976 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 934:	ff852703          	lw	a4,-8(a0)
 938:	9e39                	addw	a2,a2,a4
 93a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 93c:	ff053703          	ld	a4,-16(a0)
 940:	e398                	sd	a4,0(a5)
 942:	a099                	j	988 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 944:	6398                	ld	a4,0(a5)
 946:	00e7e463          	bltu	a5,a4,94e <free+0x40>
 94a:	00e6ea63          	bltu	a3,a4,95e <free+0x50>
{
 94e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 950:	fed7fae3          	bgeu	a5,a3,944 <free+0x36>
 954:	6398                	ld	a4,0(a5)
 956:	00e6e463          	bltu	a3,a4,95e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 95a:	fee7eae3          	bltu	a5,a4,94e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 95e:	ff852583          	lw	a1,-8(a0)
 962:	6390                	ld	a2,0(a5)
 964:	02059713          	slli	a4,a1,0x20
 968:	9301                	srli	a4,a4,0x20
 96a:	0712                	slli	a4,a4,0x4
 96c:	9736                	add	a4,a4,a3
 96e:	fae60ae3          	beq	a2,a4,922 <free+0x14>
    bp->s.ptr = p->s.ptr;
 972:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 976:	4790                	lw	a2,8(a5)
 978:	02061713          	slli	a4,a2,0x20
 97c:	9301                	srli	a4,a4,0x20
 97e:	0712                	slli	a4,a4,0x4
 980:	973e                	add	a4,a4,a5
 982:	fae689e3          	beq	a3,a4,934 <free+0x26>
  } else
    p->s.ptr = bp;
 986:	e394                	sd	a3,0(a5)
  freep = p;
 988:	00000717          	auipc	a4,0x0
 98c:	66f73c23          	sd	a5,1656(a4) # 1000 <freep>
}
 990:	6422                	ld	s0,8(sp)
 992:	0141                	addi	sp,sp,16
 994:	8082                	ret

0000000000000996 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 996:	7139                	addi	sp,sp,-64
 998:	fc06                	sd	ra,56(sp)
 99a:	f822                	sd	s0,48(sp)
 99c:	f426                	sd	s1,40(sp)
 99e:	f04a                	sd	s2,32(sp)
 9a0:	ec4e                	sd	s3,24(sp)
 9a2:	e852                	sd	s4,16(sp)
 9a4:	e456                	sd	s5,8(sp)
 9a6:	e05a                	sd	s6,0(sp)
 9a8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9aa:	02051493          	slli	s1,a0,0x20
 9ae:	9081                	srli	s1,s1,0x20
 9b0:	04bd                	addi	s1,s1,15
 9b2:	8091                	srli	s1,s1,0x4
 9b4:	0014899b          	addiw	s3,s1,1
 9b8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9ba:	00000517          	auipc	a0,0x0
 9be:	64653503          	ld	a0,1606(a0) # 1000 <freep>
 9c2:	c515                	beqz	a0,9ee <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9c4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9c6:	4798                	lw	a4,8(a5)
 9c8:	02977f63          	bgeu	a4,s1,a06 <malloc+0x70>
 9cc:	8a4e                	mv	s4,s3
 9ce:	0009871b          	sext.w	a4,s3
 9d2:	6685                	lui	a3,0x1
 9d4:	00d77363          	bgeu	a4,a3,9da <malloc+0x44>
 9d8:	6a05                	lui	s4,0x1
 9da:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9de:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9e2:	00000917          	auipc	s2,0x0
 9e6:	61e90913          	addi	s2,s2,1566 # 1000 <freep>
  if(p == (char*)-1)
 9ea:	5afd                	li	s5,-1
 9ec:	a88d                	j	a5e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9ee:	00000797          	auipc	a5,0x0
 9f2:	63278793          	addi	a5,a5,1586 # 1020 <base>
 9f6:	00000717          	auipc	a4,0x0
 9fa:	60f73523          	sd	a5,1546(a4) # 1000 <freep>
 9fe:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a00:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a04:	b7e1                	j	9cc <malloc+0x36>
      if(p->s.size == nunits)
 a06:	02e48b63          	beq	s1,a4,a3c <malloc+0xa6>
        p->s.size -= nunits;
 a0a:	4137073b          	subw	a4,a4,s3
 a0e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a10:	1702                	slli	a4,a4,0x20
 a12:	9301                	srli	a4,a4,0x20
 a14:	0712                	slli	a4,a4,0x4
 a16:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a18:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a1c:	00000717          	auipc	a4,0x0
 a20:	5ea73223          	sd	a0,1508(a4) # 1000 <freep>
      return (void*)(p + 1);
 a24:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a28:	70e2                	ld	ra,56(sp)
 a2a:	7442                	ld	s0,48(sp)
 a2c:	74a2                	ld	s1,40(sp)
 a2e:	7902                	ld	s2,32(sp)
 a30:	69e2                	ld	s3,24(sp)
 a32:	6a42                	ld	s4,16(sp)
 a34:	6aa2                	ld	s5,8(sp)
 a36:	6b02                	ld	s6,0(sp)
 a38:	6121                	addi	sp,sp,64
 a3a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a3c:	6398                	ld	a4,0(a5)
 a3e:	e118                	sd	a4,0(a0)
 a40:	bff1                	j	a1c <malloc+0x86>
  hp->s.size = nu;
 a42:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a46:	0541                	addi	a0,a0,16
 a48:	00000097          	auipc	ra,0x0
 a4c:	ec6080e7          	jalr	-314(ra) # 90e <free>
  return freep;
 a50:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a54:	d971                	beqz	a0,a28 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a56:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a58:	4798                	lw	a4,8(a5)
 a5a:	fa9776e3          	bgeu	a4,s1,a06 <malloc+0x70>
    if(p == freep)
 a5e:	00093703          	ld	a4,0(s2)
 a62:	853e                	mv	a0,a5
 a64:	fef719e3          	bne	a4,a5,a56 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a68:	8552                	mv	a0,s4
 a6a:	00000097          	auipc	ra,0x0
 a6e:	b76080e7          	jalr	-1162(ra) # 5e0 <sbrk>
  if(p == (char*)-1)
 a72:	fd5518e3          	bne	a0,s5,a42 <malloc+0xac>
        return 0;
 a76:	4501                	li	a0,0
 a78:	bf45                	j	a28 <malloc+0x92>
