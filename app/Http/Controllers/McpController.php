<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Psr\Http\Message\ServerRequestInterface;
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;
use Mcp\Server;
use Symfony\Component\Uid\Uuid;
use Illuminate\Support\Facades\Cache;
use App\MCP\AccountingTools;
use App\MCP\LaravelSseTransport;
use App\Models\McpToken;

class McpController extends Controller
{
    public function handle(ServerRequestInterface $psrRequest)
    {
        $method = $psrRequest->getMethod();
        $origin = $psrRequest->getHeaderLine('Origin') ?: '*';

        if ($method === 'OPTIONS') {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', $origin)
                ->header('Access-Control-Allow-Credentials', 'true')
                ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                ->header('Access-Control-Allow-Headers', '*');
        }

        // Check authentication: Token verification or active Admin Web Session
        $authHeader = $psrRequest->getHeaderLine('Authorization');
        $token = null;

        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = trim($matches[1]);
        }

        if (!$token) {
            $queryParams = $psrRequest->getQueryParams();
            $token = $queryParams['token'] ?? ($queryParams['api_key'] ?? null);
        }

        $isValid = false;
        if ($token) {
            $mcpToken = McpToken::where('token', $token)->where('is_active', true)->first();
            if ($mcpToken) {
                $isValid = true;
                $mcpToken->update(['last_used_at' => now()]);
            }
        } elseif (auth()->check()) {
            $isValid = true;
        }

        if (!$isValid) {
            return response()->json([
                'jsonrpc' => '2.0',
                'error' => [
                    'code' => -32000,
                    'message' => 'Unauthorized. Admin authentication required to access MCP server. Please login from the Admin Panel or provide a valid Bearer token generated in Settings > MCP.',
                ]
            ], 401)
            ->header('Content-Type', 'application/json')
            ->header('Access-Control-Allow-Origin', $origin);
        }

        $accountingTools = new AccountingTools();
        $sessionStore = new \App\MCP\LaravelCacheSessionStore();

        // Build the server with full CRUD and Al-Aseel Golden Tools
        $serverBuilder = Server::builder()
            ->setServerInfo('Laravel-Accounting-AlAseel-MCP', '3.0.0')
            ->setSession($sessionStore)
            // General Accounting & Queries
            ->addTool([$accountingTools, 'getAccounts'])
            ->addTool([$accountingTools, 'getInvoices'])
            ->addTool([$accountingTools, 'getBills'])
            ->addTool([$accountingTools, 'getSystemStatus'])
            ->addTool([$accountingTools, 'getParties'])
            ->addTool([$accountingTools, 'getItems'])
            ->addTool([$accountingTools, 'getStores'])
            ->addTool([$accountingTools, 'getCategories'])
            // Creation Tools
            ->addTool([$accountingTools, 'createCustomer'])
            ->addTool([$accountingTools, 'createVendor'])
            ->addTool([$accountingTools, 'createItem'])
            ->addTool([$accountingTools, 'createStore'])
            ->addTool([$accountingTools, 'createCategory'])
            ->addTool([$accountingTools, 'createInvoice'])
            ->addTool([$accountingTools, 'createAccount'])
            ->addTool([$accountingTools, 'createJournalEntry'])
            // Updates & Deletes
            ->addTool([$accountingTools, 'updateParty'])
            ->addTool([$accountingTools, 'updateItem'])
            ->addTool([$accountingTools, 'updateStore'])
            ->addTool([$accountingTools, 'updateCategory'])
            ->addTool([$accountingTools, 'updateAccount'])
            ->addTool([$accountingTools, 'deleteInvoice'])
            ->addTool([$accountingTools, 'deleteParty'])
            ->addTool([$accountingTools, 'deleteItem'])
            ->addTool([$accountingTools, 'deleteStore'])
            ->addTool([$accountingTools, 'deleteCategory'])
            ->addTool([$accountingTools, 'deleteAccount'])
            ->addTool([$accountingTools, 'deleteJournalEntry'])
            // Al-Aseel Golden: Vouchers (سندات القبض والصرف)
            ->addTool([$accountingTools, 'getVouchers'])
            ->addTool([$accountingTools, 'getVoucher'])
            ->addTool([$accountingTools, 'createVoucher'])
            ->addTool([$accountingTools, 'createReceiptVoucher'])
            ->addTool([$accountingTools, 'createPaymentVoucher'])
            ->addTool([$accountingTools, 'updateVoucher'])
            ->addTool([$accountingTools, 'deleteVoucher'])
            // Al-Aseel Golden: Checks Portfolio (حافظة الشيكات)
            ->addTool([$accountingTools, 'getChecks'])
            ->addTool([$accountingTools, 'createCheck'])
            ->addTool([$accountingTools, 'updateCheckStatus'])
            ->addTool([$accountingTools, 'collectCheck'])
            ->addTool([$accountingTools, 'endorseCheck'])
            // Al-Aseel Golden: Cost Centers (مراكز التكلفة)
            ->addTool([$accountingTools, 'getCostCenters'])
            ->addTool([$accountingTools, 'createCostCenter'])
            ->addTool([$accountingTools, 'updateCostCenter'])
            ->addTool([$accountingTools, 'deleteCostCenter'])
            // Al-Aseel Golden: Stock Movements & Transfers (مناقلات وحركات المخزون)
            ->addTool([$accountingTools, 'getStockTransfers'])
            ->addTool([$accountingTools, 'createStockTransfer'])
            ->addTool([$accountingTools, 'createStockAdjustment'])
            // Al-Aseel Golden: Quotations (عروض الأسعار)
            ->addTool([$accountingTools, 'getQuotations'])
            ->addTool([$accountingTools, 'createQuotation'])
            ->addTool([$accountingTools, 'convertQuotationToInvoice'])
            // Al-Aseel Golden: Fixed Assets (الأصول الثابتة والإهلاك)
            ->addTool([$accountingTools, 'getFixedAssets'])
            ->addTool([$accountingTools, 'createFixedAsset'])
            ->addTool([$accountingTools, 'calculateDepreciation'])
            // Al-Aseel Golden: Advanced Reports & Statements (القوائم المالية والتقارير المحاسبية)
            ->addTool([$accountingTools, 'getAccountStatement'])
            ->addTool([$accountingTools, 'getTrialBalance'])
            ->addTool([$accountingTools, 'getIncomeStatement'])
            ->addTool([$accountingTools, 'getPartyStatement'])
            ->addTool([$accountingTools, 'getStockMovementReport'])
            ->addTool([$accountingTools, 'getAgingReport'])
            ->addTool([$accountingTools, 'getCostCentersReport'])
            ->addTool([$accountingTools, 'getChecksReport'])
            ->addTool([$accountingTools, 'getInventoryValuationReport'])
            ->addTool([$accountingTools, 'getDashboardSummary'])
            // E-Commerce Orders & AI Analytics (إدارة الطلبات والمبيعات الإلكترونية)
            ->addTool([$accountingTools, 'getOrders'])
            ->addTool([$accountingTools, 'getOrderDetails'])
            ->addTool([$accountingTools, 'updateOrderStatus'])
            ->addTool([$accountingTools, 'updateOrder'])
            ->addTool([$accountingTools, 'deleteOrder'])
            ->addTool([$accountingTools, 'analyzeOrdersSales']);

        $server = $serverBuilder->build();

        $transport = new LaravelSseTransport($psrRequest);

        return $server->run($transport);
    }
}
