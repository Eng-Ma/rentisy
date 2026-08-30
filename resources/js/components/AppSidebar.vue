<script setup lang="ts">
import NavFooter from '@/components/NavFooter.vue';
import NavMain, { type NavGroup } from '@/components/NavMain.vue';
import NavUser from '@/components/NavUser.vue';
import { Sidebar, SidebarContent, SidebarFooter, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from '@/components/ui/sidebar';
import { Link } from '@inertiajs/vue3';
import { 
    LayoutGrid, 
    BookKey, 
    FileText, 
    Receipt, 
    CreditCard, 
    Target, 
    Package, 
    ArrowLeftRight, 
    FileSpreadsheet, 
    ShoppingCart, 
    ShoppingBag,
    Users, 
    Building2, 
    LineChart,
    Bot,
    MapPin
} from 'lucide-vue-next';
import AppLogo from './AppLogo.vue';

const navGroups: NavGroup[] = [
    {
        label: 'الرئيسية',
        items: [
            { title: 'لوحة التحكم', href: '/dashboard', icon: LayoutGrid },
        ],
    },
    {
        label: 'المحاسبة والمالية (الأصيل)',
        items: [
            { title: 'شجرة الحسابات', href: '/accounts', icon: BookKey },
            { title: 'سندات القبض والصرف', href: '/vouchers', icon: Receipt },
            { title: 'حافظة الشيكات', href: '/checks', icon: CreditCard },
            { title: 'القيود اليومية', href: '/journal-entries', icon: FileText },
            { title: 'مراكز التكلفة والمشاريع', href: '/cost-centers', icon: Target },
        ],
    },
    {
        label: 'المستودعات والمبيعات',
        items: [
            { title: 'طلبات المتجر الإلكتروني', href: '/orders', icon: ShoppingBag },
            { title: 'طرق وحسابات التحويل', href: '/transfer-methods', icon: CreditCard },
            { title: 'مناطق وأسعار التوصيل', href: '/delivery-zones', icon: MapPin },
            { title: 'الأصناف والمخزون', href: '/items', icon: Package },
            { title: 'مناقلات وحركات المخزون', href: '/stock-transfers', icon: ArrowLeftRight },
            { title: 'عروض الأسعار', href: '/quotations', icon: FileSpreadsheet },
            { title: 'الفواتير والمبيعات', href: '/invoices', icon: ShoppingCart },
            { title: 'العملاء والموردين', href: '/parties', icon: Users },
        ],
    },
    {
        label: 'الأصول والتقارير والنظام',
        items: [
            { title: 'الأصول الثابتة والإهلاك', href: '/fixed-assets', icon: Building2 },
            { title: 'التقارير المالية والأصيل', href: '/reports', icon: LineChart },
            { title: 'اتصالات الذكاء الاصطناعي (MCP)', href: '/settings/mcp', icon: Bot },
        ],
    },
];
</script>

<template>
    <Sidebar collapsible="icon" variant="inset" class="border-l border-border">
        <SidebarHeader>
            <SidebarMenu>
                <SidebarMenuItem>
                    <SidebarMenuButton size="lg" as-child>
                        <Link :href="route('dashboard')">
                            <AppLogo />
                        </Link>
                    </SidebarMenuButton>
                </SidebarMenuItem>
            </SidebarMenu>
        </SidebarHeader>

        <SidebarContent class="overflow-y-auto" style="-webkit-overflow-scrolling: touch;">
            <NavMain :groups="navGroups" />
        </SidebarContent>

        <SidebarFooter>
            <NavUser />
        </SidebarFooter>
    </Sidebar>
    <slot />
</template>
