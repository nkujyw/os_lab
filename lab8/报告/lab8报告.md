## 练习1: 完成读文件操作的实现（需要编码）

#### 问：首先了解打开文件的处理流程，然后参考本实验后续的文件读写操作的过程分析，填写在 kern/fs/sfs/sfs_inode.c中 的sfs_io_nolock()函数，实现读文件中数据的代码。

答：在` sfs_io_nolock `函数中，我采用以文件偏移为驱动的顺序循环方式，实现了对普通文件数据的连续读写。核心思想是：将任意给定的文件区间` [offset, endpos)` 拆分为若干个磁盘块内的访问操作，并根据访问是否对齐块边界选择合适的` I/O` 接口。

```c
    while (pos < endpos)
    {
        blkno = pos / SFS_BLKSIZE;
        blkoff = pos % SFS_BLKSIZE;
        size = SFS_BLKSIZE - blkoff;
        if (size > endpos - pos)
        {
            size = endpos - pos;
        }

        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0)
        {
            goto out;
        }

        if (size == SFS_BLKSIZE)
        {
            ret = sfs_block_op(sfs, data, ino, 1);
        }
        else
        {
            ret = sfs_buf_op(sfs, data, size, ino, blkoff);
        }
        if (ret != 0)
        {
            goto out;
        }
        pos += size;
        data += size;
        alen += size;
    }
```

在该循环中，我以当前文件偏移` pos `为驱动，顺序完成对文件区间` [offset, endpos) `的读写操作。每次迭代根据` pos` 计算对应的逻辑块号` blkno` 及块内偏移` blkoff`，并据此确定本次可访问的数据长度 `size`，确保不会越过请求的结束位置。

随后通过 `sfs_bmap_load_nolock` 将逻辑块号映射为实际磁盘块号` ino`。当本次访问覆盖整个磁盘块时，直接调用块级接口`sfs_block_op`；否则使用缓冲区级接口 `sfs_buf_op` 对块内局部数据进行读写。每次操作成功后，更新文件位置、用户缓冲区指针及已完成长度，直至处理完全部请求数据。


## 练习2: 完成基于文件系统的执行程序机制的实现（需要编码）

#### 问：改写proc.c中的load_icode函数和其他相关函数，实现基于文件系统的执行程序机制。执行：make qemu。如果能看看到sh用户程序的执行界面，则基本成功了。如果在sh用户界面上可以执行`exit`, `hello`（更多用户程序放在`user`目录下）等其他放置在`sfs`文件系统中的其他执行程序，则可以认为本实验基本成功。

答：load_icode 的目标是将由文件描述符 fd 指定的 ELF 可执行文件加载到当前进程的用户地址空间中，并正确构造用户态执行环境，使进程能够从 ELF 入口点开始运行，同时在用户栈中按照约定传递参数 argc / argv。

该过程本质上对应操作系统中的 exec 机制，是进程地址空间重建与用户态初始化的核心步骤。

```c
static int
load_icode(int fd, int argc, char **kargv)
{
    if (current->mm != NULL)
    {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    if ((mm = mm_create()) == NULL)
    {
        goto bad_mm;
    }
    if ((ret = setup_pgdir(mm)) != 0)
    {
        goto bad_pgdir_cleanup_mm;
    }

    struct elfhdr elf;
    if ((ret = load_icode_read(fd, &elf, sizeof(struct elfhdr), 0)) != 0)
    {
        goto bad_elf_cleanup_pgdir;
    }
    if (elf.e_magic != ELF_MAGIC)
    {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    struct proghdr *ph = NULL, *ph_end;
    if ((ph = kmalloc(sizeof(struct proghdr) * elf.e_phnum)) == NULL)
    {
        goto bad_elf_cleanup_pgdir;
    }
    if ((ret = load_icode_read(fd, ph, sizeof(struct proghdr) * elf.e_phnum, elf.e_phoff)) != 0)
    {
        goto bad_free_ph;
    }

    struct Page *page;
    uint32_t vm_flags, perm;
    size_t off, size;
    ph_end = ph + elf.e_phnum;
    for (struct proghdr *p = ph; p < ph_end; p++)
    {
        if (p->p_type != ELF_PT_LOAD)
        {
            continue;
        }
        if (p->p_filesz > p->p_memsz)
        {
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        vm_flags = 0, perm = PTE_U | PTE_V;
        if (p->p_flags & ELF_PF_X)
            vm_flags |= VM_EXEC;
        if (p->p_flags & ELF_PF_W)
            vm_flags |= VM_WRITE;
        if (p->p_flags & ELF_PF_R)
            vm_flags |= VM_READ;
        if (vm_flags & VM_READ)
            perm |= PTE_R;
        if (vm_flags & VM_WRITE)
            perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC)
            perm |= PTE_X;
        if ((ret = mm_map(mm, p->p_va, p->p_memsz, vm_flags, NULL)) != 0)
        {
            goto bad_cleanup_mmap;
        }

        uintptr_t start = p->p_va, end, la = ROUNDDOWN(start, PGSIZE);
        ret = -E_NO_MEM;

        end = p->p_va + p->p_filesz;
        while (start < end)
        {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
            {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la)
            {
                size -= la - end;
            }
            if ((ret = load_icode_read(fd, page2kva(page) + off, size, p->p_offset + start - p->p_va)) != 0)
            {
                goto bad_cleanup_mmap;
            }
            start += size;
        }

        end = p->p_va + p->p_memsz;
        if (start < la)
        {
            if (start == end)
            {
                continue;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la)
            {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        while (start < end)
        {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
            {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la)
            {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }

    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
    {
        goto bad_cleanup_mmap;
    }

    for (size_t i = 0; i < USTACKPAGE; i++)
    {
        assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - (i + 1) * PGSIZE, PTE_USER) != NULL);
    }

    bool satp_switched = 0;
    lsatp(PADDR(mm->pgdir));
    satp_switched = 1;

    uintptr_t *argv_store = NULL;
    uintptr_t stacktop = USTACKTOP;
    if (argc > 0)
    {
        if ((argv_store = kmalloc(sizeof(uintptr_t) * (argc + 1))) == NULL)
        {
            ret = -E_NO_MEM;
            goto bad_cleanup_mmap;
        }

        for (int i = argc - 1; i >= 0; i--)
        {
            size_t len = strlen(kargv[i]) + 1;
            stacktop -= len;
            if (!copy_to_user(mm, (void *)stacktop, kargv[i], len))
            {
                ret = -E_NO_MEM;
                goto bad_cleanup_mmap;
            }
            argv_store[i] = stacktop;
        }
        stacktop = ROUNDDOWN(stacktop, sizeof(uintptr_t));
        argv_store[argc] = 0;
        stacktop -= (argc + 1) * sizeof(uintptr_t);
        if (!copy_to_user(mm, (void *)stacktop, argv_store, (argc + 1) * sizeof(uintptr_t)))
        {
            ret = -E_NO_MEM;
            goto bad_cleanup_mmap;
        }
    }
    else
    {
        stacktop = USTACKTOP;
    }

    mm_count_inc(mm);
    current->mm = mm;
    current->pgdir = PADDR(mm->pgdir);
    lsatp(PADDR(mm->pgdir));

    struct trapframe *tf = current->tf;
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    tf->gpr.sp = stacktop;
    tf->gpr.a0 = argc;
    tf->gpr.a1 = (argc > 0) ? stacktop : 0;
    tf->epc = elf.e_entry;
    tf->status = read_csr(sstatus);
    tf->status &= ~SSTATUS_SPP;
    tf->status |= SSTATUS_SPIE;
    ret = 0;

bad_free_ph:
    if (ph != NULL)
    {
        kfree(ph);
    }
bad_close_fd:
    sysfile_close(fd);
out:
    if (argv_store != NULL)
    {
        kfree(argv_store);
    }
    return ret;
bad_elf_cleanup_pgdir:
    if (satp_switched)
    {
        lsatp(boot_pgdir_pa);
    }
    put_pgdir(mm);
    mm_destroy(mm);
    goto bad_close_fd;
bad_cleanup_mmap:
    if (satp_switched)
    {
        lsatp(boot_pgdir_pa);
    }
    exit_mmap(mm);
    put_pgdir(mm);
    mm_destroy(mm);
    goto bad_free_ph;
bad_pgdir_cleanup_mm:
    if (satp_switched)
    {
        lsatp(boot_pgdir_pa);
    }
    mm_destroy(mm);
bad_mm:
    goto bad_close_fd;
}
```

## 1. 基本思路

本实验里，用户程序不是从内存镜像里“直接拿到”的，而是通过**文件描述符 `fd`**从文件系统读取。因此 `load_icode` 要做的事可以理解为：

1. 从 `fd` 读出 ELF 的结构信息（ELF 头 + Program Header）
2. 按 Program Header 把每个可加载段（`PT_LOAD`）映射到用户地址空间
3. 把文件内容拷进去，并把 BSS 补零
4. 建立用户栈并放好 `argc/argv`，最后设置好 trapframe 进入用户态执行

---

## 2. 创建并初始化新的地址空间

进入 `load_icode` 时，要求当前进程还没有用户地址空间，否则说明状态不对：

```c
if (current->mm != NULL)
    panic("load_icode: current->mm must be empty.\n");
```

接着创建并初始化一套新的用户地址空间：

* `mm_create()` 生成新的 `mm_struct`
* `setup_pgdir(mm)` 为该地址空间建立页表（pgdir）

做到这里，进程已经拥有了一份**干净的、空的用户虚拟地址空间**，后续就可以开始往里面“装载程序”。

---

## 3. 通过 fd 读取并解析 ELF

### 3.1 读取 ELF 头并校验格式

程序首先从文件开头读取 ELF 头：

```c
load_icode_read(fd, &elf, sizeof(struct elfhdr), 0);
```

然后检查 `ELF_MAGIC`，确保这是合法的 ELF 可执行文件。这样做的意义是：避免把非 ELF 文件当成程序装载，导致后续解析结构体越界或映射错误。

### 3.2 读取 Program Header Table

ELF 头里给出了程序头表的位置和数量（`e_phoff`、`e_phnum`），于是一次性把所有 program header 读出来：

```c
load_icode_read(fd, ph, sizeof(struct proghdr) * elf.e_phnum, elf.e_phoff);
```

之后遍历 program header，只处理 `p_type == PT_LOAD` 的段，因为只有这些段需要装入内存。

---

## 4. 装载 TEXT / DATA / BSS 段

对每个 `PT_LOAD` 段，整体流程可以分成三步：**先建映射，再拷内容，最后补 BSS**。

### 4.1 建立虚拟内存映射（VMA）

根据该段的 `p_va`（虚拟地址）、`p_memsz`（内存大小）以及 `p_flags`（权限），调用 `mm_map` 在用户地址空间中建立一段 VMA。

同时需要把 ELF 的权限转换为页表权限（例如读 / 写 / 执行对应 `PTE_R / PTE_W / PTE_X`），保证用户态访问权限与 ELF 描述一致。

### 4.2 拷贝文件内容（TEXT / DATA）

段内 `p_filesz` 这部分是文件里真实存在的数据（一般对应 text/data），装载时按页处理：

* 用 `pgdir_alloc_page` 为用户虚拟地址对应的页分配物理页
* 用 `load_icode_read(fd, ...)` 从文件的 `p_offset` 位置读取数据
* 把数据写入新分配的页面中

这里要特别注意：段的起始地址可能不是页对齐的，所以实现通常会做对齐计算（如 `ROUNDDOWN/ROUNDUP`），确保第一页的偏移、最后一页的剩余都处理正确。

### 4.3 初始化 BSS（补零）

当 `p_memsz > p_filesz` 时，多出来的部分就是 BSS（未初始化全局变量区域）。这部分文件里没有数据，所以需要：

* 对还没覆盖到的内存区域继续分配页面
* 用 `memset(..., 0, ...)` 将其清零

这样可以保证用户态看到的未初始化全局变量初始值为 0。

---

## 5. 用户栈建立与 argc / argv 布局

### 5.1 建立用户栈 VMA

通常在用户地址空间的高地址处映射栈区域：

```c
mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE,
       VM_READ | VM_WRITE | VM_STACK, NULL);
```

随后逐页分配物理页，让这段栈空间在页表中真正可用。

### 5.2 用户态期望的参数约定

用户程序启动时一般约定：

* `a0 = argc`
* `a1 = argv`（指向用户地址空间中的 `char **argv`）
* `argv[argc] = NULL`

因此内核要在用户栈里“拼出”两类东西：**字符串本体**和**指针数组 argv**。布局通常是：

```
高地址
[ 参数字符串内容 ... ]   <-- 字符串从高往低放
[ 对齐填充 ]
[ argv[0], argv[1], ... argv[argc]=NULL ]  <-- 指针数组
低地址
```

### 5.3 拷贝策略

实现上一般采用“先放字符串，再放 argv 指针”的方式更稳：

* 先把每个 `kargv[i]` 的字符串拷到用户栈中（常用逆序放置，便于更新栈顶指针）
* 记录每个字符串在**用户空间中的地址**
* 对 `sp` 做必要的对齐（例如 `uintptr_t` 对齐）
* 再把这些“用户地址”组成的指针数组写入用户栈，形成 `argv`

最终得到的 `argv` 指向的是用户栈里那片指针数组，指针数组里的每个元素又指向用户栈里的对应字符串。

---

## 6. 切换页表与初始化 trapframe

当所有段和用户栈都准备好后，需要把进程的执行上下文切到这套新地址空间上：

1. 更新 `current->mm` 与 `current->pgdir`
2. 切换页表：`lsatp(PADDR(mm->pgdir))`
3. 设置 trapframe，让返回用户态时从 ELF 入口开始跑：

* `tf->epc = elf.e_entry`
* `tf->gpr.sp` 指向构造好的用户栈顶
* `tf->gpr.a0 = argc`
* `tf->gpr.a1 = argv`
* 配置 `sstatus`，确保 `sret` 能正确返回用户态执行

到这里，进程的用户态运行环境就完整了。

---

## 7. 错误处理与资源回收

`load_icode` 中间任何一步出错都需要及时回收资源，因此代码通常用 `goto` 统一跳转到清理路径，避免遗漏释放。清理目标一般包括：

* 已创建但未完成的页表 / pgdir
* 已建立的 VMA / mm_struct
* 已分配的物理页
* 恢复 SATP 为内核页表（防止留在错误的用户页表上）

这样能保证失败路径不会泄漏内存，也不会破坏内核当前运行环境。

---



make grade结果
<img width="1140" height="402" alt="ea362e56d01f3434d9f3e2c7b90d5f85" src="https://github.com/user-attachments/assets/6c60558c-36e9-48c9-90c2-a3b33a5d1a3a" />
make qemu结果
<img width="813" height="600" alt="4fb1620bcf7098740bb8efda47f132b4" src="https://github.com/user-attachments/assets/c9207b17-5fa7-4c47-aed4-3582267f893c" />


## 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

如果要在ucore里加入UNIX的管道（Pipe）机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的PIPE机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）







#### 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

如果要在ucore里加入UNIX的软连接和硬连接机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的软连接和硬连接机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

#### 1. 总体设计思路

在 ucore 的 Simple File System (SFS) 中引入 UNIX 风格的链接机制，主要是将文件系统的**目录树结构**与**物理数据存储**分开，即让文件名只是一个标签，文件数据归文件数据存。这样，一份数据就可以贴好几个不同的标签（硬链接），或者一个标签指向另一个标签（软链接）。。

- **硬链接 (Hard Link)**：利用索引节点（Inode）的**引用计数**机制，允许不同的目录项指向同一个 Inode。
- **软链接 (Symbolic Link)**：引入一种新的文件类型，其数据块中存储的内容不再是普通数据，而是指向另一个文件的**路径字符串**。

#### 2. 数据结构设计

根据 SFS 文件系统的定义（参考 `sfs.h`），实现链接机制需要利用以下核心数据结构。

##### 2.1 磁盘索引节点设计 (`struct sfs_disk_inode`)

这是文件元数据在磁盘上的结构。主要是复用 `nlinks` 字段和扩展 `type` 字段。

```c
struct sfs_disk_inode {
    uint32_t size;                  // 文件大小
    uint16_t type;                  // 文件类型
    uint16_t nlinks;                // 硬链接计数
    uint32_t blocks;                // 块数量
    uint32_t direct[SFS_NDIRECT];   // 直接索引
    uint32_t indirect;              // 间接索引
};
```

- **`nlinks`**：用于硬链接计数。创建文件时初始化为 1。每增加一个硬链接，该值 +1。每删除一个硬链接，该值 -1。只有当 `nlinks == 0` 且内存中无进程引用时，才回收该 inode。
- **`type`**：用于标识软链接。 `type == SFS_TYPE_LINK` 时，系统将该文件的数据块内容解释为路径。

##### 2.2 内存文件系统控制块 (`struct sfs_fs`)

用于管理文件系统全局状态，主要是用同步互斥的锁。

```c
struct sfs_fs {
    // ... 其他字段 ...
    semaphore_t mutex_sem;          // 文件系统级互斥锁
    // ...
};
```

- **`mutex_sem`**：一个大粒度的互斥锁。设计要求在进行涉及目录结构变更的操作（如 `link`, `unlink`, `rename`）时必须持有此锁，以维护目录树的一致性。

##### 2.3 内存索引节点 (`struct sfs_inode`)

用于内存中的文件操作。

```C
struct sfs_inode {
    struct sfs_disk_inode *din;     // 对应的磁盘 inode
    // ...
    semaphore_t sem;                //Inode 级读写锁
};
```

- **`sem`**：用于保护单个 Inode 的内部数据。在修改 `nlinks` 计数时用此锁。

------

#### 3. 接口设计与语义

需要在 VFS 层与 SFS 层之间定义以下操作接口。

##### 3.1 硬链接接口: `vop_link`

在指定目录 `dir` 下创建一个名为 `name` 的新目录项，使其直接指向源节点 `node` 对应的 Inode。它不分配新 Inode，仅增加源 Inode 的 `nlinks` 计数。

- **参数**：
  - `dir`: 目标目录的 Inode。
  - `name`: 新链接的文件名。
  - `node`: 被链接的源文件 Inode。
- **返回值**：0 表示成功，非 0 表示错误码（如目标已存在、源为目录等）。

##### 3.2 软链接接口: `vop_symlink`

在指定目录 `dir` 下创建一个名为 `name` 的新文件，其类型为 `SFS_TYPE_LINK`，内容为 `path` 字符串。它分配新 Inode，分配数据块，将 `path` 写入数据块。

- **参数**：
  - `dir`: 目标目录的 Inode。
  - `name`: 软链接的文件名。
  - `path`: 软链接指向的目标路径。

##### 3.3 读软链接接口: `vop_readlink`

读取软链接文件 `node` 中存储的路径信息。像读普通文件一样读取数据块内容，但仅供系统路径解析使用。

- **参数**：
  - `node`: 软链接文件的 Inode。
  - `iob`: 用于回传数据的 I/O 缓冲区。

##### 3.4 删除链接接口: `vop_unlink`

从目录 `dir` 中移除名为 `name` 的目录项，并递减对应 Inode 的硬链接计数。如果递减后 `nlinks == 0`，则标记该 Inode 待回收。

------

#### 4. 概要设计方案

##### 4.1 硬链接操作流程

1. **检查合法性**：检查源节点是否为目录。
2. **并发保护**：锁定文件系统 (`lock_sfs_fs`) 和源节点 (`lock_sin`)。
3. **更新元数据**：将源 Inode 的 `nlinks` 加 1，并标记 Inode 为 Dirty。
4. **创建目录项**：在目标目录的数据块中写入 `(name, source_ino)` 映射。
5. **落盘**：将修改后的 Inode 和目录块写回磁盘。

##### 4.2 软链接操作流程

1. **创建节点**：分配一个新的 Inode，设置 `type = SFS_TYPE_LINK`。
2. **写入数据**：将目标路径字符串作为文件内容写入 Inode 关联的数据块。
3. **建立映射**：在父目录中创建目录项指向这个新 Inode。
4. **路径解析修改**：修改 VFS 的 `lookup` 逻辑，当遇到 `SFS_TYPE_LINK` 时，触发 `vop_readlink` 读取路径并插入当前解析序列。

##### 4.3 删除链接 (Unlink) 与资源回收流程

1. **删除映射**：在父目录中删除对应的文件名条目。
2. **递减计数**：对应文件的 Inode `nlinks` 减 1。
3. **条件回收**：
   - 若 `nlinks > 0`：仅更新 Inode 并保存。
   - 若 `nlinks == 0`：检查内存引用计数 (`reclaim_count`)。如果也为 0，则释放该 Inode 及其占用的所有数据块（Bitmap 位置 1）。

------

#### 5. 同步互斥问题的处理

在多进程操作系统中，文件系统操作必须具备原子性，否则可能导致文件丢失或文件系统损坏。本设计采用**两级锁机制**：

##### 5.1 第一级：文件系统锁 (`sfs_fs.mutex_sem`)

用于保护目录树结构的一致性。即在执行 `link`、`symlink`、`unlink` 的最外层操作中，持有 `sfs->mutex_sem`。确保目录项的增删和 Inode 的查找是一个原子过程。
**应用场景**：

  - 防止“A 进程正在目录下创建链接”的同时，“B 进程删除了该目录”。
  - 防止“A 进程正在链接文件 X”的同时，“B 进程删除了文件 X”。


##### 5.2 第二级：索引节点锁 (`sfs_inode.sem`)

用于保护单个文件元数据（特别是 `nlinks`）的一致性。即在修改 `sin->din->nlinks` 字段前后，必须持有 `sin->sem`。
**应用场景**： 防止两个进程同时对同一个文件创建硬链接，导致 `nlinks` 计算错误（例如两个进程读到 1，都写回 2，实际应为 3）。

##### 5.3 死锁预防

用以下的严格的层级加锁顺序可以有效避免 AB-BA 类型的死锁。

- **加锁顺序**：严格遵守 **先获取 FS 级锁，再获取 Inode 级锁** 的顺序。
- **解锁顺序**：严格遵守 **先释放 Inode 级锁，再释放 FS 级锁** 的顺序。


## 心得体会
