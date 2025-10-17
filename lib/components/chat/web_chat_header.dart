import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class WebChatHeader extends StatelessWidget {
  final bool isAIMode;
  final VoidCallback onToggleMode;

  const WebChatHeader({
    super.key,
    required this.isAIMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(text: S.of(context).chatSupport),
                Text(
                  isAIMode
                      ? S.of(context).aiAssistant
                      : S.of(context).adminSupport,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onToggleMode,
            icon: Icon(isAIMode ? Icons.support_agent : Icons.smart_toy,
                size: 18),
            label: Text(
              isMobile
                  ? (isAIMode ? 'Admin' : 'AI')
                  : (isAIMode
                      ? S.of(context).switchToAdmin
                      : S.of(context).switchToAI),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
