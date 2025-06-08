import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lobby.dart';
import 'chat/chat_bubble.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LobbyChat extends ConsumerStatefulWidget {
  final String lobbyId;
  final String userId;
  final String userName;

  const LobbyChat({
    Key? key,
    required this.lobbyId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  ConsumerState<LobbyChat> createState() => _LobbyChatState();
}

class _LobbyChatState extends ConsumerState<LobbyChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isComposing = false;
  String? _hostId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isComposing = _textController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      final chatService = ref.read(chatServiceProvider);
      chatService.sendMessage(
        lobbyId: widget.lobbyId,
        senderId: widget.userId,
        senderName: widget.userName,
        content: message,
        type: 'user',
      );
      _textController.clear();
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatService = ref.watch(chatServiceProvider);
    final theme = Theme.of(context);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: chatService.getMessages(widget.lobbyId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur de chargement des messages',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
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
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Démarrez la conversation...',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection('lobbies').doc(widget.lobbyId).snapshots(),
                builder: (context, lobbySnapshot) {
                  if (lobbySnapshot.hasData && lobbySnapshot.data != null) {
                    final lobby = Lobby.fromFirestore(lobbySnapshot.data!);
                    _hostId = lobby.hostId;
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
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
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        _buildMessageComposer(isDark, Theme.of(context)),
      ],
    );
  }

  Widget _buildMessageComposer(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
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
                  color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: _isComposing 
                  ? theme.primaryColor
                  : (isDark ? Colors.white38 : Colors.black38),
              ),
              onPressed: _isComposing ? _handleSendMessage : null,
            ),
          ],
        ),
      ),
    );
  }
} 