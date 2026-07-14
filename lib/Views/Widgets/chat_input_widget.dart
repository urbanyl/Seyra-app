import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seyra/l10n/app_localizations.dart';

enum _AttachAction { camera, gallery, file, gif }

const int _maxFileSize = 500 * 1024;

class ChatInputWidget extends StatefulWidget {
  final Function createChatDoc;
  final Function(bool isTyping)? onTypingChanged;

  ChatInputWidget(this.createChatDoc, {this.onTypingChanged});

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  String? mediaMessage;
  late final TextEditingController _controller;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onTypingChanged == null) return;
    final text = _controller.text;
    if (text.isEmpty) {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged!(false);
      }
      _typingTimer?.cancel();
      return;
    }
    
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingChanged!(true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged!(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 12.0 + bottomPad,
          top: 8.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.surface
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        cursorColor: theme.colorScheme.onSurface,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 15.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: t.chatHint,
                          hintStyle: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.add_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        size: 22,
                      ),
                      onPressed: () => showMyBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: IconButton(
                onPressed: () {
                  final txt = _controller.text.trim();
                  if (txt.isNotEmpty) {
                    widget.createChatDoc(txt, '');
                    _controller.clear();
                  }
                },
                icon: Icon(
                  Icons.send_rounded,
                  color: theme.colorScheme.onTertiary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  showMyBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        side: BorderSide(color: theme.dividerColor, width: 2),
      ),
      builder: (context) {
        final availableWidth = MediaQuery.of(context).size.width - 32.0;
        final itemWidth = (availableWidth - 8.0) / 2.0;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                  child: Text(
                    'SECURE TRANSFER',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: createButtonCard(
                        context,
                        _AttachAction.camera,
                        t.useCamera,
                        Icons.photo_camera_outlined,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: createButtonCard(
                        context,
                        _AttachAction.gallery,
                        t.useGallery,
                        Icons.image_outlined,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: createButtonCard(
                        context,
                        _AttachAction.file,
                        t.sendFile,
                        Icons.add,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: createButtonCard(
                        context,
                        _AttachAction.gif,
                        t.sendGif,
                        Icons.gif_box_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget createButtonCard(
    BuildContext context,
    _AttachAction action,
    String label,
    IconData icondata,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        handleBottomButtuns(action);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icondata, color: theme.colorScheme.onSurface, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  handleBottomButtuns(_AttachAction action) {
    switch (action) {
      case _AttachAction.camera:
        handleUseCamera(ImageSource.camera);
        break;
      case _AttachAction.gallery:
        handleUseCamera(ImageSource.gallery);
        break;
      case _AttachAction.file:
        handleFile();
        break;
      case _AttachAction.gif:
        handleGif();
        break;
    }
  }

  void handleUseCamera(ImageSource source) async {
    final imagePicker = ImagePicker();
    try {
      final xfile = await imagePicker.pickImage(source: source, imageQuality: 20);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      mediaMessage = 'data:image/jpeg;base64,$b64';
      widget.createChatDoc('', mediaMessage);
    } catch (_) {}
  }

  void handleFile() async {
    final result = await fp.FilePicker.pickFiles(withData: true);
    if (result == null) return;
    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;
    if (fileBytes.length > _maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File too large. Max 500KB.', style: TextStyle(fontFamily: 'Hanken Grotesk')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final fileName = result.files.first.name;
    final b64 = base64Encode(fileBytes);
    mediaMessage = 'data:file;name=$fileName;base64,$b64';
    widget.createChatDoc('', mediaMessage);
  }

  void handleGif() async {
    final result = await fp.FilePicker.pickFiles(
      withData: true,
      type: fp.FileType.custom,
      allowedExtensions: ['gif'],
    );
    if (result == null) return;
    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;
    if (fileBytes.length > _maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File too large. Max 500KB.', style: TextStyle(fontFamily: 'Hanken Grotesk')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final b64 = base64Encode(fileBytes);
    mediaMessage = 'data:image/gif;base64,$b64';
    widget.createChatDoc('', mediaMessage);
  }
}
