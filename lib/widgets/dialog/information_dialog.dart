import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/enums/processing/dialog_name_enum.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_button.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class InformationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final VoidCallback? onPressed;
  final DialogName dialogName;
  const InformationDialog({
    super.key,
    this.title = '',
    this.content = '',
    this.buttonText,
    this.onPressed,
    this.dialogName = DialogName.empty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface.withOpacity(0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dialogName != DialogName.empty) ...[
                Text(
                  dialogName == DialogName.success
                      ? S.of(context).success
                      : S.of(context).failure,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: dialogName == DialogName.success
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPress: onPressed ?? () => Navigator.pop(context),
                text: buttonText ?? S.of(context).ok,
                fontSize: 16,
                fontColor: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}