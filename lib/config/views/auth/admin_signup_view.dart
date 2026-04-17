// lib/views/auth/admin_signup_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../common/custom_button.dart';
import '../common/custom_text_field.dart';

class AdminSignUpView extends StatefulWidget {
  const AdminSignUpView({super.key});

  @override
  State<AdminSignUpView> createState() => _AdminSignUpViewState();
}

class _AdminSignUpViewState extends State<AdminSignUpView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _communityName = TextEditingController();
  final TextEditingController _organization = TextEditingController();
  final TextEditingController _adminReason = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _communityName.dispose();
    _organization.dispose();
    _adminReason.dispose();
    super.dispose();
  }

  String? _validateCommunityName(String? v) {
    if (v == null || v.trim().length < 3) {
      return 'Community name required (min 3 chars)';
    }
    return null;
  }

  String? _validateOrganization(String? v) {
    if (v == null || v.trim().length < 2) {
      return 'Organization / University name required';
    }
    return null;
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await auth.signUp(
      fullName: _fullName.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: 'admin',
      communityName: _communityName.text.trim(),
      organization: _organization.text.trim(),
      adminReason: _adminReason.text.trim(),
    );

    setState(() => _loading = false);

    if (!ok && mounted) {
      final errorMsg = auth.authError ?? 'Sign up failed — check details';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } else if (mounted) {
      // Pop back to login → EntryDecider will route to AdminDashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        centerTitle: true,
        title: const Text('Admin Registration'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 18.0,
            right: 18.0,
            top: 12.0,
            bottom: 12.0,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Header with admin badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Admin',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Register as a community administrator',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section: Personal Info
                _sectionHeader(context, 'Personal Information'),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'e.g. Dr. Ahmed Khan',
                  validator: auth.validateName,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _username,
                  label: 'Admin Username',
                  hint: 'e.g. admin_ahmed',
                  validator: auth.validateUsername,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _email,
                  label: 'Official Email',
                  hint: 'admin@university.edu',
                  keyboardType: TextInputType.emailAddress,
                  validator: auth.validateEmail,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _password,
                  label: 'Password',
                  hint: '••••••••',
                  obscure: true,
                  validator: auth.validatePassword,
                ),

                const SizedBox(height: 24),

                // Section: Community Info
                _sectionHeader(context, 'Community Details'),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _communityName,
                  label: 'Community Name',
                  hint: 'e.g. NUST Green Society',
                  validator: _validateCommunityName,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _organization,
                  label: 'Organization / University',
                  hint: 'e.g. NUST Islamabad',
                  validator: _validateOrganization,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _adminReason,
                  label: 'Why do you want admin access?',
                  hint: 'Briefly describe your role...',
                  maxLines: 3,
                ),

                const SizedBox(height: 28),

                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'As a community admin, you can create communities, manage users, organize plantation drives, and generate QR codes.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        onPressed: _submit,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded),
                            SizedBox(width: 8),
                            Text('Register as Admin'),
                          ],
                        ),
                      ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}
