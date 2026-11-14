import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/nasa/power.dart';

const forest = Color(0xFF173E32);
const green = Color(0xFF548364);
const lime = Color(0xFFD7E8B3);
const cream = Color(0xFFF5F5EF);
const ink = Color(0xFF223A30);
const muted = Color(0xFF778379);
const gold = Color(0xFFBE9954);

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ink.withValues(alpha: .07)),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = green});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EBD9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF8D7440)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Color(0xFF79663D),
            ),
          ),
        ),
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  final String title, value, caption;
  final IconData icon;
  const Metric(this.title, this.value, this.caption, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: green, size: 20),
            const Spacer(),
            const Icon(Icons.north_east, color: muted, size: 15),
          ],
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          style: const TextStyle(color: muted, fontSize: 10, height: 1.5),
        ),
      ],
    ),
  );
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 220,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = math.max(1, (constraints.maxWidth / minWidth).floor());
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((c) => SizedBox(width: width, child: c))
            .toList(),
      );
    },
  );
}

class Andes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF244E3C), Color(0xFF8AA17E)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(Offset.zero & s),
    );
    canvas.drawCircle(
      Offset(s.width * .82, s.height * .19),
      s.height * .13,
      Paint()..color = const Color(0xFFD9C998).withValues(alpha: .75),
    );
    for (var j = 0; j < 4; j++) {
      final path = Path()..moveTo(-10, s.height * (.50 + j * .1));
      for (var i = 0; i <= 60; i++) {
        final x = s.width * i / 60;
        final y =
            s.height * (.51 + j * .12) -
            math.sin(i / 60 * math.pi * 2.2 + j * .9) *
                s.height *
                (.27 - j * .035);
        path.lineTo(x, y);
      }
      path.lineTo(s.width, s.height);
      path.lineTo(0, s.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = [
            const Color(0xFF557663),
            const Color(0xFF3A604A),
            const Color(0xFF72915A),
            const Color(0xFF35563B),
          ][j],
      );
    }
    for (var j = 0; j < 10; j++) {
      final path = Path()..moveTo(s.width * .38, s.height * (.50 + j * .052));
      path.cubicTo(
        s.width * .53,
        s.height * (.25 + j * .075),
        s.width * .72,
        s.height * (.88 + j * .035),
        s.width * 1.05,
        s.height * (.52 + j * .066),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFBECE8C).withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant Andes oldDelegate) => false;
}

class ClimateChart extends StatelessWidget {
  final List<Measurement> data;
  final String variable;
  const ClimateChart({super.key, required this.data, required this.variable});
  @override
  Widget build(BuildContext context) {
    final rows = data.where((m) => m.variable == variable).toList()
      ..sort((a, b) => a.observationDate.compareTo(b.observationDate));
    if (!rows.any((m) => m.value != null)) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'Consulta NASA POWER para ver la serie real.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    final valid = rows.where((m) => m.value != null).toList();
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: CustomPaint(
            painter: _ChartPainter(rows),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              dateLabel(rows.first.observationDate),
              style: const TextStyle(color: muted, fontSize: 10),
            ),
            Text(
              'Mín ${valid.map((m) => m.value!).reduce(math.min).toStringAsFixed(1)} · Máx ${valid.map((m) => m.value!).reduce(math.max).toStringAsFixed(1)} ${valid.first.unit}',
              style: const TextStyle(color: muted, fontSize: 10),
            ),
            Text(
              dateLabel(rows.last.observationDate),
              style: const TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Measurement> rows;
  _ChartPainter(this.rows);
  @override
  void paint(Canvas c, Size s) {
    final vals = rows
        .where((m) => m.value != null)
        .map((m) => m.value!)
        .toList();
    if (vals.isEmpty) return;
    final lo = vals.reduce(math.min) - 2, hi = vals.reduce(math.max) + 2;
    for (var i = 0; i < 5; i++) {
      final y = s.height * i / 4;
      c.drawLine(
        Offset(0, y),
        Offset(s.width, y),
        Paint()..color = const Color(0xFFEDF0E8),
      );
    }
    final p = Path();
    var active = false;
    for (var i = 0; i < rows.length; i++) {
      final v = rows[i].value;
      if (v == null) {
        active = false;
        continue;
      }
      final x = rows.length == 1
          ? s.width / 2
          : i / (rows.length - 1) * s.width;
      final y = s.height - (v - lo) / (hi - lo) * s.height;
      if (active) {
        p.lineTo(x, y);
      } else {
        p.moveTo(x, y);
        active = true;
      }
      c.drawCircle(Offset(x, y), 2.5, Paint()..color = green);
    }
    c.drawPath(
      p,
      Paint()
        ..color = green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

class PlotMap extends StatefulWidget {
  final double latitude, longitude;
  final void Function(double, double)? onSelect;
  const PlotMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onSelect,
  });
  @override
  State<PlotMap> createState() => _PlotMapState();
}

class _PlotMapState extends State<PlotMap> {
  int zoom = 11;
  late double lat = widget.latitude, lon = widget.longitude;
  @override
  void didUpdateWidget(PlotMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      lat = widget.latitude;
      lon = widget.longitude;
    }
  }

  math.Point<double> pixel(double latitude, double longitude) {
    final n = 256.0 * math.pow(2, zoom);
    final phi = latitude.clamp(-85.0, 85.0) * math.pi / 180;
    return math.Point(
      (longitude + 180) / 360 * n,
      (1 - math.log(math.tan(phi) + 1 / math.cos(phi)) / math.pi) / 2 * n,
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: LayoutBuilder(
      builder: (context, box) {
        final center = pixel(lat, lon);
        final left = center.x - box.maxWidth / 2,
            top = center.y - box.maxHeight / 2;
        final tiles = <Widget>[];
        final n = math.pow(2, zoom).toInt();
        for (
          var x = (left / 256).floor();
          x <= ((left + box.maxWidth) / 256).floor();
          x++
        ) {
          for (
            var y = (top / 256).floor();
            y <= ((top + box.maxHeight) / 256).floor();
            y++
          ) {
            if (y < 0 || y >= n) continue;
            tiles.add(
              Positioned(
                left: x * 256 - left,
                top: y * 256 - top,
                width: 256,
                height: 256,
                child: Image.network(
                  'https://tile.openstreetmap.org/$zoom/${x % n}/$y.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Container(
                    color: const Color(0xFFDCE3D4),
                    child: const Center(
                      child: Icon(Icons.map_outlined, color: muted),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        return GestureDetector(
          onTapUp: widget.onSelect == null
              ? null
              : (details) {
                  final worldX = left + details.localPosition.dx,
                      worldY = top + details.localPosition.dy;
                  final newLon = worldX / (256 * n) * 360 - 180;
                  final a = math.pi * (1 - 2 * worldY / (256 * n));
                  final newLat =
                      math.atan((math.exp(a) - math.exp(-a)) / 2) *
                      180 /
                      math.pi;
                  widget.onSelect!(newLat, ((newLon + 180) % 360) - 180);
                },
          onPanUpdate: (d) {
            final a = pixel(lat, lon);
            final worldY = a.y - d.delta.dy;
            final h = math.pi * (1 - 2 * worldY / (256 * n));
            setState(() {
              lon = ((a.x - d.delta.dx) / (256 * n) * 360) % 360 - 180;
              lat =
                  (math.atan((math.exp(h) - math.exp(-h)) / 2) * 180 / math.pi)
                      .clamp(-85, 85);
            });
          },
          child: Stack(
            children: [
              Container(color: const Color(0xFFE3E9DB)),
              ...tiles,
              Positioned(
                left: pixel(widget.latitude, widget.longitude).x - left - 18,
                top: pixel(widget.latitude, widget.longitude).y - top - 36,
                child: const Icon(Icons.location_on, color: forest, size: 36),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Acercar',
                      onPressed: zoom < 17
                          ? () => setState(() => zoom++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 4),
                    IconButton.filledTonal(
                      tooltip: 'Alejar',
                      onPressed: zoom > 3 ? () => setState(() => zoom--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 5,
                right: 5,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9, color: ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
