<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    ShoppingCart,
    Heart,
    Star,
    Sparkles,
    Truck,
    ShieldCheck,
    CheckCircle2,
    RotateCcw,
    Zap,
    Share2,
    ArrowRight,
    Package,
    FileText,
    Coins
} from 'lucide-vue-next';

interface Item {
    id: number;
    name: string;
    barcode?: string;
    image?: string;
    description?: string;
    unit?: string;
    sales_price: number;
    discount_price?: number;
    effective_price: number;
    total_stock: number;
    rating: number;
    reviews_count: number;
    category?: { id: number; name: string };
    is_deal?: boolean;
    is_featured?: boolean;
}

interface Props {
    item: Item;
    relatedItems: Item[];
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const quantity = ref(1);
const activeTab = ref<'description' | 'specs' | 'shipping'>('description');

const addToCart = (buyNow: boolean = false) => {
    router.post(route('cart.add'), {
        item_id: props.item.id,
        quantity: quantity.value
    }, {
        preserveScroll: true,
        onSuccess: () => {
            if (buyNow) {
                router.visit(route('checkout.index'));
            }
        }
    });
};

const toggleWishlist = () => {
    router.post(route('wishlist.toggle'), {
        item_id: props.item.id
    }, {
        preserveScroll: true
    });
};

const isWishlisted = () => {
    return props.storeContext?.wishlistIds?.includes(props.item.id) ?? false;
};
</script>

<template>
    <StoreLayout :title="item.name + ' | رنتيسي ستور'" :storeContext="storeContext">
        <!-- Breadcrumbs -->
        <div class="bg-white dark:bg-slate-900 border-b border-slate-200/80 dark:border-slate-800 py-4">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <nav class="flex items-center gap-2 text-xs text-slate-500">
                    <Link :href="route('home')" class="hover:text-emerald-600">الرئيسية</Link>
                    <span>/</span>
                    <Link :href="route('store.shop')" class="hover:text-emerald-600">المتجر</Link>
                    <span>/</span>
                    <Link v-if="item.category" :href="route('store.shop', { category_id: item.category.id })" class="hover:text-emerald-600">
                        {{ item.category.name }}
                    </Link>
                    <span v-if="item.category">/</span>
                    <span class="text-emerald-600 font-bold truncate max-w-xs">{{ item.name }}</span>
                </nav>
            </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Main Product Section -->
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 bg-white dark:bg-slate-900 rounded-3xl p-6 sm:p-10 border border-slate-200/80 dark:border-slate-800 shadow-sm">
                <!-- Gallery Image -->
                <div class="lg:col-span-6 space-y-4">
                    <div class="h-96 sm:h-[450px] rounded-3xl bg-slate-100 dark:bg-slate-800 overflow-hidden relative border border-slate-200/60 dark:border-slate-700">
                        <img
                            :src="item.image || 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80'"
                            :alt="item.name"
                            class="w-full h-full object-cover"
                        />
                        <span
                            v-if="item.discount_price && item.discount_price < item.sales_price"
                            class="absolute top-4 right-4 px-3 py-1.5 rounded-full bg-rose-600 text-white text-xs font-black shadow-lg"
                        >
                            خصم {{ Math.round(((item.sales_price - item.discount_price) / item.sales_price) * 100) }}%
                        </span>
                    </div>
                </div>

                <!-- Product Details -->
                <div class="lg:col-span-6 space-y-6 text-right">
                    <div class="space-y-2">
                        <div class="flex items-center justify-between">
                            <span class="text-xs font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-3 py-1 rounded-lg">
                                {{ item.category?.name || 'تصنيف عام' }}
                            </span>
                            <span v-if="item.barcode" class="text-xs font-mono text-slate-400">
                                باركود: {{ item.barcode }}
                            </span>
                        </div>

                        <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white leading-tight">
                            {{ item.name }}
                        </h1>

                        <!-- Ratings -->
                        <div class="flex items-center gap-2 text-amber-400 text-sm">
                            <div class="flex items-center">
                                <Star v-for="i in 5" :key="i" class="w-4 h-4 fill-amber-400" />
                            </div>
                            <span class="font-bold text-slate-700 dark:text-slate-300 mr-1">{{ item.rating || 5.0 }}</span>
                            <span class="text-slate-400 text-xs">({{ item.reviews_count || 18 }} تقييم الزبائن)</span>
                        </div>
                    </div>

                    <!-- Price -->
                    <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 flex items-center justify-between">
                        <div>
                            <div class="text-3xl font-black text-emerald-600 dark:text-emerald-400">
                                {{ item.effective_price }} ₪
                            </div>
                            <div v-if="item.discount_price && item.discount_price < item.sales_price" class="text-sm text-slate-400 line-through mt-0.5">
                                {{ item.sales_price }} ₪
                            </div>
                        </div>

                        <div class="text-left">
                            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold" :class="item.total_stock > 0 ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/80 dark:text-emerald-300' : 'bg-amber-100 text-amber-700'">
                                <CheckCircle2 class="w-3.5 h-3.5" />
                                {{ item.total_stock > 0 ? `متوفر بالمستودع (${item.total_stock} ${item.unit || 'قطعة'})` : 'متوفر للطلب الفوري' }}
                            </span>
                        </div>
                    </div>

                    <!-- Short description -->
                    <p class="text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                        {{ item.description || 'منتج أصلي عالي الجودة معتمد ومطابق لأعلى معايير الأداء، مدرج تلقائياً في دورة المبيعات ونظام الفوترة الإلكترونية.' }}
                    </p>

                    <!-- Purchase Actions -->
                    <div class="space-y-4 pt-2">
                        <div class="flex items-center gap-4">
                            <!-- Quantity selector -->
                            <div class="flex items-center border border-slate-300 dark:border-slate-700 rounded-2xl overflow-hidden bg-slate-50 dark:bg-slate-800 shrink-0">
                                <button
                                    @click="quantity = Math.max(1, quantity - 1)"
                                    class="px-4 py-3 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 font-bold"
                                >
                                    -
                                </button>
                                <span class="px-4 py-3 text-sm font-bold text-slate-900 dark:text-white">{{ quantity }}</span>
                                <button
                                    @click="quantity += 1"
                                    class="px-4 py-3 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 font-bold"
                                >
                                    +
                                </button>
                            </div>

                            <!-- Add to Cart -->
                            <button
                                @click="addToCart(false)"
                                class="flex-1 py-3.5 px-6 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-xl shadow-emerald-600/25 transition-all hover:scale-[1.02]"
                            >
                                <ShoppingCart class="w-5 h-5" />
                                <span>إضافة إلى السلة</span>
                            </button>

                            <!-- Wishlist -->
                            <button
                                @click="toggleWishlist"
                                class="p-3.5 rounded-2xl border border-slate-200 dark:border-slate-700 hover:border-rose-500 text-slate-700 dark:text-slate-300 transition-colors"
                                :title="isWishlisted() ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'"
                            >
                                <Heart class="w-5 h-5" :class="{ 'fill-rose-500 text-rose-500': isWishlisted() }" />
                            </button>
                        </div>

                        <!-- Direct Buy Now -->
                        <button
                            @click="addToCart(true)"
                            class="w-full py-3.5 px-6 rounded-2xl bg-slate-900 dark:bg-slate-800 hover:bg-emerald-600 text-white font-bold text-sm transition-all shadow-md flex items-center justify-center gap-2"
                        >
                            <Zap class="w-4 h-4 text-amber-400" />
                            <span>شراء فوري وإتمام الطلب</span>
                        </button>

                        <!-- Instant Quotation PDF -->
                        <Link
                            :href="route('store.quotation.product', item.id)"
                            :data="{ quantity }"
                            method="post"
                            as="button"
                            class="w-full py-2.5 px-4 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 font-bold text-xs flex items-center justify-center gap-2 transition"
                        >
                            <FileText class="w-4 h-4 text-indigo-500" />
                            <span>طلب عرض سعر رسمي معتمد (PDF) لهذا المنتج</span>
                        </Link>

                        <!-- Cashback Reward Incentive Badge -->
                        <div class="p-2.5 bg-amber-50 dark:bg-amber-950/30 border border-amber-200/60 dark:border-amber-900/40 rounded-xl text-center">
                            <span class="text-xs font-bold text-amber-700 dark:text-amber-300 flex items-center justify-center gap-1.5">
                                <Coins class="w-4 h-4 text-amber-500" />
                                ستحصل على {{ Math.floor(item.effective_price / 10) * quantity }} نقطة كاش باك عند شراء هذا المنتج!
                            </span>
                        </div>
                    </div>

                    <!-- Trust checklist -->
                    <div class="pt-6 border-t border-slate-100 dark:border-slate-800 grid grid-cols-2 gap-3 text-xs text-slate-500 dark:text-slate-400">
                        <div class="flex items-center gap-2">
                            <Truck class="w-4 h-4 text-emerald-500" />
                            <span>شحن مجاني فوق 200 ₪</span>
                        </div>
                        <div class="flex items-center gap-2">
                            <ShieldCheck class="w-4 h-4 text-emerald-500" />
                            <span>ضمان الجودة والأصالة</span>
                        </div>
                        <div class="flex items-center gap-2">
                            <Sparkles class="w-4 h-4 text-emerald-500" />
                            <span>فاتورة إلكترونية معتمدة</span>
                        </div>
                        <div class="flex items-center gap-2">
                            <RotateCcw class="w-4 h-4 text-emerald-500" />
                            <span>إرجاع سهل خلال 14 يوم</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs Section -->
            <div class="mt-12 bg-white dark:bg-slate-900 rounded-3xl p-6 sm:p-10 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                <div class="flex items-center gap-4 border-b border-slate-100 dark:border-slate-800 pb-4">
                    <button
                        @click="activeTab = 'description'"
                        class="px-4 py-2 rounded-xl text-xs font-bold transition-all"
                        :class="activeTab === 'description' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                        وصف المنتج
                    </button>
                    <button
                        @click="activeTab = 'specs'"
                        class="px-4 py-2 rounded-xl text-xs font-bold transition-all"
                        :class="activeTab === 'specs' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                        المواصفات الفنية
                    </button>
                    <button
                        @click="activeTab = 'shipping'"
                        class="px-4 py-2 rounded-xl text-xs font-bold transition-all"
                        :class="activeTab === 'shipping' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'"
                    >
                        الشحن والتسليم
                    </button>
                </div>

                <div v-if="activeTab === 'description'" class="text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed space-y-3">
                    <p>{{ item.description || 'تم تصميم هذا المنتج بعناية فائقة ليوفر لك أفضل تجربة استخدام. يتميز بالجودة العالية والمتانة لضمان رضاك التام.' }}</p>
                    <p>المنتج مسجل رسمياً في قاعدة بيانات المحاسبة، ويتم توليد فاتورة مبيعات فورية عند إتمام عملية الشراء، مما يضمن حفظ حقوقك بالكامل وتوثيق الحساب.</p>
                </div>

                <div v-else-if="activeTab === 'specs'" class="text-xs sm:text-sm">
                    <table class="w-full text-right border-collapse">
                        <tbody>
                            <tr class="border-b border-slate-100 dark:border-slate-800">
                                <td class="py-2.5 font-bold text-slate-700 dark:text-slate-300 w-1/3">الباركود / الرقم المرجعي:</td>
                                <td class="py-2.5 text-slate-600 dark:text-slate-400 font-mono">{{ item.barcode || 'N/A' }}</td>
                            </tr>
                            <tr class="border-b border-slate-100 dark:border-slate-800">
                                <td class="py-2.5 font-bold text-slate-700 dark:text-slate-300">وحدة القياس:</td>
                                <td class="py-2.5 text-slate-600 dark:text-slate-400">{{ item.unit || 'قطعة' }}</td>
                            </tr>
                            <tr class="border-b border-slate-100 dark:border-slate-800">
                                <td class="py-2.5 font-bold text-slate-700 dark:text-slate-300">التصنيف:</td>
                                <td class="py-2.5 text-slate-600 dark:text-slate-400">{{ item.category?.name || 'عام' }}</td>
                            </tr>
                            <tr>
                                <td class="py-2.5 font-bold text-slate-700 dark:text-slate-300">حالة المستودع:</td>
                                <td class="py-2.5 text-emerald-600 font-semibold">متوفر في المستودعات الرئيسية</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div v-else-if="activeTab === 'shipping'" class="text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed space-y-3">
                    <p>يتم توصيل الطلبات خلال 24 إلى 48 ساعة من تاريخ تأكيد الطلب.</p>
                    <p>الشحن مجاني لجميع الطلبات التي تزيد قيمتها عن 200 شيكل، ورسوم الشحن القياسية هي 20 شيكل للطلبات الأخرى.</p>
                </div>
            </div>

            <!-- Related Products -->
            <div v-if="relatedItems && relatedItems.length > 0" class="mt-16 space-y-6">
                <div class="flex items-center justify-between">
                    <h3 class="text-xl font-black text-slate-900 dark:text-white">منتجات ذات صلة قد تعجبك</h3>
                    <Link :href="route('store.shop', { category_id: item.category?.id })" class="text-xs font-bold text-emerald-600 hover:underline">
                        عرض المزيد من هذا القسم
                    </Link>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
                    <div
                        v-for="rel in relatedItems"
                        :key="rel.id"
                        class="rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 p-4 space-y-3 hover:shadow-lg transition-all"
                    >
                        <div class="h-44 rounded-2xl bg-slate-100 dark:bg-slate-800 overflow-hidden">
                            <img :src="rel.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'" :alt="rel.name" class="w-full h-full object-cover" />
                        </div>
                        <div>
                            <Link :href="route('store.product', rel.id)">
                                <h4 class="text-xs font-bold text-slate-900 dark:text-white hover:text-emerald-600 line-clamp-1">{{ rel.name }}</h4>
                            </Link>
                            <div class="text-sm font-black text-emerald-600 mt-1">{{ rel.effective_price }} ₪</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
