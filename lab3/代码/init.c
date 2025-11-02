#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];

    // 把 BSS 清零
    memset(edata, 0, end - edata);

    // 设备/控制台初始化
    dtb_init();
    cons_init();

    const char *message = "(THU.CST) os is loading ...\n";
    cputs(message);

    print_kerninfo();

    // 设置中断/异常向量入口（stvec = __alltraps）
    idt_init();

    // --------------------
    // Challenge3 测试：触发两个异常
    // 1. mret 在 S 模式下是非法指令
    // 2. ebreak 触发断点异常
    // 我们的 exception_handler 会打印并 tf->epc += 4 跳过它们
    // --------------------
    asm volatile("mret");
    asm volatile("ebreak");

    // 到这里，两种异常都应该被捕获并打印
    // 然后我们进入死循环，保持内核不退出
    while (1)
        ;
}

// 下面这些是你原本就有的回溯辅助函数，保留，方便后面实验
void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) {
    grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000);
}
