import 'package:seyra/Views/Screens/call_screen.dart';
import 'package:seyra/Views/Screens/group_members_screen.dart';
import 'package:seyra/Views/Widgets/chat_bubble.dart';
import 'package:seyra/Views/Widgets/chat_input_widget.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  static const ROUTE_NAME = '/chats';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? docID;
  bool isFirst = true;
  String? contactUid;
  String contactProfile = '';
  String displayName = 'Someone';
  bool isGroup = false;
  var state = false;
  bool hasChatBeenCreated = false;

  Stream<QuerySnapshot>? _messagesStream;
  Stream<DocumentSnapshot>? _chatDocStream;

  // Cache uid → display name for group member name labels
  final Map<String, String> _senderNameCache = {};

  String _formatTime(Timestamp? timestamp) {
    final dateTime = timestamp != null ? timestamp.toDate() : DateTime.now();
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minuteStr = minute < 10 ? '0$minute' : '$minute';
    return '$hour:$minuteStr $period';
  }

  Future<String> _getSenderName(String uid) async {
    if (_senderNameCache.containsKey(uid)) {
      return _senderNameCache[uid]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final name = (doc.data()!['displayName'] ?? '').toString().trim();
        final result = name.isNotEmpty ? name : (doc.data()!['username'] ?? uid);
        _senderNameCache[uid] = result;
        return result;
      }
    } catch (_) {}
    _senderNameCache[uid] = uid;
    return uid;
  }

  Future<void> _removeChatHistory() async {
    if (docID == null) return;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: Text('Remove Chat History', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Text(
            'Are you sure you want to permanently delete all messages in this chat? This cannot be undone.',
            style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Removing chat history...',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        final messagesRef =
            FirebaseFirestore.instance.collection('chats/$docID/messages');
        final snapshot = await messagesRef.get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chat history removed successfully.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Color(0xFF111111),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to clear chat history. Please try again.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _purgeRemoteIdentity() async {
    if (docID == null) return;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: Text('Purge Remote Identity', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Text(
            'This will delete all shared cryptographic keys and break the encrypted channel. Are you absolutely sure?',
            style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Purge', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purging secure identity keys...',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Color(0xFF111111),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        final messagesRef =
            FirebaseFirestore.instance.collection('chats/$docID/messages');
        final snapshot = await messagesRef.get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(docID)
            .delete();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .update({
          'chats': FieldValue.arrayRemove([docID]),
        });
        if (contactUid != null && contactUid!.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(contactUid)
              .update({
            'chats': FieldValue.arrayRemove([docID]),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Secure identity purged successfully.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Color(0xFF111111),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to purge secure identity. Please try again.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    if (docID == null) return;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: const Text(
          'Leave Group',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Are you sure you want to leave this group chat? You will not be able to see the messages until you are re-added.',
          style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUid = FirebaseAuth.instance.currentUser!.uid;
        // Remove from chat's users list
        await FirebaseFirestore.instance.collection('chats').doc(docID).update({
          'users': FieldValue.arrayRemove([currentUid]),
        });

        // Remove from user's chats list
        await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
          'chats': FieldValue.arrayRemove([docID]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have left the group.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Color(0xFF111111),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Pop chat screen back to home/main screen
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to leave group. Please try again.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleUnsendMessage(String messageId, bool isMe) async {
    if (!isMe) return;

    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: Text('Unsend Message', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Text(
            'Are you sure you want to unsend this message? It will be deleted for everyone.',
            style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unsend', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('chats/$docID/messages')
            .doc(messageId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message deleted for everyone.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Color(0xFF111111),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to delete message. Please check your connection.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _updateTypingStatus(bool isTyping) {
    if (docID == null) return;
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('chats').doc(docID).set({
      'typingStatus': {
        myUid: isTyping,
      }
    }, SetOptions(merge: true));
  }

  void createChatDoc(String textMessage, String mediaMessage) async {
    try {
      await createChatDocument();
      await createMessageDocument(textMessage, mediaMessage);
      await updateCurrentUserChatProperty();
      await updateContactChatProperty();
      updateState();
    } catch (error) {
      handleCreateChatDocError(error);
    }
  }

  void handleCreateChatDocError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to initialize secure connection. Please check your internet.',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    throw error;
  }

  void updateState() {
    if (hasChatBeenCreated) {

      if (state) {
        setState(() => null);
        state = false;
      }
    }
  }

  Future<void> updateContactChatProperty() async {
    if (hasChatBeenCreated) {
      if (contactUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(contactUid)
            .update({'chats': FieldValue.arrayUnion([docID])});
      }
    }
  }

  Future<void> updateCurrentUserChatProperty() async {
    if (hasChatBeenCreated) {
      if (contactUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'chats': FieldValue.arrayUnion([docID])});
      }
    }
  }

  Future<void> createMessageDocument(
      String textMessage, String mediaMessage) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(docID)
        .collection('messages')
        .add({
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'textMessage': textMessage,
      'mediaMessage': mediaMessage,
    });
    if (docID != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(docID)
          .update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> createChatDocument() async {
    if (docID == null) {
      hasChatBeenCreated = true;
      final res =
          await FirebaseFirestore.instance.collection('chats').add({
        'users': [FirebaseAuth.instance.currentUser!.uid, contactUid],
        'type': 'Private',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      if (docID == null) {
        state = true;
        docID = res.id;
        _messagesStream = FirebaseFirestore.instance
            .collection('chats/$docID/messages')
            .orderBy('createdAt', descending: true)
            .snapshots();
        _chatDocStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(docID)
            .snapshots();
      }
    }
  }

  void _fetchContactDetails() async {
    if (contactUid == null || contactUid!.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(contactUid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          String fetchedName = data['displayName'] ?? '';
          if (fetchedName.trim().isEmpty) {
            fetchedName = data['username'] ?? '';
          }
          if (fetchedName.trim().isNotEmpty && fetchedName != displayName) {
            setState(() {
              displayName = fetchedName;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isFirst) {
      var args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      docID = args['docId'];
      contactUid = args['contactUid'] ?? '';
      contactProfile = args['contactProfile'] ?? '';
      isGroup = args['isGroup'] == true;
      final String rawName = args['displayName'] ?? '';
      displayName = rawName.trim().isNotEmpty ? rawName : 'Someone';
      isFirst = false;
      _fetchContactDetails();

      if (docID != null) {
        _messagesStream = FirebaseFirestore.instance
            .collection('chats/$docID/messages')
            .orderBy('createdAt', descending: true)
            .snapshots();
        _chatDocStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(docID)
            .snapshots();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeonAvatar(
              displayName: displayName,
              size: 36,
              isGroup: isGroup,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                displayName.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
            onSelected: (val) {
              if (val == 'Group Members') {
                Navigator.of(context).pushNamed(
                  GroupMembersPage.ROUTE_NAME,
                  arguments: {
                    'docId': docID,
                    'displayName': displayName,
                  },
                );
              } else if (val == 'Remove the chat history') {
                _removeChatHistory();
              } else if (val == 'Purge remote identity') {
                _purgeRemoteIdentity();
              } else if (val == 'Leave Group') {
                _leaveGroup();
              }
            },
            itemBuilder: (context) => [
              if (isGroup) 'Group Members',
              'Remove the chat history',
              if (!isGroup) 'Purge remote identity',
              if (isGroup) 'Leave Group',
            ]
                .map((e) => PopupMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: docID == null
                ? const Center(child: Text('Nothing Yet'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (ctx, AsyncSnapshot<QuerySnapshot> streamSnapShot) {
                      if (streamSnapShot.connectionState ==
                          ConnectionState.waiting && !streamSnapShot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      } else if (streamSnapShot.hasError) {
                  
                        return const Center(
                          child: Text('Something went wrong'),
                        );
                      } else {
                        return ListView.builder(
                          reverse: true,
                          itemCount: streamSnapShot.data!.docs.length,
                          itemBuilder: (ctx, index) {
                            final doc = streamSnapShot.data!.docs[index];
                            final myUid =
                                FirebaseAuth.instance.currentUser!.uid;
                            final senderId =
                                doc['senderId'] as String? ?? '';
                            final isMe = senderId == myUid;
                            final createdAt = doc['createdAt'] as Timestamp?;

                            // For group chats, resolve and cache sender name
                            // asynchronously using FutureBuilder per bubble
                            Widget bubbleWidget;
                            if (isGroup && !isMe) {
                              bubbleWidget = FutureBuilder<String>(
                                future: _getSenderName(senderId),
                                builder: (ctx, snap) {
                                  final name = snap.data ?? '';
                                  return ChatBubble(
                                    doc['textMessage'],
                                    isMe,
                                    ValueKey(doc.id),
                                    doc['mediaMessage'],
                                    formattedTime: _formatTime(createdAt),
                                    onLongPress: () =>
                                        _handleUnsendMessage(doc.id, isMe),
                                    senderName: name,
                                  );
                                },
                              );
                            } else {
                              bubbleWidget = ChatBubble(
                                doc['textMessage'],
                                isMe,
                                ValueKey(doc.id),
                                doc['mediaMessage'],
                                formattedTime: _formatTime(createdAt),
                                onLongPress: () =>
                                    _handleUnsendMessage(doc.id, isMe),
                              );
                            }

                            if (index ==
                                streamSnapShot.data!.docs.length - 1) {
                              return Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : const Color(0xFFF3F4F6),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              Icons.lock_outline_rounded,
                                              size: 13,
                                              color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                          const SizedBox(width: 6),
                                          Text(
                                            isGroup
                                                ? 'GROUP CHAT'
                                                : 'ENCRYPTED CONNECTION',
                                            style: TextStyle(
                                              fontFamily: 'Geist',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  bubbleWidget,
                                ],
                              );
                            }
                            return bubbleWidget;
                          },
                        );
                      }
                    },
                  ),
          ),

          // Typing Indicator Banner (private chats only)
          if (docID != null && !isGroup && _chatDocStream != null)
            StreamBuilder<DocumentSnapshot>(
              stream: _chatDocStream,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && contactUid != null) {
                    final typingMap =
                        data['typingStatus'] as Map<String, dynamic>?;
                    final isContactTyping = typingMap?[contactUid] == true;

                    if (isContactTyping) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, bottom: 4.0, top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              '${displayName.toUpperCase()} IS TYPING...',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2B54ED),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
                return const SizedBox.shrink();
              },
            ),

          // Call buttons — shown for private and group chats
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Audio Call button
                GestureDetector(
                  onTap: () {
                    final String? targetId = isGroup ? docID : contactUid;
                    if (targetId != null && targetId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CallPage(
                            callType: 'Audio',
                            contactId: targetId,
                            name: displayName,
                            isOffering: true,
                            roomId: null,
                            isGroup: isGroup,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: theme.brightness == Brightness.dark ? const [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                // Video Call button
                GestureDetector(
                  onTap: () {
                    final String? targetId = isGroup ? docID : contactUid;
                    if (targetId != null && targetId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CallPage(
                            callType: 'Video',
                            contactId: targetId,
                            name: displayName,
                            isOffering: true,
                            roomId: null,
                            isGroup: isGroup,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: theme.brightness == Brightness.dark ? const [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.videocam_outlined,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ChatInputWidget(
            createChatDoc,
            onTypingChanged: (isTyping) {
              if (!isGroup) _updateTypingStatus(isTyping);
            },
          ),
        ],
      ),
    );
  }
}
