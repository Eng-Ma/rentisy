<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Check;
use App\Models\Party;
use App\Models\Account;
use App\Models\JournalEntry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CheckApiController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->query('type'); // received or issued
        $status = $request->query('status');

        $query = Check::with(['party', 'endorsedParty', 'currency', 'voucher'])
            ->orderBy('due_date', 'asc');

        if ($type) {
            $query->where('type', $type);
        }

        if ($status) {
            $query->where('status', $status);
        }

        $checks = $query->paginate($request->input('per_page', 30));

        $stats = [
            'total_received' => (float)Check::where('type', 'received')->sum('amount'),
            'total_issued' => (float)Check::where('type', 'issued')->sum('amount'),
            'under_collection' => (float)Check::where('status', 'under_collection')->sum('amount'),
            'collected' => (float)Check::where('status', 'collected')->sum('amount'),
            'endorsed' => (float)Check::where('status', 'endorsed')->sum('amount'),
            'bounced' => (float)Check::where('status', 'bounced')->sum('amount'),
        ];

        return response()->json([
            'success' => true,
            'data' => $checks->items(),
            'stats' => $stats,
            'current_page' => $checks->currentPage(),
            'last_page' => $checks->lastPage(),
            'total' => $checks->total(),
        ]);
    }

    public function show(Check $check)
    {
        return response()->json([
            'success' => true,
            'data' => $check->load(['party', 'endorsedParty', 'currency', 'voucher', 'journalEntry.lines.account']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'check_number' => 'required|string',
            'type' => 'required|in:received,issued',
            'bank_name' => 'required|string',
            'branch' => 'nullable|string',
            'drawer_name' => 'nullable|string',
            'beneficiary_name' => 'nullable|string',
            'due_date' => 'required|date',
            'issue_date' => 'nullable|date',
            'amount' => 'required|numeric|min:0.01',
            'currency_id' => 'required|exists:currencies,id',
            'party_id' => 'nullable|exists:parties,id',
            'notes' => 'nullable|string',
        ]);

        $validated['status'] = 'under_collection';
        $check = Check::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'تمت إضافة الشيك إلى الحافظة بنجاح',
            'data' => $check->load(['party', 'currency']),
        ], 201);
    }

    public function updateStatus(Request $request, Check $check)
    {
        $validated = $request->validate([
            'status' => 'required|in:under_collection,collected,endorsed,bounced,cancelled',
            'bank_account_id' => 'nullable|exists:accounts,id',
            'endorsed_party_id' => 'nullable|exists:parties,id',
            'collection_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        DB::transaction(function () use ($check, $validated) {
            $newStatus = $validated['status'];
            $check->status = $newStatus;
            $check->notes = $validated['notes'] ?? $check->notes;

            if ($newStatus === 'collected') {
                $check->collection_date = $validated['collection_date'] ?? date('Y-m-d');
                $bankAccountId = $validated['bank_account_id'] ?? Account::where('code', '1102')->first()?->id;

                if ($bankAccountId && $check->type === 'received') {
                    $entry = JournalEntry::create([
                        'date' => $check->collection_date,
                        'reference' => 'CHK-COL-' . $check->check_number,
                        'description' => "تحصيل شيك وارد رقم {$check->check_number} من {$check->bank_name}",
                        'currency_id' => $check->currency_id,
                        'exchange_rate' => 1.0,
                    ]);

                    // Debit: Bank Account
                    $entry->lines()->create([
                        'account_id' => $bankAccountId,
                        'description' => "إيداع وتحصيل شيك {$check->check_number}",
                        'debit' => $check->amount,
                        'credit' => 0,
                    ]);

                    // Credit: Checks under collection
                    $checksBufferAccount = Account::where('code', '1101')->first() ?? $bankAccountId;
                    $entry->lines()->create([
                        'account_id' => $checksBufferAccount->id,
                        'description' => "تحصيل شيك برسم التحصيل {$check->check_number}",
                        'debit' => 0,
                        'credit' => $check->amount,
                    ]);

                    $check->journal_entry_id = $entry->id;
                }
            } elseif ($newStatus === 'endorsed') {
                $check->endorsed_party_id = $validated['endorsed_party_id'] ?? null;
                if ($check->endorsed_party_id) {
                    $endorsedParty = Party::find($check->endorsed_party_id);
                    $vendorAccountId = $endorsedParty->account_id ?? Account::where('code', '2101')->first()?->id;

                    if ($vendorAccountId) {
                        $entry = JournalEntry::create([
                            'date' => date('Y-m-d'),
                            'reference' => 'CHK-END-' . $check->check_number,
                            'description' => "تجيير شيك رقم {$check->check_number} إلى المورد {$endorsedParty->name}",
                            'currency_id' => $check->currency_id,
                            'exchange_rate' => 1.0,
                        ]);

                        // Debit: Vendor Account
                        $entry->lines()->create([
                            'account_id' => $vendorAccountId,
                            'description' => "سداد بتجيير شيك {$check->check_number}",
                            'debit' => $check->amount,
                            'credit' => 0,
                        ]);

                        // Credit: Checks buffer
                        $checksBufferAccount = Account::where('code', '1101')->first()?->id ?? $vendorAccountId;
                        $entry->lines()->create([
                            'account_id' => $checksBufferAccount,
                            'description' => "تجيير شيك {$check->check_number}",
                            'debit' => 0,
                            'credit' => $check->amount,
                        ]);

                        $check->journal_entry_id = $entry->id;
                    }
                }
            }

            $check->save();
        });

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث حالة الشيك وترحيل القيود بنجاح',
            'data' => $check->load(['party', 'endorsedParty', 'currency']),
        ]);
    }

    public function destroy(Check $check)
    {
        $check->delete();
        return response()->json([
            'success' => true,
            'message' => 'تم حذف الشيك بنجاح',
        ]);
    }
}
