<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, useForm } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    ShieldCheck,
    Truck,
    CreditCard,
    Banknote,
    Building2,
    CheckCircle2,
    Lock,
    ArrowRight,
    LoaderCircle
} from 'lucide-vue-next';

interface CartItem {
    id: number;
    quantity: number;
    item?: {
        id: number;
        name: string;
        image?: string;
        effective_price: number;
    };
}

interface Props {
    cartItems: CartItem[];
    summary: {
        subtotal: number;
        shippingFee: number;
        total: number;
        itemsCount: number;
    };
    customer: {
        name: string;
        email: string;
        phone: string;
        address: string;
        city: string;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const form = useForm({
    name: props.customer.name || '',
    email: props.customer.email || '',
    phone: props.customer.phone || '',
    address: props.customer.address || '',
    city: props.customer.city || 'غزة',
    payment_method: 'cod', // cod, card, bank_transfer
    notes: '',
});

const submitOrder = () => {
    form.post(route('checkout.process'));
};
</script>

<template>
    <StoreLayout title="إتمام الطلب والدفع | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <div class="mb-8">
                <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">إتمام الطلب والشحن</h1>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                    أدخل بيانات التوصيل واختر طريقة الدفع لتأكيد طلبك وتوليد الفاتورة المحاسبية
                </p>
            </div>

            <form @submit.prevent="submitOrder" class="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <!-- Shipping and Payment Form -->
                <div class="lg:col-span-8 space-y-6">
                    <!-- Step 1: Customer Contact & Shipping Details -->
                    <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <div class="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
                            <div class="w-8 h-8 rounded-full bg-emerald-600 text-white font-bold flex items-center justify-center text-xs">
                                1
                            </div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">
                                بيانات المستلم وعنوان التوصيل
                            </h3>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">الاسم الكامل *</label>
                                <input
                                    type="text"
                                    v-model="form.name"
                                    required
                                    placeholder="مثال: أحمد محمد"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                />
                                <span v-if="form.errors.name" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.name }}</span>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">البريد الإلكتروني *</label>
                                <input
                                    type="email"
                                    v-model="form.email"
                                    required
                                    placeholder="example@domain.com"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                />
                                <span v-if="form.errors.email" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.email }}</span>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">رقم الهاتف / الجوال *</label>
                                <input
                                    type="tel"
                                    v-model="form.phone"
                                    required
                                    placeholder="0599000000"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                />
                                <span v-if="form.errors.phone" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.phone }}</span>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">المدينة / المحافظة *</label>
                                <select
                                    v-model="form.city"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-medium focus:ring-2 focus:ring-emerald-500"
                                >
                                    <option value="غزة">غزة</option>
                                    <option value="خان يونس">خان يونس</option>
                                    <option value="رفح">رفح</option>
                                    <option value="شمال غزة">شمال غزة</option>
                                    <option value="الوسطى / دير البلح">الوسطى / دير البلح</option>
                                    <option value="القدس">القدس</option>
                                    <option value="رام الله">رام الله</option>
                                    <option value="نابلس">نابلس</option>
                                    <option value="الخليل">الخليل</option>
                                </select>
                            </div>

                            <div class="sm:col-span-2">
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">العنوان التفصيلي (الشارع، الحي، أقرب معلم) *</label>
                                <textarea
                                    v-model="form.address"
                                    required
                                    rows="2"
                                    placeholder="الشارع الرئيسي، بجوار مسجد أو معلم بارز..."
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                ></textarea>
                                <span v-if="form.errors.address" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.address }}</span>
                            </div>

                            <div class="sm:col-span-2">
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">ملاحظات إضافية للتوصيل (اختياري)</label>
                                <input
                                    type="text"
                                    v-model="form.notes"
                                    placeholder="أوقات التوصيل المفضلة، تعليمات خاصة..."
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- Step 2: Payment Method -->
                    <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <div class="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
                            <div class="w-8 h-8 rounded-full bg-emerald-600 text-white font-bold flex items-center justify-center text-xs">
                                2
                            </div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">
                                اختيار طريقة الدفع
                            </h3>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            <!-- COD -->
                            <label
                                class="p-4 rounded-2xl border cursor-pointer transition-all flex flex-col justify-between space-y-3"
                                :class="form.payment_method === 'cod' ? 'border-emerald-500 bg-emerald-50/50 dark:bg-emerald-950/40 ring-2 ring-emerald-500' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <div class="flex items-center justify-between">
                                    <Banknote class="w-6 h-6 text-emerald-600" />
                                    <input type="radio" value="cod" v-model="form.payment_method" class="text-emerald-600" />
                                </div>
                                <div>
                                    <h4 class="text-xs font-bold text-slate-900 dark:text-white">الدفع عند الاستلام</h4>
                                    <p class="text-[11px] text-slate-500 mt-1">ادفع نقداً عند استلام طلبك لباب منزلك</p>
                                </div>
                            </label>

                            <!-- Card -->
                            <label
                                class="p-4 rounded-2xl border cursor-pointer transition-all flex flex-col justify-between space-y-3"
                                :class="form.payment_method === 'card' ? 'border-emerald-500 bg-emerald-50/50 dark:bg-emerald-950/40 ring-2 ring-emerald-500' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <div class="flex items-center justify-between">
                                    <CreditCard class="w-6 h-6 text-indigo-600" />
                                    <input type="radio" value="card" v-model="form.payment_method" class="text-emerald-600" />
                                </div>
                                <div>
                                    <h4 class="text-xs font-bold text-slate-900 dark:text-white">بطاقة ائتمانية</h4>
                                    <p class="text-[11px] text-slate-500 mt-1">فيزا / ماستركارد عبر بوابة آمنة</p>
                                </div>
                            </label>

                            <!-- Bank Transfer -->
                            <label
                                class="p-4 rounded-2xl border cursor-pointer transition-all flex flex-col justify-between space-y-3"
                                :class="form.payment_method === 'bank_transfer' ? 'border-emerald-500 bg-emerald-50/50 dark:bg-emerald-950/40 ring-2 ring-emerald-500' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <div class="flex items-center justify-between">
                                    <Building2 class="w-6 h-6 text-teal-600" />
                                    <input type="radio" value="bank_transfer" v-model="form.payment_method" class="text-emerald-600" />
                                </div>
                                <div>
                                    <h4 class="text-xs font-bold text-slate-900 dark:text-white">تحويل بنكي</h4>
                                    <p class="text-[11px] text-slate-500 mt-1">إيداع في حساب بنك فلسطين / الإسلامي</p>
                                </div>
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Order Review & Place Order Sidebar -->
                <div class="lg:col-span-4 space-y-6">
                    <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <h3 class="text-base font-black text-slate-900 dark:text-white pb-3 border-b border-slate-100 dark:border-slate-800">
                            مراجعة المنتجات والطلب
                        </h3>

                        <!-- Items Preview List -->
                        <div class="space-y-3 max-h-60 overflow-y-auto pr-1">
                            <div
                                v-for="item in cartItems"
                                :key="item.id"
                                class="flex items-center justify-between text-xs py-2 border-b border-slate-50 dark:border-slate-800/60"
                            >
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 overflow-hidden shrink-0">
                                        <img :src="item.item?.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200&auto=format&fit=crop&q=80'" :alt="item.item?.name" class="w-full h-full object-cover" />
                                    </div>
                                    <div>
                                        <h5 class="font-bold text-slate-900 dark:text-white line-clamp-1 max-w-[120px]">{{ item.item?.name }}</h5>
                                        <span class="text-[10px] text-slate-400">الكمية: {{ item.quantity }}</span>
                                    </div>
                                </div>
                                <span class="font-black text-slate-900 dark:text-white">
                                    {{ ((item.item?.effective_price || 0) * item.quantity).toFixed(2) }} ₪
                                </span>
                            </div>
                        </div>

                        <!-- Price Breakdown -->
                        <div class="space-y-2.5 text-xs pt-2">
                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>المجموع الفرعي:</span>
                                <span class="font-bold text-slate-900 dark:text-white">{{ summary.subtotal }} ₪</span>
                            </div>
                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>تكلفة الشحن:</span>
                                <span v-if="summary.shippingFee === 0" class="text-emerald-600 font-bold">مجاني</span>
                                <span v-else class="font-bold text-slate-900 dark:text-white">{{ summary.shippingFee }} ₪</span>
                            </div>
                            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-base">
                                <span class="font-black text-slate-900 dark:text-white">الإجمالي النهائي:</span>
                                <span class="font-black text-2xl text-emerald-600 dark:text-emerald-400">
                                    {{ summary.total }} ₪
                                </span>
                            </div>
                        </div>

                        <!-- Submit Button -->
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="w-full py-4 px-6 rounded-2xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-xl shadow-emerald-600/25 transition-all hover:scale-[1.02]"
                        >
                            <LoaderCircle v-if="form.processing" class="w-5 h-5 animate-spin" />
                            <Lock v-else class="w-4 h-4" />
                            <span>تأكيد الطلب وإصدار الفاتورة</span>
                        </button>
                    </div>

                    <div class="p-5 rounded-3xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 text-xs text-slate-500 dark:text-slate-400 space-y-2">
                        <div class="flex items-center gap-1.5 font-bold text-slate-700 dark:text-slate-300">
                            <ShieldCheck class="w-4 h-4 text-emerald-500" />
                            <span>ضمان المحاسبة والفوترة الآلية</span>
                        </div>
                        <p class="leading-relaxed">
                            بمجرد الضغط على تأكيد الطلب، سيتم تسجيل قيد المبيعات في نظام المحاسبة ERP وإنشاء الفاتورة وتجهيز الشحنة فوراً.
                        </p>
                    </div>
                </div>
            </form>
        </div>
    </StoreLayout>
</template>
