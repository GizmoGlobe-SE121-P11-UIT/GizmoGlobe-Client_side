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
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add sender indicator for AI messages
                  if (!isUser) ...[
                    Row(
                      children: [
                        Icon(
                          isAdminBot ? Icons.support_agent : Icons.smart_toy,
                          size: 16,
                          color: isAdminBot
                              ? colorScheme.onSurface.withOpacity(0.7)
                              : colorScheme.onSecondaryContainer
                                  .withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAdminBot ? 'Admin' : 'AI Assistant',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAdminBot
                                ? colorScheme.onSurface.withOpacity(0.8)
                                : colorScheme.onSecondaryContainer
                                    .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
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
                  Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (isUser) ...[
                        Icon(
                          Icons.person,
                          size: 12,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : isAdminBot
                                  ? colorScheme.onSurfaceVariant
                                      .withOpacity(0.7)
                                  : colorScheme.onSecondaryContainer
                                      .withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
