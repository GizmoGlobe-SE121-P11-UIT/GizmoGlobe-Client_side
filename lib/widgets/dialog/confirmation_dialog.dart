import 'package:flutter/material.dart';
import '../general/app_text_style.dart';
import '../general/gradient_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ButtonStyle? confirmButtonStyle;
  final ButtonStyle? cancelButtonStyle;

  const ConfirmationDialog({
    super.key,
    this.title = '',
    this.content = '',
    this.confirmText = 'Confirm', //Xác nhận
    this.cancelText = 'Cancel', //Hủy
    this.onConfirm,
    this.onCancel,
    this.confirmButtonStyle,
    this.cancelButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyle.smallTitle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: AppTextStyle.regularText.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm?.call();
                      },
                      style: confirmButtonStyle ??
                          ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      child: Text(
                        confirmText,
                        style: AppTextStyle.buttonTextBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel?.call();
                      },
                      style: cancelButtonStyle ??
                          ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      child: Text(
                        cancelText,
                        style: AppTextStyle.buttonTextBold,
                      ),
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
