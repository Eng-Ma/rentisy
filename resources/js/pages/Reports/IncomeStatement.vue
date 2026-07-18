<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/vue3';
import ReportFilterBar from './Components/ReportFilterBar.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير المالية', href: '/reports' },
    { title: 'قائمة الدخل', href: '/reports/income-statement' },
];

defineProps<{
    revenueData: any[];
    expenseData: any[];
    totalRevenue: number;
    totalExpense: number;
    netIncome: number;
    filters?: any;
}>();

const applyFilters = (newFilters: any) => {
    router.get('/reports/income-statement', newFilters, { preserveState: true, preserveScroll: true });
};

const clearFilters = () => {
    router.get('/reports/income-statement', {}, { preserveState: true, preserveScroll: true });
};
</script>

<template>
    <Head title="قائمة الدخل" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-6" dir="rtl">
            <div class="flex justify-between items-center mb-4 border-b border-gray-200 dark:border-gray-700 pb-4">
                <div>
                    <h1 class="text-3xl font-bold text-gray-900 dark:text-white">قائمة الدخل (الأرباح والخسائر)</h1>
                    <p class="text-gray-500 dark:text-gray-400 mt-1">توضح الأداء المالي للمنشأة عن طريق مقارنة الإيرادات بالمصروفات.</p>
                </div>
                <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded shadow flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" /></svg>
                    طباعة القائمة
                </button>
            </div>

            <ReportFilterBar 
                :filters="filters" 
                @filter="applyFilters" 
                @clear="clearFilters" 
            />

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <!-- Revenues Section -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md border-t-4 border-green-500 overflow-hidden">
                    <div class="bg-green-50 dark:bg-gray-900 p-4 border-b border-green-100 dark:border-gray-700">
                        <h2 class="text-xl font-bold text-green-800 dark:text-green-400">الإيرادات (Revenues)</h2>
                    </div>
                    <div class="p-4">
                        <table class="min-w-full">
                            <tbody>
                                <tr v-for="(rev, idx) in revenueData" :key="idx" class="border-b border-gray-100 dark:border-gray-700 last:border-0">
                                    <td class="py-3 text-gray-800 dark:text-gray-200">{{ rev.name }}</td>
                                    <td class="py-3 text-left font-bold text-gray-900 dark:text-white">{{ Number(rev.balance).toFixed(2) }}</td>
                                </tr>
                                <tr v-if="revenueData.length === 0">
                                    <td colspan="2" class="py-4 text-center text-gray-500">لا توجد إيرادات مسجلة.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="bg-gray-50 dark:bg-gray-900 p-4 border-t border-gray-200 dark:border-gray-700 flex justify-between items-center">
                        <span class="font-bold text-gray-700 dark:text-gray-300">إجمالي الإيرادات:</span>
                        <span class="text-xl font-bold text-green-600 dark:text-green-400">{{ Number(totalRevenue).toFixed(2) }}</span>
                    </div>
                </div>

                <!-- Expenses Section -->
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md border-t-4 border-red-500 overflow-hidden">
                    <div class="bg-red-50 dark:bg-gray-900 p-4 border-b border-red-100 dark:border-gray-700">
                        <h2 class="text-xl font-bold text-red-800 dark:text-red-400">المصروفات والتكاليف (Expenses)</h2>
                    </div>
                    <div class="p-4">
                        <table class="min-w-full">
                            <tbody>
                                <tr v-for="(exp, idx) in expenseData" :key="idx" class="border-b border-gray-100 dark:border-gray-700 last:border-0">
                                    <td class="py-3 text-gray-800 dark:text-gray-200">{{ exp.name }}</td>
                                    <td class="py-3 text-left font-bold text-gray-900 dark:text-white">{{ Number(exp.balance).toFixed(2) }}</td>
                                </tr>
                                <tr v-if="expenseData.length === 0">
                                    <td colspan="2" class="py-4 text-center text-gray-500">لا توجد مصروفات مسجلة.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="bg-gray-50 dark:bg-gray-900 p-4 border-t border-gray-200 dark:border-gray-700 flex justify-between items-center">
                        <span class="font-bold text-gray-700 dark:text-gray-300">إجمالي المصروفات:</span>
                        <span class="text-xl font-bold text-red-600 dark:text-red-400">{{ Number(totalExpense).toFixed(2) }}</span>
                    </div>
                </div>
            </div>

            <!-- Net Income Result -->
            <div class="mt-4 p-8 rounded-xl shadow-lg border-2" 
                :class="netIncome >= 0 ? 'bg-green-50 border-green-500 dark:bg-green-900/20 dark:border-green-700' : 'bg-red-50 border-red-500 dark:bg-red-900/20 dark:border-red-700'">
                <div class="flex flex-col md:flex-row justify-between items-center gap-4">
                    <div>
                        <h2 class="text-2xl font-bold" :class="netIncome >= 0 ? 'text-green-800 dark:text-green-400' : 'text-red-800 dark:text-red-400'">
                            صافي الدخل ({{ netIncome >= 0 ? 'ربح' : 'خسارة' }})
                        </h2>
                        <p class="text-sm mt-1" :class="netIncome >= 0 ? 'text-green-600 dark:text-green-500' : 'text-red-600 dark:text-red-500'">
                            إجمالي الإيرادات مطروحاً منه إجمالي المصروفات.
                        </p>
                    </div>
                    <div class="text-4xl font-black" :class="netIncome >= 0 ? 'text-green-700 dark:text-green-300' : 'text-red-700 dark:text-red-300'">
                        {{ Math.abs(netIncome).toFixed(2) }}
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
