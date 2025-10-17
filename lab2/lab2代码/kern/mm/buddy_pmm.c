#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

/*
 * 伙伴系统（Buddy System）物理页分配器
 * - 最小分配单位：1 页（PGSIZE）
 * - 阶(order) 的含义：order=k 表示该块大小为 2^k 页
 */

#ifndef MAX_BUDDY_ORDER
// 最大阶；2^16 页 × 4KiB = 256MiB（实验环境足够），需要更大内存可调大
#define MAX_BUDDY_ORDER 16
#endif

// 每个阶一个空闲链表，记录该阶“空闲块头页”
typedef struct {
    list_entry_t free_list;   // 该阶空闲块双向链表表头（链上元素均为块头页）
    unsigned int nr_blocks;   // 该阶空闲块数量（单位是“块数”，非页数）
} buddy_area_t;

static buddy_area_t buddy_area[MAX_BUDDY_ORDER + 1];
static struct Page *arena_base;    // 管理的连续物理页区间的起始 Page 指针
static size_t arena_npages;        // 管理的总页数
static int buddy_inited;           // 仅用于标识是否初始化过（当前未用）

// 计算 >=n 的最小 k，使得 2^k >= n
static inline size_t ilog2_ceil(size_t n) {
    size_t k = 0, s = 1;
    while (s < n) { s <<= 1; k++; }
    return k;
}

static inline size_t pages_of_order(size_t order) { return (size_t)1 << order; }

static inline size_t page_index(struct Page *p) {
    return (size_t)(p - arena_base);
}

// 将相对索引还原为 Page*
static inline struct Page *index_page(size_t idx) { return arena_base + idx; }

// 将一个“块头页”加入到指定阶的空闲链表
// 约定：仅块头页 SetPageProperty，且 page->property=order；非头页 property=0
static void buddy_list_add(size_t order, struct Page *p) {
    SetPageProperty(p);
    p->property = order;
    set_page_ref(p, 0);
    list_add(&(buddy_area[order].free_list), &(p->page_link));
    buddy_area[order].nr_blocks++;
}

// 将一个“块头页”从指定阶空闲链表删除
static void buddy_list_del(size_t order, struct Page *p) {
    list_del(&(p->page_link));
    ClearPageProperty(p);
    p->property = 0;
    buddy_area[order].nr_blocks--;
}

// 从指定阶弹出一个空闲块（返回块头页）；若该阶为空返回 NULL
static struct Page *buddy_list_pop(size_t order) {
    list_entry_t *le = list_next(&(buddy_area[order].free_list));
    if (le == &(buddy_area[order].free_list)) return NULL;
    struct Page *p = le2page(le, page_link);
    buddy_list_del(order, p);
    return p;
}

// 分配器内部初始化：清空各阶链表与计数
static void buddy_init(void) {
    for (size_t i = 0; i <= MAX_BUDDY_ORDER; i++) {
        list_init(&(buddy_area[i].free_list));
        buddy_area[i].nr_blocks = 0;
    }
    arena_base = NULL;
    arena_npages = 0;
    buddy_inited = 1;
}

// 建立可管理的页区间并切分为若干 2 的幂大小的空闲块
// 切分策略：在当前位置 i 选择“满足对齐且不超过剩余页数”的最大阶，贪心加入空闲链
static void buddy_init_memmap(struct Page *base, size_t n) {
    arena_base = base;
    arena_npages = n;

    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        assert(PageReserved(p));
        ClearPageReserved(p);
        ClearPageProperty(p);
        p->property = 0;
        set_page_ref(p, 0);
    }

    // 贪心切分：在位置 i 选尽可能大的 2^k，要求 i 按 2^k 对齐，且 2^k 不超过剩余
    size_t i = 0;
    while (i < n) {
        size_t max_fit = 0;
        size_t remain = n - i;
        size_t align_lsb = i ? __builtin_ctzll(i) : MAX_BUDDY_ORDER;
        (void)align_lsb;

        for (size_t k = 0; k <= MAX_BUDDY_ORDER; k++) {
            size_t sz = pages_of_order(k);
            if (sz > remain) break;
            if (((i & (sz - 1)) == 0)) max_fit = k; // i 按 2^k 对齐则可用，保留最大可用 k
        }
        size_t k = max_fit;
        while (pages_of_order(k) > remain) k--;     // 兜底，确保不越界
        struct Page *p = base + i;
        buddy_list_add(k, p);
        i += pages_of_order(k);
    }
}

// 统计当前空闲页数：∑(各阶块数 × 2^阶)
static size_t buddy_nr_free_pages(void) {
    size_t total = 0;
    for (size_t k = 0; k <= MAX_BUDDY_ORDER; k++) {
        total += buddy_area[k].nr_blocks * pages_of_order(k);
    }
    return total;
}

// 分配 n 页：向上取整到 need_order，从 need_order 往上找首个非空阶，必要时不断二分拆分
static struct Page *buddy_alloc_pages(size_t n) {
    if (n == 0) return NULL;
    size_t need_order = ilog2_ceil(n);
    if (need_order > MAX_BUDDY_ORDER) return NULL;

    size_t k = need_order;
    while (k <= MAX_BUDDY_ORDER && buddy_area[k].nr_blocks == 0) {
        k++;
    }
    if (k > MAX_BUDDY_ORDER) return NULL; // 无可用内存

    struct Page *block = buddy_list_pop(k);
    while (k > need_order) {
        k--;
        size_t half = pages_of_order(k);
        struct Page *second = block + half;  // 上半块
        buddy_list_add(k, second);           // 上半块回收为自由块
    }

    ClearPageProperty(block);
    for (size_t i = 0; i < pages_of_order(need_order); i++) {
        set_page_ref(block + i, 0);
    }
    return block;
}

// 释放 n 页：按 ceil_log2(n) 得到阶，从基址 idx 出发，与伙伴 idx^(1<<order) 同阶且空闲则合并，逐阶向上
static void buddy_free_pages(struct Page *base, size_t n) {
    if (n == 0) return;
    size_t order = ilog2_ceil(n);
    if (order > MAX_BUDDY_ORDER) return;

    size_t idx = page_index(base);
    assert(idx < arena_npages);

    while (order < MAX_BUDDY_ORDER) {
        size_t buddy_idx = idx ^ pages_of_order(order); // 伙伴块的头页索引（异或翻转该阶位）
        if (buddy_idx >= arena_npages) break;

        struct Page *buddy = index_page(buddy_idx);
        if (!(PageProperty(buddy) && buddy->property == order)) {
            break;
        }
        buddy_list_del(order, buddy);
        idx = (idx < buddy_idx) ? idx : buddy_idx;
        order++;
    }
    struct Page *p = index_page(idx);
    buddy_list_add(order, p);
}

/*
 * 自检函数（供 pmm_init -> check_alloc_page 调用）：
 * 1) 基础功能：分配/释放 1、2、3(向上取整为4) 页，并校验空闲页统计变化是否正确；
 * 2) 阶测试：按不同阶（2^k）分配再释放，验证拆分与合并完整性；
 * 3) 交错序列：记录每次分配的请求页数，乱序释放时用“同一请求尺寸”释放，避免阶不一致导致错误。
 */
static void buddy_check(void) {
    size_t total = buddy_nr_free_pages();
    assert(total > 0);

    struct Page *p1 = buddy_alloc_pages(1);
    assert(p1 != NULL);
    assert(buddy_nr_free_pages() == total - 1);

    struct Page *p2 = buddy_alloc_pages(2);
    assert(p2 != NULL);
    assert(buddy_nr_free_pages() == total - 1 - 2);

    buddy_free_pages(p1, 1);
    assert(buddy_nr_free_pages() == total - 2);

    struct Page *p4 = buddy_alloc_pages(3);
    assert(p4 != NULL);
    size_t need4 = pages_of_order(ilog2_ceil(3));
    assert(need4 == 4);
    assert(buddy_nr_free_pages() == total - 2 - need4);

    // 释放 2 页、再释放 4 页，计数应回到初始
    buddy_free_pages(p2, 2);
    buddy_free_pages(p4, 3);
    assert(buddy_nr_free_pages() == total);

    for (size_t k = 0; k <= MAX_BUDDY_ORDER; k++) {
        size_t sz = pages_of_order(k);
        if (sz > arena_npages / 2) break;
        struct Page *p = buddy_alloc_pages(sz);
        assert(p != NULL);
        buddy_free_pages(p, sz);
    }

    struct { struct Page *p; size_t req; } A[64];
    size_t cnt = 0;

    for (size_t i = 1; i <= 32; i++) {
        size_t req = (i % 7) + 1;          // 请求 1~7 页
        A[cnt].p = buddy_alloc_pages(req);
        assert(A[cnt].p != NULL);
        A[cnt].req = req;                  // 记录用于正确释放
        cnt++;
    }
    for (size_t i = 0; i < cnt; i += 2) {
        if (A[i].p) buddy_free_pages(A[i].p, A[i].req);
    }
    for (size_t i = 1; i < cnt; i += 2) {
        if (A[i].p) buddy_free_pages(A[i].p, A[i].req);
    }

    assert(buddy_nr_free_pages() == total);
    cprintf("buddy_check passed.\n");
}

// pmm_manager 实例：接入 uCore 物理内存管理框架
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
