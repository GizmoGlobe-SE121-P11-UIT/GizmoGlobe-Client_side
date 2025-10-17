import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import '../../../objects/chat_related/chat_message.dart';
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<InlineSpan> _buildMessageSpans(
      String content, Color textColor, ThemeData theme) {
    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _productLinkRegex.allMatches(content)) {
      // Thêm text trước link nếu có
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
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
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebView(context);
  }

  Widget _buildWebView(BuildContext context) {
    return BlocBuilder<ChatScreenCubit, ChatScreenState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        // final colorScheme = theme.colorScheme; // kept for future styling hooks
        final isMobile = MediaQuery.of(context).size.width < 600;

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
