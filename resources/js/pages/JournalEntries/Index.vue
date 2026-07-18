<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import { watchDebounced } from '@vueuse/core';
import Pagination from '@/Components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'القيود اليومية', href: '/journal-entries' },
];

const props = defineProps<{
    entries: any;
    filters?: any;
}>();

const search = ref(props.filters?.search || '');
const date = ref(props.filters?.date || '');

watchDebounced(
    [search, date],
    ([newSearch, newDate]) => {
        router.get('/journal-entries', { search: newSearch, date: newDate }, {
            preserveState: true,
            preserveScroll: true,
            replace: true
        });
    },
    { debounce: 300 }
);
</script>

<template>
    <Head title="القيود اليومية" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <div class="flex justify-between items-center mb-4">
                <h1 class="text-2xl font-bold dark:text-white">القيود المحاسبية اليومية</h1>
                <Link href="/journal-entries/create" class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                    + قيد جديد
                </Link>
            </div>

            <div class="flex gap-4 mb-4">
                <input
                    v-model="search"
                    type="text"
                    placeholder="ابحث برقم القيد، المرجع، أو البيان..."
                    class="border-gray-300 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 focus:border-indigo-500 dark:focus:border-indigo-600 focus:ring-indigo-500 dark:focus:ring-indigo-600 rounded-md shadow-sm w-1/3"
                >
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
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">رقم القيد</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">التاريخ</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">البيان</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">المرجع</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">العملة</th>
                            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase">الإجمالي (المدين/الدائن)</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                        <tr v-for="entry in entries.data" :key="entry.id" class="hover:bg-gray-50 dark:hover:bg-gray-700">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100 font-bold">JE-{{ entry.id }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ entry.date }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ entry.description }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ entry.reference || '-' }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">{{ entry.currency?.code }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900 dark:text-gray-100">
                                {{ entry.lines.reduce((sum, line) => sum + Number(line.debit), 0).toFixed(2) }}
                            </td>
                        </tr>
                        <tr v-if="entries.data.length === 0">
                            <td colspan="6" class="px-6 py-4 text-center text-gray-500 dark:text-gray-400">لا توجد قيود يومية حالياً.</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <Pagination :links="entries.links" />
        </div>
    </AppLayout>
</template>
