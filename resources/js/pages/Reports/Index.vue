<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';
import { LineChart, BookOpen, Scale, TrendingUp, Users, Clock, Target, CreditCard, Package } from 'lucide-vue-next';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير المالية والأصيل', href: '/reports' },
];

const reportsList = [
    {
        title: 'كشف حساب تفصيلي',
        desc: 'عرض الحركات المالية (مدين ودائن) والرصيد التراكمي لحساب معين خلال فترة محددة.',
        href: '/reports/account-statement',
        icon: BookOpen,
        color: 'border-blue-500 text-blue-500',
    },
    {
        title: 'ميزان المراجعة',
        desc: 'ملخص بأرصدة جميع الحسابات المفتوحة (مدين ودائن) للتأكد من توازن القيود المحاسبية.',
        href: '/reports/trial-balance',
        icon: Scale,
        color: 'border-purple-500 text-purple-500',
    },
    {
        title: 'قائمة الدخل (الأرباح والخسائر)',
        desc: 'بيان يوضح الإيرادات والمصروفات وصافي الدخل (الربح أو الخسارة) للمنشأة.',
        href: '/reports/income-statement',
        icon: TrendingUp,
        color: 'border-emerald-500 text-emerald-500',
    },
    {
        title: 'تقرير كشف حساب عميل / مورد',
        desc: 'عرض كشف حساب الديون والمشتريات وسجل الفواتير لزبون أو مورد محدد خلال فترة زمنية.',
        href: '/reports/party-statement',
        icon: Users,
        color: 'border-amber-500 text-amber-500',
    },
    {
        title: 'تقرير أعمار الديون (Aging Analysis)',
        desc: 'تحليل أعمار الذمم المدينة للعملاء والدائنة للموردين (0-30، 31-60، 61-90، +90 يوماً).',
        href: '/reports/aging',
        icon: Clock,
        color: 'border-rose-500 text-rose-500',
    },
    {
        title: 'كشف مراكز التكلفة',
        desc: 'تحليل المصاريف والإيرادات والربحية الموزعة على كل مركز تكلفة أو مشروع.',
        href: '/reports/cost-centers',
        icon: Target,
        color: 'border-cyan-500 text-cyan-500',
    },
    {
        title: 'تقرير حافظة الشيكات',
        desc: 'إحصائيات الشيكات الواردة والصادرة ومواعيد الاستحقاق ومتابعة التحصيل.',
        href: '/reports/checks',
        icon: CreditCard,
        color: 'border-indigo-500 text-indigo-500',
    },
    {
        title: 'كشف حركة وتقييم الأصناف',
        desc: 'تتبع حركة دخول وخروج الصنف وسجل المناقلات وتقييم المخزون المالي.',
        href: '/reports/stock-movement',
        icon: Package,
        color: 'border-teal-500 text-teal-500',
    },
];
</script>

<template>
    <Head title="التقارير المالية والأصيل الذهبي" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div>
                <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                    <LineChart class="w-6 h-6 text-primary" />
                    التقارير المالية ومخرجات الأصيل الذهبي
                </h1>
                <p class="text-sm text-muted-foreground mt-1">
                    مجموعة التقارير المالية والتحليلية الشاملة ومؤشرات الأداء.
                </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <Link 
                    v-for="rep in reportsList" 
                    :key="rep.href" 
                    :href="rep.href" 
                    class="bg-card hover:bg-muted/40 p-5 rounded-xl border border-border hover:border-primary/50 shadow-sm transition-all flex flex-col justify-between border-t-4"
                    :class="rep.color.split(' ')[0]"
                >
                    <div>
                        <div class="flex items-center gap-2 mb-2">
                            <component :is="rep.icon" class="w-5 h-5 shrink-0" :class="rep.color.split(' ')[1]" />
                            <h2 class="text-base font-bold text-foreground">{{ rep.title }}</h2>
                        </div>
                        <p class="text-muted-foreground text-xs leading-relaxed">{{ rep.desc }}</p>
                    </div>
                    <div class="mt-4 text-xs font-semibold text-primary">فتح التقرير ←</div>
                </Link>
            </div>
        </div>
    </AppLayout>
</template>
