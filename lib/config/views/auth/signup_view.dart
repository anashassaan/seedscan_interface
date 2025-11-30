// lib/views/auth/signup_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../common/custom_button.dart';
import '../common/custom_text_field.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
    );
    setState(() => _loading = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed — check details')),
      );
    } else {
      Navigator.of(
        context,
      ).pop(); // will cause entrydecider to route to main navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
        title: const Text('Create Account'),
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
                const SizedBox(height: 6),
                Text(
                  'Sign up',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join SeedScan with your details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _fullName,
                  label: 'Full Name',
                  hint: 'e.g. Ali Khan',
                  validator: Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).validateName,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _username,
                  label: 'Username',
                  hint: 'user123',
                  validator: Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).validateUsername,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@uni.edu',
                  keyboardType: TextInputType.emailAddress,
                  validator: Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).validateEmail,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _password,
                  label: 'Password',
                  hint: '••••••',
                  obscure: true,
                  validator: Provider.of<AuthController>(
                    context,
                    listen: false,
                  ).validatePassword,
                ),
                const SizedBox(height: 20),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        onPressed: _submit,
                        child: const Text('Create Account'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
