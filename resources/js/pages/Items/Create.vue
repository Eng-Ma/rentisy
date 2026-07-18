<script setup lang="ts">
import { ref } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'بطاقات الأصناف', href: '/items' },
    { title: 'إضافة صنف جديد', href: '/items/create' },
];

defineProps<{
    categories: any[];
}>();

const form = useForm({
    category_id: '',
    barcode: '',
    name: '',
    description: '',
    unit: 'حبة', // Default unit
    purchase_price: 0,
    sales_price: 0,
    is_active: true,
});

const submit = () => {
    form.post('/items');
};
</script>

<template>
    <Head title="صنف جديد" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <h1 class="text-2xl font-bold dark:text-white mb-4">بطاقة صنف جديد</h1>

            <form @submit.prevent="submit" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-6 max-w-4xl">
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <!-- اسم الصنف -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">اسم الصنف <span class="text-red-500">*</span></label>
                        <input type="text" v-model="form.name" required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        <div v-if="form.errors.name" class="text-red-500 text-sm mt-1">{{ form.errors.name }}</div>
                    </div>

                    <!-- الباركود -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">الباركود (Barcode)</label>
                        <input type="text" v-model="form.barcode" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        <div v-if="form.errors.barcode" class="text-red-500 text-sm mt-1">{{ form.errors.barcode }}</div>
                    </div>

                    <!-- التصنيف -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">التصنيف</label>
                        <select v-model="form.category_id" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            <option value="">بدون تصنيف</option>
                            <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                        </select>
                    </div>

                    <!-- الوحدة -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">الوحدة الأساسية <span class="text-red-500">*</span></label>
                        <input type="text" v-model="form.unit" placeholder="حبة، كرتونة، كجم..." required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    </div>

                    <!-- سعر الشراء -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">سعر الشراء المتوقع</label>
                        <input type="number" step="0.01" v-model="form.purchase_price" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    </div>

                    <!-- سعر البيع -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">سعر البيع الافتراضي</label>
                        <input type="number" step="0.01" v-model="form.sales_price" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    </div>
                </div>

                <!-- الوصف -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">وصف الصنف / ملاحظات</label>
                    <textarea v-model="form.description" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"></textarea>
                </div>

                <div class="flex items-center">
                    <input type="checkbox" id="is_active" v-model="form.is_active" class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50">
                    <label for="is_active" class="mr-2 block text-sm text-gray-900 dark:text-gray-300">صنف فعال (نشط)</label>
                </div>

                <div class="flex justify-end pt-4 border-t border-gray-200 dark:border-gray-700">
                    <button type="submit" :disabled="form.processing" class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-2 px-6 rounded">
                        حفظ الصنف
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
