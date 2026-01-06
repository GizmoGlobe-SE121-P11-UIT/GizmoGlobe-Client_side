import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/general/gradient_icon_button.dart';
import '../../../widgets/general/gradient_text.dart';
import '../../../widgets/product/product_minicard.dart';
import '../../../objects/chat_related/chat_message.dart';
import '../../../screens/chat/chat_screen/chat_screen_cubit.dart';
import '../../../screens/chat/chat_screen/chat_screen_state.dart';
import '../../../screens/chat/chat_screen/chat_screen_webview.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => ChatScreenCubit(),
        child: const ChatScreen(),
      );

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RegExp _productLinkRegex =
      RegExp(r'\[PRODUCT_LINK:([^\]]+)\]([^\[]+)\[/PRODUCT_LINK\]');
  final RegExp _productCardsRegex =
      RegExp(r'\[PRODUCT_CARDS\](.*?)\[/PRODUCT_CARDS\]', dotAll: true);
  ChatScreenCubit get cubit => context.read<ChatScreenCubit>();

  @override
  void initState() {
    super.initState();
    cubit.initialize(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<InlineSpan> _buildMessageSpans(
      String content, bool isUser, ThemeData theme) {
    final sanitizedContent = content.replaceAll(_productCardsRegex, '');
    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _productLinkRegex.allMatches(sanitizedContent)) {
      // Thêm text trước link nếu có
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: sanitizedContent.substring(lastIndex, match.start),
          style: TextStyle(
            fontSize: 16,
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ));
      }

      // Thêm tên sản phẩm như text thông thường
      final productName = match.group(2)!;
      spans.add(
        TextSpan(
          text: productName,
          style: TextStyle(
            fontSize: 16,
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Thêm phần text còn lại sau link cuối cùng
    if (lastIndex < sanitizedContent.length) {
      spans.add(TextSpan(
        text: sanitizedContent.substring(lastIndex),
        style: TextStyle(
          fontSize: 16,
          color: isUser
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ));
    }
    return spans;
  }

  List<Map<String, dynamic>> _extractProductCards(String content) {
    final matches = _productCardsRegex.allMatches(content);
    final List<Map<String, dynamic>> result = [];
    for (final match in matches) {
      final jsonString = match.group(1);
      if (jsonString == null || jsonString.isEmpty) continue;
      try {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              result.add(item);
            }
          }
        }
      } catch (e) {
        // Failed to parse product cards
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Use kIsWeb to determine platform
    if (kIsWeb) {
      return const ChatScreenWebView();
    } else {
      // Use mobile implementation
      return BlocBuilder<ChatScreenCubit, ChatScreenState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              leading: GradientIconButton(
                icon: Icons.chevron_left,
                onPressed: () => Navigator.pop(context),
                fillColor: Colors.transparent,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(text: S.of(context).chatSupport),
                  Text(
                    state.isAIMode
                        ? S.of(context).aiAssistant
                        : S.of(context).adminSupport,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    state.isAIMode ? Icons.support_agent : Icons.smart_toy,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    if (state.isAIMode) {
                      await cubit
                          .switchToAdmin(S.of(context).adminWelcomeMessage);
                    } else {
                      await cubit.switchToAI(S.of(context).aiWelcomeMessage);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      // Reverse index to show messages in correct order
                      final reversedIndex = state.messages.length - 1 - index;
                      final message = state.messages[reversedIndex];
                      return _buildMessageBubble(message, theme);
                    },
                  ),
                ),
                _buildMessageInput(theme),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = !message.isFromBot;
    final isAdmin = !message.isAIMode && message.isFromBot;
    final isAI = message.isAIMode && message.isFromBot;
    final sanitizedContent = message.content.replaceAll(_productCardsRegex, '');
    final productCards = _extractProductCards(message.content);

    // Determine colors for AI responses
    final Color bubbleColor;
    if (isUser) {
      bubbleColor = theme.colorScheme.primary;
    } else if (isAdmin) {
      bubbleColor = theme.colorScheme.secondary;
    } else {
      // AI response - use a distinct light blue/gray color
      bubbleColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isAI
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
          boxShadow: isAI
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sanitizedContent.trim().isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: Theme(
                    data: theme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        selectionColor:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                        selectionHandleColor: theme.colorScheme.primary,
                      ),
                    ),
                    child: SelectableText.rich(
                      TextSpan(
                        children: _buildMessageSpans(
                          message.content,
                          isUser,
                          theme,
                        ),
                      ),
                      textAlign: isAI ? TextAlign.justify : TextAlign.start,
                      scrollPhysics: const NeverScrollableScrollPhysics(),
                    ),
                  ),
                ),
                if (!isUser && productCards.isNotEmpty)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: S.of(context).typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                context
                    .read<ChatScreenCubit>()
                    .sendMessage(_messageController.text, context);
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
