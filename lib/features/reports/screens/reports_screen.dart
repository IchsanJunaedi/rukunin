import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(reportProvider);
    final notifier = ref.read(reportProvider.notifier);

    final String monthName = DateFormat('MMMM', 'id_ID').format(DateTime(state.selectedYear, state.selectedMonth)).capitalize();

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
               if (state.isLoading) return;

               // Tampilkan Bottom Sheet Pilihan
               showModalBottomSheet(
                 context: context,
                 builder: (context) {
                   return SafeArea(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Padding(
                           padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                           child: Text('Pilih Aksi PDF', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18)),
                         ),
                         ListTile(
                           leading: Icon(Icons.share, color: RukuninColors.brandGreen),
                           title: const Text('Kirim / Bagikan (Share)'),
                           subtitle: const Text('Kirim ke WhatsApp, Telegram, dll'),
                           onTap: () {
                             Navigator.pop(context);
                             _processPdf(context, ref, state, monthName, isShare: true);
                           },
                         ),
                         ListTile(
                           leading: Icon(Icons.download, color: RukuninColors.brandGreen),
                           title: const Text('Download (Simpan)'),
                           subtitle: const Text('Simpan file PDF ke dalam HP / Komputer'),
                           onTap: () {
                             Navigator.pop(context);
                             _processPdf(context, ref, state, monthName, isShare: false);
                           },
                         ),
                       ],
                     )
                   );
                 }
               );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Mode Chips
          Container(
            color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Bulan Ini', ReportFilterMode.currentMonth, state.filterMode, notifier, isDark),
                  const SizedBox(width: 8),
                  _filterChip('3 Bulan', ReportFilterMode.threeMonths, state.filterMode, notifier, isDark),
                  const SizedBox(width: 8),
                  _filterChip('6 Bulan', ReportFilterMode.sixMonths, state.filterMode, notifier, isDark),
                  const SizedBox(width: 8),
                  _filterChip('Pilih Bulan', ReportFilterMode.custom, state.filterMode, notifier, isDark),
                ],
              ),
            ),
          ),

          // Month Selector (only shown in custom mode)
          if (state.filterMode == ReportFilterMode.custom)
            Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      if (state.selectedMonth == 1) {
                        notifier.changePeriod(12, state.selectedYear - 1);
                      } else {
                        notifier.changePeriod(state.selectedMonth - 1, state.selectedYear);
                      }
                    },
                  ),
                  Text(
                    '$monthName ${state.selectedYear}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      if (state.selectedMonth == 12) {
                        notifier.changePeriod(1, state.selectedYear + 1);
                      } else {
                        notifier.changePeriod(state.selectedMonth + 1, state.selectedYear);
                      }
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  '$monthName ${state.selectedYear}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
              ),
            ),

          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen))
                : state.error != null
                    ? Center(child: Text('Gagal memuat laporan: ${state.error}', style: const TextStyle(color: Colors.red)))
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadReportData(state.selectedMonth, state.selectedYear),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildSummaryCards(state.currentMonthReport, isDark),
                            const SizedBox(height: 24),
                            _buildChartSection(state.lastSixMonths, state.filterMode, isDark),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(dynamic report, bool isDark) {
    return Column(
      children: [
        // ── Saldo Bersih Card ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: RukuninColors.brandGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: RukuninShadow.brand,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saldo Bersih Bulan Ini',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CurrencyFormatter.format(report.netBalance),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.south_rounded, color: Colors.white, size: 11),
                              ),
                              const SizedBox(width: 6),
                              Text('Pemasukan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            CurrencyFormatter.format(report.totalIncome),
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.north_rounded, color: Colors.white, size: 11),
                              ),
                              const SizedBox(width: 6),
                              Text('Pengeluaran', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            CurrencyFormatter.format(report.totalExpense),
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Kolektibilitas Card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: RukuninColors.brandGreen.withValues(alpha: isDark ? 0.22 : 0.14),
              width: 1.0,
            ),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: RukuninColors.brandGreen.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(
                      value: report.totalExpected > 0
                          ? (report.totalIncome / report.totalExpected).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                      valueColor: const AlwaysStoppedAnimation<Color>(RukuninColors.brandGreen),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    '${report.collectionRate.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tingkat Kolektibilitas',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(report.totalIncome)} terkumpul dari target ${CurrencyFormatter.format(report.totalExpected)}',
                      style: GoogleFonts.poppins(
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, ReportFilterMode mode, ReportFilterMode current, ReportNotifier notifier, bool isDark) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => notifier.setFilterMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(List<dynamic> sixMonths, ReportFilterMode filterMode, bool isDark) {
    if (sixMonths.isEmpty) return const SizedBox();

    // Slice based on filter mode
    final barsToShow = filterMode == ReportFilterMode.threeMonths ? 3 : 6;
    final visibleMonths = sixMonths.length > barsToShow
        ? sixMonths.sublist(sixMonths.length - barsToShow)
        : sixMonths;

    // Reverse array agar bulan paling lama di kiri
    final reversed = List.from(visibleMonths);

    // Hitung maxY biar grafik proper
    double maxY = 100000;
    for(var rep in reversed) {
       if (rep.totalIncome > maxY) maxY = rep.totalIncome;
       if (rep.totalExpense > maxY) maxY = rep.totalExpense;
    }
    // Tambah 20% margin
    maxY = maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
          width: 0.5,
        ),
        boxShadow: RukuninShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             filterMode == ReportFilterMode.threeMonths ? 'Kas 3 Bulan Terakhir' : 'Kas 6 Bulan Terakhir',
             style: GoogleFonts.poppins(
               fontWeight: FontWeight.w800,
               fontSize: 16,
               color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
               letterSpacing: -0.3,
             ),
           ),
           const SizedBox(height: 24),
           SizedBox(
             height: 200,
             child: BarChart(
               BarChartData(
                 alignment: BarChartAlignment.spaceAround,
                 maxY: maxY,
                 barTouchData: BarTouchData(enabled: false),
                 titlesData: FlTitlesData(
                   show: true,
                   bottomTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       getTitlesWidget: (value, meta) {
                         if (value.toInt() >= reversed.length) return const Text('');
                         final report = reversed[value.toInt()];
                         final monthStr = DateFormat('MMM', 'id_ID').format(DateTime(report.year, report.month));
                         return Padding(padding: const EdgeInsets.only(top: 8), child: Text(monthStr, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary)));
                       },
                       reservedSize: 28,
                     ),
                   ),
                   leftTitles: AxisTitles(
                     sideTitles: SideTitles(showTitles: false), // Sembunyikan tulisan angka di kiri biar nggak sempit
                   ),
                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 ),
                 gridData: FlGridData(
                   show: true,
                   drawVerticalLine: false,
                   horizontalInterval: maxY / 4,
                   getDrawingHorizontalLine: (value) => FlLine(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2, strokeWidth: 1),
                 ),
                 borderData: FlBorderData(show: false),
                 barGroups: reversed.asMap().entries.map((e) {
                   final index = e.key;
                   final rep = e.value;
                   return BarChartGroupData(
                     x: index,
                     barRods: [
                       BarChartRodData(
                         toY: rep.totalIncome,
                         color: RukuninColors.success,
                         width: 8,
                         borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                       ),
                       BarChartRodData(
                         toY: rep.totalExpense,
                         color: RukuninColors.error,
                         width: 8,
                         borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                       ),
                     ],
                   );
                 }).toList(),
               ),
             ),
           ),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               _buildLegend(RukuninColors.success, 'Pemasukan', isDark),
               const SizedBox(width: 16),
               _buildLegend(RukuninColors.error, 'Pengeluaran', isDark),
             ],
           )
        ],
      )
    );
  }

  Widget _buildLegend(Color color, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _processPdf(BuildContext context, WidgetRef ref, ReportState state, String monthName, {required bool isShare}) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyiapkan laporan PDF...'), duration: Duration(seconds: 1)));

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await client.from('profiles').select('community_id').eq('id', client.auth.currentUser!.id).single();
      final community = await client.from('communities').select('name').eq('id', profile['community_id']).single();
      final communityName = community['name'] ?? 'Warga';

      final bytes = await PdfGenerator.generateReport(state.currentMonthReport, communityName);
      final fileName = 'Laporan_Keuangan_${monthName}_${state.selectedYear}';

      if (isShare) {
        // Tulis ke file sementara agar tombol Copy di dialog Share berfungsi
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/$fileName.pdf');
        await tempFile.writeAsBytes(bytes);

        if (context.mounted) {
           final xFile = XFile(tempFile.path, mimeType: 'application/pdf', name: '$fileName.pdf');
           await SharePlus.instance.share(ShareParams(files: [xFile], text: 'Berikut adalah laporan keuangan $communityName untuk bulan $monthName ${state.selectedYear}'));
        }
      } else {
        // Download menggunakar file_saver
        final result = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.pdf,
        );
        if (context.mounted && result.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF berhasil diunduh'), backgroundColor: RukuninColors.success));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: RukuninColors.error));
      }
    }
  }
}
