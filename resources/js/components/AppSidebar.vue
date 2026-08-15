<script setup lang="ts">
import NavFooter from '@/components/NavFooter.vue';
import NavMain from '@/components/NavMain.vue';
import NavUser from '@/components/NavUser.vue';
import { Sidebar, SidebarContent, SidebarFooter, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from '@/components/ui/sidebar';
import { type NavItem } from '@/types';
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
    Users, 
    Building2, 
    LineChart,
    Bot,
    Folder,
    BookOpen
} from 'lucide-vue-next';
import AppLogo from './AppLogo.vue';

const mainNavItems: NavItem[] = [
    {
        title: 'الرئيسية',
        href: '/dashboard',
        icon: LayoutGrid,
    },
    {
        title: 'شجرة الحسابات',
        href: '/accounts',
        icon: BookKey,
    },
    {
        title: 'مراكز التكلفة',
        href: '/cost-centers',
        icon: Target,
    },
    {
        title: 'القيود اليومية',
        href: '/journal-entries',
        icon: FileText,
    },
    {
        title: 'سندات القبض والصرف',
        href: '/vouchers',
        icon: Receipt,
    },
    {
        title: 'حافظة الشيكات',
        href: '/checks',
        icon: CreditCard,
    },
    {
        title: 'الأصناف والمخزون',
        href: '/items',
        icon: Package,
    },
    {
        title: 'مناقلات وحركات المخزون',
        href: '/stock-transfers',
        icon: ArrowLeftRight,
    },
    {
        title: 'عروض الأسعار',
        href: '/quotations',
        icon: FileSpreadsheet,
    },
    {
        title: 'الفواتير والمبيعات',
        href: '/invoices',
        icon: ShoppingCart,
    },
    {
        title: 'العملاء والموردين',
        href: '/parties',
        icon: Users,
    },
    {
        title: 'الأصول الثابتة',
        href: '/fixed-assets',
        icon: Building2,
    },
    {
        title: 'التقارير المالية والأصيل',
        href: '/reports',
        icon: LineChart,
    },
    {
        title: 'اتصالات الذكاء الاصطناعي (MCP)',
        href: '/settings/mcp',
        icon: Bot,
    },
];

const footerNavItems: NavItem[] = [];
</script>

<template>
    <Sidebar collapsible="icon" variant="inset">
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

        <SidebarContent>
            <NavMain :items="mainNavItems" />
        </SidebarContent>

        <SidebarFooter>
            <NavUser />
        </SidebarFooter>
    </Sidebar>
    <slot />
</template>
