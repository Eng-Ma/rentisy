<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    ShoppingBag,
    PackageCheck,
    Clock,
    Heart,
    FileText,
    Settings,
    ArrowLeft,
    ShieldCheck,
    Sparkles,
    CreditCard,
    ExternalLink,
    Coins
} from 'lucide-vue-next';

interface Order {
    id: number;
    order_number: string;
    status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
    total_amount: number;
    created_at: string;
    items?: Array<{ id: number; item_name: string; quantity: number }>;
}

interface Props {
    stats: {
        totalOrders: number;
        activeOrders: number;
        totalSpent: number;
        wishlistCount: number;
    };
    recentOrders: Order[];
    customer: {
        id: number;
        name: string;
        email: string;
        phone?: string;
        role?: string;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const getStatusBadgeClass = (status: string) => {
    switch (status) {
        case 'delivered':
            return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300';
        case 'shipped':
            return 'bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-300';
        case 'processing':
            return 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300';
        case 'cancelled':
            return 'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300';
        case 'pending':
        default:
            return 'bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300';
    }
};

const getStatusLabel = (status: string) => {
    switch (status) {
        case 'delivered': return 'تم التوصيل';
        case 'shipped': return 'تم الشحن بالطريق';
        case 'processing': return 'قيد التجهيز';
        case 'cancelled': return 'ملغي';
        case 'pending':
        default: return 'قيد الانتظار والمراجعة';
    }
};
</script>

<template>
    <StoreLayout title="لوحة تحكم حسابي | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Header Greeting -->
            <div class="p-8 rounded-3xl bg-gradient-to-r from-slate-900 via-emerald-950 to-slate-900 text-white shadow-xl flex flex-col md:flex-row items-center justify-between gap-6 mb-10">
                <div class="space-y-2 text-right">
                    <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 text-xs font-bold">
                        <Sparkles class="w-3.5 h-3.5" />
                        <span>بوابة الزبون المتكاملة مع المحاسبة</span>
                    </div>
                    <h1 class="text-2xl sm:text-3xl font-black">أهلاً بك، {{ customer.name }} 👋</h1>
                    <p class="text-xs sm:text-sm text-slate-300">
                        مرحباً بك في لوحة تحكم حسابك. يمكنك هنا متابعة طلباتك، فواتيرك، وربط حساباتك الاجتماعية.
                    </p>
                </div>

                <div class="flex items-center gap-3 shrink-0">
                    <Link
                        :href="route('customer.profile')"
                        class="px-5 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white text-xs font-bold backdrop-blur-sm transition-colors flex items-center gap-1.5"
                    >
                        <Settings class="w-4 h-4" />
                        <span>الملف الشخصي والربط</span>
                    </Link>
                    <Link
                        :href="route('store.shop')"
                        class="px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold shadow-lg shadow-emerald-500/25 transition-all flex items-center gap-1.5"
                    >
                        <ShoppingBag class="w-4 h-4" />
                        <span>تسوق الآن</span>
                    </Link>
                </div>
            </div>

            <!-- KPI Statistics Cards -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
                <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex items-center gap-4">
                    <div class="w-14 h-14 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
                        <PackageCheck class="w-7 h-7" />
                    </div>
                    <div>
                        <span class="text-xs text-slate-500 dark:text-slate-400">إجمالي الطلبات</span>
                        <div class="text-2xl font-black text-slate-900 dark:text-white">{{ stats.totalOrders }}</div>
                    </div>
                </div>

                <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex items-center gap-4">
                    <div class="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0">
                        <Clock class="w-7 h-7" />
                    </div>
                    <div>
                        <span class="text-xs text-slate-500 dark:text-slate-400">الطلبات النشطة</span>
                        <div class="text-2xl font-black text-slate-900 dark:text-white">{{ stats.activeOrders }}</div>
                    </div>
                </div>

                <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex items-center gap-4">
                    <div class="w-14 h-14 rounded-2xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0">
                        <CreditCard class="w-7 h-7" />
                    </div>
                    <div>
                        <span class="text-xs text-slate-500 dark:text-slate-400">إجمالي المشتريات</span>
                        <div class="text-2xl font-black text-slate-900 dark:text-white">{{ stats.totalSpent }} ₪</div>
                    </div>
                </div>

                <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex items-center gap-4">
                    <div class="w-14 h-14 rounded-2xl bg-rose-50 dark:bg-rose-950/60 text-rose-500 flex items-center justify-center shrink-0">
                        <Heart class="w-7 h-7" />
                    </div>
                    <div>
                        <span class="text-xs text-slate-500 dark:text-slate-400">المنتجات بالمفضلة</span>
                        <div class="text-2xl font-black text-slate-900 dark:text-white">{{ stats.wishlistCount }}</div>
                    </div>
                </div>
            </div>

            <!-- Quick Navigation Modules -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
                <Link
                    :href="route('customer.orders')"
                    class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-lg transition-all flex items-center justify-between group"
                >
                    <div class="space-y-1 text-right">
                        <h3 class="text-sm font-bold text-slate-900 dark:text-white group-hover:text-emerald-600 transition-colors">
                            طلباتي ومشترياتي
                        </h3>
                        <p class="text-xs text-slate-500">تتبع مسار شحناتك وفواتيرك</p>
                    </div>
                    <ArrowLeft class="w-4 h-4 text-slate-400 group-hover:text-emerald-600 group-hover:-translate-x-1 transition-all" />
                </Link>

                <Link
                    :href="route('customer.rewards')"
                    class="p-6 rounded-3xl bg-gradient-to-br from-amber-50 to-amber-100/40 dark:from-amber-950/30 dark:to-slate-900 border border-amber-200 dark:border-amber-900/60 hover:border-amber-500 shadow-sm hover:shadow-lg transition-all flex items-center justify-between group"
                >
                    <div class="space-y-1 text-right">
                        <h3 class="text-sm font-bold text-amber-900 dark:text-amber-300 group-hover:text-amber-600 transition-colors flex items-center gap-1.5">
                            <Coins class="w-4 h-4 text-amber-500" />
                            نقاط الولاء والكاش باك
                        </h3>
                        <p class="text-xs text-amber-700/80 dark:text-amber-400/70">رصيدك ومكافآت الترقية</p>
                    </div>
                    <ArrowLeft class="w-4 h-4 text-amber-600 group-hover:-translate-x-1 transition-all" />
                </Link>

                <Link
                    :href="route('customer.statement')"
                    class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-lg transition-all flex items-center justify-between group"
                >
                    <div class="space-y-1 text-right">
                        <h3 class="text-sm font-bold text-slate-900 dark:text-white group-hover:text-emerald-600 transition-colors">
                            كشف حسابي المحاسبي (ERP)
                        </h3>
                        <p class="text-xs text-slate-500">عرض رصيدك وسنداتك المالية</p>
                    </div>
                    <ArrowLeft class="w-4 h-4 text-slate-400 group-hover:text-emerald-600 group-hover:-translate-x-1 transition-all" />
                </Link>

                <Link
                    :href="route('customer.profile')"
                    class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-lg transition-all flex items-center justify-between group"
                >
                    <div class="space-y-1 text-right">
                        <h3 class="text-sm font-bold text-slate-900 dark:text-white group-hover:text-emerald-600 transition-colors">
                            الملف الشخصي والربط
                        </h3>
                        <p class="text-xs text-slate-500">إدارة الأمان والربط الاجتماعي</p>
                    </div>
                    <ArrowLeft class="w-4 h-4 text-slate-400 group-hover:text-emerald-600 group-hover:-translate-x-1 transition-all" />
                </Link>
            </div>

            <!-- Recent Orders Section -->
            <div class="bg-white dark:bg-slate-900 rounded-3xl p-6 sm:p-8 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                <div class="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
                    <div>
                        <h3 class="text-base font-black text-slate-900 dark:text-white">آخر الطلبات</h3>
                        <p class="text-xs text-slate-500">أحدث عمليات الشراء التي قمت بها</p>
                    </div>

                    <Link :href="route('customer.orders')" class="text-xs font-bold text-emerald-600 hover:underline">
                        عرض كافة الطلبات ({{ stats.totalOrders }})
                    </Link>
                </div>

                <div v-if="recentOrders.length > 0" class="overflow-x-auto">
                    <table class="w-full text-right text-xs">
                        <thead>
                            <tr class="text-slate-400 border-b border-slate-100 dark:border-slate-800 pb-3">
                                <th class="py-3 font-semibold">رقم الطلب</th>
                                <th class="py-3 font-semibold">التاريخ</th>
                                <th class="py-3 font-semibold">المنتجات</th>
                                <th class="py-3 font-semibold">الإجمالي</th>
                                <th class="py-3 font-semibold">حالة الطلب</th>
                                <th class="py-3 font-semibold text-left">الإجراء</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                            <tr v-for="order in recentOrders" :key="order.id" class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                                <td class="py-4 font-mono font-bold text-slate-900 dark:text-white">{{ order.order_number }}</td>
                                <td class="py-4 text-slate-500">{{ new Date(order.created_at).toLocaleDateString('ar-EG') }}</td>
                                <td class="py-4 text-slate-600 dark:text-slate-300">
                                    {{ order.items?.length || 0 }} أصناف
                                </td>
                                <td class="py-4 font-black text-emerald-600">{{ order.total_amount }} ₪</td>
                                <td class="py-4">
                                    <span class="px-3 py-1 rounded-full text-[11px] font-bold" :class="getStatusBadgeClass(order.status)">
                                        {{ getStatusLabel(order.status) }}
                                    </span>
                                </td>
                                <td class="py-4 text-left">
                                    <Link
                                        :href="route('customer.orders.show', order.id)"
                                        class="px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-600 hover:text-white text-slate-700 dark:text-slate-300 font-bold transition-colors inline-block"
                                    >
                                        التفاصيل والفاتورة
                                    </Link>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div v-else class="text-center py-10 text-slate-500 text-xs">
                    لم تقم بإجراء أي طلبات حتى الآن.
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
