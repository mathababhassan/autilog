import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/models/incident_model.dart';
import '../../shared/models/positive_moment_model.dart';

class PdfReportService {
  static final _dateFmt = DateFormat('d MMM yyyy');

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
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(childName, from, to),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _summarySection(incidents, positiveMoments),
          pw.SizedBox(height: 24),
          if (incidents.isNotEmpty) ...[
            _sectionTitle('Behavioral Incidents'),
            pw.SizedBox(height: 8),
            ...incidents.map(_incidentCard),
            pw.SizedBox(height: 24),
          ],
          if (positiveMoments.isNotEmpty) ...[
            _sectionTitle('Positive Moments'),
            pw.SizedBox(height: 8),
            ...positiveMoments.map(_positiveMomentCard),
          ],
          if (incidents.isEmpty && positiveMoments.isEmpty)
            pw.Center(
              child: pw.Text(
                'No logs found for this period.',
                style: const pw.TextStyle(color: PdfColors.grey600),
              ),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'AutiLog_${childName.replaceAll(' ', '_')}_${_dateFmt.format(from)}-${_dateFmt.format(to)}.pdf',
    );
  }

  static pw.Widget _buildHeader(String childName, DateTime from, DateTime to) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AutiLog Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#F97316'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  childName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${_dateFmt.format(from)} – ${_dateFmt.format(to)}',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Text(
              'Generated ${_dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('AutiLog — Confidential', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summarySection(
    List<IncidentModel> incidents,
    List<PositiveMomentModel> moments,
  ) {
    final topTrigger = _topTrigger(incidents);
    final avgSeverity = incidents.isEmpty
        ? 0.0
        : incidents.map((e) => e.behaviorSeverity).reduce((a, b) => a + b) /
            incidents.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF7ED'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColor.fromHex('#FDBA74'), width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statBox('Total Incidents', '${incidents.length}'),
          _statBox('Positive Moments', '${moments.length}'),
          _statBox('Avg Severity', avgSeverity == 0 ? '--' : avgSeverity.toStringAsFixed(1)),
          _statBox('Top Trigger', topTrigger),
        ],
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _incidentCard(IncidentModel i) {
    final timeStr =
        '${i.time.hour.toString().padLeft(2, '0')}:${i.time.minute.toString().padLeft(2, '0')}';
    final duration = i.behaviorDuration.inMinutes > 0
        ? '${i.behaviorDuration.inMinutes}m'
        : '${i.behaviorDuration.inSeconds}s';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _dateFmt.format(i.date),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
              pw.Text(
                '$timeStr  ·  $duration  ·  Severity ${i.behaviorSeverity}/5',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          _abcRow('A', i.antecedentDescription, i.antecedentTriggers),
          pw.SizedBox(height: 4),
          _abcRow('B', i.behaviorDescription, i.behaviorTypes),
          pw.SizedBox(height: 4),
          _abcRow('C', i.consequenceDescription, i.strategies),
          if (i.therapistFeedback?.comment != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Therapist note: ${i.therapistFeedback!.comment}',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _positiveMomentCard(PositiveMomentModel m) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0FDF4'),
        border: pw.Border.all(color: PdfColor.fromHex('#86EFAC'), width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _dateFmt.format(m.date),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
              pw.Text(
                '${m.setting}  ·  Rating ${m.positiveBehaviorRating}/5',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          _abcRow('A', m.antecedentDescription, []),
          pw.SizedBox(height: 4),
          _abcRow('B', m.behaviorDescription, m.behaviorTypes),
          pw.SizedBox(height: 4),
          _abcRow('C', m.consequenceDescription, []),
        ],
      ),
    );
  }

  static pw.Widget _abcRow(String label, String description, List<String> chips) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 18,
          height: 18,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: label == 'A'
                ? PdfColor.fromHex('#DBEAFE')
                : label == 'B'
                    ? PdfColor.fromHex('#FEE2E2')
                    : PdfColor.fromHex('#DCFCE7'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                pw.Text(description, style: const pw.TextStyle(fontSize: 10)),
              if (chips.isNotEmpty)
                pw.Text(
                  chips.join(' · '),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
