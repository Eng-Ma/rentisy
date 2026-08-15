<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { Package, Printer, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير', href: '/reports' },
    { title: 'كشف حركة وتقييم الأصناف', href: '#' },
];

const props = defineProps<{
    items: any[];
    selectedItem?: any;
    movements: any[];
}>();

const onSelectChange = (e: any) => {
    router.get('/reports/stock-movement', { item_id: e.target.value || undefined }, { preserveState: true, replace: true });
};

const printReport = () => window.print();
</script>

<template>
    <Head title="كشف حركة وتقييم الأصناف (Stock Movement)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 no-print">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Package class="w-6 h-6 text-primary" />
                        كشف حركة وتقييم الأصناف (Item Movement Card)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تتبع كامل لسجل الحركات الواردة والصادرة والمناقلات لصنف محدد.
                    </p>
                </div>
                <div class="flex items-center gap-2">
                    <Button variant="outline" as-child>
                        <Link :href="route('reports.index')">رجوع للتقارير</Link>
                    </Button>
                    <Button @click="printReport" class="gap-2">
                        <Printer class="w-4 h-4" />
                        <span>طباعة التقرير</span>
                    </Button>
                </div>
            </div>

            <!-- Item Selector -->
            <div class="max-w-md no-print space-y-1.5">
                <label class="text-xs font-semibold">اختر الصنف لعرض بطاقة الحركة:</label>
                <select :value="selectedItem?.id || ''" @change="onSelectChange" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm font-medium">
                    <option value="">— اختر صنفاً من الدليل —</option>
                    <option v-for="itm in items" :key="itm.id" :value="itm.id">
                        {{ itm.name }} ({{ itm.unit }})
                    </option>
                </select>
            </div>

            <!-- Item Details Card -->
            <div v-if="selectedItem" class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">سعر الشراء (التكلفة)</span>
                    <span class="font-mono font-bold text-lg">{{ Number(selectedItem.purchase_price).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">سعر البيع</span>
                    <span class="font-mono font-bold text-lg text-emerald-600">{{ Number(selectedItem.sales_price).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">التصنيف</span>
                    <span class="font-medium text-sm">{{ selectedItem.category?.name || 'عام' }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">وحدة القياس</span>
                    <span class="font-medium text-sm">{{ selectedItem.unit }}</span>
                </div>
            </div>

            <!-- Movements Table Card -->
            <Card v-if="selectedItem" class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">التاريخ</th>
                                    <th class="px-6 py-3 font-semibold">نوع الحركة</th>
                                    <th class="px-6 py-3 font-semibold">المرجع</th>
                                    <th class="px-6 py-3 font-semibold">الطرف / المستودع</th>
                                    <th class="px-6 py-3 font-semibold text-emerald-600">وارد (+)</th>
                                    <th class="px-6 py-3 font-semibold text-rose-600">صادر (-)</th>
                                    <th class="px-6 py-3 font-semibold">سعر الوحدة</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border font-mono">
                                <tr v-for="(m, idx) in movements" :key="idx" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 text-muted-foreground">{{ m.date }}</td>
                                    <td class="px-6 py-4 font-sans">
                                        <Badge variant="outline">{{ m.type }}</Badge>
                                    </td>
                                    <td class="px-6 py-4 font-bold">{{ m.reference }}</td>
                                    <td class="px-6 py-4 font-sans text-muted-foreground">{{ m.party_name }} ({{ m.store_name }})</td>
                                    <td class="px-6 py-4 text-emerald-600 font-bold">{{ m.in_qty > 0 ? m.in_qty : '—' }}</td>
                                    <td class="px-6 py-4 text-rose-600 font-bold">{{ m.out_qty > 0 ? m.out_qty : '—' }}</td>
                                    <td class="px-6 py-4">{{ Number(m.unit_price).toLocaleString() }}</td>
                                </tr>
                                <tr v-if="movements.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center font-sans text-muted-foreground">
                                        لا توجد حركات مسجلة لهذا الصنف حتى الآن.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <div v-else class="text-center py-16 text-muted-foreground bg-card rounded-xl border border-dashed border-border">
                يرجى اختيار صنف من القائمة أعلاه لعرض بطاقة الحركة وسجل المخزون.
            </div>
        </div>
    </AppLayout>
</template>

<style scoped>
@media print {
    .no-print {
        display: none !important;
    }
}
</style>
