<script setup lang="ts">
import { SidebarGroup, SidebarGroupLabel, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from '@/components/ui/sidebar';
import { type SharedData } from '@/types';
import { Link, usePage } from '@inertiajs/vue3';
import type { Component } from 'vue';

export interface NavGroup {
    label: string;
    items: {
        title: string;
        href: string;
        icon: Component;
    }[];
}

defineProps<{
    groups: NavGroup[];
}>();

const page = usePage<SharedData>();
</script>

<template>
    <div class="space-y-4 py-2">
        <SidebarGroup v-for="group in groups" :key="group.label" class="px-2 py-0">
            <SidebarGroupLabel class="text-[11px] font-bold text-muted-foreground/70 uppercase tracking-wider px-2 mb-1">
                {{ group.label }}
            </SidebarGroupLabel>
            <SidebarMenu>
                <SidebarMenuItem v-for="item in group.items" :key="item.title">
                    <SidebarMenuButton as-child :is-active="item.href === page.url" class="gap-2.5 rounded-lg text-sm font-medium">
                        <Link :href="item.href">
                            <component :is="item.icon" class="w-4 h-4 shrink-0 opacity-80" />
                            <span class="truncate">{{ item.title }}</span>
                        </Link>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            </SidebarMenu>
        </SidebarGroup>
    </div>
</template>
