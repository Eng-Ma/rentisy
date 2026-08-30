<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AppLayout from '@/layouts/AppLayout.vue';
import {
    ShoppingBag,
    Search,
    Filter,
    Eye,
    Trash2,
    Clock,
    Truck,
    PackageCheck,
    CheckCircle2,
    XCircle,
    RotateCcw,
    DollarSign,
    ChevronDown,
    Printer,
    FileText
} from 'lucide-vue-next';

interface OrderItem {
    id: number;
    item_name: string;
    quantity: number;
    total_price: number;
}

interface Order {
    id: number;
    order_number: string;
    status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
    payment_method: string;
    payment_status: string;
    total_amount: number;
    shipping_name: string;
    shipping_phone: string;
    shipping_city?: string;
    created_at: string;
    items?: OrderItem[];
    invoice_id?: number;
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
        search?: string;
        status?: string;
        payment_method?: string;
        date?: string;
    };
    metrics: {
        totalOrders: number;
        pendingOrders: number;
        processingOrders: number;
        shippedOrders: number;
        deliveredOrders: number;
        cancelledOrders: number;
        totalRevenue: number;
    };
}

const props = defineProps<Props>();

const breadcrumbs = [
    { title: 'الرئيسية', href: '/dashboard' },
    { title: 'طلبات المتجر الإلكتروني', href: '/orders' },
];

const search = ref(props.filters.search || '');
const currentStatus = ref(props.filters.status || '');
const paymentMethod = ref(props.filters.payment_method || '');

const handleFilter = () => {
    router.get(route('orders.index'), {
        search: search.value,
        status: currentStatus.value,
        payment_method: paymentMethod.value,
    }, {
        preserveState: true,
        preserveScroll: true,
    });
};

const filterByStatusTab = (statusKey: string) => {
    currentStatus.value = statusKey;
    handleFilter();
};

const updateOrderStatus = (orderId: number, newStatus: string) => {
    router.post(route('orders.update_status', orderId), {
        status: newStatus,
    }, {
        preserveScroll: true,
    });
};

const deleteOrder = (orderId: number) => {
    if (confirm('هل أنت متأكد من حذف هذا الطلب نهائياً؟')) {
        router.delete(route('orders.destroy', orderId), {
            preserveScroll: true,
        });
    }
};

const getStatusBadge = (status: string) => {
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
        case 'shipped': return 'تم الشحن';
        case 'processing': return 'قيد التجهيز';
        case 'cancelled': return 'ملغي';
        case 'pending':
        default: return 'قيد الانتظار';
    }
};
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">
        <Head title="إدارة طلبات المتجر الإلكتروني" />

        <div class="space-y-6 p-6 font-sans" dir="rtl">
            <!-- Header Title -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 class="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-2.5">
                        <ShoppingBag class="w-7 h-7 text-emerald-600" />
                        <span>إدارة طلبات المتجر والمبيعات الإلكترونية</span>
                    </h1>
                    <p class="text-xs text-slate-500 mt-1">
                        لوحة التحكم المركزية للطلبات، تحديث حالات الشحن، وتتبع قيود الفواتير المحاسبية
                    </p>
                </div>

                <div class="flex items-center gap-2">
                    <Link
                        :href="route('home')"
                        target="_blank"
                        class="px-4 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-200 text-xs font-bold transition-colors"
                    >
                        زيارة المتجر العام ↗
                    </Link>
                </div>
            </div>

            <!-- KPI Metric Cards -->
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
                <div class="p-4 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm">
                    <span class="text-[11px] text-slate-500 block">إجمالي الطلبات</span>
                    <div class="text-xl font-black text-slate-900 dark:text-white mt-1">{{ metrics.totalOrders }}</div>
                </div>

                <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-800 shadow-sm">
                    <span class="text-[11px] text-slate-500 block">قيد الانتظار</span>
                    <div class="text-xl font-black text-slate-700 dark:text-slate-300 mt-1">{{ metrics.pendingOrders }}</div>
                </div>

                <div class="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 shadow-sm">
                    <span class="text-[11px] text-amber-700 dark:text-amber-400 block font-semibold">قيد التجهيز</span>
                    <div class="text-xl font-black text-amber-700 dark:text-amber-300 mt-1">{{ metrics.processingOrders }}</div>
                </div>

                <div class="p-4 rounded-2xl bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-900/60 shadow-sm">
                    <span class="text-[11px] text-blue-700 dark:text-blue-400 block font-semibold">تم الشحن</span>
                    <div class="text-xl font-black text-blue-700 dark:text-blue-300 mt-1">{{ metrics.shippedOrders }}</div>
                </div>

                <div class="p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900/60 shadow-sm">
                    <span class="text-[11px] text-emerald-700 dark:text-emerald-400 block font-semibold">تم التسليم</span>
                    <div class="text-xl font-black text-emerald-700 dark:text-emerald-300 mt-1">{{ metrics.deliveredOrders }}</div>
                </div>

                <div class="p-4 rounded-2xl bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-900/60 shadow-sm">
                    <span class="text-[11px] text-indigo-700 dark:text-indigo-400 block font-semibold">إجمالي المبيعات</span>
                    <div class="text-lg font-black text-indigo-700 dark:text-indigo-300 mt-1">{{ metrics.totalRevenue }} ₪</div>
                </div>
            </div>

            <!-- Status Tabs & Search Bar -->
            <div class="p-4 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
                <!-- Status Tab Buttons -->
                <div class="flex flex-wrap items-center gap-2 border-b border-slate-100 dark:border-slate-800 pb-3">
                    <button
                        @click="filterByStatusTab('')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === '' ? 'bg-slate-900 text-white dark:bg-emerald-600 shadow-sm' : 'text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                        الكل ({{ metrics.totalOrders }})
                    </button>
                    <button
                        @click="filterByStatusTab('pending')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === 'pending' ? 'bg-slate-800 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                        قيد الانتظار ({{ metrics.pendingOrders }})
                    </button>
                    <button
                        @click="filterByStatusTab('processing')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === 'processing' ? 'bg-amber-600 text-white shadow-sm' : 'text-amber-700 hover:bg-amber-50 dark:hover:bg-amber-950/40'"
                    >
                        قيد التجهيز ({{ metrics.processingOrders }})
                    </button>
                    <button
                        @click="filterByStatusTab('shipped')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === 'shipped' ? 'bg-blue-600 text-white shadow-sm' : 'text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-950/40'"
                    >
                        تم الشحن ({{ metrics.shippedOrders }})
                    </button>
                    <button
                        @click="filterByStatusTab('delivered')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === 'delivered' ? 'bg-emerald-600 text-white shadow-sm' : 'text-emerald-700 hover:bg-emerald-50 dark:hover:bg-emerald-950/40'"
                    >
                        تم التسليم ({{ metrics.deliveredOrders }})
                    </button>
                    <button
                        @click="filterByStatusTab('cancelled')"
                        class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all"
                        :class="currentStatus === 'cancelled' ? 'bg-rose-600 text-white shadow-sm' : 'text-rose-700 hover:bg-rose-50 dark:hover:bg-rose-950/40'"
                    >
                        ملغي ({{ metrics.cancelledOrders }})
                    </button>
                </div>

                <!-- Search Inputs -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div class="sm:col-span-2 relative">
                        <input
                            type="text"
                            v-model="search"
                            @keyup.enter="handleFilter"
                            placeholder="ابحث برقم الطلب، اسم العميل، رقم الهاتف، أو اسم المنتج..."
                            class="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                        />
                        <button @click="handleFilter" class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
                            <Search class="w-4 h-4" />
                        </button>
                    </div>

                    <div>
                        <select
                            v-model="paymentMethod"
                            @change="handleFilter"
                            class="w-full px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-medium focus:ring-2 focus:ring-emerald-500"
                        >
                            <option value="">جميع طرق الدفع</option>
                            <option value="cod">الدفع عند الاستلام (COD)</option>
                            <option value="card">بطاقة ائتمان</option>
                            <option value="bank_transfer">تحويل بنكي</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Orders Table -->
            <div class="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                <div v-if="orders.data.length > 0" class="overflow-x-auto">
                    <table class="w-full text-right text-xs">
                        <thead class="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-slate-500">
                            <tr>
                                <th class="py-3.5 px-4 font-bold">رقم الطلب</th>
                                <th class="py-3.5 px-4 font-bold">التاريخ</th>
                                <th class="py-3.5 px-4 font-bold">العميل والمستلم</th>
                                <th class="py-3.5 px-4 font-bold">المنتجات</th>
                                <th class="py-3.5 px-4 font-bold">المجموع</th>
                                <th class="py-3.5 px-4 font-bold">طريقة وسداد الدفع</th>
                                <th class="py-3.5 px-4 font-bold">حالة الطلب والتحكم</th>
                                <th class="py-3.5 px-4 font-bold text-left">الإجراءات</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                            <tr v-for="order in orders.data" :key="order.id" class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                                <td class="py-3.5 px-4 font-mono font-bold text-slate-900 dark:text-white">
                                    <Link :href="route('orders.show', order.id)" class="hover:text-emerald-600 hover:underline">
                                        {{ order.order_number }}
                                    </Link>
                                    <div v-if="order.invoice_id" class="text-[10px] text-slate-400 font-normal">
                                        فاتورة ERP #{{ order.invoice_id }}
                                    </div>
                                </td>
                                <td class="py-3.5 px-4 text-slate-500">
                                    {{ new Date(order.created_at).toLocaleDateString('ar-EG') }}
                                </td>
                                <td class="py-3.5 px-4">
                                    <div class="font-bold text-slate-900 dark:text-white">{{ order.shipping_name }}</div>
                                    <div class="text-[11px] text-slate-500 font-mono">{{ order.shipping_phone }} ({{ order.shipping_city || 'غزة' }})</div>
                                </td>
                                <td class="py-3.5 px-4 text-slate-600 dark:text-slate-300">
                                    <span class="font-bold text-slate-900 dark:text-white">{{ order.items?.length || 0 }} قطع</span>
                                    <div class="text-[10px] text-slate-400 line-clamp-1 max-w-[140px]">
                                        {{ order.items?.map(i => i.item_name).join(', ') }}
                                    </div>
                                </td>
                                <td class="py-3.5 px-4 font-black text-emerald-600">
                                    {{ order.total_amount }} ₪
                                </td>
                                <td class="py-3.5 px-4">
                                    <span class="text-[11px] block font-medium">
                                        {{ order.payment_method === 'cod' ? 'عند الاستلام' : (order.payment_method === 'card' ? 'بطاقة' : 'تحويل') }}
                                    </span>
                                    <span class="text-[10px] px-1.5 py-0.5 rounded font-bold" :class="order.payment_status === 'paid' ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-600'">
                                        {{ order.payment_status === 'paid' ? 'مدفوع ✓' : 'غير مسدد' }}
                                    </span>
                                </td>
                                <td class="py-3.5 px-4">
                                    <select
                                        :value="order.status"
                                        @change="(e: any) => updateOrderStatus(order.id, e.target.value)"
                                        class="px-2.5 py-1 rounded-lg text-[11px] font-bold border-0 cursor-pointer focus:ring-2 focus:ring-emerald-500"
                                        :class="getStatusBadge(order.status)"
                                    >
                                        <option value="pending">قيد الانتظار</option>
                                        <option value="processing">قيد التجهيز</option>
                                        <option value="shipped">تم الشحن</option>
                                        <option value="delivered">تم التسليم</option>
                                        <option value="cancelled">إلغاء الطلب</option>
                                    </select>
                                </td>
                                <td class="py-3.5 px-4 text-left">
                                    <div class="flex items-center justify-end gap-2">
                                        <Link
                                            :href="route('orders.show', order.id)"
                                            class="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
                                            title="عرض التفاصيل والفاتورة"
                                        >
                                            <Eye class="w-4 h-4" />
                                        </Link>
                                        <button
                                            @click="deleteOrder(order.id)"
                                            class="p-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors"
                                            title="حذف الطلب"
                                        >
                                            <Trash2 class="w-4 h-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div v-else class="p-12 text-center text-slate-500 text-xs">
                    لم يتم العثور على أي طلبات في هذه القائمة.
                </div>

                <!-- Pagination -->
                <div v-if="orders.last_page > 1" class="p-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-center gap-2">
                    <Link
                        v-for="(link, i) in orders.links"
                        :key="i"
                        :href="link.url || '#'"
                        class="px-3 py-1.5 rounded-xl text-xs font-bold transition-colors"
                        :class="{
                            'bg-emerald-600 text-white': link.active,
                            'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300': !link.active && link.url,
                            'opacity-40 cursor-not-allowed': !link.url
                        }"
                        v-html="link.label"
                    />
                </div>
            </div>
        </div>
    </AppLayout>
</template>
