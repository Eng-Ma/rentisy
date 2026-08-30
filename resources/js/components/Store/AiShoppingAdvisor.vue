<script setup lang="ts">
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { 
    Sparkles, 
    X, 
    Send, 
    ShoppingBag, 
    Check, 
    ArrowRight,
    SlidersHorizontal,
    Zap,
    Scale
} from 'lucide-vue-next'

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
    userPrompt.value = p.prompt
    selectedUseCase.value = p.useCase
    maxPrice.value = p.maxPrice
    getAdvice()
}

const getAdvice = async () => {
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
            class="group relative flex items-center gap-3 px-5 py-3.5 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white rounded-full shadow-2xl hover:shadow-indigo-500/40 hover:scale-105 transition-all duration-300 active:scale-95"
        >
            <span class="absolute -top-1 -end-1 flex h-3.5 w-3.5">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
            </span>
            <Sparkles class="w-5 h-5 animate-pulse text-amber-300" />
            <span class="font-bold text-sm">مستشار المشتريات الذكي AI</span>
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
                <div class="p-4 bg-gradient-to-r from-indigo-600 to-purple-600 text-white flex items-center justify-between">
                    <div class="flex items-center gap-2.5">
                        <div class="p-2 bg-white/15 rounded-xl backdrop-blur-md">
                            <Sparkles class="w-5 h-5 text-amber-300" />
                        </div>
                        <div>
                            <h3 class="font-bold text-sm">المستشار التقني والمالي الذكي</h3>
                            <p class="text-xs text-indigo-100">يرشح لك المنتجات المناسبة لميزانيتك واحتياجك</p>
                        </div>
                    </div>
                    <button @click="isOpen = false" class="p-1.5 hover:bg-white/20 rounded-lg text-white/80 hover:text-white transition">
                        <X class="w-5 h-5" />
                    </button>
                </div>

                <!-- Body -->
                <div class="p-4 overflow-y-auto flex-1 space-y-4 text-sm">
                    <!-- Quick Presets -->
                    <div>
                        <div class="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-2">أفكار وبحث سريع:</div>
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

                <!-- Footer -->
                <div class="p-3 bg-slate-50 dark:bg-slate-900/80 border-t border-slate-100 dark:border-slate-800 text-center">
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
