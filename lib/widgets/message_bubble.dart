import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;

  const MessageBubble({required this.msg, required this.isMe, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: msg.type == 'image'
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          // surfaceVariant fue eliminado en Flutter 3.22+ → surfaceContainerHighest
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && msg.fromUsername.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(msg.fromUsername,
                    style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.blueGrey,
                        fontWeight: FontWeight.w600)),
              ),
            if (msg.type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  imageUrl: msg.content,
                  width: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
              )
            else
              Text(
                msg.content,
                style:
                    TextStyle(color: isMe ? Colors.white : null, fontSize: 15),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(msg.createdAt),
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white60 : Colors.grey),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _statusIcon(msg.status),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all,
            size: 14, color: Colors.lightBlueAccent);
      case 'delivered':
        return const Icon(Icons.done_all, size: 14, color: Colors.white60);
      default:
        return const Icon(Icons.done, size: 14, color: Colors.white60);
    }
  }

  String _time(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
