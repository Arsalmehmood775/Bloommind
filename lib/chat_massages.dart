import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final Timestamp timestamp;
  final String status;
  final bool edited;
  final Map<String, dynamic>? replyTo;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.status,
    required this.edited,
    this.replyTo,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String docId) {
    return ChatMessage(
      id: docId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'Sent',
      replyTo: data['replyTo'],
      edited: data['edited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'status': status,
      'edited': edited,
      if (replyTo != null) 'replyTo': replyTo,
    };
  }

  ChatMessage copyWith({
    String? status,
    bool? edited,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: timestamp,
      status: status ?? this.status,
      edited: edited ?? this.edited,
      replyTo: replyTo,
    );
  }
}
