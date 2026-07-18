<script setup lang="ts">
import { ref, computed } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'القيود اليومية', href: '/journal-entries' },
    { title: 'قيد جديد', href: '/journal-entries/create' },
];

const props = defineProps<{
    currencies: any[];
    accounts: any[];
}>();

const form = useForm({
    date: new Date().toISOString().split('T')[0],
    reference: '',
    description: '',
    currency_id: props.currencies.length > 0 ? props.currencies[0].id : '',
    exchange_rate: 1.0,
    lines: [
        { account_id: '', description: '', debit: 0, credit: 0 },
        { account_id: '', description: '', debit: 0, credit: 0 },
    ]
});

const totalDebit = computed(() => {
    return form.lines.reduce((sum, line) => sum + Number(line.debit || 0), 0);
});

const totalCredit = computed(() => {
    return form.lines.reduce((sum, line) => sum + Number(line.credit || 0), 0);
});

const isBalanced = computed(() => {
    return totalDebit.value === totalCredit.value && totalDebit.value > 0;
});

const addLine = () => {
    form.lines.push({ account_id: '', description: '', debit: 0, credit: 0 });
};

const removeLine = (index: number) => {
    if (form.lines.length > 2) {
        form.lines.splice(index, 1);
    }
};

const submit = () => {
    form.post('/journal-entries');
};
</script>

<template>
    <Head title="قيد يومية جديد" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-4 p-4" dir="rtl">
            <h1 class="text-2xl font-bold dark:text-white mb-4">إنشاء قيد يومية جديد</h1>

            <form @submit.prevent="submit" class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">التاريخ</label>
                        <input type="date" v-model="form.date" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                        <div v-if="form.errors.date" class="text-red-500 text-sm mt-1">{{ form.errors.date }}</div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">المرجع</label>
                        <input type="text" v-model="form.reference" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">العملة</label>
                        <select v-model="form.currency_id" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            <option v-for="c in currencies" :key="c.id" :value="c.id">{{ c.name }} ({{ c.code }})</option>
                        </select>
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">البيان (الوصف العام)</label>
                    <input type="text" v-model="form.description" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                    <div v-if="form.errors.description" class="text-red-500 text-sm mt-1">{{ form.errors.description }}</div>
                </div>

                <hr class="border-gray-200 dark:border-gray-700">

                <div>
                    <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">تفاصيل القيد</h3>
                    <div v-if="form.errors.lines" class="text-red-500 text-sm mb-4 p-2 bg-red-100 rounded">{{ form.errors.lines }}</div>
                    
                    <div class="space-y-2">
                        <div v-for="(line, index) in form.lines" :key="index" class="flex items-center gap-2">
                            <div class="flex-1">
                                <select v-model="line.account_id" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                                    <option value="" disabled>اختر الحساب</option>
                                    <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
                                </select>
                            </div>
                            <div class="flex-1">
                                <input type="text" v-model="line.description" placeholder="البيان" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            </div>
                            <div class="w-32">
                                <input type="number" step="0.01" v-model="line.debit" placeholder="مدين" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            </div>
                            <div class="w-32">
                                <input type="number" step="0.01" v-model="line.credit" placeholder="دائن" class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                            </div>
                            <button type="button" @click="removeLine(index)" class="text-red-500 hover:text-red-700 p-2" :disabled="form.lines.length <= 2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" /></svg>
                            </button>
                        </div>
                    </div>
                    
                    <button type="button" @click="addLine" class="mt-4 text-blue-600 hover:text-blue-800 text-sm font-medium">+ إضافة سطر جديد</button>
                </div>

                <div class="flex justify-between items-center bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
                    <div class="flex gap-8">
                        <div class="text-lg">
                            <span class="text-gray-500 dark:text-gray-400">إجمالي المدين: </span>
                            <span class="font-bold text-gray-900 dark:text-white">{{ totalDebit.toFixed(2) }}</span>
                        </div>
                        <div class="text-lg">
                            <span class="text-gray-500 dark:text-gray-400">إجمالي الدائن: </span>
                            <span class="font-bold text-gray-900 dark:text-white">{{ totalCredit.toFixed(2) }}</span>
                        </div>
                    </div>
                    <div v-if="!isBalanced && (totalDebit > 0 || totalCredit > 0)" class="text-red-500 font-bold">
                        القيد غير متوازن! الفرق: {{ Math.abs(totalDebit - totalCredit).toFixed(2) }}
                    </div>
                    <div v-else-if="isBalanced" class="text-green-500 font-bold">
                        القيد متوازن ✓
                    </div>
                </div>

                <div class="flex justify-end pt-4">
                    <button type="submit" :disabled="form.processing || !isBalanced" class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-bold py-2 px-6 rounded">
                        حفظ القيد
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
