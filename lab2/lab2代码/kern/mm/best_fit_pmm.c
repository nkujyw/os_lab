#include <defs.h>
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <best_fit_pmm.h>

/*
 * Best-Fit 物理内存分配器：
 * - 空闲块链表按地址有序（便于合并相邻块）
 * - 分配：线性扫描选择“刚好能装下”的最小块
 * - 切分：若块比需求大，切出剩余部分并按地址插回
 * - 释放：按地址插入并尝试与前/后块合并
 */

// 注意：free_area_t 类型已经在 memlayout.h 中定义，切勿在此重复 typedef
// 这里只定义一个仅在本文件可见的实例

static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free   (free_area.nr_free)

// —— 工具函数 ——

// 按地址顺序插入
static void insert_block_by_addr(struct Page *base) {/*LAB2 EXERCISE 2: 2211044*/
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
        return;
    }
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base < page) {                        // 第一个地址比 base 大的块
            list_add_before(le, &(base->page_link));
            return;
        }
        if (list_next(le) == &free_list) {        // 到尾了，接到尾
            list_add(le, &(base->page_link));
            return;
        }
    }
}

// 与前后相邻块合并（链表按地址有序）
static void try_merge_neighbors(struct Page *base) {/*LAB2 EXERCISE 2: 2211044*/
    // 与前块合并
    list_entry_t *ple = list_prev(&(base->page_link));
    if (ple != &free_list) {
        struct Page *prev = le2page(ple, page_link);
        if (prev + prev->property == base) {      // 物理相邻
            prev->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = prev;                           // 合并后用 prev 继续向后看
        }
    }
    // 与后块合并
    list_entry_t *nle = list_next(&(base->page_link));/*LAB2 EXERCISE 2: 2211044*/
    if (nle != &free_list) {
        struct Page *next = le2page(nle, page_link);
        if (base + base->property == next) {      // 物理相邻
            base->property += next->property;
            ClearPageProperty(next);
            list_del(&(next->page_link));
        }
    }
}

// —— pmm_manager 所需接口 ——

// 初始化管理结构
static void best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

// 把 [base, base+n) 注册为一段可用物理页
static void best_fit_init_memmap(struct Page *base, size_t n) {/*LAB2 EXERCISE 2: 2211044*/
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
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

// 分配 n 页：Best-Fit 选择最小可用块
static struct Page *best_fit_alloc_pages(size_t n) {/*LAB2 EXERCISE 2: 2211044*/
    assert(n > 0);
    if (n > nr_free) return NULL;

    struct Page *best = NULL;
    size_t best_size = (size_t)-1;

    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (PageProperty(p) && p->property >= n) {
            if (p->property < best_size) {
                best = p;
                best_size = p->property;
                if (best_size == n) break;        // 不能更优了
            }
        }
    }
    if (best == NULL) return NULL;

    // 保存前驱位置，便于把剩余块插回原处（保持地址有序）
    list_entry_t *prev = list_prev(&(best->page_link));
    list_del(&(best->page_link));

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

// 释放 n 页：插入并与相邻可合并
static void best_fit_free_pages(struct Page *base, size_t n) {/*LAB2 EXERCISE 2: 2211044*/
    assert(n > 0);
    for (struct Page *p = base; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    base->property = n;
    SetPageProperty(base);
    insert_block_by_addr(base);
    nr_free += n;

    try_merge_neighbors(base);
}

static size_t best_fit_nr_free_pages(void) {
    return nr_free;
}


static void best_fit_check(void) {
    size_t before = nr_free;
    struct Page *p = alloc_pages(1);
    assert(p != NULL);
    free_pages(p, 1);
    assert(nr_free == before);
}

// 管理器对象
const struct pmm_manager best_fit_pmm_manager = {
    .name          = "best_fit_pmm_manager",
    .init          = best_fit_init,
    .init_memmap   = best_fit_init_memmap,
    .alloc_pages   = best_fit_alloc_pages,
    .free_pages    = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check         = best_fit_check,    // 关键：用自己的自检实现
};
