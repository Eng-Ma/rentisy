<script setup lang="ts">
import { ref, reactive } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    Filter,
    Search,
    Grid,
    List,
    Heart,
    ShoppingCart,
    Star,
    Sparkles,
    RotateCcw,
    ChevronDown,
    SlidersHorizontal,
    X,
    Eye
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
    items_count?: number;
}

interface Props {
    items: {
        data: Item[];
        current_page: number;
        last_page: number;
        total: number;
        links: Array<{ url: string | null; label: string; active: boolean }>;
    };
    categories: Category[];
    filters: {
        search?: string;
        category_id?: number | string;
        min_price?: number | string;
        max_price?: number | string;
        deals_only?: boolean;
        featured_only?: boolean;
        sort?: string;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const isFilterDrawerOpen = ref(false);
const viewMode = ref<'grid' | 'list'>('grid');

const filterForm = reactive({
    search: props.filters.search || '',
    category_id: props.filters.category_id || '',
    min_price: props.filters.min_price || '',
    max_price: props.filters.max_price || '',
    deals_only: Boolean(props.filters.deals_only),
    featured_only: Boolean(props.filters.featured_only),
    sort: props.filters.sort || 'newest',
});

const applyFilters = () => {
    router.get(route('store.shop'), filterForm as any, {
        preserveState: true,
        preserveScroll: true,
    });
    isFilterDrawerOpen.value = false;
};

const resetFilters = () => {
    filterForm.search = '';
    filterForm.category_id = '';
    filterForm.min_price = '';
    filterForm.max_price = '';
    filterForm.deals_only = false;
    filterForm.featured_only = false;
    filterForm.sort = 'newest';
    applyFilters();
};

const addToCart = (item: Item) => {
    router.post(route('cart.add'), {
        item_id: item.id,
        quantity: 1,
    }, {
        preserveScroll: true
    });
};

const toggleWishlist = (itemId: number) => {
    router.post(route('wishlist.toggle'), {
        item_id: itemId,
    }, {
        preserveScroll: true
    });
};

const isWishlisted = (itemId: number) => {
    return props.storeContext?.wishlistIds?.includes(itemId) ?? false;
};
</script>

<template>
    <StoreLayout title="كتالوج المنتجات والمتجر | رنتيسي ستور" :storeContext="storeContext">
        <!-- Breadcrumb / Header Header -->
        <div class="bg-white dark:bg-slate-900 border-b border-slate-200/80 dark:border-slate-800 py-6">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 class="text-2xl font-black text-slate-900 dark:text-white">كتالوج المتجر</h1>
                        <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                            تصفح جميع المنتجات المتاحة والمسجلة بنظام المستودعات والمحاسبة
                        </p>
                    </div>

                    <div class="flex items-center gap-2 text-xs text-slate-500">
                        <Link :href="route('home')" class="hover:text-emerald-600">الرئيسية</Link>
                        <span>/</span>
                        <span class="text-emerald-600 font-bold">كافة المنتجات ({{ items.total }})</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
                <!-- Desktop Sidebar Filters -->
                <aside class="hidden lg:block space-y-6">
                    <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                        <div class="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
                            <span class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                                <Filter class="w-4 h-4 text-emerald-600" />
                                تصفية النتائج
                            </span>
                            <button
                                @click="resetFilters"
                                class="text-xs font-semibold text-rose-500 hover:underline flex items-center gap-1"
                            >
                                <RotateCcw class="w-3 h-3" />
                                إعادة ضبط
                            </button>
                        </div>

                        <!-- Categories Filter -->
                        <div>
                            <h4 class="text-xs font-bold text-slate-900 dark:text-white mb-3">التصنيفات</h4>
                            <div class="space-y-1.5 max-h-60 overflow-y-auto pr-1">
                                <label class="flex items-center justify-between p-2 rounded-xl text-xs cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/60" :class="{ 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 font-bold': filterForm.category_id === '' }">
                                    <div class="flex items-center gap-2">
                                        <input type="radio" value="" v-model="filterForm.category_id" @change="applyFilters" class="text-emerald-600 focus:ring-emerald-500" />
                                        <span>كافة التصنيفات</span>
                                    </div>
                                    <span class="text-[11px] opacity-70">{{ items.total }}</span>
                                </label>
                                <label
                                    v-for="cat in categories"
                                    :key="cat.id"
                                    class="flex items-center justify-between p-2 rounded-xl text-xs cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/60"
                                    :class="{ 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 font-bold': String(filterForm.category_id) === String(cat.id) }"
                                >
                                    <div class="flex items-center gap-2">
                                        <input type="radio" :value="cat.id" v-model="filterForm.category_id" @change="applyFilters" class="text-emerald-600 focus:ring-emerald-500" />
                                        <span>{{ cat.name }}</span>
                                    </div>
                                    <span class="text-[11px] opacity-70">{{ cat.items_count ?? 0 }}</span>
                                </label>
                            </div>
                        </div>

                        <!-- Price Range Filter -->
                        <div class="pt-4 border-t border-slate-100 dark:border-slate-800">
                            <h4 class="text-xs font-bold text-slate-900 dark:text-white mb-3">نطاق السعر (شيكل ₪)</h4>
                            <div class="grid grid-cols-2 gap-2">
                                <div>
                                    <label class="text-[10px] text-slate-400 block mb-1">الحد الأدنى</label>
                                    <input
                                        type="number"
                                        v-model="filterForm.min_price"
                                        placeholder="0"
                                        class="w-full px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                    />
                                </div>
                                <div>
                                    <label class="text-[10px] text-slate-400 block mb-1">الحد الأقصى</label>
                                    <input
                                        type="number"
                                        v-model="filterForm.max_price"
                                        placeholder="1000"
                                        class="w-full px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                                    />
                                </div>
                            </div>
                            <button
                                @click="applyFilters"
                                class="mt-3 w-full py-2 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-emerald-600 text-white text-xs font-bold transition-colors"
                            >
                                تطبيق نطاق السعر
                            </button>
                        </div>

                        <!-- Special Toggles -->
                        <div class="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-2.5">
                            <label class="flex items-center gap-2 text-xs cursor-pointer">
                                <input
                                    type="checkbox"
                                    v-model="filterForm.deals_only"
                                    @change="applyFilters"
                                    class="rounded text-emerald-600 focus:ring-emerald-500"
                                />
                                <span class="text-rose-600 font-bold">عروض وتخفيضات فقط</span>
                            </label>
                            <label class="flex items-center gap-2 text-xs cursor-pointer">
                                <input
                                    type="checkbox"
                                    v-model="filterForm.featured_only"
                                    @change="applyFilters"
                                    class="rounded text-emerald-600 focus:ring-emerald-500"
                                />
                                <span>المنتجات المميزة فقط</span>
                            </label>
                        </div>
                    </div>
                </aside>

                <!-- Products Grid / Results -->
                <div class="lg:col-span-3 space-y-6">
                    <!-- Controls Bar -->
                    <div class="p-4 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
                        <div class="flex items-center gap-3 w-full sm:w-auto">
                            <!-- Mobile Filter Drawer Trigger -->
                            <button
                                @click="isFilterDrawerOpen = true"
                                class="lg:hidden px-3.5 py-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-xs font-bold flex items-center gap-2"
                            >
                                <SlidersHorizontal class="w-4 h-4" />
                                <span>تصفية</span>
                            </button>

                            <span class="text-xs text-slate-500 dark:text-slate-400">
                                تم العثور على <strong class="text-slate-900 dark:text-white">{{ items.total }}</strong> منتج
                            </span>
                        </div>

                        <div class="flex items-center gap-3 w-full sm:w-auto justify-between sm:justify-end">
                            <!-- Sort Dropdown -->
                            <div class="flex items-center gap-2">
                                <span class="text-xs text-slate-500 hidden sm:inline">ترتيب حسب:</span>
                                <select
                                    v-model="filterForm.sort"
                                    @change="applyFilters"
                                    class="px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold focus:ring-2 focus:ring-emerald-500"
                                >
                                    <option value="newest">الأحدث وصولاً</option>
                                    <option value="price_asc">السعر: من الأقل للأعلى</option>
                                    <option value="price_desc">السعر: من الأعلى للأقل</option>
                                    <option value="rating">الأعلى تقييماً</option>
                                    <option value="name">الاسم أبجدياً</option>
                                </select>
                            </div>

                            <!-- View Mode Switcher -->
                            <div class="flex items-center bg-slate-100 dark:bg-slate-800 p-1 rounded-xl">
                                <button
                                    @click="viewMode = 'grid'"
                                    class="p-1.5 rounded-lg transition-colors"
                                    :class="{ 'bg-white dark:bg-slate-700 shadow-sm text-emerald-600': viewMode === 'grid', 'text-slate-400': viewMode !== 'grid' }"
                                >
                                    <Grid class="w-4 h-4" />
                                </button>
                                <button
                                    @click="viewMode = 'list'"
                                    class="p-1.5 rounded-lg transition-colors"
                                    :class="{ 'bg-white dark:bg-slate-700 shadow-sm text-emerald-600': viewMode === 'list', 'text-slate-400': viewMode !== 'list' }"
                                >
                                    <List class="w-4 h-4" />
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Products Grid -->
                    <div v-if="items.data.length > 0">
                        <div
                            v-if="viewMode === 'grid'"
                            class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6"
                        >
                            <div
                                v-for="item in items.data"
                                :key="item.id"
                                class="group rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-xl transition-all overflow-hidden flex flex-col"
                            >
                                <div class="relative h-56 bg-slate-100 dark:bg-slate-800 overflow-hidden">
                                    <img
                                        :src="item.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                                        :alt="item.name"
                                        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                    />
                                    <span
                                        v-if="item.discount_price && item.discount_price < item.sales_price"
                                        class="absolute top-3 right-3 px-2.5 py-1 rounded-full bg-rose-600 text-white text-[10px] font-extrabold shadow-sm"
                                    >
                                        خصم {{ Math.round(((item.sales_price - item.discount_price) / item.sales_price) * 100) }}%
                                    </span>
                                    <div class="absolute top-3 left-3 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <button
                                            @click="toggleWishlist(item.id)"
                                            class="w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-slate-700 dark:text-slate-200 hover:text-rose-600 flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                                        >
                                            <Heart class="w-4 h-4" :class="{ 'fill-rose-500 text-rose-500': isWishlisted(item.id) }" />
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
                                            <div v-if="item.discount_price && item.discount_price < item.sales_price" class="text-xs text-slate-400 line-through">
                                                {{ item.sales_price }} ₪
                                            </div>
                                        </div>
                                        <button
                                            @click="addToCart(item)"
                                            class="p-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white transition-colors shadow-md shadow-emerald-600/20"
                                            title="أضف إلى السلة"
                                        >
                                            <ShoppingCart class="w-4 h-4" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- List View Mode -->
                        <div v-else class="space-y-4">
                            <div
                                v-for="item in items.data"
                                :key="item.id"
                                class="p-4 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm flex flex-col sm:flex-row items-center gap-6"
                            >
                                <div class="w-full sm:w-44 h-40 rounded-2xl bg-slate-100 dark:bg-slate-800 overflow-hidden shrink-0">
                                    <img
                                        :src="item.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                                        :alt="item.name"
                                        class="w-full h-full object-cover"
                                    />
                                </div>
                                <div class="flex-1 space-y-2 text-right w-full">
                                    <span class="text-[10px] font-bold text-emerald-600 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md">
                                        {{ item.category?.name || 'عام' }}
                                    </span>
                                    <Link :href="route('store.product', item.id)">
                                        <h3 class="text-base font-bold text-slate-900 dark:text-white hover:text-emerald-600">
                                            {{ item.name }}
                                        </h3>
                                    </Link>
                                    <p class="text-xs text-slate-500 line-clamp-2">
                                        {{ item.description || 'منتج عالي الجودة معتمد ومطابق للمعايير.' }}
                                    </p>
                                </div>
                                <div class="w-full sm:w-auto flex sm:flex-col items-center justify-between sm:justify-center gap-3 shrink-0 sm:border-r sm:border-slate-100 sm:dark:border-slate-800 sm:pr-6">
                                    <div class="text-right sm:text-center">
                                        <div class="text-lg font-black text-emerald-600">{{ item.effective_price }} ₪</div>
                                        <div v-if="item.discount_price && item.discount_price < item.sales_price" class="text-xs text-slate-400 line-through">
                                            {{ item.sales_price }} ₪
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-2">
                                        <button
                                            @click="toggleWishlist(item.id)"
                                            class="p-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600"
                                        >
                                            <Heart class="w-4 h-4" :class="{ 'fill-rose-500 text-rose-500': isWishlisted(item.id) }" />
                                        </button>
                                        <button
                                            @click="addToCart(item)"
                                            class="px-4 py-2.5 rounded-xl bg-emerald-600 text-white font-bold text-xs flex items-center gap-2"
                                        >
                                            <ShoppingCart class="w-4 h-4" />
                                            <span>شراء</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Pagination -->
                        <div v-if="items.last_page > 1" class="pt-8 flex items-center justify-center gap-2">
                            <Link
                                v-for="(link, i) in items.links"
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
                    <div v-else class="p-12 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 dark:border-slate-800 space-y-4">
                        <div class="w-16 h-16 rounded-2xl bg-slate-100 dark:bg-slate-800 text-slate-400 flex items-center justify-center mx-auto">
                            <Search class="w-8 h-8" />
                        </div>
                        <h3 class="text-base font-bold text-slate-900 dark:text-white">لم يتم العثور على نتائج</h3>
                        <p class="text-xs text-slate-500 max-w-sm mx-auto">
                            جرب البحث بكلمات أخرى أو قم بإلغاء بعض الفلاتر لعرض مزيد من المنتجات.
                        </p>
                        <button
                            @click="resetFilters"
                            class="px-5 py-2.5 rounded-xl bg-emerald-600 text-white text-xs font-bold"
                        >
                            إلغاء جميع الفلاتر
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
