<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Head, Link, useForm } from '@inertiajs/vue3'
import StoreLayout from '@/layouts/StoreLayout.vue'
import {
    ShieldCheck,
    Truck,
    Building2,
    CheckCircle2,
    Lock,
    ArrowRight,
    LoaderCircle,
    Store,
    MapPin,
    Upload,
    Image,
    Coins,
    Sparkles,
    Plus,
    X,
    QrCode,
    Check,
    CreditCard,
    AlertCircle
} from 'lucide-vue-next'

interface CartItem {
    id: number
    quantity: number
    item?: {
        id: number
        name: string
        image?: string
        effective_price: number
    }
}

interface DeliveryZone {
    id: number
    name: string
    city: string
    delivery_fee: number
    estimated_time: string
}

interface TransferMethod {
    id: number
    name: string
    account_name?: string
    account_number?: string
    iban?: string
    phone?: string
    instructions?: string
    logo_url?: string
    is_active: boolean
    sort_order: number
}

interface Props {
    cartItems: CartItem[]
    deliveryZones: DeliveryZone[]
    transferMethods: TransferMethod[]
    remainingSuggestions: number
    summary: {
        subtotal: number
        shippingFee: number
        total: number
        itemsCount: number
    }
    customer: {
        name: string
        email: string
        phone: string
        address: string
        city: string
        points_balance?: number
    }
    storeContext?: {
        cartCount?: number
        wishlistIds?: number[]
    }
}

const props = defineProps<Props>()

// Form State
const form = useForm({
    name: props.customer.name || '',
    email: props.customer.email || '',
    phone: props.customer.phone || '',
    address: props.customer.address || '',
    city: props.customer.city || 'غزة',
    delivery_type: 'delivery', // delivery, pickup
    delivery_zone_id: props.deliveryZones[0]?.id || null,
    transfer_method_id: props.transferMethods[0]?.id || null,
    payment_receipt: null as File | null,
    redeem_points: false,
    notes: '',
})

// Suggestion Modal State
const isSuggestModalOpen = ref(false)
const suggestForm = ref({
    name: '',
    city: props.customer.city || 'غزة',
    notes: '',
})
const isSuggesting = ref(false)
const suggestSuccessMessage = ref('')
const suggestErrorMessage = ref('')
const remainingSuggestionsCount = ref(props.remainingSuggestions ?? 2)

// Receipt Preview
const receiptPreviewUrl = ref<string | null>(null)

const onReceiptSelected = (event: Event) => {
    const target = event.target as HTMLInputElement
    if (target.files && target.files[0]) {
        const file = target.files[0]
        form.payment_receipt = file
        receiptPreviewUrl.value = URL.createObjectURL(file)
    }
}

// Dynamic Calculations
const selectedZone = computed(() => {
    return props.deliveryZones.find(z => z.id === Number(form.delivery_zone_id))
})

const selectedMethod = computed(() => {
    return props.transferMethods.find(m => m.id === Number(form.transfer_method_id)) || props.transferMethods[0]
})

const currentShippingFee = computed(() => {
    if (form.delivery_type === 'pickup') return 0.00
    if (selectedZone.value) return Number(selectedZone.value.delivery_fee)
    return props.summary.subtotal > 200 ? 0.00 : 20.00
})

const pointsDiscount = computed(() => {
    if (!form.redeem_points || !props.customer.points_balance) return 0
    const maxDiscount = props.summary.subtotal * 0.5
    const pointsValue = props.customer.points_balance / 10
    return Math.min(pointsValue, maxDiscount)
})

const finalTotal = computed(() => {
    const total = props.summary.subtotal + currentShippingFee.value - pointsDiscount.value
    return Math.max(0, total)
})

const submitOrder = () => {
    form.post(route('checkout.process'), {
        forceFormData: true,
    })
}

const submitSuggestion = async () => {
    if (!suggestForm.value.name) return
    isSuggesting.value = true
    suggestSuccessMessage.value = ''
    suggestErrorMessage.value = ''

    try {
        const res = await fetch(route('store.suggest_zone'), {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': (document.querySelector('meta[name="csrf-token"]') as any)?.content || '',
                'Accept': 'application/json'
            },
            body: JSON.stringify(suggestForm.value)
        })

        const data = await res.json()
        if (res.ok && data.status === 'success') {
            suggestSuccessMessage.value = data.message
            remainingSuggestionsCount.value = data.remaining_suggestions
            setTimeout(() => {
                isSuggestModalOpen.value = false
                suggestSuccessMessage.value = ''
            }, 3000)
        } else {
            suggestErrorMessage.value = data.message || 'حدث خطأ أثناء إرسال الاقتراح.'
        }
    } catch (e: any) {
        suggestErrorMessage.value = 'حدث خطأ في الاتصال بالخادم.'
    } finally {
        isSuggesting.value = false
    }
}
</script>

<template>
    <StoreLayout title="إتمام الطلب والدفع | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <div class="mb-8">
                <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">إتمام الطلب والتحويل المالي</h1>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                    اختر طريقة وحساب التحويل المعتمد، وقم بتحويل المبلغ وأرفق سكرين شوت إشعار التحويل لتأكيد طلبك وتوليد الفاتورة المحاسبية فوراً
                </p>
            </div>

            <form @submit.prevent="submitOrder" class="grid grid-cols-1 lg:grid-cols-12 gap-8">
                <!-- Shipping & Payment Form (8 Columns) -->
                <div class="lg:col-span-8 space-y-6">
                    
                    <!-- STEP 1: Delivery Mode (توصيل أم استلام) -->
                    <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <div class="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
                            <div class="w-8 h-8 rounded-full bg-emerald-600 text-white font-bold flex items-center justify-center text-xs">
                                1
                            </div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">
                                طريقة استلام الطلب
                            </h3>
                        </div>

                        <!-- Delivery / Pickup Switcher -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <!-- Delivery Option -->
                            <label 
                                class="p-4 rounded-2xl border-2 cursor-pointer transition-all flex items-center gap-4"
                                :class="form.delivery_type === 'delivery' ? 'border-emerald-600 bg-emerald-50/50 dark:bg-emerald-950/40 ring-2 ring-emerald-500/20' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <input type="radio" value="delivery" v-model="form.delivery_type" class="text-emerald-600" />
                                <div class="p-3 bg-emerald-500/10 text-emerald-600 rounded-xl shrink-0">
                                    <Truck class="w-6 h-6" />
                                </div>
                                <div class="text-start">
                                    <h4 class="text-xs font-bold text-slate-900 dark:text-white">توصيل إلى العنوان</h4>
                                    <p class="text-[11px] text-slate-500 mt-0.5">شحن آمن إلى باب منزلك أو مكان عملك</p>
                                </div>
                            </label>

                            <!-- Pickup Option -->
                            <label 
                                class="p-4 rounded-2xl border-2 cursor-pointer transition-all flex items-center gap-4"
                                :class="form.delivery_type === 'pickup' ? 'border-emerald-600 bg-emerald-50/50 dark:bg-emerald-950/40 ring-2 ring-emerald-500/20' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <input type="radio" value="pickup" v-model="form.delivery_type" class="text-emerald-600" />
                                <div class="p-3 bg-indigo-500/10 text-indigo-600 rounded-xl shrink-0">
                                    <Store class="w-6 h-6" />
                                </div>
                                <div class="text-start">
                                    <div class="flex items-center gap-2">
                                        <h4 class="text-xs font-bold text-slate-900 dark:text-white">استلام من المعرض / المستودع</h4>
                                        <span class="text-[10px] font-black px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300">مجاني 0 ₪</span>
                                    </div>
                                    <p class="text-[11px] text-slate-500 mt-0.5">الاستلام المباشر من مقر الشركة والمستودع الرئيسي</p>
                                </div>
                            </label>
                        </div>

                        <!-- Customer Details Inputs -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-slate-100 dark:border-slate-800">
                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">الاسم الكامل *</label>
                                <input
                                    type="text"
                                    v-model="form.name"
                                    required
                                    placeholder="مثال: أحمد محمد"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 outline-none"
                                />
                                <span v-if="form.errors.name" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.name }}</span>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">رقم الهاتف / الجوال *</label>
                                <input
                                    type="tel"
                                    v-model="form.phone"
                                    required
                                    placeholder="0599000000"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 outline-none"
                                />
                                <span v-if="form.errors.phone" class="text-[11px] text-rose-500 mt-1 block">{{ form.errors.phone }}</span>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">البريد الإلكتروني *</label>
                                <input
                                    type="email"
                                    v-model="form.email"
                                    required
                                    placeholder="example@domain.com"
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 outline-none"
                                />
                            </div>

                            <!-- Delivery Zone Selector (Shown if delivery is chosen) -->
                            <div v-if="form.delivery_type === 'delivery'">
                                <div class="flex items-center justify-between mb-1.5">
                                    <label class="block text-xs font-bold text-slate-700 dark:text-slate-300">منطقة التوصيل المحددة *</label>
                                    <button 
                                        type="button" 
                                        @click="isSuggestModalOpen = true"
                                        class="text-[11px] font-bold text-indigo-600 hover:text-indigo-700 dark:text-indigo-400 flex items-center gap-1"
                                    >
                                        <Plus class="w-3.5 h-3.5" />
                                        اقترح منطقة جديدة
                                    </button>
                                </div>
                                <select
                                    v-model="form.delivery_zone_id"
                                    required
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-bold text-slate-800 dark:text-slate-200 focus:ring-2 focus:ring-emerald-500 outline-none"
                                >
                                    <option v-for="zone in deliveryZones" :key="zone.id" :value="zone.id">
                                        {{ zone.name }} — سعر التوصيل: {{ zone.delivery_fee }} ₪ ({{ zone.estimated_time }})
                                    </option>
                                </select>
                            </div>

                            <!-- Detailed Address (Shown if delivery is chosen) -->
                            <div v-if="form.delivery_type === 'delivery'" class="sm:col-span-2">
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">العنوان التفصيلي (الشارع، الحي، أقرب معلم) *</label>
                                <textarea
                                    v-model="form.address"
                                    required
                                    rows="2"
                                    placeholder="الشارع الرئيسي، عمارة أو معلم بارز..."
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 outline-none"
                                ></textarea>
                            </div>

                            <div class="sm:col-span-2">
                                <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">ملاحظات إضافية للتوصيل (اختياري)</label>
                                <input
                                    type="text"
                                    v-model="form.notes"
                                    placeholder="أوقات التوصيل أو تعليمات خاصة..."
                                    class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500 outline-none"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- STEP 2: Transfer Payment Method (Dynamic Admin Transfer Methods) -->
                    <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                        <div class="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
                            <div class="w-8 h-8 rounded-full bg-indigo-600 text-white font-bold flex items-center justify-center text-xs">
                                2
                            </div>
                            <div>
                                <h3 class="text-base font-bold text-slate-900 dark:text-white">
                                    طريقة وحساب التحويل المالي (تحويل بنكي / محفظة)
                                </h3>
                                <p class="text-[11px] text-slate-500">اختر الحساب المناسب لك وقم بالتحويل ثم ارفع سكرين شوت الإشعار</p>
                            </div>
                        </div>

                        <!-- Dynamic Transfer Methods Cards with Logos -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <label
                                v-for="method in transferMethods"
                                :key="method.id"
                                class="p-4 rounded-2xl border-2 cursor-pointer transition-all flex items-center gap-3 relative"
                                :class="form.transfer_method_id === method.id ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 ring-2 ring-indigo-500/30' : 'border-slate-200 dark:border-slate-800 hover:border-slate-300'"
                            >
                                <input type="radio" :value="method.id" v-model="form.transfer_method_id" class="text-indigo-600" />
                                
                                <div class="w-12 h-12 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 overflow-hidden flex items-center justify-center shrink-0 shadow-sm">
                                    <img v-if="method.logo_url" :src="method.logo_url" :alt="method.name" class="w-full h-full object-cover" />
                                    <Building2 v-else class="w-6 h-6 text-indigo-500" />
                                </div>

                                <div class="text-start flex-1 min-w-0">
                                    <h4 class="text-xs font-bold text-slate-900 dark:text-white line-clamp-1">{{ method.name }}</h4>
                                    <p class="text-[11px] text-slate-500 line-clamp-1 mt-0.5">{{ method.account_name || 'حساب معتمد' }}</p>
                                </div>
                            </label>
                        </div>

                        <span v-if="form.errors.transfer_method_id" class="text-[11px] text-rose-500 block">{{ form.errors.transfer_method_id }}</span>

                        <!-- Selected Transfer Method Details Box -->
                        <div v-if="selectedMethod" class="p-6 rounded-2xl bg-gradient-to-br from-indigo-50/80 to-slate-50 dark:from-indigo-950/40 dark:to-slate-900 border-2 border-indigo-200 dark:border-indigo-900 space-y-4">
                            <div class="flex items-center gap-3 pb-3 border-b border-indigo-200/60 dark:border-indigo-900/60">
                                <div class="w-10 h-10 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 overflow-hidden flex items-center justify-center shrink-0 shadow-sm">
                                    <img v-if="selectedMethod.logo_url" :src="selectedMethod.logo_url" class="w-full h-full object-cover" />
                                    <Building2 v-else class="w-5 h-5 text-indigo-600" />
                                </div>
                                <div>
                                    <h4 class="font-bold text-xs text-indigo-950 dark:text-indigo-200">بيانات التحويل لحساب: {{ selectedMethod.name }}</h4>
                                    <p class="text-[11px] text-slate-500">قم بتحويل المبلغ المطلوب ({{ finalTotal.toFixed(2) }} ₪) إلى البيانات أدناه</p>
                                </div>
                            </div>

                            <!-- Account Attributes -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                                <div v-if="selectedMethod.account_name" class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100 dark:border-slate-700 space-y-0.5">
                                    <span class="text-[11px] text-slate-400 font-bold block">اسم المستفيد:</span>
                                    <strong class="text-slate-900 dark:text-white">{{ selectedMethod.account_name }}</strong>
                                </div>

                                <div v-if="selectedMethod.account_number" class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100 dark:border-slate-700 space-y-0.5">
                                    <span class="text-[11px] text-slate-400 font-bold block">رقم الحساب / كود التاجر:</span>
                                    <strong class="text-slate-900 dark:text-white font-mono">{{ selectedMethod.account_number }}</strong>
                                </div>

                                <div v-if="selectedMethod.iban" class="sm:col-span-2 p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100 dark:border-slate-700 space-y-0.5">
                                    <span class="text-[11px] text-slate-400 font-bold block">رقم الآيبان IBAN:</span>
                                    <strong class="text-indigo-600 dark:text-indigo-400 font-mono break-all">{{ selectedMethod.iban }}</strong>
                                </div>

                                <div v-if="selectedMethod.phone" class="p-3 bg-white dark:bg-slate-800 rounded-xl border border-indigo-100 dark:border-slate-700 space-y-0.5">
                                    <span class="text-[11px] text-slate-400 font-bold block">رقم الجوال / المحفظة:</span>
                                    <strong class="text-slate-900 dark:text-white font-mono">{{ selectedMethod.phone }}</strong>
                                </div>
                            </div>

                            <!-- Admin Custom Instructions / Notes Box -->
                            <div v-if="selectedMethod.instructions" class="p-4 rounded-xl bg-amber-50/70 dark:bg-amber-950/30 border border-amber-200/80 dark:border-amber-900/60 text-xs text-amber-950 dark:text-amber-200 space-y-1">
                                <span class="font-bold flex items-center gap-1.5 text-amber-800 dark:text-amber-300">
                                    <AlertCircle class="w-4 h-4" />
                                    ملاحظات وتعليمات هامة من الإدارة:
                                </span>
                                <p class="leading-relaxed text-[11px]">{{ selectedMethod.instructions }}</p>
                            </div>

                            <!-- Proof Screenshot Upload Input -->
                            <div class="space-y-2 pt-2">
                                <label class="block text-xs font-bold text-indigo-950 dark:text-indigo-200">
                                    أرفق سكرين شوت إشعار التحويل المالي (صورة الإشعار من تطبيق البنك أو المحفظة) *
                                </label>
                                
                                <div class="flex items-center gap-4">
                                    <label class="flex-1 cursor-pointer flex flex-col items-center justify-center p-4 border-2 border-dashed border-indigo-300 dark:border-indigo-700 rounded-2xl bg-white dark:bg-slate-800 hover:border-indigo-500 transition">
                                        <Upload class="w-6 h-6 text-indigo-600 mb-1" />
                                        <span class="text-xs font-bold text-slate-700 dark:text-slate-300">اضغط هنا لرفع صورة الإشعار (PNG, JPG, WEBP)</span>
                                        <span class="text-[10px] text-slate-400 mt-0.5">سيقوم الأدمن بفحص السكرين شوت ومطابقة الحساب لتأكيد الطلب فوراً</span>
                                        <input type="file" accept="image/*" @change="onReceiptSelected" class="hidden" required />
                                    </label>

                                    <!-- Thumbnail preview if uploaded -->
                                    <div v-if="receiptPreviewUrl" class="w-24 h-24 rounded-2xl overflow-hidden border-2 border-emerald-500 relative shrink-0 shadow-md">
                                        <img :src="receiptPreviewUrl" class="w-full h-full object-cover" />
                                        <span class="absolute bottom-1 right-1 px-1.5 py-0.5 rounded bg-emerald-600 text-white text-[9px] font-bold">تم الرفع ✓</span>
                                    </div>
                                </div>
                                <span v-if="form.errors.payment_receipt" class="text-[11px] text-rose-500 block">{{ form.errors.payment_receipt }}</span>
                            </div>
                        </div>

                        <!-- Loyalty Points Redemption Section -->
                        <div v-if="customer.points_balance && customer.points_balance > 0" class="p-4 rounded-2xl bg-amber-50/70 dark:bg-amber-950/30 border border-amber-200/80 dark:border-amber-900/60 flex items-center justify-between gap-4">
                            <div class="flex items-center gap-3">
                                <div class="p-2.5 rounded-xl bg-amber-500/10 text-amber-500">
                                    <Coins class="w-6 h-6" />
                                </div>
                                <div class="text-start">
                                    <h4 class="text-xs font-bold text-amber-950 dark:text-amber-200">
                                        استبدال نقاط الولاء (لديك {{ customer.points_balance }} نقطة ≈ {{ (customer.points_balance / 10).toFixed(2) }} ₪)
                                    </h4>
                                    <p class="text-[11px] text-amber-800/80 dark:text-amber-400/80">
                                        استبدل نقاطك بخصم مالي مباشر على هذا الطلب
                                    </p>
                                </div>
                            </div>
                            <label class="flex items-center gap-2 cursor-pointer font-bold text-xs text-amber-900 dark:text-amber-300">
                                <input type="checkbox" v-model="form.redeem_points" class="w-4 h-4 text-amber-600 rounded" />
                                <span>تطبيق الخصم</span>
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Order Review Sidebar (4 Columns) -->
                <div class="lg:col-span-4 space-y-6">
                    <div class="p-6 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-5">
                        <h3 class="text-base font-black text-slate-900 dark:text-white pb-3 border-b border-slate-100 dark:border-slate-800">
                            ملخص الطلب والحساب
                        </h3>

                        <!-- Items List Preview -->
                        <div class="space-y-3 max-h-56 overflow-y-auto pr-1">
                            <div
                                v-for="item in cartItems"
                                :key="item.id"
                                class="flex items-center justify-between text-xs py-2 border-b border-slate-50 dark:border-slate-800/60"
                            >
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 overflow-hidden shrink-0">
                                        <img :src="item.item?.image || 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200'" class="w-full h-full object-cover" />
                                    </div>
                                    <div>
                                        <h5 class="font-bold text-slate-900 dark:text-white line-clamp-1 max-w-[120px]">{{ item.item?.name }}</h5>
                                        <span class="text-[10px] text-slate-400">الكمية: {{ item.quantity }}</span>
                                    </div>
                                </div>
                                <span class="font-black text-slate-900 dark:text-white">
                                    {{ ((item.item?.effective_price || 0) * item.quantity).toFixed(2) }} ₪
                                </span>
                            </div>
                        </div>

                        <!-- Price Calculations Breakdown -->
                        <div class="space-y-2.5 text-xs pt-2">
                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>المجموع الفرعي:</span>
                                <span class="font-bold text-slate-900 dark:text-white">{{ summary.subtotal }} ₪</span>
                            </div>

                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>طريقة التحويل:</span>
                                <span class="font-bold text-indigo-600 dark:text-indigo-400 flex items-center gap-1.5">
                                    <img v-if="selectedMethod?.logo_url" :src="selectedMethod.logo_url" class="w-4 h-4 rounded object-cover" />
                                    <span>{{ selectedMethod?.name || 'تحويل' }}</span>
                                </span>
                            </div>

                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>نوع الاستلام / التوصيل:</span>
                                <span class="font-bold text-slate-900 dark:text-white">
                                    {{ form.delivery_type === 'pickup' ? 'استلام من المعرض (0 ₪)' : (selectedZone?.name || 'توصيل') }}
                                </span>
                            </div>

                            <div class="flex items-center justify-between text-slate-600 dark:text-slate-400">
                                <span>تكلفة التوصيل:</span>
                                <span v-if="currentShippingFee === 0" class="text-emerald-600 font-bold">مجاني 0 ₪</span>
                                <span v-else class="font-bold text-slate-900 dark:text-white">{{ currentShippingFee.toFixed(2) }} ₪</span>
                            </div>

                            <div v-if="pointsDiscount > 0" class="flex items-center justify-between text-amber-600 font-bold">
                                <span>خصم نقاط الكاش باك:</span>
                                <span>- {{ pointsDiscount.toFixed(2) }} ₪</span>
                            </div>

                            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-base">
                                <span class="font-black text-slate-900 dark:text-white">الإجمالي النهائي:</span>
                                <span class="font-black text-2xl text-emerald-600 dark:text-emerald-400">
                                    {{ finalTotal.toFixed(2) }} ₪
                                </span>
                            </div>
                        </div>

                        <!-- Submit Order Button -->
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="w-full py-4 px-6 rounded-2xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-xl shadow-indigo-600/25 transition-all hover:scale-[1.02]"
                        >
                            <LoaderCircle v-if="form.processing" class="w-5 h-5 animate-spin" />
                            <Lock v-else class="w-4 h-4" />
                            <span>تأكيد التحويل وإرسال الإشعار</span>
                        </button>
                    </div>

                    <!-- Security & Verification Badge -->
                    <div class="p-5 rounded-3xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800 text-xs text-slate-500 dark:text-slate-400 space-y-2">
                        <div class="flex items-center gap-1.5 font-bold text-slate-700 dark:text-slate-300">
                            <ShieldCheck class="w-4 h-4 text-emerald-500" />
                            <span>نظام الفحص والتحقق المحاسبي الآمن</span>
                        </div>
                        <p class="leading-relaxed">
                            يقوم النظام بمطابقة إشعار التحويل البنكي وتأكيد الفاتورة المحاسبية وحجز المخزون فوراً من المستودع المركزي.
                        </p>
                    </div>
                </div>
            </form>
        </div>

        <!-- Suggest New Delivery Zone Modal -->
        <div v-if="isSuggestModalOpen" class="fixed inset-0 z-50 bg-slate-900/70 backdrop-blur-sm flex items-center justify-center p-4">
            <div class="bg-white dark:bg-slate-900 rounded-3xl max-w-md w-full p-6 space-y-5 border border-slate-200 dark:border-slate-800 shadow-2xl">
                <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
                    <div class="flex items-center gap-2">
                        <MapPin class="w-5 h-5 text-indigo-600" />
                        <h3 class="text-base font-black text-slate-900 dark:text-white">اقترح منطقة توصيل جديدة</h3>
                    </div>
                    <button @click="isSuggestModalOpen = false" class="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                        <X class="w-5 h-5" />
                    </button>
                </div>

                <div v-if="suggestSuccessMessage" class="p-3 bg-emerald-50 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300 text-xs rounded-xl flex items-center gap-2">
                    <Check class="w-4 h-4 shrink-0" />
                    <span>{{ suggestSuccessMessage }}</span>
                </div>

                <div v-if="suggestErrorMessage" class="p-3 bg-rose-50 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300 text-xs rounded-xl flex items-center gap-2">
                    <X class="w-4 h-4 shrink-0" />
                    <span>{{ suggestErrorMessage }}</span>
                </div>

                <form v-if="!suggestSuccessMessage" @submit.prevent="submitSuggestion" class="space-y-4 text-xs">
                    <div class="p-3 bg-indigo-50/60 dark:bg-indigo-950/30 rounded-xl text-indigo-900 dark:text-indigo-300 leading-relaxed">
                        متبقي لك <strong>{{ remainingSuggestionsCount }}</strong> اقتراح من أصل 2. سيقوم فريق الإدارة بمراجعة طلبك واعتماد سعر الشحن فوراً.
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">اسم المنطقة / الحي / القرية *</label>
                        <input
                            v-model="suggestForm.name"
                            type="text"
                            required
                            placeholder="مثال: غزة - تل الهوا خلف المستشفى الأردني"
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                        />
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">المحافظة / المدينة *</label>
                        <input
                            v-model="suggestForm.city"
                            type="text"
                            required
                            placeholder="غزة، رام الله، نابلس، الخليل..."
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                        />
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">ملاحظات توضيحية (اختياري)</label>
                        <textarea
                            v-model="suggestForm.notes"
                            rows="2"
                            placeholder="معالم بارزة أو تفاصيل مساعدة..."
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                        ></textarea>
                    </div>

                    <div class="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-3">
                        <button
                            type="button"
                            @click="isSuggestModalOpen = false"
                            class="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-bold rounded-xl"
                        >
                            إلغاء
                        </button>
                        <button
                            type="submit"
                            :disabled="isSuggesting"
                            class="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow"
                        >
                            {{ isSuggesting ? 'جاري الإرسال...' : 'إرسال الاقتراح للإدارة' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </StoreLayout>
</template>
