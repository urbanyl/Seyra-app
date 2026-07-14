import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ChatBubble extends StatelessWidget {
  final String chatText;
  final String chatMedia;
  final bool isFromMe;
  final Key textKey;
  final String formattedTime;
  final VoidCallback? onLongPress;
  final String senderName;

  ChatBubble(
    this.chatText,
    this.isFromMe,
    this.textKey,
    this.chatMedia, {
    this.formattedTime = '',
    this.onLongPress,
    this.senderName = '',
  });

  Future<void> _downloadImage(BuildContext context, String url) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download not supported on web in this build.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      Directory? baseDir = await getExternalStorageDirectory();
      baseDir ??= await getApplicationDocumentsDirectory();

      final targetDir = Directory('${baseDir.path}${Platform.pathSeparator}seyra_downloads');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName = _fileNameFromUrl(url);
      final targetFile = File('${targetDir.path}${Platform.pathSeparator}$fileName');
      await targetFile.writeAsBytes(response.bodyBytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${targetFile.path}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final raw = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image';
      final cleaned = raw.split('?').first;
      if (cleaned.toLowerCase().endsWith('.png') ||
          cleaned.toLowerCase().endsWith('.jpg') ||
          cleaned.toLowerCase().endsWith('.jpeg') ||
          cleaned.toLowerCase().endsWith('.gif')) {
        return cleaned;
      }
      return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (_) {
      return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
  }

  void _openImageViewer(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text(''),
              actions: [
                IconButton(
                  onPressed: () => _downloadImage(context, url),
                  icon: const Icon(Icons.download_rounded),
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isFromMe ? 20 : 4),
      bottomRight: Radius.circular(isFromMe ? 4 : 20),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bubbleColor = isFromMe
        ? theme.colorScheme.tertiary
        : (isDark ? theme.colorScheme.surface : const Color(0xFFF2F2F2));

    final Color textColor = isFromMe
        ? theme.colorScheme.onTertiary
        : theme.colorScheme.onSurface;

    final String mediaLower = chatMedia.toLowerCase();
    final bool isImageMedia = mediaLower.endsWith('.png') ||
        mediaLower.endsWith('.jpg') ||
        mediaLower.endsWith('.jpeg') ||
        mediaLower.endsWith('.gif') ||
        mediaLower.contains('/chats/images/') ||
        mediaLower.contains('/chats/gifs/');

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
              isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isFromMe && senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 3),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment:
                  isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: bubbleBorderRadius,
                    border: isFromMe
                        ? Border.all(
                            color: const Color(0xFF111111).withOpacity(0.05),
                            width: 1)
                        : Border.all(
                            color: const Color(0xFF111111).withOpacity(0.03),
                            width: 1),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chatMedia.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: isImageMedia
                              ? InkWell(
                                  onTap: () => _openImageViewer(context, chatMedia),
                                  child: Image.network(
                                    chatMedia,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 160,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.05),
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: theme.colorScheme.onSurface,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: 120,
                                      color: Colors.red.withOpacity(0.1),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.error_outline,
                                          color: Colors.red),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 12),
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(isDark ? 0.06 : 0.04),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 18,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          chatMedia.split('/').last,
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (chatText.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (chatText.isNotEmpty)
                        Text(
                          chatText,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: textColor,
                            fontWeight:
                                isFromMe ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 15.5,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (formattedTime.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isFromMe ? 0 : 24,
                  right: isFromMe ? 24 : 0,
                  top: 4,
                  bottom: 2,
                ),
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
