import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isPhoneLogin = false;
  bool _isSignUp = false;
  String? _verificationId;

  bool _obscurePassword = true;

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      if (_isSignUp) {
        // Password Validation
        if (password.length < 8) {
          throw 'كلمة المرور يجب أن لا تقل عن 8 أحرف';
        }
        if (!password.contains(RegExp(r'[A-Z]'))) {
          throw 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل (A-Z)';
        }
        if (!password.contains(RegExp(r'[0-9]'))) {
          throw 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل (0-9)';
        }

        // Create user
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Update display name
        await credential.user?.updateDisplayName(_usernameController.text.trim());
      } else {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loginWithPhone() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _verificationId = verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(50),
                  colorScheme.secondary.withAlpha(50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(30),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.translate('appTitle'),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  Text(
                    'Your AI Learning Companion',
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 48),
                  
                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withAlpha(200),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.primary.withAlpha(50)),
                    ),
                    child: Column(
                      children: [
                        if (!_isPhoneLogin) ...[
                          if (_isSignUp) 
                            _buildTextField(
                              controller: _usernameController,
                              label: AppLocalizations.of(context)!.translate('username'),
                              icon: Icons.person_outline,
                            ),
                          _buildTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)!.translate('email'),
                            icon: Icons.email_outlined,
                          ),
                          _buildTextField(
                            controller: _passwordController,
                            label: AppLocalizations.of(context)!.translate('password'),
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          if (_isSignUp)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                '• At least 8 characters\n• At least one uppercase letter (A-Z)\n• At least one number (0-9)',
                                style: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150), fontSize: 11),
                              ),
                            ),
                          if (!_isSignUp)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                child: Text('Forgot Password?', style: TextStyle(color: colorScheme.primary, fontSize: 13)),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: _handleEmailAuth, 
                            child: Text(
                              _isSignUp ? AppLocalizations.of(context)!.translate('signUp') : AppLocalizations.of(context)!.translate('signIn'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ] else ...[
                          if (_verificationId == null) ...[
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _loginWithPhone, 
                              child: const Text('Send Verification Code'),
                            ),
                          ] else ...[
                            _buildTextField(
                              controller: _otpController,
                              label: 'Verification Code',
                              icon: Icons.lock_clock_outlined,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _verifyOtp, 
                              child: const Text('Verify & Sign In'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle Login Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.primary.withAlpha(50))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: colorScheme.primary.withAlpha(50))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Other Login Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: _isPhoneLogin ? Icons.email : Icons.phone,
                        onTap: () => setState(() {
                          _isPhoneLogin = !_isPhoneLogin;
                          _isSignUp = false;
                          _verificationId = null;
                        }),
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        icon: Icons.person_search_outlined,
                        label: 'Anonymous',
                        onTap: () async {
                          await FirebaseAuth.instance.signInAnonymously();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
          ),
          filled: true,
          fillColor: Colors.grey.withAlpha(10),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary.withAlpha(100)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            if (label != null) ...[
              const SizedBox(width: 12),
              Text(label!, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
