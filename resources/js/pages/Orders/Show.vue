<script setup lang="ts">
import { ref } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
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
    ExternalLink,
    Store,
    Image,
    Check,
    X,
    Eye,
    ShieldCheck
} from 'lucide-vue-next'

interface OrderItem {
    id: number
    item_id?: number
    item_name: string
    quantity: number
    unit_price: number
    total_price: number
}

interface Order {
    id: number
    order_number: string
    status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
    subtotal: number
    discount_amount?: number
    cashback_discount?: number
    shipping_fee: number
    total_amount: number
    payment_method: string
    transfer_method_id?: number
    transfer_method_name?: string
    transfer_method?: { id: number; name: string; account_name?: string; account_number?: string; iban?: string; phone?: string; logo_url?: string }
    payment_status: string
    payment_receipt_url?: string
    is_payment_verified?: boolean
    delivery_type?: 'delivery' | 'pickup'
    delivery_zone_id?: number
    delivery_zone?: { id: number; name: string; city: string; delivery_fee: number }
    shipping_name: string
    shipping_phone: string
    shipping_address: string
    shipping_city?: string
    notes?: string
    invoice_id?: number
    created_at: string
    items?: OrderItem[]
    party?: { id: number; name: string; phone?: string }
    invoice?: { id: number; date: string; notes?: string }
    user?: { id: number; name: string; email: string }
}

interface Props {
    order: Order
}

const props = defineProps<Props>()

const breadcrumbs = [
    { title: 'الرئيسية', href: '/dashboard' },
    { title: 'طلبات المتجر', href: '/orders' },
    { title: props.order.order_number, href: `/orders/${props.order.id}` },
]

const selectedStatus = ref(props.order.status)
const statusNotes = ref('')
const isPreviewOpen = ref(false)

const updateStatus = () => {
    router.post(route('orders.update_status', props.order.id), {
        status: selectedStatus.value,
        notes: statusNotes.value,
    }, {
        preserveScroll: true,
    })
}

const verifyPayment = (isVerified: boolean) => {
    router.post(route('orders.verify_payment', props.order.id), {
        is_verified: isVerified,
    }, {
        preserveScroll: true,
    })
}

const printInvoice = () => {
    window.print()
}
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
                            'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300': order.status === 'delivered',
                            'bg-blue-100 text-blue-800 dark:bg-blue-950/60 dark:text-blue-300': order.status === 'shipped',
                            'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300': order.status === 'processing',
                            'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300': order.status === 'cancelled',
                            'bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300': order.status === 'pending',
                        }">
                            {{ order.status }}
                        </span>

                        <span v-if="order.is_payment_verified" class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300 flex items-center gap-1">
                            <ShieldCheck class="w-3.5 h-3.5" />
                            <span>دفع مؤكد معتمد ✓</span>
                        </span>
                        <span v-else-if="order.payment_receipt_url" class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300 flex items-center gap-1">
                            <Clock class="w-3.5 h-3.5" />
                            <span>مرفق سكرين شوت (بانتظار الفحص)</span>
                        </span>
                    </div>
                    <p class="text-xs text-slate-500">
                        تاريخ الطلب: {{ new Date(order.created_at).toLocaleString('ar-EG') }}
                    </p>
                </div>

                <div class="flex items-center gap-3">
                    <button
                        @click="printInvoice"
                        class="px-4 py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 text-xs font-bold rounded-xl flex items-center gap-2 transition-colors"
                    >
                        <Printer class="w-4 h-4" />
                        طباعة الفاتورة
                    </button>
                    <Link
                        href="/orders"
                        class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition-colors"
                    >
                        العودة لقائمة الطلبات
                    </Link>
                </div>
            </div>

            <!-- Payment Proof Screenshot Verification Card (Admin Inspection) -->
            <div v-if="order.payment_receipt_url" class="p-6 rounded-3xl bg-white dark:bg-slate-900 border-2 border-indigo-200 dark:border-indigo-900 shadow-sm space-y-4">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="w-12 h-12 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800 overflow-hidden flex items-center justify-center shrink-0">
                            <img v-if="order.transfer_method?.logo_url" :src="order.transfer_method.logo_url" :alt="order.transfer_method.name" class="w-full h-full object-cover" />
                            <Image v-else class="w-6 h-6 text-indigo-600 dark:text-indigo-400" />
                        </div>
                        <div>
                            <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                                <span>إشعار وسكرين شوت التحويل:</span>
                                <span class="text-indigo-600 dark:text-indigo-400">{{ order.transfer_method_name || order.payment_method }}</span>
                            </h3>
                            <p class="text-xs text-slate-500">
                                الحساب المحول إليه: <strong>{{ order.transfer_method?.account_name || order.transfer_method?.name || order.payment_method }}</strong>
                            </p>
                        </div>
                    </div>

                    <div class="flex items-center gap-2">
                        <button
                            v-if="!order.is_payment_verified"
                            @click="verifyPayment(true)"
                            class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl shadow flex items-center gap-1.5 transition"
                        >
                            <Check class="w-4 h-4" />
                            <span>تأكيد سداد المبلغ واعتماد الدفع</span>
                        </button>
                        <button
                            v-else
                            @click="verifyPayment(false)"
                            class="px-3 py-1.5 bg-rose-50 text-rose-600 hover:bg-rose-100 text-xs font-bold rounded-xl transition"
                        >
                            <X class="w-4 h-4" />
                            <span>إلغاء الاعتماد</span>
                        </button>
                    </div>
                </div>

                <div class="flex items-center gap-4 pt-2">
                    <div 
                        @click="isPreviewOpen = true"
                        class="w-48 h-32 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-700 cursor-pointer relative group shadow-sm bg-slate-50"
                    >
                        <img :src="order.payment_receipt_url" alt="إشعار السداد" class="w-full h-full object-cover group-hover:scale-105 transition" />
                        <div class="absolute inset-0 bg-slate-900/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center text-white text-xs font-bold gap-1">
                            <Eye class="w-4 h-4" />
                            <span>تكبير الصورة</span>
                        </div>
                    </div>

                    <div class="space-y-1 text-xs text-slate-600 dark:text-slate-300">
                        <p class="font-bold text-slate-900 dark:text-white">إجراءات الفحص:</p>
                        <p>1. تأكد من مطابقة المبلغ المحول ({{ order.total_amount }} ₪) مع حساب المستفيد.</p>
                        <p>2. اضغط على "تأكيد سداد المبلغ" ليتحول الطلب إلى مدفوع (Paid) وترتبط الفاتورة بالدفعة.</p>
                    </div>
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
                        <p>
                            <strong class="text-slate-900 dark:text-white">نوع الاستلام:</strong>
                            <span v-if="order.delivery_type === 'pickup'" class="mr-1 font-bold text-indigo-600">
                                🏬 استلام شخصي من المعرض / المستودع الرئيسي
                            </span>
                            <span v-else class="mr-1 font-bold text-emerald-600">
                                🚚 توصيل إلى العنوان ({{ order.delivery_zone?.name || order.shipping_city || 'غزة' }})
                            </span>
                        </p>
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
                        <p><strong class="text-slate-900 dark:text-white">طريقة الدفع:</strong> {{ order.payment_method === 'cod' ? 'عند الاستلام (نقداً)' : (order.payment_method === 'bank_transfer' ? 'تحويل بنك فلسطين' : order.payment_method) }}</p>
                        <p>
                            <strong class="text-slate-900 dark:text-white">حالة السداد:</strong> 
                            <span :class="order.payment_status === 'paid' ? 'text-emerald-600 font-bold' : 'text-amber-600 font-bold'">
                                {{ order.payment_status === 'paid' ? 'مسدد بالكامل ✓' : 'غير مسدد ⏳' }}
                            </span>
                        </p>
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
                        <div v-if="order.cashback_discount && Number(order.cashback_discount) > 0" class="flex items-center justify-between text-amber-600 font-bold">
                            <span>خصم نقاط الولاء:</span>
                            <span>- {{ order.cashback_discount }} ₪</span>
                        </div>
                        <div class="flex items-center justify-between text-slate-500">
                            <span>الشحن والتوصيل:</span>
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

        <!-- Lightbox Modal for Fullscreen Screenshot Proof Preview -->
        <div v-if="isPreviewOpen" class="fixed inset-0 z-50 bg-slate-950/90 backdrop-blur-md flex items-center justify-center p-4">
            <div class="max-w-3xl max-h-[90vh] bg-slate-900 rounded-3xl overflow-hidden border border-slate-800 flex flex-col">
                <div class="p-4 flex items-center justify-between border-b border-slate-800 text-white text-xs font-bold">
                    <span>إشعار التحويل البنكي - طلب #{{ order.order_number }}</span>
                    <button @click="isPreviewOpen = false" class="p-1 text-slate-400 hover:text-white">
                        <X class="w-6 h-6" />
                    </button>
                </div>
                <div class="p-4 flex-1 overflow-auto flex items-center justify-center">
                    <img :src="order.payment_receipt_url" class="max-w-full max-h-[75vh] object-contain rounded-xl" />
                </div>
            </div>
        </div>
    </AppLayout>
</template>
