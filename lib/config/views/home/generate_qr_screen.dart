// lib/config/views/home/generate_qr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

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
  final _scientificNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Tree';
  bool _isGenerating = false;
  bool _qrGenerated = false;
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

  @override
  void dispose() {
    _plantNameController.dispose();
    _scientificNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'PLT-${timestamp.toString().substring(8)}-$random';
  }

  void _generateQRCode() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGenerating = true;
      });

      final auth = Provider.of<AuthController>(context, listen: false);
      _uniqueId = _generateUniqueId();

      final qrData = {
        'id': _uniqueId,
        'plantName': _plantNameController.text,
        'scientificName': _scientificNameController.text,
        'category': _selectedCategory,
        'notes': _notesController.text,
        'owner': auth.userName,
        'ownerEmail': auth.userEmail ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'gardenId': 'GARDEN-${auth.userHandle.toUpperCase()}',
      };

      _generatedQRData = jsonEncode(qrData);

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isGenerating = false;
          _qrGenerated = true;
        });
      });
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
      final file = File('${tempDir.path}/plant_qr_$_uniqueId.png');
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
                    'Plant QR Code',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
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
                _buildPdfField(
                    'Scientific Name', _scientificNameController.text),
                _buildPdfField('Category', _selectedCategory),
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
                    'SeedScan - AI-Powered Plant Management',
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
      final file = File('${output.path}/plant_qr_$_uniqueId.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() => _isGenerating = false);

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Plant QR Code - $_uniqueId',
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
          'Generate Plant QR Code',
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
                          'Create Plant QR Code',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Fill in the details to generate a unique QR code for your plant',
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

            // Scientific Name
            Text(
              'Scientific Name',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _scientificNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Epipremnum aureum',
                prefixIcon: const Icon(LucideIcons.flaskConical),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                        'QR Code Generated!',
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
                  if (_scientificNameController.text.isNotEmpty)
                    Text(
                      _scientificNameController.text,
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
                _buildDetailRow(
                    'Category', _selectedCategory, LucideIcons.tags),
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
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _qrGenerated = false;
                  _formKey.currentState!.reset();
                  _plantNameController.clear();
                  _scientificNameController.clear();
                  _notesController.clear();
                  _selectedCategory = 'Tree';
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
