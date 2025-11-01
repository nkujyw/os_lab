# Lab3实验报告

### 练习1：完善中断处理 （需要编程）

请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

实验代码如下：

在trap.c文件里面：

```c
static int print_count = 0; 
        case IRQ_S_TIMER:
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();

            ticks++;

            if (ticks == TICK_NUM) {
                ticks = 0; // 重置 ticks 计数器
                print_ticks(); 
                print_count++; 
            }
            if (print_count == 10) {
                sbi_shutdown(); // 关机
            }
            break;
```

实现过程首先是在 `kern/trap/trap.c` 文件顶部添加了一个静态变量 `static int print_count = 0;` 用来跟踪打印行数。接着，在 `interrupt_handler` 函数的 `case IRQ_S_TIMER:` 分支 中添加了如上代码，首先调用 `clock_set_next_event()` 来设置下一次中断，然后递增定义在 `clock.c` 中的全局 `ticks` 计数器。当 `ticks` 达到100时，它会被重置为0，并调用 `print_ticks()` 和递增 `print_count`；当 `print_count` 达到10次时，系统将调用 `sbi_shutdown()` 关机。

定时器中断的完整处理流程始于内核初始化，此时 `clock_init()` 会开启S模式时钟中断 并调用 `clock_set_next_event()` 来预约第一次中断。当硬件定时器到期触发中断，CPU会根据 `stvec` 寄存器（在 `idt_init` 中设置）的地址跳转到汇编入口 `__alltraps`。汇编代码保存所有CPU寄存器后，调用C函数 `trap()`，后者随即调用 `trap_dispatch()` 来识别中断类型。当中断被识别为时钟中断，`interrupt_handler` 会执行到 `case IRQ_S_TIMER:` 分支。重置下一次中断，增加 `ticks` 计数，并执行打印或关机判断。如果未触发关机，函数将逐层返回，最后通过汇编代码恢复寄存器并执行 `sret` 指令，CPU返回到被中断前的代码继续执行。

`make qemu`运行结果，运行成功

![image-20251028224019972](./Lab3报告.assets/image-20251028224019972.png)

### 扩展练习 Challenge1：描述与理解中断流程

回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

#### 1) uCore中断异常处理的整体流程

```
中断/异常发生
       ↓
硬件跳转 → stvec → __alltraps (trapentry.S)
       ↓
SAVE_ALL（保存上下文）
       ↓
trap(sp) —— 调用 C 函数
       ↓
  trap_dispatch(tf)
     ├── interrupt_handler(tf)
     └── exception_handler(tf)
       ↓
__trapret:
RESTORE_ALL（恢复寄存器）
sret（返回原程序）
```

1. 异常或中断发生时，硬件把当前 PC 写入 `sepc`，把原因写入 `scause`，若适用则把相关地址写入 `stval`（旧名 `sbadaddr`），随后切换到 `stvec` 指向的陷入入口执行。uCore 将 `stvec` 设为 direct 模式，对应的入口为 `__alltraps`。
2. 在 `__alltraps` 中首先执行 `SAVE_ALL` 建立陷阱帧：把进入时的 `sp` 临时存入 `sscratch`，然后一次性为陷阱帧在内核栈上预留 `36*REGBYTES` 空间，依序保存通用寄存器（`x0..x31`）及 `sstatus/sepc/stval/scause`。
3. 保存完现场后将陷阱帧指针传入 C 侧处理函数：`move a0, sp` 把当前 `sp`（即陷阱帧基址）作为参数传给 `trap(struct trapframe *tf)`，随后 `jal trap` 进入 C。`trap` 内部调用 `trap_dispatch(tf)` 按 `scause` 分派：若为中断则进入 `interrupt_handler(tf)`；若为异常则进入 `exception_handler(tf)`。
4. 处理完成后回到 `__trapret` 执行 `RESTORE_ALL`：先恢复 `sstatus` 与 `sepc`，再按保存时的固定偏移恢复各通用寄存器，并确保最后恢复 `sp`，随后执行 `sret` 返回到 `sepc` 指向的指令继续运行。

#### 2) `move a0, sp` 的目的

把陷阱帧（trapframe）的地址作为参数传给 C 处理函数 `trap(tf)`。`SAVE_ALL` 后的 `sp` 就指向陷阱帧的起始地址，所以 `move a0, sp`（伪指令，等价 `addi a0, sp, 0`）就是“`a0 = tf_ptr`”。C 端就能通过这个指针读写已保存的寄存器、`sepc/scause/stval/sstatus` 等。

#### 3) `SAVE_ALL` 中“寄存器保存在栈中的位置”是怎么确定的？

1. 预留大小固定为 `36*REGBYTES`；`REGBYTES` 为 XLEN/8（RV64 为 8，RV32 为 4）。前 32 个槽位给 x0…x31，后 4 个槽位依次放 sstatus、sepc、stval、scause。

2. 槽位与寄存器编号一一对应：xN 保存在偏移 `N*REGBYTES`。x2（sp）因正在当地址寄存器使用，先把旧 sp 存到 sscratch，再取到 s0 回填到偏移 `2*REGBYTES`，从而保持“编号即偏移”的整齐布局。

这种布局与 `struct trapframe`/`struct pushregs` 的字段顺序保持一致，便于按常量偏移读写。


#### 4) `__alltraps` 里对“任何中断”都必须保存**所有**寄存器吗？

**不一定必须。**

在通用入口 `__alltraps` 里通常选择 保存全部寄存器，因为进入 `trap()` 之后是 C 代码，编译器可以自由改写 caller-saved 寄存器，且处理流程可能开启中断、发生二次陷入或进程切换；若未完整保存，返回时就无法还原被打断现场。所以“保存全部寄存器”是最安全、最简单的做法。

在严格受控的“快速中断路径”里，如果整个处理完全在汇编中完成、且能保证仅使用极少数寄存器并在返回前手工恢复，那么可以只保存必要子集。但一旦要调用 C、可能调度或允许嵌套，就应保存全部以确保正确性。

### 扩展练习 Challenge2：理解上下文切换机制

回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

#### 1） 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

`csrw sscratch, sp`：把进入陷阱前正在用的栈指针写到 `sscratch`。

`csrrw s0, sscratch, x0`：把 `sscratch` 里的旧 `sp` 读回到 `s0`，同时把 `sscratch` 写成 0。

**目的：**

此时我们已经把 `sp`改成“指向陷阱帧”的地址，不能直接拿自己当被保存对象。所以我们需要先把陷入瞬间的“旧内核栈指针”备份到 `sscratch`。

把 `sscratch` 清成 0 后，如果在处理中又发生一次陷入，入口代码可通过检查 `sscratch==0` 识别这次是内核态再次陷入，从而走安全分支避免覆盖已存在的陷阱帧。


#### 2）为何 `SAVE_ALL` 里保存了 `stval/scause` 等 CSR，而 `RESTORE_ALL` 却不恢复它们？存它们有何意义？

返回所需的只有 `sstatus` 与 `sepc`，`sret` 只依赖这两个寄存器来决定返回位置，存储陷阱发生前的特权级、中断使能状态等关键标志。

`stval/scause` 属于这一次陷阱的描述性信息，根据 `scause` 明确陷阱类型，区分中断还是异常、利用 `stval` 补充关联数据 —— 若为缺页异常，stval 存储缺失的虚拟地址；若为非法指令异常，stval 存储非法指令的机器码。被陷阱打断的原程序在正常执行时，完全不需要 stval/scause 的值 。

### 扩展练习Challenge3：完善异常中断

编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。
