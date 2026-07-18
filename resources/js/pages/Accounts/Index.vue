<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import { watchDebounced } from '@vueuse/core';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'شجرة الحسابات',
        href: '/accounts',
    },
];

const props = defineProps<{
    accounts: any;
    filters?: any;
}>();

const search = ref(props.filters?.search || '');
const type = ref(props.filters?.type || '');

watchDebounced(
    [search, type],
    ([newSearch, newType]) => {
        router.get('/accounts', { search: newSearch, type: newType }, {
            preserveState: true,
            preserveScroll: true,
            replace: true
        });
    },
    { debounce: 300 }
);
</script>

<template>
    <Head title="شجرة الحسابات" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-4 rounded-xl p-4" dir="rtl">
            <div class="flex justify-between items-center mb-4">
                <h1 class="text-2xl font-bold dark:text-white">شجرة الحسابات (Chart of Accounts)</h1>
                <Link href="/accounts/create" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                    إضافة حساب جديد
                </Link>
            </div>

            <div class="flex gap-4 mb-4">
                <input
                    v-model="search"
                    type="text"
                    placeholder="ابحث بالاسم أو الرقم..."
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/3"
                >
                <select
                    v-model="type"
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/4"
                >
                    <option value="">جميع الأنواع</option>
                    <option value="asset">أصل</option>
                    <option value="liability">التزام</option>
                    <option value="equity">حقوق ملكية</option>
                    <option value="revenue">إيراد</option>
                    <option value="expense">مصروف</option>
                </select>
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-900">
                        <tr>
                            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">رقم الحساب</th>
                            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">اسم الحساب</th>
                            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">النوع</th>
                            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">طبيعة الحساب</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="account in accounts.data" :key="account.id">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ account.code }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                                <span :class="{'mr-4': account.parent_id}">{{ account.name }}</span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ account.type }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ account.balance_type }}</td>
                        </tr>
                        <tr v-if="accounts.data.length === 0">
                            <td colspan="4" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا يوجد حسابات حالياً.</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <Pagination :links="accounts.links" />
        </div>
    </AppLayout>
</template>
