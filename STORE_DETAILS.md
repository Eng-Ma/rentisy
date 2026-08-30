# Rentisy E-Commerce Storefront & Customer Portal Architecture

## Standout & Unique Features (ميزات تنافسية واستثنائية)
1. **AI Shopping & Tech Advisor (مستشار المشتريات والتقنية الذكي)**:
   - Floating interactive AI widget that dynamically matches user needs, budget range (slider), and use-case presets (Accounting, Design, Noise-Cancelling, Mobile).
   - Generates natural Arabic advice reasons and live stock availability from ERP.
2. **Instant Official ERP Price Quotations (عروض أسعار رسمية فورية بضغطة زر)**:
   - 1-click generation of stamped formal Price Quotations (`Quotation` & `QuotationLine` in ERP) from Cart or single product.
   - Print & PDF layout with company registration, VAT, 15-day validity guarantee, and digital verification seal.
3. **Rentisy Rewards & Cashback Wallet (محفظة نقاط الولاء والكاش باك)**:
   - Real cashback points earned on every purchase (1 point per 10 ₪ spent).
   - 4 VIP Tiers: Bronze 🥉, Silver 🥈, Gold 🥇, Diamond VIP 💎 with increasing cashback percentage (1% to 5%).
   - Redeem points as instant monetary discounts directly at checkout (10 points = 1 ₪).
   - "Share & Earn" Viral Referral Program with personal referral links and WhatsApp/Facebook 1-click sharing.
4. **Live Social Proof Stream (إشعارات الشراء المباشرة)**:
   - Subtle floating toasts showing real-time anonymized purchases from various Palestinian cities (غزة، رام الله، الخليل، نابلس، بيت لحم، جنين).

4. **Real Google & Facebook OAuth 2.0 Integration (تسجيل وربط حقيقي عبر جوجل وفيسبوك)**:
   - Built on official `laravel/socialite` package.
   - Dual-mode support:
     1. **Login & Registration**: Instant 1-click registration/login with Google/Facebook, auto-generating linked customer profile and accounting party.
     2. **Account Linking & Disconnection in Customer Portal (`/customer/profile`)**: Logged-in users can link or unlink their real Google / Facebook accounts.
   - Configured in `config/services.php` and `.env` with `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `FACEBOOK_CLIENT_ID`, `FACEBOOK_CLIENT_SECRET`.

5. **Payment Transfer Screenshot Proof (الدفع عبر إشعار وسكرين شوت التحويل)**:
   - Supports Palestinian bank transfers (بنك فلسطين) with account and IBAN PS66PALS000000000000001892040 and digital wallets (جوال باي / بال باي).
   - Shoppers upload their transfer receipt screenshot directly during checkout.
   - Admin inspects the screenshot proof in the Admin Order details screen (`/orders/{id}`) with lightbox zoom, and confirms/verifies payment with 1 click.
6. **Delivery vs Pickup Mode & Dynamic Zone Rates (مناطق وأسعار التوصيل المخصصة والاستلام الشخصي)**:
   - Customers choose between Home Delivery (`delivery`) or In-Store/Warehouse Pickup (`pickup` - 0 ₪).
   - Custom delivery zones configured per Palestinian city (Gaza, Ramallah, Hebron, Nablus, Jerusalem, Jenin, etc.) with custom fees (₪) and estimated delivery times.
   - Admin manages zones, adds new ones, edits rates at `/delivery-zones`.
7. **Customer Suggested Delivery Zones (اقتراح مناطق توصيل جديدة)**:
   - Customers can propose up to 2 delivery zones if their area is unlisted.
   - Admin reviews suggestions at `/delivery-zones` tab, approves them, and sets their official delivery fee.
8. **100% MCP AI Full Control**:
   - `get_delivery_zones`, `create_delivery_zone`, `update_delivery_zone`, `delete_delivery_zone`
   - `get_suggested_delivery_zones`, `approve_suggested_delivery_zone`, `reject_suggested_delivery_zone`
   - `verify_order_payment_receipt`

## Architecture & Routes


## Key Features & Structure
1. **Storefront Landing Page (`/`)**:
   - Modern, high-converting hero carousel with CTAs.
   - Value propositions (Free delivery, Instant support, Secure checkout, Quality guarantee).
   - Dynamic Categories grid with product counts.
   - Flash Deals & Discount countdown timers.
   - Featured & Top Rated Products with Quick-View modal.
   - Testimonials & Trust badges.
2. **Store Internal Pages**:
   - `/shop`: Full product catalog with multi-filter sidebar (categories, price range, in-stock), live search, sorting (price-asc, price-desc, newest, rating, name), pagination.
   - `/shop/category/{id}`: Category-specific product catalog.
   - `/shop/product/{id}`: Product detail view with image gallery, stock availability, SKU, quantity picker, specs, reviews, and related items.
   - `/cart`: Interactive shopping cart with quantity modifications, coupon code calculation (`RENTISY10`), subtotal/shipping/total breakdown.
   - `/checkout`: Streamlined checkout with delivery address, phone, payment method (Cash on delivery, Card, Bank Transfer), order notes, and instant accounting posting.
   - `/wishlist`: Customer favorites page with 1-click move to cart.
3. **Customer Authentication & Social Logins**:
   - Standard email/password registration and login with RTL support.
   - **Google & Facebook Social Login**:
     - Fast 1-click login and sign up via Google and Facebook (`/auth/{provider}/redirect` & `/auth/{provider}/callback`).
     - Profile social linking: Customers can connect or disconnect their Google and Facebook accounts from their customer dashboard (`/customer/profile`).
4. **Admin Protection & Dedicated Login**:
   - `AdminMiddleware`: Strict isolation protecting `/dashboard` and all ERP routes (`/accounts`, `/invoices`, `/orders`, etc.). Any non-admin user is redirected to `/customer/dashboard`.
   - Dedicated Admin Login at `/admin/login` and `/admin/logout`.
5. **Admin Orders Management (`/orders`)**:
   - `/orders`: Real-time order listing, KPI stats (Total, Pending, Processing, Shipped, Delivered, Cancelled, Revenue ₪), search, and instant status switcher.
   - `/orders/{id}`: Detailed line items, printable sales invoice, customer shipping info, and ERP ledger link.
   - Inventory & ERP sync: Automatic stock restoration when an order is cancelled.
6. **MCP AI Assistant Integration for Orders & Analytics**:
   - `get_orders`: Filter and query store orders.
   - `get_order_details`: Detailed analysis of individual orders and ledger postings.
   - `update_order_status`: Automated order status transitions with inventory sync.
   - `analyze_orders_sales`: Comprehensive AI sales analytics (total revenue, average order value, top items, payment methods distribution, conversion trends).
7. **Customer Portal & Dashboard**:
   - `/customer/dashboard`: Overview with order metrics, active orders, total spent, saved items count, recent orders.
   - `/customer/orders`: Complete order history with status filters (pending, processing, shipped, delivered, cancelled).
   - `/customer/orders/{id}`: Order tracking timeline, invoice breakdown, and print-ready receipt / invoice.
   - `/customer/profile`: Personal information, shipping address, social connections (Google & Facebook connect/disconnect), password security.
   - `/customer/statement`: Live customer ledger statement from the accounting system (كشف الحساب المحاسبي - ERP).
8. **Accounting & Inventory Integration**:
   - Auto-Party creation: Customers are linked to an accounting `Party` (type: customer).
   - Sales Invoices: Every placed order generates an official `Invoice` (type: sale) with matching `InvoiceLine` items.
   - Stock Management: Orders automatically deduct stock from the warehouse (`StoreItem`).
   - Customer Accounting Statement: Orders and payments are reflected in the customer's financial statement.

## Demo Credentials
- **Admin User (ERP)**: `admin@admin.com` / `password` (Login: `/admin/login`)
- **Customer User (Store)**: `customer@store.com` / `password` (Login: `/login`)
