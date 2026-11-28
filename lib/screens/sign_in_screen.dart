// 6.3 Đăng nhập (spec 016 US3, contracts/account-ui.md): email + password; asks once whether to
// merge when both the phone and the account hold data (FR-011).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/sync_merge.dart';
import '../l10n/app_strings.dart';
import '../providers/account_providers.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/sync_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/account_fields.dart';
import '../widgets/gradient_pill_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({this.email = '', super.key});

  /// Pre-filled, e.g. after "Hãy đăng nhập lại".
  final String email;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

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
    });
    final actions = ref.read(accountActionsProvider);
    try {
      final status = await actions.signIn(_email.text, _password.text);
      if (!mounted) return;
      if (status == FirstLoginStatus.needsMergeChoice) {
        final choice = await showDialog<MergeChoice>(
          context: context,
          builder: (context) => const _MergeDialog(),
        );
        if (choice == null) {
          await actions.cancelSignIn();
          return;
        }
        await actions.completeSignIn(choice);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.accountSignedIn)));
      // An account that already finished the intro skips onboarding (US3-1).
      final onboarded = ref.read(profileRepositoryProvider).isOnboardingDone;
      context.go(onboarded ? AppRoutes.today : AppRoutes.onboarding);
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
      appBar: AppBar(title: const Text(AppStrings.accountSignIn)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            EmailField(controller: _email),
            const SizedBox(height: AppSpacing.sm),
            PasswordField(controller: _password, checkLength: false),
            FormErrorText(_error),
            const SizedBox(height: AppSpacing.lg),
            GradientPillButton(
              label: AppStrings.accountSignIn,
              height: AppButton.compact,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push(AppRoutes.accountForgotPassword),
              child: const Text(AppStrings.accountForgotPassword),
            ),
            TextButton(
              onPressed: () => context.pushReplacement(AppRoutes.accountSignUp),
              child: const Text(AppStrings.accountNoAccountYet),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeDialog extends StatelessWidget {
  const _MergeDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.mergeTitle),
      content: const Text(AppStrings.mergeMessage),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: AppSpacing.sm,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, MergeChoice.merge),
          child: const Text(AppStrings.mergeKeepBoth),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, MergeChoice.useAccount),
          child: const Text(AppStrings.mergeUseAccount),
        ),
      ],
    );
  }
}
