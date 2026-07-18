<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/vue3';
import ReportFilterBar from './Components/ReportFilterBar.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير المالية', href: '/reports' },
    { title: 'ميزان المراجعة', href: '/reports/trial-balance' },
];

defineProps<{
    trialBalance: any[];
    sumDebit: number;
    sumCredit: number;
    filters?: any;
}>();

const applyFilters = (newFilters: any) => {
    router.get('/reports/trial-balance', newFilters, { preserveState: true, preserveScroll: true });
};

const clearFilters = () => {
    router.get('/reports/trial-balance', {}, { preserveState: true, preserveScroll: true });
};
</script>

<template>
    <Head title="ميزان المراجعة" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <div class="flex justify-between items-center mb-4">
                <h1 class="text-2xl font-bold dark:text-white">ميزان المراجعة (بالأرصدة)</h1>
                <button class="bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-white font-bold py-2 px-4 rounded shadow">
                    طباعة
                </button>
            </div>

            <ReportFilterBar 
                :filters="filters" 
                @filter="applyFilters" 
                @clear="clearFilters" 
            />

            <div class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-100 dark:bg-gray-900">
                        <tr>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم الحساب</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">اسم الحساب</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase bg-blue-50 dark:bg-gray-800">أرصدة مدينة</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase bg-red-50 dark:bg-gray-800">أرصدة دائنة</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="row in trialBalance" :key="row.code" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ row.code }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100 font-bold">{{ row.name }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-blue-600 bg-blue-50 dark:bg-gray-800 dark:text-blue-400">
                                {{ row.balance_type === 'debit' ? Number(row.balance).toFixed(2) : '' }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-red-600 bg-red-50 dark:bg-gray-800 dark:text-red-400">
                                {{ row.balance_type === 'credit' ? Number(row.balance).toFixed(2) : '' }}
                            </td>
                        </tr>
                        <tr v-if="trialBalance.length === 0">
                            <td colspan="4" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا توجد أرصدة للحسابات حالياً.</td>
                        </tr>
                    </tbody>
                    <tfoot class="bg-gray-100 dark:bg-gray-900 border-t-4 border-gray-300 dark:border-gray-600">
                        <tr>
                            <td colspan="2" class="px-6 py-4 whitespace-nowrap text-lg font-bold text-gray-900 dark:text-gray-100 text-left">إجمالي ميزان المراجعة:</td>
                            <td class="px-6 py-4 whitespace-nowrap text-lg font-bold text-blue-600 dark:text-blue-400">{{ Number(sumDebit).toFixed(2) }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-lg font-bold text-red-600 dark:text-red-400">{{ Number(sumCredit).toFixed(2) }}</td>
                        </tr>
                    </tfoot>
                </table>
            </div>
            
            <div class="mt-4 flex justify-end">
                <div v-if="Math.abs(sumDebit - sumCredit) < 0.01 && sumDebit > 0" class="bg-green-100 text-green-800 p-3 rounded border border-green-300 font-bold flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
                    الميزان متطابق
                </div>
                <div v-else-if="Math.abs(sumDebit - sumCredit) >= 0.01" class="bg-red-100 text-red-800 p-3 rounded border border-red-300 font-bold flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                    الميزان غير متطابق! يوجد فرق: {{ Math.abs(sumDebit - sumCredit).toFixed(2) }}
                </div>
            </div>
        </div>
    </AppLayout>
</template>
