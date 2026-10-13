import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medina_advmobprog/widgets/custom_text.dart';

import '../services/chat_service.dart';

class ChatDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tappedUser;

  const ChatDetailsScreen({super.key, required this.tappedUser});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final Set<String> _markingSeen = <String>{};

  late final Future<void> _conversationReady;
  bool _isSending = false;
  String? _lastNewestMessageId;

  String? get _currentUserId => _chatService.currentUserId;
  String get _receiverId => (widget.tappedUser['uid'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _conversationReady = _chatService.ensureConversation(_receiverId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_currentUserId == null || _receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify this conversation.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(_receiverId, text);
      if (!mounted) return;

      _msgCtrl.clear();
      _msgFocus.requestFocus();
      if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: ${_errorMessage(error)}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _markMessagesSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
    String currentUserId,
  ) {
    final unseenMessages = messages.where((document) {
      final data = document.data();
      return data['receiverId'] == currentUserId &&
          data['status'] != 'seen' &&
          !_markingSeen.contains(document.id);
    }).toList();

    if (unseenMessages.isEmpty) return;
    _markingSeen.addAll(unseenMessages.map((message) => message.id));

    unawaited(() async {
      try {
        await _chatService.markMessagesSeen(unseenMessages, currentUserId);
      } catch (error) {
        debugPrint('Unable to update message read receipts: $error');
      } finally {
        _markingSeen.removeAll(unseenMessages.map((message) => message.id));
      }
    }());
  }

  void _scrollToNewestMessage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) {
    if (messages.isEmpty || messages.first.id == _lastNewestMessageId) return;
    _lastNewestMessageId = messages.first.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _errorMessage(Object? error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You do not have permission to access this conversation.';
      }
      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        return 'Network unavailable. Check your connection and try again.';
      }
      return error.message ?? 'A Firestore error occurred.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _receiverName() {
    for (final key in ['displayName', 'username', 'name', 'firstName']) {
      final value = (widget.tappedUser[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return (widget.tappedUser['email'] ?? 'Chat').toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;
    if (currentUserId == null || _receiverId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Unable to load conversation user data')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: CustomText(text: _receiverName(), fontSize: 25.sp),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _conversationReady,
              builder: (context, conversationSnapshot) {
                if (conversationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (conversationSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Text(
                        'Error opening conversation: '
                        '${_errorMessage(conversationSnapshot.error)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _chatService.getMessages(currentUserId, _receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Text(
                            'Error loading messages: '
                            '${_errorMessage(snapshot.error)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final messages = snapshot.data?.docs ?? [];
                    _markMessagesSeen(messages, currentUserId);
                    _scrollToNewestMessage(messages);

                    if (messages.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final document = messages[index];
                        final data = document.data();
                        final message = (data['message'] ?? '').toString();
                        final isMe = data['senderId'] == currentUserId;
                        final status = (data['status'] ?? 'sent').toString();
                        final isPending = document.metadata.hasPendingWrites;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(document.id),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          builder: (context, progress, child) {
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 8 * (1 - progress)),
                                child: child,
                              ),
                            );
                          },
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.5)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12)
                                    .copyWith(
                                      bottomLeft: isMe
                                          ? const Radius.circular(12)
                                          : Radius.zero,
                                      bottomRight: isMe
                                          ? Radius.zero
                                          : const Radius.circular(12),
                                    ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: CustomText(
                                      text: message.isNotEmpty
                                          ? message
                                          : '[empty]',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.normal,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  if (isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isPending
                                                ? 'Sending'
                                                : status == 'seen'
                                                ? 'Seen'
                                                : 'Sent',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (!isPending)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 3,
                                              ),
                                              child: Icon(
                                                status == 'seen'
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 13.sp,
                                                color: status == 'seen'
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _msgFocus,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontFamily: 'Poppins'),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _msgCtrl.text.trim().isEmpty
                              ? null
                              : _send,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
