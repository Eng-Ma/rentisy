<script setup>
import { Link } from '@inertiajs/vue3';

defineProps({
    links: Array,
});
</script>

<template>
    <div v-if="links && links.length > 3" class="flex flex-wrap -mb-1 mt-4">
        <template v-for="(link, p) in links" :key="p">
            <div
                v-if="link.url === null"
                class="mr-1 mb-1 px-4 py-3 text-sm leading-4 text-gray-400 border rounded dark:border-gray-700"
                v-html="link.label"
            />
            <Link
                v-else
                class="mr-1 mb-1 px-4 py-3 text-sm leading-4 border rounded hover:bg-gray-100 dark:hover:bg-gray-800 focus:border-indigo-500 focus:text-indigo-500 dark:border-gray-700 dark:text-gray-300"
                :class="{ 'bg-gray-100 dark:bg-gray-800 font-bold': link.active }"
                :href="link.url"
                v-html="link.label"
                preserve-scroll
                preserve-state
            />
        </template>
    </div>
</template>
