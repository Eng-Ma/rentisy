<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    PackageCheck,
    Search,
    Filter,
    ArrowLeft,
    Clock,
    Truck,
    CheckCircle2,
    XCircle,
    ShoppingBag
} from 'lucide-vue-next';

interface OrderItem {
    id: number;
    item_name: string;
    quantity: number;
    unit_price: number;
    total_price: number;
}

interface Order {
    id: number;
    order_number: string;
    status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
    payment_method: string;
    payment_status: string;
    total_amount: number;
    created_at: string;
    items?: OrderItem[];
}

interface Props {
    orders: {
        data: Order[];
        current_page: number;
        last_page: number;
        total: number;
        links: Array<{ url: string | null; label: string; active: boolean }>;
    };
    filters: {
        status?: string;
        search?: string;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const search = ref(props.filters.search || '');
const status = ref(props.filters.status || '');

const handleFilter = () => {
    router.get(route('customer.orders'), {
        search: search.value,
        status: status.value,
    }, {
        preserveState: true,
        preserveScroll: true,
    });
};

const getStatusBadgeClass = (status: string) => {
    switch (status) {
        case 'delivered': return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300';
        case 'shipped': return 'bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-300';
        case 'processing': return 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300';
        case 'cancelled': return 'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300';
        case 'pending':
        default: return 'bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300';
    }
};

const getStatusLabel = (status: string) => {
    switch (status) {
        case 'delivered': return 'تم التوصيل';
        case 'shipped': return 'تم الشحن بالطريق';
        case 'processing': return 'قيد التجهيز';
        case 'cancelled': return 'ملغي';
        case 'pending':
        default: return 'قيد المراجعة والانتظار';
    }
};

const getPaymentMethodLabel = (method: string) => {
    switch (method) {
        case 'cod': return 'دفع عند الاستلام';
        case 'card': return 'بطاقة ائتمان';
        case 'bank_transfer': return 'تحويل بنكي';
        default: return method;
    }
};
</script>

<template>
    <StoreLayout title="سجل طلباتي ومشترياتي | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Header -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
                <div>
                    <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">طلباتي ومشترياتي</h1>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        استعراض وتتبع كافة الطلبات وتفاصيل فواتير المبيعات المرتبطة بها
                    </p>
                </div>

                <Link
                    :href="route('customer.dashboard')"
                    class="text-xs font-bold text-slate-600 dark:text-slate-400 hover:text-emerald-600 flex items-center gap-1 self-start sm:self-auto"
                >
                    <ArrowRight class="w-4 h-4" />
                    <span>العودة للوحة الحساب</span>
                </Link>
            </div>

            <!-- Filters Bar -->
            <div class="p-4 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4 mb-8">
                <!-- Search -->
                <div class="w-full sm:max-w-md relative">
                    <input
                        type="text"
                        v-model="search"
                        @keyup.enter="handleFilter"
                        placeholder="ابحث برقم الطلب أو اسم المنتج..."
                        class="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                    />
                    <button @click="handleFilter" class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
                        <Search class="w-4 h-4" />
                    </button>
                </div>

                <!-- Status Filter -->
                <div class="flex items-center gap-3 w-full sm:w-auto">
                    <span class="text-xs text-slate-500 whitespace-nowrap">الحالة:</span>
                    <select
                        v-model="status"
                        @change="handleFilter"
                        class="w-full sm:w-auto px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-medium focus:ring-2 focus:ring-emerald-500"
                    >
                        <option value="">جميع الحالات</option>
                        <option value="pending">قيد الانتظار</option>
                        <option value="processing">قيد التجهيز</option>
                        <option value="shipped">تم الشحن</option>
                        <option value="delivered">تم التوصيل</option>
                        <option value="cancelled">ملغي</option>
                    </select>
                </div>
            </div>

            <!-- Orders Listing -->
            <div v-if="orders.data.length > 0" class="space-y-4">
                <div
                    v-for="order in orders.data"
                    :key="order.id"
                    class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm hover:border-emerald-500 transition-all flex flex-col md:flex-row items-start md:items-center justify-between gap-6"
                >
                    <div class="space-y-2 text-right">
                        <div class="flex items-center gap-3">
                            <span class="text-sm font-mono font-black text-slate-900 dark:text-white">
                                {{ order.order_number }}
                            </span>
                            <span class="px-3 py-1 rounded-full text-[11px] font-bold" :class="getStatusBadgeClass(order.status)">
                                {{ getStatusLabel(order.status) }}
                            </span>
                        </div>

                        <div class="flex flex-wrap items-center gap-4 text-xs text-slate-500">
                            <span>التاريخ: {{ new Date(order.created_at).toLocaleDateString('ar-EG') }}</span>
                            <span>طريقة الدفع: {{ getPaymentMethodLabel(order.payment_method) }}</span>
                            <span>عدد الأصناف: {{ order.items?.length || 0 }}</span>
                        </div>

                        <div v-if="order.items && order.items.length > 0" class="text-xs text-slate-600 dark:text-slate-300 pt-1 line-clamp-1">
                            المنتجات: {{ order.items.map(i => `${i.item_name} (${i.quantity})`).join(', ') }}
                        </div>
                    </div>

                    <div class="flex items-center justify-between md:justify-end gap-6 w-full md:w-auto pt-4 md:pt-0 border-t md:border-t-0 border-slate-100 dark:border-slate-800">
                        <div class="text-right md:text-left">
                            <span class="text-[11px] text-slate-400 block">إجمالي الفاتورة</span>
                            <span class="text-xl font-black text-emerald-600 dark:text-emerald-400">{{ order.total_amount }} ₪</span>
                        </div>

                        <Link
                            :href="route('customer.orders.show', order.id)"
                            class="px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 transition-colors shadow-md shadow-emerald-600/20"
                        >
                            <span>تفاصيل الفاتورة</span>
                            <ArrowLeft class="w-4 h-4" />
                        </Link>
                    </div>
                </div>

                <!-- Pagination -->
                <div v-if="orders.last_page > 1" class="pt-8 flex items-center justify-center gap-2">
                    <Link
                        v-for="(link, i) in orders.links"
                        :key="i"
                        :href="link.url || '#'"
                        class="px-4 py-2 rounded-xl text-xs font-bold transition-colors"
                        :class="{
                            'bg-emerald-600 text-white shadow-md': link.active,
                            'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-50': !link.active && link.url,
                            'opacity-40 cursor-not-allowed': !link.url
                        }"
                        v-html="link.label"
                    />
                </div>
            </div>

            <!-- Empty State -->
            <div v-else class="p-16 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 space-y-6 max-w-xl mx-auto shadow-sm">
                <div class="w-20 h-20 rounded-3xl bg-slate-100 dark:bg-slate-800 text-slate-400 flex items-center justify-center mx-auto">
                    <PackageCheck class="w-10 h-10" />
                </div>
                <div class="space-y-2">
                    <h3 class="text-xl font-black text-slate-900 dark:text-white">لم يتم العثور على أي طلبات</h3>
                    <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                        لا توجد طلبات تطابق معايير البحث الحالية.
                    </p>
                </div>
                <Link
                    :href="route('store.shop')"
                    class="inline-flex items-center gap-2 px-8 py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-lg shadow-emerald-600/25"
                >
                    <ShoppingBag class="w-4 h-4" />
                    <span>تصفح المتجر الآن</span>
                </Link>
            </div>
        </div>
    </StoreLayout>
</template>
