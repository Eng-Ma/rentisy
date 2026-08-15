<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { FileSpreadsheet, Plus, Eye, Trash2, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'عروض الأسعار', href: '/quotations' },
];

interface QuotationItem {
    id: number;
    quotation_number: string;
    party?: { name: string };
    store?: { name: string };
    date: string;
    expiry_date?: string;
    status: 'draft' | 'sent' | 'accepted' | 'converted' | 'rejected';
    total_amount: number;
    lines?: any[];
}

const props = defineProps<{
    quotations: {
        data: QuotationItem[];
        links: any[];
    };
    currentStatus?: string;
}>();

const setFilter = (status: string) => {
    router.get('/quotations', { status: status || undefined }, { preserveState: true, replace: true });
};

const convertToInvoice = (id: number) => {
    if (confirm('هل ترغب بتحويل عرض السعر هذا مباشرة إلى فاتورة مبيعات؟ سيتم خصم الكميات من المستودع وترحيل القيد المحاسبي.')) {
        router.post(route('quotations.convert', id));
    }
};

const deleteQuote = (id: number) => {
    if (confirm('هل أنت متأكد من حذف عرض السعر؟')) {
        router.delete(route('quotations.destroy', id));
    }
};
</script>

<template>
    <Head title="عروض الأسعار (Quotations)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <FileSpreadsheet class="w-6 h-6 text-primary" />
                        عروض الأسعار للعملاء (Price Offers)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        إعداد عروض الأسعار مع فترات الصلاحية وتحويلها إلى فواتير مبيعات بنقرة واحدة.
                    </p>
                </div>
                <Button as-child class="gap-2">
                    <Link :href="route('quotations.create')">
                        <Plus class="w-4 h-4" />
                        <span>عرض سعر جديد</span>
                    </Link>
                </Button>
            </div>

            <!-- Filter tabs -->
            <div class="flex gap-2 border-b border-border pb-3">
                <Button size="sm" :variant="!currentStatus ? 'default' : 'outline'" @click="setFilter('')">
                    الكل
                </Button>
                <Button size="sm" :variant="currentStatus === 'draft' ? 'default' : 'outline'" @click="setFilter('draft')">
                    مسودة
                </Button>
                <Button size="sm" :variant="currentStatus === 'converted' ? 'default' : 'outline'" @click="setFilter('converted')">
                    محول إلى فاتورة
                </Button>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">رقم العرض</th>
                                    <th class="px-6 py-3 font-semibold">العميل</th>
                                    <th class="px-6 py-3 font-semibold">التاريخ</th>
                                    <th class="px-6 py-3 font-semibold">صالح حتى</th>
                                    <th class="px-6 py-3 font-semibold">المبلغ الإجمالي</th>
                                    <th class="px-6 py-3 font-semibold">الحالة</th>
                                    <th class="px-6 py-3 font-semibold text-left">إجراءات</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="q in quotations.data" :key="q.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold text-primary">{{ q.quotation_number }}</td>
                                    <td class="px-6 py-4 font-medium">{{ q.party?.name }}</td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ q.date }}</td>
                                    <td class="px-6 py-4 text-muted-foreground text-xs font-mono">{{ q.expiry_date || 'غير محدد' }}</td>
                                    <td class="px-6 py-4 font-bold font-mono">
                                        {{ Number(q.total_amount).toLocaleString() }}
                                    </td>
                                    <td class="px-6 py-4">
                                        <Badge v-if="q.status === 'converted'" class="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">
                                            محول لفاتورة
                                        </Badge>
                                        <Badge v-else variant="outline">مسودة</Badge>
                                    </td>
                                    <td class="px-6 py-4 text-left">
                                        <div class="flex items-center justify-end gap-2">
                                            <Button v-if="q.status !== 'converted'" size="sm" variant="outline" class="text-emerald-600 hover:text-emerald-700 text-xs h-8" @click="convertToInvoice(q.id)">
                                                تحويل لفاتورة
                                            </Button>
                                            <Button size="sm" variant="ghost" as-child>
                                                <Link :href="route('quotations.show', q.id)">
                                                    <Eye class="w-4 h-4" />
                                                </Link>
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10" @click="deleteQuote(q.id)">
                                                <Trash2 class="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="quotations.data.length === 0">
                                    <td colspan="7" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد عروض أسعار مسجلة.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <Pagination :links="quotations.links" />
        </div>
    </AppLayout>
</template>
