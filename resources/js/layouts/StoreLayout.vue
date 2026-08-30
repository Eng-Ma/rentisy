<script setup lang="ts">
import { ref, computed } from 'vue';
import { Head, Link, usePage, router } from '@inertiajs/vue3';
import {
    ShoppingCart,
    Heart,
    User as UserIcon,
    Search,
    Menu,
    X,
    ChevronDown,
    ShoppingBag,
    PackageCheck,
    FileText,
    Settings,
    LogOut,
    Sparkles,
    ShieldCheck,
    Truck,
    Headphones,
    ArrowRight,
    Trash2,
    Store as StoreIcon,
    ExternalLink,
    Coins
} from 'lucide-vue-next';
import AiShoppingAdvisor from '@/components/Store/AiShoppingAdvisor.vue';
import LivePurchaseNotifications from '@/components/Store/LivePurchaseNotifications.vue';

interface Props {
    title?: string;
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = withDefaults(defineProps<Props>(), {
    title: 'متجر رنتيسي الإلكتروني',
});

const page = usePage();
const authUser = computed(() => (page.props as any).auth?.user);
const flash = computed(() => (page.props as any).flash || {});

const searchQuery = ref('');
const isMobileMenuOpen = ref(false);
const isCartDrawerOpen = ref(false);
const isUserMenuOpen = ref(false);

const cartCount = computed(() => {
    return props.storeContext?.cartCount ?? 0;
});

const wishlistCount = computed(() => {
    return props.storeContext?.wishlistIds?.length ?? 0;
});

const handleSearch = () => {
    if (searchQuery.value.trim()) {
        router.visit(route('store.shop', { search: searchQuery.value.trim() }));
    } else {
        router.visit(route('store.shop'));
    }
};

const logout = () => {
    router.post(route('logout'));
};
</script>

<template>
    <div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100 flex flex-col font-sans" dir="rtl">
        <Head :title="title" />

        <!-- Top Announcement Bar -->
        <div class="bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-700 text-white text-xs py-2 px-4 shadow-sm">
            <div class="max-w-7xl mx-auto flex items-center justify-between">
                <div class="flex items-center gap-4 text-emerald-50">
                    <span class="flex items-center gap-1.5 font-medium">
                        <Truck class="w-3.5 h-3.5" />
                        شحن مجاني لكافة الطلبات فوق 200 ₪
                    </span>
                    <span class="hidden sm:inline opacity-70">|</span>
                    <span class="hidden sm:flex items-center gap-1.5 opacity-90">
                        <Sparkles class="w-3.5 h-3.5 text-amber-300" />
                        مدمج لحظياً مع نظام المحاسبة والفوترة
                    </span>
                </div>
                <div class="flex items-center gap-3 text-xs">
                    <span class="hidden md:flex items-center gap-1 opacity-90">
                        <Headphones class="w-3 h-3" />
                        خدمة العملاء: 0599000000
                    </span>
                    <span class="px-2 py-0.5 rounded bg-emerald-700/60 font-semibold">شيكل (ILS ₪)</span>
                </div>
            </div>
        </div>

        <!-- Main Header -->
        <header class="sticky top-0 z-40 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800 shadow-sm">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex items-center justify-between h-20 gap-4">
                    <!-- Logo -->
                    <Link :href="route('home')" class="flex items-center gap-3 group shrink-0">
                        <div class="w-12 h-12 rounded-2xl overflow-hidden border-2 border-emerald-500/30 shadow-lg shadow-emerald-500/20 group-hover:scale-105 group-hover:border-emerald-400 transition-all bg-slate-900 flex items-center justify-center">
                            <img src="/images/nova_logo.jpg" alt="NOVA Store" class="w-full h-full object-cover" />
                        </div>
                        <div>
                            <div class="flex items-center gap-1.5">
                                <span class="text-xl font-black tracking-tight bg-gradient-to-r from-emerald-400 via-teal-300 to-cyan-400 bg-clip-text text-transparent block">
                                    NOVA STORE
                                </span>
                                <span class="text-[10px] font-black px-1.5 py-0.5 rounded-md bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">PRO</span>
                            </div>
                            <span class="text-[11px] text-slate-500 dark:text-slate-400 font-medium block">
                                نوفا ستور — للتقنية الذكية
                            </span>
                        </div>
                    </Link>

                    <!-- Search Bar (Desktop) -->
                    <div class="hidden md:flex flex-1 max-w-xl mx-4">
                        <form @submit.prevent="handleSearch" class="w-full relative">
                            <input
                                v-model="searchQuery"
                                type="text"
                                placeholder="ابحث عن منتج، صنف، باركود، مواصفات..."
                                class="w-full pl-12 pr-4 py-2.5 rounded-full border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all shadow-inner"
                            />
                            <button
                                type="submit"
                                class="absolute left-1.5 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white flex items-center justify-center transition-colors shadow-sm"
                            >
                                <Search class="w-4 h-4" />
                            </button>
                        </form>
                    </div>

                    <!-- Actions (Wishlist, Cart, Profile) -->
                    <div class="flex items-center gap-2 sm:gap-3 shrink-0">
                        <!-- Wishlist Button -->
                        <Link
                            :href="route('wishlist.index')"
                            class="relative p-2.5 rounded-xl text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                            title="المفضلة"
                        >
                            <Heart class="w-6 h-6" />
                            <span
                                v-if="wishlistCount > 0"
                                class="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-rose-500 text-white text-[11px] font-bold flex items-center justify-center animate-pulse shadow-sm"
                            >
                                {{ wishlistCount }}
                            </span>
                        </Link>

                        <!-- Cart Button -->
                        <Link
                            :href="route('cart.index')"
                            class="relative p-2.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-100 dark:hover:bg-emerald-900/50 transition-colors flex items-center gap-2 font-medium"
                            title="سلة التسوق"
                        >
                            <div class="relative">
                                <ShoppingCart class="w-6 h-6" />
                                <span
                                    v-if="cartCount > 0"
                                    class="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-emerald-600 text-white text-[11px] font-bold flex items-center justify-center shadow-sm"
                                >
                                    {{ cartCount }}
                                </span>
                            </div>
                            <span class="hidden lg:inline text-xs font-semibold">السلة</span>
                        </Link>

                        <!-- Divider -->
                        <div class="h-6 w-px bg-slate-200 dark:bg-slate-800 mx-1"></div>

                        <!-- User Profile Dropdown / Login -->
                        <div class="relative">
                            <template v-if="authUser">
                                <button
                                    @click="isUserMenuOpen = !isUserMenuOpen"
                                    class="flex items-center gap-2 p-1.5 pr-3 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-emerald-500 transition-all bg-white dark:bg-slate-900 shadow-sm"
                                >
                                    <div class="w-8 h-8 rounded-lg bg-emerald-100 dark:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 font-bold flex items-center justify-center text-sm uppercase">
                                        {{ authUser.name ? authUser.name.charAt(0) : 'U' }}
                                    </div>
                                    <div class="text-right hidden sm:block">
                                        <div class="text-xs font-bold leading-tight line-clamp-1 max-w-[90px]">{{ authUser.name }}</div>
                                        <div class="text-[10px] text-slate-500 dark:text-slate-400">حسابي</div>
                                    </div>
                                    <ChevronDown class="w-3.5 h-3.5 text-slate-400" />
                                </button>

                                <!-- Dropdown Menu -->
                                <div
                                    v-if="isUserMenuOpen"
                                    class="absolute left-0 mt-2 w-56 bg-white dark:bg-slate-900 rounded-2xl shadow-xl border border-slate-100 dark:border-slate-800 py-2 z-50 animate-in fade-in slide-in-from-top-2 duration-150"
                                    @click="isUserMenuOpen = false"
                                >
                                    <div class="px-4 py-2 border-b border-slate-100 dark:border-slate-800">
                                        <p class="text-xs font-bold text-slate-900 dark:text-white">{{ authUser.name }}</p>
                                        <p class="text-[11px] text-slate-500 truncate">{{ authUser.email }}</p>
                                    </div>

                                    <Link
                                        :href="route('customer.dashboard')"
                                        class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-slate-700 dark:text-slate-300 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 hover:text-emerald-600 transition-colors"
                                    >
                                        <ShoppingBag class="w-4 h-4 text-slate-400" />
                                        لوحة تحكم الزبون
                                    </Link>

                                    <Link
                                        :href="route('customer.orders')"
                                        class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-slate-700 dark:text-slate-300 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 hover:text-emerald-600 transition-colors"
                                    >
                                        <PackageCheck class="w-4 h-4 text-slate-400" />
                                        طلباتي ومشترياتي
                                    </Link>

                                    <Link
                                        :href="route('customer.rewards')"
                                        class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-amber-600 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-950/40 font-semibold transition-colors"
                                    >
                                        <Coins class="w-4 h-4 text-amber-500" />
                                        محفظة نقاط الكاش باك
                                    </Link>

                                    <Link
                                        :href="route('customer.profile')"
                                        class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-slate-700 dark:text-slate-300 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 hover:text-emerald-600 transition-colors"
                                    >
                                        <Settings class="w-4 h-4 text-slate-400" />
                                        الملف الشخصي وربط الحسابات
                                    </Link>

                                    <Link
                                        :href="route('customer.statement')"
                                        class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-slate-700 dark:text-slate-300 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 hover:text-emerald-600 transition-colors"
                                    >
                                        <FileText class="w-4 h-4 text-slate-400" />
                                        كشف حسابي المحاسبي (ERP)
                                    </Link>

                                    <!-- Admin Link ONLY if Admin -->
                                    <template v-if="authUser && authUser.role === 'admin'">
                                        <div class="h-px bg-slate-100 dark:bg-slate-800 my-1"></div>
                                        <Link
                                            :href="route('dashboard')"
                                            class="flex items-center gap-2.5 px-4 py-2.5 text-xs text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-950/40 font-semibold transition-colors"
                                        >
                                            <ExternalLink class="w-4 h-4" />
                                            لوحة إدارة المحاسبة (ERP)
                                        </Link>
                                    </template>

                                    <button
                                        @click="logout"
                                        class="w-full flex items-center gap-2.5 px-4 py-2.5 text-xs text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-colors text-right"
                                    >
                                        <LogOut class="w-4 h-4" />
                                        تسجيل الخروج
                                    </button>
                                </div>
                            </template>

                            <template v-else>
                                <div class="flex items-center gap-2">
                                    <Link
                                        :href="route('login')"
                                        class="px-3 py-2 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:text-emerald-600 transition-colors"
                                    >
                                        دخول
                                    </Link>
                                    <Link
                                        :href="route('register')"
                                        class="px-3.5 py-2 text-xs font-bold rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm shadow-emerald-600/20 transition-all hover:shadow"
                                    >
                                        حساب جديد
                                    </Link>
                                </div>
                            </template>
                        </div>

                        <!-- Mobile Menu Button -->
                        <button
                            @click="isMobileMenuOpen = !isMobileMenuOpen"
                            class="md:hidden p-2 rounded-xl text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800"
                        >
                            <Menu v-if="!isMobileMenuOpen" class="w-6 h-6" />
                            <X v-else class="w-6 h-6" />
                        </button>
                    </div>
                </div>

                <!-- Mobile Search -->
                <div class="md:hidden pb-4">
                    <form @submit.prevent="handleSearch" class="w-full relative">
                        <input
                            v-model="searchQuery"
                            type="text"
                            placeholder="ابحث عن منتج، ماركة، تصنيف..."
                            class="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                        />
                        <button
                            type="submit"
                            class="absolute left-1.5 top-1/2 -translate-y-1/2 p-1.5 rounded-lg bg-emerald-600 text-white"
                        >
                            <Search class="w-3.5 h-3.5" />
                        </button>
                    </form>
                </div>
            </div>

            <!-- Categories / Navigation Bar -->
            <div class="hidden md:block bg-slate-100/70 dark:bg-slate-900/50 border-t border-slate-200/60 dark:border-slate-800 text-xs font-semibold">
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between">
                    <nav class="flex items-center gap-6 py-2.5">
                        <Link
                            :href="route('home')"
                            class="text-slate-700 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                        >
                            الرئيسية
                        </Link>
                        <Link
                            :href="route('store.shop')"
                            class="text-slate-700 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                        >
                            كافة المنتجات
                        </Link>
                        <Link
                            :href="route('store.shop', { deals_only: 1 })"
                            class="flex items-center gap-1 text-rose-600 dark:text-rose-400 hover:underline font-bold"
                        >
                            <Sparkles class="w-3.5 h-3.5" />
                            عروض حصرية وتخفيضات
                        </Link>
                        <Link
                            :href="route('store.shop', { featured_only: 1 })"
                            class="text-slate-700 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                        >
                            المنتجات المميزة
                        </Link>
                        <Link
                            v-if="authUser"
                            :href="route('customer.orders')"
                            class="text-slate-700 dark:text-slate-300 hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                        >
                            تتبع طلبي
                        </Link>
                    </nav>

                    <div class="flex items-center gap-4 text-slate-500 dark:text-slate-400">
                        <span class="flex items-center gap-1 text-[11px]">
                            <ShieldCheck class="w-3.5 h-3.5 text-emerald-500" />
                            ضمان الجودة والدفع الآمن
                        </span>
                    </div>
                </div>
            </div>

            <!-- Mobile Navigation Drawer -->
            <div
                v-if="isMobileMenuOpen"
                class="md:hidden border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 py-4 space-y-3"
            >
                <Link
                    :href="route('home')"
                    class="block py-2 text-sm font-semibold text-slate-700 dark:text-slate-200"
                    @click="isMobileMenuOpen = false"
                >
                    الرئيسية
                </Link>
                <Link
                    :href="route('store.shop')"
                    class="block py-2 text-sm font-semibold text-slate-700 dark:text-slate-200"
                    @click="isMobileMenuOpen = false"
                >
                    كافة المنتجات
                </Link>
                <Link
                    :href="route('store.shop', { deals_only: 1 })"
                    class="block py-2 text-sm font-semibold text-rose-600"
                    @click="isMobileMenuOpen = false"
                >
                    عروض وتخفيضات اليوم
                </Link>
                <Link
                    :href="route('wishlist.index')"
                    class="block py-2 text-sm font-semibold text-slate-700 dark:text-slate-200"
                    @click="isMobileMenuOpen = false"
                >
                    قائمة المفضلة ({{ wishlistCount }})
                </Link>
                <Link
                    :href="route('cart.index')"
                    class="block py-2 text-sm font-semibold text-slate-700 dark:text-slate-200"
                    @click="isMobileMenuOpen = false"
                >
                    سلة المشتريات ({{ cartCount }})
                </Link>

                <div class="pt-3 border-t border-slate-200 dark:border-slate-800">
                    <template v-if="authUser">
                        <Link
                            :href="route('customer.dashboard')"
                            class="block py-2 text-sm font-bold text-emerald-600"
                            @click="isMobileMenuOpen = false"
                        >
                            لوحة تحكم الزبون
                        </Link>
                        <Link
                            :href="route('customer.profile')"
                            class="block py-2 text-sm text-slate-600 dark:text-slate-400"
                            @click="isMobileMenuOpen = false"
                        >
                            الملف الشخصي وربط الحسابات
                        </Link>
                        <button
                            @click="logout"
                            class="block w-full text-right py-2 text-sm text-rose-600"
                        >
                            تسجيل الخروج
                        </button>
                    </template>
                    <template v-else>
                        <div class="grid grid-cols-2 gap-2 pt-2">
                            <Link
                                :href="route('login')"
                                class="w-full py-2.5 text-center text-xs font-bold rounded-xl border border-slate-300 dark:border-slate-700"
                                @click="isMobileMenuOpen = false"
                            >
                                تسجيل الدخول
                            </Link>
                            <Link
                                :href="route('register')"
                                class="w-full py-2.5 text-center text-xs font-bold rounded-xl bg-emerald-600 text-white"
                                @click="isMobileMenuOpen = false"
                            >
                                إنشاء حساب جديد
                            </Link>
                        </div>
                    </template>
                </div>
            </div>
        </header>

        <!-- Flash Messages -->
        <div v-if="flash.success || flash.error || flash.message" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4 w-full">
            <div
                v-if="flash.success"
                class="p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 text-sm font-medium flex items-center justify-between shadow-sm animate-in fade-in"
            >
                <span>{{ flash.success }}</span>
                <span class="text-xs opacity-75">✓</span>
            </div>
            <div
                v-if="flash.error"
                class="p-4 rounded-2xl bg-rose-50 dark:bg-rose-950/60 border border-rose-200 dark:border-rose-800 text-rose-800 dark:text-rose-200 text-sm font-medium flex items-center justify-between shadow-sm animate-in fade-in"
            >
                <span>{{ flash.error }}</span>
                <span class="text-xs opacity-75">✕</span>
            </div>
            <div
                v-if="flash.message"
                class="p-4 rounded-2xl bg-blue-50 dark:bg-blue-950/60 border border-blue-200 dark:border-blue-800 text-blue-800 dark:text-blue-200 text-sm font-medium shadow-sm animate-in fade-in"
            >
                {{ flash.message }}
            </div>
        </div>

        <!-- Page Content -->
        <main class="flex-1">
            <slot />
        </main>

        <!-- Footer -->
        <footer class="bg-slate-900 text-slate-300 border-t border-slate-800 pt-16 pb-12 mt-20">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 pb-12 border-b border-slate-800">
                    <!-- Brand info -->
                    <div class="lg:col-span-2 space-y-4">
                        <div class="flex items-center gap-3">
                            <div class="w-11 h-11 rounded-2xl overflow-hidden border border-slate-700 bg-slate-900 shadow-md">
                                <img src="/images/nova_logo.jpg" alt="NOVA Store" class="w-full h-full object-cover" />
                            </div>
                            <div>
                                <span class="text-xl font-black text-white block">NOVA STORE</span>
                                <span class="text-[10px] text-emerald-400 font-bold">نوفا ستور — الوجهة الذكية للإلكترونيات</span>
                            </div>
                        </div>
                        <p class="text-xs leading-relaxed text-slate-400 max-w-sm">
                            المنظومة الإلكترونية الرائدة للأجهزة والحلول التقنية الذكية. نوفر لك أحدث المنتجات الأصلية مع كفالة معتمدة ودمج محاسبي متكامل وفواتير فورية.
                        </p>
                        <div class="flex items-center gap-3 pt-2">
                            <span class="text-xs text-slate-400 font-semibold">الدفع المعتمد:</span>
                            <span class="px-2.5 py-1 rounded-lg bg-slate-800 text-[10px] font-bold text-slate-300 border border-slate-700">تحويل بنكي فوري</span>
                            <span class="px-2.5 py-1 rounded-lg bg-slate-800 text-[10px] font-bold text-slate-300 border border-slate-700">محافظ رقمية</span>
                        </div>
                    </div>

                    <!-- Quick Links -->
                    <div>
                        <h4 class="text-sm font-bold text-white mb-4">روابط سريعة</h4>
                        <ul class="space-y-2.5 text-xs text-slate-400">
                            <li><Link :href="route('home')" class="hover:text-emerald-400 transition-colors">الرئيسية</Link></li>
                            <li><Link :href="route('store.shop')" class="hover:text-emerald-400 transition-colors">كافة المنتجات</Link></li>
                            <li><Link :href="route('store.shop', { deals_only: 1 })" class="hover:text-emerald-400 transition-colors">العروض والتخفيضات</Link></li>
                            <li><Link :href="route('wishlist.index')" class="hover:text-emerald-400 transition-colors">قائمة المفضلة</Link></li>
                            <li><Link :href="route('cart.index')" class="hover:text-emerald-400 transition-colors">سلة المشتريات</Link></li>
                        </ul>
                    </div>

                    <!-- Customer Service -->
                    <div>
                        <h4 class="text-sm font-bold text-white mb-4">خدمة العملاء</h4>
                        <ul class="space-y-2.5 text-xs text-slate-400">
                            <li><Link :href="route('customer.dashboard')" class="hover:text-emerald-400 transition-colors">لوحة حساب الزبون</Link></li>
                            <li><Link :href="route('customer.orders')" class="hover:text-emerald-400 transition-colors">تتبع مسار الطلب</Link></li>
                            <li><Link :href="route('customer.statement')" class="hover:text-emerald-400 transition-colors">كشف الحساب المحاسبي</Link></li>
                            <li><Link :href="route('privacy.policy')" class="hover:text-emerald-400 transition-colors">سياسة الخصوصية والشروط</Link></li>
                        </ul>
                    </div>

                    <!-- Accounting & Integration -->
                    <div>
                        <h4 class="text-sm font-bold text-white mb-4">نظام المحاسبة ERP</h4>
                        <p class="text-xs text-slate-400 leading-relaxed mb-4">
                            المتجر مرتبط لحظياً بدفتر اليومية وشجرة الحسابات والمستودعات.
                        </p>
                        <Link
                            :href="route('admin.login')"
                            class="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-sm"
                        >
                            <ExternalLink class="w-3.5 h-3.5" />
                            دخول لوحة إدارة المحاسبة (Admin)
                        </Link>
                    </div>
                </div>

                <div class="pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
                    <p>© {{ new Date().getFullYear() }} رنتيسي ستور للمحاسبة والتجارة الإلكترونية. جميع الحقوق محفوظة.</p>
                    <div class="flex items-center gap-4">
                        <span>نظام آمن ومحمي بالكامل 🔒</span>
                    </div>
                </div>
            </div>
        </footer>

        <!-- Mobile Sticky Bottom Bar -->
        <div class="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-200 dark:border-slate-800 px-4 py-2 flex items-center justify-around text-[10px] font-medium shadow-lg">
            <Link :href="route('home')" class="flex flex-col items-center gap-1 text-slate-600 dark:text-slate-400 hover:text-emerald-600">
                <StoreIcon class="w-5 h-5" />
                <span>الرئيسية</span>
            </Link>
            <Link :href="route('store.shop')" class="flex flex-col items-center gap-1 text-slate-600 dark:text-slate-400 hover:text-emerald-600">
                <Search class="w-5 h-5" />
                <span>المتجر</span>
            </Link>
            <Link :href="route('wishlist.index')" class="flex flex-col items-center gap-1 relative text-slate-600 dark:text-slate-400 hover:text-emerald-600">
                <Heart class="w-5 h-5" />
                <span v-if="wishlistCount > 0" class="absolute -top-1 right-2 w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center">
                    {{ wishlistCount }}
                </span>
                <span>المفضلة</span>
            </Link>
            <Link :href="route('cart.index')" class="flex flex-col items-center gap-1 relative text-slate-600 dark:text-slate-400 hover:text-emerald-600">
                <ShoppingCart class="w-5 h-5" />
                <span v-if="cartCount > 0" class="absolute -top-1 right-2 w-4 h-4 rounded-full bg-emerald-600 text-white text-[9px] font-bold flex items-center justify-center">
                    {{ cartCount }}
                </span>
                <span>السلة</span>
            </Link>
            <Link :href="authUser ? route('customer.dashboard') : route('login')" class="flex flex-col items-center gap-1 text-slate-600 dark:text-slate-400 hover:text-emerald-600">
                <UserIcon class="w-5 h-5" />
                <span>{{ authUser ? 'حسابي' : 'دخول' }}</span>
            </Link>
        </div>

        <!-- Floating AI Shopping Advisor -->
        <AiShoppingAdvisor />

        <!-- Live Social Proof Notification Ticker -->
        <LivePurchaseNotifications />
    </div>
</template>
