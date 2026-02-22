import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/theme_controller.dart';

class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;
  bool _isEditing = false;
  bool _twoFactorEnabled = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthController>(context, listen: false);
    _nameCtrl = TextEditingController(text: auth.userName);
    _bioCtrl = TextEditingController(
      text: '',
    );
    _phoneCtrl = TextEditingController(text: '');
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      final auth = Provider.of<AuthController>(context, listen: false);
      auth.updateProfile(name: _nameCtrl.text, imagePath: image.path);
    }
  }

  void _showImagePicker() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Update Photo',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text('Choose a new profile picture',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _imagePickerOption(
                        cs,
                        icon: LucideIcons.image,
                        label: 'Gallery',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imagePickerOption(
                        cs,
                        icon: LucideIcons.camera,
                        label: 'Camera',
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePickerOption(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.primaryContainer.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cs.primary, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        final auth = Provider.of<AuthController>(context, listen: false);
        auth.updateProfile(name: _nameCtrl.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _isEditing = !_isEditing;
    });
  }

  void _showChangePasswordDialog() {
    final cs = Theme.of(context).colorScheme;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lock, color: cs.primary, size: 24),
          ),
          title: const Text('Change Password',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(
                  cs, currentCtrl, 'Current Password', obscureCurrent, () {
                setDialogState(() => obscureCurrent = !obscureCurrent);
              }),
              const SizedBox(height: 12),
              _passwordField(cs, newCtrl, 'New Password', obscureNew, () {
                setDialogState(() => obscureNew = !obscureNew);
              }),
              const SizedBox(height: 12),
              _passwordField(
                  cs, confirmCtrl, 'Confirm Password', obscureConfirm, () {
                setDialogState(() => obscureConfirm = !obscureConfirm);
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.info, size: 12, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Minimum 8 characters with letters & numbers',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
            ),
            FilledButton.icon(
              onPressed: () {
                if (newCtrl.text.length >= 8 &&
                    newCtrl.text == confirmCtrl.text) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Password changed successfully'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Passwords must match and be at least 8 characters'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              icon: const Icon(LucideIcons.check, size: 16),
              label: const Text('Update',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(ColorScheme cs, TextEditingController ctrl,
      String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final admin = Provider.of<AdminController>(context);
    final cs = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;

    // Admin stats
    final totalCommunities = admin.communities.length;
    final totalUsers = admin.totalUsers;
    final totalQr = admin.totalQrCodes;
    final totalScans = admin.totalScans;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // STATIC PROFILE HEADER
          // ═══════════════════════════════════════════════════════════
          FadeTransition(
            opacity: _headerAnim,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0BA360),
                    const Color(0xFF3CBA92),
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
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: auth.profileImage != null
                              ? FileImage(File(auth.profileImage!))
                              : null,
                          child: auth.profileImage == null
                              ? const Icon(LucideIcons.user,
                                  color: Colors.white, size: 36)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(LucideIcons.camera,
                                size: 14, color: cs.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name (editable)
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _nameCtrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white54)),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.white54)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _toggleEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(auth.userName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _toggleEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),
                  Text(auth.userEmail ?? 'admin@seedscan.com',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 10),

                  // Role badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shield,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text('System Administrator',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row inside header
                  Row(
                    children: [
                      _headerStatPill(
                          totalCommunities.toString(), 'Communities'),
                      const SizedBox(width: 8),
                      _headerStatPill(totalUsers.toString(), 'Users'),
                      const SizedBox(width: 8),
                      _headerStatPill(_formatNum(totalScans), 'Scans'),
                      const SizedBox(width: 8),
                      _headerStatPill(totalQr.toString(), 'QR Codes'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // SCROLLABLE BODY CONTENT
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              physics: const ClampingScrollPhysics(),
              children: [
                // ── Personal Information ──
                _sectionHeader(
                    cs, 'Personal Information', LucideIcons.userCircle),
                const SizedBox(height: 14),
                _infoCard(cs, [
                  _infoRow(cs,
                      icon: LucideIcons.user,
                      label: 'Full Name',
                      value: auth.userName,
                      isEditing: _isEditing,
                      controller: _nameCtrl),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.mail,
                      label: 'Email',
                      value: auth.userEmail ?? 'admin@seedscan.com'),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.atSign,
                      label: 'Username',
                      value: '@${auth.userHandle}'),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.phone,
                      label: 'Phone',
                      value: _phoneCtrl.text,
                      isEditing: _isEditing,
                      controller: _phoneCtrl),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.briefcase,
                      label: 'Role',
                      value: 'System Administrator'),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.fileText,
                      label: 'Bio',
                      value: _bioCtrl.text,
                      isEditing: _isEditing,
                      controller: _bioCtrl),
                ]),

                const SizedBox(height: 28),

                // ── Appearance ──
                _sectionHeader(cs, 'Appearance', LucideIcons.palette),
                const SizedBox(height: 14),
                _infoCard(cs, [
                  Consumer<ThemeController>(
                    builder: (context, themeCtrl, _) => _settingsTile(
                      cs,
                      icon: themeCtrl.isDarkMode
                          ? LucideIcons.moon
                          : LucideIcons.sun,
                      title: 'Dark Mode',
                      subtitle: themeCtrl.isDarkMode
                          ? 'Dark theme enabled'
                          : 'Light theme enabled',
                      trailing: Switch(
                        value: themeCtrl.isDarkMode,
                        onChanged: (v) {
                          themeCtrl.toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(v
                                  ? 'Dark mode enabled'
                                  : 'Light mode enabled'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor:
                                  v ? Colors.blueGrey : Colors.amber,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Security ──
                _sectionHeader(cs, 'Security', LucideIcons.shield),
                const SizedBox(height: 14),
                _infoCard(cs, [
                  _settingsTile(cs,
                      icon: LucideIcons.lock,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      trailing: Icon(LucideIcons.chevronRight,
                          size: 18, color: cs.onSurface.withOpacity(0.25)),
                      onTap: _showChangePasswordDialog),
                  _infoDivider(cs),
                  _settingsTile(
                    cs,
                    icon: LucideIcons.smartphone,
                    title: 'Two-Factor Authentication',
                    subtitle: _twoFactorEnabled ? 'Enabled' : 'Not enabled',
                    trailing: Switch(
                      value: _twoFactorEnabled,
                      onChanged: (v) {
                        setState(() => _twoFactorEnabled = v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(v
                                ? '2FA enabled successfully'
                                : '2FA disabled'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor:
                                v ? Colors.green : Colors.redAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  _infoDivider(cs),
                  _settingsTile(cs,
                      icon: LucideIcons.fingerprint,
                      title: 'Login Sessions',
                      subtitle: 'Manage active sessions',
                      trailing: Icon(LucideIcons.chevronRight,
                          size: 18, color: cs.onSurface.withOpacity(0.25)),
                      onTap: () => _showSessionsDialog()),
                ]),

                const SizedBox(height: 28),

                // ── Notifications Preferences ──
                _sectionHeader(cs, 'Notifications', LucideIcons.bell),
                const SizedBox(height: 14),
                _infoCard(cs, [
                  _settingsTile(
                    cs,
                    icon: LucideIcons.mail,
                    title: 'Email Notifications',
                    subtitle: 'Alerts, reports & digests',
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (v) => setState(() => _emailNotifications = v),
                    ),
                  ),
                  _infoDivider(cs),
                  _settingsTile(
                    cs,
                    icon: LucideIcons.bellRing,
                    title: 'Push Notifications',
                    subtitle: 'Real-time system alerts',
                    trailing: Switch(
                      value: _pushNotifications,
                      onChanged: (v) => setState(() => _pushNotifications = v),
                    ),
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Account Info ──
                _sectionHeader(cs, 'Account Info', LucideIcons.info),
                const SizedBox(height: 14),
                _infoCard(cs, [
                  _infoRow(cs,
                      icon: LucideIcons.calendar,
                      label: 'Member Since',
                      value: '—'),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.clock,
                      label: 'Last Login',
                      value: _formatLastLogin()),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.server,
                      label: 'Server Status',
                      value: admin.serverStatus),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.hash,
                      label: 'Admin ID',
                      value: auth.userId ?? '—'),
                  _infoDivider(cs),
                  _infoRow(cs,
                      icon: LucideIcons.globe, label: 'Region', value: '—'),
                ]),

                const SizedBox(height: 28),

                // ── Danger Zone ──
                _sectionHeader(cs, 'Danger Zone', LucideIcons.alertTriangle),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    children: [
                      _settingsTile(cs,
                          icon: LucideIcons.logOut,
                          title: 'Sign Out',
                          subtitle: 'Log out of this admin account',
                          iconColor: Colors.redAccent,
                          trailing: Icon(LucideIcons.chevronRight,
                              size: 18,
                              color: Colors.redAccent.withOpacity(0.4)),
                          onTap: () => _showSignOutDialog()),
                      Divider(
                          height: 1,
                          color: Colors.redAccent.withOpacity(0.1),
                          indent: 56,
                          endIndent: 16),
                      _settingsTile(cs,
                          icon: LucideIcons.trash2,
                          title: 'Deactivate Account',
                          subtitle: 'Permanently disable this account',
                          iconColor: Colors.redAccent,
                          trailing: Icon(LucideIcons.chevronRight,
                              size: 18,
                              color: Colors.redAccent.withOpacity(0.4)),
                          onTap: () => _showDeactivateDialog()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App version
                Center(
                  child: Column(
                    children: [
                      Text('SeedScan Admin',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.3))),
                      const SizedBox(height: 2),
                      Text('v1.0.0',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.2))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HELPERS ═══════════════════

  static String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  static String _formatLastLogin() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return 'Today at $h12:$m $period';
  }

  // Header stat pill
  Widget _headerStatPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Section header
  Widget _sectionHeader(ColorScheme cs, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cs.onSurface)),
      ],
    );
  }

  // Wrapping card
  Widget _infoCard(ColorScheme cs, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: children),
      ),
    );
  }

  // Info row
  Widget _infoRow(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
    bool isEditing = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.45))),
                const SizedBox(height: 2),
                if (isEditing && controller != null)
                  TextField(
                    controller: controller,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: cs.primary.withOpacity(0.3))),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: cs.primary.withOpacity(0.3))),
                      focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: cs.primary, width: 1.5)),
                    ),
                  )
                else
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Divider
  Widget _infoDivider(ColorScheme cs) {
    return Divider(
      height: 1,
      color: cs.onSurface.withOpacity(0.06),
      indent: 42,
    );
  }

  // Activity metric card
  Widget _activityMetric(
    ColorScheme cs, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: cs.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  // Activity item
  Widget _activityItem(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(time,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Settings tile
  Widget _settingsTile(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? cs.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ═══════════════════ DIALOGS ═══════════════════

  void _showSessionsDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.fingerprint, color: cs.primary, size: 24),
        ),
        title: const Text('Active Sessions',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sessionItem(cs,
                device: 'This Device',
                location: 'Current session',
                time: 'Now',
                isActive: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All other sessions terminated'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Revoke Others'),
          ),
        ],
      ),
    );
  }

  Widget _sessionItem(
    ColorScheme cs, {
    required String device,
    required String location,
    required String time,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? LucideIcons.smartphone : LucideIcons.monitor,
              color: isActive ? Colors.green : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                Text('$location - $time',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Active',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green)),
            ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final cs = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthController>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Are you sure you want to sign out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.alertTriangle,
              color: Colors.redAccent, size: 24),
        ),
        title: const Text('Deactivate Account',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This action is irreversible. Your admin account will be permanently deactivated and you will lose all access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account deactivation request submitted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
