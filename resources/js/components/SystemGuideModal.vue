<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { 
    HelpCircle, 
    X, 
    ArrowRight, 
    ArrowLeft, 
    CheckCircle2, 
    Sparkles, 
    BookKey, 
    Receipt, 
    CreditCard, 
    Package, 
    FileSpreadsheet, 
    Building2, 
    LineChart,
    Bot,
    Compass
} from 'lucide-vue-next';
import { Button } from '@/components/ui/button';

const props = withDefaults(defineProps<{
    modelValue?: boolean;
    autoOpenFirstTime?: boolean;
}>(), {
    modelValue: false,
    autoOpenFirstTime: true,
});

const emit = defineEmits<{
    (e: 'update:modelValue', value: boolean): void;
}>();

const isVisible = ref(false);
const currentStep = ref(0);

const steps = [
    {
        title: 'مرحباً بك في نظام الأصيل الذهبي المحاسبي',
        subtitle: 'نظام إدارة مالي ومستودعي متكامل مبني بأعلى معايير المحاسبة المزدوجة.',
        icon: Sparkles,
        color: 'from-blue-600 to-indigo-600',
        badge: 'جولة تعريفية سريعة',
        points: [
            { title: 'واجهة عصرية وسريعة', desc: 'نظام فائق السرعة يدعم الوضع الليلي والنهاري والعمل بسلاسة على كافة الشاشات.' },
            { title: 'محرك بحث فوري (Cmd + K)', desc: 'اضغط في أي وقت على Cmd+K للبحث السريع عن أي صفحة، تقرير، أو سند في ثوانٍ.' },
            { title: 'ترحيل قيود آلي', desc: 'جميع الفواتير والسندات والإهلاكات يتم ترحيل قيودها المحاسبية تلقائياً في دفتر الأستاذ.' }
        ]
    },
    {
        title: 'المحاسبة العامة وشجرة الحسابات ومراكز التكلفة',
        subtitle: 'إدارة متكاملة للحسابات العامة وقيود اليومية ومراكز التكلفة للمشاريع.',
        icon: BookKey,
        color: 'from-indigo-600 to-purple-600',
        badge: 'المحاسبة العامة',
        points: [
            { title: 'دليل الحسابات الشجري', desc: 'شجرة حسابات مرنة (أصول، خصوم، حقوق ملكية، إيرادات، ومصروفات).' },
            { title: 'القيود اليومية المزدوجة', desc: 'تسجيل القيود اليدوية والآلية مع التحقق الصارم من توازن المدين والدائن.' },
            { title: 'دليل مراكز التكلفة', desc: 'تخصيص المصاريف والإيرادات على المشاريع والفروع لمعرفة ربحية كل مركز بدقة.' }
        ]
    },
    {
        title: 'سندات القبض والصرف وحافظة الشيكات',
        subtitle: 'توثيق مقبوضات ومدفوعات المنشأة وتتبع دورة حياة الشيكات البنكية.',
        icon: Receipt,
        color: 'from-emerald-600 to-teal-600',
        badge: 'الخزينة والشيكات',
        points: [
            { title: 'سندات القبض والصرف', desc: 'إصدار سندات مالية (نقدي، بنكي، شيك) مع شاشات طباعة رسمية فورية.' },
            { title: 'حافظة الشيكات', desc: 'متابعة الشيكات الواردة والصادرة وحالاتها (برسم التحصيل، محصل، مجير، مرتجع).' },
            { title: 'تحصيل وتجيير فوري', desc: 'تحصيل الشيك في البنك أو تجييره لمورد بنقرة زر مع توليد القيود تلقائياً.' }
        ]
    },
    {
        title: 'المستودعات والمخزون والمناقلات',
        subtitle: 'مراقبة حركة البضائع، سندات الإدخال والإخراج، والمناقلة بين الفروع.',
        icon: Package,
        color: 'from-amber-500 to-orange-600',
        badge: 'المستودعات',
        points: [
            { title: 'بطاقات الأصناف والباركود', desc: 'تسجيل أسعار التكلفة وسعر البيع ووحدات القياس وتنبيهات نواقص المخزون.' },
            { title: 'مناقلات بين المستودعات', desc: 'تحويل البضائع بين الفروع والمستودعات مع تحديث الأرصدة تلقائياً.' },
            { title: 'التسويات الجردية', desc: 'سندات إدخال بضاعة، إخراج تالف، وإجراء جرد المخازن الفعلي.' }
        ]
    },
    {
        title: 'عروض الأسعار والفواتير والمبيعات',
        subtitle: 'دورة مبيعات ومشتريات تبدأ من عرض السعر وحتى الفاتورة الرسمية.',
        icon: FileSpreadsheet,
        color: 'from-blue-500 to-cyan-600',
        badge: 'المبيعات والمشتريات',
        points: [
            { title: 'عروض أسعار ذكية', desc: 'إصدار عروض أسعار تجارية للعملاء بمدد صلاحية ونسب خصم وطباعة معتمدة.' },
            { title: 'تحويل العرض لفاتورة بنقرة زر', desc: 'زر سريع يحول عرض السعر لفاتورة مبيعات، يخصم المخزن، ويرحل القيد فوراً.' },
            { title: 'فواتير المبيعات والمشتريات', desc: 'إدارة المبيعات والمشتريات والمردودات وحسابات الذمم المدينة والدائنة.' }
        ]
    },
    {
        title: 'الأصول الثابتة واحتساب الإهلاك',
        subtitle: 'تسجيل أصول الشركة الرأسمالية واحتساب الإهلاك الدوري آلياً.',
        icon: Building2,
        color: 'from-rose-500 to-pink-600',
        badge: 'الأصول الثابتة',
        points: [
            { title: 'سجل بطاقات الأصول', desc: 'حفظ تكلفة الشراء، العمر الإنتاجي، القيمة التخريدية، ونسبة الإهلاك.' },
            { title: 'احتساب الإهلاك الدوري', desc: 'حساب قسط الإهلاك وتوليد قيد الإهلاك في دفتر الأستاذ بنقرة واحدة.' },
            { title: 'متابعة القيمة الدفترية', desc: 'مراقبة صافي القيمة الدفترية للأصل ومجمع الإهلاك التراكمي.' }
        ]
    },
    {
        title: 'تقارير الأصيل وربط الذكاء الاصطناعي (MCP)',
        subtitle: 'مجموعة تقارير مالية تحليلية ومساعد ذكي مرتبط بالكامل مع ChatGPT.',
        icon: Bot,
        color: 'from-violet-600 to-indigo-600',
        badge: 'التقارير والذكاء الاصطناعي',
        points: [
            { title: 'تقرير أعمار الديون (Aging)', desc: 'تحليل أعمار ديون العملاء والموردين على فترات (0-30، 31-60، +90 يوماً).' },
            { title: 'كشوفات الحسابات والمراكز', desc: 'ميزان المراجعة، قائمة الدخل، كشف مراكز التكلفة، وتقييم المخزون.' },
            { title: 'المصادقة مع ChatGPT و MCP', desc: 'ربط النظام مع ChatGPT لتنفيذ العمليات المحاسبية عبر الأوامر النصية بأمان.' }
        ]
    }
];

const openGuide = () => {
    currentStep.value = 0;
    isVisible.value = true;
    emit('update:modelValue', true);
};

const closeGuide = () => {
    isVisible.value = false;
    emit('update:modelValue', false);
    localStorage.setItem('has_seen_alaseel_guide', 'true');
};

const nextStep = () => {
    if (currentStep.value < steps.length - 1) {
        currentStep.value++;
    } else {
        closeGuide();
    }
};

const prevStep = () => {
    if (currentStep.value > 0) {
        currentStep.value--;
    }
};

const goToStep = (index: number) => {
    currentStep.value = index;
};

onMounted(() => {
    if (props.autoOpenFirstTime) {
        const seen = localStorage.getItem('has_seen_alaseel_guide');
        if (!seen) {
            // Auto open guide for new users
            setTimeout(() => {
                openGuide();
            }, 500);
        }
    }
});

defineExpose({
    openGuide,
    closeGuide,
});
</script>

<template>
    <div>
        <!-- Modal Overlay -->
        <div v-if="isVisible" class="fixed inset-0 z-[120] flex items-center justify-center p-4">
            <div class="fixed inset-0 bg-black/70 backdrop-blur-sm transition-opacity" @click="closeGuide"></div>

            <!-- Guide Card Container -->
            <div 
                class="relative w-full max-w-2xl bg-card border border-border shadow-2xl rounded-3xl overflow-hidden z-10 transition-all flex flex-col max-h-[90vh]"
                dir="rtl"
            >
                <!-- Top Header with Progress -->
                <div class="p-6 pb-4 border-b border-border bg-muted/20 relative">
                    <div class="flex items-center justify-between mb-4">
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                                <Compass class="w-5 h-5" />
                            </div>
                            <div>
                                <h3 class="text-base font-bold text-foreground">دليل الاستخدام السريع</h3>
                                <span class="text-xs text-muted-foreground">جولة تعريفية بميزات نظام الأصيل الذهبي</span>
                            </div>
                        </div>

                        <div class="flex items-center gap-2">
                            <span class="text-xs font-mono font-bold text-muted-foreground bg-muted px-2.5 py-1 rounded-full border border-border">
                                {{ currentStep + 1 }} / {{ steps.length }}
                            </span>
                            <button 
                                @click="closeGuide" 
                                class="w-8 h-8 rounded-full hover:bg-muted text-muted-foreground hover:text-foreground flex items-center justify-center transition-colors"
                                title="إغلاق الدليل"
                            >
                                <X class="w-4 h-4" />
                            </button>
                        </div>
                    </div>

                    <!-- Progress Dots -->
                    <div class="flex items-center gap-1.5 justify-center">
                        <button 
                            v-for="(step, idx) in steps" 
                            :key="idx" 
                            @click="goToStep(idx)"
                            class="h-1.5 rounded-full transition-all duration-300"
                            :class="idx === currentStep ? 'w-8 bg-primary' : (idx < currentStep ? 'w-3 bg-primary/40 hover:bg-primary/60' : 'w-3 bg-muted hover:bg-muted-foreground/30')"
                        />
                    </div>
                </div>

                <!-- Step Content Body (Scrollable) -->
                <div class="p-6 overflow-y-auto space-y-6 flex-1">
                    <!-- Step Hero Banner -->
                    <div class="flex items-start gap-4 p-4 rounded-2xl bg-gradient-to-l from-primary/10 via-primary/5 to-transparent border border-primary/20">
                        <div class="w-12 h-12 rounded-xl bg-gradient-to-br text-white flex items-center justify-center shadow-md shrink-0" :class="steps[currentStep].color">
                            <component :is="steps[currentStep].icon" class="w-6 h-6" />
                        </div>
                        <div>
                            <div class="inline-block px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-primary/15 text-primary mb-1 border border-primary/20">
                                {{ steps[currentStep].badge }}
                            </div>
                            <h2 class="text-lg font-bold text-foreground">{{ steps[currentStep].title }}</h2>
                            <p class="text-xs text-muted-foreground mt-0.5 leading-relaxed">{{ steps[currentStep].subtitle }}</p>
                        </div>
                    </div>

                    <!-- Feature Bullet Points -->
                    <div class="space-y-3">
                        <div 
                            v-for="(pt, pIdx) in steps[currentStep].points" 
                            :key="pIdx" 
                            class="p-3.5 bg-muted/40 hover:bg-muted/60 transition-colors rounded-xl border border-border/70 flex items-start gap-3"
                        >
                            <div class="w-5 h-5 rounded-full bg-emerald-500/10 text-emerald-600 flex items-center justify-center shrink-0 mt-0.5">
                                <CheckCircle2 class="w-3.5 h-3.5" />
                            </div>
                            <div>
                                <h4 class="text-sm font-bold text-foreground">{{ pt.title }}</h4>
                                <p class="text-xs text-muted-foreground mt-0.5 leading-relaxed">{{ pt.desc }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Footer Navigation Buttons -->
                <div class="p-4 px-6 border-t border-border bg-card flex justify-between items-center gap-3">
                    <Button variant="ghost" size="sm" @click="closeGuide" class="text-muted-foreground hover:text-foreground text-xs font-semibold">
                        تخطي الشرح (Skip)
                    </Button>

                    <div class="flex items-center gap-2">
                        <Button 
                            v-if="currentStep > 0" 
                            variant="outline" 
                            size="sm" 
                            @click="prevStep" 
                            class="gap-1 text-xs"
                        >
                            <ArrowRight class="w-3.5 h-3.5" />
                            <span>السابق</span>
                        </Button>

                        <Button 
                            size="sm" 
                            @click="nextStep" 
                            class="gap-1 text-xs px-5 font-bold"
                        >
                            <span>{{ currentStep === steps.length - 1 ? 'إنهاء وبدء العمل' : 'التالي' }}</span>
                            <ArrowLeft v-if="currentStep < steps.length - 1" class="w-3.5 h-3.5" />
                            <CheckCircle2 v-else class="w-3.5 h-3.5" />
                        </Button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
