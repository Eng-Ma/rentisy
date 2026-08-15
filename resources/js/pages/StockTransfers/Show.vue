<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';
import { ArrowLeftRight, Printer, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const props = defineProps<{
    transfer: any;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'مناقلات وحركات المخزون', href: '/stock-transfers' },
    { title: props.transfer.transfer_number, href: '#' },
];

const printTransfer = () => {
    window.print();
};
</script>

<template>
    <Head :title="'سند حركة مخزون ' + transfer.transfer_number" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between no-print">
                <Button variant="outline" as-child>
                    <Link :href="route('stock-transfers.index')">رجوع لقائمة الحركات</Link>
                </Button>
                <Button @click="printTransfer" class="gap-2">
                    <Printer class="w-4 h-4" />
                    <span>طباعة المستند</span>
                </Button>
            </div>

            <Card class="border-2 border-border shadow-lg p-6 bg-card">
                <!-- Header -->
                <div class="border-b-2 border-border pb-6 flex justify-between items-start">
                    <div>
                        <h2 class="text-2xl font-black text-foreground">نظام الأصيل للمستودعات</h2>
                        <p class="text-xs text-muted-foreground mt-1">سند مناقلة وحركة بضاعة رسمي</p>
                    </div>
                    <div class="text-left font-mono">
                        <div class="text-xl font-bold text-primary">{{ transfer.transfer_number }}</div>
                        <div class="text-xs text-muted-foreground mt-1">التاريخ: {{ transfer.date }}</div>
                    </div>
                </div>

                <!-- Info Grid -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 my-6 text-sm">
                    <div class="p-3 bg-muted/40 rounded-lg">
                        <span class="text-xs text-muted-foreground block">نوع الحركة:</span>
                        <span class="font-bold">
                            {{ transfer.type === 'transfer' ? 'مناقلة بين مستودعين' : (transfer.type === 'stock_in' ? 'إدخال بضاعة' : (transfer.type === 'stock_out' ? 'إخراج بضاعة' : 'تسوية جردية')) }}
                        </span>
                    </div>
                    <div class="p-3 bg-muted/40 rounded-lg">
                        <span class="text-xs text-muted-foreground block">من مستودع:</span>
                        <span class="font-bold">{{ transfer.from_store?.name || '—' }}</span>
                    </div>
                    <div class="p-3 bg-muted/40 rounded-lg">
                        <span class="text-xs text-muted-foreground block">إلى مستودع:</span>
                        <span class="font-bold">{{ transfer.to_store?.name || '—' }}</span>
                    </div>
                </div>

                <!-- Lines Table -->
                <div class="border border-border rounded-lg overflow-hidden my-6">
                    <table class="w-full text-sm text-right">
                        <thead class="bg-muted/60 text-muted-foreground border-b border-border">
                            <tr>
                                <th class="px-4 py-3 font-semibold">#</th>
                                <th class="px-4 py-3 font-semibold">الصنف</th>
                                <th class="px-4 py-3 font-semibold">الكمية</th>
                                <th class="px-4 py-3 font-semibold">الوحدة</th>
                                <th class="px-4 py-3 font-semibold">التكلفة التقديرية</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-border">
                            <tr v-for="(line, idx) in transfer.lines" :key="line.id">
                                <td class="px-4 py-3 text-muted-foreground">{{ idx + 1 }}</td>
                                <td class="px-4 py-3 font-medium">{{ line.item?.name }}</td>
                                <td class="px-4 py-3 font-bold font-mono text-primary">{{ line.quantity }}</td>
                                <td class="px-4 py-3 text-muted-foreground">{{ line.item?.unit }}</td>
                                <td class="px-4 py-3 font-mono">{{ Number(line.unit_cost).toLocaleString() }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div v-if="transfer.notes" class="p-3 bg-muted/40 rounded-lg text-sm mb-6">
                    <span class="text-muted-foreground block text-xs">ملاحظات:</span>
                    <span>{{ transfer.notes }}</span>
                </div>

                <!-- Signatures -->
                <div class="grid grid-cols-2 gap-8 pt-10 border-t border-border text-center">
                    <div class="space-y-6">
                        <span class="text-xs text-muted-foreground">أمين المستودع (المسؤول)</span>
                        <div class="border-b border-dashed border-muted-foreground/50 w-2/3 mx-auto"></div>
                    </div>
                    <div class="space-y-6">
                        <span class="text-xs text-muted-foreground">المستلم / المحاسب</span>
                        <div class="border-b border-dashed border-muted-foreground/50 w-2/3 mx-auto"></div>
                    </div>
                </div>
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
