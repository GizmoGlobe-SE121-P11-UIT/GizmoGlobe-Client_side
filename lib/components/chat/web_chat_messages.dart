import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gizmoglobe_client/objects/chat_related/chat_message.dart';

class WebChatMessages extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isMobile;
  final ScrollController controller;
  final List<InlineSpan> Function(String, Color, ThemeData) buildMessageSpans;

  const WebChatMessages({
    super.key,
    required this.messages,
    required this.isMobile,
    required this.controller,
    required this.buildMessageSpans,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      shrinkWrap: false,
      physics: const BouncingScrollPhysics(),
      controller: controller,
      reverse: true,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = !message.isFromBot;
        final isAdminBot =
            !message.isAIMode && message.isFromBot; // admin reply
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile
                    ? MediaQuery.of(context).size.width * 0.75
                    : MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : isAdminBot
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: buildMessageSpans(
                        message.content,
                        isUser
                            ? colorScheme.onPrimary
                            : isAdminBot
                                ? colorScheme.onSurface
                                : colorScheme.onSecondaryContainer,
                        Theme.of(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : isAdminBot
                              ? colorScheme.onSurfaceVariant.withOpacity(0.7)
                              : colorScheme.onSecondaryContainer
                                  .withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
