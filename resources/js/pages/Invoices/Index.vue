<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import { watchDebounced } from '@vueuse/core';
import Pagination from '@/Components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'المبيعات والمشتريات', href: '#' },
    { title: 'فواتير المبيعات والمشتريات', href: '/invoices' },
];

const props = defineProps<{
    invoices: any;
    filters?: any;
}>();

const getInvoiceTypeName = (type: string) => {
    const types: Record<string, string> = {
        'purchase': 'مشتريات',
        'sale': 'مبيعات',
        'purchase_return': 'مردود مشتريات',
        'sale_return': 'مردود مبيعات'
    };
    return types[type] || type;
};

const search = ref(props.filters?.search || '');
const type = ref(props.filters?.type || '');
const date = ref(props.filters?.date || '');

watchDebounced(
    [search, type, date],
    ([newSearch, newType, newDate]) => {
        router.get('/invoices', { search: newSearch, type: newType, date: newDate }, {
            preserveState: true,
            preserveScroll: true,
            replace: true
        });
    },
    { debounce: 300 }
);
</script>

<template>
    <Head title="الفواتير" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <div class="flex justify-between items-center mb-4">
                <h1 class="text-2xl font-bold dark:text-white">الفواتير (المبيعات والمشتريات)</h1>
                <Link href="/invoices/create" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                    + فاتورة جديدة
                </Link>
            </div>

            <div class="flex gap-4 mb-4">
                <input
                    v-model="search"
                    type="text"
                    placeholder="ابحث برقم الفاتورة، الملاحظات، أو اسم الجهة..."
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/3"
                >
                <select
                    v-model="type"
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/4"
                >
                    <option value="">جميع الأنواع</option>
                    <option value="sale">مبيعات</option>
                    <option value="purchase">مشتريات</option>
                    <option value="sale_return">مردود مبيعات</option>
                    <option value="purchase_return">مردود مشتريات</option>
                </select>
                <input
                    v-model="date"
                    type="date"
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/4"
                >
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-900">
                        <tr>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم الفاتورة</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">التاريخ</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">نوع الفاتورة</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">الجهة (عميل/مورد)</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">المخزن</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">المبلغ الإجمالي</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم القيد</th>
                            <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">إجراءات</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="invoice in invoices.data" :key="invoice.id" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100 font-bold">INV-{{ invoice.id }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ invoice.date }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                                <span :class="{'text-green-600': invoice.type === 'sale', 'text-blue-600': invoice.type === 'purchase', 'text-red-600': invoice.type.includes('return')}">
                                    {{ getInvoiceTypeName(invoice.type) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ invoice.party?.name }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ invoice.store?.name }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900 dark:text-gray-100">{{ invoice.total_amount }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-blue-500 underline cursor-pointer">JE-{{ invoice.journal_entry_id || '-' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                                <Link :href="`/invoices/${invoice.id}`" class="inline-flex items-center gap-1 bg-indigo-100 dark:bg-indigo-900/50 text-indigo-700 dark:text-indigo-400 px-3 py-1.5 rounded hover:bg-indigo-200 dark:hover:bg-indigo-800 transition-colors font-bold text-xs">
                                    عرض / طباعة
                                </Link>
                            </td>
                        </tr>
                        <tr v-if="invoices.data.length === 0">
                            <td colspan="8" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا توجد فواتير حالياً.</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <Pagination :links="invoices.links" />
        </div>
    </AppLayout>
</template>
