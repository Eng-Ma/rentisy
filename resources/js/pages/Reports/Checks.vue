<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { CreditCard, Printer, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير', href: '/reports' },
    { title: 'تقرير حافظة الشيكات', href: '#' },
];

const props = defineProps<{
    checks: any[];
    stats: {
        total_received: number;
        total_issued: number;
        under_collection: number;
        collected: number;
    };
    filters?: any;
}>();

const setFilter = (type?: string, status?: string) => {
    router.get('/reports/checks', { type, status }, { preserveState: true, replace: true });
};

const printReport = () => window.print();
</script>

<template>
    <Head title="تقرير حافظة الشيكات (Checks Report)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 no-print">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <CreditCard class="w-6 h-6 text-primary" />
                        تقرير وحافظة الشيكات المصرفية (Checks Portfolio)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تقرير شامل ببيانات الشيكات الواردة والصادرة وحالات التحصيل ومواعيد الاستحقاق.
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

            <!-- Stats Grid -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">إجمالي الشيكات الواردة</span>
                    <span class="font-mono font-bold text-xl text-emerald-600">{{ Number(stats.total_received).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">إجمالي الشيكات الصادرة</span>
                    <span class="font-mono font-bold text-xl text-rose-600">{{ Number(stats.total_issued).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">شيكات برسم التحصيل (معلقة)</span>
                    <span class="font-mono font-bold text-xl text-amber-600">{{ Number(stats.under_collection).toLocaleString() }}</span>
                </div>
                <div class="p-4 bg-muted/40 rounded-xl border border-border">
                    <span class="text-xs text-muted-foreground block">شيكات تم تحصيلها بالبنك</span>
                    <span class="font-mono font-bold text-xl text-primary">{{ Number(stats.collected).toLocaleString() }}</span>
                </div>
            </div>

            <!-- Filter Buttons -->
            <div class="flex flex-wrap gap-2 no-print">
                <Button size="sm" :variant="!filters?.type && !filters?.status ? 'default' : 'outline'" @click="setFilter('', '')">
                    الكل
                </Button>
                <Button size="sm" :variant="filters?.type === 'received' ? 'default' : 'outline'" @click="setFilter('received', undefined)">
                    شيكات واردة
                </Button>
                <Button size="sm" :variant="filters?.type === 'issued' ? 'default' : 'outline'" @click="setFilter('issued', undefined)">
                    شيكات صادرة
                </Button>
                <Button size="sm" :variant="filters?.status === 'under_collection' ? 'default' : 'outline'" @click="setFilter(undefined, 'under_collection')">
                    برسم التحصيل فقط
                </Button>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">رقم الشيك</th>
                                    <th class="px-6 py-3 font-semibold">النوع</th>
                                    <th class="px-6 py-3 font-semibold">البنك</th>
                                    <th class="px-6 py-3 font-semibold">الساحب / العميل</th>
                                    <th class="px-6 py-3 font-semibold">تاريخ الاستحقاق</th>
                                    <th class="px-6 py-3 font-semibold">المبلغ</th>
                                    <th class="px-6 py-3 font-semibold">الحالة</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="chk in checks" :key="chk.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold">{{ chk.check_number }}</td>
                                    <td class="px-6 py-4">
                                        <Badge :variant="chk.type === 'received' ? 'default' : 'outline'">
                                            {{ chk.type === 'received' ? 'وارد' : 'صادر' }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ chk.bank_name }}</td>
                                    <td class="px-6 py-4 font-medium">{{ chk.party?.name || chk.drawer_name || '—' }}</td>
                                    <td class="px-6 py-4 font-mono text-xs">{{ chk.due_date }}</td>
                                    <td class="px-6 py-4 font-mono font-bold text-primary">
                                        {{ Number(chk.amount).toLocaleString() }} {{ chk.currency?.code || 'ILS' }}
                                    </td>
                                    <td class="px-6 py-4">
                                        <Badge v-if="chk.status === 'under_collection'" class="bg-amber-500/10 text-amber-600 border-amber-500/20">
                                            برسم التحصيل
                                        </Badge>
                                        <Badge v-else-if="chk.status === 'collected'" class="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">
                                            محصل
                                        </Badge>
                                        <Badge v-else-if="chk.status === 'endorsed'" class="bg-indigo-500/10 text-indigo-600 border-indigo-500/20">
                                            مجير
                                        </Badge>
                                        <Badge v-else variant="outline">مرتجع/ملغي</Badge>
                                    </td>
                                </tr>
                                <tr v-if="checks.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد شيكات مطابقة.
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
