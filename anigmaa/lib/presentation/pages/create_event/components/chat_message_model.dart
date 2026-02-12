import 'package:flutter/material.dart';

enum ConversationStep {
  greeting,
  askStartDate,
  askStartTime,
  askEndTime,
  askLocation,
  askName,
  askDescription,
  askCategory,
  askPrice,
  askCapacity,
  askPrivacy,
  askImage,
  preview,
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
    this.customWidget,
  }) : timestamp = timestamp ?? DateTime.now();
}
