<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { ArrowLeftRight, Plus, Eye, Trash2 } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'مناقلات وحركات المخزون', href: '/stock-transfers' },
];

interface StockTransferItem {
    id: number;
    transfer_number: string;
    type: 'transfer' | 'stock_in' | 'stock_out' | 'adjustment';
    date: string;
    from_store?: { name: string };
    to_store?: { name: string };
    lines?: any[];
    notes?: string;
}

const props = defineProps<{
    transfers: {
        data: StockTransferItem[];
        links: any[];
    };
    currentType?: string;
}>();

const setFilter = (type: string) => {
    router.get('/stock-transfers', { type: type || undefined }, { preserveState: true, replace: true });
};

const deleteTransfer = (id: number) => {
    if (confirm('هل أنت متأكد من إلغاء حركة المخزون هذه؟ سيتم استرجاع كميات المخزون السابقة.')) {
        router.delete(route('stock-transfers.destroy', id));
    }
};
</script>

<template>
    <Head title="مناقلات وحركات المخزون (Stock Transfers)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <ArrowLeftRight class="w-6 h-6 text-primary" />
                        مناقلات وحركات المستودعات (Stock Movements)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        مناقلة البضائع بين المستودعات، سندات الإدخال والإخراج المباشر والتسويات.
                    </p>
                </div>
                <Button as-child class="gap-2">
                    <Link :href="route('stock-transfers.create')">
                        <Plus class="w-4 h-4" />
                        <span>حركة مخزون جديدة</span>
                    </Link>
                </Button>
            </div>

            <!-- Filter tabs -->
            <div class="flex gap-2 border-b border-border pb-3">
                <Button size="sm" :variant="!currentType ? 'default' : 'outline'" @click="setFilter('')">
                    الكل
                </Button>
                <Button size="sm" :variant="currentType === 'transfer' ? 'default' : 'outline'" @click="setFilter('transfer')">
                    مناقلة بين مستودعين
                </Button>
                <Button size="sm" :variant="currentType === 'stock_in' ? 'default' : 'outline'" @click="setFilter('stock_in')">
                    إدخال بضاعة
                </Button>
                <Button size="sm" :variant="currentType === 'stock_out' ? 'default' : 'outline'" @click="setFilter('stock_out')">
                    إخراج بضاعة / تالف
                </Button>
                <Button size="sm" :variant="currentType === 'adjustment' ? 'default' : 'outline'" @click="setFilter('adjustment')">
                    تسوية جردية
                </Button>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">رقم الحركة</th>
                                    <th class="px-6 py-3 font-semibold">النوع</th>
                                    <th class="px-6 py-3 font-semibold">التاريخ</th>
                                    <th class="px-6 py-3 font-semibold">من مستودع</th>
                                    <th class="px-6 py-3 font-semibold">إلى مستودع</th>
                                    <th class="px-6 py-3 font-semibold">عدد الأصناف</th>
                                    <th class="px-6 py-3 font-semibold text-left">إجراءات</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="t in transfers.data" :key="t.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold">{{ t.transfer_number }}</td>
                                    <td class="px-6 py-4">
                                        <Badge variant="outline">
                                            {{ t.type === 'transfer' ? 'مناقلة' : (t.type === 'stock_in' ? 'إدخال' : (t.type === 'stock_out' ? 'إخراج' : 'تسوية')) }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ t.date }}</td>
                                    <td class="px-6 py-4 font-medium">{{ t.from_store?.name || '—' }}</td>
                                    <td class="px-6 py-4 font-medium">{{ t.to_store?.name || '—' }}</td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ t.lines?.length || 0 }} أصناف</td>
                                    <td class="px-6 py-4 text-left">
                                        <div class="flex items-center justify-end gap-2">
                                            <Button size="sm" variant="ghost" as-child>
                                                <Link :href="route('stock-transfers.show', t.id)">
                                                    <Eye class="w-4 h-4" />
                                                </Link>
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10" @click="deleteTransfer(t.id)">
                                                <Trash2 class="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="transfers.data.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد حركات مخزون مسجلة.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <Pagination :links="transfers.links" />
        </div>
    </AppLayout>
</template>
