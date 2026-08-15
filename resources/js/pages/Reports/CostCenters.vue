<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { Target, Printer, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير', href: '/reports' },
    { title: 'كشف مراكز التكلفة', href: '#' },
];

const props = defineProps<{
    costCenters: any[];
    selectedId?: string;
    reportData: any[];
    totalDebit: number;
    totalCredit: number;
    netBalance: number;
}>();

const onSelectChange = (e: any) => {
    router.get('/reports/cost-centers', { cost_center_id: e.target.value || undefined }, { preserveState: true, replace: true });
};

const printReport = () => window.print();
</script>

<template>
    <Head title="كشف مراكز التكلفة (Cost Centers Statement)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 no-print">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Target class="w-6 h-6 text-primary" />
                        كشف حساب مراكز التكلفة (Cost Centers Statement)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        عرض وتدقيق الحركات المالية وتكلفة ومردود كل مركز أو مشروع.
                    </p>
                </div>
                <div class="flex items-center gap-2">
                    <Button variant="outline" as-child>
                        <Link :href="route('reports.index')">رجوع للتقارير</Link>
                    </Button>
                    <Button @click="printReport" class="gap-2">
                        <Printer class="w-4 h-4" />
                        <span>طباعة الكشف</span>
                    </Button>
                </div>
            </div>

            <!-- Selector -->
            <div class="max-w-md no-print space-y-1.5">
                <label class="text-xs font-semibold">اختر مركز التكلفة لعرض كشف الحساب:</label>
                <select :value="selectedId || ''" @change="onSelectChange" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm font-medium">
                    <option value="">— اختر مركز تكلفة —</option>
                    <option v-for="cc in costCenters" :key="cc.id" :value="cc.id">
                        {{ cc.code }} - {{ cc.name }}
                    </option>
                </select>
            </div>

            <!-- Financial Summary -->
            <div v-if="selectedId" class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">إجمالي المدين (المصروفات/التكاليف)</span>
                    <span class="font-mono font-bold text-xl text-rose-600">{{ Number(totalDebit).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">إجمالي الدائن (الإيرادات/المخصصات)</span>
                    <span class="font-mono font-bold text-xl text-emerald-600">{{ Number(totalCredit).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-primary/10 rounded-xl border border-primary/20">
                    <span class="text-xs text-primary font-bold block">صافي رصيد المركز</span>
                    <span class="font-mono font-bold text-xl text-primary">{{ Number(netBalance).toLocaleString() }}</span>
                </div>
            </div>

            <!-- Table Card -->
            <Card v-if="selectedId" class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">التاريخ</th>
                                    <th class="px-6 py-3 font-semibold">المرجع</th>
                                    <th class="px-6 py-3 font-semibold">الحساب المالي</th>
                                    <th class="px-6 py-3 font-semibold">البيان</th>
                                    <th class="px-6 py-3 font-semibold">مدين</th>
                                    <th class="px-6 py-3 font-semibold">دائن</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border font-mono">
                                <tr v-for="(l, idx) in reportData" :key="idx" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 text-muted-foreground">{{ l.date }}</td>
                                    <td class="px-6 py-4 font-bold">{{ l.reference || '—' }}</td>
                                    <td class="px-6 py-4 font-sans font-medium text-foreground">{{ l.account_code }} - {{ l.account_name }}</td>
                                    <td class="px-6 py-4 font-sans text-muted-foreground">{{ l.description }}</td>
                                    <td class="px-6 py-4 text-rose-600">{{ l.debit > 0 ? Number(l.debit).toLocaleString() : '—' }}</td>
                                    <td class="px-6 py-4 text-emerald-600">{{ l.credit > 0 ? Number(l.credit).toLocaleString() : '—' }}</td>
                                </tr>
                                <tr v-if="reportData.length === 0">
                                    <td colspan="6" class="px-6 py-10 text-center font-sans text-muted-foreground">
                                        لا توجد حركات مالية مسجلة على هذا المركز حتى الآن.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <div v-else class="text-center py-16 text-muted-foreground bg-card rounded-xl border border-dashed border-border">
                يرجى اختيار مركز تكلفة من القائمة أعلاه لعرض كشف الحساب التفصيلي.
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
