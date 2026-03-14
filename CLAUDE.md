# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚠️ ATURAN WAJIB — BACA DULU SEBELUM APAPUN

**Ini adalah project mature yang sedang dalam pengembangan aktif. Berlaku aturan ketat berikut:**

1. **DILARANG refactoring tanpa persetujuan eksplisit.** Jangan ubah struktur, nama variabel, pola coding, atau arsitektur yang sudah ada — meskipun kamu merasa ada cara yang lebih baik.
2. **Selalu ikuti pola coding yang sudah ada.** Riverpod provider pattern, Supabase query style, model `fromMap/toMap` — semua harus konsisten dengan yang sudah ada di codebase.
3. **WAJIB baca `ARCHITECTURE.md` dan `PROGRESS.md`** sebelum mengerjakan task apapun. Ini memastikan kamu tidak mengulang kerja atau bertentangan dengan keputusan arsitektur yang sudah dibuat.
4. **Jangan ubah logic yang sudah berjalan** tanpa konfirmasi. Kalau menemukan bug, laporkan dulu sebelum memperbaiki.
5. **Jangan membuat file baru** jika sudah ada file yang relevan — extend yang ada.

---

## Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK (release)
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

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

# Deploy Edge Function
supabase functions deploy <function-name>
```

## Environment Setup

File `.env` wajib ada di root project:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

File `.env` sudah didaftarkan sebagai Flutter asset di `pubspec.yaml` dan dimuat via `flutter_dotenv` di `main.dart`.

---

## Arsitektur Singkat

Untuk detail lengkap → baca `ARCHITECTURE.md`.

### State Management — Riverpod
- Semua provider ada di `lib/features/<feature>/providers/`
- **SATU entry point Supabase:** `supabaseClientProvider` di `lib/core/supabase/supabase_client.dart` — semua provider wajib watch/read ini
- `FutureProvider.autoDispose` untuk fetch data, `AsyncNotifier` untuk mutations, `Notifier` untuk state kompleks

### Navigation — GoRouter
- Semua route di `lib/app/router.dart`
- Dua ShellRoute: `AdminShell` (6 tab) dan `ResidentShell` (5 tab)
- Route full-screen tanpa bottom nav → deklarasikan di luar ShellRoute

### Feature Structure
```
lib/features/<feature>/
  models/      ← plain Dart class, fromMap/toMap, BUKAN Freezed
  providers/   ← Riverpod providers
  screens/     ← Flutter widgets
```

### Design System
- Token warna & tipografi: `lib/app/theme.dart` (`AppColors`, `AppTextStyles`)
- Primary: `#FFC107` (kuning), Surface: `#0D0D0D` (hitam)
- Font: Playfair Display (headline) + Plus Jakarta Sans (body)

### Database
- Migrations: `supabase/migrations/` — dijalankan manual via Supabase SQL Editor
- RLS policies: `supabase/migrations/20260311_rls_policies.sql`
- AI menggunakan **Groq API** (`llama-3.3-70b-versatile`), bukan Anthropic

### Dual User Roles
- **Admin** `/admin/*` — kelola warga, tagihan, kas, laporan, surat, AI
- **Resident** `/resident/*` — lihat tagihan sendiri, marketplace, pengumuman
- Beberapa screen di-share (AnnouncementsScreen, MarketplaceScreen)

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (90-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk vitest run          # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%)
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->