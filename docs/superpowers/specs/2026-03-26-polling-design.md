# Polling & Voting Feature Design
**Date:** 2026-03-26
**Status:** Approved

---

## Overview

Fitur polling memungkinkan admin RT membuat pertanyaan Ya/Tidak untuk musyawarah warga. Warga vote langsung dari app, hasil tampil real-time setelah vote.

---

## Scope

- Admin: buat, lihat detail, tutup polling
- Resident: lihat polling aktif, vote, lihat hasil
- Format jawaban: Ya / Tidak saja
- Deadline: admin set tanggal berakhir + bisa tutup manual kapanpun
- Hasil: tampil real-time setelah warga vote

---

## Database Schema

### Tabel `polls`
```sql
id           uuid PRIMARY KEY DEFAULT gen_random_uuid()
community_id uuid NOT NULL REFERENCES communities(id)
created_by   uuid NOT NULL REFERENCES profiles(id)
title        text NOT NULL
description  text
starts_at    timestamptz NOT NULL
ends_at      timestamptz NOT NULL
status       text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed'))
created_at   timestamptz DEFAULT now()
```

### Tabel `poll_votes`
```sql
id          uuid PRIMARY KEY DEFAULT gen_random_uuid()
poll_id     uuid NOT NULL REFERENCES polls(id) ON DELETE CASCADE
resident_id uuid NOT NULL REFERENCES profiles(id)
vote        boolean NOT NULL   -- true = Ya, false = Tidak
voted_at    timestamptz DEFAULT now()
UNIQUE (poll_id, resident_id)  -- satu warga satu vote per poll
```

### RLS Policies
- `polls`: admin CRUD untuk community_id-nya; resident SELECT untuk community_id-nya
- `poll_votes`: resident INSERT/SELECT vote milik sendiri; admin SELECT semua votes di community-nya

---

## Feature Structure

```
lib/features/polling/
  models/
    poll_model.dart        — Poll + computed getters (isOpen, isExpired, yesCount, noCount, totalVotes, yesPercent)
    poll_vote_model.dart   — PollVote
  providers/
    poll_provider.dart     — pollsProvider (FutureProvider.autoDispose), PollNotifier (AsyncNotifier)
    poll_vote_provider.dart — pollVoteProvider.family(pollId), VoteNotifier (AsyncNotifier)
  screens/
    polls_admin_screen.dart      — list polling (admin)
    create_poll_screen.dart      — form buat polling
    poll_detail_admin_screen.dart — detail + hasil + tutup
    poll_vote_screen.dart        — vote screen (resident)
```

---

## Navigation

### Admin
- Entry: Dashboard aksi cepat → tap "Polling" → `/admin/polling`
- Routes (di luar ShellRoute):
  - `/admin/polling` → PollsAdminScreen
  - `/admin/polling/buat` → CreatePollScreen
  - `/admin/polling/:id` → PollDetailAdminScreen

### Resident
- Entry: Tab "Info RT" (AnnouncementsScreen) → section "Polling Aktif"
- Routes (di luar ShellRoute):
  - `/resident/polling/:id` → PollVoteScreen

---

## Screen Specs

### PollsAdminScreen
- AppBar: "Polling"
- List polls dikelompokkan: Aktif (open + belum expired) | Selesai (closed atau expired)
- Setiap card: judul, tanggal berakhir, jumlah vote, status badge
- FAB: tambah polling baru → CreatePollScreen
- Empty state jika belum ada polling

### CreatePollScreen
- Form fields: Judul*, Deskripsi (opsional), Tanggal Mulai*, Tanggal Berakhir*
- Validasi: ends_at harus setelah starts_at
- Submit → insert ke `polls` → kembali ke PollsAdminScreen

### PollDetailAdminScreen
- Tampilkan: judul, deskripsi, periode, status
- Hasil visual: progress bar Ya vs Tidak + persentase + jumlah vote
- List siapa saja sudah vote (nama, vote apa, waktu) — admin only
- Tombol "Tutup Polling" jika status masih open → update status ke 'closed'

### PollVoteScreen (Resident)
- Tampilkan: judul, deskripsi, periode
- Jika belum vote + poll open: tombol "Ya" dan "Tidak"
- Setelah vote / sudah pernah vote: tampil hasil (progress bar %) readonly
- Jika poll closed/expired: tampil hasil final + badge "Polling Selesai"

### AnnouncementsScreen (modifikasi)
- Tambah section "Polling Aktif" di atas list pengumuman
- Horizontal scroll card atau list vertical sederhana
- Jika tidak ada polling aktif: section tidak ditampilkan

---

## Data Flow

```
Admin buat poll
    → insert polls table
    → pollsProvider invalidated

Resident buka AnnouncementsScreen
    → pollsProvider fetch polls WHERE community_id + status='open' + ends_at > now()
    → tap poll → /resident/polling/:id

Resident vote
    → VoteNotifier.vote(pollId, voteValue)
    → insert poll_votes
    → pollVoteProvider.family(pollId) invalidated (trigger rebuild hasil)

Admin tutup polling
    → PollNotifier.closePoll(pollId)
    → UPDATE polls SET status='closed'
    → pollsProvider invalidated
```

---

## Model Computed Getters

```dart
// PollModel
bool get isOpen => status == 'open' && DateTime.now().isBefore(endsAt);
bool get isClosed => status == 'closed' || DateTime.now().isAfter(endsAt);
int get yesCount    // dari list PollVote
int get noCount
int get totalVotes
double get yesPercent
double get noPercent
```

---

## Migration File

`supabase/migrations/20260326_polling.sql`

---

## Out of Scope

- Polling multiple choice (hanya Ya/Tidak)
- Warga buat polling
- Notifikasi WA saat polling dibuat (bisa ditambah nanti via send-whatsapp)
- Panic button
