import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medina_advmobprog/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return <String, dynamic>{...doc.data(), 'uid': doc.id};
      }).toList();
    });
  }

  String conversationIdFor(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return ids.join('_');
  }

  Future<void> ensureConversation(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Sign in before opening a conversation.');
    }
    if (otherUserId.isEmpty || otherUserId == userId) {
      throw ArgumentError('Choose another registered user to chat with.');
    }

    final participants = [userId, otherUserId]..sort();
    await _firestore
        .collection('chatRooms')
        .doc(conversationIdFor(userId, otherUserId))
        .set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final senderId = currentUserId;
    if (senderId == null) {
      throw StateError('Sign in before sending a message.');
    }
    if (receiverId.isEmpty || receiverId == senderId) {
      throw ArgumentError('Choose another registered user to chat with.');
    }
    if (message.trim().isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    final chatRoomId = conversationIdFor(senderId, receiverId);
    final chatRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final messageRef = chatRef.collection('messages').doc();
    final newMessage = MessageModel(
      senderId: senderId,
      receiverId: receiverId,
      message: message.trim(),
    );

    final batch = _firestore.batch();
    final chatData = <String, dynamic>{
      'participants': [senderId, receiverId]..sort(),
      'lastMessage': message.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    };

    batch.set(chatRef, chatData, SetOptions(merge: true));
    batch.set(messageRef, newMessage.toMap(useServerTimestamp: true));
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String userId,
    String otherUserId,
  ) {
    final chatRoomId = conversationIdFor(userId, otherUserId);

    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> markMessagesSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
    String currentUserId,
  ) async {
    final unseenMessages = messages.where((document) {
      final data = document.data();
      return data['receiverId'] == currentUserId && data['status'] != 'seen';
    }).toList();

    for (var start = 0; start < unseenMessages.length; start += 450) {
      final end = (start + 450).clamp(0, unseenMessages.length);
      final batch = _firestore.batch();
      for (final document in unseenMessages.sublist(start, end)) {
        batch.update(document.reference, {
          'status': 'seen',
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
