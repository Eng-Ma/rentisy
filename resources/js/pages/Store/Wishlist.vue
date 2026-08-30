<script setup lang="ts">
import { Head, Link, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    Heart,
    ShoppingCart,
    Trash2,
    ShoppingBag,
    ArrowLeft
} from 'lucide-vue-next';

interface WishlistItem {
    id: number;
    item_id: number;
    item?: {
        id: number;
        name: string;
        image?: string;
        sales_price: number;
        discount_price?: number;
        effective_price: number;
        total_stock: number;
        category?: { id: number; name: string };
    };
}

interface Props {
    wishlistItems: WishlistItem[];
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const moveToCart = (wishlistId: number) => {
    router.post(route('wishlist.move_to_cart', wishlistId), {}, {
        preserveScroll: true
    });
};

const removeFromWishlist = (wishlistId: number) => {
    router.delete(route('wishlist.remove', wishlistId), {
        preserveScroll: true
    });
};
</script>

<template>
    <StoreLayout title="قائمة المفضلة | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <div class="mb-8">
                <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">قائمة المفضلة</h1>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                    المنتجات التي قمت بحفظها للرجوع إليها لاحقاً ({{ wishlistItems.length }} منتج)
                </p>
            </div>

            <div v-if="wishlistItems.length > 0" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                <div
                    v-for="wi in wishlistItems"
                    :key="wi.id"
                    class="group rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 hover:border-emerald-500 shadow-sm hover:shadow-xl transition-all overflow-hidden flex flex-col justify-between"
                >
                    <div class="relative h-56 bg-slate-100 dark:bg-slate-800 overflow-hidden">
                        <img
                            :src="wi.item?.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&auto=format&fit=crop&q=80'"
                            :alt="wi.item?.name"
                            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                        />
                        <button
                            @click="removeFromWishlist(wi.id)"
                            class="absolute top-3 left-3 w-8 h-8 rounded-full bg-white/90 dark:bg-slate-900/90 text-rose-500 hover:bg-rose-500 hover:text-white flex items-center justify-center shadow-md backdrop-blur-sm transition-colors"
                            title="إزالة من المفضلة"
                        >
                            <Trash2 class="w-4 h-4" />
                        </button>
                    </div>

                    <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
                        <div>
                            <span class="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-2 py-0.5 rounded-md">
                                {{ wi.item?.category?.name || 'عام' }}
                            </span>
                            <Link v-if="wi.item" :href="route('store.product', wi.item.id)" class="block mt-2">
                                <h3 class="text-sm font-bold text-slate-900 dark:text-white hover:text-emerald-600 transition-colors line-clamp-2">
                                    {{ wi.item.name }}
                                </h3>
                            </Link>
                        </div>

                        <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
                            <div class="text-base font-black text-emerald-600 dark:text-emerald-400">
                                {{ wi.item?.effective_price }} ₪
                            </div>

                            <button
                                @click="moveToCart(wi.id)"
                                class="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 transition-colors shadow-md shadow-emerald-600/20"
                            >
                                <ShoppingCart class="w-3.5 h-3.5" />
                                <span>نقل للسلة</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Empty Wishlist -->
            <div v-else class="p-16 text-center bg-white dark:bg-slate-900 rounded-3xl border border-slate-200/80 dark:border-slate-800 space-y-6 max-w-xl mx-auto shadow-sm">
                <div class="w-20 h-20 rounded-3xl bg-rose-50 dark:bg-rose-950/60 text-rose-500 flex items-center justify-center mx-auto shadow-inner">
                    <Heart class="w-10 h-10" />
                </div>
                <div class="space-y-2">
                    <h3 class="text-xl font-black text-slate-900 dark:text-white">قائمة المفضلة فارغة</h3>
                    <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                        لم تقم بحفظ أي منتج في المفضلة بعد. تصفح الكتالوج واضغط على أيقونة القلب لحفظ ما يعجبك.
                    </p>
                </div>
                <Link
                    :href="route('store.shop')"
                    class="inline-flex items-center gap-2 px-8 py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-lg shadow-emerald-600/25 transition-all"
                >
                    <ShoppingBag class="w-4 h-4" />
                    <span>تصفح الكتالوج</span>
                </Link>
            </div>
        </div>
    </StoreLayout>
</template>
