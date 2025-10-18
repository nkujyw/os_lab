
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/*
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	84c50513          	addi	a0,a0,-1972 # ffffffffc0201898 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	85650513          	addi	a0,a0,-1962 # ffffffffc02018b8 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	82458593          	addi	a1,a1,-2012 # ffffffffc0201892 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	86250513          	addi	a0,a0,-1950 # ffffffffc02018d8 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	86e50513          	addi	a0,a0,-1938 # ffffffffc02018f8 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	07258593          	addi	a1,a1,114 # ffffffffc0206108 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0201918 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char *)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	45d58593          	addi	a1,a1,1117 # ffffffffc0206507 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201938 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:
 * kern_init - the first function after the kernel is loaded into memory.
 * It initializes the console, prints kernel info, and sets up memory.
 */
int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	02860613          	addi	a2,a2,40 # ffffffffc0206108 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	790010ef          	jal	ra,ffffffffc0201880 <memset>

    // init device tree and console
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201968 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // init physical memory management (包含自检与 satp 打印)
    pmm_init();
ffffffffc020010c:	091000ef          	jal	ra,ffffffffc020099c <pmm_init>

    // do nothing
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	32a010ef          	jal	ra,ffffffffc020146a <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	2f4010ef          	jal	ra,ffffffffc020146a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	efe30313          	addi	t1,t1,-258 # ffffffffc02060c0 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	79650513          	addi	a0,a0,1942 # ffffffffc0201988 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	fa850513          	addi	a0,a0,-88 # ffffffffc02021b0 <best_fit_pmm_manager+0x608>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	5d00106f          	j	ffffffffc02017ec <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	78650513          	addi	a0,a0,1926 # ffffffffc02019a8 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	76850513          	addi	a0,a0,1896 # ffffffffc02019b8 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	76250513          	addi	a0,a0,1890 # ffffffffc02019c8 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	76a50513          	addi	a0,a0,1898 # ffffffffc02019e0 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9de5>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	70090913          	addi	s2,s2,1792 # ffffffffc0201a30 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	6ea48493          	addi	s1,s1,1770 # ffffffffc0201a28 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	71650513          	addi	a0,a0,1814 # ffffffffc0201aa8 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	74250513          	addi	a0,a0,1858 # ffffffffc0201ae0 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	62250513          	addi	a0,a0,1570 # ffffffffc0201a00 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	41a010ef          	jal	ra,ffffffffc0201806 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	460010ef          	jal	ra,ffffffffc020185a <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	3ac010ef          	jal	ra,ffffffffc020183c <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	59450513          	addi	a0,a0,1428 # ffffffffc0201a38 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	4e650513          	addi	a0,a0,1254 # ffffffffc0201a58 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	4ec50513          	addi	a0,a0,1260 # ffffffffc0201a70 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0201a90 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	53e50513          	addi	a0,a0,1342 # ffffffffc0201ae0 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	b087bf23          	sd	s0,-1250(a5) # ffffffffc02060c8 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	b167bf23          	sd	s6,-1250(a5) # ffffffffc02060d0 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	b0c53503          	ld	a0,-1268(a0) # ffffffffc02060c8 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	b0a53503          	ld	a0,-1270(a0) # ffffffffc02060d0 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0206018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
// —— pmm_manager 所需接口 ——

// 初始化管理结构
static void best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
    try_merge_neighbors(base);
}

static size_t best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00006517          	auipc	a0,0x6
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	cd59                	beqz	a0,ffffffffc020068a <best_fit_alloc_pages+0x9e>
    if (n > nr_free) return NULL;
ffffffffc02005ee:	00006697          	auipc	a3,0x6
ffffffffc02005f2:	a2a68693          	addi	a3,a3,-1494 # ffffffffc0206018 <free_area>
ffffffffc02005f6:	0106a803          	lw	a6,16(a3)
ffffffffc02005fa:	862a                	mv	a2,a0
ffffffffc02005fc:	02081793          	slli	a5,a6,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e263          	bltu	a5,a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	669c                	ld	a5,8(a3)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200608:	06d78f63          	beq	a5,a3,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
    size_t best_size = (size_t)-1;
ffffffffc020060c:	55fd                	li	a1,-1
    struct Page *best = NULL;
ffffffffc020060e:	4501                	li	a0,0
        if (PageProperty(p) && p->property >= n) {
ffffffffc0200610:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200614:	8b09                	andi	a4,a4,2
ffffffffc0200616:	cf01                	beqz	a4,ffffffffc020062e <best_fit_alloc_pages+0x42>
ffffffffc0200618:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020061c:	00c76963          	bltu	a4,a2,ffffffffc020062e <best_fit_alloc_pages+0x42>
            if (p->property < best_size) {
ffffffffc0200620:	00b77763          	bgeu	a4,a1,ffffffffc020062e <best_fit_alloc_pages+0x42>
        struct Page *p = le2page(le, page_link);
ffffffffc0200624:	fe878513          	addi	a0,a5,-24
                if (best_size == n) break;        // 不能更优了
ffffffffc0200628:	00c70763          	beq	a4,a2,ffffffffc0200636 <best_fit_alloc_pages+0x4a>
ffffffffc020062c:	85ba                	mv	a1,a4
ffffffffc020062e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200630:	fed790e3          	bne	a5,a3,ffffffffc0200610 <best_fit_alloc_pages+0x24>
    if (best == NULL) return NULL;
ffffffffc0200634:	c931                	beqz	a0,ffffffffc0200688 <best_fit_alloc_pages+0x9c>
    if (best->property > n) {
ffffffffc0200636:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020063a:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc020063c:	710c                	ld	a1,32(a0)
ffffffffc020063e:	02089793          	slli	a5,a7,0x20
ffffffffc0200642:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200644:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200646:	e198                	sd	a4,0(a1)
        remain->property = best->property - n;
ffffffffc0200648:	0006031b          	sext.w	t1,a2
    if (best->property > n) {
ffffffffc020064c:	02f67563          	bgeu	a2,a5,ffffffffc0200676 <best_fit_alloc_pages+0x8a>
        struct Page *remain = best + n;
ffffffffc0200650:	00261793          	slli	a5,a2,0x2
ffffffffc0200654:	97b2                	add	a5,a5,a2
ffffffffc0200656:	078e                	slli	a5,a5,0x3
ffffffffc0200658:	97aa                	add	a5,a5,a0
        SetPageProperty(remain);
ffffffffc020065a:	6790                	ld	a2,8(a5)
        remain->property = best->property - n;
ffffffffc020065c:	406888bb          	subw	a7,a7,t1
ffffffffc0200660:	0117a823          	sw	a7,16(a5)
        SetPageProperty(remain);
ffffffffc0200664:	00266613          	ori	a2,a2,2
ffffffffc0200668:	e790                	sd	a2,8(a5)
        list_add(prev, &(remain->page_link));
ffffffffc020066a:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc020066e:	e190                	sd	a2,0(a1)
ffffffffc0200670:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200672:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200674:	ef98                	sd	a4,24(a5)
    ClearPageProperty(best);
ffffffffc0200676:	651c                	ld	a5,8(a0)
    nr_free -= n;
ffffffffc0200678:	4068083b          	subw	a6,a6,t1
ffffffffc020067c:	0106a823          	sw	a6,16(a3)
    ClearPageProperty(best);
ffffffffc0200680:	9bf5                	andi	a5,a5,-3
ffffffffc0200682:	e51c                	sd	a5,8(a0)
    return best;
ffffffffc0200684:	8082                	ret
    if (n > nr_free) return NULL;
ffffffffc0200686:	4501                	li	a0,0
}
ffffffffc0200688:	8082                	ret
static struct Page *best_fit_alloc_pages(size_t n) {/*LAB2 EXERCISE 2: 2211044*/
ffffffffc020068a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020068c:	00001697          	auipc	a3,0x1
ffffffffc0200690:	46c68693          	addi	a3,a3,1132 # ffffffffc0201af8 <etext+0x266>
ffffffffc0200694:	00001617          	auipc	a2,0x1
ffffffffc0200698:	46c60613          	addi	a2,a2,1132 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020069c:	06100593          	li	a1,97
ffffffffc02006a0:	00001517          	auipc	a0,0x1
ffffffffc02006a4:	47850513          	addi	a0,a0,1144 # ffffffffc0201b18 <etext+0x286>
static struct Page *best_fit_alloc_pages(size_t n) {/*LAB2 EXERCISE 2: 2211044*/
ffffffffc02006a8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006aa:	b19ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006ae <best_fit_free_pages>:
static void best_fit_free_pages(struct Page *base, size_t n) {/*LAB2 EXERCISE 2: 2211044*/
ffffffffc02006ae:	1141                	addi	sp,sp,-16
ffffffffc02006b0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006b2:	14058863          	beqz	a1,ffffffffc0200802 <best_fit_free_pages+0x154>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc02006b6:	00259693          	slli	a3,a1,0x2
ffffffffc02006ba:	96ae                	add	a3,a3,a1
ffffffffc02006bc:	068e                	slli	a3,a3,0x3
ffffffffc02006be:	96aa                	add	a3,a3,a0
ffffffffc02006c0:	87aa                	mv	a5,a0
ffffffffc02006c2:	00d50e63          	beq	a0,a3,ffffffffc02006de <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02006c6:	6798                	ld	a4,8(a5)
ffffffffc02006c8:	8b0d                	andi	a4,a4,3
ffffffffc02006ca:	10071c63          	bnez	a4,ffffffffc02007e2 <best_fit_free_pages+0x134>
        p->flags = 0;
ffffffffc02006ce:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02006d2:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc02006d6:	02878793          	addi	a5,a5,40
ffffffffc02006da:	fed796e3          	bne	a5,a3,ffffffffc02006c6 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc02006de:	00853803          	ld	a6,8(a0)
    return list->next == list;
ffffffffc02006e2:	00006697          	auipc	a3,0x6
ffffffffc02006e6:	93668693          	addi	a3,a3,-1738 # ffffffffc0206018 <free_area>
ffffffffc02006ea:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc02006ec:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02006ee:	00286713          	ori	a4,a6,2
    base->property = n;
ffffffffc02006f2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02006f4:	e518                	sd	a4,8(a0)
    if (list_empty(&free_list)) {
ffffffffc02006f6:	00d79763          	bne	a5,a3,ffffffffc0200704 <best_fit_free_pages+0x56>
ffffffffc02006fa:	a8c1                	j	ffffffffc02007ca <best_fit_free_pages+0x11c>
    return listelm->next;
ffffffffc02006fc:	6798                	ld	a4,8(a5)
        if (list_next(le) == &free_list) {        // 到尾了，接到尾
ffffffffc02006fe:	08d70563          	beq	a4,a3,ffffffffc0200788 <best_fit_free_pages+0xda>
ffffffffc0200702:	87ba                	mv	a5,a4
        struct Page *page = le2page(le, page_link);
ffffffffc0200704:	fe878713          	addi	a4,a5,-24
        if (base < page) {                        // 第一个地址比 base 大的块
ffffffffc0200708:	fee57ae3          	bgeu	a0,a4,ffffffffc02006fc <best_fit_free_pages+0x4e>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020070c:	6390                	ld	a2,0(a5)
    nr_free += n;
ffffffffc020070e:	0106a883          	lw	a7,16(a3)
            list_add_before(le, &(base->page_link));
ffffffffc0200712:	01850313          	addi	t1,a0,24
    prev->next = next->prev = elm;
ffffffffc0200716:	0067b023          	sd	t1,0(a5)
ffffffffc020071a:	00663423          	sd	t1,8(a2)
    nr_free += n;
ffffffffc020071e:	00b888bb          	addw	a7,a7,a1
    elm->next = next;
ffffffffc0200722:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200724:	ed10                	sd	a2,24(a0)
ffffffffc0200726:	0116a823          	sw	a7,16(a3)
    if (ple != &free_list) {
ffffffffc020072a:	02d60563          	beq	a2,a3,ffffffffc0200754 <best_fit_free_pages+0xa6>
        if (prev + prev->property == base) {      // 物理相邻
ffffffffc020072e:	ff862e03          	lw	t3,-8(a2)
        struct Page *prev = le2page(ple, page_link);
ffffffffc0200732:	fe860313          	addi	t1,a2,-24
        if (prev + prev->property == base) {      // 物理相邻
ffffffffc0200736:	020e1893          	slli	a7,t3,0x20
ffffffffc020073a:	0208d893          	srli	a7,a7,0x20
ffffffffc020073e:	00289713          	slli	a4,a7,0x2
ffffffffc0200742:	9746                	add	a4,a4,a7
ffffffffc0200744:	070e                	slli	a4,a4,0x3
ffffffffc0200746:	971a                	add	a4,a4,t1
ffffffffc0200748:	02e50463          	beq	a0,a4,ffffffffc0200770 <best_fit_free_pages+0xc2>
    if (nle != &free_list) {
ffffffffc020074c:	00d78f63          	beq	a5,a3,ffffffffc020076a <best_fit_free_pages+0xbc>
ffffffffc0200750:	fe878713          	addi	a4,a5,-24
        if (base + base->property == next) {      // 物理相邻
ffffffffc0200754:	490c                	lw	a1,16(a0)
ffffffffc0200756:	02059613          	slli	a2,a1,0x20
ffffffffc020075a:	9201                	srli	a2,a2,0x20
ffffffffc020075c:	00261693          	slli	a3,a2,0x2
ffffffffc0200760:	96b2                	add	a3,a3,a2
ffffffffc0200762:	068e                	slli	a3,a3,0x3
ffffffffc0200764:	96aa                	add	a3,a3,a0
ffffffffc0200766:	02d70f63          	beq	a4,a3,ffffffffc02007a4 <best_fit_free_pages+0xf6>
}
ffffffffc020076a:	60a2                	ld	ra,8(sp)
ffffffffc020076c:	0141                	addi	sp,sp,16
ffffffffc020076e:	8082                	ret
            prev->property += base->property;
ffffffffc0200770:	01c585bb          	addw	a1,a1,t3
ffffffffc0200774:	feb62c23          	sw	a1,-8(a2)
            ClearPageProperty(base);
ffffffffc0200778:	ffd87813          	andi	a6,a6,-3
ffffffffc020077c:	01053423          	sd	a6,8(a0)
    prev->next = next;
ffffffffc0200780:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc0200782:	e390                	sd	a2,0(a5)
            base = prev;                           // 合并后用 prev 继续向后看
ffffffffc0200784:	851a                	mv	a0,t1
ffffffffc0200786:	b7d9                	j	ffffffffc020074c <best_fit_free_pages+0x9e>
    nr_free += n;
ffffffffc0200788:	4a98                	lw	a4,16(a3)
            list_add(le, &(base->page_link));
ffffffffc020078a:	01850893          	addi	a7,a0,24
    prev->next = next->prev = elm;
ffffffffc020078e:	0117b423          	sd	a7,8(a5)
    nr_free += n;
ffffffffc0200792:	9f2d                	addw	a4,a4,a1
    elm->prev = prev;
ffffffffc0200794:	ed1c                	sd	a5,24(a0)
ffffffffc0200796:	863e                	mv	a2,a5
    prev->next = next->prev = elm;
ffffffffc0200798:	0116b023          	sd	a7,0(a3)
    elm->next = next;
ffffffffc020079c:	f114                	sd	a3,32(a0)
ffffffffc020079e:	ca98                	sw	a4,16(a3)
ffffffffc02007a0:	87b6                	mv	a5,a3
ffffffffc02007a2:	b771                	j	ffffffffc020072e <best_fit_free_pages+0x80>
            base->property += next->property;
ffffffffc02007a4:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(next);
ffffffffc02007a8:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007ac:	0007b803          	ld	a6,0(a5)
ffffffffc02007b0:	6790                	ld	a2,8(a5)
            base->property += next->property;
ffffffffc02007b2:	9db5                	addw	a1,a1,a3
ffffffffc02007b4:	c90c                	sw	a1,16(a0)
            ClearPageProperty(next);
ffffffffc02007b6:	9b75                	andi	a4,a4,-3
ffffffffc02007b8:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc02007bc:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02007be:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc02007c2:	01063023          	sd	a6,0(a2)
ffffffffc02007c6:	0141                	addi	sp,sp,16
ffffffffc02007c8:	8082                	ret
    nr_free += n;
ffffffffc02007ca:	4b98                	lw	a4,16(a5)
}
ffffffffc02007cc:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02007ce:	01850693          	addi	a3,a0,24
    nr_free += n;
ffffffffc02007d2:	9db9                	addw	a1,a1,a4
    prev->next = next->prev = elm;
ffffffffc02007d4:	e394                	sd	a3,0(a5)
ffffffffc02007d6:	e794                	sd	a3,8(a5)
    elm->next = next;
ffffffffc02007d8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02007da:	ed1c                	sd	a5,24(a0)
ffffffffc02007dc:	cb8c                	sw	a1,16(a5)
}
ffffffffc02007de:	0141                	addi	sp,sp,16
ffffffffc02007e0:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02007e2:	00001697          	auipc	a3,0x1
ffffffffc02007e6:	34e68693          	addi	a3,a3,846 # ffffffffc0201b30 <etext+0x29e>
ffffffffc02007ea:	00001617          	auipc	a2,0x1
ffffffffc02007ee:	31660613          	addi	a2,a2,790 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02007f2:	08800593          	li	a1,136
ffffffffc02007f6:	00001517          	auipc	a0,0x1
ffffffffc02007fa:	32250513          	addi	a0,a0,802 # ffffffffc0201b18 <etext+0x286>
ffffffffc02007fe:	9c5ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200802:	00001697          	auipc	a3,0x1
ffffffffc0200806:	2f668693          	addi	a3,a3,758 # ffffffffc0201af8 <etext+0x266>
ffffffffc020080a:	00001617          	auipc	a2,0x1
ffffffffc020080e:	2f660613          	addi	a2,a2,758 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200812:	08600593          	li	a1,134
ffffffffc0200816:	00001517          	auipc	a0,0x1
ffffffffc020081a:	30250513          	addi	a0,a0,770 # ffffffffc0201b18 <etext+0x286>
ffffffffc020081e:	9a5ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200822 <best_fit_check>:


static void best_fit_check(void) {
ffffffffc0200822:	1101                	addi	sp,sp,-32
ffffffffc0200824:	e822                	sd	s0,16(sp)
    size_t before = nr_free;
    struct Page *p = alloc_pages(1);
ffffffffc0200826:	4505                	li	a0,1
    size_t before = nr_free;
ffffffffc0200828:	00005417          	auipc	s0,0x5
ffffffffc020082c:	7f040413          	addi	s0,s0,2032 # ffffffffc0206018 <free_area>
static void best_fit_check(void) {
ffffffffc0200830:	e426                	sd	s1,8(sp)
ffffffffc0200832:	ec06                	sd	ra,24(sp)
    size_t before = nr_free;
ffffffffc0200834:	4804                	lw	s1,16(s0)
    struct Page *p = alloc_pages(1);
ffffffffc0200836:	142000ef          	jal	ra,ffffffffc0200978 <alloc_pages>
    assert(p != NULL);
ffffffffc020083a:	cd01                	beqz	a0,ffffffffc0200852 <best_fit_check+0x30>
    free_pages(p, 1);
ffffffffc020083c:	4585                	li	a1,1
ffffffffc020083e:	146000ef          	jal	ra,ffffffffc0200984 <free_pages>
    assert(nr_free == before);
ffffffffc0200842:	481c                	lw	a5,16(s0)
ffffffffc0200844:	02979763          	bne	a5,s1,ffffffffc0200872 <best_fit_check+0x50>
}
ffffffffc0200848:	60e2                	ld	ra,24(sp)
ffffffffc020084a:	6442                	ld	s0,16(sp)
ffffffffc020084c:	64a2                	ld	s1,8(sp)
ffffffffc020084e:	6105                	addi	sp,sp,32
ffffffffc0200850:	8082                	ret
    assert(p != NULL);
ffffffffc0200852:	00001697          	auipc	a3,0x1
ffffffffc0200856:	30668693          	addi	a3,a3,774 # ffffffffc0201b58 <etext+0x2c6>
ffffffffc020085a:	00001617          	auipc	a2,0x1
ffffffffc020085e:	2a660613          	addi	a2,a2,678 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200862:	09d00593          	li	a1,157
ffffffffc0200866:	00001517          	auipc	a0,0x1
ffffffffc020086a:	2b250513          	addi	a0,a0,690 # ffffffffc0201b18 <etext+0x286>
ffffffffc020086e:	955ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == before);
ffffffffc0200872:	00001697          	auipc	a3,0x1
ffffffffc0200876:	2f668693          	addi	a3,a3,758 # ffffffffc0201b68 <etext+0x2d6>
ffffffffc020087a:	00001617          	auipc	a2,0x1
ffffffffc020087e:	28660613          	addi	a2,a2,646 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200882:	09f00593          	li	a1,159
ffffffffc0200886:	00001517          	auipc	a0,0x1
ffffffffc020088a:	29250513          	addi	a0,a0,658 # ffffffffc0201b18 <etext+0x286>
ffffffffc020088e:	935ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200892 <best_fit_init_memmap>:
static void best_fit_init_memmap(struct Page *base, size_t n) {/*LAB2 EXERCISE 2: 2211044*/
ffffffffc0200892:	1141                	addi	sp,sp,-16
ffffffffc0200894:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200896:	c1e9                	beqz	a1,ffffffffc0200958 <best_fit_init_memmap+0xc6>
    for (; p != base + n; p++) {
ffffffffc0200898:	00259693          	slli	a3,a1,0x2
ffffffffc020089c:	96ae                	add	a3,a3,a1
ffffffffc020089e:	068e                	slli	a3,a3,0x3
ffffffffc02008a0:	96aa                	add	a3,a3,a0
ffffffffc02008a2:	87aa                	mv	a5,a0
ffffffffc02008a4:	00d50f63          	beq	a0,a3,ffffffffc02008c2 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc02008a8:	6798                	ld	a4,8(a5)
ffffffffc02008aa:	8b05                	andi	a4,a4,1
ffffffffc02008ac:	c751                	beqz	a4,ffffffffc0200938 <best_fit_init_memmap+0xa6>
        p->flags = 0;
ffffffffc02008ae:	0007b423          	sd	zero,8(a5)
ffffffffc02008b2:	0007a023          	sw	zero,0(a5)
        p->property = 0;
ffffffffc02008b6:	0007a823          	sw	zero,16(a5)
    for (; p != base + n; p++) {
ffffffffc02008ba:	02878793          	addi	a5,a5,40
ffffffffc02008be:	fed795e3          	bne	a5,a3,ffffffffc02008a8 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc02008c2:	6518                	ld	a4,8(a0)
    return list->next == list;
ffffffffc02008c4:	00005697          	auipc	a3,0x5
ffffffffc02008c8:	75468693          	addi	a3,a3,1876 # ffffffffc0206018 <free_area>
ffffffffc02008cc:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc02008ce:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02008d0:	00276713          	ori	a4,a4,2
    base->property = n;
ffffffffc02008d4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02008d6:	e518                	sd	a4,8(a0)
    if (list_empty(&free_list)) {
ffffffffc02008d8:	00d79763          	bne	a5,a3,ffffffffc02008e6 <best_fit_init_memmap+0x54>
ffffffffc02008dc:	a091                	j	ffffffffc0200920 <best_fit_init_memmap+0x8e>
    return listelm->next;
ffffffffc02008de:	6798                	ld	a4,8(a5)
        if (list_next(le) == &free_list) {        // 到尾了，接到尾
ffffffffc02008e0:	02d70463          	beq	a4,a3,ffffffffc0200908 <best_fit_init_memmap+0x76>
ffffffffc02008e4:	87ba                	mv	a5,a4
        struct Page *page = le2page(le, page_link);
ffffffffc02008e6:	fe878713          	addi	a4,a5,-24
        if (base < page) {                        // 第一个地址比 base 大的块
ffffffffc02008ea:	fee57ae3          	bgeu	a0,a4,ffffffffc02008de <best_fit_init_memmap+0x4c>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02008ee:	6398                	ld	a4,0(a5)
            list_add_before(le, &(base->page_link));
ffffffffc02008f0:	01850613          	addi	a2,a0,24
    prev->next = next->prev = elm;
ffffffffc02008f4:	e390                	sd	a2,0(a5)
ffffffffc02008f6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02008f8:	f11c                	sd	a5,32(a0)
    nr_free += n;
ffffffffc02008fa:	4a9c                	lw	a5,16(a3)
}
ffffffffc02008fc:	60a2                	ld	ra,8(sp)
    elm->prev = prev;
ffffffffc02008fe:	ed18                	sd	a4,24(a0)
    nr_free += n;
ffffffffc0200900:	9dbd                	addw	a1,a1,a5
ffffffffc0200902:	ca8c                	sw	a1,16(a3)
}
ffffffffc0200904:	0141                	addi	sp,sp,16
ffffffffc0200906:	8082                	ret
            list_add(le, &(base->page_link));
ffffffffc0200908:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020090c:	e798                	sd	a4,8(a5)
    elm->prev = prev;
ffffffffc020090e:	ed1c                	sd	a5,24(a0)
    nr_free += n;
ffffffffc0200910:	4a9c                	lw	a5,16(a3)
}
ffffffffc0200912:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200914:	e298                	sd	a4,0(a3)
    nr_free += n;
ffffffffc0200916:	9dbd                	addw	a1,a1,a5
    elm->next = next;
ffffffffc0200918:	f114                	sd	a3,32(a0)
ffffffffc020091a:	ca8c                	sw	a1,16(a3)
}
ffffffffc020091c:	0141                	addi	sp,sp,16
ffffffffc020091e:	8082                	ret
        list_add(&free_list, &(base->page_link));
ffffffffc0200920:	01850793          	addi	a5,a0,24
    prev->next = next->prev = elm;
ffffffffc0200924:	e29c                	sd	a5,0(a3)
ffffffffc0200926:	e69c                	sd	a5,8(a3)
    nr_free += n;
ffffffffc0200928:	4a9c                	lw	a5,16(a3)
}
ffffffffc020092a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020092c:	f114                	sd	a3,32(a0)
    nr_free += n;
ffffffffc020092e:	9dbd                	addw	a1,a1,a5
    elm->prev = prev;
ffffffffc0200930:	ed14                	sd	a3,24(a0)
ffffffffc0200932:	ca8c                	sw	a1,16(a3)
}
ffffffffc0200934:	0141                	addi	sp,sp,16
ffffffffc0200936:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200938:	00001697          	auipc	a3,0x1
ffffffffc020093c:	24868693          	addi	a3,a3,584 # ffffffffc0201b80 <etext+0x2ee>
ffffffffc0200940:	00001617          	auipc	a2,0x1
ffffffffc0200944:	1c060613          	addi	a2,a2,448 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200948:	05300593          	li	a1,83
ffffffffc020094c:	00001517          	auipc	a0,0x1
ffffffffc0200950:	1cc50513          	addi	a0,a0,460 # ffffffffc0201b18 <etext+0x286>
ffffffffc0200954:	86fff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200958:	00001697          	auipc	a3,0x1
ffffffffc020095c:	1a068693          	addi	a3,a3,416 # ffffffffc0201af8 <etext+0x266>
ffffffffc0200960:	00001617          	auipc	a2,0x1
ffffffffc0200964:	1a060613          	addi	a2,a2,416 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200968:	05000593          	li	a1,80
ffffffffc020096c:	00001517          	auipc	a0,0x1
ffffffffc0200970:	1ac50513          	addi	a0,a0,428 # ffffffffc0201b18 <etext+0x286>
ffffffffc0200974:	84fff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200978 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200978:	00005797          	auipc	a5,0x5
ffffffffc020097c:	7707b783          	ld	a5,1904(a5) # ffffffffc02060e8 <pmm_manager>
ffffffffc0200980:	6f9c                	ld	a5,24(a5)
ffffffffc0200982:	8782                	jr	a5

ffffffffc0200984 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200984:	00005797          	auipc	a5,0x5
ffffffffc0200988:	7647b783          	ld	a5,1892(a5) # ffffffffc02060e8 <pmm_manager>
ffffffffc020098c:	739c                	ld	a5,32(a5)
ffffffffc020098e:	8782                	jr	a5

ffffffffc0200990 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200990:	00005797          	auipc	a5,0x5
ffffffffc0200994:	7587b783          	ld	a5,1880(a5) # ffffffffc02060e8 <pmm_manager>
ffffffffc0200998:	779c                	ld	a5,40(a5)
ffffffffc020099a:	8782                	jr	a5

ffffffffc020099c <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;/*LAB2 EXERCISE 2: 2211044*/
ffffffffc020099c:	00001797          	auipc	a5,0x1
ffffffffc02009a0:	20c78793          	addi	a5,a5,524 # ffffffffc0201ba8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02009a4:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02009a6:	1101                	addi	sp,sp,-32
ffffffffc02009a8:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02009aa:	00001517          	auipc	a0,0x1
ffffffffc02009ae:	23650513          	addi	a0,a0,566 # ffffffffc0201be0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;/*LAB2 EXERCISE 2: 2211044*/
ffffffffc02009b2:	00005497          	auipc	s1,0x5
ffffffffc02009b6:	73648493          	addi	s1,s1,1846 # ffffffffc02060e8 <pmm_manager>
void pmm_init(void) {
ffffffffc02009ba:	ec06                	sd	ra,24(sp)
ffffffffc02009bc:	e822                	sd	s0,16(sp)
ffffffffc02009be:	e04a                	sd	s2,0(sp)
    pmm_manager = &best_fit_pmm_manager;/*LAB2 EXERCISE 2: 2211044*/
ffffffffc02009c0:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02009c2:	f8aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02009c6:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02009c8:	00005917          	auipc	s2,0x5
ffffffffc02009cc:	73890913          	addi	s2,s2,1848 # ffffffffc0206100 <va_pa_offset>
    pmm_manager->init();
ffffffffc02009d0:	679c                	ld	a5,8(a5)
ffffffffc02009d2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02009d4:	57f5                	li	a5,-3
ffffffffc02009d6:	07fa                	slli	a5,a5,0x1e
ffffffffc02009d8:	00f93023          	sd	a5,0(s2)
    uint64_t mem_begin = get_memory_base();
ffffffffc02009dc:	be1ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc02009e0:	842a                	mv	s0,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02009e2:	be5ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02009e6:	14050e63          	beqz	a0,ffffffffc0200b42 <pmm_init+0x1a6>
    cprintf("physcial memory map:\n");
ffffffffc02009ea:	00001517          	auipc	a0,0x1
ffffffffc02009ee:	23e50513          	addi	a0,a0,574 # ffffffffc0201c28 <best_fit_pmm_manager+0x80>
ffffffffc02009f2:	f5aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  memory: 0x0000000008000000, [0x0000000080000000, 0x0000000087ffffff].\n");
ffffffffc02009f6:	00001517          	auipc	a0,0x1
ffffffffc02009fa:	24a50513          	addi	a0,a0,586 # ffffffffc0201c40 <best_fit_pmm_manager+0x98>
ffffffffc02009fe:	f4eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    mem_end  = mem_begin + mem_size;
ffffffffc0200a02:	080005b7          	lui	a1,0x8000
ffffffffc0200a06:	95a2                	add	a1,a1,s0
    npage = maxpa / PGSIZE;
ffffffffc0200a08:	c80007b7          	lui	a5,0xc8000
ffffffffc0200a0c:	862e                	mv	a2,a1
ffffffffc0200a0e:	0cb7e963          	bltu	a5,a1,ffffffffc0200ae0 <pmm_init+0x144>
ffffffffc0200a12:	00006797          	auipc	a5,0x6
ffffffffc0200a16:	6f578793          	addi	a5,a5,1781 # ffffffffc0207107 <end+0xfff>
ffffffffc0200a1a:	757d                	lui	a0,0xfffff
ffffffffc0200a1c:	8d7d                	and	a0,a0,a5
ffffffffc0200a1e:	8231                	srli	a2,a2,0xc
ffffffffc0200a20:	00005797          	auipc	a5,0x5
ffffffffc0200a24:	6ac7bc23          	sd	a2,1720(a5) # ffffffffc02060d8 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200a28:	00005797          	auipc	a5,0x5
ffffffffc0200a2c:	6aa7bc23          	sd	a0,1720(a5) # ffffffffc02060e0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200a30:	000807b7          	lui	a5,0x80
ffffffffc0200a34:	00200837          	lui	a6,0x200
ffffffffc0200a38:	02f60563          	beq	a2,a5,ffffffffc0200a62 <pmm_init+0xc6>
ffffffffc0200a3c:	00261813          	slli	a6,a2,0x2
ffffffffc0200a40:	00c807b3          	add	a5,a6,a2
ffffffffc0200a44:	fec006b7          	lui	a3,0xfec00
ffffffffc0200a48:	078e                	slli	a5,a5,0x3
ffffffffc0200a4a:	96aa                	add	a3,a3,a0
ffffffffc0200a4c:	96be                	add	a3,a3,a5
ffffffffc0200a4e:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200a50:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200a52:	02878793          	addi	a5,a5,40 # 80028 <kern_entry-0xffffffffc017ffd8>
        SetPageReserved(pages + i);
ffffffffc0200a56:	00176713          	ori	a4,a4,1
ffffffffc0200a5a:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200a5e:	fef699e3          	bne	a3,a5,ffffffffc0200a50 <pmm_init+0xb4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200a62:	9832                	add	a6,a6,a2
ffffffffc0200a64:	fec006b7          	lui	a3,0xfec00
ffffffffc0200a68:	96aa                	add	a3,a3,a0
ffffffffc0200a6a:	080e                	slli	a6,a6,0x3
ffffffffc0200a6c:	96c2                	add	a3,a3,a6
ffffffffc0200a6e:	c02007b7          	lui	a5,0xc0200
ffffffffc0200a72:	0af6ec63          	bltu	a3,a5,ffffffffc0200b2a <pmm_init+0x18e>
ffffffffc0200a76:	00093703          	ld	a4,0(s2)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200a7a:	77fd                	lui	a5,0xfffff
ffffffffc0200a7c:	8dfd                	and	a1,a1,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200a7e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200a80:	06b6e363          	bltu	a3,a1,ffffffffc0200ae6 <pmm_init+0x14a>
    // Run SLUB test
    slub_check();
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200a84:	609c                	ld	a5,0(s1)
ffffffffc0200a86:	7b9c                	ld	a5,48(a5)
ffffffffc0200a88:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200a8a:	00001517          	auipc	a0,0x1
ffffffffc0200a8e:	25e50513          	addi	a0,a0,606 # ffffffffc0201ce8 <best_fit_pmm_manager+0x140>
ffffffffc0200a92:	ebaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc0200a96:	00004697          	auipc	a3,0x4
ffffffffc0200a9a:	56a68693          	addi	a3,a3,1386 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200a9e:	00005797          	auipc	a5,0x5
ffffffffc0200aa2:	64d7bd23          	sd	a3,1626(a5) # ffffffffc02060f8 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200aa6:	c02007b7          	lui	a5,0xc0200
ffffffffc0200aaa:	0af6e863          	bltu	a3,a5,ffffffffc0200b5a <pmm_init+0x1be>
ffffffffc0200aae:	00093783          	ld	a5,0(s2)
    cprintf("satp virtual address: 0xffffffffc0204000\n");
ffffffffc0200ab2:	00001517          	auipc	a0,0x1
ffffffffc0200ab6:	25650513          	addi	a0,a0,598 # ffffffffc0201d08 <best_fit_pmm_manager+0x160>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200aba:	8e9d                	sub	a3,a3,a5
ffffffffc0200abc:	00005797          	auipc	a5,0x5
ffffffffc0200ac0:	62d7ba23          	sd	a3,1588(a5) # ffffffffc02060f0 <satp_physical>
    cprintf("satp virtual address: 0xffffffffc0204000\n");
ffffffffc0200ac4:	e88ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("satp physical address: 0x0000000080204000\n");
ffffffffc0200ac8:	00001517          	auipc	a0,0x1
ffffffffc0200acc:	27050513          	addi	a0,a0,624 # ffffffffc0201d38 <best_fit_pmm_manager+0x190>
ffffffffc0200ad0:	e7cff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200ad4:	6442                	ld	s0,16(sp)
ffffffffc0200ad6:	60e2                	ld	ra,24(sp)
ffffffffc0200ad8:	64a2                	ld	s1,8(sp)
ffffffffc0200ada:	6902                	ld	s2,0(sp)
ffffffffc0200adc:	6105                	addi	sp,sp,32
    slub_check();
ffffffffc0200ade:	ae41                	j	ffffffffc0200e6e <slub_check>
    npage = maxpa / PGSIZE;
ffffffffc0200ae0:	c8000637          	lui	a2,0xc8000
ffffffffc0200ae4:	b73d                	j	ffffffffc0200a12 <pmm_init+0x76>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200ae6:	6705                	lui	a4,0x1
ffffffffc0200ae8:	177d                	addi	a4,a4,-1
ffffffffc0200aea:	96ba                	add	a3,a3,a4
ffffffffc0200aec:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200aee:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200af2:	02c7f063          	bgeu	a5,a2,ffffffffc0200b12 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200af6:	6090                	ld	a2,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200af8:	fff80737          	lui	a4,0xfff80
ffffffffc0200afc:	973e                	add	a4,a4,a5
ffffffffc0200afe:	00271793          	slli	a5,a4,0x2
ffffffffc0200b02:	97ba                	add	a5,a5,a4
ffffffffc0200b04:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200b06:	8d95                	sub	a1,a1,a3
ffffffffc0200b08:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200b0a:	81b1                	srli	a1,a1,0xc
ffffffffc0200b0c:	953e                	add	a0,a0,a5
ffffffffc0200b0e:	9702                	jalr	a4
}
ffffffffc0200b10:	bf95                	j	ffffffffc0200a84 <pmm_init+0xe8>
        panic("pa2page called with invalid pa");
ffffffffc0200b12:	00001617          	auipc	a2,0x1
ffffffffc0200b16:	1a660613          	addi	a2,a2,422 # ffffffffc0201cb8 <best_fit_pmm_manager+0x110>
ffffffffc0200b1a:	06a00593          	li	a1,106
ffffffffc0200b1e:	00001517          	auipc	a0,0x1
ffffffffc0200b22:	1ba50513          	addi	a0,a0,442 # ffffffffc0201cd8 <best_fit_pmm_manager+0x130>
ffffffffc0200b26:	e9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200b2a:	00001617          	auipc	a2,0x1
ffffffffc0200b2e:	16660613          	addi	a2,a2,358 # ffffffffc0201c90 <best_fit_pmm_manager+0xe8>
ffffffffc0200b32:	05f00593          	li	a1,95
ffffffffc0200b36:	00001517          	auipc	a0,0x1
ffffffffc0200b3a:	0e250513          	addi	a0,a0,226 # ffffffffc0201c18 <best_fit_pmm_manager+0x70>
ffffffffc0200b3e:	e84ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200b42:	00001617          	auipc	a2,0x1
ffffffffc0200b46:	0b660613          	addi	a2,a2,182 # ffffffffc0201bf8 <best_fit_pmm_manager+0x50>
ffffffffc0200b4a:	04500593          	li	a1,69
ffffffffc0200b4e:	00001517          	auipc	a0,0x1
ffffffffc0200b52:	0ca50513          	addi	a0,a0,202 # ffffffffc0201c18 <best_fit_pmm_manager+0x70>
ffffffffc0200b56:	e6cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200b5a:	00001617          	auipc	a2,0x1
ffffffffc0200b5e:	13660613          	addi	a2,a2,310 # ffffffffc0201c90 <best_fit_pmm_manager+0xe8>
ffffffffc0200b62:	07000593          	li	a1,112
ffffffffc0200b66:	00001517          	auipc	a0,0x1
ffffffffc0200b6a:	0b250513          	addi	a0,a0,178 # ffffffffc0201c18 <best_fit_pmm_manager+0x70>
ffffffffc0200b6e:	e54ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200b72 <kmem_cache_alloc>:
    struct Slab *new_slab;
    struct Slab *slab;
    list_entry_t *le;
    void *obj;
    // 1. 遍历Slab列表，寻找有空闲对象的Slab
    list_for_each(le, &(cache->slab_list)) {
ffffffffc0200b72:	6d1c                	ld	a5,24(a0)
void *kmem_cache_alloc(struct kmem_cache *cache) {
ffffffffc0200b74:	1101                	addi	sp,sp,-32
ffffffffc0200b76:	e822                	sd	s0,16(sp)
ffffffffc0200b78:	e04a                	sd	s2,0(sp)
ffffffffc0200b7a:	ec06                	sd	ra,24(sp)
ffffffffc0200b7c:	e426                	sd	s1,8(sp)
    list_for_each(le, &(cache->slab_list)) {
ffffffffc0200b7e:	01050413          	addi	s0,a0,16
void *kmem_cache_alloc(struct kmem_cache *cache) {
ffffffffc0200b82:	892a                	mv	s2,a0
    list_for_each(le, &(cache->slab_list)) {
ffffffffc0200b84:	00879663          	bne	a5,s0,ffffffffc0200b90 <kmem_cache_alloc+0x1e>
ffffffffc0200b88:	a03d                	j	ffffffffc0200bb6 <kmem_cache_alloc+0x44>
ffffffffc0200b8a:	679c                	ld	a5,8(a5)
ffffffffc0200b8c:	02878563          	beq	a5,s0,ffffffffc0200bb6 <kmem_cache_alloc+0x44>
        //找Slab结构体
        slab = to_struct(le, struct Slab, slab_link);
        
        if (slab->free_count > 0) {
ffffffffc0200b90:	4f98                	lw	a4,24(a5)
ffffffffc0200b92:	df65                	beqz	a4,ffffffffc0200b8a <kmem_cache_alloc+0x18>
            obj = slab->freelist;
ffffffffc0200b94:	6b84                	ld	s1,16(a5)
            // 将freelist指向下一个空闲对象
            slab->freelist = *((void **)obj); 
            slab->free_count--;
            cache->ref_count++;
ffffffffc0200b96:	02c92683          	lw	a3,44(s2)
            slab->free_count--;
ffffffffc0200b9a:	377d                	addiw	a4,a4,-1
            slab->freelist = *((void **)obj); 
ffffffffc0200b9c:	6090                	ld	a2,0(s1)
            cache->ref_count++;
ffffffffc0200b9e:	2685                	addiw	a3,a3,1
            slab->free_count--;
ffffffffc0200ba0:	cf98                	sw	a4,24(a5)
            slab->freelist = *((void **)obj); 
ffffffffc0200ba2:	eb90                	sd	a2,16(a5)
            cache->ref_count++;
ffffffffc0200ba4:	02d92623          	sw	a3,44(s2)
    obj = new_slab->freelist;
    new_slab->freelist = *((void **)obj);
    new_slab->free_count--;
    cache->ref_count++;
    return obj;
}
ffffffffc0200ba8:	60e2                	ld	ra,24(sp)
ffffffffc0200baa:	6442                	ld	s0,16(sp)
ffffffffc0200bac:	6902                	ld	s2,0(sp)
ffffffffc0200bae:	8526                	mv	a0,s1
ffffffffc0200bb0:	64a2                	ld	s1,8(sp)
ffffffffc0200bb2:	6105                	addi	sp,sp,32
ffffffffc0200bb4:	8082                	ret

//创建一个新的 Slab

static struct Slab *slab_create(struct kmem_cache *cache) {
    // 向 Buddy System 申请 (物理页)
    struct Page *page = alloc_pages(cache->slab_pages);
ffffffffc0200bb6:	02093503          	ld	a0,32(s2)
ffffffffc0200bba:	dbfff0ef          	jal	ra,ffffffffc0200978 <alloc_pages>
ffffffffc0200bbe:	84aa                	mv	s1,a0
    if (page == NULL) {
ffffffffc0200bc0:	c145                	beqz	a0,ffffffffc0200c60 <kmem_cache_alloc+0xee>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bc2:	00005797          	auipc	a5,0x5
ffffffffc0200bc6:	51e7b783          	ld	a5,1310(a5) # ffffffffc02060e0 <pages>
ffffffffc0200bca:	40f507b3          	sub	a5,a0,a5
ffffffffc0200bce:	00002717          	auipc	a4,0x2
ffffffffc0200bd2:	83a73703          	ld	a4,-1990(a4) # ffffffffc0202408 <nbase+0x8>
ffffffffc0200bd6:	878d                	srai	a5,a5,0x3
ffffffffc0200bd8:	02e787b3          	mul	a5,a5,a4
ffffffffc0200bdc:	00002717          	auipc	a4,0x2
ffffffffc0200be0:	82473703          	ld	a4,-2012(a4) # ffffffffc0202400 <nbase>
    uintptr_t pa = page2pa(page);
    void *va = KADDR(pa);
    // 初始化 Slab 结构体
    struct Slab *slab = (struct Slab *)va;
    slab->cache = cache;
    slab->free_count = cache->objects_per_slab;
ffffffffc0200be4:	02892503          	lw	a0,40(s2)
    void *va = KADDR(pa);
ffffffffc0200be8:	00005597          	auipc	a1,0x5
ffffffffc0200bec:	5185b583          	ld	a1,1304(a1) # ffffffffc0206100 <va_pa_offset>
    new_slab->free_count--;
ffffffffc0200bf0:	fff5081b          	addiw	a6,a0,-1
ffffffffc0200bf4:	8342                	mv	t1,a6
ffffffffc0200bf6:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bf8:	07b2                	slli	a5,a5,0xc
    void *va = KADDR(pa);
ffffffffc0200bfa:	95be                	add	a1,a1,a5
    slab->cache = cache;
ffffffffc0200bfc:	0125b023          	sd	s2,0(a1)
    slab->free_count = cache->objects_per_slab;
ffffffffc0200c00:	d188                	sw	a0,32(a1)
    
    // 剩余空间串联成 freelist
    size_t slab_metadata_size = ALIGN_UP(sizeof(struct Slab), sizeof(void *));
    void *obj_start = (char *)va + slab_metadata_size;
ffffffffc0200c02:	02858493          	addi	s1,a1,40
    
    char *current_obj = obj_start;
    for (unsigned int i = 0; i < cache->objects_per_slab; i++) {
ffffffffc0200c06:	c505                	beqz	a0,ffffffffc0200c2e <kmem_cache_alloc+0xbc>
                         ? NULL // 最后一个对象，指向NULL
                         : (current_obj + cache->object_size);
        
        *((void **)current_obj) = next_obj;
        
        current_obj += cache->object_size;
ffffffffc0200c08:	00893883          	ld	a7,8(s2)
    char *current_obj = obj_start;
ffffffffc0200c0c:	8726                	mv	a4,s1
    for (unsigned int i = 0; i < cache->objects_per_slab; i++) {
ffffffffc0200c0e:	4781                	li	a5,0
ffffffffc0200c10:	a029                	j	ffffffffc0200c1a <kmem_cache_alloc+0xa8>
        *((void **)current_obj) = next_obj;
ffffffffc0200c12:	e214                	sd	a3,0(a2)
    for (unsigned int i = 0; i < cache->objects_per_slab; i++) {
ffffffffc0200c14:	2785                	addiw	a5,a5,1
ffffffffc0200c16:	00f50c63          	beq	a0,a5,ffffffffc0200c2e <kmem_cache_alloc+0xbc>
        void *next_obj = (i == cache->objects_per_slab - 1) 
ffffffffc0200c1a:	863a                	mv	a2,a4
                         : (current_obj + cache->object_size);
ffffffffc0200c1c:	9746                	add	a4,a4,a7
ffffffffc0200c1e:	86ba                	mv	a3,a4
ffffffffc0200c20:	fef819e3          	bne	a6,a5,ffffffffc0200c12 <kmem_cache_alloc+0xa0>
ffffffffc0200c24:	4681                	li	a3,0
        *((void **)current_obj) = next_obj;
ffffffffc0200c26:	e214                	sd	a3,0(a2)
    for (unsigned int i = 0; i < cache->objects_per_slab; i++) {
ffffffffc0200c28:	2785                	addiw	a5,a5,1
ffffffffc0200c2a:	fef518e3          	bne	a0,a5,ffffffffc0200c1a <kmem_cache_alloc+0xa8>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c2e:	01893703          	ld	a4,24(s2)
    }
    
    slab->freelist = obj_start;
    list_add(&(cache->slab_list), &(slab->slab_link));
ffffffffc0200c32:	00858693          	addi	a3,a1,8
    cache->ref_count++;
ffffffffc0200c36:	02c92783          	lw	a5,44(s2)
    prev->next = next->prev = elm;
ffffffffc0200c3a:	e314                	sd	a3,0(a4)
ffffffffc0200c3c:	00d93c23          	sd	a3,24(s2)
    new_slab->freelist = *((void **)obj);
ffffffffc0200c40:	7594                	ld	a3,40(a1)
    elm->prev = prev;
ffffffffc0200c42:	e580                	sd	s0,8(a1)
}
ffffffffc0200c44:	60e2                	ld	ra,24(sp)
ffffffffc0200c46:	6442                	ld	s0,16(sp)
    elm->next = next;
ffffffffc0200c48:	e998                	sd	a4,16(a1)
    new_slab->freelist = *((void **)obj);
ffffffffc0200c4a:	ed94                	sd	a3,24(a1)
    new_slab->free_count--;
ffffffffc0200c4c:	0265a023          	sw	t1,32(a1)
    cache->ref_count++;
ffffffffc0200c50:	2785                	addiw	a5,a5,1
ffffffffc0200c52:	02f92623          	sw	a5,44(s2)
}
ffffffffc0200c56:	8526                	mv	a0,s1
ffffffffc0200c58:	6902                	ld	s2,0(sp)
ffffffffc0200c5a:	64a2                	ld	s1,8(sp)
ffffffffc0200c5c:	6105                	addi	sp,sp,32
ffffffffc0200c5e:	8082                	ret
        cprintf("SLUB: '%s' failed to create new slab (OOM)\n", cache->name);
ffffffffc0200c60:	00093583          	ld	a1,0(s2)
ffffffffc0200c64:	00001517          	auipc	a0,0x1
ffffffffc0200c68:	13c50513          	addi	a0,a0,316 # ffffffffc0201da0 <best_fit_pmm_manager+0x1f8>
ffffffffc0200c6c:	ce0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200c70:	bf25                	j	ffffffffc0200ba8 <kmem_cache_alloc+0x36>

ffffffffc0200c72 <kmem_cache_free>:
    if (obj == NULL) {
ffffffffc0200c72:	c5bd                	beqz	a1,ffffffffc0200ce0 <kmem_cache_free+0x6e>
void kmem_cache_free(struct kmem_cache *cache, void *obj) {
ffffffffc0200c74:	1141                	addi	sp,sp,-16
ffffffffc0200c76:	e406                	sd	ra,8(sp)
}

//通过对象指针找到它所属的 Slab
static struct Slab *find_slab_by_object(void *obj) {
    //将对象指针转为物理地址
    uintptr_t pa = PADDR(obj);
ffffffffc0200c78:	c02007b7          	lui	a5,0xc0200
ffffffffc0200c7c:	08f5ef63          	bltu	a1,a5,ffffffffc0200d1a <kmem_cache_free+0xa8>
ffffffffc0200c80:	00005697          	auipc	a3,0x5
ffffffffc0200c84:	4806b683          	ld	a3,1152(a3) # ffffffffc0206100 <va_pa_offset>
ffffffffc0200c88:	40d58733          	sub	a4,a1,a3
    if (PPN(pa) >= npage) {
ffffffffc0200c8c:	8331                	srli	a4,a4,0xc
ffffffffc0200c8e:	00005797          	auipc	a5,0x5
ffffffffc0200c92:	44a7b783          	ld	a5,1098(a5) # ffffffffc02060d8 <npage>
ffffffffc0200c96:	06f77663          	bgeu	a4,a5,ffffffffc0200d02 <kmem_cache_free+0x90>
    return &pages[PPN(pa) - nbase];
ffffffffc0200c9a:	00001617          	auipc	a2,0x1
ffffffffc0200c9e:	76663603          	ld	a2,1894(a2) # ffffffffc0202400 <nbase>
ffffffffc0200ca2:	8f11                	sub	a4,a4,a2
ffffffffc0200ca4:	00271793          	slli	a5,a4,0x2
ffffffffc0200ca8:	97ba                	add	a5,a5,a4
ffffffffc0200caa:	078e                	slli	a5,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cac:	878d                	srai	a5,a5,0x3
ffffffffc0200cae:	00001717          	auipc	a4,0x1
ffffffffc0200cb2:	75a73703          	ld	a4,1882(a4) # ffffffffc0202408 <nbase+0x8>
ffffffffc0200cb6:	02e787b3          	mul	a5,a5,a4
ffffffffc0200cba:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cbc:	07b2                	slli	a5,a5,0xc
    
    // 找物理页的起始物理地址
    uintptr_t page_pa = page2pa(page); 

    // 将页的起始物理地址转为内核虚拟地址
    void *slab_va = KADDR(page_pa);
ffffffffc0200cbe:	97b6                	add	a5,a5,a3
    assert(slab != NULL && slab->cache == cache); 
ffffffffc0200cc0:	c38d                	beqz	a5,ffffffffc0200ce2 <kmem_cache_free+0x70>
ffffffffc0200cc2:	6398                	ld	a4,0(a5)
ffffffffc0200cc4:	00a71f63          	bne	a4,a0,ffffffffc0200ce2 <kmem_cache_free+0x70>
    slab->free_count++;
ffffffffc0200cc8:	5390                	lw	a2,32(a5)
    *((void **)obj) = slab->freelist;
ffffffffc0200cca:	6f88                	ld	a0,24(a5)
    cache->ref_count--;
ffffffffc0200ccc:	5754                	lw	a3,44(a4)
}
ffffffffc0200cce:	60a2                	ld	ra,8(sp)
    *((void **)obj) = slab->freelist;
ffffffffc0200cd0:	e188                	sd	a0,0(a1)
    slab->free_count++;
ffffffffc0200cd2:	2605                	addiw	a2,a2,1
    slab->freelist = obj;
ffffffffc0200cd4:	ef8c                	sd	a1,24(a5)
    slab->free_count++;
ffffffffc0200cd6:	d390                	sw	a2,32(a5)
    cache->ref_count--;
ffffffffc0200cd8:	36fd                	addiw	a3,a3,-1
ffffffffc0200cda:	d754                	sw	a3,44(a4)
}
ffffffffc0200cdc:	0141                	addi	sp,sp,16
ffffffffc0200cde:	8082                	ret
ffffffffc0200ce0:	8082                	ret
    assert(slab != NULL && slab->cache == cache); 
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	0ee68693          	addi	a3,a3,238 # ffffffffc0201dd0 <best_fit_pmm_manager+0x228>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	e1660613          	addi	a2,a2,-490 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200cf2:	05e00593          	li	a1,94
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	09250513          	addi	a0,a0,146 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc0200cfe:	cc4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200d02:	00001617          	auipc	a2,0x1
ffffffffc0200d06:	fb660613          	addi	a2,a2,-74 # ffffffffc0201cb8 <best_fit_pmm_manager+0x110>
ffffffffc0200d0a:	06a00593          	li	a1,106
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	fca50513          	addi	a0,a0,-54 # ffffffffc0201cd8 <best_fit_pmm_manager+0x130>
ffffffffc0200d16:	cacff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t pa = PADDR(obj);
ffffffffc0200d1a:	86ae                	mv	a3,a1
ffffffffc0200d1c:	00001617          	auipc	a2,0x1
ffffffffc0200d20:	f7460613          	addi	a2,a2,-140 # ffffffffc0201c90 <best_fit_pmm_manager+0xe8>
ffffffffc0200d24:	08f00593          	li	a1,143
ffffffffc0200d28:	00001517          	auipc	a0,0x1
ffffffffc0200d2c:	06050513          	addi	a0,a0,96 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc0200d30:	c92ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d34 <kmem_cache_shrink>:
    return (struct Slab *)slab_va;
}


//收缩缓存，释放所有完全空闲的 Slab
void kmem_cache_shrink(struct kmem_cache *cache) {
ffffffffc0200d34:	715d                	addi	sp,sp,-80
ffffffffc0200d36:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200d38:	6d00                	ld	s0,24(a0)
ffffffffc0200d3a:	f44e                	sd	s3,40(sp)
ffffffffc0200d3c:	e486                	sd	ra,72(sp)
ffffffffc0200d3e:	fc26                	sd	s1,56(sp)
ffffffffc0200d40:	f84a                	sd	s2,48(sp)
ffffffffc0200d42:	f052                	sd	s4,32(sp)
ffffffffc0200d44:	ec56                	sd	s5,24(sp)
ffffffffc0200d46:	e85a                	sd	s6,16(sp)
ffffffffc0200d48:	e45e                	sd	s7,8(sp)
    list_entry_t *le = list_next(&(cache->slab_list));
    while (le != &(cache->slab_list)) {
ffffffffc0200d4a:	01050993          	addi	s3,a0,16
ffffffffc0200d4e:	03340e63          	beq	s0,s3,ffffffffc0200d8a <kmem_cache_shrink+0x56>
ffffffffc0200d52:	892a                	mv	s2,a0
        // 检查这个Slab是否完全空闲
        if (slab->free_count == cache->objects_per_slab) {
            // 从缓存的Slab列表中移除该Slab
            list_del(le);
            //将Slab对应的物理页归还给 Buddy System
            struct Page *page = pa2page(PADDR(slab)); 
ffffffffc0200d54:	c02004b7          	lui	s1,0xc0200
ffffffffc0200d58:	00005b97          	auipc	s7,0x5
ffffffffc0200d5c:	3a8b8b93          	addi	s7,s7,936 # ffffffffc0206100 <va_pa_offset>
    if (PPN(pa) >= npage) {
ffffffffc0200d60:	00005b17          	auipc	s6,0x5
ffffffffc0200d64:	378b0b13          	addi	s6,s6,888 # ffffffffc02060d8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d68:	00005a97          	auipc	s5,0x5
ffffffffc0200d6c:	378a8a93          	addi	s5,s5,888 # ffffffffc02060e0 <pages>
ffffffffc0200d70:	00001a17          	auipc	s4,0x1
ffffffffc0200d74:	690a0a13          	addi	s4,s4,1680 # ffffffffc0202400 <nbase>
        if (slab->free_count == cache->objects_per_slab) {
ffffffffc0200d78:	4c18                	lw	a4,24(s0)
ffffffffc0200d7a:	02892783          	lw	a5,40(s2)
ffffffffc0200d7e:	86a2                	mv	a3,s0
ffffffffc0200d80:	6400                	ld	s0,8(s0)
ffffffffc0200d82:	00f70f63          	beq	a4,a5,ffffffffc0200da0 <kmem_cache_shrink+0x6c>
    while (le != &(cache->slab_list)) {
ffffffffc0200d86:	ff3419e3          	bne	s0,s3,ffffffffc0200d78 <kmem_cache_shrink+0x44>
            free_pages(page, cache->slab_pages); 
        }
        le = next;
    }
}
ffffffffc0200d8a:	60a6                	ld	ra,72(sp)
ffffffffc0200d8c:	6406                	ld	s0,64(sp)
ffffffffc0200d8e:	74e2                	ld	s1,56(sp)
ffffffffc0200d90:	7942                	ld	s2,48(sp)
ffffffffc0200d92:	79a2                	ld	s3,40(sp)
ffffffffc0200d94:	7a02                	ld	s4,32(sp)
ffffffffc0200d96:	6ae2                	ld	s5,24(sp)
ffffffffc0200d98:	6b42                	ld	s6,16(sp)
ffffffffc0200d9a:	6ba2                	ld	s7,8(sp)
ffffffffc0200d9c:	6161                	addi	sp,sp,80
ffffffffc0200d9e:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200da0:	629c                	ld	a5,0(a3)
        struct Slab *slab = to_struct(le, struct Slab, slab_link);
ffffffffc0200da2:	16e1                	addi	a3,a3,-8
    prev->next = next;
ffffffffc0200da4:	e780                	sd	s0,8(a5)
    next->prev = prev;
ffffffffc0200da6:	e01c                	sd	a5,0(s0)
            struct Page *page = pa2page(PADDR(slab)); 
ffffffffc0200da8:	0296eb63          	bltu	a3,s1,ffffffffc0200dde <kmem_cache_shrink+0xaa>
ffffffffc0200dac:	000bb703          	ld	a4,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0200db0:	000b3783          	ld	a5,0(s6)
ffffffffc0200db4:	8e99                	sub	a3,a3,a4
ffffffffc0200db6:	82b1                	srli	a3,a3,0xc
ffffffffc0200db8:	02f6ff63          	bgeu	a3,a5,ffffffffc0200df6 <kmem_cache_shrink+0xc2>
    return &pages[PPN(pa) - nbase];
ffffffffc0200dbc:	000a3783          	ld	a5,0(s4)
ffffffffc0200dc0:	000ab503          	ld	a0,0(s5)
            free_pages(page, cache->slab_pages); 
ffffffffc0200dc4:	02093583          	ld	a1,32(s2)
ffffffffc0200dc8:	8e9d                	sub	a3,a3,a5
ffffffffc0200dca:	00269793          	slli	a5,a3,0x2
ffffffffc0200dce:	96be                	add	a3,a3,a5
ffffffffc0200dd0:	068e                	slli	a3,a3,0x3
ffffffffc0200dd2:	9536                	add	a0,a0,a3
ffffffffc0200dd4:	bb1ff0ef          	jal	ra,ffffffffc0200984 <free_pages>
    while (le != &(cache->slab_list)) {
ffffffffc0200dd8:	fb3410e3          	bne	s0,s3,ffffffffc0200d78 <kmem_cache_shrink+0x44>
ffffffffc0200ddc:	b77d                	j	ffffffffc0200d8a <kmem_cache_shrink+0x56>
            struct Page *page = pa2page(PADDR(slab)); 
ffffffffc0200dde:	00001617          	auipc	a2,0x1
ffffffffc0200de2:	eb260613          	addi	a2,a2,-334 # ffffffffc0201c90 <best_fit_pmm_manager+0xe8>
ffffffffc0200de6:	0aa00593          	li	a1,170
ffffffffc0200dea:	00001517          	auipc	a0,0x1
ffffffffc0200dee:	f9e50513          	addi	a0,a0,-98 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc0200df2:	bd0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200df6:	00001617          	auipc	a2,0x1
ffffffffc0200dfa:	ec260613          	addi	a2,a2,-318 # ffffffffc0201cb8 <best_fit_pmm_manager+0x110>
ffffffffc0200dfe:	06a00593          	li	a1,106
ffffffffc0200e02:	00001517          	auipc	a0,0x1
ffffffffc0200e06:	ed650513          	addi	a0,a0,-298 # ffffffffc0201cd8 <best_fit_pmm_manager+0x130>
ffffffffc0200e0a:	bb8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e0e <kmem_cache_destroy>:

//销毁一个 kmem_cache
void kmem_cache_destroy(struct kmem_cache *cache) {

    if (cache->ref_count > 0) {
ffffffffc0200e0e:	5550                	lw	a2,44(a0)
void kmem_cache_destroy(struct kmem_cache *cache) {
ffffffffc0200e10:	1141                	addi	sp,sp,-16
ffffffffc0200e12:	e022                	sd	s0,0(sp)
ffffffffc0200e14:	e406                	sd	ra,8(sp)
ffffffffc0200e16:	842a                	mv	s0,a0
    if (cache->ref_count > 0) {
ffffffffc0200e18:	e20d                	bnez	a2,ffffffffc0200e3a <kmem_cache_destroy+0x2c>
        cprintf("ERROR: attempt to destroy cache '%s' with ref_count %u\n", cache->name, cache->ref_count);
        return;
    }
    kmem_cache_shrink(cache);
ffffffffc0200e1a:	f1bff0ef          	jal	ra,ffffffffc0200d34 <kmem_cache_shrink>
    assert(list_empty(&(cache->slab_list)));
ffffffffc0200e1e:	6c18                	ld	a4,24(s0)
ffffffffc0200e20:	01040793          	addi	a5,s0,16
ffffffffc0200e24:	02f71563          	bne	a4,a5,ffffffffc0200e4e <kmem_cache_destroy+0x40>
    cache->name = "DESTROYED";
ffffffffc0200e28:	00001797          	auipc	a5,0x1
ffffffffc0200e2c:	02878793          	addi	a5,a5,40 # ffffffffc0201e50 <best_fit_pmm_manager+0x2a8>
}
ffffffffc0200e30:	60a2                	ld	ra,8(sp)
    cache->name = "DESTROYED";
ffffffffc0200e32:	e01c                	sd	a5,0(s0)
}
ffffffffc0200e34:	6402                	ld	s0,0(sp)
ffffffffc0200e36:	0141                	addi	sp,sp,16
ffffffffc0200e38:	8082                	ret
ffffffffc0200e3a:	6402                	ld	s0,0(sp)
        cprintf("ERROR: attempt to destroy cache '%s' with ref_count %u\n", cache->name, cache->ref_count);
ffffffffc0200e3c:	610c                	ld	a1,0(a0)
}
ffffffffc0200e3e:	60a2                	ld	ra,8(sp)
        cprintf("ERROR: attempt to destroy cache '%s' with ref_count %u\n", cache->name, cache->ref_count);
ffffffffc0200e40:	00001517          	auipc	a0,0x1
ffffffffc0200e44:	fb850513          	addi	a0,a0,-72 # ffffffffc0201df8 <best_fit_pmm_manager+0x250>
}
ffffffffc0200e48:	0141                	addi	sp,sp,16
        cprintf("ERROR: attempt to destroy cache '%s' with ref_count %u\n", cache->name, cache->ref_count);
ffffffffc0200e4a:	b02ff06f          	j	ffffffffc020014c <cprintf>
    assert(list_empty(&(cache->slab_list)));
ffffffffc0200e4e:	00001697          	auipc	a3,0x1
ffffffffc0200e52:	fe268693          	addi	a3,a3,-30 # ffffffffc0201e30 <best_fit_pmm_manager+0x288>
ffffffffc0200e56:	00001617          	auipc	a2,0x1
ffffffffc0200e5a:	caa60613          	addi	a2,a2,-854 # ffffffffc0201b00 <etext+0x26e>
ffffffffc0200e5e:	0b900593          	li	a1,185
ffffffffc0200e62:	00001517          	auipc	a0,0x1
ffffffffc0200e66:	f2650513          	addi	a0,a0,-218 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc0200e6a:	b58ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e6e <slub_check>:
static struct kmem_cache cache_128;

//  （可选）用于测试 ctor 的辅助函数 


void slub_check(void) {
ffffffffc0200e6e:	7159                	addi	sp,sp,-112
ffffffffc0200e70:	f0a2                	sd	s0,96(sp)
ffffffffc0200e72:	eca6                	sd	s1,88(sp)
ffffffffc0200e74:	e4ce                	sd	s3,72(sp)
ffffffffc0200e76:	fc56                	sd	s5,56(sp)
ffffffffc0200e78:	f85a                	sd	s6,48(sp)
ffffffffc0200e7a:	f486                	sd	ra,104(sp)
ffffffffc0200e7c:	e8ca                	sd	s2,80(sp)
ffffffffc0200e7e:	e0d2                	sd	s4,64(sp)
ffffffffc0200e80:	f45e                	sd	s7,40(sp)
ffffffffc0200e82:	f062                	sd	s8,32(sp)
ffffffffc0200e84:	ec66                	sd	s9,24(sp)
    cache->name = name;
ffffffffc0200e86:	00005417          	auipc	s0,0x5
ffffffffc0200e8a:	1da40413          	addi	s0,s0,474 # ffffffffc0206060 <cache_32>
    elm->prev = elm->next = elm;
ffffffffc0200e8e:	00005717          	auipc	a4,0x5
ffffffffc0200e92:	1e270713          	addi	a4,a4,482 # ffffffffc0206070 <cache_32+0x10>
ffffffffc0200e96:	00005497          	auipc	s1,0x5
ffffffffc0200e9a:	1fa48493          	addi	s1,s1,506 # ffffffffc0206090 <cache_64>
ffffffffc0200e9e:	ec18                	sd	a4,24(s0)
ffffffffc0200ea0:	e818                	sd	a4,16(s0)
ffffffffc0200ea2:	00001717          	auipc	a4,0x1
ffffffffc0200ea6:	fce70713          	addi	a4,a4,-50 # ffffffffc0201e70 <best_fit_pmm_manager+0x2c8>
ffffffffc0200eaa:	e098                	sd	a4,0(s1)
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200eac:	04000713          	li	a4,64
    cache->name = name;
ffffffffc0200eb0:	00001697          	auipc	a3,0x1
ffffffffc0200eb4:	fb068693          	addi	a3,a3,-80 # ffffffffc0201e60 <best_fit_pmm_manager+0x2b8>
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200eb8:	e498                	sd	a4,8(s1)
    cache->objects_per_slab = count;
ffffffffc0200eba:	03f00713          	li	a4,63
    cache->name = name;
ffffffffc0200ebe:	00005a97          	auipc	s5,0x5
ffffffffc0200ec2:	172a8a93          	addi	s5,s5,370 # ffffffffc0206030 <cache_128>
ffffffffc0200ec6:	e014                	sd	a3,0(s0)
    cache->objects_per_slab = count;
ffffffffc0200ec8:	f498                	sd	a4,40(s1)
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200eca:	02000693          	li	a3,32
    cache->name = name;
ffffffffc0200ece:	00001717          	auipc	a4,0x1
ffffffffc0200ed2:	fb270713          	addi	a4,a4,-78 # ffffffffc0201e80 <best_fit_pmm_manager+0x2d8>
ffffffffc0200ed6:	00005b17          	auipc	s6,0x5
ffffffffc0200eda:	1cab0b13          	addi	s6,s6,458 # ffffffffc02060a0 <cache_64+0x10>
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200ede:	e414                	sd	a3,8(s0)
    cache->name = name;
ffffffffc0200ee0:	00eab023          	sd	a4,0(s5)
    cache->objects_per_slab = count;
ffffffffc0200ee4:	07e00693          	li	a3,126
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200ee8:	08000713          	li	a4,128
ffffffffc0200eec:	00005797          	auipc	a5,0x5
ffffffffc0200ef0:	15478793          	addi	a5,a5,340 # ffffffffc0206040 <cache_128+0x10>
    cache->slab_pages = 1;
ffffffffc0200ef4:	4985                	li	s3,1
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
ffffffffc0200ef6:	00eab423          	sd	a4,8(s5)
void slub_check(void) {
ffffffffc0200efa:	81010113          	addi	sp,sp,-2032
    cache->objects_per_slab = count;
ffffffffc0200efe:	477d                	li	a4,31

    //  T1: 初始化 和 ctor 测试 
    kmem_cache_init(&cache_32, "cache_32", 32);
    kmem_cache_init(&cache_64, "cache_64", 64);
    kmem_cache_init(&cache_128, "cache_128", 128);
    cprintf("  T1: Cache initialization passed.\n");
ffffffffc0200f00:	00001517          	auipc	a0,0x1
ffffffffc0200f04:	f9050513          	addi	a0,a0,-112 # ffffffffc0201e90 <best_fit_pmm_manager+0x2e8>
    cache->objects_per_slab = count;
ffffffffc0200f08:	f414                	sd	a3,40(s0)
ffffffffc0200f0a:	0164bc23          	sd	s6,24(s1)
ffffffffc0200f0e:	0164b823          	sd	s6,16(s1)
ffffffffc0200f12:	00fabc23          	sd	a5,24(s5)
ffffffffc0200f16:	00fab823          	sd	a5,16(s5)
    cache->slab_pages = 1;
ffffffffc0200f1a:	03343023          	sd	s3,32(s0)
ffffffffc0200f1e:	0334b023          	sd	s3,32(s1)
ffffffffc0200f22:	033ab023          	sd	s3,32(s5)
    cache->objects_per_slab = count;
ffffffffc0200f26:	02eab423          	sd	a4,40(s5)
    cprintf("  T1: Cache initialization passed.\n");
ffffffffc0200f2a:	a22ff0ef          	jal	ra,ffffffffc020014c <cprintf>

    //  T2: 基本分配/释放/Ref_Count/Ctor 测试 
    assert(cache_32.ref_count == 0);
ffffffffc0200f2e:	545c                	lw	a5,44(s0)
ffffffffc0200f30:	2a079763          	bnez	a5,ffffffffc02011de <slub_check+0x370>

    obj_a = kmem_cache_alloc(&cache_32);
ffffffffc0200f34:	8522                	mv	a0,s0
ffffffffc0200f36:	c3dff0ef          	jal	ra,ffffffffc0200b72 <kmem_cache_alloc>
ffffffffc0200f3a:	892a                	mv	s2,a0
    assert(obj_a != NULL);
ffffffffc0200f3c:	28050163          	beqz	a0,ffffffffc02011be <slub_check+0x350>
    assert(cache_32.ref_count == 1); // 检查 ref_count 增加
ffffffffc0200f40:	545c                	lw	a5,44(s0)
ffffffffc0200f42:	25379e63          	bne	a5,s3,ffffffffc020119e <slub_check+0x330>
    
    kmem_cache_free(&cache_32, obj_a);
ffffffffc0200f46:	85aa                	mv	a1,a0
ffffffffc0200f48:	8522                	mv	a0,s0
ffffffffc0200f4a:	d29ff0ef          	jal	ra,ffffffffc0200c72 <kmem_cache_free>
    assert(cache_32.ref_count == 0); // 检查 ref_count 减少
ffffffffc0200f4e:	545c                	lw	a5,44(s0)
ffffffffc0200f50:	22079763          	bnez	a5,ffffffffc020117e <slub_check+0x310>
    
    cprintf("  T2: Alloc/Free/Ref_Count/Ctor passed.\n");
ffffffffc0200f54:	00001517          	auipc	a0,0x1
ffffffffc0200f58:	fa450513          	addi	a0,a0,-92 # ffffffffc0201ef8 <best_fit_pmm_manager+0x350>
ffffffffc0200f5c:	9f0ff0ef          	jal	ra,ffffffffc020014c <cprintf>

    //  T3: 对象复用 (LIFO Freelist) 测试 
    obj_b = kmem_cache_alloc(&cache_32);
ffffffffc0200f60:	8522                	mv	a0,s0
ffffffffc0200f62:	c11ff0ef          	jal	ra,ffffffffc0200b72 <kmem_cache_alloc>
    assert(obj_b == obj_a); // 检查是否复用了刚释放的对象
ffffffffc0200f66:	1ea91c63          	bne	s2,a0,ffffffffc020115e <slub_check+0x2f0>
    kmem_cache_free(&cache_32, obj_b);
ffffffffc0200f6a:	85ca                	mv	a1,s2
ffffffffc0200f6c:	8522                	mv	a0,s0
ffffffffc0200f6e:	d05ff0ef          	jal	ra,ffffffffc0200c72 <kmem_cache_free>
    
    cprintf("  T3: Object reuse (LIFO) passed.\n");
ffffffffc0200f72:	00001517          	auipc	a0,0x1
ffffffffc0200f76:	fc650513          	addi	a0,a0,-58 # ffffffffc0201f38 <best_fit_pmm_manager+0x390>
ffffffffc0200f7a:	9d2ff0ef          	jal	ra,ffffffffc020014c <cprintf>

    //  T4: 新 Slab 触发测试 
    initial_pages = nr_free_pages();
ffffffffc0200f7e:	a13ff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
    N = cache_64.objects_per_slab;
ffffffffc0200f82:	0284ac83          	lw	s9,40(s1)
    assert(N > 0 && N < 256);
ffffffffc0200f86:	0fe00793          	li	a5,254
    initial_pages = nr_free_pages();
ffffffffc0200f8a:	8baa                	mv	s7,a0
    N = cache_64.objects_per_slab;
ffffffffc0200f8c:	020c9c13          	slli	s8,s9,0x20
ffffffffc0200f90:	020c5c13          	srli	s8,s8,0x20
    assert(N > 0 && N < 256);
ffffffffc0200f94:	fffc0713          	addi	a4,s8,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0200f98:	1ae7e363          	bltu	a5,a4,ffffffffc020113e <slub_check+0x2d0>
ffffffffc0200f9c:	890a                	mv	s2,sp
ffffffffc0200f9e:	003c1a13          	slli	s4,s8,0x3
ffffffffc0200fa2:	014909b3          	add	s3,s2,s4
ffffffffc0200fa6:	844a                	mv	s0,s2
    
    // 分配 N 个对象 (应填满第一个 Slab)
    for (i = 0; i < N; i++) {
        objs[i] = kmem_cache_alloc(&cache_64);
ffffffffc0200fa8:	8526                	mv	a0,s1
ffffffffc0200faa:	bc9ff0ef          	jal	ra,ffffffffc0200b72 <kmem_cache_alloc>
ffffffffc0200fae:	e008                	sd	a0,0(s0)
        assert(objs[i] != NULL);
ffffffffc0200fb0:	16050763          	beqz	a0,ffffffffc020111e <slub_check+0x2b0>
    for (i = 0; i < N; i++) {
ffffffffc0200fb4:	0421                	addi	s0,s0,8
ffffffffc0200fb6:	ff3419e3          	bne	s0,s3,ffffffffc0200fa8 <slub_check+0x13a>
    }
    // 第一个 Slab 被创建，页数应 -1
    assert(nr_free_pages() == initial_pages - 1);
ffffffffc0200fba:	9d7ff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc0200fbe:	fffb8793          	addi	a5,s7,-1
ffffffffc0200fc2:	40f51e63          	bne	a0,a5,ffffffffc02013de <slub_check+0x570>
    assert(cache_64.ref_count == N);
ffffffffc0200fc6:	54dc                	lw	a5,44(s1)
ffffffffc0200fc8:	3f979b63          	bne	a5,s9,ffffffffc02013be <slub_check+0x550>
    
    // 分配第 N+1 个对象 (必须触发第二个 Slab)
    objs[N] = kmem_cache_alloc(&cache_64);
ffffffffc0200fcc:	00005517          	auipc	a0,0x5
ffffffffc0200fd0:	0c450513          	addi	a0,a0,196 # ffffffffc0206090 <cache_64>
ffffffffc0200fd4:	b9fff0ef          	jal	ra,ffffffffc0200b72 <kmem_cache_alloc>
ffffffffc0200fd8:	6785                	lui	a5,0x1
ffffffffc0200fda:	80078793          	addi	a5,a5,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0200fde:	978a                	add	a5,a5,sp
ffffffffc0200fe0:	97d2                	add	a5,a5,s4
ffffffffc0200fe2:	80a7b023          	sd	a0,-2048(a5)
    assert(objs[N] != NULL);
ffffffffc0200fe6:	3a050c63          	beqz	a0,ffffffffc020139e <slub_check+0x530>
    
    // 第二个 Slab 被创建，页数应 -2
    assert(nr_free_pages() == initial_pages - 2);
ffffffffc0200fea:	9a7ff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc0200fee:	ffeb8c93          	addi	s9,s7,-2
ffffffffc0200ff2:	39951663          	bne	a0,s9,ffffffffc020137e <slub_check+0x510>
    assert(cache_64.ref_count == N + 1);
ffffffffc0200ff6:	02c4e783          	lwu	a5,44(s1)
ffffffffc0200ffa:	0c05                	addi	s8,s8,1
ffffffffc0200ffc:	37879163          	bne	a5,s8,ffffffffc020135e <slub_check+0x4f0>
    
    cprintf("  T4: New Slab trigger (alloc_pages) passed.\n");
ffffffffc0201000:	00001517          	auipc	a0,0x1
ffffffffc0201004:	02050513          	addi	a0,a0,32 # ffffffffc0202020 <best_fit_pmm_manager+0x478>
ffffffffc0201008:	00890413          	addi	s0,s2,8
ffffffffc020100c:	014409b3          	add	s3,s0,s4
ffffffffc0201010:	93cff0ef          	jal	ra,ffffffffc020014c <cprintf>

    //  T5: 收缩 (Shrink) 测试 
    // 释放所有 N+1 个对象
    for (i = 0; i < N + 1; i++) {
        kmem_cache_free(&cache_64, objs[i]);
ffffffffc0201014:	00005a17          	auipc	s4,0x5
ffffffffc0201018:	07ca0a13          	addi	s4,s4,124 # ffffffffc0206090 <cache_64>
ffffffffc020101c:	a011                	j	ffffffffc0201020 <slub_check+0x1b2>
ffffffffc020101e:	0421                	addi	s0,s0,8
ffffffffc0201020:	00093583          	ld	a1,0(s2)
ffffffffc0201024:	8552                	mv	a0,s4
    for (i = 0; i < N + 1; i++) {
ffffffffc0201026:	8922                	mv	s2,s0
        kmem_cache_free(&cache_64, objs[i]);
ffffffffc0201028:	c4bff0ef          	jal	ra,ffffffffc0200c72 <kmem_cache_free>
    for (i = 0; i < N + 1; i++) {
ffffffffc020102c:	fe8999e3          	bne	s3,s0,ffffffffc020101e <slub_check+0x1b0>
    }
    assert(cache_64.ref_count == 0);
ffffffffc0201030:	54dc                	lw	a5,44(s1)
ffffffffc0201032:	30079663          	bnez	a5,ffffffffc020133e <slub_check+0x4d0>
    // 此时 Slabs 仍在缓存中，页数仍然是 -2
    assert(nr_free_pages() == initial_pages - 2);
ffffffffc0201036:	95bff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc020103a:	2eac9263          	bne	s9,a0,ffffffffc020131e <slub_check+0x4b0>
    
    // 执行收缩
    kmem_cache_shrink(&cache_64);
ffffffffc020103e:	00005517          	auipc	a0,0x5
ffffffffc0201042:	05250513          	addi	a0,a0,82 # ffffffffc0206090 <cache_64>
ffffffffc0201046:	cefff0ef          	jal	ra,ffffffffc0200d34 <kmem_cache_shrink>
    
    // 两个Slab都应被归还给 PMM
    assert(nr_free_pages() == initial_pages); 
ffffffffc020104a:	947ff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc020104e:	2b751863          	bne	a0,s7,ffffffffc02012fe <slub_check+0x490>
    assert(list_empty(&cache_64.slab_list));
ffffffffc0201052:	6c9c                	ld	a5,24(s1)
ffffffffc0201054:	29679563          	bne	a5,s6,ffffffffc02012de <slub_check+0x470>
    
    cprintf("  T5: Cache shrink (free_pages) passed.\n");
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	05850513          	addi	a0,a0,88 # ffffffffc02020b0 <best_fit_pmm_manager+0x508>
ffffffffc0201060:	8ecff0ef          	jal	ra,ffffffffc020014c <cprintf>

    //  T6: 安全销毁 (Destroy) 测试 
    initial_pages = nr_free_pages();
ffffffffc0201064:	92dff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc0201068:	842a                	mv	s0,a0
    o128 = kmem_cache_alloc(&cache_128);
ffffffffc020106a:	00005517          	auipc	a0,0x5
ffffffffc020106e:	fc650513          	addi	a0,a0,-58 # ffffffffc0206030 <cache_128>
ffffffffc0201072:	b01ff0ef          	jal	ra,ffffffffc0200b72 <kmem_cache_alloc>
    assert(cache_128.ref_count == 1);
ffffffffc0201076:	02caa983          	lw	s3,44(s5)
ffffffffc020107a:	4785                	li	a5,1
    o128 = kmem_cache_alloc(&cache_128);
ffffffffc020107c:	892a                	mv	s2,a0
    assert(cache_128.ref_count == 1);
ffffffffc020107e:	24f99063          	bne	s3,a5,ffffffffc02012be <slub_check+0x450>
    assert(nr_free_pages() == initial_pages - 1);
ffffffffc0201082:	90fff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc0201086:	fff40793          	addi	a5,s0,-1
ffffffffc020108a:	84aa                	mv	s1,a0
ffffffffc020108c:	20f51963          	bne	a0,a5,ffffffffc020129e <slub_check+0x430>

    // 尝试销毁一个正在使用的 cache (应该失败)
    kmem_cache_destroy(&cache_128);
ffffffffc0201090:	00005517          	auipc	a0,0x5
ffffffffc0201094:	fa050513          	addi	a0,a0,-96 # ffffffffc0206030 <cache_128>
ffffffffc0201098:	d77ff0ef          	jal	ra,ffffffffc0200e0e <kmem_cache_destroy>
    assert(cache_128.ref_count == 1); // 检查 ref_count 没变
ffffffffc020109c:	02caa783          	lw	a5,44(s5)
ffffffffc02010a0:	1d379f63          	bne	a5,s3,ffffffffc020127e <slub_check+0x410>
    assert(nr_free_pages() == initial_pages - 1); // 检查页数没变
ffffffffc02010a4:	8edff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc02010a8:	1aa49b63          	bne	s1,a0,ffffffffc020125e <slub_check+0x3f0>

    // 释放最后一个对象
    kmem_cache_free(&cache_128, o128);
ffffffffc02010ac:	85ca                	mv	a1,s2
ffffffffc02010ae:	00005517          	auipc	a0,0x5
ffffffffc02010b2:	f8250513          	addi	a0,a0,-126 # ffffffffc0206030 <cache_128>
ffffffffc02010b6:	bbdff0ef          	jal	ra,ffffffffc0200c72 <kmem_cache_free>
    assert(cache_128.ref_count == 0);
ffffffffc02010ba:	02caa783          	lw	a5,44(s5)
ffffffffc02010be:	18079063          	bnez	a5,ffffffffc020123e <slub_check+0x3d0>

    // 尝试销毁一个空闲的 cache (应该成功)
    kmem_cache_destroy(&cache_128);
ffffffffc02010c2:	00005517          	auipc	a0,0x5
ffffffffc02010c6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0206030 <cache_128>
ffffffffc02010ca:	d45ff0ef          	jal	ra,ffffffffc0200e0e <kmem_cache_destroy>
    // 检查页是否被归还
    assert(nr_free_pages() == initial_pages); 
ffffffffc02010ce:	8c3ff0ef          	jal	ra,ffffffffc0200990 <nr_free_pages>
ffffffffc02010d2:	14851663          	bne	a0,s0,ffffffffc020121e <slub_check+0x3b0>
    assert(strcmp(cache_128.name, "DESTROYED") == 0);
ffffffffc02010d6:	000ab503          	ld	a0,0(s5)
ffffffffc02010da:	00001597          	auipc	a1,0x1
ffffffffc02010de:	d7658593          	addi	a1,a1,-650 # ffffffffc0201e50 <best_fit_pmm_manager+0x2a8>
ffffffffc02010e2:	75a000ef          	jal	ra,ffffffffc020183c <strcmp>
ffffffffc02010e6:	10051c63          	bnez	a0,ffffffffc02011fe <slub_check+0x390>

    cprintf("  T6: Safe destroy (ref_count) passed.\n");
ffffffffc02010ea:	00001517          	auipc	a0,0x1
ffffffffc02010ee:	06650513          	addi	a0,a0,102 # ffffffffc0202150 <best_fit_pmm_manager+0x5a8>
ffffffffc02010f2:	85aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("SLUB allocator (our design) check finished successfully!\n");
ffffffffc02010f6:	7f010113          	addi	sp,sp,2032
ffffffffc02010fa:	70a6                	ld	ra,104(sp)
ffffffffc02010fc:	7406                	ld	s0,96(sp)
ffffffffc02010fe:	64e6                	ld	s1,88(sp)
ffffffffc0201100:	6946                	ld	s2,80(sp)
ffffffffc0201102:	69a6                	ld	s3,72(sp)
ffffffffc0201104:	6a06                	ld	s4,64(sp)
ffffffffc0201106:	7ae2                	ld	s5,56(sp)
ffffffffc0201108:	7b42                	ld	s6,48(sp)
ffffffffc020110a:	7ba2                	ld	s7,40(sp)
ffffffffc020110c:	7c02                	ld	s8,32(sp)
ffffffffc020110e:	6ce2                	ld	s9,24(sp)
    cprintf("SLUB allocator (our design) check finished successfully!\n");
ffffffffc0201110:	00001517          	auipc	a0,0x1
ffffffffc0201114:	06850513          	addi	a0,a0,104 # ffffffffc0202178 <best_fit_pmm_manager+0x5d0>
ffffffffc0201118:	6165                	addi	sp,sp,112
    cprintf("SLUB allocator (our design) check finished successfully!\n");
ffffffffc020111a:	832ff06f          	j	ffffffffc020014c <cprintf>
        assert(objs[i] != NULL);
ffffffffc020111e:	00001697          	auipc	a3,0x1
ffffffffc0201122:	e5a68693          	addi	a3,a3,-422 # ffffffffc0201f78 <best_fit_pmm_manager+0x3d0>
ffffffffc0201126:	00001617          	auipc	a2,0x1
ffffffffc020112a:	9da60613          	addi	a2,a2,-1574 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020112e:	0ec00593          	li	a1,236
ffffffffc0201132:	00001517          	auipc	a0,0x1
ffffffffc0201136:	c5650513          	addi	a0,a0,-938 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020113a:	888ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(N > 0 && N < 256);
ffffffffc020113e:	00001697          	auipc	a3,0x1
ffffffffc0201142:	e2268693          	addi	a3,a3,-478 # ffffffffc0201f60 <best_fit_pmm_manager+0x3b8>
ffffffffc0201146:	00001617          	auipc	a2,0x1
ffffffffc020114a:	9ba60613          	addi	a2,a2,-1606 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020114e:	0e700593          	li	a1,231
ffffffffc0201152:	00001517          	auipc	a0,0x1
ffffffffc0201156:	c3650513          	addi	a0,a0,-970 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020115a:	868ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(obj_b == obj_a); // 检查是否复用了刚释放的对象
ffffffffc020115e:	00001697          	auipc	a3,0x1
ffffffffc0201162:	dca68693          	addi	a3,a3,-566 # ffffffffc0201f28 <best_fit_pmm_manager+0x380>
ffffffffc0201166:	00001617          	auipc	a2,0x1
ffffffffc020116a:	99a60613          	addi	a2,a2,-1638 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020116e:	0df00593          	li	a1,223
ffffffffc0201172:	00001517          	auipc	a0,0x1
ffffffffc0201176:	c1650513          	addi	a0,a0,-1002 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020117a:	848ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_32.ref_count == 0); // 检查 ref_count 减少
ffffffffc020117e:	00001697          	auipc	a3,0x1
ffffffffc0201182:	d3a68693          	addi	a3,a3,-710 # ffffffffc0201eb8 <best_fit_pmm_manager+0x310>
ffffffffc0201186:	00001617          	auipc	a2,0x1
ffffffffc020118a:	97a60613          	addi	a2,a2,-1670 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020118e:	0d900593          	li	a1,217
ffffffffc0201192:	00001517          	auipc	a0,0x1
ffffffffc0201196:	bf650513          	addi	a0,a0,-1034 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020119a:	828ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_32.ref_count == 1); // 检查 ref_count 增加
ffffffffc020119e:	00001697          	auipc	a3,0x1
ffffffffc02011a2:	d4268693          	addi	a3,a3,-702 # ffffffffc0201ee0 <best_fit_pmm_manager+0x338>
ffffffffc02011a6:	00001617          	auipc	a2,0x1
ffffffffc02011aa:	95a60613          	addi	a2,a2,-1702 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02011ae:	0d600593          	li	a1,214
ffffffffc02011b2:	00001517          	auipc	a0,0x1
ffffffffc02011b6:	bd650513          	addi	a0,a0,-1066 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02011ba:	808ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(obj_a != NULL);
ffffffffc02011be:	00001697          	auipc	a3,0x1
ffffffffc02011c2:	d1268693          	addi	a3,a3,-750 # ffffffffc0201ed0 <best_fit_pmm_manager+0x328>
ffffffffc02011c6:	00001617          	auipc	a2,0x1
ffffffffc02011ca:	93a60613          	addi	a2,a2,-1734 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02011ce:	0d500593          	li	a1,213
ffffffffc02011d2:	00001517          	auipc	a0,0x1
ffffffffc02011d6:	bb650513          	addi	a0,a0,-1098 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02011da:	fe9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_32.ref_count == 0);
ffffffffc02011de:	00001697          	auipc	a3,0x1
ffffffffc02011e2:	cda68693          	addi	a3,a3,-806 # ffffffffc0201eb8 <best_fit_pmm_manager+0x310>
ffffffffc02011e6:	00001617          	auipc	a2,0x1
ffffffffc02011ea:	91a60613          	addi	a2,a2,-1766 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02011ee:	0d200593          	li	a1,210
ffffffffc02011f2:	00001517          	auipc	a0,0x1
ffffffffc02011f6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02011fa:	fc9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(strcmp(cache_128.name, "DESTROYED") == 0);
ffffffffc02011fe:	00001697          	auipc	a3,0x1
ffffffffc0201202:	f2268693          	addi	a3,a3,-222 # ffffffffc0202120 <best_fit_pmm_manager+0x578>
ffffffffc0201206:	00001617          	auipc	a2,0x1
ffffffffc020120a:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020120e:	12100593          	li	a1,289
ffffffffc0201212:	00001517          	auipc	a0,0x1
ffffffffc0201216:	b7650513          	addi	a0,a0,-1162 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020121a:	fa9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages); 
ffffffffc020121e:	00001697          	auipc	a3,0x1
ffffffffc0201222:	e4a68693          	addi	a3,a3,-438 # ffffffffc0202068 <best_fit_pmm_manager+0x4c0>
ffffffffc0201226:	00001617          	auipc	a2,0x1
ffffffffc020122a:	8da60613          	addi	a2,a2,-1830 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020122e:	12000593          	li	a1,288
ffffffffc0201232:	00001517          	auipc	a0,0x1
ffffffffc0201236:	b5650513          	addi	a0,a0,-1194 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020123a:	f89fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_128.ref_count == 0);
ffffffffc020123e:	00001697          	auipc	a3,0x1
ffffffffc0201242:	ec268693          	addi	a3,a3,-318 # ffffffffc0202100 <best_fit_pmm_manager+0x558>
ffffffffc0201246:	00001617          	auipc	a2,0x1
ffffffffc020124a:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020124e:	11b00593          	li	a1,283
ffffffffc0201252:	00001517          	auipc	a0,0x1
ffffffffc0201256:	b3650513          	addi	a0,a0,-1226 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020125a:	f69fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages - 1); // 检查页数没变
ffffffffc020125e:	00001697          	auipc	a3,0x1
ffffffffc0201262:	d2a68693          	addi	a3,a3,-726 # ffffffffc0201f88 <best_fit_pmm_manager+0x3e0>
ffffffffc0201266:	00001617          	auipc	a2,0x1
ffffffffc020126a:	89a60613          	addi	a2,a2,-1894 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020126e:	11700593          	li	a1,279
ffffffffc0201272:	00001517          	auipc	a0,0x1
ffffffffc0201276:	b1650513          	addi	a0,a0,-1258 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020127a:	f49fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_128.ref_count == 1); // 检查 ref_count 没变
ffffffffc020127e:	00001697          	auipc	a3,0x1
ffffffffc0201282:	e6268693          	addi	a3,a3,-414 # ffffffffc02020e0 <best_fit_pmm_manager+0x538>
ffffffffc0201286:	00001617          	auipc	a2,0x1
ffffffffc020128a:	87a60613          	addi	a2,a2,-1926 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020128e:	11600593          	li	a1,278
ffffffffc0201292:	00001517          	auipc	a0,0x1
ffffffffc0201296:	af650513          	addi	a0,a0,-1290 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020129a:	f29fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages - 1);
ffffffffc020129e:	00001697          	auipc	a3,0x1
ffffffffc02012a2:	cea68693          	addi	a3,a3,-790 # ffffffffc0201f88 <best_fit_pmm_manager+0x3e0>
ffffffffc02012a6:	00001617          	auipc	a2,0x1
ffffffffc02012aa:	85a60613          	addi	a2,a2,-1958 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02012ae:	11200593          	li	a1,274
ffffffffc02012b2:	00001517          	auipc	a0,0x1
ffffffffc02012b6:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02012ba:	f09fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_128.ref_count == 1);
ffffffffc02012be:	00001697          	auipc	a3,0x1
ffffffffc02012c2:	e2268693          	addi	a3,a3,-478 # ffffffffc02020e0 <best_fit_pmm_manager+0x538>
ffffffffc02012c6:	00001617          	auipc	a2,0x1
ffffffffc02012ca:	83a60613          	addi	a2,a2,-1990 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02012ce:	11100593          	li	a1,273
ffffffffc02012d2:	00001517          	auipc	a0,0x1
ffffffffc02012d6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02012da:	ee9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_empty(&cache_64.slab_list));
ffffffffc02012de:	00001697          	auipc	a3,0x1
ffffffffc02012e2:	db268693          	addi	a3,a3,-590 # ffffffffc0202090 <best_fit_pmm_manager+0x4e8>
ffffffffc02012e6:	00001617          	auipc	a2,0x1
ffffffffc02012ea:	81a60613          	addi	a2,a2,-2022 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02012ee:	10a00593          	li	a1,266
ffffffffc02012f2:	00001517          	auipc	a0,0x1
ffffffffc02012f6:	a9650513          	addi	a0,a0,-1386 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02012fa:	ec9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages); 
ffffffffc02012fe:	00001697          	auipc	a3,0x1
ffffffffc0201302:	d6a68693          	addi	a3,a3,-662 # ffffffffc0202068 <best_fit_pmm_manager+0x4c0>
ffffffffc0201306:	00000617          	auipc	a2,0x0
ffffffffc020130a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020130e:	10900593          	li	a1,265
ffffffffc0201312:	00001517          	auipc	a0,0x1
ffffffffc0201316:	a7650513          	addi	a0,a0,-1418 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020131a:	ea9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages - 2);
ffffffffc020131e:	00001697          	auipc	a3,0x1
ffffffffc0201322:	cba68693          	addi	a3,a3,-838 # ffffffffc0201fd8 <best_fit_pmm_manager+0x430>
ffffffffc0201326:	00000617          	auipc	a2,0x0
ffffffffc020132a:	7da60613          	addi	a2,a2,2010 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020132e:	10300593          	li	a1,259
ffffffffc0201332:	00001517          	auipc	a0,0x1
ffffffffc0201336:	a5650513          	addi	a0,a0,-1450 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020133a:	e89fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_64.ref_count == 0);
ffffffffc020133e:	00001697          	auipc	a3,0x1
ffffffffc0201342:	d1268693          	addi	a3,a3,-750 # ffffffffc0202050 <best_fit_pmm_manager+0x4a8>
ffffffffc0201346:	00000617          	auipc	a2,0x0
ffffffffc020134a:	7ba60613          	addi	a2,a2,1978 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020134e:	10100593          	li	a1,257
ffffffffc0201352:	00001517          	auipc	a0,0x1
ffffffffc0201356:	a3650513          	addi	a0,a0,-1482 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020135a:	e69fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_64.ref_count == N + 1);
ffffffffc020135e:	00001697          	auipc	a3,0x1
ffffffffc0201362:	ca268693          	addi	a3,a3,-862 # ffffffffc0202000 <best_fit_pmm_manager+0x458>
ffffffffc0201366:	00000617          	auipc	a2,0x0
ffffffffc020136a:	79a60613          	addi	a2,a2,1946 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020136e:	0f800593          	li	a1,248
ffffffffc0201372:	00001517          	auipc	a0,0x1
ffffffffc0201376:	a1650513          	addi	a0,a0,-1514 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020137a:	e49fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages - 2);
ffffffffc020137e:	00001697          	auipc	a3,0x1
ffffffffc0201382:	c5a68693          	addi	a3,a3,-934 # ffffffffc0201fd8 <best_fit_pmm_manager+0x430>
ffffffffc0201386:	00000617          	auipc	a2,0x0
ffffffffc020138a:	77a60613          	addi	a2,a2,1914 # ffffffffc0201b00 <etext+0x26e>
ffffffffc020138e:	0f700593          	li	a1,247
ffffffffc0201392:	00001517          	auipc	a0,0x1
ffffffffc0201396:	9f650513          	addi	a0,a0,-1546 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc020139a:	e29fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(objs[N] != NULL);
ffffffffc020139e:	00001697          	auipc	a3,0x1
ffffffffc02013a2:	c2a68693          	addi	a3,a3,-982 # ffffffffc0201fc8 <best_fit_pmm_manager+0x420>
ffffffffc02013a6:	00000617          	auipc	a2,0x0
ffffffffc02013aa:	75a60613          	addi	a2,a2,1882 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02013ae:	0f400593          	li	a1,244
ffffffffc02013b2:	00001517          	auipc	a0,0x1
ffffffffc02013b6:	9d650513          	addi	a0,a0,-1578 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02013ba:	e09fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(cache_64.ref_count == N);
ffffffffc02013be:	00001697          	auipc	a3,0x1
ffffffffc02013c2:	bf268693          	addi	a3,a3,-1038 # ffffffffc0201fb0 <best_fit_pmm_manager+0x408>
ffffffffc02013c6:	00000617          	auipc	a2,0x0
ffffffffc02013ca:	73a60613          	addi	a2,a2,1850 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02013ce:	0f000593          	li	a1,240
ffffffffc02013d2:	00001517          	auipc	a0,0x1
ffffffffc02013d6:	9b650513          	addi	a0,a0,-1610 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02013da:	de9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_pages - 1);
ffffffffc02013de:	00001697          	auipc	a3,0x1
ffffffffc02013e2:	baa68693          	addi	a3,a3,-1110 # ffffffffc0201f88 <best_fit_pmm_manager+0x3e0>
ffffffffc02013e6:	00000617          	auipc	a2,0x0
ffffffffc02013ea:	71a60613          	addi	a2,a2,1818 # ffffffffc0201b00 <etext+0x26e>
ffffffffc02013ee:	0ef00593          	li	a1,239
ffffffffc02013f2:	00001517          	auipc	a0,0x1
ffffffffc02013f6:	99650513          	addi	a0,a0,-1642 # ffffffffc0201d88 <best_fit_pmm_manager+0x1e0>
ffffffffc02013fa:	dc9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02013fe <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02013fe:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201402:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201404:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201408:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020140a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020140e:	f022                	sd	s0,32(sp)
ffffffffc0201410:	ec26                	sd	s1,24(sp)
ffffffffc0201412:	e84a                	sd	s2,16(sp)
ffffffffc0201414:	f406                	sd	ra,40(sp)
ffffffffc0201416:	e44e                	sd	s3,8(sp)
ffffffffc0201418:	84aa                	mv	s1,a0
ffffffffc020141a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020141c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201420:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201422:	03067e63          	bgeu	a2,a6,ffffffffc020145e <printnum+0x60>
ffffffffc0201426:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201428:	00805763          	blez	s0,ffffffffc0201436 <printnum+0x38>
ffffffffc020142c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020142e:	85ca                	mv	a1,s2
ffffffffc0201430:	854e                	mv	a0,s3
ffffffffc0201432:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201434:	fc65                	bnez	s0,ffffffffc020142c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201436:	1a02                	slli	s4,s4,0x20
ffffffffc0201438:	00001797          	auipc	a5,0x1
ffffffffc020143c:	d8078793          	addi	a5,a5,-640 # ffffffffc02021b8 <best_fit_pmm_manager+0x610>
ffffffffc0201440:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201444:	9a3e                	add	s4,s4,a5
}
ffffffffc0201446:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201448:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020144c:	70a2                	ld	ra,40(sp)
ffffffffc020144e:	69a2                	ld	s3,8(sp)
ffffffffc0201450:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201452:	85ca                	mv	a1,s2
ffffffffc0201454:	87a6                	mv	a5,s1
}
ffffffffc0201456:	6942                	ld	s2,16(sp)
ffffffffc0201458:	64e2                	ld	s1,24(sp)
ffffffffc020145a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020145c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020145e:	03065633          	divu	a2,a2,a6
ffffffffc0201462:	8722                	mv	a4,s0
ffffffffc0201464:	f9bff0ef          	jal	ra,ffffffffc02013fe <printnum>
ffffffffc0201468:	b7f9                	j	ffffffffc0201436 <printnum+0x38>

ffffffffc020146a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020146a:	7119                	addi	sp,sp,-128
ffffffffc020146c:	f4a6                	sd	s1,104(sp)
ffffffffc020146e:	f0ca                	sd	s2,96(sp)
ffffffffc0201470:	ecce                	sd	s3,88(sp)
ffffffffc0201472:	e8d2                	sd	s4,80(sp)
ffffffffc0201474:	e4d6                	sd	s5,72(sp)
ffffffffc0201476:	e0da                	sd	s6,64(sp)
ffffffffc0201478:	fc5e                	sd	s7,56(sp)
ffffffffc020147a:	f06a                	sd	s10,32(sp)
ffffffffc020147c:	fc86                	sd	ra,120(sp)
ffffffffc020147e:	f8a2                	sd	s0,112(sp)
ffffffffc0201480:	f862                	sd	s8,48(sp)
ffffffffc0201482:	f466                	sd	s9,40(sp)
ffffffffc0201484:	ec6e                	sd	s11,24(sp)
ffffffffc0201486:	892a                	mv	s2,a0
ffffffffc0201488:	84ae                	mv	s1,a1
ffffffffc020148a:	8d32                	mv	s10,a2
ffffffffc020148c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020148e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201492:	5b7d                	li	s6,-1
ffffffffc0201494:	00001a97          	auipc	s5,0x1
ffffffffc0201498:	d58a8a93          	addi	s5,s5,-680 # ffffffffc02021ec <best_fit_pmm_manager+0x644>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020149c:	00001b97          	auipc	s7,0x1
ffffffffc02014a0:	f2cb8b93          	addi	s7,s7,-212 # ffffffffc02023c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014a4:	000d4503          	lbu	a0,0(s10)
ffffffffc02014a8:	001d0413          	addi	s0,s10,1
ffffffffc02014ac:	01350a63          	beq	a0,s3,ffffffffc02014c0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02014b0:	c121                	beqz	a0,ffffffffc02014f0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02014b2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014b4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02014b6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02014b8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02014bc:	ff351ae3          	bne	a0,s3,ffffffffc02014b0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014c0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02014c4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02014c8:	4c81                	li	s9,0
ffffffffc02014ca:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02014cc:	5c7d                	li	s8,-1
ffffffffc02014ce:	5dfd                	li	s11,-1
ffffffffc02014d0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02014d4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014d6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02014da:	0ff5f593          	zext.b	a1,a1
ffffffffc02014de:	00140d13          	addi	s10,s0,1
ffffffffc02014e2:	04b56263          	bltu	a0,a1,ffffffffc0201526 <vprintfmt+0xbc>
ffffffffc02014e6:	058a                	slli	a1,a1,0x2
ffffffffc02014e8:	95d6                	add	a1,a1,s5
ffffffffc02014ea:	4194                	lw	a3,0(a1)
ffffffffc02014ec:	96d6                	add	a3,a3,s5
ffffffffc02014ee:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02014f0:	70e6                	ld	ra,120(sp)
ffffffffc02014f2:	7446                	ld	s0,112(sp)
ffffffffc02014f4:	74a6                	ld	s1,104(sp)
ffffffffc02014f6:	7906                	ld	s2,96(sp)
ffffffffc02014f8:	69e6                	ld	s3,88(sp)
ffffffffc02014fa:	6a46                	ld	s4,80(sp)
ffffffffc02014fc:	6aa6                	ld	s5,72(sp)
ffffffffc02014fe:	6b06                	ld	s6,64(sp)
ffffffffc0201500:	7be2                	ld	s7,56(sp)
ffffffffc0201502:	7c42                	ld	s8,48(sp)
ffffffffc0201504:	7ca2                	ld	s9,40(sp)
ffffffffc0201506:	7d02                	ld	s10,32(sp)
ffffffffc0201508:	6de2                	ld	s11,24(sp)
ffffffffc020150a:	6109                	addi	sp,sp,128
ffffffffc020150c:	8082                	ret
            padc = '0';
ffffffffc020150e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201510:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201514:	846a                	mv	s0,s10
ffffffffc0201516:	00140d13          	addi	s10,s0,1
ffffffffc020151a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020151e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201522:	fcb572e3          	bgeu	a0,a1,ffffffffc02014e6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201526:	85a6                	mv	a1,s1
ffffffffc0201528:	02500513          	li	a0,37
ffffffffc020152c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020152e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201532:	8d22                	mv	s10,s0
ffffffffc0201534:	f73788e3          	beq	a5,s3,ffffffffc02014a4 <vprintfmt+0x3a>
ffffffffc0201538:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020153c:	1d7d                	addi	s10,s10,-1
ffffffffc020153e:	ff379de3          	bne	a5,s3,ffffffffc0201538 <vprintfmt+0xce>
ffffffffc0201542:	b78d                	j	ffffffffc02014a4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201544:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201548:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020154c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020154e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201552:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201556:	02d86463          	bltu	a6,a3,ffffffffc020157e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020155a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020155e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201562:	0186873b          	addw	a4,a3,s8
ffffffffc0201566:	0017171b          	slliw	a4,a4,0x1
ffffffffc020156a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020156c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201570:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201572:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201576:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020157a:	fed870e3          	bgeu	a6,a3,ffffffffc020155a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020157e:	f40ddce3          	bgez	s11,ffffffffc02014d6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201582:	8de2                	mv	s11,s8
ffffffffc0201584:	5c7d                	li	s8,-1
ffffffffc0201586:	bf81                	j	ffffffffc02014d6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201588:	fffdc693          	not	a3,s11
ffffffffc020158c:	96fd                	srai	a3,a3,0x3f
ffffffffc020158e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201592:	00144603          	lbu	a2,1(s0)
ffffffffc0201596:	2d81                	sext.w	s11,s11
ffffffffc0201598:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020159a:	bf35                	j	ffffffffc02014d6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020159c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015a0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02015a4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015a6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02015a8:	bfd9                	j	ffffffffc020157e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02015aa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015ac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02015b0:	01174463          	blt	a4,a7,ffffffffc02015b8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02015b4:	1a088e63          	beqz	a7,ffffffffc0201770 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02015b8:	000a3603          	ld	a2,0(s4)
ffffffffc02015bc:	46c1                	li	a3,16
ffffffffc02015be:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02015c0:	2781                	sext.w	a5,a5
ffffffffc02015c2:	876e                	mv	a4,s11
ffffffffc02015c4:	85a6                	mv	a1,s1
ffffffffc02015c6:	854a                	mv	a0,s2
ffffffffc02015c8:	e37ff0ef          	jal	ra,ffffffffc02013fe <printnum>
            break;
ffffffffc02015cc:	bde1                	j	ffffffffc02014a4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02015ce:	000a2503          	lw	a0,0(s4)
ffffffffc02015d2:	85a6                	mv	a1,s1
ffffffffc02015d4:	0a21                	addi	s4,s4,8
ffffffffc02015d6:	9902                	jalr	s2
            break;
ffffffffc02015d8:	b5f1                	j	ffffffffc02014a4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02015da:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015dc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02015e0:	01174463          	blt	a4,a7,ffffffffc02015e8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02015e4:	18088163          	beqz	a7,ffffffffc0201766 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02015e8:	000a3603          	ld	a2,0(s4)
ffffffffc02015ec:	46a9                	li	a3,10
ffffffffc02015ee:	8a2e                	mv	s4,a1
ffffffffc02015f0:	bfc1                	j	ffffffffc02015c0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015f2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02015f6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015f8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02015fa:	bdf1                	j	ffffffffc02014d6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02015fc:	85a6                	mv	a1,s1
ffffffffc02015fe:	02500513          	li	a0,37
ffffffffc0201602:	9902                	jalr	s2
            break;
ffffffffc0201604:	b545                	j	ffffffffc02014a4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201606:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020160a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020160c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020160e:	b5e1                	j	ffffffffc02014d6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201610:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201612:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201616:	01174463          	blt	a4,a7,ffffffffc020161e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020161a:	14088163          	beqz	a7,ffffffffc020175c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020161e:	000a3603          	ld	a2,0(s4)
ffffffffc0201622:	46a1                	li	a3,8
ffffffffc0201624:	8a2e                	mv	s4,a1
ffffffffc0201626:	bf69                	j	ffffffffc02015c0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201628:	03000513          	li	a0,48
ffffffffc020162c:	85a6                	mv	a1,s1
ffffffffc020162e:	e03e                	sd	a5,0(sp)
ffffffffc0201630:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201632:	85a6                	mv	a1,s1
ffffffffc0201634:	07800513          	li	a0,120
ffffffffc0201638:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020163a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020163c:	6782                	ld	a5,0(sp)
ffffffffc020163e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201640:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201644:	bfb5                	j	ffffffffc02015c0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201646:	000a3403          	ld	s0,0(s4)
ffffffffc020164a:	008a0713          	addi	a4,s4,8
ffffffffc020164e:	e03a                	sd	a4,0(sp)
ffffffffc0201650:	14040263          	beqz	s0,ffffffffc0201794 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201654:	0fb05763          	blez	s11,ffffffffc0201742 <vprintfmt+0x2d8>
ffffffffc0201658:	02d00693          	li	a3,45
ffffffffc020165c:	0cd79163          	bne	a5,a3,ffffffffc020171e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201660:	00044783          	lbu	a5,0(s0)
ffffffffc0201664:	0007851b          	sext.w	a0,a5
ffffffffc0201668:	cf85                	beqz	a5,ffffffffc02016a0 <vprintfmt+0x236>
ffffffffc020166a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020166e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201672:	000c4563          	bltz	s8,ffffffffc020167c <vprintfmt+0x212>
ffffffffc0201676:	3c7d                	addiw	s8,s8,-1
ffffffffc0201678:	036c0263          	beq	s8,s6,ffffffffc020169c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020167c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020167e:	0e0c8e63          	beqz	s9,ffffffffc020177a <vprintfmt+0x310>
ffffffffc0201682:	3781                	addiw	a5,a5,-32
ffffffffc0201684:	0ef47b63          	bgeu	s0,a5,ffffffffc020177a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201688:	03f00513          	li	a0,63
ffffffffc020168c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020168e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201692:	3dfd                	addiw	s11,s11,-1
ffffffffc0201694:	0a05                	addi	s4,s4,1
ffffffffc0201696:	0007851b          	sext.w	a0,a5
ffffffffc020169a:	ffe1                	bnez	a5,ffffffffc0201672 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020169c:	01b05963          	blez	s11,ffffffffc02016ae <vprintfmt+0x244>
ffffffffc02016a0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02016a2:	85a6                	mv	a1,s1
ffffffffc02016a4:	02000513          	li	a0,32
ffffffffc02016a8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02016aa:	fe0d9be3          	bnez	s11,ffffffffc02016a0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02016ae:	6a02                	ld	s4,0(sp)
ffffffffc02016b0:	bbd5                	j	ffffffffc02014a4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02016b2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016b4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02016b8:	01174463          	blt	a4,a7,ffffffffc02016c0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02016bc:	08088d63          	beqz	a7,ffffffffc0201756 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02016c0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02016c4:	0a044d63          	bltz	s0,ffffffffc020177e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02016c8:	8622                	mv	a2,s0
ffffffffc02016ca:	8a66                	mv	s4,s9
ffffffffc02016cc:	46a9                	li	a3,10
ffffffffc02016ce:	bdcd                	j	ffffffffc02015c0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02016d0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016d4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02016d6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02016d8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02016dc:	8fb5                	xor	a5,a5,a3
ffffffffc02016de:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016e2:	02d74163          	blt	a4,a3,ffffffffc0201704 <vprintfmt+0x29a>
ffffffffc02016e6:	00369793          	slli	a5,a3,0x3
ffffffffc02016ea:	97de                	add	a5,a5,s7
ffffffffc02016ec:	639c                	ld	a5,0(a5)
ffffffffc02016ee:	cb99                	beqz	a5,ffffffffc0201704 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02016f0:	86be                	mv	a3,a5
ffffffffc02016f2:	00001617          	auipc	a2,0x1
ffffffffc02016f6:	af660613          	addi	a2,a2,-1290 # ffffffffc02021e8 <best_fit_pmm_manager+0x640>
ffffffffc02016fa:	85a6                	mv	a1,s1
ffffffffc02016fc:	854a                	mv	a0,s2
ffffffffc02016fe:	0ce000ef          	jal	ra,ffffffffc02017cc <printfmt>
ffffffffc0201702:	b34d                	j	ffffffffc02014a4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201704:	00001617          	auipc	a2,0x1
ffffffffc0201708:	ad460613          	addi	a2,a2,-1324 # ffffffffc02021d8 <best_fit_pmm_manager+0x630>
ffffffffc020170c:	85a6                	mv	a1,s1
ffffffffc020170e:	854a                	mv	a0,s2
ffffffffc0201710:	0bc000ef          	jal	ra,ffffffffc02017cc <printfmt>
ffffffffc0201714:	bb41                	j	ffffffffc02014a4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201716:	00001417          	auipc	s0,0x1
ffffffffc020171a:	aba40413          	addi	s0,s0,-1350 # ffffffffc02021d0 <best_fit_pmm_manager+0x628>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020171e:	85e2                	mv	a1,s8
ffffffffc0201720:	8522                	mv	a0,s0
ffffffffc0201722:	e43e                	sd	a5,8(sp)
ffffffffc0201724:	0fc000ef          	jal	ra,ffffffffc0201820 <strnlen>
ffffffffc0201728:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020172c:	01b05b63          	blez	s11,ffffffffc0201742 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201730:	67a2                	ld	a5,8(sp)
ffffffffc0201732:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201736:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201738:	85a6                	mv	a1,s1
ffffffffc020173a:	8552                	mv	a0,s4
ffffffffc020173c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020173e:	fe0d9ce3          	bnez	s11,ffffffffc0201736 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201742:	00044783          	lbu	a5,0(s0)
ffffffffc0201746:	00140a13          	addi	s4,s0,1
ffffffffc020174a:	0007851b          	sext.w	a0,a5
ffffffffc020174e:	d3a5                	beqz	a5,ffffffffc02016ae <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201750:	05e00413          	li	s0,94
ffffffffc0201754:	bf39                	j	ffffffffc0201672 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201756:	000a2403          	lw	s0,0(s4)
ffffffffc020175a:	b7ad                	j	ffffffffc02016c4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020175c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201760:	46a1                	li	a3,8
ffffffffc0201762:	8a2e                	mv	s4,a1
ffffffffc0201764:	bdb1                	j	ffffffffc02015c0 <vprintfmt+0x156>
ffffffffc0201766:	000a6603          	lwu	a2,0(s4)
ffffffffc020176a:	46a9                	li	a3,10
ffffffffc020176c:	8a2e                	mv	s4,a1
ffffffffc020176e:	bd89                	j	ffffffffc02015c0 <vprintfmt+0x156>
ffffffffc0201770:	000a6603          	lwu	a2,0(s4)
ffffffffc0201774:	46c1                	li	a3,16
ffffffffc0201776:	8a2e                	mv	s4,a1
ffffffffc0201778:	b5a1                	j	ffffffffc02015c0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020177a:	9902                	jalr	s2
ffffffffc020177c:	bf09                	j	ffffffffc020168e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020177e:	85a6                	mv	a1,s1
ffffffffc0201780:	02d00513          	li	a0,45
ffffffffc0201784:	e03e                	sd	a5,0(sp)
ffffffffc0201786:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201788:	6782                	ld	a5,0(sp)
ffffffffc020178a:	8a66                	mv	s4,s9
ffffffffc020178c:	40800633          	neg	a2,s0
ffffffffc0201790:	46a9                	li	a3,10
ffffffffc0201792:	b53d                	j	ffffffffc02015c0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201794:	03b05163          	blez	s11,ffffffffc02017b6 <vprintfmt+0x34c>
ffffffffc0201798:	02d00693          	li	a3,45
ffffffffc020179c:	f6d79de3          	bne	a5,a3,ffffffffc0201716 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02017a0:	00001417          	auipc	s0,0x1
ffffffffc02017a4:	a3040413          	addi	s0,s0,-1488 # ffffffffc02021d0 <best_fit_pmm_manager+0x628>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017a8:	02800793          	li	a5,40
ffffffffc02017ac:	02800513          	li	a0,40
ffffffffc02017b0:	00140a13          	addi	s4,s0,1
ffffffffc02017b4:	bd6d                	j	ffffffffc020166e <vprintfmt+0x204>
ffffffffc02017b6:	00001a17          	auipc	s4,0x1
ffffffffc02017ba:	a1ba0a13          	addi	s4,s4,-1509 # ffffffffc02021d1 <best_fit_pmm_manager+0x629>
ffffffffc02017be:	02800513          	li	a0,40
ffffffffc02017c2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017c6:	05e00413          	li	s0,94
ffffffffc02017ca:	b565                	j	ffffffffc0201672 <vprintfmt+0x208>

ffffffffc02017cc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02017cc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02017ce:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02017d2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02017d4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02017d6:	ec06                	sd	ra,24(sp)
ffffffffc02017d8:	f83a                	sd	a4,48(sp)
ffffffffc02017da:	fc3e                	sd	a5,56(sp)
ffffffffc02017dc:	e0c2                	sd	a6,64(sp)
ffffffffc02017de:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02017e0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02017e2:	c89ff0ef          	jal	ra,ffffffffc020146a <vprintfmt>
}
ffffffffc02017e6:	60e2                	ld	ra,24(sp)
ffffffffc02017e8:	6161                	addi	sp,sp,80
ffffffffc02017ea:	8082                	ret

ffffffffc02017ec <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02017ec:	4781                	li	a5,0
ffffffffc02017ee:	00005717          	auipc	a4,0x5
ffffffffc02017f2:	82273703          	ld	a4,-2014(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02017f6:	88ba                	mv	a7,a4
ffffffffc02017f8:	852a                	mv	a0,a0
ffffffffc02017fa:	85be                	mv	a1,a5
ffffffffc02017fc:	863e                	mv	a2,a5
ffffffffc02017fe:	00000073          	ecall
ffffffffc0201802:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201804:	8082                	ret

ffffffffc0201806 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201806:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020180a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020180c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc020180e:	cb81                	beqz	a5,ffffffffc020181e <strlen+0x18>
        cnt ++;
ffffffffc0201810:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201812:	00a707b3          	add	a5,a4,a0
ffffffffc0201816:	0007c783          	lbu	a5,0(a5)
ffffffffc020181a:	fbfd                	bnez	a5,ffffffffc0201810 <strlen+0xa>
ffffffffc020181c:	8082                	ret
    }
    return cnt;
}
ffffffffc020181e:	8082                	ret

ffffffffc0201820 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201820:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201822:	e589                	bnez	a1,ffffffffc020182c <strnlen+0xc>
ffffffffc0201824:	a811                	j	ffffffffc0201838 <strnlen+0x18>
        cnt ++;
ffffffffc0201826:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201828:	00f58863          	beq	a1,a5,ffffffffc0201838 <strnlen+0x18>
ffffffffc020182c:	00f50733          	add	a4,a0,a5
ffffffffc0201830:	00074703          	lbu	a4,0(a4)
ffffffffc0201834:	fb6d                	bnez	a4,ffffffffc0201826 <strnlen+0x6>
ffffffffc0201836:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201838:	852e                	mv	a0,a1
ffffffffc020183a:	8082                	ret

ffffffffc020183c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020183c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201840:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201844:	cb89                	beqz	a5,ffffffffc0201856 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201846:	0505                	addi	a0,a0,1
ffffffffc0201848:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020184a:	fee789e3          	beq	a5,a4,ffffffffc020183c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020184e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201852:	9d19                	subw	a0,a0,a4
ffffffffc0201854:	8082                	ret
ffffffffc0201856:	4501                	li	a0,0
ffffffffc0201858:	bfed                	j	ffffffffc0201852 <strcmp+0x16>

ffffffffc020185a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020185a:	c20d                	beqz	a2,ffffffffc020187c <strncmp+0x22>
ffffffffc020185c:	962e                	add	a2,a2,a1
ffffffffc020185e:	a031                	j	ffffffffc020186a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201860:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201862:	00e79a63          	bne	a5,a4,ffffffffc0201876 <strncmp+0x1c>
ffffffffc0201866:	00b60b63          	beq	a2,a1,ffffffffc020187c <strncmp+0x22>
ffffffffc020186a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020186e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201870:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201874:	f7f5                	bnez	a5,ffffffffc0201860 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201876:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020187a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020187c:	4501                	li	a0,0
ffffffffc020187e:	8082                	ret

ffffffffc0201880 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201880:	ca01                	beqz	a2,ffffffffc0201890 <memset+0x10>
ffffffffc0201882:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201884:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201886:	0785                	addi	a5,a5,1
ffffffffc0201888:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020188c:	fec79de3          	bne	a5,a2,ffffffffc0201886 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201890:	8082                	ret
