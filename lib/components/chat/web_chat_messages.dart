import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gizmoglobe_client/objects/chat_related/chat_message.dart';
import 'package:gizmoglobe_client/widgets/product/product_minicard.dart';

class WebChatMessages extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isMobile;
  final ScrollController controller;
  final List<InlineSpan> Function(String, Color, ThemeData) buildMessageSpans;
  final String Function(String) sanitizeContent;
  final List<Map<String, dynamic>> Function(String) extractProductCards;

  const WebChatMessages({
    super.key,
    required this.messages,
    required this.isMobile,
    required this.controller,
    required this.buildMessageSpans,
    required this.sanitizeContent,
    required this.extractProductCards,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      shrinkWrap: false,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // With reverse: true, index 0 is the last message, so we need to reverse the index
        final reversedIndex = messages.length - 1 - index;
        final message = messages[reversedIndex];
        final isUser = !message.isFromBot;
        final isAdminBot =
            !message.isAIMode && message.isFromBot; // admin reply
        final sanitizedContent = sanitizeContent(message.content);
        final productCards = extractProductCards(message.content);
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
                          color: colorScheme.primary.withValues(alpha: 0.1),
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
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : colorScheme.onSecondaryContainer
                                  .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAdminBot ? 'Admin' : 'AI Assistant',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAdminBot
                                ? colorScheme.onSurface.withValues(alpha: 0.8)
                                : colorScheme.onSecondaryContainer
                                    .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (sanitizedContent.trim().isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        children: buildMessageSpans(
                          sanitizedContent,
                          isUser
                              ? colorScheme.onPrimary
                              : isAdminBot
                                  ? colorScheme.onSurface
                                  : colorScheme.onSecondaryContainer,
                          Theme.of(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!isUser && productCards.isNotEmpty) ...[
                    Column(
                      children: productCards
                          .map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ProductMiniCard(cardData: card),
                            ),
                          )
                          .toList(),
                    ),
                  ],
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
                          color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.7)
                              : isAdminBot
                                  ? colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7)
                                  : colorScheme.onSecondaryContainer
                                      .withValues(alpha: 0.7),
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
