import 'dart:async';
import 'package:seyra/Views/Screens/chat_screen.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  static const ROUTE_NAME = '/create_group';

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController =
      TextEditingController();
  final TextEditingController _searchController =
      TextEditingController();

  bool _isCreating = false;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final String _currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  final Map<String, String> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
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
        });
      }
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = List.from(users);
        });
      }
    } catch (_) {}
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final q = query.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          final username =
              (user['username'] ?? '').toString().toLowerCase();
          final displayName =
              (user['displayName'] ?? '').toString().toLowerCase();
          return username.contains(q) || displayName.contains(q);
        }).toList();
      }
    });
  }

  void _toggleUser(String uid, String displayName) {
    setState(() {
      if (_selectedUsers.containsKey(uid)) {
        _selectedUsers.remove(uid);
      } else {
        _selectedUsers[uid] = displayName;
      }
    });
  }

  Future<void> _createGroup() async {
    final theme = Theme.of(context);
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a group name.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: theme.scaffoldBackgroundColor,
            ),
          ),
          backgroundColor: theme.colorScheme.onSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one user.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: theme.scaffoldBackgroundColor,
            ),
          ),
          backgroundColor: theme.colorScheme.onSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final allUserIds = [
        _currentUid,
        ..._selectedUsers.keys.toList()
      ];

      final docRef =
          await FirebaseFirestore.instance.collection('chats').add({
        'displayName': groupName,
        'users': allUserIds,
        'type': 'Group',
        'chatPic': '',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _currentUid,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      for (final uid in allUserIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'chats': FieldValue.arrayUnion([docRef.id])
        });
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          ChatScreen.ROUTE_NAME,
          arguments: {
            'docId': docRef.id,
            'contactUid': null,
            'displayName': groupName,
            'contactProfile': '',
            'isGroup': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to create group.',
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'NEW GROUP',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _groupNameController,
                maxLength: 30,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Group name...',
                  prefixIcon: Icon(Icons.group_outlined,
                      color: theme.colorScheme.onSurface,
                      size: 20),
                  hintStyle: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.35),
                    fontSize: 15,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(
                        color: theme.colorScheme.tertiary,
                        width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(
                        color: theme.colorScheme.tertiary,
                        width: 2.0),
                  ),
                ),
              ),
            ),

            if (_selectedUsers.isNotEmpty)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: _selectedUsers.length,
                  itemBuilder: (context, index) {
                    final uid =
                        _selectedUsers.keys.elementAt(index);
                    final name = _selectedUsers[uid]!;
                    return Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            _toggleUser(uid, name),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                          decoration: BoxDecoration(
                            color: theme
                                .colorScheme.tertiary,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily:
                                      'Hanken Grotesk',
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.brightness ==
                                          Brightness
                                              .dark
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(
                                  width: 6),
                              Icon(Icons.close,
                                  size: 14,
                                  color: theme.brightness ==
                                          Brightness
                                              .dark
                                      ? Colors.black
                                      : Colors.white),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Search by @username or name...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: theme.colorScheme.onSurface),
                  suffixIcon: _searchController
                          .text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                              Icons.clear_rounded,
                              color: theme
                                  .colorScheme
                                  .onSurface),
                          onPressed: () {
                            _searchController.clear();
                            _filterContacts('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 6.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT MEMBERS',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          color: theme
                              .colorScheme.onSurface
                              .withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4),
                      itemCount:
                          _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user =
                            _filteredUsers[index];
                        final uid = user['uid'];
                        final displayName =
                            user['displayName'] ?? '';
                        final username =
                            user['username'] ?? '';
                        final isSelected =
                            _selectedUsers
                                .containsKey(uid);

                        return GestureDetector(
                          onTap: () => _toggleUser(
                              uid,
                              displayName.isNotEmpty
                                  ? displayName
                                  : username),
                          child:
                              AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            padding:
                                const EdgeInsets.all(12),
                            margin: const EdgeInsets
                                .symmetric(
                                vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme
                                      .colorScheme
                                      .tertiary
                                      .withOpacity(
                                          0.15)
                                  : theme
                                      .scaffoldBackgroundColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme
                                        .colorScheme
                                        .tertiary
                                    : theme
                                        .dividerColor,
                                width:
                                    isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                NeonAvatar(
                                  displayName:
                                      displayName
                                              .isNotEmpty
                                          ? displayName
                                          : username,
                                  size: 44,
                                ),
                                const SizedBox(
                                    width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        displayName
                                                .isNotEmpty
                                            ? displayName
                                            : 'New User',
                                        style:
                                            TextStyle(
                                          fontFamily:
                                              'Hanken Grotesk',
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize: 15,
                                          color: theme
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                      ),
                                      if (username
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                            height: 2),
                                        Text(
                                          username,
                                          style:
                                              TextStyle(
                                            fontFamily:
                                                'Geist',
                                            color: theme
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(
                                                    0.45),
                                            fontSize:
                                                12,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration:
                                      const Duration(
                                          milliseconds:
                                              200),
                                  width: 28,
                                  height: 28,
                                  decoration:
                                      BoxDecoration(
                                    color: isSelected
                                        ? theme
                                            .colorScheme
                                            .tertiary
                                        : Colors
                                            .transparent,
                                    shape: BoxShape
                                        .circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme
                                              .colorScheme
                                              .tertiary
                                          : theme
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(
                                                  0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: theme.brightness ==
                                                  Brightness
                                                      .dark
                                              ? Colors
                                                  .black
                                              : Colors
                                                  .white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.tertiary,
                    foregroundColor: theme.brightness ==
                            Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.brightness ==
                                    Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        )
                      : const Text(
                          'CREATE GROUP',
                          style: TextStyle(
                            fontFamily:
                                'Hanken Grotesk',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
