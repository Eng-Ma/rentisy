<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm, Link } from '@inertiajs/vue3';
import { ArrowLeftRight, Plus, Trash2, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';

const props = defineProps<{
    stores: any[];
    items: any[];
    transferNumber: string;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'مناقلات وحركات المخزون', href: '/stock-transfers' },
    { title: 'حركة مخزون جديدة', href: '#' },
];

const form = useForm({
    transfer_number: props.transferNumber,
    type: 'transfer',
    from_store_id: props.stores[0]?.id || '',
    to_store_id: props.stores[1]?.id || props.stores[0]?.id || '',
    date: new Date().toISOString().split('T')[0],
    notes: '',
    lines: [
        { item_id: props.items[0]?.id || '', quantity: 1, unit_cost: props.items[0]?.purchase_price || 0, notes: '' },
    ],
});

const addLine = () => {
    form.lines.push({
        item_id: props.items[0]?.id || '',
        quantity: 1,
        unit_cost: props.items[0]?.purchase_price || 0,
        notes: '',
    });
};

const removeLine = (index: number) => {
    if (form.lines.length > 1) {
        form.lines.splice(index, 1);
    }
};

const onItemChange = (index: number) => {
    const itm = props.items.find(i => i.id == form.lines[index].item_id);
    if (itm) {
        form.lines[index].unit_cost = itm.purchase_price;
    }
};

const submit = () => {
    form.post(route('stock-transfers.store'));
};
</script>

<template>
    <Head title="تسجيل حركة مخزون جديدة" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <ArrowLeftRight class="w-6 h-6 text-primary" />
                        حركة مخزون ومناقلة جديدة
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        إجراء مناقلة بين المستودعات أو إدخال/إخراج أو تسوية جردية مع تحديث الأرصدة.
                    </p>
                </div>
                <Button variant="outline" as-child>
                    <Link :href="route('stock-transfers.index')">رجوع</Link>
                </Button>
            </div>

            <Card class="border-border shadow-md">
                <form @submit.prevent="submit">
                    <CardHeader class="border-b border-border pb-4">
                        <div class="flex justify-between items-center">
                            <CardTitle class="text-lg">بيانات الحركة</CardTitle>
                            <span class="font-mono text-sm px-3 py-1 bg-muted rounded-md font-bold">
                                {{ form.transfer_number }}
                            </span>
                        </div>
                    </CardHeader>

                    <CardContent class="pt-6 space-y-6">
                        <!-- Type & Date -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="space-y-1.5">
                                <Label>نوع الحركة</Label>
                                <select v-model="form.type" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm font-medium">
                                    <option value="transfer">مناقلة بين مستودعين</option>
                                    <option value="stock_in">سند إدخال بضاعة / أول المدة</option>
                                    <option value="stock_out">سند إخراج بضاعة / تالف</option>
                                    <option value="adjustment">تسوية جردية</option>
                                </select>
                            </div>
                            <div class="space-y-1.5">
                                <Label>تاريخ الحركة</Label>
                                <Input type="date" v-model="form.date" required />
                            </div>
                        </div>

                        <!-- Stores -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div v-if="form.type !== 'stock_in'" class="space-y-1.5">
                                <Label>من مستودع (المصدر)</Label>
                                <select v-model="form.from_store_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option v-for="s in stores" :key="s.id" :value="s.id">
                                        {{ s.name }}
                                    </option>
                                </select>
                            </div>

                            <div v-if="form.type !== 'stock_out'" class="space-y-1.5">
                                <Label>إلى مستودع (الوجهة)</Label>
                                <select v-model="form.to_store_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option v-for="s in stores" :key="s.id" :value="s.id">
                                        {{ s.name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <!-- Items Lines -->
                        <div class="space-y-3">
                            <div class="flex justify-between items-center">
                                <Label class="text-base font-bold">الأصناف والكميات</Label>
                                <Button type="button" size="sm" variant="outline" @click="addLine" class="gap-1">
                                    <Plus class="w-3.5 h-3.5" />
                                    <span>إضافة صنف</span>
                                </Button>
                            </div>

                            <div class="space-y-2">
                                <div v-for="(line, idx) in form.lines" :key="idx" class="flex flex-col sm:flex-row items-center gap-3 p-3 bg-muted/40 rounded-lg border border-border">
                                    <div class="flex-1 w-full sm:w-auto">
                                        <select v-model="line.item_id" @change="onItemChange(idx)" class="w-full h-9 px-2 rounded-md border border-input bg-background text-sm" required>
                                            <option v-for="itm in items" :key="itm.id" :value="itm.id">
                                                {{ itm.name }} ({{ itm.unit }})
                                            </option>
                                        </select>
                                    </div>
                                    <div class="w-full sm:w-32">
                                        <Input type="number" step="0.01" min="0.01" v-model="line.quantity" placeholder="الكمية" required />
                                    </div>
                                    <div class="w-full sm:w-32">
                                        <Input type="number" step="0.01" v-model="line.unit_cost" placeholder="التكلفة" />
                                    </div>
                                    <Button type="button" size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10 shrink-0" @click="removeLine(idx)">
                                        <Trash2 class="w-4 h-4" />
                                    </Button>
                                </div>
                            </div>
                        </div>

                        <!-- Notes -->
                        <div class="space-y-1.5">
                            <Label>ملاحظات</Label>
                            <Input v-model="form.notes" placeholder="ملاحظات الحركة..." />
                        </div>
                    </CardContent>

                    <CardFooter class="border-t border-border pt-4 flex justify-between">
                        <Button type="button" variant="outline" as-child>
                            <Link :href="route('stock-transfers.index')">إلغاء</Link>
                        </Button>
                        <Button type="submit" :disabled="form.processing" class="gap-2 px-8">
                            <span>حفظ حركة المخزون</span>
                            <ArrowRight class="w-4 h-4 rotate-180" />
                        </Button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    </AppLayout>
</template>
