import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../theme/theme_controller.dart';

class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isHost;
  final VoidCallback? onLongPress;
  final bool showAvatar;
  final bool showSenderName;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.isHost = false,
    this.onLongPress,
    this.showAvatar = true,
    this.showSenderName = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeControllerProvider);
    final isSystem = message.type == 'system';
    final theme = Theme.of(context);

    if (isSystem) {
      return _buildSystemMessage(isDarkMode, context);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 2.0,
        bottom: 2.0,
        left: isCurrentUser ? 40.0 : 8.0,
        right: isCurrentUser ? 8.0 : 40.0,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar) _buildAvatar(context),
          const SizedBox(width: 4),
          Flexible(
            child: InkWell(
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _getBubbleColor(isDarkMode, theme),
                  borderRadius: _getBubbleBorderRadius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderName,
                            style: TextStyle(
                              color: _getSenderNameColor(isDarkMode, isHost),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isHost) ...[
                            const SizedBox(width: 4),
                            _buildHostBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (isCurrentUser && isHost) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHostBadge(),
                          const SizedBox(width: 4),
                          Text(
                            message.senderName,
                            style: TextStyle(
                              color: _getSenderNameColor(isDarkMode, isHost),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ] else if (isCurrentUser) ...[
                      Text(
                        message.senderName,
                        style: TextStyle(
                          color: _getSenderNameColor(isDarkMode, isHost),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 9,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black45,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.done_all,
                                size: 12,
                                color: theme.primaryColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (isCurrentUser && showAvatar) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(bool isDarkMode, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final primaryColor = isHost
        ? Colors.amber
        : Theme.of(context).primaryColor;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message.senderName.isNotEmpty 
              ? message.senderName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildHostBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Hôte',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BorderRadius _getBubbleBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isCurrentUser
          ? const Radius.circular(16)
          : const Radius.circular(4),
      bottomRight: isCurrentUser
          ? const Radius.circular(4)
          : const Radius.circular(16),
    );
  }

  Color _getBubbleColor(bool isDarkMode, ThemeData theme) {
    if (isCurrentUser) {
      if (isHost) {
        return isDarkMode 
            ? const Color(0xFFAA6500).withOpacity(0.8)
            : const Color(0xFFFFA000).withOpacity(0.9);
      } else {
        return isDarkMode 
            ? const Color(0xFF1A237E).withOpacity(0.8)
            : theme.primaryColor.withOpacity(0.9);
      }
    } else {
      if (isHost) {
        return isDarkMode
            ? const Color(0xFF664500).withOpacity(0.7)
            : const Color(0xFFFFECB3).withOpacity(0.9);
      } else {
        return isDarkMode
            ? const Color(0xFF2D3748).withOpacity(0.7)
            : const Color(0xFFF5F5F5);
      }
    }
  }

  Color _getSenderNameColor(bool isDarkMode, bool isHost) {
    if (isHost) {
      return Colors.amber;
    } else if (isDarkMode) {
      return Colors.lightBlue;
    } else {
      return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final diff = now.difference(timestamp);
      if (diff.inMinutes < 1) {
        return 'à l\'instant';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min';
      } else if (diff.inHours < 24 && now.day == timestamp.day) {
        return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      } else {
        return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
} 