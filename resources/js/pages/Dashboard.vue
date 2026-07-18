<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';
import { Package, Users, FileText, Banknote, TrendingUp, BarChart3, CreditCard, ShoppingCart, Receipt } from 'lucide-vue-next';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'الرئيسية',
        href: '/dashboard',
    },
];

defineProps<{
    name?: string;
    stats?: {
        totalSales: string;
        totalPurchases: string;
        netProfit: string;
        totalParties: number;
        totalItems: number;
        totalInvoicesCount: number;
    };
}>();
</script>

<template>
    <Head title="الرئيسية" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-8 p-8" dir="rtl">
            
            <!-- Welcome Header -->
            <div class="flex flex-col md:flex-row justify-between items-center bg-white/40 dark:bg-gray-800/40 backdrop-blur-lg p-6 rounded-3xl border border-white/50 dark:border-gray-700/50 shadow-xl">
                <div>
                    <h1 class="text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-l from-blue-600 to-indigo-600 dark:from-blue-400 dark:to-indigo-400 mb-2">
                        مرحباً بك في نظام المحاسبة المتقدم
                    </h1>
                    <p class="text-gray-600 dark:text-gray-300 text-lg">كل ما تحتاجه لإدارة أعمالك بفعالية واحترافية.</p>
                    <p class="text-indigo-600 dark:text-indigo-400 text-sm mt-3 flex items-center gap-2 font-bold bg-indigo-50 dark:bg-indigo-900/30 w-fit px-4 py-2 rounded-full border border-indigo-100 dark:border-indigo-800">
                        <span>💡 جرب الضغط على</span>
                        <kbd class="bg-white dark:bg-gray-800 px-2 py-1 rounded shadow-sm border border-indigo-200 dark:border-indigo-700 font-sans text-xs">Cmd + K</kbd>
                        <span>للبحث والانتقال السريع لأي مكان في النظام!</span>
                    </p>
                </div>
                <div class="mt-4 md:mt-0">
                    <Link href="/invoices/create" class="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-3 px-8 rounded-full shadow-lg hover:shadow-indigo-500/30 transition-all duration-300 transform hover:-translate-y-1 flex items-center gap-2">
                        <FileText class="w-5 h-5" />
                        إنشاء فاتورة جديدة
                    </Link>
                </div>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <!-- Stat Card 1 -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-blue-100 dark:bg-blue-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">إجمالي المبيعات</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">{{ stats?.totalSales || '0.00' }}</h3>
                        </div>
                        <div class="p-3 bg-blue-50 dark:bg-blue-900/30 rounded-xl text-blue-600 dark:text-blue-400">
                            <Banknote class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 z-10">
                        <Link href="/invoices?type=sale" class="hover:text-blue-600 dark:hover:text-blue-400 hover:underline">عرض فواتير المبيعات</Link>
                    </div>
                </div>

                <!-- Stat Card 2 -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-emerald-100 dark:bg-emerald-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">صافي الأرباح</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">{{ stats?.netProfit || '0.00' }}</h3>
                        </div>
                        <div class="p-3 bg-emerald-50 dark:bg-emerald-900/30 rounded-xl text-emerald-600 dark:text-emerald-400">
                            <BarChart3 class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 z-10">
                        <Link href="/reports/income-statement" class="hover:text-emerald-600 dark:hover:text-emerald-400 hover:underline">عرض قائمة الدخل</Link>
                    </div>
                </div>

                <!-- Stat Card 3 (Purchases) -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-rose-100 dark:bg-rose-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">إجمالي المشتريات</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-rose-600 dark:group-hover:text-rose-400 transition-colors">{{ stats?.totalPurchases || '0.00' }}</h3>
                        </div>
                        <div class="p-3 bg-rose-50 dark:bg-rose-900/30 rounded-xl text-rose-600 dark:text-rose-400">
                            <ShoppingCart class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 dark:text-gray-400 z-10">
                        <Link href="/invoices?type=purchase" class="hover:text-rose-600 dark:hover:text-rose-400 hover:underline">عرض فواتير المشتريات</Link>
                    </div>
                </div>

                <!-- Stat Card 4 -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-purple-100 dark:bg-purple-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">العملاء والموردين</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">{{ stats?.totalParties || 0 }}</h3>
                        </div>
                        <div class="p-3 bg-purple-50 dark:bg-purple-900/30 rounded-xl text-purple-600 dark:text-purple-400">
                            <Users class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 dark:text-gray-400 z-10">
                        <Link href="/parties" class="hover:text-purple-600 dark:hover:text-purple-400 hover:underline">عرض جميع الجهات</Link>
                    </div>
                </div>

                <!-- Stat Card 5 -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-amber-100 dark:bg-amber-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">الأصناف بالمخزن</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors">{{ stats?.totalItems || 0 }}</h3>
                        </div>
                        <div class="p-3 bg-amber-50 dark:bg-amber-900/30 rounded-xl text-amber-600 dark:text-amber-400">
                            <Package class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 dark:text-gray-400 z-10">
                        <Link href="/items" class="hover:text-amber-600 dark:hover:text-amber-400 hover:underline">إدارة الأصناف</Link>
                    </div>
                </div>

                <!-- Stat Card 6 (Invoices Count) -->
                <div class="glass-card p-6 flex flex-col justify-between group cursor-pointer relative overflow-hidden">
                    <div class="absolute -right-4 -top-4 w-24 h-24 bg-indigo-100 dark:bg-indigo-900/50 rounded-full blur-2xl opacity-50 group-hover:opacity-100 transition-opacity"></div>
                    <div class="flex justify-between items-start z-10">
                        <div>
                            <p class="text-gray-500 dark:text-gray-400 text-sm font-semibold mb-1">عدد الفواتير</p>
                            <h3 class="text-3xl font-black text-gray-900 dark:text-white group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">{{ stats?.totalInvoicesCount || 0 }}</h3>
                        </div>
                        <div class="p-3 bg-indigo-50 dark:bg-indigo-900/30 rounded-xl text-indigo-600 dark:text-indigo-400">
                            <Receipt class="w-6 h-6" />
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-sm text-gray-500 dark:text-gray-400 z-10">
                        <Link href="/invoices" class="hover:text-indigo-600 dark:hover:text-indigo-400 hover:underline">إدارة الفواتير</Link>
                    </div>
                </div>
            </div>

            <!-- Quick Access Menu -->
            <div class="mt-4">
                <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">الوصول السريع</h2>
                <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
                    <Link href="/reports/income-statement" class="glass-card p-4 flex flex-col items-center justify-center text-center group hover:bg-white/90 dark:hover:bg-gray-800/90">
                        <div class="w-12 h-12 bg-green-100 dark:bg-green-900/40 text-green-600 dark:text-green-400 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                            <BarChart3 class="w-6 h-6" />
                        </div>
                        <span class="font-bold text-gray-800 dark:text-gray-200">قائمة الدخل</span>
                    </Link>
                    
                    <Link href="/reports/trial-balance" class="glass-card p-4 flex flex-col items-center justify-center text-center group hover:bg-white/90 dark:hover:bg-gray-800/90">
                        <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                            <TrendingUp class="w-6 h-6" />
                        </div>
                        <span class="font-bold text-gray-800 dark:text-gray-200">ميزان المراجعة</span>
                    </Link>

                    <Link href="/reports/account-statement" class="glass-card p-4 flex flex-col items-center justify-center text-center group hover:bg-white/90 dark:hover:bg-gray-800/90">
                        <div class="w-12 h-12 bg-purple-100 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                            <FileText class="w-6 h-6" />
                        </div>
                        <span class="font-bold text-gray-800 dark:text-gray-200">كشف حساب</span>
                    </Link>
                    
                    <Link href="/journal-entries" class="glass-card p-4 flex flex-col items-center justify-center text-center group hover:bg-white/90 dark:hover:bg-gray-800/90">
                        <div class="w-12 h-12 bg-amber-100 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
                            <CreditCard class="w-6 h-6" />
                        </div>
                        <span class="font-bold text-gray-800 dark:text-gray-200">القيود اليومية</span>
                    </Link>
                </div>
            </div>

        </div>
    </AppLayout>
</template>
