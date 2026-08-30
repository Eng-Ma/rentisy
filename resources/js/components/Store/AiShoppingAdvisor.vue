<script setup lang="ts">
import { ref, computed } from 'vue'
import { router, usePage, Link } from '@inertiajs/vue3'
import { 
    Sparkles, 
    X, 
    Send, 
    ShoppingBag, 
    Check, 
    ArrowRight, 
    Lock, 
    Zap, 
    ShieldCheck, 
    Gift, 
    Cpu, 
    LogIn, 
    UserPlus,
    Flame
} from 'lucide-vue-next'

const page = usePage()
const user = computed(() => (page.props as any).auth?.user)

const isOpen = ref(false)
const isLoading = ref(false)
const userPrompt = ref('')
const maxPrice = ref(5000)
const selectedUseCase = ref('all')
const recommendations = ref<any[]>([])
const aiAdvice = ref('')
const addedId = ref<number | null>(null)

const quickPresets = [
    { label: 'لابتوب محاسبة وأعمال 💻', prompt: 'بدي لابتوب قوي وسريع لبرامج المحاسبة والأعمال اليومية', useCase: 'business', maxPrice: 4500 },
    { label: 'سماعات عازلة للضوضاء 🎧', prompt: 'أفضل سماعات عازلة للضوضاء للمكالمات والتركيز', useCase: 'audio', maxPrice: 1500 },
    { label: 'هاتف مميز للتصوير 📱', prompt: 'هاتف ذكي قوي بكاميرا وبطارية ممتازة', useCase: 'mobile', maxPrice: 6000 },
    { label: 'شاشة وتصميم جرافيك 🎨', prompt: 'شاشة أو جهاز مناسب لأعمال الجرافيك والتصميم', useCase: 'design', maxPrice: 3500 },
]

const selectPreset = (p: any) => {
    if (!user.value) {
        isOpen.value = true
        return
    }
    userPrompt.value = p.prompt
    selectedUseCase.value = p.useCase
    maxPrice.value = p.maxPrice
    getAdvice()
}

const getAdvice = async () => {
    if (!user.value) return

    isLoading.value = true
    try {
        const params = new URLSearchParams()
        if (userPrompt.value) params.append('prompt', userPrompt.value)
        if (maxPrice.value) params.append('max_price', maxPrice.value.toString())
        if (selectedUseCase.value) params.append('use_case', selectedUseCase.value)

        const res = await fetch(`/api/store/ai-advisor/recommend?${params.toString()}`)
        const data = await res.json()
        recommendations.value = data.items || []
        aiAdvice.value = data.ai_advice || ''
    } catch (e) {
        console.error(e)
    } finally {
        isLoading.value = false
    }
}

const addToCart = (item: any) => {
    router.post(route('cart.add'), {
        item_id: item.id,
        quantity: 1
    }, {
        preserveScroll: true,
        onSuccess: () => {
            addedId.value = item.id
            setTimeout(() => { addedId.value = null }, 2000)
        }
    })
}
</script>

<template>
    <div class="fixed bottom-6 start-6 z-50">
        <!-- Floating Trigger Button -->
        <button 
            @click="isOpen = !isOpen"
            class="group relative flex items-center gap-3 px-5 py-3.5 rounded-full shadow-2xl hover:scale-105 transition-all duration-300 active:scale-95 text-white"
            :class="user 
                ? 'bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 shadow-indigo-500/40 hover:shadow-indigo-500/60' 
                : 'bg-gradient-to-r from-slate-900 via-indigo-950 to-purple-950 border-2 border-amber-400/80 shadow-amber-500/20 hover:shadow-amber-500/40'"
        >
            <!-- Badge on Top -->
            <span v-if="!user" class="absolute -top-3 start-4 px-2.5 py-0.5 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 text-slate-950 text-[10px] font-black tracking-wide shadow-md flex items-center gap-1 animate-bounce">
                <Sparkles class="w-3 h-3 fill-slate-950" />
                حصري للأعضاء 🔒
            </span>

            <span v-else class="absolute -top-1 -end-1 flex h-3.5 w-3.5">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
            </span>

            <div class="p-1.5 rounded-full bg-white/10 backdrop-blur-sm">
                <Sparkles v-if="user" class="w-5 h-5 animate-pulse text-amber-300" />
                <Lock v-else class="w-5 h-5 text-amber-400 animate-pulse" />
            </div>

            <div class="text-start">
                <span class="font-black text-xs sm:text-sm block leading-tight">مستشار المشتريات الذكي AI</span>
                <span v-if="!user" class="text-[10px] text-amber-300 font-bold block opacity-90">سجّل دخولك واستشره مجاناً</span>
            </div>
        </button>

        <!-- Assistant Drawer / Modal -->
        <Transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="transform opacity-0 scale-95 translate-y-4"
            enter-to-class="transform opacity-100 scale-100 translate-y-0"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="transform opacity-100 scale-100 translate-y-0"
            leave-to-class="transform opacity-0 scale-95 translate-y-4"
        >
            <div 
                v-if="isOpen" 
                class="absolute bottom-16 start-0 w-[360px] sm:w-[420px] max-h-[85vh] flex flex-col bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl shadow-2xl overflow-hidden backdrop-blur-xl"
            >
                <!-- Header -->
                <div class="p-4 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white flex items-center justify-between shadow-md">
                    <div class="flex items-center gap-2.5">
                        <div class="p-2 bg-white/15 rounded-xl backdrop-blur-md">
                            <Sparkles class="w-5 h-5 text-amber-300" />
                        </div>
                        <div>
                            <h3 class="font-bold text-sm">المستشار التقني والمالي الذكي AI</h3>
                            <p class="text-xs text-indigo-100">يرشح لك أفضل الأجهزة والمواصفات لميزانيتك</p>
                        </div>
                    </div>
                    <button @click="isOpen = false" class="p-1.5 hover:bg-white/20 rounded-lg text-white/80 hover:text-white transition">
                        <X class="w-5 h-5" />
                    </button>
                </div>

                <!-- CASE 1: USER IS NOT LOGGED IN (Stunning VIP Teaser & Auth Prompt) -->
                <div v-if="!user" class="p-6 overflow-y-auto flex-1 space-y-5 text-center">
                    <!-- Glowing AI Icon -->
                    <div class="relative mx-auto w-20 h-20 flex items-center justify-center">
                        <div class="absolute inset-0 rounded-full bg-gradient-to-tr from-amber-400 to-indigo-600 opacity-30 blur-lg animate-pulse"></div>
                        <div class="relative w-16 h-16 rounded-2xl bg-gradient-to-tr from-indigo-600 via-purple-600 to-pink-600 flex items-center justify-center text-white shadow-xl shadow-indigo-500/30">
                            <Cpu class="w-8 h-8 text-amber-300 animate-pulse" />
                        </div>
                        <div class="absolute -bottom-1 -end-1 p-1 bg-amber-500 rounded-full text-slate-950 shadow-md">
                            <Lock class="w-3.5 h-3.5" />
                        </div>
                    </div>

                    <!-- Title & Pitch -->
                    <div class="space-y-2">
                        <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 text-xs font-black">
                            <Sparkles class="w-3.5 h-3.5" />
                            ميزة حصرية لأعضاء رنتيسي ستور
                        </span>
                        <h4 class="text-base font-black text-slate-900 dark:text-white">
                            مستشارك الذكي بانتظارك! 🤖
                        </h4>
                        <p class="text-xs text-slate-500 dark:text-slate-400 leading-relaxed px-2">
                            سجل دخولك بنقرة واحدة لتحصل على استشارات فورية ومطابقة مواصفات الأجهزة مع ميزانيتك ومخزون المستودع المركزي.
                        </p>
                    </div>

                    <!-- Feature Highlights -->
                    <div class="grid grid-cols-1 gap-2.5 text-start text-xs">
                        <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 flex items-center gap-3">
                            <div class="p-2 rounded-xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 shrink-0">
                                <Zap class="w-4 h-4" />
                            </div>
                            <div>
                                <strong class="block text-slate-900 dark:text-white font-bold">مطابقة ذكية حسب ميزانيتك</strong>
                                <span class="text-[11px] text-slate-400">يقترح أفضل الخيارات بدقة من بين آلاف المنتجات</span>
                            </div>
                        </div>

                        <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 flex items-center gap-3">
                            <div class="p-2 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 shrink-0">
                                <ShieldCheck class="w-4 h-4" />
                            </div>
                            <div>
                                <strong class="block text-slate-900 dark:text-white font-bold">فحص فوري للمخزون والضمان</strong>
                                <span class="text-[11px] text-slate-400">تأكد لحظي من توفر القطع بالمستودع الأصلي</span>
                            </div>
                        </div>

                        <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 flex items-center gap-3">
                            <div class="p-2 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 shrink-0">
                                <Gift class="w-4 h-4" />
                            </div>
                            <div>
                                <strong class="block text-slate-900 dark:text-white font-bold">كاش باك ونقاط ولاء مضاعفة</strong>
                                <span class="text-[11px] text-slate-400">استبدل نقاطك بخصم مالي مباشر على طلبك</span>
                            </div>
                        </div>
                    </div>

                    <!-- 1-Click Fast Auth Buttons -->
                    <div class="space-y-2.5 pt-2">
                        <!-- Direct Google OAuth 1-Click -->
                        <a
                            href="/auth/google/redirect"
                            class="w-full py-3 px-4 rounded-2xl bg-white hover:bg-slate-50 dark:bg-slate-800 dark:hover:bg-slate-700 border-2 border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-100 font-bold text-xs flex items-center justify-center gap-2.5 shadow-sm transition hover:scale-[1.02]"
                        >
                            <svg class="w-4 h-4 shrink-0" viewBox="0 0 24 24">
                                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
                                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
                            </svg>
                            <span>تسجيل سريع بنقرة واحدة عبر Google</span>
                        </a>

                        <!-- Standard Login / Register Buttons -->
                        <div class="grid grid-cols-2 gap-2">
                            <Link
                                :href="route('login')"
                                class="py-2.5 px-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-md shadow-indigo-600/20 transition"
                            >
                                <LogIn class="w-3.5 h-3.5" />
                                <span>تسجيل الدخول</span>
                            </Link>

                            <Link
                                :href="route('register')"
                                class="py-2.5 px-3 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 font-bold text-xs flex items-center justify-center gap-1.5 border border-slate-200 dark:border-slate-700 transition"
                            >
                                <UserPlus class="w-3.5 h-3.5" />
                                <span>حساب جديد</span>
                            </Link>
                        </div>
                    </div>
                </div>

                <!-- CASE 2: USER IS LOGGED IN (Full AI Advisor Experience) -->
                <div v-else class="p-4 overflow-y-auto flex-1 space-y-4 text-sm">
                    <!-- Quick Presets -->
                    <div>
                        <div class="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-2 flex items-center gap-1.5">
                            <Flame class="w-3.5 h-3.5 text-rose-500" />
                            <span>أفكار وبحث سريع:</span>
                        </div>
                        <div class="flex flex-wrap gap-1.5">
                            <button
                                v-for="preset in quickPresets"
                                :key="preset.label"
                                @click="selectPreset(preset)"
                                class="text-xs px-2.5 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-indigo-50 dark:hover:bg-indigo-950/50 hover:text-indigo-600 dark:hover:text-indigo-400 border border-slate-200 dark:border-slate-700 transition"
                            >
                                {{ preset.label }}
                            </button>
                        </div>
                    </div>

                    <!-- Search Input & Budget -->
                    <div class="space-y-3 bg-slate-50 dark:bg-slate-800/50 p-3.5 rounded-2xl border border-slate-200/60 dark:border-slate-800">
                        <div>
                            <label class="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">ما الذي تبحث عنه؟</label>
                            <div class="relative">
                                <input
                                    v-model="userPrompt"
                                    @keydown.enter="getAdvice"
                                    type="text"
                                    placeholder="مثال: لابتوب ممتاز للأعمال ببطارية تدوم طويلاً..."
                                    class="w-full text-xs pe-9 ps-3 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                                />
                                <button
                                    @click="getAdvice"
                                    class="absolute end-1.5 top-1.5 p-1 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                                >
                                    <Send class="w-3.5 h-3.5" />
                                </button>
                            </div>
                        </div>

                        <!-- Budget Range -->
                        <div>
                            <div class="flex justify-between text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                                <span>الحد الأقصى للميزانية:</span>
                                <span class="text-indigo-600 dark:text-indigo-400 font-bold">{{ maxPrice }} ₪</span>
                            </div>
                            <input 
                                v-model.number="maxPrice" 
                                @change="getAdvice"
                                type="range" 
                                min="200" 
                                max="15000" 
                                step="100" 
                                class="w-full accent-indigo-600 cursor-pointer"
                            />
                        </div>
                    </div>

                    <!-- AI Advice Summary -->
                    <div v-if="aiAdvice" class="p-3 bg-indigo-50/80 dark:bg-indigo-950/40 border border-indigo-100 dark:border-indigo-900/60 rounded-2xl text-xs leading-relaxed text-indigo-900 dark:text-indigo-200 flex gap-2">
                        <Zap class="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                        <div>{{ aiAdvice }}</div>
                    </div>

                    <!-- Loading State -->
                    <div v-if="isLoading" class="py-8 text-center text-slate-400 flex flex-col items-center gap-2">
                        <div class="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
                        <span class="text-xs">جاري فحص المواصفات ومطابقة المخزون...</span>
                    </div>

                    <!-- Recommendations List -->
                    <div v-else-if="recommendations.length > 0" class="space-y-2.5">
                        <div class="text-xs font-bold text-slate-700 dark:text-slate-300">الترشيحات الموصى بها:</div>
                        <div 
                            v-for="item in recommendations" 
                            :key="item.id"
                            class="p-2.5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl flex gap-3 items-center hover:border-indigo-400 transition"
                        >
                            <img 
                                :src="item.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300'" 
                                class="w-14 h-14 object-cover rounded-lg bg-slate-100 dark:bg-slate-800 shrink-0" 
                            />
                            <div class="flex-1 min-w-0">
                                <h4 class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate">{{ item.name }}</h4>
                                <div class="flex items-center gap-2 mt-1">
                                    <span class="text-xs font-black text-indigo-600 dark:text-indigo-400">{{ item.effective_price }} ₪</span>
                                    <span v-if="item.is_deal" class="text-[10px] line-through text-slate-400">{{ item.sales_price }} ₪</span>
                                </div>
                                <div class="text-[10px] text-emerald-600 dark:text-emerald-400 font-medium">متوفر بالمستودع الرئيسي</div>
                            </div>
                            <button
                                @click="addToCart(item)"
                                :class="[
                                    addedId === item.id 
                                        ? 'bg-emerald-500 text-white' 
                                        : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                                ]"
                                class="p-2 rounded-lg transition shrink-0 shadow-sm"
                                title="إضافة للسلة"
                            >
                                <Check v-if="addedId === item.id" class="w-4 h-4" />
                                <ShoppingBag v-else class="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Footer (Only for Logged In User) -->
                <div v-if="user" class="p-3 bg-slate-50 dark:bg-slate-900/80 border-t border-slate-100 dark:border-slate-800 text-center">
                    <button 
                        @click="getAdvice" 
                        class="w-full py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow transition"
                    >
                        تحديث واقتراح خيارات إضافية
                    </button>
                </div>
            </div>
        </Transition>
    </div>
</template>
