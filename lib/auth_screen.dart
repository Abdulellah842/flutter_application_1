import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  late final AnimationController _bgController;
  bool _isLogin = true;
  bool _loading = false;
  bool _phoneMode = false;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _runEmailFlow() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _snack('أدخل إيميل صحيح وكلمة مرور 6 أحرف على الأقل.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(email: email, password: password);
      } else {
        await AuthService.instance.signUpWithEmail(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _snack('أدخل رقم الجوال بصيغة دولية مثل +9665...');
      return;
    }
    setState(() => _loading = true);
    await AuthService.instance.sendPhoneCode(
      phoneNumber: phone,
      onCodeSent: () => _snack('تم إرسال رمز التحقق.'),
      onVerificationId: (id) => _verificationId = id,
      onFailure: _snack,
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _verifyCode() async {
    final code = _smsCodeController.text.trim();
    if (_verificationId.isEmpty || code.length < 4) {
      _snack('رمز التحقق غير مكتمل.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.verifySmsCode(
        verificationId: _verificationId,
        smsCode: code,
      );
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.lerp(const Color(0xFF0A0F1E), const Color(0xFF1D4ED8), t)!,
                        Color.lerp(const Color(0xFF111827), const Color(0xFF0F766E), 1 - t)!,
                      ],
                    ),
                  ),
                );
              },
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مرحبا بك',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'سجّل الدخول أو أنشئ حسابك لمزامنة بياناتك عبر كل الأجهزة.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              ChoiceChip(
                                label: Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
                                selected: true,
                                selectedColor: const Color(0xFF2563EB),
                                labelStyle: const TextStyle(color: Colors.white),
                                onSelected: (_) => setState(() => _isLogin = !_isLogin),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text(_phoneMode ? 'وضع الجوال' : 'وضع الإيميل'),
                                selected: _phoneMode,
                                onSelected: (v) => setState(() => _phoneMode = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _phoneMode ? _buildPhoneForm() : _buildEmailForm(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : _phoneMode
                                      ? (_verificationId.isEmpty ? _sendCode : _verifyCode)
                                      : _runEmailFlow,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                _phoneMode
                                    ? (_verificationId.isEmpty ? 'إرسال رمز التحقق' : 'تأكيد الرمز')
                                    : (_isLogin ? 'دخول' : 'إنشاء حساب'),
                              ),
                            ),
                          ),
                          if (!_phoneMode && _isLogin) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  _snack('أدخل الإيميل أولاً.');
                                  return;
                                }
                                await AuthService.instance.sendPasswordReset(email);
                                _snack('تم إرسال رابط استعادة كلمة المرور.');
                              },
                              child: const Text('نسيت كلمة المرور؟'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('الإيميل'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('كلمة المرور'),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone_form'),
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('رقم الجوال (+966...)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _smsCodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('رمز التحقق SMS'),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
