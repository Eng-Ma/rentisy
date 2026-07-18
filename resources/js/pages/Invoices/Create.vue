<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm, usePage } from '@inertiajs/vue3';
import { FileText, Plus, Trash2, Save, AlertCircle, RefreshCw } from 'lucide-vue-next';
import SearchableSelect from '@/components/SearchableSelect.vue';
import QuickAddPartyModal from '@/components/QuickAddPartyModal.vue';
import QuickAddItemModal from '@/components/QuickAddItemModal.vue';
import QuickAddStoreModal from '@/components/QuickAddStoreModal.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'الفواتير', href: '/invoices' },
    { title: 'إنشاء فاتورة', href: '/invoices/create' },
];

const props = defineProps<{
    parties: any[];
    stores: any[];
    items: any[];
}>();

const form = useForm({
    type: 'sale',
    date: new Date().toISOString().split('T')[0],
    party_id: '',
    store_id: props.stores.length > 0 ? props.stores[0].id : '',
    notes: '',
    lines: [
        { item_id: '', quantity: 1, unit_price: 0, total_price: 0 },
    ]
});

// Options formatting for SearchableSelect
const partyOptions = computed(() => {
    return props.parties.map(p => ({
        value: p.id,
        label: `${p.name} (${p.type === 'customer' ? 'عميل' : 'مورد'})`
    }));
});

const itemOptions = computed(() => {
    return props.items.map(i => ({
        value: i.id,
        label: i.name,
        barcode: i.barcode
    }));
});

// Update total price when quantity or unit price changes
const updateLineTotal = (index: number) => {
    const line = form.lines[index];
    line.total_price = Number(line.quantity) * Number(line.unit_price);
};

// Auto-fill price when item is selected
const onItemChange = (index: number, itemId: any) => {
    const line = form.lines[index];
    line.item_id = itemId;
    const selectedItem = props.items.find(i => i.id === itemId);
    if (selectedItem) {
        line.unit_price = form.type === 'sale' || form.type === 'sale_return' 
            ? selectedItem.sales_price 
            : selectedItem.purchase_price;
        updateLineTotal(index);
    }
};

// Recalculate prices if invoice type changes
watch(() => form.type, () => {
    form.lines.forEach((line, index) => {
        if(line.item_id) onItemChange(index, line.item_id);
    });
});

const totalAmount = computed(() => {
    return form.lines.reduce((sum, line) => sum + Number(line.total_price || 0), 0);
});

const addLine = () => {
    form.lines.push({ item_id: '', quantity: 1, unit_price: 0, total_price: 0 });
};

const removeLine = (index: number) => {
    if (form.lines.length > 1) {
        form.lines.splice(index, 1);
    }
};

const submit = () => {
    form.post('/invoices');
};

// Modals State
const showPartyModal = ref(false);
const showItemModal = ref(false);
const showStoreModal = ref(false);
const pendingItemIndex = ref<number | null>(null);

const openItemModalForLine = (index: number) => {
    pendingItemIndex.value = index;
    showItemModal.value = true;
};

// Handle saved modals
const onStoreSaved = (newStore: any) => {
    if (newStore && newStore.id) {
        form.store_id = newStore.id;
    }
};
const onPartySaved = (newParty: any) => {
    if (newParty && newParty.id) {
        form.party_id = newParty.id;
    }
};

const onItemSaved = (newItem: any) => {
    if (newItem && newItem.id) {
        if (pendingItemIndex.value !== null) {
            // Automatically select the new item for the line that requested the modal
            onItemChange(pendingItemIndex.value, newItem.id);
            pendingItemIndex.value = null;
        } else {
            // General button was clicked: add a new line or use the last empty line
            const lastLine = form.lines[form.lines.length - 1];
            if (!lastLine.item_id) {
                onItemChange(form.lines.length - 1, newItem.id);
            } else {
                form.lines.push({ item_id: '', quantity: 1, unit_price: 0, total_price: 0 });
                onItemChange(form.lines.length - 1, newItem.id);
            }
        }
    }
};
</script>

<template>
    <Head title="فاتورة جديدة" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex flex-col gap-6 p-6 lg:p-10" dir="rtl">
            
            <!-- Header -->
            <div class="flex flex-col md:flex-row justify-between items-center bg-white/40 dark:bg-gray-800/40 backdrop-blur-lg p-6 rounded-3xl border border-white/50 dark:border-gray-700/50 shadow-xl">
                <div class="flex items-center gap-4">
                    <div class="p-4 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-2xl text-white shadow-lg shadow-indigo-500/30">
                        <FileText class="w-8 h-8" />
                    </div>
                    <div>
                        <h1 class="text-3xl font-extrabold text-gray-900 dark:text-white">إنشاء فاتورة جديدة</h1>
                        <p class="text-gray-500 dark:text-gray-400 mt-1">قم بتعبئة بيانات الفاتورة والأصناف بكل سهولة.</p>
                    </div>
                </div>
            </div>

            <form @submit.prevent="submit" class="glass-card p-6 lg:p-8 max-w-6xl mx-auto w-full space-y-8 relative overflow-hidden">
                <!-- Section: Info -->
                <div>
                    <h2 class="text-xl font-bold text-indigo-800 dark:text-indigo-400 mb-6 flex items-center gap-2">
                        <span class="w-8 h-8 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center text-sm">1</span>
                        المعلومات الأساسية
                    </h2>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">نوع الفاتورة <span class="text-red-500">*</span></label>
                            <select v-model="form.type" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50 font-bold text-indigo-700 dark:text-indigo-400">
                                <option value="sale">فاتورة مبيعات</option>
                                <option value="purchase">فاتورة مشتريات</option>
                                <option value="sale_return">مردود مبيعات</option>
                                <option value="purchase_return">مردود مشتريات</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">التاريخ <span class="text-red-500">*</span></label>
                            <input type="date" v-model="form.date" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                            <div v-if="form.errors.date" class="text-red-500 text-sm mt-1">{{ form.errors.date }}</div>
                        </div>
                        <div class="col-span-1 md:col-span-2">
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">العميل / المورد <span class="text-red-500">*</span></label>
                            <div class="flex gap-2">
                                <div class="flex-1">
                                    <SearchableSelect 
                                        v-model="form.party_id" 
                                        :options="partyOptions"
                                        placeholder="ابحث عن اسم الجهة..."
                                        :required="true"
                                    />
                                    <div v-if="form.errors.party_id" class="text-red-500 text-sm mt-1">{{ form.errors.party_id }}</div>
                                </div>
                                <button type="button" @click="showPartyModal = true" class="px-3 py-2 bg-indigo-50 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-xl hover:bg-indigo-100 dark:hover:bg-indigo-800 border border-indigo-200 dark:border-indigo-700 transition-colors flex items-center justify-center" title="إضافة جهة جديدة">
                                    <Plus class="w-5 h-5" />
                                </button>
                            </div>
                        </div>
                        <div class="col-span-1 md:col-span-2">
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">المخزن المتأثر <span class="text-red-500">*</span></label>
                            <div class="flex gap-2">
                                <div class="flex-1">
                                    <select v-model="form.store_id" required class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                                        <option value="" disabled>اختر المخزن</option>
                                        <option v-for="s in stores" :key="s.id" :value="s.id">{{ s.name }}</option>
                                    </select>
                                </div>
                                <button type="button" @click="showStoreModal = true" class="px-3 py-2 bg-indigo-50 dark:bg-indigo-900/50 text-indigo-600 dark:text-indigo-400 rounded-xl hover:bg-indigo-100 dark:hover:bg-indigo-800 border border-indigo-200 dark:border-indigo-700 transition-colors flex items-center justify-center" title="إضافة مخزن جديد">
                                    <Plus class="w-5 h-5" />
                                </button>
                            </div>
                        </div>
                        <div class="col-span-1 md:col-span-2">
                            <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">ملاحظات إضافية</label>
                            <input type="text" v-model="form.notes" placeholder="ملاحظات تطبع على الفاتورة..." class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50">
                        </div>
                    </div>
                </div>

                <!-- Section: Lines -->
                <div class="pt-6 border-t border-gray-200 dark:border-gray-700">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-xl font-bold text-indigo-800 dark:text-indigo-400 flex items-center gap-2">
                            <span class="w-8 h-8 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center text-sm">2</span>
                            محتويات الفاتورة
                        </h2>
                        <button type="button" @click="showItemModal = true" class="text-sm font-bold text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300 flex items-center gap-1 bg-indigo-50 dark:bg-indigo-900/30 px-3 py-1.5 rounded-lg transition-colors">
                            <Plus class="w-4 h-4" /> إضافة صنف للمخزن
                        </button>
                    </div>

                    <div v-if="form.errors.lines" class="text-red-500 text-sm mb-4 p-3 bg-red-50 dark:bg-red-900/30 rounded-xl flex items-center gap-2">
                        <AlertCircle class="w-5 h-5"/> {{ form.errors.lines }}
                    </div>
                    
                    <div class="bg-gray-50/50 dark:bg-gray-900/30 rounded-xl border border-gray-200 dark:border-gray-700">
                        <!-- Desktop Header -->
                        <div class="hidden md:flex items-center gap-4 p-4 bg-gray-100 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 text-sm font-bold text-gray-700 dark:text-gray-300 rounded-t-xl">
                            <div class="flex-1">الصنف</div>
                            <div class="w-32 text-center">الكمية</div>
                            <div class="w-40 text-center">سعر الوحدة</div>
                            <div class="w-40 text-center">الإجمالي</div>
                            <div class="w-12"></div>
                        </div>

                        <!-- Lines -->
                        <div class="divide-y divide-gray-200 dark:divide-gray-700">
                            <div v-for="(line, index) in form.lines" :key="index" class="p-4 flex flex-col md:flex-row md:items-center gap-4 transition-colors hover:bg-white/50 dark:hover:bg-gray-800/50">
                                
                                <div class="flex-1 w-full relative">
                                    <label class="md:hidden text-xs font-bold text-gray-500 mb-1 block">الصنف</label>
                                    <SearchableSelect 
                                        :model-value="line.item_id"
                                        @update:model-value="(val) => onItemChange(index, val)"
                                        :options="itemOptions"
                                        placeholder="ابحث بالاسم أو الباركود..."
                                        :required="true"
                                    />
                                </div>
                                
                                <div class="flex gap-4 w-full md:w-auto">
                                    <div class="flex-1 md:w-32">
                                        <label class="md:hidden text-xs font-bold text-gray-500 mb-1 block">الكمية</label>
                                        <input type="number" step="0.01" v-model="line.quantity" @input="updateLineTotal(index)" required min="0.01" 
                                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white text-center">
                                    </div>
                                    <div class="flex-1 md:w-40">
                                        <label class="md:hidden text-xs font-bold text-gray-500 mb-1 block">السعر</label>
                                        <input type="number" step="0.01" v-model="line.unit_price" @input="updateLineTotal(index)" required min="0" 
                                            class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white text-center">
                                    </div>
                                </div>

                                <div class="flex items-center justify-between w-full md:w-auto gap-4 mt-2 md:mt-0">
                                    <div class="flex-1 md:w-40">
                                        <label class="md:hidden text-xs font-bold text-gray-500 mb-1 block">الإجمالي</label>
                                        <input type="number" readonly v-model="line.total_price" 
                                            class="block w-full rounded-xl border-gray-200 shadow-sm bg-gray-100 dark:bg-gray-900 dark:border-gray-700 dark:text-indigo-400 font-bold text-center text-lg">
                                    </div>
                                    <div class="w-12 text-left pt-6 md:pt-0">
                                        <button type="button" @click="removeLine(index)" :disabled="form.lines.length <= 1"
                                            class="text-gray-400 hover:text-red-500 disabled:opacity-30 disabled:hover:text-gray-400 p-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/30 transition-colors">
                                            <Trash2 class="w-5 h-5" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <button type="button" @click="addLine" class="mt-4 text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 font-bold flex items-center gap-1 bg-indigo-50 dark:bg-indigo-900/30 px-4 py-2 rounded-xl transition-colors">
                        <Plus class="w-5 h-5" /> إضافة سطر جديد
                    </button>
                </div>

                <!-- Footer Summary -->
                <div class="mt-8 bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800 p-6 lg:p-8 rounded-2xl border-2 border-indigo-500/20 flex flex-col md:flex-row justify-between items-center gap-6 shadow-inner">
                    <div class="flex items-start gap-3">
                        <RefreshCw class="w-6 h-6 text-indigo-500 mt-1" />
                        <div>
                            <h4 class="font-bold text-gray-900 dark:text-white">الأتمتة المحاسبية مفعلة</h4>
                            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                                حفظ هذه الفاتورة سيقوم فوراً بتحديث كميات مستودع ({{ stores.find(s => s.id === form.store_id)?.name || 'غير محدد' }}) وتوليد قيد يومية متوازن آلياً.
                            </p>
                        </div>
                    </div>
                    <div class="text-left w-full md:w-auto bg-white dark:bg-gray-800 p-4 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 flex flex-col items-center justify-center">
                        <span class="text-sm font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wide">الإجمالي النهائي</span>
                        <span class="font-black text-4xl text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400 mt-1">
                            {{ totalAmount.toFixed(2) }}
                        </span>
                    </div>
                </div>

                <!-- Actions -->
                <div class="flex justify-end pt-4 mt-4">
                    <button type="submit" :disabled="form.processing || form.lines.length === 0" 
                        class="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 disabled:opacity-50 text-white font-bold py-4 px-10 rounded-xl text-xl shadow-xl hover:shadow-indigo-500/40 transition-all transform hover:-translate-y-1 flex items-center gap-3">
                        <Save class="w-6 h-6" />
                        حفظ الفاتورة وترحيلها
                    </button>
                </div>
            </form>
        </div>

        <!-- Modals -->
        <QuickAddPartyModal 
            :show="showPartyModal" 
            @close="showPartyModal = false" 
            @saved="onPartySaved" 
        />
        
        <QuickAddStoreModal 
            :show="showStoreModal" 
            @close="showStoreModal = false" 
            @saved="onStoreSaved" 
        />

        <QuickAddItemModal 
            :show="showItemModal" 
            @close="showItemModal = false" 
            @saved="onItemSaved" 
        />
    </AppLayout>
</template>
