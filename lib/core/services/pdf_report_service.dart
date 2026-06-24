import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/models/incident_model.dart';
import '../../shared/models/positive_moment_model.dart';

class PatientReportData {
  final String childName;
  final List<IncidentModel> incidents;
  final List<PositiveMomentModel> positiveMoments;

  const PatientReportData({
    required this.childName,
    required this.incidents,
    required this.positiveMoments,
  });
}

class PdfReportService {
  static final _dateFmt  = DateFormat('d MMM yyyy');
  // Minimal palette — one accent, rest greyscale
  static const _accent   = PdfColor(0.976, 0.451, 0.086); // brand orange
  static const _ink      = PdfColor(0.15, 0.15, 0.15);    // near-black body text
  static const _muted    = PdfColor(0.45, 0.45, 0.45);    // captions
  static const _rule     = PdfColor(0.82, 0.82, 0.82);    // divider lines
  static const _rowAlt   = PdfColor(0.97, 0.97, 0.97);    // table alt row

  // ── Per-patient report ───────────────────────────────────────────────────────

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
        maxPages: 200,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        header: (ctx) => _pageHeader(ctx, 'Behavioural Progress Report', childName, from, to),
        footer: (ctx) => _pageFooter(ctx),
        build: (ctx) {
          final items = <pw.Widget>[
            pw.SizedBox(height: 16),
            _statsRow([
              _Stat('${incidents.length}', 'Incidents logged'),
              _Stat('${positiveMoments.length}', 'Positive moments'),
              _Stat(_avgSeverity(incidents), 'Avg severity (1–5)'),
              _Stat(_topTrigger(incidents), 'Most common trigger'),
            ]),
            pw.SizedBox(height: 24),
          ];

          if (incidents.isNotEmpty) {
            items.add(_sectionTitle('Behavioural Incidents'));
            items.add(pw.SizedBox(height: 8));
            items.add(_incidentTableHeader());
            bool alt = false;
            for (final inc in incidents) {
              items.add(_incidentTableRow(inc, alt));
              alt = !alt;
            }
            items.add(pw.SizedBox(height: 8));
            items.add(_dividerLine());
            items.add(pw.SizedBox(height: 20));
          }

          if (positiveMoments.isNotEmpty) {
            items.add(_sectionTitle('Positive Moments'));
            items.add(pw.SizedBox(height: 8));
            items.add(_momentTableHeader());
            bool alt = false;
            for (final m in positiveMoments) {
              items.add(_momentTableRow(m, alt));
              alt = !alt;
            }
            items.add(pw.SizedBox(height: 8));
            items.add(_dividerLine());
          }

          if (incidents.isEmpty && positiveMoments.isEmpty) {
            items.add(_emptyNote('No log entries found for this period.'));
          }

          return items;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'AutiLog_${childName.replaceAll(' ', '_')}_${_dateFmt.format(from)}_to_${_dateFmt.format(to)}.pdf',
    );
  }

  // ── Practice report (all patients combined) ──────────────────────────────────

  static Future<void> exportPracticeReport({
    required DateTime from,
    required DateTime to,
    required String aiSummary,
    required String aiFocus,
    required int totalIncidents,
    required double avgSleep,
    required String topTrigger,
    required Map<String, int> triggerCounts,
    required List<PatientReportData> patients,
  }) async {
    final pdf = pw.Document();
    final totalMoments = patients.fold<int>(0, (s, p) => s + p.positiveMoments.length);
    final activePatients = patients.where((p) => p.incidents.isNotEmpty || p.positiveMoments.isNotEmpty).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        header: (ctx) => _pageHeader(ctx, 'Practice Progress Report', 'All Patients', from, to),
        footer: (ctx) => _pageFooter(ctx),
        build: (ctx) {
          final items = <pw.Widget>[
            pw.SizedBox(height: 16),
            _statsRow([
              _Stat('$totalIncidents', 'Total incidents'),
              _Stat('$totalMoments', 'Positive moments'),
              _Stat(avgSleep > 0 ? avgSleep.toStringAsFixed(1) : '--', 'Avg sleep (hrs)'),
              _Stat(topTrigger.isEmpty ? '--' : topTrigger, 'Top trigger'),
            ]),
            pw.SizedBox(height: 24),
          ];

          if (aiSummary.isNotEmpty) {
            items.add(_sectionTitle('AI Practice Summary'));
            items.add(pw.SizedBox(height: 8));
            items.add(_textBlock(aiSummary));
            if (aiFocus.isNotEmpty) {
              items.add(pw.SizedBox(height: 6));
              items.add(_labeledLine('Recommended focus', aiFocus));
            }
            items.add(pw.SizedBox(height: 20));
            items.add(_dividerLine());
            items.add(pw.SizedBox(height: 20));
          }

          if (triggerCounts.isNotEmpty) {
            items.add(_sectionTitle('Trigger Frequency'));
            items.add(pw.SizedBox(height: 8));
            items.add(_triggerTable(triggerCounts));
            items.add(pw.SizedBox(height: 20));
            items.add(_dividerLine());
            items.add(pw.SizedBox(height: 20));
          }

          for (final p in activePatients) {
            items.add(_patientSectionHeader(p.childName, p.incidents.length, p.positiveMoments.length));
            items.add(pw.SizedBox(height: 10));

            if (p.incidents.isNotEmpty) {
              items.add(_subsectionTitle('Behavioural Incidents'));
              items.add(pw.SizedBox(height: 6));
              items.add(_incidentTableHeader());
              bool alt = false;
              for (final inc in p.incidents) {
                items.add(_incidentTableRow(inc, alt));
                alt = !alt;
              }
              items.add(pw.SizedBox(height: 10));
            }

            if (p.positiveMoments.isNotEmpty) {
              items.add(_subsectionTitle('Positive Moments'));
              items.add(pw.SizedBox(height: 6));
              items.add(_momentTableHeader());
              bool alt = false;
              for (final m in p.positiveMoments) {
                items.add(_momentTableRow(m, alt));
                alt = !alt;
              }
              items.add(pw.SizedBox(height: 10));
            }

            items.add(_dividerLine());
            items.add(pw.SizedBox(height: 20));
          }

          if (activePatients.isEmpty) {
            items.add(_emptyNote('No log entries found for any patient in this period.'));
          }

          return items;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'AutiLog_Practice_Report_${_dateFmt.format(from)}_to_${_dateFmt.format(to)}.pdf',
    );
  }

  // ── Page chrome ───────────────────────────────────────────────────────────────

  static pw.Widget _pageHeader(pw.Context ctx, String reportType, String subject, DateTime from, DateTime to) {
    final isFirst = ctx.pageNumber == 1;
    if (isFirst) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('AutiLog', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _accent)),
              pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 8, color: _muted, letterSpacing: 1.2)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(width: double.infinity, height: 1, color: _accent),
          pw.SizedBox(height: 8),
          pw.Text(reportType, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              pw.Text(subject, style: pw.TextStyle(fontSize: 11, color: _muted)),
              pw.Text('   ·   ', style: pw.TextStyle(color: _rule)),
              pw.Text('${_dateFmt.format(from)} – ${_dateFmt.format(to)}', style: pw.TextStyle(fontSize: 11, color: _muted)),
              pw.Spacer(),
              pw.Text('Generated ${_dateFmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: _muted)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(width: double.infinity, height: 0.5, color: _rule),
        ],
      );
    }
    // Continuation pages — compact
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('AutiLog  ·  $reportType', style: pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text('$subject  ·  ${_dateFmt.format(from)} – ${_dateFmt.format(to)}', style: pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(width: double.infinity, height: 0.5, color: _rule),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Container(width: double.infinity, height: 0.5, color: _rule),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('For clinical use only. Not for distribution.', style: pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ],
    );
  }

  // ── Layout primitives ─────────────────────────────────────────────────────────

  static pw.Widget _statsRow(List<_Stat> stats) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: stats.asMap().entries.map((e) {
          final isLast = e.key == stats.length - 1;
          return pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                border: isLast ? null : pw.Border(right: pw.BorderSide(color: _rule, width: 0.5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(e.value.value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
                  pw.SizedBox(height: 2),
                  pw.Text(e.value.label, style: pw.TextStyle(fontSize: 8, color: _muted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 3, height: 14, color: _accent),
        pw.SizedBox(width: 7),
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink, letterSpacing: 0.8)),
      ],
    );
  }

  static pw.Widget _subsectionTitle(String title) {
    return pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _muted, letterSpacing: 0.4));
  }

  static pw.Widget _dividerLine() =>
      pw.Container(width: double.infinity, height: 0.5, color: _rule);

  static pw.Widget _textBlock(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 3));
  }

  static pw.Widget _labeledLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label:  ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, color: _muted))),
      ],
    );
  }

  static pw.Widget _emptyNote(String msg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 24),
      child: pw.Text(msg, style: pw.TextStyle(fontSize: 10, color: _muted, fontStyle: pw.FontStyle.italic)),
    );
  }

  static pw.Widget _patientSectionHeader(String name, int incidents, int moments) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _rowAlt,
        border: pw.Border(left: pw.BorderSide(color: _accent, width: 3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.Text('$incidents incident${incidents == 1 ? '' : 's'}   $moments positive moment${moments == 1 ? '' : 's'}',
              style: pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    );
  }

  // ── Incident table ────────────────────────────────────────────────────────────

  static pw.Widget _incidentTableHeader() {
    return pw.Container(
      color: _ink,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 68, child: _th('Date')),
          pw.SizedBox(width: 40, child: _th('Time')),
          pw.SizedBox(width: 36, child: _th('Sev.')),
          pw.SizedBox(width: 50, child: _th('Duration')),
          pw.Expanded(child: _th('Antecedent')),
          pw.Expanded(child: _th('Behavior')),
          pw.Expanded(child: _th('Consequence')),
        ],
      ),
    );
  }

  static pw.Widget _incidentTableRow(IncidentModel i, bool alt) {
    final timeStr = '${i.time.hour.toString().padLeft(2, '0')}:${i.time.minute.toString().padLeft(2, '0')}';
    final dur = i.behaviorDuration.inSeconds == 0
        ? '—'
        : i.behaviorDuration.inMinutes > 0
            ? '${i.behaviorDuration.inMinutes} min'
            : '${i.behaviorDuration.inSeconds} sec';

    return pw.Container(
      color: alt ? _rowAlt : PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 68, child: _td(_dateFmt.format(i.date))),
          pw.SizedBox(width: 40, child: _td(timeStr)),
          pw.SizedBox(width: 36, child: _td('${i.behaviorSeverity}/5')),
          pw.SizedBox(width: 50, child: _td(dur)),
          pw.Expanded(child: _tdMulti(i.antecedentDescription, i.antecedentTriggers)),
          pw.Expanded(child: _tdMulti(i.behaviorDescription, i.behaviorTypes)),
          pw.Expanded(child: _tdMulti(i.consequenceDescription, i.strategies)),
        ],
      ),
    );
  }

  // ── Positive moment table ─────────────────────────────────────────────────────

  static pw.Widget _momentTableHeader() {
    return pw.Container(
      color: _ink,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 68, child: _th('Date')),
          pw.SizedBox(width: 40, child: _th('Time')),
          pw.SizedBox(width: 40, child: _th('Rating')),
          pw.SizedBox(width: 60, child: _th('Setting')),
          pw.Expanded(child: _th('Antecedent')),
          pw.Expanded(child: _th('Behavior')),
          pw.Expanded(child: _th('Consequence')),
        ],
      ),
    );
  }

  static pw.Widget _momentTableRow(PositiveMomentModel m, bool alt) {
    final h = (m.timeMinutes ~/ 60).toString().padLeft(2, '0');
    final min = (m.timeMinutes % 60).toString().padLeft(2, '0');
    final timeStr = '$h:$min';
    return pw.Container(
      color: alt ? _rowAlt : PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 68, child: _td(_dateFmt.format(m.date))),
          pw.SizedBox(width: 40, child: _td(timeStr)),
          pw.SizedBox(width: 40, child: _td('${m.positiveBehaviorRating}/5')),
          pw.SizedBox(width: 60, child: _td(m.setting)),
          pw.Expanded(child: _td(m.antecedentDescription)),
          pw.Expanded(child: _tdMulti(m.behaviorDescription, m.behaviorTypes)),
          pw.Expanded(child: _td(m.consequenceDescription)),
        ],
      ),
    );
  }

  // ── Trigger table ─────────────────────────────────────────────────────────────

  static pw.Widget _triggerTable(Map<String, int> triggerCounts) {
    final sorted = triggerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).toList();
    final maxVal = top.isEmpty ? 1 : top.first.value;

    final rows = <pw.Widget>[
      pw.Container(
        color: _ink,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: _th('Trigger')),
            pw.Expanded(flex: 5, child: _th('Frequency')),
            pw.SizedBox(width: 30, child: _th('Count')),
          ],
        ),
      ),
    ];

    bool alt = false;
    for (final e in top) {
      final fraction = maxVal == 0 ? 0.0 : e.value / maxVal;
      rows.add(pw.Container(
        color: alt ? _rowAlt : PdfColors.white,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Row(
          children: [
            pw.Expanded(flex: 3, child: _td(e.key)),
            pw.Expanded(
              flex: 5,
              child: pw.LayoutBuilder(
                builder: (ctx, constraints) => pw.Stack(
                  children: [
                    pw.Container(height: 10, color: _rule),
                    pw.Container(
                      width: (constraints?.maxWidth ?? 200) * fraction,
                      height: 10,
                      color: _accent,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 30, child: _td('${e.value}', center: true)),
          ],
        ),
      ));
      alt = !alt;
    }

    return pw.Column(children: rows);
  }

  // ── Table cell helpers ────────────────────────────────────────────────────────

  static pw.Widget _th(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      );

  static pw.Widget _td(String text, {bool center = false}) => pw.Text(
        text.isEmpty ? '—' : text,
        style: pw.TextStyle(fontSize: 8, color: _ink),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      );

  static pw.Widget _tdMulti(String description, List<String> tags) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty)
          pw.Text(description, style: pw.TextStyle(fontSize: 8, color: _ink)),
        if (tags.isNotEmpty)
          pw.Text(tags.join(', '), style: pw.TextStyle(fontSize: 7, color: _muted)),
      ],
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────────

  static String _avgSeverity(List<IncidentModel> incidents) {
    if (incidents.isEmpty) return '--';
    final avg = incidents.map((e) => e.behaviorSeverity).reduce((a, b) => a + b) / incidents.length;
    return avg.toStringAsFixed(1);
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

class _Stat {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
}
