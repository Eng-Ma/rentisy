<script setup lang="ts">
import { ref, computed } from 'vue'
import { router } from '@inertiajs/vue3'
import { 
    Scale, 
    X, 
    ShoppingBag, 
    Check, 
    Star, 
    ShieldCheck, 
    Zap,
    Trash2
} from 'lucide-vue-next'

const props = defineProps<{
    show: boolean
    items: any[]
}>()

const emit = defineEmits(['close', 'remove', 'clear'])

const addedId = ref<number | null>(null)

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
    <Transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition duration-200 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
    >
        <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto bg-slate-900/70 backdrop-blur-md flex items-center justify-center p-4">
            <div class="relative w-full max-w-5xl bg-white dark:bg-slate-900 rounded-3xl shadow-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col max-h-[90vh]">
                <!-- Modal Header -->
                <div class="p-6 bg-gradient-to-r from-slate-900 to-indigo-950 text-white flex items-center justify-between border-b border-slate-800">
                    <div class="flex items-center gap-3">
                        <div class="p-2.5 bg-indigo-500/20 text-indigo-400 rounded-2xl border border-indigo-500/30">
                            <Scale class="w-6 h-6" />
                        </div>
                        <div>
                            <h2 class="text-lg font-black tracking-tight">مقارنة المنتجات والمواصفات المباشرة</h2>
                            <p class="text-xs text-slate-400">مقارنة تفصيلية جنباً إلى جنب لمساعدتك في اتخاذ القرار الأنسب</p>
                        </div>
                    </div>
                    <div class="flex items-center gap-3">
                        <button 
                            v-if="items.length > 0"
                            @click="emit('clear')"
                            class="text-xs text-rose-400 hover:text-rose-300 flex items-center gap-1 font-medium transition"
                        >
                            <Trash2 class="w-3.5 h-3.5" />
                            مسح المقارنة
                        </button>
                        <button 
                            @click="emit('close')"
                            class="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-white/10 transition"
                        >
                            <X class="w-5 h-5" />
                        </button>
                    </div>
                </div>

                <!-- Modal Body (Comparison Matrix) -->
                <div class="p-6 overflow-x-auto flex-1">
                    <div v-if="items.length === 0" class="py-16 text-center text-slate-400">
                        <Scale class="w-12 h-12 mx-auto mb-3 opacity-40" />
                        <p class="text-sm font-medium">لم يتم اختيار أي منتجات للمقارنة بعد.</p>
                        <p class="text-xs text-slate-500 mt-1">اضغط على زر (مقارنة) في أي بطاقة منتج للمقارنة الفورية.</p>
                    </div>

                    <div v-else class="grid" :style="`grid-template-columns: 180px repeat(${items.length}, minmax(220px, 1fr));`">
                        <!-- Header Row (Product Cards) -->
                        <div class="p-3 font-bold text-xs text-slate-400 self-center">المنتج</div>
                        <div 
                            v-for="item in items" 
                            :key="item.id" 
                            class="p-4 border-s border-slate-100 dark:border-slate-800 text-center relative flex flex-col items-center"
                        >
                            <button 
                                @click="emit('remove', item.id)"
                                class="absolute top-2 end-2 p-1 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                                title="إزالة من المقارنة"
                            >
                                <X class="w-4 h-4" />
                            </button>
                            <img 
                                :src="item.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300'" 
                                class="w-24 h-24 object-cover rounded-2xl mb-3 shadow-sm bg-slate-100 dark:bg-slate-800" 
                            />
                            <h4 class="font-bold text-xs text-slate-800 dark:text-slate-200 line-clamp-2 min-h-[32px]">{{ item.name }}</h4>
                            <div class="mt-2 mb-3">
                                <span class="text-base font-black text-indigo-600 dark:text-indigo-400">{{ item.effective_price }} ₪</span>
                                <span v-if="item.is_deal" class="text-xs line-through text-slate-400 ms-2">{{ item.sales_price }} ₪</span>
                            </div>
                            <button
                                @click="addToCart(item)"
                                :class="[
                                    addedId === item.id 
                                        ? 'bg-emerald-500 text-white' 
                                        : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                                ]"
                                class="w-full py-2 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 shadow-md shadow-indigo-500/20 transition active:scale-95"
                            >
                                <Check v-if="addedId === item.id" class="w-3.5 h-3.5" />
                                <ShoppingBag v-else class="w-3.5 h-3.5" />
                                <span>{{ addedId === item.id ? 'تمت الإضافة' : 'إضافة للسلة' }}</span>
                            </button>
                        </div>

                        <!-- Price Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">السعر النهائي</div>
                        <div 
                            v-for="item in items" 
                            :key="'price-' + item.id" 
                            class="p-3 text-xs font-bold text-center border-t border-s border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30"
                        >
                            {{ item.effective_price }} ₪
                        </div>

                        <!-- Category Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800">التصنيف</div>
                        <div 
                            v-for="item in items" 
                            :key="'cat-' + item.id" 
                            class="p-3 text-xs text-center border-t border-s border-slate-100 dark:border-slate-800 text-slate-700 dark:text-slate-300"
                        >
                            {{ item.category?.name || 'عام' }}
                        </div>

                        <!-- Rating Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">التقييم والمراجعات</div>
                        <div 
                            v-for="item in items" 
                            :key="'rating-' + item.id" 
                            class="p-3 text-xs text-center border-t border-s border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30"
                        >
                            <div class="flex items-center justify-center gap-1 text-amber-500 font-bold">
                                <Star class="w-3.5 h-3.5 fill-amber-500" />
                                <span>{{ item.rating || '4.8' }}</span>
                                <span class="text-[10px] text-slate-400 font-normal">({{ item.reviews_count || 45 }})</span>
                            </div>
                        </div>

                        <!-- Stock Status Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800">حالة المخزون الفعلي</div>
                        <div 
                            v-for="item in items" 
                            :key="'stock-' + item.id" 
                            class="p-3 text-xs text-center border-t border-s border-slate-100 dark:border-slate-800 font-semibold text-emerald-600 dark:text-emerald-400"
                        >
                            <span class="inline-flex items-center gap-1">
                                <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                                متوفر في المستودع المركزي
                            </span>
                        </div>

                        <!-- Warranty Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">الضمان والكفالة</div>
                        <div 
                            v-for="item in items" 
                            :key="'warranty-' + item.id" 
                            class="p-3 text-xs text-center border-t border-s border-slate-100 dark:border-slate-800 text-slate-700 dark:text-slate-300 bg-slate-50/50 dark:bg-slate-800/30"
                        >
                            <span class="inline-flex items-center gap-1 text-indigo-600 dark:text-indigo-400 font-medium">
                                <ShieldCheck class="w-3.5 h-3.5" />
                                ضمان رسمي 12-24 شهر
                            </span>
                        </div>

                        <!-- Description Row -->
                        <div class="p-3 font-semibold text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800">أبرز المزايا</div>
                        <div 
                            v-for="item in items" 
                            :key="'desc-' + item.id" 
                            class="p-3 text-xs border-t border-s border-slate-100 dark:border-slate-800 text-slate-600 dark:text-slate-400 leading-relaxed"
                        >
                            {{ item.description || 'أداء عالي وجودة معتمدة تلبي كافة الاستخدامات.' }}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </Transition>
</template>
