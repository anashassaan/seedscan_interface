// lib/views/auth/login_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../common/custom_button.dart';
import '../common/custom_text_field.dart';
import 'signup_view.dart';
import '../../assets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await auth.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    setState(() => _loading = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed — check credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Forest gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Scrollable content
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Logo at top
                      Padding(
                        padding: const EdgeInsets.only(top: 48.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Image.asset(
                              AppAssets.logo,
                              height: MediaQuery.of(context).size.width * 0.65,
                              width: MediaQuery.of(context).size.width * 0.65,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Glassmorphism form card
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 20.0,
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 22.0,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Welcome back',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in with your Email',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  CustomTextField(
                                    controller: _email,
                                    label: 'Email',
                                    hint: 'name@gmail.com',
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
                                    hint: '••••••••',
                                    obscure: true,
                                    validator: Provider.of<AuthController>(
                                      context,
                                      listen: false,
                                    ).validatePassword,
                                  ),
                                  const SizedBox(height: 18),
                                  _loading
                                      ? const CircularProgressIndicator()
                                      : CustomButton(
                                          onPressed: _submit,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.lock_open_rounded),
                                              SizedBox(width: 8),
                                              Text('Sign In'),
                                            ],
                                          ),
                                        ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('New here?'),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SignUpView(),
                                            ),
                                          );
                                        },
                                        child: const Text('Create account'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Add spacing for keyboard
                      SizedBox(height: keyboardHeight > 0 ? 20 : 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
