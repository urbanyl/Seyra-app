import 'dart:async';
import 'package:seyra/Views/Screens/chat_screen.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactsList extends StatefulWidget {
  const ContactsList({Key? key}) : super(key: key);

  @override
  State<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  String _searchQuery = '';
  final Map<String, bool> _buttonLoadingState = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        if (doc.id == _currentUid) continue;
        final data = doc.data();
        users.add({
          'uid': doc.id,
          'username': data['username'] ?? '',
          'displayName': data['displayName'] ?? '',
          'profilePic': data['profilePic'] ?? '',
          'chats': data['chats'] ?? [],
        });
      }
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = List.from(users);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadUsers();
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final q = query.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          final username = (user['username'] ?? '')
              .toString()
              .toLowerCase();
          final displayName = (user['displayName'] ?? '')
              .toString()
              .toLowerCase();
          return username.contains(q) ||
              displayName.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _handleChatAction(
      Map<String, dynamic> targetUser) async {
    final contactUid = targetUser['uid'];
    final contactDisplayName =
        (targetUser['displayName'] ?? '').toString().trim().isNotEmpty
            ? targetUser['displayName']
            : targetUser['username'];
    final contactProfile = targetUser['profilePic'] ?? '';
    final btnKey = contactUid;

    setState(() {
      _buttonLoadingState[btnKey] = true;
    });

    try {
      String? existingDocId;

      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('users',
              whereIn: [
                [_currentUid, contactUid],
                [contactUid, _currentUid]
              ])
          .get();

      if (chatQuery.docs.isNotEmpty) {
        existingDocId = chatQuery.docs.first.id;
      } else {
        final chatRef =
            await FirebaseFirestore.instance.collection('chats').add({
          'users': [_currentUid, contactUid],
          'type': 'Private',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
        existingDocId = chatRef.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .update({
          'chats': FieldValue.arrayUnion([existingDocId])
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(contactUid)
            .update({
          'chats': FieldValue.arrayUnion([existingDocId])
        });
      }

      if (mounted) {
        Navigator.of(context).pushNamed(ChatScreen.ROUTE_NAME,
            arguments: {
              'docId': existingDocId,
              'contactUid': contactUid,
              'displayName': contactDisplayName,
              'contactProfile': contactProfile,
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open conversation.',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _buttonLoadingState[btnKey] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            onChanged: _filterContacts,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search by @username or name...',
              prefixIcon:
                  Icon(Icons.search_rounded, color: theme.colorScheme.onSurface),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: theme.colorScheme.onSurface),
                      onPressed: () => _filterContacts(''),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded,
                                size: 56,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No matching users',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final uid = user['uid'];
                      final displayName =
                          user['displayName'] ?? '';
                      final username = user['username'] ?? '';
                      final isButtonLoading =
                          _buttonLoadingState[uid] ?? false;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            NeonAvatar(
                              displayName:
                                  displayName.isNotEmpty ? displayName : username,
                              size: 46,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName.isNotEmpty
                                        ? displayName
                                        : 'New User',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: theme
                                          .colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                  if (username.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      username,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        color: theme
                                            .colorScheme.onSurface
                                            .withOpacity(0.45),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 38,
                              child: isButtonLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child:
                                          CircularProgressIndicator(
                                              strokeWidth: 2))
                                  : ElevatedButton(
                                      onPressed: () =>
                                          _handleChatAction(user),
                                      style: ElevatedButton
                                          .styleFrom(
                                        backgroundColor:
                                            theme.colorScheme
                                                .tertiary,
                                        foregroundColor:
                                            theme.brightness ==
                                                    Brightness
                                                        .dark
                                                ? Colors.black
                                                : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets
                                            .symmetric(
                                                horizontal: 16),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(24),
                                        ),
                                      ),
                                      child: const Text(
                                        'Chat',
                                        style: TextStyle(
                                          fontFamily:
                                              'Hanken Grotesk',
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
