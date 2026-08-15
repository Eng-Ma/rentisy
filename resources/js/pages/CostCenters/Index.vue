<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm } from '@inertiajs/vue3';
import { ref } from 'vue';
import { Target, Plus, Trash2, Edit3, CheckCircle2 } from 'lucide-vue-next';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'مراكز التكلفة',
        href: '/cost-centers',
    },
];

interface CostCenterItem {
    id: number;
    code: string;
    name: string;
    parent_id?: number;
    parent?: { name: string };
    description?: string;
    is_active: boolean;
    journal_lines_count?: number;
    vouchers_count?: number;
    invoices_count?: number;
}

const props = defineProps<{
    costCenters: CostCenterItem[];
}>();

const showCreateModal = ref(false);
const editingCenter = ref<CostCenterItem | null>(null);

const form = useForm({
    code: '',
    name: '',
    parent_id: '',
    description: '',
    is_active: true,
});

const openCreate = () => {
    editingCenter.value = null;
    form.reset();
    form.code = (props.costCenters.length + 1).toString();
    showCreateModal.value = true;
};

const openEdit = (cc: CostCenterItem) => {
    editingCenter.value = cc;
    form.code = cc.code;
    form.name = cc.name;
    form.parent_id = cc.parent_id ? cc.parent_id.toString() : '';
    form.description = cc.description || '';
    form.is_active = cc.is_active;
    showCreateModal.value = true;
};

const submitForm = () => {
    if (editingCenter.value) {
        form.put(route('cost-centers.update', editingCenter.value.id), {
            onSuccess: () => {
                showCreateModal.value = false;
                form.reset();
            },
        });
    } else {
        form.post(route('cost-centers.store'), {
            onSuccess: () => {
                showCreateModal.value = false;
                form.reset();
            },
        });
    }
};

const deleteCenter = (id: number) => {
    if (confirm('هل أنت متأكد من حذف مركز التكلفة هذا؟')) {
        useForm({}).delete(route('cost-centers.destroy', id));
    }
};
</script>

<template>
    <Head title="مراكز التكلفة (Cost Centers)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <Target class="w-6 h-6 text-primary" />
                        دليل مراكز التكلفة (Cost Centers)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تتبع وتوزيع الإيرادات والمصروفات حسب المشاريع، الفروع، والأقسام.
                    </p>
                </div>
                <Button @click="openCreate" class="gap-2">
                    <Plus class="w-4 h-4" />
                    <span>إضافة مركز تكلفة</span>
                </Button>
            </div>

            <!-- Table Card -->
            <Card class="border-border">
                <CardHeader class="pb-3">
                    <CardTitle class="text-base">شجرة مراكز التكلفة المعرفة ({{ costCenters.length }})</CardTitle>
                </CardHeader>
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">الكود</th>
                                    <th class="px-6 py-3 font-semibold">اسم مركز التكلفة</th>
                                    <th class="px-6 py-3 font-semibold">المركز الرئيسي (الأب)</th>
                                    <th class="px-6 py-3 font-semibold">عدد الحركات</th>
                                    <th class="px-6 py-3 font-semibold">الحالة</th>
                                    <th class="px-6 py-3 font-semibold text-left">إجراءات</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="cc in costCenters" :key="cc.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold text-primary">{{ cc.code }}</td>
                                    <td class="px-6 py-4 font-medium">{{ cc.name }}</td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ cc.parent?.name || '—' }}</td>
                                    <td class="px-6 py-4 text-muted-foreground">
                                        {{ (cc.journal_lines_count || 0) + (cc.vouchers_count || 0) + (cc.invoices_count || 0) }} حركة
                                    </td>
                                    <td class="px-6 py-4">
                                        <Badge :variant="cc.is_active ? 'default' : 'secondary'">
                                            {{ cc.is_active ? 'نشط' : 'معطل' }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 text-left">
                                        <div class="flex items-center justify-end gap-2">
                                            <Button size="sm" variant="ghost" @click="openEdit(cc)">
                                                <Edit3 class="w-4 h-4" />
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-destructive hover:bg-destructive/10" @click="deleteCenter(cc.id)">
                                                <Trash2 class="w-4 h-4" />
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                                <tr v-if="costCenters.length === 0">
                                    <td colspan="6" class="px-6 py-10 text-center text-muted-foreground">
                                        لا يوجد مراكز تكلفة معرفة حتى الآن. ابدأ بإضافة مشروع أو فرع جديد.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <!-- Modal for Create / Edit -->
            <div v-if="showCreateModal" class="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
                <Card class="w-full max-w-md bg-card border-border shadow-2xl">
                    <CardHeader>
                        <CardTitle>{{ editingCenter ? 'تعديل مركز تكلفة' : 'إضافة مركز تكلفة جديد' }}</CardTitle>
                        <CardDescription>أدخل بيانات مركز التكلفة ورمزه المحاسبي</CardDescription>
                    </CardHeader>
                    <form @submit.prevent="submitForm">
                        <CardContent class="space-y-4">
                            <div class="space-y-1.5">
                                <Label>كود المركز</Label>
                                <Input v-model="form.code" placeholder="مثال: 101" required />
                            </div>
                            <div class="space-y-1.5">
                                <Label>اسم مركز التكلفة</Label>
                                <Input v-model="form.name" placeholder="مثال: مشروع مجمع النور / فرع عمان" required />
                            </div>
                            <div class="space-y-1.5">
                                <Label>المركز الأب (اختياري)</Label>
                                <select v-model="form.parent_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm">
                                    <option value="">بدون (مركز رئيسي)</option>
                                    <option v-for="c in costCenters.filter(x => !editingCenter || x.id !== editingCenter.id)" :key="c.id" :value="c.id">
                                        {{ c.code }} - {{ c.name }}
                                    </option>
                                </select>
                            </div>
                            <div class="space-y-1.5">
                                <Label>ملاحظات / وصف</Label>
                                <Input v-model="form.description" placeholder="وصف اختياري" />
                            </div>
                        </CardContent>
                        <div class="p-6 border-t border-border flex justify-end gap-2">
                            <Button type="button" variant="outline" @click="showCreateModal = false">إلغاء</Button>
                            <Button type="submit" :disabled="form.processing">
                                {{ editingCenter ? 'حفظ التعديلات' : 'إنشاء المركز' }}
                            </Button>
                        </div>
                    </form>
                </Card>
            </div>
        </div>
    </AppLayout>
</template>
