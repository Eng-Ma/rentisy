# Project Memory: Accounting / Rentisy (Al-Aseel Golden Edition)

## Project Overview
A complete enterprise-grade accounting and ERP system inspired by "Al-Aseel Al-Dhahabi" (برنامج الأصيل الذهبي للمحاسبة والمستودعات), built with Laravel 11+, Inertia.js, and Vue 3 with TypeScript, styled with Tailwind CSS, with native Model Context Protocol (MCP) server integration.

## Key Technologies
- **Backend:** Laravel 11+ (PHP 8.2+)
- **Frontend Framework:** Vue 3 with TypeScript & Lucide Icons
- **State/Routing Bridge:** Inertia.js (Vue 3 adapter)
- **Styling:** Tailwind CSS, Radix Vue
- **Build Tool:** Vite
- **Database:** SQLite / MySQL / PostgreSQL with Eloquent ORM

## Git Configuration
- **Remote URL:** `https://github.com/Eng-Ma/rentisy.git`
- **Branch:** `main`

## Core Modules (Al-Aseel Golden Feature Matrix)
1. **General Accounting & Chart of Accounts (المحاسبة العامة وشجرة الحسابات)**:
   - Multi-level Chart of Accounts (`Account`)
   - Balanced Journal Entries (`JournalEntry`, `JournalEntryLine`)
   - Currencies & Exchange Rates (`Currency`)
2. **Receipt & Payment Vouchers (سندات القبض والصرف)**:
   - Cash / Bank / Check vouchers with automated balanced double-entry accounting (`Voucher`).
3. **Checks Portfolio & Management (حافظة الشيكات)**:
   - Received and Issued Checks tracking (`Check`).
   - Lifecycle: Under Collection, Deposited/Collected, Endorsed to Vendor, Returned/Bounced, Cancelled.
4. **Cost Centers (مراكز التكلفة)**:
   - Multi-level Cost Center tree (`CostCenter`) with line-level allocation across journals, vouchers, and invoices.
5. **Inventory & Warehouse Management (المستودعات والمخزون)**:
   - Multi-store catalog (`Item`, `Category`, `Store`, `StoreItem`).
   - Stock Transfers, Adjustments, Stock-in / Stock-out (`StockTransfer`, `StockTransferLine`).
6. **Sales & Purchases (المبيعات والمشتريات)**:
   - Invoices (Cash/Credit sales, purchases, returns) (`Invoice`, `InvoiceLine`).
   - Quotations & Price Offers with 1-click invoice conversion (`Quotation`, `QuotationLine`).
7. **Fixed Assets & Depreciation (الأصول الثابتة والإهلاك)**:
   - Fixed Asset register with automatic depreciation schedule & journal generation (`FixedAsset`, `AssetDepreciation`).
8. **Al-Aseel Financial & Operational Reports (تقارير الأصيل المتقدمة)**:
   - Account Statement (كشف حساب), Trial Balance (ميزان المراجعة), Income Statement (قائمة الدخل).
   - Aging of Receivables & Payables (أعمار الديون).
   - Cost Centers Statement (كشف مراكز التكلفة).
   - Checks Portfolio Status (تقرير الشيكات).
   - Item Stock Movement & Profitability (حركة الأصناف والربحية).

## MCP Server Configuration
- **SSE Endpoint:** `https://rantisy.matajir.io/mcp/sse`
- **Messages Endpoint:** `https://rantisy.matajir.io/mcp/messages`
- **Controller:** `App\Http\Controllers\McpController`
- **Transport:** `App\MCP\LaravelSseTransport` (File Cache store)
- **Tools Suite:** `App\MCP\AccountingTools`
  - Complete read, write, update, delete, lifecycle, and reporting tools matching all system capabilities.
