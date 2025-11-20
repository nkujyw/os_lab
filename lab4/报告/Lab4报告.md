#### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）





#### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

##### 设计与实现过程概述
系统首先调用 alloc_proc 为新进程分配并初始化一个进程控制块 proc_struct，其中包含进程状态、上下文、父进程指针等必要信息。随后，setup_kstack 为新进程分配独立的内核栈空间，用于保存运行时的内核态数据。接着，copy_mm 根据 clone_flags 参数决定是与父进程共享内存空间（线程）还是复制一份独立的地址空间（进程）。在完成内存环境的设置后，copy_thread 会建立子进程的内核上下文和陷入帧，使得新进程能够从正确的执行点开始运行。进程的唯一标识符 pid 由 get_pid() 函数生成，它通过静态自增和全局链表查重机制保证系统中每个活跃进程的 id 唯一。最后，系统将新建的进程插入进程哈希表和全局进程链表，并调用 wakeup_proc 将其状态设置为可运行。通过这一系列步骤，ucore 实现了从进程控制块分配、内核栈设置、上下文建立到唯一标识符分配的完整 fork 流程，从而确保新进程能被内核正确调度和管理。

##### 唯一性说明
ucore 为每个新创建的进程分配一个唯一的进程标识符 pid，其唯一性由 get_pid() 函数保证。该函数内部维护静态变量 last_pid，每次调用时会自增以生成新的 pid。当 last_pid 达到上限 MAX_PID 时会从 1 重新开始分配。函数会遍历系统的全局进程链表 proc_list，检测当前候选 pid 是否已被占用，若重复则继续递增直到找到未使用的 pid。因此，在任意时刻，系统中每个活动进程都拥有唯一的 pid。当进程结束并被父进程回收后，其 pid 才会被释放并可能被再次使用。综上，ucore 通过静态自增与全局查重机制实现了对每个 fork 创建的新线程分配唯一 id 的设计，从而保证了内核调度与进程管理的一致性和正确性。

#### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu





#### 扩展练习 Challenge：

1. 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

2. 深入理解不同分页模式的工作原理（思考题）

   get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

   - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
   - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

#### 知识点总结
虚拟内存与分页的本质是把程序看到的线性地址空间与物理内存解耦：CPU发出的虚拟地址通过页表（由操作系统维护）映射到物理帧，MMU和TLB承担硬件加速。这样做有三重好处：一是进程隔离与访问保护（通过PTE的权限位限制读/写/执行）；二是逻辑上扩展内存（程序可使用比物理内存更大的地址空间）；三是延迟分配与共享（按需分页只在首次访问时分配物理页，文件映射可实现进程间共享）。代价在于缺页处理和换页带来的高延迟，频繁换页会导致抖动（thrashing）。在 uCore 的教学实现中常见简化——没有 swap，因此按需分配存在但不能把冷页写到磁盘。

以 RISC-V sv39 为例，39 位虚拟地址按 9/9/9/12 划分为 VPN[2]/VPN[1]/VPN[0]/PGOFF，物理地址由 PPN2
/PPN[1]/PPN[0]/PGOFF 表示，页表是三级的（最高层通常称为 Page Directory）。页表项（PTE）同时保存 PPN 字段和一组控制位（V,R,W,X,U,A,D,G 等），既用来恢复物理地址也用来控制访问与置换策略。实现中常用的宏（如 PDX1/PDX0/PTX/PGOFF、PGADDR、PTE_ADDR）负责把线性地址拆解出各级索引或把 PTE 中的 PPN 还原为物理地址，以便在内核中用 KADDR 访问对应页表页。

多级页表的实现要点在于逐级查找与按需创建页表页。get_pte 的职责就是对给定虚拟地址定位其最终 PTE：从 pgdir 的 PDX1 索引查到第一级 PDE，若无有效项且允许创建便分配一页做为下一层页表、清零并设置相应 PDE（通常初始带 PTE_U|PTE_V）；然后继续 PDX0 层直到 PTX 得到对应的 pte_t 指针并返回。这里的实现必须处理物理地址与内核虚拟地址的互转（page2pa / KADDR），并保证新分配页表页被清零以避免信息泄露或脏条目。多级结构节省了稀疏地址空间的内存开销，但会增加查表内存访问，TLB与大页是常用的优化手段。

建立与撤销映射的原子性与引用计数是可靠实现的核心。page_insert 的流程：调用 get_pte（按需创建）拿到 PTE 指针，先将被映射物理页的引用计数加一；若目标 PTE 已有效且映射到不同物理页，则调用 page_remove_pte 减少旧页引用并在必要时释放物理页；最后写入新的 PTE（包含 pte_create(page2ppn(page), PTE_V|perm)），并执行 tlb_invalidate 以使得 MMU/CPU 的翻译缓存一致。page_remove_pte 在清除映射时先检查 PTE_V，找到对应 struct Page、page_ref_dec、在引用变为 0 时 free_page，然后把 PTE 清 0 并刷新 TLB。实现上要注意写 PTE 与刷新 TLB 的顺序，以及并发/中断下的原子性（通常在修改页表时要临时禁中断或持锁）。

对于内核镜像各段（.text/.rodata/.data/.bss），单一的大页（例如在早期引导时建立的粗糙 Giga-Page）权限相同会导致安全问题（例如可以写入 .text）。正确做法是对各段进行精细映射：为每个段按页建立 PTE 并设置恰当的 R/W/X/U 标志，必要时采用写时复制来支持共享只读与写时分离；实现时一种常见策略是构造一张新的精细页表、在新页表内为每个虚拟页设置正确权限，然后用 satp 指向新页表原子切换，最后回收旧的粗糙映射。这一过程要求在切换时保证短暂的一致性窗口并刷新 TLB。

进程控制块（proc_struct）把一个进程/线程的所有元信息集中：状态（PROC_UNINIT/RUNNABLE/SLEEPING/ZOMBIE）、PID、内核栈地址 kstack、调度标志 need_resched、父进程指针 parent、内存管理指针 mm（描述地址空间与页表根）、context（保存 callee-saved 寄存器 ra/sp/s0–s11，用于 switch_to 恢复）、trapframe（保存用户态进入内核时的完整寄存器现场以便 __trapret 恢复）、pgdir（页表根的物理地址）、名字与链表/哈希链结点等。区分 context 与 trapframe 很重要：context 仅保存切换时必须恢复的寄存器（减少开销），而 trapframe 是中断/系统调用时完整的寄存器快照，内核可修改其字段（如 a0、epc）以控制系统调用返回值或下一次返回的 PC。

内核线程的创建与调度链路从 kernel_thread 开始：kernel_thread 用局部 trapframe 填入要执行的函数指针（s0）与参数（s1），设置 sstatus（将 SPP/SPIE 置位、清 SIE）并把 epc 指向 kernel_thread_entry，然后调用 do_fork。do_fork 负责 alloc_proc、分配内核栈、按 clone_flags 决定 mm 的复制或共享（内核线程通常 CLONE_VM 共享内核地址空间）、调用 copy_thread 在新栈上复制 trapframe 并设置 context（context.ra=forkret、context.sp 指向 trapframe），把新进程插入 proc_list 并置为 RUNNABLE。forkret 和 forkrets 负责在第一次切换进入新进程时把 sp 设置为该进程的 trapframe 并跳回 __trapret，以从 trapframe 恢复完整寄存器；kernel_thread_entry 则把 s1 移到 a0 并 jalr s0 来调用用户指定函数，函数返回后执行 do_exit 完成清理。

调度与上下文切换的实际操作由 cpu_idle、schedule、proc_run 与 switch_to 协同完成。cpu_idle 循环检查 current->need_resched 并在为真时调用 schedule；schedule 将当前 need_resched 清零、在 proc_list 中按 FIFO/轮转策略查找下一个 PROC_RUNNABLE（当前非 idle 则从 next 节点开始，idle 则从表头查找，找不到则回退到 idleproc），找到后调用 proc_run：proc_run 先把新进程的 pgdir 加载到 satp（切换地址空间），然后调用 switch_to 完成寄存器层面的切换。switch_to 的汇编实现仅保存并恢复被调用者保存寄存器（ra, s0–s11），以最小开销恢复上下文并返回到新进程的 context.ra（通常是 forkret），随后通过 forkrets/__trapret 从 trapframe 恢复剩余寄存器并回到进程执行流。
  
- 基本原理概述：虚拟内存是操作系统为程序提供的逻辑地址空间，CPU/程序看到的地址由页表映射到物理内存，借此实现地址隔离、访问保护和内存扩展。分页将逻辑地址拆为页号与页内偏移，MMU/页表完成 VPN→PFN 的转换，TLB 缓存常用映射以提升性能；按需分页可延迟分配物理帧以节省内存，换页（swap）把冷页写入磁盘以扩大可用逻辑内存，但会带来高延迟和抖动风险。
  
- 页表项设计思路：页表项（PTE）既承载物理页号（PPN）也承载权限与状态位，常见字段包括有效位（V）、读/写/执行位（R/W/X）、用户位（U）、访问/脏位（A/D）及全局位等；设计要点是把地址与标志清晰分离、保证对齐并能高效提取/组装（如 PDX/PTX/PGOFF、PGADDR、PTE_ADDR 等宏），同时利用 A/D 等位支持高效置换策略和写回优化，并通过严格权限位实现内核与用户态、只读段与可写段的安全隔离。
使用多级页表实现虚拟存储：以 RISC-V sv39 为例采用三级页表，地址逐级查找 VPN[2]→VPN[1]→VPN[0] 得到最终 PTE；实现上 get_pte 支持按需分配页表页并清零，page_insert/page_remove 负责建立/撤销映射并维护物理页引用计数，page_remove_pte 在撤销时处理引用递减与可能的物理页释放，所有页表修改后须调用 tlb_invalidate 保持一致性；对于需要细粒度权限的段（如 .text/.rodata/.data/.bss），常需放弃粗糙大页、重建精细页表并切换 satp 来完成重映射。

- 内核线程管理：内核线程在内核虚拟空间运行、通常共享内核页表，无需独立地址空间；创建流程由 kernel_thread 构造初始 trapframe（将目标函数与参数放入寄存器、设置 sstatus 与 epc 指向内核入口）并调用 do_fork，do_fork 负责分配 PCB 与内核栈、设置上下文与 trapframe（由 copy_thread 完成），使新线程在被调度时可从 kernel_thread_entry 恢复并执行指定函数，线程执行完毕后通过 do_exit 回收。
  
- 设计关键数据结构：proc_struct 包含进程生命周期与运行所需的所有元信息——状态（PROC_UNINIT/RUNNABLE/SLEEPING/ZOMBIE）、PID、内核栈地址 kstack、调度标志 need_resched、父进程 parent、内存管理指针 mm、上下文 context（保存 callee-saved 寄存器以供 switch）、trapframe tf（保存用户态陷入内核时完整寄存器现场）、页表根 pgdir、标志与名字，以及用于全局管理的链表/哈希链结点；这些字段使得调度、地址空间切换、系统调用返回与资源回收都可被正确实施，并通过全局结构（current、initproc、proc_list、hash_list）实现进程的查找与调度管理。
