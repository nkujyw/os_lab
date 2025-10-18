#include <pmm.h> 
#include <list.h>
#include <defs.h>
#include <string.h> 
#include <assert.h>
#include <stdio.h>    
#include "slub_pmm.h"
// 将物理地址转换为内核虚拟地址
#define KADDR(pa) ((void *)((uintptr_t)(pa) + va_pa_offset))

// Slab 结构体定义
struct Slab {
    struct kmem_cache *cache;   // 指回它所属的 kmem_cache
    list_entry_t slab_link;     // 用于链入 kmem_cache->slab_list
    void *freelist;             // 指向此 Slab 内部的第一个空闲对象
    unsigned int free_count;    // 此 Slab 当前的空闲块数量
};

// 确保Slab元数据是对齐
#define ALIGN_UP(addr, align) (((addr) + (align) - 1) & ~((align) - 1))

// 内存无Slab空闲时，创建一个新的 Slab
static struct Slab *slab_create(struct kmem_cache *cache);

// 通过对象指针找到它所属的 Slab
static struct Slab *find_slab_by_object(void *obj);


//初始化一个 kmem_cache 管理器

void kmem_cache_init(struct kmem_cache *cache, const char *name, size_t size) {
    cache->name = name;
    // 确保对象大小至少是一个指针的大小，因为空闲对象需要被串联起来
    cache->object_size = (size < sizeof(void *)) ? sizeof(void *) : size;
    
    // Slab固定为1物理页
    cache->slab_pages = 1;
    //计算结构体对齐后的大小
    size_t slab_metadata_size = ALIGN_UP(sizeof(struct Slab), sizeof(void *));
    
    // 除去Slab元数据后，还能放多少个对象
    unsigned int count = 0;
    size_t able_space = (PGSIZE * cache->slab_pages) - slab_metadata_size;
    if (able_space > cache->object_size) {
        count = able_space / cache->object_size;
    }
    cache->objects_per_slab = count;
    cache->ref_count = 0;
    list_init(&(cache->slab_list));
    assert(cache->objects_per_slab > 0); 
}

//分配一个对象
void *kmem_cache_alloc(struct kmem_cache *cache) {
    struct Slab *new_slab;
    struct Slab *slab;
    list_entry_t *le;
    void *obj;
    // 1. 遍历Slab列表，寻找有空闲对象的Slab
    list_for_each(le, &(cache->slab_list)) {
        //找Slab结构体
        slab = to_struct(le, struct Slab, slab_link);
        
        if (slab->free_count > 0) {
            obj = slab->freelist;
            // 将freelist指向下一个空闲对象
            slab->freelist = *((void **)obj); 
            slab->free_count--;
            cache->ref_count++;
            return obj;
        }
    }

    // 没有找到空闲Slab，创建新Slab
    new_slab = slab_create(cache);
    if (new_slab == NULL) {
        // 内存耗尽
        cprintf("SLUB: '%s' failed to create new slab (OOM)\n", cache->name);
        return NULL;
    }
    obj = new_slab->freelist;
    new_slab->freelist = *((void **)obj);
    new_slab->free_count--;
    cache->ref_count++;
    return obj;
}

//释放一个对象
void kmem_cache_free(struct kmem_cache *cache, void *obj) {
    if (obj == NULL) {
        return;
    }
    struct Slab *slab = find_slab_by_object(obj);
    assert(slab != NULL && slab->cache == cache); 
    *((void **)obj) = slab->freelist;
    slab->freelist = obj;
    slab->free_count++;
    cache->ref_count--;
}

//创建一个新的 Slab

static struct Slab *slab_create(struct kmem_cache *cache) {
    // 向 Buddy System 申请 (物理页)
    struct Page *page = alloc_pages(cache->slab_pages);
    if (page == NULL) {
        return NULL;
    }

    //将物理页地址转换为内核虚拟地址
    uintptr_t pa = page2pa(page);
    void *va = KADDR(pa);
    // 初始化 Slab 结构体
    struct Slab *slab = (struct Slab *)va;
    slab->cache = cache;
    slab->free_count = cache->objects_per_slab;
    
    // 剩余空间串联成 freelist
    size_t slab_metadata_size = ALIGN_UP(sizeof(struct Slab), sizeof(void *));
    void *obj_start = (char *)va + slab_metadata_size;
    
    char *current_obj = obj_start;
    for (unsigned int i = 0; i < cache->objects_per_slab; i++) {

        // 将当前对象的头部用作指针，指向下一个对象
        void *next_obj = (i == cache->objects_per_slab - 1) 
                         ? NULL // 最后一个对象，指向NULL
                         : (current_obj + cache->object_size);
        
        *((void **)current_obj) = next_obj;
        
        current_obj += cache->object_size;
    }
    
    slab->freelist = obj_start;
    list_add(&(cache->slab_list), &(slab->slab_link));
    return slab;
}

//通过对象指针找到它所属的 Slab
static struct Slab *find_slab_by_object(void *obj) {
    //将对象指针转为物理地址
    uintptr_t pa = PADDR(obj);
    
    // 找物理页 Page 
    struct Page *page = pa2page(pa); 
    
    // 找物理页的起始物理地址
    uintptr_t page_pa = page2pa(page); 

    // 将页的起始物理地址转为内核虚拟地址
    void *slab_va = KADDR(page_pa);
    
    return (struct Slab *)slab_va;
}


//收缩缓存，释放所有完全空闲的 Slab
void kmem_cache_shrink(struct kmem_cache *cache) {
    list_entry_t *le = list_next(&(cache->slab_list));
    while (le != &(cache->slab_list)) {
        struct Slab *slab = to_struct(le, struct Slab, slab_link);
        list_entry_t *next = list_next(le);
        
        // 检查这个Slab是否完全空闲
        if (slab->free_count == cache->objects_per_slab) {
            // 从缓存的Slab列表中移除该Slab
            list_del(le);
            //将Slab对应的物理页归还给 Buddy System
            struct Page *page = pa2page(PADDR(slab)); 
            free_pages(page, cache->slab_pages); 
        }
        le = next;
    }
}

//销毁一个 kmem_cache
void kmem_cache_destroy(struct kmem_cache *cache) {

    if (cache->ref_count > 0) {
        cprintf("ERROR: attempt to destroy cache '%s' with ref_count %u\n", cache->name, cache->ref_count);
        return;
    }
    kmem_cache_shrink(cache);
    assert(list_empty(&(cache->slab_list)));
    cache->name = "DESTROYED";
}

//测试代码
static struct kmem_cache cache_32;
static struct kmem_cache cache_64;
static struct kmem_cache cache_128;

//  （可选）用于测试 ctor 的辅助函数 


void slub_check(void) {
    void *obj_a, *obj_b, *o128;
    size_t initial_pages, N;
    int i; 
    void* objs[256]; // 假设一个 Slab 最多 256 个对象

    //  T1: 初始化 和 ctor 测试 
    kmem_cache_init(&cache_32, "cache_32", 32);
    kmem_cache_init(&cache_64, "cache_64", 64);
    kmem_cache_init(&cache_128, "cache_128", 128);
    cprintf("  T1: Cache initialization passed.\n");

    //  T2: 基本分配/释放/Ref_Count/Ctor 测试 
    assert(cache_32.ref_count == 0);

    obj_a = kmem_cache_alloc(&cache_32);
    assert(obj_a != NULL);
    assert(cache_32.ref_count == 1); // 检查 ref_count 增加
    
    kmem_cache_free(&cache_32, obj_a);
    assert(cache_32.ref_count == 0); // 检查 ref_count 减少
    
    cprintf("  T2: Alloc/Free/Ref_Count/Ctor passed.\n");

    //  T3: 对象复用 (LIFO Freelist) 测试 
    obj_b = kmem_cache_alloc(&cache_32);
    assert(obj_b == obj_a); // 检查是否复用了刚释放的对象
    kmem_cache_free(&cache_32, obj_b);
    
    cprintf("  T3: Object reuse (LIFO) passed.\n");

    //  T4: 新 Slab 触发测试 
    initial_pages = nr_free_pages();
    N = cache_64.objects_per_slab;
    assert(N > 0 && N < 256);
    
    // 分配 N 个对象 (应填满第一个 Slab)
    for (i = 0; i < N; i++) {
        objs[i] = kmem_cache_alloc(&cache_64);
        assert(objs[i] != NULL);
    }
    // 第一个 Slab 被创建，页数应 -1
    assert(nr_free_pages() == initial_pages - 1);
    assert(cache_64.ref_count == N);
    
    // 分配第 N+1 个对象 (必须触发第二个 Slab)
    objs[N] = kmem_cache_alloc(&cache_64);
    assert(objs[N] != NULL);
    
    // 第二个 Slab 被创建，页数应 -2
    assert(nr_free_pages() == initial_pages - 2);
    assert(cache_64.ref_count == N + 1);
    
    cprintf("  T4: New Slab trigger (alloc_pages) passed.\n");

    //  T5: 收缩 (Shrink) 测试 
    // 释放所有 N+1 个对象
    for (i = 0; i < N + 1; i++) {
        kmem_cache_free(&cache_64, objs[i]);
    }
    assert(cache_64.ref_count == 0);
    // 此时 Slabs 仍在缓存中，页数仍然是 -2
    assert(nr_free_pages() == initial_pages - 2);
    
    // 执行收缩
    kmem_cache_shrink(&cache_64);
    
    // 两个Slab都应被归还给 PMM
    assert(nr_free_pages() == initial_pages); 
    assert(list_empty(&cache_64.slab_list));
    
    cprintf("  T5: Cache shrink (free_pages) passed.\n");

    //  T6: 安全销毁 (Destroy) 测试 
    initial_pages = nr_free_pages();
    o128 = kmem_cache_alloc(&cache_128);
    assert(cache_128.ref_count == 1);
    assert(nr_free_pages() == initial_pages - 1);

    // 尝试销毁一个正在使用的 cache (应该失败)
    kmem_cache_destroy(&cache_128);
    assert(cache_128.ref_count == 1); // 检查 ref_count 没变
    assert(nr_free_pages() == initial_pages - 1); // 检查页数没变

    // 释放最后一个对象
    kmem_cache_free(&cache_128, o128);
    assert(cache_128.ref_count == 0);

    // 尝试销毁一个空闲的 cache (应该成功)
    kmem_cache_destroy(&cache_128);
    // 检查页是否被归还
    assert(nr_free_pages() == initial_pages); 
    assert(strcmp(cache_128.name, "DESTROYED") == 0);

    cprintf("  T6: Safe destroy (ref_count) passed.\n");
    cprintf("SLUB allocator (our design) check finished successfully!\n");
}