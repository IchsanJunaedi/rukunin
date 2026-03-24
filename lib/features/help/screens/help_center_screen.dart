import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(context, 'Tagihan & Pembayaran', [
            ('Bagaimana cara membayar tagihan?',
              'Buka menu Tagihan → pilih tagihan yang belum dibayar → tap "Upload Bukti Bayar" → upload foto bukti transfer. Admin akan memverifikasi dalam 1x24 jam.'),
            ('Tagihan saya sudah dibayar tapi masih "Pending"?',
              'Tagihan dalam status "Menunggu Verifikasi" artinya bukti bayar sudah diterima dan sedang ditinjau admin. Tunggu konfirmasi dari admin.'),
            ('Kapan tagihan diterbitkan?',
              'Tagihan diterbitkan otomatis setiap tanggal 1 oleh sistem. Kamu akan mendapat notifikasi saat tagihan baru tersedia.'),
            ('Saya tidak bisa upload bukti bayar?',
              'Pastikan ukuran foto tidak melebihi 5MB. Coba gunakan foto dari kamera langsung atau compress foto terlebih dahulu.'),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Registrasi & Akun', [
            ('Bagaimana cara bergabung ke komunitas?',
              'Minta kode komunitas ke admin RT/RW kamu. Lalu tap "Gabung sbg Warga" di halaman login, masukkan kode tersebut dan lengkapi data diri.'),
            ('Akun saya sedang "Menunggu Persetujuan"?',
              'Setelah mendaftar, admin perlu menyetujui akunmu. Hubungi admin RT/RW kamu agar segera diproses.'),
            ('Bagaimana cara mengganti password?',
              'Di halaman login, tap "Lupa password?" → masukkan email → cek email untuk link reset password.'),
            ('Data profil saya salah, bagaimana mengubahnya?',
              'Hubungi admin RT/RW untuk update data profil seperti nama, NIK, atau nomor unit.'),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Marketplace', [
            ('Bagaimana cara menjual barang?',
              'Buka menu Marketplace → tap tombol "+" → isi detail barang (judul, kategori, harga, stok, foto) → tap Simpan.'),
            ('Bagaimana menandai barang sudah terjual?',
              'Buka listing barang kamu → tap "Tandai Terjual". Barang akan hilang dari feed marketplace.'),
            ('Bagaimana cara menghubungi penjual?',
              'Buka detail listing → tap tombol "Hubungi Penjual via WA" untuk chat langsung di WhatsApp.'),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Lainnya', [
            ('Aplikasi lambat atau error?',
              'Coba tutup dan buka ulang aplikasi. Pastikan koneksi internet stabil. Jika masalah berlanjut, hubungi admin komunitasmu.'),
            ('Bagaimana cara melaporkan masalah?',
              'Hubungi admin RT/RW kamu langsung melalui WhatsApp atau secara langsung.'),
          ]),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Rukunin v1.0 — Dikembangkan untuk kemudahan warga',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<(String, String)> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final (question, answer) = entry.value;
              return Column(
                children: [
                  ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: Text(
                      question,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                    ),
                    iconColor: RukuninColors.brandGreen,
                    collapsedIconColor: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    children: [
                      Text(
                        answer,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
