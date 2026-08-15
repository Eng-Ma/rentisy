<script setup lang="ts">
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from '@/components/ui/breadcrumb';
import { SidebarTrigger } from '@/components/ui/sidebar';
import type { BreadcrumbItemType } from '@/types';
import { Compass } from 'lucide-vue-next';
import SystemGuideModal from '@/components/SystemGuideModal.vue';
import { ref } from 'vue';

defineProps<{
    breadcrumbs?: BreadcrumbItemType[];
}>();

const headerGuideRef = ref<InstanceType<typeof SystemGuideModal> | null>(null);

const openGuide = () => {
    headerGuideRef.value?.openGuide();
};
</script>

<template>
    <header
        class="flex h-16 shrink-0 items-center justify-between gap-2 border-b border-sidebar-border/70 px-6 transition-[width,height] ease-linear group-has-[[data-collapsible=icon]]/sidebar-wrapper:h-12 md:px-4"
    >
        <div class="flex items-center gap-2">
            <SidebarTrigger class="-ml-1" />
            <template v-if="breadcrumbs && breadcrumbs.length > 0">
                <Breadcrumb>
                    <BreadcrumbList>
                        <template v-for="(item, index) in breadcrumbs" :key="index">
                            <BreadcrumbItem>
                                <template v-if="index === breadcrumbs.length - 1">
                                    <BreadcrumbPage>{{ item.title }}</BreadcrumbPage>
                                </template>
                                <template v-else>
                                    <BreadcrumbLink :href="item.href">
                                        {{ item.title }}
                                    </BreadcrumbLink>
                                </template>
                            </BreadcrumbItem>
                            <BreadcrumbSeparator v-if="index !== breadcrumbs.length - 1" />
                        </template>
                    </BreadcrumbList>
                </Breadcrumb>
            </template>
        </div>

        <div class="flex items-center gap-2">
            <button 
                @click="openGuide" 
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg bg-muted/60 hover:bg-muted text-muted-foreground hover:text-foreground transition-colors border border-border"
                title="فتح دليل الاستخدام السريع"
            >
                <Compass class="w-3.5 h-3.5 text-primary" />
                <span>دليل النظام</span>
            </button>
        </div>

        <!-- Global Header Guide Modal -->
        <SystemGuideModal ref="headerGuideRef" :auto-open-first-time="false" />
    </header>
</template>
