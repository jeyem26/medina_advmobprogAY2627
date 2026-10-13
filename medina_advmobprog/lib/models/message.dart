import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final Timestamp? timestamp;
  final String status;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.timestamp,
    this.status = 'sent',
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp'] as Timestamp
          : null,
      status: (map['status'] ?? 'sent').toString(),
    );
  }

  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : timestamp,
      'status': status,
    };
  }
}
