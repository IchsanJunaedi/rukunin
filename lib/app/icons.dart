import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RUKUNIN — Custom Icon System
// ─────────────────────────────────────────────────────────────────────────────

class RukuninIconData {
  final String pathData;
  final bool filled;

  const RukuninIconData(this.pathData, {this.filled = false});
}

class RukuninIcon extends StatelessWidget {
  final RukuninIconData icon;
  final double size;
  final Color? color;

  const RukuninIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IconPainter(icon, c),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final RukuninIconData icon;
  final Color color;

  _IconPainter(this.icon, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = icon.filled ? PaintingStyle.fill : PaintingStyle.stroke;

    final path = _parseSvgPath(icon.pathData);

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    final scaledPath = path.transform(
      Matrix4.diagonal3Values(scaleX, scaleY, 1).storage,
    );

    canvas.drawPath(scaledPath, paint);
  }

  Path _parseSvgPath(String d) {
    final path = Path();
    final tokens = RegExp(
      r'([MLHVCSQTAZmlhvcsqtaz])|(-?[\d.]+(?:e[-+]?\d+)?)',
    ).allMatches(d);

    String? cmd;
    final nums = <double>[];

    void flush() {
      if (cmd == null) return;
      _applyCmd(path, cmd, nums);
      nums.clear();
    }

    for (final m in tokens) {
      final letter = m.group(1);
      final number = m.group(2);
      if (letter != null) {
        flush();
        cmd = letter;
      } else if (number != null) {
        nums.add(double.parse(number));
      }
    }
    flush();
    return path;
  }

  void _applyCmd(Path path, String cmd, List<double> n) {
    switch (cmd) {
      case 'M': for (var i = 0; i + 1 < n.length; i += 2) path.moveTo(n[i], n[i+1]); break;
      case 'm': for (var i = 0; i + 1 < n.length; i += 2) path.relativeMoveTo(n[i], n[i+1]); break;
      case 'L': for (var i = 0; i + 1 < n.length; i += 2) path.lineTo(n[i], n[i+1]); break;
      case 'l': for (var i = 0; i + 1 < n.length; i += 2) path.relativeLineTo(n[i], n[i+1]); break;
      case 'H': for (final x in n) path.lineTo(x, path.getBounds().bottom); break;
      case 'h': for (final dx in n) path.relativeLineTo(dx, 0); break;
      case 'V': for (final y in n) path.lineTo(path.getBounds().right, y); break;
      case 'v': for (final dy in n) path.relativeLineTo(0, dy); break;
      case 'C': for (var i = 0; i + 5 < n.length; i += 6) path.cubicTo(n[i], n[i+1], n[i+2], n[i+3], n[i+4], n[i+5]); break;
      case 'c': for (var i = 0; i + 5 < n.length; i += 6) path.relativeCubicTo(n[i], n[i+1], n[i+2], n[i+3], n[i+4], n[i+5]); break;
      case 'Q': for (var i = 0; i + 3 < n.length; i += 4) path.quadraticBezierTo(n[i], n[i+1], n[i+2], n[i+3]); break;
      case 'q': for (var i = 0; i + 3 < n.length; i += 4) path.relativeQuadraticBezierTo(n[i], n[i+1], n[i+2], n[i+3]); break;
      case 'Z': case 'z': path.close(); break;
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.icon != icon;
}

// ─────────────────────────────────────────────────────────────────────────────
//  ICON CATALOGUE
// ─────────────────────────────────────────────────────────────────────────────

abstract class RukuninIcons {

  // ── Navigation ────────────────────────────────────────────────────────────
  static const home = RukuninIconData(
    'M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z '
    'M9 21V12h6v9',
  );

  static const homeFilled = RukuninIconData(
    'M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z '
    'M9 21V12h6v9',
    filled: true,
  );

  static const users = RukuninIconData(
    'M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2 '
    'M23 21v-2a4 4 0 00-3-3.87 '
    'M16 3.13a4 4 0 010 7.75 '
    'M9 7a4 4 0 110 8 4 4 0 010-8z',
  );

  static const receipt = RukuninIconData(
    'M14 2H6a2 2 0 00-2 2v16l4-2 4 2 4-2 4 2V8z '
    'M14 2v6h6 '
    'M9 13h6 '
    'M9 17h3',
  );

  static const megaphone = RukuninIconData(
    'M3 11v2a8 8 0 008 8h1 '
    'M11 3L21 6v12l-10 3V3z '
    'M11 7v10',
  );

  static const store = RukuninIconData(
    'M3 9l1-5h16l1 5 '
    'M3 9a2 2 0 002 2 2 2 0 002-2 2 2 0 002 2 2 2 0 002-2 2 2 0 002 2 2 2 0 002-2 '
    'M5 11v9a1 1 0 001 1h12a1 1 0 001-1v-9 '
    'M10 11v5h4v-5',
  );

  static const profile = RukuninIconData(
    'M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2 '
    'M12 11a4 4 0 100-8 4 4 0 000 8z',
  );

  static const aiSpark = RukuninIconData(
    'M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z',
  );

  // ── Actions ───────────────────────────────────────────────────────────────
  static const plus         = RukuninIconData('M12 5v14M5 12h14');
  static const close        = RukuninIconData('M18 6L6 18M6 6l12 12');
  static const check        = RukuninIconData('M20 6L9 17l-5-5');
  static const chevronRight = RukuninIconData('M9 18l6-6-6-6');
  static const chevronLeft  = RukuninIconData('M15 18l-6-6 6-6');
  static const chevronDown  = RukuninIconData('M6 9l6 6 6-6');
  static const chevronUp    = RukuninIconData('M18 15l-6-6-6 6');
  static const arrowLeft    = RukuninIconData('M19 12H5M12 5l-7 7 7 7');

  static const search = RukuninIconData(
    'M21 21l-4.35-4.35 '
    'M17 11A6 6 0 115 11a6 6 0 0112 0z',
  );

  static const filter   = RukuninIconData('M22 3H2l8 9.46V19l4 2v-8.54z');
  static const send     = RukuninIconData('M22 2L11 13 M22 2L15 22l-4-9-9-4 20-7z');

  static const upload = RukuninIconData(
    'M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4 '
    'M17 8l-5-5-5 5 '
    'M12 3v12',
  );

  static const download = RukuninIconData(
    'M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4 '
    'M7 10l5 5 5-5 '
    'M12 15V3',
  );

  static const edit = RukuninIconData(
    'M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7 '
    'M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z',
  );

  static const trash = RukuninIconData(
    'M3 6h18 '
    'M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6 '
    'M8 6V4a1 1 0 011-1h6a1 1 0 011 1v2',
  );

  static const copy = RukuninIconData(
    'M20 9H11a2 2 0 00-2 2v9a2 2 0 002 2h9a2 2 0 002-2v-9a2 2 0 00-2-2z '
    'M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1',
  );

  static const more = RukuninIconData(
    'M12 13a1 1 0 100-2 1 1 0 000 2z '
    'M19 13a1 1 0 100-2 1 1 0 000 2z '
    'M5 13a1 1 0 100-2 1 1 0 000 2z',
    filled: true,
  );

  static const refresh = RukuninIconData(
    'M23 4v6h-6 '
    'M1 20v-6h6 '
    'M3.51 9a9 9 0 0114.85-3.36L23 10 '
    'M1 14l4.64 4.36A9 9 0 0020.49 15',
  );

  static const share = RukuninIconData(
    'M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8 '
    'M16 6l-4-4-4 4 '
    'M12 2v13',
  );

  // ── Finance ───────────────────────────────────────────────────────────────
  static const wallet = RukuninIconData(
    'M21 12V7H5a2 2 0 010-4h15a1 1 0 011 1v4 '
    'M3 5v14a2 2 0 002 2h16v-5 '
    'M18 12a2 2 0 000 4h4v-4z',
  );

  static const bank = RukuninIconData(
    'M2 22h20 '
    'M2 11l10-8 10 8 '
    'M6 11v7 '
    'M10 11v7 '
    'M14 11v7 '
    'M18 11v7',
  );

  static const qr = RukuninIconData(
    'M3 3h7v7H3z '
    'M14 3h7v7h-7z '
    'M3 14h7v7H3z '
    'M17 14v1 '
    'M14 14h1 '
    'M14 17h3 '
    'M17 17v4 '
    'M20 14v4 '
    'M20 20v1',
  );

  static const chartBar  = RukuninIconData('M18 20V10 M12 20V4 M6 20v-6');
  static const chartLine = RukuninIconData('M3 3v18h18 M7 16l4-4 4 4 4-4');
  static const arrowUp   = RukuninIconData('M5 15l7-7 7 7');
  static const arrowDown = RukuninIconData('M19 9l-7 7-7-7');

  // ── Status & Info ─────────────────────────────────────────────────────────
  static const info = RukuninIconData(
    'M12 22a10 10 0 100-20 10 10 0 000 20z '
    'M12 8v4 '
    'M12 16h.01',
  );

  static const warning = RukuninIconData(
    'M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z '
    'M12 9v4 '
    'M12 17h.01',
  );

  static const checkCircle = RukuninIconData(
    'M22 11.08V12a10 10 0 11-5.93-9.14 '
    'M22 4L12 14.01l-3-3',
  );

  static const xCircle = RukuninIconData(
    'M12 22a10 10 0 100-20 10 10 0 000 20z '
    'M15 9l-6 6 '
    'M9 9l6 6',
  );

  static const clock = RukuninIconData(
    'M12 22a10 10 0 100-20 10 10 0 000 20z '
    'M12 6v6l4 2',
  );

  static const calendar = RukuninIconData(
    'M3 4h18v18H3z '
    'M16 2v4 '
    'M8 2v4 '
    'M3 10h18',
  );

  static const bell = RukuninIconData(
    'M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9 '
    'M13.73 21a2 2 0 01-3.46 0',
  );

  static const key = RukuninIconData(
    'M21 2l-2 2m-7.61 7.61a5.5 5.5 0 11-7.778 7.778 5.5 5.5 0 017.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4',
  );

  static const lock = RukuninIconData(
    'M19 11H5a2 2 0 00-2 2v7a2 2 0 002 2h14a2 2 0 002-2v-7a2 2 0 00-2-2z '
    'M7 11V7a5 5 0 0110 0v4',
  );

  static const settings = RukuninIconData(
    'M12 15a3 3 0 100-6 3 3 0 000 6z '
    'M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z',
  );

  static const help = RukuninIconData(
    'M12 22a10 10 0 100-20 10 10 0 000 20z '
    'M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3 '
    'M12 17h.01',
  );

  static const logout = RukuninIconData(
    'M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4 '
    'M16 17l5-5-5-5 '
    'M21 12H9',
  );

  static const phone = RukuninIconData(
    'M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z',
  );

  static const whatsapp = RukuninIconData(
    'M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z '
    'M13.05 22c-3.36 0-6.49-1.32-8.83-3.69A12.14 12.14 0 012 13.3C2 6.64 7.3 1.2 13.95 1.2c3.2 0 6.2 1.26 8.47 3.53A11.93 11.93 0 0126 13.2c.01 6.57-5.26 11.97-11.86 12h-.09M2 22l1.53-5.56A11.67 11.67 0 012 13.3',
  );

  // ── Community & Services ──────────────────────────────────────────────────
  static const document = RukuninIconData(
    'M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z '
    'M14 2v6h6 '
    'M9 13h6 '
    'M9 17h3',
  );

  static const complaint = RukuninIconData(
    'M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z',
  );

  static const contact = RukuninIconData(
    'M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2 '
    'M9 7a4 4 0 110 8 4 4 0 010-8z '
    'M23 21v-2a4 4 0 00-3-3.87 '
    'M16 3.13a4 4 0 010 7.75',
  );

  static const house = RukuninIconData(
    'M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z',
  );

  static const car = RukuninIconData(
    'M5 17H3v-5l2-5h14l2 5v5h-2 '
    'M5 17a2 2 0 104 0 2 2 0 00-4 0z '
    'M15 17a2 2 0 104 0 2 2 0 00-4 0z '
    'M3 12h18',
  );

  static const image = RukuninIconData(
    'M21 19a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2z '
    'M8.5 10a1.5 1.5 0 100-3 1.5 1.5 0 000 3z '
    'M21 15l-5-5L5 21',
  );

  static const camera = RukuninIconData(
    'M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z '
    'M12 17a4 4 0 100-8 4 4 0 000 8z',
  );

  static const tag = RukuninIconData(
    'M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z '
    'M7 7h.01',
  );

  static const star = RukuninIconData(
    'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z',
  );

  static const starFilled = RukuninIconData(
    'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z',
    filled: true,
  );

  static const grid = RukuninIconData(
    'M3 3h7v7H3z '
    'M14 3h7v7h-7z '
    'M3 14h7v7H3z '
    'M14 14h7v7h-7z',
  );
}
