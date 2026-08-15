<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import { type BreadcrumbItem } from '@/types';
import { Head, router, useForm } from '@inertiajs/vue3';
import { CreditCard, Plus, CheckCircle2, Share2, RefreshCw, XCircle, AlertCircle } from 'lucide-vue-next';
import { ref } from 'vue';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import Pagination from '@/components/Pagination.vue';

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'حافظة الشيكات', href: '/checks' },
];

interface CheckItem {
    id: number;
    check_number: string;
    type: 'received' | 'issued';
    bank_name: string;
    drawer_name?: string;
    beneficiary_name?: string;
    due_date: string;
    amount: number;
    status: 'under_collection' | 'collected' | 'endorsed' | 'bounced' | 'cancelled';
    party?: { name: string };
    endorsed_party?: { name: string };
    currency?: { code: string };
    notes?: string;
}

const props = defineProps<{
    checks: {
        data: CheckItem[];
        links: any[];
    };
    currentType?: string;
    currentStatus?: string;
    parties: any[];
    bankAccounts: any[];
}>();

const showStatusModal = ref(false);
const activeCheck = ref<CheckItem | null>(null);

const statusForm = useForm({
    status: 'collected',
    bank_account_id: props.bankAccounts[0]?.id || '',
    endorsed_party_id: '',
    collection_date: new Date().toISOString().split('T')[0],
    notes: '',
});

const openStatusModal = (chk: CheckItem, targetStatus: string) => {
    activeCheck.value = chk;
    statusForm.status = targetStatus;
    statusForm.notes = '';
    showStatusModal.value = true;
};

const submitStatusUpdate = () => {
    if (activeCheck.value) {
        statusForm.post(route('checks.update_status', activeCheck.value.id), {
            onSuccess: () => {
                showStatusModal.value = false;
            },
        });
    }
};

const setFilter = (type?: string, status?: string) => {
    router.get('/checks', {
        type: type !== undefined ? type : props.currentType,
        status: status !== undefined ? status : props.currentStatus,
    }, { preserveState: true, replace: true });
};
</script>

<template>
    <Head title="حافظة الشيكات (Checks Portfolio)" />

    <AppLayout :breadcrumbs="breadcrumbs">
        <div class="flex h-full flex-1 flex-col gap-6 p-4 md:p-6" dir="rtl">
            <!-- Header -->
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                    <h1 class="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
                        <CreditCard class="w-6 h-6 text-primary" />
                        حافظة الشيكات (Checks Portfolio)
                    </h1>
                    <p class="text-sm text-muted-foreground mt-1">
                        تتبع الشيكات الواردة والصادرة وعمليات التحصيل والتجيير والإرجاع التلقائي.
                    </p>
                </div>
            </div>

            <!-- Filter tabs -->
            <div class="flex flex-wrap gap-2 border-b border-border pb-3">
                <Button size="sm" :variant="!currentType ? 'default' : 'outline'" @click="setFilter('', '')">
                    جميع الشيكات
                </Button>
                <Button size="sm" :variant="currentType === 'received' ? 'default' : 'outline'" @click="setFilter('received', undefined)">
                    شيكات واردة (قبض)
                </Button>
                <Button size="sm" :variant="currentType === 'issued' ? 'default' : 'outline'" @click="setFilter('issued', undefined)">
                    شيكات صادرة (دفع)
                </Button>

                <div class="border-r border-border mx-2 h-6 self-center"></div>

                <Button size="sm" :variant="currentStatus === 'under_collection' ? 'secondary' : 'ghost'" @click="setFilter(undefined, 'under_collection')">
                    برسم التحصيل
                </Button>
                <Button size="sm" :variant="currentStatus === 'collected' ? 'secondary' : 'ghost'" @click="setFilter(undefined, 'collected')">
                    محصل في البنك
                </Button>
                <Button size="sm" :variant="currentStatus === 'endorsed' ? 'secondary' : 'ghost'" @click="setFilter(undefined, 'endorsed')">
                    مجير
                </Button>
                <Button size="sm" :variant="currentStatus === 'bounced' ? 'secondary' : 'ghost'" @click="setFilter(undefined, 'bounced')">
                    مرتجع
                </Button>
            </div>

            <!-- Checks Table Card -->
            <Card class="border-border">
                <CardContent class="p-0">
                    <div class="overflow-x-auto">
                        <table class="w-full text-sm text-right">
                            <thead class="bg-muted/50 text-muted-foreground border-b border-border">
                                <tr>
                                    <th class="px-6 py-3 font-semibold">رقم الشيك</th>
                                    <th class="px-6 py-3 font-semibold">النوع</th>
                                    <th class="px-6 py-3 font-semibold">البنك المسحوب عليه</th>
                                    <th class="px-6 py-3 font-semibold">الساحب / العميل</th>
                                    <th class="px-6 py-3 font-semibold">تاريخ الاستحقاق</th>
                                    <th class="px-6 py-3 font-semibold">المبلغ</th>
                                    <th class="px-6 py-3 font-semibold">الحالة</th>
                                    <th class="px-6 py-3 font-semibold text-left">إجراءات التحصيل</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-border">
                                <tr v-for="chk in checks.data" :key="chk.id" class="hover:bg-muted/30 transition-colors">
                                    <td class="px-6 py-4 font-mono font-bold">{{ chk.check_number }}</td>
                                    <td class="px-6 py-4">
                                        <Badge :variant="chk.type === 'received' ? 'default' : 'outline'">
                                            {{ chk.type === 'received' ? 'شيك وارد' : 'شيك صادر' }}
                                        </Badge>
                                    </td>
                                    <td class="px-6 py-4 text-muted-foreground">{{ chk.bank_name }}</td>
                                    <td class="px-6 py-4 font-medium">{{ chk.party?.name || chk.drawer_name || '—' }}</td>
                                    <td class="px-6 py-4 font-mono text-xs">{{ chk.due_date }}</td>
                                    <td class="px-6 py-4 font-bold text-primary">
                                        {{ Number(chk.amount).toLocaleString() }} {{ chk.currency?.code || 'ILS' }}
                                    </td>
                                    <td class="px-6 py-4">
                                        <Badge v-if="chk.status === 'under_collection'" class="bg-amber-500/10 text-amber-600 border-amber-500/20">
                                            برسم التحصيل
                                        </Badge>
                                        <Badge v-else-if="chk.status === 'collected'" class="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">
                                            محصل بالبنك
                                        </Badge>
                                        <Badge v-else-if="chk.status === 'endorsed'" class="bg-indigo-500/10 text-indigo-600 border-indigo-500/20">
                                            مجير لـ ({{ chk.endorsed_party?.name || 'مورد' }})
                                        </Badge>
                                        <Badge v-else-if="chk.status === 'bounced'" class="bg-rose-500/10 text-rose-600 border-rose-500/20">
                                            مرتجع
                                        </Badge>
                                        <Badge v-else variant="secondary">ملغي</Badge>
                                    </td>
                                    <td class="px-6 py-4 text-left">
                                        <div v-if="chk.status === 'under_collection'" class="flex items-center justify-end gap-1.5">
                                            <Button size="sm" variant="outline" class="text-emerald-600 hover:text-emerald-700 text-xs h-8" @click="openStatusModal(chk, 'collected')">
                                                <CheckCircle2 class="w-3.5 h-3.5 mr-1" />
                                                تحصيل
                                            </Button>
                                            <Button v-if="chk.type === 'received'" size="sm" variant="outline" class="text-indigo-600 hover:text-indigo-700 text-xs h-8" @click="openStatusModal(chk, 'endorsed')">
                                                <Share2 class="w-3.5 h-3.5 mr-1" />
                                                تجيير
                                            </Button>
                                            <Button size="sm" variant="ghost" class="text-rose-600 hover:bg-rose-500/10 text-xs h-8" @click="openStatusModal(chk, 'bounced')">
                                                <AlertCircle class="w-3.5 h-3.5 mr-1" />
                                                إرجاع
                                            </Button>
                                        </div>
                                        <span v-else class="text-xs text-muted-foreground">مكتمل</span>
                                    </td>
                                </tr>
                                <tr v-if="checks.data.length === 0">
                                    <td colspan="8" class="px-6 py-10 text-center text-muted-foreground">
                                        لا توجد شيكات مطابقة للمعايير المحددة.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </CardContent>
            </Card>

            <Pagination :links="checks.links" />

            <!-- Status Modal -->
            <div v-if="showStatusModal" class="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
                <Card class="w-full max-w-md bg-card border-border shadow-2xl">
                    <CardHeader>
                        <CardTitle>
                            {{ statusForm.status === 'collected' ? 'تحصيل الشيك وإيداعه في البنك' : (statusForm.status === 'endorsed' ? 'تجيير الشيك إلى مورد' : 'تسجيل الشيك كمرتجع') }}
                        </CardTitle>
                        <CardDescription>
                            شيك رقم: <span class="font-bold text-foreground font-mono">{{ activeCheck?.check_number }}</span> بمبلغ <span class="font-bold text-primary font-mono">{{ Number(activeCheck?.amount).toLocaleString() }}</span>
                        </CardDescription>
                    </CardHeader>
                    <form @submit.prevent="submitStatusUpdate">
                        <CardContent class="space-y-4">
                            <!-- If collecting: pick bank account -->
                            <div v-if="statusForm.status === 'collected'" class="space-y-1.5">
                                <Label>حساب البنك المودع فيه</Label>
                                <select v-model="statusForm.bank_account_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option v-for="acc in bankAccounts" :key="acc.id" :value="acc.id">
                                        {{ acc.code }} - {{ acc.name }}
                                    </option>
                                </select>
                            </div>

                            <!-- If endorsing: pick vendor -->
                            <div v-if="statusForm.status === 'endorsed'" class="space-y-1.5">
                                <Label>المورد المحول إليه (المجير له)</Label>
                                <select v-model="statusForm.endorsed_party_id" class="w-full h-10 px-3 rounded-md border border-input bg-background text-sm" required>
                                    <option value="">— اختيار المورد —</option>
                                    <option v-for="p in parties" :key="p.id" :value="p.id">
                                        {{ p.name }}
                                    </option>
                                </select>
                            </div>

                            <div class="space-y-1.5">
                                <Label>تاريخ الحركة</Label>
                                <Input type="date" v-model="statusForm.collection_date" required />
                            </div>

                            <div class="space-y-1.5">
                                <Label>ملاحظات</Label>
                                <Input v-model="statusForm.notes" placeholder="ملاحظات اختيارية..." />
                            </div>
                        </CardContent>
                        <div class="p-6 border-t border-border flex justify-end gap-2">
                            <Button type="button" variant="outline" @click="showStatusModal = false">إلغاء</Button>
                            <Button type="submit" :disabled="statusForm.processing">
                                تأكيد التحديث وترحيل القيد
                            </Button>
                        </div>
                    </form>
                </Card>
            </div>
        </div>
    </AppLayout>
</template>
