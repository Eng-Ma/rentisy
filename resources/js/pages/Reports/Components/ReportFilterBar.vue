<script setup lang="ts">
import { ref, watch } from 'vue';
import { Search, X, Calendar } from 'lucide-vue-next';

const props = defineProps<{
    filters: {
        from_date?: string;
        to_date?: string;
        [key: string]: any;
    };
    isLoading?: boolean;
}>();

const emit = defineEmits<{
    (e: 'filter', filters: Record<string, any>): void;
    (e: 'clear'): void;
}>();

const localFilters = ref({
    from_date: props.filters?.from_date || '',
    to_date: props.filters?.to_date || '',
});

watch(() => props.filters, (newFilters) => {
    localFilters.value.from_date = newFilters?.from_date || '';
    localFilters.value.to_date = newFilters?.to_date || '';
}, { deep: true });

const applyFilters = () => {
    emit('filter', { ...localFilters.value });
};

const clearFilters = () => {
    localFilters.value = { from_date: '', to_date: '' };
    emit('clear');
};
</script>

<template>
    <div class="glass-card p-4 lg:p-6 mb-6">
        <div class="flex flex-col lg:flex-row gap-4 items-end">
            <!-- Optional Custom Slots (e.g. Account Selection, Party Selection) -->
            <slot name="custom-filters"></slot>

            <!-- From Date -->
            <div class="w-full lg:w-48">
                <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">من تاريخ</label>
                <div class="relative">
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <Calendar class="w-4 h-4 text-gray-400" />
                    </div>
                    <input type="date" v-model="localFilters.from_date" 
                        class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50 pr-10 text-sm">
                </div>
            </div>

            <!-- To Date -->
            <div class="w-full lg:w-48">
                <label class="block text-sm font-bold text-gray-700 dark:text-gray-300 mb-2">إلى تاريخ</label>
                <div class="relative">
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <Calendar class="w-4 h-4 text-gray-400" />
                    </div>
                    <input type="date" v-model="localFilters.to_date" 
                        class="block w-full rounded-xl border-gray-200 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800/50 dark:border-gray-700 dark:text-white backdrop-blur-sm transition-all bg-white/50 pr-10 text-sm">
                </div>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-2 w-full lg:w-auto mt-4 lg:mt-0">
                <button @click="applyFilters" :disabled="isLoading"
                    class="flex-1 lg:flex-none bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2.5 px-6 rounded-xl shadow-lg shadow-indigo-500/30 transition-all flex items-center justify-center gap-2 disabled:opacity-50 text-sm">
                    <Search class="w-4 h-4" />
                    عرض التقرير
                </button>
                
                <button @click="clearFilters" :disabled="isLoading"
                    class="flex-1 lg:flex-none bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300 font-bold py-2.5 px-4 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 disabled:opacity-50 text-sm">
                    <X class="w-4 h-4" />
                    مسح
                </button>
            </div>
        </div>
    </div>
</template>
