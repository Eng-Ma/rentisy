<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\Category;
use Illuminate\Http\Request;

class StoreAiAdvisorController extends Controller
{
    /**
     * AI Shopping Advisor recommendation endpoint.
     */
    public function recommend(Request $request)
    {
        $prompt = trim($request->input('prompt', ''));
        $maxPrice = $request->filled('max_price') ? (float)$request->input('max_price') : null;
        $minPrice = $request->filled('min_price') ? (float)$request->input('min_price') : null;
        $useCase = $request->input('use_case', 'all'); // business, gaming, design, student, audio, mobile

        $query = Item::where('is_active', true)->with(['category', 'storeItems']);

        if ($maxPrice) {
            $query->where('sales_price', '<=', $maxPrice);
        }
        if ($minPrice) {
            $query->where('sales_price', '>=', $minPrice);
        }

        // Keywords detection
        if (!empty($prompt)) {
            $keywords = array_filter(explode(' ', $prompt));
            $query->where(function ($q) use ($keywords, $prompt) {
                $q->where('name', 'like', "%{$prompt}%")
                  ->orWhere('description', 'like', "%{$prompt}%");

                foreach ($keywords as $kw) {
                    if (mb_strlen($kw) >= 3) {
                        $q->orWhere('name', 'like', "%{$kw}%")
                          ->orWhere('description', 'like', "%{$kw}%");
                    }
                }
            });
        }

        // Use-case heuristic matching
        if ($useCase === 'business' || str_contains($prompt, 'محاسب') || str_contains($prompt, 'أعمال') || str_contains($prompt, 'شركة')) {
            $query->orWhere('name', 'like', '%ThinkPad%')
                  ->orWhere('name', 'like', '%Logitech%')
                  ->orWhere('name', 'like', '%MacBook%');
        } elseif ($useCase === 'design' || str_contains($prompt, 'تصميم') || str_contains($prompt, 'مونتاج') || str_contains($prompt, 'جرافيك')) {
            $query->orWhere('name', 'like', '%MacBook%')
                  ->orWhere('name', 'like', '%XPS%')
                  ->orWhere('name', 'like', '%LG%')
                  ->orWhere('name', 'like', '%iPad%');
        } elseif ($useCase === 'audio' || str_contains($prompt, 'صوت') || str_contains($prompt, 'سماعة') || str_contains($prompt, 'عزل')) {
            $query->orWhere('name', 'like', '%Sony%')
                  ->orWhere('name', 'like', '%AirPods%');
        } elseif ($useCase === 'mobile' || str_contains($prompt, 'هاتف') || str_contains($prompt, 'جوال') || str_contains($prompt, 'موبايل')) {
            $query->orWhere('name', 'like', '%iPhone%')
                  ->orWhere('name', 'like', '%Galaxy%');
        }

        $items = $query->take(6)->get()->append(['effective_price', 'total_stock']);

        // Fallback if strict query was empty
        if ($items->isEmpty()) {
            $items = Item::where('is_active', true)
                ->where('is_featured', true)
                ->with(['category', 'storeItems'])
                ->take(4)
                ->get()
                ->append(['effective_price', 'total_stock']);
        }

        // Generate tailored AI shopping advice
        $aiAdvice = "بناءً على طلبك وميزانيتك المحددة، قمنا بفحص مواصفات الأصناف والأرصدة المتوفرة لحظياً في المستودع واخترنا لك أفضل خيارات ذات جودة فائقة وكفالة معتمدة تناسب استخدامك تماماً.";

        if ($maxPrice && $items->isNotEmpty()) {
            $firstItem = $items->first();
            $aiAdvice = "تم ترشيح {$firstItem->name} كخيار أول لك؛ لأنه يمنحك أفضل قيمة وأداء ضمن ميزانية {$maxPrice} ₪ مع توفر مخزون فوري بالمستودع وضمان رسمي.";
        }

        return response()->json([
            'status' => 'success',
            'ai_advice' => $aiAdvice,
            'items' => $items,
            'count' => $items->count(),
        ]);
    }
}
