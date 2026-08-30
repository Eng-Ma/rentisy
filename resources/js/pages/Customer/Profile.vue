<script setup lang="ts">
import { ref } from 'vue';
import { Head, Link, useForm, router } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    User as UserIcon,
    Settings,
    ShieldCheck,
    Lock,
    ArrowRight,
    CheckCircle2,
    XCircle,
    LoaderCircle,
    Sparkles,
    KeyRound
} from 'lucide-vue-next';

interface Props {
    customer: {
        id: number;
        name: string;
        email: string;
        phone?: string;
        address?: string;
        city?: string;
        google_id?: string;
        facebook_id?: string;
        avatar?: string;
        role?: string;
        created_at?: string;
    };
    socialConnections: {
        google: boolean;
        facebook: boolean;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const profileForm = useForm({
    name: props.customer.name,
    phone: props.customer.phone || '',
    address: props.customer.address || '',
    city: props.customer.city || 'غزة',
});

const passwordForm = useForm({
    current_password: '',
    password: '',
    password_confirmation: '',
});

const updateProfile = () => {
    profileForm.post(route('customer.profile.update'), {
        preserveScroll: true,
    });
};

const updatePassword = () => {
    passwordForm.post(route('customer.password.update'), {
        preserveScroll: true,
        onSuccess: () => passwordForm.reset(),
    });
};

const connectSocial = (provider: 'google' | 'facebook') => {
    router.post(route('customer.social.connect', provider), {}, {
        preserveScroll: true,
    });
};

const disconnectSocial = (provider: 'google' | 'facebook') => {
    if (confirm(`هل أنت متأكد من رغبتك في إلغاء ربط حساب ${provider === 'google' ? 'Google' : 'Facebook'}؟`)) {
        router.post(route('customer.social.disconnect', provider), {}, {
            preserveScroll: true,
        });
    }
};
</script>

<template>
    <StoreLayout title="الملف الشخصي وربط الحسابات | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Header -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
                <div>
                    <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">إدارة الملف الشخصي والأمان</h1>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        تحديث بياناتك الشخصية، ربط حسابات التواصل الاجتماعي، وإدارة كلمة المرور
                    </p>
                </div>

                <Link
                    :href="route('customer.dashboard')"
                    class="text-xs font-bold text-slate-600 dark:text-slate-400 hover:text-emerald-600 flex items-center gap-1 self-start sm:self-auto"
                >
                    <ArrowRight class="w-4 h-4" />
                    <span>العودة للوحة الحساب</span>
                </Link>
            </div>

            <div class="space-y-8">
                <!-- Section 1: Personal & Shipping Information -->
                <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                    <div class="flex items-center gap-3 pb-4 border-b border-slate-100 dark:border-slate-800">
                        <div class="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 flex items-center justify-center">
                            <UserIcon class="w-5 h-5" />
                        </div>
                        <div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">البيانات الشخصية وعنوان الشحن الافتراضي</h3>
                            <p class="text-xs text-slate-500">هذه البيانات تُستخدم تلقائياً عند إنشاء فواتير المبيعات وتوصيل الطلبات</p>
                        </div>
                    </div>

                    <form @submit.prevent="updateProfile" class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">الاسم الكامل</label>
                            <input
                                type="text"
                                v-model="profileForm.name"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            />
                            <span v-if="profileForm.errors.name" class="text-[11px] text-rose-500 mt-1 block">{{ profileForm.errors.name }}</span>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">البريد الإلكتروني</label>
                            <input
                                type="email"
                                :value="customer.email"
                                disabled
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-100 dark:bg-slate-800/40 text-slate-500 text-xs cursor-not-allowed"
                            />
                            <span class="text-[10px] text-slate-400 mt-1 block">البريد الإلكتروني هو المعرف الأساسي لحسابك</span>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">رقم الهاتف / الجوال</label>
                            <input
                                type="tel"
                                v-model="profileForm.phone"
                                placeholder="0599000000"
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            />
                            <span v-if="profileForm.errors.phone" class="text-[11px] text-rose-500 mt-1 block">{{ profileForm.errors.phone }}</span>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">المدينة / المنطقة</label>
                            <select
                                v-model="profileForm.city"
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            >
                                <option value="غزة">غزة</option>
                                <option value="خان يونس">خان يونس</option>
                                <option value="رفح">رفح</option>
                                <option value="شمال غزة">شمال غزة</option>
                                <option value="الوسطى / دير البلح">الوسطى / دير البلح</option>
                                <option value="القدس">القدس</option>
                                <option value="رام الله">رام الله</option>
                                <option value="نابلس">نابلس</option>
                                <option value="الخليل">الخليل</option>
                            </select>
                        </div>

                        <div class="sm:col-span-2">
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">العنوان التفصيلي</label>
                            <textarea
                                v-model="profileForm.address"
                                rows="2"
                                placeholder="الشارع، الحي، أقرب معلم..."
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            ></textarea>
                            <span v-if="profileForm.errors.address" class="text-[11px] text-rose-500 mt-1 block">{{ profileForm.errors.address }}</span>
                        </div>

                        <div class="sm:col-span-2 flex justify-end">
                            <button
                                type="submit"
                                :disabled="profileForm.processing"
                                class="px-6 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold text-xs shadow-md shadow-emerald-600/20 transition-all"
                            >
                                <LoaderCircle v-if="profileForm.processing" class="w-4 h-4 animate-spin" />
                                <span v-else>حفظ التعديلات</span>
                            </button>
                        </div>
                    </form>
                </div>

                <!-- Section 2: Social Account Connections (Google & Facebook) -->
                <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                    <div class="flex items-center gap-3 pb-4 border-b border-slate-100 dark:border-slate-800">
                        <div class="w-10 h-10 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 flex items-center justify-center">
                            <Sparkles class="w-5 h-5" />
                        </div>
                        <div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">ربط الحسابات الاجتماعية (Google & Facebook)</h3>
                            <p class="text-xs text-slate-500">اربط حساباتك الاجتماعية لتسجيل الدخول السريع بنقرة واحدة مستقبلاً</p>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <!-- Google Link Card -->
                        <div class="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 space-y-4">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <svg class="w-6 h-6" viewBox="0 0 24 24">
                                        <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/>
                                        <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/>
                                        <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.42l4.03-3.15z"/>
                                        <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/>
                                    </svg>
                                    <div>
                                        <h4 class="text-xs font-bold text-slate-900 dark:text-white">حساب Google</h4>
                                        <span class="text-[11px] text-slate-500">تسجيل الدخول السريع عبر جوجل</span>
                                    </div>
                                </div>

                                <span
                                    class="px-2.5 py-1 rounded-full text-[10px] font-extrabold"
                                    :class="socialConnections.google ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/80 dark:text-emerald-300' : 'bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-300'"
                                >
                                    {{ socialConnections.google ? 'مربوط ✓' : 'غير مربوط' }}
                                </span>
                            </div>

                            <div class="pt-2 border-t border-slate-200/60 dark:border-slate-700/60 flex items-center justify-between">
                                <span class="text-[11px] text-slate-500">
                                    {{ socialConnections.google ? 'حسابك موصول بجوجل بنجاح' : 'اضغط للربط بنقرة واحدة' }}
                                </span>

                                <button
                                    v-if="socialConnections.google"
                                    @click="disconnectSocial('google')"
                                    class="px-3 py-1.5 rounded-xl border border-rose-200 hover:bg-rose-50 text-rose-600 text-xs font-bold transition-colors"
                                >
                                    إلغاء الربط
                                </button>
                                <button
                                    v-else
                                    @click="connectSocial('google')"
                                    class="px-4 py-1.5 rounded-xl bg-slate-900 dark:bg-slate-700 hover:bg-emerald-600 text-white text-xs font-bold transition-colors"
                                >
                                    ربط الحساب الآن
                                </button>
                            </div>
                        </div>

                        <!-- Facebook Link Card -->
                        <div class="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/40 space-y-4">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <svg class="w-6 h-6 text-[#1877F2]" fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                                    </svg>
                                    <div>
                                        <h4 class="text-xs font-bold text-slate-900 dark:text-white">حساب Facebook</h4>
                                        <span class="text-[11px] text-slate-500">تسجيل الدخول عبر فيسبوك</span>
                                    </div>
                                </div>

                                <span
                                    class="px-2.5 py-1 rounded-full text-[10px] font-extrabold"
                                    :class="socialConnections.facebook ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/80 dark:text-emerald-300' : 'bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-300'"
                                >
                                    {{ socialConnections.facebook ? 'مربوط ✓' : 'غير مربوط' }}
                                </span>
                            </div>

                            <div class="pt-2 border-t border-slate-200/60 dark:border-slate-700/60 flex items-center justify-between">
                                <span class="text-[11px] text-slate-500">
                                    {{ socialConnections.facebook ? 'حسابك موصول بفيسبوك بنجاح' : 'اضغط للربط بنقرة واحدة' }}
                                </span>

                                <button
                                    v-if="socialConnections.facebook"
                                    @click="disconnectSocial('facebook')"
                                    class="px-3 py-1.5 rounded-xl border border-rose-200 hover:bg-rose-50 text-rose-600 text-xs font-bold transition-colors"
                                >
                                    إلغاء الربط
                                </button>
                                <button
                                    v-else
                                    @click="connectSocial('facebook')"
                                    class="px-4 py-1.5 rounded-xl bg-slate-900 dark:bg-slate-700 hover:bg-emerald-600 text-white text-xs font-bold transition-colors"
                                >
                                    ربط الحساب الآن
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Section 3: Password Update -->
                <div class="p-6 sm:p-8 rounded-3xl bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-6">
                    <div class="flex items-center gap-3 pb-4 border-b border-slate-100 dark:border-slate-800">
                        <div class="w-10 h-10 rounded-2xl bg-amber-50 dark:bg-amber-950/60 text-amber-600 flex items-center justify-center">
                            <KeyRound class="w-5 h-5" />
                        </div>
                        <div>
                            <h3 class="text-base font-bold text-slate-900 dark:text-white">تغيير كلمة المرور</h3>
                            <p class="text-xs text-slate-500">تأكد من استخدام كلمة مرور قوية تحتوي على أحرف وأرقام</p>
                        </div>
                    </div>

                    <form @submit.prevent="updatePassword" class="grid grid-cols-1 sm:grid-cols-3 gap-5">
                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">كلمة المرور الحالية</label>
                            <input
                                type="password"
                                v-model="passwordForm.current_password"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            />
                            <span v-if="passwordForm.errors.current_password" class="text-[11px] text-rose-500 mt-1 block">{{ passwordForm.errors.current_password }}</span>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">كلمة المرور الجديدة</label>
                            <input
                                type="password"
                                v-model="passwordForm.password"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            />
                            <span v-if="passwordForm.errors.password" class="text-[11px] text-rose-500 mt-1 block">{{ passwordForm.errors.password }}</span>
                        </div>

                        <div>
                            <label class="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5">تأكيد كلمة المرور الجديدة</label>
                            <input
                                type="password"
                                v-model="passwordForm.password_confirmation"
                                required
                                class="w-full px-4 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs focus:ring-2 focus:ring-emerald-500"
                            />
                        </div>

                        <div class="sm:col-span-3 flex justify-end">
                            <button
                                type="submit"
                                :disabled="passwordForm.processing"
                                class="px-6 py-2.5 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-emerald-600 disabled:opacity-50 text-white font-bold text-xs transition-colors"
                            >
                                <LoaderCircle v-if="passwordForm.processing" class="w-4 h-4 animate-spin" />
                                <span v-else>تحديث كلمة المرور</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
