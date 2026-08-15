<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue';
import { router } from '@inertiajs/vue3';
import { 
    Search, 
    FileText, 
    Users, 
    Package, 
    CreditCard, 
    LayoutDashboard, 
    Settings, 
    ArrowLeft,
    Receipt,
    Target,
    ArrowLeftRight,
    FileSpreadsheet,
    Building2,
    LineChart,
    Bot
} from 'lucide-vue-next';

const isOpen = ref(false);
const searchQuery = ref('');
const searchInput = ref<HTMLInputElement | null>(null);

const handleKeydown = (e: KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        isOpen.value = !isOpen.value;
        if (isOpen.value) {
            nextTick(() => searchInput.value?.focus());
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
    { id: 'vouchers', name: 'سندات القبض والصرف', icon: Receipt, route: '/vouchers', category: 'السندات' },
    { id: 'create_voucher', name: 'إنشاء سند مالي جديد', icon: Receipt, route: '/vouchers/create', category: 'السندات' },
    { id: 'checks', name: 'حافظة ودورة حياة الشيكات', icon: CreditCard, route: '/checks', category: 'الشيكات' },
    { id: 'cost_centers', name: 'دليل مراكز التكلفة والمشاريع', icon: Target, route: '/cost-centers', category: 'المحاسبة' },
    { id: 'stock_transfers', name: 'مناقلات وحركات المستودعات', icon: ArrowLeftRight, route: '/stock-transfers', category: 'المخزون' },
    { id: 'create_stock_transfer', name: 'تسجيل مناقلة مخزون جديدة', icon: ArrowLeftRight, route: '/stock-transfers/create', category: 'المخزون' },
    { id: 'quotations', name: 'عروض الأسعار للعملاء', icon: FileSpreadsheet, route: '/quotations', category: 'المبيعات' },
    { id: 'create_quotation', name: 'إنشاء عرض سعر جديد', icon: FileSpreadsheet, route: '/quotations/create', category: 'المبيعات' },
    { id: 'fixed_assets', name: 'الأصول الثابتة والإهلاك', icon: Building2, route: '/fixed-assets', category: 'الأصول' },
    { id: 'aging_report', name: 'تقرير أعمار الديون (Aging)', icon: LineChart, route: '/reports/aging', category: 'التقارير' },
    { id: 'cost_centers_report', name: 'كشف حساب مراكز التكلفة', icon: LineChart, route: '/reports/cost-centers', category: 'التقارير' },
    { id: 'checks_report', name: 'تقرير حافظة الشيكات', icon: CreditCard, route: '/reports/checks', category: 'التقارير' },
    { id: 'stock_movement_report', name: 'كشف حركة وتقييم الأصناف', icon: Package, route: '/reports/stock-movement', category: 'التقارير' },
    { id: 'create_invoice', name: 'إنشاء فاتورة جديدة', icon: FileText, route: '/invoices/create', category: 'الفواتير' },
    { id: 'view_invoices', name: 'عرض الفواتير', icon: FileText, route: '/invoices', category: 'الفواتير' },
    { id: 'accounts', name: 'شجرة الحسابات', icon: CreditCard, route: '/accounts', category: 'المحاسبة' },
    { id: 'create_account', name: 'إضافة حساب جديد', icon: CreditCard, route: '/accounts/create', category: 'المحاسبة' },
    { id: 'parties', name: 'العملاء والموردين', icon: Users, route: '/parties', category: 'الجهات' },
    { id: 'items', name: 'الأصناف والمخزون', icon: Package, route: '/items', category: 'المخزون' },
    { id: 'reports', name: 'جميع التقارير المالية', icon: LineChart, route: '/reports', category: 'التقارير' },
    { id: 'mcp_settings', name: 'اتصالات الذكاء الاصطناعي (MCP)', icon: Bot, route: '/settings/mcp', category: 'الإعدادات' },
    { id: 'settings', name: 'إعدادات الحساب', icon: Settings, route: '/settings/profile', category: 'الإعدادات' },
];

const filteredCommands = computed(() => {
    if (!searchQuery.value) return allCommands;
    const q = searchQuery.value.toLowerCase().trim();
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
        <!-- High-Performance Dark Backdrop -->
        <div class="fixed inset-0 bg-black/60 transition-opacity" @click="isOpen = false"></div>
        
        <!-- Palette Modal Box (Zero Lag - Hardware Accelerated) -->
        <div class="relative w-full max-w-2xl transform overflow-hidden rounded-2xl bg-card border border-border shadow-2xl transition-all"
             role="dialog" aria-modal="true" dir="rtl">
            
            <!-- Search Input Bar -->
            <div class="relative border-b border-border z-10 flex items-center bg-card">
                <Search class="pointer-events-none absolute right-4 h-5 w-5 text-primary" />
                <input
                    ref="searchInput"
                    v-model="searchQuery"
                    type="text"
                    class="h-14 w-full bg-transparent pl-4 pr-12 text-foreground placeholder-muted-foreground focus:outline-none text-base border-0"
                    placeholder="ماذا تريد أن تفعل؟ (ابحث عن صفحة، تقرير، أو سند...)"
                />
                <div class="absolute left-4 flex items-center gap-1">
                    <span class="text-[11px] font-mono font-semibold text-muted-foreground bg-muted px-2 py-0.5 rounded border border-border">ESC</span>
                </div>
            </div>

            <!-- Optimized Scrollable List -->
            <div class="max-h-[55vh] overflow-y-auto p-2 divide-y divide-border/40" style="-webkit-overflow-scrolling: touch; overscroll-behavior: contain;">
                <div v-if="filteredCommands.length > 0" class="space-y-1">
                    <button
                        v-for="command in filteredCommands"
                        :key="command.id"
                        @click="executeCommand(command.route)"
                        class="group flex w-full items-center rounded-xl p-2.5 text-right hover:bg-muted transition-colors outline-none"
                    >
                        <div class="flex h-10 w-10 flex-none items-center justify-center rounded-lg bg-primary/10 text-primary transition-colors">
                            <component :is="command.icon" class="h-5 w-5" />
                        </div>
                        <div class="mr-3 flex-auto">
                            <p class="text-sm font-bold text-foreground group-hover:text-primary transition-colors">
                                {{ command.name }}
                            </p>
                            <p class="text-xs text-muted-foreground mt-0.5">
                                {{ command.category }}
                            </p>
                        </div>
                        <ArrowLeft class="h-4 w-4 text-muted-foreground group-hover:text-primary ml-2 transition-transform group-hover:-translate-x-1" />
                    </button>
                </div>

                <!-- Empty State -->
                <div v-else class="px-6 py-12 text-center text-sm">
                    <Search class="h-8 w-8 text-muted-foreground mx-auto mb-2 opacity-50" />
                    <p class="font-bold text-foreground">لم يتم العثور على نتائج</p>
                    <p class="text-xs text-muted-foreground mt-1">لا يوجد أي تطابق مع بحثك "{{ searchQuery }}"</p>
                </div>
            </div>
            
            <!-- Footer -->
            <div class="bg-muted/50 px-4 py-2.5 border-t border-border flex justify-between items-center text-xs text-muted-foreground">
                <div class="flex items-center gap-2">
                    <span>استخدم <kbd class="bg-background px-1.5 py-0.5 rounded border border-border font-mono text-[10px]">↑</kbd> <kbd class="bg-background px-1.5 py-0.5 rounded border border-border font-mono text-[10px]">↓</kbd> للتنقل</span>
                    <span>و <kbd class="bg-background px-1.5 py-0.5 rounded border border-border font-mono text-[10px]">Enter</kbd> للفتح</span>
                </div>
                <div class="text-[11px] font-medium text-primary">نظام الأصيل للمحاسبة</div>
            </div>
        </div>
    </div>
</template>
