import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/log/data/log_api.dart';
import '../../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../../shared/config/api_config.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/terms_privacy_widget.dart';
import '../../../../shared/widgets/validation_dialog.dart';
import '../widgets/auth_chrome.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _selectedGender;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Map<String, dynamic> _decodeResponseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Keep a friendly fallback when the server does not return JSON.
    }

    return const {};
  }

  String _signUpFailureMessage(Map<String, dynamic> data) {
    final serverMessage = data['message'] ?? data['error'];
    final normalizedMessage = serverMessage?.toString().trim();

    if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
      return normalizedMessage;
    }

    return 'Signup failed';
  }

  Future<void> signUp() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(ApiConfig.auth('/signup'));

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "age": int.tryParse(_ageController.text.trim()),
          "gender": _selectedGender,
          "password": _passwordController.text.trim(),
        }),
      );

      final data = _decodeResponseBody(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authToken = data['access_token']?.toString().trim();
        if (authToken == null || authToken.isEmpty) {
          if (!mounted) return;
          await ValidationDialog.show(
            context,
            message: 'Signup failed: session token was missing.',
            type: ValidationDialogType.error,
          );
          return;
        }

        await UserSessionController.instance.saveUser(
          Map<String, dynamic>.from(data['user'] as Map<String, dynamic>),
          authToken: authToken,
        );
        await LogApi.persistServerStreakSnapshot(
          data['streak'] as Map<String, dynamic>?,
        );

        setState(() {
          _emailController.clear();
          _usernameController.clear();
          _ageController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _selectedGender = null;
          _agreeTerms = false;
        });

        _formKey.currentState?.reset();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        await ValidationDialog.show(
          context,
          message:
              data['message']?.toString() ?? 'Account created successfully',
          type: ValidationDialogType.success,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingPage(
              userId: (data['user'] as Map<String, dynamic>)['user_id'] as int,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        await ValidationDialog.show(
          context,
          message: _signUpFailureMessage(data),
          type: ValidationDialogType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await ValidationDialog.show(
        context,
        message:
            'Unable to reach the server right now. Please check your connection and try again.',
        type: ValidationDialogType.connection,
      );
    }

    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return authInputDecoration(
      context,
      label: label,
      icon: icon,
      suffixIcon: suffixIcon,
    );
  }

  void _showTermsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142237) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Terms & Conditions and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: const TermsPrivacyWidget(),
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

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScaffold(
      illustrationAsset: authWorkoutAsset,
      centerContent: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 28),
        child: AuthGlassPanel(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AuthHeroIllustration(
                  asset: authWorkoutAsset,
                  semanticsLabel: 'Wellness movement illustration',
                  height: 150,
                ),
                const SizedBox(height: 12),
                const AuthBrandHeader(
                  title: 'Create your Account',
                  subtitle: 'Start your wellness journey with VitalySync.',
                  logoSize: 68,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Age',
                    icon: Icons.cake_outlined,
                  ),
                  validator: (value) {
                    final ageText = value?.trim() ?? '';
                    if (ageText.isEmpty) {
                      return 'Enter your age';
                    }

                    final age = int.tryParse(ageText);
                    if (age == null) {
                      return 'Enter a valid age';
                    }
                    if (age < 1 || age > 120) {
                      return 'Age must be between 1 and 120';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedGender),
                  initialValue: _selectedGender,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? const Color(0xFF142237)
                      : Colors.white,
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Gender',
                    icon: Icons.wc_outlined,
                  ),
                  items: _genderOptions
                      .map(
                        (gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Select your gender'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: pagePrimaryTextColor(context)),
                  decoration: _inputDecoration(
                    label: 'Confirm Password',
                    icon: Icons.lock_person_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF4FBF8).withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pageBorderColor(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 1.05,
                        child: Checkbox(
                          value: _agreeTerms,
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _agreeTerms = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'I agree to the Terms and Conditions and Privacy Policy ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: pageSecondaryTextColor(context),
                                  height: 1.4,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showTermsModal,
                                child: Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AuthButton.primary(
                  label: 'Create Account',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: _isLoading,
                  onPressed: (_agreeTerms && !_isLoading)
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            signUp();
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                  label: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
