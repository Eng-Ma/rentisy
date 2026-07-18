<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'جهات التعامل', href: '/parties' },
    { title: 'إضافة جهة جديدة', href: '/parties/create' },
];

defineProps<{
    accounts: any[];
}>();

const form = useForm({
    type: 'customer',
    name: '',
    phone: '',
    address: '',
    account_id: '',
});

const submit = () => {
    form.post('/parties');
};
</script>

<template>
    <Head title="جهة جديدة" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <h1 class="text-2xl font-bold dark:text-white mb-4">بطاقة عميل/مورد جديد</h1>

            <form @submit.prevent="submit" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-6 max-w-2xl">
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">نوع الجهة <span class="text-red-500">*</span></label>
                    <select v-model="form.type" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        <option value="customer">عميل (زبون)</option>
                        <option value="vendor">مورد (شركة)</option>
                    </select>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">الاسم <span class="text-red-500">*</span></label>
                    <input type="text" v-model="form.name" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    <div v-if="form.errors.name" class="text-red-500 text-sm mt-1">{{ form.errors.name }}</div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">رقم الهاتف</label>
                    <input type="text" v-model="form.phone" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">العنوان</label>
                    <input type="text" v-model="form.address" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">الحساب المحاسبي المرتبط</label>
                    <select v-model="form.account_id" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        <option value="">(يتم ربطه تلقائياً بحساب الذمم إذا تُرك فارغاً)</option>
                        <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
                    </select>
                </div>

                <div class="flex justify-end pt-4 border-t border-gray-200 dark:border-gray-700">
                    <button type="submit" :disabled="form.processing" class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-2 px-6 rounded">
                        حفظ
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
