# Lab2物理内存和页表

## 练习1：理解first-fit 连续物理内存分配算法（思考题）

> first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 你的first fit算法是否有进一步的改进空间？



# First-Fit 连续物理内存分配算法分析

## 一、实现过程的理解
物理内存管理模块以链表维护连续空闲页的方式实现页级内存分配。系统启动后，内核根据探测到的可用物理内存区间调用初始化函数建立空闲页链表。每个物理页由 `struct Page` 描述，字段 `property` 仅在块头页上记录该块的页数，`PG_property` 标志该页为块头页，`page_link` 将块头页连接入 `free_list`。全局变量 `free_area` 维护空闲页链表头及空闲页计数 `nr_free`。链表按照物理地址有序排列，保证释放时只需检查前后节点即可判断是否相邻并合并，从而维持空闲块连续性。First-Fit 算法基于此结构实现，从头开始扫描空闲链表，找到第一个能容纳所需页数的空闲块进行分配或切分。

## 二、相关函数的分析
`default_init` 负责初始化空闲链表，将 `free_list` 置为空并清零计数，为后续挂载空闲块做准备。  
`default_init_memmap` 接受物理页起始地址和页数，将指定区间初始化为空闲块：清除每页的标志与引用计数，只在首页设置 `property=n` 并标记为块头，然后将其按地址序插入链表并更新 `nr_free`。  
`default_alloc_pages` 执行分配逻辑，从链表头开始顺序遍历，遇到第一个 `property>=n` 的块即命中；若块长等于 n，直接摘链返回；若更大，则切下前 n 页返回，将剩余页构成新的空闲块插回原位置，更新空闲页数。  
`default_free_pages` 处理释放，恢复指定区间为可用状态，在首页设置 `property=n` 并标记后插入空闲链表中，保持地址有序，然后检测并合并与前后相邻的空闲块，删除被合并的块头节点，更新块长与 `nr_free`。

## 三、各个函数的作用
`default_init` 用于建立干净的空闲链表环境；  
`default_init_memmap` 将探测到的可用内存映射为空闲块；  
`default_alloc_pages` 完成物理页的分配与块的切割；  
`default_free_pages` 实现页块的回收与邻接块合并。  
四个函数共同维持空闲页链表的正确性与全局计数的精确性，使得分配与释放操作在链表层面相互平衡。

## 四、程序在进行物理内存分配的过程
系统初始化阶段通过 `init_memmap` 将所有可用物理内存分块挂入空闲链表。执行分配请求时，分配函数从链表首节点开始扫描，依据 First-Fit 策略选择第一个能容纳所需页数的空闲块。如果该块大小恰好等于请求值，直接摘链返回；若更大，则切割为分配区与剩余区，前者返回使用，后者重新入链。释放操作则将回收区间转化为空闲块按地址插回链表，并检查前后邻接块是否连续，若连续则合并为更大的块。通过这种“分配切分、释放合并”的循环，系统动态维护一张有序空闲页表，实现物理内存的高效复用。

## 五、设计实验过程
实验设计以验证内存分配器的正确性和一致性为目标。  
首先，通过初始化阶段检查空闲页数与可用区间一致；  
其次，在多次分配与释放操作后验证 `nr_free_pages()` 与链表长度之和保持不变；  
再次，通过构造连续分配与交错释放的测试序列，观察块的切分与合并是否正确；  
最后，利用系统自检函数检查各页标志位是否符合规范，确保仅块头页带有 `PG_property`，链表严格按物理地址递增且无交叠或断裂。  
实验过程体现了链表结构与算法逻辑的一致性验证方法。

## 六、First-Fit 的改进
First-Fit 算法结构简单、实现容易，但存在线性扫描开销和外部碎片问题。可改进的方向包括：采用 Next-Fit 策略从上次命中处继续搜索以减少链表前段遍历；采用 Best-Fit 策略在所有可用块中选择最小可容纳块以降低外部碎片；引入按块大小分类的分离适配机制减少查找复杂度；使用平衡树或跳表按大小有序存储空闲块实现对数级查找；在更高层面引入伙伴系统以对齐块大小到 2 的幂，实现常数时间的分配与合并。以上改进能够在保持正确性的前提下提升内存利用率与分配效率，从而优化物理内存管理的整体性能。







## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

> 在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
>
>- 你的 Best-Fit 算法是否有进一步的改进空间？


## 一、设计思路

本实验在 uCore 的物理内存管理框架下实现了 **Best-Fit 连续页分配算法**。系统通过 `pmm_manager` 接口封装不同策略的物理页管理器，实现时只需定义对应的 `best_fit_pmm_manager` 并实现相关函数。

设计核心如下：

- **空闲页管理结构**：使用一个 `free_area_t` 实例，其中 `free_list` 是双向链表，按物理地址递增顺序存储空闲块；`nr_free` 记录当前空闲页总数。  
- **页块信息**：每个空闲块的首页通过 `Page.property` 记录块大小（页数），并将 `PageProperty` 标志位置 1。
- **主要操作**：
  1. 初始化空闲块链表；
  2. 分配时在空闲块中查找“刚好能容纳请求的最小块”（Best-Fit）；
  3. 若块大于需求，切分出剩余部分；
  4. 释放时按地址顺序插入，并尝试与前后相邻空闲块合并。

---

## 二、关键数据结构与函数说明

### 1. 新增的全局结构与辅助函数

```c
// 内部维护的空闲块区域
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free   (free_area.nr_free)
```

`free_area` 用于管理所有空闲页块；链表按物理地址有序，便于在释放时判断相邻页是否可合并。

#### 插入函数（按地址顺序）

```c
static void insert_block_by_addr(struct Page *base) {
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
        return;
    }
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base < page) {
            list_add_before(le, &(base->page_link));
            return;
        }
        if (list_next(le) == &free_list) {
            list_add(le, &(base->page_link));
            return;
        }
    }
}
```

按物理地址排序插入的原因：

- 方便释放时直接判断相邻页；
- 保证 `free_list` 的有序性；
- 后续 `try_merge_neighbors()` 能 O(1) 检查前后合并。

#### 合并相邻空闲块

```c
static void try_merge_neighbors(struct Page *base) {
    list_entry_t *ple = list_prev(&(base->page_link));
    if (ple != &free_list) {
        struct Page *prev = le2page(ple, page_link);
        if (prev + prev->property == base) {
            prev->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = prev;
        }
    }
    list_entry_t *nle = list_next(&(base->page_link));
    if (nle != &free_list) {
        struct Page *next = le2page(nle, page_link);
        if (base + base->property == next) {
            base->property += next->property;
            ClearPageProperty(next);
            list_del(&(next->page_link));
        }
    }
}
```

---

### 2. 初始化阶段

```c
static void best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    for (struct Page *p = base; p != base + n; p++) {
        p->flags = 0;
        set_page_ref(p, 0);
        p->property = 0;
        ClearPageProperty(p);
    }
    base->property = n;
    SetPageProperty(base);
    insert_block_by_addr(base);
    nr_free += n;
}
```

初始化函数清空状态，建立初始空闲链表。  
`base->property` 记录连续空闲页数，并插入链表。

---

### 3. 分配函数（Best-Fit 核心逻辑）

```c
static struct Page *best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) return NULL;

    struct Page *best = NULL;
    size_t best_size = (size_t)-1;

    // 遍历所有空闲块，找出最小可用块
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (PageProperty(p) && p->property >= n && p->property < best_size) {
            best = p;
            best_size = p->property;
            if (best_size == n) break; // 精确匹配立即结束
        }
    }
    if (best == NULL) return NULL;

    list_entry_t *prev = list_prev(&(best->page_link));
    list_del(&(best->page_link));

    // 若块大于需求，切分剩余部分并重新插入
    if (best->property > n) {
        struct Page *remain = best + n;
        remain->property = best->property - n;
        SetPageProperty(remain);
        list_add(prev, &(remain->page_link));
    }

    nr_free -= n;
    ClearPageProperty(best);
    return best;
}
```

该函数遍历整个空闲链表，挑选出满足条件的最小块，实现“最佳匹配”分配。  
若块大于请求页数，则切割并重新插入剩余部分。

---

### 4. 释放函数

```c
static void best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    for (struct Page *p = base; p != base + n; p++) {
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    insert_block_by_addr(base);
    nr_free += n;
    try_merge_neighbors(base);
}
```

释放时重新插入空闲链表并调用 `try_merge_neighbors`，保证相邻空闲块能及时合并，减少外部碎片。

---

### 5. 管理器结构体定义

```c
static size_t best_fit_nr_free_pages(void) { return nr_free; }

static void best_fit_check(void) {
    size_t before = nr_free;
    struct Page *p = best_fit_alloc_pages(1);
    assert(p != NULL);
    best_fit_free_pages(p, 1);
    assert(nr_free == before);
}

const struct pmm_manager best_fit_pmm_manager = {
    .name          = "best_fit_pmm_manager",
    .init          = best_fit_init,
    .init_memmap   = best_fit_init_memmap,
    .alloc_pages   = best_fit_alloc_pages,
    .free_pages    = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check         = best_fit_check,
};
```

此结构将 Best-Fit 管理逻辑与系统物理内存管理框架连接，使 `pmm_init()` 能正确调用并输出。

---

## 三、实现流程概述

1. 系统启动后，内核从设备树 (DTB) 读取物理内存范围。  
2. 建立页结构体数组 `pages[]`，为每一页生成 `struct Page`。  
3. 调用 `best_fit_init_memmap()` 初始化空闲链表。  
4. 分配内存时调用 `best_fit_alloc_pages(n)` 查找最小可用块；若块过大则切分。  
5. 释放内存时调用 `best_fit_free_pages()` 插入并自动合并相邻块。  
6. 系统在 `pmm_init()` 中调用 `pmm_manager->check()` 自检并输出测试信息。

---

实验结果如下：
![实验结果截图](./31760627825_.pic_hd.jpg)
可以看到，我们很好的通过了测试！

## 四、算法特性与改进空间

当前实现能正确完成页分配与回收，减少空间浪费，满足测试要求。  
但仍存在以下可优化点：

- **查找复杂度高**：每次分配需遍历整个链表，复杂度为 O(k)。可维护一个按块大小排序的树结构或多级空闲链，将分配降至 O(log k) 或近似 O(1)。  
- **碎片控制不足**：可设置最小切分粒度，或通过延迟合并减少过小残块。  
- **并发性能**：当前全局链表无锁，无法并行访问。可增加自旋锁或每 CPU 独立空闲区。  
- **调试增强**：可增加双重释放检测、内存污染标识与链表一致性检查。







## 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

>Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...
>
>- 参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。











## 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

>slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。
>
>- 参考[linux的slub分配算法/](https://github.com/torvalds/linux/blob/master/mm/slub.c)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。









## 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）

>- 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？







## 知识点总结

