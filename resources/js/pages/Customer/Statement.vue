<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
import StoreLayout from '@/layouts/StoreLayout.vue';
import {
    FileText,
    Printer,
    ArrowRight,
    Building2,
    DollarSign,
    CreditCard,
    Sparkles
} from 'lucide-vue-next';

interface Party {
    id: number;
    name: string;
    phone?: string;
    address?: string;
    account?: {
        code: string;
        name: string;
    };
}

interface Invoice {
    id: number;
    type: string;
    date: string;
    notes?: string;
    lines: Array<{ quantity: number; unit_price: number }>;
}

interface Voucher {
    id: number;
    voucher_number?: string;
    type: string;
    date: string;
    amount: number;
    notes?: string;
}

interface Props {
    party?: Party | null;
    invoices: Invoice[];
    vouchers: Voucher[];
    summary: {
        totalDebit: number;
        totalCredit: number;
        balance: number;
    };
    customer: {
        name: string;
        email: string;
    };
    storeContext?: {
        cartCount?: number;
        wishlistIds?: number[];
    };
}

const props = defineProps<Props>();

const printStatement = () => {
    window.print();
};
</script>

<template>
    <StoreLayout title="كشف الحساب المحاسبي (ERP) | رنتيسي ستور" :storeContext="storeContext">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <!-- Header Actions -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 print:hidden">
                <div class="space-y-1 text-right">
                    <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 text-xs font-bold">
                        <Sparkles class="w-3.5 h-3.5" />
                        <span>الربط المباشر مع دفتر الأستاذ العام ERP</span>
                    </div>
                    <h1 class="text-2xl sm:text-3xl font-black text-slate-900 dark:text-white">
                        كشف حساب العميل المالي
                    </h1>
                    <p class="text-xs text-slate-500">
                        كشف حساب تفصيلي يوضح كافة فواتير المشتريات والسندات المالية المقيدة بحسابك
                    </p>
                </div>

                <div class="flex items-center gap-3">
                    <button
                        @click="printStatement"
                        class="px-5 py-2.5 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-2 transition-colors shadow-sm"
                    >
                        <Printer class="w-4 h-4" />
                        <span>طباعة كشف الحساب</span>
                    </button>
                    <Link
                        :href="route('customer.dashboard')"
                        class="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100"
                    >
                        العودة للوحة الحساب
                    </Link>
                </div>
            </div>

            <!-- Main Statement Card -->
            <div class="bg-white dark:bg-slate-900 rounded-3xl p-6 sm:p-10 border border-slate-200/80 dark:border-slate-800 shadow-sm space-y-8">
                <!-- Top Summary Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                    <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
                        <span class="text-xs text-slate-500 block mb-1">إجمالي الفواتير المسحوبة (مدين):</span>
                        <div class="text-2xl font-black text-rose-600">{{ summary.totalDebit }} ₪</div>
                    </div>

                    <div class="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
                        <span class="text-xs text-slate-500 block mb-1">إجمالي الدفعات والمردودات (دائن):</span>
                        <div class="text-2xl font-black text-emerald-600">{{ summary.totalCredit }} ₪</div>
                    </div>

                    <div class="p-5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800">
                        <span class="text-xs text-emerald-800 dark:text-emerald-300 font-semibold block mb-1">صافي الرصيد الحالي:</span>
                        <div class="text-2xl font-black text-emerald-700 dark:text-emerald-300">
                            {{ summary.balance }} ₪
                            <span class="text-xs font-normal text-slate-500">
                                ({{ summary.balance > 0 ? 'مستحق عليك' : (summary.balance < 0 ? 'رصيد لصالحك' : 'حساب خالص') }})
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Customer Account Details -->
                <div class="p-4 rounded-2xl bg-slate-50 dark:bg-slate-800/40 border border-slate-100 dark:border-slate-800 text-xs flex flex-wrap items-center justify-between gap-4">
                    <div>
                        <strong class="text-slate-900 dark:text-white">اسم العميل:</strong> {{ party?.name || customer.name }}
                    </div>
                    <div>
                        <strong class="text-slate-900 dark:text-white">رقم الحساب المحاسبي:</strong> {{ party?.account?.code || '1103-01' }}
                    </div>
                    <div>
                        <strong class="text-slate-900 dark:text-white">تاريخ إصدار الكشف:</strong> {{ new Date().toLocaleDateString('ar-EG') }}
                    </div>
                </div>

                <!-- Ledger Transactions Table -->
                <div class="space-y-4">
                    <h3 class="text-base font-black text-slate-900 dark:text-white">سجل العمليات المحاسبية</h3>

                    <div class="overflow-x-auto">
                        <table class="w-full text-right text-xs">
                            <thead>
                                <tr class="text-slate-400 border-b border-slate-100 dark:border-slate-800 pb-3">
                                    <th class="py-3 font-bold">التاريخ</th>
                                    <th class="py-3 font-bold">نوع السند / الحركة</th>
                                    <th class="py-3 font-bold">رقم المستند</th>
                                    <th class="py-3 font-bold">البيان / الملاحظات</th>
                                    <th class="py-3 font-bold text-rose-600">مدين (₪)</th>
                                    <th class="py-3 font-bold text-emerald-600">دائن (₪)</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <!-- Invoices -->
                                <tr v-for="inv in invoices" :key="'inv-' + inv.id" class="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                                    <td class="py-3 text-slate-500 font-mono">{{ inv.date }}</td>
                                    <td class="py-3 font-bold">
                                        <span class="px-2 py-0.5 rounded text-[10px]" :class="inv.type === 'sale' ? 'bg-rose-50 text-rose-700' : 'bg-blue-50 text-blue-700'">
                                            {{ inv.type === 'sale' ? 'فاتورة مبيعات' : 'مردودات مبيعات' }}
                                        </span>
                                    </td>
                                    <td class="py-3 font-mono font-semibold">INV-000{{ inv.id }}</td>
                                    <td class="py-3 text-slate-600 dark:text-slate-400 line-clamp-1 max-w-xs">{{ inv.notes || 'فاتورة طلب من المتجر' }}</td>
                                    <td class="py-3 font-black text-rose-600">
                                        {{ inv.type === 'sale' ? inv.lines.reduce((s, l) => s + (l.quantity * l.unit_price), 0).toFixed(2) : '0.00' }}
                                    </td>
                                    <td class="py-3 font-black text-emerald-600">
                                        {{ inv.type === 'sale_return' ? inv.lines.reduce((s, l) => s + (l.quantity * l.unit_price), 0).toFixed(2) : '0.00' }}
                                    </td>
                                </tr>

                                <!-- Vouchers -->
                                <tr v-for="v in vouchers" :key="'v-' + v.id" class="hover:bg-slate-50 dark:hover:bg-slate-800/40">
                                    <td class="py-3 text-slate-500 font-mono">{{ v.date }}</td>
                                    <td class="py-3 font-bold">
                                        <span class="px-2 py-0.5 rounded text-[10px] bg-emerald-50 text-emerald-700">
                                            {{ v.type === 'receipt' ? 'سند قبض' : 'سند صرف' }}
                                        </span>
                                    </td>
                                    <td class="py-3 font-mono font-semibold">{{ v.voucher_number || 'V-000' + v.id }}</td>
                                    <td class="py-3 text-slate-600 dark:text-slate-400 line-clamp-1 max-w-xs">{{ v.notes || 'دفعة مسددة' }}</td>
                                    <td class="py-3 font-black text-rose-600">{{ v.type === 'payment' ? v.amount : '0.00' }}</td>
                                    <td class="py-3 font-black text-emerald-600">{{ v.type === 'receipt' ? v.amount : '0.00' }}</td>
                                </tr>

                                <tr v-if="invoices.length === 0 && vouchers.length === 0">
                                    <td colspan="6" class="text-center py-8 text-slate-400">
                                        لا توجد حركات محاسبية مسجلة بعد لهذا الحساب.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="pt-6 border-t border-slate-100 dark:border-slate-800 text-center text-xs text-slate-400">
                    كشف حساب إلكتروني رسمي مستخرج من نظام الأصيل / رنتيسي ERP.
                </div>
            </div>
        </div>
    </StoreLayout>
</template>
