<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    Printer,
    ArrowRight,
    CheckCircle2,
    Clock,
    Truck,
    PackageCheck,
    ShieldCheck,
    FileText,
    MapPin,
    Phone,
    User as UserIcon,
    CreditCard
} from 'lucide-vue-next';

interface OrderItem {
    id: number;
    item_id?: number;
    item_name: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    item?: {
        image?: string;
    };
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
    invoice?: {
        id: number;
        date: string;
        notes?: string;
    };
}

interface Props {
    order: Order;
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const printReceipt = () => {
    window.print();
};

const getStatusIndex = (status: string) => {
    switch (status) {
        case 'pending': return 1;
        case 'processing': return 2;
        case 'shipped': return 3;
        case 'delivered': return 4;
        case 'cancelled': return 0;
        default: return 1;
    }
};

const getPaymentMethodLabel = (method: string) => {
    switch (method) {
        case 'cod': return 'الدفع عند الاستلام نقداً';
        case 'card': return 'بطاقة ائتمانية (Visa / Mastercard)';
        case 'bank_transfer': return 'حوالة بنكية مباشرة';
        default: return method;
    }
};
</script>

<template>
    <StoreLayout :title="`تفاصيل الطلب ${order.order_number} | رنتيسي ستور`" :storeContext="storeContext">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Header Actions -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 print:hidden">
                <div class="space-y-1 text-right">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white font-mono">
                            {{ order.order_number }}
                        </h1>
                        <span class="px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300">
                            فاتورة مبيعات ERP #{{ order.invoice_id }}
                        </span>
                    </div>
                    <p class="text-xs text-slate-500">
                        تاريخ الإنشاء: {{ new Date(order.created_at).toLocaleString('ar-EG') }}
                    </p>
                </div>

                <div class="flex items-center gap-3">
                    <button
                        @click="printReceipt"
                        class="px-5 py-2.5 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-2 transition-colors shadow-sm"
                    >
                        <Printer class="w-4 h-4" />
                        <span>طباعة الفاتورة / الإيصال</span>
                    </button>
                    <Link
                        :href="route('customer.orders')"
                        class="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100"
                    >
                        العودة لقائمتي
                    </Link>
                </div>
            </div>

            <!-- Main Order Printable Card -->
            <div class="bg-white dark:bg-slate-900 rounded-3xl p-6 sm:p-10 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-10">
                <!-- Timeline Progress (Hidden in print) -->
                <div v-if="order.status !== 'cancelled'" class="space-y-4 print:hidden">
                    <h3 class="text-xs font-bold text-slate-500 uppercase tracking-wider">مسار تقدم الطلب والتوصيل</h3>
                    <div class="grid grid-cols-4 gap-2 text-center text-xs">
                        <!-- Step 1 -->
                        <div class="space-y-2">
                            <div class="w-10 h-10 rounded-full mx-auto flex items-center justify-center font-bold text-sm shadow-md" :class="getStatusIndex(order.status) >= 1 ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-400'">
                                <Clock class="w-5 h-5" />
                            </div>
                            <span class="font-bold text-slate-900 dark:text-white block">تم استلام الطلب</span>
                        </div>

                        <!-- Step 2 -->
                        <div class="space-y-2">
                            <div class="w-10 h-10 rounded-full mx-auto flex items-center justify-center font-bold text-sm shadow-md" :class="getStatusIndex(order.status) >= 2 ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-400'">
                                <PackageCheck class="w-5 h-5" />
                            </div>
                            <span class="font-bold text-slate-900 dark:text-white block">قيد التجهيز بالمستودع</span>
                        </div>

                        <!-- Step 3 -->
                        <div class="space-y-2">
                            <div class="w-10 h-10 rounded-full mx-auto flex items-center justify-center font-bold text-sm shadow-md" :class="getStatusIndex(order.status) >= 3 ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-400'">
                                <Truck class="w-5 h-5" />
                            </div>
                            <span class="font-bold text-slate-900 dark:text-white block">في الطريق للشحن</span>
                        </div>

                        <!-- Step 4 -->
                        <div class="space-y-2">
                            <div class="w-10 h-10 rounded-full mx-auto flex items-center justify-center font-bold text-sm shadow-md" :class="getStatusIndex(order.status) >= 4 ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-400'">
                                <CheckCircle2 class="w-5 h-5" />
                            </div>
                            <span class="font-bold text-slate-900 dark:text-white block">تم التسليم بنجاح</span>
                        </div>
                    </div>
                </div>

                <!-- Order Info & Customer Box -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-8 pb-8 border-b border-slate-100 dark:border-slate-800 text-xs">
                    <div class="space-y-3">
                        <h4 class="font-black text-sm text-slate-900 dark:text-white flex items-center gap-2">
                            <MapPin class="w-4 h-4 text-emerald-600" />
                            عنوان وبيانات المستلم
                        </h4>
                        <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 space-y-1.5 text-slate-600 dark:text-slate-300">
                            <p><strong class="text-slate-900 dark:text-white">الاسم:</strong> {{ order.shipping_name }}</p>
                            <p><strong class="text-slate-900 dark:text-white">رقم الهاتف:</strong> {{ order.shipping_phone }}</p>
                            <p><strong class="text-slate-900 dark:text-white">المدينة:</strong> {{ order.shipping_city || 'غزة' }}</p>
                            <p><strong class="text-slate-900 dark:text-white">العنوان:</strong> {{ order.shipping_address }}</p>
                            <p v-if="order.notes"><strong class="text-slate-900 dark:text-white">ملاحظات:</strong> {{ order.notes }}</p>
                        </div>
                    </div>

                    <div class="space-y-3">
                        <h4 class="font-black text-sm text-slate-900 dark:text-white flex items-center gap-2">
                            <CreditCard class="w-4 h-4 text-emerald-600" />
                            تفاصيل الدفع والمحاسبة
                        </h4>
                        <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 space-y-1.5 text-slate-600 dark:text-slate-300">
                            <p><strong class="text-slate-900 dark:text-white">طريقة الدفع:</strong> {{ getPaymentMethodLabel(order.payment_method) }}</p>
                            <p><strong class="text-slate-900 dark:text-white">حالة السداد:</strong> {{ order.payment_status === 'paid' ? 'مدفوع بالكامل ✓' : 'مستحق الدفع عند الاستلام' }}</p>
                            <p><strong class="text-slate-900 dark:text-white">رقم القيد / الفاتورة:</strong> INV-000{{ order.invoice_id }}</p>
                            <p><strong class="text-slate-900 dark:text-white">المستودع المنفذ:</strong> المستودع الرئيسي (MAIN-01)</p>
                        </div>
                    </div>
                </div>

                <!-- Line Items Table -->
                <div class="space-y-4">
                    <h4 class="font-black text-sm text-slate-900 dark:text-white">بنود الفاتورة والمنتجات</h4>
                    <div class="overflow-x-auto">
                        <table class="w-full text-right text-xs">
                            <thead>
                                <tr class="text-slate-400 border-b border-slate-100 dark:border-slate-800 pb-3">
                                    <th class="py-3 font-bold">المنتج</th>
                                    <th class="py-3 font-bold text-center">الكمية</th>
                                    <th class="py-3 font-bold">سعر الوحدة</th>
                                    <th class="py-3 font-bold text-left">المجموع</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <tr v-for="line in order.items" :key="line.id" class="py-4">
                                    <td class="py-4 font-bold text-slate-900 dark:text-white">
                                        {{ line.item_name }}
                                    </td>
                                    <td class="py-4 text-center font-bold">{{ line.quantity }}</td>
                                    <td class="py-4 font-semibold text-slate-600 dark:text-slate-300">{{ line.unit_price }} ₪</td>
                                    <td class="py-4 text-left font-black text-emerald-600">{{ line.total_price }} ₪</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Totals Section -->
                <div class="pt-6 border-t border-slate-100 dark:border-slate-800 flex justify-end">
                    <div class="w-full sm:w-72 space-y-3 text-xs">
                        <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                            <span>المجموع الفرعي:</span>
                            <span class="font-bold text-slate-900 dark:text-white">{{ order.subtotal }} ₪</span>
                        </div>
                        <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                            <span>رسوم التوصيل والشحن:</span>
                            <span v-if="order.shipping_fee == 0" class="text-emerald-600 font-bold">مجاني</span>
                            <span v-else class="font-bold text-slate-900 dark:text-white">{{ order.shipping_fee }} ₪</span>
                        </div>
                        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-base">
                            <span class="font-black text-slate-900 dark:text-white">الإجمالي الكلي:</span>
                            <span class="font-black text-2xl text-emerald-600 dark:text-emerald-400">{{ order.total_amount }} ₪</span>
                        </div>
                    </div>
                </div>

                <!-- ERP Trust Footer -->
                <div class="pt-6 border-t border-dashed border-slate-200 dark:border-slate-800 text-center text-xs text-slate-400 space-y-1">
                    <p>فاتورة إلكترونية معتمدة صادرة من نظام رنتيسي للمحاسبة والمستودعات ERP.</p>
                    <p>شكراً لتعاملك معنا. لأي استفسار يرجى التواصل مع الدعم الفني.</p>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
