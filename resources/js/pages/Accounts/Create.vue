<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';
import { BookKey, Save, AlertCircle } from 'lucide-vue-next';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'شجرة الحسابات', href: '/accounts' },
    { title: 'إضافة حساب جديد', href: '/accounts/create' },
];

defineProps<{
    parentAccounts: any[];
}>();

const form = useForm({
    parent_id: '',
    code: '',
    name: '',
    type: 'asset',
    balance_type: 'debit',
    is_active: true,
    description: '',
});

const submit = () => {
    form.post('/accounts');
};
</script>

<template>
    <Head title="حساب جديد" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-6 lg:p-10" dir="rtl">
            <!-- Header -->
            <div class="flex flex-col md:flex-row justify-between items-center bg-white/40 dark:bg-gray-800/40 backdrop-blur-lg p-6 rounded-3xl border border-white/50 dark:border-gray-700/50 shadow-xl">
                <div class="flex items-center gap-4">
                    <div class="p-4 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl text-white shadow-lg shadow-indigo-500/30">
                        <BookKey class="w-8 h-8" />
                    </div>
                    <div>
                        <h1 class="text-3xl font-extrabold text-gray-900 dark:text-white">إضافة حساب جديد</h1>
                        <p class="text-gray-500 dark:text-gray-400 mt-1">قم بتعريف حساب جديد في شجرة الحسابات المحاسبية.</p>
                    </div>
                </div>
            </div>

            <!-- Form Card -->
            <form @submit.prevent="submit" class="glass-card p-8 lg:p-10 max-w-4xl mx-auto w-full space-y-8 relative overflow-hidden">
                <!-- Decorative background elements -->
                <div class="absolute -left-20 -top-20 w-64 h-64 bg-indigo-100 dark:bg-indigo-900/30 rounded-full blur-3xl opacity-50 pointer-events-none"></div>
                <div class="absolute -right-20 -bottom-20 w-64 h-64 bg-purple-100 dark:bg-purple-900/30 rounded-full blur-3xl opacity-50 pointer-events-none"></div>

                <div class="relative z-10 grid grid-cols-1 md:grid-cols-2 gap-8">
                    
                    <!-- Section: Basic Info -->
                    <div class="col-span-1 md:col-span-2">
                        <h2 class="text-xl font-bold text-indigo-800 dark:text-indigo-400 mb-4 border-b border-indigo-100 dark:border-indigo-900 pb-2 flex items-center gap-2">
                            <span class="w-8 h-8 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center text-sm">1</span>
                            المعلومات الأساسية
                        </h2>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">رمز الحساب (رقم الحساب) <span class="text-red-500">*</span></label>
                        <input type="text" v-model="form.code" required placeholder="مثال: 1101" 
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                        <div v-if="form.errors.code" class="text-red-500 text-sm mt-2 flex items-center gap-1">
                            <AlertCircle class="w-4 h-4"/> {{ form.errors.code }}
                        </div>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">اسم الحساب <span class="text-red-500">*</span></label>
                        <input type="text" v-model="form.name" required placeholder="مثال: البنك الأهلي" 
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                        <div v-if="form.errors.name" class="text-red-500 text-sm mt-2 flex items-center gap-1">
                            <AlertCircle class="w-4 h-4"/> {{ form.errors.name }}
                        </div>
                    </div>

                    <div class="col-span-1 md:col-span-2">
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">الحساب الأب (الحساب الرئيسي)</label>
                        <select v-model="form.parent_id" 
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                            <option value="">-- بدون حساب أب (حساب رئيسي) --</option>
                            <option v-for="a in parentAccounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
                        </select>
                    </div>

                    <!-- Section: Accounting Rules -->
                    <div class="col-span-1 md:col-span-2 mt-4">
                        <h2 class="text-xl font-bold text-purple-800 dark:text-purple-400 mb-4 border-b border-purple-100 dark:border-purple-900 pb-2 flex items-center gap-2">
                            <span class="w-8 h-8 rounded-full bg-purple-100 dark:bg-purple-900/50 flex items-center justify-center text-sm">2</span>
                            القواعد المحاسبية
                        </h2>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">طبيعة الحساب (ميزانية أم قائمة دخل) <span class="text-red-500">*</span></label>
                        <select v-model="form.type" required 
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-purple-500 focus:ring-purple-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                            <option value="asset">أصول (موجودات)</option>
                            <option value="liability">خصوم (مطلوبات)</option>
                            <option value="equity">حقوق الملكية</option>
                            <option value="revenue">إيرادات</option>
                            <option value="expense">مصروفات</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">طبيعة الرصيد الدائمة <span class="text-red-500">*</span></label>
                        <select v-model="form.balance_type" required 
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-purple-500 focus:ring-purple-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                            <option value="debit">مدين (Debit)</option>
                            <option value="credit">دائن (Credit)</option>
                        </select>
                    </div>

                    <!-- Section: Additional Details -->
                    <div class="col-span-1 md:col-span-2 mt-4">
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">وصف الحساب أو ملاحظات</label>
                        <textarea v-model="form.description" rows="3" placeholder="أدخل أي ملاحظات إضافية هنا..."
                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50"></textarea>
                    </div>

                    <div class="col-span-1 md:col-span-2 flex items-center bg-gray-50/50 dark:bg-gray-800/30 p-4 rounded-xl border border-gray-100 dark:border-gray-700 backdrop-blur-sm">
                        <input type="checkbox" id="is_active" v-model="form.is_active" 
                            class="w-6 h-6 rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 transition-all cursor-pointer">
                        <label for="is_active" class="mr-3 block text-base font-bold text-gray-900 dark:text-gray-200 cursor-pointer">الحساب فعال ومتاح للاستخدام</label>
                    </div>
                </div>

                <!-- Footer Actions -->
                <div class="relative z-10 flex justify-end pt-6 border-t border-gray-200/50 dark:border-gray-700/50 mt-8 gap-4">
                    <button type="button" @click="form.reset()" class="px-6 py-3 rounded-xl font-bold text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white transition-colors">
                        مسح الحقول
                    </button>
                    <button type="submit" :disabled="form.processing" 
                        class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 disabled:opacity-50 text-white font-bold py-3 px-8 rounded-xl shadow-lg hover:shadow-indigo-500/40 transition-all transform hover:-translate-y-1 flex items-center gap-2">
                        <Save class="w-5 h-5" />
                        حفظ الحساب
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
