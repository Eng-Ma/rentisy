<script setup lang="ts">
import { Head, useForm, Link } from '@inertiajs/vue3';
import {
    ShieldCheck,
    Lock,
    Mail,
    ArrowRight,
    LoaderCircle,
    Building2,
    KeyRound
} from 'lucide-vue-next';

defineProps<{
    status?: string;
}>();

const form = useForm({
    email: '',
    password: '',
    remember: false,
});

const fillAdminDemo = () => {
    form.email = 'admin@admin.com';
    form.password = 'password';
};

const submit = () => {
    form.post(route('admin.login.store'), {
        onFinish: () => form.reset('password'),
    });
};
</script>

<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 text-slate-100 flex items-center justify-center p-4 sm:p-6 font-sans selection:bg-indigo-500 selection:text-white" dir="rtl">
        <Head title="دخول إدارة النظام المحاسبي ERP" />

        <div class="w-full max-w-md space-y-6">
            <!-- Brand Header -->
            <div class="text-center space-y-3">
                <div class="inline-flex p-3 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 shadow-inner">
                    <ShieldCheck class="w-8 h-8" />
                </div>
                <h1 class="text-2xl sm:text-3xl font-black tracking-tight text-white">
                    بوابة إدارة النظام المحاسبي
                </h1>
                <p class="text-xs text-slate-400 max-w-xs mx-auto">
                    تسجيل الدخول المخصص لمدراء الحسابات والإدارة العامة لنظام رنتيسي / الأصيل ERP
                </p>
            </div>

            <!-- Login Card -->
            <div class="p-8 rounded-3xl bg-slate-900/80 border border-slate-800 backdrop-blur-xl shadow-2xl space-y-6">
                <div v-if="status" class="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-bold text-center">
                    {{ status }}
                </div>

                <form @submit.prevent="submit" class="space-y-4 text-right">
                    <div>
                        <label class="block text-xs font-bold text-slate-300 mb-1.5">البريد الإلكتروني للإدارة</label>
                        <div class="relative">
                            <input
                                type="email"
                                v-model="form.email"
                                required
                                autofocus
                                placeholder="admin@admin.com"
                                class="w-full pl-4 pr-10 py-2.5 rounded-xl border border-slate-700 bg-slate-800/80 text-xs text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                            />
                            <Mail class="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                        </div>
                        <span v-if="form.errors.email" class="text-[11px] text-rose-400 mt-1 block font-medium">{{ form.errors.email }}</span>
                    </div>

                    <div>
                        <label class="block text-xs font-bold text-slate-300 mb-1.5">كلمة المرور السرية</label>
                        <div class="relative">
                            <input
                                type="password"
                                v-model="form.password"
                                required
                                placeholder="••••••••"
                                class="w-full pl-4 pr-10 py-2.5 rounded-xl border border-slate-700 bg-slate-800/80 text-xs text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                            />
                            <Lock class="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
                        </div>
                        <span v-if="form.errors.password" class="text-[11px] text-rose-400 mt-1 block font-medium">{{ form.errors.password }}</span>
                    </div>

                    <div class="flex items-center justify-between pt-1">
                        <label class="flex items-center gap-2 text-xs text-slate-400 cursor-pointer">
                            <input type="checkbox" v-model="form.remember" class="rounded text-indigo-600 focus:ring-indigo-500 bg-slate-800 border-slate-700" />
                            <span>تذكر الجلسة</span>
                        </label>

                        <button
                            type="button"
                            @click="fillAdminDemo"
                            class="text-[11px] text-indigo-400 hover:text-indigo-300 font-semibold underline underline-offset-2 flex items-center gap-1"
                        >
                            <KeyRound class="w-3 h-3" />
                            تعبئة حساب الإدارة التجريبي
                        </button>
                    </div>

                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-indigo-600 to-emerald-600 hover:from-indigo-500 hover:to-emerald-500 disabled:opacity-50 text-white font-bold text-xs shadow-lg shadow-indigo-600/30 transition-all flex items-center justify-center gap-2 mt-4"
                    >
                        <LoaderCircle v-if="form.processing" class="w-4 h-4 animate-spin" />
                        <ShieldCheck v-else class="w-4 h-4" />
                        <span>دخول لوحة التحكم والتحكم الإداري</span>
                    </button>
                </form>
            </div>

            <!-- Footer Links -->
            <div class="text-center space-y-2">
                <Link
                    :href="route('home')"
                    class="text-xs text-slate-400 hover:text-white transition-colors inline-flex items-center gap-1"
                >
                    <ArrowRight class="w-3.5 h-3.5" />
                    <span>العودة للمتجر الإلكتروني الرئيسي</span>
                </Link>
                <div class="text-[11px] text-slate-600">
                    نظام آمن ومحمي | مشفر بمعايير SHA-256
                </div>
            </div>
        </div>
    </div>
</template>
