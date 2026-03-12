# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Rukunin** is a Flutter app for digital RT/RW (Indonesian neighborhood association) management. It targets a single RW with up to 300 units. Stack: Flutter + Supabase (Postgres + Edge Functions) + Riverpod.

## Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK (release)
flutter build apk --release

# Code generation (Freezed + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs

# Lint
flutter analyze

# Tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart
```

## Environment Setup

The app requires a `.env` file in the project root with:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

The `.env` file is declared as a Flutter asset in `pubspec.yaml` and loaded via `flutter_dotenv` at startup.

## Architecture

### State Management — Riverpod

All state lives in providers under `lib/features/<feature>/providers/`. The pattern is:
- `FutureProvider` / `FutureProvider.family` for async reads (Supabase queries)
- `AsyncNotifier` / `AsyncNotifierProvider` for write operations (create/update/delete)
- `supabaseClientProvider` (in `lib/core/supabase/supabase_client.dart`) is the single Supabase entry point — every provider watches or reads it

### Navigation — GoRouter

Routes are defined in `lib/app/router.dart` via `routerProvider`. There are two `ShellRoute`s:
- **Admin shell** (`/admin/*`) — wrapped by `AdminShell` with 6-tab bottom nav
- **Resident shell** (`/resident/*`) — wrapped by `ResidentShell` with 5-tab bottom nav

Auth redirect is handled in the router's `redirect` callback: checks `Supabase.instance.client.auth.currentSession` and reads the `role` field from the `profiles` table (`admin` → `/admin`, `resident` → `/resident`).

Routes that should not inherit the shell's bottom nav (e.g., full-screen detail pages) are declared as top-level `GoRoute`s outside the `ShellRoute`.

### Feature Structure

Each feature follows:
```
lib/features/<feature>/
  models/      # Plain Dart classes with fromMap/fromJson constructors
  providers/   # Riverpod providers (data fetching & mutations)
  screens/     # Flutter widgets
```

Models are hand-written (no Freezed codegen used yet, despite the dependency being present).

### Supabase Schema (key tables)

| Table | Purpose |
|---|---|
| `communities` | One row per RW |
| `profiles` | All users (admin + residents), `role` field: `admin`/`resident` |
| `billing_types` | Jenis iuran (IPL, keamanan, etc.) scoped to a community |
| `invoices` | Per-resident per-month billing; status: `pending`/`paid`/`overdue` |
| `payments` | Payment records linked to invoices |
| `expenses` | Community cash outflows with fixed categories |
| `announcements` | Admin → resident broadcasts |
| `marketplace_listings` | Peer-to-peer listings between residents |
| `ai_logs` | Logs of AI assistant queries |

RLS policies are in `supabase/migrations/20260311_rls_policies.sql`. Migrations are run manually via the Supabase SQL Editor.

### Edge Functions (Deno / TypeScript)

Located in `supabase/functions/`:
- `ai-assistant` — Uses **Groq API** (`llama-3.3-70b-versatile`) to answer financial questions about the community; logs to `ai_logs`
- `auto-generate-invoices` — Bulk-creates invoice rows for all active residents
- `send-reminders` — WhatsApp reminder blasts for overdue invoices
- `send-whatsapp` — WhatsApp message delivery helper
- `generate-letter` — PDF letter generation

Deploy edge functions with: `supabase functions deploy <function-name>`

### Design System

Design tokens are in `lib/app/theme.dart`:
- `AppColors` — color constants (primary: `#FFC107` yellow, surface: `#0D0D0D` black)
- `AppTextStyles` — two font families: **Playfair Display** (display/headline) and **Plus Jakarta Sans** (body/labels)
- Theme is built with Material 3 (`useMaterial3: true`)

### Dual User Roles

The app has two completely separate UIs sharing some screens:
- **Admin** — full management (residents, billing, expenses, reports, letters, AI assistant, announcements, settings)
- **Resident portal** — limited view (home summary, own invoices, announcements, marketplace)

`AnnouncementsScreen` and `MarketplaceScreen` are reused across both roles via separate routes.
