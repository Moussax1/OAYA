<div align="center">

# OAYA

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?logo=stripe)](https://stripe.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**🛍️ Full-stack mobile e-commerce app — cart, payments, and push notifications in one Flutter app 📱**

[Features](#features) · [Quick Start](#quick-start) · [Architecture](#architecture) · [Tests](#tests) · [Deployment](#deployment)

</div>

---

## Overview

OAYA is a complete mobile e-commerce application built with Flutter and Supabase. Users can browse products, manage a cart, pay via Stripe or cash on delivery, and receive real-time notifications — all from a polished, responsive mobile interface.

**Built to showcase:** A complete, production-ready mobile architecture with real payment integration, push notifications, and three layers of automated tests.

---

## Features

- 🔐 **Authentication** — sign up, login, forgot/reset password via Supabase Auth with JWT
- 🛒 **Cart** — add, update, remove items; cart synced to Supabase in real time
- 💳 **Payments** — Stripe card payments (test mode) + cash on delivery
- 📦 **Orders** — order history with status tracking and detailed receipts
- 🔔 **Notifications** — in-app SnackBars, AlertDialogs, Firebase push notifications, and email confirmations via Mailtrap
- ❤️ **Wishlist** — save products for later
- 🔍 **Search** — full-text product search
- 👤 **Profile** — manage account details and order history
- 🌐 **Web + Android** — runs on both platforms without crashes

---

## Quick Start

### Prerequisites

- Flutter 3.x (`flutter --version`)
- Supabase account — [supabase.com](https://supabase.com)
- Stripe account — [stripe.com](https://stripe.com) (test mode)
- Firebase project — [console.firebase.google.com](https://console.firebase.google.com)
- Mailtrap account — [mailtrap.io](https://mailtrap.io) (free tier)

### 1. Clone and install

```bash
git clone https://github.com/your-username/oaya_flutter.git
cd oaya_flutter
flutter pub get
```

### 2. Configure environment

```bash
cp .env.example assets/.env
```

Open `assets/.env` and fill in your credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### 3. Set up Supabase

Run the migration in your Supabase SQL Editor:

```bash
# Copy contents of supabase/migrations/001_initial_schema.sql
# Paste and run in: Supabase Dashboard → SQL Editor
```

Deploy edge functions:

```bash
supabase login
supabase link --project-ref your-project-ref
supabase functions deploy create-payment-intent
supabase functions deploy send-order-email
supabase functions deploy stripe-webhook
```

Add secrets to edge functions:

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set MAILTRAP_API_TOKEN=your-mailtrap-token
supabase secrets set MAILTRAP_SENDER_EMAIL=noreply@oaya.store
supabase secrets set MAILTRAP_INBOX_ID=your-inbox-id
supabase secrets set FCM_SERVER_KEY=your-fcm-server-key
```

Run database migrations:

```bash
supabase db push --linked --include-all --yes
```

The checkout flow now uses:
- `create-payment-intent` to initialize Stripe test payments
- `stripe-webhook` to mark orders paid/failed and trigger notifications
- `send-order-email` to send the receipt/confirmation email

### 4. Configure Firebase

1. Download `google-services.json` from your Firebase project
2. Place it at `android/app/google-services.json`
3. Add to `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

4. Add to `android/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### 5. Configure Supabase Auth redirect

In Supabase Dashboard → Authentication → URL Configuration:

- **Site URL:** `com.oaya.oaya_flutter://reset-password`
- **Redirect URLs:** `com.oaya.oaya_flutter://reset-password`

### 6. Run the app

```bash
# Android (device or emulator)
flutter run

# Web
flutter run -d chrome
```

---

## Architecture

```
oaya_flutter/
├── lib/
│   ├── constants/          # Theme, colors, spacing
│   ├── providers/          # Riverpod state management
│   ├── screens/
│   │   ├── checkout/       # Address, payment, success screens
│   │   ├── admin/          # Admin user management
│   │   └── *.dart          # Main app screens
│   ├── services/           # Supabase, Stripe, notifications, orders
│   ├── utils/              # Currency formatting, helpers
│   ├── widgets/            # Reusable UI components
│   ├── main.dart
│   └── router.dart
├── supabase/
│   ├── functions/
│   │   ├── create-payment-intent/
│   │   └── send-order-email/
│   └── migrations/
├── test/
│   ├── unit/               # Cart + price format tests
│   └── integration/        # Supabase API tests
├── integration_test/       # E2E user journey tests
└── android/app/
    └── google-services.json
```

### State management

All state is managed with **Riverpod**. Key providers:

| Provider | Type | Purpose |
|---|---|---|
| `authProvider` | `StateNotifierProvider` | Current user session |
| `cartProvider` | `StateNotifierProvider` | Cart items + totals |
| `ordersProvider` | `FutureProvider` | Order history |
| `productsProvider` | `FutureProvider` | Product catalog |
| `notificationCountProvider` | `FutureProvider` | Unread notifications |

### Database schema

| Table | Description |
|---|---|
| `profiles` | User profiles + FCM token |
| `products` | Product catalog |
| `cart_items` | Per-user cart (RLS enforced) |
| `orders` | Order records with status |
| `order_items` | Line items per order |
| `notifications` | In-app notification log |

All tables have Row Level Security — users can only access their own data.

---

## Tests

### Run all tests

```bash
# Unit tests
flutter test test/unit/

# Integration tests (requires .env with real Supabase credentials)
flutter test test/integration/

# E2E test (requires connected device or emulator)
flutter test integration_test/e2e_test.dart
```

### Test coverage

| Suite | File | Tests |
|---|---|---|
| Unit | `test/unit/cart_test.dart` | Cart total, item count, shipping logic |
| Unit | `test/unit/price_format_test.dart` | TND currency formatting |
| Integration | `test/integration/cart_api_test.dart` | Add, update, remove cart items via Supabase |
| Integration | `test/integration/order_api_test.dart` | Create and fetch orders via Supabase |
| E2E | `integration_test/e2e_test.dart` | Full user journey: login → cart → checkout → confirmation |

---

## Payment

Stripe is integrated in **test mode**. No real transactions occur.

**Test card credentials:**

| Field | Value |
|---|---|
| Card number | `4242 4242 4242 4242` |
| Expiry | `12/26` |
| CVC | `123` |
| ZIP | Any 5 digits |

Payment flow:
1. User selects Stripe or cash on delivery
2. Stripe: Flutter calls Supabase edge function `create-payment-intent` → receives `clientSecret` → presents Stripe payment sheet
3. On success: order created in database, cart cleared, confirmation email sent via `send-order-email` edge function

---

## Notifications

Three notification channels are implemented:

| Type | Trigger | Implementation |
|---|---|---|
| In-app SnackBar | Item added to cart | `NotificationService.showSnackBar()` |
| In-app AlertDialog | Payment success/failure | `NotificationService.showResultDialog()` |
| Push (FCM) | Order status change | Firebase Cloud Messaging |
| Email | After payment | Supabase edge function → Mailtrap SMTP |

---

## Deployment

### Backend (Supabase)

Supabase handles all backend infrastructure — no separate server needed. Edge functions run on Deno.

```bash
# Deploy both edge functions
supabase functions deploy create-payment-intent
supabase functions deploy send-order-email
```

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Web

```bash
flutter build web --release
# Output: build/web/
```

---

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `SUPABASE_URL` | ✅ | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous key |
| `STRIPE_PUBLISHABLE_KEY` | ✅ | Stripe publishable key (pk_test_...) |
| `STRIPE_SECRET_KEY` | ✅ | Stripe secret key — edge function only |
| `MAILTRAP_USERNAME` | ✅ | Mailtrap SMTP username |
| `MAILTRAP_PASSWORD` | ✅ | Mailtrap SMTP password |

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x / Dart |
| State management | Riverpod |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Payments | Stripe (flutter_stripe, test mode) |
| Push notifications | Firebase Cloud Messaging |
| Email | Mailtrap (SMTP simulation) |
| Navigation | go_router |
| HTTP | Supabase client + Dio |

---

## License

MIT — see [LICENSE](LICENSE) for details.
