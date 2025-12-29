import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import '../../../objects/chat_related/chat_message.dart';
import '../../../enums/processing/process_state_enum.dart';
import '../../../screens/chat/chat_screen/chat_screen_cubit.dart';
import '../../../screens/chat/chat_screen/chat_screen_state.dart';
// import '../../../components/general/web_footer.dart';
import '../../../components/chat/web_chat_header.dart';
import '../../../components/chat/web_chat_messages.dart';
import '../../../components/chat/web_chat_input.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class ChatScreenWebView extends StatefulWidget {
  const ChatScreenWebView({super.key, this.embedded = false});

  // When embedded in floating panel, we hide the site header to avoid nesting
  final bool embedded;

  static Widget newInstance({bool embedded = false}) => BlocProvider(
        create: (context) => ChatScreenCubit(),
        child: ChatScreenWebView(embedded: embedded),
      );

  @override
  State<ChatScreenWebView> createState() => _ChatScreenWebViewState();
}

class _ChatScreenWebViewState extends State<ChatScreenWebView> {
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
    // Initialize scroll position at bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Scroll to top since we're using reverse: true
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<InlineSpan> _buildMessageSpans(
      String content, Color textColor, ThemeData theme) {
    final sanitizedContent = _stripProductCardMarkup(content);
    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _productLinkRegex.allMatches(sanitizedContent)) {
      // Thêm text trước link nếu có
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: sanitizedContent.substring(lastIndex, match.start),
          style: TextStyle(
            fontSize: 16,
            color: textColor,
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
            color: textColor,
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
          color: textColor,
        ),
      ));
    }

    return spans;
  }

  String _stripProductCardMarkup(String content) {
    return content.replaceAll(_productCardsRegex, '');
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
        if (kDebugMode) {
          print('Failed to parse product cards: $e');
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebView(context);
  }

  Widget _buildWebView(BuildContext context) {
    return BlocBuilder<ChatScreenCubit, ChatScreenState>(
      buildWhen: (previous, current) {
        // Rebuild when messages change
        return previous.messages.length != current.messages.length ||
            previous.processState != current.processState;
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        // final colorScheme = theme.colorScheme; // kept for future styling hooks
        final isMobile = MediaQuery.of(context).size.width < 600;

        // Show loading indicator while initializing (idle or loading with no messages)
        final isInitializing = (state.processState == ProcessState.idle ||
                state.processState == ProcessState.loading) &&
            state.messages.isEmpty;

        if (isInitializing) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              color: theme.colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).loading,
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Scroll to bottom only when new messages arrive (not on every rebuild)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check if this is actually a new message by comparing with buildWhen condition
          if (state.messages.isNotEmpty && _scrollController.hasClients) {
            // Only scroll if at bottom or new message
            final isAtBottom = _scrollController.position.pixels == 0.0;
            if (isAtBottom) {
              _scrollToBottom();
            }
          }
        });

        return Scaffold(
          body: Column(
            children: [
              // Web Header removed for embedded mode
              // Chat Content (fills remaining height)
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      // Chat Header (component)
                      WebChatHeader(
                        isAIMode: state.isAIMode,
                        onToggleMode: () async {
                          if (state.isAIMode) {
                            await cubit.switchToAdmin(
                                S.of(context).adminWelcomeMessage);
                          } else {
                            await cubit
                                .switchToAI(S.of(context).aiWelcomeMessage);
                          }
                        },
                      ),
                      // Messages List (fills within chat content)
                      Expanded(
                        child: WebChatMessages(
                          messages: state.messages,
                          isMobile: isMobile,
                          controller: _scrollController,
                          buildMessageSpans: _buildMessageSpans,
                          sanitizeContent: _stripProductCardMarkup,
                          extractProductCards: _extractProductCards,
                        ),
                      ),
                      // Message Input
                      WebChatInput(
                        controller: _messageController,
                        isMobile: isMobile,
                        onSend: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            cubit.sendMessage(
                                _messageController.text.trim(), context);
                            _messageController.clear();
                            _scrollToBottom();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Footer removed to keep input anchored to the bottom
            ],
          ),
        );
      },
    );
  }

  // Message bubble rendering has been moved into WebChatMessages component.
}
