<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import ReportFilterBar from './Components/ReportFilterBar.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير المالية', href: '/reports' },
    { title: 'كشف حساب', href: '/reports/account-statement' },
];

const props = defineProps<{
    accounts: any[];
    statement: any[];
    account: any;
    totalDebit: number;
    totalCredit: number;
    finalBalance: number;
    filters: any;
}>();

const accountId = ref(props.filters.account_id || '');

const applyFilters = (newFilters: any) => {
    if (!accountId.value) {
        alert('الرجاء اختيار الحساب أولاً');
        return;
    }
    router.get('/reports/account-statement', { ...newFilters, account_id: accountId.value }, { preserveState: true, preserveScroll: true });
};

const clearFilters = () => {
    accountId.value = '';
    router.get('/reports/account-statement', {}, { preserveState: true, preserveScroll: true });
};
</script>

<template>
    <Head title="كشف حساب" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <h1 class="text-2xl font-bold dark:text-white mb-4">كشف حساب تفصيلي</h1>

            <!-- Filters -->
            <ReportFilterBar 
                :filters="filters" 
                @filter="applyFilters" 
                @clear="clearFilters"
            >
                <template #custom-filters>
                    <div class="w-full lg:flex-1 min-w-[250px]">
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">اختر الحساب <span class="text-red-500">*</span></label>
                        <select v-model="accountId" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50 text-sm">
                            <option value="" disabled>-- اختر الحساب --</option>
                            <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
                        </select>
                    </div>
                </template>
            </ReportFilterBar>

            <!-- Report Results -->
            <div v-if="account" class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                <div class="p-4 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 flex justify-between items-center">
                    <div>
                        <h2 class="text-xl font-bold text-gray-900 dark:text-white">كشف حساب: {{ account.name }}</h2>
                        <p class="text-sm text-gray-500 dark:text-gray-400">رقم الحساب: {{ account.code }}</p>
                    </div>
                    <div class="text-left bg-white dark:bg-gray-800 p-3 rounded shadow-sm border border-gray-200 dark:border-gray-700">
                        <div class="text-sm text-gray-500 dark:text-gray-400">الرصيد النهائي:</div>
                        <div class="text-2xl font-bold" :class="finalBalance >= 0 ? 'text-green-600' : 'text-red-600'">
                            {{ Math.abs(finalBalance).toFixed(2) }} <span class="text-sm font-normal text-gray-500">{{ finalBalance >= 0 ? account.balance_type === 'debit' ? 'مدين' : 'دائن' : account.balance_type === 'debit' ? 'دائن' : 'مدين' }}</span>
                        </div>
                    </div>
                </div>

                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-100 dark:bg-gray-900">
                        <tr>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">التاريخ</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم القيد/المرجع</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">البيان</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase bg-blue-50 dark:bg-gray-800">مدين (له)</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase bg-red-50 dark:bg-gray-800">دائن (عليه)</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">الرصيد التراكمي</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="line in statement" :key="line.id" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ line.date }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ line.reference || '-' }}</td>
                            <td class="px-6 py-4 text-sm text-gray-900 dark:text-gray-100">{{ line.description }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-blue-600 bg-blue-50 dark:bg-gray-800 dark:text-blue-400">{{ Number(line.debit) > 0 ? line.debit : '' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-red-600 bg-red-50 dark:bg-gray-800 dark:text-red-400">{{ Number(line.credit) > 0 ? line.credit : '' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold" :class="line.balance >= 0 ? 'text-green-600' : 'text-red-600'">{{ Math.abs(line.balance).toFixed(2) }}</td>
                        </tr>
                        <tr v-if="statement.length === 0">
                            <td colspan="6" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا توجد حركات لهذا الحساب في الفترة المحددة.</td>
                        </tr>
                    </tbody>
                    <tfoot class="bg-gray-50 dark:bg-gray-900 border-t-2 border-gray-300 dark:border-gray-600">
                        <tr>
                            <td colspan="3" class="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900 dark:text-gray-100 text-left">الإجماليات:</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-blue-600 dark:text-blue-400">{{ totalDebit.toFixed(2) }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-red-600 dark:text-red-400">{{ totalCredit.toFixed(2) }}</td>
                            <td></td>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <div v-else-if="filters.account_id" class="mt-6 text-center text-gray-500">
                جاري التحميل...
            </div>
            
            <div v-else class="mt-6 text-center text-gray-500 dark:text-gray-400 bg-white dark:bg-gray-800 p-8 rounded-lg shadow border border-dashed border-gray-300 dark:border-gray-600">
                يرجى تحديد حساب من القائمة أعلاه لعرض كشف الحساب الخاص به.
            </div>

        </div>
    </AppLayout>
</template>
