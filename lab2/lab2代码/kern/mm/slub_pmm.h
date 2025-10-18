/* --- slub.h --- */
#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>

#define list_for_each(pos, head) \
    for (pos = (head)->next; pos != (head); pos = pos->next)
// kmem_cache 结构体定义
struct kmem_cache {
    const char *name;           // 缓存的名称
    size_t object_size;         // 本缓存管理的固定块的大小（字节）
    list_entry_t slab_list;    // 缓存管理的 Slab 链表
    size_t slab_pages;          // 每个 Slab 包含的物理页数（本实现简化为 1）
    unsigned int objects_per_slab; // 每个 Slab 能容纳的固定大小块的数量
    unsigned int ref_count;     // 引用计数器
};

void slub_check(void); //SLUB 测试函数
#endif