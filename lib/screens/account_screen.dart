// 6.3 Tài khoản (spec 016 US2, US3, US5, US7; contracts/account-ui.md): guest choices, or the
// signed-in email, sync status, sign-out and account deletion.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/sync_merge.dart';
import '../l10n/app_strings.dart';
import '../providers/account_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/remote_store.dart';
import '../theme/app_theme.dart';
import '../widgets/account_fields.dart';
import '../widgets/gradient_pill_button.dart';

/// "Đã đồng bộ lúc HH:mm", "Đang đồng bộ…", "Chưa đồng bộ…" or "Hãy đăng nhập lại" (FR-017).
String syncStatusLabel(SyncStatus status) {
  switch (status.kind) {
    case SyncKind.syncing:
      return AppStrings.accountSyncing;
    case SyncKind.signInAgain:
      return AppStrings.accountSignInAgain;
    case SyncKind.pending:
      return AppStrings.accountNotSynced;
    case SyncKind.synced:
      final time = status.lastOkAt;
      if (time == null) return AppStrings.accountNotSynced;
      String two(int n) => n.toString().padLeft(2, '0');
      return AppStrings.accountSyncedAt('${two(time.hour)}:${two(time.minute)}');
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: switch (account.kind) {
          AccountKind.signedIn => [_SignedInView(email: account.email)],
          AccountKind.signInAgain => [_SignInAgainView(email: account.email)],
          AccountKind.guest || AccountKind.unavailable => const [_GuestView()],
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.accountGuestIntro, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        GradientPillButton(
          label: AppStrings.accountSignIn,
          height: AppButton.compact,
          onPressed: () => context.push(AppRoutes.accountSignIn),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.accountSignUp),
          child: const Text(AppStrings.accountSignUp),
        ),
      ],
    );
  }
}

class _SignInAgainView extends StatelessWidget {
  const _SignInAgainView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(email, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const Text(AppStrings.accountSignInAgain),
        const SizedBox(height: AppSpacing.lg),
        GradientPillButton(
          label: AppStrings.accountSignIn,
          height: AppButton.compact,
          onPressed: () => context.push(AppRoutes.accountSignInWith(email)),
        ),
      ],
    );
  }
}

class _SignedInView extends ConsumerStatefulWidget {
  const _SignedInView({required this.email});

  final String email;

  @override
  ConsumerState<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends ConsumerState<_SignedInView> {
  bool _busy = false;

  Future<void> _signOut() async {
    // Signing out swaps this view for the guest one, so keep the router before awaiting.
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    final actions = ref.read(accountActionsProvider);
    final pending = await actions.prepareSignOut();
    if (!mounted) return;
    var confirmed = true;
    if (pending > 0) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppStrings.signOutPendingTitle),
              content: Text(AppStrings.signOutPendingMessage(pending)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(AppStrings.signOutAnyway),
                ),
                FilledButton(
                  autofocus: true,
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(AppStrings.signOutStay),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!confirmed) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    await actions.signOut();
    router.go(AppRoutes.onboarding);
  }

  Future<void> _delete() async {
    // Deleting swaps this view for the guest one, so keep these before awaiting.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (deleted != true) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.accountDeleted)));
    router.go(AppRoutes.settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(syncStatusProvider);
    final sessionRunning = ref.watch(focusSessionProvider).isRunning;
    final offline = status.kind == SyncKind.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(AppIcons.account),
            title: Text(widget.email),
            subtitle: Text(syncStatusLabel(status)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GradientPillButton(
          label: AppStrings.accountSyncNow,
          icon: AppIcons.sync,
          height: AppButton.compact,
          onPressed: status.kind == SyncKind.syncing
              ? null
              : () => ref.read(accountActionsProvider).syncNow(),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(AppIcons.signOut),
          label: const Text(AppStrings.accountSignOut),
          onPressed: _busy || sessionRunning ? null : _signOut,
        ),
        if (sessionRunning)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(AppStrings.accountSignOutDuringSession, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.xxl),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: offline || _busy ? null : _delete,
          child: const Text(AppStrings.accountDelete),
        ),
        if (offline)
          Text(
            AppStrings.accountDeleteNeedsNetwork,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Asks for the password again, offers to clear the phone too, then deletes (FR-018).
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _clearLocal = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).deleteAccount(_password.text, clearLocal: _clearLocal);
      if (mounted) Navigator.pop(context, true);
    } on AuthFailure catch (failure) {
      setState(() => _error = authErrorMessage(failure.code));
    } on RemoteUnavailable {
      setState(() => _error = AppStrings.accountNoNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.deleteTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.deleteMessage),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _clearLocal,
                title: const Text(AppStrings.deleteLocalToo),
                onChanged: (value) => setState(() => _clearLocal = value ?? false),
              ),
              PasswordField(controller: _password, checkLength: false),
              FormErrorText(_error),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: _busy ? null : _confirm,
          child: Text(_error == null ? AppStrings.accountDelete : AppStrings.deleteRetry),
        ),
      ],
    );
  }
}
