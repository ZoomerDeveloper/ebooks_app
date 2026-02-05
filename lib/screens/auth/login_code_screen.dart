import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class LoginCodeScreen extends StatefulWidget {
  const LoginCodeScreen({super.key});

  @override
  State<LoginCodeScreen> createState() => _LoginCodeScreenState();
}

class _LoginCodeScreenState extends State<LoginCodeScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.requestCode(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _codeSent = true;
      });
      SuccessSnackbar.show(
        context,
        'Код отправлен на ${_emailController.text.trim()}',
      );
    } else if (authProvider.error != null) {
      ErrorSnackbar.show(context, authProvider.error!);
    }
  }

  Future<void> _loginWithCode() async {
    if (!_codeFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginByCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (authProvider.error != null) {
      ErrorSnackbar.show(context, authProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Вход по коду',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Введите код, отправленный на ваш email'
                    : 'Мы отправим код на ваш email',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (!_codeSent) ...[
                // Email Form
                Form(
                  key: _emailFormKey,
                  child: CustomTextField(
                    label: 'Email',
                    hint: 'ваш@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@')) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return GradientButton(
                      text: 'Отправить код',
                      onPressed: _requestCode,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
              ] else ...[
                // Code Form
                Form(
                  key: _codeFormKey,
                  child: CustomTextField(
                    label: 'Код подтверждения',
                    hint: '123456',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите код';
                      }
                      if (value.length != 6) {
                        return 'Код должен состоять из 6 цифр';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Resend Code
                Center(
                  child: TextButton(
                    onPressed: _requestCode,
                    child: Text(
                      'Отправить код ещё раз',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return GradientButton(
                      text: 'Проверить и войти',
                      onPressed: _loginWithCode,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
