import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Widgets/contact_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatItem extends StatefulWidget {
  final Key key;
  final Map<String, dynamic> chatInfo;

  ChatItem(this.key, this.chatInfo) : super(key: key);

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  Stream<DocumentSnapshot>? _userStream;
  String? _otherUserId;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    if (widget.chatInfo['type'] == 'Private') {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final List<dynamic> users = widget.chatInfo['users'] ?? [];
        _otherUserId = users.firstWhere((userId) => userId != myUid, orElse: () => null);
        if (_otherUserId != null) {
          _userStream = FirebaseFirestore.instance
              .collection('users')
              .doc(_otherUserId)
              .snapshots();
        }
      }
    }
  }

  @override
  void didUpdateWidget(ChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatInfo['type'] == 'Private') {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        final List<dynamic> users = widget.chatInfo['users'] ?? [];
        final newOtherUserId = users.firstWhere((userId) => userId != myUid, orElse: () => null);
        if (newOtherUserId != _otherUserId) {
          setState(() {
            _otherUserId = newOtherUserId;
            if (_otherUserId != null) {
              _userStream = FirebaseFirestore.instance
                  .collection('users')
                  .doc(_otherUserId)
                  .snapshots();
            } else {
              _userStream = null;
            }
          });
        }
      }
    } else {
      if (_userStream != null) {
        setState(() {
          _userStream = null;
          _otherUserId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatInfo['type'] == 'Private') {
      if (_userStream == null) {
        return const SizedBox.shrink();
      }
      return StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, AsyncSnapshot<DocumentSnapshot> asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting && !asyncSnapshot.hasData) {
            return const SizedBox.shrink();
          }
          if (!asyncSnapshot.hasData || asyncSnapshot.data == null || asyncSnapshot.data!.data() == null) {
            return const SizedBox.shrink();
          }
          var data = asyncSnapshot.data!.data() as Map<String, dynamic>;
          
          // check if chat contact is a phone contact; if so, we show the local contact Name
          String? displayName = Provider.of<UserManager>(context)
              .getDisplayNameForUsername(data['username'] ?? '');
          String userDisplayName = data['displayName'] ?? '';
          if (userDisplayName.trim().isEmpty) {
            userDisplayName = data['username'] ?? '';
          }

          if (displayName == null || displayName == '') {
            return ContactListItem(
                docId: widget.chatInfo['id'],
                chatDisplayName: userDisplayName,
                chatId: asyncSnapshot.data!.id,
                chatProfilePic: data['profilePic'] ?? '',
                contactUsername: data['username'] ?? '',
                addToGp: () {});
          } else {
            return ContactListItem(
              docId: widget.chatInfo['id'],
              chatDisplayName: displayName,
              chatId: asyncSnapshot.data!.id,
              chatProfilePic: data['profilePic'] ?? '',
              contactUsername: data['username'] ?? '',
              addToGp: () {},
            );
          }
        },
      );
    } else {
      //its a group or channel
      return ContactListItem(
          docId: widget.chatInfo['id'],
          chatDisplayName: widget.chatInfo['displayName'] ?? '',
          chatId: widget.chatInfo['id'],
          chatProfilePic: widget.chatInfo['chatPic'] ?? '',
          isGroup: true,
          addToGp: () {});
    }
  }
}
