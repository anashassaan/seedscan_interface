import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/admin_controller.dart';
import 'community_details_view.dart';

class ManageCommunitiesView extends StatefulWidget {
  const ManageCommunitiesView({super.key});

  @override
  State<ManageCommunitiesView> createState() => _ManageCommunitiesViewState();
}

class _ManageCommunitiesViewState extends State<ManageCommunitiesView> {
  String _searchQuery = '';

  List<AdminCommunity> _filtered(List<AdminCommunity> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.location.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            c.createdBy.toLowerCase().contains(q))
        .toList();
  }

  // ── Create Community Bottom-Sheet ──────────────────────────────────────
  void _showCreateCommunitySheet(BuildContext context) {
    final admin = Provider.of<AdminController>(context, listen: false);
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final creatorCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'General';
    File? selectedImage;
    String? imageError;

    final categories = [
      'General',
      'Reforestation',
      'Urban Gardening',
      'Agriculture',
      'Research',
      'Education',
    ];

    Future<void> pickImage(
        StateSetter setSheetState, ImageSource source) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setSheetState(() {
          selectedImage = File(picked.path);
          imageError = null;
        });
      }
    }

    void showImageSourceDialog(StateSetter setSheetState) {
      final cs = Theme.of(context).colorScheme;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text('Choose Image Source',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceOption(
                      cs: cs,
                      icon: LucideIcons.image,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        pickImage(setSheetState, ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _imageSourceOption(
                      cs: cs,
                      icon: LucideIcons.camera,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        pickImage(setSheetState, ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(LucideIcons.plus, color: cs.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('New Community',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface)),
                                  Text('Create a new gardening community',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              cs.onSurface.withOpacity(0.6))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Image Picker ──
                        GestureDetector(
                          onTap: () => showImageSourceDialog(setSheetState),
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: imageError != null
                                    ? cs.error
                                    : cs.outlineVariant.withOpacity(0.5),
                                width: imageError != null ? 1.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: selectedImage != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                      // Overlay with change button
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: InkWell(
                                            onTap: () => showImageSourceDialog(
                                                setSheetState),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(LucideIcons.camera,
                                                      size: 14,
                                                      color: Colors.white),
                                                  SizedBox(width: 6),
                                                  Text('Change',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.imagePlus,
                                          size: 40,
                                          color: imageError != null
                                              ? cs.error.withOpacity(0.5)
                                              : cs.onSurface.withOpacity(0.25)),
                                      const SizedBox(height: 10),
                                      Text('Tap to add community image *',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: imageError != null
                                                  ? cs.error
                                                  : cs.onSurface
                                                      .withOpacity(0.4),
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text('Gallery or Camera',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurface
                                                  .withOpacity(0.3))),
                                    ],
                                  ),
                          ),
                        ),
                        if (imageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(imageError!,
                                style:
                                    TextStyle(fontSize: 12, color: cs.error)),
                          ),
                        const SizedBox(height: 16),

                        // ── Name field ──
                        TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Community Name *',
                            hintText: 'e.g. Green Valley',
                            prefixIcon:
                                Icon(LucideIcons.users, color: cs.primary),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Community name is required';
                            }
                            if (v.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Location field ──
                        TextFormField(
                          controller: locationCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Location *',
                            hintText: 'e.g. Northern Sector',
                            prefixIcon:
                                Icon(LucideIcons.mapPin, color: cs.primary),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Location is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Creator Name field ──
                        TextFormField(
                          controller: creatorCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Creator Name *',
                            hintText: 'e.g. John Doe',
                            prefixIcon:
                                Icon(LucideIcons.userCheck, color: cs.primary),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Creator name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Category Dropdown ──
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon:
                                Icon(LucideIcons.tag, color: cs.primary),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
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
                          items: categories
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => selectedCategory = v);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Description field ──
                        TextFormField(
                          controller: descCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            hintText:
                                'Describe the community\'s mission and goals...',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 60),
                              child:
                                  Icon(LucideIcons.fileText, color: cs.primary),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
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
                        ),
                        const SizedBox(height: 28),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: cs.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  // Validate image separately
                                  bool imageValid = selectedImage != null;
                                  if (!imageValid) {
                                    setSheetState(() {
                                      imageError =
                                          'Community image is required';
                                    });
                                  }
                                  if (formKey.currentState!.validate() &&
                                      imageValid) {
                                    final success = await admin.addCommunity(
                                      name: nameCtrl.text.trim(),
                                      location: locationCtrl.text.trim(),
                                      description: descCtrl.text.trim(),
                                      createdBy: creatorCtrl.text.trim(),
                                      imagePath: selectedImage!.path,
                                      category: selectedCategory,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${nameCtrl.text.trim()} created successfully'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          backgroundColor: cs.primary,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(admin.errorMessage ??
                                              'Failed to create community'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(LucideIcons.plus, size: 18),
                                label: const Text('Create Community',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _imageSourceOption({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: cs.primary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation Dialog ─────────────────────────────────────────
  void _confirmDelete(BuildContext context, AdminController admin, int index) {
    final cs = Theme.of(context).colorScheme;
    final community = admin.communities[index];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.trash2, color: cs.onErrorContainer),
        ),
        title: const Text('Delete Community',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Are you sure you want to delete '),
            TextSpan(
                text: community.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: '? This action cannot be undone.'),
          ]),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurface)),
          ),
          FilledButton(
            onPressed: () async {
              await admin.deleteCommunity(index);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${community.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: cs.error,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete',
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
    final communities = admin.communities;
    final filtered = _filtered(communities);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ═══════════ STATIC GREEN HEADER ═══════════
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0BA360),
                  Color(0xFF3CBA92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0BA360).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.globe2,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Communities',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Manage your plant communities',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats row
                Row(
                  children: [
                    _headerStat(communities.length.toString(), 'Communities',
                        LucideIcons.globe2),
                    const SizedBox(width: 12),
                    _headerStat(admin.totalUsers.toString(), 'Members',
                        LucideIcons.users),
                    const SizedBox(width: 12),
                    _headerStat(
                        communities
                            .fold<int>(
                                0,
                                (sum, c) =>
                                    sum +
                                    c.members.fold<int>(
                                        0, (s, u) => s + u.totalCoins))
                            .toString(),
                        'Coins',
                        LucideIcons.coins),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════ SCROLLABLE CONTENT ═══════════
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search communities...',
                        prefixIcon: Icon(LucideIcons.search,
                            color: cs.onSurface.withOpacity(0.5)),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Empty state ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.globe,
                              size: 64, color: cs.onSurface.withOpacity(0.15)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No communities yet'
                                : 'No results for "$_searchQuery"',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tap + below to create your first community'
                                : 'Try a different search term',
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Community list ──
                if (filtered.isNotEmpty)
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final community = filtered[index];
                          final actualIndex = communities.indexOf(community);
                          final memberCount = community.members.length;
                          final totalCoins = community.members
                              .fold<int>(0, (sum, u) => sum + u.totalCoins);
                          final daysSinceCreated = DateTime.now()
                              .difference(community.createdAt)
                              .inDays;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityDetailsView(
                                        communityIndex: actualIndex),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: cs.outlineVariant, width: 1),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Community Image Banner ──
                                      if (community.displayImage != null)
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(17)),
                                          child: community.hasNetworkImage
                                              ? Image.network(
                                                  community.imageUrl!,
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    height: 80,
                                                    color: cs.primaryContainer
                                                        .withOpacity(0.3),
                                                    child: Center(
                                                      child: Icon(
                                                          LucideIcons.image,
                                                          color: cs.primary
                                                              .withOpacity(0.4),
                                                          size: 28),
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(community.imagePath!),
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    height: 80,
                                                    color: cs.primaryContainer
                                                        .withOpacity(0.3),
                                                    child: Center(
                                                      child: Icon(
                                                          LucideIcons.image,
                                                          color: cs.primary
                                                              .withOpacity(0.4),
                                                          size: 28),
                                                    ),
                                                  ),
                                                ),
                                        ),

                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Top row: name + status + actions
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: cs.primaryContainer
                                                        .withOpacity(0.4),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Icon(LucideIcons.trees,
                                                      color: cs.primary,
                                                      size: 22),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                                community.name,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: cs
                                                                        .onSurface)),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: community
                                                                      .isActive
                                                                  ? Colors.green
                                                                      .withOpacity(
                                                                          0.12)
                                                                  : cs.errorContainer
                                                                      .withOpacity(
                                                                          0.6),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              community.isActive
                                                                  ? 'Active'
                                                                  : 'Inactive',
                                                              style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: community.isActive
                                                                      ? Colors
                                                                          .green
                                                                          .shade700
                                                                      : cs.error),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                              LucideIcons
                                                                  .mapPin,
                                                              size: 13,
                                                              color: cs
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.5)),
                                                          const SizedBox(
                                                              width: 4),
                                                          Flexible(
                                                            child: Text(
                                                                community
                                                                    .location,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: cs
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.5))),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(LucideIcons.trash2,
                                                      size: 18,
                                                      color: cs.error
                                                          .withOpacity(0.7)),
                                                  onPressed: () =>
                                                      _confirmDelete(context,
                                                          admin, actualIndex),
                                                  tooltip: 'Delete',
                                                ),
                                                Icon(LucideIcons.chevronRight,
                                                    size: 20,
                                                    color: cs.onSurface
                                                        .withOpacity(0.3)),
                                              ],
                                            ),

                                            // ── Description ──
                                            if (community
                                                .description.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                community.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6),
                                                    height: 1.4),
                                              ),
                                            ],

                                            const SizedBox(height: 12),

                                            // ── Meta info row: creator + category + date ──
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 6,
                                              children: [
                                                _buildMetaInfo(
                                                    context,
                                                    LucideIcons.userCheck,
                                                    community.createdBy),
                                                _buildMetaInfo(
                                                    context,
                                                    LucideIcons.tag,
                                                    community.category),
                                                _buildMetaInfo(
                                                    context,
                                                    LucideIcons.calendar,
                                                    daysSinceCreated == 0
                                                        ? 'Today'
                                                        : '${daysSinceCreated}d ago'),
                                              ],
                                            ),

                                            const SizedBox(height: 12),

                                            // Stats chips
                                            Row(
                                              children: [
                                                _buildChip(
                                                    context,
                                                    LucideIcons.users,
                                                    '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                                                    cs.primaryContainer,
                                                    cs.onPrimaryContainer),
                                                const SizedBox(width: 10),
                                                _buildChip(
                                                    context,
                                                    LucideIcons.coins,
                                                    '$totalCoins Coins',
                                                    cs.tertiaryContainer,
                                                    cs.onTertiaryContainer),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB: Create Community ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCommunitySheet(context),
        backgroundColor: const Color(0xFF0BA360),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Community',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header stat pill ──
  Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
