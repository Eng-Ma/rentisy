<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';
import { Receipt, Printer, ArrowRight, ArrowDownLeft, ArrowUpRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const props = defineProps<{
    voucher: any;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'سندات القبض والصرف', href: '/vouchers' },
    { title: props.voucher.voucher_number, href: '#' },
];

const printVoucher = () => {
    window.print();
};
</script>

<template>
    <Head :title="'سند مالي ' + voucher.voucher_number" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between no-print">
                <div class="flex items-center gap-2">
                    <Button variant="outline" as-child>
                        <Link :href="route('vouchers.index')">رجوع لقائمة السندات</Link>
                    </Button>
                </div>
                <Button @click="printVoucher" class="gap-2">
                    <Printer class="w-4 h-4" />
                    <span>طباعة السند</span>
                </Button>
            </div>

            <!-- Printable Voucher Card -->
            <Card class="border-2 border-border shadow-lg p-6 bg-card">
                <!-- Header -->
                <div class="border-b-2 border-border pb-6 flex justify-between items-start">
                    <div>
                        <h2 class="text-2xl font-black text-foreground">نظام الأصيل المحاسبي</h2>
                        <p class="text-xs text-muted-foreground mt-1">سند مالي رسمي معتمد ومقيد دفترياً</p>
                    </div>
                    <div class="text-left font-mono">
                        <div class="text-xl font-bold text-primary">{{ voucher.voucher_number }}</div>
                        <div class="text-xs text-muted-foreground mt-1">التاريخ: {{ voucher.date }}</div>
                    </div>
                </div>

                <!-- Title -->
                <div class="text-center my-6">
                    <span 
                        class="inline-block px-6 py-2 rounded-full text-lg font-bold border"
                        :class="voucher.type === 'receipt' ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/30' : 'bg-rose-500/10 text-rose-600 border-rose-500/30'"
                    >
                        {{ voucher.type === 'receipt' ? 'سَنَد قَبْض مَالِي' : 'سَنَد صَرْف مَالِي' }}
                    </span>
                </div>

                <!-- Content Grid -->
                <div class="space-y-4 text-sm">
                    <div class="flex justify-between items-center p-3 bg-muted/40 rounded-lg">
                        <span class="text-muted-foreground">{{ voucher.type === 'receipt' ? 'استلمنا من السيد/السادة:' : 'صرفنا إلى السيد/السادة:' }}</span>
                        <span class="font-bold text-base">{{ voucher.party?.name || voucher.target_account?.name || '—' }}</span>
                    </div>

                    <div class="flex justify-between items-center p-3 bg-muted/40 rounded-lg">
                        <span class="text-muted-foreground">مبلغ وقدره:</span>
                        <span class="font-mono font-black text-xl text-primary">
                            {{ Number(voucher.amount).toLocaleString() }} {{ voucher.currency?.code || 'ILS' }}
                        </span>
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div class="p-3 bg-muted/40 rounded-lg">
                            <span class="text-muted-foreground block text-xs">طريقة الدفع:</span>
                            <span class="font-semibold">
                                {{ voucher.payment_method === 'cash' ? 'نقدي (كاش)' : (voucher.payment_method === 'bank' ? 'حوالة بنكية' : 'شيك مصرفي') }}
                            </span>
                        </div>
                        <div class="p-3 bg-muted/40 rounded-lg">
                            <span class="text-muted-foreground block text-xs">الحساب المودع فيه/المسحوب منه:</span>
                            <span class="font-semibold">{{ voucher.account?.name }}</span>
                        </div>
                    </div>

                    <div v-if="voucher.cost_center" class="p-3 bg-muted/40 rounded-lg">
                        <span class="text-muted-foreground block text-xs">مركز التكلفة:</span>
                        <span class="font-semibold">{{ voucher.cost_center.name }} ({{ voucher.cost_center.code }})</span>
                    </div>

                    <div v-if="voucher.notes" class="p-3 bg-muted/40 rounded-lg">
                        <span class="text-muted-foreground block text-xs">البيان:</span>
                        <span class="font-medium">{{ voucher.notes }}</span>
                    </div>
                </div>

                <!-- Signatures -->
                <div class="grid grid-cols-2 gap-8 pt-12 mt-8 border-t border-border text-center">
                    <div class="space-y-8">
                        <span class="text-xs text-muted-foreground">توقيع المستلم / المحاسب</span>
                        <div class="border-b border-dashed border-muted-foreground/50 w-2/3 mx-auto"></div>
                    </div>
                    <div class="space-y-8">
                        <span class="text-xs text-muted-foreground">اعتماد الإدارة المالية</span>
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
