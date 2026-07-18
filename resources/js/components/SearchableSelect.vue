<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { ChevronDown, Search, X } from 'lucide-vue-next';

const props = defineProps<{
    modelValue: string | number;
    options: Array<{ value: string | number; label: string; [key: string]: any }>;
    placeholder?: string;
    required?: boolean;
    disabled?: boolean;
}>();

const emit = defineEmits(['update:modelValue', 'change']);

const isOpen = ref(false);
const searchQuery = ref('');
const dropdownRef = ref<HTMLElement | null>(null);

const filteredOptions = computed(() => {
    if (!searchQuery.value) return props.options;
    const query = searchQuery.value.toLowerCase();
    return props.options.filter(option => 
        option.label.toLowerCase().includes(query) || 
        (option.barcode && option.barcode.toLowerCase().includes(query))
    );
});

const selectedOption = computed(() => {
    return props.options.find(opt => opt.value === props.modelValue) || null;
});

const toggleDropdown = () => {
    if (props.disabled) return;
    isOpen.value = !isOpen.value;
    if (isOpen.value) {
        searchQuery.value = '';
    }
};

const selectOption = (option: any) => {
    emit('update:modelValue', option.value);
    emit('change', option.value);
    isOpen.value = false;
};

const clearSelection = (e: Event) => {
    e.stopPropagation();
    emit('update:modelValue', '');
    emit('change', '');
};

// Close dropdown when clicking outside
const handleClickOutside = (event: MouseEvent) => {
    if (dropdownRef.value && !dropdownRef.value.contains(event.target as Node)) {
        isOpen.value = false;
    }
};

onMounted(() => {
    document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside);
});
</script>

<template>
    <div class="relative" ref="dropdownRef">
        <!-- Main Select Button -->
        <div 
            @click="toggleDropdown"
            class="flex items-center justify-between w-full min-h-[42px] px-3 py-2 bg-white/50 dark:bg-gray-800/50 backdrop-blur-sm border border-gray-200 dark:border-gray-700 rounded-xl cursor-pointer hover:border-indigo-500 transition-colors shadow-sm"
            :class="{ 'opacity-50 cursor-not-allowed': disabled, 'border-indigo-500 ring-1 ring-indigo-500': isOpen }"
        >
            <div class="flex-1 truncate text-right">
                <span v-if="selectedOption" class="text-gray-900 dark:text-gray-100 font-bold">
                    {{ selectedOption.label }}
                </span>
                <span v-else class="text-gray-500 dark:text-gray-400">
                    {{ placeholder || 'اختر...' }}
                </span>
            </div>
            <div class="flex items-center gap-1">
                <button 
                    v-if="selectedOption && !disabled" 
                    @click.stop="clearSelection"
                    class="p-1 text-gray-400 hover:text-red-500 rounded-full hover:bg-red-50 dark:hover:bg-red-900/30 transition-colors"
                >
                    <X class="w-4 h-4" />
                </button>
                <ChevronDown class="w-4 h-4 text-gray-500 transition-transform duration-200" :class="{ 'rotate-180': isOpen }" />
            </div>
        </div>

        <!-- Hidden input for required validation -->
        <input type="text" :value="modelValue" class="hidden" :required="required" />

        <!-- Dropdown Menu -->
        <div 
            v-if="isOpen" 
            class="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-2xl overflow-hidden"
        >
            <!-- Search Input -->
            <div class="p-2 border-b border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50">
                <div class="relative">
                    <Search class="w-4 h-4 absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input 
                        type="text" 
                        v-model="searchQuery" 
                        placeholder="ابحث هنا..." 
                        class="w-full pl-3 pr-9 py-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-sm focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 dark:text-white"
                        @click.stop
                        autofocus
                    >
                </div>
            </div>

            <!-- Options List -->
            <ul class="max-h-60 overflow-y-auto py-1">
                <li 
                    v-for="option in filteredOptions" 
                    :key="option.value"
                    @click="selectOption(option)"
                    class="px-4 py-2 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 cursor-pointer text-gray-700 dark:text-gray-200 transition-colors text-right"
                    :class="{ 'bg-indigo-50 dark:bg-indigo-900/30 font-bold text-indigo-700 dark:text-indigo-400': option.value === modelValue }"
                >
                    {{ option.label }}
                    <span v-if="option.barcode" class="text-xs text-gray-400 block">{{ option.barcode }}</span>
                </li>
                <li v-if="filteredOptions.length === 0" class="px-4 py-3 text-center text-gray-500 text-sm">
                    لا توجد نتائج مطابقة للبحث
                </li>
            </ul>
        </div>
    </div>
</template>
