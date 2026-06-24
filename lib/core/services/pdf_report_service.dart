import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/models/incident_model.dart';
import '../../shared/models/positive_moment_model.dart';

class PdfReportService {
  static final _dateFmt = DateFormat('d MMM yyyy');

  // Brand colours
  static const _orange = PdfColor(0.976, 0.451, 0.086);
  static const _teal   = PdfColor(0.059, 0.631, 0.580);
  static const _red    = PdfColor(0.937, 0.267, 0.267);
  static const _blue   = PdfColor(0.231, 0.510, 0.965);
  static const _green  = PdfColor(0.133, 0.773, 0.369);
  static const _grey1  = PdfColor(0.96, 0.96, 0.96);
  static const _grey2  = PdfColor(0.4, 0.4, 0.4);
  static const _grey3  = PdfColor(0.7, 0.7, 0.7);

  static Future<void> exportReport({
    required String childName,
    required DateTime from,
    required DateTime to,
    required List<IncidentModel> incidents,
    required List<PositiveMomentModel> positiveMoments,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        header: (ctx) => _header(ctx, childName, from, to),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                _summaryBar(incidents, positiveMoments),
                pw.SizedBox(height: 28),
                if (incidents.isNotEmpty) ...[
                  _sectionHeading('Behavioral Incidents', _red, incidents.length),
                  pw.SizedBox(height: 10),
                  ...incidents.map(_incidentCard),
                  pw.SizedBox(height: 28),
                ],
                if (positiveMoments.isNotEmpty) ...[
                  _sectionHeading('Positive Moments', _teal, positiveMoments.length),
                  pw.SizedBox(height: 10),
                  ...positiveMoments.map(_positiveMomentCard),
                ],
                if (incidents.isEmpty && positiveMoments.isEmpty)
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 40),
                      child: pw.Text(
                        'No logs found for this period.',
                        style: pw.TextStyle(color: _grey2, fontSize: 12),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'AutiLog_${childName.replaceAll(' ', '_')}_${_dateFmt.format(from)}_to_${_dateFmt.format(to)}.pdf',
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  static pw.Widget _header(pw.Context ctx, String childName, DateTime from, DateTime to) {
    final isFirstPage = ctx.pageNumber == 1;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Orange top strip
        pw.Container(
          width: double.infinity,
          color: _orange,
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AutiLog',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Behavioural Progress Report',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.white),
              ),
            ],
          ),
        ),
        if (isFirstPage) ...[
          pw.Container(
            width: double.infinity,
            color: const PdfColor(0.996, 0.937, 0.914),
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      childName,
                      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Period: ${_dateFmt.format(from)} to ${_dateFmt.format(to)}',
                      style: pw.TextStyle(fontSize: 10, color: _grey2),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: ${_dateFmt.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: _grey2),
                ),
              ],
            ),
          ),
        ] else ...[
          pw.Container(
            width: double.infinity,
            color: const PdfColor(0.996, 0.937, 0.914),
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 6),
            child: pw.Text(
              '$childName  |  ${_dateFmt.format(from)} to ${_dateFmt.format(to)}',
              style: pw.TextStyle(fontSize: 9, color: _grey2),
            ),
          ),
        ],
        pw.SizedBox(height: 2),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(32, 8, 32, 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CONFIDENTIAL — For clinical use only', style: pw.TextStyle(fontSize: 8, color: _grey3)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _grey3)),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────────────

  static pw.Widget _summaryBar(
    List<IncidentModel> incidents,
    List<PositiveMomentModel> moments,
  ) {
    final avgSeverity = incidents.isEmpty
        ? '--'
        : (incidents.map((e) => e.behaviorSeverity).reduce((a, b) => a + b) /
                incidents.length)
            .toStringAsFixed(1);
    final topTrigger = _topTrigger(incidents);
    final workedCount = incidents.where((i) => i.didItWork).length;

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _grey3, width: 0.5),
      ),
      child: pw.Row(
        children: [
          _statCell('${incidents.length}', 'Incidents', _red, leftRounded: true),
          _divider(),
          _statCell('${moments.length}', 'Positive Moments', _teal),
          _divider(),
          _statCell(avgSeverity, 'Avg Severity', _orange),
          _divider(),
          _statCell('$workedCount/${incidents.length}', 'Strategy Worked', _blue),
          _divider(),
          _statCell(topTrigger, 'Top Trigger', _grey2, rightRounded: true),
        ],
      ),
    );
  }

  static pw.Widget _divider() => pw.Container(width: 0.5, height: 56, color: _grey3);

  static pw.Widget _statCell(
    String value,
    String label,
    PdfColor color, {
    bool leftRounded = false,
    bool rightRounded = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: _grey1,
          borderRadius: pw.BorderRadius.only(
            topLeft: leftRounded ? const pw.Radius.circular(8) : pw.Radius.zero,
            bottomLeft: leftRounded ? const pw.Radius.circular(8) : pw.Radius.zero,
            topRight: rightRounded ? const pw.Radius.circular(8) : pw.Radius.zero,
            bottomRight: rightRounded ? const pw.Radius.circular(8) : pw.Radius.zero,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, color: _grey2),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section heading ───────────────────────────────────────────────────────────

  static pw.Widget _sectionHeading(String title, PdfColor color, int count) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 4, height: 20, color: color,
            decoration: const pw.BoxDecoration(borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)))),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Text(
            '$count',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── Incident card ─────────────────────────────────────────────────────────────

  static pw.Widget _incidentCard(IncidentModel i) {
    final timeStr = '${i.time.hour.toString().padLeft(2, '0')}:${i.time.minute.toString().padLeft(2, '0')}';
    final duration = i.behaviorDuration.inSeconds == 0
        ? 'Unknown duration'
        : i.behaviorDuration.inMinutes > 0
            ? '${i.behaviorDuration.inMinutes} min'
            : '${i.behaviorDuration.inSeconds} sec';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _grey3, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Card header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColor(0.99, 0.95, 0.95),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: _red,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('INCIDENT', style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(_dateFmt.format(i.date), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('$timeStr  |  $duration  |  ', style: pw.TextStyle(fontSize: 9, color: _grey2)),
                    pw.Text('Severity: ${i.behaviorSeverity}/5', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _red)),
                  ],
                ),
              ],
            ),
          ),
          // ABC body
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: [
                _abcRow('A', 'Antecedent', i.antecedentDescription, i.antecedentTriggers, _blue),
                pw.SizedBox(height: 8),
                _abcRow('B', 'Behavior', i.behaviorDescription, i.behaviorTypes, _red),
                pw.SizedBox(height: 8),
                _abcRow('C', 'Consequence', i.consequenceDescription, i.strategies, _green),
                if (i.therapistFeedback?.comment != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor(0.95, 0.95, 1.0),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: _blue, width: 0.5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Therapist Note:  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _blue)),
                        pw.Expanded(
                          child: pw.Text(
                            i.therapistFeedback!.comment,
                            style: pw.TextStyle(fontSize: 9, color: _grey2, fontStyle: pw.FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Positive moment card ──────────────────────────────────────────────────────

  static pw.Widget _positiveMomentCard(PositiveMomentModel m) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _grey3, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColor(0.93, 0.98, 0.95),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: _teal,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text('POSITIVE', style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(_dateFmt.format(m.date), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('${m.setting}  |  ', style: pw.TextStyle(fontSize: 9, color: _grey2)),
                    pw.Text('Rating: ${m.positiveBehaviorRating}/5', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _teal)),
                  ],
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: [
                _abcRow('A', 'Antecedent', m.antecedentDescription, [], _blue),
                pw.SizedBox(height: 8),
                _abcRow('B', 'Behavior', m.behaviorDescription, m.behaviorTypes, _teal),
                pw.SizedBox(height: 8),
                _abcRow('C', 'Consequence', m.consequenceDescription, [], _green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ABC row ───────────────────────────────────────────────────────────────────

  static pw.Widget _abcRow(String letter, String fullLabel, String description, List<String> chips, PdfColor color) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          children: [
            pw.Container(
              width: 22,
              height: 22,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(letter, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
          ],
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(fullLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
              pw.SizedBox(height: 2),
              if (description.isNotEmpty)
                pw.Text(description, style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
              if (chips.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: chips.map((c) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColor(color.red * 0.15 + 0.85, color.green * 0.15 + 0.85, color.blue * 0.15 + 0.85),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: color, width: 0.5),
                      ),
                      child: pw.Text(c, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _topTrigger(List<IncidentModel> incidents) {
    if (incidents.isEmpty) return '--';
    final counts = <String, int>{};
    for (final i in incidents) {
      for (final t in i.antecedentTriggers) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '--';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
