// lib/config/views/home/my_garden_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/auth_controller.dart';
import '../common/plant_card.dart';
import 'qr_scanner_screen.dart';
import 'generate_qr_screen.dart';
import '../../../services/database_service.dart';
import '../../../models/my_garden_qr_model.dart';

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Database integration
  final DatabaseService _dbService = DatabaseService();
  List<MyGardenQRModel> _myGardenQRCodes = [];
  bool _isLoadingQRCodes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadMyGardenQRCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyGardenQRCodes() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) return;

    setState(() => _isLoadingQRCodes = true);
    try {
      final codes = await _dbService.listMyGardenQRCodes(userId);
      setState(() {
        _myGardenQRCodes = codes;
        _isLoadingQRCodes = false;
      });
    } catch (e) {
      debugPrint('Error loading My Garden QR codes: $e');
      setState(() => _isLoadingQRCodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scanController = Provider.of<ScanController>(context);
    final auth = Provider.of<AuthController>(context);
    final plants = scanController.getMyPlants();

    // Filter plants based on search and filter
    final filteredPlants = plants.where((plant) {
      final matchesSearch =
          plant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              plant.scientificName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == 'All' || plant.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    // Count plants by status
    final healthyCount = plants.where((p) => p.status == 'Healthy').length;
    final needsAttentionCount =
        plants.where((p) => p.status == 'Needs Water').length;
    final allCount = plants.length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'My Garden',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.primaryContainer,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        LucideIcons.leaf,
                        size: 120,
                        color: cs.onPrimary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.qrCode),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GenerateQRScreen(),
                    ),
                  );
                  // Refresh QR codes list after returning
                  _loadMyGardenQRCodes();
                },
                tooltip: 'Generate QR Code',
              ),
              IconButton(
                icon: const Icon(LucideIcons.search),
                onPressed: () => _showSearchDialog(context),
              ),
              IconButton(
                icon: const Icon(LucideIcons.filter),
                onPressed: () => _showFilterDialog(context),
              ),
            ],
          ),

          // Header Stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primary.withOpacity(0.2),
                        child: Icon(
                          LucideIcons.user,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${auth.userName}\'s Garden',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${plants.length} plants growing strong',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        context,
                        icon: LucideIcons.sprout,
                        label: 'All',
                        count: allCount,
                        color: Colors.blue,
                      ),
                      _buildStatChip(
                        context,
                        icon: LucideIcons.heartPulse,
                        label: 'Healthy',
                        count: healthyCount,
                        color: Colors.green,
                      ),
                      _buildStatChip(
                        context,
                        icon: LucideIcons.alertCircle,
                        label: 'Attention',
                        count: needsAttentionCount,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurface.withOpacity(0.6),
                indicatorColor: cs.primary,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'All Plants'),
                  Tab(text: 'Healthy'),
                  Tab(text: 'Needs Care'),
                  Tab(text: 'My QR Codes'),
                ],
              ),
            ),
          ),

          // Plants List / QR Codes List (based on tab)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: _tabController.index == 3
                ? _buildQRCodesSliver(cs)
                : (filteredPlants.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plant = filteredPlants[index];
                            return _buildPlantCard(
                                context, plant, scanController);
                          },
                          childCount: filteredPlants.length,
                        ),
                      )),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my_garden_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );
        },
        icon: const Icon(LucideIcons.scanLine),
        label: Text(
          'Scan QR',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// Smart image builder: uses Image.file for local paths, Image.network for URLs.
  Widget _buildPlantImage(
    String imagePath, {
    double? width,
    double? height,
    required ColorScheme cs,
  }) {
    final isLocal = imagePath.startsWith('/') ||
        imagePath.startsWith('C:') ||
        imagePath.contains('\\');
    if (isLocal && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => _imagePlaceholder(width, height, cs),
      );
    }
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => _imagePlaceholder(width, height, cs),
    );
  }

  Widget _imagePlaceholder(double? width, double? height, ColorScheme cs) {
    return Container(
      width: width,
      height: height,
      color: cs.surfaceContainerHighest,
      child: Icon(LucideIcons.flower2, size: 40, color: cs.onSurfaceVariant),
    );
  }

  Widget _buildPlantCard(
      BuildContext context, PlantModel plant, ScanController controller) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showPlantDetails(context, plant),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cs.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Plant Image
              Hero(
                tag: 'plant_${plant.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildPlantImage(
                    plant.image,
                    width: 80,
                    height: 80,
                    cs: cs,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Plant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: plant.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plant.status,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: plant.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.scanLine,
                          size: 14,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scanned ${plant.lastScan}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.flower2,
              size: 80,
              color: cs.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'No plants found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding plants to your garden\nby scanning them!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QRScannerScreen()),
                );
              },
              icon: const Icon(LucideIcons.scanLine),
              label: const Text('Scan Plant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodesSliver(ColorScheme cs) {
    if (_isLoadingQRCodes) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_myGardenQRCodes.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.qrCode,
                  size: 80,
                  color: cs.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 20),
                Text(
                  'No QR Codes Yet',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate QR codes for your plants\nand seeds to track them!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GenerateQRScreen()),
                    );
                    _loadMyGardenQRCodes();
                  },
                  icon: const Icon(LucideIcons.qrCode),
                  label: const Text('Generate QR Code'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final qr = _myGardenQRCodes[index];
          return _buildQRCodeCard(context, qr, cs);
        },
        childCount: _myGardenQRCodes.length,
      ),
    );
  }

  Widget _buildQRCodeCard(
      BuildContext context, MyGardenQRModel qr, ColorScheme cs) {
    final isPlant = qr.qrType == 'Plant';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _showQRCodeDetails(context, qr),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isPlant
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPlant ? LucideIcons.flower2 : LucideIcons.sprout,
                  size: 28,
                  color: isPlant ? Colors.teal : Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            qr.plantName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPlant
                                ? Colors.teal.withOpacity(0.1)
                                : Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            qr.qrType,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  isPlant ? Colors.teal : Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qr.localName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.sun,
                            size: 13, color: cs.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          qr.bestSeason,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                        ),
                        if (isPlant && qr.plantAge != null) ...[
                          const SizedBox(width: 12),
                          Icon(LucideIcons.clock,
                              size: 13, color: cs.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            qr.plantAge!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCodeDetails(BuildContext context, MyGardenQRModel qr) {
    final cs = Theme.of(context).colorScheme;
    final isPlant = qr.qrType == 'Plant';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // MY GARDEN badge
                  Center(
                    child: Container(
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
                  ),
                  const SizedBox(height: 16),

                  // Plant Name
                  Text(
                    qr.plantName,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    qr.localName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Type & Season badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isPlant
                              ? Colors.teal.withOpacity(0.1)
                              : Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlant
                                  ? LucideIcons.flower2
                                  : LucideIcons.sprout,
                              size: 16,
                              color:
                                  isPlant ? Colors.teal : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              qr.qrType,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isPlant
                                    ? Colors.teal
                                    : Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          qr.category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _qrDetailRow(context,
                      icon: LucideIcons.hash,
                      label: 'Unique ID',
                      value: qr.uniqueCode),
                  _qrDetailRow(context,
                      icon: LucideIcons.sun,
                      label: 'Best Season',
                      value: qr.bestSeason),
                  if (isPlant && qr.plantAge != null)
                    _qrDetailRow(context,
                        icon: LucideIcons.clock,
                        label: 'Plant Age',
                        value: qr.plantAge!),
                  _qrDetailRow(context,
                      icon: LucideIcons.home,
                      label: 'Garden ID',
                      value: qr.gardenId),
                  _qrDetailRow(context,
                      icon: LucideIcons.user,
                      label: 'Owner',
                      value: qr.ownerName),
                  if (qr.notes.isNotEmpty)
                    _qrDetailRow(context,
                        icon: LucideIcons.fileText,
                        label: 'Notes',
                        value: qr.notes),
                  _qrDetailRow(context,
                      icon: LucideIcons.calendar,
                      label: 'Created',
                      value: qr.createdAt.toString().substring(0, 16)),

                  const SizedBox(height: 24),

                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete QR Code'),
                          content: Text(
                              'Are you sure you want to delete "${qr.plantName}" QR code?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _dbService.deleteMyGardenQR(qr.id);
                          if (context.mounted) Navigator.pop(context);
                          _loadMyGardenQRCodes();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    label: const Text('Delete QR Code',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _qrDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Search Plants',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter plant name...',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Filter Plants',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterOption('All', context),
              _filterOption('Healthy', context),
              _filterOption('Needs Water', context),
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption(String filter, BuildContext context) {
    return RadioListTile<String>(
      title: Text(filter),
      value: filter,
      groupValue: _selectedFilter,
      onChanged: (value) {
        setState(() => _selectedFilter = value!);
        Navigator.pop(context);
      },
    );
  }

  void _showPlantDetails(BuildContext context, PlantModel plant) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Plant Image
                  Hero(
                    tag: 'plant_${plant.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildPlantImage(
                        plant.image,
                        height: 250,
                        width: double.infinity,
                        cs: cs,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plant Name
                  Text(
                    plant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.scientificName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: plant.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              plant.status == 'Healthy'
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.alertCircle,
                              size: 16,
                              color: plant.statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              plant.status,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: plant.statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Plant Details
                  _detailRow(
                    context,
                    icon: LucideIcons.scanLine,
                    label: 'Last Scanned',
                    value: plant.lastScan,
                  ),
                  _detailRow(
                    context,
                    icon: LucideIcons.hash,
                    label: 'Plant ID',
                    value: plant.id,
                  ),
                  const SizedBox(height: 16),
                  // Location Card - Tappable to open Google Maps
                  if (plant.location != null)
                    InkWell(
                      onTap: () async {
                        if (plant.latitude != null && plant.longitude != null) {
                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${plant.latitude},${plant.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open Google Maps',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 24,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plant.location!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  if (plant.latitude != null &&
                                      plant.longitude != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${plant.latitude!.toStringAsFixed(4)}, Lng: ${plant.longitude!.toStringAsFixed(4)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: cs.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to open in Google Maps',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blue.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.externalLink,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showImageSourcePicker(context, plant);
                    },
                    icon: const Icon(LucideIcons.upload),
                    label: const Text('Update Plant Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final scanController = Provider.of<ScanController>(
                        context,
                        listen: false,
                      );

                      try {
                        final result =
                            await scanController.updatePlantLocation(plant.id);

                        if (context.mounted) {
                          if (result['success']) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Location updated successfully!\nLat: ${result['latitude'].toStringAsFixed(4)}, Lng: ${result['longitude'].toStringAsFixed(4)}',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['error'] ??
                                      'Failed to update location',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }

                          // Close modal after showing snackbar
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString()}',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );

                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.mapPin),
                    label: const Text('Update Location'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context, PlantModel plant) {
    final scanController = Provider.of<ScanController>(context, listen: false);
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Update Plant Image',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a source to update the plant image',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ImageSourceButton(
                        icon: LucideIcons.camera,
                        label: 'Camera',
                        onTap: () async {
                          Navigator.pop(context);
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1200,
                            maxHeight: 1200,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            final result = await scanController
                                .updatePlantImage(plant.id, image.path);
                            if (context.mounted) {
                              final now = DateTime.now();
                              final timeStr =
                                  '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['success'] == true
                                        ? 'Plant image updated & saved to database at $timeStr'
                                        : 'Image updated locally (upload failed: ${result['error']})',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: result['success'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _ImageSourceButton(
                        icon: LucideIcons.image,
                        label: 'Gallery',
                        onTap: () async {
                          Navigator.pop(context);
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            final result = await scanController
                                .updatePlantImage(plant.id, image.path);
                            if (context.mounted) {
                              final now = DateTime.now();
                              final timeStr =
                                  '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['success'] == true
                                        ? 'Plant image updated & saved to database at $timeStr'
                                        : 'Image updated locally (upload failed: ${result['error']})',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: result['success'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Image Source Button Widget
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF0B6E4F).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B6E4F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B6E4F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
