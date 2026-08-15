<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm, Link } from '@inertiajs/vue3';
import { FileSpreadsheet, Plus, Trash2, ArrowRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { computed } from 'vue';

const props = defineProps<{
    parties: any[];
    stores: any[];
    items: any[];
    quotationNumber: string;
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'عروض الأسعار', href: '/quotations' },
    { title: 'عرض سعر جديد', href: '#' },
];

const form = useForm({
    quotation_number: props.quotationNumber,
    party_id: props.parties[0]?.id || '',
    store_id: props.stores[0]?.id || '',
    date: new Date().toISOString().split('T')[0],
    expiry_date: '',
    discount: 0,
    notes: '',
    lines: [
        { item_id: props.items[0]?.id || '', quantity: 1, unit_price: props.items[0]?.sales_price || 0, notes: '' },
    ],
});

const addLine = () => {
    form.lines.push({
        item_id: props.items[0]?.id || '',
        quantity: 1,
        unit_price: props.items[0]?.sales_price || 0,
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
        form.lines[index].unit_price = itm.sales_price;
    }
};

const subtotal = computed(() => {
    return form.lines.reduce((sum, l) => sum + (Number(l.quantity) * Number(l.unit_price)), 0);
});

const totalAmount = computed(() => {
    return Math.max(0, subtotal.value - Number(form.discount || 0));
});

const submit = () => {
    form.post(route('quotations.store'));
};
</script>

<template>
    <Head title="إنشاء عرض سعر جديد" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <FileSpreadsheet class="w-6 h-6 text-primary" />
                        إنشاء عرض سعر جديد (Quotation)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تقديم عرض أسعار رسمي للعميل مع تفاصيل الأصناف والخصم.
                    </p>
                </div>
                <Button variant="outline" as-child>
                    <Link :href="route('quotations.index')">رجوع</Link>
                </Button>
            </div>

            <Card class="border-border shadow-md">
                <form @submit.prevent="submit">
                    <CardHeader class="border-b border-border pb-4">
                        <div class="flex justify-between items-center">
                            <CardTitle class="text-lg">بيانات عرض السعر</CardTitle>
                            <span class="font-mono text-sm px-3 py-1 bg-muted rounded-md font-bold">
                                {{ form.quotation_number }}
                            </span>
                        </div>
                    </CardHeader>

                    <CardContent class="pt-6 space-y-6">
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="space-y-1.5">
                                <Label>العميل المستهدف</Label>
                                <select v-model="form.party_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option v-for="p in parties" :key="p.id" :value="p.id">
                                        {{ p.name }}
                                    </option>
                                </select>
                            </div>

                            <div class="space-y-1.5">
                                <Label>المستودع المقترح</Label>
                                <select v-model="form.store_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option v-for="s in stores" :key="s.id" :value="s.id">
                                        {{ s.name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="space-y-1.5">
                                <Label>تاريخ العرض</Label>
                                <Input type="date" v-model="form.date" required />
                            </div>
                            <div class="space-y-1.5">
                                <Label>تاريخ انتهاء الصلاحية (اختياري)</Label>
                                <Input type="date" v-model="form.expiry_date" />
                            </div>
                        </div>

                        <!-- Items Lines -->
                        <div class="space-y-3">
                            <div class="flex justify-between items-center">
                                <Label class="text-base font-bold">الأصناف والأسعار</Label>
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
                                                {{ itm.name }} ({{ itm.sales_price }})
                                            </option>
                                        </select>
                                    </div>
                                    <div class="w-full sm:w-28">
                                        <Input type="number" step="0.01" min="0.01" v-model="line.quantity" placeholder="الكمية" required />
                                    </div>
                                    <div class="w-full sm:w-32">
                                        <Input type="number" step="0.01" min="0" v-model="line.unit_price" placeholder="سعر الوحدة" required />
                                    </div>
                                    <div class="w-full sm:w-28 text-left font-mono font-bold text-sm">
                                        {{ (Number(line.quantity) * Number(line.unit_price)).toLocaleString() }}
                                    </div>
                                    <Button type="button" size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10 shrink-0" @click="removeLine(idx)">
                                        <Trash2 class="w-4 h-4" />
                                    </Button>
                                </div>
                            </div>
                        </div>

                        <!-- Financial Summary -->
                        <div class="p-4 bg-muted/40 rounded-xl border border-border space-y-3 max-w-sm mr-auto">
                            <div class="flex justify-between text-sm">
                                <span class="text-muted-foreground">المجموع الفرعي:</span>
                                <span class="font-mono font-bold">{{ subtotal.toLocaleString() }}</span>
                            </div>
                            <div class="flex justify-between items-center gap-2 text-sm">
                                <span class="text-muted-foreground">قيمة الخصم:</span>
                                <Input type="number" step="0.01" min="0" v-model="form.discount" class="w-28 h-8 text-left font-mono" />
                            </div>
                            <div class="border-t border-border pt-2 flex justify-between text-base font-bold text-primary">
                                <span>المجموع النهائي:</span>
                                <span class="font-mono text-lg">{{ totalAmount.toLocaleString() }}</span>
                            </div>
                        </div>

                        <div class="space-y-1.5">
                            <Label>شروط وملاحظات العرض</Label>
                            <Input v-model="form.notes" placeholder="شروط الدفع والتسليم..." />
                        </div>
                    </CardContent>

                    <CardFooter class="border-t border-border pt-4 flex justify-between">
                        <Button type="button" variant="outline" as-child>
                            <Link :href="route('quotations.index')">إلغاء</Link>
                        </Button>
                        <Button type="submit" :disabled="form.processing" class="gap-2 px-8">
                            <span>حفظ عرض السعر</span>
                            <ArrowRight class="w-4 h-4 rotate-180" />
                        </Button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    </AppLayout>
</template>
