# Project Memory: Accounting / Rentisy

## Project Overview
This is a Laravel application integrated with Inertia.js and Vue 3 for an Accounting/Rentisy system.

## Key Technologies
- **Backend:** Laravel 11+ (PHP 8.2+)
- **Frontend Framework:** Vue 3 with TypeScript
- **State/Routing Bridge:** Inertia.js (Vue 3 adapter)
- **Styling:** Tailwind CSS, Radix Vue, Headless UI Vue
- **Build Tool:** Vite
- **Database/Seeders:** DatabaseSeeder, stores migration, JournalEntry and Account models are used.

## Git Configuration
- **Remote URL:** `https://github.com/Eng-Ma/rentisy.git`

## MCP Server Configuration
- **SSE Endpoint:** `https://rantisy.matajir.io/mcp/sse`
- **Messages Endpoint:** `https://rantisy.matajir.io/mcp/messages`
- **Controller:** `App\Http\Controllers\McpController`
- **Transport:** `App\MCP\LaravelSseTransport`
- **Tools (Full CRUD Suite):** `App\MCP\AccountingTools`
  - **Read Queries:** `get_accounts`, `get_invoices`, `get_bills`, `get_system_status`, `get_parties`, `get_items`, `get_stores`, `get_categories`
  - **Creation (Writes):** `create_customer`, `create_vendor`, `create_item`, `create_store`, `create_category`, `create_invoice`, `create_account`, `create_journal_entry`
  - **Updates:** `update_party`, `update_item`, `update_store`, `update_category`, `update_account`
  - **Deletions:** `delete_invoice`, `delete_party`, `delete_item`, `delete_store`, `delete_category`, `delete_account`, `delete_journal_entry`
- **OAuth Discovery:** Endpoints configured in `routes/web.php` (`/.well-known/oauth-authorization-server`, `/oauth/authorize`, `/oauth/token`, `/oauth/register`)
- **Transport Cache Store:** Must explicitly use `Cache::store('file')` across all send/receive methods so FPM POST and SSE workers communicate.
