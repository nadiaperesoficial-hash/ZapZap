import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

class MessageVoiceNote extends StatefulWidget {
  final Map<String, dynamic> content;
  final int messageId;

  const MessageVoiceNote({super.key, required this.content, required this.messageId});

  @override
  State<MessageVoiceNote> createState() => _MessageVoiceNoteState();
}

class _MessageVoiceNoteState extends State<MessageVoiceNote> {
  bool _isDownloading = false;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadIfNeeded() async {
    final voiceNote = widget.content['voiceNote'];
    final path = voiceNote?['voice']?['local']?['path'];
    final fileId = voiceNote?['voice']?['id'];

    if ((path == null || path.isEmpty) && fileId != null) {
      setState(() => _isDownloading = true);
      try {
        await TDLibClient.downloadFile(fileId: fileId);
      } catch (e) {
        logger.e('Error downloading voice note: $e');
      } finally {
        if (mounted) setState(() => _isDownloading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final voiceNote = widget.content['voiceNote'];
    final duration = voiceNote?['duration'] ?? 0;
    final path = voiceNote?['voice']?['local']?['path'] ?? '';
    final isDownloaded = path.isNotEmpty && File(path).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        _isDownloading
            ? const SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDownloaded ? Icons.play_arrow : Icons.download,
                  color: Colors.white,
                  size: 24,
                ),
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                child: CustomPaint(
                  painter: _WaveformPainter(color: Theme.of(context).colorScheme.primary),
                  size: const Size(double.infinity, 24),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.mic, size: 14, color: Colors.grey),
      ]),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barCount = 30;
    final barWidth = size.width / (barCount * 2);
    final heights = [0.3, 0.5, 0.8, 0.6, 0.4, 0.9, 0.7, 0.5, 0.3, 0.6,
                     0.8, 0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.8, 0.4, 0.7,
                     0.5, 0.3, 0.6, 0.9, 0.4, 0.7, 0.5, 0.8, 0.3, 0.6];

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth;
      final h = size.height * heights[i % heights.length];
      final y1 = (size.height - h) / 2;
      final y2 = y1 + h;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => false;
}
