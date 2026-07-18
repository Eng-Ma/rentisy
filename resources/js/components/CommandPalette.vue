<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { router } from '@inertiajs/vue3';
import { Search, FileText, Users, Package, CreditCard, LayoutDashboard, Settings, ArrowLeft } from 'lucide-vue-next';

const isOpen = ref(false);
const searchQuery = ref('');
const searchInput = ref<HTMLInputElement | null>(null);

// Keyboard shortcut to open Cmd+K or Ctrl+K
const handleKeydown = (e: KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        isOpen.value = !isOpen.value;
        if (isOpen.value) {
            setTimeout(() => searchInput.value?.focus(), 100);
        }
    }
    if (e.key === 'Escape' && isOpen.value) {
        isOpen.value = false;
    }
};

onMounted(() => {
    window.addEventListener('keydown', handleKeydown);
});

onUnmounted(() => {
    window.removeEventListener('keydown', handleKeydown);
});

const allCommands = [
    { id: 'dashboard', name: 'الرئيسية (Dashboard)', icon: LayoutDashboard, route: '/dashboard', category: 'عام' },
    { id: 'create_invoice', name: 'إنشاء فاتورة جديدة', icon: FileText, route: '/invoices/create', category: 'الفواتير' },
    { id: 'view_invoices', name: 'عرض الفواتير', icon: FileText, route: '/invoices', category: 'الفواتير' },
    { id: 'accounts', name: 'شجرة الحسابات', icon: CreditCard, route: '/accounts', category: 'المحاسبة' },
    { id: 'create_account', name: 'إضافة حساب جديد', icon: CreditCard, route: '/accounts/create', category: 'المحاسبة' },
    { id: 'parties', name: 'العملاء والموردين', icon: Users, route: '/parties', category: 'الجهات' },
    { id: 'items', name: 'الأصناف والمخزون', icon: Package, route: '/items', category: 'المخزون' },
    { id: 'reports', name: 'التقارير المالية', icon: FileText, route: '/reports/income-statement', category: 'التقارير' },
    { id: 'settings', name: 'إعدادات الحساب', icon: Settings, route: '/settings/profile', category: 'الإعدادات' },
];

const filteredCommands = computed(() => {
    if (!searchQuery.value) return allCommands;
    const q = searchQuery.value.toLowerCase();
    return allCommands.filter(c => c.name.toLowerCase().includes(q) || c.category.toLowerCase().includes(q));
});

const executeCommand = (route: string) => {
    isOpen.value = false;
    searchQuery.value = '';
    router.visit(route);
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[100] flex items-start justify-center pt-[10vh] sm:pt-[15vh]">
        <!-- Backdrop -->
        <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm transition-opacity" @click="isOpen = false"></div>
        
        <!-- Palette Modal -->
        <div class="relative w-full max-w-2xl transform overflow-hidden rounded-3xl bg-white/90 dark:bg-gray-900/90 shadow-[0_0_50px_-12px_rgba(79,70,229,0.3)] ring-1 ring-black/5 transition-all backdrop-blur-2xl dark:ring-white/10"
             role="dialog" aria-modal="true" dir="rtl">
            
            <!-- Glow Effect behind the modal -->
            <div class="absolute -left-20 -top-20 w-64 h-64 bg-indigo-500/20 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
            <div class="absolute -right-20 -bottom-20 w-64 h-64 bg-purple-500/20 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
            
            <!-- Search Input -->
            <div class="relative border-b border-gray-100 dark:border-gray-800/50 z-10">
                <Search class="pointer-events-none absolute right-5 top-5 h-6 w-6 text-indigo-500" />
                <input
                    ref="searchInput"
                    v-model="searchQuery"
                    type="text"
                    class="h-16 w-full bg-transparent pl-4 pr-16 text-gray-900 dark:text-white placeholder-gray-400 focus:ring-0 text-lg border-0 outline-none"
                    placeholder="ماذا تريد أن تفعل؟ (بحث عن صفحة، أو إجراء...)"
                    role="combobox"
                    aria-expanded="false"
                    aria-controls="options"
                />
                <div class="absolute left-4 top-4 flex items-center gap-2">
                    <span class="text-[10px] font-bold text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded shadow-inner">ESC</span>
                </div>
            </div>

            <!-- Results List -->
            <div class="max-h-[60vh] scroll-py-3 overflow-y-auto p-3 z-10 relative">
                <div v-if="filteredCommands.length > 0">
                    <div class="space-y-2">
                        <button
                            v-for="(command, index) in filteredCommands"
                            :key="command.id"
                            @click="executeCommand(command.route)"
                            class="group flex w-full items-center rounded-2xl p-3 text-right hover:bg-indigo-50/50 dark:hover:bg-indigo-900/30 transition-all duration-200 focus:bg-indigo-50 outline-none transform hover:scale-[1.01]"
                        >
                            <div class="flex h-12 w-12 flex-none items-center justify-center rounded-xl bg-gradient-to-br from-indigo-100 to-purple-100 dark:from-indigo-900/50 dark:to-purple-900/50 group-hover:from-indigo-200 group-hover:to-purple-200 dark:group-hover:from-indigo-800 dark:group-hover:to-purple-800 transition-colors shadow-sm">
                                <component :is="command.icon" class="h-6 w-6 text-indigo-600 dark:text-indigo-400" />
                            </div>
                            <div class="mr-4 flex-auto">
                                <p class="text-base font-bold text-gray-900 dark:text-white group-hover:text-indigo-700 dark:group-hover:text-indigo-300">
                                    {{ command.name }}
                                </p>
                                <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5 font-medium">
                                    {{ command.category }}
                                </p>
                            </div>
                            <ArrowLeft class="h-5 w-5 text-gray-300 group-hover:text-indigo-500 ml-2 transition-transform group-hover:-translate-x-1" />
                        </button>
                    </div>
                </div>

                <!-- Empty State -->
                <div v-else class="px-6 py-16 text-center text-sm sm:px-14">
                    <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 dark:bg-gray-800/50 border border-dashed border-gray-300 dark:border-gray-700">
                        <Search class="h-8 w-8 text-gray-400" />
                    </div>
                    <p class="mt-4 text-lg font-bold text-gray-900 dark:text-white">لم يتم العثور على نتائج</p>
                    <p class="mt-2 text-gray-500 dark:text-gray-400">لا يوجد أي تطابق مع بحثك "{{ searchQuery }}"</p>
                </div>
            </div>
            
            <!-- Footer Hints -->
            <div class="bg-gray-50/50 dark:bg-gray-800/30 px-6 py-3 border-t border-gray-100 dark:border-gray-800/50 flex justify-between items-center text-xs text-gray-500 z-10 relative">
                <div class="flex items-center gap-3">
                    <span class="flex items-center gap-1">استخدم <kbd class="bg-white dark:bg-gray-700 px-1.5 py-0.5 rounded shadow-sm border border-gray-200 dark:border-gray-600 font-sans">↑</kbd> <kbd class="bg-white dark:bg-gray-700 px-1.5 py-0.5 rounded shadow-sm border border-gray-200 dark:border-gray-600 font-sans">↓</kbd> للتنقل</span>
                    <span class="flex items-center gap-1">و <kbd class="bg-white dark:bg-gray-700 px-1.5 py-0.5 rounded shadow-sm border border-gray-200 dark:border-gray-600 font-sans">Enter</kbd> للاختيار</span>
                </div>
                <div>الوصول السريع للمشروع</div>
            </div>
        </div>
    </div>
</template>
