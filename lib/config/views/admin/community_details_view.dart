import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../controllers/admin_controller.dart';
import 'qr_code_manager_view.dart';

class CommunityDetailsView extends StatelessWidget {
  final int communityIndex;
  const CommunityDetailsView({super.key, required this.communityIndex});

  // ── Add Member Dialog ──────────────────────────────────────────────────
  void _showAddMemberSheet(BuildContext context) {
    final admin = Provider.of<AdminController>(context, listen: false);
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Form(
              key: formKey,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(LucideIcons.userPlus, color: cs.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Member',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface)),
                            Text('Add a new user to this community',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. John Doe',
                      prefixIcon: Icon(LucideIcons.user, color: cs.primary),
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
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. john@example.com',
                      prefixIcon: Icon(LucideIcons.mail, color: cs.primary),
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
                      if (v == null || v.trim().isEmpty)
                        return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              admin.addUserToCommunity(
                                communityIndex,
                                nameCtrl.text.trim(),
                                emailCtrl.text.trim(),
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${nameCtrl.text.trim()} added successfully'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: cs.primary,
                                ),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.userPlus, size: 18),
                          label: const Text('Add Member',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
          ),
        );
      },
    );
  }

  // ── Remove Member Confirmation ─────────────────────────────────────────
  void _confirmRemoveMember(
      BuildContext context, AdminController admin, int userIndex, String name) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text.rich(TextSpan(children: [
          const TextSpan(text: 'Remove '),
          TextSpan(
              text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const TextSpan(text: ' from this community?'),
        ])),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurface)),
          ),
          FilledButton(
            onPressed: () {
              admin.removeUserFromCommunity(communityIndex, userIndex);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Remove',
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

    // Safety Check
    if (communityIndex < 0 || communityIndex >= admin.communities.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle,
                  size: 48, color: cs.error.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text("Community not found",
                  style: TextStyle(
                      fontSize: 16, color: cs.onSurface.withOpacity(0.6))),
            ],
          ),
        ),
      );
    }

    final community = admin.communities[communityIndex];
    final totalCoins =
        community.members.fold<int>(0, (sum, u) => sum + u.totalCoins);
    final totalPlants = community.members.fold<int>(
        0,
        (sum, u) =>
            sum + u.stats.fold<int>(0, (s, stat) => s + (stat.count ?? 0)));

    return Scaffold(
      appBar: AppBar(
        title: Text(community.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () => _showAddMemberSheet(context),
            tooltip: 'Add Member',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Community Image Banner ──
          if (community.imagePath != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: cs.surfaceVariant.withOpacity(0.3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(community.imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(LucideIcons.image,
                      size: 36, color: cs.onSurface.withOpacity(0.15)),
                ),
              ),
            ),

          // ── Community header card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Container(
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
                  // Location row
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin,
                          size: 16, color: cs.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 6),
                      Text(community.location,
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withOpacity(0.6))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: community.isActive
                              ? Colors.green.withOpacity(0.12)
                              : cs.errorContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          community.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: community.isActive
                                  ? Colors.green.shade700
                                  : cs.error),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (community.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(community.description,
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.6),
                            height: 1.4)),
                  ],

                  const SizedBox(height: 12),

                  // Meta info: creator, category, created date
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _buildMetaInfo(
                          context, LucideIcons.userCheck, community.createdBy),
                      _buildMetaInfo(
                          context, LucideIcons.tag, community.category),
                      _buildMetaInfo(context, LucideIcons.calendar,
                          '${community.createdAt.day}/${community.createdAt.month}/${community.createdAt.year}'),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: _buildMiniStat(context, LucideIcons.users,
                            '${community.members.length}', 'Members'),
                      ),
                      Flexible(
                        child: _buildMiniStat(
                            context, LucideIcons.coins, '$totalCoins', 'Coins'),
                      ),
                      Flexible(
                        child: _buildMiniStat(context, LucideIcons.leaf,
                            '$totalPlants', 'Plants'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── QR Code Manager Action ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Material(
              color: cs.surfaceVariant.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QrCodeManagerView(communityIndex: communityIndex),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(LucideIcons.qrCode,
                            color: cs.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('QR Manager',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Generate QR codes or bulk import via CSV',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withOpacity(0.55))),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight,
                          size: 20, color: cs.onSurface.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text('Members',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${community.members.length}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ],
            ),
          ),

          // ── Member list ──
          Expanded(
            child: community.members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.userX,
                            size: 52, color: cs.onSurface.withOpacity(0.12)),
                        const SizedBox(height: 12),
                        Text("No members yet",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.4))),
                        const SizedBox(height: 4),
                        Text("Tap + to add the first member",
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.3))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: community.members.length,
                    itemBuilder: (context, userIndex) {
                      final user = community.members[userIndex];
                      final initial = user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : "?";
                      final plantCount = user.stats
                          .fold<int>(0, (sum, s) => sum + (s.count ?? 0));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.primaryContainer,
                              child: Text(initial,
                                  style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            title: Text(user.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(user.email,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                cs.onSurface.withOpacity(0.5))),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.role == 'Admin'
                                          ? cs.errorContainer.withOpacity(0.5)
                                          : cs.surfaceVariant.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(user.role,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: user.role == 'Admin'
                                                ? cs.onErrorContainer
                                                : cs.onSurfaceVariant)),
                                  ),
                                ],
                              ),
                            ),
                            children: [
                              // Stats row
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.leaf,
                                                  size: 16, color: cs.primary),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                    "$plantCount plants",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: cs.onSurface)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.coins,
                                                size: 16, color: cs.primary),
                                            const SizedBox(width: 4),
                                            Text("${user.totalCoins}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.primary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (user.stats.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      // Plant activity table
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Table(
                                          border: TableBorder.all(
                                              color: cs.outlineVariant
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          columnWidths: const {
                                            0: FlexColumnWidth(2),
                                            1: FlexColumnWidth(1),
                                            2: FlexColumnWidth(1),
                                          },
                                          children: [
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: cs.surfaceVariant
                                                      .withOpacity(0.5)),
                                              children: [
                                                _tableHeader("Plant"),
                                                _tableHeader("Count"),
                                                _tableHeader("Coins"),
                                              ],
                                            ),
                                            ...user.stats
                                                .map((s) => TableRow(children: [
                                                      _tableCell(
                                                          s.type ?? "Unknown"),
                                                      _tableCell((s.count ?? 0)
                                                          .toString()),
                                                      _tableCell(
                                                          "+${s.coinsEarned ?? 0}"),
                                                    ])),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _confirmRemoveMember(
                                            context,
                                            admin,
                                            userIndex,
                                            user.name),
                                        icon: Icon(LucideIcons.userMinus,
                                            size: 16, color: cs.error),
                                        label: Text('Remove',
                                            style: TextStyle(
                                                color: cs.error,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── FAB ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberSheet(context),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(LucideIcons.userPlus),
      ),
    );
  }

  Widget _buildMiniStat(
      BuildContext context, IconData icon, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceVariant.withOpacity(0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: cs.primary),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13)),
    );
  }
}
