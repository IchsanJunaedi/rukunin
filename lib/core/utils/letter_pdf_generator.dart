import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../features/letters/providers/letter_provider.dart';

class LetterPdfGenerator {
  // ──────────────────────────────────────────────
  // Template isi surat per jenis. {placeholders}
  // ──────────────────────────────────────────────
  static String getTemplate({
    required String letterType,
    required String residentName,
    required String residentNik,
    required String residentAge,
    required String residentGender,
    required String residentAddress,
    required String rtNumber,
    required String rwNumber,
    required String village,
    required String district,
    required String city,
    required String? purpose,
  }) {
    final purposeText = purpose?.isNotEmpty == true
        ? purpose!
        : _defaultPurpose(letterType);

    switch (letterType) {
      case 'ktp_kk':
        return 'Nama tersebut di atas benar-benar merupakan warga yang berdomisili di wilayah RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city. Surat keterangan ini diberikan kepada yang bersangkutan dengan NIK $residentNik guna keperluan pengurusan Kartu Tanda Penduduk (KTP) dan/atau Kartu Keluarga (KK) pada instansi yang berwenang.';

      case 'domisili':
        return 'Nama tersebut di atas benar-benar merupakan penduduk kami yang berdomisili dan bertempat tinggal di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city. Surat Keterangan Domisili ini diberikan kepada yang bersangkutan guna keperluan $purposeText.';

      case 'sktm':
        return 'Nama tersebut di atas benar-benar merupakan warga tidak mampu yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city. Berdasarkan kenyataan yang ada, yang bersangkutan termasuk dalam kategori keluarga kurang mampu sehingga layak mendapatkan bantuan/keringanan. Surat keterangan ini dibuat untuk keperluan $purposeText.';

      case 'skck':
        return 'Nama tersebut di atas benar-benar warga yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city dan sejauh pengetahuan kami tidak pernah melakukan tindakan yang melanggar norma/hukum yang berlaku. Surat ini dibuat sebagai pengantar untuk keperluan $purposeText kepada Kepolisian Sektor setempat.';

      case 'kematian':
        return 'Berdasarkan laporan yang telah kami terima, menerangkan bahwa warga di atas telah meninggal dunia. Surat Keterangan Kematian ini diberikan kepada ahli waris/keluarga yang bersangkutan guna keperluan pengurusan administrasi kependudukan di instansi yang berwenang.';

      case 'nikah':
        return 'Nama tersebut di atas benar-benar bertempat tinggal di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city dan berdasarkan keterangan yang ada sampai saat ini yang bersangkutan belum pernah melangsungkan pernikahan / tercatat sebagai warga yang hendak melangsungkan perkawinan. Surat pengantar ini diberikan guna keperluan proses administrasi pernikahan pada instansi berwenang.';

      case 'sku':
        return 'Nama tersebut di atas benar-benar merupakan warga yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city dan menjalankan usaha mikro/kecil di lingkungan kami. Surat Keterangan Usaha ini diberikan guna keperluan $purposeText.';

      case 'custom':
        return purposeText.isNotEmpty
            ? 'Nama tersebut di atas benar-benar merupakan warga yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city. Surat keterangan ini diberikan guna keperluan $purposeText.'
            : 'Nama tersebut di atas benar-benar merupakan warga yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city.';

      default:
        return 'Nama tersebut di atas merupakan warga yang berdomisili di RT $rtNumber/RW $rwNumber, Kelurahan $village, Kecamatan $district, $city.';
    }
  }

  static String _defaultPurpose(String letterType) {
    switch (letterType) {
      case 'domisili': return 'keperluan administrasi kependudukan';
      case 'sktm': return 'keperluan pengurusan bantuan sosial';
      case 'skck': return 'pengurusan SKCK';
      case 'sku': return 'keperluan perizinan usaha';
      default: return 'keperluan administrasi';
    }
  }

  // ──────────────────────────────────────────────
  // Generate PDF
  // ──────────────────────────────────────────────
  static Future<Uint8List> generate({
    required String letterNumber,
    required String letterType,
    required String generatedContent,
    required Map<String, dynamic> resident,
    required Map<String, dynamic> community,
  }) async {
    final pdf = pw.Document();

    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();
    final ttfItalic = pw.Font.helveticaOblique();

    final today = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(today);
    final namaJenisSurat = letterTypeLabels[letterType] ?? 'Surat Keterangan';

    final rtNumber = community['rt_number'] ?? '01';
    final rwNumber = community['rw_number'] ?? '01';
    final village = community['village'] ?? '';
    final district = community['district'] ?? '';
    final city = community['city'] ?? '';
    final province = community['province'] ?? '';
    final leaderName = community['leader_name'] ?? 'Ketua RW';
    final communityName = community['name'] ?? 'Lingkungan RW';

    final residentName = resident['full_name'] ?? '-';
    final residentNik = resident['nik'] ?? '-';
    final residentGender = resident['gender'] ?? '-';

    // Format TTL
    String ttlText = '-';
    if (resident['place_of_birth'] != null || resident['date_of_birth'] != null) {
      final pob = resident['place_of_birth'] ?? '';
      final dobRaw = resident['date_of_birth'];
      String dob = '';
      if (dobRaw != null) {
        try {
          dob = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(dobRaw));
        } catch (_) {
          dob = dobRaw;
        }
      }
      ttlText = pob.isNotEmpty && dob.isNotEmpty ? '$pob, $dob' : (pob.isNotEmpty ? pob : dob);
    }

    final residentReligion = resident['religion'] ?? '-';
    final residentMarital = resident['marital_status'] ?? '-';
    final residentOccupation = resident['occupation'] ?? '-';
    final residentAddress = 'RT $rtNumber/RW $rwNumber, $village, $district, $city';
    final residentAge = resident['age'] ?? '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 42),
        build: (context) => [
          // ─── KOP SURAT ───────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey800, width: 2.5)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 64, height: 64,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey700, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text('RW\n$rwNumber', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('PENGURUS $communityName', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 11, letterSpacing: 1.5)),
                      pw.SizedBox(height: 2),
                      pw.Text('RT $rtNumber / RW $rwNumber', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 13)),
                      pw.SizedBox(height: 2),
                      pw.Text('Kelurahan $village, Kecamatan $district', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text('$city – $province', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ─── JUDUL SURAT ──────────────────────────────────────
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'SURAT KETERANGAN ${namaJenisSurat.toUpperCase()}'.replaceFirst('SURAT KETERANGAN SURAT KETERANGAN', 'SURAT KETERANGAN').replaceFirst('SURAT KETERANGAN PENGANTAR', 'SURAT PENGANTAR').replaceFirst('SURAT KETERANGAN KETERANGAN', 'SURAT KETERANGAN'),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: ttfBold, fontSize: 13, decoration: pw.TextDecoration.underline),
                ),
                pw.SizedBox(height: 2),
                pw.Text('Nomor: $letterNumber', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // ─── KALIMAT PEMBUKA ──────────────────────────────────
          pw.Text(
            'Yang bertanda tangan di bawah ini, Ketua RW $rwNumber Kelurahan $village, Kecamatan $district, $city, dengan ini menerangkan bahwa:',
            style: pw.TextStyle(font: ttf, fontSize: 10.5),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 14),

          // ─── DATA WARGA ───────────────────────────────────────
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(135),
              1: const pw.FixedColumnWidth(14),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              _row('Nama Lengkap', residentName, ttf, ttfBold),
              _row('NIK', residentNik, ttf),
              _row('Tempat, Tanggal Lahir', ttlText, ttf),
              _row('Umur', residentAge, ttf),
              _row('Jenis Kelamin', residentGender, ttf),
              _row('Agama', residentReligion, ttf),
              _row('Status Perkawinan', residentMarital, ttf),
              _row('Pekerjaan', residentOccupation, ttf),
              _row('Alamat', residentAddress, ttf),
            ],
          ),
          pw.SizedBox(height: 16),

          // ─── ISI SURAT ────────────────────────────────────────
          pw.Text(generatedContent, style: pw.TextStyle(font: ttf, fontSize: 10.5, lineSpacing: 4), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 12),

          // ─── PENUTUP ──────────────────────────────────────────
          pw.Text(
            'Demikian surat keterangan ini dibuat dengan sebenarnya dan penuh rasa tanggung jawab, untuk dapat dipergunakan sebagaimana mestinya.',
            style: pw.TextStyle(font: ttf, fontSize: 10.5),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 26),

          // ─── TANDA TANGAN ─────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Stempel
              pw.Container(
                width: 80, height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(40),
                ),
                child: pw.Center(
                  child: pw.Text('STEMPEL\nRT/RW', textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: ttfItalic, fontSize: 9, color: PdfColors.grey500)),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('$city, $formattedDate', style: pw.TextStyle(font: ttf, fontSize: 10.5)),
                  pw.SizedBox(height: 2),
                  pw.Text('Ketua RW $rwNumber', style: pw.TextStyle(font: ttf, fontSize: 10.5)),
                  pw.SizedBox(height: 50),
                  pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8))),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Text('( $leaderName )', style: pw.TextStyle(font: ttfBold, fontSize: 10.5)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _row(String label, String value, pw.Font ttf, [pw.Font? bold]) {
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2.5), child: pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 10))),
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2.5), child: pw.Text(':', style: pw.TextStyle(font: ttf, fontSize: 10))),
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2.5), child: pw.Text(value, style: pw.TextStyle(font: bold ?? ttf, fontSize: 10))),
    ]);
  }
}
