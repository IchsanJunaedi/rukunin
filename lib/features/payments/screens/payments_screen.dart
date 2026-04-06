import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/components.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final adminPaymentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({int month, int year})>(
  (ref, filter) async {
    final client = ref.watch(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    final communityId = profile?['community_id'];
    if (communityId == null) return [];

    final startDate = DateTime(filter.year, filter.month);
    final endDate = DateTime(filter.year, filter.month + 1);

    final data = await client
        .from('payments')
        .select(
          'id, amount, method, paid_at, '
          'invoices(month, year, billing_types(name), profiles:resident_id(full_name, unit_number))',
        )
        .eq('community_id', communityId)
        .gte('paid_at', startDate.toIso8601String())
        .lt('paid_at', endDate.toIso8601String())
        .order('paid_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  },
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = (month: _selectedMonth, year: _selectedYear);
    final paymentsAsync = ref.watch(adminPaymentsProvider(filter));
    final currencyFmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final months = List.generate(12, (i) => i + 1);
    final years = [DateTime.now().year - 1, DateTime.now().year];

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        actions: [
          DropdownButton<int>(
            value: _selectedMonth,
            underline: const SizedBox(),
            dropdownColor:
                isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            style: RukuninFonts.pjs(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? RukuninColors.darkTextPrimary
                  : RukuninColors.lightTextPrimary,
            ),
            items: months
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                          DateFormat('MMM', 'id_ID').format(DateTime(0, m))),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedMonth = v!),
          ),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            dropdownColor:
                isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            style: RukuninFonts.pjs(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? RukuninColors.darkTextPrimary
                  : RukuninColors.lightTextPrimary,
            ),
            items: years
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text('$y'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedYear = v!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat data',
            description: e.toString(),
            ctaLabel: 'Coba lagi',
            onCta: () => ref.invalidate(adminPaymentsProvider(filter)),
          ),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            final monthName = DateFormat('MMMM yyyy', 'id_ID')
                .format(DateTime(_selectedYear, _selectedMonth));
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pembayaran',
              description:
                  'Tidak ada pembayaran terkonfirmasi pada $monthName.',
            );
          }

          final total = payments.fold(
            0.0,
            (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
          );

          return RefreshIndicator(
            color: RukuninColors.brandGreen,
            onRefresh: () async =>
                ref.invalidate(adminPaymentsProvider(filter)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // ── Summary card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: RukuninColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL TERKUMPUL',
                            style: RukuninFonts.pjs(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFmt.format(total),
                            style: RukuninFonts.pjs(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${payments.length} transaksi',
                          style: RukuninFonts.pjs(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── List ───────────────────────────────────────────────────
                ...payments.map((p) => _PaymentItem(
                      payment: p,
                      fmt: currencyFmt,
                      isDark: isDark,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Payment Item ─────────────────────────────────────────────────────────────

class _PaymentItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  final NumberFormat fmt;
  final bool isDark;

  const _PaymentItem({
    required this.payment,
    required this.fmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final invoice = payment['invoices'] as Map<String, dynamic>?;
    final profile = invoice?['profiles'] as Map<String, dynamic>?;
    final billingType = invoice?['billing_types'] as Map<String, dynamic>?;

    final name = (profile?['full_name'] as String?) ?? 'Warga';
    final unit = (profile?['unit_number'] as String?) ?? '-';
    final billingName = (billingType?['name'] as String?) ?? 'Iuran';
    final month = invoice?['month'] as int? ?? 0;
    final year = invoice?['year'] as int? ?? 0;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;

    final paidAt = payment['paid_at'] != null
        ? DateTime.tryParse(payment['paid_at'].toString())
        : null;
    final dateStr = paidAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(paidAt.toLocal())
        : '-';
    final monthName = month > 0
        ? DateFormat('MMM yyyy', 'id_ID').format(DateTime(year, month))
        : '-';

    final words = name.trim().split(' ');
    final initials = words
        .take(2)
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? null : RukuninShadow.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: RukuninColors.brandGreen.withValues(alpha: 0.15),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: RukuninFonts.pjs(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: RukuninColors.brandGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: RukuninFonts.pjs(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark
                        ? RukuninColors.darkTextPrimary
                        : RukuninColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Unit $unit · $billingName · $monthName',
                  style: RukuninFonts.pjs(
                    fontSize: 12,
                    color: isDark
                        ? RukuninColors.darkTextTertiary
                        : RukuninColors.lightTextTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateStr,
                  style: RukuninFonts.pjs(
                    fontSize: 11,
                    color: isDark
                        ? RukuninColors.darkTextTertiary
                        : RukuninColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fmt.format(amount),
            style: RukuninFonts.pjs(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: RukuninColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
