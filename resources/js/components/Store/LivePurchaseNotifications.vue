<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ShoppingBag, X, Flame } from 'lucide-vue-next'

const isVisible = ref(false)
const currentPurchase = ref<any>(null)
let intervalId: any = null

const purchaseFeed = [
    { city: 'رام الله', product: 'Apple MacBook Pro M3 Max 16"', time: 'منذ 4 دقائق', price: '12,900 ₪', image: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=150' },
    { city: 'غزة', product: 'سماعات Sony WH-1000XM5 العازلة للضوضاء', time: 'منذ 11 دقيقة', price: '1,190 ₪', image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=150' },
    { city: 'الخليل', product: 'Lenovo ThinkPad X1 Carbon Gen 11', time: 'منذ 18 دقيقة', price: '6,800 ₪', image: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=150' },
    { city: 'نابلس', product: 'Apple iPhone 16 Pro Max 256GB', time: 'منذ 25 دقيقة', price: '5,450 ₪', image: 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=150' },
    { city: 'بيت لحم', product: 'شاشة LG 27" UltraFine 4K IPS', time: 'منذ 34 دقيقة', price: '1,750 ₪', image: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=150' },
    { city: 'جنين', product: 'فأرة Logitech MX Master 3S اللاسلكية', time: 'منذ 42 دقيقة', price: '390 ₪', image: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=150' },
]

let feedIndex = 0

const triggerNotification = () => {
    currentPurchase.value = purchaseFeed[feedIndex % purchaseFeed.length]
    feedIndex++
    isVisible.value = true

    setTimeout(() => {
        isVisible.value = false
    }, 6500)
}

onMounted(() => {
    // Initial delay then repeat every 20 seconds
    setTimeout(() => {
        triggerNotification()
        intervalId = setInterval(triggerNotification, 22000)
    }, 4000)
})

onUnmounted(() => {
    if (intervalId) clearInterval(intervalId)
})
</script>

<template>
    <Transition
        enter-active-class="transition duration-500 ease-out"
        enter-from-class="transform opacity-0 translate-y-6 sm:translate-y-0 sm:-translate-x-6"
        enter-to-class="transform opacity-100 translate-y-0 sm:translate-x-0"
        leave-active-class="transition duration-300 ease-in"
        leave-from-class="transform opacity-100 translate-y-0 sm:translate-x-0"
        leave-to-class="transform opacity-0 translate-y-6 sm:translate-y-0 sm:-translate-x-6"
    >
        <div 
            v-if="isVisible && currentPurchase"
            class="fixed bottom-24 start-6 z-40 max-w-sm bg-white/95 dark:bg-slate-900/95 border border-slate-200/80 dark:border-slate-800 rounded-2xl shadow-2xl backdrop-blur-xl p-3 flex items-center gap-3 text-start"
        >
            <img 
                :src="currentPurchase.image" 
                class="w-12 h-12 rounded-xl object-cover bg-slate-100 dark:bg-slate-800 shrink-0 border border-slate-100 dark:border-slate-800" 
            />
            <div class="flex-1 min-w-0">
                <div class="flex items-center gap-1.5 text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                    <Flame class="w-3.5 h-3.5 fill-rose-500 text-rose-500" />
                    <span>طلب جديد من {{ currentPurchase.city }}</span>
                    <span class="text-slate-400 text-[10px]">({{ currentPurchase.time }})</span>
                </div>
                <h5 class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate mt-0.5">{{ currentPurchase.product }}</h5>
                <span class="text-[11px] font-black text-indigo-600 dark:text-indigo-400">{{ currentPurchase.price }}</span>
            </div>
            <button 
                @click="isVisible = false"
                class="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
            >
                <X class="w-3.5 h-3.5" />
            </button>
        </div>
    </Transition>
</template>
