// lib/config/views/home/generate_qr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../../services/database_service.dart';
import '../../../models/my_garden_qr_model.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _qrKey = GlobalKey();

  // Form fields
  final _plantNameController = TextEditingController();
  final _localNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _plantAgeController = TextEditingController();

  String _selectedCategory = 'Tree';
  String _selectedSeason = 'Spring';
  String _selectedQrType = 'Seed'; // 'Seed' or 'Plant'
  bool _isGenerating = false;
  bool _qrGenerated = false;
  bool _savedToDb = false;
  bool _isSavingToDb = false;
  String _generatedQRData = '';
  String _uniqueId = '';

  final List<String> _categories = [
    'Tree',
    'Shrub',
    'Herb',
    'Flower',
    'Vegetable',
    'Fruit',
    'Other'
  ];

  final List<String> _seasons = [
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
    'All Year',
  ];

  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _plantNameController.dispose();
    _localNameController.dispose();
    _notesController.dispose();
    _plantAgeController.dispose();
    super.dispose();
  }

  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'MYGARDEN-${timestamp.toString().substring(5)}-$random';
  }

  Future<void> _generateQRCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGenerating = true;
      });

      final auth = Provider.of<AuthController>(context, listen: false);
      _uniqueId = _generateUniqueId();

      final gardenId = 'GARDEN-${auth.userHandle.toUpperCase()}';

      final qrModel = MyGardenQRModel(
        id: '',
        uniqueCode: _uniqueId,
        plantName: _plantNameController.text.trim(),
        localName: _localNameController.text.trim(),
        category: _selectedCategory,
        bestSeason: _selectedSeason,
        qrType: _selectedQrType,
        plantAge:
            _selectedQrType == 'Plant' ? _plantAgeController.text.trim() : null,
        notes: _notesController.text.trim(),
        ownerId: auth.userId ?? '',
        ownerName: auth.userName,
        ownerEmail: auth.userEmail ?? '',
        gardenId: gardenId,
        source: 'my_garden',
        createdAt: DateTime.now(),
      );

      _generatedQRData = jsonEncode(qrModel.toQrPayload());

      setState(() {
        _isGenerating = false;
        _qrGenerated = true;
        _savedToDb = false;
      });
    }
  }

  /// Upload / save the generated QR code to the database explicitly.
  Future<void> _uploadToDatabase() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final gardenId = 'GARDEN-${auth.userHandle.toUpperCase()}';

    setState(() => _isSavingToDb = true);
    try {
      await _dbService.createMyGardenQR(
        uniqueCode: _uniqueId,
        plantName: _plantNameController.text.trim(),
        localName: _localNameController.text.trim(),
        category: _selectedCategory,
        bestSeason: _selectedSeason,
        qrType: _selectedQrType,
        plantAge:
            _selectedQrType == 'Plant' ? _plantAgeController.text.trim() : null,
        notes: _notesController.text.trim(),
        ownerId: auth.userId ?? '',
        ownerName: auth.userName,
        ownerEmail: auth.userEmail ?? '',
        gardenId: gardenId,
      );
      setState(() {
        _isSavingToDb = false;
        _savedToDb = true;
      });
      _showSuccessDialog('QR Code uploaded to your My Garden database!');
    } catch (e) {
      setState(() => _isSavingToDb = false);
      _showErrorDialog('Error uploading QR Code: $e');
    }
  }

  Future<void> _saveQRAsImage() async {
    try {
      setState(() => _isGenerating = true);

      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mygarden_qr_$_uniqueId.png');
      await file.writeAsBytes(pngBytes);

      // Save to gallery using gal package
      await Gal.putImage(file.path, album: 'SeedScan');

      setState(() => _isGenerating = false);
      _showSuccessDialog('QR Code saved to gallery successfully!');
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorDialog('Error saving QR Code: $e');
    }
  }

  Future<void> _saveQRAsPDF() async {
    try {
      setState(() => _isGenerating = true);

      final pdf = pw.Document();
      final auth = Provider.of<AuthController>(context, listen: false);

      // Generate QR code image for PDF
      final qrValidationResult = QrValidator.validate(
        data: _generatedQRData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final picData = await painter.toImageData(500);
      final imageBytes = picData!.buffer.asUint8List();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'My Garden - Plant QR Code',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green),
                  ),
                  child: pw.Text(
                    'Source: MY GARDEN  |  Type: $_selectedQrType',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Plant Details',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                _buildPdfField('Unique ID', _uniqueId),
                _buildPdfField('Plant Name', _plantNameController.text),
                _buildPdfField('Local Name', _localNameController.text),
                _buildPdfField('Category', _selectedCategory),
                _buildPdfField('Best Season', _selectedSeason),
                _buildPdfField('QR Type', _selectedQrType),
                if (_selectedQrType == 'Plant')
                  _buildPdfField('Plant Age', _plantAgeController.text),
                _buildPdfField('Notes', _notesController.text),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                _buildPdfField('Owner', auth.userName),
                _buildPdfField(
                    'Garden ID', 'GARDEN-${auth.userHandle.toUpperCase()}'),
                _buildPdfField(
                    'Generated', DateTime.now().toString().substring(0, 19)),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'SeedScan - AI-Powered Plant Management | My Garden QR',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/mygarden_qr_$_uniqueId.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() => _isGenerating = false);

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Garden QR Code - $_uniqueId',
        text: 'Plant: ${_plantNameController.text}',
      );

      _showSuccessDialog('PDF generated and ready to share!');
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorDialog('Error generating PDF: $e');
    }
  }

  pw.Widget _buildPdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon:
            const Icon(LucideIcons.checkCircle, color: Colors.green, size: 48),
        title: Text(
          'Success',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
        title: Text(
          'Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Garden QR Code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: _qrGenerated ? _buildQRView(cs) : _buildFormView(cs),
    );
  }

  Widget _buildFormView(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.qrCode, size: 40, color: cs.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Garden QR Code',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Generate a unique QR code for your personal garden plant or seed',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── QR Type (Seed / Plant) ─────────────────────────
            Text(
              'QR Code For *',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    label: 'Seed',
                    icon: LucideIcons.sprout,
                    isSelected: _selectedQrType == 'Seed',
                    cs: cs,
                    onTap: () {
                      setState(() {
                        _selectedQrType = 'Seed';
                        _plantAgeController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip(
                    label: 'Plant',
                    icon: LucideIcons.flower2,
                    isSelected: _selectedQrType == 'Plant',
                    cs: cs,
                    onTap: () {
                      setState(() => _selectedQrType = 'Plant');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Plant Age (only when type = Plant) ──────────────
            if (_selectedQrType == 'Plant') ...[
              Text(
                'Plant Age *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _plantAgeController,
                decoration: InputDecoration(
                  hintText: 'e.g., 2 years, 6 months',
                  prefixIcon: const Icon(LucideIcons.clock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (_selectedQrType == 'Plant' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter the plant age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Plant Name
            Text(
              'Plant Name *',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _plantNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Golden Pothos',
                prefixIcon: const Icon(LucideIcons.leaf),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter plant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Local Name (replaces Scientific Name)
            Text(
              'Local Name *',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _localNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Money Plant, Neem, Tulsi',
                prefixIcon: const Icon(LucideIcons.languages),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter local name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Category *',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.tags),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),

            // Best Season for Plantation
            Text(
              'Best Season for Plantation *',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.sun),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _seasons.map((season) {
                return DropdownMenuItem(
                  value: season,
                  child: Text(season),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedSeason = value!);
              },
            ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Additional information...',
                prefixIcon: const Icon(LucideIcons.fileText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateQRCode,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.qrCode),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate QR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withOpacity(0.15)
              : cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView(ColorScheme cs) {
    final auth = Provider.of<AuthController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Garden QR Code Generated!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        'ID: $_uniqueId',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Code Card
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // MY GARDEN badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.home,
                            size: 14, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'MY GARDEN',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seed / Plant type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedQrType == 'Seed'
                          ? Colors.amber.shade50
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedQrType == 'Seed'
                            ? Colors.amber.shade400
                            : Colors.teal.shade400,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedQrType == 'Seed'
                              ? LucideIcons.sprout
                              : LucideIcons.flower2,
                          size: 14,
                          color: _selectedQrType == 'Seed'
                              ? Colors.amber.shade800
                              : Colors.teal.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedQrType.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedQrType == 'Seed'
                                ? Colors.amber.shade800
                                : Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  QrImageView(
                    data: _generatedQRData,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _plantNameController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_localNameController.text.isNotEmpty)
                    Text(
                      _localNameController.text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _uniqueId,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Garden: GARDEN-${auth.userHandle.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Plant Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Local Name', _localNameController.text,
                    LucideIcons.languages),
                _buildDetailRow(
                    'Category', _selectedCategory, LucideIcons.tags),
                _buildDetailRow(
                    'Best Season', _selectedSeason, LucideIcons.sun),
                _buildDetailRow(
                    'Type',
                    _selectedQrType,
                    _selectedQrType == 'Seed'
                        ? LucideIcons.sprout
                        : LucideIcons.flower2),
                if (_selectedQrType == 'Plant' &&
                    _plantAgeController.text.isNotEmpty)
                  _buildDetailRow(
                      'Plant Age', _plantAgeController.text, LucideIcons.clock),
                if (_notesController.text.isNotEmpty)
                  _buildDetailRow(
                      'Notes', _notesController.text, LucideIcons.fileText),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _saveQRAsImage,
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Save Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _saveQRAsPDF,
                  icon: const Icon(LucideIcons.filePlus),
                  label: const Text('Save PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload to Database Button
          SizedBox(
            width: double.infinity,
            child: _savedToDb
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle,
                            size: 20, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Saved to My Garden Database',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isSavingToDb ? null : _uploadToDatabase,
                    icon: _isSavingToDb
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.upload),
                    label: Text(
                      _isSavingToDb
                          ? 'Uploading...'
                          : 'Upload to My Garden Database',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _qrGenerated = false;
                  _savedToDb = false;
                  _isSavingToDb = false;
                  _formKey.currentState!.reset();
                  _plantNameController.clear();
                  _localNameController.clear();
                  _notesController.clear();
                  _plantAgeController.clear();
                  _selectedCategory = 'Tree';
                  _selectedSeason = 'Spring';
                  _selectedQrType = 'Seed';
                });
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Generate Another'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
