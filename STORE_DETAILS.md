# Rentisy E-Commerce Storefront & Customer Portal Architecture

## Overview
The E-commerce Storefront is a full-featured customer-facing online store integrated directly into the Rentisy Accounting ERP system.

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
4. **Customer Portal & Dashboard**:
   - `/customer/dashboard`: Overview with order metrics, active orders, total spent, saved items count, recent orders.
   - `/customer/orders`: Complete order history with status filters (pending, processing, shipped, delivered, cancelled).
   - `/customer/orders/{id}`: Order tracking timeline, invoice breakdown, and print-ready receipt / invoice.
   - `/customer/profile`: Personal information, shipping address, social connections (Google & Facebook connect/disconnect), password security.
   - `/customer/statement`: Live customer ledger statement from the accounting system (كشف الحساب المحاسبي - ERP).
5. **Accounting & Inventory Integration**:
   - Auto-Party creation: Customers are linked to an accounting `Party` (type: customer).
   - Sales Invoices: Every placed order generates an official `Invoice` (type: sale) with matching `InvoiceLine` items.
   - Stock Management: Orders automatically deduct stock from the warehouse (`StoreItem`).
   - Customer Accounting Statement: Orders and payments are reflected in the customer's financial statement.

## Demo Credentials
- **Customer User**: `customer@store.com` / `password` (Name: `م. محمود علي`)
- **Admin User**: `admin@admin.com` / `password`
