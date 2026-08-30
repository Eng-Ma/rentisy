<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    ShoppingBag,
    ShoppingCart,
    Heart,
    Star,
    Sparkles,
    ArrowLeft,
    CheckCircle2,
    Truck,
    ShieldCheck,
    Clock,
    Zap,
    Tag,
    Eye,
    X,
    Laptop,
    Smartphone,
    Layers,
    Tv,
    Headphones,
    Plus
} from 'lucide-vue-next';

interface Item {
    id: number;
    name: string;
    barcode?: string;
    image?: string;
    description?: string;
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

interface Category {
    id: number;
    name: string;
    description?: string;
    items_count?: number;
}

interface Props {
    categories: Category[];
    featuredItems: Item[];
    dealItems: Item[];
    newArrivals: Item[];
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

// Quick View Modal
const selectedItem = ref<Item | null>(null);
const quickViewQty = ref(1);
const isQuickViewOpen = ref(false);

const openQuickView = (item: Item) => {
    selectedItem.value = item;
    quickViewQty.value = 1;
    isQuickViewOpen.value = true;
};

const closeQuickView = () => {
    isQuickViewOpen.value = false;
    selectedItem.value = null;
};

const addToCart = (item: Item, qty: number = 1) => {
    router.post(route('cart.add'), {
        item_id: item.id,
        quantity: qty
    }, {
        preserveScroll: true,
        onSuccess: () => {
            if (isQuickViewOpen.value) {
                closeQuickView();
            }
        }
    });
};

const toggleWishlist = (itemId: number) => {
    router.post(route('wishlist.toggle'), {
        item_id: itemId
    }, {
        preserveScroll: true
    });
};

const isWishlisted = (itemId: number) => {
    return props.storeContext?.wishlistIds?.includes(itemId) ?? false;
};

const getCategoryIcon = (index: number) => {
    const icons = [Laptop, Smartphone, Tv, Headphones, Layers, ShoppingBag];
    return icons[index % icons.length];
};
</script>

<template>
    <StoreLayout title="رنتيسي ستور | الصفحة الرئيسية للمتجر الإلكتروني" :storeContext="storeContext">
        <!-- Hero Section -->
        <section class="relative overflow-hidden bg-gradient-to-br from-slate-900 via-emerald-950 to-slate-900 text-white py-16 md:py-24">
            <!-- Glow elements -->
            <div class="absolute -top-24 -left-24 w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-24 -right-24 w-96 h-96 bg-teal-500/15 rounded-full blur-3xl pointer-events-none"></div>

            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                    <div class="lg:col-span-7 space-y-6 text-right">
                        <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold tracking-wide">
                            <Sparkles class="w-4 h-4 text-emerald-400" />
                            <span>موسم التخفيضات الكبرى | عروض حصرية</span>
                        </div>

                        <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black leading-tight tracking-tight text-white">
                            أفضل المنتجات الأصلية <br />
                            <span class="bg-gradient-to-r from-emerald-400 via-teal-300 to-cyan-300 bg-clip-text text-transparent">
                                وفواتير فورية مدمجة بالـ ERP
                            </span>
                        </h1>

                        <p class="text-slate-300 text-sm sm:text-base leading-relaxed max-w-xl font-normal">
                            اكتشف تشكيلة واسعة من أحدث الأجهزة الإلكترونية والمستلزمات مع تجربة تسوق آمنة وسريعة، وربط تلقائي بحسابك المحاسبي مع إمكانية الدفع عند الاستلام.
                        </p>

                        <div class="flex flex-wrap items-center gap-4 pt-4">
                            <Link
                                :href="route('store.shop')"
                                class="px-8 py-4 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-bold text-sm shadow-xl shadow-emerald-500/25 hover:shadow-emerald-500/40 hover:-translate-y-0.5 transition-all flex items-center gap-2"
                            >
                                <ShoppingBag class="w-5 h-5" />
                                <span>ابدأ التسوق الآن</span>
                            </Link>

                            <Link
                                :href="route('store.shop', { deals_only: 1 })"
                                class="px-7 py-4 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 text-white font-bold text-sm backdrop-blur-sm transition-all flex items-center gap-2"
                            >
                                <Tag class="w-4 h-4 text-amber-400" />
                                <span>عروض اليوم الخاصة</span>
                            </Link>
                        </div>

                        <!-- Mini Badges -->
                        <div class="pt-6 grid grid-cols-3 gap-4 border-t border-slate-800/80 max-w-lg text-slate-300 text-xs">
                            <div class="flex items-center gap-2">
                                <CheckCircle2 class="w-4 h-4 text-emerald-400 shrink-0" />
                                <span>أصلي ومضمون 100%</span>
                            </div>
                            <div class="flex items-center gap-2">
                                <Truck class="w-4 h-4 text-emerald-400 shrink-0" />
                                <span>توصيل سريع لباب بيتك</span>
                            </div>
                            <div class="flex items-center gap-2">
                                <ShieldCheck class="w-4 h-4 text-emerald-400 shrink-0" />
                                <span>دفع آمن بالكامل</span>
                            </div>
                        </div>
                    </div>

                    <!-- Hero Visual Card -->
                    <div class="lg:col-span-5 relative">
                        <div class="relative mx-auto max-w-md rounded-3xl p-6 bg-gradient-to-b from-white/10 to-white/5 border border-white/20 backdrop-blur-xl shadow-2xl space-y-6">
                            <div class="flex items-center justify-between">
                                <span class="px-3 py-1 rounded-full bg-rose-500/90 text-white text-[11px] font-extrabold flex items-center gap-1">
                                    <Zap class="w-3 h-3" /> خصم 30%
                                </span>
                                <span class="text-xs font-semibold text-emerald-400">الأكثر مبيعاً هذا الأسبوع</span>
                            </div>

                            <div class="h-60 rounded-2xl bg-gradient-to-tr from-slate-800 to-slate-700/60 overflow-hidden flex items-center justify-center relative group">
                                <img
                                    src="https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&auto=format&fit=crop&q=80"
                                    alt="Hero Product"
                                    class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                />
                                <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
                                <div class="absolute bottom-4 right-4 left-4 text-right">
                                    <h3 class="text-base font-bold text-white">سماعات رأس لاسلكية فائقة النقاء Pro</h3>
                                    <div class="flex items-center justify-between mt-1">
                                        <div class="flex items-center gap-2">
                                            <span class="text-lg font-black text-emerald-400">320.00 ₪</span>
                                            <span class="text-xs text-slate-400 line-through">450.00 ₪</span>
                                        </div>
                                        <div class="flex items-center text-amber-400 text-xs">
                                            <Star class="w-3.5 h-3.5 fill-amber-400" />
                                            <span class="font-bold mr-1">4.9</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="flex items-center justify-between pt-2">
                                <div class="text-right">
                                    <span class="text-[11px] text-slate-400 block">التوفر في المستودع:</span>
                                    <span class="text-xs font-bold text-emerald-400">متوفر وجاهز للشحن الفوري</span>
                                </div>
                                <Link
                                    :href="route('store.shop')"
                                    class="px-4 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs flex items-center gap-1.5 transition-colors"
                                >
                                    <span>تصفح الكتالوج</span>
                                    <ArrowLeft class="w-3.5 h-3.5" />
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Value Propositions Grid -->
        <section class="py-10 bg-white dark:bg-slate-900 border-b border-slate-100 dark:border-slate-800">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                    <div class="flex items-start gap-4 p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 hover:border-emerald-500/40 transition-colors">
                        <div class="w-12 h-12 rounded-xl bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
                            <Truck class="w-6 h-6" />
                        </div>
                        <div>
                            <h4 class="text-sm font-bold text-slate-900 dark:text-white">شحن سريع ومجاني</h4>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">توصيل مجاني للطلبات أكثر من 200 ₪ في غضون 24-48 ساعة.</p>
                        </div>
                    </div>

                    <div class="flex items-start gap-4 p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 hover:border-emerald-500/40 transition-colors">
                        <div class="w-12 h-12 rounded-xl bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center shrink-0">
                            <ShieldCheck class="w-6 h-6" />
                        </div>
                        <div>
                            <h4 class="text-sm font-bold text-slate-900 dark:text-white">دفع آمن ومتعدد</h4>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">خيارات دفع مرنة: عند الاستلام، بطاقات ائتمان، أو تحويل بنكي.</p>
                        </div>
                    </div>

                    <div class="flex items-start gap-4 p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 hover:border-emerald-500/40 transition-colors">
                        <div class="w-12 h-12 rounded-xl bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0">
                            <Sparkles class="w-6 h-6" />
                        </div>
                        <div>
                            <h4 class="text-sm font-bold text-slate-900 dark:text-white">ربط محاسبي فوري</h4>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">إصدار فاتورة إلكترونية معتمدة وإضافتها لكشف حسابك المحاسبي.</p>
                        </div>
                    </div>

                    <div class="flex items-start gap-4 p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 hover:border-emerald-500/40 transition-colors">
                        <div class="w-12 h-12 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                            <Clock class="w-6 h-6" />
                        </div>
                        <div>
                            <h4 class="text-sm font-bold text-slate-900 dark:text-white">دعم فني 24/7</h4>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">فريق خدمة العملاء متواجد دائماً لمساعدتك في أي استفسار.</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Categories Showcase -->
        <section class="py-14 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h2 class="text-2xl font-black text-slate-900 dark:text-white">تسوق حسب التصنيف</h2>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">تصفح أقسام المتجر واكتشف تشكيلاتنا المتنوعة</p>
                </div>
                <Link
                    :href="route('store.shop')"
                    class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline flex items-center gap-1"
                >
                    <span>عرض الكل</span>
                    <ArrowLeft class="w-4 h-4" />
                </Link>
            </div>

            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
                <Link
                    v-for="(cat, idx) in categories"
                    :key="cat.id"
                    :href="route('store.shop', { category_id: cat.id })"
                    class="group p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 hover:shadow-lg hover:shadow-emerald-500/10 transition-all text-center flex flex-col items-center justify-center"
                >
                    <div class="w-14 h-14 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center group-hover:scale-110 group-hover:bg-emerald-600 group-hover:text-white transition-all mb-3">
                        <component :is="getCategoryIcon(idx)" class="w-7 h-7" />
                    </div>
                    <h3 class="text-xs font-bold text-slate-900 dark:text-white group-hover:text-emerald-600 transition-colors line-clamp-1">
                        {{ cat.name }}
                    </h3>
                    <span class="text-[11px] text-slate-400 mt-1">
                        {{ cat.items_count ?? 0 }} منتج
                    </span>
                </Link>
            </div>
        </section>

        <!-- Flash Deals of the Day -->
        <section v-if="dealItems && dealItems.length > 0" class="py-14 bg-gradient-to-b from-slate-100/70 to-white dark:from-slate-900/60 dark:to-slate-950">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-rose-500 text-white flex items-center justify-center shadow-lg shadow-rose-500/30">
                            <Zap class="w-6 h-6 animate-bounce" />
                        </div>
                        <div>
                            <h2 class="text-2xl font-black text-slate-900 dark:text-white">عروض وتخفيضات اليوم المحدودة</h2>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">أسعار استثنائية على أصناف مختارة حتى نفاد الكمية</p>
                        </div>
                    </div>

                    <div class="flex items-center gap-2">
                        <span class="text-xs font-bold text-slate-600 dark:text-slate-300">ينتهي العرض خلال:</span>
                        <div class="flex items-center gap-1.5 text-xs font-mono font-bold">
                            <span class="px-2.5 py-1 rounded-lg bg-rose-600 text-white">14</span> :
                            <span class="px-2.5 py-1 rounded-lg bg-rose-600 text-white">45</span> :
                            <span class="px-2.5 py-1 rounded-lg bg-rose-600 text-white">20</span>
                        </div>
                    </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    <div
                        v-for="item in dealItems"
                        :key="item.id"
                        class="group rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-xl transition-all overflow-hidden flex flex-col"
                    >
                        <!-- Image Container -->
                        <div class="relative h-56 bg-slate-100 dark:bg-slate-800 overflow-hidden">
                            <img
                                :src="item.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                                :alt="item.name"
                                class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                            />

                            <!-- Discount Badge -->
                            <span
                                v-if="item.discount_price && item.discount_price < item.sales_price"
                                class="absolute top-3 right-3 px-2.5 py-1 rounded-full bg-rose-600 text-white text-[10px] font-extrabold shadow-sm"
                            >
                                خصم {{ Math.round(((item.sales_price - item.discount_price) / item.sales_price) * 100) }}%
                            </span>

                            <!-- Wishlist & Quick View Buttons -->
                            <div class="absolute top-3 left-3 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button
                                    @click="toggleWishlist(item.id)"
                                    class="w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200 hover:text-rose-600 flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                                    :title="isWishlisted(item.id) ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'"
                                >
                                    <Heart class="w-4 h-4" :class="{ 'fill-rose-500 text-rose-500': isWishlisted(item.id) }" />
                                </button>
                                <button
                                    @click="openQuickView(item)"
                                    class="w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200 hover:text-emerald-600 flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                                    title="معاينة سريعة"
                                >
                                    <Eye class="w-4 h-4" />
                                </button>
                            </div>
                        </div>

                        <!-- Info Content -->
                        <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
                            <div>
                                <span class="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md">
                                    {{ item.category?.name || 'منتج عام' }}
                                </span>

                                <Link :href="route('store.product', item.id)" class="block mt-2">
                                    <h3 class="text-sm font-bold text-slate-900 dark:text-white hover:text-emerald-600 transition-colors line-clamp-2">
                                        {{ item.name }}
                                    </h3>
                                </Link>

                                <div class="flex items-center gap-1.5 mt-2 text-amber-400 text-xs">
                                    <Star class="w-3.5 h-3.5 fill-amber-400" />
                                    <span class="font-bold text-slate-700 dark:text-slate-300">{{ item.rating || 5.0 }}</span>
                                    <span class="text-slate-400 text-[10px]">({{ item.reviews_count || 12 }} تقييم)</span>
                                </div>
                            </div>

                            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
                                <div>
                                    <div class="text-base font-black text-emerald-600 dark:text-emerald-400">
                                        {{ item.effective_price }} ₪
                                    </div>
                                    <div v-if="item.discount_price && item.discount_price < item.sales_price" class="text-xs text-slate-400 line-through">
                                        {{ item.sales_price }} ₪
                                    </div>
                                </div>

                                <button
                                    @click="addToCart(item, 1)"
                                    class="p-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white transition-colors shadow-md shadow-emerald-600/20"
                                    title="أضف إلى السلة"
                                >
                                    <ShoppingCart class="w-4 h-4" />
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Featured Products -->
        <section class="py-14 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h2 class="text-2xl font-black text-slate-900 dark:text-white">المنتجات الأكثر تميزاً</h2>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">مجموعة منتقاة بعناية تلبي كافة احتياجاتك</p>
                </div>
                <Link
                    :href="route('store.shop', { featured_only: 1 })"
                    class="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline flex items-center gap-1"
                >
                    <span>تصفح المميز</span>
                    <ArrowLeft class="w-4 h-4" />
                </Link>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                <div
                    v-for="item in featuredItems"
                    :key="item.id"
                    class="group rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-xl transition-all overflow-hidden flex flex-col"
                >
                    <div class="relative h-56 bg-slate-100 dark:bg-slate-800 overflow-hidden">
                        <img
                            :src="item.image || 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=500&auto=format&fit=crop&q=80'"
                            :alt="item.name"
                            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        />
                        <div class="absolute top-3 left-3 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                                @click="toggleWishlist(item.id)"
                                class="w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200 hover:text-rose-600 flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                            >
                                <Heart class="w-4 h-4" :class="{ 'fill-rose-500 text-rose-500': isWishlisted(item.id) }" />
                            </button>
                            <button
                                @click="openQuickView(item)"
                                class="w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200 hover:text-emerald-600 flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                            >
                                <Eye class="w-4 h-4" />
                            </button>
                        </div>
                    </div>

                    <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
                        <div>
                            <span class="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md">
                                {{ item.category?.name || 'عام' }}
                            </span>
                            <Link :href="route('store.product', item.id)" class="block mt-2">
                                <h3 class="text-sm font-bold text-slate-900 dark:text-white hover:text-emerald-600 transition-colors line-clamp-2">
                                    {{ item.name }}
                                </h3>
                            </Link>
                        </div>

                        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
                            <div>
                                <div class="text-base font-black text-emerald-600 dark:text-emerald-400">
                                    {{ item.effective_price }} ₪
                                </div>
                            </div>
                            <button
                                @click="addToCart(item, 1)"
                                class="p-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white transition-colors shadow-md shadow-emerald-600/20"
                                title="أضف إلى السلة"
                            >
                                <ShoppingCart class="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Banner Promo Section -->
        <section class="py-12 bg-emerald-600 text-white relative overflow-hidden">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div class="flex flex-col md:flex-row items-center justify-between gap-8 text-right">
                    <div class="space-y-3">
                        <span class="px-3 py-1 rounded-full bg-emerald-700 text-xs font-bold uppercase tracking-wider">
                            تطبيق الهواتف ونظام ERP
                        </span>
                        <h2 class="text-2xl sm:text-3xl font-black">
                            تسوّق أينما كنت وتتبّع فواتيرك ولوازمك بسهولة
                        </h2>
                        <p class="text-xs sm:text-sm text-emerald-100 max-w-xl leading-relaxed">
                            متجر رنتيسي يوفر لك تجربة متكاملة تشمل الفواتير الإلكترونية، ربط سريع بحسابات جوجل وفيسبوك، وإشعارات فورية بكل جديد.
                        </p>
                    </div>

                    <div class="flex items-center gap-4 shrink-0">
                        <Link
                            :href="route('register')"
                            class="px-7 py-3.5 rounded-2xl bg-white text-emerald-700 hover:bg-emerald-50 font-bold text-sm shadow-xl transition-all hover:scale-105"
                        >
                            انضم إلينا وافتح حسابك
                        </Link>
                    </div>
                </div>
            </div>
        </section>

        <!-- Quick View Modal -->
        <div
            v-if="isQuickViewOpen && selectedItem"
            class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200"
            @click.self="closeQuickView"
        >
            <div class="bg-white dark:bg-slate-900 rounded-3xl max-w-2xl w-full p-6 relative shadow-2xl border border-slate-100 dark:border-slate-800 text-right space-y-6">
                <button
                    @click="closeQuickView"
                    class="absolute top-4 left-4 p-2 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                >
                    <X class="w-5 h-5" />
                </button>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
                    <div class="h-64 rounded-2xl bg-slate-100 dark:bg-slate-800 overflow-hidden">
                        <img
                            :src="selectedItem.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                            :alt="selectedItem.name"
                            class="w-full h-full object-cover"
                        />
                    </div>

                    <div class="space-y-4">
                        <span class="text-xs font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-1 rounded-md">
                            {{ selectedItem.category?.name || 'منتج عام' }}
                        </span>

                        <h3 class="text-lg font-black text-slate-900 dark:text-white">
                            {{ selectedItem.name }}
                        </h3>

                        <p class="text-xs text-slate-500 dark:text-slate-400 line-clamp-3 leading-relaxed">
                            {{ selectedItem.description || 'منتج أصلي عالي الجودة معتمد ومدرج بنظام الفوترة والمحاسبة.' }}
                        </p>

                        <div class="flex items-center gap-3">
                            <span class="text-2xl font-black text-emerald-600 dark:text-emerald-400">
                                {{ selectedItem.effective_price }} ₪
                            </span>
                            <span v-if="selectedItem.discount_price && selectedItem.discount_price < selectedItem.sales_price" class="text-sm text-slate-400 line-through">
                                {{ selectedItem.sales_price }} ₪
                            </span>
                        </div>

                        <!-- Quantity and Add to Cart -->
                        <div class="flex items-center gap-3 pt-2">
                            <div class="flex items-center border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden bg-slate-50 dark:bg-slate-800">
                                <button
                                    @click="quickViewQty = Math.max(1, quickViewQty - 1)"
                                    class="px-3 py-2 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700"
                                >
                                    -
                                </button>
                                <span class="px-3 py-2 text-xs font-bold text-slate-900 dark:text-white">{{ quickViewQty }}</span>
                                <button
                                    @click="quickViewQty += 1"
                                    class="px-3 py-2 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700"
                                >
                                    +
                                </button>
                            </div>

                            <button
                                @click="addToCart(selectedItem, quickViewQty)"
                                class="flex-1 py-3 px-5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/20"
                            >
                                <ShoppingCart class="w-4 h-4" />
                                <span>إضافة إلى السلة</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
