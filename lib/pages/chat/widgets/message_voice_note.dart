import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _player = AudioPlayer();
  bool _isDownloading = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _localPath = '';

  @override
  void initState() {
    super.initState();

    // Pega o path inicial se já existir
    final voiceNote = widget.content['voiceNote'];
    final path = voiceNote?['voice']?['local']?['path'] ?? '';
    if (path.isNotEmpty && File(path).existsSync()) {
      _localPath = path;
    } else {
      _downloadIfNeeded();
    }

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _downloadIfNeeded() async {
    final voiceNote = widget.content['voiceNote'];
    final fileId = voiceNote?['voice']?['id'];
    if (fileId == null) return;

    if (mounted) setState(() => _isDownloading = true);
    try {
      await TDLibClient.downloadFile(fileId: fileId);
      // Aguarda um pouco para o arquivo ser escrito
      await Future.delayed(const Duration(milliseconds: 500));
      // Tenta pegar o path atualizado via getFile
      final path = voiceNote?['voice']?['local']?['path'] ?? '';
      if (path.isNotEmpty && File(path).existsSync()) {
        if (mounted) setState(() => _localPath = path);
      }
    } catch (e) {
      logger.e('Error downloading voice note: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_localPath.isEmpty || !File(_localPath).existsSync()) {
      await _downloadIfNeeded();
      if (_localPath.isEmpty) return;
    }

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(_localPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceNote = widget.content['voiceNote'];
    final totalSeconds = voiceNote?['duration'] ?? 0;
    final totalDuration = _duration.inSeconds > 0 ? _duration : Duration(seconds: totalSeconds);
    final progress = totalDuration.inSeconds > 0
        ? (_position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final isReady = _localPath.isNotEmpty && File(_localPath).existsSync();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: _isDownloading ? null : _togglePlay,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: _isDownloading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    !isReady
                        ? Icons.download
                        : (_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 26,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isPlaying ? _formatDuration(_position) : _formatDuration(totalDuration),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const Icon(Icons.mic, size: 12, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
