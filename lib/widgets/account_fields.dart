// 6.3 Tài khoản (spec 016): the email and password fields shared by the sign-in, sign-up and
// forgot-password screens, with the checks of data-model.md Validation.
import 'package:material_ui/material_ui.dart';

import '../data/sync_merge.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class EmailField extends StatelessWidget {
  const EmailField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    autofillHints: const [AutofillHints.email],
    autocorrect: false,
    decoration: const InputDecoration(labelText: AppStrings.accountEmail),
    validator: (value) => looksLikeEmail(value ?? '') ? null : AppStrings.accountInvalidEmail,
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({required this.controller, this.checkLength = true, super.key});

  final TextEditingController controller;

  /// Sign-up and re-authentication check the 8-character rule before calling the backend.
  final bool checkLength;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !_visible,
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      labelText: AppStrings.accountPassword,
      suffixIcon: IconButton(
        tooltip: _visible ? AppStrings.accountHidePassword : AppStrings.accountShowPassword,
        icon: Icon(_visible ? AppIcons.hidePassword : AppIcons.showPassword),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    ),
    validator: (value) {
      final text = value ?? '';
      if (text.isEmpty) return AppStrings.accountWeakPassword;
      if (widget.checkLength && text.length < minPasswordLength) {
        return AppStrings.accountWeakPassword;
      }
      return null;
    },
  );
}

/// An error line under a form, in the theme's error colour.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message!,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
