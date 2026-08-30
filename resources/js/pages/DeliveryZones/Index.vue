<script setup lang="ts">
import { ref } from 'vue'
import { Head, useForm, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import { 
    MapPin, 
    Plus, 
    Edit, 
    Trash2, 
    Check, 
    X, 
    Clock, 
    Coins, 
    User, 
    CheckCircle2, 
    AlertCircle, 
    Sparkles, 
    MessageSquare
} from 'lucide-vue-next'

const props = defineProps<{
    zones: any[]
    suggestions: any[]
}>()

const activeTab = ref<'zones' | 'suggestions'>('zones')
const isModalOpen = ref(false)
const editingZone = ref<any>(null)

// Approval Modal State
const isApproveModalOpen = ref(false)
const approvingSuggestion = ref<any>(null)
const approveForm = useForm({
    delivery_fee: 15,
    name: '',
    estimated_time: 'خلال 24-48 ساعة',
    admin_notes: 'تم اعتماد المنطقة المقترحة.',
})

const form = useForm({
    name: '',
    city: 'غزة',
    delivery_fee: 15,
    estimated_time: 'خلال 24-48 ساعة',
    is_active: true,
    admin_notes: '',
})

const openCreateModal = () => {
    editingZone.value = null
    form.reset()
    form.city = 'غزة'
    form.delivery_fee = 15
    form.estimated_time = 'خلال 24-48 ساعة'
    form.is_active = true
    isModalOpen.value = true
}

const openEditModal = (zone: any) => {
    editingZone.value = zone
    form.name = zone.name
    form.city = zone.city
    form.delivery_fee = zone.delivery_fee
    form.estimated_time = zone.estimated_time
    form.is_active = Boolean(zone.is_active)
    form.admin_notes = zone.admin_notes || ''
    isModalOpen.value = true
}

const saveZone = () => {
    if (editingZone.value) {
        form.put(route('delivery-zones.update', editingZone.value.id), {
            onSuccess: () => { isModalOpen.value = false }
        })
    } else {
        form.post(route('delivery-zones.store'), {
            onSuccess: () => { isModalOpen.value = false }
        })
    }
}

const deleteZone = (zone: any) => {
    if (confirm(`هل أنت متأكد من حذف منطقة التوصيل (${zone.name})؟`)) {
        router.delete(route('delivery-zones.destroy', zone.id))
    }
}

const openApproveModal = (suggestion: any) => {
    approvingSuggestion.value = suggestion
    approveForm.name = suggestion.name
    approveForm.delivery_fee = 15
    approveForm.estimated_time = 'خلال 24-48 ساعة'
    approveForm.admin_notes = 'تم اعتماد المنطقة بنجاح.'
    isApproveModalOpen.value = true
}

const submitApproval = () => {
    if (!approvingSuggestion.value) return
    approveForm.post(route('delivery-zones.approve', approvingSuggestion.value.id), {
        onSuccess: () => { isApproveModalOpen.value = false }
    })
}

const rejectSuggestion = (suggestion: any) => {
    const reason = prompt('أدخل سبب الرفض (اختياري):', 'المنطقة خارج نطاق التوصيل حالياً')
    if (reason !== null) {
        router.post(route('delivery-zones.reject', suggestion.id), {
            admin_notes: reason
        })
    }
}
</script>

<template>
    <Head title="إدارة مناطق وأسعار التوصيل - رنتيسي ERP" />

    <AppLayout>
        <div class="p-6 max-w-7xl mx-auto space-y-6">
            <!-- Header -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 class="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-3">
                        <span class="p-2.5 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20">
                            <MapPin class="w-6 h-6" />
                        </span>
                        إدارة مناطق وأسعار التوصيل واقتراحات الزبائن
                    </h1>
                    <p class="text-xs text-slate-500 mt-1">
                        تحديد وتعديل أسعار الشحن والتوصيل لكل منطقة في فلسطين مع مراجعة واعتماد اقتراحات الزبائن
                    </p>
                </div>

                <div class="flex items-center gap-3">
                    <button
                        @click="openCreateModal"
                        class="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow flex items-center gap-2 transition"
                    >
                        <Plus class="w-4 h-4" />
                        إضافة منطقة توصيل جديدة
                    </button>
                </div>
            </div>

            <!-- Tabs Navigation -->
            <div class="flex items-center gap-3 border-b border-slate-200 dark:border-slate-800 pb-2">
                <button
                    @click="activeTab = 'zones'"
                    :class="[
                        activeTab === 'zones'
                            ? 'bg-indigo-600 text-white shadow-md'
                            : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 border border-slate-200 dark:border-slate-700'
                    ]"
                    class="px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2"
                >
                    <MapPin class="w-4 h-4" />
                    المناطق المعتمدة ({{ zones.length }})
                </button>

                <button
                    @click="activeTab = 'suggestions'"
                    :class="[
                        activeTab === 'suggestions'
                            ? 'bg-amber-600 text-white shadow-md'
                            : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 border border-slate-200 dark:border-slate-700'
                    ]"
                    class="px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2"
                >
                    <Sparkles class="w-4 h-4" />
                    اقتراحات الزبائن الجديدة
                    <span 
                        v-if="suggestions.length > 0"
                        class="px-2 py-0.5 rounded-full bg-rose-500 text-white text-[10px] font-black"
                    >
                        {{ suggestions.length }}
                    </span>
                </button>
            </div>

            <!-- TAB 1: Approved Zones Table -->
            <div v-if="activeTab === 'zones'" class="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                <div class="overflow-x-auto">
                    <table class="w-full text-start text-xs">
                        <thead>
                            <tr class="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-slate-500 font-bold">
                                <th class="p-4 text-start">المنطقة / الحي</th>
                                <th class="p-4 text-start">المحافظة / المدينة</th>
                                <th class="p-4 text-center">سعر التوصيل (₪)</th>
                                <th class="p-4 text-center">المدة التقديرية</th>
                                <th class="p-4 text-center">الحالة</th>
                                <th class="p-4 text-end">الإجراءات</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                            <tr v-if="zones.length === 0">
                                <td colspan="6" class="p-8 text-center text-slate-400">
                                    لا توجد مناطق توصيل مضافة حتى الآن.
                                </td>
                            </tr>
                            <tr v-for="zone in zones" :key="zone.id" class="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition">
                                <td class="p-4 font-bold text-slate-900 dark:text-white">
                                    <div class="flex items-center gap-2">
                                        <MapPin class="w-4 h-4 text-indigo-500" />
                                        <span>{{ zone.name }}</span>
                                    </div>
                                </td>
                                <td class="p-4 font-medium text-slate-600 dark:text-slate-300">
                                    {{ zone.city }}
                                </td>
                                <td class="p-4 text-center font-black text-indigo-600 dark:text-indigo-400 text-sm">
                                    {{ zone.delivery_fee }} ₪
                                </td>
                                <td class="p-4 text-center text-slate-500">
                                    <span class="inline-flex items-center gap-1">
                                        <Clock class="w-3.5 h-3.5 text-slate-400" />
                                        {{ zone.estimated_time }}
                                    </span>
                                </td>
                                <td class="p-4 text-center">
                                    <span 
                                        :class="zone.is_active ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300' : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'"
                                        class="px-2.5 py-1 rounded-full text-[11px] font-bold"
                                    >
                                        {{ zone.is_active ? 'مفعلة بالمتجر' : 'معطلة' }}
                                    </span>
                                </td>
                                <td class="p-4 text-end">
                                    <div class="flex items-center justify-end gap-2">
                                        <button
                                            @click="openEditModal(zone)"
                                            class="p-1.5 text-slate-600 hover:text-indigo-600 dark:text-slate-400 dark:hover:text-indigo-400 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                                            title="تعديل"
                                        >
                                            <Edit class="w-4 h-4" />
                                        </button>
                                        <button
                                            @click="deleteZone(zone)"
                                            class="p-1.5 text-slate-600 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                                            title="حذف"
                                        >
                                            <Trash2 class="w-4 h-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- TAB 2: Customer Suggestions Review -->
            <div v-else class="bg-white dark:bg-slate-900 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden p-6">
                <div v-if="suggestions.length === 0" class="py-12 text-center text-slate-400">
                    <CheckCircle2 class="w-12 h-12 mx-auto mb-3 text-emerald-500 opacity-60" />
                    <p class="text-sm font-bold text-slate-700 dark:text-slate-300">لا توجد اقتراحات مناطق معلقة حالياً.</p>
                    <p class="text-xs text-slate-500 mt-1">جميع اقتراحات الزبائن تمت مراجعتها واتخاذ القرار بشأنها.</p>
                </div>

                <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div 
                        v-for="s in suggestions" 
                        :key="s.id"
                        class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700/80 space-y-4"
                    >
                        <div class="flex items-start justify-between">
                            <div class="space-y-1">
                                <div class="flex items-center gap-2">
                                    <span class="text-xs font-bold px-2 py-0.5 rounded-md bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300">
                                        اقتراح جديد
                                    </span>
                                    <h4 class="font-black text-sm text-slate-900 dark:text-white">{{ s.name }}</h4>
                                </div>
                                <p class="text-xs text-slate-500">المدينة / المحافظة: <strong class="text-slate-800 dark:text-slate-200">{{ s.city }}</strong></p>
                            </div>
                            <span class="text-[11px] text-slate-400 font-mono">{{ new Date(s.created_at).toLocaleDateString('ar-EG') }}</span>
                        </div>

                        <div v-if="s.suggested_by_user" class="text-xs text-slate-600 dark:text-slate-300 flex items-center gap-2 bg-white dark:bg-slate-900 p-2.5 rounded-xl border border-slate-100 dark:border-slate-800">
                            <User class="w-4 h-4 text-indigo-500 shrink-0" />
                            <span>مقترح من الزبون: <strong>{{ s.suggested_by_user.name }}</strong> ({{ s.suggested_by_user.phone || s.suggested_by_user.email }})</span>
                        </div>

                        <div v-if="s.admin_notes" class="text-xs text-slate-500 italic bg-amber-50/60 dark:bg-amber-950/20 p-2.5 rounded-xl">
                            {{ s.admin_notes }}
                        </div>

                        <div class="flex items-center gap-2 pt-2 border-t border-slate-200 dark:border-slate-700">
                            <button
                                @click="openApproveModal(s)"
                                class="flex-1 py-2 px-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow flex items-center justify-center gap-1.5 transition"
                            >
                                <Check class="w-3.5 h-3.5" />
                                <span>موافقة وتحديد السعر</span>
                            </button>
                            <button
                                @click="rejectSuggestion(s)"
                                class="py-2 px-4 bg-rose-50 hover:bg-rose-100 text-rose-600 dark:bg-rose-950/40 dark:hover:bg-rose-900/60 font-bold text-xs rounded-xl transition"
                            >
                                <X class="w-3.5 h-3.5" />
                                <span>رفض</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add/Edit Zone Modal -->
        <div v-if="isModalOpen" class="fixed inset-0 z-50 bg-slate-900/70 backdrop-blur-sm flex items-center justify-center p-4">
            <div class="bg-white dark:bg-slate-900 rounded-3xl max-w-lg w-full p-6 space-y-5 border border-slate-200 dark:border-slate-800 shadow-2xl">
                <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
                    <h3 class="text-base font-black text-slate-900 dark:text-white">
                        {{ editingZone ? 'تعديل منطقة توصيل' : 'إضافة منطقة توصيل جديدة' }}
                    </h3>
                    <button @click="isModalOpen = false" class="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                        <X class="w-5 h-5" />
                    </button>
                </div>

                <form @submit.prevent="saveZone" class="space-y-4 text-xs">
                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">اسم المنطقة / الحي / البلدة *</label>
                        <input
                            v-model="form.name"
                            type="text"
                            required
                            placeholder="مثال: غزة - حي النصر والشيخ رضوان"
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                        />
                    </div>

                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">المحافظة / المدينة *</label>
                            <input
                                v-model="form.city"
                                type="text"
                                required
                                placeholder="غزة، رام الله، نابلس..."
                                class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                        </div>

                        <div>
                            <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">سعر التوصيل (₪) *</label>
                            <input
                                v-model.number="form.delivery_fee"
                                type="number"
                                step="0.5"
                                min="0"
                                required
                                class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                        </div>
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">المدة الزمنية التقديرية للتوصيل</label>
                        <input
                            v-model="form.estimated_time"
                            type="text"
                            placeholder="مثال: خلال نفس اليوم (2-6 ساعات) أو 24-48 ساعة"
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                        />
                    </div>

                    <div class="flex items-center gap-2 pt-2">
                        <input
                            v-model="form.is_active"
                            type="checkbox"
                            id="zone_active"
                            class="w-4 h-4 text-indigo-600 rounded"
                        />
                        <label for="zone_active" class="font-bold text-slate-700 dark:text-slate-300 cursor-pointer">
                            تفعيل المنطقة فوراً وإتاحتها للزبائن في المتجر
                        </label>
                    </div>

                    <div class="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-3">
                        <button
                            type="button"
                            @click="isModalOpen = false"
                            class="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-bold rounded-xl"
                        >
                            إلغاء
                        </button>
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow"
                        >
                            {{ form.processing ? 'جاري الحفظ...' : 'حفظ المنطقة' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Approve Suggestion Modal -->
        <div v-if="isApproveModalOpen" class="fixed inset-0 z-50 bg-slate-900/70 backdrop-blur-sm flex items-center justify-center p-4">
            <div class="bg-white dark:bg-slate-900 rounded-3xl max-w-md w-full p-6 space-y-5 border border-slate-200 dark:border-slate-800 shadow-2xl">
                <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
                    <h3 class="text-base font-black text-slate-900 dark:text-white">
                        اعتماد منطقة مقترحة: {{ approvingSuggestion?.name }}
                    </h3>
                    <button @click="isApproveModalOpen = false" class="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                        <X class="w-5 h-5" />
                    </button>
                </div>

                <form @submit.prevent="submitApproval" class="space-y-4 text-xs">
                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">اسم المنطقة المعتمد</label>
                        <input
                            v-model="approveForm.name"
                            type="text"
                            required
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl outline-none"
                        />
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">حدد سعر التوصيل المعتمد (₪) *</label>
                        <input
                            v-model.number="approveForm.delivery_fee"
                            type="number"
                            step="0.5"
                            min="0"
                            required
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl outline-none"
                        />
                    </div>

                    <div>
                        <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">مدة التوصيل التقديرية</label>
                        <input
                            v-model="approveForm.estimated_time"
                            type="text"
                            class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl outline-none"
                        />
                    </div>

                    <div class="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-3">
                        <button
                            type="button"
                            @click="isApproveModalOpen = false"
                            class="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-bold rounded-xl"
                        >
                            إلغاء
                        </button>
                        <button
                            type="submit"
                            :disabled="approveForm.processing"
                            class="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl shadow"
                        >
                            {{ approveForm.processing ? 'جاري الاعتماد...' : 'اعتماد وتفعيل المنطقة فوراً' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AppLayout>
</template>
