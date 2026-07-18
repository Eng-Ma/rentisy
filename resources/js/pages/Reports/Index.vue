<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير المالية', href: '/reports' },
];
</script>

<template>
    <Head title="التقارير" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-6" dir="rtl">
            <h1 class="text-3xl font-bold dark:text-white">التقارير المالية والمحاسبية</h1>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <!-- Account Statement -->
                <Link href="/reports/account-statement" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow hover:shadow-lg transition-shadow border-t-4 border-blue-500">
                    <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">كشف حساب</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm">عرض الحركات المالية (مدين ودائن) والرصيد التراكمي لحساب معين خلال فترة محددة.</p>
                </Link>

                <!-- Trial Balance -->
                <Link href="/reports/trial-balance" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow hover:shadow-lg transition-shadow border-t-4 border-purple-500">
                    <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">ميزان المراجعة</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm">ملخص بأرصدة جميع الحسابات المفتوحة (مدين ودائن) للتأكد من توازن القيود المحاسبية.</p>
                </Link>

                <!-- Income Statement -->
                <Link href="/reports/income-statement" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow hover:shadow-lg transition-shadow border-t-4 border-green-500">
                    <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">قائمة الدخل (الأرباح والخسائر)</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm">بيان يوضح الإيرادات والمصروفات وصافي الدخل (الربح أو الخسارة) للمنشأة.</p>
                </Link>

                <!-- Party Report -->
                <Link href="/reports/party-statement" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow hover:shadow-lg transition-shadow border-t-4 border-amber-500">
                    <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">تقرير الزبائن والموردين</h2>
                    <p class="text-gray-500 dark:text-gray-400 text-sm">عرض كشف حساب الديون والمشتريات وسجل الفواتير لزبون أو مورد محدد خلال فترة زمنية.</p>
                </Link>
            </div>
        </div>
    </AppLayout>
</template>
