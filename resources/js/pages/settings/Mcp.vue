<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import SettingsLayout from '@/layouts/settings/Layout.vue';
import { Head, useForm } from '@inertiajs/vue3';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Bot, Key, Copy, Check, Trash2, Power, ShieldAlert, Sparkles } from 'lucide-vue-next';
import { ref } from 'vue';

interface McpTokenItem {
    id: number;
    name: string;
    token: string;
    client_id?: string;
    is_active: boolean;
    last_used_at?: string;
    created_at: string;
    user?: {
        name: string;
        email: string;
    };
}

const props = defineProps<{
    tokens: McpTokenItem[];
    mcpUrl: string;
    oauthUrl: string;
}>();

const createForm = useForm({
    name: '',
});

const copiedText = ref<string | null>(null);

const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    copiedText.value = id;
    setTimeout(() => {
        if (copiedText.value === id) {
            copiedText.value = null;
        }
    }, 2500);
};

const createToken = () => {
    createForm.post(route('settings.mcp.store'), {
        onSuccess: () => createForm.reset(),
    });
};

const toggleToken = (id: number) => {
    useForm({}).patch(route('settings.mcp.toggle', id));
};

const deleteToken = (id: number) => {
    if (confirm('هل أنت متأكد من رغبتك في حذف مفتاح الـ MCP هذا؟ سيتوقف ChatGPT أو التطبيق المتصل فوراً.')) {
        useForm({}).delete(route('settings.mcp.destroy', id));
    }
};
</script>

<template>
    <AppLayout>
        <Head title="إعدادات وتفويضات MCP و ChatGPT" />

        <SettingsLayout>
            <div class="space-y-6" dir="rtl">
                <!-- Header -->
                <div class="space-y-1">
                    <div class="flex items-center gap-2">
                        <Bot class="w-6 h-6 text-primary" />
                        <h2 class="text-xl font-bold tracking-tight">إدارة اتصالات وتفويضات MCP (ChatGPT)</h2>
                    </div>
                    <p class="text-sm text-muted-foreground">
                        تحكم في وصول ChatGPT ونماذج الذكاء الاصطناعي إلى النظام المحاسبي وإدارة مفاتيح الـ API الآمنة.
                    </p>
                </div>

                <!-- Info Banner -->
                <div class="rounded-xl border border-primary/20 bg-primary/5 p-4 flex items-start gap-3">
                    <Sparkles class="w-5 h-5 text-primary shrink-0 mt-0.5" />
                    <div class="text-xs text-foreground leading-relaxed space-y-1">
                        <p class="font-semibold text-primary">حماية مشددة: مسموح للأدمن فقط!</p>
                        <p class="text-muted-foreground">
                            لا يمكن لأي طرف خارجي أو لـ ChatGPT استخدام خادم الـ MCP دون تسجيل دخول مسؤول النظام والموافقة الصريحة، أو عبر استخدام مفتاح Bearer Token مفعل تم إنشاؤه من هذه الصفحة.
                        </p>
                    </div>
                </div>

                <!-- Server Info Card -->
                <Card class="border-border">
                    <CardHeader class="pb-3">
                        <CardTitle class="text-base flex items-center gap-2">
                            <Key class="w-4 h-4 text-primary" />
                            بيانات الاتصال بخادم MCP
                        </CardTitle>
                        <CardDescription class="text-xs">
                            عناوين الـ Endpoints لاستخدامها في إعدادات عميل الذكاء الاصطناعي
                        </CardDescription>
                    </CardHeader>
                    <CardContent class="space-y-3">
                        <div class="space-y-1.5">
                            <Label class="text-xs">رابط الـ SSE Endpoint</Label>
                            <div class="flex gap-2">
                                <Input :value="mcpUrl" readonly class="font-mono text-xs text-left" dir="ltr" />
                                <Button variant="outline" size="sm" @click="copyToClipboard(mcpUrl, 'mcp_url')">
                                    <Check v-if="copiedText === 'mcp_url'" class="w-4 h-4 text-emerald-500" />
                                    <Copy v-else class="w-4 h-4" />
                                </Button>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <!-- Create New Token Card -->
                <Card class="border-border">
                    <CardHeader class="pb-3">
                        <CardTitle class="text-base">إنشاء مفتاح MCP يدوي (Bearer Token)</CardTitle>
                        <CardDescription class="text-xs">
                            يمكنك توليد مفتاح دائم لاستخدامه مباشرة في أدوات الـ CLI أو ChatGPT
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <form @submit.prevent="createToken" class="flex flex-col sm:flex-row gap-3">
                            <div class="flex-1">
                                <Input 
                                    v-model="createForm.name" 
                                    placeholder="مثال: ChatGPT Admin Assistant أو Cursor MCP" 
                                    required 
                                />
                            </div>
                            <Button type="submit" :disabled="createForm.processing" class="shrink-0">
                                إنشاء المفتاح
                            </Button>
                        </form>
                    </CardContent>
                </Card>

                <!-- Tokens List -->
                <Card class="border-border">
                    <CardHeader class="pb-3">
                        <CardTitle class="text-base">المفاتيح والاتصالات المصرح لها ({{ tokens.length }})</CardTitle>
                        <CardDescription class="text-xs">
                            قائمة بكافة الجلسات والتوكنات المعتمدة للاتصال بـ MCP
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div v-if="tokens.length === 0" class="text-center py-8 text-muted-foreground text-sm">
                            لا توجد مفاتيح أو اتصالات مفعلة حتى الآن.
                        </div>

                        <div v-else class="divide-y divide-border">
                            <div v-for="tok in tokens" :key="tok.id" class="py-3.5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                                <div class="space-y-1">
                                    <div class="flex items-center gap-2">
                                        <span class="font-medium text-sm">{{ tok.name }}</span>
                                        <Badge :variant="tok.is_active ? 'default' : 'secondary'" class="text-[10px]">
                                            {{ tok.is_active ? 'نشط' : 'معطل' }}
                                        </Badge>
                                    </div>
                                    <div class="flex items-center gap-2 text-xs text-muted-foreground font-mono" dir="ltr">
                                        <span>{{ tok.token.substring(0, 16) }}...{{ tok.token.substring(tok.token.length - 8) }}</span>
                                        <button @click="copyToClipboard(tok.token, 'token_' + tok.id)" class="text-primary hover:underline inline-flex items-center gap-1">
                                            <Check v-if="copiedText === 'token_' + tok.id" class="w-3 h-3 text-emerald-500" />
                                            <Copy v-else class="w-3 h-3" />
                                        </button>
                                    </div>
                                    <div class="text-[11px] text-muted-foreground">
                                        تاريخ الإنشاء: {{ new Date(tok.created_at).toLocaleDateString('ar-EG') }}
                                        <span v-if="tok.last_used_at"> • آخر استخدام: {{ new Date(tok.last_used_at).toLocaleDateString('ar-EG') }}</span>
                                    </div>
                                </div>

                                <div class="flex items-center gap-2 self-end sm:self-center">
                                    <Button 
                                        size="sm" 
                                        variant="outline" 
                                        :class="tok.is_active ? 'text-amber-600 hover:text-amber-700' : 'text-emerald-600 hover:text-emerald-700'"
                                        @click="toggleToken(tok.id)"
                                    >
                                        <Power class="w-3.5 h-3.5 mr-1" />
                                        {{ tok.is_active ? 'تعطيل' : 'تفعيل' }}
                                    </Button>
                                    <Button 
                                        size="sm" 
                                        variant="ghost" 
                                        class="text-destructive hover:bg-destructive/10"
                                        @click="deleteToken(tok.id)"
                                    >
                                        <Trash2 class="w-3.5 h-3.5" />
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </SettingsLayout>
    </AppLayout>
</template>
