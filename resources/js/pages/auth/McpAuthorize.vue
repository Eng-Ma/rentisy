<script setup lang="ts">
import { Head, useForm } from '@inertiajs/vue3';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Bot, ShieldCheck, CheckCircle2, ArrowRight } from 'lucide-vue-next';

const props = defineProps<{
    clientId?: string;
    redirectUri?: string;
    state?: string;
    user: {
        id: number;
        name: string;
        email: string;
    };
}>();

const form = useForm({
    client_id: props.clientId || '',
    redirect_uri: props.redirectUri || '',
    state: props.state || '',
    approve: true,
});

const submit = (approved: boolean) => {
    form.approve = approved;
    form.post(route('oauth.authorize.post'));
};
</script>

<template>
    <Head title="تفويض اتصال ChatGPT و MCP" />

    <div class="min-h-screen flex items-center justify-center bg-muted/40 p-4" dir="rtl">
        <Card class="w-full max-w-lg shadow-xl border-border bg-card">
            <CardHeader class="text-center space-y-3 pb-6 border-b border-border">
                <div class="mx-auto w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center text-primary shadow-inner">
                    <Bot class="w-10 h-10" />
                </div>
                <CardTitle class="text-2xl font-bold">تفويض اتصال ChatGPT بنظام المحاسبة</CardTitle>
                <CardDescription class="text-sm text-muted-foreground">
                    يرغب تطبيق الذكاء الاصطناعي (ChatGPT / MCP Client) بالاتصال بنظامك المحاسبي
                </CardDescription>
            </CardHeader>

            <CardContent class="pt-6 space-y-6">
                <!-- User account indicator -->
                <div class="flex items-center gap-3 p-3.5 rounded-lg bg-muted/60 border border-border">
                    <div class="w-10 h-10 rounded-full bg-primary text-primary-foreground font-bold flex items-center justify-center text-base">
                        {{ user.name.charAt(0) }}
                    </div>
                    <div class="flex-1 overflow-hidden text-right">
                        <div class="text-sm font-semibold truncate">{{ user.name }} (لوحة المدير)</div>
                        <div class="text-xs text-muted-foreground truncate">{{ user.email }}</div>
                    </div>
                    <span class="inline-flex items-center gap-1 text-xs font-medium text-emerald-600 bg-emerald-500/10 px-2 py-0.5 rounded-full">
                        <ShieldCheck class="w-3.5 h-3.5" />
                        مسؤول نظام
                    </span>
                </div>

                <!-- Granted Permissions -->
                <div class="space-y-3">
                    <h4 class="text-sm font-semibold text-foreground">الصلاحيات التي سيحصل عليها الذكاء الاصطناعي:</h4>
                    <ul class="space-y-2.5 text-sm text-muted-foreground">
                        <li class="flex items-start gap-2">
                            <CheckCircle2 class="w-4 h-4 text-emerald-500 mt-0.5 shrink-0" />
                            <span>الاطلاع على شجرة الحسابات والقيود اليومية والتقارير المالية.</span>
                        </li>
                        <li class="flex items-start gap-2">
                            <CheckCircle2 class="w-4 h-4 text-emerald-500 mt-0.5 shrink-0" />
                            <span>إدارة الفواتير والعملاء والموردين وحركات المستودعات.</span>
                        </li>
                        <li class="flex items-start gap-2">
                            <CheckCircle2 class="w-4 h-4 text-emerald-500 mt-0.5 shrink-0" />
                            <span>إنشاء سندات القبض والصرف وإدارة حافظة الشيكات ومراكز التكلفة.</span>
                        </li>
                    </ul>
                </div>
            </CardContent>

            <CardFooter class="flex flex-col sm:flex-row gap-3 pt-6 border-t border-border">
                <Button 
                    variant="outline" 
                    class="w-full sm:w-1/2" 
                    :disabled="form.processing"
                    @click="submit(false)"
                >
                    رفض الاتصال
                </Button>
                <Button 
                    class="w-full sm:w-1/2 gap-2" 
                    :disabled="form.processing"
                    @click="submit(true)"
                >
                    <span>الموافقة وتفويض الاتصال</span>
                    <ArrowRight class="w-4 h-4 rotate-180" />
                </Button>
            </CardFooter>
        </Card>
    </div>
</template>
