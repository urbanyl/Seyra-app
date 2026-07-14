import 'dart:async';
import 'package:seyra/Models/user.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';

import 'chat_screen.dart';

class CreateGroupPage extends StatefulWidget {
  static const ROUTE_NAME = '/create_group';

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isCreating = false;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  Map<String, Map<String, dynamic>> _registeredUsersByPhone = {};
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Selected user IDs → display name mapping
  final Map<String, String> _selectedUsers = {};

  StreamSubscription<QuerySnapshot>? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _loadContactsAndUsers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    _usersSubscription?.cancel();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      clean = '+213' + clean.substring(1);
    }
    return clean;
  }

  Future<void> _loadContactsAndUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (await FlutterContacts.requestPermission()) {
        _contacts = await FlutterContacts.getContacts(withProperties: true);
      }
      _contacts = _contacts.where((c) => c.phones.isNotEmpty).toList();
      _filteredContacts = List.from(_contacts);

      _usersSubscription?.cancel();
      _usersSubscription = FirebaseFirestore.instance
          .collection('users')
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _registeredUsersByPhone.clear();
          for (var doc in snapshot.docs) {
            if (doc.id == _currentUid) continue;
            final data = doc.data();
            final userUsername = data['username'] ?? '';
            if (userUsername.isNotEmpty) {
              _registeredUsersByPhone[userUsername] = {
                'uid': doc.id,
                'displayName': data['displayName'] ?? '',
                'profilePic': data['profilePic'] ?? '',
              };
            }
          }
        });
      });
    } catch (e) {

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts
            .where((c) =>
                c.displayName.toLowerCase().contains(query.toLowerCase()) ||
                c.phones.any((p) => p.number.contains(query)))
            .toList();
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
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a group name.',
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
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one contact.',
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
      return;
    }

    setState(() => _isCreating = true);

    try {
      final allUserIds = [_currentUid, ..._selectedUsers.keys.toList()];

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

      // Link chat ID to all members
      for (final uid in allUserIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'chats': FieldValue.arrayUnion([docRef.id])});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create group. Please check your internet connection.',
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
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'NEW GROUP',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B54ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF111111), width: 1.5),
                  ),
                  child: Text(
                    '${_selectedUsers.length} selected',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF111111)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Group Name Field ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _groupNameController,
                    cursorColor: const Color(0xFF111111),
                    maxLength: 35,
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111111),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Group name...',
                      prefixIcon: const Icon(Icons.group_outlined,
                          color: Color(0xFF111111), size: 20),
                      counterText: '',
                      hintStyle: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        color: const Color(0xFF111111).withValues(alpha: 0.35),
                        fontSize: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(color: Color(0xFF2B54ED), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(color: Color(0xFF2B54ED), width: 2.0),
                      ),
                    ),
                  ),
                ),

                // ── Selected Members Chips ────────────────────────────────
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
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _toggleUser(uid, name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B54ED),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF111111),
                                    width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name.split(' ').first,
                                    style: const TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.close,
                                      size: 14, color: Color(0xFF111111)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Search Bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterContacts,
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF111111)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Color(0xFF111111)),
                              onPressed: () {
                                _searchController.clear();
                                _filterContacts('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // ── Contacts List ─────────────────────────────────────────
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'SELECT MEMBERS',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),

                Expanded(
                  child: _filteredContacts.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found.',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              color:
                                  const Color(0xFF111111).withOpacity(0.5),
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final phoneRaw = contact.phones.first.number;
                            final normalized = _normalizePhone(phoneRaw);
                            final isRegistered =
                                _registeredUsersByPhone.containsKey(normalized);

                            if (!isRegistered) return const SizedBox.shrink();

                            final firestoreUser =
                                _registeredUsersByPhone[normalized]!;
                            final uid = firestoreUser['uid'] as String;
                            final displayName =
                                (firestoreUser['displayName'] as String)
                                        .trim()
                                        .isNotEmpty
                                    ? firestoreUser['displayName'] as String
                                    : contact.displayName;

                            final isSelected =
                                _selectedUsers.containsKey(uid);

                            return GestureDetector(
                              onTap: () => _toggleUser(uid, displayName),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2B54ED)
                                          .withOpacity(0.15)
                                      : const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2B54ED)
                                        : const Color(0xFF111111)
                                            .withOpacity(0.08),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    NeonAvatar(
                                      displayName: displayName,
                                      size: 44,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontFamily: 'Hanken Grotesk',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF111111),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            phoneRaw,
                                            style: const TextStyle(
                                              fontFamily: 'Geist',
                                              color: Color(0xFF747878),
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2B54ED)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF111111)
                                              : const Color(0xFF111111)
                                                  .withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              size: 16,
                                              color: Color(0xFF111111))
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // ── Create Button ─────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B54ED),
                        foregroundColor: const Color(0xFF111111),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                              color: Color(0xFF111111), width: 1.5),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF111111),
                              ),
                            )
                          : const Text(
                              'CREATE GROUP',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
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
    );
  }
}
