import 'package:seyra/Views/Widgets/neon_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class GroupMembersPage extends StatefulWidget {
  static const ROUTE_NAME = 'group_members';

  const GroupMembersPage({Key? key}) : super(key: key);

  @override
  _GroupMembersPageState createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  late String _docId;
  late String _groupName;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<Contact> _contacts = [];
  Map<String, Map<String, dynamic>> _registeredUsersByPhone = {};
  bool _isLoadingContacts = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContactsAndUsers();
  }

  Future<void> _loadContactsAndUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingContacts = true);

    try {
      if (await FlutterContacts.requestPermission()) {
        _contacts = await FlutterContacts.getContacts(withProperties: true);
      }
      _contacts = _contacts.where((c) => c.phones.isNotEmpty).toList();

      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, Map<String, dynamic>> usersMap = {};
      for (var doc in snapshot.docs) {
        if (doc.id == _currentUid) continue;
        final data = doc.data();
        final userUsername = data['username'] ?? '';
        if (userUsername.isNotEmpty) {
          usersMap[userUsername] = {
            'uid': doc.id,
            'displayName': data['displayName'] ?? '',
            'profilePic': data['profilePic'] ?? '',
          };
        }
      }
      if (mounted) {
        setState(() {
          _registeredUsersByPhone = usersMap;
        });
      }
    } catch (e) {

    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  String _normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+' + cleaned.substring(2);
    }
    return cleaned;
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _removeMember(String memberUid, String memberName) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.onSurface, width: 2),
        ),
        title: const Text(
          'Remove Member',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
          style: const TextStyle(fontFamily: 'Hanken Grotesk'),
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
              'Remove',
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
        // Remove from chat's users array
        await FirebaseFirestore.instance.collection('chats').doc(_docId).update({
          'users': FieldValue.arrayRemove([memberUid]),
        });

        // Remove from user's chats array
        await FirebaseFirestore.instance.collection('users').doc(memberUid).update({
          'chats': FieldValue.arrayRemove([_docId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$memberName has been removed.',
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to remove member. Please try again.',
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
    }
  }

  Future<void> _addMember(String memberUid, String memberName) async {
    final theme = Theme.of(context);
    try {
      // Add to chat's users array
      await FirebaseFirestore.instance.collection('chats').doc(_docId).update({
        'users': FieldValue.arrayUnion([memberUid]),
      });

      // Add to user's chats array
      await FirebaseFirestore.instance.collection('users').doc(memberUid).update({
        'chats': FieldValue.arrayUnion([_docId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$memberName added successfully.',
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to add member. Please try again.',
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
  }

  void _showAddMemberBottomSheet(List<dynamic> existingMembers) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<Map<String, dynamic>> eligibleContacts = [];

            for (var contact in _contacts) {
              for (var phone in contact.phones) {
                final normalized = _normalizePhone(phone.number);
                if (_registeredUsersByPhone.containsKey(normalized)) {
                  final regUser = _registeredUsersByPhone[normalized]!;
                  final uid = regUser['uid']!;
                  if (!existingMembers.contains(uid) &&
                      !eligibleContacts.any((item) => item['uid'] == uid)) {
                    eligibleContacts.add({
                      'uid': uid,
                      'displayName': regUser['displayName'] ?? contact.displayName,
                      'profilePic': regUser['profilePic'] ?? '',
                      'phoneNumber': phone.number,
                    });
                  }
                }
              }
            }

            final filteredEligible = eligibleContacts.where((item) {
              final query = _searchQuery.toLowerCase();
              return item['displayName'].toString().toLowerCase().contains(query) ||
                  item['phoneNumber'].toString().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ADD GROUP MEMBER',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        _filterContacts(val);
                      });
                    },
                    cursorColor: theme.colorScheme.onSurface,
                    style: const TextStyle(fontFamily: 'Hanken Grotesk'),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: theme.colorScheme.onSurface, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: _isLoadingContacts
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface),
                            ),
                          )
                        : filteredEligible.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No new contacts to add.',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredEligible.length,
                                itemBuilder: (ctx, index) {
                                  final item = filteredEligible[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEEEEEE),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: NeonAvatar(
                                        displayName: item['displayName'],
                                        imageUrl: item['profilePic'],
                                        size: 40,
                                      ),
                                      title: Text(
                                        item['displayName'],
                                        style: const TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item['phoneNumber'],
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.onSurface,
                                          foregroundColor: theme.scaffoldBackgroundColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _addMember(item['uid'], item['displayName']);
                                        },
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
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.onSurface, width: 2),
        ),
        title: const Text(
          'Leave Group',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: const Text(
          'Are you sure you want to leave this group chat? You will not be able to see the messages until you are re-added.',
          style: TextStyle(fontFamily: 'Hanken Grotesk'),
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
        // Remove from chat's users list
        await FirebaseFirestore.instance.collection('chats').doc(_docId).update({
          'users': FieldValue.arrayRemove([_currentUid]),
        });

        // Remove from user's chats list
        await FirebaseFirestore.instance.collection('users').doc(_currentUid).update({
          'chats': FieldValue.arrayRemove([_docId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You have left the group.',
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

        // Pop all back to home/main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to leave group. Please try again.',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _docId = routeArgs['docId']!;
    _groupName = routeArgs['displayName']!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MEMBERS: ${_groupName.toUpperCase()}',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(_docId).snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface),
              ),
            );
          }

          if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
            return const Center(
              child: Text(
                'Group not found.',
                style: TextStyle(fontFamily: 'Hanken Grotesk'),
              ),
            );
          }

          final chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> memberUids = chatData['users'] ?? [];
          final String createdBy = chatData['createdBy'] ?? '';
          final bool isAdmin = createdBy == _currentUid;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onSurface),
                  ),
                );
              }

              final Map<String, Map<String, dynamic>> allUsers = {};
              if (usersSnapshot.hasData) {
                for (var doc in usersSnapshot.data!.docs) {
                  allUsers[doc.id] = doc.data() as Map<String, dynamic>;
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: memberUids.length,
                      itemBuilder: (ctx, index) {
                        final uid = memberUids[index];
                        final userData = allUsers[uid] ?? {};
                        final name = userData['displayName'] ?? 'Unknown Member';
                        final profile = userData['profilePic'] ?? '';
                        final isMemberAdmin = uid == createdBy;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 2.0,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: NeonAvatar(
                              displayName: name,
                              imageUrl: profile,
                              size: 44,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMemberAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.tertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              userData['username'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            trailing: (isAdmin && !isMemberAdmin)
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _removeMember(uid, name),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isAdmin)
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.onSurface,
                                foregroundColor: theme.scaffoldBackgroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _showAddMemberBottomSheet(memberUids),
                              icon: Icon(Icons.person_add_outlined, color: theme.colorScheme.tertiary),
                              label: const Text(
                                'ADD NEW MEMBER',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        if (isAdmin) const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _leaveGroup,
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            label: const Text(
                              'LEAVE GROUP',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
