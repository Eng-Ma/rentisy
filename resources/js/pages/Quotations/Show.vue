<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { FileSpreadsheet, Printer, ArrowRight, CheckCircle2 } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const props = defineProps<{
    quotation: any;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'عروض الأسعار', href: '/quotations' },
    { title: props.quotation.quotation_number, href: '#' },
];

const printQuote = () => {
    window.print();
};

const convertToInvoice = () => {
    if (confirm('هل ترغب بتحويل عرض السعر هذا إلى فاتورة مبيعات؟')) {
        router.post(route('quotations.convert', props.quotation.id));
    }
};
</script>

<template>
    <Head :title="'عرض سعر ' + quotation.quotation_number" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between no-print">
                <Button variant="outline" as-child>
                    <Link :href="route('quotations.index')">رجوع لقائمة العروض</Link>
                </Button>
                <div class="flex items-center gap-2">
                    <Button v-if="quotation.status !== 'converted'" @click="convertToInvoice" class="bg-emerald-600 hover:bg-emerald-700 text-white gap-2">
                        <CheckCircle2 class="w-4 h-4" />
                        <span>تحويل لفاتورة مبيعات</span>
                    </Button>
                    <Button @click="printQuote" variant="outline" class="gap-2">
                        <Printer class="w-4 h-4" />
                        <span>طباعة العرض</span>
                    </Button>
                </div>
            </div>

            <Card class="border-2 border-border shadow-lg p-6 bg-card">
                <!-- Header -->
                <div class="border-b-2 border-border pb-6 flex justify-between items-start">
                    <div>
                        <h2 class="text-2xl font-black text-foreground">نظام الأصيل للمبيعات</h2>
                        <p class="text-xs text-muted-foreground mt-1">عرض أسعار تجاري رسمي (Price Quotation)</p>
                    </div>
                    <div class="text-left font-mono">
                        <div class="text-xl font-bold text-primary">{{ quotation.quotation_number }}</div>
                        <div class="text-xs text-muted-foreground mt-1">التاريخ: {{ quotation.date }}</div>
                        <div v-if="quotation.expiry_date" class="text-xs text-muted-foreground">صالح حتى: {{ quotation.expiry_date }}</div>
                    </div>
                </div>

                <!-- Customer Details -->
                <div class="p-4 my-6 bg-muted/40 rounded-lg flex justify-between items-center text-sm">
                    <div>
                        <span class="text-xs text-muted-foreground block">مقدم إلى السيد/السادة:</span>
                        <span class="font-bold text-base">{{ quotation.party?.name }}</span>
                        <span v-if="quotation.party?.phone" class="text-xs text-muted-foreground block mt-0.5">هاتف: {{ quotation.party.phone }}</span>
                    </div>
                    <div>
                        <Badge v-if="quotation.status === 'converted'" class="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">
                            تم التحويل لفاتورة #{{ quotation.converted_invoice_id }}
                        </Badge>
                        <Badge v-else variant="outline">عرض سعر ساري</Badge>
                    </div>
                </div>

                <!-- Lines Table -->
                <div class="border border-border rounded-lg overflow-hidden my-6">
                    <table class="w-full text-sm text-right">
                        <thead class="bg-muted/60 text-muted-foreground border-b border-border">
                            <tr>
                                <th class="px-4 py-3 font-semibold">#</th>
                                <th class="px-4 py-3 font-semibold">الصنف والبيان</th>
                                <th class="px-4 py-3 font-semibold">الكمية</th>
                                <th class="px-4 py-3 font-semibold">سعر الوحدة</th>
                                <th class="px-4 py-3 font-semibold text-left">الإجمالي</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-border">
                            <tr v-for="(line, idx) in quotation.lines" :key="line.id">
                                <td class="px-4 py-3 text-muted-foreground">{{ idx + 1 }}</td>
                                <td class="px-4 py-3 font-medium">{{ line.item?.name }}</td>
                                <td class="px-4 py-3 font-mono font-bold">{{ line.quantity }} {{ line.item?.unit }}</td>
                                <td class="px-4 py-3 font-mono">{{ Number(line.unit_price).toLocaleString() }}</td>
                                <td class="px-4 py-3 font-mono font-bold text-left">{{ Number(line.total_price).toLocaleString() }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Financial Totals -->
                <div class="flex justify-end my-6">
                    <div class="w-full max-w-xs space-y-2 text-sm bg-muted/40 p-4 rounded-xl border border-border">
                        <div class="flex justify-between">
                            <span class="text-muted-foreground">المجموع:</span>
                            <span class="font-mono font-bold">{{ Number(quotation.subtotal).toLocaleString() }}</span>
                        </div>
                        <div v-if="quotation.discount > 0" class="flex justify-between text-rose-600">
                            <span>الخصم:</span>
                            <span class="font-mono font-bold">- {{ Number(quotation.discount).toLocaleString() }}</span>
                        </div>
                        <div class="border-t border-border pt-2 flex justify-between text-base font-bold text-primary">
                            <span>المبلغ الصافي:</span>
                            <span class="font-mono text-xl">{{ Number(quotation.total_amount).toLocaleString() }}</span>
                        </div>
                    </div>
                </div>

                <div v-if="quotation.notes" class="p-3 bg-muted/40 rounded-lg text-xs text-muted-foreground mb-8">
                    <span class="font-bold text-foreground block mb-1">ملاحظات وشروط:</span>
                    <span>{{ quotation.notes }}</span>
                </div>

                <!-- Signatures -->
                <div class="grid grid-cols-2 gap-8 pt-10 border-t border-border text-center">
                    <div class="space-y-6">
                        <span class="text-xs text-muted-foreground">توقيع مسؤول المبيعات</span>
                        <div class="border-b border-dashed border-muted-foreground/50 w-2/3 mx-auto"></div>
                    </div>
                    <div class="space-y-6">
                        <span class="text-xs text-muted-foreground">موافقة العميل والاعتماد</span>
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
