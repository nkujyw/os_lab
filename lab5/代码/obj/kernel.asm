
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000b1517          	auipc	a0,0xb1
ffffffffc020004e:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02b0bb8 <buf>
ffffffffc0200052:	000b5617          	auipc	a2,0xb5
ffffffffc0200056:	01a60613          	addi	a2,a2,26 # ffffffffc02b506c <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	143050ef          	jal	ra,ffffffffc02059a4 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	96258593          	addi	a1,a1,-1694 # ffffffffc02059d0 <etext+0x2>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	97a50513          	addi	a0,a0,-1670 # ffffffffc02059f0 <etext+0x22>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	734020ef          	jal	ra,ffffffffc02027ba <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	231030ef          	jal	ra,ffffffffc0203ac2 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	060050ef          	jal	ra,ffffffffc02050f6 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	1ec050ef          	jal	ra,ffffffffc020528e <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	93c50513          	addi	a0,a0,-1732 # ffffffffc02059f8 <etext+0x2a>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000b1b97          	auipc	s7,0xb1
ffffffffc02000d6:	ae6b8b93          	addi	s7,s7,-1306 # ffffffffc02b0bb8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000b1517          	auipc	a0,0xb1
ffffffffc0200132:	a8a50513          	addi	a0,a0,-1398 # ffffffffc02b0bb8 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	3f8050ef          	jal	ra,ffffffffc0205580 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	3c2050ef          	jal	ra,ffffffffc0205580 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	7e250513          	addi	a0,a0,2018 # ffffffffc0205a00 <etext+0x32>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	7ec50513          	addi	a0,a0,2028 # ffffffffc0205a20 <etext+0x52>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	78e58593          	addi	a1,a1,1934 # ffffffffc02059ce <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	7f850513          	addi	a0,a0,2040 # ffffffffc0205a40 <etext+0x72>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000b1597          	auipc	a1,0xb1
ffffffffc0200258:	96458593          	addi	a1,a1,-1692 # ffffffffc02b0bb8 <buf>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	80450513          	addi	a0,a0,-2044 # ffffffffc0205a60 <etext+0x92>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000b5597          	auipc	a1,0xb5
ffffffffc020026c:	e0458593          	addi	a1,a1,-508 # ffffffffc02b506c <end>
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	81050513          	addi	a0,a0,-2032 # ffffffffc0205a80 <etext+0xb2>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000b5597          	auipc	a1,0xb5
ffffffffc0200280:	1ef58593          	addi	a1,a1,495 # ffffffffc02b546b <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00006517          	auipc	a0,0x6
ffffffffc02002a2:	80250513          	addi	a0,a0,-2046 # ffffffffc0205aa0 <etext+0xd2>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00006617          	auipc	a2,0x6
ffffffffc02002b0:	82460613          	addi	a2,a2,-2012 # ffffffffc0205ad0 <etext+0x102>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00006517          	auipc	a0,0x6
ffffffffc02002bc:	83050513          	addi	a0,a0,-2000 # ffffffffc0205ae8 <etext+0x11a>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00006617          	auipc	a2,0x6
ffffffffc02002cc:	83860613          	addi	a2,a2,-1992 # ffffffffc0205b00 <etext+0x132>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	85058593          	addi	a1,a1,-1968 # ffffffffc0205b20 <etext+0x152>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	85050513          	addi	a0,a0,-1968 # ffffffffc0205b28 <etext+0x15a>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	85260613          	addi	a2,a2,-1966 # ffffffffc0205b38 <etext+0x16a>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	87258593          	addi	a1,a1,-1934 # ffffffffc0205b60 <etext+0x192>
ffffffffc02002f6:	00006517          	auipc	a0,0x6
ffffffffc02002fa:	83250513          	addi	a0,a0,-1998 # ffffffffc0205b28 <etext+0x15a>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	86e60613          	addi	a2,a2,-1938 # ffffffffc0205b70 <etext+0x1a2>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	88658593          	addi	a1,a1,-1914 # ffffffffc0205b90 <etext+0x1c2>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	81650513          	addi	a0,a0,-2026 # ffffffffc0205b28 <etext+0x15a>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00006517          	auipc	a0,0x6
ffffffffc0200350:	85450513          	addi	a0,a0,-1964 # ffffffffc0205ba0 <etext+0x1d2>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00006517          	auipc	a0,0x6
ffffffffc0200372:	85a50513          	addi	a0,a0,-1958 # ffffffffc0205bc8 <etext+0x1fa>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	8b4c0c13          	addi	s8,s8,-1868 # ffffffffc0205c38 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	86490913          	addi	s2,s2,-1948 # ffffffffc0205bf0 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	86448493          	addi	s1,s1,-1948 # ffffffffc0205bf8 <etext+0x22a>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	862b0b13          	addi	s6,s6,-1950 # ffffffffc0205c00 <etext+0x232>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	77aa0a13          	addi	s4,s4,1914 # ffffffffc0205b20 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00006d17          	auipc	s10,0x6
ffffffffc02003cc:	870d0d13          	addi	s10,s10,-1936 # ffffffffc0205c38 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	574050ef          	jal	ra,ffffffffc020594a <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	560050ef          	jal	ra,ffffffffc020594a <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	566050ef          	jal	ra,ffffffffc020598e <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	528050ef          	jal	ra,ffffffffc020598e <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	7a050513          	addi	a0,a0,1952 # ffffffffc0205c20 <etext+0x252>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000b5317          	auipc	t1,0xb5
ffffffffc0200492:	b5230313          	addi	t1,t1,-1198 # ffffffffc02b4fe0 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	7c450513          	addi	a0,a0,1988 # ffffffffc0205c80 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00007517          	auipc	a0,0x7
ffffffffc02004d6:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0206da0 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	79a50513          	addi	a0,a0,1946 # ffffffffc0205ca0 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00007517          	auipc	a0,0x7
ffffffffc020052a:	87a50513          	addi	a0,a0,-1926 # ffffffffc0206da0 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd578>
ffffffffc0200540:	000b5717          	auipc	a4,0xb5
ffffffffc0200544:	aaf73823          	sd	a5,-1360(a4) # ffffffffc02b4ff0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	76050513          	addi	a0,a0,1888 # ffffffffc0205cc0 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000b5797          	auipc	a5,0xb5
ffffffffc020056c:	a807b023          	sd	zero,-1408(a5) # ffffffffc02b4fe8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000b5797          	auipc	a5,0xb5
ffffffffc020057a:	a7a7b783          	ld	a5,-1414(a5) # ffffffffc02b4ff0 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	6e050513          	addi	a0,a0,1760 # ffffffffc0205ce0 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	6c250513          	addi	a0,a0,1730 # ffffffffc0205cf0 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	6bc50513          	addi	a0,a0,1724 # ffffffffc0205d00 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	6c450513          	addi	a0,a0,1732 # ffffffffc0205d18 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe2ae81>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	65a90913          	addi	s2,s2,1626 # ffffffffc0205d68 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	64448493          	addi	s1,s1,1604 # ffffffffc0205d60 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	67050513          	addi	a0,a0,1648 # ffffffffc0205de0 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	69c50513          	addi	a0,a0,1692 # ffffffffc0205e18 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	57c50513          	addi	a0,a0,1404 # ffffffffc0205d38 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	138050ef          	jal	ra,ffffffffc0205902 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	190050ef          	jal	ra,ffffffffc0205968 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	0dc050ef          	jal	ra,ffffffffc020594a <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	4ee50513          	addi	a0,a0,1262 # ffffffffc0205d70 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	44050513          	addi	a0,a0,1088 # ffffffffc0205d90 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	44650513          	addi	a0,a0,1094 # ffffffffc0205da8 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	45450513          	addi	a0,a0,1108 # ffffffffc0205dc8 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	49850513          	addi	a0,a0,1176 # ffffffffc0205e18 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000b4797          	auipc	a5,0xb4
ffffffffc020098c:	6687b823          	sd	s0,1648(a5) # ffffffffc02b4ff8 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000b4797          	auipc	a5,0xb4
ffffffffc0200994:	6767b823          	sd	s6,1648(a5) # ffffffffc02b5000 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000b4517          	auipc	a0,0xb4
ffffffffc020099e:	65e53503          	ld	a0,1630(a0) # ffffffffc02b4ff8 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000b4517          	auipc	a0,0xb4
ffffffffc02009a8:	65c53503          	ld	a0,1628(a0) # ffffffffc02b5000 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	52878793          	addi	a5,a5,1320 # ffffffffc0200ee8 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	45250513          	addi	a0,a0,1106 # ffffffffc0205e30 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	45a50513          	addi	a0,a0,1114 # ffffffffc0205e48 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	46450513          	addi	a0,a0,1124 # ffffffffc0205e60 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	46e50513          	addi	a0,a0,1134 # ffffffffc0205e78 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	47850513          	addi	a0,a0,1144 # ffffffffc0205e90 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	48250513          	addi	a0,a0,1154 # ffffffffc0205ea8 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	48c50513          	addi	a0,a0,1164 # ffffffffc0205ec0 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	49650513          	addi	a0,a0,1174 # ffffffffc0205ed8 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	4a050513          	addi	a0,a0,1184 # ffffffffc0205ef0 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	4aa50513          	addi	a0,a0,1194 # ffffffffc0205f08 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	4b450513          	addi	a0,a0,1204 # ffffffffc0205f20 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	4be50513          	addi	a0,a0,1214 # ffffffffc0205f38 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	4c850513          	addi	a0,a0,1224 # ffffffffc0205f50 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	4d250513          	addi	a0,a0,1234 # ffffffffc0205f68 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205f80 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	4e650513          	addi	a0,a0,1254 # ffffffffc0205f98 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	4f050513          	addi	a0,a0,1264 # ffffffffc0205fb0 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	4fa50513          	addi	a0,a0,1274 # ffffffffc0205fc8 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	50450513          	addi	a0,a0,1284 # ffffffffc0205fe0 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	50e50513          	addi	a0,a0,1294 # ffffffffc0205ff8 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	51850513          	addi	a0,a0,1304 # ffffffffc0206010 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	52250513          	addi	a0,a0,1314 # ffffffffc0206028 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	52c50513          	addi	a0,a0,1324 # ffffffffc0206040 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	53650513          	addi	a0,a0,1334 # ffffffffc0206058 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	54050513          	addi	a0,a0,1344 # ffffffffc0206070 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	54a50513          	addi	a0,a0,1354 # ffffffffc0206088 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	55450513          	addi	a0,a0,1364 # ffffffffc02060a0 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	55e50513          	addi	a0,a0,1374 # ffffffffc02060b8 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	56850513          	addi	a0,a0,1384 # ffffffffc02060d0 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	57250513          	addi	a0,a0,1394 # ffffffffc02060e8 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	57c50513          	addi	a0,a0,1404 # ffffffffc0206100 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	58250513          	addi	a0,a0,1410 # ffffffffc0206118 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	58450513          	addi	a0,a0,1412 # ffffffffc0206130 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	58450513          	addi	a0,a0,1412 # ffffffffc0206148 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	58c50513          	addi	a0,a0,1420 # ffffffffc0206160 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	59450513          	addi	a0,a0,1428 # ffffffffc0206178 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	59050513          	addi	a0,a0,1424 # ffffffffc0206188 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76463          	bltu	a4,a5,ffffffffc0200c98 <interrupt_handler+0x92>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	66c70713          	addi	a4,a4,1644 # ffffffffc0206280 <commands+0x648>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	5da50513          	addi	a0,a0,1498 # ffffffffc0206200 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	5ae50513          	addi	a0,a0,1454 # ffffffffc02061e0 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	56250513          	addi	a0,a0,1378 # ffffffffc02061a0 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	57650513          	addi	a0,a0,1398 # ffffffffc02061c0 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
            *(1) 设置下一次时钟中断（clock_set_next_event）
            *(2) ticks 计数器自增
            *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // 1. 设置下一次时钟中断
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        
        // 2. 增加 tick 计数
        ticks++;
ffffffffc0200c5e:	000b4797          	auipc	a5,0xb4
ffffffffc0200c62:	38a78793          	addi	a5,a5,906 # ffffffffc02b4fe8 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
        
        // 3. 检查是否需要调度
        // 如果 ticks 累计达到 TICK_NUM (100)，说明时间片用完了
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	eb81                	bnez	a5,ffffffffc0200c86 <interrupt_handler+0x80>
            // print_ticks(); // 可选：打印一下 tick 信息，证明还活着
            assert(current != NULL);
ffffffffc0200c78:	000b4797          	auipc	a5,0xb4
ffffffffc0200c7c:	3d87b783          	ld	a5,984(a5) # ffffffffc02b5050 <current>
ffffffffc0200c80:	cf89                	beqz	a5,ffffffffc0200c9a <interrupt_handler+0x94>
            current->need_resched = 1; // 标记当前进程需要被抢占
ffffffffc0200c82:	4705                	li	a4,1
ffffffffc0200c84:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	5d450513          	addi	a0,a0,1492 # ffffffffc0206260 <commands+0x628>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>
            assert(current != NULL);
ffffffffc0200c9a:	00005697          	auipc	a3,0x5
ffffffffc0200c9e:	58668693          	addi	a3,a3,1414 # ffffffffc0206220 <commands+0x5e8>
ffffffffc0200ca2:	00005617          	auipc	a2,0x5
ffffffffc0200ca6:	58e60613          	addi	a2,a2,1422 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0200caa:	08700593          	li	a1,135
ffffffffc0200cae:	00005517          	auipc	a0,0x5
ffffffffc0200cb2:	59a50513          	addi	a0,a0,1434 # ffffffffc0206248 <commands+0x610>
ffffffffc0200cb6:	fd8ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200cba <exception_handler>:
}

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cba:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cbe:	1101                	addi	sp,sp,-32
ffffffffc0200cc0:	e822                	sd	s0,16(sp)
ffffffffc0200cc2:	ec06                	sd	ra,24(sp)
ffffffffc0200cc4:	e426                	sd	s1,8(sp)
ffffffffc0200cc6:	473d                	li	a4,15
ffffffffc0200cc8:	842a                	mv	s0,a0
ffffffffc0200cca:	0ef76e63          	bltu	a4,a5,ffffffffc0200dc6 <exception_handler+0x10c>
ffffffffc0200cce:	00005717          	auipc	a4,0x5
ffffffffc0200cd2:	76e70713          	addi	a4,a4,1902 # ffffffffc020643c <commands+0x804>
ffffffffc0200cd6:	078a                	slli	a5,a5,0x2
ffffffffc0200cd8:	97ba                	add	a5,a5,a4
ffffffffc0200cda:	439c                	lw	a5,0(a5)
ffffffffc0200cdc:	97ba                	add	a5,a5,a4
ffffffffc0200cde:	8782                	jr	a5
        break;
    case CAUSE_ILLEGAL_INSTRUCTION:
        cprintf("Illegal instruction\n");
        break;
    case CAUSE_BREAKPOINT:
        cprintf("Breakpoint\n");
ffffffffc0200ce0:	00005517          	auipc	a0,0x5
ffffffffc0200ce4:	62850513          	addi	a0,a0,1576 # ffffffffc0206308 <commands+0x6d0>
ffffffffc0200ce8:	cacff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200cec:	6458                	ld	a4,136(s0)
ffffffffc0200cee:	47a9                	li	a5,10
ffffffffc0200cf0:	10f70063          	beq	a4,a5,ffffffffc0200df0 <exception_handler+0x136>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cf4:	60e2                	ld	ra,24(sp)
ffffffffc0200cf6:	6442                	ld	s0,16(sp)
ffffffffc0200cf8:	64a2                	ld	s1,8(sp)
ffffffffc0200cfa:	6105                	addi	sp,sp,32
ffffffffc0200cfc:	8082                	ret
        cprintf("Environment call from S-mode\n");
ffffffffc0200cfe:	00005517          	auipc	a0,0x5
ffffffffc0200d02:	66a50513          	addi	a0,a0,1642 # ffffffffc0206368 <commands+0x730>
ffffffffc0200d06:	c8eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200d0a:	10843783          	ld	a5,264(s0)
}
ffffffffc0200d0e:	60e2                	ld	ra,24(sp)
ffffffffc0200d10:	64a2                	ld	s1,8(sp)
        tf->epc += 4;
ffffffffc0200d12:	0791                	addi	a5,a5,4
ffffffffc0200d14:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d18:	6442                	ld	s0,16(sp)
ffffffffc0200d1a:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200d1c:	7620406f          	j	ffffffffc020547e <syscall>
        cprintf("Instruction page fault\n");
ffffffffc0200d20:	00005517          	auipc	a0,0x5
ffffffffc0200d24:	6a850513          	addi	a0,a0,1704 # ffffffffc02063c8 <commands+0x790>
}
ffffffffc0200d28:	6442                	ld	s0,16(sp)
ffffffffc0200d2a:	60e2                	ld	ra,24(sp)
ffffffffc0200d2c:	64a2                	ld	s1,8(sp)
ffffffffc0200d2e:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200d30:	c64ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d34:	00005517          	auipc	a0,0x5
ffffffffc0200d38:	6ac50513          	addi	a0,a0,1708 # ffffffffc02063e0 <commands+0x7a8>
ffffffffc0200d3c:	b7f5                	j	ffffffffc0200d28 <exception_handler+0x6e>
    if (check_mm_struct != NULL) {
ffffffffc0200d3e:	000b4517          	auipc	a0,0xb4
ffffffffc0200d42:	30253503          	ld	a0,770(a0) # ffffffffc02b5040 <check_mm_struct>
        assert(current == NULL);
ffffffffc0200d46:	000b4797          	auipc	a5,0xb4
ffffffffc0200d4a:	30a7b783          	ld	a5,778(a5) # ffffffffc02b5050 <current>
    if (check_mm_struct != NULL) {
ffffffffc0200d4e:	cd51                	beqz	a0,ffffffffc0200dea <exception_handler+0x130>
        assert(current == NULL);
ffffffffc0200d50:	e7e1                	bnez	a5,ffffffffc0200e18 <exception_handler+0x15e>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200d52:	11043603          	ld	a2,272(s0)
ffffffffc0200d56:	45bd                	li	a1,15
ffffffffc0200d58:	122030ef          	jal	ra,ffffffffc0203e7a <do_pgfault>
ffffffffc0200d5c:	84aa                	mv	s1,a0
        if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200d5e:	d959                	beqz	a0,ffffffffc0200cf4 <exception_handler+0x3a>
            print_trapframe(tf);
ffffffffc0200d60:	8522                	mv	a0,s0
ffffffffc0200d62:	e43ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200d66:	86a6                	mv	a3,s1
ffffffffc0200d68:	00005617          	auipc	a2,0x5
ffffffffc0200d6c:	6b860613          	addi	a2,a2,1720 # ffffffffc0206420 <commands+0x7e8>
ffffffffc0200d70:	0fa00593          	li	a1,250
ffffffffc0200d74:	00005517          	auipc	a0,0x5
ffffffffc0200d78:	4d450513          	addi	a0,a0,1236 # ffffffffc0206248 <commands+0x610>
ffffffffc0200d7c:	f12ff0ef          	jal	ra,ffffffffc020048e <__panic>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d80:	00005517          	auipc	a0,0x5
ffffffffc0200d84:	60850513          	addi	a0,a0,1544 # ffffffffc0206388 <commands+0x750>
ffffffffc0200d88:	b745                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d8a:	00005517          	auipc	a0,0x5
ffffffffc0200d8e:	61e50513          	addi	a0,a0,1566 # ffffffffc02063a8 <commands+0x770>
ffffffffc0200d92:	bf59                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Load access fault\n");
ffffffffc0200d94:	00005517          	auipc	a0,0x5
ffffffffc0200d98:	5a450513          	addi	a0,a0,1444 # ffffffffc0206338 <commands+0x700>
ffffffffc0200d9c:	b771                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Load address misaligned\n");
ffffffffc0200d9e:	00005517          	auipc	a0,0x5
ffffffffc0200da2:	57a50513          	addi	a0,a0,1402 # ffffffffc0206318 <commands+0x6e0>
ffffffffc0200da6:	b749                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Instruction address misaligned\n");
ffffffffc0200da8:	00005517          	auipc	a0,0x5
ffffffffc0200dac:	50850513          	addi	a0,a0,1288 # ffffffffc02062b0 <commands+0x678>
ffffffffc0200db0:	bfa5                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Instruction access fault\n");
ffffffffc0200db2:	00005517          	auipc	a0,0x5
ffffffffc0200db6:	51e50513          	addi	a0,a0,1310 # ffffffffc02062d0 <commands+0x698>
ffffffffc0200dba:	b7bd                	j	ffffffffc0200d28 <exception_handler+0x6e>
        cprintf("Illegal instruction\n");
ffffffffc0200dbc:	00005517          	auipc	a0,0x5
ffffffffc0200dc0:	53450513          	addi	a0,a0,1332 # ffffffffc02062f0 <commands+0x6b8>
ffffffffc0200dc4:	b795                	j	ffffffffc0200d28 <exception_handler+0x6e>
        print_trapframe(tf);
ffffffffc0200dc6:	8522                	mv	a0,s0
}
ffffffffc0200dc8:	6442                	ld	s0,16(sp)
ffffffffc0200dca:	60e2                	ld	ra,24(sp)
ffffffffc0200dcc:	64a2                	ld	s1,8(sp)
ffffffffc0200dce:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200dd0:	bbd1                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200dd2:	00005617          	auipc	a2,0x5
ffffffffc0200dd6:	57e60613          	addi	a2,a2,1406 # ffffffffc0206350 <commands+0x718>
ffffffffc0200dda:	0db00593          	li	a1,219
ffffffffc0200dde:	00005517          	auipc	a0,0x5
ffffffffc0200de2:	46a50513          	addi	a0,a0,1130 # ffffffffc0206248 <commands+0x610>
ffffffffc0200de6:	ea8ff0ef          	jal	ra,ffffffffc020048e <__panic>
        if (current == NULL) {
ffffffffc0200dea:	c7b9                	beqz	a5,ffffffffc0200e38 <exception_handler+0x17e>
        mm = current->mm;
ffffffffc0200dec:	7788                	ld	a0,40(a5)
ffffffffc0200dee:	b795                	j	ffffffffc0200d52 <exception_handler+0x98>
            tf->epc += 4;
ffffffffc0200df0:	10843783          	ld	a5,264(s0)
ffffffffc0200df4:	0791                	addi	a5,a5,4
ffffffffc0200df6:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200dfa:	684040ef          	jal	ra,ffffffffc020547e <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dfe:	000b4797          	auipc	a5,0xb4
ffffffffc0200e02:	2527b783          	ld	a5,594(a5) # ffffffffc02b5050 <current>
ffffffffc0200e06:	6b9c                	ld	a5,16(a5)
ffffffffc0200e08:	8522                	mv	a0,s0
}
ffffffffc0200e0a:	6442                	ld	s0,16(sp)
ffffffffc0200e0c:	60e2                	ld	ra,24(sp)
ffffffffc0200e0e:	64a2                	ld	s1,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e10:	6589                	lui	a1,0x2
ffffffffc0200e12:	95be                	add	a1,a1,a5
}
ffffffffc0200e14:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e16:	a245                	j	ffffffffc0200fb6 <kernel_execve_ret>
        assert(current == NULL);
ffffffffc0200e18:	00005697          	auipc	a3,0x5
ffffffffc0200e1c:	5e068693          	addi	a3,a3,1504 # ffffffffc02063f8 <commands+0x7c0>
ffffffffc0200e20:	00005617          	auipc	a2,0x5
ffffffffc0200e24:	41060613          	addi	a2,a2,1040 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0200e28:	0ad00593          	li	a1,173
ffffffffc0200e2c:	00005517          	auipc	a0,0x5
ffffffffc0200e30:	41c50513          	addi	a0,a0,1052 # ffffffffc0206248 <commands+0x610>
ffffffffc0200e34:	e5aff0ef          	jal	ra,ffffffffc020048e <__panic>
            print_trapframe(tf);
ffffffffc0200e38:	8522                	mv	a0,s0
ffffffffc0200e3a:	d6bff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
            print_regs(&tf->gpr);
ffffffffc0200e3e:	8522                	mv	a0,s0
ffffffffc0200e40:	b97ff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
            panic("unhandled page fault.\n");
ffffffffc0200e44:	00005617          	auipc	a2,0x5
ffffffffc0200e48:	5c460613          	addi	a2,a2,1476 # ffffffffc0206408 <commands+0x7d0>
ffffffffc0200e4c:	0b300593          	li	a1,179
ffffffffc0200e50:	00005517          	auipc	a0,0x5
ffffffffc0200e54:	3f850513          	addi	a0,a0,1016 # ffffffffc0206248 <commands+0x610>
ffffffffc0200e58:	e36ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e5c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e5c:	1101                	addi	sp,sp,-32
ffffffffc0200e5e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e60:	000b4417          	auipc	s0,0xb4
ffffffffc0200e64:	1f040413          	addi	s0,s0,496 # ffffffffc02b5050 <current>
ffffffffc0200e68:	6018                	ld	a4,0(s0)
{
ffffffffc0200e6a:	ec06                	sd	ra,24(sp)
ffffffffc0200e6c:	e426                	sd	s1,8(sp)
ffffffffc0200e6e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e70:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e74:	cf1d                	beqz	a4,ffffffffc0200eb2 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e76:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e7a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e7e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e80:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e84:	0206c463          	bltz	a3,ffffffffc0200eac <trap+0x50>
        exception_handler(tf);
ffffffffc0200e88:	e33ff0ef          	jal	ra,ffffffffc0200cba <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e8c:	601c                	ld	a5,0(s0)
ffffffffc0200e8e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e92:	e499                	bnez	s1,ffffffffc0200ea0 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e94:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e98:	8b05                	andi	a4,a4,1
ffffffffc0200e9a:	e329                	bnez	a4,ffffffffc0200edc <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e9c:	6f9c                	ld	a5,24(a5)
ffffffffc0200e9e:	eb85                	bnez	a5,ffffffffc0200ece <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200ea0:	60e2                	ld	ra,24(sp)
ffffffffc0200ea2:	6442                	ld	s0,16(sp)
ffffffffc0200ea4:	64a2                	ld	s1,8(sp)
ffffffffc0200ea6:	6902                	ld	s2,0(sp)
ffffffffc0200ea8:	6105                	addi	sp,sp,32
ffffffffc0200eaa:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200eac:	d5bff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200eb0:	bff1                	j	ffffffffc0200e8c <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200eb2:	0006c863          	bltz	a3,ffffffffc0200ec2 <trap+0x66>
}
ffffffffc0200eb6:	6442                	ld	s0,16(sp)
ffffffffc0200eb8:	60e2                	ld	ra,24(sp)
ffffffffc0200eba:	64a2                	ld	s1,8(sp)
ffffffffc0200ebc:	6902                	ld	s2,0(sp)
ffffffffc0200ebe:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200ec0:	bbed                	j	ffffffffc0200cba <exception_handler>
}
ffffffffc0200ec2:	6442                	ld	s0,16(sp)
ffffffffc0200ec4:	60e2                	ld	ra,24(sp)
ffffffffc0200ec6:	64a2                	ld	s1,8(sp)
ffffffffc0200ec8:	6902                	ld	s2,0(sp)
ffffffffc0200eca:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200ecc:	bb2d                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200ece:	6442                	ld	s0,16(sp)
ffffffffc0200ed0:	60e2                	ld	ra,24(sp)
ffffffffc0200ed2:	64a2                	ld	s1,8(sp)
ffffffffc0200ed4:	6902                	ld	s2,0(sp)
ffffffffc0200ed6:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200ed8:	4ba0406f          	j	ffffffffc0205392 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200edc:	555d                	li	a0,-9
ffffffffc0200ede:	7fa030ef          	jal	ra,ffffffffc02046d8 <do_exit>
            if (current->need_resched)
ffffffffc0200ee2:	601c                	ld	a5,0(s0)
ffffffffc0200ee4:	bf65                	j	ffffffffc0200e9c <trap+0x40>
	...

ffffffffc0200ee8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ee8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200eec:	00011463          	bnez	sp,ffffffffc0200ef4 <__alltraps+0xc>
ffffffffc0200ef0:	14002173          	csrr	sp,sscratch
ffffffffc0200ef4:	712d                	addi	sp,sp,-288
ffffffffc0200ef6:	e002                	sd	zero,0(sp)
ffffffffc0200ef8:	e406                	sd	ra,8(sp)
ffffffffc0200efa:	ec0e                	sd	gp,24(sp)
ffffffffc0200efc:	f012                	sd	tp,32(sp)
ffffffffc0200efe:	f416                	sd	t0,40(sp)
ffffffffc0200f00:	f81a                	sd	t1,48(sp)
ffffffffc0200f02:	fc1e                	sd	t2,56(sp)
ffffffffc0200f04:	e0a2                	sd	s0,64(sp)
ffffffffc0200f06:	e4a6                	sd	s1,72(sp)
ffffffffc0200f08:	e8aa                	sd	a0,80(sp)
ffffffffc0200f0a:	ecae                	sd	a1,88(sp)
ffffffffc0200f0c:	f0b2                	sd	a2,96(sp)
ffffffffc0200f0e:	f4b6                	sd	a3,104(sp)
ffffffffc0200f10:	f8ba                	sd	a4,112(sp)
ffffffffc0200f12:	fcbe                	sd	a5,120(sp)
ffffffffc0200f14:	e142                	sd	a6,128(sp)
ffffffffc0200f16:	e546                	sd	a7,136(sp)
ffffffffc0200f18:	e94a                	sd	s2,144(sp)
ffffffffc0200f1a:	ed4e                	sd	s3,152(sp)
ffffffffc0200f1c:	f152                	sd	s4,160(sp)
ffffffffc0200f1e:	f556                	sd	s5,168(sp)
ffffffffc0200f20:	f95a                	sd	s6,176(sp)
ffffffffc0200f22:	fd5e                	sd	s7,184(sp)
ffffffffc0200f24:	e1e2                	sd	s8,192(sp)
ffffffffc0200f26:	e5e6                	sd	s9,200(sp)
ffffffffc0200f28:	e9ea                	sd	s10,208(sp)
ffffffffc0200f2a:	edee                	sd	s11,216(sp)
ffffffffc0200f2c:	f1f2                	sd	t3,224(sp)
ffffffffc0200f2e:	f5f6                	sd	t4,232(sp)
ffffffffc0200f30:	f9fa                	sd	t5,240(sp)
ffffffffc0200f32:	fdfe                	sd	t6,248(sp)
ffffffffc0200f34:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f38:	100024f3          	csrr	s1,sstatus
ffffffffc0200f3c:	14102973          	csrr	s2,sepc
ffffffffc0200f40:	143029f3          	csrr	s3,stval
ffffffffc0200f44:	14202a73          	csrr	s4,scause
ffffffffc0200f48:	e822                	sd	s0,16(sp)
ffffffffc0200f4a:	e226                	sd	s1,256(sp)
ffffffffc0200f4c:	e64a                	sd	s2,264(sp)
ffffffffc0200f4e:	ea4e                	sd	s3,272(sp)
ffffffffc0200f50:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f52:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f54:	f09ff0ef          	jal	ra,ffffffffc0200e5c <trap>

ffffffffc0200f58 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f58:	6492                	ld	s1,256(sp)
ffffffffc0200f5a:	6932                	ld	s2,264(sp)
ffffffffc0200f5c:	1004f413          	andi	s0,s1,256
ffffffffc0200f60:	e401                	bnez	s0,ffffffffc0200f68 <__trapret+0x10>
ffffffffc0200f62:	1200                	addi	s0,sp,288
ffffffffc0200f64:	14041073          	csrw	sscratch,s0
ffffffffc0200f68:	10049073          	csrw	sstatus,s1
ffffffffc0200f6c:	14191073          	csrw	sepc,s2
ffffffffc0200f70:	60a2                	ld	ra,8(sp)
ffffffffc0200f72:	61e2                	ld	gp,24(sp)
ffffffffc0200f74:	7202                	ld	tp,32(sp)
ffffffffc0200f76:	72a2                	ld	t0,40(sp)
ffffffffc0200f78:	7342                	ld	t1,48(sp)
ffffffffc0200f7a:	73e2                	ld	t2,56(sp)
ffffffffc0200f7c:	6406                	ld	s0,64(sp)
ffffffffc0200f7e:	64a6                	ld	s1,72(sp)
ffffffffc0200f80:	6546                	ld	a0,80(sp)
ffffffffc0200f82:	65e6                	ld	a1,88(sp)
ffffffffc0200f84:	7606                	ld	a2,96(sp)
ffffffffc0200f86:	76a6                	ld	a3,104(sp)
ffffffffc0200f88:	7746                	ld	a4,112(sp)
ffffffffc0200f8a:	77e6                	ld	a5,120(sp)
ffffffffc0200f8c:	680a                	ld	a6,128(sp)
ffffffffc0200f8e:	68aa                	ld	a7,136(sp)
ffffffffc0200f90:	694a                	ld	s2,144(sp)
ffffffffc0200f92:	69ea                	ld	s3,152(sp)
ffffffffc0200f94:	7a0a                	ld	s4,160(sp)
ffffffffc0200f96:	7aaa                	ld	s5,168(sp)
ffffffffc0200f98:	7b4a                	ld	s6,176(sp)
ffffffffc0200f9a:	7bea                	ld	s7,184(sp)
ffffffffc0200f9c:	6c0e                	ld	s8,192(sp)
ffffffffc0200f9e:	6cae                	ld	s9,200(sp)
ffffffffc0200fa0:	6d4e                	ld	s10,208(sp)
ffffffffc0200fa2:	6dee                	ld	s11,216(sp)
ffffffffc0200fa4:	7e0e                	ld	t3,224(sp)
ffffffffc0200fa6:	7eae                	ld	t4,232(sp)
ffffffffc0200fa8:	7f4e                	ld	t5,240(sp)
ffffffffc0200faa:	7fee                	ld	t6,248(sp)
ffffffffc0200fac:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fae:	10200073          	sret

ffffffffc0200fb2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fb2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200fb4:	b755                	j	ffffffffc0200f58 <__trapret>

ffffffffc0200fb6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200fb6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200fba:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200fbe:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200fc2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200fc6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200fca:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200fce:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200fd2:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200fd6:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200fda:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200fdc:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200fde:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200fe0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200fe2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200fe4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200fe6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200fe8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200fea:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200fec:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200fee:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200ff0:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200ff2:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200ff4:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200ff6:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200ff8:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200ffa:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200ffc:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200ffe:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0201000:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0201002:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0201004:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0201006:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0201008:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc020100a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc020100c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc020100e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0201010:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0201012:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0201014:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0201016:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0201018:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc020101a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc020101c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc020101e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0201020:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0201022:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0201024:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0201026:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0201028:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc020102a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc020102c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc020102e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0201030:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0201032:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0201034:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0201036:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0201038:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc020103a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc020103c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc020103e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201040:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201042:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201044:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201046:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201048:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020104a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020104c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020104e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201050:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201052:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201054:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201056:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201058:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020105a:	812e                	mv	sp,a1
ffffffffc020105c:	bdf5                	j	ffffffffc0200f58 <__trapret>

ffffffffc020105e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020105e:	000b0797          	auipc	a5,0xb0
ffffffffc0201062:	f5a78793          	addi	a5,a5,-166 # ffffffffc02b0fb8 <free_area>
ffffffffc0201066:	e79c                	sd	a5,8(a5)
ffffffffc0201068:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020106a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020106e:	8082                	ret

ffffffffc0201070 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201070:	000b0517          	auipc	a0,0xb0
ffffffffc0201074:	f5856503          	lwu	a0,-168(a0) # ffffffffc02b0fc8 <free_area+0x10>
ffffffffc0201078:	8082                	ret

ffffffffc020107a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020107a:	715d                	addi	sp,sp,-80
ffffffffc020107c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020107e:	000b0417          	auipc	s0,0xb0
ffffffffc0201082:	f3a40413          	addi	s0,s0,-198 # ffffffffc02b0fb8 <free_area>
ffffffffc0201086:	641c                	ld	a5,8(s0)
ffffffffc0201088:	e486                	sd	ra,72(sp)
ffffffffc020108a:	fc26                	sd	s1,56(sp)
ffffffffc020108c:	f84a                	sd	s2,48(sp)
ffffffffc020108e:	f44e                	sd	s3,40(sp)
ffffffffc0201090:	f052                	sd	s4,32(sp)
ffffffffc0201092:	ec56                	sd	s5,24(sp)
ffffffffc0201094:	e85a                	sd	s6,16(sp)
ffffffffc0201096:	e45e                	sd	s7,8(sp)
ffffffffc0201098:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020109a:	2a878d63          	beq	a5,s0,ffffffffc0201354 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020109e:	4481                	li	s1,0
ffffffffc02010a0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010a2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02010a6:	8b09                	andi	a4,a4,2
ffffffffc02010a8:	2a070a63          	beqz	a4,ffffffffc020135c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc02010ac:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010b0:	679c                	ld	a5,8(a5)
ffffffffc02010b2:	2905                	addiw	s2,s2,1
ffffffffc02010b4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010b6:	fe8796e3          	bne	a5,s0,ffffffffc02010a2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010ba:	89a6                	mv	s3,s1
ffffffffc02010bc:	6df000ef          	jal	ra,ffffffffc0201f9a <nr_free_pages>
ffffffffc02010c0:	6f351e63          	bne	a0,s3,ffffffffc02017bc <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010c4:	4505                	li	a0,1
ffffffffc02010c6:	657000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02010ca:	8aaa                	mv	s5,a0
ffffffffc02010cc:	42050863          	beqz	a0,ffffffffc02014fc <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010d0:	4505                	li	a0,1
ffffffffc02010d2:	64b000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02010d6:	89aa                	mv	s3,a0
ffffffffc02010d8:	70050263          	beqz	a0,ffffffffc02017dc <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010dc:	4505                	li	a0,1
ffffffffc02010de:	63f000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02010e2:	8a2a                	mv	s4,a0
ffffffffc02010e4:	48050c63          	beqz	a0,ffffffffc020157c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010e8:	293a8a63          	beq	s5,s3,ffffffffc020137c <default_check+0x302>
ffffffffc02010ec:	28aa8863          	beq	s5,a0,ffffffffc020137c <default_check+0x302>
ffffffffc02010f0:	28a98663          	beq	s3,a0,ffffffffc020137c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010f4:	000aa783          	lw	a5,0(s5)
ffffffffc02010f8:	2a079263          	bnez	a5,ffffffffc020139c <default_check+0x322>
ffffffffc02010fc:	0009a783          	lw	a5,0(s3)
ffffffffc0201100:	28079e63          	bnez	a5,ffffffffc020139c <default_check+0x322>
ffffffffc0201104:	411c                	lw	a5,0(a0)
ffffffffc0201106:	28079b63          	bnez	a5,ffffffffc020139c <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020110a:	000b4797          	auipc	a5,0xb4
ffffffffc020110e:	f1e7b783          	ld	a5,-226(a5) # ffffffffc02b5028 <pages>
ffffffffc0201112:	40fa8733          	sub	a4,s5,a5
ffffffffc0201116:	00007617          	auipc	a2,0x7
ffffffffc020111a:	bba63603          	ld	a2,-1094(a2) # ffffffffc0207cd0 <nbase>
ffffffffc020111e:	8719                	srai	a4,a4,0x6
ffffffffc0201120:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201122:	000b4697          	auipc	a3,0xb4
ffffffffc0201126:	efe6b683          	ld	a3,-258(a3) # ffffffffc02b5020 <npage>
ffffffffc020112a:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020112c:	0732                	slli	a4,a4,0xc
ffffffffc020112e:	28d77763          	bgeu	a4,a3,ffffffffc02013bc <default_check+0x342>
    return page - pages + nbase;
ffffffffc0201132:	40f98733          	sub	a4,s3,a5
ffffffffc0201136:	8719                	srai	a4,a4,0x6
ffffffffc0201138:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020113a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020113c:	4cd77063          	bgeu	a4,a3,ffffffffc02015fc <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201140:	40f507b3          	sub	a5,a0,a5
ffffffffc0201144:	8799                	srai	a5,a5,0x6
ffffffffc0201146:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201148:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020114a:	30d7f963          	bgeu	a5,a3,ffffffffc020145c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020114e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201150:	00043c03          	ld	s8,0(s0)
ffffffffc0201154:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201158:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020115c:	e400                	sd	s0,8(s0)
ffffffffc020115e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201160:	000b0797          	auipc	a5,0xb0
ffffffffc0201164:	e607a423          	sw	zero,-408(a5) # ffffffffc02b0fc8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201168:	5b5000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc020116c:	2c051863          	bnez	a0,ffffffffc020143c <default_check+0x3c2>
    free_page(p0);
ffffffffc0201170:	4585                	li	a1,1
ffffffffc0201172:	8556                	mv	a0,s5
ffffffffc0201174:	5e7000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_page(p1);
ffffffffc0201178:	4585                	li	a1,1
ffffffffc020117a:	854e                	mv	a0,s3
ffffffffc020117c:	5df000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_page(p2);
ffffffffc0201180:	4585                	li	a1,1
ffffffffc0201182:	8552                	mv	a0,s4
ffffffffc0201184:	5d7000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    assert(nr_free == 3);
ffffffffc0201188:	4818                	lw	a4,16(s0)
ffffffffc020118a:	478d                	li	a5,3
ffffffffc020118c:	28f71863          	bne	a4,a5,ffffffffc020141c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201190:	4505                	li	a0,1
ffffffffc0201192:	58b000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201196:	89aa                	mv	s3,a0
ffffffffc0201198:	26050263          	beqz	a0,ffffffffc02013fc <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020119c:	4505                	li	a0,1
ffffffffc020119e:	57f000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02011a2:	8aaa                	mv	s5,a0
ffffffffc02011a4:	3a050c63          	beqz	a0,ffffffffc020155c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011a8:	4505                	li	a0,1
ffffffffc02011aa:	573000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02011ae:	8a2a                	mv	s4,a0
ffffffffc02011b0:	38050663          	beqz	a0,ffffffffc020153c <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc02011b4:	4505                	li	a0,1
ffffffffc02011b6:	567000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02011ba:	36051163          	bnez	a0,ffffffffc020151c <default_check+0x4a2>
    free_page(p0);
ffffffffc02011be:	4585                	li	a1,1
ffffffffc02011c0:	854e                	mv	a0,s3
ffffffffc02011c2:	599000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011c6:	641c                	ld	a5,8(s0)
ffffffffc02011c8:	20878a63          	beq	a5,s0,ffffffffc02013dc <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc02011cc:	4505                	li	a0,1
ffffffffc02011ce:	54f000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02011d2:	30a99563          	bne	s3,a0,ffffffffc02014dc <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02011d6:	4505                	li	a0,1
ffffffffc02011d8:	545000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02011dc:	2e051063          	bnez	a0,ffffffffc02014bc <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02011e0:	481c                	lw	a5,16(s0)
ffffffffc02011e2:	2a079d63          	bnez	a5,ffffffffc020149c <default_check+0x422>
    free_page(p);
ffffffffc02011e6:	854e                	mv	a0,s3
ffffffffc02011e8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011ea:	01843023          	sd	s8,0(s0)
ffffffffc02011ee:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011f2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02011f6:	565000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_page(p1);
ffffffffc02011fa:	4585                	li	a1,1
ffffffffc02011fc:	8556                	mv	a0,s5
ffffffffc02011fe:	55d000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_page(p2);
ffffffffc0201202:	4585                	li	a1,1
ffffffffc0201204:	8552                	mv	a0,s4
ffffffffc0201206:	555000ef          	jal	ra,ffffffffc0201f5a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020120a:	4515                	li	a0,5
ffffffffc020120c:	511000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201210:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201212:	26050563          	beqz	a0,ffffffffc020147c <default_check+0x402>
ffffffffc0201216:	651c                	ld	a5,8(a0)
ffffffffc0201218:	8385                	srli	a5,a5,0x1
ffffffffc020121a:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc020121c:	54079063          	bnez	a5,ffffffffc020175c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201220:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201222:	00043b03          	ld	s6,0(s0)
ffffffffc0201226:	00843a83          	ld	s5,8(s0)
ffffffffc020122a:	e000                	sd	s0,0(s0)
ffffffffc020122c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020122e:	4ef000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201232:	50051563          	bnez	a0,ffffffffc020173c <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201236:	08098a13          	addi	s4,s3,128
ffffffffc020123a:	8552                	mv	a0,s4
ffffffffc020123c:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020123e:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201242:	000b0797          	auipc	a5,0xb0
ffffffffc0201246:	d807a323          	sw	zero,-634(a5) # ffffffffc02b0fc8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020124a:	511000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020124e:	4511                	li	a0,4
ffffffffc0201250:	4cd000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201254:	4c051463          	bnez	a0,ffffffffc020171c <default_check+0x6a2>
ffffffffc0201258:	0889b783          	ld	a5,136(s3)
ffffffffc020125c:	8385                	srli	a5,a5,0x1
ffffffffc020125e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201260:	48078e63          	beqz	a5,ffffffffc02016fc <default_check+0x682>
ffffffffc0201264:	0909a703          	lw	a4,144(s3)
ffffffffc0201268:	478d                	li	a5,3
ffffffffc020126a:	48f71963          	bne	a4,a5,ffffffffc02016fc <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020126e:	450d                	li	a0,3
ffffffffc0201270:	4ad000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201274:	8c2a                	mv	s8,a0
ffffffffc0201276:	46050363          	beqz	a0,ffffffffc02016dc <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020127a:	4505                	li	a0,1
ffffffffc020127c:	4a1000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201280:	42051e63          	bnez	a0,ffffffffc02016bc <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201284:	418a1c63          	bne	s4,s8,ffffffffc020169c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201288:	4585                	li	a1,1
ffffffffc020128a:	854e                	mv	a0,s3
ffffffffc020128c:	4cf000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_pages(p1, 3);
ffffffffc0201290:	458d                	li	a1,3
ffffffffc0201292:	8552                	mv	a0,s4
ffffffffc0201294:	4c7000ef          	jal	ra,ffffffffc0201f5a <free_pages>
ffffffffc0201298:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020129c:	04098c13          	addi	s8,s3,64
ffffffffc02012a0:	8385                	srli	a5,a5,0x1
ffffffffc02012a2:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012a4:	3c078c63          	beqz	a5,ffffffffc020167c <default_check+0x602>
ffffffffc02012a8:	0109a703          	lw	a4,16(s3)
ffffffffc02012ac:	4785                	li	a5,1
ffffffffc02012ae:	3cf71763          	bne	a4,a5,ffffffffc020167c <default_check+0x602>
ffffffffc02012b2:	008a3783          	ld	a5,8(s4)
ffffffffc02012b6:	8385                	srli	a5,a5,0x1
ffffffffc02012b8:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012ba:	3a078163          	beqz	a5,ffffffffc020165c <default_check+0x5e2>
ffffffffc02012be:	010a2703          	lw	a4,16(s4)
ffffffffc02012c2:	478d                	li	a5,3
ffffffffc02012c4:	38f71c63          	bne	a4,a5,ffffffffc020165c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012c8:	4505                	li	a0,1
ffffffffc02012ca:	453000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02012ce:	36a99763          	bne	s3,a0,ffffffffc020163c <default_check+0x5c2>
    free_page(p0);
ffffffffc02012d2:	4585                	li	a1,1
ffffffffc02012d4:	487000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012d8:	4509                	li	a0,2
ffffffffc02012da:	443000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02012de:	32aa1f63          	bne	s4,a0,ffffffffc020161c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02012e2:	4589                	li	a1,2
ffffffffc02012e4:	477000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    free_page(p2);
ffffffffc02012e8:	4585                	li	a1,1
ffffffffc02012ea:	8562                	mv	a0,s8
ffffffffc02012ec:	46f000ef          	jal	ra,ffffffffc0201f5a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012f0:	4515                	li	a0,5
ffffffffc02012f2:	42b000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc02012f6:	89aa                	mv	s3,a0
ffffffffc02012f8:	48050263          	beqz	a0,ffffffffc020177c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02012fc:	4505                	li	a0,1
ffffffffc02012fe:	41f000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0201302:	2c051d63          	bnez	a0,ffffffffc02015dc <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201306:	481c                	lw	a5,16(s0)
ffffffffc0201308:	2a079a63          	bnez	a5,ffffffffc02015bc <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020130c:	4595                	li	a1,5
ffffffffc020130e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201310:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201314:	01643023          	sd	s6,0(s0)
ffffffffc0201318:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020131c:	43f000ef          	jal	ra,ffffffffc0201f5a <free_pages>
    return listelm->next;
ffffffffc0201320:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201322:	00878963          	beq	a5,s0,ffffffffc0201334 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201326:	ff87a703          	lw	a4,-8(a5)
ffffffffc020132a:	679c                	ld	a5,8(a5)
ffffffffc020132c:	397d                	addiw	s2,s2,-1
ffffffffc020132e:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201330:	fe879be3          	bne	a5,s0,ffffffffc0201326 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201334:	26091463          	bnez	s2,ffffffffc020159c <default_check+0x522>
    assert(total == 0);
ffffffffc0201338:	46049263          	bnez	s1,ffffffffc020179c <default_check+0x722>
}
ffffffffc020133c:	60a6                	ld	ra,72(sp)
ffffffffc020133e:	6406                	ld	s0,64(sp)
ffffffffc0201340:	74e2                	ld	s1,56(sp)
ffffffffc0201342:	7942                	ld	s2,48(sp)
ffffffffc0201344:	79a2                	ld	s3,40(sp)
ffffffffc0201346:	7a02                	ld	s4,32(sp)
ffffffffc0201348:	6ae2                	ld	s5,24(sp)
ffffffffc020134a:	6b42                	ld	s6,16(sp)
ffffffffc020134c:	6ba2                	ld	s7,8(sp)
ffffffffc020134e:	6c02                	ld	s8,0(sp)
ffffffffc0201350:	6161                	addi	sp,sp,80
ffffffffc0201352:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201354:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201356:	4481                	li	s1,0
ffffffffc0201358:	4901                	li	s2,0
ffffffffc020135a:	b38d                	j	ffffffffc02010bc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020135c:	00005697          	auipc	a3,0x5
ffffffffc0201360:	12468693          	addi	a3,a3,292 # ffffffffc0206480 <commands+0x848>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020136c:	11000593          	li	a1,272
ffffffffc0201370:	00005517          	auipc	a0,0x5
ffffffffc0201374:	12050513          	addi	a0,a0,288 # ffffffffc0206490 <commands+0x858>
ffffffffc0201378:	916ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	1ac68693          	addi	a3,a3,428 # ffffffffc0206528 <commands+0x8f0>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	eac60613          	addi	a2,a2,-340 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020138c:	0db00593          	li	a1,219
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	10050513          	addi	a0,a0,256 # ffffffffc0206490 <commands+0x858>
ffffffffc0201398:	8f6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	1b468693          	addi	a3,a3,436 # ffffffffc0206550 <commands+0x918>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02013ac:	0dc00593          	li	a1,220
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	0e050513          	addi	a0,a0,224 # ffffffffc0206490 <commands+0x858>
ffffffffc02013b8:	8d6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	1d468693          	addi	a3,a3,468 # ffffffffc0206590 <commands+0x958>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02013cc:	0de00593          	li	a1,222
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	0c050513          	addi	a0,a0,192 # ffffffffc0206490 <commands+0x858>
ffffffffc02013d8:	8b6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	23c68693          	addi	a3,a3,572 # ffffffffc0206618 <commands+0x9e0>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02013ec:	0f700593          	li	a1,247
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	0a050513          	addi	a0,a0,160 # ffffffffc0206490 <commands+0x858>
ffffffffc02013f8:	896ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	0cc68693          	addi	a3,a3,204 # ffffffffc02064c8 <commands+0x890>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020140c:	0f000593          	li	a1,240
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	08050513          	addi	a0,a0,128 # ffffffffc0206490 <commands+0x858>
ffffffffc0201418:	876ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	1ec68693          	addi	a3,a3,492 # ffffffffc0206608 <commands+0x9d0>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020142c:	0ee00593          	li	a1,238
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	06050513          	addi	a0,a0,96 # ffffffffc0206490 <commands+0x858>
ffffffffc0201438:	856ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	1b468693          	addi	a3,a3,436 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	dec60613          	addi	a2,a2,-532 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020144c:	0e900593          	li	a1,233
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	04050513          	addi	a0,a0,64 # ffffffffc0206490 <commands+0x858>
ffffffffc0201458:	836ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	17468693          	addi	a3,a3,372 # ffffffffc02065d0 <commands+0x998>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020146c:	0e000593          	li	a1,224
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	02050513          	addi	a0,a0,32 # ffffffffc0206490 <commands+0x858>
ffffffffc0201478:	816ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	1e468693          	addi	a3,a3,484 # ffffffffc0206660 <commands+0xa28>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	dac60613          	addi	a2,a2,-596 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020148c:	11800593          	li	a1,280
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	00050513          	mv	a0,a0
ffffffffc0201498:	ff7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	1b468693          	addi	a3,a3,436 # ffffffffc0206650 <commands+0xa18>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02014ac:	0fd00593          	li	a1,253
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	fe050513          	addi	a0,a0,-32 # ffffffffc0206490 <commands+0x858>
ffffffffc02014b8:	fd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	13468693          	addi	a3,a3,308 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02014cc:	0fb00593          	li	a1,251
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	fc050513          	addi	a0,a0,-64 # ffffffffc0206490 <commands+0x858>
ffffffffc02014d8:	fb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	15468693          	addi	a3,a3,340 # ffffffffc0206630 <commands+0x9f8>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02014ec:	0fa00593          	li	a1,250
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	fa050513          	addi	a0,a0,-96 # ffffffffc0206490 <commands+0x858>
ffffffffc02014f8:	f97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	fcc68693          	addi	a3,a3,-52 # ffffffffc02064c8 <commands+0x890>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020150c:	0d700593          	li	a1,215
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	f8050513          	addi	a0,a0,-128 # ffffffffc0206490 <commands+0x858>
ffffffffc0201518:	f77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	0d468693          	addi	a3,a3,212 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020152c:	0f400593          	li	a1,244
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	f6050513          	addi	a0,a0,-160 # ffffffffc0206490 <commands+0x858>
ffffffffc0201538:	f57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	fcc68693          	addi	a3,a3,-52 # ffffffffc0206508 <commands+0x8d0>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	cec60613          	addi	a2,a2,-788 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020154c:	0f200593          	li	a1,242
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	f4050513          	addi	a0,a0,-192 # ffffffffc0206490 <commands+0x858>
ffffffffc0201558:	f37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	f8c68693          	addi	a3,a3,-116 # ffffffffc02064e8 <commands+0x8b0>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020156c:	0f100593          	li	a1,241
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	f2050513          	addi	a0,a0,-224 # ffffffffc0206490 <commands+0x858>
ffffffffc0201578:	f17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	f8c68693          	addi	a3,a3,-116 # ffffffffc0206508 <commands+0x8d0>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	cac60613          	addi	a2,a2,-852 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020158c:	0d900593          	li	a1,217
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	f0050513          	addi	a0,a0,-256 # ffffffffc0206490 <commands+0x858>
ffffffffc0201598:	ef7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	21468693          	addi	a3,a3,532 # ffffffffc02067b0 <commands+0xb78>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02015ac:	14600593          	li	a1,326
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	ee050513          	addi	a0,a0,-288 # ffffffffc0206490 <commands+0x858>
ffffffffc02015b8:	ed7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	09468693          	addi	a3,a3,148 # ffffffffc0206650 <commands+0xa18>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02015cc:	13a00593          	li	a1,314
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	ec050513          	addi	a0,a0,-320 # ffffffffc0206490 <commands+0x858>
ffffffffc02015d8:	eb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	01468693          	addi	a3,a3,20 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02015ec:	13800593          	li	a1,312
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	ea050513          	addi	a0,a0,-352 # ffffffffc0206490 <commands+0x858>
ffffffffc02015f8:	e97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	fb468693          	addi	a3,a3,-76 # ffffffffc02065b0 <commands+0x978>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	c2c60613          	addi	a2,a2,-980 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020160c:	0df00593          	li	a1,223
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	e8050513          	addi	a0,a0,-384 # ffffffffc0206490 <commands+0x858>
ffffffffc0201618:	e77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	15468693          	addi	a3,a3,340 # ffffffffc0206770 <commands+0xb38>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	c0c60613          	addi	a2,a2,-1012 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020162c:	13200593          	li	a1,306
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	e6050513          	addi	a0,a0,-416 # ffffffffc0206490 <commands+0x858>
ffffffffc0201638:	e57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	11468693          	addi	a3,a3,276 # ffffffffc0206750 <commands+0xb18>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	bec60613          	addi	a2,a2,-1044 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020164c:	13000593          	li	a1,304
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	e4050513          	addi	a0,a0,-448 # ffffffffc0206490 <commands+0x858>
ffffffffc0201658:	e37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	0cc68693          	addi	a3,a3,204 # ffffffffc0206728 <commands+0xaf0>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020166c:	12e00593          	li	a1,302
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	e2050513          	addi	a0,a0,-480 # ffffffffc0206490 <commands+0x858>
ffffffffc0201678:	e17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	08468693          	addi	a3,a3,132 # ffffffffc0206700 <commands+0xac8>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	bac60613          	addi	a2,a2,-1108 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020168c:	12d00593          	li	a1,301
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	e0050513          	addi	a0,a0,-512 # ffffffffc0206490 <commands+0x858>
ffffffffc0201698:	df7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	05468693          	addi	a3,a3,84 # ffffffffc02066f0 <commands+0xab8>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02016ac:	12800593          	li	a1,296
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	de050513          	addi	a0,a0,-544 # ffffffffc0206490 <commands+0x858>
ffffffffc02016b8:	dd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	f3468693          	addi	a3,a3,-204 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02016cc:	12700593          	li	a1,295
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	dc050513          	addi	a0,a0,-576 # ffffffffc0206490 <commands+0x858>
ffffffffc02016d8:	db7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	ff468693          	addi	a3,a3,-12 # ffffffffc02066d0 <commands+0xa98>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02016ec:	12600593          	li	a1,294
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	da050513          	addi	a0,a0,-608 # ffffffffc0206490 <commands+0x858>
ffffffffc02016f8:	d97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	fa468693          	addi	a3,a3,-92 # ffffffffc02066a0 <commands+0xa68>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020170c:	12500593          	li	a1,293
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	d8050513          	addi	a0,a0,-640 # ffffffffc0206490 <commands+0x858>
ffffffffc0201718:	d77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	f6c68693          	addi	a3,a3,-148 # ffffffffc0206688 <commands+0xa50>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020172c:	12400593          	li	a1,292
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	d6050513          	addi	a0,a0,-672 # ffffffffc0206490 <commands+0x858>
ffffffffc0201738:	d57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020173c:	00005697          	auipc	a3,0x5
ffffffffc0201740:	eb468693          	addi	a3,a3,-332 # ffffffffc02065f0 <commands+0x9b8>
ffffffffc0201744:	00005617          	auipc	a2,0x5
ffffffffc0201748:	aec60613          	addi	a2,a2,-1300 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020174c:	11e00593          	li	a1,286
ffffffffc0201750:	00005517          	auipc	a0,0x5
ffffffffc0201754:	d4050513          	addi	a0,a0,-704 # ffffffffc0206490 <commands+0x858>
ffffffffc0201758:	d37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020175c:	00005697          	auipc	a3,0x5
ffffffffc0201760:	f1468693          	addi	a3,a3,-236 # ffffffffc0206670 <commands+0xa38>
ffffffffc0201764:	00005617          	auipc	a2,0x5
ffffffffc0201768:	acc60613          	addi	a2,a2,-1332 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020176c:	11900593          	li	a1,281
ffffffffc0201770:	00005517          	auipc	a0,0x5
ffffffffc0201774:	d2050513          	addi	a0,a0,-736 # ffffffffc0206490 <commands+0x858>
ffffffffc0201778:	d17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020177c:	00005697          	auipc	a3,0x5
ffffffffc0201780:	01468693          	addi	a3,a3,20 # ffffffffc0206790 <commands+0xb58>
ffffffffc0201784:	00005617          	auipc	a2,0x5
ffffffffc0201788:	aac60613          	addi	a2,a2,-1364 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020178c:	13700593          	li	a1,311
ffffffffc0201790:	00005517          	auipc	a0,0x5
ffffffffc0201794:	d0050513          	addi	a0,a0,-768 # ffffffffc0206490 <commands+0x858>
ffffffffc0201798:	cf7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020179c:	00005697          	auipc	a3,0x5
ffffffffc02017a0:	02468693          	addi	a3,a3,36 # ffffffffc02067c0 <commands+0xb88>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	a8c60613          	addi	a2,a2,-1396 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02017ac:	14700593          	li	a1,327
ffffffffc02017b0:	00005517          	auipc	a0,0x5
ffffffffc02017b4:	ce050513          	addi	a0,a0,-800 # ffffffffc0206490 <commands+0x858>
ffffffffc02017b8:	cd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc02017bc:	00005697          	auipc	a3,0x5
ffffffffc02017c0:	cec68693          	addi	a3,a3,-788 # ffffffffc02064a8 <commands+0x870>
ffffffffc02017c4:	00005617          	auipc	a2,0x5
ffffffffc02017c8:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02017cc:	11300593          	li	a1,275
ffffffffc02017d0:	00005517          	auipc	a0,0x5
ffffffffc02017d4:	cc050513          	addi	a0,a0,-832 # ffffffffc0206490 <commands+0x858>
ffffffffc02017d8:	cb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02017dc:	00005697          	auipc	a3,0x5
ffffffffc02017e0:	d0c68693          	addi	a3,a3,-756 # ffffffffc02064e8 <commands+0x8b0>
ffffffffc02017e4:	00005617          	auipc	a2,0x5
ffffffffc02017e8:	a4c60613          	addi	a2,a2,-1460 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02017ec:	0d800593          	li	a1,216
ffffffffc02017f0:	00005517          	auipc	a0,0x5
ffffffffc02017f4:	ca050513          	addi	a0,a0,-864 # ffffffffc0206490 <commands+0x858>
ffffffffc02017f8:	c97fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02017fc <default_free_pages>:
{
ffffffffc02017fc:	1141                	addi	sp,sp,-16
ffffffffc02017fe:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201800:	14058463          	beqz	a1,ffffffffc0201948 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201804:	00659693          	slli	a3,a1,0x6
ffffffffc0201808:	96aa                	add	a3,a3,a0
ffffffffc020180a:	87aa                	mv	a5,a0
ffffffffc020180c:	02d50263          	beq	a0,a3,ffffffffc0201830 <default_free_pages+0x34>
ffffffffc0201810:	6798                	ld	a4,8(a5)
ffffffffc0201812:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201814:	10071a63          	bnez	a4,ffffffffc0201928 <default_free_pages+0x12c>
ffffffffc0201818:	6798                	ld	a4,8(a5)
ffffffffc020181a:	8b09                	andi	a4,a4,2
ffffffffc020181c:	10071663          	bnez	a4,ffffffffc0201928 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201820:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201824:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201828:	04078793          	addi	a5,a5,64
ffffffffc020182c:	fed792e3          	bne	a5,a3,ffffffffc0201810 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201830:	2581                	sext.w	a1,a1
ffffffffc0201832:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201834:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201838:	4789                	li	a5,2
ffffffffc020183a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020183e:	000af697          	auipc	a3,0xaf
ffffffffc0201842:	77a68693          	addi	a3,a3,1914 # ffffffffc02b0fb8 <free_area>
ffffffffc0201846:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201848:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020184a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020184e:	9db9                	addw	a1,a1,a4
ffffffffc0201850:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201852:	0ad78463          	beq	a5,a3,ffffffffc02018fa <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201856:	fe878713          	addi	a4,a5,-24
ffffffffc020185a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020185e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201860:	00e56a63          	bltu	a0,a4,ffffffffc0201874 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201864:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201866:	04d70c63          	beq	a4,a3,ffffffffc02018be <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020186a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020186c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201870:	fee57ae3          	bgeu	a0,a4,ffffffffc0201864 <default_free_pages+0x68>
ffffffffc0201874:	c199                	beqz	a1,ffffffffc020187a <default_free_pages+0x7e>
ffffffffc0201876:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020187a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020187c:	e390                	sd	a2,0(a5)
ffffffffc020187e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201880:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201882:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201884:	00d70d63          	beq	a4,a3,ffffffffc020189e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201888:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020188c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201890:	02059813          	slli	a6,a1,0x20
ffffffffc0201894:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201898:	97b2                	add	a5,a5,a2
ffffffffc020189a:	02f50c63          	beq	a0,a5,ffffffffc02018d2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020189e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02018a0:	00d78c63          	beq	a5,a3,ffffffffc02018b8 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02018a4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02018a6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02018aa:	02061593          	slli	a1,a2,0x20
ffffffffc02018ae:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02018b2:	972a                	add	a4,a4,a0
ffffffffc02018b4:	04e68a63          	beq	a3,a4,ffffffffc0201908 <default_free_pages+0x10c>
}
ffffffffc02018b8:	60a2                	ld	ra,8(sp)
ffffffffc02018ba:	0141                	addi	sp,sp,16
ffffffffc02018bc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018c0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018c2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018c4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018c6:	02d70763          	beq	a4,a3,ffffffffc02018f4 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02018ca:	8832                	mv	a6,a2
ffffffffc02018cc:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018ce:	87ba                	mv	a5,a4
ffffffffc02018d0:	bf71                	j	ffffffffc020186c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02018d2:	491c                	lw	a5,16(a0)
ffffffffc02018d4:	9dbd                	addw	a1,a1,a5
ffffffffc02018d6:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02018da:	57f5                	li	a5,-3
ffffffffc02018dc:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e0:	01853803          	ld	a6,24(a0)
ffffffffc02018e4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02018e6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02018e8:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02018ec:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018ee:	0105b023          	sd	a6,0(a1)
ffffffffc02018f2:	b77d                	j	ffffffffc02018a0 <default_free_pages+0xa4>
ffffffffc02018f4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018f6:	873e                	mv	a4,a5
ffffffffc02018f8:	bf41                	j	ffffffffc0201888 <default_free_pages+0x8c>
}
ffffffffc02018fa:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018fc:	e390                	sd	a2,0(a5)
ffffffffc02018fe:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201900:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201902:	ed1c                	sd	a5,24(a0)
ffffffffc0201904:	0141                	addi	sp,sp,16
ffffffffc0201906:	8082                	ret
            base->property += p->property;
ffffffffc0201908:	ff87a703          	lw	a4,-8(a5)
ffffffffc020190c:	ff078693          	addi	a3,a5,-16
ffffffffc0201910:	9e39                	addw	a2,a2,a4
ffffffffc0201912:	c910                	sw	a2,16(a0)
ffffffffc0201914:	5775                	li	a4,-3
ffffffffc0201916:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020191a:	6398                	ld	a4,0(a5)
ffffffffc020191c:	679c                	ld	a5,8(a5)
}
ffffffffc020191e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201920:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201922:	e398                	sd	a4,0(a5)
ffffffffc0201924:	0141                	addi	sp,sp,16
ffffffffc0201926:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201928:	00005697          	auipc	a3,0x5
ffffffffc020192c:	eb068693          	addi	a3,a3,-336 # ffffffffc02067d8 <commands+0xba0>
ffffffffc0201930:	00005617          	auipc	a2,0x5
ffffffffc0201934:	90060613          	addi	a2,a2,-1792 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201938:	09400593          	li	a1,148
ffffffffc020193c:	00005517          	auipc	a0,0x5
ffffffffc0201940:	b5450513          	addi	a0,a0,-1196 # ffffffffc0206490 <commands+0x858>
ffffffffc0201944:	b4bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201948:	00005697          	auipc	a3,0x5
ffffffffc020194c:	e8868693          	addi	a3,a3,-376 # ffffffffc02067d0 <commands+0xb98>
ffffffffc0201950:	00005617          	auipc	a2,0x5
ffffffffc0201954:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201958:	09000593          	li	a1,144
ffffffffc020195c:	00005517          	auipc	a0,0x5
ffffffffc0201960:	b3450513          	addi	a0,a0,-1228 # ffffffffc0206490 <commands+0x858>
ffffffffc0201964:	b2bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201968 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201968:	c941                	beqz	a0,ffffffffc02019f8 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020196a:	000af597          	auipc	a1,0xaf
ffffffffc020196e:	64e58593          	addi	a1,a1,1614 # ffffffffc02b0fb8 <free_area>
ffffffffc0201972:	0105a803          	lw	a6,16(a1)
ffffffffc0201976:	872a                	mv	a4,a0
ffffffffc0201978:	02081793          	slli	a5,a6,0x20
ffffffffc020197c:	9381                	srli	a5,a5,0x20
ffffffffc020197e:	00a7ee63          	bltu	a5,a0,ffffffffc020199a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201982:	87ae                	mv	a5,a1
ffffffffc0201984:	a801                	j	ffffffffc0201994 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201986:	ff87a683          	lw	a3,-8(a5)
ffffffffc020198a:	02069613          	slli	a2,a3,0x20
ffffffffc020198e:	9201                	srli	a2,a2,0x20
ffffffffc0201990:	00e67763          	bgeu	a2,a4,ffffffffc020199e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201994:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201996:	feb798e3          	bne	a5,a1,ffffffffc0201986 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020199a:	4501                	li	a0,0
}
ffffffffc020199c:	8082                	ret
    return listelm->prev;
ffffffffc020199e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02019a2:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02019a6:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02019aa:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02019ae:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02019b2:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02019b6:	02c77863          	bgeu	a4,a2,ffffffffc02019e6 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02019ba:	071a                	slli	a4,a4,0x6
ffffffffc02019bc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02019be:	41c686bb          	subw	a3,a3,t3
ffffffffc02019c2:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019c4:	00870613          	addi	a2,a4,8
ffffffffc02019c8:	4689                	li	a3,2
ffffffffc02019ca:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02019ce:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02019d2:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02019d6:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02019da:	e290                	sd	a2,0(a3)
ffffffffc02019dc:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02019e0:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02019e2:	01173c23          	sd	a7,24(a4)
ffffffffc02019e6:	41c8083b          	subw	a6,a6,t3
ffffffffc02019ea:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019ee:	5775                	li	a4,-3
ffffffffc02019f0:	17c1                	addi	a5,a5,-16
ffffffffc02019f2:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019f6:	8082                	ret
{
ffffffffc02019f8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019fa:	00005697          	auipc	a3,0x5
ffffffffc02019fe:	dd668693          	addi	a3,a3,-554 # ffffffffc02067d0 <commands+0xb98>
ffffffffc0201a02:	00005617          	auipc	a2,0x5
ffffffffc0201a06:	82e60613          	addi	a2,a2,-2002 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201a0a:	06c00593          	li	a1,108
ffffffffc0201a0e:	00005517          	auipc	a0,0x5
ffffffffc0201a12:	a8250513          	addi	a0,a0,-1406 # ffffffffc0206490 <commands+0x858>
{
ffffffffc0201a16:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a18:	a77fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a1c <default_init_memmap>:
{
ffffffffc0201a1c:	1141                	addi	sp,sp,-16
ffffffffc0201a1e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201a20:	c5f1                	beqz	a1,ffffffffc0201aec <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc0201a22:	00659693          	slli	a3,a1,0x6
ffffffffc0201a26:	96aa                	add	a3,a3,a0
ffffffffc0201a28:	87aa                	mv	a5,a0
ffffffffc0201a2a:	00d50f63          	beq	a0,a3,ffffffffc0201a48 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201a2e:	6798                	ld	a4,8(a5)
ffffffffc0201a30:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201a32:	cf49                	beqz	a4,ffffffffc0201acc <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201a34:	0007a823          	sw	zero,16(a5)
ffffffffc0201a38:	0007b423          	sd	zero,8(a5)
ffffffffc0201a3c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a40:	04078793          	addi	a5,a5,64
ffffffffc0201a44:	fed795e3          	bne	a5,a3,ffffffffc0201a2e <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a48:	2581                	sext.w	a1,a1
ffffffffc0201a4a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a4c:	4789                	li	a5,2
ffffffffc0201a4e:	00850713          	addi	a4,a0,8
ffffffffc0201a52:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a56:	000af697          	auipc	a3,0xaf
ffffffffc0201a5a:	56268693          	addi	a3,a3,1378 # ffffffffc02b0fb8 <free_area>
ffffffffc0201a5e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a60:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a62:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a66:	9db9                	addw	a1,a1,a4
ffffffffc0201a68:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a6a:	04d78a63          	beq	a5,a3,ffffffffc0201abe <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a6e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a72:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a76:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a78:	00e56a63          	bltu	a0,a4,ffffffffc0201a8c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a7c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a7e:	02d70263          	beq	a4,a3,ffffffffc0201aa2 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a82:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a84:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a88:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a7c <default_init_memmap+0x60>
ffffffffc0201a8c:	c199                	beqz	a1,ffffffffc0201a92 <default_init_memmap+0x76>
ffffffffc0201a8e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a92:	6398                	ld	a4,0(a5)
}
ffffffffc0201a94:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a96:	e390                	sd	a2,0(a5)
ffffffffc0201a98:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a9a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a9c:	ed18                	sd	a4,24(a0)
ffffffffc0201a9e:	0141                	addi	sp,sp,16
ffffffffc0201aa0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201aa2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201aa4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201aa6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201aa8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201aaa:	00d70663          	beq	a4,a3,ffffffffc0201ab6 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201aae:	8832                	mv	a6,a2
ffffffffc0201ab0:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201ab2:	87ba                	mv	a5,a4
ffffffffc0201ab4:	bfc1                	j	ffffffffc0201a84 <default_init_memmap+0x68>
}
ffffffffc0201ab6:	60a2                	ld	ra,8(sp)
ffffffffc0201ab8:	e290                	sd	a2,0(a3)
ffffffffc0201aba:	0141                	addi	sp,sp,16
ffffffffc0201abc:	8082                	ret
ffffffffc0201abe:	60a2                	ld	ra,8(sp)
ffffffffc0201ac0:	e390                	sd	a2,0(a5)
ffffffffc0201ac2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201ac4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201ac6:	ed1c                	sd	a5,24(a0)
ffffffffc0201ac8:	0141                	addi	sp,sp,16
ffffffffc0201aca:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201acc:	00005697          	auipc	a3,0x5
ffffffffc0201ad0:	d3468693          	addi	a3,a3,-716 # ffffffffc0206800 <commands+0xbc8>
ffffffffc0201ad4:	00004617          	auipc	a2,0x4
ffffffffc0201ad8:	75c60613          	addi	a2,a2,1884 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201adc:	04b00593          	li	a1,75
ffffffffc0201ae0:	00005517          	auipc	a0,0x5
ffffffffc0201ae4:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206490 <commands+0x858>
ffffffffc0201ae8:	9a7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201aec:	00005697          	auipc	a3,0x5
ffffffffc0201af0:	ce468693          	addi	a3,a3,-796 # ffffffffc02067d0 <commands+0xb98>
ffffffffc0201af4:	00004617          	auipc	a2,0x4
ffffffffc0201af8:	73c60613          	addi	a2,a2,1852 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201afc:	04700593          	li	a1,71
ffffffffc0201b00:	00005517          	auipc	a0,0x5
ffffffffc0201b04:	99050513          	addi	a0,a0,-1648 # ffffffffc0206490 <commands+0x858>
ffffffffc0201b08:	987fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201b0c <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201b0c:	c94d                	beqz	a0,ffffffffc0201bbe <slob_free+0xb2>
{
ffffffffc0201b0e:	1141                	addi	sp,sp,-16
ffffffffc0201b10:	e022                	sd	s0,0(sp)
ffffffffc0201b12:	e406                	sd	ra,8(sp)
ffffffffc0201b14:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201b16:	e9c1                	bnez	a1,ffffffffc0201ba6 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b18:	100027f3          	csrr	a5,sstatus
ffffffffc0201b1c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b1e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b20:	ebd9                	bnez	a5,ffffffffc0201bb6 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b22:	000af617          	auipc	a2,0xaf
ffffffffc0201b26:	08660613          	addi	a2,a2,134 # ffffffffc02b0ba8 <slobfree>
ffffffffc0201b2a:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b2c:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b2e:	679c                	ld	a5,8(a5)
ffffffffc0201b30:	02877a63          	bgeu	a4,s0,ffffffffc0201b64 <slob_free+0x58>
ffffffffc0201b34:	00f46463          	bltu	s0,a5,ffffffffc0201b3c <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b38:	fef76ae3          	bltu	a4,a5,ffffffffc0201b2c <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201b3c:	400c                	lw	a1,0(s0)
ffffffffc0201b3e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b42:	96a2                	add	a3,a3,s0
ffffffffc0201b44:	02d78a63          	beq	a5,a3,ffffffffc0201b78 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b48:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b4a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b4c:	00469793          	slli	a5,a3,0x4
ffffffffc0201b50:	97ba                	add	a5,a5,a4
ffffffffc0201b52:	02f40e63          	beq	s0,a5,ffffffffc0201b8e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b56:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b58:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b5a:	e129                	bnez	a0,ffffffffc0201b9c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b5c:	60a2                	ld	ra,8(sp)
ffffffffc0201b5e:	6402                	ld	s0,0(sp)
ffffffffc0201b60:	0141                	addi	sp,sp,16
ffffffffc0201b62:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b64:	fcf764e3          	bltu	a4,a5,ffffffffc0201b2c <slob_free+0x20>
ffffffffc0201b68:	fcf472e3          	bgeu	s0,a5,ffffffffc0201b2c <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b6c:	400c                	lw	a1,0(s0)
ffffffffc0201b6e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b72:	96a2                	add	a3,a3,s0
ffffffffc0201b74:	fcd79ae3          	bne	a5,a3,ffffffffc0201b48 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b78:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b7a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b7c:	9db5                	addw	a1,a1,a3
ffffffffc0201b7e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b80:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b82:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b84:	00469793          	slli	a5,a3,0x4
ffffffffc0201b88:	97ba                	add	a5,a5,a4
ffffffffc0201b8a:	fcf416e3          	bne	s0,a5,ffffffffc0201b56 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b8e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b90:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b92:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b94:	9ebd                	addw	a3,a3,a5
ffffffffc0201b96:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b98:	e70c                	sd	a1,8(a4)
ffffffffc0201b9a:	d169                	beqz	a0,ffffffffc0201b5c <slob_free+0x50>
}
ffffffffc0201b9c:	6402                	ld	s0,0(sp)
ffffffffc0201b9e:	60a2                	ld	ra,8(sp)
ffffffffc0201ba0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201ba2:	e0dfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201ba6:	25bd                	addiw	a1,a1,15
ffffffffc0201ba8:	8191                	srli	a1,a1,0x4
ffffffffc0201baa:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bac:	100027f3          	csrr	a5,sstatus
ffffffffc0201bb0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201bb2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bb4:	d7bd                	beqz	a5,ffffffffc0201b22 <slob_free+0x16>
        intr_disable();
ffffffffc0201bb6:	dfffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201bba:	4505                	li	a0,1
ffffffffc0201bbc:	b79d                	j	ffffffffc0201b22 <slob_free+0x16>
ffffffffc0201bbe:	8082                	ret

ffffffffc0201bc0 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bc0:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bc2:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bc4:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bc8:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bca:	352000ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
	if (!page)
ffffffffc0201bce:	c91d                	beqz	a0,ffffffffc0201c04 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bd0:	000b3697          	auipc	a3,0xb3
ffffffffc0201bd4:	4586b683          	ld	a3,1112(a3) # ffffffffc02b5028 <pages>
ffffffffc0201bd8:	8d15                	sub	a0,a0,a3
ffffffffc0201bda:	8519                	srai	a0,a0,0x6
ffffffffc0201bdc:	00006697          	auipc	a3,0x6
ffffffffc0201be0:	0f46b683          	ld	a3,244(a3) # ffffffffc0207cd0 <nbase>
ffffffffc0201be4:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201be6:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bea:	83b1                	srli	a5,a5,0xc
ffffffffc0201bec:	000b3717          	auipc	a4,0xb3
ffffffffc0201bf0:	43473703          	ld	a4,1076(a4) # ffffffffc02b5020 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bf4:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bf6:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c0a <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bfa:	000b3697          	auipc	a3,0xb3
ffffffffc0201bfe:	43e6b683          	ld	a3,1086(a3) # ffffffffc02b5038 <va_pa_offset>
ffffffffc0201c02:	9536                	add	a0,a0,a3
}
ffffffffc0201c04:	60a2                	ld	ra,8(sp)
ffffffffc0201c06:	0141                	addi	sp,sp,16
ffffffffc0201c08:	8082                	ret
ffffffffc0201c0a:	86aa                	mv	a3,a0
ffffffffc0201c0c:	00005617          	auipc	a2,0x5
ffffffffc0201c10:	c5460613          	addi	a2,a2,-940 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc0201c14:	07100593          	li	a1,113
ffffffffc0201c18:	00005517          	auipc	a0,0x5
ffffffffc0201c1c:	c7050513          	addi	a0,a0,-912 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0201c20:	86ffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c24 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c24:	1101                	addi	sp,sp,-32
ffffffffc0201c26:	ec06                	sd	ra,24(sp)
ffffffffc0201c28:	e822                	sd	s0,16(sp)
ffffffffc0201c2a:	e426                	sd	s1,8(sp)
ffffffffc0201c2c:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c2e:	01050713          	addi	a4,a0,16
ffffffffc0201c32:	6785                	lui	a5,0x1
ffffffffc0201c34:	0cf77363          	bgeu	a4,a5,ffffffffc0201cfa <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c38:	00f50493          	addi	s1,a0,15
ffffffffc0201c3c:	8091                	srli	s1,s1,0x4
ffffffffc0201c3e:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c40:	10002673          	csrr	a2,sstatus
ffffffffc0201c44:	8a09                	andi	a2,a2,2
ffffffffc0201c46:	e25d                	bnez	a2,ffffffffc0201cec <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c48:	000af917          	auipc	s2,0xaf
ffffffffc0201c4c:	f6090913          	addi	s2,s2,-160 # ffffffffc02b0ba8 <slobfree>
ffffffffc0201c50:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c54:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c56:	4398                	lw	a4,0(a5)
ffffffffc0201c58:	08975e63          	bge	a4,s1,ffffffffc0201cf4 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c5c:	00f68b63          	beq	a3,a5,ffffffffc0201c72 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c60:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c62:	4018                	lw	a4,0(s0)
ffffffffc0201c64:	02975a63          	bge	a4,s1,ffffffffc0201c98 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c68:	00093683          	ld	a3,0(s2)
ffffffffc0201c6c:	87a2                	mv	a5,s0
ffffffffc0201c6e:	fef699e3          	bne	a3,a5,ffffffffc0201c60 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c72:	ee31                	bnez	a2,ffffffffc0201cce <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c74:	4501                	li	a0,0
ffffffffc0201c76:	f4bff0ef          	jal	ra,ffffffffc0201bc0 <__slob_get_free_pages.constprop.0>
ffffffffc0201c7a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c7c:	cd05                	beqz	a0,ffffffffc0201cb4 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c7e:	6585                	lui	a1,0x1
ffffffffc0201c80:	e8dff0ef          	jal	ra,ffffffffc0201b0c <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c84:	10002673          	csrr	a2,sstatus
ffffffffc0201c88:	8a09                	andi	a2,a2,2
ffffffffc0201c8a:	ee05                	bnez	a2,ffffffffc0201cc2 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c8c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c90:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c92:	4018                	lw	a4,0(s0)
ffffffffc0201c94:	fc974ae3          	blt	a4,s1,ffffffffc0201c68 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c98:	04e48763          	beq	s1,a4,ffffffffc0201ce6 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c9c:	00449693          	slli	a3,s1,0x4
ffffffffc0201ca0:	96a2                	add	a3,a3,s0
ffffffffc0201ca2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201ca4:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201ca6:	9f05                	subw	a4,a4,s1
ffffffffc0201ca8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201caa:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201cac:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201cae:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201cb2:	e20d                	bnez	a2,ffffffffc0201cd4 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201cb4:	60e2                	ld	ra,24(sp)
ffffffffc0201cb6:	8522                	mv	a0,s0
ffffffffc0201cb8:	6442                	ld	s0,16(sp)
ffffffffc0201cba:	64a2                	ld	s1,8(sp)
ffffffffc0201cbc:	6902                	ld	s2,0(sp)
ffffffffc0201cbe:	6105                	addi	sp,sp,32
ffffffffc0201cc0:	8082                	ret
        intr_disable();
ffffffffc0201cc2:	cf3fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201cc6:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201cca:	4605                	li	a2,1
ffffffffc0201ccc:	b7d1                	j	ffffffffc0201c90 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201cce:	ce1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201cd2:	b74d                	j	ffffffffc0201c74 <slob_alloc.constprop.0+0x50>
ffffffffc0201cd4:	cdbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201cd8:	60e2                	ld	ra,24(sp)
ffffffffc0201cda:	8522                	mv	a0,s0
ffffffffc0201cdc:	6442                	ld	s0,16(sp)
ffffffffc0201cde:	64a2                	ld	s1,8(sp)
ffffffffc0201ce0:	6902                	ld	s2,0(sp)
ffffffffc0201ce2:	6105                	addi	sp,sp,32
ffffffffc0201ce4:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ce6:	6418                	ld	a4,8(s0)
ffffffffc0201ce8:	e798                	sd	a4,8(a5)
ffffffffc0201cea:	b7d1                	j	ffffffffc0201cae <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201cec:	cc9fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201cf0:	4605                	li	a2,1
ffffffffc0201cf2:	bf99                	j	ffffffffc0201c48 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201cf4:	843e                	mv	s0,a5
ffffffffc0201cf6:	87b6                	mv	a5,a3
ffffffffc0201cf8:	b745                	j	ffffffffc0201c98 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cfa:	00005697          	auipc	a3,0x5
ffffffffc0201cfe:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0206898 <default_pmm_manager+0x70>
ffffffffc0201d02:	00004617          	auipc	a2,0x4
ffffffffc0201d06:	52e60613          	addi	a2,a2,1326 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0201d0a:	06300593          	li	a1,99
ffffffffc0201d0e:	00005517          	auipc	a0,0x5
ffffffffc0201d12:	baa50513          	addi	a0,a0,-1110 # ffffffffc02068b8 <default_pmm_manager+0x90>
ffffffffc0201d16:	f78fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201d1a <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d1a:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d1c:	00005517          	auipc	a0,0x5
ffffffffc0201d20:	bb450513          	addi	a0,a0,-1100 # ffffffffc02068d0 <default_pmm_manager+0xa8>
{
ffffffffc0201d24:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d26:	c6efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d2a:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d2c:	00005517          	auipc	a0,0x5
ffffffffc0201d30:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02068e8 <default_pmm_manager+0xc0>
}
ffffffffc0201d34:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d36:	c5efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d3a <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d3a:	4501                	li	a0,0
ffffffffc0201d3c:	8082                	ret

ffffffffc0201d3e <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d3e:	1101                	addi	sp,sp,-32
ffffffffc0201d40:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d42:	6905                	lui	s2,0x1
{
ffffffffc0201d44:	e822                	sd	s0,16(sp)
ffffffffc0201d46:	ec06                	sd	ra,24(sp)
ffffffffc0201d48:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d4a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc1>
{
ffffffffc0201d4e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d50:	04a7f963          	bgeu	a5,a0,ffffffffc0201da2 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d54:	4561                	li	a0,24
ffffffffc0201d56:	ecfff0ef          	jal	ra,ffffffffc0201c24 <slob_alloc.constprop.0>
ffffffffc0201d5a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d5c:	c929                	beqz	a0,ffffffffc0201dae <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d5e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d62:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d64:	00f95763          	bge	s2,a5,ffffffffc0201d72 <kmalloc+0x34>
ffffffffc0201d68:	6705                	lui	a4,0x1
ffffffffc0201d6a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d6c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d6e:	fef74ee3          	blt	a4,a5,ffffffffc0201d6a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d72:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d74:	e4dff0ef          	jal	ra,ffffffffc0201bc0 <__slob_get_free_pages.constprop.0>
ffffffffc0201d78:	e488                	sd	a0,8(s1)
ffffffffc0201d7a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d7c:	c525                	beqz	a0,ffffffffc0201de4 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d7e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d82:	8b89                	andi	a5,a5,2
ffffffffc0201d84:	ef8d                	bnez	a5,ffffffffc0201dbe <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d86:	000b3797          	auipc	a5,0xb3
ffffffffc0201d8a:	28278793          	addi	a5,a5,642 # ffffffffc02b5008 <bigblocks>
ffffffffc0201d8e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d90:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d92:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d94:	60e2                	ld	ra,24(sp)
ffffffffc0201d96:	8522                	mv	a0,s0
ffffffffc0201d98:	6442                	ld	s0,16(sp)
ffffffffc0201d9a:	64a2                	ld	s1,8(sp)
ffffffffc0201d9c:	6902                	ld	s2,0(sp)
ffffffffc0201d9e:	6105                	addi	sp,sp,32
ffffffffc0201da0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201da2:	0541                	addi	a0,a0,16
ffffffffc0201da4:	e81ff0ef          	jal	ra,ffffffffc0201c24 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201da8:	01050413          	addi	s0,a0,16
ffffffffc0201dac:	f565                	bnez	a0,ffffffffc0201d94 <kmalloc+0x56>
ffffffffc0201dae:	4401                	li	s0,0
}
ffffffffc0201db0:	60e2                	ld	ra,24(sp)
ffffffffc0201db2:	8522                	mv	a0,s0
ffffffffc0201db4:	6442                	ld	s0,16(sp)
ffffffffc0201db6:	64a2                	ld	s1,8(sp)
ffffffffc0201db8:	6902                	ld	s2,0(sp)
ffffffffc0201dba:	6105                	addi	sp,sp,32
ffffffffc0201dbc:	8082                	ret
        intr_disable();
ffffffffc0201dbe:	bf7fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201dc2:	000b3797          	auipc	a5,0xb3
ffffffffc0201dc6:	24678793          	addi	a5,a5,582 # ffffffffc02b5008 <bigblocks>
ffffffffc0201dca:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201dcc:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201dce:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201dd0:	bdffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201dd4:	6480                	ld	s0,8(s1)
}
ffffffffc0201dd6:	60e2                	ld	ra,24(sp)
ffffffffc0201dd8:	64a2                	ld	s1,8(sp)
ffffffffc0201dda:	8522                	mv	a0,s0
ffffffffc0201ddc:	6442                	ld	s0,16(sp)
ffffffffc0201dde:	6902                	ld	s2,0(sp)
ffffffffc0201de0:	6105                	addi	sp,sp,32
ffffffffc0201de2:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de4:	45e1                	li	a1,24
ffffffffc0201de6:	8526                	mv	a0,s1
ffffffffc0201de8:	d25ff0ef          	jal	ra,ffffffffc0201b0c <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201dec:	b765                	j	ffffffffc0201d94 <kmalloc+0x56>

ffffffffc0201dee <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201dee:	c169                	beqz	a0,ffffffffc0201eb0 <kfree+0xc2>
{
ffffffffc0201df0:	1101                	addi	sp,sp,-32
ffffffffc0201df2:	e822                	sd	s0,16(sp)
ffffffffc0201df4:	ec06                	sd	ra,24(sp)
ffffffffc0201df6:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201df8:	03451793          	slli	a5,a0,0x34
ffffffffc0201dfc:	842a                	mv	s0,a0
ffffffffc0201dfe:	e3d9                	bnez	a5,ffffffffc0201e84 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e00:	100027f3          	csrr	a5,sstatus
ffffffffc0201e04:	8b89                	andi	a5,a5,2
ffffffffc0201e06:	e7d9                	bnez	a5,ffffffffc0201e94 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e08:	000b3797          	auipc	a5,0xb3
ffffffffc0201e0c:	2007b783          	ld	a5,512(a5) # ffffffffc02b5008 <bigblocks>
    return 0;
ffffffffc0201e10:	4601                	li	a2,0
ffffffffc0201e12:	cbad                	beqz	a5,ffffffffc0201e84 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e14:	000b3697          	auipc	a3,0xb3
ffffffffc0201e18:	1f468693          	addi	a3,a3,500 # ffffffffc02b5008 <bigblocks>
ffffffffc0201e1c:	a021                	j	ffffffffc0201e24 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e1e:	01048693          	addi	a3,s1,16
ffffffffc0201e22:	c3a5                	beqz	a5,ffffffffc0201e82 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201e24:	6798                	ld	a4,8(a5)
ffffffffc0201e26:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201e28:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e2a:	fe871ae3          	bne	a4,s0,ffffffffc0201e1e <kfree+0x30>
				*last = bb->next;
ffffffffc0201e2e:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201e30:	ee2d                	bnez	a2,ffffffffc0201eaa <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201e32:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201e36:	4098                	lw	a4,0(s1)
ffffffffc0201e38:	08f46963          	bltu	s0,a5,ffffffffc0201eca <kfree+0xdc>
ffffffffc0201e3c:	000b3697          	auipc	a3,0xb3
ffffffffc0201e40:	1fc6b683          	ld	a3,508(a3) # ffffffffc02b5038 <va_pa_offset>
ffffffffc0201e44:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e46:	8031                	srli	s0,s0,0xc
ffffffffc0201e48:	000b3797          	auipc	a5,0xb3
ffffffffc0201e4c:	1d87b783          	ld	a5,472(a5) # ffffffffc02b5020 <npage>
ffffffffc0201e50:	06f47163          	bgeu	s0,a5,ffffffffc0201eb2 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e54:	00006517          	auipc	a0,0x6
ffffffffc0201e58:	e7c53503          	ld	a0,-388(a0) # ffffffffc0207cd0 <nbase>
ffffffffc0201e5c:	8c09                	sub	s0,s0,a0
ffffffffc0201e5e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201e60:	000b3517          	auipc	a0,0xb3
ffffffffc0201e64:	1c853503          	ld	a0,456(a0) # ffffffffc02b5028 <pages>
ffffffffc0201e68:	4585                	li	a1,1
ffffffffc0201e6a:	9522                	add	a0,a0,s0
ffffffffc0201e6c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e70:	0ea000ef          	jal	ra,ffffffffc0201f5a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e74:	6442                	ld	s0,16(sp)
ffffffffc0201e76:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e78:	8526                	mv	a0,s1
}
ffffffffc0201e7a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e7c:	45e1                	li	a1,24
}
ffffffffc0201e7e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e80:	b171                	j	ffffffffc0201b0c <slob_free>
ffffffffc0201e82:	e20d                	bnez	a2,ffffffffc0201ea4 <kfree+0xb6>
ffffffffc0201e84:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e88:	6442                	ld	s0,16(sp)
ffffffffc0201e8a:	60e2                	ld	ra,24(sp)
ffffffffc0201e8c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e8e:	4581                	li	a1,0
}
ffffffffc0201e90:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e92:	b9ad                	j	ffffffffc0201b0c <slob_free>
        intr_disable();
ffffffffc0201e94:	b21fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e98:	000b3797          	auipc	a5,0xb3
ffffffffc0201e9c:	1707b783          	ld	a5,368(a5) # ffffffffc02b5008 <bigblocks>
        return 1;
ffffffffc0201ea0:	4605                	li	a2,1
ffffffffc0201ea2:	fbad                	bnez	a5,ffffffffc0201e14 <kfree+0x26>
        intr_enable();
ffffffffc0201ea4:	b0bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201ea8:	bff1                	j	ffffffffc0201e84 <kfree+0x96>
ffffffffc0201eaa:	b05fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201eae:	b751                	j	ffffffffc0201e32 <kfree+0x44>
ffffffffc0201eb0:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201eb2:	00005617          	auipc	a2,0x5
ffffffffc0201eb6:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc0201eba:	06900593          	li	a1,105
ffffffffc0201ebe:	00005517          	auipc	a0,0x5
ffffffffc0201ec2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0201ec6:	dc8fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201eca:	86a2                	mv	a3,s0
ffffffffc0201ecc:	00005617          	auipc	a2,0x5
ffffffffc0201ed0:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc0201ed4:	07700593          	li	a1,119
ffffffffc0201ed8:	00005517          	auipc	a0,0x5
ffffffffc0201edc:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0201ee0:	daefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ee4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ee4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ee6:	00005617          	auipc	a2,0x5
ffffffffc0201eea:	a4a60613          	addi	a2,a2,-1462 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc0201eee:	06900593          	li	a1,105
ffffffffc0201ef2:	00005517          	auipc	a0,0x5
ffffffffc0201ef6:	99650513          	addi	a0,a0,-1642 # ffffffffc0206888 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201efa:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201efc:	d92fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f00 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201f00:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201f02:	00005617          	auipc	a2,0x5
ffffffffc0201f06:	a4e60613          	addi	a2,a2,-1458 # ffffffffc0206950 <default_pmm_manager+0x128>
ffffffffc0201f0a:	07f00593          	li	a1,127
ffffffffc0201f0e:	00005517          	auipc	a0,0x5
ffffffffc0201f12:	97a50513          	addi	a0,a0,-1670 # ffffffffc0206888 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201f16:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201f18:	d76fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201f1c <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f1c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f20:	8b89                	andi	a5,a5,2
ffffffffc0201f22:	e799                	bnez	a5,ffffffffc0201f30 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f24:	000b3797          	auipc	a5,0xb3
ffffffffc0201f28:	10c7b783          	ld	a5,268(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201f2c:	6f9c                	ld	a5,24(a5)
ffffffffc0201f2e:	8782                	jr	a5
{
ffffffffc0201f30:	1141                	addi	sp,sp,-16
ffffffffc0201f32:	e406                	sd	ra,8(sp)
ffffffffc0201f34:	e022                	sd	s0,0(sp)
ffffffffc0201f36:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201f38:	a7dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f3c:	000b3797          	auipc	a5,0xb3
ffffffffc0201f40:	0f47b783          	ld	a5,244(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201f44:	6f9c                	ld	a5,24(a5)
ffffffffc0201f46:	8522                	mv	a0,s0
ffffffffc0201f48:	9782                	jalr	a5
ffffffffc0201f4a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f4c:	a63fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f50:	60a2                	ld	ra,8(sp)
ffffffffc0201f52:	8522                	mv	a0,s0
ffffffffc0201f54:	6402                	ld	s0,0(sp)
ffffffffc0201f56:	0141                	addi	sp,sp,16
ffffffffc0201f58:	8082                	ret

ffffffffc0201f5a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f5a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f5e:	8b89                	andi	a5,a5,2
ffffffffc0201f60:	e799                	bnez	a5,ffffffffc0201f6e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f62:	000b3797          	auipc	a5,0xb3
ffffffffc0201f66:	0ce7b783          	ld	a5,206(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201f6a:	739c                	ld	a5,32(a5)
ffffffffc0201f6c:	8782                	jr	a5
{
ffffffffc0201f6e:	1101                	addi	sp,sp,-32
ffffffffc0201f70:	ec06                	sd	ra,24(sp)
ffffffffc0201f72:	e822                	sd	s0,16(sp)
ffffffffc0201f74:	e426                	sd	s1,8(sp)
ffffffffc0201f76:	842a                	mv	s0,a0
ffffffffc0201f78:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f7a:	a3bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f7e:	000b3797          	auipc	a5,0xb3
ffffffffc0201f82:	0b27b783          	ld	a5,178(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201f86:	739c                	ld	a5,32(a5)
ffffffffc0201f88:	85a6                	mv	a1,s1
ffffffffc0201f8a:	8522                	mv	a0,s0
ffffffffc0201f8c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f8e:	6442                	ld	s0,16(sp)
ffffffffc0201f90:	60e2                	ld	ra,24(sp)
ffffffffc0201f92:	64a2                	ld	s1,8(sp)
ffffffffc0201f94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f96:	a19fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f9a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f9e:	8b89                	andi	a5,a5,2
ffffffffc0201fa0:	e799                	bnez	a5,ffffffffc0201fae <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fa2:	000b3797          	auipc	a5,0xb3
ffffffffc0201fa6:	08e7b783          	ld	a5,142(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201faa:	779c                	ld	a5,40(a5)
ffffffffc0201fac:	8782                	jr	a5
{
ffffffffc0201fae:	1141                	addi	sp,sp,-16
ffffffffc0201fb0:	e406                	sd	ra,8(sp)
ffffffffc0201fb2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201fb4:	a01fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fb8:	000b3797          	auipc	a5,0xb3
ffffffffc0201fbc:	0787b783          	ld	a5,120(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0201fc0:	779c                	ld	a5,40(a5)
ffffffffc0201fc2:	9782                	jalr	a5
ffffffffc0201fc4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fc6:	9e9fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201fca:	60a2                	ld	ra,8(sp)
ffffffffc0201fcc:	8522                	mv	a0,s0
ffffffffc0201fce:	6402                	ld	s0,0(sp)
ffffffffc0201fd0:	0141                	addi	sp,sp,16
ffffffffc0201fd2:	8082                	ret

ffffffffc0201fd4 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fd4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201fd8:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201fdc:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fde:	078e                	slli	a5,a5,0x3
{
ffffffffc0201fe0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fe2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fe6:	6094                	ld	a3,0(s1)
{
ffffffffc0201fe8:	f04a                	sd	s2,32(sp)
ffffffffc0201fea:	ec4e                	sd	s3,24(sp)
ffffffffc0201fec:	e852                	sd	s4,16(sp)
ffffffffc0201fee:	fc06                	sd	ra,56(sp)
ffffffffc0201ff0:	f822                	sd	s0,48(sp)
ffffffffc0201ff2:	e456                	sd	s5,8(sp)
ffffffffc0201ff4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201ff6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201ffa:	892e                	mv	s2,a1
ffffffffc0201ffc:	8a32                	mv	s4,a2
ffffffffc0201ffe:	000b3997          	auipc	s3,0xb3
ffffffffc0202002:	02298993          	addi	s3,s3,34 # ffffffffc02b5020 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0202006:	efbd                	bnez	a5,ffffffffc0202084 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202008:	14060c63          	beqz	a2,ffffffffc0202160 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020200c:	100027f3          	csrr	a5,sstatus
ffffffffc0202010:	8b89                	andi	a5,a5,2
ffffffffc0202012:	14079963          	bnez	a5,ffffffffc0202164 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202016:	000b3797          	auipc	a5,0xb3
ffffffffc020201a:	01a7b783          	ld	a5,26(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc020201e:	6f9c                	ld	a5,24(a5)
ffffffffc0202020:	4505                	li	a0,1
ffffffffc0202022:	9782                	jalr	a5
ffffffffc0202024:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202026:	12040d63          	beqz	s0,ffffffffc0202160 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc020202a:	000b3b17          	auipc	s6,0xb3
ffffffffc020202e:	ffeb0b13          	addi	s6,s6,-2 # ffffffffc02b5028 <pages>
ffffffffc0202032:	000b3503          	ld	a0,0(s6)
ffffffffc0202036:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020203a:	000b3997          	auipc	s3,0xb3
ffffffffc020203e:	fe698993          	addi	s3,s3,-26 # ffffffffc02b5020 <npage>
ffffffffc0202042:	40a40533          	sub	a0,s0,a0
ffffffffc0202046:	8519                	srai	a0,a0,0x6
ffffffffc0202048:	9556                	add	a0,a0,s5
ffffffffc020204a:	0009b703          	ld	a4,0(s3)
ffffffffc020204e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202052:	4685                	li	a3,1
ffffffffc0202054:	c014                	sw	a3,0(s0)
ffffffffc0202056:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202058:	0532                	slli	a0,a0,0xc
ffffffffc020205a:	16e7f763          	bgeu	a5,a4,ffffffffc02021c8 <get_pte+0x1f4>
ffffffffc020205e:	000b3797          	auipc	a5,0xb3
ffffffffc0202062:	fda7b783          	ld	a5,-38(a5) # ffffffffc02b5038 <va_pa_offset>
ffffffffc0202066:	6605                	lui	a2,0x1
ffffffffc0202068:	4581                	li	a1,0
ffffffffc020206a:	953e                	add	a0,a0,a5
ffffffffc020206c:	139030ef          	jal	ra,ffffffffc02059a4 <memset>
    return page - pages + nbase;
ffffffffc0202070:	000b3683          	ld	a3,0(s6)
ffffffffc0202074:	40d406b3          	sub	a3,s0,a3
ffffffffc0202078:	8699                	srai	a3,a3,0x6
ffffffffc020207a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020207c:	06aa                	slli	a3,a3,0xa
ffffffffc020207e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202082:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202084:	77fd                	lui	a5,0xfffff
ffffffffc0202086:	068a                	slli	a3,a3,0x2
ffffffffc0202088:	0009b703          	ld	a4,0(s3)
ffffffffc020208c:	8efd                	and	a3,a3,a5
ffffffffc020208e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202092:	10e7ff63          	bgeu	a5,a4,ffffffffc02021b0 <get_pte+0x1dc>
ffffffffc0202096:	000b3a97          	auipc	s5,0xb3
ffffffffc020209a:	fa2a8a93          	addi	s5,s5,-94 # ffffffffc02b5038 <va_pa_offset>
ffffffffc020209e:	000ab403          	ld	s0,0(s5)
ffffffffc02020a2:	01595793          	srli	a5,s2,0x15
ffffffffc02020a6:	1ff7f793          	andi	a5,a5,511
ffffffffc02020aa:	96a2                	add	a3,a3,s0
ffffffffc02020ac:	00379413          	slli	s0,a5,0x3
ffffffffc02020b0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020b2:	6014                	ld	a3,0(s0)
ffffffffc02020b4:	0016f793          	andi	a5,a3,1
ffffffffc02020b8:	ebad                	bnez	a5,ffffffffc020212a <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020ba:	0a0a0363          	beqz	s4,ffffffffc0202160 <get_pte+0x18c>
ffffffffc02020be:	100027f3          	csrr	a5,sstatus
ffffffffc02020c2:	8b89                	andi	a5,a5,2
ffffffffc02020c4:	efcd                	bnez	a5,ffffffffc020217e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020c6:	000b3797          	auipc	a5,0xb3
ffffffffc02020ca:	f6a7b783          	ld	a5,-150(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc02020ce:	6f9c                	ld	a5,24(a5)
ffffffffc02020d0:	4505                	li	a0,1
ffffffffc02020d2:	9782                	jalr	a5
ffffffffc02020d4:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020d6:	c4c9                	beqz	s1,ffffffffc0202160 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc02020d8:	000b3b17          	auipc	s6,0xb3
ffffffffc02020dc:	f50b0b13          	addi	s6,s6,-176 # ffffffffc02b5028 <pages>
ffffffffc02020e0:	000b3503          	ld	a0,0(s6)
ffffffffc02020e4:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020e8:	0009b703          	ld	a4,0(s3)
ffffffffc02020ec:	40a48533          	sub	a0,s1,a0
ffffffffc02020f0:	8519                	srai	a0,a0,0x6
ffffffffc02020f2:	9552                	add	a0,a0,s4
ffffffffc02020f4:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020f8:	4685                	li	a3,1
ffffffffc02020fa:	c094                	sw	a3,0(s1)
ffffffffc02020fc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020fe:	0532                	slli	a0,a0,0xc
ffffffffc0202100:	0ee7f163          	bgeu	a5,a4,ffffffffc02021e2 <get_pte+0x20e>
ffffffffc0202104:	000ab783          	ld	a5,0(s5)
ffffffffc0202108:	6605                	lui	a2,0x1
ffffffffc020210a:	4581                	li	a1,0
ffffffffc020210c:	953e                	add	a0,a0,a5
ffffffffc020210e:	097030ef          	jal	ra,ffffffffc02059a4 <memset>
    return page - pages + nbase;
ffffffffc0202112:	000b3683          	ld	a3,0(s6)
ffffffffc0202116:	40d486b3          	sub	a3,s1,a3
ffffffffc020211a:	8699                	srai	a3,a3,0x6
ffffffffc020211c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020211e:	06aa                	slli	a3,a3,0xa
ffffffffc0202120:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202124:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202126:	0009b703          	ld	a4,0(s3)
ffffffffc020212a:	068a                	slli	a3,a3,0x2
ffffffffc020212c:	757d                	lui	a0,0xfffff
ffffffffc020212e:	8ee9                	and	a3,a3,a0
ffffffffc0202130:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202134:	06e7f263          	bgeu	a5,a4,ffffffffc0202198 <get_pte+0x1c4>
ffffffffc0202138:	000ab503          	ld	a0,0(s5)
ffffffffc020213c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202140:	1ff97913          	andi	s2,s2,511
ffffffffc0202144:	96aa                	add	a3,a3,a0
ffffffffc0202146:	00391513          	slli	a0,s2,0x3
ffffffffc020214a:	9536                	add	a0,a0,a3
}
ffffffffc020214c:	70e2                	ld	ra,56(sp)
ffffffffc020214e:	7442                	ld	s0,48(sp)
ffffffffc0202150:	74a2                	ld	s1,40(sp)
ffffffffc0202152:	7902                	ld	s2,32(sp)
ffffffffc0202154:	69e2                	ld	s3,24(sp)
ffffffffc0202156:	6a42                	ld	s4,16(sp)
ffffffffc0202158:	6aa2                	ld	s5,8(sp)
ffffffffc020215a:	6b02                	ld	s6,0(sp)
ffffffffc020215c:	6121                	addi	sp,sp,64
ffffffffc020215e:	8082                	ret
            return NULL;
ffffffffc0202160:	4501                	li	a0,0
ffffffffc0202162:	b7ed                	j	ffffffffc020214c <get_pte+0x178>
        intr_disable();
ffffffffc0202164:	851fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202168:	000b3797          	auipc	a5,0xb3
ffffffffc020216c:	ec87b783          	ld	a5,-312(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc0202170:	6f9c                	ld	a5,24(a5)
ffffffffc0202172:	4505                	li	a0,1
ffffffffc0202174:	9782                	jalr	a5
ffffffffc0202176:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202178:	837fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020217c:	b56d                	j	ffffffffc0202026 <get_pte+0x52>
        intr_disable();
ffffffffc020217e:	837fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202182:	000b3797          	auipc	a5,0xb3
ffffffffc0202186:	eae7b783          	ld	a5,-338(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc020218a:	6f9c                	ld	a5,24(a5)
ffffffffc020218c:	4505                	li	a0,1
ffffffffc020218e:	9782                	jalr	a5
ffffffffc0202190:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202192:	81dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202196:	b781                	j	ffffffffc02020d6 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202198:	00004617          	auipc	a2,0x4
ffffffffc020219c:	6c860613          	addi	a2,a2,1736 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02021a0:	0fa00593          	li	a1,250
ffffffffc02021a4:	00004517          	auipc	a0,0x4
ffffffffc02021a8:	7d450513          	addi	a0,a0,2004 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02021ac:	ae2fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021b0:	00004617          	auipc	a2,0x4
ffffffffc02021b4:	6b060613          	addi	a2,a2,1712 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02021b8:	0ed00593          	li	a1,237
ffffffffc02021bc:	00004517          	auipc	a0,0x4
ffffffffc02021c0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02021c4:	acafe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021c8:	86aa                	mv	a3,a0
ffffffffc02021ca:	00004617          	auipc	a2,0x4
ffffffffc02021ce:	69660613          	addi	a2,a2,1686 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02021d2:	0e900593          	li	a1,233
ffffffffc02021d6:	00004517          	auipc	a0,0x4
ffffffffc02021da:	7a250513          	addi	a0,a0,1954 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02021de:	ab0fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021e2:	86aa                	mv	a3,a0
ffffffffc02021e4:	00004617          	auipc	a2,0x4
ffffffffc02021e8:	67c60613          	addi	a2,a2,1660 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02021ec:	0f700593          	li	a1,247
ffffffffc02021f0:	00004517          	auipc	a0,0x4
ffffffffc02021f4:	78850513          	addi	a0,a0,1928 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02021f8:	a96fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02021fc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021fc:	1141                	addi	sp,sp,-16
ffffffffc02021fe:	e022                	sd	s0,0(sp)
ffffffffc0202200:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202202:	4601                	li	a2,0
{
ffffffffc0202204:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202206:	dcfff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
    if (ptep_store != NULL)
ffffffffc020220a:	c011                	beqz	s0,ffffffffc020220e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc020220c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020220e:	c511                	beqz	a0,ffffffffc020221a <get_page+0x1e>
ffffffffc0202210:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202212:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202214:	0017f713          	andi	a4,a5,1
ffffffffc0202218:	e709                	bnez	a4,ffffffffc0202222 <get_page+0x26>
}
ffffffffc020221a:	60a2                	ld	ra,8(sp)
ffffffffc020221c:	6402                	ld	s0,0(sp)
ffffffffc020221e:	0141                	addi	sp,sp,16
ffffffffc0202220:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202222:	078a                	slli	a5,a5,0x2
ffffffffc0202224:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202226:	000b3717          	auipc	a4,0xb3
ffffffffc020222a:	dfa73703          	ld	a4,-518(a4) # ffffffffc02b5020 <npage>
ffffffffc020222e:	00e7ff63          	bgeu	a5,a4,ffffffffc020224c <get_page+0x50>
ffffffffc0202232:	60a2                	ld	ra,8(sp)
ffffffffc0202234:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202236:	fff80537          	lui	a0,0xfff80
ffffffffc020223a:	97aa                	add	a5,a5,a0
ffffffffc020223c:	079a                	slli	a5,a5,0x6
ffffffffc020223e:	000b3517          	auipc	a0,0xb3
ffffffffc0202242:	dea53503          	ld	a0,-534(a0) # ffffffffc02b5028 <pages>
ffffffffc0202246:	953e                	add	a0,a0,a5
ffffffffc0202248:	0141                	addi	sp,sp,16
ffffffffc020224a:	8082                	ret
ffffffffc020224c:	c99ff0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>

ffffffffc0202250 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202250:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202252:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202256:	f486                	sd	ra,104(sp)
ffffffffc0202258:	f0a2                	sd	s0,96(sp)
ffffffffc020225a:	eca6                	sd	s1,88(sp)
ffffffffc020225c:	e8ca                	sd	s2,80(sp)
ffffffffc020225e:	e4ce                	sd	s3,72(sp)
ffffffffc0202260:	e0d2                	sd	s4,64(sp)
ffffffffc0202262:	fc56                	sd	s5,56(sp)
ffffffffc0202264:	f85a                	sd	s6,48(sp)
ffffffffc0202266:	f45e                	sd	s7,40(sp)
ffffffffc0202268:	f062                	sd	s8,32(sp)
ffffffffc020226a:	ec66                	sd	s9,24(sp)
ffffffffc020226c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020226e:	17d2                	slli	a5,a5,0x34
ffffffffc0202270:	e3ed                	bnez	a5,ffffffffc0202352 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202272:	002007b7          	lui	a5,0x200
ffffffffc0202276:	842e                	mv	s0,a1
ffffffffc0202278:	0ef5ed63          	bltu	a1,a5,ffffffffc0202372 <unmap_range+0x122>
ffffffffc020227c:	8932                	mv	s2,a2
ffffffffc020227e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202372 <unmap_range+0x122>
ffffffffc0202282:	4785                	li	a5,1
ffffffffc0202284:	07fe                	slli	a5,a5,0x1f
ffffffffc0202286:	0ec7e663          	bltu	a5,a2,ffffffffc0202372 <unmap_range+0x122>
ffffffffc020228a:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020228c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020228e:	000b3c97          	auipc	s9,0xb3
ffffffffc0202292:	d92c8c93          	addi	s9,s9,-622 # ffffffffc02b5020 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202296:	000b3c17          	auipc	s8,0xb3
ffffffffc020229a:	d92c0c13          	addi	s8,s8,-622 # ffffffffc02b5028 <pages>
ffffffffc020229e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02022a2:	000b3d17          	auipc	s10,0xb3
ffffffffc02022a6:	d8ed0d13          	addi	s10,s10,-626 # ffffffffc02b5030 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022aa:	00200b37          	lui	s6,0x200
ffffffffc02022ae:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022b2:	4601                	li	a2,0
ffffffffc02022b4:	85a2                	mv	a1,s0
ffffffffc02022b6:	854e                	mv	a0,s3
ffffffffc02022b8:	d1dff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc02022bc:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02022be:	cd29                	beqz	a0,ffffffffc0202318 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02022c0:	611c                	ld	a5,0(a0)
ffffffffc02022c2:	e395                	bnez	a5,ffffffffc02022e6 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02022c4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022c6:	ff2466e3          	bltu	s0,s2,ffffffffc02022b2 <unmap_range+0x62>
}
ffffffffc02022ca:	70a6                	ld	ra,104(sp)
ffffffffc02022cc:	7406                	ld	s0,96(sp)
ffffffffc02022ce:	64e6                	ld	s1,88(sp)
ffffffffc02022d0:	6946                	ld	s2,80(sp)
ffffffffc02022d2:	69a6                	ld	s3,72(sp)
ffffffffc02022d4:	6a06                	ld	s4,64(sp)
ffffffffc02022d6:	7ae2                	ld	s5,56(sp)
ffffffffc02022d8:	7b42                	ld	s6,48(sp)
ffffffffc02022da:	7ba2                	ld	s7,40(sp)
ffffffffc02022dc:	7c02                	ld	s8,32(sp)
ffffffffc02022de:	6ce2                	ld	s9,24(sp)
ffffffffc02022e0:	6d42                	ld	s10,16(sp)
ffffffffc02022e2:	6165                	addi	sp,sp,112
ffffffffc02022e4:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022e6:	0017f713          	andi	a4,a5,1
ffffffffc02022ea:	df69                	beqz	a4,ffffffffc02022c4 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02022ec:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022f0:	078a                	slli	a5,a5,0x2
ffffffffc02022f2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022f4:	08e7ff63          	bgeu	a5,a4,ffffffffc0202392 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02022f8:	000c3503          	ld	a0,0(s8)
ffffffffc02022fc:	97de                	add	a5,a5,s7
ffffffffc02022fe:	079a                	slli	a5,a5,0x6
ffffffffc0202300:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202302:	411c                	lw	a5,0(a0)
ffffffffc0202304:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202308:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020230a:	cf11                	beqz	a4,ffffffffc0202326 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc020230c:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202310:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202314:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202316:	bf45                	j	ffffffffc02022c6 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202318:	945a                	add	s0,s0,s6
ffffffffc020231a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020231e:	d455                	beqz	s0,ffffffffc02022ca <unmap_range+0x7a>
ffffffffc0202320:	f92469e3          	bltu	s0,s2,ffffffffc02022b2 <unmap_range+0x62>
ffffffffc0202324:	b75d                	j	ffffffffc02022ca <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202326:	100027f3          	csrr	a5,sstatus
ffffffffc020232a:	8b89                	andi	a5,a5,2
ffffffffc020232c:	e799                	bnez	a5,ffffffffc020233a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020232e:	000d3783          	ld	a5,0(s10)
ffffffffc0202332:	4585                	li	a1,1
ffffffffc0202334:	739c                	ld	a5,32(a5)
ffffffffc0202336:	9782                	jalr	a5
    if (flag)
ffffffffc0202338:	bfd1                	j	ffffffffc020230c <unmap_range+0xbc>
ffffffffc020233a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020233c:	e78fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202340:	000d3783          	ld	a5,0(s10)
ffffffffc0202344:	6522                	ld	a0,8(sp)
ffffffffc0202346:	4585                	li	a1,1
ffffffffc0202348:	739c                	ld	a5,32(a5)
ffffffffc020234a:	9782                	jalr	a5
        intr_enable();
ffffffffc020234c:	e62fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202350:	bf75                	j	ffffffffc020230c <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202352:	00004697          	auipc	a3,0x4
ffffffffc0202356:	63668693          	addi	a3,a3,1590 # ffffffffc0206988 <default_pmm_manager+0x160>
ffffffffc020235a:	00004617          	auipc	a2,0x4
ffffffffc020235e:	ed660613          	addi	a2,a2,-298 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202362:	12000593          	li	a1,288
ffffffffc0202366:	00004517          	auipc	a0,0x4
ffffffffc020236a:	61250513          	addi	a0,a0,1554 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020236e:	920fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202372:	00004697          	auipc	a3,0x4
ffffffffc0202376:	64668693          	addi	a3,a3,1606 # ffffffffc02069b8 <default_pmm_manager+0x190>
ffffffffc020237a:	00004617          	auipc	a2,0x4
ffffffffc020237e:	eb660613          	addi	a2,a2,-330 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202382:	12100593          	li	a1,289
ffffffffc0202386:	00004517          	auipc	a0,0x4
ffffffffc020238a:	5f250513          	addi	a0,a0,1522 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020238e:	900fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202392:	b53ff0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>

ffffffffc0202396 <exit_range>:
{
ffffffffc0202396:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202398:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020239c:	fc86                	sd	ra,120(sp)
ffffffffc020239e:	f8a2                	sd	s0,112(sp)
ffffffffc02023a0:	f4a6                	sd	s1,104(sp)
ffffffffc02023a2:	f0ca                	sd	s2,96(sp)
ffffffffc02023a4:	ecce                	sd	s3,88(sp)
ffffffffc02023a6:	e8d2                	sd	s4,80(sp)
ffffffffc02023a8:	e4d6                	sd	s5,72(sp)
ffffffffc02023aa:	e0da                	sd	s6,64(sp)
ffffffffc02023ac:	fc5e                	sd	s7,56(sp)
ffffffffc02023ae:	f862                	sd	s8,48(sp)
ffffffffc02023b0:	f466                	sd	s9,40(sp)
ffffffffc02023b2:	f06a                	sd	s10,32(sp)
ffffffffc02023b4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023b6:	17d2                	slli	a5,a5,0x34
ffffffffc02023b8:	20079a63          	bnez	a5,ffffffffc02025cc <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02023bc:	002007b7          	lui	a5,0x200
ffffffffc02023c0:	24f5e463          	bltu	a1,a5,ffffffffc0202608 <exit_range+0x272>
ffffffffc02023c4:	8ab2                	mv	s5,a2
ffffffffc02023c6:	24c5f163          	bgeu	a1,a2,ffffffffc0202608 <exit_range+0x272>
ffffffffc02023ca:	4785                	li	a5,1
ffffffffc02023cc:	07fe                	slli	a5,a5,0x1f
ffffffffc02023ce:	22c7ed63          	bltu	a5,a2,ffffffffc0202608 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023d2:	c00009b7          	lui	s3,0xc0000
ffffffffc02023d6:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023da:	ffe00937          	lui	s2,0xffe00
ffffffffc02023de:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02023e2:	5cfd                	li	s9,-1
ffffffffc02023e4:	8c2a                	mv	s8,a0
ffffffffc02023e6:	0125f933          	and	s2,a1,s2
ffffffffc02023ea:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02023ec:	000b3d17          	auipc	s10,0xb3
ffffffffc02023f0:	c34d0d13          	addi	s10,s10,-972 # ffffffffc02b5020 <npage>
    return KADDR(page2pa(page));
ffffffffc02023f4:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023f8:	000b3717          	auipc	a4,0xb3
ffffffffc02023fc:	c3070713          	addi	a4,a4,-976 # ffffffffc02b5028 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202400:	000b3d97          	auipc	s11,0xb3
ffffffffc0202404:	c30d8d93          	addi	s11,s11,-976 # ffffffffc02b5030 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202408:	c0000437          	lui	s0,0xc0000
ffffffffc020240c:	944e                	add	s0,s0,s3
ffffffffc020240e:	8079                	srli	s0,s0,0x1e
ffffffffc0202410:	1ff47413          	andi	s0,s0,511
ffffffffc0202414:	040e                	slli	s0,s0,0x3
ffffffffc0202416:	9462                	add	s0,s0,s8
ffffffffc0202418:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
        if (pde1 & PTE_V)
ffffffffc020241c:	001a7793          	andi	a5,s4,1
ffffffffc0202420:	eb99                	bnez	a5,ffffffffc0202436 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202422:	12098463          	beqz	s3,ffffffffc020254a <exit_range+0x1b4>
ffffffffc0202426:	400007b7          	lui	a5,0x40000
ffffffffc020242a:	97ce                	add	a5,a5,s3
ffffffffc020242c:	894e                	mv	s2,s3
ffffffffc020242e:	1159fe63          	bgeu	s3,s5,ffffffffc020254a <exit_range+0x1b4>
ffffffffc0202432:	89be                	mv	s3,a5
ffffffffc0202434:	bfd1                	j	ffffffffc0202408 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc0202436:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020243a:	0a0a                	slli	s4,s4,0x2
ffffffffc020243c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202440:	1cfa7263          	bgeu	s4,a5,ffffffffc0202604 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202444:	fff80637          	lui	a2,0xfff80
ffffffffc0202448:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020244a:	000806b7          	lui	a3,0x80
ffffffffc020244e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202450:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202454:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202456:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202458:	18f5fa63          	bgeu	a1,a5,ffffffffc02025ec <exit_range+0x256>
ffffffffc020245c:	000b3817          	auipc	a6,0xb3
ffffffffc0202460:	bdc80813          	addi	a6,a6,-1060 # ffffffffc02b5038 <va_pa_offset>
ffffffffc0202464:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202468:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020246a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020246e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202470:	00080337          	lui	t1,0x80
ffffffffc0202474:	6885                	lui	a7,0x1
ffffffffc0202476:	a819                	j	ffffffffc020248c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202478:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020247a:	002007b7          	lui	a5,0x200
ffffffffc020247e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202480:	08090c63          	beqz	s2,ffffffffc0202518 <exit_range+0x182>
ffffffffc0202484:	09397a63          	bgeu	s2,s3,ffffffffc0202518 <exit_range+0x182>
ffffffffc0202488:	0f597063          	bgeu	s2,s5,ffffffffc0202568 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020248c:	01595493          	srli	s1,s2,0x15
ffffffffc0202490:	1ff4f493          	andi	s1,s1,511
ffffffffc0202494:	048e                	slli	s1,s1,0x3
ffffffffc0202496:	94da                	add	s1,s1,s6
ffffffffc0202498:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020249a:	0017f693          	andi	a3,a5,1
ffffffffc020249e:	dee9                	beqz	a3,ffffffffc0202478 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02024a0:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024a4:	078a                	slli	a5,a5,0x2
ffffffffc02024a6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024a8:	14b7fe63          	bgeu	a5,a1,ffffffffc0202604 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ac:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02024ae:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02024b2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02024b6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024ba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024bc:	12bef863          	bgeu	t4,a1,ffffffffc02025ec <exit_range+0x256>
ffffffffc02024c0:	00083783          	ld	a5,0(a6)
ffffffffc02024c4:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024c6:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02024ca:	629c                	ld	a5,0(a3)
ffffffffc02024cc:	8b85                	andi	a5,a5,1
ffffffffc02024ce:	f7d5                	bnez	a5,ffffffffc020247a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024d0:	06a1                	addi	a3,a3,8
ffffffffc02024d2:	fed59ce3          	bne	a1,a3,ffffffffc02024ca <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d6:	631c                	ld	a5,0(a4)
ffffffffc02024d8:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024da:	100027f3          	csrr	a5,sstatus
ffffffffc02024de:	8b89                	andi	a5,a5,2
ffffffffc02024e0:	e7d9                	bnez	a5,ffffffffc020256e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02024e2:	000db783          	ld	a5,0(s11)
ffffffffc02024e6:	4585                	li	a1,1
ffffffffc02024e8:	e032                	sd	a2,0(sp)
ffffffffc02024ea:	739c                	ld	a5,32(a5)
ffffffffc02024ec:	9782                	jalr	a5
    if (flag)
ffffffffc02024ee:	6602                	ld	a2,0(sp)
ffffffffc02024f0:	000b3817          	auipc	a6,0xb3
ffffffffc02024f4:	b4880813          	addi	a6,a6,-1208 # ffffffffc02b5038 <va_pa_offset>
ffffffffc02024f8:	fff80e37          	lui	t3,0xfff80
ffffffffc02024fc:	00080337          	lui	t1,0x80
ffffffffc0202500:	6885                	lui	a7,0x1
ffffffffc0202502:	000b3717          	auipc	a4,0xb3
ffffffffc0202506:	b2670713          	addi	a4,a4,-1242 # ffffffffc02b5028 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020250a:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020250e:	002007b7          	lui	a5,0x200
ffffffffc0202512:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202514:	f60918e3          	bnez	s2,ffffffffc0202484 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202518:	f00b85e3          	beqz	s7,ffffffffc0202422 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc020251c:	000d3783          	ld	a5,0(s10)
ffffffffc0202520:	0efa7263          	bgeu	s4,a5,ffffffffc0202604 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202524:	6308                	ld	a0,0(a4)
ffffffffc0202526:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202528:	100027f3          	csrr	a5,sstatus
ffffffffc020252c:	8b89                	andi	a5,a5,2
ffffffffc020252e:	efad                	bnez	a5,ffffffffc02025a8 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202530:	000db783          	ld	a5,0(s11)
ffffffffc0202534:	4585                	li	a1,1
ffffffffc0202536:	739c                	ld	a5,32(a5)
ffffffffc0202538:	9782                	jalr	a5
ffffffffc020253a:	000b3717          	auipc	a4,0xb3
ffffffffc020253e:	aee70713          	addi	a4,a4,-1298 # ffffffffc02b5028 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202542:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202546:	ee0990e3          	bnez	s3,ffffffffc0202426 <exit_range+0x90>
}
ffffffffc020254a:	70e6                	ld	ra,120(sp)
ffffffffc020254c:	7446                	ld	s0,112(sp)
ffffffffc020254e:	74a6                	ld	s1,104(sp)
ffffffffc0202550:	7906                	ld	s2,96(sp)
ffffffffc0202552:	69e6                	ld	s3,88(sp)
ffffffffc0202554:	6a46                	ld	s4,80(sp)
ffffffffc0202556:	6aa6                	ld	s5,72(sp)
ffffffffc0202558:	6b06                	ld	s6,64(sp)
ffffffffc020255a:	7be2                	ld	s7,56(sp)
ffffffffc020255c:	7c42                	ld	s8,48(sp)
ffffffffc020255e:	7ca2                	ld	s9,40(sp)
ffffffffc0202560:	7d02                	ld	s10,32(sp)
ffffffffc0202562:	6de2                	ld	s11,24(sp)
ffffffffc0202564:	6109                	addi	sp,sp,128
ffffffffc0202566:	8082                	ret
            if (free_pd0)
ffffffffc0202568:	ea0b8fe3          	beqz	s7,ffffffffc0202426 <exit_range+0x90>
ffffffffc020256c:	bf45                	j	ffffffffc020251c <exit_range+0x186>
ffffffffc020256e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202570:	e42a                	sd	a0,8(sp)
ffffffffc0202572:	c42fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202576:	000db783          	ld	a5,0(s11)
ffffffffc020257a:	6522                	ld	a0,8(sp)
ffffffffc020257c:	4585                	li	a1,1
ffffffffc020257e:	739c                	ld	a5,32(a5)
ffffffffc0202580:	9782                	jalr	a5
        intr_enable();
ffffffffc0202582:	c2cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202586:	6602                	ld	a2,0(sp)
ffffffffc0202588:	000b3717          	auipc	a4,0xb3
ffffffffc020258c:	aa070713          	addi	a4,a4,-1376 # ffffffffc02b5028 <pages>
ffffffffc0202590:	6885                	lui	a7,0x1
ffffffffc0202592:	00080337          	lui	t1,0x80
ffffffffc0202596:	fff80e37          	lui	t3,0xfff80
ffffffffc020259a:	000b3817          	auipc	a6,0xb3
ffffffffc020259e:	a9e80813          	addi	a6,a6,-1378 # ffffffffc02b5038 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025a2:	0004b023          	sd	zero,0(s1)
ffffffffc02025a6:	b7a5                	j	ffffffffc020250e <exit_range+0x178>
ffffffffc02025a8:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02025aa:	c0afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025ae:	000db783          	ld	a5,0(s11)
ffffffffc02025b2:	6502                	ld	a0,0(sp)
ffffffffc02025b4:	4585                	li	a1,1
ffffffffc02025b6:	739c                	ld	a5,32(a5)
ffffffffc02025b8:	9782                	jalr	a5
        intr_enable();
ffffffffc02025ba:	bf4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02025be:	000b3717          	auipc	a4,0xb3
ffffffffc02025c2:	a6a70713          	addi	a4,a4,-1430 # ffffffffc02b5028 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025c6:	00043023          	sd	zero,0(s0)
ffffffffc02025ca:	bfb5                	j	ffffffffc0202546 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025cc:	00004697          	auipc	a3,0x4
ffffffffc02025d0:	3bc68693          	addi	a3,a3,956 # ffffffffc0206988 <default_pmm_manager+0x160>
ffffffffc02025d4:	00004617          	auipc	a2,0x4
ffffffffc02025d8:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02025dc:	13500593          	li	a1,309
ffffffffc02025e0:	00004517          	auipc	a0,0x4
ffffffffc02025e4:	39850513          	addi	a0,a0,920 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02025e8:	ea7fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025ec:	00004617          	auipc	a2,0x4
ffffffffc02025f0:	27460613          	addi	a2,a2,628 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02025f4:	07100593          	li	a1,113
ffffffffc02025f8:	00004517          	auipc	a0,0x4
ffffffffc02025fc:	29050513          	addi	a0,a0,656 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0202600:	e8ffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202604:	8e1ff0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202608:	00004697          	auipc	a3,0x4
ffffffffc020260c:	3b068693          	addi	a3,a3,944 # ffffffffc02069b8 <default_pmm_manager+0x190>
ffffffffc0202610:	00004617          	auipc	a2,0x4
ffffffffc0202614:	c2060613          	addi	a2,a2,-992 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202618:	13600593          	li	a1,310
ffffffffc020261c:	00004517          	auipc	a0,0x4
ffffffffc0202620:	35c50513          	addi	a0,a0,860 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202624:	e6bfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202628 <page_remove>:
{
ffffffffc0202628:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020262a:	4601                	li	a2,0
{
ffffffffc020262c:	ec26                	sd	s1,24(sp)
ffffffffc020262e:	f406                	sd	ra,40(sp)
ffffffffc0202630:	f022                	sd	s0,32(sp)
ffffffffc0202632:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202634:	9a1ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
    if (ptep != NULL)
ffffffffc0202638:	c511                	beqz	a0,ffffffffc0202644 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020263a:	611c                	ld	a5,0(a0)
ffffffffc020263c:	842a                	mv	s0,a0
ffffffffc020263e:	0017f713          	andi	a4,a5,1
ffffffffc0202642:	e711                	bnez	a4,ffffffffc020264e <page_remove+0x26>
}
ffffffffc0202644:	70a2                	ld	ra,40(sp)
ffffffffc0202646:	7402                	ld	s0,32(sp)
ffffffffc0202648:	64e2                	ld	s1,24(sp)
ffffffffc020264a:	6145                	addi	sp,sp,48
ffffffffc020264c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020264e:	078a                	slli	a5,a5,0x2
ffffffffc0202650:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202652:	000b3717          	auipc	a4,0xb3
ffffffffc0202656:	9ce73703          	ld	a4,-1586(a4) # ffffffffc02b5020 <npage>
ffffffffc020265a:	06e7f363          	bgeu	a5,a4,ffffffffc02026c0 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020265e:	fff80537          	lui	a0,0xfff80
ffffffffc0202662:	97aa                	add	a5,a5,a0
ffffffffc0202664:	079a                	slli	a5,a5,0x6
ffffffffc0202666:	000b3517          	auipc	a0,0xb3
ffffffffc020266a:	9c253503          	ld	a0,-1598(a0) # ffffffffc02b5028 <pages>
ffffffffc020266e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202670:	411c                	lw	a5,0(a0)
ffffffffc0202672:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202676:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202678:	cb11                	beqz	a4,ffffffffc020268c <page_remove+0x64>
        *ptep = 0;
ffffffffc020267a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020267e:	12048073          	sfence.vma	s1
}
ffffffffc0202682:	70a2                	ld	ra,40(sp)
ffffffffc0202684:	7402                	ld	s0,32(sp)
ffffffffc0202686:	64e2                	ld	s1,24(sp)
ffffffffc0202688:	6145                	addi	sp,sp,48
ffffffffc020268a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020268c:	100027f3          	csrr	a5,sstatus
ffffffffc0202690:	8b89                	andi	a5,a5,2
ffffffffc0202692:	eb89                	bnez	a5,ffffffffc02026a4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202694:	000b3797          	auipc	a5,0xb3
ffffffffc0202698:	99c7b783          	ld	a5,-1636(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc020269c:	739c                	ld	a5,32(a5)
ffffffffc020269e:	4585                	li	a1,1
ffffffffc02026a0:	9782                	jalr	a5
    if (flag)
ffffffffc02026a2:	bfe1                	j	ffffffffc020267a <page_remove+0x52>
        intr_disable();
ffffffffc02026a4:	e42a                	sd	a0,8(sp)
ffffffffc02026a6:	b0efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02026aa:	000b3797          	auipc	a5,0xb3
ffffffffc02026ae:	9867b783          	ld	a5,-1658(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc02026b2:	739c                	ld	a5,32(a5)
ffffffffc02026b4:	6522                	ld	a0,8(sp)
ffffffffc02026b6:	4585                	li	a1,1
ffffffffc02026b8:	9782                	jalr	a5
        intr_enable();
ffffffffc02026ba:	af4fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02026be:	bf75                	j	ffffffffc020267a <page_remove+0x52>
ffffffffc02026c0:	825ff0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>

ffffffffc02026c4 <page_insert>:
{
ffffffffc02026c4:	7139                	addi	sp,sp,-64
ffffffffc02026c6:	e852                	sd	s4,16(sp)
ffffffffc02026c8:	8a32                	mv	s4,a2
ffffffffc02026ca:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026cc:	4605                	li	a2,1
{
ffffffffc02026ce:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026d0:	85d2                	mv	a1,s4
{
ffffffffc02026d2:	f426                	sd	s1,40(sp)
ffffffffc02026d4:	fc06                	sd	ra,56(sp)
ffffffffc02026d6:	f04a                	sd	s2,32(sp)
ffffffffc02026d8:	ec4e                	sd	s3,24(sp)
ffffffffc02026da:	e456                	sd	s5,8(sp)
ffffffffc02026dc:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026de:	8f7ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
    if (ptep == NULL)
ffffffffc02026e2:	c961                	beqz	a0,ffffffffc02027b2 <page_insert+0xee>
    page->ref += 1;
ffffffffc02026e4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026e6:	611c                	ld	a5,0(a0)
ffffffffc02026e8:	89aa                	mv	s3,a0
ffffffffc02026ea:	0016871b          	addiw	a4,a3,1
ffffffffc02026ee:	c018                	sw	a4,0(s0)
ffffffffc02026f0:	0017f713          	andi	a4,a5,1
ffffffffc02026f4:	ef05                	bnez	a4,ffffffffc020272c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02026f6:	000b3717          	auipc	a4,0xb3
ffffffffc02026fa:	93273703          	ld	a4,-1742(a4) # ffffffffc02b5028 <pages>
ffffffffc02026fe:	8c19                	sub	s0,s0,a4
ffffffffc0202700:	000807b7          	lui	a5,0x80
ffffffffc0202704:	8419                	srai	s0,s0,0x6
ffffffffc0202706:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202708:	042a                	slli	s0,s0,0xa
ffffffffc020270a:	8cc1                	or	s1,s1,s0
ffffffffc020270c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202710:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202714:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202718:	4501                	li	a0,0
}
ffffffffc020271a:	70e2                	ld	ra,56(sp)
ffffffffc020271c:	7442                	ld	s0,48(sp)
ffffffffc020271e:	74a2                	ld	s1,40(sp)
ffffffffc0202720:	7902                	ld	s2,32(sp)
ffffffffc0202722:	69e2                	ld	s3,24(sp)
ffffffffc0202724:	6a42                	ld	s4,16(sp)
ffffffffc0202726:	6aa2                	ld	s5,8(sp)
ffffffffc0202728:	6121                	addi	sp,sp,64
ffffffffc020272a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020272c:	078a                	slli	a5,a5,0x2
ffffffffc020272e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202730:	000b3717          	auipc	a4,0xb3
ffffffffc0202734:	8f073703          	ld	a4,-1808(a4) # ffffffffc02b5020 <npage>
ffffffffc0202738:	06e7ff63          	bgeu	a5,a4,ffffffffc02027b6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020273c:	000b3a97          	auipc	s5,0xb3
ffffffffc0202740:	8eca8a93          	addi	s5,s5,-1812 # ffffffffc02b5028 <pages>
ffffffffc0202744:	000ab703          	ld	a4,0(s5)
ffffffffc0202748:	fff80937          	lui	s2,0xfff80
ffffffffc020274c:	993e                	add	s2,s2,a5
ffffffffc020274e:	091a                	slli	s2,s2,0x6
ffffffffc0202750:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202752:	01240c63          	beq	s0,s2,ffffffffc020276a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202756:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccaf94>
ffffffffc020275a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020275e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202762:	c691                	beqz	a3,ffffffffc020276e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202764:	120a0073          	sfence.vma	s4
}
ffffffffc0202768:	bf59                	j	ffffffffc02026fe <page_insert+0x3a>
ffffffffc020276a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020276c:	bf49                	j	ffffffffc02026fe <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020276e:	100027f3          	csrr	a5,sstatus
ffffffffc0202772:	8b89                	andi	a5,a5,2
ffffffffc0202774:	ef91                	bnez	a5,ffffffffc0202790 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202776:	000b3797          	auipc	a5,0xb3
ffffffffc020277a:	8ba7b783          	ld	a5,-1862(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc020277e:	739c                	ld	a5,32(a5)
ffffffffc0202780:	4585                	li	a1,1
ffffffffc0202782:	854a                	mv	a0,s2
ffffffffc0202784:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202786:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020278a:	120a0073          	sfence.vma	s4
ffffffffc020278e:	bf85                	j	ffffffffc02026fe <page_insert+0x3a>
        intr_disable();
ffffffffc0202790:	a24fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202794:	000b3797          	auipc	a5,0xb3
ffffffffc0202798:	89c7b783          	ld	a5,-1892(a5) # ffffffffc02b5030 <pmm_manager>
ffffffffc020279c:	739c                	ld	a5,32(a5)
ffffffffc020279e:	4585                	li	a1,1
ffffffffc02027a0:	854a                	mv	a0,s2
ffffffffc02027a2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027a4:	a0afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02027a8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027ac:	120a0073          	sfence.vma	s4
ffffffffc02027b0:	b7b9                	j	ffffffffc02026fe <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02027b2:	5571                	li	a0,-4
ffffffffc02027b4:	b79d                	j	ffffffffc020271a <page_insert+0x56>
ffffffffc02027b6:	f2eff0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>

ffffffffc02027ba <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027ba:	00004797          	auipc	a5,0x4
ffffffffc02027be:	06e78793          	addi	a5,a5,110 # ffffffffc0206828 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027c2:	638c                	ld	a1,0(a5)
{
ffffffffc02027c4:	7159                	addi	sp,sp,-112
ffffffffc02027c6:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027c8:	00004517          	auipc	a0,0x4
ffffffffc02027cc:	20850513          	addi	a0,a0,520 # ffffffffc02069d0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027d0:	000b3b17          	auipc	s6,0xb3
ffffffffc02027d4:	860b0b13          	addi	s6,s6,-1952 # ffffffffc02b5030 <pmm_manager>
{
ffffffffc02027d8:	f486                	sd	ra,104(sp)
ffffffffc02027da:	e8ca                	sd	s2,80(sp)
ffffffffc02027dc:	e4ce                	sd	s3,72(sp)
ffffffffc02027de:	f0a2                	sd	s0,96(sp)
ffffffffc02027e0:	eca6                	sd	s1,88(sp)
ffffffffc02027e2:	e0d2                	sd	s4,64(sp)
ffffffffc02027e4:	fc56                	sd	s5,56(sp)
ffffffffc02027e6:	f45e                	sd	s7,40(sp)
ffffffffc02027e8:	f062                	sd	s8,32(sp)
ffffffffc02027ea:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027ec:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027f0:	9a5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027f4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027f8:	000b3997          	auipc	s3,0xb3
ffffffffc02027fc:	84098993          	addi	s3,s3,-1984 # ffffffffc02b5038 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202800:	679c                	ld	a5,8(a5)
ffffffffc0202802:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202804:	57f5                	li	a5,-3
ffffffffc0202806:	07fa                	slli	a5,a5,0x1e
ffffffffc0202808:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020280c:	98efe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc0202810:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0202812:	992fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202816:	200505e3          	beqz	a0,ffffffffc0203220 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020281a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020281c:	00004517          	auipc	a0,0x4
ffffffffc0202820:	1ec50513          	addi	a0,a0,492 # ffffffffc0206a08 <default_pmm_manager+0x1e0>
ffffffffc0202824:	971fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202828:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020282c:	fff40693          	addi	a3,s0,-1
ffffffffc0202830:	864a                	mv	a2,s2
ffffffffc0202832:	85a6                	mv	a1,s1
ffffffffc0202834:	00004517          	auipc	a0,0x4
ffffffffc0202838:	1ec50513          	addi	a0,a0,492 # ffffffffc0206a20 <default_pmm_manager+0x1f8>
ffffffffc020283c:	959fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202840:	c8000737          	lui	a4,0xc8000
ffffffffc0202844:	87a2                	mv	a5,s0
ffffffffc0202846:	54876163          	bltu	a4,s0,ffffffffc0202d88 <pmm_init+0x5ce>
ffffffffc020284a:	757d                	lui	a0,0xfffff
ffffffffc020284c:	000b4617          	auipc	a2,0xb4
ffffffffc0202850:	81f60613          	addi	a2,a2,-2017 # ffffffffc02b606b <end+0xfff>
ffffffffc0202854:	8e69                	and	a2,a2,a0
ffffffffc0202856:	000b2497          	auipc	s1,0xb2
ffffffffc020285a:	7ca48493          	addi	s1,s1,1994 # ffffffffc02b5020 <npage>
ffffffffc020285e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202862:	000b2b97          	auipc	s7,0xb2
ffffffffc0202866:	7c6b8b93          	addi	s7,s7,1990 # ffffffffc02b5028 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020286a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020286c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202870:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202874:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202876:	02f50863          	beq	a0,a5,ffffffffc02028a6 <pmm_init+0xec>
ffffffffc020287a:	4781                	li	a5,0
ffffffffc020287c:	4585                	li	a1,1
ffffffffc020287e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202882:	00679513          	slli	a0,a5,0x6
ffffffffc0202886:	9532                	add	a0,a0,a2
ffffffffc0202888:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd49f9c>
ffffffffc020288c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202890:	6088                	ld	a0,0(s1)
ffffffffc0202892:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202894:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202898:	00d50733          	add	a4,a0,a3
ffffffffc020289c:	fee7e3e3          	bltu	a5,a4,ffffffffc0202882 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028a0:	071a                	slli	a4,a4,0x6
ffffffffc02028a2:	00e606b3          	add	a3,a2,a4
ffffffffc02028a6:	c02007b7          	lui	a5,0xc0200
ffffffffc02028aa:	2ef6ece3          	bltu	a3,a5,ffffffffc02033a2 <pmm_init+0xbe8>
ffffffffc02028ae:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028b2:	77fd                	lui	a5,0xfffff
ffffffffc02028b4:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028b6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028b8:	5086eb63          	bltu	a3,s0,ffffffffc0202dce <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028bc:	00004517          	auipc	a0,0x4
ffffffffc02028c0:	18c50513          	addi	a0,a0,396 # ffffffffc0206a48 <default_pmm_manager+0x220>
ffffffffc02028c4:	8d1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028c8:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028cc:	000b2917          	auipc	s2,0xb2
ffffffffc02028d0:	74c90913          	addi	s2,s2,1868 # ffffffffc02b5018 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028d4:	7b9c                	ld	a5,48(a5)
ffffffffc02028d6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028d8:	00004517          	auipc	a0,0x4
ffffffffc02028dc:	18850513          	addi	a0,a0,392 # ffffffffc0206a60 <default_pmm_manager+0x238>
ffffffffc02028e0:	8b5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028e4:	00007697          	auipc	a3,0x7
ffffffffc02028e8:	71c68693          	addi	a3,a3,1820 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028ec:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028f0:	c02007b7          	lui	a5,0xc0200
ffffffffc02028f4:	28f6ebe3          	bltu	a3,a5,ffffffffc020338a <pmm_init+0xbd0>
ffffffffc02028f8:	0009b783          	ld	a5,0(s3)
ffffffffc02028fc:	8e9d                	sub	a3,a3,a5
ffffffffc02028fe:	000b2797          	auipc	a5,0xb2
ffffffffc0202902:	70d7b923          	sd	a3,1810(a5) # ffffffffc02b5010 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202906:	100027f3          	csrr	a5,sstatus
ffffffffc020290a:	8b89                	andi	a5,a5,2
ffffffffc020290c:	4a079763          	bnez	a5,ffffffffc0202dba <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202910:	000b3783          	ld	a5,0(s6)
ffffffffc0202914:	779c                	ld	a5,40(a5)
ffffffffc0202916:	9782                	jalr	a5
ffffffffc0202918:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020291a:	6098                	ld	a4,0(s1)
ffffffffc020291c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202920:	83b1                	srli	a5,a5,0xc
ffffffffc0202922:	66e7e363          	bltu	a5,a4,ffffffffc0202f88 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202926:	00093503          	ld	a0,0(s2)
ffffffffc020292a:	62050f63          	beqz	a0,ffffffffc0202f68 <pmm_init+0x7ae>
ffffffffc020292e:	03451793          	slli	a5,a0,0x34
ffffffffc0202932:	62079b63          	bnez	a5,ffffffffc0202f68 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202936:	4601                	li	a2,0
ffffffffc0202938:	4581                	li	a1,0
ffffffffc020293a:	8c3ff0ef          	jal	ra,ffffffffc02021fc <get_page>
ffffffffc020293e:	60051563          	bnez	a0,ffffffffc0202f48 <pmm_init+0x78e>
ffffffffc0202942:	100027f3          	csrr	a5,sstatus
ffffffffc0202946:	8b89                	andi	a5,a5,2
ffffffffc0202948:	44079e63          	bnez	a5,ffffffffc0202da4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020294c:	000b3783          	ld	a5,0(s6)
ffffffffc0202950:	4505                	li	a0,1
ffffffffc0202952:	6f9c                	ld	a5,24(a5)
ffffffffc0202954:	9782                	jalr	a5
ffffffffc0202956:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202958:	00093503          	ld	a0,0(s2)
ffffffffc020295c:	4681                	li	a3,0
ffffffffc020295e:	4601                	li	a2,0
ffffffffc0202960:	85d2                	mv	a1,s4
ffffffffc0202962:	d63ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0202966:	26051ae3          	bnez	a0,ffffffffc02033da <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020296a:	00093503          	ld	a0,0(s2)
ffffffffc020296e:	4601                	li	a2,0
ffffffffc0202970:	4581                	li	a1,0
ffffffffc0202972:	e62ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0202976:	240502e3          	beqz	a0,ffffffffc02033ba <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020297a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020297c:	0017f713          	andi	a4,a5,1
ffffffffc0202980:	5a070263          	beqz	a4,ffffffffc0202f24 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202984:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202986:	078a                	slli	a5,a5,0x2
ffffffffc0202988:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020298a:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020298e:	000bb683          	ld	a3,0(s7)
ffffffffc0202992:	fff80637          	lui	a2,0xfff80
ffffffffc0202996:	97b2                	add	a5,a5,a2
ffffffffc0202998:	079a                	slli	a5,a5,0x6
ffffffffc020299a:	97b6                	add	a5,a5,a3
ffffffffc020299c:	14fa17e3          	bne	s4,a5,ffffffffc02032ea <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02029a0:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc02029a4:	4785                	li	a5,1
ffffffffc02029a6:	12f692e3          	bne	a3,a5,ffffffffc02032ca <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029aa:	00093503          	ld	a0,0(s2)
ffffffffc02029ae:	77fd                	lui	a5,0xfffff
ffffffffc02029b0:	6114                	ld	a3,0(a0)
ffffffffc02029b2:	068a                	slli	a3,a3,0x2
ffffffffc02029b4:	8efd                	and	a3,a3,a5
ffffffffc02029b6:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029ba:	0ee67ce3          	bgeu	a2,a4,ffffffffc02032b2 <pmm_init+0xaf8>
ffffffffc02029be:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029c2:	96e2                	add	a3,a3,s8
ffffffffc02029c4:	0006ba83          	ld	s5,0(a3)
ffffffffc02029c8:	0a8a                	slli	s5,s5,0x2
ffffffffc02029ca:	00fafab3          	and	s5,s5,a5
ffffffffc02029ce:	00cad793          	srli	a5,s5,0xc
ffffffffc02029d2:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203298 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029d6:	4601                	li	a2,0
ffffffffc02029d8:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029da:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029dc:	df8ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029e0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e2:	55551363          	bne	a0,s5,ffffffffc0202f28 <pmm_init+0x76e>
ffffffffc02029e6:	100027f3          	csrr	a5,sstatus
ffffffffc02029ea:	8b89                	andi	a5,a5,2
ffffffffc02029ec:	3a079163          	bnez	a5,ffffffffc0202d8e <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029f0:	000b3783          	ld	a5,0(s6)
ffffffffc02029f4:	4505                	li	a0,1
ffffffffc02029f6:	6f9c                	ld	a5,24(a5)
ffffffffc02029f8:	9782                	jalr	a5
ffffffffc02029fa:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029fc:	00093503          	ld	a0,0(s2)
ffffffffc0202a00:	46d1                	li	a3,20
ffffffffc0202a02:	6605                	lui	a2,0x1
ffffffffc0202a04:	85e2                	mv	a1,s8
ffffffffc0202a06:	cbfff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0202a0a:	060517e3          	bnez	a0,ffffffffc0203278 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a0e:	00093503          	ld	a0,0(s2)
ffffffffc0202a12:	4601                	li	a2,0
ffffffffc0202a14:	6585                	lui	a1,0x1
ffffffffc0202a16:	dbeff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0202a1a:	02050fe3          	beqz	a0,ffffffffc0203258 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a1e:	611c                	ld	a5,0(a0)
ffffffffc0202a20:	0107f713          	andi	a4,a5,16
ffffffffc0202a24:	7c070e63          	beqz	a4,ffffffffc0203200 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a28:	8b91                	andi	a5,a5,4
ffffffffc0202a2a:	7a078b63          	beqz	a5,ffffffffc02031e0 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a2e:	00093503          	ld	a0,0(s2)
ffffffffc0202a32:	611c                	ld	a5,0(a0)
ffffffffc0202a34:	8bc1                	andi	a5,a5,16
ffffffffc0202a36:	78078563          	beqz	a5,ffffffffc02031c0 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a3a:	000c2703          	lw	a4,0(s8)
ffffffffc0202a3e:	4785                	li	a5,1
ffffffffc0202a40:	76f71063          	bne	a4,a5,ffffffffc02031a0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a44:	4681                	li	a3,0
ffffffffc0202a46:	6605                	lui	a2,0x1
ffffffffc0202a48:	85d2                	mv	a1,s4
ffffffffc0202a4a:	c7bff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0202a4e:	72051963          	bnez	a0,ffffffffc0203180 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a52:	000a2703          	lw	a4,0(s4)
ffffffffc0202a56:	4789                	li	a5,2
ffffffffc0202a58:	70f71463          	bne	a4,a5,ffffffffc0203160 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a5c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a60:	6e079063          	bnez	a5,ffffffffc0203140 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a64:	00093503          	ld	a0,0(s2)
ffffffffc0202a68:	4601                	li	a2,0
ffffffffc0202a6a:	6585                	lui	a1,0x1
ffffffffc0202a6c:	d68ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0202a70:	6a050863          	beqz	a0,ffffffffc0203120 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a74:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a76:	00177793          	andi	a5,a4,1
ffffffffc0202a7a:	4a078563          	beqz	a5,ffffffffc0202f24 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a7e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a80:	00271793          	slli	a5,a4,0x2
ffffffffc0202a84:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a86:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a8a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a8e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a92:	97d6                	add	a5,a5,s5
ffffffffc0202a94:	079a                	slli	a5,a5,0x6
ffffffffc0202a96:	97b6                	add	a5,a5,a3
ffffffffc0202a98:	66fa1463          	bne	s4,a5,ffffffffc0203100 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a9c:	8b41                	andi	a4,a4,16
ffffffffc0202a9e:	64071163          	bnez	a4,ffffffffc02030e0 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202aa2:	00093503          	ld	a0,0(s2)
ffffffffc0202aa6:	4581                	li	a1,0
ffffffffc0202aa8:	b81ff0ef          	jal	ra,ffffffffc0202628 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202aac:	000a2c83          	lw	s9,0(s4)
ffffffffc0202ab0:	4785                	li	a5,1
ffffffffc0202ab2:	60fc9763          	bne	s9,a5,ffffffffc02030c0 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202ab6:	000c2783          	lw	a5,0(s8)
ffffffffc0202aba:	5e079363          	bnez	a5,ffffffffc02030a0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202abe:	00093503          	ld	a0,0(s2)
ffffffffc0202ac2:	6585                	lui	a1,0x1
ffffffffc0202ac4:	b65ff0ef          	jal	ra,ffffffffc0202628 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202ac8:	000a2783          	lw	a5,0(s4)
ffffffffc0202acc:	52079a63          	bnez	a5,ffffffffc0203000 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202ad0:	000c2783          	lw	a5,0(s8)
ffffffffc0202ad4:	50079663          	bnez	a5,ffffffffc0202fe0 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202ad8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202adc:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ade:	000a3683          	ld	a3,0(s4)
ffffffffc0202ae2:	068a                	slli	a3,a3,0x2
ffffffffc0202ae4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ae6:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aea:	000bb503          	ld	a0,0(s7)
ffffffffc0202aee:	96d6                	add	a3,a3,s5
ffffffffc0202af0:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202af2:	00d507b3          	add	a5,a0,a3
ffffffffc0202af6:	439c                	lw	a5,0(a5)
ffffffffc0202af8:	4d979463          	bne	a5,s9,ffffffffc0202fc0 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202afc:	8699                	srai	a3,a3,0x6
ffffffffc0202afe:	00080637          	lui	a2,0x80
ffffffffc0202b02:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202b04:	00c69713          	slli	a4,a3,0xc
ffffffffc0202b08:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b0a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202b0c:	48b77e63          	bgeu	a4,a1,ffffffffc0202fa8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b10:	0009b703          	ld	a4,0(s3)
ffffffffc0202b14:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b16:	629c                	ld	a5,0(a3)
ffffffffc0202b18:	078a                	slli	a5,a5,0x2
ffffffffc0202b1a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b1c:	40b7f263          	bgeu	a5,a1,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b20:	8f91                	sub	a5,a5,a2
ffffffffc0202b22:	079a                	slli	a5,a5,0x6
ffffffffc0202b24:	953e                	add	a0,a0,a5
ffffffffc0202b26:	100027f3          	csrr	a5,sstatus
ffffffffc0202b2a:	8b89                	andi	a5,a5,2
ffffffffc0202b2c:	30079963          	bnez	a5,ffffffffc0202e3e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b30:	000b3783          	ld	a5,0(s6)
ffffffffc0202b34:	4585                	li	a1,1
ffffffffc0202b36:	739c                	ld	a5,32(a5)
ffffffffc0202b38:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b3e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b40:	078a                	slli	a5,a5,0x2
ffffffffc0202b42:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b44:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b48:	000bb503          	ld	a0,0(s7)
ffffffffc0202b4c:	fff80737          	lui	a4,0xfff80
ffffffffc0202b50:	97ba                	add	a5,a5,a4
ffffffffc0202b52:	079a                	slli	a5,a5,0x6
ffffffffc0202b54:	953e                	add	a0,a0,a5
ffffffffc0202b56:	100027f3          	csrr	a5,sstatus
ffffffffc0202b5a:	8b89                	andi	a5,a5,2
ffffffffc0202b5c:	2c079563          	bnez	a5,ffffffffc0202e26 <pmm_init+0x66c>
ffffffffc0202b60:	000b3783          	ld	a5,0(s6)
ffffffffc0202b64:	4585                	li	a1,1
ffffffffc0202b66:	739c                	ld	a5,32(a5)
ffffffffc0202b68:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b6a:	00093783          	ld	a5,0(s2)
ffffffffc0202b6e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd49f94>
    asm volatile("sfence.vma");
ffffffffc0202b72:	12000073          	sfence.vma
ffffffffc0202b76:	100027f3          	csrr	a5,sstatus
ffffffffc0202b7a:	8b89                	andi	a5,a5,2
ffffffffc0202b7c:	28079b63          	bnez	a5,ffffffffc0202e12 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b80:	000b3783          	ld	a5,0(s6)
ffffffffc0202b84:	779c                	ld	a5,40(a5)
ffffffffc0202b86:	9782                	jalr	a5
ffffffffc0202b88:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b8a:	4b441b63          	bne	s0,s4,ffffffffc0203040 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b8e:	00004517          	auipc	a0,0x4
ffffffffc0202b92:	1fa50513          	addi	a0,a0,506 # ffffffffc0206d88 <default_pmm_manager+0x560>
ffffffffc0202b96:	dfefd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b9a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b9e:	8b89                	andi	a5,a5,2
ffffffffc0202ba0:	24079f63          	bnez	a5,ffffffffc0202dfe <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ba4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ba8:	779c                	ld	a5,40(a5)
ffffffffc0202baa:	9782                	jalr	a5
ffffffffc0202bac:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bae:	6098                	ld	a4,0(s1)
ffffffffc0202bb0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bb4:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bb6:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bba:	6a05                	lui	s4,0x1
ffffffffc0202bbc:	02f47c63          	bgeu	s0,a5,ffffffffc0202bf4 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bc0:	00c45793          	srli	a5,s0,0xc
ffffffffc0202bc4:	00093503          	ld	a0,0(s2)
ffffffffc0202bc8:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202ec6 <pmm_init+0x70c>
ffffffffc0202bcc:	0009b583          	ld	a1,0(s3)
ffffffffc0202bd0:	4601                	li	a2,0
ffffffffc0202bd2:	95a2                	add	a1,a1,s0
ffffffffc0202bd4:	c00ff0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0202bd8:	32050463          	beqz	a0,ffffffffc0202f00 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bdc:	611c                	ld	a5,0(a0)
ffffffffc0202bde:	078a                	slli	a5,a5,0x2
ffffffffc0202be0:	0157f7b3          	and	a5,a5,s5
ffffffffc0202be4:	2e879e63          	bne	a5,s0,ffffffffc0202ee0 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202be8:	6098                	ld	a4,0(s1)
ffffffffc0202bea:	9452                	add	s0,s0,s4
ffffffffc0202bec:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bf0:	fcf468e3          	bltu	s0,a5,ffffffffc0202bc0 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bf4:	00093783          	ld	a5,0(s2)
ffffffffc0202bf8:	639c                	ld	a5,0(a5)
ffffffffc0202bfa:	42079363          	bnez	a5,ffffffffc0203020 <pmm_init+0x866>
ffffffffc0202bfe:	100027f3          	csrr	a5,sstatus
ffffffffc0202c02:	8b89                	andi	a5,a5,2
ffffffffc0202c04:	24079963          	bnez	a5,ffffffffc0202e56 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c08:	000b3783          	ld	a5,0(s6)
ffffffffc0202c0c:	4505                	li	a0,1
ffffffffc0202c0e:	6f9c                	ld	a5,24(a5)
ffffffffc0202c10:	9782                	jalr	a5
ffffffffc0202c12:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c14:	00093503          	ld	a0,0(s2)
ffffffffc0202c18:	4699                	li	a3,6
ffffffffc0202c1a:	10000613          	li	a2,256
ffffffffc0202c1e:	85d2                	mv	a1,s4
ffffffffc0202c20:	aa5ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0202c24:	44051e63          	bnez	a0,ffffffffc0203080 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c28:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc0202c2c:	4785                	li	a5,1
ffffffffc0202c2e:	42f71963          	bne	a4,a5,ffffffffc0203060 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c32:	00093503          	ld	a0,0(s2)
ffffffffc0202c36:	6405                	lui	s0,0x1
ffffffffc0202c38:	4699                	li	a3,6
ffffffffc0202c3a:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab0>
ffffffffc0202c3e:	85d2                	mv	a1,s4
ffffffffc0202c40:	a85ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0202c44:	72051363          	bnez	a0,ffffffffc020336a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c48:	000a2703          	lw	a4,0(s4)
ffffffffc0202c4c:	4789                	li	a5,2
ffffffffc0202c4e:	6ef71e63          	bne	a4,a5,ffffffffc020334a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c52:	00004597          	auipc	a1,0x4
ffffffffc0202c56:	27e58593          	addi	a1,a1,638 # ffffffffc0206ed0 <default_pmm_manager+0x6a8>
ffffffffc0202c5a:	10000513          	li	a0,256
ffffffffc0202c5e:	4db020ef          	jal	ra,ffffffffc0205938 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c62:	10040593          	addi	a1,s0,256
ffffffffc0202c66:	10000513          	li	a0,256
ffffffffc0202c6a:	4e1020ef          	jal	ra,ffffffffc020594a <strcmp>
ffffffffc0202c6e:	6a051e63          	bnez	a0,ffffffffc020332a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c72:	000bb683          	ld	a3,0(s7)
ffffffffc0202c76:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c7a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c7c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c80:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c82:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c84:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c86:	8031                	srli	s0,s0,0xc
ffffffffc0202c88:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c8c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c8e:	30f77d63          	bgeu	a4,a5,ffffffffc0202fa8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c92:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c96:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c9a:	96be                	add	a3,a3,a5
ffffffffc0202c9c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca0:	463020ef          	jal	ra,ffffffffc0205902 <strlen>
ffffffffc0202ca4:	66051363          	bnez	a0,ffffffffc020330a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202ca8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cac:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cae:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd49f94>
ffffffffc0202cb2:	068a                	slli	a3,a3,0x2
ffffffffc0202cb4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cb6:	26f6f563          	bgeu	a3,a5,ffffffffc0202f20 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202cba:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cbc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cbe:	2ef47563          	bgeu	s0,a5,ffffffffc0202fa8 <pmm_init+0x7ee>
ffffffffc0202cc2:	0009b403          	ld	s0,0(s3)
ffffffffc0202cc6:	9436                	add	s0,s0,a3
ffffffffc0202cc8:	100027f3          	csrr	a5,sstatus
ffffffffc0202ccc:	8b89                	andi	a5,a5,2
ffffffffc0202cce:	1e079163          	bnez	a5,ffffffffc0202eb0 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202cd2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd6:	4585                	li	a1,1
ffffffffc0202cd8:	8552                	mv	a0,s4
ffffffffc0202cda:	739c                	ld	a5,32(a5)
ffffffffc0202cdc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cde:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202ce0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ce2:	078a                	slli	a5,a5,0x2
ffffffffc0202ce4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ce6:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cea:	000bb503          	ld	a0,0(s7)
ffffffffc0202cee:	fff80737          	lui	a4,0xfff80
ffffffffc0202cf2:	97ba                	add	a5,a5,a4
ffffffffc0202cf4:	079a                	slli	a5,a5,0x6
ffffffffc0202cf6:	953e                	add	a0,a0,a5
ffffffffc0202cf8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cfc:	8b89                	andi	a5,a5,2
ffffffffc0202cfe:	18079d63          	bnez	a5,ffffffffc0202e98 <pmm_init+0x6de>
ffffffffc0202d02:	000b3783          	ld	a5,0(s6)
ffffffffc0202d06:	4585                	li	a1,1
ffffffffc0202d08:	739c                	ld	a5,32(a5)
ffffffffc0202d0a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d0c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202d10:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d12:	078a                	slli	a5,a5,0x2
ffffffffc0202d14:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d16:	20e7f563          	bgeu	a5,a4,ffffffffc0202f20 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d1a:	000bb503          	ld	a0,0(s7)
ffffffffc0202d1e:	fff80737          	lui	a4,0xfff80
ffffffffc0202d22:	97ba                	add	a5,a5,a4
ffffffffc0202d24:	079a                	slli	a5,a5,0x6
ffffffffc0202d26:	953e                	add	a0,a0,a5
ffffffffc0202d28:	100027f3          	csrr	a5,sstatus
ffffffffc0202d2c:	8b89                	andi	a5,a5,2
ffffffffc0202d2e:	14079963          	bnez	a5,ffffffffc0202e80 <pmm_init+0x6c6>
ffffffffc0202d32:	000b3783          	ld	a5,0(s6)
ffffffffc0202d36:	4585                	li	a1,1
ffffffffc0202d38:	739c                	ld	a5,32(a5)
ffffffffc0202d3a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d3c:	00093783          	ld	a5,0(s2)
ffffffffc0202d40:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d44:	12000073          	sfence.vma
ffffffffc0202d48:	100027f3          	csrr	a5,sstatus
ffffffffc0202d4c:	8b89                	andi	a5,a5,2
ffffffffc0202d4e:	10079f63          	bnez	a5,ffffffffc0202e6c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	779c                	ld	a5,40(a5)
ffffffffc0202d58:	9782                	jalr	a5
ffffffffc0202d5a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d5c:	4c8c1e63          	bne	s8,s0,ffffffffc0203238 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d60:	00004517          	auipc	a0,0x4
ffffffffc0202d64:	1e850513          	addi	a0,a0,488 # ffffffffc0206f48 <default_pmm_manager+0x720>
ffffffffc0202d68:	c2cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d6c:	7406                	ld	s0,96(sp)
ffffffffc0202d6e:	70a6                	ld	ra,104(sp)
ffffffffc0202d70:	64e6                	ld	s1,88(sp)
ffffffffc0202d72:	6946                	ld	s2,80(sp)
ffffffffc0202d74:	69a6                	ld	s3,72(sp)
ffffffffc0202d76:	6a06                	ld	s4,64(sp)
ffffffffc0202d78:	7ae2                	ld	s5,56(sp)
ffffffffc0202d7a:	7b42                	ld	s6,48(sp)
ffffffffc0202d7c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d7e:	7c02                	ld	s8,32(sp)
ffffffffc0202d80:	6ce2                	ld	s9,24(sp)
ffffffffc0202d82:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d84:	f97fe06f          	j	ffffffffc0201d1a <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d88:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d8c:	bc7d                	j	ffffffffc020284a <pmm_init+0x90>
        intr_disable();
ffffffffc0202d8e:	c27fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d92:	000b3783          	ld	a5,0(s6)
ffffffffc0202d96:	4505                	li	a0,1
ffffffffc0202d98:	6f9c                	ld	a5,24(a5)
ffffffffc0202d9a:	9782                	jalr	a5
ffffffffc0202d9c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d9e:	c11fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202da2:	b9a9                	j	ffffffffc02029fc <pmm_init+0x242>
        intr_disable();
ffffffffc0202da4:	c11fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202da8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dac:	4505                	li	a0,1
ffffffffc0202dae:	6f9c                	ld	a5,24(a5)
ffffffffc0202db0:	9782                	jalr	a5
ffffffffc0202db2:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202db4:	bfbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202db8:	b645                	j	ffffffffc0202958 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202dba:	bfbfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dbe:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc2:	779c                	ld	a5,40(a5)
ffffffffc0202dc4:	9782                	jalr	a5
ffffffffc0202dc6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dc8:	be7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dcc:	b6b9                	j	ffffffffc020291a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dce:	6705                	lui	a4,0x1
ffffffffc0202dd0:	177d                	addi	a4,a4,-1
ffffffffc0202dd2:	96ba                	add	a3,a3,a4
ffffffffc0202dd4:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202dd6:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dda:	14a77363          	bgeu	a4,a0,ffffffffc0202f20 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dde:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202de2:	fff80537          	lui	a0,0xfff80
ffffffffc0202de6:	972a                	add	a4,a4,a0
ffffffffc0202de8:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202dea:	8c1d                	sub	s0,s0,a5
ffffffffc0202dec:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202df0:	00c45593          	srli	a1,s0,0xc
ffffffffc0202df4:	9532                	add	a0,a0,a2
ffffffffc0202df6:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202df8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202dfc:	b4c1                	j	ffffffffc02028bc <pmm_init+0x102>
        intr_disable();
ffffffffc0202dfe:	bb7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e02:	000b3783          	ld	a5,0(s6)
ffffffffc0202e06:	779c                	ld	a5,40(a5)
ffffffffc0202e08:	9782                	jalr	a5
ffffffffc0202e0a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e0c:	ba3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e10:	bb79                	j	ffffffffc0202bae <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e12:	ba3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e16:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1a:	779c                	ld	a5,40(a5)
ffffffffc0202e1c:	9782                	jalr	a5
ffffffffc0202e1e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e20:	b8ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e24:	b39d                	j	ffffffffc0202b8a <pmm_init+0x3d0>
ffffffffc0202e26:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e28:	b8dfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e30:	6522                	ld	a0,8(sp)
ffffffffc0202e32:	4585                	li	a1,1
ffffffffc0202e34:	739c                	ld	a5,32(a5)
ffffffffc0202e36:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e38:	b77fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e3c:	b33d                	j	ffffffffc0202b6a <pmm_init+0x3b0>
ffffffffc0202e3e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e40:	b75fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e44:	000b3783          	ld	a5,0(s6)
ffffffffc0202e48:	6522                	ld	a0,8(sp)
ffffffffc0202e4a:	4585                	li	a1,1
ffffffffc0202e4c:	739c                	ld	a5,32(a5)
ffffffffc0202e4e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e50:	b5ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e54:	b1dd                	j	ffffffffc0202b3a <pmm_init+0x380>
        intr_disable();
ffffffffc0202e56:	b5ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e5a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5e:	4505                	li	a0,1
ffffffffc0202e60:	6f9c                	ld	a5,24(a5)
ffffffffc0202e62:	9782                	jalr	a5
ffffffffc0202e64:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e66:	b49fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e6a:	b36d                	j	ffffffffc0202c14 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e6c:	b49fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e70:	000b3783          	ld	a5,0(s6)
ffffffffc0202e74:	779c                	ld	a5,40(a5)
ffffffffc0202e76:	9782                	jalr	a5
ffffffffc0202e78:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e7a:	b35fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e7e:	bdf9                	j	ffffffffc0202d5c <pmm_init+0x5a2>
ffffffffc0202e80:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e82:	b33fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e86:	000b3783          	ld	a5,0(s6)
ffffffffc0202e8a:	6522                	ld	a0,8(sp)
ffffffffc0202e8c:	4585                	li	a1,1
ffffffffc0202e8e:	739c                	ld	a5,32(a5)
ffffffffc0202e90:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e92:	b1dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e96:	b55d                	j	ffffffffc0202d3c <pmm_init+0x582>
ffffffffc0202e98:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e9a:	b1bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e9e:	000b3783          	ld	a5,0(s6)
ffffffffc0202ea2:	6522                	ld	a0,8(sp)
ffffffffc0202ea4:	4585                	li	a1,1
ffffffffc0202ea6:	739c                	ld	a5,32(a5)
ffffffffc0202ea8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eaa:	b05fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202eae:	bdb9                	j	ffffffffc0202d0c <pmm_init+0x552>
        intr_disable();
ffffffffc0202eb0:	b05fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202eb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202eb8:	4585                	li	a1,1
ffffffffc0202eba:	8552                	mv	a0,s4
ffffffffc0202ebc:	739c                	ld	a5,32(a5)
ffffffffc0202ebe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ec0:	aeffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202ec4:	bd29                	j	ffffffffc0202cde <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ec6:	86a2                	mv	a3,s0
ffffffffc0202ec8:	00004617          	auipc	a2,0x4
ffffffffc0202ecc:	99860613          	addi	a2,a2,-1640 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc0202ed0:	24500593          	li	a1,581
ffffffffc0202ed4:	00004517          	auipc	a0,0x4
ffffffffc0202ed8:	aa450513          	addi	a0,a0,-1372 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202edc:	db2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ee0:	00004697          	auipc	a3,0x4
ffffffffc0202ee4:	f0868693          	addi	a3,a3,-248 # ffffffffc0206de8 <default_pmm_manager+0x5c0>
ffffffffc0202ee8:	00003617          	auipc	a2,0x3
ffffffffc0202eec:	34860613          	addi	a2,a2,840 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202ef0:	24600593          	li	a1,582
ffffffffc0202ef4:	00004517          	auipc	a0,0x4
ffffffffc0202ef8:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202efc:	d92fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f00:	00004697          	auipc	a3,0x4
ffffffffc0202f04:	ea868693          	addi	a3,a3,-344 # ffffffffc0206da8 <default_pmm_manager+0x580>
ffffffffc0202f08:	00003617          	auipc	a2,0x3
ffffffffc0202f0c:	32860613          	addi	a2,a2,808 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202f10:	24500593          	li	a1,581
ffffffffc0202f14:	00004517          	auipc	a0,0x4
ffffffffc0202f18:	a6450513          	addi	a0,a0,-1436 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202f1c:	d72fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202f20:	fc5fe0ef          	jal	ra,ffffffffc0201ee4 <pa2page.part.0>
ffffffffc0202f24:	fddfe0ef          	jal	ra,ffffffffc0201f00 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f28:	00004697          	auipc	a3,0x4
ffffffffc0202f2c:	c7868693          	addi	a3,a3,-904 # ffffffffc0206ba0 <default_pmm_manager+0x378>
ffffffffc0202f30:	00003617          	auipc	a2,0x3
ffffffffc0202f34:	30060613          	addi	a2,a2,768 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202f38:	21500593          	li	a1,533
ffffffffc0202f3c:	00004517          	auipc	a0,0x4
ffffffffc0202f40:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202f44:	d4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f48:	00004697          	auipc	a3,0x4
ffffffffc0202f4c:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206ae0 <default_pmm_manager+0x2b8>
ffffffffc0202f50:	00003617          	auipc	a2,0x3
ffffffffc0202f54:	2e060613          	addi	a2,a2,736 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202f58:	20800593          	li	a1,520
ffffffffc0202f5c:	00004517          	auipc	a0,0x4
ffffffffc0202f60:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202f64:	d2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f68:	00004697          	auipc	a3,0x4
ffffffffc0202f6c:	b3868693          	addi	a3,a3,-1224 # ffffffffc0206aa0 <default_pmm_manager+0x278>
ffffffffc0202f70:	00003617          	auipc	a2,0x3
ffffffffc0202f74:	2c060613          	addi	a2,a2,704 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202f78:	20700593          	li	a1,519
ffffffffc0202f7c:	00004517          	auipc	a0,0x4
ffffffffc0202f80:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202f84:	d0afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	af868693          	addi	a3,a3,-1288 # ffffffffc0206a80 <default_pmm_manager+0x258>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	2a060613          	addi	a2,a2,672 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202f98:	20600593          	li	a1,518
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202fa4:	ceafd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fa8:	00004617          	auipc	a2,0x4
ffffffffc0202fac:	8b860613          	addi	a2,a2,-1864 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc0202fb0:	07100593          	li	a1,113
ffffffffc0202fb4:	00004517          	auipc	a0,0x4
ffffffffc0202fb8:	8d450513          	addi	a0,a0,-1836 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0202fbc:	cd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fc0:	00004697          	auipc	a3,0x4
ffffffffc0202fc4:	d7068693          	addi	a3,a3,-656 # ffffffffc0206d30 <default_pmm_manager+0x508>
ffffffffc0202fc8:	00003617          	auipc	a2,0x3
ffffffffc0202fcc:	26860613          	addi	a2,a2,616 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202fd0:	22e00593          	li	a1,558
ffffffffc0202fd4:	00004517          	auipc	a0,0x4
ffffffffc0202fd8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202fdc:	cb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fe0:	00004697          	auipc	a3,0x4
ffffffffc0202fe4:	d0868693          	addi	a3,a3,-760 # ffffffffc0206ce8 <default_pmm_manager+0x4c0>
ffffffffc0202fe8:	00003617          	auipc	a2,0x3
ffffffffc0202fec:	24860613          	addi	a2,a2,584 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0202ff0:	22c00593          	li	a1,556
ffffffffc0202ff4:	00004517          	auipc	a0,0x4
ffffffffc0202ff8:	98450513          	addi	a0,a0,-1660 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0202ffc:	c92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203000:	00004697          	auipc	a3,0x4
ffffffffc0203004:	d1868693          	addi	a3,a3,-744 # ffffffffc0206d18 <default_pmm_manager+0x4f0>
ffffffffc0203008:	00003617          	auipc	a2,0x3
ffffffffc020300c:	22860613          	addi	a2,a2,552 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203010:	22b00593          	li	a1,555
ffffffffc0203014:	00004517          	auipc	a0,0x4
ffffffffc0203018:	96450513          	addi	a0,a0,-1692 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020301c:	c72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203020:	00004697          	auipc	a3,0x4
ffffffffc0203024:	de068693          	addi	a3,a3,-544 # ffffffffc0206e00 <default_pmm_manager+0x5d8>
ffffffffc0203028:	00003617          	auipc	a2,0x3
ffffffffc020302c:	20860613          	addi	a2,a2,520 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203030:	24900593          	li	a1,585
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	94450513          	addi	a0,a0,-1724 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020303c:	c52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	d2068693          	addi	a3,a3,-736 # ffffffffc0206d60 <default_pmm_manager+0x538>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	1e860613          	addi	a2,a2,488 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203050:	23600593          	li	a1,566
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	92450513          	addi	a0,a0,-1756 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020305c:	c32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	df868693          	addi	a3,a3,-520 # ffffffffc0206e58 <default_pmm_manager+0x630>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	1c860613          	addi	a2,a2,456 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203070:	24e00593          	li	a1,590
ffffffffc0203074:	00004517          	auipc	a0,0x4
ffffffffc0203078:	90450513          	addi	a0,a0,-1788 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020307c:	c12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	d9868693          	addi	a3,a3,-616 # ffffffffc0206e18 <default_pmm_manager+0x5f0>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	1a860613          	addi	a2,a2,424 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203090:	24d00593          	li	a1,589
ffffffffc0203094:	00004517          	auipc	a0,0x4
ffffffffc0203098:	8e450513          	addi	a0,a0,-1820 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020309c:	bf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	c4868693          	addi	a3,a3,-952 # ffffffffc0206ce8 <default_pmm_manager+0x4c0>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	18860613          	addi	a2,a2,392 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02030b0:	22800593          	li	a1,552
ffffffffc02030b4:	00004517          	auipc	a0,0x4
ffffffffc02030b8:	8c450513          	addi	a0,a0,-1852 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02030bc:	bd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	ac868693          	addi	a3,a3,-1336 # ffffffffc0206b88 <default_pmm_manager+0x360>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	16860613          	addi	a2,a2,360 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02030d0:	22700593          	li	a1,551
ffffffffc02030d4:	00004517          	auipc	a0,0x4
ffffffffc02030d8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02030dc:	bb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	c2068693          	addi	a3,a3,-992 # ffffffffc0206d00 <default_pmm_manager+0x4d8>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	14860613          	addi	a2,a2,328 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02030f0:	22400593          	li	a1,548
ffffffffc02030f4:	00004517          	auipc	a0,0x4
ffffffffc02030f8:	88450513          	addi	a0,a0,-1916 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02030fc:	b92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206b70 <default_pmm_manager+0x348>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	12860613          	addi	a2,a2,296 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203110:	22300593          	li	a1,547
ffffffffc0203114:	00004517          	auipc	a0,0x4
ffffffffc0203118:	86450513          	addi	a0,a0,-1948 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020311c:	b72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	af068693          	addi	a3,a3,-1296 # ffffffffc0206c10 <default_pmm_manager+0x3e8>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	10860613          	addi	a2,a2,264 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203130:	22200593          	li	a1,546
ffffffffc0203134:	00004517          	auipc	a0,0x4
ffffffffc0203138:	84450513          	addi	a0,a0,-1980 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020313c:	b52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	ba868693          	addi	a3,a3,-1112 # ffffffffc0206ce8 <default_pmm_manager+0x4c0>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	0e860613          	addi	a2,a2,232 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203150:	22100593          	li	a1,545
ffffffffc0203154:	00004517          	auipc	a0,0x4
ffffffffc0203158:	82450513          	addi	a0,a0,-2012 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020315c:	b32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206cd0 <default_pmm_manager+0x4a8>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	0c860613          	addi	a2,a2,200 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203170:	22000593          	li	a1,544
ffffffffc0203174:	00004517          	auipc	a0,0x4
ffffffffc0203178:	80450513          	addi	a0,a0,-2044 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020317c:	b12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206ca0 <default_pmm_manager+0x478>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	0a860613          	addi	a2,a2,168 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203190:	21f00593          	li	a1,543
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	7e450513          	addi	a0,a0,2020 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020319c:	af2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	ae868693          	addi	a3,a3,-1304 # ffffffffc0206c88 <default_pmm_manager+0x460>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	08860613          	addi	a2,a2,136 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02031b0:	21d00593          	li	a1,541
ffffffffc02031b4:	00003517          	auipc	a0,0x3
ffffffffc02031b8:	7c450513          	addi	a0,a0,1988 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02031bc:	ad2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	aa868693          	addi	a3,a3,-1368 # ffffffffc0206c68 <default_pmm_manager+0x440>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	06860613          	addi	a2,a2,104 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02031d0:	21c00593          	li	a1,540
ffffffffc02031d4:	00003517          	auipc	a0,0x3
ffffffffc02031d8:	7a450513          	addi	a0,a0,1956 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02031dc:	ab2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031e0:	00004697          	auipc	a3,0x4
ffffffffc02031e4:	a7868693          	addi	a3,a3,-1416 # ffffffffc0206c58 <default_pmm_manager+0x430>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	04860613          	addi	a2,a2,72 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02031f0:	21b00593          	li	a1,539
ffffffffc02031f4:	00003517          	auipc	a0,0x3
ffffffffc02031f8:	78450513          	addi	a0,a0,1924 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02031fc:	a92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	a4868693          	addi	a3,a3,-1464 # ffffffffc0206c48 <default_pmm_manager+0x420>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	02860613          	addi	a2,a2,40 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203210:	21a00593          	li	a1,538
ffffffffc0203214:	00003517          	auipc	a0,0x3
ffffffffc0203218:	76450513          	addi	a0,a0,1892 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020321c:	a72fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc0203220:	00003617          	auipc	a2,0x3
ffffffffc0203224:	7c860613          	addi	a2,a2,1992 # ffffffffc02069e8 <default_pmm_manager+0x1c0>
ffffffffc0203228:	06500593          	li	a1,101
ffffffffc020322c:	00003517          	auipc	a0,0x3
ffffffffc0203230:	74c50513          	addi	a0,a0,1868 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203234:	a5afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203238:	00004697          	auipc	a3,0x4
ffffffffc020323c:	b2868693          	addi	a3,a3,-1240 # ffffffffc0206d60 <default_pmm_manager+0x538>
ffffffffc0203240:	00003617          	auipc	a2,0x3
ffffffffc0203244:	ff060613          	addi	a2,a2,-16 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203248:	26000593          	li	a1,608
ffffffffc020324c:	00003517          	auipc	a0,0x3
ffffffffc0203250:	72c50513          	addi	a0,a0,1836 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203254:	a3afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203258:	00004697          	auipc	a3,0x4
ffffffffc020325c:	9b868693          	addi	a3,a3,-1608 # ffffffffc0206c10 <default_pmm_manager+0x3e8>
ffffffffc0203260:	00003617          	auipc	a2,0x3
ffffffffc0203264:	fd060613          	addi	a2,a2,-48 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203268:	21900593          	li	a1,537
ffffffffc020326c:	00003517          	auipc	a0,0x3
ffffffffc0203270:	70c50513          	addi	a0,a0,1804 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203274:	a1afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203278:	00004697          	auipc	a3,0x4
ffffffffc020327c:	95868693          	addi	a3,a3,-1704 # ffffffffc0206bd0 <default_pmm_manager+0x3a8>
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	fb060613          	addi	a2,a2,-80 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203288:	21800593          	li	a1,536
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203294:	9fafd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203298:	86d6                	mv	a3,s5
ffffffffc020329a:	00003617          	auipc	a2,0x3
ffffffffc020329e:	5c660613          	addi	a2,a2,1478 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02032a2:	21400593          	li	a1,532
ffffffffc02032a6:	00003517          	auipc	a0,0x3
ffffffffc02032aa:	6d250513          	addi	a0,a0,1746 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02032ae:	9e0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032b2:	00003617          	auipc	a2,0x3
ffffffffc02032b6:	5ae60613          	addi	a2,a2,1454 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02032ba:	21300593          	li	a1,531
ffffffffc02032be:	00003517          	auipc	a0,0x3
ffffffffc02032c2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02032c6:	9c8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032ca:	00004697          	auipc	a3,0x4
ffffffffc02032ce:	8be68693          	addi	a3,a3,-1858 # ffffffffc0206b88 <default_pmm_manager+0x360>
ffffffffc02032d2:	00003617          	auipc	a2,0x3
ffffffffc02032d6:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02032da:	21100593          	li	a1,529
ffffffffc02032de:	00003517          	auipc	a0,0x3
ffffffffc02032e2:	69a50513          	addi	a0,a0,1690 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02032e6:	9a8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032ea:	00004697          	auipc	a3,0x4
ffffffffc02032ee:	88668693          	addi	a3,a3,-1914 # ffffffffc0206b70 <default_pmm_manager+0x348>
ffffffffc02032f2:	00003617          	auipc	a2,0x3
ffffffffc02032f6:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02032fa:	21000593          	li	a1,528
ffffffffc02032fe:	00003517          	auipc	a0,0x3
ffffffffc0203302:	67a50513          	addi	a0,a0,1658 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203306:	988fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020330a:	00004697          	auipc	a3,0x4
ffffffffc020330e:	c1668693          	addi	a3,a3,-1002 # ffffffffc0206f20 <default_pmm_manager+0x6f8>
ffffffffc0203312:	00003617          	auipc	a2,0x3
ffffffffc0203316:	f1e60613          	addi	a2,a2,-226 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020331a:	25700593          	li	a1,599
ffffffffc020331e:	00003517          	auipc	a0,0x3
ffffffffc0203322:	65a50513          	addi	a0,a0,1626 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203326:	968fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020332a:	00004697          	auipc	a3,0x4
ffffffffc020332e:	bbe68693          	addi	a3,a3,-1090 # ffffffffc0206ee8 <default_pmm_manager+0x6c0>
ffffffffc0203332:	00003617          	auipc	a2,0x3
ffffffffc0203336:	efe60613          	addi	a2,a2,-258 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020333a:	25400593          	li	a1,596
ffffffffc020333e:	00003517          	auipc	a0,0x3
ffffffffc0203342:	63a50513          	addi	a0,a0,1594 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203346:	948fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020334a:	00004697          	auipc	a3,0x4
ffffffffc020334e:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0206eb8 <default_pmm_manager+0x690>
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	ede60613          	addi	a2,a2,-290 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020335a:	25000593          	li	a1,592
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	61a50513          	addi	a0,a0,1562 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020336a:	00004697          	auipc	a3,0x4
ffffffffc020336e:	b0668693          	addi	a3,a3,-1274 # ffffffffc0206e70 <default_pmm_manager+0x648>
ffffffffc0203372:	00003617          	auipc	a2,0x3
ffffffffc0203376:	ebe60613          	addi	a2,a2,-322 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020337a:	24f00593          	li	a1,591
ffffffffc020337e:	00003517          	auipc	a0,0x3
ffffffffc0203382:	5fa50513          	addi	a0,a0,1530 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203386:	908fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020338a:	00003617          	auipc	a2,0x3
ffffffffc020338e:	57e60613          	addi	a2,a2,1406 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc0203392:	0c900593          	li	a1,201
ffffffffc0203396:	00003517          	auipc	a0,0x3
ffffffffc020339a:	5e250513          	addi	a0,a0,1506 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc020339e:	8f0fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02033a2:	00003617          	auipc	a2,0x3
ffffffffc02033a6:	56660613          	addi	a2,a2,1382 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc02033aa:	08100593          	li	a1,129
ffffffffc02033ae:	00003517          	auipc	a0,0x3
ffffffffc02033b2:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02033b6:	8d8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033ba:	00003697          	auipc	a3,0x3
ffffffffc02033be:	78668693          	addi	a3,a3,1926 # ffffffffc0206b40 <default_pmm_manager+0x318>
ffffffffc02033c2:	00003617          	auipc	a2,0x3
ffffffffc02033c6:	e6e60613          	addi	a2,a2,-402 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02033ca:	20f00593          	li	a1,527
ffffffffc02033ce:	00003517          	auipc	a0,0x3
ffffffffc02033d2:	5aa50513          	addi	a0,a0,1450 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02033d6:	8b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033da:	00003697          	auipc	a3,0x3
ffffffffc02033de:	73668693          	addi	a3,a3,1846 # ffffffffc0206b10 <default_pmm_manager+0x2e8>
ffffffffc02033e2:	00003617          	auipc	a2,0x3
ffffffffc02033e6:	e4e60613          	addi	a2,a2,-434 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02033ea:	20c00593          	li	a1,524
ffffffffc02033ee:	00003517          	auipc	a0,0x3
ffffffffc02033f2:	58a50513          	addi	a0,a0,1418 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02033f6:	898fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02033fa <copy_range>:
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc02033fa:	7119                	addi	sp,sp,-128
ffffffffc02033fc:	f4a6                	sd	s1,104(sp)
ffffffffc02033fe:	84b6                	mv	s1,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203400:	8ed1                	or	a3,a3,a2
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc0203402:	fc86                	sd	ra,120(sp)
ffffffffc0203404:	f8a2                	sd	s0,112(sp)
ffffffffc0203406:	f0ca                	sd	s2,96(sp)
ffffffffc0203408:	ecce                	sd	s3,88(sp)
ffffffffc020340a:	e8d2                	sd	s4,80(sp)
ffffffffc020340c:	e4d6                	sd	s5,72(sp)
ffffffffc020340e:	e0da                	sd	s6,64(sp)
ffffffffc0203410:	fc5e                	sd	s7,56(sp)
ffffffffc0203412:	f862                	sd	s8,48(sp)
ffffffffc0203414:	f466                	sd	s9,40(sp)
ffffffffc0203416:	f06a                	sd	s10,32(sp)
ffffffffc0203418:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020341a:	16d2                	slli	a3,a3,0x34
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc020341c:	e43a                	sd	a4,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020341e:	24069663          	bnez	a3,ffffffffc020366a <copy_range+0x270>
    assert(USER_ACCESS(start, end));
ffffffffc0203422:	00200737          	lui	a4,0x200
ffffffffc0203426:	8db2                	mv	s11,a2
ffffffffc0203428:	22e66163          	bltu	a2,a4,ffffffffc020364a <copy_range+0x250>
ffffffffc020342c:	20967f63          	bgeu	a2,s1,ffffffffc020364a <copy_range+0x250>
ffffffffc0203430:	4705                	li	a4,1
ffffffffc0203432:	077e                	slli	a4,a4,0x1f
ffffffffc0203434:	20976b63          	bltu	a4,s1,ffffffffc020364a <copy_range+0x250>
ffffffffc0203438:	5bfd                	li	s7,-1
ffffffffc020343a:	8a2a                	mv	s4,a0
ffffffffc020343c:	842e                	mv	s0,a1
        start += PGSIZE;
ffffffffc020343e:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc0203440:	000b2b17          	auipc	s6,0xb2
ffffffffc0203444:	be0b0b13          	addi	s6,s6,-1056 # ffffffffc02b5020 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203448:	000b2a97          	auipc	s5,0xb2
ffffffffc020344c:	be0a8a93          	addi	s5,s5,-1056 # ffffffffc02b5028 <pages>
    return KADDR(page2pa(page));
ffffffffc0203450:	00cbdb93          	srli	s7,s7,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203454:	000b2d17          	auipc	s10,0xb2
ffffffffc0203458:	bdcd0d13          	addi	s10,s10,-1060 # ffffffffc02b5030 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020345c:	4601                	li	a2,0
ffffffffc020345e:	85ee                	mv	a1,s11
ffffffffc0203460:	8522                	mv	a0,s0
ffffffffc0203462:	b73fe0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0203466:	892a                	mv	s2,a0
        if (ptep == NULL) {
ffffffffc0203468:	c951                	beqz	a0,ffffffffc02034fc <copy_range+0x102>
        if (*ptep & PTE_V) {
ffffffffc020346a:	6118                	ld	a4,0(a0)
ffffffffc020346c:	8b05                	andi	a4,a4,1
ffffffffc020346e:	e705                	bnez	a4,ffffffffc0203496 <copy_range+0x9c>
        start += PGSIZE;
ffffffffc0203470:	9dce                	add	s11,s11,s3
    } while (start != 0 && start < end);
ffffffffc0203472:	fe9de5e3          	bltu	s11,s1,ffffffffc020345c <copy_range+0x62>
    return 0;
ffffffffc0203476:	4501                	li	a0,0
}
ffffffffc0203478:	70e6                	ld	ra,120(sp)
ffffffffc020347a:	7446                	ld	s0,112(sp)
ffffffffc020347c:	74a6                	ld	s1,104(sp)
ffffffffc020347e:	7906                	ld	s2,96(sp)
ffffffffc0203480:	69e6                	ld	s3,88(sp)
ffffffffc0203482:	6a46                	ld	s4,80(sp)
ffffffffc0203484:	6aa6                	ld	s5,72(sp)
ffffffffc0203486:	6b06                	ld	s6,64(sp)
ffffffffc0203488:	7be2                	ld	s7,56(sp)
ffffffffc020348a:	7c42                	ld	s8,48(sp)
ffffffffc020348c:	7ca2                	ld	s9,40(sp)
ffffffffc020348e:	7d02                	ld	s10,32(sp)
ffffffffc0203490:	6de2                	ld	s11,24(sp)
ffffffffc0203492:	6109                	addi	sp,sp,128
ffffffffc0203494:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc0203496:	4605                	li	a2,1
ffffffffc0203498:	85ee                	mv	a1,s11
ffffffffc020349a:	8552                	mv	a0,s4
ffffffffc020349c:	b39fe0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc02034a0:	10050e63          	beqz	a0,ffffffffc02035bc <copy_range+0x1c2>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034a4:	00093703          	ld	a4,0(s2)
    if (!(pte & PTE_V))
ffffffffc02034a8:	00177693          	andi	a3,a4,1
ffffffffc02034ac:	0007091b          	sext.w	s2,a4
ffffffffc02034b0:	18068163          	beqz	a3,ffffffffc0203632 <copy_range+0x238>
    if (PPN(pa) >= npage)
ffffffffc02034b4:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034b8:	070a                	slli	a4,a4,0x2
ffffffffc02034ba:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02034bc:	14d77f63          	bgeu	a4,a3,ffffffffc020361a <copy_range+0x220>
    return &pages[PPN(pa) - nbase];
ffffffffc02034c0:	000ab583          	ld	a1,0(s5)
ffffffffc02034c4:	fff807b7          	lui	a5,0xfff80
ffffffffc02034c8:	973e                	add	a4,a4,a5
ffffffffc02034ca:	071a                	slli	a4,a4,0x6
ffffffffc02034cc:	00e58cb3          	add	s9,a1,a4
            assert(page != NULL);
ffffffffc02034d0:	120c8563          	beqz	s9,ffffffffc02035fa <copy_range+0x200>
            if (share) {
ffffffffc02034d4:	67a2                	ld	a5,8(sp)
ffffffffc02034d6:	c3a1                	beqz	a5,ffffffffc0203516 <copy_range+0x11c>
                if ((ret = page_insert(to, page, start, perm & ~PTE_W)) != 0) {
ffffffffc02034d8:	01b97913          	andi	s2,s2,27
ffffffffc02034dc:	86ca                	mv	a3,s2
ffffffffc02034de:	866e                	mv	a2,s11
ffffffffc02034e0:	85e6                	mv	a1,s9
ffffffffc02034e2:	8552                	mv	a0,s4
ffffffffc02034e4:	9e0ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc02034e8:	f941                	bnez	a0,ffffffffc0203478 <copy_range+0x7e>
                if ((ret = page_insert(from, page, start, perm & ~PTE_W)) != 0) {
ffffffffc02034ea:	86ca                	mv	a3,s2
ffffffffc02034ec:	866e                	mv	a2,s11
ffffffffc02034ee:	85e6                	mv	a1,s9
ffffffffc02034f0:	8522                	mv	a0,s0
ffffffffc02034f2:	9d2ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc02034f6:	f149                	bnez	a0,ffffffffc0203478 <copy_range+0x7e>
        start += PGSIZE;
ffffffffc02034f8:	9dce                	add	s11,s11,s3
    } while (start != 0 && start < end);
ffffffffc02034fa:	bfa5                	j	ffffffffc0203472 <copy_range+0x78>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034fc:	00200637          	lui	a2,0x200
ffffffffc0203500:	00cd87b3          	add	a5,s11,a2
ffffffffc0203504:	ffe00637          	lui	a2,0xffe00
ffffffffc0203508:	00c7fdb3          	and	s11,a5,a2
    } while (start != 0 && start < end);
ffffffffc020350c:	f60d85e3          	beqz	s11,ffffffffc0203476 <copy_range+0x7c>
ffffffffc0203510:	f49de6e3          	bltu	s11,s1,ffffffffc020345c <copy_range+0x62>
ffffffffc0203514:	b78d                	j	ffffffffc0203476 <copy_range+0x7c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203516:	10002773          	csrr	a4,sstatus
ffffffffc020351a:	8b09                	andi	a4,a4,2
ffffffffc020351c:	e749                	bnez	a4,ffffffffc02035a6 <copy_range+0x1ac>
        page = pmm_manager->alloc_pages(n);
ffffffffc020351e:	000d3703          	ld	a4,0(s10)
ffffffffc0203522:	4505                	li	a0,1
ffffffffc0203524:	6f18                	ld	a4,24(a4)
ffffffffc0203526:	9702                	jalr	a4
ffffffffc0203528:	8c2a                	mv	s8,a0
                assert(npage != NULL);
ffffffffc020352a:	0a0c0863          	beqz	s8,ffffffffc02035da <copy_range+0x1e0>
    return page - pages + nbase;
ffffffffc020352e:	000ab703          	ld	a4,0(s5)
ffffffffc0203532:	000808b7          	lui	a7,0x80
    return KADDR(page2pa(page));
ffffffffc0203536:	000b3603          	ld	a2,0(s6)
    return page - pages + nbase;
ffffffffc020353a:	40ec86b3          	sub	a3,s9,a4
ffffffffc020353e:	8699                	srai	a3,a3,0x6
ffffffffc0203540:	96c6                	add	a3,a3,a7
    return KADDR(page2pa(page));
ffffffffc0203542:	0176f5b3          	and	a1,a3,s7
    return page2ppn(page) << PGSHIFT;
ffffffffc0203546:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203548:	06c5fd63          	bgeu	a1,a2,ffffffffc02035c2 <copy_range+0x1c8>
    return page - pages + nbase;
ffffffffc020354c:	40ec0733          	sub	a4,s8,a4
    return KADDR(page2pa(page));
ffffffffc0203550:	000b2797          	auipc	a5,0xb2
ffffffffc0203554:	ae878793          	addi	a5,a5,-1304 # ffffffffc02b5038 <va_pa_offset>
ffffffffc0203558:	6388                	ld	a0,0(a5)
    return page - pages + nbase;
ffffffffc020355a:	8719                	srai	a4,a4,0x6
ffffffffc020355c:	9746                	add	a4,a4,a7
    return KADDR(page2pa(page));
ffffffffc020355e:	017778b3          	and	a7,a4,s7
ffffffffc0203562:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203566:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc0203568:	04c8fc63          	bgeu	a7,a2,ffffffffc02035c0 <copy_range+0x1c6>
                memcpy((void *)dst_kvaddr, (void *)src_kvaddr, PGSIZE);
ffffffffc020356c:	6605                	lui	a2,0x1
ffffffffc020356e:	953a                	add	a0,a0,a4
ffffffffc0203570:	446020ef          	jal	ra,ffffffffc02059b6 <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc0203574:	01f97693          	andi	a3,s2,31
ffffffffc0203578:	866e                	mv	a2,s11
ffffffffc020357a:	85e2                	mv	a1,s8
ffffffffc020357c:	8552                	mv	a0,s4
ffffffffc020357e:	946ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
                assert(ret == 0);
ffffffffc0203582:	ee0507e3          	beqz	a0,ffffffffc0203470 <copy_range+0x76>
ffffffffc0203586:	00004697          	auipc	a3,0x4
ffffffffc020358a:	a0268693          	addi	a3,a3,-1534 # ffffffffc0206f88 <default_pmm_manager+0x760>
ffffffffc020358e:	00003617          	auipc	a2,0x3
ffffffffc0203592:	ca260613          	addi	a2,a2,-862 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203596:	1a300593          	li	a1,419
ffffffffc020359a:	00003517          	auipc	a0,0x3
ffffffffc020359e:	3de50513          	addi	a0,a0,990 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02035a2:	eedfc0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02035a6:	c0efd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035aa:	000d3703          	ld	a4,0(s10)
ffffffffc02035ae:	4505                	li	a0,1
ffffffffc02035b0:	6f18                	ld	a4,24(a4)
ffffffffc02035b2:	9702                	jalr	a4
ffffffffc02035b4:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02035b6:	bf8fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02035ba:	bf85                	j	ffffffffc020352a <copy_range+0x130>
                return -E_NO_MEM;
ffffffffc02035bc:	5571                	li	a0,-4
ffffffffc02035be:	bd6d                	j	ffffffffc0203478 <copy_range+0x7e>
ffffffffc02035c0:	86ba                	mv	a3,a4
ffffffffc02035c2:	00003617          	auipc	a2,0x3
ffffffffc02035c6:	29e60613          	addi	a2,a2,670 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02035ca:	07100593          	li	a1,113
ffffffffc02035ce:	00003517          	auipc	a0,0x3
ffffffffc02035d2:	2ba50513          	addi	a0,a0,698 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc02035d6:	eb9fc0ef          	jal	ra,ffffffffc020048e <__panic>
                assert(npage != NULL);
ffffffffc02035da:	00004697          	auipc	a3,0x4
ffffffffc02035de:	99e68693          	addi	a3,a3,-1634 # ffffffffc0206f78 <default_pmm_manager+0x750>
ffffffffc02035e2:	00003617          	auipc	a2,0x3
ffffffffc02035e6:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02035ea:	19e00593          	li	a1,414
ffffffffc02035ee:	00003517          	auipc	a0,0x3
ffffffffc02035f2:	38a50513          	addi	a0,a0,906 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc02035f6:	e99fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc02035fa:	00004697          	auipc	a3,0x4
ffffffffc02035fe:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206f68 <default_pmm_manager+0x740>
ffffffffc0203602:	00003617          	auipc	a2,0x3
ffffffffc0203606:	c2e60613          	addi	a2,a2,-978 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020360a:	18900593          	li	a1,393
ffffffffc020360e:	00003517          	auipc	a0,0x3
ffffffffc0203612:	36a50513          	addi	a0,a0,874 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203616:	e79fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020361a:	00003617          	auipc	a2,0x3
ffffffffc020361e:	31660613          	addi	a2,a2,790 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc0203622:	06900593          	li	a1,105
ffffffffc0203626:	00003517          	auipc	a0,0x3
ffffffffc020362a:	26250513          	addi	a0,a0,610 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc020362e:	e61fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203632:	00003617          	auipc	a2,0x3
ffffffffc0203636:	31e60613          	addi	a2,a2,798 # ffffffffc0206950 <default_pmm_manager+0x128>
ffffffffc020363a:	07f00593          	li	a1,127
ffffffffc020363e:	00003517          	auipc	a0,0x3
ffffffffc0203642:	24a50513          	addi	a0,a0,586 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0203646:	e49fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020364a:	00003697          	auipc	a3,0x3
ffffffffc020364e:	36e68693          	addi	a3,a3,878 # ffffffffc02069b8 <default_pmm_manager+0x190>
ffffffffc0203652:	00003617          	auipc	a2,0x3
ffffffffc0203656:	bde60613          	addi	a2,a2,-1058 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020365a:	17c00593          	li	a1,380
ffffffffc020365e:	00003517          	auipc	a0,0x3
ffffffffc0203662:	31a50513          	addi	a0,a0,794 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203666:	e29fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020366a:	00003697          	auipc	a3,0x3
ffffffffc020366e:	31e68693          	addi	a3,a3,798 # ffffffffc0206988 <default_pmm_manager+0x160>
ffffffffc0203672:	00003617          	auipc	a2,0x3
ffffffffc0203676:	bbe60613          	addi	a2,a2,-1090 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020367a:	17b00593          	li	a1,379
ffffffffc020367e:	00003517          	auipc	a0,0x3
ffffffffc0203682:	2fa50513          	addi	a0,a0,762 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203686:	e09fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020368a <pgdir_alloc_page>:
{
ffffffffc020368a:	7179                	addi	sp,sp,-48
ffffffffc020368c:	ec26                	sd	s1,24(sp)
ffffffffc020368e:	e84a                	sd	s2,16(sp)
ffffffffc0203690:	e052                	sd	s4,0(sp)
ffffffffc0203692:	f406                	sd	ra,40(sp)
ffffffffc0203694:	f022                	sd	s0,32(sp)
ffffffffc0203696:	e44e                	sd	s3,8(sp)
ffffffffc0203698:	8a2a                	mv	s4,a0
ffffffffc020369a:	84ae                	mv	s1,a1
ffffffffc020369c:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020369e:	100027f3          	csrr	a5,sstatus
ffffffffc02036a2:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02036a4:	000b2997          	auipc	s3,0xb2
ffffffffc02036a8:	98c98993          	addi	s3,s3,-1652 # ffffffffc02b5030 <pmm_manager>
ffffffffc02036ac:	ef8d                	bnez	a5,ffffffffc02036e6 <pgdir_alloc_page+0x5c>
ffffffffc02036ae:	0009b783          	ld	a5,0(s3)
ffffffffc02036b2:	4505                	li	a0,1
ffffffffc02036b4:	6f9c                	ld	a5,24(a5)
ffffffffc02036b6:	9782                	jalr	a5
ffffffffc02036b8:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc02036ba:	cc09                	beqz	s0,ffffffffc02036d4 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036bc:	86ca                	mv	a3,s2
ffffffffc02036be:	8626                	mv	a2,s1
ffffffffc02036c0:	85a2                	mv	a1,s0
ffffffffc02036c2:	8552                	mv	a0,s4
ffffffffc02036c4:	800ff0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc02036c8:	e915                	bnez	a0,ffffffffc02036fc <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc02036ca:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc02036cc:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc02036ce:	4785                	li	a5,1
ffffffffc02036d0:	04f71e63          	bne	a4,a5,ffffffffc020372c <pgdir_alloc_page+0xa2>
}
ffffffffc02036d4:	70a2                	ld	ra,40(sp)
ffffffffc02036d6:	8522                	mv	a0,s0
ffffffffc02036d8:	7402                	ld	s0,32(sp)
ffffffffc02036da:	64e2                	ld	s1,24(sp)
ffffffffc02036dc:	6942                	ld	s2,16(sp)
ffffffffc02036de:	69a2                	ld	s3,8(sp)
ffffffffc02036e0:	6a02                	ld	s4,0(sp)
ffffffffc02036e2:	6145                	addi	sp,sp,48
ffffffffc02036e4:	8082                	ret
        intr_disable();
ffffffffc02036e6:	acefd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036ea:	0009b783          	ld	a5,0(s3)
ffffffffc02036ee:	4505                	li	a0,1
ffffffffc02036f0:	6f9c                	ld	a5,24(a5)
ffffffffc02036f2:	9782                	jalr	a5
ffffffffc02036f4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02036f6:	ab8fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02036fa:	b7c1                	j	ffffffffc02036ba <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02036fc:	100027f3          	csrr	a5,sstatus
ffffffffc0203700:	8b89                	andi	a5,a5,2
ffffffffc0203702:	eb89                	bnez	a5,ffffffffc0203714 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203704:	0009b783          	ld	a5,0(s3)
ffffffffc0203708:	8522                	mv	a0,s0
ffffffffc020370a:	4585                	li	a1,1
ffffffffc020370c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020370e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203710:	9782                	jalr	a5
    if (flag)
ffffffffc0203712:	b7c9                	j	ffffffffc02036d4 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203714:	aa0fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203718:	0009b783          	ld	a5,0(s3)
ffffffffc020371c:	8522                	mv	a0,s0
ffffffffc020371e:	4585                	li	a1,1
ffffffffc0203720:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203722:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203724:	9782                	jalr	a5
        intr_enable();
ffffffffc0203726:	a88fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020372a:	b76d                	j	ffffffffc02036d4 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020372c:	00004697          	auipc	a3,0x4
ffffffffc0203730:	86c68693          	addi	a3,a3,-1940 # ffffffffc0206f98 <default_pmm_manager+0x770>
ffffffffc0203734:	00003617          	auipc	a2,0x3
ffffffffc0203738:	afc60613          	addi	a2,a2,-1284 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020373c:	1ed00593          	li	a1,493
ffffffffc0203740:	00003517          	auipc	a0,0x3
ffffffffc0203744:	23850513          	addi	a0,a0,568 # ffffffffc0206978 <default_pmm_manager+0x150>
ffffffffc0203748:	d47fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020374c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020374c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020374e:	00004697          	auipc	a3,0x4
ffffffffc0203752:	86268693          	addi	a3,a3,-1950 # ffffffffc0206fb0 <default_pmm_manager+0x788>
ffffffffc0203756:	00003617          	auipc	a2,0x3
ffffffffc020375a:	ada60613          	addi	a2,a2,-1318 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020375e:	07500593          	li	a1,117
ffffffffc0203762:	00004517          	auipc	a0,0x4
ffffffffc0203766:	86e50513          	addi	a0,a0,-1938 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020376a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020376c:	d23fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203770 <mm_create>:
{
ffffffffc0203770:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203772:	04000513          	li	a0,64
{
ffffffffc0203776:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203778:	dc6fe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
    if (mm != NULL)
ffffffffc020377c:	cd19                	beqz	a0,ffffffffc020379a <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020377e:	e508                	sd	a0,8(a0)
ffffffffc0203780:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203782:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203786:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020378a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020378e:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203792:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203796:	02053c23          	sd	zero,56(a0)
}
ffffffffc020379a:	60a2                	ld	ra,8(sp)
ffffffffc020379c:	0141                	addi	sp,sp,16
ffffffffc020379e:	8082                	ret

ffffffffc02037a0 <find_vma>:
{
ffffffffc02037a0:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02037a2:	c505                	beqz	a0,ffffffffc02037ca <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02037a4:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037a6:	c501                	beqz	a0,ffffffffc02037ae <find_vma+0xe>
ffffffffc02037a8:	651c                	ld	a5,8(a0)
ffffffffc02037aa:	02f5f263          	bgeu	a1,a5,ffffffffc02037ce <find_vma+0x2e>
    return listelm->next;
ffffffffc02037ae:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02037b0:	00f68d63          	beq	a3,a5,ffffffffc02037ca <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037b4:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037b8:	00e5e663          	bltu	a1,a4,ffffffffc02037c4 <find_vma+0x24>
ffffffffc02037bc:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037c0:	00e5ec63          	bltu	a1,a4,ffffffffc02037d8 <find_vma+0x38>
ffffffffc02037c4:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037c6:	fef697e3          	bne	a3,a5,ffffffffc02037b4 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02037ca:	4501                	li	a0,0
}
ffffffffc02037cc:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037ce:	691c                	ld	a5,16(a0)
ffffffffc02037d0:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02037ae <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02037d4:	ea88                	sd	a0,16(a3)
ffffffffc02037d6:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037d8:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037dc:	ea88                	sd	a0,16(a3)
ffffffffc02037de:	8082                	ret

ffffffffc02037e0 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037e0:	6590                	ld	a2,8(a1)
ffffffffc02037e2:	0105b803          	ld	a6,16(a1)
{
ffffffffc02037e6:	1141                	addi	sp,sp,-16
ffffffffc02037e8:	e406                	sd	ra,8(sp)
ffffffffc02037ea:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037ec:	01066763          	bltu	a2,a6,ffffffffc02037fa <insert_vma_struct+0x1a>
ffffffffc02037f0:	a085                	j	ffffffffc0203850 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02037f2:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037f6:	04e66863          	bltu	a2,a4,ffffffffc0203846 <insert_vma_struct+0x66>
ffffffffc02037fa:	86be                	mv	a3,a5
ffffffffc02037fc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02037fe:	fef51ae3          	bne	a0,a5,ffffffffc02037f2 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203802:	02a68463          	beq	a3,a0,ffffffffc020382a <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203806:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020380a:	fe86b883          	ld	a7,-24(a3)
ffffffffc020380e:	08e8f163          	bgeu	a7,a4,ffffffffc0203890 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203812:	04e66f63          	bltu	a2,a4,ffffffffc0203870 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203816:	00f50a63          	beq	a0,a5,ffffffffc020382a <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020381a:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020381e:	05076963          	bltu	a4,a6,ffffffffc0203870 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203822:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203826:	02c77363          	bgeu	a4,a2,ffffffffc020384c <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020382a:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020382c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020382e:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203832:	e390                	sd	a2,0(a5)
ffffffffc0203834:	e690                	sd	a2,8(a3)
}
ffffffffc0203836:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203838:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020383a:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020383c:	0017079b          	addiw	a5,a4,1
ffffffffc0203840:	d11c                	sw	a5,32(a0)
}
ffffffffc0203842:	0141                	addi	sp,sp,16
ffffffffc0203844:	8082                	ret
    if (le_prev != list)
ffffffffc0203846:	fca690e3          	bne	a3,a0,ffffffffc0203806 <insert_vma_struct+0x26>
ffffffffc020384a:	bfd1                	j	ffffffffc020381e <insert_vma_struct+0x3e>
ffffffffc020384c:	f01ff0ef          	jal	ra,ffffffffc020374c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203850:	00003697          	auipc	a3,0x3
ffffffffc0203854:	79068693          	addi	a3,a3,1936 # ffffffffc0206fe0 <default_pmm_manager+0x7b8>
ffffffffc0203858:	00003617          	auipc	a2,0x3
ffffffffc020385c:	9d860613          	addi	a2,a2,-1576 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203860:	07b00593          	li	a1,123
ffffffffc0203864:	00003517          	auipc	a0,0x3
ffffffffc0203868:	76c50513          	addi	a0,a0,1900 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc020386c:	c23fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203870:	00003697          	auipc	a3,0x3
ffffffffc0203874:	7b068693          	addi	a3,a3,1968 # ffffffffc0207020 <default_pmm_manager+0x7f8>
ffffffffc0203878:	00003617          	auipc	a2,0x3
ffffffffc020387c:	9b860613          	addi	a2,a2,-1608 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203880:	07400593          	li	a1,116
ffffffffc0203884:	00003517          	auipc	a0,0x3
ffffffffc0203888:	74c50513          	addi	a0,a0,1868 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc020388c:	c03fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203890:	00003697          	auipc	a3,0x3
ffffffffc0203894:	77068693          	addi	a3,a3,1904 # ffffffffc0207000 <default_pmm_manager+0x7d8>
ffffffffc0203898:	00003617          	auipc	a2,0x3
ffffffffc020389c:	99860613          	addi	a2,a2,-1640 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02038a0:	07300593          	li	a1,115
ffffffffc02038a4:	00003517          	auipc	a0,0x3
ffffffffc02038a8:	72c50513          	addi	a0,a0,1836 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc02038ac:	be3fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038b0 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02038b0:	591c                	lw	a5,48(a0)
{
ffffffffc02038b2:	1141                	addi	sp,sp,-16
ffffffffc02038b4:	e406                	sd	ra,8(sp)
ffffffffc02038b6:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02038b8:	e78d                	bnez	a5,ffffffffc02038e2 <mm_destroy+0x32>
ffffffffc02038ba:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02038bc:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02038be:	00a40c63          	beq	s0,a0,ffffffffc02038d6 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038c2:	6118                	ld	a4,0(a0)
ffffffffc02038c4:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02038c6:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02038c8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038ca:	e398                	sd	a4,0(a5)
ffffffffc02038cc:	d22fe0ef          	jal	ra,ffffffffc0201dee <kfree>
    return listelm->next;
ffffffffc02038d0:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038d2:	fea418e3          	bne	s0,a0,ffffffffc02038c2 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038d6:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038d8:	6402                	ld	s0,0(sp)
ffffffffc02038da:	60a2                	ld	ra,8(sp)
ffffffffc02038dc:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038de:	d10fe06f          	j	ffffffffc0201dee <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038e2:	00003697          	auipc	a3,0x3
ffffffffc02038e6:	75e68693          	addi	a3,a3,1886 # ffffffffc0207040 <default_pmm_manager+0x818>
ffffffffc02038ea:	00003617          	auipc	a2,0x3
ffffffffc02038ee:	94660613          	addi	a2,a2,-1722 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02038f2:	09f00593          	li	a1,159
ffffffffc02038f6:	00003517          	auipc	a0,0x3
ffffffffc02038fa:	6da50513          	addi	a0,a0,1754 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc02038fe:	b91fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203902 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203902:	7139                	addi	sp,sp,-64
ffffffffc0203904:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203906:	6405                	lui	s0,0x1
ffffffffc0203908:	147d                	addi	s0,s0,-1
ffffffffc020390a:	77fd                	lui	a5,0xfffff
ffffffffc020390c:	9622                	add	a2,a2,s0
ffffffffc020390e:	962e                	add	a2,a2,a1
{
ffffffffc0203910:	f426                	sd	s1,40(sp)
ffffffffc0203912:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203914:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203918:	f04a                	sd	s2,32(sp)
ffffffffc020391a:	ec4e                	sd	s3,24(sp)
ffffffffc020391c:	e852                	sd	s4,16(sp)
ffffffffc020391e:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203920:	002005b7          	lui	a1,0x200
ffffffffc0203924:	00f67433          	and	s0,a2,a5
ffffffffc0203928:	06b4e363          	bltu	s1,a1,ffffffffc020398e <mm_map+0x8c>
ffffffffc020392c:	0684f163          	bgeu	s1,s0,ffffffffc020398e <mm_map+0x8c>
ffffffffc0203930:	4785                	li	a5,1
ffffffffc0203932:	07fe                	slli	a5,a5,0x1f
ffffffffc0203934:	0487ed63          	bltu	a5,s0,ffffffffc020398e <mm_map+0x8c>
ffffffffc0203938:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020393a:	cd21                	beqz	a0,ffffffffc0203992 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020393c:	85a6                	mv	a1,s1
ffffffffc020393e:	8ab6                	mv	s5,a3
ffffffffc0203940:	8a3a                	mv	s4,a4
ffffffffc0203942:	e5fff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
ffffffffc0203946:	c501                	beqz	a0,ffffffffc020394e <mm_map+0x4c>
ffffffffc0203948:	651c                	ld	a5,8(a0)
ffffffffc020394a:	0487e263          	bltu	a5,s0,ffffffffc020398e <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020394e:	03000513          	li	a0,48
ffffffffc0203952:	becfe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
ffffffffc0203956:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203958:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020395a:	02090163          	beqz	s2,ffffffffc020397c <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc020395e:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203960:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203964:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203968:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020396c:	85ca                	mv	a1,s2
ffffffffc020396e:	e73ff0ef          	jal	ra,ffffffffc02037e0 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203972:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203974:	000a0463          	beqz	s4,ffffffffc020397c <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203978:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc020397c:	70e2                	ld	ra,56(sp)
ffffffffc020397e:	7442                	ld	s0,48(sp)
ffffffffc0203980:	74a2                	ld	s1,40(sp)
ffffffffc0203982:	7902                	ld	s2,32(sp)
ffffffffc0203984:	69e2                	ld	s3,24(sp)
ffffffffc0203986:	6a42                	ld	s4,16(sp)
ffffffffc0203988:	6aa2                	ld	s5,8(sp)
ffffffffc020398a:	6121                	addi	sp,sp,64
ffffffffc020398c:	8082                	ret
        return -E_INVAL;
ffffffffc020398e:	5575                	li	a0,-3
ffffffffc0203990:	b7f5                	j	ffffffffc020397c <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203992:	00003697          	auipc	a3,0x3
ffffffffc0203996:	6c668693          	addi	a3,a3,1734 # ffffffffc0207058 <default_pmm_manager+0x830>
ffffffffc020399a:	00003617          	auipc	a2,0x3
ffffffffc020399e:	89660613          	addi	a2,a2,-1898 # ffffffffc0206230 <commands+0x5f8>
ffffffffc02039a2:	0b400593          	li	a1,180
ffffffffc02039a6:	00003517          	auipc	a0,0x3
ffffffffc02039aa:	62a50513          	addi	a0,a0,1578 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc02039ae:	ae1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039b2 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039b2:	7139                	addi	sp,sp,-64
ffffffffc02039b4:	fc06                	sd	ra,56(sp)
ffffffffc02039b6:	f822                	sd	s0,48(sp)
ffffffffc02039b8:	f426                	sd	s1,40(sp)
ffffffffc02039ba:	f04a                	sd	s2,32(sp)
ffffffffc02039bc:	ec4e                	sd	s3,24(sp)
ffffffffc02039be:	e852                	sd	s4,16(sp)
ffffffffc02039c0:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039c2:	c52d                	beqz	a0,ffffffffc0203a2c <dup_mmap+0x7a>
ffffffffc02039c4:	892a                	mv	s2,a0
ffffffffc02039c6:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039c8:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039ca:	e595                	bnez	a1,ffffffffc02039f6 <dup_mmap+0x44>
ffffffffc02039cc:	a085                	j	ffffffffc0203a2c <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039ce:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02039d0:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee0>
        vma->vm_end = vm_end;
ffffffffc02039d4:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02039d8:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02039dc:	e05ff0ef          	jal	ra,ffffffffc02037e0 <insert_vma_struct>

        bool share = 1;//需要进行共享
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039e0:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc0>
ffffffffc02039e4:	fe843603          	ld	a2,-24(s0)
ffffffffc02039e8:	6c8c                	ld	a1,24(s1)
ffffffffc02039ea:	01893503          	ld	a0,24(s2)
ffffffffc02039ee:	4705                	li	a4,1
ffffffffc02039f0:	a0bff0ef          	jal	ra,ffffffffc02033fa <copy_range>
ffffffffc02039f4:	e105                	bnez	a0,ffffffffc0203a14 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc02039f6:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02039f8:	02848863          	beq	s1,s0,ffffffffc0203a28 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039fc:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203a00:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203a04:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203a08:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a0c:	b32fe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
ffffffffc0203a10:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203a12:	fd55                	bnez	a0,ffffffffc02039ce <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203a14:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a16:	70e2                	ld	ra,56(sp)
ffffffffc0203a18:	7442                	ld	s0,48(sp)
ffffffffc0203a1a:	74a2                	ld	s1,40(sp)
ffffffffc0203a1c:	7902                	ld	s2,32(sp)
ffffffffc0203a1e:	69e2                	ld	s3,24(sp)
ffffffffc0203a20:	6a42                	ld	s4,16(sp)
ffffffffc0203a22:	6aa2                	ld	s5,8(sp)
ffffffffc0203a24:	6121                	addi	sp,sp,64
ffffffffc0203a26:	8082                	ret
    return 0;
ffffffffc0203a28:	4501                	li	a0,0
ffffffffc0203a2a:	b7f5                	j	ffffffffc0203a16 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203a2c:	00003697          	auipc	a3,0x3
ffffffffc0203a30:	63c68693          	addi	a3,a3,1596 # ffffffffc0207068 <default_pmm_manager+0x840>
ffffffffc0203a34:	00002617          	auipc	a2,0x2
ffffffffc0203a38:	7fc60613          	addi	a2,a2,2044 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203a3c:	0d000593          	li	a1,208
ffffffffc0203a40:	00003517          	auipc	a0,0x3
ffffffffc0203a44:	59050513          	addi	a0,a0,1424 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203a48:	a47fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a4c <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a4c:	1101                	addi	sp,sp,-32
ffffffffc0203a4e:	ec06                	sd	ra,24(sp)
ffffffffc0203a50:	e822                	sd	s0,16(sp)
ffffffffc0203a52:	e426                	sd	s1,8(sp)
ffffffffc0203a54:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a56:	c531                	beqz	a0,ffffffffc0203aa2 <exit_mmap+0x56>
ffffffffc0203a58:	591c                	lw	a5,48(a0)
ffffffffc0203a5a:	84aa                	mv	s1,a0
ffffffffc0203a5c:	e3b9                	bnez	a5,ffffffffc0203aa2 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a5e:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a60:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a64:	02850663          	beq	a0,s0,ffffffffc0203a90 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a68:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a6c:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a70:	854a                	mv	a0,s2
ffffffffc0203a72:	fdefe0ef          	jal	ra,ffffffffc0202250 <unmap_range>
ffffffffc0203a76:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a78:	fe8498e3          	bne	s1,s0,ffffffffc0203a68 <exit_mmap+0x1c>
ffffffffc0203a7c:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a7e:	00848c63          	beq	s1,s0,ffffffffc0203a96 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a82:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a86:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a8a:	854a                	mv	a0,s2
ffffffffc0203a8c:	90bfe0ef          	jal	ra,ffffffffc0202396 <exit_range>
ffffffffc0203a90:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a92:	fe8498e3          	bne	s1,s0,ffffffffc0203a82 <exit_mmap+0x36>
    }
}
ffffffffc0203a96:	60e2                	ld	ra,24(sp)
ffffffffc0203a98:	6442                	ld	s0,16(sp)
ffffffffc0203a9a:	64a2                	ld	s1,8(sp)
ffffffffc0203a9c:	6902                	ld	s2,0(sp)
ffffffffc0203a9e:	6105                	addi	sp,sp,32
ffffffffc0203aa0:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203aa2:	00003697          	auipc	a3,0x3
ffffffffc0203aa6:	5e668693          	addi	a3,a3,1510 # ffffffffc0207088 <default_pmm_manager+0x860>
ffffffffc0203aaa:	00002617          	auipc	a2,0x2
ffffffffc0203aae:	78660613          	addi	a2,a2,1926 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203ab2:	0e900593          	li	a1,233
ffffffffc0203ab6:	00003517          	auipc	a0,0x3
ffffffffc0203aba:	51a50513          	addi	a0,a0,1306 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203abe:	9d1fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ac2 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ac2:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ac4:	04000513          	li	a0,64
{
ffffffffc0203ac8:	fc06                	sd	ra,56(sp)
ffffffffc0203aca:	f822                	sd	s0,48(sp)
ffffffffc0203acc:	f426                	sd	s1,40(sp)
ffffffffc0203ace:	f04a                	sd	s2,32(sp)
ffffffffc0203ad0:	ec4e                	sd	s3,24(sp)
ffffffffc0203ad2:	e852                	sd	s4,16(sp)
ffffffffc0203ad4:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ad6:	a68fe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
    if (mm != NULL)
ffffffffc0203ada:	2e050663          	beqz	a0,ffffffffc0203dc6 <vmm_init+0x304>
ffffffffc0203ade:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203ae0:	e508                	sd	a0,8(a0)
ffffffffc0203ae2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203ae4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203ae8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203aec:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203af0:	02053423          	sd	zero,40(a0)
ffffffffc0203af4:	02052823          	sw	zero,48(a0)
ffffffffc0203af8:	02053c23          	sd	zero,56(a0)
ffffffffc0203afc:	03200413          	li	s0,50
ffffffffc0203b00:	a811                	j	ffffffffc0203b14 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203b02:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b04:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b06:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203b0a:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b0c:	8526                	mv	a0,s1
ffffffffc0203b0e:	cd3ff0ef          	jal	ra,ffffffffc02037e0 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b12:	c80d                	beqz	s0,ffffffffc0203b44 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b14:	03000513          	li	a0,48
ffffffffc0203b18:	a26fe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
ffffffffc0203b1c:	85aa                	mv	a1,a0
ffffffffc0203b1e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b22:	f165                	bnez	a0,ffffffffc0203b02 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203b24:	00003697          	auipc	a3,0x3
ffffffffc0203b28:	6fc68693          	addi	a3,a3,1788 # ffffffffc0207220 <default_pmm_manager+0x9f8>
ffffffffc0203b2c:	00002617          	auipc	a2,0x2
ffffffffc0203b30:	70460613          	addi	a2,a2,1796 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203b34:	12d00593          	li	a1,301
ffffffffc0203b38:	00003517          	auipc	a0,0x3
ffffffffc0203b3c:	49850513          	addi	a0,a0,1176 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203b40:	94ffc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203b44:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b48:	1f900913          	li	s2,505
ffffffffc0203b4c:	a819                	j	ffffffffc0203b62 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203b4e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203b50:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b52:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b56:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b58:	8526                	mv	a0,s1
ffffffffc0203b5a:	c87ff0ef          	jal	ra,ffffffffc02037e0 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b5e:	03240a63          	beq	s0,s2,ffffffffc0203b92 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b62:	03000513          	li	a0,48
ffffffffc0203b66:	9d8fe0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
ffffffffc0203b6a:	85aa                	mv	a1,a0
ffffffffc0203b6c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203b70:	fd79                	bnez	a0,ffffffffc0203b4e <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203b72:	00003697          	auipc	a3,0x3
ffffffffc0203b76:	6ae68693          	addi	a3,a3,1710 # ffffffffc0207220 <default_pmm_manager+0x9f8>
ffffffffc0203b7a:	00002617          	auipc	a2,0x2
ffffffffc0203b7e:	6b660613          	addi	a2,a2,1718 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203b82:	13400593          	li	a1,308
ffffffffc0203b86:	00003517          	auipc	a0,0x3
ffffffffc0203b8a:	44a50513          	addi	a0,a0,1098 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203b8e:	901fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203b92:	649c                	ld	a5,8(s1)
ffffffffc0203b94:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203b96:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203b9a:	16f48663          	beq	s1,a5,ffffffffc0203d06 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b9e:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd49f7c>
ffffffffc0203ba2:	ffe70693          	addi	a3,a4,-2 # 1ffffe <_binary_obj___user_exit_out_size+0x1f4ed6>
ffffffffc0203ba6:	10d61063          	bne	a2,a3,ffffffffc0203ca6 <vmm_init+0x1e4>
ffffffffc0203baa:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203bae:	0ed71c63          	bne	a4,a3,ffffffffc0203ca6 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203bb2:	0715                	addi	a4,a4,5
ffffffffc0203bb4:	679c                	ld	a5,8(a5)
ffffffffc0203bb6:	feb712e3          	bne	a4,a1,ffffffffc0203b9a <vmm_init+0xd8>
ffffffffc0203bba:	4a1d                	li	s4,7
ffffffffc0203bbc:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bbe:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203bc2:	85a2                	mv	a1,s0
ffffffffc0203bc4:	8526                	mv	a0,s1
ffffffffc0203bc6:	bdbff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
ffffffffc0203bca:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203bcc:	16050d63          	beqz	a0,ffffffffc0203d46 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203bd0:	00140593          	addi	a1,s0,1
ffffffffc0203bd4:	8526                	mv	a0,s1
ffffffffc0203bd6:	bcbff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
ffffffffc0203bda:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203bdc:	14050563          	beqz	a0,ffffffffc0203d26 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203be0:	85d2                	mv	a1,s4
ffffffffc0203be2:	8526                	mv	a0,s1
ffffffffc0203be4:	bbdff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203be8:	16051f63          	bnez	a0,ffffffffc0203d66 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203bec:	00340593          	addi	a1,s0,3
ffffffffc0203bf0:	8526                	mv	a0,s1
ffffffffc0203bf2:	bafff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203bf6:	1a051863          	bnez	a0,ffffffffc0203da6 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203bfa:	00440593          	addi	a1,s0,4
ffffffffc0203bfe:	8526                	mv	a0,s1
ffffffffc0203c00:	ba1ff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203c04:	18051163          	bnez	a0,ffffffffc0203d86 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c08:	00893783          	ld	a5,8(s2)
ffffffffc0203c0c:	0a879d63          	bne	a5,s0,ffffffffc0203cc6 <vmm_init+0x204>
ffffffffc0203c10:	01093783          	ld	a5,16(s2)
ffffffffc0203c14:	0b479963          	bne	a5,s4,ffffffffc0203cc6 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c18:	0089b783          	ld	a5,8(s3)
ffffffffc0203c1c:	0c879563          	bne	a5,s0,ffffffffc0203ce6 <vmm_init+0x224>
ffffffffc0203c20:	0109b783          	ld	a5,16(s3)
ffffffffc0203c24:	0d479163          	bne	a5,s4,ffffffffc0203ce6 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203c28:	0415                	addi	s0,s0,5
ffffffffc0203c2a:	0a15                	addi	s4,s4,5
ffffffffc0203c2c:	f9541be3          	bne	s0,s5,ffffffffc0203bc2 <vmm_init+0x100>
ffffffffc0203c30:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203c32:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203c34:	85a2                	mv	a1,s0
ffffffffc0203c36:	8526                	mv	a0,s1
ffffffffc0203c38:	b69ff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
ffffffffc0203c3c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203c40:	c90d                	beqz	a0,ffffffffc0203c72 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203c42:	6914                	ld	a3,16(a0)
ffffffffc0203c44:	6510                	ld	a2,8(a0)
ffffffffc0203c46:	00003517          	auipc	a0,0x3
ffffffffc0203c4a:	56250513          	addi	a0,a0,1378 # ffffffffc02071a8 <default_pmm_manager+0x980>
ffffffffc0203c4e:	d46fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203c52:	00003697          	auipc	a3,0x3
ffffffffc0203c56:	57e68693          	addi	a3,a3,1406 # ffffffffc02071d0 <default_pmm_manager+0x9a8>
ffffffffc0203c5a:	00002617          	auipc	a2,0x2
ffffffffc0203c5e:	5d660613          	addi	a2,a2,1494 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203c62:	15a00593          	li	a1,346
ffffffffc0203c66:	00003517          	auipc	a0,0x3
ffffffffc0203c6a:	36a50513          	addi	a0,a0,874 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203c6e:	821fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203c72:	147d                	addi	s0,s0,-1
ffffffffc0203c74:	fd2410e3          	bne	s0,s2,ffffffffc0203c34 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203c78:	8526                	mv	a0,s1
ffffffffc0203c7a:	c37ff0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c7e:	00003517          	auipc	a0,0x3
ffffffffc0203c82:	56a50513          	addi	a0,a0,1386 # ffffffffc02071e8 <default_pmm_manager+0x9c0>
ffffffffc0203c86:	d0efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203c8a:	7442                	ld	s0,48(sp)
ffffffffc0203c8c:	70e2                	ld	ra,56(sp)
ffffffffc0203c8e:	74a2                	ld	s1,40(sp)
ffffffffc0203c90:	7902                	ld	s2,32(sp)
ffffffffc0203c92:	69e2                	ld	s3,24(sp)
ffffffffc0203c94:	6a42                	ld	s4,16(sp)
ffffffffc0203c96:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c98:	00003517          	auipc	a0,0x3
ffffffffc0203c9c:	57050513          	addi	a0,a0,1392 # ffffffffc0207208 <default_pmm_manager+0x9e0>
}
ffffffffc0203ca0:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ca2:	cf2fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ca6:	00003697          	auipc	a3,0x3
ffffffffc0203caa:	41a68693          	addi	a3,a3,1050 # ffffffffc02070c0 <default_pmm_manager+0x898>
ffffffffc0203cae:	00002617          	auipc	a2,0x2
ffffffffc0203cb2:	58260613          	addi	a2,a2,1410 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203cb6:	13e00593          	li	a1,318
ffffffffc0203cba:	00003517          	auipc	a0,0x3
ffffffffc0203cbe:	31650513          	addi	a0,a0,790 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203cc2:	fccfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cc6:	00003697          	auipc	a3,0x3
ffffffffc0203cca:	48268693          	addi	a3,a3,1154 # ffffffffc0207148 <default_pmm_manager+0x920>
ffffffffc0203cce:	00002617          	auipc	a2,0x2
ffffffffc0203cd2:	56260613          	addi	a2,a2,1378 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203cd6:	14f00593          	li	a1,335
ffffffffc0203cda:	00003517          	auipc	a0,0x3
ffffffffc0203cde:	2f650513          	addi	a0,a0,758 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203ce2:	facfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ce6:	00003697          	auipc	a3,0x3
ffffffffc0203cea:	49268693          	addi	a3,a3,1170 # ffffffffc0207178 <default_pmm_manager+0x950>
ffffffffc0203cee:	00002617          	auipc	a2,0x2
ffffffffc0203cf2:	54260613          	addi	a2,a2,1346 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203cf6:	15000593          	li	a1,336
ffffffffc0203cfa:	00003517          	auipc	a0,0x3
ffffffffc0203cfe:	2d650513          	addi	a0,a0,726 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203d02:	f8cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d06:	00003697          	auipc	a3,0x3
ffffffffc0203d0a:	3a268693          	addi	a3,a3,930 # ffffffffc02070a8 <default_pmm_manager+0x880>
ffffffffc0203d0e:	00002617          	auipc	a2,0x2
ffffffffc0203d12:	52260613          	addi	a2,a2,1314 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203d16:	13c00593          	li	a1,316
ffffffffc0203d1a:	00003517          	auipc	a0,0x3
ffffffffc0203d1e:	2b650513          	addi	a0,a0,694 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203d22:	f6cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203d26:	00003697          	auipc	a3,0x3
ffffffffc0203d2a:	3e268693          	addi	a3,a3,994 # ffffffffc0207108 <default_pmm_manager+0x8e0>
ffffffffc0203d2e:	00002617          	auipc	a2,0x2
ffffffffc0203d32:	50260613          	addi	a2,a2,1282 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203d36:	14700593          	li	a1,327
ffffffffc0203d3a:	00003517          	auipc	a0,0x3
ffffffffc0203d3e:	29650513          	addi	a0,a0,662 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203d42:	f4cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203d46:	00003697          	auipc	a3,0x3
ffffffffc0203d4a:	3b268693          	addi	a3,a3,946 # ffffffffc02070f8 <default_pmm_manager+0x8d0>
ffffffffc0203d4e:	00002617          	auipc	a2,0x2
ffffffffc0203d52:	4e260613          	addi	a2,a2,1250 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203d56:	14500593          	li	a1,325
ffffffffc0203d5a:	00003517          	auipc	a0,0x3
ffffffffc0203d5e:	27650513          	addi	a0,a0,630 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203d62:	f2cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203d66:	00003697          	auipc	a3,0x3
ffffffffc0203d6a:	3b268693          	addi	a3,a3,946 # ffffffffc0207118 <default_pmm_manager+0x8f0>
ffffffffc0203d6e:	00002617          	auipc	a2,0x2
ffffffffc0203d72:	4c260613          	addi	a2,a2,1218 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203d76:	14900593          	li	a1,329
ffffffffc0203d7a:	00003517          	auipc	a0,0x3
ffffffffc0203d7e:	25650513          	addi	a0,a0,598 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203d82:	f0cfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203d86:	00003697          	auipc	a3,0x3
ffffffffc0203d8a:	3b268693          	addi	a3,a3,946 # ffffffffc0207138 <default_pmm_manager+0x910>
ffffffffc0203d8e:	00002617          	auipc	a2,0x2
ffffffffc0203d92:	4a260613          	addi	a2,a2,1186 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203d96:	14d00593          	li	a1,333
ffffffffc0203d9a:	00003517          	auipc	a0,0x3
ffffffffc0203d9e:	23650513          	addi	a0,a0,566 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203da2:	eecfc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203da6:	00003697          	auipc	a3,0x3
ffffffffc0203daa:	38268693          	addi	a3,a3,898 # ffffffffc0207128 <default_pmm_manager+0x900>
ffffffffc0203dae:	00002617          	auipc	a2,0x2
ffffffffc0203db2:	48260613          	addi	a2,a2,1154 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203db6:	14b00593          	li	a1,331
ffffffffc0203dba:	00003517          	auipc	a0,0x3
ffffffffc0203dbe:	21650513          	addi	a0,a0,534 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203dc2:	eccfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203dc6:	00003697          	auipc	a3,0x3
ffffffffc0203dca:	29268693          	addi	a3,a3,658 # ffffffffc0207058 <default_pmm_manager+0x830>
ffffffffc0203dce:	00002617          	auipc	a2,0x2
ffffffffc0203dd2:	46260613          	addi	a2,a2,1122 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0203dd6:	12500593          	li	a1,293
ffffffffc0203dda:	00003517          	auipc	a0,0x3
ffffffffc0203dde:	1f650513          	addi	a0,a0,502 # ffffffffc0206fd0 <default_pmm_manager+0x7a8>
ffffffffc0203de2:	eacfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203de6 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203de6:	7179                	addi	sp,sp,-48
ffffffffc0203de8:	f022                	sd	s0,32(sp)
ffffffffc0203dea:	f406                	sd	ra,40(sp)
ffffffffc0203dec:	ec26                	sd	s1,24(sp)
ffffffffc0203dee:	e84a                	sd	s2,16(sp)
ffffffffc0203df0:	e44e                	sd	s3,8(sp)
ffffffffc0203df2:	e052                	sd	s4,0(sp)
ffffffffc0203df4:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203df6:	c135                	beqz	a0,ffffffffc0203e5a <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203df8:	002007b7          	lui	a5,0x200
ffffffffc0203dfc:	04f5e663          	bltu	a1,a5,ffffffffc0203e48 <user_mem_check+0x62>
ffffffffc0203e00:	00c584b3          	add	s1,a1,a2
ffffffffc0203e04:	0495f263          	bgeu	a1,s1,ffffffffc0203e48 <user_mem_check+0x62>
ffffffffc0203e08:	4785                	li	a5,1
ffffffffc0203e0a:	07fe                	slli	a5,a5,0x1f
ffffffffc0203e0c:	0297ee63          	bltu	a5,s1,ffffffffc0203e48 <user_mem_check+0x62>
ffffffffc0203e10:	892a                	mv	s2,a0
ffffffffc0203e12:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e14:	6a05                	lui	s4,0x1
ffffffffc0203e16:	a821                	j	ffffffffc0203e2e <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e18:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e1c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e1e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e20:	c685                	beqz	a3,ffffffffc0203e48 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e22:	c399                	beqz	a5,ffffffffc0203e28 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e24:	02e46263          	bltu	s0,a4,ffffffffc0203e48 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e28:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e2a:	04947663          	bgeu	s0,s1,ffffffffc0203e76 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e2e:	85a2                	mv	a1,s0
ffffffffc0203e30:	854a                	mv	a0,s2
ffffffffc0203e32:	96fff0ef          	jal	ra,ffffffffc02037a0 <find_vma>
ffffffffc0203e36:	c909                	beqz	a0,ffffffffc0203e48 <user_mem_check+0x62>
ffffffffc0203e38:	6518                	ld	a4,8(a0)
ffffffffc0203e3a:	00e46763          	bltu	s0,a4,ffffffffc0203e48 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e3e:	4d1c                	lw	a5,24(a0)
ffffffffc0203e40:	fc099ce3          	bnez	s3,ffffffffc0203e18 <user_mem_check+0x32>
ffffffffc0203e44:	8b85                	andi	a5,a5,1
ffffffffc0203e46:	f3ed                	bnez	a5,ffffffffc0203e28 <user_mem_check+0x42>
            return 0;
ffffffffc0203e48:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203e4a:	70a2                	ld	ra,40(sp)
ffffffffc0203e4c:	7402                	ld	s0,32(sp)
ffffffffc0203e4e:	64e2                	ld	s1,24(sp)
ffffffffc0203e50:	6942                	ld	s2,16(sp)
ffffffffc0203e52:	69a2                	ld	s3,8(sp)
ffffffffc0203e54:	6a02                	ld	s4,0(sp)
ffffffffc0203e56:	6145                	addi	sp,sp,48
ffffffffc0203e58:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e5a:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e5e:	4501                	li	a0,0
ffffffffc0203e60:	fef5e5e3          	bltu	a1,a5,ffffffffc0203e4a <user_mem_check+0x64>
ffffffffc0203e64:	962e                	add	a2,a2,a1
ffffffffc0203e66:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203e4a <user_mem_check+0x64>
ffffffffc0203e6a:	c8000537          	lui	a0,0xc8000
ffffffffc0203e6e:	0505                	addi	a0,a0,1
ffffffffc0203e70:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e74:	bfd9                	j	ffffffffc0203e4a <user_mem_check+0x64>
        return 1;
ffffffffc0203e76:	4505                	li	a0,1
ffffffffc0203e78:	bfc9                	j	ffffffffc0203e4a <user_mem_check+0x64>

ffffffffc0203e7a <do_pgfault>:

// kern/mm/vmm.c

int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203e7a:	715d                	addi	sp,sp,-80
ffffffffc0203e7c:	fc26                	sd	s1,56(sp)
ffffffffc0203e7e:	84ae                	mv	s1,a1
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203e80:	85b2                	mv	a1,a2
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203e82:	e0a2                	sd	s0,64(sp)
ffffffffc0203e84:	f84a                	sd	s2,48(sp)
ffffffffc0203e86:	e486                	sd	ra,72(sp)
ffffffffc0203e88:	f44e                	sd	s3,40(sp)
ffffffffc0203e8a:	f052                	sd	s4,32(sp)
ffffffffc0203e8c:	ec56                	sd	s5,24(sp)
ffffffffc0203e8e:	e85a                	sd	s6,16(sp)
ffffffffc0203e90:	e45e                	sd	s7,8(sp)
ffffffffc0203e92:	8432                	mv	s0,a2
ffffffffc0203e94:	892a                	mv	s2,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203e96:	90bff0ef          	jal	ra,ffffffffc02037a0 <find_vma>

    pgfault_num++;
ffffffffc0203e9a:	000b1797          	auipc	a5,0xb1
ffffffffc0203e9e:	1ae7a783          	lw	a5,430(a5) # ffffffffc02b5048 <pgfault_num>
ffffffffc0203ea2:	2785                	addiw	a5,a5,1
ffffffffc0203ea4:	000b1717          	auipc	a4,0xb1
ffffffffc0203ea8:	1af72223          	sw	a5,420(a4) # ffffffffc02b5048 <pgfault_num>

    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203eac:	18050a63          	beqz	a0,ffffffffc0204040 <do_pgfault+0x1c6>
ffffffffc0203eb0:	651c                	ld	a5,8(a0)
ffffffffc0203eb2:	18f46763          	bltu	s0,a5,ffffffffc0204040 <do_pgfault+0x1c6>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    // 1. 权限检查
    switch (error_code & 3) {
ffffffffc0203eb6:	0034f793          	andi	a5,s1,3
ffffffffc0203eba:	c7d1                	beqz	a5,ffffffffc0203f46 <do_pgfault+0xcc>
ffffffffc0203ebc:	4705                	li	a4,1
ffffffffc0203ebe:	04e78663          	beq	a5,a4,ffffffffc0203f0a <do_pgfault+0x90>
    default:
    case 2: /* write, not present */
        if (!(vma->vm_flags & VM_WRITE)) {
ffffffffc0203ec2:	4d1c                	lw	a5,24(a0)
ffffffffc0203ec4:	0027f713          	andi	a4,a5,2
ffffffffc0203ec8:	18070e63          	beqz	a4,ffffffffc0204064 <do_pgfault+0x1ea>
            goto failed;
        }
    }

    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_READ) {
ffffffffc0203ecc:	8b85                	andi	a5,a5,1
ffffffffc0203ece:	49d9                	li	s3,22
ffffffffc0203ed0:	cbd1                	beqz	a5,ffffffffc0203f64 <do_pgfault+0xea>
        perm |= PTE_R;
    }
    if (vma->vm_flags & VM_WRITE) {
        perm |= PTE_W;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203ed2:	767d                	lui	a2,0xfffff
    ret = -E_NO_MEM;

    pte_t *ptep = NULL;
    
    // 获取页表项
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0203ed4:	01893503          	ld	a0,24(s2)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203ed8:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0203eda:	85a2                	mv	a1,s0
ffffffffc0203edc:	4605                	li	a2,1
ffffffffc0203ede:	8f6fe0ef          	jal	ra,ffffffffc0201fd4 <get_pte>
ffffffffc0203ee2:	18050a63          	beqz	a0,ffffffffc0204076 <do_pgfault+0x1fc>
    // cprintf("DEBUG: addr=%x, err=%x, *ptep=%x, PTE_W=%d\n", addr, error_code, *ptep, (*ptep & PTE_W) != 0);
    // ==========================================

    // Challenge 1: Copy-on-Write 核心处理逻辑
    // 判断条件：PTE存在(V) 且 是写操作(err&2) 且 当前不可写(!W)
    if ((*ptep & PTE_V) && (error_code & 2) && !(*ptep & PTE_W)) {
ffffffffc0203ee6:	6110                	ld	a2,0(a0)
ffffffffc0203ee8:	00167793          	andi	a5,a2,1
ffffffffc0203eec:	c3b1                	beqz	a5,ffffffffc0203f30 <do_pgfault+0xb6>
ffffffffc0203eee:	8889                	andi	s1,s1,2
ffffffffc0203ef0:	c481                	beqz	s1,ffffffffc0203ef8 <do_pgfault+0x7e>
ffffffffc0203ef2:	00467793          	andi	a5,a2,4
ffffffffc0203ef6:	cbbd                	beqz	a5,ffffffffc0203f6c <do_pgfault+0xf2>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        // 如果不是 COW，且 PTE 又有值，说明状态异常（Lab5没有Swap）
        cprintf("do_pgfault error: PTE exists but not COW. addr=%x, *ptep=%x\n", addr, *ptep);
ffffffffc0203ef8:	85a2                	mv	a1,s0
ffffffffc0203efa:	00003517          	auipc	a0,0x3
ffffffffc0203efe:	49650513          	addi	a0,a0,1174 # ffffffffc0207390 <default_pmm_manager+0xb68>
ffffffffc0203f02:	a92fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203f06:	5571                	li	a0,-4
        goto failed;
ffffffffc0203f08:	a809                	j	ffffffffc0203f1a <do_pgfault+0xa0>
        cprintf("do_pgfault failed: read present error, addr=%x\n", addr);
ffffffffc0203f0a:	85a2                	mv	a1,s0
ffffffffc0203f0c:	00003517          	auipc	a0,0x3
ffffffffc0203f10:	38450513          	addi	a0,a0,900 # ffffffffc0207290 <default_pmm_manager+0xa68>
ffffffffc0203f14:	a80fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc0203f18:	5575                	li	a0,-3
    }
    
    ret = 0;
failed:
    return ret;
}
ffffffffc0203f1a:	60a6                	ld	ra,72(sp)
ffffffffc0203f1c:	6406                	ld	s0,64(sp)
ffffffffc0203f1e:	74e2                	ld	s1,56(sp)
ffffffffc0203f20:	7942                	ld	s2,48(sp)
ffffffffc0203f22:	79a2                	ld	s3,40(sp)
ffffffffc0203f24:	7a02                	ld	s4,32(sp)
ffffffffc0203f26:	6ae2                	ld	s5,24(sp)
ffffffffc0203f28:	6b42                	ld	s6,16(sp)
ffffffffc0203f2a:	6ba2                	ld	s7,8(sp)
ffffffffc0203f2c:	6161                	addi	sp,sp,80
ffffffffc0203f2e:	8082                	ret
    if (*ptep == 0) {
ffffffffc0203f30:	f661                	bnez	a2,ffffffffc0203ef8 <do_pgfault+0x7e>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203f32:	01893503          	ld	a0,24(s2)
ffffffffc0203f36:	864e                	mv	a2,s3
ffffffffc0203f38:	85a2                	mv	a1,s0
ffffffffc0203f3a:	f50ff0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0203f3e:	0e050963          	beqz	a0,ffffffffc0204030 <do_pgfault+0x1b6>
        return 0; // 成功修复
ffffffffc0203f42:	4501                	li	a0,0
ffffffffc0203f44:	bfd9                	j	ffffffffc0203f1a <do_pgfault+0xa0>
        if (!(vma->vm_flags & (VM_READ | VM_EXEC))) {
ffffffffc0203f46:	4d1c                	lw	a5,24(a0)
ffffffffc0203f48:	0057f713          	andi	a4,a5,5
ffffffffc0203f4c:	10070363          	beqz	a4,ffffffffc0204052 <do_pgfault+0x1d8>
    if (vma->vm_flags & VM_READ) {
ffffffffc0203f50:	0017f713          	andi	a4,a5,1
    uint32_t perm = PTE_U;
ffffffffc0203f54:	49c1                	li	s3,16
        if (!(vma->vm_flags & VM_WRITE)) {
ffffffffc0203f56:	8b89                	andi	a5,a5,2
    if (vma->vm_flags & VM_READ) {
ffffffffc0203f58:	c311                	beqz	a4,ffffffffc0203f5c <do_pgfault+0xe2>
        perm |= PTE_R;
ffffffffc0203f5a:	49c9                	li	s3,18
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203f5c:	dbbd                	beqz	a5,ffffffffc0203ed2 <do_pgfault+0x58>
        perm |= PTE_W;
ffffffffc0203f5e:	0049e993          	ori	s3,s3,4
ffffffffc0203f62:	bf85                	j	ffffffffc0203ed2 <do_pgfault+0x58>
    uint32_t perm = PTE_U;
ffffffffc0203f64:	49c1                	li	s3,16
        perm |= PTE_W;
ffffffffc0203f66:	0049e993          	ori	s3,s3,4
ffffffffc0203f6a:	b7a5                	j	ffffffffc0203ed2 <do_pgfault+0x58>
    if (PPN(pa) >= npage)
ffffffffc0203f6c:	000b1b17          	auipc	s6,0xb1
ffffffffc0203f70:	0b4b0b13          	addi	s6,s6,180 # ffffffffc02b5020 <npage>
ffffffffc0203f74:	000b3783          	ld	a5,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203f78:	060a                	slli	a2,a2,0x2
ffffffffc0203f7a:	8231                	srli	a2,a2,0xc
    if (PPN(pa) >= npage)
ffffffffc0203f7c:	12f67a63          	bgeu	a2,a5,ffffffffc02040b0 <do_pgfault+0x236>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f80:	000b1b97          	auipc	s7,0xb1
ffffffffc0203f84:	0a8b8b93          	addi	s7,s7,168 # ffffffffc02b5028 <pages>
ffffffffc0203f88:	000bb483          	ld	s1,0(s7)
ffffffffc0203f8c:	00004a97          	auipc	s5,0x4
ffffffffc0203f90:	d44aba83          	ld	s5,-700(s5) # ffffffffc0207cd0 <nbase>
ffffffffc0203f94:	41560633          	sub	a2,a2,s5
ffffffffc0203f98:	061a                	slli	a2,a2,0x6
ffffffffc0203f9a:	94b2                	add	s1,s1,a2
        if (page_ref(page) == 1) {
ffffffffc0203f9c:	4098                	lw	a4,0(s1)
ffffffffc0203f9e:	4785                	li	a5,1
ffffffffc0203fa0:	06f70e63          	beq	a4,a5,ffffffffc020401c <do_pgfault+0x1a2>
        struct Page *npage = alloc_page();
ffffffffc0203fa4:	4505                	li	a0,1
ffffffffc0203fa6:	f77fd0ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0203faa:	8a2a                	mv	s4,a0
        if (npage == NULL) {
ffffffffc0203fac:	0c050d63          	beqz	a0,ffffffffc0204086 <do_pgfault+0x20c>
    return page - pages + nbase;
ffffffffc0203fb0:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc0203fb4:	567d                	li	a2,-1
ffffffffc0203fb6:	000b3803          	ld	a6,0(s6)
    return page - pages + nbase;
ffffffffc0203fba:	40e486b3          	sub	a3,s1,a4
ffffffffc0203fbe:	8699                	srai	a3,a3,0x6
ffffffffc0203fc0:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc0203fc2:	8231                	srli	a2,a2,0xc
ffffffffc0203fc4:	00c6f7b3          	and	a5,a3,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fc8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203fca:	0d07f763          	bgeu	a5,a6,ffffffffc0204098 <do_pgfault+0x21e>
    return page - pages + nbase;
ffffffffc0203fce:	40e507b3          	sub	a5,a0,a4
ffffffffc0203fd2:	8799                	srai	a5,a5,0x6
ffffffffc0203fd4:	97d6                	add	a5,a5,s5
    return KADDR(page2pa(page));
ffffffffc0203fd6:	000b1517          	auipc	a0,0xb1
ffffffffc0203fda:	06253503          	ld	a0,98(a0) # ffffffffc02b5038 <va_pa_offset>
ffffffffc0203fde:	8e7d                	and	a2,a2,a5
ffffffffc0203fe0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203fe4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203fe6:	0b067863          	bgeu	a2,a6,ffffffffc0204096 <do_pgfault+0x21c>
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203fea:	6605                	lui	a2,0x1
ffffffffc0203fec:	953e                	add	a0,a0,a5
ffffffffc0203fee:	1c9010ef          	jal	ra,ffffffffc02059b6 <memcpy>
        if (page_insert(mm->pgdir, npage, addr, perm | PTE_W) != 0) {
ffffffffc0203ff2:	01893503          	ld	a0,24(s2)
ffffffffc0203ff6:	0049e693          	ori	a3,s3,4
ffffffffc0203ffa:	8622                	mv	a2,s0
ffffffffc0203ffc:	85d2                	mv	a1,s4
ffffffffc0203ffe:	ec6fe0ef          	jal	ra,ffffffffc02026c4 <page_insert>
ffffffffc0204002:	d121                	beqz	a0,ffffffffc0203f42 <do_pgfault+0xc8>
            cprintf("page_insert in do_pgfault failed\n");
ffffffffc0204004:	00003517          	auipc	a0,0x3
ffffffffc0204008:	33c50513          	addi	a0,a0,828 # ffffffffc0207340 <default_pmm_manager+0xb18>
ffffffffc020400c:	988fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
            free_page(npage);
ffffffffc0204010:	8552                	mv	a0,s4
ffffffffc0204012:	4585                	li	a1,1
ffffffffc0204014:	f47fd0ef          	jal	ra,ffffffffc0201f5a <free_pages>
    ret = -E_NO_MEM;
ffffffffc0204018:	5571                	li	a0,-4
            goto failed;
ffffffffc020401a:	b701                	j	ffffffffc0203f1a <do_pgfault+0xa0>
            page_insert(mm->pgdir, page, addr, perm | PTE_W);
ffffffffc020401c:	01893503          	ld	a0,24(s2)
ffffffffc0204020:	0049e693          	ori	a3,s3,4
ffffffffc0204024:	8622                	mv	a2,s0
ffffffffc0204026:	85a6                	mv	a1,s1
ffffffffc0204028:	e9cfe0ef          	jal	ra,ffffffffc02026c4 <page_insert>
            return 0;
ffffffffc020402c:	4501                	li	a0,0
ffffffffc020402e:	b5f5                	j	ffffffffc0203f1a <do_pgfault+0xa0>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204030:	00003517          	auipc	a0,0x3
ffffffffc0204034:	33850513          	addi	a0,a0,824 # ffffffffc0207368 <default_pmm_manager+0xb40>
ffffffffc0204038:	95cfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = -E_NO_MEM;
ffffffffc020403c:	5571                	li	a0,-4
            goto failed;
ffffffffc020403e:	bdf1                	j	ffffffffc0203f1a <do_pgfault+0xa0>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204040:	85a2                	mv	a1,s0
ffffffffc0204042:	00003517          	auipc	a0,0x3
ffffffffc0204046:	1ee50513          	addi	a0,a0,494 # ffffffffc0207230 <default_pmm_manager+0xa08>
ffffffffc020404a:	94afc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc020404e:	5575                	li	a0,-3
        goto failed;
ffffffffc0204050:	b5e9                	j	ffffffffc0203f1a <do_pgfault+0xa0>
            cprintf("do_pgfault failed: read no-present error, addr=%x\n", addr);
ffffffffc0204052:	85a2                	mv	a1,s0
ffffffffc0204054:	00003517          	auipc	a0,0x3
ffffffffc0204058:	26c50513          	addi	a0,a0,620 # ffffffffc02072c0 <default_pmm_manager+0xa98>
ffffffffc020405c:	938fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc0204060:	5575                	li	a0,-3
            goto failed;
ffffffffc0204062:	bd65                	j	ffffffffc0203f1a <do_pgfault+0xa0>
            cprintf("do_pgfault failed: write error, addr=%x\n", addr);
ffffffffc0204064:	85a2                	mv	a1,s0
ffffffffc0204066:	00003517          	auipc	a0,0x3
ffffffffc020406a:	1fa50513          	addi	a0,a0,506 # ffffffffc0207260 <default_pmm_manager+0xa38>
ffffffffc020406e:	926fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    int ret = -E_INVAL;
ffffffffc0204072:	5575                	li	a0,-3
            goto failed;
ffffffffc0204074:	b55d                	j	ffffffffc0203f1a <do_pgfault+0xa0>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204076:	00003517          	auipc	a0,0x3
ffffffffc020407a:	28250513          	addi	a0,a0,642 # ffffffffc02072f8 <default_pmm_manager+0xad0>
ffffffffc020407e:	916fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204082:	5571                	li	a0,-4
        goto failed;
ffffffffc0204084:	bd59                	j	ffffffffc0203f1a <do_pgfault+0xa0>
            cprintf("alloc_page in do_pgfault failed\n");
ffffffffc0204086:	00003517          	auipc	a0,0x3
ffffffffc020408a:	29250513          	addi	a0,a0,658 # ffffffffc0207318 <default_pmm_manager+0xaf0>
ffffffffc020408e:	906fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204092:	5571                	li	a0,-4
            goto failed;
ffffffffc0204094:	b559                	j	ffffffffc0203f1a <do_pgfault+0xa0>
ffffffffc0204096:	86be                	mv	a3,a5
ffffffffc0204098:	00002617          	auipc	a2,0x2
ffffffffc020409c:	7c860613          	addi	a2,a2,1992 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc02040a0:	07100593          	li	a1,113
ffffffffc02040a4:	00002517          	auipc	a0,0x2
ffffffffc02040a8:	7e450513          	addi	a0,a0,2020 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc02040ac:	be2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02040b0:	00003617          	auipc	a2,0x3
ffffffffc02040b4:	88060613          	addi	a2,a2,-1920 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc02040b8:	06900593          	li	a1,105
ffffffffc02040bc:	00002517          	auipc	a0,0x2
ffffffffc02040c0:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc02040c4:	bcafc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02040c8 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02040c8:	8526                	mv	a0,s1
	jalr s0
ffffffffc02040ca:	9402                	jalr	s0

	jal do_exit
ffffffffc02040cc:	60c000ef          	jal	ra,ffffffffc02046d8 <do_exit>

ffffffffc02040d0 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02040d0:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02040d2:	10800513          	li	a0,264
{
ffffffffc02040d6:	e022                	sd	s0,0(sp)
ffffffffc02040d8:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02040da:	c65fd0ef          	jal	ra,ffffffffc0201d3e <kmalloc>
ffffffffc02040de:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02040e0:	c525                	beqz	a0,ffffffffc0204148 <alloc_proc+0x78>
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
      
        // 进程状态相关
        proc->state = PROC_UNINIT;      // 刚分配，尚未可调度
ffffffffc02040e2:	57fd                	li	a5,-1
ffffffffc02040e4:	1782                	slli	a5,a5,0x20
ffffffffc02040e6:	e11c                	sd	a5,0(a0)
        proc->need_resched = 0;         // 默认不需要重新调度

        // 栈/地址空间
        proc->kstack = 0;               // 内核栈地址待 setup_kstack 设置
        proc->mm = NULL;                // 本实验不创建用户态地址空间（仅内核线程）
        proc->pgdir = boot_pgdir_pa;    // 使用内核页表（RISC-V: satp 的物理基址）
ffffffffc02040e8:	000b1797          	auipc	a5,0xb1
ffffffffc02040ec:	f287b783          	ld	a5,-216(a5) # ffffffffc02b5010 <boot_pgdir_pa>
ffffffffc02040f0:	f55c                	sd	a5,168(a0)
        proc->parent = NULL;
        proc->flags = 0;
        proc->wait_state = 0;
        proc->exit_code = 0;
        proc->cptr = proc->optr = proc->yptr = NULL;
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc02040f2:	4641                	li	a2,16
ffffffffc02040f4:	4581                	li	a1,0
        proc->runs = 0;                 // 运行次数为 0
ffffffffc02040f6:	00052423          	sw	zero,8(a0)
        proc->need_resched = 0;         // 默认不需要重新调度
ffffffffc02040fa:	00053c23          	sd	zero,24(a0)
        proc->kstack = 0;               // 内核栈地址待 setup_kstack 设置
ffffffffc02040fe:	00053823          	sd	zero,16(a0)
        proc->mm = NULL;                // 本实验不创建用户态地址空间（仅内核线程）
ffffffffc0204102:	02053423          	sd	zero,40(a0)
        proc->parent = NULL;
ffffffffc0204106:	02053023          	sd	zero,32(a0)
        proc->flags = 0;
ffffffffc020410a:	0a052823          	sw	zero,176(a0)
        proc->exit_code = 0;
ffffffffc020410e:	0e053423          	sd	zero,232(a0)
        proc->cptr = proc->optr = proc->yptr = NULL;
ffffffffc0204112:	0e053823          	sd	zero,240(a0)
ffffffffc0204116:	0e053c23          	sd	zero,248(a0)
ffffffffc020411a:	10053023          	sd	zero,256(a0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc020411e:	0b450513          	addi	a0,a0,180
ffffffffc0204122:	083010ef          	jal	ra,ffffffffc02059a4 <memset>

        // 上下文与陷入帧
        memset(&proc->context, 0, sizeof(proc->context)); // ra/sp/s0–s11 清零
ffffffffc0204126:	07000613          	li	a2,112
ffffffffc020412a:	4581                	li	a1,0
ffffffffc020412c:	03040513          	addi	a0,s0,48
ffffffffc0204130:	075010ef          	jal	ra,ffffffffc02059a4 <memset>
        proc->tf = NULL;                                  // 由 copy_thread() 放到内核栈顶
        list_init(&(proc->list_link));
ffffffffc0204134:	0c840713          	addi	a4,s0,200
        list_init(&(proc->hash_link));
ffffffffc0204138:	0d840793          	addi	a5,s0,216
        proc->tf = NULL;                                  // 由 copy_thread() 放到内核栈顶
ffffffffc020413c:	0a043023          	sd	zero,160(s0)
    elm->prev = elm->next = elm;
ffffffffc0204140:	e878                	sd	a4,208(s0)
ffffffffc0204142:	e478                	sd	a4,200(s0)
ffffffffc0204144:	f07c                	sd	a5,224(s0)
ffffffffc0204146:	ec7c                	sd	a5,216(s0)
    }
    return proc;
}
ffffffffc0204148:	60a2                	ld	ra,8(sp)
ffffffffc020414a:	8522                	mv	a0,s0
ffffffffc020414c:	6402                	ld	s0,0(sp)
ffffffffc020414e:	0141                	addi	sp,sp,16
ffffffffc0204150:	8082                	ret

ffffffffc0204152 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204152:	000b1797          	auipc	a5,0xb1
ffffffffc0204156:	efe7b783          	ld	a5,-258(a5) # ffffffffc02b5050 <current>
ffffffffc020415a:	73c8                	ld	a0,160(a5)
ffffffffc020415c:	e57fc06f          	j	ffffffffc0200fb2 <forkrets>

ffffffffc0204160 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204160:	000b1797          	auipc	a5,0xb1
ffffffffc0204164:	ef07b783          	ld	a5,-272(a5) # ffffffffc02b5050 <current>
ffffffffc0204168:	43cc                	lw	a1,4(a5)
{
ffffffffc020416a:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020416c:	00003617          	auipc	a2,0x3
ffffffffc0204170:	26460613          	addi	a2,a2,612 # ffffffffc02073d0 <default_pmm_manager+0xba8>
ffffffffc0204174:	00003517          	auipc	a0,0x3
ffffffffc0204178:	26c50513          	addi	a0,a0,620 # ffffffffc02073e0 <default_pmm_manager+0xbb8>
{
ffffffffc020417c:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc020417e:	816fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0204182:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204186:	7e678793          	addi	a5,a5,2022 # a968 <_binary_obj___user_forktest_out_size>
ffffffffc020418a:	e43e                	sd	a5,8(sp)
ffffffffc020418c:	00003517          	auipc	a0,0x3
ffffffffc0204190:	24450513          	addi	a0,a0,580 # ffffffffc02073d0 <default_pmm_manager+0xba8>
ffffffffc0204194:	00050797          	auipc	a5,0x50
ffffffffc0204198:	e6478793          	addi	a5,a5,-412 # ffffffffc0253ff8 <_binary_obj___user_forktest_out_start>
ffffffffc020419c:	f03e                	sd	a5,32(sp)
ffffffffc020419e:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02041a0:	e802                	sd	zero,16(sp)
ffffffffc02041a2:	760010ef          	jal	ra,ffffffffc0205902 <strlen>
ffffffffc02041a6:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02041a8:	4511                	li	a0,4
ffffffffc02041aa:	55a2                	lw	a1,40(sp)
ffffffffc02041ac:	4662                	lw	a2,24(sp)
ffffffffc02041ae:	5682                	lw	a3,32(sp)
ffffffffc02041b0:	4722                	lw	a4,8(sp)
ffffffffc02041b2:	48a9                	li	a7,10
ffffffffc02041b4:	9002                	ebreak
ffffffffc02041b6:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc02041b8:	65c2                	ld	a1,16(sp)
ffffffffc02041ba:	00003517          	auipc	a0,0x3
ffffffffc02041be:	24e50513          	addi	a0,a0,590 # ffffffffc0207408 <default_pmm_manager+0xbe0>
ffffffffc02041c2:	fd3fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(cow);
#endif
    panic("user_main execve failed.\n");
ffffffffc02041c6:	00003617          	auipc	a2,0x3
ffffffffc02041ca:	25260613          	addi	a2,a2,594 # ffffffffc0207418 <default_pmm_manager+0xbf0>
ffffffffc02041ce:	3bf00593          	li	a1,959
ffffffffc02041d2:	00003517          	auipc	a0,0x3
ffffffffc02041d6:	26650513          	addi	a0,a0,614 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc02041da:	ab4fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02041de <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc02041de:	6d14                	ld	a3,24(a0)
{
ffffffffc02041e0:	1141                	addi	sp,sp,-16
ffffffffc02041e2:	e406                	sd	ra,8(sp)
ffffffffc02041e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02041e8:	02f6ee63          	bltu	a3,a5,ffffffffc0204224 <put_pgdir+0x46>
ffffffffc02041ec:	000b1517          	auipc	a0,0xb1
ffffffffc02041f0:	e4c53503          	ld	a0,-436(a0) # ffffffffc02b5038 <va_pa_offset>
ffffffffc02041f4:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc02041f6:	82b1                	srli	a3,a3,0xc
ffffffffc02041f8:	000b1797          	auipc	a5,0xb1
ffffffffc02041fc:	e287b783          	ld	a5,-472(a5) # ffffffffc02b5020 <npage>
ffffffffc0204200:	02f6fe63          	bgeu	a3,a5,ffffffffc020423c <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204204:	00004517          	auipc	a0,0x4
ffffffffc0204208:	acc53503          	ld	a0,-1332(a0) # ffffffffc0207cd0 <nbase>
}
ffffffffc020420c:	60a2                	ld	ra,8(sp)
ffffffffc020420e:	8e89                	sub	a3,a3,a0
ffffffffc0204210:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204212:	000b1517          	auipc	a0,0xb1
ffffffffc0204216:	e1653503          	ld	a0,-490(a0) # ffffffffc02b5028 <pages>
ffffffffc020421a:	4585                	li	a1,1
ffffffffc020421c:	9536                	add	a0,a0,a3
}
ffffffffc020421e:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204220:	d3bfd06f          	j	ffffffffc0201f5a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204224:	00002617          	auipc	a2,0x2
ffffffffc0204228:	6e460613          	addi	a2,a2,1764 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc020422c:	07700593          	li	a1,119
ffffffffc0204230:	00002517          	auipc	a0,0x2
ffffffffc0204234:	65850513          	addi	a0,a0,1624 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0204238:	a56fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020423c:	00002617          	auipc	a2,0x2
ffffffffc0204240:	6f460613          	addi	a2,a2,1780 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc0204244:	06900593          	li	a1,105
ffffffffc0204248:	00002517          	auipc	a0,0x2
ffffffffc020424c:	64050513          	addi	a0,a0,1600 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0204250:	a3efc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204254 <proc_run>:
{
ffffffffc0204254:	7179                	addi	sp,sp,-48
ffffffffc0204256:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204258:	000b1497          	auipc	s1,0xb1
ffffffffc020425c:	df848493          	addi	s1,s1,-520 # ffffffffc02b5050 <current>
ffffffffc0204260:	6098                	ld	a4,0(s1)
{
ffffffffc0204262:	f406                	sd	ra,40(sp)
ffffffffc0204264:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204266:	02a70763          	beq	a4,a0,ffffffffc0204294 <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020426a:	100027f3          	csrr	a5,sstatus
ffffffffc020426e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204270:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204272:	ef85                	bnez	a5,ffffffffc02042aa <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204274:	755c                	ld	a5,168(a0)
ffffffffc0204276:	56fd                	li	a3,-1
ffffffffc0204278:	16fe                	slli	a3,a3,0x3f
ffffffffc020427a:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc020427c:	e088                	sd	a0,0(s1)
ffffffffc020427e:	8fd5                	or	a5,a5,a3
ffffffffc0204280:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(current->context));
ffffffffc0204284:	03050593          	addi	a1,a0,48
ffffffffc0204288:	03070513          	addi	a0,a4,48
ffffffffc020428c:	01c010ef          	jal	ra,ffffffffc02052a8 <switch_to>
    if (flag)
ffffffffc0204290:	00091763          	bnez	s2,ffffffffc020429e <proc_run+0x4a>
}
ffffffffc0204294:	70a2                	ld	ra,40(sp)
ffffffffc0204296:	7482                	ld	s1,32(sp)
ffffffffc0204298:	6962                	ld	s2,24(sp)
ffffffffc020429a:	6145                	addi	sp,sp,48
ffffffffc020429c:	8082                	ret
ffffffffc020429e:	70a2                	ld	ra,40(sp)
ffffffffc02042a0:	7482                	ld	s1,32(sp)
ffffffffc02042a2:	6962                	ld	s2,24(sp)
ffffffffc02042a4:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02042a6:	f08fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc02042aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02042ac:	f08fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;//需要保存现场
ffffffffc02042b0:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02042b2:	6522                	ld	a0,8(sp)
ffffffffc02042b4:	4905                	li	s2,1
ffffffffc02042b6:	bf7d                	j	ffffffffc0204274 <proc_run+0x20>

ffffffffc02042b8 <do_fork>:
{
ffffffffc02042b8:	7119                	addi	sp,sp,-128
ffffffffc02042ba:	e8d2                	sd	s4,80(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02042bc:	000b1a17          	auipc	s4,0xb1
ffffffffc02042c0:	daca0a13          	addi	s4,s4,-596 # ffffffffc02b5068 <nr_process>
ffffffffc02042c4:	000a2703          	lw	a4,0(s4)
{
ffffffffc02042c8:	fc86                	sd	ra,120(sp)
ffffffffc02042ca:	f8a2                	sd	s0,112(sp)
ffffffffc02042cc:	f4a6                	sd	s1,104(sp)
ffffffffc02042ce:	f0ca                	sd	s2,96(sp)
ffffffffc02042d0:	ecce                	sd	s3,88(sp)
ffffffffc02042d2:	e4d6                	sd	s5,72(sp)
ffffffffc02042d4:	e0da                	sd	s6,64(sp)
ffffffffc02042d6:	fc5e                	sd	s7,56(sp)
ffffffffc02042d8:	f862                	sd	s8,48(sp)
ffffffffc02042da:	f466                	sd	s9,40(sp)
ffffffffc02042dc:	f06a                	sd	s10,32(sp)
ffffffffc02042de:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02042e0:	6785                	lui	a5,0x1
ffffffffc02042e2:	32f75263          	bge	a4,a5,ffffffffc0204606 <do_fork+0x34e>
ffffffffc02042e6:	892a                	mv	s2,a0
ffffffffc02042e8:	89ae                	mv	s3,a1
ffffffffc02042ea:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc02042ec:	de5ff0ef          	jal	ra,ffffffffc02040d0 <alloc_proc>
ffffffffc02042f0:	842a                	mv	s0,a0
ffffffffc02042f2:	2e050763          	beqz	a0,ffffffffc02045e0 <do_fork+0x328>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02042f6:	4509                	li	a0,2
ffffffffc02042f8:	c25fd0ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
    if (page != NULL)
ffffffffc02042fc:	2c050f63          	beqz	a0,ffffffffc02045da <do_fork+0x322>
    return page - pages + nbase;
ffffffffc0204300:	000b1a97          	auipc	s5,0xb1
ffffffffc0204304:	d28a8a93          	addi	s5,s5,-728 # ffffffffc02b5028 <pages>
ffffffffc0204308:	000ab683          	ld	a3,0(s5)
ffffffffc020430c:	00004797          	auipc	a5,0x4
ffffffffc0204310:	9c478793          	addi	a5,a5,-1596 # ffffffffc0207cd0 <nbase>
ffffffffc0204314:	6390                	ld	a2,0(a5)
ffffffffc0204316:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020431a:	000b1b97          	auipc	s7,0xb1
ffffffffc020431e:	d06b8b93          	addi	s7,s7,-762 # ffffffffc02b5020 <npage>
    return page - pages + nbase;
ffffffffc0204322:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204324:	57fd                	li	a5,-1
ffffffffc0204326:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc020432a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020432c:	00c7db13          	srli	s6,a5,0xc
ffffffffc0204330:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204334:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204336:	32e5fd63          	bgeu	a1,a4,ffffffffc0204670 <do_fork+0x3b8>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020433a:	000b1c17          	auipc	s8,0xb1
ffffffffc020433e:	d16c0c13          	addi	s8,s8,-746 # ffffffffc02b5050 <current>
ffffffffc0204342:	000c3583          	ld	a1,0(s8)
ffffffffc0204346:	000b1c97          	auipc	s9,0xb1
ffffffffc020434a:	cf2c8c93          	addi	s9,s9,-782 # ffffffffc02b5038 <va_pa_offset>
ffffffffc020434e:	000cb703          	ld	a4,0(s9)
ffffffffc0204352:	0285bd83          	ld	s11,40(a1)
ffffffffc0204356:	e432                	sd	a2,8(sp)
ffffffffc0204358:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020435a:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc020435c:	020d8763          	beqz	s11,ffffffffc020438a <do_fork+0xd2>
    if (clone_flags & CLONE_VM)
ffffffffc0204360:	10097913          	andi	s2,s2,256
ffffffffc0204364:	1a090a63          	beqz	s2,ffffffffc0204518 <do_fork+0x260>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204368:	030da783          	lw	a5,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020436c:	018db683          	ld	a3,24(s11)
ffffffffc0204370:	c0200737          	lui	a4,0xc0200
ffffffffc0204374:	2785                	addiw	a5,a5,1
ffffffffc0204376:	02fda823          	sw	a5,48(s11)
    proc->mm = mm;
ffffffffc020437a:	03b43423          	sd	s11,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020437e:	2ce6e163          	bltu	a3,a4,ffffffffc0204640 <do_fork+0x388>
ffffffffc0204382:	000cb783          	ld	a5,0(s9)
ffffffffc0204386:	8e9d                	sub	a3,a3,a5
ffffffffc0204388:	f454                	sd	a3,168(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020438a:	100027f3          	csrr	a5,sstatus
ffffffffc020438e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204390:	4a81                	li	s5,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204392:	26079163          	bnez	a5,ffffffffc02045f4 <do_fork+0x33c>
    if (++last_pid >= MAX_PID)
ffffffffc0204396:	000ad817          	auipc	a6,0xad
ffffffffc020439a:	81a80813          	addi	a6,a6,-2022 # ffffffffc02b0bb0 <last_pid.1>
    proc->parent = current;
ffffffffc020439e:	000c3703          	ld	a4,0(s8)
    if (++last_pid >= MAX_PID)
ffffffffc02043a2:	00082783          	lw	a5,0(a6)
ffffffffc02043a6:	6689                	lui	a3,0x2
    proc->parent = current;
ffffffffc02043a8:	f018                	sd	a4,32(s0)
    if (++last_pid >= MAX_PID)
ffffffffc02043aa:	0017851b          	addiw	a0,a5,1
    current->wait_state = 0;
ffffffffc02043ae:	0e072623          	sw	zero,236(a4) # ffffffffc02000ec <readline+0x46>
    if (++last_pid >= MAX_PID)
ffffffffc02043b2:	00a82023          	sw	a0,0(a6)
ffffffffc02043b6:	0ed55863          	bge	a0,a3,ffffffffc02044a6 <do_fork+0x1ee>
    if (last_pid >= next_safe)
ffffffffc02043ba:	000ac317          	auipc	t1,0xac
ffffffffc02043be:	7fa30313          	addi	t1,t1,2042 # ffffffffc02b0bb4 <next_safe.0>
ffffffffc02043c2:	00032783          	lw	a5,0(t1)
ffffffffc02043c6:	000b1917          	auipc	s2,0xb1
ffffffffc02043ca:	c0a90913          	addi	s2,s2,-1014 # ffffffffc02b4fd0 <proc_list>
ffffffffc02043ce:	0ef55463          	bge	a0,a5,ffffffffc02044b6 <do_fork+0x1fe>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02043d2:	6818                	ld	a4,16(s0)
ffffffffc02043d4:	6789                	lui	a5,0x2
ffffffffc02043d6:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd0>
ffffffffc02043da:	973e                	add	a4,a4,a5
    *(proc->tf) = *tf;
ffffffffc02043dc:	8626                	mv	a2,s1
    proc->pid = get_pid();
ffffffffc02043de:	c048                	sw	a0,4(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02043e0:	f058                	sd	a4,160(s0)
    *(proc->tf) = *tf;
ffffffffc02043e2:	87ba                	mv	a5,a4
ffffffffc02043e4:	12048313          	addi	t1,s1,288
ffffffffc02043e8:	00063883          	ld	a7,0(a2)
ffffffffc02043ec:	00863803          	ld	a6,8(a2)
ffffffffc02043f0:	6a0c                	ld	a1,16(a2)
ffffffffc02043f2:	6e14                	ld	a3,24(a2)
ffffffffc02043f4:	0117b023          	sd	a7,0(a5)
ffffffffc02043f8:	0107b423          	sd	a6,8(a5)
ffffffffc02043fc:	eb8c                	sd	a1,16(a5)
ffffffffc02043fe:	ef94                	sd	a3,24(a5)
ffffffffc0204400:	02060613          	addi	a2,a2,32
ffffffffc0204404:	02078793          	addi	a5,a5,32
ffffffffc0204408:	fe6610e3          	bne	a2,t1,ffffffffc02043e8 <do_fork+0x130>
    proc->tf->gpr.a0 = 0;
ffffffffc020440c:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204410:	10098263          	beqz	s3,ffffffffc0204514 <do_fork+0x25c>
ffffffffc0204414:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204418:	00000797          	auipc	a5,0x0
ffffffffc020441c:	d3a78793          	addi	a5,a5,-710 # ffffffffc0204152 <forkret>
ffffffffc0204420:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204422:	fc18                	sd	a4,56(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204424:	45a9                	li	a1,10
ffffffffc0204426:	2501                	sext.w	a0,a0
ffffffffc0204428:	0d6010ef          	jal	ra,ffffffffc02054fe <hash32>
ffffffffc020442c:	02051793          	slli	a5,a0,0x20
ffffffffc0204430:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204434:	000ad797          	auipc	a5,0xad
ffffffffc0204438:	b9c78793          	addi	a5,a5,-1124 # ffffffffc02b0fd0 <hash_list>
ffffffffc020443c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020443e:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204440:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204442:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc0204446:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204448:	00893603          	ld	a2,8(s2)
    prev->next = next->prev = elm;
ffffffffc020444c:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020444e:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204450:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc0204454:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc0204456:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204458:	e21c                	sd	a5,0(a2)
ffffffffc020445a:	00f93423          	sd	a5,8(s2)
    elm->next = next;
ffffffffc020445e:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204460:	0d243423          	sd	s2,200(s0)
    proc->yptr = NULL;
ffffffffc0204464:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204468:	10e43023          	sd	a4,256(s0)
ffffffffc020446c:	c311                	beqz	a4,ffffffffc0204470 <do_fork+0x1b8>
        proc->optr->yptr = proc;
ffffffffc020446e:	ff60                	sd	s0,248(a4)
    nr_process++;
ffffffffc0204470:	000a2783          	lw	a5,0(s4)
    proc->parent->cptr = proc;
ffffffffc0204474:	fae0                	sd	s0,240(a3)
    wakeup_proc(proc);
ffffffffc0204476:	8522                	mv	a0,s0
    nr_process++;
ffffffffc0204478:	2785                	addiw	a5,a5,1
ffffffffc020447a:	00fa2023          	sw	a5,0(s4)
    wakeup_proc(proc);
ffffffffc020447e:	695000ef          	jal	ra,ffffffffc0205312 <wakeup_proc>
    if (flag)
ffffffffc0204482:	160a9163          	bnez	s5,ffffffffc02045e4 <do_fork+0x32c>
    ret = proc->pid;
ffffffffc0204486:	4048                	lw	a0,4(s0)
}
ffffffffc0204488:	70e6                	ld	ra,120(sp)
ffffffffc020448a:	7446                	ld	s0,112(sp)
ffffffffc020448c:	74a6                	ld	s1,104(sp)
ffffffffc020448e:	7906                	ld	s2,96(sp)
ffffffffc0204490:	69e6                	ld	s3,88(sp)
ffffffffc0204492:	6a46                	ld	s4,80(sp)
ffffffffc0204494:	6aa6                	ld	s5,72(sp)
ffffffffc0204496:	6b06                	ld	s6,64(sp)
ffffffffc0204498:	7be2                	ld	s7,56(sp)
ffffffffc020449a:	7c42                	ld	s8,48(sp)
ffffffffc020449c:	7ca2                	ld	s9,40(sp)
ffffffffc020449e:	7d02                	ld	s10,32(sp)
ffffffffc02044a0:	6de2                	ld	s11,24(sp)
ffffffffc02044a2:	6109                	addi	sp,sp,128
ffffffffc02044a4:	8082                	ret
        last_pid = 1;
ffffffffc02044a6:	4785                	li	a5,1
ffffffffc02044a8:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02044ac:	4505                	li	a0,1
ffffffffc02044ae:	000ac317          	auipc	t1,0xac
ffffffffc02044b2:	70630313          	addi	t1,t1,1798 # ffffffffc02b0bb4 <next_safe.0>
    return listelm->next;
ffffffffc02044b6:	000b1917          	auipc	s2,0xb1
ffffffffc02044ba:	b1a90913          	addi	s2,s2,-1254 # ffffffffc02b4fd0 <proc_list>
ffffffffc02044be:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc02044c2:	6789                	lui	a5,0x2
ffffffffc02044c4:	00f32023          	sw	a5,0(t1)
ffffffffc02044c8:	86aa                	mv	a3,a0
ffffffffc02044ca:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02044cc:	6e89                	lui	t4,0x2
ffffffffc02044ce:	132e0763          	beq	t3,s2,ffffffffc02045fc <do_fork+0x344>
ffffffffc02044d2:	88ae                	mv	a7,a1
ffffffffc02044d4:	87f2                	mv	a5,t3
ffffffffc02044d6:	6609                	lui	a2,0x2
ffffffffc02044d8:	a811                	j	ffffffffc02044ec <do_fork+0x234>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02044da:	00e6d663          	bge	a3,a4,ffffffffc02044e6 <do_fork+0x22e>
ffffffffc02044de:	00c75463          	bge	a4,a2,ffffffffc02044e6 <do_fork+0x22e>
ffffffffc02044e2:	863a                	mv	a2,a4
ffffffffc02044e4:	4885                	li	a7,1
ffffffffc02044e6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02044e8:	01278d63          	beq	a5,s2,ffffffffc0204502 <do_fork+0x24a>
            if (proc->pid == last_pid)
ffffffffc02044ec:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c74>
ffffffffc02044f0:	fed715e3          	bne	a4,a3,ffffffffc02044da <do_fork+0x222>
                if (++last_pid >= next_safe)
ffffffffc02044f4:	2685                	addiw	a3,a3,1
ffffffffc02044f6:	0ec6da63          	bge	a3,a2,ffffffffc02045ea <do_fork+0x332>
ffffffffc02044fa:	679c                	ld	a5,8(a5)
ffffffffc02044fc:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02044fe:	ff2797e3          	bne	a5,s2,ffffffffc02044ec <do_fork+0x234>
ffffffffc0204502:	c581                	beqz	a1,ffffffffc020450a <do_fork+0x252>
ffffffffc0204504:	00d82023          	sw	a3,0(a6)
ffffffffc0204508:	8536                	mv	a0,a3
ffffffffc020450a:	ec0884e3          	beqz	a7,ffffffffc02043d2 <do_fork+0x11a>
ffffffffc020450e:	00c32023          	sw	a2,0(t1)
ffffffffc0204512:	b5c1                	j	ffffffffc02043d2 <do_fork+0x11a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204514:	89ba                	mv	s3,a4
ffffffffc0204516:	bdfd                	j	ffffffffc0204414 <do_fork+0x15c>
    if ((mm = mm_create()) == NULL)
ffffffffc0204518:	a58ff0ef          	jal	ra,ffffffffc0203770 <mm_create>
ffffffffc020451c:	8d2a                	mv	s10,a0
ffffffffc020451e:	c159                	beqz	a0,ffffffffc02045a4 <do_fork+0x2ec>
    if ((page = alloc_page()) == NULL)
ffffffffc0204520:	4505                	li	a0,1
ffffffffc0204522:	9fbfd0ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0204526:	cd25                	beqz	a0,ffffffffc020459e <do_fork+0x2e6>
    return page - pages + nbase;
ffffffffc0204528:	000ab683          	ld	a3,0(s5)
ffffffffc020452c:	6622                	ld	a2,8(sp)
    return KADDR(page2pa(page));
ffffffffc020452e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204532:	40d506b3          	sub	a3,a0,a3
ffffffffc0204536:	8699                	srai	a3,a3,0x6
ffffffffc0204538:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020453a:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc020453e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204540:	12e7f863          	bgeu	a5,a4,ffffffffc0204670 <do_fork+0x3b8>
ffffffffc0204544:	000cb903          	ld	s2,0(s9)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204548:	6605                	lui	a2,0x1
ffffffffc020454a:	000b1597          	auipc	a1,0xb1
ffffffffc020454e:	ace5b583          	ld	a1,-1330(a1) # ffffffffc02b5018 <boot_pgdir_va>
ffffffffc0204552:	9936                	add	s2,s2,a3
ffffffffc0204554:	854a                	mv	a0,s2
ffffffffc0204556:	460010ef          	jal	ra,ffffffffc02059b6 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020455a:	038d8b13          	addi	s6,s11,56
    mm->pgdir = pgdir;
ffffffffc020455e:	012d3c23          	sd	s2,24(s10)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204562:	4785                	li	a5,1
ffffffffc0204564:	40fb37af          	amoor.d	a5,a5,(s6)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204568:	8b85                	andi	a5,a5,1
ffffffffc020456a:	4905                	li	s2,1
ffffffffc020456c:	c799                	beqz	a5,ffffffffc020457a <do_fork+0x2c2>
    {
        schedule();
ffffffffc020456e:	625000ef          	jal	ra,ffffffffc0205392 <schedule>
ffffffffc0204572:	412b37af          	amoor.d	a5,s2,(s6)
    while (!try_lock(lock))
ffffffffc0204576:	8b85                	andi	a5,a5,1
ffffffffc0204578:	fbfd                	bnez	a5,ffffffffc020456e <do_fork+0x2b6>
        ret = dup_mmap(mm, oldmm);
ffffffffc020457a:	85ee                	mv	a1,s11
ffffffffc020457c:	856a                	mv	a0,s10
ffffffffc020457e:	c34ff0ef          	jal	ra,ffffffffc02039b2 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204582:	57f9                	li	a5,-2
ffffffffc0204584:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc0204588:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020458a:	c3d9                	beqz	a5,ffffffffc0204610 <do_fork+0x358>
good_mm:
ffffffffc020458c:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc020458e:	dc050de3          	beqz	a0,ffffffffc0204368 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc0204592:	856a                	mv	a0,s10
ffffffffc0204594:	cb8ff0ef          	jal	ra,ffffffffc0203a4c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204598:	856a                	mv	a0,s10
ffffffffc020459a:	c45ff0ef          	jal	ra,ffffffffc02041de <put_pgdir>
    mm_destroy(mm);
ffffffffc020459e:	856a                	mv	a0,s10
ffffffffc02045a0:	b10ff0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02045a4:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02045a6:	c02007b7          	lui	a5,0xc0200
ffffffffc02045aa:	0af6e763          	bltu	a3,a5,ffffffffc0204658 <do_fork+0x3a0>
ffffffffc02045ae:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage)
ffffffffc02045b2:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02045b6:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02045ba:	83b1                	srli	a5,a5,0xc
ffffffffc02045bc:	06e7f663          	bgeu	a5,a4,ffffffffc0204628 <do_fork+0x370>
    return &pages[PPN(pa) - nbase];
ffffffffc02045c0:	00003717          	auipc	a4,0x3
ffffffffc02045c4:	71070713          	addi	a4,a4,1808 # ffffffffc0207cd0 <nbase>
ffffffffc02045c8:	6318                	ld	a4,0(a4)
ffffffffc02045ca:	000ab503          	ld	a0,0(s5)
ffffffffc02045ce:	4589                	li	a1,2
ffffffffc02045d0:	8f99                	sub	a5,a5,a4
ffffffffc02045d2:	079a                	slli	a5,a5,0x6
ffffffffc02045d4:	953e                	add	a0,a0,a5
ffffffffc02045d6:	985fd0ef          	jal	ra,ffffffffc0201f5a <free_pages>
    kfree(proc);
ffffffffc02045da:	8522                	mv	a0,s0
ffffffffc02045dc:	813fd0ef          	jal	ra,ffffffffc0201dee <kfree>
    ret = -E_NO_MEM;
ffffffffc02045e0:	5571                	li	a0,-4
    return ret;
ffffffffc02045e2:	b55d                	j	ffffffffc0204488 <do_fork+0x1d0>
        intr_enable();
ffffffffc02045e4:	bcafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02045e8:	bd79                	j	ffffffffc0204486 <do_fork+0x1ce>
                    if (last_pid >= MAX_PID)
ffffffffc02045ea:	01d6c363          	blt	a3,t4,ffffffffc02045f0 <do_fork+0x338>
                        last_pid = 1;
ffffffffc02045ee:	4685                	li	a3,1
                    goto repeat;
ffffffffc02045f0:	4585                	li	a1,1
ffffffffc02045f2:	bdf1                	j	ffffffffc02044ce <do_fork+0x216>
        intr_disable();
ffffffffc02045f4:	bc0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02045f8:	4a85                	li	s5,1
ffffffffc02045fa:	bb71                	j	ffffffffc0204396 <do_fork+0xde>
ffffffffc02045fc:	c599                	beqz	a1,ffffffffc020460a <do_fork+0x352>
ffffffffc02045fe:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204602:	8536                	mv	a0,a3
ffffffffc0204604:	b3f9                	j	ffffffffc02043d2 <do_fork+0x11a>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204606:	556d                	li	a0,-5
ffffffffc0204608:	b541                	j	ffffffffc0204488 <do_fork+0x1d0>
    return last_pid;
ffffffffc020460a:	00082503          	lw	a0,0(a6)
ffffffffc020460e:	b3d1                	j	ffffffffc02043d2 <do_fork+0x11a>
    {
        panic("Unlock failed.\n");
ffffffffc0204610:	00003617          	auipc	a2,0x3
ffffffffc0204614:	e4060613          	addi	a2,a2,-448 # ffffffffc0207450 <default_pmm_manager+0xc28>
ffffffffc0204618:	03f00593          	li	a1,63
ffffffffc020461c:	00003517          	auipc	a0,0x3
ffffffffc0204620:	e4450513          	addi	a0,a0,-444 # ffffffffc0207460 <default_pmm_manager+0xc38>
ffffffffc0204624:	e6bfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204628:	00002617          	auipc	a2,0x2
ffffffffc020462c:	30860613          	addi	a2,a2,776 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc0204630:	06900593          	li	a1,105
ffffffffc0204634:	00002517          	auipc	a0,0x2
ffffffffc0204638:	25450513          	addi	a0,a0,596 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc020463c:	e53fb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204640:	00002617          	auipc	a2,0x2
ffffffffc0204644:	2c860613          	addi	a2,a2,712 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc0204648:	18e00593          	li	a1,398
ffffffffc020464c:	00003517          	auipc	a0,0x3
ffffffffc0204650:	dec50513          	addi	a0,a0,-532 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204654:	e3bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204658:	00002617          	auipc	a2,0x2
ffffffffc020465c:	2b060613          	addi	a2,a2,688 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc0204660:	07700593          	li	a1,119
ffffffffc0204664:	00002517          	auipc	a0,0x2
ffffffffc0204668:	22450513          	addi	a0,a0,548 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc020466c:	e23fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204670:	00002617          	auipc	a2,0x2
ffffffffc0204674:	1f060613          	addi	a2,a2,496 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc0204678:	07100593          	li	a1,113
ffffffffc020467c:	00002517          	auipc	a0,0x2
ffffffffc0204680:	20c50513          	addi	a0,a0,524 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0204684:	e0bfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204688 <kernel_thread>:
{
ffffffffc0204688:	7129                	addi	sp,sp,-320
ffffffffc020468a:	fa22                	sd	s0,304(sp)
ffffffffc020468c:	f626                	sd	s1,296(sp)
ffffffffc020468e:	f24a                	sd	s2,288(sp)
ffffffffc0204690:	84ae                	mv	s1,a1
ffffffffc0204692:	892a                	mv	s2,a0
ffffffffc0204694:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204696:	4581                	li	a1,0
ffffffffc0204698:	12000613          	li	a2,288
ffffffffc020469c:	850a                	mv	a0,sp
{
ffffffffc020469e:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046a0:	304010ef          	jal	ra,ffffffffc02059a4 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02046a4:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02046a6:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02046a8:	100027f3          	csrr	a5,sstatus
ffffffffc02046ac:	edd7f793          	andi	a5,a5,-291
ffffffffc02046b0:	1207e793          	ori	a5,a5,288
ffffffffc02046b4:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046b6:	860a                	mv	a2,sp
ffffffffc02046b8:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046bc:	00000797          	auipc	a5,0x0
ffffffffc02046c0:	a0c78793          	addi	a5,a5,-1524 # ffffffffc02040c8 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046c4:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046c6:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046c8:	bf1ff0ef          	jal	ra,ffffffffc02042b8 <do_fork>
}
ffffffffc02046cc:	70f2                	ld	ra,312(sp)
ffffffffc02046ce:	7452                	ld	s0,304(sp)
ffffffffc02046d0:	74b2                	ld	s1,296(sp)
ffffffffc02046d2:	7912                	ld	s2,288(sp)
ffffffffc02046d4:	6131                	addi	sp,sp,320
ffffffffc02046d6:	8082                	ret

ffffffffc02046d8 <do_exit>:
{
ffffffffc02046d8:	7179                	addi	sp,sp,-48
ffffffffc02046da:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02046dc:	000b1417          	auipc	s0,0xb1
ffffffffc02046e0:	97440413          	addi	s0,s0,-1676 # ffffffffc02b5050 <current>
ffffffffc02046e4:	601c                	ld	a5,0(s0)
{
ffffffffc02046e6:	f406                	sd	ra,40(sp)
ffffffffc02046e8:	ec26                	sd	s1,24(sp)
ffffffffc02046ea:	e84a                	sd	s2,16(sp)
ffffffffc02046ec:	e44e                	sd	s3,8(sp)
ffffffffc02046ee:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02046f0:	000b1717          	auipc	a4,0xb1
ffffffffc02046f4:	96873703          	ld	a4,-1688(a4) # ffffffffc02b5058 <idleproc>
ffffffffc02046f8:	0ce78c63          	beq	a5,a4,ffffffffc02047d0 <do_exit+0xf8>
    if (current == initproc)
ffffffffc02046fc:	000b1497          	auipc	s1,0xb1
ffffffffc0204700:	96448493          	addi	s1,s1,-1692 # ffffffffc02b5060 <initproc>
ffffffffc0204704:	6098                	ld	a4,0(s1)
ffffffffc0204706:	0ee78b63          	beq	a5,a4,ffffffffc02047fc <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc020470a:	0287b983          	ld	s3,40(a5)
ffffffffc020470e:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204710:	02098663          	beqz	s3,ffffffffc020473c <do_exit+0x64>
ffffffffc0204714:	000b1797          	auipc	a5,0xb1
ffffffffc0204718:	8fc7b783          	ld	a5,-1796(a5) # ffffffffc02b5010 <boot_pgdir_pa>
ffffffffc020471c:	577d                	li	a4,-1
ffffffffc020471e:	177e                	slli	a4,a4,0x3f
ffffffffc0204720:	83b1                	srli	a5,a5,0xc
ffffffffc0204722:	8fd9                	or	a5,a5,a4
ffffffffc0204724:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204728:	0309a783          	lw	a5,48(s3)
ffffffffc020472c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204730:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204734:	cb55                	beqz	a4,ffffffffc02047e8 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204736:	601c                	ld	a5,0(s0)
ffffffffc0204738:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020473c:	601c                	ld	a5,0(s0)
ffffffffc020473e:	470d                	li	a4,3
ffffffffc0204740:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204742:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204746:	100027f3          	csrr	a5,sstatus
ffffffffc020474a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020474c:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020474e:	e3f9                	bnez	a5,ffffffffc0204814 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204750:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204752:	800007b7          	lui	a5,0x80000
ffffffffc0204756:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204758:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020475a:	0ec52703          	lw	a4,236(a0)
ffffffffc020475e:	0af70f63          	beq	a4,a5,ffffffffc020481c <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204762:	6018                	ld	a4,0(s0)
ffffffffc0204764:	7b7c                	ld	a5,240(a4)
ffffffffc0204766:	c3a1                	beqz	a5,ffffffffc02047a6 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204768:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc020476c:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc020476e:	0985                	addi	s3,s3,1
ffffffffc0204770:	a021                	j	ffffffffc0204778 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204772:	6018                	ld	a4,0(s0)
ffffffffc0204774:	7b7c                	ld	a5,240(a4)
ffffffffc0204776:	cb85                	beqz	a5,ffffffffc02047a6 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204778:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020477c:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020477e:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204780:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204782:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204786:	10e7b023          	sd	a4,256(a5)
ffffffffc020478a:	c311                	beqz	a4,ffffffffc020478e <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020478c:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020478e:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204790:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204792:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204794:	fd271fe3          	bne	a4,s2,ffffffffc0204772 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204798:	0ec52783          	lw	a5,236(a0)
ffffffffc020479c:	fd379be3          	bne	a5,s3,ffffffffc0204772 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02047a0:	373000ef          	jal	ra,ffffffffc0205312 <wakeup_proc>
ffffffffc02047a4:	b7f9                	j	ffffffffc0204772 <do_exit+0x9a>
    if (flag)
ffffffffc02047a6:	020a1263          	bnez	s4,ffffffffc02047ca <do_exit+0xf2>
    schedule();
ffffffffc02047aa:	3e9000ef          	jal	ra,ffffffffc0205392 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02047ae:	601c                	ld	a5,0(s0)
ffffffffc02047b0:	00003617          	auipc	a2,0x3
ffffffffc02047b4:	ce860613          	addi	a2,a2,-792 # ffffffffc0207498 <default_pmm_manager+0xc70>
ffffffffc02047b8:	23d00593          	li	a1,573
ffffffffc02047bc:	43d4                	lw	a3,4(a5)
ffffffffc02047be:	00003517          	auipc	a0,0x3
ffffffffc02047c2:	c7a50513          	addi	a0,a0,-902 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc02047c6:	cc9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02047ca:	9e4fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02047ce:	bff1                	j	ffffffffc02047aa <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02047d0:	00003617          	auipc	a2,0x3
ffffffffc02047d4:	ca860613          	addi	a2,a2,-856 # ffffffffc0207478 <default_pmm_manager+0xc50>
ffffffffc02047d8:	20900593          	li	a1,521
ffffffffc02047dc:	00003517          	auipc	a0,0x3
ffffffffc02047e0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc02047e4:	cabfb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02047e8:	854e                	mv	a0,s3
ffffffffc02047ea:	a62ff0ef          	jal	ra,ffffffffc0203a4c <exit_mmap>
            put_pgdir(mm);
ffffffffc02047ee:	854e                	mv	a0,s3
ffffffffc02047f0:	9efff0ef          	jal	ra,ffffffffc02041de <put_pgdir>
            mm_destroy(mm);
ffffffffc02047f4:	854e                	mv	a0,s3
ffffffffc02047f6:	8baff0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>
ffffffffc02047fa:	bf35                	j	ffffffffc0204736 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02047fc:	00003617          	auipc	a2,0x3
ffffffffc0204800:	c8c60613          	addi	a2,a2,-884 # ffffffffc0207488 <default_pmm_manager+0xc60>
ffffffffc0204804:	20d00593          	li	a1,525
ffffffffc0204808:	00003517          	auipc	a0,0x3
ffffffffc020480c:	c3050513          	addi	a0,a0,-976 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204810:	c7ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204814:	9a0fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204818:	4a05                	li	s4,1
ffffffffc020481a:	bf1d                	j	ffffffffc0204750 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020481c:	2f7000ef          	jal	ra,ffffffffc0205312 <wakeup_proc>
ffffffffc0204820:	b789                	j	ffffffffc0204762 <do_exit+0x8a>

ffffffffc0204822 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204822:	715d                	addi	sp,sp,-80
ffffffffc0204824:	f84a                	sd	s2,48(sp)
ffffffffc0204826:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204828:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020482c:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc020482e:	fc26                	sd	s1,56(sp)
ffffffffc0204830:	f052                	sd	s4,32(sp)
ffffffffc0204832:	ec56                	sd	s5,24(sp)
ffffffffc0204834:	e85a                	sd	s6,16(sp)
ffffffffc0204836:	e45e                	sd	s7,8(sp)
ffffffffc0204838:	e486                	sd	ra,72(sp)
ffffffffc020483a:	e0a2                	sd	s0,64(sp)
ffffffffc020483c:	84aa                	mv	s1,a0
ffffffffc020483e:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204840:	000b1b97          	auipc	s7,0xb1
ffffffffc0204844:	810b8b93          	addi	s7,s7,-2032 # ffffffffc02b5050 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204848:	00050b1b          	sext.w	s6,a0
ffffffffc020484c:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204850:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204852:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204854:	ccbd                	beqz	s1,ffffffffc02048d2 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204856:	0359e863          	bltu	s3,s5,ffffffffc0204886 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020485a:	45a9                	li	a1,10
ffffffffc020485c:	855a                	mv	a0,s6
ffffffffc020485e:	4a1000ef          	jal	ra,ffffffffc02054fe <hash32>
ffffffffc0204862:	02051793          	slli	a5,a0,0x20
ffffffffc0204866:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020486a:	000ac797          	auipc	a5,0xac
ffffffffc020486e:	76678793          	addi	a5,a5,1894 # ffffffffc02b0fd0 <hash_list>
ffffffffc0204872:	953e                	add	a0,a0,a5
ffffffffc0204874:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204876:	a029                	j	ffffffffc0204880 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204878:	f2c42783          	lw	a5,-212(s0)
ffffffffc020487c:	02978163          	beq	a5,s1,ffffffffc020489e <do_wait.part.0+0x7c>
ffffffffc0204880:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204882:	fe851be3          	bne	a0,s0,ffffffffc0204878 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204886:	5579                	li	a0,-2
}
ffffffffc0204888:	60a6                	ld	ra,72(sp)
ffffffffc020488a:	6406                	ld	s0,64(sp)
ffffffffc020488c:	74e2                	ld	s1,56(sp)
ffffffffc020488e:	7942                	ld	s2,48(sp)
ffffffffc0204890:	79a2                	ld	s3,40(sp)
ffffffffc0204892:	7a02                	ld	s4,32(sp)
ffffffffc0204894:	6ae2                	ld	s5,24(sp)
ffffffffc0204896:	6b42                	ld	s6,16(sp)
ffffffffc0204898:	6ba2                	ld	s7,8(sp)
ffffffffc020489a:	6161                	addi	sp,sp,80
ffffffffc020489c:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020489e:	000bb683          	ld	a3,0(s7)
ffffffffc02048a2:	f4843783          	ld	a5,-184(s0)
ffffffffc02048a6:	fed790e3          	bne	a5,a3,ffffffffc0204886 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02048aa:	f2842703          	lw	a4,-216(s0)
ffffffffc02048ae:	478d                	li	a5,3
ffffffffc02048b0:	0ef70b63          	beq	a4,a5,ffffffffc02049a6 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02048b4:	4785                	li	a5,1
ffffffffc02048b6:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02048b8:	0f26a623          	sw	s2,236(a3) # 20ec <_binary_obj___user_faultread_out_size-0x7ac4>
        schedule();
ffffffffc02048bc:	2d7000ef          	jal	ra,ffffffffc0205392 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02048c0:	000bb783          	ld	a5,0(s7)
ffffffffc02048c4:	0b07a783          	lw	a5,176(a5)
ffffffffc02048c8:	8b85                	andi	a5,a5,1
ffffffffc02048ca:	d7c9                	beqz	a5,ffffffffc0204854 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02048cc:	555d                	li	a0,-9
ffffffffc02048ce:	e0bff0ef          	jal	ra,ffffffffc02046d8 <do_exit>
        proc = current->cptr;
ffffffffc02048d2:	000bb683          	ld	a3,0(s7)
ffffffffc02048d6:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02048d8:	d45d                	beqz	s0,ffffffffc0204886 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02048da:	470d                	li	a4,3
ffffffffc02048dc:	a021                	j	ffffffffc02048e4 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02048de:	10043403          	ld	s0,256(s0)
ffffffffc02048e2:	d869                	beqz	s0,ffffffffc02048b4 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02048e4:	401c                	lw	a5,0(s0)
ffffffffc02048e6:	fee79ce3          	bne	a5,a4,ffffffffc02048de <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02048ea:	000b0797          	auipc	a5,0xb0
ffffffffc02048ee:	76e7b783          	ld	a5,1902(a5) # ffffffffc02b5058 <idleproc>
ffffffffc02048f2:	0c878963          	beq	a5,s0,ffffffffc02049c4 <do_wait.part.0+0x1a2>
ffffffffc02048f6:	000b0797          	auipc	a5,0xb0
ffffffffc02048fa:	76a7b783          	ld	a5,1898(a5) # ffffffffc02b5060 <initproc>
ffffffffc02048fe:	0cf40363          	beq	s0,a5,ffffffffc02049c4 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204902:	000a0663          	beqz	s4,ffffffffc020490e <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204906:	0e842783          	lw	a5,232(s0)
ffffffffc020490a:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020490e:	100027f3          	csrr	a5,sstatus
ffffffffc0204912:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204914:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204916:	e7c1                	bnez	a5,ffffffffc020499e <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204918:	6c70                	ld	a2,216(s0)
ffffffffc020491a:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020491c:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204920:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204922:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204924:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204926:	6470                	ld	a2,200(s0)
ffffffffc0204928:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020492a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020492c:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc020492e:	c319                	beqz	a4,ffffffffc0204934 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204930:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204932:	7c7c                	ld	a5,248(s0)
ffffffffc0204934:	c3b5                	beqz	a5,ffffffffc0204998 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204936:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020493a:	000b0717          	auipc	a4,0xb0
ffffffffc020493e:	72e70713          	addi	a4,a4,1838 # ffffffffc02b5068 <nr_process>
ffffffffc0204942:	431c                	lw	a5,0(a4)
ffffffffc0204944:	37fd                	addiw	a5,a5,-1
ffffffffc0204946:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204948:	e5a9                	bnez	a1,ffffffffc0204992 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020494a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020494c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204950:	04f6ee63          	bltu	a3,a5,ffffffffc02049ac <do_wait.part.0+0x18a>
ffffffffc0204954:	000b0797          	auipc	a5,0xb0
ffffffffc0204958:	6e47b783          	ld	a5,1764(a5) # ffffffffc02b5038 <va_pa_offset>
ffffffffc020495c:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020495e:	82b1                	srli	a3,a3,0xc
ffffffffc0204960:	000b0797          	auipc	a5,0xb0
ffffffffc0204964:	6c07b783          	ld	a5,1728(a5) # ffffffffc02b5020 <npage>
ffffffffc0204968:	06f6fa63          	bgeu	a3,a5,ffffffffc02049dc <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020496c:	00003517          	auipc	a0,0x3
ffffffffc0204970:	36453503          	ld	a0,868(a0) # ffffffffc0207cd0 <nbase>
ffffffffc0204974:	8e89                	sub	a3,a3,a0
ffffffffc0204976:	069a                	slli	a3,a3,0x6
ffffffffc0204978:	000b0517          	auipc	a0,0xb0
ffffffffc020497c:	6b053503          	ld	a0,1712(a0) # ffffffffc02b5028 <pages>
ffffffffc0204980:	9536                	add	a0,a0,a3
ffffffffc0204982:	4589                	li	a1,2
ffffffffc0204984:	dd6fd0ef          	jal	ra,ffffffffc0201f5a <free_pages>
    kfree(proc);
ffffffffc0204988:	8522                	mv	a0,s0
ffffffffc020498a:	c64fd0ef          	jal	ra,ffffffffc0201dee <kfree>
    return 0;
ffffffffc020498e:	4501                	li	a0,0
ffffffffc0204990:	bde5                	j	ffffffffc0204888 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204992:	81cfc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204996:	bf55                	j	ffffffffc020494a <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204998:	701c                	ld	a5,32(s0)
ffffffffc020499a:	fbf8                	sd	a4,240(a5)
ffffffffc020499c:	bf79                	j	ffffffffc020493a <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020499e:	816fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02049a2:	4585                	li	a1,1
ffffffffc02049a4:	bf95                	j	ffffffffc0204918 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02049a6:	f2840413          	addi	s0,s0,-216
ffffffffc02049aa:	b781                	j	ffffffffc02048ea <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02049ac:	00002617          	auipc	a2,0x2
ffffffffc02049b0:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc02049b4:	07700593          	li	a1,119
ffffffffc02049b8:	00002517          	auipc	a0,0x2
ffffffffc02049bc:	ed050513          	addi	a0,a0,-304 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc02049c0:	acffb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02049c4:	00003617          	auipc	a2,0x3
ffffffffc02049c8:	af460613          	addi	a2,a2,-1292 # ffffffffc02074b8 <default_pmm_manager+0xc90>
ffffffffc02049cc:	36700593          	li	a1,871
ffffffffc02049d0:	00003517          	auipc	a0,0x3
ffffffffc02049d4:	a6850513          	addi	a0,a0,-1432 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc02049d8:	ab7fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02049dc:	00002617          	auipc	a2,0x2
ffffffffc02049e0:	f5460613          	addi	a2,a2,-172 # ffffffffc0206930 <default_pmm_manager+0x108>
ffffffffc02049e4:	06900593          	li	a1,105
ffffffffc02049e8:	00002517          	auipc	a0,0x2
ffffffffc02049ec:	ea050513          	addi	a0,a0,-352 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc02049f0:	a9ffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049f4 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02049f4:	1141                	addi	sp,sp,-16
ffffffffc02049f6:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02049f8:	da2fd0ef          	jal	ra,ffffffffc0201f9a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02049fc:	b3efd0ef          	jal	ra,ffffffffc0201d3a <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204a00:	4601                	li	a2,0
ffffffffc0204a02:	4581                	li	a1,0
ffffffffc0204a04:	fffff517          	auipc	a0,0xfffff
ffffffffc0204a08:	75c50513          	addi	a0,a0,1884 # ffffffffc0204160 <user_main>
ffffffffc0204a0c:	c7dff0ef          	jal	ra,ffffffffc0204688 <kernel_thread>
    if (pid <= 0)
ffffffffc0204a10:	00a04563          	bgtz	a0,ffffffffc0204a1a <init_main+0x26>
ffffffffc0204a14:	a071                	j	ffffffffc0204aa0 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204a16:	17d000ef          	jal	ra,ffffffffc0205392 <schedule>
    if (code_store != NULL)
ffffffffc0204a1a:	4581                	li	a1,0
ffffffffc0204a1c:	4501                	li	a0,0
ffffffffc0204a1e:	e05ff0ef          	jal	ra,ffffffffc0204822 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204a22:	d975                	beqz	a0,ffffffffc0204a16 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204a24:	00003517          	auipc	a0,0x3
ffffffffc0204a28:	ad450513          	addi	a0,a0,-1324 # ffffffffc02074f8 <default_pmm_manager+0xcd0>
ffffffffc0204a2c:	f68fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204a30:	000b0797          	auipc	a5,0xb0
ffffffffc0204a34:	6307b783          	ld	a5,1584(a5) # ffffffffc02b5060 <initproc>
ffffffffc0204a38:	7bf8                	ld	a4,240(a5)
ffffffffc0204a3a:	e339                	bnez	a4,ffffffffc0204a80 <init_main+0x8c>
ffffffffc0204a3c:	7ff8                	ld	a4,248(a5)
ffffffffc0204a3e:	e329                	bnez	a4,ffffffffc0204a80 <init_main+0x8c>
ffffffffc0204a40:	1007b703          	ld	a4,256(a5)
ffffffffc0204a44:	ef15                	bnez	a4,ffffffffc0204a80 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204a46:	000b0697          	auipc	a3,0xb0
ffffffffc0204a4a:	6226a683          	lw	a3,1570(a3) # ffffffffc02b5068 <nr_process>
ffffffffc0204a4e:	4709                	li	a4,2
ffffffffc0204a50:	0ae69463          	bne	a3,a4,ffffffffc0204af8 <init_main+0x104>
    return listelm->next;
ffffffffc0204a54:	000b0697          	auipc	a3,0xb0
ffffffffc0204a58:	57c68693          	addi	a3,a3,1404 # ffffffffc02b4fd0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204a5c:	6698                	ld	a4,8(a3)
ffffffffc0204a5e:	0c878793          	addi	a5,a5,200
ffffffffc0204a62:	06f71b63          	bne	a4,a5,ffffffffc0204ad8 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204a66:	629c                	ld	a5,0(a3)
ffffffffc0204a68:	04f71863          	bne	a4,a5,ffffffffc0204ab8 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204a6c:	00003517          	auipc	a0,0x3
ffffffffc0204a70:	b7450513          	addi	a0,a0,-1164 # ffffffffc02075e0 <default_pmm_manager+0xdb8>
ffffffffc0204a74:	f20fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204a78:	60a2                	ld	ra,8(sp)
ffffffffc0204a7a:	4501                	li	a0,0
ffffffffc0204a7c:	0141                	addi	sp,sp,16
ffffffffc0204a7e:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204a80:	00003697          	auipc	a3,0x3
ffffffffc0204a84:	aa068693          	addi	a3,a3,-1376 # ffffffffc0207520 <default_pmm_manager+0xcf8>
ffffffffc0204a88:	00001617          	auipc	a2,0x1
ffffffffc0204a8c:	7a860613          	addi	a2,a2,1960 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204a90:	3d500593          	li	a1,981
ffffffffc0204a94:	00003517          	auipc	a0,0x3
ffffffffc0204a98:	9a450513          	addi	a0,a0,-1628 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204a9c:	9f3fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204aa0:	00003617          	auipc	a2,0x3
ffffffffc0204aa4:	a3860613          	addi	a2,a2,-1480 # ffffffffc02074d8 <default_pmm_manager+0xcb0>
ffffffffc0204aa8:	3cc00593          	li	a1,972
ffffffffc0204aac:	00003517          	auipc	a0,0x3
ffffffffc0204ab0:	98c50513          	addi	a0,a0,-1652 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204ab4:	9dbfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204ab8:	00003697          	auipc	a3,0x3
ffffffffc0204abc:	af868693          	addi	a3,a3,-1288 # ffffffffc02075b0 <default_pmm_manager+0xd88>
ffffffffc0204ac0:	00001617          	auipc	a2,0x1
ffffffffc0204ac4:	77060613          	addi	a2,a2,1904 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204ac8:	3d800593          	li	a1,984
ffffffffc0204acc:	00003517          	auipc	a0,0x3
ffffffffc0204ad0:	96c50513          	addi	a0,a0,-1684 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204ad4:	9bbfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204ad8:	00003697          	auipc	a3,0x3
ffffffffc0204adc:	aa868693          	addi	a3,a3,-1368 # ffffffffc0207580 <default_pmm_manager+0xd58>
ffffffffc0204ae0:	00001617          	auipc	a2,0x1
ffffffffc0204ae4:	75060613          	addi	a2,a2,1872 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204ae8:	3d700593          	li	a1,983
ffffffffc0204aec:	00003517          	auipc	a0,0x3
ffffffffc0204af0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204af4:	99bfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204af8:	00003697          	auipc	a3,0x3
ffffffffc0204afc:	a7868693          	addi	a3,a3,-1416 # ffffffffc0207570 <default_pmm_manager+0xd48>
ffffffffc0204b00:	00001617          	auipc	a2,0x1
ffffffffc0204b04:	73060613          	addi	a2,a2,1840 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204b08:	3d600593          	li	a1,982
ffffffffc0204b0c:	00003517          	auipc	a0,0x3
ffffffffc0204b10:	92c50513          	addi	a0,a0,-1748 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204b14:	97bfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204b18 <do_execve>:
{
ffffffffc0204b18:	7171                	addi	sp,sp,-176
ffffffffc0204b1a:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204b1c:	000b0d97          	auipc	s11,0xb0
ffffffffc0204b20:	534d8d93          	addi	s11,s11,1332 # ffffffffc02b5050 <current>
ffffffffc0204b24:	000db783          	ld	a5,0(s11)
{
ffffffffc0204b28:	e54e                	sd	s3,136(sp)
ffffffffc0204b2a:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204b2c:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204b30:	e94a                	sd	s2,144(sp)
ffffffffc0204b32:	f4de                	sd	s7,104(sp)
ffffffffc0204b34:	892a                	mv	s2,a0
ffffffffc0204b36:	8bb2                	mv	s7,a2
ffffffffc0204b38:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204b3a:	862e                	mv	a2,a1
ffffffffc0204b3c:	4681                	li	a3,0
ffffffffc0204b3e:	85aa                	mv	a1,a0
ffffffffc0204b40:	854e                	mv	a0,s3
{
ffffffffc0204b42:	f506                	sd	ra,168(sp)
ffffffffc0204b44:	f122                	sd	s0,160(sp)
ffffffffc0204b46:	e152                	sd	s4,128(sp)
ffffffffc0204b48:	fcd6                	sd	s5,120(sp)
ffffffffc0204b4a:	f8da                	sd	s6,112(sp)
ffffffffc0204b4c:	f0e2                	sd	s8,96(sp)
ffffffffc0204b4e:	ece6                	sd	s9,88(sp)
ffffffffc0204b50:	e8ea                	sd	s10,80(sp)
ffffffffc0204b52:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204b54:	a92ff0ef          	jal	ra,ffffffffc0203de6 <user_mem_check>
ffffffffc0204b58:	40050a63          	beqz	a0,ffffffffc0204f6c <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204b5c:	4641                	li	a2,16
ffffffffc0204b5e:	4581                	li	a1,0
ffffffffc0204b60:	1808                	addi	a0,sp,48
ffffffffc0204b62:	643000ef          	jal	ra,ffffffffc02059a4 <memset>
    memcpy(local_name, name, len);
ffffffffc0204b66:	47bd                	li	a5,15
ffffffffc0204b68:	8626                	mv	a2,s1
ffffffffc0204b6a:	1e97e263          	bltu	a5,s1,ffffffffc0204d4e <do_execve+0x236>
ffffffffc0204b6e:	85ca                	mv	a1,s2
ffffffffc0204b70:	1808                	addi	a0,sp,48
ffffffffc0204b72:	645000ef          	jal	ra,ffffffffc02059b6 <memcpy>
    if (mm != NULL)
ffffffffc0204b76:	1e098363          	beqz	s3,ffffffffc0204d5c <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204b7a:	00002517          	auipc	a0,0x2
ffffffffc0204b7e:	4de50513          	addi	a0,a0,1246 # ffffffffc0207058 <default_pmm_manager+0x830>
ffffffffc0204b82:	e4afb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204b86:	000b0797          	auipc	a5,0xb0
ffffffffc0204b8a:	48a7b783          	ld	a5,1162(a5) # ffffffffc02b5010 <boot_pgdir_pa>
ffffffffc0204b8e:	577d                	li	a4,-1
ffffffffc0204b90:	177e                	slli	a4,a4,0x3f
ffffffffc0204b92:	83b1                	srli	a5,a5,0xc
ffffffffc0204b94:	8fd9                	or	a5,a5,a4
ffffffffc0204b96:	18079073          	csrw	satp,a5
ffffffffc0204b9a:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b80>
ffffffffc0204b9e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204ba2:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204ba6:	2c070463          	beqz	a4,ffffffffc0204e6e <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204baa:	000db783          	ld	a5,0(s11)
ffffffffc0204bae:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204bb2:	bbffe0ef          	jal	ra,ffffffffc0203770 <mm_create>
ffffffffc0204bb6:	84aa                	mv	s1,a0
ffffffffc0204bb8:	1c050d63          	beqz	a0,ffffffffc0204d92 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc0204bbc:	4505                	li	a0,1
ffffffffc0204bbe:	b5efd0ef          	jal	ra,ffffffffc0201f1c <alloc_pages>
ffffffffc0204bc2:	3a050963          	beqz	a0,ffffffffc0204f74 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc0204bc6:	000b0c97          	auipc	s9,0xb0
ffffffffc0204bca:	462c8c93          	addi	s9,s9,1122 # ffffffffc02b5028 <pages>
ffffffffc0204bce:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0204bd2:	000b0c17          	auipc	s8,0xb0
ffffffffc0204bd6:	44ec0c13          	addi	s8,s8,1102 # ffffffffc02b5020 <npage>
    return page - pages + nbase;
ffffffffc0204bda:	00003717          	auipc	a4,0x3
ffffffffc0204bde:	0f673703          	ld	a4,246(a4) # ffffffffc0207cd0 <nbase>
ffffffffc0204be2:	40d506b3          	sub	a3,a0,a3
ffffffffc0204be6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204be8:	5afd                	li	s5,-1
ffffffffc0204bea:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204bee:	96ba                	add	a3,a3,a4
ffffffffc0204bf0:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204bf2:	00cad713          	srli	a4,s5,0xc
ffffffffc0204bf6:	ec3a                	sd	a4,24(sp)
ffffffffc0204bf8:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bfa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bfc:	38f77063          	bgeu	a4,a5,ffffffffc0204f7c <do_execve+0x464>
ffffffffc0204c00:	000b0b17          	auipc	s6,0xb0
ffffffffc0204c04:	438b0b13          	addi	s6,s6,1080 # ffffffffc02b5038 <va_pa_offset>
ffffffffc0204c08:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204c0c:	6605                	lui	a2,0x1
ffffffffc0204c0e:	000b0597          	auipc	a1,0xb0
ffffffffc0204c12:	40a5b583          	ld	a1,1034(a1) # ffffffffc02b5018 <boot_pgdir_va>
ffffffffc0204c16:	9936                	add	s2,s2,a3
ffffffffc0204c18:	854a                	mv	a0,s2
ffffffffc0204c1a:	59d000ef          	jal	ra,ffffffffc02059b6 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204c1e:	7782                	ld	a5,32(sp)
ffffffffc0204c20:	4398                	lw	a4,0(a5)
ffffffffc0204c22:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204c26:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204c2a:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9457>
ffffffffc0204c2e:	14f71863          	bne	a4,a5,ffffffffc0204d7e <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204c32:	7682                	ld	a3,32(sp)
ffffffffc0204c34:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204c38:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204c3c:	00371793          	slli	a5,a4,0x3
ffffffffc0204c40:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204c42:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204c44:	078e                	slli	a5,a5,0x3
ffffffffc0204c46:	97ce                	add	a5,a5,s3
ffffffffc0204c48:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204c4a:	00f9fc63          	bgeu	s3,a5,ffffffffc0204c62 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204c4e:	0009a783          	lw	a5,0(s3)
ffffffffc0204c52:	4705                	li	a4,1
ffffffffc0204c54:	14e78163          	beq	a5,a4,ffffffffc0204d96 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204c58:	77a2                	ld	a5,40(sp)
ffffffffc0204c5a:	03898993          	addi	s3,s3,56
ffffffffc0204c5e:	fef9e8e3          	bltu	s3,a5,ffffffffc0204c4e <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204c62:	4701                	li	a4,0
ffffffffc0204c64:	46ad                	li	a3,11
ffffffffc0204c66:	00100637          	lui	a2,0x100
ffffffffc0204c6a:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204c6e:	8526                	mv	a0,s1
ffffffffc0204c70:	c93fe0ef          	jal	ra,ffffffffc0203902 <mm_map>
ffffffffc0204c74:	892a                	mv	s2,a0
ffffffffc0204c76:	1e051263          	bnez	a0,ffffffffc0204e5a <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204c7a:	6c88                	ld	a0,24(s1)
ffffffffc0204c7c:	467d                	li	a2,31
ffffffffc0204c7e:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204c82:	a09fe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204c86:	38050363          	beqz	a0,ffffffffc020500c <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c8a:	6c88                	ld	a0,24(s1)
ffffffffc0204c8c:	467d                	li	a2,31
ffffffffc0204c8e:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204c92:	9f9fe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204c96:	34050b63          	beqz	a0,ffffffffc0204fec <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204c9a:	6c88                	ld	a0,24(s1)
ffffffffc0204c9c:	467d                	li	a2,31
ffffffffc0204c9e:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204ca2:	9e9fe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204ca6:	32050363          	beqz	a0,ffffffffc0204fcc <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204caa:	6c88                	ld	a0,24(s1)
ffffffffc0204cac:	467d                	li	a2,31
ffffffffc0204cae:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204cb2:	9d9fe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204cb6:	2e050b63          	beqz	a0,ffffffffc0204fac <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204cba:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204cbc:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204cc0:	6c94                	ld	a3,24(s1)
ffffffffc0204cc2:	2785                	addiw	a5,a5,1
ffffffffc0204cc4:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204cc6:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204cc8:	c02007b7          	lui	a5,0xc0200
ffffffffc0204ccc:	2cf6e463          	bltu	a3,a5,ffffffffc0204f94 <do_execve+0x47c>
ffffffffc0204cd0:	000b3783          	ld	a5,0(s6)
ffffffffc0204cd4:	577d                	li	a4,-1
ffffffffc0204cd6:	177e                	slli	a4,a4,0x3f
ffffffffc0204cd8:	8e9d                	sub	a3,a3,a5
ffffffffc0204cda:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204cde:	f654                	sd	a3,168(a2)
ffffffffc0204ce0:	8fd9                	or	a5,a5,a4
ffffffffc0204ce2:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204ce6:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204ce8:	4581                	li	a1,0
ffffffffc0204cea:	12000613          	li	a2,288
ffffffffc0204cee:	8526                	mv	a0,s1
ffffffffc0204cf0:	4b5000ef          	jal	ra,ffffffffc02059a4 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204cf4:	7782                	ld	a5,32(sp)
ffffffffc0204cf6:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204cf8:	4785                	li	a5,1
ffffffffc0204cfa:	07fe                	slli	a5,a5,0x1f
ffffffffc0204cfc:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;
ffffffffc0204cfe:	10e4b423          	sd	a4,264(s1)
    tf->status = read_csr(sstatus);
ffffffffc0204d02:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d06:	000db403          	ld	s0,0(s11)
    tf->status &= ~SSTATUS_SPP; // 确保返回后是用户态 (SPP=0)
ffffffffc0204d0a:	eff7f793          	andi	a5,a5,-257
    tf->status |= SSTATUS_SPIE; // 确保返回后中断是使能的 (SPIE=1)
ffffffffc0204d0e:	0207e793          	ori	a5,a5,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d12:	0b440413          	addi	s0,s0,180
ffffffffc0204d16:	4641                	li	a2,16
ffffffffc0204d18:	4581                	li	a1,0
    tf->status |= SSTATUS_SPIE; // 确保返回后中断是使能的 (SPIE=1)
ffffffffc0204d1a:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d1e:	8522                	mv	a0,s0
ffffffffc0204d20:	485000ef          	jal	ra,ffffffffc02059a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204d24:	463d                	li	a2,15
ffffffffc0204d26:	180c                	addi	a1,sp,48
ffffffffc0204d28:	8522                	mv	a0,s0
ffffffffc0204d2a:	48d000ef          	jal	ra,ffffffffc02059b6 <memcpy>
}
ffffffffc0204d2e:	70aa                	ld	ra,168(sp)
ffffffffc0204d30:	740a                	ld	s0,160(sp)
ffffffffc0204d32:	64ea                	ld	s1,152(sp)
ffffffffc0204d34:	69aa                	ld	s3,136(sp)
ffffffffc0204d36:	6a0a                	ld	s4,128(sp)
ffffffffc0204d38:	7ae6                	ld	s5,120(sp)
ffffffffc0204d3a:	7b46                	ld	s6,112(sp)
ffffffffc0204d3c:	7ba6                	ld	s7,104(sp)
ffffffffc0204d3e:	7c06                	ld	s8,96(sp)
ffffffffc0204d40:	6ce6                	ld	s9,88(sp)
ffffffffc0204d42:	6d46                	ld	s10,80(sp)
ffffffffc0204d44:	6da6                	ld	s11,72(sp)
ffffffffc0204d46:	854a                	mv	a0,s2
ffffffffc0204d48:	694a                	ld	s2,144(sp)
ffffffffc0204d4a:	614d                	addi	sp,sp,176
ffffffffc0204d4c:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204d4e:	463d                	li	a2,15
ffffffffc0204d50:	85ca                	mv	a1,s2
ffffffffc0204d52:	1808                	addi	a0,sp,48
ffffffffc0204d54:	463000ef          	jal	ra,ffffffffc02059b6 <memcpy>
    if (mm != NULL)
ffffffffc0204d58:	e20991e3          	bnez	s3,ffffffffc0204b7a <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204d5c:	000db783          	ld	a5,0(s11)
ffffffffc0204d60:	779c                	ld	a5,40(a5)
ffffffffc0204d62:	e40788e3          	beqz	a5,ffffffffc0204bb2 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204d66:	00003617          	auipc	a2,0x3
ffffffffc0204d6a:	89a60613          	addi	a2,a2,-1894 # ffffffffc0207600 <default_pmm_manager+0xdd8>
ffffffffc0204d6e:	24900593          	li	a1,585
ffffffffc0204d72:	00002517          	auipc	a0,0x2
ffffffffc0204d76:	6c650513          	addi	a0,a0,1734 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204d7a:	f14fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204d7e:	8526                	mv	a0,s1
ffffffffc0204d80:	c5eff0ef          	jal	ra,ffffffffc02041de <put_pgdir>
    mm_destroy(mm);
ffffffffc0204d84:	8526                	mv	a0,s1
ffffffffc0204d86:	b2bfe0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204d8a:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0204d8c:	854a                	mv	a0,s2
ffffffffc0204d8e:	94bff0ef          	jal	ra,ffffffffc02046d8 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204d92:	5971                	li	s2,-4
ffffffffc0204d94:	bfe5                	j	ffffffffc0204d8c <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204d96:	0289b603          	ld	a2,40(s3)
ffffffffc0204d9a:	0209b783          	ld	a5,32(s3)
ffffffffc0204d9e:	1cf66d63          	bltu	a2,a5,ffffffffc0204f78 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204da2:	0049a783          	lw	a5,4(s3)
ffffffffc0204da6:	0017f693          	andi	a3,a5,1
ffffffffc0204daa:	c291                	beqz	a3,ffffffffc0204dae <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204dac:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204dae:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204db2:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204db4:	e779                	bnez	a4,ffffffffc0204e82 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204db6:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204db8:	c781                	beqz	a5,ffffffffc0204dc0 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204dba:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204dbe:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204dc0:	0026f793          	andi	a5,a3,2
ffffffffc0204dc4:	e3f1                	bnez	a5,ffffffffc0204e88 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204dc6:	0046f793          	andi	a5,a3,4
ffffffffc0204dca:	c399                	beqz	a5,ffffffffc0204dd0 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204dcc:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204dd0:	0109b583          	ld	a1,16(s3)
ffffffffc0204dd4:	4701                	li	a4,0
ffffffffc0204dd6:	8526                	mv	a0,s1
ffffffffc0204dd8:	b2bfe0ef          	jal	ra,ffffffffc0203902 <mm_map>
ffffffffc0204ddc:	892a                	mv	s2,a0
ffffffffc0204dde:	ed35                	bnez	a0,ffffffffc0204e5a <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204de0:	0109bb83          	ld	s7,16(s3)
ffffffffc0204de4:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204de6:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204dea:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204dee:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204df2:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204df4:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204df6:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204df8:	054be963          	bltu	s7,s4,ffffffffc0204e4a <do_execve+0x332>
ffffffffc0204dfc:	aa95                	j	ffffffffc0204f70 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204dfe:	6785                	lui	a5,0x1
ffffffffc0204e00:	415b8533          	sub	a0,s7,s5
ffffffffc0204e04:	9abe                	add	s5,s5,a5
ffffffffc0204e06:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204e0a:	015a7463          	bgeu	s4,s5,ffffffffc0204e12 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204e0e:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204e12:	000cb683          	ld	a3,0(s9)
ffffffffc0204e16:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204e18:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204e1c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204e20:	8699                	srai	a3,a3,0x6
ffffffffc0204e22:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e24:	67e2                	ld	a5,24(sp)
ffffffffc0204e26:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e2a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e2c:	14b87863          	bgeu	a6,a1,ffffffffc0204f7c <do_execve+0x464>
ffffffffc0204e30:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204e34:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204e36:	9bb2                	add	s7,s7,a2
ffffffffc0204e38:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204e3a:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204e3c:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204e3e:	379000ef          	jal	ra,ffffffffc02059b6 <memcpy>
            start += size, from += size;
ffffffffc0204e42:	6622                	ld	a2,8(sp)
ffffffffc0204e44:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204e46:	054bf363          	bgeu	s7,s4,ffffffffc0204e8c <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204e4a:	6c88                	ld	a0,24(s1)
ffffffffc0204e4c:	866a                	mv	a2,s10
ffffffffc0204e4e:	85d6                	mv	a1,s5
ffffffffc0204e50:	83bfe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204e54:	842a                	mv	s0,a0
ffffffffc0204e56:	f545                	bnez	a0,ffffffffc0204dfe <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204e58:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc0204e5a:	8526                	mv	a0,s1
ffffffffc0204e5c:	bf1fe0ef          	jal	ra,ffffffffc0203a4c <exit_mmap>
    put_pgdir(mm);
ffffffffc0204e60:	8526                	mv	a0,s1
ffffffffc0204e62:	b7cff0ef          	jal	ra,ffffffffc02041de <put_pgdir>
    mm_destroy(mm);
ffffffffc0204e66:	8526                	mv	a0,s1
ffffffffc0204e68:	a49fe0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>
    return ret;
ffffffffc0204e6c:	b705                	j	ffffffffc0204d8c <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204e6e:	854e                	mv	a0,s3
ffffffffc0204e70:	bddfe0ef          	jal	ra,ffffffffc0203a4c <exit_mmap>
            put_pgdir(mm);
ffffffffc0204e74:	854e                	mv	a0,s3
ffffffffc0204e76:	b68ff0ef          	jal	ra,ffffffffc02041de <put_pgdir>
            mm_destroy(mm);
ffffffffc0204e7a:	854e                	mv	a0,s3
ffffffffc0204e7c:	a35fe0ef          	jal	ra,ffffffffc02038b0 <mm_destroy>
ffffffffc0204e80:	b32d                	j	ffffffffc0204baa <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204e82:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204e86:	fb95                	bnez	a5,ffffffffc0204dba <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204e88:	4d5d                	li	s10,23
ffffffffc0204e8a:	bf35                	j	ffffffffc0204dc6 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204e8c:	0109b683          	ld	a3,16(s3)
ffffffffc0204e90:	0289b903          	ld	s2,40(s3)
ffffffffc0204e94:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204e96:	075bfd63          	bgeu	s7,s5,ffffffffc0204f10 <do_execve+0x3f8>
            if (start == end)
ffffffffc0204e9a:	db790fe3          	beq	s2,s7,ffffffffc0204c58 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e9e:	6785                	lui	a5,0x1
ffffffffc0204ea0:	00fb8533          	add	a0,s7,a5
ffffffffc0204ea4:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204ea8:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204eac:	0b597d63          	bgeu	s2,s5,ffffffffc0204f66 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204eb0:	000cb683          	ld	a3,0(s9)
ffffffffc0204eb4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204eb6:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204eba:	40d406b3          	sub	a3,s0,a3
ffffffffc0204ebe:	8699                	srai	a3,a3,0x6
ffffffffc0204ec0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ec2:	67e2                	ld	a5,24(sp)
ffffffffc0204ec4:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ec8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204eca:	0ac5f963          	bgeu	a1,a2,ffffffffc0204f7c <do_execve+0x464>
ffffffffc0204ece:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ed2:	8652                	mv	a2,s4
ffffffffc0204ed4:	4581                	li	a1,0
ffffffffc0204ed6:	96c2                	add	a3,a3,a6
ffffffffc0204ed8:	9536                	add	a0,a0,a3
ffffffffc0204eda:	2cb000ef          	jal	ra,ffffffffc02059a4 <memset>
            start += size;
ffffffffc0204ede:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204ee2:	03597463          	bgeu	s2,s5,ffffffffc0204f0a <do_execve+0x3f2>
ffffffffc0204ee6:	d6e909e3          	beq	s2,a4,ffffffffc0204c58 <do_execve+0x140>
ffffffffc0204eea:	00002697          	auipc	a3,0x2
ffffffffc0204eee:	73e68693          	addi	a3,a3,1854 # ffffffffc0207628 <default_pmm_manager+0xe00>
ffffffffc0204ef2:	00001617          	auipc	a2,0x1
ffffffffc0204ef6:	33e60613          	addi	a2,a2,830 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204efa:	2b200593          	li	a1,690
ffffffffc0204efe:	00002517          	auipc	a0,0x2
ffffffffc0204f02:	53a50513          	addi	a0,a0,1338 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204f06:	d88fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204f0a:	ff5710e3          	bne	a4,s5,ffffffffc0204eea <do_execve+0x3d2>
ffffffffc0204f0e:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204f10:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204c58 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204f14:	6c88                	ld	a0,24(s1)
ffffffffc0204f16:	866a                	mv	a2,s10
ffffffffc0204f18:	85d6                	mv	a1,s5
ffffffffc0204f1a:	f70fe0ef          	jal	ra,ffffffffc020368a <pgdir_alloc_page>
ffffffffc0204f1e:	842a                	mv	s0,a0
ffffffffc0204f20:	dd05                	beqz	a0,ffffffffc0204e58 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204f22:	6785                	lui	a5,0x1
ffffffffc0204f24:	415b8533          	sub	a0,s7,s5
ffffffffc0204f28:	9abe                	add	s5,s5,a5
ffffffffc0204f2a:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204f2e:	01597463          	bgeu	s2,s5,ffffffffc0204f36 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204f32:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204f36:	000cb683          	ld	a3,0(s9)
ffffffffc0204f3a:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204f3c:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204f40:	40d406b3          	sub	a3,s0,a3
ffffffffc0204f44:	8699                	srai	a3,a3,0x6
ffffffffc0204f46:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204f48:	67e2                	ld	a5,24(sp)
ffffffffc0204f4a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204f4e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204f50:	02b87663          	bgeu	a6,a1,ffffffffc0204f7c <do_execve+0x464>
ffffffffc0204f54:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204f58:	4581                	li	a1,0
            start += size;
ffffffffc0204f5a:	9bb2                	add	s7,s7,a2
ffffffffc0204f5c:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204f5e:	9536                	add	a0,a0,a3
ffffffffc0204f60:	245000ef          	jal	ra,ffffffffc02059a4 <memset>
ffffffffc0204f64:	b775                	j	ffffffffc0204f10 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204f66:	417a8a33          	sub	s4,s5,s7
ffffffffc0204f6a:	b799                	j	ffffffffc0204eb0 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204f6c:	5975                	li	s2,-3
ffffffffc0204f6e:	b3c1                	j	ffffffffc0204d2e <do_execve+0x216>
        while (start < end)
ffffffffc0204f70:	86de                	mv	a3,s7
ffffffffc0204f72:	bf39                	j	ffffffffc0204e90 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204f74:	5971                	li	s2,-4
ffffffffc0204f76:	bdc5                	j	ffffffffc0204e66 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204f78:	5961                	li	s2,-8
ffffffffc0204f7a:	b5c5                	j	ffffffffc0204e5a <do_execve+0x342>
ffffffffc0204f7c:	00002617          	auipc	a2,0x2
ffffffffc0204f80:	8e460613          	addi	a2,a2,-1820 # ffffffffc0206860 <default_pmm_manager+0x38>
ffffffffc0204f84:	07100593          	li	a1,113
ffffffffc0204f88:	00002517          	auipc	a0,0x2
ffffffffc0204f8c:	90050513          	addi	a0,a0,-1792 # ffffffffc0206888 <default_pmm_manager+0x60>
ffffffffc0204f90:	cfefb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204f94:	00002617          	auipc	a2,0x2
ffffffffc0204f98:	97460613          	addi	a2,a2,-1676 # ffffffffc0206908 <default_pmm_manager+0xe0>
ffffffffc0204f9c:	2d100593          	li	a1,721
ffffffffc0204fa0:	00002517          	auipc	a0,0x2
ffffffffc0204fa4:	49850513          	addi	a0,a0,1176 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204fa8:	ce6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204fac:	00002697          	auipc	a3,0x2
ffffffffc0204fb0:	79468693          	addi	a3,a3,1940 # ffffffffc0207740 <default_pmm_manager+0xf18>
ffffffffc0204fb4:	00001617          	auipc	a2,0x1
ffffffffc0204fb8:	27c60613          	addi	a2,a2,636 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204fbc:	2cc00593          	li	a1,716
ffffffffc0204fc0:	00002517          	auipc	a0,0x2
ffffffffc0204fc4:	47850513          	addi	a0,a0,1144 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204fc8:	cc6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204fcc:	00002697          	auipc	a3,0x2
ffffffffc0204fd0:	72c68693          	addi	a3,a3,1836 # ffffffffc02076f8 <default_pmm_manager+0xed0>
ffffffffc0204fd4:	00001617          	auipc	a2,0x1
ffffffffc0204fd8:	25c60613          	addi	a2,a2,604 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204fdc:	2cb00593          	li	a1,715
ffffffffc0204fe0:	00002517          	auipc	a0,0x2
ffffffffc0204fe4:	45850513          	addi	a0,a0,1112 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0204fe8:	ca6fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204fec:	00002697          	auipc	a3,0x2
ffffffffc0204ff0:	6c468693          	addi	a3,a3,1732 # ffffffffc02076b0 <default_pmm_manager+0xe88>
ffffffffc0204ff4:	00001617          	auipc	a2,0x1
ffffffffc0204ff8:	23c60613          	addi	a2,a2,572 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0204ffc:	2ca00593          	li	a1,714
ffffffffc0205000:	00002517          	auipc	a0,0x2
ffffffffc0205004:	43850513          	addi	a0,a0,1080 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0205008:	c86fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020500c:	00002697          	auipc	a3,0x2
ffffffffc0205010:	65c68693          	addi	a3,a3,1628 # ffffffffc0207668 <default_pmm_manager+0xe40>
ffffffffc0205014:	00001617          	auipc	a2,0x1
ffffffffc0205018:	21c60613          	addi	a2,a2,540 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020501c:	2c900593          	li	a1,713
ffffffffc0205020:	00002517          	auipc	a0,0x2
ffffffffc0205024:	41850513          	addi	a0,a0,1048 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0205028:	c66fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020502c <do_yield>:
    current->need_resched = 1;
ffffffffc020502c:	000b0797          	auipc	a5,0xb0
ffffffffc0205030:	0247b783          	ld	a5,36(a5) # ffffffffc02b5050 <current>
ffffffffc0205034:	4705                	li	a4,1
ffffffffc0205036:	ef98                	sd	a4,24(a5)
}
ffffffffc0205038:	4501                	li	a0,0
ffffffffc020503a:	8082                	ret

ffffffffc020503c <do_wait>:
{
ffffffffc020503c:	1101                	addi	sp,sp,-32
ffffffffc020503e:	e822                	sd	s0,16(sp)
ffffffffc0205040:	e426                	sd	s1,8(sp)
ffffffffc0205042:	ec06                	sd	ra,24(sp)
ffffffffc0205044:	842e                	mv	s0,a1
ffffffffc0205046:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0205048:	c999                	beqz	a1,ffffffffc020505e <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc020504a:	000b0797          	auipc	a5,0xb0
ffffffffc020504e:	0067b783          	ld	a5,6(a5) # ffffffffc02b5050 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205052:	7788                	ld	a0,40(a5)
ffffffffc0205054:	4685                	li	a3,1
ffffffffc0205056:	4611                	li	a2,4
ffffffffc0205058:	d8ffe0ef          	jal	ra,ffffffffc0203de6 <user_mem_check>
ffffffffc020505c:	c909                	beqz	a0,ffffffffc020506e <do_wait+0x32>
ffffffffc020505e:	85a2                	mv	a1,s0
}
ffffffffc0205060:	6442                	ld	s0,16(sp)
ffffffffc0205062:	60e2                	ld	ra,24(sp)
ffffffffc0205064:	8526                	mv	a0,s1
ffffffffc0205066:	64a2                	ld	s1,8(sp)
ffffffffc0205068:	6105                	addi	sp,sp,32
ffffffffc020506a:	fb8ff06f          	j	ffffffffc0204822 <do_wait.part.0>
ffffffffc020506e:	60e2                	ld	ra,24(sp)
ffffffffc0205070:	6442                	ld	s0,16(sp)
ffffffffc0205072:	64a2                	ld	s1,8(sp)
ffffffffc0205074:	5575                	li	a0,-3
ffffffffc0205076:	6105                	addi	sp,sp,32
ffffffffc0205078:	8082                	ret

ffffffffc020507a <do_kill>:
{
ffffffffc020507a:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc020507c:	6789                	lui	a5,0x2
{
ffffffffc020507e:	e406                	sd	ra,8(sp)
ffffffffc0205080:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0205082:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205086:	17f9                	addi	a5,a5,-2
ffffffffc0205088:	02e7e963          	bltu	a5,a4,ffffffffc02050ba <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020508c:	842a                	mv	s0,a0
ffffffffc020508e:	45a9                	li	a1,10
ffffffffc0205090:	2501                	sext.w	a0,a0
ffffffffc0205092:	46c000ef          	jal	ra,ffffffffc02054fe <hash32>
ffffffffc0205096:	02051793          	slli	a5,a0,0x20
ffffffffc020509a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020509e:	000ac797          	auipc	a5,0xac
ffffffffc02050a2:	f3278793          	addi	a5,a5,-206 # ffffffffc02b0fd0 <hash_list>
ffffffffc02050a6:	953e                	add	a0,a0,a5
ffffffffc02050a8:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02050aa:	a029                	j	ffffffffc02050b4 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc02050ac:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02050b0:	00870b63          	beq	a4,s0,ffffffffc02050c6 <do_kill+0x4c>
ffffffffc02050b4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050b6:	fef51be3          	bne	a0,a5,ffffffffc02050ac <do_kill+0x32>
    return -E_INVAL;
ffffffffc02050ba:	5475                	li	s0,-3
}
ffffffffc02050bc:	60a2                	ld	ra,8(sp)
ffffffffc02050be:	8522                	mv	a0,s0
ffffffffc02050c0:	6402                	ld	s0,0(sp)
ffffffffc02050c2:	0141                	addi	sp,sp,16
ffffffffc02050c4:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc02050c6:	fd87a703          	lw	a4,-40(a5)
ffffffffc02050ca:	00177693          	andi	a3,a4,1
ffffffffc02050ce:	e295                	bnez	a3,ffffffffc02050f2 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02050d0:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc02050d2:	00176713          	ori	a4,a4,1
ffffffffc02050d6:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc02050da:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02050dc:	fe06d0e3          	bgez	a3,ffffffffc02050bc <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc02050e0:	f2878513          	addi	a0,a5,-216
ffffffffc02050e4:	22e000ef          	jal	ra,ffffffffc0205312 <wakeup_proc>
}
ffffffffc02050e8:	60a2                	ld	ra,8(sp)
ffffffffc02050ea:	8522                	mv	a0,s0
ffffffffc02050ec:	6402                	ld	s0,0(sp)
ffffffffc02050ee:	0141                	addi	sp,sp,16
ffffffffc02050f0:	8082                	ret
        return -E_KILLED;
ffffffffc02050f2:	545d                	li	s0,-9
ffffffffc02050f4:	b7e1                	j	ffffffffc02050bc <do_kill+0x42>

ffffffffc02050f6 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02050f6:	1101                	addi	sp,sp,-32
ffffffffc02050f8:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc02050fa:	000b0797          	auipc	a5,0xb0
ffffffffc02050fe:	ed678793          	addi	a5,a5,-298 # ffffffffc02b4fd0 <proc_list>
ffffffffc0205102:	ec06                	sd	ra,24(sp)
ffffffffc0205104:	e822                	sd	s0,16(sp)
ffffffffc0205106:	e04a                	sd	s2,0(sp)
ffffffffc0205108:	000ac497          	auipc	s1,0xac
ffffffffc020510c:	ec848493          	addi	s1,s1,-312 # ffffffffc02b0fd0 <hash_list>
ffffffffc0205110:	e79c                	sd	a5,8(a5)
ffffffffc0205112:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205114:	000b0717          	auipc	a4,0xb0
ffffffffc0205118:	ebc70713          	addi	a4,a4,-324 # ffffffffc02b4fd0 <proc_list>
ffffffffc020511c:	87a6                	mv	a5,s1
ffffffffc020511e:	e79c                	sd	a5,8(a5)
ffffffffc0205120:	e39c                	sd	a5,0(a5)
ffffffffc0205122:	07c1                	addi	a5,a5,16
ffffffffc0205124:	fef71de3          	bne	a4,a5,ffffffffc020511e <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205128:	fa9fe0ef          	jal	ra,ffffffffc02040d0 <alloc_proc>
ffffffffc020512c:	000b0917          	auipc	s2,0xb0
ffffffffc0205130:	f2c90913          	addi	s2,s2,-212 # ffffffffc02b5058 <idleproc>
ffffffffc0205134:	00a93023          	sd	a0,0(s2)
ffffffffc0205138:	0e050f63          	beqz	a0,ffffffffc0205236 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020513c:	4789                	li	a5,2
ffffffffc020513e:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205140:	00003797          	auipc	a5,0x3
ffffffffc0205144:	ec078793          	addi	a5,a5,-320 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205148:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020514c:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc020514e:	4785                	li	a5,1
ffffffffc0205150:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205152:	4641                	li	a2,16
ffffffffc0205154:	4581                	li	a1,0
ffffffffc0205156:	8522                	mv	a0,s0
ffffffffc0205158:	04d000ef          	jal	ra,ffffffffc02059a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020515c:	463d                	li	a2,15
ffffffffc020515e:	00002597          	auipc	a1,0x2
ffffffffc0205162:	64258593          	addi	a1,a1,1602 # ffffffffc02077a0 <default_pmm_manager+0xf78>
ffffffffc0205166:	8522                	mv	a0,s0
ffffffffc0205168:	04f000ef          	jal	ra,ffffffffc02059b6 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020516c:	000b0717          	auipc	a4,0xb0
ffffffffc0205170:	efc70713          	addi	a4,a4,-260 # ffffffffc02b5068 <nr_process>
ffffffffc0205174:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205176:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020517a:	4601                	li	a2,0
    nr_process++;
ffffffffc020517c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020517e:	4581                	li	a1,0
ffffffffc0205180:	00000517          	auipc	a0,0x0
ffffffffc0205184:	87450513          	addi	a0,a0,-1932 # ffffffffc02049f4 <init_main>
    nr_process++;
ffffffffc0205188:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc020518a:	000b0797          	auipc	a5,0xb0
ffffffffc020518e:	ecd7b323          	sd	a3,-314(a5) # ffffffffc02b5050 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205192:	cf6ff0ef          	jal	ra,ffffffffc0204688 <kernel_thread>
ffffffffc0205196:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205198:	08a05363          	blez	a0,ffffffffc020521e <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc020519c:	6789                	lui	a5,0x2
ffffffffc020519e:	fff5071b          	addiw	a4,a0,-1
ffffffffc02051a2:	17f9                	addi	a5,a5,-2
ffffffffc02051a4:	2501                	sext.w	a0,a0
ffffffffc02051a6:	02e7e363          	bltu	a5,a4,ffffffffc02051cc <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02051aa:	45a9                	li	a1,10
ffffffffc02051ac:	352000ef          	jal	ra,ffffffffc02054fe <hash32>
ffffffffc02051b0:	02051793          	slli	a5,a0,0x20
ffffffffc02051b4:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02051b8:	96a6                	add	a3,a3,s1
ffffffffc02051ba:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02051bc:	a029                	j	ffffffffc02051c6 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc02051be:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c84>
ffffffffc02051c2:	04870b63          	beq	a4,s0,ffffffffc0205218 <proc_init+0x122>
    return listelm->next;
ffffffffc02051c6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02051c8:	fef69be3          	bne	a3,a5,ffffffffc02051be <proc_init+0xc8>
    return NULL;
ffffffffc02051cc:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02051ce:	0b478493          	addi	s1,a5,180
ffffffffc02051d2:	4641                	li	a2,16
ffffffffc02051d4:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02051d6:	000b0417          	auipc	s0,0xb0
ffffffffc02051da:	e8a40413          	addi	s0,s0,-374 # ffffffffc02b5060 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02051de:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02051e0:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02051e2:	7c2000ef          	jal	ra,ffffffffc02059a4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02051e6:	463d                	li	a2,15
ffffffffc02051e8:	00002597          	auipc	a1,0x2
ffffffffc02051ec:	5e058593          	addi	a1,a1,1504 # ffffffffc02077c8 <default_pmm_manager+0xfa0>
ffffffffc02051f0:	8526                	mv	a0,s1
ffffffffc02051f2:	7c4000ef          	jal	ra,ffffffffc02059b6 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02051f6:	00093783          	ld	a5,0(s2)
ffffffffc02051fa:	cbb5                	beqz	a5,ffffffffc020526e <proc_init+0x178>
ffffffffc02051fc:	43dc                	lw	a5,4(a5)
ffffffffc02051fe:	eba5                	bnez	a5,ffffffffc020526e <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205200:	601c                	ld	a5,0(s0)
ffffffffc0205202:	c7b1                	beqz	a5,ffffffffc020524e <proc_init+0x158>
ffffffffc0205204:	43d8                	lw	a4,4(a5)
ffffffffc0205206:	4785                	li	a5,1
ffffffffc0205208:	04f71363          	bne	a4,a5,ffffffffc020524e <proc_init+0x158>
}
ffffffffc020520c:	60e2                	ld	ra,24(sp)
ffffffffc020520e:	6442                	ld	s0,16(sp)
ffffffffc0205210:	64a2                	ld	s1,8(sp)
ffffffffc0205212:	6902                	ld	s2,0(sp)
ffffffffc0205214:	6105                	addi	sp,sp,32
ffffffffc0205216:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205218:	f2878793          	addi	a5,a5,-216
ffffffffc020521c:	bf4d                	j	ffffffffc02051ce <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020521e:	00002617          	auipc	a2,0x2
ffffffffc0205222:	58a60613          	addi	a2,a2,1418 # ffffffffc02077a8 <default_pmm_manager+0xf80>
ffffffffc0205226:	3fb00593          	li	a1,1019
ffffffffc020522a:	00002517          	auipc	a0,0x2
ffffffffc020522e:	20e50513          	addi	a0,a0,526 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc0205232:	a5cfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205236:	00002617          	auipc	a2,0x2
ffffffffc020523a:	55260613          	addi	a2,a2,1362 # ffffffffc0207788 <default_pmm_manager+0xf60>
ffffffffc020523e:	3ec00593          	li	a1,1004
ffffffffc0205242:	00002517          	auipc	a0,0x2
ffffffffc0205246:	1f650513          	addi	a0,a0,502 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc020524a:	a44fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020524e:	00002697          	auipc	a3,0x2
ffffffffc0205252:	5aa68693          	addi	a3,a3,1450 # ffffffffc02077f8 <default_pmm_manager+0xfd0>
ffffffffc0205256:	00001617          	auipc	a2,0x1
ffffffffc020525a:	fda60613          	addi	a2,a2,-38 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020525e:	40200593          	li	a1,1026
ffffffffc0205262:	00002517          	auipc	a0,0x2
ffffffffc0205266:	1d650513          	addi	a0,a0,470 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc020526a:	a24fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020526e:	00002697          	auipc	a3,0x2
ffffffffc0205272:	56268693          	addi	a3,a3,1378 # ffffffffc02077d0 <default_pmm_manager+0xfa8>
ffffffffc0205276:	00001617          	auipc	a2,0x1
ffffffffc020527a:	fba60613          	addi	a2,a2,-70 # ffffffffc0206230 <commands+0x5f8>
ffffffffc020527e:	40100593          	li	a1,1025
ffffffffc0205282:	00002517          	auipc	a0,0x2
ffffffffc0205286:	1b650513          	addi	a0,a0,438 # ffffffffc0207438 <default_pmm_manager+0xc10>
ffffffffc020528a:	a04fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020528e <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020528e:	1141                	addi	sp,sp,-16
ffffffffc0205290:	e022                	sd	s0,0(sp)
ffffffffc0205292:	e406                	sd	ra,8(sp)
ffffffffc0205294:	000b0417          	auipc	s0,0xb0
ffffffffc0205298:	dbc40413          	addi	s0,s0,-580 # ffffffffc02b5050 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020529c:	6018                	ld	a4,0(s0)
ffffffffc020529e:	6f1c                	ld	a5,24(a4)
ffffffffc02052a0:	dffd                	beqz	a5,ffffffffc020529e <cpu_idle+0x10>
        {
            schedule();
ffffffffc02052a2:	0f0000ef          	jal	ra,ffffffffc0205392 <schedule>
ffffffffc02052a6:	bfdd                	j	ffffffffc020529c <cpu_idle+0xe>

ffffffffc02052a8 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02052a8:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02052ac:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02052b0:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02052b2:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02052b4:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02052b8:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02052bc:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02052c0:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02052c4:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02052c8:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02052cc:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02052d0:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02052d4:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02052d8:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02052dc:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02052e0:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02052e4:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02052e6:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02052e8:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02052ec:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02052f0:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02052f4:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02052f8:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02052fc:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205300:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205304:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205308:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020530c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205310:	8082                	ret

ffffffffc0205312 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205312:	4118                	lw	a4,0(a0)
{
ffffffffc0205314:	1101                	addi	sp,sp,-32
ffffffffc0205316:	ec06                	sd	ra,24(sp)
ffffffffc0205318:	e822                	sd	s0,16(sp)
ffffffffc020531a:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020531c:	478d                	li	a5,3
ffffffffc020531e:	04f70b63          	beq	a4,a5,ffffffffc0205374 <wakeup_proc+0x62>
ffffffffc0205322:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205324:	100027f3          	csrr	a5,sstatus
ffffffffc0205328:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020532a:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020532c:	ef9d                	bnez	a5,ffffffffc020536a <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020532e:	4789                	li	a5,2
ffffffffc0205330:	02f70163          	beq	a4,a5,ffffffffc0205352 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205334:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205336:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc020533a:	e491                	bnez	s1,ffffffffc0205346 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020533c:	60e2                	ld	ra,24(sp)
ffffffffc020533e:	6442                	ld	s0,16(sp)
ffffffffc0205340:	64a2                	ld	s1,8(sp)
ffffffffc0205342:	6105                	addi	sp,sp,32
ffffffffc0205344:	8082                	ret
ffffffffc0205346:	6442                	ld	s0,16(sp)
ffffffffc0205348:	60e2                	ld	ra,24(sp)
ffffffffc020534a:	64a2                	ld	s1,8(sp)
ffffffffc020534c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020534e:	e60fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205352:	00002617          	auipc	a2,0x2
ffffffffc0205356:	50660613          	addi	a2,a2,1286 # ffffffffc0207858 <default_pmm_manager+0x1030>
ffffffffc020535a:	45d1                	li	a1,20
ffffffffc020535c:	00002517          	auipc	a0,0x2
ffffffffc0205360:	4e450513          	addi	a0,a0,1252 # ffffffffc0207840 <default_pmm_manager+0x1018>
ffffffffc0205364:	992fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205368:	bfc9                	j	ffffffffc020533a <wakeup_proc+0x28>
        intr_disable();
ffffffffc020536a:	e4afb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020536e:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205370:	4485                	li	s1,1
ffffffffc0205372:	bf75                	j	ffffffffc020532e <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205374:	00002697          	auipc	a3,0x2
ffffffffc0205378:	4ac68693          	addi	a3,a3,1196 # ffffffffc0207820 <default_pmm_manager+0xff8>
ffffffffc020537c:	00001617          	auipc	a2,0x1
ffffffffc0205380:	eb460613          	addi	a2,a2,-332 # ffffffffc0206230 <commands+0x5f8>
ffffffffc0205384:	45a5                	li	a1,9
ffffffffc0205386:	00002517          	auipc	a0,0x2
ffffffffc020538a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0207840 <default_pmm_manager+0x1018>
ffffffffc020538e:	900fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205392 <schedule>:

void schedule(void)
{
ffffffffc0205392:	1141                	addi	sp,sp,-16
ffffffffc0205394:	e406                	sd	ra,8(sp)
ffffffffc0205396:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205398:	100027f3          	csrr	a5,sstatus
ffffffffc020539c:	8b89                	andi	a5,a5,2
ffffffffc020539e:	4401                	li	s0,0
ffffffffc02053a0:	efbd                	bnez	a5,ffffffffc020541e <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02053a2:	000b0897          	auipc	a7,0xb0
ffffffffc02053a6:	cae8b883          	ld	a7,-850(a7) # ffffffffc02b5050 <current>
ffffffffc02053aa:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02053ae:	000b0517          	auipc	a0,0xb0
ffffffffc02053b2:	caa53503          	ld	a0,-854(a0) # ffffffffc02b5058 <idleproc>
ffffffffc02053b6:	04a88e63          	beq	a7,a0,ffffffffc0205412 <schedule+0x80>
ffffffffc02053ba:	0c888693          	addi	a3,a7,200
ffffffffc02053be:	000b0617          	auipc	a2,0xb0
ffffffffc02053c2:	c1260613          	addi	a2,a2,-1006 # ffffffffc02b4fd0 <proc_list>
        le = last;
ffffffffc02053c6:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02053c8:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02053ca:	4809                	li	a6,2
ffffffffc02053cc:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02053ce:	00c78863          	beq	a5,a2,ffffffffc02053de <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02053d2:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02053d6:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02053da:	03070163          	beq	a4,a6,ffffffffc02053fc <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02053de:	fef697e3          	bne	a3,a5,ffffffffc02053cc <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02053e2:	ed89                	bnez	a1,ffffffffc02053fc <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02053e4:	451c                	lw	a5,8(a0)
ffffffffc02053e6:	2785                	addiw	a5,a5,1
ffffffffc02053e8:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02053ea:	00a88463          	beq	a7,a0,ffffffffc02053f2 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02053ee:	e67fe0ef          	jal	ra,ffffffffc0204254 <proc_run>
    if (flag)
ffffffffc02053f2:	e819                	bnez	s0,ffffffffc0205408 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02053f4:	60a2                	ld	ra,8(sp)
ffffffffc02053f6:	6402                	ld	s0,0(sp)
ffffffffc02053f8:	0141                	addi	sp,sp,16
ffffffffc02053fa:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02053fc:	4198                	lw	a4,0(a1)
ffffffffc02053fe:	4789                	li	a5,2
ffffffffc0205400:	fef712e3          	bne	a4,a5,ffffffffc02053e4 <schedule+0x52>
ffffffffc0205404:	852e                	mv	a0,a1
ffffffffc0205406:	bff9                	j	ffffffffc02053e4 <schedule+0x52>
}
ffffffffc0205408:	6402                	ld	s0,0(sp)
ffffffffc020540a:	60a2                	ld	ra,8(sp)
ffffffffc020540c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020540e:	da0fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205412:	000b0617          	auipc	a2,0xb0
ffffffffc0205416:	bbe60613          	addi	a2,a2,-1090 # ffffffffc02b4fd0 <proc_list>
ffffffffc020541a:	86b2                	mv	a3,a2
ffffffffc020541c:	b76d                	j	ffffffffc02053c6 <schedule+0x34>
        intr_disable();
ffffffffc020541e:	d96fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205422:	4405                	li	s0,1
ffffffffc0205424:	bfbd                	j	ffffffffc02053a2 <schedule+0x10>

ffffffffc0205426 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205426:	000b0797          	auipc	a5,0xb0
ffffffffc020542a:	c2a7b783          	ld	a5,-982(a5) # ffffffffc02b5050 <current>
}
ffffffffc020542e:	43c8                	lw	a0,4(a5)
ffffffffc0205430:	8082                	ret

ffffffffc0205432 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205432:	4501                	li	a0,0
ffffffffc0205434:	8082                	ret

ffffffffc0205436 <sys_putc>:
    cputchar(c);
ffffffffc0205436:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205438:	1141                	addi	sp,sp,-16
ffffffffc020543a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020543c:	d8ffa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc0205440:	60a2                	ld	ra,8(sp)
ffffffffc0205442:	4501                	li	a0,0
ffffffffc0205444:	0141                	addi	sp,sp,16
ffffffffc0205446:	8082                	ret

ffffffffc0205448 <sys_kill>:
    return do_kill(pid);
ffffffffc0205448:	4108                	lw	a0,0(a0)
ffffffffc020544a:	c31ff06f          	j	ffffffffc020507a <do_kill>

ffffffffc020544e <sys_yield>:
    return do_yield();
ffffffffc020544e:	bdfff06f          	j	ffffffffc020502c <do_yield>

ffffffffc0205452 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205452:	6d14                	ld	a3,24(a0)
ffffffffc0205454:	6910                	ld	a2,16(a0)
ffffffffc0205456:	650c                	ld	a1,8(a0)
ffffffffc0205458:	6108                	ld	a0,0(a0)
ffffffffc020545a:	ebeff06f          	j	ffffffffc0204b18 <do_execve>

ffffffffc020545e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020545e:	650c                	ld	a1,8(a0)
ffffffffc0205460:	4108                	lw	a0,0(a0)
ffffffffc0205462:	bdbff06f          	j	ffffffffc020503c <do_wait>

ffffffffc0205466 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205466:	000b0797          	auipc	a5,0xb0
ffffffffc020546a:	bea7b783          	ld	a5,-1046(a5) # ffffffffc02b5050 <current>
ffffffffc020546e:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205470:	4501                	li	a0,0
ffffffffc0205472:	6a0c                	ld	a1,16(a2)
ffffffffc0205474:	e45fe06f          	j	ffffffffc02042b8 <do_fork>

ffffffffc0205478 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205478:	4108                	lw	a0,0(a0)
ffffffffc020547a:	a5eff06f          	j	ffffffffc02046d8 <do_exit>

ffffffffc020547e <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020547e:	715d                	addi	sp,sp,-80
ffffffffc0205480:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205482:	000b0497          	auipc	s1,0xb0
ffffffffc0205486:	bce48493          	addi	s1,s1,-1074 # ffffffffc02b5050 <current>
ffffffffc020548a:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020548c:	e0a2                	sd	s0,64(sp)
ffffffffc020548e:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205490:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205492:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205494:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205496:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020549a:	0327ee63          	bltu	a5,s2,ffffffffc02054d6 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020549e:	00391713          	slli	a4,s2,0x3
ffffffffc02054a2:	00002797          	auipc	a5,0x2
ffffffffc02054a6:	41e78793          	addi	a5,a5,1054 # ffffffffc02078c0 <syscalls>
ffffffffc02054aa:	97ba                	add	a5,a5,a4
ffffffffc02054ac:	639c                	ld	a5,0(a5)
ffffffffc02054ae:	c785                	beqz	a5,ffffffffc02054d6 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02054b0:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02054b2:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02054b4:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02054b6:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02054b8:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02054ba:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02054bc:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02054be:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02054c0:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02054c2:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02054c4:	0028                	addi	a0,sp,8
ffffffffc02054c6:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02054c8:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02054ca:	e828                	sd	a0,80(s0)
}
ffffffffc02054cc:	6406                	ld	s0,64(sp)
ffffffffc02054ce:	74e2                	ld	s1,56(sp)
ffffffffc02054d0:	7942                	ld	s2,48(sp)
ffffffffc02054d2:	6161                	addi	sp,sp,80
ffffffffc02054d4:	8082                	ret
    print_trapframe(tf);
ffffffffc02054d6:	8522                	mv	a0,s0
ffffffffc02054d8:	eccfb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02054dc:	609c                	ld	a5,0(s1)
ffffffffc02054de:	86ca                	mv	a3,s2
ffffffffc02054e0:	00002617          	auipc	a2,0x2
ffffffffc02054e4:	39860613          	addi	a2,a2,920 # ffffffffc0207878 <default_pmm_manager+0x1050>
ffffffffc02054e8:	43d8                	lw	a4,4(a5)
ffffffffc02054ea:	06200593          	li	a1,98
ffffffffc02054ee:	0b478793          	addi	a5,a5,180
ffffffffc02054f2:	00002517          	auipc	a0,0x2
ffffffffc02054f6:	3b650513          	addi	a0,a0,950 # ffffffffc02078a8 <default_pmm_manager+0x1080>
ffffffffc02054fa:	f95fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02054fe <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02054fe:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205502:	2785                	addiw	a5,a5,1
ffffffffc0205504:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205508:	02000793          	li	a5,32
ffffffffc020550c:	9f8d                	subw	a5,a5,a1
}
ffffffffc020550e:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205512:	8082                	ret

ffffffffc0205514 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205514:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205518:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020551a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020551e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205520:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205524:	f022                	sd	s0,32(sp)
ffffffffc0205526:	ec26                	sd	s1,24(sp)
ffffffffc0205528:	e84a                	sd	s2,16(sp)
ffffffffc020552a:	f406                	sd	ra,40(sp)
ffffffffc020552c:	e44e                	sd	s3,8(sp)
ffffffffc020552e:	84aa                	mv	s1,a0
ffffffffc0205530:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205532:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205536:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205538:	03067e63          	bgeu	a2,a6,ffffffffc0205574 <printnum+0x60>
ffffffffc020553c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020553e:	00805763          	blez	s0,ffffffffc020554c <printnum+0x38>
ffffffffc0205542:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205544:	85ca                	mv	a1,s2
ffffffffc0205546:	854e                	mv	a0,s3
ffffffffc0205548:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020554a:	fc65                	bnez	s0,ffffffffc0205542 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020554c:	1a02                	slli	s4,s4,0x20
ffffffffc020554e:	00002797          	auipc	a5,0x2
ffffffffc0205552:	47278793          	addi	a5,a5,1138 # ffffffffc02079c0 <syscalls+0x100>
ffffffffc0205556:	020a5a13          	srli	s4,s4,0x20
ffffffffc020555a:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020555c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020555e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205562:	70a2                	ld	ra,40(sp)
ffffffffc0205564:	69a2                	ld	s3,8(sp)
ffffffffc0205566:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205568:	85ca                	mv	a1,s2
ffffffffc020556a:	87a6                	mv	a5,s1
}
ffffffffc020556c:	6942                	ld	s2,16(sp)
ffffffffc020556e:	64e2                	ld	s1,24(sp)
ffffffffc0205570:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205572:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205574:	03065633          	divu	a2,a2,a6
ffffffffc0205578:	8722                	mv	a4,s0
ffffffffc020557a:	f9bff0ef          	jal	ra,ffffffffc0205514 <printnum>
ffffffffc020557e:	b7f9                	j	ffffffffc020554c <printnum+0x38>

ffffffffc0205580 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205580:	7119                	addi	sp,sp,-128
ffffffffc0205582:	f4a6                	sd	s1,104(sp)
ffffffffc0205584:	f0ca                	sd	s2,96(sp)
ffffffffc0205586:	ecce                	sd	s3,88(sp)
ffffffffc0205588:	e8d2                	sd	s4,80(sp)
ffffffffc020558a:	e4d6                	sd	s5,72(sp)
ffffffffc020558c:	e0da                	sd	s6,64(sp)
ffffffffc020558e:	fc5e                	sd	s7,56(sp)
ffffffffc0205590:	f06a                	sd	s10,32(sp)
ffffffffc0205592:	fc86                	sd	ra,120(sp)
ffffffffc0205594:	f8a2                	sd	s0,112(sp)
ffffffffc0205596:	f862                	sd	s8,48(sp)
ffffffffc0205598:	f466                	sd	s9,40(sp)
ffffffffc020559a:	ec6e                	sd	s11,24(sp)
ffffffffc020559c:	892a                	mv	s2,a0
ffffffffc020559e:	84ae                	mv	s1,a1
ffffffffc02055a0:	8d32                	mv	s10,a2
ffffffffc02055a2:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02055a4:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02055a8:	5b7d                	li	s6,-1
ffffffffc02055aa:	00002a97          	auipc	s5,0x2
ffffffffc02055ae:	442a8a93          	addi	s5,s5,1090 # ffffffffc02079ec <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02055b2:	00002b97          	auipc	s7,0x2
ffffffffc02055b6:	656b8b93          	addi	s7,s7,1622 # ffffffffc0207c08 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02055ba:	000d4503          	lbu	a0,0(s10)
ffffffffc02055be:	001d0413          	addi	s0,s10,1
ffffffffc02055c2:	01350a63          	beq	a0,s3,ffffffffc02055d6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02055c6:	c121                	beqz	a0,ffffffffc0205606 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02055c8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02055ca:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02055cc:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02055ce:	fff44503          	lbu	a0,-1(s0)
ffffffffc02055d2:	ff351ae3          	bne	a0,s3,ffffffffc02055c6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055d6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02055da:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02055de:	4c81                	li	s9,0
ffffffffc02055e0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02055e2:	5c7d                	li	s8,-1
ffffffffc02055e4:	5dfd                	li	s11,-1
ffffffffc02055e6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02055ea:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055ec:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02055f0:	0ff5f593          	zext.b	a1,a1
ffffffffc02055f4:	00140d13          	addi	s10,s0,1
ffffffffc02055f8:	04b56263          	bltu	a0,a1,ffffffffc020563c <vprintfmt+0xbc>
ffffffffc02055fc:	058a                	slli	a1,a1,0x2
ffffffffc02055fe:	95d6                	add	a1,a1,s5
ffffffffc0205600:	4194                	lw	a3,0(a1)
ffffffffc0205602:	96d6                	add	a3,a3,s5
ffffffffc0205604:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205606:	70e6                	ld	ra,120(sp)
ffffffffc0205608:	7446                	ld	s0,112(sp)
ffffffffc020560a:	74a6                	ld	s1,104(sp)
ffffffffc020560c:	7906                	ld	s2,96(sp)
ffffffffc020560e:	69e6                	ld	s3,88(sp)
ffffffffc0205610:	6a46                	ld	s4,80(sp)
ffffffffc0205612:	6aa6                	ld	s5,72(sp)
ffffffffc0205614:	6b06                	ld	s6,64(sp)
ffffffffc0205616:	7be2                	ld	s7,56(sp)
ffffffffc0205618:	7c42                	ld	s8,48(sp)
ffffffffc020561a:	7ca2                	ld	s9,40(sp)
ffffffffc020561c:	7d02                	ld	s10,32(sp)
ffffffffc020561e:	6de2                	ld	s11,24(sp)
ffffffffc0205620:	6109                	addi	sp,sp,128
ffffffffc0205622:	8082                	ret
            padc = '0';
ffffffffc0205624:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205626:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020562a:	846a                	mv	s0,s10
ffffffffc020562c:	00140d13          	addi	s10,s0,1
ffffffffc0205630:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205634:	0ff5f593          	zext.b	a1,a1
ffffffffc0205638:	fcb572e3          	bgeu	a0,a1,ffffffffc02055fc <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020563c:	85a6                	mv	a1,s1
ffffffffc020563e:	02500513          	li	a0,37
ffffffffc0205642:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205644:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205648:	8d22                	mv	s10,s0
ffffffffc020564a:	f73788e3          	beq	a5,s3,ffffffffc02055ba <vprintfmt+0x3a>
ffffffffc020564e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205652:	1d7d                	addi	s10,s10,-1
ffffffffc0205654:	ff379de3          	bne	a5,s3,ffffffffc020564e <vprintfmt+0xce>
ffffffffc0205658:	b78d                	j	ffffffffc02055ba <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020565a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020565e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205662:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205664:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205668:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020566c:	02d86463          	bltu	a6,a3,ffffffffc0205694 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205670:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205674:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205678:	0186873b          	addw	a4,a3,s8
ffffffffc020567c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205680:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205682:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205686:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205688:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020568c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205690:	fed870e3          	bgeu	a6,a3,ffffffffc0205670 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205694:	f40ddce3          	bgez	s11,ffffffffc02055ec <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205698:	8de2                	mv	s11,s8
ffffffffc020569a:	5c7d                	li	s8,-1
ffffffffc020569c:	bf81                	j	ffffffffc02055ec <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020569e:	fffdc693          	not	a3,s11
ffffffffc02056a2:	96fd                	srai	a3,a3,0x3f
ffffffffc02056a4:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056a8:	00144603          	lbu	a2,1(s0)
ffffffffc02056ac:	2d81                	sext.w	s11,s11
ffffffffc02056ae:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02056b0:	bf35                	j	ffffffffc02055ec <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02056b2:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056b6:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02056ba:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056bc:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02056be:	bfd9                	j	ffffffffc0205694 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02056c0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056c2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056c6:	01174463          	blt	a4,a7,ffffffffc02056ce <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02056ca:	1a088e63          	beqz	a7,ffffffffc0205886 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02056ce:	000a3603          	ld	a2,0(s4)
ffffffffc02056d2:	46c1                	li	a3,16
ffffffffc02056d4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02056d6:	2781                	sext.w	a5,a5
ffffffffc02056d8:	876e                	mv	a4,s11
ffffffffc02056da:	85a6                	mv	a1,s1
ffffffffc02056dc:	854a                	mv	a0,s2
ffffffffc02056de:	e37ff0ef          	jal	ra,ffffffffc0205514 <printnum>
            break;
ffffffffc02056e2:	bde1                	j	ffffffffc02055ba <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02056e4:	000a2503          	lw	a0,0(s4)
ffffffffc02056e8:	85a6                	mv	a1,s1
ffffffffc02056ea:	0a21                	addi	s4,s4,8
ffffffffc02056ec:	9902                	jalr	s2
            break;
ffffffffc02056ee:	b5f1                	j	ffffffffc02055ba <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02056f0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056f2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02056f6:	01174463          	blt	a4,a7,ffffffffc02056fe <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02056fa:	18088163          	beqz	a7,ffffffffc020587c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02056fe:	000a3603          	ld	a2,0(s4)
ffffffffc0205702:	46a9                	li	a3,10
ffffffffc0205704:	8a2e                	mv	s4,a1
ffffffffc0205706:	bfc1                	j	ffffffffc02056d6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205708:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020570c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020570e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205710:	bdf1                	j	ffffffffc02055ec <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205712:	85a6                	mv	a1,s1
ffffffffc0205714:	02500513          	li	a0,37
ffffffffc0205718:	9902                	jalr	s2
            break;
ffffffffc020571a:	b545                	j	ffffffffc02055ba <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020571c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205720:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205722:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205724:	b5e1                	j	ffffffffc02055ec <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205726:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205728:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020572c:	01174463          	blt	a4,a7,ffffffffc0205734 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205730:	14088163          	beqz	a7,ffffffffc0205872 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205734:	000a3603          	ld	a2,0(s4)
ffffffffc0205738:	46a1                	li	a3,8
ffffffffc020573a:	8a2e                	mv	s4,a1
ffffffffc020573c:	bf69                	j	ffffffffc02056d6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020573e:	03000513          	li	a0,48
ffffffffc0205742:	85a6                	mv	a1,s1
ffffffffc0205744:	e03e                	sd	a5,0(sp)
ffffffffc0205746:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205748:	85a6                	mv	a1,s1
ffffffffc020574a:	07800513          	li	a0,120
ffffffffc020574e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205750:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205752:	6782                	ld	a5,0(sp)
ffffffffc0205754:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205756:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020575a:	bfb5                	j	ffffffffc02056d6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020575c:	000a3403          	ld	s0,0(s4)
ffffffffc0205760:	008a0713          	addi	a4,s4,8
ffffffffc0205764:	e03a                	sd	a4,0(sp)
ffffffffc0205766:	14040263          	beqz	s0,ffffffffc02058aa <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020576a:	0fb05763          	blez	s11,ffffffffc0205858 <vprintfmt+0x2d8>
ffffffffc020576e:	02d00693          	li	a3,45
ffffffffc0205772:	0cd79163          	bne	a5,a3,ffffffffc0205834 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205776:	00044783          	lbu	a5,0(s0)
ffffffffc020577a:	0007851b          	sext.w	a0,a5
ffffffffc020577e:	cf85                	beqz	a5,ffffffffc02057b6 <vprintfmt+0x236>
ffffffffc0205780:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205784:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205788:	000c4563          	bltz	s8,ffffffffc0205792 <vprintfmt+0x212>
ffffffffc020578c:	3c7d                	addiw	s8,s8,-1
ffffffffc020578e:	036c0263          	beq	s8,s6,ffffffffc02057b2 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205792:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205794:	0e0c8e63          	beqz	s9,ffffffffc0205890 <vprintfmt+0x310>
ffffffffc0205798:	3781                	addiw	a5,a5,-32
ffffffffc020579a:	0ef47b63          	bgeu	s0,a5,ffffffffc0205890 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020579e:	03f00513          	li	a0,63
ffffffffc02057a2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057a4:	000a4783          	lbu	a5,0(s4)
ffffffffc02057a8:	3dfd                	addiw	s11,s11,-1
ffffffffc02057aa:	0a05                	addi	s4,s4,1
ffffffffc02057ac:	0007851b          	sext.w	a0,a5
ffffffffc02057b0:	ffe1                	bnez	a5,ffffffffc0205788 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02057b2:	01b05963          	blez	s11,ffffffffc02057c4 <vprintfmt+0x244>
ffffffffc02057b6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02057b8:	85a6                	mv	a1,s1
ffffffffc02057ba:	02000513          	li	a0,32
ffffffffc02057be:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02057c0:	fe0d9be3          	bnez	s11,ffffffffc02057b6 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02057c4:	6a02                	ld	s4,0(sp)
ffffffffc02057c6:	bbd5                	j	ffffffffc02055ba <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02057c8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057ca:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02057ce:	01174463          	blt	a4,a7,ffffffffc02057d6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02057d2:	08088d63          	beqz	a7,ffffffffc020586c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02057d6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02057da:	0a044d63          	bltz	s0,ffffffffc0205894 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02057de:	8622                	mv	a2,s0
ffffffffc02057e0:	8a66                	mv	s4,s9
ffffffffc02057e2:	46a9                	li	a3,10
ffffffffc02057e4:	bdcd                	j	ffffffffc02056d6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02057e6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02057ea:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02057ec:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02057ee:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02057f2:	8fb5                	xor	a5,a5,a3
ffffffffc02057f4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02057f8:	02d74163          	blt	a4,a3,ffffffffc020581a <vprintfmt+0x29a>
ffffffffc02057fc:	00369793          	slli	a5,a3,0x3
ffffffffc0205800:	97de                	add	a5,a5,s7
ffffffffc0205802:	639c                	ld	a5,0(a5)
ffffffffc0205804:	cb99                	beqz	a5,ffffffffc020581a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205806:	86be                	mv	a3,a5
ffffffffc0205808:	00000617          	auipc	a2,0x0
ffffffffc020580c:	1f060613          	addi	a2,a2,496 # ffffffffc02059f8 <etext+0x2a>
ffffffffc0205810:	85a6                	mv	a1,s1
ffffffffc0205812:	854a                	mv	a0,s2
ffffffffc0205814:	0ce000ef          	jal	ra,ffffffffc02058e2 <printfmt>
ffffffffc0205818:	b34d                	j	ffffffffc02055ba <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020581a:	00002617          	auipc	a2,0x2
ffffffffc020581e:	1c660613          	addi	a2,a2,454 # ffffffffc02079e0 <syscalls+0x120>
ffffffffc0205822:	85a6                	mv	a1,s1
ffffffffc0205824:	854a                	mv	a0,s2
ffffffffc0205826:	0bc000ef          	jal	ra,ffffffffc02058e2 <printfmt>
ffffffffc020582a:	bb41                	j	ffffffffc02055ba <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020582c:	00002417          	auipc	s0,0x2
ffffffffc0205830:	1ac40413          	addi	s0,s0,428 # ffffffffc02079d8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205834:	85e2                	mv	a1,s8
ffffffffc0205836:	8522                	mv	a0,s0
ffffffffc0205838:	e43e                	sd	a5,8(sp)
ffffffffc020583a:	0e2000ef          	jal	ra,ffffffffc020591c <strnlen>
ffffffffc020583e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205842:	01b05b63          	blez	s11,ffffffffc0205858 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205846:	67a2                	ld	a5,8(sp)
ffffffffc0205848:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020584c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020584e:	85a6                	mv	a1,s1
ffffffffc0205850:	8552                	mv	a0,s4
ffffffffc0205852:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205854:	fe0d9ce3          	bnez	s11,ffffffffc020584c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205858:	00044783          	lbu	a5,0(s0)
ffffffffc020585c:	00140a13          	addi	s4,s0,1
ffffffffc0205860:	0007851b          	sext.w	a0,a5
ffffffffc0205864:	d3a5                	beqz	a5,ffffffffc02057c4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205866:	05e00413          	li	s0,94
ffffffffc020586a:	bf39                	j	ffffffffc0205788 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020586c:	000a2403          	lw	s0,0(s4)
ffffffffc0205870:	b7ad                	j	ffffffffc02057da <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205872:	000a6603          	lwu	a2,0(s4)
ffffffffc0205876:	46a1                	li	a3,8
ffffffffc0205878:	8a2e                	mv	s4,a1
ffffffffc020587a:	bdb1                	j	ffffffffc02056d6 <vprintfmt+0x156>
ffffffffc020587c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205880:	46a9                	li	a3,10
ffffffffc0205882:	8a2e                	mv	s4,a1
ffffffffc0205884:	bd89                	j	ffffffffc02056d6 <vprintfmt+0x156>
ffffffffc0205886:	000a6603          	lwu	a2,0(s4)
ffffffffc020588a:	46c1                	li	a3,16
ffffffffc020588c:	8a2e                	mv	s4,a1
ffffffffc020588e:	b5a1                	j	ffffffffc02056d6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205890:	9902                	jalr	s2
ffffffffc0205892:	bf09                	j	ffffffffc02057a4 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205894:	85a6                	mv	a1,s1
ffffffffc0205896:	02d00513          	li	a0,45
ffffffffc020589a:	e03e                	sd	a5,0(sp)
ffffffffc020589c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020589e:	6782                	ld	a5,0(sp)
ffffffffc02058a0:	8a66                	mv	s4,s9
ffffffffc02058a2:	40800633          	neg	a2,s0
ffffffffc02058a6:	46a9                	li	a3,10
ffffffffc02058a8:	b53d                	j	ffffffffc02056d6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02058aa:	03b05163          	blez	s11,ffffffffc02058cc <vprintfmt+0x34c>
ffffffffc02058ae:	02d00693          	li	a3,45
ffffffffc02058b2:	f6d79de3          	bne	a5,a3,ffffffffc020582c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02058b6:	00002417          	auipc	s0,0x2
ffffffffc02058ba:	12240413          	addi	s0,s0,290 # ffffffffc02079d8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058be:	02800793          	li	a5,40
ffffffffc02058c2:	02800513          	li	a0,40
ffffffffc02058c6:	00140a13          	addi	s4,s0,1
ffffffffc02058ca:	bd6d                	j	ffffffffc0205784 <vprintfmt+0x204>
ffffffffc02058cc:	00002a17          	auipc	s4,0x2
ffffffffc02058d0:	10da0a13          	addi	s4,s4,269 # ffffffffc02079d9 <syscalls+0x119>
ffffffffc02058d4:	02800513          	li	a0,40
ffffffffc02058d8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02058dc:	05e00413          	li	s0,94
ffffffffc02058e0:	b565                	j	ffffffffc0205788 <vprintfmt+0x208>

ffffffffc02058e2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02058e2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02058e4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02058e8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02058ea:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02058ec:	ec06                	sd	ra,24(sp)
ffffffffc02058ee:	f83a                	sd	a4,48(sp)
ffffffffc02058f0:	fc3e                	sd	a5,56(sp)
ffffffffc02058f2:	e0c2                	sd	a6,64(sp)
ffffffffc02058f4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02058f6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02058f8:	c89ff0ef          	jal	ra,ffffffffc0205580 <vprintfmt>
}
ffffffffc02058fc:	60e2                	ld	ra,24(sp)
ffffffffc02058fe:	6161                	addi	sp,sp,80
ffffffffc0205900:	8082                	ret

ffffffffc0205902 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205902:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205906:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205908:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020590a:	cb81                	beqz	a5,ffffffffc020591a <strlen+0x18>
        cnt ++;
ffffffffc020590c:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020590e:	00a707b3          	add	a5,a4,a0
ffffffffc0205912:	0007c783          	lbu	a5,0(a5)
ffffffffc0205916:	fbfd                	bnez	a5,ffffffffc020590c <strlen+0xa>
ffffffffc0205918:	8082                	ret
    }
    return cnt;
}
ffffffffc020591a:	8082                	ret

ffffffffc020591c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020591c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020591e:	e589                	bnez	a1,ffffffffc0205928 <strnlen+0xc>
ffffffffc0205920:	a811                	j	ffffffffc0205934 <strnlen+0x18>
        cnt ++;
ffffffffc0205922:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205924:	00f58863          	beq	a1,a5,ffffffffc0205934 <strnlen+0x18>
ffffffffc0205928:	00f50733          	add	a4,a0,a5
ffffffffc020592c:	00074703          	lbu	a4,0(a4)
ffffffffc0205930:	fb6d                	bnez	a4,ffffffffc0205922 <strnlen+0x6>
ffffffffc0205932:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205934:	852e                	mv	a0,a1
ffffffffc0205936:	8082                	ret

ffffffffc0205938 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205938:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020593a:	0005c703          	lbu	a4,0(a1)
ffffffffc020593e:	0785                	addi	a5,a5,1
ffffffffc0205940:	0585                	addi	a1,a1,1
ffffffffc0205942:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205946:	fb75                	bnez	a4,ffffffffc020593a <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205948:	8082                	ret

ffffffffc020594a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020594a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020594e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205952:	cb89                	beqz	a5,ffffffffc0205964 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205954:	0505                	addi	a0,a0,1
ffffffffc0205956:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205958:	fee789e3          	beq	a5,a4,ffffffffc020594a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020595c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205960:	9d19                	subw	a0,a0,a4
ffffffffc0205962:	8082                	ret
ffffffffc0205964:	4501                	li	a0,0
ffffffffc0205966:	bfed                	j	ffffffffc0205960 <strcmp+0x16>

ffffffffc0205968 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205968:	c20d                	beqz	a2,ffffffffc020598a <strncmp+0x22>
ffffffffc020596a:	962e                	add	a2,a2,a1
ffffffffc020596c:	a031                	j	ffffffffc0205978 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020596e:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205970:	00e79a63          	bne	a5,a4,ffffffffc0205984 <strncmp+0x1c>
ffffffffc0205974:	00b60b63          	beq	a2,a1,ffffffffc020598a <strncmp+0x22>
ffffffffc0205978:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020597c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020597e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205982:	f7f5                	bnez	a5,ffffffffc020596e <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205984:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205988:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020598a:	4501                	li	a0,0
ffffffffc020598c:	8082                	ret

ffffffffc020598e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020598e:	00054783          	lbu	a5,0(a0)
ffffffffc0205992:	c799                	beqz	a5,ffffffffc02059a0 <strchr+0x12>
        if (*s == c) {
ffffffffc0205994:	00f58763          	beq	a1,a5,ffffffffc02059a2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205998:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020599c:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020599e:	fbfd                	bnez	a5,ffffffffc0205994 <strchr+0x6>
    }
    return NULL;
ffffffffc02059a0:	4501                	li	a0,0
}
ffffffffc02059a2:	8082                	ret

ffffffffc02059a4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02059a4:	ca01                	beqz	a2,ffffffffc02059b4 <memset+0x10>
ffffffffc02059a6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02059a8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02059aa:	0785                	addi	a5,a5,1
ffffffffc02059ac:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02059b0:	fec79de3          	bne	a5,a2,ffffffffc02059aa <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02059b4:	8082                	ret

ffffffffc02059b6 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02059b6:	ca19                	beqz	a2,ffffffffc02059cc <memcpy+0x16>
ffffffffc02059b8:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02059ba:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02059bc:	0005c703          	lbu	a4,0(a1)
ffffffffc02059c0:	0585                	addi	a1,a1,1
ffffffffc02059c2:	0785                	addi	a5,a5,1
ffffffffc02059c4:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02059c8:	fec59ae3          	bne	a1,a2,ffffffffc02059bc <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02059cc:	8082                	ret
