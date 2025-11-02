#include <assert.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <kdebug.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>
#include <stdio.h>
#include <trap.h>
#include <sbi.h>

#define TICK_NUM 100

static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/*
 * idt_init - 初始化异常/中断入口：把 stvec 设到 __alltraps，LAB3  2313109 滕一睿
 */
void idt_init(void) {
    extern void __alltraps(void);

    // sscratch = 0，表示我们当前已经在内核栈
    write_csr(sscratch, 0);

    // stvec = 中断/异常入口(__alltraps，在 trapentry.S 里)
    write_csr(stvec, &__alltraps);
}

/* trap_in_kernel - trap 是否发生在内核态 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

void print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

/*
 * interrupt_handler - 处理中断 (异步)
 * 2313109 滕一睿 LAB3
 * 
 */
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;

    switch (cause) {
    case IRQ_U_SOFT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
        break;
    case IRQ_S_TIMER: {

        clock_set_next_event();

        static uint64_t ticks = 0;
        static uint32_t num = 0;

        ticks++;

        if (ticks % TICK_NUM == 0) {
            print_ticks();
            num++;
            if (num == 10) {
                sbi_shutdown();
            }
        }
        break;
    }
    case IRQ_H_TIMER:
        cprintf("Hypervisor Timer interrupt\n");
        break;
    case IRQ_M_TIMER:
        cprintf("Machine Timer interrupt\n");
        break;
    case IRQ_U_EXT:
        cprintf("User external interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
        break;
    case IRQ_H_EXT:
        cprintf("Hypervisor external interrupt\n");
        break;
    case IRQ_M_EXT:
        cprintf("Machine external interrupt\n");
        break;
    default:
        // 未知中断：把 trapframe 打出来
        print_trapframe(tf);
        break;
    }
}

/*
 * exception_handler - 处理异常 (同步)
 * 学号：2313109 滕一睿 LAB3
 */
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    case CAUSE_ILLEGAL_INSTRUCTION:
        // 非法指令异常
        cprintf("Exception type:Illegal instruction\n");
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
        // 跳过这条非法指令，避免死循环
        tf->epc += 4;
        break;

    case CAUSE_BREAKPOINT:
        // 断点异常
        cprintf("Exception type: breakpoint\n");
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
        // 跳过 ebreak 指令
        tf->epc += 2;  // ebreak 是 2 字节指令，不是 4 字节
        break;

    case CAUSE_MISALIGNED_FETCH:
        cprintf("Exception type: misaligned fetch\n");
        break;
    case CAUSE_FAULT_FETCH:
        cprintf("Exception type: fault fetch\n");
        break;
    case CAUSE_MISALIGNED_LOAD:
        cprintf("Exception type: misaligned load\n");
        break;
    case CAUSE_FAULT_LOAD:
        cprintf("Exception type: fault load\n");
        break;
    case CAUSE_MISALIGNED_STORE:
        cprintf("Exception type: misaligned store\n");
        break;
    case CAUSE_FAULT_STORE:
        cprintf("Exception type: fault store\n");
        break;
    case CAUSE_USER_ECALL:
        cprintf("Exception type: user ecall\n");
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Exception type: supervisor ecall\n");
        break;
    case CAUSE_HYPERVISOR_ECALL:
        cprintf("Exception type: hypervisor ecall\n");
        break;
    case CAUSE_MACHINE_ECALL:
        cprintf("Exception type: machine ecall\n");
        break;
    default:
        // 其他异常就把寄存器状态全吐出来
        print_trapframe(tf);
        break;
    }
}

/* 根据 tf->cause 是负数(中断)还是正数(异常)来分发 */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}

/*
 * trap - 从 trapentry.S 的 __alltraps 过来，C 级入口
 */
void trap(struct trapframe *tf) {
    trap_dispatch(tf);
}
