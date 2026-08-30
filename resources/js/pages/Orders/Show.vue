<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import AppLayout from '@/layouts/AppLayout.vue';
import {
    ShoppingBag,
    Printer,
    ArrowRight,
    CheckCircle2,
    Clock,
    Truck,
    PackageCheck,
    XCircle,
    User,
    Phone,
    MapPin,
    CreditCard,
    FileText,
    ExternalLink
} from 'lucide-vue-next';

interface OrderItem {
    id: number;
    item_id?: number;
    item_name: string;
    quantity: number;
    unit_price: number;
    total_price: number;
}

interface Order {
    id: number;
    order_number: string;
    status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
    subtotal: number;
    shipping_fee: number;
    total_amount: number;
    payment_method: string;
    payment_status: string;
    shipping_name: string;
    shipping_phone: string;
    shipping_address: string;
    shipping_city?: string;
    notes?: string;
    invoice_id?: number;
    created_at: string;
    items?: OrderItem[];
    party?: { id: number; name: string; phone?: string };
    invoice?: { id: number; date: string; notes?: string };
    user?: { id: number; name: string; email: string };
}

interface Props {
    order: Order;
}

const props = defineProps<Props>();

const breadcrumbs = [
    { title: 'الرئيسية', href: '/dashboard' },
    { title: 'طلبات المتجر', href: '/orders' },
    { title: props.order.order_number, href: `/orders/${props.order.id}` },
];

const selectedStatus = ref(props.order.status);
const statusNotes = ref('');

const updateStatus = () => {
    router.post(route('orders.update_status', props.order.id), {
        status: selectedStatus.value,
        notes: statusNotes.value,
    }, {
        preserveScroll: true,
    });
};

const printInvoice = () => {
    window.print();
};
</script>

<template>
    <AppLayout :breadcrumbs="breadcrumbs">
        <Head :title="`تفاصيل الطلب ${order.order_number}`" />

        <div class="space-y-6 p-6 font-sans" dir="rtl">
            <!-- Header Bar -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 print:hidden">
                <div class="space-y-1">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-black text-slate-900 dark:text-white font-mono">
                            {{ order.order_number }}
                        </h1>
                        <span class="px-3 py-1 rounded-full text-xs font-bold" :class="{
                            'bg-emerald-100 text-emerald-800': order.status === 'delivered',
                            'bg-blue-100 text-blue-800': order.status === 'shipped',
                            'bg-amber-100 text-amber-800': order.status === 'processing',
                            'bg-rose-100 text-rose-800': order.status === 'cancelled',
                            'bg-slate-100 text-slate-800': order.status === 'pending',
                        }">
                            {{ order.status }}
                        </span>
                    </div>
                    <p class="text-xs text-slate-500">
                        تاريخ الطلب: {{ new Date(order.created_at).toLocaleString('ar-EG') }}
                    </p>
                </div>

                <div class="flex items-center gap-3">
                    <button
                        @click="printInvoice"
                        class="px-4 py-2 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-2 transition-colors shadow-sm"
                    >
                        <Printer class="w-4 h-4" />
                        <span>طباعة الفاتورة</span>
                    </button>
                    <Link
                        :href="route('orders.index')"
                        class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100"
                    >
                        العودة لقائمة الطلبات
                    </Link>
                </div>
            </div>

            <!-- Status Changer Card (Print: hidden) -->
            <div class="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4 print:hidden">
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">تحديث حالة الطلب والشحن</h3>
                <div class="flex flex-wrap items-center gap-4">
                    <select
                        v-model="selectedStatus"
                        class="px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-bold focus:ring-2 focus:ring-emerald-500"
                    >
                        <option value="pending">قيد الانتظار (Pending)</option>
                        <option value="processing">قيد التجهيز (Processing)</option>
                        <option value="shipped">تم الشحن (Shipped)</option>
                        <option value="delivered">تم التسليم (Delivered)</option>
                        <option value="cancelled">إلغاء الطلب (Cancelled)</option>
                    </select>

                    <input
                        type="text"
                        v-model="statusNotes"
                        placeholder="ملاحظات التحديث (اختياري)..."
                        class="flex-1 min-w-[200px] px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                    />

                    <button
                        @click="updateStatus"
                        class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-md shadow-emerald-600/20 transition-colors"
                    >
                        حفظ الحالة
                    </button>
                </div>
            </div>

            <!-- Customer & Accounting Info Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Customer Info -->
                <div class="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-3 text-xs">
                    <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                        <User class="w-4 h-4 text-emerald-600" />
                        بيانات العميل والشحن
                    </h3>
                    <div class="space-y-1.5 text-slate-600 dark:text-slate-300">
                        <p><strong class="text-slate-900 dark:text-white">الاسم:</strong> {{ order.shipping_name }}</p>
                        <p><strong class="text-slate-900 dark:text-white">رقم الهاتف:</strong> {{ order.shipping_phone }}</p>
                        <p><strong class="text-slate-900 dark:text-white">المدينة:</strong> {{ order.shipping_city || 'غزة' }}</p>
                        <p><strong class="text-slate-900 dark:text-white">العنوان:</strong> {{ order.shipping_address }}</p>
                        <p v-if="order.user"><strong class="text-slate-900 dark:text-white">حساب الزبون:</strong> {{ order.user.email }}</p>
                        <p v-if="order.notes"><strong class="text-slate-900 dark:text-white">ملاحظات العميل:</strong> {{ order.notes }}</p>
                    </div>
                </div>

                <!-- Accounting Link -->
                <div class="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-3 text-xs">
                    <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                        <FileText class="w-4 h-4 text-indigo-600" />
                        الربط المحاسبي (ERP Ledger)
                    </h3>
                    <div class="space-y-1.5 text-slate-600 dark:text-slate-300">
                        <p>
                            <strong class="text-slate-900 dark:text-white">فاتورة المبيعات:</strong>
                            <Link v-if="order.invoice_id" :href="`/invoices`" class="text-indigo-600 font-bold mr-1 underline">
                                INV-000{{ order.invoice_id }}
                            </Link>
                            <span v-else class="text-slate-400">غير منشأة</span>
                        </p>
                        <p><strong class="text-slate-900 dark:text-white">طريقة الدفع:</strong> {{ order.payment_method === 'cod' ? 'عند الاستلام (نقداً)' : order.payment_method }}</p>
                        <p><strong class="text-slate-900 dark:text-white">حالة السداد:</strong> {{ order.payment_status === 'paid' ? 'مسدد بالكامل ✓' : 'غير مسدد' }}</p>
                        <p><strong class="text-slate-900 dark:text-white">العميل المحاسبي:</strong> {{ order.party?.name || 'عميل نقدي' }}</p>
                    </div>
                </div>
            </div>

            <!-- Items Table -->
            <div class="p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
                <h3 class="text-sm font-bold text-slate-900 dark:text-white">أصناف الطلب والكميات</h3>
                <div class="overflow-x-auto">
                    <table class="w-full text-right text-xs">
                        <thead class="text-slate-400 border-b border-slate-100 dark:border-slate-800 pb-2">
                            <tr>
                                <th class="py-2.5 font-bold">اسم المنتج</th>
                                <th class="py-2.5 font-bold text-center">الكمية</th>
                                <th class="py-2.5 font-bold">سعر الوحدة</th>
                                <th class="py-2.5 font-bold text-left">المجموع</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                            <tr v-for="item in order.items" :key="item.id">
                                <td class="py-3 font-bold text-slate-900 dark:text-white">{{ item.item_name }}</td>
                                <td class="py-3 text-center font-bold">{{ item.quantity }}</td>
                                <td class="py-3 text-slate-600 dark:text-slate-300">{{ item.unit_price }} ₪</td>
                                <td class="py-3 text-left font-black text-emerald-600">{{ item.total_price }} ₪</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                    <div class="w-64 space-y-2 text-xs">
                        <div class="flex items-center justify-between text-slate-500">
                            <span>المجموع الفرعي:</span>
                            <span class="font-bold text-slate-900 dark:text-white">{{ order.subtotal }} ₪</span>
                        </div>
                        <div class="flex items-center justify-between text-slate-500">
                            <span>الشحن:</span>
                            <span class="font-bold text-slate-900 dark:text-white">{{ order.shipping_fee }} ₪</span>
                        </div>
                        <div class="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-sm">
                            <span class="font-black text-slate-900 dark:text-white">الإجمالي الكلي:</span>
                            <span class="font-black text-emerald-600 text-lg">{{ order.total_amount }} ₪</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
