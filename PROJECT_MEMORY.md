# Project Memory: Accounting / Rentisy (Al-Aseel Golden Edition)

## Project Overview
A complete enterprise-grade accounting and ERP system inspired by "Al-Aseel Al-Dhahabi" (برنامج الأصيل الذهبي للمحاسبة والمستودعات).
- **Web Backend & Panel:** Laravel 12+, Inertia.js, and Vue 3 with TypeScript, styled with Tailwind CSS.
- **REST API Suite:** Full API coverage under `/api/...` for mobile & external integrations with Token-based authentication.
- **Mobile & Multi-platform App:** Flutter (iOS, Android, macOS, Web, Windows) with modern responsive UI and full Arabic RTL / English support.
- **AI & MCP:** Model Context Protocol (MCP) server integration for automated agentic bookkeeping.

## Key Technologies
- **Backend:** Laravel 12+ (PHP 8.2+)
- **Web Panel:** Vue 3, Inertia.js, Tailwind CSS, Lucide Icons
- **Mobile/Client App:** Flutter (Dart), Material 3, Glassmorphism design tokens, Provider state management, Dio HTTP client
- **Database:** SQLite / MySQL / PostgreSQL with Eloquent ORM
- **Git Remote:** `https://github.com/Eng-Ma/rentisy.git` (Branch: `main`)

## Core Modules & Capabilities (Al-Aseel Golden Feature Matrix)
1. **Authentication & Session**:
   - Web: Laravel Breeze / Session auth.
   - API / Flutter: Token-based auth (`Bearer <token>`), dynamic backend host switcher, remember me.
2. **General Accounting & Chart of Accounts (المحاسبة العامة وشجرة الحسابات)**:
   - Multi-level Chart of Accounts (`Account`), type classification (Asset, Liability, Equity, Revenue, Expense), Debit/Credit balance.
   - Multi-line balanced Journal Entries (`JournalEntry`, `JournalEntryLine`) with automated balance verification.
   - Currencies & Exchange Rates (`Currency`).
3. **Receipt & Payment Vouchers (سندات القبض والصرف)**:
   - Cash / Bank / Check vouchers with automated balanced double-entry accounting (`Voucher`).
4. **Checks Portfolio & Management (حافظة الشيكات)**:
   - Received and Issued Checks tracking (`Check`).
   - Complete Lifecycle: Under Collection, Deposited/Collected in Bank, Endorsed to Vendor, Returned/Bounced, Cancelled.
5. **Cost Centers (مراكز التكلفة)**:
   - Multi-level Cost Center tree (`CostCenter`) with line-level allocation across journals, vouchers, and invoices.
6. **Inventory & Warehouse Management (المستودعات والمخزون)**:
   - Multi-store catalog (`Item`, `Category`, `Store`, `StoreItem`).
   - Stock Transfers, Adjustments, Stock-in / Stock-out (`StockTransfer`, `StockTransferLine`).
7. **Sales & Purchases (المبيعات والمشتريات)**:
   - Invoices (Cash/Credit sales, purchases, returns) (`Invoice`, `InvoiceLine`) with automatic inventory stock deductions/additions and automatic journal entries.
   - Quotations & Price Offers (`Quotation`, `QuotationLine`) with 1-click conversion to sales invoices.
8. **Fixed Assets & Depreciation (الأصول الثابتة والإهلاك)**:
   - Fixed Asset register with cost, useful life, salvage value, accumulated depreciation, and 1-click depreciation journal entry calculation & posting.
9. **Financial & Operational Reports (تقارير الأصيل المتقدمة)**:
   - Account Statement (كشف حساب تفصيلي).
   - Trial Balance (ميزان المراجعة بالمجاميع والأرصدة).
   - Income Statement (قائمة الدخل - الأرباح والخسائر).
   - Customer / Supplier Statement (كشف حساب عميل ومورد).
   - Aging of Receivables & Payables (أعمار الديون).
   - Cost Centers Statement (كشف مراكز التكلفة).
   - Checks Portfolio Status (تقرير الشيكات والإحصائيات).
   - Item Stock Movement & Profitability (حركة الأصناف والمخزون).

## REST API Endpoints Summary (`/api/...`)
- `POST /api/login` - Authenticate user & return token
- `POST /api/register` - Register new user
- `POST /api/logout` - Revoke token
- `GET /api/user` - Current authenticated user
- `GET /api/dashboard` - KPI summary stats & metrics
- `GET /api/accounts`, `POST /api/accounts`, `PUT /api/accounts/{id}`, `DELETE /api/accounts/{id}`
- `GET /api/journal-entries`, `POST /api/journal-entries`, `GET /api/journal-entries/{id}`
- `GET /api/cost-centers`, `POST /api/cost-centers`, `PUT /api/cost-centers/{id}`, `DELETE /api/cost-centers/{id}`
- `GET /api/currencies`
- `GET /api/vouchers`, `POST /api/vouchers`, `GET /api/vouchers/{id}`, `DELETE /api/vouchers/{id}`
- `GET /api/checks`, `POST /api/checks`, `POST /api/checks/{id}/status`, `DELETE /api/checks/{id}`
- `GET /api/items`, `POST /api/items`, `PUT /api/items/{id}`, `DELETE /api/items/{id}`
- `GET /api/categories`, `POST /api/categories`
- `GET /api/stores`, `POST /api/stores`
- `GET /api/stock-transfers`, `POST /api/stock-transfers`, `GET /api/stock-transfers/{id}`, `DELETE /api/stock-transfers/{id}`
- `GET /api/parties`, `POST /api/parties`, `PUT /api/parties/{id}`, `DELETE /api/parties/{id}`
- `GET /api/invoices`, `POST /api/invoices`, `GET /api/invoices/{id}`
- `GET /api/quotations`, `POST /api/quotations`, `GET /api/quotations/{id}`, `POST /api/quotations/{id}/convert`, `DELETE /api/quotations/{id}`
- `GET /api/fixed-assets`, `POST /api/fixed-assets`, `POST /api/fixed-assets/{id}/depreciate`, `DELETE /api/fixed-assets/{id}`
- `GET /api/reports/account-statement`
- `GET /api/reports/trial-balance`
- `GET /api/reports/income-statement`
- `GET /api/reports/party-statement`
- `GET /api/reports/aging`
- `GET /api/reports/cost-centers`
- `GET /api/reports/checks`
- `GET /api/reports/stock-movement`

## Flutter Application Structure (`flutter_app/`)
- `lib/core/`: Theme, AppColors, API Client with auth token interceptor, responsive layout builders, glassmorphism cards.
- `lib/features/`:
  - `auth/`: Login screen with demo credentials shortcut, dynamic API host switcher.
  - `dashboard/`: KPI stats, quick actions, financial overview.
  - `accounts/`: Chart of accounts tree, balance filters, new account modal.
  - `journal_entries/`: Journal entry listing, search, balanced multi-line entry builder.
  - `vouchers/`: Receipt & Payment vouchers, check linking, journal generation.
  - `checks/`: Received/Issued checks portfolio, 1-click collection & endorsement actions.
  - `inventory/`: Items catalog, barcode search, stock transfers & adjustments.
  - `invoices/`: Sales & purchase invoices, interactive item lines calculation, print-ready view.
  - `quotations/`: Price offers, status tracking, 1-click invoice conversion.
  - `fixed_assets/`: Assets register, book value tracking, 1-click depreciation generator.
  - `cost_centers/`: Cost centers tree & expense/revenue tracking.
  - `parties/`: Customer and vendor management.
  - `reports/`: Complete 8 Al-Aseel financial & stock reports with charts & tables.
  - `settings/`: Host URL configuration, dark/light theme, user profile.
