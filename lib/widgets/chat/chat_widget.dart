import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../theme/theme_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'chat_bubble.dart';

class ChatWidget extends ConsumerStatefulWidget {
  final String gameId;
  final String userId;
  final String userName;

  const ChatWidget({
    Key? key,
    required this.gameId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isTyping = false;
  bool _isComposing = false;
  String? _hostId;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = ref.read(chatServiceProvider);
    final isDarkMode = ref.read(themeControllerProvider);

    try {
      await chatService.sendMessage(
        lobbyId: widget.gameId,
        senderId: widget.userId,
        senderName: widget.userName,
        content: _messageController.text.trim(),
        type: 'user',
        chatTheme: isDarkMode ? ChatTheme.night : ChatTheme.day,
      );

      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeControllerProvider);
    final chatService = ref.watch(chatServiceProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: chatService.getMessages(widget.gameId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              final messages = snapshot.data!;

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Démarrez la conversation...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.senderId == widget.userId;
                  final isHost = message.senderId == _hostId;

                  // Déterminer si ce message est le premier d'une séquence du même expéditeur
                  final bool isFirstInSequence = index == 0 || 
                      messages[index - 1].senderId != message.senderId;
                  
                  // Déterminer si on affiche l'avatar
                  final bool showAvatar = isFirstInSequence || index == messages.length - 1;
                  
                  // N'afficher le nom de l'expéditeur que pour le premier message d'une séquence
                  return ChatBubble(
                    message: message,
                    isCurrentUser: isCurrentUser,
                    isHost: isHost,
                    showAvatar: showAvatar,
                    showSenderName: true,
                    onLongPress: isCurrentUser ? () {
                      // Fonctionnalité future : supprimer son propre message
                    } : null,
                  );
                },
              );
            },
          ),
        ),
        _buildTypingIndicator(isDarkMode),
        _buildMessageComposer(isDarkMode, theme),
      ],
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    if (!_isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quelqu\'un écrit',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(3, (index) => 
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.black.withOpacity(0.3)
          : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.sentiment_satisfied_alt_outlined,
                color: _isComposing ? theme.primaryColor : Colors.grey,
              ),
              onPressed: () {
                // Fonctionnalité future : sélection d'émojis
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre message...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _isComposing 
                  ? theme.primaryColor
                  : (isDarkMode ? Colors.white38 : Colors.black38),
              ),
              onPressed: _isComposing ? _sendMessage : null,
            ),
          ],
        ),
      ),
    );
  }
} 