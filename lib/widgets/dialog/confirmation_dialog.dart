import 'package:flutter/material.dart';
import '../general/app_text_style.dart';
import '../general/gradient_button.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Gradient? confirmGradient;
  final Gradient? cancelGradient;
  final double confirmHeight;
  final double cancelHeight;
  final double confirmWidth;
  final double cancelWidth;
  final double confirmBorderRadius;
  final double cancelBorderRadius;
  final double confirmFontSize;
  final double cancelFontSize;
  final Color confirmFontColor;
  final Color cancelFontColor;
  final FontWeight confirmFontWeight;
  final FontWeight cancelFontWeight;

  const ConfirmationDialog({
    super.key,
    this.title = '',
    this.content = '',
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmGradient,
    this.cancelGradient,
    this.confirmHeight = 48,
    this.cancelHeight = 48,
    this.confirmWidth = double.infinity,
    this.cancelWidth = double.infinity,
    this.confirmBorderRadius = 8,
    this.cancelBorderRadius = 8,
    this.confirmFontSize = 16,
    this.cancelFontSize = 16,
    this.confirmFontColor = Colors.white,
    this.cancelFontColor = Colors.white,
    this.confirmFontWeight = FontWeight.w600,
    this.cancelFontWeight = FontWeight.w600,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GradientButton(
                      onPress: onCancel ?? () => Navigator.pop(context),
                      gradient: cancelGradient,
                      height: cancelHeight,
                      width: cancelWidth,
                      borderRadius: cancelBorderRadius,
                      text: cancelText ?? S.of(context).cancel,
                      fontSize: cancelFontSize,
                      fontColor: cancelFontColor,
                      fontWeight: cancelFontWeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GradientButton(
                      onPress: onConfirm ?? () => Navigator.pop(context),
                      gradient: confirmGradient,
                      height: confirmHeight,
                      width: confirmWidth,
                      borderRadius: confirmBorderRadius,
                      text: confirmText ?? S.of(context).confirm,
                      fontSize: confirmFontSize,
                      fontColor: confirmFontColor,
                      fontWeight: confirmFontWeight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
