<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';
import { Building2, Plus, Calculator, Trash2 } from 'lucide-vue-next';
import { ref } from 'vue';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'الأصول الثابتة', href: '/fixed-assets' },
];

interface Asset {
    id: number;
    code: string;
    name: string;
    purchase_date: string;
    purchase_cost: number;
    salvage_value: number;
    useful_life_years: number;
    depreciation_rate: number;
    total_depreciated: number;
    current_book_value: number;
    is_active: boolean;
    cost_center?: { name: string };
    asset_account?: { name: string };
    depreciations?: any[];
}

const props = defineProps<{
    assets: Asset[];
    accounts: any[];
    costCenters: any[];
}>();

const showCreateModal = ref(false);
const showDepreciateModal = ref(false);
const selectedAsset = ref<Asset | null>(null);

const createForm = useForm({
    code: '',
    name: '',
    purchase_date: new Date().toISOString().split('T')[0],
    purchase_cost: '',
    salvage_value: '0',
    useful_life_years: '5',
    depreciation_rate: '20',
    asset_account_id: '',
    depreciation_expense_account_id: '',
    accumulated_depreciation_account_id: '',
    cost_center_id: '',
    notes: '',
});

const depreciateForm = useForm({
    date: new Date().toISOString().split('T')[0],
    amount: '',
    notes: '',
});

const openCreate = () => {
    createForm.reset();
    createForm.code = 'AST-' + (props.assets.length + 1);
    showCreateModal.value = true;
};

const openDepreciate = (asset: Asset) => {
    selectedAsset.value = asset;
    depreciateForm.reset();
    // Default 1 period depreciation
    const base = Math.max(0, asset.purchase_cost - asset.salvage_value);
    depreciateForm.amount = ((base * (asset.depreciation_rate / 100)) / 12).toFixed(2); // monthly default
    showDepreciateModal.value = true;
};

const submitCreate = () => {
    createForm.post(route('fixed-assets.store'), {
        onSuccess: () => {
            showCreateModal.value = false;
            createForm.reset();
        },
    });
};

const submitDepreciate = () => {
    if (selectedAsset.value) {
        depreciateForm.post(route('fixed_assets.depreciate', selectedAsset.value.id), {
            onSuccess: () => {
                showDepreciateModal.value = false;
            },
        });
    }
};

const deleteAsset = (id: number) => {
    if (confirm('هل أنت متأكد من حذف هذا الأصل الثابت وسجل إهلاكاته؟')) {
        useForm({}).delete(route('fixed-assets.destroy', id));
    }
};
</script>

<template>
    <Head title="الأصول الثابتة والإهلاك (Fixed Assets)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Building2 class="w-6 h-6 text-primary" />
                        الأصول الثابتة واحتساب الإهلاك (Fixed Assets)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        إدارة الأصول الرأسمالية واحتساب الإهلاك الدوري وتوليد القيود المحاسبية التلقائية.
                    </p>
                </div>
                <Button @click="openCreate" class="gap-2">
                    <Plus class="w-4 h-4" />
                    <span>تسجيل أصل جديد</span>
                </Button>
            </div>

            <!-- Assets Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">كود الأصل</th>
                                    <th class="px-6 py-3 font-semibold">اسم الأصل</th>
                                    <th class="px-6 py-3 font-semibold">تاريخ الشراء</th>
                                    <th class="px-6 py-3 font-semibold">تكلفة الشراء</th>
                                    <th class="px-6 py-3 font-semibold">مجمع الإهلاك</th>
                                    <th class="px-6 py-3 font-semibold">القيمة الدفترية الحالية</th>
                                    <th class="px-6 py-3 font-semibold">مركز التكلفة</th>
                                    <th class="px-6 py-3 font-semibold text-left">احتساب الإهلاك</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="ast in assets" :key="ast.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold text-primary">{{ ast.code }}</td>
                                    <td class="px-6 py-4 font-medium">{{ ast.name }}</td>
                                    <td class="px-6 py-4 text-muted-foreground text-xs font-mono">{{ ast.purchase_date }}</td>
                                    <td class="px-6 py-4 font-mono">{{ Number(ast.purchase_cost).toLocaleString() }}</td>
                                    <td class="px-6 py-4 font-mono text-rose-600">
                                        {{ Number(ast.total_depreciated).toLocaleString() }} ({{ ast.depreciations?.length || 0 }} قيد)
                                    </td>
                                    <td class="px-6 py-4 font-mono font-bold text-emerald-600">
                                        {{ Number(ast.current_book_value).toLocaleString() }}
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ ast.cost_center?.name || '—' }}</td>
                                    <td class="px-6 py-4 text-left">
                                        <div class="flex items-center justify-end gap-2">
                                            <Button size="sm" variant="outline" class="text-xs h-8 gap-1 text-primary hover:text-primary" @click="openDepreciate(ast)">
                                                <Calculator class="w-3.5 h-3.5" />
                                                إهلاك
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10" @click="deleteAsset(ast.id)">
                                                <Trash2 class="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="assets.length === 0">
                                    <td colspan="8" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد أصول ثابتة مسجلة حتى الآن.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <!-- Create Asset Modal -->
            <div v-if="showCreateModal" class="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
                <Card class="w-full max-w-lg bg-card border-border shadow-2xl">
                    <CardHeader>
                        <CardTitle>تسجيل بطاقة أصل ثابت جديد</CardTitle>
                        <CardDescription>أدخل بيانات الأصل ومحددات الإهلاك</CardDescription>
                    </CardHeader>
                    <form @submit.prevent="submitCreate">
                        <CardContent class="space-y-4 max-h-[70vh] overflow-y-auto pr-1">
                            <div class="grid grid-cols-2 gap-3">
                                <div class="space-y-1.5">
                                    <Label>كود الأصل</Label>
                                    <Input v-model="createForm.code" required />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>اسم الأصل</Label>
                                    <Input v-model="createForm.name" placeholder="مثال: سيارة نقل / سيرفر" required />
                                </div>
                            </div>

                            <div class="grid grid-cols-2 gap-3">
                                <div class="space-y-1.5">
                                    <Label>تاريخ الشراء</Label>
                                    <Input type="date" v-model="createForm.purchase_date" required />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>تكلفة الشراء</Label>
                                    <Input type="number" step="0.01" min="0.01" v-model="createForm.purchase_cost" required />
                                </div>
                            </div>

                            <div class="grid grid-cols-3 gap-3">
                                <div class="space-y-1.5">
                                    <Label>القيمة التخريدية</Label>
                                    <Input type="number" step="0.01" min="0" v-model="createForm.salvage_value" />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>العمر (سنوات)</Label>
                                    <Input type="number" step="0.5" min="0.5" v-model="createForm.useful_life_years" />
                                </div>
                                <div class="space-y-1.5">
                                    <Label>نسبة الإهلاك %</Label>
                                    <Input type="number" step="0.1" v-model="createForm.depreciation_rate" />
                                </div>
                            </div>

                            <div class="space-y-1.5">
                                <Label>مركز التكلفة (اختياري)</Label>
                                <select v-model="createForm.cost_center_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option value="">— بدون —</option>
                                    <option v-for="cc in costCenters" :key="cc.id" :value="cc.id">
                                        {{ cc.code }} - {{ cc.name }}
                                    </option>
                                </select>
                            </div>
                        </CardContent>
                        <div class="p-6 border-t border-border flex justify-end gap-2">
                            <Button type="button" variant="outline" @click="showCreateModal = false">إلغاء</Button>
                            <Button type="submit" :disabled="createForm.processing">حفظ الأصل</Button>
                        </div>
                    </form>
                </Card>
            </div>

            <!-- Depreciate Modal -->
            <div v-if="showDepreciateModal" class="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
                <Card class="w-full max-w-md bg-card border-border shadow-2xl">
                    <CardHeader>
                        <CardTitle>احتساب قسط الإهلاك الدوري</CardTitle>
                        <CardDescription>
                            أصل: <span class="font-bold text-foreground">{{ selectedAsset?.name }}</span> (القيمة الحالية: <span class="font-mono text-primary font-bold">{{ Number(selectedAsset?.current_book_value).toLocaleString() }}</span>)
                        </CardDescription>
                    </CardHeader>
                    <form @submit.prevent="submitDepreciate">
                        <CardContent class="space-y-4">
                            <div class="space-y-1.5">
                                <Label>تاريخ قيد الإهلاك</Label>
                                <Input type="date" v-model="depreciateForm.date" required />
                            </div>
                            <div class="space-y-1.5">
                                <Label>مبلغ قسط الإهلاك</Label>
                                <Input type="number" step="0.01" min="0.01" v-model="depreciateForm.amount" required class="text-lg font-bold font-mono" />
                            </div>
                            <div class="space-y-1.5">
                                <Label>ملاحظات</Label>
                                <Input v-model="depreciateForm.notes" placeholder="قسط إهلاك شهر كذا..." />
                            </div>
                        </CardContent>
                        <div class="p-6 border-t border-border flex justify-end gap-2">
                            <Button type="button" variant="outline" @click="showDepreciateModal = false">إلغاء</Button>
                            <Button type="submit" :disabled="depreciateForm.processing">توليد قيد الإهلاك</Button>
                        </div>
                    </form>
                </Card>
            </div>
        </div>
    </AppLayout>
</template>
