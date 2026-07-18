<script setup lang="ts">
import { ref } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, Link } from '@inertiajs/vue3';
import { Printer, ArrowRight, FileText, Download } from 'lucide-vue-next';

const props = defineProps<{
    invoice: any;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'الفواتير', href: '/invoices' },
    { title: `فاتورة رقم #${props.invoice.id}`, href: `/invoices/${props.invoice.id}` },
];

const printInvoice = () => {
    window.print();
};

const getInvoiceTypeName = (type: string) => {
    const types: Record<string, string> = {
        sale: 'فاتورة مبيعات',
        purchase: 'فاتورة مشتريات',
        sale_return: 'مردود مبيعات',
        purchase_return: 'مردود مشتريات'
    };
    return types[type] || type;
};
</script>

<template>
    <Head :title="`فاتورة #${invoice.id}`" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="p-6 lg:p-10" dir="rtl">
            
            <!-- Action Bar (Hidden when printing) -->
            <div class="print:hidden mb-6 flex flex-col md:flex-row justify-between items-center gap-4 bg-white/50 dark:bg-gray-800/50 backdrop-blur-md p-4 rounded-2xl border border-gray-200 dark:border-gray-700 shadow-sm">
                <Link href="/invoices" class="inline-flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 font-bold transition-colors">
                    <ArrowRight class="w-5 h-5" />
                    العودة للقائمة
                </Link>
                <div class="flex gap-3">
                    <button @click="printInvoice" class="inline-flex items-center gap-2 px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-lg shadow-indigo-500/30 transition-all transform hover:-translate-y-0.5">
                        <Printer class="w-5 h-5" />
                        طباعة الفاتورة
                    </button>
                </div>
            </div>

            <!-- Printable Invoice Paper -->
            <div class="print:!shadow-none print:!m-0 print:!p-0 print:!border-0 print:!max-w-none print:!bg-transparent">
                <!-- The A4 wrapper -->
                <div class="bg-white dark:bg-gray-900 mx-auto max-w-4xl shadow-2xl rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden print:!rounded-none print:!shadow-none print:!border-0 text-gray-900 dark:text-gray-100">
                    
                    <!-- Header -->
                    <div class="p-8 md:p-12 border-b border-gray-200 dark:border-gray-800 flex justify-between items-start print:!border-gray-300">
                        <div>
                            <h1 class="text-4xl font-black text-indigo-700 dark:text-indigo-400 print:!text-black">
                                {{ getInvoiceTypeName(invoice.type) }}
                            </h1>
                            <p class="text-gray-500 dark:text-gray-400 mt-2 text-lg font-medium print:!text-gray-600">
                                رقم الفاتورة: <span class="font-bold text-gray-900 dark:text-white print:!text-black">#{{ invoice.id }}</span>
                            </p>
                        </div>
                        <div class="text-left">
                            <div class="w-16 h-16 bg-indigo-100 dark:bg-indigo-900/50 rounded-2xl flex items-center justify-center text-indigo-600 dark:text-indigo-400 mr-auto mb-4 print:!hidden">
                                <FileText class="w-8 h-8" />
                            </div>
                            <h2 class="text-2xl font-bold">شركتك الافتراضية</h2>
                            <p class="text-gray-500 dark:text-gray-400 mt-1 print:!text-gray-600">فلسطين، غزة</p>
                            <p class="text-gray-500 dark:text-gray-400 print:!text-gray-600">هاتف: +970 12 345 6789</p>
                        </div>
                    </div>

                    <!-- Meta Data -->
                    <div class="p-8 md:p-12 grid grid-cols-1 md:grid-cols-2 gap-8 print:!grid-cols-2">
                        <div class="space-y-4">
                            <div>
                                <h3 class="text-sm font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider print:!text-gray-600">إلى ({{ invoice.party.type === 'customer' ? 'العميل' : 'المورد' }})</h3>
                                <p class="text-xl font-black mt-1">{{ invoice.party.name }}</p>
                                <p v-if="invoice.party.phone" class="text-gray-600 dark:text-gray-400 mt-1 print:!text-gray-700">هاتف: <span dir="ltr">{{ invoice.party.phone }}</span></p>
                                <p v-if="invoice.party.address" class="text-gray-600 dark:text-gray-400 print:!text-gray-700">العنوان: {{ invoice.party.address }}</p>
                            </div>
                        </div>
                        <div class="space-y-4 text-left">
                            <div>
                                <h3 class="text-sm font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider print:!text-gray-600">تاريخ الفاتورة</h3>
                                <p class="text-lg font-bold mt-1">{{ invoice.date }}</p>
                            </div>
                            <div>
                                <h3 class="text-sm font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider print:!text-gray-600">المخزن المرتبط</h3>
                                <p class="text-lg font-bold mt-1">{{ invoice.store.name }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- Table -->
                    <div class="px-8 md:px-12 print:!px-0">
                        <table class="w-full text-right border-collapse">
                            <thead>
                                <tr class="bg-gray-50 dark:bg-gray-800 print:!bg-gray-100 border-y border-gray-200 dark:border-gray-700 print:!border-gray-300">
                                    <th class="py-4 px-4 font-bold text-gray-700 dark:text-gray-300 print:!text-black">#</th>
                                    <th class="py-4 px-4 font-bold text-gray-700 dark:text-gray-300 print:!text-black w-1/2">بيان الصنف</th>
                                    <th class="py-4 px-4 font-bold text-gray-700 dark:text-gray-300 print:!text-black text-center">الكمية</th>
                                    <th class="py-4 px-4 font-bold text-gray-700 dark:text-gray-300 print:!text-black text-center">السعر</th>
                                    <th class="py-4 px-4 font-bold text-gray-700 dark:text-gray-300 print:!text-black text-left">الإجمالي</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100 dark:divide-gray-800 print:!divide-gray-200">
                                <tr v-for="(line, index) in invoice.lines" :key="line.id" class="group hover:bg-gray-50 dark:hover:bg-gray-800/50 print:!bg-transparent transition-colors">
                                    <td class="py-4 px-4 text-gray-500">{{ index + 1 }}</td>
                                    <td class="py-4 px-4 font-bold">
                                        {{ line.item.name }}
                                        <div class="text-sm font-normal text-gray-400 mt-1 print:!hidden">{{ line.item.barcode }}</div>
                                    </td>
                                    <td class="py-4 px-4 text-center font-medium">{{ Number(line.quantity).toFixed(2) }}</td>
                                    <td class="py-4 px-4 text-center font-medium">{{ Number(line.unit_price).toFixed(2) }}</td>
                                    <td class="py-4 px-4 text-left font-bold text-indigo-700 dark:text-indigo-400 print:!text-black">
                                        {{ Number(line.total_price).toFixed(2) }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Footer & Totals -->
                    <div class="p-8 md:p-12 flex flex-col md:flex-row justify-between items-end gap-8 mt-4 print:!mt-8">
                        <div class="w-full md:w-1/2 text-gray-500 dark:text-gray-400 print:!text-gray-600">
                            <div v-if="invoice.notes" class="mb-4">
                                <h4 class="font-bold text-gray-700 dark:text-gray-300 print:!text-black mb-1">ملاحظات:</h4>
                                <p class="text-sm leading-relaxed">{{ invoice.notes }}</p>
                            </div>
                            <div class="text-sm mt-8 border-t border-gray-200 dark:border-gray-800 pt-4 print:!border-gray-300">
                                توقيع المستلم: ________________________
                            </div>
                        </div>
                        
                        <div class="w-full md:w-1/3 bg-gray-50 dark:bg-gray-800 print:!bg-gray-50 p-6 rounded-2xl print:!rounded-none border border-gray-100 dark:border-gray-700 print:!border-gray-300">
                            <div class="flex justify-between items-center text-xl font-black">
                                <span>الإجمالي:</span>
                                <span class="text-indigo-700 dark:text-indigo-400 print:!text-black">
                                    {{ Number(invoice.total_amount).toFixed(2) }}
                                </span>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    </AppLayout>
</template>

<style>
@media print {
    body {
        background: white !important;
        color: black !important;
        print-color-adjust: exact;
        -webkit-print-color-adjust: exact;
    }
    
    /* Hide the sidebar and top navigation of AppLayout */
    header, aside, .sidebar-inset > header, nav {
        display: none !important;
    }

    /* Remove padding from the main wrapper */
    main {
        padding: 0 !important;
        margin: 0 !important;
        background: white !important;
    }

    @page {
        margin: 1cm;
        size: A4 portrait;
    }
}
</style>
