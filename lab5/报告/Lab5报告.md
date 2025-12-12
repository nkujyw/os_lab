# 用户程序实验报告
## 练习1: 加载应用程序并执行（需要编码）
do_execv函数调用load_icode（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充load_icode的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好proc_struct结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。


### 1. 设计实现过程

在 `load_icode` 函数中，我们在完成了建立虚拟内存空间、加载 ELF 二进制文件之后，需要设置进程的**中断帧（Trapframe）**，以便内核在执行中断返回（`sret`）指令时，能够正确地切换到用户态并开始执行应用程序。

我的具体设计实现如下：

1.  **设置用户栈指针 (`tf->gpr.sp`)**：
    将中断帧中的栈指针寄存器 `sp` 设置为 `USTACKTOP`。这是因为在前面的步骤中，我们已经映射了用户栈的虚拟地址空间，此处需要确保用户程序在开始执行时，栈指针指向正确的用户栈顶位置。

2.  **设置入口地址 (`tf->epc`)**：
    将中断帧中的异常程序计数器 `epc` 设置为 ELF header 中读取到的 `e_entry`。当执行 `sret` 指令时，硬件会将 PC 跳转到 `sepc` 寄存器（即此处的 `epc`）指向的地址，从而进入应用程序的第一条指令。

3.  **设置处理器状态 (`tf->status`)**：
    为了确保进程在用户模式下运行且能够响应中断，需要修改 `sstatus` 寄存器的对应位：
    * **清除 `SSTATUS_SPP` 位**：将 SPP（Supervisor Previous Privilege）位清零，确保执行 `sret` 后 CPU 处于 User Mode（用户态）。
    * **置位 `SSTATUS_SPIE` 位**：将 SPIE（Supervisor Previous Interrupt Enable）位置 1，确保进入用户态后，中断是被允许的（即恢复之前的中断使能状态）。


补充代码如下：
```C
     // 1. 设置用户栈指针 (sp)
    tf->gpr.sp = USTACKTOP;

    // 2. 设置异常程序计数器 (epc)
    tf->epc = elf->e_entry;

    // 3. 设置状态寄存器 (status/sstatus)
    // SSTATUS_SPP (Supervisor Previous Privilege): 设为 0，代表中断返回后处于 User Mode
    // SSTATUS_SPIE (Supervisor Previous Interrupt Enable): 设为 1，代表中断返回后开启中断
    tf->status = read_csr(sstatus);
    tf->status &= ~SSTATUS_SPP; // 确保返回后是用户态 (SPP=0)
    tf->status |= SSTATUS_SPIE; // 确保返回后中断是使能的 (SPIE=1)
```


### 2. 详细执行流程描述

当该用户态进程被 uCore 调度器选择占用 CPU（从 `PROC_RUNNABLE` 态转变为 `PROC_RUNNING` 态），直到执行应用程序第一条指令，经历了以下过程：

1.  **调度与切换 (`schedule` -> `proc_run`)**：
    内核调度器调用 `schedule` 函数，选中该进程，并调用 `proc_run`。`proc_run` 内部通过 `lsatp` 切换页表（切换到该进程的地址空间），然后调用汇编函数 `switch_to`。

2.  **上下文恢复 (`switch_to`)**：
    `switch_to` 保存当前进程的上下文，并加载新进程的 `proc_struct->context`（内核上下文）。由于这是一个新创建的进程，其上下文中的 `ra`（返回地址）此前在 `copy_thread` 中被设置为了 `forkret` 函数的入口。

3.  **内核线程入口 (`forkret`)**：
    `switch_to` 返回后，CPU 跳转到 `forkret` 函数。该函数通过 `current->tf` 获取当前进程的中断帧，并调用 `forkrets(current->tf)`。

4.  **准备中断返回 (`forkrets` -> `__trapret`)**：
    `forkrets` 会接收中断帧指针，并跳转到 `trapentry.S` 中的 `__trapret` 标号处。

5.  **恢复硬件上下文 (`RESTORE_ALL`)**：
    在 `__trapret` 中，执行一系列 `LOAD` 指令，将 `current->tf`（中断帧）中保存的数据恢复到 CPU 的通用寄存器中。此时：
    * `sp` 寄存器被恢复为 `USTACKTOP`（用户栈）。
    * 其他通用寄存器被清零或恢复。
    * `sepc` 寄存器被恢复为 ELF 的入口地址。

6.  **特权级切换 (`sret`)**：
    最后执行 `sret` 指令。CPU 依据 `sstatus` 中的 `SPP` 位（已设为 0）将特权级从 Supervisor Mode 切换到 **User Mode**，同时将 PC 跳转到 `sepc` 中的地址。

7.  **执行第一条指令**：
    此时 CPU 处于用户态，PC 指向应用程序入口，开始执行应用程序的第一条指令。

## 练习2: 父进程复制自己的内存空间给子进程（需要编码）
创建子进程的函数do_fork在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过copy_range函数（位于kern/mm/pmm.c中）实现的，请补充copy_range的实现，确保能够正确执行。

请在实验报告中简要说明你的设计实现过程。

如何设计实现Copy on Write机制？给出概要设计，鼓励给出详细设计。


## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：

- 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
- 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-1.0.1）


## 扩展练习 Challenge
- 实现 Copy on Write （COW）机制

给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

这是一个big challenge.

- 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？