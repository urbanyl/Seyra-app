import 'dart:async';
import 'package:seyra/Views/Screens/chat_screen.dart';
import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsList extends StatefulWidget {
  const ContactsList({Key? key}) : super(key: key);

  @override
  State<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  bool _isLoading = true;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  Map<String, Map<String, dynamic>> _registeredUsersByPhone = {};
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  String _searchQuery = '';
  final Map<String, bool> _buttonLoadingState = {}; // contact.id -> loading state
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _loadContactsAndUsers();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      // Assume Algerian standard prefix conversion (e.g. 0557037906 -> +213557037906)
      clean = '+213' + clean.substring(1);
    }
    return clean;
  }

  Future<void> _loadContactsAndUsers({bool isRefetch = false}) async {
    if (!mounted) return;
    if (!isRefetch) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 1. Request permission & load device contacts with phone number properties
      if (await FlutterContacts.requestPermission()) {
        _contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      // Filter out contacts with no phone numbers for a cleaner list
      _contacts = _contacts.where((c) => c.phones.isNotEmpty).toList();
      _filteredContacts = List.from(_contacts);

      // 2. Listen to registered users from Firebase in real-time
      _usersSubscription?.cancel();
      _usersSubscription = FirebaseFirestore.instance.collection('users').snapshots().listen((usersSnapshot) {
        if (!mounted) return;
        setState(() {
          _registeredUsersByPhone.clear();
          for (var doc in usersSnapshot.docs) {
            if (doc.id == _currentUid) continue; // Skip matching current user
            final data = doc.data();
            final phone = _normalizePhone(data['phoneNumber'] ?? '');
            if (phone.isNotEmpty) {
              _registeredUsersByPhone[phone] = {
                'uid': doc.id,
                'displayName': data['displayName'] ?? '',
                'profilePic': data['profilePic'] ?? '',
                'chats': data['chats'] ?? [],
              };
            }
          }
        });
      });
    } catch (e) {

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadContactsAndUsers(isRefetch: true);
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts
            .where((contact) =>
                contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
                contact.phones.any((p) => p.number.contains(query)))
            .toList();
      }
    });
  }

  Future<void> _handleChatAction(Contact contact, String phoneNum, Map<String, dynamic> firestoreUser) async {
    final contactUid = firestoreUser['uid'];
    final contactDisplayName = firestoreUser['displayName'].toString().trim().isNotEmpty
        ? firestoreUser['displayName']
        : contact.displayName;
    final contactProfile = firestoreUser['profilePic'];

    setState(() {
      _buttonLoadingState[contact.id] = true;
    });

    try {
      String? existingDocId;

      // Check if a chat room already exists between these two users
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('users', whereIn: [
            [_currentUid, contactUid],
            [contactUid, _currentUid]
          ]).get();

      if (chatQuery.docs.isNotEmpty) {
        existingDocId = chatQuery.docs.first.id;
      } else {
        // Create a new private chat document
        final chatRef = await FirebaseFirestore.instance.collection('chats').add({
          'users': [_currentUid, contactUid],
          'type': 'Private',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
        existingDocId = chatRef.id;

        // Link chat ID to both user profiles
        await FirebaseFirestore.instance.collection('users').doc(_currentUid).update({
          'chats': FieldValue.arrayUnion([existingDocId])
        });
        await FirebaseFirestore.instance.collection('users').doc(contactUid).update({
          'chats': FieldValue.arrayUnion([existingDocId])
        });
      }

      if (mounted) {
        Navigator.of(context).pushNamed(ChatScreen.ROUTE_NAME, arguments: {
          'docId': existingDocId,
          'contactUid': contactUid,
          'displayName': contactDisplayName,
          'contactProfile': contactProfile
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open conversation. Please check your internet connection.',
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
      if (mounted) {
        setState(() {
          _buttonLoadingState[contact.id] = false;
        });
      }
    }
  }

  Future<void> _handleAddAction(Contact contact, String phoneNum) async {
    setState(() {
      _buttonLoadingState[contact.id] = true;
    });

    try {
      final String normalizedPhone = _normalizePhone(phoneNum);

      // 1. Create the user in Firebase Firestore
      final newUserRef = FirebaseFirestore.instance.collection('users').doc();
      final String newUid = newUserRef.id;

      final newUserData = {
        'phoneNumber': normalizedPhone,
        'displayName': contact.displayName,
        'profilePic': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        'chats': [],
        'channels': []
      };

      await newUserRef.set(newUserData);

      // 2. Automatically set up the private chat document
      final chatRef = await FirebaseFirestore.instance.collection('chats').add({
        'users': [_currentUid, newUid],
        'type': 'Private',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      final String chatId = chatRef.id;

      // 3. Link chat ID in Firebase
      await FirebaseFirestore.instance.collection('users').doc(_currentUid).update({
        'chats': FieldValue.arrayUnion([chatId])
      });
      await newUserRef.update({
        'chats': FieldValue.arrayUnion([chatId])
      });

      // Update local memory map for immediate UI reflect
      _registeredUsersByPhone[normalizedPhone] = {
        'uid': newUid,
        'displayName': contact.displayName,
        'profilePic': newUserData['profilePic']!,
        'chats': [chatId],
      };

      if (mounted) {
        Navigator.of(context).pushNamed(ChatScreen.ROUTE_NAME, arguments: {
          'docId': chatId,
          'contactUid': newUid,
          'displayName': contact.displayName,
          'contactProfile': newUserData['profilePic']!
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to invite contact. Please check your internet connection.',
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
      if (mounted) {
        setState(() {
          _buttonLoadingState[contact.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF111111)),
      );
    }

    return Column(
      children: [
        // Premium Minimalist Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            onChanged: _filterContacts,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
            decoration: const InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF111111)),
            ),
          ),
        ),

        // Contacts list view
        Expanded(
          child: _filteredContacts.isEmpty
              ? RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.65,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 40),
                          // Custom Refresherator Circle Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF2196F3),
                                size: 30,
                              ),
                            ),
                          ),
                          // Bottom Info Text matching user screenshot
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Column(
                              children: [
                                Text(
                                  _searchQuery.isEmpty ? 'There is not contacts.' : 'No matching contacts found.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    color: const Color(0xFF111111).withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pull to refresh.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    color: const Color(0xFF111111).withOpacity(0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final String phoneNum = contact.phones.first.number;
                      final String normalized = _normalizePhone(phoneNum);
                      final isRegistered = _registeredUsersByPhone.containsKey(normalized);
                      final isButtonLoading = _buttonLoadingState[contact.id] ?? false;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF111111).withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Custom Styled Neon Monogram Avatar
                            NeonAvatar(
                              displayName: contact.displayName,
                              size: 46,
                            ),
                            const SizedBox(width: 16),

                            // Display name and number
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                      color: Color(0xFF111111),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    phoneNum,
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

                            const SizedBox(width: 8),

                            // Action buttons
                            SizedBox(
                              width: 88,
                              height: 38,
                              child: isButtonLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                    )
                                  : isRegistered
                                      ? ElevatedButton(
                                          onPressed: () => _handleChatAction(
                                            contact,
                                            phoneNum,
                                            _registeredUsersByPhone[normalized]!,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2B54ED), // Neon Lime active action button
                                            foregroundColor: const Color(0xFF111111),
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            side: const BorderSide(color: Color(0xFF111111), width: 1.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: const Text(
                                            'Chat',
                                            style: TextStyle(
                                              fontFamily: 'Hanken Grotesk',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                      : OutlinedButton(
                                          onPressed: () => _handleAddAction(contact, phoneNum),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFFFFF),
                                            foregroundColor: const Color(0xFF111111),
                                            side: const BorderSide(color: Color(0xFF111111), width: 1.5), // Outlined secondary button
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(
                                              fontFamily: 'Hanken Grotesk',
                                              fontWeight: FontWeight.bold,
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
