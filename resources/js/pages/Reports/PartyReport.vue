<script setup lang="ts">
import { ref, computed } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, router, Link } from '@inertiajs/vue3';
import { Search, Calendar, FileText, User, Banknote, CreditCard } from 'lucide-vue-next';
import SearchableSelect from '@/components/SearchableSelect.vue';
import ReportFilterBar from './Components/ReportFilterBar.vue';

const props = defineProps<{
    parties: any[];
    reportData: {
        party: any | null;
        balance: number;
        totalPurchases: number;
        invoices: any[];
    };
    filters: {
        party_id?: string;
        from_date?: string;
        to_date?: string;
    };
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'التقارير', href: '/reports' },
    { title: 'تقرير الزبائن والموردين', href: '/reports/party-statement' },
];

const partyId = ref(props.filters.party_id || '');

const partyOptions = computed(() => {
    return props.parties.map(p => ({
        value: p.id,
        label: `${p.name} - ${p.phone || 'بدون هاتف'} (${p.type === 'customer' ? 'عميل' : 'مورد'})`,
    }));
});

const applyFilters = (newFilters: any) => {
    if (!partyId.value) {
        alert('الرجاء اختيار الزبون/المورد أولاً');
        return;
    }
    router.get('/reports/party-statement', { ...newFilters, party_id: partyId.value }, {
        preserveState: true,
        replace: true,
    });
};

const clearFilters = () => {
    partyId.value = '';
    router.get('/reports/party-statement', {}, { preserveState: true, replace: true });
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
    <Head title="تقرير الزبائن والموردين" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-6 lg:p-10 max-w-7xl mx-auto" dir="rtl">
            
            <div class="flex items-center gap-4 bg-white/40 dark:bg-gray-800/40 backdrop-blur-lg p-6 rounded-3xl border border-white/50 dark:border-gray-700/50 shadow-xl mb-2">
                <div class="p-4 bg-gradient-to-br from-amber-500 to-orange-600 rounded-2xl text-white shadow-lg shadow-amber-500/30">
                    <User class="w-8 h-8" />
                </div>
                <div>
                    <h1 class="text-3xl font-extrabold text-gray-900 dark:text-white">تقرير الزبائن والموردين</h1>
                    <p class="text-gray-500 dark:text-gray-400 mt-1">ابحث عن أي زبون لعرض مسحوباته وديونه أو فواتيره السابقة.</p>
                </div>
            </div>

            <!-- Filter Card -->
            <ReportFilterBar 
                :filters="filters" 
                @filter="applyFilters" 
                @clear="clearFilters"
            >
                <template #custom-filters>
                    <div class="w-full lg:flex-1 min-w-[250px]">
                        <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">الزبون / المورد <span class="text-red-500">*</span></label>
                        <SearchableSelect 
                            v-model="partyId" 
                            :options="partyOptions"
                            placeholder="ابحث بالاسم أو رقم الجوال..."
                            :required="true"
                        />
                    </div>
                </template>
            </ReportFilterBar>

            <!-- Report Results -->
            <div v-if="reportData.party" class="space-y-6">
                <!-- Summary Cards -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <!-- Balance Card -->
                    <div class="glass-card p-6 flex items-center gap-4 border-r-4 border-r-indigo-500">
                        <div class="p-4 bg-indigo-50 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-full">
                            <Banknote class="w-8 h-8" />
                        </div>
                        <div>
                            <p class="text-sm font-bold text-gray-500 dark:text-gray-400">رصيد الحساب الحالي</p>
                            <h3 class="text-2xl font-black mt-1" :class="reportData.balance >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'">
                                <span v-if="reportData.balance > 0">مدين (عليه) بـ </span>
                                <span v-else-if="reportData.balance < 0">دائن (له) بـ </span>
                                <span v-else>رصيد مصفر </span>
                                {{ Math.abs(reportData.balance).toFixed(2) }}
                            </h3>
                        </div>
                    </div>

                    <!-- Purchases Card -->
                    <div class="glass-card p-6 flex items-center gap-4 border-r-4 border-r-blue-500">
                        <div class="p-4 bg-blue-50 dark:bg-blue-900/50 text-blue-600 dark:text-blue-400 rounded-full">
                            <CreditCard class="w-8 h-8" />
                        </div>
                        <div>
                            <p class="text-sm font-bold text-gray-500 dark:text-gray-400">
                                {{ reportData.party.type === 'customer' ? 'إجمالي المشتريات منا' : 'إجمالي المشتريات منه' }}
                            </p>
                            <h3 class="text-2xl font-black mt-1 text-gray-900 dark:text-white">
                                {{ Number(reportData.totalPurchases).toFixed(2) }}
                            </h3>
                        </div>
                    </div>
                    
                    <div class="glass-card p-6 flex items-center gap-4 border-r-4 border-r-purple-500">
                        <div class="p-4 bg-purple-50 dark:bg-purple-900/50 text-purple-600 dark:text-purple-400 rounded-full">
                            <FileText class="w-8 h-8" />
                        </div>
                        <div>
                            <p class="text-sm font-bold text-gray-500 dark:text-gray-400">عدد الفواتير بالفترة المحددة</p>
                            <h3 class="text-2xl font-black mt-1 text-gray-900 dark:text-white">
                                {{ reportData.invoices.length }} فاتورة
                            </h3>
                        </div>
                    </div>
                </div>

                <!-- Invoices Table -->
                <div class="glass-card overflow-hidden">
                    <div class="p-6 border-b border-gray-100 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-800/50 flex justify-between items-center">
                        <h2 class="text-xl font-bold text-gray-900 dark:text-white">سجل الفواتير للفترة المحددة</h2>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full text-right">
                            <thead class="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
                                <tr>
                                    <th class="py-4 px-6 text-sm font-bold text-gray-500 dark:text-gray-400">التاريخ</th>
                                    <th class="py-4 px-6 text-sm font-bold text-gray-500 dark:text-gray-400">رقم الفاتورة</th>
                                    <th class="py-4 px-6 text-sm font-bold text-gray-500 dark:text-gray-400">نوع الفاتورة</th>
                                    <th class="py-4 px-6 text-sm font-bold text-gray-500 dark:text-gray-400">المخزن</th>
                                    <th class="py-4 px-6 text-sm font-bold text-gray-500 dark:text-gray-400">الإجمالي</th>
                                    <th class="py-4 px-6 text-center text-sm font-bold text-gray-500 dark:text-gray-400">تفاصيل</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100 dark:divide-gray-800 bg-white dark:bg-gray-800">
                                <tr v-for="invoice in reportData.invoices" :key="invoice.id" class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                                    <td class="py-4 px-6 text-gray-900 dark:text-gray-100">{{ invoice.date }}</td>
                                    <td class="py-4 px-6 text-gray-900 dark:text-gray-100 font-bold">INV-{{ invoice.id }}</td>
                                    <td class="py-4 px-6">
                                        <span class="px-3 py-1 rounded-full text-xs font-bold"
                                            :class="{
                                                'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400': invoice.type === 'sale',
                                                'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400': invoice.type === 'purchase',
                                                'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400': invoice.type.includes('return')
                                            }">
                                            {{ getInvoiceTypeName(invoice.type) }}
                                        </span>
                                    </td>
                                    <td class="py-4 px-6 text-gray-900 dark:text-gray-100">{{ invoice.store?.name }}</td>
                                    <td class="py-4 px-6 font-bold text-indigo-700 dark:text-indigo-400">{{ Number(invoice.total_amount).toFixed(2) }}</td>
                                    <td class="py-4 px-6 text-center">
                                        <Link :href="`/invoices/${invoice.id}`" class="text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300 font-bold text-sm bg-indigo-50 dark:bg-indigo-900/30 px-3 py-1.5 rounded-lg">
                                            عرض الفاتورة
                                        </Link>
                                    </td>
                                </tr>
                                <tr v-if="reportData.invoices.length === 0">
                                    <td colspan="6" class="py-8 text-center text-gray-500 dark:text-gray-400">
                                        لا توجد أي فواتير مسجلة لهذا الحساب في الفترة المحددة.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            <div v-else-if="filters.party_id" class="glass-card p-12 text-center text-gray-500 flex flex-col items-center justify-center">
                <FileText class="w-16 h-16 text-gray-300 mb-4" />
                <h3 class="text-xl font-bold">الحساب غير موجود</h3>
                <p>يرجى التحقق من عملية البحث.</p>
            </div>
            
            <div v-else class="glass-card p-12 text-center text-gray-500 flex flex-col items-center justify-center border-dashed border-2">
                <Search class="w-16 h-16 text-gray-300 mb-4" />
                <h3 class="text-xl font-bold">ابحث عن زبون أو مورد</h3>
                <p>قم باختيار جهة من القائمة في الأعلى لاستعراض تقاريرها المالية فوراً.</p>
            </div>

        </div>
    </AppLayout>
</template>
