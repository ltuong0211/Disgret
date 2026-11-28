// 6.3 Quên mật khẩu (spec 016 US6, FR-007): sends a reset link; the same message whether or not
// the email has an account.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/sync_merge.dart';
import '../l10n/app_strings.dart';
import '../providers/account_providers.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_fields.dart';
import '../widgets/gradient_pill_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).sendPasswordReset(_email.text);
      setState(() => _sent = true);
    } on AuthFailure catch (failure) {
      setState(() => _error = authErrorMessage(failure.code));
    } on Object {
      setState(() => _error = AppStrings.accountNoNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountForgotPassword)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            EmailField(controller: _email),
            FormErrorText(_error),
            if (_sent)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  AppStrings.accountResetSent,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            GradientPillButton(
              label: AppStrings.accountSendReset,
              height: AppButton.compact,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
