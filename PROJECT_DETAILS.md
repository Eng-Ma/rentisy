# Rentisy Accounting ERP - Project Details & Architecture

## Overview
- **Backend**: Laravel 11 / PHP 8.2+ with SQLite / MySQL support.
- **Frontend**: Flutter 3.33+ Multi-platform (macOS, iOS, Android, Web).
- **Repository**: `https://github.com/Eng-Ma/rentisy.git` (main branch).

## Core Accounting Modules (12 Modules)
1. **Chart of Accounts (`/api/accounts`)**: Parent-child hierarchical tree, debit/credit classification, level codes (1101, 1102, 1103, 4101, 5101).
2. **Journal Entries (`/api/journal-entries`)**: Balanced double-entry transactions with debit/credit ledger lines.
3. **Vouchers (`/api/vouchers`)**: Receipt (`receipt`) & Payment (`payment`) vouchers with automated cash/bank account resolution & ledger posting. Supports flexible deletion and updates by numeric ID, voucher number (e.g. `RV-00001`), or amount.
4. **Checks (`/api/checks`)**: Portfolio lifecycle (`received`/`issued`) with status transitions (`collected`, `deposited`, `bounced`, `endorsed`, `cancelled`).
5. **Invoices (`/api/invoices`)**: Sales, Purchases, Returns with store inventory integration.
6. **Quotations (`/api/quotations`)**: Price quotations with 1-click conversion to sales invoices.
7. **Items & Warehouses (`/api/items`, `/api/stores`)**: Stock catalog, purchase/sales pricing, barcodes, multi-warehouse stock levels.
8. **Stock Transfers (`/api/stock-transfers`)**: Inter-warehouse inventory transfers.
9. **Parties (`/api/parties`)**: Customers and Vendors management with contact info.
10. **Fixed Assets (`/api/fixed-assets`)**: Capital assets with automated monthly/annual straight-line depreciation ledger generation.
11. **Cost Centers (`/api/cost-centers`)**: Projects and branches expense tracking.
12. **AI Direct Database Engine (`/api/ai/query`, `/api/ai/schema`, `/api/ai/search`)**: Real SQL execution, table schema inspector, universal full-database search.

## AI Assistant & Live Voice Call
- **Live Voice Call Mode (`AiVoiceCallScreen`)**: Real-time conversational voice call with glowing pulsing audio visualizer (ChatGPT/Gemini Live style). Speaks Arabic TTS and transcribes Arabic voice commands.
- **Microphone Input (`AiVoiceService`)**: Tap-to-speak voice transcription directly in chat bar.
- **Fast-Path Chit-Chat & Greeting Classifier**: Instantly detects casual conversation (greetings, thank-yous, status checks, who-are-you) and returns zero-latency responses without making unnecessary database queries.
- **Natural Dialect Intent Engine**: Understands conversational Arabic dialects (`اعملي`, `سويلي`, `حط`, `ضيف`, `سجل`, `بدي`, `احذفه`, `خليها 1000`).
- **Contextual Deletion & Updates**: Resolves targets by context (latest created entity), explicit ID, voucher number, or amount.
- **Zero-Hallucination Guarantee**: All accounting actions are executed against real backend endpoints; failures return concise, token-efficient error summaries instead of stack traces.
- **Live Database Streaming**: Real-time SSE streaming with Gemini, OpenAI, Groq, with live database financial snapshot injected into system prompt.
