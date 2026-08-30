<script setup lang="ts">
import { ref } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import StoreLayout from '@/layouts/StoreLayout.vue'
import { 
    Award, 
    Gift, 
    Sparkles, 
    Coins, 
    Share2, 
    Copy, 
    Check, 
    ArrowUpRight, 
    ArrowDownLeft, 
    Crown, 
    ShieldCheck, 
    ShoppingBag, 
    Zap,
    MessageCircle
} from 'lucide-vue-next'

const props = defineProps<{
    points: number
    cashValue: number
    tier: string
    cashbackRate: string
    nextTierTarget: number
    referralCode: string
    referralUrl: string
    transactions: any[]
}>()

const copied = ref(false)

const copyReferral = () => {
    navigator.clipboard.writeText(props.referralUrl)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2500)
}

const shareWhatsApp = () => {
    const text = encodeURIComponent(`تسوق أحدث الأجهزة والتقنيات مع متجر رنتيسي واحصل على خصم فوري ونقاط كاش باك عند التسجيل من خلال الرابط: ${props.referralUrl}`)
    window.open(`https://api.whatsapp.com/send?text=${text}`, '_blank')
}
</script>

<template>
    <Head title="محفظة نقاط الولاء والكاش باك - رنتيسي" />

    <StoreLayout>
        <div class="min-h-screen py-10 bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100">
            <div class="max-w-6xl mx-auto px-4 sm:px-6">
                <!-- Page Title -->
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
                    <div>
                        <h1 class="text-2xl sm:text-3xl font-black tracking-tight flex items-center gap-3">
                            <span class="p-2.5 rounded-2xl bg-amber-500/10 text-amber-500 border border-amber-500/20">
                                <Coins class="w-7 h-7" />
                            </span>
                            محفظة مكافآت الولاء والكاش باك (Rentisy Rewards)
                        </h1>
                        <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
                            اكسب كاش باك ونقاطاً حقيقية مع كل عملية شراء، واستبدلها بخصومات مالية فورية عند الدفع
                        </p>
                    </div>

                    <Link
                        :href="route('store.shop')"
                        class="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-lg shadow-indigo-500/20 transition"
                    >
                        <ShoppingBag class="w-4 h-4" />
                        تسوق الآن واكسب المزيد
                    </Link>
                </div>

                <!-- Main Hero Grid (Balance & VIP Tier) -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
                    <!-- Points & Cash Value Card -->
                    <div class="md:col-span-2 relative overflow-hidden bg-gradient-to-br from-indigo-900 via-indigo-800 to-purple-900 text-white rounded-3xl p-6 sm:p-8 shadow-2xl border border-indigo-700/50">
                        <div class="absolute -end-10 -bottom-10 w-60 h-60 bg-purple-500/20 rounded-full blur-3xl pointer-events-none"></div>
                        <div class="relative z-10">
                            <div class="flex items-center justify-between">
                                <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-md rounded-full text-xs font-bold text-amber-300">
                                    <Sparkles class="w-3.5 h-3.5" />
                                    رصيد الكاش باك المتاح للاستبدال
                                </div>
                                <span class="text-xs font-medium text-indigo-200">10 نقاط = 1 ₪ كاش باك</span>
                            </div>

                            <div class="mt-6 flex flex-wrap items-baseline gap-4">
                                <div class="text-4xl sm:text-5xl font-black tracking-tight text-white">
                                    {{ points }} <span class="text-xl sm:text-2xl font-bold text-indigo-200">نقطة</span>
                                </div>
                                <div class="text-2xl sm:text-3xl font-black text-amber-400">
                                    ≈ {{ cashValue }} ₪ <span class="text-xs font-normal text-amber-200/80">رصيد مالي</span>
                                </div>
                            </div>

                            <!-- Next Tier Progress -->
                            <div class="mt-8 pt-6 border-t border-indigo-700/60">
                                <div class="flex justify-between text-xs font-semibold mb-2">
                                    <span>التقدم نحو ترقية المستوى التالي</span>
                                    <span>{{ points }} / {{ nextTierTarget }} نقطة</span>
                                </div>
                                <div class="w-full h-3 bg-indigo-950/60 rounded-full overflow-hidden p-0.5 border border-indigo-600/40">
                                    <div 
                                        class="h-full bg-gradient-to-r from-amber-400 to-emerald-400 rounded-full transition-all duration-500"
                                        :style="`width: ${Math.min(100, (points / nextTierTarget) * 100)}%;`"
                                    ></div>
                                </div>
                                <div class="text-[11px] text-indigo-200 mt-2 flex items-center gap-1.5">
                                    <Zap class="w-3.5 h-3.5 text-amber-400" />
                                    <span>المتبقي لك {{ Math.max(0, nextTierTarget - points) }} نقطة للوصول إلى المستوى القادم والحصول على نسبة كاش باك أعلى وميزات مضاعفة!</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Current VIP Tier Status Card -->
                    <div class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl p-6 shadow-xl flex flex-col justify-between">
                        <div>
                            <div class="flex items-center justify-between mb-4">
                                <div class="text-xs font-bold text-slate-400 uppercase tracking-wider">مستوى عضويتك الحالي</div>
                                <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                                    <Crown class="w-5 h-5" />
                                </div>
                            </div>

                            <div class="text-2xl font-black text-slate-900 dark:text-white capitalize flex items-center gap-2">
                                <span>{{ tier === 'diamond' ? 'VIP Diamond 💎' : (tier === 'gold' ? 'Gold Tier 🥇' : (tier === 'silver' ? 'Silver Tier 🥈' : 'Bronze Tier 🥉')) }}</span>
                            </div>

                            <div class="mt-4 space-y-2 text-xs text-slate-600 dark:text-slate-300">
                                <div class="flex items-center gap-2">
                                    <ShieldCheck class="w-4 h-4 text-emerald-500" />
                                    <span>نسبة كاش باك: <strong class="text-slate-900 dark:text-white">{{ cashbackRate }}</strong> على كل طلب</span>
                                </div>
                                <div class="flex items-center gap-2">
                                    <ShieldCheck class="w-4 h-4 text-emerald-500" />
                                    <span>استبدال فوري عند صفحة الدفع بنقرة واحدة</span>
                                </div>
                                <div class="flex items-center gap-2">
                                    <ShieldCheck class="w-4 h-4 text-emerald-500" />
                                    <span>كفالة ذهبية ودعم فني مخصص</span>
                                </div>
                            </div>
                        </div>

                        <div class="mt-6 pt-4 border-t border-slate-100 dark:border-slate-800 text-[11px] text-slate-400">
                            يتم احتساب النقاط تلقائياً على كل طلب مؤكد من المتجر.
                        </div>
                    </div>
                </div>

                <!-- Referral Program & Invite Friends (Viral Growth) -->
                <div class="bg-gradient-to-r from-emerald-900/90 via-teal-900/90 to-slate-900 text-white rounded-3xl p-6 sm:p-8 shadow-xl border border-emerald-700/40 mb-10">
                    <div class="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
                        <div class="max-w-xl">
                            <div class="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-500/20 text-emerald-300 rounded-full text-xs font-bold mb-2">
                                <Gift class="w-3.5 h-3.5" />
                                برنامج شارك واكسب رصيداً فورياً
                            </div>
                            <h3 class="text-xl font-black text-white">ادعُ أصدقاءك واكسب 50 نقطة كاش باك عن كل صديق يسجل ويطلب!</h3>
                            <p class="text-xs text-emerald-100/80 mt-1.5 leading-relaxed">
                                شارك كود أو رابط الإحالة الخاص بك، وسيحصل صديقك على كاش باك ترحيبي وتحصل أنت على 50 نقطة مكافأة فورية في محفظتك.
                            </p>
                        </div>

                        <div class="w-full lg:w-auto flex flex-col sm:flex-row items-center gap-3">
                            <!-- Link Box -->
                            <div class="w-full sm:w-80 bg-slate-950/60 border border-emerald-500/30 rounded-2xl px-3.5 py-2.5 flex items-center justify-between gap-2">
                                <span class="text-xs text-emerald-200 font-mono truncate">{{ referralUrl }}</span>
                                <button
                                    @click="copyReferral"
                                    class="p-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl transition shrink-0"
                                    title="نسخ الرابط"
                                >
                                    <Check v-if="copied" class="w-4 h-4 text-white" />
                                    <Copy v-else class="w-4 h-4" />
                                </button>
                            </div>

                            <!-- WhatsApp Share -->
                            <button
                                @click="shareWhatsApp"
                                class="w-full sm:w-auto px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs rounded-2xl shadow flex items-center justify-center gap-2 transition"
                            >
                                <MessageCircle class="w-4 h-4" />
                                مشاركة عبر واتساب
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Points Transaction Log -->
                <div class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl p-6 sm:p-8 shadow-xl">
                    <h3 class="text-base font-black text-slate-900 dark:text-white mb-6 flex items-center gap-2">
                        <span>سجل حركات المكافآت والنقاط</span>
                        <span class="text-xs font-normal text-slate-400">({{ transactions.length }} حركة)</span>
                    </h3>

                    <div v-if="transactions.length === 0" class="py-12 text-center text-slate-400">
                        <Coins class="w-10 h-10 mx-auto mb-2 opacity-40" />
                        <p class="text-xs">لا توجد حركات نقاط سابقة حتى الآن.</p>
                    </div>

                    <div v-else class="divide-y divide-slate-100 dark:divide-slate-800">
                        <div 
                            v-for="tx in transactions" 
                            :key="tx.id" 
                            class="py-4 flex items-center justify-between gap-4"
                        >
                            <div class="flex items-center gap-3">
                                <div 
                                    :class="[
                                        tx.points > 0 
                                            ? 'bg-emerald-500/10 text-emerald-500 border border-emerald-500/20' 
                                            : 'bg-rose-500/10 text-rose-500 border border-rose-500/20'
                                    ]"
                                    class="p-2.5 rounded-2xl"
                                >
                                    <ArrowDownLeft v-if="tx.points > 0" class="w-4 h-4" />
                                    <ArrowUpRight v-else class="w-4 h-4" />
                                </div>
                                <div>
                                    <div class="text-xs font-bold text-slate-900 dark:text-white">{{ tx.description }}</div>
                                    <div class="text-[11px] text-slate-400 mt-0.5">{{ new Date(tx.created_at).toLocaleDateString('ar-EG') }}</div>
                                </div>
                            </div>

                            <div 
                                :class="[
                                    tx.points > 0 
                                        ? 'text-emerald-600 dark:text-emerald-400' 
                                        : 'text-rose-600 dark:text-rose-400'
                                ]"
                                class="text-sm font-black text-end"
                            >
                                {{ tx.points > 0 ? '+' : '' }}{{ tx.points }} نقطة
                                <div class="text-[10px] text-slate-400 font-normal">
                                    {{ tx.points > 0 ? '+' : '' }}{{ (tx.points / 10).toFixed(2) }} ₪
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
