<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { Receipt, Plus, Eye, Trash2, ArrowDownLeft, ArrowUpRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'سندات القبض والصرف',
        href: '/vouchers',
    },
];

interface VoucherItem {
    id: number;
    voucher_number: string;
    type: 'receipt' | 'payment';
    payment_method: 'cash' | 'bank' | 'check';
    date: string;
    amount: number;
    account?: { name: string; code: string };
    party?: { name: string };
    target_account?: { name: string };
    cost_center?: { name: string };
    currency?: { code: string };
    notes?: string;
}

const props = defineProps<{
    vouchers: {
        data: VoucherItem[];
        links: any[];
    };
    currentType?: string;
}>();

const setTypeFilter = (type: string) => {
    router.get('/vouchers', { type: type || undefined }, { preserveState: true, replace: true });
};

const deleteVoucher = (id: number) => {
    if (confirm('هل أنت متأكد من حذف هذا السند؟ سيتم إلغاء القيد المحاسبي المرتبط به.')) {
        router.delete(route('vouchers.destroy', id));
    }
};
</script>

<template>
    <Head title="سندات القبض والصرف (Vouchers)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Receipt class="w-6 h-6 text-primary" />
                        سندات القبض والصرف (Vouchers)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        إدارة المقبوضات والمدفوعات النقدية والبنكية والشيكات مع القيود الآلية.
                    </p>
                </div>
                <div class="flex items-center gap-2">
                    <Button as-child class="bg-emerald-600 hover:bg-emerald-700 text-white gap-2">
                        <Link :href="route('vouchers.create', { type: 'receipt' })">
                            <ArrowDownLeft class="w-4 h-4" />
                            <span>سند قبض جديد</span>
                        </Link>
                    </Button>
                    <Button as-child class="bg-rose-600 hover:bg-rose-700 text-white gap-2">
                        <Link :href="route('vouchers.create', { type: 'payment' })">
                            <ArrowUpRight class="w-4 h-4" />
                            <span>سند صرف جديد</span>
                        </Link>
                    </Button>
                </div>
            </div>

            <!-- Filter tabs -->
            <div class="flex gap-2 border-b border-border pb-3">
                <Button 
                    size="sm" 
                    :variant="!currentType ? 'default' : 'outline'" 
                    @click="setTypeFilter('')"
                >
                    جميع السندات
                </Button>
                <Button 
                    size="sm" 
                    :variant="currentType === 'receipt' ? 'default' : 'outline'" 
                    @click="setTypeFilter('receipt')"
                >
                    سندات القبض (مقبوضات)
                </Button>
                <Button 
                    size="sm" 
                    :variant="currentType === 'payment' ? 'default' : 'outline'" 
                    @click="setTypeFilter('payment')"
                >
                    سندات الصرف (مدفوعات)
                </Button>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">رقم السند</th>
                                    <th class="px-6 py-3 font-semibold">النوع</th>
                                    <th class="px-6 py-3 font-semibold">التاريخ</th>
                                    <th class="px-6 py-3 font-semibold">الطرف / الحساب</th>
                                    <th class="px-6 py-3 font-semibold">طريقة الدفع</th>
                                    <th class="px-6 py-3 font-semibold">المبلغ</th>
                                    <th class="px-6 py-3 font-semibold text-left">إجراءات</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="v in vouchers.data" :key="v.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold">{{ v.voucher_number }}</td>
                                    <td class="px-6 py-4">
                                        <Badge :class="v.type === 'receipt' ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20' : 'bg-rose-500/10 text-rose-600 border-rose-500/20'">
                                            {{ v.type === 'receipt' ? 'سند قبض' : 'سند صرف' }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ v.date }}</td>
                                    <td class="px-6 py-4 font-medium">
                                        {{ v.party?.name || v.target_account?.name || '—' }}
                                    </td>
                                    <td class="px-6 py-4">
                                        <Badge variant="outline">
                                            {{ v.payment_method === 'cash' ? 'نقدي' : (v.payment_method === 'bank' ? 'حوالة بنكية' : 'شيك') }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 font-bold" :class="v.type === 'receipt' ? 'text-emerald-600' : 'text-rose-600'">
                                        {{ Number(v.amount).toLocaleString() }} {{ v.currency?.code || 'ILS' }}
                                    </td>
                                    <td class="px-6 py-4 text-left">
                                        <div class="flex items-center justify-end gap-2">
                                            <Button size="sm" variant="ghost" as-child>
                                                <Link :href="route('vouchers.show', v.id)">
                                                    <Eye class="w-4 h-4" />
                                                </Link>
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10" @click="deleteVoucher(v.id)">
                                                <Trash2 class="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="vouchers.data.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد سندات مسجلة في هذا القسم.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <Pagination :links="vouchers.links" />
        </div>
    </AppLayout>
</template>
