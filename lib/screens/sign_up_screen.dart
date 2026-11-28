// 6.3 Tạo tài khoản (spec 016 US2, FR-005; contracts/account-ui.md): the privacy notice first, then
// email + password. The guest data on the phone moves into the new account (FR-010).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/sync_merge.dart';
import '../l10n/app_strings.dart';
import '../providers/account_providers.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_fields.dart';
import '../widgets/gradient_pill_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  bool _busy = false;
  String? _error;
  bool _emailInUse = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _emailInUse = false;
    });
    try {
      await ref.read(accountActionsProvider).signUp(_email.text, _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.accountCreated)));
      final onboarded = ref.read(profileRepositoryProvider).isOnboardingDone;
      context.go(onboarded ? AppRoutes.account : AppRoutes.onboarding);
    } on AuthFailure catch (failure) {
      setState(() {
        _error = authErrorMessage(failure.code);
        _emailInUse = failure.code == 'email-already-in-use';
      });
    } on Object {
      setState(() => _error = AppStrings.accountNoNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_agreed ? AppStrings.accountSignUp : AppStrings.privacyTitle)),
      body: _agreed ? _buildForm() : _PrivacyNotice(onAgree: () => setState(() => _agreed = true)),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          EmailField(controller: _email),
          const SizedBox(height: AppSpacing.sm),
          PasswordField(controller: _password),
          FormErrorText(_error),
          if (_emailInUse)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.pushReplacement(AppRoutes.accountSignInWith(_email.text)),
                child: const Text(AppStrings.accountSignIn),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          GradientPillButton(
            label: AppStrings.accountSignUp,
            height: AppButton.compact,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Every piece of data that leaves the phone, where it goes, and how to delete it (FR-005).
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.onAgree});

  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        section(AppStrings.privacyLeavesTitle, AppStrings.privacyLeaves),
        section(AppStrings.privacyWhereTitle, AppStrings.privacyWhere),
        section(AppStrings.privacyStaysTitle, AppStrings.privacyStays),
        Text(AppStrings.privacyNoTracking, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.privacyDelete, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.privacyUnder16, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.lg),
        GradientPillButton(
          label: AppStrings.privacyAgree,
          height: AppButton.compact,
          onPressed: onAgree,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: () => context.pop(), child: const Text(AppStrings.privacyLater)),
      ],
    );
  }
}
