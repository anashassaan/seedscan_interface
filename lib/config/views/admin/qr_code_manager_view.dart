import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/admin_controller.dart';

class QrCodeManagerView extends StatefulWidget {
  final int communityIndex;
  const QrCodeManagerView({super.key, required this.communityIndex});

  @override
  State<QrCodeManagerView> createState() => _QrCodeManagerViewState();
}

class _QrCodeManagerViewState extends State<QrCodeManagerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _quantityCtrl = TextEditingController(text: '10');
  final _plantNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _plantAgeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<PlantQrCode> _generatedCodes = [];
  List<List<dynamic>> _csvData = [];
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _csvFileName;

  // Plant info fields
  String _selectedPlantType = 'Tree';
  String _selectedSeason = 'Spring';
  bool _isSeed = true;

  static const List<String> _plantTypes = [
    'Tree',
    'Shrub',
    'Herb',
    'Climber',
    'Grass',
    'Succulent',
    'Fern',
  ];

  static const List<String> _seasons = [
    'Spring',
    'Summer',
    'Monsoon',
    'Autumn',
    'Winter',
    'Year-round',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityCtrl.dispose();
    _plantNameCtrl.dispose();
    _notesCtrl.dispose();
    _plantAgeCtrl.dispose();
    super.dispose();
  }

  // ── Generate QR Codes ──────────────────────────────────────────────────
  Future<void> _generateQrCodes() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = Provider.of<AdminController>(context, listen: false);
    final community = admin.communities[widget.communityIndex];
    final quantity = int.parse(_quantityCtrl.text.trim());
    const uuid = Uuid();

    setState(() => _isGenerating = true);

    // Use the real Appwrite $id — NOT a slugified name.
    // The QR data embeds this as the community identifier so the scanner
    // can resolve the correct community document from Appwrite.
    final communityId = community.id; // e.g. '699bef18c5fa79c38fa0'

    final codes = List.generate(quantity, (_) {
      final uniqueId = uuid.v4().split('-').first.toUpperCase();
      return PlantQrCode(
        id: '${communityId}_$uniqueId',
        communityId: communityId,
        communityName: community.name,
        plantName: _plantNameCtrl.text.trim(),
        plantType: _selectedPlantType,
        bestSeason: _selectedSeason,
        notes: _notesCtrl.text.trim(),
        isSeed: _isSeed,
        plantAge: _isSeed ? null : _plantAgeCtrl.text.trim(),
      );
    });

    setState(() {
      _generatedCodes = codes;
      _isGenerating = false;
    });

    // Store in controller and persist to Appwrite
    await admin.addQrCodes(widget.communityIndex, codes);
  }

  // ── Render a styled QR card image for gallery save ─────────────────────
  Future<ui.Image> _renderQrCard(PlantQrCode code) async {
    const double cardW = 600;
    const double cardH = 820;
    const double qrSize = 420;
    const double pad = 40;
    const double borderW = 6;
    const double radius = 28;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, cardW, cardH));

    // Green border
    final borderPaint = Paint()..color = const Color(0xFF0B6E4F);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, cardW, cardH),
            const Radius.circular(radius)),
        borderPaint);

    // White fill
    final fillPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                borderW, borderW, cardW - borderW * 2, cardH - borderW * 2),
            const Radius.circular(radius - 4)),
        fillPaint);

    // Draw QR code
    final qrPainter = QrPainter(
      data: code.qrData,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );
    final qrImage =
        await qrPainter.toImageData(qrSize, format: ui.ImageByteFormat.png);
    if (qrImage != null) {
      final codec =
          await ui.instantiateImageCodec(qrImage.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final dx = (cardW - qrSize) / 2;
      canvas.drawImage(frame.image, Offset(dx, pad), Paint());
    }

    // Plant name (bold, large)
    final nameParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center, fontSize: 36, fontWeight: FontWeight.w700))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
      ..addText(code.displayLabel);
    final nameLayout = nameParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: cardW - pad * 2));
    canvas.drawParagraph(nameLayout, Offset(pad, pad + qrSize + 16));

    // ID badge (green rounded rect, centered)
    final idText = code.id;
    final badgeMaxW = cardW - pad * 2;
    final idPb = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center, fontSize: 18, fontWeight: FontWeight.w700))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
      ..addText(idText);
    final idLayout = idPb.build()
      ..layout(ui.ParagraphConstraints(width: badgeMaxW));
    final badgeContentW = idLayout.longestLine + 48;
    final badgeW = badgeContentW > badgeMaxW ? badgeMaxW : badgeContentW;
    final badgeH = idLayout.height + 20;
    final badgeX = (cardW - badgeW) / 2;
    final badgeY = pad + qrSize + 16 + nameLayout.height + 14;
    final badgePaint = Paint()..color = const Color(0xFFCCEEDD);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
            const Radius.circular(12)),
        badgePaint);
    // Re-layout ID text constrained to badge width so it centers within the badge
    final idPb2 = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center, fontSize: 18, fontWeight: FontWeight.w700))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
      ..addText(idText);
    final idLayout2 = idPb2.build()
      ..layout(ui.ParagraphConstraints(width: badgeW));
    canvas.drawParagraph(idLayout2, Offset(badgeX, badgeY + 10));

    // Community name
    final commPb = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 16))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF888888)))
      ..addText('Garden: ${code.communityName}');
    final commLayout = commPb.build()
      ..layout(const ui.ParagraphConstraints(width: cardW - pad * 2));
    canvas.drawParagraph(commLayout, Offset(pad, badgeY + badgeH + 14));

    final picture = recorder.endRecording();
    return picture.toImage(cardW.toInt(), cardH.toInt());
  }

  // ── Save All QR Codes to Gallery ───────────────────────────────────────
  Future<void> _saveToGallery() async {
    if (_generatedCodes.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final dir = await getTemporaryDirectory();
      int saved = 0;

      for (final code in _generatedCodes) {
        final cardImage = await _renderQrCard(code);
        final byteData =
            await cardImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('${dir.path}/qr_${code.id}.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
          await Gal.putImage(file.path);
          saved++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved QR codes saved to gallery'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving to gallery: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Generate PDF with all QR codes ────────────────────────────────────
  Future<void> _generatePdf() async {
    if (_generatedCodes.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final admin = Provider.of<AdminController>(context, listen: false);
      final community = admin.communities[widget.communityIndex];
      final pdf = pw.Document();

      // Build each QR card
      pw.Widget buildQrCard(PlantQrCode code) {
        return pw.Container(
          width: 160,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green800, width: 1.2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: code.qrData,
                width: 110,
                height: 110,
              ),
              pw.SizedBox(height: 6),
              pw.Text(code.displayLabel,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 3),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(code.id,
                    style: pw.TextStyle(
                        fontSize: 5, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(height: 3),
              pw.Text('${code.plantType} | ${code.isSeed ? "Seed" : "Plant"}',
                  style:
                      const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.center),
              pw.Text('Season: ${code.bestSeason}',
                  style:
                      const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center),
            ],
          ),
        );
      }

      // Layout: 3 columns per row, build rows manually
      const int cols = 3;
      const int rowsPerPage = 4;
      const int perPage = cols * rowsPerPage;

      for (int pageStart = 0;
          pageStart < _generatedCodes.length;
          pageStart += perPage) {
        final pageEnd = (pageStart + perPage).clamp(0, _generatedCodes.length);
        final pageCodes = _generatedCodes.sublist(pageStart, pageEnd);

        // Build rows
        final List<pw.Widget> rows = [];
        for (int r = 0; r < pageCodes.length; r += cols) {
          final rowEnd = (r + cols).clamp(0, pageCodes.length);
          final rowCodes = pageCodes.sublist(r, rowEnd);

          final rowChildren = <pw.Widget>[];
          for (final code in rowCodes) {
            rowChildren.add(buildQrCard(code));
          }
          // Fill empty cells to keep alignment
          while (rowChildren.length < cols) {
            rowChildren.add(pw.SizedBox(width: 160));
          }

          rows.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
          rows.add(pw.SizedBox(height: 10));
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('QR Codes - ${community.name}',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey)),
                  ],
                ),
                pw.Divider(color: PdfColors.green200),
                pw.SizedBox(height: 10),
                ...rows,
              ],
            ),
          ),
        );
      }

      // Save PDF bytes once
      final pdfBytes = await pdf.save();

      // Save PDF to documents
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'QR_${community.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        // Show share/print options
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: $fileName'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Upload to Database dialog ──────────────────────────────────────────
  void _showUploadDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.uploadCloud, color: cs.primary, size: 28),
        ),
        title: const Text('Upload to Database',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Do you want to upload these ${_generatedCodes.length} QR codes to the database?',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now', style: TextStyle(color: cs.onSurface)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              // Simulate upload
              setState(() => _isSaving = true);
              await Future.delayed(const Duration(seconds: 2));

              final admin =
                  Provider.of<AdminController>(context, listen: false);
              await admin.markQrCodesUploaded(widget.communityIndex);

              if (mounted) {
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${_generatedCodes.length} QR codes uploaded to database'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: cs.primary,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.uploadCloud, size: 18),
            label: const Text('Upload',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Pick & Parse CSV ───────────────────────────────────────────────────
  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        final rows = const CsvToListConverter().convert(csvString);

        setState(() {
          _csvFileName = result.files.single.name;
          _csvData = rows;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading CSV: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ── Import CSV QR Codes ─────────────────────────────────────────────────
  Future<void> _importCsvCodes() async {
    if (_csvData.isEmpty) return;

    final admin = Provider.of<AdminController>(context, listen: false);
    final community = admin.communities[widget.communityIndex];
    // Use the real Appwrite $id — NOT a slugified name.
    final communityId = community.id;

    final codes = <PlantQrCode>[];

    // Skip header row, parse remaining
    final headers =
        _csvData[0].map((h) => h.toString().trim().toLowerCase()).toList();
    final nameIdx = headers.indexOf('plant_name');
    final typeIdx = headers.indexOf('plant_type');
    final seasonIdx = headers.indexOf('season');
    final seedIdx = headers.indexOf('seed_or_plant');
    final ageIdx = headers.indexOf('age');
    final notesIdx = headers.indexOf('notes');

    for (int i = 1; i < _csvData.length; i++) {
      final row = _csvData[i];
      if (row.isNotEmpty) {
        final id = row[0].toString().trim();
        if (id.isNotEmpty) {
          final plantName = nameIdx >= 0 && row.length > nameIdx
              ? row[nameIdx].toString().trim()
              : '';
          final plantType = typeIdx >= 0 && row.length > typeIdx
              ? row[typeIdx].toString().trim()
              : 'Tree';
          final season = seasonIdx >= 0 && row.length > seasonIdx
              ? row[seasonIdx].toString().trim()
              : 'Spring';
          final seedOrPlant = seedIdx >= 0 && row.length > seedIdx
              ? row[seedIdx].toString().trim().toLowerCase()
              : 'seed';
          final age = ageIdx >= 0 && row.length > ageIdx
              ? row[ageIdx].toString().trim()
              : '';
          final notes = notesIdx >= 0 && row.length > notesIdx
              ? row[notesIdx].toString().trim()
              : '';

          codes.add(PlantQrCode(
            id: id.contains(communityId) ? id : '${communityId}_$id',
            communityId: communityId,
            communityName: community.name,
            plantName: plantName,
            plantType: plantType,
            bestSeason: season,
            isSeed: seedOrPlant != 'plant',
            plantAge: seedOrPlant == 'plant' && age.isNotEmpty && age != '-'
                ? age
                : null,
            notes: notes,
          ));
        }
      }
    }

    if (codes.isNotEmpty) {
      await admin.addQrCodes(widget.communityIndex, codes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${codes.length} QR codes imported from CSV'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Ask to upload
      _showCsvUploadDialog(codes.length);
    }
  }

  void _showCsvUploadDialog(int count) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.uploadCloud, color: cs.primary, size: 28),
        ),
        title: const Text('Upload to Database',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Do you want to upload these $count imported QR codes to the database?',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now', style: TextStyle(color: cs.onSurface)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              await Future.delayed(const Duration(seconds: 2));

              final admin =
                  Provider.of<AdminController>(context, listen: false);
              await admin.markQrCodesUploaded(widget.communityIndex);

              if (mounted) {
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count QR codes uploaded to database'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: cs.primary,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.uploadCloud, size: 18),
            label: const Text('Upload',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;

    if (widget.communityIndex < 0 ||
        widget.communityIndex >= admin.communities.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Community not found")),
      );
    }

    final community = admin.communities[widget.communityIndex];
    final existingCodes = admin.getQrCodes(widget.communityIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('QR Manager',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.5),
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(LucideIcons.qrCode), text: 'Generate QR'),
            Tab(icon: Icon(LucideIcons.fileUp), text: 'Upload CSV'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Generate QR Codes ──
              _buildGenerateTab(cs, community, existingCodes),

              // ── Tab 2: Upload CSV ──
              _buildCsvTab(cs, community),
            ],
          ),

          // Loading overlay
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: cs.primary),
                      const SizedBox(height: 16),
                      Text('Processing...',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Generate Tab ───────────────────────────────────────────────────────
  Widget _buildGenerateTab(
      ColorScheme cs, AdminCommunity community, List<PlantQrCode> existing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.qrCode,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(community.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${existing.length} QR codes generated',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quantity input
          Text('Generate QR Codes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('Each QR code gets a unique ID linked to this community',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          const SizedBox(height: 20),

          // ── Plant Information Section ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.leaf, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Plant Information',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Details encoded in each QR code',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                const SizedBox(height: 16),

                // Plant Name
                TextFormField(
                  controller: _plantNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Plant Name *',
                    hintText: 'e.g. Neem, Banyan, Tulsi',
                    prefixIcon: Icon(LucideIcons.trees, color: cs.primary),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Plant Type & Best Season – side by side
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPlantType,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Plant Type',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        items: _plantTypes
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedPlantType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSeason,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Best Season',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        items: _seasons
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSeason = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Seed or Plant toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(_isSeed ? LucideIcons.circle : LucideIcons.flower2,
                          size: 20, color: cs.primary),
                      const SizedBox(width: 10),
                      Text('Type:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface)),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: true,
                              label:
                                  Text('Seed', style: TextStyle(fontSize: 13))),
                          ButtonSegment(
                              value: false,
                              label: Text('Plant',
                                  style: TextStyle(fontSize: 13))),
                        ],
                        selected: {_isSeed},
                        onSelectionChanged: (v) =>
                            setState(() => _isSeed = v.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Plant Age – only visible when "Plant" is selected
                if (!_isSeed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: _plantAgeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Plant Age',
                        hintText: 'e.g. 2 years, 6 months',
                        prefixIcon: Icon(LucideIcons.clock, color: cs.primary),
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Any special care instructions...',
                    prefixIcon: Icon(LucideIcons.stickyNote, color: cs.primary),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity *',
                hintText: 'e.g. 10, 50, 100',
                prefixIcon: Icon(LucideIcons.hash, color: cs.primary),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a quantity';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'Must be at least 1';
                if (n > 500) return 'Maximum 500 at once';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateQrCodes,
              icon: _isGenerating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary))
                  : const Icon(LucideIcons.sparkles, size: 18),
              label: Text(_isGenerating ? 'Generating...' : 'Generate QR Codes',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generated codes preview
          if (_generatedCodes.isNotEmpty) ...[
            Row(
              children: [
                Text('Generated: ${_generatedCodes.length} codes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Ready',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QR code grid preview
            SizedBox(
              height: 340,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _generatedCodes.length,
                itemBuilder: (context, index) {
                  final code = _generatedCodes[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: QrImageView(
                            data: code.qrData,
                            version: QrVersions.auto,
                            size: 100,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0B6E4F),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(code.displayLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                        Text(
                            '${code.plantType} · ${code.isSeed ? "Seed" : "Plant"}',
                            style: TextStyle(
                                fontSize: 8,
                                color: cs.onSurface.withOpacity(0.5)),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    cs: cs,
                    icon: LucideIcons.download,
                    label: 'Save to Gallery',
                    onTap: _saveToGallery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    cs: cs,
                    icon: LucideIcons.fileText,
                    label: 'Save as PDF',
                    onTap: _generatePdf,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _actionButton(
                cs: cs,
                icon: LucideIcons.uploadCloud,
                label: 'Upload to Database',
                onTap: _showUploadDialog,
                isPrimary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CSV Upload Tab ─────────────────────────────────────────────────────
  Widget _buildCsvTab(ColorScheme cs, AdminCommunity community) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Text('CSV Format Guide',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload a CSV file with QR code IDs and plant details for bulk import. '
                  'The file should have a header row with columns for QR ID, plant name, type, season, seed/plant, age and notes.',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.6),
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Example CSV:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 6),
                      Text(
                        'qr_id, plant_name, plant_type, season, seed_or_plant, age, notes\n'
                        'NBC_001, Neem, Tree, Monsoon, Seed, -, Sector A\n'
                        'NBC_002, Banyan, Tree, Spring, Plant, 2 years, Sector B\n'
                        'NBC_003, Tulsi, Herb, Summer, Seed, -, Sector C',
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: cs.onSurface.withOpacity(0.7),
                            height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upload button
          GestureDetector(
            onTap: _pickCsvFile,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _csvFileName != null
                      ? cs.primary.withOpacity(0.5)
                      : cs.outlineVariant,
                  width: _csvFileName != null ? 2 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _csvFileName != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileCheck,
                            size: 40, color: cs.primary),
                        const SizedBox(height: 10),
                        Text(_csvFileName!,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Text('${_csvData.length - 1} records found',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 8),
                        Text('Tap to change file',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.uploadCloud,
                            size: 44, color: cs.onSurface.withOpacity(0.25)),
                        const SizedBox(height: 12),
                        Text('Tap to select CSV file',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 4),
                        Text('Supports .csv files only',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.3))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // CSV Preview
          if (_csvData.isNotEmpty) ...[
            Text('Preview',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                      cs.surfaceVariant.withOpacity(0.5)),
                  columns: _csvData.isNotEmpty
                      ? _csvData[0]
                          .map((h) => DataColumn(
                              label: Text(h.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12))))
                          .toList()
                      : [],
                  rows: _csvData
                      .skip(1)
                      .take(10) // Show max 10 preview rows
                      .map((row) => DataRow(
                          cells: row
                              .map((cell) => DataCell(Text(cell.toString(),
                                  style: const TextStyle(fontSize: 12))))
                              .toList()))
                      .toList(),
                ),
              ),
            ),
            if (_csvData.length > 11)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('... and ${_csvData.length - 11} more rows',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
              ),
            const SizedBox(height: 20),

            // Import button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _importCsvCodes,
                icon: const Icon(LucideIcons.fileInput, size: 18),
                label: Text('Import ${_csvData.length - 1} QR Codes',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? cs.primary : cs.surfaceVariant.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: isPrimary ? cs.onPrimary : cs.onSurface),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? cs.onPrimary : cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
