import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_message_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isBot ? AppColors.white : AppColors.secondary,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isBot ? const Radius.circular(4) : null,
                  bottomRight: message.isBot ? null : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.customWidget ??
                  Text(
                    message.text,
                    style: AppTextStyles.button.copyWith(
                      fontSize: 15,
                      color: message.isBot ? AppColors.textEmphasis : AppColors.primary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
