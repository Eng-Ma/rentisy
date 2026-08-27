<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AiDatabaseApiController extends Controller
{
    /**
     * Get complete database schema & summary for AI context
     */
    public function schema()
    {
        try {
            $driver = DB::getDriverName();
            $tables = [];

            if ($driver === 'sqlite') {
                $tableRows = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
                foreach ($tableRows as $row) {
                    $tableName = $row->name;
                    $cols = DB::select("PRAGMA table_info({$tableName})");
                    $count = DB::table($tableName)->count();
                    $columns = array_map(function ($c) {
                        return [
                            'name' => $c->name,
                            'type' => $c->type,
                            'pk' => (bool)$c->pk,
                            'nullable' => !(bool)$c->notnull,
                        ];
                    }, $cols);

                    $tables[$tableName] = [
                        'row_count' => $count,
                        'columns' => $columns,
                    ];
                }
            } else {
                // MySQL / MariaDB / PostgreSQL
                $tableRows = DB::select('SHOW TABLES');
                $dbKey = 'Tables_in_' . env('DB_DATABASE');
                foreach ($tableRows as $row) {
                    $tableName = $row->$dbKey ?? reset($row);
                    $cols = DB::select("DESCRIBE `{$tableName}`");
                    $count = DB::table($tableName)->count();
                    $columns = array_map(function ($c) {
                        return [
                            'name' => $c->Field,
                            'type' => $c->Type,
                            'pk' => $c->Key === 'PRI',
                            'nullable' => $c->Null === 'YES',
                        ];
                    }, $cols);

                    $tables[$tableName] = [
                        'row_count' => $count,
                        'columns' => $columns,
                    ];
                }
            }

            return response()->json([
                'success' => true,
                'driver' => $driver,
                'tables_count' => count($tables),
                'tables' => $tables,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'تعذر جلب هيكلية قاعدة البيانات: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Execute direct SQL query with full flexibility (SELECT, INSERT, UPDATE, DELETE)
     */
    public function executeQuery(Request $request)
    {
        $request->validate([
            'query' => 'required|string',
        ]);

        $query = trim($request->input('query'));

        try {
            // Check query type
            $upper = strtoupper($query);
            if (str_starts_with($upper, 'SELECT') || str_starts_with($upper, 'PRAGMA') || str_starts_with($upper, 'SHOW') || str_starts_with($upper, 'EXPLAIN')) {
                $results = DB::select($query);
                return response()->json([
                    'success' => true,
                    'type' => 'read',
                    'count' => count($results),
                    'data' => $results,
                ]);
            } else {
                // Mutation (INSERT, UPDATE, DELETE)
                $affected = DB::affectingStatement($query);
                return response()->json([
                    'success' => true,
                    'type' => 'write',
                    'affected_rows' => $affected,
                    'message' => "تم تنفيذ استعلام قاعدة البيانات بنجاح (تأثر {$affected} سجل).",
                ]);
            }
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'خطأ في تنفيذ استعلام SQL: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Universal Global Search across all ERP tables
     */
    public function globalSearch(Request $request)
    {
        $term = trim($request->input('q', ''));
        if (empty($term)) {
            return response()->json(['success' => true, 'results' => []]);
        }

        $results = [];

        // 1. Parties
        $parties = DB::table('parties')
            ->where('name', 'like', "%{$term}%")
            ->orWhere('phone', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($parties->isNotEmpty()) $results['parties'] = $parties;

        // 2. Items
        $items = DB::table('items')
            ->where('name', 'like', "%{$term}%")
            ->orWhere('barcode', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($items->isNotEmpty()) $results['items'] = $items;

        // 3. Accounts
        $accounts = DB::table('accounts')
            ->where('name', 'like', "%{$term}%")
            ->orWhere('code', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($accounts->isNotEmpty()) $results['accounts'] = $accounts;

        // 4. Invoices
        $invoices = DB::table('invoices')
            ->where('invoice_number', 'like', "%{$term}%")
            ->orWhere('notes', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($invoices->isNotEmpty()) $results['invoices'] = $invoices;

        // 5. Vouchers
        $vouchers = DB::table('vouchers')
            ->where('voucher_number', 'like', "%{$term}%")
            ->orWhere('notes', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($vouchers->isNotEmpty()) $results['vouchers'] = $vouchers;

        // 6. Checks
        $checks = DB::table('checks')
            ->where('check_number', 'like', "%{$term}%")
            ->orWhere('bank_name', 'like', "%{$term}%")
            ->limit(10)
            ->get();
        if ($checks->isNotEmpty()) $results['checks'] = $checks;

        return response()->json([
            'success' => true,
            'query' => $term,
            'results' => $results,
        ]);
    }
}
