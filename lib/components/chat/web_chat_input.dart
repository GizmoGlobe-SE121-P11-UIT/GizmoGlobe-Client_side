import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class WebChatInput extends StatefulWidget {
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
  State<WebChatInput> createState() => _WebChatInputState();
}

class _WebChatInputState extends State<WebChatInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
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
                  widget.onSend();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed:
                widget.controller.text.trim().isEmpty ? null : widget.onSend,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
