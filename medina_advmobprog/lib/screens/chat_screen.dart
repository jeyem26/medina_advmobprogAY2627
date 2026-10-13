import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchText = '';
  String? _profileSyncError;

  @override
  void initState() {
    super.initState();
    _syncCurrentProfile();
  }

  Future<void> _syncCurrentProfile() async {
    if (_chatService.currentUserId == null) return;

    try {
      await UserService().syncCurrentUserProfile();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileSyncError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Chats'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: TextField(
                controller: _searchChatController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchText = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search chat...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_searchChatController.text.isNotEmpty)
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _searchChatController.clear();
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (_profileSyncError != null)
              _emptyState(
                'Unable to load your chat profile: $_profileSyncError',
              )
            else if (currentUserId == null)
              _emptyState('Sign in to view registered users')
            else
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: ScreenUtil().screenHeight * 0.6,
                      padding: EdgeInsets.all(16.sp),
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _emptyState(_userLoadError(snapshot.error));
                  }

                  final registeredUsers = (snapshot.data ?? [])
                      .where((user) => user['uid'] != currentUserId)
                      .toList();
                  final query = _searchText.toLowerCase();
                  final users = registeredUsers.where((user) {
                    final name = _userName(user).toLowerCase();
                    final email = (user['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    return query.isEmpty ||
                        name.contains(query) ||
                        email.contains(query);
                  }).toList();

                  if (users.isEmpty) {
                    final message = registeredUsers.isEmpty
                        ? 'No other registered users yet'
                        : 'No users match your search';
                    return _emptyState(message);
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final name = _userName(user);
                      final email = (user['email'] ?? 'No email').toString();
                      final photoUrl =
                          (user['photoURL'] ??
                                  user['photoUrl'] ??
                                  user['avatarUrl'] ??
                                  '')
                              .toString();

                      return GestureDetector(
                        onTap: () {
                          final receiverId = (user['uid'] ?? '').toString();
                          if (receiverId.isEmpty ||
                              receiverId == currentUserId) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatDetailsScreen(tappedUser: user),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? CustomText(
                                      text: name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                            title: CustomText(
                              text: name,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: CustomText(
                              text: email,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      height: ScreenUtil().screenHeight * 0.6,
      padding: EdgeInsets.all(16.sp),
      child: Center(
        child: CustomText(
          text: message,
          fontSize: 16.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _userName(Map<String, dynamic> user) {
    for (final key in ['displayName', 'username', 'name']) {
      final value = (user[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }

    final firstName = (user['firstName'] ?? '').toString().trim();
    final lastName = (user['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    return (user['email'] ?? 'Unknown user').toString();
  }

  String _userLoadError(Object? error) {
    final code = error is FirebaseException ? error.code : '';
    if (code == 'permission-denied') {
      return 'You do not have permission to view users';
    }
    if (code == 'unavailable' || code == 'network-request-failed') {
      return 'Unable to connect. Check your internet connection';
    }
    return 'Error loading users';
  }
}
