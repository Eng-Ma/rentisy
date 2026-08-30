<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import { 
    Printer, 
    ArrowRight, 
    FileText, 
    ShieldCheck, 
    Calendar, 
    CheckCircle2, 
    Building2,
    Phone,
    Mail,
    QrCode,
    ShoppingBag
} from 'lucide-vue-next'

const props = defineProps<{
    quotation: any
}>()

const printQuotation = () => {
    window.print()
}
</script>

<template>
    <Head :title="`عرض سعر رسمي - ${quotation.quotation_number}`" />

    <div class="min-h-screen bg-slate-100 dark:bg-slate-950 py-8 px-4 sm:px-6 print:p-0 print:bg-white text-slate-800 dark:text-slate-200">
        <!-- Top Toolbar (Hidden when printing) -->
        <div class="max-w-4xl mx-auto mb-6 flex items-center justify-between print:hidden">
            <Link 
                :href="route('cart.index')" 
                class="inline-flex items-center gap-2 text-sm font-bold text-slate-600 dark:text-slate-400 hover:text-indigo-600 transition"
            >
                <ArrowRight class="w-4 h-4" />
                العودة إلى سلة المشتريات
            </Link>
            <div class="flex items-center gap-3">
                <Link
                    :href="route('checkout.index')"
                    class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow flex items-center gap-2 transition"
                >
                    <ShoppingBag class="w-4 h-4" />
                    تحويل إلى طلب شراء فوري
                </Link>
                <button
                    @click="printQuotation"
                    class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow flex items-center gap-2 transition"
                >
                    <Printer class="w-4 h-4" />
                    طباعة / حفظ كـ PDF
                </button>
            </div>
        </div>

        <!-- Official Quotation Document -->
        <div class="max-w-4xl mx-auto bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl p-8 sm:p-12 shadow-xl print:shadow-none print:border-none print:p-0">
            <!-- Document Header -->
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center pb-8 border-b-2 border-slate-100 dark:border-slate-800 gap-6">
                <div class="flex items-center gap-4">
                    <div class="w-14 h-14 rounded-2xl overflow-hidden border-2 border-emerald-500/30 bg-slate-900 shadow-lg shrink-0">
                        <img src="/images/nova_logo.jpg" alt="NOVA Store" class="w-full h-full object-cover" />
                    </div>
                    <div>
                        <h1 class="text-xl font-black tracking-tight text-slate-900 dark:text-white">NOVA STORE | شركة نوفا للإلكترونيات والتقنية</h1>
                        <p class="text-xs text-slate-500 mt-0.5">NOVA Tech & ERP Solutions Ltd. • سجل تجاري: 56392014</p>
                        <div class="flex items-center gap-4 text-[11px] text-slate-400 mt-1.5">
                            <span class="flex items-center gap-1"><Phone class="w-3 h-3 text-emerald-500" /> 0599-000000</span>
                            <span class="flex items-center gap-1"><Mail class="w-3 h-3 text-emerald-500" /> sales@nova-store.ps</span>
                            <span>فلسطين</span>
                        </div>
                    </div>
                </div>

                <div class="text-start sm:text-end bg-emerald-50 dark:bg-emerald-950/40 p-4 rounded-2xl border border-emerald-100 dark:border-emerald-900/50">
                    <div class="text-xs font-semibold text-emerald-600 dark:text-emerald-400">عرض سعر رسمي معتمد</div>
                    <div class="text-lg font-black text-slate-900 dark:text-white mt-0.5">{{ quotation.quotation_number }}</div>
                    <div class="text-[11px] text-slate-500 mt-1">تاريخ الإصدار: {{ quotation.date }}</div>
                    <div class="text-[11px] font-bold text-rose-600 dark:text-rose-400">صالح لغاية: {{ quotation.expiry_date }} (15 يوماً)</div>
                </div>
            </div>

            <!-- Customer & Quotation Info Grid -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6 my-8 p-6 bg-slate-50 dark:bg-slate-800/40 rounded-2xl border border-slate-200/60 dark:border-slate-800">
                <div>
                    <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">معلومات العميل / الجهة الطالبة</h3>
                    <div class="text-sm font-black text-slate-900 dark:text-white">{{ quotation.party?.name || 'عميل تجاري' }}</div>
                    <div class="text-xs text-slate-600 dark:text-slate-300 mt-1">الهاتف: {{ quotation.party?.phone || 'غير محدد' }}</div>
                    <div class="text-xs text-slate-600 dark:text-slate-300">العنوان: {{ quotation.party?.address || 'فلسطين' }}</div>
                </div>

                <div>
                    <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">بيانات المستودع والضمان</h3>
                    <div class="text-xs text-slate-700 dark:text-slate-300">المستودع المصدر: <span class="font-bold text-slate-900 dark:text-white">{{ quotation.store?.name || 'المستودع الرئيسي' }}</span></div>
                    <div class="text-xs text-slate-700 dark:text-slate-300 mt-1">الضمان: <span class="font-bold text-emerald-600 dark:text-emerald-400">كفالة وصيانة رسمية معتمدة 12-24 شهر</span></div>
                    <div class="text-xs text-slate-700 dark:text-slate-300 mt-1">العملة المعتمدة: <span class="font-bold text-emerald-600 dark:text-emerald-400">شيكل إسرائيلي (ILS ₪)</span></div>
                </div>
            </div>

            <!-- Quotation Lines Table -->
            <div class="overflow-x-auto my-6">
                <table class="w-full text-start text-xs">
                    <thead>
                        <tr class="border-b-2 border-slate-200 dark:border-slate-700 text-slate-500 font-bold">
                            <th class="pb-3 text-start">#</th>
                            <th class="pb-3 text-start">بيان الصنف والمواصفات</th>
                            <th class="pb-3 text-center">الكمية</th>
                            <th class="pb-3 text-end">سعر الوحدة</th>
                            <th class="pb-3 text-end">الإجمالي (₪)</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                        <tr v-for="(line, idx) in quotation.lines" :key="line.id" class="hover:bg-slate-50/50 dark:hover:bg-slate-800/20">
                            <td class="py-3.5 text-slate-400 font-bold">{{ idx + 1 }}</td>
                            <td class="py-3.5">
                                <div class="font-bold text-slate-900 dark:text-white text-sm">{{ line.item?.name || 'صنف تقني' }}</div>
                                <div class="text-[11px] text-slate-500 mt-0.5 line-clamp-1">{{ line.item?.description }}</div>
                            </td>
                            <td class="py-3.5 text-center font-bold">{{ line.quantity }}</td>
                            <td class="py-3.5 text-end font-semibold">{{ line.unit_price }} ₪</td>
                            <td class="py-3.5 text-end font-black text-emerald-600 dark:text-emerald-400">{{ line.total_price ?? line.total }} ₪</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Summary & Official Stamp Box -->
            <div class="mt-8 pt-6 border-t-2 border-slate-100 dark:border-slate-800 flex flex-col sm:flex-row justify-between items-start sm:items-end gap-6">
                <!-- Terms & Stamp -->
                <div class="space-y-3 max-w-md">
                    <div class="text-xs font-bold text-slate-700 dark:text-slate-300">الشروط والأحكام:</div>
                    <ul class="text-[11px] text-slate-500 space-y-1 list-disc list-inside">
                        <li>الأسعار شاملة ضريبة القيمة المضافة ما لم يذكر خلاف ذلك.</li>
                        <li>التسليم فوري من المستودعات أو خلال 24-48 ساعة لجميع محافظات الوطن.</li>
                        <li>هذا العرض صادر آلياً من نظام NOVA STORE ERP المحاسبي المعتمد ولا يتطلب توقيعاً خطياً.</li>
                    </ul>

                    <!-- Official Stamp simulation -->
                    <div class="inline-flex items-center gap-3 p-3 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 rounded-2xl mt-4">
                        <CheckCircle2 class="w-8 h-8 text-emerald-600" />
                        <div>
                            <div class="text-xs font-black text-emerald-800 dark:text-emerald-300">معتمد رسمياً ومحمي بنظام الـ ERP</div>
                            <div class="text-[10px] text-emerald-600 dark:text-emerald-400">كود التحقق الرقمي: {{ quotation.quotation_number }}</div>
                        </div>
                    </div>
                </div>

                <!-- Totals Box -->
                <div class="w-full sm:w-72 bg-slate-900 text-white p-6 rounded-2xl shadow-xl">
                    <div class="flex justify-between text-xs text-slate-400 mb-2">
                        <span>المجموع الفرعي:</span>
                        <span>{{ quotation.total_amount }} ₪</span>
                    </div>
                    <div class="flex justify-between text-xs text-slate-400 mb-3 pb-3 border-b border-slate-800">
                        <span>الخصم المعتمد:</span>
                        <span class="text-emerald-400 font-bold">0.00 ₪</span>
                    </div>
                    <div class="flex justify-between items-center text-sm font-black">
                        <span>المبلغ الإجمالي النهائي:</span>
                        <span class="text-xl text-amber-400">{{ quotation.total_amount }} ₪</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
