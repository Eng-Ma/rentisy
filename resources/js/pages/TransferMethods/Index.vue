<script setup lang="ts">
import { ref } from 'vue'
import { Head, useForm, router } from '@inertiajs/vue3'
import AppLayout from '@/layouts/AppLayout.vue'
import {
    CreditCard,
    Plus,
    Edit,
    Trash2,
    Check,
    X,
    Building2,
    Phone,
    FileText,
    Image,
    Upload,
    CheckCircle2,
    ToggleLeft,
    ToggleRight,
    QrCode
} from 'lucide-vue-next'

const props = defineProps<{
    methods: any[]
}>()

const isModalOpen = ref(false)
const editingMethod = ref<any>(null)
const logoPreview = ref<string | null>(null)

const form = useForm({
    name: '',
    account_name: '',
    account_number: '',
    iban: '',
    phone: '',
    instructions: '',
    logo_url: '',
    logo: null as File | null,
    is_active: true,
    sort_order: 1,
})

const onLogoSelected = (event: Event) => {
    const target = event.target as HTMLInputElement
    if (target.files && target.files[0]) {
        const file = target.files[0]
        form.logo = file
        logoPreview.value = URL.createObjectURL(file)
    }
}

const openCreateModal = () => {
    editingMethod.value = null
    form.reset()
    logoPreview.value = null
    form.is_active = true
    form.sort_order = props.methods.length + 1
    isModalOpen.value = true
}

const openEditModal = (method: any) => {
    editingMethod.value = method
    form.name = method.name
    form.account_name = method.account_name || ''
    form.account_number = method.account_number || ''
    form.iban = method.iban || ''
    form.phone = method.phone || ''
    form.instructions = method.instructions || ''
    form.logo_url = method.logo_url || ''
    form.logo = null
    logoPreview.value = method.logo_url || null
    form.is_active = Boolean(method.is_active)
    form.sort_order = method.sort_order || 1
    isModalOpen.value = true
}

const saveMethod = () => {
    if (editingMethod.value) {
        form.post(route('transfer-methods.update', editingMethod.value.id), {
            forceFormData: true,
            onSuccess: () => { isModalOpen.value = false }
        })
    } else {
        form.post(route('transfer-methods.store'), {
            forceFormData: true,
            onSuccess: () => { isModalOpen.value = false }
        })
    }
}

const toggleActive = (method: any) => {
    router.post(route('transfer-methods.toggle', method.id), {}, {
        preserveScroll: true
    })
}

const deleteMethod = (method: any) => {
    if (confirm(`هل أنت متأكد من حذف طريقة التحويل (${method.name})؟`)) {
        router.delete(route('transfer-methods.destroy', method.id))
    }
}
</script>

<template>
    <Head title="إدارة طرق وحسابات التحويل المالي - رنتيسي ERP" />

    <AppLayout>
        <div class="p-6 max-w-7xl mx-auto space-y-6">
            <!-- Header -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 class="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-3">
                        <span class="p-2.5 rounded-2xl bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20">
                            <CreditCard class="w-6 h-6" />
                        </span>
                        إدارة طرق وحسابات التحويل المالي
                    </h1>
                    <p class="text-xs text-slate-500 mt-1">
                        تحديد وتخصيص حسابات التحويل البنكي، محافظ الدفع الإلكتروني، حسابات التجار، وإرفاق الشعارات والتعليمات الخاصة لكل طريقة
                    </p>
                </div>

                <button
                    @click="openCreateModal"
                    class="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow flex items-center gap-2 transition"
                >
                    <Plus class="w-4 h-4" />
                    إضافة حساب / طريقة تحويل جديدة
                </button>
            </div>

            <!-- Methods Grid / Table -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div
                    v-for="method in methods"
                    :key="method.id"
                    class="p-6 rounded-3xl bg-white dark:bg-slate-900 border-2 transition-all space-y-4 shadow-sm"
                    :class="method.is_active ? 'border-slate-200/80 dark:border-slate-800' : 'border-dashed border-slate-300 dark:border-slate-800 opacity-60'"
                >
                    <div class="flex items-start justify-between gap-3">
                        <div class="flex items-center gap-3">
                            <div class="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 overflow-hidden flex items-center justify-center shrink-0">
                                <img v-if="method.logo_url" :src="method.logo_url" :alt="method.name" class="w-full h-full object-cover" />
                                <Building2 v-else class="w-6 h-6 text-indigo-500" />
                            </div>
                            <div>
                                <h3 class="font-black text-sm text-slate-900 dark:text-white line-clamp-1">{{ method.name }}</h3>
                                <p class="text-[11px] text-slate-500 mt-0.5">{{ method.account_name || 'بدون اسم مستفيد' }}</p>
                            </div>
                        </div>

                        <button
                            @click="toggleActive(method)"
                            class="text-xs font-bold transition"
                            :class="method.is_active ? 'text-emerald-600' : 'text-slate-400'"
                            :title="method.is_active ? 'تعطيل الطريقة' : 'تفعيل الطريقة'"
                        >
                            <ToggleRight v-if="method.is_active" class="w-7 h-7" />
                            <ToggleLeft v-else class="w-7 h-7" />
                        </button>
                    </div>

                    <!-- Details Fields -->
                    <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/50 space-y-2 text-xs font-mono text-slate-700 dark:text-slate-300 border border-slate-100 dark:border-slate-800">
                        <div v-if="method.account_number" class="flex items-center justify-between">
                            <span class="text-slate-400 font-sans">رقم الحساب:</span>
                            <strong class="text-slate-900 dark:text-white">{{ method.account_number }}</strong>
                        </div>
                        <div v-if="method.iban" class="flex flex-col gap-0.5">
                            <span class="text-slate-400 font-sans">الآيبان IBAN:</span>
                            <strong class="text-[11px] text-indigo-600 dark:text-indigo-400 break-all">{{ method.iban }}</strong>
                        </div>
                        <div v-if="method.phone" class="flex items-center justify-between">
                            <span class="text-slate-400 font-sans">رقم الجوال / المحفظة:</span>
                            <strong class="text-slate-900 dark:text-white">{{ method.phone }}</strong>
                        </div>
                    </div>

                    <!-- Custom Instructions / Notes -->
                    <div v-if="method.instructions" class="p-3 rounded-xl bg-indigo-50/50 dark:bg-indigo-950/20 text-[11px] text-slate-600 dark:text-slate-400 border border-indigo-100/50 dark:border-indigo-900/30">
                        <span class="font-bold text-indigo-900 dark:text-indigo-300 block mb-0.5">ملاحظات التحويل للزبون:</span>
                        {{ method.instructions }}
                    </div>

                    <!-- Action Buttons -->
                    <div class="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2">
                        <button
                            @click="openEditModal(method)"
                            class="p-2 text-slate-600 hover:text-indigo-600 dark:text-slate-400 dark:hover:text-indigo-400 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 transition flex items-center gap-1 text-xs font-bold"
                        >
                            <Edit class="w-3.5 h-3.5" />
                            <span>تعديل</span>
                        </button>
                        <button
                            @click="deleteMethod(method)"
                            class="p-2 text-slate-600 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 transition flex items-center gap-1 text-xs font-bold"
                        >
                            <Trash2 class="w-3.5 h-3.5" />
                            <span>حذف</span>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Add / Edit Modal -->
            <div v-if="isModalOpen" class="fixed inset-0 z-50 bg-slate-900/70 backdrop-blur-sm flex items-center justify-center p-4">
                <div class="bg-white dark:bg-slate-900 rounded-3xl max-w-lg w-full p-6 space-y-5 border border-slate-200 dark:border-slate-800 shadow-2xl max-h-[90vh] overflow-y-auto">
                    <div class="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
                        <h3 class="text-base font-black text-slate-900 dark:text-white">
                            {{ editingMethod ? 'تعديل طريقة التحويل' : 'إضافة طريقة تحويل جديدة' }}
                        </h3>
                        <button @click="isModalOpen = false" class="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                            <X class="w-5 h-5" />
                        </button>
                    </div>

                    <form @submit.prevent="saveMethod" class="space-y-4 text-xs">
                        <div>
                            <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">اسم طريقة التحويل / البنك / المحفظة *</label>
                            <input
                                v-model="form.name"
                                type="text"
                                required
                                placeholder="مثال: تحويل بنك فلسطين، تحويل جوال باي، تحويل لتاجر"
                                class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">اسم المستفيد / صاحب الحساب</label>
                                <input
                                    v-model="form.account_name"
                                    type="text"
                                    placeholder="مثال: شركة رنتيسي للأنظمة"
                                    class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                                />
                            </div>

                            <div>
                                <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">رقم الحساب / كود التاجر</label>
                                <input
                                    v-model="form.account_number"
                                    type="text"
                                    placeholder="مثال: 1892040 أو MERCHANT-99882"
                                    class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                                />
                            </div>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">رقم الآيبان IBAN</label>
                                <input
                                    v-model="form.iban"
                                    type="text"
                                    placeholder="مثال: PS66PALS..."
                                    class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none font-mono"
                                />
                            </div>

                            <div>
                                <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">رقم الجوال المرتبط</label>
                                <input
                                    v-model="form.phone"
                                    type="text"
                                    placeholder="مثال: 0599123456"
                                    class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                                />
                            </div>
                        </div>

                        <!-- Logo Upload / URL -->
                        <div class="space-y-2">
                            <label class="block font-bold text-slate-700 dark:text-slate-300">شعار / لوجو طريقة الدفع</label>
                            
                            <div class="flex items-center gap-3">
                                <label class="flex-1 cursor-pointer flex items-center justify-center p-3 border-2 border-dashed border-slate-300 dark:border-slate-700 rounded-xl bg-slate-50 dark:bg-slate-800 hover:border-indigo-500 transition gap-2">
                                    <Upload class="w-4 h-4 text-indigo-600" />
                                    <span class="text-xs text-slate-600 dark:text-slate-300">رفع صورة الشعار</span>
                                    <input type="file" accept="image/*" @change="onLogoSelected" class="hidden" />
                                </label>

                                <div v-if="logoPreview" class="w-12 h-12 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden shrink-0">
                                    <img :src="logoPreview" class="w-full h-full object-cover" />
                                </div>
                            </div>

                            <input
                                v-model="form.logo_url"
                                type="url"
                                placeholder="أو أدخل رابط الشعار المباشر (URL)"
                                class="w-full p-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-xs outline-none"
                            />
                        </div>

                        <!-- Custom Instructions / Notes -->
                        <div>
                            <label class="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                                معلومات وملاحظات التحويل (تظهر للزبون عند اختيار هذه الطريقة) *
                            </label>
                            <textarea
                                v-model="form.instructions"
                                rows="3"
                                placeholder="مثال: الفرع الرئيسي، يرجى كتابة اسمك في ملاحظات التحويل ورفع سكرين شوت الإشعار بعد التحويل..."
                                class="w-full p-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:ring-2 focus:ring-indigo-500 outline-none"
                            ></textarea>
                        </div>

                        <div class="flex items-center justify-between pt-2">
                            <div class="flex items-center gap-2">
                                <input
                                    v-model="form.is_active"
                                    type="checkbox"
                                    id="method_active"
                                    class="w-4 h-4 text-indigo-600 rounded"
                                />
                                <label for="method_active" class="font-bold text-slate-700 dark:text-slate-300 cursor-pointer">
                                    تفعيل الطريقة وإظهارها للزبائن في المتجر
                                </label>
                            </div>

                            <div class="flex items-center gap-2">
                                <label class="font-bold text-slate-700 dark:text-slate-300">الترتيب:</label>
                                <input
                                    v-model.number="form.sort_order"
                                    type="number"
                                    min="1"
                                    class="w-16 p-1.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-center"
                                />
                            </div>
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
                                {{ form.processing ? 'جاري الحفظ...' : 'حفظ طريقة التحويل' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
