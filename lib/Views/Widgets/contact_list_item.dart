import 'package:seyra/Views/Screens/call_screen.dart';
import 'package:seyra/Views/Screens/chat_screen.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContactListItem extends StatefulWidget {
  final String chatDisplayName;
  final String chatId;
  final String chatProfilePic;
  final String contactUsername;
  final bool isGroup;
  String? docId;
  Function addToGp;

  ContactListItem(
      {required this.chatDisplayName,
      required this.chatId,
      required this.chatProfilePic,
      this.contactUsername = '',
      this.docId,
      this.isGroup = false,
      required this.addToGp});

  @override
  State<ContactListItem> createState() => _ContactListItemState();
}

class _ContactListItemState extends State<ContactListItem> {
  bool isSelectedforGroup = false;

  void tap() {
    if (isSelectedforGroup) {
      setState(() {
        isSelectedforGroup = false;
      });
    } else {
      Navigator.of(context).pushNamed(ChatScreen.ROUTE_NAME, arguments: {
        'docId': widget.docId,
        'contactUid': widget.chatId,
        'displayName': widget.chatDisplayName,
        'contactProfile': widget.chatProfilePic,
        'isGroup': widget.isGroup,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: tap,
      onLongPress: longTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.brightness == Brightness.dark ? theme.colorScheme.tertiary.withOpacity(0.2) : theme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Styled Avatar
            Stack(
              children: [
                Hero(
                  tag: widget.chatId,
                  child: NeonAvatar(
                    displayName: widget.chatDisplayName.isNotEmpty
                        ? widget.chatDisplayName
                        : widget.contactUsername,
                    size: 46,
                    isGroup: widget.isGroup,
                  ),
                ),
                if (isSelectedforGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                        boxShadow: const [],
                      ),
                      child: Icon(Icons.check, color: theme.colorScheme.onTertiary, size: 12),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 16),
            
            // Name & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatDisplayName.trim().isNotEmpty
                        ? widget.chatDisplayName
                        : (widget.contactUsername.isNotEmpty
                            ? widget.contactUsername
                            : 'Someone'),
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.contactUsername.isNotEmpty &&
                      widget.chatDisplayName.trim().isNotEmpty &&
                      widget.chatDisplayName != widget.contactUsername) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.contactUsername,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice Call Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : const Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CallPage(
                            callType: 'Audio',
                            contactId: widget.chatId,
                            name: widget.chatDisplayName,
                            isOffering: true,
                            roomId: null,
                            isGroup: widget.isGroup,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.phone_outlined, color: theme.colorScheme.onSurface, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                // Video Call Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? theme.colorScheme.secondary : const Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CallPage(
                            callType: 'Video',
                            contactId: widget.chatId,
                            name: widget.chatDisplayName,
                            isOffering: true,
                            roomId: null,
                            isGroup: widget.isGroup,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.videocam_outlined, color: theme.colorScheme.onSurface, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void longTap() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final theme = Theme.of(context);
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
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Monogram header in sheet
              Row(
                children: [
                  NeonAvatar(
                    displayName: widget.chatDisplayName,
                    size: 52,
                    isGroup: widget.isGroup,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chatDisplayName,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.contactUsername.isNotEmpty
                              ? widget.contactUsername
                              : 'Secure Chat Group',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 8),
              
              // Remove Chat Action
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text(
                  'Remove Chat History',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Wipes chat history permanently', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmRemoveChat();
                },
              ),
              

              // Delete User Action (Private Chats Only)
              if (widget.chatId != widget.docId)
                ListTile(
                  leading: const Icon(Icons.no_accounts_outlined, color: Colors.red),
                  title: const Text(
                    'Purge Remote Identity',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Completely deletes profile from network nodes', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmDeleteUser();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveChat() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: Text(
          'Remove Chat',
          style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to remove this chat room? This will delete all history.',
          style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface, fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performRemoveChat();
            },
            child: const Text('Remove', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performRemoveChat() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || widget.docId == null) return;

    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.docId).delete();
      await FirebaseFirestore.instance.collection('users').doc(myUid).update({
        'chats': FieldValue.arrayRemove([widget.docId])
      });
      if (widget.chatId != widget.docId) {
        await FirebaseFirestore.instance.collection('users').doc(widget.chatId).update({
          'chats': FieldValue.arrayRemove([widget.docId])
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat removed successfully.',
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
            'Unable to remove chat. Please try again.',
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



  void _confirmDeleteUser() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.dividerColor, width: 2),
        ),
        title: const Text(
          'Purge Identity',
          style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'Warning: This will permanently delete ${widget.chatDisplayName} from the database. This action is irreversible.',
          style: TextStyle(fontFamily: 'Hanken Grotesk', color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface, fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performDeleteUser();
            },
            child: const Text('Delete', style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteUser() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.chatId).delete();
      await _performRemoveChat();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.chatDisplayName} purged from secure network.',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete identity. Please check connection.',
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
