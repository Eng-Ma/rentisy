<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm, Link } from '@inertiajs/vue3';
import { Receipt, ArrowRight, ArrowDownLeft, ArrowUpRight } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card';

const props = defineProps<{
    type: 'receipt' | 'payment';
    voucherNumber: string;
    accounts: any[];
    cashAccounts: any[];
    parties: any[];
    currencies: any[];
    costCenters: any[];
}>();

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'سندات القبض والصرف', href: '/vouchers' },
    { title: props.type === 'receipt' ? 'سند قبض جديد' : 'سند صرف جديد', href: '#' },
];

const defaultCurrency = props.currencies.find(c => c.is_default) || props.currencies[0];

const form = useForm({
    voucher_number: props.voucherNumber,
    type: props.type,
    payment_method: 'cash',
    date: new Date().toISOString().split('T')[0],
    account_id: props.cashAccounts[0]?.id || '',
    party_id: '',
    target_account_id: '',
    cost_center_id: '',
    currency_id: defaultCurrency?.id || '',
    exchange_rate: defaultCurrency?.exchange_rate || 1.0,
    amount: '',
    check_number: '',
    check_date: new Date().toISOString().split('T')[0],
    bank_name: '',
    notes: '',
});

const onCurrencyChange = () => {
    const cur = props.currencies.find(c => c.id == form.currency_id);
    if (cur) {
        form.exchange_rate = cur.exchange_rate;
    }
};

const submit = () => {
    form.post(route('vouchers.store'));
};
</script>

<template>
    <Head :title="type === 'receipt' ? 'إنشاء سند قبض' : 'إنشاء سند صرف'" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6 max-w-4xl mx-auto w-full" dir="rtl">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <ArrowDownLeft v-if="type === 'receipt'" class="w-6 h-6 text-emerald-600" />
                        <ArrowUpRight v-else class="w-6 h-6 text-rose-600" />
                        {{ type === 'receipt' ? 'إنشاء سند قبض مالي جديد' : 'إنشاء سند صرف مالي جديد' }}
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        {{ type === 'receipt' ? 'استلام مبالغ نقدية أو بنكية أو شيكات وترحيلها لحساب العميل/الإيراد.' : 'صرف مبالغ نقدية أو بنكية أو شيكات للمورد أو المصروفات.' }}
                    </p>
                </div>
                <Button variant="outline" as-child>
                    <Link :href="route('vouchers.index')">رجوع</Link>
                </Button>
            </div>

            <Card class="border-border shadow-md">
                <form @submit.prevent="submit">
                    <CardHeader class="border-b border-border pb-4">
                        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                            <CardTitle class="text-lg">بيانات السند المالي</CardTitle>
                            <span class="font-mono text-sm px-3 py-1 bg-muted rounded-md font-bold">
                                {{ form.voucher_number }}
                            </span>
                        </div>
                    </CardHeader>

                    <CardContent class="pt-6 space-y-6">
                        <!-- Row 1: Date & Payment Method -->
                        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            <div class="space-y-1.5">
                                <Label>تاريخ السند</Label>
                                <Input type="date" v-model="form.date" required />
                            </div>

                            <div class="space-y-1.5">
                                <Label>طريقة الدفع</Label>
                                <select v-model="form.payment_method" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm font-medium">
                                    <option value="cash">نقدي (كاش / صندوق)</option>
                                    <option value="bank">حوالة بنكية / بطاقة</option>
                                    <option value="check">شيك مصرفي</option>
                                </select>
                            </div>

                            <div class="space-y-1.5">
                                <Label>{{ type === 'receipt' ? 'إيداع في حساب (الصندوق/البنك)' : 'الصرف من حساب (الصندوق/البنك)' }}</Label>
                                <select v-model="form.account_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option v-for="acc in cashAccounts" :key="acc.id" :value="acc.id">
                                        {{ acc.code }} - {{ acc.name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <!-- Row 2: Party or Counter Account -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="space-y-1.5">
                                <Label>{{ type === 'receipt' ? 'العميل / الطرف المقبوض منه' : 'المورد / الطرف المدفوع له' }}</Label>
                                <select v-model="form.party_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option value="">— اختيار طرف (عميل أو مورد) —</option>
                                    <option v-for="p in parties" :key="p.id" :value="p.id">
                                        {{ p.name }} ({{ p.type === 'customer' ? 'عميل' : 'مورد' }})
                                    </option>
                                </select>
                            </div>

                            <div class="space-y-1.5">
                                <Label>أو حساب بديل (مصروف / إيراد / وسيط)</Label>
                                <select v-model="form.target_account_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option value="">— اختيار حساب بديل إذا لم يكن طرفاً —</option>
                                    <option v-for="acc in accounts" :key="acc.id" :value="acc.id">
                                        {{ acc.code }} - {{ acc.name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <!-- Row 3: Amount, Currency, Cost Center -->
                        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            <div class="space-y-1.5">
                                <Label>المبلغ</Label>
                                <Input type="number" step="0.01" min="0.01" v-model="form.amount" placeholder="0.00" required class="text-lg font-bold" />
                            </div>

                            <div class="space-y-1.5">
                                <Label>العملة</Label>
                                <select v-model="form.currency_id" @change="onCurrencyChange" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option v-for="c in currencies" :key="c.id" :value="c.id">
                                        {{ c.code }} - {{ c.name }}
                                    </option>
                                </select>
                            </div>

                            <div class="space-y-1.5">
                                <Label>مركز التكلفة (اختياري)</Label>
                                <select v-model="form.cost_center_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option value="">— بدون مركز تكلفة —</option>
                                    <option v-for="cc in costCenters" :key="cc.id" :value="cc.id">
                                        {{ cc.code }} - {{ cc.name }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <!-- Check Details (Shown if Check selected) -->
                        <div v-if="form.payment_method === 'check'" class="p-4 rounded-xl border border-primary/20 bg-primary/5 space-y-4">
                            <h4 class="text-sm font-bold text-primary">بيانات الشيك</h4>
                            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                <div class="space-y-1.5">
                                    <Label>رقم الشيك</Label>
                                    <Input v-model="form.check_number" placeholder="رقم الشيك المطبوع" required />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>اسم البنك المسحوب عليه</Label>
                                    <Input v-model="form.bank_name" placeholder="مثال: بنك فلسطين / بنك الإسكان" />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>تاريخ استحقاق الشيك</Label>
                                    <Input type="date" v-model="form.check_date" required />
                                </div>
                            </div>
                        </div>

                        <!-- Notes -->
                        <div class="space-y-1.5">
                            <Label>البيان والملاحظات</Label>
                            <Input v-model="form.notes" placeholder="تفاصيل الدفعة أو سبب الصرف/القبض..." />
                        </div>
                    </CardContent>

                    <CardFooter class="border-t border-border pt-4 flex justify-between">
                        <Button type="button" variant="outline" as-child>
                            <Link :href="route('vouchers.index')">إلغاء</Link>
                        </Button>
                        <Button type="submit" :disabled="form.processing" class="gap-2 px-8">
                            <span>حفظ وترحيل السند</span>
                            <ArrowRight class="w-4 h-4 rotate-180" />
                        </Button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    </AppLayout>
</template>
