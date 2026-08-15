<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { Clock, Printer, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير', href: '/reports' },
    { title: 'أعمار الديون والذمم', href: '#' },
];

const props = defineProps<{
    agingData: any[];
    totals: {
        '0_30': number;
        '31_60': number;
        '61_90': number;
        'over_90': number;
        'total': number;
    };
    type: 'customer' | 'vendor';
}>();

const setType = (t: string) => {
    router.get('/reports/aging', { type: t }, { preserveState: true, replace: true });
};

const printReport = () => window.print();
</script>

<template>
    <Head title="تقرير أعمار الديون (Aging Analysis)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 no-print">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Clock class="w-6 h-6 text-primary" />
                        تقرير أعمار الذمم والديون (Aging Analysis)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تحليل الفترات الزمنية للديون المستحقة وغير المسددة.
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

            <!-- Filter Buttons -->
            <div class="flex gap-2 no-print">
                <Button size="sm" :variant="type === 'customer' ? 'default' : 'outline'" @click="setType('customer')">
                    أعمار ديون العملاء (الذمم المدينة)
                </Button>
                <Button size="sm" :variant="type === 'vendor' ? 'default' : 'outline'" @click="setType('vendor')">
                    أعمار ديون الموردين (الذمم الدائنة)
                </Button>
            </div>

            <!-- Aging Summary Cards -->
            <div class="grid grid-cols-2 sm:grid-cols-5 gap-3">
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">1 - 30 يوماً</span>
                    <span class="font-mono font-bold text-lg text-emerald-600">{{ Number(totals['0_30']).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">31 - 60 يوماً</span>
                    <span class="font-mono font-bold text-lg text-amber-600">{{ Number(totals['31_60']).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">61 - 90 يوماً</span>
                    <span class="font-mono font-bold text-lg text-orange-600">{{ Number(totals['61_90']).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">أكثر من 90 يوماً</span>
                    <span class="font-mono font-bold text-lg text-rose-600">{{ Number(totals['over_90']).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-primary/10 rounded-xl border border-primary/20 col-span-2 sm:col-span-1">
                    <span class="text-xs text-primary font-bold block">إجمالي الذمم</span>
                    <span class="font-mono font-bold text-xl text-primary">{{ Number(totals['total']).toLocaleString() }}</span>
                </div>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">اسم الطرف</th>
                                    <th class="px-6 py-3 font-semibold">الهاتف</th>
                                    <th class="px-6 py-3 font-semibold">1 - 30 يوماً</th>
                                    <th class="px-6 py-3 font-semibold">31 - 60 يوماً</th>
                                    <th class="px-6 py-3 font-semibold">61 - 90 يوماً</th>
                                    <th class="px-6 py-3 font-semibold">+90 يوماً</th>
                                    <th class="px-6 py-3 font-semibold text-left font-bold">الإجمالي المستحق</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border font-mono">
                                <tr v-for="p in agingData" :key="p.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-sans font-medium text-foreground">{{ p.name }}</td>
                                    <td class="px-6 py-4 text-muted-foreground text-xs">{{ p.phone || '—' }}</td>
                                    <td class="px-6 py-4">{{ Number(p['0_30']).toLocaleString() }}</td>
                                    <td class="px-6 py-4">{{ Number(p['31_60']).toLocaleString() }}</td>
                                    <td class="px-6 py-4">{{ Number(p['61_90']).toLocaleString() }}</td>
                                    <td class="px-6 py-4 text-rose-600">{{ Number(p['over_90']).toLocaleString() }}</td>
                                    <td class="px-6 py-4 text-left font-bold text-primary">{{ Number(p.total).toLocaleString() }}</td>
                                </tr>
                                <tr v-if="agingData.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center font-sans text-muted-foreground">
                                        لا توجد ذمم مستحقة غير مسددة في هذا التصنيف.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>
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
