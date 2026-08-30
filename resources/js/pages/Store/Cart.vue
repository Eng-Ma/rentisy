<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    ShoppingCart,
    Trash2,
    ArrowLeft,
    ArrowRight,
    ShieldCheck,
    Truck,
    Tag,
    ShoppingBag
} from 'lucide-vue-next';

interface CartItem {
    id: number;
    quantity: number;
    item?: {
        id: number;
        name: string;
        image?: string;
        sales_price: number;
        discount_price?: number;
        effective_price: number;
        category?: { id: number; name: string };
    };
}

interface Props {
    cartItems: CartItem[];
    summary: {
        subtotal: number;
        shippingFee: number;
        tax: number;
        total: number;
        itemsCount: number;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const couponCode = ref('');
const couponDiscount = ref(0);
const couponApplied = ref(false);

const updateQuantity = (cartItemId: number, newQty: number) => {
    if (newQty < 1) return;
    router.post(route('cart.update', cartItemId), {
        quantity: newQty
    }, {
        preserveScroll: true
    });
};

const removeItem = (cartItemId: number) => {
    router.delete(route('cart.remove', cartItemId), {
        preserveScroll: true
    });
};

const clearCart = () => {
    router.post(route('cart.clear'), {}, {
        preserveScroll: true
    });
};

const applyCoupon = () => {
    if (couponCode.value.trim().toUpperCase() === 'RENTISY10' || couponCode.value.trim().toUpperCase() === 'DISCOUNT') {
        couponDiscount.value = props.summary.subtotal * 0.1;
        couponApplied.value = true;
    } else {
        alert('كود الخصم غير صحيح. جرب كود RENTISY10');
    }
};
</script>

<template>
    <StoreLayout title="سلة المشتريات | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">سلة المشتريات</h1>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        لديك {{ summary.itemsCount }} منتج في سلة التسوق
                    </p>
                </div>

                <button
                    v-if="cartItems.length > 0"
                    @click="clearCart"
                    class="text-xs font-semibold text-rose-500 hover:underline flex items-center gap-1"
                >
                    <Trash2 class="w-3.5 h-3.5" />
                    تفريغ السلة بالكامل
                </button>
            </div>

            <!-- If Cart has items -->
            <div v-if="cartItems.length > 0" class="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <!-- Cart Items Table / List -->
                <div class="lg:col-span-8 space-y-4">
                    <div
                        v-for="cartItem in cartItems"
                        :key="cartItem.id"
                        class="p-5 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex flex-col sm:flex-row items-center gap-5 justify-between"
                    >
                        <div class="flex items-center gap-4 w-full sm:w-auto">
                            <div class="w-20 h-20 rounded-2xl bg-slate-100 dark:bg-slate-800 overflow-hidden shrink-0">
                                <img
                                    :src="cartItem.item?.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                                    :alt="cartItem.item?.name"
                                    class="w-full h-full object-cover"
                                />
                            </div>

                            <div class="space-y-1 text-right">
                                <span class="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md">
                                    {{ cartItem.item?.category?.name || 'عام' }}
                                </span>
                                <Link
                                    v-if="cartItem.item"
                                    :href="route('store.product', cartItem.item.id)"
                                    class="block text-sm font-bold text-slate-900 dark:text-white hover:text-emerald-600 line-clamp-1"
                                >
                                    {{ cartItem.item.name }}
                                </Link>
                                <div class="text-xs font-semibold text-slate-500">
                                    سعر القطعة: {{ cartItem.item?.effective_price }} ₪
                                </div>
                            </div>
                        </div>

                        <!-- Quantity and Line Total -->
                        <div class="flex items-center justify-between sm:justify-end gap-6 w-full sm:w-auto pt-3 sm:pt-0 border-t sm:border-t-0 border-slate-100 dark:border-slate-800">
                            <!-- Stepper -->
                            <div class="flex items-center border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden bg-slate-50 dark:bg-slate-800">
                                <button
                                    @click="updateQuantity(cartItem.id, cartItem.quantity - 1)"
                                    class="px-3 py-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 font-bold text-xs"
                                >
                                    -
                                </button>
                                <span class="px-3 py-1.5 text-xs font-bold text-slate-900 dark:text-white">{{ cartItem.quantity }}</span>
                                <button
                                    @click="updateQuantity(cartItem.id, cartItem.quantity + 1)"
                                    class="px-3 py-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 font-bold text-xs"
                                >
                                    +
                                </button>
                            </div>

                            <div class="text-right">
                                <span class="text-xs text-slate-400 block sm:hidden">المجموع:</span>
                                <div class="text-base font-black text-emerald-600 dark:text-emerald-400">
                                    {{ ((cartItem.item?.effective_price || 0) * cartItem.quantity).toFixed(2) }} ₪
                                </div>
                            </div>

                            <button
                                @click="removeItem(cartItem.id)"
                                class="p-2 rounded-xl text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-colors"
                                title="حذف من السلة"
                            >
                                <Trash2 class="w-4 h-4" />
                            </button>
                        </div>
                    </div>

                    <!-- Coupon Code Card -->
                    <div class="p-5 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
                        <div class="flex items-center gap-2 text-xs font-bold text-slate-700 dark:text-slate-300 w-full sm:w-auto">
                            <Tag class="w-4 h-4 text-emerald-600" />
                            <span>هل لديك كود خصم أو قسيمة شراء؟</span>
                        </div>

                        <div class="flex items-center gap-2 w-full sm:w-auto">
                            <input
                                type="text"
                                v-model="couponCode"
                                placeholder="أدخل كود الخصم (مثال RENTISY10)"
                                class="px-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 uppercase"
                            />
                            <button
                                @click="applyCoupon"
                                class="px-4 py-2 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-emerald-600 text-white text-xs font-bold transition-colors"
                            >
                                تطبيق
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Order Summary Sidebar -->
                <div class="lg:col-span-4 space-y-6">
                    <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <h3 class="text-base font-black text-slate-900 dark:text-white pb-3 border-b border-slate-100 dark:border-slate-800">
                            ملخص الطلب والفاتورة
                        </h3>

                        <div class="space-y-3 text-xs">
                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>المجموع الفرعي ({{ summary.itemsCount }} قطع):</span>
                                <span class="font-bold text-slate-900 dark:text-white">{{ summary.subtotal }} ₪</span>
                            </div>

                            <div v-if="couponApplied" class="flex items-center justify-between text-emerald-600 font-bold">
                                <span>خصم الكود (10%):</span>
                                <span>- {{ couponDiscount.toFixed(2) }} ₪</span>
                            </div>

                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>تكلفة الشحن والتوصيل:</span>
                                <span v-if="summary.shippingFee === 0" class="text-emerald-600 font-bold">مجاني</span>
                                <span v-else class="font-bold text-slate-900 dark:text-white">{{ summary.shippingFee }} ₪</span>
                            </div>

                            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-base">
                                <span class="font-black text-slate-900 dark:text-white">المجموع الكلي:</span>
                                <span class="font-black text-2xl text-emerald-600 dark:text-emerald-400">
                                    {{ (summary.total - couponDiscount).toFixed(2) }} ₪
                                </span>
                            </div>
                        </div>

                        <!-- Checkout CTA -->
                        <Link
                            :href="route('checkout.index')"
                            class="w-full py-4 px-6 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-xl shadow-emerald-600/25 transition-all hover:scale-[1.02]"
                        >
                            <span>متابعة إتمام الطلب</span>
                            <ArrowLeft class="w-4 h-4" />
                        </Link>

                        <div class="pt-3 text-center">
                            <Link :href="route('store.shop')" class="text-xs text-slate-500 hover:text-emerald-600 font-medium">
                                ← متابعة التسوق وإضافة منتجات أخرى
                            </Link>
                        </div>
                    </div>

                    <!-- Safety Guarantee -->
                    <div class="p-5 rounded-3xl bg-emerald-50/50 dark:bg-emerald-950/20 border border-emerald-100 dark:border-emerald-900/40 text-xs space-y-2 text-slate-600 dark:text-slate-400">
                        <div class="flex items-center gap-2 font-bold text-emerald-700 dark:text-emerald-300">
                            <ShieldCheck class="w-4 h-4" />
                            <span>تسوق موثوق ومحمي بالكامل</span>
                        </div>
                        <p class="leading-relaxed">
                            يتم إرسال الفاتورة المحاسبية المعتمدة فور إتمام الطلب وتسجيلها مباشرة بحسابك.
                        </p>
                    </div>
                </div>
            </div>

            <!-- Empty Cart State -->
            <div v-else class="p-16 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 space-y-6 max-w-xl mx-auto shadow-sm">
                <div class="w-20 h-20 rounded-3xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center mx-auto shadow-inner">
                    <ShoppingCart class="w-10 h-10" />
                </div>
                <div class="space-y-2">
                    <h3 class="text-xl font-black text-slate-900 dark:text-white">سلة التسوق فارغة حالياً</h3>
                    <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                        لم تقم بإضافة أي منتجات إلى سلتك بعد. استكشف كتالوج المنتجات واختر ما يناسبك.
                    </p>
                </div>
                <Link
                    :href="route('store.shop')"
                    class="inline-flex items-center gap-2 px-8 py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-lg shadow-emerald-600/25 transition-all"
                >
                    <ShoppingBag class="w-4 h-4" />
                    <span>تصفح المنتجات الآن</span>
                </Link>
            </div>
        </div>
    </StoreLayout>
</template>
