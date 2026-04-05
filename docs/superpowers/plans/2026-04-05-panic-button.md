# Panic Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambah tombol S.O.S Darurat di dashboard admin yang mengirim pesan WhatsApp ke satpam via Fonnte ketika admin menekan dan memilih jenis darurat.

**Architecture:** Admin tekan `_PanicActionBtn` (merah) di Quick Actions section → `showModalBottomSheet` muncul pilihan 4 jenis darurat → setelah konfirmasi, `PanicNotifier.sendAlert()` ambil `security_phone` dari tabel `communities` lalu call Edge Function `send-whatsapp` yang sudah ada. Tidak ada backend baru — reuse existing Edge Function.

**Tech Stack:** Flutter/Dart, flutter_riverpod ^3, supabase_flutter, existing `send-whatsapp` Deno Edge Function, Fonnte WhatsApp API.

---

## File Map

| Action | Path |
|--------|------|
| Create | `supabase/migrations/20260405_add_security_phone.sql` |
| Modify | `lib/features/community/screens/community_settings_screen.dart` |
| Create | `lib/features/dashboard/providers/panic_provider.dart` |
| Modify | `lib/features/dashboard/screens/admin_dashboard_screen.dart` |

---

## Task 1: DB Migration — Tambah Kolom `security_phone`

**Files:**
- Create: `supabase/migrations/20260405_add_security_phone.sql`

- [ ] **Step 1: Buat file migration**

```sql
-- supabase/migrations/20260405_add_security_phone.sql
ALTER TABLE communities ADD COLUMN IF NOT EXISTS security_phone text;

COMMENT ON COLUMN communities.security_phone IS 'Nomor WhatsApp satpam/security, diformat 08xxx atau +62xxx';
```

- [ ] **Step 2: Jalankan di Supabase SQL Editor**

Buka Supabase Dashboard → SQL Editor → paste isi file → Run.

Expected: Query berhasil tanpa error. Bisa verify dengan:
```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'communities' AND column_name = 'security_phone';
```
Expected output: 1 row dengan `column_name = security_phone`, `data_type = text`.

- [ ] **Step 3: Commit**

```bash
rtk git add supabase/migrations/20260405_add_security_phone.sql
rtk git commit -m "feat(db): add security_phone column to communities"
```

---

## Task 2: Community Settings — Tambah Field Nomor WA Satpam

**Files:**
- Modify: `lib/features/community/screens/community_settings_screen.dart`

Kita perlu: (a) tambah `_securityPhoneCtrl`, (b) load nilainya di `_loadCommunity()`, (c) save nilainya di `_save()`, (d) tambah field UI di bagian "Informasi Dasar".

- [ ] **Step 1: Tambah controller di state class**

Di `_CommunitySettingsScreenState`, tepat setelah `final _rwCtrl = TextEditingController();` (baris 23), tambahkan:

```dart
final _securityPhoneCtrl = TextEditingController();
```

- [ ] **Step 2: Dispose controller**

Tambah `dispose()` method setelah `initState()` (sebelum `_loadCommunity()`). Cek apakah sudah ada `dispose()`. Kalau belum ada:

```dart
@override
void dispose() {
  _nameCtrl.dispose();
  _rwCtrl.dispose();
  _securityPhoneCtrl.dispose();
  super.dispose();
}
```

Kalau sudah ada `dispose()`, tambahkan saja `_securityPhoneCtrl.dispose();` di dalamnya sebelum `super.dispose()`.

- [ ] **Step 3: Load `security_phone` dari DB**

Di `_loadCommunity()`, tepat setelah `_rtCount = (c['rt_count'] as int?) ?? 3;` (dalam blok `if (c != null)`), tambahkan:

```dart
_securityPhoneCtrl.text = c['security_phone'] ?? '';
```

- [ ] **Step 4: Save `security_phone` ke DB**

Di `_save()`, dalam `client.from('communities').update({...})`, tambahkan key baru:

```dart
'security_phone': _securityPhoneCtrl.text.trim().isEmpty
    ? null
    : _securityPhoneCtrl.text.trim(),
```

Jadi blok update menjadi:
```dart
await client.from('communities').update({
  'name': _nameCtrl.text.trim(),
  'rw_number': _rwCtrl.text.trim(),
  'rt_count': _rtCount,
  'security_phone': _securityPhoneCtrl.text.trim().isEmpty
      ? null
      : _securityPhoneCtrl.text.trim(),
  if (_provinsi != null) 'province': _provinsi!.name,
  if (_kabupaten != null) 'kabupaten': _kabupaten!.name,
  if (_kecamatan != null) 'kecamatan': _kecamatan!.name,
  if (_kelurahan != null) 'kelurahan': _kelurahan!.name,
}).eq('id', _communityId!);
```

- [ ] **Step 5: Tambah UI field di form**

Di `build()`, dalam `_card(context, [...])` untuk section "Informasi Dasar", tambahkan `_divider()` dan field baru di akhir list (setelah `_rtCountRow(context)`):

```dart
_divider(),
_textField(
  context: context,
  ctrl: _securityPhoneCtrl,
  label: 'Nomor WA Satpam',
  icon: Icons.security_rounded,
  keyboardType: TextInputType.phone,
),
```

- [ ] **Step 6: Verifikasi manual**

```bash
flutter run
```

Buka Settings → Profil RW → pastikan field "Nomor WA Satpam" muncul, bisa diisi, dan tersimpan (setelah tap Simpan, buka screen lagi, nilai masih ada).

- [ ] **Step 7: Commit**

```bash
rtk git add lib/features/community/screens/community_settings_screen.dart
rtk git commit -m "feat(settings): add security_phone field to community settings"
```

---

## Task 3: Panic Provider

**Files:**
- Create: `lib/features/dashboard/providers/panic_provider.dart`

- [ ] **Step 1: Buat file provider**

```dart
// lib/features/dashboard/providers/panic_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';

enum PanicType { kemalingan, kebakaran, medis, lainnya }

extension PanicTypeX on PanicType {
  String get label {
    switch (this) {
      case PanicType.kemalingan: return 'Kemalingan';
      case PanicType.kebakaran:  return 'Kebakaran';
      case PanicType.medis:      return 'Darurat Medis';
      case PanicType.lainnya:    return 'Lainnya';
    }
  }

  String buildMessage(String communityName) {
    switch (this) {
      case PanicType.kemalingan:
        return '🚨 DARURAT KEMALINGAN!\nAda indikasi pencurian di $communityName. Mohon segera cek keamanan lingkungan.\n\n_Dikirim via Rukunin_';
      case PanicType.kebakaran:
        return '🔥 DARURAT KEBAKARAN!\nAda kebakaran di $communityName. Mohon segera cek dan bantu evakuasi.\n\n_Dikirim via Rukunin_';
      case PanicType.medis:
        return '🏥 DARURAT MEDIS!\nAda kondisi darurat medis di $communityName. Mohon segera cek dan bantu.\n\n_Dikirim via Rukunin_';
      case PanicType.lainnya:
        return '🚨 KONDISI DARURAT!\n$communityName membutuhkan bantuan segera. Mohon segera cek.\n\n_Dikirim via Rukunin_';
    }
  }
}

class PanicNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendAlert(PanicType type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final profile = await client
          .from('profiles')
          .select('community_id, communities(name, security_phone)')
          .eq('id', userId)
          .maybeSingle();

      final communityId = profile?['community_id'] as String?;
      if (communityId == null) throw Exception('Community tidak ditemukan');

      final community = profile?['communities'] as Map?;
      final securityPhone = community?['security_phone'] as String?;
      if (securityPhone == null || securityPhone.isEmpty) {
        throw Exception('Nomor WA satpam belum diatur. Buka Pengaturan → Profil RW untuk mengisinya.');
      }

      final communityName = community?['name'] as String? ?? 'Perumahan';

      await client.functions.invoke(
        'send-whatsapp',
        body: {
          'target': securityPhone,
          'message': type.buildMessage(communityName),
        },
      );
    });
  }
}

final panicProvider = AsyncNotifierProvider<PanicNotifier, void>(PanicNotifier.new);
```

- [ ] **Step 2: Verifikasi compile**

```bash
flutter analyze lib/features/dashboard/providers/panic_provider.dart
```

Expected: No errors. (Warning tentang unused imports boleh diabaikan selama tidak ada error.)

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/dashboard/providers/panic_provider.dart
rtk git commit -m "feat(panic): add PanicNotifier and PanicType"
```

---

## Task 4: Panic Button Widget di Dashboard

**Files:**
- Modify: `lib/features/dashboard/screens/admin_dashboard_screen.dart`

- [ ] **Step 1: Tambah import panic_provider**

Di bagian atas `admin_dashboard_screen.dart`, tambahkan import setelah import terakhir:

```dart
import '../providers/panic_provider.dart';
```

- [ ] **Step 2: Tambah `_PanicActionBtn` widget**

Tambahkan widget berikut di akhir file, setelah `_ServiceCard`:

```dart
// ── Panic Action Button ───────────────────────────────────────────────────────

class _PanicActionBtn extends ConsumerStatefulWidget {
  const _PanicActionBtn();

  @override
  ConsumerState<_PanicActionBtn> createState() => _PanicActionBtnState();
}

class _PanicActionBtnState extends ConsumerState<_PanicActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward();
    HapticFeedback.heavyImpact();
    _showPanicSheet();
  }

  Future<void> _showPanicSheet() async {
    final type = await showModalBottomSheet<PanicType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PanicBottomSheet(),
    );
    if (type == null || !mounted) return;

    // Konfirmasi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kirim Alert Darurat?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Pesan "${type.label}" akan dikirim ke WhatsApp satpam sekarang.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Kirim Sekarang',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(panicProvider.notifier).sendAlert(type);

    if (!mounted) return;
    final state = ref.read(panicProvider);
    if (state.hasError) {
      showToast(context, 'Gagal: ${state.error}');
    } else {
      showToast(context, '✅ Alert "${type.label}" terkirim ke satpam!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panicState = ref.watch(panicProvider);
    final isLoading = panicState.isLoading;

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _onTap(),
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.40 : 0.30),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFFEF4444)),
                )
              else
                const Icon(Icons.emergency_rounded,
                    color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 10),
              Text(
                isLoading ? 'Mengirim...' : '🚨  Darurat — Hubungi Satpam',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Panic Bottom Sheet ────────────────────────────────────────────────────────

class _PanicBottomSheet extends StatelessWidget {
  const _PanicBottomSheet();

  static const _options = [
    (PanicType.kemalingan, Icons.security_rounded,     'Kemalingan',    '🔓'),
    (PanicType.kebakaran,  Icons.local_fire_department, 'Kebakaran',     '🔥'),
    (PanicType.medis,      Icons.medical_services_outlined, 'Darurat Medis', '🏥'),
    (PanicType.lainnya,    Icons.warning_amber_rounded, 'Lainnya',       '⚠️'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih Jenis Darurat',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pesan WhatsApp akan dikirim ke satpam',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? RukuninColors.darkTextTertiary
                    : RukuninColors.lightTextTertiary),
          ),
          const SizedBox(height: 20),
          ..._options.map((opt) => _OptionTile(
                type: opt.$1,
                icon: opt.$2,
                label: opt.$3,
                emoji: opt.$4,
              )),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final PanicType type;
  final IconData icon;
  final String label;
  final String emoji;

  const _OptionTile({
    required this.type,
    required this.icon,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.pop(context, type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFEF4444).withValues(alpha: 0.08)
              : const Color(0xFFEF4444).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? RukuninColors.darkTextPrimary
                        : RukuninColors.lightTextPrimary),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? RukuninColors.darkTextTertiary
                    : RukuninColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Pasang panic button di `_buildContent`**

Di `_buildContent()`, tepat setelah:
```dart
_QuickActions(),
const SizedBox(height: 24),
```

Tambahkan:
```dart
const _PanicActionBtn(),
const SizedBox(height: 24),
```

Sehingga urutan menjadi:
```dart
SectionHeader(title: 'Aksi Cepat'),
const SizedBox(height: 12),
_QuickActions(),
const SizedBox(height: 12),
const _PanicActionBtn(),
const SizedBox(height: 24),
SectionHeader(title: 'Layanan Warga'),
```

- [ ] **Step 4: Verifikasi compile**

```bash
flutter analyze lib/features/dashboard/screens/admin_dashboard_screen.dart
```

Expected: No errors.

- [ ] **Step 5: Verifikasi manual di device**

```bash
flutter run
```

Checklist:
- [ ] Tombol merah "🚨 Darurat — Hubungi Satpam" muncul di dashboard admin di bawah Quick Actions
- [ ] Tap → BottomSheet muncul dengan 4 pilihan (Kemalingan, Kebakaran, Darurat Medis, Lainnya)
- [ ] Pilih salah satu → Dialog konfirmasi muncul
- [ ] Tap "Kirim Sekarang" → loading state muncul di tombol
- [ ] Jika `security_phone` belum diset → toast error "Nomor WA satpam belum diatur..." muncul
- [ ] Jika `security_phone` sudah diset → toast sukses muncul, WA terkirim

- [ ] **Step 6: Commit**

```bash
rtk git add lib/features/dashboard/screens/admin_dashboard_screen.dart
rtk git commit -m "feat(dashboard): add panic button with emergency type selection"
```

---

## Scope Check

| Requirement dari spec | Task |
|----------------------|------|
| Admin pilih jenis darurat (Kemalingan/Kebakaran/Medis/Lainnya) | Task 4 — `_PanicBottomSheet` |
| Konfirmasi sebelum kirim | Task 4 — `AlertDialog` di `_showPanicSheet()` |
| WA ke `communities.security_phone` via Fonnte | Task 3 — `PanicNotifier.sendAlert()` |
| Reuse edge function `send-whatsapp` | Task 3 — `client.functions.invoke('send-whatsapp', ...)` |
| Widget merah terpisah dari `_items` list | Task 4 — `_PanicActionBtn` widget terpisah |
| DB: `ALTER TABLE communities ADD COLUMN security_phone` | Task 1 |
| Settings: field input nomor satpam | Task 2 |

Semua requirement tercakup.
