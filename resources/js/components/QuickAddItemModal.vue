<script setup lang="ts">
import { ref } from 'vue';
import { X, Save } from 'lucide-vue-next';
import axios from 'axios';
import { router } from '@inertiajs/vue3';

const props = defineProps<{
    show: boolean;
}>();

const emit = defineEmits(['close', 'saved']);

const form = ref({
    barcode: '',
    name: '',
    unit: 'حبة',
    purchase_price: 0,
    sales_price: 0,
    is_active: true,
});

const errors = ref<Record<string, string>>({});
const processing = ref(false);

const submit = () => {
    processing.value = true;
    errors.value = {};
    
    axios.post('/items', form.value, {
        headers: { 'Accept': 'application/json' }
    })
    .then(response => {
        router.reload({
            only: ['items'],
            onSuccess: () => {
                form.value.name = '';
                form.value.barcode = '';
                emit('saved', response.data);
                emit('close');
                processing.value = false;
            }
        });
    })
    .catch(error => {
        processing.value = false;
        if (error.response?.data?.errors) {
            const errs = error.response.data.errors;
            Object.keys(errs).forEach(key => {
                errors.value[key] = errs[key][0];
            });
        }
    });
};
</script>

<template>
    <div v-if="show" class="fixed inset-0 z-[100] flex items-center justify-center overflow-y-auto overflow-x-hidden bg-black/50 backdrop-blur-sm p-4" dir="rtl">
        <div class="relative w-full max-w-lg bg-white dark:bg-gray-800 rounded-2xl shadow-2xl overflow-hidden transform transition-all">
            <!-- Header -->
            <div class="flex items-center justify-between p-4 border-b border-gray-100 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-900/50">
                <h3 class="text-xl font-bold text-gray-900 dark:text-white">إضافة صنف جديد</h3>
                <button @click="emit('close')" type="button" class="text-gray-400 hover:text-gray-500 focus:outline-none rounded-full p-1 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                    <X class="w-5 h-5" />
                </button>
            </div>

            <!-- Body -->
            <div class="p-6">
                <form @submit.prevent="submit" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="md:col-span-2">
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">اسم الصنف <span class="text-red-500">*</span></label>
                            <input type="text" v-model="form.name" required placeholder="مثال: لابتوب ديل انسبايرون" class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            <div v-if="errors.name" class="text-red-500 text-sm mt-1">{{ errors.name }}</div>
                        </div>

                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">الباركود</label>
                            <input type="text" v-model="form.barcode" class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>

                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">الوحدة <span class="text-red-500">*</span></label>
                            <input type="text" v-model="form.unit" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        </div>

                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">سعر الشراء <span class="text-red-500">*</span></label>
                            <input type="number" step="0.01" min="0" v-model="form.purchase_price" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white text-left" dir="ltr">
                        </div>

                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">سعر البيع <span class="text-red-500">*</span></label>
                            <input type="number" step="0.01" min="0" v-model="form.sales_price" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white text-left" dir="ltr">
                        </div>
                    </div>

                    <!-- Footer -->
                    <div class="flex justify-end gap-3 pt-4 mt-6 border-t border-gray-100 dark:border-gray-700">
                        <button type="button" @click="emit('close')" class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700 transition-colors">
                            إلغاء
                        </button>
                        <button type="submit" :disabled="processing" class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 transition-colors">
                            <Save class="w-4 h-4" />
                            حفظ الصنف
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>
