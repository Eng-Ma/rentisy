<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import { watchDebounced } from '@vueuse/core';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'جهات التعامل', href: '/parties' },
];

const props = defineProps<{
    parties: any;
    filters?: any;
}>();

const search = ref(props.filters?.search || '');
const type = ref(props.filters?.type || '');

watchDebounced(
    [search, type],
    ([newSearch, newType]) => {
        router.get('/parties', { search: newSearch, type: newType }, {
            preserveState: true,
            preserveScroll: true,
            replace: true
        });
    },
    { debounce: 300 }
);
</script>

<template>
    <Head title="جهات التعامل" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <div class="flex justify-between items-center mb-4">
                <h1 class="text-2xl font-bold dark:text-white">جهات التعامل (العملاء والموردين)</h1>
                <Link href="/parties/create" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                    + جهة جديدة
                </Link>
            </div>

            <div class="flex gap-4 mb-4">
                <input
                    v-model="search"
                    type="text"
                    placeholder="ابحث بالاسم، الهاتف، أو العنوان..."
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/3"
                >
                <select
                    v-model="type"
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/4"
                >
                    <option value="">جميع الأنواع</option>
                    <option value="customer">عميل</option>
                    <option value="vendor">مورد</option>
                </select>
            </div>

            <div class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead class="bg-gray-50 dark:bg-gray-900">
                        <tr>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">النوع</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">الاسم</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم الهاتف</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">الحساب المرتبط</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="party in parties.data" :key="party.id" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100 font-bold">
                                {{ party.type === 'customer' ? 'عميل' : 'مورد' }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ party.name }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ party.phone || '-' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ party.account?.name || 'غير محدد' }}</td>
                        </tr>
                        <tr v-if="parties.data.length === 0">
                            <td colspan="4" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا توجد جهات مسجلة.</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <Pagination :links="parties.links" />
        </div>
    </AppLayout>
</template>
