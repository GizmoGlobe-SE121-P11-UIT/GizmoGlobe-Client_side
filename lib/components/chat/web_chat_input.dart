import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class WebChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isMobile;
  final VoidCallback onSend;

  const WebChatInput({
    super.key,
    required this.controller,
    required this.isMobile,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: S.of(context).typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: controller.text.trim().isEmpty ? null : onSend,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
